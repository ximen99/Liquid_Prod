# Weekly Load Automation

- This file will be the main interface to run python code which will operate on the respective folder used in weekly load.
- The main function code sits in lib folder which is a python package. The package is structured in a way that each module within works on specific working folder for weekly load.
- The config module in lib package has a variable "IS_DEV" which is used as a flag to determine if the code is running in dev environment or not and gets fed into all modules. please make sure it's turned to "False" before running in production.
