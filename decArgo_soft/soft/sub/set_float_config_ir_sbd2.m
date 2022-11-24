% ------------------------------------------------------------------------------
% Set the float configuration used to process the data of given profiles.
%
% SYNTAX :
%  set_float_config_ir_sbd2(a_cyProfPhaseList, a_floatSoftVersion, a_decoderId)
%
% INPUT PARAMETERS :
%   a_cyProfPhaseList  : list of cycle and profiles associated to that
%                        configuration
%   a_floatSoftVersion : version of the float's software
%   a_decoderId        : float decoder Id
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function set_float_config_ir_sbd2(a_cyProfPhaseList, a_floatSoftVersion, a_decoderId)

% current float WMO number
global g_decArgo_floatNum;

% float configuration
global g_decArgo_floatConfig;

% no sampled data mode
global g_decArgo_noDataFlag;


switch (a_decoderId)
   
   case {301}
      
      % update the configuration if data packets has been received or if no data has
      % been sampled
      if (~isempty(a_cyProfPhaseList))
         idData = find(a_cyProfPhaseList(:, 1) == 0);
         if ((~isempty(idData)) || (g_decArgo_noDataFlag == 1))
            
            % retrieve the configuration of the previous profile
            configNames = g_decArgo_floatConfig.DYNAMIC.NAMES;
            if (~isempty(g_decArgo_floatConfig.USE.CONFIG))
               idConf = find(g_decArgo_floatConfig.DYNAMIC.NUMBER == g_decArgo_floatConfig.USE.CONFIG(end));
            else
               idConf = 1;
            end
            currentConfig = g_decArgo_floatConfig.DYNAMIC.VALUES(:, idConf);
            
            % update the current configuration
            tmpConfNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
            tmpConfValues = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, end);
            
            % update the configuration for all the concerned cycles and profiles
            % (in a nominal case, by construction, there is generally only one cycle,
            % however sometimes one SBD of a given cycle contains data of other cycles
            % due to float dysfunctioning ? ...)
            if (~isempty(idData))
               uCy = sort(unique(a_cyProfPhaseList(idData, 3)));
               uProf = sort(unique(a_cyProfPhaseList(idData, 4)));
            else
               id253 = find(a_cyProfPhaseList(:, 1) == 253);
               uCy = sort(unique(a_cyProfPhaseList(id253, 3)));
               uProf = sort(unique(a_cyProfPhaseList(id253, 4)));
            end
            
            % from 2902087 cycle #38 prof #0 it seems that the 254 and 255 message
            % types are immediately taken into account
            % (question asked to NKE on 19/11/2014, still waiting answer)
            updateNowPtPvPm = 1;
            
            %       % in the first versions of the float's software, 254 and 255 message types
            %       % are immediately taken into account whereas in the following versions,
            %       % they are considered only the next cycle
            %       updateNowPtPvPm = 0;
            %       if (a_floatSoftVersion == -1)
            %          fprintf('WARNING: Float #%d: float software version is unknown => 254 and 255 message types are considered the next cycle\n', ...
            %             g_decArgo_floatNum);
            %          if (~isempty(find(uProf == 0, 1)))
            %             updateNowPtPvPm = 1;
            %          end
            %       elseif (a_floatSoftVersion < 1.06)
            %          updateNowPtPvPm = 1;
            %       else
            %          if (~isempty(find(uProf == 0, 1)))
            %             updateNowPtPvPm = 1;
            %          end
            %       end
            
            for idC = 1:length(uCy)
               cyNum = uCy(idC);
               for idP = 1:length(uProf)
                  profNum = uProf(idP);
                  
                  if (~isempty(find((a_cyProfPhaseList(:, 3) == cyNum) & ...
                        (a_cyProfPhaseList(:, 4) == profNum), 1)))
                     
                     % update the current configuration
                     for id = 1:length(tmpConfNames)
                        configName = tmpConfNames{id};
                        if (isempty(strfind(configName, 'CONFIG_PC_')))
                           if (updateNowPtPvPm == 0)
                              continue
                           end
                        end
                        idPos = find(strcmp(configName, configNames) == 1, 1);
                        if (~isempty(idPos))
                           currentConfig(idPos) = tmpConfValues(id);
                        end
                     end
                     
                     % for PM parameters, duplicate the information of the concerned
                     % profile in the PM03 to PM07 parameters
                     for id = 1:5
                        configName = sprintf('CONFIG_PM_%d', 3+(id-1)+profNum*5);
                        idL1 = find(strcmp(configName, configNames) == 1, 1);
                        configName = sprintf('CONFIG_PM_%02d', 3+(id-1));
                        idL2 = find(strcmp(configName, configNames) == 1, 1);
                        currentConfig(idL2) = currentConfig(idL1);
                     end
                     
                     % fill the CONFIG_PV_03 parameter
                     idF1 = find(strcmp('CONFIG_PV_0', configNames) == 1, 1);
                     if (~isnan(currentConfig(idF1)))
                        idFPV03 = find(strcmp('CONFIG_PV_03', configNames) == 1, 1);
                        if (currentConfig(idF1) == 1)
                           idF2 = find(strcmp('CONFIG_PV_3', configNames) == 1, 1);
                           currentConfig(idFPV03) = currentConfig(idF2);
                        else
                           for idCP = 1:currentConfig(idF1)
                              confName = sprintf('CONFIG_PV_%d', 4+(idCP-1)*4);
                              idFDay = find(strcmp(confName, configNames) == 1, 1);
                              day = currentConfig(idFDay);
                              
                              confName = sprintf('CONFIG_PV_%d', 5+(idCP-1)*4);
                              idFMonth = find(strcmp(confName, configNames) == 1, 1);
                              month = currentConfig(idFMonth);
                              
                              confName = sprintf('CONFIG_PV_%d', 6+(idCP-1)*4);
                              idFyear = find(strcmp(confName, configNames) == 1, 1);
                              year = currentConfig(idFyear);
                              
                              if ~((day == 31) && (month == 12) && (year == 99))
                                 pvDate = gregorian_2_julian_dec_argo( ...
                                    sprintf('20%02d/%02d/%02d 00:00:00', year, month, day));
                                 if (tmpConfDate < pvDate)
                                    confName = sprintf('CONFIG_PV_%d', 3+(idCP-1)*4);
                                    idFCyclePeriod = find(strcmp(confName, configNames) == 1, 1);
                                    currentConfig(idFPV03) = currentConfig(idFCyclePeriod);
                                    break
                                 end
                              else
                                 confName = sprintf('CONFIG_PV_%d', 3+(idCP-1)*4);
                                 idFCyclePeriod = find(strcmp(confName, configNames) == 1, 1);
                                 currentConfig(idFPV03) = currentConfig(idFCyclePeriod);
                                 break
                              end
                           end
                        end
                     end
                     
                     % fill the CONFIG_PC_0_1_12 parameter
                     idPC0112 = find(strcmp('CONFIG_PC_0_1_12', configNames) == 1, 1);
                     if (~isempty(idPC0112))
                        idPC013 = find(strcmp('CONFIG_PC_0_1_3', configNames) == 1, 1);
                        if (~isempty(idPC013))
                           
                           configPC013 = currentConfig(idPC013);
                           currentConfig(idPC0112) = configPC013 + 0.5;
                        end
                     end
                     
                     % look for the current configurations in existing ones
                     [configNum] = config_exists_ir_rudics_sbd2( ...
                        currentConfig, ...
                        g_decArgo_floatConfig.DYNAMIC.NUMBER, ...
                        g_decArgo_floatConfig.DYNAMIC.VALUES, ...
                        g_decArgo_floatConfig.DYNAMIC.IGNORED_ID);
                     
                     % if configNum == -1 the new configuration doesn't exist
                     % if configNum == 0 the new configuration is identical to launch
                     % configuration, we create a new one however so that the launch
                     % configuration should never be referenced in the prof and traj
                     % data
                     
                     % anomaly-managment: check if a config already exists for this
                     % cycle and profile
                     idUsedConf = find((g_decArgo_floatConfig.USE.CYCLE == cyNum) & ...
                        (g_decArgo_floatConfig.USE.PROFILE == profNum));
                     
                     if (~isempty(idUsedConf))
                        
                        fprintf('WARNING: Float #%d: config already exists for cycle #%d and profile #%d => updating the current one\n', ...
                           g_decArgo_floatNum, cyNum, profNum);
                        
                        if ((configNum == -1) || (configNum == 0))
                           idConf = find(g_decArgo_floatConfig.DYNAMIC.NUMBER == ...
                              g_decArgo_floatConfig.USE.CONFIG(idUsedConf));
                           g_decArgo_floatConfig.DYNAMIC.VALUES(:, idConf) = currentConfig;
                        else
                           g_decArgo_floatConfig.USE.CONFIG(idUsedConf) = configNum;
                        end
                        
                     else
                        
                        % nominal case
                        if ((configNum == -1) || (configNum == 0))
                           
                           % create a new config
                           
                           g_decArgo_floatConfig.DYNAMIC.NUMBER(end+1) = ...
                              max(g_decArgo_floatConfig.DYNAMIC.NUMBER) + 1;
                           g_decArgo_floatConfig.DYNAMIC.VALUES(:, end+1) = currentConfig;
                           configNum = g_decArgo_floatConfig.DYNAMIC.NUMBER(end);
                        end
                        
                        % assign the config to the cycle and profile
                        g_decArgo_floatConfig.USE.CYCLE(end+1) = cyNum;
                        g_decArgo_floatConfig.USE.PROFILE(end+1) = profNum;
                        g_decArgo_floatConfig.USE.CYCLE_OUT(end+1) = -1;
                        g_decArgo_floatConfig.USE.CONFIG(end+1) = configNum;
                     end
                  end
               end
            end
            
%             create_csv_to_print_config_ir_rudics_sbd2('setConfig_', 1, g_decArgo_floatConfig);
         end
      end
      
   case {302, 303}
      
      % update the configuration if data packets has been received or if no data has
      % been sampled
      if (~isempty(a_cyProfPhaseList))
         idData = find(a_cyProfPhaseList(:, 1) == 0);
         if ((~isempty(idData)) || (g_decArgo_noDataFlag == 1))
            
            % retrieve the configuration of the previous profile
            configNames = g_decArgo_floatConfig.DYNAMIC.NAMES;
            if (~isempty(g_decArgo_floatConfig.USE.CONFIG))
               idConf = find(g_decArgo_floatConfig.DYNAMIC.NUMBER == g_decArgo_floatConfig.USE.CONFIG(end));
            else
               idConf = 1;
            end
            currentConfig = g_decArgo_floatConfig.DYNAMIC.VALUES(:, idConf);
            
            % update the current configuration
            tmpConfNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
            tmpConfValues = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, end);
            
            % update the configuration for all the concerned cycles and profiles
            % (in a nominal case, by construction, there is generally only one cycle,
            % however sometimes one SBD of a given cycle contains data of other cycles
            % due to float dysfunctioning ? ...)
            if (~isempty(idData))
               uCy = sort(unique(a_cyProfPhaseList(idData, 3)));
               uProf = sort(unique(a_cyProfPhaseList(idData, 4)));
            else
               id253 = find(a_cyProfPhaseList(:, 1) == 253);
               uCy = sort(unique(a_cyProfPhaseList(id253, 3)));
               uProf = sort(unique(a_cyProfPhaseList(id253, 4)));
            end
            
            % in the first versions of the float's software, 254 and 255 message types
            % are immediately taken into account whereas in the following versions,
            % they are considered only the next cycle
            updateNowPtPvPm = 0;
            if (a_floatSoftVersion == -1)
               fprintf('DEC_WARNING: Float #%d: float software version is unknown => 254 and 255 message types are considered the next cycle\n', ...
                  g_decArgo_floatNum);
               if (~isempty(find(uProf == 0, 1)))
                  updateNowPtPvPm = 1;
               end
            elseif (a_floatSoftVersion < 1.06)
               updateNowPtPvPm = 1;
            else
               if (~isempty(find(uProf == 0, 1)))
                  updateNowPtPvPm = 1;
               end
            end
            
            for idC = 1:length(uCy)
               cyNum = uCy(idC);
               for idP = 1:length(uProf)
                  profNum = uProf(idP);
                  
                  if (~isempty(find((a_cyProfPhaseList(:, 3) == cyNum) & ...
                        (a_cyProfPhaseList(:, 4) == profNum), 1)))
                     
                     % update the current configuration
                     for id = 1:length(tmpConfNames)
                        configName = tmpConfNames{id};
                        if (isempty(strfind(configName, 'CONFIG_PC_')))
                           if (updateNowPtPvPm == 0)
                              continue
                           end
                        end
                        idPos = find(strcmp(configName, configNames) == 1, 1);
                        if (~isempty(idPos))
                           currentConfig(idPos) = tmpConfValues(id);
                        end
                     end
                     
                     % for PM parameters, duplicate the information of the concerned
                     % profile in the PM03 to PM07 parameters
                     for id = 1:5
                        configName = sprintf('CONFIG_PM_%d', 3+(id-1)+profNum*5);
                        idL1 = find(strcmp(configName, configNames) == 1, 1);
                        configName = sprintf('CONFIG_PM_%02d', 3+(id-1));
                        idL2 = find(strcmp(configName, configNames) == 1, 1);
                        currentConfig(idL2) = currentConfig(idL1);
                     end
                     
                     % fill the CONFIG_PV_03 parameter
                     idF1 = find(strcmp('CONFIG_PV_0', configNames) == 1, 1);
                     if (~isnan(currentConfig(idF1)))
                        idFPV03 = find(strcmp('CONFIG_PV_03', configNames) == 1, 1);
                        if (currentConfig(idF1) == 1)
                           idF2 = find(strcmp('CONFIG_PV_3', configNames) == 1, 1);
                           currentConfig(idFPV03) = currentConfig(idF2);
                        else
                           for idCP = 1:currentConfig(idF1)
                              confName = sprintf('CONFIG_PV_%d', 4+(idCP-1)*4);
                              idFDay = find(strcmp(confName, configNames) == 1, 1);
                              day = currentConfig(idFDay);
                              
                              confName = sprintf('CONFIG_PV_%d', 5+(idCP-1)*4);
                              idFMonth = find(strcmp(confName, configNames) == 1, 1);
                              month = currentConfig(idFMonth);
                              
                              confName = sprintf('CONFIG_PV_%d', 6+(idCP-1)*4);
                              idFyear = find(strcmp(confName, configNames) == 1, 1);
                              year = currentConfig(idFyear);
                              
                              if ~((day == 31) && (month == 12) && (year == 99))
                                 pvDate = gregorian_2_julian_dec_argo( ...
                                    sprintf('20%02d/%02d/%02d 00:00:00', year, month, day));
                                 if (tmpConfDate < pvDate)
                                    confName = sprintf('CONFIG_PV_%d', 3+(idCP-1)*4);
                                    idFCyclePeriod = find(strcmp(confName, configNames) == 1, 1);
                                    currentConfig(idFPV03) = currentConfig(idFCyclePeriod);
                                    break
                                 end
                              else
                                 confName = sprintf('CONFIG_PV_%d', 3+(idCP-1)*4);
                                 idFCyclePeriod = find(strcmp(confName, configNames) == 1, 1);
                                 currentConfig(idFPV03) = currentConfig(idFCyclePeriod);
                                 break
                              end
                           end
                        end
                     end
                     
                     % fill the CONFIG_PC_0_1_15 parameter
                     idPC0115 = find(strcmp('CONFIG_PC_0_1_15', configNames) == 1, 1);
                     if (~isempty(idPC0115))
                        idPC014 = find(strcmp('CONFIG_PC_0_1_4', configNames) == 1, 1);
                        if (~isempty(idPC014))
                           
                           configPC014 = currentConfig(idPC014);
                           
                           % retrieve the treatment type of the depth zone associated
                           % to CONFIG_PC_0_1_4 pressure value
                           
                           % find the depth zone thresholds
                           depthZoneNum = -1;
                           for id = 1:4
                              % zone threshold
                              confParamName = sprintf('CONFIG_PC_0_0_%d', 44+id);
                              idPos = find(strcmp(confParamName, configNames) == 1, 1);
                              if (~isempty(idPos))
                                 zoneThreshold = currentConfig(idPos);
                                 if (configPC014 <= zoneThreshold)
                                    depthZoneNum = id;
                                    break
                                 end
                              end
                           end
                           if (depthZoneNum == -1)
                              depthZoneNum = 5;
                           end
                           
                           % retrieve treatment type for this depth zone
                           confParamName = sprintf('CONFIG_PC_0_0_%d', 6+(depthZoneNum-1)*9);
                           idPos = find(strcmp(confParamName, configNames) == 1, 1);
                           if (~isempty(idPos))
                              treatType = currentConfig(idPos);
                              if (treatType == 0)
                                 currentConfig(idPC0115) = configPC014;
                              else
                                 currentConfig(idPC0115) = configPC014 + 0.5;
                              end
                           end
                        end
                     end
                     
                     % look for the current configurations in existing ones
                     [configNum] = config_exists_ir_rudics_sbd2( ...
                        currentConfig, ...
                        g_decArgo_floatConfig.DYNAMIC.NUMBER, ...
                        g_decArgo_floatConfig.DYNAMIC.VALUES, ...
                        g_decArgo_floatConfig.DYNAMIC.IGNORED_ID);
                     
                     % if configNum == -1 the new configuration doesn't exist
                     % if configNum == 0 the new configuration is identical to launch
                     % configuration, we create a new one however so that the launch
                     % configuration should never be referenced in the prof and traj
                     % data
                     
                     % anomaly-managment: check if a config already exists for this
                     % cycle and profile
                     idUsedConf = find((g_decArgo_floatConfig.USE.CYCLE == cyNum) & ...
                        (g_decArgo_floatConfig.USE.PROFILE == profNum));
                     
                     if (~isempty(idUsedConf))
                        
                        fprintf('WARNING: Float #%d: config already exists for cycle #%d and profile #%d => updating the current one\n', ...
                           g_decArgo_floatNum, cyNum, profNum);
                        
                        if ((configNum == -1) || (configNum == 0))
                           idConf = find(g_decArgo_floatConfig.DYNAMIC.NUMBER == ...
                              g_decArgo_floatConfig.USE.CONFIG(idUsedConf));
                           g_decArgo_floatConfig.DYNAMIC.VALUES(:, idConf) = currentConfig;
                        else
                           g_decArgo_floatConfig.USE.CONFIG(idUsedConf) = configNum;
                        end
                        
                     else
                        
                        % nominal case
                        if ((configNum == -1) || (configNum == 0))
                           
                           % create a new config
                           
                           g_decArgo_floatConfig.DYNAMIC.NUMBER(end+1) = ...
                              max(g_decArgo_floatConfig.DYNAMIC.NUMBER) + 1;
                           g_decArgo_floatConfig.DYNAMIC.VALUES(:, end+1) = currentConfig;
                           configNum = g_decArgo_floatConfig.DYNAMIC.NUMBER(end);
                        end
                        
                        % assign the config to the cycle and profile
                        g_decArgo_floatConfig.USE.CYCLE(end+1) = cyNum;
                        g_decArgo_floatConfig.USE.PROFILE(end+1) = profNum;
                        g_decArgo_floatConfig.USE.CYCLE_OUT(end+1) = -1;
                        g_decArgo_floatConfig.USE.CONFIG(end+1) = configNum;
                     end
                  end
               end
            end
            
%             create_csv_to_print_config_ir_rudics_sbd2('setConfig_', 1, g_decArgo_floatConfig);
         end
      end
   otherwise
      fprintf('WARNING: Nothing done yet in set_float_config_ir_sbd2 for decoderId #%d\n', ...
         a_decoderId);
end

return
