% ------------------------------------------------------------------------------
% Create the detailed description of the vertical sampling scheme for Apex Argos
% floats.
%
% SYNTAX :
% function [o_description] = ...
%    create_vertical_sampling_scheme_description_apx_argos(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
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
%   04/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_description] = ...
   create_vertical_sampling_scheme_description_apx_argos(a_decoderId)

% output parameters initialization
o_description = [];

% current float WMO number
global g_decArgo_floatNum;

% float configuration
global g_decArgo_floatConfig;


switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % APEX APF9 floats
   case {1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011, ...
         1012, 1013, 1014, 1015, 1016}
      o_description = [];
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % APEX APF11 floats
   case {1021, 1022}
      
      % current configuration
      configName = [];
      configValue = [];
      if (~isempty(g_decArgo_floatConfig))
         configName = g_decArgo_floatConfig.NAMES;
         configValue = g_decArgo_floatConfig.VALUES;
      end
      
      idF = find(strcmp(configName, 'CONFIG_SAMPLE_ASCENT_PTS_NumberOfZones'));
      if (~isempty(idF) && ~isnan(configValue(idF, 1)))
         nbZone = configValue(idF, 1);
         for idZ = nbZone:-1:1
            startPres = [];
            stopPres = [];
            depthInterval = [];
            nbSamples = [];
            idF = find(strcmp(configName, sprintf('CONFIG_SAMPLE_ASCENT_PTS_%d_StartPressure', idZ)));
            if (~isempty(idF) && ~isnan(configValue(idF, 1)))
               startPres = configValue(idF, 1);
            end
            idF = find(strcmp(configName, sprintf('CONFIG_SAMPLE_ASCENT_PTS_%d_StopPressure', idZ)));
            if (~isempty(idF) && ~isnan(configValue(idF, 1)))
               stopPres = configValue(idF, 1);
            end
            idF = find(strcmp(configName, sprintf('CONFIG_SAMPLE_ASCENT_PTS_%d_DepthInterval', idZ)));
            if (~isempty(idF) && ~isnan(configValue(idF, 1)))
               depthInterval = configValue(idF, 1);
            end
            idF = find(strcmp(configName, sprintf('CONFIG_SAMPLE_ASCENT_PTS_%d_NumberOfSamples', idZ)));
            if (~isempty(idF) && ~isnan(configValue(idF, 1)))
               nbSamples = configValue(idF, 1);
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
                  idF = find(strcmp(configName, 'CONFIG_ATI_AscentTimerInterval'));
                  if (~isempty(idF) && ~isnan(configValue(idF, 1)))
                     ascTimerInterval = configValue(idF, 1);
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
      fprintf('WARNING: Float #%d: Nothing done yet in create_vertical_sampling_scheme_description_apx_argos for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
