% ------------------------------------------------------------------------------
% Store GPS data in a cell array.
%
% SYNTAX :
% store_gps_data_pfv2(a_selfTest, a_tech1, a_tech2, o_eol, a_cycleNum)
%
% INPUT PARAMETERS :
%   a_selfTest : self test tech data
%   a_tech1    : tech #1 data
%   a_tech2    : tech #2 data
%   o_eol      : EOL tech data
%   a_cycleNum : cycle number
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/23/2024 - RNU - creation
% ------------------------------------------------------------------------------
function store_gps_data_pfv2(a_selfTest, a_tech1, a_tech2, o_eol, a_cycleNum)

% default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;

% array to store GPS data
global g_decArgo_gpsData;


% unpack the GPS data
if (~isempty(g_decArgo_gpsData))
   gpsLocCycleNum = g_decArgo_gpsData{1};
   gpsLocDate = g_decArgo_gpsData{4};
   gpsLocLon = g_decArgo_gpsData{5};
   gpsLocLat = g_decArgo_gpsData{6};
   gpsLocQc = g_decArgo_gpsData{7};
   gpsLocAccuracy = g_decArgo_gpsData{8};
else
   gpsLocCycleNum = [];
   gpsLocDate = [];
   gpsLocLon = [];
   gpsLocLat = [];
   gpsLocQc = [];
   gpsLocAccuracy = [];
end

nbLocStart = length(gpsLocCycleNum);
for file = 1:4
   if (file == 1)
      inputData = a_selfTest;
   elseif (file == 2)
      inputData = a_tech1;
   elseif (file == 3)
      inputData = a_tech2;
   elseif (file == 4)
      inputData = o_eol;
   end

   for idL = 1:size(inputData, 1)
      techTimeData = inputData{idL, 2};
      techTrajData = inputData{idL, 3};

      idLoc = find([techTrajData.techId] == 700000);
      idValid = find([techTimeData.techId] == 700004);

      for idP = 1:length(idLoc)
         if (techTimeData(idValid(idP)).value)
            gpsLocCycleNum = [gpsLocCycleNum; a_cycleNum];
            gpsLocDate = [gpsLocDate; techTrajData(idLoc(idP)).julD];
            gpsLocLon = [gpsLocLon; techTrajData(idLoc(idP)).lon];
            gpsLocLat = [gpsLocLat; techTrajData(idLoc(idP)).lat];
            gpsLocQc = [gpsLocQc; 0];
            gpsLocAccuracy = [gpsLocQc; 'G'];
         end
      end
   end
end
nbLocEnd = length(gpsLocCycleNum);

if (nbLocEnd > nbLocStart)

   % sort GPS data according to location dates
   [~, idSort] = sort(gpsLocDate);
   gpsLocCycleNum = gpsLocCycleNum(idSort);
   gpsLocDate = gpsLocDate(idSort);
   gpsLocLon = gpsLocLon(idSort);
   gpsLocLat = gpsLocLat(idSort);
   gpsLocQc = gpsLocQc(idSort);
   gpsLocAccuracy = gpsLocAccuracy(idSort);

   % compute the JAMSTEC QC for the GPS locations of the current cycle

   lastLocDateOfPrevCycle = g_decArgo_dateDef;
   lastLocLonOfPrevCycle = g_decArgo_argosLonDef;
   lastLocLatOfPrevCycle = g_decArgo_argosLatDef;

   % retrieve the last good GPS location of the previous cycle
   % (a_cycleNum-1)
   if (a_cycleNum > 0)
      idF = find((gpsLocCycleNum == a_cycleNum-1) & (gpsLocQc == 1), 1, 'last');
      if (~isempty(idF))
         lastLocDateOfPrevCycle = gpsLocDate(idF);
         lastLocLonOfPrevCycle = gpsLocLon(idF);
         lastLocLatOfPrevCycle = gpsLocLat(idF);
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

   % update GPS data global variable
   g_decArgo_gpsData{1} = gpsLocCycleNum;
   g_decArgo_gpsData{4} = gpsLocDate;
   g_decArgo_gpsData{5} = gpsLocLon;
   g_decArgo_gpsData{6} = gpsLocLat;
   g_decArgo_gpsData{7} = gpsLocQc;
   g_decArgo_gpsData{8} = gpsLocAccuracy;
end

return
