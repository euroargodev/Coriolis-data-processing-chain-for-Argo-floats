% ------------------------------------------------------------------------------
% Update the META.json files: add END_DECODING_DATE information.
%
% SYNTAX :
%   update_meta_json_set_END_DECODING_DATE or
%   update_meta_json_set_END_DECODING_DATE(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : WMO number of floats to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/22/2022 - RNU - creation
% ------------------------------------------------------------------------------
function update_meta_json_set_END_DECODING_DATE(varargin)

% list of floats to process (if empty, all encountered files will be checked)
FLOAT_LIST_FILE_NAME = '';

% directory of META.json files to update
DIR_INPUT_OUTPUT_JSON_FILES = 'C:\Users\jprannou\_DATA\END_DECODING_DATE\IN_OUT\json_float_meta\';

% input CSV file of CRUISE_NAME values to use
DIR_INPUT_CSV_FILE = 'C:\Users\jprannou\_DATA\END_DECODING_DATE\db_export_END_DECODING_DATE.csv';

% temporary directory used to update the files
DIR_TMP = 'C:\Users\jprannou\_DATA\OUT\tmp\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the XML file
DIR_XML_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\xml\';

% DOM node of XML report
global g_couf_xmlReportDOMNode;

% report information structure
global g_couf_floatNum;
global g_couf_reportData;
g_couf_reportData = [];
g_couf_reportData.metaFile = [];
g_couf_reportData.float = [];


% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'update_meta_json_set_END_DECODING_DATE_' currentTime '.log'];
diary(logFile);

% startTime
ticStartTime = tic;

try
   
   % init the XML report
   init_xml_report(currentTime);
   
   % input parameters management
   floatList = [];
   if (nargin == 0)
      if (~isempty(FLOAT_LIST_FILE_NAME))
         floatListFileName = FLOAT_LIST_FILE_NAME;
         
         % floats to process come from floatListFileName
         if ~(exist(floatListFileName, 'file') == 2)
            fprintf('ERROR: File not found: %s\n', floatListFileName);
            return
         end
         
         fprintf('Floats from list: %s\n', floatListFileName);
         floatList = load(floatListFileName);
      end
   else
      % floats to process come from input parameters
      floatList = cell2mat(varargin);
   end

   if ~(exist(DIR_INPUT_CSV_FILE, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', DIR_INPUT_CSV_FILE);
      return
   end

   % read CSV file of input information
   fId = fopen(DIR_INPUT_CSV_FILE, 'r');
   if (fId == -1)
      fprintf('ERROR: Unable to open file: %s\n', DIR_INPUT_CSV_FILE);
      return
   end
   fileContents = textscan(fId, '%s', 'delimiter', ';');
   fileContents = fileContents{:};
   fclose(fId);

   if (rem(size(fileContents, 1), 5) ~= 0)
      fprintf('ERROR: Unable to parse file: %s\n', DIR_INPUT_CSV_FILE);
      return
   end

   inputData = reshape(fileContents, 5, size(fileContents, 1)/5)';
   clear fileContents

   if (size(inputData, 1) == 1)
      fprintf('WARNING: Empty file: %s\n', DIR_INPUT_CSV_FILE);
      clear inputData
      return
   end

   idF = find(strcmp(inputData(:, 2), '831'));
   wmoList = cellfun(@str2num, inputData(idF, 1));
   dataList = inputData(idF, 4);

   % create a temporary directory for this run
   tmpDir = [DIR_TMP '/' 'update_meta_json_set_END_DECODING_DATE_' currentTime];
   status = mkdir(tmpDir);
   if (status ~= 1)
      fprintf('ERROR: cannot create temporary directory (%s)\n', tmpDir);
   end

   % META.json files
   floatFiles = dir([DIR_INPUT_OUTPUT_JSON_FILES '/*_meta.json']);
   for idFile = 1:length(floatFiles)

      floatFileName = floatFiles(idFile).name;
      idFUs = strfind(floatFileName, '_');
      floatWmo = str2double(floatFileName(1:idFUs-1));

      if ((isempty(floatList)) || (~isempty(floatList) && ismember(floatWmo, floatList)))

         fprintf('%03d/%03d %d\n', idFile, length(floatFiles), floatWmo);
         g_couf_floatNum = floatWmo;

         % find input data for this float
         idF = find(wmoList == floatWmo);
         if (length(idF) > 1)
            fprintf('ERROR: Float %d: multiple (%d) lines in file : %s\n', ...
               floatWmo, ...
               length(idF), ...
               DIR_INPUT_CSV_FILE);
            continue
         end

         dataFloat = '';
         if (~isempty(idF))
            dataFloat = strtrim(dataList{idF});
         end

         if ~(isempty(dataFloat) || length(dataFloat) == 14)
            fprintf('ERROR: Float %d: length (%d) of input data (''%s'') is not the expected one (14)\n', ...
               floatWmo, ...
               length(dataFloat), ...
               dataFloat);
            continue
         end

         floatFilePathName = [DIR_INPUT_OUTPUT_JSON_FILES '/' floatFileName];
         if (exist(floatFilePathName, 'file') == 2)
            process_json_file(floatFilePathName, tmpDir, format_date(dataFloat));
         end
      end
   end

   % remove the temporary directory of this run
   [status, message, messageid] = rmdir(tmpDir,'s');
   if (status ~= 1)
      fprintf('ERROR: cannot remove temporary directory (%s)\n', tmpDir);
   end
   
   diary off;
   
   % finalize XML report
   [status] = finalize_xml_report(ticStartTime, logFile, []);
   
catch
   
   diary off;
   
   % finalize XML report
   [status] = finalize_xml_report(ticStartTime, logFile, lasterror);
   
end

% create the XML report path file name
xmlFileName = [DIR_XML_FILE '/co041405_' currentTime '.xml'];

% save the XML report
xmlwrite(xmlFileName, g_couf_xmlReportDOMNode);
% if (strcmp(status, 'nok') == 1)
%    edit(xmlFileName);
% end

return

% ------------------------------------------------------------------------------
% Process one META.json file.
%
% SYNTAX :
%  process_json_file(a_jsonPathFileName, a_tmpDir, a_inputData)
%
% INPUT PARAMETERS :
%   a_jsonPathFileName : name of the file to process
%   a_tmpDir           : available temporary directory
%   a_inputData        : input data to update
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/23/2022 - RNU - creation
% ------------------------------------------------------------------------------
function process_json_file(a_jsonPathFileName, a_tmpDir, a_inputData)

% report information structure
global g_couf_floatNum;
global g_couf_reportData;


if (exist(a_jsonPathFileName, 'file') == 2)

   % get information to see if the file should be updated
   updateNeeded = 1;
   metaData = loadjson(a_jsonPathFileName);
   if (isfield(metaData, 'END_DECODING_DATE'))
      if (strcmp(a_inputData, metaData.END_DECODING_DATE))
         updateNeeded = 0;
      end
   end
   
   % update the file
   if (updateNeeded == 1)
      
      fprintf('File to update: %s\n', a_jsonPathFileName);
      if (isfield(metaData, 'END_DECODING_DATE'))
         fprintf('END_DECODING_DATE updated = ''%s'' => ''%s''\n', metaData.END_DECODING_DATE, a_inputData);
      else
         fprintf('END_DECODING_DATE set = ''%s''\n', a_inputData);
      end
      
      % make a copy of the file in the temporary directory
      [~, fileName, fileExt] = fileparts(a_jsonPathFileName);
      fileToUpdate = [a_tmpDir '/' fileName fileExt];
      [status] = copyfile(a_jsonPathFileName, fileToUpdate);
      if (status == 1)

         % update the file
         ok = update_file(fileToUpdate, a_inputData);

         if (ok == 1)
            
            % move the updated file
            [status, message, messageid] = movefile(fileToUpdate, a_jsonPathFileName);
            if (status ~= 1)
               fprintf('ERROR: cannot move file to update (%s) to replace input file (%s)\n', fileToUpdate, a_jsonPathFileName);
               return
            end
            
            % store the information for the XML report
            g_couf_reportData.metaFile = [g_couf_reportData.metaFile {a_jsonPathFileName}];
            g_couf_reportData.float = [g_couf_reportData.float g_couf_floatNum];
            
         end
      else
         fprintf('ERROR: cannot copy file to update (%s) to temporary directory (%s)\n', a_jsonPathFileName, a_tmpDir);
      end
   end
end

return

% ------------------------------------------------------------------------------
% Update one META.json file.
%
% SYNTAX :
%  [o_ok] = update_file(a_jsonPathFileName, a_inputData)
%
% INPUT PARAMETERS :
%   a_jsonPathFileName : name of the file to update
%   a_inputData        : input data to update
%
% OUTPUT PARAMETERS :
%   o_ok : 1 if update succeeded, 0 otherwise
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/23/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = update_file(a_jsonPathFileName, a_inputData)

% output parameters initialization
o_ok = 0;


if (exist(a_jsonPathFileName, 'file') == 2)

   % read file
   fIdIn = fopen(a_jsonPathFileName, 'r');
   if (fIdIn == -1)
      fprintf('ERROR: Unable to open INPUT file: %s\n', a_jsonPathFileName);
      return
   end

   text = [];
   while (1)
      line = fgetl(fIdIn);
      if (line == -1)
         break
      end

      text{end+1} = line;
   end

   fclose(fIdIn);

   idL = cellfun(@(x) strfind(text, x), {'"END_DECODING_DATE" :'}, 'UniformOutput', 0);
   if (~isempty([idL{:}]))
      idLine = find(~cellfun(@isempty, idL{:}) == 1);
      if (~isempty(idLine))
         lineVal = text{idLine};
         idF = strfind(lineVal, '"');
         if (length(idF) > 3)
            lineVal = [lineVal(1:idF(3)) a_inputData lineVal(idF(end):end)];
            text{idLine} = lineVal;
         end
      else
         idL = cellfun(@(x) strfind(text, x), {'"END_MISSION_STATUS" :'}, 'UniformOutput', 0);
         if (~isempty([idL{:}]))
            idLine = find(~cellfun(@isempty, idL{:}) == 1);
            if (~isempty(idLine))
               lineVal = text{idLine};
               lineVal = regexprep(lineVal, 'END_MISSION_STATUS', 'END_DECODING_DATE');
               idF = strfind(lineVal, '"');
               if (length(idF) > 3)
                  lineVal = [lineVal(1:idF(3)) a_inputData lineVal(idF(end):end)];
                  text(idLine+1:end+1) = text(idLine:end);
                  text{idLine+1} = lineVal;
               end
            else
               fprintf('ERROR: Unable to find ''END_MISSION_STATUS'' in INPUT file: %s\n', a_jsonPathFileName);
               return
            end
         end
      end
   end

   % write file
   fIdOut = fopen(a_jsonPathFileName, 'wt');
   if (fIdOut == -1)
      fprintf('ERROR: Unable to open OUTPUT file: %s\n', a_jsonPathFileName);
      return
   end

   for id = 1:length(text)
      fprintf(fIdOut, '%s\n', text{id});
   end

   fclose(fIdOut);

   o_ok = 1;

end

return

% ------------------------------------------------------------------------------
% Convert string date from 'YYYYMMDDhhmmss' to 'DD/MM/YYYY hh:mm:ss'.
%
% SYNTAX :
% [o_dateOut] = format_date(a_dateIn)
%
% INPUT PARAMETERS :
%   a_dateIn : date ('YYYYMMDDhhmmss')
%
% OUTPUT PARAMETERS :
%   o_dateOut : date ('DD/MM/YYYY hh:mm:ss')
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/23/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dateOut] = format_date(a_dateIn)

% output parameters initialization
o_dateOut = '';


if (~isempty(a_dateIn))
   o_dateOut = [a_dateIn(7:8) '/' a_dateIn(5:6) '/' a_dateIn(1:4) ' ' a_dateIn(9:10) ':' a_dateIn(11:12) ':' a_dateIn(13:14)];
end

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
%   12/21/2021 - RNU - creation
% ------------------------------------------------------------------------------
function init_xml_report(a_time)

% DOM node of XML report
global g_couf_xmlReportDOMNode;


% initialize XML report
docNode = com.mathworks.xml.XMLUtils.createDocument('coriolis_function_report');
docRootNode = docNode.getDocumentElement;

newChild = docNode.createElement('function');
newChild.appendChild(docNode.createTextNode('coXXXXXX '));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('comment');
newChild.appendChild(docNode.createTextNode('Argo Coriolis update META.json tool (update_meta_json_set_END_DECODING_DATE)'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('date');
newChild.appendChild(docNode.createTextNode(datestr(datenum(a_time, 'yyyymmddTHHMMSSZ'), 'dd/mm/yyyy HH:MM:SS')));
docRootNode.appendChild(newChild);

g_couf_xmlReportDOMNode = docNode;

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
%   12/21/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_status] = finalize_xml_report(a_ticStartTime, a_logFileName, a_error)

% DOM node of XML report
global g_couf_xmlReportDOMNode;

% report information structure
global g_couf_reportData;


% initalize final status
o_status = 'ok';

% finalize the report
docNode = g_couf_xmlReportDOMNode;
docRootNode = docNode.getDocumentElement;

newChild = docNode.createElement('updates');

newChildBis = docNode.createElement('updated_float_WMO_list');
if (isfield(g_couf_reportData, 'float'))
   wmoList = sort(unique(g_couf_reportData.float));
   newChildBis.appendChild(docNode.createTextNode(sprintf('%d ', wmoList)));
else
   newChildBis.appendChild(docNode.createTextNode(''));
end
newChild.appendChild(newChildBis);

% list of updated files
if (isfield(g_couf_reportData, 'metaFile'))
   for idFile = 1:length(g_couf_reportData.metaFile)
      newChildBis = docNode.createElement('updated_meta_file');
      textNode = g_couf_reportData.metaFile{idFile};
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
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
%  [o_decInfoMsg, o_decWarningMsg, o_decErrorMsg, ...
%    o_rtQcInfoMsg, o_rtQcWarningMsg, o_rtQcErrorMsg, ...
%    o_rtAdjInfoMsg, o_rtAdjWarningMsg, o_rtAdjErrorMsg] = parse_log_file(a_logFileName)
%
% INPUT PARAMETERS :
%   a_logFileName  : log file path name of the run
%
% OUTPUT PARAMETERS :
%   o_decInfoMsg      : DECODER INFO messages
%   o_decWarningMsg   : DECODER WARNING messages
%   o_decErrorMsg     : DECODER ERROR messages
%   o_rtQcInfoMsg     : RTQC INFO messages
%   o_rtQcWarningMsg  : RTQC WARNING messages
%   o_rtQcErrorMsg    : RTQC ERROR messages
%   o_rtAdjInfoMsg    : RTADJ INFO messages
%   o_rtAdjWarningMsg : RTADJ WARNING messages
%   o_rtAdjErrorMsg   : RTADJ ERROR messages
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/21/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decInfoMsg, o_decWarningMsg, o_decErrorMsg, ...
   o_rtQcInfoMsg, o_rtQcWarningMsg, o_rtQcErrorMsg, ...
   o_rtAdjInfoMsg, o_rtAdjWarningMsg, o_rtAdjErrorMsg] = parse_log_file(a_logFileName)

% output parameters initialization
o_decInfoMsg = [];
o_decWarningMsg = [];
o_decErrorMsg = [];
o_rtQcInfoMsg = [];
o_rtQcWarningMsg = [];
o_rtQcErrorMsg = [];
o_rtAdjInfoMsg = [];
o_rtAdjWarningMsg = [];
o_rtAdjErrorMsg = [];

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
         if (strncmpi(line, 'INFO:', length('INFO:')))
            o_decInfoMsg = [o_decInfoMsg {strtrim(line(length('INFO:')+1:end))}];
         elseif (strncmpi(line, 'WARNING:', length('WARNING:')))
            o_decWarningMsg = [o_decWarningMsg {strtrim(line(length('WARNING:')+1:end))}];
         elseif (strncmpi(line, 'ERROR:', length('ERROR:')))
            o_decErrorMsg = [o_decErrorMsg {strtrim(line(length('ERROR:')+1:end))}];
         elseif (strncmpi(line, 'RTQC_INFO:', length('RTQC_INFO:')))
            o_rtQcInfoMsg = [o_rtQcInfoMsg {strtrim(line(length('RTQC_INFO:')+1:end))}];
         elseif (strncmpi(line, 'RTQC_WARNING:', length('RTQC_WARNING:')))
            o_rtQcWarningMsg = [o_rtQcWarningMsg {strtrim(line(length('RTQC_WARNING:')+1:end))}];
         elseif (strncmpi(line, 'RTQC_ERROR:', length('RTQC_ERROR:')))
            o_rtQcErrorMsg = [o_rtQcErrorMsg {strtrim(line(length('RTQC_ERROR:')+1:end))}];
         elseif (strncmpi(line, 'RTADJ_INFO:', length('RTADJ_INFO:')))
            o_rtAdjInfoMsg = [o_rtAdjInfoMsg {strtrim(line(length('RTADJ_INFO:')+1:end))}];
         elseif (strncmpi(line, 'RTADJ_WARNING:', length('RTADJ_WARNING:')))
            o_rtAdjWarningMsg = [o_rtAdjWarningMsg {strtrim(line(length('RTADJ_WARNING:')+1:end))}];
         elseif (strncmpi(line, 'RTADJ_ERROR:', length('RTADJ_ERROR:')))
            o_rtAdjErrorMsg = [o_rtAdjErrorMsg {strtrim(line(length('RTADJ_ERROR:')+1:end))}];
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
%   12/21/2021 - RNU - creation
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
