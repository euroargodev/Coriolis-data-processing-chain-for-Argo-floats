% ------------------------------------------------------------------------------
% Create data files from SBD files.
%
% SYNTAX :
% [o_ok] = create_data_files_pfv2(a_inputDirName, a_outputDataDirName, a_outputDataGzDirName)
%
% INPUT PARAMETERS :
%   a_inputDirName        : name of input SBD file directory
%   a_outputDataDirName   : name of output data file directory
%   a_outputDataGzDirName : name of output compressed data file directory
%
% OUTPUT PARAMETERS :
%   o_fileInfo : float data files information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/03/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_fileInfo] = create_data_files_pfv2(a_sbdFileNamList, a_sbdFileDateList, ...
   a_inputDirName, a_outputDataDirName, a_outputDataGzDirName)

% output parameters initialization
o_fileInfo = [];

% current float WMO number
global g_decArgo_floatNum;

% debug mode (to avoid creating float files from SBD)
global g_decArgo_pfv2DebugMode


% in debug mode, read mat file if exists
if (g_decArgo_pfv2DebugMode)
   debugModeFilePathName = [a_outputDataDirName 'debug_mode_file.mat'];
   if (exist(debugModeFilePathName, 'file') == 2)
      fileInfo = load(debugModeFilePathName);
      o_fileInfo = fileInfo.fileInfo;
      return
   end
end

% process SBD files
compressedDataFlag = 0;
cpt = 1;
% SBD file information
% 1: float HEX base file Name
% 2: file number
% 3: last file flag
% 4: file data
% 5: SBD file name
% 6: SBD file date
% 7: SBD file size
% 8: float HEX file name
% 9: data length
sbdDataTab = cell(length(a_sbdFileNamList), 9);
for idFile = 1:length(a_sbdFileNamList)
   sbdFileName = regexprep(a_sbdFileNamList{idFile}, '.txt', '.sbd');

   % read SBD data
   sbdFilePathName = [a_inputDirName '/' sbdFileName];
   fId = fopen(sbdFilePathName, 'r');
   if (fId == -1)
      fprintf('ERROR: Float #%d: Error while opening file : %s\n', ...
         g_decArgo_floatNum, ...
         sbdFilePathName);
      return
   end
   sbdData = fread(fId);
   fclose(fId);

   % retrieve SBD file parts
   [fileName, sepByteVal, data] = get_sbd_data(sbdData);
   if (isempty(fileName))
      fprintf('ERROR: Float #%d: Separating character not found in file : %s\n', ...
         g_decArgo_floatNum, ...
         sbdFileName);
      continue
   end

   % store data file information
   if (any(strfind(fileName, '.gz')))
      idF = strfind(fileName, '.gz');
      sbdDataTab{cpt, 1} = fileName(1:idF-1);
      if (length(fileName) > idF+4)
         sbdDataTab{cpt, 2} = str2double(fileName(idF+4:end));
      else
         sbdDataTab{cpt, 2} = 1;
      end
      sbdDataTab{cpt, 3} = (sepByteVal == hex2dec('04'));
      sbdDataTab{cpt, 4} = data;
      sbdDataTab{cpt, 5} = sbdFileName;
      sbdDataTab{cpt, 6} = a_sbdFileDateList(idFile);
      fileInfo = dir(sbdFilePathName);
      sbdDataTab{cpt, 7} = fileInfo.bytes;
      sbdDataTab{cpt, 8} = fileName;
      sbdDataTab{cpt, 9} = length(data);
      cpt = cpt + 1;
      compressedDataFlag = 1;
   else
      fprintf('ERROR: Float #%d: Uncompressed file in SBD not implemented yet : %s\n', ...
         g_decArgo_floatNum, ...
         sbdFileName);
      continue
   end
end
sbdDataTab(cpt:end, :) = [];

% uncompress data files
if (compressedDataFlag)
   fileList = unique(sbdDataTab(:, 1));
   cpt = 1;
   % float file information
   % 1: float HEX base file Name
   % 2: float final file name
   % 3: zip file size
   % 4: final file size
   % 5: SBD file information (1: SBD file name, 2: SBD file date, 3: SBD file size, 4: data file size)
   fileInfo = cell(length(fileList), 5);
   for idFile = 1:length(fileList)
      fileName = fileList{idFile};
      idForFile = find(strcmp(sbdDataTab(:, 1), fileName));
      if (any([sbdDataTab{idForFile, 3}] == 1))
         fileNum = [sbdDataTab{idForFile, 2}];
         [fileNumS, idSort] = sort(fileNum);
         if ((fileNumS(1) == 1) && all(diff(fileNumS) == 1))

            % concatenate data to create the data file
            fileData = sbdDataTab(idForFile, 4);
            data = cell2mat(fileData(idSort));

            % create the data file
            dataFilePathName = [a_outputDataGzDirName '/' fileName '.gz'];
            fId = fopen(dataFilePathName, 'w');
            if (fId == -1)
               fprintf('ERROR: Error while creating file : %s\n', ...
                  dataFilePathName);
               continue
            end
            fwrite(fId, data);
            fclose(fId);

            originalFileName = get_file_name(data);
            fileInfo{cpt, 1} = fileName;
            fileInfo{cpt, 2} = originalFileName;
            fileInfo{cpt, 5} = sbdDataTab(idForFile, [5 6 7 9]);
            cpt = cpt + 1;

         else
            fprintf('WARNING: Float #%d: Still waiting for completion of file: %s.gz\n', ...
               g_decArgo_floatNum, ...
               fileName);
            continue
         end
      else
         fprintf('WARNING: Float #%d: Still waiting for completion of file: %s.gz\n', ...
            g_decArgo_floatNum, ...
            fileName);
         continue
      end
   end
   fileInfo(cpt:end, :) = [];

   % uncompress data files
   gzFileList = dir([a_outputDataGzDirName '*.gz']);
   for idFile = 1:length(gzFileList)
      gzFilePathName = [a_outputDataGzDirName gzFileList(idFile).name];

      % uncompress the file
      try
         filePathName = gunzip(gzFilePathName, a_outputDataDirName);
      catch infos
         fprintf('ERROR: Float #%d: Failed while uncompressing file: %s (%s) - ignored\n', ...
            g_decArgo_floatNum, ...
            gzFilePathName, ...
            infos.message);
      end

      % retrieve float file original name
      [~, fileNameIn, fileExtIn] = fileparts(filePathName{:});
      idF = find(strcmp(fileInfo(:, 1), [fileNameIn, fileExtIn]));

      % rename the uncompressed files
      filePathNameIn = [a_outputDataDirName [fileNameIn, fileExtIn]];
      if (~isempty(idF))
         filePathNameOut = [a_outputDataDirName fileInfo{idF, 2}];
      else
         filePathNameOut = filePathNameIn;
      end
      move_file(filePathNameIn, filePathNameOut);

      % store additional information
      fileInfo{idF, 3} = gzFileList(idFile).bytes;
      tmpFile = dir(filePathNameOut);
      fileInfo{idF, 4} = tmpFile.bytes;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% specific PFV2
if (g_decArgo_floatNum == 5907190)
   % rename file 'M1C76TEC.hex' to 'M1C76TEC2.hex'
   filePathNameIn = [a_outputDataDirName 'M1C76TEC.hex'];
   filePathNameOut = [a_outputDataDirName 'M1C76TEC2.hex'];
   if (exist(filePathNameIn, 'file') == 2)
      move_file(filePathNameIn, filePathNameOut);
   end
   % update fileInfo array
   idF = find(strcmp(fileInfo(:, 2), 'M1C76TEC.hex'));
   if (~isempty(idF))
      fileInfo{idF, 2} = 'M1C76TEC2.hex';
   end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% fprintf('DEC_INFO: %s\n', fileInfo{:, 2});

% in debug mode, save mat file if doen't exist
if (g_decArgo_pfv2DebugMode)
   debugModeFilePathName = [a_outputDataDirName 'debug_mode_file.mat'];
   if ~(exist(debugModeFilePathName, 'file') == 2)
      save(debugModeFilePathName, 'fileInfo');
   end
end

o_fileInfo = fileInfo;

return

% ------------------------------------------------------------------------------
% Get SBD file parts (filename, separating character and binary data).
%
% SYNTAX :
% [o_fileName, o_sepByteVal, o_data] = get_sbd_data(a_sbdData)
%
% INPUT PARAMETERS :
%   a_sbdData : input SBD data
%
% OUTPUT PARAMETERS :
%   o_fileName   : data file name
%   o_sepByteVal : separating byte value
%   o_data       : binary data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/03/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_fileName, o_sepByteVal, o_data] = get_sbd_data(a_sbdData)

% output parameters initialization
o_fileName = '';
o_sepByteVal = '';
o_data = [];


% retrieve the separating character
sepByteNum = '';
sepByteNum1 = find(a_sbdData == hex2dec('03'), 1, 'first');
sepByteNum2 = find(a_sbdData == hex2dec('04'), 1, 'first');
if (~isempty(sepByteNum1) && ~isempty(sepByteNum2))
   if (sepByteNum1 < sepByteNum2)
      sepByteNum = sepByteNum1;
   else
      sepByteNum = sepByteNum2;
   end
elseif (~isempty(sepByteNum1))
   sepByteNum = sepByteNum1;
elseif (~isempty(sepByteNum2))
   sepByteNum = sepByteNum2;
end
if (~isempty(sepByteNum))
   o_fileName = char(a_sbdData(1:sepByteNum-1))';
   o_sepByteVal = a_sbdData(sepByteNum);
   o_data = a_sbdData(sepByteNum+1:end);
end

return

% ------------------------------------------------------------------------------
% Retrieve the original name of a compressed file.
%
% SYNTAX :
% [o_fileName] = get_file_name(a_gzData)
%
% INPUT PARAMETERS :
%   a_gzData : input compressed data
%
% OUTPUT PARAMETERS :
%   o_fileName   : original compressed file name
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/03/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_fileName] = get_file_name(a_gzData)

% output parameters initialization
o_fileName = '';

% see https://www.ietf.org/rfc/rfc1952.txt for details
flg = a_gzData(4);
if (bitand(flg, 2^3) > 0)
   start = 11;
   if (bitand(flg, 2^2) > 0)
      xlen = a_gzData(start)*256 + a_gzData(start+1);
      start = start + xlen;
   end
   stop = start + 1;
   while (a_gzData(stop) ~= 0)
      stop = stop + 1;
   end
   stop = stop - 1;
   o_fileName = char(a_gzData(start:stop)');
end

return
