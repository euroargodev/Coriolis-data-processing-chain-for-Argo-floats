% ------------------------------------------------------------------------------
% Generate KML file from estimate_profile_position tool output CSV file to plot
% final (and intermediate) trajectories of estimated profile locations.
%
% SYNTAX :
%   ge_generate_traj_from_csv_estimate_profile_position(6902899)
%
% INPUT PARAMETERS :
%   varargin : CSV file path name
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
function ge_generate_traj_from_csv_estimate_profile_position(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START

% directory of KML output file
DIR_OUTPUT_KML_FILES = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% GEBCO bathymetric file
GEBCO_FILE = 'C:\Users\jprannou\_RNU\_ressources\GEBCO_2022\GEBCO_2022.nc';

% flag to generate local isobath lines
GENERATE_ISOBATH = 1;

% CONFIGURATION - END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% default values initialization
init_default_values;

% check input parameters
if (nargin == 0)
   fprintf('ERROR: Input csv file path name is expected - abort\n');
   return
else
   inputFilePathName = varargin{:};
   if ~(exist(inputFilePathName, 'file') == 2)
      fprintf('ERROR: Input csv file not found: %s - abort\n', inputFilePathName);
      return
   end
end

% read CSV input data
trajData = read_csv_file(inputFilePathName);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% positions provided by the float

floatPos = [];
idF = find((trajData.posQc ~= 8) & (trajData.posQc ~= 9));
floatPos.wmo = trajData.wmo(idF);
floatPos.cyNum = trajData.cyNum(idF);
floatPos.juld = trajData.juld(idF);
floatPos.lat = trajData.lat(idF);
floatPos.lon = trajData.lon(idF);
floatPos.posQc = trajData.posQc(idF);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% float launch location
floatLaunchPosStr = create_launch(floatPos, '#LAUNCH_POS', 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% located profile positions

floatPosTrajStr = create_traj1(floatPos, '#PROFILE_TRAJ', 1);

floatPosLocStr = create_loc1(floatPos, '#PROFILE_POS_0_1_2', '#PROFILE_POS_3_4', 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% linearly interpolated profile positions

pos = ones(size(trajData.wmo));
idF = find((trajData.posQc == 8) | (trajData.posQc == 9));
pos(idF) = 0;
startIdList = find(diff(pos) == -1);
stopIdList = find(diff(pos) == 1) + 1;

linEstPosTrajStr = create_traj2(trajData, startIdList, stopIdList, '#LIN_EST_PROFILE_TRAJ', 1);

linEstPosLocStr = create_loc2(trajData, startIdList, stopIdList, '#LIN_EST_PROFILE_POS', 0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% forward estimated profile positions

floatPos = [];
floatPos.wmo = trajData.wmo;
floatPos.cyNum = trajData.cyNum;
floatPos.juld = trajData.juld;
floatPos.lat = trajData.forwLat;
floatPos.lon = trajData.forwLon;
floatPos.depthConstraint = trajData.depthConstraint;
floatPos.gebcoDepth = trajData.forwGebcoDepth;
floatPos.grd = trajData.grd;

forwEstPosTrajStr = create_traj2(floatPos, startIdList, stopIdList, '#FORW_EST_PROFILE_TRAJ', 0);

forwEstPosLocStr = create_loc2(floatPos, startIdList, stopIdList, '#FORW_EST_PROFILE_POS', 0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% backward estimated profile positions

floatPos = [];
floatPos.wmo = trajData.wmo;
floatPos.cyNum = trajData.cyNum;
floatPos.juld = trajData.juld;
floatPos.lat = trajData.backwLat;
floatPos.lon = trajData.backwLon;
floatPos.depthConstraint = trajData.depthConstraint;
floatPos.gebcoDepth = trajData.backwGebcoDepth;
floatPos.grd = trajData.grd;

backwEstPosTrajStr = create_traj2(floatPos, startIdList, stopIdList, '#BACKW_EST_PROFILE_TRAJ', 0);

backwEstPosLocStr = create_loc2(floatPos, startIdList, stopIdList, '#BACKW_EST_PROFILE_POS', 0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% merged estimated profile positions

floatPos = [];
floatPos.wmo = trajData.wmo;
floatPos.cyNum = trajData.cyNum;
floatPos.juld = trajData.juld;
floatPos.lat = trajData.trajLat;
floatPos.lon = trajData.trajLon;
floatPos.depthConstraint = trajData.depthConstraint;
floatPos.gebcoDepth = trajData.backwGebcoDepth;
nb1 = ceil(length(floatPos.gebcoDepth)/2);
floatPos.gebcoDepth(1:nb1) = trajData.forwGebcoDepth(1:nb1);
floatPos.grd = trajData.grd;

mergedEstPosTrajStr = create_traj2(floatPos, startIdList, stopIdList, '#MERGED_EST_PROFILE_TRAJ', 1);

mergedEstPosLocStr = create_loc2(floatPos, startIdList, stopIdList, '#MERGED_EST_PROFILE_POS', 0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% local isobath around estimated profile positions
if (GENERATE_ISOBATH == 1)

   floatPos = [];
   floatPos.wmo = trajData.wmo;
   floatPos.cyNum = trajData.cyNum;
   floatPos.juld = trajData.juld;
   floatPos.lat = trajData.lat;
   floatPos.lon = trajData.lon;
   floatPos.forwLat = trajData.forwLat;
   floatPos.forwLon = trajData.forwLon;
   floatPos.backwLat = trajData.backwLat;
   floatPos.backwLon = trajData.backwLon;
   floatPos.depthConstraint = trajData.depthConstraint;

   isobathLineStr = create_isobath(floatPos, startIdList, stopIdList, '#ISOBATH', 1, GEBCO_FILE);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create and fill output KML file

ident = datestr(now, 'yyyymmddTHHMMSS');
kmlFileNameBase = ['ge_generate_traj_from_csv_estimate_profile_position_' num2str(trajData.wmo(1)) '_' ident];
kmlFileName = [kmlFileNameBase '.kml'];
kmzFileName = [kmlFileNameBase '.kmz'];
outputFileName = [DIR_OUTPUT_KML_FILES kmlFileName];

fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create output file: %s\n', outputFileName);
   return
end

% put output file header
description = 'Comparison of profile positions estimated by estimate_profile_locations tool';
ge_put_header_for_estimate_profile_position(fidOut, description, kmlFileName);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
kmlStr = [ ...
   9, '<Folder>', 10, ...
   9, 9, '<name>float launch position</name>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);
fprintf(fidOut, '%s', floatLaunchPosStr);
kmlStr = [ ...
   9, '</Folder>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
kmlStr = [ ...
   9, '<Folder>', 10, ...
   9, 9, '<name>trajectory of profile positions provided by the float</name>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);
fprintf(fidOut, '%s', floatPosTrajStr);
kmlStr = [ ...
   9, '</Folder>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
kmlStr = [ ...
   9, '<Folder>', 10, ...
   9, 9, '<name>profile positions provided by the float</name>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);
fprintf(fidOut, '%s', floatPosLocStr);
kmlStr = [ ...
   9, '</Folder>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
kmlStr = [ ...
   9, '<Folder>', 10, ...
   9, 9, '<name>trajectory of linearly interpolated profile positions</name>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);
fprintf(fidOut, '%s', linEstPosTrajStr);
kmlStr = [ ...
   9, '</Folder>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
kmlStr = [ ...
   9, '<Folder>', 10, ...
   9, 9, '<name>linearly estimated profile positions</name>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);
fprintf(fidOut, '%s', linEstPosLocStr);
kmlStr = [ ...
   9, '</Folder>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
kmlStr = [ ...
   9, '<Folder>', 10, ...
   9, 9, '<name>trajectory of forward interpolated profile positions</name>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);
fprintf(fidOut, '%s', forwEstPosTrajStr);
kmlStr = [ ...
   9, '</Folder>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
kmlStr = [ ...
   9, '<Folder>', 10, ...
   9, 9, '<name>forward estimated profile positions</name>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);
fprintf(fidOut, '%s', forwEstPosLocStr);
kmlStr = [ ...
   9, '</Folder>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
kmlStr = [ ...
   9, '<Folder>', 10, ...
   9, 9, '<name>trajectory of backward interpolated profile positions</name>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);
fprintf(fidOut, '%s', backwEstPosTrajStr);
kmlStr = [ ...
   9, '</Folder>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
kmlStr = [ ...
   9, '<Folder>', 10, ...
   9, 9, '<name>backward estimated profile positions</name>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);
fprintf(fidOut, '%s', backwEstPosLocStr);
kmlStr = [ ...
   9, '</Folder>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
kmlStr = [ ...
   9, '<Folder>', 10, ...
   9, 9, '<name>trajectory of merged interpolated profile positions</name>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);
fprintf(fidOut, '%s', mergedEstPosTrajStr);
kmlStr = [ ...
   9, '</Folder>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
kmlStr = [ ...
   9, '<Folder>', 10, ...
   9, 9, '<name>merged estimated profile positions</name>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);
fprintf(fidOut, '%s', mergedEstPosLocStr);
kmlStr = [ ...
   9, '</Folder>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (GENERATE_ISOBATH == 1)

   kmlStr = [ ...
      9, '<Folder>', 10, ...
      9, 9, '<name>local depth constraints</name>', 10, ...
      ];
   fprintf(fidOut, '%s', kmlStr);
   fprintf(fidOut, '%s', isobathLineStr);
   kmlStr = [ ...
      9, '</Folder>', 10, ...
      ];
   fprintf(fidOut, '%s', kmlStr);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% KML file finalization
footer = [ ...
   '</Document>', 10, ...
   '</kml>', 10];

fprintf(fidOut,'%s',footer);
fclose(fidOut);

% KMZ file generation
zip([DIR_OUTPUT_KML_FILES kmzFileName], [DIR_OUTPUT_KML_FILES kmlFileName]);
delete([DIR_OUTPUT_KML_FILES kmlFileName]);
move_file([DIR_OUTPUT_KML_FILES kmzFileName '.zip '], [DIR_OUTPUT_KML_FILES kmzFileName]);

return

% ------------------------------------------------------------------------------
% Read CSV file generated by estimate_profile_position tool.
%
% SYNTAX :
%  [o_trajData] = read_csv_file(a_filePathName)
%
% INPUT PARAMETERS :
%   a_filePathName : CSV file path name
%
% OUTPUT PARAMETERS :
%   o_trajData : CSV file data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/27/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_trajData] = read_csv_file(a_filePathName)

% output parameters initialization
o_trajData = [];

% default values initialization
global g_decArgo_janFirst1950InMatlab;


% read input file
fId = fopen(a_filePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_filePathName);
   return
end
fileContents = textscan(fId, '%s', 'delimiter', ';');
fileContents = fileContents{:};
fclose(fId);

if (rem(size(fileContents, 1), 35) ~= 0)
   fprintf('ERROR: Unable to parse file: %s\n', a_filePathName);
   return
end

trajData = reshape(fileContents, 35, size(fileContents, 1)/35)';
clear fileContents

if (size(trajData, 1) == 1)
   fprintf('WARNING: Empty file: %s\n', a_filePathName);
   clear trajData
   return
end

% fill output structure
for idCol = 1:35
   switch trajData{1, idCol}
      case 'WMO'
         o_trajData.wmo = str2double(trajData(2:end, idCol)');
      case 'CyNum'
         o_trajData.cyNum = str2double(trajData(2:end, idCol)');
      case 'Dir'
         o_trajData.dir = str2double(trajData(2:end, idCol)');
      case 'Juld'
         o_trajData.juld = (datenum([trajData(2:end, idCol)], 'yyyy/mm/dd HH:MM:SS') - g_decArgo_janFirst1950InMatlab)';
      case 'JuldQC'
         o_trajData.juldQc = str2double(trajData(2:end, idCol)');
      case 'JuldLoc'
         o_trajData.juldLoc = (datenum([trajData(2:end, idCol)], 'yyyy/mm/dd HH:MM:SS') - g_decArgo_janFirst1950InMatlab)';
      case 'Lat'
         o_trajData.lat = str2double(trajData(2:end, idCol)');
      case 'Lon'
         o_trajData.lon = str2double(trajData(2:end, idCol)');
      case 'PosQC'
         o_trajData.posQc = str2double(trajData(2:end, idCol)');
      case 'Speed'
         o_trajData.speed = str2double(trajData(2:end, idCol)');
      case 'ProfPresMax'
         o_trajData.profPresMax = str2double(trajData(2:end, idCol)');
      case 'Rpp'
         o_trajData.rpp = str2double(trajData(2:end, idCol)');
      case 'Grd'
         o_trajData.grd = str2double(trajData(2:end, idCol)');
      case 'GrdPres'
         o_trajData.grdPres = str2double(trajData(2:end, idCol)');
      case 'GebcoDepth'
         o_trajData.gebcoDepth = str2double(trajData(2:end, idCol)');
      case 'SetNum'
         o_trajData.setNum = str2double(trajData(2:end, idCol)');
      case 'DepthConstraint'
         o_trajData.depthConstraint = str2double(trajData(2:end, idCol)');
      case 'ForwLat'
         o_trajData.forwLat = str2double(trajData(2:end, idCol)');
      case 'ForwLon'
         o_trajData.forwLon = str2double(trajData(2:end, idCol)');
      case 'ForwGebcoDepth'
         o_trajData.forwGebcoDepth = str2double(trajData(2:end, idCol)');
      case 'ForwDiffDepth'
         o_trajData.forwDiffDepth = str2double(trajData(2:end, idCol)');
      case 'BackwLat'
         o_trajData.backwLat = str2double(trajData(2:end, idCol)');
      case 'BackwLon'
         o_trajData.backwLon = str2double(trajData(2:end, idCol)');
      case 'BackwGebcoDepth'
         o_trajData.backwGebcoDepth = str2double(trajData(2:end, idCol)');
      case 'BackDiffDepth'
         o_trajData.backDiffDepth = str2double(trajData(2:end, idCol)');
      case 'TrajLat'
         o_trajData.trajLat = str2double(trajData(2:end, idCol)');
      case 'TrajLon'
         o_trajData.trajLon = str2double(trajData(2:end, idCol)');
      case 'SpeedEst'
         o_trajData.speedEst = str2double(trajData(2:end, idCol)');
      case {'DIFF_DEPTH_TO_START', 'FLOAT_VS_BATHY_TOLERANCE', ...
            'FLOAT_VS_BATHY_TOLERANCE_FOR_GRD', 'FIRST_RANGE', ...
            'LAST_RANGE', 'RANGE_PERIOD', 'TOOL_VERSION'}
         % not used
      otherwise
         fprintf('ERROR: Unexpected column (''%'') in file: %s\n', trajData{1, idCol}, a_filePathName);
   end
end

return

% ------------------------------------------------------------------------------
% Generate KML code to plot the float launch location.
%
% SYNTAX :
%  [o_kmlStr] = create_launch(a_locData, a_locStyle, a_visibility)
%
% INPUT PARAMETERS :
%   a_locData    : input location information
%   a_locStyle   : style of the KML elements
%   a_visibility : initial visibility flag of the KML elements
%
% OUTPUT PARAMETERS :
%   o_kmlStr : output KML code
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/27/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_kmlStr] = create_launch(a_locData, a_locStyle, a_visibility)

% output parameters initialization
o_kmlStr = '';

% default values initialization
global g_decArgo_janFirst1950InMatlab;


idF = find(a_locData.cyNum == 0);
if (~isempty(idF))

   floatWmo = a_locData.wmo(idF);
   launchJuld = a_locData.juld(idF);
   launchLat = a_locData.lat(idF);
   launchLon = a_locData.lon(idF);
   launcPosQc = a_locData.posQc(idF);

   o_kmlStr = [o_kmlStr, ...
      9, '<Folder>', 10, ...
      9, 9, '<name>', 'Launch location', '</name>', 10, ...
      ];

   launchPosDescription = '';
   launchPosDescription = [launchPosDescription, ...
      sprintf('LAUNCH POSITION (lon, lat): %8.3f, %7.3f\n', launchLon, launchLat)];
   launchPosDescription = [launchPosDescription, ...
      sprintf('LAUNCH DATE               : %s\n', julian_2_gregorian_dec_argo(launchJuld))];
   launchPosDescription = [launchPosDescription, ...
      sprintf('LAUNCH POSITION QC        : %c\n', num2str(launcPosQc))];

   timeSpanStart = datestr(launchJuld+g_decArgo_janFirst1950InMatlab, 'yyyy-mm-ddTHH:MM:SSZ');

   o_kmlStr = [o_kmlStr, ge_create_pos( ...
      launchLon, launchLat, ...
      launchPosDescription, ...
      sprintf('%d', floatWmo), ...
      a_locStyle, a_visibility, ...
      timeSpanStart, '')];

   o_kmlStr = [o_kmlStr, ...
      9, '</Folder>', 10, ...
      ];
end

return

% ------------------------------------------------------------------------------
% Generate KML code to plot the trajectory of float profile locations.
%
% SYNTAX :
%  [o_kmlStr] = create_traj1(a_locData, a_locStyle, a_visibility)
%
% INPUT PARAMETERS :
%   a_locData    : input location information
%   a_locStyle   : style of the KML elements
%   a_visibility : initial visibility flag of the KML elements
%
% OUTPUT PARAMETERS :
%   o_kmlStr : output KML code
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/27/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_kmlStr] = create_traj1(a_locData, a_locStyle, a_visibility)

% output parameters initialization
o_kmlStr = '';

% default values initialization
global g_decArgo_janFirst1950InMatlab;


prevCyNum = nan;
for idCy = 1:length(a_locData.cyNum)

   cyNum = a_locData.cyNum(idCy);
   juld = a_locData.juld(idCy);
   lon = a_locData.lon(idCy);
   lat = a_locData.lat(idCy);

   if (cyNum == 0)
      prevCyNum = cyNum;
      prevLon = lon;
      prevLat = lat;
      continue
   end

   if (~isnan(prevCyNum) && (prevCyNum == cyNum-1))

      o_kmlStr = [o_kmlStr, ...
         9, '<Folder>', 10, ...
         9, 9, '<name>', sprintf('cycle %d', cyNum), '</name>', 10, ...
         ];

      lineDescription = '';
      timeSpanStart = datestr(juld+g_decArgo_janFirst1950InMatlab, 'yyyy-mm-ddTHH:MM:SSZ');
      o_kmlStr = [o_kmlStr, ge_create_line( ...
         [prevLon lon], [prevLat lat], ...
         lineDescription, ...
         '', ...
         a_locStyle, a_visibility, ...
         timeSpanStart, '')];

      o_kmlStr = [o_kmlStr, ...
         9, '</Folder>', 10, ...
         ];
   end

   prevCyNum = cyNum;
   prevLon = lon;
   prevLat = lat;
end

return

% ------------------------------------------------------------------------------
% Generate KML code to plot the trajectory of float estimated profile locations.
%
% SYNTAX :
%  [o_kmlStr] = create_traj2(a_locData, a_startIdList, a_stopIdList, a_locStyle, a_visibility)
%
% INPUT PARAMETERS :
%   a_locData     : input location information
%   a_startIdList : start indexes of the set of cycles to process
%   a_stopIdList  : stop indexes of the set of cycles to process
%   a_locStyle    : style of the KML elements
%   a_visibility  : initial visibility flag of the KML elements
%
% OUTPUT PARAMETERS :
%   o_kmlStr : output KML code
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/27/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_kmlStr] = create_traj2(a_locData, a_startIdList, a_stopIdList, a_locStyle, a_visibility)

% output parameters initialization
o_kmlStr = '';

% default values initialization
global g_decArgo_janFirst1950InMatlab;


for idSet = 1:length(a_startIdList)

   idList = a_startIdList(idSet):a_stopIdList(idSet);
   cyNumList = a_locData.cyNum(idList);
   juldList = a_locData.juld(idList);
   lonList = a_locData.lon(idList);
   latList = a_locData.lat(idList);

   prevCyNum = nan;
   for idCy = 1:length(cyNumList)

      cyNum = cyNumList(idCy);
      juld = juldList(idCy);
      lon = lonList(idCy);
      lat = latList(idCy);

      if (idCy == 1)
         prevCyNum = cyNum;
         prevLon = lon;
         prevLat = lat;
         continue
      end

      if (~isnan(prevCyNum) && (prevCyNum == cyNum-1))

         o_kmlStr = [o_kmlStr, ...
            9, '<Folder>', 10, ...
            9, 9, '<name>', sprintf('cycle %d', cyNum), '</name>', 10, ...
            ];

         lineDescription = '';
         timeSpanStart = datestr(juld+g_decArgo_janFirst1950InMatlab, 'yyyy-mm-ddTHH:MM:SSZ');
         o_kmlStr = [o_kmlStr, ge_create_line( ...
            [prevLon lon], [prevLat lat], ...
            lineDescription, ...
            '', ...
            a_locStyle, a_visibility, ...
            timeSpanStart, '')];

         o_kmlStr = [o_kmlStr, ...
            9, '</Folder>', 10, ...
            ];
      end

      prevCyNum = cyNum;
      prevLon = lon;
      prevLat = lat;
   end
end

return

% ------------------------------------------------------------------------------
% Generate KML code to plot float profile locations.
%
% SYNTAX :
%  [o_kmlStr] = create_loc1(a_locData, a_goodLocStyle, a_badLocStyle, a_visibility)
%
% INPUT PARAMETERS :
%   a_locData      : input location information
%   a_goodLocStyle : style of the KML elements for good locations
%   a_badLocStyle  : style of the KML elements for bad locations
%   a_visibility   : initial visibility flag of the KML elements
%
% OUTPUT PARAMETERS :
%   o_kmlStr : output KML code
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/27/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_kmlStr] = create_loc1(a_locData, a_goodLocStyle, a_badLocStyle, a_visibility)

% output parameters initialization
o_kmlStr = '';

% default values initialization
global g_decArgo_janFirst1950InMatlab;


o_kmlStr = '';
for idCy = 1:length(a_locData.cyNum)

   cyNum = a_locData.cyNum(idCy);
   juld = a_locData.juld(idCy);
   lon = a_locData.lon(idCy);
   lat = a_locData.lat(idCy);
   posQc = a_locData.posQc(idCy);
   
   if (cyNum == 0)
      continue
   end

   o_kmlStr = [o_kmlStr, ...
      9, '<Folder>', 10, ...
      9, 9, '<name>', sprintf('cycle %d', cyNum), '</name>', 10, ...
      ];

   argosPosDescription = '';
   argosPosDescription = [argosPosDescription, ...
      sprintf('POSITION (lon, lat): %8.3f, %7.3f\n', lon, lat)];
   argosPosDescription = [argosPosDescription, ...
      sprintf('DATE               : %s\n', julian_2_gregorian_dec_argo(juld))];
   argosPosDescription = [argosPosDescription, ...
      sprintf('LOC CLASS          : %c\n', num2str(posQc))];

   if (ismember(posQc, [0 1 2]))
      locStyle = a_goodLocStyle;
   else
      locStyle = a_badLocStyle;
   end

   timeSpanStart = datestr(juld+g_decArgo_janFirst1950InMatlab, 'yyyy-mm-ddTHH:MM:SSZ');

   o_kmlStr = [o_kmlStr, ge_create_pos( ...
      lon, lat, ...
      argosPosDescription, ...
      sprintf('%d', cyNum), ...
      locStyle, a_visibility, ...
      timeSpanStart, '')];

   o_kmlStr = [o_kmlStr, ...
      9, '</Folder>', 10, ...
      ];
end

return

% ------------------------------------------------------------------------------
% Generate KML code to plot the estimated profile locations.
%
% SYNTAX :
%  [o_kmlStr] = create_loc2(a_locData, a_startIdList, a_stopIdList, a_locStyle, a_visibility)
%
% INPUT PARAMETERS :
%   a_locData     : input location information
%   a_startIdList : start indexes of the set of cycles to process
%   a_stopIdList  : stop indexes of the set of cycles to process
%   a_locStyle    : style of the KML elements
%   a_visibility  : initial visibility flag of the KML elements
%
% OUTPUT PARAMETERS :
%   o_kmlStr : output KML code
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/27/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_kmlStr] = create_loc2(a_locData, a_startIdList, a_stopIdList, a_locStyle, a_visibility)

% output parameters initialization
o_kmlStr = '';

% default values initialization
global g_decArgo_janFirst1950InMatlab;


o_kmlStr = '';
for idSet = 1:length(a_startIdList)

   idList = a_startIdList(idSet)+1:a_stopIdList(idSet)-1;
   cyNumList = a_locData.cyNum(idList);
   juldList = a_locData.juld(idList);
   lonList = a_locData.lon(idList);
   latList = a_locData.lat(idList);
   depthConstList = a_locData.depthConstraint(idList);
   gebcoDepthList = a_locData.gebcoDepth(idList);
   groundedList = a_locData.grd(idList);

   for idCy = 1:length(cyNumList)

      cyNum = cyNumList(idCy);
      juld = juldList(idCy);
      lon = lonList(idCy);
      lat = latList(idCy);
      depthConst = depthConstList(idCy);
      gebcoDepth = gebcoDepthList(idCy);
      grounded = groundedList(idCy);

      o_kmlStr = [o_kmlStr, ...
         9, '<Folder>', 10, ...
         9, 9, '<name>', sprintf('cycle %d', cyNum), '</name>', 10, ...
         ];

      argosPosDescription = '';
      argosPosDescription = [argosPosDescription, ...
         sprintf('POSITION (lon, lat): %8.3f, %7.3f\n', lon, lat)];
      argosPosDescription = [argosPosDescription, ...
         sprintf('DATE               : %s\n', julian_2_gregorian_dec_argo(juld))];
      argosPosDescription = [argosPosDescription, ...
         sprintf('DEPTH CONSTRAINT   : %.1f\n', depthConst)];
      argosPosDescription = [argosPosDescription, ...
         sprintf('GEBCO DEPTH        : %.1f\n', gebcoDepth)];
      argosPosDescription = [argosPosDescription, ...
         sprintf('GROUNDED FLAG      : %d\n', grounded)];

      timeSpanStart = datestr(juld+g_decArgo_janFirst1950InMatlab, 'yyyy-mm-ddTHH:MM:SSZ');

      o_kmlStr = [o_kmlStr, ge_create_pos( ...
         lon, lat, ...
         argosPosDescription, ...
         sprintf('%d', cyNum), ...
         a_locStyle, a_visibility, ...
         timeSpanStart, '')];

      o_kmlStr = [o_kmlStr, ...
         9, '</Folder>', 10, ...
         ];
   end
end

return

% ------------------------------------------------------------------------------
% Generate KML code to plot local isobath for estimated locations.
%
% SYNTAX :
%  [o_kmlStr] = create_isobath(a_locData, a_startIdList, a_stopIdList, a_lineStyle, a_visibility, a_gebcoFileName)
%
% INPUT PARAMETERS :
%   a_locData       : input location information
%   a_startIdList   : start indexes of the set of cycles to process
%   a_stopIdList    : stop indexes of the set of cycles to process
%   a_locStyle      : style of the KML elements
%   a_visibility    : initial visibility flag of the KML elements
%   a_gebcoFileName : GEBCO file path name
%
% OUTPUT PARAMETERS :
%   o_kmlStr : output KML code
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/27/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_kmlStr] = create_isobath(a_locData, a_startIdList, a_stopIdList, a_lineStyle, a_visibility, a_gebcoFileName)

% output parameters initialization
o_kmlStr = '';


for idSet = 1:length(a_startIdList)

   idList = a_startIdList(idSet):a_stopIdList(idSet);
   cyNumList = a_locData.cyNum(idList);
   juldList = a_locData.juld(idList);
   lonList = a_locData.lon(idList);
   latList = a_locData.lat(idList);
   forwLonList = a_locData.forwLon(idList);
   forwLatList = a_locData.forwLat(idList);
   backwLonList = a_locData.backwLon(idList);
   backwLatList = a_locData.backwLat(idList);
   depthList = a_locData.depthConstraint(idList);

   lonAllList = [lonList forwLonList backwLonList];
   if (any(lonAllList > 180))
      id = find(lonAllList > 180);
      lonAllList(id) = lonAllList(id) - 360;
   end
   latAllList = [latList forwLatList backwLatList];

   lonMin = min(lonAllList);
   lonMax = max(lonAllList);
   latMin = min(latAllList);
   latMax = max(latAllList);

   depthMin = min(depthList);
   depthMax = max(depthList);

   kmlStr = ge_generate_isobath((depthMin:100:depthMax)*-1, [lonMin lonMax], [latMin latMax], a_lineStyle, a_visibility, juldList(1), a_gebcoFileName);

   o_kmlStr = [o_kmlStr, ...
      9, '<Folder>', 10, ...
      9, 9, '<name>', sprintf('cycles %d - %d', cyNumList(1), cyNumList(end)), '</name>', 10, ...
      ];
   o_kmlStr = [o_kmlStr, ...
      kmlStr];
   o_kmlStr = [o_kmlStr, ...
      9, '</Folder>', 10, ...
      ];
end

return

% ------------------------------------------------------------------------------
% Generate KML code to plot local isobath for on set of estimated locations.
%
% SYNTAX :
%  [o_kmlStr] = ge_generate_isobath(a_levels, a_lon, a_lat, ...
%    a_lineStyle, a_visibility, a_timeSpanStart, a_gebcoFileName)
%
% INPUT PARAMETERS :
%   a_levels        : depth level of isobath
%   a_lon           : min and max longitudes
%   a_lat           : min and max latitudes
%   a_lineStyle     : style of the KML elements
%   a_visibility    : initial visibility flag of the KML elements
%   a_timeSpanStart : date to start visibility of the KML elements
%   a_gebcoFileName : GEBCO file path name
%
% OUTPUT PARAMETERS :
%   o_kmlStr : output KML code
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/27/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_kmlStr] = ge_generate_isobath(a_levels, a_lon, a_lat, ...
   a_lineStyle, a_visibility, a_timeSpanStart, a_gebcoFileName)

o_kmlStr = [];

% default values initialization
global g_decArgo_janFirst1950InMatlab;


% retrieve GEBCO elevations
[gebcoElev, gebcoLon , gebcoLat] = get_gebco_elev_zone(a_lon(1), a_lon(2), a_lat(1), a_lat(2), a_gebcoFileName);
gebcoLon = gebcoLon(1,:);
gebcoLat = gebcoLat(:,1);

levels = a_levels;
if (length(levels))
   levels = [levels levels];
end

% generate isobath
resCont = contourc(gebcoLon , gebcoLat, gebcoElev, levels);

% create KML code for generated isobath
[lin, col] = size(resCont);
id = 1;
while (id < col)
   nbVertices = resCont(2, id);

   lon = resCont(1, id+1:id+nbVertices);
   idLon = find(lon > 180);
   lon(idLon) = lon(idLon) - 360;
   idLon = find(lon < -180);
   lon(idLon) = lon(idLon) + 360;
   lat = resCont(2, id+1:id+nbVertices);

   timeSpanStart = datestr(a_timeSpanStart+g_decArgo_janFirst1950InMatlab, 'yyyy-mm-ddTHH:MM:SSZ');

   o_kmlStr = [o_kmlStr, ge_create_line( ...
      lon, lat, ...
      '', ...
      '', ...
      a_lineStyle, a_visibility, ...
      timeSpanStart, '')];

   id = id + nbVertices + 1;
end

return

% ------------------------------------------------------------------------------
% Generate KML code to plot a line.
%
% SYNTAX :
%  [o_kmlStr] = ge_create_line(a_lon, a_lat, a_description, a_name, ...
%    a_style, a_visibility, a_timeSpanStart, a_timeSpanEnd)
%
% INPUT PARAMETERS :
%   a_lon           : line longitudes
%   a_lat           : line latitudes
%   a_description   : description of the KML elements
%   a_name          : name of the KML elements
%   a_style         : style of the KML elements
%   a_visibility    : initial visibility flag of the KML elements
%   a_timeSpanStart : date to start visibility of the KML elements
%   a_timeSpanEnd   : date to stop visibility of the KML elements
%
% OUTPUT PARAMETERS :
%   o_kmlStr : output KML code
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/27/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_kmlStr] = ge_create_line(a_lon, a_lat, a_description, a_name, ...
   a_style, a_visibility, a_timeSpanStart, a_timeSpanEnd)

o_kmlStr = [];

timeSpanStartStr = [];
timeSpanEndStr = [];
if (~isempty(a_timeSpanStart))
   timeSpanStartStr = [ ...
      9, 9, 9, '<begin>', a_timeSpanStart, '</begin>', 10, ...
      ];
end
if (~isempty(a_timeSpanEnd))
   timeSpanEndStr = [ ...
      9, 9, 9, '<end>', a_timeSpanEnd, '</end>', 10, ...
      ];
end
timeSpanStr = [ ...
   9, 9, '<TimeSpan>', 10, ...
   timeSpanStartStr, ...
   timeSpanEndStr, ...
   9, 9, '</TimeSpan>', 10, ...
   ];

coordinatesLine = [];
for idPos = 1:length(a_lon)
   coordinatesLine = [ coordinatesLine ...
      sprintf('%.3f,%.3f,0 ', a_lon(idPos), a_lat(idPos))];
end

o_kmlStr = [ ...
   9, '<Placemark>', 10, ...
   9, 9, ['<visibility> ' num2str(a_visibility) ' </visibility>'], 10, ...
   9, 9, '<description>', 10, ...
   9, 9, 9, '<![CDATA[' a_description ']]>', 10, ...
   9, 9, '</description>', 10, ...
   9, 9, '<name>', a_name, '</name>', 10, ...
   9, 9, '<styleUrl>', a_style, '</styleUrl>', 10, ...
   timeSpanStr, ...
   9, 9, '<LineString>', 10, ...
   9, 9, 9, '<coordinates>', 10, ...
   9, 9, 9, 9, coordinatesLine, 10, ...
   9, 9, 9, '</coordinates>', 10, ...
   9, 9, '</LineString>', 10, ...
   9, '</Placemark>', 10, ...
   ];

return

% ------------------------------------------------------------------------------
% Generate KML code to plot a location.
%
% SYNTAX :
%  [o_kmlStr] = ge_create_pos(a_lon, a_lat, a_description, a_name, ...
%    a_style, a_visibility, a_timeSpanStart, a_timeSpanEnd)
%
% INPUT PARAMETERS :
%   a_lon           : location longitudes
%   a_lat           : location latitudes
%   a_description   : description of the KML elements
%   a_name          : name of the KML elements
%   a_style         : style of the KML elements
%   a_visibility    : initial visibility flag of the KML elements
%   a_timeSpanStart : date to start visibility of the KML elements
%   a_timeSpanEnd   : date to stop visibility of the KML elements
%
% OUTPUT PARAMETERS :
%   o_kmlStr : output KML code
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/27/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_kmlStr] = ge_create_pos(a_lon, a_lat, a_description, a_name, ...
   a_style, a_visibility, a_timeSpanStart, a_timeSpanEnd)

o_kmlStr = [];

timeSpanStartStr = [];
timeSpanEndStr = [];
if (~isempty(a_timeSpanStart))
   timeSpanStartStr = [ ...
      9, 9, 9, '<begin>', a_timeSpanStart, '</begin>', 10, ...
      ];
end
if (~isempty(a_timeSpanEnd))
   timeSpanEndStr = [ ...
      9, 9, 9, '<end>', a_timeSpanEnd, '</end>', 10, ...
      ];
end
timeSpanStr = [ ...
   9, 9, '<TimeSpan>', 10, ...
   timeSpanStartStr, ...
   timeSpanEndStr, ...
   9, 9, '</TimeSpan>', 10, ...
   ];

coordinatesLine = [];
for idPos = 1:length(a_lon)
   coordinatesLine = [ coordinatesLine...
      sprintf('%.3f,%.3f,0 ', a_lon(idPos), a_lat(idPos))];
end

o_kmlStr = [ ...
   9, '<Placemark>', 10, ...
   9, 9, ['<visibility> ' num2str(a_visibility) ' </visibility>'], 10, ...
   9, 9, '<description>', 10, ...
   9, 9, 9, '<![CDATA[' a_description ']]>', 10, ...
   9, 9, '</description>', 10, ...
   9, 9, '<name>', a_name, '</name>', 10, ...
   9, 9, '<styleUrl>', a_style, '</styleUrl>', 10, ...
   timeSpanStr, ...
   9, 9, '<Point>', 10, ...
   9, 9, 9, '<coordinates>', 10, ...
   9, 9, 9, 9, coordinatesLine, 10, ...
   9, 9, 9, '</coordinates>', 10, ...
   9, 9, '</Point>', 10, ...
   9, '</Placemark>', 10, ...
   ];

return
