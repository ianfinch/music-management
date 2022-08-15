#!/bin/bash

# Grab the input parameters
album="$1"
src="$2"
target="$3"
albumArtistData="$4"

# Extract album name and artist from what was passed in.  The directory
# structure is <artist>/<album>, so we just need to split around the slash.
album=$( echo "$album" | sed -e "s|^$src/||" )
artist=$( echo "$album" | sed -e 's|/.*$||' )
album=$( echo "$album" | sed -e "s|^$artist/||" )

# Also find the album artist
albumArtist=$( grep -E "^$album/" "$albumArtistData" | sed -e 's|^.*/||' )
if [[ "$albumArtist" == "" ]] ; then
    albumArtist="Compilations"
fi

# If our source doesn't exist, create it
if [[ ! -e "$target" ]] ; then

    mkdir "$target"
fi

# Keep to a subset for initial testing
if [[ "$artist" =~ ^[ABC] ]] ; then

    # Make sure we've got a directory for this artist
    if [[ ! -e "$target/$albumArtist" ]] ; then

        mkdir "$target/$albumArtist"
    fi

    # Make sure we've got a directory for this album
    if [[ ! -e "$target/$albumArtist/$album" ]] ; then

        mkdir "$target/$albumArtist/$album"
    fi

    # Now convert each track in the source directory
    for track in "$src/$artist/$album/"* ; do

        # Get just the track part, not the full path
        track=$( echo "$track" | sed -e "s|^$src/$artist/$album/||" )

        # Only convert tracks if they don't already exist
        mp3version=$( echo "$track" | sed -e 's/\.[^.]*$/.mp3/' )
        if [[ ! -e "$target/$albumArtist/$album/$mp3version" ]] ; then

            echo "Converting to MP3: $albumArtist, $album, $track"

            # If the source is already an MP3, just copy it
            if [[ "$track" =~ \.mp3$ ]] ; then

                cp "$src/$artist/$album/$track" "$target/$albumArtist/$album/$mp3version"

            # For FLAC format, convert to MP3 via AIFF
            elif [[ "$track" =~ \.flac$ ]] ; then

                cat "$src/$artist/$album/$track" \
                    | docker run -i --rm guzo/audio-tools flac2aiff \
                    | docker run -i --rm guzo/audio-tools aiff2mp3 \
                    > "$target/$albumArtist/$album/$mp3version"
            else

                echo "Unable to find converter"
            fi

            # Now set the tags on the converted track
            if [[ -e "$target/$albumArtist/$album/$mp3version" ]] ; then

                $( dirname $0 )/add-tags.sh "$src/$artist/$album/$track" "$target/$albumArtist/$album/$mp3version"
            fi
        fi
    done
fi
