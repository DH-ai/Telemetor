import threading
import csvtojson
import csv
import random
import time

"""
    ToDo 
    1. Implement two seperate threades 
    2. one is poulating a csv with random values
    3. the other thread is reading from the csv for any new values and saving it to a new csv

"""




def populate_csv():
    with open('D:/Obfuscation/telemetor/Backend/csv-temp/data.csv', 'w') as file:
        writer = csv.writer(file,lineterminator='\n')
        writer.writerow(['A', 'B', 'C', 'D', 'E'])
    for i in range(100):

        time.sleep(random.randint(2, 5))
        with open('D:/Obfuscation/telemetor/Backend/csv-temp/data.csv', 'a') as file:
            writer = csv.writer(file,lineterminator='\n')
            
            num = random.randint(1,10)
            for i in range(1, num):
                writer.writerow([random.randint(1,100) for j in range(5)])

            print(f"{time.thread_time()} Appended ",num-1," rows to the csv")

            
            
        
def read_csv():
    time.sleep(3)
    try:
        
        csv_obj = csvtojson.CsvToJson('D:/Obfuscation/telemetor/Backend/csv-temp/data.csv')
        csv_obj.readCsv(header=True,headerrows=1)
        while True:
            time.sleep(1)
            num = len(csv_obj.packet())
            if num>0:
                print("Packet: ",num,"Current Index: ",csv_obj.currentindex,csv_obj.header.headers)
            
    except Exception as e:
        print("Some error occured ",e)


def main ():
    
    t1 = threading.Thread(target=populate_csv)
    t2 = threading.Thread(target=read_csv)
    t1.start()
    t2.start()
    t1.join()
    t2.join()


main()
