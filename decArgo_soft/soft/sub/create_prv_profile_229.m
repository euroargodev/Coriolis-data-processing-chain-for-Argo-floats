% ------------------------------------------------------------------------------
% Create the profiles.
%
% SYNTAX :
% [o_descProfDate, o_descProfPres, o_descProfTemp, o_descProfSal, o_descProfTempCndc, ...
%   o_ascProfDate, o_ascProfPres, o_ascProfTemp, o_ascProfSal, o_ascProfTempCndc] = ...
%   create_prv_profile_229(a_dataCTDRbr, a_refDay)
%
% INPUT PARAMETERS :
%   a_dataCTDRbr : decoded data of the CTD sensor
%   a_refDay     : reference day (day of the first descent)
%
% OUTPUT PARAMETERS :
%   o_descProfDate      : descending profile dates
%   o_descProfPres      : descending profile PRES
%   o_descProfTemp      : descending profile TEMP
%   o_descProfSal       : descending profile PSAL
%   o_descProfTempCndc  : descending profile TEMP_CNDC
%   o_ascProfDate       : ascending profile dates
%   o_ascProfPres       : ascending profile PRES
%   o_ascProfTemp       : ascending profile TEMP
%   o_ascProfSal        : ascending profile PSAL
%   o_ascProfTempCndc   : ascending profile TEMP_CNDC
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_descProfDate, o_descProfPres, o_descProfTemp, o_descProfSal, o_descProfTempCndc, ...
   o_ascProfDate, o_ascProfPres, o_ascProfTemp, o_ascProfSal, o_ascProfTempCndc] = ...
   create_prv_profile_229(a_dataCTDRbr, a_refDay)

% output parameters initialization
o_descProfDate = [];
o_descProfPres = [];
o_descProfTemp = [];
o_descProfSal = [];
o_descProfTempCndc = [];
o_ascProfDate = [];
o_ascProfPres = [];
o_ascProfTemp = [];
o_ascProfSal = [];
o_ascProfTempCndc = [];

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_dateDef;


if (isempty(a_dataCTDRbr))
   return
end

profTypeList = [1, ... % descending profile
   3];                 % ascending profile
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
   tabTempCndc = [];
   for idP = 1:length(idForType)
      data = a_dataCTDRbr(idForType(idP), 3:end);

      switch (type)
         case {1, 3}
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
               end

               tabDate = [tabDate; date];
               tabTransDate = [tabTransDate; dateTrans];
               tabPres = [tabPres; data(idMeas+11*2)];
               tabTemp = [tabTemp; data(idMeas+11*3)];
               tabSal = [tabSal; data(idMeas+11*4)];
               tabTempCndc = [tabTempCndc; data(idMeas+11*5)];
            end
      end
   end

   switch (type)
      case 1
         o_descProfDate = tabDate;
         o_descProfPres = tabPres;
         o_descProfTemp = tabTemp;
         o_descProfSal = tabSal;
         o_descProfTempCndc = tabTempCndc;
      case 3
         o_ascProfDate = tabDate;
         o_ascProfPres = tabPres;
         o_ascProfTemp = tabTemp;
         o_ascProfSal = tabSal;
         o_ascProfTempCndc = tabTempCndc;
   end
end

% sort the data by decreasing pressure
[o_descProfPres, idSorted] = sort(o_descProfPres, 'descend');
o_descProfDate = o_descProfDate(idSorted);
o_descProfTemp = o_descProfTemp(idSorted);
o_descProfSal = o_descProfSal(idSorted);
o_descProfTempCndc = o_descProfTempCndc(idSorted);

[o_ascProfPres, idSorted] = sort(o_ascProfPres, 'descend');
o_ascProfDate = o_ascProfDate(idSorted);
o_ascProfTemp = o_ascProfTemp(idSorted);
o_ascProfSal = o_ascProfSal(idSorted);
o_ascProfTempCndc = o_ascProfTempCndc(idSorted);

return
