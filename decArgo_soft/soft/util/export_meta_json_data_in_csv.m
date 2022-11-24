% ------------------------------------------------------------------------------
% Read META.json file information and save it in a CSV file.
%
% SYNTAX :
%   export_meta_json_data_in_csv or export_meta_json_data_in_csv(6900189, 7900118)
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
%   09/28/2021 - RNU - creation
% ------------------------------------------------------------------------------
function export_meta_json_data_in_csv(varargin)

% directory of input META.json files
DIR_INPUT_META_JSON_FILES = 'C:\Users\jprannou\_DATA\IN\decArgo_config_floats\json_float_meta\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the csv file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';

% default list of floats to process
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_meta_json_list.txt';


% input parameters management
if (nargin == 0)
   % floats to process come from FLOAT_LIST_FILE_NAME
   floatListFileName = FLOAT_LIST_FILE_NAME;
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
   [~, name, ~] = fileparts(floatListFileName);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

currentTime = datestr(now, 'yyyymmddTHHMMSS');

logFile = [DIR_LOG_FILE '/' 'export_meta_json_data_in_csv' name '_' currentTime '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_CSV_FILE '/' 'export_meta_json_data_in_csv' name '_' currentTime '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = ['WMO'];
fprintf(fidOut, '%s\n', header);

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);
   
   % json meta-data file for this float
   jsonInputFileName = [DIR_INPUT_META_JSON_FILES '/' sprintf('%d_meta.json', floatNum)];
   
   if ~(exist(jsonInputFileName, 'file') == 2)
      fprintf('ERROR: Json meta-data file not found: %s\n', jsonInputFileName);
      continue
   end
   
   % read meta-data file
   metaData = loadjson(jsonInputFileName);
   
   % print structure contents in CSV file
   print_structure_in_csv(metaData, fidOut, floatNum, {''});

end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Recursively save structure contents in a CSV file.
%
% SYNTAX :
%  print_structure_in_csv(a_struct, a_fid, a_floatNum, a_fieldList)
%
% INPUT PARAMETERS :
%   a_struct    : input structure
%   a_fid       : CSV file Id
%   a_floatNum  : float WMO number
%   a_fieldList : list of already done fields
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/28/2021 - RNU - creation
% ------------------------------------------------------------------------------
function print_structure_in_csv(a_struct, a_fid, a_floatNum, a_fieldList)

if (isstruct(a_struct))
   fieldNames = fields(a_struct);
   for idF = 1:length(fieldNames)
      fileList = a_fieldList;
      fileList{end+1} = fieldNames{idF};
      print_structure_in_csv(a_struct.(fieldNames{idF}), a_fid, a_floatNum, fileList);
   end
elseif (iscell(a_struct))
   for idC = 1:length(a_struct)
      print_structure_in_csv(a_struct{idC}, a_fid, a_floatNum, a_fieldList);
   end
elseif (ischar(a_struct) || isempty(a_struct))
   fprintf(a_fid, '%d;', a_floatNum);
   fprintf(a_fid, '%s;', a_fieldList{2:end});
   fprintf(a_fid, '%s\n', a_struct);
elseif (isfloat(a_struct))
   if ((length(a_fieldList) > 1) && strcmp(a_fieldList{2}, 'CALIBRATION_COEFFICIENT'))
      fprintf(a_fid, '%d;', a_floatNum);
      fprintf(a_fid, '%s;', a_fieldList{2:end});
      fprintf(a_fid, '%.25f\n', a_struct);
   else
      fprintf(a_fid, '%d;', a_floatNum);
      fprintf(a_fid, '%s;', a_fieldList{2:end});
      fprintf(a_fid, '%f\n', a_struct);
   end
else
   fprintf('ERROR: Field type not managed yet\n');
end

return
