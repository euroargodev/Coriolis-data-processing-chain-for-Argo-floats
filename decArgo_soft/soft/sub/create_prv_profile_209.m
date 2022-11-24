% ------------------------------------------------------------------------------
% Create the profiles.
%
% SYNTAX :
%  [o_descProfDate, o_descProfPres, o_descProfTemp, o_descProfSal, ...
%    o_descProfC1PhaseDoxy, o_descProfC2PhaseDoxy, o_descProfTempDoxyAa, ...
%    o_descProfPhaseDelayDoxy, o_descProfTempDoxySbe, ...
%    o_ascProfDate, o_ascProfPres, o_ascProfTemp, o_ascProfSal, ...
%    o_ascProfC1PhaseDoxy, o_ascProfC2PhaseDoxy, o_ascProfTempDoxyAa, ...
%    o_ascProfPhaseDelayDoxy, o_ascProfTempDoxySbe] = ...
%    create_prv_profile_209(a_dataCTDO, a_refDay)
%
% INPUT PARAMETERS :
%   a_dataCTDO : CTDO decoded data
%   a_refDay   : reference day (day of the first descent)
%
% OUTPUT PARAMETERS :
%   o_descProfDate           : descending profile dates
%   o_descProfPres           : descending profile PRES
%   o_descProfTemp           : descending profile TEMP
%   o_descProfSal            : descending profile PSAL
%   o_descProfC1PhaseDoxy    : descending profile C1PHASE_DOXY
%   o_descProfC2PhaseDoxy    : descending profile C2PHASE_DOXY
%   o_descProfTempDoxyAa     : descending profile TEMP_DOXY (Aanderaa sensor)
%   o_descProfPhaseDelayDoxy : descending profile PHASE_DELAY_DOXY
%   o_descProfTempDoxySbe    : descending profile TEMP_DOXY (SBE sensor)
%   o_ascProfDate            : ascending profile dates
%   o_ascProfPres            : ascending profile PRES
%   o_ascProfTemp            : ascending profile TEMP
%   o_ascProfSal             : ascending profile PSAL
%   o_ascProfC1PhaseDoxy     : ascending profile C1PHASE_DOXY
%   o_ascProfC2PhaseDoxy     : ascending profile C2PHASE_DOXY
%   o_ascProfTempDoxyAa      : ascending profile TEMP_DOXY (Aanderaa sensor)
%   o_ascProfPhaseDelayDoxy  : ascending profile PHASE_DELAY_DOXY
%   o_ascProfTempDoxySbe     : ascending profile TEMP_DOXY (SBE sensor)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/03/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_descProfDate, o_descProfPres, o_descProfTemp, o_descProfSal, ...
   o_descProfC1PhaseDoxy, o_descProfC2PhaseDoxy, o_descProfTempDoxyAa, ...
   o_descProfPhaseDelayDoxy, o_descProfTempDoxySbe, ...
   o_ascProfDate, o_ascProfPres, o_ascProfTemp, o_ascProfSal, ...
   o_ascProfC1PhaseDoxy, o_ascProfC2PhaseDoxy, o_ascProfTempDoxyAa, ...
   o_ascProfPhaseDelayDoxy, o_ascProfTempDoxySbe] = ...
   create_prv_profile_209(a_dataCTDO, a_refDay)

% output parameters initialization
o_descProfDate = [];
o_descProfPres = [];
o_descProfTemp = [];
o_descProfSal = [];
o_descProfC1PhaseDoxy = [];
o_descProfC2PhaseDoxy = [];
o_descProfTempDoxyAa = [];
o_descProfPhaseDelayDoxy = [];
o_descProfTempDoxySbe = [];
o_ascProfDate = [];
o_ascProfPres = [];
o_ascProfTemp = [];
o_ascProfSal = [];
o_ascProfC1PhaseDoxy = [];
o_ascProfC2PhaseDoxy = [];
o_ascProfTempDoxyAa = [];
o_ascProfPhaseDelayDoxy = [];
o_ascProfTempDoxySbe = [];

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_c1C2PhaseDoxyDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_phaseDelayDoxyDef;


if (isempty(a_dataCTDO))
   return;
end

optodeType = unique(a_dataCTDO(:, end));
switch (optodeType)
   case 2
      % CTD only
      
      for type = [1 3]
         idForType = find(a_dataCTDO(:, 1) == type);
         for idP = 1:length(idForType)
            data = a_dataCTDO(idForType(idP), :);
            for idMeas = 1:15
               if (idMeas == 1)
                  data(idMeas+1) = data(idMeas+1) + a_refDay;
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
   case 1
      % CTD + Aanderaa 4330
      
      for type = [8 10]
         idForType = find(a_dataCTDO(:, 1) == type);
         for idP = 1:length(idForType)
            data = a_dataCTDO(idForType(idP), :);
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
               
               if (type == 8)
                  o_descProfDate = [o_descProfDate; data(idMeas+1)];
                  o_descProfPres = [o_descProfPres; data(idMeas+1+7*2)];
                  o_descProfTemp = [o_descProfTemp; data(idMeas+1+7*3)];
                  o_descProfSal = [o_descProfSal; data(idMeas+1+7*4)];
                  o_descProfC1PhaseDoxy = [o_descProfC1PhaseDoxy; data(idMeas+1+7*5)];
                  o_descProfC2PhaseDoxy = [o_descProfC2PhaseDoxy; data(idMeas+1+7*6)];
                  o_descProfTempDoxyAa = [o_descProfTempDoxyAa; data(idMeas+1+7*7)];
               else
                  o_ascProfDate = [o_ascProfDate; data(idMeas+1)];
                  o_ascProfPres = [o_ascProfPres; data(idMeas+1+7*2)];
                  o_ascProfTemp = [o_ascProfTemp; data(idMeas+1+7*3)];
                  o_ascProfSal = [o_ascProfSal; data(idMeas+1+7*4)];
                  o_ascProfC1PhaseDoxy = [o_ascProfC1PhaseDoxy; data(idMeas+1+7*5)];
                  o_ascProfC2PhaseDoxy = [o_ascProfC2PhaseDoxy; data(idMeas+1+7*6)];
                  o_ascProfTempDoxyAa = [o_ascProfTempDoxyAa; data(idMeas+1+7*7)];
               end
            end
         end
      end
   case 4
      % CTD + SBE 63
      
      for type = [11 13]
         idForType = find(a_dataCTDO(:, 1) == type);
         for idP = 1:length(idForType)
            data = a_dataCTDO(idForType(idP), :);
            for idMeas = 1:9
               if (idMeas == 1)
                  data(idMeas+1) = data(idMeas+1) + a_refDay;
               else
                  if ((data(idMeas+1+9*2) == g_decArgo_presDef) && ...
                        (data(idMeas+1+9*3) == g_decArgo_tempDef) && ...
                        (data(idMeas+1+9*4) == g_decArgo_salDef) && ...
                        (data(idMeas+1+9*5) == g_decArgo_phaseDelayDoxyDef) && ...
                        (data(idMeas+1+9*6) == g_decArgo_tempDoxyDef))
                     break;
                  end
               end
               
               if (type == 11)
                  o_descProfDate = [o_descProfDate; data(idMeas+1)];
                  o_descProfPres = [o_descProfPres; data(idMeas+1+9*2)];
                  o_descProfTemp = [o_descProfTemp; data(idMeas+1+9*3)];
                  o_descProfSal = [o_descProfSal; data(idMeas+1+9*4)];
                  o_descProfPhaseDelayDoxy = [o_descProfPhaseDelayDoxy; data(idMeas+1+9*5)];
                  o_descProfTempDoxySbe = [o_descProfTempDoxySbe; data(idMeas+1+9*6)];
               else
                  o_ascProfDate = [o_ascProfDate; data(idMeas+1)];
                  o_ascProfPres = [o_ascProfPres; data(idMeas+1+9*2)];
                  o_ascProfTemp = [o_ascProfTemp; data(idMeas+1+9*3)];
                  o_ascProfSal = [o_ascProfSal; data(idMeas+1+9*4)];
                  o_ascProfPhaseDelayDoxy = [o_ascProfPhaseDelayDoxy; data(idMeas+1+9*5)];
                  o_ascProfTempDoxySbe = [o_ascProfTempDoxySbe; data(idMeas+1+9*6)];
               end
            end
         end
      end
   case 5
      % CTD + Aanderaa 4330 + SBE 63
      
      for type = [14 16]
         idForType = find(a_dataCTDO(:, 1) == type);
         for idP = 1:length(idForType)
            data = a_dataCTDO(idForType(idP), :);
            for idMeas = 1:5
               if (idMeas == 1)
                  data(idMeas+1) = data(idMeas+1) + a_refDay;
               else
                  if ((data(idMeas+1+5*2) == g_decArgo_presDef) && ...
                        (data(idMeas+1+5*3) == g_decArgo_tempDef) && ...
                        (data(idMeas+1+5*4) == g_decArgo_salDef) && ...
                        (data(idMeas+1+5*5) == g_decArgo_c1C2PhaseDoxyDef) && ...
                        (data(idMeas+1+5*6) == g_decArgo_c1C2PhaseDoxyDef) && ...
                        (data(idMeas+1+5*7) == g_decArgo_tempDoxyDef) && ...
                        (data(idMeas+1+5*8) == g_decArgo_phaseDelayDoxyDef) && ...
                        (data(idMeas+1+5*9) == g_decArgo_tempDoxyDef))
                     break;
                  end
               end
               
               if (type == 14)
                  o_descProfDate = [o_descProfDate; data(idMeas+1)];
                  o_descProfPres = [o_descProfPres; data(idMeas+1+5*2)];
                  o_descProfTemp = [o_descProfTemp; data(idMeas+1+5*3)];
                  o_descProfSal = [o_descProfSal; data(idMeas+1+5*4)];
                  o_descProfC1PhaseDoxy = [o_descProfC1PhaseDoxy; data(idMeas+1+5*5)];
                  o_descProfC2PhaseDoxy = [o_descProfC2PhaseDoxy; data(idMeas+1+5*6)];
                  o_descProfTempDoxyAa = [o_descProfTempDoxyAa; data(idMeas+1+5*7)];
                  o_descProfPhaseDelayDoxy = [o_descProfPhaseDelayDoxy; data(idMeas+1+5*8)];
                  o_descProfTempDoxySbe = [o_descProfTempDoxySbe; data(idMeas+1+5*9)];
               else
                  o_ascProfDate = [o_ascProfDate; data(idMeas+1)];
                  o_ascProfPres = [o_ascProfPres; data(idMeas+1+5*2)];
                  o_ascProfTemp = [o_ascProfTemp; data(idMeas+1+5*3)];
                  o_ascProfSal = [o_ascProfSal; data(idMeas+1+5*4)];
                  o_ascProfC1PhaseDoxy = [o_ascProfC1PhaseDoxy; data(idMeas+1+5*5)];
                  o_ascProfC2PhaseDoxy = [o_ascProfC2PhaseDoxy; data(idMeas+1+5*6)];
                  o_ascProfTempDoxyAa = [o_ascProfTempDoxyAa; data(idMeas+1+5*7)];
                  o_ascProfPhaseDelayDoxy = [o_ascProfPhaseDelayDoxy; data(idMeas+1+5*8)];
                  o_ascProfTempDoxySbe = [o_ascProfTempDoxySbe; data(idMeas+1+5*9)];
               end
            end
         end
      end
   otherwise
      fprintf('WARNING: Nothing done yet for optode type #%d\n', ...
         optodeType);
end

% sort the data by decreasing pressure
[o_descProfPres, idSorted] = sort(o_descProfPres, 'descend');
o_descProfDate = o_descProfDate(idSorted);
o_descProfTemp = o_descProfTemp(idSorted);
o_descProfSal = o_descProfSal(idSorted);
if (~isempty(o_descProfC1PhaseDoxy))
   o_descProfC1PhaseDoxy = o_descProfC1PhaseDoxy(idSorted);
   o_descProfC2PhaseDoxy = o_descProfC2PhaseDoxy(idSorted);
   o_descProfTempDoxyAa = o_descProfTempDoxyAa(idSorted);
end
if (~isempty(o_descProfPhaseDelayDoxy))
   o_descProfPhaseDelayDoxy = o_descProfPhaseDelayDoxy(idSorted);
   o_descProfTempDoxySbe = o_descProfTempDoxySbe(idSorted);
end

[o_ascProfPres, idSorted] = sort(o_ascProfPres, 'descend');
o_ascProfDate = o_ascProfDate(idSorted);
o_ascProfTemp = o_ascProfTemp(idSorted);
o_ascProfSal = o_ascProfSal(idSorted);
if (~isempty(o_ascProfC1PhaseDoxy))
   o_ascProfC1PhaseDoxy = o_ascProfC1PhaseDoxy(idSorted);
   o_ascProfC2PhaseDoxy = o_ascProfC2PhaseDoxy(idSorted);
   o_ascProfTempDoxyAa = o_ascProfTempDoxyAa(idSorted);
end
if (~isempty(o_ascProfPhaseDelayDoxy))
   o_ascProfPhaseDelayDoxy = o_ascProfPhaseDelayDoxy(idSorted);
   o_ascProfTempDoxySbe = o_ascProfTempDoxySbe(idSorted);
end

return;
