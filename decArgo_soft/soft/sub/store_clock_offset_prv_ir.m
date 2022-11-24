% ------------------------------------------------------------------------------
% Store clcock offset in a dedicated global structure.
%
% SYNTAX :
%  store_clock_offset_prv_ir(a_cycleNum, a_juldUtc, a_clockOffset)
%
% INPUT PARAMETERS :
%   a_cycleNum    : cycle number
%   a_juldUtc     : UTC time of the clock offset determination
%   a_clockOffset : clock offset value (in seconds)
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/09/2019 - RNU - creation
% ------------------------------------------------------------------------------
function store_clock_offset_prv_ir(a_cycleNum, a_juldUtc, a_clockOffset)

% clock offset storage
global g_decArgo_clockOffset;


g_decArgo_clockOffset.cycleNum = [g_decArgo_clockOffset.cycleNum a_cycleNum];
g_decArgo_clockOffset.juldUtc = [g_decArgo_clockOffset.juldUtc a_juldUtc];
g_decArgo_clockOffset.clockOffset = [g_decArgo_clockOffset.clockOffset a_clockOffset];

[~, idSort] = sort([g_decArgo_clockOffset.juldUtc]);
g_decArgo_clockOffset.cycleNum = g_decArgo_clockOffset.cycleNum(idSort);
g_decArgo_clockOffset.juldUtc = g_decArgo_clockOffset.juldUtc(idSort);
g_decArgo_clockOffset.clockOffset = g_decArgo_clockOffset.clockOffset(idSort);

return
