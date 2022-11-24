% ------------------------------------------------------------------------------
% Retrieve the elevations of a given zone from the GEBCO 2019 file.
%
% SYNTAX :
%  [o_elev, o_lon, o_lat] = get_gebco_elev_zone( ...
%    a_lonMin, a_lonMax, a_latMin, a_latMax, a_gebcoFileName)
%
% INPUT PARAMETERS :
%   a_lonMin        : min longitude of the zone
%   a_lonMax        : max longitude of the zone
%   a_latMin        : min latitude of the zone
%   a_latMax        : max latitude of the zone
%   a_gebcoFileName : GEBCO 2019 file path name
%
% OUTPUT PARAMETERS :
%   o_elev : elevations of locations of the grid
%   o_lon  : longitudes of locations of the grid
%   o_lat  : latitudes of locations of the grid
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_elev, o_lon, o_lat] = get_gebco_elev_zone( ...
   a_lonMin, a_lonMax, a_latMin, a_latMax, a_gebcoFileName)

% output parameters initialization
o_elev = [];
o_lon = [];
o_lat = [];

if (isempty(a_gebcoFileName))
   a_gebcoFileName = 'C:\Users\jprannou\_RNU\_ressources\GEBCO_2021\GEBCO_2021.nc';
end


% check inputs
if (a_latMin > a_latMax)
   fprintf('ERROR: get_gebco_elev_zone: latMin > latMax\n');
   return
else
   if (a_latMin < -90)
      fprintf('ERROR: get_gebco_elev_zone: latMin < -90\n');
      return
   elseif (a_latMax > 90)
      fprintf('ERROR: get_gebco_elev_zone: a_latMax > 90\n');
      return
   end
end
if (a_lonMin >= 180)
   a_lonMin = a_lonMin - 360;
   a_lonMax = a_lonMax - 360;
end
if (a_lonMax < a_lonMin)
   a_lonMax = a_lonMax + 360;
end

% check GEBCO file exists
if ~(exist(a_gebcoFileName, 'file') == 2)
   fprintf('ERROR: GEBCO file not found (%s)\n', a_gebcoFileName);
   return
end

% open NetCDF file
fCdf = netcdf.open(a_gebcoFileName, 'NC_NOWRITE');
if (isempty(fCdf))
   fprintf('RTQC_ERROR: Unable to open NetCDF input file: %s\n', a_gebcoFileName);
   return
end

lonVarId = netcdf.inqVarID(fCdf, 'lon');
latVarId = netcdf.inqVarID(fCdf, 'lat');
elevVarId = netcdf.inqVarID(fCdf, 'elevation');

lon = netcdf.getVar(fCdf, lonVarId);
lat = netcdf.getVar(fCdf, latVarId);
minLon = min(lon);
maxLon = max(lon);

idLigStart = find(lat <= a_latMin, 1, 'last');
idLigEnd = find(lat >= a_latMax, 1, 'first');
latVal = lat(fliplr(idLigStart:idLigEnd));

% a_lonMin is in the [-180, 180[ interval
% a_lonMax can be in the [-180, 180[ interval (case A) or [0, 360[ interval (case B)

% if ((a_lonMax - a_lonMin) > (maxLon - minLon)) we return the whole set of longitudes
% otherwise
% in case A: we should manage 3 zones
% [-180, minLon[, [minLon, maxLon] and ]maxLon, -180[, thus 5 cases
% case A1: a_lonMin and a_lonMax in [-180, minLon[
% case A2: a_lonMin in [-180, minLon[ and a_lonMax in [minLon, maxLon]
% case A3: a_lonMin in [minLon, maxLon] and a_lonMax in [minLon, maxLon]
% case A4: a_lonMin in [minLon, maxLon] and a_lonMax in ]maxLon, -180[
% case A5: a_lonMin in ]maxLon, -180[ and a_lonMax in ]maxLon, -180[
% in case B: we should manage 3 zones
% [minLon, maxLon], ]maxLon, -180[, [180, minLon+360[ and [minLon+360, maxLon+360], thus 4 cases
% case B1: a_lonMin in [minLon, maxLon] and a_lonMax in [180, minLon+360[
% case B2: a_lonMin in [minLon, maxLon] and a_lonMax in [minLon+360, maxLon+360]
% case B3: a_lonMin in ]maxLon, -180[ and a_lonMax in [180, minLon+360[
% case B4: a_lonMin in ]maxLon, -180[ and a_lonMax in [minLon+360, maxLon+360]

if ((a_lonMax - a_lonMin) <= (maxLon - minLon))
   if (a_lonMax < 180) % case A
      if ((a_lonMin >= minLon) && (a_lonMin <= maxLon) && ...
            (a_lonMax >= minLon) && (a_lonMax <= maxLon))
         % case A3
         idColStart = find(lon <= a_lonMin, 1, 'last');
         idColEnd = find(lon >= a_lonMax, 1, 'first');
         
         elev = nan(length(idLigStart:idLigEnd), length(idColStart:idColEnd));
         for idL = idLigStart:idLigEnd
            elev(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 idColStart-1]), fliplr([1 length(idColStart:idColEnd)]))';
         end
         
         lonVal = lon(idColStart:idColEnd);
      elseif ((a_lonMin < minLon) && ...
            (a_lonMax >= minLon) && (a_lonMax <= maxLon))
         % case A2
         elev1 = nan(length(idLigStart:idLigEnd), 1);
         for idL = idLigStart:idLigEnd
            elev1(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 length(lon)-1]), fliplr([1 1]))';
         end
         
         lonVal1 = lon(end);
         
         idColStart = 1;
         idColEnd = find(lon >= a_lonMax, 1, 'first');
         
         elev2 = nan(length(idLigStart:idLigEnd), length(idColStart:idColEnd));
         for idL = idLigStart:idLigEnd
            elev2(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 idColStart-1]), fliplr([1 length(idColStart:idColEnd)]))';
         end
         
         lonVal2 = lon(idColStart:idColEnd) + 360;
         
         elev = cat(2, elev1, elev2);
         lonVal = cat(1, lonVal1, lonVal2);
         clear elev1 elev2 lonVal1 lonVal2
      elseif ((a_lonMin >= minLon) && (a_lonMin <= maxLon) && ...
            (a_lonMax > maxLon))
         % case A4
         idColStart = find(lon <= a_lonMin, 1, 'last');
         idColEnd = length(lon);
         
         elev1 = nan(length(idLigStart:idLigEnd), length(idColStart:idColEnd));
         for idL = idLigStart:idLigEnd
            elev1(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 idColStart-1]), fliplr([1 length(idColStart:idColEnd)]))';
         end
         
         lonVal1 = lon(idColStart:idColEnd);
         
         elev2 = nan(length(idLigStart:idLigEnd), 1);
         for idL = idLigStart:idLigEnd
            elev2(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 0]), fliplr([1 1]))';
         end
         
         lonVal2 = lon(1) + 360;
         
         elev = cat(2, elev1, elev2);
         lonVal = cat(1, lonVal1, lonVal2);
         clear elev1 elev2 lonVal1 lonVal2
      elseif ((a_lonMin < minLon) && ...
            (a_lonMax < minLon))
         % case A1
         elev1 = nan(length(idLigStart:idLigEnd), 1);
         for idL = idLigStart:idLigEnd
            elev1(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 length(lon)-1]), fliplr([1 1]))';
         end
         
         lonVal1 = lon(end);
         
         elev2 = nan(length(idLigStart:idLigEnd), 1);
         for idL = idLigStart:idLigEnd
            elev2(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 0]), fliplr([1 1]))';
         end
         
         lonVal2 = lon(1) + 360;
         
         elev = cat(2, elev1, elev2);
         lonVal = cat(1, lonVal1, lonVal2);
         clear elev1 elev2 lonVal1 lonVal2
      elseif ((a_lonMin > maxLon) && ...
            (a_lonMax > maxLon))
         % case A5
         elev1 = nan(length(idLigStart:idLigEnd), 1);
         for idL = idLigStart:idLigEnd
            elev1(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 length(lon)-1]), fliplr([1 1]))';
         end
         
         lonVal1 = lon(end);
         
         elev2 = nan(length(idLigStart:idLigEnd), 1);
         for idL = idLigStart:idLigEnd
            elev2(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 0]), fliplr([1 1]))';
         end
         
         lonVal2 = lon(1) + 360;
         
         elev = cat(2, elev1, elev2);
         lonVal = cat(1, lonVal1, lonVal2);
         clear elev1 elev2 lonVal1 lonVal2         
      end
   else % case B
      if (a_lonMin <= maxLon) && (a_lonMax >= minLon + 360)
         % case B2
         idColStart = find(lon <= a_lonMin, 1, 'last');
         idColEnd = length(lon);
         
         elev1 = nan(length(idLigStart:idLigEnd), length(idColStart:idColEnd));
         for idL = idLigStart:idLigEnd
            elev1(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 idColStart-1]), fliplr([1 length(idColStart:idColEnd)]))';
         end
         
         lonVal1 = lon(idColStart:idColEnd);
         
         idColStart = 1;
         idColEnd = find(lon >= a_lonMax - 360, 1, 'first');
         
         elev2 = nan(length(idLigStart:idLigEnd), length(idColStart:idColEnd));
         for idL = idLigStart:idLigEnd
            elev2(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 idColStart-1]), fliplr([1 length(idColStart:idColEnd)]))';
         end
         
         lonVal2 = lon(idColStart:idColEnd) + 360;
         
         elev = cat(2, elev1, elev2);
         lonVal = cat(1, lonVal1, lonVal2);
         clear elev1 elev2 lonVal1 lonVal2
      elseif (a_lonMin <= maxLon) && (a_lonMax < minLon + 360)
         % case B1
         idColStart = find(lon <= a_lonMin, 1, 'last');
         idColEnd = length(lon);
         
         elev1 = nan(length(idLigStart:idLigEnd), length(idColStart:idColEnd));
         for idL = idLigStart:idLigEnd
            elev1(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 idColStart-1]), fliplr([1 length(idColStart:idColEnd)]))';
         end
         
         lonVal1 = lon(idColStart:idColEnd);
                  
         elev2 = nan(length(idLigStart:idLigEnd), 1);
         for idL = idLigStart:idLigEnd
            elev2(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 0]), fliplr([1 1]))';
         end
         
         lonVal2 = lon(1) + 360;
         
         elev = cat(2, elev1, elev2);
         lonVal = cat(1, lonVal1, lonVal2);
         clear elev1 elev2 lonVal1 lonVal2
      elseif (a_lonMin > maxLon) && (a_lonMax >= minLon + 360)
         % case B4
         elev1 = nan(length(idLigStart:idLigEnd), 1);
         for idL = idLigStart:idLigEnd
            elev1(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 length(lon)-1]), fliplr([1 1]))';
         end
         
         lonVal1 = lon(end);
         
         idColStart = 1;
         idColEnd = find(lon >= a_lonMax - 360, 1, 'first');
         
         elev2 = nan(length(idLigStart:idLigEnd), length(idColStart:idColEnd));
         for idL = idLigStart:idLigEnd
            elev2(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 idColStart-1]), fliplr([1 length(idColStart:idColEnd)]))';
         end
         
         lonVal2 = lon(idColStart:idColEnd) + 360;
         
         elev = cat(2, elev1, elev2);
         lonVal = cat(1, lonVal1, lonVal2);
         clear elev1 elev2 lonVal1 lonVal2
      elseif (a_lonMin > maxLon) && (a_lonMax < minLon + 360)
         % case B3
         elev1 = nan(length(idLigStart:idLigEnd), 1);
         for idL = idLigStart:idLigEnd
            elev1(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 length(lon)-1]), fliplr([1 1]))';
         end
         
         lonVal1 = lon(end);
         
         elev2 = nan(length(idLigStart:idLigEnd), 1);
         for idL = idLigStart:idLigEnd
            elev2(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 0]), fliplr([1 1]))';
         end
         
         lonVal2 = lon(1) + 360;
         
         elev = cat(2, elev1, elev2);
         lonVal = cat(1, lonVal1, lonVal2);
         clear elev1 elev2 lonVal1 lonVal2
      end
      
   end
else % return the whole set of longitudes
   idColStart = 1;
   idColEnd = length(lon);
   
   elev = nan(length(idLigStart:idLigEnd), length(idColStart:idColEnd));
   for idL = idLigStart:idLigEnd
      elev(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 idColStart-1]), fliplr([1 length(idColStart:idColEnd)]))';
   end
   
   lonVal = lon(idColStart:idColEnd);
end

netcdf.close(fCdf);

[longitudes, latitudes] = meshgrid(lonVal, latVal);

o_elev = elev;
o_lon = longitudes;
o_lat = latitudes;

clear lon lat elev longitudes latitudes

return
