% ------------------------------------------------------------------------------
% Rename and move the Argos input file in the correct directory (according to
% the 'processmode' input parameter value).
%
% SYNTAX :
%  [o_ok] = move_argos_input_file(a_floatArgosId, a_firstArgosMsgDate, ...
%    a_floatNum, a_cycleNumber, a_noCycleNumberTag)
%
% INPUT PARAMETERS :
%   a_floatArgosId      : float PTT number
%   a_firstArgosMsgDate : first Argos msg date of the file
%   a_floatNum          : float WMO number
%   a_cycleNumber       : cycle number
%   a_noCycleNumberTag  : tag to explain why cycle number has not been
%                         determined:
%                         'EEE': empty file (no consistent Argos message)
%                         'WWW': no WMO number for the given ArgosId
%                         'MMM': missing meta-data to computed cycle number
%                         'TTT': emission test done before float launch date
%                         'GGG': ghost message file
%                         additional tag set by miscellaneous utility tools
%                         'UUU': data frozen by an operator action
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
%   01/10/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = move_argos_input_file(a_floatArgosId, a_firstArgosMsgDate, ...
   a_floatNum, a_cycleNumber, a_noCycleNumberTag)

% output parameters initialization
o_ok = 1;

% global input parameter information
global g_decArgo_processModeAll;
global g_decArgo_inputArgosFile;

% default values
global g_decArgo_janFirst1950InMatlab;

% configuration values
global g_decArgo_dirInputHexArgosFileFormat1

% Argos Id temporary sub-directory
global g_decArgo_tmpArgosIdDirectory;


% create the new name of the Argos input file
[inputArgosFilePathName, inputArgosFileName, ext] = fileparts(g_decArgo_inputArgosFile);
inputArgosFileName = [inputArgosFileName ext];

if (isempty(a_floatNum))
   newArgosFileName = sprintf('%06d_%s_WWWWWWW_%s.txt', ...
      a_floatArgosId, ...
      datestr(a_firstArgosMsgDate+g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'), ...
      a_noCycleNumberTag);
elseif (isempty(a_cycleNumber))
   newArgosFileName = sprintf('%06d_%s_%d_%s.txt', ...
      a_floatArgosId, ...
      datestr(a_firstArgosMsgDate+g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'), ...
      a_floatNum, ...
      a_noCycleNumberTag);
else
   newArgosFileName = sprintf('%06d_%s_%d_%03d.txt', ...
      a_floatArgosId, ...
      datestr(a_firstArgosMsgDate+g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'), ...
      a_floatNum, ...
      a_cycleNumber);
end

% for comparison with archived files
% if (~isempty(a_cycleNumber))
%    pattern = sprintf('%d_%03d', a_floatNum, a_cycleNumber);
%    if (isempty(strfind(inputArgosFileName, pattern)))
%       fprintf('\n#@# DIFF Filenames differ %s %s\n\n', ...
%          inputArgosFileName, newArgosFileName);
%    end
% end

% create the Argos Id directory
argosIdDirName = [g_decArgo_dirInputHexArgosFileFormat1 '/' sprintf('%06d', a_floatArgosId) '/'];
if ~(exist(argosIdDirName, 'dir') == 7)
   mkdir(argosIdDirName);
end

if (isempty(a_floatNum) || isempty(a_cycleNumber))
   
   % no processing of input data, just archiving of the file
   if (g_decArgo_processModeAll == 1)
      % move the Argos input file for storage
      fileNameIn = g_decArgo_inputArgosFile;
      fileNamOut = [argosIdDirName newArgosFileName];
      if (move_file(fileNameIn, fileNamOut) == 0)
         o_ok = 0;
         return
      end
   end

else
   
   % the input data will be processed
   
   % create the temporary sub-directory
   g_decArgo_tmpArgosIdDirectory = [argosIdDirName 'tmp/'];
   if (exist(g_decArgo_tmpArgosIdDirectory, 'dir') == 7)
      [status, message, messageid] = rmdir(g_decArgo_tmpArgosIdDirectory, 's');
      if (status == 0)
         fprintf('ERROR: Error while deleting the %s directory (%s)\n', ...
            g_decArgo_tmpArgosIdDirectory, ...
            message);
         o_ok = 0;
         return
      end
   end
   mkdir(g_decArgo_tmpArgosIdDirectory);
   
   % copy the Argos input file in the temporary sub-directory
   fileNameIn = g_decArgo_inputArgosFile;
   fileNamOut = [g_decArgo_tmpArgosIdDirectory newArgosFileName];
   if (copy_file(fileNameIn, fileNamOut) == 0)
      o_ok = 0;
      return
   end
   
   % check if there is already some data for this file
   existingCycleFiles = dir([argosIdDirName sprintf('*_%d_%03d*', a_floatNum, a_cycleNumber)]);
   if (length(existingCycleFiles) == 0)
      
      if (g_decArgo_processModeAll == 1)
         % move the temporary Argos input file for processing
         fileNameIn = [g_decArgo_tmpArgosIdDirectory newArgosFileName];
         fileNamOut = [argosIdDirName newArgosFileName];
         if (move_file(fileNameIn, fileNamOut) == 0)
            o_ok = 0;
            return
         end
         
         % delete the temporary sub-directory
         [status, message, messageid] = rmdir(g_decArgo_tmpArgosIdDirectory, 's');
         if (status == 0)
            fprintf('ERROR: Error while deleting the %s directory (%s)\n', ...
               g_decArgo_tmpArgosIdDirectory, ...
               message);
            o_ok = 0;
            return
         end
         g_decArgo_tmpArgosIdDirectory = [];
         
         % delete the Argos input file
         delete(g_decArgo_inputArgosFile);
      end
      
   else
      
      fprintf('WARNING: %d Argos file(s) already exist(s) for float #%d and cycle #%d => concatenating contents before processing\n', ...
         length(existingCycleFiles), a_floatNum, a_cycleNumber);
      fprintf('\n#@# CONCAT %d Argos file(s) already exist(s) for float #%d and cycle #%d => concatenating contents before processing\n', ...
         length(existingCycleFiles), a_floatNum, a_cycleNumber);
      
      % sort the files to concatenate according to the date of their name
      listFileName{1} = newArgosFileName;
      listFilePathName{1} = [g_decArgo_tmpArgosIdDirectory newArgosFileName];
      fileDate = datenum(newArgosFileName(8:26), 'yyyy-mm-dd-HH-MM-SS') - g_decArgo_janFirst1950InMatlab;
      listFileDate(1) = fileDate;
      for idFile = 1:length(existingCycleFiles)
         fileName = existingCycleFiles(idFile).name;
         filePathName = [argosIdDirName existingCycleFiles(idFile).name];
         fileDate = datenum(fileName(8:26), 'yyyy-mm-dd-HH-MM-SS') - g_decArgo_janFirst1950InMatlab;
         listFileName{end+1} = fileName;
         listFilePathName{end+1} = filePathName;
         listFileDate(end+1) = fileDate;
      end
      [listFileDate, idSort] = sort(listFileDate);
      listFileName = listFileName(idSort);
      listFilePathName = listFilePathName(idSort);
      
      % the newArgosFileName can be updated
      if (idSort(1) ~= 1)
         baseFileName = listFileName{1};
         baseFileDate = datenum(baseFileName(8:26), 'yyyy-mm-dd-HH-MM-SS') - g_decArgo_janFirst1950InMatlab;
         baseFileName = sprintf('%06d_%s_%d_%03d.txt', ...
            a_floatArgosId, ...
            datestr(baseFileDate+g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'), ...
            a_floatNum, ...
            a_cycleNumber);
      else
         baseFileName = newArgosFileName;
      end
      
      % concatenate all the file contents in a new file
      baseFilePathName = [g_decArgo_tmpArgosIdDirectory 'concat_' baseFileName];
      for idFile = 1:length(listFileName)
         filePathName = listFilePathName{idFile};
         fprintf('#@# CONCAT %s\n', filePathName);
         if (concatenate_files(baseFilePathName, filePathName) == 0)
            o_ok = 0;
            return
         end
      end
      
      % delete the temporary Argos input file
      delete([g_decArgo_tmpArgosIdDirectory newArgosFileName]);
      
      % rename the concatenated file
      fileNameIn = [g_decArgo_tmpArgosIdDirectory 'concat_' baseFileName];
      fileNamOut = [g_decArgo_tmpArgosIdDirectory baseFileName];
      if (move_file(fileNameIn, fileNamOut) == 0)
         o_ok = 0;
         return
      end
      
      % set the new temporary file to process
      newArgosFileName = baseFileName;
      
      if (g_decArgo_processModeAll == 1)

         % delete concatenated files
         for idFile = 1:length(listFilePathName)
            if (idSort(idFile) ~= 1)
               delete(listFilePathName{idFile});
               %                fprintf('DEC_INFO: Deleting file %s\n', ...
               %                   listFilePathName{idFile});
            end
         end
         
         % move the temporary Argos input file for processing
         fileNameIn = [g_decArgo_tmpArgosIdDirectory newArgosFileName];
         fileNamOut = [argosIdDirName newArgosFileName];
         if (move_file(fileNameIn, fileNamOut) == 0)
            o_ok = 0;
            return
         end
         
         % delete the temporary sub-directory
         [status, message, messageid] = rmdir(g_decArgo_tmpArgosIdDirectory, 's');
         if (status == 0)
            fprintf('ERROR: Error while deleting the %s directory (%s)\n', ...
               g_decArgo_tmpArgosIdDirectory, ...
               message);
            o_ok = 0;
            return
         end
         g_decArgo_tmpArgosIdDirectory = [];
         
         % delete the Argos input file
         delete(g_decArgo_inputArgosFile);
      end
   end
end

return
