% STANDALONE VERSION OF ge_generate_traj_from_csv_estimate_profile_position
% ------------------------------------------------------------------------------
% Generate KML file from estimate_profile_position tool output CSV file to plot
% final (and intermediate) trajectories of estimated profile locations.
%
% SYNTAX :
%   ge_generate_traj_from_csv_estimate_profile_position('csv_file_path_name')
%
% INPUT PARAMETERS :
%   varargin : CSV file path name
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/27/2022 - RNU - creation
%   08/21/2024 - RNU - for V1.2 version of estimate_profile_locations
% ------------------------------------------------------------------------------
function ge_generate_traj_from_csv_estimate_profile_position(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START

% directory of KML output file
DIR_OUTPUT_KML_FILES = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% GEBCO bathymetric file
GEBCO_FILE = 'C:\Users\jprannou\_RNU\_ressources\GEBCO_2024\GEBCO_2024.nc';

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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
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

if (rem(size(fileContents, 1), 37) ~= 0)
   fprintf('ERROR: Unable to parse file: %s\n', a_filePathName);
   return
end

trajData = reshape(fileContents, 37, size(fileContents, 1)/37)';
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
      case 'SpeedForw'
         o_trajData.speedForw = str2double(trajData(2:end, idCol)');
      case 'BackwLat'
         o_trajData.backwLat = str2double(trajData(2:end, idCol)');
      case 'BackwLon'
         o_trajData.backwLon = str2double(trajData(2:end, idCol)');
      case 'BackwGebcoDepth'
         o_trajData.backwGebcoDepth = str2double(trajData(2:end, idCol)');
      case 'BackDiffDepth'
         o_trajData.backDiffDepth = str2double(trajData(2:end, idCol)');
      case 'SpeedBack'
         o_trajData.speedBack = str2double(trajData(2:end, idCol)');
      case 'TrajLat'
         o_trajData.trajLat = str2double(trajData(2:end, idCol)');
      case 'TrajLon'
         o_trajData.trajLon = str2double(trajData(2:end, idCol)');
      case 'SpeedTraj'
         o_trajData.speedTraj = str2double(trajData(2:end, idCol)');
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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
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

% ------------------------------------------------------------------------------
% ADDITIONAL FUNCTIONS NEEDED TO CREATE A STANDALONE TOOL
% ------------------------------------------------------------------------------

% ------------------------------------------------------------------------------
% Initialize global default values.
%
% SYNTAX :
%  init_default_values(varargin)
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function init_default_values(varargin)

% decoder version
global g_decArgo_decoderVersion;

% lists of managed decoders
global g_decArgo_decoderIdListNkeArgos;
global g_decArgo_decoderIdListNkeIridiumRbr;
global g_decArgo_decoderIdListNkeIridiumNotDeep;
global g_decArgo_decoderIdListNkeIridiumDeep;
global g_decArgo_decoderIdListNkeIridium;
global g_decArgo_decoderIdListNkeCts4NotIce;
global g_decArgo_decoderIdListNkeCts4Ice;
global g_decArgo_decoderIdListNkeCts4;
global g_decArgo_decoderIdListNkeCts5Osean;
global g_decArgo_decoderIdListNkeCts5Usea;
global g_decArgo_decoderIdListNkeCts5;
global g_decArgo_decoderIdListNkeMisc;
global g_decArgo_decoderIdListNke;
global g_decArgo_decoderIdListApexApf9Argos;
global g_decArgo_decoderIdListApexApf9IridiumRudics;
global g_decArgo_decoderIdListApexApf9IridiumSbd;
global g_decArgo_decoderIdListApexApf9Iridium;
global g_decArgo_decoderIdListApexApf11IridiumRudics;
global g_decArgo_decoderIdListApexApf11IridiumSbd;
global g_decArgo_decoderIdListApexApf11Iridium;
global g_decArgo_decoderIdListApexApf11Argos;
global g_decArgo_decoderIdListApexArgos;
global g_decArgo_decoderIdListApexIridium;
global g_decArgo_decoderIdListApex;
global g_decArgo_decoderIdListNavis;
global g_decArgo_decoderIdListNova;
global g_decArgo_decoderIdListNemo;
global g_decArgo_decoderIdListAll;
global g_decArgo_decoderIdListDeepFloat;
global g_decArgo_decoderIdListBgcFloatNKE;
global g_decArgo_decoderIdListBgcFloatApex;
global g_decArgo_decoderIdListBgcFloatAll;
global g_decArgo_decoderIdListProfWithDatedLev;
global g_decArgo_decoderIdListMtime;

% for RBR PSAL RT adjustment
% list of pre-april 2021 RBR floats
global g_decArgo_rbrPreApril2021FloatList;

% lists of CTS5 files
global g_decArgo_provorCts5OseanFileTypeListRsync;
global g_decArgo_provorCts5UseaFileTypeListRsync;
global g_decArgo_provorCts5UseaFileTypeListCopy;
global g_decArgo_provorCts5UseaFileTypeList;
global g_decArgo_provorCts5OseanFileTypeListAll;
global g_decArgo_provorCts5UseaFileTypeListAll;

% list of parameters that have an extra dimension (N_VALUESx)
global g_decArgo_paramWithExtraDimList;

% list of parameters that have at least one RTQC test
global g_decArgo_paramWithRtqcTest;

% global default values
global g_decArgo_dateDef;
global g_decArgo_epochDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;
global g_decArgo_ncDateDef;
global g_decArgo_ncArgosLonDef;
global g_decArgo_ncArgosLatDef;
global g_decArgo_presCountsDef;
global g_decArgo_presCountsOkDef;
global g_decArgo_tempCountsDef;
global g_decArgo_salCountsDef;
global g_decArgo_cndcCountsDef;
global g_decArgo_oxyPhaseCountsDef;
global g_decArgo_chloroACountsDef;
global g_decArgo_chloroAVoltCountsDef;
global g_decArgo_backscatCountsDef;
global g_decArgo_cdomCountsDef;
global g_decArgo_iradianceCountsDef;
global g_decArgo_parCountsDef;
global g_decArgo_turbiCountsDef;
global g_decArgo_turbiVoltCountsDef;
global g_decArgo_concNitraCountsDef;
global g_decArgo_coefAttCountsDef;
global g_decArgo_vrsPhCountsDef;
global g_decArgo_molarDoxyCountsDef;
global g_decArgo_tPhaseDoxyCountsDef;
global g_decArgo_c1C2PhaseDoxyCountsDef;
global g_decArgo_phaseDelayDoxyCountsDef;
global g_decArgo_tempDoxyCountsDef;

global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_cndcDef;
global g_decArgo_molarDoxyDef;
global g_decArgo_mlplDoxyDef;
global g_decArgo_nbSampleDef;
global g_decArgo_c1C2PhaseDoxyDef;
global g_decArgo_bPhaseDoxyDef;
global g_decArgo_tPhaseDoxyDef;
global g_decArgo_rPhaseDoxyDef;
global g_decArgo_phaseDelayDoxyDef;
global g_decArgo_frequencyDoxyDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_doxyDef;
global g_decArgo_oxyPhaseDef;
global g_decArgo_chloroADef;
global g_decArgo_backscatDef;
global g_decArgo_cdomDef;
global g_decArgo_chloroDef;
global g_decArgo_chloroVoltDef;
global g_decArgo_turbiDef;
global g_decArgo_turbiVoltDef;
global g_decArgo_concNitraDef;
global g_decArgo_coefAttDef;
global g_decArgo_vrsPhDef;
global g_decArgo_fluorescenceChlaDef;
global g_decArgo_betaBackscattering700Def;
global g_decArgo_tempCpuChlaDef;
global g_decArgo_blueRefDef;
global g_decArgo_ntuRefDef;
global g_decArgo_sideScatteringTurbidityDef;

global g_decArgo_CHLADef;
global g_decArgo_PARTICLE_BACKSCATTERINGDef;

global g_decArgo_groundedDef;
global g_decArgo_durationDef;

global g_decArgo_janFirst1950InMatlab;
global g_decArgo_janFirst1970InJulD;
global g_decArgo_janFirst2000InJulD;

global g_decArgo_nbHourForProfDateCompInRtOffsetAdj;

global g_decArgo_profNum;
global g_decArgo_vertSpeed;

global g_decArgo_minNonTransDurForNewCycle;
global g_decArgo_minNonTransDurForGhost
global g_decArgo_minNumMsgForNotGhost;
global g_decArgo_minNumMsgForProcessing;
global g_decArgo_minSubSurfaceCycleDuration;
global g_decArgo_minSubSurfaceCycleDurationIrSbd2;
global g_decArgo_maxIntervalToRecoverConfigMessageBeforeLaunchDate;

% cycle phases
global g_decArgo_phasePreMission;
global g_decArgo_phaseSurfWait;
global g_decArgo_phaseInitNewCy;
global g_decArgo_phaseInitNewProf;
global g_decArgo_phaseBuoyRed;
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseDsc2Prof;
global g_decArgo_phaseProfDrift;
global g_decArgo_phaseAscProf;
global g_decArgo_phaseAscEmerg;
global g_decArgo_phaseDataProc;
global g_decArgo_phaseSatTrans;
global g_decArgo_phaseEndOfProf;
global g_decArgo_phaseEndOfLife;
global g_decArgo_phaseEmergencyAsc;
global g_decArgo_phaseUserDialog;
global g_decArgo_phaseBuoyInv;

% treatment types
global g_decArgo_treatRaw;
global g_decArgo_treatAverage;
global g_decArgo_treatAverageAndStDev;
global g_decArgo_treatAverageAndMedian;
global g_decArgo_treatAverageAndStDevAndMedian;
global g_decArgo_treatMedian;
global g_decArgo_treatMin;
global g_decArgo_treatMax;
global g_decArgo_treatStDev;
global g_decArgo_treatDecimatedRaw;

% common long_name for nc files
global g_decArgo_longNameOfParamAdjErr;

% QC flag values (numerical)
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;
global g_decArgo_qcGood;
global g_decArgo_qcProbablyGood;
global g_decArgo_qcCorrectable;
global g_decArgo_qcBad;
global g_decArgo_qcChanged;
global g_decArgo_qcInterpolated;
global g_decArgo_qcMissing;

% QC flag values (char)
global g_decArgo_qcStrDef;
global g_decArgo_qcStrNoQc;
global g_decArgo_qcStrGood;
global g_decArgo_qcStrProbablyGood;
global g_decArgo_qcStrCorrectable;
global g_decArgo_qcStrBad;
global g_decArgo_qcStrChanged;
global g_decArgo_qcStrUnused1;
global g_decArgo_qcStrUnused2;
global g_decArgo_qcStrInterpolated;
global g_decArgo_qcStrMissing;

% max number of CTD samples in one NOVA sensor data packet
global g_decArgo_maxCTDSampleInNovaDataPacket;

% max number of CTDO samples in one DOVA sensor data packet
global g_decArgo_maxCTDOSampleInDovaDataPacket;

% codes for CTS5 phases
global g_decArgo_cts5PhaseDescent;
global g_decArgo_cts5PhasePark;
global g_decArgo_cts5PhaseDeepProfile;
global g_decArgo_cts5PhaseShortPark;
global g_decArgo_cts5PhaseAscent;
global g_decArgo_cts5PhaseSurface;

% codes for CTS5 treatment types
global g_decArgo_cts5Treat_AM_SD_MD;
global g_decArgo_cts5Treat_AM_SD;
global g_decArgo_cts5Treat_AM_MD;
global g_decArgo_cts5Treat_RW;
global g_decArgo_cts5Treat_AM;
global g_decArgo_cts5Treat_SS;
global g_decArgo_cts5Treat_DW;

% max length allowed for VERTICAL_SAMPLING_SCHEME
global g_decArgo_vssMaxLength;

% max index for misc configuration parameters (CONFIG_PX)
global g_decArgo_configPxMaxT;
global g_decArgo_configPxMaxS;
global g_decArgo_configPxMaxP;
global g_decArgo_configPxMaxI;
global g_decArgo_configPxMaxK;

% DOXY coefficients
global g_decArgo_doxy_nomAirPress;
global g_decArgo_doxy_nomAirMix;

global g_decArgo_doxy_201and202_201_301_d0;
global g_decArgo_doxy_201and202_201_301_d1;
global g_decArgo_doxy_201and202_201_301_d2;
global g_decArgo_doxy_201and202_201_301_d3;
global g_decArgo_doxy_201and202_201_301_sPreset;
global g_decArgo_doxy_201and202_201_301_b0;
global g_decArgo_doxy_201and202_201_301_b1;
global g_decArgo_doxy_201and202_201_301_b2;
global g_decArgo_doxy_201and202_201_301_b3;
global g_decArgo_doxy_201and202_201_301_c0;
global g_decArgo_doxy_201and202_201_301_pCoef2;
global g_decArgo_doxy_201and202_201_301_pCoef3;

global g_decArgo_doxy_202_204_204_d0;
global g_decArgo_doxy_202_204_204_d1;
global g_decArgo_doxy_202_204_204_d2;
global g_decArgo_doxy_202_204_204_d3;
global g_decArgo_doxy_202_204_204_sPreset;
global g_decArgo_doxy_202_204_204_b0;
global g_decArgo_doxy_202_204_204_b1;
global g_decArgo_doxy_202_204_204_b2;
global g_decArgo_doxy_202_204_204_b3;
global g_decArgo_doxy_202_204_204_c0;
global g_decArgo_doxy_202_204_204_pCoef1;
global g_decArgo_doxy_202_204_204_pCoef2;
global g_decArgo_doxy_202_204_204_pCoef3;

global g_decArgo_doxy_202_204_202_a0;
global g_decArgo_doxy_202_204_202_a1;
global g_decArgo_doxy_202_204_202_a2;
global g_decArgo_doxy_202_204_202_a3;
global g_decArgo_doxy_202_204_202_a4;
global g_decArgo_doxy_202_204_202_a5;
global g_decArgo_doxy_202_204_202_d0;
global g_decArgo_doxy_202_204_202_d1;
global g_decArgo_doxy_202_204_202_d2;
global g_decArgo_doxy_202_204_202_d3;
global g_decArgo_doxy_202_204_202_sPreset;
global g_decArgo_doxy_202_204_202_b0;
global g_decArgo_doxy_202_204_202_b1;
global g_decArgo_doxy_202_204_202_b2;
global g_decArgo_doxy_202_204_202_b3;
global g_decArgo_doxy_202_204_202_c0;
global g_decArgo_doxy_202_204_202_pCoef1;
global g_decArgo_doxy_202_204_202_pCoef2;
global g_decArgo_doxy_202_204_202_pCoef3;

global g_decArgo_doxy_202_204_203_a0;
global g_decArgo_doxy_202_204_203_a1;
global g_decArgo_doxy_202_204_203_a2;
global g_decArgo_doxy_202_204_203_a3;
global g_decArgo_doxy_202_204_203_a4;
global g_decArgo_doxy_202_204_203_a5;
global g_decArgo_doxy_202_204_203_d0;
global g_decArgo_doxy_202_204_203_d1;
global g_decArgo_doxy_202_204_203_d2;
global g_decArgo_doxy_202_204_203_d3;
global g_decArgo_doxy_202_204_203_sPreset;
global g_decArgo_doxy_202_204_203_b0;
global g_decArgo_doxy_202_204_203_b1;
global g_decArgo_doxy_202_204_203_b2;
global g_decArgo_doxy_202_204_203_b3;
global g_decArgo_doxy_202_204_203_c0;
global g_decArgo_doxy_202_204_203_pCoef1;
global g_decArgo_doxy_202_204_203_pCoef2;
global g_decArgo_doxy_202_204_203_pCoef3;

global g_decArgo_doxy_202_204_302_a0;
global g_decArgo_doxy_202_204_302_a1;
global g_decArgo_doxy_202_204_302_a2;
global g_decArgo_doxy_202_204_302_a3;
global g_decArgo_doxy_202_204_302_a4;
global g_decArgo_doxy_202_204_302_a5;
global g_decArgo_doxy_202_204_302_d0;
global g_decArgo_doxy_202_204_302_d1;
global g_decArgo_doxy_202_204_302_d2;
global g_decArgo_doxy_202_204_302_d3;
global g_decArgo_doxy_202_204_302_sPreset;
global g_decArgo_doxy_202_204_302_b0;
global g_decArgo_doxy_202_204_302_b1;
global g_decArgo_doxy_202_204_302_b2;
global g_decArgo_doxy_202_204_302_b3;
global g_decArgo_doxy_202_204_302_c0;
global g_decArgo_doxy_202_204_302_pCoef1;
global g_decArgo_doxy_202_204_302_pCoef2;
global g_decArgo_doxy_202_204_302_pCoef3;

global g_decArgo_doxy_202_205_302_a0;
global g_decArgo_doxy_202_205_302_a1;
global g_decArgo_doxy_202_205_302_a2;
global g_decArgo_doxy_202_205_302_a3;
global g_decArgo_doxy_202_205_302_a4;
global g_decArgo_doxy_202_205_302_a5;
global g_decArgo_doxy_202_205_302_d0;
global g_decArgo_doxy_202_205_302_d1;
global g_decArgo_doxy_202_205_302_d2;
global g_decArgo_doxy_202_205_302_d3;
global g_decArgo_doxy_202_205_302_sPreset;
global g_decArgo_doxy_202_205_302_b0;
global g_decArgo_doxy_202_205_302_b1;
global g_decArgo_doxy_202_205_302_b2;
global g_decArgo_doxy_202_205_302_b3;
global g_decArgo_doxy_202_205_302_c0;
global g_decArgo_doxy_202_205_302_pCoef1;
global g_decArgo_doxy_202_205_302_pCoef2;
global g_decArgo_doxy_202_205_302_pCoef3;

global g_decArgo_doxy_202_204_303_a0;
global g_decArgo_doxy_202_204_303_a1;
global g_decArgo_doxy_202_204_303_a2;
global g_decArgo_doxy_202_204_303_a3;
global g_decArgo_doxy_202_204_303_a4;
global g_decArgo_doxy_202_204_303_a5;
global g_decArgo_doxy_202_204_303_d0;
global g_decArgo_doxy_202_204_303_d1;
global g_decArgo_doxy_202_204_303_d2;
global g_decArgo_doxy_202_204_303_d3;
global g_decArgo_doxy_202_204_303_sPreset;
global g_decArgo_doxy_202_204_303_b0;
global g_decArgo_doxy_202_204_303_b1;
global g_decArgo_doxy_202_204_303_b2;
global g_decArgo_doxy_202_204_303_b3;
global g_decArgo_doxy_202_204_303_c0;
global g_decArgo_doxy_202_204_303_pCoef1;
global g_decArgo_doxy_202_204_303_pCoef2;
global g_decArgo_doxy_202_204_303_pCoef3;

global g_decArgo_doxy_202_205_303_a0;
global g_decArgo_doxy_202_205_303_a1;
global g_decArgo_doxy_202_205_303_a2;
global g_decArgo_doxy_202_205_303_a3;
global g_decArgo_doxy_202_205_303_a4;
global g_decArgo_doxy_202_205_303_a5;
global g_decArgo_doxy_202_205_303_d0;
global g_decArgo_doxy_202_205_303_d1;
global g_decArgo_doxy_202_205_303_d2;
global g_decArgo_doxy_202_205_303_d3;
global g_decArgo_doxy_202_205_303_sPreset;
global g_decArgo_doxy_202_205_303_b0;
global g_decArgo_doxy_202_205_303_b1;
global g_decArgo_doxy_202_205_303_b2;
global g_decArgo_doxy_202_205_303_b3;
global g_decArgo_doxy_202_205_303_c0;
global g_decArgo_doxy_202_205_303_pCoef1;
global g_decArgo_doxy_202_205_303_pCoef2;
global g_decArgo_doxy_202_205_303_pCoef3;

global g_decArgo_doxy_202_205_304_d0;
global g_decArgo_doxy_202_205_304_d1;
global g_decArgo_doxy_202_205_304_d2;
global g_decArgo_doxy_202_205_304_d3;
global g_decArgo_doxy_202_205_304_sPreset;
global g_decArgo_doxy_202_205_304_b0;
global g_decArgo_doxy_202_205_304_b1;
global g_decArgo_doxy_202_205_304_b2;
global g_decArgo_doxy_202_205_304_b3;
global g_decArgo_doxy_202_205_304_c0;
global g_decArgo_doxy_202_205_304_pCoef1;
global g_decArgo_doxy_202_205_304_pCoef2;
global g_decArgo_doxy_202_205_304_pCoef3;

global g_decArgo_doxy_103_208_307_d0;
global g_decArgo_doxy_103_208_307_d1;
global g_decArgo_doxy_103_208_307_d2;
global g_decArgo_doxy_103_208_307_d3;
global g_decArgo_doxy_103_208_307_sPreset;
global g_decArgo_doxy_103_208_307_solB0;
global g_decArgo_doxy_103_208_307_solB1;
global g_decArgo_doxy_103_208_307_solB2;
global g_decArgo_doxy_103_208_307_solB3;
global g_decArgo_doxy_103_208_307_solC0;
global g_decArgo_doxy_103_208_307_pCoef1;
global g_decArgo_doxy_103_208_307_pCoef2;
global g_decArgo_doxy_103_208_307_pCoef3;

global g_decArgo_doxy_201_203_202_d0;
global g_decArgo_doxy_201_203_202_d1;
global g_decArgo_doxy_201_203_202_d2;
global g_decArgo_doxy_201_203_202_d3;
global g_decArgo_doxy_201_203_202_sPreset;
global g_decArgo_doxy_201_203_202_b0;
global g_decArgo_doxy_201_203_202_b1;
global g_decArgo_doxy_201_203_202_b2;
global g_decArgo_doxy_201_203_202_b3;
global g_decArgo_doxy_201_203_202_c0;
global g_decArgo_doxy_201_203_202_pCoef1;
global g_decArgo_doxy_201_203_202_pCoef2;
global g_decArgo_doxy_201_203_202_pCoef3;

global g_decArgo_doxy_201_202_202_d0;
global g_decArgo_doxy_201_202_202_d1;
global g_decArgo_doxy_201_202_202_d2;
global g_decArgo_doxy_201_202_202_d3;
global g_decArgo_doxy_201_202_202_sPreset;
global g_decArgo_doxy_201_202_202_b0;
global g_decArgo_doxy_201_202_202_b1;
global g_decArgo_doxy_201_202_202_b2;
global g_decArgo_doxy_201_202_202_b3;
global g_decArgo_doxy_201_202_202_c0;
global g_decArgo_doxy_201_202_202_pCoef1;
global g_decArgo_doxy_201_202_202_pCoef2;
global g_decArgo_doxy_201_202_202_pCoef3;

global g_decArgo_doxy_202_204_304_d0;
global g_decArgo_doxy_202_204_304_d1;
global g_decArgo_doxy_202_204_304_d2;
global g_decArgo_doxy_202_204_304_d3;
global g_decArgo_doxy_202_204_304_sPreset;
global g_decArgo_doxy_202_204_304_b0;
global g_decArgo_doxy_202_204_304_b1;
global g_decArgo_doxy_202_204_304_b2;
global g_decArgo_doxy_202_204_304_b3;
global g_decArgo_doxy_202_204_304_c0;
global g_decArgo_doxy_202_204_304_pCoef1;
global g_decArgo_doxy_202_204_304_pCoef2;
global g_decArgo_doxy_202_204_304_pCoef3;

global g_decArgo_doxy_102_207_206_a0;
global g_decArgo_doxy_102_207_206_a1;
global g_decArgo_doxy_102_207_206_a2;
global g_decArgo_doxy_102_207_206_a3;
global g_decArgo_doxy_102_207_206_a4;
global g_decArgo_doxy_102_207_206_a5;
global g_decArgo_doxy_102_207_206_b0;
global g_decArgo_doxy_102_207_206_b1;
global g_decArgo_doxy_102_207_206_b2;
global g_decArgo_doxy_102_207_206_b3;
global g_decArgo_doxy_102_207_206_c0;

% NITRATE coefficients
global g_decArgo_nitrate_a;
global g_decArgo_nitrate_b;
global g_decArgo_nitrate_c;
global g_decArgo_nitrate_d;
global g_decArgo_nitrate_e;
global g_decArgo_nitrate_opticalWavelengthOffset;


% the first 3 digits are incremented at each new complete dated release
% the last digit is incremented at each patch associated to a given complete
% dated release
g_decArgo_decoderVersion = '067a';

% list of managed decoders

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THE FOLLOWING LISTS SHOULD BE UPDATED FOR EACH NEW DECODER

% all managed decoders
g_decArgo_decoderIdListNkeArgos = [1, 3, 4, 11, 12, 17, 19, 24, 25, 27:32];
g_decArgo_decoderIdListNkeIridiumRbr = [224, 226, 227, 228, 229];
g_decArgo_decoderIdListNkeIridiumDeep = [201, 202, 203, 215, 216, 218, 221, 228, 229, 230];
g_decArgo_decoderIdListNkeIridiumNotDeep = setdiff([201:227 231], g_decArgo_decoderIdListNkeIridiumDeep);
g_decArgo_decoderIdListNkeIridium = [ ...
   g_decArgo_decoderIdListNkeIridiumNotDeep ...
   g_decArgo_decoderIdListNkeIridiumDeep];
g_decArgo_decoderIdListNkeCts4NotIce = [105, 106, 107, 109, 110, 112];
g_decArgo_decoderIdListNkeCts4Ice = [111, 113, 114, 115, 116];
g_decArgo_decoderIdListNkeCts4 = [ ...
   g_decArgo_decoderIdListNkeCts4NotIce ...
   g_decArgo_decoderIdListNkeCts4Ice];
g_decArgo_decoderIdListNkeCts5Osean = [121:125];
g_decArgo_decoderIdListNkeCts5Usea = [126:137];
g_decArgo_decoderIdListNkeCts5 = [ ...
   g_decArgo_decoderIdListNkeCts5Osean ...
   g_decArgo_decoderIdListNkeCts5Usea ...
   ];
g_decArgo_decoderIdListNkeMisc = [301, 302, 303];

g_decArgo_decoderIdListNke = [ ...
   g_decArgo_decoderIdListNkeArgos ...
   g_decArgo_decoderIdListNkeIridium ...
   g_decArgo_decoderIdListNkeCts4 ...
   g_decArgo_decoderIdListNkeCts5 ...
   g_decArgo_decoderIdListNkeMisc];

g_decArgo_decoderIdListApexApf9Argos = [1001:1016];
g_decArgo_decoderIdListApexApf9IridiumRudics = [1101:1114];
g_decArgo_decoderIdListApexApf9IridiumSbd = [1314];
g_decArgo_decoderIdListApexApf9Iridium = [ ...
   g_decArgo_decoderIdListApexApf9IridiumRudics ...
   g_decArgo_decoderIdListApexApf9IridiumSbd];
g_decArgo_decoderIdListApexApf11Argos = [1021, 1022];
g_decArgo_decoderIdListApexApf11IridiumRudics = [1121:1132];
g_decArgo_decoderIdListApexApf11IridiumSbd = [1321:1323];
g_decArgo_decoderIdListApexApf11Iridium = [ ...
   g_decArgo_decoderIdListApexApf11IridiumRudics ...
   g_decArgo_decoderIdListApexApf11IridiumSbd];
g_decArgo_decoderIdListApexArgos = [ ...
   g_decArgo_decoderIdListApexApf9Argos ...
   g_decArgo_decoderIdListApexApf11Argos];
g_decArgo_decoderIdListApexIridium = [ ...
   g_decArgo_decoderIdListApexApf9Iridium ...
   g_decArgo_decoderIdListApexApf11Iridium];

g_decArgo_decoderIdListApex = [ ...
   g_decArgo_decoderIdListApexArgos ...
   g_decArgo_decoderIdListApexIridium];

g_decArgo_decoderIdListNavis = [1201];
g_decArgo_decoderIdListNova = [2001, 2002, 2003];
g_decArgo_decoderIdListNemo = [3001];

g_decArgo_decoderIdListAll = [ ...
   g_decArgo_decoderIdListNke ...
   g_decArgo_decoderIdListApex ...
   g_decArgo_decoderIdListNavis ...
   g_decArgo_decoderIdListNova ...
   g_decArgo_decoderIdListNemo];

% DEEP float decoders
g_decArgo_decoderIdListDeepFloat = g_decArgo_decoderIdListNkeIridiumDeep;

% BGC float decoders (each sensor has is own PRES axis, i.e. need to interpolate
% the CTD data when needed by a BGC parameter)
g_decArgo_decoderIdListBgcFloatNKE = [ ...
   g_decArgo_decoderIdListNkeCts4 ...
   g_decArgo_decoderIdListNkeCts5 ...
   g_decArgo_decoderIdListNkeMisc ...
   ];
g_decArgo_decoderIdListBgcFloatApex = g_decArgo_decoderIdListApexApf11Iridium;
g_decArgo_decoderIdListBgcFloatAll = [ ...
   g_decArgo_decoderIdListBgcFloatNKE ...
   g_decArgo_decoderIdListBgcFloatApex];

% the floats that report profile dated levels are:
% - all NKE floats
% - all NOVA/DOVA floats
% - all NAVIS floats
% - all NEMO floats
% - Apex APF11 Iridium floats
g_decArgo_decoderIdListProfWithDatedLev = [ ...
   g_decArgo_decoderIdListNke ...
   g_decArgo_decoderIdListNova ...
   g_decArgo_decoderIdListNavis ...
   g_decArgo_decoderIdListNemo ...
   g_decArgo_decoderIdListApexIridium];

% the float with 'MTIME' parameter
g_decArgo_decoderIdListMtime = [ ...
   g_decArgo_decoderIdListNkeArgos ...
   setdiff(g_decArgo_decoderIdListNkeIridium, [219 220]) ... % no MTIME in Arvor C
   g_decArgo_decoderIdListNkeCts4 ...
   g_decArgo_decoderIdListNkeCts5 ...
   g_decArgo_decoderIdListApexApf11Iridium ...
   g_decArgo_decoderIdListNavis ...
   g_decArgo_decoderIdListNemo];

% for RBR PSAL RT adjustment
% list of pre-april 2021 RBR floats
g_decArgo_rbrPreApril2021FloatList = [ ...
   6903076 ...
   6903075 ...
   6904104 ...
   6904105 ...
   6904103 ...
   6904101 ...
   6904102 ...
   6903709 ...
   6903710 ...
   6903077 ...
   6903078 ...
   ];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% lists of CTS5 files

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THE FOLLOWING LISTS SHOULD BE UPDATED FOR EACH NEW CTS5 DECODER OR SENSOR

% FOR OSEAN

g_decArgo_provorCts5OseanFileTypeListRsync = [ ...
   {'_apmt'} {'.ini'}; ...
   {'_autotest_'} {'.txt'}; ...
   {'_default_'} {'.txt'}; ...
   {'_technical'} {'.txt'}; ...
   {'_payload'} {'.bin'}; ...
   {'_payload_'} {'.txt'}; ...
   {'_payload'} {'.xml'}; ...
   {'_sbe41'} {'.hex'}; ...
   {'_system_'} {'.hex'}; ...
   ];

g_decArgo_provorCts5OseanFileTypeListAll = [ ...
   {1} {'*_apmt*.ini'} {'_%u_%u_apmt'} {16} {'_%03d_%02d_apmt*.ini'};...
   {9} {'*_payload*.xml'} {'_%u_%u_payload'} {19} {'_%03d_%02d_payload*.xml'}; ...
   {2} {'_payload*.txt'} {''} {[]} {''}; ...
   {3} {'*_autotest_*.txt'} {'_%u_autotest'} {17} {'_%03d_autotest_*.txt'}; ...
   {4} {'*_technical*.txt'} {'_%u_%u_technical'} {21} {'_%03d_%02d_technical*.txt'}; ...
   {5} {'*_default_*.txt'} {'_%u_%u_default'} {19} {'_%03d_%02d_default_*.txt'}; ...
   {6} {'*_sbe41*.hex'} {'_%u_%u_sbe41'} {17} {'_%03d_%02d_sbe41*.hex'}; ...
   {7} {'*_payload*.bin'} {'_%u_%u_payload'} {19} {'_%03d_%02d_payload*.bin'}; ...
   %    {8} {'_system_*.hex'} {'_system_%u.hex'} {''}; ...
   {10} {'_payload*.xml'} {''} {[]} {''}; ...
   ];

% FOR USEA

g_decArgo_provorCts5UseaFileTypeListRsync = [ ...
   {'_apmt'} {'.ini'}; ...
   {'_payload'} {'.xml'}; ...
   {'_payload_'} {'.txt'}; ...
   {'_autotest_'} {'.txt'}; ...
   {'_technical'} {'.txt'}; ...
   {'_default_'} {'.txt'}; ...
   {'_sbe41'} {'.hex'}; ...
   {'_payload'} {'.bin'}; ...
   {'_system_'} {'.hex'}; ...
   {'_metadata'} {'.xml'}; ... % CTS5-USEA
   {'_do'} {'.hex'}; ... % CTS5-USEA
   {'_eco'} {'.hex'}; ... % CTS5-USEA
   {'_ocr'} {'.hex'}; ... % CTS5-USEA
   {'_opus_blk'} {'.hex'}; ... % CTS5-USEA
   {'_opus_lgt'} {'.hex'}; ... % CTS5-USEA
   {'_uvp6_blk'} {'.hex'}; ... % CTS5-USEA
   {'_uvp6_lpm'} {'.hex'}; ... % CTS5-USEA
   {'_uvp6_txo'} {'.hex'}; ... % CTS5-USEA
   {'_crover'} {'.hex'}; ... % CTS5-USEA
   {'_sbeph'} {'.hex'}; ... % CTS5-USEA
   {'_suna'} {'.hex'}; ... % CTS5-USEA
   {'_ramses'} {'.hex'}; ... % CTS5-USEA
   {'_ramses2'} {'.hex'}; ... % CTS5-USEA
   {'_mpe'} {'.hex'}; ... % CTS5-USEA
   {'_hydroc_c'} {'.hex'}; ... % CTS5-USEA
   {'_hydroc_m'} {'.hex'}; ... % CTS5-USEA
   {'_imu'} {'.hex'}; ... % CTS5-USEA
   {'_wave'} {'.hex'}; ... % CTS5-USEA
   ];

g_decArgo_provorCts5UseaFileTypeListCopy = [ ...
   {'*_apmt*.ini'} ...
   {'*_payload*.xml'} ...
   {'_payload_*.txt'} ...
   {'*_autotest_*.txt'} ...
   {'*_technical*.txt'} ...
   {'*_default_*.txt'} ...
   {'*_sbe41*.hex'} ...
   {'*_payload*.bin'} ...
   {'*_system_*.hex'} ...
   {'*_metadata*.xml'} ... % CTS5-USEA
   {'*_do*.hex'} ... % CTS5-USEA
   {'*_eco*.hex'} ... % CTS5-USEA
   {'*_ocr*.hex'} ... % CTS5-USEA
   {'*_opus_blk*.hex'} ... % CTS5-USEA
   {'*_opus_lgt*.hex'} ... % CTS5-USEA
   {'*_uvp6_blk*.hex'} ... % CTS5-USEA
   {'*_uvp6_lpm*.hex'} ... % CTS5-USEA
   {'*_uvp6_txo*.hex'} ... % CTS5-USEA
   {'*_crover*.hex'} ... % CTS5-USEA
   {'*_sbeph*.hex'} ... % CTS5-USEA
   {'*_suna*.hex'} ... % CTS5-USEA
   {'*_ramses*.hex'} ... % CTS5-USEA
   {'*_ramses2*.hex'} ... % CTS5-USEA
   {'*_mpe*.hex'} ... % CTS5-USEA
   {'*_hydroc_c*.hex'} ... % CTS5-USEA
   {'*_hydroc_m*.hex'} ... % CTS5-USEA
   {'*_imu*.hex'} ... % CTS5-USEA
   {'*_wave*.hex'} ... % CTS5-USEA
   ];

g_decArgo_provorCts5UseaFileTypeList = [ ...
   {'*_apmt*.ini'} ...
   {'*_autotest_*.txt'} ...
   {'*_technical*.txt'} ...
   {'*_default_*.txt'} ...
   {'*_sbe41*.hex'} ...
   {'*_payload*.bin'} ...
   {'*_metadata*.xml'} ... % CTS5-USEA
   {'*_do*.hex'} ... % CTS5-USEA
   {'*_eco*.hex'} ... % CTS5-USEA
   {'*_ocr*.hex'} ... % CTS5-USEA
   {'*_opus_blk*.hex'} ... % CTS5-USEA
   {'*_opus_lgt*.hex'} ... % CTS5-USEA
   {'*_uvp6_blk*.hex'} ... % CTS5-USEA
   {'*_uvp6_lpm*.hex'} ... % CTS5-USEA
   {'*_uvp6_txo*.hex'} ... % CTS5-USEA
   {'*_crover*.hex'} ... % CTS5-USEA
   {'*_sbeph*.hex'} ... % CTS5-USEA
   {'*_suna*.hex'} ... % CTS5-USEA
   {'*_ramses*.hex'} ... % CTS5-USEA
   {'*_ramses2*.hex'} ... % CTS5-USEA
   {'*_mpe*.hex'} ... % CTS5-USEA
   {'*_hydroc_c*.hex'} ... % CTS5-USEA
   {'*_hydroc_m*.hex'} ... % CTS5-USEA
   {'*_imu*.hex'} ... % CTS5-USEA
   {'*_wave*.hex'} ... % CTS5-USEA
   ];

g_decArgo_provorCts5UseaFileTypeListAll = [ ...
   {1} {'*_apmt*.ini'} {'_%u_%u_apmt'} {16} {'_%03d_%02d_apmt*.ini'};...
   {2} {'*_metadata*.xml'} {'_%u_%u_metadata'} {20} {'_%03d_%02d_metadata*.xml'};... % not used (already used at float declaration)
   {3} {'*_autotest_*.txt'} {'_%u_autotest'} {17} {'_%03d_autotest_*.txt'}; ...
   {4} {'*_technical*.txt'} {'_%u_%u_technical'} {21} {'_%03d_%02d_technical*.txt'}; ...
   {5} {'*_default_*.txt'} {'_%u_%u_default'} {19} {'_%03d_%02d_default_*.txt'}; ...
   {6} {'*_sbe41*.hex'} {'_%u_%u_sbe41'} {17} {'_%03d_%02d_sbe41*.hex'}; ...
   {7} {'*_do*.hex'} {'_%u_%u_do'} {14} {'_%03d_%02d_do*.hex'}; ...
   {8} {'*_eco*.hex'} {'_%u_%u_eco'} {15} {'_%03d_%02d_eco*.hex'}; ...
   {9} {'*_ocr*.hex'} {'_%u_%u_ocr'} {15} {'_%03d_%02d_ocr*.hex'}; ...
   {10} {'*_uvp6_blk*.hex'} {'_%u_%u_uvp6_blk'} {20} {'_%03d_%02d_uvp6_blk*.hex'}; ...
   {11} {'*_uvp6_lpm*.hex'} {'_%u_%u_uvp6_lpm'} {20} {'_%03d_%02d_uvp6_lpm*.hex'}; ...
   {12} {'*_crover*.hex'} {'_%u_%u_crover'} {18} {'_%03d_%02d_crover*.hex'}; ...
   {13} {'*_sbeph*.hex'} {'_%u_%u_sbeph'} {17} {'_%03d_%02d_sbeph*.hex'}; ...
   {14} {'*_suna*.hex'} {'_%u_%u_suna'} {16} {'_%03d_%02d_suna*.hex'}; ...
   {15} {'*_opus_blk*.hex'} {'_%u_%u_opus_blk'} {20} {'_%03d_%02d_opus_blk*.hex'}; ...
   {16} {'*_opus_lgt*.hex'} {'_%u_%u_opus_lgt'} {20} {'_%03d_%02d_opus_lgt*.hex'}; ...
   {17} {'*_ramses*.hex'} {'_%u_%u_ramses'} {18} {'_%03d_%02d_ramses*.hex'}; ...
   {18} {'*_mpe*.hex'} {'_%u_%u_mpe'} {15} {'_%03d_%02d_mpe*.hex'}; ...
   {19} {'*_hydroc_c*.hex'} {'_%u_%u_hydroc_c'} {20} {'_%03d_%02d_hydroc_c*.hex'}; ...
   {20} {'*_hydroc_m*.hex'} {'_%u_%u_hydroc_m'} {20} {'_%03d_%02d_hydroc_m*.hex'}; ...
   {21} {'*_uvp6_txo*.hex'} {'_%u_%u_uvp6_txo'} {20} {'_%03d_%02d_uvp6_txo*.hex'}; ...
   {22} {'*_ramses2*.hex'} {'_%u_%u_ramses2'} {19} {'_%03d_%02d_ramses2*.hex'}; ...
   {23} {'*_imu*.hex'} {'_%u_%u_imu'} {15} {'_%03d_%02d_imu*.hex'}; ...
   {24} {'*_wave*.hex'} {'_%u_%u_wave'} {16} {'_%03d_%02d_wave*.hex'}; ...
   ];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% list of parameters that have an extra dimension (N_VALUESx)
g_decArgo_paramWithExtraDimList = [ ...
   {'UV_INTENSITY_NITRATE'} ...
   {'UV_INTENSITY_NITRATE_2'} ...
   {'NB_SIZE_SPECTRA_PARTICLES'} ...
   {'NB_SIZE_SPECTRA_PARTICLES_PER_IMAGE'} ...
   {'GREY_SIZE_SPECTRA_PARTICLES'} ...
   {'BLACK_NB_SIZE_SPECTRA_PARTICLES'} ...
   {'RAW_DOWNWELLING_IRRADIANCE'} ...
   {'RAW_UPWELLING_RADIANCE'} ...
   {'INDEX_CATEGORY'} ...
   {'ECOTAXA_CATEGORY_ID'} ...
   {'NB_OBJECT_CATEGORY'} ...
   {'OBJECT_MEAN_VOLUME_CATEGORY'} ...
   {'OBJECT_MEAN_GREY_LEVEL_CATEGORY'} ...
   {'CONCENTRATION_LPM'} ...
   {'CONCENTRATION_CATEGORY'} ...
   {'BIOVOLUME_CATEGORY'} ...
   ];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% list of parameters that have at least one RTQC test
g_decArgo_paramWithRtqcTest = [ ...
   {'PRES'} ...
   {'PRES2'} ...
   {'PRES_2'} ...
   {'TEMP'} ...
   {'TEMP2'} ...
   {'TEMP_2'} ...
   {'PSAL'} ...
   {'PSAL2'} ...
   {'PSAL_2'} ...
   {'CNDC'} ...
   {'TEMP_CNDC'} ...
   {'DOXY'} ...
   {'DOXY2'} ...
   {'DOXY_2'} ...
   {'TEMP_DOXY'} ...
   {'TEMP_DOXY2'} ...
   {'TEMP_DOXY_2'} ...
   {'CHLA'} ...
   {'CHLA2'} ...
   {'CHLA_2'} ...
   {'CHLA_FLUORESCENCE'} ...
   {'CHLA_FLUORESCENCE2'} ...
   {'CHLA_FLUORESCENCE_2'} ...
   {'BBP700'} ...
   {'PH_IN_SITU_TOTAL'} ...
   {'NITRATE'} ...
   {'DOWN_IRRADIANCE380'} ...
   {'DOWN_IRRADIANCE412'} ...
   {'DOWN_IRRADIANCE443'} ...
   {'DOWN_IRRADIANCE490'} ...
   {'DOWN_IRRADIANCE665'} ...
   {'DOWNWELLING_PAR'} ...
   ];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% global default values initialization
g_decArgo_dateDef = 99999.99999999;
g_decArgo_epochDef = 9999999999;
g_decArgo_argosLonDef = 999.999;
g_decArgo_argosLatDef = 99.999;
g_decArgo_ncDateDef = 999999;
g_decArgo_ncArgosLonDef = 99999;
g_decArgo_ncArgosLatDef = 99999;
g_decArgo_presCountsDef = 99999;
g_decArgo_presCountsOkDef = -1;
g_decArgo_tempCountsDef = 99999;
g_decArgo_salCountsDef = 99999;
g_decArgo_cndcCountsDef = 99999;
g_decArgo_oxyPhaseCountsDef = 9999999999;
g_decArgo_chloroACountsDef = 99999;
g_decArgo_chloroAVoltCountsDef = 99999;
g_decArgo_backscatCountsDef = 99999;
g_decArgo_cdomCountsDef = 99999;
g_decArgo_iradianceCountsDef = 9999999999;
g_decArgo_parCountsDef = 9999999999;
g_decArgo_turbiCountsDef = 99999;
g_decArgo_turbiVoltCountsDef = 99999;
g_decArgo_concNitraCountsDef = 999e+036; % max = 3.40282346e+038
g_decArgo_coefAttCountsDef = 99999;
g_decArgo_vrsPhCountsDef = 99999;
g_decArgo_molarDoxyCountsDef = 99999;
g_decArgo_tPhaseDoxyCountsDef = 99999;
g_decArgo_c1C2PhaseDoxyCountsDef = 99999;
g_decArgo_phaseDelayDoxyCountsDef = 99999;
g_decArgo_tempDoxyCountsDef = 99999;

g_decArgo_presDef = 9999.9;
g_decArgo_tempDef = 99.999;
g_decArgo_salDef = 99.999;
g_decArgo_cndcDef = 99.9999;
g_decArgo_molarDoxyDef = 999;
g_decArgo_mlplDoxyDef = 999;
g_decArgo_nbSampleDef = 99999;
g_decArgo_c1C2PhaseDoxyDef = 999.999;
g_decArgo_bPhaseDoxyDef = 999.999;
g_decArgo_tPhaseDoxyDef = 999.999;
g_decArgo_rPhaseDoxyDef = 999.999;
g_decArgo_phaseDelayDoxyDef = 99999.999;
g_decArgo_frequencyDoxyDef = 99999.99;
g_decArgo_tempDoxyDef = 99.999;
g_decArgo_doxyDef = 999.999;
g_decArgo_oxyPhaseDef = 9999999.999;
g_decArgo_chloroADef = 9999.9;
g_decArgo_backscatDef = 9999.9;
g_decArgo_cdomDef = 9999.9;
g_decArgo_chloroDef = 9999.9;
g_decArgo_chloroVoltDef = 9.999;
g_decArgo_turbiDef = 9999.9;
g_decArgo_turbiVoltDef = 9.999;
g_decArgo_concNitraDef = 9.99e+038;
g_decArgo_coefAttDef = 99.999;
g_decArgo_vrsPhDef = 99.999999;
g_decArgo_fluorescenceChlaDef = 9999;
g_decArgo_betaBackscattering700Def = 9999;
g_decArgo_tempCpuChlaDef = 999;
g_decArgo_blueRefDef = 99999;
g_decArgo_ntuRefDef = 99999;
g_decArgo_sideScatteringTurbidityDef = 99999;

g_decArgo_CHLADef = 99999;
g_decArgo_PARTICLE_BACKSCATTERINGDef = 99999;

g_decArgo_groundedDef = -1;
g_decArgo_durationDef = -1;

g_decArgo_janFirst1950InMatlab = datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');

g_decArgo_janFirst1970InJulD = gregorian_2_julian_dec_argo('1970/01/01 00:00:00');

g_decArgo_janFirst2000InJulD = gregorian_2_julian_dec_argo('2000/01/01 00:00:00');

% RT offset adjustments comes from meta-data and are dated. The following
% parameter is used as the accepted interval to compare profile dates to
% adjustment dates (because historical adjustments could have been done with a
% different algorithm for profile date determination, thus cannot be directly
% compared)
g_decArgo_nbHourForProfDateCompInRtOffsetAdj = 2;

g_decArgo_profNum = 99;
g_decArgo_vertSpeed = 99.9;

% minimum duration (in hour) of a non-transmission period to create a new
% cycle for an Argos float
g_decArgo_minNonTransDurForNewCycle = 10;

% minimum duration (in hour) of a non-transmission period to use the ghost
% detection algorithm
g_decArgo_minNonTransDurForGhost = 3;

% minimum duration (in hour) of a sub-surface period for an Iridium float
g_decArgo_minSubSurfaceCycleDuration = 5;
g_decArgo_minSubSurfaceCycleDurationIrSbd2 = 1.5;

% minimum number of float messages in an Argos file to use it
% (if the Argos file contains less than g_decArgo_minNumMsgForNotGhost float
% Argos messages, the file is not decoded because considered as a ghost
% file (i.e. it only contains ghost messages))
g_decArgo_minNumMsgForNotGhost = 4;

% minimum number of float messages in an Argos file to be processed within the
% 'profile' mode
g_decArgo_minNumMsgForProcessing = 5;

% for delayed decoders: interval, before float launch date to consider float
% configuration messages of the prelude phase (when they are transmitted before
% float launch date)
g_decArgo_maxIntervalToRecoverConfigMessageBeforeLaunchDate = 6/24; % in days

g_decArgo_phasePreMission = 0;
g_decArgo_phaseSurfWait = 1;
g_decArgo_phaseInitNewCy = 2;
g_decArgo_phaseInitNewProf = 3;
g_decArgo_phaseBuoyRed = 4;
g_decArgo_phaseDsc2Prk = 5;
g_decArgo_phaseParkDrift = 6;
g_decArgo_phaseDsc2Prof = 7;
g_decArgo_phaseProfDrift = 8;
g_decArgo_phaseAscProf = 9;
g_decArgo_phaseAscEmerg = 10;
g_decArgo_phaseDataProc = 11;
g_decArgo_phaseSatTrans = 12;
g_decArgo_phaseEndOfProf = 13;
g_decArgo_phaseEndOfLife = 14;
g_decArgo_phaseEmergencyAsc = 15;
g_decArgo_phaseUserDialog = 16;
g_decArgo_phaseBuoyInv = 17;

g_decArgo_treatRaw = 0;
g_decArgo_treatAverage = 1;
g_decArgo_treatAverageAndStDev = 7;
g_decArgo_treatAverageAndMedian = 8;
g_decArgo_treatAverageAndStDevAndMedian = 9;
g_decArgo_treatMedian = 10;
g_decArgo_treatMin = 11;
g_decArgo_treatMax = 12;
g_decArgo_treatStDev = 13;
g_decArgo_treatDecimatedRaw = 14;

g_decArgo_longNameOfParamAdjErr = 'Contains the error on the adjusted values as determined by the delayed mode QC process';

% QC flag values (numerical)
g_decArgo_qcDef = -1;
g_decArgo_qcNoQc = 0;
g_decArgo_qcGood = 1;
g_decArgo_qcProbablyGood = 2;
g_decArgo_qcCorrectable = 3;
g_decArgo_qcBad = 4;
g_decArgo_qcChanged = 5;
g_decArgo_qcInterpolated = 8;
g_decArgo_qcMissing = 9;

% QC flag values (char)
g_decArgo_qcStrDef = ' ';
g_decArgo_qcStrNoQc = '0';
g_decArgo_qcStrGood = '1';
g_decArgo_qcStrProbablyGood = '2';
g_decArgo_qcStrCorrectable = '3';
g_decArgo_qcStrBad = '4';
g_decArgo_qcStrChanged = '5';
g_decArgo_qcStrUnused1 = '6';
g_decArgo_qcStrUnused2 = '7';
g_decArgo_qcStrInterpolated = '8';
g_decArgo_qcStrMissing = '9';

% max number of CTD samples in one NOVA sensor data packet (340 bytes max)
g_decArgo_maxCTDSampleInNovaDataPacket = 55;

% max number of CTDO samples in one DOVA sensor data packet (340 bytes max)
g_decArgo_maxCTDOSampleInDovaDataPacket = 33;

% codes for CTS5 phases
g_decArgo_cts5PhaseDescent = 1;
g_decArgo_cts5PhasePark = 2;
g_decArgo_cts5PhaseDeepProfile = 3;
g_decArgo_cts5PhaseShortPark = 4;
g_decArgo_cts5PhaseAscent = 5;
g_decArgo_cts5PhaseSurface = 6;

% codes for CTS5 treatment types
g_decArgo_cts5Treat_AM_SD_MD = 1; % mean + st dev + median
g_decArgo_cts5Treat_AM_SD = 2; % mean + st dev
g_decArgo_cts5Treat_AM_MD = 3; % mean + median
g_decArgo_cts5Treat_RW = 4; % raw
g_decArgo_cts5Treat_AM = 5; % mean
g_decArgo_cts5Treat_SS = 6; % sub-surface point (last pumped raw measurement)
g_decArgo_cts5Treat_DW = 7; % decimated raw

% max length allowed for VERTICAL_SAMPLING_SCHEME
g_decArgo_vssMaxLength = 256;

% max index for misc configuration parameters (CONFIG_PX)
g_decArgo_configPxMaxT = 3;
g_decArgo_configPxMaxS = 13;
g_decArgo_configPxMaxP = 3;
g_decArgo_configPxMaxI = 4;
g_decArgo_configPxMaxK = 8;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COEFFICIENTS FOR B PARAMETERS PROCESSING

% DOXY coefficients
g_decArgo_doxy_nomAirPress = 1013.25;
g_decArgo_doxy_nomAirMix = 0.20946;

g_decArgo_doxy_201and202_201_301_d0 = 24.4543;
g_decArgo_doxy_201and202_201_301_d1 = -67.4509;
g_decArgo_doxy_201and202_201_301_d2 = -4.8489;
g_decArgo_doxy_201and202_201_301_d3 = -5.44e-4;
g_decArgo_doxy_201and202_201_301_sPreset = 0;
g_decArgo_doxy_201and202_201_301_b0 = -6.24523e-3;
g_decArgo_doxy_201and202_201_301_b1 = -7.37614e-3;
g_decArgo_doxy_201and202_201_301_b2 = -1.03410e-2;
g_decArgo_doxy_201and202_201_301_b3 = -8.17083e-3;
g_decArgo_doxy_201and202_201_301_c0 = -4.88682e-7;
g_decArgo_doxy_201and202_201_301_pCoef2 = 0.00025;
g_decArgo_doxy_201and202_201_301_pCoef3 = 0.0328;

g_decArgo_doxy_202_204_204_d0 = 24.4543;
g_decArgo_doxy_202_204_204_d1 = -67.4509;
g_decArgo_doxy_202_204_204_d2 = -4.8489;
g_decArgo_doxy_202_204_204_d3 = -5.44e-4;
g_decArgo_doxy_202_204_204_sPreset = 0;
g_decArgo_doxy_202_204_204_b0 = -6.24523e-3;
g_decArgo_doxy_202_204_204_b1 = -7.37614e-3;
g_decArgo_doxy_202_204_204_b2 = -1.03410e-2;
g_decArgo_doxy_202_204_204_b3 = -8.17083e-3;
g_decArgo_doxy_202_204_204_c0 = -4.88682e-7;
g_decArgo_doxy_202_204_204_pCoef1 = 0.1;
g_decArgo_doxy_202_204_204_pCoef2 = 0.00022;
g_decArgo_doxy_202_204_204_pCoef3 = 0.0419;

g_decArgo_doxy_202_204_202_a0 = 2.00856;
g_decArgo_doxy_202_204_202_a1 = 3.22400;
g_decArgo_doxy_202_204_202_a2 = 3.99063;
g_decArgo_doxy_202_204_202_a3 = 4.80299;
g_decArgo_doxy_202_204_202_a4 = 9.78188e-1;
g_decArgo_doxy_202_204_202_a5 = 1.71069;
g_decArgo_doxy_202_204_202_d0 = 24.4543;
g_decArgo_doxy_202_204_202_d1 = -67.4509;
g_decArgo_doxy_202_204_202_d2 = -4.8489;
g_decArgo_doxy_202_204_202_d3 = -5.44e-4;
g_decArgo_doxy_202_204_202_sPreset = 0;
g_decArgo_doxy_202_204_202_b0 = -6.24523e-3;
g_decArgo_doxy_202_204_202_b1 = -7.37614e-3;
g_decArgo_doxy_202_204_202_b2 = -1.03410e-2;
g_decArgo_doxy_202_204_202_b3 = -8.17083e-3;
g_decArgo_doxy_202_204_202_c0 = -4.88682e-7;
g_decArgo_doxy_202_204_202_pCoef1 = 0.1;
g_decArgo_doxy_202_204_202_pCoef2 = 0.00022;
g_decArgo_doxy_202_204_202_pCoef3 = 0.0419;

g_decArgo_doxy_202_204_203_a0 = 2.00856;
g_decArgo_doxy_202_204_203_a1 = 3.22400;
g_decArgo_doxy_202_204_203_a2 = 3.99063;
g_decArgo_doxy_202_204_203_a3 = 4.80299;
g_decArgo_doxy_202_204_203_a4 = 9.78188e-1;
g_decArgo_doxy_202_204_203_a5 = 1.71069;
g_decArgo_doxy_202_204_203_d0 = 24.4543;
g_decArgo_doxy_202_204_203_d1 = -67.4509;
g_decArgo_doxy_202_204_203_d2 = -4.8489;
g_decArgo_doxy_202_204_203_d3 = -5.44e-4;
g_decArgo_doxy_202_204_203_sPreset = 0;
g_decArgo_doxy_202_204_203_b0 = -6.24523e-3;
g_decArgo_doxy_202_204_203_b1 = -7.37614e-3;
g_decArgo_doxy_202_204_203_b2 = -1.03410e-2;
g_decArgo_doxy_202_204_203_b3 = -8.17083e-3;
g_decArgo_doxy_202_204_203_c0 = -4.88682e-7;
g_decArgo_doxy_202_204_203_pCoef1 = 0.1;
g_decArgo_doxy_202_204_203_pCoef2 = 0.00022;
g_decArgo_doxy_202_204_203_pCoef3 = 0.0419;

g_decArgo_doxy_202_204_302_a0 = 2.00856;
g_decArgo_doxy_202_204_302_a1 = 3.22400;
g_decArgo_doxy_202_204_302_a2 = 3.99063;
g_decArgo_doxy_202_204_302_a3 = 4.80299;
g_decArgo_doxy_202_204_302_a4 = 9.78188e-1;
g_decArgo_doxy_202_204_302_a5 = 1.71069;
g_decArgo_doxy_202_204_302_d0 = 24.4543;
g_decArgo_doxy_202_204_302_d1 = -67.4509;
g_decArgo_doxy_202_204_302_d2 = -4.8489;
g_decArgo_doxy_202_204_302_d3 = -5.44e-4;
g_decArgo_doxy_202_204_302_sPreset = 0;
g_decArgo_doxy_202_204_302_b0 = -6.24523e-3;
g_decArgo_doxy_202_204_302_b1 = -7.37614e-3;
g_decArgo_doxy_202_204_302_b2 = -1.03410e-2;
g_decArgo_doxy_202_204_302_b3 = -8.17083e-3;
g_decArgo_doxy_202_204_302_c0 = -4.88682e-7;
g_decArgo_doxy_202_204_302_pCoef1 = 0.1;
g_decArgo_doxy_202_204_302_pCoef2 = 0.00022;
g_decArgo_doxy_202_204_302_pCoef3 = 0.0419;

g_decArgo_doxy_202_205_302_a0 = 2.00856;
g_decArgo_doxy_202_205_302_a1 = 3.22400;
g_decArgo_doxy_202_205_302_a2 = 3.99063;
g_decArgo_doxy_202_205_302_a3 = 4.80299;
g_decArgo_doxy_202_205_302_a4 = 9.78188e-1;
g_decArgo_doxy_202_205_302_a5 = 1.71069;
g_decArgo_doxy_202_205_302_d0 = 24.4543;
g_decArgo_doxy_202_205_302_d1 = -67.4509;
g_decArgo_doxy_202_205_302_d2 = -4.8489;
g_decArgo_doxy_202_205_302_d3 = -5.44e-4;
g_decArgo_doxy_202_205_302_sPreset = 0;
g_decArgo_doxy_202_205_302_b0 = -6.24523e-3;
g_decArgo_doxy_202_205_302_b1 = -7.37614e-3;
g_decArgo_doxy_202_205_302_b2 = -1.03410e-2;
g_decArgo_doxy_202_205_302_b3 = -8.17083e-3;
g_decArgo_doxy_202_205_302_c0 = -4.88682e-7;
g_decArgo_doxy_202_205_302_pCoef1 = 0.1;
g_decArgo_doxy_202_205_302_pCoef2 = 0.00022;
g_decArgo_doxy_202_205_302_pCoef3 = 0.0419;

g_decArgo_doxy_202_204_303_a0 = 2.00856;
g_decArgo_doxy_202_204_303_a1 = 3.22400;
g_decArgo_doxy_202_204_303_a2 = 3.99063;
g_decArgo_doxy_202_204_303_a3 = 4.80299;
g_decArgo_doxy_202_204_303_a4 = 9.78188e-1;
g_decArgo_doxy_202_204_303_a5 = 1.71069;
g_decArgo_doxy_202_204_303_d0 = 24.4543;
g_decArgo_doxy_202_204_303_d1 = -67.4509;
g_decArgo_doxy_202_204_303_d2 = -4.8489;
g_decArgo_doxy_202_204_303_d3 = -5.44e-4;
g_decArgo_doxy_202_204_303_sPreset = 0;
g_decArgo_doxy_202_204_303_b0 = -6.24523e-3;
g_decArgo_doxy_202_204_303_b1 = -7.37614e-3;
g_decArgo_doxy_202_204_303_b2 = -1.03410e-2;
g_decArgo_doxy_202_204_303_b3 = -8.17083e-3;
g_decArgo_doxy_202_204_303_c0 = -4.88682e-7;
g_decArgo_doxy_202_204_303_pCoef1 = 0.1;
g_decArgo_doxy_202_204_303_pCoef2 = 0.00022;
g_decArgo_doxy_202_204_303_pCoef3 = 0.0419;

g_decArgo_doxy_202_205_303_a0 = 2.00856;
g_decArgo_doxy_202_205_303_a1 = 3.22400;
g_decArgo_doxy_202_205_303_a2 = 3.99063;
g_decArgo_doxy_202_205_303_a3 = 4.80299;
g_decArgo_doxy_202_205_303_a4 = 9.78188e-1;
g_decArgo_doxy_202_205_303_a5 = 1.71069;
g_decArgo_doxy_202_205_303_d0 = 24.4543;
g_decArgo_doxy_202_205_303_d1 = -67.4509;
g_decArgo_doxy_202_205_303_d2 = -4.8489;
g_decArgo_doxy_202_205_303_d3 = -5.44e-4;
g_decArgo_doxy_202_205_303_sPreset = 0;
g_decArgo_doxy_202_205_303_b0 = -6.24523e-3;
g_decArgo_doxy_202_205_303_b1 = -7.37614e-3;
g_decArgo_doxy_202_205_303_b2 = -1.03410e-2;
g_decArgo_doxy_202_205_303_b3 = -8.17083e-3;
g_decArgo_doxy_202_205_303_c0 = -4.88682e-7;
g_decArgo_doxy_202_205_303_pCoef1 = 0.1;
g_decArgo_doxy_202_205_303_pCoef2 = 0.00022;
g_decArgo_doxy_202_205_303_pCoef3 = 0.0419;

g_decArgo_doxy_202_205_304_d0 = 24.4543;
g_decArgo_doxy_202_205_304_d1 = -67.4509;
g_decArgo_doxy_202_205_304_d2 = -4.8489;
g_decArgo_doxy_202_205_304_d3 = -5.44e-4;
g_decArgo_doxy_202_205_304_sPreset = 0;
g_decArgo_doxy_202_205_304_b0 = -6.24523e-3;
g_decArgo_doxy_202_205_304_b1 = -7.37614e-3;
g_decArgo_doxy_202_205_304_b2 = -1.03410e-2;
g_decArgo_doxy_202_205_304_b3 = -8.17083e-3;
g_decArgo_doxy_202_205_304_c0 = -4.88682e-7;
g_decArgo_doxy_202_205_304_pCoef1 = 0.1;
g_decArgo_doxy_202_205_304_pCoef2 = 0.00022;
g_decArgo_doxy_202_205_304_pCoef3 = 0.0419;

g_decArgo_doxy_103_208_307_d0 = 24.4543;
g_decArgo_doxy_103_208_307_d1 = -67.4509;
g_decArgo_doxy_103_208_307_d2 = -4.8489;
g_decArgo_doxy_103_208_307_d3 = -5.44e-4;
g_decArgo_doxy_103_208_307_sPreset = 0;
g_decArgo_doxy_103_208_307_solB0 = -6.24523e-3;
g_decArgo_doxy_103_208_307_solB1 = -7.37614e-3;
g_decArgo_doxy_103_208_307_solB2 = -1.03410e-2;
g_decArgo_doxy_103_208_307_solB3 = -8.17083e-3;
g_decArgo_doxy_103_208_307_solC0 = -4.88682e-7;
g_decArgo_doxy_103_208_307_pCoef1 = 0.115;
g_decArgo_doxy_103_208_307_pCoef2 = 0.00022;
g_decArgo_doxy_103_208_307_pCoef3 = 0.0419;

g_decArgo_doxy_201_203_202_d0 = 24.4543;
g_decArgo_doxy_201_203_202_d1 = -67.4509;
g_decArgo_doxy_201_203_202_d2 = -4.8489;
g_decArgo_doxy_201_203_202_d3 = -5.44e-4;
g_decArgo_doxy_201_203_202_sPreset = 0;
g_decArgo_doxy_201_203_202_b0 = -6.24523e-3;
g_decArgo_doxy_201_203_202_b1 = -7.37614e-3;
g_decArgo_doxy_201_203_202_b2 = -1.03410e-2;
g_decArgo_doxy_201_203_202_b3 = -8.17083e-3;
g_decArgo_doxy_201_203_202_c0 = -4.88682e-7;
g_decArgo_doxy_201_203_202_pCoef1 = 0.1;
g_decArgo_doxy_201_203_202_pCoef2 = 0.00022;
g_decArgo_doxy_201_203_202_pCoef3 = 0.0419;

g_decArgo_doxy_201_202_202_d0 = 24.4543;
g_decArgo_doxy_201_202_202_d1 = -67.4509;
g_decArgo_doxy_201_202_202_d2 = -4.8489;
g_decArgo_doxy_201_202_202_d3 = -5.44e-4;
g_decArgo_doxy_201_202_202_sPreset = 0;
g_decArgo_doxy_201_202_202_b0 = -6.24523e-3;
g_decArgo_doxy_201_202_202_b1 = -7.37614e-3;
g_decArgo_doxy_201_202_202_b2 = -1.03410e-2;
g_decArgo_doxy_201_202_202_b3 = -8.17083e-3;
g_decArgo_doxy_201_202_202_c0 = -4.88682e-7;
g_decArgo_doxy_201_202_202_pCoef1 = 0.1;
g_decArgo_doxy_201_202_202_pCoef2 = 0.00022;
g_decArgo_doxy_201_202_202_pCoef3 = 0.0419;

g_decArgo_doxy_202_204_304_d0 = 24.4543;
g_decArgo_doxy_202_204_304_d1 = -67.4509;
g_decArgo_doxy_202_204_304_d2 = -4.8489;
g_decArgo_doxy_202_204_304_d3 = -5.44e-4;
g_decArgo_doxy_202_204_304_sPreset = 0;
g_decArgo_doxy_202_204_304_b0 = -6.24523e-3;
g_decArgo_doxy_202_204_304_b1 = -7.37614e-3;
g_decArgo_doxy_202_204_304_b2 = -1.03410e-2;
g_decArgo_doxy_202_204_304_b3 = -8.17083e-3;
g_decArgo_doxy_202_204_304_c0 = -4.88682e-7;
g_decArgo_doxy_202_204_304_pCoef1 = 0.1;
g_decArgo_doxy_202_204_304_pCoef2 = 0.00022;
g_decArgo_doxy_202_204_304_pCoef3 = 0.0419;

g_decArgo_doxy_102_207_206_a0 = 2.00907;
g_decArgo_doxy_102_207_206_a1 = 3.22014;
g_decArgo_doxy_102_207_206_a2 = 4.0501;
g_decArgo_doxy_102_207_206_a3 = 4.94457;
g_decArgo_doxy_102_207_206_a4 = -0.256847;
g_decArgo_doxy_102_207_206_a5 = 3.88767;
g_decArgo_doxy_102_207_206_b0 = -0.00624523;
g_decArgo_doxy_102_207_206_b1 = -0.00737614;
g_decArgo_doxy_102_207_206_b2 = -0.00103410;
g_decArgo_doxy_102_207_206_b3 = -0.00817083;
g_decArgo_doxy_102_207_206_c0 = -0.000000488682;

% NITRATE coefficients
g_decArgo_nitrate_a = 1.27353e-07;
g_decArgo_nitrate_b = -7.56395e-06;
g_decArgo_nitrate_c = 2.91898e-05;
g_decArgo_nitrate_d = 1.67660e-03;
g_decArgo_nitrate_e = 1.46380e-02;
g_decArgo_nitrate_opticalWavelengthOffset = 210;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

return

% ------------------------------------------------------------------------------
% Convert a gregorian date to a julian 1950 date.
%
% SYNTAX :
%   [o_julDay] = gregorian_2_julian_dec_argo(a_gregorianDate)
%
% INPUT PARAMETERS :
%   a_gregorianDate : gregorain date (in 'yyyy/mm/dd HH:MM' or
%                     'yyyy/mm/dd HH:MM:SS' format)
%
% OUTPUT PARAMETERS :
%   o_julDay : julian 1950 date
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_julDay] = gregorian_2_julian_dec_argo(a_gregorianDate)

% default values
global g_decArgo_dateDef;
global g_decArgo_janFirst1950InMatlab;

% output parameters initialization
o_julDay = g_decArgo_dateDef;

if (~strcmp(deblank(a_gregorianDate(:)), ''))

   if (length(a_gregorianDate) == 16)
      a_gregorianDate = [a_gregorianDate ':00'];
   end

   res = sscanf(a_gregorianDate, '%d/%d/%d %d:%d:%d');
   if ((res(1) ~= 9999) && (res(2) ~= 99) && (res(3) ~= 99) && ...
         (res(4) ~= 99) && (res(5) ~= 99))

      o_julDay = datenum(a_gregorianDate, 'yyyy/mm/dd HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
   end
end

return

% ------------------------------------------------------------------------------
% Convert a julian 1950 date to a gregorian date.
%
% SYNTAX :
%   [o_gregorianDate] = julian_2_gregorian_dec_argo(a_julDay)
%
% INPUT PARAMETERS :
%   a_julDay : julian 1950 date
%
% OUTPUT PARAMETERS :
%   o_gregorianDate : gregorain date (in 'yyyy/mm/dd HH:MM' or
%                     'yyyy/mm/dd HH:MM:SS' format)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_gregorianDate] = julian_2_gregorian_dec_argo(a_julDay)

% default values
global g_decArgo_dateDef;

% output parameters initialization
o_gregorianDate = repmat('9999/99/99 99:99:99', length(a_julDay), 1);

idOk = find(~isnan(a_julDay) & (a_julDay ~= g_decArgo_dateDef));
[dayNum, dd, mm, yyyy, HH, MI, SS] = format_juld_dec_argo(a_julDay(idOk));

for idDate = 1:length(dayNum)
   if (a_julDay(idOk(idDate)) ~= g_decArgo_dateDef)
      o_gregorianDate(idOk(idDate), :) = sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
         yyyy(idDate), mm(idDate), dd(idDate), HH(idDate), MI(idDate), SS(idDate));
   end
end

return

% ------------------------------------------------------------------------------
% Split of a julian 1950 date in gregorian date parts.
%
% SYNTAX :
%   [o_dayNum, o_day, o_month, o_year, o_hour, o_min, o_sec] = format_juld_dec_argo(a_juld)
%
% INPUT PARAMETERS :
%   a_juld : julian 1950 date
%
% OUTPUT PARAMETERS :
%   o_dayNum : julian 1950 day number
%   o_day    : gregorian day
%   o_month  : gregorian month
%   o_year   : gregorian year
%   o_hour   : gregorian hour
%   o_min    : gregorian minute
%   o_sec    : gregorian second
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dayNum, o_day, o_month, o_year, o_hour, o_min, o_sec] = format_juld_dec_argo(a_juld)

% output parameters initialization
o_dayNum = [];
o_day = [];
o_month = [];
o_year = [];
o_hour = [];
o_min = [];
o_sec = [];

% default values
global g_decArgo_dateDef;
global g_decArgo_janFirst1950InMatlab;


for id = 1:length(a_juld)
   juldStr = num2str(a_juld(id), 11);
   res = sscanf(juldStr, '%5d.%6d');
   o_day(id) = res(1);

   if (o_day(id) ~= fix(g_decArgo_dateDef))
      o_dayNum(id) = fix(a_juld(id));

      dateNum = o_day(id) + g_decArgo_janFirst1950InMatlab;
      ymd = datestr(dateNum, 'yyyy/mm/dd');
      res = sscanf(ymd, '%4d/%2d/%d');
      o_year(id) = res(1);
      o_month(id) = res(2);
      o_day(id) = res(3);

      hms = datestr(a_juld(id), 'HH:MM:SS');
      res = sscanf(hms, '%d:%d:%d');
      o_hour(id) = res(1);
      o_min(id) = res(2);
      o_sec(id) = res(3);
   else
      o_dayNum(id) = 99999;
      o_day(id) = 99;
      o_month(id) = 99;
      o_year(id) = 9999;
      o_hour(id) = 99;
      o_min(id) = 99;
      o_sec(id) = 99;
   end

end

return

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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
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
   a_gebcoFileName = 'C:\Users\jprannou\_RNU\_ressources\GEBCO_2024\GEBCO_2024.nc';
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

try

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

catch MException
   netcdf.close(fCdf);
   rethrow(MException)
end

[longitudes, latitudes] = meshgrid(lonVal, latVal);

o_elev = elev;
o_lon = longitudes;
o_lat = latitudes;

clear lon lat elev longitudes latitudes

return

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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
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

% ------------------------------------------------------------------------------
% Conversion hexa d'une couleur donnée en RGB pour affichage dans GE.
%
% SYNTAX :
%   [o_color] = ge_rgb_2_hex(a_red, a_green, a_blue)
%
% INPUT PARAMETERS :
%   a_red   : valeur du rouge [0..1]
%   a_green : valeur du vert [0..1]
%   a_blue  : valeur du bleu [0..1]
%
% OUTPUT PARAMETERS :
%   o_color : valeur hexa de la couleur souhaitée
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/01/2009 - RNU - creation
% ------------------------------------------------------------------------------
function [o_color] = ge_rgb_2_hex(a_red, a_green, a_blue)

o_color = '000000';

hexR = dec2hex(round(a_red*255));
hexG = dec2hex(round(a_green*255));
hexB = dec2hex(round(a_blue*255));

LR = length(hexR);
LG = length(hexG);
LB = length(hexB);

o_color(7-LR:6) = hexR;
o_color(5-LG:4) = hexG;
o_color(3-LB:2) = hexB;

return

% ------------------------------------------------------------------------------
% Move file.
%
% SYNTAX :
%  [o_ok] = move_file(a_sourceFileName, a_destFileName)
%
% INPUT PARAMETERS :
%   a_sourceFileName : source file path name
%   a_destFileName   : destination file path name
%
% OUTPUT PARAMETERS :
%   o_ok : copy operation report flag (1 if ok, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/10/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = move_file(a_sourceFileName, a_destFileName)

% output parameters initialization
o_ok = 1;


[status, message, messageid] = movefile(a_sourceFileName, a_destFileName);
if (status == 0)
   fprintf('ERROR: Error while moving file %s to file %s (%s)\n', ...
      a_sourceFileName, ...
      a_destFileName, ...
      message);
   o_ok = 0;
end

return
