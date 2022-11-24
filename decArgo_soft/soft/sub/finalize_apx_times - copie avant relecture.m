% ------------------------------------------------------------------------------
% Compute APEX cycle times for all received cycles.
%
% SYNTAX :
%  [o_timeData] = finalize_apx_times(a_timeData)
%
% INPUT PARAMETERS :
%   a_timeData : input cycle time data structure
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
function [o_timeData] = finalize_apx_times(a_timeData)

% output parameters initialization
o_timeData = a_timeData;

% global time status
global g_JULD_STATUS_1;
global g_JULD_STATUS_3;

% default values
global g_decArgo_dateDef;


% configuration information
dpfFloatFlag = o_timeData.configParam.dpfFloatFlag;
if (isempty(dpfFloatFlag))
   dpfFloatFlag = 1;
end

% retrieve adjustment parameters
clockOffset = o_timeData.clockOffsetAtLaunch;
clockOffsetRefDate = o_timeData.clockOffsetAtLaunchRefDate;
clockDrift = o_timeData.clockDriftInSecPerYear;

if (isempty(clockOffset))
   clockOffset = 0;
   idMin = find([o_timeData.cycleNum] == min([o_timeData.cycleNum]));
   clockOffsetRefDate = o_timeData.cycleTime(idMin).firstMsgTime;
end
if (isempty(clockDrift))
   clockDrift = 0;
end

% compute parking and profile pressures for all received cycles
parkingPres = o_timeData.configParam.parkingPres;
profilePres = o_timeData.configParam.profilePres;
parkAndProfileCycleLength = o_timeData.configParam.parkAndProfileCycleLength;
if (~isempty(parkingPres) && ~isempty(profilePres) && ~isempty(parkAndProfileCycleLength))
   tabCycleNum = o_timeData.cycleNum;
   tabParkPres = ones(size(tabCycleNum))*parkingPres;
   tabProfPres = ones(size(tabCycleNum))*parkingPres;
   if (parkAndProfileCycleLength ~= 234)
      idDeep = find(rem(tabCycleNum, parkAndProfileCycleLength) == 0);
      tabProfPres(idDeep) = profilePres;
   end
   if (o_timeData.configParam.dpfFloatFlag)
      idCy1 = find(tabCycleNum == 1);
      if (~isempty(idCy1))
         tabProfPres(idCy1) = profilePres;
      end
   end
   
   o_timeData.cycleParkPres = tabParkPres;
   o_timeData.cycleProfPres = tabProfPres;
end

% compute clock offset for each cycle and adjust times
for idCy = 1:length(o_timeData.cycleNum)

   %    if (o_timeData.cycleNum(idCy) == 61)
   %       a=1
   %    end

   % store clock offset for the current cycle
   refDate = o_timeData.cycleTime(idCy).firstMsgTime;
   refDateAdj = adjust_apx_time( ...
      refDate, clockDrift, clockOffset, clockOffsetRefDate);
   refDate = gregorian_2_julian_dec_argo(julian_2_gregorian_dec_argo(refDate));
   refDateAdj = gregorian_2_julian_dec_argo(julian_2_gregorian_dec_argo(refDateAdj));
   o_timeData.cycleTime(idCy).clockOffset = refDate - refDateAdj;
   %    fprintf('Cycle #%d: clock offset %s\n', ...
   %       o_timeData.cycleNum(idCy), format_time_dec_argo(o_timeData.cycleTime(idCy).clockOffset*24));
   
   if ((o_timeData.cycleNum(idCy) == 0) || ...
         (dpfFloatFlag == 1) && (o_timeData.cycleNum(idCy) == 1))
      o_timeData.cycleTime(idCy).transEndTime1 = o_timeData.cycleTime(idCy).lastMsgTime - ...
         o_timeData.cycleTime(idCy).clockOffset;
   end
   
   % TET
   if (o_timeData.configParam.downTimeEndProvidedFlag)
      % TET = DOWN_TIME end + UP_TIME
      o_timeData.cycleTime(idCy).transEndTime = o_timeData.cycleTime(idCy).transEndTime1;
      o_timeData.cycleTime(idCy).transEndTimeAdj = adjust_apx_time( ...
         o_timeData.cycleTime(idCy).transEndTime, clockDrift, clockOffset, clockOffsetRefDate);
      if (o_timeData.cycleTime(idCy).transEndTime ~= g_decArgo_dateDef)
         o_timeData.cycleTime(idCy).transEndTimeStatus = g_JULD_STATUS_3;
      end
   else
      % TET (estimated from LMTs)
      o_timeData.cycleTime(idCy).transEndTime = g_decArgo_dateDef;
      o_timeData.cycleTime(idCy).transEndTimeAdj = o_timeData.cycleTime(idCy).transEndTime2;
      if (o_timeData.cycleTime(idCy).transEndTimeAdj ~= g_decArgo_dateDef)
         o_timeData.cycleTime(idCy).transEndTimeStatus = g_JULD_STATUS_1;
      end
   end
   
   % DOWN_TIME end
   if (o_timeData.configParam.downTimeEndProvidedFlag)
      % provided by the float
      o_timeData.cycleTime(idCy).downTimeEnd = o_timeData.cycleTime(idCy).downTimeEndFloat;
      o_timeData.cycleTime(idCy).downTimeEndAdj = adjust_apx_time( ...
         o_timeData.cycleTime(idCy).downTimeEndFloat, clockDrift, clockOffset, clockOffsetRefDate);
      o_timeData.cycleTime(idCy).downTimeEndStatus = o_timeData.cycleTime(idCy).downTimeEndFloatStatus;
      %    else
      %       % otherwise DOWN_TIME end = TET (estimated from LMTs) - UP_TIME
      %       if (o_timeData.cycleNum(idCy) > 0)
      %          if (~isempty(o_timeData.configParam.upTime))
      %             if (o_timeData.cycleTime(idCy).transEndTimeAdj ~= g_decArgo_dateDef)
      %                o_timeData.cycleTime(idCy).downTimeEnd = g_decArgo_dateDef;
      %                o_timeData.cycleTime(idCy).downTimeEndAdj = o_timeData.cycleTime(idCy).transEndTimeAdj - o_timeData.configParam.upTime/24;
      %                o_timeData.cycleTime(idCy).downTimeEndStatus = o_timeData.cycleTime(idCy).transEndTimeStatus;
      %             end
      %          end
      %       end
   end
   
   % PET
   % PET not set when PARK P = PROF P (since PET = AST)
   % otherwise PET = TET - UP_TIME - DPDP hours
   if (o_timeData.cycleNum(idCy) > 0)
      if (~isempty(o_timeData.cycleParkPres) && ...
            ~isempty(o_timeData.configParam.upTime) && ...
            ~isempty(o_timeData.configParam.deepProfileDescentPeriod))
         if (o_timeData.cycleParkPres(idCy) ~= o_timeData.cycleProfPres(idCy))
            if (o_timeData.cycleTime(idCy).transEndTimeStatus == g_JULD_STATUS_3)
               % TET is computed
               if (o_timeData.cycleTime(idCy).transEndTime ~= g_decArgo_dateDef)
                  o_timeData.cycleTime(idCy).parkEndTime = o_timeData.cycleTime(idCy).transEndTime ...
                     - (o_timeData.configParam.upTime + o_timeData.configParam.deepProfileDescentPeriod)/24;
                  o_timeData.cycleTime(idCy).parkEndTimeAdj = o_timeData.cycleTime(idCy).transEndTimeAdj ...
                     - (o_timeData.configParam.upTime + o_timeData.configParam.deepProfileDescentPeriod)/24;
                  o_timeData.cycleTime(idCy).parkEndTimeStatus = o_timeData.cycleTime(idCy).transEndTimeStatus;
               end
            elseif (o_timeData.cycleTime(idCy).transEndTimeStatus == g_JULD_STATUS_1)
               % TET is estimated
               if (o_timeData.cycleTime(idCy).transEndTimeAdj ~= g_decArgo_dateDef)
                  o_timeData.cycleTime(idCy).parkEndTime = g_decArgo_dateDef;
                  o_timeData.cycleTime(idCy).parkEndTimeAdj = o_timeData.cycleTime(idCy).transEndTimeAdj ...
                     - (o_timeData.configParam.upTime + o_timeData.configParam.deepProfileDescentPeriod)/24;
                  o_timeData.cycleTime(idCy).parkEndTimeStatus = o_timeData.cycleTime(idCy).transEndTimeStatus;
               end
            end
         end
      end
   end
   
   % AST
   % AST = TET - UP_TIME when PARK P = PROF P
   if (o_timeData.cycleNum(idCy) > 0)
      if (~isempty(o_timeData.cycleParkPres) && ...
            ~isempty(o_timeData.configParam.upTime))
         if (o_timeData.cycleParkPres(idCy) == o_timeData.cycleProfPres(idCy))
            if (o_timeData.cycleTime(idCy).transEndTimeStatus == g_JULD_STATUS_3)
               % TET is computed
               if (o_timeData.cycleTime(idCy).transEndTime ~= g_decArgo_dateDef)
                  o_timeData.cycleTime(idCy).ascentStartTime = o_timeData.cycleTime(idCy).transEndTime ...
                     - o_timeData.configParam.upTime/24;
                  o_timeData.cycleTime(idCy).ascentStartTimeAdj = o_timeData.cycleTime(idCy).transEndTimeAdj ...
                     - o_timeData.configParam.upTime/24;
                  o_timeData.cycleTime(idCy).ascentStartTimeStatus = o_timeData.cycleTime(idCy).transEndTimeStatus;
               end
            elseif (o_timeData.cycleTime(idCy).transEndTimeStatus == g_JULD_STATUS_1)
               % TET is estimated
               if (o_timeData.cycleTime(idCy).transEndTimeAdj ~= g_decArgo_dateDef)
                  o_timeData.cycleTime(idCy).ascentStartTime = g_decArgo_dateDef;
                  o_timeData.cycleTime(idCy).ascentStartTimeAdj = o_timeData.cycleTime(idCy).transEndTimeAdj ...
                     - o_timeData.configParam.upTime/24;
                  o_timeData.cycleTime(idCy).ascentStartTimeStatus = o_timeData.cycleTime(idCy).transEndTimeStatus;
               end
            end
         end
      end
   end
   
   % AST float
   if (o_timeData.configParam.ascentStartTimeProvidedFlag)
      o_timeData.cycleTime(idCy).ascentStartTimeFloatAdj = adjust_apx_time( ...
         o_timeData.cycleTime(idCy).ascentStartTimeFloat, clockDrift, clockOffset, clockOffsetRefDate);
   end
   
   % DDET
   % DDET = AST
   if (o_timeData.cycleNum(idCy) > 0)
      if (o_timeData.configParam.ascentStartTimeProvidedFlag)
         o_timeData.cycleTime(idCy).deepDescentEndTime = o_timeData.cycleTime(idCy).ascentStartTimeFloat;
         o_timeData.cycleTime(idCy).deepDescentEndTimeAdj = o_timeData.cycleTime(idCy).ascentStartTimeFloatAdj;
         o_timeData.cycleTime(idCy).deepDescentEndTimeStatus = o_timeData.cycleTime(idCy).ascentStartTimeFloatStatus;
      else
         if (o_timeData.cycleTime(idCy).ascentStartTimeStatus == g_JULD_STATUS_3)
            % AST is computed
            o_timeData.cycleTime(idCy).deepDescentEndTime = o_timeData.cycleTime(idCy).ascentStartTime;
         elseif (o_timeData.cycleTime(idCy).ascentStartTimeStatus == g_JULD_STATUS_1)
            % AST is estimated
            o_timeData.cycleTime(idCy).deepDescentEndTime = g_decArgo_dateDef;
         end
         o_timeData.cycleTime(idCy).deepDescentEndTimeAdj = o_timeData.cycleTime(idCy).ascentStartTimeAdj;
         o_timeData.cycleTime(idCy).deepDescentEndTimeStatus = o_timeData.cycleTime(idCy).ascentStartTimeStatus;
      end
   end
   
   % TST from transmission strategy: done in compute_apx_times
   
   % TST from float
   o_timeData.cycleTime(idCy).transStartTimeFloatAdj = adjust_apx_time( ...
      o_timeData.cycleTime(idCy).transStartTimeFloat, clockDrift, clockOffset, clockOffsetRefDate);
   
   % AET = TST - 10 minutes: done in compute_apx_times
   
   % AET float = TST float - 10 minutes
   if (o_timeData.cycleTime(idCy).transStartTimeFloat ~= g_decArgo_dateDef)
      o_timeData.cycleTime(idCy).ascentEndTimeFloat = o_timeData.cycleTime(idCy).transStartTimeFloat - 10/1440;
      o_timeData.cycleTime(idCy).ascentEndTimeFloatAdj = o_timeData.cycleTime(idCy).transStartTimeFloatAdj - 10/1440;
      o_timeData.cycleTime(idCy).ascentEndTimeFloatStatus = o_timeData.cycleTime(idCy).transStartTimeFloatStatus;
   end
   
end

% finalize DST and descending pressure mark times
for idCy = 1:length(o_timeData.cycleNum)
   
   % DST
   % DST = TET of the previous cycle
   idPrevCycle = find([a_timeData.cycleNum] == o_timeData.cycleNum(idCy)-1);
   if (~isempty(idPrevCycle))
      if (o_timeData.cycleTime(idPrevCycle).transEndTimeStatus == g_JULD_STATUS_3)
         % TET is computed
         o_timeData.cycleTime(idCy).descentStartTime = o_timeData.cycleTime(idPrevCycle).transEndTime;
      elseif (o_timeData.cycleTime(idPrevCycle).transEndTimeStatus == g_JULD_STATUS_1)
         % TET is estimated
         o_timeData.cycleTime(idCy).descentStartTime = g_decArgo_dateDef;
      end
      o_timeData.cycleTime(idCy).descentStartTimeAdj = o_timeData.cycleTime(idPrevCycle).transEndTimeAdj;
      o_timeData.cycleTime(idCy).descentStartTimeStatus = o_timeData.cycleTime(idPrevCycle).transEndTimeStatus;
      
      if (~isempty(o_timeData.cycleTime(idCy).descPresMark))
         for idPM = 2:length(o_timeData.cycleTime(idCy).descPresMark.dates)
            if (o_timeData.cycleTime(idCy).descentStartTimeStatus == g_JULD_STATUS_3)
               % DST is computed
               if (o_timeData.cycleTime(idCy).descentStartTime ~= g_decArgo_dateDef)
                  o_timeData.cycleTime(idCy).descPresMark.dates(idPM) = o_timeData.cycleTime(idCy).descentStartTime + (idPM-1)/24;
                  o_timeData.cycleTime(idCy).descPresMark.datesAdj(idPM) = o_timeData.cycleTime(idCy).descentStartTimeAdj + (idPM-1)/24;
                  o_timeData.cycleTime(idCy).descPresMark.datesStatus(idPM) = o_timeData.cycleTime(idCy).descentStartTimeStatus;
               end
            elseif (o_timeData.cycleTime(idCy).descentStartTimeStatus == g_JULD_STATUS_1)
               % DST is estimated
               if (o_timeData.cycleTime(idCy).descentStartTimeAdj ~= g_decArgo_dateDef)
                  o_timeData.cycleTime(idCy).descPresMark.dates(idPM) = g_decArgo_dateDef;
                  o_timeData.cycleTime(idCy).descPresMark.datesAdj(idPM) = o_timeData.cycleTime(idCy).descentStartTimeAdj + (idPM-1)/24;
                  o_timeData.cycleTime(idCy).descPresMark.datesStatus(idPM) = o_timeData.cycleTime(idCy).descentStartTimeStatus;
               end
            end
         end
      end
   end
end

return;
