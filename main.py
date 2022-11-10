import lib
from datetime import date, timedelta

from_date = date(2022, 11, 4)
new_date = from_date + timedelta(days=7)

lib.total_fund_bmk_tree.create_template_folder(from_date, new_date)
