% ------------------------------------------------------------------------------
% Compute geographic boundaries to plot a set of locations.
%
% SYNTAX :
%  [o_lonMin, o_lonMax, o_latMin, o_latMax] = ...
%    compute_geo_extrema(a_date, a_lon, a_lat, a_zoom)
%
% INPUT PARAMETERS :
%   a_date : date of the locations
%   a_lon  : longitude of the locations
%   a_lat  : latitude of the locations
%   a_zoom : zoom factor
%
% OUTPUT PARAMETERS :
%   o_lonMin  : min longitude of the plot
%   o_lonMax  : max longitude of the plot
%   o_latMin  : min latitude of the plot
%   o_latMax  : max latitude of the plot
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_lonMin, o_lonMax, o_latMin, o_latMax] = ...
   compute_geo_extrema(a_date, a_lon, a_lat, a_zoom)

o_lonMin = [];
o_lonMax = [];
o_latMin = [];
o_latMax = [];

global g_dateDef;
global g_latDef;
global g_lonDef;

% default values initialization
init_valdef;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute the geographic boundaries of the plot

if (~isempty(a_date))
   idNoData = find((a_date == g_dateDef) | (a_lon == g_lonDef) | (a_lat == g_latDef));
else
   idNoData = find((a_lon == g_lonDef) | (a_lat == g_latDef));
end
a_lon(idNoData) = [];
a_lat(idNoData) = [];

% geographic boundaries of the locations
latMin = min(a_lat);
latMax = max(a_lat);
latMarge = abs((latMax-latMin)/5);
if (latMarge == 0)
   latMarge = 1/60;
end
latMin = latMin - latMarge;
latMax = latMax + latMarge;

lonMin = min(a_lon);
lonMax = max(a_lon);

borneLonMax = 180;
if ((abs(lonMin - lonMax) > 180) && ...
      (abs(lonMin - lonMax) > abs(lonMin + lonMax)))
   id = find(a_lon < 0);
   a_lon(id) = a_lon(id) + 360;
   lonMin = min(a_lon);
   lonMax = max(a_lon);
   borneLonMax = 360;
end

lonMarge = abs((lonMax-lonMin)/5);
if (lonMarge == 0)
   lonMarge = 1/60;
end
lonMin = lonMin - lonMarge;
lonMax = lonMax + lonMarge;

% use of zoom factor
deltaLat = abs((latMax-latMin)/2);
deltaLon = abs((lonMax-lonMin)/2);
latMin = latMin - a_zoom*2*deltaLat;
latMax = latMax + a_zoom*2*deltaLat;
lonMin = lonMin - a_zoom*2*deltaLon;
lonMax = lonMax + a_zoom*2*deltaLon;

if (latMin < -90)
   latMin = -90;
end
if (latMax > 90)
   latMax = 90;
end
if (lonMin < -180)
   lonMin = -180;
end
if (lonMax > borneLonMax)
   lonMax = borneLonMax;
end

o_latMin = latMin;
o_latMax = latMax;
o_lonMin = lonMin;
o_lonMax = lonMax;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% optimization of the drawing window

m_proj('mercator', 'latitudes', [latMin latMax], 'longitudes', [lonMin lonMax]);

[xSW, ySW] = m_ll2xy(lonMin, latMin);
[xNW, yNW] = m_ll2xy(lonMin, latMax);
[xSE, ySE] = m_ll2xy(lonMax, latMin);

% use X/Y = 1.4 (with a legend, otherwise use 1.2)
coef = 1.4;
deltaX = xSE - xSW;
deltaY = yNW - ySW;
if (deltaX/deltaY > coef)
   complement = (deltaX/coef) - deltaY;
   ySW = ySW - complement/2;
   yNW = yNW + complement/2;
else
   complement = deltaY*coef - deltaX;
   xSW = xSW - complement/2;
   xSE = xSE + complement/2;
end

[lonMin, latMin] = m_xy2ll(xSW, ySW);
[bidon, latMax] = m_xy2ll(xNW, yNW);
[lonMax, bidon] = m_xy2ll(xSE, ySE);

if ((latMin >= -90) && (latMax <= 90) && (lonMin >= -180) && (lonMax <= borneLonMax))
   o_latMin = latMin;
   o_latMax = latMax;
   o_lonMin = lonMin;
   o_lonMax = lonMax;
else
   fprintf('compute_geo_extrema: cannot use the optimization of the drawing window\n');
end

return;
