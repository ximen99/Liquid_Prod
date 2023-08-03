from pathlib import Path
from . import utils as ut
from datetime import date, timedelta, datetime
from . import config
import pandas as pd
import xlwings as xw
import numpy as np
from . import mds
from typing import List

prod_path = Path(
    r"S:\IT IRSR Shared\RedSwan\RedSwan\Master_bcIMC\LIQUID\Liquid")
base_path = config.DEV_PATH if config.IS_DEV else prod_path
sql_path = Path(__file__).parent / "sql" / "liquid"


def create_folder_path(basePath: Path, folder_date: date, create_path: bool = False) -> Path:
    yearStr = str(folder_date.year)
    monthStr = ut.int_to_two_digit_str(folder_date.month)
    dayStr = ut.int_to_two_digit_str(folder_date.day)
    final_path = basePath / yearStr / monthStr / (monthStr+"_"+dayStr)
    if create_path:
        final_path.mkdir(parents=True, exist_ok=True)
    return final_path


def delete_files(from_date: date, to_date: date) -> None:
    to_path = create_folder_path(base_path, to_date, False)
    ut.delete_files_in_folder(to_path / "Mapping")
    ut.delete_files_in_folder(to_path / "Results")
    ut.delete_files_with_extension(to_path / "Files", ".csv")
    old_wk_date_str = ut.date_to_str(from_date - timedelta(days=7))
    ut.delete_files_name_contains(
        to_path, "PV Report Liquids "+old_wk_date_str+".xlsx")
    ut.delete_files_name_contains(
        to_path / "Illiquid RMLs", "PV Report Illiquids "+old_wk_date_str+".xlsx")


def update_env_file_date(from_date, to_date):
    from_path = create_folder_path(prod_path, from_date, False)
    to_path = create_folder_path(prod_path, to_date, False)
    file_path = create_folder_path(
        base_path, to_date, False) / "NewArch_LiquidsDerivatives V1 CSV.environment"
    from_date_str = ut.date_to_str(from_date)
    to_date_str = ut.date_to_str(to_date)
    ut.replace_text_in_file(
        file_path, str(from_path), str(to_path))
    ut.replace_text_in_file(file_path, from_date_str, to_date_str)


def update_env_file_position(date: date, position: str) -> None:
    if position not in ["Basket_Hedge", "Fix", "IFT", "Illiquids", "Main"]:
        raise Exception(
            "position not valid, please choose in Basket_Hedge, Fix, IFT, Illiquids, Main")
    path = create_folder_path(base_path, date)
    file_path = path / "NewArch_LiquidsDerivatives V1 CSV.environment"
    position_regex = r"Basket_Hedge|Fix|IFT|Illiquids|Main"
    ut.replace_text_in_file_with_regex(file_path, position_regex, position)


def create_template_folder(from_date: date, to_date: date) -> None:
    from_path = create_folder_path(base_path, from_date, False)
    to_path = create_folder_path(base_path, to_date, False)
    ut.copy_folder_with_check(from_path, to_path)
    delete_files(from_date, to_date)
    update_env_file_date(from_date, to_date)
    update_env_file_position(to_date, "Basket_Hedge")


def get_all_liquid_except_CIBC() -> pd.DataFrame:
    path = sql_path / "all_liquid_except_CIBC.sql"
    return ut.read_data_from_preston_with_sql_file(path)


def get_basket_data() -> pd.DataFrame:
    path = sql_path / "basket.sql"
    return ut.read_data_from_preston_with_sql_file(path)


def get_hedge_data(check_type: bool = True) -> pd.DataFrame:
    path = sql_path / "hedge.sql"
    df = ut.read_data_from_preston_with_sql_file(path)
    if check_type:
        if (df["ISR_streamName"] != "SCD_FXFWD").any():
            raise Exception("ISR_streamName is not SCD_FXFWD")
    return df


def get_illiquids_data() -> pd.DataFrame:
    path = sql_path / "illiquids.sql"
    return ut.read_data_from_preston_with_sql_file(path)


def get_ift_data(date: date) -> pd.DataFrame:
    path = sql_path / "IFT.sql"
    date_str = ut.date_to_str_with_dash(date)
    return ut.read_data_from_preston_with_sql_file(path, [date_str])


def get_gpf_neutralization_data(port_code: str) -> pd.DataFrame:
    sql = ut.read_sql_file(sql_path/"gpf_neutralization.sql")
    sql = ut.replace_mark_with_text(
        sql, {"?": f"{port_code}"})
    return ut.read_data_from_preston_with_string_single_statement(sql)


def get_all_gpf_neutralization_data() -> pd.DataFrame:
    port_codes = ["E0075", "E0178", "E0063"]
    df = pd.DataFrame()
    for port_code in port_codes:
        df = df.append(get_gpf_neutralization_data(
            port_code), ignore_index=True)
    return df


def get_main_data() -> pd.DataFrame:
    path = sql_path / "main.sql"
    return ut.read_data_from_preston_with_sql_file(path)


def get_filter_group_data() -> pd.DataFrame:
    path = sql_path / "portfolio_filter_group.sql"
    return ut.read_data_from_preston_with_sql_file(path)


def update_load_excel_template(dt: date, type: str, df: pd.DataFrame) -> None:
    if type not in ["Basket_Hedge", "Illiquids", "Main", "IFT", "Fix"]:
        raise Exception(
            "type not valid, please choose in Basket_Hedge, Illiquids, Main, IFT, Fix")

    folder_path = create_folder_path(base_path, dt, False) / "Files"
    excel_file_regex = r"Positions_\d{8}_"+type+".xlsx"
    file_path = ut.get_files_with_regex(folder_path, excel_file_regex)

    if len(file_path) != 1:
        raise Exception("file not found")
    file_path = file_path[0]

    def paste_data(wb: xw.Book, df: pd.DataFrame) -> None:
        sheet = wb.sheets[0]
        sheet.clear_contents()
        sheet.range("A1").value = df
    ut.work_on_excel(paste_data, file_path, None, df)
    ut.rename_file_with_regex(
        folder_path, excel_file_regex, f"Positions_{ut.date_to_str(dt)}_{type}.xlsx")


def save_weekly_liquid_data(date) -> None:
    path = create_folder_path(base_path, date, True)
    to_download = {}
    prefix = "Positions_"+ut.date_to_str(date)
    to_download["IFT"] = get_ift_data(date)
    gpf_neut = get_all_gpf_neutralization_data()
    to_download["Main"] = pd.concat([get_main_data(), gpf_neut])
    to_download["Illiquids"] = get_illiquids_data()
    hedge = get_hedge_data()
    basket = get_basket_data()
    to_download["Basket_Hedge"] = pd.concat([basket, hedge])

    for name, df in to_download.items():
        df.to_csv(path / "Files" / f"{prefix}_{name}.csv", index=False)
        print(f"Saved {name} at "+str(path / "Files" / name))
        update_load_excel_template(date, name, df.set_index("ExcludeOverride"))


def create_fix_file(dt: date) -> None:
    save_folder_path = create_folder_path(base_path, dt) / "Files"
    result_folder_path = create_folder_path(base_path, dt) / "Results"
    rejected_bond = (
        pd.read_csv(result_folder_path /
                    ("Main_"+ut.date_to_str(dt)+"_log.csv"))
        .query("`RMG_PositionStatus`.str.contains('Proxied', na = False )", engine="python")
        .query("`instrumentType`.str.contains('Bond', na = False)", engine="python")
        ["BCI_Id"]
        .tolist()
    )

    def check_na(df):
        if df.ModelRuleEffective.isna().sum() > 0:
            raise Exception("ModelRuleEffective is NA")
        else:
            return df

    def update_excel(df: pd.DataFrame) -> pd.DataFrame:
        update_load_excel_template(dt, "Fix", df.set_index("ExcludeOverride"))
        return df

    main_df = get_main_data()
    (
        main_df
        .query("PositionId in @rejected_bond")
        .assign(ModelRuleEffective=lambda _df: _df.FloatingRateIndicator.astype("int64").map({1: "Reject Floating Rate Bond", 0: "Reject Fixed Coupon Bond"}))
        .pipe(lambda _df: check_na(_df))
        .pipe(lambda _df: update_excel(_df))
        .to_csv(save_folder_path / ("Positions_"+ut.date_to_str(dt)+"_Fix.csv"), index=False)
    )
    print("Saved Positions_"+ut.date_to_str(dt) +
          "_Fix.csv at "+str(save_folder_path))


def create_portfolio_filter_group(from_date: date, to_date: date) -> None:
    path = create_folder_path(base_path, to_date)
    new_week_portfolios = (
        get_filter_group_data()
        ['ParentPortfolioCode']
        .unique()
        .reshape(-1, 1)
        .tolist()
    )
    with xw.App(visible=False) as app:
        wb = app.books.open(
            path / ("Portfolio Filter Group " + ut.date_to_str(from_date)+".xlsx"))
        sheet = wb.sheets[0]
        old_week_portfolios = sheet.range(
            "F2").options(expand="down", ndim=1).value
        sheet.range("B1").value = sheet.range("F1").value
        old_week_portfolios, new_week_portfolios = ut.sort_lists_move_unmatch_to_last(
            sheet.range("F2").options(expand="down", ndim=2).value, new_week_portfolios)
        sheet.range("F2").expand("down").clear_contents()
        sheet.range("B2").expand("down").clear_contents()
        sheet.range("A3").expand('down').clear_contents()
        sheet.range("B2").value = old_week_portfolios
        last_r = sheet.range("B1").end("down").row
        sheet.range("A2:A"+str(last_r)).formula = sheet.range("A2").formula
        sheet.range("F1").value = datetime(
            to_date.year, to_date.month, to_date.day)
        sheet.range("F2").value = new_week_portfolios
        sheet.range("E3").expand("down").clear_contents()
        last_r = sheet.range("F1").end("down").row
        sheet.range("E2:E"+str(last_r)).formula = sheet.range("E2").formula
        app.calculate()
        wb.save(path / ("Portfolio Filter Group " +
                        ut.date_to_str(to_date)+".xlsx"))
        wb.close()
    print("Created Portfolio Filter Group file at " + str(path /
          ("Portfolio Filter Group " + ut.date_to_str(to_date)+".xlsx")))
    ut.delete_files_with_extension(
        path, " Group " + ut.date_to_str(from_date)+".xlsx")


def update_pv_validation_excel(wb: xw.Book, mv_df: pd.DataFrame, pv_df: pd.DataFrame) -> None:
    # update RM PV Report tab data
    wb.sheets["RM PV Report"].range("A1").value = pv_df.set_index("Level")
    # update position level tab
    position_sheet = wb.sheets["Positional Level"]
    position_sheet.api.AutoFilter.ShowAllData()
    position_sheet.range(
        f"A3:L{position_sheet.range('A1').end('down').row}").clear_contents()
    position_sheet.range("A1").value = (
        mv_df
        .copy()
        .set_index("ParentPortfolioCode")
        .assign(**{"Sum of BaseTotalMarketValue": lambda _df: np.where(np.logical_or(_df.index.str.startswith('E008'), _df.index.str.startswith('E004')), 0, _df["Sum of BaseTotalMarketValue"])})
    )
    position_sheet_last_row = position_sheet.range("A2").end("down").row
    position_sheet.range("I3").expand("table").clear_contents()
    position_sheet.range("I2:K2").copy(position_sheet.range(
        f"I2:K{position_sheet_last_row}"))
    position_sheet.api.Range("A1:K1").AutoFilter(2, "<>*FX*")
    position_sheet.api.Range("A1:K1").AutoFilter(
        10, ">1000", xw.constants.AutoFilterOperator.xlOr, "<-1000")
    position_sheet.api.Range("A1:K1").AutoFilter(
        11, ">0.03", xw.constants.AutoFilterOperator.xlOr, "<-0.03")
    # update portfolio level tab
    portfolio_sheet = wb.sheets["Portfolio Level"]
    old_week_df = portfolio_sheet.range("A3").options(
        pd.DataFrame, expand="table").value
    pivot = portfolio_sheet.api.PivotTables("PivotTable7")
    pivot_cache = wb.api.PivotCaches().Create(SourceType=xw.constants.PivotTableSourceType.xlDatabase,
                                              SourceData=position_sheet.range(f"A1:H{position_sheet_last_row}").api)
    pivot.ChangePivotCache(pivot_cache)
    pivot.PivotCache().Refresh()
    pivot_last_row = portfolio_sheet.range("A3").end("down").row
    portfolio_sheet.range(
        f"C5:F{portfolio_sheet.range('C3').end('down').row}").clear_contents()
    portfolio_sheet.range("C4:E4").copy(
        portfolio_sheet.range(f"C4:E{pivot_last_row-1}"))
    portfolio_sheet.range(
        f"C{pivot_last_row}").formula = f"=SUM(C4:C{pivot_last_row-1})"
    portfolio_sheet.range(
        f"D{pivot_last_row}").formula = f"=C{pivot_last_row}-B{pivot_last_row}"
    portfolio_sheet.range(
        f"F{pivot_last_row}").formula = f"='RM PV Report'!C2"
    portfolio_sheet.range(f"E{pivot_last_row-1}").copy(
        portfolio_sheet.range(f"E{pivot_last_row}"))
    for i in range(4, pivot_last_row):
        if portfolio_sheet.range(f"A{i}").value in old_week_df.index:
            portfolio_sheet.range(f"F{i}").value = old_week_df.loc[portfolio_sheet.range(
                f"A{i}").value, "Comments"]


def check_date(df: pd.DataFrame, dt: date) -> pd.DataFrame:
    if len(df["RiskDate"].unique()) > 1:
        raise ValueError(f"Multiple RiskDate in Data")
    if df["RiskDate"].unique()[0] != ut.date_to_str(dt):
        raise ValueError(
            f"RiskDate in Data is {ut.date_to_str(df['RiskDate'].unique()[0])}, not {dt}")
    return df


def create_pv_validation(dt: date) -> None:

    path = create_folder_path(base_path, dt)
    mv_df = (
        pd.concat([get_filter_group_data(), get_ift_data(dt)])
        .pipe(check_date, dt)
        .astype({"Amount": "float", "BaseTotalMarketValue": "float"})
        .groupby(["ParentPortfolioCode", "InstrumentTypeDesc", "PositionId", "securityName", "LocalPriceCcyCode", "MaturityDate"], dropna=False, as_index=False)
        [["Amount", "BaseTotalMarketValue"]]
        .sum()
        .rename(columns={"Amount": "Sum of Amount", "BaseTotalMarketValue": "Sum of BaseTotalMarketValue"})
    )
    pv_df = pd.read_excel(path / "PV Report Liquids.xlsx",
                          skiprows=19, usecols="B:M")
    ut.rename_file_with_regex(
        path, "PV Report Liquids.xlsx", f"PV Report Liquids {ut.date_to_str(dt)}.xlsx")
    validation_path = ut.get_files_with_regex(
        path, r"^LiquidsDerivatives PV Validation .*\.xlsx")[0]
    ut.work_on_excel(update_pv_validation_excel,
                     validation_path, mv_df=mv_df, pv_df=pv_df)
    ut.rename_file_with_regex(
        path, r"^LiquidsDerivatives PV Validation .*\.xlsx", f"LiquidsDerivatives PV Validation {ut.date_to_str(dt)}.xlsx")


def counter_party_check(dt: date) -> None:
    instruments = ["Interest Rate Vanilla Swap", "Interest Rate Cross Currency Basis Swap", "Interest Rate Overnight Index Swap",
                   "Equity Index Swap", "FX Forward", "Equity Single Name Swap", "Fully Funded Swap", "FX Spot", "Repurchase Agreement", "Reverse Repo"]
    df = (
        get_filter_group_data()
        .query("InstrumentType in @instruments")
    )
    counter_party = mds.get_counter_party_map(
        dt)['COUNTERPARTY_OUTPUT'].tolist()
    unmapped_counter_party = set(
        df['CounterParty'].unique().tolist()) - set(counter_party)
    if len(unmapped_counter_party) > 0:
        print(f"Unmapped counter party: {unmapped_counter_party}")
    else:
        print("All counter party are mapped")


def get_superD_BTRSEQ(dt: date) -> pd.DataFrame:
    path = Path(r"T:\EDM\Sample Data\daily_dumps\SuperD") / ut.date_to_str(dt)
    return (
        pd.read_excel(
            ut.get_files_with_regex(
                path, r"^BTRSEQ.*\.xls")[0],
            skiprows=4
        )
        .query("`Instrument Type` == 'Total Return Swap'")
        .pivot_table(index="External ID", values=['External Trade ID', 'Volume'], aggfunc={'External Trade ID': 'count', 'Volume': 'sum'})
    )


def get_index_map(index: List[str], dt: date):
    df_data = get_all_liquid_except_CIBC()
    df_final = pd.DataFrame()
    df_map = mds.get_benchmark_security_map(dt)
    sec_id_ls = []

    for i in index:
        sec_id = (
            df_data
            .query("InstrumentTypeDesc == 'Equity Index Swap' & SwapLegTypeCode == 'EQUITY_LEG'")
            .query("securityName.str.contains(@i) & not SwapIndexId.isnull()", engine='python')
            [["SecId", "securityName", "SwapIndexId"]]
        )
        if len(sec_id) > 0:
            print(
                f"for {i}, find {df_.iloc[0].loc[['SecId','securityName','SwapIndexId']].to_dict()}")
            sec_id_ls.append(sec_id.iloc[0])
        else:
            print(f"can't find sec_id for {index}")
    for sec_id in sec_id_ls:
        df_final = pd.concat([df_final, df_map.query("SEC_ID == @sec_id")[
            ['SEC_ID', 'ACC_SYS_SEC_ID', 'BENCHMARK_ID', 'INDEX_NAME', 'MSCI_RM_INDEX_ID']]])
    return df_final
