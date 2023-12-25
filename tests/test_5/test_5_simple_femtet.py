import os
import numpy as np
import pandas as pd
from pyfemtet.opt import OptimizerOptuna, FemtetInterface


os.chdir(os.path.dirname(__file__))
record = True


def max_disp(Femtet):
    return Femtet.Gogh.Galileo.GetMaxDisplacement_py()[1]


def volume(Femtet, femopt):
    d, h, _ = femopt.get_parameter('values')
    w = Femtet.GetVariableValue('w')
    return d * h * w


def bottom_surface(_, femopt):
    d, h, w = femopt.get_parameter('values')
    return d * w


def test_simple_femtet():
    """
    テストしたい状況
        Femtet で一通りの機能が動くか
    結果
        結果が保存したものと一致するか
    """

    fem = FemtetInterface('test_5_simple_femtet.femprj')
    femopt = OptimizerOptuna(fem)
    femopt.set_random_seed(42)
    femopt.add_parameter('d', 5, 1, 10)
    femopt.add_parameter('h', 5, 1, 10)
    femopt.add_parameter('w', 5, 1, 10)
    femopt.add_objective(max_disp)  # 名前なし目的変数（obj_0 になる）
    femopt.add_objective(max_disp)  # 名前なし目的変数（obj_1 になる）
    femopt.add_objective(volume, 'volume(mm3)', args=femopt)
    femopt.add_objective(volume, 'volume(mm3)', args=femopt)  # 上書き
    femopt.add_constraint(bottom_surface, 'surf<=20', upper_bound=20, args=femopt)
    femopt.main(n_trials=30, n_parallel=1)
    femopt.terminate_monitor()

    if record:
        # データの保存
        femopt.history.data.to_csv('test_5.csvdata')

    else:
        # データの取得
        ref_df = pd.read_csv('test_5.csvdata').replace(np.nan, None)
        def_df = femopt.history.data.copy()

        # 並べ替え（並列しているから順番は違いうる）
        ref_df = ref_df.iloc[:, 1:].sort_values('d').sort_values('h').sort_values('w').select_dtypes(include='number')
        def_df = def_df.iloc[:, 1:].sort_values('d').sort_values('h').sort_values('w').select_dtypes(include='number')

        assert np.sum(np.abs(def_df.values - ref_df.values)) < 0.001


def simple():
    """シンプルな動作確認用"""

    path = os.path.join(os.path.dirname(__file__), 'test_5_simple_femtet.femprj')

    fem = FemtetInterface(path)
    femopt = OptimizerOptuna(fem)
    femopt.set_random_seed(42)
    femopt.add_parameter('d', 5, 1, 10)
    femopt.add_parameter('h', 5, 1, 10)
    femopt.add_parameter('w', 5, 1, 10)
    femopt.add_objective(max_disp, '最大変位(m)')
    femopt.add_objective(volume, '体積(mm3)', args=femopt)
    femopt.add_constraint(bottom_surface, '底面積<=20', upper_bound=30, args=femopt)
    femopt.main(n_trials=30, n_parallel=3)
    femopt.terminate_monitor()



if __name__ == '__main__':
    test_simple_femtet()


