import json
import re
import matplotlib.pyplot as plt
import numpy as np

def convert_iperf_to_json(input_file, output_file):
    results = []
    
    with open(input_file, 'r') as file:
        for line in file:
            if line.startswith('[ ID]'):
                continue
            
            match = re.match(r'^\[\s*\d+\]\s+(\d+\.\d+)-(\d+\.\d+)\s+sec\s+([\d\.]+)\s+MBytes\s+([\d\.]+)\s+Mbits/sec\s+(\d+)\s+(\d+\.?\d*)\s*(KBytes|MBytes)?', line)
            if match:
                interval_start = match.group(1)
                interval_end = match.group(2)
                transfer = match.group(3)
                bitrate = match.group(4)
                retransmits = match.group(5)
                cwnd = match.group(6)
                cwnd_unit = match.group(7) if match.group(7) else 'KBytes'
                
                data = {
                    "Interval Start": interval_start,
                    "Interval End": interval_end,
                    "Transfer (MBytes)": transfer,
                    "Bitrate (Mbits/sec)": bitrate,
                    "Retransmits": retransmits,
                    "Cwnd": f"{cwnd} {cwnd_unit}"
                }
                
                results.append(data)
    
    with open(output_file, 'w') as json_file:
        json.dump(results, json_file, indent=4)

def read_rtt_report(input_file):
    rtt_data = []
    
    with open(input_file, 'r') as file:
        for line in file:
            print(f"Processing line: {line.strip()}")
            match = re.match(r'- RTT value: (\d+) us\.', line)
            if match:
                rtt_value = int(match.group(1))
                rtt_data.append(rtt_value)
                print(f"Extracted RTT: {rtt_value}")

    return rtt_data

def convert_cwnd_to_kbytes(cwnd):
    if 'MBytes' in cwnd:
        return float(cwnd.replace('MBytes', '').strip()) * 1024
    elif 'KBytes' in cwnd:
        return float(cwnd.replace('KBytes', '').strip())
    else:
        return float(cwnd)

def plot_graphs(rtt_values, cwnd_values):
    plt.figure(figsize=(12, 6))

    plt.subplot(2, 1, 1)
    plt.plot(rtt_values, label='RTT (ms)', color='blue')
    plt.title('RTT Over Time')
    plt.xlabel('Sample')
    plt.ylabel('RTT (ms)')
    plt.grid()
    plt.legend()

    plt.subplot(2, 1, 2)
    plt.plot(cwnd_values, label='Cwnd (KBytes)', color='red')
    plt.title('Cwnd Over Time')
    plt.xlabel('Sample')
    plt.ylabel('Cwnd (KBytes)')
    plt.grid()
    plt.legend()
    
    yticks = np.linspace(min(cwnd_values), max(cwnd_values), 6)
    plt.yticks(yticks)

    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    iperf_json_file = 'output_iperf.json'
    iperf_input_file = 'output_iperf.txt'
    rtt_input_file = 'packet_report.txt'

    convert_iperf_to_json(iperf_input_file, iperf_json_file)

    rtt_values = read_rtt_report(rtt_input_file)
    print(f"RTT Values: {rtt_values}")
    
    with open(iperf_json_file, 'r') as json_file:
        iperf_data = json.load(json_file)
        cwnd_values = [convert_cwnd_to_kbytes(data["Cwnd"]) for data in iperf_data]  # Convertir a KBytes

    plot_graphs(rtt_values, cwnd_values)
