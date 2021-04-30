#!/bin/bash
set -eu

#cd to location of script
MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)

usage () {
  echo "Usage: "
  echo "  $0 PLATFORM COMPILER"
  echo ""
  echo "PLATFORM: Name of machine you are building on"
  echo "COMPILER: (optional) compiler to use; valid options are 'intel', 'gnu'"
  echo ""
  echo "NOTE: This script is for internal developer use only;"
  echo "See User's Guide for detailed build instructions"
}

PLATFORM="${1:-NONE}"
COMPILER="${2:-intel}"


if [ $# -lt 1 ]; then 
  echo "ERROR: not enough arguments"
  usage
  exit 1
fi
if [ $# -gt 2 ]; then
  echo "ERROR: too many arguments"
  usage
  exit 1
fi

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then 
  usage
  exit 0
fi

ENV_FILE="env/build_${PLATFORM}_${COMPILER}.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: environment file ($ENV_FILE) does not exist for this platform/compiler combination"
  echo "PLATFORM=$PLATFORM"
  echo "COMPILER=$COMPILER"
  echo ""
  echo "See User's Guide for detailed build instructions"
  exit 64
fi

# If build directory already exists, offer a choice
BUILD_DIR=${MYDIR}/build

if [ -d "${BUILD_DIR}" ]; then
  while true; do
    echo "Build directory (${BUILD_DIR}) already exists! Please choose what to do:"
    echo ""
    echo "[R]emove the existing directory"
    echo "[C]ontinue building in the existing directory"
    echo "[Q]uit this build script"
    read -p "Choose an option (R/C/Q):" choice
    case $choice in
      [Rr]* ) rm -rf ${BUILD_DIR}; break;;
      [Cc]* ) break;;
      [Qq]* ) exit;;
      * ) echo "Invalid option selected.\n";;
    esac
  done
fi

# Source the README file for this platform/compiler combination, then build the code
. $ENV_FILE

mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
cmake .. -DCMAKE_INSTALL_PREFIX=..
make -j ${BUILD_JOBS:-4}

. ${MYDIR}/${ENV_FILE}_DA
cd ${BUILD_DIR}
mkdir -p build_gsi
cd build_gsi
cmake ${MYDIR}/src/gsi -DBUILD_CORELIBS=ON -DCMAKE_INSTALL_PREFIX=.
make -j ${BUILD_JOBS:-4}
cp ./bin/gsi.x ${MYDIR}/bin/.

. ${MYDIR}/${ENV_FILE}_DA
cd ${BUILD_DIR}
mkdir -p build_rrfs_utl
cd build_rrfs_utl
cmake ${MYDIR}/src/rrfs_utl -DCMAKE_INSTALL_PREFIX=.
make -j ${BUILD_JOBS:-4}
cp ./bin/* ${MYDIR}/bin/.

#building bufr sounding codes
# this could be made optional
cd ${MYDIR}/src/bufr_sounding
./build_bufr.sh
./build_sndp.sh
./build_stnmlist.sh
cp ${MYDIR}/src/bufr_sounding/regional_bufr.fd/regional_bufr.x ${MYDIR}/bin/.
cp ${MYDIR}/src/bufr_sounding/regional_sndp.fd/regional_sndp.x ${MYDIR}/bin/.
cp ${MYDIR}/src/bufr_sounding/regional_stnmlist.fd/regional_stnmlist.x ${MYDIR}/bin/.

exit 0
