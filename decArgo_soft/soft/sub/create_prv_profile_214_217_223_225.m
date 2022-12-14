% ------------------------------------------------------------------------------
% Create the profiles.
%
% SYNTAX :
%  [o_descProfDate, o_descProfPres, o_descProfTemp, o_descProfSal, ...
%    o_descProfC1PhaseDoxy, o_descProfC2PhaseDoxy, o_descProfTempDoxy, ...
%    o_ascProfDate, o_ascProfPres, o_ascProfTemp, o_ascProfSal, ...
%    o_ascProfC1PhaseDoxy, o_ascProfC2PhaseDoxy, o_ascProfTempDoxy, ...
%    o_nearSurfDate, o_nearSurfTransDate, o_nearSurfPres, o_nearSurfTemp, o_nearSurfSal, ...
%    o_nearSurfC1PhaseDoxy, o_nearSurfC2PhaseDoxy, o_nearSurfTempDoxy, ...
%    o_inAirDate, o_inAirTransDate, o_inAirPres, o_inAirTemp, o_inAirSal, ...
%    o_inAirC1PhaseDoxy, o_inAirC2PhaseDoxy, o_inAirTempDoxy] = ...
%    create_prv_profile_214_217_223_225(a_dataCTD, a_dataCTDO, a_deepCycleFlag, a_refDay)
%
% INPUT PARAMETERS :
%   a_dataCTD        : decoded CTD data
%   a_dataCTDO       : decoded CTDO data
%   a_deepCycleFlag  : 1 if it is a deep cycle, 0 if it is a surface one
%   a_refDay         : reference day (day of the first descent)
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
%   o_nearSurfDate        : "near surface" profile dates
%   o_nearSurfTransDate   : "near surface" profile transmitted date flags
%   o_nearSurfPres        : "near surface" profile PRES
%   o_nearSurfTemp        : "near surface" profile TEMP
%   o_nearSurfSal         : "near surface" profile PSAL
%   o_nearSurfC1PhaseDoxy : "near surface" profile C1PHASE_DOXY
%   o_nearSurfC2PhaseDoxy : "near surface" profile C2PHASE_DOXY
%   o_nearSurfTempDoxy    : "near surface" profile TEMP_DOXY
%   o_inAirDate           : "in air" profile dates
%   o_inAirTransDate      : "in air" profile transmitted date flags
%   o_inAirPres           : "in air" profile PRES
%   o_inAirTemp           : "in air" profile TEMP
%   o_inAirSal            : "in air" profile PSAL
%   o_inAirC1PhaseDoxy    : "in air" profile C1PHASE_DOXY
%   o_inAirC2PhaseDoxy    : "in air" profile C2PHASE_DOXY
%   o_inAirTempDoxy       : "in air" profile TEMP_DOXY
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/07/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_descProfDate, o_descProfPres, o_descProfTemp, o_descProfSal, ...
   o_descProfC1PhaseDoxy, o_descProfC2PhaseDoxy, o_descProfTempDoxy, ...
   o_ascProfDate, o_ascProfPres, o_ascProfTemp, o_ascProfSal, ...
   o_ascProfC1PhaseDoxy, o_ascProfC2PhaseDoxy, o_ascProfTempDoxy, ...
   o_nearSurfDate, o_nearSurfTransDate, o_nearSurfPres, o_nearSurfTemp, o_nearSurfSal, ...
   o_nearSurfC1PhaseDoxy, o_nearSurfC2PhaseDoxy, o_nearSurfTempDoxy, ...
   o_inAirDate, o_inAirTransDate, o_inAirPres, o_inAirTemp, o_inAirSal, ...
   o_inAirC1PhaseDoxy, o_inAirC2PhaseDoxy, o_inAirTempDoxy] = ...
   create_prv_profile_214_217_223_225(a_dataCTD, a_dataCTDO, a_deepCycleFlag, a_refDay)

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
o_nearSurfDate = [];
o_nearSurfTransDate = [];
o_nearSurfPres = [];
o_nearSurfTemp = [];
o_nearSurfSal = [];
o_nearSurfC1PhaseDoxy = [];
o_nearSurfC2PhaseDoxy = [];
o_nearSurfTempDoxy = [];
o_inAirDate = [];
o_inAirTransDate = [];
o_inAirPres = [];
o_inAirTemp = [];
o_inAirSal = [];
o_inAirC1PhaseDoxy = [];
o_inAirC2PhaseDoxy = [];
o_inAirTempDoxy = [];

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_dateDef;
global g_decArgo_c1C2PhaseDoxyDef;
global g_decArgo_tempDoxyDef;

% current cycle number
global g_decArgo_cycleNum;

% float configuration
global g_decArgo_floatConfig;


if ~((~isempty(a_dataCTD) && any(ismember(a_dataCTD(:, 1), [1 3 13 14]))) || ...
      (~isempty(a_dataCTDO) && any(ismember(a_dataCTDO(:, 1), [8 10 11 12]))))
   return
end

% retrieve the "Near Surface" or "In Air" sampling period from the configuration
if (a_deepCycleFlag)
   % for a deep cycle, a configuration must exist
   [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
else
   % for a surface cycle (In Air measurements), no associated configuration
   % exists
   if (any(g_decArgo_floatConfig.USE.CYCLE == g_decArgo_cycleNum))
      [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
   else
      cyNum = g_decArgo_cycleNum - 1;
      while (cyNum >= 0)
         if (any(g_decArgo_floatConfig.USE.CYCLE == cyNum))
            [configNames, configValues] = get_float_config_ir_sbd(cyNum);
            break
         end
         cyNum = cyNum - 1;
      end
   end
end
inAirSampPeriodSeconds = get_config_value('CONFIG_MC30', configNames, configValues);

if (~isempty(a_dataCTD))
   for type = [1 3 13 14]
      idForType = find(a_dataCTD(:, 1) == type);
      for idP = 1:length(idForType)
         data = a_dataCTD(idForType(idP), 3:end);
         for idMeas = 1:15
            date = g_decArgo_dateDef;
            dateTrans = 0;
            if (idMeas == 1)
               date = data(idMeas) + a_refDay;
               dateTrans = 1;
            else
               if ((data(idMeas+15*2) == g_decArgo_presDef) && ...
                     (data(idMeas+15*3) == g_decArgo_tempDef) && ...
                     (data(idMeas+15*4) == g_decArgo_salDef))
                  break
               end
               if (ismember(type, [13 14]))
                  date = data(1) + a_refDay + (idMeas-1)*inAirSampPeriodSeconds/86400;
               end
            end
            
            if (type == 1)
               o_descProfDate = [o_descProfDate; date];
               o_descProfPres = [o_descProfPres; data(idMeas+15*2)];
               o_descProfTemp = [o_descProfTemp; data(idMeas+15*3)];
               o_descProfSal = [o_descProfSal; data(idMeas+15*4)];
            elseif (type == 3)
               o_ascProfDate = [o_ascProfDate; date];
               o_ascProfPres = [o_ascProfPres; data(idMeas+15*2)];
               o_ascProfTemp = [o_ascProfTemp; data(idMeas+15*3)];
               o_ascProfSal = [o_ascProfSal; data(idMeas+15*4)];
            elseif (type == 13)
               o_nearSurfDate = [o_nearSurfDate; date];
               o_nearSurfTransDate = [o_nearSurfTransDate; dateTrans];
               o_nearSurfPres = [o_nearSurfPres; data(idMeas+15*2)];
               o_nearSurfTemp = [o_nearSurfTemp; data(idMeas+15*3)];
               o_nearSurfSal = [o_nearSurfSal; data(idMeas+15*4)];
            elseif (type == 14)
               o_inAirDate = [o_inAirDate; date];
               o_inAirTransDate = [o_inAirTransDate; dateTrans];
               o_inAirPres = [o_inAirPres; data(idMeas+15*2)];
               o_inAirTemp = [o_inAirTemp; data(idMeas+15*3)];
               o_inAirSal = [o_inAirSal; data(idMeas+15*4)];
            end
         end
      end
   end
end

if (~isempty(a_dataCTDO))
   for type = [8 10 11 12]
      idForType = find(a_dataCTDO(:, 1) == type);
      for idP = 1:length(idForType)
         data = a_dataCTDO(idForType(idP), 3:end);
         for idMeas = 1:7
            date = g_decArgo_dateDef;
            dateTrans = 0;
            if (idMeas == 1)
               date = data(idMeas) + a_refDay;
               dateTrans = 1;
            else
               if ((data(idMeas+7*2) == g_decArgo_presDef) && ...
                     (data(idMeas+7*3) == g_decArgo_tempDef) && ...
                     (data(idMeas+7*4) == g_decArgo_salDef) && ...
                     (data(idMeas+7*5) == g_decArgo_c1C2PhaseDoxyDef) && ...
                     (data(idMeas+7*6) == g_decArgo_c1C2PhaseDoxyDef) && ...
                     (data(idMeas+7*7) == g_decArgo_tempDoxyDef))
                  break
               end
               if (ismember(type, [11 12]))
                  date = data(1) + a_refDay + (idMeas-1)*inAirSampPeriodSeconds/86400;
               end
            end
            
            if (type == 8)
               o_descProfDate = [o_descProfDate; date];
               o_descProfPres = [o_descProfPres; data(idMeas+7*2)];
               o_descProfTemp = [o_descProfTemp; data(idMeas+7*3)];
               o_descProfSal = [o_descProfSal; data(idMeas+7*4)];
               o_descProfC1PhaseDoxy = [o_descProfC1PhaseDoxy; data(idMeas+7*5)];
               o_descProfC2PhaseDoxy = [o_descProfC2PhaseDoxy; data(idMeas+7*6)];
               o_descProfTempDoxy = [o_descProfTempDoxy; data(idMeas+7*7)];
            elseif (type == 10)
               o_ascProfDate = [o_ascProfDate; date];
               o_ascProfPres = [o_ascProfPres; data(idMeas+7*2)];
               o_ascProfTemp = [o_ascProfTemp; data(idMeas+7*3)];
               o_ascProfSal = [o_ascProfSal; data(idMeas+7*4)];
               o_ascProfC1PhaseDoxy = [o_ascProfC1PhaseDoxy; data(idMeas+7*5)];
               o_ascProfC2PhaseDoxy = [o_ascProfC2PhaseDoxy; data(idMeas+7*6)];
               o_ascProfTempDoxy = [o_ascProfTempDoxy; data(idMeas+7*7)];
            elseif (type == 11)
               o_nearSurfDate = [o_nearSurfDate; date];
               o_nearSurfTransDate = [o_nearSurfTransDate; dateTrans];
               o_nearSurfPres = [o_nearSurfPres; data(idMeas+7*2)];
               o_nearSurfTemp = [o_nearSurfTemp; data(idMeas+7*3)];
               o_nearSurfSal = [o_nearSurfSal; data(idMeas+7*4)];
               o_nearSurfC1PhaseDoxy = [o_nearSurfC1PhaseDoxy; data(idMeas+7*5)];
               o_nearSurfC2PhaseDoxy = [o_nearSurfC2PhaseDoxy; data(idMeas+7*6)];
               o_nearSurfTempDoxy = [o_nearSurfTempDoxy; data(idMeas+7*7)];
            elseif (type == 12)
               o_inAirDate = [o_inAirDate; date];
               o_inAirTransDate = [o_inAirTransDate; dateTrans];
               o_inAirPres = [o_inAirPres; data(idMeas+7*2)];
               o_inAirTemp = [o_inAirTemp; data(idMeas+7*3)];
               o_inAirSal = [o_inAirSal; data(idMeas+7*4)];
               o_inAirC1PhaseDoxy = [o_inAirC1PhaseDoxy; data(idMeas+7*5)];
               o_inAirC2PhaseDoxy = [o_inAirC2PhaseDoxy; data(idMeas+7*6)];
               o_inAirTempDoxy = [o_inAirTempDoxy; data(idMeas+7*7)];
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

return
