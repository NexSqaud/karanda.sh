#!/bin/bash

for demo in demos/*
do
	echo "Run $demo demo..."
	./$demo
	echo "$demo demo done"
done
