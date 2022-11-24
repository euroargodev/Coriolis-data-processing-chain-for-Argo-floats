% ------------------------------------------------------------------------------
% Create the profiles.
%
% SYNTAX :
%  [o_ascProfPres, o_ascProfPresTrans, o_ascProfTemp, o_ascProfSal] = ...
%    create_prv_profile_219_220(a_dataCTD)
%
% INPUT PARAMETERS :
%   a_dataCTD : decoded data of the CTD sensor
%
% OUTPUT PARAMETERS :
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
%   09/17/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ascProfPres, o_ascProfPresTrans, o_ascProfTemp, o_ascProfSal] = ...
   create_prv_profile_219_220(a_dataCTD)

% output parameters initialization
o_ascProfPres = [];
o_ascProfPresTrans = [];
o_ascProfTemp = [];
o_ascProfSal = [];

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;


if (isempty(a_dataCTD))
   return
end

nbPackets = size(a_dataCTD, 1);
tabPres = ones(nbPackets*24, 1)*g_decArgo_presDef;
tabPresTrans = zeros(nbPackets*24, 1);
tabTemp = ones(nbPackets*24, 1)*g_decArgo_tempDef;
tabPsal = ones(nbPackets*24, 1)*g_decArgo_salDef;
cpt = 1;
for idP = 1:size(a_dataCTD, 1)
   data = a_dataCTD(idP, :);
   for idMeas = 1:24
      pres = data(idMeas+1);
      temp = data(idMeas+25);
      psal = data(idMeas+49);
      
      if ~((pres == g_decArgo_presDef) && ...
            (temp == g_decArgo_tempDef) && ...
            (psal == g_decArgo_salDef))
         if (idMeas == 1)
            tabPresTrans(cpt) = 1;
         end
         tabPres(cpt) = pres;
         tabTemp(cpt) = temp;
         tabPsal(cpt) = psal;
         cpt = cpt + 1;
      end
   end
end
tabPres(cpt-1:end) = [];
tabPresTrans(cpt-1:end) = [];
tabTemp(cpt-1:end) = [];
tabPsal(cpt-1:end) = [];

% sort the data by decreasing pressure
[~, idSorted] = sort(tabPres, 'descend');
tabPres = tabPres(idSorted);
tabPresTrans = tabPresTrans(idSorted);
tabTemp = tabTemp(idSorted);
tabPsal = tabPsal(idSorted);

% output parameters
o_ascProfPres = tabPres;
o_ascProfPresTrans = tabPresTrans;
o_ascProfTemp = tabTemp;
o_ascProfSal = tabPsal;

return
