% ------------------------------------------------------------------------------
% Move a list of files from a directory to another one.
%
% SYNTAX :
%  [o_ok] = move_files_ir_sbd(a_listFileNames, a_inputDir, a_outputDir, ...
%    a_updateXmlReportFlag, a_deleteSbdFileFlag)
%
% INPUT PARAMETERS :
%   a_listFileNames       : names of the files to move
%   a_inputDir            : input directory
%   a_outputDir           : output directory
%   a_updateXmlReportFlag : flag for adding or not the moved file path name in
%                           the XML report (in the "input file" section)
%   a_deleteSbdFileFlag   : flag for deleting or not the associated SBD file
%
% OUTPUT PARAMETERS :
%   o_ok : move operation report flag (1 if ok, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = move_files_ir_sbd(a_listFileNames, a_inputDir, a_outputDir, ...
   a_updateXmlReportFlag, a_deleteSbdFileFlag)

% output parameters initialization
o_ok = 1;

% current float WMO number
global g_decArgo_floatNum;

% RT processing flag
global g_decArgo_realtimeFlag;

% report information structure
global g_decArgo_reportStruct;

% array to store information on already decoded SBD files
global g_decArgo_sbdInfo;


% if the SBD has been decoded, update the associated list
if ((~isempty(a_listFileNames)) && (a_updateXmlReportFlag == 1) && (a_deleteSbdFileFlag == 1))
   
   % check the files of the directory
   for idFile = 1:length(a_listFileNames)
      fileName = a_listFileNames{idFile};
      
      idFUs = strfind(fileName, '_');
      if (length(idFUs) == 5)
         imei = str2num(fileName(idFUs(2)+1:idFUs(3)-1));
         momsn = str2num(fileName(idFUs(3)+1:idFUs(4)-1));
         mtmsn = str2num(fileName(idFUs(4)+1:idFUs(5)-1));
      else
         fprintf('WARNING: Inconsistent SBD file name: %s\n', dirFileName);
      end
      
      g_decArgo_sbdInfo = [g_decArgo_sbdInfo; ...
         imei momsn mtmsn];
   end
   g_decArgo_sbdInfo = unique(g_decArgo_sbdInfo, 'rows');
end

% move the files of the list
for idFile = 1:length(a_listFileNames)
   fileName = a_listFileNames{idFile};
   fileNameIn = [a_inputDir '/' fileName];
   fileNamOut = [a_outputDir '/' fileName];
   
   if (strcmp(fileName(end-3:end), '.txt'))
      
      %       if ((g_decArgo_realtimeFlag == 1) && (a_updateXmlReportFlag == 1))
      %          % in RT we delete the processed files
      %          delete(fileNameIn);
      %       else
      if (move_file(fileNameIn, fileNamOut) == 0)
         o_ok = 0;
         continue;
      end
      %       end
      
      if (a_updateXmlReportFlag == 1)
         if (g_decArgo_realtimeFlag == 1)
            % store information for the XML report
            g_decArgo_reportStruct.inputFiles = [g_decArgo_reportStruct.inputFiles ...
               {fileName}];
         end
      end
      
      if (a_deleteSbdFileFlag == 1)
         fileNameSbd = [fileName(1:end-4) '.sbd'];
         fileNameSbdIn = [a_inputDir '/' fileNameSbd];
         delete(fileNameSbdIn);
      end
      
   elseif (strcmp(fileName(end-3:end), '.sbd'))
      
      if (a_deleteSbdFileFlag == 1)
         delete(fileNameIn);
      end
      
      fileNameTxt = [fileName(1:end-4) '.txt'];
      fileNameTxtIn = [a_inputDir '/' fileNameTxt];
      fileNameTxtOut = [a_outputDir '/' fileNameTxt];
      
      %       if ((g_decArgo_realtimeFlag == 1) && (a_updateXmlReportFlag == 1))
      %          % in RT we delete the processed files
      %          delete(fileNameTxtIn);
      %       else
      if (move_file(fileNameTxtIn, fileNameTxtOut) == 0)
         o_ok = 0;
         continue;
      end
      %       end
      
   end
end

return;
