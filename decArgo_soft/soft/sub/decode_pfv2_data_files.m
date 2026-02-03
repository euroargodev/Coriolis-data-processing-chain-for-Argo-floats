% ------------------------------------------------------------------------------
% Decode float files.
%
% SYNTAX :
%  [o_floatData] = decode_pfv2_data_files(a_fileInfo, a_decoderId)
%
% INPUT PARAMETERS :
%   a_fileInfo  : float data files input information
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_floatData : float data information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/02/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatData] = decode_pfv2_data_files(a_fileInfo, a_decoderId)

% output parameters initialization
o_floatData = [];

% default values
global g_decArgo_janFirst1950InMatlab;

% current float WMO number
global g_decArgo_floatNum;


if (isempty(a_fileInfo))
   return
end

% add decoding data to file information
floatData = cat(2, ...
   cat(2, repmat({nan}, size(a_fileInfo, 1), 10), cell(size(a_fileInfo, 1), 1)), ...
   a_fileInfo);
floatFileList = a_fileInfo(:, 2);
for idFile = 1:length(floatFileList)
   
   fileName = floatFileList{idFile};

   if (any(strfind(fileName,'_selftest.hex')))
      fileTypeStr = 'SelfTest';
   elseif (any(strfind(fileName,'_setting.xml')))
      fileTypeStr = 'Config';
   elseif (any(strfind(fileName,'_SBD_cmd.txt')))
      fileTypeStr = 'Command';
   elseif (any(strfind(fileName,'TEC')))
      fileTypeStr = 'Tech';
   elseif (any(strfind(fileName,'EOL')))
      fileTypeStr = 'Eol';
   else
      fileTypeStr = 'DataMeas';
   end

   switch (fileTypeStr)

      case {'SelfTest', 'Tech', 'Eol'}

         techData = decode_pfv2_tech_file(fileName, a_decoderId);

         % CSV output: techData = [fileType missionNum cycleNum {fileName} reportedDate {tabEvt} {nan} {nan} {nan} {nan} {tabEvtBis}];
         % NetCDF output: techData = [fileType missionNum cycleNum {fileName} reportedDate {tabTech} {tabTechTime} {tabTraj} {tabBuoy} {tabSpy} {tabTechBis}];

         if (~isempty(techData))
            floatData{idFile, 1} = techData{1}; % fileType
            floatData{idFile, 2} = techData{2}; % missionNum
            floatData{idFile, 3} = techData{3}; % cycleNum
            floatData{idFile, 4} = techData{4}; % fileName

            floatData{idFile, 5} = techData{6}; % tabTechEvt or tabTech
            floatData{idFile, 6} = techData{7}; % tabTechTime
            floatData{idFile, 7} = techData{8}; % tabTechTraj
            floatData{idFile, 8} = techData{9}; % tabTechBuoy
            floatData{idFile, 9} = techData{10}; % tabTechSpy

            floatData{idFile, 10} = techData{5}; % selfTestDate or cycleLastDate

            floatData{idFile, 11} = techData{11}; % tabTechBis (i.e. tech data but not for the current mission or cycle)
         else
            floatData{idFile, 1} = -1; % fileType
            floatData{idFile, 4} = floatData{idFile, 12}; % fileName
         end

      case {'DataMeas'}

         measData = decode_pfv2_data_file(fileName);

         % measData = [fileType missionNum cycleNum {fileName} sensorNum formatNum measData];

         if (~isempty(measData))
            floatData{idFile, 1} = measData{1}; % fileType
            floatData{idFile, 2} = measData{2}; % missionNum
            floatData{idFile, 3} = measData{3}; % cycleNum
            floatData{idFile, 4} = measData{4}; % fileName

            floatData{idFile, 5} = measData{5}; % sensorNum
            floatData{idFile, 6} = measData{6}; % formatNum
            floatData{idFile, 7} = measData{7}; % measData
         else
            floatData{idFile, 1} = -1; % fileType
            floatData{idFile, 4} = floatData{idFile, 12}; % fileName
         end

      case {'Config'}

         confData = decode_pfv2_config_file(fileName);

         % confData = [fileType missionNum cycleNum {fileName} settingDate {confLabels} {confValues}];

         if (~isempty(confData))
            floatData{idFile, 1} = confData{1}; % fileType
            floatData{idFile, 2} = confData{2}; % missionNum
            floatData{idFile, 3} = confData{3}; % cycleNum
            floatData{idFile, 4} = confData{4}; % fileName

            floatData{idFile, 5} = confData{6}; % confLabels
            floatData{idFile, 6} = confData{7}; % confValues

            floatData{idFile, 10} = confData{5}; % settingDate
         end

      case {'Command'}
         % not used
         fileType = 40;
         floatData{idFile, 1} = fileType; % fileType
         floatData{idFile, 4} = floatData{idFile, 12}; % fileName

         fileNameDate = datenum(fileName(1:12), 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
         floatData{idFile, 10} = fileNameDate; % date found in file name

      otherwise
         fprintf('ERROR: Float #%d: File type (%s) not implemented yet for file %s\n', ...
            g_decArgo_floatNum, ...
            fileType, ...
            fileName);
         break
   end
end

% remove inconsistent data files
idDel = find([floatData{:, 1}] == -1);
floatData(idDel, :) = [];

% reassign delayed TECH data
idTechList = find(~cellfun(@isempty, floatData(:, 11)));
for idT = idTechList'
   techTab = floatData{idT, 11};
   missionNum = techTab{1};
   cycleNum = techTab{2};
   techStructTab = techTab{3};
   idF = find(([floatData{:, 1}] == floatData{idT, 1}) & ([floatData{:, 2}] == missionNum) & ([floatData{:, 3}] == cycleNum));
   if (~isempty(idF))
      floatData(idF, 5) = {[floatData{idF, 5} techStructTab]};
   else
      fprintf('ERROR: Float #%d: Cannot assign delayed TECH data to the correct mission (#%d) and cycle (#%d)\n', ...
         g_decArgo_floatNum, ...
         missionNum, ...
         cycleNum);
   end
end
floatData(:, 11) = [];

% in case new mission has been created at sea
missionList = [floatData{:, 2}];
missionList(isnan(missionList)) = [];
missionNum = unique(missionList);
if (length(missionNum) > 1)
   fprintf('ERROR: Float #%d: Multi mission data files received, not implemented yet\n', ...
      g_decArgo_floatNum);
   return
end

% sort received files cycle (and date for configuration files)
floatDataSorted = cell(size(floatData));
cycleNumList = unique([floatData{:, 3}]);
cycleNumList = cycleNumList(~isnan(cycleNumList));
cpt = 1;
for cyNum = cycleNumList
   idF = find(([floatData{:, 3}] == cyNum) & ([floatData{:, 1}] == 11)); % TECH #1
   if (~isempty(idF))
      floatDataSorted(cpt, :) = floatData(idF, :);
      cpt = cpt + 1;
   end
   idF = find(([floatData{:, 3}] == cyNum) & ([floatData{:, 1}] == 12)); % TECH #2
   if (~isempty(idF))
      floatDataSorted(cpt, :) = floatData(idF, :);
      cpt = cpt + 1;
   end
   idF = find(([floatData{:, 3}] == cyNum) & ([floatData{:, 1}] ~= 11) & ([floatData{:, 1}] ~= 12) & ([floatData{:, 1}] ~= 13)); % remaining files (but EOL)
   if (~isempty(idF))
      floatDataSorted(cpt:cpt+length(idF)-1, :) = floatData(idF, :);
      cpt = cpt + length(idF);
   end
   idF = find(([floatData{:, 3}] == cyNum) & ([floatData{:, 1}] == 13)); % EOL
   if (~isempty(idF))
      [~, sortId] = sort([floatData{idF, 10}]);
      floatDataSorted(cpt:cpt+length(idF)-1, :) = floatData(idF(sortId), :);
      cpt = cpt + length(idF);
   end
end
% insert remaining dated files (10-self test, 40-command, 30-configuration)
datedId = find(ismember([floatData{:, 1}], [10 30 40]));
for id = datedId
   tech2Id = find([floatDataSorted{:, 1}] == 12);
   idF = find([floatDataSorted{tech2Id, 10}] <= floatData{id, 10}, 1, 'last');
   if (isempty(idF))
      idF = 1;
   end
   floatDataSorted(idF+1:end, :) = floatDataSorted(idF:end-1, :);
   floatDataSorted(idF, :) = floatData(id, :);
   cpt = cpt + 1;
end
if (cpt - 1 ~= size(floatData, 1))
   fprintf('ERROR: Float #%d: Error in sorting received data\n', ...
      g_decArgo_floatNum);
   return
end
floatData = floatDataSorted;

% set missionNum and cycleNum to configuration data
% the one of the previous TECH #2 file
confId = find([floatData{:, 1}] == 30);
tech2Id = find([floatData{:, 1}] == 12);
for id = confId
   floatData{id, 2} = missionNum;
   idF = find([floatData{tech2Id, 10}] <= floatData{id, 10}, 1, 'last');
   if (isempty(idF))
      floatData{id, 3} = 0;
   else
      floatData{id, 3} = floatData{tech2Id(idF), 3};
   end
end

o_floatData = floatData;

return
