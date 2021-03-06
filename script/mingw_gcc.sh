#!/bin/bash
# -*- coding: utf-8 -*-
# Ubuntu 上で Windows バイナリのビルド (gcc)
# sudo apt install build-essential mingw-w64 libopenblas-dev

# Example 1: 全パターンのビルド
# mingw_gcc.sh

# Example 2: 指定パターンのビルド(-e: エディション名, -t: ターゲット名)
# mingw_gcc.sh -e YANEURAOU_ENGINE_NNUE

# Example 3: 特定パターンのビルド(ワイルドカード使用時はシングルクォートで囲む)
# mingw_gcc.sh -e '*KPPT*,*NNUE*'

MAKE=make
MAKEFILE=Makefile
JOBS=`grep -c ^processor /proc/cpuinfo 2>/dev/null`

ARCHCPUS='*'
COMPILERS="x86_64-w64-mingw32-g++-posix,i686-w64-mingw32-g++-posix"
DEBUG='off'
EDITIONS='*'
OS='Windows_NT'
TARGETS='*'

while getopts a:c:e:t: OPT
do
  case $OPT in
    a) ARCHCPUS="$OPTARG"
      ;;
    c) COMPILERS="$OPTARG"
      ;;
    d) DEBUG="$OPTARG"
      ;;
    e) EDITIONS="$OPTARG"
      ;;
    o) OS="$OPTARG"
      ;;
    t) TARGETS="$OPTARG"
      ;;
  esac
done

set -f
IFS=, eval 'ARCHCPUSARR=($ARCHCPUS)'
IFS=, eval 'COMPILERSARR=($COMPILERS)'
IFS=, eval 'EDITIONSARR=($EDITIONS)'
IFS=, eval 'TARGETSARR=($TARGETS)'

pushd `dirname $0`
pushd ../source

ARCHCPUS=(
  AVX512VNNI
  AVX512
  AVXVNNI
  AVX2
  SSE42
  SSE41
  SSSE3
  SSE2
  NO_SSE
  OTHER
  ZEN1
  ZEN2
  ZEN3
)

EDITIONS=(
  YANEURAOU_ENGINE_NNUE
  YANEURAOU_ENGINE_NNUE_HALFKPE9
  YANEURAOU_ENGINE_NNUE_KP256
  YANEURAOU_ENGINE_KPPT
  YANEURAOU_ENGINE_KPP_KKPT
  YANEURAOU_ENGINE_MATERIAL
  MATE_ENGINE
  USER_ENGINE
)

TARGETS=(
  normal
  tournament
  evallearn
)

declare -A DIRSTR;
DIRSTR=(
  ["YANEURAOU_ENGINE_NNUE"]="NNUE"
  ["YANEURAOU_ENGINE_NNUE_HALFKPE9"]="NNUE_HALFKPE9"
  ["YANEURAOU_ENGINE_NNUE_KP256"]="NNUE_KP256"
  ["YANEURAOU_ENGINE_KPPT"]="KPPT"
  ["YANEURAOU_ENGINE_KPP_KKPT"]="KPP_KKPT"
  ["YANEURAOU_ENGINE_MATERIAL"]="KOMA"
  ["MATE_ENGINE"]="MATE"
  ["USER_ENGINE"]="USER"
);

declare -A FILESTR;
FILESTR=(
  ["YANEURAOU_ENGINE_NNUE"]="YaneuraOu_NNUE"
  ["YANEURAOU_ENGINE_NNUE_HALFKPE9"]="YaneuraOu_NNUE_KPE9"
  ["YANEURAOU_ENGINE_NNUE_KP256"]="YaneuraOu_NNUE_KP256"
  ["YANEURAOU_ENGINE_KPPT"]="YaneuraOu_KPPT"
  ["YANEURAOU_ENGINE_KPP_KKPT"]="YaneuraOu_KPP_KKPT"
  ["YANEURAOU_ENGINE_MATERIAL"]="YaneuraOu_KOMA"
  ["MATE_ENGINE"]="tanuki_MATE"
  ["USER_ENGINE"]="user"
);

for COMPILER in ${COMPILERSARR[@]}; do
  echo "* compiler: ${COMPILER}"
  CSTR=${COMPILER##*/}
  CSTR=${CSTR##*\\}
  for EDITION in ${EDITIONS[@]}; do
    for EDITIONPTN in ${EDITIONSARR[@]}; do
      if [[ $EDITION == $EDITIONPTN ]]; then
        echo "* edition: ${EDITION}"
        BUILDDIR=../build/mingw/${DIRSTR[$EDITION]}
        mkdir -p ${BUILDDIR}
        for TARGET in ${TARGETS[@]}; do
          for TARGETPTN in ${TARGETSARR[@]}; do
            if [[ $TARGET == $TARGETPTN ]]; then
              echo "* target: ${TARGET}"
              for ARCHCPU in ${ARCHCPUS[@]}; do
                for ARCHCPUPTN in ${ARCHCPUSARR[@]}; do
                  if [[ $ARCHCPU == $ARCHCPUPTN ]]; then
                    echo "* archcpu: ${ARCHCPU}"
                    TGSTR=${FILESTR[$EDITION]}-windows-${CSTR}-${TARGET}-${ARCHCPU}
                    ${MAKE} -f ${MAKEFILE} clean OS=${OS} YANEURAOU_EDITION=${EDITION}
                    nice ${MAKE} -f ${MAKEFILE} -j${JOBS} ${TARGET} OS=${OS} TARGET_CPU=${ARCHCPU} YANEURAOU_EDITION=${EDITION} COMPILER=${COMPILER} DEBUG=${DEBUG} > >(tee ${BUILDDIR}/${TGSTR}.log) || exit $?
                    cp YaneuraOu-by-gcc.exe ${BUILDDIR}/${TGSTR}.exe
                    ${MAKE} -f ${MAKEFILE} clean OS=${OS} YANEURAOU_EDITION=${EDITION}
                    break
                  fi
                done
              done
            fi
          done
        done
        break
      fi
    done
  done
done

popd
popd
