% ------------------------------------------------------------------------------
% Create the drift measurements and add their dates.
%
% SYNTAX :
%  [o_parkDate, o_parkTransDate, ...
%    o_parkPres, o_parkTemp, o_parkSal, ...
%    o_parkC1PhaseDoxy, o_parkC2PhaseDoxy, o_parkTempDoxyAa, ...
%    o_parkPhaseDelayDoxy, o_parkTempDoxySbe] = create_prv_drift_209(a_dataCTDO, a_refDay)
%
% INPUT PARAMETERS :
%   a_dataCTDO : CTDO decoded data
%   a_refDay   : reference day (day of the first descent)
%
% OUTPUT PARAMETERS :
%   o_parkDate           : drift meas dates
%   o_parkTransDate      : drift meas transmitted date flags
%   o_parkPres           : drift meas PRES
%   o_parkTemp           : drift meas TEMP
%   o_parkSal            : drift meas PSAL
%   o_parkC1PhaseDoxy    : drift meas C1PHASE_DOXY
%   o_parkC2PhaseDoxy    : drift meas C2PHASE_DOXY
%   o_parkTempDoxyAa     : drift meas TEMP_DOXY (Aanderaa sensor)
%   o_parkPhaseDelayDoxy : drift meas PHASE_DELAY_DOXY
%   o_parkTempDoxySbe    : drift meas TEMP_DOXY (SBE sensor)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/03/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkDate, o_parkTransDate, ...
   o_parkPres, o_parkTemp, o_parkSal, ...
   o_parkC1PhaseDoxy, o_parkC2PhaseDoxy, o_parkTempDoxyAa, ...
   o_parkPhaseDelayDoxy, o_parkTempDoxySbe] = create_prv_drift_209(a_dataCTDO, a_refDay)

% output parameters initialization
o_parkDate = [];
o_parkTransDate = [];
o_parkPres = [];
o_parkTemp = [];
o_parkSal = [];
o_parkC1PhaseDoxy = [];
o_parkC2PhaseDoxy = [];
o_parkTempDoxyAa = [];
o_parkPhaseDelayDoxy = [];
o_parkTempDoxySbe = [];

% current cycle number
global g_decArgo_cycleNum;

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

% retrieve the drift sampling period from the configuration
[configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
driftSampPeriodHours = get_config_value('CONFIG_PM06', configNames, configValues);

% create drift data
optodeType = unique(a_dataCTDO(:, end));
switch (optodeType)
   case 2
      % CTD only
      
      idDrift = find(a_dataCTDO(:, 1) == 2);
      for idP = 1:length(idDrift)
         data = a_dataCTDO(idDrift(idP), :);
         for idMeas = 1:15
            if (idMeas == 1)
               data(idMeas+1) = data(idMeas+1) + a_refDay;
               data(idMeas+1+15) = 1;
            else
               if ~((data(idMeas+1+15*2) == g_decArgo_presDef) && ...
                     (data(idMeas+1+15*3) == g_decArgo_tempDef) && ...
                     (data(idMeas+1+15*4) == g_decArgo_salDef))
                  data(idMeas+1) = data(idMeas) + driftSampPeriodHours/24;
                  data(idMeas+1+15) = 0;
               else
                  break;
               end
            end
            
            o_parkDate = [o_parkDate; data(idMeas+1)];
            o_parkTransDate = [o_parkTransDate; data(idMeas+1+15)];
            o_parkPres = [o_parkPres; data(idMeas+1+15*2)];
            o_parkTemp = [o_parkTemp; data(idMeas+1+15*3)];
            o_parkSal = [o_parkSal; data(idMeas+1+15*4)];
         end
      end
   case 1
      % CTD + Aanderaa 4330
      
      idDrift = find(a_dataCTDO(:, 1) == 9);
      for idP = 1:length(idDrift)
         data = a_dataCTDO(idDrift(idP), :);
         for idMeas = 1:7
            if (idMeas == 1)
               data(idMeas+1) = data(idMeas+1) + a_refDay;
               data(idMeas+1+7) = 1;
            else
               if ~((data(idMeas+1+7*2) == g_decArgo_presDef) && ...
                     (data(idMeas+1+7*3) == g_decArgo_tempDef) && ...
                     (data(idMeas+1+7*4) == g_decArgo_salDef) && ...
                     (data(idMeas+1+7*5) == g_decArgo_c1C2PhaseDoxyDef) && ...
                     (data(idMeas+1+7*6) == g_decArgo_c1C2PhaseDoxyDef) && ...
                     (data(idMeas+1+7*7) == g_decArgo_tempDoxyDef))
                  data(idMeas+1) = data(idMeas) + driftSampPeriodHours/24;
                  data(idMeas+1+7) = 0;
               else
                  break;
               end
            end
            
            o_parkDate = [o_parkDate; data(idMeas+1)];
            o_parkTransDate = [o_parkTransDate; data(idMeas+1+7)];
            o_parkPres = [o_parkPres; data(idMeas+1+7*2)];
            o_parkTemp = [o_parkTemp; data(idMeas+1+7*3)];
            o_parkSal = [o_parkSal; data(idMeas+1+7*4)];
            o_parkC1PhaseDoxy = [o_parkC1PhaseDoxy; data(idMeas+1+7*5)];
            o_parkC2PhaseDoxy = [o_parkC2PhaseDoxy; data(idMeas+1+7*6)];
            o_parkTempDoxyAa = [o_parkTempDoxyAa; data(idMeas+1+7*7)];
         end
      end
   case 4
      % CTD + SBE 63
      
      idDrift = find(a_dataCTDO(:, 1) == 12);
      for idP = 1:length(idDrift)
         data = a_dataCTDO(idDrift(idP), :);
         for idMeas = 1:9
            if (idMeas == 1)
               data(idMeas+1) = data(idMeas+1) + a_refDay;
               data(idMeas+1+9) = 1;
            else
               if ~((data(idMeas+1+9*2) == g_decArgo_presDef) && ...
                     (data(idMeas+1+9*3) == g_decArgo_tempDef) && ...
                     (data(idMeas+1+9*4) == g_decArgo_salDef) && ...
                     (data(idMeas+1+9*5) == g_decArgo_phaseDelayDoxyDef) && ...
                     (data(idMeas+1+9*6) == g_decArgo_tempDoxyDef))
                  data(idMeas+1) = data(idMeas) + driftSampPeriodHours/24;
                  data(idMeas+1+9) = 0;
               else
                  break;
               end
            end
            
            o_parkDate = [o_parkDate; data(idMeas+1)];
            o_parkTransDate = [o_parkTransDate; data(idMeas+1+9)];
            o_parkPres = [o_parkPres; data(idMeas+1+9*2)];
            o_parkTemp = [o_parkTemp; data(idMeas+1+9*3)];
            o_parkSal = [o_parkSal; data(idMeas+1+9*4)];
            o_parkPhaseDelayDoxy = [o_parkPhaseDelayDoxy; data(idMeas+1+9*5)];
            o_parkTempDoxySbe = [o_parkTempDoxySbe; data(idMeas+1+9*6)];
         end
      end
   case 5
      % CTD + Aanderaa 4330 + SBE 63
      
      idDrift = find(a_dataCTDO(:, 1) == 15);
      for idP = 1:length(idDrift)
         data = a_dataCTDO(idDrift(idP), :);
         for idMeas = 1:5
            if (idMeas == 1)
               data(idMeas+1) = data(idMeas+1) + a_refDay;
               data(idMeas+1+5) = 1;
            else
               if ~((data(idMeas+1+5*2) == g_decArgo_presDef) && ...
                     (data(idMeas+1+5*3) == g_decArgo_tempDef) && ...
                     (data(idMeas+1+5*4) == g_decArgo_salDef) && ...
                     (data(idMeas+1+5*5) == g_decArgo_c1C2PhaseDoxyDef) && ...
                     (data(idMeas+1+5*6) == g_decArgo_c1C2PhaseDoxyDef) && ...
                     (data(idMeas+1+5*7) == g_decArgo_tempDoxyDef) && ...
                     (data(idMeas+1+5*8) == g_decArgo_phaseDelayDoxyDef) && ...
                     (data(idMeas+1+5*9) == g_decArgo_tempDoxyDef))
                  data(idMeas+1) = data(idMeas) + driftSampPeriodHours/24;
                  data(idMeas+1+5) = 0;
               else
                  break;
               end
            end
            
            o_parkDate = [o_parkDate; data(idMeas+1)];
            o_parkTransDate = [o_parkTransDate; data(idMeas+1+5)];
            o_parkPres = [o_parkPres; data(idMeas+1+5*2)];
            o_parkTemp = [o_parkTemp; data(idMeas+1+5*3)];
            o_parkSal = [o_parkSal; data(idMeas+1+5*4)];
            o_parkC1PhaseDoxy = [o_parkC1PhaseDoxy; data(idMeas+1+5*5)];
            o_parkC2PhaseDoxy = [o_parkC2PhaseDoxy; data(idMeas+1+5*6)];
            o_parkTempDoxyAa = [o_parkTempDoxyAa; data(idMeas+1+5*7)];
            o_parkPhaseDelayDoxy = [o_parkPhaseDelayDoxy; data(idMeas+1+5*8)];
            o_parkTempDoxySbe = [o_parkTempDoxySbe; data(idMeas+1+5*9)];
         end
      end
   otherwise
      fprintf('WARNING: Nothing done yet for optode type #%d\n', ...
         optodeType);
end

% sort the measurements in chronological order
[o_parkDate, idSorted] = sort(o_parkDate);
o_parkTransDate = o_parkTransDate(idSorted);
o_parkPres = o_parkPres(idSorted);
o_parkTemp = o_parkTemp(idSorted);
o_parkSal = o_parkSal(idSorted);
if (~isempty(o_parkC1PhaseDoxy))
   o_parkC1PhaseDoxy = o_parkC1PhaseDoxy(idSorted);
   o_parkC2PhaseDoxy = o_parkC2PhaseDoxy(idSorted);
   o_parkTempDoxyAa = o_parkTempDoxyAa(idSorted);
end
if (~isempty(o_parkPhaseDelayDoxy))
   o_parkPhaseDelayDoxy = o_parkPhaseDelayDoxy(idSorted);
   o_parkTempDoxySbe = o_parkTempDoxySbe(idSorted);
end

return;
