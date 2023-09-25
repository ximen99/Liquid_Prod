from pathlib import Path
from . import utils as ut
from datetime import date
from . import config
import pandas as pd
import xlwings as xw


prod_path = Path(
    r"S:\IT IRSR Shared\RedSwan\RedSwan\Master_bcIMC\TREE\Lookthrough for Cube")
base_path = config.DEV_PATH if config.IS_DEV else prod_path
sql_path = Path(__file__).parent / "sql" / "lookthrough"


def create_folder_path(basePath: Path, folder_date: date, create_path: bool = False) -> Path:
    yearStr = str(folder_date.year)
    final_path = basePath / yearStr / (ut.date_to_str(folder_date))
    if create_path:
        final_path.mkdir(parents=True, exist_ok=True)
    return final_path


def delete_files(to_date: date) -> None:
    to_path = create_folder_path(base_path, to_date, False)
    ut.delete_files_except_extensions(
        to_path / "Loading", [".environment", ".rst4"])
    ut.delete_files_with_extension(to_path, ".csv")


def update_env_file(from_date: date, to_date: date):
    from_path = create_folder_path(prod_path, from_date, False)
    to_path = create_folder_path(prod_path, to_date, False)
    file_path = create_folder_path(base_path, to_date, False) / \
        "Loading" / "Lookthrough Index Cube.environment"
    from_date_str = ut.date_to_str(from_date)
    to_date_str = ut.date_to_str(to_date)
    ut.replace_text_in_file(
        file_path, str(from_path), str(to_path))
    ut.replace_text_in_file(file_path, from_date_str, to_date_str)


def create_template_folder(from_date: date, to_date: date) -> None:
    from_path = create_folder_path(base_path, from_date, False)
    to_path = create_folder_path(base_path, to_date, False)
    ut.copy_folder_with_check(from_path, to_path)
    delete_files(to_date)
    update_env_file(from_date, to_date)


def get_lookthru_data() -> pd.DataFrame:
    path = sql_path / "lookthrough.sql"
    return ut.read_data_from_preston_with_sql_file(path)


def get_indexCSV_data() -> pd.DataFrame:
    path = sql_path / "indexCSV.sql"
    return ut.read_data_from_preston_with_sql_file(path)


def create_lookthru_cube(from_date: date, to_date: date) -> None:
    new_week_df_to_append = get_indexCSV_data()
    path = create_folder_path(base_path, to_date, False)
    file_prefix = "Lookthrough - Cube -  "
    old_week_str = ut.date_to_str(from_date)
    new_week_str = ut.date_to_str(to_date)
    port_ls = ['ECOMPASS', 'EISOMAIA', 'EISOBOR']
    ecompass_df = (
        pd.read_excel(path / (file_prefix + old_week_str + ".xlsx"))
        .query(f"MSCI_RM_INDEX_ID.str.contains('{'|'.join(port_ls)}')", engine="python")
        .assign(
            MSCI_RM_INDEX_ID=lambda _df: _df["MSCI_RM_INDEX_ID"].str.replace(
                old_week_str, new_week_str),
            PRICED_SECURITY_NAME=lambda _df: _df["PRICED_SECURITY_NAME"].str.replace(
                old_week_str, new_week_str)
        )
    )
    new_week_df = pd.concat(
        [ecompass_df, new_week_df_to_append], ignore_index=True)

    with xw.App(visible=False) as app:
        wb = app.books.open(
            path / f"{file_prefix}{old_week_str}.xlsx")
        sheet = wb.sheets[0]
        sheet.clear_contents()
        sheet.range("A1").value = new_week_df.set_index("MSCI_RM_INDEX_ID")
        app.calculate()
        wb.save(path / f"{file_prefix}{new_week_str}.xlsx")
        wb.close()
    print("Lookthrough Cube created at " +
          str(path / f"{file_prefix}{new_week_str}.xlsx"))
    ut.delete_files_name_contains(
        path, f"{file_prefix}{old_week_str}.xlsx")


def turn_lookthru_cube_to_csv(to_date: date) -> None:
    path = create_folder_path(base_path, to_date, False)
    file_name = f"Lookthrough - Cube -  {ut.date_to_str(to_date)}.xlsx"
    ut.excel_to_csv(path / file_name)


def create_LookthroughMapping(from_date: date, to_date: date) -> None:
    path = create_folder_path(base_path, to_date, False)
    file_prefix = "LookthroughMapping_"
    old_week_str = ut.date_to_str(from_date)
    new_week_str = ut.date_to_str(to_date)
    old_week_df = pd.read_excel(
        path / (file_prefix + old_week_str + ".xlsx"), index_col=0)
    port_ls = ['ECOMPASS', 'EISOMAIA', 'EISOBOR']
    ecompass_df = old_week_df.query(
        f"BCI_ID.str.contains('{'|'.join(port_ls)}')", engine="python")
    new_week_df_to_append = (
        get_lookthru_data()
        .replace('', pd.NA)
        .set_index("BCI_ID")
        .assign(BENCHMARK_ID=lambda _df: _df["BENCHMARK_ID"].fillna(old_week_df["BENCHMARK_ID"]))
    )

    new_week_df = pd.concat(
        [ecompass_df, new_week_df_to_append])

    with xw.App(visible=False) as app:
        wb = app.books.open(
            path / (file_prefix + old_week_str + ".xlsx"))
        sheet = wb.sheets[0]
        sheet.clear_contents()
        sheet.range("A1").value = new_week_df
        app.calculate()
        wb.save(path / f"{file_prefix}{new_week_str}.xlsx")
        wb.close()
    print("LookthroughMapping created at " +
          str(path / f"{file_prefix}{new_week_str}.xlsx"))
    ut.delete_files_name_contains(
        path, f"{file_prefix}{old_week_str}.xlsx")


def turn_LookthruMapping_to_csv(to_date: date) -> None:
    path = create_folder_path(base_path, to_date, False)
    file_name = f"LookthroughMapping_{ut.date_to_str(to_date)}.xlsx"
    ut.excel_to_csv(path / file_name)
