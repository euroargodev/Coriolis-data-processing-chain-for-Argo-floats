% ------------------------------------------------------------------------------
% Create and add the vertical sampling scheme information to the profiles of the
% Nova floats.
%
% SYNTAX :
%  [o_tabProfiles] = add_vertical_sampling_scheme_ir_sbd_nva(a_tabProfiles, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabProfiles : input profile structures
%   a_decoderId   : float decoder Id
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
%   04/28/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = add_vertical_sampling_scheme_ir_sbd_nva(a_tabProfiles, a_decoderId)

% output parameters initialization
o_tabProfiles = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


% add the vertical sampling scheme for each profile
for idP = 1:length(a_tabProfiles)
   prof = a_tabProfiles(idP);
      
   [configNames, configValues] = get_float_config_ir_sbd(prof.cycleNumber);
   if (~isempty(configNames))
      
      % retrieve needed information from configuration
      
      % sampling periods
      descSamplingPeriod = get_config_value('CONFIG_PM04', configNames, configValues);
      ascSamplingPeriod = get_config_value('CONFIG_PM03', configNames, configValues);
      % if not set, use a default sampling period of 10 sec
      if (isempty(ascSamplingPeriod))
         ascSamplingPeriod = 10;
      end
      if (isempty(descSamplingPeriod))
         descSamplingPeriod = ascSamplingPeriod;
      end

      % park and prof depth
      parkPres = get_config_value('CONFIG_PM06', configNames, configValues);
      profilePres = get_config_value('CONFIG_PM07', configNames, configValues);

      % sampling method and associated parameters
      samplingMethod = get_config_value('CONFIG_PH38', configNames, configValues);
      % bin averaged method
      topBinInterval = get_config_value('CONFIG_PH29', configNames, configValues);
      topBinSize = get_config_value('CONFIG_PH30', configNames, configValues);
      topBinMax = get_config_value('CONFIG_PH31', configNames, configValues);
      middleBinInterval = get_config_value('CONFIG_PH32', configNames, configValues);
      middleBinSize = get_config_value('CONFIG_PH33', configNames, configValues);
      middleBinMax = get_config_value('CONFIG_PH34', configNames, configValues);
      bottomBinInterval = get_config_value('CONFIG_PH35', configNames, configValues);
      bottomBinSize = get_config_value('CONFIG_PH36', configNames, configValues);
      transitionBin = get_config_value('CONFIG_PH37', configNames, configValues);
      % spot sampling method
      depthInterval = get_config_value('CONFIG_PM09', configNames, configValues);
      
      vssText = [];
      if (samplingMethod == 0)
         
         % bin averaged method
         vssText = 'Primary sampling: averaged';
         
         % create detailed description
         description = '';
         
         if (prof.direction == 'A')
            if (~isempty(topBinInterval) && ~isempty(topBinSize) && ~isempty(topBinMax) && ...
                  ~isempty(middleBinInterval) && ~isempty(middleBinSize) && ~isempty(middleBinMax) && ...
                  ~isempty(bottomBinInterval) && ~isempty(bottomBinSize) && ~isempty(transitionBin) && ...
                  ~isempty(ascSamplingPeriod) && ~isempty(profilePres))
               
               % compute bin sizes as they are used (operation performed by the
               % CTD)
               topBinSize = min(topBinInterval, topBinSize);
               middleBinSize = min(middleBinInterval, middleBinSize);
               bottomBinSize = min(bottomBinInterval, bottomBinSize);
               
               description = sprintf( ...
                  ['%dsec sampling;%dcbar interval,%dcbar average from %dcbar to %dcbar;' ...
                  '%dcbar interval,%dcbar average from %dcbar to %dcbar;', ...
                  '%dcbar interval,%dcbar average from %dcbar to %dcbar'], ...
                  ascSamplingPeriod, bottomBinInterval, bottomBinSize, profilePres*10, middleBinMax, ...
                  middleBinInterval, middleBinSize, middleBinMax, topBinMax, ...
                  topBinInterval, topBinSize, topBinMax, prof.presCutOffProf*10);
               if (transitionBin == 1)
                  description = [description ';transition bins included'];
               else
                  description = [description ';transition bins not included'];
               end
            else
               
               fprintf('WARNING: Float #%d Cycle #%d: Missing information to create the description of the vertical sampling scheme\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum);
            end
         else
            
            if (~isempty(topBinInterval) && ~isempty(topBinSize) && ~isempty(topBinMax) && ...
                  ~isempty(middleBinInterval) && ~isempty(middleBinSize) && ~isempty(middleBinMax) && ...
                  ~isempty(bottomBinInterval) && ~isempty(bottomBinSize) && ~isempty(transitionBin) && ...
                  ~isempty(descSamplingPeriod) && ~isempty(parkPres))
               
               % compute bin sizes as they are used (operation performed by the
               % CTD)
               topBinSize = min(topBinInterval, topBinSize);
               middleBinSize = min(middleBinInterval, middleBinSize);
               bottomBinSize = min(bottomBinInterval, bottomBinSize);

               if (parkPres*10 >  middleBinMax)
                  description = sprintf( ...
                     ['%dsec sampling;%dcbar interval,%dcbar average from surface to %dcbar;' ...
                     '%dcbar interval,%dcbar average from %dcbar to %dcbar;', ...
                     '%dcbar interval,%dcbar average from %dcbar to %dcbar'], ...
                     descSamplingPeriod, topBinInterval, topBinSize, topBinMax, ...
                     middleBinInterval, middleBinSize, topBinMax, middleBinMax, ...
                     bottomBinInterval, bottomBinSize, middleBinMax, parkPres*10);
               elseif (parkPres*10 >  topBinMax)
                  description = sprintf( ...
                     ['%dsec sampling;%dcbar interval,%dcbar average from surface to %dcbar;' ...
                     '%dcbar interval,%dcbar average from %dcbar to %dcbar'], ...
                     descSamplingPeriod, topBinInterval, topBinSize, topBinMax, ...
                     middleBinInterval, middleBinSize, topBinMax, parkPres*10);
               else
                  description = sprintf( ...
                     ['%dsec sampling;%dcbar interval,%dcbar average from surface to %dcbar'], ...
                     descSamplingPeriod, topBinInterval, topBinSize, parkPres*10);
               end
               if (transitionBin == 1)
                  description = [description ';transition bins included'];
               else
                  description = [description ';transition bins not included'];
               end
            else
               
               fprintf('WARNING: Float #%d Cycle #%d: Missing information to create the description of the vertical sampling scheme\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum);
            end
         end
         
      else
         
         % spot sampling method
         vssText = 'Primary sampling: discrete';
         
         % create detailed description
         description = '';
         
         if (prof.direction == 'A')
            if (~isempty(depthInterval) && ~isempty(ascSamplingPeriod) && ~isempty(profilePres))
               
               description = sprintf( ...
                  ['%dsec sampling,%ddbar interval,from %ddbar to %ddbar'], ...
                  ascSamplingPeriod, depthInterval, profilePres, prof.presCutOffProf);
            else
               
               fprintf('WARNING: Float #%d Cycle #%d: Missing information to create the description of the vertical sampling scheme\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum);
            end
         else
            
            if (~isempty(depthInterval) && ~isempty(descSamplingPeriod) && ~isempty(parkPres))
               
               description = sprintf( ...
                  ['%dsec sampling,%ddbar interval,from surface to %ddbar'], ...
                  descSamplingPeriod, depthInterval, parkPres);
            else
               
               fprintf('WARNING: Float #%d Cycle #%d: Missing information to create the description of the vertical sampling scheme\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum);
            end
         end         
      end
      
      vssText = [vssText ' [' description ']'];
      
      a_tabProfiles(idP).vertSamplingScheme = vssText;
      
   end
end

o_tabProfiles = a_tabProfiles;

return;
