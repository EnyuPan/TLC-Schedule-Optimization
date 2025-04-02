# TLC Schedule Optimization

The goal of the project is to automate the creation of schedules for tutors at the Tutoring and Learning Centre. The finished product should analyze appointment data from past terms to determine the demand levels for each timeslot in the week and subject, then create an optimal weekly schedule for tutors based on demand, availability, and the tutors' desired hours, by solving an integer program.

Part of the problem's integer program formulation was done by Louise and Nitya, the Tutoring and Learning Centre assistants from Spring/Summer 2024, with guidance from Sullivan. The formulation was expanded by Enyu to the current version in Fall 2024. The file `Schedule Optimization Formulation 2.pdf` contains the current integer program formulation of the problem, which is important to understanding how the program works.

Two aspects of the project were worked on between Fall 2024 and Winter 2025:

- Analyzing appointment data on WCO using a linear regression model and predicting the demand for tutoring. This was implemented by Sebastian in R. Its documentation can be found at `R doc/R documentation.pdf`.

- Implementing and solving the integer program according to the formulation, using the demand data from the first part. The Python script (`main.py`), made by Enyu, implements this integer program and solves it using the `cvxpy` library.

Either three or four dimensions will be considered in the optimization: **tutor**, **subject**, **timeslot**, and **campus (*optional*)**. When starting, the program will ask the user whether to consider campus as a dimension or not. Depending on whether campus is considered, the input files (spreadsheets) would have to be in different formats.

The program takes a long time to run (~30 minutes) if campus is considered; when last tested, it takes around ~17 minutes if campus is not considered.

## Requirements

To run the Python script, you need Python installed, as well as the following libraries:
* numpy
* pandas
* cvxpy
    * The cvxpy library formulates the integer program and delegates the job of solving it to a specific solver. The GLPK_MI solver, for handling mixed-integer programs, is used in the Python script by default and should be installed automatically upon installing the cvxpy library. Other solvers can also be used, but they might require separate installation or licensing. See https://www.cvxpy.org/tutorial/solvers/index.html for a list of solvers supported by the cvxpy library and https://www.cvxpy.org/install/ for how to install them.

You can install these libraries using the line
```
pip install numpy pandas cvxpy
```

## Inputs

The program takes in three files: **demand**, **availability**, and **desired hours** spreadsheets. *They must be of the same format as the example spreadsheets in this folder*.

1. Demand matrix, which has either two dimensions (subject, timeslot) or two (subject, timeslot, campus). This is produced based on the *demand prediction* aspect of the project, done by Sebastian.

2. Availability matrix, which has either three dimensions (tutor, subject, timeslot) or four (tutor, subject, timeslot, campus).

3. Desired hours matrix, which has two dimensions (tutor and hours).

## Output

The program writes the schedule to a csv file, called `ans.csv` by default.

## Explanation of the code

```
import time

print("Importing modules...")

start_time = time.time()
import numpy as np
print("module imported: numpy, time used: " + str(time.time() - start_time) + " seconds")

start_time = time.time()
import pandas as pd
print("module imported: pandas, time used: " + str(time.time() - start_time) + " seconds")

start_time = time.time()
import csv
print("module imported: csv, time used: " + str(time.time() - start_time) + " seconds")

start_time = time.time()
import cvxpy
print("module imported: cvxpy, time used: " + str(time.time() - start_time) + " seconds")
```

Imports the necessary libraries. Numpy and pandas are not heavily used; pandas is only used for parsing the csv files as dataframes, which are then turned into numpy arrays for easier operations. The csv module is used for exporting the data in the end. The cvxpy library handles the main work of solving the integer program, by calling upon a solver such as GLPK_MI.

The dimension constants will be used when parsing the demand and availability matrices. When the program is run, the user will be given the option to modify the constants. **These constants must match the actual dimensions of the csv files.** Otherwise, there will be undefined behavior when parsing the spreadsheets. You need to change num_tutors to reflect the actual number of tutors, and change num_daily_timeslot to reflect the actual number of 30-minute timeslots in a day, etc.

The csv files are read in as pandas dataframes. This is the only place where the pandas library is used in the program: to hold the spreadsheet data in dataframes until they are converted to numpy arrays later. There might be a more efficient way to do this.
The parsing of the csv files is a little inelegant, but I don't know if there are any more efficient ways to do it.

The constraints are explained in the file `Schedule Optimization Formulation 2.pdf`.

## Areas for further work

1. Since integer programming scales up exponentially, having a huge integer program with many variables (as we do here!) can make the runtime horribly slow. It may be more efficient to run the program *iteratively*, e.g., the program only considers one campus in each run, but we would run this program multiple times, once for each campus, with different inputs. This could theoretically take less time (since 2^n + 2^m is generally less than 2^(n+m)), but there may be more consideration with having to adjust the availabilities after having run the program on the first campus. Specifically there may be complications with the online schedule, which tends to overlap a lot with the in-person schedules, while the in-person schedules have less overlap with each other.

2. The desired hours matrix is currently only used in a constraint that requires tutors do not work for more than their desired hours. However, the program might assign all available hours to one tutor, and assign no hours to another tutor. It might be possible to add a minimum number of hours for each tutor (though this has the risk of making the integer program infeasible) or to integrate the desired hours into the objective function somehow (though it is challenging to decide how to weigh the desired hours against the demand).
