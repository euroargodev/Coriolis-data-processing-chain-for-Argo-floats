% ------------------------------------------------------------------------------
% Format position from lon/lat numerical values to degrees and decimal minutes.
%
% SYNTAX :
%  [o_longitudeStr, o_latitudeStr] = format_position(a_longitude, a_latitude)
%
% INPUT PARAMETERS :
%   a_longitude : input longitude decimal value
%   a_latitude  : input latitude decimal value
%
% OUTPUT PARAMETERS :
%   o_longitudeStr : output formated longitude
%   o_latitudeStr  : output formated latitude
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/03/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_longitudeStr, o_latitudeStr] = format_position(a_longitude, a_latitude)

% output parameters initialization
o_longitudeStr = [];
o_latitudeStr = [];

% global default values
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;


if ((a_longitude ~= g_decArgo_argosLonDef) && (a_latitude ~= g_decArgo_argosLatDef))
   
   if (a_longitude < 0)
      lonStr = 'W';
   else
      lonStr = 'E';
   end
   a_longitude = abs(a_longitude);
   lonDeg = fix(a_longitude);
   lonMin = (a_longitude - lonDeg)*60;
   o_longitudeStr = sprintf('%d deg %.3f %s', lonDeg, lonMin, lonStr);
   
   if (a_latitude < 0)
      latStr = 'S';
   else
      latStr = 'N';
   end
   a_latitude = abs(a_latitude);
   latDeg = fix(a_latitude);
   latMin = (a_latitude - latDeg)*60;
   o_latitudeStr = sprintf('%d deg %.3f %s', latDeg, latMin, latStr);
end

return
