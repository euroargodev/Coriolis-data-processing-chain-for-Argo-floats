% ------------------------------------------------------------------------------
% Print the configurations in a CSV file.
%
% SYNTAX :
%  print_config_in_csv_file_ir_sbd(a_comment, a_conf, a_configStruct)
%
% INPUT PARAMETERS :
%   a_comment      : comment to add into the CSV file name
%   a_conf         : which configuration to print
%                    (0: DYNAMIC_TMP, 1: DYNAMIC, 2: NC configuration, 3: Argos
%                     CURRENT configuration)
%   a_configStruct : configuration structure
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function print_config_in_csv_file_ir_sbd(a_comment, a_conf, a_configStruct)

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
   configDates = a_configStruct.DYNAMIC_TMP.DATES;
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
   
   fprintf(fidOut, 'Dates; %d;', sumModVal3);
   for idC = 1:length(configDates)
      fprintf(fidOut, '%s;', julian_2_gregorian_dec_argo(configDates(idC)));
      if (idC < length(configDates))
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
   cfNum = a_configStruct.USE.CONFIG;
   configNum = a_configStruct.DYNAMIC.NUMBER;
   configNames = a_configStruct.DYNAMIC.NAMES;
   configValues = a_configStruct.DYNAMIC.VALUES;
   
   fprintf(fidOut, 'Cycles#;');
   for idC = 1:length(cycle)
      fprintf(fidOut, '%d;', cycle(idC));
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

if (a_conf == 3)
   % output TMP configuration CSV file creation
   outputFileName = [g_decArgo_dirOutputCsvFile '/provor_config_' a_comment num2str(g_decArgo_floatNum) '_' dateStr '.csv'];
   fidOut = fopen(outputFileName, 'wt');
   if (fidOut == -1)
      fprintf('ERROR: Unable to create CSV output file: %s\n', outputFileName);
      return;
   end
   
   % print the full configuration
   cycle = a_configStruct.USE.CYCLE;
   cfNum = a_configStruct.USE.CONFIG;
   configNum = a_configStruct.NUMBER;
   configNames = a_configStruct.NAMES;
   configValues = a_configStruct.VALUES;
   
   fprintf(fidOut, 'Cycles#;');
   for idC = 1:length(cycle)
      fprintf(fidOut, '%d;', cycle(idC));
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

return;
