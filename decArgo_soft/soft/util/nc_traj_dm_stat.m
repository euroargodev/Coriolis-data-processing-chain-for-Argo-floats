% ------------------------------------------------------------------------------
% Collect adjustment information in a DM trajectory file.
%
% SYNTAX :
%   nc_traj_dm_stat(6902899)
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
%   06/21/2024 - RNU - creation
% ------------------------------------------------------------------------------
function nc_traj_dm_stat(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START

% default list of floats to process
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_tmp.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ANDRO_2_TRAJ-DM\Decomptes_20240621\arvor_in_andro.txt';

% top directory of the input DM TRAJ NetCDF files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\TRAJ_DM_2024\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the csv file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';

% CONFIGURATION - END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

logFile = [DIR_LOG_FILE '/' 'nc_traj_dm_stat' name '_' currentTime '.log'];
diary(logFile);
tic;

% create output CSV file
csvFilepathName = [DIR_CSV_FILE '\nc_traj_dm_stat' name '_' currentTime '.csv'];
fId = fopen(csvFilepathName, 'wt');
if (fId == -1)
   fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
   return
end
header = 'Level;WMO;CyNum;Data mode;Meas code;Param;Nb meas;Nb meas no DM;%;Nb meas DM;%;Nb Meas DM adj FV;%;Nb Meas DM adj 0;%; Nb meas DM adj <> 0;%';
fprintf(fId, '%s\n', header);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process floats of the list

juldInfo = get_netcdf_param_attributes('JULD');
presInfo = get_netcdf_param_attributes('PRES');
tempInfo = get_netcdf_param_attributes('TEMP');
psalInfo = get_netcdf_param_attributes('PSAL');

NB_LINE = 2000;
NB_COL = 15;
trajStatAll5 = repmat(cell(1, NB_COL), NB_LINE, 1);
cptLine5 = 1;

nbFloats = length(floatList);
for idFloat = 1:nbFloats

   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   inputFloatDir = [DIR_INPUT_NC_FILES '/' floatNumStr '/'];
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);

   trajFile = dir([inputFloatDir sprintf('%d_Dtraj.nc', floatNum)]);
   if (isempty(trajFile))
      fprintf('INFO: No trajectory file for float %d - ignored\n', ...
         floatNum);
      continue
   end
   trajFileName = trajFile(1).name;
   trajFilePathName = [inputFloatDir trajFileName];

   wantedVars = [ ...
      {'MEASUREMENT_CODE'} ...
      {'CYCLE_NUMBER'} ...
      {'CYCLE_NUMBER_ADJUSTED'} ...
      {'DATA_MODE'} ...
      {'TRAJECTORY_PARAMETERS'} ...
      {'TRAJECTORY_PARAMETER_DATA_MODE'} ...
      {'JULD_DATA_MODE'} ...
      {'CYCLE_NUMBER_INDEX'} ...
      {'CYCLE_NUMBER_INDEX_ADJUSTED'} ...
      {'JULD'} ...
      {'JULD_QC'} ...
      {'JULD_ADJUSTED'} ...
      {'JULD_ADJUSTED_QC'} ...
      {'PRES'} ...
      {'PRES_QC'} ...
      {'PRES_ADJUSTED'} ...
      {'PRES_ADJUSTED_QC'} ...
      {'PRES_ADJUSTED_ERROR'} ...
      {'TEMP'} ...
      {'TEMP_QC'} ...
      {'TEMP_ADJUSTED'} ...
      {'TEMP_ADJUSTED_QC'} ...
      {'TEMP_ADJUSTED_ERROR'} ...
      {'PSAL'} ...
      {'PSAL_QC'} ...
      {'PSAL_ADJUSTED'} ...
      {'PSAL_ADJUSTED_QC'} ...
      {'PSAL_ADJUSTED_ERROR'} ...
      ];

   ncTrajData = get_data_from_nc_file(trajFilePathName, wantedVars);

   measurementCode = get_data_from_name('MEASUREMENT_CODE', ncTrajData);
   cycleNumber = get_data_from_name('CYCLE_NUMBER', ncTrajData);
   cycleNumberAdj = get_data_from_name('CYCLE_NUMBER_ADJUSTED', ncTrajData);
   dataMode = get_data_from_name('DATA_MODE', ncTrajData);
   trajParam = get_data_from_name('TRAJECTORY_PARAMETERS', ncTrajData);
   trajParamDataMode = get_data_from_name('TRAJECTORY_PARAMETER_DATA_MODE', ncTrajData);
   juldDataMode = get_data_from_name('JULD_DATA_MODE', ncTrajData);
   cycleNumberIndex = get_data_from_name('CYCLE_NUMBER_INDEX', ncTrajData);
   cycleNumberIndexAdj = get_data_from_name('CYCLE_NUMBER_INDEX_ADJUSTED', ncTrajData);

   juldData = get_data_from_name('JULD', ncTrajData);
   juldQcData = get_data_from_name('JULD_QC', ncTrajData);
   juldAdjData = get_data_from_name('JULD_ADJUSTED', ncTrajData);
   juldAdjQcData = get_data_from_name('JULD_ADJUSTED_QC', ncTrajData);

   presData = get_data_from_name('PRES', ncTrajData);
   presQcData = get_data_from_name('PRES_QC', ncTrajData);
   presAdjData = get_data_from_name('PRES_ADJUSTED', ncTrajData);
   presAdjQcData = get_data_from_name('PRES_ADJUSTED_QC', ncTrajData);
   presAdjErrData = get_data_from_name('PRES_ADJUSTED_ERROR', ncTrajData);

   tempData = get_data_from_name('TEMP', ncTrajData);
   tempQcData = get_data_from_name('TEMP_QC', ncTrajData);
   tempAdjData = get_data_from_name('TEMP_ADJUSTED', ncTrajData);
   tempAdjQcData = get_data_from_name('TEMP_ADJUSTED_ERROR', ncTrajData);
   tempAdjErrData = get_data_from_name('TEMP_ADJUSTED_ERROR', ncTrajData);

   psalData = get_data_from_name('PSAL', ncTrajData);
   psalQcData = get_data_from_name('PSAL_QC', ncTrajData);
   psalAdjData = get_data_from_name('PSAL_ADJUSTED', ncTrajData);
   psalAdjQcData = get_data_from_name('PSAL_ADJUSTED_QC', ncTrajData);
   psalAdjErrData = get_data_from_name('PSAL_ADJUSTED_ERROR', ncTrajData);

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

   NB_LINE = 10000;
   trajStatAll = repmat(cell(1, NB_COL), NB_LINE, 1);
   cptLine = 1;

   for idCy = 1:length(dataMode)
      if (dataMode(idCy) == 'D')
         cyNumIndex = cycleNumberIndexAdj(idCy);
         idMeasForCy = find(cycleNumberAdj == cyNumIndex);
      else
         cyNumIndex = cycleNumberIndex(idCy);

         trajStat = [{cyNumIndex} {dataMode(idCy)} {''} {''} {''} {''} {''} {''} {''} {''} {''} {''} {''} {''} {''}];
         trajStatAll(cptLine, :) = trajStat;
         cptLine = cptLine + 1;
         if (cptLine > length(trajStatAll))
            trajStatAll = cat(1, trajStatAll, repmat(cell(1, NB_COL), NB_LINE, 1));
         end
         continue
      end

      mcList = unique(measurementCode(idMeasForCy));
      for measCode = mcList'

         idForMc = idMeasForCy(find([measurementCode(idMeasForCy)] == measCode));

         if (any(juldData(idForMc) ~= juldInfo.fillValue))
            idMeas = idForMc(find(juldData(idForMc) ~= juldInfo.fillValue));
            idMeasNoD = idMeas(find(juldDataMode(idMeas) ~= 'D'));
            idMeasD = idMeas(find(juldDataMode(idMeas) == 'D'));
            juld = juldData(idMeasD);
            juldAdj = juldAdjData(idMeasD);
            idAdjNan = find(juldAdj == juldInfo.fillValue);
            idAdjNoNan = find(juldAdj ~= juldInfo.fillValue);
            idAdjNull = find(juld(idAdjNoNan) == juldAdj(idAdjNoNan));
            idAdjNoNull = find(juld(idAdjNoNan) ~= juldAdj(idAdjNoNan));

            trajStat = [{cyNumIndex} {dataMode(idCy)} {measCode} {'JULD'} ...
               {length(idMeas)} ...
               {length(idMeasNoD)} {100*length(idMeasNoD)/length(idMeas)} ...
               {length(idMeasD)} {100*length(idMeasD)/length(idMeas)} ...
               {length(idAdjNan)} {100*length(idAdjNan)/length(idMeasD)} ...
               {length(idAdjNull)} {100*length(idAdjNull)/length(idMeasD)} ...
               {length(idAdjNoNull)} {100*length(idAdjNoNull)/length(idMeasD)}];
            trajStatAll(cptLine, :) = trajStat;
            cptLine = cptLine + 1;
            if (cptLine > size(trajStatAll, 1))
               trajStatAll = cat(1, trajStatAll, repmat(cell(1, NB_COL), NB_LINE, 1));
            end
         end

         if (any(presData(idForMc) ~= presInfo.fillValue))
            idMeas = idForMc(find(presData(idForMc) ~= presInfo.fillValue));
            idMeasNoD = idMeas(find(trajParamDataMode(presParamId, idMeas) ~= 'D'));
            idMeasD = idMeas(find(trajParamDataMode(presParamId, idMeas) == 'D'));
            pres = presData(idMeasD);
            presAdj = presAdjData(idMeasD);
            idAdjNan = find(presAdj == presInfo.fillValue);
            idAdjNoNan = find(presAdj ~= presInfo.fillValue);
            idAdjNull = find(pres(idAdjNoNan) == presAdj(idAdjNoNan));
            idAdjNoNull = find(pres(idAdjNoNan) ~= presAdj(idAdjNoNan));

            trajStat = [{cyNumIndex} {dataMode(idCy)} {measCode} {'PRES'} ...
               {length(idMeas)} ...
               {length(idMeasNoD)} {100*length(idMeasNoD)/length(idMeas)} ...
               {length(idMeasD)} {100*length(idMeasD)/length(idMeas)} ...
               {length(idAdjNan)} {100*length(idAdjNan)/length(idMeasD)} ...
               {length(idAdjNull)} {100*length(idAdjNull)/length(idMeasD)} ...
               {length(idAdjNoNull)} {100*length(idAdjNoNull)/length(idMeasD)}];
            trajStatAll(cptLine, :) = trajStat;
            cptLine = cptLine + 1;
            if (cptLine > size(trajStatAll, 1))
               trajStatAll = cat(1, trajStatAll, repmat(cell(1, NB_COL), NB_LINE, 1));
            end
         end

         if (any(tempData(idForMc) ~= tempInfo.fillValue))
            idMeas = idForMc(find(tempData(idForMc) ~= tempInfo.fillValue));
            idMeasNoD = idMeas(find(trajParamDataMode(tempParamId, idMeas) ~= 'D'));
            idMeasD = idMeas(find(trajParamDataMode(tempParamId, idMeas) == 'D'));
            temp = tempData(idMeasD);
            tempAdj = tempAdjData(idMeasD);
            idAdjNan = find(tempAdj == tempInfo.fillValue);
            idAdjNoNan = find(tempAdj ~= tempInfo.fillValue);
            idAdjNull = find(temp(idAdjNoNan) == tempAdj(idAdjNoNan));
            idAdjNoNull = find(temp(idAdjNoNan) ~= tempAdj(idAdjNoNan));

            trajStat = [{cyNumIndex} {dataMode(idCy)} {measCode} {'TEMP'} ...
               {length(idMeas)} ...
               {length(idMeasNoD)} {100*length(idMeasNoD)/length(idMeas)} ...
               {length(idMeasD)} {100*length(idMeasD)/length(idMeas)} ...
               {length(idAdjNan)} {100*length(idAdjNan)/length(idMeasD)} ...
               {length(idAdjNull)} {100*length(idAdjNull)/length(idMeasD)} ...
               {length(idAdjNoNull)} {100*length(idAdjNoNull)/length(idMeasD)}];
            trajStatAll(cptLine, :) = trajStat;
            cptLine = cptLine + 1;
            if (cptLine > size(trajStatAll, 1))
               trajStatAll = cat(1, trajStatAll, repmat(cell(1, NB_COL), NB_LINE, 1));
            end
         end

         if (any(psalData(idForMc) ~= psalInfo.fillValue))
            idMeas = idForMc(find(psalData(idForMc) ~= psalInfo.fillValue));
            idMeasNoD = idMeas(find(trajParamDataMode(psalParamId, idMeas) ~= 'D'));
            idMeasD = idMeas(find(trajParamDataMode(psalParamId, idMeas) == 'D'));
            psal = psalData(idMeasD);
            psalAdj = psalAdjData(idMeasD);
            idAdjNan = find(psalAdj == psalInfo.fillValue);
            idAdjNoNan = find(psalAdj ~= psalInfo.fillValue);
            idAdjNull = find(psal(idAdjNoNan) == psalAdj(idAdjNoNan));
            idAdjNoNull = find(psal(idAdjNoNan) ~= psalAdj(idAdjNoNan));

            trajStat = [{cyNumIndex} {dataMode(idCy)} {measCode} {'PSAL'} ...
               {length(idMeas)} ...
               {length(idMeasNoD)} {100*length(idMeasNoD)/length(idMeas)} ...
               {length(idMeasD)} {100*length(idMeasD)/length(idMeas)} ...
               {length(idAdjNan)} {100*length(idAdjNan)/length(idMeasD)} ...
               {length(idAdjNull)} {100*length(idAdjNull)/length(idMeasD)} ...
               {length(idAdjNoNull)} {100*length(idAdjNoNull)/length(idMeasD)}];
            trajStatAll(cptLine, :) = trajStat;
            cptLine = cptLine + 1;
            if (cptLine > size(trajStatAll, 1))
               trajStatAll = cat(1, trajStatAll, repmat(cell(1, NB_COL), NB_LINE, 1));
            end
         end
      end
   end
   trajStatAll(cptLine:end, :) = [];

   for idL = 1:size(trajStatAll, 1)
      if (trajStatAll{idL, 2} == 'D')
         fprintf(fId, '1;%d;%d;%c;%s;%s;%d;%d;%.1f;%d;%.1f;%d;%.1f;%d;%.1f;%d;%.1f\n', ...
            floatNum, trajStatAll{idL, 1:2}, ...
            get_meas_code_name(trajStatAll{idL, 3}), ...
            trajStatAll{idL, 4:NB_COL});
      else
         fprintf(fId, '1;%d;%d;%c\n', ...
            floatNum, trajStatAll{idL, 1:2});
      end
   end

   idD = find([trajStatAll{:, 2}] == 'D');
   trajStatAll2 = trajStatAll(idD, :);
   cyNumList = unique([trajStatAll2{:, 1}]);
   for cyN = cyNumList
      idForCy = find([trajStatAll2{:, 1}] == cyN);
      paramList = unique({trajStatAll2{idForCy, 4}}, 'stable');
      for param = paramList
         idForParam = idForCy(find(strcmp({trajStatAll2{idForCy, 4}}, param{:})));
         if (~isempty(idForParam))
            trajStat = [{cyN} {'D'} {'-'} {param{:}} ...
               {sum([trajStatAll2{idForParam, 5}])} ...
               {sum([trajStatAll2{idForParam, 6}])} {100*sum([trajStatAll2{idForParam, 6}])/sum([trajStatAll2{idForParam, 5}])} ...
               {sum([trajStatAll2{idForParam, 8}])} {100*sum([trajStatAll2{idForParam, 8}])/sum([trajStatAll2{idForParam, 5}])} ...
               {sum([trajStatAll2{idForParam, 10}])} {100*sum([trajStatAll2{idForParam, 10}])/sum([trajStatAll2{idForParam, 8}])} ...
               {sum([trajStatAll2{idForParam, 12}])} {100*sum([trajStatAll2{idForParam, 12}])/sum([trajStatAll2{idForParam, 8}])} ...
               {sum([trajStatAll2{idForParam, 14}])} {100*sum([trajStatAll2{idForParam, 14}])/sum([trajStatAll2{idForParam, 8}])}];

            fprintf(fId, '2;%d;%d;%c;%c;%s;%d;%d;%.1f;%d;%.1f;%d;%.1f;%d;%.1f;%d;%.1f\n', ...
               floatNum, trajStat{:});
         end
      end
   end

   NB_LINE = 4;
   trajStatAll4 = repmat(cell(1, NB_COL), NB_LINE, 1);
   cptLine = 1;

   idD = find([trajStatAll{:, 2}] == 'D');
   trajStatAll2 = trajStatAll(idD, :);
   paramList = unique({trajStatAll2{:, 4}}, 'stable');
   for param = paramList
      idForParam = find(strcmp({trajStatAll2{:, 4}}, param{:}));
      if (~isempty(idForParam))
         trajStat = [{'-'} {'D'} {'-'} {param{:}} ...
            {sum([trajStatAll2{idForParam, 5}])} ...
            {sum([trajStatAll2{idForParam, 6}])} {100*sum([trajStatAll2{idForParam, 6}])/sum([trajStatAll2{idForParam, 5}])} ...
            {sum([trajStatAll2{idForParam, 8}])} {100*sum([trajStatAll2{idForParam, 8}])/sum([trajStatAll2{idForParam, 5}])} ...
            {sum([trajStatAll2{idForParam, 10}])} {100*sum([trajStatAll2{idForParam, 10}])/sum([trajStatAll2{idForParam, 8}])} ...
            {sum([trajStatAll2{idForParam, 12}])} {100*sum([trajStatAll2{idForParam, 12}])/sum([trajStatAll2{idForParam, 8}])} ...
            {sum([trajStatAll2{idForParam, 14}])} {100*sum([trajStatAll2{idForParam, 14}])/sum([trajStatAll2{idForParam, 8}])} ];
         trajStatAll4(cptLine, :) = trajStat;
         cptLine = cptLine + 1;
         if (cptLine > size(trajStatAll4, 1))
            trajStatAll4 = cat(1, trajStatAll4, repmat(cell(1, NB_COL), NB_LINE, 1));
         end
      end
   end
   trajStatAll4(cptLine:end, :) = [];

   for idL = 1:size(trajStatAll4, 1)
      fprintf(fId, '3;%d;%c;%c;%c;%s;%d;%d;%.1f;%d;%.1f;%d;%.1f;%d;%.1f;%d;%.1f\n', ...
         floatNum, trajStatAll4{idL, 1:NB_COL});
   end

   if (cptLine5 + size(trajStatAll4, 1) - 1 > size(trajStatAll5, 1))
      trajStatAll5 = cat(1, trajStatAll5, repmat(cell(1, NB_COL), NB_LINE, 1));
   end
   trajStatAll5(cptLine5:cptLine5+size(trajStatAll4, 1)-1, :) = trajStatAll4;
   cptLine5 = cptLine5 + size(trajStatAll4, 1);

end
trajStatAll5(cptLine5:end, :) = [];

paramList = unique({trajStatAll5{:, 4}}, 'stable');
for param = paramList
   idForParam = find(strcmp({trajStatAll5{:, 4}}, param{:}));
   if (~isempty(idForParam))
      trajStat = [{'-'} {'D'} {'-'} {param{:}} ...
         {sum([trajStatAll5{idForParam, 5}])} ...
         {sum([trajStatAll5{idForParam, 6}])} {100*sum([trajStatAll5{idForParam, 6}])/sum([trajStatAll5{idForParam, 5}])} ...
         {sum([trajStatAll5{idForParam, 8}])} {100*sum([trajStatAll5{idForParam, 8}])/sum([trajStatAll5{idForParam, 5}])} ...
         {sum([trajStatAll5{idForParam, 10}])} {100*sum([trajStatAll5{idForParam, 10}])/sum([trajStatAll5{idForParam, 8}])} ...
         {sum([trajStatAll5{idForParam, 12}])} {100*sum([trajStatAll5{idForParam, 12}])/sum([trajStatAll5{idForParam, 8}])} ...
         {sum([trajStatAll5{idForParam, 14}])} {100*sum([trajStatAll5{idForParam, 14}])/sum([trajStatAll5{idForParam, 8}])} ];

      fprintf(fId, '4;-;%c;%c;%c;%s;%d;%d;%.1f;%d;%.1f;%d;%.1f;%d;%.1f;%d;%.1f\n', ...
         trajStat{:});
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fclose(fId);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
