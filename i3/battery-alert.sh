#!/bin/bash

# Niveles de batería para notificar
CRITICAL_LEVELS=(20 15 10)

# Archivo temporal para rastrear notificaciones
TEMP_FILE="/tmp/battery_notified_level"

# Obtiene el porcentaje de la batería
BATTERY=$(cat /sys/class/power_supply/BAT0/capacity)
STATUS=$(cat /sys/class/power_supply/BAT0/status)

if [ "$STATUS" = "Discharging" ]; then
    for LEVEL in "${CRITICAL_LEVELS[@]}"; do
        if [ "$BATTERY" -le "$LEVEL" ]; then
            # Si no se ha notificado para este nivel
            if [ ! -f "${TEMP_FILE}_${LEVEL}" ]; then
                notify-send -u critical -t 10000 "Batería baja" "Queda $BATTERY% de batería"
                touch "${TEMP_FILE}_${LEVEL}" # Marca este nivel como notificado
            fi
        else
            # Limpia el archivo si la batería sube por encima del nivel
            [ -f "${TEMP_FILE}_${LEVEL}" ] && rm "${TEMP_FILE}_${LEVEL}"
        fi
    done
else
    # Si no está descargándose, elimina todas las marcas de notificación
    for LEVEL in "${CRITICAL_LEVELS[@]}"; do
        [ -f "${TEMP_FILE}_${LEVEL}" ] && rm "${TEMP_FILE}_${LEVEL}"
    done
fi

