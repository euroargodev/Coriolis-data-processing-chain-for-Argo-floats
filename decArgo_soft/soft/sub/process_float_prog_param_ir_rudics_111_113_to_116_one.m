% ------------------------------------------------------------------------------
% Process one packet of float programmed parameter data for TECH NetCDF file.
%
% SYNTAX :
%  process_float_prog_param_ir_rudics_111_113_to_116_one( ...
%    a_dataIndex, a_floatProgParam)
%
% INPUT PARAMETERS :
%   a_dataIndex      : index of the packet
%   a_floatProgParam : float programmed parameter data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function process_float_prog_param_ir_rudics_111_113_to_116_one( ...
   a_dataIndex, a_floatProgParam)

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;


% cycle, prof and phase number coded in the packet
cycleNum = a_floatProgParam(a_dataIndex, 2);
profNum = a_floatProgParam(a_dataIndex, 3);

% RECEIVED REMOTE CONTROL

% Number of received remote control
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   255 cycleNum profNum -1 300];
g_decArgo_outputNcParamValue{end+1} = a_floatProgParam(a_dataIndex, 4) - a_floatProgParam(a_dataIndex, 5);

% Number of rejected remote control
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   255 cycleNum profNum -1 301];
g_decArgo_outputNcParamValue{end+1} = a_floatProgParam(a_dataIndex, 5);

return
