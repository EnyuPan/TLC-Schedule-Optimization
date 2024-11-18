% dimension constants; must be entered manually
num_tutors = 53; % number of tutors (same tutor across different schedules is counted as one tutor)
num_daily_timeslots = 24; % number of 30-minute timeslots in a day
num_days = 7; % number of days in a week
num_timeslots = num_daily_timeslots * num_days; % number of 30-minute timeslots in a week
num_subjects = 6; % number of distinct tutoring subjects e.g. English, Math, Accounting
num_campuses = 6; % includes Online and each in-person campus

% constraint constants
budget = 1000; % total number of budgeted work hours for all tutors collectively
weekly_limit = 48; % each tutor works no more than 24 hours (48 timeslots) a week
daily_limit = 14; % each tutor works no more than 7 hours (14 timeslots) a day
consecutive_time_limit = 10; % each tutor works no more than 5 hours (10 timeslots) consecutively without break
in_person_opening_time = 3; % in-person schedules start at 10 AM each day, which is the 3rd time slot of each day
in_person_closing_time = 16; % in-person schedules end at 5 PM each day, so the last time slot available is the 16th of each day

% import data as 2D cell arrays
fprintf("Importing input csv files...\n")
demand_cells = readcell('demand_matrix_3d.csv');
availability_cells = readcell('availability_matrix_4d.csv');

% import and parse the desired hours spreadsheet; requires that tutors are 
% listed in the same order as in the availability matrix
desired_hours_cells = readcell('desired_hours.csv');
desired_hours = cell2mat(desired_hours_cells(:, 2));

% retrieve label names in each dimension; used for displaying the data in
% the end
tutor_names = availability_cells(3:3+num_tutors-1, 1)';
timeslot_names = availability_cells(2, 2:end);
subject_names = availability_cells(2:num_tutors+1:2+num_tutors*num_subjects, 1)';
campus_names = demand_cells(1:num_subjects+1:1+num_subjects*num_campuses, 1)';

% construct demand matrix
fprintf("Constructing demand matrix...\n")
demand = zeros(num_timeslots, num_subjects, num_campuses);
for l = 1:num_campuses
    campus_start = 1 + (num_subjects + 1) * (l - 1); % the row number on which data for this campus begins
    demand(1:num_timeslots, 1:num_subjects, l) = cell2mat(demand_cells(campus_start+1:campus_start+num_subjects, 2:end))';
end

% construct availability matrix
fprintf("Constructing availability matrix...\n")
availability = zeros(num_tutors, num_timeslots, num_subjects, num_campuses);
for l = 1:num_campuses
    campus_start = 1 + ((num_tutors + 1) * num_subjects + 1) * (l - 1);
    for k = 1:num_subjects
        subject_start = campus_start + 1 + (num_tutors + 1) * (k - 1);
        availability(1:num_tutors, 1:num_timeslots, k, l) = cell2mat(availability_cells(subject_start+1:subject_start+num_tutors,2:end));
    end
end

% decision variables
% Note: for efficiency purposes, each variable is not required to be
% integer. The optimization problem would be too large otherwise.
x = optimvar('x', num_tutors, num_timeslots, num_subjects, num_campuses, 'LowerBound', 0, 'UpperBound', 1);

% setting up constraints
availability_constr = optimconstr(num_tutors, num_timeslots, num_subjects, num_campuses);
no_multiple_bookings_constr;
no_consecutive_at_different_campuses_constr = optimconstr(num_tutors, num_timeslots - 1, num_subjects, num_subjects, num_campuses, num_campuses);
in_person_constr;
weekly_max_constr = optimconstr(num_tutors);
daily_max_constr = optimconstr(num_tutors, num_days);
break_constr = optimconstr(num_tutors, num_days, num_daily_timeslots);
desired_hours_constr;
budget_constr;

% availability constraint (tutors should not work in spots where they are
% marked as 0 in the availability matrix)
fprintf("Setting up availability constraints...\n")
unavailable_spots = availability == 0; % all indices at which the availability matrix is 0
availability_constr(unavailable_spots) = x(unavailable_spots) == 0;

% no multiple bookings at the same time constraint (the same tutor should
% not be on the schedule for different subjects or different campuses at
% the same time slot)
fprintf("Setting up no-multiple-bookings constraints...\n")
no_multiple_bookings_constr = sum(x, [3, 4]) <= 1;

% no consecutive time slots at different campuses constraint (each
% contiguous shift must take place at the same campus)
fprintf("Setting up no-consecutive-timeslots-at-different-campuses constraints...\n")
campus_pairs = nchoosek(1:num_campuses, 2); % list of distinct campus pairs l_1 and l_2
for r = 1:size(campus_pairs, 1)
    l1 = campus_pairs(r, 1);
    l2 = campus_pairs(r, 2);
    for k1 = 1:num_subjects
        for k2 = 1:num_subjects
            no_consecutive_at_different_campuses_constr(:, :, k1, k2, l1, l2) = x(:, 1:end-1, k1, l1) + x(:, 2:end, k2, l2) <= 1;
        end
    end
end

% online vs. in-person schedules constriant: in-person appointments are not
% open on weekends or before 9 AM or after 5 PM
fprintf("Setting up online vs. in-person schedules constraints...\n")
non_operating = false(num_tutors, num_timeslots, num_subjects, num_campuses); % logical arrays representing indices of non-operating hours at in-person campuses
non_operating(:, (1:num_timeslots) >= 121 | mod((1:num_timeslots) - 1, num_daily_timeslots) + 1 < in_person_opening_time | mod((1:num_timeslots) - 1, num_daily_timeslots) > in_person_closing_time, :, (1:num_campuses) >= 2) = true;
in_person_constr = x(non_operating) == 0;

% daily max working hours constraint
fprintf("Setting up daily maximum constraints...\n")
for d = 1:num_days
    daily_max_constr(:, d) = sum(x(:, num_daily_timeslots * (d-1) + (1:num_daily_timeslots), :, :), [2, 3, 4]) <= daily_limit;
end

% break constraint
fprintf("Setting up break constraints...\n")
for d = 1:num_days
    for t = 1:num_daily_timeslots - consecutive_time_limit
        break_constr(:, d, t) = sum(x(:, num_daily_timeslots * (d-1) + t + (0:consecutive_time_limit), :, :), [2, 3, 4]) <= consecutive_time_limit;
    end
end

% weekly_max_constr
% To be formulated: minimum per day/week constraint

% desired hours budget
fprintf("Setting up desired hours constraints...\n")
desired_hours_constr = sum(x, [2, 3, 4]) <= desired_hours;

% budget constraint
fprintf("Setting up budget constraint...\n")
budget_constr = sum(x, 'all') <= budget;

% optimization problem
fprintf("Creating optimization problem...\n")
prob = optimproblem('ObjectiveSense', 'minimize');
prob.Objective = sum((demand - squeeze(sum(x, 1))).^2, 'all');
prob.Constraints.availability_constr = availability_constr;
prob.Constraints.no_multiple_bookings_constr = no_multiple_bookings_constr;prob.Constraints.no_consecutive_at_different_campuses_constr = no_consecutive_at_different_campuses_constr;
prob.Constraints.in_person_constr = in_person_constr;
if max(desired_hours) > weekly_limit % enforce weekly limit only if some desired hours are too large
    prob.Constraints.weekly_max_constr = weekly_max_constr;
end
prob.Constraints.daily_max_constr = daily_max_constr;
prob.Constraints.break_constr = break_constr;
prob.Constraints.desired_hours_constr = desired_hours_constr;
if sum(desired_hours) > budget % enforce budget constraint only if sum of desired hours is too large
    prob.Constraints.budget_contr = budget_constr;
end

% solve the problem
fprintf("Beginning solution. This could take around 20 minutes.")
sol = solve(prob);
%sol.x(:,5,1,1)
