import lib
from lib import utils as ut
import pandas as pd
from datetime import date, timedelta
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')


# last week's validation date
from_date = date(2022, 11, 18)
# new week's date to work on
new_date = from_date + timedelta(days=7)
lib.liquid.base_path

lib.liquid.create_fix_file(new_date)
