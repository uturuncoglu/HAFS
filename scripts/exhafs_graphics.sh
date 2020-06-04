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

# GPLOT-specific variables (might go elsewhere)
GPLOT_PARSE="${GPLOThafs}/shell/parse_atcf.sh"
GPLOT_WRAPPER="${GPLOThafs}/shell/GPLOT_wrapper.sh"
GPLOT_ARCHIVE="${GPLOThafs}/archive/GPLOT_tarballer.sh"

# Setup the working directory and change into it
DATA=${DATA:-${WORKhafs}/graphics}
mkdir -p ${DATA}
cd ${DATA}

# Copy and edit the GPLOT namelist
NML=${DATA}/namelist.master.${SUBEXPT}
if [ ! -f ${NML} ];
then
    cp -p ${GPLOThafs}/nmlist/namelist.master.HAFS_Default ${NML}
fi
sed -i 's/^EXPT =.*/EXPT = '"${SUBEXPT}"'/g' ${NML}
sed -i 's/^IDATE =.*/IDATE = '"${CDATE}"'/g' ${NML}
sed -i 's/^INIT_HR =.*/INIT_HR = 0/g' ${NML}
sed -i 's/^FNL_HR =.*/FNL_HR = '"${NHRS}"'/g' ${NML}
sed -i 's@^IDIR =.*@IDIR = '"${COMhafs}"'@g' ${NML}
sed -i 's@^ODIR =.*@ODIR = '"${DATA}"'@g' ${NML}
sed -i 's@^ATCF1_DIR =.*@ATCF1_DIR = '"${COMhafs}"'@g' ${NML}
sed -i 's@^ATCF2_DIR =.*@ATCF2_DIR = '"${COMhafs}"'@g' ${NML}
sed -i 's@^ADECK_DIR =.*@ADECK_DIR = '"${ADECKhafs}"'@g' ${NML}
sed -i 's@^BDECK_DIR =.*@BDECK_DIR = '"${BDECKhafs}"'@g' ${NML}
sed -i 's/^SYS_ENV =.*/SYS_ENV = '"$( echo ${machine} | tr "[a-z]" "[A-Z]")"'/g' ${NML}
sed -i 's/^BATCH_MODE =.*/BATCH_MODE = Background/g' ${NML}

# Initialize ALL_COMPLETE as false 
ALL_COMPLETE=0

# Loop for forecast hours
while [[ ${ALL_COMPLETE} -eq 0 ]];
do
    echo "Top of loop"

    # Find and parse the ATCF file into an individual file for each storm
    # Need to know the bdeck staging directory. Could use GJA's.
    ${GPLOT_PARSE} HAFS ${COMhafs} ${COMhafs} ${BDECKhafs} ${SYNDAThafs} 4
    
    # Check the status files for all GPLOT components.
    GPLOT_STATUS=( `find ${DATA}/. -name "status.*" -exec cat {} \;` )
    ALL_COMPLETE=1
    if [ ! -z "${GPLOT_STATUS[*]}" ];
    then
        for GS in ${GPLOT_STATUS[@]};
        do
            if [ ${GS} != "complete" ]; then
                ALL_COMPLETE=0
            fi
        done
    else
        ALL_COMPLETE=0
    fi

    # If all are complete, then exit with success!
    # If not, submit the GPLOT wrapper again.
    if [[ ${ALL_COMPLETE} -eq 1 ]];
    then
        echo "All status files were found to read 'complete.' That means we're done!"
        break
    else
        echo "Waiting for all status files to read 'complete'. Trying again..."
    fi
    
    # Call the GPLOT wrapper
    ${GPLOT_WRAPPER} ${NML} &
    
    # Now sleep for 15 min
    echo "sleeping 900 seconds..."
    sleep 900s

done

# Now that everything is complete, move all graphics to the $COMhafs directory.
cp -rp ${DATA} ${COMhafs}/graphics

# Zip up and move contents to the tape archive. Local scrubbing optional.
# This is experimental and turned OFF for now.
GPLOT_DOARCH="NO"
if [ "${GPLOT_DOARCH}" == "YES" ];
then
    ${GPLOT_ARCHIVE} ${SUBEXPT} ${DATA} /5year/HFIP/hur-aoml/Ghassan.Alaka/GPLOT ${CDATE} NO NO
fi

echo "graphics job done"

exit
