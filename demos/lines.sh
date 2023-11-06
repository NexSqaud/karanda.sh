#!/bin/bash

. "$PWD/karanda.sh"

create_canvas 800 600 0xFFA0A0A0

draw_line 0 0 800 600 0xFF0000FF
draw_line 800 0 0 600 0xFF00FF00
draw_line 400 0 400 600 0xFFFF0000
draw_line 0 300 800 300 0xFFFF00FF
draw_line 100 0 700 600 0xFFFFFF00
draw_line 700 0 100 600 0xFF00FFFF

save_to_ppm "lines.ppm"