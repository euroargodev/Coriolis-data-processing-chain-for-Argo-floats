% ------------------------------------------------------------------------------
% Compute derived parameters for Apex APF11 Iridium-SBD floats.
%
% SYNTAX :
%  [o_profDo, o_profCtdPtsh, o_profCtdCpH] = ...
%    compute_derived_parameters_apx_apf11_ir( ...
%    a_profCtdPts, a_profCtdCp, a_profDo, ...
%    a_profCtdPtsh, a_profCtdCpH, ...
%    a_cycleTimeData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_profCtdPts    : input CTD_PTS data
%   a_profCtdCp     : input CTD_CP data
%   a_profDo        : input O2 data
%   a_profCtdPtsh   : input CTD_PTSH data
%   a_profCtdCpH    : input CTD_CP_H data
%   a_cycleTimeData : input cycle timings data
%   a_decoderId     : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_profDo      : output O2 data
%   o_profCtdPtsh : output CTD_PTSH data
%   o_profCtdCpH  : output CTD_CP_H data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profDo, o_profCtdPtsh, o_profCtdCpH] = ...
   compute_derived_parameters_apx_apf11_ir( ...
   a_profCtdPts, a_profCtdCp, a_profDo, ...
   a_profCtdPtsh, a_profCtdCpH, ...
   a_cycleTimeData, a_decoderId)

% output parameters initialization
o_profDo = a_profDo;
o_profCtdPtsh = a_profCtdPtsh;
o_profCtdCpH = a_profCtdCpH;


switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {1322}
      
      if (~isempty(o_profDo))
         
         paramDoxy = get_netcdf_param_attributes('DOXY');
         paramPpoxDoxy = get_netcdf_param_attributes('PPOX_DOXY');
         paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
         paramC1phaseDoxy = get_netcdf_param_attributes('C1PHASE_DOXY');
         paramC2phaseDoxy = get_netcdf_param_attributes('C2PHASE_DOXY');
         paramPres = get_netcdf_param_attributes('PRES');
         paramTemp = get_netcdf_param_attributes('TEMP');
         paramPsal = get_netcdf_param_attributes('PSAL');
         
         % add DOXY and PPOX_DOXY to the DO profile
         o_profDo.paramList = [o_profDo.paramList paramDoxy paramPpoxDoxy];
         o_profDo.data = [o_profDo.data ...
            ones(size(o_profDo.data, 1), 1)*paramDoxy.fillValue ...
            ones(size(o_profDo.data, 1), 1)*paramPpoxDoxy.fillValue];
         if (~isempty(o_profDo.dataAdj))
            o_profDo.dataAdj = [o_profDo.dataAdj ...
               ones(size(o_profDo.dataAdj, 1), 1)*paramDoxy.fillValue ...
               ones(size(o_profDo.dataAdj, 1), 1)*paramPpoxDoxy.fillValue];
         end
         
         idPres = find(strcmp({o_profDo.paramList.name}, 'PRES') == 1);
         idC1PhaseDoxy = find(strcmp({o_profDo.paramList.name}, 'C1PHASE_DOXY') == 1);
         idC2PhaseDoxy = find(strcmp({o_profDo.paramList.name}, 'C2PHASE_DOXY') == 1);
         idTempDoxy = find(strcmp({o_profDo.paramList.name}, 'TEMP_DOXY') == 1);
         idDoxy = find(strcmp({o_profDo.paramList.name}, 'DOXY') == 1);
         idPpoxDoxy = find(strcmp({o_profDo.paramList.name}, 'PPOX_DOXY') == 1);
         
         if (~isempty(idPres) && ...
               ~isempty(idC1PhaseDoxy) && ~isempty(idC2PhaseDoxy) && ...
               ~isempty(idTempDoxy) && ~isempty(idDoxy) && ~isempty(idPpoxDoxy))
            
            % retrieve discrete PTS measurements from CTD_PTS and CTD_PTSH data
            ctdData = [];
            if (~isempty(a_profCtdPts))
               ctdData = a_profCtdPts;
            end
            if (~isempty(a_profCtdPtsh))
               if (isempty(ctdData))
                  ctdData = a_profCtdPtsh;
                  ctdData.data = ctdData.data(:, 1:3);
                  if (~isempty(ctdData.dataAdj))
                     ctdData.dataAdj = ctdData.dataAdj(:, 1:3);
                  end
               else
                  ctdData.dates = [ctdData.dates; a_profCtdPtsh.dates];
                  ctdData.data = [ctdData.data; a_profCtdPtsh.data(:, 1:3)];
                  [~, idSort] = sort(ctdData.dates);
                  ctdData.dates = ctdData.dates(idSort);
                  ctdData.data = ctdData.data(idSort, :);
                  if (~isempty(ctdData.dataAdj))
                     ctdData.dataAdj = [ctdData.dataAdj; a_profCtdPtsh.dataAdj(:, 1:3)];
                     ctdData.dataAdj = ctdData.dataAdj(idSort, :);
                  end
               end
            end
            
            % compute DOXY for sub-surface measurements
            if (~isempty(a_cycleTimeData.ascentStartDateSci))
               idPark = find(o_profDo.dates < a_cycleTimeData.ascentStartDateSci);
               
               if (length(idPark) > 1)
                  
                  % interpolate and extrapolate PTS data at the times of the OPTODE
                  % measurements
                  presData = interp1(ctdData.dates, ctdData.data(:, 1), ...
                     o_profDo.dates(idPark), 'linear', 'extrap');
                  tempData = interp1(ctdData.dates, ctdData.data(:, 2), ...
                     o_profDo.dates(idPark), 'linear', 'extrap');
                  psalData = interp1(ctdData.dates, ctdData.data(:, 3), ...
                     o_profDo.dates(idPark), 'linear', 'extrap');
                  
                  % compute DOXY
                  doxyValues = compute_DOXY_1322( ...
                     o_profDo.data(idPark, idC1PhaseDoxy), o_profDo.data(idPark, idC2PhaseDoxy), o_profDo.data(idPark, idTempDoxy), ...
                     paramC1phaseDoxy.fillValue, paramC2phaseDoxy.fillValue, paramTempDoxy.fillValue, ...
                     presData, tempData, psalData, ...
                     paramPres.fillValue, paramTemp.fillValue, paramPsal.fillValue, ...
                     paramDoxy.fillValue);
                  o_profDo.data(idPark, idDoxy) = doxyValues;
                  
                  % from "Minutes of the 6th BGC-Argo meeting 27, 28 November 2017,
                  % Hamburg"
                  % http://www.argodatamgt.org/content/download/30911/209493/file/minutes_BGC6_ADMT18.pdf
                  % -For a parameter to pass to mode 'A' (i.e., adjusted in real-time),
                  % the calculation for the adjustment must involve the parameter itself
                  % (e.g., with an offset or slope). If a different parameter used for
                  % the calculations is in mode 'A' (e.g., PSAL_ADJUSTED), this does not
                  % transitions onto the parameter itself and does not put it into mode
                  % 'A'. The <PARAM> field is always calculated with other parameters in
                  % 'R' mode (e.g., PSAL). <PARAM>_ADJUSTED  is  only  populated  with  a
                  % "real"  parameter  adjustment  as  defined above.  A calculation
                  % without  a  "real"  parameter  adjustment  but  involving  other
                  % adjusted  parameters (e.g., PSAL_ADJUSTED) is not performed/not
                  % recorded in the BGC-Argofiles.
                  
                  % there is no need to compute derived parameters with PRES_ADJUSTED
                  %                   if (~isempty(o_profDo.dataAdj))
                  %
                  %                      % interpolate and extrapolate PTS data at the times of the OPTODE
                  %                      % measurements
                  %                      presData = interp1(ctdData.dates, ctdData.dataAdj(:, 1), ...
                  %                         o_profDo.dates(idPark), 'linear', 'extrap');
                  %                      tempData = interp1(ctdData.dates, ctdData.dataAdj(:, 2), ...
                  %                         o_profDo.dates(idPark), 'linear', 'extrap');
                  %                      psalData = interp1(ctdData.dates, ctdData.dataAdj(:, 3), ...
                  %                         o_profDo.dates(idPark), 'linear', 'extrap');
                  %
                  %                      % compute DOXY
                  %                      doxyValues = compute_DOXY_1322( ...
                  %                         o_profDo.dataAdj(idPark, idC1PhaseDoxy), o_profDo.dataAdj(idPark, idC2PhaseDoxy), o_profDo.dataAdj(idPark, idTempDoxy), ...
                  %                         paramC1phaseDoxy.fillValue, paramC2phaseDoxy.fillValue, paramTempDoxy.fillValue, ...
                  %                         presData, tempData, psalData, ...
                  %                         paramPres.fillValue, paramTemp.fillValue, paramPsal.fillValue, ...
                  %                         paramDoxy.fillValue);
                  %                      o_profDo.dataAdj(idPark, idDoxy) = doxyValues;
                  %                   end
               end
            end
            
            % compute DOXY for profile measurements
            if (~isempty(a_cycleTimeData.ascentStartDateSci) && ...
                  ~isempty(a_cycleTimeData.ascentEndDateSci))
               idAscent = find(((o_profDo.dates >= a_cycleTimeData.ascentStartDateSci) & ...
                  (o_profDo.dates <= a_cycleTimeData.ascentEndDateSci)));
               
               if (length(idAscent) > 1)
                  
                  % retrieve PTS measurements sampled suring ascent profile from
                  % CTD_PTS, CTD_PTSH, CTD_CP and CTD_CP_H data
                  ctdDataAscent = [];
                  idCtdAscent = find(((ctdData.dates >= a_cycleTimeData.ascentStartDateSci) & ...
                     (ctdData.dates <= a_cycleTimeData.ascentEndDateSci)));
                  if (~isempty(idCtdAscent))
                     ctdDataAscent = ctdData;
                     ctdDataAscent.data = ctdDataAscent.data(idCtdAscent, :);
                     if (~isempty(ctdDataAscent.dataAdj))
                        ctdDataAscent.dataAdj = ctdDataAscent.dataAdj(idCtdAscent, :);
                     end
                  end
                  if (~isempty(a_profCtdCp))
                     if (isempty(ctdDataAscent))
                        ctdDataAscent = a_profCtdCp;
                     else
                        ctdDataAscent.data = [ctdDataAscent.data; a_profCtdCp.data(:, 1:3)];
                        if (~isempty(ctdDataAscent.dataAdj))
                           ctdDataAscent.dataAdj = [ctdDataAscent.dataAdj; a_profCtdCp.dataAdj(:, 1:3)];
                        end
                     end
                  end
                  if (~isempty(a_profCtdCpH))
                     if (isempty(ctdDataAscent))
                        ctdDataAscent = a_profCtdCpH;
                        ctdDataAscent.data = ctdDataAscent.data(:, 1:3);
                        if (~isempty(ctdDataAscent.dataAdj))
                           ctdDataAscent.dataAdj = ctdDataAscent.dataAdj(:, 1:3);
                        end
                     else
                        ctdDataAscent.data = [ctdDataAscent.data; a_profCtdCpH.data(:, 1:3)];
                        if (~isempty(ctdDataAscent.dataAdj))
                           ctdDataAscent.dataAdj = [ctdDataAscent.dataAdj; a_profCtdCpH.dataAdj(:, 1:3)];
                        end
                     end
                  end
                  
                  if (~isempty(ctdDataAscent))
                     [~, idSort] = sort(ctdDataAscent.data(:, 1));
                     ctdDataAscent.data = ctdDataAscent.data(idSort, :);
                     if (~isempty(ctdDataAscent.dataAdj))
                        ctdDataAscent.dataAdj = ctdDataAscent.dataAdj(idSort, :);
                     end
                     [~, idUnique, ~] = unique(ctdDataAscent.data(:, 1));
                     ctdDataAscent.data = ctdDataAscent.data(idUnique, :);
                     if (~isempty(ctdDataAscent.dataAdj))
                        ctdDataAscent.dataAdj = ctdDataAscent.dataAdj(idUnique, :);
                     end
                  end
                  
                  % interpolate and extrapolate TS data at the pressures of the OPTODE
                  % measurements
                  tempData = interp1(ctdDataAscent.data(:, 1), ctdDataAscent.data(:, 2), ...
                     o_profDo.data(idAscent, idPres), 'linear', 'extrap');
                  psalData = interp1(ctdDataAscent.data(:, 1), ctdDataAscent.data(:, 3), ...
                     o_profDo.data(idAscent, idPres), 'linear', 'extrap');
                  
                  % compute DOXY
                  doxyValues = compute_DOXY_1322( ...
                     o_profDo.data(idAscent, idC1PhaseDoxy), o_profDo.data(idAscent, idC2PhaseDoxy), o_profDo.data(idAscent, idTempDoxy), ...
                     paramC1phaseDoxy.fillValue, paramC2phaseDoxy.fillValue, paramTempDoxy.fillValue, ...
                     o_profDo.data(idAscent, idPres), tempData, psalData, ...
                     paramPres.fillValue, paramTemp.fillValue, paramPsal.fillValue, ...
                     paramDoxy.fillValue);
                  o_profDo.data(idAscent, idDoxy) = doxyValues;
                  
                  % from "Minutes of the 6th BGC-Argo meeting 27, 28 November 2017,
                  % Hamburg"
                  % http://www.argodatamgt.org/content/download/30911/209493/file/minutes_BGC6_ADMT18.pdf
                  % -For a parameter to pass to mode 'A' (i.e., adjusted in real-time),
                  % the calculation for the adjustment must involve the parameter itself
                  % (e.g., with an offset or slope). If a different parameter used for
                  % the calculations is in mode 'A' (e.g., PSAL_ADJUSTED), this does not
                  % transitions onto the parameter itself and does not put it into mode
                  % 'A'. The <PARAM> field is always calculated with other parameters in
                  % 'R' mode (e.g., PSAL). <PARAM>_ADJUSTED  is  only  populated  with  a
                  % "real"  parameter  adjustment  as  defined above.  A calculation
                  % without  a  "real"  parameter  adjustment  but  involving  other
                  % adjusted  parameters (e.g., PSAL_ADJUSTED) is not performed/not
                  % recorded in the BGC-Argofiles.
                  
                  % there is no need to compute derived parameters with PRES_ADJUSTED
                  %                   if (~isempty(o_profDo.dataAdj))
                  %
                  %                      % interpolate and extrapolate TS data at the pressures of the OPTODE
                  %                      % measurements
                  %                      tempData = interp1(ctdDataAscent.dataAdj(:, 1), ctdDataAscent.dataAdj(:, 2), ...
                  %                         o_profDo.dataAdj(idAscent, idPres), 'linear', 'extrap');
                  %                      psalData = interp1(ctdDataAscent.dataAdj(:, 1), ctdDataAscent.dataAdj(:, 3), ...
                  %                         o_profDo.dataAdj(idAscent, idPres), 'linear', 'extrap');
                  %
                  %                      % compute DOXY
                  %                      doxyValues = compute_DOXY_1322( ...
                  %                         o_profDo.dataAdj(idAscent, idC1PhaseDoxy), o_profDo.dataAdj(idAscent, idC2PhaseDoxy), o_profDo.dataAdj(idAscent, idTempDoxy), ...
                  %                         paramC1phaseDoxy.fillValue, paramC2phaseDoxy.fillValue, paramTempDoxy.fillValue, ...
                  %                         o_profDo.dataAdj(idAscent, idPres), tempData, psalData, ...
                  %                         paramPres.fillValue, paramTemp.fillValue, paramPsal.fillValue, ...
                  %                         paramDoxy.fillValue);
                  %                      o_profDo.dataAdj(idAscent, idDoxy) = doxyValues;
                  %                   end
               end
            end
            
            % compute PPOX_DOXY for surface measurements
            if (~isempty(a_cycleTimeData.ascentEndDateSci))
               idSurf = find(o_profDo.dates > a_cycleTimeData.ascentEndDateSci);
               
               if (~isempty(idSurf))
                  
                  % compute PPOX_DOXY
                  ppoxDoxyValues = compute_PPOX_DOXY_1322( ...
                     o_profDo.data(idSurf, idC1PhaseDoxy), o_profDo.data(idSurf, idC2PhaseDoxy), o_profDo.data(idSurf, idTempDoxy), ...
                     paramC1phaseDoxy.fillValue, paramC2phaseDoxy.fillValue, paramTempDoxy.fillValue, ...
                     o_profDo.data(idSurf, idPres), ...
                     paramPres.fillValue, ...
                     paramPpoxDoxy.fillValue);
                  o_profDo.data(idSurf, idPpoxDoxy) = ppoxDoxyValues;
                  
                  % from "Minutes of the 6th BGC-Argo meeting 27, 28 November 2017,
                  % Hamburg"
                  % http://www.argodatamgt.org/content/download/30911/209493/file/minutes_BGC6_ADMT18.pdf
                  % -For a parameter to pass to mode 'A' (i.e., adjusted in real-time),
                  % the calculation for the adjustment must involve the parameter itself
                  % (e.g., with an offset or slope). If a different parameter used for
                  % the calculations is in mode 'A' (e.g., PSAL_ADJUSTED), this does not
                  % transitions onto the parameter itself and does not put it into mode
                  % 'A'. The <PARAM> field is always calculated with other parameters in
                  % 'R' mode (e.g., PSAL). <PARAM>_ADJUSTED  is  only  populated  with  a
                  % "real"  parameter  adjustment  as  defined above.  A calculation
                  % without  a  "real"  parameter  adjustment  but  involving  other
                  % adjusted  parameters (e.g., PSAL_ADJUSTED) is not performed/not
                  % recorded in the BGC-Argofiles.
                  
                  % there is no need to compute derived parameters with PRES_ADJUSTED
                  %                   if (~isempty(o_profDo.dataAdj))
                  %
                  %                      % compute PPOX_DOXY
                  %                      ppoxDoxyValues = compute_PPOX_DOXY_1322( ...
                  %                         o_profDo.dataAdj(idSurf, idC1PhaseDoxy), o_profDo.dataAdj(idSurf, idC2PhaseDoxy), o_profDo.dataAdj(idSurf, idTempDoxy), ...
                  %                         paramC1phaseDoxy.fillValue, paramC2phaseDoxy.fillValue, paramTempDoxy.fillValue, ...
                  %                         o_profDo.dataAdj(idSurf, idPres), ...
                  %                         paramPres.fillValue, ...
                  %                         paramPpoxDoxy.fillValue);
                  %                      o_profDo.dataAdj(idSurf, idPpoxDoxy) = ppoxDoxyValues;
                  %                   end
               end
            end
         end
      end
      
      if ((~isempty(o_profCtdPtsh)) || (~isempty(o_profCtdCpH)))
         
         paramVrsPh = get_netcdf_param_attributes('VRS_PH');
         paramPres = get_netcdf_param_attributes('PRES');
         paramTemp = get_netcdf_param_attributes('TEMP');
         paramPsal = get_netcdf_param_attributes('PSAL');
         paramPhInSituFree = get_netcdf_param_attributes('PH_IN_SITU_FREE');
         paramPhInSituTotal = get_netcdf_param_attributes('PH_IN_SITU_TOTAL');
         
         % compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL for discrete measurements
         if (~isempty(o_profCtdPtsh))
            
            % add PH_IN_SITU_FREE and PH_IN_SITU_TOTAL to the PH profile
            o_profCtdPtsh.paramList = [o_profCtdPtsh.paramList paramPhInSituFree paramPhInSituTotal];
            o_profCtdPtsh.data = [o_profCtdPtsh.data ...
               ones(size(o_profCtdPtsh.data, 1), 1)*paramPhInSituFree.fillValue ...
               ones(size(o_profCtdPtsh.data, 1), 1)*paramPhInSituTotal.fillValue];
            if (~isempty(o_profCtdPtsh.dataAdj))
               o_profCtdPtsh.dataAdj = [o_profCtdPtsh.dataAdj ...
                  ones(size(o_profCtdPtsh.dataAdj, 1), 1)*paramPhInSituFree.fillValue ...
                  ones(size(o_profCtdPtsh.dataAdj, 1), 1)*paramPhInSituTotal.fillValue];
            end
            
            idPres = find(strcmp({o_profCtdPtsh.paramList.name}, 'PRES') == 1);
            idTemp = find(strcmp({o_profCtdPtsh.paramList.name}, 'TEMP') == 1);
            idPsal = find(strcmp({o_profCtdPtsh.paramList.name}, 'PSAL') == 1);
            idVrsPh = find(strcmp({o_profCtdPtsh.paramList.name}, 'VRS_PH') == 1);
            idPhInSituFree = find(strcmp({o_profCtdPtsh.paramList.name}, 'PH_IN_SITU_FREE') == 1);
            idPhInSituTotal = find(strcmp({o_profCtdPtsh.paramList.name}, 'PH_IN_SITU_TOTAL') == 1);
            
            if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal) && ...
                  ~isempty(idVrsPh) && ~isempty(idPhInSituFree) && ~isempty(idPhInSituTotal))
               
               % compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL
               [phInSituFreeValues, phInSituTotalValues] = compute_PH_1322( ...
                  o_profCtdPtsh.data(:, idVrsPh), ...
                  paramVrsPh.fillValue, ...
                  o_profCtdPtsh.data(:, idPres), o_profCtdPtsh.data(:, idTemp), o_profCtdPtsh.data(:, idPsal), ...
                  paramPres.fillValue, paramTemp.fillValue, paramPsal.fillValue, ...
                  paramPhInSituFree.fillValue, paramPhInSituTotal.fillValue);
               o_profCtdPtsh.data(:, idPhInSituFree) = phInSituFreeValues;
               o_profCtdPtsh.data(:, idPhInSituTotal) = phInSituTotalValues;
               
               % from "Minutes of the 6th BGC-Argo meeting 27, 28 November 2017,
               % Hamburg"
               % http://www.argodatamgt.org/content/download/30911/209493/file/minutes_BGC6_ADMT18.pdf
               % -For a parameter to pass to mode 'A' (i.e., adjusted in real-time),
               % the calculation for the adjustment must involve the parameter itself
               % (e.g., with an offset or slope). If a different parameter used for
               % the calculations is in mode 'A' (e.g., PSAL_ADJUSTED), this does not
               % transitions onto the parameter itself and does not put it into mode
               % 'A'. The <PARAM> field is always calculated with other parameters in
               % 'R' mode (e.g., PSAL). <PARAM>_ADJUSTED  is  only  populated  with  a
               % "real"  parameter  adjustment  as  defined above.  A calculation
               % without  a  "real"  parameter  adjustment  but  involving  other
               % adjusted  parameters (e.g., PSAL_ADJUSTED) is not performed/not
               % recorded in the BGC-Argofiles.
               
               % there is no need to compute derived parameters with PRES_ADJUSTED
               %                if (~isempty(o_profCtdPtsh.dataAdj))
               %
               %                   % compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL
               %                   [phInSituFreeValues, phInSituTotalValues] = compute_PH_1322( ...
               %                      o_profCtdPtsh.dataAdj(:, idVrsPh), ...
               %                      paramVrsPh.fillValue, ...
               %                      o_profCtdPtsh.dataAdj(:, idPres), o_profCtdPtsh.dataAdj(:, idTemp), o_profCtdPtsh.dataAdj(:, idPsal), ...
               %                      paramPres.fillValue, paramTemp.fillValue, paramPsal.fillValue, ...
               %                      paramPhInSituFree.fillValue, paramPhInSituTotal.fillValue);
               %                   o_profCtdPtsh.dataAdj(:, idPhInSituFree) = phInSituFreeValues;
               %                   o_profCtdPtsh.dataAdj(:, idPhInSituTotal) = phInSituTotalValues;
               %                end
            end
         end
         
         % compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL for averaged measurements
         if (~isempty(o_profCtdCpH))
            
            o_profCtdCpH.paramList = [o_profCtdCpH.paramList paramPhInSituFree paramPhInSituTotal];
            o_profCtdCpH.data = [o_profCtdCpH.data ...
               ones(size(o_profCtdCpH.data, 1), 1)*paramPhInSituFree.fillValue ...
               ones(size(o_profCtdCpH.data, 1), 1)*paramPhInSituTotal.fillValue];
            if (~isempty(o_profCtdCpH.dataAdj))
               o_profCtdCpH.dataAdj = [o_profCtdCpH.dataAdj ...
                  ones(size(o_profCtdCpH.dataAdj, 1), 1)*paramPhInSituFree.fillValue ...
                  ones(size(o_profCtdCpH.dataAdj, 1), 1)*paramPhInSituTotal.fillValue];
            end
            
            idPres = find(strcmp({o_profCtdCpH.paramList.name}, 'PRES') == 1);
            idTemp = find(strcmp({o_profCtdCpH.paramList.name}, 'TEMP') == 1);
            idPsal = find(strcmp({o_profCtdCpH.paramList.name}, 'PSAL') == 1);
            idVrsPh = find(strcmp({o_profCtdCpH.paramList.name}, 'VRS_PH') == 1);
            idPhInSituFree = find(strcmp({o_profCtdCpH.paramList.name}, 'PH_IN_SITU_FREE') == 1);
            idPhInSituTotal = find(strcmp({o_profCtdCpH.paramList.name}, 'PH_IN_SITU_TOTAL') == 1);
            
            if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal) && ...
                  ~isempty(idVrsPh) && ~isempty(idPhInSituFree) && ~isempty(idPhInSituTotal))
               
               % compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL
               [phInSituFreeValues, phInSituTotalValues] = compute_PH_1322( ...
                  o_profCtdCpH.data(:, idVrsPh), ...
                  paramVrsPh.fillValue, ...
                  o_profCtdCpH.data(:, idPres), o_profCtdCpH.data(:, idTemp), o_profCtdCpH.data(:, idPsal), ...
                  paramPres.fillValue, paramTemp.fillValue, paramPsal.fillValue, ...
                  paramPhInSituFree.fillValue, paramPhInSituTotal.fillValue);
               o_profCtdCpH.data(:, idPhInSituFree) = phInSituFreeValues;
               o_profCtdCpH.data(:, idPhInSituTotal) = phInSituTotalValues;
               
               % from "Minutes of the 6th BGC-Argo meeting 27, 28 November 2017,
               % Hamburg"
               % http://www.argodatamgt.org/content/download/30911/209493/file/minutes_BGC6_ADMT18.pdf
               % -For a parameter to pass to mode 'A' (i.e., adjusted in real-time),
               % the calculation for the adjustment must involve the parameter itself
               % (e.g., with an offset or slope). If a different parameter used for
               % the calculations is in mode 'A' (e.g., PSAL_ADJUSTED), this does not
               % transitions onto the parameter itself and does not put it into mode
               % 'A'. The <PARAM> field is always calculated with other parameters in
               % 'R' mode (e.g., PSAL). <PARAM>_ADJUSTED  is  only  populated  with  a
               % "real"  parameter  adjustment  as  defined above.  A calculation
               % without  a  "real"  parameter  adjustment  but  involving  other
               % adjusted  parameters (e.g., PSAL_ADJUSTED) is not performed/not
               % recorded in the BGC-Argofiles.
               
               % there is no need to compute derived parameters with PRES_ADJUSTED
               %                if (~isempty(o_profCtdCpH.dataAdj))
               %
               %                   % compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL
               %                   [phInSituFreeValues, phInSituTotalValues] = compute_PH_1322( ...
               %                      o_profCtdCpH.dataAdj(:, idVrsPh), ...
               %                      paramVrsPh.fillValue, ...
               %                      o_profCtdCpH.dataAdj(:, idPres), o_profCtdCpH.dataAdj(:, idTemp), o_profCtdCpH.dataAdj(:, idPsal), ...
               %                      paramPres.fillValue, paramTemp.fillValue, paramPsal.fillValue, ...
               %                      paramPhInSituFree.fillValue, paramPhInSituTotal.fillValue);
               %                   o_profCtdCpH.dataAdj(:, idPhInSituFree) = phInSituFreeValues;
               %                   o_profCtdCpH.dataAdj(:, idPhInSituTotal) = phInSituTotalValues;
               %                end
            end
         end
      end
end

return
