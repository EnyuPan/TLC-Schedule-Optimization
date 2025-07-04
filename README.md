# TLC Schedule Optimization

## Overview

The goal of the project is to automate the creation of schedules for tutors at the Tutoring and Learning Centre. The finished product should analyze appointment data from past terms to determine the demand levels for each timeslot in the week and subject, then create an optimal weekly schedule for tutors based on demand, availability, and the tutors' desired hours, by solving an integer program.

Part of the problem's integer program formulation was done by Louise and Nitya, the Tutoring and Learning Centre assistants from Spring/Summer 2024, with guidance from Sullivan, the math advisor. The formulation was expanded by Enyu to the current version in Fall 2024. The file `Schedule Optimization Formulation 2.pdf` contains the current integer program formulation of the problem, which is important to understanding how the program works.

Two aspects of the project were worked on between Fall 2024 and Winter 2025:

- Demand prediction: analyzing appointment data on WCO, our booking website, using a linear regression model and predicting the demand for tutoring. This was implemented by Sebastian in the file `Demand Prediction\Schedule optim.R`. Its documentation can be found at `Demand Prediction\R documentation.pdf`.

- Schedule creation: implementing and solving the integer program according to the formulation, using the demand data outputted by the first part. The Python script (`main.py`), made by Enyu, implements this integer program and solves it using the `cvxpy` library.

The demand prediction program takes in data from WCO and uses it to build a linear regression model to predict the demand. It works by taking the data from WCO, which stores information by individual appointments, and transforming it to be stored by appointment times.

The schedule creation Python script takes a long time to run (30 minutes or more) if campus is considered; when last tested, it takes up to 17 minutes if campus is not considered.

## Requirements

For the *demand prediction* R script (`Demand Prediction\Schedule optim.R`), you will need the following installed:

* R, an open-source Statistics-based language
* R-studio, which while not required, is a useful IDE for R, and was used to compile the documentation for the R script.

To run the *schedule creation* Python script (`main.py`), you need Python installed, as well as the following libraries:

* numpy
* pandas
* cvxpy
    * The cvxpy library formulates the integer program and delegates the job of solving it to a specific solver. The GLPK_MI solver, for handling mixed-integer programs, is used in the Python script by default and should be installed automatically upon installing the cvxpy library. Other solvers can also be used, but they might require separate installation or licensing. If a squared-difference objective function is used, see [this page](https://www.cvxpy.org/examples/basic/mixed_integer_quadratic_program.html) for solvers that support mixed-integer quadratic programs. See [here](https://www.cvxpy.org/tutorial/solvers/index.html) for a list of solvers supported by the cvxpy library and [how to install them](https://www.cvxpy.org/install/).

Numpy and pandas are not heavily used; pandas is only used for parsing the csv files as dataframes, which are then turned into numpy arrays for easier operations. The csv module is used for exporting the data in the end. The cvxpy library handles the main work of solving the integer program.

You can install these libraries using pip on the terminal:
```
pip install numpy pandas cvxpy
```

## Inputs

The demand prediction script requires only 1 input file: The exported Excel file from "system data export" from WCO. It requires the same export that is used for 1-on-1 statistics, which is the default.

The schedule creation script `main.py` takes in three files: **demand**, **availability**, and **desired hours** spreadsheets. The information they represent is described in more detail in the file `Schedule Optimization Formulation 2.pdf`. They must be placed in the same directory as the script file (`main.py`), and *they must be in the same format as the example spreadsheets in this folder* (described below).

Either three or four dimensions will be considered in the optimization: **tutor**, **subject**, **timeslot**, and **campus (*optional*)**. When run, the program will prompt the user whether to consider campus as a dimension or not. Depending on whether campus is considered, the input files would have to be in different formats and have different names.

The input files are as follows:

1. Demand matrix, which has either two dimensions (subject, timeslot) or three (subject, timeslot, campus), depending on whether campus is considered. The demand matrix is produced based on the *demand prediction* aspect of the project done by Sebastian.
    * If campus is considered, it should be structured in blocks representing campuses (with their names on the top-left of each block), with each subject as a row and each timeslot as a column.
    * If campus is not considered, it should simply have one block, with each subject as a row and each timeslot as a column.
    * The file name should be `demand_matrix_3d.csv` (if campus is considered) or `demand_matrix_2d.csv` (otherwise). The program chooses which of the two file names to read based on whether campus is considered.

2. Availability matrix, which has either three dimensions (tutor, subject, timeslot) or four (tutor, subject, timeslot, campus). This is obtained by asking the tutors to provide their availabilities throughout the week. They should provide *all times* during which they can potentially work, even if they might not be assigned shifts in all of their indicated availabilities. Each entry of the matrix is either 0 or 1.
    * If campus is considered, it should be structured in large blocks representing campuses, each of which cotains smaller blocks representing subjects. Each smaller block has each tutor as a row and each timeslot as a column. (See the example spreadsheet).
    * If campus is not considered, it should be structured in blocks representing subjects, with each tutor as a row and each timeslot as a column.
    * The file name should be `availability_matrix_4d.csv` or `availability_matrix_3d.csv`.

3. Desired hours matrix, which has two dimensions (tutor and hours). This is obtained by asking the tutors *at most* how many hours they are willing to work each week.
    * This spreadsheet is formatted the same whether campus is considered or not. It has only two columns: the first column has the names of each tutor, and the second column has the tutor's maximum desired number of timeslots per week.
    * *The order in which the tutors are listed must be the same as in the availability matrix.*
    * The file name should be `desired_hours.csv`.

## Configuration
The schedule creation program `main.py` gives the user the following prompts when run:

* Consider campuses as a dimension? (Y/N)
    * If campus is considered, the program uses the 4D formulation (tutor, timeslot, subject, campus) and reads from `demand_matrix_3d.csv` and `availability_matrix_4d.csv`.
    * If campus is not considered, the program uses the 3D formulation (tutor, timeslot, subject) and reads from `demand_matrix_2d.csv` and `availability_matrix_3d.csv`.

* Dimension constants: The program displays the default values for dimensions (number of tutors, timeslots, subjects, and campuses) and gives the user the option to enter new values for them if needed. The dimension constants will be used when parsing the demand and availability matrices. When the program is run, the user will be given the option to modify the constants. **These constants must match the actual dimensions of the csv files.** Otherwise, there will be undefined behavior when parsing the spreadsheets. You need to change `num_tutors` to reflect the actual number of tutors, and change `num_daily_timeslot` to reflect the actual number of 30-minute timeslots in a day, etc. The dimension constants are:
    * `num_tutors`: number of tutors (one tutor across different schedules is counted as one)
    * `num_daily_timeslots`: number of 30-minute timeslots in a day
    * `num_days`: number of days in a week
    * `num_subjects`: number of distinct tutoring subjects e.g. English, Math, Accounting
    * `num_campuses`: number of campuses

* Constraint constants: The program displays the default values for constraints (budget, weekly/daily/consecutive hour limits, etc.) and gives the user the option to enter new values for them if needed. The constraint constants are:
    * `budget`: total number of budgeted work hours for all tutors collectively
    * `weekly_limit`: each tutor works no more than 24 hours (48 timeslots) a week
    * `daily_limit`: each tutor works no more than 7 hours (14 timeslots) a day
    * `consecutive_time_limit`: each tutor works no more than 5 hours (10 timeslots) consecutively without break
    * `in_person_opening_time`: in-person schedules start at 10 AM each day, which is the 3rd time slot of each day
    * `in_person_closing_time`: in-person schedules end at 5 PM each day, so the last time slot available is the 16th of each day

## Output

The program writes the schedule to a csv file, named `ans.csv` by default.

## Areas for further work

* Currently, the appointment counter in the R program runs in O(nm) time, where n is the number of appointments and m is the number of timeslots. We could implememnt a faster algorithm that uses a binary search algorithm to find the time and day an appointment takes place, and that would run in O(nlog(m)) which, for large data pools, is significantly faster.

* Currently, the R code genereates a linear model in R, which is not the format required for `main.py`. To ammend this, there needs to be a function that creates an output file that could be inputted into the demand matrix for the optimization program. To do this, you should predict for each week, campus and subject and then create a CSV output as shown on the Demand matrix (see the example spreadsheets `demand_matrix_2d.csv` and `demand_matrix_3d.csv`) so that it can be used an input for `main.py`.

* When tested with the example matrices, there is the problem that when many schedules (i.e., combinations of subjects and campuses) are considered, only the first few schedules are filled out, while few or no tutors are assigned to the later schedules. Also, since the weekly maximum constraint limits each tutor to at most 48 timeslots a week, a tutor often has all 48 timeslots allotted to the same subject and campus, and has no hours allotted to other subjects and campuses. This is likely because when there is freedom in choosing where to place the 48 allotted timeslots, the program defaults to placing them in the first few schedules, and there is no incentive for spreading them out across schedules. This should not be a significant problem in practice since most tutors are mainly relegated to one subject and one campus, although tutors who work both online and in person do need to be spread out between at least two campuses.

* Since integer programming scales up exponentially, having a huge integer program with many variables (as we do here!) can make the runtime horribly slow. Some possible ways to remedy this:
    * It may be more efficient to run the program *iteratively*, e.g., the program only considers one campus in each run, but we would run this program multiple times, once for each campus, with different inputs. This could theoretically take less time (since 2<sup>n</sup> + 2<sup>m</sup> is generally less than 2<sup>n+m</sup>), but there may be more consideration with having to adjust the availabilities after having run the program on the first campus. Specifically there may be complications with the online schedule, which tends to overlap a lot with the in-person schedules, while the in-person schedules have less overlap with each other.
    * Since considering campuses causes the program to become a lot more expensive, it may be sufficient to consider only one online schedule and one in-person schedule instead of having one block for each campus, since most tutors work mainly at one campus.
    * We could also reduce the number of subjects. Study Skills is not typically in high demand and is very tutor-dependent, and Accounting could be removed since it is mainly limited to the 200 King campus, and most math tutors at 200 King can also tutor accounting.

* The desired hours matrix is currently only used in a constraint that requires tutors do not work for more than their desired hours. However, the program might assign all available hours to one tutor, and assign no hours to another tutor. It might be possible to add a minimum number of hours for each tutor (though this has the risk of making the integer program infeasible) or to integrate the desired hours into the objective function somehow (though it is challenging to decide how to weigh the desired hours against the demand).

* The budget is currently a single integer representing the total number of hours that can be allocated across all tutors. In practice, there may be separate budgets for each subject, which would require updating the budget constraint.

* The output schedule is formatted in the same way as the availability matrix, with 1's and 0's representing whether a tutor is working at a certain timeslot for a certain subject at a certain campus. If a different output format could be more readable (e.g. "Areej: Mon 9 - 11 AM, Wed 11 AM - 3 PM"), then the output section of the program could be revised to account for different formats.

* Currently, time is allocated by generating all days between the start and end date given, and gave all possible slots from 9AM - 9PM for every schedule which. But different schedules work on different hours (like most in-person schedules working from 10-5), and the program generates for dates even where the schedule might be closed (like in-person not being open on weekdays.)

* We also need to find a way to filter out dates - the TLC is not open every day of the year, and the 0 results can affect the model significantly, and since there is currently no interaction terms, can affect the paramaters of different schedules. There needs to be a way to filter out when the scheudle isn't open on a schedule basis.
