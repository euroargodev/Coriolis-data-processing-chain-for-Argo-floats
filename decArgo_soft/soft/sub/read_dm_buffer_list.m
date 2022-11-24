% ------------------------------------------------------------------------------
% Read, in the appropriate file, information to decode Iridium files in DM.
%
% SYNTAX :
%  [o_fileNameList, o_fileRank, o_fileDate, ...
%    o_fileCyNum, o_fileProfNum, o_sbdFileDataType] = ...
%    read_dm_buffer_list(a_floatNum, a_bufferFileDirName, a_fileDirName)
%
% INPUT PARAMETERS :
%   a_floatNum          : float WMO number
%   a_bufferFileDirName : directory of buffer list file
%   a_fileDirName       : directory of files
%
% OUTPUT PARAMETERS :
%   o_fileNameList    : name of files to process
%   o_fileRank        : rank of files to process
%   o_fileDate        : date of files to process
%   o_fileCyNum       : cycle number of files to process
%   o_fileProfNum     : profile number of files to process
%   o_sbdFileDataType : packet type of SBD files to process
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_fileNameList, o_fileRank, o_fileDate, ...
   o_fileCyNum, o_fileProfNum, o_sbdFileDataType] = ...
   read_dm_buffer_list(a_floatNum, a_bufferFileDirName, a_fileDirName)

% output parameters initialization
o_fileNameList = [];
o_fileRank = [];
o_fileDate = [];
o_fileCyNum = [];
o_fileProfNum = [];
o_sbdFileDataType = [];

global g_decArgo_janFirst1950InMatlab;


bufferListFileName = [a_bufferFileDirName '/' num2str(a_floatNum) '_buffers.txt'];
if (exist(bufferListFileName, 'file') == 2)
   
   fId = fopen(bufferListFileName, 'r');
   if (fId == -1)
      fprintf('ERROR: Error while opening file : %s\n', bufferListFileName);
   end
   
   data = textscan(fId, '%d %s %d %d');
   
   o_fileRank = data{1}(:);
   fileNameList = data{2}(:);
   fileCyCorList = data{3}(:);
   if (~any(fileCyCorList ~= 0))
      fileCyCorList = ones(size(fileCyCorList))*-1;
   end
   fileProfCorList = data{4}(:);
   if (~any(fileProfCorList ~= 0))
      fileProfCorList = ones(size(fileProfCorList))*-1;
   end
   
   fclose(fId);
   
   if (any(fileCyCorList ~= -1))
      idFModif = find(fileCyCorList ~= -1);
      for idF = 1:length(idFModif)
         newFileName = modify_sbd_file(a_fileDirName, ...
            fileNameList{idFModif(idF)}, fileCyCorList(idFModif(idF)), fileProfCorList(idFModif(idF)));
         if (~isempty(newFileName))
            fileNameList{idFModif(idF)} = newFileName;
         end
      end
   end
   
   for idFile = 1:length(o_fileRank)
      
      fileName = fileNameList{idFile};
      
      idFUs = strfind(fileName, '_');
      dateStr = fileName(idFUs(1)+1:idFUs(2)-1);
      date = datenum(dateStr, 'yyyymmddTHHMMSS') - g_decArgo_janFirst1950InMatlab;
      
      dataType = str2num(fileName(idFUs(2)+1:idFUs(3)-1));
      
      cycleStr = fileName(idFUs(3)+1:idFUs(4)-1);
      if (strcmp(cycleStr, 'xxx'))
         cycle = -1;
      else
         cycle = str2num(cycleStr);
      end
      
      profileStr = fileName(idFUs(4)+1:idFUs(5)-1);
      if (strcmp(profileStr, 'x'))
         profile = -1;
      else
         profile = str2num(profileStr);
      end
      
      o_fileDate(idFile) = date;
      o_fileCyNum(idFile) = cycle;
      o_fileProfNum(idFile) = profile;
      o_sbdFileDataType(idFile) = dataType;
      o_fileNameList{idFile} = [a_fileDirName '/' fileName];
   end
end

return;

% ------------------------------------------------------------------------------
% Modify the name and contents of a CTS4 Remocean SBD file by setting a new
% cycle and profile number.
%
% SYNTAX :
%  [o_newFileName] = modify_sbd_file(a_fileDirName, a_fileName, a_fileCyCor, a_fileProfCor)
%
% INPUT PARAMETERS :
%   a_fileDirName : directory of the sbd file
%   a_fileName    : name of the sbd file
%   a_fileCyCor   : new cycle number
%   a_fileProfCor : new profile number
%
% OUTPUT PARAMETERS :
%   o_newFileName : name of the new file (empty is there was no need top modify
%                   the file)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/23/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_newFileName] = modify_sbd_file(a_fileDirName, a_fileName, a_fileCyCor, a_fileProfCor)

% output parameters initialization
o_newFileName = [];


% check if the file need to be modified
idFUs = strfind(a_fileName, '_');
packType = str2num(a_fileName(idFUs(2)+1:idFUs(3)-1));
if (packType ~= 251)
   
   % create the new name of the file
   cyStr = sprintf('%03d', a_fileCyCor);
   if (a_fileProfCor ~= -1)
      profStr = sprintf('%d', a_fileProfCor);
   else
      profStr = a_fileName(idFUs(4)+1:idFUs(5)-1);
   end
   newFileName = [a_fileName(1:idFUs(3)) cyStr '_' profStr a_fileName(idFUs(5):end)];
   
   % if the file with the name stored in the buffer exists, it has not been modified yet
   if (exist([a_fileDirName '/' a_fileName], 'file') == 2)
      
      % create a temporary directory
      tmpDirName = [a_fileDirName '/tmp/'];
      if (exist(tmpDirName, 'dir') == 7)
         rmdir(tmpDirName, 's');
      end
      mkdir(tmpDirName);
      
      % modify the file contents
      move_file([a_fileDirName '/' a_fileName], [tmpDirName '/' a_fileName]);
      ok = set_cy_prof_num(packType, [tmpDirName '/' a_fileName], [tmpDirName '/' newFileName], a_fileCyCor, a_fileProfCor);
      if (~ok)
         fprintf('ERROR: Anomaly in modify_sbd_file while processing file : %s\n', ...
            [tmpDirName '/' a_fileName]);
         return;
      end
      move_file([tmpDirName '/' newFileName], [a_fileDirName '/' newFileName]);
      
      % remove the temporary directory
      rmdir(tmpDirName, 's');
      
   end
   
   o_newFileName = newFileName;
end

return;

% ------------------------------------------------------------------------------
% Modify the contents of a CTS4 Remocean SBD file by setting a new cycle and
% profile number.
%
% SYNTAX :
%  [o_ok] = set_cy_prof_num(a_packType, a_fileNameIn, a_fileNameOut, a_cyNum, a_profNum)
%
% INPUT PARAMETERS :
%   a_packType    : SBD file type
%   a_fileNameIn  : input file path name
%   a_fileNameOut : output file path name
%   a_cyNum       : new cycle number
%   a_profNum     : new profile number
%
% OUTPUT PARAMETERS :
%   o_ok : report flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/23/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = set_cy_prof_num(a_packType, a_fileNameIn, a_fileNameOut, a_cyNum, a_profNum)

% output parameters initialization
o_ok = 0;


% read input file
fId = fopen(a_fileNameIn, 'r');
if (fId == -1)
   fprintf('ERROR: Error while opening file : %s\n', ...
      a_fileNameIn);
end
[sbdData, ~] = fread(fId);
fclose(fId);

% modify cycle dans profile numbers in file contents
switch (a_packType)
   
   case 0
      % sensor data
      sbdData(3) = uint8(bitshift(a_cyNum, -8));
      sbdData(4) = uint8(bitand(a_cyNum, 2^8-1));
      if (a_profNum ~= -1)
         sbdData(5) = uint8(a_profNum);
      end
      
   case 250
      % sensor tech data
      sbdData(3) = uint8(bitshift(a_cyNum, -8));
      sbdData(4) = uint8(bitand(a_cyNum, 2^8-1));
      if (a_profNum ~= -1)
         sbdData(5) = uint8(a_profNum);
      end
      
   case 252
      % float pressure data
      sbdData(2) = uint8(bitshift(a_cyNum, -8));
      sbdData(3) = uint8(bitand(a_cyNum, 2^8-1));
      if (a_profNum ~= -1)
         phaseNum = bitshift(sbdData(4), -4);
         sbdData(4) = uint8(bitshift(phaseNum, 4) + a_profNum);
      end
      
   case 253
      % float technical data
      sbdData(12) = uint8(bitshift(a_cyNum, -8));
      sbdData(13) = uint8(bitand(a_cyNum, 2^8-1));
      if (a_profNum ~= -1)
         sbdData(14) = uint8(a_profNum);
      end
      
   case 254
      % float prog technical data
      sbdData(8) = uint8(bitshift(a_cyNum, -8));
      sbdData(9) = uint8(bitand(a_cyNum, 2^8-1));
      if (a_profNum ~= -1)
         sbdData(10) = uint8(a_profNum);
      end
      
   case 255
      % float prog param data
      sbdData(8) = uint8(bitshift(a_cyNum, -8));
      sbdData(9) = uint8(bitand(a_cyNum, 2^8-1));
      if (a_profNum ~= -1)
         sbdData(10) = uint8(a_profNum);
      end
      
   otherwise
      fprintf('WARNING: Nothing done yet in set_cy_prof_num for packet type #%d\n', ...
         a_packType);
end

% write output file
fId = fopen(a_fileNameOut, 'w');
if (fId == -1)
   fprintf('ERROR: Error while opening file : %s\n', ...
      a_fileNameOut);
end
fwrite(fId, sbdData);
fclose(fId);

o_ok = 1;

return;
