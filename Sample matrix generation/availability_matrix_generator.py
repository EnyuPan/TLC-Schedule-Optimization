import csv
import json
import random
from perlin_noise import PerlinNoise

consider_campuses = False
while True:
    s = input("Consider campuses as a dimension? (Y/N): ")
    if s == "Y" or s == "y":
        consider_campuses = True
        break
    elif s == "N" or s == "n":
        consider_campuses = False
        break

online = False
if not(consider_campuses):
    while True:
        s = input("Choose between online (O) or in-person (I) schedule: ")
        if s == "O" or s == "o":
            online = True
            break
        elif s == "I" or s == "i":
            online = False
            break

if consider_campuses:
    destination_filename = "availability_matrix_4d.csv"
else:
    destination_filename = "availability_matrix_3d.csv"

availability = []

with open("Sample matrix generation/label_names.json", "r") as labels_f:
    labels = json.load(labels_f)
tutors = labels.get("tutors", [])
days = labels.get("days", [])
subjects = labels.get("subjects", [])
campuses = labels.get("campuses", [])

num_days = 7
num_daily_timeslots = 24
num_timeslots = num_days * num_daily_timeslots
online_start_hour = 9
online_end_hour = int(online_start_hour + num_timeslots / num_days / 2)
inperson_start_hour = 10
inperson_end_hour = 17
inperson_start_day = 1
inperson_end_day = 6

def title_row(title):
    availability.append([title] + [""] * (num_timeslots - 1))

def timeslots_row(header, start_hour, end_hour):
    timeslots = [header]
    for day in days:
        for h in range(start_hour, end_hour):
            timeslots.append(day + " " + str(h) + ":00")
            timeslots.append(day + " " + str(h) + ":30")
    availability.append(timeslots)

def empty_row():
    title_row("")

def make_noise(noise, noise_index):
    return min(1, round(abs(noise(noise_index/50)) * 10))

def make_online(consider_campuses=False):
    noise_seed = random.randint(0, 10000)
    noise = PerlinNoise(seed=noise_seed)
    noise_index = 0
    if consider_campuses:
        title_row(campuses[0])
    for subject in subjects:
        timeslots_row(subject, online_start_hour, online_end_hour)
        for tutor in tutors:
            s = [tutor]
            for i in range(num_timeslots):
                s.append(str(make_noise(noise, noise_index)))
                noise_index += 1
            availability.append(s)
    if consider_campuses:
        empty_row()

# function to create multiple in-person availability matrices if consider_campuses=True, or one in-person availability matrix otherwise
def make_inperson(consider_campuses=False):
    noise_seed = random.randint(0, 10000)
    noise = PerlinNoise(seed=noise_seed)
    noise_index = 0
    if consider_campuses:
        for campus in range(1, len(campuses)):
            title_row(campuses[campus])
            for subject in subjects:
                # if different campuses are considered, every campus should have the same dimensions
                timeslots_row(subject, online_start_hour, online_end_hour)
                for tutor in tutors:
                    s = [tutor]
                    for day in range(inperson_start_day, inperson_end_day):
                        for i in range((online_start_hour - inperson_start_hour) * 2):
                            s.append("0")
                        for i in range((inperson_end_hour - inperson_start_hour) * 2):
                            s.append(str(make_noise(noise, noise_index)))
                            noise_index += 1
                        for i in range((online_end_hour - inperson_end_hour) * 2):
                            s.append("0")
                    for i in range((num_days - inperson_end_day + inperson_start_day) * num_daily_timeslots):
                        s.append("0")
                    availability.append(s)
            empty_row()
    else:
        for subject in subjects:
            timeslots_row(subject, inperson_start_hour, inperson_end_hour)
            for tutor in tutors:
                s = [tutor]
                for i in range((inperson_end_hour - inperson_start_hour) * 2):
                    s.append(str(make_noise(noise, noise_index)))
                    noise_index += 1
                availability.append(s)
            empty_row()

if consider_campuses:
    make_online(consider_campuses=True)
    make_inperson(consider_campuses=True)
elif online:
    make_online(consider_campuses=False)
else:
    make_online(consider_campuses=False)

with open(destination_filename, mode='w', newline='') as f:
    writer = csv.writer(f)
    writer.writerows(availability)
