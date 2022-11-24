% ------------------------------------------------------------------------------
% Store information on received Iridium packet types.
%
% SYNTAX :
%  store_received_packet_type_info_for_nc(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : decoder Id
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/29/2017 - RNU - creation
% ------------------------------------------------------------------------------
function store_received_packet_type_info_for_nc(a_decoderId)

% current cycle number
global g_decArgo_cycleNum;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% array ro store statistics on received packets
global g_decArgo_nbDescentPacketsReceived;
global g_decArgo_nbParkPacketsReceived;
global g_decArgo_nbAscentPacketsReceived;
global g_decArgo_nbNearSurfacePacketsReceived;
global g_decArgo_nbInAirPacketsReceived;
global g_decArgo_nbHydraulicPacketsReceived;
global g_decArgo_nbTechPacketsReceived;
global g_decArgo_nbTech1PacketsReceived;
global g_decArgo_nbTech2PacketsReceived;
global g_decArgo_nbParmPacketsReceived;
global g_decArgo_nbParm1PacketsReceived;
global g_decArgo_nbParm2PacketsReceived;

% to detect ICE mode activation (first cycle for which parameter packet #2 has
% been received)
global g_decArgo_7TypePacketReceivedCyNum;


switch (a_decoderId)
   
   case {201, 202, 203}
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1001];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbDescentPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1002];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParkPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1003];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbAscentPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1004];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbHydraulicPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1005];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbTech1PacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1006];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbTech2PacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1007];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParmPacketsReceived;
      
   case {204, 205, 206, 207, 208, 209}
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1001];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbDescentPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1002];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParkPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1003];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbAscentPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1004];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbTechPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1005];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParmPacketsReceived;
      
   case {210, 211, 213}
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1001];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbDescentPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1002];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParkPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1003];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbAscentPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1004];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbNearSurfacePacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1005];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbInAirPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1006];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbHydraulicPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1007];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbTech1PacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1008];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbTech2PacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1009];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParmPacketsReceived;
      
   case {212, 214, 217}
               
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1001];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbDescentPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1002];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParkPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1003];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbAscentPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1004];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbNearSurfacePacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1005];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbInAirPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1006];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbHydraulicPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1007];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbTech1PacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1008];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbTech2PacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1009];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParm1PacketsReceived;
      
      if (~isempty(g_decArgo_7TypePacketReceivedCyNum))
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 1010];
         g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParm2PacketsReceived;
      end
      
   case {215}
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1001];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbDescentPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1002];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParkPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1003];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbAscentPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1004];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbHydraulicPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1005];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbTech1PacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1006];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbTech2PacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1007];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParmPacketsReceived;      
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1008];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbNearSurfacePacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1009];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbInAirPacketsReceived;
      
   case {216}

      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1001];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbDescentPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1002];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParkPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1003];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbAscentPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1004];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbHydraulicPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1005];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbTech1PacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1006];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbTech2PacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1007];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParmPacketsReceived;      
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1008];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbNearSurfacePacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1009];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbInAirPacketsReceived;   
      
   case {218, 221}

      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1001];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbDescentPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1002];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParkPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1003];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbAscentPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1004];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbHydraulicPacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1005];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbTech1PacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1006];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbTech2PacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1007];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParm1PacketsReceived;      
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1008];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbNearSurfacePacketsReceived;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1009];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbInAirPacketsReceived;
      
      if (~isempty(g_decArgo_7TypePacketReceivedCyNum))
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 1016];
         g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParm2PacketsReceived;
      end
      
   case {219, 220}

      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1000];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbAscentPacketsReceived;      
      
   otherwise
      fprintf('WARNING: Received packet type information is not defined yet for decoderId #%d\n', a_decoderId);
end

return
