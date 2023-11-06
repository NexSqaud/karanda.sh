#!/bin/bash

. "$PWD/karanda.sh"

create_canvas 800 600 0xFFFFFFFF

rect_width=20
rect_height=20

for (( y=0; y<600; y+=$rect_height ))
do
	for (( x=0; x<800; x+=$rect_height ))
	do
		draw_rectangle $x $y $rect_width $rect_height $(( 0xFF000000 | $(( (($x*255)/800)<<8 )) | $(( (($y*255)/600) )) ))
	done
done

save_to_ppm "rectangles.ppm"