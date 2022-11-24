% ------------------------------------------------------------------------------
% Read all .profile files of a NEMO float and retrieve meta-data and data in a
% CSV file.
%
% SYNTAX :
%   collect_nemo_profile_info
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/04/2017 - RNU - creation
% ------------------------------------------------------------------------------
function collect_nemo_profile_info

% directory of .profile files
DIR_INPUT_PROFILE_FILES = 'C:\Users\jprannou\_DATA\IN\NEMO\nemo_data_from_v2_20181026\co01010302\archive\cycle\';
DIR_INPUT_PROFILE_FILES = 'C:\Users\jprannou\_DATA\IN\NEMO\nemo_data_from_v2_manu\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the output csv files
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';


% create and start log file recording
timeInfo = datestr(now, 'yyyymmddTHHMMSS');
logFile = [DIR_LOG_FILE '/' 'collect_nemo_profile_info_' timeInfo '.log'];
diary(logFile);
tic;

floatDataAll = [];
floatData2All = [];
floatIdentificationItems = [];
overallMissionInformationItems = [];
deploymentInfoItems = [];
profileTechnicalDataItems = [];
bottomValuesDuringDriftItems = [];
rafosValuesFormatItems = [];
profileHeaderItems = [];
qualityControlHeaderItems = [];
profileDataHeaderItems = [];
surfaceGpsDataFormatItems = [];
iridiumPositionsFormatItems = [];
iridiumDataFormatItems = [];
startupMessageItems = [];
secondOrderInformationItems = [];

floatDirs = dir(DIR_INPUT_PROFILE_FILES);
for idDir = 1:length(floatDirs)
   
   floatDataFields = [];
   floatData = [];
   floatData2Fields = [];
   floatData2 = [];
   
   floatDirName = floatDirs(idDir).name;
   
%    if (~strcmp(floatDirName, '0187'))
%       continue
%    end
%       if (~strcmp(floatDirName, '0185') && ~strcmp(floatDirName, '0187') && ~strcmp(floatDirName, '0188'))
%          continue
%       end
   
   floatDirPathName = [DIR_INPUT_PROFILE_FILES '/' floatDirName];
   if ((exist(floatDirPathName, 'dir') == 7) && ~strcmp(floatDirName, '.') && ~strcmp(floatDirName, '..'))
            
      floatFiles = dir([floatDirPathName '/*.profile']);
      
      fprintf('%02d/%02d Processing directory: %s (%d files)\n', ...
         idDir, length(floatDirs), floatDirName, length(floatFiles));

      for idFile = 1:length(floatFiles)
         floatFileName = floatFiles(idFile).name;
         floatFilePathName = [floatDirPathName '/' floatFileName];
         if (exist(floatFilePathName, 'file') == 2)
            
            % read .profile file
            [ ...
               error, ...
               floatIdentificationStr, ...
               overallMissionInformationStr, ...
               deploymentInfoStr, ...
               profileTechnicalDataStr, ...
               bottomValuesDuringDriftStr, ...
               rafosValuesFormatStr, ...
               rafosValuesStr, ...
               profileHeaderStr, ...
               qualityControlHeaderStr, ...
               profileDataHeaderStr, ...
               profileDataStr, ...
               surfaceGpsDataFormatStr, ...
               surfaceGpsDataStr, ...
               iridiumPositionsFormatStr, ...
               iridiumPositionsStr, ...
               iridiumDataFormatStr, ...
               iridiumDataStr, ...
               startupMessageStr, ...
               secondOrderInformationStr ...
               ] = read_nemo_profile_file(floatFilePathName);
            if (error == 1)
               fprintf('ERROR: Error in file: %s => ignored\n', floatFilePathName);
               continue
            elseif (error == 2)
               continue
            end
            
            % parse information and parameter measurements
            floatIdentification = parse_nemo_info(floatIdentificationStr);
            floatIdentificationItems = unique([floatIdentificationItems; fieldnames(floatIdentification)], 'stable');
            
            overallMissionInformation = parse_nemo_info(overallMissionInformationStr);
            overallMissionInformationItems = unique([overallMissionInformationItems; fieldnames(overallMissionInformation)], 'stable');

            deploymentInfo = parse_nemo_info(deploymentInfoStr);
            deploymentInfoItems = unique([deploymentInfoItems; fieldnames(deploymentInfo)], 'stable');

            profileTechnicalData = parse_nemo_info(profileTechnicalDataStr);
            profileTechnicalDataItems = unique([profileTechnicalDataItems; fieldnames(profileTechnicalData)], 'stable');
            
            bottomValuesDuringDrift = parse_nemo_info(bottomValuesDuringDriftStr);
            bottomValuesDuringDriftItems = unique([bottomValuesDuringDriftItems; fieldnames(bottomValuesDuringDrift)], 'stable');

            rafosValuesFormatItems = unique([rafosValuesFormatItems; strsplit(rafosValuesFormatStr{:}, '\t')'], 'stable');

            profileHeader = parse_nemo_info(profileHeaderStr);
            profileHeaderItems = unique([profileHeaderItems; fieldnames(profileHeader)], 'stable');

            qualityControlHeader = parse_nemo_info(qualityControlHeaderStr);
            qualityControlHeaderItems = unique([qualityControlHeaderItems; fieldnames(qualityControlHeader)], 'stable');
            
            if (~isempty(profileDataHeaderStr))
               profileDataHeaderItems = unique([profileDataHeaderItems; strsplit(profileDataHeaderStr{:}, '\t')'], 'stable');
            else
               fprintf('WARNING: ''PROFILE_DATA_HEADER'' section not found in file %s\n', floatFileName);
            end
            
            surfaceGpsDataFormatItems = unique([surfaceGpsDataFormatItems; strsplit(surfaceGpsDataFormatStr{:}, '\t')'], 'stable');
            
            iridiumPositionsFormatItems = unique([iridiumPositionsFormatItems; strsplit(iridiumPositionsFormatStr{:}, '\t')'], 'stable');
            
            iridiumDataFormatItems = unique([iridiumDataFormatItems; strsplit(iridiumDataFormatStr{:}, '\t')'], 'stable');
            
            startupMessage = [];
            if (~isempty(startupMessageStr))
               startupMessage = parse_nemo_info(startupMessageStr);
               startupMessageItems = unique([startupMessageItems; fieldnames(startupMessage)], 'stable');
            else
               fprintf('WARNING: ''STARTUP_MESSAGE'' section not found in file %s\n', floatFileName);
            end
            
            secondOrderInformation = parse_nemo_info(secondOrderInformationStr);
            secondOrderInformationItems = unique([secondOrderInformationItems; fieldnames(secondOrderInformation)], 'stable');
            
            % store FLOAT_IDENTIFICATION data of all floats
            inputFields = fieldnames(floatIdentification);
            for idField = 1:length(inputFields)
               fieldNameIn = inputFields{idField};
               fieldNameOut = ['FLOAT_IDENTIFICATION_' inputFields{idField}];
               if (~ismember(fieldNameOut, floatDataFields))
                  floatDataFields{end+1} = fieldNameOut;
                  floatData.(fieldNameOut) = {floatIdentification.(fieldNameIn)};
               else
                  floatData.(fieldNameOut){end+1} = floatIdentification.(fieldNameIn);
                  floatData.(fieldNameOut) = unique(floatData.(fieldNameOut));
               end
            end
            
            % store OVERALL_MISSION_INFORMATION data of all floats
            inputFields = fieldnames(overallMissionInformation);
            for idField = 1:length(inputFields)
               fieldNameIn = inputFields{idField};
               fieldNameOut = ['OVERALL_MISSION_INFORMATION_' inputFields{idField}];
               if (~ismember(fieldNameOut, floatDataFields))
                  floatDataFields{end+1} = fieldNameOut;
                  floatData.(fieldNameOut) = {overallMissionInformation.(fieldNameIn)};
               else
                  floatData.(fieldNameOut){end+1} = overallMissionInformation.(fieldNameIn);
                  floatData.(fieldNameOut) = unique(floatData.(fieldNameOut));
               end
            end
            
            % store DEPLOYMENT_INFO data of all floats
            inputFields = fieldnames(deploymentInfo);
            for idField = 1:length(inputFields)
               fieldNameIn = inputFields{idField};
               fieldNameOut = ['DEPLOYMENT_INFO_' inputFields{idField}];
               if (~ismember(fieldNameOut, floatDataFields))
                  floatDataFields{end+1} = fieldNameOut;
                  floatData.(fieldNameOut) = {deploymentInfo.(fieldNameIn)};
               else
                  floatData.(fieldNameOut){end+1} = deploymentInfo.(fieldNameIn);
                  floatData.(fieldNameOut) = unique(floatData.(fieldNameOut));
               end
            end
            
            % store STARTUP_MESSAGE data of all floats
            if (~isempty(startupMessage))
               inputFields = fieldnames(startupMessage);
               for idField = 1:length(inputFields)
                  fieldNameIn = inputFields{idField};
                  fieldNameOut = ['STARTUP_MESSAGE_' inputFields{idField}];
                  if (~ismember(fieldNameOut, floatDataFields))
                     floatDataFields{end+1} = fieldNameOut;
                     floatData.(fieldNameOut) = {startupMessage.(fieldNameIn)};
                  else
                     floatData.(fieldNameOut){end+1} = startupMessage.(fieldNameIn);
                     floatData.(fieldNameOut) = unique(floatData.(fieldNameOut));
                  end
               end
            end
                        
            % store PROFILE_TECHNICAL_DATA data of all floats
            inputFields = fieldnames(profileTechnicalData);
            for idField = 1:length(inputFields)
               fieldNameIn = inputFields{idField};
               fieldNameOut = ['PROFILE_TECHNICAL_DATA_' inputFields{idField}];
               if (~ismember(fieldNameOut, floatData2Fields))
                  floatData2Fields{end+1} = fieldNameOut;
                  floatData2.(fieldNameOut) = {profileTechnicalData.(fieldNameIn)};
               else
                  floatData2.(fieldNameOut){end+1} = profileTechnicalData.(fieldNameIn);
                  floatData2.(fieldNameOut) = unique(floatData2.(fieldNameOut));
               end
            end
            
            % store BOTTOM_VALUES_DURING_DRIFT data of all floats
            inputFields = fieldnames(bottomValuesDuringDrift);
            for idField = 1:length(inputFields)
               fieldNameIn = inputFields{idField};
               fieldNameOut = ['BOTTOM_VALUES_DURING_DRIFT_' inputFields{idField}];
               if (~ismember(fieldNameOut, floatData2Fields))
                  floatData2Fields{end+1} = fieldNameOut;
                  floatData2.(fieldNameOut) = {bottomValuesDuringDrift.(fieldNameIn)};
               else
                  floatData2.(fieldNameOut){end+1} = bottomValuesDuringDrift.(fieldNameIn);
                  floatData2.(fieldNameOut) = unique(floatData2.(fieldNameOut));
               end
            end
            
            % store PROFILE_HEADER data of all floats
            inputFields = fieldnames(profileHeader);
            for idField = 1:length(inputFields)
               fieldNameIn = inputFields{idField};
               fieldNameOut = ['PROFILE_HEADER_' inputFields{idField}];
               if (~ismember(fieldNameOut, floatData2Fields))
                  floatData2Fields{end+1} = fieldNameOut;
                  floatData2.(fieldNameOut) = {profileHeader.(fieldNameIn)};
               else
                  floatData2.(fieldNameOut){end+1} = profileHeader.(fieldNameIn);
                  floatData2.(fieldNameOut) = unique(floatData2.(fieldNameOut));
               end
            end
            
            % store QUALITY_CONTROL_HEADER data of all floats
            inputFields = fieldnames(qualityControlHeader);
            for idField = 1:length(inputFields)
               fieldNameIn = inputFields{idField};
               fieldNameOut = ['QUALITY_CONTROL_HEADER_' inputFields{idField}];
               if (~ismember(fieldNameOut, floatData2Fields))
                  floatData2Fields{end+1} = fieldNameOut;
                  floatData2.(fieldNameOut) = {qualityControlHeader.(fieldNameIn)};
               else
                  floatData2.(fieldNameOut){end+1} = qualityControlHeader.(fieldNameIn);
                  floatData2.(fieldNameOut) = unique(floatData2.(fieldNameOut));
               end
            end
            
            % store SECOND_ORDER_INFORMATION data of all floats
            inputFields = fieldnames(secondOrderInformation);
            for idField = 1:length(inputFields)
               fieldNameIn = inputFields{idField};
               fieldNameOut = ['SECOND_ORDER_INFORMATION_' inputFields{idField}];
               if (~ismember(fieldNameOut, floatData2Fields))
                  floatData2Fields{end+1} = fieldNameOut;
                  floatData2.(fieldNameOut) = {secondOrderInformation.(fieldNameIn)};
               else
                  floatData2.(fieldNameOut){end+1} = secondOrderInformation.(fieldNameIn);
                  floatData2.(fieldNameOut) = unique(floatData2.(fieldNameOut));
               end
            end
         end
      end
            
      floatDataFinal = [];
      floatDataFinal.id = floatDirName;
      floatDataFinal.floatData = floatData;
      floatDataAll = [floatDataAll floatDataFinal];
      
      floatData2Final = [];
      floatData2Final.id = floatDirName;
      floatData2Final.floatData = floatData2;
      floatData2All = [floatData2All floatData2Final];
   end
end

fieldNameAll = [];
for idD = 1:length(floatDataAll)
   fieldNameAll = [fieldNameAll; fieldnames(floatDataAll(idD).floatData)];
end
fieldNameAll = unique(fieldNameAll);

% create the CSV output file
outputFileName = [DIR_CSV_FILE '/' 'collect_nemo_profile_section_info_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = 'Float Id';
fprintf(fidOut, '%s', header);
fprintf(fidOut, ';%s', fieldNameAll{:});
fprintf(fidOut, '\n');

for idD = 1:length(floatDataAll)
   fprintf(fidOut, '%s', floatDataAll(idD).id);
   
   for idField = 1:length(fieldNameAll)
      if (isfield(floatDataAll(idD).floatData, fieldNameAll{idField}))
         data = floatDataAll(idD).floatData.(fieldNameAll{idField});
         if (length(data) > 1)
            data = sprintf('%s|', data{:});
            data(end) = [];
         else
            data = data{:};
         end
         data = regexprep(data, char(9), ' ');
         fprintf(fidOut, '; %s', data);
      else
         fprintf(fidOut, ';');
      end
   end
   fprintf(fidOut, '\n');
end

fclose(fidOut);

fieldNameAll2 = [];
for idD = 1:length(floatData2All)
   fieldNameAll2 = [fieldNameAll2; fieldnames(floatData2All(idD).floatData)];
end
fieldNameAll2 = unique(fieldNameAll2);

% create the CSV output file
outputFileName = [DIR_CSV_FILE '/' 'collect_nemo_profile_section_info2_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = 'Float Id';
fprintf(fidOut, '%s', header);
fprintf(fidOut, ';%s', fieldNameAll2{:});
fprintf(fidOut, '\n');

for idD = 1:length(floatData2All)
   fprintf(fidOut, '%s', floatData2All(idD).id);
   
   for idField = 1:length(fieldNameAll2)
      if (isfield(floatData2All(idD).floatData, fieldNameAll2{idField}))
         data = floatData2All(idD).floatData.(fieldNameAll2{idField});
         if (length(data) > 1)
            data = sprintf('%s|', data{:});
            data(end) = [];
         else
            data = data{:};
         end
         data = regexprep(data, char(9), ' ');
         fprintf(fidOut, '; %s', data);
      else
         fprintf(fidOut, ';');
      end
   end
   fprintf(fidOut, '\n');
end

fclose(fidOut);

% create the CSV output file
outputFileName = [DIR_CSV_FILE '/' 'collect_nemo_profile_secion_items_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end

item = 'FLOAT_IDENTIFICATION';
for id = 1:length(floatIdentificationItems)
   fprintf(fidOut, '%s;%s\n', item, floatIdentificationItems{id});
end
item = 'OVERALL_MISSION_INFORMATION';
for id = 1:length(overallMissionInformationItems)
   fprintf(fidOut, '%s;%s\n', item, overallMissionInformationItems{id});
end
item = 'DEPLOYMENT_INFO';
for id = 1:length(deploymentInfoItems)
   fprintf(fidOut, '%s;%s\n', item, deploymentInfoItems{id});
end
item = 'PROFILE_TECHNICAL_DATA';
for id = 1:length(profileTechnicalDataItems)
   fprintf(fidOut, '%s;%s\n', item, profileTechnicalDataItems{id});
end
item = 'BOTTOM_VALUES_DURING_DRIFT';
for id = 1:length(bottomValuesDuringDriftItems)
   fprintf(fidOut, '%s;%s\n', item, bottomValuesDuringDriftItems{id});
end
item = 'RAFOS_VALUES_FORMAT';
for id = 1:length(rafosValuesFormatItems)
   fprintf(fidOut, '%s;%s\n', item, rafosValuesFormatItems{id});
end
item = 'PROFILE_HEADER';
for id = 1:length(profileHeaderItems)
   fprintf(fidOut, '%s;%s\n', item, profileHeaderItems{id});
end
item = 'QUALITY_CONTROL_HEADER';
for id = 1:length(qualityControlHeaderItems)
   fprintf(fidOut, '%s;%s\n', item, qualityControlHeaderItems{id});
end
item = 'PROFILE_DATA_HEADER';
for id = 1:length(profileDataHeaderItems)
   fprintf(fidOut, '%s;%s\n', item, profileDataHeaderItems{id});
end
item = 'SURFACE_GPS_DATA_FORMAT';
for id = 1:length(surfaceGpsDataFormatItems)
   fprintf(fidOut, '%s;%s\n', item, surfaceGpsDataFormatItems{id});
end
item = 'IRIDIUM_POSITIONS_FORMAT';
for id = 1:length(iridiumPositionsFormatItems)
   fprintf(fidOut, '%s;%s\n', item, iridiumPositionsFormatItems{id});
end
item = 'IRIDIUM_DATA_FORMAT';
for id = 1:length(iridiumDataFormatItems)
   fprintf(fidOut, '%s;%s\n', item, iridiumDataFormatItems{id});
end
item = 'STARTUP_MESSAGE';
for id = 1:length(startupMessageItems)
   fprintf(fidOut, '%s;%s\n', item, startupMessageItems{id});
end
item = 'SECOND_ORDER_INFORMATION';
for id = 1:length(secondOrderInformationItems)
   fprintf(fidOut, '%s;%s\n', item, secondOrderInformationItems{id});
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
