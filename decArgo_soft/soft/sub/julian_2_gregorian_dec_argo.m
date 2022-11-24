% ------------------------------------------------------------------------------
% Convert a julian 1950 date to a gregorian date.
%
% SYNTAX :
%   [o_gregorianDate] = julian_2_gregorian_dec_argo(a_julDay)
%
% INPUT PARAMETERS :
%   a_julDay : julian 1950 date
%
% OUTPUT PARAMETERS :
%   o_gregorianDate : gregorain date (in 'yyyy/mm/dd HH:MM' or 
%                     'yyyy/mm/dd HH:MM:SS' format)
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_gregorianDate] = julian_2_gregorian_dec_argo(a_julDay)

% default values
global g_decArgo_dateDef;

% output parameters initialization
o_gregorianDate = [];

[dayNum, dd, mm, yyyy, HH, MI, SS] = format_juld_dec_argo(a_julDay);

for idDate = 1:length(dayNum)
   if (a_julDay(idDate) ~= g_decArgo_dateDef)
      o_gregorianDate = [o_gregorianDate; sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
         yyyy(idDate), mm(idDate), dd(idDate), HH(idDate), MI(idDate), SS(idDate))];
   else
      o_gregorianDate = [o_gregorianDate; '9999/99/99 99:99:99'];
   end
end

return
