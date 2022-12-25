% ------------------------------------------------------------------------------
% Store GPS data in a cell array.
%
% SYNTAX :
%  store_gps_data_ir_rudics_111_113_114_115(a_tabTech)
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
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function store_gps_data_ir_rudics_111_113_114_115(a_tabTech)

% global default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;

% array to store GPS data
global g_decArgo_gpsData;

% cycle phases
global g_decArgo_phaseSurfWait;


if (~isempty(a_tabTech))
   
   idPos = find((a_tabTech(:, 88) ~= g_decArgo_argosLonDef) & (a_tabTech(:, 77) == 1)); % valid fix
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
         gpsLocInTrajFlag = g_decArgo_gpsData{13};
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
         gpsLocInTrajFlag = [];
      end
      
      % GPS data (consider only 'valid' GPS locations)
      
      gpsLocCycleNum = [gpsLocCycleNum; a_tabTech(idPos, 4)];
      gpsLocProfNum = [gpsLocProfNum; a_tabTech(idPos, 5)];
      gpsLocPhase = [gpsLocPhase; a_tabTech(idPos, 8)];
      gpsLocDate = [gpsLocDate; a_tabTech(idPos, 1)];
      gpsLocLon = [gpsLocLon; a_tabTech(idPos, 88)];
      gpsLocLat = [gpsLocLat; a_tabTech(idPos, 89)];
      gpsLocQc = [gpsLocQc; zeros(length(idPos), 1)];
      gpsLocAccuracy = [gpsLocAccuracy; repmat('G', length(idPos), 1)];
      gpsLocSbdFileDate = [gpsLocSbdFileDate; a_tabTech(idPos, 90)];
      gpsLocInTrajFlag = [gpsLocInTrajFlag; zeros(length(idPos), 1)];

      % sort GPS data according to location dates
      [~, idSort] = sort(gpsLocDate);
      gpsLocCycleNum = gpsLocCycleNum(idSort);
      gpsLocProfNum = gpsLocProfNum(idSort);
      gpsLocPhase = gpsLocPhase(idSort);
      gpsLocDate = gpsLocDate(idSort);
      gpsLocLon = gpsLocLon(idSort);
      gpsLocLat = gpsLocLat(idSort);
      gpsLocQc = gpsLocQc(idSort);
      gpsLocAccuracy = gpsLocAccuracy(idSort);
      gpsLocSbdFileDate = gpsLocSbdFileDate(idSort);
      gpsLocInTrajFlag = gpsLocInTrajFlag(idSort);

      % for JAMSTEC QC, we need to retrieve the last good GPS location of the
      % previous surface phase, for that we need to use an updated cycle and
      % profile number for the second Iridium session locations
      % (should be assigned to last deep cycle)
      cyProfNumBis = nan(length(gpsLocCycleNum), 2);
      for idCy = 1:length(gpsLocCycleNum)
         if ((gpsLocPhase(idCy) == g_decArgo_phaseSurfWait) && (gpsLocCycleNum(idCy) > 0)) % second Iridium session
            cyProfNumBis(idCy, 1) = gpsLocCycleNum(idCy) - 1;
            idF = find(gpsLocCycleNum == gpsLocCycleNum(idCy) - 1);
            if (~isempty(idF))
               cyProfNumBis(idCy, 2) = max(gpsLocProfNum(idF)); % may fail in case of delayed transmission
            else
               cyProfNumBis(idCy, 2) = 0;
            end
         else
            cyProfNumBis(idCy, 1) = gpsLocCycleNum(idCy);
            cyProfNumBis(idCy, 2) = gpsLocProfNum(idCy);
         end
      end

      cyProfNumListBis = cyProfNumBis(end-length(idPos)+1:end, :);
      uCyProfNumListBis = unique(cyProfNumListBis, 'rows');
      for idCy = 1:size(uCyProfNumListBis, 1)
         
         cycleNumber = uCyProfNumListBis(idCy, 1);
         profNumber = uCyProfNumListBis(idCy, 2);
         
         % compute the JAMSTEC QC for the GPS locations of the current cycle
         
         lastLocDateOfPrevCycle = g_decArgo_dateDef;
         lastLocLonOfPrevCycle = g_decArgo_argosLonDef;
         lastLocLatOfPrevCycle = g_decArgo_argosLatDef;
                  
         % retrieve the last good GPS location of the previous surface phase
         idF = find((cyProfNumBis(:, 1) == cycleNumber) & (cyProfNumBis(:, 2) < profNumber) & (gpsLocQc == 1), 1, 'last'); % they have been previously sorted
         if (isempty(idF))
            idF = find((cyProfNumBis(:, 1) == cycleNumber-1) & (gpsLocQc == 1), 1, 'last'); % they have been previously sorted
         end
         if (~isempty(idF))
            lastLocDateOfPrevCycle = gpsLocDate(idF);
            lastLocLonOfPrevCycle = gpsLocLon(idF);
            lastLocLatOfPrevCycle = gpsLocLat(idF);
         end
         
         idF = find((cyProfNumBis(:, 1) == cycleNumber) & (cyProfNumBis(:, 2) == profNumber));
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
      g_decArgo_gpsData{13} = gpsLocInTrajFlag;
   end
end

return
