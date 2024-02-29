from pathlib import Path
from . import utils as ut
from datetime import date, timedelta, datetime
from . import config
import xlwings as xw
import pandas as pd

PROD_PATH = Path(
    r"S:\IT IRSR Shared\RedSwan\RedSwan\Master_bcIMC\TREE\Total Fund Tree")
BASE_PATH = config.DEV_PATH if config.IS_DEV else PROD_PATH
SQL_PATH = Path(__file__).parent / "sql" / "total_fund_tree"


def create_folder_path(basePath: Path, folder_date: date, create_path: bool = False) -> Path:
    yearStr = str(folder_date.year)
    monthStr = ut.int_to_two_digit_str(folder_date.month)
    final_path = basePath / yearStr / monthStr / (ut.date_to_str(folder_date))
    if create_path:
        final_path.mkdir(parents=True, exist_ok=True)
    return final_path


def delete_files(from_date: date, to_date: date) -> None:
    to_path = create_folder_path(BASE_PATH, to_date, False)
    ut.delete_files_except_extensions(
        to_path / "Loading", [".environment", ".rst4"])
    ut.delete_files_with_extension(to_path, ".csv")
    ut.delete_files_name_contains(to_path / "Scale Calculation", " Ext Man ")
    old_wk_date_str = ut.date_to_str(from_date - timedelta(days=7))
    ut.delete_files_name_contains(
        to_path, "Total Fund PV Report "+old_wk_date_str+".xlsx")


def update_env_file(from_date, to_date):
    from_path = create_folder_path(PROD_PATH, from_date, False)
    to_path = create_folder_path(PROD_PATH, to_date, False)
    file_path = create_folder_path(BASE_PATH, to_date, False) / \
        "Loading" / "TotalFundHierarchy Prod Load.environment"
    from_date_str = ut.date_to_str(from_date)
    to_date_str = ut.date_to_str(to_date)
    ut.replace_text_in_file(
        file_path, str(from_path), str(to_path))
    ut.replace_text_in_file(file_path, from_date_str, to_date_str)


def create_template_folder(from_date: date, to_date: date) -> None:
    from_path = create_folder_path(BASE_PATH, from_date, False)
    to_path = create_folder_path(BASE_PATH, to_date, False)
    ut.copy_folder_with_check(from_path, to_path)
    delete_files(from_date, to_date)
    update_env_file(from_date, to_date)


def update_extMan_PV_report(path: Path, file_name: str, to_date: date) -> None:

    def get_save_to_file_name(clientPorfolioID: list) -> str:
        for id in clientPorfolioID:
            if id is not None and "GPF" in id:
                return "PV Report GPF Ext Man " + ut.date_to_str(to_date) + ".xlsx"
            elif id is not None and "MTG" in id:
                return "PV Report E0043 Ext Man " + ut.date_to_str(to_date) + ".xlsx"

    with xw.App(visible=False) as app:
        wb = app.books.open(
            path / file_name)
        sheet = wb.sheets[0]
        save_to_name = get_save_to_file_name(
            sheet.range("I21").expand("down").value)
        sheet.range("20:20").api.AutoFilter(Field := 1, Criteria1 := ['0', '-1'],
                                            Operator := xw.constants.AutoFilterOperator.xlFilterValues)
        wb.save(path / save_to_name)
        wb.close()
    ut.delete_files_name_contains(path, file_name)
    print("Updated " + save_to_name + " in " + str(path))

def get_gpf_pv_report_path(dt:date) -> str:
    folder_path = create_folder_path(PROD_PATH, dt, False) / "Scale Calculation"
    return folder_path / ("PV Report GPF Ext Man " + ut.date_to_str(dt) + ".xlsx")

def get_mtg_pv_report_path(dt: date) -> str:
    folder_path = create_folder_path(PROD_PATH, dt, False) / "Scale Calculation"
    return folder_path / ("PV Report E0043 Ext Man " + ut.date_to_str(dt) + ".xlsx")

def create_extMan_PV_reports(to_date: date) -> None:
    path = create_folder_path(BASE_PATH, to_date, False) / "Scale Calculation"
    ut.loop_through_files_contains(
        path, "PV Report Liquids External Manager", update_extMan_PV_report, to_date)


def get_fx_rate(to_date: date) -> float:
    return (
        ut.read_data_from_preston_with_sql_file(
            SQL_PATH/"fx.sql", [ut.date_to_str_with_dash(to_date)])
        .loc[0, "IPS_CAD_QUOTE_MID"]
    )


def update_mtg_scale_calc(from_date: date, to_date: date) -> None:
    file_prefix = "Scale calculation E0043 "
    folder_path = create_folder_path(
        BASE_PATH, to_date, False) / "Scale Calculation"
    file_path = folder_path / \
        (file_prefix + ut.date_to_str(from_date) + ".xlsx")
    save_to_path = folder_path / \
        (file_prefix + ut.date_to_str(to_date) + ".xlsx")
    pv_path = get_mtg_pv_report_path(to_date)
    pv_data = (
        pd.read_excel(pv_path, skiprows=19,
                      usecols=lambda x: 'Unnamed' not in x)
        .query("Level == 0")
        .filter(["Name", "PV"])
        .set_index("Name")
    )
    fx = get_fx_rate(to_date)

    with xw.App(visible=False) as app:
        wb = app.books.open(file_path)
        sheet = wb.sheets[0]
        row_start = 21
        num_of_positions = sheet.range(
            f"A{row_start}").end("down").row - (row_start-1)
        sheet.range(f"A{row_start}").expand("down").value = [
            [datetime(to_date.year, to_date.month, to_date.day)]]*num_of_positions
        sheet.range(f"F{row_start}").expand(
            "down").value = [[fx]]*num_of_positions
        for r in range(row_start, row_start+num_of_positions):
            sheet.range(f"E{r}").value = pv_data.loc[sheet.range(
                f"D{r}").value, "PV"]
        app.calculate()
        wb.save(save_to_path)
        wb.close()
    ut.delete_files_name_contains(
        folder_path, file_prefix + ut.date_to_str(from_date))
    print("Updated " + str(save_to_path))


def get_gpf_mv(dt: date):
    sql = ut.read_multi_statement_sql_file(SQL_PATH/"gpf.sql")
    sql = ut.replace_mark_with_text(
        sql, {"@valuationDate": f"''{ut.date_to_str_with_dash(dt)}''"})
    return ut.read_data_from_preston_with_string_single_statement(sql)


def update_GPF_scale_calc(from_date: date, to_date: date) -> None:
    file_prefix = "Scale calculation GPF "
    folder_path = create_folder_path(
        BASE_PATH, to_date, False) / "Scale Calculation"
    file_path = folder_path / \
        (file_prefix + ut.date_to_str(from_date) + ".xlsx")
    save_to_path = folder_path / \
        (file_prefix + ut.date_to_str(to_date) + ".xlsx")
    pv_path = get_gpf_pv_report_path(to_date)
    pv_data = (
        pd.read_excel(pv_path, skiprows=19,
                      usecols=lambda x: 'Unnamed' not in x)
        .query("Level == 0")
        .filter(["Name", "PV"])
        .set_index("Name")
    )
    gpf_mv = (
        get_gpf_mv(to_date)
        .replace(dict.fromkeys(['EISOEOSB', 'EISOEOS', 'EISOEOSC', 'EISOEOSB1'], 'ECPCSA'))
        .groupby('SCD_SEC_ID')[['MARKET_VALUE_ACCRUED_INTEREST_BASE_NAV']]
        .sum()
    )
    fx = get_fx_rate(to_date)
    with xw.App(visible=False) as app:
        wb = app.books.open(file_path)
        sheet = wb.sheets[0]
        row_start_mv = 3  # row start for market value normally dont' need to change
        num_of_positions = sheet.range(f"A{row_start_mv}").end("down").row - 2
        row_start_pv = 39  # row start for pv
        sheet.range(f"A{row_start_mv}").expand("down").value = [
            [datetime(to_date.year, to_date.month, to_date.day)]]*num_of_positions
        sheet.range(f"A{row_start_pv}").expand("down").value = [
            [datetime(to_date.year, to_date.month, to_date.day)]]*num_of_positions
        for r in range(row_start_mv, row_start_mv+num_of_positions):
            sheet.range(f"H{r}").value = gpf_mv.loc[sheet.range(
                f"E{r}").value, "MARKET_VALUE_ACCRUED_INTEREST_BASE_NAV"]
            sheet.range(f"I{r}").value = fx
        for r in range(row_start_pv, row_start_pv+num_of_positions):
            sheet.range(f"E{r}").value = pv_data.loc[sheet.range(
                f"D{r}").value, "PV"]
        app.calculate()
        wb.save(save_to_path)
        wb.close()
    ut.delete_files_name_contains(
        folder_path, file_prefix + ut.date_to_str(from_date))
    print("Updated " + str(save_to_path))


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
                                                            ut.date_to_str(folder_date) + ".xlsx"), 74)
    return pd.concat([mtg_scale, gpf_scale], axis=0)


def update_total_fund_tree(to_date: date) -> None:
    file_name = "Total_Fund_Tree _" + ut.date_to_str(to_date) + ".xlsx"
    path = create_folder_path(BASE_PATH, to_date, False)
    scale = get_scale_df(path, to_date)
    with xw.App(visible=False) as app:
        wb = app.books.open(path / file_name)
        sheet = wb.sheets[0]
        last_row = sheet.range("A1").end("down").row
        for r in range(2, last_row+1):
            if sheet.range(f"F{r}").value in scale.index:
                sheet.range(f"J{r}").value = scale.loc[sheet.range(
                    f"F{r}").value, "scale"]
        (sheet.range("A1:J"+str(last_row))
         .options(pd.DataFrame)
         .value
         .to_csv(path / ("Total_Fund_Tree _" + ut.date_to_str(to_date) + ".csv"))
         )
        app.calculate()
        wb.save()
        wb.close()
    print("Updated " + str(path / file_name))


def update_total_fund_pv_report(to_date: date) -> None:
    file_name = "Total Fund PV Report.xlsx"
    path = create_folder_path(BASE_PATH, to_date, False)

    with xw.App(visible=False) as app:
        wb = app.books.open(path / file_name)
        sheet = wb.sheets[0]
        sheet.copy(
            before=wb.sheets['Statistic Definitions'], name="View 1 assetClass (2)")
        sheet.api.Outline.ShowLevels(RowLevels=2)
        sheet_copy = wb.sheets["View 1 assetClass (2)"]
        sheet_copy.api.Outline.ShowLevels(RowLevels=4)
        sheet_copy.range("A1:A10").api.EntireRow.Hidden = True
        sheet_copy.range("A12:A19").api.EntireRow.Hidden = True
        wb.save(path/("Total Fund PV Report " +
                ut.date_to_str(to_date) + ".xlsx"))
        wb.close()
    print("Updated " + str(path/("Total Fund PV Report " +
          ut.date_to_str(to_date) + ".xlsx")))
    ut.delete_files_name_contains(path, "Total Fund PV Report.xlsx")


def GPF_Managers_MV_excel_operation(wb: xw.Book, dt: date) -> None:
    mv_df = (
        get_gpf_mv(dt)
        .set_index("SCD_SEC_ID")
        .filter(["SHORT_NAME", "MARKET_VALUE_ACCRUED_INTEREST_BASE_NAV"])
    )
    sheet = wb.sheets[0]
    last_row = sheet.range("A1").end("down").row
    excel_sec_id = sheet.range(f"A2:A{last_row}").value
    new_positions = ut.get_values_not_in_list(
        mv_df.index.tolist(), excel_sec_id)
    if len(new_positions) > 0:
        sheet.range(f"A{last_row-len(new_positions)+1}:D{last_row}").copy()
        sheet.range(f"A{last_row+1}:D{last_row+1}").insert("down")
        sheet.range(
            f"A{last_row+1}").value = mv_df.loc[new_positions, "SHORT_NAME"].reset_index().values
        last_row += len(new_positions)
    reordered_sec_id = excel_sec_id + new_positions
    mv_df = mv_df.reindex(reordered_sec_id)
    sheet.range("K1").value = mv_df
    wb.sheets.add(ut.date_to_str(dt), after=sheet)
    sheet.range(f"A1:D{last_row+1}").copy()
    wb.sheets[ut.date_to_str(dt)].range("A1").paste("formats")

    df = sheet.range(
        f"A1:D{last_row+1}").options(pd.DataFrame).value
    df = pd.concat([df.query("`Base MV` != 'N/A'"),
                   df.query("`Base MV` == 'N/A'")])
    wb.sheets[ut.date_to_str(dt)].range("A1").value = df
    wb.sheets[ut.date_to_str(dt)].autofit()


def update_GPF_Managers_MV(to_date: date) -> None:
    file_name = "GPF Managers Weekly & Monthly MV.xlsx"
    path = create_folder_path(BASE_PATH, to_date, False) / "Queries"
    ut.work_on_excel(GPF_Managers_MV_excel_operation,
                     path / file_name, None, to_date)
