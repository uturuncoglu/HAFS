"""
SCRIPT:   

   date_time_format.py

AUTHOR: 

   Henry R. Winterbottom; 22 March 2019

ABSTRACT:

   (1) DateTimeAttributes: This is the base-class object for all date
       and timestamp manipulations relative to the user
       specifications.

   (2) DateTimeOptions: This is the base-class object to parse all
       user specified options passed to the driver level of the
       script.

   * main; This is the driver-level method to invoke the tasks within
     this script.

USAGE:

   python date_time_format.py --date_string <analysis date> \
     --offset_seconds <total number of seconds relative to analysis date \
     for which to determine date and time attributes> --output_file \
     <path to external file to write results>

NOTE:

   * Both the <offset_seconds> and <output_file> arguments are
     optional; they default to a value of 0 and
     'date_time_format.output', respectively.

HISTORY:

   2019-03-22: Henry R. Winterbottom -- Initial implementation.

"""

#----

import argparse
import datetime
import os
import sqlite3
import sys

#----

__author__ = "Henry R. Winterbottom"
__copyright__ = "2019 Henry R. Winterbottom, NOAA/NCEP/EMC"
__version__ = "1.0.0"
__maintainer__ = "Henry R. Winterbottom"
__email__ = "henry.winterbottom@noaa.gov"
__status__ = "Development"

#----

class DateTimeAttributes(object):
    """
    DESCRIPTION:

    This is the base-class object for all date and timestamp
    manipulations relative to the user specifications.

    INPUT VARIABLES:

    * opts_obj; a Python object containing the user command line
      options.

    """
    def __init__(self,opts_obj):
        """ 
        DESCRIPTION:
        
        Creates a new DateTimeAttributes object.

        """
        self.opts_obj=opts_obj
        self.datestr=getattr(self.opts_obj,'date_string')
        self.offset_seconds=getattr(self.opts_obj,'offset_seconds')
        self.dateobj=datetime.datetime.strptime(self.datestr,'%Y%m%d%H')+\
            datetime.timedelta(0,self.offset_seconds)
        self.datetime_obj=lambda:None
        self.obj_keys_list=list()
    def datecomps(self):
        """
        DESCRIPTION:

        This method determines the date and time attributes with
        respect to the data and time attributes provided by the user.

        """
        date_comps_dict={'year':'%Y','month':'%m','day':'%d','hour':'%H',\
            'minute':'%M','second':'%S','month_name_long':'%B','month_name_short':\
            '%b','weekday_long':'%A','weekday_short':'%a','date_string':\
            '%Y-%m-%d_%H:%M:%S','cycle':'%Y%m%d%H'}        
        for key in date_comps_dict.keys():
            self.obj_keys_list.append(key)
            value=datetime.datetime.strftime(self.dateobj,date_comps_dict[key])
            setattr(self.datetime_obj,key,value)
    def infowrite(self):
        """
        DESCRIPTION:

        This method writes the date and time attribute diagnostics to
        the user specified output file.

        """
        with open(getattr(self.opts_obj,'output_file'),'wt') as f:
            for item in self.obj_keys_list:
                value=getattr(self.datetime_obj,item)
                f.write('%s %s\n'%(item,value))
    def julianday(self):
        """
        DESCRIPTION:

        This method utilizes the attributes within the Python SQLite3
        module to determine the Julian date with respect to the date
        and time attributes provided by the user.

        """
        connect=sqlite3.connect(':memory:')
        datestr='%s-%s-%s %s:%s:%s'%(getattr(self.datetime_obj,'year'),\
            getattr(self.datetime_obj,'month'),getattr(self.datetime_obj,'day'),\
            getattr(self.datetime_obj,'hour'),getattr(self.datetime_obj,'minute'),\
            getattr(self.datetime_obj,'second'))
        value=list(connect.execute('select julianday("%s")'%datestr))[0][0]
        setattr(self.datetime_obj,'julian_day',value)
        self.obj_keys_list.append('julian_day')
    def run(self):
        """
        DESCRIPTION:

        This method performs the following tasks:

        (1) Determines the time and date attributes with respect to
        the user specifications.

        (2) Computes the Julian date with respect to the user specifications.

        (3) Writes the date and time attribute diagnostics to the user
        specified output file.

        """
        self.datecomps()
        self.julianday()
        self.infowrite()

#----

class DateTimeOptions(object):
    """
    DESCRIPTION:

    This is the base-class object to parse all user specified options
    passed to the driver level of the script.

    """
    def __init__(self):
        """ 
        DESCRIPTION:

        Creates a new DateTimeOptions object.

        """
        self.parser=argparse.ArgumentParser()
        self.parser.add_argument('-d','--date_string',help='The base date '\
            'string about which to manipulate; format is %Y%m%d%H%M%S.',\
            default=None)
        self.parser.add_argument('-ofs','--offset_seconds',help='The total '\
            'number of seconds, relative to the base date string, for which '\
            'to manipulate and define the output date string attributes.',\
            default=0)
        self.parser.add_argument('-out','--output_file',help='The output file '\
            'to write the resultant diagnostics.',default=\
            'date_time_format.output')
        self.opts_obj=lambda:None
    def run(self):
        """
        DESCRIPTION:

        This method collects the user-specified command-line
        arguments; the available command line arguments are as
        follows:

        -d; the base date string about which to manipulate; format is
            (assuming UNIX standard) %Y%m%d%H%M%S.

        -ofs; the total number of seconds, relative to the base data
              string, for which to manipulate and define the output
              date string attributes.
        
        -out; The output file to write the resultant diagnostics.

        """
        opts_obj=self.opts_obj
        args_list=['date_string','offset_seconds','output_file']
        args=self.parser.parse_args()
        for item in args_list:
            value=getattr(args,item)
            if item=='offset_seconds':
                value=int(value)
            setattr(opts_obj,item,value)
        return opts_obj

#----

def main():
    """
    DESCRIPTION:

    This is the driver-level method to invoke the tasks within this
    script.

    """
    options=DateTimeOptions()
    opts_obj=options.run()
    datetimeattrbs=DateTimeAttributes(opts_obj=opts_obj)
    datetimeattrbs.run()

#----

if __name__=='__main__':
    main()


