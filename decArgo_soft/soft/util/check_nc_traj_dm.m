% ------------------------------------------------------------------------------
% Check consistency between PROF DM measurements and TRJ DM measurements.
% (DM and associated RT TEMP and PSAL measurements are checked)
%
% SYNTAX :
%   check_nc_traj_dm(6902899)
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
%   06/26/2024 - RNU - creation
% ------------------------------------------------------------------------------
function check_nc_traj_dm(varargin)

% measurement codes initialization
init_measurement_codes;

% default values initialization
init_default_values;

% global measurement codes
global g_MC_FillValue;
global g_MC_DescProf;
global g_MC_DescProfDeepestBin;
global g_MC_DriftAtPark;
global g_MC_AscProfDeepestBin;
global g_MC_AscProf;
global g_MC_LastAscPumpedCtd;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START

% default list of floats to process
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_tmp.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ANDRO_2_TRAJ-DM\Decomptes_20240621\arvor_in_andro.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ANDRO_2_TRAJ-DM\Decomptes_20240621\arvor_in_andro_with_prof_DM_psal_adj_not_null.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ANDRO_2_TRAJ-DM\Decomptes_20240621\arvor_in_andro_with_prof_DM.txt';

% top directory of the input DM PROF NetCDF files
DIR_INPUT_NC_PROF_FILES = 'C:\Users\jprannou\_DATA\TRAJ_DM_2024\snapshot-202405_arvor_ir_in_andro_325\';

% top directory of the input TRAJ NetCDF files
DIR_INPUT_NC_TRAJ_FILES = 'C:\Users\jprannou\_DATA\TRAJ_DM_2024\TRAJ_DM_2024_OUT\';
DIR_INPUT_NC_TRAJ_FILES = 'C:\Users\jprannou\_DATA\OUT\TRAJ_DM_2024\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the csv file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';

% PARAM THRESHOLD:
% [MC (use g_MC_FillValue as default), threshold for TEMP, TEMP_ADJUSTED, PSAL, PSAL_ADJUSTED];
PARAM_THRESHOLD = [ ...
   [g_MC_DescProf 1 1 0.7 0.7]; ... % should fit only if descending profile exists
   [g_MC_DescProfDeepestBin 1 1 0.7 0.7]; ... % should fit only if descending profile exists
   [g_MC_DriftAtPark 3 3 0.7 0.7]; ...
   [g_MC_AscProfDeepestBin 0 0 0 0]; ... % should fit
   [g_MC_AscProf 0 0 0 0]; ... % should fit
   [g_MC_LastAscPumpedCtd 0.5 0.5 0.1 0.1]; ...
   [g_MC_FillValue 0 0 0 0]; ...
   ];

% CONFIGURATION - END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% PARAM threshold
global g_decArgo_paramThreshold;
g_decArgo_paramThreshold = PARAM_THRESHOLD;


% check inputs
if (nargin == 0)
   if ~(exist(FLOAT_LIST_FILE_NAME, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', FLOAT_LIST_FILE_NAME);
      return
   end
end
if ~(exist(DIR_INPUT_NC_PROF_FILES, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s\n', DIR_INPUT_NC_FILES);
   return
end
if ~(exist(DIR_INPUT_NC_TRAJ_FILES, 'dir') == 7)
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

logFile = [DIR_LOG_FILE '/' 'check_nc_traj_dm' name '_' currentTime '.log'];
diary(logFile);
tic;

% create output CSV file
csvFilepathName = [DIR_CSV_FILE '\check_nc_traj_dm' name '_' currentTime '.csv'];
fId = fopen(csvFilepathName, 'wt');
if (fId == -1)
   fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
   return
end
header = 'WMO;CyNum;Meas code;Param;Juld;Pres;Param val;Ref param val;Diff;THRESHOLD';

fprintf(fId, '%s\n', header);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process floats of the list

nbFloats = length(floatList);
for idFloat = 1:nbFloats

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
   % check TRAJ DM data against PROF DM ones

   anomaly = check_traj_data(floatNum, inputTrajFloatDir, dmCProfileData, cParamList, dmBProfileData, bParamList);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % print anomalies
   % [{floatNum} {cyNum} {measCode} {<PARAM>name} {juld} {pres} {<PARAM>Val} {interp<PARAM>} {abs(<PARAM>Val-interp<PARAM>)} {threshold}]];

   for idL = 1:size(anomaly, 1)
      juld = anomaly{idL, 5};
      pres = anomaly{idL, 6};
      param = anomaly{idL, 7};
      paramInter = anomaly{idL, 8};
      paramDiff = anomaly{idL, 9};
      for idL2 = 1:length(juld)
         fprintf(fId, '%d;%d;%s;%s; %s;%.1f;%.4f;%.4f;%.4f;%.4f\n', ...
            anomaly{idL, 1:2}, ...
            get_meas_code_name(anomaly{idL, 3}), ...
            anomaly{idL, 4}, ...
            julian_2_gregorian_dec_argo(juld(idL2)), ...
            pres(idL2), ...
            param(idL2), ...
            paramInter(idL2), ...
            paramDiff(idL2), ...
            anomaly{idL, 10});
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fclose(fId);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Check trajectory measurements against profile DM data.
%
% SYNTAX :
% [o_anomaly] = check_traj_data(a_floatNum, a_ncFileDir, a_dmCProfileData, a_cParamList, ...
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
%   o_anomaly : detected anomalies
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/27/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_anomaly] = check_traj_data(a_floatNum, a_ncFileDir, a_dmCProfileData, a_cParamList, ...
   a_dmBProfileData, a_bParamList)

% output parameters initialization
o_anomaly = [];

% global measurement codes
global g_MC_FillValue;
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
global g_decArgo_qcStrGood;          % '1'
global g_decArgo_qcStrProbablyGood;  % '2'

% PARAM threshold
global g_decArgo_paramThreshold;


juldInfo = get_netcdf_param_attributes('JULD');
presInfo = get_netcdf_param_attributes('PRES');
tempInfo = get_netcdf_param_attributes('TEMP');
psalInfo = get_netcdf_param_attributes('PSAL');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% retrieve data from trajectory file

trajFile = dir([a_ncFileDir sprintf('%d_Dtraj.nc', a_floatNum)]);
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
   {'CYCLE_NUMBER_ADJUSTED'} ...
   {'CYCLE_NUMBER_INDEX'} ...
   {'CYCLE_NUMBER_INDEX_ADJUSTED'} ...
   {'MEASUREMENT_CODE'} ...
   {'JULD_DATA_MODE'} ...
   {'TRAJECTORY_PARAMETERS'} ...
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

cycleNumber = get_data_from_name('CYCLE_NUMBER', ncTrajData);
cycleNumberAdj = get_data_from_name('CYCLE_NUMBER_ADJUSTED', ncTrajData);
cycleNumberIdx = get_data_from_name('CYCLE_NUMBER_INDEX', ncTrajData);
cycleNumberIdxAdj = get_data_from_name('CYCLE_NUMBER_INDEX_ADJUSTED', ncTrajData);
measurementCode = get_data_from_name('MEASUREMENT_CODE', ncTrajData);
juldDataMode = get_data_from_name('JULD_DATA_MODE', ncTrajData);
trajParams = get_data_from_name('TRAJECTORY_PARAMETERS', ncTrajData);
trajParamDataMode = get_data_from_name('TRAJECTORY_PARAMETER_DATA_MODE', ncTrajData);

juldData = get_data_from_name('JULD', ncTrajData);
juldData(juldData == juldInfo.fillValue) = nan;
juldQcData = get_data_from_name('JULD_QC', ncTrajData);
juldAdjData = get_data_from_name('JULD_ADJUSTED', ncTrajData);
juldAdjData(juldAdjData == juldInfo.fillValue) = nan;
juldAdjQcData = get_data_from_name('JULD_ADJUSTED_QC', ncTrajData);

presData = get_data_from_name('PRES', ncTrajData);
presData(presData == presInfo.fillValue) = nan;
presQcData = get_data_from_name('PRES_QC', ncTrajData);
presAdjData = get_data_from_name('PRES_ADJUSTED', ncTrajData);
presAdjData(presAdjData == presInfo.fillValue) = nan;
presAdjQcData = get_data_from_name('PRES_ADJUSTED_QC', ncTrajData);
presAdjErrData = get_data_from_name('PRES_ADJUSTED_ERROR', ncTrajData);
presAdjErrData(presAdjErrData == presInfo.fillValue) = nan;

tempData = get_data_from_name('TEMP', ncTrajData);
tempData(tempData == tempInfo.fillValue) = nan;
tempQcData = get_data_from_name('TEMP_QC', ncTrajData);
tempAdjData = get_data_from_name('TEMP_ADJUSTED', ncTrajData);
tempAdjData(tempAdjData == tempInfo.fillValue) = nan;
tempAdjQcData = get_data_from_name('TEMP_ADJUSTED_QC', ncTrajData);
tempAdjErrData = get_data_from_name('TEMP_ADJUSTED_ERROR', ncTrajData);
tempAdjErrData(tempAdjErrData == tempInfo.fillValue) = nan;

psalData = get_data_from_name('PSAL', ncTrajData);
psalData(psalData == psalInfo.fillValue) = nan;
psalQcData = get_data_from_name('PSAL_QC', ncTrajData);
psalAdjData = get_data_from_name('PSAL_ADJUSTED', ncTrajData);
psalAdjData(psalAdjData == psalInfo.fillValue) = nan;
psalAdjQcData = get_data_from_name('PSAL_ADJUSTED_QC', ncTrajData);
psalAdjErrData = get_data_from_name('PSAL_ADJUSTED_ERROR', ncTrajData);
psalAdjErrData(psalAdjErrData == psalInfo.fillValue) = nan;

% list of attributes to retrieve from NetCDF file
wantedVarAtts = [ ...
   {'CYCLE_NUMBER'} {'_FillValue'} ...
   {'CYCLE_NUMBER_ADJUSTED'} {'_FillValue'} ...
   {'CYCLE_NUMBER_INDEX'} {'_FillValue'} ...
   {'CYCLE_NUMBER_INDEX_ADJUSTED'} {'_FillValue'} ...
   ];

% retrieve attributes from NetCDF file
ncAtt = get_att_from_nc_file(trajFilePathName, wantedVarAtts);

cycleNumberFV = get_att_from_name('CYCLE_NUMBER', '_FillValue', ncAtt);
cycleNumberAdjFV = get_att_from_name('CYCLE_NUMBER_ADJUSTED', '_FillValue', ncAtt);
cycleNumberIdxFV = get_att_from_name('CYCLE_NUMBER_INDEX', '_FillValue', ncAtt);
cycleNumberIdxAdjFV = get_att_from_name('CYCLE_NUMBER_INDEX_ADJUSTED', '_FillValue', ncAtt);

cycleNumber = double(cycleNumber);
cycleNumber(cycleNumber == cycleNumberFV) = nan;
cycleNumberAdj = double(cycleNumberAdj);
cycleNumberAdj(cycleNumberAdj == cycleNumberAdjFV) = nan;
cycleNumberIdx = double(cycleNumberIdx);
cycleNumberIdx(cycleNumberIdx == cycleNumberIdxFV) = nan;
cycleNumberIdxAdj = double(cycleNumberIdxAdj);
cycleNumberIdxAdj(cycleNumberIdxAdj == cycleNumberIdxAdjFV) = nan;

juldBest = juldAdjData;
juldBest(juldDataMode == 'R') = juldData(juldDataMode == 'R');

% retrieve N_PARAM Id of each parameter
[~, nParam] = size(trajParams);
presParamId = nan;
tempParamId = nan;
psalParamId = nan;
for idParam = 1:nParam
   paramName = deblank(trajParams(:, idParam)');
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
   % process TRAJ cycle numbers

   for idCy = 1:length(cycleNumberIdxAdj)

      cyNumIdxAdj = cycleNumberIdxAdj(idCy);
      cyNumIdx = cycleNumberIdx(idCy);

      if (isnan(cyNumIdxAdj))
         % the cycle is not in DM
         continue
      end

      idPrev = '';
      idCur = find([dmProfileData{:, 1}] == cyNumIdx);
      if (isempty(idCur))
         continue
      end
      if (cyNumIdx > 1)
         idPrev = find([dmProfileData{:, 1}] == cyNumIdx-1);
      end

      if (~isempty(idPrev))
         profPrev = dmProfileData{idPrev, 3};
         profCur = dmProfileData{idCur, 3};
      else
         profPrev = '';
         profCur = dmProfileData{idCur, 3};
      end

      idMeasForCy = find(cycleNumberAdj == cyNumIdxAdj);
      mcList = unique(measurementCode(idMeasForCy));

      for measCode = mcList'

         paramThreshold = g_decArgo_paramThreshold;
         profP = profPrev;
         profC = profCur;
         profCurDesc = '';

         switch (measCode)

            case {g_MC_FST}
               % MC managed by the ANDRO 2 TRAJ-DM tool

            case {g_MC_DescProf, g_MC_DescProfDeepestBin, ...
                  g_MC_DriftAtPark, ...
                  g_MC_AscProfDeepestBin, g_MC_AscProf, g_MC_LastAscPumpedCtd}

               if (ismember(measCode, [g_MC_DescProf, g_MC_DescProfDeepestBin]))
                  % first look for the DM descending profile
                  idCurDesc = find(([dmProfileData{:, 1}] == cyNumIdx) & ([dmProfileData{:, 2}] == 1));
                  if (~isempty(idCurDesc))
                     profCurDesc = dmProfileData{idCurDesc, 3};
                     % the data should fit
                     idF = find(paramThreshold(:, 1) == measCode);
                     if (~isempty(idF))
                        paramThreshold(idF, :) = [measCode 0 0 0 0];
                     end
                  end
               elseif (ismember(measCode, [g_MC_AscProfDeepestBin, g_MC_AscProf]))
                  % the data should fit
                  profP = '';
               end

               tempThresholdRt = '';
               idF = find(paramThreshold(:, 1) == measCode);
               if (~isempty(idF))
                  tempThresholdRt = paramThreshold(idF, 2);
                  tempThresholdDm = paramThreshold(idF, 3);
                  psalThresholdRt = paramThreshold(idF, 4);
                  psalThresholdDm = paramThreshold(idF, 5);
               else
                  idF = find(paramThreshold(:, 1) == g_MC_FillValue);
                  if (~isempty(idF))
                     tempThresholdRt = paramThreshold(idF, 2);
                     tempThresholdDm = paramThreshold(idF, 3);
                     psalThresholdRt = paramThreshold(idF, 4);
                     psalThresholdDm = paramThreshold(idF, 5);
                  end
               end
               if (isempty(tempThresholdRt))
                  fprintf('ANOMALY\n');
                  continue
               end

               % one loop for each param (TEMP and PSAL)
               for idLoop2 = 1:2

                  % one loop for each data mode ('R'/'A' or 'D')
                  for idLoop3 = 1:2

                     if (idLoop2 == 1)
                        if (idLoop3 == 1)

                           idNoDef = find( ...
                              (juldBest ~= juldInfo.fillValue) & ...
                              (cycleNumberAdj == cyNumIdxAdj) & ...
                              (measurementCode == measCode) & ...
                              ((tempQcData == g_decArgo_qcStrGood) | ...
                              (tempQcData == g_decArgo_qcStrProbablyGood)) & ...
                              (trajParamDataMode(tempParamId, :)' == 'D'));
                           if (isempty(idNoDef))
                              idNoDef = find( ...
                                 (cycleNumberAdj == cyNumIdxAdj) & ...
                                 (measurementCode == measCode) & ...
                                 ((tempQcData == g_decArgo_qcStrGood) | ...
                                 (tempQcData == g_decArgo_qcStrProbablyGood)) & ...
                                 (trajParamDataMode(tempParamId, :)' == 'D'));
                              if (isempty(idNoDef))
                                 continue
                              end
                           end

                           dataModeStr = 'R';
                           juldVal = juldData(idNoDef);
                           presVal = presData(idNoDef);
                           trajParamVal = tempData(idNoDef);
                           paramColNum = 3;
                           paramName = 'TEMP';
                           threshold = tempThresholdRt;
                        else

                           idNoDef = find( ...
                              (juldBest ~= juldInfo.fillValue) & ...
                              (cycleNumberAdj == cyNumIdxAdj) & ...
                              (measurementCode == measCode) & ...
                              ((tempAdjQcData == g_decArgo_qcStrGood) | ...
                              (tempAdjQcData == g_decArgo_qcStrProbablyGood)) & ...
                              (trajParamDataMode(tempParamId, :)' == 'D'));
                           if (isempty(idNoDef))
                              idNoDef = find( ...
                                 (cycleNumberAdj == cyNumIdxAdj) & ...
                                 (measurementCode == measCode) & ...
                                 ((tempAdjQcData == g_decArgo_qcStrGood) | ...
                                 (tempAdjQcData == g_decArgo_qcStrProbablyGood)) & ...
                                 (trajParamDataMode(tempParamId, :)' == 'D'));
                              if (isempty(idNoDef))
                                 continue
                              end
                           end

                           dataModeStr = 'R';
                           juldVal = juldAdjData(idNoDef);
                           presVal = presAdjData(idNoDef);
                           trajParamVal = tempAdjData(idNoDef);
                           paramColNum = 3;
                           paramName = 'TEMP_ADJUSTED';
                           threshold = tempThresholdDm;
                        end
                     else
                        if (idLoop3 == 1)

                           idNoDef = find( ...
                              (juldBest ~= juldInfo.fillValue) & ...
                              (cycleNumberAdj == cyNumIdxAdj) & ...
                              (measurementCode == measCode) & ...
                              ((psalQcData == g_decArgo_qcStrGood) | ...
                              (psalQcData == g_decArgo_qcStrProbablyGood)) & ...
                              (trajParamDataMode(psalParamId, :)' == 'D'));
                           if (isempty(idNoDef))
                              idNoDef = find( ...
                                 (juldBest ~= juldInfo.fillValue) & ...
                                 (cycleNumberAdj == cyNumIdxAdj) & ...
                                 (measurementCode == measCode) & ...
                                 ((psalQcData == g_decArgo_qcStrGood) | ...
                                 (psalQcData == g_decArgo_qcStrProbablyGood)) & ...
                                 (trajParamDataMode(psalParamId, :)' == 'D'));
                              if (isempty(idNoDef))
                                 continue
                              end
                           end

                           dataModeStr = 'R';
                           juldVal = juldData(idNoDef);
                           presVal = presData(idNoDef);
                           trajParamVal = psalData(idNoDef);
                           paramColNum = 4;
                           paramName = 'PSAL';
                           threshold = psalThresholdRt;
                        else

                           idNoDef = find( ...
                              (juldBest ~= juldInfo.fillValue) & ...
                              (cycleNumberAdj == cyNumIdxAdj) & ...
                              (measurementCode == measCode) & ...
                              ((psalAdjQcData == g_decArgo_qcStrGood) | ...
                              (psalAdjQcData == g_decArgo_qcStrProbablyGood)) & ...
                              (trajParamDataMode(psalParamId, :)' == 'D'));
                           if (isempty(idNoDef))
                              idNoDef = find( ...
                                 (juldBest ~= juldInfo.fillValue) & ...
                                 (cycleNumberAdj == cyNumIdxAdj) & ...
                                 (measurementCode == measCode) & ...
                                 ((psalAdjQcData == g_decArgo_qcStrGood) | ...
                                 (psalAdjQcData == g_decArgo_qcStrProbablyGood)) & ...
                                 (trajParamDataMode(psalParamId, :)' == 'D'));
                              if (isempty(idNoDef))
                                 continue
                              end
                           end

                           dataModeStr = 'D';
                           juldVal = juldAdjData(idNoDef);
                           presVal = presAdjData(idNoDef);
                           trajParamVal = psalAdjData(idNoDef);
                           paramColNum = 4;
                           paramName = 'PSAL_ADJUSTED';
                           threshold = psalThresholdDm;
                        end
                     end

                     % get reference measurements (interpolated from PROF DM)
                     [dataInterp, dataPrev, dataCur] = interp_prof_data(juldVal, presVal, profP, profC, profCurDesc, dataModeStr);

                     interpParam = [];
                     if (any(~isnan(dataInterp(:, paramColNum))))
                        interpParam = dataInterp(:, paramColNum);
                     elseif (any(~isnan(dataCur(:, paramColNum))))
                        interpParam = dataCur(:, paramColNum);
                     end
                     if (~isempty(interpParam))
                        if (any(abs(trajParamVal-interpParam) > threshold))
                           idKo = find(abs(trajParamVal-interpParam) > threshold);
                           o_anomaly = [o_anomaly; ...
                              [{a_floatNum} {cyNumIdxAdj} {measCode} {paramName} {juldVal(idKo)} {presVal(idKo)} {trajParamVal(idKo)} {interpParam(idKo)} {abs(trajParamVal(idKo)-interpParam(idKo))} {threshold}]];
                        end
                     end
                  end
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

               % otherwise
               %    fprintf('Not implement yet for MC = %d\n', measCode);
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve reference measurements (from PROF DM data) for a set of TRAJ
% measurements.
%
% SYNTAX :
% [o_dataInterp, o_dataPrev, o_dataCur] = interp_prof_data( ...
%   a_trajJuld, a_trajPres, a_profPrev, a_profCur, a_profCurDesc, a_dataMode)
%
% INPUT PARAMETERS :
%   a_trajJuld    : JULD of TRAJ measurements
%   a_trajPres    : PRES of TRAJ measurements
%   a_profPrev    : previous profile
%   a_profCur     : current profile
%   a_profCurDesc : current descending profile
%   a_dataMode    : data mode to consider
%
% OUTPUT PARAMETERS :
%   o_dataInterp : interpolated (time + pres) data (JULD, PRES, TEMP, PSAL)
%   o_dataPrev   : interpolated (pres) data from previous profile (JULD, PRES, TEMP, PSAL)
%   o_dataCur    : interpolated (pres) data from current profile (JULD, PRES, TEMP, PSAL)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/26/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataInterp, o_dataPrev, o_dataCur] = interp_prof_data( ...
   a_trajJuld, a_trajPres, a_profPrev, a_profCur, a_profCurDesc, a_dataMode)

% output parameters initialization
o_dataInterp = nan(length(a_trajPres), 4);
o_dataPrev = nan(length(a_trajPres), 4);
o_dataCur = nan(length(a_trajPres), 4);

% QC flag values
global g_decArgo_qcStrGood;          % '1'
global g_decArgo_qcStrProbablyGood;  % '2'


% one loop for each profile (previous and current)
for idLoop = 1:2
   if (idLoop == 1)
      if (~isempty(a_profCurDesc))
         continue
      end
      prof = a_profPrev;
   else
      if (~isempty(a_profCurDesc))
         prof = a_profCurDesc;
      else
         prof = a_profCur;
      end
   end
   if (~isempty(prof))
      if (a_dataMode == 'R')
         profPresData = prof.data(:, 1);
         profPresDataQc = prof.dataQc(:, 1);

         profTempData = prof.data(:, 2);
         profTempDataQc = prof.dataQc(:, 2);

         profPsalData = prof.data(:, 3);
         profPsalDataQc = prof.dataQc(:, 3);
      else
         profPresData = prof.dataAdj(:, 1);
         profPresDataQc = prof.dataAdjQc(:, 1);

         profTempData = prof.dataAdj(:, 2);
         profTempDataQc = prof.dataAdjQc(:, 2);

         profPsalData = prof.dataAdj(:, 3);
         profPsalDataQc = prof.dataAdjQc(:, 3);
      end

      data = nan(length(a_trajPres), 4);

      data(:, 1) = prof.juld;
      data(:, 2) = a_trajPres;

      idNoDef1 = find(~isnan(a_trajPres));
      if (~isempty(idNoDef1))

         % interpolate TEMP profile measurements at the TRAJ PRES level
         idNoDef2 = find( ...
            ~isnan(profPresData) & ...
            ((profPresDataQc == g_decArgo_qcStrGood) | ...
            (profPresDataQc == g_decArgo_qcStrProbablyGood)) & ...
            ~isnan(profTempData) & ...
            ((profTempDataQc == g_decArgo_qcStrGood) | ...
            (profTempDataQc == g_decArgo_qcStrProbablyGood)));

         if (length(idNoDef2) > 1)
            data(idNoDef1, 3) = interp1(profPresData(idNoDef2), profTempData(idNoDef2), a_trajPres(idNoDef1), 'linear');
         end

         % interpolate PSAL profile measurements at the TRAJ PRES level
         idNoDef3 = find( ...
            ~isnan(profPresData) & ...
            ((profPresDataQc == g_decArgo_qcStrGood) | ...
            (profPresDataQc == g_decArgo_qcStrProbablyGood)) & ...
            ~isnan(profPsalData) & ...
            ((profTempDataQc == g_decArgo_qcStrGood) | ...
            (profPsalDataQc == g_decArgo_qcStrProbablyGood)));

         if (length(idNoDef3) > 1)
            data(idNoDef1, 4) = interp1(profPresData(idNoDef3), profPsalData(idNoDef3), a_trajPres(idNoDef1), 'linear');
         end
      end

      if (idLoop == 1)
         o_dataPrev = data;
      else
         o_dataCur = data;
      end
   end
end

o_dataInterp(:, 1) = a_trajJuld;
o_dataInterp(:, 2) = a_trajPres;

% timely interpolate the TEMP measurments
idNoDef = find( ...
   ~isnan(o_dataInterp(:, 1)) & ...
   ~isnan(o_dataPrev(:, 1)) & ...
   ~isnan(o_dataPrev(:, 3)) & ...
   ~isnan(o_dataCur(:, 1)) & ...
   ~isnan(o_dataCur(:, 3)));
if (~isempty(idNoDef))
   for id = idNoDef'
      o_dataInterp(id, 3) = interp1([o_dataPrev(id, 1); o_dataCur(id, 1)], [o_dataPrev(id, 3); o_dataCur(id, 3)], a_trajJuld(id), 'linear');
   end
end

% timely interpolate the PSAL measurments
idNoDef = find( ...
   ~isnan(o_dataInterp(:, 1)) & ...
   ~isnan(o_dataPrev(:, 1)) & ...
   ~isnan(o_dataPrev(:, 4)) & ...
   ~isnan(o_dataCur(:, 1)) & ...
   ~isnan(o_dataCur(:, 4)));
if (~isempty(idNoDef))
   for id = idNoDef'
      o_dataInterp(id, 4) = interp1([o_dataPrev(id, 1); o_dataCur(id, 1)], [o_dataPrev(id, 4); o_dataCur(id, 4)], a_trajJuld(id), 'linear');
   end
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
%   06/26/2024 - RNU - creation
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
   'timeData', [], ...
   'paramList', [], ...
   'data', [], ...
   'dataQc', [], ...
   'dataAdj', [], ...
   'dataAdjQc', [], ...
   'dataAdjErr', [] ...
   );

return
