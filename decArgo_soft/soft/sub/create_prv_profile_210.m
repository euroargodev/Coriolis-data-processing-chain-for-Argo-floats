% ------------------------------------------------------------------------------
% Create the profiles.
%
% SYNTAX :
%  [o_descProfDate, o_descProfPres, o_descProfTemp, o_descProfSal, ...
%    o_ascProfDate, o_ascProfPres, o_ascProfTemp, o_ascProfSal, ...
%    o_nearSurfDate, o_nearSurfTransDate, o_nearSurfPres, o_nearSurfTemp, o_nearSurfSal, ...
%    o_inAirDate, o_inAirTransDate, o_inAirPres, o_inAirTemp, o_inAirSal] = ...
%    create_prv_profile_210(a_dataCTD, a_refDay)
%
% INPUT PARAMETERS :
%   a_dataCTD : decoded data of the CTD sensor
%   a_refDay  : reference day (day of the first descent)
%
% OUTPUT PARAMETERS :
%   o_descProfDate      : descending profile dates
%   o_descProfPres      : descending profile PRES
%   o_descProfTemp      : descending profile TEMP
%   o_descProfSal       : descending profile PSAL
%   o_ascProfDate       : ascending profile dates
%   o_ascProfPres       : ascending profile PRES
%   o_ascProfTemp       : ascending profile TEMP
%   o_ascProfSal        : ascending profile PSAL
%   o_nearSurfDate      : "near surface" profile dates
%   o_nearSurfTransDate : "near surface" profile transmitted date falgs
%   o_nearSurfPres      : "near surface" profile PRES
%   o_nearSurfTemp      : "near surface" profile TEMP
%   o_nearSurfSal       : "near surface" profile PSAL
%   o_inAirDate         : "in air" profile dates
%   o_inAirTransDate    : "in air" profile transmitted date falgs
%   o_inAirPres         : "in air" profile PRES
%   o_inAirTemp         : "in air" profile TEMP
%   o_inAirSal          : "in air" profile PSAL
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/04/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_descProfDate, o_descProfPres, o_descProfTemp, o_descProfSal, ...
   o_ascProfDate, o_ascProfPres, o_ascProfTemp, o_ascProfSal, ...
   o_nearSurfDate, o_nearSurfTransDate, o_nearSurfPres, o_nearSurfTemp, o_nearSurfSal, ...
   o_inAirDate, o_inAirTransDate, o_inAirPres, o_inAirTemp, o_inAirSal] = ...
   create_prv_profile_210(a_dataCTD, a_refDay)

% output parameters initialization
o_descProfDate = [];
o_descProfPres = [];
o_descProfTemp = [];
o_descProfSal = [];
o_ascProfDate = [];
o_ascProfPres = [];
o_ascProfTemp = [];
o_ascProfSal = [];
o_nearSurfDate = [];
o_nearSurfTransDate = [];
o_nearSurfPres = [];
o_nearSurfTemp = [];
o_nearSurfSal = [];
o_inAirDate = [];
o_inAirTransDate = [];
o_inAirPres = [];
o_inAirTemp = [];
o_inAirSal = [];

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_dateDef;

% current cycle number
global g_decArgo_cycleNum;


if (isempty(a_dataCTD))
   return;
end

% retrieve the drift sampling period from the configuration
[configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
inAirSampPeriodSeconds = get_config_value('CONFIG_MC30', configNames, configValues);

for idT = [1 3 13 14]
   idDesc = find(a_dataCTD(:, 1) == idT);
   for idP = 1:length(idDesc)
      data = a_dataCTD(idDesc(idP), 2:end);
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
               break;
            end
            if (idT > 3)
               date = data(1) + a_refDay + (idMeas-1)*inAirSampPeriodSeconds/86400;
               dateTrans = 0;
            end
         end
         
         if (idT == 1)
            o_descProfDate = [o_descProfDate; date];
            o_descProfPres = [o_descProfPres; data(idMeas+15*2)];
            o_descProfTemp = [o_descProfTemp; data(idMeas+15*3)];
            o_descProfSal = [o_descProfSal; data(idMeas+15*4)];
         elseif (idT == 3)
            o_ascProfDate = [o_ascProfDate; date];
            o_ascProfPres = [o_ascProfPres; data(idMeas+15*2)];
            o_ascProfTemp = [o_ascProfTemp; data(idMeas+15*3)];
            o_ascProfSal = [o_ascProfSal; data(idMeas+15*4)];
         elseif (idT == 13)
            o_nearSurfDate = [o_nearSurfDate; date];
            o_nearSurfTransDate = [o_nearSurfTransDate; dateTrans];
            o_nearSurfPres = [o_nearSurfPres; data(idMeas+15*2)];
            o_nearSurfTemp = [o_nearSurfTemp; data(idMeas+15*3)];
            o_nearSurfSal = [o_nearSurfSal; data(idMeas+15*4)];
         elseif (idT == 3)
            o_inAirDate = [o_inAirDate; date];
            o_inAirTransDate = [o_inAirTransDate; dateTrans];
            o_inAirPres = [o_inAirPres; data(idMeas+15*2)];
            o_inAirTemp = [o_inAirTemp; data(idMeas+15*3)];
            o_inAirSal = [o_inAirSal; data(idMeas+15*4)];
         end
      end
   end
end

% sort the data by decreasing pressure
[o_descProfPres, idSorted] = sort(o_descProfPres, 'descend');
o_descProfDate = o_descProfDate(idSorted);
o_descProfTemp = o_descProfTemp(idSorted);
o_descProfSal = o_descProfSal(idSorted);

[o_ascProfPres, idSorted] = sort(o_ascProfPres, 'descend');
o_ascProfDate = o_ascProfDate(idSorted);
o_ascProfTemp = o_ascProfTemp(idSorted);
o_ascProfSal = o_ascProfSal(idSorted);

return;
