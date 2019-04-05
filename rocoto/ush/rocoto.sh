#!/bin/ksh

################################################################################
#
# UNIX Script Documentation Block
#
# Script name:         rocoto.sh
#
# Script description:  This script prepares the necessary files for the
#                      Rocoto workflow manager in accordance with the
#                      user experiment configuration.
#
# Script history log:  2019-03-29  Henry Winterbottom -- Original version.
#
################################################################################

set -x -e

#----

# FUNCTION:

# _rdhpcs_jet_workflow.sh

# DESCRIPTION:

# This function defines the relevant environment variables for the
# NOAA RHPCS-Jet cluster.

_rdhpcs_jet_workflow (){

    # Define the host attributes entity file path (e.g., host.ent) for
    # the workflow.

    export HOSTent=${ROCOTOdir}/site/hosts/host.RDHPCS-Jet.ent

    # Define the platform attributes entity file path (e.g.,
    # platform.ent) for the workflow.

    export PLATFORMent=${ROCOTOdir}/site/platforms/platform.RDHPCS-Jet.ent

    # Define the path to the script containing the prerequisite
    # modules and environment variables for the workflow.

    export PREREQSscript=${HOMEdir}/util/rtf/rtf.RDHPCS-Jet.sh

}

#----

# FUNCTION:

# build_rocoto_filepath.sh

# DESCRIPTION:

# This function defines the file naming conventions for the Rocoto
# workflow in accordance with the user experiment configuration.

build_rocoto_filepaths (){

    # Check the user experiment configuration and proceed accordingly.

    if [ -z ${TCID+x} ]; then

	# Define the string to be used to create the necessary Rocoto
	# files.

	filestr="hafs-${EXPTname}-${CYCLEstart}"

    else # [ -z ${TCID+x} ]

	# Define the string to be used to create the necessary Rocoto
	# files.

	filestr="hafs-${EXPTname}-${TCID}-${CYCLEstart}"

    fi   # [ -z ${TCID+x} ]

    # Define Rocoto database file.

    export ROCOTOdbfilepath=${ROCOTOdir}/${filestr}.db

    # Define Rocoto workflow file.

    export ROCOTOwffilepath=${ROCOTOdir}/${filestr}.xml
	
    # Copy previous Rocoto database file to a backed-up version.

    cp ${ROCOTOdbfilepath} ${ROCOTOdbfilepath}.bak 2>/dev/null || :
}

#----

# FUNCTION:

# build_rocoto_workflow.sh

# DESCRIPTION:

# This function builds the Rocoto workflow file in accordance with the
# user experiment configuration.

build_rocoto_workflow (){

    # Configure workflow attributes for respective host machine.

    host_machine_config

    # Define the Rocoto workflow realtime status information.

    define_realtime

    # Define the Rocoto workflow cycledef information.

    define_cycledef

    # Define the Rocoto workflow logger information.

    define_logger

    # Initialize XML file for Rocoto workflow manager directives.

    cat <<EOF > ${ROCOTOwffilepath}
<?xml version="1.0"?>

<!DOCTYPE workflow [
 <!ENTITY % HOST     SYSTEM "${HOSTent}">
 <!ENTITY % PLATFORM SYSTEM "${PLATFORMent}">
 <!ENTITY % TASKS    SYSTEM "${ROCOTOdir}/tasks/tasks.ent">

 %HOST;
 %PLATFORM;
 %TASKS;

 <!ENTITY PRE "${PREREQSscript}">

]>
<workflow realtime="${REALTIME}" scheduler="&SCHEDULER;">
  <cycledef>${CYCLEDEF}</cycledef>
  <log><cyclestr>${LOGGER}</cyclestr></log>
  
EOF

    # Define launcher tasks and append to Rocoto workflow manager
    # file.

    task_launcher

    # Define bufrprep tasks and append to Rocoto workflow manager
    # file.

    task_bufrprep

    # Finalize XML file for Rocoto workflow manager directives.

    cat <<EOF >> ${ROCOTOwffilepath}
</workflow>
EOF
}

#----

# FUNCTION:

# define_cycledef.sh

# DESCRIPTION:

# This function defines the cycledef attribute for the Rocoto
# workflow.

define_cycledef (){

    # Define the start date for the workflow.

    cycle_start=${CYCLEstart}

    # Check whether user has specified a stop date for the workflow;
    # if not, assign the start and stop dates to be indentical.

    cycle_stop=${CYCLEstop:-${CYCLEstart}}

    # Check whether the user has defined the interval for successive
    # cycles within the workflow; if not, default to 6-hours.

    cycle_interval=${CYCLEinterval:-"06:00:00"}

    # Define the cycle definition string (e.g., cycledef) for the
    # Rocoto workflow manager.

    export CYCLEDEF="${cycle_start} ${cycle_stop} ${cycle_interval}"
}

#----

# FUNCTION:

# define_logger.sh

# DESCRIPTION:

# This function defines the logger file attributes in accordance with
# the user experiment configuration.

define_logger (){

    # Define path for Rocoto log files.

    logpath=${WORKdir}/${USER}/${EXPTname}/log

    # Create directory for Rocoto log files.

    mkdir -p ${logpath}

    # Check the user experiment configuration and proceed accordingly.

    if [ -z ${TCID+x} ]; then

	# Define the string to be used to create the necessary Rocoto
	# files.

	filestr="rocoto.@Y@m@d@H.log"

    else # [ -z ${TCID+x} ]

	# Define the string to be used to create the necessary Rocoto
	# files.

	filestr="rocoto_${TCID}.@Y@m@d@H.log"

    fi   # [ -z ${TCID+x} ]

    # Define the logger definition string for the Rocoto workflow
    # manager.

    export LOGGER=${logpath}/${filestr}
}

#----

# FUNCTION:

# define_realtime.sh

# DESCRIPTION:

# This function defines the realtime status for the Rocoto workflow
# based on the user experiment configuration.

define_realtime (){

    # Get the user forecast type (e.g., history or realtime)

    fcsttype=${FCSTtype}

    # Check the user forecast type and proceed accordingly.

    if [ ${fcsttype}=='history' ]; then

	export REALTIME=F

    else # if [ ${fcsttype}=='history' ]

	export REALTIME=T

    fi   # if [ ${fcsttype}=='history' ]
}

#----

# FUNCTION:

# host_machine_config.sh

# DESCRIPTION:

# This function configures the host machine environment relative to
# the respective (supportted) platform and host.

host_machine_config (){

    # Get host machine platform name.

    osname=`uname`

    # Get host machine name.

    hostname=`hostname`

    # If on a Linux platform, proceed accordingly.

    if [ ${osname}=='Linux' ]; then

	# Check whether running on the NOAA RDHPCS Jet cluster.

	if [[ ${hostname}==*"fe"* ]]; then

	    # Define all workflow related variables for the RDHPCS-Jet
	    # machine.

	    _rdhpcs_jet_workflow

	fi # [[ ${hostname}==*"fe"* ]]
 
    fi # if [ ${osname}=='Linux' ]

}

#----

# FUNCTION:

# launch_rocoto_workflow.sh

# DESCRIPTION:

# This function launches the Rocoto workflow manager.

launch_rocoto_workflow (){

    # Launch the Rocoto workflow manager.

    rocotorun --database ${ROCOTOdbfilepath} --workflow ${ROCOTOwffilepath}
}

#----

# FUNCTION:

# task_bufrprep.sh

# DESCRIPTION:

# This function writes the bufrprep task attributes to the Rocoto
# workflow manager file.

task_bufrprep (){

    # Write bufrprep task directives to Rocoto workflow manager file.

    cat <<EOF >> ${ROCOTOwffilepath}
  <!-- HAFS workflow bufrprep tasks -->
  <metatask name="meta_bufrprep" mode="parallel">
    <var name="ENS">99</var>
    &bufrprep_tasks;
  </metatask>
EOF
}

#----

# FUNCTION:

# task_launcher.sh

# DESCRIPTION:

# This function writes the launcher task attributes to the Rocoto
# workflow manager file.

task_launcher (){

    # Write launcher task directives to Rocoto workflow manager file.

    cat <<EOF >> ${ROCOTOwffilepath}
  <!-- HAFS workflow launch tasks -->
  <metatask name="meta_launch" mode="parallel">
    <var name="ENS">99</var>
    &launch_tasks;
  </metatask>
EOF
}

#----

script_name=`basename "$0"`
start_date=`date`
echo "START ${script_name}: ${start_date}"

# (1) Define Rocoto database and workflow file paths.

build_rocoto_filepaths

# (2) Build the Rocoto workflow manager file.

build_rocoto_workflow

# (3) Launch Rocoto workflow.

launch_rocoto_workflow

stop_date=`date`
echo "STOP ${script_name}: ${stop_date}"

exit
