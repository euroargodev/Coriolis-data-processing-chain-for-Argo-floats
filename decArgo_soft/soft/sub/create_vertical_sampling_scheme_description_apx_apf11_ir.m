% ------------------------------------------------------------------------------
% Create the detailed description of the vertical sampling scheme for Apex APF11
% Iridium floats.
%
% SYNTAX :
%  [o_description] = ...
%    create_vertical_sampling_scheme_description_apx_apf11_ir( ...
%    a_cycleNum, a_firstSensorName, a_secondSensorName, a_minMax)
%
% INPUT PARAMETERS :
%   a_cycleNum         : current cycle number
%   a_firstSensorName  : 'coded' first sensor type
%   a_secondSensorName : 'coded' second sensor type
%   a_minMax           : range of the CP data (min and max pressures)
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
%   07/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_description] = ...
   create_vertical_sampling_scheme_description_apx_apf11_ir( ...
   a_cycleNum, a_firstSensorName, a_secondSensorName, a_minMax)

% output parameters initialization
o_description = [];

% current float WMO number
global g_decArgo_floatNum;


% retrieve configuration parameters
[configNames, configValues] = get_float_config_apx_apf11_ir(a_cycleNum);

switch (a_firstSensorName)
   
   case {'CTD', 'PH'}
      
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
      
      if (strcmp(a_firstSensorName, 'PH'))
         descriptionCtd = o_description;
         descriptionPh = '';
         
         idF = find(strcmp(configNames, 'CONFIG_PROFILE_ASCENT_PH_NumberOfZones'));
         if (~isempty(idF) && ~isnan(configValues(idF, 1)))
            nbZone = configValues(idF, 1);
            for idZ = nbZone:-1:1
               startPres = [];
               stopPres = [];
               timeInterval = [];
               idF = find(strcmp(configNames, sprintf('CONFIG_PROFILE_ASCENT_PH_%d_StartPressure', idZ)));
               if (~isempty(idF) && ~isnan(configValues(idF, 1)))
                  startPres = configValues(idF, 1);
               end
               idF = find(strcmp(configNames, sprintf('CONFIG_PROFILE_ASCENT_PH_%d_StopPressure', idZ)));
               if (~isempty(idF) && ~isnan(configValues(idF, 1)))
                  stopPres = configValues(idF, 1);
               end
               idF = find(strcmp(configNames, sprintf('CONFIG_PROFILE_ASCENT_PH_%d_TimeInterval', idZ)));
               if (~isempty(idF) && ~isnan(configValues(idF, 1)))
                  timeInterval = configValues(idF, 1);
               end
               if (~isempty(startPres) && ~isempty(stopPres) && ~isempty(timeInterval))
                  description = sprintf('%d second interval from %d dbar to %d dbar', ...
                     timeInterval, startPres, stopPres);
                  if (isempty(descriptionPh))
                     descriptionPh = description;
                  else
                     descriptionPh = [descriptionPh '; ' description];
                  end
               end
            end
         end
         
         if (~isempty(descriptionCtd) && ~isempty(descriptionPh))
            o_description = ['[' descriptionCtd '] for CTD; [' descriptionPh '] for TRANSISTOR_PH'];
         end
      end
      
      if (~isempty(o_description))
         minPres = a_minMax{1};
         maxPres = a_minMax{2};
         if (~isempty(minPres) && ~isempty(maxPres))
            o_description = sprintf('averaged from %g dbar to %g dbar {%s}; discrete otherwise', ...
               minPres, maxPres, o_description);
         end
      end
      
   case {'PTS', 'PTSH', 'OPT', 'FLBB', 'IRAD'}
      
      configPrefix = ['CONFIG_SAMPLE_ASCENT_' a_firstSensorName];
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
         a_firstSensorName);
end

return
