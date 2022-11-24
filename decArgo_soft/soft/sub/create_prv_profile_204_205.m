% ------------------------------------------------------------------------------
% Create the profiles.
%
% SYNTAX :
%  [o_descProfDate, o_descProfPres, o_descProfTemp, o_descProfSal, ...
%    o_ascProfDate, o_ascProfPres, o_ascProfTemp, o_ascProfSal] = ...
%    create_prv_profile_204_205(a_dataCTD, a_refDay)
%
% INPUT PARAMETERS :
%   a_dataCTD : decoded data of the CTD sensor
%   a_refDay  : reference day (day of the first descent)
%
% OUTPUT PARAMETERS :
%   o_descProfDate        : descending profile dates
%   o_descProfPres        : descending profile PRES
%   o_descProfTemp        : descending profile TEMP
%   o_descProfSal         : descending profile PSAL
%   o_ascProfDate         : ascending profile dates
%   o_ascProfPres         : ascending profile PRES
%   o_ascProfTemp         : ascending profile TEMP
%   o_ascProfSal          : ascending profile PSAL
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/11/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_descProfDate, o_descProfPres, o_descProfTemp, o_descProfSal, ...
   o_ascProfDate, o_ascProfPres, o_ascProfTemp, o_ascProfSal] = ...
   create_prv_profile_204_205(a_dataCTD, a_refDay)

% output parameters initialization
o_descProfDate = [];
o_descProfPres = [];
o_descProfTemp = [];
o_descProfSal = [];
o_ascProfDate = [];
o_ascProfPres = [];
o_ascProfTemp = [];
o_ascProfSal = [];

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;


if (isempty(a_dataCTD))
   return;
end

for idT = [1 3]
   idDesc = find(a_dataCTD(:, 1) == idT);
   for idP = 1:length(idDesc)
      data = a_dataCTD(idDesc(idP), :);
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
         
         if (idT == 1)
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
