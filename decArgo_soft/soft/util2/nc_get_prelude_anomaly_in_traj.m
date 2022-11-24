% ------------------------------------------------------------------------------
% Retrieve time difference between first and last location of cycle #0.
%
% SYNTAX :
%   nc_get_prelude_anomaly_in_traj
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
%   08/26/2021 - RNU - creation
% ------------------------------------------------------------------------------
function nc_get_prelude_anomaly_in_traj

% list of floats to process
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\nke_argos.txt';

% top directory of input NetCDF mono-profile files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\E_DAC_TRAJ\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';

% global measurement codes
global g_MC_Surface;


% default values initialization
init_default_values;

% measurement codes initialization
init_measurement_codes;

logFile = [DIR_LOG_CSV_FILE '/' 'nc_get_prelude_anomaly_in_traj_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

header = ['DAC; WMO; CYCLE #; LOC_MIN_DATE; LOC_MAX_DATE; LOC_SPAN_TIME (hour)'];

floatList = load(FLOAT_LIST_FILE_NAME);

dacDir = dir(DIR_INPUT_NC_FILES);
for idDir = 1:length(dacDir)
   
   dacDirName = dacDir(idDir).name;
   
   % use the following lines to select/exclude DACs to be processed
   %    if (strcmp(dacDirName, 'doc') || ...
   %          strcmp(dacDirName, 'aoml'))
   %       continue
   %    end
   
   dacDirPathName = [DIR_INPUT_NC_FILES '/' dacDirName];
   if ((exist(dacDirPathName, 'dir') == 7) && ~strcmp(dacDirName, '.') && ~strcmp(dacDirName, '..'))
      
      fprintf('\nProcessing directory: %s\n', dacDirName);
            
      % create the CSV output file
      outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_get_prelude_anomaly_in_traj_' dacDirName '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
      fidOut = fopen(outputFileName, 'wt');
      if (fidOut == -1)
         return
      end
      fprintf(fidOut, '%s\n', header);
      
      floatDir = dir(dacDirPathName);
      for idDir2 = 1:length(floatDir)
         
         floatDirName = floatDir(idDir2).name;
         floatDirPathName = [dacDirPathName '/' floatDirName];
         if ((exist(floatDirPathName, 'dir') == 7) && ~strcmp(floatDirName, '.') && ~strcmp(floatDirName, '..'))
            
            if (~ismember(str2double(floatDirName), floatList))
               continue
            end
            
            % TRAJ file
            
            floatTrajFilePathName = [dacDirPathName '/' floatDirName '/' floatDirName '_Rtraj.nc'];
            if ~(exist(floatTrajFilePathName, 'file') == 2)
               floatTrajFilePathName = [dacDirPathName '/' floatDirName '/' floatDirName '_Dtraj.nc'];
            end
            
            if (exist(floatTrajFilePathName, 'file') == 2)
               
               fprintf('   %s\n', floatDirName);

               % retrieve information from traj file
               wantedInputVars = [ ...
                  {'FORMAT_VERSION'} ...
                  {'JULD'} ...
                  {'CYCLE_NUMBER'} ...
                  {'MEASUREMENT_CODE'} ...
                  ];
               [trajData] = get_data_from_nc_file(floatTrajFilePathName, wantedInputVars);
               
               idVal = find(strcmp('FORMAT_VERSION', trajData(1:2:end)) == 1, 1);
               formatVersion = strtrim(trajData{2*idVal}');
               if (~ismember(formatVersion, [{'3.1'} {'3.2'}]))
                  continue
               end
               
               idVal = find(strcmp('JULD', trajData(1:2:end)) == 1, 1);
               juld = trajData{2*idVal};
               idVal = find(strcmp('CYCLE_NUMBER', trajData(1:2:end)) == 1, 1);
               cycleNumber = trajData{2*idVal};
               idVal = find(strcmp('MEASUREMENT_CODE', trajData(1:2:end)) == 1, 1);
               measurementCode = trajData{2*idVal};
               
               idF = find((cycleNumber == 0) & (measurementCode == g_MC_Surface));
               if (~isempty(idF))
                  fprintf(fidOut, '%s; %s; %d; %s; %s; %.1f\n', ...
                     dacDirName, floatDirName, 0, ...
                     julian_2_gregorian_dec_argo(min(juld(idF))), ...
                     julian_2_gregorian_dec_argo(max(juld(idF))), ...
                     max(juld(idF))-min(juld(idF)));
               else
                  fprintf(fidOut, '%s; %s; %d; -; -; -\n', ...
                     dacDirName, floatDirName, 0);
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
