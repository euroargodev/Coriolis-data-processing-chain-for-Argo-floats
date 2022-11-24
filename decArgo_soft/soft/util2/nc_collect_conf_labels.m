% ------------------------------------------------------------------------------
% Collect a list of configuration labels in meta.nc files.
%
% SYNTAX :
%   nc_collect_conf_labels
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
%   02/23/2017 - RNU - creation
% ------------------------------------------------------------------------------
function nc_collect_conf_labels(varargin)

% top directory of input NetCDF meta files
DIR_INPUT_NC_FILES = 'H:\archive_201701\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

logFile = [DIR_LOG_CSV_FILE '/' 'nc_collect_conf_labels_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

g_couf_searchedLabelList = [ ...
   {'CONFIG_AscentTime'} ...
   ];

% output CSV file header
header = ['File; PLATFORM_NUMBER; FORMAT_VERSION; DATA_CENTRE; PLATFORM_TYPE; CONFIG_PARAMETER_NAME'];

dacDir = dir(DIR_INPUT_NC_FILES);
for idDir = 1:length(dacDir)
   
   dacDirName = dacDir(idDir).name;
   %    if (~strcmp(dacDirName, 'jma') && ~strcmp(dacDirName, 'kma') && ...
   %          ~strcmp(dacDirName, 'kordi') && ~strcmp(dacDirName, 'meds') && ...
   %          ~strcmp(dacDirName, 'nmdis'))
      if (~strcmp(dacDirName, 'jma'))
         continue
      end
   dacDirPathName = [DIR_INPUT_NC_FILES '/' dacDirName];
   if ((exist(dacDirPathName, 'dir') == 7) && ~strcmp(dacDirName, '.') && ~strcmp(dacDirName, '..'))
      
      fprintf('\nProcessing directory: %s\n', dacDirName);
      
      % create the CSV output file
      outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_collect_conf_labels_' dacDirName '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
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
            
            floatMetaFilePathName = [dacDirPathName '/' floatDirName '/' floatDirName '_meta.nc'];
            
            if (exist(floatMetaFilePathName, 'file') == 2)
               
               fprintf('%03d/%03d %s\n', idDir2, length(floatDir), floatDirName);
               
               % retrieve information from meta-data file
               wantedInputVars = [ ...
                  {'PLATFORM_NUMBER'} ...
                  {'FORMAT_VERSION'} ...
                  {'DATA_CENTRE'} ...
                  {'PLATFORM_TYPE'} ...
                  {'LAUNCH_CONFIG_PARAMETER_NAME'} ...
                  {'LAUNCH_CONFIG_PARAMETER_VALUE'} ...
                  {'CONFIG_PARAMETER_NAME'} ...
                  {'CONFIG_PARAMETER_VALUE'} ...
                  ];
               [metaData] = get_data_from_nc_file(floatMetaFilePathName, wantedInputVars);
               idVal = find(strcmp('FORMAT_VERSION', metaData(1:2:end)) == 1, 1);
               formatVersion = metaData{2*idVal}';
               if (str2num(formatVersion) ~= 3.1)
                  continue
               end
               idVal = find(strcmp('PLATFORM_NUMBER', metaData(1:2:end)) == 1, 1);
               platformNumber = metaData{2*idVal}';
               idVal = find(strcmp('DATA_CENTRE', metaData(1:2:end)) == 1, 1);
               dataCentre = metaData{2*idVal}';
               idVal = find(strcmp('PLATFORM_TYPE', metaData(1:2:end)) == 1, 1);
               platformType = metaData{2*idVal}';
               idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_NAME', metaData(1:2:end)) == 1, 1);
               launchConfigParamName = unique(cellstr(metaData{2*idVal}'));
               idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_Value', metaData(1:2:end)) == 1, 1);
               launchConfigParamValue = [metaData{2*idVal}];
               idVal = find(strcmp('CONFIG_PARAMETER_NAME', metaData(1:2:end)) == 1, 1);
               configParamName = unique(cellstr(metaData{2*idVal}'));
               idVal = find(strcmp('CONFIG_PARAMETER_VALUE', metaData(1:2:end)) == 1, 1);
               configParamValue = [metaData{2*idVal}];
               
               % create the CONFIG label list for this file
               labelList = [];
               for id = 1:length(launchConfigParamName)
                  label = launchConfigParamName{id};
                  if (isempty(strtrim(label)))
                     fprintf('ERROR: empty label detected - label ignored\n');
                     continue
                  end
                  labelList{end+1} = label;
               end
               for id = 1:length(configParamName)
                  label = configParamName{id};
                  if (isempty(strtrim(label)))
                     fprintf('ERROR: empty label detected - label ignored\n');
                     continue
                  end
                  labelList{end+1} = label;
               end
               labelList = unique(labelList);
               
               % output existing ones
               if (~isempty(labelList))
                  for id = 1:length(g_couf_searchedLabelList)
                     searchedLabel = g_couf_searchedLabelList{id};
                     if (~isempty(cell2mat(strfind(labelList, searchedLabel))))
                        idF = strfind(labelList, searchedLabel);
                        for id2 = 1:length(idF)
                           if (~isempty(idF{id2}))
                              fprintf(fidOut, '%s;%s;%s;%s;%s;%s\n', ...
                                 [floatDirName '_meta.nc'], ...
                                 strtrim(platformNumber), strtrim(formatVersion), strtrim(dataCentre), ...
                                 strtrim(platformType), labelList{id2});
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
