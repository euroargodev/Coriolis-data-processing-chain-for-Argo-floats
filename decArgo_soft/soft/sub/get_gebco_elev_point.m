% ------------------------------------------------------------------------------
% Retrieve the surounding elevations of a list of locations from the GEBCO 2019
% file.
%
% SYNTAX :
%  [o_elev] = get_gebco_elev_point(a_lon, a_lat, a_gebcoFileName)
%
% INPUT PARAMETERS :
%   a_lon           : list of location longitudes
%   a_lat           : list of location atitudes
%   a_gebcoFileName : GEBCO 2019 file path name
%
% OUTPUT PARAMETERS :
%   o_elev : surrounding elevations of each location
%            (size(o_elev) = [length(a_lon) 4]
%             4 elevations are generally provided [elevSW elevNW elevSE elevNE]
%             when only 1 or 2 are provided other ones are set to NaN)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/29/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_elev] = get_gebco_elev_point(a_lon, a_lat, a_gebcoFileName)

% output parameters initialization
o_elev = nan(length(a_lon), 4);


% check inputs
if (a_lon < -180)
   fprintf('ERROR: get_gebco_elev_point: input lon < -180\n');
   return
end
if (a_lon >= 360)
   fprintf('ERROR: get_gebco_elev_point: input lat >= 360\n');
   return
end
if (a_lat < -90)
   fprintf('ERROR: get_gebco_elev_point: input lat < -90\n');
   return
elseif (a_lat > 90)
   fprintf('ERROR: get_gebco_elev_point: input lat > 90\n');
   return
end

if (a_lon >= 180)
   a_lon = a_lon - 360;
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

for idP = 1:length(a_lat)

   if (isnan(a_lat(idP)) || isnan(a_lon(idP)))
      continue
   end

   idLigStart = find(lat <= a_lat(idP), 1, 'last');
   if (isempty(idLigStart))
      idLigStart = 1;
   end
   idLigEnd = find(lat >= a_lat(idP), 1, 'first');
   if (isempty(idLigEnd))
      idLigEnd = length(lat);
   end
   %    latVal = lat(fliplr(idLigStart:idLigEnd));
   
   % a_lon(idP) is in the [-180, 180[ interval
   % it can be in 3 zones:
   % case 1: [-180, minLon[
   % case 2: [minLon, maxLon]
   % case 3: ]maxLon, -180[
   if ((a_lon(idP) >= minLon) && (a_lon(idP) <= maxLon))
      % case 2
      idColStart = find(lon <= a_lon(idP), 1, 'last');
      idColEnd = find(lon >= a_lon(idP), 1, 'first');
      
      elev = nan(length(idLigStart:idLigEnd), length(idColStart:idColEnd));
      for idL = idLigStart:idLigEnd
         elev(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 idColStart-1]), fliplr([1 length(idColStart:idColEnd)]))';
      end
      
      %       lonVal = lon(idColStart:idColEnd);
   elseif (a_lon(idP) < minLon)
      % case 1
      elev1 = nan(length(idLigStart:idLigEnd), 1);
      for idL = idLigStart:idLigEnd
         elev1(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 length(lon)-1]), fliplr([1 1]))';
      end
      
      %       lonVal1 = lon(end);
      
      elev2 = nan(length(idLigStart:idLigEnd), 1);
      for idL = idLigStart:idLigEnd
         elev2(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 0]), fliplr([1 1]))';
      end
      
      %       lonVal2 = lon(1) + 360;
      
      elev = cat(2, elev1, elev2);
      %       lonVal = cat(1, lonVal1, lonVal2);
      clear elev1 elev2
   elseif (a_lon(idP) > maxLon)
      % case 3
      elev1 = nan(length(idLigStart:idLigEnd), 1);
      for idL = idLigStart:idLigEnd
         elev1(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 length(lon)-1]), fliplr([1 1]))';
      end
      
      %       lonVal1 = lon(end);
      
      elev2 = nan(length(idLigStart:idLigEnd), 1);
      for idL = idLigStart:idLigEnd
         elev2(end-(idL-idLigStart), :) = netcdf.getVar(fCdf, elevVarId, fliplr([idL-1 0]), fliplr([1 1]))';
      end
      
      %       lonVal2 = lon(1) + 360;
      
      elev = cat(2, elev1, elev2);
      %       lonVal = cat(1, lonVal1, lonVal2);
      clear elev1 elev2
   end

   if (~isempty(elev))
      if (size(elev, 1) == 2)
         if (size(elev, 2) == 2)
            o_elev(idP, 1) = elev(2, 1);
            o_elev(idP, 2) = elev(1, 1);
            o_elev(idP, 3) = elev(2, 2);
            o_elev(idP, 4) = elev(1, 2);
         else
            o_elev(idP, 1) = elev(2);
            o_elev(idP, 2) = elev(1);
         end
      else
         if (size(elev, 2) == 2)
            o_elev(idP, 1) = elev(1, 1);
            o_elev(idP, 3) = elev(1, 2);
         else
            o_elev(idP, 1) = elev;
         end
      end
   end
   
   clear elev
end

netcdf.close(fCdf);

clear lon lat

return
