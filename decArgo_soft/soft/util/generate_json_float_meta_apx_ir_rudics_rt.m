% ------------------------------------------------------------------------------
% Process meta-data exported from Coriolis data base and save it in individual
% json files.
%
% SYNTAX :
%  generate_json_float_meta_apx_ir_rudics_rt(varargin)
%
% INPUT PARAMETERS :
%   'floatMetaFileName' : meta-data file exported from Coriolis data base
%   'floatListFileName' : list of concerned floats
%   'outputJsonDirName' : directory of individual json float meta-data files
%   'outputLogDirName'  : directory of log files
%   'xmlReportDirName'  : directory of xml files
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
%   09/01/2017 - RNU - RT version added
% ------------------------------------------------------------------------------
function generate_json_float_meta_apx_ir_rudics_rt(varargin)

% input parameters
global g_cogj_floatMetaFileName;
global g_cogj_floatListFileName;
global g_cogj_outputJsonDirName;
global g_cogj_outputLogDirName;
global g_cogj_xmlReportDirName;

% DOM node of XML report
global g_cogj_xmlReportDOMNode;

% report information structure
global g_cogj_reportData;
g_cogj_reportData = [];


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
   [inputError, logLines] = parse_input_param(varargin);
   
   % log file creation
   if (~isempty(g_cogj_outputLogDirName))
      logFileName = [g_cogj_outputLogDirName '/generate_json_float_meta_apx_ir_rudics_rt_' currentTime '.log'];
   else
      logFileName = [tempdir '/generate_json_float_meta_apx_ir_rudics_rt_' currentTime '.log'];
   end
   
   diary(logFileName);
   
   fprintf('Log file: %s\n', logFileName);

   if (~isempty(logLines))
      fprintf('%s', logLines{:});
   end
   
   if (~inputError)
      % generate JSON meta-data files
      generate_json_float_meta_apx_ir_rudics_(...
         g_cogj_floatMetaFileName, ...
         g_cogj_floatListFileName, ...
         g_cogj_outputJsonDirName);
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
if (~isempty(g_cogj_xmlReportDirName))
   xmlFileName = [g_cogj_xmlReportDirName '/generate_json_float_meta_apx_ir_rudics_rt_' currentTime '.xml'];
else
   xmlFileName = [tempdir '/generate_json_float_meta_apx_ir_rudics_rt_' currentTime '.xml'];
end

% save the XML report
xmlwrite(xmlFileName, g_cogj_xmlReportDOMNode);
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
%   09/01/2017 - RNU - creation
% ------------------------------------------------------------------------------
function init_xml_report(a_time)

% DOM node of XML report
global g_cogj_xmlReportDOMNode;


% initialize XML report
docNode = com.mathworks.xml.XMLUtils.createDocument('coriolis_function_report');
docRootNode = docNode.getDocumentElement;

newChild = docNode.createElement('function');
newChild.appendChild(docNode.createTextNode('co041407'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('comment');
newChild.appendChild(docNode.createTextNode('Argo Coriolis float meta-data json file generating tool (generate_json_float_meta_apx_ir_rudics_rt)'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('date');
newChild.appendChild(docNode.createTextNode(datestr(datenum(a_time, 'yyyymmddTHHMMSSZ'), 'dd/mm/yyyy HH:MM:SS')));
docRootNode.appendChild(newChild);

g_cogj_xmlReportDOMNode = docNode;

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
%   09/01/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_inputError, o_logLines] = parse_input_param(a_varargin)

% output parameters initialization
o_inputError = 0;
o_logLines = [];

global g_cogj_floatMetaFileName;
global g_cogj_floatListFileName;
global g_cogj_outputJsonDirName;
global g_cogj_outputLogDirName;
global g_cogj_xmlReportDirName;

g_cogj_floatMetaFileName = [];
g_cogj_floatListFileName = [];
g_cogj_outputJsonDirName = [];
g_cogj_outputLogDirName = [];
g_cogj_xmlReportDirName = [];


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
      o_logLines{end+1} = sprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') - exit\n');
      o_inputError = 1;
      return
   else
      for id = 1:2:length(a_varargin)
         if (strcmpi(a_varargin{id}, 'floatMetaFileName'))
            g_cogj_floatMetaFileName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'floatListFileName'))
            g_cogj_floatListFileName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'outputJsonDirName'))
            g_cogj_outputJsonDirName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'outputLogDirName'))
            g_cogj_outputLogDirName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'xmlReportDirName'))
            g_cogj_xmlReportDirName = a_varargin{id+1};
         else
            o_logLines{end+1} = sprintf('WARNING: unexpected input argument (''%s'') - ignored\n', a_varargin{id});
         end
      end
   end
end

% all expected parameters are mandatory
if (isempty(g_cogj_floatMetaFileName))
   o_logLines{end+1} = sprintf('ERROR: ''floatMetaFileName'' input parameter is mandatory\n');
   o_inputError = 1;
   return
end
if (isempty(g_cogj_floatListFileName))
   o_logLines{end+1} = sprintf('ERROR: ''floatListFileName'' input parameter is mandatory\n');
   o_inputError = 1;
   return
end
if (isempty(g_cogj_outputJsonDirName))
   o_logLines{end+1} = sprintf('ERROR: ''outputJsonDirName'' input parameter is mandatory\n');
   o_inputError = 1;
   return
end
if (isempty(g_cogj_outputLogDirName))
   o_logLines{end+1} = sprintf('ERROR: ''outputLogDirName'' input parameter is mandatory\n');
   o_inputError = 1;
   return
end
if (isempty(g_cogj_xmlReportDirName))
   o_logLines{end+1} = sprintf('ERROR: ''xmlReportDirName'' input parameter is mandatory\n');
   o_inputError = 1;
   return
end

o_logLines{end+1} = sprintf('INPUT PARAMETERS\n');
o_logLines{end+1} = sprintf('floatMetaFileName: %s\n', g_cogj_floatMetaFileName);
o_logLines{end+1} = sprintf('floatListFileName: %s\n', g_cogj_floatListFileName);
o_logLines{end+1} = sprintf('outputJsonDirName: %s\n', g_cogj_outputJsonDirName);
o_logLines{end+1} = sprintf('outputLogDirName: %s\n', g_cogj_outputLogDirName);
o_logLines{end+1} = sprintf('xmlReportDirName: %s\n', g_cogj_xmlReportDirName);
o_logLines{end+1} = sprintf('\n');

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
%   09/01/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_status] = finalize_xml_report(a_ticStartTime, a_logFileName, a_error)

% DOM node of XML report
global g_cogj_xmlReportDOMNode;

% report information structure
global g_cogj_reportData;


% initalize final status
o_status = 'ok';

% finalize the report
docNode = g_cogj_xmlReportDOMNode;
docRootNode = docNode.getDocumentElement;

% list of generated files
newChild = docNode.createElement('generated_files');
for idFile = 1:length(g_cogj_reportData)
   newChildBis = docNode.createElement('generated_file');
   textNode = g_cogj_reportData{idFile};
   newChildBis.appendChild(docNode.createTextNode(textNode));
   newChild.appendChild(newChildBis);
end
docRootNode.appendChild(newChild);

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
%   09/01/2017 - RNU - creation
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
%   09/01/2017 - RNU - creation
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
