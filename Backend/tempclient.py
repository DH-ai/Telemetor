import socket 
import time
import threading
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)




connected = False

def handleConnection(sock:socket.socket):
    while True:
        try:
            print("Trying to connect to server")
            data = sock.recv(1024)
            print(data.decode("utf-8"))
            if data.decode("utf-8") == "ACK-CONNECT":
                print("Connected to server")
                sock.send('ACK-CONNECT'.encode("utf-8"))
                data = sock.recv(1024).decode("utf-8")
                if data == "ACK-EXCHANGE":
                    sock.send('ACK-EXCHANGE'.encode("utf-8"))
                    print("headers")
                    data = sock.recv(1024)
                    print(data)
                    print("="*10)
                    print(data.decode("utf-8"))
                    sock.send("ACK-COMPLETE".encode("utf-8"))
                    while True:
                        data = sock.recv(1024)
                        print(data.decode("utf-8"))
                        i=0
                        data = data.decode("utf-8")
                        for i in range(len(data)):
                            if data[i] == ":" and data[i+1] == ":":
                                    sock.send(data[i:].encode("utf-8"))              




            time.sleep(1)
        except Exception as e: 
            print("Unable to get the data due to ", e)
            print("Retrying")
            time.sleep(1)



while True:
    try:
        if not connected:
            sock.connect(('localhost', 12345))
            connected = True

            t1 = threading.Thread(target=handleConnection, args=(sock,))
            t1.start()
            break

            

    except:
        print("Connection failed")
        print("Trying again")
        time.sleep(1)
        connection = False
        



