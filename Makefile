SHELL := bash
DEFAULT_GOAL := all

include ./Makefile.config

.PHONY: all
all: mp3

identifyAlbumArtists:
	./scripts/identify-album-artists.sh '$(master)/CDs' '$(albumArtists)'

mp3: identifyAlbumArtists
	find '$(master)/CDs' -mindepth 2 -type d -exec ./scripts/process-master-album.sh {} '$(master)/CDs' '$(mp3s)' '$(albumArtists)' \;
