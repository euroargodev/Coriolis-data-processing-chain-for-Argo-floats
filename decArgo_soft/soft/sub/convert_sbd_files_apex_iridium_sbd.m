% ------------------------------------------------------------------------------
% Convert SBD files to raw .msg and .log ASCII files.
%
% SYNTAX :
%  [o_nbSbdFiles, o_nbAsciiFiles] = convert_sbd_files_apex_iridium_sbd( ...
%    a_inputDirName, a_outputDirName)
%
% INPUT PARAMETERS :
%   a_inputDirName  : input files dir name
%   a_outputDirName : output files dir name
%
% OUTPUT PARAMETERS :
%   o_nbSbdFiles   : number of input SBD files
%   o_nbAsciiFiles : number of output ASCII files
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/03/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_nbSbdFiles, o_nbAsciiFiles] = convert_sbd_files_apex_iridium_sbd( ...
   a_inputDirName, a_outputDirName)

% output parameters initialization
o_nbSbdFiles = 0;
o_nbAsciiFiles = 0;


% process all SBD files of the directory
sbdFiles = dir([a_inputDirName '*.sbd']);
o_nbSbdFiles = length(sbdFiles);

prevMomsn = -1;
dataList = [];
currentData = [];
% store SBD data in the dataList structure
for iFile = 1:length(sbdFiles)
   
   sbdFileName = sbdFiles(iFile).name;
   sbdFilePathName = [a_inputDirName sbdFiles(iFile).name];
   
   fId = fopen(sbdFilePathName, 'r');
   if (fId == -1)
      fprintf('ERROR: Error while opening file : %s\n', sbdFilePathName);
   end
   [sbdData, sbdDataCount] = fread(fId);
   fclose(fId);
   
   if (sbdData(1) == 1)
      % header (filename and size) + first data
      if (~isempty(currentData))
         dataList = [dataList; currentData];
      end
      currentData = [];
      
      idF = find(sbdData(4:end) == 0, 1)+2;
      asciiFileName = char(sbdData(4:idF)');
      if (length(strfind(asciiFileName, '.')) == 1)
         asciiFileName = [asciiFileName '.msg'];
      end
      asciiFilePathName = [a_outputDirName asciiFileName];
      
      currentData.asciiFileName = {asciiFileName};
      currentData.size = 256*sbdData(2)+sbdData(3);
      currentData.data = {sbdData(idF+2:end)'};
      currentData.dataRaw = {sbdData'};
      
      prevMomsn = -1;
      
   elseif (sbdData(1) == 2)
      % following data
      currentData.data = [currentData.data {sbdData(2:end)'}];
      currentData.dataRaw = [currentData.dataRaw {sbdData'}];
   else
      fprintf('ERROR: Anomaly in file : %s\n', asciiFilePathName);
      continue;
   end
   
   % retrieve MOMSN number from SBD file name
   idFUs = strfind(sbdFileName, '_');
   momsn = str2num(sbdFileName(idFUs(3)+1:idFUs(4)-1));
   
   % look for inconsistencies from MOMSN number
   if (prevMomsn ~= -1)
      if (momsn == prevMomsn)
         sbdDataPrev = currentData.dataRaw{end-1}';
         if ((length(sbdData) == length(sbdDataPrev)) && ~any(sbdData ~= sbdDataPrev))
            fprintf('INFO: Ignoring duplicated data : %s\n', sbdFileName);
            currentData.data{end} = [];
            currentData.dataRaw{end} = [];
         else
            fprintf('WARNING: Same MOMSN but data differ : %s\n', sbdFileName);
         end
      end
   end
   
   prevMomsn = momsn;
end

% flush last SBD file data
if (~isempty(currentData))
   dataList = [dataList; currentData];
end

% clear duplicates in raw .msg or .log files
if (length([dataList.asciiFileName]) ~= length(unique([dataList.asciiFileName])))

   nbDel = 0;
   while(length([dataList.asciiFileName]) ~= length(unique([dataList.asciiFileName])))
      for iFile = 1:length(dataList)
         fileName = dataList(iFile).asciiFileName{:};
         idF = find(strcmp([dataList.asciiFileName], fileName));
         if (length(idF) > 1)
            sizeList = cellfun(@length, {dataList(idF).data});
            [~, idMax] = max(sizeList);
            idToDel = setdiff(idF, idF(idMax));
            dataList(idToDel) = [];
            nbDel = nbDel + length(idToDel);
            break;
         end
      end
   end
   
   fprintf('WARNING: %d duplicates in .msg or .log files => cleared\n', nbDel);
end

% generate raw .msg and .log ASCII files in the output directory
for iFile = 1:length(dataList)
   
   asciiFilePathName = [a_outputDirName dataList(iFile).asciiFileName{:}];
   
   % output file
   fIdOut = fopen(asciiFilePathName, 'wt');
   if (fIdOut == -1)
      fprintf('ERROR: Error while creating file : %s\n', asciiFilePathName);
      return;
   end
   
   data = dataList(iFile).data;
   for iL = 1:length(data)
      fprintf(fIdOut, '%s', data{iL});
   end
   
   fclose(fIdOut);
end

o_nbAsciiFiles = length(dataList);

return;
