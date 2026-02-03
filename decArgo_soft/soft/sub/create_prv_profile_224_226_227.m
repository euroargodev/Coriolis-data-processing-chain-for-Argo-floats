% ------------------------------------------------------------------------------
% Create the profiles.
%
% SYNTAX :
% [o_descProfDate, o_descProfPres, o_descProfTemp, o_descProfSal, o_descProfSalCor, o_descProfTempCndc, ...
%   o_ascProfDate, o_ascProfPres, o_ascProfTemp, o_ascProfSal, o_ascProfSalCor, o_ascProfTempCndc, ...
%   o_nearSurfDate, o_nearSurfTransDate, o_nearSurfPres, o_nearSurfTemp, o_nearSurfSal, o_nearSurfSalCor, o_nearSurfTempCndc, ...
%   o_inAirDate, o_inAirTransDate, o_inAirPres, o_inAirTemp, o_inAirSal, o_inAirSalCor, o_inAirTempCndc] = ...
%   create_prv_profile_224_226_227(a_dataCTDRbr, a_deepCycleFlag, a_refDay)
%
% INPUT PARAMETERS :
%   a_dataCTDRbr     : decoded data of the CTD sensor
%   a_deepCycleFlag  : 1 if it is a deep cycle, 0 if it is a surface one
%   a_refDay         : reference day (day of the first descent)
%
% OUTPUT PARAMETERS :
%   o_descProfDate      : descending profile dates
%   o_descProfPres      : descending profile PRES
%   o_descProfTemp      : descending profile TEMP
%   o_descProfSal       : descending profile PSAL
%   o_descProfSalCor    : descending profile PSAL_DynamicCorrection
%   o_descProfTempCndc  : descending profile TEMP_CNDC
%   o_ascProfDate       : ascending profile dates
%   o_ascProfPres       : ascending profile PRES
%   o_ascProfTemp       : ascending profile TEMP
%   o_ascProfSal        : ascending profile PSAL
%   o_ascProfSalCor     : ascending profile PSAL_DynamicCorrection
%   o_ascProfTempCndc   : ascending profile TEMP_CNDC
%   o_nearSurfDate      : "near surface" profile dates
%   o_nearSurfTransDate : "near surface" profile transmitted date flags
%   o_nearSurfPres      : "near surface" profile PRES
%   o_nearSurfTemp      : "near surface" profile TEMP
%   o_nearSurfSal       : "near surface" profile PSAL
%   o_nearSurfSalCor    : "near surface" profile PSAL_DynamicCorrection
%   o_nearSurfTempCndc  : "near surface" profile TEMP_CNDC
%   o_inAirDate         : "in air" profile dates
%   o_inAirTransDate    : "in air" profile transmitted date flags
%   o_inAirPres         : "in air" profile PRES
%   o_inAirTemp         : "in air" profile TEMP
%   o_inAirSal          : "in air" profile PSAL
%   o_inAirSalCor       : "in air" profile PSAL_DynamicCorrection
%   o_inAirTempCndc     : "in air" profile TEMP_CNDC
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/08/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_descProfDate, o_descProfPres, o_descProfTemp, o_descProfSal, o_descProfSalCor, o_descProfTempCndc, ...
   o_ascProfDate, o_ascProfPres, o_ascProfTemp, o_ascProfSal, o_ascProfSalCor, o_ascProfTempCndc, ...
   o_nearSurfDate, o_nearSurfTransDate, o_nearSurfPres, o_nearSurfTemp, o_nearSurfSal, o_nearSurfSalCor, o_nearSurfTempCndc, ...
   o_inAirDate, o_inAirTransDate, o_inAirPres, o_inAirTemp, o_inAirSal, o_inAirSalCor, o_inAirTempCndc] = ...
   create_prv_profile_224_226_227(a_dataCTDRbr, a_deepCycleFlag, a_refDay)

% output parameters initialization
o_descProfDate = [];
o_descProfPres = [];
o_descProfTemp = [];
o_descProfSal = [];
o_descProfSalCor = [];
o_descProfTempCndc = [];
o_ascProfDate = [];
o_ascProfPres = [];
o_ascProfTemp = [];
o_ascProfSal = [];
o_ascProfSalCor = [];
o_ascProfTempCndc = [];
o_nearSurfDate = [];
o_nearSurfTransDate = [];
o_nearSurfPres = [];
o_nearSurfTemp = [];
o_nearSurfSal = [];
o_nearSurfSalCor = [];
o_nearSurfTempCndc = [];
o_inAirDate = [];
o_inAirTransDate = [];
o_inAirPres = [];
o_inAirTemp = [];
o_inAirSal = [];
o_inAirSalCor = [];
o_inAirTempCndc = [];

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_dateDef;

% current cycle number
global g_decArgo_cycleNum;

% float configuration
global g_decArgo_floatConfig;


if (isempty(a_dataCTDRbr))
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

profTypeList = [1, 15, 25, 36, ... % descending profile
   3, 17, 28, 38, ...              % ascending profile
   13, 18, 29, 39, ...             % NS profile
   14, 19, 30, 40];                % IA profile
idProf = find(ismember(a_dataCTDRbr(:, 1), profTypeList));
typeList = unique(a_dataCTDRbr(idProf, 1));
for idT = 1:length(typeList)
   type = typeList(idT);
   idForType = find(a_dataCTDRbr(:, 1) == type);

   tabDate = [];
   tabTransDate = [];
   tabPres = [];
   tabTemp = [];
   tabSal = [];
   tabSalCor = [];
   tabTempCndc = [];
   for idP = 1:length(idForType)
      data = a_dataCTDRbr(idForType(idP), 3:end);

      switch (type)
         case {1, 3, 13, 14}
            for idMeas = 1:11
               date = g_decArgo_dateDef;
               dateTrans = 0;
               if (idMeas == 1)
                  date = data(idMeas) + a_refDay;
                  dateTrans = 1;
               else
                  if ((data(idMeas+11*2) == g_decArgo_presDef) && ...
                        (data(idMeas+11*3) == g_decArgo_tempDef) && ...
                        (data(idMeas+11*4) == g_decArgo_salDef))
                     break
                  end
                  if (ismember(type, [13, 14]))
                     date = data(1) + a_refDay + (idMeas-1)*inAirSampPeriodSeconds/86400;
                  end
               end

               tabDate = [tabDate; date];
               tabTransDate = [tabTransDate; dateTrans];
               tabPres = [tabPres; data(idMeas+11*2)];
               tabTemp = [tabTemp; data(idMeas+11*3)];
               tabSal = [tabSal; data(idMeas+11*4)];
            end
         case {15, 17, 18, 19}
            for idMeas = 1:11
               date = g_decArgo_dateDef;
               dateTrans = 0;
               if (idMeas == 1)
                  date = data(idMeas) + a_refDay;
                  dateTrans = 1;
               else
                  if ((data(idMeas+11*2) == g_decArgo_presDef) && ...
                        (data(idMeas+11*3) == g_decArgo_tempDef) && ...
                        (data(idMeas+11*4) == g_decArgo_salDef) && ...
                        (data(idMeas+11*5) == g_decArgo_tempDef))
                     break
                  end
                  if (ismember(type, [18, 19]))
                     date = data(1) + a_refDay + (idMeas-1)*inAirSampPeriodSeconds/86400;
                  end
               end

               tabDate = [tabDate; date];
               tabTransDate = [tabTransDate; dateTrans];
               tabPres = [tabPres; data(idMeas+11*2)];
               tabTemp = [tabTemp; data(idMeas+11*3)];
               tabSal = [tabSal; data(idMeas+11*4)];
               tabTempCndc = [tabTempCndc; data(idMeas+11*5)];
            end
         case {25, 28, 29, 30}
            for idMeas = 1:11
               date = g_decArgo_dateDef;
               dateTrans = 0;
               if (idMeas == 1)
                  date = data(idMeas) + a_refDay;
                  dateTrans = 1;
               else
                  if ((data(idMeas+11*2) == g_decArgo_presDef) && ...
                        (data(idMeas+11*3) == g_decArgo_tempDef) && ...
                        (data(idMeas+11*4) == g_decArgo_salDef) && ...
                        (data(idMeas+11*5) == g_decArgo_salDef))
                     break
                  end
                  if (ismember(type, [29, 30]))
                     date = data(1) + a_refDay + (idMeas-1)*inAirSampPeriodSeconds/86400;
                  end
               end

               tabDate = [tabDate; date];
               tabTransDate = [tabTransDate; dateTrans];
               tabPres = [tabPres; data(idMeas+11*2)];
               tabTemp = [tabTemp; data(idMeas+11*3)];
               tabSal = [tabSal; data(idMeas+11*4)];
               tabSalCor = [tabSalCor; data(idMeas+11*5)];
            end
         case {36, 38, 39, 40}
            for idMeas = 1:11
               date = g_decArgo_dateDef;
               dateTrans = 0;
               if (idMeas == 1)
                  date = data(idMeas) + a_refDay;
                  dateTrans = 1;
               else
                  if ((data(idMeas+11*2) == g_decArgo_presDef) && ...
                        (data(idMeas+11*3) == g_decArgo_tempDef) && ...
                        (data(idMeas+11*4) == g_decArgo_salDef))
                     break
                  end
                  if (ismember(type, [39, 40]))
                     date = data(1) + a_refDay + (idMeas-1)*inAirSampPeriodSeconds/86400;
                  end
               end

               tabDate = [tabDate; date];
               tabTransDate = [tabTransDate; dateTrans];
               tabPres = [tabPres; data(idMeas+11*2)];
               tabTemp = [tabTemp; data(idMeas+11*3)];
               tabSalCor = [tabSalCor; data(idMeas+11*4)];
            end
      end
   end

   switch (type)
      case 1
         o_descProfDate = tabDate;
         o_descProfPres = tabPres;
         o_descProfTemp = tabTemp;
         o_descProfSal = tabSal;
      case 3
         o_ascProfDate = tabDate;
         o_ascProfPres = tabPres;
         o_ascProfTemp = tabTemp;
         o_ascProfSal = tabSal;
      case 13
         o_nearSurfDate = tabDate;
         o_nearSurfTransDate = tabTransDate;
         o_nearSurfPres = tabPres;
         o_nearSurfTemp = tabTemp;
         o_nearSurfSal = tabSal;
      case 14
         o_inAirDate = tabDate;
         o_inAirTransDate = tabTransDate;
         o_inAirPres = tabPres;
         o_inAirTemp = tabTemp;
         o_inAirSal = tabSal;

      case 15
         o_descProfDate = tabDate;
         o_descProfPres = tabPres;
         o_descProfTemp = tabTemp;
         o_descProfSal = tabSal;
         o_descProfTempCndc = tabTempCndc;
      case 17
         o_ascProfDate = tabDate;
         o_ascProfPres = tabPres;
         o_ascProfTemp = tabTemp;
         o_ascProfSal = tabSal;
         o_ascProfTempCndc = tabTempCndc;
      case 18
         o_nearSurfDate = tabDate;
         o_nearSurfTransDate = tabTransDate;
         o_nearSurfPres = tabPres;
         o_nearSurfTemp = tabTemp;
         o_nearSurfSal = tabSal;
         o_nearSurfTempCndc = tabTempCndc;
      case 19
         o_inAirDate = tabDate;
         o_inAirTransDate = tabTransDate;
         o_inAirPres = tabPres;
         o_inAirTemp = tabTemp;
         o_inAirSal = tabSal;
         o_inAirTempCndc = tabTempCndc;

      case 25
         o_descProfDate = tabDate;
         o_descProfPres = tabPres;
         o_descProfTemp = tabTemp;
         o_descProfSal = tabSal;
         o_descProfSalCor = tabSalCor;
      case 28
         o_ascProfDate = tabDate;
         o_ascProfPres = tabPres;
         o_ascProfTemp = tabTemp;
         o_ascProfSal = tabSal;
         o_ascProfSalCor = tabSalCor;
      case 29
         o_nearSurfDate = tabDate;
         o_nearSurfTransDate = tabTransDate;
         o_nearSurfPres = tabPres;
         o_nearSurfTemp = tabTemp;
         o_nearSurfSal = tabSal;
         o_nearSurfSalCor = tabSalCor;
      case 30
         o_inAirDate = tabDate;
         o_inAirTransDate = tabTransDate;
         o_inAirPres = tabPres;
         o_inAirTemp = tabTemp;
         o_inAirSal = tabSal;
         o_inAirSalCor = tabSalCor;

      case 36
         o_descProfDate = tabDate;
         o_descProfPres = tabPres;
         o_descProfTemp = tabTemp;
         o_descProfSalCor = tabSalCor;
      case 38
         o_ascProfDate = tabDate;
         o_ascProfPres = tabPres;
         o_ascProfTemp = tabTemp;
         o_ascProfSalCor = tabSalCor;
      case 39
         o_nearSurfDate = tabDate;
         o_nearSurfTransDate = tabTransDate;
         o_nearSurfPres = tabPres;
         o_nearSurfTemp = tabTemp;
         o_nearSurfSalCor = tabSalCor;
      case 40
         o_inAirDate = tabDate;
         o_inAirTransDate = tabTransDate;
         o_inAirPres = tabPres;
         o_inAirTemp = tabTemp;
         o_inAirSalCor = tabSalCor;
   end
end

% sort the data by decreasing pressure
[o_descProfPres, idSorted] = sort(o_descProfPres, 'descend');
o_descProfDate = o_descProfDate(idSorted);
o_descProfTemp = o_descProfTemp(idSorted);
o_descProfSal = o_descProfSal(idSorted);
if (~isempty(o_descProfSalCor))
   o_descProfSalCor = o_descProfSalCor(idSorted);
end
if (~isempty(o_descProfTempCndc))
   o_descProfTempCndc = o_descProfTempCndc(idSorted);
end

[o_ascProfPres, idSorted] = sort(o_ascProfPres, 'descend');
o_ascProfDate = o_ascProfDate(idSorted);
o_ascProfTemp = o_ascProfTemp(idSorted);
o_ascProfSal = o_ascProfSal(idSorted);
if (~isempty(o_ascProfSalCor))
   o_ascProfSalCor = o_ascProfSalCor(idSorted);
end
if (~isempty(o_ascProfTempCndc))
   o_ascProfTempCndc = o_ascProfTempCndc(idSorted);
end

return
