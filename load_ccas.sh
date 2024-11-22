#!/bin/bash

# Array con todos los módulos de algoritmos de control de congestión TCP
modules=(
  tcp_bbr
  tcp_bic
  tcp_cdg
  tcp_dctcp
  tcp_diag
  tcp_highspeed
  tcp_htcp
  tcp_hybla
  tcp_illinois
  tcp_lp
  tcp_nv
  tcp_scalable
  tcp_vegas
  tcp_veno
  tcp_westwood
  tcp_yeah
)

# Bucle para cargar cada módulo
for module in "${modules[@]}"; do
  if modprobe $module; then
    echo "Módulo $module cargado correctamente."
  else
    echo "No se pudo cargar el módulo $module o ya está cargado."
  fi
done

# Mostrar los algoritmos de control de congestión disponibles
echo "\nAlgoritmos de control de congestión TCP disponibles:"
sysctl net.ipv4.tcp_available_congestion_control