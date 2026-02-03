% ------------------------------------------------------------------------------
% Retrieve decoded data.
%
% SYNTAX :
% [o_tabSelfTest, o_tabTech1, o_tabTech2, o_tabEol, ...
%   o_dataDesc2Park, o_dataParkDrift, o_dataDesc2Prof, o_dataProfDrift, o_dataAsc, o_dataInAir, ...
%   o_tabConfig] = ...
%   get_decoded_data_pfv2(a_decDataTab, a_decoderId)
%
% INPUT PARAMETERS :
%   a_decodedDataTab : decoded data
%   a_decoderId      : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabSelfTest   : self test data
%   o_tabTech1      : tech #1 data
%   o_tabTech2      : tech #2 data
%   o_tabEol        : EOL data
%   o_dataDesc2Park : desc2park data
%   o_dataParkDrift : parkDrift data
%   o_dataDesc2Prof : desc2Prof data
%   o_dataProfDrift : profDrift data
%   o_dataAsc       : asc data
%   o_dataInAir     : inAir data
%   o_tabConfig     : config data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/23/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabSelfTest, o_tabTech1, o_tabTech2, o_tabEol, ...
   o_dataDesc2Park, o_dataParkDrift, o_dataDesc2Prof, o_dataProfDrift, o_dataAsc, o_dataInAir, ...
   o_tabConfig] = ...
   get_decoded_data_pfv2(a_decDataTab, a_decoderId)

% output parameters initialization
o_tabSelfTest = [];
o_tabTech1 = [];
o_tabTech2 = [];
o_tabEol = [];
o_dataDesc2Park = [];
o_dataParkDrift = [];
o_dataDesc2Prof = [];
o_dataProfDrift = [];
o_dataAsc = [];
o_dataInAir = [];
o_tabConfig = [];

% current float WMO number
global g_decArgo_floatNum;

% array to store information on received file types
global g_decArgo_nbSelfTestFileReceived;
global g_decArgo_nbTechFileReceived;
global g_decArgo_nbEolFileReceived;
global g_decArgo_nbParamFileReceived;
global g_decArgo_expectCtdDescDataFileReceivedFlag;
global g_decArgo_expectOptodeDescDataFileReceivedFlag;
global g_decArgo_expectCtdParkDriftDataFileReceivedFlag;
global g_decArgo_expectOptodeParkDriftDataFileReceivedFlag;
global g_decArgo_expectCtdDescToProfDataFileReceivedFlag;
global g_decArgo_expectOptodeDescToProfDataFileReceivedFlag;
global g_decArgo_expectCtdProfDriftDataFileReceivedFlag;
global g_decArgo_expectOptodeProfDriftDataFileReceivedFlag;
global g_decArgo_expectCtdAscDataFileReceivedFlag;
global g_decArgo_expectOptodeAscDataFileReceivedFlag;
global g_decArgo_expectCtdInAirDataFileReceivedFlag;
global g_decArgo_expectOptodeInAirDataFileReceivedFlag;


switch (a_decoderId)

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {401, 402}
      % Arvor PFV2 8.01
      % Arvor PFV2 8.02

      g_decArgo_nbSelfTestFileReceived = 0;
      g_decArgo_nbTechFileReceived = 0;
      g_decArgo_nbEolFileReceived = 0;
      g_decArgo_nbParamFileReceived = 0;
      g_decArgo_expectCtdDescDataFileReceivedFlag = 0;
      g_decArgo_expectOptodeDescDataFileReceivedFlag = 0;
      g_decArgo_expectCtdParkDriftDataFileReceivedFlag = 0;
      g_decArgo_expectOptodeParkDriftDataFileReceivedFlag = 0;
      g_decArgo_expectCtdDescToProfDataFileReceivedFlag = 0;
      g_decArgo_expectOptodeDescToProfDataFileReceivedFlag = 0;
      g_decArgo_expectCtdProfDriftDataFileReceivedFlag = 0;
      g_decArgo_expectOptodeProfDriftDataFileReceivedFlag = 0;
      g_decArgo_expectCtdAscDataFileReceivedFlag = 0;
      g_decArgo_expectOptodeAscDataFileReceivedFlag = 0;
      g_decArgo_expectCtdInAirDataFileReceivedFlag = 0;
      g_decArgo_expectOptodeInAirDataFileReceivedFlag = 0;

      % retrieve data and update counters
      for idFile = 1:size(a_decDataTab, 1)

         switch (a_decDataTab{idFile, 1})

            case 10
               % self test file
               o_tabSelfTest = [o_tabSelfTest; a_decDataTab(idFile, 5:10)];
               g_decArgo_nbSelfTestFileReceived = g_decArgo_nbSelfTestFileReceived + 1;

            case 11
               % technical #1 file
               o_tabTech1 = [o_tabTech1; a_decDataTab(idFile, 5:10)];
               g_decArgo_nbTechFileReceived = g_decArgo_nbTechFileReceived + 1;

            case 12
               % technical #2 file
               o_tabTech2 = [o_tabTech2; a_decDataTab(idFile, 5:10)];
               g_decArgo_nbTechFileReceived = g_decArgo_nbTechFileReceived + 1;

            case 13
               % eol file
               o_tabEol = [o_tabEol; a_decDataTab(idFile, 5:10)];
               g_decArgo_nbEolFileReceived = g_decArgo_nbEolFileReceived + 1;

            case 20
               % desc2Park file
               o_dataDesc2Park = [o_dataDesc2Park; a_decDataTab(idFile, 5:7)];
               if (a_decDataTab{idFile, 5} == 2)
                  g_decArgo_expectOptodeDescDataFileReceivedFlag = 1;
               else
                  g_decArgo_expectCtdDescDataFileReceivedFlag = 1;
               end

            case 21
               % parkDrift file
               o_dataParkDrift = [o_dataParkDrift; a_decDataTab(idFile, 5:7)];
               if (a_decDataTab{idFile, 5} == 2)
                  g_decArgo_expectOptodeParkDriftDataFileReceivedFlag = 1;
               else
                  g_decArgo_expectCtdParkDriftDataFileReceivedFlag = 1;
               end

            case 22
               % desc2Prof file
               o_dataDesc2Prof = [o_dataDesc2Prof; a_decDataTab(idFile, 5:7)];
               if (a_decDataTab{idFile, 5} == 2)
                  g_decArgo_expectOptodeDescToProfDataFileReceivedFlag = 1;
               else
                  g_decArgo_expectCtdDescToProfDataFileReceivedFlag = 1;
               end

            case 23
               % profDrift file
               o_dataProfDrift = [o_dataProfDrift; a_decDataTab(idFile, 5:7)];
               if (a_decDataTab{idFile, 5} == 2)
                  g_decArgo_expectOptodeProfDriftDataFileReceivedFlag = 1;
               else
                  g_decArgo_expectCtdProfDriftDataFileReceivedFlag = 1;
               end

            case 24
               % asc file
               o_dataAsc = [o_dataAsc; a_decDataTab(idFile, 5:7)];
               if (a_decDataTab{idFile, 5} == 2)
                  g_decArgo_expectOptodeAscDataFileReceivedFlag = 1;
               else
                  g_decArgo_expectCtdAscDataFileReceivedFlag = 1;
               end

            case 25
               % inAir
               o_dataInAir = [o_dataInAir; a_decDataTab(idFile, 5:7)];
               if (a_decDataTab{idFile, 5} == 2)
                  g_decArgo_expectOptodeInAirDataFileReceivedFlag = 1;
               else
                  g_decArgo_expectCtdInAirDataFileReceivedFlag = 1;
               end

            case 30
               % config
               o_tabConfig = [o_tabConfig; a_decDataTab(idFile, [5, 6, 10])];
               g_decArgo_nbParamFileReceived = g_decArgo_nbParamFileReceived + 1;

            case 40
               % command
               % not managed

         end
      end

   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in get_decoded_data_pfv2 for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return
