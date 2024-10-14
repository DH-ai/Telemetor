import socket
import threading
from  csvtojson import CsvToJson
import random
import time 
import logging
import sys
import os
from queue import Queue
import serial
import csv ## Might remove this later


## TO DO
"""
    1. Implement Timeouts perfectly 
    2. Retries mechanism
    3. Shutting down the client connectin
    4. Logging of the error
    5. Authentication and Authorization Mechanism
    6. 



"""



logging.basicConfig(
    stream=sys.stdout, 
    level=logging.INFO, 
    format='%(asctime)s - %(message)s',
    datefmt='%H:%M:%S'
)


### Temperary code To simulate the data flow stream

def populate_csv():
    with open(TEMPPATH, 'w') as file:
        writer = csv.writer(file,lineterminator='\n')
        writer.writerow(['A', 'B', 'C', 'D', 'E'])
    for i in range(100):

        time.sleep(random.randint(2, 5))
        with open(TEMPPATH, 'a') as file:
            writer = csv.writer(file,lineterminator='\n')
            
            num = random.randint(1,10)
            for i in range(1, num):
                writer.writerow([random.randint(1,100) for j in range(5)])

            logging.info("Appended {} rows to the csv".format(num-1))







SAMAPLINGTIME = 100   #100ms
SAMAPLINGTIME = SAMAPLINGTIME/1000
FILEPATH = 'D:/Obfuscation/telemetor/Backend/rocket.csv'
TEMPPATH = 'D:/Obfuscation/telemetor/Backend/csv-temp/data.csv'


class SocketServer:
    def __init__(self, host="127.0.0.1", port=12345):
        self.host = host
        self.port = port
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.clients = [] ## maxing it to 2 to 3 for now 
    
    def start(self):
        self.server_socket.bind((self.host, self.port))
        self.server_socket.listen(2)
        logging.info(f"Server is listening on {self.host}:{self.port}")
        
        
        accept_thread = threading.Thread(target=self.accept_clients)
        accept_thread.start()

    


    def accept_clients(self):
        while True:
            if len(self.clients) >= 3:
                logging.info("Max clients reached")
                break
            client_socket, address = self.server_socket.accept()
            # client_socket.recv(1024)
            logging.info(f"Connection established with {address}")
            self.clients.append(client_socket)
            client_thread = threading.Thread(target=self.handle_client, args=(client_socket,))
            client_thread.start()





    def handle_client(self, client_socket):


        while True:
            try:
                ## Acknoledgment Sequence to be implemented 
                # 1. ACknoledgment of the connection
                # 2. Sharing of types and data
                # 3. Sending the Headers and types as a form of acknoledgment 

                
                
                
                client_socket.send("ACK".encode('utf-8'))
            except ConnectionResetError:
                break
        
        client_socket.close()
        self.clients.remove(client_socket)


    def get_data():
        data  = bufferQueue.get()

        pass

    def stop(self):
        for client in self.clients:
            client.close()
        self.server_socket.close()

## Will handle Serial Communitcatino in future
class DataHandler():
    
    def __init__(self, filePath=None,ser:serial.Serial=None,queue:Queue=None):
        assert filePath or ser, "Either file_path or serial port must be provided"
        assert not (filePath and ser), "Only one of file_path or serial port must be provided"
        
        # Serial Logic to be implmented
        #
        #
        ##



        self.file_path = filePath
        self.header = []
        self.data = []
        self.state=[]
        if queue is not None:
            self.data_queue = queue
        else: 
            self.data_queue = Queue()
        self.data_thread = threading.Thread(target=self.parser_csv)
        self.data_thread.start()




    def parser_csv(self):
        csv_obj = CsvToJson(self.file_path)
        csv_obj.readCsv(header=True,headerrows=2)

        try:
            self.header = csv_obj.header.headers # The entire header list from row 0 and row 2
            self.state = csv_obj.header.types # b'F' or b'S'


        except Exception as e:
            logging.error("There is some error in reading the header")

        try:
            while True:
                data = csv_obj.packet()
                if data !=[]:
                    self.data_queue.put(data)
                time.sleep(SAMAPLINGTIME)
        except Exception as e:
            logging.error("There is some error ")
            
        finally:
            self.process_complete()
            

        ## data logic to be implemented

    def process_complete(self):
        ## this method will be called when the rocket laucnch is completed or data stream is stoped 
        ## ideal time need to be decide
        logging.info("Data Stream Completed")
        pass


    

     ### We might only call bufferQueue.get() to get the data in the server thread
    # def get_data(self):
    #     return self.data_queue.get()



def handle_buffer(bufferQueue):
    while True:
        data = bufferQueue.get()
        
        # if data ==[]:
        #     logging.info("Data is None")
        # else:
        logging.info("DATA: {}".format(data))

if __name__ == "__main__":
    bufferQueue = Queue()
    t3 = threading.Thread(target=populate_csv, )
    t3.start()
    # server = SocketServer()
    # server.start()
    logging.info("Initiating Rocket Launch")
    rocket_laucnh = True
    
    if rocket_laucnh:
        dataHandler = DataHandler(filePath=TEMPPATH,queue=bufferQueue)


    ## sample thread for handling the buffer
    # temp = threading.Thread(target=handle_buffer, args=(bufferQueue,))
    # temp.start()
       
            


