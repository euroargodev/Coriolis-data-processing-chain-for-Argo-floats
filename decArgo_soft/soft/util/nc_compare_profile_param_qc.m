% ------------------------------------------------------------------------------
% For each cycle compare PROFILE_<PARAM>_QC values of S profile files
% to B profile file ones.
% Tool implemented to select S-PROF files that should be processed anew with
% '048a' version of the decoder.
%
% SYNTAX :
%   nc_compare_profile_param_qc or 
%   nc_compare_profile_param_qc(6900189, 7900118)
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
%   04/21/2022 - RNU - creation
% ------------------------------------------------------------------------------
function nc_compare_profile_param_qc(varargin)

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
logFile = [DIR_LOG_FILE '/' 'nc_compare_profile_param_qc_' currentTime '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_CSV_FILE '/' 'nc_compare_profile_param_qc_' currentTime '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = 'WMO;S file name;PROFILE_<PARAM>_QC;S-PROF value;B-PROF value';
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

                     if (isempty(dir([floatDirPathName '/' sprintf('S*%d_*.nc', floatWmo)])))
                        continue
                     end

                     % gather files to process
                     floatFiles = dir([floatDirPathName '/' sprintf('S*%d_*.nc', floatWmo)]);
                     fileList = cell(length(floatFiles), 5);
                     nbL = 0;
                     for idFile = 1:length(floatFiles)

                        floatFileName = floatFiles(idFile).name;
                        idFUs = strfind(floatFileName, '_');
                        cyNum = str2double(floatFileName(idFUs+1:idFUs+3));
                        if (floatFileName(idFUs+4) == 'D')
                           direction = 1;
                        else
                           direction = 2;
                        end
                        fileList{nbL+1, 1} = cyNum;
                        fileList{nbL+1, 2} = direction;
                        fileList{nbL+1, 3} = floatFileName;
                        nbL = nbL + 1;
                     end
                     fileList(nbL+1:end, :) = [];

                     floatFiles = dir([floatDirPathName '/' sprintf('B*%d_*.nc', floatWmo)]);
                     for idFile = 1:length(floatFiles)

                        floatFileName = floatFiles(idFile).name;
                        idFUs = strfind(floatFileName, '_');
                        cyNum = str2double(floatFileName(idFUs+1:idFUs+3));
                        if (floatFileName(idFUs+4) == 'D')
                           direction = 1;
                        else
                           direction = 2;
                        end
                        idF = find(([fileList{:, 1}] == cyNum) & ([fileList{:, 2}] == direction));
                        if (~isempty(idF))
                           fileList{idF, 4} = floatFileName;
                        end
                     end

                     floatFiles = [dir([floatDirPathName '/' sprintf('R*%d_*.nc', floatWmo)]); ...
                        dir([floatDirPathName '/' sprintf('D*%d_*.nc', floatWmo)])];
                     for idFile = 1:length(floatFiles)

                        floatFileName = floatFiles(idFile).name;
                        idFUs = strfind(floatFileName, '_');
                        cyNum = str2double(floatFileName(idFUs+1:idFUs+3));
                        if (floatFileName(idFUs+4) == 'D')
                           direction = 1;
                        else
                           direction = 2;
                        end
                        idF = find(([fileList{:, 1}] == cyNum) & ([fileList{:, 2}] == direction));
                        if (~isempty(idF))
                           fileList{idF, 5} = floatFileName;
                        end
                     end

                     % process files by pairs
                     for idF = 1:size(fileList, 1)
                        process_nc_file(fileList{idF, 3}, fileList{idF, 4}, fileList{idF, 5}, floatDirPathName, fidOut, floatWmo);
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
% Process NetCDF S and B files of a given cycle.
%
% SYNTAX :
%  process_nc_file(a_sFileName, a_bFileName, a_cFileName, a_ncPathFileName, a_fidOut, a_floatWmo)
%
% INPUT PARAMETERS :
%   a_sFileName      : S-PROF file name
%   a_bFileName      : B-PROF file name
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
function process_nc_file(a_sFileName, a_bFileName, a_cFileName, a_ncPathFileName, a_fidOut, a_floatWmo)


if (isempty(a_sFileName))
   return
end

sFilePathName = [a_ncPathFileName '/' a_sFileName];
cFilePathName = [a_ncPathFileName '/' a_cFileName];
bFilePathName = [a_ncPathFileName '/' a_bFileName];

sProfQc = get_profile_qc(sFilePathName);
% cProfQc = get_profile_qc(cFilePathName);
bProfQc = get_profile_qc(bFilePathName);

idPres = -1;
for idP = 1:size(bProfQc, 1)
   if (strcmp(bProfQc{idP, 1} , 'PROFILE_PRES_QC'))
      idPres = idP;
      continue
   end
   bProfQc{idP, 2} = strtrim(bProfQc{idP, 2}');
   if (isempty(bProfQc{idP, 2}))
      bProfQc{idP, 2} = ' ';
   end
end
bProfQc(idPres, :) = [];

for idP = 1:size(sProfQc, 1)
   sProfParam = sProfQc{idP, 1};
   if (ismember(sProfParam, [{'PROFILE_PRES_QC'} {'PROFILE_TEMP_QC'} {'PROFILE_PSAL_QC'}]))
      continue
   end
   sProfParamQc = sProfQc{idP, 2};
   idF = find(strcmp(bProfQc(:, 1), sProfParam));
   if (isempty(idF))
      fprintf('ERROR: Cannot find %s in %s\n', sProfParam, a_bFileName);
      continue
   end
   if (sProfParamQc ~= bProfQc{idF, 2})
      fprintf('WARNING: File %s : %s = ''%s'' - ''%s''\n', a_sFileName, sProfParam, sProfParamQc, bProfQc{idF, 2});

      fprintf(a_fidOut, '%d;%s;%s;%s;%s\n', a_floatWmo, a_sFileName, sProfParam, sProfParamQc, bProfQc{idF, 2});
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve PROFILE_<PARAM>_QC from a NetCDF file.
%
% SYNTAX :
%  [o_profQc] = get_profile_qc(a_ncFilePathName)
%
% INPUT PARAMETERS :
%   a_ncFilePathName : NetCDF file path name
%
% OUTPUT PARAMETERS :
%   o_profQc : PROFILE_<PARAM>_QC values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/21/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profQc] = get_profile_qc(a_ncFilePathName)

% output parameters initialization
o_profQc = [];


if (exist(a_ncFilePathName, 'file') == 2)

   % retrieve STATION_PARAMETERS
   wantedVars = [ ...
      {'STATION_PARAMETERS'} ...
      ];
   ncData = get_var_from_nc_file(a_ncFilePathName, wantedVars);

   paramList = [];
   stationParameters = get_data_from_name('STATION_PARAMETERS', ncData);
   [~, nParam, nProf] = size(stationParameters);
   for idProf = 1:nProf
      for idParam = 1:nParam
         paramName = strtrim(stationParameters(:, idParam, idProf)');
         if (~isempty(paramName))
            paramList{end+1} = paramName;
         end
      end
      paramList = unique(paramList);
   end

   % retrieve PROFILE_<PARAM>_QC
   wantedVars = [];
   for idP = 1:length(paramList)
      wantedVars = [ wantedVars ...
         {['PROFILE_' paramList{idP} '_QC']} ...
         ];
   end
   ncData = get_var_from_nc_file(a_ncFilePathName, wantedVars);

   o_profQc = cell(length(paramList), 2);
   o_profQc(:, 1) = ncData(1:2:end)';
   o_profQc(:, 2) = ncData(2:2:end)';
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
