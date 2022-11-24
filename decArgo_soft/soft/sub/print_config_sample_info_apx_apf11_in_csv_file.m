% ------------------------------------------------------------------------------
% Print sample configuration data in CSV file.
%
% SYNTAX :
%  print_config_sample_info_apx_apf11_in_csv_file(a_configdata)
%
% INPUT PARAMETERS :
%   a_configdata : sample configuration data
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
function print_config_sample_info_apx_apf11_in_csv_file(a_configdata)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


for idS = 1:size(a_configdata, 1)
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; SampleCfg; Sys; Conf#; Sample configuration date; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_configdata{idS, 1}));
   
   configData = a_configdata{idS, 2};
   phaseLabel = fieldnames(configData);
   for idP = 1:length(phaseLabel)
      phase = phaseLabel{idP};
      sampTypes = fieldnames(configData.(phase));
      for idST = 1:length(sampTypes)
         sampType = sampTypes{idST};
         sensorLabel = fieldnames(configData.(phase).(sampType));
         for idC = 1:length(sensorLabel)
            sensor = sensorLabel{idC};
            data = configData.(phase).(sampType).(sensor);
            for idZ = 1:size(data, 1)
               val = sprintf('%d;', data(idZ, :));
               fprintf(g_decArgo_outputCsvFileId, '%d; %d; SampleCfg; Sys; %d; %s; %s; %s; %s\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  idS, phase, sampType, sensor, val);
            end
         end
      end
   end
end

return
