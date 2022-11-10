from pathlib import Path
from . import utils as ut
from datetime import date, timedelta


def collateral_folder_path(folder_date: date, create_path: bool) -> Path:
    basePath = Path(
        r"S:\IT IRSR Shared\RedSwan\RedSwan\Master_bcIMC\LIQUID\Collateral")
    yearStr = str(folder_date.year)
    monthStr = ut.int_to_two_digit_str(folder_date.month)
    dayStr = ut.int_to_two_digit_str(folder_date.day)
    final_path = basePath / yearStr / monthStr / (monthStr+"_"+dayStr)
    if create_path:
        final_path.mkdir(parents=True, exist_ok=True)
    return final_path


def test_folder_path(folder_date: date, create_path: bool) -> Path:
    basePath = Path(__file__).parents[2]
    yearStr = str(folder_date.year)
    monthStr = ut.int_to_two_digit_str(folder_date.month)
    dayStr = ut.int_to_two_digit_str(folder_date.day)
    final_path = basePath / yearStr / monthStr / (monthStr+"_"+dayStr)
    if create_path:
        final_path.mkdir(parents=True, exist_ok=True)
    return final_path


def delete_files(to_date: date) -> None:
    to_path = test_folder_path(to_date, False)
    ut.delete_files_except_extensions(
        to_path / "Loading", [".environment", ".rst4"])
    ut.delete_files_with_extension(to_path, ".csv")


def update_env_file(from_date, to_date):
    from_path = collateral_folder_path(from_date, False)
    to_path = collateral_folder_path(to_date, False)
    file_path = test_folder_path(to_date, False) / \
        "Loading" / "OTC_Collateral.environment"
    from_date_str = ut.date_to_str(from_date)
    to_date_str = ut.date_to_str(to_date)
    ut.replace_text_in_file(
        file_path, str(from_path), str(to_path))
    ut.replace_text_in_file(file_path, from_date_str, to_date_str)


def create_template_folder(from_date: date, to_date: date) -> None:
    from_path = test_folder_path(from_date, False)
    to_path = test_folder_path(to_date, False)
    ut.copy_folder_with_check(from_path, to_path)
    delete_files(to_date)
    update_env_file(from_date, to_date)
