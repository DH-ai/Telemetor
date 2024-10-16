import socket 
import time
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)




connected = False


while True:
    try:
        if not connected:
            sock.connect(('localhost', 12345))
            connected = True
            sock.send(b'Hello, world')
            break

            

    except:
        print("Connection failed")
        print("Trying again")
        connection = False
        
while True:
    try:
        data = sock.recv(1024)
        print(data.decode())
        time.sleep(1)
    except Exception as e: 

        
        print("Closing connection", e)
        break