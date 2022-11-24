% ------------------------------------------------------------------------------
% Convert SBD files (transmitted by Apex APF11 Iridium-SBD floats) to float
% files.
%
% SYNTAX :
%  [o_error, o_nbSbdFiles, o_nbTestFiles, o_nbProductionLogFiles, ...
%    o_nbSystemLogFiles, o_nbCriticalLogFiles, o_nbScienceLogFiles, ...
%    o_nbVitalsLogFiles] = convert_sbd_files_apex_apf11_iridium_sbd( ...
%    a_inputDirName, a_outputDirName)
%
% INPUT PARAMETERS :
%   a_inputDirName  : input SBD files dir name
%   a_outputDirName : output float files dir name
%
% OUTPUT PARAMETERS :
%   o_error                : error flag
%   o_nbSbdFiles           : number of input SBD files
%   o_nbTestFiles          : number of output '.test.txt' files
%   o_nbProductionLogFiles : number of output '.production_log.txt' files
%   o_nbSystemLogFiles     : number of output '.system_log.txt' files
%   o_nbCriticalLogFiles   : number of output '.critical_log.txt' files
%   o_nbScienceLogFiles    : number of output '.science_log.bin' files
%   o_nbVitalsLogFiles     : number of output '.vitals_log.bin' files
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/13/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_error, o_nbSbdFiles, o_nbTestFiles, o_nbProductionLogFiles, ...
   o_nbSystemLogFiles, o_nbCriticalLogFiles, o_nbScienceLogFiles, ...
   o_nbVitalsLogFiles] = convert_sbd_files_apex_apf11_iridium_sbd( ...
   a_inputDirName, a_outputDirName)

% output parameters initialization
o_error = 0;
o_nbSbdFiles = 0;
o_nbTestFiles = 0;
o_nbProductionLogFiles = 0;
o_nbSystemLogFiles = 0;
o_nbCriticalLogFiles = 0;
o_nbScienceLogFiles = 0;
o_nbVitalsLogFiles = 0;


% process all SBD files of the input directory
sbdFiles = dir([a_inputDirName '*.sbd']);
o_nbSbdFiles = length(sbdFiles);

prevMomsn = -1;
prevData = [];
dataList = [];
currentData = [];
% store SBD data in the 'dataList' structure
for iFile = 1:length(sbdFiles)
   
   sbdFileName = sbdFiles(iFile).name;
   sbdFilePathName = [a_inputDirName sbdFiles(iFile).name];
   
   fId = fopen(sbdFilePathName, 'r');
   if (fId == -1)
      fprintf('ERROR: Error while opening file : %s\n', sbdFilePathName);
      o_error = 1;
      return
   end
   sbdData = fread(fId);
   fclose(fId);
   
   if (sbdData(1) == 1)
      
      % header:
      % - number of SBD files for the current float file (2 bytes)
      % - float file name('\0' terminated))
      % - first data
      
      % check if an existing current float file could be finalized
      if (~isempty(currentData))
         if (currentData.nbSbdFileExpected ~= currentData.nbSbdFileUsed)
            fprintf('INFO: convert_sbd_files_apex_apf11_iridium_sbd: Incomplete file : %s - ignored\n', currentData.floatFileName{:});
         else
            dataList = [dataList; currentData];
         end
      end
      
      % initialize a new float file conversion
      currentData = [];
      
      % retrieve the name of the float file
      idF = find(sbdData(4:end) == 0, 1)+3;
      floatFileName = char(sbdData(4:idF-1)');
      
      currentData.floatFileName = {floatFileName}; % float file name
      currentData.nbSbdFileExpected = 256*sbdData(2)+sbdData(3); % number of expected SBD files to create the float file
      currentData.nbSbdFileUsed = 1; % SBD file counter
      currentData.sbdFileList = {sbdFileName}; % SBD file names list
      currentData.data = {sbdData(idF+1:end)'}; % data
      
      prevMomsn = -1;
      prevData = [];
      
   elseif (sbdData(1) == 2)
      
      % following data
      
      % no header received for SBD file contents (the first SBD file considered
      % is chosen according to float date, thus the header SBD file could have
      % been ignored)
      if (isempty(prevData) && isempty(currentData))
         fprintf('INFO: convert_sbd_files_apex_apf11_iridium_sbd: Starting with SBD with no header in file : %s - ignored\n', sbdFileName);
         continue
      end
      
      % SBD file contents transmitted twice
      if (~isempty(prevData) && (length(sbdData) == length(prevData)) && ~any(sbdData ~= prevData))
         fprintf('INFO: convert_sbd_files_apex_apf11_iridium_sbd: Duplicated data in file : %s - ignored\n', sbdFileName);
         continue
      end
      
      % not needed additional SBD file
      if (currentData.nbSbdFileExpected == currentData.nbSbdFileUsed)
         fprintf('INFO: convert_sbd_files_apex_apf11_iridium_sbd: Useless data in file : %s - ignored\n', sbdFileName);
         continue
      end
      
      % store following data and information
      currentData.nbSbdFileUsed = currentData.nbSbdFileUsed + 1; % SBD file counter
      currentData.sbdFileList = [currentData.sbdFileList {sbdFileName}]; % SBD file names list
      currentData.data = [currentData.data {sbdData(2:end)'}]; % data
      
      prevData = sbdData;
   else
      fprintf('WARNING: convert_sbd_files_apex_apf11_iridium_sbd: Anomaly in file : %s - ignored\n', sbdFileName);
      continue
   end
   
   % retrieve MOMSN number from SBD file name
   idFUs = strfind(sbdFileName, '_');
   momsn = str2num(sbdFileName(idFUs(3)+1:idFUs(4)-1));
   
   % look for inconsistencies from MOMSN number
   if (prevMomsn ~= -1)
      if (momsn == prevMomsn)
         sbdDataPrev = currentData.dataRaw{end-1}';
         if ((length(sbdData) == length(sbdDataPrev)) && ~any(sbdData ~= sbdDataPrev))
            fprintf('INFO: convert_sbd_files_apex_apf11_iridium_sbd: Ignoring duplicated data : %s\n', sbdFileName);
            currentData.data{end} = [];
            currentData.dataRaw{end} = [];
         else
            fprintf('WARNING: convert_sbd_files_apex_apf11_iridium_sbd: Same MOMSN but data differ : %s\n', sbdFileName);
         end
      end
   end
   
   prevMomsn = momsn;
end

% flush last SBD file data
if (~isempty(currentData))
   if (currentData.nbSbdFileExpected ~= currentData.nbSbdFileUsed)
      fprintf('INFO: convert_sbd_files_apex_apf11_iridium_sbd: Incomplete file : %s - ignored\n', currentData.floatFileName{:});
   else
      dataList = [dataList; currentData];
   end
end

% clear duplicates in float files
if (~isempty(dataList))
   if (length([dataList.floatFileName]) ~= length(unique([dataList.floatFileName])))
      
      nbDel = 0;
      while(length([dataList.floatFileName]) ~= length(unique([dataList.floatFileName])))
         for iFile = 1:length(dataList)
            fileName = dataList(iFile).floatFileName{:};
            idF = find(strcmp([dataList.floatFileName], fileName));
            if (length(idF) > 1)
               sizeList = cellfun(@length, {dataList(idF).data});
               [~, idMax] = max(sizeList);
               idToDel = setdiff(idF, idF(idMax));
               fprintf('INFO: convert_sbd_files_apex_apf11_iridium_sbd: file %s (%d bytes) kept (%d file(s) ignored)\n', ...
                  fileName, sizeList(idMax), length(idToDel));
               dataList(idToDel) = [];
               nbDel = nbDel + length(idToDel);
               break
            end
         end
      end
   end
end

% generate float files in the output directory
for iFile = 1:length(dataList)
   
   floatFilePathName = [a_outputDirName dataList(iFile).floatFileName{:}];
   
   % output file
   fIdOut = fopen(floatFilePathName, 'wb');
   if (fIdOut == -1)
      fprintf('ERROR: Error while creating file : %s\n', floatFilePathName);
      return
   end
   
   data = dataList(iFile).data;
   fwrite(fIdOut, [data{:}]);
   
   fclose(fIdOut);
end

% uncompress .gz files
gzFiles = dir([a_outputDirName '*.gz']);
for iFile = 1:length(gzFiles)
   gzFilePathName = [a_outputDirName gzFiles(iFile).name];
   if (gzFiles(iFile).bytes == 0)
      fprintf('ERROR: Empty file: %s - ignored\n', ...
         gzFilePathName);
      delete(gzFilePathName);
      continue
   end
   try
      gunzip(gzFilePathName);
   catch infos
      fprintf('ERROR: Failed while uncompressing file: %s (%s) - ignored\n', ...
         gzFilePathName, ...
         infos.message);
   end
   delete(gzFilePathName);
end

% output parameters
files = dir([a_outputDirName '*.test.txt']);
o_nbTestFiles = length(files);
files = dir([a_outputDirName '*.production_log.txt']);
o_nbProductionLogFiles = length(files);
files = dir([a_outputDirName '*.system_log.txt']);
o_nbSystemLogFiles = length(files);
files = dir([a_outputDirName '*.critical_log.txt']);
o_nbCriticalLogFiles = length(files);
files = dir([a_outputDirName '*.science_log.bin']);
o_nbScienceLogFiles = length(files);
files = dir([a_outputDirName '*.vitals_log.bin']);
o_nbVitalsLogFiles = length(files);

return
