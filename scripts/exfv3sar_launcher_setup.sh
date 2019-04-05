#!/bin/ksh

################################################################################
#
# UNIX Script Documentation Block
#
# Script name:         exfv3sar_launcher_setup.sh
#
# Script description:  This script generates builds the top-level
#                      directory paths for the user experiment,
#                      defines the forecast cycle time attributes, and
#                      constructs the environment variable source file
#                      used by the workflow scripts.
#
# Script history log:  2019-03-27  Henry Winterbottom -- Original version.
#
################################################################################

set -x -e

# Define environment for respective experiment.

. ${ROCOTOdir}/experiment.config

#----

# FUNCTION:

# build_experiment.sh

# DESCRIPTION:

# This function builds the top-level directories for the user
# experiment.

build_experiment (){

    # Define local variables

    export COMROOT=${WORKdir}/${USER}/${EXPTname}/com/${CYCLE}
    export EXPTROOT=${WORKdir}/${USER}/${EXPTname}/${CYCLE}
    export ITRCROOT=${EXPTROOT}/intercom

    # Create local sub-directories

    mkdir -p ${COMROOT}
    mkdir -p ${EXPTROOT}
    mkdir -p ${ITRCROOT}
}

#----

# FUNCTION:

# build_experiment_info.sh

# DESCRIPTION:

# This function constructs the external file used by all workflow
# scripts which contains all experiment environment variables.

build_experiment_info (){

    # Define external file to contain experiment configuration and
    # environment variables.

    export EXPTINFO_FILEPATH=${ITRCROOT}/experiment.${CYCLE}

    # Remove any previous occurances of external file.

    rm ${EXPTINFO_FILEPATH} 2> /dev/null || :

    # Append the user job environment file to external file.

    grep . $HOMEdir/jobs/JFV3SAR_ENVIR >> ${EXPTINFO_FILEPATH}
    grep . $PARMdir/configure.experiment >> ${EXPTINFO_FILEPATH}

    # Write environment variables to external file.

    echo "export COMROOT=${COMROOT}" >> ${EXPTINFO_FILEPATH}
    echo "export EXPTROOT=${EXPTROOT}" >> ${EXPTINFO_FILEPATH}
    echo "export ITRCROOT=${ITRCROOT}" >> ${EXPTINFO_FILEPATH}
    echo "export TIMEINFO_FILEPATH=${TIMEINFO_FILEPATH}" >> ${EXPTINFO_FILEPATH}
    echo "export TCV_TIMESTAMP='${TCV_TIMESTAMP}'" >> ${EXPTINFO_FILEPATH}
    echo "export TCEVENT='${TCEVENT}'" >> ${EXPTINFO_FILEPATH}
}

#----

# FUNCTION:

# cycle_timeinfo.sh

# DESCRIPTION:

# This function defines the time and date information corresponding to
# the forecast cycle.

cycle_timeinfo (){

    # Define external file to contain forecast cycle date and time
    # information.

    export TIMEINFO_FILEPATH=${ITRCROOT}/cycle.timeinfo

    # Create external file containing time-stamp attributes.

    python ${USHdir}/date_time_format.py --date_string ${CYCLE} --output_file ${TIMEINFO_FILEPATH}

    # Define forecast cycle time stamp attributes.

    year=`cat ${TIMEINFO_FILEPATH} | grep -w "year" | awk '{print $2}'`
    month=`cat ${TIMEINFO_FILEPATH} | grep -w "month" | awk '{print $2}'`
    day=`cat ${TIMEINFO_FILEPATH} | grep -w "day" | awk '{print $2}'`
    hour=`cat ${TIMEINFO_FILEPATH} | grep -w "hour" | awk '{print $2}'`
    
    # Define time stamp search string for TC-vitals records.
    
    export TCV_TIMESTAMP="${year}${month}${day} ${hour}00"
}

#----

# FUNCTION:

# define_experiment_configuration.sh

# DESCRIPTION:

# This function parses the user run-time environment to check whether
# a TC event has been specified; if one has not been specified, a
# value of NONE is return which implies to run the simulation for all
# tropical cyclones (TCs) within the TC-vitals record for the user
# specified cycle.

define_experiment_configuration (){

    # Define the tropical cyclone (TC) event the user has specified;
    # if not defined, assign a default value of 'NONE'.

    export TCEVENT=${TCID:-'NONE'}
}

#----

# FUNCTION:

# deliver_products.sh

# DESCRIPTION:

# This function copies (e.g., delivers) the relavant files to
# respective paths expected by the workflow.

deliver_products (){

    # Copy (e.g., deliver) relevant file to respective paths.

    cp ${EXPTINFO_FILEPATH} ${COMROOT}/`basename ${EXPTINFO_FILEPATH}`
    cp ${TIMEINFO_FILEPATH} ${COMROOT}/`basename ${TIMEINFO_FILEPATH}`
}

#----

script_name=`basename "$0"`
start_date=`date`
echo "START ${script_name}: ${start_date}"

# The following tasks are accomplished by this script:

# (1) Build the top-level directory paths for the user experiment.

build_experiment

# (2) Define the forecast cycle time information; this information is
#     used by the subsequent function calls to parse and create the
#     necessary files for the workflow.

cycle_timeinfo

# (3) Define the experiment configuration (e.g., is this experiment
#     configured to run a single TC event or configured to run for all
#     events within the current cycle TC-vitals.).

define_experiment_configuration

# (4) Build external file containing all environment variables for
#     user experiment.

build_experiment_info

# (5) Deliver the relevant files to the respective /intercom and /com
#     paths.

deliver_products

stop_date=`date`
echo "STOP ${script_name}: ${stop_date}"

exit
