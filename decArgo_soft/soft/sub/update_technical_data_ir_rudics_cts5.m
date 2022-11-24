% ------------------------------------------------------------------------------
% Update technical data (add float cycle and pattern number to the NetCDF
% technical data).
% 
% SYNTAX :
%  [o_techNcParamIndex, o_techNcParamValue] = ...
%    update_technical_data_ir_rudics_cts5(a_techNcParamIndex, a_techNcParamValue, a_firstCycleNum, a_decoderId)
% 
% INPUT PARAMETERS :
%   a_techNcParamIndex : input technical index information
%   a_techNcParamValue : input technical data
%   a_firstCycleNum    : first cycle to consider
%   a_decoderId        : float decoder Id
% 
% OUTPUT PARAMETERS :
%   o_techNcParamIndex : output technical index information
%   o_techNcParamValue : output technical data
% 
% EXAMPLES :
% 
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_techNcParamIndex, o_techNcParamValue] = ...
   update_technical_data_ir_rudics_cts5(a_techNcParamIndex, a_techNcParamValue, a_firstCycleNum, a_decoderId)

% output parameters initialization
o_techNcParamIndex = a_techNcParamIndex;
o_techNcParamValue = a_techNcParamValue;

% float configuration
global g_decArgo_floatConfig;


if (~isempty(o_techNcParamIndex))
   
   outputCyNumList = unique(o_techNcParamIndex(:, 6));
   for idC = 1:length(outputCyNumList)
      floatCyNum = unique(o_techNcParamIndex(find(o_techNcParamIndex(:, 6) == outputCyNumList(idC)), 2));
      floatPtnNum = unique(o_techNcParamIndex(find(o_techNcParamIndex(:, 6) == outputCyNumList(idC)), 3));
      if ((length(floatCyNum) == 1) && (length(floatPtnNum) == 1))
         % nominal case
         o_techNcParamIndex = cat(1, ...
            o_techNcParamIndex, ...
            [-1 floatCyNum floatPtnNum 0 101 outputCyNumList(idC)]);
         o_techNcParamValue{end+1} = num2str(floatCyNum);
         if (floatPtnNum ~= -1)
            o_techNcParamIndex = cat(1, ...
               o_techNcParamIndex, ...
               [-1 floatCyNum floatPtnNum 0 100 outputCyNumList(idC)]);
            o_techNcParamValue{end+1} = num2str(floatPtnNum);
         end
      else
         if ((length(floatCyNum) == 1) && (floatCyNum == a_firstCycleNum))
            % nominal case for the first cycle
            floatPtnNum(find(floatPtnNum == -1)) = 0;
            floatPtnNum = unique(floatPtnNum);
            o_techNcParamIndex = cat(1, ...
               o_techNcParamIndex, ...
               [-1 floatCyNum floatPtnNum 0 101 outputCyNumList(idC)]);
            o_techNcParamValue{end+1} = num2str(floatCyNum);
            o_techNcParamIndex = cat(1, ...
               o_techNcParamIndex, ...
               [-1 floatCyNum floatPtnNum 0 100 outputCyNumList(idC)]);
            o_techNcParamValue{end+1} = num2str(floatPtnNum);
         else
            % anomaly, the float has been reset: we assign all surface
            % information to a dedicated cycle
            floatPtnNum = 0;
            for id = 1:length(floatCyNum)
               o_techNcParamIndex = cat(1, ...
                  o_techNcParamIndex, ...
                  [-1 floatCyNum(id) floatPtnNum 0 101 outputCyNumList(idC)]);
               o_techNcParamValue{end+1} = num2str(floatCyNum(id));
            end
            o_techNcParamIndex = cat(1, ...
               o_techNcParamIndex, ...
               [-1 floatCyNum(1) floatPtnNum 0 100 outputCyNumList(idC)]);
            o_techNcParamValue{end+1} = num2str(floatPtnNum);
         end
      end
   end

   % set Ice detected bit in TECH data

   configName = g_decArgo_floatConfig.DYNAMIC.NAMES;
   configValue = g_decArgo_floatConfig.DYNAMIC.VALUES;
   % check if Ice algorithm is started
   if (any(strcmp(configName, 'CONFIG_APMT_ICE_AVOIDANCE_P00')))
      idF = find(strcmp(configName, 'CONFIG_APMT_ICE_AVOIDANCE_P00'));
      if (any(configValue(idF, :) == 1))

         [o_techNcParamIndex, o_techNcParamValue] = ...
            add_ice_detected_bit_value_cts5(o_techNcParamIndex, o_techNcParamValue, a_decoderId);
      end
   end
end

return

% ------------------------------------------------------------------------------
% Create the list of ice detected cycles summarized in 8 bits (LSB is the
% current cycle).
%
% SYNTAX :
%  [o_techNcParamIndex, o_techNcParamValue] = ...
%    add_ice_detected_bit_value_cts5(a_techNcParamIndex, a_techNcParamValue, a_decoderId)
%
% INPUT PARAMETERS :
%   a_techNcParamIndex : input technical index information
%   a_techNcParamValue : input technical data
%   a_decoderId        : float decoder Id
% 
% OUTPUT PARAMETERS :
%   o_techNcParamIndex : output technical index information
%   o_techNcParamValue : output technical data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/22/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_techNcParamIndex, o_techNcParamValue] = ...
   add_ice_detected_bit_value_cts5(a_techNcParamIndex, a_techNcParamValue, a_decoderId)

% output parameters initialization
o_techNcParamIndex = a_techNcParamIndex;
o_techNcParamValue = a_techNcParamValue;

% compute Ice detection bit
cycleNumList = unique(o_techNcParamIndex(:, 6));
for idC = 1:length(cycleNumList)
   iceDetectedBitValueBin = '';
   cyNum = cycleNumList(idC);
   for id = 0:7
      idFCy = find(o_techNcParamIndex(:, 6) == cyNum-id);
      if (~isempty(idFCy))
         if (any(o_techNcParamIndex(idFCy, 5) == 213)) % NC techId for PRES_IceAvoidance_dbar
            iceDetectedBitValueBin = ['1' iceDetectedBitValueBin];
         else
            iceDetectedBitValueBin = ['0' iceDetectedBitValueBin];
         end
      else
         iceDetectedBitValueBin = ['0' iceDetectedBitValueBin];
      end
   end
   idFCyRef = find(o_techNcParamIndex(:, 6) == cyNum, 1);
   techNcParamIndexNew = o_techNcParamIndex(idFCyRef, :);
   techNcParamIndexNew(4) = 0;
   techNcParamIndexNew(5) = 249;
   o_techNcParamIndex = cat(1, o_techNcParamIndex, techNcParamIndexNew);
   o_techNcParamValue{end+1} = iceDetectedBitValueBin;
end

return
