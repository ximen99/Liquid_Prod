from . import utils as ut
from datetime import date
from pathlib import Path
import pandas as pd

sql_template = """
SELECT *
  FROM [MDS_ISR].[mdm].[%s]
"""


def get_counter_party_map() -> pd.DataFrame:
    sql = sql_template % "ENRICHMENT_viwCounterpartyMap"
    return ut.read_data_from_preston_with_string(sql)


def get_benchmark_security_map() -> pd.DataFrame:
    sql = sql_template % "ENRICHMENT_viwBenchmarkSecurityMap"
    return ut.read_data_from_preston_with_string(sql)
