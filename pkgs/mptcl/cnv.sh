#!/bin/sh
#
# Convert media to a seekable format
#
exec ffmpeg \
    -i "$1" \
    -c:v mjpeg \
    -acodec adpcm_ms \
    "$2"
exit $?



# Default codec:
#    ffvhuf 
D..... = Decoding supported
 .E.... = Encoding supported
 ..V... = Video codec
 .....S = Lossless compression

mjpeg
ffv1/huffyuv

