#!/bin/bash

# Verificar que si se escriba el parametro indicado
if [ $# -lt 1 ]; then
    echo "Please write: $0 <path>"
    exit 1
fi

# Parámetro de entrada
DIRECTORY=$1 #Variable que almacena la ruta que se va a escanear
REPORT="ReportPerm.txt"   #Nombre del archivo que se va a generar

# Función para revisar los permisos de todos los archivos y listarlos en el reporte
list_files_per() {
    echo "Listando permisos de todos los archivos en el directorio: $DIRECTORY"
    
    # Comprobar si el directorio existe y si no existe te lo dira 
    if [ ! -d "$DIRECTORY" ]; then
        echo "Error: El directorio $DIRECTORY no existe."
        return 1
    fi

    # Listar todos los archivos con sus permisos y guardarlos en el reporte
    find "$DIRECTORY" -type f -exec ls -l {} \; > "$REPORT" 2>/dev/null

    # Verificar si el comando funciono 
    if [ $? -eq 0 ]; then
        echo "Reporte generado: $REPORT"
    else
        echo "Error al generar el reporte."
        return 1
    fi
}

# Función para revisar permisos inseguros (archivos con permisos 777)
check_insfiles() {
    echo "Revisando permisos inseguros en el directorio: $DIRECTORY"
    
    if [ ! -d "$DIRECTORY" ]; then
        echo "Error: El directorio $DIRECTORY no existe."
        #Le asignamos como nueva ruta la actual 
        DIRECTORY=$(pwd)
        echo "Ruta cambiada a $DIRECTORY" 
        return 1
    fi

    # Buscar archivos con permisos 777
    archivos_inseguros=$(find "$DIRECTORY" -type f -perm 777 2>/dev/null)
    # Si se encontraron archivos inseguros los mostrara y si no mostrara que no hay 
    if [ -z "$archivos_inseguros" ]; then
        echo "No se encontraron archivos con permisos inseguros en $DIRECTORY."
    else
        echo "Archivos con permisos inseguros:"
        echo "$archivos_inseguros"
        return 0
    fi
}

change_perm() {
#Aqui cambiaremos los archivos inseguros a permisos de lectura y escritura, mientras que los demás tienen solo permisos de lectura
    echo "Cambiando permisos de los siguientes archivos a 644:"
    for archivo in $archivos_inseguros; do
        chmod 644 "$archivo"
        echo "Permisos cambiados para: $archivo"
    done
}

# Función para mostrar el menu con sus funciones
show_menu() {
    echo ""
    echo "Menu de funcionalidades:"
    echo ""
    echo "1) Revisar permisos inseguros"
    echo "2) Listar todos los archivos y sus permisos en el reporte"
    echo "3) Ejecutar de nuevo con una nueva carpeta"
    echo "4) Cambiar los permisos a los archivos inseguros"
    echo "5) Salir"
    echo ""
}

# Ciclo paraMostrar menú y realizar acciones
while true; do
    echo ""
    show_menu
    read -p "Elija una opción: " opcion
    echo ""
    case $opcion in
        1)
            check_insfiles # Se ejecuta la funcion que revisa si hay archivos inseguros 
            ;;
        2)
            list_files_per # Se ejecuta la funcion que crea el reporte de todos los archivos  
            ;;
        3)
            read -p "Ingrese la nueva ruta de carpeta: " new_directory
            DIRECTORY=$new_directory
            check_insfiles # Se ejecuta la funcion que revisa si hay archivos inseguros pero con la nueva ruta
            ;;
        4)
            if [ -z "$archivos_inseguros" ]; then
                echo "No hay archivos inseguros para cambiar permisos."
            else
                change_perm # Cambiamos los perimsos de los archivos inseguros para que no lo sean 
            fi
            ;; 
        5)
            echo "Saliendo..."
            exit 0 # Salimos del programa
            ;;
        *)
            echo "Opción inválida. Intente de nuevo."
            ;; #En caso de ingresar un numero no valido se volvera a mostrar el menu
    esac
done
