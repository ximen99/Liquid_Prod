import lib.liquid as li
import lib.collateral as co
from datetime import date, timedelta

from_date = date(2022, 10, 21)
new_date = from_date + timedelta(days=7)

co.create_template_folder(from_date, new_date)
