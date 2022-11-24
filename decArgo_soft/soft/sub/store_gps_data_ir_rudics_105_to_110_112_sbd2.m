% ------------------------------------------------------------------------------
% Store GPS data in a cell array.
%
% SYNTAX :
% store_gps_data_ir_rudics_105_to_110_112_sbd2(a_tabTech)
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
%   02/15/2013 - RNU - creation
% ------------------------------------------------------------------------------
function store_gps_data_ir_rudics_105_to_110_112_sbd2(a_tabTech)

% global default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;

% array to store GPS data
global g_decArgo_gpsData;


if (~isempty(a_tabTech))
   
   idPos = find(a_tabTech(:, 76) ~= g_decArgo_argosLonDef);
   if (~isempty(idPos))
      
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
      
      % GPS data (consider only 'valid' GPS locations)
      % for float software versions 1.04 to 1.06: locations with valid fix = 0
      % are erroneous due to GPS frame failure (issue fixed in 1.07 version)
      idValidFix = find(a_tabTech(idPos, 71) == 1);
      for idP = 1:length(idValidFix)
         gpsLocCycleNum = [gpsLocCycleNum; a_tabTech(idPos(idValidFix(idP)), 4)];
         gpsLocProfNum = [gpsLocProfNum; a_tabTech(idPos(idValidFix(idP)), 5)];
         gpsLocPhase = [gpsLocPhase; a_tabTech(idPos(idValidFix(idP)), 8)];
         gpsLocDate = [gpsLocDate; a_tabTech(idPos(idValidFix(idP)), 1)];
         gpsLocLon = [gpsLocLon; a_tabTech(idPos(idValidFix(idP)), 76)];
         gpsLocLat = [gpsLocLat; a_tabTech(idPos(idValidFix(idP)), 77)];
         gpsLocQc = [gpsLocQc; zeros(length(idPos(idValidFix(idP))), 1)];
         gpsLocAccuracy = [gpsLocAccuracy; repmat('G', length(idPos(idValidFix(idP))), 1)];
         gpsLocSbdFileDate = [gpsLocSbdFileDate; a_tabTech(idPos(idValidFix(idP)), 78)];
         
         for id = 1:length(idPos)
            
            % compute the JAMSTEC QC for the GPS locations of the current cycle
            
            lastLocDateOfPrevCycle = g_decArgo_dateDef;
            lastLocLonOfPrevCycle = g_decArgo_argosLonDef;
            lastLocLatOfPrevCycle = g_decArgo_argosLatDef;
            
            cycleNumber = a_tabTech(idPos(id), 4);
            profNumber = a_tabTech(idPos(id), 5);
            
            % retrieve the last good GPS location of the previous surface phase
            idF = find((gpsLocCycleNum == cycleNumber) & (gpsLocProfNum < profNumber));
            if (~isempty(idF))
               idF = idF(end);
            else
               idF = find(gpsLocCycleNum == cycleNumber-1);
               if (~isempty(idF))
                  idF = idF(end);
               end
            end
            
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
            
            idF = find((gpsLocCycleNum == cycleNumber) & (gpsLocProfNum == profNumber));
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

return
