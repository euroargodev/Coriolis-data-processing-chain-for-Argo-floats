% ------------------------------------------------------------------------------
% Add Iridium locations in Trajectory data.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle] = ...
%    add_iridium_locations_in_trajectory_data(a_tabTrajNMeas, a_tabTrajNCycle, a_iridiumMailData)
%
% INPUT PARAMETERS :
%   a_tabTrajNMeas    : input N_MEASUREMENT trajectory data
%   a_tabTrajNCycle   : input N_CYCLE trajectory data
%   a_iridiumMailData : Iridium mail contents
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas  : output N_MEASUREMENT trajectory data
%   o_tabTrajNCycle : output N_CYCLE trajectory data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%  08/23/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle] = ...
   add_iridium_locations_in_trajectory_data(a_tabTrajNMeas, a_tabTrajNCycle, a_iridiumMailData)

% output parameters initialization
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;

% global measurement codes
global g_MC_FMT;
global g_MC_Surface;
global g_MC_LMT;

% global time status
global g_JULD_STATUS_4;

% default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;


if (~isempty(a_iridiumMailData))
   
   cycleNumList = sort(unique([o_tabTrajNMeas.outputCycleNumber a_iridiumMailData.cycleNumber]));
   cycleNumList(cycleNumList == -1) = [];
   for idCy = 1:length(cycleNumList)
      cycleNum = cycleNumList(idCy);
      
      idNMeasForCy = find([o_tabTrajNMeas.outputCycleNumber] == cycleNum);
      if (isempty(idNMeasForCy))
         trajNMeasStruct = get_traj_n_meas_init_struct(cycleNum, -1);
         trajNMeasStruct.outputCycleNumber = cycleNum;
         o_tabTrajNMeas = [o_tabTrajNMeas trajNMeasStruct];
         idNMeasForCy = find([o_tabTrajNMeas.outputCycleNumber] == cycleNum);
      end
      
      idNCycleForCy = find([o_tabTrajNCycle.outputCycleNumber] == cycleNum);
      if (isempty(idNCycleForCy))
         trajNCycleStruct = get_traj_n_cycle_init_struct(cycleNum, -1);
         trajNCycleStruct.outputCycleNumber = cycleNum;
         o_tabTrajNCycle = [o_tabTrajNCycle trajNCycleStruct];
         idNCycleForCy = find([o_tabTrajNCycle.outputCycleNumber] == cycleNum);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % FISRT MESSAGE TIME
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      [firstMsgTime, lastMsgTime] = ...
         compute_first_last_msg_time_from_iridium_mail(a_iridiumMailData, cycleNum);
      
      if (firstMsgTime ~= g_decArgo_dateDef)

         measStruct = create_one_meas_surface(g_MC_FMT, ...
            firstMsgTime, ...
            g_decArgo_argosLonDef, [], [], [], [], 1);
         if (~isempty(o_tabTrajNMeas(idNMeasForCy).tabMeas))
            idF = find([o_tabTrajNMeas(idNMeasForCy).tabMeas.measCode] == g_MC_FMT);
            if (isempty(idF))
               o_tabTrajNMeas(idNMeasForCy).tabMeas = [o_tabTrajNMeas(idNMeasForCy).tabMeas; measStruct];
            else
               o_tabTrajNMeas(idNMeasForCy).tabMeas(idF) = measStruct; % FMT already set for INCOIS FLBB (based on packet dates)
            end
         else
            o_tabTrajNMeas(idNMeasForCy).tabMeas = [o_tabTrajNMeas(idNMeasForCy).tabMeas; measStruct];
         end
         
         [o_tabTrajNCycle(idNCycleForCy).juldFirstMessage] = deal(firstMsgTime);
         [o_tabTrajNCycle(idNCycleForCy).juldFirstMessageStatus] = deal(g_JULD_STATUS_4);
      end
            
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % IRIDIUM LOCATIONS
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      idFixForCycle = find([a_iridiumMailData.cycleNumber] == cycleNum);
      surfaceLocData = repmat(get_traj_one_meas_init_struct, length(idFixForCycle), 1);
      cpt = 1;
      for idFix = idFixForCycle
         if (a_iridiumMailData(idFix).cepRadius ~= 0)
            surfaceLocData(cpt) = create_one_meas_surface_with_error_ellipse(g_MC_Surface, ...
               a_iridiumMailData(idFix).timeOfSessionJuld, ...
               a_iridiumMailData(idFix).unitLocationLon, ...
               a_iridiumMailData(idFix).unitLocationLat, ...
               'I', ...
               0, ... % no need to set a Qc, it will be set during RTQC
               a_iridiumMailData(idFix).cepRadius*1000, ...
               a_iridiumMailData(idFix).cepRadius*1000, ...
               '', ...
               ' ', ...
               1);
            cpt = cpt + 1;
         end
      end
      surfaceLocData(cpt:end) = [];
      o_tabTrajNMeas(idNMeasForCy).tabMeas = [o_tabTrajNMeas(idNMeasForCy).tabMeas; surfaceLocData];

      % sort GPS and Iridium locations
      surfLocDate = [];
      if (~isempty(o_tabTrajNMeas(idNMeasForCy).tabMeas))
         idFSurfLoc = find([o_tabTrajNMeas(idNMeasForCy).tabMeas.measCode] == g_MC_Surface);
         surfLocDate = [o_tabTrajNMeas(idNMeasForCy).tabMeas(idFSurfLoc).juld];
         [~, idSort] = sort(surfLocDate);
         o_tabTrajNMeas(idNMeasForCy).tabMeas(idFSurfLoc) = o_tabTrajNMeas(idNMeasForCy).tabMeas(idFSurfLoc(idSort));
      end
      
      if (~isempty(surfLocDate))

         o_tabTrajNCycle(idNCycleForCy).juldFirstLocation = min(surfLocDate);
         o_tabTrajNCycle(idNCycleForCy).juldFirstLocationStatus = g_JULD_STATUS_4;
         
         o_tabTrajNCycle(idNCycleForCy).juldLastLocation = max(surfLocDate);
         o_tabTrajNCycle(idNCycleForCy).juldLastLocationStatus = g_JULD_STATUS_4;
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % LAST MESSAGE TIME
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      if (lastMsgTime ~= g_decArgo_dateDef)
         measStruct = create_one_meas_surface(g_MC_LMT, ...
            lastMsgTime, ...
            g_decArgo_argosLonDef, [], [], [], [], 1);
         if (~isempty(o_tabTrajNMeas(idNMeasForCy).tabMeas))
            idF = find([o_tabTrajNMeas(idNMeasForCy).tabMeas.measCode] == g_MC_LMT);
            if (isempty(idF))
               o_tabTrajNMeas(idNMeasForCy).tabMeas = [o_tabTrajNMeas(idNMeasForCy).tabMeas; measStruct];
            else
               o_tabTrajNMeas(idNMeasForCy).tabMeas(idF) = measStruct; % LMT already set for INCOIS FLBB (based on packet dates)
            end
         else
            o_tabTrajNMeas(idNMeasForCy).tabMeas = [o_tabTrajNMeas(idNMeasForCy).tabMeas; measStruct];
         end
         
         o_tabTrajNCycle(idNCycleForCy).juldLastMessage = lastMsgTime;
         o_tabTrajNCycle(idNCycleForCy).juldLastMessageStatus = g_JULD_STATUS_4;
      end
   end
end

return
