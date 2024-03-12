import plotly.graph_objs as go
import plotly.express as px


CUSTOM_DATA_DICT = {'trial': 0}  # 連番


class ColorSet:
    non_domi = {True: '#007bff', False: '#6c757d'}  # color


class SymbolSet:
    feasible = {True: 'circle', False: 'circle-open'}  # style


class LanguageSet:

    feasible = {'label': 'feasible', True: True, False: False}
    non_domi = {'label': 'non_domi', True: True, False: False}

    def __init__(self, language: str = 'ja'):
        self.lang = language
        if self.lang.lower() == 'ja':
            self.feasible = {'label': '拘束条件', True: '満足', False: '違反'}
            self.non_domi = {'label': '最適性', True: '非劣解', False: '劣解'}

    def localize(self, history, df):
        # 元のオブジェクトを変更しないようにコピー
        cdf = df.copy()

        # feasible, non_domi の localize
        cdf[self.feasible['label']] = [self.feasible[v] for v in cdf['feasible']]
        cdf[self.non_domi['label']] = [self.non_domi[v] for v in cdf['non_domi']]

        # obj_names から prefix を除去
        columns = cdf.columns
        columns = [n[len(history.OBJ_PREFIX):] if n.startswith(history.OBJ_PREFIX) else n for n in columns]
        cdf.columns = columns
        return cdf


ls = LanguageSet('ja')
cs = ColorSet()
ss = SymbolSet()


def update_hypervolume_plot(history, df):
    df = ls.localize(history, df)

    # create figure
    fig = px.line(
        df,
        x="trial",
        y="hypervolume",
        markers=True,
        custom_data=CUSTOM_DATA_DICT.keys(),
    )

    fig.update_layout(
        dict(
            title_text="ハイパーボリュームプロット",
        )
    )

    return fig


def update_default_figure(history, df):

    # data setting
    obj_names = history.obj_names

    if len(obj_names) == 0:
        return go.Figure()

    elif len(obj_names) == 1:
        return update_single_objective_plot(history, df)

    elif len(obj_names) >= 2:
        return update_multi_objective_pairplot(history, df)


def update_single_objective_plot(history, df):

    df = ls.localize(history, df)
    obj_name = history.obj_names[0]

    fig = px.scatter(
        df,
        x='trial',
        y=obj_name,
        symbol=ls.feasible['label'],
        symbol_map={
            ls.feasible[True]: ss.feasible[True],
            ls.feasible[False]: ss.feasible[False],
        },
        hover_data={
            ls.feasible['label']: False,
            'trial': True,
        },
        custom_data=CUSTOM_DATA_DICT.keys(),
    )

    fig.add_trace(
        go.Scatter(
            x=df['trial'],
            y=df[obj_name],
            mode="lines",
            line=go.scatter.Line(
                width=0.5,
                color='#6c757d',
            ),
            showlegend=False
        )
    )

    fig.update_layout(
        dict(
            title_text="目的プロット",
            xaxis_title="解析実行回数(回)",
            yaxis_title=obj_name,
        )
    )

    return fig


def update_multi_objective_pairplot(history, df):
    df = ls.localize(history, df)

    obj_names = history.obj_names

    common_kwargs = dict(
        color=ls.non_domi['label'],
        color_discrete_map={
            ls.non_domi[True]: cs.non_domi[True],
            ls.non_domi[False]: cs.non_domi[False],
        },
        symbol=ls.feasible['label'],
        symbol_map={
            ls.feasible[True]: ss.feasible[True],
            ls.feasible[False]: ss.feasible[False],
        },
        hover_data={
            ls.feasible['label']: False,
            'trial': True,
        },
        custom_data=CUSTOM_DATA_DICT.keys(),
        category_orders={
            ls.feasible['label']: (ls.feasible[False], ls.feasible[True]),
            ls.non_domi['label']: (ls.non_domi[False], ls.non_domi[True]),
        },
    )

    if len(obj_names) == 2:
        fig = px.scatter(
            data_frame=df,
            x=obj_names[0],
            y=obj_names[1],
            **common_kwargs,
        )
        fig.update_layout(
            dict(
                xaxis_title=obj_names[0],
                yaxis_title=obj_names[1],
            )
        )

    else:
        fig = px.scatter_matrix(
            data_frame=df,
            dimensions=obj_names,
            **common_kwargs,
        )
        fig.update_traces(
            patch={'diagonal.visible': False},
            showupperhalf=False,
        )

    fig.update_layout(
        dict(
            title_text="多目的ペアプロット",
        )
    )

    return fig


def _debug():
    import os

    os.chdir(os.path.dirname(__file__))
    csv_path = '_sample_history_include_infeasible_1obj.csv'

    show_static_monitor(csv_path)


def show_static_monitor(csv_path):
    from pyfemtet.opt.core import History
    from pyfemtet.opt.visualization._monitor import StaticMonitor
    _h = History(history_path=csv_path)
    _monitor = StaticMonitor(history=_h)
    _monitor.run()


def entry_point():
    import argparse
    parser = argparse.ArgumentParser()

    parser.add_argument('csv_path', help='pyfemtet を実行した結果の csv ファイルのパスを指定してください。', type=str)

    # parser.add_argument(
    #     "-c",
    #     "--csv-path",
    #     help="pyfemtet.opt による最適化結果 csv ファイルパス",
    #     type=str,
    # )

    args = parser.parse_args()

    if args.csv_path:
        show_static_monitor(args.csv_path)


if __name__ == '__main__':
    _debug()
