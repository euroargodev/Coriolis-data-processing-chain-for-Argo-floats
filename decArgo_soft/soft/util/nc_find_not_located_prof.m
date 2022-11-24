% ------------------------------------------------------------------------------
% Retrieve the list of dated but not located profiles.
%
% SYNTAX :
%   nc_find_not_located_prof or 
%   nc_find_not_located_prof(6900189, 7900118)
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
%   04/27/2022 - RNU - creation
% ------------------------------------------------------------------------------
function nc_find_not_located_prof(varargin)

% list of floats to process (if empty, all encountered files will be checked)
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_tmp.txt';
FLOAT_LIST_FILE_NAME = '';

% top directory of NetCDF files to check
% (expected path to NetCDF files: DIR_INPUT_NC_FILES\dac_name\wmo_number)
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\test_compare_profile_param_qc\';
DIR_INPUT_NC_FILES = 'D:\202202-ArgoData\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the csv file
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
logFile = [DIR_LOG_FILE '/' 'nc_find_not_located_prof_' currentTime '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_CSV_FILE '/' 'nc_find_not_located_prof_' currentTime '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = 'WMO;File';
fprintf(fidOut, '%s\n', header);

dacDir = dir(DIR_INPUT_NC_FILES);
for idDir = 1:length(dacDir)

   dacDirName = dacDir(idDir).name;
   dacDirPathName = [DIR_INPUT_NC_FILES '/' dacDirName];
   if ((exist(dacDirPathName, 'dir') == 7) && ~strcmp(dacDirName, '.') && ~strcmp(dacDirName, '..'))

      fprintf('\nProcessing directory: %s\n', dacDirName);

      floatNum = 1;
      floatDir = dir(dacDirPathName);
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

                     floatFiles = [dir([floatDirPathName '/' sprintf('R*%d_*.nc', floatWmo)]); ...
                        dir([floatDirPathName '/' sprintf('D*%d_*.nc', floatWmo)])];
                     for idFile = 1:length(floatFiles)
                        process_nc_file(floatFiles(idFile).name, floatDirPathName, fidOut, floatWmo);
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

diary off;

return

% ------------------------------------------------------------------------------
% Process NetCDF profile files of a given cycle.
%
% SYNTAX :
%  process_nc_file(a_cFileName,, a_ncPathFileName, a_fidOut, a_floatWmo)
%
% INPUT PARAMETERS :
%   a_cFileName      : C-PROF file name
%   a_ncPathFileName : directory of the files to process
%   a_fidOut         : output csv file Id
%   a_floatWmo       : float WMO number
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/21/2022 - RNU - creation
% ------------------------------------------------------------------------------
function process_nc_file(a_cFileName, a_ncPathFileName, a_fidOut, a_floatWmo)

if (isempty(a_cFileName))
   return
end

cFilePathName = [a_ncPathFileName '/' a_cFileName];

if (exist(cFilePathName, 'file') == 2)

   % retrieve STATION_PARAMETERS
   wantedVars = [ ...
      {'JULD'} ...
      {'JULD_LOCATION'} ...
      {'POSITION_QC'} ...
      ];
   ncData = get_var_from_nc_file(cFilePathName, wantedVars);

   juld = get_data_from_name('JULD', ncData);
   juldLocation = get_data_from_name('JULD_LOCATION', ncData);
   positionQc = get_data_from_name('POSITION_QC', ncData);
   if (any((juld ~= 999999) & (juldLocation == 999999) & (positionQc == '9')))
      fprintf('File %s : dated but not located\n', a_cFileName);
      fprintf(a_fidOut, '%d;%s\n', a_floatWmo, a_cFileName);
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve Matlab variable (definition and contents) from a NetCDF file.
%
% SYNTAX :
%  [o_ncVarList] = get_var_from_nc_file(a_ncPathFileName, a_wantedVars)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : NetCDF file name
%   a_wantedVars     : name of the variables to retrieve
%
% OUTPUT PARAMETERS :
%   o_ncVarList : retrieved information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/11/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncVarList] = get_var_from_nc_file(a_ncPathFileName, a_wantedVars)

% output parameters initialization
o_ncVarList = [];


if (exist(a_ncPathFileName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return
   end
   
   % retrieve variables from NetCDF file
   for idVar = 1:length(a_wantedVars)
      varName = a_wantedVars{idVar};
      
      if (var_is_present_dec_argo(fCdf, varName))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
         varInfo = ncinfo(a_ncPathFileName, varName);
         o_ncVarList = [o_ncVarList {varName} {varValue}];
      else
         o_ncVarList = [o_ncVarList {varName} {[]}];
      end
      
   end
   
   netcdf.close(fCdf);
end

return

% ------------------------------------------------------------------------------
% Get data from name in a {name}/{data} list.
%
% SYNTAX :
%  [o_dataValues] = get_data_from_name(a_dataName, a_dataList)
%
% INPUT PARAMETERS :
%   a_dataName : name of the data to retrieve
%   a_dataList : {name}/{data} list
%
% OUTPUT PARAMETERS :
%   o_dataValues : concerned data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataValues] = get_data_from_name(a_dataName, a_dataList)

% output parameters initialization
o_dataValues = [];

idVal = find(strcmp(a_dataName, a_dataList) == 1, 1);
if (~isempty(idVal))
   o_dataValues = a_dataList{idVal+1};
end

return
