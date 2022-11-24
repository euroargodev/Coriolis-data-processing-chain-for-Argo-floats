% ------------------------------------------------------------------------------
% Check if the provided profile has RT adjustment to be performed;
%
% SYNTAX :
%  [o_adjExist] = rt_adjusment_exist(a_profile, a_coreDataFlag)
%
% INPUT PARAMETERS :
%   a_profile      : concerned profile information
%   a_coreDataFlag : core data flag (1 if core data is concerned, 0 otherwise)
%
% OUTPUT PARAMETERS :
%   o_adjExist : 1 if the profile has RT adjustments, 0 otherwise
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/16/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_adjExist] = rt_adjusment_exist(a_profile, a_coreDataFlag)

% output parameters initialization
o_adjExist = 0;

% global default values
global g_decArgo_dateDef;
global g_decArgo_nbHourForProfDateCompInRtOffsetAdj;

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;


% search if this profile need to be RT adjusted
if (~isempty(g_decArgo_rtOffsetInfo))
   parameterList = a_profile.paramList;
   for idParam = 1:length(parameterList)
      
      profParam = parameterList(idParam);
      if (((a_coreDataFlag == 1) && (profParam.adjAllowed == 1)) || ...
            ((a_coreDataFlag == 0) && (profParam.adjAllowed == 1) && (profParam.paramType ~= 'c')))
         
         for idF = 1:length(g_decArgo_rtOffsetInfo.param)
            if (strcmp(g_decArgo_rtOffsetInfo.param{idF}, profParam.name) == 1)
               tabDate = g_decArgo_rtOffsetInfo.date{idF};
               if (a_profile.date ~= g_decArgo_dateDef)
                  idD = find((a_profile.date - g_decArgo_nbHourForProfDateCompInRtOffsetAdj/24) >= tabDate);
                  if (~isempty(idD))
                     o_adjExist = 1;
                     return;
                  end
               end
            end
         end
         
      end
   end
end
                  
return;
