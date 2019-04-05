#!/bin/ksh

################################################################################
#
# UNIX Script Documentation Block
#
# Script name:         exfv3sar_bufrprep_givuvtdr.sh
#
# Script description:  This script generates a Binary Universal Format
#                      (BUFR) file containing the NOAA/AOML/HRD G-IV
#                      reconnaisance tail-Doppler radar (TDR) u- and
#                      v-wind observations.
#
# Script history log:  2019-03-26  Henry Winterbottom -- Original version.
#
################################################################################

set -x

# Define environment for respective experiment.

. ${WORKdir}/${USER}/${CYCLE}/intercom/experiment.${CYCLE}

#----

# FUNCTION:

# format_observation_files.sh

# DESCRIPTION:

# This function determines the valid observation time for each
# available observation file and creates an external file to be used
# to create the PREPBUFR-formatted observation file.

format_observation_files (){

    # Create working directory for G-IV tail-Doppler radar (TDR) u-
    # and v-wind observations.

    mkdir -p ${BUFRPREPdir}/givtdruv/obs

    # Copy all available observation files to current working
    # directory.

    cp ${G4TDRUVdatapath}/*_xy.nc ${BUFRPREPdir}/givtdruv/obs/

    # Move to directory containing observations.

    cd ${BUFRPREPdir}/givtdruv/obs

    # Create a list of observation files.

    filenames=`ls ${BUFRPREPdir}/givtdruv/obs`

    # Remove any previous occurrances of external file list.

    rm ${BUFRPREPdir}/givtdruv/givtdruv.filelist

    # Loop through all file names and retrieve time-stamp information.

    for filename in ${filenames}; do

	# Define the reference time stamp.

	refdate=`ncdump -h ${filename} | grep "seconds since" | awk '{print $5}' | sed 's/-//g'`
	refdate=${refdate}00

	# Define the offset number of seconds relative to the
	# reference time stamp.

	offset_seconds=`ncdump -v time ${filename} | grep "time" | tail -1 | awk '{print $3}'`
	
	# Create external file containing time-stamp attributes.

	python ${USHdir}/date_time_format.py --date_string ${refdate} --offset_seconds ${offset_seconds} --output_file ${BUFRPREPdir}/givtdruv/obs/${filename}.timeinfo

	# Define observation valid time date string.

	date_string=`cat ${BUFRPREPdir}/givtdruv/obs/${filename}.timeinfo | grep "date_string" | awk '{print $2}'`

	# Update external file list.

	echo "${date_string} ${BUFRPREPdir}/givtdruv/obs/${filename}" >> ${BUFRPREPdir}/givtdruv/givtdruv.filelist

    done # for filename in ${filenames}
}    

#----

# FUNCTION:

# deliver_products.sh

# DESCRIPTION:

# This function copies (e.g., delivers) the relavant files to
# respective paths expected by the workflow.

deliver_products (){

    # Create directories to which to deliver products.

    mkdir -p ${COMROOT}/bufrprep
    mkdir -p ${ITRCROOT}/bufrprep

    # Copy (e.g., deliver) relevant file to respective paths.

    cp ${BUFRPREPdir}/givtdruv/prepbufr.givtdruv ${COMROOT}/bufrprep
    cp ${BUFRPREPdir}/givtdruv/prepbufr.givtdruv ${ITRCROOT}/bufrprep
}

#----

# FUNCTION:

# run_obs_to_bufr.sh

# DESCRIPTION:

# This function launches the executable to format the G-IV TDR u- and
# v-wind observations within a PREPBUFR-formatted file.

run_obs_to_bufr (){

    # Create external file containing time-stamp attributes.

    python ${USHdir}/date_time_format.py --date_string ${CYCLE} --output_file ${BUFRPREPdir}/givtdruv/cycle.info

    # Define analysis date relative to which to define observation
    # times.

    analdate=`cat ${BUFRPREPdir}/givtdruv/cycle.info | grep 'date_string' | awk '{print $2}'`

    # Define environment variables.

    export ANALDATE=${analdate}
    export RUNPATH=${BUFRPREPdir}/givtdruv
    export IS_GIVTDRUV=T
    export BUFR_TBLPATH=${G4TDRUVprepbufrtbl_filepath}
    export GIVTDRUV_BUFR_INFO_FILEPATH=${G4TDRUVbufrinfo_filepath}
    export GIVTDRUV_OBS_FILEPATH=${BUFRPREPdir}/givtdruv/givtdruv.filelist

    # Create PREPBUFR-formatted file for G-IV TDR u- and v-wind
    # observations.

    ${SCRIPTdir}/exfv3sar_bufrprep_obstobufr.sh
}

#----

script_name=`basename "$0"`
start_date=`date`
echo "START ${script_name}: ${start_date}"

# The following tasks are accomplished by this script:

# (1) Define local sub-directories.

export BUFRPREPdir=${EXPTROOT}/bufrprep

# (2) Format relevant observation files.

format_observation_files

# (3) Create the PREPBUFR formatted file containing the G-IV TDR u-
#     and v-wind sonde observations.

run_obs_to_bufr

# (4) Deliver the relevant files to the respective /intercom and /com
#     paths.

deliver_products

stop_date=`date`
echo "STOP ${script_name}: ${stop_date}"

exit
