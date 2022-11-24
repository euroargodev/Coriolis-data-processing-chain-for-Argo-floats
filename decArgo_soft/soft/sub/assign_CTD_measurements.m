% ------------------------------------------------------------------------------
% Assign P, T and S from a CTD at given dates (timely closest association).
%
% SYNTAX :
%  [o_ctdLinkData] = assign_CTD_measurements( ...
%    a_ctdDates, a_ctdData, a_dates)
%
% INPUT PARAMETERS :
%   a_ctdDates : CTD dates
%   a_ctdData  : CTD P, T and S measurements
%   a_dates    : assignment dates
%
% OUTPUT PARAMETERS :
%   o_ctdLinkData : CTD assigned data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/10/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ctdLinkData] = assign_CTD_measurements( ...
   a_ctdDates, a_ctdData, a_dates)

% output parameters initialization
o_ctdLinkData = [];


if (isempty(a_ctdDates))
   return
end

paramJuld = get_netcdf_param_attributes('JULD');
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramSal = get_netcdf_param_attributes('PSAL');

o_ctdLinkData = [ ...
   ones(length(a_dates), 1)*paramPres.fillValue ...
   ones(length(a_dates), 1)*paramTemp.fillValue ...
   ones(length(a_dates), 1)*paramSal.fillValue ...
   ];

idDel = find(a_ctdDates == paramJuld.fillValue);
a_ctdDates(idDel) = [];
a_ctdData(idDel, :) = [];
for idL = 1:length(a_dates)
   if (a_dates(idL) ~= paramJuld.fillValue)
      [valMin, idMin] = min(abs(a_dates(idL) - a_ctdDates));
      o_ctdLinkData(idL, :) = a_ctdData(idMin, :);
   end
end

return
