import csv
import pandas as pd
import time 
import socket
import matplotlib.pyplot as plt
import matplotlib.animation as animation

def parse_csv(file_path):
    with open(file_path, 'r') as file:
        reader = csv.reader(file)
        data = list(reader)
    return data

file_path = 'D:\Obfuscation/telemetor/Backend/rocket.csv'

if __name__ == '__main__':
  
    _list = parse_csv(file_path)
    _bF = [row for row in _list if row[0] == "b'F'"]
    _bS = [row for row in _list if row[0] == "b'S'"]

    head1= ["b'F'", ' time', ' state', ' temperature', ' alt', ' ram_diff', ' bno_x', ' bno_y', ' bno_z', ' high_x', ' high_y', ' high_z', ' gyro_x', ' gyro_y', ' gyro_z', '', '', '', '']

    head2 = ["b'S'", 'lat(deg)', 'lat(min)', 'lat(sec)', 'lat(N/W)', 'lon(deg)', 'lon(min)', 'lon(sec)', 'lon(E/W)', 'v_horizontal', 'course', 'hdop', 'vdop', 'type', 'alt(ABL)', 'fix_time_since_start', 'time_since_fix', '', '']
    df1 = pd.DataFrame(_bF)
    df1.columns = head1

    df2 = pd.DataFrame(_bS)
    df2.columns = head2
    

    df = df1.dropna(subset=[' time', ' temperature']).loc[0:1000]
    df[' time'] = df[' time'].astype(float)
    df[' temperature'] = df[' temperature'].astype(float)
    df[' time'] = df[ ' time'] - df[' time'][0]
    fig, ax = plt.subplots()
    
    line, = ax.plot(df[' time'], df[' temperature'], lw=2)
    ax.set_xlim(df[' time'].min(), df[' time'].max())
    ax.set_ylim(df[' temperature'].min(), df[' temperature'].max())
    ax.set_title('Altitude vs Time')
    ax.set_xlabel('Time')
    ax.set_ylabel('Altitude')
 

    def init():
        line.set_data([], [])
        return line,

    def animate(i):
        x = df[' time'][:i]
        y = df[' temperature'][:i]
        line.set_data(x, y)
        return line,


    ani = animation.FuncAnimation(fig, animate, frames=len(df[' time']), init_func=init, blit=True, interval=10)
    ani2 = animation.FuncAnimation(fig, animate, frames=len(df[' time']), init_func=init, blit=True, interval=10)
    plt.show()


