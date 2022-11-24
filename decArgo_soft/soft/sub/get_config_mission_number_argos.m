% ------------------------------------------------------------------------------
% Get the config mission number associated with the cycle number.
%
% SYNTAX :
%  [o_configMissionNumber] = get_config_mission_number_argos( ...
%    a_cycleNum, a_repRateMetaData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_cycleNum        : current cycle number
%   a_repRateMetaData : repetition rate information from json meta-data file
%   a_decoderId       : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_configMissionNumber : configuration mission number
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/21/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configMissionNumber] = get_config_mission_number_argos( ...
   a_cycleNum, a_repRateMetaData, a_decoderId)

% output parameters initialization
o_configMissionNumber = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% float configuration
global g_decArgo_floatConfig;


switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % NKE floats
   case {1, 3, 4, 11, 12, 17, 19, 24, 25, 27, 28, 29, 31}
      
      % compute the configuration mission number
      if (~isempty(a_repRateMetaData))
         if ((a_cycleNum == 0) || ...
               ((a_cycleNum == 1) && (get_default_prelude_duration(a_decoderId) ~= 0)))
            o_configMissionNumber = 1;
         else
            repRateMetaData = a_repRateMetaData{2};
            if (size(repRateMetaData, 2) == 1)
               o_configMissionNumber = 2;
            else
               sumRepRate = 0;
               for idRep = 1:length(repRateMetaData)
                  sumRepRate = sumRepRate + ...
                     str2num(getfield(repRateMetaData{idRep}, char(fieldnames(repRateMetaData{idRep}))));
               end
               if (rem(a_cycleNum, sumRepRate) ~= 0)
                  o_configMissionNumber = 2;
               else
                  o_configMissionNumber = 3;
               end
            end
         end
      end
      
   case {30, 32}
      
      % retrieve the configuration mission number
      
      % search the concerned cycle configuration
      idUsedConf = find(g_decArgo_floatConfig.USE.CYCLE == a_cycleNum);
      
      if (isempty(idUsedConf))
         
         fprintf('WARNING: Float #%d: config missing for cycle #%d\n', ...
            g_decArgo_floatNum, a_cycleNum);
         return;
      end
      
      % retrieve the number of the concerned configuration
      o_configMissionNumber = unique(g_decArgo_floatConfig.USE.CONFIG(idUsedConf));
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % APEX floats
   case {1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011, ...
         1012, 1013, 1014, 1015, 1016, 1021, 1022}
      
      % 1 - DPF = yes and N = 1 (2 configurations):
      %     - config #1: cycle duration reduced, profile pres = TP
      %     - config #2: cycle duration = CT, profile pres = TP
      % 2 - DPF = yes and N > 1 and N ~= 234/254 (3 configurations):
      %     - config #1: cycle duration reduced, profile pres = TP
      %     - config #2: cycle duration = CT, profile pres = PRKP
      %     - config #3: cycle duration = CT, profile pres = TP
      % 3 - DPF = yes and N = 234/254 (2 configurations):
      %     - config #1: cycle duration reduced, profile pres = TP
      %     - config #2: cycle duration = CT, profile pres = PRKP
      % 4 - DPF = no and N = 1 (1 configuration):
      %     - config #1: cycle duration = CT, profile pres = TP
      % 5 - DPF = no and N > 1 and N ~= 234/254 (2 configurations):
      %     - config #1: cycle duration = CT, profile pres = PRKP
      %     - config #2: cycle duration = CT, profile pres = TP
      % 6 - DPF = no and N = 234/254 (1 configuration):
      %     - config #1: cycle duration = CT, profile pres = PRKP
      
      % retrieve configuration parameters
      a_timeData = a_repRateMetaData;
      
      dpfFloatFlag = a_timeData.configParam.dpfFloatFlag;
      parkAndProfileCycleLength = a_timeData.configParam.parkAndProfileCycleLength;
      
      if ~(isempty(dpfFloatFlag) || isempty(parkAndProfileCycleLength))
         if (dpfFloatFlag == 1)
            if ((parkAndProfileCycleLength == 1) || (parkAndProfileCycleLength == get_park_and_prof_specific_value(a_decoderId)))
               if (a_cycleNum <= 1)
                  o_configMissionNumber = 1;
               else
                  o_configMissionNumber = 2;
               end
            else
               if (a_cycleNum <= 1)
                  o_configMissionNumber = 1;
               else
                  if (rem(a_cycleNum, parkAndProfileCycleLength) == 0)
                     o_configMissionNumber = 3;
                  else
                     o_configMissionNumber = 2;
                  end
               end
            end
         else
            if ((parkAndProfileCycleLength == 1) || (parkAndProfileCycleLength == get_park_and_prof_specific_value(a_decoderId)))
               o_configMissionNumber = 1;
            else
               if (rem(a_cycleNum, parkAndProfileCycleLength) == 0)
                  o_configMissionNumber = 2;
               else
                  o_configMissionNumber = 1;
               end
            end
         end
      else
         fprintf('WARNING: Float #%d Cycle #%d: config mission number cannot be computed\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
      end
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing done yet in get_config_mission_number_argos for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
      
end

return;

% ------------------------------------------------------------------------------
% Get the park and profile specific value (that causes all profiles to start at
% park depth) for a given decoder.
%
% SYNTAX :
%  [o_specificValue] = get_park_and_prof_specific_value(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_specificValue : PnP specific value for this decoder Id
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/21/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_specificValue] = get_park_and_prof_specific_value(a_decoderId)

% output parameters initialization
o_specificValue = [];

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   case {1001, 1005, 1007, 1009, 1010, 1011, 1012, 1015, 1016}
      % 071412, 061810, 082213, 032213, 110613&090413, 121512, 110813, 020110,
      % 090810
      o_specificValue = 234;
      
   case {1002, 1003, 1004, 1006, 1008, 1013, 1014}
      % 062608, 061609, 021009, 093008, 021208, 071807, 082807
      o_specificValue = 254;
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing done yet in get_park_and_prof_specific_value for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
      
end

return;
