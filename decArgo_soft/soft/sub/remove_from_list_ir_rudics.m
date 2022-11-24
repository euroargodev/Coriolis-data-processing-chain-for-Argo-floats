% ------------------------------------------------------------------------------
% Remove a given item from a given virtual buffer list.
%
% SYNTAX :
%  remove_from_list_ir_rudics(a_fileName, a_listName, a_updateXmlReportFlag)
%
% INPUT PARAMETERS :
%   a_fileName            : name of the file to be removed
%   a_listName            : name of the virtual buffer list
%   a_updateXmlReportFlag : update XML report flag
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/17/2016 - RNU - creation
% ------------------------------------------------------------------------------
function remove_from_list_ir_rudics(a_fileName, a_listName, a_updateXmlReportFlag)

% current float WMO number
global g_decArgo_floatNum;

% SBD sub-directories
global g_decArgo_archiveDirectory;

% to use virtual buffers instead of directories
global g_decArgo_spoolFileList;
global g_decArgo_bufFileList;

% RT processing flag
global g_decArgo_realtimeFlag;

% report information structure
global g_decArgo_reportStruct;


if (isempty(a_fileName))
   return;
end

if (~ismember(a_listName, [{'spool'} {'buffer'}]))
   fprintf('BUFF_ERROR: Float #%d: remove_from_list_ir_rudics: unknown list name (''%s'')\n', ...
      g_decArgo_floatNum, a_listName);
   return;
end

fileNameList = a_fileName;
if (~iscell(a_fileName))
   fileNameList = {a_fileName};
end

for idFile = 1:length(fileNameList)
   
   fileName = fileNameList{idFile};
   if (strcmp(a_listName, 'spool'))
      idF = find(strcmp(fileName, g_decArgo_spoolFileList));
      if (length(idF) == 1)
         g_decArgo_spoolFileList(idF) = [];
      else
         if (isempty(idF))
            fprintf('BUFF_ERROR: Float #%d: remove_from_list_ir_rudics: cannot find ''%s'' in list ''%s''\n', ...
               g_decArgo_floatNum, fileName, a_listName);
         else
            fprintf('BUFF_ERROR: Float #%d: remove_from_list_ir_rudics: more than one ''%s'' in list ''%s''\n', ...
               g_decArgo_floatNum, fileName, a_listName);
         end
      end
   elseif (strcmp(a_listName, 'buffer'))
      idF = find(strcmp(fileName, g_decArgo_bufFileList));
      if (length(idF) == 1)
         g_decArgo_bufFileList(idF) = [];
         
         if (a_updateXmlReportFlag == 1)
            if (g_decArgo_realtimeFlag == 1)
               % store information for the XML report
               fileName = [fileName(1:end-4) '.txt'];
               g_decArgo_reportStruct.inputFiles = [g_decArgo_reportStruct.inputFiles ...
                  {[g_decArgo_archiveDirectory '/' fileName]}];
            end
         end
      else
         if (isempty(idF))
            fprintf('BUFF_ERROR: Float #%d: remove_from_list_ir_rudics: cannot find ''%s'' in list ''%s''\n', ...
               g_decArgo_floatNum, fileName, a_listName);
         else
            fprintf('BUFF_ERROR: Float #%d: remove_from_list_ir_rudics: more than one ''%s'' in list ''%s''\n', ...
               g_decArgo_floatNum, fileName, a_listName);
         end
      end
   end
end

return;
