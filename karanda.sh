#!/bin/bash

# Typedefs:
# Color = int   (0xAABBGGRR)
# bool = int	(0/1)

# File formats:
# 	RAW:
# 		uint32_t width
# 		uint32_t height
# 		Color[] imageData


KARANDASH_WIDTH=0
KARANDASH_HEIGHT=0
declare -a KARANDASH_CANVAS

# Arguments:
# 	int width
# 	int height
# 	Color fillColor (optional)
# Output: 0 on success; 1 on error
create_canvas() {
	local width=$1
	local height=$2
	local fillColor=0xFFFFFFFF
	
	if [[ $# -ge 3 ]];
	then
		fillColor=$3
	fi
	
	if [[ width -lt 0 || height -lt 0 ]];
	then
		return 1
	fi

	KARANDASH_WIDTH=$width
	KARANDASH_HEIGHT=$height
	
	for (( i=0; i<$(($width*$height-1)); i++))
	do
		KARANDASH_CANVAS[$i]=$fillColor
	done
}

# Arguments:
# 	int x
# 	int y
# Output: 0 if point inside the canvas; otherwise 1
is_point_in_canvas() {
	local x=$1
	local y=$2
	
	if [[ x -lt 0 || y -lt 0 || x -ge KARANDASH_WIDTH || y -ge KARANDASH_HEIGHT ]]; 
	then
		return 1
	fi
	
	return 0
}

# Arguments:
# 	int x
# 	int y
# 	Color color
# Output: 0 on success; 1 on error
draw_pixel() {
	local x=$1
	local y=$2
	local color=$3
	
	if [[ $x -lt 0 || $y -lt 0 || $x -ge KARANDASH_WIDTH || $y -ge KARANDASH_HEIGHT ]];
	then
		return 0
	fi
	
	KARANDASH_CANVAS[$(($y*KARANDASH_WIDTH+$y))]=color
}

# Arguments:
# 	int x
# 	int y
# 	int width
# 	int height
# 	Color fillColor
# Output: 0 on success; 1 on error
draw_rectangle() {
	local x=$1
	local y=$2
	local width=$3
	local height=$4
	local fillColor=$5
	
	is_point_in_canvas $x $y
	if [[ $? -ne 0 ]];
	then
		return 1
	fi
	
	if [[ $x -lt 0 ]];
	then
		width=$(($width+$x))
		x=0
	fi
	
	if [[ $y -lt 0 ]];
	then
		height=$(($height+$y))
		y=0
	fi
	
	if [[ $(($width+x)) -ge KARANDASH_WIDTH ]];
	then
		width=$((KARANDASH_WIDTH-x-1))
	fi
	
	if [[ $(($height+y)) -ge KARANDASH_HEIGHT ]];
	then
		height=$((KARANDASH_HEIGHT-y-1))
	fi
	
	for (( dy=0; dy<height; dy++ ))
	do
		for (( dx=0; dx<width; dx++ ))
		do
			KARANDASH_CANVAS[$((($y+$dy)*KARANDASH_WIDTH+($x+$dx)))]=$fillColor
		done
	done
}

# Arguments:
# 	int centerX
# 	int centerY
# 	int radius
# 	Color fillColor
# Output: 0 on success; 1 on error
draw_circle() {
	local centerX=$1
	local centerY=$2
	local radius=$3
	local fillColor=$4
	
	if [[ $(($centerX+$radius)) -lt 0 || $(($centerY+$radius)) -lt 0 || $(($centerX-$radius)) -ge KARANDASH_WIDTH || $(($centerY-$radius)) -ge KARANDASH_HEIGHT ]];
	then
		return 0
	fi
	
	for (( dy=$((0-$radius)); dy<$radius; dy++ ))
	do
		for (( dx=$((0-$radius)); dx<$radius; dx++ ))
		do
			if [[ $(($centerX+$dx)) -lt 0 || $(($centerX+$dx)) -ge KARANDASH_WIDTH || $(($centerY+$dy)) -lt 0 || $(($centerY+$dy)) -ge KARANDASH_HEIGHT ]];
			then
				continue
			fi
			
			if [[ $(($dx*$dx+$dy*$dy)) -le $(($radius*$radius)) ]];
			then
				local x=$(($centerX+$dx))
				local y=$(($centerY+$dy))
				
				KARANDASH_CANVAS[$(($y*$KARANDASH_WIDTH+$x))]=$fillColor
			fi
		done
	done
}

# Arguments:
# 	int x1
# 	int y1
# 	int x2
# 	int y2
# 	int x3
# 	int y3
# 	Color color
# Output: 0 on success; 1 on error
draw_triangle() {
	local x1=$1
	local y1=$2
	local x2=$3
	local y2=$4
	local x3=$5
	local y3=$6
	local color=$7
	
	local minX=0
	local maxX=0
	local minY=0
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
			
			if [[ $inside -ne 0 ]];
			then
				KARANDASH_CANVAS[$(($y*$KARANDASH_WIDTH+$x))]=$color
			fi
		done
	done
	
}

# Arguments:
# 	int x1
# 	int y1
# 	int x2
# 	int y2
# 	int x3
# 	int y3
# 	Color color1
# 	Color color2
# 	Color color3
# Output: 0 on success; 1 on error
draw_gradient_triangle() {
	local x1=$1
	local y1=$2
	local x2=$3
	local y2=$4
	local x3=$5
	local y3=$6
	local color1=$7
	local color2=$8
	local color3=$9
	
	local minX=0
	local maxX=0
	local minY=0
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
			
			if [[ $inside -ne 0 && $det -ne 0 ]];
			then
				local r1=$(( color1 & 0xFF ))
				local g1=$(( color1>>8 & 0xFF ))
				local b1=$(( color1>>16 & 0xFF ))
				
				local r2=$(( color2 & 0xFF ))
				local g2=$(( color2>>8 & 0xFF ))
				local b2=$(( color2>>16 & 0xFF ))
				
				local r3=$(( color3 & 0xFF ))
				local g3=$(( color3>>8 & 0xFF ))
				local b3=$(( color3>>16 & 0xFF ))
				
				local u3=$(( $det-$u1-$u2 ))
				
				local r=$(( ($r1*$u1 + $r2*$u2 + $r3*$u3)/$det ))
				local g=$(( ($g1*$u1 + $g2*$u2 + $g3*$u3)/$det ))
				local b=$(( ($b1*$u1 + $b2*$u2 + $b3*$u3)/$det ))
				
				local color=$(( 0xFF000000 | ($b&0xFF)<<16 | ($g&0xFF)<<8 | ($r&0xFF) ))
				
				KARANDASH_CANVAS[$(($y*$KARANDASH_WIDTH+$x))]=$color
			fi
		done
	done
}

# Arguments:
# 	int x1
# 	int y1
# 	int x2
# 	int y2
# 	Color color
# Output: 0 on success; 1 on error
draw_line() {
	local x1=$1
	local y1=$2
	local x2=$3
	local y2=$4
	local color=$5
	
	if [[ ($x1 -lt 0 && $x2 -lt 0) || ($y1 -lt 0 && $y2 -lt 0) || ($x1 -ge KARANDASH_WIDTH && $x2 -ge KARANDASH_WIDTH) || ($y1 -ge KARANDASH_HEIGHT && $y2 -ge KARANDASH_HEIGHT) ]];
	then
		return 0
	fi
	
	local tmp=$((x2-x1))
	local deltaX=${tmp#-}
	tmp=$((y2-y1))
	local deltaY=${tmp#-}
	
	if [[ ($deltaX -gt $deltaY && $x2 -lt $x1) || ($deltaX -le $deltaY && $y2 -lt $y1) ]];
	then
		tmp=$x1
		x1=$x2
		x2=$tmp
		
		tmp=$y1
		y1=$y2
		y2=$tmp
	fi
	
	deltaX=$((x2-x1))
	local deltaXabs=${deltaX#-}
	deltaY=$((y2-y1))
	local deltaYabs=${deltaY#-}
	
	local step=1
	KARANDASH_CANVAS[$(($y1*$KARANDASH_WIDTH+$x1))]=$color
	
	if [[ deltaXabs -gt deltaYabs ]];
	then
		if [[ deltaY -lt 0 ]];
		then
			step=-1
			deltaY=$((-$deltaY))
		fi
		
		local d=$(($deltaY*2-$deltaX))
		local d1=$(($deltaY*2))
		local d2=$((($deltaY-$deltaX)*2))
		
		local y=$y1
		
		for (( x=$(($x1+1)); x<$x2; x++ ))
		do
			if [[ $d -gt 0 ]];
			then
				y=$(($y+$step))
				d=$(($d+$d2))
			else
				d=$(($d+$d1))
			fi
			KARANDASH_CANVAS[$(($y*$KARANDASH_WIDTH+$x))]=$color
		done
	else
		if [[ deltaX -lt 0 ]];
		then
			step=-1
			deltaX=$((-$deltaX))
		fi
		
		local d=$(($deltaX*2-$deltaY))
		local d1=$(($deltaX*2))
		local d2=$((($deltaX-$deltaY)*2))
		
		local x=$x1
		
		for (( y=$(($y1+1)); y<$y2; y++ ))
		do
			if [[ $d -gt 0 ]]
			then
				x=$(($x+$step))
				d=$(($d+$d2))
			else
				d=$(($d+$d1))
			fi
			KARANDASH_CANVAS[$(($y*$KARANDASH_WIDTH+$x))]=$color
		done
		
	fi
}

# Arguments:
# 	int x
# 	int y
# 	int width
# 	int height
# 	Color[] buffer
# Output: 0 on success; 1 on error
draw_image() {
	local x=$1
	local y=$2	
	local width=$3
	local height=$4
	shift 4
	local buffer=("$@")
	
	if [[ $x -gt KARANDASH_WIDTH || $y -gt KARANDASH_HEIGHT || $(($x+$width)) -lt 0 || $(($y+$height)) -lt 0 ]];
	then
		return 0
	fi
	
	local minDy=0
	local minDx=0
	
	if [[ $y -lt 0 ]];
	then
		minDy=${y#-}
	fi
	
	if [[ $x -lt 0 ]];
	then
		minDx=${x#-}
	fi
	
	for (( dy=minDy; dy<$height; dy++ ))
	do
		for (( dx=minDx; dx<$width; dx++ ))
		do
			KARANDASH_CANVAS[$((($y+$dy)*$KARANDASH_WIDTH+($x+$dx)))]=${buffer[$(($dy*$width+$dx))]}
		done
	done
}

# Arguments:
# 	< Stream inputFile
# 	> Stream buffer
# Output: 0 if success; 1 on error
load_raw_image_from_stream() {
	local width=0
	local height=0
	
	read32 width
	read32 height

	local buffer
	
	for (( i=0; i<$(($width*$height)); i++ ))
	do
		pixel=0
		read32 pixel
		buffer[$i]=$pixel
	done
	
	echo ${buffer[@]}
}

# Arguments:
# 	string filename
# Output: 0 if success; 1 on error
save_to_ppm() {
	local filename=$1
	
	if [[ ! -n $filename ]];
	then
		return 1
	fi
	
	local fileContent=""
	
	#file header
	fileContent+="P3"$'\n'
	fileContent+="$KARANDASH_WIDTH $KARANDASH_HEIGHT"$'\n'
	fileContent+="255"$'\n'
	fileContent+=$'\n'
	
	#file content
	
	for (( y=0; y<KARANDASH_HEIGHT; y++ ))
	do 
		for (( x=0; x<KARANDASH_WIDTH; x++ ))
		do
			local pixelIndex=$(($y*KARANDASH_WIDTH+$x))
			local r=$((KARANDASH_CANVAS[$pixelIndex] & 0xFF))
			local g=$((KARANDASH_CANVAS[$pixelIndex]>>8 & 0xFF))
			local b=$((KARANDASH_CANVAS[$pixelIndex]>>16 & 0xFF))
			
			fileContent+="$r $g $b"$'\n'
		done
	done
	
	echo "$fileContent" > $filename
}

# Arguments:
# 	int x1
# 	int y1
# 	int x2
# 	int y2
# 	int x3
# 	int y3
# 	int x
# 	int y
# 	int& u1
# 	int& u2
# 	int& det
# 	bool& inside
# Output: 0 on success; 1 on error
# u3 = det - u1 - u2
barycentric() {
	local x1=$1
	local y1=$2
	
	local x2=$3
	local y2=$4
	
	local x3=$5
	local y3=$6
	
	local x=$7
	local y=$8
	
	local output_u1=$9
	local output_u2=${10}
	local output_det=${11}
	local output_inside=${12}
	
	local _det=$(( (($x1-$x3)*($y2-$y3) - ($x2-$x3)*($y1-$y3)) ))
	local _u1=$(( (($y2-$y3)*($x-$x3) + ($x3-$x2)*($y-$y3)) ))
	local _u2=$(( (($y3-$y1)*($x-$x3) + ($x1-$x3)*($y-$y3)) ))
	local _u3=$(( $_det-$_u1-$_u2 ))
	
	local u1_sign=0
	local u2_sign=0
	local u3_sign=0
	local det_sign=0
	
	get_sign $_u1 u1_sign
	get_sign $_u2 u2_sign
	get_sign $_u3 u3_sign
	get_sign $_det det_sign
		
	local _inside=0
	if [[ $u1_sign -eq $det_sign || $_u1 -eq 0 ]] && [[ $u2_sign -eq $det_sign || $_u2 -eq 0 ]] && [[ $u3_sign -eq $det_sign || $_u3 -eq 0 ]];
	then
		_inside=1
	fi
	
	write_int_value $output_u1 $_u1
	write_int_value $output_u2 $_u2
	write_int_value $output_det $_det
	write_int_value $output_inside $_inside
}

# Arguments:
# 	int x1
# 	int y1
# 	int x2
# 	int y2
# 	int x3
# 	int y3
# 	int& minX
# 	int& maxX
# 	int& minY
# 	int& maxY
# 	bool& insideCanvas
# Output: 0 on success; 1 on error
clamp_triangle_on_canvas() {
	local x1=$1
	local y1=$2
	local x2=$3
	local y2=$4
	local x3=$5
	local y3=$6
	
	local output_minX=$7
	local output_maxX=$8
	local output_minY=$9
	local output_maxY=${10}
	local output_insideCanvas=${11}
	
	local _minX=$x1
	local _maxX=$x1
	
	if [[ $_minX -gt $x2 ]];
	then
		_minX=$x2
	fi
	
	if [[ $_minX -gt $x3 ]];
	then
		_minX=$x3
	fi
	
	if [[ $_maxX -lt $x2 ]];
	then
		_maxX=$x2
	fi
	
	if [[ $_maxX -lt $x3 ]];
	then
		_maxX=$x3
	fi
	
	if [[ $_minX -lt 0 ]];
	then
		_minX=0
	fi
	
	if [[ $_minX -ge $KARANDASH_WIDTH ]];
	then
		write_int_value $output_insideCanvas 0
		return 0
	fi
	
	if [[ $_maxX -lt 0 ]];
	then
		write_int_value $output_insideCanvas 0
		return 0
	fi
	
	if [[ $_maxX -ge $KARANDASH_WIDTH ]];
	then
		_maxX=$(($KARANDASH_WIDTH-1))
	fi
	
	local _minY=$y1
	local _maxY=$y1
	
	if [[ $_minY -gt $y2 ]];
	then
		_minY=$y2
	fi
	
	if [[ $_minY -gt $y3 ]];
	then
		_minY=$y3
	fi
	
	if [[ $_maxY -lt $y2 ]];
	then
		_maxY=$y2
	fi
	
	if [[ $_maxY -lt $y3 ]];
	then
		_maxY=$y3
	fi
	
	if [[ $_minY -ge $KARANDASH_HEIGHT ]];
	then
		write_int_value $output_insideCanvas 0
		return 0
	fi
	
	if [[ $_maxY -lt 0 ]];
	then
		write_int_value $output_insideCanvas 0
		return 0
	fi
	
	if [[ $_maxY -ge $KARANDASH_HEIGHT ]];
	then
		maxX=$(($KARANDASH_HEIGHT-1))
	fi
	
	write_int_value $output_minX $_minX
	write_int_value $output_maxX $_maxX
	write_int_value $output_minY $_minY
	write_int_value $output_maxY $_maxY
	write_int_value $output_insideCanvas 1
}

# Arguments:
# 	int number
# 	int& sign
# Output: 0 on success; 1 on error
get_sign() {
	local number=$1
	local output_sign=$2
	
	local sign=0
	
	if [[ $number -lt 0 ]];
	then
		sign=-1
	fi
	
	if [[ $number -gt 0 ]];
	then
		sign=1
	fi
	
	write_int_value $output_sign $sign
}

# Arguments:
# 	int& var
# 	int value
# Output: 0 on success; 1 on error
write_int_value() {
	printf -v $1 %d $2
}

#
# https://stackoverflow.com/questions/13889659/read-a-file-by-bytes-in-bash
#

read8() {  local _r8_var=${1:-OUTBIN} _r8_car LANG=C IFS=
    read -r -d '' -n 1 _r8_car
    printf -v $_r8_var %d "'"$_r8_car ;}
read16() { local _r16_var=${1:-OUTBIN} _r16_lb _r16_hb
    read8  _r16_lb && read8  _r16_hb
    printf -v $_r16_var %d $(( _r16_hb<<8 | _r16_lb )) ;}
read32() { local _r32_var=${1:-OUTBIN} _r32_lw _r32_hw
    read16 _r32_lw && read16 _r32_hw
    printf -v $_r32_var %d $(( _r32_hw<<16| _r32_lw )) ;}
