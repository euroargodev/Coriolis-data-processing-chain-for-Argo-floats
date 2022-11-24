% ------------------------------------------------------------------------------
% Create the final configuration that will be used in the meta.nc file.
%
% SYNTAX :
%  [o_ncConfig] = create_output_float_config_ir_sbd( ...
%    a_decArgoConfParamNames, a_ncConfParamNames, a_decoderId)
%
% INPUT PARAMETERS :
%   a_decArgoConfParamNames : internal configuration parameter names
%   a_ncConfParamNames      : NetCDF configuration parameter names
%   a_decoderId             : float decoder Id
%
% OUTPUT PARAMETERS :
% o_ncConfig : NetCDF configuration
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncConfig] = create_output_float_config_ir_sbd( ...
   a_decArgoConfParamNames, a_ncConfParamNames, a_decoderId)

% output parameters initialization
o_ncConfig = [];

% float configuration
global g_decArgo_floatConfig;

% current float WMO number
global g_decArgo_floatNum;

% to detect ICE mode activation
global g_decArgo_7TypePacketReceivedCyNum;


% current configuration
inputConfigNum = g_decArgo_floatConfig.DYNAMIC.NUMBER;
inputConfigName = g_decArgo_floatConfig.DYNAMIC.NAMES;
inputConfigValue = g_decArgo_floatConfig.DYNAMIC.VALUES;

% final configuration
finalConfigNum = inputConfigNum;
finalConfigName = inputConfigName;
finalConfigValue = inputConfigValue;

switch (a_decoderId)
   
   case {2001, 2002, 2003}
      
      % nothing for Nova floats

   case {201, 202, 203, 204, 205, 206, 208, 209, 215, 216, 218, 221}
      
      % use CONFIG_PT20 to fill CONFIG_PX02 = CONFIG_PT20 + 0.5
      idPos1 = find(strcmp(finalConfigName, 'CONFIG_PT20') == 1, 1);
      idPos2 = find(strcmp(finalConfigName, 'CONFIG_PX02') == 1, 1);
      if (~isempty(idPos1) && ~isempty(idPos2))
         finalConfigValue(idPos2, :) = finalConfigValue(idPos1, :);
         idNoNan = find(~isnan(finalConfigValue(idPos2, :)));
         finalConfigValue(idPos2, idNoNan) = finalConfigValue(idPos2, idNoNan) + 0.5;
      end
      
      if (a_decoderId == 216)
         
         % ice mode is supposed to be activated
         
         % if ice detection is used for at least one cycle, set ice float mandatory
         % parameter (CONFIG_BitMaskMonthsIceDetectionActive_NUMBER) to 4095
         idPos1 = find(strcmp(finalConfigName, 'CONFIG_PG00') == 1, 1);
         idPos2 = find(strcmp(finalConfigName, 'CONFIG_PX05') == 1, 1);
         if (~isempty(idPos1) && ~isempty(idPos2))
            iceUsed = finalConfigValue(idPos1, :);
            if (any(~isnan(iceUsed) | (iceUsed ~= 0)))
               finalConfigValue(idPos2, :) = 4095;
            end
         end
         
      elseif (ismember(a_decoderId, [218 221]))

         if (~isempty(g_decArgo_7TypePacketReceivedCyNum))
            
            % when ice mode is activated
            
            % if ice detection is used for at least one cycle, set ice float mandatory
            % parameter (CONFIG_BitMaskMonthsIceDetectionActive_NUMBER) to 4095
            idPos1 = find(strcmp(finalConfigName, 'CONFIG_PG00') == 1, 1);
            idPos2 = find(strcmp(finalConfigName, 'CONFIG_PX05') == 1, 1);
            if (~isempty(idPos1) && ~isempty(idPos2))
               iceUsed = finalConfigValue(idPos1, :);
               if (any(~isnan(iceUsed) | (iceUsed ~= 0)))
                  finalConfigValue(idPos2, :) = 4095;
               end
            end
            
            %             % when ice detection is used, replace TC19 by IC10
            %             idPos1 = find(strcmp(finalConfigName, 'CONFIG_IC00_') == 1, 1);
            %             idPos2 = find(strcmp(finalConfigName, 'CONFIG_TC19_') == 1, 1);
            %             idPos3 = find(strcmp(finalConfigName, 'CONFIG_IC10_') == 1, 1);
            %             if (~isempty(idPos1) && ~isempty(idPos2))
            %                iceUsed = finalConfigValue(idPos1, :);
            %                idF = find(iceUsed ~= 0);
            %                finalConfigValue(idPos2, idF) = finalConfigValue(idPos3, idF);
            %                finalConfigValue(idPos3, :) = nan;
            %             end
         else
            
            % when ice mode is not activated
            
            % remove ice configuration parameters from final configuration
            idDel = [];
            for id = 0:15
               name = sprintf('CONFIG_PG%02d', id);
               idPos = find(strcmp(finalConfigName, name) == 1, 1);
               if (~isempty(idPos))
                  idDel = [idDel; idPos];
               end
            end
            finalConfigName(idDel) = [];
            finalConfigValue(idDel, :) = [];
         end
      end
      
   case {210, 211, 213}
      
      % use CONFIG_MC28 to fill CONFIG_PX02 = CONFIG_MC28 + 0.5
      idPos1 = find(strcmp(finalConfigName, 'CONFIG_MC28_') == 1, 1);
      idPos2 = find(strcmp(finalConfigName, 'CONFIG_PX02_') == 1, 1);
      if (~isempty(idPos1) && ~isempty(idPos2))
         finalConfigValue(idPos2, :) = finalConfigValue(idPos1, :);
         idNoNan = find(~isnan(finalConfigValue(idPos2, :)));
         finalConfigValue(idPos2, idNoNan) = finalConfigValue(idPos2, idNoNan) + 0.5;
      end
      
   case {212, 222, 214, 217, 223}
      
      % use CONFIG_MC28 to fill CONFIG_PX02 = CONFIG_MC28 + 0.5
      idPos1 = find(strcmp(finalConfigName, 'CONFIG_MC28_') == 1, 1);
      idPos2 = find(strcmp(finalConfigName, 'CONFIG_PX02_') == 1, 1);
      if (~isempty(idPos1) && ~isempty(idPos2))
         finalConfigValue(idPos2, :) = finalConfigValue(idPos1, :);
         idNoNan = find(~isnan(finalConfigValue(idPos2, :)));
         finalConfigValue(idPos2, idNoNan) = finalConfigValue(idPos2, idNoNan) + 0.5;
      end
      
      if (~isempty(g_decArgo_7TypePacketReceivedCyNum))
         
         % when ice mode is activated
         
         % if ice detection is used for at least one cycle, set ice float mandatory
         % parameter (CONFIG_BitMaskMonthsIceDetectionActive_NUMBER) to 4095
         idPos1 = find(strcmp(finalConfigName, 'CONFIG_IC00_') == 1, 1);
         if (ismember(a_decoderId, [212, 222, 223]))
            idPos2 = find(strcmp(finalConfigName, 'CONFIG_PX03_') == 1, 1);
         else
            idPos2 = find(strcmp(finalConfigName, 'CONFIG_PX05_') == 1, 1);
         end
         if (~isempty(idPos1) && ~isempty(idPos2))
            iceUsed = finalConfigValue(idPos1, :);
            if (any(~isnan(iceUsed) | (iceUsed ~= 0)))
               finalConfigValue(idPos2, :) = 4095;
            end
         end
         
         % when ice detection is used, replace TC19 by IC10
         idPos1 = find(strcmp(finalConfigName, 'CONFIG_IC00_') == 1, 1);
         idPos2 = find(strcmp(finalConfigName, 'CONFIG_TC19_') == 1, 1);
         idPos3 = find(strcmp(finalConfigName, 'CONFIG_IC10_') == 1, 1);
         if (~isempty(idPos1) && ~isempty(idPos2))
            iceUsed = finalConfigValue(idPos1, :);
            idF = find(iceUsed ~= 0);
            finalConfigValue(idPos2, idF) = finalConfigValue(idPos3, idF);
            finalConfigValue(idPos3, :) = nan;
         end
      else
         
         % when ice mode is not activated
         
         % remove ice configuration parameters from final configuration
         idDel = [];
         for id = 0:15
            name = sprintf('CONFIG_IC%02d_', id);
            idPos = find(strcmp(finalConfigName, name) == 1, 1);
            if (~isempty(idPos))
               idDel = [idDel; idPos];
            end
         end
         finalConfigName(idDel) = [];
         finalConfigValue(idDel, :) = [];
      end
      
   case {224}
            
      if (~isempty(g_decArgo_7TypePacketReceivedCyNum))
         
         % when ice mode is activated
         
         % if ice detection is used for at least one cycle, set ice float mandatory
         % parameter (CONFIG_BitMaskMonthsIceDetectionActive_NUMBER) to 4095
         idPos1 = find(strcmp(finalConfigName, 'CONFIG_IC00_') == 1, 1);
         idPos2 = find(strcmp(finalConfigName, 'CONFIG_PX03_') == 1, 1);
         if (~isempty(idPos1) && ~isempty(idPos2))
            iceUsed = finalConfigValue(idPos1, :);
            if (any(~isnan(iceUsed) | (iceUsed ~= 0)))
               finalConfigValue(idPos2, :) = 4095;
            end
         end
         
         % when ice detection is used, replace TC19 by IC10
         idPos1 = find(strcmp(finalConfigName, 'CONFIG_IC00_') == 1, 1);
         idPos2 = find(strcmp(finalConfigName, 'CONFIG_TC19_') == 1, 1);
         idPos3 = find(strcmp(finalConfigName, 'CONFIG_IC10_') == 1, 1);
         if (~isempty(idPos1) && ~isempty(idPos2))
            iceUsed = finalConfigValue(idPos1, :);
            idF = find(iceUsed ~= 0);
            finalConfigValue(idPos2, idF) = finalConfigValue(idPos3, idF);
            finalConfigValue(idPos3, :) = nan;
         end
      else
         
         % when ice mode is not activated
         
         % remove ice configuration parameters from final configuration
         idDel = [];
         for id = 0:15
            name = sprintf('CONFIG_IC%02d_', id);
            idPos = find(strcmp(finalConfigName, name) == 1, 1);
            if (~isempty(idPos))
               idDel = [idDel; idPos];
            end
         end
         finalConfigName(idDel) = [];
         finalConfigValue(idDel, :) = [];
      end
      
   case {219, 220}
      
      % nothing for Arvor-C floats
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet to create output configuration parameters for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

% delete the unused configuration parameters
idDel = [];
for idL = 1:size(finalConfigValue, 1)
   if (sum(isnan(finalConfigValue(idL, :))) == size(finalConfigValue, 2))
      idDel = [idDel; idL];
   end
end
finalConfigName(idDel) = [];
finalConfigValue(idDel, :) = [];

% static configuration parameters
staticConfigName = g_decArgo_floatConfig.STATIC.NAMES;
staticConfigValue = g_decArgo_floatConfig.STATIC.VALUES;

% convert decoder names into NetCDF ones
if (~isempty(a_decArgoConfParamNames))
   idDel = [];
   for idConfParam = 1:length(staticConfigName)
      idF = find(strcmp(staticConfigName{idConfParam}, a_decArgoConfParamNames) == 1);
      if (~isempty(idF))
         staticConfigName{idConfParam} = a_ncConfParamNames{idF};
      else
         % some of the managed parameters are not saved in the meta.nc file
         idDel = [idDel; idConfParam];
         %          fprintf('ERROR: Float #%d: Cannot convert configuration param name :''%s'' into NetCDF one\n', ...
         %             g_decArgo_floatNum, ...
         %             staticConfigName{idConfParam});
      end
   end
   staticConfigName(idDel) = [];
   staticConfigValue(idDel, :) = [];
   
   idDel = [];
   for idConfParam = 1:length(finalConfigName)
      idF = find(strcmp(finalConfigName{idConfParam}, a_decArgoConfParamNames) == 1);
      if (~isempty(idF))
         finalConfigName{idConfParam} = a_ncConfParamNames{idF};
      else
         % some of the managed parameters are not saved in the meta.nc file
         idDel = [idDel; idConfParam];
         %          fprintf('ERROR: Float #%d: Cannot convert configuration param name :''%s'' into NetCDF one\n', ...
         %             g_decArgo_floatNum, ...
         %             finalConfigName{idConfParam});
      end
   end
   finalConfigName(idDel) = [];
   finalConfigValue(idDel, :) = [];
end

% output data
o_ncConfig.STATIC_NC.NAMES = staticConfigName;
o_ncConfig.STATIC_NC.VALUES = staticConfigValue;
o_ncConfig.DYNAMIC_NC.NUMBER = finalConfigNum;
o_ncConfig.DYNAMIC_NC.NAMES = finalConfigName;
o_ncConfig.DYNAMIC_NC.VALUES = finalConfigValue;

return
