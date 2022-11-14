import os
import shutil
from datetime import date
from pathlib import Path
import pyodbc
import pandas as pd
from typing import List


def delete_files_with_extension(path, extension):
    for file in os.listdir(path):
        if file.endswith(extension):
            os.remove(os.path.join(path, file))


def date_to_str(date: date) -> str:
    return str(date.year) + int_to_two_digit_str(date.month) + int_to_two_digit_str(date.day)


def date_to_str_with_dash(date: date) -> str:
    return str(date.year) + "-" + int_to_two_digit_str(date.month) + "-" + int_to_two_digit_str(date.day)


def get_file_extension(path) -> str:
    return os.path.splitext(path)[1]


def delete_files_name_contains(path, text):
    for file in os.listdir(path):
        if text in file:
            os.remove(os.path.join(path, file))


def delete_files_except_extensions(path, extensions):
    for file in os.listdir(path):
        file_extension = get_file_extension(file)
        if file_extension not in extensions:
            os.remove(os.path.join(path, file))


def delete_files_in_folder(path):
    for file in os.listdir(path):
        os.remove(os.path.join(path, file))


def copy_and_overwrite(from_path: str, to_path: str):
    if os.path.exists(to_path):
        shutil.rmtree(to_path)
    shutil.copytree(from_path, to_path)


def int_to_two_digit_str(number: int) -> str:
    return str(number).zfill(2)


def replace_text_in_file(file_path, old_text, new_text):
    with open(file_path, 'r') as file:
        filedata = file.read()
    filedata = filedata.replace(old_text, new_text)
    with open(file_path, 'w') as file:
        file.write(filedata)


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


def read_sql_file(path: str) -> str:
    with open(path, "r") as file:
        sql = file.read()
    return sql


def read_data_from_preston_with_sql_file(path: Path, params: list = None) -> pd.DataFrame:
    sql = read_sql_file(path)
    return read_data_from_preston_with_string(sql, params)
