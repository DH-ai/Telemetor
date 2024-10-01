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
    

    df = df1.dropna(subset=[' time', ' temperature', ' alt', ' bno_x', ' bno_y', ' bno_z']).loc[0:1000]



    df[' time'] = df[' time'].astype(float)
    df[' temperature'] = df[' temperature'].astype(float)
    df[' alt'] = df[' alt'].astype(float)
    df[' bno_x'] = df[ ' bno_x'].astype(float)
    df[' bno_y'] = df[ ' bno_y'].astype(float)
    df[' bno_z'] = df[ ' bno_z'].astype(float)
    df[' temperature'] = df[' temperature'].astype(float)
    df[' time'] = df[ ' time'] - df[' time'][0]
    fig, ax = plt.subplots(1,4, figsize=(15, 5))
    
    line0, = ax[0].plot(df[' time'], df[' bno_x'], lw=2) #bnox
    line1, = ax[1].plot(df[' time'], df[' bno_y'], lw=2) #bnox
    line2, = ax[2].plot(df[' time'], df[' bno_z'], lw=2) #bnox
    line3, = ax[3].plot(df[' time'], df[' alt'], lw=2) #bnox
    for i in range(3):
        ax[i].set_xlim(df[' time'].min(),df[' time'].max())
        ax[i].set_xlabel('Time')


    
    ax[0].set_ylim(df[' bno_x'].min(), df[' bno_x'].max())
    ax[1].set_ylim(df[' bno_y'].min(), df[' bno_y'].max())
    ax[2].set_ylim(df[' bno_z'].min(), df[' bno_z'].max())
    ax[3].set_ylim(df[' alt'].min(), df[' alt'].max())


    ax[0].set_title('X vs Time')
    ax[1].set_title('Y vs Time')
    ax[2].set_title('Z vs Time')
    ax[3].set_title('Altitude vs Time')


    ax[0].set_ylabel('Bno_X')
    ax[1].set_ylabel('Bno_Y')
    ax[2].set_ylabel('Bno_Z')
    ax[3].set_ylabel('Altitude')
 

    def init0():
        line0.set_data([], [])
        return line0,
    def init1():
        line1.set_data([], [])
        return line1,
    def init2():
        line2.set_data([], [])
        return line2,
    def init3():
        line3.set_data([], [])
        return line3,   

    def animate0(i):
        x = df[' time'][:i]
        y = df[' bno_x'][:i]
        
        line0.set_data(x, y)
        return line0,
    def animate1(i):
        x = df[' time'][:i]
        y = df[' bno_x'][:i]
        
        line1.set_data(x, y)
        return line1,
    def animate2(i):
        x = df[' time'][:i]
        y = df[' bno_x'][:i]
        
        line2.set_data(x, y)
        return line2,
    def animate3(i):    
        x = df[' time'][:i]
        y = df[' alt'][:i]
        
        line3.set_data(x, y)
        return line3,   


    ani0 = animation.FuncAnimation(fig, animate0, frames=len(df[' time']), init_func=init0, blit=True, interval=10)
    ani1 = animation.FuncAnimation(fig, animate1, frames=len(df[' time']), init_func=init1, blit=True, interval=10)
    ani2 = animation.FuncAnimation(fig, animate2, frames=len(df[' time']), init_func=init2, blit=True, interval=10)
    ani3 = animation.FuncAnimation(fig, animate3, frames=len(df[' time']), init_func=init3, blit=True, interval=10)
    plt.show()


