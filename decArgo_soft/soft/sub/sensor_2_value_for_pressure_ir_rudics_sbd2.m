% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for pressures.
%
% SYNTAX :
%  [o_presValues] = sensor_2_value_for_pressure_ir_rudics_sbd2(a_presCounts, a_decoderId)
%
% INPUT PARAMETERS :
%   a_presCounts : pressure counts
%   a_decoderId  : float decoder Id
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
function [o_presValues] = sensor_2_value_for_pressure_ir_rudics_sbd2(a_presCounts, a_decoderId)

% output parameters initialization
o_presValues = [];

% current float WMO number
global g_decArgo_floatNum;

% default values
global g_decArgo_presCountsDef;
global g_decArgo_presDef;


switch (a_decoderId)
   
   case {105, 106, 107, 109, 110, 301, 302, 303}
      
      % convert counts to values
      o_presValues = a_presCounts;
      idDef = find(a_presCounts == g_decArgo_presCountsDef);
      o_presValues(idDef) = ones(length(idDef), 1)*g_decArgo_presDef;
      idNoDef = find(a_presCounts ~= g_decArgo_presCountsDef);
      o_presValues(idNoDef) = o_presValues(idNoDef)/10;

   case {111}
      
      % convert counts to values
      o_presValues = a_presCounts;
      idDef = find(a_presCounts == g_decArgo_presCountsDef);
      o_presValues(idDef) = ones(length(idDef), 1)*g_decArgo_presDef;
      idNoDef = find(a_presCounts ~= g_decArgo_presCountsDef);
      o_presValues(idNoDef) = o_presValues(idNoDef)/10 - 100;
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in sensor_2_value_for_pressure_ir_rudics_sbd2 for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
