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
    6. Sendint the headers and types as a first step to setup the communication
    7. Setting up the Real Time data stream or atleast as soon as data is available
    8. Implementing the Serial Communication
    9. Thread for checking the status or logging importatn info 



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
ROCKETLAUNCH = False


class SerialComm:
    def __init__(self, port:str, baudrate:int):
        self.port = port
        self.baudrate = baudrate
        self.ser = serial.Serial(port, baudrate)
        self.ser.flush()


class SocketServer:
    def __init__(self, host="127.0.0.1", port=12345):
        self.host = host
        self.port = port
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.clients = [] ## maxing it to 2  for now 
        self.dataHandler:DataHandler = None
        if ROCKETLAUNCH:
            self.dataHandler = DataHandler(filePath=TEMPPATH, queue=bufferQueue)
    
    def start(self,timeout=8):
        self.server_socket.bind((self.host, self.port))
        self.server_socket.listen(2)
        self.server_socket.settimeout(timeout)
        logging.info(f"Server is listening on {self.host}:{self.port}")
        
        
        accept_thread = threading.Thread(target=self.accept_clients)
        accept_thread.start()

    


    def accept_clients(self):
        while True:
            if len(self.clients) >= 2:
                logging.info("Max clients reached")
                break
            client_socket, address = self.server_socket.accept()
            client_socket.recv(1024)
            logging.info(f"Connection established with {address}")
            self.clients.append(client_socket)

            ## Implmenting some sort of mechanism to close the connection
            client_thread = threading.Thread(target=self.handle_client, args=(client_socket,address))
            client_thread.start()





    def handle_client(self, client_socket:socket.socket,address):



        ## Acknoledgment Sequence to be implemented 
        # 1. ACknoledgment of the connection
        # 2. Sharing of types and data
        # 3. Sending the Headers and types as a form of acknoledgment 
        # 4. Resting mechanism, this might happen that maximum client are reached now the all client 
        # connecetions are closed and now need to call the accept_clients again but the question is we are on 
        # which thread and should we call it from the same thread or some mechanism to stop all threads or 
        # other threads running (if they are) and runn accept_cleiens again as if the socketServer Entierly 
        # restarted, might calling start works

        ## time out need to implment


        ACK_SUCCESS = False
        retries = 0 ## 5 retries
        try:
            client_socket.send("ACK-CONNECT".encode('utf-8'))
            client_socket.timeout = 5
            csvobj = CsvToJson(FILEPATH)

            while not ACK_SUCCESS:
                if retries > 4:
                    ACK_SUCCESS = False
                    logging.error("Max Retries reached")
                    logging.info("Closing the connection")
                    break
                data = client_socket.recv(1024).decode('utf-8')
                if data == "ACK-CONNECT":
                    
                    logging.info("Client Connected")
                    client_socket.send("ACK-EXCHANGE".encode('utf-8'))
                    data = client_socket.recv(1024).decode('utf-8')

                    if data == "ACK-EXCHANGE":
                        headers = "Headers{}:Types{}".format(self.dataHandler.header, self.dataHandler.state)
                        client_socket.send(headers.encode('utf-8'))
                        data = client_socket.recv(1024).decode('utf-8')

                        if data == "ACK-COMPLETE":
                            ACK_SUCCESS = True
                            logging.info("Connection Established")
                            logging.info("Starting data stream")
                            ## Starting the data stream
                            try:
                                if self.dataHandler is not None:
                                    self.sending_data(client_socket)
                            except Exception as e:
                                logging.error("Unable to Send Data due to {}\n".format(e))
                                ACK_SUCCESS = False
                            finally:
                                if self.dataHandler is  None:
                                    ACK_SUCCESS = False
                                    logging.info("Rocket Launch Not Started")
                                    logging.info(f"ROCKETLAUNCH{ROCKETLAUNCH}") ## Remove Later debuging purpose code line
                                    logging.info("Retrying......")
                                

                        else:
                            logging.error("Connection Failed Data Stream not started")
                            logging.info("Retrying......")
                            
                    else:
                        logging.error("Exchange Failed")
                        logging.info("Retrying......")
                        ACK_SUCCESS = False
                else:
                    logging.error("Connection Failed")
                    logging.info("Retrying......")
                    ACK_SUCCESS = False

                retries += 1

        except Exception as e: ## not sure about error 

            # Logging the error
            #   

            pass
        finally:
            if not ACK_SUCCESS:
                client_socket.close()
                self.clients.remove(client_socket)
        

        logging.error(f"Unable to establish connection to the client {address}") 

            
            

                    

                    

    def sending_data(self, client_socket:socket.socket):
        ## Sending the data to the client
        """
        1. Error handling
        2. Timeout handling
        3. Retries for below mentioned case
        4. local buffer to store the sent data to stop packet loss in case data is not  ## already a thing in tcp
        5. Acknowledgment of the data sent (need to see if not profucing overheads)
        5. Logging the data sent (probably or but somethign else type of logging)
        6. Implementing the real time data stream (SORT OF)
        7. Implementing the Serial Communication

        data sent
        data received
        waiting for the ack 
        ack received custom ack
        sending the ack back 
        if ack received pop the value from the tempBuffer
        send again the packet but packets are from the tempBuffer
        """

        # self.dataHandler.data_thread.start() ##3 this will start the thread which is start populating the queue
        acknum=0
        if not ROCKETLAUNCH:
            logging.error("Rocket Launch not started")
            return
        client_socket.settimeout(5)
        retries = 0
        while ROCKETLAUNCH and retries < 5: 
            try:
                logging.info("Sending data to {}".format(client_socket.getpeername()))
                data = bufferQueue.get() ## string bascially json data
                if data is not None: 
                    #  try lock 
                    client_socket.send(f"{data}::ACK({acknum})" .encode('utf-8'))
                    logging.info("Data Sent")
                    logging.info("Wating for the ACK")
                    try:
                        
                        temp = client_socket.receive(1024).decode('utf-8')
                        if temp == f"ACK({acknum})":
                            logging.info("ACK Received")
                            acknum += 1
                    except socket.timeout as e:
                        logging.error(f"Timeout Occured for client {client_socket.getpeername()}")
                        logging.info("Retrying......")
                        retires += 1
                        time.sleep(1)
                    except Exception as e:
                        logging.error("Some Error Occured")
                        logging.info("Retrying......")
                        retires += 1

                        time.sleep(1)
                        
            except socket.timeout as e:
                logging.error(f"Timeout Occured for client {client_socket.getpeername()}")
                logging.info("Retrying......")
                retires += 1

                time.sleep(1)
            except Exception as e:
                logging.error("Unable to send data due to {}".format(e)) ## need to change the error message
                logging.info("Retrying......")
                retires += 1

                time.sleep(1)

             
     
# 
    
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
                data = csv_obj.packet() ## json data 
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


def main(queue):
    
    t3 = threading.Thread(target=populate_csv)
    t3.start()
    # server = SocketServer()
    # server.start()
    logging.info("Initiating Rocket Launch")
    ROCKETLAUNCH = True

    
    

    ## sample thread for handling the buffer
    # temp = threading.Thread(target=handle_buffer, args=(bufferQueue,))
    # temp.start()













if __name__ == "__main__":
    bufferQueue = Queue()
    # main(bufferQueue)

    print(("ds".encode('utf-8')))  
     
            


