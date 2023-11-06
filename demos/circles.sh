#!/bin/bash

. "$PWD/karanda.sh"

create_canvas 800 600 0xFFFFFFFF

# count from 20 to 120
count=$(( ($RANDOM%100)+20 ))

for (( i=0; i<$count; i++ ))
do
	x=$(($RANDOM%800))
	y=$(($RANDOM%600))
	radius=$(( ($RANDOM%50)+10 ))
	
	color=$(( ($RANDOM<<8) | ($RANDOM) ))
	
	draw_circle $x $y $radius $color
done

save_to_ppm "circles.ppm"