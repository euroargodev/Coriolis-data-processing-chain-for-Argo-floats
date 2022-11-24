% ------------------------------------------------------------------------------
% Compute APEX cycle times.
%
% SYNTAX :
%  [o_timeData] = compute_apx_times(a_timeData, a_timeInfo, a_cycleNum, ...
%    a_argosDataData, a_argosDataUsed, a_argosDataDate, ...
%    a_cycleSurfData, a_decoderId, a_finalStep)
%
% INPUT PARAMETERS :
%   a_timeData      : input cycle time data structure
%   a_timeInfo      : decoded time information
%   a_cycleNum      : cycle number
%   a_argosDataData : Argos received message data
%   a_argosDataUsed : Argos used message data
%   a_argosDataDate : Argos received message dates
%   a_cycleSurfData : cycle surface information
%   a_decoderId     : float decoder Id
%   a_finalStep     : final step flag
%
% OUTPUT PARAMETERS :
%   o_timeData : updated cycle time data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_timeData] = compute_apx_times(a_timeData, a_timeInfo, a_cycleNum, ...
   a_argosDataData, a_argosDataUsed, a_argosDataDate, ...
   a_cycleSurfData, a_decoderId, a_finalStep)

% output parameters initialization
o_timeData = a_timeData;

% global time status
global g_JULD_STATUS_1;
global g_JULD_STATUS_2;
global g_JULD_STATUS_3;

% default values
global g_decArgo_dateDef;

VERBOSE = 0;


% retrieve current cycle times
idCycleStruct = find([o_timeData.cycleNum] == a_cycleNum);
if (isempty(idCycleStruct))
   
   % add a new one
   cycleTimeStruct = get_apx_cycle_time_init_struct;
   o_timeData.cycleNum = [o_timeData.cycleNum a_cycleNum];
   o_timeData.cycleTime = [o_timeData.cycleTime cycleTimeStruct];
   
   idCycleStruct = length([o_timeData.cycleTime]);
else
   cycleTimeStruct = o_timeData.cycleTime(idCycleStruct);
end

% store Argos times
cycleTimeStruct.firstMsgTime = a_cycleSurfData.firstMsgTime;
cycleTimeStruct.lastMsgTime = a_cycleSurfData.lastMsgTime;

% store decoded times
if (a_cycleNum == 0)
   
   [~, o_timeData.clockOffsetAtLaunchRefDate] = find_struct(a_timeInfo, 'label', 'clockOffsetRefDate', 'value');
   [~, o_timeData.clockOffsetAtLaunch] = find_struct(a_timeInfo, 'label', 'clockOffset', 'value');
   
   % the following ones have already been initialized (in
   % create_float_config_apx_argos) from configuration (meta json + test msg)
   %    [~, o_timeData.configParam.parkingPres] = find_struct(a_timeInfo, 'label', 'parkingPres', 'value');
   %    [~, o_timeData.configParam.profilePres] = find_struct(a_timeInfo, 'label', 'profilePres', 'value');
   %    [~, o_timeData.configParam.parkAndProfileCycleLength] = find_struct(a_timeInfo, 'label', 'parkAndProfileCycleLength', 'value');
   %    [~, o_timeData.configParam.deepProfileDescentPeriod] = find_struct(a_timeInfo, 'label', 'deepProfileDescentPeriod', 'value');
   
   % elseif (a_cycleNum < 7) || (a_cycleNum == 12)

else
   [~, downTimeEnd] = find_struct(a_timeInfo, 'label', 'downTimeEnd', 'value');
   if (~isempty(downTimeEnd))
      cycleTimeStruct.downTimeEndFloat = downTimeEnd;
      cycleTimeStruct.downTimeEndFloatStatus = g_JULD_STATUS_2;     
   end
   [~, transStartDateFromFloat] = find_struct(a_timeInfo, 'label', 'transStartDateFromFloat', 'value');
   if (~isempty(transStartDateFromFloat))
      cycleTimeStruct.transStartTimeFloat = transStartDateFromFloat;
      cycleTimeStruct.transStartTimeFloatStatus = g_JULD_STATUS_3;
   end
   [~, tpi] = find_struct(a_timeInfo, 'label', 'tpi', 'value');
   if (~isempty(tpi))
      cycleTimeStruct.timeOfProfileInit = tpi;
   end
   
   if (~isempty(downTimeEnd) && ~isempty(tpi))
      cycleTimeStruct.ascentStartTimeFloat = downTimeEnd + tpi;
      cycleTimeStruct.ascentStartTimeFloatStatus = g_JULD_STATUS_3;
   end
end

if (a_cycleNum > 0)
   
   % compute TST from float transmission strategy
   [tabTst1, tabTst2] = compute_apx_TST( ...
      a_argosDataData, a_argosDataUsed, a_argosDataDate, o_timeData.configParam, a_decoderId);
   if (~isempty(tabTst1))
      [cycleTimeStruct.transStartTime1, ~] = select_a_value(tabTst1);
   end
   if (~isempty(tabTst2))
      [cycleTimeStruct.transStartTime2, ~] = select_a_value(tabTst2);
   end
   
   if (VERBOSE)
      uTst1 = unique(tabTst1(find(tabTst1 ~= g_decArgo_dateDef)));
      uTst2 = unique(tabTst2(find(tabTst2 ~= g_decArgo_dateDef)));
      if ((~isempty(uTst1) && (length(uTst1) > 1)) || ...
            (~isempty(uTst1) && (length(uTst2) > 1) )|| ...
            ((cycleTimeStruct.transStartTime1 ~= g_decArgo_dateDef) && ...
            (cycleTimeStruct.transStartTime2 ~= g_decArgo_dateDef) && ...
            (cycleTimeStruct.transStartTime1 ~= cycleTimeStruct.transStartTime2)) || ...
            ((cycleTimeStruct.transStartTimeFloat ~= g_decArgo_dateDef) && ...
            (cycleTimeStruct.firstMsgTime < cycleTimeStruct.transStartTimeFloat)))
         for id = 1:length(uTst1)
            fprintf('Tst1: %s (%d)\n', julian_2_gregorian_dec_argo(uTst1(id)), length(find(tabTst1 == uTst1(id))));
         end
         for id = 1:length(uTst2)
            fprintf('Tst2: %s (%d)\n', julian_2_gregorian_dec_argo(uTst2(id)), length(find(tabTst2 == uTst2(id))));
         end
         fprintf('Tst_float: %s\n', julian_2_gregorian_dec_argo(cycleTimeStruct.transStartTimeFloat));
         fprintf('Tst1: %s\n', julian_2_gregorian_dec_argo(cycleTimeStruct.transStartTime1));
         fprintf('Tst2: %s\n', julian_2_gregorian_dec_argo(cycleTimeStruct.transStartTime2));
         fprintf('FMT: %s\n', julian_2_gregorian_dec_argo(cycleTimeStruct.firstMsgTime));
      end
   end
   
   % store TST from float transmission strategy
   if (cycleTimeStruct.transStartTime2 ~= g_decArgo_dateDef)
      % we prefer the improved method because the TWR one needs additional
      % configuration information (trans rep rate) that can be erroneously
      % reported
      cycleTimeStruct.transStartTimeAdj = cycleTimeStruct.transStartTime2;
   else
      cycleTimeStruct.transStartTimeAdj = cycleTimeStruct.transStartTime1;
   end
   if (cycleTimeStruct.transStartTimeAdj ~= g_decArgo_dateDef)
      cycleTimeStruct.transStartTimeStatus = g_JULD_STATUS_1;
   end
   
   % compute AET = TST - 10 minutes
   if (~ismember(a_decoderId, [1021 1022]))
      if (cycleTimeStruct.transStartTimeAdj ~= g_decArgo_dateDef)
         cycleTimeStruct.ascentEndTimeAdj = cycleTimeStruct.transStartTimeAdj - 10/1440;
         cycleTimeStruct.ascentEndTimeStatus = cycleTimeStruct.transStartTimeStatus;
      end
   end
end

% store cycle times
o_timeData.cycleTime(idCycleStruct) = cycleTimeStruct;

if (a_finalStep)
   
   % compute (or estimate) TET and clock drift
   o_timeData = compute_apx_TET(o_timeData, a_decoderId);
   
   % finalize cycle times
   o_timeData = finalize_apx_times(o_timeData, a_decoderId);
   
end

return
