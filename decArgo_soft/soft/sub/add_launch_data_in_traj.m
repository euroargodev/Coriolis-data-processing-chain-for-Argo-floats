% ------------------------------------------------------------------------------
% Add float launch date and position in trajectory data structure.
%
% SYNTAX :
%  [o_tabTrajNMeas] = add_launch_data_in_traj(a_floatSurfData)
%
% INPUT PARAMETERS :
%   a_floatSurfData : float surface data structure
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas : N_MEASUREMENT trajectory data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas] = add_launch_data_in_traj(a_floatSurfData)

% output parameters initialization
o_tabTrajNMeas = [];

% global measurement codes
global g_MC_Launch;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FLOAT LAUNCH TIME AND POSITION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% structure to store N_MEASUREMENT data
trajNMeasStruct = get_traj_n_meas_init_struct(-1, -1);

measStruct = create_one_meas_surface(g_MC_Launch, ...
   a_floatSurfData.launchDate, ...
   a_floatSurfData.launchLon, ...
   a_floatSurfData.launchLat, ...
   ' ', ' ', '0', 0);

trajNMeasStruct.surfOnly = 1;
trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

% output data
o_tabTrajNMeas = trajNMeasStruct;

return
