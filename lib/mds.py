from . import utils as ut
from datetime import date
from pathlib import Path
import pandas as pd

sql_template = """
SELECT *
  FROM [MDS_ISR].[mdm].[%s]
  where VersionName = ?
"""


def get_counter_party_map(date: date) -> pd.DataFrame:
    sql = sql_template % "ENRICHMENT_viwCounterpartyMap"
    versionName = f"VERSION_{ut.date_to_str(date)}"
    return ut.read_data_from_preston_with_string(sql, [versionName])


def get_benchmark_security_map(date: date) -> pd.DataFrame:
    sql = sql_template % "ENRICHMENT_viwBenchmarkSecurityMap"
    versionName = f"VERSION_{ut.date_to_str(date)}"
    return ut.read_data_from_preston_with_string(sql, [versionName])
