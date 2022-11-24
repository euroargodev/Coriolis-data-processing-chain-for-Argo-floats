% ------------------------------------------------------------------------------
% Retrieve the size of M-PROF files.
%
% SYNTAX :
%   get_m_prof_file_size or get_m_prof_file_size(6900189, 7900118)
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
%   08/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function get_m_prof_file_size(varargin)

% top directory of the first set of NetCDF files
DIR_INPUT_NC_FILES = 'H:\archive_201801\coriolis\';

% default list of floats to convert
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';
FLOAT_LIST_FILE_NAME = '';

% directory to store the log and the csv files
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% default values initialization
init_default_values;

floatList = [];
if (nargin == 0)
   floatListFileName = FLOAT_LIST_FILE_NAME;
   
   if (~isempty(floatListFileName))
      % floats to process come from floatListFileName
      if ~(exist(floatListFileName, 'file') == 2)
         fprintf('ERROR: File not found: %s\n', floatListFileName);
         return;
      end
      
      fprintf('Floats from list: %s\n', floatListFileName);
      floatList = load(floatListFileName);
   end
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

if (isempty(floatList))
   % process floats encountered in the DIR_INPUT_NC_FILES directory
   
   floatDirs = dir(DIR_INPUT_NC_FILES);
   for idDir = 1:length(floatDirs)
      
      floatDirName = floatDirs(idDir).name;
      floatDirPathName = [DIR_INPUT_NC_FILES '/' floatDirName];
      if ((exist(floatDirPathName, 'dir') == 7) && ~strcmp(floatDirName, '.') && ~strcmp(floatDirName, '..'))
         floatList = [floatList str2num(floatDirName)];
      end
   end
end

logFile = [DIR_LOG_FILE '/' 'get_m_prof_file_size' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_FILE '/' 'get_m_prof_file_size' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return;
end
header = ['File; Size'];
fprintf(fidOut, '%s\n', header);

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   for idDir = 1:2
      
      if (idDir == 1)
         ncFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/'];
      else
         ncFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/profiles/'];
      end
      
      if (exist(ncFileDir, 'dir') == 7)
         
         if (idDir == 1)
            ncFiles = dir([ncFileDir '*_Mprof.nc']);
         else
            ncFiles = dir([ncFileDir 'M*.nc']);
         end
         
         for idFile = 1:length(ncFiles)
            
            fprintf(fidOut, '%s; %f\n', ...
               ncFiles(idFile).name, ncFiles(idFile).bytes);
         end
      end
   end
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;
