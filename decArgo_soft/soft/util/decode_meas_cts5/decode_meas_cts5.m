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
%                                (for decId 128)
%   08/30/2023 - RNU - creation: V1.1 delivered in '057h' decoder version
%                                (for decId 129)
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
FLOAT_DECODER_ID = 129;


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
read_apmt_technical_data(floatCycleList, g_decArgo_cyclePatternNumFloat, g_decArgo_filePrefixCts5, FLOAT_DECODER_ID, 1);

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
      tabDrift, tabDesc2Prof, tabSurf, subSurfaceMeas, trajDataFromApmtTech, ...
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
         tabDrift, tabDesc2Prof, tabSurf, subSurfaceMeas, trajDataFromApmtTech, ...
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
%    o_tabDrift, o_tabDesc2Prof, o_tabSurf, o_subSurfaceMeas, o_trajDataFromApmtTech, ...
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
%   o_tabDesc2Prof         : decoded descent 2 prof measurement data
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
   o_tabDrift, o_tabDesc2Prof, o_tabSurf, o_subSurfaceMeas, o_trajDataFromApmtTech, ...
   o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
   decode_files(a_fileNameList, a_decoderId)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];
o_tabDesc2Prof = [];
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

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;


if (isempty(a_fileNameList))
   return
end

% set the type of each file
fileNames = a_fileNameList;
fileTypes = zeros(size(fileNames));
for idF = 1:length(fileNames)
   fileName = fileNames{idF};
   if (~isempty(g_decArgo_patternNumFloat))
      typeList = fliplr([1 2 4:24]); % types with pattern # (fliplr so that ramses2 is checked before ramses)
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
if (~isempty(intersect(fileTypes, 6:24)))
   % we should set the configuration before decoding apmt configuration
   % (which concerns the next cycle and pattern)
   set_float_config_ir_rudics_cts5_usea(g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat);
end

% the files should be processed in the following order
typeOrderList = [3 4 6:24 5 1];
% 3, 4, 6 to 24, 5: usual order i.e. tech first, data after and EOL at the end
% 1: last the apmt configuration because it concerns the next cycle and pattern

% process the files
fprintf('DEC_INFO: decoding files:\n');
apmtCtd = [];
apmtDo = [];
apmtEco = [];
apmtOcr = [];
apmtUvpLpm = [];
apmtUvpLpmV2 = [];
apmtUvpBlack = [];
apmtUvpBlackV2 = [];
apmtUvpTaxoV2 = [];
apmtSbeph = [];
apmtCrover = [];
apmtSuna = [];
apmtOpusLight = [];
apmtOpusBlack = [];
apmtRamses = [];
apmtRamses2 = [];
apmtMpe = [];
apmtHydrocM = [];
apmtHydrocC = [];
apmtImuRaw = [];
apmtImuTiltHeading = [];
apmtImuWave = [];

apmtTimeFromTech = [];
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

                  if (~isempty(g_decArgo_iridiumMailData))
                     print_iridium_locations_in_csv_file_ir_rudics_cts5(g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat);
                  end

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
               apmtCtd = decode_apmt_ctd(fileNameInfo, a_decoderId);
               if (isempty(apmtCtd))
                  continue
               end

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
               apmtDo = decode_apmt_do(fileNameInfo);
               if (isempty(apmtDo))
                  continue
               end

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
               apmtEco = decode_apmt_eco(fileNameInfo);
               if (isempty(apmtEco))
                  continue
               end

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end

                  print_data_in_csv_file_ir_rudics_cts5_ECO(apmtEco, a_decoderId);
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 9
               % '*_ocr*.hex'

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               apmtOcr = decode_apmt_ocr(fileNameInfo);
               if (isempty(apmtOcr))
                  continue
               end

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end

                  print_data_in_csv_file_ir_rudics_cts5_OCR(apmtOcr, a_decoderId);
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case {10, 11, 21}
               % '*_uvp6_blk*.hex'
               % '*_uvp6_lpm*.hex'
               % '*_uvp6_txo*.hex'

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               [apmtUvpLpmDec, apmtUvpLpmV2Dec, ...
                  apmtUvpBlackDec, apmtUvpBlackV2Dec, ...
                  apmtUvpTaxoV2Dec] = decode_apmt_uvp(fileNameInfo);
               if (isempty(apmtUvpLpmDec) && isempty(apmtUvpLpmV2Dec) && ...
                     isempty(apmtUvpBlackDec) && isempty(apmtUvpBlackV2Dec) && ...
                     isempty(apmtUvpTaxoV2Dec))
                  continue
               end

               if (~isempty(apmtUvpLpmDec))
                  apmtUvpLpm = apmtUvpLpmDec;
               end
               if (~isempty(apmtUvpLpmV2Dec))
                  apmtUvpLpmV2 = apmtUvpLpmV2Dec;
               end
               if (~isempty(apmtUvpBlackDec))
                  apmtUvpBlack = apmtUvpBlackDec;
               end
               if (~isempty(apmtUvpBlackV2Dec))
                  apmtUvpBlackV2 = apmtUvpBlackV2Dec;
               end
               if (~isempty(apmtUvpTaxoV2Dec))
                  apmtUvpTaxoV2 = apmtUvpTaxoV2Dec;
               end

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end

                  print_data_in_csv_file_ir_rudics_cts5_UVP( ...
                     apmtUvpLpmDec, apmtUvpLpmV2Dec, ...
                     apmtUvpBlackDec, apmtUvpBlackV2Dec, ...
                     apmtUvpTaxoV2Dec);
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 12
               % '*_crover*.hex'

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               apmtCrover = decode_apmt_crover(fileNameInfo);
               if (isempty(apmtCrover))
                  continue
               end

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
               apmtSbeph = decode_apmt_sbeph(fileNameInfo);
               if (isempty(apmtSbeph))
                  continue
               end

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
               apmtSuna = decode_apmt_suna(fileNameInfo);
               if (isempty(apmtSuna))
                  continue
               end

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
               [apmtOpusLightDec, apmtOpusBlackDec] = decode_apmt_opus(fileNameInfo);
               if (isempty(apmtOpusLightDec) && isempty(apmtOpusBlackDec))
                  continue
               end
               
               if (~isempty(apmtOpusLightDec))
                  apmtOpusLight = apmtOpusLightDec;
               end
               if (~isempty(apmtOpusBlackDec))
                  apmtOpusBlack = apmtOpusBlackDec;
               end

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  print_data_in_csv_file_ir_rudics_cts5_OPUS(apmtOpusLightDec, apmtOpusBlackDec);
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case {17, 22}
               % '*_ramses*.hex'
               % '*_ramses2*.hex'

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               [apmtRamsesDec, apmtRamses2Dec] = decode_apmt_ramses(fileNameInfo);
               if (isempty(apmtRamsesDec) && isempty(apmtRamses2Dec))
                  continue
               end

               if (~isempty(apmtRamsesDec))
                  apmtRamses = apmtRamsesDec;
               end
               if (~isempty(apmtRamses2Dec))
                  apmtRamses2 = apmtRamses2Dec;
               end

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end

                  print_data_in_csv_file_ir_rudics_cts5_RAMSES(apmtRamsesDec, apmtRamses2Dec);
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 18
               % '*_mpe*.hex'

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               apmtMpe = decode_apmt_mpe(fileNameInfo);
               if (isempty(apmtMpe))
                  continue
               end

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end

                  print_data_in_csv_file_ir_rudics_cts5_MPE(apmtMpe);
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case {19, 20}
               % '*_hydroc_c*.hex'
               % '*_hydroc_m*.hex'

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               [apmtHydrocMDec, apmtHydrocCDec] = decode_apmt_hydroc(fileNameInfo);
               if (isempty(apmtHydrocMDec) && isempty(apmtHydrocCDec))
                  continue
               end
               
               if (~isempty(apmtHydrocMDec))
                  apmtHydrocM = apmtHydrocMDec;
               end
               if (~isempty(apmtHydrocCDec))
                  apmtHydrocC = apmtHydrocCDec;
               end

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  print_data_in_csv_file_ir_rudics_cts5_HYDROC(apmtHydrocMDec, apmtHydrocCDec);
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case {23, 24}
               % '*_imu*.hex'
               % '*_wave*.hex'

               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               [apmtImuRawDec, apmtImuTiltHeadingDec, ...
                  apmtImuWaveDec] = decode_apmt_imu(fileNameInfo);
               if (isempty(apmtImuRawDec) && isempty(apmtImuTiltHeadingDec) && ...
                     isempty(apmtImuWaveDec))
                  continue
               end

               if (~isempty(apmtImuRawDec))
                  apmtImuRaw = apmtImuRawDec;
               end
               if (~isempty(apmtImuTiltHeadingDec))
                  apmtImuTiltHeading = apmtImuTiltHeadingDec;
               end
               if (~isempty(apmtImuWaveDec))
                  apmtImuWave = apmtImuWaveDec;
               end

               if (~isempty(g_decArgo_outputCsvFileId))

                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  print_data_in_csv_file_ir_rudics_cts5_IMU(apmtImuRawDec, apmtImuTiltHeadingDec, apmtImuWaveDec);
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
      timeDataFromApmtTech, apmtCtd, apmtDo, apmtEco, apmtOcr, ...
      apmtUvpLpm, apmtUvpLpmV2, apmtUvpBlack, apmtUvpBlackV2, apmtUvpTaxoV2, ...
      apmtSbeph, apmtCrover, apmtSuna, apmtOpusLight, apmtOpusBlack, ...
      apmtRamses, apmtRamses2, apmtMpe, ...
      apmtHydrocM, apmtHydrocC, ...
      apmtImuRaw, apmtImuTiltHeading, apmtImuWave);
end

% output NetCDF data
if (isempty(g_decArgo_outputCsvFileId))

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtCtd))

      % create profiles (as they are transmitted)
      [tabProfilesCtd, tabDriftCtd, tabDesc2ProfCtd, tabSurfCtd, o_subSurfaceMeas] = ...
         process_profile_ir_rudics_cts5_usea_ctd(apmtCtd, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesCtd] = merge_profile_meas_ir_rudics_cts5_usea_ctd(tabProfilesCtd);

      % add the vertical sampling scheme from configuration information
      [tabProfilesCtd] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_ctd(tabProfilesCtd);

      o_tabProfiles = [o_tabProfiles tabProfilesCtd];
      o_tabDrift = [o_tabDrift tabDriftCtd];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfCtd];
      o_tabSurf = [o_tabSurf tabSurfCtd];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtDo))

      % create profiles (as they are transmitted)
      [tabProfilesDo, tabDriftDo, tabDesc2ProfDo, tabSurfDo] = ...
         process_profile_ir_rudics_cts5_usea_do(apmtDo, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesDo] = merge_profile_meas_ir_rudics_cts5_usea_do(tabProfilesDo);

      % add the vertical sampling scheme from configuration information
      [tabProfilesDo] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesDo);

      o_tabProfiles = [o_tabProfiles tabProfilesDo];
      o_tabDrift = [o_tabDrift tabDriftDo];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfDo];
      o_tabSurf = [o_tabSurf tabSurfDo];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtOcr))

      % create profiles (as they are transmitted)
      [tabProfilesOcr, tabDriftOcr, tabDesc2ProfOcr, tabSurfOcr] = ...
         process_profile_ir_rudics_cts5_usea_ocr(apmtOcr, apmtTimeFromTech, g_decArgo_gpsData, a_decoderId);

      % merge profiles (all data from a given sensor together)
      [tabProfilesOcr] = merge_profile_meas_ir_rudics_cts5_usea_ocr(tabProfilesOcr, a_decoderId);

      % add the vertical sampling scheme from configuration information
      [tabProfilesOcr] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesOcr);

      o_tabProfiles = [o_tabProfiles tabProfilesOcr];
      o_tabDrift = [o_tabDrift tabDriftOcr];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfOcr];
      o_tabSurf = [o_tabSurf tabSurfOcr];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtEco))

      % create profiles (as they are transmitted)
      [tabProfilesEco, tabDriftEco, tabDesc2ProfEco, tabSurfEco] = ...
         process_profile_ir_rudics_cts5_usea_eco(apmtEco, apmtTimeFromTech, g_decArgo_gpsData, a_decoderId);

      % merge profiles (all data from a given sensor together)
      [tabProfilesEco] = merge_profile_meas_ir_rudics_cts5_usea_eco(tabProfilesEco, a_decoderId);

      % add the vertical sampling scheme from configuration information
      [tabProfilesEco] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesEco);

      o_tabProfiles = [o_tabProfiles tabProfilesEco];
      o_tabDrift = [o_tabDrift tabDriftEco];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfEco];
      o_tabSurf = [o_tabSurf tabSurfEco];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtSbeph))

      % create profiles (as they are transmitted)
      [tabProfilesSbeph, tabDriftSbeph, tabDesc2ProfSbeph, tabSurfSbeph] = ...
         process_profile_ir_rudics_cts5_usea_sbeph(apmtSbeph, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesSbeph] = merge_profile_meas_ir_rudics_cts5_usea_sbeph(tabProfilesSbeph);

      % add the vertical sampling scheme from configuration information
      [tabProfilesSbeph] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesSbeph);

      o_tabProfiles = [o_tabProfiles tabProfilesSbeph];
      o_tabDrift = [o_tabDrift tabDriftSbeph];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfSbeph];
      o_tabSurf = [o_tabSurf tabSurfSbeph];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtCrover))

      % create profiles (as they are transmitted)
      [tabProfilesCrover, tabDriftCrover, tabDesc2ProfCrover, tabSurfCrover] = ...
         process_profile_ir_rudics_cts5_usea_crover(apmtCrover, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesCrover] = merge_profile_meas_ir_rudics_cts5_usea_crover(tabProfilesCrover);

      % add the vertical sampling scheme from configuration information
      [tabProfilesCrover] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesCrover);

      o_tabProfiles = [o_tabProfiles tabProfilesCrover];
      o_tabDrift = [o_tabDrift tabDriftCrover];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfCrover];
      o_tabSurf = [o_tabSurf tabSurfCrover];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtSuna))

      % create profiles (as they are transmitted)
      [tabProfilesSuna, tabDriftSuna, tabDesc2ProfSuna, tabSurfSuna] = ...
         process_profile_ir_rudics_cts5_usea_suna(apmtSuna, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesSuna] = merge_profile_meas_ir_rudics_cts5_usea_suna(tabProfilesSuna);

      % add the vertical sampling scheme from configuration information
      [tabProfilesSuna] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesSuna);

      o_tabProfiles = [o_tabProfiles tabProfilesSuna];
      o_tabDrift = [o_tabDrift tabDriftSuna];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfSuna];
      o_tabSurf = [o_tabSurf tabSurfSuna];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtUvpLpm))

      % create profiles (as they are transmitted)
      [tabProfilesUvpLpm, tabDriftUvpLpm, tabDesc2ProfUvpLpm, tabSurfUvpLpm] = ...
         process_profile_ir_rudics_cts5_usea_uvp_lpm(apmtUvpLpm, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesUvpLpm] = merge_profile_meas_ir_rudics_cts5_usea_uvp_lpm(tabProfilesUvpLpm);

      % add the vertical sampling scheme from configuration information
      [tabProfilesUvpLpm] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesUvpLpm);

      o_tabProfiles = [o_tabProfiles tabProfilesUvpLpm];
      o_tabDrift = [o_tabDrift tabDriftUvpLpm];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfUvpLpm];
      o_tabSurf = [o_tabSurf tabSurfUvpLpm];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtUvpLpmV2))

      % create profiles (as they are transmitted)
      [tabProfilesUvpLpmV2, tabDriftUvpLpmV2, tabDesc2ProfUvpLpmV2, tabSurfUvpLpmV2] = ...
         process_profile_ir_rudics_cts5_usea_uvp_lpm_v2(apmtUvpLpmV2, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesUvpLpmV2] = merge_profile_meas_ir_rudics_cts5_usea_uvp_lpm_v2(tabProfilesUvpLpmV2);

      % add the vertical sampling scheme from configuration information
      [tabProfilesUvpLpmV2] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesUvpLpmV2);

      o_tabProfiles = [o_tabProfiles tabProfilesUvpLpmV2];
      o_tabDrift = [o_tabDrift tabDriftUvpLpmV2];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfUvpLpmV2];
      o_tabSurf = [o_tabSurf tabSurfUvpLpmV2];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtUvpBlack))

      % create profiles (as they are transmitted)
      [tabProfilesUvpBlack, tabDriftUvpBlack, tabDesc2ProfUvpBlack, tabSurfUvpBlack] = ...
         process_profile_ir_rudics_cts5_usea_uvp_black(apmtUvpBlack, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesUvpBlack] = merge_profile_meas_ir_rudics_cts5_usea_uvp_black(tabProfilesUvpBlack);

      % add the vertical sampling scheme from configuration information
      [tabProfilesUvpBlack] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesUvpBlack);

      o_tabProfiles = [o_tabProfiles tabProfilesUvpBlack];
      o_tabDrift = [o_tabDrift tabDriftUvpBlack];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfUvpBlack];
      o_tabSurf = [o_tabSurf tabSurfUvpBlack];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtUvpBlackV2))

      % create profiles (as they are transmitted)
      [tabProfilesUvpBlackV2, tabDriftUvpBlackV2, tabDesc2ProfUvpBlackV2, tabSurfUvpBlackV2] = ...
         process_profile_ir_rudics_cts5_usea_uvp_black_v2(apmtUvpBlackV2, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesUvpBlackV2] = merge_profile_meas_ir_rudics_cts5_usea_uvp_black_v2(tabProfilesUvpBlackV2);

      % add the vertical sampling scheme from configuration information
      [tabProfilesUvpBlackV2] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesUvpBlackV2);

      o_tabProfiles = [o_tabProfiles tabProfilesUvpBlackV2];
      o_tabDrift = [o_tabDrift tabDriftUvpBlackV2];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfUvpBlackV2];
      o_tabSurf = [o_tabSurf tabSurfUvpBlackV2];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtUvpTaxoV2))

      % create profiles (as they are transmitted)
      [tabProfilesUvpTaxoV2, tabDriftUvpTaxoV2, tabDesc2ProfUvpTaxoV2, tabSurfUvpTaxoV2] = ...
         process_profile_ir_rudics_cts5_usea_uvp_taxo_v2(apmtUvpTaxoV2, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesUvpTaxoV2] = merge_profile_meas_ir_rudics_cts5_usea_uvp_taxo_v2(tabProfilesUvpTaxoV2);

      % add the vertical sampling scheme from configuration information
      [tabProfilesUvpTaxoV2] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesUvpTaxoV2);

      o_tabProfiles = [o_tabProfiles tabProfilesUvpTaxoV2];
      o_tabDrift = [o_tabDrift tabDriftUvpTaxoV2];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfUvpTaxoV2];
      o_tabSurf = [o_tabSurf tabSurfUvpTaxoV2];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtOpusLight))

      % create profiles (as they are transmitted)
      [tabProfilesOpusLight, tabDriftOpusLight, tabDesc2ProfOpusLight, tabSurfOpusLight] = ...
         process_profile_ir_rudics_cts5_usea_opus_light(apmtOpusLight, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesOpusLight] = merge_profile_meas_ir_rudics_cts5_usea_opus_light(tabProfilesOpusLight);

      % add the vertical sampling scheme from configuration information
      [tabProfilesOpusLight] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesOpusLight);

      o_tabProfiles = [o_tabProfiles tabProfilesOpusLight];
      o_tabDrift = [o_tabDrift tabDriftOpusLight];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfOpusLight];
      o_tabSurf = [o_tabSurf tabSurfOpusLight];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtOpusBlack))

      % create profiles (as they are transmitted)
      [tabProfilesOpusBlack, tabDriftOpusBlack, tabDesc2ProfOpusBlack, tabSurfOpusBlack] = ...
         process_profile_ir_rudics_cts5_usea_opus_black(apmtOpusBlack, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesOpusBlack] = merge_profile_meas_ir_rudics_cts5_usea_opus_black(tabProfilesOpusBlack);

      % add the vertical sampling scheme from configuration information
      [tabProfilesOpusBlack] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesOpusBlack);

      o_tabProfiles = [o_tabProfiles tabProfilesOpusBlack];
      o_tabDrift = [o_tabDrift tabDriftOpusBlack];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfOpusBlack];
      o_tabSurf = [o_tabSurf tabSurfOpusBlack];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtRamses))

      % create profiles (as they are transmitted)
      [tabProfilesRamses, tabDriftRamses, tabDesc2ProfRamses, tabSurfRamses] = ...
         process_profile_ir_rudics_cts5_usea_ramses(apmtRamses, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesRamses] = merge_profile_meas_ir_rudics_cts5_usea_ramses(tabProfilesRamses);

      % add the vertical sampling scheme from configuration information
      [tabProfilesRamses] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesRamses);

      o_tabProfiles = [o_tabProfiles tabProfilesRamses];
      o_tabDrift = [o_tabDrift tabDriftRamses];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfRamses];
      o_tabSurf = [o_tabSurf tabSurfRamses];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtRamses2))

      % create profiles (as they are transmitted)
      [tabProfilesRamses2, tabDriftRamses2, tabDesc2ProfRamses2, tabSurfRamses2] = ...
         process_profile_ir_rudics_cts5_usea_ramses2(apmtRamses2, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesRamses2] = merge_profile_meas_ir_rudics_cts5_usea_ramses2(tabProfilesRamses2);

      % add the vertical sampling scheme from configuration information
      [tabProfilesRamses2] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesRamses2);

      o_tabProfiles = [o_tabProfiles tabProfilesRamses2];
      o_tabDrift = [o_tabDrift tabDriftRamses2];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfRamses2];
      o_tabSurf = [o_tabSurf tabSurfRamses2];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtMpe))

      % create profiles (as they are transmitted)
      [tabProfilesMpe, tabDriftMpe, tabDesc2ProfMpe, tabSurfMpe] = ...
         process_profile_ir_rudics_cts5_usea_mpe(apmtMpe, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesMpe] = merge_profile_meas_ir_rudics_cts5_usea_mpe(tabProfilesMpe);

      % add the vertical sampling scheme from configuration information
      [tabProfilesMpe] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesMpe);

      o_tabProfiles = [o_tabProfiles tabProfilesMpe];
      o_tabDrift = [o_tabDrift tabDriftMpe];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfMpe];
      o_tabSurf = [o_tabSurf tabSurfMpe];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtHydrocM) || ~isempty(apmtHydrocC))

      % create profiles (as they are transmitted)
      [tabProfilesHydroc, tabDriftHydroc, tabDesc2ProfHydroc, tabSurfHydroc] = ...
         process_profile_ir_rudics_cts5_usea_hydroc(apmtHydrocM, apmtHydrocC, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesHydroc] = merge_profile_meas_ir_rudics_cts5_usea_hydroc(tabProfilesHydroc);

      % add the vertical sampling scheme from configuration information
      [tabProfilesHydroc] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesHydroc);

      o_tabProfiles = [o_tabProfiles tabProfilesHydroc];
      o_tabDrift = [o_tabDrift tabDriftHydroc];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfHydroc];
      o_tabSurf = [o_tabSurf tabSurfHydroc];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtImuRaw))

      % create profiles (as they are transmitted)
      [tabProfilesImuRaw, tabDriftImuRaw, tabDesc2ProfImuRaw, tabSurfImuRaw] = ...
         process_profile_ir_rudics_cts5_usea_imu_raw(apmtImuRaw, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesImuRaw] = merge_profile_meas_ir_rudics_cts5_usea_imu_raw(tabProfilesImuRaw);

      % add the vertical sampling scheme from configuration information
      [tabProfilesImuRaw] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesImuRaw);

      o_tabProfiles = [o_tabProfiles tabProfilesImuRaw];
      o_tabDrift = [o_tabDrift tabDriftImuRaw];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfImuRaw];
      o_tabSurf = [o_tabSurf tabSurfImuRaw];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtImuTiltHeading))

      % create profiles (as they are transmitted)
      [tabProfilesImuTiltHeading, tabDriftImuTiltHeading, tabDesc2ProfImuTiltHeading, tabSurfImuTiltHeading] = ...
         process_profile_ir_rudics_cts5_usea_imu_tilt_heading(apmtImuTiltHeading, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesImuTiltHeading] = merge_profile_meas_ir_rudics_cts5_usea_imu_tilt_heading(tabProfilesImuTiltHeading);

      % add the vertical sampling scheme from configuration information
      [tabProfilesImuTiltHeading] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesImuTiltHeading);

      o_tabProfiles = [o_tabProfiles tabProfilesImuTiltHeading];
      o_tabDrift = [o_tabDrift tabDriftImuTiltHeading];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfImuTiltHeading];
      o_tabSurf = [o_tabSurf tabSurfImuTiltHeading];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtImuWave))

      % create profiles (as they are transmitted)
      [tabProfilesImuWave, tabDriftImuWave, tabDesc2ProfImuWave, tabSurfImuWave] = ...
         process_profile_ir_rudics_cts5_usea_imu_wave(apmtImuWave, apmtTimeFromTech, g_decArgo_gpsData);

      % merge profiles (all data from a given sensor together)
      [tabProfilesImuWave] = merge_profile_meas_ir_rudics_cts5_usea_imu_wave(tabProfilesImuWave);

      % add the vertical sampling scheme from configuration information
      [tabProfilesImuWave] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesImuWave);

      o_tabProfiles = [o_tabProfiles tabProfilesImuWave];
      o_tabDrift = [o_tabDrift tabDriftImuWave];
      o_tabDesc2Prof = [o_tabDesc2Prof tabDesc2ProfImuWave];
      o_tabSurf = [o_tabSurf tabSurfImuWave];
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % compute derived parameters of the profiles
   [o_tabProfiles] = compute_profile_derived_parameters_ir_rudics(o_tabProfiles, a_decoderId);

   % compute derived parameters of the park phase
   [o_tabDrift] = compute_drift_derived_parameters_ir_rudics(o_tabDrift, a_decoderId);

   % compute derived parameters of the deep profiles
   [o_tabDesc2Prof] = compute_profile_derived_parameters_ir_rudics(o_tabDesc2Prof, a_decoderId);

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

if (~isempty(o_tabProfiles) || ~isempty(o_tabDrift) || ~isempty(o_tabDesc2Prof) || ...
      ~isempty(o_tabSurf) || ~isempty(o_tabNcTechIndex) || ...
      ~isempty(o_tabNcTechVal) || ~isempty(o_tabTechNMeas))
   g_decArgo_generateNcFlag = 1;
end

return
