import csv 
# import  pandas as pd
import json
import errno

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

    def convertToJson(self,data=None):
        jsonObj = {}
        jsonObj = json.dumps(data)
        return jsonObj

    def saveJson(self,optPath:str=None,name:str=None,data:str=None):
        jsonObj = json.loads(data)
        jsonFile = optPath+"/"+name+".json"
        try:
            with open(jsonFile, 'w') as file:
                json.dump(jsonObj, file,indent=0)
        except FileNotFoundError as e:
            print(errno.ENOENT)
            print("File not found")
        except Exception as e:
            print(e)
            print("An error occured")
        else:
            print("File saved as "+name+".json")

    def saveCSV(self,optPath:str=None,name:str=None,data:list=None):
        csvFile = optPath+"/"+name+".csv"
        data = iter(data)
        try:
            with open(csvFile, 'w') as file:
                writer = csv.writer(file,lineterminator='\n')
                for item in data:
                    writer.writerow(item)           
        except FileNotFoundError as e:
            print(errno.ENOENT)
            print("File not found")
        except Exception as e:
            print(e)
            print("An error occured")
        else:
            print("File saved as "+name+".csv")

    def 


    def nullCheck(self,Row:int=0,Col:int=None):     
        
        pass

    
    

dicti = list((
    {1,2,3,4,5},
    {2,3,4,4,55},
    {13,22,23,43,35},
)
)
CsvToJson("D:/Obfuscation/telemetor/Backend/rocket.csv").saveCSV(".", "test", dicti)



