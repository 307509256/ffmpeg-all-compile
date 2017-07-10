#!/bin/bash

# the jobs to make ffmpeg
if [[ "" == $SRS_JOBS ]]; then 
    export SRS_JOBS="--jobs=8" 
fi

ff_current_dir=$(pwd -P)
ff_build_dir="${ff_current_dir}/_build"
ff_release_dir="${ff_current_dir}/_release"
echo "start to build the tools for transcode system:"
echo "current_dir: ${ff_current_dir}"
echo "build_dir: ${ff_build_dir}"
echo "release_dir: ${ff_release_dir}"
echo "SRS_JOBS: ${SRS_JOBS}"

mkdir -p ${ff_build_dir}
mkdir -p ${ff_release_dir}

#1 yasm for libx264
ff_yasm_bin=${ff_release_dir}/bin/yasm
if [[ -f ${ff_yasm_bin} ]]; then 
    echo "yasm is ok"
else
    echo "build yasm"
    cd $ff_current_dir &&
    cd yasm && ./configure --prefix=${ff_release_dir} &&
    make && make install
    ret=$?; if [[ 0 -ne ${ret} ]]; then echo "build yasm failed"; exit 1; fi
fi
# add yasm to path, for x264 to use yasm directly.
# ffmpeg can specifies the yasm path when configure it.
export PATH=${PATH}:${ff_release_dir}/bin

#2 libfdk-aac
if [[ -f ${ff_release_dir}/lib/libfdk-aac.a ]]; then
    echo "libfdk_aac is ok"
else
    echo "build fdk-aac"
    cd $ff_current_dir &&
    cd fdk-aac && bash autogen.sh && ./configure --prefix=${ff_release_dir} --enable-static && make ${SRS_JOBS} && make install
    ret=$?; if [[ 0 -ne ${ret} ]]; then echo "build fdk-aac failed"; exit 1; fi
fi

#3 lame
if [[ -f ${ff_release_dir}/lib/libmp3lame.a ]]; then
    echo "libmp3lame is ok"
else
    echo "build lame-3.99.5"
    cd $ff_current_dir &&
    cd lame-3.99.5 && ./configure --prefix=${ff_release_dir} --enable-static && make ${SRS_JOBS} && make install
    ret=$?; if [[ 0 -ne ${ret} ]]; then echo "build lame failed"; exit 1; fi
fi

#4 libogg
if [[ -f ${ff_release_dir}/lib/libogg.a ]]; then
    echo "libogg.a is ok"
else
    echo "build libogg"
    cd $ff_current_dir &&
    cd libogg-1.3.2 && ./configure --prefix=${ff_release_dir} --enable-static && make ${SRS_JOBS} && make install
    ret=$?; if [[ 0 -ne ${ret} ]]; then echo "libogg failed"; exit 1; fi
fi

#5 faac
if [[ -f ${ff_release_dir}/lib/libfaac.a ]]; then
    echo "libfaac.a is ok"
else
    echo "build libfaac"
    cd $ff_current_dir &&
    cd faac-1.28 && ./configure --prefix=${ff_release_dir} --enable-static && make ${SRS_JOBS} && make install
    ret=$?; if [[ 0 -ne ${ret} ]]; then echo "faac failed"; exit 1; fi
fi

#6 libtheora
if [[ -f ${ff_release_dir}/lib/libtheoraenc.a ]]; then
    echo "libtheoraenc.a is ok"
else
    echo "build libtheoraenc"
    cd $ff_current_dir &&
    cd libtheora-1.1.1 && ./configure --prefix=${ff_release_dir} --enable-static && make ${SRS_JOBS} && make install
    ret=$?; if [[ 0 -ne ${ret} ]]; then echo "libtheora-1.1.1 failed"; exit 1; fi
fi

#7 libvorbis
if [[ -f ${ff_release_dir}/lib/libvorbis.a ]]; then
    echo "libvorbis.a is ok"
else
    echo "build libvorbis"
    cd $ff_current_dir &&
    cd libvorbis-1.3.5 && ./configure --prefix=${ff_release_dir} --enable-static && make ${SRS_JOBS} && make install
    ret=$?; if [[ 0 -ne ${ret} ]]; then echo "libvorbis-1.3.5 failed"; exit 1; fi
fi

#8 xvidcore
if [[ -f ${ff_release_dir}/lib/libxvidcore.a ]]; then
    echo "libxvidcore.a is ok"
else
    echo "build xvidcore"
    cd $ff_current_dir &&
    cd xvidcore/build/generic && ./configure --prefix=${ff_release_dir} --enable-static && make ${SRS_JOBS} && make install
    ret=$?; if [[ 0 -ne ${ret} ]]; then echo "xvidcore failed"; exit 1; fi
fi

#9 x264
if [[ -f ${ff_release_dir}/lib/libx264.a ]]; then
    echo "x264 is ok"
else
    echo "build x264"
    cd $ff_current_dir &&
    cd x264 && 
    chmod +w configure &&
    ./configure \
    		--prefix=${ff_release_dir} --enable-static --disable-opencl --disable-avs  --disable-cli --disable-ffms \
    		--disable-gpac --disable-lavf --disable-swscale && 
    make ${SRS_JOBS} && make install
    ret=$?; if [[ 0 -ne ${ret} ]]; then echo "build x264 failed"; exit 1; fi
fi

#10 ffmpeg
if [[ -f ${ff_release_dir}/bin/ffmpeg ]]; then
    echo "ffmpeg is ok"
else
    echo "build ffmpeg"
    cd $ff_current_dir &&
    echo "remove all so to force the ffmpeg to build in static" &&
    rm -f ${ff_release_dir}/lib/*.so* &&
    echo "export the dir to enable the build command canbe use." &&
    export ffmpeg_exported_release_dir=${ff_release_dir} &&
    cd ffmpeg-3.3.2 && 
    ./configure \
        --enable-gpl --enable-nonfree \
        --yasmexe=${ff_yasm_bin} \
        --prefix=${ff_release_dir} --cc= \
        --enable-static --disable-shared --disable-debug \
        --extra-cflags='-I${ffmpeg_exported_release_dir}/include' \
        --extra-ldflags='-L${ffmpeg_exported_release_dir}/lib -lm -ldl' \
        --enable-ffmpeg --disable-ffplay --enable-gpl \
        --enable-version3 --enable-nonfree --enable-postproc --enable-pthreads \
        --enable-encoders --enable-decoders --enable-avfilter --enable-muxers --enable-demuxers \
        --enable-zlib --enable-libfdk_aac --enable-libmp3lame  --enable-libx264  \
        --enable-libtheora --enable-libxvid  --enable-libvorbis  && 
    make ${SRS_JOBS} && make install
    ret=$?; if [[ 0 -ne ${ret} ]]; then echo "build ffmpeg failed"; exit 1; fi
fi

