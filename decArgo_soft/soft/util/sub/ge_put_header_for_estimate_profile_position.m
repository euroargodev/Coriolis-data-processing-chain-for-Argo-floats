% ------------------------------------------------------------------------------
% Put KML file header.
%
% SYNTAX :
%  ge_put_header_for_estimate_profile_position(a_fId, a_fileDescription, a_fileName)
%
% INPUT PARAMETERS :
%   a_fId             : KML file Id
%   a_fileDescription : input for KML 'description' attribute
%   a_fileName        : input for KML 'name' attribute
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/27/2022 - RNU - creation
% ------------------------------------------------------------------------------
function ge_put_header_for_estimate_profile_position(a_fId, a_fileDescription, a_fileName)

% white for launch location
launchPosColor = ge_rgb_2_hex(1, 1, 1);

% green for good profile locations
profilePos012Color = ge_rgb_2_hex(0, 1, 0);
% orange for bad profile locations
profilePos34Color = ge_rgb_2_hex(1, 0.8745, 0);
% green for located profile trajectory
profileTrajColor = ge_rgb_2_hex(0, 1, 0);

% red for linearly interpolated profile locations
linEstPosColor = ge_rgb_2_hex(1, 0, 0);
% red for linearly interpolated profile trajectory
linEstTrajColor = ge_rgb_2_hex(1, 0, 0);

% yellow for forward estimated profile locations
forwEstPosColor = ge_rgb_2_hex(1, 1, 0);
% yellow for forward estimated profile trajectory
forwEstTrajColor = ge_rgb_2_hex(1, 1, 0);

% cyan for backward estimated profile locations
backwEstPosColor = ge_rgb_2_hex(0, 1, 1);
% cyan for backward estimated profile trajectory
backwEstTrajColor = ge_rgb_2_hex(0, 1, 1);

% white for merged estimated profile locations
mergedEstPosColor = ge_rgb_2_hex(1, 1, 1);
% white for merged estimated profile trajectory
mergedEstTrajColor = ge_rgb_2_hex(1, 1, 1);

% magenta for isobath
isobathColor = ge_rgb_2_hex(1, 0, 1);

header = [ ...
   '<?xml version="1.0" encoding="UTF-8"?>', 10, ...
   '<kml xmlns="http://earth.google.com/kml/2.1">', 10, ...
   '<Document>', 10, ...
   9, '<description><![CDATA[', a_fileDescription, ']]></description>', 10, ...
   9, '<open>1</open>', 10, ...
   9, '<name>', a_fileName, '</name>', 10, ...
   9, '<Style id="LAUNCH_POS">', 10, ...
   9, 9, '<IconStyle>', 10, ...
   9, 9, 9, '<color>', ['FF' launchPosColor], '</color>', 10, ...
   9, 9, 9, '<Icon>', 10, ...
   9, 9, 9, 9, '<href>http://maps.google.com/mapfiles/kml/pal5/icon7.png</href>', 10, ...
   9, 9, 9, '</Icon>', 10, ...
   9, 9, '</IconStyle>', 10, ...
   9, 9, '<LabelStyle>', 10, ...
   9, 9, 9, '<scale>0.6</scale>', 10, ...
   9, 9, '</LabelStyle>', 10, ...
   9, '</Style>', 10, ...
   9, '<Style id="PROFILE_POS_0_1_2">', 10, ...
   9, 9, '<IconStyle>', 10, ...
   9, 9, 9, '<color>', ['FF' profilePos012Color], '</color>', 10, ...
   9, 9, 9, '<Icon>', 10, ...
   9, 9, 9, 9, '<href>http://maps.google.com/mapfiles/kml/shapes/shaded_dot.png</href>', 10, ...
   9, 9, 9, '</Icon>', 10, ...
   9, 9, '</IconStyle>', 10, ...
   9, 9, '<LabelStyle>', 10, ...
   9, 9, 9, '<scale>0.6</scale>', 10, ...
   9, 9, '</LabelStyle>', 10, ...
   9, '</Style>', 10, ...
   9, '<Style id="PROFILE_POS_3_4">', 10, ...
   9, 9, '<IconStyle>', 10, ...
   9, 9, 9, '<color>', ['FF' profilePos34Color], '</color>', 10, ...
   9, 9, 9, '<Icon>', 10, ...
   9, 9, 9, 9, '<href>http://maps.google.com/mapfiles/kml/shapes/shaded_dot.png</href>', 10, ...
   9, 9, 9, '</Icon>', 10, ...
   9, 9, '</IconStyle>', 10, ...
   9, 9, '<LabelStyle>', 10, ...
   9, 9, 9, '<scale>0.6</scale>', 10, ...
   9, 9, '</LabelStyle>', 10, ...
   9, '</Style>', 10, ...
   9, '<Style id="PROFILE_TRAJ">', 10, ...
   9, 9, '<LineStyle>', 10, ...
   9, 9, 9, '<color>', ['ff' profileTrajColor], '</color>', 10, ...
   9, 9, 9, '<width>2</width>', 10, ...
   9, 9, '</LineStyle>', 10, ...
   9, '</Style>', 10, ...
   9, '<Style id="LIN_EST_PROFILE_POS">', 10, ...
   9, 9, '<IconStyle>', 10, ...
   9, 9, 9, '<color>', ['FF' linEstPosColor], '</color>', 10, ...
   9, 9, 9, '<Icon>', 10, ...
   9, 9, 9, 9, '<href>http://maps.google.com/mapfiles/kml/shapes/shaded_dot.png</href>', 10, ...
   9, 9, 9, '</Icon>', 10, ...
   9, 9, '</IconStyle>', 10, ...
   9, 9, '<LabelStyle>', 10, ...
   9, 9, 9, '<scale>0.6</scale>', 10, ...
   9, 9, '</LabelStyle>', 10, ...
   9, '</Style>', 10, ...
   9, '<Style id="LIN_EST_PROFILE_TRAJ">', 10, ...
   9, 9, '<LineStyle>', 10, ...
   9, 9, 9, '<color>', ['ff' linEstTrajColor], '</color>', 10, ...
   9, 9, 9, '<width>2</width>', 10, ...
   9, 9, '</LineStyle>', 10, ...
   9, '</Style>', 10, ...
   9, '<Style id="FORW_EST_PROFILE_POS">', 10, ...
   9, 9, '<IconStyle>', 10, ...
   9, 9, 9, '<color>', ['FF' forwEstPosColor], '</color>', 10, ...
   9, 9, 9, '<Icon>', 10, ...
   9, 9, 9, 9, '<href>http://maps.google.com/mapfiles/kml/shapes/shaded_dot.png</href>', 10, ...
   9, 9, 9, '</Icon>', 10, ...
   9, 9, '</IconStyle>', 10, ...
   9, 9, '<LabelStyle>', 10, ...
   9, 9, 9, '<scale>0.6</scale>', 10, ...
   9, 9, '</LabelStyle>', 10, ...
   9, '</Style>', 10, ...
   9, '<Style id="FORW_EST_PROFILE_TRAJ">', 10, ...
   9, 9, '<LineStyle>', 10, ...
   9, 9, 9, '<color>', ['ff' forwEstTrajColor], '</color>', 10, ...
   9, 9, 9, '<width>2</width>', 10, ...
   9, 9, '</LineStyle>', 10, ...
   9, '</Style>', 10, ...
   9, '<Style id="BACKW_EST_PROFILE_POS">', 10, ...
   9, 9, '<IconStyle>', 10, ...
   9, 9, 9, '<color>', ['FF' backwEstPosColor], '</color>', 10, ...
   9, 9, 9, '<Icon>', 10, ...
   9, 9, 9, 9, '<href>http://maps.google.com/mapfiles/kml/shapes/shaded_dot.png</href>', 10, ...
   9, 9, 9, '</Icon>', 10, ...
   9, 9, '</IconStyle>', 10, ...
   9, 9, '<LabelStyle>', 10, ...
   9, 9, 9, '<scale>0.6</scale>', 10, ...
   9, 9, '</LabelStyle>', 10, ...
   9, '</Style>', 10, ...
   9, '<Style id="BACKW_EST_PROFILE_TRAJ">', 10, ...
   9, 9, '<LineStyle>', 10, ...
   9, 9, 9, '<color>', ['ff' backwEstTrajColor], '</color>', 10, ...
   9, 9, 9, '<width>2</width>', 10, ...
   9, 9, '</LineStyle>', 10, ...
   9, '</Style>', 10, ...
   9, '<Style id="MERGED_EST_PROFILE_POS">', 10, ...
   9, 9, '<IconStyle>', 10, ...
   9, 9, 9, '<color>', ['FF' mergedEstPosColor], '</color>', 10, ...
   9, 9, 9, '<Icon>', 10, ...
   9, 9, 9, 9, '<href>http://maps.google.com/mapfiles/kml/shapes/shaded_dot.png</href>', 10, ...
   9, 9, 9, '</Icon>', 10, ...
   9, 9, '</IconStyle>', 10, ...
   9, 9, '<LabelStyle>', 10, ...
   9, 9, 9, '<scale>0.6</scale>', 10, ...
   9, 9, '</LabelStyle>', 10, ...
   9, '</Style>', 10, ...
   9, '<Style id="MERGED_EST_PROFILE_TRAJ">', 10, ...
   9, 9, '<LineStyle>', 10, ...
   9, 9, 9, '<color>', ['ff' mergedEstTrajColor], '</color>', 10, ...
   9, 9, 9, '<width>2</width>', 10, ...
   9, 9, '</LineStyle>', 10, ...
   9, '</Style>', 10, ...
   9, '<Style id="ISOBATH">', 10, ...
   9, 9, '<LineStyle>', 10, ...
   9, 9, 9, '<color>', ['ff' isobathColor], '</color>', 10, ...
   9, 9, 9, '<width>1</width>', 10, ...
   9, 9, '</LineStyle>', 10, ...
   9, '</Style>', 10 ...
   ];

fprintf(a_fId, '%s', header);

return
