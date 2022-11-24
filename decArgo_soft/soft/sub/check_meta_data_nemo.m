% ------------------------------------------------------------------------------
% Check collected meta-data data against float meta-data stored in the JSON file
% and provide needed updates (PI decoder only).
%
% SYNTAX :
%  check_meta_data_nemo
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :.
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function check_meta_data_nemo

% current float WMO number
global g_decArgo_floatNum;

% directory of json meta-data files
global g_decArgo_dirInputJsonFloatMetaDataFile;

% storage of META-DATA information (to update data base) - CSV decoder only
global g_decArgo_metaDataAll;

% configuration values
global g_decArgo_dirOutputCsvFile;

% file to store BDD update
global g_decArgo_bddUpdateCsvFileName;
global g_decArgo_bddUpdateCsvFileId;


if (isempty(g_decArgo_metaDataAll))
   return
end

ONLY_DIFF = 1;

% clean meta-data from duplicates
techParamIdList = unique([g_decArgo_metaDataAll.techParamId]);
for idP = techParamIdList
   idF = find([g_decArgo_metaDataAll.techParamId] == idP);
   if (length(idF) > 1)
      if (length(unique({g_decArgo_metaDataAll(idF).value})) > 1)
         values = unique({g_decArgo_metaDataAll(idF).value});
         valuesStr = sprintf('''%s'' ', values{:});
         fprintf('WARNING: Float #%d: Multiple values for meta-data ''%s'' (%s)\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_metaDataAll(idF(1)).metaConfigLabel, ...
            valuesStr(1:end-1));
      end
   end
end
[~, idUnique, ~] = unique([g_decArgo_metaDataAll.techParamId]);
g_decArgo_metaDataAll = g_decArgo_metaDataAll(idUnique);

% json meta-data file for this float
jsonInputFileName = [g_decArgo_dirInputJsonFloatMetaDataFile '/' sprintf('%d_meta.json', g_decArgo_floatNum)];

if ~(exist(jsonInputFileName, 'file') == 2)
   fprintf('ERROR: Json meta-data file not found: %s\n', jsonInputFileName);
   return
end

% read meta-data file
jsonMetaData = loadjson(jsonInputFileName);

% check meta-data consistency (compare meta-data with JSON file contents)
for idM = 1:length(g_decArgo_metaDataAll)
   dataStruct = g_decArgo_metaDataAll(idM);
   if (isfield(jsonMetaData, dataStruct.metaConfigLabel))
      if (~strcmp(dataStruct.metaConfigLabel, 'TRANS_SYSTEM'))
         if (~strcmp(jsonMetaData.(dataStruct.metaConfigLabel), dataStruct.techParamValue))
            % output CSV file creation
            if (g_decArgo_bddUpdateCsvFileId == -1)
               g_decArgo_bddUpdateCsvFileName = [g_decArgo_dirOutputCsvFile '/data_to_update_bdd_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
               g_decArgo_bddUpdateCsvFileId = fopen(g_decArgo_bddUpdateCsvFileName, 'wt');
               if (g_decArgo_bddUpdateCsvFileId == -1)
                  fprintf('ERROR: Unable to create CSV output file: %s\n', g_decArgo_bddUpdateCsvFileName);
                  return
               end
               
               header = 'PLATFORM_CODE;TECH_PARAMETER_ID;DIM_LEVEL;CORIOLIS_TECH_METADATA.PARAMETER_VALUE;TECH_PARAMETER_CODE';
               fprintf(g_decArgo_bddUpdateCsvFileId, '%s\n', header);
            end
            
            if (~strcmp(dataStruct.techParamCode, 'PR_LAUNCH_DATETIME'))
               fprintf(g_decArgo_bddUpdateCsvFileId, '%d;%d;%d;%s;%s\n', ...
                  g_decArgo_floatNum, ...
                  dataStruct.techParamId, 1, dataStruct.techParamValue, dataStruct.techParamCode);
            else
               fprintf(g_decArgo_bddUpdateCsvFileId, '%d;%d;%d;''%s;%s\n', ...
                  g_decArgo_floatNum, ...
                  dataStruct.techParamId, 1, dataStruct.techParamValue, dataStruct.techParamCode);
            end
            
            fprintf('WARNING: Float #%d: Meta-data ''%s'': decoder value (''%s'') and configuration value (''%s'') differ => BDD contents should be updated (see %s)\n', ...
               g_decArgo_floatNum, ...
               dataStruct.metaConfigLabel, ...
               dataStruct.techParamValue, ...
               jsonMetaData.(dataStruct.metaConfigLabel), ...
               g_decArgo_bddUpdateCsvFileName);
         else
            if (ONLY_DIFF == 0)
               fprintf('INFO: Float #%d: Meta-data ''%s'': decoder value (''%s'') and configuration value (''%s'')\n', ...
                  g_decArgo_floatNum, ...
                  dataStruct.metaConfigLabel, ...
                  dataStruct.techParamValue, ...
                  jsonMetaData.(dataStruct.metaConfigLabel));
            end
         end
      elseif (strcmp(dataStruct.metaConfigLabel, 'TRANS_SYSTEM'))
         fieldNames = fields(jsonMetaData.(dataStruct.metaConfigLabel));
         if (~strcmp(jsonMetaData.(dataStruct.metaConfigLabel).(fieldNames{1}), dataStruct.techParamValue))
            % output CSV file creation
            if (g_decArgo_bddUpdateCsvFileId == -1)
               g_decArgo_bddUpdateCsvFileName = [g_decArgo_dirOutputCsvFile '/data_to_update_bdd_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
               g_decArgo_bddUpdateCsvFileId = fopen(g_decArgo_bddUpdateCsvFileName, 'wt');
               if (g_decArgo_bddUpdateCsvFileId == -1)
                  fprintf('ERROR: Unable to create CSV output file: %s\n', g_decArgo_bddUpdateCsvFileName);
                  return
               end
               
               header = 'PLATFORM_CODE;TECH_PARAMETER_ID;DIM_LEVEL;CORIOLIS_TECH_METADATA.PARAMETER_VALUE;TECH_PARAMETER_CODE';
               fprintf(g_decArgo_bddUpdateCsvFileId, '%s\n', header);
            end
            
            fprintf(g_decArgo_bddUpdateCsvFileId, '%d;%d;%d;%s;%s\n', ...
               g_decArgo_floatNum, ...
               dataStruct.techParamId, 1, dataStruct.techParamValue, dataStruct.techParamCode);
            
            fprintf('WARNING: Float #%d: Meta-data ''%s'': decoder value (''%s'') and configuration value (''%s'') differ => BDD contents should be updated (see %s)\n', ...
               g_decArgo_floatNum, ...
               dataStruct.metaConfigLabel, ...
               dataStruct.techParamValue, ...
               jsonMetaData.(dataStruct.metaConfigLabel).(fieldNames{1}), ...
               g_decArgo_bddUpdateCsvFileName);
         else
            if (ONLY_DIFF == 0)
               fprintf('INFO: Float #%d: Meta-data ''%s'': decoder value (''%s'') and configuration value (''%s'')\n', ...
                  g_decArgo_floatNum, ...
                  dataStruct.metaConfigLabel, ...
                  dataStruct.techParamValue, ...
                  jsonMetaData.(dataStruct.metaConfigLabel).(fieldNames{1}));
            end
         end
      end
   else
      fprintf('WARNING: Float #%d: Field ''%s'' is not in the meta-data configuration\n', ...
         g_decArgo_floatNum, dataStruct.metaConfigLabel);
      
      fprintf(g_decArgo_bddUpdateCsvFileId, '%d;%d;%d;%s;%s\n', ...
         g_decArgo_floatNum, ...
         dataStruct.techParamId, 1, dataStruct.techParamValue, dataStruct.techParamCode);
   end
end

return
