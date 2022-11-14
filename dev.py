# %%
import lib
import pandas as pd
from datetime import date, timedelta

# last week's validation date
from_date = date(2022, 11, 4)
# new week's date to work on
new_date = from_date + timedelta(days=6)
df = lib.liquid.get_ift_data(from_date)
