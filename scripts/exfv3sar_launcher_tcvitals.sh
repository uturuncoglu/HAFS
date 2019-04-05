#!/bin/ksh

################################################################################
#
# UNIX Script Documentation Block
#
# Script name:         exfv3sar_launcher_tcvitals.sh
#
# Script description:  This script generates the TC-vitals files for
#                      the current forecast cycle (in accordance with
#                      the user experiment configuration) as well as
#                      the TC-vitals history records for all TC events
#                      to be simulated.
#
# Script history log:  2019-03-27  Henry Winterbottom -- Original version.
#
################################################################################

set -x -e

# Define environment for respective experiment.

. ${WORKdir}/${USER}/${EXPTname}/${CYCLE}/intercom/experiment.${CYCLE}

#----

# FUNCTION:

# parse_tcv_records.sh

# DESCRIPTION:

# This function collects TC-vitals records in accordance with the user
# experiment configuration.

parse_tcv_records (){

    # Define external file to contain TC-vitals records for events in
    # accordance with the user experiment configuration.

    export TCV_RECORD_FILEPATH=${ITRCROOT}/tcvitals.${CYCLE}

    # Remove previous occurance of external file.

    rm ${TCV_RECORD_FILEPATH} 2> /dev/null || :

    # Parse TC-vitals records relative to the experiment configuraiton
    # for the user specified forecast cycle.

    tcv_record

    # Create a TC-vitals records history files for the respective TC
    # events within the current forecast cycle.

    tcv_record_history
}

#----

# FUNCTION:

# tcv_record.sh

# DESCRIPTION:

# This function collects the TC-vitals records for the user specified
# current forecast cycle in accordance with the user experiment
# configuration.

tcv_record (){

    # Check local variable and proceed accordingly

    if [ "${TCEVENT}" == "NONE" ]; then

	# Parse TC-vitals records relative to the user specified
	# forecast cycle only.

	python ${USHdir}/tcv_format.py --cycle ${CYCLE} --output_file ${TCV_RECORD_FILEPATH} --rename True --renumber True --unrenumber True

    else # if [ "${TCEVENT}" == "NONE" ]

	# Parse TC-vitals records relative to the user specified
	# forecast cycle and TC event.

	python ${USHdir}/tcv_format.py --cycle ${CYCLE} --tcvid ${TCEVENT} --output_file ${TCV_RECORD_FILEPATH} --rename True --renumber True --unrenumber True	
    fi   # if [ "${TCEVENT}" == "NONE" ]
}

#----

# FUNCTION:

# tcv_record_history.sh

# DESCRIPTION:

# This function collects all previous TC-vitals records for the user
# specified TC event.

tcv_record_history (){

    # Define file path to contain a list of the TC-vitals events for
    # the current forecast cycle.

    export TCV_EVENTS_FILEPATH=${ITRCROOT}/tcevents.${CYCLE}.info

    # Write all TC-vitals events for the current forecast cycle to an
    # external file.

    cat ${TCV_RECORD_FILEPATH} | grep -w "${TCV_TIMESTAMP}" | awk '{print $2}' | sort -u > ${TCV_EVENTS_FILEPATH}

    # Define the year for the respective experiment.

    year=`cat ${ITRCROOT}/cycle.timeinfo | grep -w "year" | awk '{print $2}'`

    # Loop through all TC events for current cycle and create a
    # composite TC-vitals history file for each event.
    
    while read -r tcv_event; do

	# Define history file for TC event TC-vitals records.
    
	history_file=${ITRCROOT}/tcvitals.${tcv_event}.${CYCLE}.history

	# Collect the TC-vitals history for the respective TC event.

	python ${USHdir}/tcv_format.py --year ${year} --tcvid ${tcv_event} --output_file ${history_file} --rename True --renumber True --unrenumber True --windthresh 1

    done < ${TCV_EVENTS_FILEPATH}
}

#----

script_name=`basename "$0"`
start_date=`date`
echo "START ${script_name}: ${start_date}"

# The following tasks are accomplished by this script:

# (1) Create local sub-directories.

export LAUNCHERdir=${EXPTROOT}

# (2) Parse the TC-vitals record and collect all information in
#     accordance with the user specified experiment configuration.

parse_tcv_records

stop_date=`date`
echo "STOP ${script_name}: ${stop_date}"

exit
