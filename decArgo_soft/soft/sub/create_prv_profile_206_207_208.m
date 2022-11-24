% ------------------------------------------------------------------------------
% Create the profiles.
%
% SYNTAX :
%  [o_descProfDate, o_descProfPres, o_descProfTemp, o_descProfSal, ...
%    o_descProfC1PhaseDoxy, o_descProfC2PhaseDoxy, o_descProfTempDoxy, ...
%    o_ascProfDate, o_ascProfPres, o_ascProfTemp, o_ascProfSal, ...
%    o_ascProfC1PhaseDoxy, o_ascProfC2PhaseDoxy, o_ascProfTempDoxy] = ...
%    create_prv_profile_206_207_208(a_dataCTDO, a_refDay)
%
% INPUT PARAMETERS :
%   a_dataCTDO : CTDO decoded data
%   a_refDay   : reference day (day of the first descent)
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
%   04/03/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_descProfDate, o_descProfPres, o_descProfTemp, o_descProfSal, ...
   o_descProfC1PhaseDoxy, o_descProfC2PhaseDoxy, o_descProfTempDoxy, ...
   o_ascProfDate, o_ascProfPres, o_ascProfTemp, o_ascProfSal, ...
   o_ascProfC1PhaseDoxy, o_ascProfC2PhaseDoxy, o_ascProfTempDoxy] = ...
   create_prv_profile_206_207_208(a_dataCTDO, a_refDay)

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


if (isempty(a_dataCTDO))
   return;
end

for idT = [1 3]
   idDesc = find(a_dataCTDO(:, 1) == idT);
   for idP = 1:length(idDesc)
      data = a_dataCTDO(idDesc(idP), :);
      for idMeas = 1:7
         if (idMeas == 1)
            data(idMeas+1) = data(idMeas+1) + a_refDay;
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
         
         if (idT == 1)
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

% sort the data by decreasing pressure
[o_descProfPres, idSorted] = sort(o_descProfPres, 'descend');
o_descProfDate = o_descProfDate(idSorted);
o_descProfTemp = o_descProfTemp(idSorted);
o_descProfSal = o_descProfSal(idSorted);
o_descProfC1PhaseDoxy = o_descProfC1PhaseDoxy(idSorted);
o_descProfC2PhaseDoxy = o_descProfC2PhaseDoxy(idSorted);
o_descProfTempDoxy = o_descProfTempDoxy(idSorted);

[o_ascProfPres, idSorted] = sort(o_ascProfPres, 'descend');
o_ascProfDate = o_ascProfDate(idSorted);
o_ascProfTemp = o_ascProfTemp(idSorted);
o_ascProfSal = o_ascProfSal(idSorted);
o_ascProfC1PhaseDoxy = o_ascProfC1PhaseDoxy(idSorted);
o_ascProfC2PhaseDoxy = o_ascProfC2PhaseDoxy(idSorted);
o_ascProfTempDoxy = o_ascProfTempDoxy(idSorted);

return;
