import csv

def parse_csv(file_path):
    with open(file_path, 'r') as file:
        reader = csv.reader(file)
        data = list(reader)
    return data

file_path = 'D:\Obfuscation/telemetor/Backend/rocket.csv'

if __name__ == '__main__':
  
    _list = parse_csv(file_path)
    print(len(_list[0]),len( _list[1]),len( _list[2]))
    j=1
    for i in _list[0]:
       print((i),j)
       j=j+1
    for i in _list[1]:
       print((i))


