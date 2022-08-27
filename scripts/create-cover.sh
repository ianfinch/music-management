#!/bin/bash
#
# Generate a CD cover for an MP3, based on the tags inside it.

track="$1"
artwork="$2"
fonts="$3"

# We have an icon font and a script font
script="$fonts/budhand.ttf"
icon="$fonts/webdings.ttf"

# Variables for the artwork
fadeStart="gold"
fadeEnd="red"
inner="#002200"
border="#fff"
overlay="#cccccc99"

# Get the artist and album
artist=$( docker run -v"$track":/home/appuser/audiofile guzo/audio-tools mid3v2 --list audiofile \
            | grep ^TPE2 | cut -d'=' -f2 | sed -e "s/[\r\n]//" -e 's/ /_/g' )
album=$( docker run -v"$track":/home/appuser/audiofile guzo/audio-tools mid3v2 --list audiofile \
            | grep ^TALB | cut -d'=' -f2 | sed -e "s/[\r\n]//" -e 's/ /_/g' )

# Square off an image to its shortest side
__squarify() {

    image="$1"
    result="/tmp/$$.squared.png"

    w=$( identify -format "%w" "$image" )
    h=$( identify -format "%h" "$image" )

    if [[ "$w" -eq "$h" ]] ; then

        if [[ "$image" =~ \.png$ ]] ; then

            result="$image"
        else

            convert "$image" "$result"
        fi

    elif [[ "$w" -gt "$h" ]] ; then

        convert "$image" -resize ${h}x$h^ -gravity center -extent ${h}x$h "$result"
    else

        convert "$image" -resize ${w}x$w^ -gravity center -extent ${w}x$w "$result"
    fi

    echo "$result"
}

# Find an album cover by artist and album name
__findAlbumCover() {

    album="$1"

    match=""
    if [[ -e "${album}.png" ]] ; then

        match=$( __squarify "${album}.png" )

    elif [[ -e "${album}.jpg" ]] ; then

        match=$( __squarify "${album}.jpg" )

    elif [[ -e "${album}.gif" ]] ; then

        match=$( __squarify "${album}.gif" )
    fi

    echo "$match"
}

# Add an album title to an image
__overlayAlbumName() {

    image="$1"
    artist="$2"
    album="$3"

    resized="/tmp/$$.resized.png"
    titled="/tmp/$$.titled.png"

    # Resize the image to a standard size
    convert "$image" -resize 500x500^ -gravity center -extent 500x500 "$resized"

    # Overlay the text
    convert "$resized"                                                                 \
            \( -size 500x80 xc:"$overlay" \) -gravity north -geometry +0+0 -composite  \
            \( -size 500x80 xc:"$overlay" \) -gravity south -geometry +0+0 -composite  \
            -size 460x60 -pointsize 0 -background none -fill black -font "$script"     \
            label:"$album" -gravity north -geometry +0+10 -composite                   \
            label:"$artist" -gravity south -geometry +0+10 -composite                  \
            "$titled"

    echo "$titled"
}

# Find a default picture for an artist
__findDefaultPicture() {

    artist="$1"
    album="$2"

    # Grab the default image
    match=""
    if [[ -e "${artist}/default.png" ]] ; then

        match=$( __squarify "${artist}/default.png" )

    elif [[ -e "${artist}/default.jpg" ]] ; then

        match=$( __squarify "${artist}/default.jpg" )

    elif [[ -e "${artist}/default.gif" ]] ; then

        match=$( __squarify "${artist}/default.gif" )
    fi

    # Add the album and artist to the cover
    if [[ "$match" != "" ]] ; then

        artistText=$( echo "$artist" | sed -e 's|^.*/||' -e 's/_/ /g' )
        albumText=$( echo "$album" | sed -e 's/_/ /g' )
        match=$( __overlayAlbumName "$match" "$artistText" "$albumText" )
    fi

    echo "$match"
}

__createGenericCover() {

    artist="$1"
    album="$2"

    generic="/tmp/$$.generic.png"

    convert -size 800x800 gradient:"$fadeStart"-"$fadeEnd" -rotate 20 -crop 500x500+200+200     \
            -background none -fill "$inner" -gravity center -font "$icon" -pointsize 400 label:'º' \
            -geometry +3+10 -composite                                                             \
            "$generic"

    titled=$( __overlayAlbumName "$generic" "$artist" "$album" )

    echo "$titled"
}

# Check we have a directory for this artist
if [[ -e "${artwork}/${artist}" ]] ; then

    # Check whether we have this album cover
    match=$( __findAlbumCover "${artwork}/${artist}/${album}" )

    # If we don't have an album cover, look for a default image
    if [[ "$match" == "" ]] ; then

        match=$( __findDefaultPicture "${artwork}/${artist}" "$album" )
    fi
fi

# If we have no directory and no default picture for this artist, we need to
# generate a complete album cover
if [[ "$match" == "" ]] ; then

    artistText=$( echo "$artist" | sed -e 's|^.*/||' -e 's/_/ /g' )
    albumText=$( echo "$album" | sed -e 's/_/ /g' )
    match=$( __createGenericCover "$artistText" "$albumText" )
fi

# Finish and clean up
cat "$match"
rm /tmp/$$.*
