% ------------------------------------------------------------------------------
% Print mission configuration data in CSV file.
%
% SYNTAX :
%  print_config_mission_info_apx_apf11_in_csv_file(a_configdata)
%
% INPUT PARAMETERS :
%   a_configdata : mission configuration data
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
function print_config_mission_info_apx_apf11_in_csv_file(a_configdata)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


for idS = 1:size(a_configdata, 1)
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; MissionCfg; Sys; Conf#; Mission configuration date; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_configdata{idS, 1}));
   
   configData = a_configdata{idS, 2};
   confLabel = fieldnames(configData);
   for idC = 1:length(confLabel)
      if (length(configData.(confLabel{idC})) == 1)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; MissionCfg; Sys; %d; %s; %s\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            idS, confLabel{idC}, configData.(confLabel{idC}){:});
      else
         data = sprintf('%s;', configData.(confLabel{idC}){:});
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; MissionCfg; Sys; %d; %s; %s\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            idS, confLabel{idC}, data);
      end
   end
end

return;
