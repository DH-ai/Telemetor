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
import signal
import json
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
    10. signaling for handling exiting process
    11. using thread-safe stop mechanism
    12. Perfectly creating the data stream as json objects



"""

## ISUEES
"""
    1. Is parsing function keep adding things to the queue if multiple clients are connected then one client will epmty the queue and other will not get the same data so there will be data inconsistency
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
    cnt=0
    for i in range(100):

        time.sleep(random.randint(2, 5))
        with open(TEMPPATH, 'a') as file:
            writer = csv.writer(file,lineterminator='\n')
            
            num = random.randint(1,10)
            for q in range(1, num):
                cnt+=1
                writer.writerow([cnt,*[random.randint(1,100) for j in range(4)]])
            # logging.info("Appended {} rows to the csv".format(num-1))







SAMAPLINGTIME = 100   #100ms
SAMAPLINGTIME = SAMAPLINGTIME/1000
FILEPATH = 'D:/Obfuscation/telemetor/Backend/rocket.csv'
TEMPPATH = 'D:/Obfuscation/telemetor/Backend/csv-temp/data.csv'
ROCKETLAUNCH = False
PORT = 12345
HOST = "127.0.0.1"

class SerialComm:
    def __init__(self, port:str, baudrate:int):
        self.port = port
        self.baudrate = baudrate
        self.ser = serial.Serial(port, baudrate)
        self.ser.flush()


class SocketServer:
    def __init__(self, host=HOST, port=PORT):
        self.host = host
        self.port = port
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.clients = [] ## maxing it to 2  for now 
        self.dataHandler:DataHandler = None
        self.connectionflag = False
        logging.info(f"ROCKETLAUNCH STATUS{ROCKETLAUNCH}")
        if ROCKETLAUNCH:
            self.dataHandler = DataHandler(filePath=TEMPPATH, queue=bufferQueue,headerrows=1)
    
    def start(self,timeout=None):
        self.server_socket.bind((self.host, self.port))
        self.server_socket.listen(2)
        self.server_socket.settimeout(timeout)
        # temp_thread_to_print_time = threading.Thread(target=self.print_time,)
        # temp_thread_to_print_time.start()
        logging.info(f"Server is listening on {self.host}:{self.port}")
        
        
        accept_thread = threading.Thread(target=self.accept_clients)
        accept_thread.start()
        # accept_thread.join()
        # temp_thread_to_print_time.join()

    ## will edit it or remove it later
    def print_time(self):
        t=1
        while True:
            
            logging.info("Time: {}".format(t))
            time.sleep(1)
            t+=1

    ## error manegment of this function
    ## need to implement the timeout mechanism  
    ## Reseting 
    ## a method as a security to check if clients are still connected or not
    def accept_clients(self):
        while True:
            if len(self.clients) >3:
                logging.info("Max clients reached")
                break
            try:
                client_socket, address = self.server_socket.accept()
                logging.info(f"Connection established with {address}")
                # logging.info(client_socket.recv(1024).decode("utf-8")) ## danger of blocking the thread 
                self.clients.append(client_socket)

                ## Implmenting some sort of mechanism to close the connection
                # try:
                        
                client_thread = threading.Thread(target=self.handle_client, args=(client_socket,address))
                client_thread.start()
            except RuntimeError as e:
                logging.error(f"Unable to start the thread due to {e}")
                logging.info("Closing the connection")
                client_socket.close()
                self.clients.remove(client_socket)
                continue
            





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

        logging.info("Handling the client")
        ACK_SUCCESS = False
        retries = 0 ## 5 retries
        try:
            client_socket.send("ACK-CONNECT".encode('utf-8'))
            # client_socket.timeout = 5
            # csvobj = CsvToJson(FILEPATH)

            while not ACK_SUCCESS:
                if retries > 10:
                    ACK_SUCCESS = False
                    logging.error("Max Retries reached")
                    logging.info("Closing the connection")
                    break
                data = client_socket.recv(1024).decode('utf-8')
                logging.info("client send {}".format(data))
                if data == "ACK-CONNECT":
                    
                    logging.info("Client Connected")
                    client_socket.send("ACK-EXCHANGE".encode('utf-8'))
                    data = client_socket.recv(1024).decode('utf-8')

                    logging.info("client send {}".format(data))
                    if data == "ACK-EXCHANGE":

                        headers = "HEADERS{}:TYPES{}".format(self.dataHandler.header, self.dataHandler.state)
                        client_socket.send(headers.encode('utf-8'))
                        data = client_socket.recv(1024).decode('utf-8')
                        logging.info("client send {}".format(data))


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
                    logging.error("Acknoledgment Failed client send d-{}".format(data)) 
                    logging.info("Retrying......")
                    ACK_SUCCESS = False

                retries += 1

        except Exception as e: ## not sure about error 
            logging.error(f"Unable to establish connection to the client {address} due to {e}") 

            # Logging the error
            #   

        finally:
            if not ACK_SUCCESS:
                client_socket.close()
                self.clients.remove(client_socket)
        


            
            

                    

                    

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

        ## if not recived the ack resend that witought updating anythng
        if not ROCKETLAUNCH:
            logging.error("Rocket Launch not started")
            return
        client_socket.settimeout(5)
        retries = 0
        while ROCKETLAUNCH and retries < 5: 
            try:
                data = bufferQueue.get() ## string bascially json data
                if data !="[]": 
                    #  try lock 
                    logging.info("Sending data to {}".format(client_socket.getpeername()))
                    client_socket.send(f"{data}::ACK({acknum})".encode('utf-8'))
                    print(data)
                    logging.info("Data Sent")
                    logging.info("Wating for the ACK")
                    try:
                        
                        temp = client_socket.recv(1024).decode('utf-8')
                        if temp == f"::ACK({acknum})":
                            logging.info("ACK Received")
                            acknum += 1
                        else:
                            logging.info("ACK not received")

                            ### sending data logic is also left as of now
                    except socket.timeout as e:
                        logging.error(f"Timeout Occured for client {client_socket.getpeername()}")
                        logging.info("Retrying......")
                        retries += 1
                        time.sleep(1)
                    except Exception as e:
                        logging.error("Some Error Occured in Acknoledgments due to {}".format(e))
                        logging.info("Retrying......")
                        retries += 1

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
    ## redifine the purpose of this function 
    def get_data():
        data  = bufferQueue.get()

        pass
    ## work on this function for proper exit sequence 
    def stop(self):
        for client in self.clients:
            client.close()
        self.server_socket.close()


## Will handle Serial Communitcatino in future
class DataHandler():
    
    def __init__(self, filePath=None,ser:serial.Serial=None,queue:Queue=None,headerrows:int=None):
        assert filePath or ser, "Either file_path or serial port must be provided"
        assert not (filePath and ser), "Only one of file_path or serial port must be provided"
        
        # Serial Logic to be implmented
        #
        #
        ##


        self.headerrows = headerrows
        self.file_path = filePath
        self.header = []
        self.data = []
        self.state=[]
        if queue is not None:
            self.data_queue = queue
        else: 
            self.data_queue = Queue()
        self.data_thread = threading.Thread(target=self.parser_csv,daemon=False)
        self.data_thread.start()



    ## retru mechanism might be needed here or maybe better error manegment
    def parser_csv(self):
        csv_obj = CsvToJson(self.file_path)
        csv_obj.readCsv(header=True,headerrows=self.headerrows)
 
        try:
            self.header = csv_obj.header.headers # The entire header list from row 0 and row 2
            self.state = csv_obj.header.types # b'F' or b'S'


        except Exception as e:
            logging.error("There is some error in reading the header parser_csv {}".format(e))

        try:
            while True:
                data = csv_obj.packet() ## json data 
                
                if data !="[]":
                    self.data_queue.put(json.loads(data))
                time.sleep(SAMAPLINGTIME)
        except Exception as e:
            logging.error("There is some error parser_csv {}".format(e))
            
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
    global ROCKETLAUNCH 
    ROCKETLAUNCH= True
    
    t3 = threading.Thread(target=populate_csv,daemon=False)

    t3.start()
    
    server = SocketServer()
    server.start()
    t3.join()
    
            

    


    ## sample thread for handling the buffer
    # temp = threading.Thread(target=handle_buffer, args=(bufferQueue,))
    # temp.start()






## after time out resart socket server







if __name__ == "__main__":
    bufferQueue = Queue()
    main(bufferQueue)
    
# 
    # print(("ds".encode('utf-8')))  
     
            


