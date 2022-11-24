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

% default values
global g_decArgo_dateDef;

% global measurement codes
global g_MC_CycleStart;
global g_MC_DST;
global g_MC_FST;
global g_MC_SpyInDescToPark;
global g_MC_DescProf;
global g_MC_MaxPresInDescToPark;
global g_MC_DescProfDeepestBin;
global g_MC_PST;
global g_MC_SpyAtPark;
global g_MC_DriftAtPark;
global g_MC_MinPresInDriftAtPark;
global g_MC_MaxPresInDriftAtPark;
global g_MC_PET;
global g_MC_RPP;
global g_MC_SpyInDescToProf;
global g_MC_MaxPresInDescToProf;
global g_MC_DPST;
global g_MC_SpyAtProf;
global g_MC_MinPresInDriftAtProf;
global g_MC_MaxPresInDriftAtProf;
global g_MC_AST;
global g_MC_AscProfDeepestBin;
global g_MC_SpyInAscProf;
global g_MC_AscProf;
global g_MC_LastAscPumpedCtd;
global g_MC_AET;
global g_MC_TST;
global g_MC_FMT;
global g_MC_Surface;
global g_MC_LMT;
global g_MC_TET;
global g_MC_Grounded;
global g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;
global g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;

% global time status
global g_JULD_STATUS_1;
global g_JULD_STATUS_2;
global g_JULD_STATUS_4;
global g_JULD_STATUS_9;

% default values
global g_decArgo_ncDateDef;
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_c1C2PhaseDoxyDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_doxyDef;


if (~isempty(a_iridiumMailData))
   
   cycleNumList = sort(unique([o_tabTrajNMeas.cycleNumber a_iridiumMailData.cycleNumber]));
   cycleNumList(cycleNumList == -1) = [];
   for idCy = 1:length(cycleNumList)
      cycleNum = cycleNumList(idCy);
      
      idNMeasForCy = find([o_tabTrajNMeas.cycleNumber] == cycleNum);
      if (isempty(idNMeasForCy))
         trajNMeasStruct = get_traj_n_meas_init_struct(cycleNum, -1);
         o_tabTrajNMeas = [o_tabTrajNMeas trajNMeasStruct];
         idNMeasForCy = find([o_tabTrajNMeas.cycleNumber] == cycleNum);
      end
      
      idNCycleForCy = find([o_tabTrajNCycle.cycleNumber] == cycleNum);
      if (isempty(idNCycleForCy))
         trajNCycleStruct = get_traj_n_cycle_init_struct(cycleNum, -1);
         o_tabTrajNCycle = [o_tabTrajNCycle trajNCycleStruct];
         idNCycleForCy = find([o_tabTrajNCycle.cycleNumber] == cycleNum);
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
         idF = find([o_tabTrajNMeas(idNMeasForCy).tabMeas.measCode] == g_MC_FMT);
         if (isempty(idF))
            o_tabTrajNMeas(idNMeasForCy).tabMeas = [o_tabTrajNMeas(idNMeasForCy).tabMeas; measStruct];
         else
            o_tabTrajNMeas(idNMeasForCy).tabMeas(idF) = measStruct; % FMT already set for INCOIS FLBB (based on packet dates)
         end
         
         [o_tabTrajNCycle(idNCycleForCy).juldFirstMessage] = deal(firstMsgTime);
         [o_tabTrajNCycle(idNCycleForCy).juldFirstMessageStatus] = deal(g_JULD_STATUS_4);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % GPS LOCATIONS
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      idFGps = find([o_tabTrajNMeas(idNMeasForCy).tabMeas.measCode] == g_MC_Surface);
      gpsCyLocDate = [o_tabTrajNMeas(idNMeasForCy).tabMeas(idFGps).juld];
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % IRIDIUM LOCATIONS
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      idFixForCycle = find([a_iridiumMailData.cycleNumber] == cycleNum);
      for idFix = idFixForCycle
         if (a_iridiumMailData(idFix).cepRadius ~= 0)
            measStruct = create_one_meas_surface_with_error_ellipse(g_MC_Surface, ...
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
            o_tabTrajNMeas(idNMeasForCy).tabMeas = [o_tabTrajNMeas(idNMeasForCy).tabMeas; measStruct];
         end
      end
      iridiumCyLocDate = [a_iridiumMailData(idFixForCycle).timeOfSessionJuld];
      
      if (~isempty(gpsCyLocDate) || ~isempty(iridiumCyLocDate))
         locDates = [gpsCyLocDate iridiumCyLocDate];
         
         o_tabTrajNCycle(idNCycleForCy).juldFirstLocation = min(locDates);
         o_tabTrajNCycle(idNCycleForCy).juldFirstLocationStatus = g_JULD_STATUS_4;
         
         o_tabTrajNCycle(idNCycleForCy).juldLastLocation = max(locDates);
         o_tabTrajNCycle(idNCycleForCy).juldLastLocationStatus = g_JULD_STATUS_4;
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % LAST MESSAGE TIME
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      if (lastMsgTime ~= g_decArgo_dateDef)
         measStruct = create_one_meas_surface(g_MC_LMT, ...
            lastMsgTime, ...
            g_decArgo_argosLonDef, [], [], [], [], 1);
         idF = find([o_tabTrajNMeas(idNMeasForCy).tabMeas.measCode] == g_MC_LMT);
         if (isempty(idF))
            o_tabTrajNMeas(idNMeasForCy).tabMeas = [o_tabTrajNMeas(idNMeasForCy).tabMeas; measStruct];
         else
            o_tabTrajNMeas(idNMeasForCy).tabMeas(idF) = measStruct; % LMT already set for INCOIS FLBB (based on packet dates)
         end
         
         o_tabTrajNCycle(idNCycleForCy).juldLastMessage = lastMsgTime;
         o_tabTrajNCycle(idNCycleForCy).juldLastMessageStatus = g_JULD_STATUS_4;
      end
   end
end

return
