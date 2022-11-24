% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for pressures.
%
% SYNTAX :
%  [o_presValues] = sensor_2_value_for_pressure_ir_rudics_sbd2(a_presCounts)
%
% INPUT PARAMETERS :
%   a_presCounts : pressure counts
%
% OUTPUT PARAMETERS :
%   o_presValues : pressure values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_presValues] = sensor_2_value_for_pressure_ir_rudics_sbd2(a_presCounts)

% output parameters initialization
o_presValues = [];

% default values
global g_decArgo_presCountsDef;
global g_decArgo_presDef;

% convert counts to values
o_presValues = a_presCounts;
idDef = find(a_presCounts == g_decArgo_presCountsDef);
o_presValues(idDef) = ones(length(idDef), 1)*g_decArgo_presDef;
idNoDef = find(a_presCounts ~= g_decArgo_presCountsDef);
o_presValues(idNoDef) = o_presValues(idNoDef)/10;

return;
