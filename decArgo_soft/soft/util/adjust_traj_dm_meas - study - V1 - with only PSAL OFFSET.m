% ------------------------------------------------------------------------------
% Adjust parameter measurement values in a DM trajectory file.
% V1: adjustments with retrieved offsets - many outputs - no update of TRAJ file.
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
%   02/13/2024 - RNU - creation
% ------------------------------------------------------------------------------
function adjust_traj_dm_meas(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START

% default list of floats to process
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TRAJ_DM\arvor_in_andro.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TRAJ_DM\arvor_in_andro_psal_adj.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TRAJ_DM\cts3_in_andro_all.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TRAJ_DM\cts3_in_andro.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TRAJ_DM\arvor_deep_in_andro_all.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_tmp.txt';

% top directory of the NetCDF files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\TRAJ_DM_2024\snapshot-202401_nke_in_andro\';

% directory of output files
DIR_OUTPUT_FILES = '';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the csv file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';

% check TRAJ VS PROF PARAM data
CHECK_TRAJ_PARAM = 1;

% CSV output options
PRINT_PROF = 1;
PRINT_TRAJ = 1;

% Arvor Deep flag
ARVOR_DEEP_FLAG = 0;

% CONFIGURATION - END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Id of the CSV output files
global g_decArgo_csvIdProf;
global g_decArgo_csvIdTraj;
global g_decArgo_csvIdCheckTraj;
g_decArgo_csvIdProf = -1;
g_decArgo_csvIdTraj = -1;
g_decArgo_csvIdCheckTraj = -1;

% adjustment values
global g_decArgo_adjVal;

% list of MC with PSAL measurement
global g_decArgo_psalMeasCodeList;
g_decArgo_psalMeasCodeList = [];

% Arvor Deep flag
global g_decArgo_arvorDeepFlag;
g_decArgo_arvorDeepFlag = ARVOR_DEEP_FLAG;

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
header = ['WMO;Cy D-PROF;Cy BD-PROF;Cy TRAJ;' ...
   'Max diff TEMP;Max diff PSAL;Max diff DOXY;' ...
   'PRES adj val;TEMP adj val;PSAL adj val;DOXY adj val;' ...
   'Max diff PROF PSAL_ADJUSTED;Max diff TRAJ PSAL_ADJUSTED;' ...
   'Cy PRES_ADJUSTED_QC=4;Cy TEMP_ADJUSTED_QC=4;Cy PSAL_ADJUSTED_QC=4;Cy DOXY_ADJUSTED_QC=4'];
fprintf(fId, '%s\n', header);
paramListHeader = [{'PRES'} {'TEMP'} {'PSAL'} {'DOXY'}];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process floats of the list
nbFloats = length(floatList);
for idFloat = 1:nbFloats

   g_decArgo_adjVal =[];

   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);

   if (CHECK_TRAJ_PARAM)
      % create output CSV file to report TRAJ data checks
      csvFilepathName = [DIR_CSV_FILE '\check_traj_param_meas_' floatNumStr '_' currentTime '.csv'];
      g_decArgo_csvIdCheckTraj = fopen(csvFilepathName, 'wt');
      if (g_decArgo_csvIdCheckTraj == -1)
         fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
         return
      end
      header = 'WMO;CYCLE_NUMBER;PARAM;MC;PRES;PARAM;Prev PARAM;abs(Prev PARAM-PARAM);Cur PARAM;abs(Cur PARAM-PARAM)';
      fprintf(g_decArgo_csvIdCheckTraj, '%s\n', header);
   end

   if (PRINT_PROF)
      % create output CSV file to report PROF adjustments
      csvFilepathName = [DIR_CSV_FILE '\adjusted_prof_dm_meas_' floatNumStr '_' currentTime '.csv'];
      g_decArgo_csvIdProf = fopen(csvFilepathName, 'wt');
      if (g_decArgo_csvIdProf == -1)
         fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
         return
      end
      header = 'WMO;CYCLE_NUMBER;DIRECTION;PRES;PSAL;PSAL_ADJUSTED;AdjVal=PSAL_ADJUSTED-PSAL;PSAL offset;PSAL_ADJUSTED2=PSAL+PSAL offset;Diff=abs(PSAL_ADJUSTED-PSAL_ADJUSTED2)';
      fprintf(g_decArgo_csvIdProf, '%s\n', header);
   end

   % retrieve float data from NetCDF files
   [dmCProfileData, cParamList, dmBProfileData, bParamList] = ...
      get_profile_dm_data(floatNum, [DIR_INPUT_NC_FILES '/' floatNumStr]);
   if (isempty(dmCProfileData) && isempty(dmBProfileData))
      if (PRINT_PROF)
         fclose(g_decArgo_csvIdProf);
      end
      if (CHECK_TRAJ_PARAM)
         fclose(g_decArgo_csvIdCheckTraj);
      end
      continue
   end

   % concat primary and NS profiles and copy PRES data from core to BGC profiles
   [dmCProfileData, dmBProfileData] = concat_profile(floatNum, dmCProfileData, dmBProfileData);

   if (PRINT_TRAJ)
      % create output CSV file to report TRAJ adjustments
      csvFilepathName = [DIR_CSV_FILE '\check_traj_adj_param_meas_' floatNumStr '_' currentTime '.csv'];
      g_decArgo_csvIdTraj = fopen(csvFilepathName, 'wt');
      if (g_decArgo_csvIdTraj == -1)
         fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
         return
      end
      header = [ ...
         'WMO;CYCLE_NUMBER;PARAM;MC;Meas#;' ...
         'Prev Prof JulD;Prev Prof Adj Val;Cur Prof JulD;cur Prof Adj Val;' ...
         'Meas Juld;Meas Pres;Meas PARAM;Meas Adj Val #1;Meas PARAM_ADJUSTED #1;' ...
         'Prev Prof PSAL offset;Cur Prof PSAL offset;' ...
         'Meas Adj Val #2;Meas PARAM_ADJUSTED #2;Meas PARAM_ADJUSTED diff;' ...
         'Prev Prof nCalib;Prev Prof Equation;Prev Prof Coef;Prev Prof Comment;Prev Prof Date;' ...
         'Cur Prof nCalib;Cur Prof Equation;Cur Prof Coef;Cur Prof Comment;Cur Prof Date;' ...
         ];
      fprintf(g_decArgo_csvIdTraj, '%s\n', header);
   end

   % adjust traj data
   % ok = adjust_traj_data(floatNum, [DIR_INPUT_NC_FILES '/' floatNumStr], dmCProfileData, cParamList, [], []);
   trajCyNumList = adjust_traj_data(floatNum, [DIR_INPUT_NC_FILES '/' floatNumStr], dmCProfileData, cParamList, dmBProfileData, bParamList);

   if (g_decArgo_csvIdTraj ~= -1)
      fclose(g_decArgo_csvIdTraj);
   end
   if (g_decArgo_csvIdProf ~= -1)
      fclose(g_decArgo_csvIdProf);
   end
   if (g_decArgo_csvIdCheckTraj ~= -1)
      fclose(g_decArgo_csvIdCheckTraj);
   end

   adjCoreCyNumListStr = '';
   if (~isempty(dmCProfileData))
      adjCoreCyNumListStr = squeeze_list(unique([dmCProfileData{:, 1}]));
   end
   adjBgcCyNumListStr = '';
   if (~isempty(dmBProfileData))
      adjBgcCyNumListStr = squeeze_list(unique([dmBProfileData{:, 1}]));
   end
   adjTrajCyNumListStr = '';
   if (~isempty(trajCyNumList))
      adjTrajCyNumListStr = squeeze_list(trajCyNumList);
   end

   fprintf(fId, '%d;%s;%s;%s', floatNum, adjCoreCyNumListStr, adjBgcCyNumListStr, adjTrajCyNumListStr);

   if (~isempty(g_decArgo_adjVal))
      % g_decArgo_adjVal global array:
      % - col #1: parameter name
      % - col #2: profile adjustment values
      % - col #3: list of cycles with all PARAM_ADJUSTED_QC=4
      % - col #4: max diff between provided PSAL adjusted values and values
      %           adjusted from SCIENTIFIC_CALIB_* information
      % - col #5: max diff between TRAJ PSAL adjusted values (from data and from
      %           SCIENTIFIC_CALIB_* information)
      % - col #6: max diff between TRAJ PARAM value and (prev and cur) PROF
      %           PARAM value

      for idP = 1:length(paramListHeader)
         paramName = paramListHeader{idP};
         if (~strcmp('PRES', paramName))
            idParam = find(strcmp(paramName, g_decArgo_adjVal(:, 1)));
            if (~isempty(idParam))
               if (~isnan(g_decArgo_adjVal{idParam, 6}))
                  fprintf(fId, ';%e', g_decArgo_adjVal{idParam, 6});
               else
                  fprintf(fId, ';');
               end
            else
               fprintf(fId, ';');
            end
         end
      end
      for idP = 1:length(paramListHeader)
         paramName = paramListHeader{idP};
         idParam = find(strcmp(paramName, g_decArgo_adjVal(:, 1)));
         if (~isempty(idParam))
            if (~isempty(g_decArgo_adjVal{idParam, 2}))
               values = unique(round_argo(g_decArgo_adjVal{idParam, 2}, paramName));
               if (length(values) <= 5)
                  valStr = sprintf(' %g', values);
               else
                  valStr = sprintf('%d values: from %g to %g', length(values), min(values), max(values));
               end
               fprintf(fId, ';%s', valStr);
            else
               fprintf(fId, ';');
            end
         else
            fprintf(fId, ';');
         end
      end
      idPsal = find(strcmp('PSAL', g_decArgo_adjVal(:, 1)));
      if (~isempty(idPsal))
         if (~isnan(g_decArgo_adjVal{idPsal, 4}))
            fprintf(fId, ';%e', g_decArgo_adjVal{idPsal, 4});
         else
            fprintf(fId, ';');
         end
         if (~isnan(g_decArgo_adjVal{idPsal, 5}))
            fprintf(fId, ';%e', g_decArgo_adjVal{idPsal, 5});
         else
            fprintf(fId, ';');
         end
      else
         fprintf(fId, ';;');
      end
      for idP = 1:length(paramListHeader)
         paramName = paramListHeader{idP};
         idParam = find(strcmp(paramName, g_decArgo_adjVal(:, 1)));
         if (~isempty(idParam))
            if (~isempty(g_decArgo_adjVal{idParam, 3}))
               valStr = squeeze_list(unique(g_decArgo_adjVal{idParam, 3}));
               fprintf(fId, ';%s', valStr);
            else
               fprintf(fId, ';');
            end
         else
            fprintf(fId, ';');
         end
      end
   end
   fprintf(fId, '\n');
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
% Adjust trajectory measurements with profile DM data.
%
% SYNTAX :
% [o_trajCNumList] = adjust_traj_data(a_floatNum, a_ncFileDir, ...
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
%   02/13/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_trajCNumList] = adjust_traj_data(a_floatNum, a_ncFileDir, ...
   a_dmCProfileData, a_cParamList, a_dmBProfileData, a_bParamList)

% output parameters initialization
o_trajCNumList = [];

% global measurement codes
global g_MC_DriftAtPark;

% list of MC with PSAL measurement
global g_decArgo_psalMeasCodeList;


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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process DM data

juldInfo = get_netcdf_param_attributes('JULD');
presInfo = get_netcdf_param_attributes('PRES');

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
   % adjust TRAJ data

   trajCyNumList = unique([dmProfileData{:, 4}]);
   for cyNum = trajCyNumList

      % if (cyNum == 63)
      %    a=1
      % end

      idPrev = '';
      idCur = find([dmProfileData{:, 4}] == cyNum);
      if (cyNum > 1)
         idPrev = find([dmProfileData{:, 4}] == cyNum-1);
      end
      if (~isempty(idPrev))
         profPrev = dmProfileData{idPrev, 3};
         profCur = dmProfileData{idCur, 3};

         paramList = intersect(profPrev.paramList, profCur.paramList, 'stable');
         % paramList = setdiff(paramList, 'PRES');

         trajPresData = get_data_from_name('PRES', ncTrajData);
         for idParam = 1:length(paramList)
            paramName = paramList{idParam};
            if ((idLoop == 2) && strcmp(paramName, 'PRES'))
               continue
            end
            paramInfo = get_netcdf_param_attributes(paramName);
            trajParamData = get_data_from_name(paramList{idParam}, ncTrajData);

            idNoDef = find((trajPresData ~= presInfo.fillValue) & ...
               (trajParamData ~= paramInfo.fillValue) & ...
               (cycleNumber == cyNum));
            if (~isempty(idNoDef))

               mcList = unique(measurementCode(idNoDef));

               if (strcmp('PSAL', paramName))
                  g_decArgo_psalMeasCodeList = unique([g_decArgo_psalMeasCodeList; mcList]);
               end

               for measCode = mcList'
                  switch (measCode)
                     case g_MC_DriftAtPark

                        o_trajCNumList = unique([o_trajCNumList cyNum]);
                        idNoDef = find( ...
                           (juldBest ~= juldInfo.fillValue) & ...
                           (trajPresData ~= presInfo.fillValue) & ...
                           (trajParamData ~= paramInfo.fillValue) & ...
                           (cycleNumber == cyNum) & ...
                           (measurementCode == measCode));
                        ok = adjust_param_data( ...
                           a_floatNum, cyNum, paramName, measCode, ...
                           juldBest(idNoDef), ...
                           double(trajPresData(idNoDef)), ...
                           double(trajParamData(idNoDef)), ...
                           profPrev, profCur);
                  end
               end
            end
         end
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
%   02/13/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = adjust_param_data(a_floatNum, a_cyNum, a_paramName, a_measCode, ...
   a_juldTrajData, a_trajPresData, a_trajParamData, a_profPrev, a_profCur)

% output parameters initialization
o_ok = 0;

% QC flag values
global g_decArgo_qcStrDef;           % ' '
global g_decArgo_qcStrNoQc;          % '0'
global g_decArgo_qcStrGood;          % '1'
global g_decArgo_qcStrProbablyGood;  % '2'
global g_decArgo_qcStrCorrectable;   % '3'
global g_decArgo_qcStrBad;           % '4'
global g_decArgo_qcStrInterpolated;  % '8'
global g_decArgo_qcStrMissing;       % '9'

% Id of the CSV output file
global g_decArgo_csvIdTraj;
global g_decArgo_csvIdCheckTraj;

% adjustment values
global g_decArgo_adjVal;


% one loop for each profile (previous and current)
for idLoop = 1:2
   if (idLoop == 1)
      prof = a_profPrev;
   else
      prof = a_profCur;
   end

   idPres = find(strcmp('PRES', prof.paramList));
   profPresData = prof.data(:, idPres);
   profPresDataQc = prof.dataQc(:, idPres);

   idParam = find(strcmp(a_paramName, prof.paramList));
   profParamData = prof.data(:, idParam);
   profParamDataAdj = prof.dataAdj(:, idParam);
   profParamDataAdjQc = prof.dataAdjQc(:, idParam);

   if (idLoop == 1)
      prevProfPresData = profPresData;
      prevProfPresDataQc = profPresDataQc;

      prevProfParamData = profParamData;
      prevProfParamDataAdj = profParamDataAdj;
      prevProfParamDataAdjQc = profParamDataAdjQc;
   else
      curProfPresData = profPresData;
      curProfPresDataQc = profPresDataQc;

      curProfParamData = profParamData;
      curProfParamDataAdj = profParamDataAdj;
      curProfParamDataAdjQc = profParamDataAdjQc;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% adjust TRAJ measurements
idNoDefPrev = find( ...
   ~isnan(prevProfPresData) & ...
   ((prevProfPresDataQc == g_decArgo_qcStrGood) | ...
   (prevProfPresDataQc == g_decArgo_qcStrProbablyGood)) & ...
   ~isnan(prevProfParamData) & ...
   ~isnan(prevProfParamDataAdj) & ...
   ((prevProfParamDataAdjQc == g_decArgo_qcStrGood) | ...
   (prevProfParamDataAdjQc == g_decArgo_qcStrProbablyGood)));
idNoDefCur = find( ...
   ~isnan(curProfPresData) & ...
   ((curProfPresDataQc == g_decArgo_qcStrGood) | ...
   (curProfPresDataQc == g_decArgo_qcStrProbablyGood)) & ...
   ~isnan(curProfParamData) & ...
   ~isnan(curProfParamDataAdj) & ...
   ((curProfParamDataAdjQc == g_decArgo_qcStrGood) | ...
   (curProfParamDataAdjQc == g_decArgo_qcStrProbablyGood)));
if ((length(idNoDefPrev) > 1) && (length(idNoDefCur) > 1))

   prevPresData = prevProfPresData(idNoDefPrev);
   prevParamData = prevProfParamData(idNoDefPrev);
   prevParamDataAdj = prevProfParamDataAdj(idNoDefPrev);
   if (length(prevPresData) ~= length(unique(prevPresData)))
      [prevPresData, measId] = pressure_increasing_test(prevPresData, a_profPrev.vss);
      prevParamData = prevParamData(measId);
      prevParamDataAdj = prevParamDataAdj(measId);
      fprintf('INFO: Float %d: PROF cycle %d: "Pressure increasing test" run anew\n', ...
         a_floatNum, a_profPrev.cycleNumber);
   end
   prevParamAdjVal = prevParamDataAdj - prevParamData;

   % create the profile of the adjustment values at the pressures of the TRAJ
   % measurements
   prevParamAdjValInt = interp1(prevPresData, prevParamAdjVal, a_trajPresData, 'linear');

   curPresData = curProfPresData(idNoDefCur);
   curParamData = curProfParamData(idNoDefCur);
   curParamDataAdj = curProfParamDataAdj(idNoDefCur);
   if (length(curPresData) ~= length(unique(curPresData)))
      [curPresData, measId] = pressure_increasing_test(curPresData, a_profCur.vss);
      curParamData = curParamData(measId);
      curParamDataAdj = curParamDataAdj(measId);
      fprintf('INFO: Float %d: PROF cycle %d: "Pressure increasing test" run anew\n', ...
         a_floatNum, a_profCur.cycleNumber);
   end
   curParamAdjVal = curParamDataAdj - curParamData;

   % create the profile of the adjustment values at the pressures of the TRAJ
   % measurements
   curParamAdjValInt = interp1(curPresData, curParamAdjVal, a_trajPresData, 'linear');

   % check TRAJ PARAM measurements against PROF ones
   if (~strcmp(a_paramName, 'PRES'))

      % create the profile of the parameter values at the pressures of the TRAJ
      % measurements
      prevParamInt = interp1(prevPresData, prevParamData, a_trajPresData, 'linear');

      % create the profile of the parameter values at the pressures of the TRAJ
      % measurements
      curParamInt = interp1(curPresData, curParamData, a_trajPresData, 'linear');

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % store max diff of 2 adjustments for CSV output
      idNoNan = find(~isnan(prevParamInt) & ~isnan(curParamInt));
      maxDiff = max([abs(prevParamInt(idNoNan)-a_trajParamData(idNoNan)); ...
         abs(curParamInt(idNoNan)-a_trajParamData(idNoNan))]);
      if (~isempty(g_decArgo_adjVal))
         idParam = find(strcmp(a_paramName, g_decArgo_adjVal(:, 1)));
         if (~isempty(idParam))
            if (~isnan(g_decArgo_adjVal{idParam, 6}))
               g_decArgo_adjVal{idParam, 6} = max(g_decArgo_adjVal{idParam, 6}, maxDiff);
            else
               g_decArgo_adjVal{idParam, 6} = maxDiff;
            end
         else
            g_decArgo_adjVal = [g_decArgo_adjVal; {a_paramName} {''} {''} {nan} {nan} {maxDiff}];
         end
      else
         g_decArgo_adjVal = [{a_paramName} {''} {''} {nan} {nan} {maxDiff}];
      end
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      if (g_decArgo_csvIdCheckTraj ~= -1)

         for idM = 1:length(a_trajPresData)

            if (~isnan(prevParamInt(idM)) && ~isnan(curParamInt(idM)))
               fprintf(g_decArgo_csvIdCheckTraj, '%d;%d;%s;%s;%.3f;%.4f;%.4f;%e;%.4f;%e\n', ...
                  a_floatNum, a_cyNum, a_paramName, get_meas_code_name(a_measCode), ...
                  a_trajPresData(idM), a_trajParamData(idM), ...
                  prevParamInt(idM), abs(a_trajParamData(idM)-prevParamInt(idM)), ...
                  curParamInt(idM), abs(a_trajParamData(idM)-curParamInt(idM)));
            end
         end
      end
   end

   if ((any((prevParamAdjValInt ~= 0) & ~isnan(prevParamAdjValInt))) || ...
         (any((curParamAdjValInt ~= 0) & ~isnan(curParamAdjValInt))))

      if (((a_profPrev.juldQc == g_decArgo_qcStrGood) || (a_profPrev.juldQc == g_decArgo_qcStrProbablyGood)) && ...
            ((a_profCur.juldQc == g_decArgo_qcStrGood) || (a_profCur.juldQc == g_decArgo_qcStrProbablyGood)))

         trajParamAdjVal = nan(size(a_trajParamData));
         trajParamDataAdj = nan(size(a_trajParamData)); % data interpolation
         trajParamDataAdj2 = nan(size(a_trajParamData)); % SCI info adjustment
         for idM = 1:length(a_trajPresData)

            if (~isnan(prevParamAdjValInt(idM)) && ~isnan(curParamAdjValInt(idM)))

               trajParamAdjVal(idM) = interp1( ...
                  [a_profPrev.juld; a_profCur.juld], ...
                  [prevParamAdjValInt(idM); curParamAdjValInt(idM)], a_juldTrajData(idM), 'linear');
               trajParamDataAdj(idM) = a_trajParamData(idM) + trajParamAdjVal(idM);

               offsetInt = nan;
               if (~isnan(a_profPrev.psalOffset) || ~isnan(a_profCur.psalOffset))
                  if (isnan(a_profPrev.psalOffset))
                     a_profPrev.psalOffset = 0;
                  end
                  if (isnan(a_profCur.psalOffset))
                     a_profCur.psalOffset = 0;
                  end
                  offsetInt = interp1( ...
                     [a_profPrev.juld; a_profCur.juld], ...
                     [a_profPrev.psalOffset; a_profCur.psalOffset], a_juldTrajData(idM), 'linear');
                  trajParamDataAdj2(idM) = a_trajParamData(idM) + offsetInt;
               end

               if (g_decArgo_csvIdTraj ~= -1)
                  fprintf(g_decArgo_csvIdTraj, '%d;%d;%s;%s;%d;''%s;%e;''%s;%e;''%s;%.3f;%.4f;%e;%.4f;', ...
                     a_floatNum, a_cyNum, a_paramName, get_meas_code_name(a_measCode), idM, ...
                     julian_2_gregorian_dec_argo(a_profPrev.juld), prevParamAdjValInt(idM), ...
                     julian_2_gregorian_dec_argo(a_profCur.juld), curParamAdjValInt(idM), ...
                     julian_2_gregorian_dec_argo(a_juldTrajData(idM)), a_trajPresData(idM), a_trajParamData(idM), ...
                     trajParamAdjVal(idM), a_trajParamData(idM)+trajParamAdjVal(idM));

                  if (strcmp(a_paramName, 'PSAL'))
                     fprintf(g_decArgo_csvIdTraj, '%e;%e;%e;%.4f;%e;', ...
                        a_profPrev.psalOffset, a_profCur.psalOffset, ...
                        offsetInt, trajParamDataAdj2(idM), abs(trajParamAdjVal(idM)-offsetInt));
                  else
                     fprintf(g_decArgo_csvIdTraj, ';;;;;');
                  end

                  nCalibPrev = 0;
                  nCalibCur = 0;
                  idParam = find(strcmp(a_paramName, a_profPrev.paramList));
                  if (~isempty(idParam))
                     sciCalEqPrev = a_profPrev.sciCalEq{idParam};
                     sciCalCoefPrev = a_profPrev.sciCalCoef{idParam};
                     sciCalComPrev = a_profPrev.sciCalCom{idParam};
                     sciCalDatePrev = a_profPrev.sciCalDate{idParam};
                     nCalibPrev = length(sciCalEqPrev);
                  end
                  idParam = find(strcmp(a_paramName, a_profCur.paramList));
                  if (~isempty(idParam))
                     sciCalEqCur = a_profCur.sciCalEq{idParam};
                     sciCalCoefCur = a_profCur.sciCalCoef{idParam};
                     sciCalComCur = a_profCur.sciCalCom{idParam};
                     sciCalDateCur = a_profCur.sciCalDate{idParam};
                     nCalibCur = length(sciCalEqCur);
                  end

                  fprintf(g_decArgo_csvIdTraj, '%d;', nCalibPrev);
                  sciCalEq = '|';
                  sciCalCoef= '|';
                  sciCalCom = '|';
                  sciCalDate = '|';
                  for idC = 1:nCalibPrev
                     sciCalEq = [sciCalEq '|' sciCalEqPrev{idC} '|'];
                     sciCalCoef = [sciCalCoef '|' sciCalCoefPrev{idC} '|'];
                     sciCalCom = [sciCalCom '|' sciCalComPrev{idC} '|'];
                     sciCalDate = [sciCalDate '|' sciCalDatePrev{idC} '|'];
                  end
                  sciCalEq = regexprep(sciCalEq, ';', ' ');
                  sciCalCoef = regexprep(sciCalCoef, ';', ' ');
                  sciCalCom = regexprep(sciCalCom, ';', ' ');
                  fprintf(g_decArgo_csvIdTraj, '%s;%s;%s;%s;', ...
                     sciCalEq, sciCalCoef, sciCalCom, sciCalDate);

                  fprintf(g_decArgo_csvIdTraj, '%d;', nCalibCur);
                  sciCalEq = '|';
                  sciCalCoef= '|';
                  sciCalCom = '|';
                  sciCalDate = '|';
                  for idC = 1:nCalibCur
                     sciCalEq = [sciCalEq '|' sciCalEqCur{idC} '|'];
                     sciCalCoef = [sciCalCoef '|' sciCalCoefCur{idC} '|'];
                     sciCalCom = [sciCalCom '|' sciCalComCur{idC} '|'];
                     sciCalDate = [sciCalDate '|' sciCalDateCur{idC} '|'];
                  end
                  sciCalEq = regexprep(sciCalEq, ';', ' ');
                  sciCalCoef = regexprep(sciCalCoef, ';', ' ');
                  sciCalCom = regexprep(sciCalCom, ';', ' ');
                  fprintf(g_decArgo_csvIdTraj, '%s;%s;%s;%s;', ...
                     sciCalEq, sciCalCoef, sciCalCom, sciCalDate);

                  fprintf(g_decArgo_csvIdTraj, '\n');
               end
            else
               % a=1
            end
         end

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % store max diff of 2 adjustments for CSV output
         if (any(~isnan(trajParamDataAdj2)))
            idNoNan = find(~isnan(trajParamDataAdj) & ~isnan(trajParamDataAdj2));
            maxDiff = max(abs(trajParamDataAdj(idNoNan)-trajParamDataAdj2(idNoNan)));
            if (~isempty(g_decArgo_adjVal))
               idPsal = find(strcmp('PSAL', g_decArgo_adjVal(:, 1)));
               if (~isempty(idPsal))
                  if (~isnan(g_decArgo_adjVal{idPsal, 5}))
                     g_decArgo_adjVal{idPsal, 5} = max(g_decArgo_adjVal{idPsal, 5}, maxDiff);
                  else
                     g_decArgo_adjVal{idPsal, 5} = maxDiff;
                  end
               else
                  g_decArgo_adjVal = [g_decArgo_adjVal; {'PSAL'} {''} {''} {nan} {maxDiff} {nan}];
               end
            else
               g_decArgo_adjVal = [{'PSAL'} {''} {''} {nan} {maxDiff} {nan}];
            end
         end
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      else
         fprintf('ERROR: Anomaly (profile JulD not set)\n');
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % store list of adjusted values for CSV output
   uParamAdjVal = unique([prevParamAdjVal; curParamAdjVal]);
   uParamAdjVal(isnan(uParamAdjVal)) = [];
   if (~isempty(g_decArgo_adjVal))
      idParam = find(strcmp(a_paramName, g_decArgo_adjVal(:, 1)));
      if (~isempty(idParam))
         if (~isempty(g_decArgo_adjVal{idParam, 2}))
            g_decArgo_adjVal{idParam, 2} = unique([g_decArgo_adjVal{idParam, 2}; uParamAdjVal]);
         else
            g_decArgo_adjVal{idParam, 2} = uParamAdjVal;
         end
      else
         g_decArgo_adjVal = [g_decArgo_adjVal; {a_paramName} {uParamAdjVal} {''} {nan} {nan} {nan}];
      end
   else
      g_decArgo_adjVal = [{a_paramName} {uParamAdjVal} {''} {nan} {nan} {nan}];
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

else

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % store list of cycles with <PARAM>_ADJUSTED_QC=4 for CSV output
   if (isempty(idNoDefPrev))
      if (all(prevProfParamDataAdjQc == g_decArgo_qcStrBad))
         if (~isempty(g_decArgo_adjVal))
            idParam = find(strcmp(a_paramName, g_decArgo_adjVal(:, 1)));
            if (~isempty(idParam))
               if (~isempty(g_decArgo_adjVal{idParam, 3}))
                  g_decArgo_adjVal{idParam, 3} = unique([g_decArgo_adjVal{idParam, 3} a_profPrev.cycleNumber]);
               else
                  g_decArgo_adjVal{idParam, 3} = a_profPrev.cycleNumber;
               end
            else
               g_decArgo_adjVal = [g_decArgo_adjVal; {a_paramName} {''} {a_profPrev.cycleNumber} {nan} {nan} {nan}];
            end
         else
            g_decArgo_adjVal = [{a_paramName} {''} {a_profPrev.cycleNumber} {nan} {nan} {nan}];
         end
      end
   end
   if (isempty(idNoDefCur))
      if (all(curProfParamDataAdjQc == g_decArgo_qcStrBad))
         if (~isempty(g_decArgo_adjVal))
            idParam = find(strcmp(a_paramName, g_decArgo_adjVal(:, 1)));
            if (~isempty(idParam))
               if (~isempty(g_decArgo_adjVal{idParam, 3}))
                  g_decArgo_adjVal{idParam, 3} = unique([g_decArgo_adjVal{idParam, 3} a_profCur.cycleNumber]);
               else
                  g_decArgo_adjVal{idParam, 3} = a_profCur.cycleNumber;
               end
            else
               g_decArgo_adjVal = [g_decArgo_adjVal; {a_paramName} {''} {a_profCur.cycleNumber} {nan} {nan} {nan}];
            end
         else
            g_decArgo_adjVal = [{a_paramName} {''} {a_profCur.cycleNumber} {nan} {nan} {nan}];
         end
      end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
%   02/13/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dmCProfileData, o_cParamList, o_dmBProfileData, o_bParamList] = ...
   get_profile_dm_data(a_floatNum, a_ncFileDir)

% output parameters initialization
o_dmCProfileData = [];
o_cParamList = [];
o_dmBProfileData = [];
o_bParamList = [];

% adjustment values
global g_decArgo_adjVal;


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
            prof.psalSlope = nan;
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

               % compare provided profile adjusted values with values adjusted
               % from SCIENTIFIC_CALIB_* information
               [prof, maxDiff] = get_profile_max_diff_adj_val(a_floatNum, prof);

               if (~isnan(maxDiff))
                  % store max diff absolute value for CSV output
                  if (~isempty(g_decArgo_adjVal))
                     idPsal = find(strcmp('PSAL', g_decArgo_adjVal(:, 1)));
                     if (~isempty(idPsal))
                        if (~isnan(g_decArgo_adjVal{idPsal, 4}))
                           g_decArgo_adjVal{idPsal, 4} = max(g_decArgo_adjVal{idPsal, 4}, maxDiff);
                        else
                           g_decArgo_adjVal{idPsal, 4} = maxDiff;
                        end
                     else
                        g_decArgo_adjVal = [g_decArgo_adjVal; {'PSAL'} {''} {''} {maxDiff} {nan} {nan}];
                     end
                  else
                     g_decArgo_adjVal = [{'PSAL'} {''} {''} {maxDiff} {nan} {nan}];
                  end
               end
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
% Compare provided profile adjusted values with values adjusted from
% SCIENTIFIC_CALIB_* information.
%
% SYNTAX :
% [o_profStruct, o_maxDiff] = get_profile_max_diff_adj_val(a_floatNum, a_profStruct)
%
% INPUT PARAMETERS :
%   a_floatNum   : float WMO number
%   a_profStruct : input DM profile structure
%
% OUTPUT PARAMETERS :
%   a_profStruct : output DM profile structure
%   o_maxDiff    : max absolute difference between the 2 adjusted profiles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profStruct, o_maxDiff] = get_profile_max_diff_adj_val(a_floatNum, a_profStruct)

% output parameters initialization
o_profStruct = a_profStruct;
o_maxDiff = nan;

% Id of the CSV output files
global g_decArgo_csvIdProf;

% Arvor Deep flag
global g_decArgo_arvorDeepFlag;


% retrieve PSAL data
idPsal = find(strcmp('PSAL', o_profStruct.paramList));
psal = o_profStruct.data(:, idPsal);
psalAdjusted = o_profStruct.dataAdj(:, idPsal);

if (any(~isnan(psalAdjusted)))
   idNoNan = find(~isnan(psalAdjusted) & ~isnan(psal));
   if (any(psalAdjusted(idNoNan) ~= psal(idNoNan)))

      if (g_decArgo_arvorDeepFlag == 0)

         % retrieve adjustment information from SCIENTIFIC_CALIB_*
         equation = o_profStruct.sciCalEq{idPsal};
         coef = o_profStruct.sciCalCoef{idPsal};
         if (length(equation) > 1)
            calDate = o_profStruct.sciCalDate{idPsal};
            [~, idSort] = sort(calDate);
            equation = equation{idSort(end)};
            coef = coef{idSort(end)};
         else
            equation = equation{1};
            coef = coef{1};
         end

         if (strncmp(equation, 'PSAL + dS, where', length('PSAL + dS, where')))
            dsStr = strfind(coef, 'dS=');
            if (~isempty(dsStr))
               dS = str2double(coef(dsStr+length('dS='):end));
               o_profStruct.psalSlope = 1;
               o_profStruct.psalOffset = dS;
            else
               fprintf('ERROR: Anomaly (cannot parse PSAL equation)\n');
            end
         elseif (strcmp(equation, 'PSAL_ADJUSTED = a1 * PSAL + a0'))
            [val, count, errmsg, ~] = sscanf(coef, 'a1=%f, a0=%f');
            if (isempty(errmsg) && (count == 2))
               o_profStruct.psalSlope = val(1);
               o_profStruct.psalOffset = val(2);
            else
               fprintf('ERROR: Anomaly (cannot parse PSAL equation)\n');
            end
         elseif (strncmp(equation, 'PSAL_ADJUSTED = PSAL  + Delta_S, where', length('PSAL_ADJUSTED = PSAL  + Delta_S, where')))
            dsStart = strfind(coef, 'dS =');
            dsStop = strfind(coef, '(+');
            dsStop = dsStop(end);
            if (~isempty(dsStart) && ~isempty(dsStop))
               dS = str2double(coef(dsStart+length('dS ='):dsStop-1));
               o_profStruct.psalSlope = 1;
               o_profStruct.psalOffset = dS;
            else
               fprintf('ERROR: Anomaly (cannot parse PSAL equation)\n');
            end
         elseif (strncmp(equation, 'PSAL_ADJUSTED=PSAL + dS, where', length('PSAL_ADJUSTED=PSAL + dS, where')))
            dsStart = strfind(coef, 'dS=');
            dsStop = strfind(coef, '(+');
            dsStop = dsStop(end);
            if (~isempty(dsStart) && ~isempty(dsStop))
               dS = str2double(coef(dsStart+length('dS='):dsStop-1));
               o_profStruct.psalSlope = 1;
               o_profStruct.psalOffset = dS;
            else
               fprintf('ERROR: Anomaly (cannot parse PSAL equation)\n');
            end
         elseif (strcmp(equation, 'PSAL_ADJUSTED = PSAL + dS.'))
            dsStart = strfind(coef, 'dS =');
            dsStop = strfind(coef, '+/-');
            dsStop = dsStop(end);
            if (~isempty(dsStart) && ~isempty(dsStop))
               dS = str2double(coef(dsStart+length('dS ='):dsStop-1));
               o_profStruct.psalSlope = 1;
               o_profStruct.psalOffset = dS;
            else
               fprintf('ERROR: Anomaly (cannot parse PSAL equation)\n');
            end
         elseif (strcmp(equation, 'PSAL_ADJUSTED = PSAL  + launch_offset'))
            dsStr = strfind(coef, 'launch_offset =');
            if (~isempty(dsStr))
               dS = str2double(coef(dsStr+length('launch_offset ='):end));
               o_profStruct.psalSlope = 1;
               o_profStruct.psalOffset = dS;
            else
               fprintf('ERROR: Anomaly (cannot parse PSAL equation)\n');
            end
         else
            fprintf('ERROR: Anomaly (cannot parse PSAL equation)\n');
         end
      end

      if (~isnan(o_profStruct.psalSlope) && ~isnan(o_profStruct.psalOffset))
         if (o_profStruct.psalSlope ~= 1)
            fprintf('WARNING: PSAL slope %g\n', o_profStruct.psalSlope);
         end

         % psalAdjustedBis = round_argo(psal*o_profStruct.psalSlope + o_profStruct.psalOffset, 'PSAL');
         psalAdjustedBis = psal*o_profStruct.psalSlope + o_profStruct.psalOffset;
         o_maxDiff = max(abs(psalAdjusted(idNoNan) - psalAdjustedBis(idNoNan)));
         % if (o_maxDiff >= 0.003194483)
         %    a=1
         % end
         if (g_decArgo_csvIdProf ~= -1)
            idPres = find(strcmp('PRES', o_profStruct.paramList));
            pres = o_profStruct.data(:, idPres);
            profDir = 'A';
            if (o_profStruct.direction == 1)
               profDir = 'D';
            end
            for idL = 1:length(idNoNan)
               id = idNoNan(idL);
               adjVal = psalAdjusted(id)-psal(id);
               diffVal = abs(psalAdjusted(id) - psalAdjustedBis(id));
               fprintf(g_decArgo_csvIdProf, '%d;%d;%c;%.3f;%.4f;%.4f;%e;%e;%.4f;%e\n', ...
                  a_floatNum, a_profStruct.cycleNumber, profDir, ...
                  pres(id), psal(id), psalAdjusted(id), adjVal, ...
                  o_profStruct.psalOffset, psalAdjustedBis(id), diffVal);
            end
         end
      end
   end
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
%   02/15/2024 - RNU - creation
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
      % if (bProf.cycleNumber == 12)
      %    a=1
      % end
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
% Apply RTQC "Pressure increasing test" on input PRES profile.
%
% SYNTAX :
%  [o_presValues, o_measId] = pressure_increasing_test(a_presValues, a_profVss)
%
% INPUT PARAMETERS :
%   a_presValues : input PRES values
%   a_profVss    : profile VERTICAL_SAMPLING_SCHEME
%
% OUTPUT PARAMETERS :
%   a_presValues : output PRES values
%   o_measId     : kept measurement ids from input data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/15/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_presValues, o_measId] = pressure_increasing_test(a_presValues, a_profVss)

% output parameters initialization
o_presValues = a_presValues;
o_measId = 1:length(a_presValues);


if (strncmp(a_profVss, 'Near-surface sampling:', length('Near-surface sampling:')))
   % for NS profiles, start algorithm from deepest value
   idToFlag = [];
   idStart = length(a_presValues);
   pMin = a_presValues(idStart);
   for id = idStart-1:-1:1
      if (a_presValues(id) >= pMin)
         idToFlag = [idToFlag id];
      else
         pMin = a_presValues(id);
      end
   end
else
   % otherwise, start algorithm from middle of the profile
   idToFlag = [];
   idStart = fix(length(a_presValues)/2);
   pMin = a_presValues(idStart);
   for id = idStart-1:-1:1
      if (a_presValues(id) >= pMin)
         idToFlag = [idToFlag id];
      else
         pMin = a_presValues(id);
      end
   end
   pMax = a_presValues(idStart);
   for id = idStart+1:length(a_presValues)
      if (a_presValues(id) <= pMax)
         idToFlag = [idToFlag id];
      else
         pMax = a_presValues(id);
      end
   end
end

o_presValues(idToFlag) = [];
o_measId = setdiff(o_measId, idToFlag);

return

% ------------------------------------------------------------------------------
% Round parameter measurement to a precision associated to each parameter
%
% SYNTAX :
% [o_values] = round_argo(a_values, a_paramName)
%
% INPUT PARAMETERS :
%   a_values    : input data
%   a_paramName : parameter name
%
% OUTPUT PARAMETERS :
%   o_values : output rounded data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/20/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_values] = round_argo(a_values, a_paramName)

o_values = double(a_values);

paramName = regexprep(a_paramName, '_ADJUSTED', '');

switch (paramName)
   case {'PRES'}
      res = 1e-3;
   case {'TEMP'}
      res = 1e-3;
   case {'PSAL'}
      res = 1e-4;
   case {'DOXY'}
      res = 1e-3;
   case {'CHLA', 'CHLA_FLUORESCENCE'}
      res = 1e-4;
   case {'NITRATE'}
      res = 1e-3;
   case {'PH_IN_SITU_TOTAL'}
      res = 1e-4;
   case {'BBP470', 'BBP532', 'BBP700'}
      res = 1e-7;
   otherwise
      res = 1e-7;
end

paramInfo = get_netcdf_param_attributes(paramName);
if (~isempty(paramInfo))
   idNoDef = find(a_values ~= paramInfo.fillValue);
else
   idNoDef = 1:length(a_values);
end
o_values(idNoDef) = round(double(a_values(idNoDef))/res)*res;

return
