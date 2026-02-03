% ------------------------------------------------------------------------------
% Detect and manage resetoffset commands not performed at the surface (for NKE
% Argos and Iridium historical floats (i.e. not ICE floats)).
%
% SYNTAX :
% [o_tabTrajNMeas, o_tabTrajNCycle, o_tabNcTechIndex, o_tabNcTechVal] = ...
%   manage_erroneous_resetoffset_argos_ir(a_decoderId, ...
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
%   04/16/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabNcTechIndex, o_tabNcTechVal] = ...
   manage_erroneous_resetoffset_argos_ir(a_decoderId, ...
   a_tabProfiles, a_tabTrajNMeas, a_tabTrajNCycle, a_tabNcTechIndex, a_tabNcTechVal)

% output parameters initialization
o_tabProfiles = a_tabProfiles;
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;
o_tabNcTechIndex = a_tabNcTechIndex;
o_tabNcTechVal = a_tabNcTechVal;

% current float WMO number
global g_decArgo_floatNum;

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


% create the list of received cycles
cyNumlist = [a_tabTrajNMeas.outputCycleNumber];
cyNumlist = unique(cyNumlist(cyNumlist >= 0));

% look for missing cycles
if (any(diff(cyNumlist) ~= 1))

   % retrieve techId for
   % PRES_SurfaceOffsetCorrectedNotResetNegative_1dbarResolution_dbar or
   % PRES_SurfaceOffsetCorrectedNotResetNegative_1cBarResolution_dbar
   % information
   switch (a_decoderId)
      case {1, 11, 3, 12, 24, 17, 4, 19, 25, 27, 28, 29, 31}
         offsetTechId = 610;
      case {30, 32}
         offsetTechId = 1213;
      case {201, 202, 203, 215}
         offsetTechId = 124;
      case {204, 205, 206, 207, 208}
         offsetTechId = 130;
      case {210, 211, 213}
         offsetTechId = 127;

      otherwise
         fprintf('ERROR: Float #%d: Cannot retrieve pressure sensor offset techId for decoderId #%d\n', ...
            g_decArgo_floatNum, ...
            a_decoderId);
         return
   end
   % techId of TECH_AUX_PRES_OffsetNotSampledAtSurface_dbar information
   offsetErrTechId = 1010;

   % retrieve the surface pressure offset values available
   idPresOffset = find(([a_tabNcTechIndex(:, 5)] == offsetTechId));
   if (~isempty(idPresOffset))

      surfPresOffsetCyNum = [a_tabNcTechIndex(idPresOffset, 6)];
      surfPresOffsetValue = [a_tabNcTechVal{idPresOffset}];
      [~, idSort] = sort(surfPresOffsetCyNum);
      surfPresOffsetCyNum = surfPresOffsetCyNum(idSort);
      surfPresOffsetValue = surfPresOffsetValue(idSort);

      % find anomalies
      tabErrCyNum = [];
      tabErrOffset = [];
      tabRefOffset = [];

      idMissing = find(diff(cyNumlist) ~= 1);
      for id = idMissing
         cyNum = cyNumlist(id + 1); % cycle following missing cycle(s)
         idPresOffset = find(surfPresOffsetCyNum == cyNum);
         if (~isempty(idPresOffset))
            idCyNumPrev = find(cyNumlist < cyNum, 1, 'last');
            if (~isempty(idCyNumPrev))
               idPresOffsetPrev = find(surfPresOffsetCyNum == cyNumlist(idCyNumPrev));
               if (~isempty(idPresOffsetPrev))
                  % unfortunately 0 is the default value for surface pressure
                  % offset in NKE transmitted packets
                  % i.e. we cannot be sure the resetOffset has been done
                  % or not when the measured pressure offset is 0
                  if (surfPresOffsetValue(idPresOffset) ~= 0)
                     tabErrCyNum = [tabErrCyNum cyNum];
                     tabErrOffset = [tabErrOffset surfPresOffsetValue(idPresOffset)];
                     tabRefOffset = [tabRefOffset surfPresOffsetValue(idPresOffsetPrev)];
                  end
               end
            end
         end
      end

      if (~isempty(tabErrCyNum))

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

            tabCyNum = min(cyNumlist):max(cyNumlist);
            for id = 1:length(tabCyNum)
               transFlag = 0;
               if (any(cyNumlist == tabCyNum(id)))
                  transFlag = 1;
               end
               presOffset = nan;
               if (any(surfPresOffsetCyNum == tabCyNum(id)))
                  presOffset = surfPresOffsetValue(surfPresOffsetCyNum == tabCyNum(id));
               end
               anomaly = 0;
               presOffsetErr = nan;
               presOffsetRef = nan;
               if (any(tabErrCyNum == tabCyNum(id)))
                  anomaly = 1;
                  presOffsetErr = tabErrOffset(tabErrCyNum == tabCyNum(id));
                  presOffsetRef = tabRefOffset(tabErrCyNum == tabCyNum(id));
               end

               fprintf(fId, '%d;%d;%d;%.1f;%d;%.1f;%.1f;%.1f\n', ...
                  g_decArgo_floatNum, ...
                  tabCyNum(id), ...
                  transFlag, ...
                  presOffset, ...
                  anomaly, ...
                  presOffsetErr, ...
                  presOffsetRef, ...
                  presOffsetErr - presOffsetRef);
            end

            fclose(fId);
         end
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

         cycleListStr = sprintf(' %d', tabErrCyNum);
         fprintf('INFO: Float #%d: resetoffset anomaly for cycles:%s\n', ...
            g_decArgo_floatNum, cycleListStr);

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PRESSURE ADJUSTMENT
         % nominal case:
         % 1- the resetoffset is done at the begining of the cycle before diving
         % 2- a surface PRES measurement is performed at the surface
         % (SurfacePresOffset, value < 0 below the surface)
         % 3- until the next resetoffset the float will transmit
         % PRES = CTD_output - SurfacePresOffset
         %
         % in case of sat_mask:
         % an erroneous resetoffset is done while the float is not necessarily
         % at the surface, thus SurfacePresOffset = ErroneousPresOffset
         % transmitted values are PRES = CTD_output - ErroneousPresOffset
         % to be compliant with what is done without resetoffset we should
         % compute PRES_ADJUSTED = CTD_output - LastSurfacePresOffset
         % i.e. PRES_ADJUSTED = (PRES + ErroneousPresOffset) - LastSurfacePresOffset

         % basic adjustment information for NetCDF files
         equation = 'PRES_ADJUSTED = PRES + ErroneousPresOffset - LastSurfacePresOffset';
         comment = 'Resetoffset not done at the surface, remove the erroneous PRES offset value correction (ErroneousPresOffset) and apply the last PRES offset value sampled at the surface (LastSurfacePresOffset).';
         currentDate = datestr(now_utc, 'yyyymmddHHMMSS');

         for idCor = 1:length(tabErrCyNum)
            cyNum = tabErrCyNum(idCor);
            presOffsetCor = tabErrOffset(idCor) - tabRefOffset(idCor);
            coefficient = sprintf('ErroneousPresOffset = %g, LastSurfacePresOffset = %g', tabErrOffset(idCor), tabRefOffset(idCor));
            trajCoefficient = ['For cycle ' num2str(cyNum) ' : ' coefficient];

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % update TECH data

            % move PRES_SurfaceOffsetCorrectedNotResetNegative_1dbarResolution_dbar or
            % PRES_SurfaceOffsetCorrectedNotResetNegative_1cBarResolution_dbar
            % to TECH_AUX_PRES_OffsetNotSampledAtSurface_dbar
            idF = find(([o_tabNcTechIndex(:, 6)] == cyNum) & ([o_tabNcTechIndex(:, 5)] == offsetTechId));
            if (~isempty(idF))
               o_tabNcTechIndex(idF, 5) = offsetErrTechId;
            end
         end
      end
   end
end

return
