% ------------------------------------------------------------------------------
% Process and store GPS data in a dedicated cell array.
% process GPS data of previous and current cycle:
% - merge GPS data from both sources (science_log and system_log files)
% - store GPS data
% - compute JAMSTEC QC for the GPS locations
%
% SYNTAX :
%  store_gps_data_apx_apf11_ir(a_gpsDataSci, a_gpsDataSys, a_cycleNum)
%
% INPUT PARAMETERS :
%   a_gpsDataSci : GPS data from science_log file
%   a_gpsDataSys : GPS data from system_log file
%   a_cycleNum   : current cycle number
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function store_gps_data_apx_apf11_ir(a_gpsDataSci, a_gpsDataSys, a_cycleNum)

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


if (isempty(a_gpsDataSci) && isempty(a_gpsDataSys))
   return;
end

% unpack  GPS data
gpsLocCycleNum = g_decArgo_gpsData{1};
gpsLocDate = g_decArgo_gpsData{4};
gpsLocLon = g_decArgo_gpsData{5};
gpsLocLat = g_decArgo_gpsData{6};
gpsLocQc = g_decArgo_gpsData{7};
gpsLocAccuracy = g_decArgo_gpsData{8};
if ((size(g_decArgo_gpsData, 1) == 1) && (length(g_decArgo_gpsData) == 9))
   gpsLocNbSat = -1;
   gpsLocTimeToFix = -1;
else
   gpsLocNbSat = g_decArgo_gpsData{10};
   gpsLocTimeToFix = g_decArgo_gpsData{11};
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process GPS data of the previous cycle
if (a_cycleNum > 0)
   
   % merge GPS data from science_log and system_log files
   gpsDataSci = a_gpsDataSci(find(a_gpsDataSci(:, 1) == a_cycleNum-1), :);
   gpsDataSciStr = [];
   for idP = 1:size(gpsDataSci, 1)
      gpsDataSciStr{end+1} = sprintf('%s %d', julian_2_gregorian_dec_argo(gpsDataSci(idP, 2)), gpsDataSci(idP, 5));
   end
   gpsDataSys = a_gpsDataSys(find(a_gpsDataSys(:, 1) == a_cycleNum-1), :);
   gpsDataSysStr = [];
   for idP = 1:size(gpsDataSys, 1)
      gpsDataSysStr{end+1} = sprintf('%s %d', julian_2_gregorian_dec_argo(gpsDataSys(idP, 2)), gpsDataSys(idP, 5));
   end
   gpsDataAllStr = unique([gpsDataSciStr; gpsDataSysStr]);
   
   gpsDataAllPrev = [];
   for idP = 1:length(gpsDataAllStr)
      idF1 = find(strcmp(gpsDataAllStr{idP}, gpsDataSciStr));
      idF2 = find(strcmp(gpsDataAllStr{idP}, gpsDataSysStr));
      if (~isempty(idF2))
         gpsDataAllPrev = [gpsDataAllPrev;  gpsDataSys(idF2(1), :)];
         if (isempty(idF1))
            fprintf('ERROR: Float #%d Cycle #%d: GPS data not reported in science_log file\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum);
         elseif (~any((abs(gpsDataSci(idF1, 3)-gpsDataSys(idF2, 3)) < 1e-5) | ...
               (abs(gpsDataSci(idF1, 4)-gpsDataSys(idF2, 4)) < 1e-5)))
            fprintf('ERROR: Float #%d Cycle #%d: GPS data not reported in science_log file\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum);
         end
      else
         gpsDataAllPrev = [gpsDataAllPrev;  [gpsDataSci(idF1(1), :) -1]];
         fprintf('ERROR: Float #%d Cycle #%d: GPS data not reported in system_log file\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
      end
   end
   
   for idP = 1:size(gpsDataAllPrev, 1)
      gpsLocCycleNum = [gpsLocCycleNum; a_cycleNum-1];
      gpsLocDate = [gpsLocDate; gpsDataAllPrev(idP, 2)];
      gpsLocLon = [gpsLocLon; gpsDataAllPrev(idP, 4)];
      gpsLocLat = [gpsLocLat; gpsDataAllPrev(idP, 3)];
      gpsLocQc = [gpsLocQc; 0];
      gpsLocAccuracy = [gpsLocAccuracy; 'G'];
      gpsLocNbSat = [gpsLocNbSat; gpsDataAllPrev(idP, 5)];
      gpsLocTimeToFix = [gpsLocTimeToFix; gpsDataAllPrev(idP, 6)];
   end
   
   if (~isempty(gpsDataAllPrev))
      
      % compute the JAMSTEC QC for the GPS locations of the previous cycle
      
      lastLocDateOfPrevCycle = g_decArgo_dateDef;
      lastLocLonOfPrevCycle = g_decArgo_argosLonDef;
      lastLocLatOfPrevCycle = g_decArgo_argosLatDef;
      
      % retrieve the last good GPS location of the previous cycle
      % (a_cycleNum-1)
      if (a_cycleNum > 1)
         idF = find(gpsLocCycleNum == a_cycleNum-2);
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
      end
      
      idF = find(gpsLocCycleNum == a_cycleNum-1);
      locDate = gpsLocDate(idF);
      locLon = gpsLocLon(idF);
      locLat = gpsLocLat(idF);
      locAcc = gpsLocAccuracy(idF);
      
      [locQc] = compute_jamstec_qc( ...
         locDate, locLon, locLat, locAcc, ...
         lastLocDateOfPrevCycle, lastLocLonOfPrevCycle, lastLocLatOfPrevCycle, []);
      
      gpsLocQc(idF) = str2num(locQc')';
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process GPS data of the current cycle

% merge GPS data from science_log and system_log files
gpsDataSci = a_gpsDataSci(find(a_gpsDataSci(:, 1) == a_cycleNum), :);
gpsDataSciStr = [];
for idP = 1:size(gpsDataSci, 1)
   gpsDataSciStr{end+1} = sprintf('%s %.5f %.5f %d', julian_2_gregorian_dec_argo(gpsDataSci(idP, 2)), gpsDataSci(idP, 5));
end
gpsDataSys = a_gpsDataSys(find(a_gpsDataSys(:, 1) == a_cycleNum), :);
gpsDataSysStr = [];
for idP = 1:size(gpsDataSys, 1)
   gpsDataSysStr{end+1} = sprintf('%s %.5f %.5f %d', julian_2_gregorian_dec_argo(gpsDataSys(idP, 2)), gpsDataSys(idP, 5));
end
gpsDataAllStr = unique([gpsDataSciStr; gpsDataSysStr]);
if ((size(gpsDataSci, 1) == 1) && (size(gpsDataSys, 1) == 1) && (length(unique(gpsDataAllStr)) == 1))
   % nominal case
   gpsDataAllCur = gpsDataSys;
else
   gpsDataAllCur = [];
   for idP = 1:length(gpsDataAllStr)
      idF1 = find(strcmp(gpsDataAllStr{idP}, gpsDataSciStr));
      idF2 = find(strcmp(gpsDataAllStr{idP}, gpsDataSysStr));
      if (~isempty(idF2))
         gpsDataAllCur = [gpsDataAllCur;  gpsDataSys(idF2(1), :)];
         if (isempty(idF1))
            fprintf('ERROR: Float #%d Cycle #%d: GPS data not reported in science_log file\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum);
         elseif (~any((abs(gpsDataSci(idF1, 3)-gpsDataSys(idF2, 3)) < 1e-5) | ...
               (abs(gpsDataSci(idF1, 4)-gpsDataSys(idF2, 4)) < 1e-5)))
            fprintf('ERROR: Float #%d Cycle #%d: GPS data not reported in science_log file\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum);
         end
      else
         gpsDataAllCur = [gpsDataAllCur;  [gpsDataSci(idF1(1), :) -1]];
         fprintf('ERROR: Float #%d Cycle #%d: GPS data not reported in system_log file\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
      end
   end
end

for idP = 1:size(gpsDataAllCur, 1)
   gpsLocCycleNum = [gpsLocCycleNum; a_cycleNum];
   gpsLocDate = [gpsLocDate; gpsDataAllCur(idP, 2)];
   gpsLocLon = [gpsLocLon; gpsDataAllCur(idP, 4)];
   gpsLocLat = [gpsLocLat; gpsDataAllCur(idP, 3)];
   gpsLocQc = [gpsLocQc; 0];
   gpsLocAccuracy = [gpsLocAccuracy; 'G'];
   gpsLocNbSat = [gpsLocNbSat; gpsDataAllCur(idP, 5)];
   gpsLocTimeToFix = [gpsLocTimeToFix; gpsDataAllCur(idP, 6)];
end

if (~isempty(gpsDataAllCur))
   
   % compute the JAMSTEC QC for the GPS locations of the current cycle
   
   lastLocDateOfPrevCycle = g_decArgo_dateDef;
   lastLocLonOfPrevCycle = g_decArgo_argosLonDef;
   lastLocLatOfPrevCycle = g_decArgo_argosLatDef;
   
   % retrieve the last good GPS location of the previous cycle
   % (a_cycleNum-1)
   if (a_cycleNum > 0)
      idF = find(gpsLocCycleNum == a_cycleNum-1);
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
   end
   
   idF = find(gpsLocCycleNum == a_cycleNum);
   locDate = gpsLocDate(idF);
   locLon = gpsLocLon(idF);
   locLat = gpsLocLat(idF);
   locAcc = gpsLocAccuracy(idF);
   
   [locQc] = compute_jamstec_qc( ...
      locDate, locLon, locLat, locAcc, ...
      lastLocDateOfPrevCycle, lastLocLonOfPrevCycle, lastLocLatOfPrevCycle, []);
   
   gpsLocQc(idF) = str2num(locQc')';
end

% update GPS data global variable
g_decArgo_gpsData{1} = gpsLocCycleNum;
g_decArgo_gpsData{4} = gpsLocDate;
g_decArgo_gpsData{5} = gpsLocLon;
g_decArgo_gpsData{6} = gpsLocLat;
g_decArgo_gpsData{7} = gpsLocQc;
g_decArgo_gpsData{8} = gpsLocAccuracy;
g_decArgo_gpsData{10} = gpsLocNbSat;
g_decArgo_gpsData{11} = gpsLocTimeToFix;

return;
