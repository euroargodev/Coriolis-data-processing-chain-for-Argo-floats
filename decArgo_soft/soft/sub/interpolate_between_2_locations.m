% ------------------------------------------------------------------------------
% Interpolate between 2 dated locations.
%
% SYNTAX :
%  [o_interpLocLon, o_interpLocLat] = interpolate_between_2_locations(...
%    a_firstLocDate, a_firstLocLon, a_firstLocLat, ...
%    a_secondLocDate, a_secondLocLon, a_secondLocLat, ...
%    a_interpDate)
%
% INPUT PARAMETERS :
%   a_firstLocDate  : date of the first location
%   a_firstLocLon   : longitude of the first location
%   a_firstLocLat   : latitude of the first location
%   a_secondLocDate : date of the second location
%   a_secondLocLon  : longitude of the second location
%   a_secondLocLat  : latitude of the second location
%   a_interpDate    : date of the interpolation
%
% OUTPUT PARAMETERS :
%   o_interpLocLon : interpolated longitude
%   o_interpLocLat : interpolated latitude
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/18/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_interpLocLon, o_interpLocLat] = interpolate_between_2_locations(...
   a_firstLocDate, a_firstLocLon, a_firstLocLat, ...
   a_secondLocDate, a_secondLocLon, a_secondLocLat, ...
   a_interpDate)

% output parameters initialization
o_interpLocLon = [];
o_interpLocLat = [];


% interpolate between the locations
if (((abs(a_firstLocLon) > 90) && (abs(a_secondLocLon) > 90)) && ...
      (((a_firstLocLon > 0) && (a_secondLocLon < 0)) || ((a_secondLocLon > 0) && (a_firstLocLon < 0))))
   % the float crossed the date line
   if (a_secondLocLon < 0)
      a_secondLocLon = a_secondLocLon + 360;
   else
      a_firstLocLon = a_firstLocLon + 360;
   end
   o_interpLocLon = interp1q([a_firstLocDate; a_secondLocDate], [a_firstLocLon; a_secondLocLon], a_interpDate);
   if (o_interpLocLon >= 180)
      o_interpLocLon = o_interpLocLon - 360;
   end
else
   o_interpLocLon = interp1q([a_firstLocDate; a_secondLocDate], [a_firstLocLon; a_secondLocLon], a_interpDate);
end
o_interpLocLat = interp1q([a_firstLocDate; a_secondLocDate], [a_firstLocLat; a_secondLocLat], a_interpDate);

return;
