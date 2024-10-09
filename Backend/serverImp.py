import socket
import socketserver
import threading
import time
import pandas as pd
import json


class ServerImpl(socket):
    def __init__(sub):
        super().__init__()
        sub.host = None


