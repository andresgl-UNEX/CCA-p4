import pandas as pd
import json

# Cargar los datos desde archivos JSON y etiquetarlos con el CCA
def load_data(file_path, cca_label):
    with open(file_path, 'r') as file:
        data = json.load(file)
        # Añadir la etiqueta CCA a cada muestra
        for sample in data:
            sample['CCA'] = cca_label
    return pd.DataFrame(data)

# Rutas de los archivos
file_paths = {
    "cubic": "./traffic/cubic.json",
    "reno": "./traffic/reno.json",
    "bbr": "./traffic/bbr.json",
    "htcp": "./traffic/htcp.json",
    "bic": "./traffic/bic.json"
}

# Cargar y combinar los datos
datasets = [load_data(file_path, cca_label) for cca_label, file_path in file_paths.items()]
full_dataset = pd.concat(datasets, ignore_index=True)

# Calcular el valor de `data_sent` como la diferencia entre registros consecutivos
full_dataset['data_sent'] = full_dataset['data_sent'].diff().fillna(full_dataset['data_sent'])

# Añadir la columna `sending_rate` y eliminar `sending_rate_time`
full_dataset['sending_rate'] = full_dataset['data_sent'] / full_dataset['sending_rate_time']

# Eliminar la primera fila de cada algoritmo
# Identificar los primeros índices para cada CCA
indices_to_remove = full_dataset.groupby("CCA").head(1).index
full_dataset = full_dataset.drop(indices_to_remove)

filtered_dataset = full_dataset[["q_delay", "q_depth", "sending_rate", "data_sent", "interarrival_time", "CCA"]]

# Guardar el DataFrame combinado filtrado
filtered_dataset.to_csv("cca_dataset.csv", index=False)