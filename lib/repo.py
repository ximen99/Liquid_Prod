from pathlib import Path
from . import utils as ut
from . import mds
from datetime import date, timedelta
from . import config
import pandas as pd

PROD_PATH = Path(
    r"S:\IT IRSR Shared\RedSwan\RedSwan\Master_bcIMC\LIQUID\Repo")
BASE_PATH = config.DEV_PATH if config.IS_DEV else PROD_PATH
SQL_PATH = Path(__file__).parent / "sql" / "repo"


def create_folder_path(basePath: Path, folder_date: date, create_path: bool) -> Path:
    yearStr = str(folder_date.year)
    monthStr = ut.int_to_two_digit_str(folder_date.month)
    dayStr = ut.int_to_two_digit_str(folder_date.day)
    final_path = basePath / yearStr / monthStr / (monthStr+"_"+dayStr)
    if create_path:
        final_path.mkdir(parents=True, exist_ok=True)
    return final_path


def delete_files(to_date: date) -> None:
    to_path = create_folder_path(BASE_PATH, to_date, False)
    ut.delete_files_except_extensions(
        to_path / "Loading", [".environment", ".rst4"])
    ut.delete_files_with_extension(to_path, ".csv")


def update_env_file(from_date, to_date):
    from_path = create_folder_path(PROD_PATH, from_date, False)
    to_path = create_folder_path(PROD_PATH, to_date, False)
    file_path = create_folder_path(BASE_PATH, to_date, False) / \
        "Loading" / "Repo_Col_V2.environment"
    ut.replace_text_in_file(
        file_path, str(from_path), str(to_path))


def create_template_folder(from_date: date, to_date: date) -> None:
    from_path = create_folder_path(BASE_PATH, from_date, False)
    to_path = create_folder_path(BASE_PATH, to_date, False)
    ut.copy_folder_with_check(from_path, to_path)
    delete_files(to_date)
    update_env_file(from_date, to_date)


def get_sql_data(dt: date) -> pd.DataFrame:
    path = SQL_PATH / "repo.sql"
    df1 = ut.read_data_from_preston_with_sql_file(path)
    sql = ut.read_sql_file(SQL_PATH / "repo2.sql")
    sql = ut.replace_mark_with_text(
        sql, {"?": f"{ut.date_to_str_with_dash(dt+timedelta(days=3))}"})
    df2 = ut.read_data_from_preston_with_string(sql)
    if df2.shape[0] == 0:
        raise ValueError("No data found in database")
    df = pd.concat([df1, df2])
    df = clean_data(df, dt)
    return df


def clean_data(df: pd.DataFrame) -> pd.DataFrame:
    countrypartyMap = (mds.get_counter_party_map()
                       .set_index('COUNTERPARTY_INPUT')
                       .to_dict()
                       ['COUNTERPARTY_OUTPUT'])
    df['counterparty'] = df.apply(lambda r: clean_counterparty(
        r['counterparty'], countrypartyMap), axis=1)
    return df


def clean_counterparty(name: str, map: dict) -> str:
    if name in map.values():
        return name
    if name == 'BCI_Internal':
        return 'BCI_Internal'
    if name in map.keys():
        return map[name]
    raise ValueError(
        f'Counterparty "{name}" not found in mapping table')


def _excel_func(wb, to_date) -> None:
    wb.sheets[0].clear_contents()
    wb.sheets[0].range("A1").value = get_sql_data(
        to_date).set_index("Valuation_date")


def update_excel_file(to_date: date) -> None:
    file_path = create_folder_path(
        BASE_PATH, to_date, False) / "REPO FINAL.xlsx"
    ut.work_on_excel(func=_excel_func, path=file_path, to_date=to_date)


def convert_to_csv(to_date: date) -> None:
    file_path = create_folder_path(
        BASE_PATH, to_date, False) / "REPO FINAL.xlsx"
    ut.excel_to_csv(file_path)
