"""
SCRIPT:   

   tcutil/__init__.py

AUTHOR: 

   Henry R. Winterbottom; 04 April 2019

ABSTRACT:

   This module initializes all modules within package tcutil.

HISTORY:

   2019-04-03: Bin Liu -- Initial implementation.  

   2019-04-04: Henry R. Winterbottom -- Updated modularity of scripts
               and made Python 3+ compliant.

"""

#----

import sys

#----

module_list=['constants',\
             'exceptions',\
             'numerics',\
             'revital',\
             'storminfo']
if sys.version_info<(3,0,0):
    for module in module_list:
        __import__('tcutil.%s'%module)
if sys.version_info>=(3,0,0):
    __all__=module_list
    from tcutil                             import *
