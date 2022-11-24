% ------------------------------------------------------------------------------
% Compare PRES axis in C and B files.
%
% SYNTAX :
%   nc_compare_pres_axis or
%   nc_compare_pres_axis(6900189, 7900118)
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
%   09/14/2022 - RNU - creation
% ------------------------------------------------------------------------------
function nc_compare_pres_axis(varargin)

% list of floats to process (if empty, all encountered files will be checked)
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\__EDAC_INCOIS.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\__EDAC_BODC.txt';
FLOAT_LIST_FILE_NAME = '';

% top directory of NetCDF files to check
% (expected path to NetCDF files: DIR_INPUT_OUTPUT_NC_FILES\dac_name\wmo_number)
DIR_INPUT_OUTPUT_NC_FILES = 'D:\202209-ArgoData\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the XML file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';


% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

% input parameters management
floatList = [];
if (nargin == 0)
   if (~isempty(FLOAT_LIST_FILE_NAME))
      floatListFileName = FLOAT_LIST_FILE_NAME;

      % floats to process come from floatListFileName
      if ~(exist(floatListFileName, 'file') == 2)
         fprintf('ERROR: File not found: %s\n', floatListFileName);
         return
      end

      fprintf('Floats from list: %s\n', floatListFileName);
      floatList = load(floatListFileName);
   end
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'nc_compare_pres_axis_' currentTime '.log'];
diary(logFile);
tic;

% CSV file creation
csvFileName = [DIR_CSV_FILE '/' 'nc_compare_pres_axis_' currentTime '.csv'];
fidOut = fopen(csvFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create CSV output file: %s\n', csvFileName);
   return
end

% print file header
header = ['DAC;WMO;Error;C-file;B-file;N_PROF-C;N_PROF-B;N_PROF error;' ...
   'N_PROF;N_LEVELS-C;N_LEVELS-B;N_LEVELS error;PRES axis error' ...
   ];
fprintf(fidOut, '%s\n', header);

dacDir = dir(DIR_INPUT_OUTPUT_NC_FILES);
for idDir = 1:length(dacDir)

   dacDirName = dacDir(idDir).name;
   dacDirPathName = [DIR_INPUT_OUTPUT_NC_FILES '/' dacDirName];
   if ((exist(dacDirPathName, 'dir') == 7) && ~strcmp(dacDirName, '.') && ~strcmp(dacDirName, '..'))

      fprintf('\nProcessing directory: %s\n', dacDirName);

      floatNum = 1;
      floatDir = dir(dacDirPathName);
      %       for idDir2 = 1:1000
      for idDir2 = 1:length(floatDir)

         floatDirName = floatDir(idDir2).name;
         floatDirPathName = [dacDirPathName '/' floatDirName];
         if ((exist(floatDirPathName, 'dir') == 7) && ~strcmp(floatDirName, '.') && ~strcmp(floatDirName, '..'))

            [floatWmo, status] = str2num(floatDirName);
            if (status == 1)

               if ((isempty(floatList)) || (~isempty(floatList) && ismember(floatWmo, floatList)))

                  fprintf('%03d/%03d %d\n', floatNum, length(floatDir)-2, floatWmo);

                  floatDirPathName = [floatDirPathName '/profiles'];
                  if (exist(floatDirPathName, 'dir') == 7)
                     floatFiles = dir([floatDirPathName '/' sprintf('B*%d_*.nc', floatWmo)]);

                     % process B files
                     for idFile = 1:length(floatFiles)

                        floatFileName = floatFiles(idFile).name;
                        floatFilePathName = [floatDirPathName '/' floatFileName];
                        if (exist(floatFilePathName, 'file') == 2)
                           process_nc_file(floatFileName, floatDirPathName, fidOut, floatWmo, floatDirName);
                        end
                     end
                  end

                  floatNum = floatNum + 1;
               end
            end
         end
      end
   end
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

return

% ------------------------------------------------------------------------------
% Compare PRES axis of two C and B files.
%
% SYNTAX :
%  process_nc_file(a_ncBFileName, a_ncFileDir, a_fidOut, a_floatWmo, a_dacName)
%
% INPUT PARAMETERS :
%   a_ncBFileName : name of the B-file to process
%   a_ncFileDir   : directory of NetCDF files
%   a_fidOut      : output CSV file Id
%   a_floatWmo    : float WMO number
%   a_dacName     : name of the DAC
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/14/2022 - RNU - creation
% ------------------------------------------------------------------------------
function process_nc_file(a_ncBFileName, a_ncFileDir, a_fidOut, a_floatWmo, a_dacName)

ncBPathFileName = [a_ncFileDir '/' a_ncBFileName];
[filePath, bFileName, ext] = fileparts(ncBPathFileName);
cFileName = ['D' bFileName(3:end) ext]; % use D file first (R and D files can be (erroneously) present)
ncCPathFileName = [filePath '/' cFileName];
if ~(exist(ncCPathFileName, 'file') == 2)
   cFileName = ['R' bFileName(3:end) ext];
end
ncCPathFileName = [filePath '/' cFileName];

if (exist(ncCPathFileName, 'file') == 2) && (exist(ncBPathFileName, 'file') == 2)

   paramPres = get_netcdf_param_attributes('PRES');

   % retrieve data from files
   wantedInputVars = [ ...
      {'FORMAT_VERSION'} ...
      {'PRES'} ...
      ];
   [ncDataC] = get_data_from_nc_file(ncCPathFileName, wantedInputVars);
   [ncDataB] = get_data_from_nc_file(ncBPathFileName, wantedInputVars);

   if (~isempty(ncDataC) && ~isempty(ncDataB))

      idVal = find(strcmp('FORMAT_VERSION', ncDataC(1:2:end)) == 1, 1);
      formatVersionC = strtrim(ncDataC{2*idVal}');
      idVal = find(strcmp('FORMAT_VERSION', ncDataB(1:2:end)) == 1, 1);
      formatVersionB = strtrim(ncDataB{2*idVal}');

      if (strcmp(formatVersionC, '3.1') && strcmp(formatVersionB, '3.1'))
      
         idVal = find(strcmp('PRES', ncDataC(1:2:end)) == 1, 1);
         presDataC = ncDataC{2*idVal};
         n_profC = size(presDataC, 2);

         idVal = find(strcmp('PRES', ncDataB(1:2:end)) == 1, 1);
         presDataB = ncDataB{2*idVal};
         n_profB = size(presDataB, 2);

         if (n_profC == n_profB)
            for idProf = 1:n_profC
               presDataCProf = presDataC(:, idProf);
               presDataBProf = presDataB(:, idProf);
               presDataCProf(presDataCProf == paramPres.fillValue) = [];
               presDataBProf(presDataBProf == paramPres.fillValue) = [];

               if (length(presDataCProf) == length(presDataBProf))
                  if (any((presDataCProf - presDataBProf) ~= 0))
                     fprintf(a_fidOut, '%s;%d;%d;%s;%s;%d;%d;%d;%d;%d;%d;%d;%d\n', ...
                        a_dacName, a_floatWmo, 1, ...
                        cFileName, a_ncBFileName, ...
                        n_profC, n_profB, 0, ...
                        idProf, length(presDataCProf), length(presDataBProf), 0, 1);
                  end
               else
                  fprintf(a_fidOut, '%s;%d;%d;%s;%s;%d;%d;%d;%d;%d;%d;%d\n', ...
                     a_dacName, a_floatWmo, 1, ...
                     cFileName, a_ncBFileName, ...
                     n_profC, n_profB, 0, ...
                     idProf, length(presDataCProf), length(presDataBProf), 1);
               end
            end
         else
            fprintf(a_fidOut, '%s;%d;%d;%s;%s;%d;%d;%d\n', ...
               a_dacName, a_floatWmo, 1, ...
               cFileName, a_ncBFileName, ...
               n_profC, n_profB, 1);
         end
      end
   end
end

return
