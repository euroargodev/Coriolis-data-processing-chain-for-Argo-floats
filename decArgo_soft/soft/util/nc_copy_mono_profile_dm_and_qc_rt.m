% ------------------------------------------------------------------------------
% Copy, in a RT profile file, DM data and QC values set by the Coriolis SCOOP
% tool.
% We use 2 data set:
% - the OLD one is supposed to contain DM data and SCOOP QC values
% - the NEW one is supposed to be a direct decoder output
% The final data set contains only files from OLD data set that have DM
% data or SCOOP QC. The provided files are based on a duplication of NEW
% data set files, then updated with OLD dataset DM and SCOOP QCs.
% Note also that the copy of DM data and the report of SCOOP QCs is performed
% for all parameters except those provided in a list (named
% IGNORED_PARAMETER_LIST below).
%
% SYNTAX :
%   nc_copy_mono_profile_dm_and_qc_rt(varargin)
%
% INPUT PARAMETERS :
%   no mandatory input parameters.
%   input parameter names are not case sensitive.
%   possible input parameters:
%      xmlReportDir     : directory to store the XML report
%      xmlReport        : file name of the XML report
%      floatWmo         : float to process (if not given: all the floats of the
%                         inputNewNcDir directory are processed)
%      inputOldNcDir    : directory of input OLD NetCDF files containing the Qc
%                         values and DM data
%      inputNewNcDir    : directory of input NEW NetCDF files
%      outputDir        : directory of output NetCDF updated files
%      ignoredparamList : list of parameters ignored in the DM and QC report
%      logDir           : directory to store the log file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/10/2018 - RNU - creation
%   08/10/2018 - RNU - V 1.0: creation
%   06/18/2019 - RNU - V 1.1: some variables indexed by N_PROF are not
%                             copied from OLD file (Ex: FLOAT_SERIAL_NO) but
%                             kept from NEW file so that an update of such
%                             parameter in the data base will be reported in
%                             all N_PROF of the output file
%   06/21/2019 - RNU - V 1.2: update of the list of variables mentioned in
%                             the V 1.1
%   10/09/2019 - RNU - V 1.3: more than one B parameter can be ignored in
%                             the report of SCOOP QCs (IGNORED_PARAMETER
%                             replaced by IGNORED_PARAMETER_LIST)
%   10/14/2019 - RNU - V 1.4: added management of 'DOWN_IRRADIANCE443' and
%                             'DOWN_IRRADIANCE555' parameters
%   11/04/2020 - RNU - V 1.5: copy, in NEW file, the global attributes only
%                             present in OLD file
%   11/12/2020 - RNU - V 1.6: correction of a bug in the copy of
%                             UV_INTENSITY_NITRATE data in output file
%   03/26/2021 - RNU - V 1.7: for ignored parameters, the PARAMETER_DATA_MODE of
%                             the old file should be replaced by the new file
%                             one (and the DATA_MODE processed accordingly).
%   07/08/2022 - RNU - V 1.8: manage case where:
%                             - statistical parameters become 'I' parameters
%                             from old to new file.
%                             - MTIME and NB_SAMPLE_CTD have been moved from
%                             B-PROF to C-PROF.
%                             - fillValue of RAW_DOWNWELLING_PAR and
%                             RAW_DOWNWELLING_IRRADIANCE* has been modified
%                             - fillValue of NB_SAMPLE_CTD and NB_SAMPLE_SFET
%                             has been modified
%   09/06/2022 - RNU - V 1.9: simplified version of 1.8 when both OLD and NEW
%                             files have the same parameters, fillValues, etc...
%   09/15/2022 - RNU - V 1.10: finalize output data set (when a BD file
%                              disapeared)
%   09/15/2022 - RNU - V 1.11: version of 
%                              nc_copy_mono_profile_dm_and_qc_specific only
%   10/03/2022 - RNU - V 1.12: creation of the RT version of the tool
% ------------------------------------------------------------------------------
function nc_copy_mono_profile_dm_and_qc_rt(varargin)

global g_cocd_dirOutputXmlFile;
global g_cocd_xmlReportFileName;
global g_cocd_floatList;
global g_cocd_dirInputOldNcFiles;
global g_cocd_dirInputNewNcFiles;
global g_cocd_dirOutputNcFiles;
global g_cocd_ignoredParameterList;
global g_cocd_dirLogFile;

% RT processing flag
global g_cocd_realtimeFlag;
g_cocd_realtimeFlag = 1;

% program version
global g_cocd_ncCopyMonoProfileDmAndQcVersion;
g_cocd_ncCopyMonoProfileDmAndQcVersion = '1.12';

% DOM node of XML report
global g_cocd_xmlReportDOMNode;

% report information structure
global g_cocd_reportData;
g_cocd_reportData = [];


% list of PARAMETER names that should not be considered in the report of DM data
% and SCOOP QCs (only 'B' parameters should be provided; their associated 'I'
% parameters will also be ignored)
% IGNORED_PARAMETER_LIST = [ ...
%    {'NITRATE'} ...
%    {'DOXY'} ...
%    ];
IGNORED_PARAMETER_LIST = [ ...
   ];

% information to set in 'HISTORY_REFERENCE (N_HISTORY, STRING64)' for the
% current action (64 characters max)
HISTORY_REFERENCE = 'http://doi.org/10.17882/42182';

% top directory of OLD input NetCDF files containing the Qc values and DM
% data
DIR_INPUT_OLD_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_DM_REPORT\DIR_INPUT_OLD_NC_FILES\';

% top directory of NEW input NetCDF files
DIR_INPUT_NEW_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_DM_REPORT\DIR_INPUT_NEW_NC_FILES\';

% top directory of output NetCDF updated files
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_DM_REPORT\OUT\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the xml report
DIR_XML_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\xml\';

% keep DM profile location information in output file
KEEP_PROFILE_LOCATION_FLAG =  1;

% information to set in 'HISTORY_REFERENCE (N_HISTORY, STRING64);' for the current action
global g_cocd_historyReferenceToReport;
g_cocd_historyReferenceToReport = HISTORY_REFERENCE;

% list of updated files
global g_cocd_updatedFileNameList;
g_cocd_updatedFileNameList = [];

% list of deleted files
global g_cocd_deletedFileNameList;
g_cocd_deletedFileNameList = [];

% flag to keep DM profile location
global g_cocd_reportProfLocFlag;
g_cocd_reportProfLocFlag = KEEP_PROFILE_LOCATION_FLAG;

% default values initialization
init_default_values;


logFileName = [];
status = 'nok';
try
   
   % startTime
   ticStartTime = tic;
   
   % store the start time of the run
   currentTime = datestr(now, 'yyyymmddTHHMMSSZ');
   
   % init the XML report
   init_xml_report(currentTime);
   
   % get input parameters
   [inputError] = parse_input_param(varargin);
   
   if (inputError == 0)

      % set parameter default values
      if (isempty(g_cocd_dirOutputXmlFile))
         g_cocd_dirOutputXmlFile = DIR_XML_FILE;
      end
      if (isempty(g_cocd_dirInputOldNcFiles))
         g_cocd_dirInputOldNcFiles = DIR_INPUT_OLD_NC_FILES;
      end
      if (isempty(g_cocd_dirInputNewNcFiles))
         g_cocd_dirInputNewNcFiles = DIR_INPUT_NEW_NC_FILES;
      end
      if (isempty(g_cocd_dirOutputNcFiles))
         g_cocd_dirOutputNcFiles = DIR_OUTPUT_NC_FILES;
      end
      if (isempty(g_cocd_ignoredParameterList))
         g_cocd_ignoredParameterList = IGNORED_PARAMETER_LIST;
      end
      if (isempty(g_cocd_dirLogFile))
         g_cocd_dirLogFile = DIR_LOG_FILE;
      end
      
      if (isempty(g_cocd_floatList))
         % all the floats of the g_cocd_dirInputNewNcFiles directory should be processed
         floatList = [];
         dirNames = dir([g_cocd_dirInputNewNcFiles '/*']);
         for idDir = 1:length(dirNames)
            
            dirName = dirNames(idDir).name;
            dirPathName = [g_cocd_dirInputQcNcFiles '/' dirName];
            
            if (isdir(dirPathName))
               if ~(strcmp(dirName, '.') || strcmp(dirName, '..'))
                  floatList = [floatList; str2num(dirName)];
               end
            end
         end
         g_cocd_floatList = floatList;
      end
      
      % log file creation
      if (~isempty(g_cocd_xmlReportFileName))
         logFileName = [g_cocd_dirLogFile '/nc_copy_mono_profile_dm_and_qc_rt_' g_cocd_xmlReportFileName(10:end-4) '.log'];
      else
         logFileName = [g_cocd_dirLogFile '/nc_copy_mono_profile_dm_and_qc_rt_' currentTime '.log'];
      end
      
      % process the files according to input and configuration parameters
      nc_copy_mono_profile_dm_and_qc_(g_cocd_floatList, logFileName, ...
         g_cocd_dirInputOldNcFiles, ...
         g_cocd_dirInputNewNcFiles, ...
         g_cocd_dirOutputNcFiles, ...
         g_cocd_ignoredParameterList, ...
         g_cocd_dirLogFile);
      
      % finalize XML report
      [status] = finalize_xml_report(ticStartTime, logFileName, []);
      
   else
      g_cocd_dirOutputXmlFile = DIR_XML_FILE;
   end
   
catch
   
   diary off;
   
   % finalize XML report
   [status] = finalize_xml_report(ticStartTime, logFileName, lasterror);
   
end

% create the XML report path file name
if (~isempty(g_cocd_xmlReportFileName))
   xmlFileName = [g_cocd_dirOutputXmlFile '/' g_cocd_xmlReportFileName];
else
   xmlFileName = [g_cocd_dirOutputXmlFile '/co041403_' currentTime '.xml'];
end

% save the XML report
xmlwrite(xmlFileName, g_cocd_xmlReportDOMNode);
% if (strcmp(status, 'nok') == 1)
%    edit(xmlFileName);
% end

return

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
%   07/18/2014 - RNU - creation
% ------------------------------------------------------------------------------
function init_xml_report(a_time)

% DOM node of XML report
global g_cocd_xmlReportDOMNode;

% decoder version
global g_cocd_ncCopyMonoProfileQcVersion;


% initialize XML report
docNode = com.mathworks.xml.XMLUtils.createDocument('coriolis_function_report');
docRootNode = docNode.getDocumentElement;

newChild = docNode.createElement('function');
newChild.appendChild(docNode.createTextNode('co041403'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('comment');
newChild.appendChild(docNode.createTextNode('Argo Coriolis DM and Qc reporting tool (nc_copy_mono_profile_dm_and_qc_rt)'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('tool_version');
newChild.appendChild(docNode.createTextNode(g_cocd_ncCopyMonoProfileQcVersion));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('date');
newChild.appendChild(docNode.createTextNode(datestr(datenum(a_time, 'yyyymmddTHHMMSSZ'), 'dd/mm/yyyy HH:MM:SS')));
docRootNode.appendChild(newChild);

g_cocd_xmlReportDOMNode = docNode;

return

% ------------------------------------------------------------------------------
% Parse input parameters.
%
% SYNTAX :
%  [o_inputError] = parse_input_param(a_varargin)
%
% INPUT PARAMETERS :
%   a_varargin : input parameters
%
% OUTPUT PARAMETERS :
%   o_inputError : input error flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/18/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_inputError] = parse_input_param(a_varargin)

% output parameters initialization
o_inputError = 0;

global g_cocd_dirOutputXmlFile;
global g_cocd_xmlReportFileName;
global g_cocd_floatList;
global g_cocd_dirInputOldNcFiles;
global g_cocd_dirInputNewNcFiles;
global g_cocd_dirOutputNcFiles;
global g_cocd_ignoredParameterList;
global g_cocd_dirLogFile;

g_cocd_dirOutputXmlFile = [];
g_cocd_xmlReportFileName = [];
g_cocd_floatList = [];
g_cocd_dirInputOldNcFiles = [];
g_cocd_dirInputNewNcFiles = [];
g_cocd_dirOutputNcFiles = [];
g_cocd_ignoredParameterList = [];
g_cocd_dirLogFile = [];


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
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') - exit\n');
      o_inputError = 1;
      return
   else
      for id = 1:2:length(a_varargin)
         if (strcmpi(a_varargin{id}, 'xmlReportDir'))
            g_cocd_dirOutputXmlFile = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'xmlReport'))
            g_cocd_xmlReportFileName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'floatWmo'))
            g_cocd_floatList = str2num(a_varargin{id+1});
         elseif (strcmpi(a_varargin{id}, 'inputOldNcDir'))
            g_cocd_dirInputOldNcFiles = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'inputNewNcDir'))
            g_cocd_dirInputNewNcFiles = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'outputDir'))
            g_cocd_dirOutputNcFiles = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'ignoredparamList'))
            g_cocd_ignoredParameterList = eval(a_varargin{id+1});
         elseif (strcmpi(a_varargin{id}, 'logDir'))
            g_cocd_dirLogFile = a_varargin{id+1};
         else
            fprintf('WARNING: unexpected input argument (%s) - ignored\n', a_varargin{id});
         end
      end
   end
end

% check the xml report file name consistency
if (~isempty(g_cocd_xmlReportFileName))
   if (length(g_cocd_xmlReportFileName) < 29)
      fprintf('WARNING: inconsistent xml report file name (%s) expecting co041403_yyyymmddTHHMMSSZ[_PID].xml - ignored\n', g_cocd_xmlReportFileName);
      g_cocd_xmlReportFileName = [];
   end
end

return

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
%   05/12/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_status] = finalize_xml_report(a_ticStartTime, a_logFileName, a_error)

% DOM node of XML report
global g_cocd_xmlReportDOMNode;

% report information structure
global g_cocd_reportData;


% initalize final status
o_status = 'ok';

% finalize the report
docNode = g_cocd_xmlReportDOMNode;
docRootNode = docNode.getDocumentElement;

% list of processings done
for idFloat = 1:length(g_cocd_reportData)
   
   reportStruct = g_cocd_reportData(idFloat);
   
   newChild = docNode.createElement(sprintf('float_%d', idFloat));
   
   newChildBis = docNode.createElement('float_wmo');
   newChildBis.appendChild(docNode.createTextNode(num2str(reportStruct.floatNum)));
   newChild.appendChild(newChildBis);
   
   for idFile = 1:length(reportStruct.updatedFile)
      newChildBis = docNode.createElement('updated_file');
      textNode = reportStruct.updatedFile{idFile};
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
   
   for idFile = 1:length(reportStruct.deletedFile)
      newChildBis = docNode.createElement('deleted_file');
      textNode = reportStruct.deletedFile{idFile};
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
   
   for idFile = 1:length(reportStruct.errorProf)
      newChildBis = docNode.createElement('erroneous_profile');
      textNode = num2str(reportStruct.errorProf{idFile});
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
   
   if (~isempty(reportStruct.errorProf))
      o_status = 'nok';
   end
   
   docRootNode.appendChild(newChild);
end

% retrieve information from the log file
[infoMsg, warningMsg, errorMsg] = parse_log_file(a_logFileName);

if (~isempty(infoMsg))
   
   for idMsg = 1:length(infoMsg)
      newChild = docNode.createElement('info');
      textNode = infoMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
end

if (~isempty(warningMsg))
   
   for idMsg = 1:length(warningMsg)
      newChild = docNode.createElement('warning');
      textNode = warningMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
end

if (~isempty(errorMsg))
   
   for idMsg = 1:length(errorMsg)
      newChild = docNode.createElement('error');
      textNode = errorMsg{idMsg};
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

return

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
%   05/12/2013 - RNU - creation
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
      return
   end
   fileContents = textscan(fId, '%s', 'delimiter', '\n');
   fclose(fId);
   
   if (~isempty(fileContents))
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
            break
         end
      end
   end
end

return

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
%   01/02/2010 - RNU - creation
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

return
