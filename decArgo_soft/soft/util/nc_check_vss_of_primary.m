% ------------------------------------------------------------------------------
% Check that VSS of N_PROF = 1 profiles starts with 'Primary' and that no VSS
% which starts with 'Primary' is assigned to N_PROF > 1.
%
% SYNTAX :
%   nc_check_vss_of_primary
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/07/2017 - RNU - creation
% ------------------------------------------------------------------------------
function nc_check_vss_of_primary(varargin)

% top directory of input NetCDF mono-profile files (should contain one directory
% per DAC to be checked)
DIR_INPUT_NC_FILES = 'H:\archive_201709\';
% DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo_apmt_all_20171006\';
% DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\TEST\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% list of concerned floats
FLOAT_LIST_FILE_NAME = ''; % to check all floats encountered in the directories
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_apmt_all.txt';

% output all checked VSS (with a ok or ko flag)
OUTPUT_ALL_VSS_FLAG = 10;


% floats to process
floatList = [];
if (~isempty(FLOAT_LIST_FILE_NAME))
   if ~(exist(FLOAT_LIST_FILE_NAME, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', FLOAT_LIST_FILE_NAME);
      return;
   end
   fprintf('Floats from list: %s\n', FLOAT_LIST_FILE_NAME);
   floatList = load(FLOAT_LIST_FILE_NAME);
else
   fprintf('All floats\n');
end

currentTime = datestr(now, 'yyyymmddTHHMMSS');
logFile = [DIR_LOG_CSV_FILE '/' 'nc_check_vss_of_primary_' currentTime '.log'];
diary(logFile);
tic;

header = ['OK; DAC; WMO; CYCLE_NUMBER; N_PROF; FILE; VSS'];

dacDir = dir(DIR_INPUT_NC_FILES);
for idDir = 1:length(dacDir)
   
   dacDirName = dacDir(idDir).name;
   dacDirPathName = [DIR_INPUT_NC_FILES '/' dacDirName];
   if ((exist(dacDirPathName, 'dir') == 7) && ~strcmp(dacDirName, '.') && ~strcmp(dacDirName, '..'))
      
      fprintf('\nProcessing directory: %s\n', dacDirName);
      
      % create the CSV output file
      outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_check_vss_of_primary_' dacDirName '_' currentTime '.csv'];
      fidOut = fopen(outputFileName, 'wt');
      if (fidOut == -1)
         return;
      end
      fprintf(fidOut, '%s\n', header);

      floatDir = dir(dacDirPathName);
      for idDir2 = 1:length(floatDir)
         %          for idDir2 = 1:3
         
         floatDirName = floatDir(idDir2).name;
         floatDirPathName = [dacDirPathName '/' floatDirName];
         if (exist(floatDirPathName, 'dir') == 7)
            
            floatProfDirPathName = [dacDirPathName '/' floatDirName '/profiles/'];
            if (exist(floatProfDirPathName, 'dir') == 7)

               floatWmo = str2num(floatDirName);
               if (~isempty(floatList) && ~ismember(floatWmo, floatList))
                  continue;
               end
               
               fprintf('%s\n', floatDirName);
               
               profDir = dir(floatProfDirPathName);
               for idProf = 1:length(profDir)
                  
                  profFileName = profDir(idProf).name;
                  profFilePathName = [floatProfDirPathName '/' profFileName];
                  if (exist(profFilePathName, 'file') == 2)
                     
                     % retrieve information from profile file
                     wantedInputVars = [ ...
                        {'FORMAT_VERSION'} ...
                        {'CYCLE_NUMBER'} ...
                        {'VERTICAL_SAMPLING_SCHEME'} ...
                        ];
                     [profData] = get_data_from_nc_file(profFilePathName, wantedInputVars);
                     idVal = find(strcmp('FORMAT_VERSION', profData(1:2:end)) == 1, 1);
                     formatVersion = strtrim(profData{2*idVal}');
                     if (strcmp(formatVersion, '3.1'))
                        
                        idVal = find(strcmp('CYCLE_NUMBER', profData(1:2:end)) == 1, 1);
                        cycleNumber = profData{2*idVal};
                        nProfDim = length(cycleNumber);
                        idVal = find(strcmp('VERTICAL_SAMPLING_SCHEME', profData(1:2:end)) == 1, 1);
                        vss = profData{2*idVal};
                     
                        for idP = 1:nProfDim
                           if (~isempty(vss))
                              vssStr = vss(:, idP)';
                              vssStr = regexprep(vssStr, ';', '/');
                              ok = 1;
                              if ((idP == 1) && (~strncmp(vssStr, 'Primary ', length('Primary '))))
                                 ok = 0;
                              elseif ((idP > 1) && (strncmp(vssStr, 'Primary ', length('Primary '))))
                                 ok = 0;
                              end
                              if (OUTPUT_ALL_VSS_FLAG || ...
                                    (~OUTPUT_ALL_VSS_FLAG && ~ok))
                                 fprintf(fidOut, '%d; %s; %s; %d; %d; %s; %s\n', ...
                                    ok, strtrim(dacDirName), strtrim(floatDirName), ...
                                    cycleNumber(idP), idP, profFilePathName, strtrim(vssStr));
                              end
                           end
                        end
                     end
                  end
               end
            end
         end
      end
      fclose(fidOut);
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;

% ------------------------------------------------------------------------------
% Retrieve data from NetCDF file.
%
% SYNTAX :
%  [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : NetCDF file name
%   a_wantedVars     : NetCDF variables to retrieve from the file
%
% OUTPUT PARAMETERS :
%   o_ncData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)

% output parameters initialization
o_ncData = [];


if (exist(a_ncPathFileName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return;
   end
   
   % retrieve variables from NetCDF file
   for idVar = 1:length(a_wantedVars)
      varName = a_wantedVars{idVar};
      
      if (var_is_present_dec_argo(fCdf, varName))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
         o_ncData = [o_ncData {varName} {varValue}];
      else
         %          fprintf('WARNING: Variable %s not present in file : %s\n', ...
         %             varName, a_ncPathFileName);
         o_ncData = [o_ncData {varName} {''}];
      end
      
   end
   
   netcdf.close(fCdf);
end
