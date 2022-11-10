import os
import shutil
from datetime import date


def delete_files_with_extension(path, extension):
    for file in os.listdir(path):
        if file.endswith(extension):
            os.remove(os.path.join(path, file))


def date_to_str(date: date) -> str:
    return str(date.year) + int_to_two_digit_str(date.month) + int_to_two_digit_str(date.day)


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
