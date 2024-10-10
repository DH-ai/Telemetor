import thread 
import csvtojson
import csv
import random

"""
    ToDo 
    1. Implement two seperate threades 
    2. one is poulating a csv with random values
    3. the other thread is reading from the csv for any new values and saving it to a new csv

"""
def populate_csv():
    while True:
        with open('data.csv', 'w') as file:
            writer = csv.writer(file,lineterminator='\n',separator=',')
            writer.header(['a','b','c','d','e'])
            writer.writerow([random.randint(0, 9) for i in range(5)])
    pass

def main():

