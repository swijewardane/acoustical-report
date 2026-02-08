import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os
import glob

def get_rt60_files(directory = '.', pattern = 'RT60*.txt'):
    file_list = glob.glob(os.path.join(directory, pattern))
    file_list.sort()
    return file_list

def read_new_rt_60(filename):

    with open(filename, 'r') as f:
        lines = f.readlines()
        data_start = 0
        for i, line in enumerate(lines):
            if line.startswith('Format is'):
                data_start = i + 2
                break
    df = pd.read_csv(filename, skiprows=data_start, header=None)

    column_names = ['Freq_Hz', 'BW', 'EDT_s', 'EDT_r', 'T20_s', 'T20_r', 
                    'T30_s', 'T30_r', 'Topt_s', 'Topt_r', 'ToptStart_dB', 
                    'ToptEnd_dB', 'T60M_s', 'Filter', 'C50_dB', 'C80_dB', 
                    'C20_dB', 'D50_pct', 'TS_s']
    df.columns = column_names
    return df

def average_rt60_files(file_list):

    dfs = []

    for file in file_list:
        df = read_new_rt_60(file)
        dfs.append(df)

    avg_df = dfs[0].copy()

    params_to_avg = ['EDT_s', 'T20_s', 'T30_s', 'Topt_s', 'C50_dB', 'C80_dB', 'C20_dB', 'D50_pct', 'TS_s']

    for param in params_to_avg:
        values = np.array([df[param].values for df in dfs])
        avg_df[param] = np.mean(values, axis=0)

    return avg_df

def plot_rt60(df, title='Averaged RT60 Measurements'):
    """
    Plot RT60 data
    """
    fig, ax = plt.subplots(figsize=(10, 6))
    ax.plot(df['Freq_Hz'][:-1], df['T30_s'][:-1], 'o-', label='T30')
    ax.plot(df['Freq_Hz'][:-1], df['T20_s'][:-1], 's-', label='T20')
    ax.plot(df['Freq_Hz'][:-1], df['EDT_s'][:-1], 'x-', label= 'EDT')

    ax.set_xlabel('Frequency (Hz)')
    ax.set_ylabel('Reverberation Time (s)')
    ax.set_title(title)

    # ax.set_xlim(40, 12000)
    freq_ticks = [50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 
                  630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 
                  5000, 6300, 8000, 10000]
    
    # ax.set_xticks(freq_ticks) 
    ax.set_xticklabels([str(f) for f in freq_ticks], rotation = 45, ha = 'center')


    ax.grid(True, which='both', alpha=0.3)
    # plt.grid(True, which='major', alpha=0.6, linewidth = 0.8)
    ax.legend()
    plt.tight_layout()
    plt.show()

def main():
    # List of RT60 files to average
    file_list = get_rt60_files(directory= r'.\rt60_measurement_exports')

    if not file_list:
        print('No RT60 measurement files found!')
    
    print(f'Found {len(file_list)} RT60 files')

    # Read and average
    avg_rt60 = average_rt60_files(file_list)
    
    # Display results
    print("\nAveraged RT60 Data:")
    print(avg_rt60[['Freq_Hz', 'EDT_s', 'T20_s', 'T30_s']])
    
    # Plot the results
    plot_rt60(avg_rt60)
    
    # Save averaged data
    avg_rt60.to_csv('RT60_averaged.csv', index=False)
    print("\nAveraged data saved to RT60_averaged.csv")

if __name__ == "__main__":
    main()