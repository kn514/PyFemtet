# -*- coding: utf-8 -*-
"""
Created on Tue Nov 14 11:20:38 2023

@author: MM11592
"""

from PyFemtet.opt import FemtetScipy, FemtetOptuna
from PyFemtet.opt.core import NoFEM, ModelError, MeshError, SolveError

i = 0

def parabora(FEMObj):
    global i
    x = FEMObj.get_parameter('value')
    i += 1
    if i<=5:
        return (x**2).sum()
    else:
        raise ModelError


FEM = NoFEM()
FEMOpt = FemtetScipy(FEM)
# FEMOpt = FemtetOptuna(FEM)

FEMOpt.add_parameter('x', 0, -1, 1)
FEMOpt.add_objective(parabora, args=(FEMOpt,))
FEMOpt.set_process_monitor()
FEMOpt.main()
print(FEMOpt.history)
 