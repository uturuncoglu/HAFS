#!/bin/ksh

set -xe

TOTAL_TASKS=${TOTAL_TASKS:-144}
NCTSK=${NCTSK:-24}
NCNODE=${NCNODE:-24}
OMP_NUM_THREADS=${OMP_NUM_THREADS:-1}
APRUNS=${APRUNS:-"aprun -b -j1 -n1 -N1 -d1 -cc depth"}
APRUNF=${APRUNF:-"aprun -b -j1 -n${TOTAL_TASKS} -N${NCTSK} -d${OMP_NUM_THREADS} -cc depth cfp"}
APRUNC=${APRUNC:-"aprun -b -j1 -n${TOTAL_TASKS} -N${NCTSK} -d${OMP_NUM_THREADS} -cc depth"}

export MP_LABELIO=yes

CDATE=${CDATE:-${YMDH}}
NHRS=${NHRS:-126}
NOUTHRS=${NOUTHRS:-3}

MPISERIAL=${MPISERIAL:-mpiserial}
NDATE=${NDATE:-ndate}
WGRIB2=${WGRIB2:-wgrib2}
GRB2INDEX=${GRB2INDEX:-grb2index}

WORKhafs=${WORKhafs:-/gpfs/hps3/ptmp/${USER}/${SUBEXPT}/${CDATE}/${STORMID}}
COMhafs=${COMhafs:-/gpfs/hps3/ptmp/${USER}/${SUBEXPT}/com/${CDATE}/${STORMID}}
SENDCOM=${SENDCOM:-YES}

output_grid=${output_grid:-rotated_latlon}
synop_gridspecs=${synop_gridspecs:-"latlon 246.6:4112:0.025 -2.4:1976:0.025"}
trker_gridspecs=${trker_gridspecs:-"latlon 246.6:4112:0.025 -2.4:1976:0.025"}
out_prefix=${out_prefix:-$(echo "${STORM}${STORMID}.${YMDH}" | tr '[A-Z]' '[a-z]')}

DATA=${DATA:-${WORKhafs}/graphics}

IFHR=0
FHR=0
FHR2=$( printf "%02d" "$FHR" )
FHR3=$( printf "%03d" "$FHR" )

# Loop for forecast hours
while [ $FHR -le $NHRS ];
do

cd ${DATA}

NEWDATE=`${NDATE} +${FHR3} $CDATE`
YYYY=`echo $NEWDATE | cut -c1-4`
MM=`echo $NEWDATE | cut -c5-6`
DD=`echo $NEWDATE | cut -c7-8`
HH=`echo $NEWDATE | cut -c9-10`

FMIN=$(( ${FHR}*60 )) 
minstr=$( printf "%5.5d" "$FMIN" )

synop_grb2graphics=hafsprs.${CDATE}.f${FHR3}.grb2
synop_grb2file=${out_prefix}.hafsprs.synoptic.0p03.f${FHR3}.grb2
synop_grb2indx=${out_prefix}.hafsprs.synoptic.0p03.f${FHR3}.grb2.idx
gmodname=hafs
rundescr=trak
atcfdescr=storm
hafstrk_grb2file=${gmodname}.${rundescr}.${atcfdescr}.${CDATE}.f${minstr}
hafstrk_grb2indx=${gmodname}.${rundescr}.${atcfdescr}.${CDATE}.f${minstr}.ix

# Check if graphics has processed this forecast hour previously
if [ -s ${INPdir}/graphicsf${FHR3} ] && [ -s ${COMhafs}/${synop_grb2file} ] && [ -s ${COMhafs}/${synop_grb2indx} ] ; then

echo "graphics message ${INPdir}/graphicsf${FHR3} exist"
echo "product ${COMhafs}/${synop_grb2file} exist"
echo "product ${COMhafs}/${synop_grb2indx} exist"
echo "skip graphics for forecast hour ${FHR3} valid at ${NEWDATE}"

# Otherwise run graphics for this forecast hour
else

# Wait for model output
n=1
while [ $n -le 600 ]
do
  if [ ! -s ${INPdir}/logf${FHR3} ] || [ ! -s ${INPdir}/dynf${FHR3}.nc ] || [ ! -s ${INPdir}/phyf${FHR3}.nc ]; then
    echo "${INPdir}/logf${FHR3} not ready, sleep 60"
    sleep 60s
  else
    echo "${INPdir}/logf${FHR3}, ${INPdir}/dynf${FHR3}.nc ${INPdir}/phyf${FHR3}.nc ready, do graphics"
    sleep 3s
    break
  fi
  n=$(( n+1 ))
done

# Create the graphics working dir for the time level
DATA_graphics=${DATA}/graphics_${NEWDATE}
rm -rf ${DATA_graphics}
mkdir -p ${DATA_graphics}
cd ${DATA_graphics}

# Deliver to COMhafs
if [ $SENDCOM = YES ]; then
  mv ${synop_grb2file} ${COMhafs}/
  mv ${synop_grb2indx} ${COMhafs}/
fi

# Check if the products are missing
if [ ! -s ${intercom}/${hafstrk_grb2file} ]; then
  echo "ERROR: intercom product ${intercom}/${hafstrk_grb2file} not exist"
  echo "ERROR: graphics for hour ${FHR3} valid at ${NEWDATE} exitting"
  exit 1
fi
if [ ! -s ${intercom}/${hafstrk_grb2indx} ] ; then
  echo "ERROR: intercom product ${intercom}/${hafstrk_grb2indx} not exist"
  echo "ERROR: graphics for hour ${FHR3} valid at ${NEWDATE} exitting"
  exit 1
fi

# Write out the graphicsdone message file
echo 'done' > ${INPdir}/graphicsf${FHR3}

cd ${DATA}

fi
# End if for checking if graphics has processed this forecast hour previously

IFHR=`expr $IFHR + 1`
FHR=`expr $FHR + $NOUTHRS`
FHR2=$( printf "%02d" "$FHR" )
FHR3=$( printf "%03d" "$FHR" )

done
# End loop for forecast hours

echo "graphics job done"

exit
