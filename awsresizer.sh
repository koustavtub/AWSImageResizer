#!/bin/bash
# Author: Koustav Ray

echo -e "\033[31m -----------------------------------------------------------"
echo ""
echo "▁ ▂ ▄ ▅ ▆ ▇ █ ĸoυѕтav'z ѕнell ιмage reѕιzer  █ ▇ ▆ ▅ ▄ ▂ ▁"
echo ""
echo "-----------------------------------------------------------"
echo -e "\033[0m "

echo "Run 'aws configure' before running this script and set your configurations"
echo "Region MUST be set to s3 Bucket creation Region eg: ap-southeast-1 "

#Our Recursive Function
function RecursiveResize
{
	echo ""
	echo "--------------------------------- Converting Images in `pwd` ---------------------------------"
	for file in `pwd`/*
	do
		
	#Check if the file is among the allowed image extensions (Add your own if you want like .tiff)
	
	   	case "$file" in  *.jpg | *.jpeg| *.gif| *.png| *.JPG| *.PNG| *.JPEG| *.GIF ) 
	        
		        #Change Resolution if Required... Default is ( 2073600 = 1920x1080 )"
		        convert $file -quality 85 -resize @2073600\> $file
		        echo "Yay! Converted ${file}" 	        
	        ;;
	        *)
	         	echo  -e "\033[33m $file is NOT an Image .. \033[0m "
	        ;;
	   	esac
	
	#Check if Directory and Go Into Directory and recursively call this function
	
		if [[ -d "${file}" ]]; then
	            cd "${file}"
	            RecursiveResize $(ls -1 ".")
	            cd ..
	     fi
    done
}



usage="$(basename "$0") [-h] [-s] [s3 URL] [-l] [Local FileSystem URL]

where:
    -h  show this help text
    -s  set the [s3 URL] followed by -l [Local FileSystem URL]
    -l  set the [Local FileSystem URL] preceded by -s [s3 URL]"


while getopts ':h:s:l:' option; do
  case "$option" in
    ""h) echo "$usage"
       exit
       ;;
    s) s3url=$OPTARG
       ;;
    l) localUrl=$OPTARG
	   ;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))

function notSet
{
		echo "$1 Not Set."
		echo "S3 URL and Local URL must be both set.."
		echo ""
		echo "$usage"
}


if [ -n "$s3url" ] && [ -z "$localUrl" ]; then
		notSet "Local URL"
		exit 1
elif [ -z "$s3url" ] && [ -n "$localUrl" ]; then
		notSet "S3 URL"
		exit 1
elif [ -n "$s3url" ] && [ -n "$localUrl" ]; then
	#Sync From aws 
	aws s3 sync $s3url $localUrl 
	
	#Check if Local Directory specified exists
	if [[ -d "${localUrl}" ]]; then
	            cd "${localUrl}"
	            RecursiveResize
	            cd -
	else
		echo "${localUrl} directory not found!"
		echo "Exiting............................"
		exit 1
	fi
	
	#Sync to aws
	aws s3 sync $localUrl $s3url 
else
	echo "Running in Conversion Only Mode in `pwd` !"
	read  -p "Continue(Y/n)" confirm
	if 	[ -n "$confirm" ] && [ "Y" = "$confirm" ]; then
		#Finally Call The Recursive Function
		RecursiveResize
	fi
fi

echo "################## Completed ##################"
