% ------------------------------------------------------------------------------
% Retrieve the values for a given TECH_AUX label.
%
% SYNTAX :
%   nc_get_tech_aux_value
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/07/2019 - RNU - creation
% ------------------------------------------------------------------------------
function nc_get_tech_aux_value

% top directory of input NetCDF TECH_AUX files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';


logFile = [DIR_LOG_CSV_FILE '/' 'nc_get_tech_aux_value_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_get_tech_aux_value_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end

% output CSV file header
header = 'WMO; CyNum; TECH_LABEL; TECH_VALUE';
fprintf(fidOut, '%s\n', header);

floatDir = dir(DIR_INPUT_NC_FILES);
for idDir2 = 1:length(floatDir)

   floatDirName = floatDir(idDir2).name;
   floatDirPathName = [DIR_INPUT_NC_FILES '/' floatDirName];
   if ((exist(floatDirPathName, 'dir') == 7) && ~strcmp(floatDirName, '.') && ~strcmp(floatDirName, '..'))

      fprintf('%03d/%03d %s\n', idDir2, length(floatDir), floatDirName);

      floatTechFilePathName = [floatDirPathName '/auxiliary/' floatDirName '_tech_aux.nc'];

      if (exist(floatTechFilePathName, 'file') == 2)

         % retrieve information from technical file
         wantedInputVars = [ ...
            {'CYCLE_NUMBER'} ...
            {'TECHNICAL_PARAMETER_NAME'} ...
            {'TECHNICAL_PARAMETER_VALUE'} ...
            ];
         [techData] = get_data_from_nc_file(floatTechFilePathName, wantedInputVars);
         idVal = find(strcmp('CYCLE_NUMBER', techData(1:2:end)) == 1, 1);
         cycleNumber = techData{2*idVal};
         idVal = find(strcmp('TECHNICAL_PARAMETER_NAME', techData(1:2:end)) == 1, 1);
         techParamNameList = cellstr(techData{2*idVal}');
         idVal = find(strcmp('TECHNICAL_PARAMETER_VALUE', techData(1:2:end)) == 1, 1);
         techParamValueList = cellstr(techData{2*idVal}');

         idF = find(strcmp('TECH_FLAG_FeedbackAlarm_LOGICAL', techParamNameList));
         for id = 1:length(idF)
            fprintf(fidOut, '%s;%d;%s;%s\n', floatDirName, cycleNumber(idF(id)), techParamNameList{idF(id)}, techParamValueList{idF(id)});
         end
      end
   end
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
