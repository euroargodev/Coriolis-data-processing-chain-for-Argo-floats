% ------------------------------------------------------------------------------
% Correct dates of dataCTD2T descending and ascending profiles (the day is
% erroneous).
%
% SYNTAX :
% [o_descProfDate2T, o_ascProfDate2T] = create_prv_profile_dates_2T_229( ...
%   a_descProfDate2T, a_ascProfDate2T, a_cycleTimeData)
%
% INPUT PARAMETERS :
%   a_descProfDate2T : descending profile dates
%   a_ascProfDate2T  : ascending profile dates
%   a_cycleTimeData  : cycle timings structure
%
% OUTPUT PARAMETERS :
%   o_descProfDate2T : descending profile dates
%   o_ascProfDate2T  : ascending profile dates
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/28/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_descProfDate2T, o_ascProfDate2T] = create_prv_profile_dates_2T_229( ...
   a_descProfDate2T, a_ascProfDate2T, a_cycleTimeData)

% output parameters initialization
o_descProfDate2T = a_descProfDate2T;
o_ascProfDate2T = a_ascProfDate2T;

% default values
global g_decArgo_dateDef;


if (~isempty(o_descProfDate2T) && ~isempty(a_cycleTimeData.descentToParkStartDate))
   prevDate = a_cycleTimeData.descentToParkStartDate;
   idDated = find(o_descProfDate2T ~= g_decArgo_dateDef);
   for idL = flipud(idDated)'
      if (o_descProfDate2T(idL) < prevDate)
         offset = 1;
         while (o_descProfDate2T(idL) + offset < prevDate)
            offset = offset + 1;
         end
         o_descProfDate2T(idL) = o_descProfDate2T(idL) + offset;
      end
      prevDate = o_descProfDate2T(idL);
   end
end

if (~isempty(o_ascProfDate2T) && ~isempty(a_cycleTimeData.ascentStartDate))
   prevDate = a_cycleTimeData.ascentStartDate;
   idDated = find(o_ascProfDate2T ~= g_decArgo_dateDef);
   for idL = idDated'
      if (o_ascProfDate2T(idL) < prevDate)
         offset = 1;
         while (o_ascProfDate2T(idL) + offset < prevDate)
            offset = offset + 1;
         end
         o_ascProfDate2T(idL) = o_ascProfDate2T(idL) + offset;
      end
      prevDate = o_ascProfDate2T(idL);
   end
end

return
