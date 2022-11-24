% ------------------------------------------------------------------------------
% Check consistency between N_CYCLE and N_MEASUREMENT arrays.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle] = set_n_cycle_vs_n_meas_consistency( ...
%    a_tabTrajNMeas, a_tabTrajNCycle)
%
% INPUT PARAMETERS :
%   a_tabTrajNMeas  : input N_MEASUREMENT trajectory data
%   a_tabTrajNCycle : input N_CYCLE trajectory data
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
%   10/30/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle] = set_n_cycle_vs_n_meas_consistency( ...
   a_tabTrajNMeas, a_tabTrajNCycle)

% output parameters initialization
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;

% current float WMO number
global g_decArgo_floatNum;

% default values
global g_decArgo_ncDateDef;
global g_decArgo_argosLonDef;

% global measurement codes
global g_MC_DST;
global g_MC_FST;
global g_MC_DET;
global g_MC_PST;
global g_MC_PET;
global g_MC_DDET;
global g_MC_DPST;
global g_MC_AST;
global g_MC_AET;
global g_MC_TST;
global g_MC_FMT;
global g_MC_Surface;
global g_MC_LMT;
global g_MC_TET;
global g_MC_Grounded;

% global time status
global g_JULD_STATUS_fill_value;


% if only launch information is stored in the data TRAJ structure, we will not
% generate TRAJ file
if ((length(o_tabTrajNMeas) == 1) && (length(o_tabTrajNMeas(1).tabMeas) == 1))
   o_tabTrajNMeas = [];
   o_tabTrajNCycle = [];
   return
end

% remove cycles with no TRAJ data information (Ex: 3902105 #54, under Ice with
% no data => only TECH information)
idNMeasToDelete = [];
for idCy = 1:length(o_tabTrajNMeas)
   if (isempty(o_tabTrajNMeas(idCy).tabMeas))
      idNMeasToDelete = [idNMeasToDelete idCy];
   end
end
o_tabTrajNMeas(idNMeasToDelete) = [];

idNCyToDelete = [];
for idCy = 1:length(o_tabTrajNCycle)
   if (~any([o_tabTrajNMeas.outputCycleNumber] == o_tabTrajNCycle(idCy).outputCycleNumber))
      idNCyToDelete = [idNCyToDelete idCy];
   end
end
o_tabTrajNCycle(idNCyToDelete) = [];

% previous version
% idNMeasToDelete = [];
% idNCyToDelete = [];
% for idCy = 1:length(o_tabTrajNMeas)
%    if (isempty(o_tabTrajNMeas(idCy).tabMeas))
%       idNMeasToDelete = [idNMeasToDelete idCy];
%       idF = find([o_tabTrajNCycle.outputCycleNumber] == o_tabTrajNMeas(idCy).outputCycleNumber);
%       idNCyToDelete = [idNCyToDelete idF];
%    end
% end
% o_tabTrajNMeas(idNMeasToDelete) = [];
% o_tabTrajNCycle(idNCyToDelete) = [];

% check N_CYCLE data
MC_LIST = [ ...
   {g_MC_DST} {'juldDescentStart'} {'juldDescentStartStatus'}; ...
   {g_MC_FST} {'juldFirstStab'} {'juldFirstStabStatus'}; ...
   {g_MC_DET} {'juldDescentEnd'} {'juldDescentEndStatus'}; ...
   {g_MC_PST} {'juldParkStart'} {'juldParkStartStatus'}; ...
   {g_MC_PET} {'juldParkEnd'} {'juldParkEndStatus'}; ...
   {g_MC_DDET} {'juldDeepDescentEnd'} {'juldDeepDescentEndStatus'}; ...
   {g_MC_DPST} {'juldDeepParkStart'} {'juldDeepParkStartStatus'}; ...
   {g_MC_AST} {'juldAscentStart'} {'juldAscentStartStatus'}; ...
   {g_MC_AET} {'juldAscentEnd'} {'juldAscentEndStatus'}; ...
   {g_MC_TST} {'juldTransmissionStart'} {'juldTransmissionStartStatus'}; ...
   {g_MC_FMT} {'juldFirstMessage'} {'juldFirstMessageStatus'}; ...
   {g_MC_LMT} {'juldLastMessage'} {'juldLastMessageStatus'}; ...
   {g_MC_TET} {'juldTransmissionEnd'} {'juldTransmissionEndStatus'} ...
   ];

for idNCy = 1:length(o_tabTrajNCycle)
   trajNCycle = o_tabTrajNCycle(idNCy);
   cycleNum = trajNCycle.outputCycleNumber;

   idFNMeas = find([o_tabTrajNMeas.outputCycleNumber] == cycleNum);
   % check consistency for MC_LIST items
   for idMc = 1:size(MC_LIST, 1)
      measCode = MC_LIST{idMc, 1};
      measField = MC_LIST{idMc, 2};
      measStatusField = MC_LIST{idMc, 3};
      juldFinal = [];
      juldStatusFinal = [];
      for idNMeas = 1:length(idFNMeas)
         trajNMeas = o_tabTrajNMeas(idFNMeas(idNMeas));
         trajNMeas.tabMeas([trajNMeas.tabMeas.sensorNumber] > 100) = []; % bounce cycles have theri DST, DET, AST and AET stored in TRAJ_AUX
         if (~isempty(trajNMeas.tabMeas) && any([trajNMeas.tabMeas.measCode] == measCode))
            idF = find([trajNMeas.tabMeas.measCode] == measCode);
            if (length(idF) == 1)
               if (isempty(trajNMeas.tabMeas(idF).juldAdj) || ...
                     (trajNMeas.tabMeas(idF).juldAdj == g_decArgo_ncDateDef))
                  juld = trajNMeas.tabMeas(idF).juld;
                  juldStatus = trajNMeas.tabMeas(idF).juldStatus;
               else
                  juld = trajNMeas.tabMeas(idF).juldAdj;
                  juldStatus = trajNMeas.tabMeas(idF).juldAdjStatus;
               end
            else
               fprintf('WARNING: Float #%d Cycle #%d: MC=%d is present %d times in the decoded data\n', ...
                  g_decArgo_floatNum, cycleNum, ...
                  measCode, length(idF));
               
               % the file should be processed in DM, however we must choose on
               % of the measurements to prevent the decoding from crashing
               
               % from 6901651 anomaly
               if (measCode == g_MC_TST)
                  if (any([trajNMeas.tabMeas(idF).juldAdj] ~= g_decArgo_ncDateDef))
                     idF2 = find([trajNMeas.tabMeas(idF).juldAdj] ~= g_decArgo_ncDateDef);
                     juld = trajNMeas.tabMeas(idF(idF2(1))).juldAdj;
                     juldStatus = trajNMeas.tabMeas(idF(1)).juldAdjStatus;
                  elseif (any([trajNMeas.tabMeas(idF).juld] ~= g_decArgo_ncDateDef))
                     idF2 = find([trajNMeas.tabMeas(idF).juld] ~= g_decArgo_ncDateDef);
                     juld = trajNMeas.tabMeas(idF(idF2(1))).juld;
                     juldStatus = trajNMeas.tabMeas(idF(1)).juldStatus;
                  else
                     juld = g_decArgo_ncDateDef;
                     juldStatus = g_JULD_STATUS_fill_value;
                  end
               elseif (measCode == g_MC_TST)
                  if (any([trajNMeas.tabMeas(idF).juldAdj] ~= g_decArgo_ncDateDef))
                     idF2 = find([trajNMeas.tabMeas(idF).juldAdj] ~= g_decArgo_ncDateDef);
                     juld = trajNMeas.tabMeas(idF(idF2(end))).juldAdj;
                     juldStatus = trajNMeas.tabMeas(idF(end)).juldAdjStatus;
                  elseif (any([trajNMeas.tabMeas(idF).juld] ~= g_decArgo_ncDateDef))
                     idF2 = find([trajNMeas.tabMeas(idF).juld] ~= g_decArgo_ncDateDef);
                     juld = trajNMeas.tabMeas(idF(idF2(end))).juld;
                     juldStatus = trajNMeas.tabMeas(idF(end)).juldStatus;
                  else
                     juld = g_decArgo_ncDateDef;
                     juldStatus = g_JULD_STATUS_fill_value;
                  end
               end
            end
            if (isempty(juldFinal) || (juldFinal == g_decArgo_ncDateDef))
               juldFinal = juld;
               juldStatusFinal = juldStatus;
            end
         end
      end
      if ((isempty(trajNCycle.(measField)) && ~isempty(juldFinal)) || ...
            (~isempty(trajNCycle.(measField)) && isempty(juldFinal)) || ...
            (~isempty(trajNCycle.(measField)) && ~isempty(juldFinal) && (trajNCycle.(measField) ~= juldFinal)))
         %          fprintf('INFO: Float #%d Cycle #%d: N_CYCLE / N_MEAS consistent (%s:%s, MC%d:%s) - N_CYCLE updated\n', ...
         %             g_decArgo_floatNum, cycleNum, ...
         %             measField, julian_2_gregorian_dec_argo(trajNCycle.(measField)), ...
         %             measCode, julian_2_gregorian_dec_argo(juldFinal));
         o_tabTrajNCycle(idNCy).(measField) = juldFinal;
      end
      if ((isempty(trajNCycle.(measStatusField)) && ~isempty(juldStatusFinal)) || ...
            (~isempty(trajNCycle.(measStatusField)) && isempty(juldStatusFinal)) || ...
            (~isempty(trajNCycle.(measStatusField)) && ~isempty(juldStatusFinal) && (trajNCycle.(measStatusField) ~= juldStatusFinal)))
         %          fprintf('INFO: Float #%d Cycle #%d: N_CYCLE / N_MEAS consistent (%s:%s, MC%d:%s) - N_CYCLE updated\n', ...
         %             g_decArgo_floatNum, cycleNum, ...
         %             measStatusField, trajNCycle.(measStatusField), ...
         %             measCode, juldStatusFinal);
         o_tabTrajNCycle(idNCy).(measStatusField) = juldStatusFinal;
      end
   end
   
   % check consistency for JULD_FIRST_LOCATION(_STATUS) and JULD_LAST_LOCATION(_STATUS)
   juld = [];
   juldStatus = [];
   for idNMeas = 1:length(idFNMeas)
      trajNMeas = o_tabTrajNMeas(idFNMeas(idNMeas));
      if (~isempty(trajNMeas.tabMeas) && any([trajNMeas.tabMeas.measCode] == g_MC_Surface))
         idFSurf = find([trajNMeas.tabMeas.measCode] == g_MC_Surface);
         for idSurf = 1:length(idFSurf)
            if (~isempty(trajNMeas.tabMeas(idFSurf(idSurf)).longitude) && ...
                  (trajNMeas.tabMeas(idFSurf(idSurf)).longitude ~= g_decArgo_argosLonDef))
               if (isempty(trajNMeas.tabMeas(idFSurf(idSurf)).juldAdj) || ...
                     (trajNMeas.tabMeas(idFSurf(idSurf)).juldAdj == g_decArgo_ncDateDef))
                  juld = [juld trajNMeas.tabMeas(idFSurf(idSurf)).juld];
                  juldStatus = [juldStatus trajNMeas.tabMeas(idFSurf(idSurf)).juldStatus];
               else
                  juld = [juld trajNMeas.tabMeas(idFSurf(idSurf)).juldAdj];
                  juldStatus = [juldStatus trajNMeas.tabMeas(idFSurf(idSurf)).juldAdjStatus];
               end
            end
         end
      end
   end
   [juldMin, idMin] = min(juld);
   [juldMax, idMax] = max(juld);
   juldStatusMin = juldStatus(idMin);
   juldStatusMax = juldStatus(idMax);
   if ((isempty(trajNCycle.juldFirstLocation) && ~isempty(juldMin)) || ...
         (~isempty(trajNCycle.juldFirstLocation) && isempty(juldMin)) || ...
         (~isempty(trajNCycle.juldFirstLocation) && ~isempty(juldMin) && (trajNCycle.juldFirstLocation ~= juldMin)))
      %       fprintf('INFO: Float #%d Cycle #%d: N_CYCLE / N_MEAS consistent (juldFirstLocation:%s, %s) - N_CYCLE updated\n', ...
      %          g_decArgo_floatNum, cycleNum, ...
      %          julian_2_gregorian_dec_argo(trajNCycle.juldFirstLocation), ...
      %          julian_2_gregorian_dec_argo(juldMin));
      o_tabTrajNCycle(idNCy).juldFirstLocation = juldMin;
   end
   if ((isempty(trajNCycle.juldFirstLocationStatus) && ~isempty(juldStatusMin)) || ...
         (~isempty(trajNCycle.juldFirstLocationStatus) && isempty(juldStatusMin)) || ...
         (~isempty(trajNCycle.juldFirstLocationStatus) && ~isempty(juldStatusMin) && (trajNCycle.juldFirstLocationStatus ~= juldStatusMin)))
      %       fprintf('INFO: Float #%d Cycle #%d: N_CYCLE / N_MEAS consistent (juldFirstLocationStatus:%s, %s) - N_CYCLE updated\n', ...
      %          g_decArgo_floatNum, cycleNum, ...
      %          trajNCycle.juldFirstLocationStatus, ...
      %          juldStatus);
      o_tabTrajNCycle(idNCy).juldFirstLocationStatus = juldStatusMin;
   end
   if ((isempty(trajNCycle.juldLastLocation) && ~isempty(juldMax)) || ...
         (~isempty(trajNCycle.juldLastLocation) && isempty(juldMax)) || ...
         (~isempty(trajNCycle.juldLastLocation) && ~isempty(juldMax) && (trajNCycle.juldLastLocation ~= juldMax)))
      %       fprintf('INFO: Float #%d Cycle #%d: N_CYCLE / N_MEAS consistent (juldLastLocation:%s, %s) - N_CYCLE updated\n', ...
      %          g_decArgo_floatNum, cycleNum, ...
      %          julian_2_gregorian_dec_argo(trajNCycle.juldLastLocation), ...
      %          julian_2_gregorian_dec_argo(juldMax));
      o_tabTrajNCycle(idNCy).juldLastLocation = juldMax;
   end
   if ((isempty(trajNCycle.juldLastLocationStatus) && ~isempty(juldStatusMax)) || ...
         (~isempty(trajNCycle.juldLastLocationStatus) && isempty(juldStatusMax)) || ...
         (~isempty(trajNCycle.juldLastLocationStatus) && ~isempty(juldStatusMax) && (trajNCycle.juldLastLocationStatus ~= juldStatusMax)))
      %       fprintf('INFO: Float #%d Cycle #%d: N_CYCLE / N_MEAS consistent (juldLastLocationStatus:%s, %s) - N_CYCLE updated\n', ...
      %          g_decArgo_floatNum, cycleNum, ...
      %          trajNCycle.juldLastLocationStatus, ...
      %          juldStatus);
      o_tabTrajNCycle(idNCy).juldLastLocationStatus = juldStatusMax;
   end
   
   % check consistency for GROUNDED
   grdFlag = 0;
   for idNMeas = 1:length(idFNMeas)
      trajNMeas = o_tabTrajNMeas(idFNMeas(idNMeas));
      if (~isempty(trajNMeas.tabMeas) && any([trajNMeas.tabMeas.measCode] == g_MC_Grounded))
         grdFlag = 1;
      end
   end
   if ((grdFlag == 1) && (trajNCycle.grounded ~= 'Y'))
      %       fprintf('INFO: Float #%d Cycle #%d: N_CYCLE / N_MEAS consistent (grounded:''%c'', ''Y'') - N_CYCLE updated\n', ...
      %          g_decArgo_floatNum, cycleNum, ...
      %          trajNCycle.grounded);
      o_tabTrajNCycle(idNCy).grounded = 'Y';
   end
end

return
