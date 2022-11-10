import lib.liquid as li
from datetime import date, timedelta

from_date = date(2022, 10, 21)
new_date = from_date + timedelta(days=7)

li.create_template_folder(from_date, new_date)
