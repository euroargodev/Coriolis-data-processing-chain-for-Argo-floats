% ------------------------------------------------------------------------------
% Apply JAMSTEC QC to GPS data.
%
% SYNTAX :
%  [o_gpsData] = update_gps_position_qc_ir_sbd
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_gpsData : updated GPS data (copy of the global variable)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/13/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_gpsData] = update_gps_position_qc_ir_sbd

% output parameters initialization
o_gpsData = [];

% array to store GPS data
global g_decArgo_gpsData;

% default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;


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
   
   % update the JAMSTEC QC of the GPS locations
   
   idCyNumList = find((gpsLocCycleNum ~= -1) & (gpsLocQc == 0));
   cyNumList = unique(gpsLocCycleNum(idCyNumList));
   for idCy = 1:length(cyNumList)
      
      cycleNum = cyNumList(idCy);
      
      lastLocDateOfPrevCycle = g_decArgo_dateDef;
      lastLocLonOfPrevCycle = g_decArgo_argosLonDef;
      lastLocLatOfPrevCycle = g_decArgo_argosLatDef;
      
      % retrieve the last good GPS location of the previous cycle
      % (cycleNum-1)
      idF = find(gpsLocCycleNum == cycleNum-1);
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
      
      idF = find(gpsLocCycleNum == cycleNum);
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
   g_decArgo_gpsData{2} = gpsLocProfNum;
   g_decArgo_gpsData{3} = gpsLocPhase;
   g_decArgo_gpsData{4} = gpsLocDate;
   g_decArgo_gpsData{5} = gpsLocLon;
   g_decArgo_gpsData{6} = gpsLocLat;
   g_decArgo_gpsData{7} = gpsLocQc;
   g_decArgo_gpsData{8} = gpsLocAccuracy;
   g_decArgo_gpsData{9} = gpsLocSbdFileDate;
end

% output data
o_gpsData = g_decArgo_gpsData;
      
return
