% ------------------------------------------------------------------------------
% Create the final configuration that will be used in the meta.nc file.
%
% SYNTAX :
%  [o_ncConfig] = create_output_float_config_apx_ir( ...
%    a_decArgoConfParamNames, a_ncConfParamNames, a_decoderId)
%
% INPUT PARAMETERS :
%    a_decArgoConfParamNames : internal configuration parameter names
%    a_ncConfParamNames      : NetCDF configuration parameter names
%   a_decoderId              : float decoder Id
%
% OUTPUT PARAMETERS :
%    o_ncConfig : NetCDF configuration
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncConfig] = create_output_float_config_apx_ir( ...
   a_decArgoConfParamNames, a_ncConfParamNames, a_decoderId)

% output parameters initialization
o_ncConfig = [];

% float configuration
global g_decArgo_floatConfig;

% current float WMO number
global g_decArgo_floatNum;


% current (and final) configuration
finalConfigNum = g_decArgo_floatConfig.NUMBER;
finalConfigName = g_decArgo_floatConfig.NAMES;
finalConfigValue = g_decArgo_floatConfig.VALUES;

% delete the unused configuration parameters
idDel = [];
for idL = 1:size(finalConfigValue, 1)
   if (sum(isnan(finalConfigValue(idL, :))) == size(finalConfigValue, 2))
      idDel = [idDel; idL];
   end
end
finalConfigName(idDel) = [];
finalConfigValue(idDel, :) = [];

% APF11 floats
if (ismember(a_decoderId, [1121 1321 1322]))
   
   % convert CONFIG_AR_AscentRate from dbar/s to mm/s
   idF1 = find(strcmp(finalConfigName, 'CONFIG_AR_AscentRate'));
   idF2 = find(~isnan(finalConfigValue(idF1, :)));
   finalConfigValue(idF1, idF2) = finalConfigValue(idF1, idF2) * 1000;
   
   % if CONFIG_ICEM_IceDetectionMask = 0, remove Ice relative configuration
   % parameters
   idF = find(strcmp(finalConfigName, 'CONFIG_ICEM_IceDetectionMask'));
   if (~any(~isnan(finalConfigValue(idF, :)) & (finalConfigValue(idF, :) ~= 0)))
      idDel = find( ...
         strcmp(finalConfigName, 'CONFIG_IBD_IceBreakupDays') | ...
         strcmp(finalConfigName, 'CONFIG_IMLT_IceDetectionTemperature') | ...
         strcmp(finalConfigName, 'CONFIG_IDP_IceDetectionMaxPres') | ...
         strcmp(finalConfigName, 'CONFIG_IEP_IceEvasionPressure') | ...
         strcmp(finalConfigName, 'CONFIG_ICEM_IceDetectionMask') ...
         );
      finalConfigName(idDel) = [];
      finalConfigValue(idDel, :) = [];
   end
   
   % link between sensor names (to create Argo names from float ones)
   floatToNcSensorList = [ ...
      {'PT'} {'Ctd'}; ...
      {'PTS'} {'Ctd'}; ...
      {'CTD'} {'Ctd'}; ...
      {'PTSH'} {'Ph'}; ...
      {'PH'} {'Ph'}; ...
      {'OPT'} {'Optode'}; ...
      {'FLBB'} {'Eco'}; ...
      {'IRAD'} {'Ocr'}; ...
   ];
end

% convert decoder names into NetCDF ones
if (~isempty(a_decArgoConfParamNames))
   
   idDel = [];
   for idConfParam = 1:length(finalConfigName)
      finalConfigNameShort = finalConfigName{idConfParam};
      if (~strncmp(finalConfigNameShort, 'CONFIG_PX_', length('CONFIG_PX_')))
         idFUs = strfind(finalConfigNameShort, '_');
         finalConfigNameShort = finalConfigNameShort(1:idFUs(2)-1);
      end
      idF = find(strcmp(finalConfigNameShort, a_decArgoConfParamNames) == 1);
      if (~isempty(idF))
         finalConfigName{idConfParam} = a_ncConfParamNames{idF};
      else
         
         % Apex APF11 floats
         if (ismember(a_decoderId, [1121 1321 1322]))
            if (ismember(finalConfigName{idConfParam}(1:idFUs(2)-1), ['CONFIG_SAMPLE' 'CONFIG_PROFILE' 'CONFIG_MEASURE']))

               % retrieve phase name
               if (~isempty(strfind(finalConfigName{idConfParam}, '_PARK_')))
                  phaseName = 'ParkDriftPhase';
               elseif (~isempty(strfind(finalConfigName{idConfParam}, '_ASCENT_')))
                  phaseName = 'AscentPhase';
               elseif (~isempty(strfind(finalConfigName{idConfParam}, '_SURFACE_')))
                  phaseName = 'SurfaceDriftPhase';
               else
                  fprintf('ERROR: Float #%d: Cannot find phase name associated to ''%s''\n', ...
                     g_decArgo_floatNum, ...
                     finalConfigName{idConfParam});
                  continue
               end
               
               % retrieve sensor name
               sensorNameIn = finalConfigName{idConfParam}(idFUs(3)+1:idFUs(4)-1);
               idS = find(strcmp(sensorNameIn, floatToNcSensorList(:, 1)));
               if (~isempty(idS))
                  sensorNameOut = floatToNcSensorList{idS, 2};
               else
                  fprintf('ERROR: Float #%d: Cannot find sensor name associated to ''%s''\n', ...
                     g_decArgo_floatNum, ...
                     sensorNameIn);
                  continue
               end
               
               if (strcmp(finalConfigName{idConfParam}(1:idFUs(2)-1), 'CONFIG_SAMPLE'))
                  
                  switch (finalConfigName{idConfParam}(idFUs(end)+1:end))
                     case 'NumberOfZones'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE01') == 1);
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut} ...
                           {'<vertical_phase_name>'} {phaseName}]);
                     case 'StartPressure'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE02') == 1);
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut} ...
                           {'<vertical_phase_name>'} {phaseName} ...
                           {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                     case 'StopPressure'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE03') == 1);
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut} ...
                           {'<vertical_phase_name>'} {phaseName} ...
                           {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                     case 'DepthInterval'
                        if (~any(finalConfigValue(idConfParam, :) == 0))
                           idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE04') == 1);
                           finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                              [{'<short_sensor_name>'} {sensorNameOut} ...
                              {'<vertical_phase_name>'} {phaseName} ...
                              {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                        else
                           % retrieve CONFIG_ATI_AscentTimerInterval information
                           idF3 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_ATI') == 1);
                           finalConfigValue(idConfParam, :) = finalConfigValue(idF3, :);
                           idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE05') == 1);
                           finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                              [{'<short_sensor_name>'} {sensorNameOut} ...
                              {'<vertical_phase_name>'} {phaseName} ...
                              {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                        end
                     case 'NumberOfSamples'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE06') == 1);
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut} ...
                           {'<vertical_phase_name>'} {phaseName} ...
                           {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                     otherwise
                        fprintf('WARNING: Float #%d: Configuration parameter (*%s) not managed yet for decoderId #%d\n', ...
                           g_decArgo_floatNum, ...
                           finalConfigName{idConfParam}(idFUs(end)+1:end), ...
                           a_decoderId);
                  end
                  
               elseif (strcmp(finalConfigName{idConfParam}(1:idFUs(2)-1), 'CONFIG_PROFILE'))
                  
                  switch (finalConfigName{idConfParam}(idFUs(end)+1:end))
                     case 'NumberOfZones'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_PROFILE01') == 1);
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut}]);
                     case 'StartPressure'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_PROFILE02') == 1);
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut} ...
                           {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                     case 'StopPressure'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_PROFILE03') == 1);
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut} ...
                           {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                     case 'BinSize'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_PROFILE04') == 1);
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut} ...
                           {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                     case 'SampleRate'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_PROFILE05') == 1);
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut} ...
                           {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                     case 'TimeInterval'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_PROFILE06') == 1);
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut} ...
                           {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                     otherwise
                        fprintf('WARNING: Float #%d: Configuration parameter (*%s) not managed yet for decoderId #%d\n', ...
                           g_decArgo_floatNum, ...
                           finalConfigName{idConfParam}(idFUs(end)+1:end), ...
                           a_decoderId);
                  end
                  
               elseif (strcmp(finalConfigName{idConfParam}(1:idFUs(2)-1), 'CONFIG_MEASURE'))
                  
                  switch (finalConfigName{idConfParam}(idFUs(end)+1:end))
                     case 'NumberOfSamples'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_MEASURE01') == 1);
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut}]);
                     case 'TimeInterval'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_MEASURE02') == 1);
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut}]);
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
               fprintf('ERROR: Float #%d: Cannot convert configuration param name :''%s'' into NetCDF one\n', ...
                  g_decArgo_floatNum, ...
                  finalConfigName{idConfParam});
            end
         else
            % some of the managed parameters are not saved in the meta.nc file
            idDel = [idDel; idConfParam];
            fprintf('ERROR: Float #%d: Cannot convert configuration param name :''%s'' into NetCDF one\n', ...
               g_decArgo_floatNum, ...
               finalConfigName{idConfParam});
         end
      end
   end
   finalConfigName(idDel) = [];
   finalConfigValue(idDel, :) = [];
end

% output data
o_ncConfig.NUMBER = finalConfigNum;
o_ncConfig.NAMES = finalConfigName;
o_ncConfig.VALUES = finalConfigValue;

return
