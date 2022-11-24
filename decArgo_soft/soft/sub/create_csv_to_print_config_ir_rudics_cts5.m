% ------------------------------------------------------------------------------
% Print float configuration in temporary CSV file.
%
% SYNTAX :
%  create_csv_to_print_config_ir_rudics_cts5(a_comment, a_conf, a_configStruct)
%
% INPUT PARAMETERS :
%   a_comment      : additional comment
%   a_conf         : configuration type
%   a_configStruct : configuration data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function create_csv_to_print_config_ir_rudics_cts5(a_comment, a_conf, a_configStruct)

% current float WMO number
global g_decArgo_floatNum;

% configuration values
global g_decArgo_dirOutputCsvFile;


% CSV files date
dateStr = datestr(now, 'yyyymmddTHHMMSS');

if (a_conf == 0)
   % output TMP configuration CSV file creation
   outputFileName = [g_decArgo_dirOutputCsvFile '/provor_config_DYNAMIC_TMP_' a_comment num2str(g_decArgo_floatNum) '_' dateStr '.csv'];
   fidOut = fopen(outputFileName, 'wt');
   if (fidOut == -1)
      fprintf('ERROR: Unable to create CSV output file: %s\n', outputFileName);
      return;
   end
   
   % print the TMP configuration
   configNums = a_configStruct.DYNAMIC_TMP.NUMBER;
   configNames = a_configStruct.DYNAMIC_TMP.NAMES;
   configValues = a_configStruct.DYNAMIC_TMP.VALUES;
   
   % detect modification in the configuration
   modifiedVal = (diff(configValues, 1, 2) ~= 0);
   sumModVal1 = sum(modifiedVal, 1);
   sumModVal2 = sum(modifiedVal, 2);
   sumModVal3 = sum(sumModVal2, 1);
   
   % keep only modified configurations
   idDel = find(sumModVal1 == 0);
   if (~isempty(idDel))
      configValues(:, idDel+1) = [];
      configDates(idDel+1) = [];
      modifiedVal = (diff(configValues, 1, 2) ~= 0);
      sumModVal1 = sum(modifiedVal, 1);
      sumModVal2 = sum(modifiedVal, 2);
      sumModVal3 = sum(sumModVal2, 1);
   end
   
   fprintf(fidOut, 'Number; %d;', sumModVal3);
   for idC = 1:length(configNums)
      fprintf(fidOut, '%d;', configNums(idC));
      if (idC < length(configNums))
         fprintf(fidOut, '%d;', sumModVal1(idC));
      end
   end
   fprintf(fidOut, '\n');
   
   for idL = 1:length(configNames)
      fprintf(fidOut, '%s;', configNames{idL});
      for idC = 1:size(configValues, 2)
         if (idC == 1)
            fprintf(fidOut, '%d;', sumModVal2(idL));
         end
         value = num2str(configValues(idL, idC));
         fprintf(fidOut, '%s;', value);
         if (idC < size(configValues, 2))
            fprintf(fidOut, '%d;', modifiedVal(idL, idC));
         end
      end
      fprintf(fidOut, '\n');
   end
   
   fclose(fidOut);
   
end

if (a_conf == 1)
   % output TMP configuration CSV file creation
   outputFileName = [g_decArgo_dirOutputCsvFile '/provor_config_DYNAMIC_' a_comment num2str(g_decArgo_floatNum) '_' dateStr '.csv'];
   fidOut = fopen(outputFileName, 'wt');
   if (fidOut == -1)
      fprintf('ERROR: Unable to create CSV output file: %s\n', outputFileName);
      return;
   end
   
   % print the full configuration
   cycle = a_configStruct.USE.CYCLE;
   profile = a_configStruct.USE.PROFILE;
   cycleOut = a_configStruct.USE.CYCLE_OUT;
   cfNum = a_configStruct.USE.CONFIG;
   configNum = a_configStruct.DYNAMIC.NUMBER;
   configNames = a_configStruct.DYNAMIC.NAMES;
   configValues = a_configStruct.DYNAMIC.VALUES;
   
   fprintf(fidOut, 'Cycles#;');
   for idC = 1:length(cycle)
      fprintf(fidOut, '%d;', cycle(idC));
   end
   fprintf(fidOut, '\n');
   fprintf(fidOut, 'Profiles#;');
   for idP = 1:length(profile)
      fprintf(fidOut, '%d;', profile(idP));
   end
   fprintf(fidOut, '\n');
   fprintf(fidOut, 'Output cycles#;');
   for idC = 1:length(cycleOut)
      fprintf(fidOut, '%d;', cycleOut(idC));
   end
   fprintf(fidOut, '\n');
   fprintf(fidOut, 'Config#;');
   for idN = 1:length(cfNum)
      fprintf(fidOut, '%d;', cfNum(idN));
   end
   fprintf(fidOut, '\n');
   fprintf(fidOut, '\n');
   
   % delete the unused configuration parameters
   idDel = [];
   for idL = 1:size(configValues, 1)
      if (sum(isnan(configValues(idL, :))) == size(configValues, 2))
         idDel = [idDel; idL];
      end
   end
   configNames(idDel) = [];
   configValues(idDel, :) = [];
   
   % detect modification in the configuration
   if (isempty(find(configValues == realmax, 1)))
      configValues2 = configValues;
      configValues2(find(isnan(configValues2))) = realmax;
   end
   modifiedVal = (diff(configValues2, 1, 2) ~= 0);
   sumModVal1 = sum(modifiedVal, 1);
   sumModVal2 = sum(modifiedVal, 2);
   sumModVal3 = sum(sumModVal2, 1);

   % keep only modified configurations
   idDel = find(sumModVal1 == 0);
   if (~isempty(idDel))
      configValues2(:, idDel+1) = [];
      modifiedVal = (diff(configValues2, 1, 2) ~= 0);
      sumModVal1 = sum(modifiedVal, 1);
      sumModVal2 = sum(modifiedVal, 2);
      sumModVal3 = sum(sumModVal2, 1);
      
      configNum(idDel) = [];
      configValues(:, idDel) = [];
   end
   
   fprintf(fidOut, 'Num; %d;', sumModVal3);
   for idC = 1:length(configNum)
      fprintf(fidOut, '%d;', configNum(idC));
      if (idC < length(configNum))
         fprintf(fidOut, '%d;', sumModVal1(idC));
      end
   end
   fprintf(fidOut, '\n');
   
   for idL = 1:length(configNames)
      fprintf(fidOut, '%s;', configNames{idL});
      for idC = 1:size(configValues, 2)
         if (idC == 1)
            fprintf(fidOut, '%d;', sumModVal2(idL));
         end
         value = num2str(configValues(idL, idC));
         fprintf(fidOut, '%s;', value);
         if (idC < size(configValues, 2))
            fprintf(fidOut, '%d;', modifiedVal(idL, idC));
         end
      end
      fprintf(fidOut, '\n');
   end
   
   fclose(fidOut);
   
end

if (a_conf == 2)
   % output final configuration CSV file creation
   outputFileName = [g_decArgo_dirOutputCsvFile '/provor_config_NC_' a_comment num2str(g_decArgo_floatNum) '_' dateStr '.csv'];
   fidOut = fopen(outputFileName, 'wt');
   if (fidOut == -1)
      fprintf('ERROR: Unable to create CSV output file: %s\n', outputFileName);
      return;
   end
   
   % print the NetCDF configuration
   staticConfigDecNames = a_configStruct.STATIC_NC.NAMES_DEC;
   staticConfigNames = a_configStruct.STATIC_NC.NAMES;
   staticConfigValues = a_configStruct.STATIC_NC.VALUES;
   configNum = a_configStruct.DYNAMIC_NC.NUMBER;
   configDecNames = a_configStruct.DYNAMIC_NC.NAMES_DEC;
   configNames = a_configStruct.DYNAMIC_NC.NAMES;
   configValues = a_configStruct.DYNAMIC_NC.VALUES;
   
   fprintf(fidOut, 'Config#;Config#;');
   for idN = 1:length(configNum)
      fprintf(fidOut, '%d;', configNum(idN));
   end
   fprintf(fidOut, '\n');
   fprintf(fidOut, '\n');
      
   % detect modification in the configuration
   if (isempty(find(configValues == 9999999999, 1)))
      configValues2 = configValues;
      configValues2(find(isnan(configValues2))) = 9999999999;
   end
   modifiedVal = (diff(configValues2, 1, 2) ~= 0);
   sumModVal1 = sum(modifiedVal, 1);
   sumModVal2 = sum(modifiedVal, 2);
   sumModVal3 = sum(sumModVal2, 1);

   % keep only modified configurations
   idDel = find(sumModVal1 == 0);
   if (~isempty(idDel))
      configValues2(:, idDel+1) = [];
      modifiedVal = (diff(configValues2, 1, 2) ~= 0);
      sumModVal1 = sum(modifiedVal, 1);
      sumModVal2 = sum(modifiedVal, 2);
      sumModVal3 = sum(sumModVal2, 1);
      
      configNum(idDel+1) = [];
      configValues(:, idDel+1) = [];
   end
   
   fprintf(fidOut, 'Num; Num; %d;', sumModVal3);
   for idC = 1:length(configNum)
      fprintf(fidOut, '%d;', configNum(idC));
      if (idC < length(configNum))
         fprintf(fidOut, '%d;', sumModVal1(idC));
      end
   end
   fprintf(fidOut, '\n');
   
   for idL = 1:length(staticConfigNames)
      fprintf(fidOut, '%s; %s;', staticConfigDecNames{idL}, staticConfigNames{idL});
      for idC = 1:size(configValues, 2)
         value = staticConfigValues{idL};
         fprintf(fidOut, '0; %s;', value);
      end
      fprintf(fidOut, '\n');
   end
   
   for idL = 1:length(configNames)
      fprintf(fidOut, '%s; %s;', configDecNames{idL}, configNames{idL});
      for idC = 1:size(configValues, 2)
         if (idC == 1)
            fprintf(fidOut, '%d;', sumModVal2(idL));
         end
         value = num2str(configValues(idL, idC));
         fprintf(fidOut, '%s;', value);
         if (idC < size(configValues, 2))
            fprintf(fidOut, '%d;', modifiedVal(idL, idC));
         end
      end
      fprintf(fidOut, '\n');
   end
   
   fclose(fidOut);
   
end

return;
