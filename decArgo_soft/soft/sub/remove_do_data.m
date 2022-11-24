% ------------------------------------------------------------------------------
% Remove DO data from profiles and trajectory.
% Used for float 6901763 where transmitted DO data come from another sensor
% when PT21=2 (PT21=2 has been set to PT21=0 at the decoding step).
%
% SYNTAX :
% function [o_tabProfiles, o_tabTrajNMeas] = remove_do_data(...
%    a_tabProfiles, a_tabTrajNMeas, a_tabTrajNCycle)
%
% INPUT PARAMETERS :
%   a_tabProfiles   : input profile structures
%   a_tabTrajNMeas  : input trajectory N_MEASUREMENT measurement structures
%   a_tabTrajNCycle : input trajectory N_CYCLE measurement structures
%
% OUTPUT PARAMETERS :
%   o_tabProfiles  : output profile structures
%   o_tabTrajNMeas : output trajectory N_MEASUREMENT measurement structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/11/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabTrajNMeas] = remove_do_data(...
   a_tabProfiles, a_tabTrajNMeas, a_tabTrajNCycle)

% output parameters initialization
o_tabProfiles = a_tabProfiles;
o_tabTrajNMeas = a_tabTrajNMeas;

% float configuration
global g_decArgo_floatConfig;


% create list of configurations numbers for which DO data should be removed
configNames = g_decArgo_floatConfig.DYNAMIC.NAMES;
configValues = g_decArgo_floatConfig.DYNAMIC.VALUES;

idPos = find(strncmp('CONFIG_PT21', configNames, length('CONFIG_PT21')) == 1, 1);
if (~isempty(idPos))
   configValueList = configValues(idPos, :);
   configNumList = find(configValueList == 0) - 1;
   configNumList = configNumList(find(configNumList > 0));
end

% remove DO data from profiles
for idProf = 1:length(o_tabProfiles)
   if (ismember(o_tabProfiles(idProf).configMissionNumber, configNumList))
      profParamNameList = {o_tabProfiles(idProf).paramList.name};
      idToKeep = [ ...
         find(strcmp('PRES', profParamNameList) == 1, 1), ...
         find(strcmp('TEMP', profParamNameList) == 1, 1), ...
         find(strcmp('PSAL', profParamNameList) == 1, 1)];
      idToDel = setdiff(1:length(profParamNameList), idToKeep);

      o_tabProfiles(idProf).paramList(idToDel) = [];
      o_tabProfiles(idProf).data(:, idToDel) = [];
      if (~isempty(o_tabProfiles(idProf).dataQc))
         o_tabProfiles(idProf).dataQc(:, idToDel) = [];
      end
      if (~isempty(o_tabProfiles(idProf).dataAdj))
         o_tabProfiles(idProf).dataAdj(:, idToDel) = [];
         if (~isempty(o_tabProfiles(idProf).dataAdjQc))
            o_tabProfiles(idProf).dataAdjQc(:, idToDel) = [];
         end
      end
   end
end

% remove DO data from trajectory
for idNCy = 1:length(a_tabTrajNCycle)
   if (ismember(a_tabTrajNCycle(idNCy).configMissionNumber, configNumList))
      idNMeas = find(a_tabTrajNCycle(idNCy).outputCycleNumber == [o_tabTrajNMeas.outputCycleNumber]);
      if (~isempty(idNMeas))
         for idMeas = 1:length(o_tabTrajNMeas(idNMeas).tabMeas)
            if (~isempty(o_tabTrajNMeas(idNMeas).tabMeas(idMeas).paramList))
               measParamNameList = {o_tabTrajNMeas(idNMeas).tabMeas(idMeas).paramList.name};
               idToKeep = [ ...
                  find(strcmp('PRES', measParamNameList) == 1, 1), ...
                  find(strcmp('TEMP', measParamNameList) == 1, 1), ...
                  find(strcmp('PSAL', measParamNameList) == 1, 1)];
               idToDel = setdiff(1:length(measParamNameList), idToKeep);
               
               if (~isempty(idToDel))
                  o_tabTrajNMeas(idNMeas).tabMeas(idMeas).paramList(idToDel) = [];
                  o_tabTrajNMeas(idNMeas).tabMeas(idMeas).paramData(:, idToDel) = [];
                  if (~isempty(o_tabTrajNMeas(idNMeas).tabMeas(idMeas).paramDataQc))
                     o_tabTrajNMeas(idNMeas).tabMeas(idMeas).paramDataQc(:, idToDel) = [];
                  end
                  if (~isempty(o_tabTrajNMeas(idNMeas).tabMeas(idMeas).paramDataAdj))
                     o_tabTrajNMeas(idNMeas).tabMeas(idMeas).paramDataAdj(:, idToDel) = [];
                     if (~isempty(o_tabTrajNMeas(idNMeas).tabMeas(idMeas).paramDataAdjQc))
                        o_tabTrajNMeas(idNMeas).tabMeas(idMeas).paramDataAdjQc(:, idToDel) = [];
                     end
                  end
               end
            end
         end
      end
   end
end

return
