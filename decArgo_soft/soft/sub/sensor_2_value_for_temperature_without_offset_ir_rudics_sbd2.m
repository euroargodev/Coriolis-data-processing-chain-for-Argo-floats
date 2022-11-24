% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for temperatures (without offset).
%
% SYNTAX :
%  [o_tempValues] = sensor_2_value_for_temperature_without_offset_ir_rudics_sbd2(a_tempCounts)
%
% INPUT PARAMETERS :
%   a_tempCounts : temperature counts
%
% OUTPUT PARAMETERS :
%   o_tempValues : temperature values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tempValues] = sensor_2_value_for_temperature_without_offset_ir_rudics_sbd2(a_tempCounts)

% output parameters initialization
o_tempValues = [];

% default values
global g_decArgo_tempCountsDef;
global g_decArgo_tempDef;

% convert counts to values
o_tempValues = a_tempCounts;
idDef = find(a_tempCounts == g_decArgo_tempCountsDef);
o_tempValues(idDef) = ones(length(idDef), 1)*g_decArgo_tempDef;
idNoDef = find((a_tempCounts ~= g_decArgo_tempCountsDef));
o_tempValues(idNoDef) = o_tempValues(idNoDef)/1000;

return
