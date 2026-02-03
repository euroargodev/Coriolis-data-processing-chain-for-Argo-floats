% ------------------------------------------------------------------------------
% As Transmission End Time is provided with one cycle offset, we processed it
% once all data have been received and update TRAJ data consequently.
%
% SYNTAX :
% [o_tabTrajNMeas, o_tabTrajNCycle, o_tabProfiles] = ...
%   process_delayed_data_pfv2(a_tabTrajNMeas, a_tabTrajNCycle, a_tabProfiles)
%
% INPUT PARAMETERS :
%   a_tabTrajNMeas  : input trajectory N_MEASUREMENT data
%   a_tabTrajNCycle : input trajectory N_CYCLE data
%   a_tabProfiles   : input profile data
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas  : output trajectory N_MEASUREMENT data
%   o_tabTrajNCycle : output trajectory N_CYCLE data
%   o_tabProfiles   : output profile data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/03/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle, o_tabProfiles] = ...
   process_delayed_data_pfv2(a_tabTrajNMeas, a_tabTrajNCycle, a_tabProfiles)

% output parameters initialization
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;
o_tabProfiles = a_tabProfiles;

% current float WMO number
global g_decArgo_floatNum;

% array to store GPS data
global g_decArgo_gpsData;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;

% TET management
global g_decArgo_transTimes;

% global measurement codes
global g_MC_FMT;
global g_MC_Surface;
global g_MC_LMT;
global g_MC_TET;

% global time status
global g_JULD_STATUS_2;
global g_JULD_STATUS_4;

% default values
global g_decArgo_argosLonDef;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% finalize TET management data
cyNumList = unique([g_decArgo_transTimes.cycleNum]);
for cyNum = cyNumList
   idF1 = find(([g_decArgo_transTimes.cycleNum] == cyNum) & ([g_decArgo_transTimes.techNum] == 1));
   idF2 = find(g_decArgo_transTimes.cycleClockOffset(:, 1) == cyNum - 1);
   if (~isempty(idF1) && ~isempty(idF2))
      transEndTimePrevCy = g_decArgo_transTimes.transEndTimePrevCy(idF1);
      transEndTimePrevCyAdj = adjust_time_pfv2(transEndTimePrevCy, g_decArgo_transTimes.cycleClockOffset(idF2, 2:end), '');
      g_decArgo_transTimes.transEndTimePrevCyAdj(idF1) = transEndTimePrevCyAdj;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create final list of TST and TET
tabCyNum = cyNumList;
tabTst = nan(size(tabCyNum));
tabTstAdj = nan(size(tabCyNum));
tabTet = nan(size(tabCyNum));
tabTetAdj = nan(size(tabCyNum));
for idC = 1:length(tabCyNum)
   idF = find([g_decArgo_transTimes.cycleNum] == tabCyNum(idC));
   if (~isempty(idF))
      tst = [g_decArgo_transTimes.transStartTime(idF)];
      tst(isnan(tst)) = [];
      if (~isempty(tst))
         tabTst(idC) = min(tst);
      end
      tstAdj = [g_decArgo_transTimes.transStartTimeAdj(idF)];
      tstAdj(isnan(tstAdj)) = [];
      if (~isempty(tstAdj))
         tabTstAdj(idC) = min(tstAdj);
      end
   end
   idF1 = find(([g_decArgo_transTimes.cycleNum] == tabCyNum(idC)) & ([g_decArgo_transTimes.techNum] == 1));
   idF2 = find(([g_decArgo_transTimes.cycleNum] == tabCyNum(idC) + 1) & ([g_decArgo_transTimes.techNum] == 2));
   tet = [];
   tetAdj = [];
   if (~isempty(idF1))
      tet = [g_decArgo_transTimes.transEndTimePrevCy(idF1)];
      tetAdj = [g_decArgo_transTimes.transEndTimePrevCyAdj(idF1)];
   end
   if (~isempty(idF2))
      tet = [tet [g_decArgo_transTimes.transEndTimePrevCy(idF2)]];
      tetAdj = [tetAdj [g_decArgo_transTimes.transEndTimePrevCyAdj(idF2)]];
   end
   tet(isnan(tet)) = [];
   tetAdj(isnan(tetAdj)) = [];
   if (~isempty(tet))
      tabTet(idC) = max(tet);
   end
   if (~isempty(tetAdj))
      tabTetAdj(idC) = max(tetAdj);
   end
end

% create list of final (best) TST and TET times
tabTstF = tabTst;
idNoNan = find(~isnan(tabTstAdj));
tabTstF(idNoNan) = tabTstAdj(idNoNan);
tabTetF = tabTet;
idNoNan = find(~isnan(tabTetAdj));
tabTetF(idNoNan) = tabTetAdj(idNoNan);

% in case of EOL and reset of the float some dates should be assigned to the
% previous cycle (see 5907190 #77)
cyNumList = [o_tabTrajNCycle.cycleNumber];
for cyNum = cyNumList
   idNM = find([o_tabTrajNMeas.cycleNumber] == cyNum);
   idT = find(tabCyNum == cyNum - 1);
   if (~isempty(idNM) && ~isempty(idT))
      for id = idNM
         if (~isempty(o_tabTrajNMeas(id).tabMeas))
            idNotDated = find(cellfun(@isempty, {o_tabTrajNMeas(id).tabMeas.juld}));
            idDated= setdiff(1:length((o_tabTrajNMeas(id).tabMeas)), idNotDated);
            idToMove = find([o_tabTrajNMeas(id).tabMeas(idDated).juld] <= tabTetF(idT));
            if (~isempty(idToMove))

               % update GPS data
               idGps = find([o_tabTrajNMeas(id).tabMeas(idDated(idToMove)).measCode] == g_MC_Surface);
               if (~isempty(idGps))
                  gpsLocCycleNum = g_decArgo_gpsData{1};
                  gpsLocDate = g_decArgo_gpsData{4};
                  for idG = idGps
                     idF = find(gpsLocDate == o_tabTrajNMeas(id).tabMeas(idDated(idToMove(idG))).juld);
                     if (gpsLocCycleNum(idF) == cyNum)
                        gpsLocCycleNum(idF) = cyNum - 1;
                     end
                  end
                  g_decArgo_gpsData{1} = gpsLocCycleNum;
                  g_decArgo_gpsData{2} = gpsLocDate;
               end

               % update TRAJ data
               idF = find(([o_tabTrajNMeas.cycleNumber] == cyNum-1) & ...
                  ([o_tabTrajNMeas.surfOnly] == o_tabTrajNMeas(id).surfOnly));
               if (~isempty(idF))
                  o_tabTrajNMeas(idF).tabMeas = [o_tabTrajNMeas(idF).tabMeas; o_tabTrajNMeas(id).tabMeas(idDated(idToMove))];
               else
                  newTrajNMeas = o_tabTrajNMeas(id);
                  newTrajNMeas.cycleNumber = cyNum-1;
                  newTrajNMeas.tabMeas = o_tabTrajNMeas(id).tabMeas(idDated(idToMove));
                  o_tabTrajNMeas = [o_tabTrajNMeas, newTrajNMeas];
               end
               o_tabTrajNMeas(id).tabMeas(idDated(idToMove)) = [];
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% assign a cycle number to each transmission session (i.e. to each mail file)
if (~isempty(g_decArgo_transTimes.cycleNum))
   for idC = 1:length(tabCyNum)
      cyNum = tabCyNum(idC);
      if (idC == 1)
         if (cyNum == 0)
            idF = find([g_decArgo_iridiumMailData.timeOfSessionJuld] <= tabTetF(idC));
         else
            idF = find([g_decArgo_iridiumMailData.timeOfSessionJuld] < tabTstF(idC));
         end
         cyNumList = zeros(1, length(idF));
         cyNumList = num2cell(cyNumList);
         [g_decArgo_iridiumMailData(idF).cycleNumber] = deal(cyNumList{:});
         if (cyNum == 0)
            continue
         end
      end

      idF = find(([g_decArgo_iridiumMailData.timeOfSessionJuld] >= tabTstF(idC)) & ...
         ([g_decArgo_iridiumMailData.timeOfSessionJuld] <= tabTetF(idC)));
      if (any([g_decArgo_iridiumMailData(idF).cycleNumber] ~= -1))
         fprintf('ERROR: Float #%d: Cycle number already set for some mail file\n', ...
            g_decArgo_floatNum);
      end
      cyNumList = ones(1, length(idF))*cyNum;
      cyNumList = num2cell(cyNumList);
      [g_decArgo_iridiumMailData(idF).cycleNumber] = deal(cyNumList{:});
   end
   % the TET of the last cycle is unknown, some mail remains without cycle
   % number
   if (any([g_decArgo_iridiumMailData.cycleNumber] == -1))
      idNotSet = find([g_decArgo_iridiumMailData.cycleNumber] == -1);
      for id = idNotSet
         idF1 = find(g_decArgo_iridiumMailData(id).timeOfSessionJuld <= (tabTetF + 1/86400), 1, 'first');
         if (~isempty(idF))
            g_decArgo_iridiumMailData(id).cycleNumber = tabCyNum(idF1);
         else
            idF2 = find(g_decArgo_iridiumMailData(id).timeOfSessionJuld >= (tabTstF - 1/86400), 1, 'last');
            if (~isempty(idF2))
               g_decArgo_iridiumMailData(id).cycleNumber = tabCyNum(idF2);
            end
         end
      end
   end
else
   cyNumList = zeros(1, length(g_decArgo_iridiumMailData));
   cyNumList = num2cell(cyNumList);
   [g_decArgo_iridiumMailData.cycleNumber] = deal(cyNumList{:});
end
if (any([g_decArgo_iridiumMailData.cycleNumber] == -1))
   fprintf('ERROR: Float #%d: Some mail files without cycle number\n', ...
      g_decArgo_floatNum);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update TRAJ data

cyNumList = [o_tabTrajNCycle.cycleNumber];
for cyNum = cyNumList
   idNM = find([o_tabTrajNMeas.cycleNumber] == cyNum);
   idNC = find([o_tabTrajNCycle.cycleNumber] == cyNum);
   idT = find(tabCyNum == cyNum);

   idF = find([g_decArgo_iridiumMailData.cycleNumber] == cyNum);
   if (~isempty(idF))

      clockDriftKnown = ~isempty(o_tabTrajNCycle(idNC).clockOffset);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % FIRST AND LAST MESSAGE TIMES
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      firstMsgTime = min([g_decArgo_iridiumMailData(idF).timeOfSessionJuld]);
      lastMsgTime = max([g_decArgo_iridiumMailData(idF).timeOfSessionJuld]);

      measStruct = create_one_meas_surface(g_MC_FMT, ...
         firstMsgTime, ...
         g_decArgo_argosLonDef, [], [], [], [], clockDriftKnown);
      o_tabTrajNMeas(idNM).tabMeas = [o_tabTrajNMeas(idNM).tabMeas; measStruct];

      measStruct = create_one_meas_surface(g_MC_LMT, ...
         lastMsgTime, ...
         g_decArgo_argosLonDef, [], [], [], [], clockDriftKnown);
      o_tabTrajNMeas(idNM).tabMeas = [o_tabTrajNMeas(idNM).tabMeas; measStruct];

      o_tabTrajNCycle(idNC).juldFirstMessage = firstMsgTime;
      o_tabTrajNCycle(idNC).juldFirstMessageStatus = g_JULD_STATUS_4;
      o_tabTrajNCycle(idNC).juldLastMessage = lastMsgTime;
      o_tabTrajNCycle(idNC).juldLastMessageStatus = g_JULD_STATUS_4;

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % IRIDIUM LOCATIONS
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      surfaceLocData = repmat(get_traj_one_meas_init_struct, length(idF), 1);
      cpt = 1;
      for idFix = idF
         if (g_decArgo_iridiumMailData(idFix).cepRadius ~= 0)
            surfaceLocData(cpt) = create_one_meas_surface_with_error_ellipse(g_MC_Surface, ...
               g_decArgo_iridiumMailData(idFix).timeOfSessionJuld, ...
               g_decArgo_iridiumMailData(idFix).unitLocationLon, ...
               g_decArgo_iridiumMailData(idFix).unitLocationLat, ...
               'I', ...
               0, ... % no need to set a Qc, it will be set during RTQC
               g_decArgo_iridiumMailData(idFix).cepRadius*1000, ...
               g_decArgo_iridiumMailData(idFix).cepRadius*1000, ...
               '', ...
               ' ', ...
               clockDriftKnown);
            cpt = cpt + 1;
         end
      end
      surfaceLocData(cpt:end) = [];
      o_tabTrajNMeas(idNM).tabMeas = [o_tabTrajNMeas(idNM).tabMeas; surfaceLocData];

      % sort GPS and Iridium fixes in chronological order
      idS = find([o_tabTrajNMeas(idNM).tabMeas.measCode] == g_MC_Surface);
      tabMeasSurf = o_tabTrajNMeas(idNM).tabMeas(idS);
      tabMeasSurfTimes = [tabMeasSurf.juld];
      [~, idSort] = sort(tabMeasSurfTimes);
      o_tabTrajNMeas(idNM).tabMeas(idS) = tabMeasSurf(idSort);

      o_tabTrajNCycle(idNC).juldFirstLocation = min(tabMeasSurfTimes);
      o_tabTrajNCycle(idNC).juldFirstLocationStatus = g_JULD_STATUS_4;
      o_tabTrajNCycle(idNC).juldLastLocation = max(tabMeasSurfTimes);
      o_tabTrajNCycle(idNC).juldLastLocationStatus = g_JULD_STATUS_4;

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % TRANSMISSION END TIME
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      if (~isempty(idT) && ~isnan(tabTet(idT)))
         idTet = find([o_tabTrajNMeas(idNM).tabMeas.measCode] == g_MC_TET);
         [measStruct, nCycleTime] = create_one_meas_float_time_pfv2( ...
            g_MC_TET, ...
            tabTet(idT), g_JULD_STATUS_2, tabTetAdj(idT));
         o_tabTrajNMeas(idNM).tabMeas(idTet) = measStruct;

         trajNCycleStruct.juldTransmissionEnd = nCycleTime;
         trajNCycleStruct.juldTransmissionEndStatus = g_JULD_STATUS_2;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update PROF data

% add profile date and location
for idP = 1:length(o_tabProfiles)
   prof = o_tabProfiles(idP);

   idNC = find([o_tabTrajNCycle.cycleNumber] == prof.cycleNumber);
   descentToParkStartDate = o_tabTrajNCycle(idNC).juldDescentStart;
   ascentEndDate = o_tabTrajNCycle(idNC).juldAscentEnd;
   transStartDate = o_tabTrajNCycle(idNC).juldTransmissionStart;

   o_tabProfiles(idP) = add_profile_date_and_location_201_to_230_40x_2001_to_2003( ...
      prof, g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
      descentToParkStartDate, ascentEndDate, transStartDate);
end

return

