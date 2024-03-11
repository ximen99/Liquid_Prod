import lib
from datetime import date, timedelta
import warnings
warnings.filterwarnings("ignore")
import pandas as pd
from lib import utils as ut
from pathlib import Path
import xlwings as xw


pd.options.display.float_format = '{:.2f}'.format

# last week's validation date 
from_date = date(2024, 2, 2)
# new week's date to work on
new_date = from_date + timedelta(days=7)


def get_scale_df(folder_path: Path, folder_date: date) -> pd.DataFrame:
    def read_scale(file_path, skiprows):
        return (
            pd.read_excel(file_path, skiprows=skiprows,
                          usecols="D:E", header=None)
            .rename(columns={3: "port_code", 4: "scale"})
            .assign(port_code=lambda _df: _df["port_code"].str.replace(" Scale", ""))
            .set_index("port_code")
        )
    # update skip row number when there're new portfoloios
    mtg_scale = read_scale(folder_path/"Scale Calculation"/("Scale calculation E0043 " +
                                                            ut.date_to_str(folder_date) + ".xlsx"), 36)
    gpf_scale = read_scale(folder_path/"Scale Calculation"/("Scale calculation GPF " +
                                                            ut.date_to_str(folder_date) + ".xlsx"), 53)
    return pd.concat([mtg_scale, gpf_scale], axis=0)

p = lib.total_fund_tree.create_folder_path(lib.total_fund_tree.BASE_PATH, new_date)
scale_df = get_scale_df(p, new_date)
path = lib.total_fund_bmk_tree.create_folder_path(lib.total_fund_bmk_tree.BASE_PATH, new_date, False)
pv_path = Path(r"C:\Users\CXimen\OneDrive - BCI\Documents\Liquid_Data_Production_Dev\Total Fund PV Report UAT.xlsx")
pv_df = (
    pd.read_excel(pv_path, skiprows=19, usecols="B:D")
    .query("Level == 3")
    .filter(["Name", "PV"])
)
bmk_path = Path(r"C:\Users\CXimen\OneDrive - BCI\Documents\Liquid_Data_Production_Dev\Total_Fund_BMK_Tree_20240209 - RD.xlsx")



def update_single_bmk_tree(scale_df: pd.DataFrame, pv_df: pd.DataFrame) -> None:
    with xw.App(visible=False) as app:
        wb = app.books.open(bmk_path)
        sheet = wb.sheets[0]
        last_row = sheet.range("A1").end("down").row
        neut_port = pv_df[pv_df.duplicated('Name',keep=False) & (pv_df['PV']>0)]
        for r in range(2, last_row + 1):
            port_code = sheet.range(f"G{r}").value
            pool_code = sheet.range(f"F{r}").value
            # update code 
            if port_code not in pv_df["Name"].values:
                raise Exception(
                    f"Port code {port_code} not found in PV report")            
            if port_code in neut_port["Name"].values:
                neut_value = neut_port.loc[neut_port["Name"] == port_code, "PV"].values[0]
                if pool_code.startswith("RISKNEU"):
                    sheet.range(f"M{r}").value = neut_value * -1
                else:
                    sheet.range(f"M{r}").value = neut_value
            else:
                sheet.range(f"M{r}").value = pv_df.loc[pv_df["Name"] == port_code, "PV"].values[0]
            # ----------------------------------------------------------------------
            if port_code in scale_df.index:
                sheet.range(f"L{r}").value = scale_df.loc[port_code, "scale"]
        df = sheet.range("A1").options(pd.DataFrame, expand="table").value
        wb.save()
        wb.close()
    df.to_csv(r'C:\Users\CXimen\OneDrive - BCI\Documents\Liquid_Data_Production_Dev\Total_Fund_BMK_Tree_20240209 - RD.csv')
    print(
        f"Total Fund BMK Tree total MV is {df['Portfolio Market Value'].sum()} and PV report total is {pv_df['PV'].sum()}")

update_single_bmk_tree(scale_df, pv_df)