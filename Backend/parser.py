import csv
import pandas as pd
import time 
import socket
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import seaborn as sns


sns.set_theme(style="darkgrid",)
sns.set_context("notebook", font_scale=0.7, rc={"lines.linewidth": .5})
# sns.set_palette("husl")

def parse_csv(file_path):
    with open(file_path, 'r') as file:
        reader = csv.reader(file)
        data = list(reader)
    return data

file_path = 'D:/Obfuscation/telemetor/Backend/rocket.csv'

if __name__ == '__main__':
  
    _list = parse_csv(file_path)

    _bF = [row for row in _list if row[0] == "b'F'"]
    _bF = _bF[1:]
    # for i in range(2,100):
    #     print(float(_bF[i][1])-float(_bF[i-1][1]))

    
    
    _bS = [row for row in _list if row[0] == "b'S'"]
    _bS = _bS[1:]




    head1= ["b'F'", ' time', ' state', ' temperature', ' alt', ' ram_diff', ' bno_x', ' bno_y', ' bno_z', ' high_x', ' high_y', ' high_z', ' gyro_x', ' gyro_y', ' gyro_z', '', '', '', '']

    head2 = ["b'S'", 'lat(deg)', 'lat(min)', 'lat(sec)', 'lat(N/W)', 'lon(deg)', 'lon(min)', 'lon(sec)', 'lon(E/W)', 'v_horizontal', 'course', 'hdop', 'vdop', 'type', 'alt(ABL)', 'fix_time_since_start', 'time_since_fix', '', '']

    

    
    df = pd.DataFrame(_bF, columns=head1)
    df2 = pd.DataFrame(_bS, columns=head2)


    df[' time'] = df[' time'].astype(float)

        
    df[' temperature'] = df[' temperature'].astype(float)
    df[' alt'] = df[' alt'].astype(float)
    df[' bno_x'] = df[ ' bno_x'].astype(float)
    df[' bno_y'] = df[ ' bno_y'].astype(float)
    df[' bno_z'] = df[ ' bno_z'].astype(float)
    df[' gyro_x'] = df[ ' gyro_x'].astype(float)
    df[' gyro_y'] = df[ ' gyro_y'].astype(float)
    df[' gyro_z'] = df[ ' gyro_z'].astype(float)

    df[' time'] = df[ ' time'] - df[' time'][0]
    fig, ax = plt.subplots(2,1, figsize=(12, 8))
    
    line0, = ax[0].plot(df[' time'], df[' bno_x'], lw=2) #bnox
    line1, = ax[0].plot(df[' time'], df[' bno_y'], lw=2) #bnox
    line2, = ax[0].plot(df[' time'], df[' bno_z'], lw=2) #bnox
    ax[0].legend(['bno_x', 'bno_y', 'bno_z'])
    line0_a, = ax[1].plot(df[' time'], df[' gyro_x'], lw=2) #gyro_x
    line1_a, = ax[1].plot(df[' time'], df[' gyro_y'], lw=2) #gyro_y
    line2_a, = ax[1].plot(df[' time'], df[' gyro_z'], lw=2) #gyro_z
    ax[1].legend(['gyro_x', 'gyro_y', 'gyro_z'])

    # line3, = ax[3].plot(df[' time'], df[' alt'], lw=2) #bnox
    for i in range(2):
        ax[i].set_xlim(df[' time'].min(),df[' time'].max())
        ax[i].set_xlabel('Time')


    
    # ax[0].set_ylim(df[' bno_x'].min(), df[' bno_x'].max())
    # ax[0].set_ylim(df[' bno_y'].min(), df[' bno_y'].max())
    # ax[0].set_ylim(df[' bno_z'].min(), df[' bno_z'].max())
    # ax[3].set_ylim(df[' alt'].min(), df[' alt'].max())


    ax[0].set_title('bno vs Time')
    ax[1].set_title('Gyro vs Time')
    # ax[2].set_title('Z vs Time')
    # ax[3].set_title('Altitude vs Time')


    ax[0].set_ylabel('Bno')
    ax[1].set_ylabel('Gyro')
    # ax[2].set_ylabel('Bno_Z')
    # ax[3].set_ylabel('Altitude')

 

    def init0():
        line0.set_data([], [])
        line1.set_data([], [])
        line2.set_data([], [])

        return line0,line1,line2,
    def init0_a():
        line0_a.set_data([], [])
        line1_a.set_data([], [])
        line2_a.set_data([], [])

        return line0_a,line1_a,line2_a,

    def animate0(i):
        x = df[' time'][:i]
        y = df[' bno_x'][:i]
        y1 = df[' bno_y'][:i]
        y2 = df[' bno_z'][:i]
        line0.set_data(x, y)
        line1.set_data(x, y1)
        line2.set_data(x, y2)


        return line0,line1,line2,
    def animate0_a(i):
        x = df[' time'][:i]
        y = df[' gyro_x'][:i]
        y1 = df[' gyro_y'][:i]
        y2 = df[' gyro_z'][:i]
        line0_a.set_data(x, y)
        line1_a.set_data(x, y1)
        line2_a.set_data(x, y2)


        return line0_a,line1_a,line2_a,


    ani0 = animation.FuncAnimation(fig, animate0, frames=len(df[' time']), init_func=init0, blit=True, interval=10)
    ani0_a = animation.FuncAnimation(fig, animate0_a, frames=len(df[' time']), init_func=init0_a, blit=True, interval=10)

    plt.show()


    # plt.show()
