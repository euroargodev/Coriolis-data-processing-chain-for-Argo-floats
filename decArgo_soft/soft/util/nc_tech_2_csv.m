% ------------------------------------------------------------------------------
% Convert NetCDF technical file contents in CSV format.
%
% SYNTAX :
%   nc_tech_2_csv or nc_tech_2_csv(6900189, 7900118)
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
%   06/22/2014 - RNU - creation
% ------------------------------------------------------------------------------
function nc_tech_2_csv(varargin)

% top directory of the NetCDF files to convert
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
% DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\test_update_format_tech\coriolis\';

% default list of floats to convert
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_cm.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_arn_ir.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_4.54.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_032213.txt';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% default values initialization
init_default_values;

% to compare different set of files do not print current dates
COMPARISON_MODE = 0;


if (nargin == 0)
   floatListFileName = FLOAT_LIST_FILE_NAME;
   
   % floats to process come from floatListFileName
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', floatListFileName);
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

logFile = [DIR_LOG_FILE '/' 'nc_tech_2_csv' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
     
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);

   ncFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/'];

   if (exist(ncFileDir, 'dir') == 7)
      
      % convert tech file
      techFileName = sprintf('%d_tech.nc', floatNum);
      techFilePathName = [ncFileDir techFileName];
      
      if (exist(techFilePathName, 'file') == 2)
         
         outputFileName = [techFileName(1:end-3) '.csv'];
         outputFilePathName = [ncFileDir outputFileName];
         nc_tech_2_csv_file(techFilePathName, outputFilePathName, floatNum, COMPARISON_MODE);
      end
      
   else
      fprintf('WARNING: Directory not found: %s\n', ncFileDir);
   end
end
   
ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;

% ------------------------------------------------------------------------------
% Convert one NetCDF technical file contents in CSV format.
%
% SYNTAX :
%  nc_tech_2_csv_file(a_inputPathFileName, a_outputPathFileName, ...
%    a_floatNum, a_comparisonFlag)
%
% INPUT PARAMETERS :
%   a_inputPathFileName  : input NetCDF file path name
%   a_outputPathFileName : output CSV file path name
%   a_floatNum           : float WMO number
%   a_comparisonFlag     : if 1, do not print current dates
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/22/2014 - RNU - creation
% ------------------------------------------------------------------------------
function nc_tech_2_csv_file(a_inputPathFileName, a_outputPathFileName, ...
   a_floatNum, a_comparisonFlag)

% input and output file names
[inputPath, inputName, inputExt] = fileparts(a_inputPathFileName);
[outputPath, outputName, outputExt] = fileparts(a_outputPathFileName);
inputFileName = [inputName inputExt];
ourputFileName = [outputName outputExt];
fprintf('Converting: %s to %s\n', inputFileName, ourputFileName);

% retrieve information from tech file
wantedTechVars = [ ...
   {'PLATFORM_NUMBER'} ...
   {'DATA_TYPE'} ...
   {'FORMAT_VERSION'} ...
   {'HANDBOOK_VERSION'} ...
   {'DATA_CENTRE'} ...
   {'TECHNICAL_PARAMETER_NAME'} ...
   {'TECHNICAL_PARAMETER_VALUE'} ...
   {'CYCLE_NUMBER'} ...
   ];
if (a_comparisonFlag == 0)
   wantedTechVars = [ ...
      wantedTechVars ...
      {'DATE_CREATION'} ...
      {'DATE_UPDATE'} ...
      ];
end

% retrieve information from TECH netCDF file
[techData] = get_data_from_nc_file(a_inputPathFileName, wantedTechVars);

% create CSV file
fidOut = fopen(a_outputPathFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create output file: %s\n', a_outputPathFileName);
   return;
end

fprintf(fidOut, ' WMO; ------------------------------; DIMENSIONS; --------------------\n');

idVal = find(strcmp('CYCLE_NUMBER', techData) == 1);
if (~isempty(idVal))
   val = techData{idVal+1}';
   fprintf(fidOut, ' %d; N_TECH_PARAM; %d\n', a_floatNum, length(val));
else
   fprintf(fidOut, ' %d; N_TECH_PARAM\n', a_floatNum);
end

fprintf(fidOut, ' %d\n', a_floatNum);
fprintf(fidOut, ' WMO; ------------------------------; GENERAL INFORMATION; --------------------\n');

techVars = [ ...
   {'DATA_TYPE'} ...
   {'FORMAT_VERSION'} ...
   {'HANDBOOK_VERSION'} ...
   {'DATA_CENTRE'} ...
   {'DATE_CREATION'} ...
   {'DATE_UPDATE'} ...
   ];

for idL = 1:length(techVars)
   
   name = techVars{idL};
   val = '';
   idVal = find(strcmp(name, techData) == 1);
   if (~isempty(idVal))
      val = techData{idVal+1}';
   end
   fprintf(fidOut, ' %d; %s; %s\n', a_floatNum, name, strtrim(val));
end

fprintf(fidOut, ' %d\n', a_floatNum);
fprintf(fidOut, ' WMO; Cycle #; TECHNICAL DATA;\n');

techParamName = '';
idVal = find(strcmp('TECHNICAL_PARAMETER_NAME', techData) == 1);
if (~isempty(idVal))
   techParamName = techData{idVal+1}';
end

techParamValue = '';
idVal = find(strcmp('TECHNICAL_PARAMETER_VALUE', techData) == 1);
if (~isempty(idVal))
   techParamValue = techData{idVal+1}';
end

cycleNumber = '';
idVal = find(strcmp('CYCLE_NUMBER', techData) == 1);
if (~isempty(idVal))
   cycleNumber = techData{idVal+1};
end

for idCycle = min(cycleNumber):max(cycleNumber)
   
   idForCy = find(cycleNumber == idCycle);
   if (~isempty(idForCy))
      for  idT = 1:length(idForCy)
         fprintf(fidOut, ' %d; %d; %s; %s\n', a_floatNum, idCycle, strtrim(techParamName(idForCy(idT), :)), strtrim(techParamValue(idForCy(idT), :)));
      end
   else
      fprintf(fidOut, ' %d; %d; NONE\n', a_floatNum, idCycle);
   end
   
   fprintf(fidOut, ' %d; ------------------------------; --------------------------------------------------------------------------------; --------------------\n', a_floatNum);
end

fclose(fidOut);

return;
