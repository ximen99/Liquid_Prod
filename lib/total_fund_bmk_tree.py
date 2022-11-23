from pathlib import Path
from . import utils as ut
from datetime import date
from . import config
from . import total_fund_tree
import pandas as pd
import xlwings as xw

prod_path = Path(
    r"S:\IT IRSR Shared\RedSwan\RedSwan\Master_bcIMC\TREE\Total Fund BMK Tree")
base_path = config.DEV_PATH if config.IS_DEV else prod_path


def create_folder_path(basePath: Path, folder_date: date, create_path: bool = False) -> Path:
    yearStr = str(folder_date.year)
    monthStr = ut.int_to_two_digit_str(folder_date.month)
    final_path = basePath / yearStr / monthStr / (ut.date_to_str(folder_date))
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
    file_path = create_folder_path(base_path, to_date, False) / "Loading"
    from_date_str = ut.date_to_str(from_date)
    to_date_str = ut.date_to_str(to_date)
    for file_path in file_path.glob("*.environment"):
        ut.replace_text_in_file(
            file_path, str(from_path), str(to_path))
        ut.replace_text_in_file(file_path, from_date_str, to_date_str)


def create_template_folder(from_date: date, to_date: date) -> None:
    from_path = create_folder_path(base_path, from_date, False)
    to_path = create_folder_path(base_path, to_date, False)
    ut.copy_folder_with_check(from_path, to_path)
    delete_files(to_date)
    update_env_file(from_date, to_date)


def update_single_bmk_tree(folder_path: Path, file_name: str, scale_df: pd.DataFrame, pv_df: pd.DataFrame) -> None:
    with xw.App(visible=False) as app:
        wb = app.books.open(folder_path / file_name)
        sheet = wb.sheets[0]
        last_row = sheet.range("A1").end("down").row
        for r in range(2, last_row + 1):
            port_code = sheet.range(f"G{r}").value
            if port_code not in pv_df.index:
                raise Exception(
                    f"Port code {port_code} not found in PV report")
            sheet.range("M" + str(r)).value = pv_df.loc[port_code, "PV"]
            if port_code in scale_df.index:
                sheet.range(f"L{r}").value = scale_df.loc[port_code, "scale"]
        df = sheet.range("A1").options(pd.DataFrame, expand="table").value
        wb.save()
        wb.close()
    df.to_csv(folder_path / file_name.replace(".xlsx", ".csv"))
    print(f"Updated {folder_path / file_name} and saved csv")
    print(
        f"Total Fund BMK Tree total MV is {df['Portfolio Market Value'].sum()} and PV report total is {pv_df['PV'].sum()}")


def update_total_fund_bmk_tree(to_date: date) -> None:
    path = create_folder_path(base_path, to_date, False)
    total_fund_tree_path = total_fund_tree.create_folder_path(
        total_fund_tree.prod_path, to_date, False)
    scale_df = total_fund_tree.get_scale_df(total_fund_tree_path, to_date)
    pv_df = (
        pd.read_excel(total_fund_tree_path /
                      f"Total Fund PV Report {ut.date_to_str(to_date)}.xlsx", skiprows=19, usecols="B:D")
        .query("Level == 3")
        .filter(["Name", "PV"])
        .set_index("Name")
    )
    ut.loop_through_files_contains(
        path, f"Total_Fund_BMK_Tree_{ut.date_to_str(to_date)}", update_single_bmk_tree, scale_df, pv_df)
