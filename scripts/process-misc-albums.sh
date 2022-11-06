#!/bin/bash

# Grab the input parameters
albumPath="$1"
base="$2"
dst="$3"

# Break down the album details
artistAndAlbum=$( echo "${albumPath}" | sed "s|^${base}||" )
artist=$( echo "${artistAndAlbum}" | cut -d'/' -f1 )
album=$( echo "${artistAndAlbum}" | cut -d'/' -f2 )

# Check we've got a directory for the artist
if [[ ! -e "${dst}/${artist}" ]] ; then
    mkdir "${dst}/${artist}"
fi

# Check we've got a directory for the album
if [[ ! -e "${dst}/${artist}/${album}" ]] ; then
    mkdir "${dst}/${artist}/${album}"
fi

# Now copy across the files from the source folder
for track in "${albumPath}/"* ; do

    target="${dst}/${artist}/${album}/$( basename "$track" )"
    if [[ ! -e "${target}" ]] ; then

        cp -v "${track}" "${target}"
    fi
done
