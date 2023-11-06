#!/bin/bash

# TODO: create demos

for demo in demos/*
do
	echo "Run $demo demo..."
	./$demo
	echo "$demo demo done"
done