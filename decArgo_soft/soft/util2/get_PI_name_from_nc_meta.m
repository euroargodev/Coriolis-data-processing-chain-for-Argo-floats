% ------------------------------------------------------------------------------
% Collect PI names from nc meta and store them in a CSV file.
%
% SYNTAX :
%   get_PI_name_from_nc_meta ou get_PI_name_from_nc_meta(6900189,7900118)
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
%   03/10/2016 - RNU - creation
% ------------------------------------------------------------------------------
function get_PI_name_from_nc_meta(varargin)

% default values initialization
init_default_values;

% default list of floats to process
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';

% directory to store the log and csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% top directory of the NetCDF files to process
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\nc_file_apex_co_in_archive_201602\';
DIR_INPUT_NC_FILES = 'H:\archive_201608\coriolis\';

% flag to search for RT/DM profile information
FIND_PROF_TYPE_FLAG = 1;


if (nargin == 0)
   floatListFileName = FLOAT_LIST_FILE_NAME;
   
   % floats to process come from FLOAT_LIST_FILE_NAME
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

if (nargin == 0)
   [~, name, ~] = fileparts(floatListFileName);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

% create and start log file recording
logFile = [DIR_LOG_CSV_FILE '/get_PI_name_from_nc_meta' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/get_PI_name_from_nc_meta' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   fprintf('Erreur ouverture fichier: %s\n', outputFileName);
   return
end

header = ['Wmo; PI name; Profile type; Nb RT prof.; Nb DM prof.'];
fprintf(fidOut, '%s\n', header);

% traitement des flotteurs
floatNumPrev = -1;
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   %    if (floatNumPrev == floatNum)
   %       fprintf(fidOut, '%d;%s\n', floatNum, piName);
   %    else
   
   % FICHIER NETCDF DE META-DONNEES
   metaFileName = [DIR_INPUT_NC_FILES '/' floatNumStr '/' floatNumStr '_meta.nc'];
   
   wantedVars = [ ...
      {'PI_NAME'} ...
      ];
   [metaData] = get_data_from_nc_file(metaFileName, wantedVars);
   
   piName = 'UNKNOWN';
   idVal = find(strcmp('PI_NAME', metaData) == 1);
   if (~isempty(idVal))
      piName = strtrim(metaData{idVal+1}');
      if (isempty(piName))
         piName = 'UNKNOWN';
      end
   else
      piName = 'UNKNOWN';
   end
   
   nbRT = -1;
   nbDM = -1;
   if (FIND_PROF_TYPE_FLAG == 1)
      floatDirPathName = [DIR_INPUT_NC_FILES '/' floatNumStr '/profiles'];
      if (exist(floatDirPathName, 'dir') == 7)
         floatFiles = dir([floatDirPathName '/R*.nc']);
         nbRT = length(floatFiles);
         floatFiles = dir([floatDirPathName '/D*.nc']);
         nbDM = length(floatFiles);
      end
   end
   if ((nbRT == -1) && (nbDM == -1))
      profType = '-';
   elseif ((nbRT > 0) && (nbDM > 0))
      profType = 'RT&DM';
   elseif (nbRT > 0)
      profType = 'RT';
   elseif (nbDM > 0)
      profType = 'DM';
   end
   
   fprintf(fidOut, '%d;%s;%s;%d;%d\n', floatNum, piName, profType, nbRT, nbDM);
   %    end
   
   floatNumPrev = floatNum;
end

diary off;

fclose(fidOut);

return
