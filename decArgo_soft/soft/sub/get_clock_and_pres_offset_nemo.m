% ------------------------------------------------------------------------------
% Parse all .profile files and store all useful information concerning clock
% offsets (RTC and counter) and pressure offset.
%
% SYNTAX :
%  [o_clockOffset, o_presOffsetData] = ...
%    get_clock_and_pres_offset_nemo(a_floatNum, a_floatRudicsId, a_archiveDirectory)
%
% INPUT PARAMETERS :
%   a_floatNum         : float WMO number
%   a_floatRudicsId    : float Rudics Id
%   a_archiveDirectory : .profile files directory
%
% OUTPUT PARAMETERS :
%   o_clockOffset    : clock offset information
%   o_presOffsetData : pressure offset information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/31/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_clockOffset, o_presOffsetData] = ...
   get_clock_and_pres_offset_nemo(a_floatNum, a_floatRudicsId, a_archiveDirectory)

% output parameters initialization
o_clockOffset = get_nemo_clock_offset_init_struct;
o_presOffsetData = get_apx_pres_offset_init_struct;

% current float WMO number
global g_decArgo_floatNum;

% default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;
global g_decArgo_janFirst1950InMatlab;

% array to store GPS data
global g_decArgo_gpsData;

% array to store Iridium data
global g_decArgo_iridiumData;
g_decArgo_iridiumData = [];

% json meta-data
global g_decArgo_jsonMetaData;

% float startup date
global g_decArgo_nemoStartupDate;
g_decArgo_nemoStartupDate = [];


% retrieve STARTUP_DATE
if (isfield(g_decArgo_jsonMetaData, 'STARTUP_DATE') && ~isempty(g_decArgo_jsonMetaData.STARTUP_DATE))
   g_decArgo_nemoStartupDate = datenum(g_decArgo_jsonMetaData.STARTUP_DATE, 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
else
   idF = find(strcmp({a_metaData.metaConfigLabel}, 'STARTUP_DATE'));
   if (~isempty(idF))
      g_decArgo_nemoStartupDate = datenum(a_metaData(idF).techParamValue, 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
   end
end
o_clockOffset.startupDate = g_decArgo_nemoStartupDate;
if (isempty(g_decArgo_nemoStartupDate))
      fprintf('WARNING: Float #%d: Cannot retrieve STARTUO_DATE - cycle timings cannot be computed\n', ...
         g_decArgo_floatNum);
end

% unpack GPS data
if (~isempty(g_decArgo_gpsData))
   gpsLocCycleNum = g_decArgo_gpsData{1};
   gpsLocProfNum = g_decArgo_gpsData{2};
   gpsLocPhase = g_decArgo_gpsData{3};
   gpsLocDate = g_decArgo_gpsData{4};
   gpsLocLon = g_decArgo_gpsData{5};
   gpsLocLat = g_decArgo_gpsData{6};
   gpsLocQc = g_decArgo_gpsData{7};
   gpsLocAccuracy = g_decArgo_gpsData{8};
   gpsLocSbdFileDate = g_decArgo_gpsData{9};
else
   gpsLocCycleNum = [];
   gpsLocProfNum = [];
   gpsLocPhase = [];
   gpsLocDate = [];
   gpsLocLon = [];
   gpsLocLat = [];
   gpsLocQc = [];
   gpsLocAccuracy = [];
   gpsLocSbdFileDate = [];
end

% process all .profile files
profileFileNames = dir([a_archiveDirectory sprintf('%04d', a_floatRudicsId) '*' num2str(a_floatNum) '*.profile']);
for idFile = 1:length(profileFileNames)
   profileFileName = profileFileNames(idFile).name;
   idF = strfind(profileFileName, '_');
   cycleNumber = profileFileName(idF(end)+1:idF(end)+4);
   [cycleNumber, status] = str2num(cycleNumber);
   if (status)

      % read .profile file
      profileFilePathName = [a_archiveDirectory profileFileName];
      [ ...
         error, ...
         floatIdentificationStr, ...
         overallMissionInformationStr, ...
         deploymentInfoStr, ...
         profileTechnicalDataStr, ...
         bottomValuesDuringDriftStr, ...
         rafosValuesFormatStr, ...
         rafosValuesStr, ...
         profileHeaderStr, ...
         qualityControlHeaderStr, ...
         profileDataHeaderStr, ...
         profileDataStr, ...
         surfaceGpsDataFormatStr, ...
         surfaceGpsDataStr, ...
         iridiumPositionsFormatStr, ...
         iridiumPositionsStr, ...
         iridiumDataFormatStr, ...
         iridiumDataStr, ...
         startupMessageStr, ...
         secondOrderInformationStr ...
         ] = read_nemo_profile_file(profileFilePathName);
      if (error == 1)
         fprintf('ERROR: Error in file: %s - ignored\n', profileFilePathName);
         continue
      elseif (error == 2)
         continue
      end
   
      % store PRES offset
      profileTechnicalData = parse_nemo_info(profileTechnicalDataStr);
      if (isfield(profileTechnicalData, 'xmit_pressure_offset'))
         if (~isnan(str2double(profileTechnicalData.xmit_pressure_offset)))
            if (~any([o_presOffsetData.cycleNum] == cycleNumber))
               o_presOffsetData.cycleNum(end+1) = cycleNumber;
               o_presOffsetData.cyclePresOffset(end+1) = str2double(profileTechnicalData.xmit_pressure_offset);
            end
         end
      end

      % store xmit_surface_start_time
      if (isfield(profileTechnicalData, 'xmit_surface_start_time'))
         if (~isnan(str2double(profileTechnicalData.xmit_surface_start_time)))
            o_clockOffset.clockOffsetCycleNum(end+1) = cycleNumber;
            o_clockOffset.clockOffsetJuldUtc(end+1) = nan;
            o_clockOffset.clockOffsetRtcValue(end+1) = nan;
            o_clockOffset.xmit_surface_start_time(end+1) = str2double(profileTechnicalData.xmit_surface_start_time);
            o_clockOffset.clockOffsetCounterValue(end+1) = nan;
         end
      end
      
      % store GPS data and associated RTC offset
      if (~isempty(surfaceGpsDataStr))
         surfaceGpsData = parse_nemo_data(surfaceGpsDataFormatStr, surfaceGpsDataStr, ...
            [{'rtcJulD'} {2:7}; {'GPSJulD'} {8:13}], 'SURFACE_GPS_DATA_FORMAT');
         
         colNames = surfaceGpsData.paramName;
         for idL = 1:size(surfaceGpsData.paramValue, 1)
            if (any(isnan(surfaceGpsData.paramValue(idL, :))))
               fprintf('WARNING: NaN value in GPS data in file: %s - ignored\n', profileFilePathName);
               continue
            end
            gpsLocCycleNum = [gpsLocCycleNum; cycleNumber];
            gpsLocProfNum = [gpsLocProfNum; -1];
            gpsLocPhase = [gpsLocPhase; -1];
            gpsLocDate = [gpsLocDate; surfaceGpsData.paramValue(idL, find(strcmp('GPSJulD', colNames), 1))];
            gpsLocLon = [gpsLocLon; surfaceGpsData.paramValue(idL, find(strcmp('lon', colNames), 1))];
            gpsLocLat = [gpsLocLat; surfaceGpsData.paramValue(idL, find(strcmp('lat', colNames), 1))];
            gpsLocQc = [gpsLocQc; 0];
            gpsLocAccuracy = [gpsLocAccuracy; 'G'];
            gpsLocSbdFileDate = [gpsLocSbdFileDate; g_decArgo_dateDef];
            
            clockOffsetJuldUtc = surfaceGpsData.paramValue(idL, find(strcmp('GPSJulD', colNames), 1));
            clockOffsetValue = round((surfaceGpsData.paramValue(idL, find(strcmp('rtcJulD', colNames), 1)) - clockOffsetJuldUtc)*86400);
            
            idF = find([o_clockOffset.clockOffsetCycleNum] == cycleNumber);
            if (~isempty(idF))
               o_clockOffset.clockOffsetJuldUtc(idF) = clockOffsetJuldUtc;
               o_clockOffset.clockOffsetRtcValue(idF) = clockOffsetValue;
            else
               o_clockOffset.clockOffsetCycleNum(end+1) = cycleNumber;
               o_clockOffset.clockOffsetJuldUtc(end+1) = clockOffsetJuldUtc;
               o_clockOffset.clockOffsetRtcValue(end+1) = clockOffsetValue;
               o_clockOffset.xmit_surface_start_time(end+1) = nan;
               o_clockOffset.clockOffsetCounterValue(end+1) = nan;
            end
         end
      end
      
      % store Iridium fixes data
      if (~isempty(iridiumPositionsStr))
         iridiumPositions = parse_nemo_data(iridiumPositionsFormatStr, iridiumPositionsStr, ...
            [{'julD'} {4:9}], 'IRIDIUM_POSITIONS_FORMAT');
         
         colNames = iridiumPositions.paramName;
         for idL = 1:size(iridiumPositions.paramValue, 1)
            if (any(isnan(iridiumPositions.paramValue(idL, :))))
               fprintf('WARNING: NaN value in Iridium data in file: %s - ignored\n', profileFilePathName);
               continue
            end
            iridiumFix = get_iridium_fix_init_struct;
            iridiumFix.timeOfSessionJuld = iridiumPositions.paramValue(idL, find(strcmp('julD', colNames), 1));
            iridiumFix.unitLocationLat = iridiumPositions.paramValue(idL, find(strcmp('sbd_lat', colNames), 1));
            iridiumFix.unitLocationLon = iridiumPositions.paramValue(idL, find(strcmp('sbd_lon', colNames), 1));
            iridiumFix.cepRadius = iridiumPositions.paramValue(idL, find(strcmp('sbd_cep', colNames), 1));
            iridiumFix.cycleNumberData = cycleNumber;
            g_decArgo_iridiumData = [g_decArgo_iridiumData iridiumFix];
         end
      end
      
      % store GPS data of the prelude phase
      if (~isempty(startupMessageStr))
         startupMessage = parse_nemo_info(startupMessageStr);
         
         if (isfield(startupMessage, 'gps_datetime') && ...
               isfield(startupMessage, 'gps_lat') && ...
               isfield(startupMessage, 'gps_lon') && ...
               ~strcmp(startupMessage.gps_datetime, 'NaN') && (length(startupMessage.gps_datetime) == 20) &&...
               ~strcmp(startupMessage.gps_lat, 'NaN') && ...
               ~strcmp(startupMessage.gps_lon, 'NaN'))
            gpsJulD = datenum(startupMessage.gps_datetime, 'dd-mmm-yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;

            gpsLocCycleNum = [gpsLocCycleNum; 0];
            gpsLocProfNum = [gpsLocProfNum; -1];
            gpsLocPhase = [gpsLocPhase; -1];
            gpsLocDate = [gpsLocDate; gpsJulD];
            gpsLocLon = [gpsLocLon; str2double(startupMessage.gps_lon)];
            gpsLocLat = [gpsLocLat; str2double(startupMessage.gps_lat)];
            gpsLocQc = [gpsLocQc; 0];
            gpsLocAccuracy = [gpsLocAccuracy; 'G'];
            gpsLocSbdFileDate = [gpsLocSbdFileDate; g_decArgo_dateDef];
            
            if (isfield(startupMessage, 'real_time_clock') && ...
                  ~strcmp(startupMessage.real_time_clock, 'NaN'))
               rtcJulD = datenum(startupMessage.real_time_clock, 'dd-mmm-yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
               
               clockOffsetJuldUtc = gpsJulD;
               clockOffsetValue = (rtcJulD - gpsJulD)*86400;
               o_clockOffset.clockOffsetCycleNum(end+1) = 0;
               o_clockOffset.clockOffsetJuldUtc(end+1) = clockOffsetJuldUtc;
               o_clockOffset.clockOffsetRtcValue(end+1) = clockOffsetValue;
               o_clockOffset.xmit_surface_start_time(end+1) = nan;
               o_clockOffset.clockOffsetCounterValue(end+1) = nan;
            end
         end
      end
   end
end

% sort PRES offset according to cycle numbers
[~, idSort] = sort([o_presOffsetData.cycleNum]);
o_presOffsetData.cycleNum = o_presOffsetData.cycleNum(idSort);
o_presOffsetData.cyclePresOffset = o_presOffsetData.cyclePresOffset(idSort);

% clean duplicates and sort RTC offset according to cycle number
[~, idUnique, ~] = unique([o_clockOffset.clockOffsetCycleNum]);
o_clockOffset.clockOffsetCycleNum = o_clockOffset.clockOffsetCycleNum(idUnique);
o_clockOffset.clockOffsetJuldUtc = o_clockOffset.clockOffsetJuldUtc(idUnique);
o_clockOffset.clockOffsetRtcValue = o_clockOffset.clockOffsetRtcValue(idUnique);
o_clockOffset.xmit_surface_start_time = o_clockOffset.xmit_surface_start_time(idUnique);
o_clockOffset.clockOffsetCounterValue = o_clockOffset.clockOffsetCounterValue(idUnique);

% compute offsets for internal time counter
if (~isempty(g_decArgo_nemoStartupDate))
   
   % interpolate (xmit_surface_start_time - GPS time) to all cycles
   
   idF = find(~isnan(o_clockOffset.xmit_surface_start_time) & ~isnan(o_clockOffset.clockOffsetJuldUtc));
   idF2 = find(~isnan(o_clockOffset.xmit_surface_start_time));
   if (~isempty(idF) && ~isempty(idF2))
      o_clockOffset.clockOffsetCounterValue(idF2) = interp1q((o_clockOffset.xmit_surface_start_time(idF))', ...
         ((g_decArgo_nemoStartupDate+o_clockOffset.xmit_surface_start_time(idF)/86400-o_clockOffset.clockOffsetJuldUtc(idF))*86400)', ...
         (o_clockOffset.xmit_surface_start_time(idF2))');
      
      o_clockOffset.clockOffsetCounterValue = round(o_clockOffset.clockOffsetCounterValue);
   end
   
   % internal counter and RTC are started at the same time => the time
   % difference (xmit_surface_start_time - GPS time) used as the reference
   % corresponds to the clock offset min value
   %    idF3 = find(~isnan(o_clockOffset.clockOffsetRtcValue) & ~isnan(o_clockOffset.xmit_surface_start_time));
   %    [~, idMin] = min(abs(o_clockOffset.clockOffsetRtcValue(idF3)));
   %
   %    o_clockOffset.clockOffsetCounterValue = ...
   %       o_clockOffset.clockOffsetCounterValue - o_clockOffset.clockOffsetCounterValue(idF3(idMin));
end

% clean GPS data according to location date
[~, idUnique, ~] = unique(gpsLocDate);
gpsLocCycleNum = gpsLocCycleNum(idUnique);
gpsLocProfNum = gpsLocProfNum(idUnique);
gpsLocPhase = gpsLocPhase(idUnique);
gpsLocDate = gpsLocDate(idUnique);
gpsLocLon = gpsLocLon(idUnique);
gpsLocLat = gpsLocLat(idUnique);
gpsLocQc = gpsLocQc(idUnique);
gpsLocAccuracy = gpsLocAccuracy(idUnique);
gpsLocSbdFileDate = gpsLocSbdFileDate(idUnique);

% sort GPS data according to cycle numbers
[~, idSort] = sort(gpsLocCycleNum);
gpsLocCycleNum = gpsLocCycleNum(idSort);
gpsLocProfNum = gpsLocProfNum(idSort);
gpsLocPhase = gpsLocPhase(idSort);
gpsLocDate = gpsLocDate(idSort);
gpsLocLon = gpsLocLon(idSort);
gpsLocLat = gpsLocLat(idSort);
gpsLocQc = gpsLocQc(idSort);
gpsLocAccuracy = gpsLocAccuracy(idSort);
gpsLocSbdFileDate = gpsLocSbdFileDate(idSort);

% compute the JAMSTEC QC for the GPS locations
cycleNumList = unique(gpsLocCycleNum);
for idCy = 1:length(cycleNumList)
   
   curCyNum = cycleNumList(idCy);
   
   lastLocDateOfPrevCycle = g_decArgo_dateDef;
   lastLocLonOfPrevCycle = g_decArgo_argosLonDef;
   lastLocLatOfPrevCycle = g_decArgo_argosLatDef;
   
   % retrieve the last good GPS location of the previous cycle
   if (curCyNum > 0)
      idF = find((gpsLocCycleNum == curCyNum-1) & (gpsLocQc == 1), 1, 'last');
      if (~isempty(idF))
         lastLocDateOfPrevCycle = gpsLocDate(idF);
         lastLocLonOfPrevCycle = gpsLocLon(idF);
         lastLocLatOfPrevCycle = gpsLocLat(idF);
      end
   end
   
   idF = find(gpsLocCycleNum == curCyNum);
   locDate = gpsLocDate(idF);
   locLon = gpsLocLon(idF);
   locLat = gpsLocLat(idF);
   locAcc = gpsLocAccuracy(idF);
   
   [locQc] = compute_jamstec_qc( ...
      locDate, locLon, locLat, locAcc, ...
      lastLocDateOfPrevCycle, lastLocLonOfPrevCycle, lastLocLatOfPrevCycle, []);
   
   gpsLocQc(idF) = str2num(locQc')';
end

% pack GPS data
g_decArgo_gpsData{1} = gpsLocCycleNum;
g_decArgo_gpsData{2} = gpsLocProfNum;
g_decArgo_gpsData{3} = gpsLocPhase;
g_decArgo_gpsData{4} = gpsLocDate;
g_decArgo_gpsData{5} = gpsLocLon;
g_decArgo_gpsData{6} = gpsLocLat;
g_decArgo_gpsData{7} = gpsLocQc;
g_decArgo_gpsData{8} = gpsLocAccuracy;
g_decArgo_gpsData{9} = gpsLocSbdFileDate;

% sort Iridium fixes data according to UTC JulD
[~, idSort] = sort([g_decArgo_iridiumData.timeOfSessionJuld]);
g_decArgo_iridiumData = g_decArgo_iridiumData(idSort);

% set cycle number of transmission sessions
% FOLLOWING DOESN'T WORK WELL (Iridium session exists without GPS fix)
% for idF = 1:length(g_decArgo_iridiumData)
%    timeOfSessionJuld = g_decArgo_iridiumData(idF).timeOfSessionJuld;
%    idAfter = find(timeOfSessionJuld > gpsLocDate, 1, 'first');
%    g_decArgo_iridiumData(idF).cycleNumber = gpsLocCycleNum(idAfter);
% end

return
