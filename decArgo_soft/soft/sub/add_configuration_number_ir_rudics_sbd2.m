% ------------------------------------------------------------------------------
% Add the configuration number and the output cycle number to the profiles and
% the N_MEASUREMENT and N_CYCLE measurements.
%
% SYNTAX :
%  [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = ...
%    add_configuration_number_ir_rudics_sbd2( ...
%    a_tabProfiles, a_tabTrajNMeas, a_tabTrajNCycle, a_tabTechNMeas)
%
% INPUT PARAMETERS :
%   a_tabProfiles   : input profile structures
%   a_tabTrajNMeas  : input trajectory N_MEASUREMENT measurement structures
%   a_tabTrajNCycle : input trajectory N_CYCLE measurement structures
%   a_tabTechNMeas  : input technical N_MEASUREMENT measurement structures
%
% OUTPUT PARAMETERS :
%   o_tabProfiles   : output profile structures
%   o_tabTrajNMeas  : output trajectory N_MEASUREMENT measurement structures
%   o_tabTrajNCycle : output trajectory N_CYCLE measurement structures
%   o_tabTechNMeas  : output technical N_MEASUREMENT measurement structures
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = ...
   add_configuration_number_ir_rudics_sbd2( ...
   a_tabProfiles, a_tabTrajNMeas, a_tabTrajNCycle, a_tabTechNMeas)

% output parameters initialization
o_tabProfiles = [];
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];
o_tabTechNMeas = [];

% current float WMO number
global g_decArgo_floatNum;

% float configuration
global g_decArgo_floatConfig;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% report information structure
global g_decArgo_reportStruct;


% add the configuration number and the output cycle number of the profiles
for idProf = 1:length(a_tabProfiles)
   idConf = find((g_decArgo_floatConfig.USE.CYCLE == a_tabProfiles(idProf).cycleNumber) & ...
      (g_decArgo_floatConfig.USE.PROFILE == a_tabProfiles(idProf).profileNumber));
   if (~isempty(idConf))
      a_tabProfiles(idProf).configMissionNumber = g_decArgo_floatConfig.USE.CONFIG(idConf);
      
      if ((g_decArgo_realtimeFlag == 1) || (g_decArgo_delayedModeFlag == 1))
         if (a_tabProfiles(idProf).outputCycleNumber == -1)
            % update the reports structure cycle list
            g_decArgo_reportStruct = add_cycle_number_in_report_struct(g_decArgo_reportStruct, g_decArgo_floatConfig.USE.CYCLE_OUT(idConf));
         end
      end
      
      a_tabProfiles(idProf).outputCycleNumber = g_decArgo_floatConfig.USE.CYCLE_OUT(idConf);
   end
end

% add the output cycle number of the traj N_MEASUREMENT measurements
for idNCy = 1:length(a_tabTrajNMeas)
   idConf = find((g_decArgo_floatConfig.USE.CYCLE == a_tabTrajNMeas(idNCy).cycleNumber) & ...
      (g_decArgo_floatConfig.USE.PROFILE == a_tabTrajNMeas(idNCy).profileNumber));
   if (~isempty(idConf))
      a_tabTrajNMeas(idNCy).outputCycleNumber = g_decArgo_floatConfig.USE.CYCLE_OUT(idConf);
   end
end

% the configuration is set when data are transmitted
% the configuration of an EOL cycle without data transmission doesn't have any
% configuration defined yet, we will duplicate the last configuration for these
% cycles
idF = find(([a_tabTrajNMeas.cycleNumber] ~= -1) & ...
   ([a_tabTrajNMeas.outputCycleNumber] == -1) & ...
   ([a_tabTrajNMeas.profileNumber] ~= -1));
if (~isempty(idF))
   cyProfNum = unique([[a_tabTrajNMeas(idF).cycleNumber]' [a_tabTrajNMeas(idF).profileNumber]'], 'rows');
   
   if (~isempty(cyProfNum))
      
      inputUsedCy = g_decArgo_floatConfig.USE.CYCLE;
      inputUsedProf = g_decArgo_floatConfig.USE.PROFILE;
      inputUsedCyOut = g_decArgo_floatConfig.USE.CYCLE_OUT;
      inputUsedConfNum = g_decArgo_floatConfig.USE.CONFIG;
      
      % create new configuration for EOL cycle
      newCreated = 0;
      for idCP = 1:size(cyProfNum, 1)
         cyNum = cyProfNum(idCP, 1);
         profNum = cyProfNum(idCP, 2);
         idFCy = find(inputUsedCy == cyNum);
         if (isempty(idFCy))
            if (cyNum > 0)
               idFCyPrev = find(inputUsedCy <= cyNum-1, 1, 'last');
               cyNumPrev = inputUsedCy(idFCyPrev);
               idFCyPrev = find(inputUsedCy == cyNumPrev);
               idFCyProfPrev = idFCyPrev(find(inputUsedProf(idFCyPrev) == max(inputUsedProf(idFCyPrev))));
               
               inputUsedCy(end+1) = cyNum;
               inputUsedProf(end+1) = profNum;
               inputUsedCyOut(end+1) = -1;
               inputUsedConfNum(end+1) = inputUsedConfNum(idFCyProfPrev);
               newCreated = 1;
            else
               inputUsedCy(end+1) = cyNum;
               inputUsedProf(end+1) = profNum;
               inputUsedCyOut(end+1) = -1;
               inputUsedConfNum(end+1) = 1;
               newCreated = 1;
            end
         else
            if (profNum < max(inputUsedProf(idFCy)))
               if (max(inputUsedProf(idFCy)) == 0)
                  idFCyPrev = find(inputUsedCy == cyNum-1);
                  idFCyProfPrev = idFCyPrev(find(inputUsedProf(idFCyPrev) == max(inputUsedProf(idFCyPrev))));
               else
                  idFCyProfPrev = idFCy(find(inputUsedProf(idFCy) == max(inputUsedProf(idFCy))));
               end
               
               inputUsedCy(end+1) = cyNum;
               inputUsedProf(end+1) = profNum;
               inputUsedCyOut(end+1) = -1;
               inputUsedConfNum(end+1) = inputUsedConfNum(idFCyProfPrev);
               newCreated = 1;
            else
               shift = 1;
               idFCyProfPrev = [];
               while (profNum - shift >= 0)
                  idFCyProfPrev = idFCy(find(inputUsedProf(idFCy) == profNum - shift));
                  if (~isempty(idFCyProfPrev))
                     break
                  else
                     shift = shift + 1;
                  end
               end
               if (~isempty(idFCyProfPrev))
                  inputUsedCy(end+1) = cyNum;
                  inputUsedProf(end+1) = profNum;
                  inputUsedCyOut(end+1) = -1;
                  inputUsedConfNum(end+1) = inputUsedConfNum(idFCyProfPrev);
                  newCreated = 1;
               else
                  fprintf('ERROR: Float #%d: Cannot insert new configuration for trajectory data\n', ...
                     g_decArgo_floatNum);
               end
            end
         end
      end
      
      if (newCreated == 1)
         
         % create the expected final table (to find the output cycle numbers)
         finalCyNum = [];
         finalProfNum = [];
         for cyNum = 0:max(inputUsedCy)
            idF = find(inputUsedCy == cyNum);
            if (~isempty(idF))
               finalCyNum = [finalCyNum repmat(cyNum, 1, max(inputUsedProf(idF))+1)];
               finalProfNum = [finalProfNum 0:max(inputUsedProf(idF))];
            else
               finalCyNum = [finalCyNum cyNum];
               finalProfNum = [finalProfNum 0];
            end
         end
      
         % update output cycle numbers of EOL cycles
         for idCP = 1:size(cyProfNum, 1)
            cyNum = cyProfNum(idCP, 1);
            profNum = cyProfNum(idCP, 2);
            idFCyProf1 = find((cyNum == inputUsedCy) & ...
               (profNum == inputUsedProf));
            idFCyProf2 = find((cyNum == finalCyNum) & ...
               (profNum == finalProfNum));
            if (~isempty(idFCyProf1) && ~isempty(idFCyProf2))
               inputUsedCyOut(idFCyProf1) = idFCyProf2;
            end
         end
         
         g_decArgo_floatConfig.USE.CYCLE = inputUsedCy;
         g_decArgo_floatConfig.USE.PROFILE = inputUsedProf;
         g_decArgo_floatConfig.USE.CYCLE_OUT = inputUsedCyOut;
         g_decArgo_floatConfig.USE.CONFIG = inputUsedConfNum;

         % add the output cycle number of the N_MEASUREMENT measurements
         for idNCy = 1:length(a_tabTrajNMeas)
            idConf = find((g_decArgo_floatConfig.USE.CYCLE == a_tabTrajNMeas(idNCy).cycleNumber) & ...
               (g_decArgo_floatConfig.USE.PROFILE == a_tabTrajNMeas(idNCy).profileNumber));
            if (~isempty(idConf))
               a_tabTrajNMeas(idNCy).outputCycleNumber = g_decArgo_floatConfig.USE.CYCLE_OUT(idConf);
            end
         end
      end
      
      idF = find(([a_tabTrajNMeas.cycleNumber] ~= -1) & ...
         ([a_tabTrajNMeas.outputCycleNumber] == -1) & ...
         ([a_tabTrajNMeas.profileNumber] ~= -1));
      if (~isempty(idF))
         fprintf('ERROR: Float #%d: Some trajectory cycles have no configuration\n', ...
            g_decArgo_floatNum);
      end
   end
end

% add the configuration number and the output cycle number of the N_CYCLE
% measurements
for idNCy = 1:length(a_tabTrajNCycle)
   idConf = find((g_decArgo_floatConfig.USE.CYCLE == a_tabTrajNCycle(idNCy).cycleNumber) & ...
      (g_decArgo_floatConfig.USE.PROFILE == a_tabTrajNCycle(idNCy).profileNumber));
   if (~isempty(idConf))
      a_tabTrajNCycle(idNCy).outputCycleNumber = g_decArgo_floatConfig.USE.CYCLE_OUT(idConf);
      if (a_tabTrajNCycle(idNCy).surfOnly == 2)
         a_tabTrajNCycle(idNCy).outputCycleNumber = 0;
      end
      if (a_tabTrajNCycle(idNCy).outputCycleNumber > 0) % we don't assign any configuration to cycle #0 data
         a_tabTrajNCycle(idNCy).configMissionNumber = g_decArgo_floatConfig.USE.CONFIG(idConf);
      end
   else
      if (a_tabTrajNCycle(idNCy).cycleNumber == 0) && (a_tabTrajNCycle(idNCy).profileNumber == 0)
         a_tabTrajNCycle(idNCy).outputCycleNumber = 0;
      end
   end
end

% add the output cycle number of the tech N_MEASUREMENT measurements
for idNCy = 1:length(a_tabTechNMeas)
   idConf = find((g_decArgo_floatConfig.USE.CYCLE == a_tabTechNMeas(idNCy).cycleNumber) & ...
      (g_decArgo_floatConfig.USE.PROFILE == a_tabTechNMeas(idNCy).profileNumber));
   if (~isempty(idConf))
      a_tabTechNMeas(idNCy).outputCycleNumber = g_decArgo_floatConfig.USE.CYCLE_OUT(idConf);
   end
end

% update output parameters
o_tabProfiles = a_tabProfiles;
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;
o_tabTechNMeas = a_tabTechNMeas;

return
