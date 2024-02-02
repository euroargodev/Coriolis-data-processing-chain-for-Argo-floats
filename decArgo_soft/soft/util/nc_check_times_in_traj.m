% ------------------------------------------------------------------------------
% Check consistency between first and last times of each cycle of a TRAJ file.
%
% SYNTAX :
%   nc_check_times_in_traj or
%   nc_check_times_in_traj(6900189, 7900118)
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
%   01/09/2023 - RNU - creation
% ------------------------------------------------------------------------------
function nc_check_times_in_traj(varargin)

% list of floats to process (if empty, all encountered files will be checked)
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\nke_argos.txt';
FLOAT_LIST_FILE_NAME = '';

% top directory of input NetCDF mono-profile files
DIR_INPUT_NC_FILES = 'E:\202211-ArgoData\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the XML file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';

% global measurement codes
global g_MC_Launch;
global g_MC_Surface;

% default values initialization
init_default_values;

% measurement codes initialization
init_measurement_codes;

logFile = [DIR_LOG_FILE '/' 'nc_check_times_in_traj_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

header = ['DAC;WMO;CYCLE_1 #;CYCLE_2 #;LAST_DATE_1;FIRST_DATE_2;DATE_DIFF (min)'];

% input parameters management
floatList = [];
if (nargin == 0)
   if (~isempty(FLOAT_LIST_FILE_NAME))
      floatListFileName = FLOAT_LIST_FILE_NAME;

      % floats to process come from floatListFileName
      if ~(exist(floatListFileName, 'file') == 2)
         fprintf('ERROR: File not found: %s\n', floatListFileName);
         return
      end

      fprintf('Floats from list: %s\n', floatListFileName);
      floatList = load(floatListFileName);
   end
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

paramJuld = get_netcdf_param_attributes('JULD');
dacDir = dir(DIR_INPUT_NC_FILES);
for idDir = 1:length(dacDir)
   
   dacDirName = dacDir(idDir).name;
   if (~strcmp(dacDirName, 'coriolis'))
      continue
   end
   
   dacDirPathName = [DIR_INPUT_NC_FILES '/' dacDirName];
   if ((exist(dacDirPathName, 'dir') == 7) && ~strcmp(dacDirName, '.') && ~strcmp(dacDirName, '..'))
      
      fprintf('\nProcessing directory: %s\n', dacDirName);
            
      % create the CSV output file
      outputFileName = [DIR_CSV_FILE '/' 'nc_check_times_in_traj_' dacDirName '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
      fidOut = fopen(outputFileName, 'wt');
      if (fidOut == -1)
         return
      end
      fprintf(fidOut, '%s\n', header);

      floatNum = 1;
      floatDir = dir(dacDirPathName);
      for idDir2 = 1:length(floatDir)
         
         floatDirName = floatDir(idDir2).name;
         floatDirPathName = [dacDirPathName '/' floatDirName];
         if ((exist(floatDirPathName, 'dir') == 7) && ~strcmp(floatDirName, '.') && ~strcmp(floatDirName, '..'))

            [floatWmo, status] = str2num(floatDirName);
            if (status == 1)
               if ((isempty(floatList)) || (~isempty(floatList) && ismember(floatWmo, floatList)))

                  % TRAJ file
                  floatTrajFilePathName = [dacDirPathName '/' floatDirName '/' floatDirName '_Rtraj.nc'];
                  if ~(exist(floatTrajFilePathName, 'file') == 2)
                     floatTrajFilePathName = [dacDirPathName '/' floatDirName '/' floatDirName '_Dtraj.nc'];
                  end

                  if (exist(floatTrajFilePathName, 'file') == 2)

                     % retrieve information from traj file
                     wantedInputVars = [ ...
                        {'FORMAT_VERSION'} ...
                        {'JULD'} ...
                        {'POSITION_ACCURACY'} ...
                        {'POSITION_QC'} ...
                        {'CYCLE_NUMBER'} ...
                        {'MEASUREMENT_CODE'} ...
                        ];
                     [trajData] = get_data_from_nc_file(floatTrajFilePathName, wantedInputVars);

                     idVal = find(strcmp('FORMAT_VERSION', trajData(1:2:end)) == 1, 1);
                     formatVersion = strtrim(trajData{2*idVal}');
                     if (~ismember(formatVersion, [{'3.1'} {'3.2'}]))
                        continue
                     end

                     fprintf('%03d/%03d %d\n', floatNum, length(floatDir)-2, floatWmo);

                     idVal = find(strcmp('JULD', trajData(1:2:end)) == 1, 1);
                     juld = trajData{2*idVal};
                     idVal = find(strcmp('POSITION_ACCURACY', trajData(1:2:end)) == 1, 1);
                     positionAccuracy = trajData{2*idVal};
                     idVal = find(strcmp('POSITION_QC', trajData(1:2:end)) == 1, 1);
                     positionQc = trajData{2*idVal};
                     idVal = find(strcmp('CYCLE_NUMBER', trajData(1:2:end)) == 1, 1);
                     cycleNumber = trajData{2*idVal};
                     idVal = find(strcmp('MEASUREMENT_CODE', trajData(1:2:end)) == 1, 1);
                     measurementCode = trajData{2*idVal};

                     cycleNum = unique(cycleNumber);
                     firstDate = nan(size(cycleNum));
                     positionQcFirst = nan(size(cycleNum));
                     lastDate = nan(size(cycleNum));
                     positionQcLast = nan(size(cycleNum));
                     for idC = 1:length(cycleNum)
                        idF = find((cycleNumber == cycleNum(idC)) & ...
                           ((measurementCode == g_MC_Launch) | (measurementCode == g_MC_Surface)) & ...
                           ((positionQc == ' ') | (positionQc == '1') | (positionQc == '2')) & ...
                           (positionAccuracy ~= 'I'));
                        if (any(juld(idF) ~= paramJuld.fillValue))
                           juldCy = juld(idF);
                           posQcCy = positionQc(idF);
                           juldCy(juldCy == paramJuld.fillValue) = [];
                           posQcCy(juldCy == paramJuld.fillValue) = [];
                           [~, idMin] = min(juldCy);
                           firstDate(idC) = juldCy(idMin);
                           positionQcFirst(idC) = posQcCy(idMin);
                           [~, idMax] = max(juldCy);
                           lastDate(idC) = juldCy(idMax);
                           positionQcLast(idC) = posQcCy(idMax);
                        end
                     end

                     for idC = 1:length(cycleNum)-1
                        if (lastDate(idC) > firstDate(idC+1))
                           fprintf('ERROR: Float: %d: Cycles %d - %d: %s - %s\n', ...
                              floatWmo, ...
                              cycleNum(idC), cycleNum(idC+1), ...
                              julian_2_gregorian_dec_argo(lastDate(idC)), ...
                              julian_2_gregorian_dec_argo(firstDate(idC+1)));

                           fprintf(fidOut, '%s;%d;%d;%d; %s; %s;%f\n', ...
                              dacDirName, floatWmo, ...
                              cycleNum(idC), cycleNum(idC+1), ...
                              julian_2_gregorian_dec_argo(lastDate(idC)), ...
                              julian_2_gregorian_dec_argo(firstDate(idC+1)), ...
                              (lastDate(idC) - firstDate(idC+1))*1440);
                        end
                     end
                     floatNum = floatNum + 1;
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
