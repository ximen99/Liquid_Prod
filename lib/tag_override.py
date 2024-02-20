from pathlib import Path
import numpy as np
from . import utils as ut
from datetime import date
from . import config
import pandas as pd
import xlwings as xw
from . import cube_lookthru as cl

PROD_PATH = Path(
    r"S:\IT IRSR Shared\RedSwan\RedSwan\Master_bcIMC\Portfolio Tag LK\Total Fund Tag Override")
BASE_PATH = config.DEV_PATH if config.IS_DEV else PROD_PATH
SQL_PATH = Path(__file__).parent / "sql" / "tag_override"
FILE_PREFIX = "Look Through Portfolio Tags "

def get_liquid_future_data() -> pd.DataFrame:
    path = SQL_PATH / "tag_override.sql"
    return ut.read_data_from_preston_with_sql_file(path)

def get_file_df(dt:date) -> pd.DataFrame:
    file_path = BASE_PATH / str(dt.year) /(FILE_PREFIX + ut.date_to_str(dt) + ".xlsx")
    return pd.read_excel(file_path)

def update_liquid_future(old_df: pd.DataFrame) -> pd.DataFrame:
    new_liquid = get_liquid_future_data()
    keep_df = old_df[old_df["BCI_Id"].isin(new_liquid["PositionId"])]
    new_liquid = (new_liquid[~new_liquid["PositionId"].isin(keep_df["BCI_Id"])]
                        .filter(['securityName','PositionId','ParentPortfolioCode'])
                        .rename(columns={"PositionId": "BCI_Id", "securityName": "BCI_SecurityName", "ParentPortfolioCode": "portfolioCode"}))
    map_data = old_df.drop_duplicates(subset='portfolioCode', keep='first')
    new_df = (new_liquid
                        .merge(map_data, on='portfolioCode', how='left', suffixes=('', '_y'))
                        [old_df.columns]
    ) 
    print(f'added new future data {new_df["BCI_Id"].to_list()} in liquid')
    return pd.concat([keep_df, new_df], ignore_index=True)

def update_msci_data(old_df: pd.DataFrame, new_dt:date) -> pd.DataFrame:
    msci_df = cl.get_ext_managers_df(new_dt)
    keep_df = old_df[old_df["BCI_Id"].isin(msci_df["BCI_Id"])]
    new_msci = (msci_df[~msci_df["BCI_Id"].isin(keep_df["BCI_Id"])]
                        .filter(['BCI_Id','BCI_SecurityName','portfolioCode']))
    map_data = old_df.drop_duplicates(subset='portfolioCode', keep='first')
    new_df = (new_msci
                    .merge(map_data, on='portfolioCode', how='left', suffixes=('', '_y'))
                    [old_df.columns]
    ) 
    print(f'added new future data {new_df["BCI_Id"].to_list()} in MSCI')
    return pd.concat([keep_df, new_df], ignore_index=True)


def create_look_through_tag_file(from_date: date, to_date: date) -> None:
    old_df = get_file_df(from_date)
    liquid_df = old_df[~old_df["portfolioCode"].isin(cl.PORT_LS)]
    liquid_df = update_liquid_future(liquid_df)
    msci_df = old_df[old_df["portfolioCode"].isin(cl.PORT_LS)]
    msci_df = update_msci_data(msci_df,from_date)
    pd.concat([liquid_df, msci_df], ignore_index=True).to_excel(BASE_PATH / str(to_date.year) /(FILE_PREFIX + ut.date_to_str(to_date) + ".xlsx"), index=False, sheet_name= "Main")
    
    
    
     
