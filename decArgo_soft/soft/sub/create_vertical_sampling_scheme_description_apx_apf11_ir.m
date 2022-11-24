% ------------------------------------------------------------------------------
% Create the detailed description of the vertical sampling scheme for Apex APF11
% Iridium floats.
%
% SYNTAX :
% function [o_description] = ...
%    create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, a_sensorType)
%
% INPUT PARAMETERS :
%   a_cycleNum   : current cycle number
%   a_sensorType : 'coded' sensor type
%
% OUTPUT PARAMETERS :
%   o_description : vertical sampling scheme detailed description
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/05/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_description] = ...
   create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, a_sensorType)

% output parameters initialization
o_description = [];

% current float WMO number
global g_decArgo_floatNum;


% retrieve configuration parameters
[configNames, configValues] = get_float_config_apx_apf11_ir(a_cycleNum);

switch (a_sensorType)
   
   case {'CTD'}
      
      idF = find(strcmp(configNames, 'CONFIG_PROFILE_ASCENT_CTD_NumberOfZones'));
      if (~isempty(idF) && ~isnan(configValues(idF, 1)))
         nbZone = configValues(idF, 1);
         for idZ = nbZone:-1:1
            startPres = [];
            stopPres = [];
            binSize = [];
            sampleRate = [];
            idF = find(strcmp(configNames, sprintf('CONFIG_PROFILE_ASCENT_CTD_%d_StartPressure', idZ)));
            if (~isempty(idF) && ~isnan(configValues(idF, 1)))
               startPres = configValues(idF, 1);
            end
            idF = find(strcmp(configNames, sprintf('CONFIG_PROFILE_ASCENT_CTD_%d_StopPressure', idZ)));
            if (~isempty(idF) && ~isnan(configValues(idF, 1)))
               stopPres = configValues(idF, 1);
            end
            idF = find(strcmp(configNames, sprintf('CONFIG_PROFILE_ASCENT_CTD_%d_BinSize', idZ)));
            if (~isempty(idF) && ~isnan(configValues(idF, 1)))
               binSize = configValues(idF, 1);
            end
            idF = find(strcmp(configNames, sprintf('CONFIG_PROFILE_ASCENT_CTD_%d_SampleRate', idZ)));
            if (~isempty(idF) && ~isnan(configValues(idF, 1)))
               sampleRate = configValues(idF, 1);
            end
            if (~isempty(startPres) && ~isempty(stopPres) && ~isempty(binSize) && ~isempty(sampleRate))
               description = sprintf('%d sample/second, %d dbar average from %d dbar to %d dbar', ...
                  sampleRate, binSize, startPres, stopPres);
               if (isempty(o_description))
                  o_description = description;
               else
                  o_description = [o_description '; ' description];
               end
            end
         end
      end
      
   case {'PTS'}
      
      idF = find(strcmp(configNames, 'CONFIG_SAMPLE_ASCENT_PTS_NumberOfZones'));
      if (~isempty(idF) && ~isnan(configValues(idF, 1)))
         nbZone = configValues(idF, 1);
         for idZ = nbZone:-1:1
            startPres = [];
            stopPres = [];
            depthInterval = [];
            nbSamples = [];
            idF = find(strcmp(configNames, sprintf('CONFIG_SAMPLE_ASCENT_PTS_%d_StartPressure', idZ)));
            if (~isempty(idF) && ~isnan(configValues(idF, 1)))
               startPres = configValues(idF, 1);
            end
            idF = find(strcmp(configNames, sprintf('CONFIG_SAMPLE_ASCENT_PTS_%d_StopPressure', idZ)));
            if (~isempty(idF) && ~isnan(configValues(idF, 1)))
               stopPres = configValues(idF, 1);
            end
            idF = find(strcmp(configNames, sprintf('CONFIG_SAMPLE_ASCENT_PTS_%d_DepthInterval', idZ)));
            if (~isempty(idF) && ~isnan(configValues(idF, 1)))
               depthInterval = configValues(idF, 1);
            end
            idF = find(strcmp(configNames, sprintf('CONFIG_SAMPLE_ASCENT_PTS_%d_NumberOfSamples', idZ)));
            if (~isempty(idF) && ~isnan(configValues(idF, 1)))
               nbSamples = configValues(idF, 1);
            end
            if (~isempty(startPres) && ~isempty(stopPres) && ~isempty(depthInterval) && ~isempty(nbSamples))
               if (depthInterval ~= 0)
                  if (nbSamples > 1)
                     description = sprintf('%d samples, %d dbar interval from %d dbar to %d dbar', ...
                        nbSamples, depthInterval, startPres, stopPres);
                  else
                     description = sprintf('%d sample, %d dbar interval from %d dbar to %d dbar', ...
                        nbSamples, depthInterval, startPres, stopPres);
                  end
               else
                  % retrieve CONFIG_ATI_AscentTimerInterval information
                  idF = find(strcmp(configNames, 'CONFIG_ATI_AscentTimerInterval'));
                  if (~isempty(idF) && ~isnan(configValues(idF, 1)))
                     ascTimerInterval = configValues(idF, 1);
                     if (nbSamples > 1)
                        description = sprintf('%d samples, %d seconds interval from %d dbar to %d dbar', ...
                           nbSamples, ascTimerInterval, startPres, stopPres);
                     else
                        description = sprintf('%d sample, %d seconds interval from %d dbar to %d dbar', ...
                           nbSamples, ascTimerInterval, startPres, stopPres);
                     end
                  end
               end
               if (isempty(o_description))
                  o_description = description;
               else
                  o_description = [o_description '; ' description];
               end
            end
         end
      end
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing done yet in create_vertical_sampling_scheme_description_apx_apf11_ir for sensor type ''%s''\n', ...
         g_decArgo_floatNum, ...
         a_sensorType);
end

return;
