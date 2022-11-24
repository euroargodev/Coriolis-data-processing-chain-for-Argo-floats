% ------------------------------------------------------------------------------
% Perform real time adjustment on parameter profile data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = ...
%    compute_rt_adjusted_param( ...
%    a_tabProfiles, a_tabTrajNMeas, a_tabTrajNCycle, a_launchDate, a_notOnlyDoxyFlag, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabProfiles     : input profile structures
%   a_tabTrajNMeas    : input N_MEASUREMENT trajectory data
%   a_tabTrajNCycle   : input N_CYCLE trajectory data
%   a_launchDate      : float launch date
%   a_notOnlyDoxyFlag : 0: if only DOXY adjustment should be done
%                       1: if other BGC parameters should be adjusted
%   a_decoderId       : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabProfiles   : output profile structures
%   o_tabTrajNMeas  : output N_MEASUREMENT trajectory data
%   o_tabTrajNCycle : output N_CYCLE trajectory data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/28/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = ...
   compute_rt_adjusted_param( ...
   a_tabProfiles, a_tabTrajNMeas, a_tabTrajNCycle, a_launchDate, a_notOnlyDoxyFlag, a_decoderId)

% output parameters initialization
o_tabProfiles = a_tabProfiles;
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;

% lists of managed decoders
global g_decArgo_decoderIdListNkeIridiumDeep;


if (ismember(a_decoderId, g_decArgo_decoderIdListNkeIridiumDeep))
   % perform PSAL RT adjustment of Deep floats
   [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = ...
      compute_rt_adjusted_psal_for_deep_float( ...
      o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle);
end

% perform DB RT adjustments
[o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = ...
   compute_rt_adjusted_param_from_db( ...
   o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle);

% perform DOXY RT adjustment
[o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = ...
   compute_rt_adjusted_doxy( ...
   o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, a_launchDate, a_decoderId);

if (a_notOnlyDoxyFlag)
   % perform CHLA RT adjustment
   [o_tabProfiles] = compute_rt_adjusted_chla(o_tabProfiles);
   
   % perform NITRATE RT adjustment
   [o_tabProfiles] = compute_rt_adjusted_nitrate(o_tabProfiles, a_launchDate);
end

return

% ------------------------------------------------------------------------------
% Perform real time adjustment on PSAL profile data for deep floats.
%
% SYNTAX :
%  [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = ...
%    compute_rt_adjusted_psal_for_deep_float(a_tabProfiles, a_tabTrajNMeas, a_tabTrajNCycle)
%
% INPUT PARAMETERS :
%   a_tabProfiles   : input profile structures
%   a_tabTrajNMeas  : input N_MEASUREMENT trajectory data
%   a_tabTrajNCycle : input N_CYCLE trajectory data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles   : output profile structures
%   o_tabTrajNMeas  : output N_MEASUREMENT trajectory data
%   o_tabTrajNCycle : output N_CYCLE trajectory data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/04/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = ...
   compute_rt_adjusted_psal_for_deep_float(a_tabProfiles, a_tabTrajNMeas, a_tabTrajNCycle)

% output parameters initialization
o_tabProfiles = a_tabProfiles;
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;

% QC flag values (numerical)
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;

% to store information on adjustments
global g_decArgo_paramProfAdjInfo;
global g_decArgo_paramProfAdjId;

% TRAJ 3.2 file generation flag
global g_decArgo_generateNcTraj32;


% from "Argo Quality Control Manual for CTD and Trajectory Data, Version 3.4, 02
% February 2021"
DELTA = 3.25e-6;
CPCOR_SBE = -9.57e-8;
% CPCOR_NEW_SBE_61 = -12.5e-8; % for Deep Apex and Deep SOLO => unused
CPCOR_NEW_SBE_41CP = -13.5e-8; % for Deep Arvor and Deep Ninja

% involved parameter information
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramPsal = get_netcdf_param_attributes('PSAL');

% basic adjustment information for NetCDF files
equation = 'new conductivity = original conductivity * (1 + delta*TEMP + CPcor_SBE*PRES) / (1 + delta*TEMP_ADJUSTED + CPcor_new*PRES_ADJUSTED)';
coefficient = sprintf('CPcor_new = %g, CPcor_SBE = %g, delta = %g', CPCOR_NEW_SBE_41CP, CPCOR_SBE, DELTA);
comment = 'New conductivity computed by using a different CPcor value from that provided by Sea-Bird.';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% adjust profile data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for idProf = 1:length(o_tabProfiles)
   profile = o_tabProfiles(idProf);
   if (any(strcmp({profile.paramList.name}, 'PSAL')))
      
      % retrieve PTS and PT_ADJUSTED values
      idPres = find(strcmp({profile.paramList.name}, 'PRES'));
      idTemp = find(strcmp({profile.paramList.name}, 'TEMP'));
      idPsal = find(strcmp({profile.paramList.name}, 'PSAL'));
      
      presValues = profile.data(:, idPres);
      tempValues = profile.data(:, idTemp);
      psalValues = profile.data(:, idPsal);
      
      presAdjValues = presValues;
      tempAdjValues = tempValues;
      if (~isempty(profile.paramDataMode))
         if (profile.paramDataMode(idPres) == 'A')
            presAdjValues = profile.dataAdj(:, idPres);
         end
         if (profile.paramDataMode(idTemp) == 'A')
            tempAdjValues = profile.dataAdj(:, idTemp);
         end
      end
      
      % clean fill values
      idNoDefPts = find((presValues ~= paramPres.fillValue) & ...
         (presAdjValues ~= paramPres.fillValue) & ...
         (tempValues ~= paramTemp.fillValue) & ...
         (tempAdjValues ~= paramTemp.fillValue) & ...
         (psalValues ~= paramPsal.fillValue));
      presValues = presValues(idNoDefPts);
      presAdjValues = presAdjValues(idNoDefPts);
      tempValues = tempValues(idNoDefPts);
      tempAdjValues = tempAdjValues(idNoDefPts);
      psalValues = psalValues(idNoDefPts);
      
      if (~isempty(presValues) && ~isempty(tempValues) && ~isempty(psalValues) && ...
            ~isempty(presAdjValues) && ~isempty(tempAdjValues))
         
         % compute original conductivity
         cndcValues = gsw_C_from_SP(psalValues, tempValues, presValues);
         
         % adjust conductivity
         cndcAdjValues = cndcValues.*(1 + DELTA*tempValues + CPCOR_SBE*presValues)./ ...
            (1 + DELTA*tempAdjValues + CPCOR_NEW_SBE_41CP*presAdjValues);
         
         % compute adjusted salinity
         psalAjValues = gsw_SP_from_C(cndcAdjValues, tempAdjValues, presAdjValues);
         psalAjValues(isnan(psalAjValues)) = paramPsal.fillValue;
         
         % create array for adjusted data
         paramFillValue = get_prof_param_fill_value(profile);
         if (isempty(profile.dataAdj))
            profile.paramDataMode = repmat(' ', 1, length(profile.paramList));
            profile.dataAdj = repmat(double(paramFillValue), size(profile.data, 1), 1);
         end
         if (isempty(profile.dataAdjQc))
            profile.dataAdjQc = ones(size(profile.dataAdj, 1), length(profile.paramList))*g_decArgo_qcDef;
         end
         if (isempty(profile.dataAdjError))
            profile.dataAdjError = repmat(double(paramFillValue), size(profile.data, 1), 1);
         end
         
         % store adjusted data
         profile.paramDataMode(idPsal) = 'A';
         profile.dataAdj(idNoDefPts, idPsal) = psalAjValues;
         
         idNoDef = find(profile.dataAdj(:, idPsal) ~= paramPsal.fillValue);
         profile.dataAdjQc(idNoDef, idPsal) = g_decArgo_qcNoQc;
         
         % store error on adjusted data
         idNoDef = find(profile.data(:, idPres) ~= paramPres.fillValue);
         profile.dataAdjError(idNoDef, idPres) = (2.5/6000) * profile.data(idNoDef, idPres) + 2;
         
         idNoDef = find(profile.data(:, idTemp) ~= paramTemp.fillValue);
         profile.dataAdjError(idNoDef, idTemp) = 0.002;
         
         idNoDef = find(profile.dataAdj(:, idPsal) ~= paramPsal.fillValue);
         profile.dataAdjError(idNoDef, idPsal) = 0.004;
         
         profile.rtParamAdjIdList = [profile.rtParamAdjIdList g_decArgo_paramProfAdjId];
         o_tabProfiles(idProf) = profile;
         
         % store profile adjustment information for NetCDF file
         if (profile.direction == 'A')
            direction = 2;
         else
            direction = 1;
         end
         
         g_decArgo_paramProfAdjInfo = [g_decArgo_paramProfAdjInfo;
            g_decArgo_paramProfAdjId profile.outputCycleNumber direction ...
            {'PSAL'} {equation} {coefficient} {comment} {''}];
         g_decArgo_paramProfAdjId = g_decArgo_paramProfAdjId + 1;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% adjust trajectory data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (g_decArgo_generateNcTraj32 ~= 0)
   
   adjFlag = 0;
   for idNMeas = 1:length(o_tabTrajNMeas)
      for idMeas = 1:length(o_tabTrajNMeas(idNMeas).tabMeas)
         
         tabMeas = o_tabTrajNMeas(idNMeas).tabMeas(idMeas);
         if (~isempty(tabMeas.paramList) && ...
               any(strcmp({tabMeas.paramList.name}, 'PSAL')))
            
            % retrieve PTS and PT_ADJUSTED values
            idPres = find(strcmp({tabMeas.paramList.name}, 'PRES'));
            idTemp = find(strcmp({tabMeas.paramList.name}, 'TEMP'));
            idPsal = find(strcmp({tabMeas.paramList.name}, 'PSAL'));
            
            presValues = tabMeas.paramData(:, idPres);
            tempValues = tabMeas.paramData(:, idTemp);
            psalValues = tabMeas.paramData(:, idPsal);
            
            presAdjValues = presValues;
            tempAdjValues = tempValues;
            if (~isempty(tabMeas.paramDataMode))
               if (tabMeas.paramDataMode(idPres) == 'A')
                  presAdjValues = tabMeas.paramDataAdj(:, idPres);
               end
               if (tabMeas.paramDataMode(idTemp) == 'A')
                  tempAdjValues = tabMeas.paramDataAdj(:, idTemp);
               end
            end
            
            % clean fill values
            idNoDefPts = find((presValues ~= paramPres.fillValue) & ...
               (presAdjValues ~= paramPres.fillValue) & ...
               (tempValues ~= paramTemp.fillValue) & ...
               (tempAdjValues ~= paramTemp.fillValue) & ...
               (psalValues ~= paramPsal.fillValue));
            presValues = presValues(idNoDefPts);
            presAdjValues = presAdjValues(idNoDefPts);
            tempValues = tempValues(idNoDefPts);
            tempAdjValues = tempAdjValues(idNoDefPts);
            psalValues = psalValues(idNoDefPts);
            
            if (~isempty(presValues) && ~isempty(tempValues) && ~isempty(psalValues) && ...
                  ~isempty(presAdjValues) && ~isempty(tempAdjValues))
               
               % compute original conductivity
               cndcValues = gsw_C_from_SP(psalValues, tempValues, presValues);
               
               % adjust conductivity
               cndcAdjValues = cndcValues.*(1 + DELTA*tempValues + CPCOR_SBE*presValues)./ ...
                  (1 + DELTA*tempAdjValues + CPCOR_NEW_SBE_41CP*presAdjValues);
               
               % compute adjusted salinity
               psalAjValues = gsw_SP_from_C(cndcAdjValues, tempAdjValues, presAdjValues);
               psalAjValues(isnan(psalAjValues)) = paramPsal.fillValue;
               
               % create array for adjusted data
               paramFillValue = get_prof_param_fill_value(tabMeas);
               if (isempty(tabMeas.paramDataAdj))
                  tabMeas.paramDataMode = repmat(' ', 1, length(tabMeas.paramList));
                  tabMeas.paramDataAdj = repmat(double(paramFillValue), size(tabMeas.paramData, 1), 1);
               end
               if (isempty(tabMeas.paramDataAdjQc))
                  tabMeas.paramDataAdjQc = ones(size(tabMeas.paramDataAdj, 1), length(tabMeas.paramList))*g_decArgo_qcDef;
               end
               if (isempty(tabMeas.paramDataAdjError))
                  tabMeas.paramDataAdjError = repmat(double(paramFillValue), size(tabMeas.paramData, 1), 1);
               end
               
               % store adjusted data
               tabMeas.paramDataMode(idPsal) = 'A';
               tabMeas.paramDataAdj(idNoDefPts, idPsal) = psalAjValues;
               
               idNoDef = find(tabMeas.paramDataAdj(:, idPsal) ~= paramPsal.fillValue);
               tabMeas.paramDataAdjQc(idNoDef, idPsal) = g_decArgo_qcNoQc;
               
               % store error on adjusted data
               idNoDef = find(tabMeas.paramData(:, idPres) ~= paramPres.fillValue);
               tabMeas.paramDataAdjError(idNoDef, idPres) = (2.5/6000) * tabMeas.paramData(idNoDef, idPres) + 2;
               
               idNoDef = find(tabMeas.paramData(:, idTemp) ~= paramTemp.fillValue);
               tabMeas.paramDataAdjError(idNoDef, idTemp) = 0.002;
               
               idNoDef = find(tabMeas.paramDataAdj(:, idPsal) ~= paramPsal.fillValue);
               tabMeas.paramDataAdjError(idNoDef, idPsal) = 0.004;
               
               o_tabTrajNMeas(idNMeas).tabMeas(idMeas) = tabMeas;
               adjFlag = 1;
               
               % store trajectory adjustment information for NetCDF file
               store_traj_adj_info(2, o_tabTrajNMeas(idNMeas).outputCycleNumber, ...
                  'PSAL', equation, coefficient, comment, '');
            end
         end
      end
   end
   
   % update DATA_MODE
   if (adjFlag)
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
end

return

% ------------------------------------------------------------------------------
% Perform real time linear adjustment on any parameter (but DOXY) profile data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = ...
%    compute_rt_adjusted_param_from_db(a_tabProfiles, a_tabTrajNMeas, a_tabTrajNCycle)
%
% INPUT PARAMETERS :
%   a_tabProfiles   : input profile structures
%   a_tabTrajNMeas  : input N_MEASUREMENT trajectory data
%   a_tabTrajNCycle : input N_CYCLE trajectory data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles   : output profile structures
%   o_tabTrajNMeas  : output N_MEASUREMENT trajectory data
%   o_tabTrajNCycle : output N_CYCLE trajectory data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/02/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = ...
   compute_rt_adjusted_param_from_db(a_tabProfiles, a_tabTrajNMeas, a_tabTrajNCycle)

% output parameters initialization
o_tabProfiles = a_tabProfiles;
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;

% QC flag values (numerical)
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;

% global default values
global g_decArgo_dateDef;
global g_decArgo_nbHourForProfDateCompInRtOffsetAdj;
global g_decArgo_janFirst1950InMatlab;

% to store information on adjustments
global g_decArgo_paramProfAdjInfo;
global g_decArgo_paramProfAdjId;

% TRAJ 3.2 file generation flag
global g_decArgo_generateNcTraj32;


if (isempty(g_decArgo_rtOffsetInfo))
   return
end

if (isempty(o_tabProfiles))
   return
end

profDateList = [o_tabProfiles.date];
profDateList(profDateList == g_decArgo_dateDef) = [];
adjFlag = 0;
for idPar = 1:length(g_decArgo_rtOffsetInfo.param)
   if (strcmp(g_decArgo_rtOffsetInfo.param{idPar}, 'DOXY')) % DOXY RT adjustment is specific and performed in compute_rt_adjusted_doxy
      continue
   end
   
   % we can have multiple linear adjustments for a given parameter
   paramName = g_decArgo_rtOffsetInfo.param{idPar};
   tabSlope = g_decArgo_rtOffsetInfo.slope{idPar};
   tabOffset = g_decArgo_rtOffsetInfo.value{idPar};
   tabEquation = g_decArgo_rtOffsetInfo.equation{idPar};
   tabCoef = g_decArgo_rtOffsetInfo.coefficient{idPar};
   tabComment = g_decArgo_rtOffsetInfo.comment{idPar};
   tabDate = g_decArgo_rtOffsetInfo.date{idPar};
   
   for idAdj = 1:length(tabDate)
      
      slopeRtAdj = tabSlope(idAdj);
      offsetRtAdj = tabOffset(idAdj);
      equationRtAdj = tabEquation{idAdj};
      coefRtAdj = tabCoef{idAdj};
      commentRtAdj = tabComment{idAdj};
      dateRtAdj = tabDate(idAdj);
      
      % basic adjustment information for NetCDF files
      equation = equationRtAdj;
      coefficient = coefRtAdj;
      comment = commentRtAdj;
      date = datestr(dateRtAdj+g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
      
      if (any((profDateList + g_decArgo_nbHourForProfDateCompInRtOffsetAdj/24) >= dateRtAdj))
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % adjust profile data
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
         for idProf = 1:length(o_tabProfiles)
            profile = o_tabProfiles(idProf);
            if (any(strcmp({profile.paramList.name}, paramName)) && ...
                  (profile.date ~= g_decArgo_dateDef) && ...
                  ((profile.date + g_decArgo_nbHourForProfDateCompInRtOffsetAdj/24) >= dateRtAdj))
               
               [idParam, firstCol, lastCol] = get_param_data_index(profile, paramName);
               
               % create array for adjusted data
               if (isempty(profile.dataAdj))
                  profile.paramDataMode = repmat(' ', 1, length(profile.paramList));
                  paramFillValue = get_prof_param_fill_value(profile);
                  profile.dataAdj = repmat(double(paramFillValue), size(profile.data, 1), 1);
                  
                  paramData = profile.data(:, firstCol:lastCol);
               else
                  if (profile.paramDataMode(idParam) == ' ')
                     paramData = profile.data(:, firstCol:lastCol);
                  else
                     paramData = profile.dataAdj(:, firstCol:lastCol);
                  end
               end
               if (isempty(profile.dataAdjQc))
                  profile.dataAdjQc = ones(size(profile.dataAdj, 1), length(profile.paramList))*g_decArgo_qcDef;
               end
               
               % adjust data
               paramDataAdj = paramData;
               idNoDef = find(paramDataAdj ~= profile.paramList(idParam).fillValue);
               paramDataAdj(idNoDef) = paramDataAdj(idNoDef)*slopeRtAdj + offsetRtAdj;
               
               % store adjusted data
               profile.paramDataMode(idParam) = 'A';
               profile.dataAdj(:, firstCol:lastCol) = paramDataAdj;
               idNoDef = find(paramDataAdj ~= profile.paramList(idParam).fillValue);
               profile.dataAdjQc(idNoDef, idParam) = g_decArgo_qcNoQc;
               
               profile.rtParamAdjIdList = [profile.rtParamAdjIdList g_decArgo_paramProfAdjId];
               o_tabProfiles(idProf) = profile;
               
               % store profile adjustment information for NetCDF file
               if (profile.direction == 'A')
                  direction = 2;
               else
                  direction = 1;
               end
               
               g_decArgo_paramProfAdjInfo = [g_decArgo_paramProfAdjInfo;
                  g_decArgo_paramProfAdjId profile.outputCycleNumber direction ...
                  {paramName} {equation} {coefficient} {comment} {date}];
               g_decArgo_paramProfAdjId = g_decArgo_paramProfAdjId + 1;
            end
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % adjust trajectory data
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
         if (g_decArgo_generateNcTraj32 ~= 0)
            
            idProfToAdjust = find(([o_tabProfiles.date] ~= g_decArgo_dateDef) & ...
               (([o_tabProfiles.date] + g_decArgo_nbHourForProfDateCompInRtOffsetAdj/24) >= dateRtAdj));
            firstCyToAdjust = min([o_tabProfiles(idProfToAdjust).outputCycleNumber]);
            
            idTrajToAdjust = find([o_tabTrajNMeas.outputCycleNumber] >= firstCyToAdjust);
            for idTraj = idTrajToAdjust
               for idMeas = 1:length(o_tabTrajNMeas(idTraj).tabMeas)
                  tabMeas = o_tabTrajNMeas(idTraj).tabMeas(idMeas);
                  if (~isempty(tabMeas.paramList) && ...
                        any(strcmp({tabMeas.paramList.name}, paramName)))
                     
                     [idParam, firstCol, lastCol] = get_param_data_index(tabMeas, paramName);
                     
                     % create array for adjusted data
                     if (isempty(tabMeas.paramDataAdj))
                        tabMeas.paramDataMode = repmat(' ', 1, length(tabMeas.paramList));
                        paramFillValue = get_prof_param_fill_value(tabMeas);
                        tabMeas.paramDataAdj = repmat(double(paramFillValue), size(tabMeas.paramData, 1), 1);
                        
                        % parameter data
                        paramData = tabMeas.paramData(:, firstCol:lastCol);
                     else
                        if (tabMeas.paramDataMode(idParam) == ' ')
                           paramData = tabMeas.paramData(:, firstCol:lastCol);
                        else
                           paramData = tabMeas.paramDataAdj(:, firstCol:lastCol);
                        end
                     end
                     if (isempty(tabMeas.paramDataAdjQc))
                        tabMeas.paramDataAdjQc = ones(size(tabMeas.paramDataAdj, 1), length(tabMeas.paramList))*g_decArgo_qcDef;
                     end
                     
                     % adjust data
                     paramDataAdj = paramData;
                     idNoDef = find(paramDataAdj ~= tabMeas.paramList(idParam).fillValue);
                     paramDataAdj(idNoDef) = paramDataAdj(idNoDef)*slopeRtAdj + offsetRtAdj;
                     
                     % store adjusted data
                     tabMeas.paramDataMode(idParam) = 'A';
                     tabMeas.paramDataAdj(:, firstCol:lastCol) = paramDataAdj;
                     idNoDef = find(paramDataAdj ~= tabMeas.paramList(idParam).fillValue);
                     tabMeas.paramDataAdjQc(idNoDef, idParam) = g_decArgo_qcNoQc;
                     o_tabTrajNMeas(idTraj).tabMeas(idMeas) = tabMeas;
                     adjFlag = 1;
                     
                     % store trajectory adjustment information for NetCDF file
                     store_traj_adj_info(1, o_tabTrajNMeas(idTraj).outputCycleNumber, ...
                        paramName, equation, coefficient, comment, date);
                  end
               end
            end
         end
      end
   end
end

% update DATA_MODE
if (g_decArgo_generateNcTraj32 ~= 0)
   if (adjFlag)
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
end

return

% ------------------------------------------------------------------------------
% Perform real time adjustment on DOXY profile data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = ...
%    compute_rt_adjusted_doxy(a_tabProfiles, a_tabTrajNMeas, a_tabTrajNCycle, a_launchDate, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabProfiles   : input profile structures
%   a_tabTrajNMeas  : input N_MEASUREMENT trajectory data
%   a_tabTrajNCycle : input N_CYCLE trajectory data
%   a_launchDate    : float launch date
%   a_decoderId     : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabProfiles   : output profile structures
%   o_tabTrajNMeas  : output N_MEASUREMENT trajectory data
%   o_tabTrajNCycle : output N_CYCLE trajectory data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/03/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = ...
   compute_rt_adjusted_doxy(a_tabProfiles, a_tabTrajNMeas, a_tabTrajNCycle, a_launchDate, a_decoderId)

% output parameters initialization
o_tabProfiles = a_tabProfiles;
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;

% current float WMO number
global g_decArgo_floatNum;

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;

% global default values
global g_decArgo_dateDef;
global g_decArgo_nbHourForProfDateCompInRtOffsetAdj;
global g_decArgo_janFirst1950InMatlab;

% to store information on DOXY adjustment
global g_decArgo_paramProfAdjInfo;
global g_decArgo_paramProfAdjId;

% TRAJ 3.2 file generation flag
global g_decArgo_generateNcTraj32;


% look for DOXY profiles
noDoxyProfile = 1;
for idProf = 1:length(o_tabProfiles)
   if (any(strcmp({o_tabProfiles(idProf).paramList.name}, 'DOXY')))
      noDoxyProfile = 0;
      break
   end
end
if (noDoxyProfile)
   % under the assumption that no DOXY profiles means that there is no DOXY
   % measurement in the trajectory
   return
end

% retrieve information on DOXY adjustement in RT_OFFSET information of META.json file
doSlope = '';
doOffset = '';
doDrift = '';
doInclineT = '';
doCorPres = '';
doDate = '';
doAdjError = '';
doAdjErrorStr = '';
doAdjErrMethod = '';
if (~isempty(g_decArgo_rtOffsetInfo))
   for idF = 1:length(g_decArgo_rtOffsetInfo.param)
      if (strcmp(g_decArgo_rtOffsetInfo.param{idF}, 'DOXY'))
         % mandatory fields
         doSlope = g_decArgo_rtOffsetInfo.slope{idF};
         doOffset = g_decArgo_rtOffsetInfo.value{idF};
         doDate = g_decArgo_rtOffsetInfo.date{idF};
         % not mandatory fields
         if (isfield(g_decArgo_rtOffsetInfo, 'adjError'))
            doAdjError = g_decArgo_rtOffsetInfo.adjError{idF};
            doAdjErrorStr = g_decArgo_rtOffsetInfo.adjErrorStr{idF}{:};
            doAdjErrMethod = g_decArgo_rtOffsetInfo.adjErrorMethod{idF}{:};
         end
         % new fields (possibly not filled for old adjustments)
         doDrift = 0;
         if (isfield(g_decArgo_rtOffsetInfo, 'drift'))
            doDrift = g_decArgo_rtOffsetInfo.drift{idF};
         end
         doInclineT = 0;
         if (isfield(g_decArgo_rtOffsetInfo, 'inclineT'))
            doInclineT = g_decArgo_rtOffsetInfo.inclineT{idF};
         end
         doCorPres = nan;
         if (isfield(g_decArgo_rtOffsetInfo, 'doCorPres'))
            doCorPres = g_decArgo_rtOffsetInfo.doCorPres{idF};
         end
         break
      end
   end
end

if (~isempty(doSlope))
   
   profDateList = [o_tabProfiles.date];
   profDateList(profDateList == g_decArgo_dateDef) = [];
   
   if (any((profDateList + g_decArgo_nbHourForProfDateCompInRtOffsetAdj/24) >= doDate))
      
      % some cases need the PPOX_ERROR to increase with time
      startDateToIncreasePpoxErrorWithTime = '';
      if (~isnan(doAdjError))
         switch (doAdjErrMethod)
            case {'1_1', '2_1'}
               startDateToIncreasePpoxErrorWithTime = '';
            case {'1_2', '2_2', '3_2', '3_2_2'}
               startDateToIncreasePpoxErrorWithTime = doDate;
         end
      end
      
      % basic adjustment information for NetCDF files
      if (~isnan(doAdjError))
         switch (doAdjErrMethod)
            case {'1_1', '1_2', '2_1', '2_2', '3_2'}
               equation = ['PPOX_DOXY=f(DOXY), ' ...
                  'PPOX_DOXY_ADJUSTED=(SLOPE*(1+DRIFT/100*(profile_date_juld-launch_date_juld)/365)+INCLINE_T*TEMP)*(PPOX_DOXY+OFFSET), ' ...
                  'DOXY_ADJUSTED=f(PPOX_DOXY_ADJUSTED)'];
               coefficient = sprintf('OFFSET = %.2f, SLOPE = %.4f, DRIFT = %.3f, INCLINE_T = %.6f, launch_date_juld = %s', ...
                  doOffset, doSlope, doDrift, doInclineT, datestr(a_launchDate + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS'));
            case {'3_2_2'}
               equation = ['DOXY_COR_PRES=DOXY*(1+DO_COR_PRES*PRES/1000), '...
                  'PPOX_DOXY=f(DOXY_COR_PRES), ' ...
                  'PPOX_DOXY_ADJUSTED=(SLOPE*(1+DRIFT/100*(profile_date_juld-launch_date_juld)/365)+INCLINE_T*TEMP)*(PPOX_DOXY+OFFSET), ' ...
                  'DOXY_ADJUSTED=f(PPOX_DOXY_ADJUSTED)'];
               coefficient = sprintf('OFFSET = %.2f, SLOPE = %.4f, DRIFT = %.3f, INCLINE_T = %.6f, DO_COR_PRES = %.4f, launch_date_juld = %s', ...
                  doOffset, doSlope, doDrift, doInclineT, doCorPres, datestr(a_launchDate + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS'));
         end
      end
      comment = '';
      if (~isnan(doAdjError))
         switch (doAdjErrMethod)
            case '1_1'
               comment = sprintf(['DOXY_ADJUSTED is computed from an adjustment ' ...
                  'of in water PSAT or PPOX float data at surface by comparison to woaPSAT ' ...
                  'climatology or WOA PPOX in using woaPSAT and floatTEMP and PSAL at 1 atm, ' ...
                  'DOXY_ADJUSTED_ERROR is computed from a PPOX_ERROR of %s mbar'], doAdjErrorStr);
            case '1_2'
               comment = sprintf(['DOXY_ADJUSTED is computed from an adjustment ' ...
                  'of in water PSAT or PPOX float data at surface by comparison to woaPSAT ' ...
                  'climatology or woaPPOX{woaPSAT,floatTEMP,floatPSAL} at 1 atm, ' ...
                  'DOXY_ADJUSTED_ERROR is computed from a PPOX_ERROR of %s mbar +1mb/year'], doAdjErrorStr);
            case '2_1'
               comment = sprintf(['DOXY_ADJUSTED is estimated from an adjustment ' ...
                  'of in air PPOX float data by comparison to NCEP reanalysis, ' ...
                  'DOXY_ADJUSTED_ERROR is recomputed from a PPOX_ERROR = %s mbar'], doAdjErrorStr);
            case '2_2'
               comment = sprintf(['DOXY_ADJUSTED is estimated from an adjustment ' ...
                  'of in air PPOX float data by comparison to NCEP reanalysis, ' ...
                  'DOXY_ADJUSTED_ERROR is recomputed from a PPOX_ERROR = %s mbar ' ...
                  'with an increase of 1mbar/year'], doAdjErrorStr);
            case '3_2'
               comment = sprintf(['DOXY_ADJUSTED is estimated from the last valid cycle ' ...
                  'with DM adjustment, DOXY_ADJUSTED_ERROR is recomputed from a ' ...
                  'PPOX_ERROR = %s mbar with an increase of 1mbar/year'], doAdjErrorStr);
            case '3_2_2'
               comment = sprintf(['DOXY_ADJUSTED is estimated from the last valid cycle ' ...
                  'with DM adjustment that includes a refined pressure correction coefficient, ', ...
                  'DOXY_ADJUSTED_ERROR is recomputed from a ' ...
                  'PPOX_ERROR = %s mbar with an increase of 1mbar/year'], doAdjErrorStr);
            otherwise
               fprintf('ERROR: Float #%d: input CALIB_RT_ADJ_ERROR_METHOD (''%s'') of DOXY adjustment is not implemented yet - SCIENTIFIC_CALIB_COMMENT of DOXY parameter not set\n', ...
                  g_decArgo_floatNum, ...
                  doAdjErrMethod);
         end
      end
      date = datestr(doDate+g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % adjust DOXY profile data
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      for idProf = 1:length(o_tabProfiles)
         profile = o_tabProfiles(idProf);
         if (any(strcmp({profile.paramList.name}, 'DOXY')) && ...
               (profile.date ~= g_decArgo_dateDef) && ...
               ((profile.date + g_decArgo_nbHourForProfDateCompInRtOffsetAdj/24) >= doDate))
            
            % retrieve associated profiles (needed for 'real' BGC floats since
            % PTS are in separate profiles)
            idProfs = find(([o_tabProfiles.outputCycleNumber] == profile.outputCycleNumber) & ...
               ([o_tabProfiles.direction] == profile.direction) & ...
               ([o_tabProfiles.sensorNumber] < 100)); % AUX profiles should not be considered
            
            % adjust DOXY for this profile
            [ok, profile] = adjust_doxy_profile( ...
               profile, o_tabProfiles(setdiff(idProfs, idProf)), ...
               doCorPres, doSlope, doOffset, doDrift, doInclineT, ...
               doAdjError, startDateToIncreasePpoxErrorWithTime, a_launchDate, a_decoderId);
            if (ok)
               profile.rtParamAdjIdList = [profile.rtParamAdjIdList g_decArgo_paramProfAdjId];
               o_tabProfiles(idProf) = profile;
               
               % store profile adjustment information for NetCDF file
               if (profile.direction == 'A')
                  direction = 2;
               else
                  direction = 1;
               end
               
               g_decArgo_paramProfAdjInfo = [g_decArgo_paramProfAdjInfo;
                  g_decArgo_paramProfAdjId profile.outputCycleNumber direction ...
                  {'DOXY'} {equation} {coefficient} {comment} {date}];
               g_decArgo_paramProfAdjId = g_decArgo_paramProfAdjId + 1;
            end
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % adjust DOXY trajectory data
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      if (g_decArgo_generateNcTraj32 ~= 0)
         
         idProfToAdjust = find(([o_tabProfiles.date] ~= g_decArgo_dateDef) & ...
            (([o_tabProfiles.date] + g_decArgo_nbHourForProfDateCompInRtOffsetAdj/24) >= doDate));
         firstCyToAdjust = min([o_tabProfiles(idProfToAdjust).outputCycleNumber]);
         
         idTrajToAdjust = find([o_tabTrajNMeas.outputCycleNumber] >= firstCyToAdjust);
         adjFlag = 0;
         for idTraj = idTrajToAdjust
            for idMeas = 1:length(o_tabTrajNMeas(idTraj).tabMeas)
               tabMeas = o_tabTrajNMeas(idTraj).tabMeas(idMeas);
               if (~isempty(tabMeas.paramList) && ...
                     any(strcmp({tabMeas.paramList.name}, 'DOXY')))

                  % adjust DOXY for this measurement
                  [ok, tabMeas] = adjust_doxy_traj_meas(tabMeas, ...
                     doCorPres, doSlope, doOffset, doDrift, doInclineT, ...
                     doAdjError, startDateToIncreasePpoxErrorWithTime, a_launchDate, ...
                     o_tabTrajNMeas(idTraj), idMeas, a_decoderId);
                  if (ok)
                     o_tabTrajNMeas(idTraj).tabMeas(idMeas) = tabMeas;
                     adjFlag = 1;
                     
                     % store trajectory adjustment information for NetCDF file
                     store_traj_adj_info(3, o_tabTrajNMeas(idTraj).outputCycleNumber, ...
                        'DOXY', equation, coefficient, comment, date);
                  end
               end
            end
         end
         
         % update DATA_MODE
         if (adjFlag)
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
      end
   end
end

return

% ------------------------------------------------------------------------------
% Perform real time adjustment on one DOXY measurement data.
%
% SYNTAX :
%  [o_ok, o_tabMeas] = adjust_doxy_traj_meas(a_tabMeas, ...
%    a_doCorPres, a_slope, a_offset, a_doDrift, a_doInclineT, ...
%    a_adjError, a_adjDate, a_launchDate, a_trajNMeas, a_idMeas, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabMeas    : input DOXY measurement structure
%   a_doCorPres  : coefficient for DOXY correction f(PRES) - in CASE 3_2_2 only
%   a_slope      : slope to be used for PPOX_DOXY adjustment
%   a_offset     : offset to be used for PPOX_DOXY adjustment
%   a_doDrift    : drift to be used for PPOX_DOXY adjustment
%   a_doInclineT : incline_t to be used for PPOX_DOXY adjustment
%   a_adjError   : error on PPOX_DOXY adjusted values
%   a_adjDate    : start date to apply adjustment
%   a_launchDate : float launch date
%   a_trajNMeas  : associated cycle measurements
%   a_idMeas     : index of current measurement in cycle measurements
%   a_decoderId  : float decoder Id

%
% OUTPUT PARAMETERS :
%   o_ok      : 1 if the adjustment has been performed, 0 otherwise
%   o_tabMeas : output DOXY measurement structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/01/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok, o_tabMeas] = adjust_doxy_traj_meas(a_tabMeas, ...
   a_doCorPres, a_slope, a_offset, a_doDrift, a_doInclineT, ...
   a_adjError, a_adjDate, a_launchDate, a_trajNMeas, a_idMeas, a_decoderId)

% output parameters initialization
o_ok = 0;
o_tabMeas = [];

% current float WMO number
global g_decArgo_floatNum;

% QC flag values (numerical)
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;

% global measurement codes
global g_MC_RPP;

% lists of managed decoders
global g_decArgo_decoderIdListBgcFloatAll;


if (isempty(a_tabMeas.ptsForDoxy))
   if (ismember(a_decoderId, g_decArgo_decoderIdListBgcFloatAll))
      %       if (~ismember(a_tabMeas.measCode, [g_MC_RPP]))
      %          fprintf('INFO: Float #%d Cycle #%d MC %d: Empty ptsForDoxy => not adjusted\n', ...
      %             g_decArgo_floatNum, ...
      %             a_trajNMeas.outputCycleNumber, ...
      %             a_tabMeas.measCode);
      %       end
      return
   else
      idPres = find(strcmp({a_tabMeas.paramList.name}, 'PRES'));
      idTemp = find(strcmp({a_tabMeas.paramList.name}, 'TEMP'));
      idPsal = find(strcmp({a_tabMeas.paramList.name}, 'PSAL'));
      if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal))
         a_tabMeas.ptsForDoxy = a_tabMeas.paramData(:, [idPres idTemp idPsal]);
      else
         %          if (~ismember(a_tabMeas.measCode, [g_MC_RPP]))
         %             fprintf('INFO: Float #%d Cycle #%d MC %d: Empty ptsForDoxy => not adjusted\n', ...
         %                g_decArgo_floatNum, ...
         %                a_trajNMeas.outputCycleNumber, ...
         %                a_tabMeas.measCode);
         %          end
         return
      end
   end
end

% involved parameter information
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramPsal = get_netcdf_param_attributes('PSAL');
paramDoxy = get_netcdf_param_attributes('DOXY');

% retrieve associated PTS measurements
presValues = a_tabMeas.ptsForDoxy(:, 1);
tempValues = a_tabMeas.ptsForDoxy(:, 2);
psalValues = a_tabMeas.ptsForDoxy(:, 3);

% retrieve DOXY measurements
idDoxy = find(strcmp({a_tabMeas.paramList.name}, 'DOXY'));
doxyValues = a_tabMeas.paramData(:, idDoxy);

% adjust DOXY data
[doxyAdjValues, doxyAdjErrValues] = compute_DOXY_ADJUSTED_traj_meas( ...
   presValues, tempValues, psalValues, doxyValues, ...
   paramPres.fillValue, paramTemp.fillValue, paramPsal.fillValue, paramDoxy.fillValue, ...
   a_doCorPres, a_slope, a_offset, a_doDrift, a_doInclineT, a_launchDate, a_adjError, a_adjDate, ...
   a_trajNMeas, a_tabMeas, a_idMeas);

if (any(doxyAdjValues ~= paramDoxy.fillValue))
   
   % create array for adjusted data
   tabMeas = a_tabMeas;
   paramFillValue = get_prof_param_fill_value(tabMeas);
   if (isempty(tabMeas.paramDataAdj))
      tabMeas.paramDataMode = repmat(' ', 1, length(tabMeas.paramList));
      tabMeas.paramDataAdj = repmat(double(paramFillValue), size(tabMeas.paramData, 1), 1);
   end
   if (isempty(tabMeas.paramDataAdjQc))
      tabMeas.paramDataAdjQc = ones(size(tabMeas.paramDataAdj, 1), length(tabMeas.paramList))*g_decArgo_qcDef;
   end
   if (isempty(tabMeas.paramDataAdjError))
      tabMeas.paramDataAdjError = repmat(double(paramFillValue), size(tabMeas.paramData, 1), 1);
   end
   
   % store adjusted data
   tabMeas.paramDataMode(idDoxy) = 'A';
   tabMeas.paramDataAdj(:, idDoxy) = doxyAdjValues;
   
   idNoDef = find(tabMeas.paramDataAdj(:, idDoxy) ~= paramDoxy.fillValue);
   tabMeas.paramDataAdjQc(idNoDef, idDoxy) = g_decArgo_qcNoQc;
   
   % store error on adjusted data
   if (~isempty(doxyAdjErrValues))
      tabMeas.paramDataAdjError(:, idDoxy) = doxyAdjErrValues;
   end
   
   % output parameters
   o_ok = 1;
   o_tabMeas = tabMeas;
end

return

% ------------------------------------------------------------------------------
% Perform real time adjustment on one DOXY profile data.
%
% SYNTAX :
%  [o_ok, o_profile] = adjust_doxy_profile( ...
%    a_profile, a_tabProfiles, ...
%    a_doCorPres, a_slope, a_offset, a_doDrift, a_doInclineT, ...
%    a_adjError, a_adjDate, a_launchDate, a_decoderId)
%
% INPUT PARAMETERS :
%   a_profile     : input DOXY profile structure
%   a_tabProfiles : profile structures with the same cycle number and
%                   direction as the DOXY one
%   a_doCorPres   : coefficient for DOXY correction f(PRES) - in CASE 3_2_2 only
%   a_slope       : slope to be used for PPOX_DOXY adjustment
%   a_offset      : offset to be used for PPOX_DOXY adjustment
%   a_doDrift     : drift to be used for PPOX_DOXY adjustment
%   a_doInclineT  : incline_t to be used for PPOX_DOXY adjustment
%   a_adjError    : error on PPOX_DOXY adjusted values
%   a_adjDate     : start date to apply adjustment
%   a_launchDate  : float launch date
%   a_decoderId   : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_ok      : 1 if the adjustment has been performed, 0 otherwise
%   o_profile : output DOXY profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/03/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok, o_profile] = adjust_doxy_profile( ...
   a_profile, a_tabProfiles, ...
   a_doCorPres, a_slope, a_offset, a_doDrift, a_doInclineT, ...
   a_adjError, a_adjDate, a_launchDate, a_decoderId)

% output parameters initialization
o_ok = 0;
o_profile = [];

% current float WMO number
global g_decArgo_floatNum;

% QC flag values (numerical)
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;

% lists of managed decoders
global g_decArgo_decoderIdListBgcFloatAll;


% involved parameter information
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramPsal = get_netcdf_param_attributes('PSAL');
paramDoxy = get_netcdf_param_attributes('DOXY');

% retrieve or interpolate PTS measurements
presValues = [];
tempValues = [];
psalValues = [];
doxyValues = [];
idPres = find(strcmp({a_profile.paramList.name}, 'PRES'));
idTemp = find(strcmp({a_profile.paramList.name}, 'TEMP'));
idPsal = find(strcmp({a_profile.paramList.name}, 'PSAL'));
idDoxy = find(strcmp({a_profile.paramList.name}, 'DOXY'));

if (~ismember(a_decoderId, g_decArgo_decoderIdListBgcFloatAll))
   
   % case of a PTSO float
   presValues = a_profile.data(:, idPres);
   tempValues = a_profile.data(:, idTemp);
   psalValues = a_profile.data(:, idPsal);
   doxyValues = a_profile.data(:, idDoxy);
else
   
   % case of a 'real' BGC float
   
   % create a PTS profile by concatenating the near-surface and the primary
   % sampling profiles
   idNssProf = [];
   idPsProf = [];
   for idProf = 1:length(a_tabProfiles)
      profile = a_tabProfiles(idProf);
      if (strncmp(profile.vertSamplingScheme, 'Near-surface sampling:', length('Near-surface sampling:')))
         idNssPres = find(strcmp({profile.paramList.name}, 'PRES'));
         idNssTemp = find(strcmp({profile.paramList.name}, 'TEMP'));
         idNssPsal = find(strcmp({profile.paramList.name}, 'PSAL'));
         if (~isempty(idNssPres) && ~isempty(idNssTemp) && ~isempty(idNssPsal))
            idNssProf = idProf;
         end
      elseif (strncmp(profile.vertSamplingScheme, 'Primary sampling:', length('Primary sampling:')))
         idPsPres = find(strcmp({profile.paramList.name}, 'PRES'));
         idPsTemp = find(strcmp({profile.paramList.name}, 'TEMP'));
         idPsPsal = find(strcmp({profile.paramList.name}, 'PSAL'));
         if (~isempty(idPsPres) && ~isempty(idPsTemp) && ~isempty(idPsPsal))
            idPsProf = idProf;
         end
      end
      if (~isempty(idNssProf) && ~isempty(idPsProf))
         break
      end
   end
   
   if (~isempty(idNssProf) && ~isempty(idPsProf))
      ctdPresData = [a_tabProfiles(idPsProf).data(:, idPsPres); a_tabProfiles(idNssProf).data(:, idNssPres)];
      ctdTempData = [a_tabProfiles(idPsProf).data(:, idPsTemp); a_tabProfiles(idNssProf).data(:, idNssTemp)];
      ctdPsalData = [a_tabProfiles(idPsProf).data(:, idPsPsal); a_tabProfiles(idNssProf).data(:, idNssPsal)];
   elseif (~isempty(idPsProf))
      ctdPresData = a_tabProfiles(idPsProf).data(:, idPsPres);
      ctdTempData = a_tabProfiles(idPsProf).data(:, idPsTemp);
      ctdPsalData = a_tabProfiles(idPsProf).data(:, idPsPsal);
   elseif (~isempty(idNssProf))
      ctdPresData = a_tabProfiles(idNssProf).data(:, idNssPres);
      ctdTempData = a_tabProfiles(idNssProf).data(:, idNssTemp);
      ctdPsalData = a_tabProfiles(idNssProf).data(:, idNssPsal);
   else
      ctdPresData = [];
      ctdTempData = [];
      ctdPsalData = [];
   end
   
   % clean fill values
   idNoDefPts = find((ctdPresData ~= paramPres.fillValue) & ...
      (ctdTempData ~= paramTemp.fillValue) & ...
      (ctdPsalData ~= paramPsal.fillValue));
   
   ctdPresData = ctdPresData(idNoDefPts);
   ctdTempData = ctdTempData(idNoDefPts);
   ctdPsalData = ctdPsalData(idNoDefPts);
   
   if (~isempty(ctdPresData))
      
      % interpolate and extrapolate the PTS data at the pressures of the
      % DOXY measurements
      ctdIntData = compute_interpolated_CTD_measurements(...
         [ctdPresData ctdTempData ctdPsalData], a_profile.data(:, idPres), a_profile.direction);
      
      presValues = ctdIntData(:, 1);
      tempValues = ctdIntData(:, 2);
      psalValues = ctdIntData(:, 3);
      doxyValues = a_profile.data(:, idDoxy);
   else
      fprintf('WARNING: Float #%d Cycle #%d%c: unable to find the associated CTD profile to adjust DOXY parameter - DOXY data cannot be adjusted\n', ...
         g_decArgo_floatNum, ...
         a_profile.outputCycleNumber, a_profile.direction);
   end
end

if (~isempty(presValues))
   
   % adjust DOXY data
   [doxyAdjValues, doxyAdjErrValues] = compute_DOXY_ADJUSTED_profile( ...
      presValues, tempValues, psalValues, doxyValues, ...
      paramPres.fillValue, paramTemp.fillValue, paramPsal.fillValue, paramDoxy.fillValue, ...
      a_doCorPres, a_slope, a_offset, a_doDrift, a_doInclineT, a_launchDate, a_adjError, a_adjDate, a_profile);
   
   if (any(doxyAdjValues ~= paramDoxy.fillValue))
      
      % create array for adjusted data
      profile = a_profile;
      paramFillValue = get_prof_param_fill_value(profile);
      if (isempty(profile.dataAdj))
         profile.paramDataMode = repmat(' ', 1, length(profile.paramList));
         profile.dataAdj = repmat(double(paramFillValue), size(profile.data, 1), 1);
      end
      if (isempty(profile.dataAdjQc))
         profile.dataAdjQc = ones(size(profile.dataAdj, 1), length(profile.paramList))*g_decArgo_qcDef;
      end
      if (isempty(profile.dataAdjError) && ~isempty(doxyAdjErrValues))
         profile.dataAdjError = repmat(double(paramFillValue), size(profile.data, 1), 1);
      end
      
      % store adjusted data
      profile.paramDataMode(idDoxy) = 'A';
      profile.dataAdj(:, idDoxy) = doxyAdjValues;
      idNoDef = find(doxyAdjValues ~= paramDoxy.fillValue);
      profile.dataAdjQc(idNoDef, idDoxy) = g_decArgo_qcNoQc;
      if (~isempty(doxyAdjErrValues))
         profile.dataAdjError(:, idDoxy) = doxyAdjErrValues;
      end
      
      % output parameters
      o_ok = 1;
      o_profile = profile;
   end
end

return

% ------------------------------------------------------------------------------
% Perform real time adjustment on CHLA profile data.
%
% SYNTAX :
%  [o_tabProfiles] = compute_rt_adjusted_chla(a_tabProfiles)
%
% INPUT PARAMETERS :
%   a_tabProfiles : input profile structures
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : output profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/28/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = compute_rt_adjusted_chla(a_tabProfiles)

% output parameters initialization
o_tabProfiles = a_tabProfiles;

% QC flag values (numerical)
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;

% to store information on CHLA adjustment
global g_decArgo_paramProfAdjInfo;
global g_decArgo_paramProfAdjId;


% look for CHLA profiles
noChlaProfile = 1;
for idProf = 1:length(o_tabProfiles)
   if (any(strcmp({o_tabProfiles(idProf).paramList.name}, 'CHLA')))
      noChlaProfile = 0;
      break
   end
end
if (noChlaProfile)
   return
end

% basic adjustment information for NetCDF files
equation = 'CHLA_ADJUSTED = CHLA/2';
comment = 'Real-time CHLA adjustment following recommendations of Roesler et al., 2017 (https://doi.org/10.1002/lom3.10185)';

% adjust CHLA data
for idProf = 1:length(o_tabProfiles)
   profile = o_tabProfiles(idProf);
   if (any(strcmp({profile.paramList.name}, 'CHLA')))
      
      paramChla = get_netcdf_param_attributes('CHLA');
      
      % retrieve CHLA data
      idChla = find(strcmp({profile.paramList.name}, 'CHLA'));
      if (~isempty(profile.paramNumberWithSubLevels))
         idSub = find(profile.paramNumberWithSubLevels < idChla);
         if (~isempty(idSub))
            idChla = idChla + sum(profile.paramNumberOfSubLevels(idSub)) - length(idSub);
         end
      end
      chlaData = profile.data(:, idChla);
      
      if (any(chlaData ~= paramChla.fillValue))
         
         % create array for adjusted data
         if (isempty(profile.dataAdj))
            paramFillValue = get_prof_param_fill_value(profile);
            profile.paramDataMode = repmat(' ', 1, length(profile.paramList));
            profile.dataAdj = repmat(double(paramFillValue), size(profile.data, 1), 1);
         end
         if (isempty(profile.dataAdjQc))
            profile.dataAdjQc = ones(size(profile.dataAdj, 1), length(profile.paramList))*g_decArgo_qcDef;
         end
         
         % adjust CHLA data
         idNoDef = find(chlaData ~= paramChla.fillValue);
         chlaDataAdj = chlaData;
         chlaDataAdj(idNoDef) = chlaDataAdj(idNoDef)/2;
         
         % store adjusted CHLA data
         profile.paramDataMode(idChla) = 'A';
         profile.dataAdj(:, idChla) = chlaDataAdj;
         profile.dataAdjQc(idNoDef, idChla) = g_decArgo_qcNoQc;
         profile.rtParamAdjIdList = [profile.rtParamAdjIdList g_decArgo_paramProfAdjId];
         o_tabProfiles(idProf) = profile;
         
         % store profile adjustment information for NetCDF file
         if (profile.direction == 'A')
            direction = 2;
         else
            direction = 1;
         end
         
         g_decArgo_paramProfAdjInfo = [g_decArgo_paramProfAdjInfo;
            g_decArgo_paramProfAdjId profile.outputCycleNumber direction ...
            {'CHLA'} {equation} {''} {comment} {''}];
         g_decArgo_paramProfAdjId = g_decArgo_paramProfAdjId + 1;
      end
   end
end

return

% ------------------------------------------------------------------------------
% Perform real time adjustment on NITRATE profile data.
%
% SYNTAX :
%  [o_tabProfiles] = compute_rt_adjusted_nitrate(a_tabProfiles, a_launchDate)
%
% INPUT PARAMETERS :
%   a_tabProfiles : input profile structures
%   a_launchDate  : float launch date
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : output profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/28/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = compute_rt_adjusted_nitrate(a_tabProfiles, a_launchDate)

% output parameters initialization
o_tabProfiles = a_tabProfiles;

% global default values
global g_decArgo_dateDef;

% current float WMO number
global g_decArgo_floatNum;

% QC flag values (numerical)
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;

% to store information on NITRATE adjustment
global g_decArgo_paramProfAdjInfo;
global g_decArgo_paramProfAdjId;

% verbose mode flag
VERBOSE_MODE = 0;


% look for NITRATE profiles
noNitrateProfile = 1;
for idProf = 1:length(o_tabProfiles)
   if (any(strcmp({o_tabProfiles(idProf).paramList.name}, 'NITRATE')))
      noNitrateProfile = 0;
      break
   end
end
if (noNitrateProfile)
   return
end

% number of days after launch date to update med_Offset value
TWO_MONTH_IN_DAYS = double(365/6);

% minimum number of offsets expected in the median
NB_OFFSET_MIN = 5;

paramPres = get_netcdf_param_attributes('PRES');
paramNitrate = get_netcdf_param_attributes('NITRATE');

% collect information on profiles
profInfo = [];
nbOffset = 0;
for idProf = 1:length(a_tabProfiles)
   profile = a_tabProfiles(idProf);
   if (any(strcmp({profile.paramList.name}, 'NITRATE')))
      
      if (profile.direction == 'A')
         direction = 2;
      else
         direction = 1;
      end
      
      idPres = find(strcmp({profile.paramList.name}, 'PRES'));
      if (~isempty(profile.paramNumberWithSubLevels))
         idSub = find(profile.paramNumberWithSubLevels < idPres);
         if (~isempty(idSub))
            idPres = idPres + sum(profile.paramNumberOfSubLevels(idSub)) - length(idSub);
         end
      end
      presData = profile.data(:, idPres);
      
      idNitrateParam = find(strcmp({profile.paramList.name}, 'NITRATE'));
      idNitrateData = idNitrateParam;
      if (~isempty(profile.paramNumberWithSubLevels))
         idSub = find(profile.paramNumberWithSubLevels < idNitrateData);
         if (~isempty(idSub))
            idNitrateData = idNitrateData + sum(profile.paramNumberOfSubLevels(idSub)) - length(idSub);
         end
      end
      nitrateData = profile.data(:, idNitrateData);
      rmsErrorData = profile.rmsError;
      
      idNoDef = find((presData ~= paramPres.fillValue) & (nitrateData ~= paramNitrate.fillValue));
      if (isempty(idNoDef))
         continue
      end
      [presWoa, idMax] = max(presData(idNoDef) - 100);
      nitratePresWoa = nitrateData(idNoDef(idMax));
      
      getValueFlag = 0;
      rmsError = rmsErrorData(idNoDef(idMax));
      if (rmsError < 0.003)
         if (profile.date ~= g_decArgo_dateDef)
            if (profile.date - a_launchDate <= TWO_MONTH_IN_DAYS)
               getValueFlag = 1;
               nbOffset = nbOffset + 1;
            elseif (nbOffset < NB_OFFSET_MIN)
               getValueFlag = 1;
               nbOffset = nbOffset + 1;
            end
         else
            getValueFlag = -2;
         end
      else
         getValueFlag = -1;
      end
      profInfo = [profInfo; ...
         [idProf profile.outputCycleNumber direction ...
         profile.date profile.locationLon profile.locationLat ...
         presWoa nitratePresWoa paramNitrate.fillValue getValueFlag]];
   end
end

if (~isempty(profInfo))
   
   % retrieve data from World Ocean Atlas 2013
   profInfo = get_WOA_data(profInfo);
   
   if (isempty(profInfo)) % if an error occured during acces to World Ocean Atlas
      return
   end
   
   woaNitrateValues = profInfo(:, 9);
   idNoDef = find(woaNitrateValues ~= paramNitrate.fillValue);
   if (length(idNoDef) >= NB_OFFSET_MIN)
      
      offsetTab = [];
      medOffset = [];
      for idP = 1:size(profInfo, 1)
         profInfoCur = profInfo(idP, :);
         idProf = profInfoCur(1);
         profile = a_tabProfiles(idProf);
         
         % retrieve NITRATE data
         idNitrateParam = find(strcmp({profile.paramList.name}, 'NITRATE'));
         idNitrateData = idNitrateParam;
         if (~isempty(profile.paramNumberWithSubLevels))
            idSub = find(profile.paramNumberWithSubLevels < idNitrateData);
            if (~isempty(idSub))
               idNitrateData = idNitrateData + sum(profile.paramNumberOfSubLevels(idSub)) - length(idSub);
            end
         end
         nitrateData = profile.data(:, idNitrateData);
         
         if (any(nitrateData ~= paramNitrate.fillValue))
            
            if (profInfoCur(10) == -1)
               fprintf('WARNING: Float #%d Cycle #%d%c: RMS error too large - NITRATE data cannot be adjusted\n', ...
                  g_decArgo_floatNum, ...
                  profile.outputCycleNumber, profile.direction);
               continue
            end
            
            if (profInfoCur(10) == -2)
               fprintf('WARNING: Float #%d Cycle #%d%c: the profile is not dated - NITRATE data cannot be adjusted\n', ...
                  g_decArgo_floatNum, ...
                  profile.outputCycleNumber, profile.direction);
               continue
            end
            
            % compute med_Offset
            if (profInfoCur(9) ~= paramNitrate.fillValue)
               offset = profInfoCur(8) - profInfoCur(9);
               offsetTab = [offsetTab offset];
            end
            medOffset = median(offsetTab);
            
            % create array for adjusted data
            if (isempty(profile.dataAdj) || isempty(profile.dataAdjError))
               paramFillValue = get_prof_param_fill_value(profile);
               if (isempty(profile.dataAdj))
                  profile.paramDataMode = repmat(' ', 1, length(profile.paramList));
                  profile.dataAdj = repmat(double(paramFillValue), size(profile.data, 1), 1);
               end
               if (isempty(profile.dataAdjQc))
                  profile.dataAdjQc = ones(size(profile.dataAdj, 1), length(profile.paramList))*g_decArgo_qcDef;
               end
               if (isempty(profile.dataAdjError))
                  profile.dataAdjError = repmat(double(paramFillValue), size(profile.data, 1), 1);
               end
            end
            
            % adjust NITRATE data
            nitrateDataAdj = nitrateData;
            idNoDef = find(nitrateData ~= paramNitrate.fillValue);
            nitrateDataAdj(idNoDef) = nitrateDataAdj(idNoDef) - medOffset;
            
            % store adjusted NITRATE data
            profile.paramDataMode(idNitrateParam) = 'A';
            profile.dataAdj(:, idNitrateData) = nitrateDataAdj;
            profile.dataAdjQc(idNoDef, idNitrateData) = g_decArgo_qcNoQc;
            profile.dataAdjError(idNoDef, idNitrateData) = 5;
            profile.rtParamAdjIdList = [profile.rtParamAdjIdList g_decArgo_paramProfAdjId];
            a_tabProfiles(idProf) = profile;
            
            % fill structure to store NITRATE adjustment information
            if (profile.direction == 'A')
               direction = 2;
            else
               direction = 1;
            end
            nitrateEquation = 'NITRATE_ADJUSTED = NITRATE - OFFSET; OFFSET = med[NITRATE(PRES_WOA)-n_an(PRES_WOA) cumulated over two months after the deployment]';
            if (profInfoCur(10) == 1)
               nitrateCoefficient = sprintf('OFFSET=%g, NITRATE(PRES_WOA)=%g, n_an(PRES_WOA)=%g', medOffset, profInfoCur(8:9));
            else
               nitrateCoefficient = sprintf('OFFSET=%g', medOffset);
            end
            nitrateComment = 'OFFSET is the median of NITRATE(PRES_WOA)-n_an(PRES_WOA) cumulated over two months after the deployment; PRES_WOA=Profile pressure-100; n_an(LATITUDE,LONGITUDE) (closest neighbour) from WOA annual file (ftp://ftp.nodc.noaa.gov/pub/data.nodc/woa/WOA13/DATA)';
            
            % store profile adjustment information for NetCDF file
            g_decArgo_paramProfAdjInfo = [g_decArgo_paramProfAdjInfo;
               g_decArgo_paramProfAdjId profile.outputCycleNumber direction ...
               {'NITRATE'} {nitrateEquation} {nitrateCoefficient} {nitrateComment} {''}];
            g_decArgo_paramProfAdjId = g_decArgo_paramProfAdjId + 1;
            
            if (VERBOSE_MODE)
               fprintf('Float #%d Cycle #%d%c:\n', ...
                  g_decArgo_floatNum, ...
                  profile.outputCycleNumber, profile.direction);
               fprintf('   * (profile_date - launch_date) = (%s - %s) = %g days\n', ...
                  julian_2_gregorian_dec_argo(profile.date), ...
                  julian_2_gregorian_dec_argo(a_launchDate), ...
                  profile.date - a_launchDate);
               if (profInfoCur(10) == 1)
                  fprintf('   * PRES_WOA = %g; float_NITRATE(PRES_WOA) = %g; WOA_NITRATE(PRES_WOA) = %g\n', ...
                     profInfoCur(7:9));
                  fprintf('   * OFFSET = float_NITRATE(PRES_WOA) - WOA_NITRATE(PRES_WOA) = %g\n', ...
                     profInfoCur(8)-profInfoCur(9));
               end
               fprintf('   * TAB_OFFSET = [');
               fprintf(' %g', offsetTab);
               fprintf(' ]\n');
               fprintf('   * MED_OFFSET = median(TAB_OFFSET) = %g\n', medOffset);
            end
         end
      end
   else
      fprintf('WARNING: Float #%d: not enough offset to compute med_offset (%d offsets while at least %d are expected) - NITRATE data cannot be adjusted\n', ...
         g_decArgo_floatNum, ...
         length(idNoDef), NB_OFFSET_MIN);
   end
end

% update output parameters
o_tabProfiles = a_tabProfiles;

return

% ------------------------------------------------------------------------------
% Store trajectory adjustment information for NetCDF file.
%
% SYNTAX :
%  store_traj_adj_info(a_adjType, a_cycleNumber, ...
%    a_paramName, a_equation, a_coefficient, a_comment, a_date)
%
% INPUT PARAMETERS :
%   a_adjType     : adjustement type
%   a_cycleNumber : concerned cycle numbers
%   a_paramName   : adjusted parameter
%   a_equation    : adjustement equation
%   a_coefficient : adjustement coefficients
%   a_comment     : adjustement comment
%   a_date        : adjustment date
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/30/2021 - RNU - creation
% ------------------------------------------------------------------------------
function store_traj_adj_info(a_adjType, a_cycleNumber, ...
   a_paramName, a_equation, a_coefficient, a_comment, a_date)

% to store information on adjustments
global g_decArgo_paramTrajAdjInfo;
global g_decArgo_paramTrajAdjId;


idF = [];
if (~isempty(g_decArgo_paramTrajAdjInfo))
   idF = find(([g_decArgo_paramTrajAdjInfo{:, 2}]' == a_adjType) & ...
      (strcmp(g_decArgo_paramTrajAdjInfo(:, 4), a_paramName)) & ...
      (strcmp(g_decArgo_paramTrajAdjInfo(:, 5), a_equation)) & ...
      (strcmp(g_decArgo_paramTrajAdjInfo(:, 6), a_coefficient)) & ...
      (strcmp(g_decArgo_paramTrajAdjInfo(:, 7), a_comment)) & ...
      (strcmp(g_decArgo_paramTrajAdjInfo(:, 8), a_date)));
end
if (isempty(idF))
   g_decArgo_paramTrajAdjInfo = [g_decArgo_paramTrajAdjInfo;
      g_decArgo_paramTrajAdjId a_adjType a_cycleNumber ...
      {a_paramName} {a_equation} {a_coefficient} {a_comment} {a_date}];
   g_decArgo_paramTrajAdjId = g_decArgo_paramTrajAdjId + 1;
else
   cyNumList = unique([g_decArgo_paramTrajAdjInfo{idF, 3} a_cycleNumber]);
   g_decArgo_paramTrajAdjInfo{idF, 3} = cyNumList;
end

return
