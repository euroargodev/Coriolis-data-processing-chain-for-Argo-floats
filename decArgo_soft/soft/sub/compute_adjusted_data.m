% ------------------------------------------------------------------------------
% Compute the RT adjusted values of a parameter data.
%
% SYNTAX :
%  [o_adjData] = compute_adjusted_data(a_data, a_param, a_profile)
%
% INPUT PARAMETERS :
%   a_data    : input data
%   a_param   : concerned parameter information
%   a_profile : concerned profile information
%
% OUTPUT PARAMETERS :
%   o_adjData : output adjusted data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/22/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_adjData] = compute_adjusted_data(a_data, a_param, a_profile)

% output parameters initialization
o_adjData = [];

% current float WMO number
global g_decArgo_floatNum;

% global default values
global g_decArgo_dateDef;
global g_decArgo_nbHourForProfDateCompInRtOffsetAdj;

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;

                  
for idF = 1:length(g_decArgo_rtOffsetInfo.param)
   if (strcmp(g_decArgo_rtOffsetInfo.param{idF}, a_param.name) == 1)
      tabSlope = g_decArgo_rtOffsetInfo.slope{idF};
      tabValue = g_decArgo_rtOffsetInfo.value{idF};
      tabDate = g_decArgo_rtOffsetInfo.date{idF};
      if (a_profile.date ~= g_decArgo_dateDef)
         idD = find((a_profile.date - g_decArgo_nbHourForProfDateCompInRtOffsetAdj/24) >= tabDate);
         if (~isempty(idD))
            slopeValue = tabSlope(idD(end));
            offsetValue = tabValue(idD(end));
            
            o_adjData = a_data;
            idNoDef = find(o_adjData ~= a_param.fillValue);
            o_adjData(idNoDef) = o_adjData(idNoDef)*slopeValue + offsetValue;
         end
      else
         fprintf('RTADJ_WARNING: Float #%d Cycle #%d Profile #%d: profile not dated => RT offset cannot be applied\n', ...
            g_decArgo_floatNum, a_profile.cycleNumber, a_profile.profileNumber);
      end
      break
   end
end

return
