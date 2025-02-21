#!/bin/bash

. $PWD/karanda.sh

# Note: all floats are multiplied by FIXED_MULTIPLIER and floored

FIXED_MULTIPLIER=10000

EPSILON=1

WIDTH=800
HEIGHT=600

# camera_near=10

perspective_project(){
	local x=$1
	local y=$2
	local z=$3
	
	local -n output_x=$4
	local -n output_y=$5
	
	if [[ $z -lt 0 ]];
	then
		$z=$((-$z))
	fi
	
	if [[ $z -lt $EPSILON ]];
	then
		$z=$(($z+$EPSILON))
	fi
	
	local projected_x_f=$((($x*$FIXED_MULTIPLIER)/$z))
	local projected_y_f=$((($y*$FIXED_MULTIPLIER)/$z))
	
	local screen_x_f=$(((($projected_x_f+$FIXED_MULTIPLIER)/2)*$WIDTH))
	local screen_y_f=$(((($projected_y_f+$FIXED_MULTIPLIER)/2)*$HEIGHT))
	
	local screen_x=$(($screen_x_f/$FIXED_MULTIPLIER))
	local screen_y=$(($screen_y_f/$FIXED_MULTIPLIER))
	
	echo "[3D] Projected coords: ($x, $y, $z) -> ($projected_x_f, $projected_y_f) -> ($screen_x_f, $screen_y_f) -> ($screen_x, $screen_y)"
	
	output_x=$screen_x
	output_y=$screen_y
}

draw_textured_triangle(){
	local x1=$1
	local y1=$2
	local x2=$3
	local y2=$4
	local x3=$5
	local y3=$6
	
	# Note: UV coordinates in range 0..texture_size
	
	local tu1=$7
	local tv1=$8
	local tu2=$9
	local tv2=${10}
	local tu3=${11}
	local tv3=${12}

	local minX=0
	local minY=0
	
	local maxX=0
	local maxY=0
	
	local insideCanvas=0
	
	clamp_triangle_on_canvas $x1 $y1 $x2 $y2 $x3 $y3 minX maxX minY maxY insideCanvas
	
	if [[ $insideCanvas -eq 0 ]];
	then
		return 0
	fi
	
	for (( y=$minY; y<=$maxY; y++ ))
	do
		for (( x=$minX; x<=$maxX; x++ ))
		do
			local u1=0
			local u2=0
			local det=0
			local inside=0
			
			barycentric $x1 $y1 $x2 $y2 $x3 $y3 $x $y u1 u2 det inside
			
			local u3=$(($det-$u1-$u2))
			
			if [[ $inside -ne 0 && $det -ne 0 ]];
			then
				local tx=$(((($u1*$tu1)+($u2*$tu2)+($u3*$tu3))/$det))
				local ty=$(((($u1*$tv1)+($u2*$tv2)+($u3*$tv3))/$det))
				
				draw_pixel $x $y ${texture[$(($ty*$texture_width+$tx))]}
			fi
		done
	done
}

echo "[3D] Creating canvas..."

create_canvas $WIDTH $HEIGHT 0xFFFFFFFF

declare -a texture_size
declare -a texture

echo "[3D] Loading texture..."

texture_size=($( get_raw_image_size <"texture.raw" ))

echo "[3D] Texture size: ${texture_size[0]} x ${texture_size[1]}"

texture=($( load_raw_image_with_od "texture.raw" ))

echo "[3D] Loaded texture"

texture_width=${texture_size[0]}
texture_height=${texture_size[1]}

# Limitations:
# 	x <- (-1.0;1.0)
# 	y <- (-1.0;1.0)
# 	z <- (1.0;2.0)

# 1 	2
# x-----x
# |     |
# |     |
# |     |
# x-----x
# 3 	4

x1=$((-1*$FIXED_MULTIPLIER))
y1=$((-1*$FIXED_MULTIPLIER))
z1=$((1*$FIXED_MULTIPLIER))

x2=$((1*$FIXED_MULTIPLIER))
y2=$((-1*$FIXED_MULTIPLIER))
z2=$((15*$FIXED_MULTIPLIER/10))

x3=$((-1*$FIXED_MULTIPLIER))
y3=$((1*$FIXED_MULTIPLIER))
z3=$((15*$FIXED_MULTIPLIER/10))

x4=$((1*$FIXED_MULTIPLIER))
y4=$((1*$FIXED_MULTIPLIER))
z4=$((2*$FIXED_MULTIPLIER))

screen_x1=0
screen_y1=0

screen_x2=0
screen_y2=0

screen_x3=0
screen_y3=0

screen_x4=0
screen_y4=0

echo "[3D] Projecting points..."

perspective_project $x1 $y1 $z1 screen_x1 screen_y1
perspective_project $x2 $y2 $z2 screen_x2 screen_y2
perspective_project $x3 $y3 $z3 screen_x3 screen_y3
perspective_project $x4 $y4 $z4 screen_x4 screen_y4

echo "[3D] Drawing quad..."

echo "[3D] Quad coords: ($screen_x1, $screen_y1), ($screen_x2, $screen_y2), ($screen_x3, $screen_y3), ($screen_x4, $screen_y4)"

draw_textured_triangle $screen_x1 $screen_y1 $screen_x2 $screen_y2 $screen_x3 $screen_y3 0 0 $texture_width 0 0 $texture_height
draw_textured_triangle $screen_x2 $screen_y2 $screen_x3 $screen_y3 $screen_x4 $screen_y4 $texture_width 0 0 $texture_height $texture_width $texture_height

echo "[3D] Saving to PPM..."

convert_to_ppm > "/dev/shm/3d.ppm"
mv /dev/shm/3d.ppm 3d.ppm