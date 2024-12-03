import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import confusion_matrix, classification_report

from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import GridSearchCV, train_test_split
from sklearn.metrics import accuracy_score
from sklearn.tree import plot_tree


def draw_confusion_matrix(conf_matrix):
    plt.figure(figsize=(10, 7))
    sns.heatmap(conf_matrix, annot=True, fmt="d", cmap="Blues", xticklabels=rf.classes_, yticklabels=rf.classes_)
    plt.xlabel("PREDICTED CCAs")
    plt.ylabel("REALISTICS CCAs")
    plt.title("CONFUSION MATRIX")
    plt.savefig("./figures/confusion_matrix.pdf", format="pdf", bbox_inches="tight")
    plt.show()


def tree_to_text(tree):
    output_file = "tree_structure.txt"
    with open(output_file, "w") as file:
        file.write(f"Número total de nodos: {tree.node_count}\n\n")

        # Nodo raíz
        root_feature = features[tree.feature[0]] if tree.feature[0] != -2 else "Hoja"
        root_threshold = tree.threshold[0]
        file.write(f"Nodo raíz (nodo 0):\n")
        file.write(f"  Característica usada: {root_feature}\n")
        file.write(f"  Umbral: {root_threshold:.6f} (menor o igual)\n\n")

        file.write("--- Información de los nodos ---\n\n")
        for node in range(tree.node_count):
            feature = features[tree.feature[node]] if tree.feature[node] != -2 else "Hoja"
            threshold = tree.threshold[node]
            condition = "menor o igual" if tree.feature[node] != -2 else "N/A"

            class_distribution = tree.value[node][0]  # Distribución de clases
            total_samples = sum(class_distribution)
            predicted_class_index = class_distribution.argmax()  # Índice de la clase predominante
            predicted_class = rf.classes_[predicted_class_index] if total_samples > 0 else "Ninguna"

            file.write(f"Nodo {node}:\n")
            file.write(f"  Característica usada: {feature}\n")
            file.write(f"  Umbral: {threshold:.6f} ({condition})\n")
            file.write(f"  Distribución de clases: {class_distribution.tolist()}\n")
            file.write(f"  Total de muestras: {int(total_samples)}\n")
            file.write(f"  Clase predicha: {predicted_class}\n\n")


def draw_features(importances, features):
    plt.figure(figsize=(8, 8))
    plt.pie(
        importances, 
        labels=features, 
        autopct='%1.1f%%',
        startangle=90,
        colors=plt.cm.tab20.colors
    )
    plt.title("IMPACT OF METRICS")
    plt.axis('equal')
    plt.savefig("./figures/impact_metrics.pdf", format="pdf", bbox_inches="tight")
    plt.show()


def draw_tree(rf):
    plt.figure(figsize=(20, 10))
    plot_tree(
        rf.estimators_[0], 
        feature_names=X.columns, 
        class_names=rf.classes_, 
        filled=True
    )
    plt.savefig("./figures/decision_tree.pdf", format="pdf", bbox_inches="tight")
    plt.close()


############################################################################################################
################################################### MAIN ###################################################
############################################################################################################

df = pd.read_csv("cca_dataset.csv")

X = df[["q_delay", "q_depth", "sending_rate", "data_sent", "interarrival_time"]]
y = df["CCA"]
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)


rf = RandomForestClassifier(max_depth=10, min_samples_split=5, random_state=42)
rf.fit(X_train, y_train)


# param_grid = {
#     'n_estimators': [100, 200, 300],
#     'max_depth': [None, 10, 20, 30],
#     'min_samples_split': [2, 5, 10],
#     'min_samples_leaf': [1, 2, 4],
#     'bootstrap': [True, False]
# }

# grid_search = GridSearchCV(estimator=rf, param_grid=param_grid, cv=3, scoring='accuracy', verbose=2)
# grid_search.fit(X_train, y_train)

# best_rf = grid_search.best_estimator_
# print(best_rf)


y_pred = rf.predict(X_test)
accuracy = accuracy_score(y_test, y_pred)


print(f"ACCURACY: {accuracy * 100:.2f}%")


conf_matrix = confusion_matrix(y_test, y_pred, labels=rf.classes_)
draw_confusion_matrix(conf_matrix)


# Informe detallado de clasificación
print("CLASIFICATION REPORT:")
print(classification_report(y_test, y_pred, target_names=rf.classes_))


# Gráfico para mostrar la importancia de cada métrica
importances = rf.feature_importances_
features = X.columns
draw_features(importances, features)


# Visualizar la estructura del árbol
# draw_tree(rf)


# Guardar la información del árbol en un archivo de texto
tree_to_text(rf.estimators_[0].tree_)