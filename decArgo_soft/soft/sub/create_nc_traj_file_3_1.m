% ------------------------------------------------------------------------------
% Create NetCDF MONO-TRAJECTORY c and b files.
%
% SYNTAX :
%  create_nc_traj_file_3_1( ...
%    a_decoderId, a_tabTrajNMeas, a_tabTrajNCycle, a_metaDataFromJson)
%
% INPUT PARAMETERS :
%   a_decoderId        : float decoder Id
%   a_tabTrajNMeas     : N_MEASUREMENT trajectory data
%   a_tabTrajNCycle    : N_CYCLE trajectory data
%   a_metaDataFromJson : additional information retrieved from JSON meta-data
%                        file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/20/2014 - RNU - creation
% ------------------------------------------------------------------------------
function create_nc_traj_file_3_1( ...
   a_decoderId, a_tabTrajNMeas, a_tabTrajNCycle, a_metaDataFromJson)

% create the c files
create_nc_traj_c_file_3_1(a_decoderId, a_tabTrajNMeas, a_tabTrajNCycle, a_metaDataFromJson);

% create the b files
create_nc_traj_b_file_3_1(a_decoderId, a_tabTrajNMeas, a_tabTrajNCycle, a_metaDataFromJson);

fprintf('... NetCDF TRAJECTORY files created\n');

return;
