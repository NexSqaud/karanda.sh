#!/bin/bash

. "$PWD/karanda.sh"

POINTS_COUNT=12

echo "[Voronoi] Creating canvas..."

create_canvas 800 600 0xFFFFFFFF

echo "[Voronoi] Creating random points..."

declare -a voronoi_points

for (( i=0; i<$POINTS_COUNT; i++ ))
do
    voronoi_points[$(($i*3+0))]=$(($RANDOM%800))
    voronoi_points[$(($i*3+1))]=$(($RANDOM%600))
    voronoi_points[$(($i*3+2))]=$((($RANDOM<<8)|$RANDOM))
done

for (( i=0; i<$POINTS_COUNT; i++ ))
do
    echo "[Voronoi] point $(($i+1)) "
    echo "    position = ($((voronoi_points[$(($i*3+0))])), $((voronoi_points[$(($i*3+1))])))"
    printf "    color = 0x%08X\n" $((voronoi_points[$(($i*3+2))]))
done

echo "[Voronoi] Rendering diagram..."

for (( y=0; y<600; y++ ))
do
    for (( x=0; x<800; x++ ))
    do
        min_i=0
        min_distance=99999999999
        for (( i=0; i<$POINTS_COUNT; i++ ))
        do
            point_x=voronoi_points[$(($i*3+0))]
            point_y=voronoi_points[$(($i*3+1))]
            distance=$((($point_x-$x)*($point_x-$x)+($point_y-$y)*($point_y-$y)))

            if [[ $distance -lt $min_distance ]];
            then
                 min_distance=$distance
                 min_i=$i
            fi
        done

        draw_pixel $x $y $((voronoi_points[$(($min_i*3+2))]))
    done
done

echo "[Voronoi] Rendering point dots..."

for (( i=0; i<$POINTS_COUNT; i++ ))
do
	point_x=voronoi_points[$(($i*3+0))]
	point_y=voronoi_points[$(($i*3+1))]
    draw_circle $point_x $point_y 5 0xFF000000
done

echo "[Voronoi] Saving to PPM..."

convert_to_ppm > "/dev/shm/voronoi.ppm"
mv /dev/shm/voronoi.ppm voronoi.ppm
