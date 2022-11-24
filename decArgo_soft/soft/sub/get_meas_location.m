% ------------------------------------------------------------------------------
% Retrieve the nearest available location of a measurement.
%
% SYNTAX :
%  [o_measLon, o_measLat] = get_meas_location(a_cycleNumber, a_profileNumber, a_profile)
%
% INPUT PARAMETERS :
%   a_cycleNumber   : concerned cycle number
%   a_profileNumber : concerned profile number (for CTS4 or CTS5 floats only)
%   a_profile       : profile data structure (not always available)
%
% OUTPUT PARAMETERS :
%   o_measLon : measurement longitude
%   o_measLat : measurement latitude
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/09/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_measLon, o_measLat] = get_meas_location(a_cycleNumber, a_profileNumber, a_profile)

% global default values
global g_decArgo_argosLonDef;

% QC flag values
global g_decArgo_qcStrGood;
global g_decArgo_qcGood;

% array to store surface data of Argos floats
global g_decArgo_floatSurfData;

% array to store GPS data
global g_decArgo_gpsData;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;

% float launch information
global g_decArgo_floatLaunchLon;
global g_decArgo_floatLaunchLat;


o_measLon = g_decArgo_floatLaunchLon;
o_measLat = g_decArgo_floatLaunchLat;

if (~isempty(a_profile))
   if (a_profile.locationLon ~= g_decArgo_argosLonDef)
      o_measLon = a_profile.locationLon;
      o_measLat = a_profile.locationLat;
      return
   end
end

% Argos float
if (~isempty(g_decArgo_floatSurfData))
   
   for cyNum = a_cycleNumber:-1:0
      idArgosCycle = find(g_decArgo_floatSurfData.cycleNumbers == cyNum);
      if (~isempty(idArgosCycle))
         if (~isempty(g_decArgo_floatSurfData.cycleData(idArgosCycle).argosLocDate))
            locLon = g_decArgo_floatSurfData.cycleData(idArgosCycle).argosLocLon;
            locLat = g_decArgo_floatSurfData.cycleData(idArgosCycle).argosLocLat;
            locQc = g_decArgo_floatSurfData.cycleData(idArgosCycle).argosLocQc;
            
            idGoodLoc = find(locQc == g_decArgo_qcStrGood);
            if (~isempty(idGoodLoc))
               o_measLon = locLon(idGoodLoc(1));
               o_measLat = locLat(idGoodLoc(1));
               return
            end
         end
      end
   end
end

% Iridium float
if (a_profileNumber == -1)
   
   % not CTS4 or CTS5 floats
   
   if (~isempty(g_decArgo_gpsData))
      
      % update GPS position QC information if needed
      if (any((g_decArgo_gpsData{1} ~= -1) & (g_decArgo_gpsData{7} == 0)))
         gpsData = update_gps_position_qc_ir_sbd;
      else
         gpsData = g_decArgo_gpsData;
      end
      
      % use the GPS locations
      gpsLocCycleNum = gpsData{1};
      gpsLocDate = gpsData{4};
      gpsLocLon = gpsData{5};
      gpsLocLat = gpsData{6};
      gpsLocQc = gpsData{7};
      
      if (isempty(g_decArgo_iridiumMailData))
         
         % Iridium RUDICS float
         for cyNum = a_cycleNumber:-1:0
            idGpsCycle = find(gpsLocCycleNum == cyNum);
            if (~isempty(idGpsCycle))
               locDate = gpsLocDate(idGpsCycle);
               locLon = gpsLocLon(idGpsCycle);
               locLat = gpsLocLat(idGpsCycle);
               locQc = gpsLocQc(idGpsCycle);
               
               idGoodLoc = find(locQc == g_decArgo_qcGood);
               if (~isempty(idGoodLoc))
                  % good GPS locations exist for the current cycle, use the first one
                  [~, idMin] = min(locDate(idGoodLoc));
                  o_measLon = locLon(idGoodLoc(idMin));
                  o_measLat = locLat(idGoodLoc(idMin));
                  return
               end
            end
         end
         
      else
         
         % Iridium SBD float
         locSetFlag = 0;
         for cyNum = a_cycleNumber:-1:0
            
            % use GPS data
            idGpsCycle = find(gpsLocCycleNum == cyNum);
            if (~isempty(idGpsCycle))
               locDate = gpsLocDate(idGpsCycle);
               locLon = gpsLocLon(idGpsCycle);
               locLat = gpsLocLat(idGpsCycle);
               locQc = gpsLocQc(idGpsCycle);
               
               idGoodLoc = find(locQc == g_decArgo_qcGood);
               if (~isempty(idGoodLoc))
                  % good GPS locations exist for the current cycle, use the first one
                  [~, idMin] = min(locDate(idGoodLoc));
                  o_measLon = locLon(idGoodLoc(idMin));
                  o_measLat = locLat(idGoodLoc(idMin));
                  locSetFlag = 1;
               end
            end
            
            if (locSetFlag == 0)
               
               % use Iridium data
               idIrCycle = find(([g_decArgo_iridiumMailData.cycleNumber] == cyNum) & ...
                  ([g_decArgo_iridiumMailData.cepRadius] < 5) & ...
                  ([g_decArgo_iridiumMailData.cepRadius] ~= 0));
               if (~isempty(idIrCycle))
                  locLon = [g_decArgo_iridiumMailData(idIrCycle).unitLocationLon];
                  locLat = [g_decArgo_iridiumMailData(idIrCycle).unitLocationLat];
                  locQc = [g_decArgo_iridiumMailData(idIrCycle).cepRadius];
                  
                  [~, idMin] = min(locQc);
                  o_measLon = locLon(idMin);
                  o_measLat = locLat(idMin);
                  locSetFlag = 1;
               end
            end
            
            if (locSetFlag == 1)
               return
            end
         end
      end
      
   else
      
      % Iridium SBD float with no GPS location
      if (~isempty(g_decArgo_iridiumMailData))
         for cyNum = a_cycleNumber:-1:0
            
            % use Iridium data
            idIrCycle = find(([g_decArgo_iridiumMailData.cycleNumber] == cyNum) & ...
               ([g_decArgo_iridiumMailData.cepRadius] < 5) & ...
               ([g_decArgo_iridiumMailData.cepRadius] ~= 0));
            if (~isempty(idIrCycle))
               locLon = [g_decArgo_iridiumMailData(idIrCycle).unitLocationLon];
               locLat = [g_decArgo_iridiumMailData(idIrCycle).unitLocationLat];
               locQc = [g_decArgo_iridiumMailData(idIrCycle).cepRadius];
               
               [~, idMin] = min(locQc);
               o_measLon = locLon(idMin);
               o_measLat = locLat(idMin);
               return
            end
         end
      end
   end
   
else
   
   % CTS4 or CTS5 floats
   
   if (~isempty(g_decArgo_gpsData))
      
      % update GPS position QC information if needed
      if (any((g_decArgo_gpsData{1} ~= -1) & (g_decArgo_gpsData{7} == 0)))
         gpsData = update_gps_position_qc_ir_sbd;
      else
         gpsData = g_decArgo_gpsData;
      end
      
      % use the GPS locations
      gpsLocCycleNum = gpsData{1};
      gpsLocProfNum = gpsData{2};
      gpsLocDate = gpsData{4};
      gpsLocLon = gpsData{5};
      gpsLocLat = gpsData{6};
      gpsLocQc = gpsData{7};
      
      if (isempty(g_decArgo_iridiumMailData))
         
         % Iridium RUDICS float
         for cyNum = a_cycleNumber:-1:0
            for profNum = max(gpsLocProfNum):-1:0
               idGpsCyProf = find((gpsLocCycleNum == cyNum) & ...
                  (gpsLocProfNum == profNum));
               if (~isempty(idGpsCyProf))
                  locDate = gpsLocDate(idGpsCyProf);
                  locLon = gpsLocLon(idGpsCyProf);
                  locLat = gpsLocLat(idGpsCyProf);
                  locQc = gpsLocQc(idGpsCyProf);
                  
                  idGoodLoc = find(locQc == g_decArgo_qcGood);
                  if (~isempty(idGoodLoc))
                     % good GPS locations exist for the current cycle, use the first one
                     [~, idMin] = min(locDate(idGoodLoc));
                     o_measLon = locLon(idGoodLoc(idMin));
                     o_measLat = locLat(idGoodLoc(idMin));
                     return
                  end
               end
            end
         end
         
      else
         
         % Iridium SBD float
         locSetFlag = 0;
         for cyNum = a_cycleNumber:-1:0
            for profNum = max(gpsLocProfNum):-1:0
               
               % use GPS data
               idGpsCyProf = find((gpsLocCycleNum == cyNum) & ...
                  (gpsLocProfNum == profNum));
               if (~isempty(idGpsCyProf))
                  locDate = gpsLocDate(idGpsCyProf);
                  locLon = gpsLocLon(idGpsCyProf);
                  locLat = gpsLocLat(idGpsCyProf);
                  locQc = gpsLocQc(idGpsCyProf);
                  
                  idGoodLoc = find(locQc == g_decArgo_qcGood);
                  if (~isempty(idGoodLoc))
                     % good GPS locations exist for the current cycle, use the first one
                     [~, idMin] = min(locDate(idGoodLoc));
                     o_measLon = locLon(idGoodLoc(idMin));
                     o_measLat = locLat(idGoodLoc(idMin));
                     locSetFlag = 1;
                  end
               end
               
               if (locSetFlag == 0)
                  
                  % use Iridium data
                  idIrCyProf = find(([g_decArgo_iridiumMailData.floatCycleNumber] == cyNum) & ...
                     ([g_decArgo_iridiumMailData.floatProfileNumber] == profNum) & ...
                     ([g_decArgo_iridiumMailData.cepRadius] < 5) & ...
                     ([g_decArgo_iridiumMailData.cepRadius] ~= 0));
                  if (~isempty(idIrCyProf))
                     locLon = [g_decArgo_iridiumMailData(idIrCyProf).unitLocationLon];
                     locLat = [g_decArgo_iridiumMailData(idIrCyProf).unitLocationLat];
                     locQc = [g_decArgo_iridiumMailData(idIrCyProf).cepRadius];
                     
                     [~, idMin] = min(locQc);
                     o_measLon = locLon(idMin);
                     o_measLat = locLat(idMin);
                     locSetFlag = 1;
                  end
               end
               
               if (locSetFlag == 1)
                  return
               end
            end
         end
      end
      
   else
      
      % Iridium SBD float with no GPS location
      if (~isempty(g_decArgo_iridiumMailData))
         for cyNum = a_cycleNumber:-1:0
            for profNum = max([g_decArgo_iridiumMailData.floatProfileNumber]):-1:0
               
               % use Iridium data
               idIrCyProf = find(([g_decArgo_iridiumMailData.floatCycleNumber] == cyNum) & ...
                  ([g_decArgo_iridiumMailData.floatProfileNumber] == profNum) & ...
                  ([g_decArgo_iridiumMailData.cepRadius] < 5) & ...
                  ([g_decArgo_iridiumMailData.cepRadius] ~= 0));
               if (~isempty(idIrCyProf))
                  locLon = [g_decArgo_iridiumMailData(idIrCyProf).unitLocationLon];
                  locLat = [g_decArgo_iridiumMailData(idIrCyProf).unitLocationLat];
                  locQc = [g_decArgo_iridiumMailData(idIrCyProf).cepRadius];
                  
                  [~, idMin] = min(locQc);
                  o_measLon = locLon(idMin);
                  o_measLat = locLat(idMin);
                  return
               end
            end
         end
      end
   end
end

return
