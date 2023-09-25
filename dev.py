import pandas as pd
import lib
from datetime import date, timedelta
import warnings
warnings.filterwarnings("ignore")

pd.options.display.float_format = '{:.2f}'.format

# last week's validation date
from_date = date(2023, 9, 8)
# new week's date to work on
new_date = from_date + timedelta(days=7)


lib.repo.get_sql_data(new_date)
