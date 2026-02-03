% ------------------------------------------------------------------------------
% Store information on received file types.
%
% SYNTAX :
%   [o_tabNcTechIndex, o_tabNcTechVal] = ...
%     store_received_file_type_info_for_nc_pfv2(a_deepCycleFlag, a_tabNcTechIndex, a_tabNcTechVal)
%
% INPUT PARAMETERS :
%   a_deepCycleFlagFlag : deep cycle flag
%   a_tabNcTechIndex    : input NC TECH Ids
%   a_tabNcTechVal      : input NC TECH values
%
% OUTPUT PARAMETERS :
%   o_tabNcTechIndex : output NC TECH Ids
%   o_tabNcTechVal   : output NC TECH values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/07/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabNcTechIndex, o_tabNcTechVal] = ...
   store_received_file_type_info_for_nc_pfv2(a_deepCycleFlag, a_tabNcTechIndex, a_tabNcTechVal)

% output parameters initialization
o_tabNcTechIndex = a_tabNcTechIndex;
o_tabNcTechVal = a_tabNcTechVal;

% current cycle number
global g_decArgo_cycleNum;

% sensor list
global g_decArgo_sensorMountedOnFloat;

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


if (g_decArgo_nbSelfTestFileReceived > 0)
   o_tabNcTechIndex = [o_tabNcTechIndex;
      g_decArgo_cycleNum 1000];
   o_tabNcTechVal{end+1, 1} = g_decArgo_nbSelfTestFileReceived;
end

o_tabNcTechIndex = [o_tabNcTechIndex;
   g_decArgo_cycleNum 1001];
o_tabNcTechVal{end+1, 1} = g_decArgo_nbTechFileReceived;

if (g_decArgo_nbEolFileReceived > 0)
   o_tabNcTechIndex = [o_tabNcTechIndex;
      g_decArgo_cycleNum 1002];
   o_tabNcTechVal{end+1, 1} = g_decArgo_nbEolFileReceived;
end

if (g_decArgo_nbParamFileReceived > 0)
   o_tabNcTechIndex = [o_tabNcTechIndex;
      g_decArgo_cycleNum 1003];
   o_tabNcTechVal{end+1, 1} = g_decArgo_nbParamFileReceived;
end

o_tabNcTechIndex = [o_tabNcTechIndex;
   g_decArgo_cycleNum 1017];
o_tabNcTechVal{end+1, 1} = a_deepCycleFlag;

% retrieve configuration information
[configNames, configValues] = get_float_config_pfv2(g_decArgo_cycleNum);

iceCapabilityEnableFlag = get_config_value_pfv2_3('ICE.P0', configNames, configValues);
if (~isempty(iceCapabilityEnableFlag))
   o_tabNcTechIndex = [o_tabNcTechIndex;
      g_decArgo_cycleNum 1016];
   o_tabNcTechVal{end+1, 1} = iceCapabilityEnableFlag;
end

if (ismember('CTD_RBR', g_decArgo_sensorMountedOnFloat))
   ctdNum = 3;
else
   ctdNum = 1;
end
if (ismember('OPTODE', g_decArgo_sensorMountedOnFloat))
   optodeFlag = 1;
else
   optodeFlag = 0;
end

% one loop for CTD, one loop for optode
for idLoop = 1:2
   if ((idLoop == 2) && (optodeFlag == 0))
      continue
   end
   if (idLoop == 1)
      sensorNum = ctdNum;
   else
      sensorNum = 2;
   end

   configName = sprintf('SENSORS-SENSOR%02d-IN_AIR.P0', sensorNum);
   inAirAcqFlag = get_config_value_pfv2_3(configName, configNames, configValues);
   if (~isempty(inAirAcqFlag))
      if (inAirAcqFlag == 1)
         if (idLoop == 1)
            o_tabNcTechIndex = [o_tabNcTechIndex;
               g_decArgo_cycleNum 1014];
            o_tabNcTechVal{end+1, 1} = g_decArgo_expectCtdInAirDataFileReceivedFlag;
         else
            o_tabNcTechIndex = [o_tabNcTechIndex;
               g_decArgo_cycleNum 1015];
            o_tabNcTechVal{end+1, 1} = g_decArgo_expectOptodeInAirDataFileReceivedFlag;
         end
      end
   end

   if (a_deepCycleFlag)

      configName = sprintf('SENSORS-SENSOR%02d-DESCENT.P0', sensorNum);
      descAcqFlag = get_config_value_pfv2_3(configName, configNames, configValues);
      if (~isempty(descAcqFlag))
         if (descAcqFlag == 1)
            if (idLoop == 1)
               o_tabNcTechIndex = [o_tabNcTechIndex;
                  g_decArgo_cycleNum 1004];
               o_tabNcTechVal{end+1, 1} = g_decArgo_expectCtdDescDataFileReceivedFlag;
            else
               o_tabNcTechIndex = [o_tabNcTechIndex;
                  g_decArgo_cycleNum 1005];
               o_tabNcTechVal{end+1, 1} = g_decArgo_expectOptodeDescDataFileReceivedFlag;
            end
         end
      end

      configName = sprintf('SENSORS-SENSOR%02d-PARK_DRIFT.P0', sensorNum);
      parkDriftSampPeriod = get_config_value_pfv2_3(configName, configNames, configValues);
      if (~isempty(parkDriftSampPeriod))
         if (parkDriftSampPeriod > 0)
            if (idLoop == 1)
               o_tabNcTechIndex = [o_tabNcTechIndex;
                  g_decArgo_cycleNum 1006];
               o_tabNcTechVal{end+1, 1} = g_decArgo_expectCtdParkDriftDataFileReceivedFlag;
            else
               o_tabNcTechIndex = [o_tabNcTechIndex;
                  g_decArgo_cycleNum 1007];
               o_tabNcTechVal{end+1, 1} = g_decArgo_expectOptodeParkDriftDataFileReceivedFlag;
            end
         end
      end

      configName = sprintf('SENSORS-SENSOR%02d-DESCENT.P1', sensorNum);
      descToProfAcqFlag = get_config_value_pfv2_3(configName, configNames, configValues);
      if (~isempty(descToProfAcqFlag))
         if (descToProfAcqFlag == 1)
            if (idLoop == 1)
               o_tabNcTechIndex = [o_tabNcTechIndex;
                  g_decArgo_cycleNum 1008];
               o_tabNcTechVal{end+1, 1} = g_decArgo_expectCtdDescToProfDataFileReceivedFlag;
            else
               o_tabNcTechIndex = [o_tabNcTechIndex;
                  g_decArgo_cycleNum 1009];
               o_tabNcTechVal{end+1, 1} = g_decArgo_expectOptodeDescToProfDataFileReceivedFlag;
            end
         end
      end

      configName = sprintf('SENSORS-SENSOR%02d-PROF_DRIFT.P0', sensorNum);
      profDriftSampPeriod = get_config_value_pfv2_3(configName, configNames, configValues);
      if (~isempty(profDriftSampPeriod))
         if (profDriftSampPeriod > 0)
            if (idLoop == 1)
               o_tabNcTechIndex = [o_tabNcTechIndex;
                  g_decArgo_cycleNum 1010];
               o_tabNcTechVal{end+1, 1} = g_decArgo_expectCtdProfDriftDataFileReceivedFlag;
            else
               o_tabNcTechIndex = [o_tabNcTechIndex;
                  g_decArgo_cycleNum 1011];
               o_tabNcTechVal{end+1, 1} = g_decArgo_expectOptodeProfDriftDataFileReceivedFlag;
            end
         end
      end

      configName = sprintf('SENSORS-SENSOR%02d-ASCENT.P0', sensorNum);
      ascAcqFlag = get_config_value_pfv2_3(configName, configNames, configValues);
      if (~isempty(ascAcqFlag))
         if (ascAcqFlag == 1)
            if (idLoop == 1)
               o_tabNcTechIndex = [o_tabNcTechIndex;
                  g_decArgo_cycleNum 1012];
               o_tabNcTechVal{end+1, 1} = g_decArgo_expectCtdAscDataFileReceivedFlag;
            else
               o_tabNcTechIndex = [o_tabNcTechIndex;
                  g_decArgo_cycleNum 1013];
               o_tabNcTechVal{end+1, 1} = g_decArgo_expectOptodeAscDataFileReceivedFlag;
            end
         end
      end
   end
end

return
