% ------------------------------------------------------------------------------
% Create and add the vertical sampling scheme information to the CTS5-USEA BGC
% profiles.
%
% SYNTAX :
%  [o_tabProfiles] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(a_tabProfiles)
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
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(a_tabProfiles)

% output parameters initialization
o_tabProfiles = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_patternNumFloat;


% add the vertical sampling scheme for each profile
for idP = 1:length(a_tabProfiles)
   prof = a_tabProfiles(idP);

   [configNames, configValues] = get_float_config_ir_rudics_sbd2(prof.cycleNumber, prof.profileNumber);
   if (~isempty(configNames))

      vssText = 'Secondary sampling:';
      vssTextSecondary = 'Secondary sampling:';

      if (prof.direction == 'A')

         % ascending profile
         profPres = get_config_value(sprintf('CONFIG_APMT_PATTERN_%02d_P02', ...
            g_decArgo_patternNumFloat), configNames, configValues);
         threshold = ones(4, 1)*-1;
         for id = 1:4
            threshold(id) = get_config_value(sprintf('CONFIG_APMT_SENSOR_%02d_P%02d', ...
               prof.payloadSensorNumber, 46+id-1), configNames, configValues);
         end

         idStart = find(threshold < profPres);
         idStart = idStart(end) + 1;
         threshold(idStart) = profPres;

         flagAvgSecondary = 0;
         flagDiscreteSecondary = 0;
         text3 = [];
         for id = idStart:-1:1
            sampPeriod = get_config_value(sprintf('CONFIG_APMT_SENSOR_%02d_P%02d', ...
               prof.payloadSensorNumber, 5+(id-1)*9), configNames, configValues);
            acqMode = get_config_value(sprintf('CONFIG_APMT_SENSOR_%02d_P%02d', ...
               prof.payloadSensorNumber, 6+(id-1)*9), configNames, configValues);
            treatType = get_config_value(sprintf('CONFIG_APMT_SENSOR_%02d_P%02d', ...
               prof.payloadSensorNumber, 7+(id-1)*9), configNames, configValues);
            slicesThick = get_config_value(sprintf('CONFIG_APMT_SENSOR_%02d_P%02d', ...
               prof.payloadSensorNumber, 9+(id-1)*9), configNames, configValues);

            % secondary samplings
            % if ((sampPeriod ~= 0) && (acqMode ~= 0)) if acqMode = 0 but sampPeriod > 0 the sensor is sampling => acqMode should not be considered
            if (sampPeriod ~= 0)
               if ((treatType == 0) || (treatType == 8))
                  text1 = sprintf('%ds samp. from ', ...
                     sampPeriod);
                  flagDiscreteSecondary = 1;
               else
                  text1 = sprintf('%ds samp., %gdbar avg from ', ...
                     sampPeriod, slicesThick);
                  flagAvgSecondary = 2;
               end

               if (id > 1)
                  text2 = sprintf('%ddbar to %ddbar', ...
                     threshold(id), threshold(id-1));
               else
                  text2 = sprintf('%ddbar to surface', ...
                     threshold(1));
               end

               text3{end+1} = [text1 text2];
            end
         end

         descriptionSecondary = '';

         % secondary sampling
         if (~isempty(text3))
            descriptionSecondary = [sprintf('%s;', text3{1:end-1}) sprintf('%s', text3{end})];
         end
         switch flagAvgSecondary+flagDiscreteSecondary
            case 1
               vssTextSecondary = [vssTextSecondary ' discrete [' descriptionSecondary ']'];
            case 2
               vssTextSecondary = [vssTextSecondary ' averaged [' descriptionSecondary ']'];
            case 3
               vssTextSecondary = [vssTextSecondary ' mixed [' descriptionSecondary ']'];
            case 0
               vssTextSecondary = [vssTextSecondary ' averaged [' descriptionSecondary ']'];
               fprintf('ERROR: Float #%dA: (Cy,Ptn)=(%d,%d): Configuration information and received data are not consistent - VSS set to default value (''%s'')\n', ...
                  g_decArgo_floatNum, prof.cycleNumber, prof.profileNumber, vssTextSecondary);
         end

         a_tabProfiles(idP).vertSamplingScheme = vssTextSecondary;

      else

         % descending profile
         parkPres = get_config_value(sprintf('CONFIG_APMT_PATTERN_%02d_P01', ...
            g_decArgo_patternNumFloat), configNames, configValues);
         if (isnan(parkPres))
            parkPres = get_config_value(sprintf('CONFIG_APMT_PATTERN_%02d_P01_01', ...
               g_decArgo_patternNumFloat), configNames, configValues);
         end
         threshold = ones(4, 1)*-1;

         for id = 1:4
            threshold(id) = get_config_value(sprintf('CONFIG_APMT_SENSOR_%02d_P%02d', ...
               prof.payloadSensorNumber, 46+id-1), configNames, configValues);
         end

         idEnd = find(threshold < parkPres);
         idEnd = idEnd(end) + 1;
         threshold(idEnd) = parkPres;

         flagAvg = 0;
         flagDiscrete = 0;
         text3 = [];
         for id = 1:idEnd
            sampPeriod = get_config_value(sprintf('CONFIG_APMT_SENSOR_%02d_P%02d', ...
               prof.payloadSensorNumber, 1+(id-1)*9), configNames, configValues);
            acqMode = get_config_value(sprintf('CONFIG_APMT_SENSOR_%02d_P%02d', ...
               prof.payloadSensorNumber, 6+(id-1)*9), configNames, configValues);
            treatType = get_config_value(sprintf('CONFIG_APMT_SENSOR_%02d_P%02d', ...
               prof.payloadSensorNumber, 7+(id-1)*9), configNames, configValues);
            slicesThick = get_config_value(sprintf('CONFIG_APMT_SENSOR_%02d_P%02d', ...
               prof.payloadSensorNumber, 9+(id-1)*9), configNames, configValues);

            % if ((sampPeriod ~= 0) && (acqMode ~= 0)) if acqMode = 0 but sampPeriod > 0 the sensor is sampling => acqMode should not be considered
            if (sampPeriod ~= 0)
               if ((treatType == 0) || (treatType == 8))
                  text1 = sprintf('%dsec samp. from ', ...
                     sampPeriod);
                  flagDiscrete = 1;
               else
                  text1 = sprintf('%dsec samp., %gdbar avg from ', ...
                     sampPeriod, slicesThick);
                  flagAvg = 2;
               end

               if (id == 1)
                  text2 = sprintf('surface to %ddbar', ...
                     threshold(1));
               else
                  text2 = sprintf('%d dbar to %ddbar', ...
                     threshold(id-1), threshold(id));
               end

               text3{end+1} = [text1 text2];
            end
         end

         description = '';
         if (~isempty(text3))
            description = [sprintf('%s;', text3{1:end-1}) sprintf('%s', text3{end})];
         end
         switch flagAvg+flagDiscrete
            case 1
               vssText = [vssText ' discrete [' description ']'];
            case 2
               vssText = [vssText ' averaged [' description ']'];
            case 3
               vssText = [vssText ' mixed [' description ']'];
            case 0
               vssText = [vssText ' averaged [' description ']'];
               fprintf('WARNING: Float #%dD: (Cy,Ptn)=(%d,%d): Configuration information and received data are not consistent - VSS set to default value (''%s'')\n', ...
                  g_decArgo_floatNum, prof.cycleNumber, prof.profileNumber, vssText);
         end

         a_tabProfiles(idP).vertSamplingScheme = vssText;

      end
   end
end

o_tabProfiles = a_tabProfiles;

return

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
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configValue] = get_config_value(a_configName, a_configNames, a_configValues)

% output parameters initialization
o_configValue = [];

% retrieve the configuration value
idPos = find(strcmp(a_configName, a_configNames) == 1, 1);
o_configValue = a_configValues(idPos);

return
