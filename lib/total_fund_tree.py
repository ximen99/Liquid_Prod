from pathlib import Path
from . import utils as ut
from datetime import date, timedelta
from . import config


prod_path = Path(
    r"S:\IT IRSR Shared\RedSwan\RedSwan\Master_bcIMC\TREE\Total Fund Tree")
base_path = config.DEV_PATH if config.IS_DEV else prod_path


def create_folder_path(basePath: Path, folder_date: date, create_path: bool) -> Path:
    yearStr = str(folder_date.year)
    monthStr = ut.int_to_two_digit_str(folder_date.month)
    final_path = basePath / yearStr / monthStr / (ut.date_to_str(folder_date))
    if create_path:
        final_path.mkdir(parents=True, exist_ok=True)
    return final_path


def delete_files(from_date: date, to_date: date) -> None:
    to_path = create_folder_path(base_path, to_date, False)
    ut.delete_files_except_extensions(
        to_path / "Loading", [".environment", ".rst4"])
    ut.delete_files_with_extension(to_path, ".csv")
    ut.delete_files_name_contains(to_path / "Scale Calculation", " Ext Man ")
    old_wk_date_str = ut.date_to_str(from_date - timedelta(days=7))
    ut.delete_files_name_contains(
        to_path, "Total Fund PV Report "+old_wk_date_str+".xlsx")


def update_env_file(from_date, to_date):
    from_path = create_folder_path(prod_path, from_date, False)
    to_path = create_folder_path(prod_path, to_date, False)
    file_path = create_folder_path(base_path, to_date, False) / \
        "Loading" / "TotalFundHierarchy Prod Load.environment"
    from_date_str = ut.date_to_str(from_date)
    to_date_str = ut.date_to_str(to_date)
    ut.replace_text_in_file(
        file_path, str(from_path), str(to_path))
    ut.replace_text_in_file(file_path, from_date_str, to_date_str)


def create_template_folder(from_date: date, to_date: date) -> None:
    from_path = create_folder_path(base_path, from_date, False)
    to_path = create_folder_path(base_path, to_date, False)
    ut.copy_folder_with_check(from_path, to_path)
    delete_files(from_date, to_date)
    update_env_file(from_date, to_date)
