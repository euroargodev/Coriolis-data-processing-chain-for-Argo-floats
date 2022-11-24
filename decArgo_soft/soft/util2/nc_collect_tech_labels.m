% ------------------------------------------------------------------------------
% Check if a given list of TECH label names are used in nc TECH files.
%
% SYNTAX :
%   nc_collect_tech_labels
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
%   02/19/2016 - RNU - creation
% ------------------------------------------------------------------------------
function nc_collect_tech_labels(varargin)

% top directory of input NetCDF tech files
DIR_INPUT_NC_FILES = 'H:\archive_201603\';
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\test_update_format_tech\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

logFile = [DIR_LOG_CSV_FILE '/' 'nc_collect_tech_labels_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;


g_couf_searchedLabelList = [ ...
   {'TIME_DelayTimeBetweenRecoveryMessage'} ...
   {'TIME_MaxTransmissionTimeForRecoveryMessage'} ...
   ];

g_couf_searchedLabelList = [ ...
   {'TIME_SinceLastIridiumGPSFix'} ...
   ];

g_couf_searchedLabelList = [ ...
   {'PRES_SurfaceOffsetBeforeReset_1dBarResolution_dbar'} ...
   {'PRES_SurfaceOffsetBeforeReset_1cBarResolution_dbar'} ...
   {'PRES_SurfaceOffsetCorrectedNotResetNegative_1dbarResolution_dbar'} ...
   {'PRES_SurfaceOffsetCorrectedNotResetNegative_1cBarResolution_dbar'} ...
   {'PRES_SurfaceOffsetCorrectedNotResetNegative_1dBarResolution_dBAR'} ...
   {'PRES_SurfaceOffsetCorrectedNotResetNegative_1cBarResolution_dBar'} ...
   {'PRES_SurfaceOffsetCorrectedNotReset_1dbarResolution_dbar'} ...
   {'PRES_SurfaceOffsetCorrectedNotReset_1cBarResolution_dbar'} ...
   ];

% output CSV file header
header = ['File; PLATFORM_NUMBER; FORMAT_VERSION; DATA_CENTRE; TECHNICAL_PARAMETER_NAME'];

dacDir = dir(DIR_INPUT_NC_FILES);
for idDir = 1:length(dacDir)
   
   dacDirName = dacDir(idDir).name;
   %    if (~strcmp(dacDirName, 'jma') && ~strcmp(dacDirName, 'kma') && ...
   %          ~strcmp(dacDirName, 'kordi') && ~strcmp(dacDirName, 'meds') && ...
   %          ~strcmp(dacDirName, 'nmdis'))
   %    if (~strcmp(dacDirName, 'coriolis'))
   %       continue
   %    end
   dacDirPathName = [DIR_INPUT_NC_FILES '/' dacDirName];
   if ((exist(dacDirPathName, 'dir') == 7) && ~strcmp(dacDirName, '.') && ~strcmp(dacDirName, '..'))
      
      fprintf('\nProcessing directory: %s\n', dacDirName);
      
      % create the CSV output file
      outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_collect_tech_labels_' dacDirName '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
      fidOut = fopen(outputFileName, 'wt');
      if (fidOut == -1)
         return
      end
      fprintf(fidOut, '%s\n', header);
      
      floatDir = dir(dacDirPathName);
      for idDir2 = 1:length(floatDir)
         
         floatDirName = floatDir(idDir2).name;
         %          if (str2num(floatDirName) ~= 2901029)
         %             continue
         %          end
         floatDirPathName = [dacDirPathName '/' floatDirName];
         if (exist(floatDirPathName, 'dir') == 7)
            
            floatTechFilePathName = [dacDirPathName '/' floatDirName '/' floatDirName '_tech.nc'];
            
            if (exist(floatTechFilePathName, 'file') == 2)
               
               fprintf('%03d/%03d %s\n', idDir2, length(floatDir), floatDirName);
               
               % retrieve information from technical file
               wantedInputVars = [ ...
                  {'PLATFORM_NUMBER'} ...
                  {'FORMAT_VERSION'} ...
                  {'DATA_CENTRE'} ...
                  {'TECHNICAL_PARAMETER_NAME'} ...
                  ];
               [techData] = get_data_from_nc_file(floatTechFilePathName, wantedInputVars);
               idVal = find(strcmp('FORMAT_VERSION', techData(1:2:end)) == 1, 1);
               formatVersion = techData{2*idVal}';
               if (str2num(formatVersion) ~= 3.1)
                  continue
               end
               idVal = find(strcmp('PLATFORM_NUMBER', techData(1:2:end)) == 1, 1);
               platformNumber = techData{2*idVal}';
               idVal = find(strcmp('DATA_CENTRE', techData(1:2:end)) == 1, 1);
               dataCentre = techData{2*idVal}';
               idVal = find(strcmp('TECHNICAL_PARAMETER_NAME', techData(1:2:end)) == 1, 1);
               techParamNameList = unique(cellstr(techData{2*idVal}'));
               
               % create the TECH label list for this file
               labelList = [];
               for id = 1:length(techParamNameList)
                  label = techParamNameList{id};
                  if (isempty(strtrim(label)))
                     fprintf('ERROR: empty label detected - label ignored\n');
                     continue
                  end
                  labelList{end+1} = label;
               end
               labelList = unique(labelList);
               
               % output not allowed ones
               if (~isempty(labelList))
                  for id = 1:length(g_couf_searchedLabelList)
                     searchedLabel = g_couf_searchedLabelList{id};
                     if (~isempty(cell2mat(strfind(labelList, searchedLabel))))
                        idF = strfind(labelList, searchedLabel);
                        for id2 = 1:length(idF)
                           if (~isempty(idF{id2}))
                              fprintf(fidOut, '%s; %s; %s; %s; %s\n', ...
                                 [floatDirName '_tech.nc'], ...
                                 strtrim(platformNumber), strtrim(formatVersion), strtrim(dataCentre), labelList{id2});
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
