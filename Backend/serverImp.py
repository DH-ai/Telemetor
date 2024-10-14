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



### Temperary code To simulate the data flow stream

def populate_csv():
    with open('D:/Obfuscation/telemetor/Backend/csv-temp/data.csv', 'w') as file:
        writer = csv.writer(file,lineterminator='\n')
        writer.writerow(['A', 'B', 'C', 'D', 'E'])
    for i in range(100):

        time.sleep(random.randint(2, 5))
        with open(TEMPPATH, 'a') as file:
            writer = csv.writer(file,lineterminator='\n')
            
            num = random.randint(1,10)
            for i in range(1, num):
                writer.writerow([random.randint(1,100) for j in range(5)])

            print(f"{time.thread_time()} Appended ",num-1," rows to the csv")







SAMAPLINGTIME = 100   #100ms
SAMAPLINGTIME = SAMAPLINGTIME/1000
FILEPATH = 'D:/Obfuscation/telemetor/Backend/rocket.csv'
TEMPPATH = 'D:/Obfuscation/telemetor/Backend/csv-temp/data.csv'


class SocketServer:
    def __init__(self, host="127.0.0.1", port=12345):
        self.host = host
        self.port = port
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.clients = []
    
    def start(self):
        self.server_socket.bind((self.host, self.port))
        self.server_socket.listen(2)
        print(f"Server is listening on {self.host}:{self.port}")
        
        
        accept_thread = threading.Thread(target=self.accept_clients)
        accept_thread.start()

    


    def accept_clients(self):
        while True:
            client_socket, address = self.server_socket.accept()
            # client_socket.recv(1024)
            print(f"Connection established with {address}")
            self.clients.append(client_socket)
            
            
            client_thread = threading.Thread(target=self.handle_client, args=(client_socket,))
            client_thread.start()





    def handle_client(self, client_socket):
        while True:
            try:
                data = client_socket.recv(1024)
                if not data:
                    break
                print(f"Received: {data.decode('utf-8')}")
                
                
                client_socket.send("ACK".encode('utf-8'))
            except ConnectionResetError:
                break
        
        client_socket.close()
        self.clients.remove(client_socket)


    def get_data():


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
        self.header = csv_obj.header.headers # The entire header list from row 0 and row 2
        self.state = csv_obj.header.types # b'F' or b'S'
        ## data logic to be implemented

    def process_complete(self):
        ## this method will be called when the rocket laucnch is completed or data stream is stoped 
        ## ideal time need to be decide
        pass


    

     ### We might only call bufferQueue.get() to get the data in the server thread
    # def get_data(self):
    #     return self.data_queue.get()

if __name__ == "__main__":
    # server = SocketServer()
    # server.start()
    bufferQueue = Queue()

    rocket_laucnh = True
    logging.info("Initiating Rocket Launch")
    logging.info
    
    if rocket_laucnh:
        dataHandler = DataHandler(filePath=FILEPATH,queue=bufferQueue)

    logging.basicConfig(
        stream=sys.stdout, 
        level=logging.INFO, 
        format='%(asctime)s - %(message)s',
        datefmt='%H:%M:%S'
    )
    # t3 = threading.Thread(target=populate_csv, )
    # t3.start()

