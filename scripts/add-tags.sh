#!/bin/bash

# The parameters
src="$1"
dst="$2"

# Get info about the track
track="$( echo $src | /usr/bin/awk -F '/' '{print $NF}' )"

if [[ "$track" =~ ^cd ]] ; then

    cdNumber="$( echo $track | cut -d'.' -f1 | sed -e 's/^cd//' )"
    trackNumber="$( echo $track | cut -d'.' -f2 | sed -e 's/^0//' )"
    track="$( echo $track | sed -e 's/^[^.]*\.[^.]*\.//' -e 's/\.[^.]*$//' -e 's/_/ /g' )"
else

    cdNumber=""
    trackNumber="$( echo $track | cut -d'.' -f1 | sed -e 's/^0//' )"
    track="$( echo $track | sed -e 's/^[^.]*\.//' -e 's/\.[^.]*$//' -e 's/_/ /g' )"
fi

album="$( echo $src | /usr/bin/awk -F '/' '{print $(NF - 1)}' )"
artist="$( echo $src | /usr/bin/awk -F '/' '{print $(NF - 2)}' | /usr/bin/sed 's/_/ /g' )"
albumArtist="$( echo $dst | /usr/bin/awk -F '/' '{print $(NF - 2)}' | /usr/bin/sed 's/_/ /g' )"
album="$( echo $album | /usr/bin/sed -e 's/_/ /g' -e 's/=.*//' )"

# Update the mp3 tags
docker run -ti --rm -v"$dst":/home/appuser/audiofile guzo/audio-tools mid3v2 --delete-all audiofile
docker run -ti --rm -v"$dst":/home/appuser/audiofile guzo/audio-tools mid3v2 --TALB "$album" audiofile \
                                                                        --TIT2 "$track" audiofile \
                                                                        --TRCK "$trackNumber" audiofile \
                                                                        --TPE1 "$artist" audiofile \
                                                                        --TPE2 "$albumArtist" audiofile

# If it's a compilation, add the marker for that
if [[ "$albumArtist" == "Various Artists" ]] ; then

    docker run -ti --rm -v"$dst":/home/appuser/audiofile guzo/audio-tools mid3v2 --TCMP 1 audiofile
fi

# For multi-CD sets, store CD number
if [[ "$cdNumber" != "" ]] ; then

    docker run -ti --rm -v"$dst":/home/appuser/audiofile guzo/audio-tools mid3v2 --TPOS "$cdNumber" audiofile
fi
