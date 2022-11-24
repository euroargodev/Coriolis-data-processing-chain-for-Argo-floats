% ------------------------------------------------------------------------------
% Convert NetCDF trajectory file contents in CSV format.
%
% SYNTAX :
%   nc_traj_adj_2_csv or nc_traj_adj_2_csv(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : WMO number of floats to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function nc_traj_adj_2_csv(varargin)

% top directory of the NetCDF files to convert
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decApx\';

% default list of floats to convert
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_071412.txt';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% measurement codes initialization
init_measurement_codes;

% default values initialization
init_default_values;


if (nargin == 0)
   floatListFileName = FLOAT_LIST_FILE_NAME;
   
   % floats to process come from floatListFileName
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', floatListFileName);
      return;
   end
   
   fprintf('Floats from list: %s\n', floatListFileName);
   floatList = load(floatListFileName);
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create and start log file recording
if (nargin == 0)
   [pathstr, name, ext] = fileparts(floatListFileName);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

logFile = [DIR_LOG_FILE '/' 'nc_traj_adj_2_csv' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   ncFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/'];
   
   if (exist(ncFileDir, 'dir') == 7)
      
      % convert trajectory file
      ncFiles = dir([ncFileDir sprintf('%d_*traj.nc', floatNum)]);
      %       ncFiles = dir([ncFileDir sprintf('%d_Rtraj.nc', floatNum)]);
      for idFile = 1:length(ncFiles)
         
         ncFileName = ncFiles(idFile).name;
         ncFilePathName = [ncFileDir '/' ncFileName];
         
         outputFileName = [ncFileName(1:end-3) '.csv'];
         outputFilePathName = [ncFileDir outputFileName];
         nc_traj_adj_2_csv_file(ncFilePathName, outputFilePathName);
      end
      
   else
      fprintf('WARNING: Directory not found: %s\n', ncFileDir);
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;

% ------------------------------------------------------------------------------
% Convert one NetCDF trajectory file contents in CSV format.
%
% SYNTAX :
%  nc_traj_adj_2_csv_file(a_inputPathFileName, a_outputPathFileName)
%
% INPUT PARAMETERS :
%   a_inputPathFileName  : input NetCDF file path name
%   a_outputPathFileName : output CSV file path name
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function nc_traj_adj_2_csv_file(a_inputPathFileName, a_outputPathFileName)

% input and output file names
[inputPath, inputName, inputExt] = fileparts(a_inputPathFileName);
[outputPath, outputName, outputExt] = fileparts(a_outputPathFileName);
inputFileName = [inputName inputExt];
ourputFileName = [outputName outputExt];
fprintf('Converting: %s to %s\n', inputFileName, ourputFileName);

% read the trajectory file contents
[nMeasData nCycleData] = read_file_traj_3_1(a_inputPathFileName, 1);

% create CSV file
fidOut = fopen(a_outputPathFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create output file: %s\n', a_outputPathFileName);
   return;
end

% compute parameter variable names and output formats

% if (length(nMeasData.paramNameList) <= 3)
%
%    paramNames = [];
%    adjParamNames = [];
%
%    for idParam = 1:length(nMeasData.paramNameList)
%       paramName  = char(nMeasData.paramNameList(idParam));
%       paramQcName  = char(nMeasData.paramQcNameList(idParam));
%
%       paramNames = [paramNames sprintf('; %s', paramName)];
%       paramNames = [paramNames sprintf('; %s', paramQcName)];
%    end
%
%    for idParam = 1:length(nMeasData.adjParamNameList)
%       adjParamName  = char(nMeasData.adjParamNameList(idParam));
%       adjParamQcName  = char(nMeasData.adjParamQcNameList(idParam));
%
%       adjParamNames = [adjParamNames sprintf('; %s', adjParamName)];
%       adjParamNames = [adjParamNames sprintf('; %s', adjParamQcName)];
%    end
%
% else

paramNames = [];
paramFormats = [];
paramQcNames = [];
paramQcFormats = [];

for idParam = 1:length(nMeasData.paramNameList)
   paramName  = char(nMeasData.paramNameList(idParam));
   paramDataNbDim = nMeasData.paramDataNbDim(idParam);
   paramQcName  = char(nMeasData.paramQcNameList(idParam));
   
   if (paramDataNbDim == 1)
      paramNames = [paramNames sprintf('; %s', paramName)];
      paramQcNames = [paramQcNames sprintf('; %s', paramQcName)];
      
      paramFormat = char(nMeasData.paramDataFormat(idParam));
      paramFormats = [paramFormats '; ' paramFormat];
      paramQcFormats = [paramQcFormats '; %c'];
   else
      for id = 1:paramDataNbDim
         paramNames = [paramNames sprintf('; %s#%d', paramName, id)];
         paramQcNames = [paramQcNames sprintf('; %s#%d', paramQcName, id)];
         
         paramFormat = char(nMeasData.paramDataFormat(idParam));
         paramFormats = [paramFormats '; ' paramFormat];
         paramQcFormats = [paramQcFormats '; %c'];
      end
   end
end

adjParamNames = [];
adjParamFormats = [];
adjParamQcNames = [];
adjParamQcFormats = [];

for idParam = 1:length(nMeasData.adjParamNameList)
   adjParamName  = char(nMeasData.adjParamNameList(idParam));
   adjParamDataNbDim = nMeasData.adjParamDataNbDim(idParam);
   adjParamQcName  = char(nMeasData.adjParamQcNameList(idParam));
   
   if (adjParamDataNbDim == 1)
      adjParamNames = [adjParamNames sprintf('; %s', adjParamName)];
      adjParamQcNames = [adjParamQcNames sprintf('; %s', adjParamQcName)];
      
      adjParamFormat = char(nMeasData.adjParamDataFormat(idParam));
      adjParamFormats = [adjParamFormats '; ' adjParamFormat];
      adjParamQcFormats = [adjParamQcFormats '; %c'];
   else
      for id = 1:adjParamDataNbDim
         adjParamNames = [adjParamNames sprintf('; %s#%d', adjParamName, id)];
         adjParamQcNames = [adjParamQcNames sprintf('; %s#%d', adjParamQcName, id)];
         
         adjParamFormat = char(nMeasData.adjParamDataFormat(idParam));
         adjParamFormats = [adjParamFormats '; ' adjParamFormat];
         adjParamQcFormats = [adjParamQcFormats '; %c'];
      end
   end
end
% end

paramNames = [paramNames repmat(';', 1, length(nMeasData.paramNameList)+1)];
fprintf(fidOut, 'WMO;Type;Cy#;N_CYCLE var or Meas. code;JULD;;;JULD_ADJ;;;Lon;Lat;;; %s\n', [paramNames adjParamNames]);

if (~isempty(nCycleData))
   cycles = unique([nCycleData.cycleNumberIndex; nMeasData.cycleNumber]);
else
   cycles = unique([nMeasData.cycleNumber]);
   cycles(find(cycles == 99999)) = [];
end
for cycleNumber = -1:max(cycles)
   
   if (~isempty(nCycleData))
      
      % print N_CYCLE data
      idCy = find(nCycleData.cycleNumberIndex == cycleNumber);
      
      if (~isempty(idCy))
         if (isfield(nCycleData, 'juldDescentStart'))
            fprintf(fidOut, '%s; CYCLE; %d; JULD_DESCENT_START; %s; %c\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               julian_2_gregorian_dec_argo(nCycleData.juldDescentStart(idCy)), ...
               nCycleData.juldDescentStartStatus(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; JULD_FIRST_STABILIZATION; %s; %c\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               julian_2_gregorian_dec_argo(nCycleData.juldFirstStab(idCy)), ...
               nCycleData.juldFirstStabStatus(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; JULD_DESCENT_END; %s; %c\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               julian_2_gregorian_dec_argo(nCycleData.juldDescentEnd(idCy)), ...
               nCycleData.juldDescentEndStatus(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; JULD_PARK_START; %s; %c\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               julian_2_gregorian_dec_argo(nCycleData.juldParkStart(idCy)), ...
               nCycleData.juldParkStartStatus(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; JULD_PARK_END; %s; %c\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               julian_2_gregorian_dec_argo(nCycleData.juldParkEnd(idCy)), ...
               nCycleData.juldParkEndStatus(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; JULD_DEEP_DESCENT_END; %s; %c\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               julian_2_gregorian_dec_argo(nCycleData.juldDeepDescentEnd(idCy)), ...
               nCycleData.juldDeepDescentEndStatus(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; JULD_DEEP_PARK_START; %s; %c\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               julian_2_gregorian_dec_argo(nCycleData.juldDeepParkStart(idCy)), ...
               nCycleData.juldDeepParkStartStatus(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; JULD_ASCENT_START; %s; %c\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               julian_2_gregorian_dec_argo(nCycleData.juldAscentStart(idCy)), ...
               nCycleData.juldAscentStartStatus(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; JULD_ASCENT_END; %s; %c\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               julian_2_gregorian_dec_argo(nCycleData.juldAscentEnd(idCy)), ...
               nCycleData.juldAscentEndStatus(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; JULD_TRANSMISSION_START; %s; %c\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               julian_2_gregorian_dec_argo(nCycleData.juldTransmissionStart(idCy)), ...
               nCycleData.juldTransmissionStartStatus(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; JULD_FIRST_MESSAGE; %s; %c\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               julian_2_gregorian_dec_argo(nCycleData.juldFirstMessage(idCy)), ...
               nCycleData.juldFirstMessageStatus(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; JULD_FIRST_LOCATION; %s; %c\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               julian_2_gregorian_dec_argo(nCycleData.juldFirstLocation(idCy)), ...
               nCycleData.juldFirstLocationStatus(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; JULD_LAST_LOCATION; %s; %c\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               julian_2_gregorian_dec_argo(nCycleData.juldLastLocation(idCy)), ...
               nCycleData.juldLastLocationStatus(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; JULD_LAST_MESSAGE; %s; %c\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               julian_2_gregorian_dec_argo(nCycleData.juldLastMessage(idCy)), ...
               nCycleData.juldLastMessageStatus(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; JULD_TRANSMISSION_END; %s; %c\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               julian_2_gregorian_dec_argo(nCycleData.juldTransmissionEnd(idCy)), ...
               nCycleData.juldTransmissionEndStatus(idCy));
            if (nCycleData.juldClockOffset(idCy) ~= 999999)
               fprintf(fidOut, '%s; CYCLE; %d; CLOCK_OFFSET; %s\n', ...
                  nMeasData.platformNumber, cycleNumber, ...
                  format_time_dec_argo(nCycleData.juldClockOffset(idCy)*24));
            else
               fprintf(fidOut, '%s; CYCLE; %d; CLOCK_OFFSET; %d\n', ...
                  nMeasData.platformNumber, cycleNumber, ...
                  nCycleData.juldClockOffset(idCy));
            end
            fprintf(fidOut, '%s; CYCLE; %d; GROUNDED; %c\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               nCycleData.grounded(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; REPRESENTATIVE_PARK_PRESSURE; %.1f; %c\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               nCycleData.representativeParkPressure(idCy), ...
               nCycleData.representativeParkPressureStatus(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; CONFIG_MISSION_NUMBER; %d\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               nCycleData.configMissionNumber(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; CYCLE_NUMBER_INDEX; %d\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               nCycleData.cycleNumberIndex(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; CYCLE_NUMBER_INDEX_ADJUSTED; %d\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               nCycleData.cycleNumberIndexAdj(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; DATA_MODE; %c\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               nCycleData.dataMode(idCy));
         else
            fprintf(fidOut, '%s; CYCLE; %d; CONFIG_MISSION_NUMBER; %d\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               nCycleData.configMissionNumber(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; CYCLE_NUMBER_INDEX; %d\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               nCycleData.cycleNumberIndex(idCy));
            fprintf(fidOut, '%s; CYCLE; %d; DATA_MODE; %c\n', ...
               nMeasData.platformNumber, cycleNumber, ...
               nCycleData.dataMode(idCy));
         end
      end
   end
   
   % print N_MEASUREMENT data
   idMeas = find(nMeasData.cycleNumber == cycleNumber);
   
   for idM = 1:length(idMeas)
      
      if (nMeasData.measCode(idMeas(idM)) == 99999)
         continue;
      end
      
      if (~isempty(nMeasData.paramData))
         
         paramData = nMeasData.paramData(idMeas(idM), :);
         paramQcData = nMeasData.paramQcData(idMeas(idM), :);
         paramQcData(find(paramQcData == -1)) = 7;
         paramQcData = num2str(paramQcData')';
         paramQcData(find(paramQcData == '7')) = ' ';
         
         paramDataAdj = nMeasData.adjParamData(idMeas(idM), :);
         paramQcDataAdj = nMeasData.adjParamQcData(idMeas(idM), :);
         paramQcDataAdj(find(paramQcDataAdj == -1)) = 7;
         paramQcDataAdj = num2str(paramQcDataAdj')';
         paramQcDataAdj(find(paramQcDataAdj == '7')) = ' ';
         
         if (isempty(nMeasData.juldAdj))
            fprintf(fidOut, ['%s; MEAS #%04d; %3d; %s; %s; %c; %c; ; ; ; %8.3f; %7.3f; %c; %c; %s' paramFormats paramQcFormats ';' adjParamFormats adjParamQcFormats '\n'], ...
               nMeasData.platformNumber, ...
               idMeas(idM), ...
               nMeasData.cycleNumber(idMeas(idM)), ...
               get_meas_code_name(nMeasData.measCode(idMeas(idM))), ...
               julian_2_gregorian_dec_argo(nMeasData.juld(idMeas(idM))), ...
               nMeasData.juldStatus(idMeas(idM)), ...
               nMeasData.juldQc(idMeas(idM)), ...
               nMeasData.longitude(idMeas(idM)), ...
               nMeasData.latitude(idMeas(idM)), ...
               nMeasData.positionAccuracy(idMeas(idM)), ...
               nMeasData.positionQc(idMeas(idM)), ...
               deblank(nMeasData.positionSat(idMeas(idM))), ...
               paramData, paramQcData, ...
               paramDataAdj, paramQcDataAdj);
         else
            fprintf(fidOut, ['%s; MEAS #%04d; %3d; %s; %s; %c; %c; %s; %c; %c; %8.3f; %7.3f; %c; %c; %s' paramFormats paramQcFormats ';' adjParamFormats adjParamQcFormats '\n'], ...
               nMeasData.platformNumber, ...
               idMeas(idM), ...
               nMeasData.cycleNumber(idMeas(idM)), ...
               get_meas_code_name(nMeasData.measCode(idMeas(idM))), ...
               julian_2_gregorian_dec_argo(nMeasData.juld(idMeas(idM))), ...
               nMeasData.juldStatus(idMeas(idM)), ...
               nMeasData.juldQc(idMeas(idM)), ...
               julian_2_gregorian_dec_argo(nMeasData.juldAdj(idMeas(idM))), ...
               nMeasData.juldAdjStatus(idMeas(idM)), ...
               nMeasData.juldAdjQc(idMeas(idM)), ...
               nMeasData.longitude(idMeas(idM)), ...
               nMeasData.latitude(idMeas(idM)), ...
               nMeasData.positionAccuracy(idMeas(idM)), ...
               nMeasData.positionQc(idMeas(idM)), ...
               deblank(nMeasData.positionSat(idMeas(idM))), ...
               paramData, paramQcData, ...
               paramDataAdj, paramQcDataAdj);
         end
      else
         if (isempty(nMeasData.juldAdj))
            fprintf(fidOut, ['%s; MEAS #%04d; %3d; %s; %s; %c; %c; ; ; ; %8.3f; %7.3f; %c; %c; %s\n'], ...
               nMeasData.platformNumber, ...
               idMeas(idM), ...
               nMeasData.cycleNumber(idMeas(idM)), ...
               get_meas_code_name(nMeasData.measCode(idMeas(idM))), ...
               julian_2_gregorian_dec_argo(nMeasData.juld(idMeas(idM))), ...
               nMeasData.juldStatus(idMeas(idM)), ...
               nMeasData.juldQc(idMeas(idM)), ...
               nMeasData.longitude(idMeas(idM)), ...
               nMeasData.latitude(idMeas(idM)), ...
               nMeasData.positionAccuracy(idMeas(idM)), ...
               nMeasData.positionQc(idMeas(idM)), ...
               deblank(nMeasData.positionSat(idMeas(idM))));
         else
            fprintf(fidOut, ['%s; MEAS #%04d; %3d; %s; %s; %c; %c; %s; %c; %c; %8.3f; %7.3f; %c; %c; %s\n'], ...
               nMeasData.platformNumber, ...
               idMeas(idM), ...
               nMeasData.cycleNumber(idMeas(idM)), ...
               get_meas_code_name(nMeasData.measCode(idMeas(idM))), ...
               julian_2_gregorian_dec_argo(nMeasData.juld(idMeas(idM))), ...
               nMeasData.juldStatus(idMeas(idM)), ...
               nMeasData.juldQc(idMeas(idM)), ...
               julian_2_gregorian_dec_argo(nMeasData.juldAdj(idMeas(idM))), ...
               nMeasData.juldAdjStatus(idMeas(idM)), ...
               nMeasData.juldAdjQc(idMeas(idM)), ...
               nMeasData.longitude(idMeas(idM)), ...
               nMeasData.latitude(idMeas(idM)), ...
               nMeasData.positionAccuracy(idMeas(idM)), ...
               nMeasData.positionQc(idMeas(idM)), ...
               deblank(nMeasData.positionSat(idMeas(idM))));
         end
      end
   end
   
   if (~isempty(idMeas))
      fprintf(fidOut, '%s\n', ...
         nMeasData.platformNumber);
   end
end

fclose(fidOut);

return;


