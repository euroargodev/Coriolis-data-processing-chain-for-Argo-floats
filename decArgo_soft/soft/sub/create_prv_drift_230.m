% ------------------------------------------------------------------------------
% Create the drift measurements and add their dates.
%
% SYNTAX :
% [o_parkDate, o_parkTransDate, ...
%   o_parkPres, o_parkTemp, o_parkSal, ...
%   o_parkC1PhaseDoxy, o_parkC2PhaseDoxy, o_parkTempDoxy, ...
%   o_parkTempCountDoxy, o_parkCountDoxy, o_parkLedFlashingCountDoxy] = ...
%   create_prv_drift_230(a_dataCTDO, a_dataStartPos)
%
% INPUT PARAMETERS :
%   a_dataCTDO     : decoded data of the CTD + Optode + AROD_FT sensor
%   a_dataStartPos : position of the first useful data
%
% OUTPUT PARAMETERS :
%   o_parkDate                 : drift meas dates
%   o_parkTransDate            : drift meas transmitted date flags
%   o_parkPres                 : drift meas PRES
%   o_parkTemp                 : drift meas TEMP
%   o_parkSal                  : drift meas PSAL
%   o_parkC1PhaseDoxy          : drift meas C1PHASE_DOXY
%   o_parkC2PhaseDoxy          : drift meas C2PHASE_DOXY
%   o_parkTempDoxy             : drift meas TEMP_DOXY
%   o_parkTempCountDoxy        : drift meas TEMP_COUNT_DOXY
%   o_parkCountDoxy            : drift meas COUNT_DOXY
%   o_parkLedFlashingCountDoxy : drift meas LED_FLASHING_COUNT_DOXY
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/05/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkDate, o_parkTransDate, ...
   o_parkPres, o_parkTemp, o_parkSal, ...
   o_parkC1PhaseDoxy, o_parkC2PhaseDoxy, o_parkTempDoxy, ...
   o_parkTempCountDoxy, o_parkCountDoxy, o_parkLedFlashingCountDoxy] = ...
   create_prv_drift_230(a_dataCTDO, a_dataStartPos)

% output parameters initialization
o_parkDate = [];
o_parkTransDate = [];
o_parkPres = [];
o_parkTemp = [];
o_parkSal = [];
o_parkC1PhaseDoxy = [];
o_parkC2PhaseDoxy = [];
o_parkTempDoxy = [];
o_parkTempCountDoxy = [];
o_parkCountDoxy = [];
o_parkLedFlashingCountDoxy = [];

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_c1C2PhaseDoxyDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_tempDoxyCountsDef;
global g_decArgo_doxyCountsDef;
global g_decArgo_ledFlashingDoxyCountsDef;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;


if (isempty(a_dataCTDO))
   return
end

% retrieve the drift sampling period from the configuration
[configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
driftSampPeriodHours = get_config_value('CONFIG_PM06', configNames, configValues);

idDrift = find(a_dataCTDO(:, 1) == 31);
for idP = 1:length(idDrift)
   data = a_dataCTDO(idDrift(idP), a_dataStartPos:end);
   for idMeas = 1:4
      if (idMeas == 1)
         data(idMeas+1) = data(idMeas+1) + g_decArgo_julD2FloatDayOffset;
         data(idMeas+1+4) = 1;
      else
         if ~((data(idMeas+1+4*2) == g_decArgo_presDef) && ...
               (data(idMeas+1+4*3) == g_decArgo_tempDef) && ...
               (data(idMeas+1+4*4) == g_decArgo_salDef) && ...
               (data(idMeas+1+4*5) == g_decArgo_c1C2PhaseDoxyDef) && ...
               (data(idMeas+1+4*6) == g_decArgo_c1C2PhaseDoxyDef) && ...
               (data(idMeas+1+4*7) == g_decArgo_tempDoxyDef) && ...
               (data(idMeas+1+4*8) == g_decArgo_tempDoxyCountsDef) && ...
               (data(idMeas+1+4*9) == g_decArgo_doxyCountsDef) && ...
               (data(idMeas+1+4*10) == g_decArgo_ledFlashingDoxyCountsDef))
            data(idMeas+1) = data(idMeas) + driftSampPeriodHours/24;
            data(idMeas+1+4) = 0;
         else
            break
         end
      end

      o_parkDate = [o_parkDate; data(idMeas+1)];
      o_parkTransDate = [o_parkTransDate; data(idMeas+1+4)];
      o_parkPres = [o_parkPres; data(idMeas+1+4*2)];
      o_parkTemp = [o_parkTemp; data(idMeas+1+4*3)];
      o_parkSal = [o_parkSal; data(idMeas+1+4*4)];
      o_parkC1PhaseDoxy = [o_parkC1PhaseDoxy; data(idMeas+1+4*5)];
      o_parkC2PhaseDoxy = [o_parkC2PhaseDoxy; data(idMeas+1+4*6)];
      o_parkTempDoxy = [o_parkTempDoxy; data(idMeas+1+4*7)];
      o_parkTempCountDoxy = [o_parkTempCountDoxy; data(idMeas+1+4*8)];
      o_parkCountDoxy = [o_parkCountDoxy; data(idMeas+1+4*9)];
      o_parkLedFlashingCountDoxy = [o_parkLedFlashingCountDoxy; data(idMeas+1+4*10)];
   end
end

% sort the measurements in chronological order
[o_parkDate, idSorted] = sort(o_parkDate);
o_parkTransDate = o_parkTransDate(idSorted);
o_parkPres = o_parkPres(idSorted);
o_parkTemp = o_parkTemp(idSorted);
o_parkSal = o_parkSal(idSorted);
o_parkC1PhaseDoxy = o_parkC1PhaseDoxy(idSorted);
o_parkC2PhaseDoxy = o_parkC2PhaseDoxy(idSorted);
o_parkTempDoxy = o_parkTempDoxy(idSorted);
o_parkTempCountDoxy = o_parkTempCountDoxy(idSorted);
o_parkCountDoxy = o_parkCountDoxy(idSorted);
o_parkLedFlashingCountDoxy = o_parkLedFlashingCountDoxy(idSorted);

return
