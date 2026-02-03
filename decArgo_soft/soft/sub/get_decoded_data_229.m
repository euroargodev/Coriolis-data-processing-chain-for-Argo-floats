% ------------------------------------------------------------------------------
% Retrieve decoded data.
%
% SYNTAX :
% [o_tabTech1, o_tabTech2, o_tabTech2T, ...
%   o_dataCTD, o_dataCTD2T, ...
%   o_evAct, o_pumpAct, ...
%   o_floatParam, o_floatParam2T] = ...
%   get_decoded_data_229(a_decDataTab, a_decoderId)
%
% INPUT PARAMETERS :
%   a_decodedDataTab : decoded data
%   a_decoderId      : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabTech1     : tech #1 packet data
%   o_tabTech2     : tech #2 packet data
%   o_tabTech2T    : tech packet data dedicated to 2T prototype
%   o_dataCTD      : CTD packet data
%   o_dataCTD2T    : CTD packet data dedicated to 2T prototype
%   o_evAct        : hydraulic (valve) packet data
%   o_pumpAct      : hydraulic (pump) packet data
%   o_floatParam   : prog param packet data
%   o_floatParam2T : prog param packet data dedicated to 2T prototype
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTech1, o_tabTech2, o_tabTech2T, ...
   o_dataCTD, o_dataCTD2T, ...
   o_evAct, o_pumpAct, ...
   o_floatParam, o_floatParam2T] = ...
   get_decoded_data_229(a_decDataTab, a_decoderId)

% output parameters initialization
o_tabTech1 = [];
o_tabTech2 = [];
o_tabTech2T = [];
o_dataCTD = [];
o_dataCTD2T = [];
o_evAct = [];
o_pumpAct = [];
o_floatParam = [];
o_floatParam2T = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% array to store statistics on received packets
global g_decArgo_nbDescentPacketsReceived;
global g_decArgo_nbDescent2TPacketsReceived;
global g_decArgo_nbParkPacketsReceived;
global g_decArgo_nbAscentPacketsReceived;
global g_decArgo_nbAscent2TPacketsReceived;
global g_decArgo_nbNearSurfacePacketsReceived;
global g_decArgo_nbInAirPacketsReceived;
global g_decArgo_nbHydraulicPacketsReceived;
global g_decArgo_nbTech1PacketsReceived;
global g_decArgo_nbTech2PacketsReceived;
global g_decArgo_nbTech2TPacketsReceived;
global g_decArgo_nbParamPacketsReceived;
global g_decArgo_nbParam2TPacketsReceived;


switch (a_decoderId)

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {229} % Arvor-Deep-Ice Iridium 5.69 (2T prototype)

      g_decArgo_nbDescentPacketsReceived = 0;
      g_decArgo_nbDescent2TPacketsReceived = 0;
      g_decArgo_nbParkPacketsReceived = 0;
      g_decArgo_nbAscentPacketsReceived = 0;
      g_decArgo_nbAscent2TPacketsReceived = 0;
      g_decArgo_nbNearSurfacePacketsReceived = 0;
      g_decArgo_nbInAirPacketsReceived = 0;
      g_decArgo_nbHydraulicPacketsReceived = 0;
      g_decArgo_nbTech1PacketsReceived = 0;
      g_decArgo_nbTech2PacketsReceived = 0;
      g_decArgo_nbTech2TPacketsReceived = 0;
      g_decArgo_nbParamPacketsReceived = 0;
      g_decArgo_nbParam2TPacketsReceived = 0;

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

            case 26
               % technical packet dedicated to 2T prototype
               o_tabTech2T = [o_tabTech2T; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbTech2TPacketsReceived = g_decArgo_nbTech2TPacketsReceived + 1;

            case 1
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbDescentPacketsReceived = g_decArgo_nbDescentPacketsReceived + 1;

            case 28
               % CTD 2T packets
               o_dataCTD2T = [o_dataCTD2T; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbDescent2TPacketsReceived = g_decArgo_nbDescent2TPacketsReceived + 1;

            case 2
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbParkPacketsReceived = g_decArgo_nbParkPacketsReceived + 1;

            case 3
               % CTD packets
               o_dataCTD = [o_dataCTD; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbAscentPacketsReceived = g_decArgo_nbAscentPacketsReceived + 1;

            case 29
               % CTD 2T packets
               o_dataCTD2T = [o_dataCTD2T; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbAscent2TPacketsReceived = g_decArgo_nbAscent2TPacketsReceived + 1;

            case 5
               % parameter packet
               o_floatParam = [o_floatParam; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbParamPacketsReceived = g_decArgo_nbParamPacketsReceived + 1;

            case 27
               % parameter 2T packet
               o_floatParam2T = [o_floatParam2T; a_decDataTab(idSbd).decData{:}];
               g_decArgo_nbParam2TPacketsReceived = g_decArgo_nbParam2TPacketsReceived + 1;

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

   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in get_decoded_data_229 for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return
