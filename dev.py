import lib
from lib import utils as ut
import pandas as pd
from datetime import date, timedelta
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

pd.options.display.float_format = '{:.2f}'.format

# last week's validation date
from_date = date(2022, 12, 30)
# new week's date to work on
new_date = from_date + timedelta(days=7)

lib.total_fund_tree.update_GPF_Managers_MV(new_date)
