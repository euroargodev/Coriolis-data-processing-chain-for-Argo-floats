% ------------------------------------------------------------------------------
% Create and add the vertical sampling scheme information to the profiles of the
% Argos floats.
%
% SYNTAX :
%  [o_tabProfiles] = add_vertical_sampling_scheme_argos(a_tabProfiles, a_decoderId)
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
%   01/22/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = add_vertical_sampling_scheme_argos(a_tabProfiles, a_decoderId)

% output parameters initialization
o_tabProfiles = [];

% structure to store miscellaneous meta-data
global g_decArgo_jsonMetaData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


presCutOffProf = -1;
if (~isempty(g_decArgo_jsonMetaData) && isfield(g_decArgo_jsonMetaData, 'PRES_CUT_OFF_PROF'))
   presCutOffProf = g_decArgo_jsonMetaData.PRES_CUT_OFF_PROF;
end

% add the vertical sampling scheme for each profile
for idP = 1:length(a_tabProfiles)
   prof = a_tabProfiles(idP);
   
   [configNames, configValues] = get_float_config_argos_1(prof.configMissionNumber);
   if (~isempty(configNames))
      
      vssText = [];
      if (prof.primarySamplingProfileFlag == 1)
         vssText = 'Primary sampling: averaged';
      else
         vssText = 'Near-surface sampling: averaged, unpumped';
      end
      
      % add configuration parameters for Argos floats
      nbThreshold = -1;
      switch (a_decoderId)
         case {1, 11, 12, 4, 19}
            nbThreshold = 1;
            descSamplingPeriod = get_config_value('CONFIG_PM5_', configNames, configValues);
            ascSamplingPeriod = get_config_value('CONFIG_PM7_', configNames, configValues);
            parkPres = get_config_value('CONFIG_PM8_', configNames, configValues);
            profilePres = get_config_value('CONFIG_PM9_', configNames, configValues);
            threshold1 = get_config_value('CONFIG_PM11_', configNames, configValues);
            thickSurf = get_config_value('CONFIG_PM12_', configNames, configValues);
            thickBottom = get_config_value('CONFIG_PM13_', configNames, configValues);
         case {3}
            nbThreshold = 1;
            descSamplingPeriod = get_config_value('CONFIG_PM5_', configNames, configValues);
            ascSamplingPeriod = get_config_value('CONFIG_PM7_', configNames, configValues);
            parkPres = get_config_value('CONFIG_PM8_', configNames, configValues);
            profilePres = get_config_value('CONFIG_PM9_', configNames, configValues);
            threshold1 = get_config_value('CONFIG_PM10_', configNames, configValues);
            thickSurf = get_config_value('CONFIG_PM11_', configNames, configValues);
            thickBottom = get_config_value('CONFIG_PM12_', configNames, configValues);
         case {24, 17, 25, 27, 28, 29, 31}
            nbThreshold = 2;
            descSamplingPeriod = get_config_value('CONFIG_PM5_', configNames, configValues);
            ascSamplingPeriod = get_config_value('CONFIG_PM7_', configNames, configValues);
            parkPres = get_config_value('CONFIG_PM8_', configNames, configValues);
            profilePres = get_config_value('CONFIG_PM9_', configNames, configValues);
            threshold1 = get_config_value('CONFIG_PM10_', configNames, configValues);
            threshold2 = get_config_value('CONFIG_PM11_', configNames, configValues);
            thickSurf = get_config_value('CONFIG_PM12_', configNames, configValues);
            thickMiddle = get_config_value('CONFIG_PM13_', configNames, configValues);
            thickBottom = get_config_value('CONFIG_PM14_', configNames, configValues);
         case {30}
            nbThreshold = 2;
            descSamplingPeriod = get_config_value('CONFIG_MC7_', configNames, configValues);
            ascSamplingPeriod = get_config_value('CONFIG_MC9_', configNames, configValues);
            parkPres = get_config_value('CONFIG_MC010_', configNames, configValues);
            profilePres = get_config_value('CONFIG_MC011_', configNames, configValues);
            threshold1 = get_config_value('CONFIG_MC14_', configNames, configValues);
            threshold2 = get_config_value('CONFIG_MC15_', configNames, configValues);
            thickSurf = get_config_value('CONFIG_MC16_', configNames, configValues);
            thickMiddle = get_config_value('CONFIG_MC17_', configNames, configValues);
            thickBottom = get_config_value('CONFIG_MC18_', configNames, configValues);
         otherwise
            fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in add_vertical_sampling_scheme_argos for decoderId #%d\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum, ...
               a_decoderId);
      end
      
      % if not set, use a default sampling period of 10 sec
      if (isempty(ascSamplingPeriod))
         ascSamplingPeriod = 10;
      end
      if (isempty(descSamplingPeriod))
         descSamplingPeriod = ascSamplingPeriod;
      end
      
      if (prof.direction == 'A')
         if (nbThreshold == 1)
            if (~isempty(ascSamplingPeriod) && ~isempty(profilePres) && ...
                  ~isempty(threshold1) && ~isempty(thickSurf) && ~isempty(thickBottom) && ...
                  (presCutOffProf ~= -1))
               if (prof.primarySamplingProfileFlag == 1)
                  description = sprintf( ...
                     ['%d sec sampling, %d dbar average from %d dbar to %d dbar; ' ...
                     '%d sec sampling, %d dbar average from %d dbar to %.1f dbar'], ...
                     ascSamplingPeriod, thickBottom, profilePres, threshold1, ...
                     ascSamplingPeriod, thickSurf, threshold1, presCutOffProf);
               else
                  description = sprintf( ...
                     ['%d sec sampling, %d dbar average from %.1f dbar to surface'], ...
                     ascSamplingPeriod, thickSurf, presCutOffProf);
               end
            else
               description = '';
               fprintf('WARNING: Float #%d Cycle #%d: Missing information to create the description of the vertical sampling scheme\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum);
            end
            
            vssText = [vssText ' [' description ']'];
         else
            if (~isempty(ascSamplingPeriod) && ~isempty(profilePres) && ...
                  ~isempty(threshold1) && ~isempty(threshold2) && ...
                  ~isempty(thickSurf) && ~isempty(thickMiddle) && ~isempty(thickBottom) && ...
                  (presCutOffProf ~= -1))
               if (prof.primarySamplingProfileFlag == 1)
                  description = sprintf( ...
                     ['%d sec sampling, %d dbar average from %d dbar to %d dbar; ' ...
                     '%d sec sampling, %d dbar average from %d dbar to %d dbar; ', ...
                     '%d sec sampling, %d dbar average from %d dbar to %.1f dbar'], ...
                     ascSamplingPeriod, thickBottom, profilePres, threshold2, ...
                     ascSamplingPeriod, thickMiddle, threshold2, threshold1, ...
                     ascSamplingPeriod, thickSurf, threshold1, presCutOffProf);
               else
                  description = sprintf( ...
                     ['%d sec sampling, %d dbar average from %.1f dbar to surface'], ...
                     ascSamplingPeriod, thickSurf, presCutOffProf);
               end
            else
               description = '';
               fprintf('WARNING: Float #%d Cycle #%d: Missing information to create the description of the vertical sampling scheme\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum);
            end
            
            vssText = [vssText ' [' description ']'];
         end
      else
         if (nbThreshold == 1)
            if (~isempty(descSamplingPeriod) && ~isempty(parkPres) && ...
                  ~isempty(threshold1) && ~isempty(thickSurf) && ~isempty(thickBottom))
               description = sprintf( ...
                  ['%d sec sampling, %d dbar average from surface to %d dbar; ' ...
                  '%d sec sampling, %d dbar average from %d dbar to %d dbar'], ...
                  descSamplingPeriod, thickSurf, threshold1, ...
                  descSamplingPeriod, thickBottom, threshold1, parkPres);
            else
               description = '';
               fprintf('WARNING: Float #%d Cycle #%d: Missing information to create the description of the vertical sampling scheme\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum);
            end
            
            vssText = [vssText ' [' description ']'];
         else
            if (~isempty(descSamplingPeriod) && ~isempty(parkPres) && ...
                  ~isempty(threshold1) && ~isempty(threshold2) && ...
                  ~isempty(thickSurf) && ~isempty(thickMiddle) && ~isempty(thickBottom))
               description = sprintf( ...
                  ['%d sec sampling, %d dbar average from surface to %d dbar; ' ...
                  '%d sec sampling, %d dbar average from %d dbar to %d dbar; ', ...
                  '%d sec sampling, %d dbar average from %d dbar to %d dbar'], ...
                  descSamplingPeriod, thickSurf, threshold1, ...
                  descSamplingPeriod, thickMiddle, threshold1, threshold2, ...
                  descSamplingPeriod, thickBottom, threshold2, parkPres);
            else
               description = '';
               fprintf('WARNING: Float #%d Cycle #%d: Missing information to create the description of the vertical sampling scheme\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum);
            end
            
            vssText = [vssText ' [' description ']'];
         end
      end
      
      a_tabProfiles(idP).vertSamplingScheme = vssText;
      
   end
end

o_tabProfiles = a_tabProfiles;

return;
