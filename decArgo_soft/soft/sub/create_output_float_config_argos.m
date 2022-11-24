% ------------------------------------------------------------------------------
% Create the final configuration that will be used in the meta.nc file.
%
% SYNTAX :
%  [o_ncConfig] = create_output_float_config_argos( ...
%    a_decArgoConfParamNames, a_ncConfParamNames, a_decoderId)
%
% INPUT PARAMETERS :
%   a_decArgoConfParamNames : internal configuration parameter names
%   a_ncConfParamNames      : NetCDF configuration parameter names
%   a_decoderId             : float decoder Id
%
% OUTPUT PARAMETERS :
% o_ncConfig : NetCDF configuration
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/10/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncConfig] = create_output_float_config_argos( ...
   a_decArgoConfParamNames, a_ncConfParamNames, a_decoderId)

% output parameters initialization
o_ncConfig = [];

% float configuration
global g_decArgo_floatConfig;

% current float WMO number
global g_decArgo_floatNum;


% current configuration
finalConfigNum = [];
finalConfigName = [];
finalConfigValue = [];
if (~isempty(g_decArgo_floatConfig) && ...
      (isfield(g_decArgo_floatConfig, 'NUMBER') && ...
      isfield(g_decArgo_floatConfig, 'NAMES') && ...
      isfield(g_decArgo_floatConfig, 'VALUES')))
   finalConfigNum = g_decArgo_floatConfig.NUMBER;
   finalConfigName = g_decArgo_floatConfig.NAMES;
   finalConfigValue = g_decArgo_floatConfig.VALUES;
end

% delete the unused configuration parameters
idDel = [];
for idL = 1:size(finalConfigValue, 1)
   if (sum(isnan(finalConfigValue(idL, :))) == size(finalConfigValue, 2))
      idDel = [idDel; idL];
   end
end
finalConfigName(idDel) = [];
finalConfigValue(idDel, :) = [];

% convert decoder names into NetCDF ones
if (~isempty(a_decArgoConfParamNames))
   idDel = [];
   for idConfParam = 1:length(finalConfigName)
      idFUs = strfind(finalConfigName{idConfParam}, '_');
      idF = find(strcmp(finalConfigName{idConfParam}(1:idFUs(2)-1), a_decArgoConfParamNames) == 1);
      if (~isempty(idF))
         finalConfigName{idConfParam} = a_ncConfParamNames{idF};
      else
         % Apex APF11 floats
         if (ismember(a_decoderId, [1021 1022]))
            if (strcmp(finalConfigName{idConfParam}(1:idFUs(2)-1), 'CONFIG_SAMPLE'))
               switch (finalConfigName{idConfParam}(idFUs(end)+1:end))
                  case 'NumberOfZones'
                     idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE01') == 1);
                     finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                        [{'<short_sensor_name>'} {'Ctd'} ...
                        {'<vertical_phase_name>'} {'AscentPhase'}]);
                  case 'StartPressure'
                     idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE02') == 1);
                     finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                        [{'<short_sensor_name>'} {'Ctd'} ...
                        {'<vertical_phase_name>'} {'AscentPhase'} ...
                        {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                  case 'StopPressure'
                     idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE03') == 1);
                     finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                        [{'<short_sensor_name>'} {'Ctd'} ...
                        {'<vertical_phase_name>'} {'AscentPhase'} ...
                        {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                  case 'DepthInterval'
                     if (~any(finalConfigValue(idConfParam, :) == 0))
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE04') == 1);
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {'Ctd'} ...
                           {'<vertical_phase_name>'} {'AscentPhase'} ...
                           {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                     else
                        % retrieve CONFIG_ATI_AscentTimerInterval information
                        idF3 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_ATI') == 1);
                        finalConfigValue(idConfParam, :) = finalConfigValue(idF3, :);
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE05') == 1);
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {'Ctd'} ...
                           {'<vertical_phase_name>'} {'AscentPhase'} ...
                           {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                     end
                  case 'NumberOfSamples'
                     idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE06') == 1);
                     finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                        [{'<short_sensor_name>'} {'Ctd'} ...
                        {'<vertical_phase_name>'} {'AscentPhase'} ...
                        {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                  otherwise
                     fprintf('WARNING: Float #%d: Configuration parameter (*%s) not managed yet for decoderId #%d\n', ...
                        g_decArgo_floatNum, ...
                        finalConfigName{idConfParam}(idFUs(end)+1:end), ...
                        a_decoderId);
               end
            end
         else
            % some of the managed parameters are not saved in the meta.nc file
            idDel = [idDel; idConfParam];
            switch (a_decoderId)
               case {30, 32}
                  notNcConfigNameList = [...
                     {'CONFIG_MC1_'} ...
                     {'CONFIG_MC2_'} ...
                     {'CONFIG_MC3_'} ...
                     {'CONFIG_MC10_'} ...
                     {'CONFIG_MC11_'} ...
                     {'CONFIG_MC12_'} ...
                     {'CONFIG_MC13_'} ...
                     {'CONFIG_MC24_'} ...
                     {'CONFIG_TC14_'} ...
                     {'CONFIG_TC15_'} ...
                     {'CONFIG_TC17_'} ...
                     {'CONFIG_TC18_'} ...
                     ];
                  configName = finalConfigName{idConfParam};
                  idFUs = strfind(configName, '_');
                  configName = configName(1:idFUs(2));
                  if (any(strcmp(configName, notNcConfigNameList)))
                     continue
                  end
            end
            
            fprintf('DEC_INFO: Float #%d: Cannot convert configuration param name :''%s'' into NetCDF one\n', ...
               g_decArgo_floatNum, ...
               finalConfigName{idConfParam});
         end
      end
   end
   finalConfigName(idDel) = [];
   finalConfigValue(idDel, :) = [];

   % output data
   o_ncConfig.STATIC_NC = [];
   o_ncConfig.STATIC_NC.NAMES = [];
   o_ncConfig.STATIC_NC.VALUES = [];
   if (~isempty(g_decArgo_floatConfig))
      if (isfield(g_decArgo_floatConfig, 'STATIC_NC'))
         o_ncConfig.STATIC_NC.NAMES = g_decArgo_floatConfig.STATIC_NC.NAMES;
         o_ncConfig.STATIC_NC.VALUES = g_decArgo_floatConfig.STATIC_NC.VALUES;
      end
   end
   o_ncConfig.NUMBER = finalConfigNum;
   o_ncConfig.NAMES = finalConfigName;
   o_ncConfig.VALUES = finalConfigValue;
end

return
