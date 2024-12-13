Attribute VB_Name = "FemtetMacro"
Option Explicit

Dim Femtet As New CFemtet
Dim Als As CAnalysis
Dim BodyAttr As CBodyAttribute
Dim Bnd As CBoundary
Dim Mtl As CMaterial
Dim Gaudi As CGaudi
Dim Gogh As CGogh
'/////////////////////////null***�̐���/////////////////////////
'//���L�̎l�̕ϐ���CGaudi�N���XMulti***���g�p����ꍇ�ɗp���܂��B
'//�Ⴆ��MultiFillet���g�p����ꍇ�Ɉ����ł���Vertex(�_)�͎w�肹��
'//������Edge(��)������Fillet����ꍇ��nullVertex()��p���܂��B
'//�uGaudi.MultiFillet nullVertex,Edge�v�Ƃ����
'//������Edge����Fillet���邱�Ƃ��ł��܂��B
'/////////////////////////////////////////////////////////////
Global nullVertex() As CGaudiVertex
Global nullEdge() As CGaudiEdge
Global nullFace() As CGaudiFace
Global nullBody() As CGaudiBody

'///////////////////////////////////////////////////

'�ϐ��̐錾
Private pi as Double
Private width as Double
Private depth as Double
Private height as Double
'///////////////////////////////////////////////////


'////////////////////////////////////////////////////////////
'    Main�֐�
'////////////////////////////////////////////////////////////
Sub FemtetMain() 
    '------- Femtet�����N�� (�s�v�ȏꍇ��Excel�Ŏ��s���Ȃ��ꍇ�͉��s���R�����g�A�E�g���Ă�������) -------
    Workbooks("FemtetRef.xla").AutoExecuteFemtet

    '------- �V�K�v���W�F�N�g -------
    If Femtet.OpenNewProject() = False Then
        Femtet.ShowLastError
    End If

    '------- �ϐ��̒�` -------
    InitVariables

    '------- �f�[�^�x�[�X�̐ݒ� -------
    AnalysisSetUp
    BodyAttributeSetUp
    MaterialSetUp
    BoundarySetUp

    '------- ���f���̍쐬 -------
    Set Gaudi = Femtet.Gaudi
    MakeModel

    '------- �W�����b�V���T�C�Y�̐ݒ� -------
    '<<<<<<< �����v�Z�ɐݒ肷��ꍇ��-1��ݒ肵�Ă������� >>>>>>>
    Gaudi.MeshSize = -1

    '------- �v���W�F�N�g�̕ۑ� -------
    Dim ProjectFilePath As String
    ProjectFilePath = "C:\Users\mm11592\Documents\myFiles2\working\1_PyFemtetOpt\PyFemtetDev3\pyfemtet\tests\excel_ui\�v���W�F�N�g"
    '<<<<<<< �v���W�F�N�g��ۑ�����ꍇ�͈ȉ��̃R�����g���O���Ă������� >>>>>>>
    'If Femtet.SaveProject(ProjectFilePath & ".femprj", True) = False Then
    '    Femtet.ShowLastError
    'End If

    '------- ���b�V���̐��� -------
    '<<<<<<< ���b�V���𐶐�����ꍇ�͈ȉ��̃R�����g���O���Ă������� >>>>>>>
    'Gaudi.Mesh

    '------- ��͂̎��s -------
    '<<<<<<< ��͂����s����ꍇ�͈ȉ��̃R�����g���O���Ă������� >>>>>>>
    'Femtet.Solve

    '------- ��͌��ʂ̒��o -------
    '<<<<<<< �v�Z���ʂ𒊏o����ꍇ�͈ȉ��̃R�����g���O���Ă������� >>>>>>>
    'SamplingResult

    '------- �v�Z���ʂ̕ۑ� -------
    '<<<<<<< �v�Z����(.pdt)�t�@�C����ۑ�����ꍇ�͈ȉ��̃R�����g���O���Ă������� >>>>>>>
    'If Femtet.SavePDT(Femtet.ResultFilePath & ".pdt", True) = False Then
    '    Femtet.ShowLastError
    'End If

End Sub

'////////////////////////////////////////////////////////////
'    ��͏����̐ݒ�
'////////////////////////////////////////////////////////////
Sub AnalysisSetUp()

    '------- �ϐ��ɃI�u�W�F�N�g�̐ݒ� -------
    Set Als = Femtet.Analysis

    '------- ��͏�������(Common) -------
    Als.AnalysisType = COULOMB_C

    '------- ����(Gauss) -------
    Als.Gauss.b2ndEdgeElement = True

    '------- �d���g(Hertz) -------
    Als.Hertz.b2ndEdgeElement = True

    '------- �J�����E(Open) -------
    Als.Open.OpenMethod = ABC_C

    '------- ���a���(Harmonic) -------
    Als.Harmonic.FreqSweepType = LINEAR_INTERVAL_C

    '------- ���x�Ȑݒ�(HighLevel) -------
    Als.HighLevel.MemoryLimit = (16)

    '------- ���b�V���̐ݒ�(MeshProperty) -------
    Als.MeshProperty.bAdaptiveMeshOnCurve = True
    Als.MeshProperty.bAutoAir = True
    Als.MeshProperty.AutoAirMeshSize = (1.8)
    Als.MeshProperty.bChangePlane = True
    Als.MeshProperty.bMeshG2 = True
    Als.MeshProperty.bPeriodMesh = False

    '------- ���ʃC���|�[�g(Import) -------
    Als.Import.AnalysisModelName = "���I��"
End Sub

'////////////////////////////////////////////////////////////
'    Body�����S�̂̐ݒ�
'////////////////////////////////////////////////////////////
Sub BodyAttributeSetUp()

    '------- �ϐ��ɃI�u�W�F�N�g�̐ݒ� -------
    Set BodyAttr = Femtet.BodyAttribute

    '------- Body�����̐ݒ� -------
    BodyAttributeSetUp_�{�f�B����_001

    '+++++++++++++++++++++++++++++++++++++++++
    '++�g�p����Ă��Ȃ�BodyAttribute�f�[�^�ł�
    '++�g�p����ۂ̓R�����g���O���ĉ�����
    '+++++++++++++++++++++++++++++++++++++++++
    'BodyAttributeSetUp_Air_Auto
End Sub

'////////////////////////////////////////////////////////////
'    Body�����̐ݒ� Body�������F�{�f�B����_001
'////////////////////////////////////////////////////////////
Sub BodyAttributeSetUp_�{�f�B����_001()
    '------- Body������Index��ۑ�����ϐ� -------
    Dim Index As Integer

    '------- Body�����̒ǉ� -------
    BodyAttr.Add "�{�f�B����_001" 

    '------- Body���� Index�̐ݒ� -------
    Index = BodyAttr.Ask ( "�{�f�B����_001" ) 

    '------- �V�[�g�{�f�B�̌��� or 2������͂̉��s��(BodyThickness)/���C���[�{�f�B��(WireWidth) -------
    BodyAttr.Length(Index).bUseAnalysisThickness2D = True

    '------- ����(Direction) -------
    BodyAttr.Direction(Index).SetAxisVector (0.0), (0.0), (1.0)

    '------- �������x(InitialVelocity) -------
    BodyAttr.InitialVelocity(Index).bAnalysisUse = True

    '------- �t��(Emittivity) -------
    BodyAttr.ThermalSurface(Index).Emittivity.Eps = (0.8)
End Sub

'////////////////////////////////////////////////////////////
'    Body�����̐ݒ� Body�������FAir_Auto
'////////////////////////////////////////////////////////////
Sub BodyAttributeSetUp_Air_Auto()
    '------- Body������Index��ۑ�����ϐ� -------
    Dim Index As Integer

    '------- Body�����̒ǉ� -------
    BodyAttr.Add "Air_Auto" 

    '------- Body���� Index�̐ݒ� -------
    Index = BodyAttr.Ask ( "Air_Auto" ) 

    '------- �V�[�g�{�f�B�̌��� or 2������͂̉��s��(BodyThickness)/���C���[�{�f�B��(WireWidth) -------
    BodyAttr.Length(Index).bUseAnalysisThickness2D = True

    '------- ��͗̈�(ActiveSolver) -------
    BodyAttr.ActiveSolver(Index).bWatt = False
    BodyAttr.ActiveSolver(Index).bGalileo = False

    '------- �������x(InitialVelocity) -------
    BodyAttr.InitialVelocity(Index).bAnalysisUse = True

    '------- �X�e�[�^/���[�^(StatorRotor) -------
    BodyAttr.StatorRotor(Index).State = AIR_C

    '------- ����(FluidBern) -------
    BodyAttr.FluidAttribute(Index).FlowCondition.bSpline = False

    '------- �t��(Emittivity) -------
    BodyAttr.ThermalSurface(Index).Emittivity.Eps = (0.8)
End Sub

'////////////////////////////////////////////////////////////
'    Material�S�̂̐ݒ�
'////////////////////////////////////////////////////////////
Sub MaterialSetUp()

    '------- �ϐ��ɃI�u�W�F�N�g�̐ݒ� -------
    Set Mtl = Femtet.Material

    '------- Material�̐ݒ� -------
    MaterialSetUp_001_�A���~�i

    '+++++++++++++++++++++++++++++++++++++++++
    '++�g�p����Ă��Ȃ�Material�f�[�^�ł�
    '++�g�p����ۂ̓R�����g���O���ĉ�����
    '+++++++++++++++++++++++++++++++++++++++++
    'MaterialSetUp_Air_Auto
End Sub

'////////////////////////////////////////////////////////////
'    Material�̐ݒ� Material���F001_�A���~�i
'////////////////////////////////////////////////////////////
Sub MaterialSetUp_001_�A���~�i()
    '------- Material��Index��ۑ�����ϐ� -------
    Dim Index As Integer

    '------- Material�̒ǉ� -------
    Mtl.Add "001_�A���~�i" 

    '------- Material Index�̐ݒ� -------
    Index = Mtl.Ask ( "001_�A���~�i" ) 

    '------- �U�d��(Permittivity) -------
    Mtl.Permittivity(Index).TanD = (0.002)
    Mtl.Permittivity(Index).sEps = (8.5)

    '------- ��R��(Resistivity) -------
    Mtl.Resistivity(Index).ResistivityUse = USE_DISABLE_C

    '------- ���x(Density) -------
    Mtl.Density(Index).Dens = (3800)

    '------- �M�`����(ThermalConductivity) -------
    Mtl.ThermalConductivity(Index).sRmd = (33)

    '------- ���c���W��(Expansion) -------
    Mtl.Expansion(Index).sAlf = (5.4) * 10 ^ (-6)

    '------- �e���萔(Elasticity) -------
    Mtl.Elasticity(Index).sY = (220) * 10 ^ (9)

    '------- ���d�萔(PiezoElectricity) -------
    Mtl.PiezoElectricity(Index).bPiezo = False

    '------- ���� -------
    Mtl.Comment(Index).Comment = "�s�o�T�t " & Chr(13) & Chr(10) & "�@���x�F [C1]P.590" & Chr(13) & Chr(10) & "�@�e���萔�F [C1]P.590" & Chr(13) & Chr(10) & "�@���c���W���F [C1]P.590" & Chr(13) & Chr(10) & "�@�U�d���F [S]P.530" & Chr(13) & Chr(10) & "�@��R���F [S]P.534" & Chr(13) & Chr(10) & "�@�M�`�����F [C1]P.590" & Chr(13) & Chr(10) & "�@ " & Chr(13) & Chr(10) & "�s�Q�l�����t " & Chr(13) & Chr(10) & "�@[C1] ���w�֗� ��b��I ����4�� ���{���w�w��� �ۑP(1993)" & Chr(13) & Chr(10) & "�@[S] ���ȔN�\ ����8�N �����V����� �ۑP(1996)" & Chr(13) & Chr(10) & "�@ "
End Sub

'////////////////////////////////////////////////////////////
'    Material�̐ݒ� Material���FAir_Auto
'////////////////////////////////////////////////////////////
Sub MaterialSetUp_Air_Auto()
    '------- Material��Index��ۑ�����ϐ� -------
    Dim Index As Integer

    '------- Material�̒ǉ� -------
    Mtl.Add "Air_Auto" 

    '------- Material Index�̐ݒ� -------
    Index = Mtl.Ask ( "Air_Auto" ) 

    '------- �U�d��(Permittivity) -------
    Mtl.Permittivity(Index).sEps = (1.000517)

    '------- ��R��(Resistivity) -------
    Mtl.Resistivity(Index).ResistivityUse = USE_DISABLE_C

    '------- �ő�/����(SolidFluid) -------
    Mtl.SolidFluid(Index).State = FLUID_C
End Sub

'////////////////////////////////////////////////////////////
'    Boundary�S�̂̐ݒ�
'////////////////////////////////////////////////////////////
Sub BoundarySetUp()

    '------- �ϐ��ɃI�u�W�F�N�g�̐ݒ� -------
    Set Bnd = Femtet.Boundary

    '------- Boundary�̐ݒ� -------
    BoundarySetUp_RESERVED_default
    BoundarySetUp_���E����_001
    BoundarySetUp_���E����_002
End Sub

'////////////////////////////////////////////////////////////
'    Boundary�̐ݒ� Boundary���FRESERVED_default (�O�����E����)
'////////////////////////////////////////////////////////////
Sub BoundarySetUp_RESERVED_default()
    '------- Boundary��Index��ۑ�����ϐ� -------
    Dim Index As Integer

    '------- Boundary�̒ǉ� -------
    Bnd.Add "RESERVED_default" 

    '------- Boundary Index�̐ݒ� -------
    Index = Bnd.Ask ( "RESERVED_default" ) 

    '------- �M(Thermal) -------
    Bnd.Thermal(Index).bConAuto = True
    Bnd.Thermal(Index).bSetRadioSetting = False

    '------- ����_�����x(RoomTemp) -------
    Bnd.Thermal(Index).RoomTemp.TempType = TEMP_AMBIENT_C

    '------- �t��(Emittivity) -------
    Bnd.Thermal(Index).Emittivity.Eps = (0.8)

    '------- ����(FluidBern) -------
    Bnd.FluidBern(Index).bSpline = False
End Sub

'////////////////////////////////////////////////////////////
'    Boundary�̐ݒ� Boundary���F���E����_001
'////////////////////////////////////////////////////////////
Sub BoundarySetUp_���E����_001()
    '------- Boundary��Index��ۑ�����ϐ� -------
    Dim Index As Integer

    '------- Boundary�̒ǉ� -------
    Bnd.Add "���E����_001" 

    '------- Boundary Index�̐ݒ� -------
    Index = Bnd.Ask ( "���E����_001" ) 

    '------- �d�C(Electrical) -------
    Bnd.Electrical(Index).Condition = ELECTRIC_WALL_C
    Bnd.Electrical(Index).V = (1)

    '------- �M(Thermal) -------
    Bnd.Thermal(Index).bConAuto = True
    Bnd.Thermal(Index).bSetRadioSetting = False

    '------- ����_�����x(RoomTemp) -------
    Bnd.Thermal(Index).RoomTemp.TempType = TEMP_AMBIENT_C

    '------- �t��(Emittivity) -------
    Bnd.Thermal(Index).Emittivity.Eps = (0.8)

    '------- ����(FluidBern) -------
    Bnd.FluidBern(Index).bSpline = False
End Sub

'////////////////////////////////////////////////////////////
'    Boundary�̐ݒ� Boundary���F���E����_002
'////////////////////////////////////////////////////////////
Sub BoundarySetUp_���E����_002()
    '------- Boundary��Index��ۑ�����ϐ� -------
    Dim Index As Integer

    '------- Boundary�̒ǉ� -------
    Bnd.Add "���E����_002" 

    '------- Boundary Index�̐ݒ� -------
    Index = Bnd.Ask ( "���E����_002" ) 

    '------- �d�C(Electrical) -------
    Bnd.Electrical(Index).Condition = ELECTRIC_WALL_C

    '------- �M(Thermal) -------
    Bnd.Thermal(Index).bConAuto = True
    Bnd.Thermal(Index).bSetRadioSetting = False

    '------- ����_�����x(RoomTemp) -------
    Bnd.Thermal(Index).RoomTemp.TempType = TEMP_AMBIENT_C

    '------- �t��(Emittivity) -------
    Bnd.Thermal(Index).Emittivity.Eps = (0.8)

    '------- ����(FluidBern) -------
    Bnd.FluidBern(Index).bSpline = False
End Sub

'////////////////////////////////////////////////////////////
'    IF�֐�
'////////////////////////////////////////////////////////////
Function F_IF(expression As Double, val_true As Double, val_false As Double) As Double
    If expression Then
        F_IF = val_true
    Else
        F_IF = val_false
    End If

End Function

'////////////////////////////////////////////////////////////
'    �ϐ���`�֐�
'////////////////////////////////////////////////////////////
Sub InitVariables()


    'VB��̕ϐ��̒�`
    pi = 3.1415926535897932
    width = 3
    depth = 3
    height = 3

    'FemtetGUI��̕ϐ��̓o�^�i�������f���̕ϐ����䓙�ł̂ݗ��p�j
    'Femtet.AddNewVariable "width", 3.00000000e+00
    'Femtet.AddNewVariable "depth", 3.00000000e+00
    'Femtet.AddNewVariable "height", 3.00000000e+00

End Sub

'////////////////////////////////////////////////////////////
'    ���f���쐬�֐�
'////////////////////////////////////////////////////////////
Sub MakeModel()

    '------- Body�z��ϐ��̒�` -------
    Dim Body() as CGaudiBody

    '------- ���f����`�悳���Ȃ��ݒ� -------
    Femtet.RedrawMode = False


    '------- CreateBox -------
    ReDim Preserve Body(0)
    Dim Point0 As new CGaudiPoint
    Point0.SetCoord 0, 0, 0
    Set Body(0) = Gaudi.CreateBox(Point0, width, depth, height)

    '------- SetName -------
    Body(0).SetName "�{�f�B����_001", "001_�A���~�i"

    '------- SetBoundary -------
    Dim Face0 As CGaudiFace
    Set Face0 = Body(0).GetFaceByID(36)
    Face0.SetBoundary "���E����_001"

    '------- SetBoundary -------
    Dim Face1 As CGaudiFace
    Set Face1 = Body(0).GetFaceByID(9)
    Face1.SetBoundary "���E����_002"


    '------- ���f�����ĕ`�悵�܂� -------
    Femtet.Redraw

End Sub

'////////////////////////////////////////////////////////////
'    �v�Z���ʒ��o�֐�
'////////////////////////////////////////////////////////////
Sub SamplingResult()

    '------- �ϐ��ɃI�u�W�F�N�g�̐ݒ� -------
    Set Gogh = Femtet.Gogh

    '------- ���݂̌v�Z���ʂ𒆊ԃt�@�C������J�� -------
    If Femtet.OpenCurrentResult(True) = False Then
        Femtet.ShowLastError
    End If

    '------- �t�B�[���h�̐ݒ� -------
    Gogh.Coulomb.Potential = COULOMB_VOLTAGE_C

    '------- �ő�l�̎擾 -------
    Dim PosMax() As Double '�ő�l�̍��W
    Dim ResultMax As Double ' �ő�l

    If Gogh.Coulomb.GetMAXPotentialPoint(CMPX_REAL_C, PosMax, ResultMax) = False Then
        Femtet.ShowLastError
    End If

    '------- �ŏ��l�̎擾 -------
    Dim PosMin() As Double '�ŏ��l�̍��W
    Dim ResultMin As Double '�ŏ��l

    If Gogh.Coulomb.GetMINPotentialPoint(CMPX_REAL_C, PosMin, ResultMin) = False Then
        Femtet.ShowLastError
    End If

    '------- �C�Ӎ��W�̌v�Z���ʂ̎擾 -------
    Dim Value As New CComplex

    If Gogh.Coulomb.GetPotentialAtPoint(3, 3, 0, Value) = False Then
        Femtet.ShowLastError
    End If

    ' �����̍��W�̌��ʂ��܂Ƃ߂Ď擾����ꍇ�́AMultiGetPotentialAtPoint�֐��������p���������B

End Sub

