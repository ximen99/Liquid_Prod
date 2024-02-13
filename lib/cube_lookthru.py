from pathlib import Path
import numpy as np
from . import utils as ut
from datetime import date
from . import config
import pandas as pd
import xlwings as xw
from . import total_fund_tree as tft
import re
from . import liquid


PROD_PATH = Path(
    r"S:\IT IRSR Shared\RedSwan\RedSwan\Master_bcIMC\TREE\Lookthrough for Cube")
BASE_PATH = config.DEV_PATH if config.IS_DEV else PROD_PATH
SQL_PATH = Path(__file__).parent / "sql" / "lookthrough"
PORT_LS = ['ECOMPASS', 'EISOMAIA', 'EISOBOR']

def create_folder_path(basePath: Path, folder_date: date, create_path: bool = False) -> Path:
    yearStr = str(folder_date.year)
    final_path = basePath / yearStr / (ut.date_to_str(folder_date))
    if create_path:
        final_path.mkdir(parents=True, exist_ok=True)
    return final_path


def delete_files(to_date: date) -> None:
    to_path = create_folder_path(BASE_PATH, to_date, False)
    ut.delete_files_except_extensions(
        to_path / "Loading", [".environment", ".rst4"])
    ut.delete_files_with_extension(to_path, ".csv")


def update_env_file(from_date: date, to_date: date):
    from_path = create_folder_path(PROD_PATH, from_date, False)
    to_path = create_folder_path(PROD_PATH, to_date, False)
    file_path = create_folder_path(BASE_PATH, to_date, False) / \
        "Loading" / "Lookthrough Index Cube.environment"
    from_date_str = ut.date_to_str(from_date)
    to_date_str = ut.date_to_str(to_date)
    ut.replace_text_in_file(
        file_path, str(from_path), str(to_path))
    ut.replace_text_in_file(file_path, from_date_str, to_date_str)


def create_template_folder(from_date: date, to_date: date) -> None:
    from_path = create_folder_path(BASE_PATH, from_date, False)
    to_path = create_folder_path(BASE_PATH, to_date, False)
    ut.copy_folder_with_check(from_path, to_path)
    delete_files(to_date)
    update_env_file(from_date, to_date)


def get_lookthru_data() -> pd.DataFrame:
    path = SQL_PATH / "lookthrough.sql"
    return ut.read_data_from_preston_with_sql_file(path)


def get_indexCSV_data() -> pd.DataFrame:
    path = SQL_PATH / "indexCSV.sql"
    return ut.read_data_from_preston_with_sql_file(path)


def create_lookthru_cube(from_date: date, to_date: date, update_msci: bool = True) -> None:
    new_week_df_to_append = get_indexCSV_data()
    path = create_folder_path(BASE_PATH, to_date, False)
    file_prefix = "Lookthrough - Cube -  "
    old_week_str = ut.date_to_str(from_date)
    new_week_str = ut.date_to_str(to_date)
    msci_load_df = (
        pd.read_excel(path / (file_prefix + old_week_str + ".xlsx"))
        .query(f"MSCI_RM_INDEX_ID.str.contains('{'|'.join(PORT_LS)}')", engine="python")
        .assign(
            MSCI_RM_INDEX_ID=lambda _df: _df["MSCI_RM_INDEX_ID"].str.replace(
                old_week_str, new_week_str),
            PRICED_SECURITY_NAME=lambda _df: _df["PRICED_SECURITY_NAME"].str.replace(
                old_week_str, new_week_str)
        )
    )
    # update positions based on rm pv report
    if update_msci:
        pv_df = get_ext_managers_df(to_date)
        msci_load_df = update_msci_load_df_cube(msci_load_df, pv_df, new_week_str)

    new_week_df = pd.concat(
        [msci_load_df, new_week_df_to_append], ignore_index=True)

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
    path = create_folder_path(BASE_PATH, to_date, False)
    file_name = f"Lookthrough - Cube -  {ut.date_to_str(to_date)}.xlsx"
    ut.excel_to_csv(path / file_name)


def create_LookthroughMapping(from_date: date, to_date: date, update_msci:bool = True) -> None:
    path = create_folder_path(BASE_PATH, to_date, False)
    file_prefix = "LookthroughMapping_"
    old_week_str = ut.date_to_str(from_date)
    new_week_str = ut.date_to_str(to_date)
    old_week_df = pd.read_excel(
        path / (file_prefix + old_week_str + ".xlsx"),index_col=0)
    
    msci_load_df = old_week_df.query(
        f"BCI_ID.str.contains('{'|'.join(PORT_LS)}')", engine="python").reset_index()
    
    new_week_df_to_append = (
        get_lookthru_data()
        .replace('', pd.NA)
        .set_index("BCI_ID")
        .assign(BENCHMARK_ID=lambda _df: _df["BENCHMARK_ID"].fillna(old_week_df["BENCHMARK_ID"]))
        .reset_index()
    )

    if update_msci:
        pv_df = get_ext_managers_df(to_date)
        msci_load_df = update_msci_load_df_mapping(msci_load_df, pv_df)

    new_week_df = pd.concat(
        [msci_load_df, new_week_df_to_append], ignore_index=True)

    with xw.App(visible=False) as app:
        wb = app.books.open(
            path / (file_prefix + old_week_str + ".xlsx"))
        sheet = wb.sheets[0]
        sheet.clear_contents()
        sheet.range("A1").value = new_week_df.set_index("BCI_ID")
        app.calculate()
        wb.save(path / f"{file_prefix}{new_week_str}.xlsx")
        wb.close()
    print("LookthroughMapping created at " +
          str(path / f"{file_prefix}{new_week_str}.xlsx"))
    ut.delete_files_name_contains(
        path, f"{file_prefix}{old_week_str}.xlsx")

def get_lookthru_benchmark_null() -> pd.DataFrame:
    df = get_lookthru_data()
    liquid_df = liquid.get_all_liquid_except_CIBC()[['PositionId','PositionName']].rename(columns={"PositionId":"BCI_ID"})
    instrument_ls = ["Equity Index Option"]
    return (df
            .query("BENCHMARK_ID == ''", engine="python")
            .query("~INSTRUMENT_TYPE.isin(@instrument_ls)", engine="python")
            .merge(liquid_df, on = "BCI_ID", how="left")
            )
    

def turn_LookthruMapping_to_csv(to_date: date) -> None:
    path = create_folder_path(BASE_PATH, to_date, False)
    file_name = f"LookthroughMapping_{ut.date_to_str(to_date)}.xlsx"
    ut.excel_to_csv(path / file_name)


def get_ext_managers_df(dt: date) -> pd.DataFrame:
    pv_path = tft.get_gpf_pv_report_path(dt)
    instrument_ls = ["Exchange Traded Fund","Equity Index Future","Equity Future"]
    pv_data = (
        pd.read_excel(pv_path, skiprows=19,
                      usecols=lambda x: 'Unnamed' not in x)
        .query("Level == 1")
        .query("portfolioCode.isin(@PORT_LS)", engine="python")
        .query("instrumentType.isin(@instrument_ls)", engine="python")
    )
    return pv_data

def update_msci_load_df_cube(old_df: pd.DataFrame, pv_df:pd.DataFrame, new_week_str:str) -> pd.DataFrame:
    pv_df = pv_df.copy()
    pv_df['BCI_Id'] = pv_df['BCI_Id'].apply(lambda id: f"{id}_{new_week_str}")
    old_df = old_df[old_df["MSCI_RM_INDEX_ID"].isin(pv_df["BCI_Id"])]
    new_positions = pv_df[~pv_df["BCI_Id"].isin(old_df["MSCI_RM_INDEX_ID"])]
    
    def get_index_name(s:str):
        if not isinstance(s, str):
            return None
        match = re.search(r'/(ISIN|CUSIP|RIC|SEDOL|TICKER)/(\w+)/', s)
        return match.group(2) if match else None
    
    new_positions_updated = (pd.DataFrame()
                             .assign(
                                MSCI_RM_INDEX_ID=new_positions["BCI_Id"],
                                INDEX_NAME = new_positions["ETSecurityIdentifier"].apply(get_index_name),
                                BENCHMARK_ID = np.nan,
                                INSTRUMENT_TYPE = new_positions["instrumentType"],
                                PRICED_SECURITY_NAME= new_positions["BCI_Id"].apply(lambda id: f"CUBE_{id}"), 
                            )
    )
    return pd.concat([old_df, new_positions_updated], ignore_index=True).sort_values("MSCI_RM_INDEX_ID")

def update_msci_load_df_mapping(old_df: pd.DataFrame, pv_df:pd.DataFrame) -> pd.DataFrame:
    old_df = old_df[old_df["BCI_ID"].isin(pv_df["BCI_Id"])]
    new_positions = pv_df[~pv_df["BCI_Id"].isin(old_df["BCI_ID"])]
    new_positions_updated = (pd.DataFrame()
                             .assign(
                                BCI_ID=new_positions["BCI_Id"],
                                MSCI_RM_INDEX_ID = np.nan,
                                BENCHMARK_ID = np.nan,
                                INSTRUMENT_TYPE = new_positions["instrumentType"]
                            )
    )
    return pd.concat([old_df, new_positions_updated], ignore_index=True).sort_values("BCI_ID")