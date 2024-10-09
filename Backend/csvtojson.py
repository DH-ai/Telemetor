import csv 
import  pandas as pd
import json

class Header:
    def __init__  (self, *args):
        self.headers = []
        self.types = [item[0] for item in args]
        for item in args:
            self.headers = self.headers + item
        for item in self.types:

            self.headers.remove(item)
        
            
        

        


class CsvToJson:
    def __init__(self, file_path):
        self.file_path = file_path
        self.header = []
        self.type:str = None
        self.data = None
        with open(self.file_path, 'r') as file:
            reader = csv.reader(file)
            data = list(reader)
            self.data =data
            
            self.header = Header(self.data[0],self.data[1])

    def printTH(self,typ:str=None):
        if (typ=="H"or typ=="h"):
            print(list(item for item in self.header.headers))
        elif (typ=="T"or typ=="T"):
            print(list(item for item in self.header.types))
        else:
            print(list(item for item in self.header.headers))
            

          

CsvToJson('D:\Obfuscation/telemetor/Backend/rocket.csv').printTH()

