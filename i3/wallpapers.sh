#!/bin/bash

WALL_DIR="$HOME/Pictures/wallpaper/"

case "$1" in 
    1) feh --bg-scale "$WALL_DIR/wolverine-yessir.jpg" ;;
    2) feh --bg-scale "$WALL_DIR/yessirsupre-forest-girl.jpg" ;;
    3) feh --bg-scale "$WALL_DIR/yessirsupra-dark-red.jpg" ;;
    *) echo "no hay img kbron" ;;
esac

