cd %~dp0
rem poetry run python pyfemtet-core.py --help
rem poetry run python pyfemtet-core.py "xlsm" "femprj" "input_sheet" 3
rem poetry run python pyfemtet-core.py "xlsm" "femprj" "input_sheet" 3 --n_startup_trials=10 --timeout=3.14
rem poetry run python pyfemtet-core.py "xlsm" "femprj" "input_sheet" 3 --n_startup_trials=10 --timeout=5
rem poetry run python pyfemtet-core.py "xlsm" "femprj" "input_sheet" 3.14 --n_startup_trials=10 --timeout=5
@REM poetry run python pyfemtet-core.py ^
@REM     �C���^�[�t�F�[�X.xlsm ^
@REM     --input_sheet_name="�݌v�ϐ�" ^
@REM     --output_sheet_name="�ړI�֐�" ^
@REM     --constraint_sheet_name="�S���֐�" ^
@REM
@REM     --n_parallel=1 ^
@REM     --csv_path="test.csv" ^
@REM     --procedure_name=FemtetMacro.FemtetMain ^
@REM     --setup_procedure_name=PrePostProcessing.setup ^
@REM     --teardown_procedure_name=PrePostProcessing.teardown ^
@REM
@REM     --algorithm=Random ^
@REM     --n_startup_trials=10 ^
@REM
@REM pause

poetry run python "C:\Users\mm11592\Documents\myFiles2\working\1_PyFemtetOpt\PyFemtetDev3\pyfemtet\excel_ui\pyfemtet-core.py"  "C:\Users\mm11592\Documents\myFiles2\working\1_PyFemtetOpt\PyFemtetDev3\pyfemtet\excel_ui\�C���^�[�t�F�[�X.xlsm" --input_sheet_name="�݌v�ϐ�" --output_sheet_name="�ړI�֐�" --n_parallel=1 --procedure_name=FemtetMacro.FemtetMain --setup_procedure_name=PrePostProcessing.setup --teardown_procedure_name=PrePostProcessing.teardown --algorithm=Random --constraint_sheet_name="�S���֐�" --n_trials=20 & pause


