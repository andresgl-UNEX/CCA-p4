import os
import json
import numpy as np
import matplotlib.pyplot as plt


def draw_figure(timestamps, metric, series_data_q_delay):
    plt.figure(figsize=(12, 3))
    for filename, data in series_data_q_delay.items():
        cca = filename.split(".")[0]
        plt.plot(timestamps, data, label=f"{cca}")

    plt.title(f"{metric} vs TIMESTAMPS", fontsize=16)
    plt.xlabel("TIMESTAMPS (s)", fontsize=14)
    plt.xticks(np.arange(0, 181, 10))
    plt.ylabel(metric, fontsize=14)
    plt.xlim(0, 180)
    plt.ylim(0)
    plt.legend(title="CCAs")
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(f"{metric}_graph.png")
    plt.show()


def calculate_differences(values):
    """Calcula la diferencia entre valores consecutivos en la lista."""
    return [values[i] - values[i - 1] for i in range(1, len(values))]


def aggregate_data(packets, metric_key, num_seconds, packets_per_second):
    aggregated_data = []
    for second in range(num_seconds + 1):
        start_idx = second * packets_per_second
        end_idx = (second + 1) * packets_per_second
        values = [packets[i][metric_key] for i in range(start_idx, min(end_idx, len(packets)))]
        # Calcula diferencias si es necesario
        if metric_key == "data_sent" and len(values) > 1:
            values = calculate_differences(values)
        if values:
            aggregated_data.append(np.mean(values))
        else:
            aggregated_data.append(0)
    return aggregated_data


def main():
    directory = "/home/admin/P4_Labs/prueba/traffic"
    series_data_q_delay = {}
    series_data_q_depth = {}
    series_data_sending_rate_time = {}
    series_data_data_sent = {}
    series_data_sending_rate = {}
    series_data_interarrival_time = {}

    duration = 180
    filenames = ["reno.json", "cubic.json", "bbr.json", "htcp.json", "bic.json"]

    for filename in filenames:
        filepath = os.path.join(directory, filename)
        if os.path.exists(filepath):
            with open(filepath, "r") as f:
                packets = json.load(f)
                packets.pop(0)

            packets_per_second = len(packets) // duration
            data_q_delay = aggregate_data(packets, "q_delay", duration, packets_per_second)
            data_q_depth = aggregate_data(packets, "q_depth", duration, packets_per_second)
            data_sending_rate_time = aggregate_data(packets, "sending_rate_time", duration, packets_per_second)
            data_data_sent = aggregate_data(packets, "data_sent", duration, packets_per_second)
            data_interarrival_time = aggregate_data(packets, "interarrival_time", duration, packets_per_second)

            series_data_q_delay[filename] = data_q_delay
            series_data_q_depth[filename] = data_q_depth
            series_data_sending_rate_time[filename] = data_sending_rate_time
            series_data_data_sent[filename] = data_data_sent
            series_data_sending_rate[filename] = [
                data_sent / sending_rate_time if sending_rate_time != 0 else 0
                for data_sent, sending_rate_time in zip(data_data_sent, data_sending_rate_time)
            ]
            series_data_interarrival_time[filename] = data_interarrival_time
        else:
            print(f"El archivo {filename} no existe en el directorio {directory}")

    timestamps = np.arange(0, duration + 1)
    draw_figure(timestamps, "QUEUE DELAY", series_data_q_delay)
    draw_figure(timestamps, "QUEUE DEPTH", series_data_q_depth)
    draw_figure(timestamps, "SENDING RATE", series_data_sending_rate)
    draw_figure(timestamps, "DATA SENT", series_data_data_sent)
    draw_figure(timestamps, "INTERARRIVAL TIME", series_data_interarrival_time)

if __name__ == '__main__':
    main()