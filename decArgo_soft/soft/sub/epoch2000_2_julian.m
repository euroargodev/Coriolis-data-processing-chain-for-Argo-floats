% ------------------------------------------------------------------------------
% Convert EPOCH 2000 date to Julian date.
%
% SYNTAX :
%  [o_julDay] = epoch2000_2_julian(a_epoch2000)
%
% INPUT PARAMETERS :
%   a_epoch2000 : EPOCH 2000 date
%
% OUTPUT PARAMETERS :
%   o_julDay : associated Julian date
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_julDay] = epoch2000_2_julian(a_epoch2000)

% reference date (01/01/2000)
global g_decArgo_janFirst2000InJulD;

o_julDay = g_decArgo_janFirst2000InJulD + a_epoch2000/86400;

return
