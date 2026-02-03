% ------------------------------------------------------------------------------
% Create the profiles.
%
% SYNTAX :
% [o_descProfDate, o_descProfPres, o_descProfTemp, o_descProfSal, ...
%   o_descProfC1PhaseDoxy, o_descProfC2PhaseDoxy, o_descProfTempDoxy, ...
%   o_descProfTempCountDoxy, o_descProfCountDoxy, o_descProfLedFlashingCountDoxy, ...
%   o_ascProfDate, o_ascProfPres, o_ascProfTemp, o_ascProfSal, ...
%   o_ascProfC1PhaseDoxy, o_ascProfC2PhaseDoxy, o_ascProfTempDoxy, ...
%   o_ascProfTempCountDoxy, o_ascProfCountDoxy, o_ascProfLedFlashingCountDoxy, ...
%   o_nearSurfDate, o_nearSurfTransDate, o_nearSurfPres, o_nearSurfTemp, o_nearSurfSal, ...
%   o_nearSurfC1PhaseDoxy, o_nearSurfC2PhaseDoxy, o_nearSurfTempDoxy, ...
%   o_nearSurfTempCountDoxy, o_nearSurfCountDoxy, o_nearSurfLedFlashingCountDoxy, ...
%   o_inAirDate, o_inAirTransDate, o_inAirPres, o_inAirTemp, o_inAirSal, ...
%   o_inAirC1PhaseDoxy, o_inAirC2PhaseDoxy, o_inAirTempDoxy, ...
%   o_inAirTempCountDoxy, o_inAirCountDoxy, o_inAirLedFlashingCountDoxy] = ...
%   create_prv_profile_230(a_dataCTDO, a_dataStartPos)
%
% INPUT PARAMETERS :
%   a_dataCTDO     : decoded data of the CTD + Optode + AROD_FT sensor
%   a_dataStartPos : position of the first useful data
%
% OUTPUT PARAMETERS :
%   o_descProfDate                 : descending profile dates
%   o_descProfPres                 : descending profile PRES
%   o_descProfTemp                 : descending profile TEMP
%   o_descProfSal                  : descending profile PSAL
%   o_descProfC1PhaseDoxy          : descending profile C1PHASE_DOXY
%   o_descProfC2PhaseDoxy          : descending profile C2PHASE_DOXY
%   o_descProfTempDoxy             : descending profile TEMP_DOXY
%   o_descProfTempCountDoxy        : descending profile TEMP_COUNT_DOXY
%   o_descProfCountDoxy            : descending profile COUNT_DOXY
%   o_descProfLedFlashingCountDoxy : descending profile LED_FLASHING_COUNT_DOXY
%   o_ascProfDate                  : ascending profile dates
%   o_ascProfPres                  : ascending profile PRES
%   o_ascProfTemp                  : ascending profile TEMP
%   o_ascProfSal                   : ascending profile PSAL
%   o_ascProfC1PhaseDoxy           : ascending profile C1PHASE_DOXY
%   o_ascProfC2PhaseDoxy           : ascending profile C2PHASE_DOXY
%   o_ascProfTempDoxy              : ascending profile TEMP_DOXY
%   o_ascProfTempCountDoxy         : ascending profile TEMP_COUNT_DOXY
%   o_ascProfCountDoxy             : ascending profile COUNT_DOXY
%   o_ascProfLedFlashingCountDoxy  : ascending profile LED_FLASHING_COUNT_DOXY
%   o_nearSurfDate                 : "near surface" profile dates
%   o_nearSurfTransDate            : "near surface" profile transmitted date flags
%   o_nearSurfPres                 : "near surface" profile PRES
%   o_nearSurfTemp                 : "near surface" profile TEMP
%   o_nearSurfSal                  : "near surface" profile PSAL
%   o_nearSurfC1PhaseDoxy          : "near surface" profile C1PHASE_DOXY
%   o_nearSurfC2PhaseDoxy          : "near surface" profile C2PHASE_DOXY
%   o_nearSurfTempDoxy             : "near surface" profile TEMP_DOXY
%   o_nearSurfTempCountDoxy        : "near surface" profile TEMP_COUNT_DOXY
%   o_nearSurfCountDoxy            : "near surface" profile COUNT_DOXY
%   o_nearSurfLedFlashingCountDoxy : "near surface" profile LED_FLASHING_COUNT_DOXY
%   o_inAirDate                    : "in air" profile dates
%   o_inAirTransDate               : "in air" profile transmitted date flags
%   o_inAirPres                    : "in air" profile PRES
%   o_inAirTemp                    : "in air" profile TEMP
%   o_inAirSal                     : "in air" profile PSAL
%   o_inAirC1PhaseDoxy             : "in air" profile C1PHASE_DOXY
%   o_inAirC2PhaseDoxy             : "in air" profile C2PHASE_DOXY
%   o_inAirTempDoxy                : "in air" profile TEMP_DOXY
%   o_inAirTempCountDoxy           : "in air" profile TEMP_COUNT_DOXY
%   o_inAirCountDoxy               : "in air" profile COUNT_DOXY
%   o_inAirLedFlashingCountDoxy    : "in air" profile LED_FLASHING_COUNT_DOXY
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/05/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_descProfDate, o_descProfPres, o_descProfTemp, o_descProfSal, ...
   o_descProfC1PhaseDoxy, o_descProfC2PhaseDoxy, o_descProfTempDoxy, ...
   o_descProfTempCountDoxy, o_descProfCountDoxy, o_descProfLedFlashingCountDoxy, ...
   o_ascProfDate, o_ascProfPres, o_ascProfTemp, o_ascProfSal, ...
   o_ascProfC1PhaseDoxy, o_ascProfC2PhaseDoxy, o_ascProfTempDoxy, ...
   o_ascProfTempCountDoxy, o_ascProfCountDoxy, o_ascProfLedFlashingCountDoxy, ...
   o_nearSurfDate, o_nearSurfTransDate, o_nearSurfPres, o_nearSurfTemp, o_nearSurfSal, ...
   o_nearSurfC1PhaseDoxy, o_nearSurfC2PhaseDoxy, o_nearSurfTempDoxy, ...
   o_nearSurfTempCountDoxy, o_nearSurfCountDoxy, o_nearSurfLedFlashingCountDoxy, ...
   o_inAirDate, o_inAirTransDate, o_inAirPres, o_inAirTemp, o_inAirSal, ...
   o_inAirC1PhaseDoxy, o_inAirC2PhaseDoxy, o_inAirTempDoxy, ...
   o_inAirTempCountDoxy, o_inAirCountDoxy, o_inAirLedFlashingCountDoxy] = ...
   create_prv_profile_230(a_dataCTDO, a_dataStartPos)

% output parameters initialization
o_descProfDate = [];
o_descProfPres = [];
o_descProfTemp = [];
o_descProfSal = [];
o_descProfC1PhaseDoxy = [];
o_descProfC2PhaseDoxy = [];
o_descProfTempDoxy = [];
o_descProfTempCountDoxy = [];
o_descProfCountDoxy = [];
o_descProfLedFlashingCountDoxy = [];
o_ascProfDate = [];
o_ascProfPres = [];
o_ascProfTemp = [];
o_ascProfSal = [];
o_ascProfC1PhaseDoxy = [];
o_ascProfC2PhaseDoxy = [];
o_ascProfTempDoxy = [];
o_ascProfTempCountDoxy = [];
o_ascProfCountDoxy = [];
o_ascProfLedFlashingCountDoxy = [];
o_nearSurfDate = [];
o_nearSurfTransDate = [];
o_nearSurfPres = [];
o_nearSurfTemp = [];
o_nearSurfSal = [];
o_nearSurfC1PhaseDoxy = [];
o_nearSurfC2PhaseDoxy = [];
o_nearSurfTempDoxy = [];
o_nearSurfTempCountDoxy = [];
o_nearSurfCountDoxy = [];
o_nearSurfLedFlashingCountDoxy = [];
o_inAirDate = [];
o_inAirTransDate = [];
o_inAirPres = [];
o_inAirTemp = [];
o_inAirSal = [];
o_inAirC1PhaseDoxy = [];
o_inAirC2PhaseDoxy = [];
o_inAirTempDoxy = [];
o_inAirTempCountDoxy = [];
o_inAirCountDoxy = [];
o_inAirLedFlashingCountDoxy = [];


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

% current cycle number
global g_decArgo_cycleNum;


if (isempty(a_dataCTDO))
   return
end

% retrieve the "Near Surface" or "In Air" sampling period from the configuration
[configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
inAirSampPeriodSeconds = get_config_value('CONFIG_PT30', configNames, configValues);

for type = [30, 32, 33, 34]
   idForType = find(a_dataCTDO(:, 1) == type);
   for idP = 1:length(idForType)
      data = a_dataCTDO(idForType(idP), a_dataStartPos:end);

      for idMeas = 1:4
         dateTrans = 0;
         if (idMeas == 1)
            data(idMeas+1) = data(idMeas+1) + g_decArgo_julD2FloatDayOffset;
            dateTrans = 1;
         else
            if ((data(idMeas+1+4*2) == g_decArgo_presDef) && ...
                  (data(idMeas+1+4*3) == g_decArgo_tempDef) && ...
                  (data(idMeas+1+4*4) == g_decArgo_salDef) && ...
                  (data(idMeas+1+4*5) == g_decArgo_c1C2PhaseDoxyDef) && ...
                  (data(idMeas+1+4*6) == g_decArgo_c1C2PhaseDoxyDef) && ...
                  (data(idMeas+1+4*7) == g_decArgo_tempDoxyDef) && ...
                  (data(idMeas+1+4*8) == g_decArgo_tempDoxyCountsDef) && ...
                  (data(idMeas+1+4*9) == g_decArgo_doxyCountsDef) && ...
                  (data(idMeas+1+4*10) == g_decArgo_ledFlashingDoxyCountsDef))
               break
            end
            if (type > 32)
               data(idMeas+1) = data(idMeas) + inAirSampPeriodSeconds/86400;
            end
         end

         if (type == 30)
            o_descProfDate = [o_descProfDate; data(idMeas+1)];
            o_descProfPres = [o_descProfPres; data(idMeas+1+4*2)];
            o_descProfTemp = [o_descProfTemp; data(idMeas+1+4*3)];
            o_descProfSal = [o_descProfSal; data(idMeas+1+4*4)];
            o_descProfC1PhaseDoxy = [o_descProfC1PhaseDoxy; data(idMeas+1+4*5)];
            o_descProfC2PhaseDoxy = [o_descProfC2PhaseDoxy; data(idMeas+1+4*6)];
            o_descProfTempDoxy = [o_descProfTempDoxy; data(idMeas+1+4*7)];
            o_descProfTempCountDoxy = [o_descProfTempCountDoxy; data(idMeas+1+4*8)];
            o_descProfCountDoxy = [o_descProfCountDoxy; data(idMeas+1+4*9)];
            o_descProfLedFlashingCountDoxy = [o_descProfLedFlashingCountDoxy; data(idMeas+1+4*10)];
         elseif (type == 32)
            o_ascProfDate = [o_ascProfDate; data(idMeas+1)];
            o_ascProfPres = [o_ascProfPres; data(idMeas+1+4*2)];
            o_ascProfTemp = [o_ascProfTemp; data(idMeas+1+4*3)];
            o_ascProfSal = [o_ascProfSal; data(idMeas+1+4*4)];
            o_ascProfC1PhaseDoxy = [o_ascProfC1PhaseDoxy; data(idMeas+1+4*5)];
            o_ascProfC2PhaseDoxy = [o_ascProfC2PhaseDoxy; data(idMeas+1+4*6)];
            o_ascProfTempDoxy = [o_ascProfTempDoxy; data(idMeas+1+4*7)];
            o_ascProfTempCountDoxy = [o_ascProfTempCountDoxy; data(idMeas+1+4*8)];
            o_ascProfCountDoxy = [o_ascProfCountDoxy; data(idMeas+1+4*9)];
            o_ascProfLedFlashingCountDoxy = [o_ascProfLedFlashingCountDoxy; data(idMeas+1+4*10)];
         elseif (type == 33)
            o_nearSurfDate = [o_nearSurfDate; data(idMeas+1)];
            o_nearSurfTransDate = [o_nearSurfTransDate; dateTrans];
            o_nearSurfPres = [o_nearSurfPres; data(idMeas+1+4*2)];
            o_nearSurfTemp = [o_nearSurfTemp; data(idMeas+1+4*3)];
            o_nearSurfSal = [o_nearSurfSal; data(idMeas+1+4*4)];
            o_nearSurfC1PhaseDoxy = [o_nearSurfC1PhaseDoxy; data(idMeas+1+4*5)];
            o_nearSurfC2PhaseDoxy = [o_nearSurfC2PhaseDoxy; data(idMeas+1+4*6)];
            o_nearSurfTempDoxy = [o_nearSurfTempDoxy; data(idMeas+1+4*7)];
            o_nearSurfTempCountDoxy = [o_nearSurfTempCountDoxy; data(idMeas+1+4*8)];
            o_nearSurfCountDoxy = [o_nearSurfCountDoxy; data(idMeas+1+4*9)];
            o_nearSurfLedFlashingCountDoxy = [o_nearSurfLedFlashingCountDoxy; data(idMeas+1+4*10)];
         elseif (type == 34)
            o_inAirDate = [o_inAirDate; data(idMeas+1)];
            o_inAirTransDate = [o_inAirTransDate; dateTrans];
            o_inAirPres = [o_inAirPres; data(idMeas+1+4*2)];
            o_inAirTemp = [o_inAirTemp; data(idMeas+1+4*3)];
            o_inAirSal = [o_inAirSal; data(idMeas+1+4*4)];
            o_inAirC1PhaseDoxy = [o_inAirC1PhaseDoxy; data(idMeas+1+4*5)];
            o_inAirC2PhaseDoxy = [o_inAirC2PhaseDoxy; data(idMeas+1+4*6)];
            o_inAirTempDoxy = [o_inAirTempDoxy; data(idMeas+1+4*7)];
            o_inAirTempCountDoxy = [o_inAirTempCountDoxy; data(idMeas+1+4*8)];
            o_inAirCountDoxy = [o_inAirCountDoxy; data(idMeas+1+4*9)];
            o_inAirLedFlashingCountDoxy = [o_inAirLedFlashingCountDoxy; data(idMeas+1+4*10)];
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
o_descProfTempCountDoxy = o_descProfTempCountDoxy(idSorted);
o_descProfCountDoxy = o_descProfCountDoxy(idSorted);
o_descProfLedFlashingCountDoxy = o_descProfLedFlashingCountDoxy(idSorted);

[o_ascProfPres, idSorted] = sort(o_ascProfPres, 'descend');
o_ascProfDate = o_ascProfDate(idSorted);
o_ascProfTemp = o_ascProfTemp(idSorted);
o_ascProfSal = o_ascProfSal(idSorted);
o_ascProfC1PhaseDoxy = o_ascProfC1PhaseDoxy(idSorted);
o_ascProfC2PhaseDoxy = o_ascProfC2PhaseDoxy(idSorted);
o_ascProfTempDoxy = o_ascProfTempDoxy(idSorted);
o_ascProfTempCountDoxy = o_ascProfTempCountDoxy(idSorted);
o_ascProfCountDoxy = o_ascProfCountDoxy(idSorted);
o_ascProfLedFlashingCountDoxy = o_ascProfLedFlashingCountDoxy(idSorted);

return
