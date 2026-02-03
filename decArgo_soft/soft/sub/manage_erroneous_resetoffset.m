% ------------------------------------------------------------------------------
% Detect and manage resetoffset commands not performed at the surface.
%
% SYNTAX :
% [o_tabTrajNMeas, o_tabTrajNCycle, o_tabNcTechIndex, o_tabNcTechVal] = ...
%   manage_erroneous_resetoffset(a_decoderId, ...
%   a_tabTrajNMeas, a_tabTrajNCycle, a_tabNcTechIndex, a_tabNcTechVal)
%
% INPUT PARAMETERS :
%   a_decoderId      : float decoder Id
%   a_tabProfiles    : input decoded profiles
%   a_tabTrajNMeas   : input trajectory N_MEASUREMENT data
%   a_tabTrajNCycle  : input trajectory N_CYCLE data
%   a_tabNcTechIndex : input technical index information
%   a_tabNcTechVal   : input technical data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles    : output decoded profiles
%   o_tabTrajNMeas   : output trajectory N_MEASUREMENT data
%   o_tabTrajNCycle  : output trajectory N_CYCLE data
%   o_tabNcTechIndex : output technical index information
%   o_tabNcTechVal   : output technical data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/13/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabNcTechIndex, o_tabNcTechVal] = ...
   manage_erroneous_resetoffset(a_decoderId, ...
   a_tabProfiles, a_tabTrajNMeas, a_tabTrajNCycle, a_tabNcTechIndex, a_tabNcTechVal)

% output parameters initialization
o_tabProfiles = a_tabProfiles;
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;
o_tabNcTechIndex = a_tabNcTechIndex;
o_tabNcTechVal = a_tabNcTechVal;

% current float WMO number
global g_decArgo_floatNum;

% to store information for resetoffset check
global g_decArgo_resetOffsetData;

% QC flag values (numerical)
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;

% to store information on adjustments
global g_decArgo_paramProfAdjInfo;
global g_decArgo_paramProfAdjId;

% TRAJ 3.2 file generation flag
global g_decArgo_generateNcTraj32;

% configuration values
global g_decArgo_dirOutputCsvFile;


if (isempty(g_decArgo_resetOffsetData))
   return
end

tabCyNum = g_decArgo_resetOffsetData.cyNum;
tabTransFlag = g_decArgo_resetOffsetData.transFlag;

if (all(tabTransFlag == 1))
   return
end

% retrieve techId for
% PRES_SurfaceOffsetCorrectedNotResetNegative_1cBarResolution_dbar information
switch (a_decoderId)
   case {212, 214, 217, 222, 223, 224, 225, 226, 227, 231, 232}
      offsetTechId = 127;
   case {216, 218, 221, 228, 229, 230}
      offsetTechId = 124;
   otherwise
      fprintf('ERROR: Float #%d: Cannot retrieve pressure sensor offset techId for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
      return
end
% techId of TECH_AUX_PRES_OffsetNotSampledAtSurface_dbar information
offsetErrTechId = 409;

% retrieve pressure sensor offset
tabPresOffset = nan(size(tabCyNum));
for idCy = 1:length(tabCyNum)
   idF = find(([a_tabNcTechIndex(:, 6)] == tabCyNum(idCy)) & ...
      ([a_tabNcTechIndex(:, 5)] == offsetTechId));
   if (~isempty(idF))
      tabPresOffset(idCy) = o_tabNcTechVal{idF};
   end
end

% find anomalies
% if tabTransFlag(N) == 0 => the resetoffset is not supposed to be performed
% => tabPresOffset(N+1) should be Nan
tabAnomaly = zeros(size(tabCyNum));
for idCy = 1:length(tabCyNum)
   if (~isnan(tabPresOffset(idCy)))
      idF = find(tabCyNum == tabCyNum(idCy) - 1) ;
      if (~isempty(idF))
         if (tabTransFlag(idF) == 0)
            tabAnomaly(idCy) = 1;
         end
      end
   end
end

if (all(tabAnomaly == 0))
   return
end

id = find(tabAnomaly == 1);
if (~isempty(id))
   cycleListStr = sprintf(' %d', tabCyNum(id));
   fprintf('INFO: Float #%d: resetoffset anomaly for cycles:%s\n', ...
      g_decArgo_floatNum, cycleListStr);
end

% manage anomalies
tabPresOffsetCor = nan(size(tabCyNum));
tabRefOffset = nan(size(tabCyNum));
tabErrOffset = nan(size(tabCyNum));
lastRefOffset = nan;
lastErrOffset = nan;
for id = 1:length(tabCyNum)
   if (id == 1)
      if (~isnan(tabPresOffset(id)))
         tabRefOffset(id) = tabPresOffset(id);
         lastRefOffset = id;
      end
   else
      if (tabCyNum(id-1) == tabCyNum(id) - 1)
         if (~isnan(tabPresOffset(id)) && (tabTransFlag(id-1) == 1))
            tabRefOffset(id) = tabPresOffset(id);
            lastRefOffset = id;
         else
            if (~isnan(lastRefOffset))
               tabRefOffset(id) = tabRefOffset(lastRefOffset);
            end
         end
         if (~isnan(tabPresOffset(id)) && (tabTransFlag(id-1) == 0))
            tabErrOffset(id) = tabPresOffset(id);
            lastErrOffset = id;
         else
            if (lastErrOffset > lastRefOffset)
               tabErrOffset(id) = tabErrOffset(lastErrOffset);
            end
         end
         if (~isnan(tabErrOffset(id)))
            tabPresOffsetCor(id) = tabRefOffset(id) - tabErrOffset(id);
         end
      end
   end
end

% output to check resetoffset corrections
if (0)

   % create output CSV file
   csvFilepathName = [g_decArgo_dirOutputCsvFile '\' num2str(g_decArgo_floatNum) '_resetOffset_anomalies_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
   fId = fopen(csvFilepathName, 'wt');
   if (fId == -1)
      fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
      return
   end
   header = [ ...
      'WMO;Cycle#;Transmission Flag;Surface PRES offset;Anomaly Flag;' ...
      'Erroneous PRES Offset;Last Surface PRES Offset;PRES correction applied by Coriolis decoder = (Erroneous PRES Offset) - (Last Surface PRES Offset)'];
   fprintf(fId, '%s\n', header);

   for id = 1:length(tabCyNum)
      fprintf(fId, '%d;%d;%d;%.1f;%d;%.1f;%.1f;%.1f\n', ...
         g_decArgo_floatNum, ...
         tabCyNum(id), ...
         tabTransFlag(id), ...
         tabPresOffset(id), ...
         tabAnomaly(id), ...
         tabErrOffset(id), ...
         tabRefOffset(id), ...
         tabErrOffset(id)-tabRefOffset(id));
   end

   fclose(fId);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRESSURE ADJUSTMENT
% nominal case:
% 1- the resetoffset is done at the begining of the cycle before diving
% 2- a surface PRES measurement is performed at the surface (SurfacePresOffset, value < 0 below the surface)
% 3- until the next resetoffset the float will transmit PRES = CTD_output - SurfacePresOffset
%
% in case of aborted profile:
% the restoffset is not done, thus SurfacePresOffset = LastSurfacePresOffset and
% the float transmits PRES = CTD_output - LastSurfacePresOffset
%
% in case of sat_mask:
% an erroneous resetoffset is done while the float is not necessarily at the
% surface, thus SurfacePresOffset = ErroneousPresOffset
% transmitted values are PRES = CTD_output - ErroneousPresOffset
% to be compliant with what is done in case of aborted profile we should compute
% PRES_ADJUSTED = CTD_output - LastSurfacePresOffset
% i.e. PRES_ADJUSTED = (PRES + ErroneousPresOffset) - LastSurfacePresOffset

% basic adjustment information for NetCDF files
equation = 'PRES_ADJUSTED = PRES + ErroneousPresOffset - LastSurfacePresOffset';
comment = 'Resetoffset not done at the surface, remove the erroneous PRES offset value correction (ErroneousPresOffset) and apply the last PRES offset value sampled at the surface (LastSurfacePresOffset).';
currentDate = datestr(now_utc, 'yyyymmddHHMMSS');

idCorList = find(~isnan(tabPresOffsetCor));
for id = idCorList
   cyNum = tabCyNum(id);
   presOffsetCor = tabPresOffsetCor(id);
   coefficient = sprintf('ErroneousPresOffset = %g, LastSurfacePresOffset = %g', tabErrOffset(id), tabRefOffset(id));
   idSameCor = find((tabRefOffset == tabRefOffset(id)) & (tabErrOffset == tabErrOffset(id)));
   sameCorCyNumList = tabCyNum(idSameCor);
   if (length(unique(sameCorCyNumList)) == 1)
      trajCoefficient = ['For cycle ' squeeze_cycle_num_list_for_ascii_output(sameCorCyNumList) ' : ' coefficient];
   else
      trajCoefficient = ['For cycles ' squeeze_cycle_num_list_for_ascii_output(sameCorCyNumList) ' : ' coefficient];
   end
   % fprintf('INFO: Float #%d: %s\n', ...
   %    g_decArgo_floatNum, trajCoefficient);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % adjust profile data

   idProfList = find([o_tabProfiles.outputCycleNumber] == cyNum);
   for idP = idProfList
      profile = o_tabProfiles(idP);

      % adjust PRES values
      idPres = find(strcmp({profile.paramList.name}, 'PRES'));
      presFillValue = profile.paramList(idPres).fillValue;
      presValues = profile.data(:, idPres);
      idNoDef = find((presValues ~= presFillValue));
      presAdjValues = presValues(idNoDef) + presOffsetCor;

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
      profile.paramDataMode(idPres) = 'A';
      profile.dataAdj(idNoDef, idPres) = presAdjValues;

      profile.dataAdjQc(idNoDef, idPres) = g_decArgo_qcNoQc;

      profile.rtParamAdjIdList = [profile.rtParamAdjIdList g_decArgo_paramProfAdjId];
      o_tabProfiles(idP) = profile;

      % store profile adjustment information for NetCDF file
      if (profile.direction == 'A')
         direction = 2;
      else
         direction = 1;
      end

      g_decArgo_paramProfAdjInfo = [g_decArgo_paramProfAdjInfo;
         g_decArgo_paramProfAdjId profile.outputCycleNumber direction ...
         {'PRES'} {equation} {coefficient} {comment} {''}];
      g_decArgo_paramProfAdjId = g_decArgo_paramProfAdjId + 1;
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % adjust trajectory data

   if (g_decArgo_generateNcTraj32 ~= 0)

      adjFlag = 0;
      idNMeasList = find([o_tabTrajNMeas.outputCycleNumber] == cyNum);
      for idNMeas = idNMeasList
         nMeas = o_tabTrajNMeas(idNMeas);

         for idMeas = 1:length(nMeas.tabMeas)

            tabMeas = nMeas.tabMeas(idMeas);
            if (~isempty(tabMeas.paramList) && ...
                  any(strcmp({tabMeas.paramList.name}, 'PRES')))

               % adjust PRES values
               idPres = find(strcmp({tabMeas.paramList.name}, 'PRES'));
               presFillValue = tabMeas.paramList(idPres).fillValue;
               presValues = tabMeas.paramData(:, idPres);
               idNoDef = find((presValues ~= presFillValue));
               presAdjValues = presValues(idNoDef) + presOffsetCor;
               if (tabMeas.paramList(idPres).resolution == 1)
                  presAdjValues = round(presAdjValues);
               end

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
               tabMeas.paramDataMode(idPres) = 'A';
               tabMeas.paramDataAdj(idNoDef, idPres) = presAdjValues;

               tabMeas.paramDataAdjQc(idNoDef, idPres) = g_decArgo_qcNoQc;

               nMeas.tabMeas(idMeas) = tabMeas;
               adjFlag = 1;

               % store trajectory adjustment information for NetCDF file
               store_traj_adj_info(2, o_tabTrajNMeas(idNMeas).outputCycleNumber, ...
                  'PRES', equation, trajCoefficient, comment, currentDate);
            end
         end
         o_tabTrajNMeas(idNMeas) = nMeas;
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

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % update TECH data

   % move PRES_SurfaceOffsetCorrectedNotResetNegative_1cBarResolution_dbar
   % to TECH_AUX_PRES_OffsetNotSampledAtSurface_dbar
   idF = find(([o_tabNcTechIndex(:, 6)] == cyNum) & ([o_tabNcTechIndex(:, 5)] == offsetTechId));
   if (~isempty(idF))
      o_tabNcTechIndex(idF, 5) = offsetErrTechId;
   end
   % remove the surface version of the
   % PRES_SurfaceOffsetCorrectedNotResetNegative_1cBarResolution_dbar parameter
   idF = find(([o_tabNcTechIndex(:, 6)] == cyNum) & ([o_tabNcTechIndex(:, 5)] == 10000 + offsetTechId));
   if (~isempty(idF))
      o_tabNcTechIndex(idF, :) = [];
      o_tabNcTechVal(idF) = [];
   end

end

return

% ------------------------------------------------------------------------------
% Create a squeezed string version of a given cycle number list.
%
% SYNTAX :
% [o_cyNumListStr] = squeeze_cycle_num_list_for_ascii_output(a_cyNumList)
%
% INPUT PARAMETERS :
%   a_cyNumList : input cycle number list
%
% OUTPUT PARAMETERS :
%   o_cyNumListStr : output char suqeezed version of the cycle number list
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/13/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cyNumListStr] = squeeze_cycle_num_list_for_ascii_output(a_cyNumList)

% output parameters initialization
o_cyNumListStr = '';

if (isempty(a_cyNumList))
   return
end

cyNumList = unique(a_cyNumList);
idSet = find(diff(cyNumList) > 1);
idStart = 1;
o_cyNumListStr = '';
for id = 1:length(idSet)+1
   if (id <= length(idSet))
      idStop = idSet(id);
   else
      idStop = length(cyNumList);
   end
   if (length(cyNumList(idStart:idStop)) == 1)
      o_cyNumListStr = [o_cyNumListStr sprintf('%d, ', cyNumList(idStart:idStop))];
   else
      o_cyNumListStr = [o_cyNumListStr sprintf('%d to %d, ', cyNumList(idStart), cyNumList(idStop))];
   end
   idStart = idStop + 1;
end
if (~isempty(o_cyNumListStr))
   o_cyNumListStr(end-1:end) = [];
end

return