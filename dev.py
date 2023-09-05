import pandas as pd
import lib
from datetime import date, timedelta
import warnings
warnings.filterwarnings("ignore")

pd.options.display.float_format = '{:.2f}'.format

# last week's validation date
from_date = date(2023, 7, 28)
# new week's date to work on
new_date = from_date + timedelta(days=3)
# check environment, if production it should return share drive path
lib.liquid.base_path

df = lib.total_fund_tree.get_gpf_mv(new_date)

print('')
