% ------------------------------------------------------------------------------
% Compute APEX TET.
% Compute TET from DOWN_TIME end times if provided by the float (TET = DOWN_TIME
% end + UP_TIME).
% Otherwise estimate TET from LMTs (and estimate the RTC clock drift if
% possible).
%
% SYNTAX :
%  [o_timeData] = compute_apx_TET(a_timeData)
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
function [o_timeData] = compute_apx_TET(a_timeData)

% output parameters initialization
o_timeData = a_timeData;

% current float WMO number
global g_decArgo_floatNum;

% global time status
global g_JULD_STATUS_3;

% default values
global g_decArgo_dateDef;


% estimate TET and clock drift from LMTs
o_timeData = estimate_TET(o_timeData);

% configuration information
dpfFloatFlag = o_timeData.configParam.dpfFloatFlag;
if (isempty(dpfFloatFlag))
   dpfFloatFlag = 1;
end

% for float versions which provide DOWN_TIME end: TET = DOWN_TIME end + UP_TIME
if (o_timeData.configParam.downTimeEndProvidedFlag)

   % interpolate DOWN_TIME end to fill missing ones
   idUsed = find([o_timeData.cycleNum] > dpfFloatFlag);
   cycleNumber = o_timeData.cycleNum(idUsed);
   downTimeEnd = [o_timeData.cycleTime(idUsed).downTimeEndFloat];
   
   idNotDated = find(downTimeEnd == g_decArgo_dateDef);
   if (~isempty(idNotDated))
      idUsed2 = find(downTimeEnd ~= g_decArgo_dateDef);
      cycleNumberUsed = cycleNumber(idUsed2);
      downTimeEndUsed = downTimeEnd(idUsed2);
      
      if (length(cycleNumberUsed) > 1)
         downTimeEndInterp = interp1(cycleNumberUsed, downTimeEndUsed, cycleNumber(idNotDated), 'linear');
         downTimeEndInterp(find(isnan(downTimeEndInterp))) = g_decArgo_dateDef;
         downTimeEndInterp = num2cell(downTimeEndInterp);
         [o_timeData.cycleTime(idUsed(idNotDated)).downTimeEndFloat] = deal(downTimeEndInterp{:});
         [o_timeData.cycleTime(idUsed(idNotDated)).downTimeEndFloatStatus] = deal(g_JULD_STATUS_3);
      end
   end
   
   % compute float clock drift from DOWN_TIME end
   idUsed = find([o_timeData.cycleNum] > dpfFloatFlag);
   cycleNumber = o_timeData.cycleNum(idUsed);
   downTimeEnd = [o_timeData.cycleTime(idUsed).downTimeEndFloat];
   idDated = find(downTimeEnd ~= g_decArgo_dateDef);
   if (length(idDated) > 1)
      cycleNumber = cycleNumber(idDated);
      downTimeEnd = downTimeEnd(idDated);
      
      % linearly fit the DOWN_TIME ends (in a least squares sense) to estimate clock drift
      cycleTime = o_timeData.configParam.cycleTime;
      cycleTimes = ones(max(cycleNumber), 1)*cycleTime;
      xVal = compute_duration(cycleNumber, cycleNumber(1), cycleTimes);
      yVal = downTimeEnd;
      polyCoef = polyfit(xVal, yVal, 1);
      
      tabVal = polyval(polyCoef, compute_duration(cycleNumber, cycleNumber(1), cycleTimes));
      % the estimated clock drift (clock drift = float time - UTC time)
      % clock drift is > 0 when the float RTC is too late and then a positive
      % offset should be substracted to float times
      % here we are fitting DOWN_TIME ends (i.e. float times), thus
      clockOffset = (tabVal(end) - (cycleNumber(end)-cycleNumber(1))*cycleTime/24 - tabVal(1))*86400;
      clockDrift = clockOffset/abs(tabVal(1) - tabVal(end))*365;
      fprintf('clock drift from DOWN_TIME end: %s per year\n', format_time_dec_argo(clockDrift/3600));
      if (~isempty(o_timeData.clockDriftInSecPerYear))
         o_timeData.clockDriftInSecPerYear = o_timeData.clockDriftInSecPerYear + clockDrift;
         fprintf('clock drift USED: %s per year\n', format_time_dec_argo(o_timeData.clockDriftInSecPerYear/3600));
      end
   end
   
   % if UP_TIME is unknown, estimate it
   upTime = o_timeData.configParam.upTime;
   %    fprintf('UP_TIME config: %d hours\n', upTime);
   if (isempty(upTime))
      [o_timeData] = estimate_UP_TIME(o_timeData);

      upTime = o_timeData.configParam.upTime;
      if (~isempty(upTime))
         fprintf('UP_TIME estimated: %d hours\n', upTime);
      else
         fprintf('WARNING: Float #%d: UP_TIME is unknown and cannot be estimated => TET (= DOWN_TIME end + UP_TIME) is not computed\n', ...
            g_decArgo_floatNum);
      end
   end
   
   % compute TET = DOWN_TIME end + UP_TIME
   if (~isempty(upTime))
      tabTet = [o_timeData.cycleTime.downTimeEndFloat];
      idDated = find(tabTet ~= g_decArgo_dateDef);
      tabTet(idDated) = tabTet(idDated) + upTime/24;
      tabTet = num2cell(tabTet);
      [o_timeData.cycleTime.transEndTime1] = deal(tabTet{:});
      
      % estimate the clock offset at launch
      % Clock off at launch is roughly estimated from RTC provided in the test
      % message. We will estimate it from TET (float) - TET (from LMTs) adj.
      % This estimate gives better results for TET (float) adjusted values.
      if (~isempty(o_timeData.clockDriftInSecPerYear))
         tet1 = [o_timeData.cycleTime(idUsed).transEndTime1];
         tet1Adj = adjust_apx_time(tet1, o_timeData.clockDriftInSecPerYear, [], g_decArgo_dateDef);
         tet2 = [o_timeData.cycleTime(idUsed).transEndTime2];
         idDated = find((tet1Adj ~= g_decArgo_dateDef) & (tet2 ~= g_decArgo_dateDef));
         if (~isempty(idDated))
            clockOffsetAtLaunch = tet1Adj(idDated(1)) - tet2(idDated(1));
            fprintf('Clock offset at launch estimated: %s\n', format_time_dec_argo(clockOffsetAtLaunch*24));
            if (~isempty(o_timeData.clockOffsetAtLaunch))
               fprintf('Clock offset at launch measured: %s\n', format_time_dec_argo(o_timeData.clockOffsetAtLaunch*24));
               fprintf('Clock offset at launch difference: %s\n', format_time_dec_argo((clockOffsetAtLaunch-o_timeData.clockOffsetAtLaunch)*24));
            end
            o_timeData.clockOffsetAtLaunch = clockOffsetAtLaunch;
            idDated = find(tet1 ~= g_decArgo_dateDef);
            o_timeData.clockOffsetAtLaunchRefDate = tet1(idDated(1));
         end
      end
   end
end

return;

% ------------------------------------------------------------------------------
% Estimate UP_TIME configuration parameter value.
%
% SYNTAX :
%  [o_timeData] = estimate_UP_TIME(a_timeData)
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
function [o_timeData] = estimate_UP_TIME(a_timeData)

% output parameters initialization
o_timeData = a_timeData;

% default values
global g_decArgo_dateDef;


% configuration information
dpfFloatFlag = a_timeData.configParam.dpfFloatFlag;
if (isempty(dpfFloatFlag))
   dpfFloatFlag = 1;
end

% estimate UP_TIME from TET and DOWN_TIME end
idUsed = find([o_timeData.cycleNum] > dpfFloatFlag);
tabTet = [o_timeData.cycleTime(idUsed).transEndTime2];
downTimeEnd = [o_timeData.cycleTime(idUsed).downTimeEndFloat];
idDated = find((tabTet ~= g_decArgo_dateDef) & (downTimeEnd ~= g_decArgo_dateDef));

[o_timeData.configParam.upTime, ~] = select_a_value(round((tabTet(idDated)-downTimeEnd(idDated))*24));
o_timeData.configParam.downTime = o_timeData.configParam.cycleTime - o_timeData.configParam.upTime;

return;

% ------------------------------------------------------------------------------
% Estimate TET from LMTs (and estimate the RTC clock drift if possible).
%
% SYNTAX :
%  [o_timeData] = estimate_TET(a_timeData)
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
function [o_timeData] = estimate_TET(a_timeData)

% output parameters initialization
o_timeData = a_timeData;

% current float WMO number
global g_decArgo_floatNum;

% default values
global g_decArgo_dateDef;

% minimum number of received cycles to estimate clock drit
NB_CYCLE_MIN = 33;
% NB_CYCLE_MIN = 9999;

% max clock drift allowed (if estimated value > MAX_CLOCK_DRIFT don't estimate
% TET)
MAX_CLOCK_DRIFT = 20; % in minutes per year


% configuration information
cycleTime = o_timeData.configParam.cycleTime;
dpfFloatFlag = a_timeData.configParam.dpfFloatFlag;
if (isempty(dpfFloatFlag))
   dpfFloatFlag = 1;
end

idUsed = find([o_timeData.cycleNum] > dpfFloatFlag);
cycleNumber = o_timeData.cycleNum(idUsed);
lastMsgTime = [o_timeData.cycleTime(idUsed).lastMsgTime];
cycleTimes = ones(max(cycleNumber), 1)*cycleTime;

if (isempty(cycleNumber))
   return;
end

% estimate TET from the max envelope of the LMTs (without clock drift estimation)
maxEnvTime = lastMsgTime - compute_duration(cycleNumber, cycleNumber(1), cycleTimes);
tabTet1 = max(maxEnvTime) + compute_duration(cycleNumber, cycleNumber(1), cycleTimes);
tabTet1 = num2cell(tabTet1);
[o_timeData.cycleTime(idUsed).transEndTime2] = deal(tabTet1{:});

% for cycle #0 (and #1 if DPF float): TET = LMT
idNotDated = find([o_timeData.cycleTime.transEndTime2] == g_decArgo_dateDef);
lmtOfNotDated = [o_timeData.cycleTime(idNotDated).lastMsgTime];
lmtOfNotDated = num2cell(lmtOfNotDated);
[o_timeData.cycleTime(idNotDated).transEndTime2] = deal(lmtOfNotDated{:});

% if there is enouch cycles, we estimate the TETs taking into account the clock
% drift

if (length(cycleNumber) >= NB_CYCLE_MIN)
   % step #1: compute the convex envelope of the LMTs
   convexEnv = lastMsgTime;
   oneMore = 1;
   while (oneMore)
      oneMore = 0;
      idDated = find(convexEnv ~= g_decArgo_dateDef);
      if (~isempty(idDated))
         idStart = idDated(1);
         stop = 0;
         while (~stop)
            stop = 1;
            idIdDated = find(idDated > idStart);
            for id = 1:length(idIdDated)-1
               idFirst = idStart;
               xFirst = compute_duration(cycleNumber(idStart), cycleNumber(1), cycleTimes);
               yFirst = convexEnv(idFirst);
               
               idCheck = idDated(idIdDated(id));
               xCheck = compute_duration(cycleNumber(idCheck), cycleNumber(1), cycleTimes);
               yCheck = convexEnv(idCheck);
               
               idLast = idDated(idIdDated(id+1));
               xLast = compute_duration(cycleNumber(idLast), cycleNumber(1), cycleTimes);
               yLast = convexEnv(idLast);
               
               coefA = (yFirst - yLast)/(xFirst - xLast);
               coefB = yFirst - coefA*xFirst;
               
               expValue = coefA*xCheck + coefB;
               if (yCheck <= expValue)
                  % idCheck is not in the convex envelope
                  convexEnv(idCheck) = g_decArgo_dateDef;
                  % one point has been excluded, a new global loop is need
                  oneMore = 1;
               else
                  % we must start from this base point, it could be one of the
                  % convex envelope
                  idStart = idCheck;
                  stop = 0;
                  break;
               end
            end
         end
      end
   end
   
   % step #2: interpolate the remaining points to set a point on the convex
   % envelope for all cycles
   idDated = find(convexEnv ~= g_decArgo_dateDef);
   cycleNumberUsed = cycleNumber(idDated);
   convexEnvUsed = convexEnv(idDated);
   
   idInterp = find(convexEnv == g_decArgo_dateDef);
   convexEnvAll = convexEnv;
   convexEnvAll(idInterp) = interp1(cycleNumberUsed, convexEnvUsed, cycleNumber(idInterp), 'linear');
   
   % step #3: ignore the first and last 1/5 of the cycles
   nbToIgnore = fix(length(cycleNumber)/5);
   idToUse = nbToIgnore+1:length(cycleNumber)-nbToIgnore;

   % step #4: linearly fit the points of the convex envelope (in a least squares
   % sense) to estimate clock drift
   xVal = compute_duration(cycleNumber(idToUse), cycleNumber(1), cycleTimes);
   yVal = convexEnvAll(idToUse);
   polyCoef = polyfit(xVal, yVal, 1);
   
   % step #5: find the base point(s) of the convex envelope
   basePoint = [];
   idDated = find(convexEnv ~= g_decArgo_dateDef);
   for id = 1:length(idDated)
      idPoint = idDated(id);
      xPoint = compute_duration(cycleNumber(idPoint), cycleNumber(1), cycleTimes);
      yPoint = convexEnv(idPoint);
      
      % line set on the current point
      coefB = yPoint - polyCoef(1)*xPoint;
      curPolyCoefCur = [polyCoef(1) coefB];
      
      % all the points should be before the current point
      yAll = polyval(curPolyCoefCur, compute_duration(cycleNumber(idDated), cycleNumber(1), cycleTimes));
      idKo = find(convexEnv(idDated) > yAll);
      if (isempty(idKo) || ((length(idKo) == 1) && (idKo == id)))
         basePoint = [basePoint; idPoint];
      end
   end
   basePoint = basePoint(1);
   
   % step #6: compute the TETs from base point and clock drift
   idPoint = basePoint;
   xPoint = compute_duration(cycleNumber(idPoint), cycleNumber(1), cycleTimes);
   yPoint = convexEnv(idPoint);
   
   % line set on the base point
   coefB = yPoint - polyCoef(1)*xPoint;
   polyCoefFinal = [polyCoef(1) coefB];
   
   % the TETs are on the line
   tabTet2 = polyval(polyCoefFinal, compute_duration(cycleNumber, cycleNumber(1), cycleTimes));
   
   % the estimated clock drift (clock drift = float time - UTC time)
   % clock drift is > 0 when the float RTC is too late and then a positive
   % offset should be substracted to float times
   % here we are fitting Tet2 (based on LMTs i.e. UTC times), thus
   clockOffset = (tabTet2(1) - (tabTet2(end) - (cycleNumber(end)-cycleNumber(1))*cycleTime/24))*86400;
   clockDrift = clockOffset/abs(tabTet2(1) - tabTet2(end))*365;
   if (clockDrift/60 > MAX_CLOCK_DRIFT)
      % the algorithm failed (there is probably a jump of the RTC)
      fprintf('WARNING: Float #%d: estimated clock drift (%s per year) > MAX_CLOCK_DRIFT (= %s per year)>  => TET cannot be estimated\n', ...
         g_decArgo_floatNum, ...
         format_time_dec_argo(clockDrift/3600), ...
         format_time_dec_argo(MAX_CLOCK_DRIFT/60));
      
      % don't keep TET estimated from the max envelope of the LMTs
      [o_timeData.cycleTime(idUsed).transEndTime2] = deal(g_decArgo_dateDef);
   else
      fprintf('clock drift from LMT: %s per year\n', format_time_dec_argo(clockDrift/3600));
      
      % store the results
      tabTet2 = num2cell(tabTet2);
      [o_timeData.cycleTime(idUsed).transEndTime2] = deal(tabTet2{:});
      o_timeData.clockDriftInSecPerYear = clockDrift;
   end
end

return;

% ------------------------------------------------------------------------------
% Compute durations between cycles.
%
% SYNTAX :
%  [o_duration] = compute_duration(a_tabEndCyNum, a_startCyNum, a_cycleTime)
%
% INPUT PARAMETERS :
%   a_tabEndCyNum : end cycle numbers
%   a_startCyNum  : start cycle number
%   a_cycleTime   : cycle durations
%
% OUTPUT PARAMETERS :
%   o_duration : durations between cycles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_duration] = compute_duration(a_tabEndCyNum, a_startCyNum, a_cycleTime)

% output parameters initialization
o_duration = [];

for id = 1:length(a_tabEndCyNum)
   % cycles to compute the duration
   cyNum = [a_startCyNum+1:a_tabEndCyNum(id)];
   if (~isempty(cyNum))
      o_duration(id) = sum(a_cycleTime(cyNum));
   else
      o_duration(id) = 0;
   end
end

o_duration = o_duration/24;

return;
