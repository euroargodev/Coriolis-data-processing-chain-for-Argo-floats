% ------------------------------------------------------------------------------
% Compare the file size of 2 sets of NetCDF files.
%
% SYNTAX :
%   nc_compare_m_prof_file_size or nc_compare_m_prof_file_size(6900189, 7900118)
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
function nc_compare_m_prof_file_size(varargin)

% top directory of the first set of NetCDF files
DIR_INPUT_NC_FILES1 = 'C:\Users\jprannou\_DATA\OUT\TEST_M-PROF_classic\';
DIR_INPUT_NC_FILES1 = 'H:\archive_201801\coriolis\';

% top directory of the second set of NetCDF files
DIR_INPUT_NC_FILES2 = 'C:\Users\jprannou\_DATA\OUT\TEST_M-PROF_netcdf4_classic\';
% DIR_INPUT_NC_FILES2 = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
% DIR_INPUT_NC_FILES2 = 'C:\Users\jprannou\_DATA\OUT\TEST_M-PROF_classic\';


% default list of floats to convert
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_ir_rudics_rem_dm.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';

% directory to store the log and the csv files
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

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

logFile = [DIR_LOG_FILE '/' 'nc_compare_m_prof_file_size' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_FILE '/' 'nc_compare_m_prof_file_size' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = ['File; Size1; Size2'];
fprintf(fidOut, '%s\n', header);

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   for idDir = 1:2
      
      if (idDir == 1)
         ncFileDir1 = [DIR_INPUT_NC_FILES1 '/' num2str(floatNum) '/'];
         ncFileDir2 = [DIR_INPUT_NC_FILES2 '/' num2str(floatNum) '/'];
      else
         ncFileDir1 = [DIR_INPUT_NC_FILES1 '/' num2str(floatNum) '/profiles/'];
         ncFileDir2 = [DIR_INPUT_NC_FILES2 '/' num2str(floatNum) '/profiles/'];
      end
      
      if ((exist(ncFileDir1, 'dir') == 7) && (exist(ncFileDir2, 'dir') == 7))
         
         if (idDir == 1)
            ncFiles1 = dir([ncFileDir1 '*_Mprof.nc']);
            ncFiles2 = dir([ncFileDir2 '*_Mprof.nc']);
         else
            ncFiles1 = dir([ncFileDir1 'M*.nc']);
            ncFiles2 = dir([ncFileDir2 'M*.nc']);
         end
         
         for idFile = 1:length(ncFiles1)
            
            idF = find(strcmp({ncFiles2.name}, ncFiles1(idFile).name));
            if (~isempty(idF))
               
               fprintf(fidOut, '%s; %f; %f\n', ...
                  ncFiles1(idFile).name, ncFiles1(idFile).bytes, ncFiles2(idF).bytes);
            end
         end
      end
   end
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
