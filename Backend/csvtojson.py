import csv 
# import  pandas as pd
import json
import errno
import time
import logging
from typing import Union


## changing all print statements to logging.error() and logging.info() statements



class Header:
    def __init__  (self, *args):
        try:
            self.headers = []
            self.types = [item[0] for item in args]
            for item in args:
                self.headers = self.headers + item
            for item in self.types:

                self.headers.remove(item)
        except Exception as e:
            logging.error("An error occured while creating header",e)
        finally:
            logging.info("Header created Headers{} Types{}".format(self.headers,self.types))
        
        
file_path = "D:/Obfuscation/telemetor/Backend/csv-temp/data.csv"
## Main csv to json converter class 
class  CsvToJson:
    def __init__(self, file_path=None,data:Union[dict,list]=None):
        assert (data is not None and file_path is  None) or (data is  None and file_path is not None), "Either data or file_path must be provided, but not both."
        self.file_path = file_path
        self.header:Header = None
        self.type:str = None
        self.data = None
        
        self.__currentindex = 0
        if file_path is None:
            self.data = data
            self.__currentindex = len(data)
            self.header = Header(*[data[header] for header in range(0,1)])
        self.jsonObj = None
        self.__lastindex = 0


    @property
    def currentindex(self):
        return self.__currentindex
    @currentindex.setter
    def currentindex(self, value):
        raise Exception("Can't set current index")
    
    def readCsv(self,header:bool=True,headerrows:int=2)-> None:
        
        try:
            if self.file_path is None and self.data is not None :
                raise Exception("Can't read csv when data is provided")
                
            with open(self.file_path, 'r') as file:
                reader = csv.reader(file)
                data = list(reader)
                self.data =data
                if header:
                    print("reading header")
                    try:
                        headers = [data[header] for header in range(0,headerrows)]
                        self.header = Header(* headers)
                    except Exception as e:
                        logging.error("An error occured while reading header",e)
                    
        except TypeError as e:
            
            print(f"File path can't be none {e}")
        except FileNotFoundError as e:
            print("File not found")
        except Exception as e:
            print(e)
        
        
        try:
            self._currentindex = len(self.data)
        except Exception as e:
            self._currentindex = 0
            print("Unable to set current index ",e)

    def printCSV(self,typ:str=None):

        if (typ=="H"or typ=="h"):
            print(list(item for item in self.header.headers))
        elif (typ=="T"or typ=="T"):
            print(list(item for item in self.header.types))
        else:
            print(list(item for item in self.header.headers))

    def convertToJson(self,data,ident:int= 4)-> str:
        jsonObj = {}
        jsonObj = json.dumps(data,indent=ident)
        return jsonObj

    def saveJson(self,optPath:str=None,name:str=None,data:str=None)-> None:
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

    def saveCSV(self,optPath:str=None,name:str=None,data:list=None)-> None:
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
    
    def __str__(self):
        return "CsvToJson"
      
    def __updateData(self):

        if self.file_path is not None:
            with open(self.file_path, 'r') as file:
                reader = csv.reader(file)
                data = list(reader)
                self.data = data
                
        else:
            self.data = self.data
            
    def packet(self):
        dictNew=list()
        for i in range(self.__lastindex,len(self.data)):
            dictNew.append(  self.data[i])
        self.__currentindex = len(self.data)-1
        self.__lastindex = self.__currentindex+1
        
        
        self.__updateData()
        return self.convertToJson(dictNew)

# data = [[1,2,3,4,5],[6,7,8,9,10],[11,12,13,14,15]]

# csv_obj = CsvToJson(data=data)

# print(csv_obj.packet())



