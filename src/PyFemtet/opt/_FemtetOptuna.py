import os
import datetime

import numpy as np
import pandas as pd

from .core import FemtetOptimizationCore

import optuna
import logging



# https://optuna.readthedocs.io/en/stable/index.html
class FemtetOptuna(FemtetOptimizationCore):

    def __init__(self, setFemtet='catch'):
        self._constraints = []
        super().__init__(setFemtet)

    def main(self, historyPath:str or None = None, timeout=None, n_trials=None, study_name=None):
        if historyPath is None:
            if self.historyPath is None:
                name = datetime.datetime.now().strftime('%Y_%m_%d_%H_%M')
                self.historyPath = os.path.join(os.getcwd(), f'{name}.csv')
            else:
                pass
        else:
            self.historyPath = historyPath

        if study_name is None:
            study_name = os.path.splitext(os.path.basename(self.historyPath))[0] + ".db"
            
        study_db_path = os.path.abspath(
            os.path.join(
                os.path.dirname(self.historyPath),
                study_name
                )
            )
        self.storage_name = f"sqlite:///{study_db_path}"
        self.timeout = timeout
        self.n_trials = n_trials
        super().main()
        
    def _main(self):
        #### 拘束のセットアップ
        self._parseConstraints()
        
        # 目的関数の設定
        def __objectives(trial):
            # 変数の設定
            x = []
            df = self.get_parameter('df')
            for i, row in df.iterrows():
                name = row['name']
                lb = row['lbound']
                ub = row['ubound']
                x.append(trial.suggest_float(name, lb, ub))
            x = np.array(x)

            # 計算実行
            ojectiveValuesToMinimize = self.f(x)

            # 拘束の設定
            constraintValuesToBeNotPositive = tuple([f(x) for f in self._constraints])

            # Store the constraints as user attributes so that they can be restored after optimization.
            trial.set_user_attr("constraint", constraintValuesToBeNotPositive)

            # 結果
            return tuple(ojectiveValuesToMinimize)

        # 拘束の設定（？）
        def __constraints(trial):
            return trial.user_attrs["constraint"]

        #### sampler の設定
        sampler = optuna.samplers.NSGAIISampler(constraints_func=__constraints)

        # #### study があったら消す
        # try:
        #     optuna.delete_study(
        #         study_name=self.study_name,
        #         storage=self.storage_name,
        #         )
        # except:
        #     pass

        #### study の設定
        study = optuna.create_study(
            study_name=self.study_name,
            storage=self.storage_name,
            load_if_exists=True,
            directions=['minimize']*len(self.objectives),
            sampler=sampler)

        #### study への初期値の設定
        # TODO: ラテンハイパーキューブサンプリングを初期値にする
        params = self.get_parameter('dict')
        study.enqueue_trial(params, user_attrs={"memo": "initial"})

        # study の実行
        study.optimize(__objectives, timeout=self.timeout, n_trials=self.n_trials)

        # 出力（あとで消す）
        # history とかの取得
        # df = study.trials_dataframe(attrs=("number", "value", "params", "state"))
        # print("Best params: ", study.best_params)
        # print("Best value: ", study.best_values)
        # print("Best Trial: ", study.best_trials)
        # print("Trials: ", study.trials)
        # print(df)
        
        return study


    def _createConstraintFun(self, x, i):
        if not self._isCalculated(x):
            self.f(x)
        return self.constraintValues[i]


    def _parseConstraints(self):
        '''与えられた拘束情報を optuna 形式に変換する'''
        self._constraints = []
        for i, constraint in enumerate(self.constraints):
            lb, ub = constraint.lb, constraint.ub
            # optuna で非正拘束にするためにそれぞれ関数を作る
            if lb is not None: # fun >= lb  <=>  lb - fun <= 0
                self._constraints.append(
                    lambda x,i=i,lb=lb:
                        lb - self._createConstraintFun(x, i)
                    )
            if ub is not None: # ub >= fun  <=>  fun - ub <= 0
                self._constraints.append(
                    lambda x,i=i,ub=ub:
                        self._createConstraintFun(x, i) - ub
                    )
            


if __name__=='__main__':
    FEMOpt = FemtetOptuna(None)
    
    # 変数の設定
    FEMOpt.add_parameter('r', 5, 0, 10)
    FEMOpt.add_parameter('theta', 0, -np.pi/2, np.pi/2)
    FEMOpt.add_parameter('fai', np.pi, 0, 2*np.pi)
    
    # 目的関数の設定
    def obj1(FEMOpt):
        r, theta, fai = FEMOpt.parameters['value'].values
        return r * np.cos(theta) * np.cos(fai)
    FEMOpt.add_objective(obj1, 'x', direction='maximize', args=(FEMOpt,))

    def obj2(FEMOpt):
        r, theta, fai = FEMOpt.parameters['value'].values
        return r * np.cos(theta) * np.sin(fai)
    FEMOpt.add_objective(obj2, 'y', args=(FEMOpt,)) # defalt direction is minimize

    def obj3(FEMOpt):
        r, theta, fai = FEMOpt.parameters['value'].values
        return r * np.sin(theta)
    FEMOpt.add_objective(obj3, 'z', direction=3, args=(FEMOpt,))


    # プロセスモニタの設定（experimental / 問題設定後実行直前に使うこと）
    FEMOpt.set_process_monitor()
    
    # 計算の実行
    study = FEMOpt.main()
    
    # 結果表示
    # print(FEMOpt.history)
    # print(study)
    
#     stop

#     #### ポスト
#     # https://optuna-readthedocs-io.translate.goog/en/stable/reference/visualization/index.html?_x_tr_sl=auto&_x_tr_tl=ja&_x_tr_hl=ja&_x_tr_pto=wapp

#     # You can use Matplotlib instead of Plotly for visualization by simply replacing `optuna.visualization` with
#     # `optuna.visualization.matplotlib` in the following examples.
#     from optuna.visualization.matplotlib import plot_contour
#     from optuna.visualization.matplotlib import plot_edf
#     from optuna.visualization.matplotlib import plot_intermediate_values
#     from optuna.visualization.matplotlib import plot_optimization_history
#     from optuna.visualization.matplotlib import plot_parallel_coordinate
#     from optuna.visualization.matplotlib import plot_param_importances
#     from optuna.visualization.matplotlib import plot_rank
#     from optuna.visualization.matplotlib import plot_slice
#     from optuna.visualization.matplotlib import plot_timeline
#     from optuna.visualization.matplotlib import plot_pareto_front
#     from optuna.visualization.matplotlib import plot_terminator_improvement
    
#     # 多分よくつかう
#     show_objective_index = [0,1,2]
    
#     ax = plot_pareto_front(
#         study,
#         targets = lambda trial: [trial.values[idx] for idx in show_objective_index]
#         )
    
#     # parate_front の scatter をクリックしたら値を表示するようにする
#     import matplotlib.pyplot as plt
#     from matplotlib.collections import PathCollection
    
#     def on_click(event):
#         ind = event.ind[0]
#         try:
#             x = event.artist._offsets3d[0][ind]
#             y = event.artist._offsets3d[1][ind]
#             z = event.artist._offsets3d[2][ind]
#             print(f"Clicked on point: ({x}, {y}, {z})")
#             costs = [x, y, z]
#         except:
#             x = event.artist._offsets[ind][0]
#             y = event.artist._offsets[ind][1]
#             print(f"Clicked on point: ({x}, {y})")
#             costs = [x, y]

#         for trial in study.trials:
#             paramsDict = trial.params
#             if costs==[trial.values[idx] for idx in show_objective_index]:
#                 print(paramsDict)
#                 try:
#                     print(trial.user_attrs['memo'])
#                 except:
#                     pass

#     def set_artist_picker(ax):
#         for artist in ax.get_children():
#             if isinstance(artist, PathCollection):
#                 artist.set_picker(True)

#     set_artist_picker(ax)
#     fig = ax.get_figure()
#     fig.canvas.mpl_connect('pick_event', on_click)
#     plt.show()





#     plot_optimization_history(study, target=lambda t: t.values[1])
#     # plot_contour(study, target=lambda t: t.values[1])
#     # plot_param_importances(study, target=lambda t: t.values[1])
#     # plot_slice(study, target=lambda t: t.values[1])
    
#     # # 多分あまり使わない
#     # plot_timeline(study)
#     # plot_edf(study, target=lambda t: t.values[0])
#     # plot_intermediate_values(study) # no-pruner study not supported
#     # plot_rank(study, target=lambda t: t.values[1])
#     # plot_terminator_improvement(study) # multiobjective not supported
    
    
    







# #### 並列処理
# if False:
#     from subprocess import Popen
    
#     # 元studyの作成
#     optuna.logging.get_logger("optuna").addHandler(logging.StreamHandler(sys.stdout))
#     study_name = "example-study"  # Unique identifier of the study.
#     storage_name = "sqlite:///{}.db".format(os.path.join(here, study_name))
#     study = optuna.create_study(study_name=study_name, storage=storage_name, load_if_exists=True)
    
    
#     path = os.path.join(here, '_optuna_dev.py')
#     pythonpath = r"C:\Users\mm11592\Documents\myFiles2\working\PyFemtetOpt\venvPyFemtetOpt\Scripts\python.exe c:\\users\\mm11592\\documents\\myfiles2\\working\\pyfemtetopt\\local\\pyfemtetopt\\pyfemtetopt\\core\\_optuna_dev.py example-study sqlite:///c:\\users\\mm11592\\documents\\myfiles2\\working\\pyfemtetopt\\local\\pyfemtetopt\\pyfemtetopt\\core\\example-study.db"
#     # Popen([pythonpath, path, study_name, storage_name])
#     # Popen([pythonpath, path, study_name, storage_name])
    
#     study = optuna.create_study(study_name=study_name, storage=storage_name, load_if_exists=True)
#     df = study.trials_dataframe(attrs=("number", "value", "params", "state"))
#     print(df)
    
#     optuna.delete_study(study_name, storage_name)

# #### 停止・再開
# if False:
#     # Add stream handler of stdout to show the messages
#     # 保存するための呪文
#     optuna.logging.get_logger("optuna").addHandler(logging.StreamHandler(sys.stdout))
#     study_name = "example-study"  # Unique identifier of the study.
#     storage_name = "sqlite:///{}.db".format(os.path.join(here, study_name))
#     study = optuna.create_study(study_name=study_name, storage=storage_name)
    
#     study.optimize(objective, n_trials=3)
    
#     # study.best_params  # E.g. {'x': 2.002108042}
    
#     # 再開
#     study = optuna.create_study(study_name=study_name, storage=storage_name, load_if_exists=True)
#     study.optimize(objective, n_trials=3)
    
    
#     # # sampler の seed をも restore するには以下の呪文を使う。
#     # import pickle
    
#     # # Save the sampler with pickle to be loaded later.
#     # with open("sampler.pkl", "wb") as fout:
#     #     pickle.dump(study.sampler, fout)
    
#     # restored_sampler = pickle.load(open("sampler.pkl", "rb"))
#     # study = optuna.create_study(
#     #     study_name=study_name, storage=storage_name, load_if_exists=True, sampler=restored_sampler
#     # )
#     # study.optimize(objective, n_trials=3)
    
    
#     # history とかの取得
#     study = optuna.create_study(study_name=study_name, storage=storage_name, load_if_exists=True)
#     df = study.trials_dataframe(attrs=("number", "value", "params", "state"))
#     print("Best params: ", study.best_params)
#     print("Best value: ", study.best_value)
#     print("Best Trial: ", study.best_trial)
#     print("Trials: ", study.trials)

