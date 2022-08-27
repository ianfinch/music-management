#!/bin/bash
#
# Check that all tracks in an album have artwork

album="$1"
artwork="$2"
fonts="$3"
cache="$4"

artist=$( echo "$album" | sed -e 's|/[^/]*$||' -e 's|^.*/||' )
albumName=$( echo "$album" | sed -e 's|^.*/||' )

echo "Checking album: $artist, $albumName"

# Our script to find / create covers
createCover="$( dirname $0 )/create-cover.sh"

# A file for our artwork
cover="${cache}/Covers/${artist}/${albumName}.png"

# Go through each track in this album, checking for cover art
find "$album" -name '*.mp3' | while read track ; do

    # Grab the album art tag
    apic=$( docker run --rm -v"$track":/home/appuser/audiofile guzo/audio-tools mid3v2 --list audiofile \
                | grep ^APIC )

    # We only need to do anything if we don't already have artwork
    if [[ "$apic" == "" ]] ; then

        # We need some actual artwork - create it if necessary
        if [[ ! -e "$cover" ]] ; then

            if [[ ! -e "${cache}" ]] ; then
                mkdir "${cache}"
            fi

            if [[ ! -e "${cache}/Covers" ]] ; then
                mkdir "${cache}/Covers"
            fi

            if [[ ! -e "${cache}/Covers/${artist}" ]] ; then
                mkdir "${cache}/Covers/${artist}"
            fi

            "$createCover" "$track" "$artwork" "$fonts" > "$cover"
        fi

        # Add the image to the file
        docker run --rm                                 \
                   -v"$track":/home/appuser/audiofile   \
                   -v"$cover":/home/appuser/coverfile   \
                   guzo/audio-tools                     \
                   mid3v2 --picture coverfile audiofile
    fi
done
