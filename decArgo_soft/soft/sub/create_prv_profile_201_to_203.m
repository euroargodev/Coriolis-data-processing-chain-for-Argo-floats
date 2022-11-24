% ------------------------------------------------------------------------------
% Create the profiles.
%
% SYNTAX :
%  [o_descProfDate, o_descProfPres, o_descProfTemp, o_descProfSal, ...
%    o_descProfC1PhaseDoxy, o_descProfC2PhaseDoxy, o_descProfTempDoxy, ...
%    o_ascProfDate, o_ascProfPres, o_ascProfTemp, o_ascProfSal, ...
%    o_ascProfC1PhaseDoxy, o_ascProfC2PhaseDoxy, o_ascProfTempDoxy] = ...
%    create_prv_profile_201_to_203(a_dataCTD, a_dataCTDO)
%
% INPUT PARAMETERS :
%   a_dataCTD  : decoded data of the CTD sensor
%   a_dataCTDO : decoded data of the CTD + Optode sensor
%
% OUTPUT PARAMETERS :
%   o_descProfDate        : descending profile dates
%   o_descProfPres        : descending profile PRES
%   o_descProfTemp        : descending profile TEMP
%   o_descProfSal         : descending profile PSAL
%   o_descProfC1PhaseDoxy : descending profile C1PHASE_DOXY
%   o_descProfC2PhaseDoxy : descending profile C2PHASE_DOXY
%   o_descProfTempDoxy    : descending profile TEMP_DOXY
%   o_ascProfDate         : ascending profile dates
%   o_ascProfPres         : ascending profile PRES
%   o_ascProfTemp         : ascending profile TEMP
%   o_ascProfSal          : ascending profile PSAL
%   o_ascProfC1PhaseDoxy  : ascending profile C1PHASE_DOXY
%   o_ascProfC2PhaseDoxy  : ascending profile C2PHASE_DOXY
%   o_ascProfTempDoxy     : ascending profile TEMP_DOXY
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_descProfDate, o_descProfPres, o_descProfTemp, o_descProfSal, ...
   o_descProfC1PhaseDoxy, o_descProfC2PhaseDoxy, o_descProfTempDoxy, ...
   o_ascProfDate, o_ascProfPres, o_ascProfTemp, o_ascProfSal, ...
   o_ascProfC1PhaseDoxy, o_ascProfC2PhaseDoxy, o_ascProfTempDoxy] = ...
   create_prv_profile_201_to_203(a_dataCTD, a_dataCTDO)

% output parameters initialization
o_descProfDate = [];
o_descProfPres = [];
o_descProfTemp = [];
o_descProfSal = [];
o_descProfC1PhaseDoxy = [];
o_descProfC2PhaseDoxy = [];
o_descProfTempDoxy = [];
o_ascProfDate = [];
o_ascProfPres = [];
o_ascProfTemp = [];
o_ascProfSal = [];
o_ascProfC1PhaseDoxy = [];
o_ascProfC2PhaseDoxy = [];
o_ascProfTempDoxy = [];

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_c1C2PhaseDoxyDef;
global g_decArgo_tempDoxyDef;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;


if (~isempty(a_dataCTD))
   for type = [1 3]
      idForType = find(a_dataCTD(:, 1) == type);
      for idP = 1:length(idForType)
         data = a_dataCTD(idForType(idP), :);
         for idMeas = 1:15
            if (idMeas == 1)
               data(idMeas+1) = data(idMeas+1) + g_decArgo_julD2FloatDayOffset;
            else
               if ((data(idMeas+1+15*2) == g_decArgo_presDef) && ...
                     (data(idMeas+1+15*3) == g_decArgo_tempDef) && ...
                     (data(idMeas+1+15*4) == g_decArgo_salDef))
                  break;
               end
            end
            
            if (type == 1)
               o_descProfDate = [o_descProfDate; data(idMeas+1)];
               o_descProfPres = [o_descProfPres; data(idMeas+1+15*2)];
               o_descProfTemp = [o_descProfTemp; data(idMeas+1+15*3)];
               o_descProfSal = [o_descProfSal; data(idMeas+1+15*4)];
            else
               o_ascProfDate = [o_ascProfDate; data(idMeas+1)];
               o_ascProfPres = [o_ascProfPres; data(idMeas+1+15*2)];
               o_ascProfTemp = [o_ascProfTemp; data(idMeas+1+15*3)];
               o_ascProfSal = [o_ascProfSal; data(idMeas+1+15*4)];
            end
         end
      end
   end
end

if (~isempty(a_dataCTDO))
   for type = [8 10]
      idForType = find(a_dataCTDO(:, 1) == type);
      for idP = 1:length(idForType)
         data = a_dataCTDO(idForType(idP), :);
         for idMeas = 1:7
            if (idMeas == 1)
               data(idMeas+1) = data(idMeas+1) + g_decArgo_julD2FloatDayOffset;
            else
               if ((data(idMeas+1+7*2) == g_decArgo_presDef) && ...
                     (data(idMeas+1+7*3) == g_decArgo_tempDef) && ...
                     (data(idMeas+1+7*4) == g_decArgo_salDef) && ...
                     (data(idMeas+1+7*5) == g_decArgo_c1C2PhaseDoxyDef) && ...
                     (data(idMeas+1+7*6) == g_decArgo_c1C2PhaseDoxyDef) && ...
                     (data(idMeas+1+7*7) == g_decArgo_tempDoxyDef))
                  break;
               end
            end
            
            if (type == 8)
               o_descProfDate = [o_descProfDate; data(idMeas+1)];
               o_descProfPres = [o_descProfPres; data(idMeas+1+7*2)];
               o_descProfTemp = [o_descProfTemp; data(idMeas+1+7*3)];
               o_descProfSal = [o_descProfSal; data(idMeas+1+7*4)];
               o_descProfC1PhaseDoxy = [o_descProfC1PhaseDoxy; data(idMeas+1+7*5)];
               o_descProfC2PhaseDoxy = [o_descProfC2PhaseDoxy; data(idMeas+1+7*6)];
               o_descProfTempDoxy = [o_descProfTempDoxy; data(idMeas+1+7*7)];
            else
               o_ascProfDate = [o_ascProfDate; data(idMeas+1)];
               o_ascProfPres = [o_ascProfPres; data(idMeas+1+7*2)];
               o_ascProfTemp = [o_ascProfTemp; data(idMeas+1+7*3)];
               o_ascProfSal = [o_ascProfSal; data(idMeas+1+7*4)];
               o_ascProfC1PhaseDoxy = [o_ascProfC1PhaseDoxy; data(idMeas+1+7*5)];
               o_ascProfC2PhaseDoxy = [o_ascProfC2PhaseDoxy; data(idMeas+1+7*6)];
               o_ascProfTempDoxy = [o_ascProfTempDoxy; data(idMeas+1+7*7)];
            end
         end
      end
   end
end

% sort the data by decreasing pressure
[o_descProfPres, idSorted] = sort(o_descProfPres, 'descend');
o_descProfDate = o_descProfDate(idSorted);
o_descProfTemp = o_descProfTemp(idSorted);
o_descProfSal = o_descProfSal(idSorted);
if (~isempty(a_dataCTDO))
   o_descProfC1PhaseDoxy = o_descProfC1PhaseDoxy(idSorted);
   o_descProfC2PhaseDoxy = o_descProfC2PhaseDoxy(idSorted);
   o_descProfTempDoxy = o_descProfTempDoxy(idSorted);
end

[o_ascProfPres, idSorted] = sort(o_ascProfPres, 'descend');
o_ascProfDate = o_ascProfDate(idSorted);
o_ascProfTemp = o_ascProfTemp(idSorted);
o_ascProfSal = o_ascProfSal(idSorted);
if (~isempty(a_dataCTDO))
   o_ascProfC1PhaseDoxy = o_ascProfC1PhaseDoxy(idSorted);
   o_ascProfC2PhaseDoxy = o_ascProfC2PhaseDoxy(idSorted);
   o_ascProfTempDoxy = o_ascProfTempDoxy(idSorted);
end

return;
