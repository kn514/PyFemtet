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
Private c_pi as Double
Private r as Double
Private h as Double
Private p as Double
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
    ProjectFilePath = "C:\Users\mm11592\Documents\myFiles2\working\1_PyFemtetOpt\PyFemtetOptDevelopment\PyFemtetOptProject\src\PyFemtet\FemtetPJTSample\TEST_NX\TEST_femprj"
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
    Als.AnalysisType = PASCAL_C

    '------- ����(Gauss) -------
    Als.Gauss.b2ndEdgeElement = True

    '------- ����(Galileo) -------
    Als.Galileo.PenetrateTolerance = (1.0) * 10 ^ (-3)

    '------- �d���g(Hertz) -------
    Als.Hertz.b2ndEdgeElement = True

    '------- ���d(Rayleigh) -------
    Als.Rayleigh.bConstantTemp = True

    '------- ���x�Ȑݒ�(HighLevel) -------
    Als.HighLevel.nNonL = (20)
    Als.HighLevel.bATS = False
    Als.HighLevel.FactorType = RADIO_ANALYTICAL_C
    Als.HighLevel.bUseDeathMaterial = False

    '------- ���b�V���̐ݒ�(MeshProperty) -------
    Als.MeshProperty.AdaptiveTolPort = (1.0) * 10 ^ (-2)
    Als.MeshProperty.AutoAirMeshSize = (180.0)
    Als.MeshProperty.bChangePlane = True
    Als.MeshProperty.bMeshG2 = True
    Als.MeshProperty.bPeriodMesh = False

    '------- �d���E(Volta) -------
    Als.Volta.b2ndEdgeElement = True

    '------- �����X�e�b�v�ݒ�(StepAnalysis) -------
    Als.StepAnalysis.bSetTime = True
    Als.StepAnalysis.Set_Table_withTime 0, (1.0), (20), (0.0)
    Als.StepAnalysis.BreakStep = (100)
End Sub

'////////////////////////////////////////////////////////////
'    Body�����S�̂̐ݒ�
'////////////////////////////////////////////////////////////
Sub BodyAttributeSetUp()

    '------- �ϐ��ɃI�u�W�F�N�g�̐ݒ� -------
    Set BodyAttr = Femtet.BodyAttribute

    '------- Body�����̐ݒ� -------
    BodyAttributeSetUp_Air
    BodyAttributeSetUp_�ő�
End Sub

'////////////////////////////////////////////////////////////
'    Body�����̐ݒ� Body�������FAir
'////////////////////////////////////////////////////////////
Sub BodyAttributeSetUp_Air()
    '------- Body������Index��ۑ�����ϐ� -------
    Dim Index As Integer

    '------- Body�����̒ǉ� -------
    BodyAttr.Add "Air" 

    '------- Body���� Index�̐ݒ� -------
    Index = BodyAttr.Ask ( "Air" ) 

    '------- �V�[�g�{�f�B�̌��� or 2������͂̉��s��(BodyThickness)/���C���[�{�f�B��(WireWidth) -------
    BodyAttr.Length(Index).bUseAnalysisThickness2D = False

    '------- �ő�/����(SolidLiquidGas) -------
    BodyAttr.SolidLiquidGas(Index).State = GAS_C

    '------- �������x(InitialVelocity) -------
    BodyAttr.InitialVelocity(Index).bAnalysisUse = False

    '------- �t��(Emittivity) -------
    BodyAttr.ThermalSurface(Index).Emittivity.Eps = (0.8)
End Sub

'////////////////////////////////////////////////////////////
'    Body�����̐ݒ� Body�������F�ő�
'////////////////////////////////////////////////////////////
Sub BodyAttributeSetUp_�ő�()
    '------- Body������Index��ۑ�����ϐ� -------
    Dim Index As Integer

    '------- Body�����̒ǉ� -------
    BodyAttr.Add "�ő�" 

    '------- Body���� Index�̐ݒ� -------
    Index = BodyAttr.Ask ( "�ő�" ) 

    '------- �V�[�g�{�f�B�̌��� or 2������͂̉��s��(BodyThickness)/���C���[�{�f�B��(WireWidth) -------
    BodyAttr.Length(Index).bUseAnalysisThickness2D = False

    '------- �������x(InitialVelocity) -------
    BodyAttr.InitialVelocity(Index).bAnalysisUse = False

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
    MaterialSetUp_�ő�
    MaterialSetUp_000_��C

    '+++++++++++++++++++++++++++++++++++++++++
    '++�g�p����Ă��Ȃ�Material�f�[�^�ł�
    '++�g�p����ۂ̓R�����g���O���ĉ�����
    '+++++++++++++++++++++++++++++++++++++++++
    'MaterialSetUp_001_�A���~�i
    'MaterialSetUp_006_�K���X�G�|�L�V
    'MaterialSetUp_008_��Cu
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

    '------- ���c���W��(Expansion) -------
    Mtl.Expansion(Index).sAlf = (0.0)
    Mtl.Expansion(Index).Set_vAlf 0, (0.0)
    Mtl.Expansion(Index).Set_vAlf 1, (0.0)
    Mtl.Expansion(Index).Set_vAlf 2, (0.0)

    '------- �S�x(Viscosity) -------
    Mtl.Viscosity(Index).Mu = (1.002) * 10 ^ (-3)

    '------- ����(Magnetize) -------
    Mtl.Magnetize(Index).MagRatioType = MAGRATIO_BR_C
End Sub

'////////////////////////////////////////////////////////////
'    Material�̐ݒ� Material���F006_�K���X�G�|�L�V
'////////////////////////////////////////////////////////////
Sub MaterialSetUp_006_�K���X�G�|�L�V()
    '------- Material��Index��ۑ�����ϐ� -------
    Dim Index As Integer

    '------- Material�̒ǉ� -------
    Mtl.Add "006_�K���X�G�|�L�V" 

    '------- Material Index�̐ݒ� -------
    Index = Mtl.Ask ( "006_�K���X�G�|�L�V" ) 

    '------- ���c���W��(Expansion) -------
    Mtl.Expansion(Index).sAlf = (0.0)
    Mtl.Expansion(Index).Set_vAlf 0, (0.0)
    Mtl.Expansion(Index).Set_vAlf 1, (0.0)
    Mtl.Expansion(Index).Set_vAlf 2, (0.0)

    '------- �S�x(Viscosity) -------
    Mtl.Viscosity(Index).Mu = (1.002) * 10 ^ (-3)

    '------- ����(Magnetize) -------
    Mtl.Magnetize(Index).MagRatioType = MAGRATIO_BR_C
End Sub

'////////////////////////////////////////////////////////////
'    Material�̐ݒ� Material���F008_��Cu
'////////////////////////////////////////////////////////////
Sub MaterialSetUp_008_��Cu()
    '------- Material��Index��ۑ�����ϐ� -------
    Dim Index As Integer

    '------- Material�̒ǉ� -------
    Mtl.Add "008_��Cu" 

    '------- Material Index�̐ݒ� -------
    Index = Mtl.Ask ( "008_��Cu" ) 

    '------- ���c���W��(Expansion) -------
    Mtl.Expansion(Index).sAlf = (0.0)
    Mtl.Expansion(Index).Set_vAlf 0, (0.0)
    Mtl.Expansion(Index).Set_vAlf 1, (0.0)
    Mtl.Expansion(Index).Set_vAlf 2, (0.0)

    '------- �S�x(Viscosity) -------
    Mtl.Viscosity(Index).Mu = (1.002) * 10 ^ (-3)

    '------- ����(Magnetize) -------
    Mtl.Magnetize(Index).MagRatioType = MAGRATIO_BR_C
End Sub

'////////////////////////////////////////////////////////////
'    Material�̐ݒ� Material���F�ő�
'////////////////////////////////////////////////////////////
Sub MaterialSetUp_�ő�()
    '------- Material��Index��ۑ�����ϐ� -------
    Dim Index As Integer

    '------- Material�̒ǉ� -------
    Mtl.Add "�ő�" 

    '------- Material Index�̐ݒ� -------
    Index = Mtl.Ask ( "�ő�" ) 

    '------- ���c���W��(Expansion) -------
    Mtl.Expansion(Index).sAlf = (0.0)
    Mtl.Expansion(Index).Set_vAlf 0, (0.0)
    Mtl.Expansion(Index).Set_vAlf 1, (0.0)
    Mtl.Expansion(Index).Set_vAlf 2, (0.0)

    '------- �S�x(Viscosity) -------
    Mtl.Viscosity(Index).Mu = (1.002) * 10 ^ (-3)

    '------- ����(Magnetize) -------
    Mtl.Magnetize(Index).MagRatioType = MAGRATIO_BR_C
End Sub

'////////////////////////////////////////////////////////////
'    Material�̐ݒ� Material���F000_��C
'////////////////////////////////////////////////////////////
Sub MaterialSetUp_000_��C()
    '------- Material��Index��ۑ�����ϐ� -------
    Dim Index As Integer

    '------- Material�̒ǉ� -------
    Mtl.Add "000_��C" 

    '------- Material Index�̐ݒ� -------
    Index = Mtl.Ask ( "000_��C" ) 

    '------- ���c���W��(Expansion) -------
    Mtl.Expansion(Index).sAlf = (0.0)
    Mtl.Expansion(Index).Set_vAlf 0, (0.0)
    Mtl.Expansion(Index).Set_vAlf 1, (0.0)
    Mtl.Expansion(Index).Set_vAlf 2, (0.0)

    '------- �S�x(Viscosity) -------
    Mtl.Viscosity(Index).Mu = (1.002) * 10 ^ (-3)

    '------- �ő�/����(SolidFluid) -------
    Mtl.SolidFluid(Index).State = FLUID_C

    '------- ����(Magnetize) -------
    Mtl.Magnetize(Index).MagRatioType = MAGRATIO_BR_C
End Sub

'////////////////////////////////////////////////////////////
'    Boundary�S�̂̐ݒ�
'////////////////////////////////////////////////////////////
Sub BoundarySetUp()

    '------- �ϐ��ɃI�u�W�F�N�g�̐ݒ� -------
    Set Bnd = Femtet.Boundary

    '------- Boundary�̐ݒ� -------
    BoundarySetUp_RESERVED_default
    BoundarySetUp_in
    BoundarySetUp_out
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
    Bnd.Thermal(Index).bConAuto = False
    Bnd.Thermal(Index).bSetRadioSetting = False

    '------- ����_�����x(RoomTemp) -------
    Bnd.Thermal(Index).RoomTemp.TempType = TEMP_AMBIENT_C
    Bnd.Thermal(Index).RoomTemp.Temp = (0.0)

    '------- �t��(Emittivity) -------
    Bnd.Thermal(Index).Emittivity.Eps = (0.999)

    '------- ����(FluidBern) -------
    Bnd.FluidBern(Index).P = (0.0)
    Bnd.FluidBern(Index).bSpline = True

    '------- ���z(Distribution) -------
    Bnd.FluidBern(Index).TempType = TEMP_DIRECT_C
End Sub

'////////////////////////////////////////////////////////////
'    Boundary�̐ݒ� Boundary���Fin
'////////////////////////////////////////////////////////////
Sub BoundarySetUp_in()
    '------- Boundary��Index��ۑ�����ϐ� -------
    Dim Index As Integer

    '------- Boundary�̒ǉ� -------
    Bnd.Add "in" 

    '------- Boundary Index�̐ݒ� -------
    Index = Bnd.Ask ( "in" ) 

    '------- �M(Thermal) -------
    Bnd.Thermal(Index).bConAuto = False
    Bnd.Thermal(Index).bSetRadioSetting = False

    '------- ����_�����x(RoomTemp) -------
    Bnd.Thermal(Index).RoomTemp.TempType = TEMP_AMBIENT_C
    Bnd.Thermal(Index).RoomTemp.Temp = (0.0)

    '------- �t��(Emittivity) -------
    Bnd.Thermal(Index).Emittivity.Eps = (0.999)

    '------- ����(Fluid) -------
    Bnd.Fluid(Index).Condition = VELOCITY_POTENTIAL_C
    Bnd.Fluid(Index).Vel = (1)
    Bnd.Fluid(Index).VP = (p)

    '------- ����(FluidBern) -------
    Bnd.FluidBern(Index).P = (0.0)
    Bnd.FluidBern(Index).bSpline = True

    '------- ���z(Distribution) -------
    Bnd.FluidBern(Index).TempType = TEMP_DIRECT_C
End Sub

'////////////////////////////////////////////////////////////
'    Boundary�̐ݒ� Boundary���Fout
'////////////////////////////////////////////////////////////
Sub BoundarySetUp_out()
    '------- Boundary��Index��ۑ�����ϐ� -------
    Dim Index As Integer

    '------- Boundary�̒ǉ� -------
    Bnd.Add "out" 

    '------- Boundary Index�̐ݒ� -------
    Index = Bnd.Ask ( "out" ) 

    '------- �M(Thermal) -------
    Bnd.Thermal(Index).bConAuto = False
    Bnd.Thermal(Index).bSetRadioSetting = False

    '------- ����_�����x(RoomTemp) -------
    Bnd.Thermal(Index).RoomTemp.TempType = TEMP_AMBIENT_C
    Bnd.Thermal(Index).RoomTemp.Temp = (0.0)

    '------- �t��(Emittivity) -------
    Bnd.Thermal(Index).Emittivity.Eps = (0.999)

    '------- ����(Fluid) -------
    Bnd.Fluid(Index).Condition = VELOCITY_POTENTIAL_C

    '------- ����(FluidBern) -------
    Bnd.FluidBern(Index).P = (0.0)
    Bnd.FluidBern(Index).bSpline = True

    '------- ���z(Distribution) -------
    Bnd.FluidBern(Index).TempType = TEMP_DIRECT_C
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
    c_pi = 3.1415926535897932
    r = 50
    h = 50
    p = 0.5

    'FemtetGUI��̕ϐ��̓o�^�i�������f���̕ϐ����䓙�ł̂ݗ��p�j
    'Femtet.AddNewVariable "c_pi", 3.14159265e+00
    'Femtet.AddNewVariable "r", 5.00000000e+01
    'Femtet.AddNewVariable "h", 5.00000000e+01
    'Femtet.AddNewVariable "p", 5.00000000e-01

End Sub

'////////////////////////////////////////////////////////////
'    ���f���쐬�֐�
'////////////////////////////////////////////////////////////
Sub MakeModel()

    '------- Body�z��ϐ��̒�` -------
    Dim Body() as CGaudiBody

    '------- ���f����`�悳���Ȃ��ݒ� -------
    Femtet.RedrawMode = False


    '------- SetPlane -------
    Dim Plane0 As new CGaudiPlane
    Plane0.Location.SetCoord 0.0, 0.0, 0.0
    Plane0.MainDirection.SetCoord 0.0, 1.0, 0.0
    Plane0.RefDirection.SetCoord 0.0, 0.0, 1.0
    Gaudi.SetPlane Plane0

    '------- CreateCylinder -------
    ReDim Preserve Body(0)
    Dim Point0 As new CGaudiPoint
    Point0.SetCoord 0, 0, 0
    Set Body(0) = Gaudi.CreateCylinder(Point0, 100, 300)

    '------- CreateCylinder -------
    ReDim Preserve Body(1)
    Dim Point1 As new CGaudiPoint
    Point1.SetCoord 0, 150-h/2, 0
    Set Body(1) = Gaudi.CreateCylinder(Point1, r, h)

    '------- SetName -------
    Body(0).SetName "Air", "000_��C"

    '------- SetName -------
    Body(1).SetName "�ő�", "�ő�"

    '------- AddBoundary -------
    Dim Face0 As CGaudiFace
    Set Face0 = Body(0).GetFaceByID(9)
    Face0.AddBoundary "in"

    '------- AddBoundary -------
    Dim Face1 As CGaudiFace
    Set Face1 = Body(0).GetFaceByID(15)
    Face1.AddBoundary "out"


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
    Gogh.Pascal.Vector = PASCAL_VELOCITY_C

    '------- �ő�l�̎擾 -------
    Dim PosMax() As Double '�ő�l�̍��W
    Dim ResultMax As Double ' �ő�l

    If Gogh.Pascal.GetMAXVectorPoint(VEC_C, CMPX_REAL_C, PosMax, ResultMax) = False Then
        Femtet.ShowLastError
    End If

    '------- �ŏ��l�̎擾 -------
    Dim PosMin() As Double '�ŏ��l�̍��W
    Dim ResultMin As Double '�ŏ��l

    If Gogh.Pascal.GetMINVectorPoint(VEC_C, CMPX_REAL_C, PosMin, ResultMin) = False Then
        Femtet.ShowLastError
    End If

    '------- �C�Ӎ��W�̌v�Z���ʂ̎擾 -------
    Dim Value() As New CComplex

    If Gogh.Pascal.GetVectorAtPoint(0, 0, 0, Value()) = False Then
        Femtet.ShowLastError
    End If

    ' �����̍��W�̌��ʂ��܂Ƃ߂Ď擾����ꍇ�́AMultiGetVectorAtPoint�֐��������p���������B

End Sub

