% ------------------------------------------------------------------------------
% Retrieve VSS information from NetCDF mono-profile files.
%
% SYNTAX :
%   nc_collect_vss
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
%   10/13/2015 - RNU - creation
% ------------------------------------------------------------------------------
function nc_collect_vss(varargin)

% top directory of input NetCDF mono-profile files
DIR_INPUT_NC_FILES = 'E:\archive_201510\201510-ArgoData\DATA\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';


logFile = [DIR_LOG_CSV_FILE '/' 'nc_collect_vss_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

header = ['DAC; WMO; PLATFORM_TYPE; PLATFORM_MAKER; FLOAT_SERIAL_NO; DAC_FORMAT_ID; File name; FORMAT_VERSION; N_PROF; CYCLE_NUMBER; DIRECTION; DATA_MODE; POSITIONING_SYSTEM; VSS'];

dacDir = dir(DIR_INPUT_NC_FILES);
for idDir = 1:length(dacDir)
   
   dacDirName = dacDir(idDir).name;
   dacDirPathName = [DIR_INPUT_NC_FILES '/' dacDirName];
   if ((exist(dacDirPathName, 'dir') == 7) && ~strcmp(dacDirName, '.') && ~strcmp(dacDirName, '..'))
      
      fprintf('\nProcessing directory: %s\n', dacDirName);
      
      % create the CSV output file
      outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_collect_vss_' dacDirName '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
      fidOut = fopen(outputFileName, 'wt');
      if (fidOut == -1)
         return;
      end
      fprintf(fidOut, '%s\n', header);

      floatDir = dir(dacDirPathName);
      for idDir2 = 1:length(floatDir)
         %       for idDir2 = 1:3
         
         floatDirName = floatDir(idDir2).name;
         floatDirPathName = [dacDirPathName '/' floatDirName];
         if (exist(floatDirPathName, 'dir') == 7)
            
            floatProfDirPathName = [dacDirPathName '/' floatDirName '/profiles/'];
            floatMetaFilePathName = [dacDirPathName '/' floatDirName '/' floatDirName '_meta.nc'];
            
            if ((exist(floatProfDirPathName, 'dir') == 7) && (exist(floatMetaFilePathName, 'file') == 2))
               
               fprintf('%03d/%03d %s\n', idDir2, length(floatDir), floatDirName);
               
               % retrieve information from meta-data file
               wantedInputVars = [ ...
                  {'DAC_FORMAT_ID'} ...
                  {'PLATFORM_TYPE'} ...
                  {'PLATFORM_MAKER'} ...
                  {'FLOAT_SERIAL_NO'} ...
                  ];
               [metaData] = get_data_from_nc_file(floatMetaFilePathName, wantedInputVars);
               idVal = find(strcmp('DAC_FORMAT_ID', metaData(1:2:end)) == 1, 1);
               dacFormatId = metaData{2*idVal};
               idVal = find(strcmp('PLATFORM_TYPE', metaData(1:2:end)) == 1, 1);
               platformType = metaData{2*idVal};
               idVal = find(strcmp('PLATFORM_MAKER', metaData(1:2:end)) == 1, 1);
               platformMaker = metaData{2*idVal};
               idVal = find(strcmp('FLOAT_SERIAL_NO', metaData(1:2:end)) == 1, 1);
               floatSerialNum = metaData{2*idVal};
               
               profDir = dir(floatProfDirPathName);
               for idProf = 1:length(profDir)
                  
                  profFileName = profDir(idProf).name;
                  profFilePathName = [floatProfDirPathName '/' profFileName];
                  if (exist(profFilePathName, 'file') == 2)
                     
                     % retrieve information from profile file
                     wantedInputVars = [ ...
                        {'FORMAT_VERSION'} ...
                        {'CYCLE_NUMBER'} ...
                        {'DIRECTION'} ...
                        {'DATA_MODE'} ...
                        {'POSITIONING_SYSTEM'} ...
                        {'VERTICAL_SAMPLING_SCHEME'} ...
                        ];
                     [profData] = get_data_from_nc_file(profFilePathName, wantedInputVars);
                     idVal = find(strcmp('FORMAT_VERSION', profData(1:2:end)) == 1, 1);
                     formatVersion = profData{2*idVal};
                     idVal = find(strcmp('CYCLE_NUMBER', profData(1:2:end)) == 1, 1);
                     cycleNumber = profData{2*idVal};
                     nProfDim = length(cycleNumber);
                     idVal = find(strcmp('DIRECTION', profData(1:2:end)) == 1, 1);
                     direction = profData{2*idVal};
                     idVal = find(strcmp('DATA_MODE', profData(1:2:end)) == 1, 1);
                     dataMode = profData{2*idVal};
                     idVal = find(strcmp('POSITIONING_SYSTEM', profData(1:2:end)) == 1, 1);
                     positioningSystem = profData{2*idVal};
                     idVal = find(strcmp('VERTICAL_SAMPLING_SCHEME', profData(1:2:end)) == 1, 1);
                     vss = profData{2*idVal};
                     
                     for idP = 1:nProfDim
                        if (~isempty(vss))
                           vssStr = vss(:, idP)';
                           vssStr = regexprep(vssStr, ';', '/');
                           if (~isempty(vssStr))
                              fprintf(fidOut, '%s; %s; %s; %s; %s; %s; %s; %s; %d; %d; %c; %c; %s; %s\n', ...
                                 strtrim(dacDirName), strtrim(floatDirName), ...
                                 strtrim(platformType'), strtrim(platformMaker'), ...
                                 strtrim(floatSerialNum'), strtrim(dacFormatId'), ...
                                 strtrim(profFileName), strtrim(formatVersion'), ...
                                 idP, cycleNumber(idP), direction(idP), dataMode(idP), ...
                                 strtrim(positioningSystem(:, idP)'), strtrim(vssStr));
                           else
                              fprintf(fidOut, '%s; %s; %s; %s; %s; %s; %s; %s; %d; %d; %c; %c; %s; empty\n', ...
                                 strtrim(dacDirName), strtrim(floatDirName), ...
                                 strtrim(platformType'), strtrim(platformMaker'), ...
                                 strtrim(floatSerialNum'), strtrim(dacFormatId'), ...
                                 strtrim(profFileName), strtrim(formatVersion'), ...
                                 idP, cycleNumber(idP), direction(idP), dataMode(idP), ...
                                 strtrim(positioningSystem(:, idP)'));
                           end
                        else
                           fprintf(fidOut, '%s; %s; %s; %s; %s; %s; %s; %s; %d; %d; %c; %c; %s; not found\n', ...
                              strtrim(dacDirName), strtrim(floatDirName), ...
                              strtrim(platformType'), strtrim(platformMaker'), ...
                              strtrim(floatSerialNum'), strtrim(dacFormatId'), ...
                              strtrim(profFileName), strtrim(formatVersion'), ...
                              idP, cycleNumber(idP), direction(idP), dataMode(idP), ...
                              strtrim(positioningSystem(:, idP)'));
                        end
                     end
                  end
               end
            end
         end
      end
      fclose(fidOut);
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;

% ------------------------------------------------------------------------------
% Retrieve data from NetCDF file.
%
% SYNTAX :
%  [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : NetCDF file name
%   a_wantedVars     : NetCDF variables to retrieve from the file
%
% OUTPUT PARAMETERS :
%   o_ncData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)

% output parameters initialization
o_ncData = [];


if (exist(a_ncPathFileName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return;
   end
   
   % retrieve variables from NetCDF file
   for idVar = 1:length(a_wantedVars)
      varName = a_wantedVars{idVar};
      
      if (var_is_present_dec_argo(fCdf, varName))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
         o_ncData = [o_ncData {varName} {varValue}];
      else
         %          fprintf('WARNING: Variable %s not present in file : %s\n', ...
         %             varName, a_ncPathFileName);
         o_ncData = [o_ncData {varName} {''}];
      end
      
   end
   
   netcdf.close(fCdf);
end
