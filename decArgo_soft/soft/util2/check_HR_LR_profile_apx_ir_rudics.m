% ------------------------------------------------------------------------------
% Retrieve information to compare HR and LR profile ranges of Apex Iridium
% floats.
%
% SYNTAX :
%   check_HR_LR_profile_apx_ir_rudics or check_HR_LR_profile_apx_ir_rudics(6900189, 7900118)
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
%   11/08/2017 - RNU - creation
% ------------------------------------------------------------------------------
function check_HR_LR_profile_apx_ir_rudics(varargin)

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% directory to store the output csv files
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values initialization
init_default_values;


% configuration parameters
configVar = [];
configVar{end+1} = 'FLOAT_LIST_FILE_NAME';
configVar{end+1} = 'FLOAT_INFORMATION_FILE_NAME';
configVar{end+1} = 'DIR_INPUT_RSYNC_DATA';

% get configuration parameters
g_decArgo_realtimeFlag = 0;
g_decArgo_delayedModeFlag = 0;
[configVal, unusedVarargin, inputError] = get_config_dec_argo(configVar, []);
floatListFileName = configVal{1};
floatInformationFileName = configVal{2};
DIR_INPUT_IR_FILES = configVal{3};

if (nargin == 0)
   
   % floats to process come from floatListFileName
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', floatListFileName);
      return
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

timeInfo = datestr(now, 'yyyymmddTHHMMSS');
logFile = [DIR_LOG_FILE '/' 'check_HR_LR_profile_apx_ir_rudics' name '_' timeInfo '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_CSV_FILE '/' 'check_HR_LR_profile_apx_ir_rudics' name '_' timeInfo '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end

header = 'WMO;DECODER_ID;CYCLE_NUM;DEEP_PROFLE_PRES;CP_ACTIVATION_PRES;DEEP_PROFLE_PRES-CP_ACTIVATION_PRES;LR_NB_LEV;LR_P_MIN;LR_P_MAX;LR_P_RANGE;HR_NB_LEV;HR_P_MIN;HR_P_MAX;HR_P_RANGE;LR-HR_P_RANGE';
fprintf(fidOut, '%s\n', header);

% get floats information
[listWmoNum, listDecId, listRudicsId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   g_decArgo_floatNum = floatNum;
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);
   
   % find float SN and decoder Id
   idF = find(listWmoNum == floatNum, 1);
   if (isempty(idF))
      fprintf('ERROR: No information on float #%d - nothing done for this float\n', floatNum);
      continue
   end
   floatDecId = listDecId(idF);
   floatRudicsId = str2num(listRudicsId{idF});

   fprintf(fidOut, '%d;%d', floatNum, floatDecId);

   dirPathFileName = [DIR_INPUT_IR_FILES '/' sprintf('%04d', floatRudicsId)];
   fileNames = dir([dirPathFileName '/' '*' num2str(floatNum) '*.msg']);
   cycleList = [];
   for idFile = 1:length(fileNames)
      fileName = fileNames(idFile).name;
      idF1 = strfind(fileName, num2str(floatNum));
      idF2 = strfind(fileName, '_');
      idF3 = find(idF2 > idF1);
      cyNum = fileName(idF2(idF3(1))+1:idF2(idF3(2))-1);
      [cyNum, status] = str2num(cyNum);
      if (status)
         cycleList = [cycleList cyNum];
      end
   end
   cycleList = unique(cycleList);
   
   for cyNum = cycleList
      %       if (cyNum == 27)
      %          a=1
      %       end
      g_decArgo_cycleNum = cyNum;
      
      fileNames = dir([dirPathFileName '/' '*' num2str(floatNum) sprintf('_%03d_', cyNum) '*.msg']);
      for idFile = 1:length(fileNames)
         fileName = fileNames(idFile).name;
         
         filePathName = [dirPathFileName '/' fileName];
         
         [error, ...
            configDataStr, ...
            driftMeasDataStr, ...
            profInfoDataStr, ...
            profLowResMeasDataStr, ...
            profHighResMeasDataStr, ...
            gpsFixDataStr, ...
            engineeringDataStr, ...
            nearSurfaceDataStr ...
            ] = read_apx_ir_rudics_msg_file(filePathName);
         if (error == 1)
            fprintf('ERROR: Error in file: %s - ignored\n', filePathName);
            continue
         end
         
         if (~isempty(configDataStr))
            fprintf(fidOut, '%d;%d;%d;', floatNum, floatDecId, cyNum);
            configData = parse_apx_ir_rudics_config_data(configDataStr);
            fieldNames = fieldnames(configData);
            values = struct2cell(configData);
            idDPP = find(strcmp(fieldNames, 'DeepProfilePressure') == 1);
            deepProfilePres = str2num(values{idDPP});
            idCPA = find(strcmp(fieldNames, 'CpActivationP') == 1);
            cpActivationPres = str2num(values{idCPA});
            fprintf(fidOut, '%d;%d;%d;', deepProfilePres, cpActivationPres, deepProfilePres-cpActivationPres);
         end
         
         lrPres = [];
         if (~isempty(profLowResMeasDataStr))
            [parkData, profLrData, expectedProfLrNbSamples] = parse_apx_ir_rudics_LR_profile_data(profLowResMeasDataStr, floatDecId);
            if (~isempty(profLrData))
               idPres = find(strcmp({profLrData.paramList.name}, 'PRES') == 1);
               lrPres = profLrData.data(:, idPres);
               fprintf(fidOut, '%d;%g;%g;%d;', length(lrPres), min(lrPres), max(lrPres), fix(ceil(max(lrPres))-floor(min(lrPres))));
            else
               fprintf(fidOut, ';;;;');
            end
         else
            fprintf(fidOut, ';;;;');
         end
         
         hrPres = [];
         if (~isempty(profHighResMeasDataStr))
            [profHrData, profHrInfo] = decode_apx_ir_rudics_HR_profile_data(profHighResMeasDataStr, floatDecId);
            if (~isempty(profHrData))
               idPres = find(strcmp({profHrData.paramList.name}, 'PRES') == 1);
               hrPres = profHrData.data(:, idPres);
               hrPres(find(hrPres == 99999)) = [];
               fprintf(fidOut, '%d;%g;%g;%d;', length(hrPres), min(hrPres), max(hrPres), fix(ceil(max(hrPres))-floor(min(hrPres))));
            end
         end
         
         if (~isempty(lrPres) && ~isempty(hrPres))
            fprintf(fidOut, '%d', fix(ceil(max(hrPres))-floor(min(hrPres)))-fix(ceil(max(lrPres))-floor(min(lrPres))));
         end
         
         fprintf(fidOut, '\n');
      end
   end
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
