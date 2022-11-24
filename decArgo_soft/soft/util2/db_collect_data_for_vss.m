% ------------------------------------------------------------------------------
% Process an export from the Coriolis data base and extract information used
% to create the VSS detailed description.
%
% SYNTAX :
%   db_collect_data_for_vss or db_collect_data_for_vss(6900189, 7900118)
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
function db_collect_data_for_vss(varargin)

% meta-data file exported from Coriolis data base
floatMetaFileName = 'C:\users\RNU\Argo\work\meta_tmp_20140317.txt';

fprintf('Extracting data for VSS from input file: %s\n', floatMetaFileName);

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\users\RNU\Argo\work\';

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
      return
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

logFile = [DIR_LOG_CSV_FILE '/' 'db_collect_data_for_vss' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'db_collect_data_for_vss' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = ['Line; WMO; Nb thresholds; ' ...
   'Threshol #1; Threshol #2; Thickness #1; Thickness #2; Thickness #3; Nb prof'];
fprintf(fidOut, '%s\n', header);

% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

% read meta file
if ~(exist(floatMetaFileName, 'file') == 2)
   fprintf('ERROR: Meta-data file not found: %s\n', floatMetaFileName);
   return
end

fId = fopen(floatMetaFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', floatMetaFileName);
   return
end
fileContents = textscan(fId, '%s', 'delimiter', '\t');
fileContents = fileContents{:};
fclose(fId);
fileContents = regexprep(fileContents, '"', '');

metaData = reshape(fileContents, 5, size(fileContents, 1)/5)';

% process the meta-data to fill the structure
% wmoList = str2num(cell2mat(metaData(:, 1))); % works only if all raws have the sme number of digits
% dimLevlist = str2num(cell2mat(metaData(:, 3))); % works only if all raws have the sme number of digits
wmoList = metaData(:, 1);
for id = 1:length(wmoList)
   if (isempty(str2num(wmoList{id})))
      fprintf('%s is not a valid WMO number\n', wmoList{id});
      return
   end
end
S = sprintf('%s*', wmoList{:});
wmoList = sscanf(S, '%f*');
techParamIdList = metaData(:, 2);
S = sprintf('%s*', techParamIdList{:});
techParamIdList = sscanf(S, '%f*');
floatList = unique(wmoList);

if ~(exist(floatListFileName, 'file') == 2)
   fprintf('File not found: %s\n', floatListFileName);
   return
end
refFloatList = load(floatListFileName);

floatList = sort(intersect(floatList, refFloatList));

notFoundFloat = setdiff(refFloatList, floatList);
if (~isempty(notFoundFloat))
   fprintf('Meta-data not found for float: %d\n', notFoundFloat);
end

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
      return
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
         continue
   end

   % meta-data of the current float
   idForWmo = find(wmoList == floatList(idFloat));
   if (nbThreshold == 1)
      threshold1 = [];
      idThreshold1 = find(techParamIdList(idForWmo) == 2148);
      if (length(idThreshold1) == 1)
         threshold1 = str2num(metaData{idForWmo(idThreshold1), 4});
      elseif (isempty(idThreshold1))
         fprintf('WARNING: Threshold#1 is missing for float %d\n', floatNum);
      else
         fprintf('WARNING: Multiple values for Threshold#1 of float %d\n', floatNum);
      end
      
      thickness1 = [];
      idThickness1 = find(techParamIdList(idForWmo) == 1358);
      if (length(idThickness1) == 1)
         thickness1 = str2num(metaData{idForWmo(idThickness1), 4});
      elseif (isempty(idThickness1))
         fprintf('WARNING: Thickness#1 is missing for float %d\n', floatNum);
      else
         fprintf('WARNING: Multiple values for Thickness#1 of float %d\n', floatNum);
      end
      
      thickness2 = [];
      idThickness2 = find(techParamIdList(idForWmo) == 1360);
      if (length(idThickness2) == 1)
         thickness2 = str2num(metaData{idForWmo(idThickness2), 4});
      elseif (isempty(idThickness2))
         fprintf('WARNING: Thickness#2 is missing for float %d\n', floatNum);
      else
         fprintf('WARNING: Multiple values for Thickness#2 of float %d\n', floatNum);
      end
      
      fprintf(fidOut, '%d; %d; %d; %d; -; %d; %d; -;\n', ...
         lineNum, floatNum, nbThreshold, ...
         threshold1, thickness1, thickness2);

   else
      
      threshold1 = [];
      idThreshold1 = find(techParamIdList(idForWmo) == 1356);
      if (length(idThreshold1) == 1)
         threshold1 = str2num(metaData{idForWmo(idThreshold1), 4});
      elseif (isempty(idThreshold1))
         fprintf('WARNING: Threshold#1 is missing for float %d\n', floatNum);
      else
         fprintf('WARNING: Multiple values for Threshold#1 of float %d\n', floatNum);
      end
      
      threshold2 = [];
      idThreshold2 = find(techParamIdList(idForWmo) == 1357);
      if (length(idThreshold2) == 1)
         threshold2 = str2num(metaData{idForWmo(idThreshold2), 4});
      elseif (isempty(idThreshold1))
         fprintf('WARNING: Threshold#2 is missing for float %d\n', floatNum);
      else
         fprintf('WARNING: Multiple values for Threshold#2 of float %d\n', floatNum);
      end

      thickness1 = [];
      idThickness1 = find(techParamIdList(idForWmo) == 1358);
      if (length(idThickness1) == 1)
         thickness1 = str2num(metaData{idForWmo(idThickness1), 4});
      elseif (isempty(idThickness1))
         fprintf('WARNING: Thickness#1 is missing for float %d\n', floatNum);
      else
         fprintf('WARNING: Multiple values for Thickness#1 of float %d\n', floatNum);
      end
      
      thickness2 = [];
      idThickness2 = find(techParamIdList(idForWmo) == 1359);
      if (length(idThickness2) == 1)
         thickness2 = str2num(metaData{idForWmo(idThickness2), 4});
      elseif (isempty(idThickness2))
         fprintf('WARNING: Thickness#2 is missing for float %d\n', floatNum);
      else
         fprintf('WARNING: Multiple values for Thickness#2 of float %d\n', floatNum);
      end
      
      thickness3 = [];
      idThickness3 = find(techParamIdList(idForWmo) == 1360);
      if (length(idThickness3) == 1)
         thickness3 = str2num(metaData{idForWmo(idThickness3), 4});
      elseif (isempty(idThickness3))
         fprintf('WARNING: Thickness#3 is missing for float %d\n', floatNum);
      else
         fprintf('WARNING: Multiple values for Thickness#3 of float %d\n', floatNum);
      end

      fprintf(fidOut, '%d; %d; %d; %d; %d; %d; %d; %d;\n', ...
         lineNum, floatNum, nbThreshold, ...
         threshold1, threshold2, ...
         thickness1, thickness2, thickness3);
      
   end
   
   lineNum = lineNum + 1;
end

fclose(fidOut);

fprintf('done\n');

diary off;

return
