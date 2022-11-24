% ------------------------------------------------------------------------------
% Remove a given item from a given virtual buffer list.
%
% SYNTAX :
%  remove_from_list_ir_sbd(a_fileName, a_listName, ...
%    a_updateXmlReportFlag, a_delayedDecoderFlag)
%
% INPUT PARAMETERS :
%   a_fileName            : name of the file to be removed
%   a_listName            : name of the virtual buffer list
%   a_updateXmlReportFlag : update XML report flag
%   a_delayedDecoderFlag  : 1 if delayed decoder, 0 otherwise
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
function remove_from_list_ir_sbd(a_fileName, a_listName, ...
   a_updateXmlReportFlag, a_delayedDecoderFlag)

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

% array to store information on already decoded SBD files
global g_decArgo_sbdInfo;


if (isempty(a_fileName))
   return
end

if (~ismember(a_listName, [{'spool'} {'buffer'}]))
   fprintf('BUFF_ERROR: Float #%d: remove_from_list_ir_sbd: unknown list name (''%s'')\n', ...
      g_decArgo_floatNum, a_listName);
   return
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
            % for delayed decoders: if a mail is used in multiple buffers, it is
            % removed from the spool buffer the first time it is used
            if (~a_delayedDecoderFlag)
               fprintf('BUFF_ERROR: Float #%d: remove_from_list_ir_sbd: cannot find ''%s'' in list ''%s''\n', ...
                  g_decArgo_floatNum, fileName, a_listName);
            end
         else
            fprintf('BUFF_ERROR: Float #%d: remove_from_list_ir_sbd: more than one ''%s'' in list ''%s''\n', ...
               g_decArgo_floatNum, fileName, a_listName);
         end
      end
   elseif (strcmp(a_listName, 'buffer'))
      fileName = [fileName(1:end-4) '.sbd'];
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
            fprintf('BUFF_ERROR: Float #%d: remove_from_list_ir_sbd: cannot find ''%s'' in list ''%s''\n', ...
               g_decArgo_floatNum, fileName, a_listName);
         else
            fprintf('BUFF_ERROR: Float #%d: remove_from_list_ir_sbd: more than one ''%s'' in list ''%s''\n', ...
               g_decArgo_floatNum, fileName, a_listName);
         end
      end
   end
end

% if the SBD has been decoded, update the associated list
if ((~isempty(a_fileName)) && (a_updateXmlReportFlag == 1))
   
   % check the files of the directory
   for idFile = 1:length(fileNameList)
      
      fileName = fileNameList{idFile};
      idFUs = strfind(fileName, '_');
      if (length(idFUs) == 5)
         imei = str2num(fileName(idFUs(2)+1:idFUs(3)-1));
         momsn = str2num(fileName(idFUs(3)+1:idFUs(4)-1));
         mtmsn = str2num(fileName(idFUs(4)+1:idFUs(5)-1));
      else
         fprintf('WARNING: Inconsistent SBD file name: %s\n', fileName);
      end
      
      g_decArgo_sbdInfo = [g_decArgo_sbdInfo; ...
         imei momsn mtmsn];
   end
   g_decArgo_sbdInfo = unique(g_decArgo_sbdInfo, 'rows');
end

return
