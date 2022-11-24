% ------------------------------------------------------------------------------
% Create the detailed description of the vertical sampling scheme for Ice cycles
% of Apex APF11 Iridium floats.
%
% SYNTAX :
%  [o_description] = ...
%    create_vss_description_apx_apf11_ir_ice_cycle( ...
%    a_cycleNum, a_sensorName, a_profileDir)
%
% INPUT PARAMETERS :
%   a_cycleNum   : current cycle number
%   a_sensorName : 'coded' first sensor type
%   a_profileDir : profile direction
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
%   03/23/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_description] = ...
   create_vss_description_apx_apf11_ir_ice_cycle( ...
   a_cycleNum, a_sensorName, a_profileDir)

% output parameters initialization
o_description = [];

% current float WMO number
global g_decArgo_floatNum;


% retrieve configuration parameters
[configNames, configValues] = get_float_config_apx_apf11_ir(a_cycleNum);

switch (a_sensorName)

   case {'PT', 'PTS', 'PTSH', 'OPT', 'FLBB', 'IRAD'}
      
      if (a_profileDir == 'A')
         configPrefix = ['CONFIG_SAMPLE_ICEASCENT_' a_sensorName];
      else
         configPrefix = ['CONFIG_SAMPLE_ICEDESCENT_' a_sensorName];
      end
      idF = find(strcmp(configNames, [configPrefix '_NumberOfZones']));
      if (~isempty(idF) && ~isnan(configValues(idF, 1)))
         nbZone = configValues(idF, 1);
         for idZ = nbZone:-1:1
            startPres = [];
            stopPres = [];
            depthInterval = [];
            nbSamples = [];
            idF = find(strcmp(configNames, sprintf('%s_%d_StartPressure', configPrefix, idZ)));
            if (~isempty(idF) && ~isnan(configValues(idF, 1)))
               startPres = configValues(idF, 1);
            end
            idF = find(strcmp(configNames, sprintf('%s_%d_StopPressure', configPrefix, idZ)));
            if (~isempty(idF) && ~isnan(configValues(idF, 1)))
               stopPres = configValues(idF, 1);
            end
            idF = find(strcmp(configNames, sprintf('%s_%d_DepthInterval', configPrefix, idZ)));
            if (~isempty(idF) && ~isnan(configValues(idF, 1)))
               depthInterval = configValues(idF, 1);
            end
            idF = find(strcmp(configNames, sprintf('%s_%d_NumberOfSamples', configPrefix, idZ)));
            if (~isempty(idF) && ~isnan(configValues(idF, 1)))
               nbSamples = configValues(idF, 1);
            end
            if (~isempty(startPres) && ~isempty(stopPres) && ~isempty(depthInterval) && ~isempty(nbSamples))
               if (depthInterval ~= 0)
                  if (nbSamples > 1)
                     description = sprintf('%d samples,%ddbar interval from %d to %ddbar', ...
                        nbSamples, depthInterval, startPres, stopPres);
                  else
                     description = sprintf('%d sample,%ddbar interval from %d to %ddbar', ...
                        nbSamples, depthInterval, startPres, stopPres);
                  end
               else
                  % retrieve CONFIG_ATI_AscentTimerInterval information
                  idF = find(strcmp(configNames, 'CONFIG_ATI_AscentTimerInterval'));
                  if (~isempty(idF) && ~isnan(configValues(idF, 1)))
                     ascTimerInterval = configValues(idF, 1);
                     if (nbSamples > 1)
                        description = sprintf('%d samples,%d sec interval from %d to %ddbar', ...
                           nbSamples, ascTimerInterval, startPres, stopPres);
                     else
                        description = sprintf('%d sample,%d sec interval from %d to %ddbar', ...
                           nbSamples, ascTimerInterval, startPres, stopPres);
                     end
                  end
               end
               if (isempty(o_description))
                  o_description = description;
               else
                  o_description = [o_description ';' description];
               end
            end
         end
      end
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing done yet in create_vss_description_apx_apf11_ir_ice_cycle for sensor type ''%s''\n', ...
         g_decArgo_floatNum, ...
         a_sensorName);
end

return
