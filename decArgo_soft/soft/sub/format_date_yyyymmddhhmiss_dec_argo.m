% ------------------------------------------------------------------------------
% Format a julian 1950 date in the yyyymmddHHMISS format.
%
% SYNTAX :
%   [o_formattedDate] = format_date_yyyymmddhhmiss_dec_argo(a_julDay)
%
% INPUT PARAMETERS :
%   a_julDay : julian 1950 date
%
% OUTPUT PARAMETERS :
%   o_formattedDate : date in the yyyymmddHHMISS format
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/10/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_formattedDate] = format_date_yyyymmddhhmiss_dec_argo(a_julDay)

% default values
global g_decArgo_dateDef;

% output parameters initialization
o_formattedDate = [];

[dayNum, dd, mm, yyyy, HH, MI, SS] = format_juld_dec_argo(a_julDay);

for idDate = 1:length(dayNum)
   if (a_julDay(idDate) ~= g_decArgo_dateDef)
      o_formattedDate = [o_formattedDate; sprintf('%04d%02d%02d%02d%02d%02d', ...
         yyyy(idDate), mm(idDate), dd(idDate), HH(idDate), MI(idDate), SS(idDate))];
   else
      o_formattedDate = [o_formattedDate; '99999999999999'];
   end
end

return
