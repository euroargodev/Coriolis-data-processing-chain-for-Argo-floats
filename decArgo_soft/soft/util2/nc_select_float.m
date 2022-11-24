% ------------------------------------------------------------------------------
% Select floats located in agiven list of geographical zones. The input data is
% an Argo monthly snapshot.
%
% SYNTAX :
%   nc_select_float
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
%   03/08/2017 - RNU - creation
% ------------------------------------------------------------------------------
function nc_select_float(varargin)

% top directory of input NetCDF mono-profile files
DIR_INPUT_NC_FILES = 'H:\archive_201702\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% geographical zones
% add as many geographical zones as needed; [latMin latMax lonMin lonMax] to
% define each one
geoZoneList = [ ...
   {[20 90 -80 25]} ... % North Atlantic
   {[-90 -30 -90 -30]} ... % cap Horn
   {[29 48 -7 42]} ... % Mediterranean
   ];

logFile = [DIR_LOG_CSV_FILE '/' 'nc_select_float_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

header1 = 'ZONE #; LAT_MIN; LAT_MAX; LON_MIN; LON_MAX';
header2 = 'DAC; WMO; FORMAT_VERSION; PLATFORM_TYPE; DAC_FORMAT_ID; PI_NAME; LAUNCH_DATE';
header3 = '; TRAJ FORMAT_VERSION; TRAJ PLATFORM_TYPE; NB_CYCLE; CYCLE_NUMBER_MAX; N_MEASUREMENT; N_MEAS_PER_CYCLE; MCs';

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_select_float_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end

fprintf(fidOut, '%s\n', header1);
for idZ = 1:length(geoZoneList)
   zone = geoZoneList{idZ};
   if (~isempty(zone))
      fprintf(fidOut, 'Z%d; %.3f; %.3f; %.3f; %.3f\n', ...
         idZ, zone);
   end
end
fprintf(fidOut, '%s', header2);
fprintf(fidOut, '; Z%d', 1:length(geoZoneList));
fprintf(fidOut, '%s\n', header3);

dacDir = dir(DIR_INPUT_NC_FILES);
for idDir = 1:length(dacDir)
   
   dacDirName = dacDir(idDir).name;
   
   % use the following lines to select/exclude DACs to be processed
   %    if (strcmp(dacDirName, 'doc') || ...
   %          strcmp(dacDirName, 'aoml'))
   %       continue
   %    end
   %    if (~strcmp(dacDirName, 'aoml'))
   %       continue
   %    end
   if (strcmp(dacDirName, 'doc'))
      continue
   end
   
   dacDirPathName = [DIR_INPUT_NC_FILES '/' dacDirName];
   if ((exist(dacDirPathName, 'dir') == 7) && ~strcmp(dacDirName, '.') && ~strcmp(dacDirName, '..'))
      
      fprintf('\nProcessing directory: %s\n', dacDirName);
      
      floatDir = dir(dacDirPathName);
      for idDir2 = 1:length(floatDir)
         
         zoneFlag = zeros(length(geoZoneList), 1);
         floatDirName = floatDir(idDir2).name;
         floatDirPathName = [dacDirPathName '/' floatDirName];
         if (exist(floatDirPathName, 'dir') == 7)
            
            fprintf('%03d/%03d %s\n', idDir2, length(floatDir), floatDirName);
            
            % TRAJ file
            
            floatTrajFilePathName = [dacDirPathName '/' floatDirName '/' floatDirName '_Rtraj.nc'];
            if ~(exist(floatTrajFilePathName, 'file') == 2)
               floatTrajFilePathName = [dacDirPathName '/' floatDirName '/' floatDirName '_Dtraj.nc'];
            end
            
            if (exist(floatTrajFilePathName, 'file') == 2)
               
               % retrieve information from meta-data file
               wantedInputVars = [ ...
                  {'FORMAT_VERSION'} ...
                  {'PLATFORM_TYPE'} ...
                  {'CYCLE_NUMBER'} ...
                  {'MEASUREMENT_CODE'} ...
                  {'LATITUDE'} ...
                  {'LONGITUDE'} ...
                  ];
               [metaData] = get_data_from_nc_file(floatTrajFilePathName, wantedInputVars);
               idVal = find(strcmp('FORMAT_VERSION', metaData(1:2:end)) == 1, 1);
               formatVersion = metaData{2*idVal};
               idVal = find(strcmp('PLATFORM_TYPE', metaData(1:2:end)) == 1, 1);
               platformType = metaData{2*idVal};
               idVal = find(strcmp('CYCLE_NUMBER', metaData(1:2:end)) == 1, 1);
               cycleNumber = metaData{2*idVal};
               NB_CYCLE = length(unique(cycleNumber));
               CYCLE_NUMBER_MAX = max(unique(cycleNumber));
               idVal = find(strcmp('MEASUREMENT_CODE', metaData(1:2:end)) == 1, 1);
               measurementCode = metaData{2*idVal};
               N_MEASUREMENT = length(measurementCode);
               N_MEAS_PER_CYCLE = N_MEASUREMENT/NB_CYCLE;
               idVal = find(strcmp('LATITUDE', metaData(1:2:end)) == 1, 1);
               latitude = metaData{2*idVal};
               idVal = find(strcmp('LONGITUDE', metaData(1:2:end)) == 1, 1);
               longitude = metaData{2*idVal};
               
               idF = find((cycleNumber >= 0) & (latitude ~= 99999) & (longitude ~= 99999));
               if (~isempty(idF))
                  lats = latitude(idF);
                  lons = longitude(idF);
                  
                  for idZ = 1:length(geoZoneList)
                     zone = geoZoneList{idZ};
                     if (~isempty(zone))
                        if (any((lats >= zone(1)) & (lats <= zone(2)) & (lons >= zone(3)) & (lons <= zone(4))))
                           zoneFlag(idZ) = 1;
                        end
                     end
                  end
               end
               
               if (any(zoneFlag == 1))
                  
                  % META file
                  
                  floatMetaFilePathName = [dacDirPathName '/' floatDirName '/' floatDirName '_meta.nc'];
                  
                  if (exist(floatMetaFilePathName, 'file') == 2)
                                          
                     % retrieve information from meta-data file
                     wantedInputVars = [ ...
                        {'FORMAT_VERSION'} ...
                        {'PLATFORM_TYPE'} ...
                        {'DAC_FORMAT_ID'} ...
                        {'PI_NAME'} ...
                        {'LAUNCH_DATE'} ...
                        ];
                     [metaData] = get_data_from_nc_file(floatMetaFilePathName, wantedInputVars);
                     idVal = find(strcmp('FORMAT_VERSION', metaData(1:2:end)) == 1, 1);
                     formatVersionTraj = metaData{2*idVal};
                     idVal = find(strcmp('PLATFORM_TYPE', metaData(1:2:end)) == 1, 1);
                     platformTypeTraj = metaData{2*idVal};
                     idVal = find(strcmp('DAC_FORMAT_ID', metaData(1:2:end)) == 1, 1);
                     dacFormatId = metaData{2*idVal};
                     idVal = find(strcmp('PI_NAME', metaData(1:2:end)) == 1, 1);
                     piName = metaData{2*idVal};
                     idVal = find(strcmp('LAUNCH_DATE', metaData(1:2:end)) == 1, 1);
                     launchDate = metaData{2*idVal};
                     
                     fprintf(fidOut, '%s; %s; %s; %s; %s; %s; %s', ...
                        strtrim(dacDirName), strtrim(floatDirName), ...
                        strtrim(formatVersion'), strtrim(platformType'), ...
                        strtrim(dacFormatId'), strtrim(piName'), strtrim(launchDate'));
                     
                     fprintf(fidOut, ';%d', zoneFlag);
                     
                     fprintf(fidOut, ';%s; %s; %d; %d; %d; %g', ...
                        strtrim(formatVersionTraj'), strtrim(platformTypeTraj'), ...
                        NB_CYCLE, CYCLE_NUMBER_MAX, N_MEASUREMENT, N_MEAS_PER_CYCLE);
                     
                     fprintf(fidOut, '; %d', ...
                        unique(measurementCode));
                     
                     fprintf(fidOut, '\n');
                  end
               end
            end
         end
      end
   end
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

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
      return
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

% ------------------------------------------------------------------------------
% Check if a given variable is present in a NetCDF file.
%
% SYNTAX :
%  [o_present] = var_is_present_dec_argo(a_ncId, a_varName)
%
% INPUT PARAMETERS :
%   a_ncId    : NetCDF file Id
%   a_varName : variable name
%
% OUTPUT PARAMETERS :
%   o_present : 1 if the variable is present (0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/27/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_present] = var_is_present_dec_argo(a_ncId, a_varName)

o_present = 0;

[nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(a_ncId);

for idVar= 0:nbVars-1
   [varName, varType, varDims, nbAtts] = netcdf.inqVar(a_ncId, idVar);
   if (strcmp(varName, a_varName))
      o_present = 1;
      break
   end
end

return
