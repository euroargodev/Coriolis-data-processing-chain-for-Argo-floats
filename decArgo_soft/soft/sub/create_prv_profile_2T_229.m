% ------------------------------------------------------------------------------
% Create the profiles.
%
% SYNTAX :
% [o_descProfDate, ...
%   o_descProfPresRbr, o_descProfTempRbr, o_descProfSalRbr, o_descProfTempCndcRbr, ...
%   o_descProfPresSbe61, o_descProfTempSbe61, o_descProfSalSbe61, ...
%   o_ascProfDate, ...
%   o_ascProfPresRbr, o_ascProfTempRbr, o_ascProfSalRbr, o_ascProfTempCndcRbr, ...
%   o_ascProfPresSbe61, o_ascProfTempSbe61, o_ascProfSalSbe61] = ...
%   create_prv_profile_2T_229(a_dataCTD, a_dataStartPos)
%
% INPUT PARAMETERS :
%   a_dataCTD      : decoded data of the 2 CTD sensors
%   a_dataStartPos : position of the first useful data
%
% OUTPUT PARAMETERS :
%   o_descProfDate        : descending profile dates
%   o_descProfPresRbr     : descending profile PRES from RBR sensor
%   o_descProfTempRbr     : descending profile TEMP from RBR sensor
%   o_descProfSalRbr      : descending profile PSAL from RBR sensor
%   o_descProfTempCndcRbr : descending profile TEMP_CNDC from RBR sensor
%   o_descProfPresSbe61   : descending profile PRES from SBE61 sensor
%   o_descProfTempSbe61   : descending profile TEMP from SBE61 sensor
%   o_descProfSalSbe61    : descending profile PSAL from SBE61 sensor
%   o_ascProfDate         : ascending profile dates
%   o_ascProfPresRbr      : ascending profile PRES from RBR sensor
%   o_ascProfTempRbr      : ascending profile TEMP from RBR sensor
%   o_ascProfSalRbr       : ascending profile PSAL from RBR sensor
%   o_ascProfTempCndcRbr  : ascending profile TEMP_CNDC from RBR sensor
%   o_ascProfPresSbe61    : ascending profile PRES from SBE61 sensor
%   o_ascProfTempSbe61    : ascending profile TEMP from SBE61 sensor
%   o_ascProfSalSbe61     : ascending profile PSAL from SBE61 sensor
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_descProfDate, ...
   o_descProfPresRbr, o_descProfTempRbr, o_descProfSalRbr, o_descProfTempCndcRbr, ...
   o_descProfPresSbe61, o_descProfTempSbe61, o_descProfSalSbe61, ...
   o_ascProfDate, ...
   o_ascProfPresRbr, o_ascProfTempRbr, o_ascProfSalRbr, o_ascProfTempCndcRbr, ...
   o_ascProfPresSbe61, o_ascProfTempSbe61, o_ascProfSalSbe61] = ...
   create_prv_profile_2T_229(a_dataCTD, a_dataStartPos)

% output parameters initialization
o_descProfDate = [];
o_descProfPresRbr = [];
o_descProfTempRbr = [];
o_descProfSalRbr = [];
o_descProfTempCndcRbr = [];
o_descProfPresSbe61 = [];
o_descProfTempSbe61 = [];
o_descProfSalSbe61 = [];
o_ascProfDate = [];
o_ascProfPresRbr = [];
o_ascProfTempRbr = [];
o_ascProfSalRbr = [];
o_ascProfTempCndcRbr = [];
o_ascProfPresSbe61 = [];
o_ascProfTempSbe61 = [];
o_ascProfSalSbe61 = [];

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;


if (isempty(a_dataCTD))
   return
end

if (~isempty(a_dataCTD))
   for type = [28 29]
      idForType = find(a_dataCTD(:, 1) == type);
      for idP = 1:length(idForType)
         data = a_dataCTD(idForType(idP), a_dataStartPos:end);
         for idMeas = 1:6
            if (idMeas == 1)
               data(idMeas+1) = data(idMeas+1) + g_decArgo_julD2FloatDayOffset;
            else
               if ((data(idMeas+1+6*2) == g_decArgo_presDef) && ...
                     (data(idMeas+1+6*3) == g_decArgo_tempDef) && ...
                     (data(idMeas+1+6*4) == g_decArgo_salDef) && ...
                     (data(idMeas+1+6*5) == g_decArgo_tempDef) && ...
                     (data(idMeas+1+6*6) == g_decArgo_presDef) && ...
                     (data(idMeas+1+6*7) == g_decArgo_tempDef) && ...
                     (data(idMeas+1+6*8) == g_decArgo_salDef))
                  break
               end
            end
            
            if (type == 28)
               o_descProfDate = [o_descProfDate; data(idMeas+1)];

               o_descProfPresRbr = [o_descProfPresRbr; data(idMeas+1+6*2)];
               o_descProfTempRbr = [o_descProfTempRbr; data(idMeas+1+6*3)];
               o_descProfSalRbr = [o_descProfSalRbr; data(idMeas+1+6*4)];
               o_descProfTempCndcRbr = [o_descProfTempCndcRbr; data(idMeas+1+6*5)];

               o_descProfPresSbe61 = [o_descProfPresSbe61; data(idMeas+1+6*6)];
               o_descProfTempSbe61 = [o_descProfTempSbe61; data(idMeas+1+6*7)];
               o_descProfSalSbe61 = [o_descProfSalSbe61; data(idMeas+1+6*8)];

            elseif (type == 29)

               o_ascProfDate = [o_ascProfDate; data(idMeas+1)];

               o_ascProfPresRbr = [o_ascProfPresRbr; data(idMeas+1+6*2)];
               o_ascProfTempRbr = [o_ascProfTempRbr; data(idMeas+1+6*3)];
               o_ascProfSalRbr = [o_ascProfSalRbr; data(idMeas+1+6*4)];
               o_ascProfTempCndcRbr = [o_ascProfTempCndcRbr; data(idMeas+1+6*5)];

               o_ascProfPresSbe61 = [o_ascProfPresSbe61; data(idMeas+1+6*6)];
               o_ascProfTempSbe61 = [o_ascProfTempSbe61; data(idMeas+1+6*7)];
               o_ascProfSalSbe61 = [o_ascProfSalSbe61; data(idMeas+1+6*8)];

            end
         end
      end
   end
end

% sort the data by decreasing pressure
[~, idSorted] = sort(o_descProfPresRbr, 'descend');
o_descProfDate = o_descProfDate(idSorted);
o_descProfPresRbr = o_descProfPresRbr(idSorted);
o_descProfTempRbr = o_descProfTempRbr(idSorted);
o_descProfSalRbr = o_descProfSalRbr(idSorted);
o_descProfTempCndcRbr = o_descProfTempCndcRbr(idSorted);
o_descProfPresSbe61 = o_descProfPresSbe61(idSorted);
o_descProfTempSbe61 = o_descProfTempSbe61(idSorted);
o_descProfSalSbe61 = o_descProfSalSbe61(idSorted);

[~, idSorted] = sort(o_ascProfPresRbr, 'descend');
o_ascProfDate = o_ascProfDate(idSorted);
o_ascProfPresRbr = o_ascProfPresRbr(idSorted);
o_ascProfTempRbr = o_ascProfTempRbr(idSorted);
o_ascProfSalRbr = o_ascProfSalRbr(idSorted);
o_ascProfTempCndcRbr = o_ascProfTempCndcRbr(idSorted);
o_ascProfPresSbe61 = o_ascProfPresSbe61(idSorted);
o_ascProfTempSbe61 = o_ascProfTempSbe61(idSorted);
o_ascProfSalSbe61 = o_ascProfSalSbe61(idSorted);

% some levels of the SBE61 ascending profile are equal to 0, convert these
% values to default ones (needed to create unpumped profile)
idF = find((o_ascProfPresSbe61 == 0) & (o_ascProfTempSbe61 == 0) & (o_ascProfSalSbe61 == 0));
o_ascProfPresSbe61(idF) = g_decArgo_presDef;
o_ascProfTempSbe61(idF) = g_decArgo_tempDef;
o_ascProfSalSbe61(idF) = g_decArgo_salDef;

return
