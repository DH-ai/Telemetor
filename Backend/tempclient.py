import socket 
import time
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)




connected = False


while True:
    try:
        if not connected:
            sock.connect(('localhost', 12345))
            connected = True

        while connected:
            sock.send(b'Hello, world')
            # data = sock.recv(1024)

            # print(data.decode("utf-8"))
            time.sleep(1)
            print("dsahhdfgjhghjfdsghjdfsjghgjhsdfgjhsdfghj")
            

    except:
        print("Connection failed")
        print("Trying again")
        connection = False
        



print("Closing connection")