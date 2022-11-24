% ------------------------------------------------------------------------------
% Compute the main dates of a PROVOR float cycle.
%
% SYNTAX :
%  [o_descentStartDate, o_firstStabDate, o_descentEndDate, ...
%    o_descentToProfStartDate, o_descentToProfEndDate, ...
%    o_ascentStartDate, o_ascentEndDate, o_transStartDate] = ...
%    compute_prv_dates_1_3_4_11_12_17_19_24_25_27_to_29_31(a_tabTech, a_floatClockDrift, a_launchDate, ...
%    a_refDay, a_cycleTime, a_driftSamplingPeriod, a_meanParkPres, a_maxProfPres, ...
%    a_firstArgosMsgDate, a_lastArgosCtdMsgDate, a_lastArgosMsgDateOfPrevCycle, ...
%    a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabTech                     : decoded technical data
%   a_floatClockDrift             : float clock drift
%   a_launchDate                  : float launch date
%   a_refDay                      : reference day (day of the first descent)
%   a_cycleTime                   : cycle duration
%   a_driftSamplingPeriod         : sampling period during drift phase (in hours)
%   a_meanParkPres                : mean of the drift measurement pressures
%   a_maxProfPres                 : deepest ascending profile measurement
%   a_firstArgosMsgDate           : date of the first Argos message received
%   a_lastArgosCtdMsgDate         : date of the last CTD Argos message received
%   a_lastArgosMsgDateOfPrevCycle : date of the last Argos message received at
%                                   the end of the previous cycle
%   a_decoderId                   : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_descentStartDate       : descent start date
%   o_firstStabDate          : first stabilisation date
%   o_descentEndDate         : descent end date
%   o_descentToProfStartDate : descent to profile start date
%   o_descentToProfEndDate   : descent to profile end date
%   o_ascentStartDate        : ascent start date
%   o_ascentEndDate          : ascent end date
%   o_transStartDate         : transmission start date
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_descentStartDate, o_firstStabDate, o_descentEndDate, ...
   o_descentToProfStartDate, o_descentToProfEndDate, ...
   o_ascentStartDate, o_ascentEndDate, o_transStartDate] = ...
   compute_prv_dates_1_3_4_11_12_17_19_24_25_27_to_29_31(a_tabTech, a_floatClockDrift, a_launchDate, ...
   a_refDay, a_cycleTime, a_driftSamplingPeriod, a_meanParkPres, a_maxProfPres, ...
   a_firstArgosMsgDate, a_lastArgosCtdMsgDate, a_lastArgosMsgDateOfPrevCycle, ...
   a_decoderId)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% cycle anomaly flag
global g_decArgo_cycleAnomalyFlag;

% threshold pressure for float cycle anomaly
NO_DIVE_THRESHOLD = 10;

% default values
global g_decArgo_dateDef;

% configuration values
global g_decArgo_add3Min;
global g_decArgo_generateNcTech;


% output parameters initialization
o_descentStartDate = g_decArgo_dateDef;
o_firstStabDate = g_decArgo_dateDef;
o_descentEndDate = g_decArgo_dateDef;
o_descentToProfStartDate = g_decArgo_dateDef;
o_descentToProfEndDate = g_decArgo_dateDef;
o_ascentStartDate = g_decArgo_dateDef;
o_ascentEndDate = g_decArgo_dateDef;
o_transStartDate = g_decArgo_dateDef;

% cycle anomaly flag
g_decArgo_cycleAnomalyFlag = 0;
if ((a_meanParkPres < NO_DIVE_THRESHOLD) || (a_maxProfPres < NO_DIVE_THRESHOLD))
   g_decArgo_cycleAnomalyFlag = 1;
   fprintf('DEC_WARNING: Float #%d Cycle #%d: cycle anomaly detected (the float stayed near the surface) => cycle dates can be inconsistent\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
end

% add and offset of 3 minutes to technical dates (given in tenths of an
% hour after truncation))
zeroOr3Min = 0;
if (g_decArgo_add3Min == 1)
   zeroOr3Min = 3/1440;
end

% delay (in minutes) between surfacing (10 dbar) and transmission start date

% for PROVOR floats
surf2TransDelay = 16;
arvorFloatList = [3 17 31];
if (ismember(a_decoderId, arvorFloatList))
   % for ARVOR floats
   surf2TransDelay = 14;
end

% determination of transmission start date

% put first Argos message date in float time
firstArgosMsgdateInFloatTime = a_firstArgosMsgDate + a_floatClockDrift;
% convert first Argos message date in tenths of an hour
firstArgosDate = fix(firstArgosMsgdateInFloatTime) + ...
   ((floor(((firstArgosMsgdateInFloatTime-fix(firstArgosMsgdateInFloatTime))*1440)/6))*6)/1440;

o_transStartDate = fix(firstArgosDate) + a_tabTech(9)*6/1440 + zeroOr3Min;
if (o_transStartDate > firstArgosDate)
   o_transStartDate = o_transStartDate - 1;
end

if (g_decArgo_cycleAnomalyFlag == 0)
   % determination of ascent end date
   o_ascentEndDate = o_transStartDate - surf2TransDelay/1440;
   
   % determination of ascent start date
   o_ascentStartDate = fix(o_ascentEndDate) + a_tabTech(23)*6/1440;
   if (o_ascentStartDate > o_ascentEndDate)
      o_ascentStartDate = o_ascentStartDate - 1;
   end
else
   % determination of ascent start date
   o_ascentStartDate = fix(o_transStartDate) + a_tabTech(23)*6/1440;
   if (o_ascentStartDate > o_transStartDate)
      o_ascentStartDate = o_ascentStartDate - 1;
   end
   
   % determination of ascent end date
   if (o_transStartDate - surf2TransDelay/1440 > o_ascentStartDate)
      o_ascentEndDate = o_transStartDate - surf2TransDelay/1440;
   else
      o_ascentEndDate = o_transStartDate;
   end
end

% determination of descent to profile end date
o_descentToProfEndDate = fix(o_ascentStartDate) + a_tabTech(34)*6/1440 + zeroOr3Min;
if (o_descentToProfEndDate > o_ascentStartDate)
   o_descentToProfEndDate = o_descentToProfEndDate - 1;
end

% determination of descent to profile start date
o_descentToProfStartDate = fix(o_descentToProfEndDate) + a_tabTech(33)*6/1440;
if (o_descentToProfStartDate > o_descentToProfEndDate)
   o_descentToProfStartDate = o_descentToProfStartDate - 1;
end

% determination of descent start date
firstDeepCycleNumber = 1;
floatWithoutPrelude = [1 11 12 4 19];
if (ismember(a_decoderId, floatWithoutPrelude))
   % floats without prelude phase
   firstDeepCycleNumber = 0;
end
if (g_decArgo_cycleNum > firstDeepCycleNumber)
   if (a_lastArgosMsgDateOfPrevCycle ~= g_decArgo_dateDef)
      % put last Argos message date of the previous cycle in float time
      lastArgosMsgDateOfPrevCycle = a_lastArgosMsgDateOfPrevCycle + a_floatClockDrift;
      % convert last Argos message date of the previous cycle in tenths of an hour
      lastArgosDateOfPrevCycle = fix(lastArgosMsgDateOfPrevCycle) + ...
         ((floor(((lastArgosMsgDateOfPrevCycle-fix(lastArgosMsgDateOfPrevCycle))*1440)/6))*6)/1440;
      
      o_descentStartDate = fix(lastArgosDateOfPrevCycle) + a_tabTech(1)*6/1440 + zeroOr3Min;
      if (o_descentStartDate < lastArgosDateOfPrevCycle)
         o_descentStartDate = o_descentStartDate + 1;
      end
   else
      % put last Argos CTD message date in float time
      lastArgosCtdMsgDate = a_lastArgosCtdMsgDate + a_floatClockDrift;
      % convert last Argos CTD message date in tenths of an hour
      lastArgosCtdMsgDate = fix(lastArgosCtdMsgDate) + ...
         ((floor(((lastArgosCtdMsgDate-fix(lastArgosCtdMsgDate))*1440)/6))*6)/1440;
      % estimated last Argos message date of the previous cycle
      estLastArgosDateOfPrevCycle = lastArgosCtdMsgDate - a_cycleTime/24;
      
      % if the first cycle is not numbered #0
      if (estLastArgosDateOfPrevCycle < a_refDay)
         estLastArgosDateOfPrevCycle = a_refDay;
      end
      
      o_descentStartDate = fix(estLastArgosDateOfPrevCycle) + a_tabTech(1)*6/1440 + zeroOr3Min;
      if (o_descentStartDate < estLastArgosDateOfPrevCycle)
         o_descentStartDate = o_descentStartDate + 1;
      end
   end
else
   % for the first deep cycle, the reference day is the day of the first descent
   o_descentStartDate = fix(a_refDay) + a_tabTech(1)*6/1440 + zeroOr3Min;
   
   % check consistency with launch date
   if (a_launchDate - (fix(a_refDay) + a_tabTech(1)*6/1440) > 6/1440)
      nbDay = 1;
      while (a_launchDate - (fix(a_refDay) + a_tabTech(1)*6/1440 + nbDay) > 6/1440)
         nbDay = nbDay + 1;
      end
      fprintf('DEC_WARNING: Float #%d Cycle #%d: launch date > descent start date => %d day added to theoretical descent start date (based on ref day)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, nbDay);
      o_descentStartDate = o_descentStartDate + nbDay;
   end
   
   nbDay = floor(o_descentStartDate - a_launchDate);
   if (nbDay > 0)
      fprintf('DEC_WARNING: Float #%d Cycle #%d: descent start date too far from launch date => %d day substracted to descent start date\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, nbDay);
      o_descentStartDate = o_descentStartDate - nbDay;
   end
   %
   %
   %    % check consistency with descent to profile start date
   %    if (o_descentStartDate - o_descentToProfStartDate > 0)
   %       nbDay = 1;
   %       while ((o_descentStartDate - nbDay) - o_descentToProfStartDate < 0)
   %
   %
   %       while ((o_descentStartDate - nbDay) - o_descentToProfStartDate > 0)
   %          nbDay = nbDay + 1;
   %       end
   %       fprintf('WARNING: Float #%d Cycle #%d: descent to profile start date > descent start date => %d day substracted to descent start date\n', ...
   %          g_decArgo_floatNum, g_decArgo_cycleNum, nbDay);
   %       o_descentStartDate = o_descentStartDate - nbDay;
   %    end
end

% determination of descent end date
o_descentEndDate = fix(o_descentStartDate) + a_tabTech(7)*6/1440 + zeroOr3Min;
if (o_descentEndDate < o_descentStartDate)
   o_descentEndDate = o_descentEndDate + 1;
end

% determination of first stabilisation date
o_firstStabDate = fix(o_descentStartDate) + a_tabTech(3)*6/1440 + zeroOr3Min;
if (o_firstStabDate < o_descentStartDate)
   o_firstStabDate = o_firstStabDate + 1;
end

print = 0;
if (print == 1)
   floatClockDrift = round(a_floatClockDrift*1440)/1440;
   fprintf('Float #%d cycle #%d:\n', g_decArgo_floatNum, g_decArgo_cycleNum);
   fprintf('CLOCK FLOAT DRIFT         : %s => %s\n', ...
      format_time_dec_argo(a_floatClockDrift*24), ...
      format_time_dec_argo(floatClockDrift*24));
   fprintf('DESCENT START DATE        : %s => %s\n', ...
      julian_2_gregorian_dec_argo(o_descentStartDate), ...
      julian_2_gregorian_dec_argo(o_descentStartDate-floatClockDrift));
   fprintf('FIRST STAB DATE           : %s => %s\n', ...
      julian_2_gregorian_dec_argo(o_firstStabDate), ...
      julian_2_gregorian_dec_argo(o_firstStabDate-floatClockDrift));
   fprintf('DESCENT END DATE          : %s => %s\n', ...
      julian_2_gregorian_dec_argo(o_descentEndDate), ...
      julian_2_gregorian_dec_argo(o_descentEndDate-floatClockDrift));
   fprintf('DESCENT TO PROF START DATE: %s => %s\n', ...
      julian_2_gregorian_dec_argo(o_descentToProfStartDate), ...
      julian_2_gregorian_dec_argo(o_descentToProfStartDate-floatClockDrift));
   fprintf('DESCENT TO PROF END DATE  : %s => %s\n', ...
      julian_2_gregorian_dec_argo(o_descentToProfEndDate), ...
      julian_2_gregorian_dec_argo(o_descentToProfEndDate-floatClockDrift));
   fprintf('ASCENT START DATE         : %s => %s\n', ...
      julian_2_gregorian_dec_argo(o_ascentStartDate), ...
      julian_2_gregorian_dec_argo(o_ascentStartDate-floatClockDrift));
   fprintf('ASCENT END DATE           : %s => %s\n', ...
      julian_2_gregorian_dec_argo(o_ascentEndDate), ...
      julian_2_gregorian_dec_argo(o_ascentEndDate-floatClockDrift));
   fprintf('TRANS START DATE          : %s => %s\n', ...
      julian_2_gregorian_dec_argo(o_transStartDate), ...
      julian_2_gregorian_dec_argo(o_transStartDate-floatClockDrift));
end

% output NetCDF files
% if (g_decArgo_generateNcTech ~= 0)
%    floatClockDrift = round(a_floatClockDrift*1440)/1440;
% in TRAJ only
%    if (o_descentStartDate ~= g_decArgo_dateDef)
%       g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
%          g_decArgo_cycleNum 114];
%       g_decArgo_outputNcParamValue{end+1} = ...
%          julian_2_gregorian_dec_argo(o_descentStartDate-floatClockDrift);
%    end
% in TRAJ only
%    if (o_firstStabDate ~= g_decArgo_dateDef)
%       g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
%          g_decArgo_cycleNum 131];
%       g_decArgo_outputNcParamValue{end+1} = ...
%          julian_2_gregorian_dec_argo(o_firstStabDate-floatClockDrift);
%    end
% in TRAJ only
%    if (o_descentEndDate ~= g_decArgo_dateDef)
%       g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
%          g_decArgo_cycleNum 117];
%       g_decArgo_outputNcParamValue{end+1} = ...
%          julian_2_gregorian_dec_argo(o_descentEndDate-floatClockDrift);
%    end
% in TRAJ only
%    if (o_descentToProfStartDate ~= g_decArgo_dateDef)
%       g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
%          g_decArgo_cycleNum 119];
%       g_decArgo_outputNcParamValue{end+1} = ...
%          julian_2_gregorian_dec_argo(o_descentToProfStartDate-floatClockDrift);
%    end
% in TRAJ only
%    if (o_descentToProfEndDate ~= g_decArgo_dateDef)
%       g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
%          g_decArgo_cycleNum 121];
%       g_decArgo_outputNcParamValue{end+1} = ...
%          julian_2_gregorian_dec_argo(o_descentToProfEndDate-floatClockDrift);
%    end
% in TRAJ only
%    if (o_ascentStartDate ~= g_decArgo_dateDef)
%       g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
%          g_decArgo_cycleNum 123];
%       g_decArgo_outputNcParamValue{end+1} = ...
%          julian_2_gregorian_dec_argo(o_ascentStartDate-floatClockDrift);
%    end
% in TRAJ only
%    if (o_ascentEndDate ~= g_decArgo_dateDef)
%       g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
%          g_decArgo_cycleNum 125];
%       g_decArgo_outputNcParamValue{end+1} = ...
%          julian_2_gregorian_dec_argo(o_ascentEndDate-floatClockDrift);
%    end
% in TRAJ only
%    if (o_transStartDate ~= g_decArgo_dateDef)
%       g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
%          g_decArgo_cycleNum 126];
%       g_decArgo_outputNcParamValue{end+1} = ...
%          julian_2_gregorian_dec_argo(o_transStartDate-floatClockDrift);
%    end
% end

return;
