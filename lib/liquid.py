from pathlib import Path
from . import utils as ut
from datetime import date, timedelta, datetime
from . import config
import pandas as pd
import xlwings as xw

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
    to_download["Main"] = get_main_data()
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
