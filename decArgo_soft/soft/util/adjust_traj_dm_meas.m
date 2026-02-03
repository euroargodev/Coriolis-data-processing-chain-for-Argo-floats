% ------------------------------------------------------------------------------
% Adjust parameter measurement values in a DM trajectory file.
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
%   04/12/2024 - RNU - V 1.0: creation
%                             only PTS adjustments, not null adjustments for PSAL only.
% ------------------------------------------------------------------------------
function adjust_traj_dm_meas(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START

% default list of floats to process
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_tmp.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ANDRO_2_TRAJ-DM\Decomptes_20240621\arvor_in_andro.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ANDRO_2_TRAJ-DM\Decomptes_20240621\arvor_in_andro_with_prof_DM.txt';

% top directory of the input DM PROF NetCDF files
DIR_INPUT_NC_PROF_FILES = 'C:\Users\jprannou\_DATA\TRAJ_DM_2024\snapshot-202405_arvor_ir_in_andro_325\';

% top directory of the input TRAJ NetCDF files
DIR_INPUT_NC_TRAJ_FILES = 'C:\Users\jprannou\_DATA\TRAJ_DM_2024\nc_output_decArgo_traj_dm\';

% top directory of the output DM TRAJ NetCDF files
DIR_OUTPUT_NC_TRAJ_FILES = 'C:\Users\jprannou\_DATA\OUT\TRAJ_DM_2024\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the csv file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';

% to generate DM TRAJ NetCDF files
GENERATE_OUTPUT_TRAJ_FLAG = 1;

% to generate CSV detailed file
GENERATE_OUTPUT_CSV_DETAILED_FLAG = 0;

% current tool version
global g_decArgo_adjustTrajDmMeasVersion
g_decArgo_adjustTrajDmMeasVersion = '1.0';

% comment for SCIENTIFIC_CALIB_COMMENT
global g_decArgo_scientificCalibComment
g_decArgo_scientificCalibComment = 'parameter measurements have been delayed mode adjuted using delayed mode adjusted profiles of the 2024-05 Argo GDAC monthly snapshot (http://doi.org/10.17882/42182#110199)';

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
if ~(exist(DIR_INPUT_NC_PROF_FILES, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s\n', DIR_INPUT_NC_PROF_FILES);
   return
end
if ~(exist(DIR_INPUT_NC_TRAJ_FILES, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s\n', DIR_INPUT_NC_TRAJ_FILES);
   return
end
if (GENERATE_OUTPUT_TRAJ_FLAG)
   if ~(exist(DIR_OUTPUT_NC_TRAJ_FILES, 'dir') == 7)
      fprintf('Creating output directory: %s\n', DIR_OUTPUT_NC_TRAJ_FILES);
      mkdir(DIR_OUTPUT_NC_TRAJ_FILES);
   end
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
   'Cy PSAL_ADJUSTED_QC=4'];
fprintf(fId, '%s\n', header);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process floats of the list

nbFloats = length(floatList);
for idFloat = 1:nbFloats

   g_decArgo_profCyNumList =[];

   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   inputProfFloatDir = [DIR_INPUT_NC_PROF_FILES '/' floatNumStr '/'];
   inputTrajFloatDir = [DIR_INPUT_NC_TRAJ_FILES '/' floatNumStr '/'];
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % retrieve float data from NetCDF files

   [dmCProfileData, cParamList, dmBProfileData, bParamList] = get_dm_profile_data(floatNum, inputProfFloatDir);
   if (isempty(dmCProfileData) && isempty(dmBProfileData))
      continue
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % concat primary and NS profiles and copy PRES data from core to BGC profiles

   [dmCProfileData, dmBProfileData] = concat_profile(floatNum, dmCProfileData, dmBProfileData);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % adjust traj data

   [trajFileName, trajDataAdj, traj2ProfCyNum] = adjust_traj_data(floatNum, inputTrajFloatDir, dmCProfileData, cParamList, dmBProfileData, bParamList);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % update traj file

   if (GENERATE_OUTPUT_TRAJ_FLAG)

      if (~isempty(trajFileName))

         % create global output diretory
         if ~(exist(DIR_OUTPUT_NC_TRAJ_FILES, 'dir') == 7)
            fprintf('Creating output directory: %s\n', DIR_OUTPUT_NC_TRAJ_FILES);
            mkdir(DIR_OUTPUT_NC_TRAJ_FILES);
         end

         % create float output diretory
         outputDir = [DIR_OUTPUT_NC_TRAJ_FILES '/' floatNumStr '/'];
         if ~(exist(outputDir, 'dir') == 7)
            mkdir(outputDir);
         end

         % make a copy of the TRAJ file in the float output diretory
         copy_file([inputTrajFloatDir trajFileName], outputDir);

         % update the file
         ok = generate_traj_dm_file([outputDir trajFileName], trajDataAdj, traj2ProfCyNum);
      else
         fprintf('WARNING: No TRAJ DM data\n');
      end
   end

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
   for measCode = mcList
      nbPsal = 0; % nombre total de mesures PSAL ajustées
      nbPsalAdjNoNan = 0; % nombre de mesures PSAL ajustées à ~FV
      nbPsalAdjNan = 0; % nombre de mesures PSAL ajustées à FV
      nbPsalAdjNull = 0; % nombre de mesures PSAL ajustées avec 0
      nbPsalAdjComp = 0; % nombre de mesures PSAL ajustées avec pcond_factor calculé
      allNanCyNumList = []; % liste des cycles avec données ajustées à FV

      idForMc = find([trajDataAdj.measCode] == measCode);
      for idL = idForMc
         traj = trajDataAdj(idL);
         idPsal = find(strcmp(traj.paramList, 'PSAL'));
         if (~isempty(idPsal))
            nbPsal = nbPsal + sum(~isnan(traj.data(:, idPsal)));
            nbPsalAdjNoNan = nbPsalAdjNoNan + sum(~isnan(traj.dataAdj(:, idPsal)));
            nbPsalAdjNan = nbPsalAdjNan + sum(isnan(traj.dataAdj(:, idPsal)));
            if (traj.paramAdjNull(idPsal) == 1)
               nbPsalAdjNull = nbPsalAdjNull + sum(~isnan(traj.dataAdj(:, idPsal)));
            elseif (traj.paramAdjNull(idPsal) == 0)
               nbPsalAdjComp = nbPsalAdjComp + sum(~isnan(traj.dataAdj(:, idPsal)));
            elseif (traj.paramAdjNull(idPsal) == -1)
               % adjusted with FV, already considered in nbPsalAdjNan = nbPsalAdjNan + sum(isnan(traj.dataAdj(:, idPsal)));
            else
               fprintf('ANOMALY\n');
            end
            if (all(isnan(traj.dataAdj(:, idPsal))))
               allNanCyNumList = cat(2, allNanCyNumList, traj.cycleNumber);
            end
         end
      end

      allNanCyNumListStr = '';
      if (~isempty(allNanCyNumList))
         allNanCyNumListStr = squeeze_list(unique(allNanCyNumList));
      end

      fprintf(fId, '%d;%s;%s;%s;%d;%d;%d;%d;%d;%s\n', ...
         floatNum, adjCoreCyNumListStr, adjTrajCyNumListStr, get_meas_code_name(measCode), ...
         nbPsal, nbPsalAdjNoNan, nbPsalAdjNan, nbPsalAdjNull, nbPsalAdjComp, ...
         allNanCyNumListStr);
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % adjusted TRAJ data

   if (GENERATE_OUTPUT_CSV_DETAILED_FLAG)

      % create output CSV file to report TRAJ adjustments
      csvFilepathName = [DIR_CSV_FILE '\check_traj_adj_param_meas_' floatNumStr '_' currentTime '.csv'];
      fId2 = fopen(csvFilepathName, 'wt');
      if (fId2 == -1)
         fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
         return
      end
      header = [ ...
         'WMO;CYCLE_NUMBER;MC;Meas#;' ...
         'Prev Prof JulD;Prev Prof pcond_fact;' ...
         'Cur Prof JulD;Cur Prof pcond_fact;' ...
         'Meas Juld;pcond_fact;Meas PSAL_ADJUSTED'];
      fprintf(fId2, '%s\n', header);

      trajCyNumList = unique([trajDataAdj.cycleNumber]);
      for cyNum = trajCyNumList

         idForCy = find([trajDataAdj.cycleNumber] == cyNum);
         mcList = unique([trajDataAdj(idForCy).measCode], 'stable');

         trajDataAdjCy = trajDataAdj(idForCy); % to be more efficient

         for measCode = mcList
            % idForMc = find(([trajDataAdj.cycleNumber] == cyNum) & ([trajDataAdj.measCode] == measCode));
            idForMc = idForCy(find([trajDataAdjCy.measCode] == measCode));

            for idT = idForMc
               traj = trajDataAdj(idT);

               idPsal = find(strcmp('PSAL', traj.paramList));

               if (~isempty(idPsal))
                  if ((traj.paramAdjNull(idPsal) == 0) && ~isempty(traj.pcondFactor))

                     for idM = 1:size(traj.data, 1)

                        if (~isempty(traj.profPrev))
                           fprintf(fId2, '%d;%d;%s;%d; %s;%.5f; %s;%.5f; %s;%.5f;%.4f\n', ...
                              floatNum, traj.cycleNumber, get_meas_code_name(traj.measCode), idM, ...
                              julian_2_gregorian_dec_argo(traj.profPrev.juld), ...
                              traj.profPrev.pcondFactor, ...
                              julian_2_gregorian_dec_argo(traj.profCur.juld), ...
                              traj.profCur.pcondFactor, ...
                              julian_2_gregorian_dec_argo(traj.timeData(idM)), ...
                              traj.pcondFactor(idM), traj.dataAdj(idM, idPsal));
                        else
                           fprintf(fId2, '%d;%d;%s;%d;;; %s;%.5f; %s;%.5f;%.4f\n', ...
                              floatNum, traj.cycleNumber, get_meas_code_name(traj.measCode), idM, ...
                              julian_2_gregorian_dec_argo(traj.profCur.juld), ...
                              traj.profCur.pcondFactor, ...
                              julian_2_gregorian_dec_argo(traj.timeData(idM)), ...
                              traj.pcondFactor(idM), traj.dataAdj(idM, idPsal));
                        end
                     end
                  end
               end
            end
         end
      end

      fclose(fId2);
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fclose(fId);

fprintf('List of MC with PSAL measurement:\n');
for mc = g_decArgo_psalMeasCodeList'
   fprintf(' - %s\n', get_meas_code_name(mc));
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Adjust trajectory measurements with profile DM data.
%
% SYNTAX :
% [o_trajFileName, o_trajDataAdj, o_traj2ProfCyNum] = ...
%   adjust_traj_data(a_floatNum, a_ncFileDir, a_dmCProfileData, a_cParamList, ...
%   a_dmBProfileData, a_bParamList)
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
%   o_trajFilePathName : input TRAJ file name
%   o_trajDataAdj      : DM adjusted TRAJ data
%   o_traj2ProfCyNum   : link between TRAJ and PROF cycle numbers
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/12/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_trajFileName, o_trajDataAdj, o_traj2ProfCyNum] = ...
   adjust_traj_data(a_floatNum, a_ncFileDir, a_dmCProfileData, a_cParamList, ...
   a_dmBProfileData, a_bParamList)

% output parameters initialization
o_trajFileName = [];
o_trajDataAdj = [];
o_traj2ProfCyNum = [];

% global measurement codes
global g_MC_FST;
global g_MC_SpyInDescToPark;
global g_MC_DescProf;
global g_MC_MaxPresInDescToPark;
global g_MC_DescProfDeepestBin;
global g_MC_SpyAtPark;
global g_MC_DriftAtPark;
global g_MC_MinPresInDriftAtPark;
global g_MC_MaxPresInDriftAtPark;
global g_MC_RPP;
global g_MC_SpyInDescToProf;
global g_MC_MaxPresInDescToProf;
global g_MC_SpyAtProf;
global g_MC_MinPresInDriftAtProf;
global g_MC_MaxPresInDriftAtProf;
global g_MC_AscProfDeepestBin;
global g_MC_SpyInAscProf;
global g_MC_AscProf;
global g_MC_LastAscPumpedCtd;
global g_MC_Grounded;

global g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;
global g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;

% QC flag values
global g_decArgo_qcStrDef;           % ' '
global g_decArgo_qcStrBad;           % '4'

% list of MC with PSAL measurement
global g_decArgo_psalMeasCodeList;


juldInfo = get_netcdf_param_attributes('JULD');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% retrieve data from trajectory file

trajFile = dir([a_ncFileDir sprintf('%d_Rtraj.nc', a_floatNum)]);
if (isempty(trajFile))
   fprintf('INFO: No trajectory file for float %d - ignored\n', ...
      a_floatNum);
   return
end
trajFileName = trajFile(1).name;
trajFilePathName = [a_ncFileDir trajFileName];

wantedVars = [ ...
   {'JULD'} ...
   {'JULD_ADJUSTED'} ...
   {'CYCLE_NUMBER'} ...
   {'MEASUREMENT_CODE'} ...
   {'JULD_DATA_MODE'} ...
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

juld = get_data_from_name('JULD', ncTrajData);
juldAdj = get_data_from_name('JULD_ADJUSTED', ncTrajData);
cycleNumber = get_data_from_name('CYCLE_NUMBER', ncTrajData);
measurementCode = get_data_from_name('MEASUREMENT_CODE', ncTrajData);
juldDataMode = get_data_from_name('JULD_DATA_MODE', ncTrajData);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute information to adjust traj data

TRAJ_DATA_ITEM = 5000;
trajDataAdjAll = repmat(cell(1, 10), TRAJ_DATA_ITEM, 1);
cptTrajDataAdjItem = 1;

% one loop for each set of profile data (core and BGC)
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

      if (prof.juld ~= juldInfo.fillValue)
         [minDiff, idMin] = min(abs(juldBest-prof.juld));
         if (minDiff ~= 0)
            fprintf('WARNING: Anomaly (PROF JulD not exactly in TRAJ, %f hours)\n', minDiff*24);
         end
         dmProfileData{idL, 4} = cycleNumber(idMin);
         if (profCyNum ~= cycleNumber(idMin))
            fprintf('WARNING: Anomaly (PROF cycle number (%d) and TRAJ cycle number (%d) differ)\n', profCyNum, cycleNumber(idMin));
         end
      else
         fprintf('WARNING: Profile #%d is not dated - not used in TRAJ adjustment\n', profCyNum);
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % process TRAJ cycle numbers

   trajCyNumList = unique([dmProfileData{:, 4}]);
   for cyNum = trajCyNumList

      if (isnan(cyNum))
         continue
      end

      % if (cyNum == 212)
      %    a=1
      % end

      % if we have a previous DM profile, we interpolate both pcond_factors at
      % the times of the park drift measurements
      % if not, we only use pcond_factor value to adjust the park drift measurements
      idPrev = '';
      idCur = find([dmProfileData{:, 4}] == cyNum);
      if (cyNum > 1)
         idPrev = find([dmProfileData{:, 4}] == cyNum-1);
      end

      if (~isempty(idPrev))
         profPrev = dmProfileData{idPrev, 3};
         profCur = dmProfileData{idCur, 3};
         paramList = intersect(profPrev.paramList, profCur.paramList, 'stable');
      else
         profPrev = '';
         profCur = dmProfileData{idCur, 3};
         paramList = profCur.paramList;
      end

      for idParam = 1:length(paramList)

         paramName = paramList{idParam};
         if ((idLoop == 2) && strcmp(paramName, 'PRES'))
            continue
         end

         trajParamData = get_data_from_name(paramName, ncTrajData);
         if (isempty(trajParamData))
            continue
         end

         % look for the measurements of the current param and current cycle
         paramInfo = get_netcdf_param_attributes(paramName);
         idNoDef = find((trajParamData ~= paramInfo.fillValue) & (cycleNumber == cyNum));
         if (~isempty(idNoDef))

            mcList = unique(measurementCode(idNoDef));

            if (strcmp('PSAL', paramName))
               g_decArgo_psalMeasCodeList = unique([g_decArgo_psalMeasCodeList; mcList]);
            end

            for measCode = mcList'

               % if (measCode == g_MC_AscProf)
               %    a=1
               % end

               switch (measCode)

                  case {g_MC_FST}
                     % MC managed by the ANDRO 2 TRAJ-DM tool

                  case {g_MC_DescProf, g_MC_DescProfDeepestBin}

                     % look for the DM descending profile
                     idCurDesc = find(([dmProfileData{:, 4}] == cyNum) & ([dmProfileData{:, 2}] == 1));
                     if (~isempty(idCurDesc))
                        profPrev2 = '';
                        profCur2 = dmProfileData{idCurDesc, 3};

                        % same as g_MC_AscProf
                        if (measCode == g_MC_DescProf)
                           idNoDef = find( ...
                              (juld ~= juldInfo.fillValue) & ... % juld and not juldBest because used to identify profile level
                              (trajParamData ~= paramInfo.fillValue) & ...
                              (cycleNumber == cyNum) & ...
                              (measurementCode == measCode));
                        else
                           idNoDef = find( ...
                              (trajParamData ~= paramInfo.fillValue) & ...
                              (cycleNumber == cyNum) & ...
                              (measurementCode == measCode));
                        end

                        pcondFactor = [];
                        switch paramName
                           case 'PRES'
                              paramAdjNull = profCur2.presAdjNullFlag;
                           case 'TEMP'
                              paramAdjNull = profCur2.tempAdjNullFlag;
                           case 'PSAL'
                              paramAdjNull = profCur2.psalAdjNullFlag;
                        end

                        trajDataAdj = [{cyNum} {paramName} {measCode} {idNoDef} {paramAdjNull} {pcondFactor} {profPrev2} {profCur2} {juld(idNoDef)} {double(trajParamData(idNoDef))}];
                        trajDataAdjAll(cptTrajDataAdjItem, :) = trajDataAdj;
                        cptTrajDataAdjItem = cptTrajDataAdjItem + 1;
                        if (cptTrajDataAdjItem > length(trajDataAdjAll))
                           trajDataAdjAll = cat(1, trajDataAdjAll, repmat(cell(1, 10), TRAJ_DATA_ITEM, 1));
                        end
                     end

                  case g_MC_DriftAtPark

                     if (~isempty(profPrev))
                        idNoDef = find( ...
                           (juldBest ~= juldInfo.fillValue) & ...
                           (trajParamData ~= paramInfo.fillValue) & ...
                           (cycleNumber == cyNum) & ...
                           (measurementCode == measCode));
                     else
                        idNoDef = find( ...
                           (trajParamData ~= paramInfo.fillValue) & ...
                           (cycleNumber == cyNum) & ...
                           (measurementCode == measCode));
                     end

                     [paramAdjNull, pcondFactor] = ...
                        interp_pcond(paramName, juldBest(idNoDef), ...
                        profPrev, profCur);

                     trajDataAdj = [{cyNum} {paramName} {measCode} {idNoDef} {paramAdjNull} {pcondFactor} {profPrev} {profCur} {juldBest(idNoDef)} {double(trajParamData(idNoDef))}];
                     trajDataAdjAll(cptTrajDataAdjItem, :) = trajDataAdj;
                     cptTrajDataAdjItem = cptTrajDataAdjItem + 1;
                     if (cptTrajDataAdjItem > length(trajDataAdjAll))
                        trajDataAdjAll = cat(1, trajDataAdjAll, repmat(cell(1, 10), TRAJ_DATA_ITEM, 1));
                     end

                  case {g_MC_AscProfDeepestBin, g_MC_AscProf, g_MC_LastAscPumpedCtd}

                     if (measCode == g_MC_AscProf)
                        idNoDef = find( ...
                           (juld ~= juldInfo.fillValue) & ... % juld and not juldBest because used to identify profile level
                           (trajParamData ~= paramInfo.fillValue) & ...
                           (cycleNumber == cyNum) & ...
                           (measurementCode == measCode));
                     else
                        idNoDef = find( ...
                           (trajParamData ~= paramInfo.fillValue) & ...
                           (cycleNumber == cyNum) & ...
                           (measurementCode == measCode));
                     end

                     pcondFactor = [];
                     switch paramName
                        case 'PRES'
                           paramAdjNull = profCur.presAdjNullFlag;
                        case 'TEMP'
                           paramAdjNull = profCur.tempAdjNullFlag;
                        case 'PSAL'
                           paramAdjNull = profCur.psalAdjNullFlag;
                           if (paramAdjNull == 0)
                              % for g_MC_LastAscPumpedCtd we use pcond_factor of the current cycle
                              pcondFactor = ones(length(idNoDef), 1)*profCur.pcondFactor;
                           end
                     end

                     trajDataAdj = [{cyNum} {paramName} {measCode} {idNoDef} {paramAdjNull} {pcondFactor} {profPrev} {profCur} {juld(idNoDef)} {double(trajParamData(idNoDef))}];
                     trajDataAdjAll(cptTrajDataAdjItem, :) = trajDataAdj;
                     cptTrajDataAdjItem = cptTrajDataAdjItem + 1;
                     if (cptTrajDataAdjItem > length(trajDataAdjAll))
                        trajDataAdjAll = cat(1, trajDataAdjAll, repmat(cell(1, 10), TRAJ_DATA_ITEM, 1));
                     end

                  case { ...
                        g_MC_MaxPresInDescToPark, ...
                        g_MC_MinPresInDriftAtPark, ...
                        g_MC_MaxPresInDriftAtPark, ...
                        g_MC_MaxPresInDescToProf, ...
                        g_MC_MinPresInDriftAtProf, ...
                        g_MC_MaxPresInDriftAtProf, ...
                        g_MC_SpyInDescToPark, ...
                        g_MC_SpyAtPark, ...
                        g_MC_SpyInDescToProf, ...
                        g_MC_SpyAtProf, ...
                        g_MC_SpyInAscProf, ...
                        g_MC_Grounded, ...
                        }
                     % MC managed by the ANDRO 2 TRAJ-DM tool

                  case g_MC_RPP

                  case g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST

                  case g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST

                  otherwise
                     fprintf('Not implement yet for MC = %d\n', measCode);
               end
            end
         end
      end
   end
end
trajDataAdjAll(cptTrajDataAdjItem:end, :) = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% adjust TRAJ data

TRAJ_DATA_ITEM = 5000;
trajDataAdjTab = repmat(get_dm_traj_init_struct, 1, TRAJ_DATA_ITEM);
cptTrajDataAdjItem = 1;

trajCyNumList = unique([trajDataAdjAll{:, 1}]);
for cyNum = trajCyNumList

   % if(cyNum == 212)
   %    a=1
   % end

   idForCy = find([trajDataAdjAll{:, 1}] == cyNum);
   mcList = unique([trajDataAdjAll{idForCy, 3}]);

   trajDataAdj = trajDataAdjAll(idForCy, :); % to be more efficient

   for measCode = mcList

      % if(measCode == g_MC_AscProf)
      %    a=1
      % end

      % idForMc = find(([trajDataAdjAll{:, 1}] == cyNum) & ([trajDataAdjAll{:, 3}] == measCode));
      idForMc = idForCy(find([trajDataAdj{:, 3}] == measCode));

      paramList = unique({trajDataAdjAll{idForMc, 2}}, 'stable');

      traj = get_dm_traj_init_struct;
      traj.cycleNumber = cyNum;
      traj.measCode = measCode;
      traj.paramList = paramList;
      traj.paramAdjNull = nan(size(paramList));
      traj.timeData = trajDataAdjAll{idForMc, 9};
      traj.data = [];
      traj.dataQc = [];
      traj.dataAdj = [];
      traj.dataAdjQc = [];
      traj.dataAdjErr = [];
      traj.profPrev = trajDataAdjAll{idForMc, 7};
      traj.profCur = trajDataAdjAll{idForMc, 8};

      for idP = 1:length(paramList)
         paramName = paramList{idP};
         % idF = find(([trajDataAdjAll{:, 1}] == cyNum) & strcmp({trajDataAdjAll{:, 2}}, paramName) & ([trajDataAdjAll{:, 3}] == measCode));
         idF = idForCy(find(strcmp({trajDataAdj{:, 2}}, paramName) & ([trajDataAdj{:, 3}] == measCode)));

         traj.paramAdjNull(idP) = trajDataAdjAll{idF, 5};
         if (isempty(traj.dataId))
            traj.dataId = trajDataAdjAll{idF, 4};
         else
            if (any(traj.dataId ~= trajDataAdjAll{idF, 4}))
               fprintf('ANOMALY\n');
            end
         end

         if (ismember(measCode, [g_MC_DescProf, g_MC_DescProfDeepestBin, g_MC_AscProfDeepestBin, g_MC_AscProf]))

            % in this case the levels should be present in the traj.profCur
            % profile

            if (traj.paramAdjNull(idP) == -1)
               traj.data = cat(2, traj.data, trajDataAdjAll{idF, end});
               traj.dataQc = cat(2, traj.dataQc, repmat(g_decArgo_qcStrBad, size(trajDataAdjAll{idF, end})));
               traj.dataAdj = cat(2, traj.dataAdj, nan(size(trajDataAdjAll{idF, end})));
               traj.dataAdjQc = cat(2, traj.dataAdjQc, repmat(g_decArgo_qcStrBad, size(trajDataAdjAll{idF, end})));
               traj.dataAdjErr = cat(2, traj.dataAdjErr, nan(size(trajDataAdjAll{idF, end})));
            else
               traj.data = cat(2, traj.data, trajDataAdjAll{idF, end});
               traj.dataQc = cat(2, traj.dataQc, repmat(g_decArgo_qcStrDef, size(trajDataAdjAll{idF, end})));
               traj.dataAdj = cat(2, traj.dataAdj, nan(size(trajDataAdjAll{idF, end})));
               traj.dataAdjQc = cat(2, traj.dataAdjQc, repmat(g_decArgo_qcStrDef, size(trajDataAdjAll{idF, end})));
               traj.dataAdjErr = cat(2, traj.dataAdjErr, nan(size(trajDataAdjAll{idF, end})));
            end

            if (strcmp(paramName, 'PSAL'))

               % retrieve the PTS measurement in the DM profile (using RT
               % values)
               profCur = traj.profCur;
               if (~isempty(trajDataAdjAll{idF, 9}) && ~isempty(profCur.timeData))
                  % use PTS + time measurement
                  profMeasStr = cell(size(profCur.data, 1), 1);
                  for idL = 1:size(profCur.data, 1)
                     profMeasStr{idL} = sprintf('%s %.1f %.3f %.3f', ...
                        julian_2_gregorian_dec_argo(profCur.timeData(idL)), ...
                        profCur.data(idL, 1), ...
                        profCur.data(idL, 2), ...
                        profCur.data(idL, 3));
                  end
                  trajMeasStr = cell(size(traj.data, 1), 1);
                  for idL = 1:size(traj.data, 1)
                     trajMeasStr{idL} = sprintf('%s %.1f %.3f %.3f', ...
                        julian_2_gregorian_dec_argo(traj.timeData(idL)), ...
                        traj.data(idL, 1), ...
                        traj.data(idL, 2), ...
                        traj.data(idL, 3));
                  end
               else
                  % use PTS only
                  profMeasStr = cell(size(profCur.data, 1), 1);
                  for idL = 1:size(profCur.data, 1)
                     profMeasStr{idL} = sprintf('%.1f %.3f %.3f', ...
                        profCur.data(idL, 1), ...
                        profCur.data(idL, 2), ...
                        profCur.data(idL, 3));
                  end
                  trajMeasStr = cell(size(traj.data, 1), 1);
                  for idL = 1:size(traj.data, 1)
                     trajMeasStr{idL} = sprintf('%.1f %.3f %.3f', ...
                        traj.data(idL, 1), ...
                        traj.data(idL, 2), ...
                        traj.data(idL, 3));
                  end
               end
               idDel = [];
               for idL = 1:size(traj.data, 1)
                  idLev = find(strcmp(trajMeasStr{idL}, profMeasStr));
                  if (length(idLev) == 1)
                     traj.dataQc(idL, :) = profCur.dataQc(idLev, :);
                     traj.dataAdj(idL, :) = profCur.dataAdj(idLev, :);
                     traj.dataAdjQc(idL, :) = profCur.dataAdjQc(idLev, :);
                     traj.dataAdjErr(idL, :) = profCur.dataAdjErr(idLev, :);
                  else
                     % if the level is not found, we don't adjust
                     % PSAL
                     idDel = [idDel; idL];
                  end
               end
               if (~isempty(idDel))
                  traj.dataId(idDel) = [];
                  if (~isempty(traj.dataId))
                     if (~isempty(traj.timeData))
                        traj.timeData(idDel) = [];
                     end
                     traj.data(idDel, :) = [];
                     traj.dataQc(idDel, :) = [];
                     traj.dataAdj(idDel, :) = [];
                     traj.dataAdjQc(idDel, :) = [];
                     traj.dataAdjErr(idDel, :) = [];
                  else
                     traj = [];
                  end
               end
            end

         else

            switch paramName
               case {'PRES', 'TEMP'}

                  if (traj.paramAdjNull(idP) == -1)
                     traj.data = cat(2, traj.data, trajDataAdjAll{idF, end});
                     traj.dataQc = cat(2, traj.dataQc, repmat(g_decArgo_qcStrBad, size(trajDataAdjAll{idF, end})));
                     traj.dataAdj = cat(2, traj.dataAdj, nan(size(trajDataAdjAll{idF, end})));
                     traj.dataAdjQc = cat(2, traj.dataAdjQc, repmat(g_decArgo_qcStrBad, size(trajDataAdjAll{idF, end})));
                     traj.dataAdjErr = cat(2, traj.dataAdjErr, nan(size(trajDataAdjAll{idF, end})));
                  elseif (traj.paramAdjNull(idP) == 1)
                     traj.data = cat(2, traj.data, trajDataAdjAll{idF, end});
                     traj.dataQc = cat(2, traj.dataQc, repmat(g_decArgo_qcStrDef, size(trajDataAdjAll{idF, end})));
                     traj.dataAdj = cat(2, traj.dataAdj, trajDataAdjAll{idF, end});
                     if (strcmp(paramName, 'PRES'))
                        profAdj = traj.profCur.dataAdj(:, 1);
                        profAdjQc = traj.profCur.dataAdjQc(:, 1);
                        dataAdjErr = traj.profCur.dataAdjErr(:, 1);
                     else
                        profAdj = traj.profCur.dataAdj(:, 2);
                        profAdjQc = traj.profCur.dataAdjQc(:, 2);
                        dataAdjErr = traj.profCur.dataAdjErr(:, 2);
                     end
                     % estimate QC of adj values
                     adjQcVal = estimate_adj_qc(profAdj, profAdjQc);
                     traj.dataAdjQc = cat(2, traj.dataAdjQc, repmat(adjQcVal, size(trajDataAdjAll{idF, end})));
                     dataAdjErr(isnan(dataAdjErr)) = [];
                     dataAdjErr = max(unique(dataAdjErr));
                     traj.dataAdjErr = cat(2, traj.dataAdjErr, ones(size(trajDataAdjAll{idF, end}))*dataAdjErr);
                  else
                     fprintf('ANOMALY\n');
                  end

               case 'PSAL'

                  if (traj.paramAdjNull(idP) == -1)
                     traj.data = cat(2, traj.data, trajDataAdjAll{idF, end});
                     traj.dataQc = cat(2, traj.dataQc, repmat(g_decArgo_qcStrBad, size(trajDataAdjAll{idF, end})));
                     traj.dataAdj = cat(2, traj.dataAdj, nan(size(trajDataAdjAll{idF, end})));
                     traj.dataAdjQc = cat(2, traj.dataAdjQc, repmat(g_decArgo_qcStrBad, size(trajDataAdjAll{idF, end})));
                     traj.dataAdjErr = cat(2, traj.dataAdjErr, nan(size(trajDataAdjAll{idF, end})));
                  elseif (traj.paramAdjNull(idP) == 1)
                     traj.data = cat(2, traj.data, trajDataAdjAll{idF, end});
                     traj.dataQc = cat(2, traj.dataQc, repmat(g_decArgo_qcStrDef, size(trajDataAdjAll{idF, end})));
                     traj.dataAdj = cat(2, traj.dataAdj, trajDataAdjAll{idF, end});
                     % estimate QC of adj values
                     profAdj = traj.profCur.dataAdj(:, 3);
                     profAdjQc = traj.profCur.dataAdjQc(:, 3);
                     adjQcVal = estimate_adj_qc(profAdj, profAdjQc);
                     traj.dataAdjQc = cat(2, traj.dataAdjQc, repmat(adjQcVal, size(trajDataAdjAll{idF, end})));
                     dataAdjErr = traj.profCur.dataAdjErr(:, 3);
                     dataAdjErr(isnan(dataAdjErr)) = [];
                     dataAdjErr = max(unique(dataAdjErr));
                     traj.dataAdjErr = cat(2, traj.dataAdjErr, ones(size(trajDataAdjAll{idF, end}))*dataAdjErr);
                  else

                     % PSAL need to be adjusted with not null values
                     switch (measCode)

                        case {g_MC_DriftAtPark, g_MC_LastAscPumpedCtd}

                           % adjust PSAL with pcond_factor stored in trajDataAdjAll

                           traj.pcondFactor = trajDataAdjAll{idF, 6};
                           traj.data = cat(2, traj.data, trajDataAdjAll{idF, end});
                           traj.dataQc = cat(2, traj.dataQc, repmat(g_decArgo_qcStrDef, size(trajDataAdjAll{idF, end})));
                           traj.dataAdj = cat(2, traj.dataAdj, nan(size(trajDataAdjAll{idF, end})));
                           % estimate QC of adj values
                           profAdj = traj.profCur.dataAdj(:, 3);
                           profAdjQc = traj.profCur.dataAdjQc(:, 3);
                           adjQcVal = estimate_adj_qc(profAdj, profAdjQc);
                           traj.dataAdjQc = cat(2, traj.dataAdjQc, repmat(adjQcVal, size(trajDataAdjAll{idF, end})));
                           dataAdjErr = traj.profCur.dataAdjErr(:, 3);
                           dataAdjErr(isnan(dataAdjErr)) = [];
                           dataAdjErr = max(unique(dataAdjErr));
                           traj.dataAdjErr = cat(2, traj.dataAdjErr, ones(size(trajDataAdjAll{idF, end}))*dataAdjErr);

                           if (~isnan(traj.pcondFactor))
                              idPres = find(strcmp(traj.paramList, 'PRES'));
                              idTemp = find(strcmp(traj.paramList, 'TEMP'));
                              idPsal = find(strcmp(traj.paramList, 'PSAL'));
                              if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal))

                                 pres = traj.data(:, idPres);
                                 presAdjusted = traj.dataAdj(:, idPres);
                                 temp = traj.data(:, idTemp);
                                 tempAdjusted = traj.dataAdj(:, idTemp);
                                 psal = traj.data(:, idPsal);

                                 % compute psalAdj
                                 idNoNan = find(~isnan(pres) & ~isnan(presAdjusted) & ...
                                    ~isnan(temp) & ~isnan(tempAdjusted) & ~isnan(psal));
                                 cndcRaw = sw_cndr(psal(idNoNan), temp(idNoNan), pres(idNoNan));
                                 psalAdjInt = sw_salt(cndcRaw, tempAdjusted(idNoNan), presAdjusted(idNoNan));
                                 ptmp = sw_ptmp(psalAdjInt, tempAdjusted(idNoNan), presAdjusted(idNoNan), 0);
                                 cndc = sw_c3515*sw_cndr(psalAdjInt, ptmp, 0);
                                 calCndc = traj.pcondFactor.*cndc;
                                 psalAdj = sw_salt(calCndc/sw_c3515, ptmp, 0);
                                 traj.dataAdj(idNoNan, idPsal) = psalAdj;
                              end
                           end

                        case g_MC_RPP
                           traj = [];

                        case g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST
                           traj = [];

                        case g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST
                           traj = [];

                        otherwise
                           fprintf('Not implement yet for MC = %d\n', measCode);

                     end
                  end

               otherwise
                  traj = [];
                  fprintf('ANOMALY\n');
            end
         end
      end
      if (~isempty(traj))
         trajDataAdjTab(cptTrajDataAdjItem) = traj;
         cptTrajDataAdjItem = cptTrajDataAdjItem + 1;
         if (cptTrajDataAdjItem > length(trajDataAdjTab))
            trajDataAdjTab = cat(2, trajDataAdjTab, repmat(get_dm_traj_init_struct, 1, TRAJ_DATA_ITEM));
         end
      end
   end
end
trajDataAdjTab(cptTrajDataAdjItem:end) = [];

if (~isempty(trajDataAdjTab))
   o_trajFileName = trajFileName;
   o_trajDataAdj = trajDataAdjTab;
   o_traj2ProfCyNum = [[dmProfileData{:, 4}]' [dmProfileData{:, 1}]'];
end

return

% ------------------------------------------------------------------------------
% Time interpolation of pconf_factor from 2 surrounding profiles.
%
% SYNTAX :
% [o_paramAdjNull, o_pcondFactor] = ...
%   interp_pcond(a_paramName, a_juldTrajData, a_profPrev, a_profCur)
%
% INPUT PARAMETERS :
%   a_paramName     : parameter name
%   a_juldTrajData  : times to interpolate
%   a_profPrev      : previous profile data structure
%   a_profCur       : current profile data structure
%
% OUTPUT PARAMETERS :
%   o_paramAdjNull : 1 if parameter is adjusted with 0 values, 0 otherwise
%   o_pcondFactor  : pcond_factor interpolated values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/18/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_paramAdjNull, o_pcondFactor] = ...
   interp_pcond(a_paramName, a_juldTrajData, a_profPrev, a_profCur)

% output parameters initialization
o_paramAdjNull = '';
o_pcondFactor = [];

% QC flag values
global g_decArgo_qcStrGood;          % '1'
global g_decArgo_qcStrProbablyGood;  % '2'

% list of profile cycle numbers
global g_decArgo_profCyNumList;


switch a_paramName
   case 'PRES'
      o_paramAdjNull = a_profCur.presAdjNullFlag;
   case 'TEMP'
      o_paramAdjNull = a_profCur.tempAdjNullFlag;
   case 'PSAL'
      if (~isempty(a_profPrev))
         if (a_profCur.psalAdjNullFlag == -1) % adjusted with nan values
            o_paramAdjNull = -1;
         else
            if ((a_profPrev.psalAdjNullFlag == 1) && (a_profCur.psalAdjNullFlag == 1))
               o_paramAdjNull = 1;
            else
               o_paramAdjNull = 0;

               % interpolate pcondFactor according to traj measurement times
               if (((a_profPrev.juldQc == g_decArgo_qcStrGood) || (a_profPrev.juldQc == g_decArgo_qcStrProbablyGood)) && ...
                     ((a_profCur.juldQc == g_decArgo_qcStrGood) || (a_profCur.juldQc == g_decArgo_qcStrProbablyGood)))
                  if (~isnan(a_profPrev.pcondFactor) && ~isnan(a_profCur.pcondFactor))
                     o_pcondFactor = interp1( ...
                        [a_profPrev.juld; a_profCur.juld], ...
                        [a_profPrev.pcondFactor; a_profCur.pcondFactor], a_juldTrajData, 'linear');
                     g_decArgo_profCyNumList = [g_decArgo_profCyNumList a_profPrev.cycleNumber a_profCur.cycleNumber];
                  end
               end
            end
         end
      else
         o_paramAdjNull = a_profCur.psalAdjNullFlag;
         if (o_paramAdjNull == 0)
            o_pcondFactor = ones(length(a_juldTrajData), 1)*a_profCur.pcondFactor;
         end
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
                  bProf.dataAdErr(:, idPresB) = cProf.dataAdjErr(:, idPresC);
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
      profPrim.dataAdjErr = cat(1, profNs.dataAdjErr(measId, :), profPrim.dataAdjErr);
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
         profPrim.dataAdjErr = cat(1, profNs.dataAdjErr(measId, :), profPrim.dataAdjErr);
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
                  bProf.dataAdjErr(:, idPresB) = cProf.dataAdjErr(:, idPresC);
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
%   get_dm_profile_data(a_floatNum, a_ncFileDir)
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
   get_dm_profile_data(a_floatNum, a_ncFileDir)

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

profDirName = [a_ncFileDir 'profiles/'];
if ~(exist(profDirName, 'dir') == 7)
   fprintf('INFO: Float %d: Directory not found: %s\n', ...
      a_floatNum, profDirName);
   return
end

mtimeInfo = get_netcdf_param_attributes('MTIME');
juldInfo = get_netcdf_param_attributes('JULD');

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
         {'VERTICAL_SAMPLING_SCHEME'} ...
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
                           {[paramName '_ADJUSTED']} {[paramName '_ADJUSTED_QC']} {[paramName '_ADJUSTED_ERROR']} ...
                           ];
                     end
                  else
                     if (~ismember(paramName, wantedVars))
                        wantedVars = [wantedVars ...
                           {paramName} {[paramName '_QC']} ...
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
      vertSampScheme = get_data_from_name('VERTICAL_SAMPLING_SCHEME', ncData);

      for idProf = 1:nProf
         if ((dataMode(idProf) == 'D') || ~isempty(floatBFiles))

            prof = get_dm_prof_init_struct;
            prof.proId = idProf;
            prof.cycleNumber = cycleNumber(idProf);
            profDir = 2;
            if (direction(idProf) == 'D')
               profDir = 1;
            end
            prof.direction = profDir;
            prof.dataMode = dataMode(idProf);
            prof.juld = juld(idProf);
            prof.juldQc = juldQc(idProf);
            prof.vss = vertSampScheme(:, idProf)';

            data = [];
            dataQc = [];
            dataAdj = [];
            dataAdjQc = [];
            dataAdjErr = [];

            paramList = [];
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
                        dataAdjErr = nan(length(paramData), length(paramListAll{idProf}));
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

                     paramDataAdjErrAll = get_data_from_name([paramName '_ADJUSTED_ERROR'], ncData);
                     paramDataAdjErr = paramDataAdjErrAll(:, idProf);
                     paramDataAdjErr(paramDataAdjErr == paramInfo.fillValue) = nan;
                     dataAdjErr(:, col) = paramDataAdjErr;

                     col = col + 1;
                  end
               end
            end

            if (all(isnan(data)))
               % to cope with inconsistencies in DATA_MODE
               continue
            end

            mTimeData = get_data_from_name('MTIME', ncData);
            if (~isempty(mTimeData))
               mTimeData = mTimeData(:, idProf);
               if (any(mTimeData ~= mtimeInfo.fillValue) && (prof.juld ~= juldInfo.fillValue))
                  timeData = nan(size(mTimeData));
                  timeData(mTimeData ~= mtimeInfo.fillValue) = mTimeData(mTimeData ~= mtimeInfo.fillValue) + prof.juld;
                  prof.timeData = timeData;
               end
            end

            % keep only PRES, TEMP and PSAL parameters
            idPres = find(strcmp('PRES', paramList));
            idTemp = find(strcmp('TEMP', paramList));
            idPsal = find(strcmp('PSAL', paramList));
            if (isempty(idPres) || isempty(idTemp) || isempty(idPsal))
               fprintf('ANOMALY\n');
               continue
            end

            prof.paramList = paramList([idPres idTemp idPsal]);
            prof.data = data(:, [idPres idTemp idPsal]);
            prof.dataQc = dataQc(:, [idPres idTemp idPsal]);
            prof.dataAdj = dataAdj(:, [idPres idTemp idPsal]);
            prof.dataAdjQc = dataAdjQc(:, [idPres idTemp idPsal]);
            prof.dataAdjErr = dataAdjErr(:, [idPres idTemp idPsal]);

            if (prof.dataMode == 'D')
               % compute pcond_factor
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
         {'VERTICAL_SAMPLING_SCHEME'} ...
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
      vertSampScheme = get_data_from_name('VERTICAL_SAMPLING_SCHEME', ncData);

      for idProf = 1:nProf
         if (length(paramListAll{idProf}) > 1)
            if (dataMode(idProf) == 'D')
               % temporary ignore descent profile (because they are not used yet)
               if (direction(idProf) == 'D')
                  continue
               end

               prof = get_dm_prof_init_struct;
               prof.proId = idProf;
               prof.cycleNumber = cycleNumber(idProf);
               profDir = 2;
               if (direction(idProf) == 'D')
                  profDir = 1;
               end
               prof.direction = profDir;
               prof.dataMode = dataMode(idProf);
               prof.juld = juld(idProf);
               prof.juldQc = juldQc(idProf);
               prof.vss = vertSampScheme(:, idProf)';

               data = [];
               dataQc = [];
               dataAdj = [];
               dataAdjQc = [];
               dataAdjErr = [];

               paramList = [];
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
                           dataAdjErr = nan(length(paramData), length(paramListAll{idProf}));
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

                           paramDataAdjErrAll = get_data_from_name([paramName '_ADJUSTED_ERROR'], ncData);
                           paramDataAdjErr = paramDataAdjErrAll(:, idProf);
                           paramDataAdjErr(paramDataAdjErr == paramInfo.fillValue) = nan;
                           dataAdjErr(:, col) = paramDataAdjErr;
                        end
                        col = col + 1;
                     end
                  end
               end

               if (all(isnan(data)))
                  % to cope with inconsistencies in DATA_MODE
                  continue
               end

               prof.paramList = paramList;
               prof.data = data;
               prof.dataQc = dataQc;
               prof.dataAdj = dataAdj;
               prof.dataAdjQc = dataAdjQc;
               prof.dataAdjErr = dataAdjErr;

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
% Compute pcond_factor from profile data.
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


% retrieve PRES, TEMP and PSAL data
pres = o_profStruct.data(:, 1);
presAdjusted = o_profStruct.dataAdj(:, 1);
temp = o_profStruct.data(:, 2);
tempAdjusted = o_profStruct.dataAdj(:, 2);
psal = o_profStruct.data(:, 3);
psalAdjusted = o_profStruct.dataAdj(:, 3);

% check that PRES_ADJSUTED = PRES
if (any(~isnan(presAdjusted)))
   idNoNan = find(~isnan(presAdjusted) & ~isnan(pres));
   if (any(presAdjusted(idNoNan) ~= pres(idNoNan)))
      fprintf('ERROR: PRES adjustment not null\n');
      o_profStruct.presAdjNullFlag = 0;
   else
      o_profStruct.presAdjNullFlag = 1;
   end
else
   o_profStruct.presAdjNullFlag = -1; % adjusted with nan values
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
else
   o_profStruct.tempAdjNullFlag = -1; % adjusted with nan values
end

% check that PSAL_ADJSUTED = PSAL or estimate pcond_factor
if (any(~isnan(psalAdjusted)))
   idNoNan = find(~isnan(psalAdjusted) & ~isnan(psal));
   if (any(psalAdjusted(idNoNan) ~= psal(idNoNan)))

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

      o_profStruct.pcondFactor = pcondFactor;
      o_profStruct.psalAdjNullFlag = 0;
   else
      o_profStruct.pcondFactor = 1;
      o_profStruct.psalAdjNullFlag = 1;
   end
else
   o_profStruct.psalAdjNullFlag = -1; % adjusted with nan values
end

return

% ------------------------------------------------------------------------------
% Generate a new trajectory file with DM adjusted data.
%
% SYNTAX :
% [o_ok] = generate_traj_dm_file(a_trajFileName, a_trajDataAdj, a_traj2ProfCyNum)
%
% INPUT PARAMETERS :
%   a_trajFileName   : trajectory file path name
%   a_trajDataAdj    : DM adjusted TRAJ data
%   a_traj2ProfCyNum : link between TRAJ and PROF cycle numbers
%
% OUTPUT PARAMETERS :
%   o_ok : ok flag (1 if in the generation succeeded, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/20/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = generate_traj_dm_file(a_trajFileName, a_trajDataAdj, a_traj2ProfCyNum)

% output parameters initialization
o_ok = 0;

% current tool version
global g_decArgo_adjustTrajDmMeasVersion

% comment for SCIENTIFIC_CALIB_COMMENT
global g_decArgo_scientificCalibComment

% global measurement codes
global g_MC_FST;
global g_MC_SpyInDescToPark;
global g_MC_DescProf;
global g_MC_MaxPresInDescToPark;
global g_MC_DescProfDeepestBin;
global g_MC_SpyAtPark;
global g_MC_DriftAtPark;
global g_MC_MinPresInDriftAtPark;
global g_MC_MaxPresInDriftAtPark;
global g_MC_RPP;
global g_MC_SpyInDescToProf;
global g_MC_MaxPresInDescToProf;
global g_MC_SpyAtProf;
global g_MC_MinPresInDriftAtProf;
global g_MC_MaxPresInDriftAtProf;
global g_MC_AscProfDeepestBin;
global g_MC_SpyInAscProf;
global g_MC_AscProf;
global g_MC_LastAscPumpedCtd;
global g_MC_Grounded;

global g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;
global g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;

% QC flag values
global g_decArgo_qcStrDef;           % ' '
global g_decArgo_qcStrBad;           % '4'


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update N_HISTORY and N_CALIB_PARAM  dimensions

ok = update_dim_in_traj_file(a_trajFileName);
if (~ok)
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% rename TRAJ file

[filePath, trajFileName, fileExtension] = fileparts(a_trajFileName);
if (any(strfind(trajFileName, 'R')))
   trajFileNameNew = regexprep(trajFileName, 'R', 'D');
   move_file(a_trajFileName, [filePath '/' trajFileNameNew fileExtension]);
   trajFileName = [trajFileNameNew fileExtension];
   trajFilePathName = [filePath '/' trajFileName];
else
   trajFileName = [trajFileName fileExtension];
   trajFilePathName = a_trajFileName;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update TRAJ file data

presInfo = get_netcdf_param_attributes('PRES');
tempInfo = get_netcdf_param_attributes('TEMP');
psalInfo = get_netcdf_param_attributes('PSAL');

% open the file to update
fCdf = netcdf.open(trajFilePathName, 'NC_WRITE');
if (isempty(fCdf))
   fprintf('ERROR: Unable to open NetCDF file: %s\n', trajFilePathName);
   return
end

try

   trajParam = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TRAJECTORY_PARAMETERS')); % TRAJECTORY_PARAMETERS(N_PARAM, STRING64)

   cycleNumber = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'CYCLE_NUMBER')); % CYCLE_NUMBER(N_MEASUREMENT)
   cycleNumberAdj = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'CYCLE_NUMBER_ADJUSTED')); % CYCLE_NUMBER_ADJUSTED(N_MEASUREMENT)
   trajParamDataMode = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TRAJECTORY_PARAMETER_DATA_MODE')); % TRAJECTORY_PARAMETER_DATA_MODE(N_MEASUREMENT, N_PARAM)
   juldDataMode = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_DATA_MODE')); % JULD_DATA_MODE(N_MEASUREMENT)

   dataMode = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_MODE')); % DATA_MODE(N_ CYCLE)
   cycleNumberIndex = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'CYCLE_NUMBER_INDEX')); % CYCLE_NUMBER_INDEX(N_CYCLE)
   cycleNumberIndexAdj = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'CYCLE_NUMBER_INDEX_ADJUSTED')); % CYCLE_NUMBER_INDEX_ADJUSTED(N_CYCLE)

   presData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PRES'));
   presQcData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PRES_QC'));
   presAdjData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PRES_ADJUSTED'));
   presAdjQcData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PRES_ADJUSTED_QC'));
   presAdjErrData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PRES_ADJUSTED_ERROR'));
   tempData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TEMP'));
   tempQcData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TEMP_QC'));
   tempAdjData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TEMP_ADJUSTED'));
   tempAdjQcData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TEMP_ADJUSTED_QC'));
   tempAdjErrData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'TEMP_ADJUSTED_ERROR'));
   psalData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PSAL'));
   psalQcData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PSAL_QC'));
   psalAdjData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PSAL_ADJUSTED'));
   psalAdjQcData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PSAL_ADJUSTED_QC'));
   psalAdjErrData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PSAL_ADJUSTED_ERROR'));

   % retrieve N_PARAM Id of each parameter
   [~, nParam] = size(trajParam);
   presParamId = nan;
   tempParamId = nan;
   psalParamId = nan;
   for idParam = 1:nParam
      paramName = deblank(trajParam(:, idParam)');
      if (~isempty(paramName))
         if (strcmp(paramName, 'PRES'))
            presParamId = idParam;
         elseif (strcmp(paramName, 'TEMP'))
            tempParamId = idParam;
         elseif (strcmp(paramName, 'PSAL'))
            psalParamId = idParam;
         end
      end
   end

   mcList = unique([a_trajDataAdj.measCode]);
   for measCode = mcList
      idForMc = find([a_trajDataAdj.measCode] == measCode);

      for idT = idForMc
         traj = a_trajDataAdj(idT);

         % if (traj.cycleNumber == 44) && (traj.measCode == 590)
         %    a=1
         % end

         switch (measCode)

            case { ...
                  g_MC_DescProf, ...
                  g_MC_DescProfDeepestBin, ...
                  g_MC_DriftAtPark, ...
                  g_MC_AscProfDeepestBin, ...
                  g_MC_AscProf, ...
                  g_MC_LastAscPumpedCtd, ...
                  }

               if (size(traj.data, 2) ~= 3)
                  fprintf('ANOMALY\n');
                  continue
               end
               if (any(presData(traj.dataId) ~= traj.data(:, 1)) || ...
                     any(tempData(traj.dataId) ~= traj.data(:, 2)) || ...
                     any(psalData(traj.dataId) ~= traj.data(:, 3)))
                  fprintf('ANOMALY\n');
                  continue
               end

               for idP = 1:3
                  if (idP == 1)
                     paramInfo = presInfo;
                     paramId = presParamId;
                     paramQcData = presQcData;
                     paramAdjData = presAdjData;
                     paramAdjQcData = presAdjQcData;
                     paramAdjErrData = presAdjErrData;
                  elseif (idP == 2)
                     paramInfo = tempInfo;
                     paramId = tempParamId;
                     paramQcData = tempQcData;
                     paramAdjData = tempAdjData;
                     paramAdjQcData = tempAdjQcData;
                     paramAdjErrData = tempAdjErrData;
                  elseif (idP == 3)
                     paramInfo = psalInfo;
                     paramId = psalParamId;
                     paramQcData = psalQcData;
                     paramAdjData = psalAdjData;
                     paramAdjQcData = psalAdjQcData;
                     paramAdjErrData = psalAdjErrData;
                  end

                  dataParamQc = traj.dataQc(:, idP);
                  if (all(dataParamQc ~= g_decArgo_qcStrDef))
                     paramQcData(traj.dataId) = dataParamQc;
                  end

                  dataParamAdj = traj.dataAdj(:, idP);
                  idNan = find(isnan(dataParamAdj));
                  dataParamAdj(idNan) = paramInfo.fillValue;
                  paramAdjData(traj.dataId) = dataParamAdj;

                  dataParamAdjQc = traj.dataAdjQc(:, idP);
                  if (all(dataParamAdjQc ~= g_decArgo_qcStrDef))
                     paramAdjQcData(traj.dataId) = dataParamAdjQc;
                  end

                  dataParamAdjErr = traj.dataAdjErr(:, idP);
                  dataParamAdjErr(isnan(dataParamAdjErr)) = paramInfo.fillValue;
                  paramAdjErrData(traj.dataId) = dataParamAdjErr;

                  if (~isempty(idNan))
                     paramQcData(traj.dataId(idNan)) = g_decArgo_qcStrBad;
                     paramAdjQcData(traj.dataId(idNan)) = g_decArgo_qcStrBad;
                     paramAdjErrData(traj.dataId(idNan)) = paramInfo.fillValue;
                  end

                  trajParamDataMode(paramId, traj.dataId) = 'D';

                  if (idP == 1)
                     presQcData = paramQcData;
                     presAdjData = paramAdjData;
                     presAdjQcData = paramAdjQcData;
                     presAdjErrData = paramAdjErrData;
                  elseif (idP == 2)
                     tempQcData = paramQcData;
                     tempAdjData = paramAdjData;
                     tempAdjQcData = paramAdjQcData;
                     tempAdjErrData = paramAdjErrData;
                  elseif (idP == 3)
                     psalQcData = paramQcData;
                     psalAdjData = paramAdjData;
                     psalAdjQcData = paramAdjQcData;
                     psalAdjErrData = paramAdjErrData;
                  end
               end

            case { ...
                  g_MC_FST, ...
                  g_MC_MaxPresInDescToPark, ...
                  g_MC_MinPresInDriftAtPark, ...
                  g_MC_MaxPresInDriftAtPark, ...
                  g_MC_MaxPresInDescToProf, ...
                  g_MC_MinPresInDriftAtProf, ...
                  g_MC_MaxPresInDriftAtProf, ...
                  g_MC_SpyInDescToPark, ...
                  g_MC_SpyAtPark, ...
                  g_MC_SpyInDescToProf, ...
                  g_MC_SpyAtProf, ...
                  g_MC_SpyInAscProf, ...
                  g_MC_Grounded, ...
                  }

               % MC managed by the ANDRO 2 TRAJ-DM tool

               % if (size(traj.data, 2) ~= 1)
               %    fprintf('ANOMALY\n');
               %    continue
               % end
               % if (any(presData(traj.dataId) ~= traj.data(:, 1)))
               %    fprintf('ANOMALY\n');
               %    continue
               % end
               %
               % dataPresQc = traj.dataQc(:, 1);
               % if (all(dataPresQc ~= g_decArgo_qcStrDef))
               %    presQcData(traj.dataId) = dataPresQc;
               % end
               %
               % dataPresAdj = traj.dataAdj(:, 1);
               % idNan = find(isnan(dataPresAdj));
               % dataPresAdj(idNan) = presInfo.fillValue;
               % presAdjData(traj.dataId) = dataPresAdj;
               %
               % dataPresAdjQc = traj.dataAdjQc(:, 1);
               % if (all(dataPresAdjQc ~= g_decArgo_qcStrDef))
               %    presAdjQcData(traj.dataId) = dataPresAdjQc;
               % end
               %
               % dataPresAdjErr = traj.dataAdjErr(:, 1);
               % dataPresAdjErr(isnan(dataPresAdjErr)) = presInfo.fillValue;
               % presAdjErrData(traj.dataId) = dataPresAdjErr;
               %
               % if (~isempty(idNan))
               %    presQcData(traj.dataId(idNan)) = g_decArgo_qcStrBad;
               %    presAdjQcData(traj.dataId(idNan)) = g_decArgo_qcStrBad;
               %    presAdjErrData(traj.dataId(idNan)) = presInfo.fillValue;
               % end
               %
               % trajParamDataMode(presParamId, traj.dataId) = 'D';

            case g_MC_RPP

            case g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST

            case g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST

            otherwise
               fprintf('Not implement yet for MC = %d\n', measCode);
         end
      end
   end

   % update CYCLE_ADJUSTED, CYCLE_NUMBER_INDEX_ADJUSTED and DATA_MODE
   for idCy = 1:length(dataMode)
      profCyNum = cycleNumberIndex(idCy);
      idF = find(a_traj2ProfCyNum(:, 2) == profCyNum);
      if (~isempty(idF))
         trajCyNum = unique(a_traj2ProfCyNum(idF, 2));
         idForCy = find(cycleNumber == profCyNum);
         if (any(juldDataMode(idForCy) == 'D') || any(any(trajParamDataMode(:, idForCy) == 'D')))
            cycleNumberIndexAdj(idCy) = trajCyNum;
            cycleNumberAdj(idForCy) = trajCyNum;
            dataMode(idCy) = 'D';
         end
      end
   end

   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'CYCLE_NUMBER_ADJUSTED'), cycleNumberAdj);
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'TRAJECTORY_PARAMETER_DATA_MODE'), trajParamDataMode);
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_MODE'), dataMode);
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'CYCLE_NUMBER_INDEX_ADJUSTED'), cycleNumberIndexAdj);

   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PRES_QC'), presQcData);
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PRES_ADJUSTED'), presAdjData);
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PRES_ADJUSTED_QC'), presAdjQcData);
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PRES_ADJUSTED_ERROR'), presAdjErrData);

   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'TEMP_QC'), tempQcData);
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'TEMP_ADJUSTED'), tempAdjData);
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'TEMP_ADJUSTED_QC'), tempAdjQcData);
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'TEMP_ADJUSTED_ERROR'), tempAdjErrData);

   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PSAL_QC'), psalQcData);
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PSAL_ADJUSTED'), psalAdjData);
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PSAL_ADJUSTED_QC'), psalAdjQcData);
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PSAL_ADJUSTED_ERROR'), psalAdjErrData);

   % update HISTORY information

   % add history information that concerns the current program
   historyInstitution = 'IF';
   historyStep = 'ARSQ';
   historySoftware = 'COAM';
   historySoftwareRelease = g_decArgo_adjustTrajDmMeasVersion;
   historyDate = datestr(now_utc, 'yyyymmddHHMMSS');

   [~, nHistory] = netcdf.inqDim(fCdf, netcdf.inqDimID(fCdf, 'N_HISTORY'));
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'), ...
      fliplr([nHistory-1 0]), fliplr([1 length(historyInstitution)]), historyInstitution');
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_STEP'), ...
      fliplr([nHistory-1 0]), fliplr([1 length(historyStep)]), historyStep');
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE'), ...
      fliplr([nHistory-1 0]), fliplr([1 length(historySoftware)]), historySoftware');
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE_RELEASE'), ...
      fliplr([nHistory-1 0]), fliplr([1 length(historySoftwareRelease)]), historySoftwareRelease');
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
      fliplr([nHistory-1 0]), fliplr([1 length(historyDate)]), historyDate');

   % update the update date
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_UPDATE'), historyDate);

   % retrieve the creation date of the updated file
   dateCreation = deblank(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_CREATION'))');

   % set the 'history' global attribute
   globalVarId = netcdf.getConstant('NC_GLOBAL');
   globalHistoryText = [datestr(datenum(dateCreation, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; '];
   globalHistoryText = [globalHistoryText ...
      datestr(datenum(historyDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' last update (coriolis COAM software (V ' g_decArgo_adjustTrajDmMeasVersion '))'];
   netcdf.reDef(fCdf);
   netcdf.putAtt(fCdf, globalVarId, 'history', globalHistoryText);
   netcdf.endDef(fCdf);

   % update SCIENTIFIC_CALIB_* information

   [~, nCalibParam] = netcdf.inqDim(fCdf, netcdf.inqDimID(fCdf, 'N_CALIB_PARAM'));

   scientificCalibParam = 'PRES';
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_PARAMETER'), ...
      fliplr([nCalibParam-1 presParamId-1 0]), fliplr([1 1 length(scientificCalibParam)]), scientificCalibParam');
   scientificCalibParam = 'TEMP';
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_PARAMETER'), ...
      fliplr([nCalibParam-1 tempParamId-1 0]), fliplr([1 1 length(scientificCalibParam)]), scientificCalibParam');
   scientificCalibParam = 'PSAL';
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_PARAMETER'), ...
      fliplr([nCalibParam-1 psalParamId-1 0]), fliplr([1 1 length(scientificCalibParam)]), scientificCalibParam');

   scientificCalibComment = ['PRES ' g_decArgo_scientificCalibComment];
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_COMMENT'), ...
      fliplr([nCalibParam-1 presParamId-1 0]), fliplr([1 1 length(scientificCalibComment)]), scientificCalibComment');
   scientificCalibComment = ['TEMP ' g_decArgo_scientificCalibComment];
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_COMMENT'), ...
      fliplr([nCalibParam-1 tempParamId-1 0]), fliplr([1 1 length(scientificCalibComment)]), scientificCalibComment');
   scientificCalibComment = ['PSAL ' g_decArgo_scientificCalibComment];
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_COMMENT'), ...
      fliplr([nCalibParam-1 psalParamId-1 0]), fliplr([1 1 length(scientificCalibComment)]), scientificCalibComment');

   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_DATE'), ...
      fliplr([nCalibParam-1 presParamId-1 0]), fliplr([1 1 length(historyDate)]), historyDate');
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_DATE'), ...
      fliplr([nCalibParam-1 tempParamId-1 0]), fliplr([1 1 length(historyDate)]), historyDate');
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_DATE'), ...
      fliplr([nCalibParam-1 psalParamId-1 0]), fliplr([1 1 length(historyDate)]), historyDate');


   netcdf.close(fCdf);

catch MException
   netcdf.close(fCdf);
   rethrow(MException)
end

o_ok = 1;

return

% ------------------------------------------------------------------------------
% Estimate the QC that should be assigned to a set of data (from a QC profile).
%
% SYNTAX :
% [o_qcVal] = estimate_adj_qc(a_data, a_dataQc)
%
% INPUT PARAMETERS :
%   a_data   : profile measurements
%   a_dataQc : profile measurement QCs
%
% OUTPUT PARAMETERS :
%   o_qcVal : estimated QC value
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/25/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_qcVal] = estimate_adj_qc(a_data, a_dataQc)

% QC flag values
global g_decArgo_qcStrGood;          % '1'
global g_decArgo_qcStrProbablyGood;  % '2'
global g_decArgo_qcStrCorrectable;   % '3'


% dataQcU = unique(a_dataQc(~isnan(a_data)));
dataQcU = unique(a_dataQc);
if (length(dataQcU) == 1)
   % if the QCs are identical for all the profil, use this value
   o_qcVal = dataQcU;
else
   % if the QCs vary, estimate the QC to use from PROFILE_PARAM_QC
   % profQc = compute_profile_quality_flag(a_dataQc(~isnan(a_data)));
   profQc = compute_profile_quality_flag(a_dataQc);
   if (ismember(profQc, 'AB'))
      o_qcVal = g_decArgo_qcStrGood;
   elseif (ismember(profQc, 'C'))
      o_qcVal = g_decArgo_qcStrProbablyGood;
   else
      o_qcVal = g_decArgo_qcStrCorrectable;
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

% ------------------------------------------------------------------------------
% Get the basic structure to store DM profile data.
%
% SYNTAX :
% [o_profStruct] = get_dm_prof_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_profStruct : DM profile initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/18/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profStruct] = get_dm_prof_init_struct

% output parameters initialization
o_profStruct = struct( ...
   'proId', nan, ... % profile Id along the N_PROF dimension
   'cycleNumber', nan, ...
   'direction', nan, ... % 1 for descending, 2 for ascending
   'dataMode', '', ...
   'juld', nan, ...
   'juldQc', '', ...
   'vss', '', ...
   'presAdjNullFlag', nan, ...
   'tempAdjNullFlag', nan, ...
   'psalAdjNullFlag', nan, ...
   'pcondFactor', nan, ...
   'timeData', [], ...
   'paramList', [], ...
   'data', [], ...
   'dataQc', [], ...
   'dataAdj', [], ...
   'dataAdjQc', [], ...
   'dataAdjErr', [] ...
   );

return

% ------------------------------------------------------------------------------
% Get the basic structure to store DM traj data.
%
% SYNTAX :
% [o_trajStruct] = get_dm_traj_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_trajStruct : DM traj initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/18/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_trajStruct] = get_dm_traj_init_struct

% output parameters initialization
o_trajStruct = struct( ...
   'cycleNumber', nan, ...
   'measCode', nan, ...
   'paramList', [], ...
   'paramAdjNull', [], ...
   'dataId', [], ... % meas Ids along the N_MEASUREMENT dimension
   'pcondFactor', [], ...
   'timeData', [], ...
   'data', [], ...
   'dataQc', [], ...
   'dataAdj', [], ...
   'dataAdjQc', [], ...
   'dataAdjErr', [], ...
   'profPrev', '', ...
   'profCur', '' ...
   );

return

% ------------------------------------------------------------------------------
% Update the N_HISTORY and N_CALIB_PARAM dimensions in a trajectory file.
%
% SYNTAX :
% [o_ok] = update_dim_in_traj_file(a_trajFileName)
%
% INPUT PARAMETERS :
%   a_trajFileName : trajectory file path name
%
% OUTPUT PARAMETERS :
%   o_ok : ok flag (1 if in the update succeeded, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/20/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = update_dim_in_traj_file(a_trajFileName)

% output parameters initialization
o_ok = 0;


% check the N_CALiB_PARAM dimension
wantedVars = [ ...
   {'SCIENTIFIC_CALIB_EQUATION'} ...
   {'SCIENTIFIC_CALIB_COEFFICIENT'} ...
   {'SCIENTIFIC_CALIB_COMMENT'} ...
   {'SCIENTIFIC_CALIB_DATE'} ...
   ];

ncTrajData = get_data_from_nc_file(a_trajFileName, wantedVars);

sciCalibEquation = get_data_from_name('SCIENTIFIC_CALIB_EQUATION', ncTrajData);
sciCalibCoefficient = get_data_from_name('SCIENTIFIC_CALIB_COEFFICIENT', ncTrajData);
sciCalibComment = get_data_from_name('SCIENTIFIC_CALIB_COMMENT', ncTrajData);
sciCalibDate = get_data_from_name('SCIENTIFIC_CALIB_DATE', ncTrajData);

lastEmptyFlag = 1;
[~, nParam, nCalibParam] = size(sciCalibEquation);
for idP = 1:nParam
   if ~(isempty(strtrim(sciCalibEquation(:, idP, max(nCalibParam))')) && ...
         isempty(strtrim(sciCalibCoefficient(:, idP, max(nCalibParam))')) && ...
         isempty(strtrim(sciCalibComment(:, idP, max(nCalibParam))')) && ...
         isempty(strtrim(sciCalibDate(:, idP, max(nCalibParam))')))
      lastEmptyFlag = 0;
      break
   end
end

% directory to store temporary files
[filePath, fileName, fileExtension] = fileparts(a_trajFileName);
DIR_TMP_FILE = [filePath '/tmp/'];

% delete the temp directory
remove_directory(DIR_TMP_FILE);

% create the temp directory
mkdir(DIR_TMP_FILE);

% make a copy of the file in the temp directory
trajFileName = [DIR_TMP_FILE '/' fileName fileExtension];
tmpTrajFileName = [DIR_TMP_FILE '/' fileName '_tmp' fileExtension];
copy_file(a_trajFileName, tmpTrajFileName);

% retrieve the file schema
outputFileSchema = ncinfo(tmpTrajFileName);

% retrieve the N_HISTORY dimension length
idF = find(strcmp([{outputFileSchema.Dimensions.Name}], 'N_HISTORY') == 1, 1);
nHistory = outputFileSchema.Dimensions(idF).Length;

% update the file schema with the correct N_HISTORY dimension
[outputFileSchema] = update_dim_in_nc_schema(outputFileSchema, ...
   'N_HISTORY', nHistory+1);

if (~lastEmptyFlag)
   % retrieve the N_CALIB_PARAM dimension length
   idF = find(strcmp([{outputFileSchema.Dimensions.Name}], 'N_CALIB_PARAM') == 1, 1);
   nCalibParam = outputFileSchema.Dimensions(idF).Length;

   % update the file schema with the correct N_HISTORY dimension
   [outputFileSchema] = update_dim_in_nc_schema(outputFileSchema, ...
      'N_CALIB_PARAM', nCalibParam+1);
end

% create updated file
ncwriteschema(trajFileName, outputFileSchema);

% copy data in updated file - V1 - NOT EFFICIENT
% for idVar = 1:length(outputFileSchema.Variables)
%    varData = ncread(tmpTrajFileName, outputFileSchema.Variables(idVar).Name);
%    if (~isempty(varData))
%       ncwrite(trajFileName, outputFileSchema.Variables(idVar).Name, varData);
%    end
% end

% copy data in updated file
fCdfIn = netcdf.open(tmpTrajFileName, 'NC_NOWRITE');
if (isempty(fCdfIn))
   fprintf('RTQC_ERROR: Unable to open NetCDF input file: %s\n', tmpTrajFileName);
   return
end

try

   fCdfOut = netcdf.open(trajFileName, 'NC_WRITE');
   if (isempty(fCdfOut))
      fprintf('RTQC_ERROR: Unable to open NetCDF input file: %s\n', trajFileName);
      return
   end

   try

      for idVar = 1:length(outputFileSchema.Variables)
         varName = outputFileSchema.Variables(idVar).Name;
         varData = netcdf.getVar(fCdfIn, netcdf.inqVarID(fCdfIn, varName));
         if (~isempty(varData))
            dimList = {outputFileSchema.Variables(idVar).Dimensions.Name};
            if (length(dimList) == 1)
               netcdf.putVar(fCdfOut, netcdf.inqVarID(fCdfOut, varName), 0, length(varData), varData);
            else
               startList = zeros(1, length(dimList));
               countList = size(varData);
               if (length(countList) < length(dimList))
                  countList = [countList ones(1, length(dimList)-length(countList))];
               end
               netcdf.putVar(fCdfOut, netcdf.inqVarID(fCdfOut, varName), startList, countList, varData);
            end
         end
      end

      netcdf.close(fCdfOut);

   catch MException
      netcdf.close(fCdfOut);
      rethrow(MException)
   end

   netcdf.close(fCdfIn);

catch MException
   netcdf.close(fCdfIn);
   rethrow(MException)
end

% update input file
move_file(trajFileName, a_trajFileName);

% delete the temp directory
remove_directory(DIR_TMP_FILE);

o_ok = 1;

return

% ------------------------------------------------------------------------------
% Modify the value of a dimension in a NetCDF schema.
%
% SYNTAX :
%  [o_outputSchema] = update_dim_in_nc_schema(a_inputSchema, ...
%    a_dimName, a_dimVal)
%
% INPUT PARAMETERS :
%   a_inputSchema  : input NetCDF schema
%   a_dimName      : dimension name
%   a_dimVal       : dimension value
%
% OUTPUT PARAMETERS :
%   o_outputSchema  : output NetCDF schema
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/09/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_outputSchema] = update_dim_in_nc_schema(a_inputSchema, ...
   a_dimName, a_dimVal)

% output parameters initialization
o_outputSchema = [];

% update the dimension
idDim = find(strcmp(a_dimName, {a_inputSchema.Dimensions.Name}) == 1, 1);

if (~isempty(idDim))
   a_inputSchema.Dimensions(idDim).Length = a_dimVal;

   % update the dimensions of the variables
   for idVar = 1:length(a_inputSchema.Variables)
      var = a_inputSchema.Variables(idVar);
      idDims = find(strcmp(a_dimName, {var.Dimensions.Name}) == 1);
      a_inputSchema.Variables(idVar).Size(idDims) = a_dimVal;
      for idDim = 1:length(idDims)
         a_inputSchema.Variables(idVar).Dimensions(idDims(idDim)).Length = a_dimVal;
      end
   end
end

o_outputSchema = a_inputSchema;

return
