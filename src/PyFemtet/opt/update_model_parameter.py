import os
import sys
import json
import NXOpen


def main(prtPath:str, parameters:'dict as str'):
    '''
    .prt ファイルのパスを受け取り、parameters に指定された変数を更新し、
    .prt と同じディレクトリに .x_t ファイルをエクスポートする

    Parameters
    ----------
    prtPath : str
        DESCRIPTION.
    parameters : 'dict as str'
        DESCRIPTION.

    Returns
    -------
    None.

    '''
    # 保存先の設定
    prtPath = os.path.abspath(prtPath) # 一応
    x_tPath = os.path.splitext(prtPath)[0] + '.x_t'

    # 辞書の作成
    parameters = json.loads(parameters)
    
    # session の取得とパートを開く
    theSession = NXOpen.Session.GetSession()
    theSession.Parts.OpenActiveDisplay(prtPath, NXOpen.DisplayPartOption.AllowAdditional)
    theSession.ApplicationSwitchImmediate("UG_APP_MODELING")

    # part の設定
    workPart = theSession.Parts.Work
    displayPart = theSession.Parts.Display

    # 式を更新
    unit_mm = workPart.UnitCollection.FindObject("MilliMeter")
    for k, v in parameters.items():
        exp = workPart.Expressions.FindObject(k)
        workPart.Expressions.EditWithUnits(exp, unit_mm, str(v))
        # 式の更新を適用
        id1 = theSession.NewestVisibleUndoMark
        nErrs1 = theSession.UpdateManager.DoUpdate(id1)


    # parasolid のエクスポート
    parasolidExporter1 = theSession.DexManager.CreateParasolidExporter()

    parasolidExporter1.ObjectTypes.Curves = False
    parasolidExporter1.ObjectTypes.Surfaces = False
    parasolidExporter1.ObjectTypes.Solids = True
    
    parasolidExporter1.InputFile = prtPath
    parasolidExporter1.ParasolidVersion = NXOpen.ParasolidExporter.ParasolidVersionOption.Current
    parasolidExporter1.OutputFile = x_tPath
    
    parasolidExporter1.Commit()

    parasolidExporter1.Destroy()
    



if __name__ == "__main__":
    print('---script started---')
    print('current directory: ', os.getcwd())
    print('arguments: ')
    for arg in sys.argv[1:]:
        print('  ', arg)

    main(*sys.argv[1:])
    print('---script end---')
