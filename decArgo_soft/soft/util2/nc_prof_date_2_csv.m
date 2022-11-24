% ------------------------------------------------------------------------------
% Export JULD of mono-profile files to a CSV file.
%
% SYNTAX :
%   nc_prof_date_2_csv or nc_prof_date_2_csv(6900189, 7900118)
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
%   10/19/2015 - RNU - creation
% ------------------------------------------------------------------------------
function nc_prof_date_2_csv(varargin)

% top directory of the NetCDF files to convert
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\IN\NC_CONVERTION_TO_3.1\NC_files_nke_old_versions_to_convert_to_3.1_fromArchive201510\';

% default list of floats to convert
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertNkeOldVersionsTo3.1\list\nke_old_all_argos.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertNkeOldVersionsTo3.1\list\tmp.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertNkeOldVersionsTo3.1\list\nke_old_all_iridium.txt';

% directory to store the log and csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

global g_dateDef;

init_valdef;

init_default_values;


if (nargin == 0)
   floatListFileName = FLOAT_LIST_FILE_NAME;
   
   % floats to process come from floatListFileName
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', floatListFileName);
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

logFile = [DIR_LOG_CSV_FILE '/' 'nc_prof_date_2_csv' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_prof_date_2_csv' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = 'WMO; Cycle number; JULD; JULD_LOCATION; Cycle duration';
fprintf(fidOut, '%s\n', header);

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
     
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   ncFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/profiles/'];
   
   if (exist(ncFileDir, 'dir') == 7)
      
      tabCyNum = [];
      tabJuld = [];
      tabJuldLocation = [];
      ncFiles = dir([ncFileDir '*.nc']);
      for idFile = 1:length(ncFiles)
         
         ncFileName = ncFiles(idFile).name;
         ncFilePathName = [ncFileDir '/' ncFileName];
         
         wantedInputVars = [ ...
            {'DIRECTION'} ...
            {'CYCLE_NUMBER'} ...
            {'JULD'} ...
            {'JULD_LOCATION'} ...
            ];
         [inputData] = get_data_from_nc_file(ncFilePathName, wantedInputVars);
         
         idVal = find(strcmp('DIRECTION', inputData(1:2:end)) == 1, 1);
         direction = strtrim(inputData{2*idVal}');
         if (unique(direction) == 'A')
            
            idVal = find(strcmp('CYCLE_NUMBER', inputData(1:2:end)) == 1, 1);
            cyNum = unique(inputData{2*idVal}');
            idVal = find(strcmp('JULD', inputData(1:2:end)) == 1, 1);
            juld = unique(inputData{2*idVal}');
            idOk = find(juld ~= 999999);
            if (~isempty(idOk))
               juld = juld(idOk(1));
            else
               juld = g_dateDef;
            end
            idVal = find(strcmp('JULD_LOCATION', inputData(1:2:end)) == 1, 1);
            juldLoc = unique(inputData{2*idVal}');
            idOk = find(juldLoc ~= 999999);
            if (~isempty(idOk))
               juldLoc = juldLoc(idOk(1));
            else
               juldLoc = g_dateDef;
            end
            
            tabCyNum(end+1) = cyNum;
            tabJuld(end+1) = juld;
            tabJuldLocation(end+1) = juldLoc;
         elseif (unique(direction) == 'D')
         else
            fprintf('WARNING: inconsistent DIRECTION information\n');
         end
      end
      
      [tabCyNum, idSort] = sort(tabCyNum);
      tabJuld = tabJuld(idSort);
      tabJuldLocation = tabJuldLocation(idSort);
      for id = 1:length(tabCyNum)
         cyDur = [];
         if (id > 1)
            date1 = g_dateDef;
            if (tabJuld(id-1) ~= g_dateDef)
               date1 = tabJuld(id-1);
            elseif (tabJuldLocation(id-1) ~= g_dateDef)
               date1 = tabJuldLocation(id-1);
            end
            date2 = g_dateDef;
            if (tabJuld(id) ~= g_dateDef)
               date2 = tabJuld(id);
            elseif (tabJuldLocation(id) ~= g_dateDef)
               date2 = tabJuldLocation(id);
            end
            if ((date1 ~= g_dateDef) && (date2 ~= g_dateDef))
               cyDur = num2str(round(date2-date1));
            end
         end
         fprintf(fidOut, '%d; %d; %s; %s; %s\n', ...
            floatNum, tabCyNum(id), ...
            julian_2_gregorian_dec_argo(tabJuld(id)), ...
            julian_2_gregorian_dec_argo(tabJuldLocation(id)), ...
            cyDur);
      end
      
   else
      fprintf('WARNING: Directory not found: %s\n', ncFileDir);
   end
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
