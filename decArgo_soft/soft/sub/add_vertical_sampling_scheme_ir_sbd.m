% ------------------------------------------------------------------------------
% Create and add the vertical sampling scheme information to the profiles of the
% Iridium floats.
%
% SYNTAX :
%  [o_tabProfiles] = add_vertical_sampling_scheme_ir_sbd(a_tabProfiles, a_decoderId)
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
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = add_vertical_sampling_scheme_ir_sbd(a_tabProfiles, a_decoderId)

% output parameters initialization
o_tabProfiles = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_presDef;


% add the vertical sampling scheme for each profile
for idP = 1:length(a_tabProfiles)
   prof = a_tabProfiles(idP);
      
   [configNames, configValues] = get_float_config_ir_sbd(prof.cycleNumber);
   if (~isempty(configNames))
      
      vssText = [];
      if (prof.primarySamplingProfileFlag == 1)
         vssText = 'Primary sampling: averaged';
      else
         vssText = 'Near-surface sampling: averaged, unpumped';
      end
      
      % add configuration parameters for Argos floats
      switch (a_decoderId)
         case {204}
            nbThreshold = 1;
            descSamplingPeriod = get_config_value('CONFIG_PM05', configNames, configValues);
            ascSamplingPeriod = get_config_value('CONFIG_PM07', configNames, configValues);
            parkPres = get_config_value('CONFIG_PM08', configNames, configValues);
            profilePres = get_config_value('CONFIG_PM09', configNames, configValues);
            threshold1 = get_config_value('CONFIG_PM10', configNames, configValues);
            thickSurf = get_config_value('CONFIG_PM11', configNames, configValues);
            thickBottom = get_config_value('CONFIG_PM12', configNames, configValues);
         case {201, 202, 203, 205, 206, 207, 208, 209, 215, 216}
            nbThreshold = 2;
            descSamplingPeriod = get_config_value('CONFIG_PM05', configNames, configValues);
            ascSamplingPeriod = get_config_value('CONFIG_PM07', configNames, configValues);
            parkPres = get_config_value('CONFIG_PM08', configNames, configValues);
            profilePres = get_config_value('CONFIG_PM09', configNames, configValues);
            threshold1 = get_config_value('CONFIG_PM10', configNames, configValues);
            threshold2 = get_config_value('CONFIG_PM11', configNames, configValues);
            thickSurf = get_config_value('CONFIG_PM12', configNames, configValues);
            thickMiddle = get_config_value('CONFIG_PM13', configNames, configValues);
            thickBottom = get_config_value('CONFIG_PM14', configNames, configValues);
         case {210, 211, 212, 213, 214, 217}
            nbThreshold = 2;
            descSamplingPeriod = get_config_value('CONFIG_MC08_', configNames, configValues);
            ascSamplingPeriod = get_config_value('CONFIG_MC10_', configNames, configValues);
            parkPres = get_config_value('CONFIG_MC011_', configNames, configValues);
            profilePres = get_config_value('CONFIG_MC012_', configNames, configValues);
            threshold1 = get_config_value('CONFIG_MC17_', configNames, configValues);
            threshold2 = get_config_value('CONFIG_MC18_', configNames, configValues);
            thickSurf = get_config_value('CONFIG_MC19_', configNames, configValues);
            thickMiddle = get_config_value('CONFIG_MC20_', configNames, configValues);
            thickBottom = get_config_value('CONFIG_MC21_', configNames, configValues);

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
                  (prof.presCutOffProf ~= g_decArgo_presDef) && ...
                  (prof.presCutOffProf ~= -g_decArgo_presDef))
               if (prof.primarySamplingProfileFlag == 1)
                  description = sprintf( ...
                     ['%d sec sampling, %d dbar average from %d dbar to %d dbar; ' ...
                     '%d sec sampling, %d dbar average from %d dbar to %.1f dbar'], ...
                     ascSamplingPeriod, thickBottom, profilePres, threshold1, ...
                     ascSamplingPeriod, thickSurf, threshold1, prof.presCutOffProf);
               else
                  description = sprintf( ...
                     ['%d sec sampling, %d dbar average from %.1f dbar to surface'], ...
                     ascSamplingPeriod, thickSurf, prof.presCutOffProf);
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
                  (prof.presCutOffProf ~= g_decArgo_presDef) && ...
                  (prof.presCutOffProf ~= -g_decArgo_presDef))
               if (prof.primarySamplingProfileFlag == 1)
                  description = sprintf( ...
                     ['%d sec sampling, %d dbar average from %d dbar to %d dbar; ' ...
                     '%d sec sampling, %d dbar average from %d dbar to %d dbar; ', ...
                     '%d sec sampling, %d dbar average from %d dbar to %.1f dbar'], ...
                     ascSamplingPeriod, thickBottom, profilePres, threshold2, ...
                     ascSamplingPeriod, thickMiddle, threshold2, threshold1, ...
                     ascSamplingPeriod, thickSurf, threshold1, prof.presCutOffProf);
               else
                  description = sprintf( ...
                     ['%d sec sampling, %d dbar average from %.1f dbar to surface'], ...
                     ascSamplingPeriod, thickSurf, prof.presCutOffProf);
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

return
