% ------------------------------------------------------------------------------
% Retrieve decoded data.
%
% SYNTAX :
%  [o_tabTech1, o_tabTech2, ...
%    o_dataCTD, o_dataCTDO, ...
%    o_evAct, o_pumpAct, ...
%    o_floatParam1, o_floatParam2] = ...
%    get_decoded_data(a_decDataTab, a_decoderId)
%
% INPUT PARAMETERS :
%   a_decodedDataTab : decoded data
%   a_decoderId      : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabTech1    : tech #1 packet data
%   o_tabTech2    : tech #2 packet data
%   o_dataCTD     : CTD packet data
%   o_dataCTDO    : CTDO packet data
%   o_evAct       : hydraulic (valve) packet data
%   o_pumpAct     : hydraulic (pump) packet data
%   o_floatParam1 : prog param #1 packet data
%   o_floatParam2 : prog param #2 packet data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/17/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTech1, o_tabTech2, ...
   o_dataCTD, o_dataCTDO, ...
   o_evAct, o_pumpAct, ...
   o_floatParam1, o_floatParam2] = ...
   get_decoded_data(a_decDataTab, a_decoderId)

% output parameters initialization
o_tabTech1 = [];
o_tabTech2 = [];
o_dataCTD = [];
o_dataCTDO = [];
o_evAct = [];
o_pumpAct = [];
o_floatParam1 = [];
o_floatParam2 = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% array ro store statistics on received packets
global g_decArgo_nbDescentPacketsReceived;
global g_decArgo_nbParkPacketsReceived;
global g_decArgo_nbAscentPacketsReceived;
global g_decArgo_nbNearSurfacePacketsReceived;
global g_decArgo_nbInAirPacketsReceived;
global g_decArgo_nbHydraulicPacketsReceived;
global g_decArgo_nbTech1PacketsReceived;
global g_decArgo_nbTech2PacketsReceived;
global g_decArgo_nbParmPacketsReceived;
global g_decArgo_nbParm1PacketsReceived;
global g_decArgo_nbParm2PacketsReceived;

% to detect ICE mode activation (first cycle for which parameter packet #7 has
% been received)
global g_decArgo_7TypePacketReceivedCyNum;


switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {212, 222} % Arvor-ARN-Ice Iridium
      
      g_decArgo_nbDescentPacketsReceived = 0;
      g_decArgo_nbParkPacketsReceived = 0;
      g_decArgo_nbAscentPacketsReceived = 0;
      g_decArgo_nbHydraulicPacketsReceived = 0;
      g_decArgo_nbTech1PacketsReceived = 0;
      g_decArgo_nbTech2PacketsReceived = 0;
      g_decArgo_nbParm1PacketsReceived = 0;
      g_decArgo_nbParm2PacketsReceived = 0;
      g_decArgo_nbNearSurfacePacketsReceived = 0;
      g_decArgo_nbInAirPacketsReceived = 0;
      
      % clean duplicates in received data
      a_decDataTab = clean_duplicates_in_received_data(a_decDataTab, a_decoderId);
      
      % retrieve data and update counters
      for idSbd = 1:length(a_decDataTab)
         
         switch (a_decDataTab(idSbd).packType)
            
            case 0
               % technical packet #1
               o_tabTech1 = [o_tabTech1; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbTech1PacketsReceived = g_decArgo_nbTech1PacketsReceived + 1;
               
            case 4
               % technical packet #2
               o_tabTech2 = [o_tabTech2; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbTech2PacketsReceived = g_decArgo_nbTech2PacketsReceived + 1;
               
            case 1
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbDescentPacketsReceived = g_decArgo_nbDescentPacketsReceived + 1;
               
            case 2
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbParkPacketsReceived = g_decArgo_nbParkPacketsReceived + 1;
               
            case 3
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbAscentPacketsReceived = g_decArgo_nbAscentPacketsReceived + 1;
               
            case 13
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbNearSurfacePacketsReceived = g_decArgo_nbNearSurfacePacketsReceived + 1;
               
            case 14
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbInAirPacketsReceived = g_decArgo_nbInAirPacketsReceived + 1;
               
            case 5
               % parameter packet #1
               o_floatParam1 = [o_floatParam1; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbParm1PacketsReceived = g_decArgo_nbParm1PacketsReceived + 1;
               
            case 7
               % parameter packet #2
               o_floatParam2 = [o_floatParam2; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbParm2PacketsReceived = g_decArgo_nbParm2PacketsReceived + 1;
               
               if (isempty(g_decArgo_7TypePacketReceivedCyNum))
                  g_decArgo_7TypePacketReceivedCyNum = g_decArgo_cycleNum;
                  fprintf('Float #%d, Cycle #%d: ICE mode activated at cycle %d\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, ...
                     g_decArgo_7TypePacketReceivedCyNum);
               end
               
            case 6
               % EV or pump packet
               decData = a_decDataTab(idSbd).decData;
               o_evAct = [o_evAct; decData{1}{:}];
               o_pumpAct = [o_pumpAct; decData{2}{:}];
               g_decArgo_nbHydraulicPacketsReceived = g_decArgo_nbHydraulicPacketsReceived + 1;
         end
      end
      
      % BE CAREFUL (updated 01/23/2019 from NKE information)
      % there is an issue with the transmitted grounding day:
      % - when it occured during phase #2 (buoyancy reduction) it is the
      % absolute float day
      % - for all other phases, the days is relative to the beginning of the
      % current cycle and the decoded value should be:
      % mod(256 - transmitted value, 0)
      %
      % => we will set grounding day of phase #2 in relative day
      if (~isempty(o_tabTech2))
         if (any(o_tabTech2(:, 26) == 2) || any(o_tabTech2(:, 31) == 2))
            if (~isempty(o_tabTech1))
               cycleStartDateDay = o_tabTech1(1, 9);
               for idT2 = 1:size(o_tabTech2, 1)
                  tech2 = o_tabTech2(idT2, :);
                  if ((tech2(22) > 0) && (tech2(26) == 2))
                     tech2(24) = tech2(24) - cycleStartDateDay;
                  end
                  if ((tech2(22) > 1) && (tech2(31) == 2))
                     tech2(29) = tech2(29) - cycleStartDateDay;
                  end
                  o_tabTech2(idT2, :) = tech2;
               end
            end
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {214, 217}
      % Provor-ARN-DO-Ice Iridium 5.75
      % Arvor-ARN-DO-Ice Iridium 5.46
      
      g_decArgo_nbDescentPacketsReceived = 0;
      g_decArgo_nbParkPacketsReceived = 0;
      g_decArgo_nbAscentPacketsReceived = 0;
      g_decArgo_nbHydraulicPacketsReceived = 0;
      g_decArgo_nbTech1PacketsReceived = 0;
      g_decArgo_nbTech2PacketsReceived = 0;
      g_decArgo_nbParm1PacketsReceived = 0;
      g_decArgo_nbParm2PacketsReceived = 0;
      g_decArgo_nbNearSurfacePacketsReceived = 0;
      g_decArgo_nbInAirPacketsReceived = 0;
      
      % clean duplicates in received data
      a_decDataTab = clean_duplicates_in_received_data(a_decDataTab, a_decoderId);
      
      % retrieve data and update counters
      for idSbd = 1:length(a_decDataTab)
         
         switch (a_decDataTab(idSbd).packType)
            
            case 0
               % technical packet #1
               o_tabTech1 = [o_tabTech1; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbTech1PacketsReceived = g_decArgo_nbTech1PacketsReceived + 1;
               
            case 4
               % technical packet #2
               o_tabTech2 = [o_tabTech2; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbTech2PacketsReceived = g_decArgo_nbTech2PacketsReceived + 1;
               
            case 1
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbDescentPacketsReceived = g_decArgo_nbDescentPacketsReceived + 1;
               
            case 2
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbParkPacketsReceived = g_decArgo_nbParkPacketsReceived + 1;
               
            case 3
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbAscentPacketsReceived = g_decArgo_nbAscentPacketsReceived + 1;
               
            case 13
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbNearSurfacePacketsReceived = g_decArgo_nbNearSurfacePacketsReceived + 1;
               
            case 14
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbInAirPacketsReceived = g_decArgo_nbInAirPacketsReceived + 1;
               
            case 8
               % CTDO packets
               o_dataCTDO = [o_dataCTDO; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbDescentPacketsReceived = g_decArgo_nbDescentPacketsReceived + 1;
               
            case 9
               % CTDO packets
               o_dataCTDO = [o_dataCTDO; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbParkPacketsReceived = g_decArgo_nbParkPacketsReceived + 1;
               
            case 10
               % CTDO packets
               o_dataCTDO = [o_dataCTDO; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbAscentPacketsReceived = g_decArgo_nbAscentPacketsReceived + 1;
               
            case 11
               % CTDO packets
               o_dataCTDO = [o_dataCTDO; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbNearSurfacePacketsReceived = g_decArgo_nbNearSurfacePacketsReceived + 1;
               
            case 12
               % CTDO packets
               o_dataCTDO = [o_dataCTDO; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbInAirPacketsReceived = g_decArgo_nbInAirPacketsReceived + 1;
               
            case 5
               % parameter packet #1
               o_floatParam1 = [o_floatParam1; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbParm1PacketsReceived = g_decArgo_nbParm1PacketsReceived + 1;
               
            case 7
               % parameter packet #2
               o_floatParam2 = [o_floatParam2; a_decDataTab(idSbd).decData{:}];
               
               if (isempty(g_decArgo_7TypePacketReceivedCyNum))
                  g_decArgo_7TypePacketReceivedCyNum = g_decArgo_cycleNum;
                  fprintf('Float #%d, Cycle #%d: ICE mode activated at cycle %d\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, ...
                     g_decArgo_7TypePacketReceivedCyNum);
               else
                  g_decArgo_nbParm2PacketsReceived = g_decArgo_nbParm2PacketsReceived + 1;
               end
               
            case 6
               % EV or pump packet
               decData = a_decDataTab(idSbd).decData;
               o_evAct = [o_evAct; decData{1}{:}];
               o_pumpAct = [o_pumpAct; decData{2}{:}];
               g_decArgo_nbHydraulicPacketsReceived = g_decArgo_nbHydraulicPacketsReceived + 1;
         end
      end
      
      % BE CAREFUL (updated 01/23/2019 from NKE information)
      % there is an issue with the transmitted grounding day:
      % - when it occured during phase #2 (buoyancy reduction) it is the
      % absolute float day
      % - for all other phases, the days is relative to the beginning of the
      % current cycle and the decoded value should be:
      % mod(256 - transmitted value, 0)
      %
      % => we will set grounding day of phase #2 in relative day
      if (~isempty(o_tabTech2))
         if (any(o_tabTech2(:, 26) == 2) || any(o_tabTech2(:, 31) == 2))
            if (~isempty(o_tabTech1))
               cycleStartDateDay = o_tabTech1(1, 9);
               for idT2 = 1:size(o_tabTech2, 1)
                  tech2 = o_tabTech2(idT2, :);
                  if ((tech2(22) > 0) && (tech2(26) == 2))
                     tech2(24) = tech2(24) - cycleStartDateDay;
                  end
                  if ((tech2(22) > 1) && (tech2(31) == 2))
                     tech2(29) = tech2(29) - cycleStartDateDay;
                  end
                  o_tabTech2(idT2, :) = tech2;
               end
            end
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {216} % Arvor-Deep-Ice Iridium 5.65 (IFREMER version)
      
      g_decArgo_nbDescentPacketsReceived = 0;
      g_decArgo_nbParkPacketsReceived = 0;
      g_decArgo_nbAscentPacketsReceived = 0;
      g_decArgo_nbHydraulicPacketsReceived = 0;
      g_decArgo_nbTech1PacketsReceived = 0;
      g_decArgo_nbTech2PacketsReceived = 0;
      g_decArgo_nbParmPacketsReceived = 0;
      g_decArgo_nbNearSurfacePacketsReceived = 0;
      g_decArgo_nbInAirPacketsReceived = 0;
      
      % clean duplicates in received data
      a_decDataTab = clean_duplicates_in_received_data(a_decDataTab, a_decoderId);
      
      % retrieve data and update counters
      for idSbd = 1:length(a_decDataTab)
         
         switch (a_decDataTab(idSbd).packType)
            
            case 0
               % technical packet #1
               o_tabTech1 = [o_tabTech1; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbTech1PacketsReceived = g_decArgo_nbTech1PacketsReceived + 1;
               
            case 4
               % technical packet #2
               o_tabTech2 = [o_tabTech2; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbTech2PacketsReceived = g_decArgo_nbTech2PacketsReceived + 1;
               
            case 1
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbDescentPacketsReceived = g_decArgo_nbDescentPacketsReceived + 1;
               
            case 2
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbParkPacketsReceived = g_decArgo_nbParkPacketsReceived + 1;
               
            case 3
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbAscentPacketsReceived = g_decArgo_nbAscentPacketsReceived + 1;
               
            case 13
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbNearSurfacePacketsReceived = g_decArgo_nbNearSurfacePacketsReceived + 1;
               
            case 14
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbInAirPacketsReceived = g_decArgo_nbInAirPacketsReceived + 1;
               
            case 8
               % CTDO packets
               o_dataCTDO = [o_dataCTDO; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbDescentPacketsReceived = g_decArgo_nbDescentPacketsReceived + 1;
               
            case 9
               % CTDO packets
               o_dataCTDO = [o_dataCTDO; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbParkPacketsReceived = g_decArgo_nbParkPacketsReceived + 1;
               
            case 10
               % CTDO packets
               o_dataCTDO = [o_dataCTDO; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbAscentPacketsReceived = g_decArgo_nbAscentPacketsReceived + 1;
               
            case 11
               % CTDO packets
               o_dataCTDO = [o_dataCTDO; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbNearSurfacePacketsReceived = g_decArgo_nbNearSurfacePacketsReceived + 1;
               
            case 12
               % CTDO packets
               o_dataCTDO = [o_dataCTDO; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbInAirPacketsReceived = g_decArgo_nbInAirPacketsReceived + 1;
               
            case 5
               % parameter packet #1
               o_floatParam1 = [o_floatParam1; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbParmPacketsReceived = g_decArgo_nbParmPacketsReceived + 1;
               
            case 6
               % EV packet
               o_evAct = [o_evAct; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbHydraulicPacketsReceived = g_decArgo_nbHydraulicPacketsReceived + 1;
               
            case 7
               % pump packet
               o_pumpAct = [o_pumpAct; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbHydraulicPacketsReceived = g_decArgo_nbHydraulicPacketsReceived + 1;
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {218} % Arvor-Deep-Ice Iridium 5.66 (NKE version)
      
      g_decArgo_nbDescentPacketsReceived = 0;
      g_decArgo_nbParkPacketsReceived = 0;
      g_decArgo_nbAscentPacketsReceived = 0;
      g_decArgo_nbHydraulicPacketsReceived = 0;
      g_decArgo_nbTech1PacketsReceived = 0;
      g_decArgo_nbTech2PacketsReceived = 0;
      g_decArgo_nbParm1PacketsReceived = 0;
      g_decArgo_nbParm2PacketsReceived = 0;
      g_decArgo_nbNearSurfacePacketsReceived = 0;
      g_decArgo_nbInAirPacketsReceived = 0;
      
      % clean duplicates in received data
      a_decDataTab = clean_duplicates_in_received_data(a_decDataTab, a_decoderId);
      
      % retrieve data and update counters
      for idSbd = 1:length(a_decDataTab)
         
         switch (a_decDataTab(idSbd).packType)
            
            case 0
               % technical packet #1
               o_tabTech1 = [o_tabTech1; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbTech1PacketsReceived = g_decArgo_nbTech1PacketsReceived + 1;
               
            case 4
               % technical packet #2
               o_tabTech2 = [o_tabTech2; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbTech2PacketsReceived = g_decArgo_nbTech2PacketsReceived + 1;
               
            case 1
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbDescentPacketsReceived = g_decArgo_nbDescentPacketsReceived + 1;
               
            case 2
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbParkPacketsReceived = g_decArgo_nbParkPacketsReceived + 1;
               
            case 3
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbAscentPacketsReceived = g_decArgo_nbAscentPacketsReceived + 1;
               
            case 13
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbNearSurfacePacketsReceived = g_decArgo_nbNearSurfacePacketsReceived + 1;
               
            case 14
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbInAirPacketsReceived = g_decArgo_nbInAirPacketsReceived + 1;
               
            case 8
               % CTDO packets
               o_dataCTDO = [o_dataCTDO; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbDescentPacketsReceived = g_decArgo_nbDescentPacketsReceived + 1;
               
            case 9
               % CTDO packets
               o_dataCTDO = [o_dataCTDO; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbParkPacketsReceived = g_decArgo_nbParkPacketsReceived + 1;
               
            case 10
               % CTDO packets
               o_dataCTDO = [o_dataCTDO; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbAscentPacketsReceived = g_decArgo_nbAscentPacketsReceived + 1;
               
            case 11
               % CTDO packets
               o_dataCTDO = [o_dataCTDO; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbNearSurfacePacketsReceived = g_decArgo_nbNearSurfacePacketsReceived + 1;
               
            case 12
               % CTDO packets
               o_dataCTDO = [o_dataCTDO; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbInAirPacketsReceived = g_decArgo_nbInAirPacketsReceived + 1;
               
            case 5
               % parameter packet #1
               o_floatParam1 = [o_floatParam1; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbParm1PacketsReceived = g_decArgo_nbParm1PacketsReceived + 1;
               
            case 6
               % EV or pump packet
               decData = a_decDataTab(idSbd).decData;
               o_evAct = [o_evAct; decData{1}{:}];
               o_pumpAct = [o_pumpAct; decData{2}{:}];
               g_decArgo_nbHydraulicPacketsReceived = g_decArgo_nbHydraulicPacketsReceived + 1;
               
            case 7
               % parameter packet #2
               o_floatParam2 = [o_floatParam2; a_decDataTab(idSbd).decData{:}];
               
               if (isempty(g_decArgo_7TypePacketReceivedCyNum))
                  g_decArgo_7TypePacketReceivedCyNum = g_decArgo_cycleNum;
                  fprintf('Float #%d, Cycle #%d: ICE mode activated at cycle %d\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, ...
                     g_decArgo_7TypePacketReceivedCyNum);
               else
                  g_decArgo_nbParm2PacketsReceived = g_decArgo_nbParm2PacketsReceived + 1;
               end
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {221} % Arvor-Deep-Ice Iridium 5.67
      
      g_decArgo_nbDescentPacketsReceived = 0;
      g_decArgo_nbParkPacketsReceived = 0;
      g_decArgo_nbAscentPacketsReceived = 0;
      g_decArgo_nbHydraulicPacketsReceived = 0;
      g_decArgo_nbTech1PacketsReceived = 0;
      g_decArgo_nbTech2PacketsReceived = 0;
      g_decArgo_nbParm1PacketsReceived = 0;
      g_decArgo_nbParm2PacketsReceived = 0;
      g_decArgo_nbNearSurfacePacketsReceived = 0;
      g_decArgo_nbInAirPacketsReceived = 0;
      
      % clean duplicates in received data
      a_decDataTab = clean_duplicates_in_received_data(a_decDataTab, a_decoderId);
      
      % retrieve data and update counters
      for idSbd = 1:length(a_decDataTab)
         
         switch (a_decDataTab(idSbd).packType)
            
            case 0
               % technical packet #1
               o_tabTech1 = [o_tabTech1; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbTech1PacketsReceived = g_decArgo_nbTech1PacketsReceived + 1;
               
            case 4
               % technical packet #2
               o_tabTech2 = [o_tabTech2; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbTech2PacketsReceived = g_decArgo_nbTech2PacketsReceived + 1;
               
            case 1
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbDescentPacketsReceived = g_decArgo_nbDescentPacketsReceived + 1;
               
            case 2
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbParkPacketsReceived = g_decArgo_nbParkPacketsReceived + 1;
               
            case 3
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbAscentPacketsReceived = g_decArgo_nbAscentPacketsReceived + 1;
               
            case 13
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbNearSurfacePacketsReceived = g_decArgo_nbNearSurfacePacketsReceived + 1;
               
            case 14
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbInAirPacketsReceived = g_decArgo_nbInAirPacketsReceived + 1;
               
            case 8
               % CTDO packets
               o_dataCTDO = [o_dataCTDO; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbDescentPacketsReceived = g_decArgo_nbDescentPacketsReceived + 1;
               
            case 9
               % CTDO packets
               o_dataCTDO = [o_dataCTDO; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbParkPacketsReceived = g_decArgo_nbParkPacketsReceived + 1;
               
            case 10
               % CTDO packets
               o_dataCTDO = [o_dataCTDO; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbAscentPacketsReceived = g_decArgo_nbAscentPacketsReceived + 1;
               
            case 11
               % CTDO packets
               o_dataCTDO = [o_dataCTDO; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbNearSurfacePacketsReceived = g_decArgo_nbNearSurfacePacketsReceived + 1;
               
            case 12
               % CTDO packets
               o_dataCTDO = [o_dataCTDO; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbInAirPacketsReceived = g_decArgo_nbInAirPacketsReceived + 1;
               
            case 5
               % parameter packet #1
               o_floatParam1 = [o_floatParam1; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbParm1PacketsReceived = g_decArgo_nbParm1PacketsReceived + 1;
               
            case 6
               % EV or pump packet
               decData = a_decDataTab(idSbd).decData;
               o_evAct = [o_evAct; decData{1}{:}];
               o_pumpAct = [o_pumpAct; decData{2}{:}];
               g_decArgo_nbHydraulicPacketsReceived = g_decArgo_nbHydraulicPacketsReceived + 1;
               
            case 7
               % parameter packet #2
               o_floatParam2 = [o_floatParam2; a_decDataTab(idSbd).decData{:}];
               
               if (isempty(g_decArgo_7TypePacketReceivedCyNum))
                  g_decArgo_7TypePacketReceivedCyNum = g_decArgo_cycleNum;
                  fprintf('Float #%d, Cycle #%d: ICE mode activated at cycle %d\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, ...
                     g_decArgo_7TypePacketReceivedCyNum);
               else
                  g_decArgo_nbParm2PacketsReceived = g_decArgo_nbParm2PacketsReceived + 1;
               end
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {219, 220} % Arvor-C 5.3 & 5.301
      
      g_decArgo_nbAscentPacketsReceived = 0;
      g_decArgo_nbTech1PacketsReceived = 0;
      
      % clean duplicates in received data
      a_decDataTab = clean_duplicates_in_received_data(a_decDataTab, a_decoderId);
      
      % retrieve data and update counters
      for idSbd = 1:length(a_decDataTab)
         
         switch (a_decDataTab(idSbd).packType)
            
            case 0
               % technical packet #1
               o_tabTech1 = [o_tabTech1; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbTech1PacketsReceived = g_decArgo_nbTech1PacketsReceived + 1;
               
            case 1
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbAscentPacketsReceived = g_decArgo_nbAscentPacketsReceived + 1;
         end
      end
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in get_decoded_data for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return
