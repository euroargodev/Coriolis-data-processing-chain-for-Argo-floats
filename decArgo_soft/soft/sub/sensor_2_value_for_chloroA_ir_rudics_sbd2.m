% ------------------------------------------------------------------------------
% Convert sensor counts values for chlorophyll A.
%
% SYNTAX :
%  [o_chloroAValues] = sensor_2_value_for_chloroA_ir_rudics_sbd2(a_chloroACounts)
%
% INPUT PARAMETERS :
%   a_chloroACounts : input chlorophyll A counts
%
% OUTPUT PARAMETERS :
%   o_chloroAValues : output chlorophyll A values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_chloroAValues] = sensor_2_value_for_chloroA_ir_rudics_sbd2(a_chloroACounts)

% output parameters initialization
o_chloroAValues = [];

% default values
global g_decArgo_chloroACountsDef;
global g_decArgo_chloroADef;

% convert counts to values
o_chloroAValues = a_chloroACounts;
idDef = find(a_chloroACounts == g_decArgo_chloroACountsDef);
o_chloroAValues(idDef) = ones(length(idDef), 1)*g_decArgo_chloroADef;
idNoDef = find(a_chloroACounts ~= g_decArgo_chloroACountsDef);
o_chloroAValues(idNoDef) = o_chloroAValues(idNoDef)/10;

return
