import lib
from datetime import date, timedelta
import warnings
warnings.filterwarnings("ignore")

# last week's validation date
from_date = date(2022, 11, 11)
# new week's date to work on
new_date = from_date + timedelta(days=7)
# check environment, if production it should return share drive path

lib.total_fund_tree.create_extMan_PV_reports(new_date)
