import socket
import threading
import csvtojson
import random
import time 
import logging
import sys
import os
from queue import Queue

class tempQueue(Queue):
    def __init__(self):
        super().__init__()
        self.__currentindex = 0
    @property
    def currentindex(self):
        return self.__currentindex




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

    def stop(self):
        for client in self.clients:
            client.close()
        self.server_socket.close()


if __name__ == "__main__":
    server = SocketServer()
    server.start()
