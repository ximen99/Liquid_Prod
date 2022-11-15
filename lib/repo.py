from pathlib import Path
from . import utils as ut
from datetime import date
from . import config

prod_path = Path(
    r"S:\IT IRSR Shared\RedSwan\RedSwan\Master_bcIMC\LIQUID\Repo")
base_path = config.DEV_PATH if config.IS_DEV else prod_path


def create_folder_path(basePath: Path, folder_date: date, create_path: bool) -> Path:
    yearStr = str(folder_date.year)
    monthStr = ut.int_to_two_digit_str(folder_date.month)
    dayStr = ut.int_to_two_digit_str(folder_date.day)
    final_path = basePath / yearStr / monthStr / (monthStr+"_"+dayStr)
    if create_path:
        final_path.mkdir(parents=True, exist_ok=True)
    return final_path


def delete_files(to_date: date) -> None:
    to_path = create_folder_path(base_path, to_date, False)
    ut.delete_files_except_extensions(
        to_path / "Loading", [".environment", ".rst4"])
    ut.delete_files_with_extension(to_path, ".csv")


def update_env_file(from_date, to_date):
    from_path = create_folder_path(prod_path, from_date, False)
    to_path = create_folder_path(prod_path, to_date, False)
    file_path = create_folder_path(base_path, to_date, False) / \
        "Loading" / "Repo_Col_V2.environment"
    ut.replace_text_in_file(
        file_path, str(from_path), str(to_path))


def create_template_folder(from_date: date, to_date: date) -> None:
    from_path = create_folder_path(base_path, from_date, False)
    to_path = create_folder_path(base_path, to_date, False)
    ut.copy_folder_with_check(from_path, to_path)
    delete_files(to_date)
    update_env_file(from_date, to_date)
