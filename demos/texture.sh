. $PWD/karanda.sh

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
			
			if [[ $inside -ne 0 ]];
			then
				local tx=$(((($u1*$tu1)+($u2*$tu2)+($u3*$tu3))/$det))
				local ty=$(((($u1*$tv1)+($u2*$tv2)+($u3*$tv3))/$det))
				
				draw_pixel $x $y ${texture[$(($ty*$texture_width+$tx))]}
			fi
		done
	done
}

echo "[Textures] Creating canvas..."

create_canvas 800 600 0xFFFFFFFF

declare -a texture_size
declare -a texture

texture_size=($( get_raw_image_size <"texture.raw" ))
texture=($( load_raw_image_from_stream <"texture.raw" ))

echo "[Textures] Loaded texture ${texture_size[0]} x ${texture_size[1]}"

texture_width=${texture_size[0]}
texture_height=${texture_size[1]}

#	1    2
#	x----x
#	|    |
#	|    |
#	x----x    
#	3    4

x1=100
y1=100

x2=700
y2=200

x3=200
y3=450

x4=550
y4=400

echo "[Textures] Drawing textured triangles..."

draw_textured_triangle $x1 $y1 $x2 $y2 $x3 $y3 0 0 $texture_width 0 0 $texture_height
draw_textured_triangle $x2 $y2 $x3 $y3 $x4 $y4 $texture_width 0 0 $texture_height $texture_width $texture_height

echo "[Textures] Saving to PPM..."

convert_to_ppm > "/dev/shm/texture.ppm"
mv /dev/shm/texture.ppm texture.ppm