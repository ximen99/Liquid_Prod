from pathlib import Path
from . import utils as ut
from datetime import date, timedelta
from . import config
import pandas as pd

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
    print("Deleted files under " + str(to_path / "Mapping"))
    ut.delete_files_in_folder(to_path / "Results")
    print("Deleted files under " + str(to_path / "Results"))
    ut.delete_files_with_extension(to_path / "Files", ".csv")
    print("Deleted csv files under " + str(to_path))
    old_wk_date_str = ut.date_to_str(from_date - timedelta(days=7))
    ut.delete_files_name_contains(
        to_path, "PV Report Liquids "+old_wk_date_str+".xlsx")
    print("Deleted " + str(to_path / ("PV Report Liquids "+old_wk_date_str+".xlsx")))
    ut.delete_files_name_contains(
        to_path / "Illiquid RMLs", "PV Report Illiquids "+old_wk_date_str+".xlsx")
    print("Deleted " + str(to_path / "Illiquid RMLs" /
          ("PV Report Liquids "+old_wk_date_str+".xlsx")))


def update_env_file(from_date, to_date):
    from_path = create_folder_path(prod_path, from_date, False)
    to_path = create_folder_path(prod_path, to_date, False)
    file_path = create_folder_path(
        base_path, to_date, False) / "NewArch_LiquidsDerivatives V1 CSV.environment"
    from_date_str = ut.date_to_str(from_date)
    to_date_str = ut.date_to_str(to_date)
    ut.replace_text_in_file(
        file_path, str(from_path), str(to_path))
    ut.replace_text_in_file(file_path, from_date_str, to_date_str)
    print("updated environment file at "+str(file_path))


def create_template_folder(from_date: date, to_date: date) -> None:
    from_path = create_folder_path(base_path, from_date, False)
    to_path = create_folder_path(base_path, to_date, False)
    ut.copy_folder_with_check(from_path, to_path)
    delete_files(from_date, to_date)
    update_env_file(from_date, to_date)


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


def save_weekly_liquid_data(date) -> None:
    path = create_folder_path(base_path, date, True)
    to_download = {}
    prefix = "Positions_"+ut.date_to_str(date)
    to_download[prefix+"_IFT.csv"] = get_ift_data(date)
    to_download[prefix+"_Main.csv"] = get_main_data()
    to_download[prefix+"_Illiquids.csv"] = get_illiquids_data()
    hedge = get_hedge_data()
    basket = get_basket_data()
    to_download[prefix+"_Basket_Hedge.csv"] = pd.concat([basket, hedge])
    for name, df in to_download.items():
        df.to_csv(path / "Files" / name, index=False)
        print("Saved "+name+" at "+str(path / "Files" / name))


def create_fix_file(date) -> None:
    save_folder_path = create_folder_path(base_path, date) / "Files"
    result_folder_path = create_folder_path(base_path, date) / "Results"
    rejected_bond = (
        pd.read_csv(result_folder_path /
                    ("Main_"+ut.date_to_str(date)+"_log.csv"))
        .query("`RMG_PositionStatus`.str.contains('Proxied')", engine="python")
        .query("`instrumentType`.str.contains('Bond')", engine="python")
        ["BCI_Id"]
        .tolist()
    )

    def check_na(df):
        if df.ModelRuleEffective.isna().sum() > 0:
            raise Exception("ModelRuleEffective is NA")
        else:
            return df

    main_df = get_main_data()
    (
        main_df
        .query("PositionId in @rejected_bond")
        .assign(ModelRuleEffective=lambda _df: _df.FloatingRateIndicator.astype("int64").map({1: "Reject Floating Rate Bond", 0: "Reject Fixed Coupon Bond"}))
        .pipe(lambda _df: check_na(_df))
        .to_csv(save_folder_path / ("Positions_"+ut.date_to_str(date)+"_Fix.csv"), index=False)
    )
    print("Saved Positions_"+ut.date_to_str(date) +
          "_Fix.csv at "+str(save_folder_path))
