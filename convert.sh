#!/bin/bash

# Deluge parameters
id=$1
folder=$2
downloads=$3

# Plex library folder locations
kids=""
movies=""
series=""
classics=""

# These are Plex media root folder location
target=""
constant=""

# Convert to test folder location
test=""

path="$downloads/$folder"

# Output log path
log=""

# Get deluge mdeia label via python script
label=$(/opt/deluge-1.3.15/bin/python "SCRIPTLOCATION"/label.py $id)

################################################################
# ADD PATH FROM LABEL ##########################################
################################################################


case $label in

	"kids")
		target=$kids
    ;;
	
	"movies")
		target=$movies
    ;;

	"series")
		target=$series
    ;;
	
	"classics")
		target=$classics
    ;;

  *)
    target=$test
    ;;
esac

echo "Target: $target" >> $log

################################################################
# BEGIN CONVERT ################################################
################################################################

if [ $target != $constant ]; then
	
	for file in $(find $path -name *.mkv -o -name *.mp4 -o -name *.fly -o -name *.avi -o -name *.wmv); do
	
		filename=${file##*/}
		basename=${filename%.*}
		
		echo "----------------------------------------------------------" >> $log
		echo "ID: $id" >> $log
		echo "Label: $label" >> $log
		echo "Folder: $folder" >> $log
		echo "Downloads: $downloads" >> $log
		echo "File: $basename" >> $log

		daAudio=false
		enAudio=false
		daSub=false
		enSub=false

		videoStream=0
		
		daAudioStream=0
		enAudioStream=0
		
		daSubStream=0
		enSubStream=0
		
		# ffprobe media details
		currentFormat=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 "$file")		
		audios=$(ffprobe -loglevel error -show_entries stream=index:stream_tags=language -select_streams a -of compact=p=0:nk=1 "$file")		
		subs=$(ffprobe -loglevel error -select_streams s -show_entries stream=index:stream_tags=language -of csv=p=0 "$file")
	
		#Check audio lang			
		for lang in $audios
		do	
			result=$(printf '%s' "$lang" | sed 's/[0-9]*|//g')
				
			if [ "$result" = "da" ] ;
				then
					daAudioStream=$(echo $lang | cut -c 1)
					daAudio=true
					echo "Danish language" >> $log
			fi
			
			if [ "$result" = "dan" ] ;
				then
					
					daAudioStream=$(echo $lang | cut -c 1)
					daAudio=true
					echo "Danish language" >> $log
			fi
				
			if [ "$result" = "en" ] ;
				then
					enAudioStream=$(echo $lang | cut -c 1)
					enAudio=true
					echo "English language" >> $log
			fi
			
			if [ "$result" = "eng" ] ;
				then
					enAudioStream=$(echo $lang | cut -c 1)
					enAudio=true
					echo "English language" >> $log					
			fi
			
		done
		
		#Check sub lang	
		for lang in $subs
		do
			result=$(printf '%s' "$lang" | sed 's/[0-9]*,//g')
				
			if [ "$result" = "da" ] ;
				then
					daSubStream=$(echo $lang | cut -c 1)
					daSub=true
					echo "Danish subtitle" >> $log		
			fi
			
			if [ "$result" = "dan" ] ;
				then
					daSubStream=$(echo $lang | cut -c 1)
					daSub=true
					echo "Danish subtitle" >> $log		
			fi
				
			if [ "$result" = "en" ] ;
				then
					enSubStream=$(echo $lang | cut -c 1)
					enSub=true
					echo "English subtitle" >> $log		
			fi
			
			if [ "$result" = "eng" ] ;
				then
					enSubStream=$(echo $lang | cut -c 1)
					enSub=true
					echo "English subtitle" >> $log							
			fi
			
		done
		
		# CONVERT
		
		params=""
		
		if [ "$currentFormat" = "h264" ] ; 
			then params="$params -c copy"
			else params="$params -c:v libx264"
		fi
		
		if [ $daAudio = true ] && [ $enAudio = true ] ; 
			then params="$params -map 0:$daAudioStream:a -c:a:0 aac -ac:a:0 2 -b:a:0 256k -map 0:$enAudioStream:a -c:a:1 ac3 -ac:a:1 6"
		fi
		
		if [ $daAudio = true ] && [ $enAudio = false ] ; 
			then params="$params -map 0:$daAudioStream:a -c:a:0 aac -ac:a:0 2 -b:a:0 256k -map 0:$daAudioStream:a -c:a:1 ac3 -ac:a:1 6"
		fi
		
		if [ $daAudio = false ] && [ $enAudio = true ] ; 
			then params="$params -map 0:$enAudioStream:a -c:a:0 aac -ac:a:0 2 -b:a:0 256k -map 0:$enAudioStream:a -c:a:1 ac3 -ac:a:1 6"
		fi
		
		if [ $daAudio = false ] && [ $enAudio = false ] ; 
			then params="$params -map 0:0:a -c:a:0 aac -ac:a:0 2 -b:a:0 256k -map 0:0:a -c:a:0 ac3 -ac:a:0 6"
		fi
		
		if [ $daSub = true ] ; 
			then params="$params -map 0:$daSubStream:s"
		fi
		
		if [ $enSub = true ] ; 
			then params="$params -map 0:$enSubStream:s"
		fi
		
		if [ $daSub = true ] ||  [ $enSub = true ] ; 
			then params="$params -c:s mov_text"
		fi
		
		ffmpeg -i "$file" -map 0:v$params "$target/${basename}.mp4"
			
	done
	
fi
