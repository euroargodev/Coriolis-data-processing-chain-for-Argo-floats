% ------------------------------------------------------------------------------
% Correct dates from clock drift.
%
% SYNTAX :
%  [o_tabDate] = add_clock_drift_in_date(a_tabDate, a_floatClockDrift)
%
% INPUT PARAMETERS :
%   a_tabDate         : dates to be corrected
%   a_floatClockDrift : float clock drift
%
% OUTPUT PARAMETERS :
%   o_tabDate : corrected dates
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabDate] = add_clock_drift_in_date(a_tabDate, a_floatClockDrift)

% output parameters initialization
o_tabDate = [];

% default values
global g_decArgo_dateDef;

% round float drift to minutes
floatClockDrift = round(a_floatClockDrift*1440)/1440;

% correct dates
o_tabDate = a_tabDate;
idNoDef = find(a_tabDate ~= g_decArgo_dateDef);
o_tabDate(idNoDef) = a_tabDate(idNoDef) - floatClockDrift;

return;
