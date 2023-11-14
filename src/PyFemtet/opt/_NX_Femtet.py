import os
import json
from time import sleep
from multiprocessing import Pool
import subprocess

from win32com.client import Dispatch, DispatchEx
import win32process
import win32api
import win32con

import numpy as np

here, me = os.path.split(__file__)


# ユーザーが案件ごとに設定する変数
# path_bas = r"C:\Users\mm11592\Documents\myFiles2\working\PyFemtetOpt2\PyFemtetOptGit\NXTEST.bas"
# path_prt = r"C:\Users\mm11592\Documents\myFiles2\working\PyFemtetOpt2\PyFemtetOptGit\NXTEST.prt"

# ユーザーが環境ごとに設定する定数
PATH_MACRO = r'C:\Program Files\Femtet_Ver2023.1.0_64bit\Program\Macro32\FemtetMacro.dll'
PATH_REF = r'C:\Program Files\Femtet_Ver2023.1.0_64bit\Program\Macro32\FemtetRef.xla'
# TODO: Femtet のプロセスハンドルか何かから得られるようにする

# ユーザーは設定しない定数
PATH_JOURNAL = os.path.abspath(os.path.join(here, 'update_model_parameter.py'))



def _f(functions, arguments): # インスタンスメソッドにしたら動かない クラスメソッドにしても動かない。なんでだろう？
    # 新しいプロセスで呼ぶ関数。
    # 新しい Femtet を作って objectives を計算する
    # その後、プロセスは死ぬので Femtet は解放される
    # TODO:この関数の最後で、Femtet を殺していいかどうか検討する
    Femtet = Dispatch('FemtetMacro.Femtet')
    Femtet.Gaudi.Mesh()
    Femtet.Solve()
    Femtet.OpenCurrentResult(True)
    ret = []
    for func, (args, kwargs) in zip(functions, arguments):
        ret.append(func(Femtet, *args, **kwargs))
    return ret

from PyFemtet.opt.core import FEMSystem

class NX_Femtet(FEMSystem):
    def __init__(self, path_prt):
        self._path_prt = os.path.abspath(path_prt)
        self._path_bas = None
        self._path_xlsm = None
    
    def set_bas(self, path_bas):
        self._path_bas = os.path.abspath(path_bas)
        self._path_xlsm = None

    def set_excel(self, path_xlsx):
        self._path_xlsm = os.path.abspath(path_xlsx)
        self._path_bas = None
            
    def run(self):
        # 使わないけど FEMSystem が実装を求めるためダミーで作成
        pass
    
    def f(self, df, objectives):
        from PyFemtet.opt.core import ModelError, MeshError, SolveError

        try:
            self._update_model(df)
        except:
            raise ModelError

        try:
            self._setup_new_Femtet()
        except:
            raise ModelError

        try:
            self._run_new_Femtet(objectives)
        except:
            raise SolveError
 
        return self.objectiveValues
            
    def _update_model(self, df):
        # run_journal を使って prt から x_t を作る
        exe = r'%UGII_BASE_DIR%\NXBIN\run_journal.exe'
        tmp = dict(zip(df.name.values, df.value.values.astype(str)))
        strDict = json.dumps(tmp)
        env = os.environ.copy()
        subprocess.run(
            [exe, PATH_JOURNAL, '-args', self._path_prt, strDict],
            env=env,
            shell=True,
            cwd=os.path.dirname(self._path_prt))
        # prt と同じ名前の x_t ができる

    def _set_reference_of_new_excel(self, wb):
        try:
            wb.VBProject.References.AddFromFile(PATH_MACRO)
        except:
            pass
        try:
            wb.VBProject.References.AddFromFile(PATH_REF)
        except:
            pass
        
    
    def _setup_new_Femtet(self):
        # excel 経由で bas を使って x_t から Femtet のセットアップをする
        # その後、excel は殺す
        # excel の立ち上げ
        self.excel = DispatchEx("Excel.Application")
        self.excel.Visible = False
        self.excel.DisplayAlerts = False
        
        # bas 指定の場合：新しい xlsm を作る
        if self._path_bas is not None:
            # wb の準備
            wb = self.excel.Workbooks.Add()
            # マクロのセットアップ
            wb.VBProject.VBComponents.Import(self._path_bas)
            self._set_reference_of_new_excel(wb)

        # xlsm 指定の場合：開く
        elif self._path_xlsm is not None:
            # wb の準備
            wb = self.excel.Workbooks.Open(self._path_xlsm)
            # マクロのセットアップ
            self._set_reference_of_new_excel(wb)


        # Femtet セットアップの実行
        self.excel.Run('FemtetMacro.FemtetMain')

        # # マクロの破棄
        # if self._path_bas is not None:
        #     self.excel.Run('HubModule.ReleaseFemtetMacroBas')    
        #     self.excel.Run('HubModule.ReleaseReference', 'FemtetMacro')
        #     self.excel.Run('HubModule.ReleaseReference', 'FemtetReference')

        # 保存せずに閉じる
        wb.Saved = True
        wb.Close()

        # 終了
        self._close_excel_by_force()

    def _run_new_Femtet(self, objectives):
        # 関数を適用する
        with Pool(processes=1) as p:
            functions = [obj.ptrFunc for obj in objectives]
            arguments = [(obj.args, obj.kwargs) for obj in objectives]
            result = p.apply(_f, (functions, arguments))
            self.objectiveValues = result
        
    def _close_excel_by_force(self):
        # プロセス ID の取得
        hwnd = self.excel.Hwnd
        _, p = win32process.GetWindowThreadProcessId(hwnd)
        # force close
        try:
            handle = win32api.OpenProcess(win32con.PROCESS_TERMINATE, 0, p)
            if handle:
                win32api.TerminateProcess(handle, 0)
                win32api.CloseHandle(handle)
        except:
            pass



# #### サンプル関数
# from win32com.client import constants
# def get_flow(Femtet):
#     Gogh = Femtet.Gogh
#     Gogh.Pascal.Vector = constants.PASCAL_VELOCITY_C
#     _, ret = Gogh.SimpleIntegralVectorAtFace_py([2], [0], constants.PART_VEC_Y_PART_C)
#     flow = ret.Real
#     return flow


# if __name__=='__main__':
#     FEMOpt = NX_Femtet()
#     df = None
#     print(FEMOpt.f(df, [get_flow]))
    