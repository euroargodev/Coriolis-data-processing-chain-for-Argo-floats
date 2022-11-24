% ------------------------------------------------------------------------------
% Add float launch date and position to the N_MEASUREMENT data.
%
% SYNTAX :
%  [o_tabTrajNMeas] = add_launch_data_ir_rudics
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas : output trajectory N_MEASUREMENT data structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas] = add_launch_data_ir_rudics

% output parameters initialization
o_tabTrajNMeas = [];

% array to store GPS data
global g_decArgo_gpsData;

% global measurement codes
global g_MC_Launch;

% global time status
global g_JULD_STATUS_4;

% QC flag values (char)
global g_decArgo_qcStrNoQc;


% unpack the GPS data

if (~isempty(g_decArgo_gpsData))
   gpsLocCycleNum = g_decArgo_gpsData{1};
   gpsLocProfNum = g_decArgo_gpsData{2};
   gpsLocPhase = g_decArgo_gpsData{3};
   gpsLocDate = g_decArgo_gpsData{4};
   gpsLocLon = g_decArgo_gpsData{5};
   gpsLocLat = g_decArgo_gpsData{6};
   gpsLocQc = g_decArgo_gpsData{7};
   gpsLocAccuracy = g_decArgo_gpsData{8};
   gpsLocSbdFileDate = g_decArgo_gpsData{9};
   
   idLaunch = find((gpsLocCycleNum == -1) & (gpsLocProfNum == -1) & (gpsLocPhase == -1));
   if (~isempty(idLaunch))
      
      % structure to store N_MEASUREMENT data
      o_tabTrajNMeas = get_traj_n_meas_init_struct(-1, -1);

      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_Launch;
      measStruct.juld = gpsLocDate(idLaunch);
      measStruct.juldStatus = g_JULD_STATUS_4;
      measStruct.juldQc = g_decArgo_qcStrNoQc;
      measStruct.juldAdj = gpsLocDate(idLaunch);
      measStruct.juldAdjStatus = g_JULD_STATUS_4;
      measStruct.juldAdjQc = g_decArgo_qcStrNoQc;
      measStruct.latitude = gpsLocLat(idLaunch);
      measStruct.longitude = gpsLocLon(idLaunch);
      measStruct.posAccuracy = gpsLocAccuracy(idLaunch);
      measStruct.posQc = num2str(gpsLocQc(idLaunch));
            
      o_tabTrajNMeas.surfOnly = 1;
      o_tabTrajNMeas.tabMeas = measStruct;
   end
end

return
