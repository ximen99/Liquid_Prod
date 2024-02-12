from pathlib import Path
from . import config
from . import utils as ut
from datetime import date
from . import cube_lookthru as cl
from . import total_fund_bmk_tree as tfbt
from . import total_fund_tree as tft
import shutil

PROD_PATH = Path(r"S:\IT IRSR Shared\RedSwan\RedSwan\Master_bcIMC\CubeFiles")
BASE_PATH = config.DEV_PATH if config.IS_DEV else PROD_PATH


def create_folder_path(basePath: Path, folder_date: date, weekly: bool = True,  create_path: bool = False) -> Path:
    if weekly:
        folder = "Weekly"
    else:
        folder = "Monthly"
    final_path = basePath / folder / (ut.date_to_str(folder_date))
    if create_path:
        final_path.mkdir(parents=True, exist_ok=True)
    return final_path


def copy_files(dt: date, path: Path) -> None:
    files = []
    files.append(cl.create_folder_path(cl.PROD_PATH, dt) /
                 f"LookthroughMapping_{ut.date_to_str(dt)}.csv")
    files.append(tfbt.create_folder_path(tfbt.PROD_PATH, dt) /
                 f"Total_Fund_BMK_Tree_{ut.date_to_str(dt)} - RD.csv")
    files.append(tfbt.create_folder_path(tfbt.PROD_PATH, dt) /
                 f"Total_Fund_BMK_Tree_{ut.date_to_str(dt)} - RU.csv")
    files.append(tft.create_folder_path(tft.PROD_PATH, dt) /
                 f"Total_Fund_Tree _{ut.date_to_str(dt)}.csv")
    for file in files:
        shutil.copy2(file, path)
        print(f"Copied file {file} to {path}")


def update_ProcessStats(dt: date, weekly: bool = True) -> None:
    ut.replace_text_in_file_with_regex(
        BASE_PATH/"ProcessStats.csv", r"\d{8}", ut.date_to_str(dt))
    risk_version = "Weekly" if weekly else "Monthly"
    ut.replace_text_in_file_with_regex(
        BASE_PATH/"ProcessStats.csv", r"Weekly|Monthly", risk_version)


def update_bmk(dt: date, path: Path):
    for f in [path/f"Total_Fund_BMK_Tree_{ut.date_to_str(dt)} - RD.csv", path/f"Total_Fund_BMK_Tree_{ut.date_to_str(dt)} - RU.csv"]:
        ut.replace_text_in_file(
            f, 'S&P/LSTA U.S. Leveraged Loan 100 - CAD Hedged', 'SP.MC.UNX000000151901432@rmgBenchmarks')
    print("updated benchmark replacement.")


def create_template_folder(dt: date, weekly: bool = True) -> None:
    path = create_folder_path(BASE_PATH, dt, weekly, True)
    print(f"Created folder {path}")
    copy_files(dt, path)
    update_bmk(dt, path)
    update_ProcessStats(dt, weekly)
