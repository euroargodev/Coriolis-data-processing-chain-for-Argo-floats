% ------------------------------------------------------------------------------
% Print the configurations of an Apex APF11 Ir-SBD in a CSV file.
%
% SYNTAX :
%  create_csv_to_print_config_apx_apf11_ir(a_comment, a_configStruct)
%
% INPUT PARAMETERS :
%   a_comment      : comment to add into the CSV file name
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
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function create_csv_to_print_config_apx_apf11_ir(a_comment, a_configStruct)

% current float WMO number
global g_decArgo_floatNum;

% configuration values
global g_decArgo_dirOutputCsvFile;


% CSV files date
dateStr = datestr(now, 'yyyymmddTHHMMSS');

% CSV file creation
outputFileName = [g_decArgo_dirOutputCsvFile '/float_config_' a_comment num2str(g_decArgo_floatNum) '_' dateStr '.csv'];
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
% idDel = find(sumModVal1 == 0);
% if (~isempty(idDel))
%    configValues2(:, idDel+1) = [];
%    modifiedVal = (diff(configValues2, 1, 2) ~= 0);
%    sumModVal1 = sum(modifiedVal, 1);
%    sumModVal2 = sum(modifiedVal, 2);
%    sumModVal3 = sum(sumModVal2, 1);
%    
%    configNum(idDel+1) = [];
%    configValues(:, idDel+1) = [];
% end

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

return;
