% ------------------------------------------------------------------------------
% Decoding of PROVOR CTS5 sensor measurements and processing of derived
% parameters.
%
% SYNTAX :
%   decode_meas_cts5('bshuse001b')
%
% INPUT PARAMETERS :
%   varargin : login name of floats to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/09/2022 - RNU - creation: V1.0 based on '050c' decoder version
% ------------------------------------------------------------------------------
function decode_meas_cts5(varargin)

% input directory of float transmitted files
DIR_INPUT_FILES = 'C:\Users\jprannou\_DATA\ESSAI_BASSIN_CTS5\DATA\IN\';

% directory of output CSV files
DIR_OUTPUT_FILES = 'C:\Users\jprannou\_DATA\ESSAI_BASSIN_CTS5\DATA\CSV\';

% input directory of float META.json files
DIR_META_JSON_FILES = 'C:\Users\jprannou\_DATA\ESSAI_BASSIN_CTS5\DATA\META_JSON\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

FLOAT_DECODER_ID = 128;


% default values initialization
init_default_values;

global g_decArgo_floatTransType;
g_decArgo_floatTransType = 2;

% SBD sub-directories
global g_decArgo_archiveDirectory;

% prefix of data file names
global g_decArgo_filePrefixCts5;

% existing cycle and pattern numbers
global g_decArgo_cyclePatternNumFloat;

% type of files to consider
global g_decArgo_provorCts5UseaFileTypeListAll;
global g_decArgo_fileTypeListCts5;
g_decArgo_fileTypeListCts5 = g_decArgo_provorCts5UseaFileTypeListAll;

% current cycle and pattern number
global g_decArgo_cycleNumFloat;
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloat;
global g_decArgo_patternNumFloatStr;

% current cycle number
global g_decArgo_cycleNum;


if (nargin == 0)
   fprintf('ERROR: Float login name expected => exit\n');
   return
end
floatLoginName = varargin{:};

dateStr = datestr(now, 'yyyymmddTHHMMSS');
logFile = [DIR_LOG_FILE '/' 'decode_meas_cts5_' dateStr '.log'];
diary(logFile);
tic;

% get sensor list and calibration information
jsonFile = [DIR_META_JSON_FILES '/' floatLoginName '_meta.json'];
if ~(exist(jsonFile, 'file') == 2)
   fprintf('ERROR: File not found: %s => exit\n', jsonFile);
   return
end
ok = init_float_config_prv_ir_rudics_cts5_usea(jsonFile, FLOAT_DECODER_ID);
if (~ok)
   return
end

% set data directory
dataDir = [DIR_INPUT_FILES '/' floatLoginName '/'];
if ~(exist(dataDir, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s => exit\n', dataDir);
   return
end
g_decArgo_archiveDirectory = dataDir;

% create temporary directory to store concatenated files
floatTmpDirName = [g_decArgo_archiveDirectory '/tmp/'];
if (exist(floatTmpDirName, 'dir') == 7)
   rmdir(floatTmpDirName, 's');
end
mkdir(floatTmpDirName);

% set file prefix
g_decArgo_filePrefixCts5 = get_file_prefix_cts5(g_decArgo_archiveDirectory);

% find cycle and (cycle,ptn) from available files
% get payload configuration files
[floatCycleList, g_decArgo_cyclePatternNumFloat] = get_cycle_ptn_cts5_usea;

% read and store clock offset information from technical data (in g_decArgo_useaTechData)
read_apmt_technical_data(g_decArgo_cyclePatternNumFloat, g_decArgo_filePrefixCts5, FLOAT_DECODER_ID, 1);

% process available files
tabProfileAll = [];
tabDriftAll = [];
tabSurfAll = [];
for idFlCy = 1:length(floatCycleList)
   floatCyNum = floatCycleList(idFlCy);
   g_decArgo_cycleNum = floatCyNum;

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % get files (without pattern #) to process

   fileToProcess = get_received_file_list_usea(floatCyNum, [], g_decArgo_filePrefixCts5);

   g_decArgo_cycleNumFloat = floatCyNum;
   g_decArgo_cycleNumFloatStr = num2str(floatCyNum);
   g_decArgo_patternNumFloat = [];
   g_decArgo_patternNumFloatStr = '-';

   [tabProfiles, ...
      tabDrift, tabSurf, subSurfaceMeas, trajDataFromApmtTech, ...
      tabNcTechIndex, tabNcTechVal, tabTechNMeas] = ...
      decode_files(fileToProcess, FLOAT_DECODER_ID);

   if (~isempty(tabProfiles))
      tabProfileAll = [tabProfileAll tabProfiles];
   end
   if (~isempty(tabDrift))
      tabDriftAll = [tabDriftAll tabDrift];
   end
   if (~isempty(tabSurf))
      tabSurfAll = [tabSurfAll tabSurf];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % get files (with pattern #) to process
   idF = find(g_decArgo_cyclePatternNumFloat(:, 1) == floatCyNum);
   for idFlCyPtn = 1:length(idF)
      floatPtnNum = g_decArgo_cyclePatternNumFloat(idF(idFlCyPtn), 2);

      % get files to process
      fileToProcess = get_received_file_list_usea(floatCyNum, floatPtnNum, g_decArgo_filePrefixCts5);

      g_decArgo_patternNumFloat = floatPtnNum;
      g_decArgo_patternNumFloatStr = num2str(floatPtnNum);

      [tabProfiles, ...
         tabDrift, tabSurf, subSurfaceMeas, trajDataFromApmtTech, ...
         tabNcTechIndex, tabNcTechVal, tabTechNMeas] = ...
         decode_files(fileToProcess, FLOAT_DECODER_ID);

      if (~isempty(tabProfiles))
         tabProfileAll = [tabProfileAll tabProfiles];
      end
      if (~isempty(tabDrift))
         tabDriftAll = [tabDriftAll tabDrift];
      end
      if (~isempty(tabSurf))
         tabSurfAll = [tabSurfAll tabSurf];
      end
   end
end

% print decoded data in output CSV file
print_data_meas_in_csv_file(tabProfileAll, tabDriftAll, tabSurfAll, DIR_OUTPUT_FILES, floatLoginName, dateStr);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Decode a set of PROVOR CTS5-USEA files.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabDrift, o_tabSurf, o_subSurfaceMeas, o_trajDataFromApmtTech, ...
%    o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
%    decode_files(a_fileNameList, a_decoderId)
%
% INPUT PARAMETERS :
%   a_fileNameList  : list of files to decode
%   a_decoderId     : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabProfiles          : decoded profiles
%   o_tabDrift             : decoded drift measurement data
%   o_tabSurf              : decoded surface measurement data
%   o_subSurfaceMeas       : decoded unique sub surface measurement
%   o_trajDataFromApmtTech : decoded TRAJ relevent technical data
%   o_tabNcTechIndex       : decoded technical index information
%   o_tabNcTechVal         : decoded technical data
%   o_tabTechNMeas         : decoded technical N_MEASUREMENT data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabDrift, o_tabSurf, o_subSurfaceMeas, o_trajDataFromApmtTech, ...
   o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
   decode_files(a_fileNameList, a_decoderId)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];
o_tabSurf = [];
o_subSurfaceMeas = [];
o_trajDataFromApmtTech = [];
o_tabNcTechIndex = [];
o_tabNcTechVal = [];
o_tabTechNMeas = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% SBD sub-directories
global g_decArgo_archiveDirectory;

% generate nc flag
global g_decArgo_generateNcFlag;

% array to store GPS data
global g_decArgo_gpsData;

% cycle phases
global g_decArgo_phasePreMission;
global g_decArgo_phaseSatTrans;
global g_decArgo_phaseEndOfLife;

% current cycle and pattern number
global g_decArgo_cycleNumFloat;
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloat;
global g_decArgo_patternNumFloatStr;

% prefix of data file names
global g_decArgo_filePrefixCts5;

% type of files to consider
global g_decArgo_fileTypeListCts5;

% meta-data retrieved from APMT tech files
global g_decArgo_apmtMetaFromTech;

% time data retrieved from APMT tech files
global g_decArgo_apmtTimeFromTech;


if (isempty(a_fileNameList))
   return
end

% set the type of each file
fileNames = a_fileNameList;
fileTypes = zeros(size(fileNames));
for idF = 1:length(fileNames)
   fileName = fileNames{idF};
   if (~isempty(g_decArgo_patternNumFloat))
      typeList = [1 2 4:20]; % types with pattern #
      for idType = typeList
         idFL = find([g_decArgo_fileTypeListCts5{:, 1}] == idType);
         if (length(fileName) > g_decArgo_fileTypeListCts5{idFL, 4})
            [val, count, errmsg, nextindex] = sscanf( ...
               fileName(1:g_decArgo_fileTypeListCts5{idFL, 4}), ...
               [g_decArgo_filePrefixCts5 g_decArgo_fileTypeListCts5{idFL, 3}]);
            if (isempty(errmsg) && (count == 2))
               if (strcmp(fileName(end-3:end), g_decArgo_fileTypeListCts5{idFL, 2}(end-3:end)))
                  fileTypes(idF) = idType;
                  break
               end
            end
         end
      end
   else
      if (strncmp(fileName, g_decArgo_filePrefixCts5, length(g_decArgo_filePrefixCts5)))
         typeList = [3]; % types without pattern #
         for idType = typeList
            idFL = find([g_decArgo_fileTypeListCts5{:, 1}] == idType);
            if (length(fileName) > g_decArgo_fileTypeListCts5{idFL, 4})
               [val, count, errmsg, nextindex] = sscanf( ...
                  fileName(1:g_decArgo_fileTypeListCts5{idFL, 4}), ...
                  [g_decArgo_filePrefixCts5 g_decArgo_fileTypeListCts5{idFL, 3}]);
               if (isempty(errmsg) && (count == 1))
                  fileTypes(idF) = idType;
                  break
               end
            end
         end
      end
   end
end

% do not consider metadata.xml (already used at float declaration)
idXmlFile = find(fileTypes == 2);
fileNames(idXmlFile) = [];
fileTypes(idXmlFile) = [];

% set the configuration only if data has been received
if (~isempty(intersect(fileTypes, 6:17)))
   % we should set the configuration before decoding apmt configuration
   % (which concerns the next cycle and pattern)
   set_float_config_ir_rudics_cts5_usea(g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat);
end

% the files should be processed in the following order
typeOrderList = [3 4 6:20 5 1];
% 3, 4, 6 to 20, 5: usual order i.e. tech first, data after and EOL at the end
% 1: last the apmt configuration because it concerns the next cycle and pattern

% process the files
fprintf('DEC_INFO: decoding files:\n');
apmtCtd = [];
apmtDo = [];
apmtEco = [];
apmtOcr = [];
uvpLpmData = [];
uvpBlackData = [];
apmtSbeph = [];
apmtCrover = [];
apmtSuna = [];
opusLightData = [];
opusBlackData = [];
ramsesData = [];
mpeData = [];
hydrocMData = [];
hydrocCData = [];

techDataFromApmtTech = [];
timeDataFromApmtTech = [];
for typeNum = typeOrderList

   idFileForType = find(fileTypes == typeNum);
   if (~isempty(idFileForType))

      fileNamesForType = fileNames(idFileForType);
      for idFile = 1:length(fileNamesForType)

         % manage split files
         [~, fileName, fileExtension] = fileparts(fileNamesForType{idFile});
         fileNameInfo = manage_split_files({g_decArgo_archiveDirectory}, ...
            {[fileName '*' fileExtension]}, a_decoderId);

         % decode files
         switch (typeNum)

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 1
               % '*_apmt*.ini'

               % apmt configuration file

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));

               % read apmt configuration
               apmtConfig = read_apmt_config([fileNameInfo{4} fileNameInfo{1}], a_decoderId);

               % update current configuration
               update_float_config_ir_rudics_cts5_usea(apmtConfig);

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end

                  % print apmt configuration in CSV file
                  print_apmt_config_in_csv_file_ir_rudics_cts5(apmtConfig);

                  % print updated configuration in CSV file
                  print_config_in_csv_file_ir_rudics_cts5('Updated_config');
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case {3, 4, 5}
               % '*_autotest_*.txt'
               % '*_technical*.txt'
               % '*_default_*.txt'

               % apmt technical information

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));

               [apmtTech, apmtTimeFromTech, ...
                  ncApmtTech, apmtTrajFromTech, apmtMetaFromTech] = ...
                  get_apmt_technical_file(fileNameInfo{1});
               g_decArgo_apmtMetaFromTech = [g_decArgo_apmtMetaFromTech apmtMetaFromTech];
               if (~isempty(g_decArgo_patternNumFloat))
                  g_decArgo_apmtTimeFromTech = cat(1, g_decArgo_apmtTimeFromTech, ...
                     [g_decArgo_cycleNumFloat g_decArgo_patternNumFloat {apmtTimeFromTech}]);
               end

               % store GPS data
               store_gps_data_ir_rudics_cts5(apmtTech, typeNum);

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end

                  print_apmt_tech_in_csv_file_ir_rudics_cts5(apmtTech, typeNum);

                  % store TIME information
                  if (~isempty(apmtTimeFromTech))
                     cycleNumFloat = g_decArgo_cycleNumFloat;
                     patternNumFloat = g_decArgo_patternNumFloat;
                     if (isempty(patternNumFloat))
                        patternNumFloat = 0;
                     end
                     timeDataFromApmtTech = [timeDataFromApmtTech;
                        [cycleNumFloat patternNumFloat {apmtTimeFromTech}]];
                  end

               else

                  % store TECH and TRAJ information
                  if (~isempty(apmtTrajFromTech) || ~isempty(ncApmtTech))
                     cycleNumFloat = g_decArgo_cycleNumFloat;
                     patternNumFloat = g_decArgo_patternNumFloat;
                     if (isempty(patternNumFloat))
                        patternNumFloat = 0;
                     end
                     if (typeNum == 3)
                        cyclePhase = g_decArgo_phasePreMission;
                     elseif (typeNum == 4)
                        cyclePhase = g_decArgo_phaseSatTrans;
                     elseif (typeNum == 5)
                        cyclePhase = g_decArgo_phaseEndOfLife;
                     end
                     if (~isempty(ncApmtTech))
                        techDataFromApmtTech = [techDataFromApmtTech;
                           [cycleNumFloat patternNumFloat cyclePhase {ncApmtTech}]];
                     end
                     if (~isempty(apmtTrajFromTech))
                        o_trajDataFromApmtTech = [o_trajDataFromApmtTech;
                           [cycleNumFloat patternNumFloat cyclePhase {apmtTrajFromTech}]];
                     end
                  end
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 6
               % '*_sbe41*.hex'

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               apmtCtd = decode_apmt_ctd([fileNameInfo{4} fileNameInfo{1}], a_decoderId);

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end

                  print_data_in_csv_file_ir_rudics_cts5_CTD(apmtCtd);
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 7
               % '*_do*.hex'

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               apmtDo = decode_apmt_do([fileNameInfo{4} fileNameInfo{1}]);

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end

                  print_data_in_csv_file_ir_rudics_cts5_DO(apmtDo);
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 8
               % '*_eco*.hex'

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               apmtEco = decode_apmt_eco([fileNameInfo{4} fileNameInfo{1}]);

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end

                  print_data_in_csv_file_ir_rudics_cts5_ECO(apmtEco);
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 9
               % '*_ocr*.hex'

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               apmtOcr = decode_apmt_ocr([fileNameInfo{4} fileNameInfo{1}]);

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end

                  print_data_in_csv_file_ir_rudics_cts5_OCR(apmtOcr, a_decoderId);
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case {10, 11}
               % '*_uvp6_blk*.hex'
               % '*_uvp6_lpm*.hex'

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               [uvpLpmDataDec, uvpBlackDataDec] = decode_apmt_uvp([fileNameInfo{4} fileNameInfo{1}]);
               if (~isempty(uvpLpmDataDec))
                  uvpLpmData = uvpLpmDataDec;
               end
               if (~isempty(uvpBlackDataDec))
                  uvpBlackData = uvpBlackDataDec;
               end

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end

                  print_data_in_csv_file_ir_rudics_cts5_UVP(uvpLpmDataDec, uvpBlackDataDec);
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 12
               % '*_crover*.hex'

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               apmtCrover = decode_apmt_crover([fileNameInfo{4} fileNameInfo{1}]);

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end

                  print_data_in_csv_file_ir_rudics_cts5_CROVER(apmtCrover);
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 13
               % '*_sbeph*.hex'

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               apmtSbeph = decode_apmt_sbeph([fileNameInfo{4} fileNameInfo{1}]);

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end

                  print_data_in_csv_file_ir_rudics_cts5_SBEPH(apmtSbeph);
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 14
               % '*_suna*.hex'

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               apmtSuna = decode_apmt_suna([fileNameInfo{4} fileNameInfo{1}]);

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end

                  print_data_in_csv_file_ir_rudics_cts5_SUNA(apmtSuna);
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case {15, 16}
               % '*_opus_blk*.hex'
               % '*_opus_lgt*.hex'

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               [opusLightDataDec, opusBlackDataDec] = decode_apmt_opus([fileNameInfo{4} fileNameInfo{1}]);
               if (~isempty(opusLightDataDec))
                  opusLightData = opusLightDataDec;
               end
               if (~isempty(opusBlackDataDec))
                  opusBlackData = opusBlackDataDec;
               end

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  print_data_in_csv_file_ir_rudics_cts5_OPUS(opusLightDataDec, opusBlackDataDec);
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 17
               % '*_ramses*.hex'

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               ramsesData = decode_apmt_ramses([fileNameInfo{4} fileNameInfo{1}]);

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end

                  print_data_in_csv_file_ir_rudics_cts5_RAMSES(ramsesData);
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 18
               % '*_mpe*.hex'

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               mpeData = decode_apmt_mpe([fileNameInfo{4} fileNameInfo{1}]);

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end

                  print_data_in_csv_file_ir_rudics_cts5_MPE(mpeData);
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case {19, 20}
               % '*_hydroc_c*.hex'
               % '*_hydroc_m*.hex'

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               [hydrocMDataDec, hydrocCDataDec] = decode_apmt_hydroc([fileNameInfo{4} fileNameInfo{1}]);
               if (~isempty(hydrocMDataDec))
                  hydrocMData = hydrocMDataDec;
               end
               if (~isempty(hydrocCDataDec))
                  hydrocCData = hydrocCDataDec;
               end

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  print_data_in_csv_file_ir_rudics_cts5_HYDROC(hydrocMDataDec, hydrocCDataDec);
               end

            otherwise
               fprintf('WARNING: Nothing define yet to process file: %s\n', ...
                  fileNamesForType{idFile});
         end
      end

      fileNames(idFileForType) = [];
      fileTypes(idFileForType) = [];

      if (isempty(fileNames))
         break
      end
   end
end

if (~isempty(fileNames))
   fprintf('DEC_WARNING: %d files were not processed\n', ...
      length(fileNames));
end

if (~isempty(g_decArgo_outputCsvFileId))

   % print time data in csv file
   print_dates_in_csv_file_ir_rudics_cts5_usea( ...
      timeDataFromApmtTech, apmtCtd, apmtDo, apmtEco, apmtOcr, uvpLpmData, uvpBlackData, ...
      apmtSbeph, apmtCrover, apmtSuna, opusLightData, opusBlackData, ramsesData, mpeData, ...
      hydrocMData, hydrocCData);
end

% output NetCDF data
if (isempty(g_decArgo_outputCsvFileId))

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtCtd))

      % create profiles (as they are transmitted)
      [tabProfilesCtd, tabDriftCtd, tabSurfCtd, o_subSurfaceMeas] = ...
         process_profile_ir_rudics_cts5_usea_ctd(apmtCtd, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesCtd] = merge_profile_meas_ir_rudics_cts5_usea_ctd(tabProfilesCtd);

      % add the vertical sampling scheme from configuration information
      [tabProfilesCtd] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_ctd(tabProfilesCtd);

      o_tabProfiles = [o_tabProfiles tabProfilesCtd];
      o_tabDrift = [o_tabDrift tabDriftCtd];
      o_tabSurf = [o_tabSurf tabSurfCtd];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtDo))

      % create profiles (as they are transmitted)
      [tabProfilesDo, tabDriftDo, tabSurfDo] = ...
         process_profile_ir_rudics_cts5_usea_do(apmtDo, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesDo] = merge_profile_meas_ir_rudics_cts5_usea_do(tabProfilesDo);

      % add the vertical sampling scheme from configuration information
      [tabProfilesDo] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesDo);

      o_tabProfiles = [o_tabProfiles tabProfilesDo];
      o_tabDrift = [o_tabDrift tabDriftDo];
      o_tabSurf = [o_tabSurf tabSurfDo];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtOcr))

      % create profiles (as they are transmitted)
      [tabProfilesOcr, tabDriftOcr, tabSurfOcr] = ...
         process_profile_ir_rudics_cts5_usea_ocr(apmtOcr, apmtTimeFromTech, g_decArgo_gpsData, a_decoderId);

      % merge profiles (all data from a given sensor together)
      [tabProfilesOcr] = merge_profile_meas_ir_rudics_cts5_usea_ocr(tabProfilesOcr);

      % add the vertical sampling scheme from configuration information
      [tabProfilesOcr] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesOcr);

      o_tabProfiles = [o_tabProfiles tabProfilesOcr];
      o_tabDrift = [o_tabDrift tabDriftOcr];
      o_tabSurf = [o_tabSurf tabSurfOcr];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtEco))

      % create profiles (as they are transmitted)
      [tabProfilesEco, tabDriftEco, tabSurfEco] = ...
         process_profile_ir_rudics_cts5_usea_eco(apmtEco, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesEco] = merge_profile_meas_ir_rudics_cts5_usea_eco(tabProfilesEco);

      % add the vertical sampling scheme from configuration information
      [tabProfilesEco] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesEco);

      o_tabProfiles = [o_tabProfiles tabProfilesEco];
      o_tabDrift = [o_tabDrift tabDriftEco];
      o_tabSurf = [o_tabSurf tabSurfEco];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtSbeph))

      % create profiles (as they are transmitted)
      [tabProfilesSbeph, tabDriftSbeph, tabSurfSbeph] = ...
         process_profile_ir_rudics_cts5_usea_sbeph(apmtSbeph, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesSbeph] = merge_profile_meas_ir_rudics_cts5_usea_sbeph(tabProfilesSbeph);

      % add the vertical sampling scheme from configuration information
      [tabProfilesSbeph] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesSbeph);

      o_tabProfiles = [o_tabProfiles tabProfilesSbeph];
      o_tabDrift = [o_tabDrift tabDriftSbeph];
      o_tabSurf = [o_tabSurf tabSurfSbeph];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtCrover))

      % create profiles (as they are transmitted)
      [tabProfilesCrover, tabDriftCrover, tabSurfCrover] = ...
         process_profile_ir_rudics_cts5_usea_crover(apmtCrover, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesCrover] = merge_profile_meas_ir_rudics_cts5_usea_crover(tabProfilesCrover);

      % add the vertical sampling scheme from configuration information
      [tabProfilesCrover] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesCrover);

      o_tabProfiles = [o_tabProfiles tabProfilesCrover];
      o_tabDrift = [o_tabDrift tabDriftCrover];
      o_tabSurf = [o_tabSurf tabSurfCrover];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtSuna))

      % create profiles (as they are transmitted)
      [tabProfilesSuna, tabDriftSuna, tabSurfSuna] = ...
         process_profile_ir_rudics_cts5_usea_suna(apmtSuna, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesSuna] = merge_profile_meas_ir_rudics_cts5_usea_suna(tabProfilesSuna);

      % add the vertical sampling scheme from configuration information
      [tabProfilesSuna] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesSuna);

      o_tabProfiles = [o_tabProfiles tabProfilesSuna];
      o_tabDrift = [o_tabDrift tabDriftSuna];
      o_tabSurf = [o_tabSurf tabSurfSuna];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(uvpLpmData))

      % create profiles (as they are transmitted)
      [tabProfilesUvpLpm, tabDriftUvpLpm, tabSurfUvpLpm] = ...
         process_profile_ir_rudics_cts5_usea_uvp_lpm(uvpLpmData, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesUvpLpm] = merge_profile_meas_ir_rudics_cts5_usea_uvp_lpm(tabProfilesUvpLpm);

      % add the vertical sampling scheme from configuration information
      [tabProfilesUvpLpm] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesUvpLpm);

      o_tabProfiles = [o_tabProfiles tabProfilesUvpLpm];
      o_tabDrift = [o_tabDrift tabDriftUvpLpm];
      o_tabSurf = [o_tabSurf tabSurfUvpLpm];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(uvpBlackData))

      % create profiles (as they are transmitted)
      [tabProfilesUvpBlack, tabDriftUvpBlack, tabSurfUvpBlack] = ...
         process_profile_ir_rudics_cts5_usea_uvp_black(uvpBlackData, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesUvpBlack] = merge_profile_meas_ir_rudics_cts5_usea_uvp_black(tabProfilesUvpBlack);

      % add the vertical sampling scheme from configuration information
      [tabProfilesUvpBlack] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesUvpBlack);

      o_tabProfiles = [o_tabProfiles tabProfilesUvpBlack];
      o_tabDrift = [o_tabDrift tabDriftUvpBlack];
      o_tabSurf = [o_tabSurf tabSurfUvpBlack];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(opusLightData))

      % create profiles (as they are transmitted)
      [tabProfilesOpusLight, tabDriftOpusLight, tabSurfOpusLight] = ...
         process_profile_ir_rudics_cts5_usea_opus_light(opusLightData, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesOpusLight] = merge_profile_meas_ir_rudics_cts5_usea_opus_light(tabProfilesOpusLight);

      % add the vertical sampling scheme from configuration information
      [tabProfilesOpusLight] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesOpusLight);

      o_tabProfiles = [o_tabProfiles tabProfilesOpusLight];
      o_tabDrift = [o_tabDrift tabDriftOpusLight];
      o_tabSurf = [o_tabSurf tabSurfOpusLight];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(opusBlackData))

      % create profiles (as they are transmitted)
      [tabProfilesOpusBlack, tabDriftOpusBlack, tabSurfOpusBlack] = ...
         process_profile_ir_rudics_cts5_usea_opus_black(opusBlackData, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesOpusBlack] = merge_profile_meas_ir_rudics_cts5_usea_opus_black(tabProfilesOpusBlack);

      % add the vertical sampling scheme from configuration information
      [tabProfilesOpusBlack] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesOpusBlack);

      o_tabProfiles = [o_tabProfiles tabProfilesOpusBlack];
      o_tabDrift = [o_tabDrift tabDriftOpusBlack];
      o_tabSurf = [o_tabSurf tabSurfOpusBlack];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(ramsesData))

      % create profiles (as they are transmitted)
      [tabProfilesRamses, tabDriftRamses, tabSurfRamses] = ...
         process_profile_ir_rudics_cts5_usea_ramses(ramsesData, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesRamses] = merge_profile_meas_ir_rudics_cts5_usea_ramses(tabProfilesRamses);

      % add the vertical sampling scheme from configuration information
      [tabProfilesRamses] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesRamses);

      o_tabProfiles = [o_tabProfiles tabProfilesRamses];
      o_tabDrift = [o_tabDrift tabDriftRamses];
      o_tabSurf = [o_tabSurf tabSurfRamses];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(mpeData))

      % create profiles (as they are transmitted)
      [tabProfilesMpe, tabDriftMpe, tabSurfMpe] = ...
         process_profile_ir_rudics_cts5_usea_mpe(mpeData, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesMpe] = merge_profile_meas_ir_rudics_cts5_usea_mpe(tabProfilesMpe);

      % add the vertical sampling scheme from configuration information
      [tabProfilesMpe] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesMpe);

      o_tabProfiles = [o_tabProfiles tabProfilesMpe];
      o_tabDrift = [o_tabDrift tabDriftMpe];
      o_tabSurf = [o_tabSurf tabSurfMpe];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(hydrocMData) || ~isempty(hydrocCData))

      % create profiles (as they are transmitted)
      [tabProfilesHydroc, tabDriftHydroc, tabSurfHydroc] = ...
         process_profile_ir_rudics_cts5_usea_hydroc(hydrocMData, hydrocCData, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesHydroc] = merge_profile_meas_ir_rudics_cts5_usea_hydroc(tabProfilesHydroc);

      % add the vertical sampling scheme from configuration information
      [tabProfilesHydroc] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesHydroc);

      o_tabProfiles = [o_tabProfiles tabProfilesHydroc];
      o_tabDrift = [o_tabDrift tabDriftHydroc];
      o_tabSurf = [o_tabSurf tabSurfHydroc];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % compute derived parameters of the profiles
   [o_tabProfiles] = compute_profile_derived_parameters_ir_rudics(o_tabProfiles, a_decoderId);

   % compute derived parameters of the park phase
   [o_tabDrift] = compute_drift_derived_parameters_ir_rudics(o_tabDrift, a_decoderId);

   % compute derived parameters of the surface phase
   [o_tabSurf] = compute_surface_derived_parameters_ir_rudics_cts5(o_tabSurf, a_decoderId);

   print = 0;
   if (print == 1)
      if (~isempty(o_tabProfiles))
         fprintf('DEC_INFO: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): %d profiles for NetCDF file\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            g_decArgo_cycleNumFloat, ...
            g_decArgo_patternNumFloat, ...
            length(o_tabProfiles));
         for idP = 1:length(o_tabProfiles)
            prof = o_tabProfiles(idP);
            paramList = prof.paramList;
            paramList = sprintf('%s ', paramList.name);
            profLength = size(prof.data, 1);
            fprintf('   ->%2d: Profile #%d dir=%c length=%d param=(%s)\n', ...
               idP, prof.profileNumber, prof.direction, ...
               profLength, paramList(1:end-1));
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % TECH NetCDF file

   % collect technical data (and merge Tech and Event technical data)
   [o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = collect_technical_data_cts5_usea(techDataFromApmtTech);

end

if (~isempty(o_tabProfiles) || ~isempty(o_tabDrift) || ...
      ~isempty(o_tabSurf) || ~isempty(o_tabNcTechIndex) || ...
      ~isempty(o_tabNcTechVal) || ~isempty(o_tabTechNMeas))
   g_decArgo_generateNcFlag = 1;
end

return
