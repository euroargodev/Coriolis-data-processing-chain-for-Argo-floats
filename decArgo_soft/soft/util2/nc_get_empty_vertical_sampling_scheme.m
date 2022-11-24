% ------------------------------------------------------------------------------
% Retrieve profiles for which the VERTICAL_SAMPLING_SCHEME is empty and it is
% not a default profile (empty profile created for the checker).
%
% SYNTAX :
%   nc_get_empty_vertical_sampling_scheme
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
%   01/03/2018 - RNU - creation
% ------------------------------------------------------------------------------
function nc_get_empty_vertical_sampling_scheme

% top directory of input NetCDF tech files
DIR_INPUT_NC_FILES = 'H:\archive_201709\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

logFile = [DIR_LOG_CSV_FILE '/' 'nc_get_empty_vertical_sampling_scheme_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;


% output CSV file header
header = ['DAC; WMO; PROJECT_NAME; PI_NAME; FILE'];

dacDir = dir(DIR_INPUT_NC_FILES);
for idDir = 1:length(dacDir)
   
   dacDirName = dacDir(idDir).name;
   
   %    if (~strcmp(dacDirName, 'coriolis') && ~strcmp(dacDirName, 'incois'))
   %       continue
   %    end
   
   dacDirPathName = [DIR_INPUT_NC_FILES '/' dacDirName];
   if ((exist(dacDirPathName, 'dir') == 7) && ~strcmp(dacDirName, '.') && ~strcmp(dacDirName, '..'))
      
      fprintf('\nProcessing directory: %s\n', dacDirName);
      
      % create the CSV output file
      outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_get_empty_vertical_sampling_scheme_' dacDirName '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
      fidOut = fopen(outputFileName, 'wt');
      if (fidOut == -1)
         return
      end
      fprintf(fidOut, '%s\n', header);
      
      floatDir = dir(dacDirPathName);
      for idDir2 = 1:length(floatDir)
         
         floatDirName = floatDir(idDir2).name;
                  
         floatDirPathName = [dacDirPathName '/' floatDirName];
         if (exist(floatDirPathName, 'dir') == 7)
            
            floatProfDirPathName = [dacDirPathName '/' floatDirName '/profiles/'];
            floatMetaFilePathName = [dacDirPathName '/' floatDirName '/' floatDirName '_meta.nc'];
            
            if ((exist(floatProfDirPathName, 'dir') == 7) && (exist(floatMetaFilePathName, 'file') == 2))
               
               fprintf('%03d/%03d %s\n', idDir2, length(floatDir), floatDirName);
               
               % retrieve information from meta-data file
               wantedInputVars = [ ...
                  {'FORMAT_VERSION'} ...
                  {'PROJECT_NAME'} ...
                  {'PI_NAME'} ...
                  ];
               [metaData] = get_data_from_nc_file(floatMetaFilePathName, wantedInputVars);
               idVal = find(strcmp('FORMAT_VERSION', metaData(1:2:end)) == 1, 1);
               formatVersion = metaData{2*idVal}';
               if (str2num(formatVersion) ~= 3.1)
                  continue
               end
               idVal = find(strcmp('PROJECT_NAME', metaData(1:2:end)) == 1, 1);
               projectName = strtrim(metaData{2*idVal});
               idVal = find(strcmp('PI_NAME', metaData(1:2:end)) == 1, 1);
               piName = strtrim(metaData{2*idVal});
               
               profDir = dir(floatProfDirPathName);
               for idProf = 1:length(profDir)
                  
                  profFileName = profDir(idProf).name;
                  if (any(strfind(profFileName, 'B')) || any(strfind(profFileName, 'M')))
                     continue
                  end
                  profFilePathName = [floatProfDirPathName '/' profFileName];
                  if (exist(profFilePathName, 'file') == 2)
                     
                     % retrieve information from profile file
                     wantedInputVars = [ ...
                        {'FORMAT_VERSION'} ...
                        {'VERTICAL_SAMPLING_SCHEME'} ...
                        {'PRES'} ...
                        ];
                     [profData] = get_data_from_nc_file(profFilePathName, wantedInputVars);
                     idVal = find(strcmp('FORMAT_VERSION', profData(1:2:end)) == 1, 1);
                     formatVersion = profData{2*idVal}';
                     if (str2num(formatVersion) ~= 3.1)
                        continue
                     end
                     idVal = find(strcmp('VERTICAL_SAMPLING_SCHEME', profData(1:2:end)) == 1, 1);
                     verticalSamplingScheme = profData{2*idVal}';
                     idVal = find(strcmp('PRES', profData(1:2:end)) == 1, 1);
                     pres = profData{2*idVal};
                     for idNProf = 1:size(verticalSamplingScheme, 1)
                        % check VERTICAL_SAMPLING_SCHEME of the current profile
                        if (isempty(strtrim(verticalSamplingScheme(idNProf, :))))
                           % be sure it is not a default profile (empty profile
                           % created for the checker)
                           if (any(pres(:, idNProf) ~= 99999))
                              fprintf(fidOut, '%s; %s; %s; %s; %s\n', ...
                                 dacDirName, floatDirName, projectName, piName, profFileName);
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

return

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
      return
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
