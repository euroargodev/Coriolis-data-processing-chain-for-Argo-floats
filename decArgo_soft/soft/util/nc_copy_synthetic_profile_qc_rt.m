% ------------------------------------------------------------------------------
% Report SCOOP QC from a Qc file (DIR_INPUT_QC_NC_FILES) to associated C-PROF
% and/or B-PROF files.
%
% 1- The Qc file is expected to have the same parameter measurements as the
% S-PROF file. The <PARAM>_dPRES parameters are retrieved from the S-PROF file
% (expected to be in the DIR_INPUT_GDAC_NC_FILES directory). Only QC of levels
% where <PARAM>_dPRES = 0 are reported to associated C-PROF and/or B-PROF files.
%
% 2- Reported SCOOP QC are retrieved from HISTORY section of Qc file under the
% constrains HISTORY_SOFTWARE = 'SCOO' and HISTORY_ACTION = 'CF', then
% HISTORY_PARAMETER =
% - <PARAM> => update <PARAM>_QC (<PARAM> can be adjusted parameter name)
% - 'DAT$'  => update JULD_QC
% - 'POS$'  => update POSITION_QC
%
% 3- Input files to update are first searched in DIR_OUTPUT_NC_FILES, then in
% DIR_INPUT_EDAC_NC_FILES
%
% 4- When QC updates modify at least one QC of the target file, it is updated.
% The SCOOP QC entries of the HISTORY section of the Qc file are then duplicated
% in the associated C-PROF and/or B-PROF files (depending on HISTORY_PARAMETER).
%
% SYNTAX :
%   nc_copy_synthetic_profile_qc_rt(varargin)
%
% INPUT PARAMETERS :
%   no mandatory input parameters.
%   input parameter names are not case sensitive.
%   possible input parameters:
%      xmlReportDir : directory to store the XML report
%      xmlReport    : file name of the XML report
%      floatWmo     : float to process (if not given: all the floats of the Qc
%                     directory are processed)
%      inputQcDir   : top directory of input NetCDF files containing the Qc
%                     values
%      inputEdacDir : top directory of input NetCDF files to be updated
%      inputGdacDir : top directory of input S-PROF and META NetCDF files
%      outputDir    : top directory of output NetCDF updated files
%      logDir       : directory to store the log file
%      csvDir       : directory to store the CSV file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/20/2023 - RNU - V 1.0: creation
%   11/28/2023 - RNU - V 1.1: anomaly in copy of SCOOP action from QC file to C
%                             or B PROF file.
%   12/04/2023 - RNU - V 1.2: uninitialized variable.
%   01/22/2024 - RNU - V 1.3: uninitialized variable.
% ------------------------------------------------------------------------------
function nc_copy_synthetic_profile_qc_rt(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START

% top directory of input NetCDF files containing the Qc values
% (top directory of the DAC name directories)
DIR_INPUT_QC_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_REPORT_QC_SPROF_PROF2\TEST_20231003\dbqc\';

% top directory of input NetCDF files to be updated
% (E-DAC, thus top directory of the DAC name directories)
DIR_INPUT_EDAC_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_REPORT_QC_SPROF_PROF2\TEST_20231003\edac\';

% top directory of input S-PROF and META NetCDF files
% (G-DAC, thus top directory of the DAC name directories)
DIR_INPUT_GDAC_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_REPORT_QC_SPROF_PROF2\TEST_20231003\gdac\';

% top directory of output NetCDF updated files
% (top directory of the DAC name directories)
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_REPORT_QC_SPROF_PROF2\TEST_20231003\out\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log';

% directory to store the csv file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv';

% directory to store the xml report
DIR_XML_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\xml\';

% flag to print QC updated values
VERBOSE_MODE = 0;

% CONFIGURATION - END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global g_cocsq_dirOutputXmlFile;
global g_cocsq_xmlReportFileName;
global g_cocsq_floatList;
global g_cocsq_dirInputQcNcFiles;
global g_cocsq_dirInputEdacNcFiles;
global g_cocsq_dirInputGdacNcFiles;
global g_cocsq_dirOutputNcFiles;
global g_cocsq_dirLogFile;
global g_cocsq_dirCsvFile;

% RT processing flag
global g_cocsq_realtimeFlag;
g_cocsq_realtimeFlag = 1;

% program version
global g_cocsq_ncCopySyntheticProfileQcVersion;
g_cocsq_ncCopySyntheticProfileQcVersion = '1.3';

% DOM node of XML report
global g_cocsq_xmlReportDOMNode;

% XML report information structure
global g_cocsq_reportXmlData;
g_cocsq_reportXmlData = [];

% date of the run
global g_cocsq_nowUtc;
g_cocsq_nowUtc = now_utc;

global g_cocsq_verboseMode;
g_cocsq_verboseMode = VERBOSE_MODE;

% default values initialization
init_default_values;


logFileName = [];
status = 'nok';
try
   
   % startTime
   ticStartTime = tic;
   
   % store the start time of the run
   currentTime = datestr(g_cocsq_nowUtc, 'yyyymmddTHHMMSSZ');
   
   % init the XML report
   init_xml_report(currentTime);
   
   % get input parameters
   [inputError] = parse_input_param(varargin);
   
   if (inputError == 0)
      
      % set parameter default values
      if (isempty(g_cocsq_dirOutputXmlFile))
         g_cocsq_dirOutputXmlFile = DIR_XML_FILE;
      end
      if (isempty(g_cocsq_dirInputQcNcFiles))
         g_cocsq_dirInputQcNcFiles = DIR_INPUT_QC_NC_FILES;
      end
      if (isempty(g_cocsq_dirInputEdacNcFiles))
         g_cocsq_dirInputEdacNcFiles = DIR_INPUT_EDAC_NC_FILES;
      end
      if (isempty(g_cocsq_dirInputGdacNcFiles))
         g_cocsq_dirInputGdacNcFiles = DIR_INPUT_GDAC_NC_FILES;
      end
      if (isempty(g_cocsq_dirOutputNcFiles))
         g_cocsq_dirOutputNcFiles = DIR_OUTPUT_NC_FILES;
      end
      if (isempty(g_cocsq_dirLogFile))
         g_cocsq_dirLogFile = DIR_LOG_FILE;
      end
      if (isempty(g_cocsq_dirCsvFile))
         g_cocsq_dirCsvFile = DIR_CSV_FILE;
      end
      
      if (isempty(g_cocsq_floatList))
         % all the floats of the g_cocsq_dirInputQcNcFiles directory should be processed
         floatList = [];
         dirNames1 = dir(g_cocsq_dirInputQcNcFiles);
         for idDir1 = 1:length(dirNames1)

            dirName1 = dirNames1(idDir1).name;
            if (strcmp(dirName1, '.') || strcmp(dirName1, '..'))
               continue
            end
            dirPathName1 = [g_cocsq_dirInputQcNcFiles '/' dirName1];

            dirNames2 = dir(dirPathName1);
            for idDir2 = 1:length(dirNames2)

               dirName2 = dirNames2(idDir2).name;
               if (strcmp(dirName2, '.') || strcmp(dirName2, '..'))
                  continue
               end
               floatList = [floatList; str2num(dirName2)];
            end
         end
         g_cocsq_floatList = floatList;
      end

      % log file creation
      if (~isempty(g_cocsq_xmlReportFileName))
         logFileName = [g_cocsq_dirLogFile '/nc_copy_synthetic_profile_qc_rt_' g_cocsq_xmlReportFileName(10:end-4) '.log'];
      else
         logFileName = [g_cocsq_dirLogFile '/nc_copy_synthetic_profile_qc_rt_' currentTime '.log'];
      end
      
      % process the files according to input and configuration parameters
      nc_copy_synthetic_profile_qc_(g_cocsq_floatList, logFileName, ...
         g_cocsq_dirInputQcNcFiles, ...
         g_cocsq_dirInputEdacNcFiles, ...
         g_cocsq_dirInputGdacNcFiles, ...
         g_cocsq_dirOutputNcFiles, ...
         g_cocsq_dirLogFile, ...
         g_cocsq_dirCsvFile);
      
      % finalize XML report
      [status] = finalize_xml_report(ticStartTime, logFileName, []);
      
   else
      g_cocsq_dirOutputXmlFile = DIR_XML_FILE;
   end
   
catch
   
   diary off;
   
   % finalize XML report
   [status] = finalize_xml_report(ticStartTime, logFileName, lasterror);
   
end

% create the XML report path file name
if (~isempty(g_cocsq_xmlReportFileName))
   xmlFileName = [g_cocsq_dirOutputXmlFile '/' g_cocsq_xmlReportFileName];
else
   xmlFileName = [g_cocsq_dirOutputXmlFile '/co041403_' currentTime '.xml'];
end

% save the XML report
xmlwrite(xmlFileName, g_cocsq_xmlReportDOMNode);
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
%   09/20/2023 - RNU - creation
% ------------------------------------------------------------------------------
function init_xml_report(a_time)

% DOM node of XML report
global g_cocsq_xmlReportDOMNode;

% program version
global g_cocsq_ncCopySyntheticProfileQcVersion;


% initialize XML report
docNode = com.mathworks.xml.XMLUtils.createDocument('coriolis_function_report');
docRootNode = docNode.getDocumentElement;

newChild = docNode.createElement('function');
newChild.appendChild(docNode.createTextNode('co041403'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('comment');
newChild.appendChild(docNode.createTextNode('Argo Coriolis Qc reporting tool (nc_copy_synthetic_profile_qc_rt)'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('tool_version');
newChild.appendChild(docNode.createTextNode(g_cocsq_ncCopySyntheticProfileQcVersion));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('date');
newChild.appendChild(docNode.createTextNode(datestr(datenum(a_time, 'yyyymmddTHHMMSSZ'), 'dd/mm/yyyy HH:MM:SS')));
docRootNode.appendChild(newChild);

g_cocsq_xmlReportDOMNode = docNode;

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
%   09/20/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_inputError] = parse_input_param(a_varargin)

% output parameters initialization
o_inputError = 0;

global g_cocsq_dirOutputXmlFile;
global g_cocsq_xmlReportFileName;
global g_cocsq_floatList;
global g_cocsq_dirInputQcNcFiles;
global g_cocsq_dirInputEdacNcFiles;
global g_cocsq_dirInputGdacNcFiles;
global g_cocsq_dirOutputNcFiles;
global g_cocsq_dirLogFile;
global g_cocsq_dirCsvFile;

g_cocsq_dirOutputXmlFile = [];
g_cocsq_xmlReportFileName = [];
g_cocsq_floatList = [];
g_cocsq_dirInputQcNcFiles = [];
g_cocsq_dirInputEdacNcFiles = [];
g_cocsq_dirInputGdacNcFiles = [];
g_cocsq_dirOutputNcFiles = [];
g_cocsq_dirLogFile = [];
g_cocsq_dirCsvFile = [];


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
            g_cocsq_dirOutputXmlFile = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'xmlReport'))
            g_cocsq_xmlReportFileName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'floatWmo'))
            g_cocsq_floatList = str2num(a_varargin{id+1});
         elseif (strcmpi(a_varargin{id}, 'inputQcDir'))
            g_cocsq_dirInputQcNcFiles = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'inputEdacDir'))
            g_cocsq_dirInputEdacNcFiles = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'inputGdacDir'))
            g_cocsq_dirInputGdacNcFiles = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'outputDir'))
            g_cocsq_dirOutputNcFiles = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'logDir'))
            g_cocsq_dirLogFile = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'csvDir'))
            g_cocsq_dirCsvFile = a_varargin{id+1};
         else
            fprintf('WARNING: unexpected input argument (%s) - ignored\n', a_varargin{id});
         end
      end
   end
end

% check the xml report file name consistency
if (~isempty(g_cocsq_xmlReportFileName))
   if (length(g_cocsq_xmlReportFileName) < 29)
      fprintf('WARNING: inconsistent xml report file name (%s) expecting co041403_yyyymmddTHHMMSSZ[_PID].xml - ignored\n', g_cocsq_xmlReportFileName);
      g_cocsq_xmlReportFileName = [];
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
%   09/20/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_status] = finalize_xml_report(a_ticStartTime, a_logFileName, a_error)

% DOM node of XML report
global g_cocsq_xmlReportDOMNode;

% report information structure
global g_cocsq_reportXmlData;


% initalize final status
o_status = 'ok';

% finalize the report
docNode = g_cocsq_xmlReportDOMNode;
docRootNode = docNode.getDocumentElement;

% list of processings done
for idFloat = 1:length(g_cocsq_reportXmlData)
   
   reportStruct = g_cocsq_reportXmlData(idFloat);
   
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
%   09/20/2023 - RNU - creation
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
%   09/20/2023 - RNU - creation
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
