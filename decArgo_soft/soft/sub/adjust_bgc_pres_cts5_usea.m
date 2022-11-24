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


if (isempty(o_tabProfiles) && isempty(a_tabDrift))
   return
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
         [o_tabDrift(profInfo(idProf, 1)), doneForProf] = adjust_bgc_pres(o_tabDrift(profInfo(idProf, 1)), o_tabDrift(profInfo(idCtd, 1)));
         if (doneForProf == 1)
            doneForDrift = 1;
         end
      end
   end
end

if (doneForDrift)
   if ~(~isempty(g_decArgo_paramTrajAdjInfo) && any([g_decArgo_paramTrajAdjInfo{:, 2}] == 4))

      param = 'PRES';
      equation = 'PRES_ADJUSTED = timely closest CTD PRES (for BGC pressures sampled during the drift phase at parking depth)';
      coefficient = 'not applicable';
      comment = 'BGC pressures, sampled during the drift phase at parking depth, are adjusted in real time by using timely closest CTD pressure. Concerned Measurement Codes are: 290 and 301.';

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
            if ((profInfo(idProf, 2) ~= 0) && (profInfo(idProf, 3) == idDir))
               idCtd = find((profInfo(:, 2) == 0) & (profInfo(:, 3) == profInfo(idProf, 3)) & ...
                  (profInfo(:, 4) == profInfo(idProf, 4)) & (profInfo(:, 5) == profInfo(idProf, 5)));
               if (~isempty(idCtd))
                  [o_tabProfiles(profInfo(idProf, 1)), doneForProf] = adjust_bgc_pres(o_tabProfiles(profInfo(idProf, 1)), o_tabProfiles(profInfo(idCtd, 1)));

                  if (doneForProf == 1)

                     o_tabProfiles(profInfo(idProf, 1)).rtParamAdjIdList = [o_tabProfiles(profInfo(idProf, 1)).rtParamAdjIdList g_decArgo_paramProfAdjId];

                     param = 'PRES';
                     equation = 'PRES_ADJUSTED = timely closest CTD PRES';
                     coefficient = 'not applicable';
                     comment = 'SUNA pressures, sampled during the profiling descent and ascent phases, are adjusted in real time by using timely closest CTD pressure.';

                     g_decArgo_paramProfAdjInfo = [g_decArgo_paramProfAdjInfo;
                        g_decArgo_paramProfAdjId o_tabProfiles(profInfo(idProf, 1)).outputCycleNumber o_tabProfiles(profInfo(idProf, 1)).direction ...
                        {param} {equation} {coefficient} {comment} {''}];
                     g_decArgo_paramProfAdjId = g_decArgo_paramProfAdjId + 1;

                     if ~(~isempty(g_decArgo_paramTrajAdjInfo) && any([g_decArgo_paramTrajAdjInfo{:, 2}] == 5))

                        param = 'PRES';
                        equation = 'PRES_ADJUSTED = timely closest CTD PRES (for SUNA pressures sampled during the profiling descent and ascent phases)';
                        coefficient = 'not applicable';
                        comment = 'SUNA pressures, sampled during the profiling descent and ascent phases, are adjusted in real time by using timely closest CTD pressure. Concerned Measurement Codes are: 190, 203, 503 and 590.';

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
end

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
function [o_drift, o_done] = adjust_bgc_pres(a_drift, a_driftCtd)

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
