import lib
from datetime import date, timedelta
import warnings
warnings.filterwarnings("ignore")
import pandas as pd


pd.options.display.float_format = '{:.2f}'.format

# last week's validation date 
from_date = date(2024, 3, 8)
# new week's date to work on
new_date = from_date + timedelta(days=7)

lib.total_fund_tree.get_gpf_mv(new_date)

