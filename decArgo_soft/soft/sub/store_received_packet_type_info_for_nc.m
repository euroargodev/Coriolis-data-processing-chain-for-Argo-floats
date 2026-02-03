% ------------------------------------------------------------------------------
% Store information on received Iridium packet types.
%
% SYNTAX :
%  store_received_packet_type_info_for_nc(a_decoderId, a_deepCycleFlag)
%
% INPUT PARAMETERS :
%   a_decoderId     : decoder Id
%   a_deepCycleFlagFlag : deep cycle flag
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/29/2017 - RNU - creation
% ------------------------------------------------------------------------------
function store_received_packet_type_info_for_nc(a_decoderId, a_deepCycleFlag)

% current cycle number
global g_decArgo_cycleNum;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% array to store statistics on received packets
global g_decArgo_nbDescentPacketsReceived;
global g_decArgo_nbDescent3TPacketsReceived;
global g_decArgo_nbDescent2TPacketsReceived;
global g_decArgo_nbParkPacketsReceived;
global g_decArgo_nbPark3TPacketsReceived;
global g_decArgo_nbPark2TPacketsReceived;
global g_decArgo_nbAscentPacketsReceived;
global g_decArgo_nbAscent3TPacketsReceived;
global g_decArgo_nbAscent2TPacketsReceived;
global g_decArgo_nbNearSurfacePacketsReceived;
global g_decArgo_nbInAirPacketsReceived;
global g_decArgo_nbHydraulicPacketsReceived;
global g_decArgo_nbTechPacketsReceived;
global g_decArgo_nbTech1PacketsReceived;
global g_decArgo_nbTech2PacketsReceived;
global g_decArgo_nbTech3TPacketsReceived;
global g_decArgo_nbTech2TPacketsReceived;
global g_decArgo_nbParamPacketsReceived;
global g_decArgo_nbParam3TPacketsReceived;
global g_decArgo_nbParam2TPacketsReceived;
global g_decArgo_nbParam1PacketsReceived;
global g_decArgo_nbParam2PacketsReceived;

% to detect ICE mode activation (first cycle for which parameter packet #2 has
% been received)
global g_decArgo_7TypePacketReceivedCyNum;


switch (a_decoderId)
   
   case {201, 202, 203}

      if (a_deepCycleFlag == 1)
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 1001];
         g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbDescentPacketsReceived;

         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 1002];
         g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParkPacketsReceived;

         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 1003];
         g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbAscentPacketsReceived;
      end

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
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParamPacketsReceived;
      
   case {204, 205, 206, 207, 208, 209}
      
      if (a_deepCycleFlag == 1)
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 1001];
         g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbDescentPacketsReceived;

         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 1002];
         g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParkPacketsReceived;

         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 1003];
         g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbAscentPacketsReceived;
      end

      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1004];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbTechPacketsReceived;

      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1005];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParamPacketsReceived;
      
   case {210, 211, 213}
      
      if (a_deepCycleFlag == 1)
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
      end
      
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
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParamPacketsReceived;
      
   case {212, 222, 214, 217, 223, 224, 225, 226, 227, 231, 232}

      if (a_deepCycleFlag == 1)
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
      end
      
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
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParam1PacketsReceived;
      
      if (~isempty(g_decArgo_7TypePacketReceivedCyNum))
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 1010];
         g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParam2PacketsReceived;
      end
      
   case {215}
      
      if (a_deepCycleFlag == 1)
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
            g_decArgo_cycleNum 1008];
         g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbNearSurfacePacketsReceived;
      end

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
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParamPacketsReceived;

      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1009];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbInAirPacketsReceived;
      
   case {216}

      if (a_deepCycleFlag == 1)
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
            g_decArgo_cycleNum 1008];
         g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbNearSurfacePacketsReceived;
      end

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
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParamPacketsReceived;      
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1009];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbInAirPacketsReceived;   
      
   case {218, 221, 230}

      if (a_deepCycleFlag == 1)
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
            g_decArgo_cycleNum 1008];
         g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbNearSurfacePacketsReceived;
      end

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
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParam1PacketsReceived;      
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1009];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbInAirPacketsReceived;
      
      if (~isempty(g_decArgo_7TypePacketReceivedCyNum))
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 1016];
         g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParam2PacketsReceived;
      end
      
   case {219, 220}

      if (a_deepCycleFlag == 1)
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 1000];
         g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbAscentPacketsReceived;
      end

   case {228}

      if (a_deepCycleFlag == 1)
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 1001];
         if (g_decArgo_nbDescent3TPacketsReceived ~= 0)
            g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbDescent3TPacketsReceived;
         else
            g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbDescentPacketsReceived;
         end

         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 1002];
         if (g_decArgo_nbPark3TPacketsReceived ~= 0)
            g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbPark3TPacketsReceived;
         else
            g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParkPacketsReceived;
         end

         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 1003];
         if (g_decArgo_nbAscent3TPacketsReceived ~= 0)
            g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbAscent3TPacketsReceived;
         else
            g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbAscentPacketsReceived;
         end
      end
      
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
         g_decArgo_cycleNum 1008];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbTech3TPacketsReceived;

      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1007];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParamPacketsReceived; 

      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1009];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParam3TPacketsReceived;      
            
   case {229}

      if (a_deepCycleFlag == 1)
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 1001];
         if (g_decArgo_nbDescent2TPacketsReceived ~= 0)
            g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbDescent2TPacketsReceived;
         else
            g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbDescentPacketsReceived;
         end

         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 1002];
         if (g_decArgo_nbPark2TPacketsReceived ~= 0)
            g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbPark2TPacketsReceived;
         else
            g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParkPacketsReceived;
         end

         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 1003];
         if (g_decArgo_nbAscent2TPacketsReceived ~= 0)
            g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbAscent2TPacketsReceived;
         else
            g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbAscentPacketsReceived;
         end
      end

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
         g_decArgo_cycleNum 1008];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbTech2TPacketsReceived;

      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1007];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParamPacketsReceived; 

      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1009];
      g_decArgo_outputNcParamValue{end+1} = g_decArgo_nbParam2TPacketsReceived; 

   otherwise
      fprintf('WARNING: Received packet type information is not defined yet for decoderId #%d\n', a_decoderId);
end

return
