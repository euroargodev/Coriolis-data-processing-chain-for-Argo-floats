% ------------------------------------------------------------------------------
% Create and add the vertical sampling scheme information to the payload profiles.
%
% SYNTAX :
%  [o_tabProfiles] = add_vertical_sampling_scheme_ir_rudics_cts5_from_payload(a_tabProfiles)
%
% INPUT PARAMETERS :
%   a_tabProfiles : input profile structures
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : output profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = add_vertical_sampling_scheme_ir_rudics_cts5_from_payload(a_tabProfiles)

% output parameters initialization
o_tabProfiles = [];

% global default values
global g_decArgo_presDef;

% current cycle and pattern number
global g_decArgo_patternNumFloat;


% add the vertical sampling scheme for each profile
for idP = 1:length(a_tabProfiles)
   prof = a_tabProfiles(idP);
   
   % specific processing for SUNA split profile
   if (prof.sensorNumber == 6)
      if (any(ismember('PRES', {prof.paramList.name}) & ...
            ismember('PSAL', {prof.paramList.name}) & ...
            ismember('TEMP', {prof.paramList.name})))
         
         vssText = 'Secondary sampling: discrete [CTD measurements concurrent with SUNA measurements, just slightly offset in time]';
         a_tabProfiles(idP).vertSamplingScheme = vssText;
         continue;
      end
   end  
   
   [configNames, configValues] = get_float_config_ir_rudics_sbd2(prof.cycleNumber, prof.profileNumber);
   %    voir = cat(2, configNames, num2cell(configValues))
   if (~isempty(configNames))
      
      vssTextDescent = 'Secondary sampling:';
      vssTextSecondary = 'Secondary sampling:';
      vssTextPrimary = 'Primary sampling:';
      vssTextNearSurface = 'Near-surface sampling:';
      
      if (prof.direction == 'A')
         
         % ascending profile
         profPres = get_config_value(sprintf('CONFIG_APMT_PATTERN_%02d_P02', ...
            g_decArgo_patternNumFloat), configNames, configValues);
         
         % number of depth zones
         nbDepthZones = get_config_value(sprintf('CONFIG_PAYLOAD_USED_SENSOR_%02d_P00_VP06', ...
            prof.payloadSensorNumber), configNames, configValues);
         
         % depth zone information
         depthZoneStartPres = ones(nbDepthZones, 1)*-1;
         depthZoneStopPres = ones(nbDepthZones, 1)*-1;
         depthZoneSampPeriod = ones(nbDepthZones, 1)*-1;
         depthZoneNbSubSamp = ones(nbDepthZones, 1)*-1;
         depthZoneSubSampType = ones(nbDepthZones, 1)*-1;
         depthZoneSubSampRate = ones(nbDepthZones, 1)*-1;
         for idDz = 1:nbDepthZones
            depthZoneStartPres(idDz) = get_config_value(sprintf('CONFIG_PAYLOAD_USED_SENSOR_%02d_P01_VP06_%d', ...
               prof.payloadSensorNumber, idDz), configNames, configValues);
            depthZoneStopPres(idDz) = get_config_value(sprintf('CONFIG_PAYLOAD_USED_SENSOR_%02d_P02_VP06_%d', ...
               prof.payloadSensorNumber, idDz), configNames, configValues);
            depthZoneSampPeriod(idDz) = get_config_value(sprintf('CONFIG_PAYLOAD_USED_SENSOR_%02d_P03_VP06_%d', ...
               prof.payloadSensorNumber, idDz), configNames, configValues);
            
            depthZoneNbSubSamp(idDz) = get_config_value(sprintf('CONFIG_PAYLOAD_USED_SENSOR_%02d_P06_VP06_%d', ...
               prof.payloadSensorNumber, idDz), configNames, configValues);
            if (depthZoneNbSubSamp(idDz) == 1)
               depthZoneSubSampType(idDz) = get_config_value(sprintf('CONFIG_PAYLOAD_USED_SENSOR_%02d_P07_VP06_%d_1', ...
                  prof.payloadSensorNumber, idDz), configNames, configValues);
               depthZoneSubSampRate(idDz) = get_config_value(sprintf('CONFIG_PAYLOAD_USED_SENSOR_%02d_P08_VP06_%d_1', ...
                  prof.payloadSensorNumber, idDz), configNames, configValues);
            end
         end
         
         % sort depth zones
         [depthZoneStartPres, idSort] = sort(depthZoneStartPres, 'descend');
         depthZoneStopPres = depthZoneStopPres(idSort);
         depthZoneSampPeriod = depthZoneSampPeriod(idSort);
         depthZoneNbSubSamp = depthZoneNbSubSamp(idSort);
         depthZoneSubSampType = depthZoneSubSampType(idSort);
         depthZoneSubSampRate = depthZoneSubSampRate(idSort);
                  
         text1List = [];
         text2List = [];
         nbSecondaryFlag = 0;
         discreteSecondaryFlag = 0;
         averagedSecondaryFlag = 0;
         nbPrimaryFlag = 0;
         discretePrimaryFlag = 0;
         averagedPrimaryFlag = 0;
         nbNearSurfaceFlag = 0;
         discreteNearSurfaceFlag = 0;
         averagedNearSurfaceFlag = 0;
         for idDz = 1:nbDepthZones
            
            text1 = [];
            text2 = [];
            
            dzStartPres = depthZoneStartPres(idDz);
            dzStopPres = depthZoneStopPres(idDz);
            dzSampPeriod = depthZoneSampPeriod(idDz);
            dzNbSubSamp = depthZoneNbSubSamp(idDz);
            dzSubSampType = depthZoneSubSampType(idDz);
            dzSubSampRate = depthZoneSubSampRate(idDz);
            
            if (profPres > dzStartPres)
               
               if (prof.primarySamplingProfileFlag == 0)
                                    
                  % secondary sampling
                  [text1, ...
                     nbSecondaryFlag, discreteSecondaryFlag, averagedSecondaryFlag] = ...
                     create_text(dzStartPres, dzStopPres, dzSampPeriod, ...
                     dzNbSubSamp, dzSubSampType, dzSubSampRate, ...
                     nbSecondaryFlag, discreteSecondaryFlag, averagedSecondaryFlag);
               else
                  
                  % primary & near surface sampling
                  if (prof.presCutOffProf ~= g_decArgo_presDef)
                     
                     if (prof.presCutOffProf < dzStopPres)
                        
                        % primary sampling
                        [text1, ...
                           nbPrimaryFlag, discretePrimaryFlag, averagedPrimaryFlag] = ...
                           create_text(dzStartPres, dzStopPres, dzSampPeriod, ...
                           dzNbSubSamp, dzSubSampType, dzSubSampRate, ...
                           nbPrimaryFlag, discretePrimaryFlag, averagedPrimaryFlag);

                     elseif (prof.presCutOffProf > dzStartPres)
                        
                        % near surface sampling
                        [text2, ...
                           nbNearSurfaceFlag, discreteNearSurfaceFlag, averagedNearSurfaceFlag] = ...
                           create_text(dzStartPres, dzStopPres, dzSampPeriod, ...
                           dzNbSubSamp, dzSubSampType, dzSubSampRate, ...
                           nbNearSurfaceFlag, discreteNearSurfaceFlag, averagedNearSurfaceFlag);

                     elseif ((prof.presCutOffProf < dzStartPres) && (prof.presCutOffProf > dzStopPres))
                        
                        % primary sampling
                        [text1, ...
                           nbPrimaryFlag, discretePrimaryFlag, averagedPrimaryFlag] = ...
                           create_text(dzStartPres, prof.presCutOffProf, dzSampPeriod, ...
                           dzNbSubSamp, dzSubSampType, dzSubSampRate, ...
                           nbPrimaryFlag, discretePrimaryFlag, averagedPrimaryFlag);
                        
                        % near surface sampling
                        [text2, ...
                           nbNearSurfaceFlag, discreteNearSurfaceFlag, averagedNearSurfaceFlag] = ...
                           create_text(prof.presCutOffProf, dzStopPres, dzSampPeriod, ...
                           dzNbSubSamp, dzSubSampType, dzSubSampRate, ...
                           nbNearSurfaceFlag, discreteNearSurfaceFlag, averagedNearSurfaceFlag);

                     end
                  end
               end
               
            elseif ((profPres < dzStartPres) && (profPres > dzStopPres))
               
               if (prof.primarySamplingProfileFlag == 0)
                                    
                  % secondary sampling
                  [text1, ...
                     nbSecondaryFlag, discreteSecondaryFlag, averagedSecondaryFlag] = ...
                     create_text(profPres, dzStopPres, dzSampPeriod, ...
                     dzNbSubSamp, dzSubSampType, dzSubSampRate, ...
                     nbSecondaryFlag, discreteSecondaryFlag, averagedSecondaryFlag);
                  
               else
                  
                  % primary & near surface sampling
                  if (prof.presCutOffProf ~= g_decArgo_presDef)
                     
                     if (prof.presCutOffProf < dzStopPres)
                        
                        % primary sampling
                        [text1, ...
                           nbPrimaryFlag, discretePrimaryFlag, averagedPrimaryFlag] = ...
                           create_text(profPres, dzStopPres, dzSampPeriod, ...
                           dzNbSubSamp, dzSubSampType, dzSubSampRate, ...
                           nbPrimaryFlag, discretePrimaryFlag, averagedPrimaryFlag);

                     elseif (prof.presCutOffProf > dzStartPres)
                        
                        % near surface sampling
                        [text2, ...
                           nbNearSurfaceFlag, discreteNearSurfaceFlag, averagedNearSurfaceFlag] = ...
                           create_text(profPres, dzStopPres, dzSampPeriod, ...
                           dzNbSubSamp, dzSubSampType, dzSubSampRate, ...
                           nbNearSurfaceFlag, discreteNearSurfaceFlag, averagedNearSurfaceFlag);

                     elseif ((prof.presCutOffProf < dzStartPres) && (prof.presCutOffProf > dzStopPres))
                        
                        % primary sampling
                        [text1, ...
                           nbPrimaryFlag, discretePrimaryFlag, averagedPrimaryFlag] = ...
                           create_text(profPres, prof.presCutOffProf, dzSampPeriod, ...
                           dzNbSubSamp, dzSubSampType, dzSubSampRate, ...
                           nbPrimaryFlag, discretePrimaryFlag, averagedPrimaryFlag);
                        
                        % near surface sampling
                        [text2, ...
                           nbNearSurfaceFlag, discreteNearSurfaceFlag, averagedNearSurfaceFlag] = ...
                           create_text(prof.presCutOffProf, dzStopPres, dzSampPeriod, ...
                           dzNbSubSamp, dzSubSampType, dzSubSampRate, ...
                           nbNearSurfaceFlag, discreteNearSurfaceFlag, averagedNearSurfaceFlag);

                     end
                  end
               end
            end
            
            if (~isempty(text1))
               text1List{end+1} = text1;
            end
            if (~isempty(text2))
               text2List{end+1} = text2;
            end
         end
         
         descriptionSecondary = '';
         descriptionPrimary = '';
         descriptionNearSurface = '';
         if (prof.primarySamplingProfileFlag == 0)
            
            % secondary sampling
            if (~isempty(text1List))
               descriptionSecondary = [sprintf('%s;', text1List{1:end-1}) sprintf('%s', text1List{end})];
            end

            if (discreteSecondaryFlag == nbSecondaryFlag)
               vssTextSecondary = [vssTextSecondary ' discrete [' descriptionSecondary ']'];
            elseif (averagedSecondaryFlag == nbSecondaryFlag)
               vssTextSecondary = [vssTextSecondary ' averaged [' descriptionSecondary ']'];
            else
               vssTextSecondary = [vssTextSecondary ' mixed [' descriptionSecondary ']'];
            end
            
            a_tabProfiles(idP).vertSamplingScheme = vssTextSecondary;
            
         else
            
            % primary sampling
            if (~isempty(text1List))
               descriptionPrimary = [sprintf('%s;', text1List{1:end-1}) sprintf('%s', text1List{end})];
            end
            if (discretePrimaryFlag == nbPrimaryFlag)
               vssTextPrimary = [vssTextPrimary ' discrete [' descriptionPrimary ']'];
            elseif (averagedPrimaryFlag == nbPrimaryFlag)
               vssTextPrimary = [vssTextPrimary ' averaged [' descriptionPrimary ']'];
            else
               vssTextPrimary = [vssTextPrimary ' mixed [' descriptionPrimary ']'];
            end

            % near-surface sampling
            if (~isempty(text2List))
               descriptionNearSurface = [sprintf('%s;', text2List{1:end-1}) sprintf('%s', text2List{end})];
            end
            if (discreteNearSurfaceFlag == nbNearSurfaceFlag)
               vssTextNearSurface = [vssTextNearSurface ' discrete, unpumped [' descriptionNearSurface ']'];
            elseif (averagedNearSurfaceFlag == nbNearSurfaceFlag)
               vssTextNearSurface = [vssTextNearSurface ' averaged, unpumped [' descriptionNearSurface ']'];
            else
               vssTextNearSurface = [vssTextNearSurface ' mixed, unpumped [' descriptionNearSurface ']'];
            end
            
            vssTextSecondaryOptode  = regexprep(vssTextPrimary, 'Primary sampling:', 'Secondary sampling:'); % the profile is cut but it is a secondary one
            a_tabProfiles(idP).vertSamplingScheme = [{vssTextSecondaryOptode} {vssTextNearSurface}];
         end
         
      else
         
         % descending profile
         parkPres = get_config_value(sprintf('CONFIG_APMT_PATTERN_%02d_P01', ...
            g_decArgo_patternNumFloat), configNames, configValues);
                  
         % number of depth zones
         nbDepthZones = get_config_value(sprintf('CONFIG_PAYLOAD_USED_SENSOR_%02d_P00_VP02', ...
            prof.payloadSensorNumber), configNames, configValues);
         
         % depth zone information
         depthZoneStartPres = ones(nbDepthZones, 1)*-1;
         depthZoneStopPres = ones(nbDepthZones, 1)*-1;
         depthZoneSampPeriod = ones(nbDepthZones, 1)*-1;
         depthZoneNbSubSamp = ones(nbDepthZones, 1)*-1;
         depthZoneSubSampType = ones(nbDepthZones, 1)*-1;
         depthZoneSubSampRate = ones(nbDepthZones, 1)*-1;
         for idDz = 1:nbDepthZones
            depthZoneStartPres(idDz) = get_config_value(sprintf('CONFIG_PAYLOAD_USED_SENSOR_%02d_P01_VP02_%d', ...
               prof.payloadSensorNumber, idDz), configNames, configValues);
            depthZoneStopPres(idDz) = get_config_value(sprintf('CONFIG_PAYLOAD_USED_SENSOR_%02d_P02_VP02_%d', ...
               prof.payloadSensorNumber, idDz), configNames, configValues);
            depthZoneSampPeriod(idDz) = get_config_value(sprintf('CONFIG_PAYLOAD_USED_SENSOR_%02d_P03_VP02_%d', ...
               prof.payloadSensorNumber, idDz), configNames, configValues);
            
            depthZoneNbSubSamp(idDz) = get_config_value(sprintf('CONFIG_PAYLOAD_USED_SENSOR_%02d_P06_VP02_%d', ...
               prof.payloadSensorNumber, idDz), configNames, configValues);
            if (depthZoneNbSubSamp(idDz) == 1)
               depthZoneSubSampType(idDz) = get_config_value(sprintf('CONFIG_PAYLOAD_USED_SENSOR_%02d_P07_VP02_%d_1', ...
                  prof.payloadSensorNumber, idDz), configNames, configValues);
               depthZoneSubSampRate(idDz) = get_config_value(sprintf('CONFIG_PAYLOAD_USED_SENSOR_%02d_P08_VP02_%d_1', ...
                  prof.payloadSensorNumber, idDz), configNames, configValues);
            end
         end
         
         % sort depth zones
         [depthZoneStartPres, idSort] = sort(depthZoneStartPres, 'ascend');
         depthZoneStopPres = depthZoneStopPres(idSort);
         depthZoneSampPeriod = depthZoneSampPeriod(idSort);
         depthZoneNbSubSamp = depthZoneNbSubSamp(idSort);
         depthZoneSubSampType = depthZoneSubSampType(idSort);
         depthZoneSubSampRate = depthZoneSubSampRate(idSort);
                  
         text1List = [];
         nbFlag = 0;
         discreteFlag = 0;
         averagedFlag = 0;
         for idDz = 1:nbDepthZones
            
            text1 = [];
            
            dzStartPres = depthZoneStartPres(idDz);
            dzStopPres = depthZoneStopPres(idDz);
            dzSampPeriod = depthZoneSampPeriod(idDz);
            dzNbSubSamp = depthZoneNbSubSamp(idDz);
            dzSubSampType = depthZoneSubSampType(idDz);
            dzSubSampRate = depthZoneSubSampRate(idDz);
            
            if (parkPres > dzStopPres)
               
               [text1, ...
                  nbFlag, discreteFlag, averagedFlag] = ...
                  create_text(dzStartPres, dzStopPres, dzSampPeriod, ...
                  dzNbSubSamp, dzSubSampType, dzSubSampRate, ...
                  nbFlag, discreteFlag, averagedFlag);
               
            elseif ((parkPres < dzStopPres) && (parkPres > dzStartPres))
               
               [text1, ...
                  nbFlag, discreteFlag, averagedFlag] = ...
                  create_text(dzStartPres, parkPres, dzSampPeriod, ...
                  dzNbSubSamp, dzSubSampType, dzSubSampRate, ...
                  nbFlag, discreteFlag, averagedFlag);
               
            end
            
            if (~isempty(text1))
               text1List{end+1} = text1;
            end
         end
         
         description = '';
         if (~isempty(text1List))
            description = [sprintf('%s;', text1List{1:end-1}) sprintf('%s', text1List{end})];
         end
         
         if (discreteFlag == nbFlag)
            vssTextDescent = [vssTextDescent ' discrete [' description ']'];
         elseif (averagedFlag == nbFlag)
            vssTextDescent = [vssTextDescent ' averaged [' description ']'];
         else
            vssTextDescent = [vssTextDescent ' mixed [' description ']'];
         end
         
         a_tabProfiles(idP).vertSamplingScheme = vssTextDescent;

      end
   end
end

o_tabProfiles = a_tabProfiles;

return;

% ------------------------------------------------------------------------------
% Get a config value from a given configuration.
%
% SYNTAX :
%  [o_configValue] = get_config_value(a_configName, a_configNames, a_configValues)
%
% INPUT PARAMETERS :
%   a_configName   : name of the wanted config parameter
%   a_configNames  : configuration names
%   a_configValues : configuration values
%
% OUTPUT PARAMETERS :
%   o_configValue : retrieved configuration value
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configValue] = get_config_value(a_configName, a_configNames, a_configValues)

% output parameters initialization
o_configValue = [];

% retrieve the configuration value
idPos = find(strcmp(a_configName, a_configNames) == 1, 1);
o_configValue = a_configValues(idPos);

return;

% ------------------------------------------------------------------------------
% Create text of a detailed description part of the VSS and report flags.
%
% SYNTAX :
%  [o_text, o_nbFlag, o_discreteFlag, o_averagedFlag] = ...
%    create_text(a_startPres, a_stopPres, a_samplingPeriod, ...
%    a_nbSubSampling, a_subSamplingType, a_subSamplingRate, ...
%    a_nbFlag, a_discreteFlag, a_averagedFlag)
%
% INPUT PARAMETERS :
%   a_startPres       : start pressure
%   a_stopPres        : stop pressure
%   a_samplingPeriod  : sampling period
%   a_nbSubSampling   : number of sub samplings
%   a_subSamplingType : sub sampling type
%   a_subSamplingRate : sub sampling rate
%   a_nbFlag          : input total counter flag 
%   a_discreteFlag    : input discreate counter flag
%   a_averagedFlag    : input averaged counter flag
%
% OUTPUT PARAMETERS :
%   o_text         : output text for VSS detailed description 
%   o_nbFlag       : output total counter flag 
%   o_discreteFlag : output discreate counter flag
%   o_averagedFlag : output averaged counter flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_text, o_nbFlag, o_discreteFlag, o_averagedFlag] = ...
   create_text(a_startPres, a_stopPres, a_samplingPeriod, ...
   a_nbSubSampling, a_subSamplingType, a_subSamplingRate, ...
   a_nbFlag, a_discreteFlag, a_averagedFlag)

% output parameters initialization
o_text = '';
o_nbFlag = a_nbFlag + 1;
o_discreteFlag = a_discreteFlag;
o_averagedFlag = a_averagedFlag;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloat;
global g_decArgo_patternNumFloat;


rawSampFlag = 0;
if (isnan(a_samplingPeriod))
   samplingText = 'raw samp.';
   rawSampFlag = 1;
else
   samplingText = sprintf('%g dbar samp.', a_samplingPeriod);
   o_averagedFlag = o_averagedFlag + 1;
end

if (a_nbSubSampling == 0)
   o_text = sprintf('%s from %g dbar to %g dbar', ...
      samplingText, a_startPres, a_stopPres);
   if (rawSampFlag == 1)
      o_discreteFlag = o_discreteFlag + 1;
   end
else
   if (rawSampFlag == 1)
      o_averagedFlag = o_averagedFlag + 1;
   end
   if (a_subSamplingType == 1)
      o_text = sprintf('%s, %d samples avg. from %g dbar to %g dbar', ...
         samplingText, a_subSamplingRate, a_startPres, a_stopPres);
   elseif (a_subSamplingType == 2)
      o_text = sprintf('%s, %d samples med. from %g dbar to %g dbar', ...
         samplingText, a_subSamplingRate, a_startPres, a_stopPres);
   elseif (a_subSamplingType == 3)
      o_text = sprintf('%s, %d samples min. from %g dbar to %g dbar', ...
         samplingText, a_subSamplingRate, a_startPres, a_stopPres);
   elseif (a_subSamplingType == 4)
      o_text = sprintf('%s, %d samples max. from %g dbar to %g dbar', ...
         samplingText, a_subSamplingRate, a_startPres, a_stopPres);
   elseif (a_subSamplingType == 5)
      o_text = sprintf('%s, %d samples stddev. from %g dbar to %g dbar', ...
         samplingText, a_subSamplingRate, a_startPres, a_stopPres);
   else
      fprintf('WARNING: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Inconsistent payload configuration to create VSS \n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         g_decArgo_cycleNumFloat, ...
         g_decArgo_patternNumFloat);
   end
end

return;
