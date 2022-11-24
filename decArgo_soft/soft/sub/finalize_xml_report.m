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
global g_decArgo_xmlReportDOMNode;

% report information structure
global g_decArgo_reportData;


% initalize final status
o_status = 'ok';

% finalize the report
docNode = g_decArgo_xmlReportDOMNode;
docRootNode = docNode.getDocumentElement;

% list of processings done
for idFloat = 1:length(g_decArgo_reportData)
   
   reportStruct = g_decArgo_reportData(idFloat);
   
   newChild = docNode.createElement(sprintf('float_%d', idFloat));
   
   newChildBis = docNode.createElement('float_wmo');
   newChildBis.appendChild(docNode.createTextNode(num2str(reportStruct.floatNum)));
   newChild.appendChild(newChildBis);
   
   reportStruct.cycleList = sort(unique(reportStruct.cycleList));
   newChildBis = docNode.createElement('nb_cycles');
   newChildBis.appendChild(docNode.createTextNode(num2str(length(reportStruct.cycleList))));
   newChild.appendChild(newChildBis);
   
   newChildBis = docNode.createElement('cycle_list');
   newChildBis.appendChild(docNode.createTextNode(sprintf('%d ', reportStruct.cycleList)));
   newChild.appendChild(newChildBis);
      
   for idFile = 1:length(reportStruct.inputFiles)
      newChildBis = docNode.createElement('input_file');
      textNode = char(reportStruct.inputFiles(idFile));
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
   
   for idFile = 1:length(reportStruct.outputMetaFiles)
      newChildBis = docNode.createElement('output_meta_file');
      textNode = char(reportStruct.outputMetaFiles(idFile));
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
   
   for idFile = 1:length(reportStruct.outputMonoProfFiles)
      newChildBis = docNode.createElement('output_mono-profile_file');
      textNode = char(reportStruct.outputMonoProfFiles(idFile));
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
   
   for idFile = 1:length(reportStruct.outputMultiProfFiles)
      newChildBis = docNode.createElement('output_multi-profile_file');
      textNode = char(reportStruct.outputMultiProfFiles(idFile));
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
   
   for idFile = 1:length(reportStruct.outputTrajFiles)
      newChildBis = docNode.createElement('output_trajectory_file');
      textNode = char(reportStruct.outputTrajFiles(idFile));
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
   
   for idFile = 1:length(reportStruct.outputTechFiles)
      newChildBis = docNode.createElement('output_technical_file');
      textNode = char(reportStruct.outputTechFiles(idFile));
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end

   docRootNode.appendChild(newChild);
end

% retrieve information from the log file
[decInfoMsg, decWarningMsg, decErrorMsg, ...
   rtQcInfoMsg, rtQcWarningMsg, rtQcErrorMsg, ...
   rtAdjInfoMsg, rtAdjWarningMsg, rtAdjErrorMsg] = parse_log_file(a_logFileName);

if (~isempty(decInfoMsg))
   for idMsg = 1:length(decInfoMsg)
      newChild = docNode.createElement('decoding_info');
      textNode = decInfoMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
end
if (~isempty(decWarningMsg))
   for idMsg = 1:length(decWarningMsg)
      newChild = docNode.createElement('decoding_warning');
      textNode = decWarningMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
end
if (~isempty(decErrorMsg))
   for idMsg = 1:length(decErrorMsg)
      newChild = docNode.createElement('decoding_error');
      textNode = decErrorMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end  
   o_status = 'nok';
end

if (~isempty(rtQcInfoMsg))
   for idMsg = 1:length(rtQcInfoMsg)
      newChild = docNode.createElement('rt_qc_info');
      textNode = rtQcInfoMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
end
if (~isempty(rtQcWarningMsg))
   for idMsg = 1:length(rtQcWarningMsg)
      newChild = docNode.createElement('rt_qc_warning');
      textNode = rtQcWarningMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
end
if (~isempty(rtQcErrorMsg))
   for idMsg = 1:length(rtQcErrorMsg)
      newChild = docNode.createElement('rt_qc_error');
      textNode = rtQcErrorMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end  
   o_status = 'nok';
end

if (~isempty(rtAdjInfoMsg))
   for idMsg = 1:length(rtAdjInfoMsg)
      newChild = docNode.createElement('rt_adj_info');
      textNode = rtAdjInfoMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
end
if (~isempty(rtAdjWarningMsg))
   for idMsg = 1:length(rtAdjWarningMsg)
      newChild = docNode.createElement('rt_adj_warning');
      textNode = rtAdjWarningMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
end
if (~isempty(rtAdjErrorMsg))
   for idMsg = 1:length(rtAdjErrorMsg)
      newChild = docNode.createElement('rt_adj_error');
      textNode = rtAdjErrorMsg{idMsg};
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
newChild.appendChild(docNode.createTextNode(format_time_dec_argo(toc(a_ticStartTime)/3600)));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('status');
newChild.appendChild(docNode.createTextNode(o_status));
docRootNode.appendChild(newChild);

return;

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
%   05/12/2013 - RNU - creation
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
      return;
   end
   fileContents = textscan(fId, '%s', 'delimiter', '\n');
   fclose(fId);
   
   if (~isempty(fileContents))
      % retrieve wanted messages
      fileContents = fileContents{:};
      idLine = 1;
      while (1)
         line = fileContents{idLine};
         if (strncmp(upper(line), 'INFO:', length('INFO:')))
            o_decInfoMsg = [o_decInfoMsg {strtrim(line(length('INFO:')+1:end))}];
         elseif (strncmp(upper(line), 'WARNING:', length('WARNING:')))
            o_decWarningMsg = [o_decWarningMsg {strtrim(line(length('WARNING:')+1:end))}];
         elseif (strncmp(upper(line), 'ERROR:', length('ERROR:')))
            o_decErrorMsg = [o_decErrorMsg {strtrim(line(length('ERROR:')+1:end))}];
         elseif (strncmp(upper(line), 'RTQC_INFO:', length('RTQC_INFO:')))
            o_rtQcInfoMsg = [o_rtQcInfoMsg {strtrim(line(length('RTQC_INFO:')+1:end))}];
         elseif (strncmp(upper(line), 'RTQC_WARNING:', length('RTQC_WARNING:')))
            o_rtQcWarningMsg = [o_rtQcWarningMsg {strtrim(line(length('RTQC_WARNING:')+1:end))}];
         elseif (strncmp(upper(line), 'RTQC_ERROR:', length('RTQC_ERROR:')))
            o_rtQcErrorMsg = [o_rtQcErrorMsg {strtrim(line(length('RTQC_ERROR:')+1:end))}];
         elseif (strncmp(upper(line), 'RTADJ_INFO:', length('RTADJ_INFO:')))
            o_rtAdjInfoMsg = [o_rtAdjInfoMsg {strtrim(line(length('RTADJ_INFO:')+1:end))}];
         elseif (strncmp(upper(line), 'RTADJ_WARNING:', length('RTADJ_WARNING:')))
            o_rtAdjWarningMsg = [o_rtAdjWarningMsg {strtrim(line(length('RTADJ_WARNING:')+1:end))}];
         elseif (strncmp(upper(line), 'RTADJ_ERROR:', length('RTADJ_ERROR:')))
            o_rtAdjErrorMsg = [o_rtAdjErrorMsg {strtrim(line(length('RTADJ_ERROR:')+1:end))}];
         end
         idLine = idLine + 1;
         if (idLine > length(fileContents))
            break;
         end
      end
   end
end

return;
