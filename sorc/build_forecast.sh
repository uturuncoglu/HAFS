#! /usr/bin/env bash
set -eux

source ./machine-setup.sh > /dev/null 2>&1
cwd=`pwd`

USE_PREINST_LIBS=${USE_PREINST_LIBS:-"true"}
if [ $USE_PREINST_LIBS = true ]; then
  export MOD_PATH=/scratch3/NCEPDEV/nwprod/lib/modulefiles
else
  export MOD_PATH=${cwd}/lib/modulefiles
fi

# Check final exec folder exists
if [ ! -d "../exec" ]; then
  mkdir ../exec
fi

if [ $target = hera ]; then target=hera.intel ; fi
if [ $target = orion ]; then target=orion.intel ; fi
if [ $target = jet ]; then target=jet.intel ; fi
if [ $target = wcoss_cray ]; then module load python/2.7.14; fi

cd hafs_forecast.fd/
FV3=$( pwd -P )/FV3
cd tests/
#./compile.sh "$FV3" "$target" "CCPP=Y STATIC=Y SUITES=HAFS_v0_gfdlmp_nocpnsstugwd,HAFS_v0_gfdlmp_nocpnsst,HAFS_v0_gfdlmp_nocp,HAFS_v0_gfdlmp_nougwd,HAFS_v0_gfdlmp_nocpugwd,HAFS_v0_gfdlmp,HAFS_v0_hwrf_nougwd,HAFS_v0_hwrf 32BIT=Y HYCOM=Y CMEPS=Y" 32bit YES NO
#./compile.sh "$FV3" "$target" "CCPP=Y STATIC=Y SUITES=HAFS_v0_gfdlmp_nocpnsstugwd,HAFS_v0_gfdlmp_nocpnsst,HAFS_v0_gfdlmp_nocp,HAFS_v0_gfdlmp_nougwd,HAFS_v0_gfdlmp_nocpugwd,HAFS_v0_gfdlmp,HAFS_v0_hwrf_nougwd,HAFS_v0_hwrf 32BIT=Y HYCOM=Y CMEPS=Y CDEPS=Y" 32bit YES NO
#./compile.sh "$FV3" "$target" "CCPP=Y STATIC=Y SUITES=HAFS_v0_gfdlmp_nocpnsstugwd,HAFS_v0_gfdlmp_nocpnsst,HAFS_v0_gfdlmp_nocp,HAFS_v0_gfdlmp_nougwd,HAFS_v0_gfdlmp_nocpugwd,HAFS_v0_gfdlmp,HAFS_v0_hwrf_nougwd,HAFS_v0_hwrf 32BIT=Y HYCOM=Y CMEPS=Y CDEPS=Y" 32bit NO NO
#./compile.sh "$FV3" "$target" "DATM=Y DOCN=Y REPRO=Y 32BIT=Y CMEPS=Y CDEPS=Y" 32bit YES NO
#./compile.sh "$FV3" "$target" "CCPP=Y REPRO=Y 32BIT=Y HYCOM=Y" 32bit YES NO
#./compile.sh "$FV3" "$target" "CCPP=Y 32BIT=Y HYCOM=Y" 32bit YES NO
#cp -p fv3_32bit.exe ../NEMS/exe/
#cp -p fv3_32bit.exe ../../../exec/hafs_forecast.exe

# configuration for data components
# 1. data atmosphere and data ocean
#./compile.sh "$FV3" "$target" "DATM=Y DOCN=Y REPRO=Y 32BIT=Y CMEPS=Y CDEPS=Y" 32bit YES NO
# 2. data atmosphere + active hycom
./compile.sh "$FV3" "$target" "DATM=Y HYCOM=Y REPRO=Y 32BIT=Y CMEPS=Y CDEPS=Y" 32bit YES NO
# 3. active FV3 and data ocean
#./compile.sh "$FV3" "$target" "FV3=Y DOCN=Y CCPP=Y STATIC=Y SUITES=HAFS_v0_gfdlmp_nocpnsstugwd,HAFS_v0_gfdlmp_nocpnsst,HAFS_v0_gfdlmp_nocp,HAFS_v0_gfdlmp_nougwd,HAFS_v0_gfdlmp_nocpugwd,HAFS_v0_gfdlmp,HAFS_v0_hwrf_nougwd,HAFS_v0_hwrf REPRO=Y 32BIT=Y CMEPS=Y CDEPS=Y" 32bit YES NO
