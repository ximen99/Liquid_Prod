import pandas as pd
import lib
from datetime import date, timedelta
import warnings
warnings.filterwarnings("ignore")

pd.options.display.float_format = '{:.2f}'.format

# last week's validation date
from_date = date(2023, 6, 16)
# new week's date to work on
new_date = from_date + timedelta(days=7)

lib.total_fund_tree.update_GPF_Managers_MV(new_date)
