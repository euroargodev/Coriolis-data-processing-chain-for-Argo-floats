% ------------------------------------------------------------------------------
% Retrieve static meta-data information from NetCDF meta files.
%
% SYNTAX :
%   nc_collect_static_meta_data
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/09/2018 - RNU - creation
% ------------------------------------------------------------------------------
function nc_collect_static_meta_data(varargin)

% top directory of input NetCDF mono-profile files
DIR_INPUT_NC_FILES = 'E:\archive_201510\201510-ArgoData\DATA\';
DIR_INPUT_NC_FILES = 'H:\archive_201801\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';


logFile = [DIR_LOG_CSV_FILE '/' 'nc_collect_static_meta_data_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

header = ['DAC; WMO; FORMAT_VERSION; PLATFORM_NUMBER; PTT; TRANS_SYSTEM; ' ...
   'POSITIONING_SYSTEM; PLATFORM_FAMILY; PLATFORM_TYPE; PLATFORM_MAKER; ' ...
   'FIRMWARE_VERSION; FLOAT_SERIAL_NO; DAC_FORMAT_ID'];

dacDir = dir(DIR_INPUT_NC_FILES);
for idDir = 1:length(dacDir)
   
   dacDirName = dacDir(idDir).name;
   dacDirPathName = [DIR_INPUT_NC_FILES '/' dacDirName];
   if ((exist(dacDirPathName, 'dir') == 7) && ~strcmp(dacDirName, '.') && ~strcmp(dacDirName, '..'))
      
      fprintf('\nProcessing directory: %s\n', dacDirName);
      
      % create the CSV output file
      outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_collect_static_meta_data_' dacDirName '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
      fidOut = fopen(outputFileName, 'wt');
      if (fidOut == -1)
         return
      end
      fprintf(fidOut, '%s\n', header);
      
      floatDir = dir(dacDirPathName);
      for idDir2 = 1:length(floatDir)
         
         floatDirName = floatDir(idDir2).name;
         floatDirPathName = [dacDirPathName '/' floatDirName];
         if (exist(floatDirPathName, 'dir') == 7)
            
            floatMetaFilePathName = [dacDirPathName '/' floatDirName '/' floatDirName '_meta.nc'];
            
            if (exist(floatMetaFilePathName, 'file') == 2)
               
               fprintf('%03d/%03d %s\n', idDir2, length(floatDir), floatDirName);
                              
               % retrieve information from meta-data file
               wantedInputVars = [ ...
                  {'FORMAT_VERSION'} ...
                  {'PLATFORM_NUMBER'} ...
                  {'PTT'} ...
                  {'TRANS_SYSTEM'} ...
                  {'POSITIONING_SYSTEM'} ...
                  {'PLATFORM_FAMILY'} ...
                  {'PLATFORM_TYPE'} ...
                  {'PLATFORM_MAKER'} ...
                  {'FIRMWARE_VERSION'} ...
                  {'FLOAT_SERIAL_NO'} ...
                  {'DAC_FORMAT_ID'} ...
                  ];
               [metaData] = get_data_from_nc_file(floatMetaFilePathName, wantedInputVars);
               
               idVal = find(strcmp('FORMAT_VERSION', metaData(1:2:end)) == 1, 1);
               formatVersion = metaData{2*idVal};
               idVal = find(strcmp('PLATFORM_NUMBER', metaData(1:2:end)) == 1, 1);
               platformNumber = metaData{2*idVal};
               idVal = find(strcmp('PTT', metaData(1:2:end)) == 1, 1);
               ptt = metaData{2*idVal};
               idVal = find(strcmp('TRANS_SYSTEM', metaData(1:2:end)) == 1, 1);
               transSystem = metaData{2*idVal};
               idVal = find(strcmp('POSITIONING_SYSTEM', metaData(1:2:end)) == 1, 1);
               posSystem = metaData{2*idVal};
               if (size(posSystem, 2) > 1)
                   positioningSystem = strtrim(posSystem(:, 1)');
                  for idPs = 2:size(posSystem, 2)
                     positioningSystem = [positioningSystem '/' strtrim(posSystem(:, idPs)')];
                  end
               else
                  positioningSystem = strtrim(posSystem);
               end
               idVal = find(strcmp('PLATFORM_FAMILY', metaData(1:2:end)) == 1, 1);
               platformFamily = metaData{2*idVal};
               idVal = find(strcmp('PLATFORM_TYPE', metaData(1:2:end)) == 1, 1);
               platformType = metaData{2*idVal};
               idVal = find(strcmp('PLATFORM_MAKER', metaData(1:2:end)) == 1, 1);
               platformMaker = metaData{2*idVal};
               idVal = find(strcmp('FIRMWARE_VERSION', metaData(1:2:end)) == 1, 1);
               firmwareVersion = metaData{2*idVal};
               idVal = find(strcmp('FLOAT_SERIAL_NO', metaData(1:2:end)) == 1, 1);
               floatSerialNum = metaData{2*idVal};
               idVal = find(strcmp('DAC_FORMAT_ID', metaData(1:2:end)) == 1, 1);
               dacFormatId = metaData{2*idVal};
               
               fprintf(fidOut, '%s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s\n', ...
                  strtrim(dacDirName), strtrim(floatDirName), ...
                  strtrim(formatVersion'), ...
                  strtrim(platformNumber'), ...
                  strtrim(ptt'), ...
                  strtrim(transSystem'), ...
                  positioningSystem, ...
                  strtrim(platformFamily'), ...
                  strtrim(platformType'), ...
                  strtrim(platformMaker'), ...
                  strtrim(firmwareVersion'), ...
                  strtrim(floatSerialNum'), ...
                  strtrim(dacFormatId'));
            end
         end
      end
      fclose(fidOut);
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
