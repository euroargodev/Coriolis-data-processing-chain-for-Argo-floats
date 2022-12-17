% ------------------------------------------------------------------------------
% Create a new set of NetCDF mono-profile files by adding Qc flags (provided in
% NetCDF unique-profile (N_PROF = 1) files).
%
% SYNTAX :
%   nc_copy_mono_profile_qc_rt(varargin)
%
% INPUT PARAMETERS :
%   no mandatory input parameters.
%   input parameter names are not case sensitive.
%   possible input parameters:
%      xmlReportDir   : directory to store the XML report
%      xmlReport      : file name of the XML report
%      floatWmo       : float to process (if not given: all the floats of the Qc
%                       directory are processed)
%      inputQcDir     : directory of input NetCDF files containing the Qc values
%      inputDir     : directory of input NetCDF files to be updated
%      outputDir      : directory of output NetCDF updated files
%      logDir         : directory to store the log file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/18/2014 - RNU - creation (V 2.0)
%   10/28/2014 - RNU - V 2.1: in get_nc_profile_info, the comparison is done
%                             using the format '%.5f' (because bio data are
%                             rounded to 1E-5 in the Coriolis data base)
%   12/23/2014 - RNU - V 2.2: the temporary directory, used to duplicate the
%                             input file before updating its QC values, is now
%                             created in the DIR_INPUT_QC_NC_FILES/WMO/
%                             directory
%   01/14/2015 - RNU - V 2.3: before the string conversion (for the comparison),
%                             the data are rounded to 1.E-5 and the negative
%                             zeros converted to positive ones.
%   01/16/2015 - RNU - V 2.4: manage the case where there is no data in a B file
%                             for a given profile.
%   02/27/2015 - RNU - V 2.5: - in 'c' files, report <PARAM>_ADJUSTED_QC if the
%                             DATA_MODE of the concerned profile is 'A' or 'D'
%                             - in 'b' files, report <PARAM>_ADJUSTED_QC if the
%                             PARAMETER_DATA_MODE of the concerned profile and
%                             parameter is 'A' or 'D'
%   07/03/2015 - RNU - V 2.6: there is only one input directory for the nc files
%                             to be updated (this is the executive DAC). The
%                             first level sub-directories of this executive DAC
%                             are scanned when looking for the file to update.
%   07/06/2015 - RNU - V 2.7: the nc input file to update can have levels where
%                             PRES = FillValue, these levels are not present in
%                             the nc input file containing the QC values.
%   07/07/2015 - RNU - V 2.8: since V 2.7, final QC merged values can differ
%                             from input QC file ones. The PROFILE_<PARAM>_QC
%                             values should then be computed from final QC
%                             merged values (in the previous versions they were
%                             copied from input Qc file  ones.
%   10/20/2015 - RNU - V 2.9: when a D c-file to be updated is found, the
%                             associated b-file can be in D or in R mode.
%   07/11/2016 - RNU - V 3.0: new management of HISTORY information:
%                             - existing HISTORY information of input files is
%                             kept
%                             - HISTORY information of QC file (reporting
%                             Coriolis SCOOP tool actions) is copied in 'c'
%                             or 'b' files (according to HISTORY_PARAMETER
%                             information)
%                             - a last HISTORY step is added to report the use
%                             of the current tool (COCQ)
%   09/28/2016 - RNU - V 3.1: HISTORY information of QC file (reporting Coriolis
%                             Objective Analysis and SCOOP tool actions) is
%                             copied in 'c' or 'b' files (according to
%                             HISTORY_PARAMETER information) only for HISTORY
%                             steps where HISTORY_SOFTWARE is in a pre-defined
%                             list (g_cocq_historySoftwareToReport).
%   10/17/2016 - RNU - V 3.2: Also manage QC flags of adjusted parameters.
%   06/23/2021 - RNU - V 3.3: String comparison is not suitable in some cases
%                             (see DOXY value for PRES level 733.59998 dbar of
%                             6902964 #127) we then compare data measurements
%                             (which should not exceed a 1.e-5 interval).
%   07/01/2021 - RNU - V 3.4: Before comparison, PRES data are rounded to 1.e-3
%                             and other parameters to 1.e-5.
% ------------------------------------------------------------------------------
function nc_copy_mono_profile_qc_rt(varargin)

global g_cocq_dirOutputXmlFile;
global g_cocq_xmlReportFileName;
global g_cocq_floatList;
global g_cocq_dirInputQcNcFiles;
global g_cocq_dirInputNcFiles;
global g_cocq_dirOutputNcFiles;
global g_cocq_dirLogFile;

% RT processing flag
global g_cocq_realtimeFlag;
g_cocq_realtimeFlag = 1;

% program version
global g_cocq_ncCopyMonoProfileQcVersion;
g_cocq_ncCopyMonoProfileQcVersion = '3.4';

% DOM node of XML report
global g_cocq_xmlReportDOMNode;

% report information structure
global g_cocq_reportData;
g_cocq_reportData = [];

% list of HISTORY_SOFTWARE that should be reported from the QC file to the
% output file
global g_cocq_historySoftwareToReport;
g_cocq_historySoftwareToReport = [ ...
   {'COOA'} ...
   {'SCOO'} ...
   ];

% top directory of input NetCDF files containing the Qc values
DIR_INPUT_QC_NC_FILES = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\TEST_20210630\dbqc\';

% top directory of input NetCDF files to be updated (executive DAC, thus top
% directory of the DAC name directories)
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\TEST_20210630\edac\';

% top directory of output NetCDF updated files
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\TEST_20210630\out\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log';

% directory to store the xml report
DIR_XML_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\xml\';

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
      if (isempty(g_cocq_dirOutputXmlFile))
         g_cocq_dirOutputXmlFile = DIR_XML_FILE;
      end
      if (isempty(g_cocq_dirInputQcNcFiles))
         g_cocq_dirInputQcNcFiles = DIR_INPUT_QC_NC_FILES;
      end
      if (isempty(g_cocq_dirInputNcFiles))
         g_cocq_dirInputNcFiles = DIR_INPUT_NC_FILES;
      end
      if (isempty(g_cocq_dirOutputNcFiles))
         g_cocq_dirOutputNcFiles = DIR_OUTPUT_NC_FILES;
      end
      if (isempty(g_cocq_dirLogFile))
         g_cocq_dirLogFile = DIR_LOG_FILE;
      end
      
      if (isempty(g_cocq_floatList))
         % all the floats of the g_cocq_dirInputQcNcFiles directory should be processed
         floatList = [];
         dirNames = dir([g_cocq_dirInputQcNcFiles '/*']);
         for idDir = 1:length(dirNames)
            
            dirName = dirNames(idDir).name;
            dirPathName = [g_cocq_dirInputQcNcFiles '/' dirName];
            
            if (isdir(dirPathName))
               if ~(strcmp(dirName, '.') || strcmp(dirName, '..'))
                  floatList = [floatList; str2num(dirName)];
               end
            end
         end
         g_cocq_floatList = floatList;
      end
      
      % log file creation
      if (~isempty(g_cocq_xmlReportFileName))
         logFileName = [g_cocq_dirLogFile '/nc_copy_mono_profile_qc_rt_' g_cocq_xmlReportFileName(10:end-4) '.log'];
      else
         logFileName = [g_cocq_dirLogFile '/nc_copy_mono_profile_qc_rt_' currentTime '.log'];
      end
      
      % process the files according to input and configuration parameters
      nc_copy_mono_profile_qc_(g_cocq_floatList, logFileName, ...
         g_cocq_dirInputQcNcFiles, ...
         g_cocq_dirInputNcFiles, ...
         g_cocq_dirOutputNcFiles, ...
         g_cocq_dirLogFile);
      
      % finalize XML report
      [status] = finalize_xml_report(ticStartTime, logFileName, []);
      
   else
      g_cocq_dirOutputXmlFile = DIR_XML_FILE;
   end
   
catch
   
   diary off;
   
   % finalize XML report
   [status] = finalize_xml_report(ticStartTime, logFileName, lasterror);
   
end

% create the XML report path file name
if (~isempty(g_cocq_xmlReportFileName))
   xmlFileName = [g_cocq_dirOutputXmlFile '/' g_cocq_xmlReportFileName];
else
   xmlFileName = [g_cocq_dirOutputXmlFile '/co041403_' currentTime '.xml'];
end

% save the XML report
xmlwrite(xmlFileName, g_cocq_xmlReportDOMNode);
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
global g_cocq_xmlReportDOMNode;

% decoder version
global g_cocq_ncCopyMonoProfileQcVersion;


% initialize XML report
docNode = com.mathworks.xml.XMLUtils.createDocument('coriolis_function_report');
docRootNode = docNode.getDocumentElement;

newChild = docNode.createElement('function');
newChild.appendChild(docNode.createTextNode('co041403'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('comment');
newChild.appendChild(docNode.createTextNode('Argo Coriolis Qc reporting tool (nc_copy_mono_profile_qc_rt)'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('tool_version');
newChild.appendChild(docNode.createTextNode(g_cocq_ncCopyMonoProfileQcVersion));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('date');
newChild.appendChild(docNode.createTextNode(datestr(datenum(a_time, 'yyyymmddTHHMMSSZ'), 'dd/mm/yyyy HH:MM:SS')));
docRootNode.appendChild(newChild);

g_cocq_xmlReportDOMNode = docNode;

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

global g_cocq_dirOutputXmlFile;
global g_cocq_xmlReportFileName;
global g_cocq_floatList;
global g_cocq_dirInputQcNcFiles;
global g_cocq_dirInputNcFiles;
global g_cocq_dirOutputNcFiles;
global g_cocq_dirLogFile;

g_cocq_dirOutputXmlFile = [];
g_cocq_xmlReportFileName = [];
g_cocq_floatList = [];
g_cocq_dirInputQcNcFiles = [];
g_cocq_dirInputNcFiles = [];
g_cocq_dirOutputNcFiles = [];
g_cocq_dirLogFile = [];


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
            g_cocq_dirOutputXmlFile = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'xmlReport'))
            g_cocq_xmlReportFileName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'floatWmo'))
            g_cocq_floatList = str2num(a_varargin{id+1});
         elseif (strcmpi(a_varargin{id}, 'inputQcDir'))
            g_cocq_dirInputQcNcFiles = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'inputDir'))
            g_cocq_dirInputNcFiles = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'outputDir'))
            g_cocq_dirOutputNcFiles = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'logDir'))
            g_cocq_dirLogFile = a_varargin{id+1};
         else
            fprintf('WARNING: unexpected input argument (%s) - ignored\n', a_varargin{id});
         end
      end
   end
end

% check the xml report file name consistency
if (~isempty(g_cocq_xmlReportFileName))
   if (length(g_cocq_xmlReportFileName) < 29)
      fprintf('WARNING: inconsistent xml report file name (%s) expecting co041403_yyyymmddTHHMMSSZ[_PID].xml - ignored\n', g_cocq_xmlReportFileName);
      g_cocq_xmlReportFileName = [];
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
global g_cocq_xmlReportDOMNode;

% report information structure
global g_cocq_reportData;


% initalize final status
o_status = 'ok';

% finalize the report
docNode = g_cocq_xmlReportDOMNode;
docRootNode = docNode.getDocumentElement;

% list of processings done
for idFloat = 1:length(g_cocq_reportData)
   
   reportStruct = g_cocq_reportData(idFloat);
   
   newChild = docNode.createElement(sprintf('float_%d', idFloat));
   
   newChildBis = docNode.createElement('float_wmo');
   newChildBis.appendChild(docNode.createTextNode(num2str(reportStruct.floatNum)));
   newChild.appendChild(newChildBis);
   
   for idFile = 1:length(reportStruct.input_ok)
      newChildBis = docNode.createElement('ok_file_in');
      textNode = reportStruct.input_ok{idFile};
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
   
   for idFile = 1:length(reportStruct.output_ok)
      newChildBis = docNode.createElement('ok_file_out');
      textNode = reportStruct.output_ok{idFile};
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
   
   for idFile = 1:length(reportStruct.profNum_ok)
      newChildBis = docNode.createElement('ok_prof_num');
      textNode = num2str(reportStruct.profNum_ok{idFile});
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
   
   for idFile = 1:length(reportStruct.input_ko)
      newChildBis = docNode.createElement('ko_file_in');
      textNode = reportStruct.input_ko{idFile};
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
   if (~isempty(reportStruct.input_ko))
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
