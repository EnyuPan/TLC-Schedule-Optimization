import csv
import json
import random
from perlin_noise import PerlinNoise

destination_filename = "Lite version/demand_matrix_2d.csv"

demand = []

with open("label_names.json", "r") as labels_f:
    labels = json.load(labels_f)
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
    demand.append([title] + [""] * num_timeslots - 1)

def timeslots_row(header, start_hour, end_hour):
    timeslots = [header]
    for day in days:
        for h in range(start_hour, end_hour):
            timeslots.append(day + " " + str(h) + ":00")
            timeslots.append(day + " " + str(h) + ":30")
    demand.append(timeslots)

def empty_row():
    title_row("")

def make_noise(noise, noise_index):
    return round(abs(noise(noise_index/25) * 10 * 5))

def make_online(consider_campuses=False):
    noise_seed = random.randint(0, 10000)
    noise = PerlinNoise(seed=noise_seed)
    noise_index = 0
    header = ""
    if consider_campuses:
        header = campuses[0]
    timeslots_row(header, online_start_hour, online_end_hour)
    for subject in subjects:
        s = [subject]
        for i in range(num_timeslots):
            s.append(str(make_noise(noise, noise_index)))
            noise_index += 1
        demand.append(s)
    if consider_campuses:
        empty_row()

# function to create multiple in-person demand matrices if consider_campuses=True, or one in-person matrix otherwise
def make_inperson(consider_campuses=False):
    noise_seed = random.randint(0, 10000)
    noise = PerlinNoise(seed=noise_seed)
    noise_index = 0
    if consider_campuses:
        for campus in range(1, len(campuses)):
            timeslots_row(campuses[campus])
            for subject in subjects:
                s = [subject]
                for day in range(inperson_start_day, inperson_end_day):
                    for i in range((online_start_hour - inperson_start_hour) * 2):
                        s.append("0")
                    for i in range((inperson_end_hour - inperson_start_hour) * 2):
                        s.append(str(make_noise(noise, noise_index)))
                        noise_index += 1
                    for i in range((online_end_hour - inperson_end_hour) * 2):
                        s.append("0")
                demand.append(s)
            empty_row()
    else:
        timeslots_row(subject, inperson_start_hour, inperson_end_hour)
        for subject in subjects:
            s = [subject]
            for i in range((inperson_end_hour - inperson_start_hour) * 2):
                s.append(str(make_noise(noise, noise_index)))
                noise_index += 1
            demand.append(s)
        empty_row()

make_online()

with open(destination_filename, mode='w', newline='') as f:
    writer = csv.writer(f)
    writer.writerows(demand)
