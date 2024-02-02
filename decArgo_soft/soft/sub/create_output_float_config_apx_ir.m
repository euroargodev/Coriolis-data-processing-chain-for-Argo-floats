% ------------------------------------------------------------------------------
% Create the final configuration that will be used in the meta.nc file.
%
% SYNTAX :
%  [o_ncConfig] = create_output_float_config_apx_ir( ...
%    a_decArgoConfParamNames, a_ncConfParamNames, a_ncConfParamIds, a_decoderId)
%
% INPUT PARAMETERS :
%    a_decArgoConfParamNames : internal configuration parameter names
%    a_ncConfParamNames      : NetCDF configuration parameter names
%    a_ncConfParamIds        : NetCDF configuration parameter Ids
%    a_decoderId             : float decoder Id
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
   a_decArgoConfParamNames, a_ncConfParamNames, a_ncConfParamIds, a_decoderId)

% output parameters initialization
o_ncConfig = [];

% float configuration
global g_decArgo_floatConfig;

% current float WMO number
global g_decArgo_floatNum;

% lists of managed decoders
global g_decArgo_decoderIdListApexApf11Iridium;

% sensor list
global g_decArgo_sensorMountedOnFloat;


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
if (ismember(a_decoderId, g_decArgo_decoderIdListApexApf11Iridium))
   
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
         strcmp(finalConfigName, 'CONFIG_IDC_IceDescentCycles') | ...
         strcmp(finalConfigName, 'CONFIG_IDP_IceDetectionMaxPres') | ...
         strcmp(finalConfigName, 'CONFIG_IEP_IceEvasionPressure') | ...
         strcmp(finalConfigName, 'CONFIG_ICEM_IceDetectionMask') | ...
         strcmp(finalConfigName, 'CONFIG_TSD_IceTelemetryStartDay') | ...
         strcmp(finalConfigName, 'CONFIG_TED_IceTelemetryEndDay') | ...
         strcmp(finalConfigName, 'CONFIG_TT_IceTelemetryTimeout') ...
         );
      finalConfigName(idDel) = [];
      finalConfigValue(idDel, :) = [];
   end
   
   % merge PT and PTS SAMPLE configurations (see 3901667 #18 and #19)
   % if SAMPE PT and PTS configurations are simultaneously present this will
   % cause duplicates in configuration labels (because both reported with 'Ctd')
   [finalConfigName, finalConfigValue] = merge_pt_pts_config(finalConfigName, finalConfigValue);

   % link between sensor names (to create Argo names from float ones)
   floatToNcSensorList = [ ...
      {'PT'} {'Ctd'}; ...
      {'PTS'} {'Ctd'}; ...
      {'CTD'} {'Ctd'}; ...
      {'PTSH'} {'Sfet'}; ...
      {'PH'} {'Sfet'}; ...
      {'OPT'} {'Optode'}; ...
      {'FLBB'} {'Eco'}; ...
      {'IRAD'} {'Ocr'}; ...
      {'RAFOS'} {''}; ...
      {'IRAD'} {'Ram'}; ...
   ];
end

% convert decoder names into NetCDF ones
if (~isempty(a_decArgoConfParamNames))
   
   idDel = [];
   finalConfigId = cell(size(finalConfigName));
   for idConfParam = 1:length(finalConfigName)
      finalConfigNameShort = finalConfigName{idConfParam};
      if (~strncmp(finalConfigNameShort, 'CONFIG_PX_', length('CONFIG_PX_')))
         idFUs = strfind(finalConfigNameShort, '_');
         finalConfigNameShort = finalConfigNameShort(1:idFUs(2)-1);
      end
      idF = find(strcmp(finalConfigNameShort, a_decArgoConfParamNames));
      if (~isempty(idF))
         finalConfigName{idConfParam} = a_ncConfParamNames{idF};
         finalConfigId{idConfParam} = a_ncConfParamIds{idF};
      else
         
         % Apex APF11 floats
         if (ismember(a_decoderId, g_decArgo_decoderIdListApexApf11Iridium))
            if (ismember(finalConfigName{idConfParam}(1:idFUs(2)-1), ...
                  ['CONFIG_SAMPLE' 'CONFIG_PROFILE' 'CONFIG_MEASURE' 'CONFIG_LISTEN' 'CONFIG_POWER']))

               % retrieve phase name
               if (~isempty(strfind(finalConfigName{idConfParam}, '_ICEDESCENT_')))
                  phaseName = 'IceDescentPhase';
               elseif (~isempty(strfind(finalConfigName{idConfParam}, '_PARK_')))
                  phaseName = 'ParkDriftPhase';
               elseif (~isempty(strfind(finalConfigName{idConfParam}, '_ASCENT_')))
                  phaseName = 'AscentPhase';
               elseif (~isempty(strfind(finalConfigName{idConfParam}, '_ICEASCENT_')))
                  phaseName = 'IceAscentPhase';
               elseif (~isempty(strfind(finalConfigName{idConfParam}, '_SURFACE_')))
                  phaseName = 'SurfaceDriftPhase';
               else
                  fprintf('ERROR: Float #%d: Cannot find phase name associated to ''%s''\n', ...
                     g_decArgo_floatNum, ...
                     finalConfigName{idConfParam});
                  continue
               end
               
               % retrieve sensor name
               sensorNameOut = '';
               sensorNameIn = finalConfigName{idConfParam}(idFUs(3)+1:idFUs(4)-1);
               idS = find(strcmp(sensorNameIn, floatToNcSensorList(:, 1)));
               if (~isempty(idS))
                  if (length(idS) > 1)
                     if (strcmp(sensorNameIn, 'IRAD'))
                        if (any(strcmp(g_decArgo_sensorMountedOnFloat, 'OCR')))
                           sensorNameOut = 'Ocr';
                        elseif (any(strcmp(g_decArgo_sensorMountedOnFloat, 'RAMSES')))
                           sensorNameOut = 'AUX_Ram';
                        end
                     end
                  else
                     sensorNameOut = floatToNcSensorList{idS, 2};
                  end
               end
               if (isempty(sensorNameOut))
                  if (~strcmp(sensorNameIn, 'RAFOS'))
                     fprintf('ERROR: Float #%d: Cannot find sensor name associated to ''%s''\n', ...
                        g_decArgo_floatNum, ...
                        sensorNameIn);
                     continue
                  end
               end
               
               if (strcmp(finalConfigName{idConfParam}(1:idFUs(2)-1), 'CONFIG_SAMPLE'))
                  
                  if (~ismember(phaseName, [{'IceDescentPhase'} {'IceAscentPhase'}]))

                     switch (finalConfigName{idConfParam}(idFUs(end)+1:end))
                        case 'NumberOfZones'
                           idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE01'));
                           finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                              [{'<short_sensor_name>'} {sensorNameOut} ...
                              {'<cycle_phase_name>'} {phaseName}]);
                           finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                        case 'StartPressure'
                           idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE02'));
                           finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                              [{'<short_sensor_name>'} {sensorNameOut} ...
                              {'<cycle_phase_name>'} {phaseName} ...
                              {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                           finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                        case 'StopPressure'
                           idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE03'));
                           finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                              [{'<short_sensor_name>'} {sensorNameOut} ...
                              {'<cycle_phase_name>'} {phaseName} ...
                              {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                           finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                        case 'DepthInterval'
                           if (~any(finalConfigValue(idConfParam, :) == 0))
                              idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE04'));
                              finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                                 [{'<short_sensor_name>'} {sensorNameOut} ...
                                 {'<cycle_phase_name>'} {phaseName} ...
                                 {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                              finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                           else
                              if (~ismember(phaseName, [{'ParkDriftPhase'} {'SurfaceDriftPhase'}]))
                                 % retrieve CONFIG_PressureCheckTimeAscent_seconds information
                                 idF3 = find(strcmp(finalConfigName, 'CONFIG_PressureCheckTimeAscent_seconds'));
                                 finalConfigValue(idConfParam, :) = finalConfigValue(idF3, :);
                                 idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE05'));
                                 finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                                    [{'<short_sensor_name>'} {sensorNameOut} ...
                                    {'<cycle_phase_name>'} {phaseName} ...
                                    {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                                 finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                              else
                                 % retrieve CONFIG_PressureCheckTimeParking_seconds information
                                 idF3 = find(strcmp(finalConfigName, 'CONFIG_PressureCheckTimeParking_seconds'));
                                 finalConfigValue(idConfParam, :) = finalConfigValue(idF3, :);
                                 idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE05'));
                                 finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                                    [{'<short_sensor_name>'} {sensorNameOut} ...
                                    {'<cycle_phase_name>'} {phaseName} ...
                                    {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                                 finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                              end
                           end
                        case 'TimeInterval'
                           idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE05'));
                           finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                              [{'<short_sensor_name>'} {sensorNameOut} ...
                              {'<cycle_phase_name>'} {phaseName} ...
                              {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                           finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                        case 'NumberOfSamples'
                           idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE06'));
                           finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                              [{'<short_sensor_name>'} {sensorNameOut} ...
                              {'<cycle_phase_name>'} {phaseName} ...
                              {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                           finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                        otherwise
                           fprintf('WARNING: Float #%d: Configuration parameter (*%s) not managed yet for decoderId #%d\n', ...
                              g_decArgo_floatNum, ...
                              finalConfigName{idConfParam}(idFUs(end)+1:end), ...
                              a_decoderId);
                     end
                  else

                     switch (finalConfigName{idConfParam}(idFUs(end)+1:end))
                        case 'NumberOfZones'
                           idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE001'));
                           finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                              [{'<short_sensor_name>'} {sensorNameOut} ...
                              {'<cycle_phase_name>'} {phaseName}]);
                           finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                        case 'StartPressure'
                           idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE002'));
                           finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                              [{'<short_sensor_name>'} {sensorNameOut} ...
                              {'<cycle_phase_name>'} {phaseName} ...
                              {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                           finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                        case 'StopPressure'
                           idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE003'));
                           finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                              [{'<short_sensor_name>'} {sensorNameOut} ...
                              {'<cycle_phase_name>'} {phaseName} ...
                              {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                           finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                        case 'DepthInterval'
                           if (~any(finalConfigValue(idConfParam, :) == 0))
                              idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE004'));
                              finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                                 [{'<short_sensor_name>'} {sensorNameOut} ...
                                 {'<cycle_phase_name>'} {phaseName} ...
                                 {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                              finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                           else
                              % retrieve CONFIG_PressureCheckTimeAscent_seconds information
                              idF3 = find(strcmp(finalConfigName, 'CONFIG_PressureCheckTimeAscent_seconds'));
                              finalConfigValue(idConfParam, :) = finalConfigValue(idF3, :);
                              idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE005'));
                              finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                                 [{'<short_sensor_name>'} {sensorNameOut} ...
                                 {'<cycle_phase_name>'} {phaseName} ...
                                 {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                              finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                           end
                        case 'TimeInterval'
                           idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE005'));
                           finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                              [{'<short_sensor_name>'} {sensorNameOut} ...
                              {'<cycle_phase_name>'} {phaseName} ...
                              {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                           finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                        case 'NumberOfSamples'
                           idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_SAMPLE006'));
                           finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                              [{'<short_sensor_name>'} {sensorNameOut} ...
                              {'<cycle_phase_name>'} {phaseName} ...
                              {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                           finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                        otherwise
                           fprintf('WARNING: Float #%d: Configuration parameter (*%s) not managed yet for decoderId #%d\n', ...
                              g_decArgo_floatNum, ...
                              finalConfigName{idConfParam}(idFUs(end)+1:end), ...
                              a_decoderId);
                     end                     
                  end
                  
               elseif (strcmp(finalConfigName{idConfParam}(1:idFUs(2)-1), 'CONFIG_PROFILE'))
                  
                  switch (finalConfigName{idConfParam}(idFUs(end)+1:end))
                     case 'NumberOfZones'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_PROFILE01'));
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut}]);
                        finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                     case 'StartPressure'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_PROFILE02'));
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut} ...
                           {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                        finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                     case 'StopPressure'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_PROFILE03'));
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut} ...
                           {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                        finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                     case 'BinSize'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_PROFILE04'));
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut} ...
                           {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                        finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                     case 'SampleRate'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_PROFILE05'));
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut} ...
                           {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                        finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                     case 'TimeInterval'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_PROFILE06'));
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut} ...
                           {'<N>'} {num2str(finalConfigName{idConfParam}(idFUs(4)+1:idFUs(5)-1))}]);
                        finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                     otherwise
                        fprintf('WARNING: Float #%d: Configuration parameter (*%s) not managed yet for decoderId #%d\n', ...
                           g_decArgo_floatNum, ...
                           finalConfigName{idConfParam}(idFUs(end)+1:end), ...
                           a_decoderId);
                  end
                  
               elseif (strcmp(finalConfigName{idConfParam}(1:idFUs(2)-1), 'CONFIG_MEASURE'))
                  
                  switch (finalConfigName{idConfParam}(idFUs(end)+1:end))
                     case 'NumberOfSamples'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_MEASURE01'));
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut}]);
                        finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                     case 'TimeInterval'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_MEASURE02'));
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut}]);
                        finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                     otherwise
                        fprintf('WARNING: Float #%d: Configuration parameter (*%s) not managed yet for decoderId #%d\n', ...
                           g_decArgo_floatNum, ...
                           finalConfigName{idConfParam}(idFUs(end)+1:end), ...
                           a_decoderId);
                  end
                  
               elseif (strcmp(finalConfigName{idConfParam}(1:idFUs(2)-1), 'CONFIG_LISTEN'))
                  
                  switch (finalConfigName{idConfParam}(idFUs(end)+1:end))
                     case 'StartDayTime'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_LISTEN_START'));
                        finalConfigName{idConfParam} = a_ncConfParamNames{idF2};
                        finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                     case 'Duration'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_LISTEN_DURATION'));
                        finalConfigName{idConfParam} = a_ncConfParamNames{idF2};
                        finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                     otherwise
                        fprintf('WARNING: Float #%d: Configuration parameter (*%s) not managed yet for decoderId #%d\n', ...
                           g_decArgo_floatNum, ...
                           finalConfigName{idConfParam}(idFUs(end)+1:end), ...
                           a_decoderId);
                  end
                  
               elseif (strcmp(finalConfigName{idConfParam}(1:idFUs(2)-1), 'CONFIG_POWER'))
                  
                  switch (finalConfigName{idConfParam}(idFUs(end)+1:end))
                     case 'StartPressure'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_POWER_START'));
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut} ...
                           {'<cycle_phase_name>'} {phaseName}]);
                        finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
                     case 'StopPressure'
                        idF2 = find(strcmp(a_decArgoConfParamNames, 'CONFIG_POWER_STOP'));
                        finalConfigName{idConfParam} = create_param_name_ir_rudics_sbd2(a_ncConfParamNames{idF2}, ...
                           [{'<short_sensor_name>'} {sensorNameOut} ...
                           {'<cycle_phase_name>'} {phaseName}]);
                        finalConfigId{idConfParam} = a_ncConfParamIds{idF2};
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
   finalConfigId(idDel) = [];
   finalConfigValue(idDel, :) = [];
end

% output data
o_ncConfig.NUMBER = finalConfigNum;
o_ncConfig.NAMES = finalConfigName;
o_ncConfig.IDS = finalConfigId;
o_ncConfig.VALUES = finalConfigValue;

return

% ------------------------------------------------------------------------------
% Merge duplicated PT and PTS SAMPLE configurations.
%
% SYNTAX :
%  [o_configName, o_configValue] = merge_pt_pts_config(a_configName, a_configValue)
%
% INPUT PARAMETERS :
%    a_configName  : input configuration names
%    a_configValue : input configuration values
%
% OUTPUT PARAMETERS :
%    o_configName  : output configuration names
%    o_configValue : output configuration values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/06/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configName, o_configValue] = merge_pt_pts_config(a_configName, a_configValue)

% output parameters initialization
o_configName = a_configName;
o_configValue = a_configValue;

% current float WMO number
global g_decArgo_floatNum;


% we have previously checked that all configuration names have at least 13
% characters
idF1 = find(cellfun(@(x) strcmp(x(end-12:end), 'NumberOfZones') & strcmp(x(1:13), 'CONFIG_SAMPLE'), o_configName));
if (~isempty(idF1))
   idF2 = find(cellfun(@(x) strcmp(x(end-16:end), '_PT_NumberOfZones'), o_configName(idF1)));
   if (~isempty(idF2))

      % look for duplicated configuration and store the sample phase
      duplicateList = [];
      for id = idF2'
         label = o_configName{idF1(id)};
         label = regexprep(label, '_PT_', '_PTS_');
         idF2 = find(cellfun(@(x) strcmp(x, label), o_configName(idF1)));
         if (~isempty(idF2))
            duplicateList{end+1} = label;
         end
      end

      % merge the configurations for each duplicated sample phase
      for id = 1:length(duplicateList)
         label = duplicateList{id};
         idF3 = strfind(label, '_PTS_');
         baseName = label(1:idF3-1);
         ptsNZ = a_configValue(strcmp(duplicateList{id}, o_configName), :);
         ptNZ = a_configValue(strcmp([baseName '_PT_NumberOfZones'], o_configName), :);
         ptsConfig = nan(4*max([ptsNZ ptNZ])+1, size(a_configValue, 2));

         idDel = [];

         % initialize new configuration with PTS configuration
         label = [baseName '_PTS_NumberOfZones'];
         idD = find(strcmp(label, o_configName));
         idDel = [idDel idD];
         ptsConfig(1, :) = a_configValue(idD, :);
         for idZ = 1:max(ptsNZ)
            label = [baseName '_PTS_' num2str(idZ) '_StartPressure'];
            idD = find(strcmp(label, o_configName));
            idDel = [idDel idD];
            ptsConfig(idZ+1+(idZ-1)*3, :) = a_configValue(idD, :);

            label = [baseName '_PTS_' num2str(idZ) '_StopPressure'];
            idD = find(strcmp(label, o_configName));
            idDel = [idDel idD];
            ptsConfig(idZ+2+(idZ-1)*3, :) = a_configValue(idD, :);

            label = [baseName '_PTS_' num2str(idZ) '_DepthInterval'];
            idD = find(strcmp(label, o_configName));
            idDel = [idDel idD];
            ptsConfig(idZ+3+(idZ-1)*3, :) = a_configValue(idD, :);

            label = [baseName '_PTS_' num2str(idZ) '_NumberOfSamples'];
            idD = find(strcmp(label, o_configName));
            idDel = [idDel idD];
            ptsConfig(idZ+4+(idZ-1)*3, :) = a_configValue(idD, :);
         end

         % add PT configuration
         label = [baseName '_PT_NumberOfZones'];
         idD = find(strcmp(label, o_configName));
         idDel = [idDel idD];
         ptNbZone = a_configValue(idD, :);
         idNoNan = find(~isnan(ptsConfig(1, :)) & ~isnan(ptNbZone));
         if (any(ptsConfig(1, idNoNan) ~= ptNbZone(idNoNan)))
            fprintf('ERROR: Float #%d: PTS and PT configuration are not consistent - PTS used in merged configuration\n', ...
               g_decArgo_floatNum);
         end
         idGo = find(isnan(ptsConfig(1, :)) & ~isnan(ptNbZone));
         ptsConfig(1, idGo) = ptNbZone(idGo);
         for idZ = 1:max(ptNZ)
            label = [baseName '_PT_' num2str(idZ) '_StartPressure'];
            idD = find(strcmp(label, o_configName));
            idDel = [idDel idD];
            ptStartPres = a_configValue(idD, :);
            idNoNan = find(~isnan(ptsConfig(idZ+1+(idZ-1)*3, :)) & ~isnan(ptStartPres));
            if (any(ptsConfig(idZ+1+(idZ-1)*3, idNoNan) ~= ptStartPres(idNoNan)))
               fprintf('ERROR: Float #%d: PTS and PT configuration are not consistent - PTS used in merged configuration\n', ...
                  g_decArgo_floatNum);
            end
            idGo = find(isnan(ptsConfig(idZ+1+(idZ-1)*3, :)) & ~isnan(ptStartPres));
            ptsConfig(idZ+1+(idZ-1)*3, idGo) = ptStartPres(idGo);

            label = [baseName '_PT_' num2str(idZ) '_StopPressure'];
            idD = find(strcmp(label, o_configName));
            idDel = [idDel idD];
            ptStopPres = a_configValue(idD, :);
            idNoNan = find(~isnan(ptsConfig(idZ+2+(idZ-1)*3, :)) & ~isnan(ptStopPres));
            if (any(ptsConfig(idZ+2+(idZ-1)*3, idNoNan) ~= ptStopPres(idNoNan)))
               fprintf('ERROR: Float #%d: PTS and PT configuration are not consistent - PTS used in merged configuration\n', ...
                  g_decArgo_floatNum);
            end
            idGo = find(isnan(ptsConfig(idZ+2+(idZ-1)*3, :)) & ~isnan(ptStopPres));
            ptsConfig(idZ+2+(idZ-1)*3, idGo) = ptStopPres(idGo);

            label = [baseName '_PT_' num2str(idZ) '_DepthInterval'];
            idD = find(strcmp(label, o_configName));
            idDel = [idDel idD];
            ptDepthInt = a_configValue(idD, :);
            idNoNan = find(~isnan(ptsConfig(idZ+3+(idZ-1)*3, :)) & ~isnan(ptDepthInt));
            if (any(ptsConfig(idZ+3+(idZ-1)*3, idNoNan) ~= ptDepthInt(idNoNan)))
               fprintf('ERROR: Float #%d: PTS and PT configuration are not consistent - PTS used in merged configuration\n', ...
                  g_decArgo_floatNum);
            end
            idGo = find(isnan(ptsConfig(idZ+3+(idZ-1)*3, :)) & ~isnan(ptDepthInt));
            ptsConfig(idZ+3+(idZ-1)*3, idGo) = ptDepthInt(idGo);

            label = [baseName '_PT_' num2str(idZ) '_NumberOfSamples'];
            idD = find(strcmp(label, o_configName));
            idDel = [idDel idD];
            ptNumOfSamp = a_configValue(idD, :);
            idNoNan = find(~isnan(ptsConfig(idZ+4+(idZ-1)*3, :)) & ~isnan(ptNumOfSamp));
            if (any(ptsConfig(idZ+4+(idZ-1)*3, idNoNan) ~= ptNumOfSamp(idNoNan)))
               fprintf('ERROR: Float #%d: PTS and PT configuration are not consistent - PTS used in merged configuration\n', ...
                  g_decArgo_floatNum);
            end
            idGo = find(isnan(ptsConfig(idZ+4+(idZ-1)*3, :)) & ~isnan(ptNumOfSamp));
            ptsConfig(idZ+4+(idZ-1)*3, idGo) = ptNumOfSamp(idGo);
         end

         % remove existing configurations
         o_configName(idDel) = [];
         o_configValue(idDel, :) = [];

         % store new configuration labels
         newConfigName = cell(size(ptsConfig, 1), 1);
         newConfigName{1} = [baseName '_PTS_NumberOfZones'];
         for idZ = 1:(size(ptsConfig, 1)-1)/4
            label = [baseName '_PTS_' num2str(idZ) '_StartPressure'];
            newConfigName{idZ+1+(idZ-1)*3} = label;

            label = [baseName '_PTS_' num2str(idZ) '_StopPressure'];
            newConfigName{idZ+2+(idZ-1)*3} = label;

            label = [baseName '_PTS_' num2str(idZ) '_DepthInterval'];
            newConfigName{idZ+3+(idZ-1)*3} = label;

            label = [baseName '_PTS_' num2str(idZ) '_NumberOfSamples'];
            newConfigName{idZ+4+(idZ-1)*3} = label;
         end

         % add new configuration
         o_configName = cat(1, o_configName, newConfigName);
         o_configValue = cat(1, o_configValue, ptsConfig);
      end
   end
end

return
