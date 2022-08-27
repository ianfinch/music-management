#!/bin/bash

# Grab the input parameters
album="$1"
src="$2"
target="$3"
albumArtistData="$4"
artwork="$5"

# Somewhere to grab debug data
debugData="INPUT PARAMETERS: album = $album, src = $src, target = $target, albumArtistData = $albumArtistData"

# Extract album name and artist from what was passed in.  The directory
# structure is <artist>/<album>, so we just need to split around the slash.
album=$( echo "$album" | sed -e "s|^$src/||" )
artist=$( echo "$album" | sed -e 's|/.*$||' )
album=$( echo "$album" | sed -e "s|^$artist/||" )

# Also find the album artist
albumArtist=$( grep "^$album/" "$albumArtistData" | sed -e 's|^.*/||' )
if [[ "$albumArtist" == "" ]] ; then
    albumArtist="Various_Artists"
fi

# To handle albums by different artists with the same names (e.g. Greatest
# Hits), I append unique IDs after an equals sign at the end of an album name
# (e.g. Lenny Kravitz's Greatest Hits becomes Greatest_Hits=LK).  So we need to
# strip that out here to get the target name for the album.
targetAlbum=$( echo "$album" | sed -e 's/=.*//' )

debugData="$debugData / PARSED DATA: album = $album, artist = $artist, albumArtist = $albumArtist, targetAlbum = $targetAlbum"

# If our top-level source directory doesn't exist, create it
if [[ ! -e "$target" ]] ; then

    mkdir "$target"
fi

# Make sure we've got a directory for this artist
if [[ ! -e "$target/$albumArtist" ]] ; then

    mkdir "$target/$albumArtist"
fi

# Make sure we've got a directory for this album
if [[ ! -e "$target/$albumArtist/$targetAlbum" ]] ; then

    mkdir "$target/$albumArtist/$targetAlbum"
fi

# Now convert each track in the source directory
for track in "$src/$artist/$album/"* ; do

    # Get just the track part, not the full path
    track=$( echo "$track" | sed -e "s|^$src/$artist/$album/||" )

    # If we get an error, print some debug information
    if [[ "$track" == '*' ]] ; then

        echo "$debugData"
        exit 1
    fi

    # Only convert tracks if they don't already exist
    mp3version=$( echo "$track" | sed -e 's/\.[^.]*$/.mp3/' )
    if [[ ! -e "$target/$albumArtist/$targetAlbum/$mp3version" ]] ; then

        if [[ "$albumArtist" == "$artist" ]] ; then
            echo "Converting to MP3: $albumArtist, $targetAlbum, $track"
        else
            echo "Converting to MP3: $albumArtist ($artist), $album, $track"
        fi

        # If the source is already an MP3, just copy it
        if [[ "$track" =~ \.mp3$ ]] ; then

            cp "$src/$artist/$album/$track" "$target/$albumArtist/$targetAlbum/$mp3version"

        # For FLAC format, convert to MP3 via AIFF
        elif [[ "$track" =~ \.flac$ ]] ; then

            cat "$src/$artist/$album/$track" \
                | docker run -i --rm guzo/audio-tools flac2aiff \
                | docker run -i --rm guzo/audio-tools aiff2mp3 \
                > "$target/$albumArtist/$targetAlbum/$mp3version"
        else

            echo "Unable to find converter"
        fi

        # Now set the tags on the converted track
        if [[ -e "$target/$albumArtist/$targetAlbum/$mp3version" ]] ; then

            $( dirname $0 )/add-tags.sh "$src/$artist/$album/$track" "$target/$albumArtist/$targetAlbum/$mp3version"
        fi
    fi
done
