#!/bin/bash

# Función para mostrar el menú.
function show_menu {
  # Muestra el encabezado del menú
  echo "============================"
  echo "  Menú de Escaneo de Puertos "
  echo "============================"
  # Opciones del menú
  echo "1) Introducir host"
  echo "2) Introducir rango de puertos (inicial y final)"
  echo "3) Iniciar escaneo"
  echo "4) Generar reporte recortado de escaneo"
  echo "5) Salir"
}

# Variables globales para almacenar la información del host y puertos.
host=""         # Variable para el host (IP o nombre de dominio)
firstport=""    # Variable para el puerto inicial
lastport=""     # Variable para el puerto final
output_file=""  # Variable para el archivo de salida

# Función para verificar si el host es válido.
function verify_host {
  # Verifica si el host es una dirección IP válida.
  if [[ "$host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # Intenta hacer ping al host para verificar conectividad.
    if ! ping -c 1 -W 1 "$host" > /dev/null 2>&1; then
      echo "Error: No se puede acceder al host (IP no responde)."
      host=""  # Limpia la variable si hay un error
    fi
  else
    # Si no es una IP, verifica como nombre de dominio.
    if ! ping -c 1 -W 1 "$host" > /dev/null 2>&1; then
      echo "Error: No se puede acceder al host (nombre de dominio no responde)."
      host=""  # Limpia la variable si hay un error
    fi
  fi
}

# Función para verificar que los puertos sean válidos.
function verify_ports {
  # Verifica si los puertos son números válidos.
  if ! [[ "$firstport" =~ ^[0-9]+$ ]] || ! [[ "$lastport" =~ ^[0-9]+$ ]]; then
    echo "Error: Los puertos deben ser números."
    firstport=""  # Limpia el puerto inicial si hay un error
    lastport=""   # Limpia el puerto final si hay un error
    return 1      # Devuelve 1 indicando error
  fi

  # Verifica que el puerto inicial no sea mayor que el final.
  if [ "$firstport" -gt "$lastport" ]; then
    echo "Error: El puerto inicial no puede ser mayor que el puerto final."
    firstport=""  # Limpia el puerto inicial si hay un error
    lastport=""   # Limpia el puerto final si hay un error
    return 1      # Devuelve 1 indicando error
  fi
  return 0  # Devuelve 0 indicando éxito
}

# Función para realizar el escaneo de puertos.
function port_scan {
  # Verifica que se haya ingresado un host.
  if [ -z "$host" ]; then
    echo "Error: No has introducido un host. Selecciona la opción 1 del menú."
    return  # Sale de la función
  fi
  # Verifica que se hayan ingresado los puertos.
  if [ -z "$firstport" ] || [ -z "$lastport" ]; then
    echo "Error: No has introducido los puertos. Selecciona la opción 2 del menú."
    return  # Sale de la función
  fi

  # Define el nombre del archivo de salida para los resultados.
  output_file="resultados_scan_$host.txt"
  echo "Escaneando puertos del $firstport al $lastport en $host..."
  # Escribe el encabezado en el archivo de salida.
  echo "Resultados del escaneo de $host:" > $output_file

  # Bucle para escanear cada puerto en el rango especificado.
  for ((counter=$firstport; counter<=$lastport; counter++)); do
    # Intenta conectarse al puerto y verifica si está abierto.
    (echo >/dev/tcp/$host/$counter) > /dev/null 2>&1 && echo "Puerto $counter abierto" | tee -a $output_file
  done

  echo "Escaneo finalizado. Resultados guardados en $output_file."
}

# Función para generar un reporte del escaneo.
function generate_report {
  # Verifica que haya resultados para generar el reporte.
  if [ -z "$output_file" ]; then
    echo "Error: No se ha realizado un escaneo aún o no hay resultados disponibles."
    return  # Sale de la función
  fi

  # Verifica si el archivo de resultados existe.
  if [ ! -f "$output_file" ]; then
    echo "Error: El archivo de resultados no existe. Realiza un escaneo primero."
    return  # Sale de la función
  fi

  echo "Generando reporte..."
  
  # Lee el archivo de resultados y cuenta los puertos abiertos.
  num_puertos_abiertos=$(grep -c "Puerto" "$output_file")

  # Crea un archivo de reporte con un resumen.
  echo "===============================" > reporte_$host.txt
  echo "Reporte de Escaneo de Puertos" >> reporte_$host.txt
  echo "Host: $host" >> reporte_$host.txt
  echo "Puertos escaneados: del $firstport al $lastport" >> reporte_$host.txt
  echo "Puertos abiertos: $num_puertos_abiertos" >> reporte_$host.txt
  echo "===============================" >> reporte_$host.txt

  echo "Reporte acortado generado: reporte_rec_$host.txt"
  cat reporte_$host.txt  # Muestra el contenido del reporte generado
}

# Bucle principal del menú.
while true; do
  show_menu  # Muestra el menú
  read -p "Elige una opción: " opcion  # Lee la opción seleccionada por el usuario
  case $opcion in
    1)
      # Opción para introducir el host.
      read -p "Introduce el host (IP o nombre de dominio): " host
      verify_host  # Verifica el host ingresado
      ;;
    2)
      # Opción para introducir el rango de puertos.
      read -p "Introduce el puerto inicial: " firstport
      read -p "Introduce el puerto final: " lastport
      verify_ports  # Verifica los puertos ingresados
      ;;
    3)
      # Opción para iniciar el escaneo de puertos.
      port_scan  # Ejecuta el escaneo de puertos
      ;;
    4)
      # Opción para generar un reporte del escaneo.
      generate_report  # Genera el reporte del escaneo
      ;;
    5)
      # Opción para salir del script.
      echo "Saliendo del script."
      break  # Sale del bucle y termina el script
      ;;
    *)
      # Manejo de opción no válida.
      echo "Opción no válida, elige entre 1 y 5."
      ;;
  esac
done
