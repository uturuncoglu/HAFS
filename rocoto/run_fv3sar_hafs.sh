#!/bin/ksh

################################################################################
#
# UNIX Script Documentation Block
#
# Script name:         run_fv3sar_hafs.sh
#
# Script description:  This script is the driver script to launch the Cubed-
#                      Sphere Finite Volume (FV3) Stand-alone Regional (SAR)
#                      application for the Hurricane Analysis and Forecasting
#                      System (HAFS).
#
# Script history log:  2019-03-28  Henry Winterbottom -- Original version.
#
################################################################################

set -x -e

. $HOMEdir/jobs/HAFS/JFV3SAR_ENVIR

#----

# Get command line argument containing the user experiment
# configuration.

exptconfig=$1

#----

# USERS: DO NOT MAKE MODIFICATIONS BELOW THIS LINE!

# Define the user experiment configuration and prepare for Rocoto
# interface.

. ${exptconfig}

# Run the Rocoto workflow management system.

# Reference: https://github.com/christopherwharrop/rocoto/wiki/documentation

${ROCOTOdir}/ush/rocoto.sh



