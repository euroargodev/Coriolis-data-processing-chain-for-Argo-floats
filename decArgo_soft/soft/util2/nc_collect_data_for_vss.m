% ------------------------------------------------------------------------------
% Retrieve, from NetCDF mono-profile files, information used to create the VSS
% detailed description.
%
% SYNTAX :
%   nc_collect_data_for_vss or nc_collect_data_for_vss(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : WMO number of floats to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/18/2014 - RNU - creation
% ------------------------------------------------------------------------------
function nc_collect_data_for_vss(varargin)

DIR_INPUT_NC_FILES = 'C:\users\RNU\Argo\work\nc_output_decPrv\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\users\RNU\Argo\work\';

% interactively display the histograms
HISTO = 0;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values initialization
init_default_values;


% configuration parameters
configVar = [];
configVar{end+1} = 'FLOAT_LIST_FILE_NAME';
configVar{end+1} = 'FLOAT_INFORMATION_FILE_NAME';

% get configuration parameters
g_decArgo_realtimeFlag = 0;
g_decArgo_delayedModeFlag = 0;
[configVal, unusedVarargin, inputError] = get_config_dec_argo(configVar, []);
floatListFileName = configVal{1};
floatInformationFileName = configVal{2};

if (nargin == 0)
   % floats to process come from floatListFileName
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('File not found: %s\n', floatListFileName);
      return;
   end
   
   fprintf('Floats from list: %s\n', floatListFileName);
   floatList = load(floatListFileName);
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create and start log file recording
if (nargin == 0)
   [pathstr, name, ext] = fileparts(floatListFileName);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

logFile = [DIR_LOG_CSV_FILE '/' 'nc_collect_data_for_vss' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_collect_data_for_vss' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return;
end
header = ['Line; WMO; Nb thresholds; ' ...
   'Threshol #1; Threshol #2; Thickness #1; Thickness #2; Thickness #3; Nb prof'];
fprintf(fidOut, '%s\n', header);

% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

% process the floats
lineNum = 1;
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);
   
   % find current float Dec Id
   idF = find(listWmoNum == floatNum, 1);
   if (isempty(idF))
      fprintf('ERROR: No information on float #%d => exit\n', floatNum);
      return;
   end
   floatDecId = listDecId(idF);
   
   % the number of thresholds depends on float version
   switch (floatDecId)
      case {1, 11, 12, 4, 19, 3}
         nbThreshold = 1;
      case {24, 17, 25, 27, 28, 29}
         nbThreshold = 2;
      otherwise
         fprintf('WARNING: Nothing done yet for decoderId #%d\n', floatDecId);
         continue;
   end
   
   % directory of files for this float
   dirFloat = [DIR_INPUT_NC_FILES '/' sprintf('%d', floatNum) '/profiles/'];
   
   % nc files to process
   diffProfAll = [];
   presProf = [];
   sliceThickness = [];
   threshold = [];
   files = dir([dirFloat '*.nc']);
   for idFile = 1:length(files)
      
      fileName = files(idFile).name;
      filePathName = [dirFloat '/' fileName];
      
      [presMeas] = get_pres_in_mono_prof(filePathName);
      
      presProf{end+1} = presMeas;
      diffProfAll = [diffProfAll; diff(presMeas)];
   end
   
   if (~isempty(diffProfAll))
      [nbElement, valCenter] = hist(diffProfAll, [min(diffProfAll):max(diffProfAll)]);
      for id = 1:nbThreshold+1
         [~, idMax] = max(nbElement);
         sliceThickness = [sliceThickness; valCenter(idMax)];
         idF = find((valCenter == (valCenter(idMax)-1)) | ...
            (valCenter == valCenter(idMax)) | ...
            (valCenter == (valCenter(idMax)+1)));
         nbElement(idF) = [];
         valCenter(idF) = [];
      end
      sliceThickness = sort(sliceThickness);
      fprintf('Thick : %d\n', sliceThickness);
      
      if (HISTO == 1)
         hist(diffProfAll, [min(diffProfAll):max(diffProfAll)]);
         pause;
      end
      
      for id = 1:nbThreshold
         thresholdALL = [];
         for idProf = 1:length(presProf)
            pres = presProf{idProf};
            diffPres = diff(pres);
            if (nbThreshold == 2)
               if (id == 1)
                  idF = find(abs(diffPres-sliceThickness(id)) < abs(diffPres-sliceThickness(id+1)));
                  if (~isempty(idF))
                     thresholdALL = [thresholdALL; pres(idF(end))];
                  end
               else
                  idF = find(abs(diffPres-sliceThickness(id)) > abs(diffPres-sliceThickness(id+1)));
                  if (~isempty(idF))
                     thresholdALL = [thresholdALL; pres(idF(1))];
                  end
               end
            else
               idF = find(abs(diffPres-sliceThickness(id)) > abs(diffPres-sliceThickness(id+1)));
               if (~isempty(idF))
                  thresholdALL = [thresholdALL; pres(idF(1))];
               end
            end
         end
         fact = 10;
         if (sliceThickness(id) > 10)
            fact = 100;
         end
         minVal = floor(min(thresholdALL)/fact)*fact;
         maxVal = ceil(max(thresholdALL)/fact)*fact;
         if (minVal == maxVal)
            threshold = [threshold; minVal];
         else
            [nbElement, valCenter] = hist(thresholdALL, [minVal:fact:maxVal]);
            [~, idMax] = max(nbElement);
            valMax = valCenter(idMax);
%             while (valMax > 1800)
%                nbElement(idMax) = [];
%                valCenter(idMax) = [];
%                if (isempty(nbElement))
%                   break;
%                end
%                [~, idMax] = max(nbElement);
%                valMax = valCenter(idMax);
%             end
            threshold = [threshold; valMax];
            
            if (HISTO == 1)
               hist(thresholdALL, [minVal:fact:maxVal]);
               pause;
            end
         end
      end
      fprintf('Thresh : %d\n', threshold);
      
      if (nbThreshold == 2)
         fprintf(fidOut, '%d; %d; %d; %d; %d; %d; %d; %d; %d\n', ...
            lineNum, floatNum, nbThreshold, ...
            threshold, sliceThickness, length(presProf));
      else
         fprintf(fidOut, '%d; %d; %d; %d; -; %d; %d; -; %d\n', ...
            lineNum, floatNum, nbThreshold, ...
            threshold, sliceThickness, length(presProf));
      end
      lineNum = lineNum + 1;
   end
end

fclose(fidOut);

fprintf('done\n');

diary off;

return;

% ------------------------------------------------------------------------------
% Retrieve pressure measurements from a NetCDF mono-profile file.
%
% SYNTAX :
%  [o_presMeas] = get_pres_in_mono_prof(a_ncProfPathFileName)
%
% INPUT PARAMETERS :
%   a_ncProfPathFileName : NetCDF mono-profile file path name
%
% OUTPUT PARAMETERS :
%   o_presMeas : pressure measurements
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/18/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_presMeas] = get_pres_in_mono_prof(a_ncProfPathFileName)

% output parameters initialization
o_presMeas = [];


% check if the file exists
if ~(exist(a_ncProfPathFileName, 'file') == 2)
   fprintf('WARNING: File not found : %s\n', a_ncProfPathFileName);
   return;
end

% open NetCDF file
fCdf = netcdf.open(a_ncProfPathFileName, 'NC_NOWRITE');
if (isempty(fCdf))
   fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncProfPathFileName);
   return;
end

% check the format version
if (var_is_present_dec_argo(fCdf, 'FORMAT_VERSION'))
   formatVersionStr = deblank(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'FORMAT_VERSION'))');
   if ((str2num(formatVersionStr) ~= 3.0) && (str2num(formatVersionStr) ~= 3.1))
      fprintf('ERROR: This program only manage Argo format 3.0 olr 3.1 version (the version of this file is %s)\n', formatVersionStr);
      netcdf.close(fCdf);
      return;
   end
else
   fprintf('ERROR: Cannot find ''FORMAT_VERSION'' variable in file: %s\n', a_ncProfPathFileName);
   netcdf.close(fCdf);
   return;
end

if (~var_is_present_dec_argo(fCdf, 'PRES'))
   fprintf('INFO: Cannot find ''PRES'' variable in file: %s\n', a_ncProfPathFileName);
   netcdf.close(fCdf);
   return;
end

% collect the station parameter list
stationParameters = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'STATION_PARAMETERS'));
[~, nParam, nProf] = size(stationParameters);
paramForProf = [];
for idProf = 1:nProf
   params = deblank(stationParameters(:, 1, idProf)');
   for idParam = 2:nParam
      params = [params '@' deblank(stationParameters(:, idParam, idProf)')];
   end
   paramForProf{end+1} = params;
end

% collect the pressure measurements
pres = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PRES'));
presFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'PRES'), '_FillValue');
for idProf = 1:nProf
   if (idProf == 1)
      % pimary profile
      o_presMeas = [pres(:, idProf)];
   else
      % the unpumped part of the primary profile has the same parameters
      if (strcmp(paramForProf{idProf}, paramForProf{1}))
         o_presMeas = [pres(:, idProf); o_presMeas];
      end
   end
end

netcdf.close(fCdf);

o_presMeas(find(o_presMeas == presFillVal)) = [];

return;
