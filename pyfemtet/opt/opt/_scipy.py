# typing
import logging
from typing import Iterable

# built-in
import os

# 3rd-party
import numpy as np
import pandas as pd
import scipy.optimize
from scipy.optimize import minimize, OptimizeResult

# pyfemtet relative
from pyfemtet.opt._femopt_core import OptimizationStatus, generate_lhs
from pyfemtet.opt.opt import AbstractOptimizer, logger, OptimizationMethodChecker
from pyfemtet.core import MeshError, ModelError, SolveError


class StopIteration2(Exception):
    pass


class StopIterationCallback:
    def __init__(self, opt):
        self.opt: ScipyOptimizer = opt
        self.res: OptimizeResult = None

    def stop_iteration(self):
        # stop iteration gimmick
        # https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.minimize.html
        if self.opt.minimize_kwargs['method'] == "trust-constr":
            raise StopIteration2  # supports nothing
        elif (
                self.opt.minimize_kwargs['method'] == 'TNC'
                or self.opt.minimize_kwargs['method'] == 'SLSQP'
                or self.opt.minimize_kwargs['method'] == 'COBYLA'
        ):
            raise StopIteration2  # supports xk
        else:
            raise StopIteration  # supports xk , intermediate_result and StopIteration


    def __call__(self, xk=None, intermediate_result=None):
        self.res = intermediate_result
        if self.opt.entire_status.get() == OptimizationStatus.INTERRUPTING:
            self.opt.worker_status.set(OptimizationStatus.INTERRUPTING)
            self.stop_iteration()


class ScipyMethodChecker(OptimizationMethodChecker):
    def check_incomplete_bounds(self, raise_error=True): return True


class ScipyOptimizer(AbstractOptimizer):

    def __init__(
            self,
            **minimize_kwargs,
    ):
        """
        Args:
            **minimize_kwargs: Kwargs of `scipy.optimize.minimize`.
        """
        super().__init__()

        # define members
        self.minimize_kwargs: dict = dict(
            method='L-BFGS-B',
        )
        self.minimize_kwargs.update(minimize_kwargs)
        self.res: OptimizeResult = None
        self.method_checker: OptimizationMethodChecker = ScipyMethodChecker(self)
        self.stop_iteration_callback = StopIterationCallback(self)

    def _objective(self, x: np.ndarray):  # x: candidate parameter
        # update parameter
        self.parameters['value'] = x
        self.fem.update_parameter(self.parameters)

        # strict constraints
        ...

        # fem
        try:
            _, obj_values, cns_values = self.f(x)
        except (ModelError, MeshError, SolveError) as e:
            logger.info(e)
            logger.info('以下の変数で FEM 解析に失敗しました。')
            print(self.get_parameter('dict'))

            # 現状、エラーが起きたらスキップできない
            raise StopIteration2

        # constraints
        ...

        # # check interruption command
        # if self.entire_status.get() == OptimizationStatus.INTERRUPTING:
        #     self.worker_status.set(OptimizationStatus.INTERRUPTING)
        #     raise StopOptimize

        # objectives to objective

        return obj_values[0]

    def _setup_before_parallel(self):
        pass

    def run(self):

        # create init
        x0 = self.parameters['value'].values

        # create bounds
        if 'bounds' not in self.minimize_kwargs.keys():
            bounds = []
            for i, row in self.parameters.iterrows():
                lb, ub = row['lb'], row['ub']
                if lb is None: lb = -np.inf
                if ub is None: ub = np.inf
                bounds.append([lb, ub])
            self.minimize_kwargs.update(
                {'bounds': bounds}
            )

        # run optimize
        try:
            res = minimize(
                fun=self._objective,
                x0=x0,
                **self.minimize_kwargs,
                callback=self.stop_iteration_callback,
            )
        except StopIteration2:
            res = None
            logger.warn('Optimization has been interrupted. '
                        'Note that you cannot acquire the OptimizationResult '
                        'in case of `trust-constr`, `TNC`, `SLSQP` or `COBYLA`.')

        if res is None:
            self.res = self.stop_iteration_callback.res
        else:
            self.res = res