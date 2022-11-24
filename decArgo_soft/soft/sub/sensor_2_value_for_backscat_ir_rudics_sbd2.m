% ------------------------------------------------------------------------------
% Convert sensor counts values for backscatter.
%
% SYNTAX :
%  [o_backscatValues] = sensor_2_value_for_backscat_ir_rudics_sbd2(a_backscatCounts)
%
% INPUT PARAMETERS :
%   a_backscatCounts : input backscatter counts
%
% OUTPUT PARAMETERS :
%   o_backscatValues : output backscatter counts
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_backscatValues] = sensor_2_value_for_backscat_ir_rudics_sbd2(a_backscatCounts)

% output parameters initialization
o_backscatValues = [];

% default values
global g_decArgo_backscatCountsDef;
global g_decArgo_backscatDef;

% convert counts to values
o_backscatValues = a_backscatCounts;
idDef = find(a_backscatCounts == g_decArgo_backscatCountsDef);
o_backscatValues(idDef) = ones(length(idDef), 1)*g_decArgo_backscatDef;
idNoDef = find(a_backscatCounts ~= g_decArgo_backscatCountsDef);
o_backscatValues(idNoDef) = o_backscatValues(idNoDef)/10;

return;
