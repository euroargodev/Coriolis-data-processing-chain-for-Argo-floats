% ------------------------------------------------------------------------------
% Report in trajectory data the RT adjustments done in profile data.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle] = ...
%    report_rt_adjusted_profile_data_in_trajectory( ...
%    a_tabTrajNMeas, a_tabTrajNCycle, a_tabProfiles)
%
% INPUT PARAMETERS :
%   a_tabTrajNMeas  : input N_MEASUREMENT trajectory data
%   a_tabTrajNCycle : input N_CYCLE trajectory data
%   a_tabProfiles   : input profile structures
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
%   06/28/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle] = ...
   report_rt_adjusted_profile_data_in_trajectory( ...
   a_tabTrajNMeas, a_tabTrajNCycle, a_tabProfiles)

% output parameters initialization
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;

% global measurement codes
global g_MC_DescProf;
global g_MC_DescProfDeepestBin;
global g_MC_AscProfDeepestBin;
global g_MC_AscProf;


for idProf = 1:length(a_tabProfiles)
   profile = a_tabProfiles(idProf);
   if (~isempty(profile.paramDataMode) && any(profile.paramDataMode == 'A'))
      
      if (profile.direction == 'A')
         refMeasCodeList = [g_MC_AscProf g_MC_AscProfDeepestBin];
      else
         refMeasCodeList = [g_MC_DescProf g_MC_DescProfDeepestBin];
      end
      idStruct = find([o_tabTrajNMeas.outputCycleNumber] == profile.outputCycleNumber); % nominal case: only one
      
      for idS = 1:length(idStruct)
         tabTrajNMeas = o_tabTrajNMeas(idStruct(idS));
         for idMc = 1:length(refMeasCodeList)
            idMeas = find([tabTrajNMeas.tabMeas.measCode] == refMeasCodeList(idMc));
            for idM = 1:length(idMeas)
               tabTrajNMeas.tabMeas(idMeas(idM)) = ...
                  update_meas(tabTrajNMeas.tabMeas(idMeas(idM)), profile);
            end
            o_tabTrajNMeas(idStruct(idS)) = tabTrajNMeas;
         end
      end
   end
end

% update DATA_MODE
if (~isempty(o_tabTrajNCycle))
   if (any([o_tabTrajNCycle.dataMode] ~= 'A'))
      idCyList = find([o_tabTrajNCycle.dataMode] ~= 'A');
      for idCy = 1:length(idCyList)
         idStruct = find([o_tabTrajNMeas.outputCycleNumber] == o_tabTrajNCycle(idCyList(idCy)).outputCycleNumber); % nominal case: only one
         for idS = 1:length(idStruct)
            tabTrajNMeas = o_tabTrajNMeas(idStruct(idS));
            if (any([tabTrajNMeas.tabMeas.paramDataMode] == 'A'))
               o_tabTrajNCycle(idCyList(idCy)).dataMode = 'A';
               break
            end
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Report in one trajectory measurement the RT adjustment done in profile data.
%
% SYNTAX :
%  [o_nMeas] = update_meas(a_nMeas, a_profile)
%
% INPUT PARAMETERS :
%   a_nMeas   : input trajectory measurement
%   a_profile : input profile data
%
% OUTPUT PARAMETERS :
%   o_nMeas : output trajectory measurement
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/28/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_nMeas] = update_meas(a_nMeas, a_profile)

% output parameters initialization
o_nMeas = a_nMeas;

% current float WMO number
global g_decArgo_floatNum;

% QC flag values (numerical)
global g_decArgo_qcDef;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% look for the profile level reported in the TRAJ measurement

% get list of common parameters
commonParamList = intersect({o_nMeas.paramList.name}, {a_profile.paramList.name}, 'stable');

% collect data for common parameters
profData = [];
trajData = [];
for idLoop =1:2
   if (idLoop == 1)
      inputStruct = a_profile;
      inputData = a_profile.data;
   else
      inputStruct = o_nMeas;
      inputData = o_nMeas.paramData;
   end
   data = [];
   for idP = 1:length(commonParamList)
      idParam = find(strcmp({inputStruct.paramList.name}, commonParamList{idP}), 1);
      firstCol = idParam;
      lastCol = firstCol;
      if (~isempty(inputStruct.paramNumberWithSubLevels))
         idSub = find(inputStruct.paramNumberWithSubLevels < idParam);
         if (~isempty(idSub))
            firstCol = firstCol + sum(inputStruct.paramNumberOfSubLevels(idSub)) - length(idSub);
            lastCol = firstCol;
         end
         idSub = find(inputStruct.paramNumberWithSubLevels == idParam);
         if (~isempty(idSub))
            lastCol = lastCol + inputStruct.paramNumberOfSubLevels(idSub) - 1;
         end
      end
      data = [data inputData(:, firstCol:lastCol)];
   end
   if (idLoop == 1)
      profData = data;
   else
      trajData = data;
   end
end

% find the concerned profile level(s)
idLevel = find(sum(profData == trajData, 2) == length(trajData));

if (isempty(idLevel))
   %    if (~strncmp(a_profile.vertSamplingScheme, 'Near-surface sampling:', length('Near-surface sampling:'))) % it is not unusual to have no dated bin in the NS profile
   %       fprintf('ERROR: Float #%d cycle #%d: one MEAS not found in profile\n', ...
   %          g_decArgo_floatNum, a_profile.outputCycleNumber);
   %    end
   %    return
   % elseif (length(idLevel) > 1)
   %    fprintf('ERROR: Float #%d cycle #%d: one MEAS found multiple (%d) times in profile\n', ...
   %       g_decArgo_floatNum, a_profile.outputCycleNumber, length(idLevel));
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update the TRAJ measurement with profile adjusted data

% list of profile adjusted parameters
idParam = find(a_profile.paramDataMode == 'A');
adjParamaNameList = {a_profile.paramList(idParam).name};

for idP = 1:length(adjParamaNameList)
   if (any(strcmp({o_nMeas.paramList.name}, adjParamaNameList{idP})))
      
      % the current adjusted parameter is in the TRAJ file => update the
      % concerned measurement
      for idLoop =1:2
         if (idLoop == 1)
            inputStruct = a_profile;
         else
            inputStruct = o_nMeas;
         end
         idParam = find(strcmp({inputStruct.paramList.name}, adjParamaNameList{idP}), 1);
         firstCol = idParam;
         lastCol = firstCol;
         if (~isempty(inputStruct.paramNumberWithSubLevels))
            idSub = find(inputStruct.paramNumberWithSubLevels < idParam);
            if (~isempty(idSub))
               firstCol = firstCol + sum(inputStruct.paramNumberOfSubLevels(idSub)) - length(idSub);
               lastCol = firstCol;
            end
            idSub = find(inputStruct.paramNumberWithSubLevels == idParam);
            if (~isempty(idSub))
               lastCol = lastCol + inputStruct.paramNumberOfSubLevels(idSub) - 1;
            end
         end
         if (idLoop == 1)
            
            % store profile adjusted data for the concerned level(s)
            profDataAdj = a_profile.dataAdj(idLevel, firstCol:lastCol);
            if (~isempty(a_profile.dataAdjQc))
               profDataAdjQc = a_profile.dataAdjQc(idLevel, firstCol);
            else
               profDataAdjQc = [];
            end
            if (~isempty(a_profile.dataAdjError))
               profDataAdjError = a_profile.dataAdjError(idLevel, firstCol:lastCol);
            else
               profDataAdjError = [];
            end
            
            % in case of multiple levels, be sure that the adjusted value is the
            % same
            ok = 1;
            if (length(profDataAdj) > 1)
               if (length(unique(profDataAdj)) > 1)
                  ok = 0;
               else
                  if (~isempty(profDataAdjQc))
                     if (length(unique(profDataAdjQc)) > 1)
                        ok = 0;
                     end
                  end
                  if (~isempty(profDataAdjError))
                     if (length(unique(profDataAdjError)) > 1)
                        ok = 0;
                     end
                  end
               end
            end
            if (ok == 1)
               profDataAdj = unique(profDataAdj);
               profDataAdjQc = unique(profDataAdjQc);
               profDataAdjError = unique(profDataAdjError);
            else
               %                fprintf('WARNING: Float #%d cycle #%d%c: one MEAS found multiple (%d) times in profile\n', ...
               %                   g_decArgo_floatNum, a_profile.outputCycleNumber, a_profile.direction, length(idLevel));
               break
            end
         else

            % create array for adjusted data
            paramFillValue = get_prof_param_fill_value(o_nMeas);
            if (isempty(o_nMeas.paramDataAdj))
               o_nMeas.paramDataMode = repmat(' ', 1, length(o_nMeas.paramList));
               o_nMeas.paramDataAdj = repmat(double(paramFillValue), size(o_nMeas.paramData, 1), 1);
            end
            if (isempty(o_nMeas.paramDataAdjQc) && ~isempty(profDataAdjQc))
               o_nMeas.paramDataAdjQc = ones(size(o_nMeas.paramDataAdj, 1), length(o_nMeas.paramList))*g_decArgo_qcDef;
            end
            if (isempty(o_nMeas.paramDataAdjError) && ~isempty(profDataAdjError))
               o_nMeas.paramDataAdjError = repmat(double(paramFillValue), size(o_nMeas.paramData, 1), 1);
            end
            
            % even if the parameter is adjusted some level may not be
            if (profDataAdj ~= paramFillValue)
               
               % report profile adjusted data in TRAJ measurement
               o_nMeas.paramDataMode(idParam) = 'A';
               o_nMeas.paramDataAdj(:, firstCol:lastCol) = profDataAdj;
               if (~isempty(profDataAdjQc))
                  o_nMeas.paramDataAdjQc(:, idParam) = profDataAdjQc;
               end
               if (~isempty(profDataAdjError))
                  o_nMeas.paramDataAdjError(:, firstCol:lastCol) = profDataAdjError;
               end
            end
         end
      end
   end
end

% check consistency of o_nMeas output
if (~isempty(o_nMeas.paramDataMode))
   if (all(o_nMeas.paramDataMode == ' '))
      o_nMeas.paramDataMode = [];
      o_nMeas.paramDataAdj = [];
      o_nMeas.paramDataAdjQc = [];
      o_nMeas.paramDataAdjError = [];
   end
end

return
