#!/bin/bash

# The folder of master versions should have been passed in
master="$1"

# The location for our list of album artists should also have been passed in
datafile="$2"

# Temporary directory to work in
/bin/mkdir /tmp/$$

# Only run this if we don't already have a data file
if [[ -e $datafile ]] ; then

    exit
fi

# Run find command from master directory (to keep paths shorter)
    cd "$master"
    for track in $( find . -type f -not -name '.*' ) ; do

        # Get album and artist
        album=$( echo $track | /usr/bin/cut -d '/' -f3 )
        artist=$( echo $track | /usr/bin/cut -d '/' -f2 | /usr/bin/sed 's/_feat\._.*//' )

        # Use a directory to store the album name
        if [[ ! -e /tmp/$$/$album ]] ; then
            /bin/mkdir /tmp/$$/$album
        fi

        # Stick the artist into the album directory
        /usr/bin/touch /tmp/$$/$album/$artist
    done

# Identify album artists
for album in $( find /tmp/$$/ -type d -execdir echo {} \; ) ; do

    artists=$( /bin/ls /tmp/$$/$album/* | /usr/bin/wc -l )
    (( artists = 0 + artists ))
    if [[ $artists == 1 ]] ; then
        echo "$album/$( /bin/ls /tmp/$$/$album/ )" | sed -e 's|^\./||' >> $datafile
    fi
done

# Remove temporary directory
/bin/rm -rf /tmp/$$
