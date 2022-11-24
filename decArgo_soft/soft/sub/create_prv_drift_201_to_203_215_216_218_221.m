% ------------------------------------------------------------------------------
% Create the drift measurements and add their dates.
%
% SYNTAX :
%  [o_parkDate, o_parkTransDate, ...
%    o_parkPres, o_parkTemp, o_parkSal, ...
%    o_parkC1PhaseDoxy, o_parkC2PhaseDoxy, o_parkTempDoxy] = ...
%    create_prv_drift_201_to_203_215_216_218_221(a_dataCTD, a_dataCTDO, a_dataStartPos)
%
% INPUT PARAMETERS :
%   a_dataCTD      : decoded data of the CTD sensor
%   a_dataCTDO     : decoded data of the CTD + Optode sensor
%   a_dataStartPos : position of the first useful data
%
% OUTPUT PARAMETERS :
%   o_parkDate        : drift meas dates
%   o_parkTransDate   : drift meas transmitted date flags
%   o_parkPres        : drift meas PRES
%   o_parkTemp        : drift meas TEMP
%   o_parkSal         : drift meas PSAL
%   o_parkC1PhaseDoxy : drift meas C1PHASE_DOXY
%   o_parkC2PhaseDoxy : drift meas C2PHASE_DOXY
%   o_parkTempDoxy    : drift meas TEMP_DOXY
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkDate, o_parkTransDate, ...
   o_parkPres, o_parkTemp, o_parkSal, ...
   o_parkC1PhaseDoxy, o_parkC2PhaseDoxy, o_parkTempDoxy] = ...
   create_prv_drift_201_to_203_215_216_218_221(a_dataCTD, a_dataCTDO, a_dataStartPos)

% output parameters initialization
o_parkDate = [];
o_parkTransDate = [];
o_parkPres = [];
o_parkTemp = [];
o_parkSal = [];
o_parkC1PhaseDoxy = [];
o_parkC2PhaseDoxy = [];
o_parkTempDoxy = [];

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_c1C2PhaseDoxyDef;
global g_decArgo_tempDoxyDef;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;


if (isempty(a_dataCTD) && isempty(a_dataCTDO))
   return
end

% retrieve the drift sampling period from the configuration
[configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
driftSampPeriodHours = get_config_value('CONFIG_PM06', configNames, configValues);

if (~isempty(a_dataCTD))
   idDrift = find(a_dataCTD(:, 1) == 2);
   for idP = 1:length(idDrift)
      data = a_dataCTD(idDrift(idP), a_dataStartPos:end);
      for idMeas = 1:15
         if (idMeas == 1)
            data(idMeas+1) = data(idMeas+1) + g_decArgo_julD2FloatDayOffset;
            data(idMeas+1+15) = 1;
         else
            if ~((data(idMeas+1+15*2) == g_decArgo_presDef) && ...
                  (data(idMeas+1+15*3) == g_decArgo_tempDef) && ...
                  (data(idMeas+1+15*4) == g_decArgo_salDef))
               data(idMeas+1) = data(idMeas) + driftSampPeriodHours/24;
               data(idMeas+1+15) = 0;
            else
               break
            end
         end
         
         o_parkDate = [o_parkDate; data(idMeas+1)];
         o_parkTransDate = [o_parkTransDate; data(idMeas+1+15)];
         o_parkPres = [o_parkPres; data(idMeas+1+15*2)];
         o_parkTemp = [o_parkTemp; data(idMeas+1+15*3)];
         o_parkSal = [o_parkSal; data(idMeas+1+15*4)];
      end
   end
end

if (~isempty(a_dataCTDO))
   idDrift = find(a_dataCTDO(:, 1) == 9);
   for idP = 1:length(idDrift)
      data = a_dataCTDO(idDrift(idP), a_dataStartPos:end);
      for idMeas = 1:7
         if (idMeas == 1)
            data(idMeas+1) = data(idMeas+1) + g_decArgo_julD2FloatDayOffset;
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
               break
            end
         end
         
         o_parkDate = [o_parkDate; data(idMeas+1)];
         o_parkTransDate = [o_parkTransDate; data(idMeas+1+7)];
         o_parkPres = [o_parkPres; data(idMeas+1+7*2)];
         o_parkTemp = [o_parkTemp; data(idMeas+1+7*3)];
         o_parkSal = [o_parkSal; data(idMeas+1+7*4)];
         o_parkC1PhaseDoxy = [o_parkC1PhaseDoxy; data(idMeas+1+7*5)];
         o_parkC2PhaseDoxy = [o_parkC2PhaseDoxy; data(idMeas+1+7*6)];
         o_parkTempDoxy = [o_parkTempDoxy; data(idMeas+1+7*7)];
      end
   end
end

% sort the measurements in chronological order
[o_parkDate, idSorted] = sort(o_parkDate);
o_parkTransDate = o_parkTransDate(idSorted);
o_parkPres = o_parkPres(idSorted);
o_parkTemp = o_parkTemp(idSorted);
o_parkSal = o_parkSal(idSorted);
if (~isempty(a_dataCTDO))
   o_parkC1PhaseDoxy = o_parkC1PhaseDoxy(idSorted);
   o_parkC2PhaseDoxy = o_parkC2PhaseDoxy(idSorted);
   o_parkTempDoxy = o_parkTempDoxy(idSorted);
end

return
