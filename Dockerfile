FROM alpine

RUN addgroup --gid 1000 -S appuser && adduser --uid 1000 -S appuser -G appuser
WORKDIR /home/appuser

RUN apk update && \
    apk add flac && \
    apk add lame && \
    apk add mutagen

RUN echo "#!/bin/sh" > /usr/local/bin/flac2aiff && \
    echo "flac --decode --stdout --force-aiff-format --silent -" >> /usr/local/bin/flac2aiff && \
    chmod 755 /usr/local/bin/flac2aiff

RUN echo "#!/bin/sh" > /usr/local/bin/aiff2mp3 && \
    echo "lame --silent -V 1 - /tmp/out.mp3" >> /usr/local/bin/aiff2mp3 && \
    echo "cat /tmp/out.mp3" >> /usr/local/bin/aiff2mp3 && \
    chmod 755 /usr/local/bin/aiff2mp3

USER appuser
CMD ls
