import csv
import json
import random

destination_filename = "desired_hours.csv"

desired_hours = []

with open("label_names.json", "r") as labels_f:
    labels = json.load(labels_f)
tutors = labels.get("tutors", [])

for tutor in tutors:
    desired_hours.append([tutor, str(random.randint(2, 26))])

with open(destination_filename, mode='w', newline='') as f:
    writer = csv.writer(f)
    writer.writerows(desired_hours)

