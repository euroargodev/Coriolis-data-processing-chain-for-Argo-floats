% ------------------------------------------------------------------------------
% Retrieve all CONF and TECH parameter names from Apex Iridium SBD msg file for
% a given float.
%
% SYNTAX :
%   extract_conf_tech_apx_ir_sbd or extract_conf_tech_apx_ir_sbd(6900189, 7900118)
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
%   11/03/2017 - RNU - creation
% ------------------------------------------------------------------------------
function extract_conf_tech_apx_ir_sbd(varargin)

% directory of rudics files
DIR_INPUT_IR_FILES = 'C:\Users\jprannou\_DATA\IN\APEX_IR\APEX_IR_SBD\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% directory to store the output csv files
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values initialization
init_default_values;


% configuration parameters
configVar = [];
configVar{end+1} = 'FLOAT_LIST_FILE_NAME';
configVar{end+1} = 'FLOAT_INFORMATION_FILE_NAME';

% get configuration parameters
g_decArgo_realtimeFlag = 0;
g_decArgo_delayedModeFlag = 0;
[configVal, unusedVarargin, inputError] = get_config_dec_argo(configVar, []);
floatListFileName = configVal{1};
floatInformationFileName = configVal{2};

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
logFile = [DIR_LOG_FILE '/' 'extract_conf_tech_apx_ir_sbd' name '_' timeInfo '.log'];
diary(logFile);
tic;

% get floats information
[listWmoNum, listDecId, listRudicsId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

% process the floats
configVersionList = [];
configNameList = [];
configUnitList = [];
configValueList = [];
engVersionList0 = {-1};
engNameList0 = {[]};
engValueList0 = {[]};
engVersionList = {-1};
engNameList = {[]};
engValueList = {[]};
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);
      
   % find float SN and decoder Id
   idF = find(listWmoNum == floatNum, 1);
   if (isempty(idF))
      fprintf('ERROR: No information on float #%d => nothing done for this float\n', floatNum);
      continue
   end
   floatDecId = listDecId(idF);
   floatRudicsId = str2num(listRudicsId{idF});

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
            ] = read_apx_ir_sbd_msg_file(filePathName, [], 0);
         if (error == 1)
            fprintf('ERROR: Error in file: %s => ignored\n', filePathName);
            continue
         end
         
         if (~isempty(configDataStr))
            configData = parse_apx_ir_rudics_config_data(configDataStr);
            fieldNames = fieldnames(configData);
            configName = fieldNames(1:2:end);
            values = struct2cell(configData);
            configUnit = values(2:2:end);
            configValue = values(1:2:end);
            
            if (isempty(configVersionList))
               configVersionList{end+1} = floatDecId;
               configNameList{end+1} = configName;
               configUnitList{end+1} = configUnit;
               configValueList{end+1} = configValue;
            else
               idF = find([configVersionList{:}] == floatDecId);
               if (isempty(idF))
                  configVersionList{end+1} = floatDecId;
                  configNameList{end+1} = configName;
                  configUnitList{end+1} = configUnit;
                  configValueList{end+1} = configValue;
               else
                  if ((length(configNameList{idF}) ~= length(configName)) || ...
                        any(~strcmp(configNameList{idF}, configName)) || ...
                        any(~strcmp(configUnitList{idF}, configUnit)))
                     if (length(configNameList{idF}) > length(configName))
                        fprintf('ERROR: Float #%d Cycle #%d: Inconsistent configuration (%d items instead of %d) => ignored\n', ...
                           floatNum, cyNum, length(configName), length(configNameList{idF}));
                     elseif (length(configNameList{idF}) < length(configName))                      
                        fprintf('ERROR: Float #%d Cycle #%d: Inconsistent configuration (%d items instead of %d) => new configuration stored, previous one ignored\n', ...
                           floatNum, cyNum, length(configName), length(configNameList{idF}));
                        configNameList{idF} = configName;
                        configUnitList{idF} = configUnit;
                        configValueList{idF} = configValue;
                     else
                        fprintf('ERROR: Float #%d Cycle #%d: Inconsistent configuration (items differ) => ignored\n', floatNum, cyNum);
                     end
                  end
               end
            end
         end
         
         if (~isempty(engineeringDataStr))
            engData = parse_apx_ir_engineering_data(engineeringDataStr);
            
            for idEng = 1:length(engData)
               
               engName = fieldnames(engData{idEng});
               if (cyNum == 0)
%                   if (isempty(engVersionList0))
%                      engVersionList0{end+1} = floatDecId;
%                      engNameList0{end+1} = engName;
%                   else
                     idF = find([engVersionList0{:}] == floatDecId);
                     if (isempty(idF))
                        engVersionList0{end+1} = floatDecId;
                        engNameList0{end+1} = engName;
                     else
                        if ((length(engNameList0{idF}) ~= length(engName)) || ...
                              any(~strcmp(engNameList0{idF}, engName)))
                           if (length(engNameList0{idF}) > length(engName))
                              fprintf('ERROR: Float #%d Cycle #%d: Inconsistent engineering (%d items instead of %d) => ignored\n', ...
                                 floatNum, cyNum, length(engName), length(engNameList0{idF}));
                           elseif (length(engNameList0{idF}) < length(engName))
                              fprintf('ERROR: Float #%d Cycle #%d: Inconsistent engineering (%d items instead of %d) => new engeneering stored, previous one ignored\n', ...
                                 floatNum, cyNum, length(engName), length(engNameList0{idF}));
                              engNameList0{idF} = engName;
                           else
                              fprintf('ERROR: Float #%d Cycle #%d: Inconsistent engineering (items differ) => ignored\n', floatNum, cyNum);
                           end
                        end
                     end
%                   end
               else
%                   if (isempty(engVersionList))
%                      engVersionList{end+1} = floatDecId;
%                      engNameList{end+1} = engName;
%                   else
                     idF = find([engVersionList{:}] == floatDecId);
                     if (isempty(idF))
                        engVersionList{end+1} = floatDecId;
                        engNameList{end+1} = engName;
                     else
                        if ((length(engNameList{idF}) ~= length(engName)) || ...
                              any(~strcmp(engNameList{idF}, engName)))
                           if (length(engNameList{idF}) > length(engName))
                              fprintf('ERROR: Float #%d Cycle #%d: Inconsistent engineering (%d items instead of %d) => ignored\n', ...
                                 floatNum, cyNum, length(engName), length(engNameList{idF}));
                           elseif (length(engNameList{idF}) < length(engName))
                              fprintf('ERROR: Float #%d Cycle #%d: Inconsistent engineering (%d items instead of %d) => new engeneering stored, previous one ignored\n', ...
                                 floatNum, cyNum, length(engName), length(engNameList{idF}));
                              engNameList{idF} = engName;
                           else
                              fprintf('ERROR: Float #%d Cycle #%d: Inconsistent engineering (items differ) => ignored\n', floatNum, cyNum);
                           end
                        end
                     end
%                   end
               end
            end
         end
      end
   end
end

% print configuration names in output CSV files
for idVer = 1:length(configVersionList)

   % create the CSV output file
   outputFileName = [DIR_CSV_FILE '/' 'extract_conf_tech_apx_ir_sbd_CONF_' num2str(configVersionList{idVer}) name '_' timeInfo '.csv'];
   fidOut = fopen(outputFileName, 'wt');
   if (fidOut == -1)
      return
   end
   header = 'CONFIG_LABEL;CONFIG_LABEL_UNIT';
   fprintf(fidOut, '%s\n', header);
   
   configName = configNameList{idVer};
   configUnit = configUnitList{idVer};
   for idConf = 1:length(configName)
      fprintf(fidOut, '%s;%s\n', configName{idConf}, configUnit{idConf});
   end
   
   fclose(fidOut);
end

% print engineering names in output CSV files
versionList = unique([engVersionList0{:} engVersionList{:}]);
for idVer = 1:length(versionList)

   if (versionList(idVer) == -1)
      continue
   end
      
   % create the CSV output file
   outputFileName = [DIR_CSV_FILE '/' 'extract_conf_tech_apx_ir_sbd_ENG_' num2str(versionList(idVer)) name '_' timeInfo '.csv'];
   fidOut = fopen(outputFileName, 'wt');
   if (fidOut == -1)
      return
   end
   header = 'ENG_LABEL_0;ENG_LABEL';
   fprintf(fidOut, '%s\n', header);
   
   idF1 = find([engVersionList0{:}] == versionList(idVer));
   idF2 = find([engVersionList{:}] == versionList(idVer));
   if (~isempty(idF1) && ~isempty(idF2))
      engName0 = engNameList0{idF1};
      engName = engNameList{idF2};
      for idEng = 1:max(length(engName0), length(engName))
         if ((idEng <= length(engName0)) && (idEng <= length(engName)))
            fprintf(fidOut, '%s;%s\n', engName0{idEng}, engName{idEng});
         elseif (idEng <= length(engName0))
            fprintf(fidOut, '%s;\n', engName0{idEng});
         else
            fprintf(fidOut, ';%s\n', engName{idEng});
         end
      end
   elseif (~isempty(idF1))
      engName0 = engNameList0{idF1};
      for idEng = 1:length(engName0)
         fprintf(fidOut, '%s;\n', engName0{idEng});
      end
   else
      engName = engNameList{idF2};
      for idEng = 1:length(engName)
         fprintf(fidOut, ';%s\n', engName{idEng});
      end
   end
   
   fclose(fidOut);
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
