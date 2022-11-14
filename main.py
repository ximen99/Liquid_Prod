import lib
from datetime import date, timedelta

# last week's validation date
from_date = date(2022, 11, 4)
# new week's date to work on
new_date = from_date + timedelta(days=6)

# code for liquid
lib.liquid.create_template_folder(from_date, new_date)
# code for collateral
lib.collateral.create_template_folder(from_date, new_date)
# code for repo
lib.repo.create_template_folder(from_date, new_date)
# code for lookthrough for cube
lib.cube_lookthru.create_template_folder(from_date, new_date)
# code for benchmark tree
lib.total_fund_tree.create_template_folder(from_date, new_date)
# code for total benchmark tree
lib.total_fund_bmk_tree.create_template_folder(from_date, new_date)
