from pathlib import Path

IS_DEV = False
DEV_PATH = Path(__file__).parents[2]
CODE_PATH = Path(__file__).parents[1]
SQL_PATH = CODE_PATH / 'lib' / 'sql'
MAPPING_PATH = CODE_PATH / 'mapping'
