% ------------------------------------------------------------------------------
% Retrieve the elevation at a given location from the ETOPO2 file.
%
% SYNTAX :
%  [o_lon, o_lat, o_elev] = get_etopo2_elev(a_lon, a_lat, a_etopo2PathFileName)
%
% INPUT PARAMETERS :
%   a_lon                : location longitude
%   a_lat                : location latitude
%   a_etopo2PathFileName : ETOPO2 file path name
%
% OUTPUT PARAMETERS :
%   o_lon  : longitudes of locations of the grid
%   o_lat  : latitudes of locations of the grid
%   o_elev : elevations of locations of the grid
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_lon, o_lat, o_elev] = get_etopo2_elev(a_lon, a_lat, a_etopo2PathFileName)

% output parameters initialization
o_lon = [];
o_lat = [];
o_elev = [];

% check ETOPO2 file exists
if ~(exist(a_etopo2PathFileName, 'file') == 2)
   fprintf('ERROR: ETOPO2 file not found (%s)\n', a_etopo2PathFileName);
   return;
end

% expecting ETOPO2v2g_i2_MSB.bin file
fId = fopen(a_etopo2PathFileName, 'r', 'b'); % in big-endian format

if (fId == -1)
   fprintf('ERROR: Error while opening ETOPO2 file (%s)\n', a_etopo2PathFileName);
   return;
end

bLat = floor(min(a_lat)*30);
tLat = ceil(max(a_lat)*30);
lLong = floor(min(a_lon)*30);
rLong = ceil(max(a_lon)*30);

lgs = [lLong:rLong]/30;
lts = fliplr([bLat:tLat]/30);

if rLong > (180*30), rLong = rLong - 360*30; lLong = lLong - 360*30; end
if lLong < -(180*30), rLong = rLong + 360*30; lLong = lLong + 360*30; end

eAxes = [lLong+180*30 rLong+180*30 90*30-bLat 90*30-tLat];

if (eAxes(2) > 360*30)   % Read it in in 2 pieces!

   nLat = round((eAxes(3)-eAxes(4))) + 1;
   nLgr = round(eAxes(2)-360*30 ) + 1;
   nLgl = 360*30 - eAxes(1);
   nLng = nLgr + nLgl;

   values = zeros(nLat, nLng);
   for ii = [1:nLat],
      fseek(fId, (ii-1+eAxes(4))*((360*30+1)*2), 'bof');
      values(ii, nLng+[-nLgr:-1]+1) = fread(fId, [1 nLgr], 'int16');
      fseek(fId, (ii-1+eAxes(4))*((360*30+1)*2)+eAxes(1)*2, 'bof');
      values(ii, 1:nLgl) = fread(fId, [1 nLgl], 'int16');
   end

else  % Read it in one piece

   nLat = round((eAxes(3)-eAxes(4))) + 1;
   nLng = round((eAxes(2)-eAxes(1))) + 1;

   values = zeros(nLat, nLng);
   for ii = [1:nLat]
      fseek(fId, (ii-1+eAxes(4))*((360*30+1)*2)+eAxes(1)*2, 'bof');
      values(ii, :) = fread(fId, [1 nLng], 'int16');
   end

end

fclose(fId);

[longs, lats] = meshgrid(lgs, lts);

o_lon = longs;
o_lat = lats;
o_elev = values;

end
