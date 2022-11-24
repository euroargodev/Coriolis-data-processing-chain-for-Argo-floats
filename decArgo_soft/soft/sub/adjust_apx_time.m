% ------------------------------------------------------------------------------
% Adjust float time from RTC clock offset.
%
% SYNTAX :
%  [o_timeAdj] = adjust_apx_time(a_time, a_clockDrift, a_clockOffset, a_clockOffsetRefDate)
%
% INPUT PARAMETERS :
%   a_time               : float time to adjust
%   a_clockDrift         : RTC clock drift (in number of seconds per year (365 days))
%   a_clockOffset        : RTC clock offset at a given reference time
%   a_clockOffsetRefDate : reference time of RTC clock offset
%
% OUTPUT PARAMETERS :
%   o_timeAdj : adjusted time
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_timeAdj] = adjust_apx_time(a_time, a_clockDrift, a_clockOffset, a_clockOffsetRefDate)

% output parameters initialization
o_timeAdj = a_time;

% default values
global g_decArgo_dateDef;


% adjust defined times only
idDated = find(a_time ~= g_decArgo_dateDef);
time = a_time(idDated);

clockOffset = a_clockOffset;
clockOffsetRefDate = a_clockOffsetRefDate;
if (isempty(clockOffset))
   % adjust only from clock drift
   clockOffset = 0;
   clockOffsetRefDate = time(1);
end

coefA = a_clockDrift/365;
coefB = clockOffset - coefA*clockOffsetRefDate/86400;
timeAdj = time + time*coefA/86400 + coefB;

o_timeAdj(idDated) = timeAdj;

return;
