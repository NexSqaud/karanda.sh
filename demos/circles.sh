#!/bin/bash

. "$PWD/karanda.sh"

echo "[Circles] Creating canvas..."

create_canvas 800 600 0xFFFFFFFF

# count from 20 to 120
count=$(( ($RANDOM%100)+20 ))

echo "[Circles] Drawing $count circles..."

for (( i=0; i<$count; i++ ))
do
	x=$(($RANDOM%800))
	y=$(($RANDOM%600))
	radius=$(( ($RANDOM%50)+10 ))
	
	color=$(( ($RANDOM<<8) | ($RANDOM) ))
	
	draw_circle $x $y $radius $color
	
	if [[ $(($i%10)) -eq 0 ]];
	then
		echo "[Circles] $i/$count done..."
	fi
	
done

echo "[Circles] Saving to \"circles.ppm\"..."

convert_to_ppm > "/dev/shm/circles.ppm"
mv /dev/shm/circles.ppm circles.ppm