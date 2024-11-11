% dimension constants; must be entered manually
num_tutors = 53; % number of tutors (same tutor across different schedules is counted as one tutor)
num_daily_timeslots = 24; % number of 30-minute timeslots in a day
num_days = 7; % number of days in a week
num_timeslots = num_daily_timeslots * num_days; % number of 30-minute timeslots in a week
num_subjects = 6; % number of distinct tutoring subjects e.g. English, Math, Accounting
num_campuses = 6; % includes Online and each in-person campus

% constraint constants
weekly_limit = 48; % each tutor works no more than 24 hours (48 timeslots) a week
daily_limit = 14; % each tutor works no more than 7 hours (14 timeslots) a day
consecutive_time_limit = 10; % each tutor works no more than 5 hours (10 timeslots) consecutively without break
in_person_opening_time = 3; % in-person schedules start at 10 AM each day, which is the 3rd time slot of each day
in_person_closing_time = 16; % in-person schedules end at 5 PM each day, so the last time slot available is the 16th of each day

% import data as 2D cell arrays
demand_cells = readcell('demand_matrix_3d.csv');
availability_cells = readcell('availability_matrix_4d.csv');

% retrieve label names in each dimension; used for displaying the data in
% the end
tutor_names = availability_cells(3:3+num_tutors-1, 1)';
timeslot_names = availability_cells(2, 2:end);
subject_names = availability_cells(2:num_tutors+1:2+num_tutors*num_subjects, 1)';
campus_names = demand_cells(1:num_subjects+1:1+num_subjects*num_campuses, 1)';

% construct demand matrix
demand = zeros(num_timeslots, num_subjects, num_campuses);
for l = 1:num_campuses
    campus_start = 1 + (num_subjects + 1) * (l - 1); % the row number on which data for this campus begins
    demand(1:num_timeslots, 1:num_subjects, l) = cell2mat(demand_cells(campus_start+1:campus_start+num_subjects, 2:end))';
end

% construct availability matrix
availability = zeros(num_tutors, num_timeslots, num_subjects, num_campuses);
for l = 1:num_campuses
    campus_start = 1 + ((num_tutors + 1) * num_subjects + 1) * (l - 1);
    for k = 1:num_subjects
        subject_start = campus_start + 1 + (num_tutors + 1) * (k - 1);
        availability(1:num_tutors, 1:num_timeslots, k, l) = cell2mat(availability_cells(subject_start+1:subject_start+num_tutors,2:end));
    end
end

% decision variables
x = optimvar('x', num_tutors, num_timeslots, num_subjects, num_campuses, 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);

% setting up constraints
availability_constr = optimconstr(num_tutors, num_timeslots, num_subjects, num_campuses);
no_multiple_bookings_constr = optimconstr(num_tutors, num_timeslots);
no_consecutive_at_different_campuses_constr = optimconstr(num_tutors, num_timeslots - 1, num_subjects, num_subjects, num_campuses, num_campuses);
in_person_constr = optimconstr(num_tutors, num_timeslots, num_subjects, num_campuses);
weekly_max_constr = optimconstr(num_tutors);
daily_max_constr = optimconstr(num_tutors, num_days-1);
break_constr = optimconstr(num_tutors, num_days-1, num_daily_timeslots);

% availability constraint (tutors should not work in spots where they are
% marked as 0 in the availability matrix)
unavailable_spots = availability == 0; % all indices at which the availability matrix is 0
availability_constr(unavailable_spots) = x(unavailable_spots) == 0;

% no multiple bookings at the same time constraint (the same tutor should
% not be on the schedule for different subjects or different campuses at
% the same time slot
no_multiple_bookings_constr = sum(x, [3, 4]) <= 1;

% no consecutive time slots at different campuses (each contiguous shift
% must take place at the same campus
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

% To be implemented: in-person_constr, weekly_max_constr, daily_max_constr, break_constr

% optimization problem
prob = optimproblem('ObjectiveSense', 'minimize');
prob.Objective = sum((demand - squeeze(sum(x, 1))).^2, 'all');
prob.Constraints.availability_constr = availability_constr;
prob.Constraints.no_multiple_bookings_constr = no_multiple_bookings_constr;
%prob.Constraints.no_consecutive_at_different_campuses_constr = no_consecutive_at_different_campuses_constr;
%prob.Constraints.in_person_constr = in_person_constr;
%prob.Constraints.weekly_max_constr = weekly_max_constr;
%prob.Constraints.daily_max_constr = daily_max_constr;
%prob.Constraints.break_constr = break_constr;

% solve the problem
%sol = solve(prob);
