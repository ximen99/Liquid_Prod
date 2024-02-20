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
    file_path = BASE_PATH / (FILE_PREFIX + ut.date_to_str(dt) + ".xlsx")
    return pd.read_excel(file_path)

def update_liquid_future(old_df: pd.DataFrame) -> pd.DataFrame:
    new_liquid = get_liquid_future_data()
    keep_df = old_df[old_df["BCI_Id"].isin(new_liquid["PositionId"])]
    new_liquid = (new_liquid[~new_liquid["PositionId"].isin(keep_df["BCI_Id"])]
                        .filter(['securityName','PositionId'])
                        .rename(columns={"PositionId": "BCI_Id", "securityName": "BCI_SecurityName"}))
    new_df = pd.concat([old_df.head(0), new_liquid], ignore_index=True)
    map_data = old_df.drop_duplicates(subset='portfoliocode', keep='first').set_index('portfoliocode')
    # new_df

    




def create_look_through_tag_file(from_date: date, to_date: date) -> None:
    old_df = get_file_df(from_date)


    
    
     
