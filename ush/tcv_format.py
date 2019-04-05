"""
SCRIPT:   

   tcv_format.py

AUTHOR: 

   Henry R. Winterbottom; 04 April 2019

ABSTRACT:

   (1) TCVTools: This is the base-class object for all TC-vitals
       record manipulations relative to the user specifications.

   (2) TCVToolsError: This is the base-class for all exceptions; it is
       a sub-class of Exceptions.

   (3) TCVToolsOptions: This is the base-class object to parse all
       user specified options passed to the driver level of the
       script.

   * main; This is the driver-level method to invoke the tasks within
     this script.

USAGE:

   python tcv_format.py --cycle <forecast cycle; formatted as %Y%m%d%H> \
     --renumber <logical variable> --output_file <output file path> \
     --datapath <path to TC-vitals files on respective machine> \
     --rename <logical variable> --tcid <TC event identifier> \
     --unrenumber <logical variable> --year <year for TC-vitals records> \
     --windthresh <threshold wind speed for TC-vitals records; units are \
     knots>

NOTE:

   * Either the <year> or <cycle> options are mandatory; variable
     values are assigned internally accordingly.

   * If <datapath> is not specified, it is assumed that one of the
     pre-defined Python list tcvlocs items contains a viable path to
     the TC-vitals files; otherwise a TCVToolsError is raised.

   * If <tcid> is not specified, all TC-vitals records are collected
     in accordance with the user specification of <year> or <cycle>.

   * If <output_file> is not specified, the resultant TC-vitals are
     written to the default file name 'tcvitals.output'.

   * The following variables are optional:

     - <renumber>
     - <rename>
     - <unrenumber>
     - <windthresh>

HISTORY:

   2019-04-03: Bin Liu -- Initial implementation.
   2019-04-04: Henry R. Winterbottom -- Script interface for HAFS.

"""

#----

import argparse
import datetime
import os

import tcutil

#----

__author__ = "Henry R. Winterbottom"
__copyright__ = "2019 Henry R. Winterbottom, NOAA/NCEP/EMC"
__version__ = "1.0.0"
__maintainer__ = "Henry R. Winterbottom"
__email__ = "henry.winterbottom@noaa.gov"
__status__ = "Development"

#----

# The following is a list of default locations for TC-vitals files;
# this applies mainly to NOAA HPC clusters.

tcvlocs=['/scratch3/NCEPDEV/hwrf/noscrub/input/SYNDAT-PLUS',\
         '/scratch3/NCEPDEV/hwrf/noscrub/input/SYNDAT',\
         '/scratch1/portfolios/NCEPDEV/hwrf/noscrub/input/SYNDAT-PLUS',\
         '/scratch1/portfolios/NCEPDEV/hwrf/noscrub/input/SYNDAT',\
         '/lfs3/projects/hwrf-data/hwrf-input/SYNDAT-PLUS',\
         '/lfs3/projects/hwrf-data/hwrf-input/SYNDAT',\
         '/hwrf/noscrub/input/SYNDAT-PLUS',\
         '/hwrf/noscrub/input/SYNDAT',\
         '/gpfs/gp1/nco/ops/com/arch/prod/syndat/',\
         '/gpfs/tp1/nco/ops/com/arch/prod/syndat/',\
         '/Users/hwinter/noscrub/fv3sar_workflow/input-data/SYNDAT-PLUS']

#----

class TCVTools(object):
    """
    DESCRIPTION:

    This is the base-class object for all TC-vitals record
    manipulations relative to the user specifications.

    INPUT VARIABLES:

    * opts_obj; a Python object containing the user command line
      options.

    """
    def __init__(self,opts_obj):
        """ 
        DESCRIPTION:

        Creates a new TCVTools object.

        """
        self.opts_obj=opts_obj
        self.defattrs()
    def defattrs(self):
        """
        DESCRIPTION:

        This method defines the base-class object attributes.

        """
        attrs_dict={'cycle':'cycle','output_file':'output_file',\
            'rename':'rename','renumber':'renumber','stormnum':'tcvid',\
            'threshold':'windthresh','unrenumber':'unrenumber','year':\
            'year'}
        for key in attrs_dict.keys():
            value=getattr(self.opts_obj,attrs_dict[key])
            if key=='stormnum':
                setattr(self,'stormid',value)
                value=int(value[0:2])
            setattr(self,key,value)
    def revital(self):
        """
        DESCRIPTION:

        This method launches the tcutil.revital package and parses
        TC-vitals records in accordance with the user specifications.

        """
        renumberlog=getattr(self,'output_file')+'.renumber'
        renumberlog=open(renumberlog,'wt+')
        output_file=open(self.output_file,'wt+')
        rvtl=tcutil.revital.Revital()
        if getattr(self.opts_obj,'datapath') is None:
            for item in tcvlocs:
                if os.path.exists(item):
                    setattr(self.opts_obj,'datapath',item)
                    break
        datapath=getattr(self.opts_obj,'datapath')
        if datapath is None:
            msg=('A datapath containing TC-vitals records could not '\
                'be located on the user machine. Aborting!!!')
            raise TCVToolsError(msg=msg)
        if self.year is not None:
            year=getattr(self.opts_obj,'year')
        if self.cycle is not None:
            year=getattr(self.opts_obj,'cycle')[0:4]
        tcvfile=os.path.join(datapath,'syndat_tcvitals.%s'%year)
        if not os.path.isfile(tcvfile):
            msg=('A TC-vitals record file for year %s could not be '\
                'located in datapath %s. Aborting!!!'%(year,datapath))
            raise TCVToolsError(msg=msg)
        def check_test_vitals(vl):
            """
            DESCRIPTION:
            
            This is a replacement for tcutil.storminfo.name_number_okay for
            use with TEST storms and internal stormids.  It allows through
            only the storm numbers matching stormnum, regardless of the storm
            name (usually TEST and UNKNOWN would be dropped).

            """
            for vital in vl:
                if vital.stnum==self.stormnum:
                    yield vital
                elif getattr(vital,'old_stnum','XX')==self.stormnum:
                    yield vital
        filelist=list()
        filelist.append(tcvfile)
        rvtl.readfiles(filelist=filelist,raise_all=False)
        if not self.renumber:
            rvtl.clean_up_vitals()
        elif self.stormnum<50:
            rvtl.renumber(threshold=self.threshold,discard_duplicates=\
                self.unrenumber)
        elif self.stormnum>=90:
            rvtl.clean_up_vitals()
        else:
            rvtl.clean_up_vitals(name_number_checker=check_test_vitals)
        if self.rename and self.stormnum<50:
            rvtl.rename()
        elif self.rename:
            pass
        if self.unrenumber:
            rvtl.swap_numbers()
            rvtl.swap_names()
        if self.stormid=='00X':
            rvtl.print_vitals(output_file,format=format,renumberlog=renumberlog,\
                old=True)       
        else:
            rvtl.print_vitals(output_file,stormid=self.stormid,format=format,\
                renumberlog=renumberlog,old=True)
        output_file.close()
        renumberlog.close()
    def write_cycle(self):
        """DESCRIPTION:

        This method, if the user specifies a specific forecast cycle
        timestamp to parse from the TC-vitals records, will write the
        record for the corresponding forecast cycle to the user
        specified (or default) output file in accordance with the user
        specifications.

        """

        if self.cycle is not None:
            dateobj=datetime.datetime.strptime(self.cycle,'%Y%m%d%H')
            cycle_str=datetime.datetime.strftime(dateobj,'%Y%m%d %H%M')
            with open(self.output_file,'rb') as f:
                data=f.read()
            with open(self.output_file,'wt') as f:
                for item in data.split('\n'):
                    if cycle_str in item:
                        f.write('%s\n'%item)                    
        else:
            pass
    def run(self):
        """
        DESCRIPTION:

        This method performs the following tasks:

        (1) Executes the tcutil.revital package in accordance with the
        user specifications.

        (2) Writes the user specified forecast cycle TC-vitals
        attributes to the user specified file (if applicable).

        """
        self.revital()
        self.write_cycle()

#----

class TCVToolsError(Exception):
   """
   DESCRIPTION:

   This is the base-class for all exceptions; it is a sub-class of
   Exceptions.

   OPTIONAL INPUT VARIABLES:

   * msg; a Python string to accompany the raised exception.

   """
   def __init__(self,msg=None):
      """
      DESCRIPTION:

      Creates a new TCVToolsError object.

      """
      super(TCVToolsError,self).__init__(msg)

#----

class TCVToolsOptions(object):
    """ 
    DESCRIPTION:

    This is the base-class object to parse all user specified options
    passed to the driver level of the script.

    """
    def __init__(self):
        """ 
        DESCRIPTION:

        Creates a new TCVToolsOptions object.

        """
        self.parser=argparse.ArgumentParser()
        self.parser.add_argument('-c','--cycle',help='The forecast cycle '\
            'for which viable TC-vitals entries are sought; format is '\
            'yyyymmddHH.',default=None)
        self.parser.add_argument('-n','--renumber',help='Disable renumbering '\
            'of invests to non-invests.',default=False)
        self.parser.add_argument('-out','--output_file',help='The output file '\
            'to write the resultant TC-vitals records.',default='tcvitals.output')
        self.parser.add_argument('-p','--datapath',help='The file path '\
            'to the TC-vitals files to be parsed.',default=None)
        self.parser.add_argument('-r','--rename',help='Enable renaming of '\
            'storms to last name seen.',default=False)
        self.parser.add_argument('-tc','--tcvid',help='The TC-vitals '\
            'event identifier (e.g., 11L for the eleventh storm in the '\
            'North-Atlantic basin.',default='00X')
        self.parser.add_argument('-u','--unrenumber',help='Unrenumber and '\
            'unrename after renumbering and renaming, discarding unrelated '\
            'cycles.',default=False)
        self.parser.add_argument('-y','--year',help='The year for which to '\
            'seek out TC-vitals records.',default=None)
        self.parser.add_argument('-w','--windthresh',help='The threshold '\
            'wind speed (knots) for which to include a TC-vitals record.',\
            default=None)
        self.opts_obj=lambda:None
    def check(self,opts_obj):
        """
        DESCRIPTION:

        This method checks that all mandatory arguments have been
        supplied by the user; if not, a TCVToolsError is raised.

        INPUT VARIABLES:

        * opts_obj; a Python object containing the user command line
          options.

        """
        mandargs_dict={'year':'cycle','cycle':'year'}
        for key in mandargs_dict.keys():
            if getattr(opts_obj,key) is None:
                try:
                    getattr(opts_obj,mandargs_dict[key])
                except Exception:
                    msg=('Arguments %s and %s cannot be both NoneType. '\
                        'Aborting!'%(key,mandargs_dict[key]))
                    raise TCVToolsError(msg=msg)
    def run(self):
        """
        DESCRIPTION:

        This method collects the user-specified command-line
        arguments; the available command line arguments are as
        follows:

        -c; the forecast cycle for which viable TC-vitals entries are
            sought; format is (assyming UNIX standard) %Y%m%d%H.

        -n; optional disable renumbering of invests to non-invests.

        -out; the output file to write the resultant TC-vitals
              records.

        -p; the file path to the TC-vitals files to be parsed.

        -r; optional renaming of storms to last name seen.

        -tc; the TC-vitals event identifier.

        -u; unrenumber and unrename after renumbering and renaming,
            discarding unrelated cycles.

        -y; the year for which to seek out TC-vitals records.

        -w; the threshold wind speed (knots) for which to include a
            TC-vitals record.

        """
        opts_obj=self.opts_obj
        args_list=['cycle','datapath','output_file','rename',\
            'renumber','tcvid','unrenumber','windthresh','year']
        args=self.parser.parse_args()
        for item in args_list:
            value=getattr(args,item)
            setattr(opts_obj,item,value)
        self.check(opts_obj=opts_obj)
        return opts_obj

#----

def main():
    """
    DESCRIPTION:

    This is the driver-level method to invoke the tasks within this
    script.

    """
    options=TCVToolsOptions()
    opts_obj=options.run()
    tcvtools=TCVTools(opts_obj=opts_obj)
    tcvtools.run()

#----

if __name__=='__main__':
    main()

        
    
