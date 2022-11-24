% ------------------------------------------------------------------------------
% Generate a merged profile (version 2) from C and B mono-profile files.
%
% SYNTAX :
%  nc_create_merged_profile_rt(varargin)
%
% INPUT PARAMETERS :
%   varargin :
%      input parameters:
%         - should be provided as pairs ('param_name','param_value')
%         - 'param_name' value is not case sensitive
%   mandatory parameters:
%      createOnlyMultiProfFlag : should be set to '1' to create multi-profile
%                                file, to '0' otherwise
%      if createOnlyMultiProfFlag is set to '0' the mandatory parameters
%      are:
%         floatCProfFileName  : input c PROF file path name
%         floatBProfFileName  : input b PROF file path name
%         floatMetaFileName   : input META file path name
%         floatCTrajFileName  : input c TRAJ file path name
%         floatBTrajFileName  : input b TRAJ file path name
%         createMultiProfFlag : should be set to '1' to create multi-profile
%                               file, to '0' otherwise
%         outputDirName       : output directory name
%      if createOnlyMultiProfFlag is set to '1' the mandatory parameters
%      are:
%         floatWmo      : WMO number of concerned float
%         outputDirName : output directory name
%   optional parameters:
%      outputLogDirName        : LOG file directory name
%      xmlReportDirName        : XML file directory name
%      xmlReportFileName       : XML file name
%      monoProfRefFileName     : M mono-profile reference file path name
%      multiProfRefFileName    : M multi-profile reference file path name
%      tmpDirName              : base name of the temporary directory
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/11/2018 - RNU - V 0.1: creation
%   03/07/2018 - RNU - V 0.2: update from 20180306 version of the specifications
%   06/15/2018 - RNU - V 1.0: creation of PI and RT tool + generate NetCDF 4 output files
%   07/13/2018 - RNU - V 1.1: the temporary directory could be set by an input parameter
%   08/22/2018 - RNU - V 1.2: manage missing PARAMETER_DATA_MODE when DATA_MODE == 'R'
%   09/25/2018 - RNU - V 1.3: added input parameters 'createOnlyMultiProfFlag' and 'floatWmo'
% ------------------------------------------------------------------------------
function nc_create_merged_profile_rt(varargin)

% generate NetCDF-4 flag for mono-profile file
global g_cocm_netCDF4FlagForMonoProf;
g_cocm_netCDF4FlagForMonoProf = 0;

% generate NetCDF-4 flag for multiple-profiles file
global g_cocm_netCDF4FlagForMultiProf;
g_cocm_netCDF4FlagForMultiProf = 1;

% default directory to store the LOG file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% default directory to store the XML file
DIR_XML_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\xml\';

% default base name of the temporary directory 
DIR_TMP = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\TMP\';

% merged profile reference file
if (g_cocm_netCDF4FlagForMonoProf)
   MONO_PROF_REF_PROFILE_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util\misc/ArgoMProf_V1.0_netcdf4_classic.nc';
else
   MONO_PROF_REF_PROFILE_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util\misc/ArgoMProf_V1.0_netcdf_classic.nc';
end
if (g_cocm_netCDF4FlagForMultiProf)
   MULTI_PROF_REF_PROFILE_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util\misc/ArgoMProf_V1.0_netcdf4_classic.nc';
else
   MULTI_PROF_REF_PROFILE_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util\misc/ArgoMProf_V1.0_netcdf_classic.nc';
end

% input parameters
global g_cocm_createOnlyMultiProfFlag;
global g_cocm_floatWmo;
global g_cocm_floatCProfFileName;
global g_cocm_floatBProfFileName;
global g_cocm_floatMetaFileName;
global g_cocm_floatCTrajFileName;
global g_cocm_floatBTrajFileName;
global g_cocm_createMultiProfFlag;
global g_cocm_monoProfRefFile;
global g_cocm_multiProfRefFile;
global g_cocm_outputDirName;
global g_cocm_outputLogDirName;
global g_cocm_outputXmlReportDirName;
global g_cocm_outputXmlReportFileName;
global g_cocm_tmpDirName;

% DOM node of XML report
global g_cocm_xmlReportDOMNode;

% report information structure
global g_cocm_reportData;
g_cocm_reportData = [];
g_cocm_reportData.inputCProfFile = [];
g_cocm_reportData.inputBProfFile = [];
g_cocm_reportData.inputMetaFile = [];
g_cocm_reportData.inputCTrajFile = [];
g_cocm_reportData.inputBTrajFile = [];
g_cocm_reportData.outputMMonoProfFile = [];
g_cocm_reportData.outputMMultiProfFile = [];

% program version
global g_cocm_ncCreateMergedProfileVersion;
g_cocm_ncCreateMergedProfileVersion = '1.3';

% current float and cycle identification
global g_cocm_floatNum;
global g_cocm_cycleNum;
global g_cocm_cycleDir;

% to print data after each processing step
global g_cocm_printCsv;
g_cocm_printCsv = 0;


% startTime
ticStartTime = tic;

% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

% set default values
g_cocm_outputLogDirName = DIR_LOG_FILE;
g_cocm_outputXmlReportDirName = DIR_XML_FILE;
g_cocm_monoProfRefFile = MONO_PROF_REF_PROFILE_FILE;
g_cocm_multiProfRefFile = MULTI_PROF_REF_PROFILE_FILE;
g_cocm_outputXmlReportFileName = ['nc_create_merged_profile_rt_' currentTime '.xml'];
g_cocm_tmpDirName = DIR_TMP;

% default values initialization
init_default_values;

% measurement codes initialization
init_measurement_codes;

logFileName = [];
status = 'nok';
try
      
   % init the XML report
   init_xml_report(currentTime);
   
   % get input parameters
   [inputError, logLines] = parse_input_param(varargin);

   % log file creation
   if (~isempty(g_cocm_outputLogDirName))
      logFileName = [g_cocm_outputLogDirName '/nc_create_merged_profile_rt_' currentTime '.log'];
   else
      logFileName = [tempdir '/nc_create_merged_profile_rt_' currentTime '.log'];
   end
   
   diary(logFileName);
   
   if (~isempty(logLines))
      fprintf('%s', logLines{:});
   end
   
   if (~inputError)
      
      g_cocm_reportData.inputCProfFile = g_cocm_floatCProfFileName;
      g_cocm_reportData.inputBProfFile = g_cocm_floatBProfFileName;
      g_cocm_reportData.inputMetaFile = g_cocm_floatMetaFileName;
      g_cocm_reportData.inputCTrajFile = g_cocm_floatCTrajFileName;
      g_cocm_reportData.inputBTrajFile = g_cocm_floatBTrajFileName;
      
      % set float, cycle an direction
      if (g_cocm_createOnlyMultiProfFlag == '0')
         [~, cProfFileName, ~] = fileparts(g_cocm_floatCProfFileName);
         idF = strfind(cProfFileName, '_');
         g_cocm_floatNum = str2double(cProfFileName(2:idF-1));
         if (cProfFileName(end) == 'D')
            g_cocm_cycleDir = 'D';
            cProfFileName(end) = [];
         else
            g_cocm_cycleDir = '';
         end
         g_cocm_cycleNum = str2double(cProfFileName(idF+1:end));
      else
         g_cocm_floatNum = str2double(g_cocm_floatWmo);
      end
      
      % generate M-PROF file
      nc_create_merged_profile_(...
         str2num(g_cocm_createOnlyMultiProfFlag), ...
         g_cocm_floatCProfFileName, ...
         g_cocm_floatBProfFileName, ...
         g_cocm_floatMetaFileName, ...
         g_cocm_floatCTrajFileName, ...
         g_cocm_floatBTrajFileName, ...
         str2num(g_cocm_createMultiProfFlag), ...
         [], [], ...
         g_cocm_outputDirName, ...
         g_cocm_monoProfRefFile, g_cocm_multiProfRefFile, ...
         g_cocm_tmpDirName);
   end
   
   diary off;
   
   % finalize XML report
   [status] = finalize_xml_report(ticStartTime, logFileName, []);
   
catch
   
   diary off;
   
   % finalize XML report
   [status] = finalize_xml_report(ticStartTime, logFileName, lasterror);
   
end

% create the XML report path file name
if (~isempty(g_cocm_outputXmlReportDirName))
   xmlFileName = [g_cocm_outputXmlReportDirName '/' g_cocm_outputXmlReportFileName];
else
   xmlFileName = [tempdir '/' g_cocm_outputXmlReportFileName];
end

% save the XML report
xmlwrite(xmlFileName, g_cocm_xmlReportDOMNode);
% if (strcmp(status, 'nok') == 1)
%    edit(xmlFileName);
% end

return;

% ------------------------------------------------------------------------------
% Initialize XML report.
%
% SYNTAX :
%  init_xml_report(a_time)
%
% INPUT PARAMETERS :
%   a_time : start date of the run ('yyyymmddTHHMMSS' format)
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/13/2018 - RNU - creation
% ------------------------------------------------------------------------------
function init_xml_report(a_time)

% DOM node of XML report
global g_cocm_xmlReportDOMNode;


% initialize XML report
docNode = com.mathworks.xml.XMLUtils.createDocument('coriolis_function_report');
docRootNode = docNode.getDocumentElement;

newChild = docNode.createElement('function');
newChild.appendChild(docNode.createTextNode('co041404'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('comment');
newChild.appendChild(docNode.createTextNode('Argo Coriolis merged profiles (version 2) generating tool (nc_create_merged_profile_rt)'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('date');
newChild.appendChild(docNode.createTextNode(datestr(datenum(a_time, 'yyyymmddTHHMMSSZ'), 'dd/mm/yyyy HH:MM:SS')));
docRootNode.appendChild(newChild);

g_cocm_xmlReportDOMNode = docNode;

return;

% ------------------------------------------------------------------------------
% Parse input parameters.
%
% SYNTAX :
%  [o_inputError, o_logLines] = parse_input_param(a_varargin)
%
% INPUT PARAMETERS :
%   a_varargin : input parameters
%
% OUTPUT PARAMETERS :
%   o_inputError : input error flag
%   o_logLines   : lines to write in log file
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/13/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_inputError, o_logLines] = parse_input_param(a_varargin)

% output parameters initialization
o_inputError = 0;
o_logLines = [];

% input parameters
global g_cocm_createOnlyMultiProfFlag;
global g_cocm_floatWmo;
global g_cocm_floatCProfFileName;
global g_cocm_floatBProfFileName;
global g_cocm_floatMetaFileName;
global g_cocm_floatCTrajFileName;
global g_cocm_floatBTrajFileName;
global g_cocm_createMultiProfFlag;
global g_cocm_monoProfRefFile;
global g_cocm_multiProfRefFile;
global g_cocm_outputDirName;
global g_cocm_outputLogDirName;
global g_cocm_outputXmlReportDirName;
global g_cocm_outputXmlReportFileName;
global g_cocm_tmpDirName;


g_cocm_floatWmo = '';
g_cocm_floatCProfFileName = '';
g_cocm_floatBProfFileName = '';
g_cocm_floatMetaFileName = '';
g_cocm_floatCTrajFileName = '';
g_cocm_floatBTrajFileName = '';
g_cocm_createMultiProfFlag = '';
g_cocm_outputDirName = '';

% ignore empty input parameters
idDel = [];
for id = 1:length(a_varargin)
   if (isempty(a_varargin{id}))
      idDel = [idDel id];
   end
end
a_varargin(idDel) = [];

% check input parameters
if (~isempty(a_varargin))
   if (rem(length(a_varargin), 2) ~= 0)
      o_logLines{end+1} = sprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') => exit\n');
      o_inputError = 1;
      return;
   else
      for id = 1:2:length(a_varargin)
         if (strcmpi(a_varargin{id}, 'floatCProfFileName'))
            g_cocm_floatCProfFileName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'floatBProfFileName'))
            g_cocm_floatBProfFileName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'floatMetaFileName'))
            g_cocm_floatMetaFileName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'floatCTrajFileName'))
            g_cocm_floatCTrajFileName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'floatBTrajFileName'))
            g_cocm_floatBTrajFileName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'createMultiProfFlag'))
            g_cocm_createMultiProfFlag = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'outputDirName'))
            g_cocm_outputDirName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'outputLogDirName'))
            g_cocm_outputLogDirName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'xmlReportDirName'))
            g_cocm_outputXmlReportDirName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'xmlReportFileName'))
            g_cocm_outputXmlReportFileName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'monoProfRefFileName'))
            g_cocm_monoProfRefFile = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'multiProfRefFileName'))
            g_cocm_multiProfRefFile = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'tmpDirName'))
            g_cocm_tmpDirName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'createOnlyMultiProfFlag'))
            g_cocm_createOnlyMultiProfFlag = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'floatWmo'))
            g_cocm_floatWmo = a_varargin{id+1};
         else
            o_logLines{end+1} = sprintf('WARNING: unexpected input argument (''%s'') => ignored\n', a_varargin{id});
         end
      end
   end
end

% check that mandatory parameters are provided
if (isempty(g_cocm_createOnlyMultiProfFlag))
   o_logLines{end+1} = sprintf('ERROR: ''createOnlyMultiProfFlag'' input parameter is mandatory\n');
   o_inputError = 1;
   return;
end
if ((length(g_cocm_createOnlyMultiProfFlag) ~= 1) || ...
      ((g_cocm_createOnlyMultiProfFlag ~= '0') && (g_cocm_createOnlyMultiProfFlag ~= '1')))
   o_logLines{end+1} = sprintf('ERROR: Inconsistent ''createOnlyMultiProfFlag'' value (%s) (expected ''0'' or ''1'')\n', g_cocm_outputDirName);
   o_inputError = 1;
   return;
end

if (g_cocm_createOnlyMultiProfFlag == '0')
   
   % check that mandatory parameters are provided
   if (isempty(g_cocm_floatCProfFileName))
      o_logLines{end+1} = sprintf('ERROR: ''floatCProfFileName'' input parameter is mandatory\n');
      o_inputError = 1;
      return;
   end
   if (isempty(g_cocm_floatBProfFileName))
      o_logLines{end+1} = sprintf('ERROR: ''floatBProfFileName'' input parameter is mandatory\n');
      o_inputError = 1;
      return;
   end
   if (isempty(g_cocm_floatMetaFileName))
      o_logLines{end+1} = sprintf('ERROR: ''floatMetaFileName'' input parameter is mandatory\n');
      o_inputError = 1;
      return;
   end
   if (isempty(g_cocm_floatCTrajFileName))
      o_logLines{end+1} = sprintf('ERROR: ''floatCTrajFileName'' input parameter is mandatory\n');
      o_inputError = 1;
      return;
   end
   if (isempty(g_cocm_floatBTrajFileName))
      o_logLines{end+1} = sprintf('ERROR: ''floatBTrajFileName'' input parameter is mandatory\n');
      o_inputError = 1;
      return;
   end
   if (isempty(g_cocm_createMultiProfFlag))
      o_logLines{end+1} = sprintf('ERROR: ''createMultiProfFlag'' input parameter is mandatory\n');
      o_inputError = 1;
      return;
   end
   if (isempty(g_cocm_outputDirName))
      o_logLines{end+1} = sprintf('ERROR: ''outputDirName'' input parameter is mandatory\n');
      o_inputError = 1;
      return;
   end

   % check input parameters
   if ~(exist(g_cocm_floatCProfFileName, 'file') == 2)
      o_logLines{end+1} = sprintf('ERROR: Input file not found: %s\n', g_cocm_floatCProfFileName);
      o_inputError = 1;
      return;
   end
   if ~(exist(g_cocm_floatBProfFileName, 'file') == 2)
      o_logLines{end+1} = sprintf('ERROR: Input file not found: %s\n', g_cocm_floatBProfFileName);
      o_inputError = 1;
      return;
   end
   if ~(exist(g_cocm_floatMetaFileName, 'file') == 2)
      o_logLines{end+1} = sprintf('ERROR: Input file not found: %s\n', g_cocm_floatMetaFileName);
      o_inputError = 1;
      return;
   end
   if ~(exist(g_cocm_floatCTrajFileName, 'file') == 2)
      o_logLines{end+1} = sprintf('ERROR: Input file not found: %s\n', g_cocm_floatCTrajFileName);
      o_inputError = 1;
      return;
   end
   if ~(exist(g_cocm_floatBTrajFileName, 'file') == 2)
      o_logLines{end+1} = sprintf('ERROR: Input file not found: %s\n', g_cocm_floatBTrajFileName);
      o_inputError = 1;
      return;
   end
   if ((length(g_cocm_createMultiProfFlag) ~= 1) || ...
         ((g_cocm_createMultiProfFlag ~= '0') && (g_cocm_createMultiProfFlag ~= '1')))
      o_logLines{end+1} = sprintf('ERROR: Inconsistent ''createMultiProfFlag'' value (%s) (expected ''0'' or ''1'')\n', g_cocm_createMultiProfFlag);
      o_inputError = 1;
      return;
   end
   if ~(exist(g_cocm_outputDirName, 'dir') == 7)
      o_logLines{end+1} = sprintf('ERROR: Output directory not found: %s\n', g_cocm_outputDirName);
      o_inputError = 1;
      return;
   end
   
   if (~isempty(g_cocm_floatWmo))
      o_logLines{end+1} = sprintf('WARNING: unexpected input argument (''floatWmo'') => ignored\n');
   end
   
else
   
   % check that mandatory parameters are provided
   if (isempty(g_cocm_floatWmo))
      o_logLines{end+1} = sprintf('ERROR: ''floatWmo'' input parameter is mandatory\n');
      o_inputError = 1;
      return;
   end
   if (isempty(g_cocm_outputDirName))
      o_logLines{end+1} = sprintf('ERROR: ''outputDirName'' input parameter is mandatory\n');
      o_inputError = 1;
      return;
   end
   
   % check input parameters
   if ~(exist(g_cocm_outputDirName, 'dir') == 7)
      o_logLines{end+1} = sprintf('ERROR: Output directory not found: %s\n', g_cocm_outputDirName);
      o_inputError = 1;
      return;
   end
   if ~(exist([g_cocm_outputDirName '/' g_cocm_floatWmo], 'dir') == 7)
      o_logLines{end+1} = sprintf('ERROR: Float output directory not found: %s\n', [g_cocm_outputDirName '/' g_cocm_floatWmo]);
      o_inputError = 1;
      return;
   end
   
   if (~isempty(g_cocm_floatCProfFileName))
      o_logLines{end+1} = sprintf('WARNING: unexpected input argument (''floatCProfFileName'') => ignored\n');
   end
   if (~isempty(g_cocm_floatBProfFileName))
      o_logLines{end+1} = sprintf('WARNING: unexpected input argument (''floatBProfFileName'') => ignored\n');
   end
   if (~isempty(g_cocm_floatMetaFileName))
      o_logLines{end+1} = sprintf('WARNING: unexpected input argument (''floatMetaFileName'') => ignored\n');
   end
   if (~isempty(g_cocm_floatCTrajFileName))
      o_logLines{end+1} = sprintf('WARNING: unexpected input argument (''floatCTrajFileName'') => ignored\n');
   end
   if (~isempty(g_cocm_floatBTrajFileName))
      o_logLines{end+1} = sprintf('WARNING: unexpected input argument (''floatBTrajFileName'') => ignored\n');
   end
   if (~isempty(g_cocm_createMultiProfFlag))
      o_logLines{end+1} = sprintf('WARNING: unexpected input argument (''createMultiProfFlag'') => ignored\n');
   end
   
end

% check input not-mandatory parameters
if ~(exist(g_cocm_monoProfRefFile, 'file') == 2)
   o_logLines{end+1} = sprintf('ERROR: Input mono-profile reference file not found: %s\n', g_cocm_monoProfRefFile);
   o_inputError = 1;
   return;
end
if ~(exist(g_cocm_multiProfRefFile, 'file') == 2)
   o_logLines{end+1} = sprintf('ERROR: Input multi-profile reference file not found: %s\n', g_cocm_multiProfRefFile);
   o_inputError = 1;
   return;
end
if ~(exist(g_cocm_outputLogDirName, 'dir') == 7)
   o_logLines{end+1} = sprintf('ERROR: Output LOG directory not found: %s\n', g_cocm_outputLogDirName);
   o_inputError = 1;
   return;
end
if ~(exist(g_cocm_outputXmlReportDirName, 'dir') == 7)
   o_logLines{end+1} = sprintf('ERROR: Output XML directory not found: %s\n', g_cocm_outputXmlReportDirName);
   o_inputError = 1;
   return;
end
if ~(exist(g_cocm_tmpDirName, 'dir') == 7)
   o_logLines{end+1} = sprintf('ERROR: Temporary directory not found: %s\n', g_cocm_tmpDirName);
   o_inputError = 1;
   return;
end

o_logLines{end+1} = sprintf('INPUT PARAMETERS\n');
o_logLines{end+1} = sprintf('createOnlyMultiProfFlag : %s\n', g_cocm_createOnlyMultiProfFlag);
if (g_cocm_createOnlyMultiProfFlag == '0')
   o_logLines{end+1} = sprintf('floatCProfFileName      : %s\n', g_cocm_floatCProfFileName);
   o_logLines{end+1} = sprintf('floatBProfFileName      : %s\n', g_cocm_floatBProfFileName);
   o_logLines{end+1} = sprintf('floatMetaFileName       : %s\n', g_cocm_floatMetaFileName);
   o_logLines{end+1} = sprintf('floatCTrajFileName      : %s\n', g_cocm_floatCTrajFileName);
   o_logLines{end+1} = sprintf('floatBTrajFileName      : %s\n', g_cocm_floatBTrajFileName);
   o_logLines{end+1} = sprintf('createMultiProfFlag     : %s\n', g_cocm_createMultiProfFlag);
else
   o_logLines{end+1} = sprintf('floatWmo                : %s\n', g_cocm_floatWmo);
end
o_logLines{end+1} = sprintf('outputDirName           : %s\n', g_cocm_outputDirName);
o_logLines{end+1} = sprintf('outputLogDirName        : %s\n', g_cocm_outputLogDirName);
o_logLines{end+1} = sprintf('xmlReportDirName        : %s\n', g_cocm_outputXmlReportDirName);
o_logLines{end+1} = sprintf('xmlReportFileName       : %s\n', g_cocm_outputXmlReportFileName);
o_logLines{end+1} = sprintf('monoProfRefFileName     : %s\n', g_cocm_monoProfRefFile);
o_logLines{end+1} = sprintf('multiProfRefFileName    : %s\n', g_cocm_multiProfRefFile);
o_logLines{end+1} = sprintf('tmpDirName              : %s\n', g_cocm_tmpDirName);
o_logLines{end+1} = sprintf('\n');

return;

% ------------------------------------------------------------------------------
% Finalize the XML report.
%
% SYNTAX :
%  [o_status] = finalize_xml_report(a_ticStartTime, a_logFileName, a_error)
%
% INPUT PARAMETERS :
%   a_ticStartTime : identifier for the "tic" command
%   a_logFileName  : log file path name of the run
%   a_error        : Matlab error
%
% OUTPUT PARAMETERS :
%   o_status : final status of the run
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/13/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_status] = finalize_xml_report(a_ticStartTime, a_logFileName, a_error)

% DOM node of XML report
global g_cocm_xmlReportDOMNode;

% report information structure
global g_cocm_reportData;


% initalize final status
o_status = 'ok';

% finalize the report
docNode = g_cocm_xmlReportDOMNode;
docRootNode = docNode.getDocumentElement;


% list of input files
newChild = docNode.createElement('input_files');

if (~isempty(g_cocm_reportData.inputCProfFile))
   newChildBis = docNode.createElement('input_c_prof_file');
   newChildBis.appendChild(docNode.createTextNode(g_cocm_reportData.inputCProfFile));
   newChild.appendChild(newChildBis);
end

if (~isempty(g_cocm_reportData.inputBProfFile))
   newChildBis = docNode.createElement('input_b_prof_file');
   newChildBis.appendChild(docNode.createTextNode(g_cocm_reportData.inputBProfFile));
   newChild.appendChild(newChildBis);
end

if (~isempty(g_cocm_reportData.inputMetaFile))
   newChildBis = docNode.createElement('input_meta_file');
   newChildBis.appendChild(docNode.createTextNode(g_cocm_reportData.inputMetaFile));
   newChild.appendChild(newChildBis);
end

if (~isempty(g_cocm_reportData.inputCTrajFile))
   newChildBis = docNode.createElement('input_c_traj_file');
   newChildBis.appendChild(docNode.createTextNode(g_cocm_reportData.inputCTrajFile));
   newChild.appendChild(newChildBis);
end

if (~isempty(g_cocm_reportData.inputBTrajFile))
   newChildBis = docNode.createElement('input_b_traj_file');
   newChildBis.appendChild(docNode.createTextNode(g_cocm_reportData.inputBTrajFile));
   newChild.appendChild(newChildBis);
end

docRootNode.appendChild(newChild);

% list of output files
newChild = docNode.createElement('output_files');

if (~isempty(g_cocm_reportData.outputMMonoProfFile))
   newChildBis = docNode.createElement('output_m_mono_prof_file');
   newChildBis.appendChild(docNode.createTextNode(g_cocm_reportData.outputMMonoProfFile));
   newChild.appendChild(newChildBis);
end

if (~isempty(g_cocm_reportData.outputMMultiProfFile))
   newChildBis = docNode.createElement('output_m_multi_prof_file');
   newChildBis.appendChild(docNode.createTextNode(g_cocm_reportData.outputMMultiProfFile));
   newChild.appendChild(newChildBis);
end

docRootNode.appendChild(newChild);

% retrieve information from the log file
[infoMsg, warningMsg, errorMsg] = parse_log_file(a_logFileName);

if (~isempty(infoMsg))
   for idMsg = 1:length(infoMsg)
      newChild = docNode.createElement('info');
      textNode = char(infoMsg(idMsg));
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
end

if (~isempty(warningMsg))
   for idMsg = 1:length(warningMsg)
      newChild = docNode.createElement('warning');
      textNode = char(warningMsg(idMsg));
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
end

if (~isempty(errorMsg))
   for idMsg = 1:length(errorMsg)
      newChild = docNode.createElement('error');
      textNode = char(errorMsg(idMsg));
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
   o_status = 'nok';
end

% add matlab error
if (~isempty(a_error))
   o_status = 'nok';
   
   newChild = docNode.createElement('matlab_error');
   
   newChildBis = docNode.createElement('error_message');
   textNode = regexprep(a_error.message, char(10), ': ');
   newChildBis.appendChild(docNode.createTextNode(textNode));
   newChild.appendChild(newChildBis);
   
   for idS = 1:size(a_error.stack, 1)
      newChildBis = docNode.createElement('stack_line');
      textNode = sprintf('Line: %3d File: %s (func: %s)', ...
         a_error.stack(idS). line, ...
         a_error.stack(idS). file, ...
         a_error.stack(idS). name);
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
   
   docRootNode.appendChild(newChild);
end

newChild = docNode.createElement('duration');
newChild.appendChild(docNode.createTextNode(format_time(toc(a_ticStartTime)/3600)));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('status');
newChild.appendChild(docNode.createTextNode(o_status));
docRootNode.appendChild(newChild);

return;

% ------------------------------------------------------------------------------
% Retrieve INFO, WARNING and ERROR messages from the log file.
%
% SYNTAX :
%  [o_infoMsg, o_warningMsg, o_errorMsg] = parse_log_file(a_logFileName)
%
% INPUT PARAMETERS :
%   a_logFileName  : log file path name of the run
%
% OUTPUT PARAMETERS :
%   o_infoMsg    : INFO messages
%   o_warningMsg : WARNING messages
%   o_errorMsg   : ERROR messages
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/13/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_infoMsg, o_warningMsg, o_errorMsg] = parse_log_file(a_logFileName)

% output parameters initialization
o_infoMsg = [];
o_warningMsg = [];
o_errorMsg = [];

if (~isempty(a_logFileName))
   % read log file
   fId = fopen(a_logFileName, 'r');
   if (fId == -1)
      errorLine = sprintf('ERROR: Unable to open file: %s\n', a_logFileName);
      o_errorMsg = [o_errorMsg {errorLine}];
      return;
   end
   fileContents = textscan(fId, '%s', 'delimiter', '\n');
   fclose(fId);
   
   if (~isempty(fileContents) && ~isempty(fileContents{:}))
      % retrieve wanted messages
      fileContents = fileContents{:};
      idLine = 1;
      while (1)
         line = fileContents{idLine};
         if (strncmp(line, 'INFO: ', length('INFO: ')))
            o_infoMsg = [o_infoMsg {line(length('INFO: ')+1:end)}];
         elseif (strncmp(line, 'WARNING: ', length('WARNING: ')))
            o_warningMsg = [o_warningMsg {line(length('WARNING: ')+1:end)}];
         elseif (strncmp(line, 'ERROR: ', length('ERROR: ')))
            o_errorMsg = [o_errorMsg {line(length('ERROR: ')+1:end)}];
         end
         idLine = idLine + 1;
         if (idLine > length(fileContents))
            break;
         end
      end
   end
end

return;

% ------------------------------------------------------------------------------
% Duration format.
%
% SYNTAX :
%   [o_time] = format_time(a_time)
%
% INPUT PARAMETERS :
%   a_time : hour (in float)
%
% OUTPUT PARAMETERS :
%   o_time : formated duration
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/13/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_time] = format_time(a_time)

% output parameters initialization
o_time = [];

if (a_time >= 0)
   sign = '';
else
   sign = '-';
end
a_time = abs(a_time);
h = fix(a_time);
m = fix((a_time-h)*60);
s = round(((a_time-h)*60-m)*60);
if (s == 60)
   s = 0;
   m = m + 1;
   if (m == 60)
      m = 0;
      h = h + 1;
   end
end
if (isempty(sign))
   o_time = sprintf('%02d:%02d:%02d', h, m, s);
else
   o_time = sprintf('%c %02d:%02d:%02d', sign, h, m, s);
end

return;
