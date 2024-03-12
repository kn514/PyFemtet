# typing
from abc import ABC, abstractmethod

# built-in
import json
from time import sleep

# 3rd-party
import numpy as np
import pandas as pd

# pyfemtet relative
from pyfemtet.opt.interface import FemtetInterface
from pyfemtet.opt._femopt_core import OptimizationStatus

# logger
import logging
from pyfemtet.logger import get_logger
logger = get_logger('opt')
logger.setLevel(logging.INFO)


class AbstractOptimizer(ABC):
    """Abstract base class for an interface of optimization library.

    Attributes:
        fem (FEMInterface): The finite element method object.
        fem_class (type): The class of the finite element method object.
        fem_kwargs (dict): The keyword arguments used to instantiate the finite element method object.
        parameters (pd.DataFrame): The parameters used in the optimization.
        objectives (dict): A dictionary containing the objective functions used in the optimization.
        constraints (dict): A dictionary containing the constraint functions used in the optimization.
        entire_status (OptimizationStatus): The status of the entire optimization process.
        history (History): An actor object that records the history of each iteration in the optimization process.
        worker_status (OptimizationStatus): The status of each worker in a distributed computing environment.
        message (str): A message associated with the current state of the optimization process.
        seed (int or None): The random seed used for random number generation during the optimization process.
        timeout (float or int or None): The maximum time allowed for each iteration of the optimization process. If exceeded, it will be interrupted and terminated early.
        n_trials (int or None): The maximum number of trials allowed for each iteration of the optimization process. If exceeded, it will be interrupted and terminated early.
        is_cluster (bool): Flag indicating if running on a distributed computing cluster.

    """

    def __init__(self):
        self.fem = None
        self.fem_class = None
        self.fem_kwargs = dict()
        self.parameters = pd.DataFrame()
        self.objectives = dict()
        self.constraints = dict()
        self.entire_status = None  # actor
        self.history = None  # actor
        self.worker_status = None  # actor
        self.message = ''
        self.seed = None
        self.timeout = None
        self.n_trials = None
        self.is_cluster = False

    def f(self, x):
        """Get x, update fem analysis, return objectives (and constraints)."""
        # interruption の実装は具象クラスに任せる

        # x の更新
        self.parameters['value'] = x

        # FEM の更新
        logger.debug('fem.update() start')
        self.fem.update(self.parameters)

        # y, _y, c の更新
        logger.debug('calculate y start')
        y = [obj.calc(self.fem) for obj in self.objectives.values()]

        logger.debug('calculate _y start')
        _y = [obj.convert(value) for obj, value in zip(self.objectives.values(), y)]

        logger.debug('calculate c start')
        c = [cns.calc(self.fem) for cns in self.constraints.values()]

        # Femtet 特有の処理
        metadata = ''
        if isinstance(self.fem, FemtetInterface):
            metadata = json.dumps(
                dict(
                    femprj_path=self.fem.original_femprj_path,
                    model_name=self.fem.model_name
                )
            )

        logger.debug('history.record start')
        self.history.record(
            self.parameters,
            self.objectives,
            self.constraints,
            y,
            c,
            self.message,
            metadata
        )

        logger.debug('history.record end')
        return np.array(y), np.array(_y), np.array(c)

    def set_fem(self, skip_reconstruct=False):
        """Reconstruct FEMInterface in a subprocess."""
        # restore fem
        if not skip_reconstruct:
            self.fem = self.fem_class(**self.fem_kwargs)

        # COM 定数の restore
        for obj in self.objectives.values():
            obj._restore_constants()
        for cns in self.constraints.values():
            cns._restore_constants()

    def get_parameter(self, format='dict'):
        """Returns the parameters in the specified format.

        Args:
            format (str, optional): The desired format of the parameters. Can be 'df' (DataFrame), 'values', or 'dict'. Defaults to 'dict'.

        Returns:
            object: The parameters in the specified format.

        Raises:
            ValueError: If an invalid format is provided.

        """
        if format == 'df':
            return self.parameters
        elif format == 'values' or format == 'value':
            return self.parameters.value.values
        elif format == 'dict':
            ret = {}
            for i, row in self.parameters.iterrows():
                ret[row['name']] = row.value
            return ret
        else:
            raise ValueError('get_parameter() got invalid format: {format}')

    def _check_interruption(self):
        """"""
        if self.entire_status.get() == OptimizationStatus.INTERRUPTING:
            self.worker_status.set(OptimizationStatus.INTERRUPTING)
            self.finalize()
            return True
        else:
            return False

    def finalize(self):
        """Destruct fem and set worker status."""
        del self.fem
        self.worker_status.set(OptimizationStatus.TERMINATED)

    def _main(
            self,
            subprocess_idx,
            worker_status_list,
            wait_setup,
            skip_set_fem=False,
    ) -> None:

        # 自分の worker_status の取得
        self.worker_status = worker_status_list[subprocess_idx]
        self.worker_status.set(OptimizationStatus.LAUNCHING_FEM)

        if self._check_interruption():
            return None

        # set_fem をはじめ、終了したらそれを示す
        if not skip_set_fem:  # なくても動く？？
            self.set_fem()
        self.fem.setup_after_parallel()
        self.worker_status.set(OptimizationStatus.WAIT_OTHER_WORKERS)

        # wait_setup or not
        if wait_setup:
            while True:
                if self._check_interruption():
                    return None
                # 他のすべての worker_status が wait 以上になったら break
                if all([ws.get() >= OptimizationStatus.WAIT_OTHER_WORKERS for ws in worker_status_list]):
                    break
                sleep(1)
        else:
            if self._check_interruption():
                return None

        # set status running
        if self.entire_status.get() < OptimizationStatus.RUNNING:
            self.entire_status.set(OptimizationStatus.RUNNING)
        self.worker_status.set(OptimizationStatus.RUNNING)

        # run and finalize
        try:
            self.main(subprocess_idx)
        finally:
            self.finalize()

        return None

    @abstractmethod
    def main(self, subprocess_idx: int = 0) -> None:
        """Start calcuration using optimization library."""
        pass

    @abstractmethod
    def setup_before_parallel(self, *args, **kwargs):
        """Setup before parallel processes are launched."""
        pass
