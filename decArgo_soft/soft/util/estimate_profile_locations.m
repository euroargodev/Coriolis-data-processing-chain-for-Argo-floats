% ------------------------------------------------------------------------------
% Replace linearly interpolated profile locations provided in real time with
% estimated locations based on Kaihe Yamazaki et al. paper
% (https://doi.org/10.1029/2019JC015406).
%
% SYNTAX :
%   estimate_profile_locations(6902899)
%
% INPUT PARAMETERS :
%   varargin : WMO number of float to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/01/2022 - RNU - creation
% ------------------------------------------------------------------------------
function estimate_profile_locations(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START

% default list of floats to process
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\liste_snapshot_202202.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\liste_snapshot_202202_prof_qc_8_9.txt';

% top directory of the NetCDF files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\DATA_UNDER_ICE\IN\';
% DIR_INPUT_NC_FILES = 'D:\202202-ArgoData\coriolis\';

% directory of output files
DIR_OUTPUT_FILES = 'C:\Users\jprannou\_DATA\DATA_UNDER_ICE\OUT6\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% GEBCO bathymetric file
GEBCO_FILE = 'C:\Users\jprannou\_RNU\_ressources\GEBCO_2021\GEBCO_2021.nc';

% max difference (in meters) between sea bottom and float parking drift to start
DIFF_DEPTH_TO_START = 100000;

% tolerance (in meters) used to compare float pressure and GEBCO depth
FLOAT_VS_BATHY_TOLERANCE = 10;

% tolerance (in meters) used to compare float pressure and GEBCO depth when the
% float grounded
FLOAT_VS_BATHY_TOLERANCE_FOR_GRD = 170;

% CONFIGURATION - END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% default values initialization
init_default_values;

% measurement codes initialization
init_measurement_codes;

% specific global variables
global g_estProfLoc_diffDepthToStart;
global g_estProfLoc_floatVsbathyTolerance;
global g_estProfLoc_floatVsbathyToleranceForGrd;

g_estProfLoc_diffDepthToStart = DIFF_DEPTH_TO_START;
g_estProfLoc_floatVsbathyTolerance = FLOAT_VS_BATHY_TOLERANCE;
g_estProfLoc_floatVsbathyToleranceForGrd = FLOAT_VS_BATHY_TOLERANCE_FOR_GRD;


% check inputs
if (nargin == 0)
   if ~(exist(FLOAT_LIST_FILE_NAME, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', FLOAT_LIST_FILE_NAME);
      return
   end
end
if ~(exist(DIR_INPUT_NC_FILES, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s\n', DIR_INPUT_NC_FILES);
   return
end
if ~(exist(DIR_LOG_FILE, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s\n', DIR_LOG_FILE);
   return
end
if ~(exist(GEBCO_FILE, 'file') == 2)
   fprintf('ERROR: File not found: %s\n', GEBCO_FILE);
   return
end

% get floats to process
if (nargin == 0)
   % floats to process come from default list
   fprintf('Floats from list: %s\n', FLOAT_LIST_FILE_NAME);
   floatList = load(FLOAT_LIST_FILE_NAME);
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create and start log file recording
if (nargin == 0)
   [~, name, ~] = fileparts(FLOAT_LIST_FILE_NAME);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

logFile = [DIR_LOG_FILE '/' 'estimate_profile_locations' name '_' currentTime '.log'];
diary(logFile);
tic;

nbFloats = length(floatList);
for idFloat = 1:nbFloats

   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);

   % retrieve float data from NetCDF files
   floatData = get_float_data(floatNum, [DIR_INPUT_NC_FILES '/' floatNumStr '/']);
   if (isempty(floatData))
      fprintf('No profile location to estimate\n');
      continue
   end

   % process float data
   process_float_data(floatNum, floatData, [DIR_OUTPUT_FILES '/' floatNumStr '/'], GEBCO_FILE);

end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Process one float data.
%
% SYNTAX :
%  process_float_data(a_floatNum, a_floatData, a_outputDir, a_gebcoFilePathName)
%
% INPUT PARAMETERS :
%   a_floatNum          : float WMO number
%   a_floatData         : float data
%   a_outputDir         : output directory
%   a_gebcoFilePathName : GEBCO file path name
%
% OUTPUT PARAMETERS :
%   o_ncData : nc data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/01/2022 - RNU - creation
% ------------------------------------------------------------------------------
function process_float_data(a_floatNum, a_floatData, a_outputDir, a_gebcoFilePathName)

% specific global variables
global g_estProfLoc_diffDepthToStart;

% QC flag values (numerical)
global g_decArgo_qcInterpolated;
global g_decArgo_qcMissing;


% define the sets of cycles to process
pos = ones(size(a_floatData.positionQc));
idF = find((a_floatData.positionQc == g_decArgo_qcInterpolated) | (a_floatData.positionQc == g_decArgo_qcMissing));
pos(idF) = 0;
startIdList = find(diff(pos) == -1);
stopIdList = find(diff(pos) == 1) + 1;

if (isempty(startIdList))
   return
end

if (length(startIdList) ~= length(stopIdList))
   if ((a_floatData.positionQc(end) == g_decArgo_qcInterpolated) || (a_floatData.positionQc(end) == g_decArgo_qcMissing))
      fprintf('ERROR: Float %d: inconsistent data (last profile location has QC = 8 or 9) - ignored\n', a_floatNum);
      return
   else
      fprintf('ERROR: Float %d: unknown reason (TO BE CHECKED) - ignored\n', a_floatNum);
      return
   end
end

% fprintf('@@FLOAT@@%d', a_floatNum);
% 
% if (any((a_floatData.positionQc == g_decArgo_qcMissing)))
%    fprintf('@@QC=9 (%d)', length(find(a_floatData.positionQc == g_decArgo_qcMissing)));
% end
% if (any(((a_floatData.positionQc == g_decArgo_qcInterpolated) | ...
%       (a_floatData.positionQc == g_decArgo_qcMissing)) & ...
%       (a_floatData.grounded == 1)))
%    fprintf('@@GRD (%d)', length(find(((a_floatData.positionQc == g_decArgo_qcInterpolated) | ...
%       (a_floatData.positionQc == g_decArgo_qcMissing)) & ...
%       (a_floatData.grounded == 1))));
% end
% 
% fprintf('\n');
% 
% return

% create output directory
if ~(exist(a_outputDir, 'dir') == 7)
   mkdir(a_outputDir);
end

% interpolate anew profile locations (because some of them are missing
% (positionQc = g_decArgo_qcMissing) or are badly interpolated (5906033_074-084
% and 084-101))
paramJuld = get_netcdf_param_attributes('JULD');
idFv = find(a_floatData.juldLocation == paramJuld.fillValue);
a_floatData.juldLocation(idFv) = a_floatData.juld(idFv);

for idS = 1:length(startIdList)
   idStart = startIdList(idS);
   idStop = stopIdList(idS);

   % interpolate the locations
   [lonInter, latInter] = interpolate_between_2_locations(...
      a_floatData.juldLocation(idStart), a_floatData.longitude(idStart), a_floatData.latitude(idStart), ...
      a_floatData.juldLocation(idStop), a_floatData.longitude(idStop), a_floatData.latitude(idStop), ...
      a_floatData.juldLocation(idStart+1:idStop-1)');
   a_floatData.longitude(idStart+1:idStop-1) = lonInter';
   a_floatData.latitude(idStart+1:idStop-1) = latInter';
   a_floatData.positionQc(idStart+1:idStop-1) = g_decArgo_qcInterpolated;
end

% compute speeds
speed = nan(size(a_floatData.juldLocation));
for idC = 2:length(a_floatData.juldLocation)
   speed(idC) = ...
      100*distance_lpo([a_floatData.latitude(idC-1) a_floatData.latitude(idC)], ...
      [a_floatData.longitude(idC-1) a_floatData.longitude(idC)]) / ...
      ((a_floatData.juldLocation(idC)-a_floatData.juldLocation(idC-1))*86400);
end
a_floatData.speed = speed;

% retrieve GEBCO depth
a_floatData.gebcoDepth = get_gebco_depth(a_floatData.longitude, a_floatData.latitude, a_gebcoFilePathName);

% process the sets of cycles
for idS = 1:length(startIdList)
   idStart = startIdList(idS);
   idStop = stopIdList(idS);

   fprintf('Processing: %d %03d-%03d\n', ...
      a_floatNum, ...
      a_floatData.cycleNumber(idStart), ...
      a_floatData.cycleNumber(idStop));

   % be sure RPP is not to far from bottom depth
   reducedFlag = 0;
   if (idStart > 1)
      for idC = idStart:idStop
         if (~isnan(a_floatData.rpp(idC)) ...
               && (a_floatData.gebcoDepth(idC) - a_floatData.rpp(idC) < g_estProfLoc_diffDepthToStart))
            break
         end
         idStart = idC;
         reducedFlag = 1;
      end
   end
   for idC = idStop:-1:idStart
      if (~isnan(a_floatData.rpp(idC)) ...
            && (a_floatData.gebcoDepth(idC) - a_floatData.rpp(idC) < g_estProfLoc_diffDepthToStart))
         break
      end
      idStop = idC;
      reducedFlag = 1;
   end
   if (idStart == idStop)
      fprintf('Drifting depth too far from bathymetry\n');
      continue
   elseif (reducedFlag == 1)
      fprintf('Reduced to: %d %03d-%03d\n', ...
         a_floatNum, ...
         a_floatData.cycleNumber(idStart), ...
         a_floatData.cycleNumber(idStop));
   end

   % process the set of cycles
   a_floatData = process_set_of_cycles(a_floatNum, a_floatData, idS, idStart, idStop, a_outputDir, a_gebcoFilePathName);

end

% write CSV report
print_csv_report(a_floatNum, a_floatData, a_outputDir);

return

% ------------------------------------------------------------------------------
% Process one set of cycles.
%
% SYNTAX :
%  [o_floatData] = process_set_of_cycles(a_floatNum, a_floatData, ...
%    a_setNum, a_idStart, a_idStop, a_outputDir, a_gebcoFilePathName)
%
% INPUT PARAMETERS :
%   a_floatNum          : float WMO number
%   a_floatData         : input float data
%   a_setNum            : number of the set of cycles
%   a_idStart           : first Id of the set of cycles
%   a_idStop            : last Id of the set of cycles
%   a_outputDir         : output directory
%   a_gebcoFilePathName : GEBCO file path name
%
% OUTPUT PARAMETERS :
%   o_ncData : nc data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/01/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatData] = process_set_of_cycles(a_floatNum, a_floatData, ...
   a_setNum, a_idStart, a_idStop, a_outputDir, a_gebcoFilePathName)

% output parameters initialization
o_floatData = a_floatData;

% specific global variables
global g_estProfLoc_floatVsbathyTolerance;
global g_estProfLoc_floatVsbathyToleranceForGrd;

RANGE_START = 20;
RANGE_STOP = 100;


% consider only data of the set
cycleNumber = a_floatData.cycleNumber(a_idStart:a_idStop);
juld = a_floatData.juld(a_idStart:a_idStop);
juldLocation = a_floatData.juldLocation(a_idStart:a_idStop);
latitude = a_floatData.latitude(a_idStart:a_idStop);
longitude = a_floatData.longitude(a_idStart:a_idStop);
profPresMax = a_floatData.profPresMax(a_idStart:a_idStop);
grounded = a_floatData.grounded(a_idStart:a_idStop);
groundedPres = a_floatData.groundedPres(a_idStart:a_idStop);
gebcoDepth = a_floatData.gebcoDepth(a_idStart:a_idStop);

% define depth constraint
depthConstraint = interp1q([juld(1); juld(end)], [gebcoDepth(1); gebcoDepth(end)], juld')';
lastId = 1;
for idC = 2:length(cycleNumber)-1
   if (~isnan(profPresMax(idC)) && ((profPresMax(idC) > depthConstraint(idC)) || (grounded(idC) == 1)))
      depthConstraint(idC) = profPresMax(idC);
      depthConstraint(lastId:idC) = interp1q([juld(lastId); juld(idC)], [depthConstraint(lastId); depthConstraint(idC)], juld(lastId:idC)')';
      lastId = idC;
   end
end
if (lastId ~= 1)
   depthConstraint(lastId:end) = interp1q([juld(lastId); juld(end)], [depthConstraint(lastId); depthConstraint(end)], juld(lastId:end)')';
end

o_floatData.setNumber(a_idStart:a_idStop) = a_setNum;
o_floatData.depthConstraint(a_idStart:a_idStop) = depthConstraint;

% create the figure
close(findobj('Name', 'Estimate profile locations'));
warning off;

screenSize = get(0, 'ScreenSize');
figure('Name', 'Estimate profile locations', ...
   'Position', [1 screenSize(4)*(1/3) screenSize(3) screenSize(4)*(2/3)-90], ...
   'Color', 'w');

longitudeOri = longitude;
latitudeOri = latitude;

if (any(abs(diff(longitude)) > 180))
   id = find(longitude < 0);
   longitude(id) = longitude(id) + 360;
end

% angle of the normal to linear trajectory
[x, y] = latLon_2_xy(longitude([1 end]), latitude([1 end]));
x1 = x(1);
x2 = x(end);
y1 = y(1);
y2 = y(end);
den = x2 - x1 + eps;
tetaRad = atan((y2-y1)/den) + pi*(x2<x1) - pi/2;
tetaDeg = tetaRad*180/pi;
if (tetaDeg < 0)
   tetaDeg = tetaDeg + 360;
end
fprintf('Teta: %.1f deg\n', tetaDeg);

% result arrays for forward and backward tries
resultF = nan(length(longitude), 2);
resultB = nan(length(longitude), 2);
resultF(1, 1) = longitude(1);
resultF(1, 2) = latitude(1);
resultB(1, 1) = longitude(end);
resultB(1, 2) = latitude(end);

% 2 loops: one for foreward, one for backward
for idLoop = 1:2

   if (idLoop == 2)
      longitude = fliplr(longitude);
      latitude = fliplr(latitude);
      depthConstraint = fliplr(depthConstraint);
   end

   % increase range until the path is found
   for range = RANGE_START:5:RANGE_STOP

      if (idLoop == 1)
         fprintf('Trying forward with RANGE = %d', range);
      else
         fprintf('Trying backward with RANGE = %d', range);
      end

      % create the map of locations to check
      nbCol = length(longitude);
      nbLig = (nbCol-1)*2*range+1;
      depthTabVal = nan(nbLig, nbCol);
      diffTabVal = nan(nbLig, nbCol);
      devTabFlag = ones(nbLig, nbCol);
      lonTabAll = nan(nbLig, nbCol);
      latTabAll = nan(nbLig, nbCol);
      for idC = 1:length(longitude)-1

         % create the set of locations on the search segment
         [lonTab, latTab] = get_loc_on_search_range(longitude([idC idC+1]), latitude([idC idC+1]), idC*range, tetaDeg);

         % retrieve location depth
         depthVal = get_gebco_depth(lonTab, latTab, a_gebcoFilePathName);

         depthFlag = ones(size(depthVal));
         diffVal = depthVal - depthConstraint(idC+1);
         if (grounded(idC+1) == 0)
            idOk = find(diffVal >= -g_estProfLoc_floatVsbathyTolerance);
         else
            idOk = find((diffVal >= -g_estProfLoc_floatVsbathyToleranceForGrd) & ...
               (diffVal <= g_estProfLoc_floatVsbathyToleranceForGrd));
         end
         depthFlag(idOk) = 0;

         depthTabVal((nbCol-(idC+1))*range+(1:length(depthVal)), idC+1) = depthVal;
         diffTabVal((nbCol-(idC+1))*range+(1:length(depthVal)), idC+1) = diffVal;
         devTabFlag((nbCol-(idC+1))*range+(1:length(depthVal)), idC+1) = depthFlag;
         lonTabAll((nbCol-(idC+1))*range+(1:length(depthVal)), idC+1) = lonTab;
         latTabAll((nbCol-(idC+1))*range+(1:length(depthVal)), idC+1) = latTab;
      end

      % try to find a path
      result = nan(length(longitude), 1);
      curId = (nbCol-1)*range + 1;
      idC = 1;
      done = 1;
      while (idC < length(longitude))
         searchId = curId-range:curId+range;
         idToCheck = find(devTabFlag(searchId, idC+1) == 0);
         if (~isempty(idToCheck))
            idToCheck = searchId(idToCheck);
            [~, minId] = min(abs(diffTabVal(idToCheck, idC+1)));
            curId = idToCheck(minId);
            devTabFlag((devTabFlag(:, idC+1) == 2), idC+1) = 3;
            devTabFlag(curId, idC+1) = 2;
            result(idC+1) = curId;
            idC = idC + 1;
         else
            if (idC <= 2)
               done = 0;
               break
            end
            idC = idC - 1;
            curId = result(idC);
         end
      end

      if (idLoop == 1)
         dir = 'Foreward';
         dir2 = '1_foreward';
      else
         dir = 'Backward';
         dir2 = '2_backward';
      end
      if (done == 1)
         koOk = 'OK';
      else
         koOk = 'KO';
      end
      fprintf(' - %s\n', koOk);
      label = sprintf('Float: %d - Cycles: %03d to %03d - %s - Range %d km - %s', ...
         a_floatNum, ...
         cycleNumber(1), ...
         cycleNumber(end), ...
         dir, ...
         range, ...
         koOk);
      pngFileName = sprintf('%d_%03d-%03d_%s_range_%d_%s.png', ...
         a_floatNum, ...
         cycleNumber(1), ...
         cycleNumber(end), ...
         dir2, ...
         range, ...
         koOk);

      % display result of the try

      % arrays to store legend information
      legendPlots = [];
      legendLabels = [];

      idDone = find(devTabFlag == 2);
      [lonMin, lonMax, latMin, latMax] = compute_geo_extrema( ...
         [], [longitudeOri lonTabAll(idDone)'], [latitudeOri latTabAll(idDone)'], 0);
      [elevC, lonC , latC] = get_gebco_elev_zone(lonMin, lonMax, latMin, latMax, '');

      cla;

      m_proj('mercator', 'latitudes', [latMin latMax], 'longitudes', [lonMin lonMax]);
      m_grid('box', 'fancy', 'tickdir', 'out', 'linestyle', 'none');
      hold on;

      isobath = -unique(round(depthConstraint));
      isobath = min(isobath):100:max(isobath);
      if (length(isobath) == 1)
         isobath = [isobath isobath];
      end
      [contourMatrix, contourHdl] = m_contour(lonC, latC, elevC, isobath, 'c');
      if (~isempty(contourMatrix))
         legendPlots = [legendPlots contourHdl];
         legendLabels = [legendLabels {'depth constraint isobath'}];
      end

      m_line([longitude(1) longitude(end)], [latitude(1) latitude(end)], 'linestyle', '-', 'visible', 'on');

      title(label, 'FontSize', 14);

      plotHdl = m_plot(longitude(1), latitude(1), 'o', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r', 'Markersize', 4);
      if (~isempty(plotHdl))
         legendPlots = [legendPlots plotHdl];
         legendLabels = [legendLabels {'starting location'}];
      end

      for idC = 1:length(longitude)-1
         lonT = lonTabAll(:, idC+1);
         latT = latTabAll(:, idC+1);

         lonL = lonT(~isnan(lonT));
         latL = latT(~isnan(latT));
         m_line([lonL(1) lonL(end)], [latL(1) latL(end)], 'linestyle', '-', 'visible', 'on');

         idNotChecked = find(devTabFlag(:, idC+1) == 0);
         plotHdl = m_plot(lonT(idNotChecked), latT(idNotChecked), 'h', 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'g', 'Markersize',  4);
         if (~isempty(plotHdl))
            if (~any(strcmp(legendLabels, 'eligible locations')))
               legendPlots = [legendPlots plotHdl];
               legendLabels = [legendLabels {'eligible locations'}];
            end
         end

         idFailed = find(devTabFlag(:, idC+1) == 3);
         plotHdl = m_plot(lonT(idFailed), latT(idFailed), 'h', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b', 'Markersize',  4);
         if (~isempty(plotHdl))
            if (~any(strcmp(legendLabels, 'failed locations')))
               legendPlots = [legendPlots plotHdl];
               legendLabels = [legendLabels {'failed locations'}];
            end
         end

         idDone = find(devTabFlag(:, idC+1) == 2);
         plotHdl = m_plot(lonT(idDone), latT(idDone), 'h', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r', 'Markersize',  4);
         if (~isempty(plotHdl))
            if (~any(strcmp(legendLabels, 'final locations')))
               legendPlots = [legendPlots plotHdl];
               legendLabels = [legendLabels {'final locations'}];
            end
         end

         if (done)
            if (idLoop == 1)
               resultF(idC+1, 1) = lonT(idDone);
               resultF(idC+1, 2) = latT(idDone);
            else
               resultB(idC+1, 1) = lonT(idDone);
               resultB(idC+1, 2) = latT(idDone);
            end
         end
      end

      % plot legend
      legend(legendPlots, legendLabels, 'Location', 'NorthEastOutside', 'Tag', 'Legend');

      if (done || (range == RANGE_STOP))
         print('-dpng', [a_outputDir '/' pngFileName]);
      end

      if (done)
         break
      end
   end
end

% plot final trajectory
if (done)

   label = sprintf('Float: %d - Cycles: %03d to %03d - Final trajectory\n', ...
      a_floatNum, ...
      cycleNumber(1), ...
      cycleNumber(end));

   pngFileName = sprintf('%d_%03d-%03d_3_final.png', ...
      a_floatNum, ...
      cycleNumber(1), ...
      cycleNumber(end));

   % arrays to store legend information
   legendPlots = [];
   legendLabels = [];

   [lonMin, lonMax, latMin, latMax] = compute_geo_extrema( ...
      [], [longitudeOri resultF(:, 1)' resultB(:, 1)'], [latitudeOri resultF(:, 2)' resultB(:, 2)'], 0);
   [elevC, lonC , latC] = get_gebco_elev_zone(lonMin, lonMax, latMin, latMax, '');

   cla;

   m_proj('mercator', 'latitudes', [latMin latMax], 'longitudes', [lonMin lonMax]);
   m_grid('box', 'fancy', 'tickdir', 'out', 'linestyle', 'none');
   hold on;

   isobath = -unique(round(depthConstraint));
   isobath = min(isobath):100:max(isobath);
   if (length(isobath) == 1)
      isobath = [isobath isobath];
   end
   m_contour(lonC, latC, elevC, isobath, 'c');

   m_line([longitude(1) longitude(end)], [latitude(1) latitude(end)], 'linestyle', '-', 'visible', 'on');

   title(label, 'FontSize', 14);

   for idC = 1:length(longitude)-1
      plotHdl = m_plot(resultF(idC+1, 1), resultF(idC+1, 2), 'o', 'Markersize', 3, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r');
      if (~isempty(plotHdl))
         if (~any(strcmp(legendLabels, 'foreward locations')))
            legendPlots = [legendPlots plotHdl];
            legendLabels = [legendLabels {'foreward locations'}];
         end
      end

      plotHdl = m_plot(resultB(idC+1, 1), resultB(idC+1, 2), 'o', 'Markersize',  6, 'MarkerEdgeColor', 'r');
      if (~isempty(plotHdl))
         if (~any(strcmp(legendLabels, 'backward locations')))
            legendPlots = [legendPlots plotHdl];
            legendLabels = [legendLabels {'backward locations'}];
         end
      end
   end

   trajLon = nan(length(longitude), 1);
   trajLat = nan(length(longitude), 1);
   nb1 = ceil(length(longitude)/2);
   nb2 = nb1;
   if (mod(length(longitude), 2) ~= 0)
      nb2 = nb2 - 1;
   end
   trajLon(1:nb1) = resultF(1:nb1, 1);
   trajLat(1:nb1) = resultF(1:nb1, 2);
   trajLon(nb1+1:end) = flipud(resultB(1:nb2, 1));
   trajLat(nb1+1:end) = flipud(resultB(1:nb2, 2));
   lineHdl = m_line(trajLon, trajLat, 'linestyle', '-', 'color', 'r', 'visible', 'on');
   if (~isempty(lineHdl))
      legendPlots = [legendPlots lineHdl];
      legendLabels = [legendLabels {'merged trajectory'}];
   end

   % plot legend
   legend(legendPlots, legendLabels, 'Location', 'NorthEastOutside', 'Tag', 'Legend');

   print('-dpng', [a_outputDir '/' pngFileName]);
end

% store output parameters

if (done)

   speed = nan(size(juld));
   for idC = 2:length(juld)
      speed(idC) = ...
         100*distance_lpo([trajLat(idC-1) trajLat(idC)], [trajLon(idC-1) trajLon(idC)]) / ...
         ((juld(idC)-juld(idC-1))*86400);
   end

   forwardLat = resultF(:, 2);
   forwardLon = resultF(:, 1);
   if (any(forwardLon > 180))
      id = find(forwardLon > 180);
      forwardLon(id) = forwardLon(id) - 360;
   end
   backwardLat = resultB(:, 2);
   backwardLon = resultB(:, 1);
   backwardLat = flipud(backwardLat);
   backwardLon = flipud(backwardLon);
   if (any(backwardLon > 180))
      id = find(backwardLon > 180);
      backwardLon(id) = backwardLon(id) - 360;
   end
   if (any(trajLon > 180))
      id = find(trajLon > 180);
      trajLon(id) = trajLon(id) - 360;
   end

   o_floatData.forwardLat(a_idStart:a_idStop) = forwardLat;
   o_floatData.forwardLon(a_idStart:a_idStop) = forwardLon;
   o_floatData.forwardGebcoDepth(a_idStart:a_idStop) = get_gebco_depth(forwardLon, forwardLat, a_gebcoFilePathName);
   o_floatData.backwardLat(a_idStart:a_idStop) = backwardLat;
   o_floatData.backwardLon(a_idStart:a_idStop) = backwardLon;
   o_floatData.backwardGebcoDepth(a_idStart:a_idStop) = get_gebco_depth(backwardLon, backwardLat, a_gebcoFilePathName);
   o_floatData.trajLat(a_idStart:a_idStop) = trajLat;
   o_floatData.trajLon(a_idStart:a_idStop) = trajLon;
   o_floatData.speedEst(a_idStart:a_idStop) = speed;
end

return

% ------------------------------------------------------------------------------
% Retrieve relevent data from float NetCDf files.
%
% SYNTAX :
%  [o_ncData] = get_float_data(a_floatNum, a_ncFileDir)
%
% INPUT PARAMETERS :
%   a_floatNum  : float WMO number
%   a_ncFileDir : float nc files directory
%
% OUTPUT PARAMETERS :
%   o_ncData : nc data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/01/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatData] = get_float_data(a_floatNum, a_ncFileDir)

% output parameters initialization
o_floatData = [];

% global measurement codes
global g_MC_Grounded;

% QC flag values (char)
global g_decArgo_qcStrGood;
global g_decArgo_qcStrProbablyGood;

% QC flag values (numerical)
global g_decArgo_qcInterpolated;
global g_decArgo_qcMissing;


paramJuld = get_netcdf_param_attributes('JULD');
paramPres = get_netcdf_param_attributes('PRES');
paramLat = get_netcdf_param_attributes('LATITUDE');
paramLon = get_netcdf_param_attributes('LONGITUDE');
floatData = get_data_init_struct;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% retrieve information from mono PROF files

profDirName = [a_ncFileDir '/profiles/'];

floatFiles = dir([profDirName '/' sprintf('*%d_*.nc', a_floatNum)]);
for idFile = 1:length(floatFiles)
   floatFileName = floatFiles(idFile).name;
   if (floatFileName(1) == 'B')
      continue
   end
   floatFilePathName = [profDirName '/' floatFileName];

   % retrieve information from file
   wantedVars = [ ...
      {'FORMAT_VERSION'} ...
      {'CYCLE_NUMBER'} ...
      {'DIRECTION'} ...
      {'DATA_MODE'} ...
      {'JULD'} ...
      {'JULD_QC'} ...
      {'JULD_LOCATION'} ...
      {'LATITUDE'} ...
      {'LONGITUDE'} ...
      {'POSITION_QC'} ...
      {'PRES'} ...
      {'PRES_ADJUSTED'} ...
      {'CONFIG_MISSION_NUMBER'} ...
      ];
   ncData = get_data_from_nc_file(floatFilePathName, wantedVars);
   formatVersion = get_data_from_name('FORMAT_VERSION', ncData)';
   formatVersion = strtrim(formatVersion);
   cycleNumber = get_data_from_name('CYCLE_NUMBER', ncData);
   direction = get_data_from_name('DIRECTION', ncData);
   dataMode = get_data_from_name('DATA_MODE', ncData);
   juld = get_data_from_name('JULD', ncData);
   juldQc = get_data_from_name('JULD_QC', ncData);
   juldLocation = get_data_from_name('JULD_LOCATION', ncData);
   latitude = get_data_from_name('LATITUDE', ncData);
   longitude = get_data_from_name('LONGITUDE', ncData);
   positionQc = get_data_from_name('POSITION_QC', ncData);
   pres = get_data_from_name('PRES', ncData);
   presAdjusted = get_data_from_name('PRES_ADJUSTED', ncData);
   configMissionNumber = get_data_from_name('CONFIG_MISSION_NUMBER', ncData);

   % check the file format version
   if (~strcmp(formatVersion, '3.1'))
      fprintf('ERROR: Input mono prof file (%s) is expected to be of 3.1 format version (but FORMAT_VERSION = %s) - ignored\n', ...
         floatFileName, formatVersion);
      continue
   end

   % check data consistency
   if ((length(unique(cycleNumber)) > 1) || (length(unique(direction)) > 1) || ...
         (length(unique(juld)) > 1) || (length(unique(juldQc)) > 1) || ...
         (length(unique(juldLocation)) > 1) || (length(unique(latitude)) > 1) || ...
         (length(unique(longitude)) > 1) || (length(unique(positionQc)) > 1) || ...
         (length(unique(configMissionNumber)) > 1))

      fprintf('ERROR: Inconsistent data in file: %s - ignored\n', floatFileName);
      continue
   end

   if (all(juld == paramJuld.fillValue))
      fprintf('WARNING: Not dated profile in file: %s - ignored\n', floatFileName);
      continue
   end

   floatData.cycleNumber = [floatData.cycleNumber unique(cycleNumber)];
   if (unique(direction) == 'D')
      direct = 1;
   else
      direct = 2;
   end
   floatData.direction = [floatData.direction direct];
   floatData.juld = [floatData.juld unique(juld)];
   floatData.juldQc = [floatData.juldQc str2double(unique(juldQc))];
   floatData.juldLocation = [floatData.juldLocation unique(juldLocation)];
   floatData.latitude = [floatData.latitude unique(latitude)];
   floatData.longitude = [floatData.longitude unique(longitude)];
   floatData.positionQc = [floatData.positionQc str2double(unique(positionQc))];
   floatData.configMissionNumber = [floatData.configMissionNumber unique(configMissionNumber)];

   presMax = -1;
   for idProf = 1:length(dataMode)
      if (dataMode(idProf) == 'R')
         presVal = pres(:, idProf);
      else
         presVal = presAdjusted(:, idProf);
      end
      presVal(presVal == paramPres.fillValue) = [];
      if (max(presVal) > presMax)
         presMax = max(presVal);
      end
   end
   floatData.profPresMax = [floatData.profPresMax presMax];
end

if ~(any((floatData.positionQc == g_decArgo_qcInterpolated) | (floatData.positionQc == g_decArgo_qcMissing)))
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% retrieve information from META file

floatFiles = dir([a_ncFileDir '/' sprintf('%d_meta.nc', a_floatNum)]);
if (isempty(floatFiles))
   fprintf('ERROR: Meta-data file not found - ignored\n');
   return
end

floatFilePathName = [a_ncFileDir '/' floatFiles(1).name];

% retrieve information from file
wantedVars = [ ...
   {'FORMAT_VERSION'} ...
   {'LAUNCH_CONFIG_PARAMETER_NAME'} ...
   {'LAUNCH_CONFIG_PARAMETER_VALUE'} ...
   {'CONFIG_PARAMETER_NAME'} ...
   {'CONFIG_PARAMETER_VALUE'} ...
   {'CONFIG_MISSION_NUMBER'} ...
   ];
ncData = get_data_from_nc_file(floatFilePathName, wantedVars);
formatVersion = get_data_from_name('FORMAT_VERSION', ncData)';
formatVersion = strtrim(formatVersion);
launchConfigParamName = get_data_from_name('LAUNCH_CONFIG_PARAMETER_NAME', ncData);
launchConfigValue = get_data_from_name('LAUNCH_CONFIG_PARAMETER_VALUE', ncData);
configParamName = get_data_from_name('CONFIG_PARAMETER_NAME', ncData);
configValue = get_data_from_name('CONFIG_PARAMETER_VALUE', ncData);
configMissionNumberMeta = get_data_from_name('CONFIG_MISSION_NUMBER', ncData);

% check the file format version
if (~strcmp(formatVersion, '3.1'))
   fprintf('ERROR: Input meta file (%s) is expected to be of 3.1 format version (but FORMAT_VERSION = %s) - ignored\n', ...
      floatFiles(1).name, formatVersion);
   return
end

% retrieve the needed configuration parameters
[~, nParam] = size(launchConfigParamName);
launchConfigName = [];
for idParam = 1:nParam
   launchConfigName{end+1} = deblank(launchConfigParamName(:, idParam)');
end
[~, nParam] = size(configParamName);
configName = [];
for idParam = 1:nParam
   configName{end+1} = deblank(configParamName(:, idParam)');
end

% process retrieved data
parkP = -1;
idF = find(strcmp('CONFIG_ParkPressure_dbar', launchConfigName(:)) == 1, 1);
if (~isempty(idF) && (launchConfigValue(idF) ~= paramPres.fillValue))
   parkP = launchConfigValue(idF);
end
parkPres = ones(size(configMissionNumberMeta))*parkP;
idF = find(strcmp('CONFIG_ParkPressure_dbar', configName(:)) == 1, 1);
if (~isempty(idF))
   parkPres = configValue(idF, :);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% retrieve information from TRAJ file

floatFileName = '';
floatFiles = dir([a_ncFileDir '/' sprintf('%d_*traj.nc', a_floatNum)]);
for idFile = 1:length(floatFiles)
   if (any(floatFiles(idFile).name == 'B'))
      continue
   end
   floatFileName = floatFiles(idFile).name;
end

if (isempty(floatFileName))
   fprintf('ERROR: Trajectory file not found - ignored\n');
   return
end

floatFilePathName = [a_ncFileDir '/' floatFileName];

% retrieve information from file
wantedVars = [ ...
   {'FORMAT_VERSION'} ...
   {'TRAJECTORY_PARAMETERS'} ...
   {'JULD'} ...
   {'JULD_QC'} ...
   {'LATITUDE'} ...
   {'LONGITUDE'} ...
   {'POSITION_ACCURACY'} ...
   {'POSITION_QC'} ...
   {'CYCLE_NUMBER'} ...
   {'MEASUREMENT_CODE'} ...
   {'PRES'} ...
   {'PRES_ADJUSTED'} ...
   {'TRAJECTORY_PARAMETER_DATA_MODE'} ...
   {'GROUNDED'} ...
   {'REPRESENTATIVE_PARK_PRESSURE'} ...
   {'CONFIG_MISSION_NUMBER'} ...
   {'CYCLE_NUMBER_INDEX'}, ...
   {'DATA_MODE'} ...
   ];
ncData = get_data_from_nc_file(floatFilePathName, wantedVars);
formatVersion = get_data_from_name('FORMAT_VERSION', ncData)';
formatVersion = strtrim(formatVersion);
trajParam = get_data_from_name('TRAJECTORY_PARAMETERS', ncData);
juld = get_data_from_name('JULD', ncData);
juldQc = get_data_from_name('JULD_QC', ncData);
latitude = get_data_from_name('LATITUDE', ncData);
longitude = get_data_from_name('LONGITUDE', ncData);
positionAccuracy = get_data_from_name('POSITION_ACCURACY', ncData);
positionQc = get_data_from_name('POSITION_QC', ncData);
cycleNumber = get_data_from_name('CYCLE_NUMBER', ncData);
measCode = get_data_from_name('MEASUREMENT_CODE', ncData);
pres = get_data_from_name('PRES', ncData);
presAdjusted = get_data_from_name('PRES_ADJUSTED', ncData);
trajParamDataMode = get_data_from_name('TRAJECTORY_PARAMETER_DATA_MODE', ncData);
grounded = get_data_from_name('GROUNDED', ncData);
rpp = get_data_from_name('REPRESENTATIVE_PARK_PRESSURE', ncData);
configMissionNumber = get_data_from_name('CONFIG_MISSION_NUMBER', ncData);
cycleNumberIndex = get_data_from_name('CYCLE_NUMBER_INDEX', ncData);
dataMode = get_data_from_name('DATA_MODE', ncData);

% check the file format version
if (~ismember(formatVersion, [{'3.1'} {'3.2'}]))
   fprintf('ERROR: Input trajectory file (%s) is expected to be of 3.1 format version (but FORMAT_VERSION = %s)\n', ...
      floatFileName, formatVersion);
   return
end

% add cycle #0 location if any or launch location otherwise
idLoc0 = find((cycleNumber == 0) & ...
   (latitude ~= paramLat.fillValue) & ...
   (longitude ~= paramLon.fillValue) & ...
   (positionAccuracy ~= 'I') & ...
   ((positionQc == g_decArgo_qcStrGood) | (positionQc == g_decArgo_qcStrProbablyGood)));
if (~isempty(idLoc0))
   [~, idMax] = max(juld(idLoc0));
   juld0 = juld(idLoc0(idMax));
   juldQc0 = juldQc(idLoc0(idMax));
   longitude0 = longitude(idLoc0(idMax));
   latitude0 = latitude(idLoc0(idMax));
   positionQc0 = positionQc(idLoc0(idMax));
else
   idLoc0 = find(cycleNumber == -1);
   juld0 = juld(idLoc0);
   juldQc0 = juldQc(idLoc0);
   longitude0 = longitude(idLoc0);
   latitude0 = latitude(idLoc0);
   positionQc0 = positionQc(idLoc0);
end

floatData.cycleNumber = [0 floatData.cycleNumber];
floatData.direction = [0 floatData.direction];
floatData.juld = [juld0 floatData.juld];
floatData.juldQc = [str2double(juldQc0) floatData.juldQc];
floatData.juldLocation = [juld0 floatData.juldLocation];
floatData.latitude = [latitude0 floatData.latitude];
floatData.longitude = [longitude0 floatData.longitude];
floatData.positionQc = [str2double(positionQc0) floatData.positionQc];
floatData.configMissionNumber = [-1 floatData.configMissionNumber];
floatData.profPresMax = [0 floatData.profPresMax];

floatData.speed = nan(size(floatData.cycleNumber));
floatData.rpp = nan(size(floatData.cycleNumber));
floatData.grounded = zeros(size(floatData.cycleNumber));
floatData.groundedPres = nan(size(floatData.cycleNumber));
floatData.gebcoDepth = nan(size(floatData.cycleNumber));
floatData.setNumber = nan(size(floatData.cycleNumber));
floatData.depthConstraint = nan(size(floatData.cycleNumber));
floatData.forwardLat = nan(size(floatData.cycleNumber));
floatData.forwardLon = nan(size(floatData.cycleNumber));
floatData.forwardGebcoDepth = nan(size(floatData.cycleNumber));
floatData.backwardLat = nan(size(floatData.cycleNumber));
floatData.backwardLon = nan(size(floatData.cycleNumber));
floatData.backwardGebcoDepth = nan(size(floatData.cycleNumber));
floatData.trajLat = nan(size(floatData.cycleNumber));
floatData.trajLon = nan(size(floatData.cycleNumber));
floatData.speedEst = nan(size(floatData.cycleNumber));

if (strcmp(formatVersion, '3.2') && any(grounded == 'Y'))
   for idP = 1:size(trajParam, 2)
      paramName = strtrim(trajParam(:, idP)');
      if (strcmp(paramName, 'PRES'))
         presParamId = idP;
         break
      end
   end
end

cycleNumberList = unique(floatData.cycleNumber);
for idCy = 1:length(cycleNumberList)
   cyNum = cycleNumberList(idCy);
   if (cyNum == 0)
      continue
   end
   idForCy = find(floatData.cycleNumber == cyNum);

   rppVal = rpp(cycleNumberIndex == cyNum);
   if (isempty(rppVal))
      floatData.rpp(idForCy) = nan;
   elseif (rppVal ~= paramPres.fillValue)
      floatData.rpp(idForCy) = rppVal;
   else
      rppVal = parkPres(configMissionNumberMeta == configMissionNumber(cycleNumberIndex == cyNum));
      floatData.rpp(idForCy) = rppVal;
   end

   groundedFlag = grounded(cycleNumberIndex == cyNum);
   if (groundedFlag == 'Y')
      floatData.grounded(idForCy) = 1;

      idGrd = find((cycleNumber == cyNum) & (measCode == g_MC_Grounded));
      if (~isempty(idGrd))
         if (strcmp(formatVersion, '3.1'))
            if (dataMode(cycleNumberIndex == cyNum) == 'R')
               presVal = pres;
            else
               presVal = presAdjusted;
            end
            presGrd = presVal(idGrd);
         elseif (strcmp(formatVersion, '3.2'))
            presGrd = [];
            for idG = 1:length(idGrd)
               if (trajParamDataMode(presParamId, idGrd(idG)) == 'R')
                  presGrd = [presGrd pres(idGrd(idG))];
               else
                  presGrd = [presGrd presAdjusted(idGrd(idG))];
               end
            end
         end
         presGrd(presGrd == paramPres.fillValue) = [];
         if (~isempty(presGrd))
            floatData.groundedPres(idForCy) = min(presGrd);
         end
      end
   end
end

% specific
if (ismember(a_floatNum, [6901880]))
   switch a_floatNum
      case 6901880
         floatData.profPresMax(floatData.cycleNumber == 14) = nan;
         floatData.rpp(floatData.cycleNumber == 14) = nan;
         floatData.grounded(floatData.cycleNumber == 14) = nan;
         floatData.groundedPres(floatData.cycleNumber == 14) = nan;
   end
end

% sort the data in chronological order
[~, idSort] = sort(floatData.juld);
floatData.cycleNumber = floatData.cycleNumber(idSort);
floatData.direction = floatData.direction(idSort);
floatData.juld = floatData.juld(idSort);
floatData.juldQc = floatData.juldQc(idSort);
floatData.juldLocation = floatData.juldLocation(idSort);
floatData.latitude = floatData.latitude(idSort);
floatData.longitude = floatData.longitude(idSort);
floatData.positionQc = floatData.positionQc(idSort);
floatData.speed = floatData.speed(idSort);
floatData.configMissionNumber = floatData.configMissionNumber(idSort);
floatData.profPresMax = floatData.profPresMax(idSort);

floatData.rpp = floatData.rpp(idSort);
floatData.grounded = floatData.grounded(idSort);
floatData.groundedPres = floatData.groundedPres(idSort);
floatData.gebcoDepth = floatData.gebcoDepth(idSort);
floatData.setNumber = floatData.setNumber(idSort);
floatData.depthConstraint = floatData.depthConstraint(idSort);
floatData.forwardLat = floatData.forwardLat(idSort);
floatData.forwardLon = floatData.forwardLon(idSort);
floatData.forwardGebcoDepth = floatData.forwardGebcoDepth(idSort);
floatData.backwardLat = floatData.backwardLat(idSort);
floatData.backwardLon = floatData.backwardLon(idSort);
floatData.backwardGebcoDepth = floatData.backwardGebcoDepth(idSort);
floatData.trajLat = floatData.trajLat(idSort);
floatData.trajLon = floatData.trajLon(idSort);
floatData.speedEst = floatData.speedEst(idSort);

% output data
o_floatData = floatData;

return

% ------------------------------------------------------------------------------
% Print estimated profile locations in CSV file report.
%
% SYNTAX :
%  print_csv_report(a_floatNum, a_floatData, a_outputDir)
%
% INPUT PARAMETERS :
%   a_floatNum  : float WMO number
%   a_floatData : input float data
%   a_outputDir : output directory
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/01/2022 - RNU - creation
% ------------------------------------------------------------------------------
function print_csv_report(a_floatNum, a_floatData, a_outputDir)

% specific global variables
global g_estProfLoc_diffDepthToStart;
global g_estProfLoc_floatVsbathyTolerance;
global g_estProfLoc_floatVsbathyToleranceForGrd;


% CSV file creation
outputFileName = [a_outputDir '/estimate_profile_locations_' num2str(a_floatNum) '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create CSV output file: %s\n', outputFileName);
   return
end

% print file header
header = ['WMO;CyNum;Dir;Juld;JuldQC;JuldLoc;Lat;Lon;PosQC;Speed;ProfPresMax;' ...
   'Rpp;Grd;GrdPres;GebcoDepth;SetNum;DepthConstraint;' ...
   'ForwLat;ForwLon;ForwGebcoDepth;ForwDiffDepth;' ...
   'BackwLat;BackLon;BackwGebcoDepth;BackDiffDepth;TrajLat;TrajLon;SpeedEst;' ...
   ';DIFF_DEPTH_TO_START;FLOAT_VS_BATHY_TOLERANCE;FLOAT_VS_BATHY_TOLERANCE_FOR_GRD'];
fprintf(fidOut, '%s\n', header);

for idC = 1:length(a_floatData.cycleNumber)
   fprintf(fidOut, ...
      '%d;%d;%d;%s;%d;%s;%.3f;%.3f;%d;%.3f;%.1f;%.1f;%d;%.1f;%.1f;%d;%.1f;%.3f;%.3f;%.1f;%.1f;%.3f;%.3f;%.1f;%.1f;%.3f;%.3f;%.3f;;%d;%d;%d\n', ...
      a_floatNum, ...
      a_floatData.cycleNumber(idC), ...
      a_floatData.direction(idC), ...
      julian_2_gregorian_dec_argo(a_floatData.juld(idC)), ...
      a_floatData.juldQc(idC), ...
      julian_2_gregorian_dec_argo(a_floatData.juldLocation(idC)), ...
      a_floatData.latitude(idC), ...
      a_floatData.longitude(idC), ...
      a_floatData.positionQc(idC), ...
      a_floatData.speed(idC), ...
      a_floatData.profPresMax(idC), ...
      a_floatData.rpp(idC), ...
      a_floatData.grounded(idC), ...
      a_floatData.groundedPres(idC), ...
      a_floatData.gebcoDepth(idC), ...
      a_floatData.setNumber(idC), ...
      a_floatData.depthConstraint(idC), ...
      a_floatData.forwardLat(idC), ...
      a_floatData.forwardLon(idC), ...
      a_floatData.forwardGebcoDepth(idC), ...
      a_floatData.forwardGebcoDepth(idC)-a_floatData.depthConstraint(idC), ...
      a_floatData.backwardLat(idC), ...
      a_floatData.backwardLon(idC), ...
      a_floatData.backwardGebcoDepth(idC), ...
      a_floatData.backwardGebcoDepth(idC)-a_floatData.depthConstraint(idC), ...
      a_floatData.trajLat(idC), ...
      a_floatData.trajLon(idC), ...
      a_floatData.speedEst(idC), ...
      g_estProfLoc_diffDepthToStart, ...
      g_estProfLoc_floatVsbathyTolerance, ...
      g_estProfLoc_floatVsbathyToleranceForGrd ...
      );
end

fclose(fidOut);

return

% ------------------------------------------------------------------------------
% Get data from name in a {var_name}/{var_data} list.
%
% SYNTAX :
%  [o_dataValues] = get_data_from_name(a_dataName, a_dataList)
%
% INPUT PARAMETERS :
%   a_dataName : name of the data to retrieve
%   a_dataList : {var_name}/{var_data} list
%
% OUTPUT PARAMETERS :
%   o_dataValues : concerned data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataValues] = get_data_from_name(a_dataName, a_dataList)

% output parameters initialization
o_dataValues = [];

idVal = find(strcmp(a_dataName, a_dataList(1:2:end)) == 1, 1);
if (~isempty(idVal))
   o_dataValues = a_dataList{2*idVal};
end

return

% ------------------------------------------------------------------------------
% Get the basic structure to store a profile information.
%
% SYNTAX :
%  [o_profStruct] = get_profile_init_struct( ...
%    a_cycleNum, a_profNum, a_phaseNum, a_PrimarySamplingProfileFlag)
%
% INPUT PARAMETERS :
%   a_cycleNum                    : cycle number
%   a_profNum                     : profile number
%   a_phaseNum                    : phase number
%   a_PrimarySamplingProfileFlag  : 1 if it is a primary sampling profile,
%                                   0 otherwise
%
% OUTPUT PARAMETERS :
%   o_profStruct : profile initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/25/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = get_data_init_struct

o_dataStruct = struct( ...
   'cycleNumber', [], ...
   'direction', [], ...
   'juld', [], ...
   'juldQc', [], ...
   'juldLocation', [], ...
   'latitude', [], ...
   'longitude', [], ...
   'positionQc', [], ...
   'speed', [], ...
   'configMissionNumber', [], ...
   'profPresMax', [], ...
   'rpp', [], ...
   'grounded', [], ...
   'groundedPres', [], ...
   'gebcoDepth', [], ...
   'setNumber', [], ...
   'depthConstraint', [], ...
   'forwardLat', [], ...
   'forwardLon', [], ...
   'forwardGebcoDepth', [], ...
   'backwardLat', [], ...
   'backwardLon', [], ...
   'backwardGebcoDepth', [], ...
   'trajLat', [], ...
   'trajLon', [], ...
   'speedEst', [] ...
   );

return

% ------------------------------------------------------------------------------
% Get GEBCO depth associated to a list of locations.
%
% SYNTAX :
%  [o_depth] = get_gebco_depth(a_lon, a_lat, a_gebcoPathFileName)
%
% INPUT PARAMETERS :
%   a_lon               : latitudes
%   a_lat               : longitudes
%   a_gebcoPathFileName : GEBCO path file name
%
% OUTPUT PARAMETERS :
%   o_depth : depths
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/01/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_depth] = get_gebco_depth(a_lon, a_lat, a_gebcoPathFileName)

[elevOri] = get_gebco_elev_point(a_lon, a_lat, a_gebcoPathFileName);
elev = mean(elevOri, 2);
if (any(isnan(elev)))
   idNan = find(isnan(elev));
   for idL = idNan'
      elev(idL) = mean(elevOri(idL, ~isnan(elevOri(idL, :))));
   end
end
o_depth = -elev';

return

% ------------------------------------------------------------------------------
% Convert lon/lat to x/y.
%
% SYNTAX :
%  [o_x, o_y] = latLon_2_xy(a_lon, a_lat)
%
% INPUT PARAMETERS :
%   a_lon : latitudes
%   a_lat : longitudes
%
% OUTPUT PARAMETERS :
%   o_x : x
%   o_y : y
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/01/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_x, o_y] = latLon_2_xy(a_lon, a_lat)

% switch in km into a local reference frame
xPosOri = a_lon(2);
yPosOri = a_lat(2);

valCos = cosd(a_lat(2))*1.852*60;
o_x = (a_lon - xPosOri) .* valCos;
o_y = (a_lat - yPosOri)*1.852*60;

return

% ------------------------------------------------------------------------------
% Create the set of locations on the search segment.
% One location per km, i.e. 2*range+1 on the search segment.
%
% SYNTAX :
%  [o_lon, o_lat] = get_loc_on_search_range(a_lon, a_lat, a_range, a_angle)
%
% INPUT PARAMETERS :
%   a_lon   : latitudes on the linear trajectory
%   a_lat   : longitudes on the linear trajectory
%   a_range : range dimention
%   a_angle : angle of the normal to linear trajectory
%
% OUTPUT PARAMETERS :
%   o_lon : longitudes on the search segment
%   o_lat : latitudes on the search segment
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/01/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_lon, o_lat] = get_loc_on_search_range(a_lon, a_lat, a_range, a_angle)

% switch in km into a local reference frame
xPosOri = a_lon(2);
yPosOri = a_lat(2);

valCos = cosd(a_lat(2))*1.852*60;

xBis = (1:a_range).*cosd(a_angle);
yBis = (1:a_range).*sind(a_angle);

xTer = (1:a_range)*cosd(a_angle+180);
yTer = (1:a_range)*sind(a_angle+180);

lonBis = xBis./valCos + xPosOri;
latBis = yBis./(1.852*60) + yPosOri;

lonTer = xTer./valCos + xPosOri;
latTer = yTer./(1.852*60) + yPosOri;

o_lon = [fliplr(lonTer) a_lon(2) lonBis];
o_lat = [fliplr(latTer) a_lat(2) latBis];

return
