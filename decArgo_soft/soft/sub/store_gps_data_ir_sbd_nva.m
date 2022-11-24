% ------------------------------------------------------------------------------
% Store GPS data in a cell array.
%
% SYNTAX :
%  store_gps_data_ir_sbd_nva(a_tabTech)
%
% INPUT PARAMETERS :
%   a_tabTech : float technical data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/28/2016 - RNU - creation
% ------------------------------------------------------------------------------
function store_gps_data_ir_sbd_nva(a_tabTech)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;

% array to store GPS data
global g_decArgo_gpsData;

% cycle timings storage
global g_decArgo_timeData;


ID_OFFSET = 1;

if (~isempty(a_tabTech))
   
   if (size(a_tabTech, 1) > 1)
      fprintf('ERROR: Float #%d cycle #%d: BUFFER anomaly (%d tech message in the buffer)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         size(a_tabTech, 1));
   elseif (size(a_tabTech, 1) == 1)
      id = 1;
      
      % no GPS fix in the TECH message
      if (a_tabTech(id, 40+ID_OFFSET) == 0) && ...
            (fix(a_tabTech(id, 38+ID_OFFSET)) == 214) && ...
            (fix(a_tabTech(id, 39+ID_OFFSET)) == 214)
         return;
      end

      % unpack the GPS data
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
      
      % append new GPS fix information
      gpsLocCycleNum = [gpsLocCycleNum; g_decArgo_cycleNum];
      gpsLocProfNum = [gpsLocProfNum; -1];
      gpsLocPhase = [gpsLocPhase; -1];
      
      % retrieve date from g_decArgo_timeData structure
      idCycleStruct = find([g_decArgo_timeData.cycleNum] == g_decArgo_cycleNum);
      gpsLocDate = [gpsLocDate; g_decArgo_timeData.cycleTime(idCycleStruct(end)).gpsTimeAdj];
      
      gpsLocLon = [gpsLocLon; a_tabTech(id, 39+ID_OFFSET)];
      gpsLocLat = [gpsLocLat; a_tabTech(id, 38+ID_OFFSET)];
      gpsLocQc = [gpsLocQc; 0];
      gpsLocAccuracy = [gpsLocAccuracy; 'G'];
      gpsLocSbdFileDate = [gpsLocSbdFileDate; a_tabTech(id, end)];
      
      % compute the JAMSTEC QC for the GPS locations of the current cycle
      
      lastLocDateOfPrevCycle = g_decArgo_dateDef;
      lastLocLonOfPrevCycle = g_decArgo_argosLonDef;
      lastLocLatOfPrevCycle = g_decArgo_argosLatDef;
      
      % retrieve the last good GPS location of the previous cycle
      % (cycleNumber-1)
      idF = find(gpsLocCycleNum == g_decArgo_cycleNum-1);
      if (~isempty(idF))
         prevLocDate = gpsLocDate(idF);
         prevLocLon = gpsLocLon(idF);
         prevLocLat = gpsLocLat(idF);
         prevLocQc = gpsLocQc(idF);
         
         idGoodLoc = find(prevLocQc == 1);
         if (~isempty(idGoodLoc))
            lastLocDateOfPrevCycle = prevLocDate(idGoodLoc(end));
            lastLocLonOfPrevCycle = prevLocLon(idGoodLoc(end));
            lastLocLatOfPrevCycle = prevLocLat(idGoodLoc(end));
         end
      end
      
      idF = find(gpsLocCycleNum == g_decArgo_cycleNum);
      locDate = gpsLocDate(idF);
      locLon = gpsLocLon(idF);
      locLat = gpsLocLat(idF);
      locAcc = gpsLocAccuracy(idF);
      
      [locQc] = compute_jamstec_qc( ...
         locDate, locLon, locLat, locAcc, ...
         lastLocDateOfPrevCycle, lastLocLonOfPrevCycle, lastLocLatOfPrevCycle, []);
      
      gpsLocQc(idF) = str2num(locQc')';
      
      % update GPS data global variable
      g_decArgo_gpsData{1} = gpsLocCycleNum;
      g_decArgo_gpsData{2} = gpsLocProfNum;
      g_decArgo_gpsData{3} = gpsLocPhase;
      g_decArgo_gpsData{4} = gpsLocDate;
      g_decArgo_gpsData{5} = gpsLocLon;
      g_decArgo_gpsData{6} = gpsLocLat;
      g_decArgo_gpsData{7} = gpsLocQc;
      g_decArgo_gpsData{8} = gpsLocAccuracy;
      g_decArgo_gpsData{9} = gpsLocSbdFileDate;
   end
end

return;
