% ------------------------------------------------------------------------------
% Retrieve NetCDF elements (dimensions, global attributes, variables and
% associated attributes) from NetCDF file and store them in CSV file.
%
% SYNTAX :
%   nc_get_info_from_netcdf_file or nc_get_info_from_netcdf_file(6900189, 7900118)
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
%   04/26/2019 - RNU - creation
% ------------------------------------------------------------------------------
function nc_get_info_from_netcdf_file(varargin)

% top directory of NetCDF files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\Conversion_en_3.1\IN\';

% default list of floats to process
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_old_bgc_all.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_1.5.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_17.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_36.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_29.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_27.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_34.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_41.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_9.txt';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% default values initialization
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

logFile = [DIR_LOG_CSV_FILE '/' 'nc_get_info_from_netcdf_file' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_get_info_from_netcdf_file'  name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = 'FILE;ITEM';
fprintf(fidOut, '%s\n', header);


% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);
      
   % process mono-profile files of the current float
   monoProfDirName = [DIR_INPUT_NC_FILES sprintf('/%d/profiles/', floatNum)];
   monoProfFileName = [monoProfDirName sprintf('*%d_*.nc', floatNum)];
   monoProfFiles = dir(monoProfFileName);

   for idFile = 1:length(monoProfFiles)
      
      fileName = monoProfFiles(idFile).name;
      profFileName = [monoProfDirName fileName];
      
      fprintf('File: %s\n', fileName);
      
      get_nc_info(profFileName, fileName, fidOut);
   end
end
   
fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Retrieve NetCDF elements (dimensions, global attributes, variables and
% associated attributes) from NetCDF file and store them in CSV file.
%
% SYNTAX :
%  get_nc_info(a_pathFileName, a_fileName, a_fidOut)
%
% INPUT PARAMETERS :
%   a_pathFileName : input NetCDF file path name
%   a_fileName     : input NetCDF file name
%   a_fidOut       : output CSV file Id
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/26/2019 - RNU - creation
% ------------------------------------------------------------------------------
function get_nc_info(a_pathFileName, a_fileName, a_fidOut)

fInfo = ncinfo(a_pathFileName);

globAtt = fInfo.Attributes;
for idAtt = 1:length(globAtt)
   att = globAtt(idAtt);
   
   fprintf(a_fidOut, '%s;GLOB_ATT;%s;=;%s\n', a_fileName, att.Name, att.Value);
end

dimensions = fInfo.Dimensions;
for idDim = 1:length(dimensions)
   if (dimensions(idDim).Unlimited == 1)
      fprintf(a_fidOut, '%s;DIM;%s;=;%d;(UNLIMITED)\n', a_fileName, dimensions(idDim).Name, dimensions(idDim).Length);
   else
      fprintf(a_fidOut, '%s;DIM;%s;=;%d\n', a_fileName, dimensions(idDim).Name, dimensions(idDim).Length);
   end
end

variables = fInfo.Variables;
for idVar = 1:length(variables)
   var = variables(idVar);
   varDimStr = fliplr({var.Dimensions.Name});
   varDimStr = sprintf('%s,', varDimStr{:});
   varDimStr(end) = [];
   fprintf(a_fidOut, '%s;VAR;%s;%s;%s(%s)\n', a_fileName, var.Datatype, var.Name, var.Name, varDimStr);
   varAtt = var.Attributes;
   for idAtt = 1:length(varAtt)
      att = varAtt(idAtt);
      fprintf(a_fidOut, '%s;VAR_ATT;%s;%s:%s;=;%s\n', a_fileName, var.Name, var.Name, att.Name, att.Value);
   end
end

return
