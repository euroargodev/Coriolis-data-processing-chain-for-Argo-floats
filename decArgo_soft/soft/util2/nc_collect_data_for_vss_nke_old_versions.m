% ------------------------------------------------------------------------------
% Retrieve, from NetCDF mono-profile files, information used to create the VSS
% detailed description.
%
% SYNTAX :
%   nc_collect_data_for_vss_nke_old_versions or nc_collect_data_for_vss_nke_old_versions(6900189, 7900118)
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
%   10/12/2015 - RNU - creation
% ------------------------------------------------------------------------------
function nc_collect_data_for_vss_nke_old_versions(varargin)

% top directory of input NetCDF mono-profile files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\IN\NC_CONVERTION_TO_3.1\NC_files_nke_old_versions_to_convert_to_3.1_fromArchive201510\';

% top directory of output NetCDF mono-profile files
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\NC_CONVERTION_TO_3.1\nke_old_versions_nc\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% default list of floats to process
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertNkeOldVersionsTo3.1\list\nke_old_all_argos.txt';

% interactively display the histograms
HISTO = 0;


% input parameters management
if (nargin == 0)
   % floats to process come from FLOAT_LIST_FILE_NAME
   floatListFileName = FLOAT_LIST_FILE_NAME;
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', floatListFileName);
      return
   end
   
   fprintf('Floats from list: %s\n', floatListFileName);
   floatList = textread(floatListFileName, '%d');
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

logFile = [DIR_LOG_CSV_FILE '/' 'nc_collect_data_for_vss_nke_old_versions' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_collect_data_for_vss_nke_old_versions' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = ['Line; WMO; DAC format Id; Nb thresholds; ' ...
   'Threshol #1; Threshol #2; Thickness #1; Thickness #2; Thickness #3; Nb prof'];
fprintf(fidOut, '%s\n', header);

% process the floats
lineNum = 1;
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);
   
   % retrieve information from NetCDF V3.1 meta-data file
   metaDataFilePathName = [DIR_OUTPUT_NC_FILES sprintf('/%d/%d_meta.nc', floatNum, floatNum)];
   wantedInputVars = [ ...
      {'DAC_FORMAT_ID'} ...
      ];
   metaData = get_data_from_nc_file(metaDataFilePathName, wantedInputVars);
   idVal = find(strcmp('DAC_FORMAT_ID', metaData(1:2:end)) == 1, 1);
   dacFormatId = strtrim(metaData{2*idVal}');
   switch (dacFormatId)
      case {'1', '2.2', '2.6', '2.7', '3.21', '3.5', '3.61', '3.8', '3.81', '4.0', '4.1', '4.11'}
         nbThreshold = 1;
      case {'4.6', '4.61', '5.0', '5.1', '5.2', '5.5'}
         nbThreshold = 2;
      otherwise
         fprintf('WARNING: Nothing done yet to deduce nbThreshold for dacFormatId %s\n', dacFormatId);
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
%                   break
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
         fprintf(fidOut, '%d; %d; %s; %d; %d; %d; %d; %d; %d; %d\n', ...
            lineNum, floatNum, dacFormatId, nbThreshold, ...
            threshold, sliceThickness, length(presProf));
      else
         fprintf(fidOut, '%d; %d; %s; %d; %d; -; %d; %d; -; %d\n', ...
            lineNum, floatNum, dacFormatId, nbThreshold, ...
            threshold, sliceThickness, length(presProf));
      end
      lineNum = lineNum + 1;
   end
end

fclose(fidOut);

fprintf('done\n');

diary off;

return

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
   return
end

% open NetCDF file
fCdf = netcdf.open(a_ncProfPathFileName, 'NC_NOWRITE');
if (isempty(fCdf))
   fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncProfPathFileName);
   return
end

% check the format version
% if (var_is_present_dec_argo(fCdf, 'FORMAT_VERSION'))
%    formatVersionStr = deblank(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'FORMAT_VERSION'))');
%    if ((str2num(formatVersionStr) ~= 3.0) && (str2num(formatVersionStr) ~= 3.1))
%       fprintf('ERROR: This program only manage Argo format 3.0 olr 3.1 version (the version of this file is %s)\n', formatVersionStr);
%       netcdf.close(fCdf);
%       return
%    end
% else
%    fprintf('ERROR: Cannot find ''FORMAT_VERSION'' variable in file: %s\n', a_ncProfPathFileName);
%    netcdf.close(fCdf);
%    return
% end

if (~var_is_present_dec_argo(fCdf, 'PRES'))
   fprintf('INFO: Cannot find ''PRES'' variable in file: %s\n', a_ncProfPathFileName);
   netcdf.close(fCdf);
   return
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

return
