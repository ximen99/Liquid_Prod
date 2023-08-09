import os
import shutil
from datetime import date
from pathlib import Path
import pyodbc
import pandas as pd
from typing import List
import xlwings as xw
import re


def date_to_str(dt: date) -> str:
    return str(dt.year) + int_to_two_digit_str(dt.month) + int_to_two_digit_str(dt.day)


def date_to_str_with_dash(dt: date) -> str:
    return str(dt.year) + "-" + int_to_two_digit_str(dt.month) + "-" + int_to_two_digit_str(dt.day)


def get_file_extension(path) -> str:
    return os.path.splitext(path)[1]


def delete_files_with_extension(path, extension):
    for file in os.listdir(path):
        if file.endswith(extension):
            os.remove(os.path.join(path, file))
            print("Deleted file: " + file)


def delete_files_name_contains(path, text):
    for file in os.listdir(path):
        if text in file:
            os.remove(os.path.join(path, file))
            print("Deleted file: " + file)


def delete_files_except_extensions(path, extensions):
    for file in os.listdir(path):
        file_extension = get_file_extension(file)
        if file_extension not in extensions:
            os.remove(os.path.join(path, file))
            print("Deleted file: " + file)


def delete_files_in_folder(path):
    for file in os.listdir(path):
        os.remove(os.path.join(path, file))
        print("Deleted file: " + file)


def copy_and_overwrite(from_path: str, to_path: str):
    if os.path.exists(to_path):
        shutil.rmtree(to_path)
        print("Deleted folder: " + str(to_path))
    shutil.copytree(from_path, to_path)
    print("Copied folder from " + str(from_path) + " to " + str(to_path))


def int_to_two_digit_str(number: int) -> str:
    return str(number).zfill(2)


def replace_text_in_file(file_path, old_text, new_text):
    with open(file_path, 'r') as file:
        filedata = file.read()
    filedata = filedata.replace(old_text, new_text)
    with open(file_path, 'w') as file:
        file.write(filedata)
    print("replaced " + old_text + " with " +
          new_text + " in " + str(file_path))


def replace_text_in_file_with_regex(file_path, old_text_regex, new_text) -> None:
    with open(file_path, 'r') as file:
        filedata = file.read()
    filedata = re.sub(old_text_regex, new_text, filedata)
    with open(file_path, 'w') as file:
        file.write(filedata)
    print("replaced " + old_text_regex + " with " +
          new_text + " in " + str(file_path))


def rename_file_with_regex(path: Path, regex: str, new_name: str) -> None:
    for file in os.listdir(path):
        if re.search(regex, file):
            os.rename(os.path.join(path, file), os.path.join(path, new_name))
            print("Renamed " + str(file) + " to " + str(new_name))


def get_files_with_regex(path: Path, regex: str) -> List[Path]:
    files = []
    for file in os.listdir(path):
        if re.search(regex, file):
            files.append(Path(path, file))
    return files


def copy_folder_with_check(from_path: date, to_path: date) -> None:
    overwrite = "Y"
    if Path(to_path).exists():
        overwrite = input(
            "Folder already exists, do you want to overwrite? (Y/N): ")

    if overwrite in ["Y", "y"]:
        copy_and_overwrite(from_path, to_path)

    print("Copied to folder at " + str(to_path))


def read_data_from_preston_with_string(sql: str, params: list = None) -> pd.DataFrame:
    """only support query with one select statement. 
    variable should be passed in params not in the sql string
    if there're multiple statements in the query, query will be split by ';' and executed one by one.
    assuming the last statement is select statement.
    params will be passed to last select statement.
    """
    sql_ls = sql.split(";")
    cnn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                         'Server=preston;'
                         'Trusted_Connection=yes;', autocommit=True, readonly=True)
    cursor = cnn.cursor()
    for index, sql in enumerate(sql_ls):
        if index != len(sql_ls) - 1:
            cursor.execute(sql)
        else:
            df = pd.read_sql(sql, cnn, params=params)
    return df


def read_data_from_preston_with_string_single_statement(sql: str, params: list = None) -> pd.DataFrame:
    cnn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                         'Server=preston;'
                         'Trusted_Connection=yes;', autocommit=True, readonly=True)
    df = pd.read_sql(sql, cnn, params=params)
    return df


def replace_mark_with_text(sql: str, replace_dict: dict) -> str:
    for key, value in replace_dict.items():
        sql = sql.replace(key, value)
    return sql


def read_sql_file(path: str) -> str:
    with open(path, "r") as file:
        sql = file.read()
    return sql


def read_data_from_preston_with_sql_file(path: Path, params: list = None) -> pd.DataFrame:
    sql = read_sql_file(path)
    return read_data_from_preston_with_string(sql, params)


def sort_lists_move_unmatch_to_last(list1, list2):
    list1.sort()
    list2.sort()
    list1_copy = list1.copy()
    list2_copy = list2.copy()
    for item in list1_copy:
        if item not in list2_copy:
            list1.remove(item)
            list1.append(item)
    for item in list2_copy:
        if item not in list1_copy:
            list2.remove(item)
            list2.append(item)
    return list1, list2


def excel_to_csv(path: Path) -> None:
    pd.read_excel(path).to_csv(str(path).replace(".xlsx", ".csv"), index=False)
    print("Converted " + str(path) + " to csv")


def loop_through_files_contains(path: Path, text: str, func, *args, **kwargs):
    for file in os.listdir(path):
        if text in file:
            func(path, file, *args, **kwargs)


def work_on_excel(func, path: Path, save_path: Path = None, *args, **kwargs) -> None:
    with xw.App(visible=False) as app:
        wb = app.books.open(path)
        func(wb, *args, **kwargs)
        wb.save(save_path)
        wb.close()
    print(f"{path} is updated and saved to {save_path}")


def get_values_not_in_list(list1, list2) -> List:
    list1_copy = list1.copy()
    list2_copy = list2.copy()
    for item in list1_copy:
        if item in list2_copy:
            list1.remove(item)
    return list1


def read_log_files_from_folder(path: Path) -> pd.DataFrame:
    combined_df = pd.DataFrame()
    files = get_files_with_regex(path, ".*_Log.csv")
    for file in files:
        df = pd.read_csv(file)
        df["file_name"] = str(file.name)
        combined_df = pd.concat([combined_df, df])
    return combined_df
