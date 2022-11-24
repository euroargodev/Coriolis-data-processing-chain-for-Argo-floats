% ------------------------------------------------------------------------------
% Adjust PRES values of BGC measurements sampled during the drift phase.
% Adjust PRES values of all SUNA measurements.
%
% Concerning BGC measurements sampled during the drift phase:
% An issue has been discovered on the first versions (Coriolis versions: 7.11,
% 7.12 and 7.13) of the PROVOR CTS5-USEA floats. The PRES values of the BGC
% measurements sampled during the drift phase are not always updated with the
% timely closest associated CTD PRES values.
%
% Concerning SUNA measurement pressures:
% The PRES value transmitted by thz float is the one of the PTS CTD measurement
% sent to the SUNA to compute a NITRATE value, thus it is sampled before the
% SUNA measurement.
% We will update this PRES value (in PRES_ADJUSTED) with the timely closest 
% associated CTD PRES values (using the SUNA adjusted time which is the estimate
% of the SUNA measurement reporting time).
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = adjust_bgc_pres_cts5_usea(a_tabProfiles, a_tabDrift)
%
% INPUT PARAMETERS :
%   a_tabProfiles : input profile structures
%   a_tabDrift    : input drift profile structures
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : output profile structures
%   o_tabDrift    : output drift profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/01/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift] = adjust_bgc_pres_cts5_usea(a_tabProfiles, a_tabDrift)

% output parameters initialization
o_tabProfiles = a_tabProfiles;
o_tabDrift = a_tabDrift;

% current cycle number
global g_decArgo_cycleNum;

% to store information on adjustments
global g_decArgo_paramTrajAdjInfo;
global g_decArgo_paramTrajAdjId;
global g_decArgo_paramProfAdjInfo;
global g_decArgo_paramProfAdjId;

% decoded event data
global g_decArgo_eventDataTraj;

% global measurement codes
global g_MC_DescProf;
global g_MC_DriftAtPark;
global g_MC_Desc2Prof;
global g_MC_DriftAtProf;
global g_MC_AscProf;


if (isempty(o_tabProfiles) && isempty(a_tabDrift))
   return
end


% we use pressure check measurements to adjust BGC PRES values (even if their
% resolution is mainly 1 dbar whereas it is 1 cbar for BCG pressures)
% we also use CTD measurements (in case SYSTEM file is missing or unreadable)

presCheckJuld = [];
presCheckPres = [];
if (~isempty(g_decArgo_eventDataTraj))
   
   % retrieve pressure checks sampled during the drift phase
   presCheckEvt = cell2mat(g_decArgo_eventDataTraj)';
   presCheckMc = [presCheckEvt.measCode];
   idDrift = find(ismember(presCheckMc, [g_MC_DescProf, g_MC_DriftAtPark, g_MC_Desc2Prof, g_MC_DriftAtProf, g_MC_AscProf]));
   eventDataTrajDrift = g_decArgo_eventDataTraj(idDrift);
   presCheckDrift = cell2mat(eventDataTrajDrift)';
   groupList = [presCheckDrift.group];
   uGroupList = unique(groupList(find(groupList > 0)));
   presCheckJuld = [];
   presCheckPres = [];
   for idG = 1:length(uGroupList)
      idF = find(groupList == uGroupList(idG));
      if (length(idF) == 2)
         juld = '';
         pres = '';
         for id = 1:2
            if (strcmp(eventDataTrajDrift{idF(id)}.paramName, 'JULD'))
               juld = eventDataTrajDrift{idF(id)}.value;
            elseif (strcmp(eventDataTrajDrift{idF(id)}.paramName, 'PRES'))
               pres = double(eventDataTrajDrift{idF(id)}.value);
            end
         end
         if (~isempty(juld) && ~isempty(pres))
            presCheckJuld = [presCheckJuld juld];
            presCheckPres = [presCheckPres pres];
         end
      end
   end
   [~, idSort] = sort(presCheckJuld);
   presCheckJuld = presCheckJuld(idSort);
   presCheckPres = presCheckPres(idSort);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BGC DRIFT MEASURMENTS

% collect information on drift profiles
profInfo = [];
for idProf = 1:length(o_tabDrift)

   profile = o_tabDrift(idProf);
   profInfo = [profInfo;
      idProf profile.sensorNumber profile.cycleNumber profile.profileNumber];
end

% adjust BGC pressures with CTD ones
doneForDrift = 0;
for idProf = 1:size(profInfo, 1)
   if (profInfo(idProf, 2) ~= 0)
      idCtd = find((profInfo(:, 2) == 0) & (profInfo(:, 3) == profInfo(idProf, 3)) & (profInfo(:, 4) == profInfo(idProf, 4)));
      if (~isempty(idCtd))
         tabDriftCtd = o_tabDrift(profInfo(idCtd, 1));
      else
         tabDriftCtd = [];
      end
      [o_tabDrift(profInfo(idProf, 1)), doneForProf] = adjust_bgc_pres(o_tabDrift(profInfo(idProf, 1)), tabDriftCtd, presCheckJuld, presCheckPres);
      if (doneForProf == 1)
         doneForDrift = 1;
      end
   end
end

if (doneForDrift)
   if ~(~isempty(g_decArgo_paramTrajAdjInfo) && any([g_decArgo_paramTrajAdjInfo{:, 2}] == 4))

      param = 'PRES';
      equation = 'PRES_ADJUSTED = time interpolated CTD PRES (for BGC pressures sampled during the drift phase at parking depth that are not consistent with CTD PRES (from PTS measurements or pressure checks))';
      coefficient = 'not applicable';
      comment = 'Inconsistent BGC pressures, sampled during the drift phase at parking depth, are adjusted in real time with time interpolated CTD pressures (from PTS measurements or pressure checks). Concerned Measurement Codes are: 290 and 301.';

      g_decArgo_paramTrajAdjInfo = [g_decArgo_paramTrajAdjInfo;
         g_decArgo_paramTrajAdjId 4 -1 ...
         {param} {equation} {coefficient} {comment} {''}];
      g_decArgo_paramTrajAdjId = g_decArgo_paramTrajAdjId + 1;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUNA PROFILE MEASURMENTS

% collect information on profiles
profInfo = [];
for idProf = 1:length(o_tabProfiles)

   profile = o_tabProfiles(idProf);
   if ((profile.sensorNumber == 0) || (profile.sensorNumber == 6))

      direction = 2;
      if (profile.direction == 'D')
         direction = 1;
      end
      profInfo = [profInfo;
         idProf profile.sensorNumber direction profile.cycleNumber profile.profileNumber];
   end
end

% adjust SUNA pressures with CTD ones
if (~isempty(profInfo))
   if (any(profInfo(:, 2) == 6))
      for idDir = 1:2
         for idProf = 1:size(profInfo, 1)
            if ((profInfo(idProf, 2) == 6) && (profInfo(idProf, 3) == idDir))
               idCtd = find((profInfo(:, 2) == 0) & (profInfo(:, 3) == profInfo(idProf, 3)) & ...
                  (profInfo(:, 4) == profInfo(idProf, 4)) & (profInfo(:, 5) == profInfo(idProf, 5)));
               if (~isempty(idCtd))
                  tabProfileCtd = o_tabProfiles(profInfo(idCtd, 1));
               else
                  tabProfileCtd = [];
               end

               [o_tabProfiles(profInfo(idProf, 1)), doneForProf] = adjust_bgc_pres_all(o_tabProfiles(profInfo(idProf, 1)), tabProfileCtd, presCheckJuld, presCheckPres);

               if (doneForProf == 1)

                  o_tabProfiles(profInfo(idProf, 1)).rtParamAdjIdList = [o_tabProfiles(profInfo(idProf, 1)).rtParamAdjIdList g_decArgo_paramProfAdjId];

                  param = 'PRES';
                  equation = 'PRES_ADJUSTED = time interpolated CTD PRES';
                  coefficient = 'not applicable';
                  comment = 'SUNA pressures, sampled during the profiling descent and ascent phases, are adjusted in real time with time interpolated CTD pressures (from PTS measurements or pressure checks).';

                  g_decArgo_paramProfAdjInfo = [g_decArgo_paramProfAdjInfo;
                     g_decArgo_paramProfAdjId o_tabProfiles(profInfo(idProf, 1)).outputCycleNumber o_tabProfiles(profInfo(idProf, 1)).direction ...
                     {param} {equation} {coefficient} {comment} {''}];
                  g_decArgo_paramProfAdjId = g_decArgo_paramProfAdjId + 1;

                  if ~(~isempty(g_decArgo_paramTrajAdjInfo) && any([g_decArgo_paramTrajAdjInfo{:, 2}] == 5))

                     param = 'PRES';
                     equation = 'PRES_ADJUSTED = time interpolated CTD PRES (for SUNA pressures sampled during the profiling descent and ascent phases)';
                     coefficient = 'not applicable';
                     comment = 'SUNA pressures, sampled during the profiling descent and ascent phases, are adjusted in real time with time interpolated CTD pressures (from PTS measurements or pressure checks). Concerned Measurement Codes are: 190, 203, 503 and 590.';

                     g_decArgo_paramTrajAdjInfo = [g_decArgo_paramTrajAdjInfo;
                        g_decArgo_paramTrajAdjId 5 -1 ...
                        {param} {equation} {coefficient} {comment} {''}];
                     g_decArgo_paramTrajAdjId = g_decArgo_paramTrajAdjId + 1;
                  end
               end
            end
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Adjust PRES values of BGC measurements with time interpolated CTD ones.
% Used CTC PRES are from PTS measurements or from pressure checks.
% Only inconsistent pressures are adjusted.
%
% SYNTAX :
%  [o_drift, o_done] = adjust_bgc_pres(a_drift, a_driftCtd, a_presCheckJuld, a_presCheckPres)
%
% INPUT PARAMETERS :
%   a_drift         : input BGC drift profile structures
%   a_driftCtd      : input CTD drift profile structures
%   a_presCheckJuld : pressure checks JULD
%   a_presCheckPres : pressure checks PRES
%
% OUTPUT PARAMETERS :
%   o_tabDrift : output BGC drift profile structures
%   o_done     : adjustment done flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/18/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_drift, o_done] = adjust_bgc_pres(a_drift, a_driftCtd, a_presCheckJuld, a_presCheckPres)

% output parameters initialization
o_drift = [];
o_done = 0;


% add CTD drift pressures and times to pressure checks data
if (~isempty(a_driftCtd))

   idPres = find(strcmp({a_driftCtd.paramList.name}, 'PRES') == 1, 1);
   if (~isempty(idPres))
      a_presCheckJuld = [a_presCheckJuld, a_driftCtd.dates'];
      a_presCheckPres = [a_presCheckPres, a_driftCtd.data(:, idPres)'];

      [~, idSort] = sort(a_presCheckJuld);
      a_presCheckJuld = a_presCheckJuld(idSort);
      a_presCheckPres = a_presCheckPres(idSort);
   end
end

if (~isempty(a_presCheckPres))

   % get BGC drift pressures and times
   bgcPres = [];
   bgcTimes = [];
   idPres = find(strcmp({a_drift.paramList.name}, 'PRES') == 1, 1);
   if (~isempty(idPres))
      bgcPres = a_drift.data(:, idPres);
      bgcTimes = a_drift.dates;
   end

   % adjust BGC drift pressures with timely closest pressure checks pressures
   if (~isempty(bgcPres))

      bgcPresAdj = nan(size(bgcPres));
      for idP = 1:length(bgcPres)

         idB = find(a_presCheckJuld <= bgcTimes(idP), 1, 'last');
         idA = find(a_presCheckJuld >= bgcTimes(idP), 1, 'first');
         if (~isempty(idB) && ~isempty(idA))
            % adjust only pressures that seem to be inconsistent
            adj = 0;
            if (fix(a_presCheckPres(idB)) >= fix(a_presCheckPres(idA)))
               if ~((fix(bgcPres(idP)) <= fix(a_presCheckPres(idB))) && ...
                     (fix(bgcPres(idP)) >= fix(a_presCheckPres(idA))))
                  adj = 1;
               end
            else
               if ~((fix(bgcPres(idP)) >= fix(a_presCheckPres(idB))) && ...
                     (fix(bgcPres(idP)) <= fix(a_presCheckPres(idA))))
                  adj = 1;
               end
            end
            if (adj == 1)
               if (idB ~= idA)
                  bgcPresAdj(idP) = interp1( ...
                     a_presCheckJuld([idB idA]), ...
                     a_presCheckPres([idB idA]), ...
                     bgcTimes(idP), 'linear');
               else
                  bgcPresAdj(idP) = a_presCheckPres(idB);
               end
               bgcPresAdj(idP) = round(bgcPresAdj(idP)*10)/10;
            end
         end
      end

      if (isempty(a_drift.dataAdj))
         a_drift.paramDataMode = repmat(' ', 1, length(a_drift.paramList));
         paramFillValue = get_prof_param_fill_value(a_drift);
         a_drift.dataAdj = repmat(double(paramFillValue), size(a_drift.data, 1), 1);
      end

      bgcPresAdjNew = bgcPres;
      bgcPresAdjNew(~isnan(bgcPresAdj)) = bgcPresAdj(~isnan(bgcPresAdj));
      a_drift.dataAdj(:, idPres) = bgcPresAdjNew;
      a_drift.paramDataMode(idPres) = 'A';
      o_done = 1;
   end
end

% update output parameters
o_drift = a_drift;

return

% ------------------------------------------------------------------------------
% Adjust PRES values of SUNA measurements with time interpolated CTD ones.
% Used CTD PRES are from PTS measurements or from pressure checks.
%
% SYNTAX :
%  [o_profile, o_done] = adjust_bgc_pres_all(a_profile, a_profileCtd, a_presCheckJuld, a_presCheckPres)
%
% INPUT PARAMETERS :
%   a_profile      : input BGC profile structures
%   a_profileCtd      : input CTD profile structures
%   a_presCheckJuld : pressure checks JULD
%   a_presCheckPres : pressure checks PRES
%
% OUTPUT PARAMETERS :
%   o_tabDrift : output BGC drift profile structures
%   o_done     : adjustment done flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/18/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profile, o_done] = adjust_bgc_pres_all(a_profile, a_profileCtd, a_presCheckJuld, a_presCheckPres)

% output parameters initialization
o_profile = [];
o_done = 0;


% add CTD drift pressures and times to pressure checks data
if (~isempty(a_profileCtd))

   idPres = find(strcmp({a_profileCtd.paramList.name}, 'PRES') == 1, 1);
   if (~isempty(idPres))
      a_presCheckJuld = [a_presCheckJuld, a_profileCtd.dates'];
      a_presCheckPres = [a_presCheckPres, a_profileCtd.data(:, idPres)'];

      [~, idSort] = sort(a_presCheckJuld);
      a_presCheckJuld = a_presCheckJuld(idSort);
      a_presCheckPres = a_presCheckPres(idSort);
   end
end

if (~isempty(a_presCheckPres))

   % get BGC drift pressures and times
   bgcPres = [];
   bgcTimes = [];
   idPres = find(strcmp({a_profile.paramList.name}, 'PRES') == 1, 1);
   if (~isempty(idPres))
      bgcPres = a_profile.data(:, idPres);
      bgcTimes = a_profile.dates;
   end

   % adjust BGC drift pressures with timely closest pressure checks pressures
   if (~isempty(bgcPres))

      [~, idUnique, ~] = unique(a_presCheckJuld);
      a_presCheckJuld = a_presCheckJuld(idUnique);
      a_presCheckPres = a_presCheckPres(idUnique);

      bgcPresAdj = interp1(a_presCheckJuld, a_presCheckPres, bgcTimes, 'linear');
      bgcPresAdj = round(bgcPresAdj*10)/10;

      paramPres = get_netcdf_param_attributes('PRES');
      bgcPresAdj(isnan(bgcPresAdj)) = paramPres.fillValue;

      if (isempty(a_profile.dataAdj))
         a_profile.paramDataMode = repmat(' ', 1, length(a_profile.paramList));
         paramFillValue = get_prof_param_fill_value(a_profile);
         a_profile.dataAdj = repmat(double(paramFillValue), size(a_profile.data, 1), 1);
      end

      a_profile.dataAdj(:, idPres) = bgcPresAdj;
      a_profile.paramDataMode(idPres) = 'A';
      o_done = 1;
   end
end

% update output parameters
o_profile = a_profile;

return

% ------------------------------------------------------------------------------
% Adjust PRES values of BGC measurements with CTD timely closest ones.
%
% SYNTAX :
%  [o_drift, o_done] = adjust_bgc_pres(a_drift, a_driftCtd)
%
% INPUT PARAMETERS :
%   a_tabDrift : input BGC drift profile structures
%   a_driftCtd : input CTD drift profile structures
%
% OUTPUT PARAMETERS :
%   o_tabDrift : output BGC drift profile structures
%   o_done     : adjustment done flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/12/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_drift, o_done] = adjust_bgc_pres_obsolete(a_drift, a_driftCtd)

% output parameters initialization
o_drift = [];
o_done = 0;


% get CTD drift pressures and times
ctdPres = [];
ctdTimes = [];
idPres = find(strcmp({a_driftCtd.paramList.name}, 'PRES') == 1, 1);
if (~isempty(idPres))
   ctdPres = a_driftCtd.data(:, idPres);
   if (~isempty(a_driftCtd.datesAdj))
      ctdTimes = a_driftCtd.datesAdj;
   else
      ctdTimes = a_driftCtd.dates;
   end
end

if (~isempty(ctdPres))

   % get BGC drift pressures and times
   bgcPres = [];
   bgcTimes = [];
   idPres = find(strcmp({a_drift.paramList.name}, 'PRES') == 1, 1);
   if (~isempty(idPres))
      bgcPres = a_drift.data(:, idPres);
      if (~isempty(a_drift.datesAdj))
         bgcTimes = a_drift.datesAdj;
      else
         bgcTimes = a_drift.dates;
      end
   end

   % adjust BGC drift pressures with timely closest CTD drift pressure
   if (~isempty(bgcPres))

      bgcPresAdj = nan(size(bgcPres));
      for idP = 1:length(bgcPres)
         [~, idMin] = min(abs(bgcTimes(idP) - ctdTimes));
         bgcPresAdj(idP) = ctdPres(idMin);
      end
      if (isempty(a_drift.dataAdj))
         a_drift.paramDataMode = repmat(' ', 1, length(a_drift.paramList));
         paramFillValue = get_prof_param_fill_value(a_drift);
         a_drift.dataAdj = repmat(double(paramFillValue), size(a_drift.data, 1), 1);
      end

      a_drift.dataAdj(:, idPres) = bgcPresAdj;
      a_drift.paramDataMode(idPres) = 'A';
      o_done = 1;
   end
end

% update output parameters
o_drift = a_drift;

return
