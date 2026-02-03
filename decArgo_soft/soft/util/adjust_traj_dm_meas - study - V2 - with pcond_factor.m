% ------------------------------------------------------------------------------
% Adjust parameter measurement values in a DM trajectory file.
% V2: adjustments with pcond_factor determination - many outputs - no update of TRAJ file.
%
% SYNTAX :
%   adjust_traj_dm_meas(6902899)
%
% INPUT PARAMETERS :
%   varargin : WMO number of float to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/12/2024 - RNU - creation
% ------------------------------------------------------------------------------
function adjust_traj_dm_meas(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START

% default list of floats to process
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TRAJ_DM\arvor_in_andro.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TRAJ_DM\arvor_in_andro_psal_adj.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TRAJ_DM\arvor_in_andro_psal_adj_with_pcond_factor_in_eq.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TRAJ_DM\cts3_in_andro_all.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TRAJ_DM\cts3_in_andro.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TRAJ_DM\arvor_deep_in_andro_all.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_tmp.txt';

% top directory of the NetCDF files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\TRAJ_DM_2024\snapshot-202401_nke_in_andro\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the csv file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\run\';

% CONFIGURATION - END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% list of profile cycle numbers used with PSAL adj with not null value
global g_decArgo_profCyNumList;

% list of MC with PSAL measurement
global g_decArgo_psalMeasCodeList;
g_decArgo_psalMeasCodeList = [];

% measurement codes initialization
init_measurement_codes;

% default values initialization
init_default_values;


% check inputs
if (nargin == 0)
   if ~(exist(FLOAT_LIST_FILE_NAME, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', FLOAT_LIST_FILE_NAME);
      return
   end
end
if ~(exist(DIR_INPUT_NC_FILES, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s\n', DIR_INPUT_NC_FILES);
   return
end

% get floats to process
if (nargin == 0)
   % floats to process come from default list
   fprintf('Floats from list: %s\n', FLOAT_LIST_FILE_NAME);
   floatList = load(FLOAT_LIST_FILE_NAME);
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create and start log file recording
if (nargin == 0)
   [~, name, ~] = fileparts(FLOAT_LIST_FILE_NAME);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

% create log directory
if ~(exist(DIR_LOG_FILE, 'dir') == 7)
   mkdir(DIR_LOG_FILE);
end

logFile = [DIR_LOG_FILE '/' 'adjust_traj_dm_meas' name '_' currentTime '.log'];
diary(logFile);
tic;

% create output CSV file
csvFilepathName = [DIR_CSV_FILE '\adjust_traj_dm_meas' name '_' currentTime '.csv'];
fId = fopen(csvFilepathName, 'wt');
if (fId == -1)
   fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
   return
end
header = ['WMO;Cy D-PROF;Cy TRAJ;Meas code;' ...
   'Nb PSAL;Nb PSAL adj not Nan;Nb PSAL adj Nan;Nb PSAL adj with 0;Nb PSAL adj with <> 0;' ...
   'Max diff pcond_factor;Max diff PSAL_ADJUSTED;Max diff with Eq;Max diff with Comp;Comp better;Cy PSAL_ADJUSTED_QC=4'];
fprintf(fId, '%s\n', header);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process floats of the list

nbFloats = length(floatList);
nbAdjNotNull = 0;
nbAdjCompBetter = 0;
for idFloat = 1:nbFloats

   g_decArgo_profCyNumList =[];

   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % retrieve float data from NetCDF files

   [dmCProfileData, cParamList, dmBProfileData, bParamList] = ...
      get_profile_dm_data(floatNum, [DIR_INPUT_NC_FILES '/' floatNumStr]);
   if (isempty(dmCProfileData) && isempty(dmBProfileData))
      continue
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % concat primary and NS profiles and copy PRES data from core to BGC profiles

   [dmCProfileData, dmBProfileData] = concat_profile(floatNum, dmCProfileData, dmBProfileData);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % adjust traj data

   trajDataAdj = adjust_traj_data(floatNum, [DIR_INPUT_NC_FILES '/' floatNumStr], dmCProfileData, cParamList, dmBProfileData, bParamList);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % report results in CSV file
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % global summary
   adjCoreCyNumListStr = '';
   if (~isempty(dmCProfileData))
      adjCoreCyNumListStr = squeeze_list(unique([dmCProfileData{:, 1}]));
   end
   adjTrajCyNumListStr = '';
   if (~isempty(trajDataAdj))
      trajCyNumList = unique([trajDataAdj.cycleNumber]);
      adjTrajCyNumListStr = squeeze_list(trajCyNumList);
   end

   mcList = unique([trajDataAdj.measCode], 'stable');
   for measCode = mcList'
      nbPsal = 0; % nombre total de mesures PSAL ajustées
      nbPsalAdjNoNan = 0; % nombre de mesures PSAL ajustées à ~FV
      nbPsalAdjNan = 0; % nombre de mesures PSAL ajustées à FV
      nbPsalAdjNull = 0; % nombre de mesures PSAL ajustées avec 0
      nbPsalAdjEq = 0; % nombre de mesures PSAL ajustées avec pcond_factor de l'équation
      nbPsalAdjComp = 0; % nombre de mesures PSAL ajustées avec pcond_factor calculé
      allNanCyNumList = []; % liste des cycles avec données ajustées à FV
      pcondFactorEq = [];
      pcondFactorComp = [];
      psalAdjEq = [];
      psalAdjComp = [];
      profPsalAdj = [];
      profPsalAdjEq = [];
      profPsalAdjComp = [];

      idForMc = find([trajDataAdj.measCode] == measCode);
      for idL = idForMc
         % if (idL == 59)
         %    a=1
         % end
         traj = trajDataAdj(idL);
         idPsal = find(strcmp(traj.paramList, 'PSAL'));
         if (~isempty(idPsal))
            nbPsal = nbPsal + sum(~isnan(traj.data(:, idPsal)));
            nbPsalAdjNoNan = nbPsalAdjNoNan + sum(~isnan(traj.dataAdjEq(:, idPsal)));
            nbPsalAdjNan = nbPsalAdjNan + sum(isnan(traj.dataAdjEq(:, idPsal)));
            if (traj.paramAdjNull(idPsal) == 1)
               nbPsalAdjNull = nbPsalAdjNull + sum(~isnan(traj.dataAdjEq(:, idPsal)));
            elseif (traj.paramAdjNull(idPsal) == 0)
               nbPsalAdjEq = nbPsalAdjEq + sum(~isnan(traj.dataAdjEq(:, idPsal)));
               nbPsalAdjComp = nbPsalAdjComp + sum(~isnan(traj.dataAdjComp(:, idPsal)));
               if (~isempty(traj.pcondFactorEq) && ~isempty(traj.pcondFactorComp))
                  idNoDef = find(~isnan(traj.dataAdjEq(:, idPsal)) & ~isnan(traj.dataAdjComp(:, idPsal)));
                  pcondFactorEq = cat(1, pcondFactorEq, traj.pcondFactorEq(idNoDef));
                  psalAdjEq = cat(1, psalAdjEq, traj.dataAdjEq(idNoDef, idPsal));
                  pcondFactorComp = cat(1, pcondFactorComp, traj.pcondFactorComp(idNoDef));
                  psalAdjComp = cat(1, psalAdjComp, traj.dataAdjComp(idNoDef, idPsal));

                  if (traj.profCur.psalAdjNullFlag == 0)
                     idPsal2 = find(strcmp(traj.profCur.paramList, 'PSAL'));
                     psalAdjProf = traj.profCur.dataAdj(:, idPsal2);
                     psalAdjEqProf = traj.profCur.psalAdjEq;
                     psalAdjCompProf = traj.profCur.psalAdjComp;
                     idNoDef = find(~isnan(psalAdjProf) & ~isnan(psalAdjEqProf) & ~isnan(psalAdjCompProf));
                     profPsalAdj = cat(1, profPsalAdj, psalAdjProf(idNoDef));
                     profPsalAdjEq = cat(1, profPsalAdjEq, psalAdjEqProf(idNoDef));
                     profPsalAdjComp = cat(1, profPsalAdjComp, psalAdjCompProf(idNoDef));
                  end
               end
            else
               fprintf('ANOMALY\n');
            end
            if (all(isnan(traj.dataAdjEq(:, idPsal))))
               allNanCyNumList = cat(2, allNanCyNumList, traj.cycleNumber);
            end
         end
      end

      allNanCyNumListStr = '';
      if (~isempty(allNanCyNumList))
         allNanCyNumListStr = squeeze_list(unique(allNanCyNumList));
      end

      fprintf(fId, '%d;%s;%s;%s;%d;%d;%d;%d;%d;%e;%e;%e;%e;%d;%s\n', ...
         floatNum, adjCoreCyNumListStr, adjTrajCyNumListStr, get_meas_code_name(measCode), ...
         nbPsal, nbPsalAdjNoNan, nbPsalAdjNan, nbPsalAdjNull, nbPsalAdjEq, ...
         max(abs(pcondFactorEq-pcondFactorComp)), max(abs(psalAdjEq-psalAdjComp)), ...
         max(abs(profPsalAdj-profPsalAdjEq)), max(abs(profPsalAdj-profPsalAdjComp)), ...
         (max(abs(profPsalAdj-profPsalAdjEq)) > max(abs(profPsalAdj-profPsalAdjComp))), ...
         allNanCyNumListStr);
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % used PROF data

   % create output CSV file to report PROF adjustments
   csvFilepathName = [DIR_CSV_FILE '\adjusted_prof_dm_meas_' floatNumStr '_' currentTime '.csv'];
   fId2 = fopen(csvFilepathName, 'wt');
   if (fId2 == -1)
      fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
      return
   end
   header = ['WMO;CYCLE_NUMBER;DIRECTION;PRES;TEMP;PSAL;PSAL_ADJUSTED;' ...
      'pcond_fact Eq;PSAL_ADJUSTED Eq;abs(PSAL_ADJUSTED-PSAL_ADJUSTED Eq);' ...
      'pcond_fact Comp;PSAL_ADJUSTED Comp;abs(PSAL_ADJUSTED-PSAL_ADJUSTED Comp);' ...
      'Comp better;' ...
      'abs(pcond_fact Eq-pcond_fact Comp);abs(PSAL_ADJUSTED Eq-PSAL_ADJUSTED Comp);PSAL SCIENTIFIC_CALIB_COEFFICIENT'];
   fprintf(fId2, '%s\n', header);

   profCyNumList = unique(g_decArgo_profCyNumList);
   for cyNum = profCyNumList
      idF = find(([dmCProfileData{:, 1}] == cyNum) & ([dmCProfileData{:, 2}] == 2));
      prof = dmCProfileData{idF, 3};

      if (prof.psalAdjNullFlag == 0)

         idPres = find(strcmp('PRES', prof.paramList));
         idTemp = find(strcmp('TEMP', prof.paramList));
         idPsal = find(strcmp('PSAL', prof.paramList));

         profDir = 'A';
         if (prof.direction == 1)
            profDir = 'D';
         end

         for idL = 1:size(prof.data, 1)
            fprintf(fId2, '%d;%d;%c;%.3f;%.4f;%.4f;%.4f;%.5f;%.4f;%e;%f;%.4f;%e;%d;%e;%e;%s\n', ...
               floatNum, prof.cycleNumber, profDir, ...
               prof.data(idL, idPres), prof.data(idL, idTemp), prof.data(idL, idPsal), prof.dataAdj(idL, idPsal), ...
               prof.pcondFactorEq, prof.psalAdjEq(idL), abs(prof.psalAdjEq(idL)-prof.dataAdj(idL, idPsal)), ...
               prof.pcondFactorComp, prof.psalAdjComp(idL), abs(prof.psalAdjComp(idL)-prof.dataAdj(idL, idPsal)), ...
               (abs(prof.psalAdjEq(idL)-prof.dataAdj(idL, idPsal)) >= abs(prof.psalAdjComp(idL)-prof.dataAdj(idL, idPsal))), ...
               abs(prof.pcondFactorEq-prof.pcondFactorComp), abs(prof.psalAdjComp(idL)-prof.psalAdjEq(idL)), ...
               prof.sciCalCoef{idPsal}{:});
            nbAdjCompBetter = nbAdjCompBetter + (abs(prof.psalAdjEq(idL)-prof.dataAdj(idL, idPsal)) >= abs(prof.psalAdjComp(idL)-prof.dataAdj(idL, idPsal)));
         end
         nbAdjNotNull = nbAdjNotNull + size(prof.data, 1);
      end
   end

   fclose(fId2);
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % adjusted TRAJ data

   % create output CSV file to report TRAJ adjustments
   csvFilepathName = [DIR_CSV_FILE '\check_traj_adj_param_meas_' floatNumStr '_' currentTime '.csv'];
   fId3 = fopen(csvFilepathName, 'wt');
   if (fId3 == -1)
      fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
      return
   end
   header = [ ...
      'WMO;CYCLE_NUMBER;MC;Meas#;' ...
      'Prev Prof JulD;Prev Prof pcond_fact Eq;Prev Prof pcond_fact Comp;' ...
      'Cur Prof JulD;Cur Prof pcond_fact Eq;Cur Prof pcond_fact Comp;' ...
      'Meas Juld;pcond_fact Eq;Meas PSAL_ADJUSTED Eq;pcond_fact Comp;Meas PSAL_ADJUSTED Comp;' ...
      'abs(pcond_fact Eq-pcond_fact Comp);abs(PSAL_ADJUSTED Eq-PSAL_ADJUSTED Comp)'];
   fprintf(fId3, '%s\n', header);

   trajCyNumList = unique([trajDataAdj.cycleNumber]);
   for cyNum = trajCyNumList
      % if (cyNum == 95)
      %    a=1
      % end
      mcList = unique([trajDataAdj.measCode], 'stable');
      for measCode = mcList'
         idForMc = find(([trajDataAdj.cycleNumber] == cyNum) & ([trajDataAdj.measCode] == measCode));
         for idT = idForMc
            traj = trajDataAdj(idT);

            idPsal = find(strcmp('PSAL', traj.paramList));

            if ((traj.paramAdjNull(idPsal) == 0) && ~isempty(traj.pcondFactorEq))

               for idM = 1:size(traj.data, 1)

                  fprintf(fId3, '%d;%d;%s;%d;''%s;%.5f;%f;''%s;%.5f;%f;''%s;%.5f;%.4f;%f;%.4f;%e;%e\n', ...
                     floatNum, traj.cycleNumber, get_meas_code_name(traj.measCode), idM, ...
                     julian_2_gregorian_dec_argo(traj.profPrev.juld), ...
                     traj.profPrev.pcondFactorEq, traj.profPrev.pcondFactorComp, ...
                     julian_2_gregorian_dec_argo(traj.profCur.juld), ...
                     traj.profCur.pcondFactorEq, traj.profCur.pcondFactorComp, ...
                     julian_2_gregorian_dec_argo(traj.dataJuld(idM)), ...
                     traj.pcondFactorEq(idM), traj.dataAdjEq(idM, idPsal), ...
                     traj.pcondFactorComp(idM), traj.dataAdjComp(idM, idPsal), ...
                     abs(traj.pcondFactorEq(idM)-traj.pcondFactorComp(idM)), ...
                     abs(traj.dataAdjEq(idM, idPsal)-traj.dataAdjComp(idM, idPsal)));
               end
            end
         end
      end
   end

   fclose(fId3);
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fclose(fId);

fprintf('List of MC with PSAL measurement:\n');
for mc = g_decArgo_psalMeasCodeList'
   fprintf(' - %s\n', get_meas_code_name(mc));
end

fprintf('PSAL adjustment with computed pcond_factor is better in : %.f %% (%d/%d)\n', ...
   nbAdjCompBetter*100/nbAdjNotNull, nbAdjCompBetter, nbAdjNotNull);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Adjust trajectory measurements with profile DM data.
%
% SYNTAX :
% [o_trajDataAdj] = adjust_traj_data(a_floatNum, a_ncFileDir, ...
%   a_dmCProfileData, a_cParamList, a_dmBProfileData, a_bParamList)
%
% INPUT PARAMETERS :
%   a_floatNum       : float WMO number
%   a_ncFileDir      : float nc files directory
%   a_dmCProfileData : DM core profile data
%   a_cParamList     : list of core parameter names
%   a_dmBProfileData : DM BGC profile data
%   a_bParamList     : list of BGC parameter names
%
% OUTPUT PARAMETERS :
%   o_trajCNumList : list of adjusted cycles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/12/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_trajDataAdj] = adjust_traj_data(a_floatNum, a_ncFileDir, ...
   a_dmCProfileData, a_cParamList, a_dmBProfileData, a_bParamList)

% output parameters initialization
o_trajDataAdj = [];

% global measurement codes
global g_MC_DriftAtPark;

% list of MC with PSAL measurement
global g_decArgo_psalMeasCodeList;


juldInfo = get_netcdf_param_attributes('JULD');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% retrieve data from trajectory file

trajFile = dir([a_ncFileDir '/' sprintf('%d_Rtraj.nc', a_floatNum)]);
if (isempty(trajFile))
   fprintf('INFO: No trajectory file for float %d - ignored\n', ...
      a_floatNum);
   return
end
trajFileName = trajFile(1).name;
trajFilePathName = [a_ncFileDir '/' trajFileName];

wantedVars = [ ...
   {'TRAJECTORY_PARAMETERS'} ...
   {'CYCLE_NUMBER_INDEX'} ...
   {'DATA_MODE'} ...
   {'JULD'} ...
   {'JULD_QC'} ...
   {'JULD_ADJUSTED'} ...
   {'JULD_ADJUSTED_QC'} ...
   {'LATITUDE'} ...
   {'LONGITUDE'} ...
   {'POSITION_ACCURACY'} ...
   {'POSITION_QC'} ...
   {'CYCLE_NUMBER'} ...
   {'MEASUREMENT_CODE'} ...
   {'JULD_DATA_MODE'} ...
   {'TRAJECTORY_PARAMETER_DATA_MODE'} ...
   ];
for idParam = 1:length(a_cParamList)
   paramName = a_cParamList{idParam};
   wantedVars = [wantedVars ...
      {paramName} {[paramName '_QC']} ...
      {[paramName '_ADJUSTED']} {[paramName '_ADJUSTED_QC']} ...
      ];
end
for idParam = 1:length(a_bParamList)
   paramName = a_bParamList{idParam};
   wantedVars = [wantedVars ...
      {paramName} {[paramName '_QC']} ...
      {[paramName '_ADJUSTED']} {[paramName '_ADJUSTED_QC']} ...
      ];
end

ncTrajData = get_data_from_nc_file(trajFilePathName, wantedVars);

trajectoryParameters = get_data_from_name('TRAJECTORY_PARAMETERS', ncTrajData);
cycleNumberIndex = get_data_from_name('CYCLE_NUMBER_INDEX', ncTrajData);
dataMode = get_data_from_name('DATA_MODE', ncTrajData);
juld = get_data_from_name('JULD', ncTrajData);
juldQc = get_data_from_name('JULD_QC', ncTrajData);
juldAdj = get_data_from_name('JULD_ADJUSTED', ncTrajData);
juldAdjQc = get_data_from_name('JULD_ADJUSTED_QC', ncTrajData);
latitude = get_data_from_name('LATITUDE', ncTrajData);
longitude = get_data_from_name('LONGITUDE', ncTrajData);
positionAccuracy = get_data_from_name('POSITION_ACCURACY', ncTrajData);
positionQc = get_data_from_name('POSITION_QC', ncTrajData);
cycleNumber = get_data_from_name('CYCLE_NUMBER', ncTrajData);
measurementCode = get_data_from_name('MEASUREMENT_CODE', ncTrajData);
juldDataMode = get_data_from_name('JULD_DATA_MODE', ncTrajData);
trajectoryParameterDataMode = get_data_from_name('TRAJECTORY_PARAMETER_DATA_MODE', ncTrajData);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute information to adjust traj data

% one loop for each set of profile data (core and BGC)
trajDataAdjAll = [];
for idLoop = 1:2
   if (idLoop == 1)
      dmProfileData = a_dmCProfileData;
   else
      if (isempty(a_dmBProfileData))
         continue
      end
      dmProfileData = a_dmBProfileData;
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % link TRAJ and PROF cycle numbers

   juldBest = juldAdj;
   juldBest(juldDataMode == 'R') = juld(juldDataMode == 'R');
   for idL = 1:size(dmProfileData, 1)
      profCyNum = dmProfileData{idL, 1};
      prof = dmProfileData{idL, 3};

      [minDiff, idMin] = min(abs(juldBest-prof.juld));
      if (minDiff ~= 0)
         fprintf('ERROR: Anomaly (PROF JulD not exactly in TRAJ, %f hours)\n', minDiff*24);
      end
      dmProfileData{idL, 4} = cycleNumber(idMin);
      if (profCyNum ~= cycleNumber(idMin))
         fprintf('ERROR: Anomaly (PROF JulD not exactly in TRAJ, %f hours)\n', minDiff*24);
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % process TRAJ cycle numbers

   trajCyNumList = unique([dmProfileData{:, 4}]);
   for cyNum = trajCyNumList

      idPrev = '';
      idCur = find([dmProfileData{:, 4}] == cyNum);
      if (cyNum > 1)
         idPrev = find([dmProfileData{:, 4}] == cyNum-1);
      end
      if (~isempty(idPrev))
         profPrev = dmProfileData{idPrev, 3};
         profCur = dmProfileData{idCur, 3};

         paramList = intersect(profPrev.paramList, profCur.paramList, 'stable');

         for idParam = 1:length(paramList)
            paramName = paramList{idParam};
            if ((idLoop == 2) && strcmp(paramName, 'PRES'))
               continue
            end

            trajParamData = get_data_from_name(paramName, ncTrajData);
            if (isempty(trajParamData))
               continue
            end

            paramInfo = get_netcdf_param_attributes(paramName);
            idNoDef = find((trajParamData ~= paramInfo.fillValue) & (cycleNumber == cyNum));
            if (~isempty(idNoDef))

               mcList = unique(measurementCode(idNoDef));

               if (strcmp('PSAL', paramName))
                  g_decArgo_psalMeasCodeList = unique([g_decArgo_psalMeasCodeList; mcList]);
               end

               for measCode = mcList'
                  switch (measCode)
                     case g_MC_DriftAtPark

                        idNoDef = find( ...
                           (juldBest ~= juldInfo.fillValue) & ...
                           (trajParamData ~= paramInfo.fillValue) & ...
                           (cycleNumber == cyNum) & ...
                           (measurementCode == measCode));

                        [paramAdjNull, pcondFactorEq, pcondFactorComp] = ...
                           interp_pcond(paramName, juldBest(idNoDef), ...
                           profPrev, profCur);

                        trajDataAdj = [{cyNum} {paramName} {measCode} {idNoDef} {paramAdjNull} {pcondFactorEq} {pcondFactorComp} {profPrev} {profCur} {juldBest(idNoDef)} {double(trajParamData(idNoDef))}];
                        trajDataAdjAll = cat(1, trajDataAdjAll, trajDataAdj);
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% adjust TRAJ data

trajCyNumList = unique([trajDataAdjAll{:, 1}]);
for cyNum = trajCyNumList

   % if (cyNum == 95)
   %    a=1
   % end

   idForCy = find([trajDataAdjAll{:, 1}] == cyNum);
   mcList = unique([trajDataAdjAll{idForCy, 3}]);

   for measCode = mcList'
      idForMc = find(([trajDataAdjAll{:, 1}] == cyNum) & ([trajDataAdjAll{:, 3}] == measCode));

      paramList = unique({trajDataAdjAll{idForMc, 2}}, 'stable');
      if (any(strcmp(paramList, 'PSAL')))
         % put PSAL at the end of the param list
         idPsal = find(strcmp(paramList, 'PSAL'));
         if (idPsal ~= length(paramList))
            paramList{idPsal} = [];
            paramList{end+1} = 'PSAL';
         end
      end

      traj = [];
      traj.cycleNumber = cyNum;
      traj.measCode = measCode;
      traj.paramList = paramList;
      traj.paramAdjNull = nan(size(paramList));
      traj.dataId = [];
      traj.pcondFactorEq = '';
      traj.pcondFactorComp = '';
      traj.dataJuld = trajDataAdjAll{idForMc, end-1};
      traj.data = [];
      traj.dataAdjEq = [];
      traj.dataAdjComp = [];
      traj.profPrev = trajDataAdjAll{idForMc, 8};
      traj.profCur = trajDataAdjAll{idForMc, 9};

      for idP = 1:length(paramList)
         paramName = paramList{idP};
         idF = find(([trajDataAdjAll{:, 1}] == cyNum) & strcmp({trajDataAdjAll{:, 2}}, paramName) & ([trajDataAdjAll{:, 3}] == measCode));

         traj.paramAdjNull(idP) = trajDataAdjAll{idF, 5};
         if (isempty(traj.dataId))
            traj.dataId = trajDataAdjAll{idF, 4};
         else
            if (any(traj.dataId ~= trajDataAdjAll{idF, 4}))
               fprintf('ANOMALY\n');
            end
         end

         switch paramName
            case {'PRES', 'TEMP'}
               if (traj.paramAdjNull(idP) == 1)
                  traj.data = cat(2, traj.data, trajDataAdjAll{idF, end});
                  traj.dataAdjEq = cat(2, traj.dataAdjEq, trajDataAdjAll{idF, end});
                  traj.dataAdjComp = cat(2, traj.dataAdjComp, trajDataAdjAll{idF, end});
               else
                  traj.data = cat(2, traj.data, trajDataAdjAll{idF, end});
                  traj.dataAdjEq = cat(2, traj.dataAdjEq, nan(size(traj.data, 1), 1));
                  traj.dataAdjComp = cat(2, traj.dataAdjComp, nan(size(traj.data, 1), 1));
               end
            case 'PSAL'
               traj.pcondFactorEq = trajDataAdjAll{idF, 6};
               traj.pcondFactorComp = trajDataAdjAll{idF, 7};
               if (traj.paramAdjNull(idP) == 1)
                  traj.data = cat(2, traj.data, trajDataAdjAll{idF, end});
                  traj.dataAdjEq = cat(2, traj.dataAdjEq, trajDataAdjAll{idF, end});
                  traj.dataAdjComp = cat(2, traj.dataAdjComp, trajDataAdjAll{idF, end});
               elseif (traj.paramAdjNull(idP) == 0)
                  traj.data = cat(2, traj.data, trajDataAdjAll{idF, end});
                  traj.dataAdjEq = cat(2, traj.dataAdjEq, nan(size(traj.data, 1), 1));
                  traj.dataAdjComp = cat(2, traj.dataAdjComp, nan(size(traj.data, 1), 1));

                  idPres = find(strcmp(paramList, 'PRES'));
                  idTemp = find(strcmp(paramList, 'TEMP'));
                  idPsal = find(strcmp(paramList, 'PSAL'));
                  if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal))

                     pres = traj.data(:, idPres);
                     presAdjusted = traj.dataAdjEq(:, idPres);
                     temp = traj.data(:, idTemp);
                     tempAdjusted = traj.dataAdjEq(:, idTemp);
                     psal = traj.data(:, idPsal);

                     % compute psalAdj for both cases
                     idNoNan = find(~isnan(pres) & ~isnan(presAdjusted) & ...
                        ~isnan(temp) & ~isnan(tempAdjusted) & ~isnan(psal));
                     if (~isempty(traj.pcondFactorEq))
                        cndcRaw = sw_cndr(psal(idNoNan), temp(idNoNan), pres(idNoNan));
                        psalAdjInt = sw_salt(cndcRaw, tempAdjusted(idNoNan), presAdjusted(idNoNan));
                        ptmp = sw_ptmp(psalAdjInt, tempAdjusted(idNoNan), presAdjusted(idNoNan), 0);
                        cndc = sw_c3515*sw_cndr(psalAdjInt, ptmp, 0);
                        calCndc = traj.pcondFactorEq.*cndc;
                        psalAdj = sw_salt(calCndc/sw_c3515, ptmp, 0);
                        traj.dataAdjEq(idNoNan, idPsal) = psalAdj;
                     end
                     if (~isempty(traj.pcondFactorComp))
                        cndcRaw = sw_cndr(psal(idNoNan), temp(idNoNan), pres(idNoNan));
                        psalAdjInt = sw_salt(cndcRaw, tempAdjusted(idNoNan), presAdjusted(idNoNan));
                        ptmp = sw_ptmp(psalAdjInt, tempAdjusted(idNoNan), presAdjusted(idNoNan), 0);
                        cndc = sw_c3515*sw_cndr(psalAdjInt, ptmp, 0);
                        calCndc = traj.pcondFactorComp.*cndc;
                        psalAdj = sw_salt(calCndc/sw_c3515, ptmp, 0);
                        traj.dataAdjComp(idNoNan, idPsal) = psalAdj;
                     end
                  end
               end
            otherwise
               traj = [];
               fprintf('ANOMALY\n');
         end
      end
      if (~isempty(traj))
         o_trajDataAdj = cat(2, o_trajDataAdj, traj);
      end
   end
end

return

% ------------------------------------------------------------------------------
% Adjust trajectory measurements with profile DM data for a given cycle and MC.
%
% SYNTAX :
% [o_ok] = adjust_param_data(a_floatNum, a_cyNum, a_paramName, a_measCode, ...
%   a_juldTrajData, a_trajPresData, a_trajParamData, a_profPrev, a_profCur)
%
% INPUT PARAMETERS :
%   a_floatNum      : float WMO number
%   a_cyNum         : traj cycle number
%   a_paramName     : parameter name
%   a_measCode      : traj measurement code
%   a_juldTrajData  : JULD Traj data
%   a_trajPresData  : PRES Traj data
%   a_trajParamData : PARAM Traj data
%   a_profPrev      : previous profile data structure
%   a_profCur       : current profile data structure
%
% OUTPUT PARAMETERS :
%   o_ok : ok flag (1 if it is ok, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/12/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_paramAdjNull, o_pcondFactorEq, o_pcondFactorComp] = ...
   interp_pcond(a_paramName, a_juldTrajData, a_profPrev, a_profCur)

% output parameters initialization
o_paramAdjNull = '';
o_pcondFactorEq = '';
o_pcondFactorComp = '';

% QC flag values
global g_decArgo_qcStrGood;          % '1'
global g_decArgo_qcStrProbablyGood;  % '2'

% list of profile cycle numbers
global g_decArgo_profCyNumList;

% if (a_profCur.cycleNumber == 95)
%    a=1
% end

switch a_paramName
   case 'PRES'
      if (a_profPrev.presAdjNullFlag == 1) && (a_profCur.presAdjNullFlag == 1)
         o_paramAdjNull = 1;
      else
         o_paramAdjNull = 0;
      end
   case 'TEMP'
      if (a_profPrev.tempAdjNullFlag == 1) && (a_profCur.tempAdjNullFlag == 1)
         o_paramAdjNull = 1;
      else
         o_paramAdjNull = 0;
      end
   case 'PSAL'
      if ((a_profPrev.psalAdjNullFlag == 1) && (a_profCur.psalAdjNullFlag == 1))
         o_paramAdjNull = 1;
      else

         % interpolate pcondFactor according to traj measurement times
         if (((a_profPrev.juldQc == g_decArgo_qcStrGood) || (a_profPrev.juldQc == g_decArgo_qcStrProbablyGood)) && ...
               ((a_profCur.juldQc == g_decArgo_qcStrGood) || (a_profCur.juldQc == g_decArgo_qcStrProbablyGood)))
            if (~isempty(a_profPrev.pcondFactorEq) && ~isempty(a_profCur.pcondFactorEq))
               o_pcondFactorEq = interp1( ...
                  [a_profPrev.juld; a_profCur.juld], ...
                  [a_profPrev.pcondFactorEq; a_profCur.pcondFactorEq], a_juldTrajData, 'linear');
               g_decArgo_profCyNumList = [g_decArgo_profCyNumList a_profPrev.cycleNumber a_profCur.cycleNumber];
            end
            if (~isempty(a_profPrev.pcondFactorComp) && ~isempty(a_profCur.pcondFactorComp))
               o_pcondFactorComp = interp1( ...
                  [a_profPrev.juld; a_profCur.juld], ...
                  [a_profPrev.pcondFactorComp; a_profCur.pcondFactorComp], a_juldTrajData, 'linear');
               g_decArgo_profCyNumList = [g_decArgo_profCyNumList a_profPrev.cycleNumber a_profCur.cycleNumber];
            end
         end
         o_paramAdjNull = 0;
      end
   otherwise
      fprintf('ANOMALY\n');
end

return

% ------------------------------------------------------------------------------
% Concat primary and NS profiles (and copy PRES data from core to BGC profiles).
%
% SYNTAX :
% [o_cProfileData, o_bProfileData] = concat_profile(a_floatNum, a_cProfileData, a_bProfileData)
%
% INPUT PARAMETERS :
%   a_floatNum     : float WMO number
%   a_cProfileData : input DM core profile data
%   a_bProfileData : input DM BGC profile data
%
% OUTPUT PARAMETERS :
%   o_cProfileData : output DM core profile data
%   o_bProfileData : output DM BGC profile data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/12/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cProfileData, o_bProfileData] = concat_profile(a_floatNum, a_cProfileData, a_bProfileData)

% output parameters initialization
o_cProfileData = a_cProfileData;
o_bProfileData = a_bProfileData;


% copy PRES data from core to BGC profiles before concatenation
if (~isempty(o_bProfileData))
   o_bProfileData = cat(2, o_bProfileData, repmat({0}, size(o_bProfileData, 1), 1));
   for idB = 1:size(o_bProfileData, 1)
      bProf = o_bProfileData{idB, 3};
      idC = find( ...
         ([o_cProfileData{:, 1}] == bProf.cycleNumber) & ...
         ([o_cProfileData{:, 2}] == bProf.direction) & ...
         ([o_cProfileData{:, 5}] == bProf.proId));
      if (~isempty(idC))
         idPresB = find(strcmp('PRES', bProf.paramList));
         cProf = o_cProfileData{idC, 3};
         idPresC = find(strcmp('PRES', cProf.paramList));
         if (~isempty(idPresB) && ~isempty(idPresC))
            profPresDataB = bProf.data(:, idPresB);
            profPresDataC = cProf.data(:, idPresC);
            if ((length(profPresDataB) == length(profPresDataC)) && ...
                  all(isnan(profPresDataB) == isnan(profPresDataC)))
               profPresDataB(isnan(profPresDataB)) = [];
               profPresDataC(isnan(profPresDataC)) = [];
               if (all(profPresDataB == profPresDataC))
                  bProf.dataQc(:, idPresB) = cProf.dataQc(:, idPresC);
                  bProf.dataAdj(:, idPresB) = cProf.dataAdj(:, idPresC);
                  bProf.dataAdjQc(:, idPresB) = cProf.dataAdjQc(:, idPresC);
                  o_bProfileData{idB, 3} = bProf;
                  o_bProfileData{idB, 6} = 1;
               else
                  fprintf('ERROR: Anomaly\n');
               end
            else
               fprintf('ERROR: Anomaly\n');
            end
         else
            fprintf('ERROR: Anomaly\n');
         end
      else
         fprintf('ERROR: Anomaly\n');
      end
   end
end

% concatenate core profiles
cyNumList = [o_cProfileData{:, 1}];
dirList = [o_cProfileData{:, 2}];
uCyNumList = unique(cyNumList);
idToDel = [];
for cyNum = uCyNumList
   idForCy = find((cyNumList == cyNum) & (dirList == 2));
   if (length(idForCy) == 2)
      prof1 = o_cProfileData{idForCy(1), 3};
      prof2 = o_cProfileData{idForCy(2), 3};
      if (strncmp(prof1.vss, 'Primary sampling:', length('Primary sampling:')) && ...
            strncmp(prof2.vss, 'Near-surface sampling:', length('Near-surface sampling:')))
         idPrim = idForCy(1);
         idNs = idForCy(2);
      elseif (strncmp(prof2.vss, 'Primary sampling:', length('Primary sampling:')) && ...
            strncmp(prof1.vss, 'Near-surface sampling:', length('Near-surface sampling:')))
         idPrim = idForCy(2);
         idNs = idForCy(1);
      else
         fprintf('ERROR: Anomaly\n');
         continue
      end

      profPrim = o_cProfileData{idPrim, 3};
      profNs = o_cProfileData{idNs, 3};
      if (length(profPrim.paramList) ~= length(profNs.paramList))
         fprintf('ERROR: Anomaly\n');
         continue
      end

      dataNs = profNs.data;
      while (sum(isnan(dataNs(end, :))) == size(dataNs, 2))
         dataNs(end, :) = [];
      end
      measId = 1:size(dataNs, 1);
      profPrim.data = cat(1, profNs.data(measId, :), profPrim.data);
      profPrim.dataQc = cat(1, profNs.dataQc(measId, :), profPrim.dataQc);
      profPrim.dataAdj = cat(1, profNs.dataAdj(measId, :), profPrim.dataAdj);
      profPrim.dataAdjQc = cat(1, profNs.dataAdjQc(measId, :), profPrim.dataAdjQc);
      profPrim.vss = 'Concatenated';

      if (o_cProfileData{idPrim, 6} == o_cProfileData{idNs, 6})
         o_cProfileData{idPrim, 3} = profPrim;
         o_cProfileData{idPrim, 5} = -1;
         idToDel = [idToDel; idNs];
      elseif (o_cProfileData{idPrim, 6} == 'D')
         o_cProfileData{idNs, 3} = profPrim;
         o_cProfileData{idNs, 5} = -1;
         o_cProfileData{idNs, 6} = 'M';
      elseif (o_cProfileData{idNs, 6} == 'D')
         o_cProfileData{idPrim, 3} = profPrim;
         o_cProfileData{idPrim, 5} = -1;
         o_cProfileData{idPrim, 6} = 'M';
      else
         o_cProfileData = [o_cProfileData; ...
            {profPrim.cycleNumber} {profPrim.direction} {profPrim} {nan} {-1} {'M'}];
      end
   elseif (length(idForCy) > 2)
      fprintf('ERROR: Anomaly\n');
   end
end
o_cProfileData(idToDel, :) = [];

% concatenate BGC profiles
if (~isempty(o_bProfileData))
   cyNumList = [o_bProfileData{:, 1}];
   dirList = [o_bProfileData{:, 2}];
   uCyNumList = unique(cyNumList);
   idToDel = [];
   for cyNum = uCyNumList
      idForCy = find((cyNumList == cyNum) & (dirList == 2));
      if (length(idForCy) == 2)
         prof1 = o_bProfileData{idForCy(1), 3};
         prof2 = o_bProfileData{idForCy(2), 3};
         if (strncmp(prof1.vss, 'Primary sampling:', length('Primary sampling:')) && ...
               strncmp(prof2.vss, 'Near-surface sampling:', length('Near-surface sampling:')))
            idPrim = idForCy(1);
            idNs = idForCy(2);
         elseif (strncmp(prof2.vss, 'Primary sampling:', length('Primary sampling:')) && ...
               strncmp(prof1.vss, 'Near-surface sampling:', length('Near-surface sampling:')))
            idPrim = idForCy(2);
            idNs = idForCy(1);
         else
            fprintf('ERROR: Anomaly\n');
            continue
         end

         profPrim = o_bProfileData{idPrim, 3};
         profNs = o_bProfileData{idNs, 3};
         if (length(profPrim.paramList) ~= length(profNs.paramList))
            fprintf('ERROR: Anomaly\n');
            continue
         end

         dataNs = profNs.data;
         while (sum(isnan(dataNs(end, :))) == size(dataNs, 2))
            dataNs(end, :) = [];
         end
         measId = 1:size(dataNs, 1);
         profPrim.data = cat(1, profNs.data(measId, :), profPrim.data);
         profPrim.dataQc = cat(1, profNs.dataQc(measId, :), profPrim.dataQc);
         profPrim.dataAdj = cat(1, profNs.dataAdj(measId, :), profPrim.dataAdj);
         profPrim.dataAdjQc = cat(1, profNs.dataAdjQc(measId, :), profPrim.dataAdjQc);
         profPrim.vss = 'Concatenated';

         o_bProfileData{idPrim, 3} = profPrim;
         o_bProfileData{idPrim, 5} = -1;
         idToDel = [idToDel; idNs];
      elseif (length(idForCy) > 2)
         fprintf('ERROR: Anomaly\n');
      end
   end
   o_bProfileData(idToDel, :) = [];
end

% copy PRES data from core to BGC profiles after concatenation (for remaining
% data (o_bProfileData{:, 6} == 0)
if (~isempty(o_bProfileData))
   if (any([o_bProfileData{:, 6}] == 0))
      for idB = 1:size(o_bProfileData, 1)
         if (o_bProfileData{idB, 6} == 0)
            bProf = o_bProfileData{idB, 3};
            idPresB = find(strcmp('PRES', bProf.paramList));
            profIdList = find( ...
               ([o_cProfileData{:, 1}] == bProf.cycleNumber) & ...
               ([o_cProfileData{:, 2}] == bProf.direction));
            for profId = profIdList
               cProf = o_cProfileData{profId, 3};
               idPresC = find(strcmp('PRES', cProf.paramList));
               profPresDataB = bProf.data(:, idPresB);
               profPresDataC = cProf.data(:, idPresC);
               if ((length(profPresDataB) == length(profPresDataC)) && ...
                     all(profPresDataB == profPresDataC))
                  bProf.dataQc(:, idPresB) = cProf.dataQc(:, idPresC);
                  bProf.dataAdj(:, idPresB) = cProf.dataAdj(:, idPresC);
                  bProf.dataAdjQc(:, idPresB) = cProf.dataAdjQc(:, idPresC);
                  o_bProfileData{idB, 3} = bProf;
                  o_bProfileData{idB, 6} = 1;
               else
                  continue
               end
            end
            if (o_bProfileData{idB, 6} == 0)
               fprintf('ERROR: Anomaly\n');
            end
         end
      end
   end
end

if (~isempty(o_cProfileData))
   idToKeep = find([o_cProfileData{:, 6}] == 'D');
   idToDel = setdiff(1:size(o_cProfileData, 1), idToKeep);
   o_cProfileData(idToDel, :) = [];
end

return

% ------------------------------------------------------------------------------
% Retrieve DM data from profile NetCDf files.
%
% SYNTAX :
% [o_dmCProfileData, o_cParamList, o_dmBProfileData, o_bParamList] = ...
%   get_profile_dm_data(a_floatNum, a_ncFileDir)
%
% INPUT PARAMETERS :
%   a_floatNum  : float WMO number
%   a_ncFileDir : float nc files directory
%
% OUTPUT PARAMETERS :
%   o_dmCProfileData : DM core profile data
%   o_cParamList     : list of core parameter names
%   o_dmBProfileData : DM BGC profile data
%   o_bParamList     : list of BGC parameter names
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/12/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dmCProfileData, o_cParamList, o_dmBProfileData, o_bParamList] = ...
   get_profile_dm_data(a_floatNum, a_ncFileDir)

% output parameters initialization
o_dmCProfileData = [];
o_cParamList = [];
o_dmBProfileData = [];
o_bParamList = [];


if ~(exist(a_ncFileDir, 'dir') == 7)
   fprintf('INFO: Float %d: Directory not found: %s\n', ...
      a_floatNum, a_ncFileDir);
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% retrieve DM data from profile files

profDirName = [a_ncFileDir '/profiles/'];
if ~(exist(profDirName, 'dir') == 7)
   fprintf('INFO: Float %d: Directory not found: %s\n', ...
      a_floatNum, profDirName);
   return
end

floatCFilesD = dir([profDirName '/' sprintf('D%d_*.nc', a_floatNum)]);
floatCFilesR = dir([profDirName '/' sprintf('R%d_*.nc', a_floatNum)]);
floatBFiles = dir([profDirName '/' sprintf('BD%d_*.nc', a_floatNum)]);
floatFiles = [floatCFilesD; floatCFilesR; floatBFiles];
for idFile = 1:length(floatFiles)

   floatFileName = floatFiles(idFile).name;

   %%%%%%%%%%%%%%
   % core profile
   if ((floatFileName(1) == 'D') || ((floatFileName(1) == 'R') && ~isempty(floatBFiles)))

      floatFilePathName = [profDirName '/' floatFileName];

      % retrieve data from file
      wantedVars = [ ...
         {'FORMAT_VERSION'} ...
         {'STATION_PARAMETERS'} ...
         {'DATA_MODE'} ...
         ];
      ncData = get_data_from_nc_file(floatFilePathName, wantedVars);

      formatVersion = get_data_from_name('FORMAT_VERSION', ncData)';
      formatVersion = strtrim(formatVersion);
      % check the file format version
      if (~strcmp(formatVersion, '3.1'))
         fprintf('INFO: Input mono prof file (%s) is expected to be of 3.1 format version (but FORMAT_VERSION = %s) - ignored\n', ...
            floatFileName, formatVersion);
         continue
      end
      stationParameters = get_data_from_name('STATION_PARAMETERS', ncData);
      dataMode = get_data_from_name('DATA_MODE', ncData);
      if (isempty(floatBFiles))
         if (~any(dataMode == 'D'))
            fprintf('ERROR: No delayed mode in prof file %s - ignored\n', ...
               floatFileName);
            continue
         end
      end

      % retrieve data from file
      wantedVars = [ ...
         {'CYCLE_NUMBER'} ...
         {'DIRECTION'} ...
         {'JULD'} ...
         {'JULD_QC'} ...
         {'JULD_LOCATION'} ...
         {'LATITUDE'} ...
         {'LONGITUDE'} ...
         {'POSITION_QC'} ...
         {'VERTICAL_SAMPLING_SCHEME'} ...
         {'PARAMETER'} ...
         {'SCIENTIFIC_CALIB_EQUATION'} ...
         {'SCIENTIFIC_CALIB_COEFFICIENT'} ...
         {'SCIENTIFIC_CALIB_COMMENT'} ...
         {'SCIENTIFIC_CALIB_DATE'} ...
         ];

      [~, nParam, nProf] = size(stationParameters);
      paramListAll = [];
      for idProf = 1:nProf
         paramList = [];
         if ((dataMode(idProf) == 'D') || ~isempty(floatBFiles))
            for idParam = 1:nParam
               paramName = strtrim(stationParameters(:, idParam, idProf)');
               if (~isempty(paramName))
                  if (~strcmp(paramName, 'MTIME'))
                     paramList{end+1} = paramName;
                     if (~ismember(paramName, o_cParamList))
                        o_cParamList{end+1} = paramName;
                     end
                     if (~ismember(paramName, wantedVars))
                        wantedVars = [wantedVars ...
                           {paramName} {[paramName '_QC']} ...
                           {[paramName '_ADJUSTED']} {[paramName '_ADJUSTED_QC']} ...
                           ];
                     end
                  end
               end
            end
         end
         paramListAll{end+1} = paramList;
      end
      ncData = get_data_from_nc_file(floatFilePathName, wantedVars);

      cycleNumber = get_data_from_name('CYCLE_NUMBER', ncData);
      direction = get_data_from_name('DIRECTION', ncData);
      juld = get_data_from_name('JULD', ncData);
      juldQc = get_data_from_name('JULD_QC', ncData);
      juldLocation = get_data_from_name('JULD_LOCATION', ncData);
      latitude = get_data_from_name('LATITUDE', ncData);
      longitude = get_data_from_name('LONGITUDE', ncData);
      positionQc = get_data_from_name('POSITION_QC', ncData);
      vertSampScheme = get_data_from_name('VERTICAL_SAMPLING_SCHEME', ncData);
      parameter = get_data_from_name('PARAMETER', ncData);
      sciCalibEquation = get_data_from_name('SCIENTIFIC_CALIB_EQUATION', ncData);
      sciCalibCoef = get_data_from_name('SCIENTIFIC_CALIB_COEFFICIENT', ncData);
      sciCalibComment = get_data_from_name('SCIENTIFIC_CALIB_COMMENT', ncData);
      sciCalibDate = get_data_from_name('SCIENTIFIC_CALIB_DATE', ncData);

      [~, nParam2, nCalib, ~] = size(parameter);
      for idProf = 1:nProf
         if ((dataMode(idProf) == 'D') || ~isempty(floatBFiles))
            % temporary ignore descent profile (because they are not used yet)
            if (direction(idProf) == 'D')
               continue
            end
            prof = [];
            prof.proId = idProf;
            prof.cycleNumber = cycleNumber(idProf);
            % if (prof.cycleNumber == 12)
            %    a=1
            % end
            profDir = 2;
            if (direction(idProf) == 'D')
               profDir = 1;
            end
            prof.direction = profDir;
            prof.dataMode = dataMode(idProf);
            prof.juld = juld(idProf);
            prof.juldQc = juldQc(idProf);
            prof.juldLocation = juldLocation(idProf);
            prof.latitude = latitude(idProf);
            prof.longitude = longitude(idProf);
            prof.positionQc = positionQc(idProf);
            prof.vss = vertSampScheme(:, idProf)';
            prof.presAdjNullFlag = nan;
            prof.tempAdjNullFlag = nan;
            prof.psalAdjNullFlag = nan;
            prof.psalSlope = nan;
            prof.psalOffset = nan;
            prof.pcondFactorEq = ''; % from SCIENTIFIC_CALIB_COEFFICIENT
            prof.pcondFactorComp = ''; % computed from profile data

            data = [];
            dataQc = [];
            dataAdj = [];
            dataAdjQc = [];

            paramList = [];
            sciCalEq = [];
            sciCalCoef = [];
            sciCalCom = [];
            sciCalDate = [];
            for idParam = 1:nParam
               paramName = strtrim(stationParameters(:, idParam, idProf)');
               if (~isempty(paramName))
                  if (~strcmp(paramName, 'MTIME'))
                     paramList{end+1} = paramName;

                     % DATA
                     paramDataAll = get_data_from_name(paramName, ncData);
                     paramData = paramDataAll(:, idProf);
                     if (isempty(data))
                        data = nan(length(paramData), length(paramListAll{idProf}));
                        dataQc = repmat(' ', length(paramData), length(paramListAll{idProf}));
                        dataAdj = nan(length(paramData), length(paramListAll{idProf}));
                        dataAdjQc = repmat(' ', length(paramData), length(paramListAll{idProf}));
                        col = 1;
                     end
                     paramInfo = get_netcdf_param_attributes(paramName);
                     paramData(paramData == paramInfo.fillValue) = nan;
                     data(:, col) = paramData;

                     paramDataAdjAll = get_data_from_name([paramName '_ADJUSTED'], ncData);
                     paramDataAdj = paramDataAdjAll(:, idProf);
                     paramDataAdj(paramDataAdj == paramInfo.fillValue) = nan;
                     dataAdj(:, col) = paramDataAdj;

                     paramDataQcAll = get_data_from_name([paramName '_QC'], ncData);
                     paramDataQc = paramDataQcAll(:, idProf);
                     dataQc(:, col) = paramDataQc;

                     paramDataAdjQcAll = get_data_from_name([paramName '_ADJUSTED_QC'], ncData);
                     paramDataAdjQc = paramDataAdjQcAll(:, idProf);
                     dataAdjQc(:, col) = paramDataAdjQc;

                     col = col + 1;

                     % SCIENTIFIC_CALIB

                     sciCalEqP = [];
                     sciCalCoefP = [];
                     sciCalComP = [];
                     sciCalDateP = [];
                     for idCalib = 1:nCalib
                        for idParam2 = 1:nParam2
                           paramName2 = strtrim(parameter(:, idParam2, idCalib, idProf)');
                           if (strcmp(paramName, paramName2))
                              sciCalEqP{end+1} = strtrim(sciCalibEquation(:, idParam2, idCalib, idProf)');
                              sciCalCoefP{end+1} = strtrim(sciCalibCoef(:, idParam2, idCalib, idProf)');
                              sciCalComP{end+1} = strtrim(sciCalibComment(:, idParam2, idCalib, idProf)');
                              sciCalDateP{end+1} = strtrim(sciCalibDate(:, idParam2, idCalib, idProf)');
                           end
                        end
                     end
                     sciCalEq{end+1} = sciCalEqP;
                     sciCalCoef{end+1} = sciCalCoefP;
                     sciCalCom{end+1} = sciCalComP;
                     sciCalDate{end+1} = sciCalDateP;
                  end
               end
            end

            if (all(isnan(data)))
               % to cope with inconsistencies in DATA_MODE
               continue
            end

            prof.data = data;
            prof.dataQc = dataQc;
            prof.dataAdj = dataAdj;
            prof.dataAdjQc = dataAdjQc;

            prof.paramList = paramList;
            prof.sciCalEq = sciCalEq;
            prof.sciCalCoef = sciCalCoef;
            prof.sciCalCom = sciCalCom;
            prof.sciCalDate = sciCalDate;

            if (prof.dataMode == 'D')

               % retrieve/compute pcond_factor
               prof = get_profile_pcond_factor(prof);
            end

            o_dmCProfileData = [o_dmCProfileData; ...
               {prof.cycleNumber} {prof.direction} {prof} {nan} {idProf} {dataMode(idProf)}];
         end
      end
   end

   %%%%%%%%%%%%%
   % BGC profile
   if ((floatFileName(1) == 'B') && (floatFileName(2) == 'D'))
      floatFilePathName = [profDirName '/' floatFileName];

      % retrieve data from file
      wantedVars = [ ...
         {'FORMAT_VERSION'} ...
         {'STATION_PARAMETERS'} ...
         {'PARAMETER_DATA_MODE'} ...
         {'DATA_MODE'} ...
         {'CYCLE_NUMBER'} ...
         ];
      ncData = get_data_from_nc_file(floatFilePathName, wantedVars);

      formatVersion = get_data_from_name('FORMAT_VERSION', ncData)';
      formatVersion = strtrim(formatVersion);
      % check the file format version
      if (~strcmp(formatVersion, '3.1'))
         fprintf('INFO: Input mono prof file (%s) is expected to be of 3.1 format version (but FORMAT_VERSION = %s) - ignored\n', ...
            floatFileName, formatVersion);
         continue
      end
      stationParameters = get_data_from_name('STATION_PARAMETERS', ncData);
      paramDataMode = get_data_from_name('PARAMETER_DATA_MODE', ncData);
      dataMode = get_data_from_name('DATA_MODE', ncData);
      cycleNumber = get_data_from_name('CYCLE_NUMBER', ncData);
      if (~any(dataMode == 'D'))
         fprintf('ERROR: No delayed mode in prof file %s - ignored\n', ...
            floatFileName);
         continue
      end

      % retrieve data from file
      wantedVars = [ ...
         {'CYCLE_NUMBER'} ...
         {'DIRECTION'} ...
         {'JULD'} ...
         {'JULD_QC'} ...
         {'JULD_LOCATION'} ...
         {'LATITUDE'} ...
         {'LONGITUDE'} ...
         {'POSITION_QC'} ...
         {'VERTICAL_SAMPLING_SCHEME'} ...
         {'PARAMETER'} ...
         {'SCIENTIFIC_CALIB_EQUATION'} ...
         {'SCIENTIFIC_CALIB_COEFFICIENT'} ...
         {'SCIENTIFIC_CALIB_COMMENT'} ...
         {'SCIENTIFIC_CALIB_DATE'} ...
         ];

      [~, nParam, nProf] = size(stationParameters);
      paramListAll = [];
      for idProf = 1:nProf
         paramList = [];
         if (dataMode(idProf) == 'D')
            for idParam = 1:nParam
               paramName = strtrim(stationParameters(:, idParam, idProf)');
               if (~isempty(paramName))
                  if (strcmp(paramName, 'PRES') || (paramDataMode(idParam, idProf) == 'D'))
                     paramList{end+1} = paramName;
                     if (~ismember(paramName, o_bParamList))
                        o_bParamList{end+1} = paramName;
                     end
                     if (~ismember(paramName, wantedVars))
                        wantedVars = [wantedVars ...
                           {paramName} {[paramName '_QC']} ...
                           {[paramName '_ADJUSTED']} {[paramName '_ADJUSTED_QC']} ...
                           ];
                     end
                  end
               end
            end
         end
         paramListAll{end+1} = paramList;
      end
      ncData = get_data_from_nc_file(floatFilePathName, wantedVars);

      cycleNumber = get_data_from_name('CYCLE_NUMBER', ncData);
      direction = get_data_from_name('DIRECTION', ncData);
      juld = get_data_from_name('JULD', ncData);
      juldQc = get_data_from_name('JULD_QC', ncData);
      juldLocation = get_data_from_name('JULD_LOCATION', ncData);
      latitude = get_data_from_name('LATITUDE', ncData);
      longitude = get_data_from_name('LONGITUDE', ncData);
      positionQc = get_data_from_name('POSITION_QC', ncData);
      vertSampScheme = get_data_from_name('VERTICAL_SAMPLING_SCHEME', ncData);
      parameter = get_data_from_name('PARAMETER', ncData);
      sciCalibEquation = get_data_from_name('SCIENTIFIC_CALIB_EQUATION', ncData);
      sciCalibCoef = get_data_from_name('SCIENTIFIC_CALIB_COEFFICIENT', ncData);
      sciCalibComment = get_data_from_name('SCIENTIFIC_CALIB_COMMENT', ncData);
      sciCalibDate = get_data_from_name('SCIENTIFIC_CALIB_DATE', ncData);

      [~, nParam2, nCalib, ~] = size(parameter);
      for idProf = 1:nProf
         if (length(paramListAll{idProf}) > 1)
            if (dataMode(idProf) == 'D')
               % temporary ignore descent profile (because they are not used yet)
               if (direction(idProf) == 'D')
                  continue
               end
               prof = [];
               prof.proId = idProf;
               prof.cycleNumber = cycleNumber(idProf);
               % if (prof.cycleNumber == 12)
               %    a=1
               % end
               profDir = 2;
               if (direction(idProf) == 'D')
                  profDir = 1;
               end
               prof.direction = profDir;
               prof.dataMode = dataMode(idProf);
               prof.juld = juld(idProf);
               prof.juldQc = juldQc(idProf);
               prof.juldLocation = juldLocation(idProf);
               prof.latitude = latitude(idProf);
               prof.longitude = longitude(idProf);
               prof.positionQc = positionQc(idProf);
               prof.vss = vertSampScheme(:, idProf)';
               prof.psalOffset = nan;

               data = [];
               dataQc = [];
               dataAdj = [];
               dataAdjQc = [];

               paramList = [];
               sciCalEq = [];
               sciCalCoef = [];
               sciCalCom = [];
               sciCalDate = [];
               for idParam = 1:nParam
                  paramName = strtrim(stationParameters(:, idParam, idProf)');
                  if (~isempty(paramName))
                     if (strcmp(paramName, 'PRES') || (paramDataMode(idParam, idProf) == 'D'))
                        paramList{end+1} = paramName;

                        % DATA
                        paramDataAll = get_data_from_name(paramName, ncData);
                        paramData = paramDataAll(:, idProf);
                        if (isempty(data))
                           data = nan(length(paramData), length(paramListAll{idProf}));
                           dataQc = repmat(' ', length(paramData), length(paramListAll{idProf}));
                           dataAdj = nan(length(paramData), length(paramListAll{idProf}));
                           dataAdjQc = repmat(' ', length(paramData), length(paramListAll{idProf}));
                           col = 1;
                        end
                        paramInfo = get_netcdf_param_attributes(paramName);
                        paramData(paramData == paramInfo.fillValue) = nan;
                        data(:, col) = paramData;

                        if (~strcmp(paramName, 'PRES'))
                           paramDataQcAll = get_data_from_name([paramName '_QC'], ncData);
                           paramDataQc = paramDataQcAll(:, idProf);
                           dataQc(:, col) = paramDataQc;

                           paramDataAdjAll = get_data_from_name([paramName '_ADJUSTED'], ncData);
                           paramDataAdj = paramDataAdjAll(:, idProf);
                           paramDataAdj(paramDataAdj == paramInfo.fillValue) = nan;
                           dataAdj(:, col) = paramDataAdj;

                           paramDataAdjQcAll = get_data_from_name([paramName '_ADJUSTED_QC'], ncData);
                           paramDataAdjQc = paramDataAdjQcAll(:, idProf);
                           dataAdjQc(:, col) = paramDataAdjQc;
                        end
                        col = col + 1;

                        % SCIENTIFIC_CALIB

                        sciCalEqP = [];
                        sciCalCoefP = [];
                        sciCalComP = [];
                        sciCalDateP = [];
                        for idCalib = 1:nCalib
                           for idParam2 = 1:nParam2
                              paramName2 = strtrim(parameter(:, idParam2, idCalib, idProf)');
                              if (strcmp(paramName, paramName2))
                                 sciCalEqP{end+1} = strtrim(sciCalibEquation(:, idParam2, idCalib, idProf)');
                                 sciCalCoefP{end+1} = strtrim(sciCalibCoef(:, idParam2, idCalib, idProf)');
                                 sciCalComP{end+1} = strtrim(sciCalibComment(:, idParam2, idCalib, idProf)');
                                 sciCalDateP{end+1} = strtrim(sciCalibDate(:, idParam2, idCalib, idProf)');
                              end
                           end
                        end
                        sciCalEq{end+1} = sciCalEqP;
                        sciCalCoef{end+1} = sciCalCoefP;
                        sciCalCom{end+1} = sciCalComP;
                        sciCalDate{end+1} = sciCalDateP;
                     end
                  end
               end

               if (all(isnan(data)))
                  % to cope with inconsistencies in DATA_MODE
                  continue
               end
               prof.data = data;
               prof.dataQc = dataQc;
               prof.dataAdj = dataAdj;
               prof.dataAdjQc = dataAdjQc;

               prof.paramList = paramList;
               prof.sciCalEq = sciCalEq;
               prof.sciCalCoef = sciCalCoef;
               prof.sciCalCom = sciCalCom;
               prof.sciCalDate = sciCalDate;

               o_dmBProfileData = [o_dmBProfileData; ...
                  {prof.cycleNumber} {prof.direction} {prof} {nan} {idProf}];
            end
         end
      end
   end
end

if (isempty(o_dmCProfileData))
   fprintf('INFO: Float %d: No DM core profile data available\n', ...
      a_floatNum);
end

% if (isempty(o_dmBProfileData))
%    fprintf('INFO: Float %d: No DM BGC profile data available\n', ...
%       a_floatNum);
% end

return

% ------------------------------------------------------------------------------
% Retrieve pcond_factor from SCIENTIFIC_CALIB_EQUATION and compute it from
% profile data.
%
% SYNTAX :
% [o_profStruct] = get_profile_pcond_factor(a_profStruct)
%
% INPUT PARAMETERS :
%   a_profStruct : input DM profile structure
%
% OUTPUT PARAMETERS :
%   a_profStruct : output DM profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profStruct] = get_profile_pcond_factor(a_profStruct)

% output parameters initialization
o_profStruct = a_profStruct;

% pcond_factor resolution
RES = 1e-5;

% if (o_profStruct.cycleNumber == 95)
%    a=1
% end

% retrieve PRES, TEMP and PSAL data
idPres = find(strcmp('PRES', o_profStruct.paramList));
pres = o_profStruct.data(:, idPres);
presAdjusted = o_profStruct.dataAdj(:, idPres);
idTemp = find(strcmp('TEMP', o_profStruct.paramList));
temp = o_profStruct.data(:, idTemp);
tempAdjusted = o_profStruct.dataAdj(:, idTemp);
idPsal = find(strcmp('PSAL', o_profStruct.paramList));
psal = o_profStruct.data(:, idPsal);
psalAdjusted = o_profStruct.dataAdj(:, idPsal);

% check that PRES_ADJSUTED = PRES
if (any(~isnan(presAdjusted)))
   idNoNan = find(~isnan(presAdjusted) & ~isnan(pres));
   if (any(presAdjusted(idNoNan) ~= pres(idNoNan)))
      fprintf('ERROR: PRES adjustment not null\n');
      o_profStruct.presAdjNullFlag = 0;
   else
      o_profStruct.presAdjNullFlag = 1;
   end
end

% check that TEMP_ADJSUTED = TEMP
if (any(~isnan(tempAdjusted)))
   idNoNan = find(~isnan(tempAdjusted) & ~isnan(temp));
   if (any(tempAdjusted(idNoNan) ~= temp(idNoNan)))
      fprintf('ERROR: TEMP adjustment not null\n');
      o_profStruct.tempAdjNullFlag = 0;
   else
      o_profStruct.tempAdjNullFlag = 1;
   end
end

% check that PSAL_ADJSUTED = PSAL or get and estimate pcond_factor
if (any(~isnan(psalAdjusted)))
   idNoNan = find(~isnan(psalAdjusted) & ~isnan(psal));
   if (any(psalAdjusted(idNoNan) ~= psal(idNoNan)))

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % retrieve pcond_factor information from SCIENTIFIC_CALIB_COEFFICIENT
      coef = o_profStruct.sciCalCoef{idPsal};
      if (length(coef) > 1)
         calDate = o_profStruct.sciCalDate{idPsal};
         [~, idSort] = sort(calDate);
         coef = coef{idSort(end)};
      else
         coef = coef{1};
      end

      if (any(strfind(coef, 'r=')))
         rStart = strfind(coef, 'r=');
         rStop = strfind(coef, ',');
         [val, count, errmsg, ~] = sscanf(coef(rStart:rStop), 'r=%f,');
         if (isempty(errmsg) && (count == 1))
            % fprintf('%s"\n', coef(rStart:rStop));
            o_profStruct.pcondFactorEq = round(double(val(1))/RES)*RES;
         else
            rStop = strfind(coef, '(+');
            rStop = rStop(1);
            [val, count, errmsg, ~] = sscanf(coef(rStart:rStop), 'r=%f (');
            if (isempty(errmsg) && (count == 1))
               % fprintf('%s"\n', coef(rStart:rStop));
               o_profStruct.pcondFactorEq = round(double(val(1))/RES)*RES;
            else
               fprintf('ERROR: Anomaly (cannot parse pcond_factor equation) - "%s"\n', coef);
            end
         end
      else
         fprintf('ERROR: Anomaly (cannot parse pcond_factor equation) - "%s"\n', coef);
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % compute pcond_factor from data
      idNoNan = find(~isnan(pres) & ~isnan(presAdjusted) & ...
         ~isnan(temp) & ~isnan(tempAdjusted) & ~isnan(psal) & ~isnan(psalAdjusted));

      cndcRaw = sw_cndr(psal(idNoNan), temp(idNoNan), pres(idNoNan));
      psalAdjInt = sw_salt(cndcRaw, tempAdjusted(idNoNan), presAdjusted(idNoNan));
      ptmp = sw_ptmp(psalAdjInt, tempAdjusted(idNoNan), presAdjusted(idNoNan), 0);
      cndcAdjInt = sw_c3515*sw_cndr(psalAdjInt, ptmp, 0);
      cndcAdj = sw_c3515*sw_cndr(psalAdjusted(idNoNan), ptmp, 0);
      pcondFactor = mean(cndcAdj./cndcAdjInt);

      o_profStruct.pcondFactorComp = round(double(pcondFactor)/RES)*RES;
      o_profStruct.pcondFactorComp = pcondFactor;
      o_profStruct.psalAdjNullFlag = 0;

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % compute psalAdj for both cases

      o_profStruct.psalAdjEq = nan(size(o_profStruct.dataAdj, 1), 1);
      o_profStruct.psalAdjComp = nan(size(o_profStruct.dataAdj, 1), 1);
      
      idNoNan = find(~isnan(pres) & ~isnan(presAdjusted) & ...
         ~isnan(temp) & ~isnan(tempAdjusted) & ~isnan(psal));

      cndcRaw = sw_cndr(psal(idNoNan), temp(idNoNan), pres(idNoNan));
      psalAdjInt = sw_salt(cndcRaw, tempAdjusted(idNoNan), presAdjusted(idNoNan));
      ptmp = sw_ptmp(psalAdjInt, tempAdjusted(idNoNan), presAdjusted(idNoNan), 0);
      cndc = sw_c3515*sw_cndr(psalAdjInt, ptmp, 0);
      calCndc = o_profStruct.pcondFactorEq.*cndc;
      psalAdj = sw_salt(calCndc/sw_c3515, ptmp, 0);

      o_profStruct.psalAdjEq(idNoNan) = psalAdj;
      o_profStruct.maxDiffPsalEq = max(abs(psalAdjusted(idNoNan)-psalAdj));

      calCndc = o_profStruct.pcondFactorComp.*cndc;
      psalAdj = sw_salt(calCndc/sw_c3515, ptmp, 0);

      o_profStruct.psalAdjComp(idNoNan) = psalAdj;
      o_profStruct.maxDiffPsalComp = max(abs(psalAdjusted(idNoNan)-psalAdj));

   else
      o_profStruct.pcondFactorEq = 1;
      o_profStruct.pcondFactorComp = 1;
      o_profStruct.psalAdjNullFlag = 1;
   end
end

return

% ------------------------------------------------------------------------------
% Create a squeezed string version of a given cycle number list.
%
% SYNTAX :
% [o_cyNumListStr] = squeeze_list(a_cyNumList)
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
%   02/16/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cyNumListStr] = squeeze_list(a_cyNumList)

% output parameters initialization
o_cyNumListStr = '';

if (isempty(a_cyNumList))
   return
end

idSet = find(diff(a_cyNumList) > 1);
idStart = 1;
o_cyNumListStr = '|';
for id = 1:length(idSet)+1
   if (id <= length(idSet))
      idStop = idSet(id);
   else
      idStop = length(a_cyNumList);
   end
   if (length(a_cyNumList(idStart:idStop)) == 1)
      o_cyNumListStr = [o_cyNumListStr sprintf('%d|', a_cyNumList(idStart:idStop))];
   else
      o_cyNumListStr = [o_cyNumListStr sprintf('%d:%d|', a_cyNumList(idStart), a_cyNumList(idStop))];
   end
   idStart = idStop + 1;
end

return
