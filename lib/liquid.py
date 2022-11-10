
from pathlib import Path
from . import utils as ut
from datetime import date, timedelta


def liquid_folder_path(folder_date: date, create_path: bool) -> Path:
    basePath = Path(
        r"S:\IT IRSR Shared\RedSwan\RedSwan\Master_bcIMC\LIQUID\Liquid")
    yearStr = str(folder_date.year)
    monthStr = ut.int_to_two_digit_str(folder_date.month)
    dayStr = ut.int_to_two_digit_str(folder_date.day)
    final_path = basePath / yearStr / monthStr / (monthStr+"_"+dayStr)
    if create_path:
        final_path.mkdir(parents=True, exist_ok=True)
    return final_path


def copy_folder(from_path: date, to_path: date) -> None:
    overwrite = "Y"
    if Path(to_path).exists():
        overwrite = input(
            "Folder already exists, do you want to overwrite? (Y/N): ")

    if overwrite == "Y":
        ut.copy_and_overwrite(from_path, to_path)


def delete_files(from_date: date, to_date: date) -> None:
    to_path = liquid_folder_path(to_date, False)
    ut.delete_files_in_folder(to_path / "Mapping")
    ut.delete_files_in_folder(to_path / "Results")
    ut.delete_files_with_extension(to_path / "Files", ".csv")
    old_wk_date_str = ut.date_to_str(from_date - timedelta(days=7))
    ut.delete_files_name_contains(
        to_path, "PV Report Liquids "+old_wk_date_str+".xlsx")
    ut.delete_files_name_contains(
        to_path / "Illiquid RMLs", "PV Report Illiquids "+old_wk_date_str+".xlsx")


def update_env_file(from_date, to_date):
    from_path = liquid_folder_path(from_date, False)
    to_path = liquid_folder_path(to_date, False)
    file_path = to_path / "NewArch_LiquidsDerivatives V1 CSV.environment"
    from_date_str = ut.date_to_str(from_date)
    to_date_str = ut.date_to_str(to_date)
    ut.replace_text_in_file(
        file_path, str(from_path), str(to_path))
    ut.replace_text_in_file(file_path, from_date_str, to_date_str)


def create_template_folder(from_date: date, to_date: date) -> None:
    from_path = liquid_folder_path(from_date, False)
    to_path = liquid_folder_path(to_date, False)
    ut.copy_folder_with_check(from_path, to_path)
    delete_files(from_date, to_date)
    update_env_file(from_date, to_date)
