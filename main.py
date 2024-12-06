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

# start_time = time.time()
# import dask.array as darray
# print("module imported: dask.array, time used: " + str(time.time() - start_time) + " seconds")

# start_time = time.time()
# import dask.dataframe as df
# print("module imported: dask.dataframe, time used: " + str(time.time() - start_time) + " seconds")

start_time = time.time()
import cvxpy
print("module imported: cvxpy, time used: " + str(time.time() - start_time) + " seconds")

# start_time = time.time()
# from dask.diagnostics import ProgressBar
# print("module imported: dask.diagnostics, time used: " + str(time.time() - start_time) + " seconds")

# Toggle the campus dimension
consider_campuses = False
while True:
    s = input("Consider campuses as a dimension? (Y/N): ")
    if s == "Y" or s == "y":
        consider_campuses = True
        break
    elif s == "N" or s == "n":
        consider_campuses = False
        break

# Dimension constants
num_tutors = 53 # number of tutors (one tutor across different schedule is counted as one)
num_daily_timeslots = 24 # number of 30-minute timeslots in a day
num_days = 7 # number of days in a week
num_timeslots = num_days * num_daily_timeslots # number of 30-minute timeslots in a week
num_subjects = 6 # number of distinct tutoring subjects e.g. English, Math, Accounting
num_campuses = 6 # includes Online and each in-person campus

# Constraint constants
budget = 1000 # total number of budgeted work hours for all tutors collectively
weekly_limit = 48 # each tutor works no more than 24 hours (48 timeslots) a week
daily_limit = 14 # each tutor works no more than 7 hours (14 timeslots) a day
consecutive_time_limit = 10 # each tutor works no more than 5 hours (10 timeslots) consecutively without break
in_person_opening_time = 3 # in-person schedules start at 10 AM each day, which is the 3rd time slot of each day
in_person_closing_time = 16 # in-person schedules end at 5 PM each day, so the last time slot available is the 16th of each day

# Import data as 2D arrays
print("Importing demand and availability spreadsheets...")
try:
    if consider_campuses:
        demand_cells = pd.read_csv("demand_matrix_3d.csv", header=None)
        availability_cells = pd.read_csv("availability_matrix_4d.csv", header=None)
    else:
        demand_cells = pd.read_csv("Lite version/demand_matrix_2d.csv", header=None)
        availability_cells = pd.read_csv("Lite version/availability_matrix_3d_loweravailability.csv", header=None)
    desired_hours_cells = pd.read_csv("desired_hours.csv", header=None)
except Exception as error:
    print("Error when reading csv files", error)
    input("Press ENTER to exit")
    exit()

# Retrieve label names in each dimension as Dataframes; used for displaying result
if consider_campuses:
    tutor_names = availability_cells.iloc[2:2+num_tutors, 0].to_numpy()
    timeslot_names = availability_cells.iloc[1, 1:].to_numpy()
    subject_names = availability_cells.iloc[1:1+num_tutors*num_subjects:num_tutors+1, 0].to_numpy()
    campus_names = demand_cells.iloc[0:(num_subjects+1)*num_campuses:num_subjects+2, 0].to_numpy()
else:
    tutor_names = availability_cells.iloc[1:1+num_tutors, 0].to_numpy()
    timeslot_names = availability_cells.iloc[0, 1:].to_numpy()
    subject_names = demand_cells.iloc[1:1+num_subjects, 0].to_numpy()

# Construct demand matrix
print("Constructing demand matrix...")
if consider_campuses:
    demand = np.zeros((num_timeslots, num_subjects, num_campuses))
    for l in range(num_campuses):
        campus_start = (num_subjects + 2) * l # Start of the campus block
        demand[:,:,l] = demand_cells.iloc[campus_start+1:campus_start+num_subjects+1, 1:].T
else:
    demand = demand_cells.iloc[1:num_subjects+1, 1:num_timeslots+1].T.to_numpy()

# Construct availability matrix
print("Constructing availability matrix...")
if consider_campuses:
    availability = np.zeros((num_tutors, num_timeslots, num_subjects, num_campuses))
    for l in range(num_campuses):
        campus_start = ((num_tutors + 1) * num_subjects + 2) * l
        for k in range(num_subjects):
            subject_start = campus_start + 1 + (num_tutors + 1) * k
            availability[:,:,k,l] = availability_cells.iloc[subject_start+1:subject_start+num_tutors+1, 1:]
else:
    availability = np.zeros((num_tutors, num_timeslots, num_subjects))
    for k in range(num_subjects):
        subject_start = 1 + (num_tutors + 1) * k
        availability[:, :, k] = availability_cells.iloc[subject_start:subject_start+num_tutors,1:num_timeslots+1]

# Construct desired hours matrix
desired_hours = desired_hours_cells.iloc[:, 1].to_numpy()

#TODO: use absolute path referencing with the csv files

# Decision variables
if consider_campuses:
    x = cvxpy.Variable((num_tutors, num_timeslots, num_subjects, num_campuses), boolean=True)
else:
    x = cvxpy.Variable((num_tutors, num_timeslots, num_subjects), boolean=True)

print("Setting up availability constraints...")
availability_constr = []
for i in range(num_tutors):
    for j in range(num_timeslots):
        for k in range(num_subjects):
            if consider_campuses:
                for l in range(num_campuses):
                    if availability[i, j, k, l] == 0:
                        availability_constr.append(x[i, j, k, l] == 0)
            else:
                if availability[i, j, k] == 0:
                    availability_constr.append(x[i, j, k] == 0)

print("Setting up no-multiple-bookings constraints...")
no_multiple_bookings_constr = []
if consider_campuses:
    for i in range(num_tutors):
        for j in range(num_timeslots):
            no_multiple_bookings_constr.append(cvxpy.sum(x[i, j, :, :]) <= 1)
else:
    for i in range(num_tutors):
        for j in range(num_timeslots):
            no_multiple_bookings_constr.append(cvxpy.sum(x[i, j, :]) <= 1)

print("Setting up weekly maximum constraints...")
weekly_max_constr = []
if consider_campuses:
    for i in range(num_tutors):
        weekly_max_constr.append(cvxpy.sum(x[i, :, :, :]) <= weekly_limit)
else:
    for i in range(num_tutors):
        weekly_max_constr.append(cvxpy.sum(x[i, :, :]) <= weekly_limit)

print("Setting up daily maximum constraints...")
daily_max_constr = []
if consider_campuses:
    for d in range(num_days):
        daily_max_constr.append(cvxpy.sum(x[:, num_daily_timeslots * d:num_daily_timeslots * (d + 1), :, :],\
            axis=(1, 2, 3)) <= daily_limit)
else:
    for d in range(num_days):
        daily_max_constr.append(cvxpy.sum(x[:, num_daily_timeslots * d:num_daily_timeslots * (d + 1), :],\
            axis=(1, 2)) <= daily_limit)

print("Setting up break constraints...")
break_constr = []
if consider_campuses:
    for d in range(num_days):
        for t in range(num_daily_timeslots - consecutive_time_limit):
            break_constr.append(cvxpy.sum(x[:, num_daily_timeslots * d + t:num_daily_timeslots * d + t + consecutive_time_limit + 1, :, :],\
                axis=(1, 2, 3)) <= consecutive_time_limit)
else:
    for d in range(num_days):
        for t in range(num_daily_timeslots - consecutive_time_limit):
            break_constr.append(cvxpy.sum(x[:, num_daily_timeslots * d + t:num_daily_timeslots * d + t + consecutive_time_limit + 1, :],\
                axis=(1, 2)) <= consecutive_time_limit)

print("Setting up desired hours constraints...")
desired_hours_constr = []
if consider_campuses:
    desired_hours_constr.append(cvxpy.sum(x, axis=(1, 2, 3)) <= desired_hours)
else:
    desired_hours_constr.append(cvxpy.sum(x, axis=(1, 2)) <= desired_hours)

print("Setting up budget constraint...")
budget_constr = []
budget_constr.append(cvxpy.sum(x) <= budget)

# Optimization problem
print("Creating optimization problem...")

# objective = cvxpy.Minimize(cvxpy.sum_squares(demand - cvxpy.sum(x, axis=0)))
underage = cvxpy.pos(demand - cvxpy.sum(x, axis=0))
overage = cvxpy.pos(cvxpy.sum(x, axis=0) - demand)
objective = cvxpy.Minimize(cvxpy.sum(underage + overage))
# objective = cvxpy.Minimize(cvxpy.sum(demand - cvxpy.sum(x, axis=0)))
# objective = cvxpy.Minimize(cvxpy.sum(cvxpy.abs(demand - cvxpy.sum(x, axis=0))))
constraints = []
constraints.extend(availability_constr)
constraints.extend(no_multiple_bookings_constr)
constraints.extend(weekly_max_constr)
constraints.extend(daily_max_constr)
constraints.extend(break_constr)
constraints.extend(desired_hours_constr)
constraints.extend(budget_constr)
prob = cvxpy.Problem(objective, constraints)

# Solve the problem
print("Solving optimization problem...")
if consider_campuses:
    print("This could take around 30 minutes.")
prob.solve(solver='GLPK_MI', verbose=True)
# prob.solve(solver='GUROBI', verbose=True)

print(prob.status)
print("Objective value:", prob.value)
destination_filename = "ans.csv"
with open(destination_filename, mode = "w", newline = "") as f:
    writer = csv.writer(f)
    if consider_campuses:
        for l in range(num_campuses):
            if l > 0:
                writer.writerow([])
            writer.writerow([campus_names[l]])
            for k in range(num_subjects):
                writer.writerow(np.concatenate(([subject_names[k]], timeslot_names)))
                for i in range(num_tutors):
                    writer.writerow(np.concatenate(([tutor_names[i]], x.value[i, :, k, l])))
    else:
        for k in range(num_subjects):
            if k > 0:
                writer.writerow([])
            writer.writerow(np.concatenate(([subject_names[k]], timeslot_names)))
            for i in range(num_tutors):
                writer.writerow(np.concatenate(([tutor_names[i]], x.value[i,:,k])))
print("Result written to", destination_filename)

input("Press ENTER to quit")
