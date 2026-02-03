% ------------------------------------------------------------------------------
% Retrieve information to separate pumped and unpumped data in the ascending
% profile.
%
% SYNTAX :
% [o_subSurfacePres, o_presCutOffProfConfig, o_presCutOffProf, o_tabTech] = ...
%    get_pres_cut_off_prof(a_tabTech, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabTech   : input technical information
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_subSurfacePres       : pressure of the last pumped PRES raw measurement
%   o_presCutOffProfConfig : pressure of the config cut-off profile
%   o_presCutOffProf       : pressure to use to cut-off the ascending profile
%   o_tabTech              : output technical information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%  12/27/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_subSurfacePres, o_presCutOffProfConfig, o_presCutOffProf, o_tabTech] = ...
   get_pres_cut_off_prof(a_tabTech, a_decoderId)

% output parameters initialization
o_subSurfacePres = '';
o_presCutOffProfConfig = '';
o_presCutOffProf = '';
o_tabTech = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


switch (a_decoderId)
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {201, 203, 215, 202}
      if (~isempty(a_tabTech))

         % retrieve the last pumped PRES from the tech msg #2
         idF2 = find(a_tabTech(:, 1) == 4);
         if (~isempty(idF2))
            if (length(idF2) > 1)
               fprintf('ERROR: Float #%d cycle #%d: %d decoded tech message #2  - using the last one\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  length(idF2));
            end
            o_tabTech = a_tabTech(idF2(end), :);
            pres = sensor_2_value_for_pressure_201_203_215_216_218_221_228_229_230(o_tabTech(10));
            temp = sensor_2_value_for_temp_2xx_1_to_3_15_16_18_21_28_29_30(o_tabTech(11));
            psal = o_tabTech(12)/1000;
            if (any([pres temp psal] ~= 0))
               % A specific bin is created after the pressure of the ‘subsurface point’
               % (PSubsurfacePoint).so that pumped and unpumped data are not mixed in the
               % bin-averaged output values.
               o_subSurfacePres = pres;
               o_presCutOffProf = o_subSurfacePres;
            end
         end
      end
      if (isempty(o_subSurfacePres))
         % retrieve the CTD pump cut-off pressure from the configuration
         [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
         ctpPumpSwitchOffPres = get_config_value('CONFIG_PT20', configNames, configValues);
         if (~isempty(ctpPumpSwitchOffPres))
            % PT20 is CTD pump cut-off pressure we should add Poverlap = 0.5 dbar
            o_presCutOffProfConfig = ctpPumpSwitchOffPres + 0.5;
         else
            o_presCutOffProfConfig = 5 + 0.5;
         end
         o_presCutOffProf = o_presCutOffProfConfig;
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {204, 205, 206, 207, 208, 209}
      if (~isempty(a_tabTech))

         % retrieve the last pumped PRES from the tech msg
         if (size(a_tabTech, 1) > 1)
            fprintf('WARNING: Float #%d cycle #%d: %d tech message in the buffer - using the last one\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, ...
               size(a_tabTech, 1));
         end
         o_tabTech = a_tabTech(end, :);
         pres = sensor_2_value_for_pressure_204_to_209_219_220(o_tabTech(41));
         temp = sensor_2_value_for_temp_2xx_4_to_14_17_19_20_22_to_27_31_32(o_tabTech(42));
         psal = o_tabTech(43)/1000;
         if (any([pres temp psal] ~= 0))
            % A specific bin is created after the pressure of the ‘subsurface point’
            % (PSubsurfacePoint).so that pumped and unpumped data are not mixed in the
            % bin-averaged output values.
            o_subSurfacePres = pres;
            o_presCutOffProf = o_subSurfacePres;
         end
      end
      if (isempty(o_subSurfacePres))
         % retrieve the CTD pump cut-off pressure from the configuration
         [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
         ctpPumpSwitchOffPres = get_config_value('CONFIG_PT20', configNames, configValues);
         if (~isempty(ctpPumpSwitchOffPres))
            % PT20 is CTD pump cut-off pressure we should add Poverlap = 0.5 dbar
            o_presCutOffProfConfig = ctpPumpSwitchOffPres + 0.5;
         else
            o_presCutOffProfConfig = 5 + 0.5;
         end
         o_presCutOffProf = o_presCutOffProfConfig;
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {213, 210, 211, 212, 214, 217, 222, 223, 225, 231, 232}
      if (~isempty(a_tabTech))

         % retrieve the last pumped PRES from the tech msg
         if (size(a_tabTech, 1) > 1)
            fprintf('WARNING: Float #%d cycle #%d: %d tech message in the buffer - using the last one\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, ...
               size(a_tabTech, 1));
         end
         o_tabTech = a_tabTech(end, :);
         pres = sensor_2_value_for_pressure_2xx_2_10_to_14_17_22_to_27_31_32(o_tabTech(16));
         temp = sensor_2_value_for_temp_2xx_4_to_14_17_19_20_22_to_27_31_32(o_tabTech(17));
         psal = o_tabTech(18)/1000;
         if (any([pres temp psal] ~= 0))
            % A specific bin is created after the pressure of the ‘subsurface point’
            % (PSubsurfacePoint).so that pumped and unpumped data are not mixed in the
            % bin-averaged output values.
            o_subSurfacePres = pres;
            o_presCutOffProf = o_subSurfacePres;
         end
      end
      if (isempty(o_subSurfacePres))
         % retrieve the CTD pump cut-off pressure from the configuration
         [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
         ctpPumpSwitchOffPres = get_config_value('CONFIG_PX02_', configNames, configValues);
         if (~isempty(ctpPumpSwitchOffPres))
            % PX02 is CTD pump cut-off pressure + Poverlap (0.5 dbar)
            o_presCutOffProfConfig = ctpPumpSwitchOffPres;
         else
            o_presCutOffProfConfig = 5 + 0.5;
         end
         o_presCutOffProf = o_presCutOffProfConfig;
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {216, 218, 228, 221, 230}
      if (~isempty(a_tabTech))

         % retrieve the last pumped PRES from the tech msg
         if (size(a_tabTech, 1) > 1)
            fprintf('WARNING: Float #%d cycle #%d: %d tech message in the buffer - using the last one\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, ...
               size(a_tabTech, 1));
         end
         o_tabTech = a_tabTech(end, :);
         pres = sensor_2_value_for_pressure_201_203_215_216_218_221_228_229_230(o_tabTech(11));
         temp = sensor_2_value_for_temp_2xx_1_to_3_15_16_18_21_28_29_30(o_tabTech(12));
         psal = o_tabTech(13)/1000;
         if (any([pres temp psal] ~= 0))
            % A specific bin is created after the pressure of the ‘subsurface point’
            % (PSubsurfacePoint).so that pumped and unpumped data are not mixed in the
            % bin-averaged output values.
            o_subSurfacePres = pres;
            o_presCutOffProf = o_subSurfacePres;
         end
      end
      if (isempty(o_subSurfacePres))
         % retrieve the CTD pump cut-off pressure from the configuration
         [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
         ctpPumpSwitchOffPres = get_config_value('CONFIG_PX02', configNames, configValues);
         if (~isempty(ctpPumpSwitchOffPres))
            % PX02 is CTD pump cut-off pressure + Poverlap (0.5 dbar)
            o_presCutOffProfConfig = ctpPumpSwitchOffPres;
         else
            o_presCutOffProfConfig = 5 + 0.5;
         end
         o_presCutOffProf = o_presCutOffProfConfig;
      end

   otherwise
      fprintf('ERROR: Float #%d: Nothing implemented yet to retrieve CTD pump cut-off pressure for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return