#!/bin/bash

. "$PWD/karanda.sh"

echo "[Rectangles] Creating canvas..."

create_canvas 800 600 0xFFFFFFFF

rect_width=20
rect_height=20

count=$(((800/$rect_width)*(600/$rect_height)))

echo "[Rectangles] Drawing $count rectangles..."

for (( y=0; y<600; y+=$rect_height ))
do
	for (( x=0; x<800; x+=$rect_width ))
	do
		draw_rectangle $x $y $rect_width $rect_height $(( 0xFF000000 | $(( (($x*255)/800)<<8 )) | $(( (($y*255)/600) )) ))
	done
	echo "[Rectangles] $((($y/$rect_height+1)*800/$rect_width))/$count done..."
done

echo "[Rectangles] Saving to \"rectangles.ppm\"..."

save_to_ppm "rectangles.ppm"