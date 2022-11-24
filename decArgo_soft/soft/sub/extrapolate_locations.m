% ------------------------------------------------------------------------------
% Extrapolate locations.
%
% SYNTAX :
%  [o_extrapLocLon, o_extrapLocLat] = extrapolate_locations(...
%    a_firstLocDate, a_firstLocLon, a_firstLocLat, ...
%    a_secondLocDate, a_secondLocLon, a_secondLocLat, ...
%    a_extrapDate)
%
% INPUT PARAMETERS :
%   a_firstLocDate  : date of the first location
%   a_firstLocLon   : longitude of the first location
%   a_firstLocLat   : latitude of the first location
%   a_secondLocDate : date of the second location
%   a_secondLocLon  : longitude of the second location
%   a_secondLocLat  : latitude of the second location
%   a_extrapDate    : date of the extrapolation
%
% OUTPUT PARAMETERS :
%   o_extrapLocLon : extrapolation longitude
%   o_extrapLocLat : extrapolation latitude
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/21/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_extrapLocLon, o_extrapLocLat] = extrapolate_locations(...
   a_firstLocDate, a_firstLocLon, a_firstLocLat, ...
   a_secondLocDate, a_secondLocLon, a_secondLocLat, ...
   a_extrapDate)

% output parameters initialization
o_extrapLocLon = [];
o_extrapLocLat = [];


% interpolate between the locations
if (((abs(a_firstLocLon) > 90) && (abs(a_secondLocLon) > 90)) && ...
      (((a_firstLocLon > 0) && (a_secondLocLon < 0)) || ((a_secondLocLon > 0) && (a_firstLocLon < 0))))
   % the float crossed the date line
   if (a_secondLocLon < 0)
      a_secondLocLon = a_secondLocLon + 360;
   else
      a_firstLocLon = a_firstLocLon + 360;
   end
   o_extrapLocLon = interp1([a_firstLocDate; a_secondLocDate], [a_firstLocLon; a_secondLocLon], a_extrapDate, 'linear', 'extrap');
   if (o_extrapLocLon >= 180)
      o_extrapLocLon = o_extrapLocLon - 360;
   end
else
   o_extrapLocLon = interp1([a_firstLocDate; a_secondLocDate], [a_firstLocLon; a_secondLocLon], a_extrapDate, 'linear', 'extrap');
end
o_extrapLocLat = interp1([a_firstLocDate; a_secondLocDate], [a_firstLocLat; a_secondLocLat], a_extrapDate, 'linear', 'extrap');

return
