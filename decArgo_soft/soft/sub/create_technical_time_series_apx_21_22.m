% ------------------------------------------------------------------------------
% Create time series of technical data (to be stored in TECH_AUX file).
%
% SYNTAX :
%  [o_tabTechNMeas] = create_technical_time_series_apx_21_22(a_techSeries, a_paramName)
%
% INPUT PARAMETERS :
%   a_techSeries : time series of technical data
%   a_paramName  : associated parameter name
%
% OUTPUT PARAMETERS :
%   o_tabTechNMeas  : N_MEASUREMENT structure of technical data time series
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/16/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTechNMeas] = create_technical_time_series_apx_21_22(a_techSeries, a_paramName)
         
% output parameters initialization
o_tabTechNMeas = [];

% current cycle number
global g_decArgo_cycleNum;

% global measurement codes
global g_MC_InAirSingleMeasRelativeToTET;

% global time status
global g_JULD_STATUS_4;


if (isempty(~isempty(a_techSeries.value)))
   return
end

% retrieve PARAM structure
param = get_netcdf_param_attributes(a_paramName);

% structure to store N_MEASUREMENT technical data
o_tabTechNMeas = get_traj_n_meas_init_struct(g_decArgo_cycleNum, -1);

% sort surface measurements
[~, idSort] = sort(a_techSeries.time);
a_techSeries.time = a_techSeries.time(idSort);
a_techSeries.value = a_techSeries.value(idSort);

% fill N_MEASUREMENT data
for idM = 1:length(a_techSeries.time);
   
   [measStruct, ~] = create_one_meas_float_time_bis( ...
      g_MC_InAirSingleMeasRelativeToTET, ...
      a_techSeries.time(idM), ...
      a_techSeries.time(idM), ...
      g_JULD_STATUS_4);
   if (~isempty(measStruct))
      measStruct.paramList = param;
      measStruct.paramData = a_techSeries.value(idM);
      
      o_tabTechNMeas.tabMeas = [o_tabTechNMeas.tabMeas; measStruct];
   end
end

return
