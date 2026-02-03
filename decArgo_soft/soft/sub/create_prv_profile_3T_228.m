% ------------------------------------------------------------------------------
% Create the profiles.
%
% SYNTAX :
% [o_descProfDate, ...
%   o_descProfPresSbe41, o_descProfTempSbe41, o_descProfSalSbe41, ...
%   o_descProfPresSbe61, o_descProfTempSbe61, o_descProfSalSbe61, ...
%   o_descProfPresRbr, o_descProfTempRbr, o_descProfSalRbr, o_descProfTempCndcRbr, ...
%   o_ascProfDate, ...
%   o_ascProfPresSbe41, o_ascProfTempSbe41, o_ascProfSalSbe41, ...
%   o_ascProfPresSbe61, o_ascProfTempSbe61, o_ascProfSalSbe61, ...
%   o_ascProfPresRbr, o_ascProfTempRbr, o_ascProfSalRbr, o_ascProfTempCndcRbr] = ...
%   create_prv_profile_3T_228(a_dataCTD, a_dataStartPos)
%
% INPUT PARAMETERS :
%   a_dataCTD      : decoded data of the 3 CTD sensors
%   a_dataStartPos : position of the first useful data
%
% OUTPUT PARAMETERS :
%   o_descProfDate        : descending profile dates
%   o_descProfPresSbe41   : descending profile PRES from SBE41 sensor
%   o_descProfTempSbe41   : descending profile TEMP from SBE41 sensor
%   o_descProfSalSbe41    : descending profile PSAL from SBE41 sensor
%   o_descProfPresSbe61   : descending profile PRES from SBE61 sensor
%   o_descProfTempSbe61   : descending profile TEMP from SBE61 sensor
%   o_descProfSalSbe61    : descending profile PSAL from SBE61 sensor
%   o_descProfPresRbr     : descending profile PRES from RBR sensor
%   o_descProfTempRbr     : descending profile TEMP from RBR sensor
%   o_descProfSalRbr      : descending profile PSAL from RBR sensor
%   o_descProfTempCndcRbr : descending profile TEMP_CNDC from RBR sensor
%   o_ascProfDate         : ascending profile dates
%   o_ascProfPresSbe41    : ascending profile PRES from SBE41 sensor
%   o_ascProfTempSbe41    : ascending profile TEMP from SBE41 sensor
%   o_ascProfSalSbe41     : ascending profile PSAL from SBE41 sensor
%   o_ascProfPresSbe61    : ascending profile PRES from SBE61 sensor
%   o_ascProfTempSbe61    : ascending profile TEMP from SBE61 sensor
%   o_ascProfSalSbe61     : ascending profile PSAL from SBE61 sensor
%   o_ascProfPresRbr      : ascending profile PRES from RBR sensor
%   o_ascProfTempRbr      : ascending profile TEMP from RBR sensor
%   o_ascProfSalRbr       : ascending profile PSAL from RBR sensor
%   o_ascProfTempCndcRbr  : ascending profile TEMP_CNDC from RBR sensor
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/22/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_descProfDate, ...
   o_descProfPresSbe41, o_descProfTempSbe41, o_descProfSalSbe41, ...
   o_descProfPresSbe61, o_descProfTempSbe61, o_descProfSalSbe61, ...
   o_descProfPresRbr, o_descProfTempRbr, o_descProfSalRbr, o_descProfTempCndcRbr, ...
   o_ascProfDate, ...
   o_ascProfPresSbe41, o_ascProfTempSbe41, o_ascProfSalSbe41, ...
   o_ascProfPresSbe61, o_ascProfTempSbe61, o_ascProfSalSbe61, ...
   o_ascProfPresRbr, o_ascProfTempRbr, o_ascProfSalRbr, o_ascProfTempCndcRbr] = ...
   create_prv_profile_3T_228(a_dataCTD, a_dataStartPos)

% output parameters initialization
o_descProfDate = [];
o_descProfPresSbe41 = [];
o_descProfTempSbe41 = [];
o_descProfSalSbe41 = [];
o_descProfPresSbe61 = [];
o_descProfTempSbe61 = [];
o_descProfSalSbe61 = [];
o_descProfPresRbr = [];
o_descProfTempRbr = [];
o_descProfSalRbr = [];
o_descProfTempCndcRbr = [];
o_ascProfDate = [];
o_ascProfPresSbe41 = [];
o_ascProfTempSbe41 = [];
o_ascProfSalSbe41 = [];
o_ascProfPresSbe61 = [];
o_ascProfTempSbe61 = [];
o_ascProfSalSbe61 = [];
o_ascProfPresRbr = [];
o_ascProfTempRbr = [];
o_ascProfSalRbr = [];
o_ascProfTempCndcRbr = [];

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
   for type = [23 25]
      idForType = find(a_dataCTD(:, 1) == type);
      for idP = 1:length(idForType)
         data = a_dataCTD(idForType(idP), a_dataStartPos:end);
         for idMeas = 1:4
            if (idMeas == 1)
               data(idMeas+1) = data(idMeas+1) + g_decArgo_julD2FloatDayOffset;
            else
               if ((data(idMeas+1+4*2) == g_decArgo_presDef) && ...
                     (data(idMeas+1+4*3) == g_decArgo_tempDef) && ...
                     (data(idMeas+1+4*4) == g_decArgo_salDef) && ...
                     (data(idMeas+1+4*5) == g_decArgo_presDef) && ...
                     (data(idMeas+1+4*6) == g_decArgo_tempDef) && ...
                     (data(idMeas+1+4*7) == g_decArgo_salDef) && ...
                     (data(idMeas+1+4*8) == g_decArgo_presDef) && ...
                     (data(idMeas+1+4*9) == g_decArgo_tempDef) && ...
                     (data(idMeas+1+4*10) == g_decArgo_salDef) && ...
                     (data(idMeas+1+4*11) == g_decArgo_tempDef))
                  break
               end
            end
            
            if (type == 23)
               o_descProfDate = [o_descProfDate; data(idMeas+1)];

               o_descProfPresSbe41 = [o_descProfPresSbe41; data(idMeas+1+4*2)];
               o_descProfTempSbe41 = [o_descProfTempSbe41; data(idMeas+1+4*3)];
               o_descProfSalSbe41 = [o_descProfSalSbe41; data(idMeas+1+4*4)];

               o_descProfPresSbe61 = [o_descProfPresSbe61; data(idMeas+1+4*5)];
               o_descProfTempSbe61 = [o_descProfTempSbe61; data(idMeas+1+4*6)];
               o_descProfSalSbe61 = [o_descProfSalSbe61; data(idMeas+1+4*7)];

               o_descProfPresRbr = [o_descProfPresRbr; data(idMeas+1+4*8)];
               o_descProfTempRbr = [o_descProfTempRbr; data(idMeas+1+4*9)];
               o_descProfSalRbr = [o_descProfSalRbr; data(idMeas+1+4*10)];
               o_descProfTempCndcRbr = [o_descProfTempCndcRbr; data(idMeas+1+4*11)];

            elseif (type == 25)

               o_ascProfDate = [o_ascProfDate; data(idMeas+1)];

               o_ascProfPresSbe41 = [o_ascProfPresSbe41; data(idMeas+1+4*2)];
               o_ascProfTempSbe41 = [o_ascProfTempSbe41; data(idMeas+1+4*3)];
               o_ascProfSalSbe41 = [o_ascProfSalSbe41; data(idMeas+1+4*4)];

               o_ascProfPresSbe61 = [o_ascProfPresSbe61; data(idMeas+1+4*5)];
               o_ascProfTempSbe61 = [o_ascProfTempSbe61; data(idMeas+1+4*6)];
               o_ascProfSalSbe61 = [o_ascProfSalSbe61; data(idMeas+1+4*7)];

               o_ascProfPresRbr = [o_ascProfPresRbr; data(idMeas+1+4*8)];
               o_ascProfTempRbr = [o_ascProfTempRbr; data(idMeas+1+4*9)];
               o_ascProfSalRbr = [o_ascProfSalRbr; data(idMeas+1+4*10)];
               o_ascProfTempCndcRbr = [o_ascProfTempCndcRbr; data(idMeas+1+4*11)];
            end
         end
      end
   end
end

% sort the data by decreasing pressure
[~, idSorted] = sort(o_descProfPresSbe41, 'descend');
o_descProfDate = o_descProfDate(idSorted);
o_descProfPresSbe41 = o_descProfPresSbe41(idSorted);
o_descProfTempSbe41 = o_descProfTempSbe41(idSorted);
o_descProfSalSbe41 = o_descProfSalSbe41(idSorted);
o_descProfPresSbe61 = o_descProfPresSbe61(idSorted);
o_descProfTempSbe61 = o_descProfTempSbe61(idSorted);
o_descProfSalSbe61 = o_descProfSalSbe61(idSorted);
o_descProfPresRbr = o_descProfPresRbr(idSorted);
o_descProfTempRbr = o_descProfTempRbr(idSorted);
o_descProfSalRbr = o_descProfSalRbr(idSorted);
o_descProfTempCndcRbr = o_descProfTempCndcRbr(idSorted);

[~, idSorted] = sort(o_ascProfPresSbe41, 'descend');
o_ascProfDate = o_ascProfDate(idSorted);
o_ascProfPresSbe41 = o_ascProfPresSbe41(idSorted);
o_ascProfTempSbe41 = o_ascProfTempSbe41(idSorted);
o_ascProfSalSbe41 = o_ascProfSalSbe41(idSorted);
o_ascProfPresSbe61 = o_ascProfPresSbe61(idSorted);
o_ascProfTempSbe61 = o_ascProfTempSbe61(idSorted);
o_ascProfSalSbe61 = o_ascProfSalSbe61(idSorted);
o_ascProfPresRbr = o_ascProfPresRbr(idSorted);
o_ascProfTempRbr = o_ascProfTempRbr(idSorted);
o_ascProfSalRbr = o_ascProfSalRbr(idSorted);
o_ascProfTempCndcRbr = o_ascProfTempCndcRbr(idSorted);

return
