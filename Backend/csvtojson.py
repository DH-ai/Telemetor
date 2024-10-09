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
        
            
        

        

## Main csv to json converter class 
class CsvToJson:
    def __init__(self, file_path):
        self.file_path = file_path
        self.header = []
        self.type:str = None
        self.data = None
        self.jsonObj = None
        

    
    
    def readCsv(self):
        with open(self.file_path, 'r') as file:
            reader = csv.reader(file)
            data = list(reader)
            self.data =data
            
            self.header = Header(self.data[0],self.data[1])

    def printCSV(self,typ:str=None):

        if (typ=="H"or typ=="h"):
            print(list(item for item in self.header.headers))
        elif (typ=="T"or typ=="T"):
            print(list(item for item in self.header.types))
        else:
            print(list(item for item in self.header.headers))

    def convertToJson(self):
        jsonObj = {}

        return jsonObj



    def saveJson(self,optPath:str=None,name:str=None):
        pass
    def saveCSV(self,optPath:str=None,name:str=None):
        pass

    def nullCheck(self,Row:int=0,Col:int=None):
        pass

    
    

# CsvToJson('D:\Obfuscation/telemetor/Backend/rocket.csv').printTH()

dicti= {
    "key":12,
    "key":12,
    "key":12,
    "key2":{
        "hello":"1",
        "world":"223",
        "fuckk":123,
    }
}

packet=json.dumps(dicti,indent=4)