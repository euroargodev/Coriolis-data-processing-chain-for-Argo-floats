% ------------------------------------------------------------------------------
% Convert a julian 1950 date to an EPOCH (1970) one.
%
% SYNTAX :
%  [o_epoch70] = julian_2_epoch70(a_julDay)
%
% INPUT PARAMETERS :
%   a_julDay : julian 1950 date
%
% OUTPUT PARAMETERS :
%   o_epoch70 : EPOCH 1970 date
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/18/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_epoch70] = julian_2_epoch70(a_julDay)

% reference date (01/01/1970)
global g_decArgo_janFirst1970InJulD;

o_epoch70 = uint64(round((a_julDay - g_decArgo_janFirst1970InJulD)*86400));

return
