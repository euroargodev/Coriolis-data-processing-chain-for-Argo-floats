% ------------------------------------------------------------------------------
% After conversion of Apex profile files, add additionnal NetCDF files
% generated from ANDRO DEP files.
%
% SYNTAX :
%   add_dep_profiles_to_generated_data_set or add_dep_profiles_to_generated_data_set(6900189, 7900118)
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
%   05/24/2019 - RNU - creation
% ------------------------------------------------------------------------------
function add_dep_profiles_to_generated_data_set(varargin)

% top directory of generated NetCDF files
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\Conversion_en_3.1\OUT\';

% top directory of DEP NetCDF files
DIR_DEP_NC_FILES = 'C:\Users\jprannou\_DATA\Conversion_en_3.1\OUT_from_DEP\';

% default list of floats to process
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_all.txt';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% default values initialization
init_default_values;

% only to check or to do the job
DO_IT = 1;


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

logFile = [DIR_LOG_FILE '/' 'add_dep_profiles_to_generated_data_set' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% process the floats
nbFloats = length(floatList);
counter = 0;
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);
   
   % DEP profile files
   depProfDirName = [DIR_DEP_NC_FILES sprintf('/%d/profiles/', floatNum)];
   if (exist(depProfDirName, 'dir') == 7)
      
      % create the list of existing cycles
      convProfDirName = [DIR_OUTPUT_NC_FILES sprintf('/%d/profiles/', floatNum)];
      convProfFileName = [convProfDirName sprintf('*%d_*.nc', floatNum)];
      convProfFiles = dir(convProfFileName);
      cyNumList = [];
      for idFile = 1:length(convProfFiles)
         
         fileName = convProfFiles(idFile).name;
         if (fileName(1) == 'B')
            continue
         end
         idF = strfind(fileName, '_');
         cyNumList = [cyNumList str2num(fileName(idF+1:idF+3))];
      end
      
      % copy additionnal DEP NetCDF files
      depProfFileName = [depProfDirName sprintf('*%d_*.nc', floatNum)];
      depProfFiles = dir(depProfFileName);
      for idFile = 1:length(depProfFiles)
         
         fileName = depProfFiles(idFile).name;
         idF = strfind(fileName, '_');
         cyNum = str2num(fileName(idF+1:idF+3));
         if (~ismember(cyNum, cyNumList))
            if (DO_IT == 0)
               fprintf('DEP NetCDF file that could be added: %s\n', fileName);
            else
               
               [status] = copyfile([depProfDirName fileName], [convProfDirName fileName]);
               if (status == 1)
                  fprintf('Added DEP NetCDF file: %s\n', fileName);
               else
                  fprintf('ERROR: cannot copy file ''%s'' to directory ''%%s''\n', ...
                     [depProfDirName fileName], convProfDirName);
               end
            end
            counter = counter + 1;
         end
      end
   end
end

fprintf('Number of added files: %d\n', counter);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
