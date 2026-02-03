% ------------------------------------------------------------------------------
% Generate Easy OneArgo BGC data sets
% (EasyOneArgoDOXY, EasyOneArgoNITRATE, EasyOneArgoPH, EasyOneArgoRADIOMETRY,
% EasyOneArgoCHLA_BBP and EasyOneArgoBGCLite).
%
% SYNTAX :
%   generate_easy_one_argo_bgc(varargin)
%
% INPUT PARAMETERS :
%   varargin :
%      input parameters:
%         - should be provided as pairs ('param_name','param_value')
%         - 'param_name' value is not case sensitive
%   no mandatory input parameters
%   possible input parameters:
%      inputDataDir  : top directory of input NetCDF files
%      inputDataDoi  : DOI of the input data set (Argo monthly snapshot)
%      csvOutputDir  : directory to store the CSV output data sets
%      logDir        : directory to store the log file
%      xmlReportDir  : directory to store the XML report
%      xmlReportName : file name of the XML report
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - V 0.1: creation
% ------------------------------------------------------------------------------
function generate_easy_one_argo_bgc(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START

% top directory of input NetCDF S-PROF files
% (top directory of the DAC name directories (as in the GDAC))
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\ONE_ARGO_BGC\IN\monoS_mini\';
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\ONE_ARGO_BGC\IN\monoS\';

% DOI of the reference input data set
INPUT_DATA_DOI = 'http://doi.org/10.17882/42182#114627';

% top directory of output CSV files
DIR_OUTPUT_CSV_FILES = 'C:\Users\jprannou\_DATA\ONE_ARGO_BGC\OUT\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log';

% directory to store the xml report
DIR_XML_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\xml\';

% generate output MAT files
GENERATE_OUTPUT_MAT_FLAG = 1;

% top directory of output MAT files
DIR_OUTPUT_MAT_FILES = 'C:\Users\jprannou\_DATA\ONE_ARGO_BGC\OUT\';

% CONFIGURATION - END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% process a reduced number of input S-PROF files (set to -1 to process all the files)
global g_cogeoab_nbFilesToProcess;
g_cogeoab_nbFilesToProcess = -1;

% program version
global g_cogeoab_generateEasyOneArgoBgcVersion;
g_cogeoab_generateEasyOneArgoBgcVersion = '0.1';

% berbose mode (for additionnal information on ignored data)
global g_cogeoab_verboseMode;
g_cogeoab_verboseMode = 0;

% minimum number of profiles in memory before creating associated CSV files
global g_cogeoab_minNbProfBeforeSaving;
g_cogeoab_minNbProfBeforeSaving = 5000;

% number of profiles in memory to allocate
global g_cogeoab_nbProfToAllocate;
g_cogeoab_nbProfToAllocate = 5000;

% input parameters
global g_cogeoab_dirInputNcFiles;
global g_cogeoab_inputDataDoi;
global g_cogeoab_dirOutputCsvFiles;
global g_cogeoab_dirLogFile;
global g_cogeoab_dirOutputXmlFile;
global g_cogeoab_xmlReportFileName;
global g_cogeoab_logFilePathName;
global g_cogeoab_generateOutputMatFlag;
global g_cogeoab_dirOutputMatFiles;

% store DAC name from input directories
global g_cogeoab_dacName;
g_cogeoab_dacName = '';

global g_cogeoab_janFirst1950InMatlab;
g_cogeoab_janFirst1950InMatlab = datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');

% DOM node of XML report
global g_cogeoab_xmlReportDOMNode;

% XML report information structure
global g_cogeoab_reportXmlData;
g_cogeoab_reportXmlData = [];

% date of the run
global g_cogeoab_nowUtc;
g_cogeoab_nowUtc = now_utc;
global g_cogeoab_nowUtcStr;
g_cogeoab_nowUtcStr = datestr(g_cogeoab_nowUtc, 'yyyy-mm-ddTHH:MM:SSZ');

% number to create a unique Id for temporary output MAT file names
global g_cogeoab_tempoOutPutMatId;
g_cogeoab_tempoOutPutMatId = 1;


logFileName = [];
status = 'nok';
% try

% startTime
ticStartTime = tic;

% store the start time of the run
currentTime = datestr(g_cogeoab_nowUtc, 'yyyymmddTHHMMSSZ');

% init the XML report
init_xml_report(currentTime);

% get input parameters
[inputError] = parse_input_param(varargin);

if (inputError == 0)

   % set parameter default values
   if (isempty(g_cogeoab_dirInputNcFiles))
      g_cogeoab_dirInputNcFiles = DIR_INPUT_NC_FILES;
   end
   if (isempty(g_cogeoab_inputDataDoi))
      g_cogeoab_inputDataDoi = INPUT_DATA_DOI;
   end
   if (isempty(g_cogeoab_dirOutputCsvFiles))
      g_cogeoab_dirOutputCsvFiles = DIR_OUTPUT_CSV_FILES;
   end
   if (isempty(g_cogeoab_dirLogFile))
      g_cogeoab_dirLogFile = DIR_LOG_FILE;
   end
   if (isempty(g_cogeoab_dirOutputXmlFile))
      g_cogeoab_dirOutputXmlFile = DIR_XML_FILE;
   end
   if (isempty(g_cogeoab_generateOutputMatFlag))
      g_cogeoab_generateOutputMatFlag = GENERATE_OUTPUT_MAT_FLAG;
   end
   if (isempty(g_cogeoab_dirOutputMatFiles))
      g_cogeoab_dirOutputMatFiles = DIR_OUTPUT_MAT_FILES;
   end

   % log file creation
   if (~isempty(g_cogeoab_xmlReportFileName))
      logFileName = [g_cogeoab_dirLogFile '/generate_easy_one_argo_bgc_' g_cogeoab_xmlReportFileName(10:end-4) '.log'];
   else
      logFileName = [g_cogeoab_dirLogFile '/generate_easy_one_argo_bgc_' currentTime '.log'];
   end

   g_cogeoab_logFilePathName = logFileName;

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % process the files according to input and configuration parameters
   generate_easy_one_argo_bgc_;

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % finalize XML report
   [status] = finalize_xml_report(ticStartTime, logFileName, []);

else
   g_cogeoab_dirOutputXmlFile = DIR_XML_FILE;
end

% catch
%
%    diary off;
%
%    % finalize XML report
%    [status] = finalize_xml_report(ticStartTime, logFileName, lasterror);
%
% end

% create the XML report path file name
if (~isempty(g_cogeoab_xmlReportFileName))
   xmlFileName = [g_cogeoab_dirOutputXmlFile '/' g_cogeoab_xmlReportFileName];
else
   xmlFileName = [g_cogeoab_dirOutputXmlFile '/co05081602_' currentTime '.xml']; % TBD
end

% save the XML report
xmlwrite(xmlFileName, g_cogeoab_xmlReportDOMNode);
% if (strcmp(status, 'nok') == 1)
%    edit(xmlFileName);
% end

return

% ------------------------------------------------------------------------------
% Generate Easy OneArgo BGC data sets
% (EasyOneArgoDOXY, EasyOneArgoNITRATE, EasyOneArgoPH, EasyOneArgoRADIOMETRY,
% EasyOneArgoCHLA_BBP and EasyOneArgoBGCLite).
%
% SYNTAX :
%    generate_easy_one_argo_bgc_
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function generate_easy_one_argo_bgc_

% input parameters
global g_cogeoab_dirInputNcFiles;
global g_cogeoab_inputDataDoi;
global g_cogeoab_dirOutputCsvFiles;
global g_cogeoab_dirLogFile;
global g_cogeoab_dirOutputXmlFile;
global g_cogeoab_logFilePathName;
global g_cogeoab_generateOutputMatFlag;
global g_cogeoab_dirOutputMatFiles;

% output directories
global g_cogeoab_dirOutputCsvFileDoxy;
global g_cogeoab_dirOutputCsvFileDoxyData;
global g_cogeoab_dirOutputCsvFileNitrate;
global g_cogeoab_dirOutputCsvFileNitrateData;
global g_cogeoab_dirOutputCsvFilePh;
global g_cogeoab_dirOutputCsvFilePhData;
global g_cogeoab_dirOutputCsvFileRadiometry;
global g_cogeoab_dirOutputCsvFileRadiometryData;
global g_cogeoab_dirOutputCsvFileChlaBbp;
global g_cogeoab_dirOutputCsvFileChlaBbpData;
global g_cogeoab_dirOutputCsvFileBgcLite;
global g_cogeoab_dirOutputCsvFileBgcLiteData;
global g_cogeoab_dirOutputMatFile;

% index files
global g_cogeoab_indexFileDoxy;
global g_cogeoab_indexFileNitrate;
global g_cogeoab_indexFilePh;
global g_cogeoab_indexFileRadiometry;
global g_cogeoab_indexFileChlaBbp;
global g_cogeoab_indexFileBgcLite;

% user report files
global g_cogeoab_reportFileDoxy;
global g_cogeoab_reportFileNitrate;
global g_cogeoab_reportFilePh;
global g_cogeoab_reportFileRadiometry;
global g_cogeoab_reportFileChlaBbp;
global g_cogeoab_reportFileBgcLite;

% time of the processed dataset
global g_cogeoab_nowUtc;

% process a reduced number of input S-PROF files
global g_cogeoab_nbFilesToProcess;

% array of processed data
global g_cogeoab_profTab;
global g_cogeoab_profLiteTab;
g_cogeoab_profTab = [];
g_cogeoab_profLiteTab = [];

% index in array of processed data
global g_cogeoab_profTabId;
global g_cogeoab_profLiteTabId;
g_cogeoab_profTabId = 1;
g_cogeoab_profLiteTabId = 1;

% minimum number of profiles in memory before creating associated CSV files
global g_cogeoab_minNbProfBeforeSaving;

% number of input files processed
global g_cogeoab_nbInputFiles;
g_cogeoab_nbInputFiles = 0;

% number of input profiles processed
global g_cogeoab_nbInputProfiles;
g_cogeoab_nbInputProfiles = 0;

% number of output files generated
global g_cogeoab_nbOutputFilesDoxy;
global g_cogeoab_nbOutputFilesNitrate;
global g_cogeoab_nbOutputFilesPh;
global g_cogeoab_nbOutputFilesRadiometry;
global g_cogeoab_nbOutputFilesChlaBbp;
global g_cogeoab_nbOutputFilesBgcLite;
global g_cogeoab_nbOutputFilesMat;
global g_cogeoab_nbOutputProfMatExpected;
global g_cogeoab_nbOutputProfMat;
g_cogeoab_nbOutputFilesDoxy = 0;
g_cogeoab_nbOutputFilesNitrate = 0;
g_cogeoab_nbOutputFilesPh = 0;
g_cogeoab_nbOutputFilesRadiometry = 0;
g_cogeoab_nbOutputFilesChlaBbp = 0;
g_cogeoab_nbOutputFilesBgcLite = 0;
g_cogeoab_nbOutputFilesMat = 0;
g_cogeoab_nbOutputProfMatExpected = 0;
g_cogeoab_nbOutputProfMat = 0;

% store DAC from input directories
global g_cogeoab_dacName;


diary(g_cogeoab_logFilePathName);
tic;

% print input parameter values in log file
fprintf('\nINPUT PARAMETERS:\n');
fprintf('DIR_INPUT_NC_FILES      : ''%s''\n', g_cogeoab_dirInputNcFiles);
fprintf('INPUT_DATA_DOI          : ''%s''\n', g_cogeoab_inputDataDoi);
fprintf('DIR_OUTPUT_CSV_FILES    : ''%s''\n', g_cogeoab_dirOutputCsvFiles);
fprintf('DIR_LOG_FILE            : ''%s''\n', g_cogeoab_dirLogFile);
fprintf('DIR_XML_FILE            : ''%s''\n', g_cogeoab_dirOutputXmlFile);
fprintf('GENERATE_OUTPUT_MAT_FLAG: %d\n', g_cogeoab_generateOutputMatFlag);
fprintf('DIR_OUTPUT_MAT_FILES    : ''%s''\n\n', g_cogeoab_dirOutputMatFiles);

% load interpolation reference data
load_bgc_levels_ref;

% create output directories
if ~(exist(g_cogeoab_dirOutputCsvFiles, 'dir') == 7)
   mkdir(g_cogeoab_dirOutputCsvFiles);
end
g_cogeoab_dirOutputCsvFileDoxy = [g_cogeoab_dirOutputCsvFiles '/EasyOneArgoDOXY_' datestr(g_cogeoab_nowUtc, 'yyyymmddTHHMMSSZ')];
if ~(exist(g_cogeoab_dirOutputCsvFileDoxy, 'dir') == 7)
   mkdir(g_cogeoab_dirOutputCsvFileDoxy);
end
g_cogeoab_dirOutputCsvFileDoxyData = [g_cogeoab_dirOutputCsvFileDoxy '/data'];
if ~(exist(g_cogeoab_dirOutputCsvFileDoxyData, 'dir') == 7)
   mkdir(g_cogeoab_dirOutputCsvFileDoxyData);
end
g_cogeoab_dirOutputCsvFileNitrate = [g_cogeoab_dirOutputCsvFiles '/EasyOneArgoNITRATE_' datestr(g_cogeoab_nowUtc, 'yyyymmddTHHMMSSZ')];
if ~(exist(g_cogeoab_dirOutputCsvFileNitrate, 'dir') == 7)
   mkdir(g_cogeoab_dirOutputCsvFileNitrate);
end
g_cogeoab_dirOutputCsvFileNitrateData = [g_cogeoab_dirOutputCsvFileNitrate '/data'];
if ~(exist(g_cogeoab_dirOutputCsvFileNitrateData, 'dir') == 7)
   mkdir(g_cogeoab_dirOutputCsvFileNitrateData);
end
g_cogeoab_dirOutputCsvFilePh = [g_cogeoab_dirOutputCsvFiles '/EasyOneArgoPH_' datestr(g_cogeoab_nowUtc, 'yyyymmddTHHMMSSZ')];
if ~(exist(g_cogeoab_dirOutputCsvFilePh, 'dir') == 7)
   mkdir(g_cogeoab_dirOutputCsvFilePh);
end
g_cogeoab_dirOutputCsvFilePhData = [g_cogeoab_dirOutputCsvFilePh '/data'];
if ~(exist(g_cogeoab_dirOutputCsvFilePhData, 'dir') == 7)
   mkdir(g_cogeoab_dirOutputCsvFilePhData);
end
g_cogeoab_dirOutputCsvFileRadiometry = [g_cogeoab_dirOutputCsvFiles '/EasyOneArgoRADIOMETRY_' datestr(g_cogeoab_nowUtc, 'yyyymmddTHHMMSSZ')];
if ~(exist(g_cogeoab_dirOutputCsvFileRadiometry, 'dir') == 7)
   mkdir(g_cogeoab_dirOutputCsvFileRadiometry);
end
g_cogeoab_dirOutputCsvFileRadiometryData = [g_cogeoab_dirOutputCsvFileRadiometry '/data'];
if ~(exist(g_cogeoab_dirOutputCsvFileRadiometryData, 'dir') == 7)
   mkdir(g_cogeoab_dirOutputCsvFileRadiometryData);
end
g_cogeoab_dirOutputCsvFileChlaBbp = [g_cogeoab_dirOutputCsvFiles '/EasyOneArgoCHLA_BBP_' datestr(g_cogeoab_nowUtc, 'yyyymmddTHHMMSSZ')];
if ~(exist(g_cogeoab_dirOutputCsvFileChlaBbp, 'dir') == 7)
   mkdir(g_cogeoab_dirOutputCsvFileChlaBbp);
end
g_cogeoab_dirOutputCsvFileChlaBbpData = [g_cogeoab_dirOutputCsvFileChlaBbp '/data'];
if ~(exist(g_cogeoab_dirOutputCsvFileChlaBbpData, 'dir') == 7)
   mkdir(g_cogeoab_dirOutputCsvFileChlaBbpData);
end
g_cogeoab_dirOutputCsvFileBgcLite = [g_cogeoab_dirOutputCsvFiles '/EasyOneArgoBGCLite_' datestr(g_cogeoab_nowUtc, 'yyyymmddTHHMMSSZ')];
if ~(exist(g_cogeoab_dirOutputCsvFileBgcLite, 'dir') == 7)
   mkdir(g_cogeoab_dirOutputCsvFileBgcLite);
end
g_cogeoab_dirOutputCsvFileBgcLiteData = [g_cogeoab_dirOutputCsvFileBgcLite '/data'];
if ~(exist(g_cogeoab_dirOutputCsvFileBgcLiteData, 'dir') == 7)
   mkdir(g_cogeoab_dirOutputCsvFileBgcLiteData);
end
if (g_cogeoab_generateOutputMatFlag)
   if ~(exist(g_cogeoab_dirOutputMatFiles, 'dir') == 7)
      mkdir(g_cogeoab_dirOutputMatFiles);
   end
   g_cogeoab_dirOutputMatFile = [g_cogeoab_dirOutputMatFiles '/EasyOneArgoBGCLite_audit_' datestr(g_cogeoab_nowUtc, 'yyyymmddTHHMMSSZ')];
   if ~(exist(g_cogeoab_dirOutputMatFile, 'dir') == 7)
      mkdir(g_cogeoab_dirOutputMatFile);
   end
end

% set index file names
g_cogeoab_indexFileDoxy = [g_cogeoab_dirOutputCsvFileDoxy '/EasyOneArgoDOXY_index.csv'];
g_cogeoab_indexFileNitrate = [g_cogeoab_dirOutputCsvFileNitrate '/EasyOneArgoNITRATE_index.csv'];
g_cogeoab_indexFilePh = [g_cogeoab_dirOutputCsvFilePh '/EasyOneArgoPH_index.csv'];
g_cogeoab_indexFileRadiometry = [g_cogeoab_dirOutputCsvFileRadiometry '/EasyOneArgoRADIOMETRY_index.csv'];
g_cogeoab_indexFileChlaBbp = [g_cogeoab_dirOutputCsvFileChlaBbp '/EasyOneArgoCHLA_BBP_index.csv'];
g_cogeoab_indexFileBgcLite = [g_cogeoab_dirOutputCsvFileBgcLite '/EasyOneArgoBGCLite_index.csv'];

% set report file names
g_cogeoab_reportFileDoxy = [g_cogeoab_dirOutputCsvFileDoxy '/EasyOneArgoDOXY_report.txt'];
g_cogeoab_reportFileNitrate = [g_cogeoab_dirOutputCsvFileNitrate '/EasyOneArgoNITRATE_report.txt'];
g_cogeoab_reportFilePh = [g_cogeoab_dirOutputCsvFilePh '/EasyOneArgoPH_report.txt'];
g_cogeoab_reportFileRadiometry = [g_cogeoab_dirOutputCsvFileRadiometry '/EasyOneArgoRADIOMETRY_report.txt'];
g_cogeoab_reportFileChlaBbp = [g_cogeoab_dirOutputCsvFileChlaBbp '/EasyOneArgoCHLA_BBP_report.txt'];
g_cogeoab_reportFileBgcLite = [g_cogeoab_dirOutputCsvFileBgcLite '/EasyOneArgoBGCLite_report.txt'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process input directory

% input are mono-cycle S profile files
stop = 0;
dirNames = dir(g_cogeoab_dirInputNcFiles);
for idDir = 1:length(dirNames)

   if (stop)
      break
   end

   dacName = dirNames(idDir).name;
   if (strcmp(dacName, '.') || strcmp(dacName, '..'))
      continue
   end

   % if (~strcmp(dacName, 'coriolis'))
   %    a=1
   %    continue
   % end

   fprintf('Processing DAC %s:\n', dacName);
   g_cogeoab_dacName = dacName;

   floatDirPath = [g_cogeoab_dirInputNcFiles '/' dacName '/'];
   floatDirNames = dir(floatDirPath);
   for idFDir = 1:length(floatDirNames)

      if (stop)
         break
      end

      floatDirName = floatDirNames(idFDir).name;
      if (strcmp(floatDirName, '.') || strcmp(floatDirName, '..'))
         continue
      end

      fprintf('%04d/%04d %s\n', idFDir-2, length(floatDirNames)-2, floatDirName);

      profFiles = dir([floatDirPath '/' floatDirName '/profiles/S*' floatDirName '*.nc']);
      for idFFile = 1:length(profFiles)

         profFilePathName = [floatDirPath '/' floatDirName '/profiles/' profFiles(idFFile).name];
         % fprintf('   %s\n', profFiles(idFFile).name);

         % process one file
         process_profile_s_file(profFilePathName);
         g_cogeoab_nbInputFiles = g_cogeoab_nbInputFiles + 1;

         if (g_cogeoab_profTabId > g_cogeoab_minNbProfBeforeSaving)
            % save the stored data in CSV files
            print_output_file;
         end

         if (g_cogeoab_nbInputFiles == g_cogeoab_nbFilesToProcess)
            stop = 1;
            break
         end
      end
   end
end

% save the remaining stored data in CSV files
print_output_file;

% concatenate output MAT files
concat_output_mat_files;

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Process one S file.
%
% SYNTAX :
% process_profile_s_file(a_profFilePathName)
%
% INPUT PARAMETERS :
%   a_profFilePathName : name of the file to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function process_profile_s_file(a_profFilePathName)

% array of processed data
global g_cogeoab_profTab;
global g_cogeoab_profLiteTab;

% index in array of processed data
global g_cogeoab_profTabId;
global g_cogeoab_profLiteTabId;

% number of profiles in memory to allocate
global g_cogeoab_nbProfToAllocate;

% number of output files generated
global g_cogeoab_nbOutputProfMatExpected;

% default values
global g_cogeoab_janFirst1950InMatlab;

% number of input profiles processed
global g_cogeoab_nbInputProfiles;

% input parameters
global g_cogeoab_generateOutputMatFlag;

global g_cogeoab_bgcLevels;

% store DAC from input directories
global g_cogeoab_dacName;

% fillValue of LATITUDE and LONGITUDE (not retreive from NetCDF file to speed up
% the process)
LAT_LON_FV = double(99999);

% fillValue of all concerned measurements (not retrieved from NetCDF file to speed up the
% process)
MEAS_FV = single(99999);


% retrieve data from profile file
wantedVars = [ ...
   {'PLATFORM_NUMBER'} ...
   {'PI_NAME'} ...
   {'STATION_PARAMETERS'} ...
   {'CYCLE_NUMBER'} ...
   {'DIRECTION'} ...
   {'DATA_CENTRE'} ...
   {'PARAMETER_DATA_MODE'} ...
   {'JULD'} ...
   {'JULD_QC'} ...
   {'JULD_LOCATION'} ...
   {'LATITUDE'} ...
   {'LONGITUDE'} ...
   {'POSITION_QC'} ...
   {'PRES_ADJUSTED'} ...
   {'PRES_ADJUSTED_QC'} ...
   {'PRES_ADJUSTED_ERROR'} ...
   {'TEMP_ADJUSTED'} ...
   {'TEMP_ADJUSTED_QC'} ...
   {'TEMP_ADJUSTED_ERROR'} ...
   {'PSAL_ADJUSTED'} ...
   {'PSAL_ADJUSTED_QC'} ...
   {'PSAL_ADJUSTED_ERROR'} ...
   {'DOXY_ADJUSTED'} ...
   {'DOXY_ADJUSTED_QC'} ...
   {'DOXY_ADJUSTED_ERROR'} ...
   {'NITRATE_ADJUSTED'} ...
   {'NITRATE_ADJUSTED_QC'} ...
   {'NITRATE_ADJUSTED_ERROR'} ...
   {'PH_IN_SITU_TOTAL_ADJUSTED'} ...
   {'PH_IN_SITU_TOTAL_ADJUSTED_QC'} ...
   {'PH_IN_SITU_TOTAL_ADJUSTED_ERROR'} ...
   {'DOWN_IRRADIANCE380_ADJUSTED'} ...
   {'DOWN_IRRADIANCE380_ADJUSTED_QC'} ...
   {'DOWN_IRRADIANCE380_ADJUSTED_ERROR'} ...
   {'DOWN_IRRADIANCE412_ADJUSTED'} ...
   {'DOWN_IRRADIANCE412_ADJUSTED_QC'} ...
   {'DOWN_IRRADIANCE412_ADJUSTED_ERROR'} ...
   {'DOWN_IRRADIANCE490_ADJUSTED'} ...
   {'DOWN_IRRADIANCE490_ADJUSTED_QC'} ...
   {'DOWN_IRRADIANCE490_ADJUSTED_ERROR'} ...
   {'DOWNWELLING_PAR_ADJUSTED'} ...
   {'DOWNWELLING_PAR_ADJUSTED_QC'} ...
   {'DOWNWELLING_PAR_ADJUSTED_ERROR'} ...
   {'CHLA_ADJUSTED'} ...
   {'CHLA_ADJUSTED_QC'} ...
   {'CHLA_ADJUSTED_ERROR'} ...
   {'BBP700_ADJUSTED'} ...
   {'BBP700_ADJUSTED_QC'} ...
   {'BBP700_ADJUSTED_ERROR'} ...
   ];

if (g_cogeoab_generateOutputMatFlag)
   wantedVars = [wantedVars ...
      {'PRES'} ...
      {'TEMP'} ...
      {'PSAL'} ...
      {'DOXY'} ...
      {'NITRATE'} ...
      {'PH_IN_SITU_TOTAL'} ...
      {'DOWN_IRRADIANCE380'} ...
      {'DOWN_IRRADIANCE412'} ...
      {'DOWN_IRRADIANCE490'} ...
      {'DOWNWELLING_PAR'} ...
      {'CHLA'} ...
      {'BBP700'} ...
      ];
end

[profData] = get_data_from_nc_file(a_profFilePathName, wantedVars);

juldQc = get_data_from_name('JULD_QC', profData);
latitude = get_data_from_name('LATITUDE', profData);
longitude = get_data_from_name('LONGITUDE', profData);
positionQc = get_data_from_name('POSITION_QC', profData);
g_cogeoab_nbInputProfiles = g_cogeoab_nbInputProfiles + length(juldQc);

% TEMP TO CHECK INPUT CONSISTENCY - START
% idF = strfind(a_profFilePathName, '/');
% newPath = [a_profFilePathName(1:idF(end)) '/profiles/'];
% if (length(juldQc) ~= length(dir([newPath 'S*.nc'])))
%    fprintf('ERROR: INCONSISTENT %d VS %d : %s\n', ...
%       length(juldQc), ...
%       length(dir([newPath 'S*.nc'])), ...
%       a_profFilePathName);
% end
% return
% TEMP TO CHECK INPUT CONSISTENCY - STOP

% select 'good' profiles
idGoList = find(((juldQc == '1') | (juldQc == '5') | (juldQc == '8')) & ...
   ((positionQc == '1') | (positionQc == '5') | (positionQc == '8')) & ...
   ~((latitude == LAT_LON_FV) | (longitude == LAT_LON_FV))); % AOML 4901542 #245A positionQc=8 and latitude=longitude=FV, Coriolis 6902829 #102A positionQc=1 and latitude=longitude=FV
if (~isempty(idGoList))

   platformNumber = get_data_from_name('PLATFORM_NUMBER', profData)';
   piName = get_data_from_name('PI_NAME', profData)';
   stationParameters = get_data_from_name('STATION_PARAMETERS', profData);
   cycleNumber = get_data_from_name('CYCLE_NUMBER', profData);
   direction = get_data_from_name('DIRECTION', profData);
   dataCenter = get_data_from_name('DATA_CENTRE', profData)';
   paramDataMode = get_data_from_name('PARAMETER_DATA_MODE', profData);
   juld = get_data_from_name('JULD', profData);
   presAdj = get_data_from_name('PRES_ADJUSTED', profData);
   presAdjQc = get_data_from_name('PRES_ADJUSTED_QC', profData);
   presAdjErr = get_data_from_name('PRES_ADJUSTED_ERROR', profData);
   tempAdj = get_data_from_name('TEMP_ADJUSTED', profData);
   tempAdjQc = get_data_from_name('TEMP_ADJUSTED_QC', profData);
   tempAdjErr = get_data_from_name('TEMP_ADJUSTED_ERROR', profData);
   psalAdj = get_data_from_name('PSAL_ADJUSTED', profData);
   psalAdjQc = get_data_from_name('PSAL_ADJUSTED_QC', profData);
   psalAdjErr = get_data_from_name('PSAL_ADJUSTED_ERROR', profData);
   doxyAdj = get_data_from_name('DOXY_ADJUSTED', profData);
   doxyAdjQc = get_data_from_name('DOXY_ADJUSTED_QC', profData);
   doxyAdjErr = get_data_from_name('DOXY_ADJUSTED_ERROR', profData);
   nitrateAdj = get_data_from_name('NITRATE_ADJUSTED', profData);
   nitrateAdjQc = get_data_from_name('NITRATE_ADJUSTED_QC', profData);
   nitrateAdjErr = get_data_from_name('NITRATE_ADJUSTED_ERROR', profData);
   phAdj = get_data_from_name('PH_IN_SITU_TOTAL_ADJUSTED', profData);
   phAdjQc = get_data_from_name('PH_IN_SITU_TOTAL_ADJUSTED_QC', profData);
   phAdjErr = get_data_from_name('PH_IN_SITU_TOTAL_ADJUSTED_ERROR', profData);
   downIrr380Adj = get_data_from_name('DOWN_IRRADIANCE380_ADJUSTED', profData);
   downIrr380AdjQc = get_data_from_name('DOWN_IRRADIANCE380_ADJUSTED_QC', profData);
   downIrr380AdjErr = get_data_from_name('DOWN_IRRADIANCE380_ADJUSTED_ERROR', profData);
   downIrr412Adj = get_data_from_name('DOWN_IRRADIANCE412_ADJUSTED', profData);
   downIrr412AdjQc = get_data_from_name('DOWN_IRRADIANCE412_ADJUSTED_QC', profData);
   downIrr412AdjErr = get_data_from_name('DOWN_IRRADIANCE412_ADJUSTED_ERROR', profData);
   downIrr490Adj = get_data_from_name('DOWN_IRRADIANCE490_ADJUSTED', profData);
   downIrr490AdjQc = get_data_from_name('DOWN_IRRADIANCE490_ADJUSTED_QC', profData);
   downIrr490AdjErr = get_data_from_name('DOWN_IRRADIANCE490_ADJUSTED_ERROR', profData);
   downwellingParAdj = get_data_from_name('DOWNWELLING_PAR_ADJUSTED', profData);
   downwellingParAdjQc = get_data_from_name('DOWNWELLING_PAR_ADJUSTED_QC', profData);
   downwellingParAdjErr = get_data_from_name('DOWNWELLING_PAR_ADJUSTED_ERROR', profData);
   chlaAdj = get_data_from_name('CHLA_ADJUSTED', profData);
   chlaAdjQc = get_data_from_name('CHLA_ADJUSTED_QC', profData);
   chlaAdjErr = get_data_from_name('CHLA_ADJUSTED_ERROR', profData);
   bbp700Adj = get_data_from_name('BBP700_ADJUSTED', profData);
   bbp700AdjQc = get_data_from_name('BBP700_ADJUSTED_QC', profData);
   bbp700AdjErr = get_data_from_name('BBP700_ADJUSTED_ERROR', profData);

   % if (isempty(downIrr380Adj) && isempty(downIrr412Adj) && isempty(downIrr490Adj) && isempty(downwellingParAdj))
   %    return
   % end
   % if (isempty(doxyAdj) || isempty(nitrateAdj) || isempty(phAdj))
   %    return
   % end
   % if (isempty(chlaAdj) && isempty(bbp700Adj))
   %    return
   % end
   % if (isempty(nitrateAdj))
   %    return
   % end
   % if (str2num(strtrim(platformNumber(1, :))) ~= 4902630)
   %    return
   % end

   % get the data mode of each parameter
   dataModePres = repmat(' ', length(juld), 1);
   dataModeTemp = repmat(' ', length(juld), 1);
   dataModePsal = repmat(' ', length(juld), 1);
   dataModeDoxy = repmat(' ', length(juld), 1);
   dataModeNitrate = repmat(' ', length(juld), 1);
   dataModePh = repmat(' ', length(juld), 1);
   dataModeDownIrr380 = repmat(' ', length(juld), 1);
   dataModeDownIrr412 = repmat(' ', length(juld), 1);
   dataModeDownIrr490 = repmat(' ', length(juld), 1);
   dataModeDownwellingPar = repmat(' ', length(juld), 1);
   dataModeChla = repmat(' ', length(juld), 1);
   dataModeBbp700 = repmat(' ', length(juld), 1);
   [~, nParam, ~] = size(stationParameters);
   for idParam = 1:nParam
      for idProf = idGoList'
         paramName = strtrim(stationParameters(:, idParam, idProf)');
         if (~isempty(paramName))
            switch (paramName)
               case 'PRES'
                  dataModePres(idProf) = paramDataMode(idParam, idProf);
               case 'TEMP'
                  dataModeTemp(idProf) = paramDataMode(idParam, idProf);
               case 'PSAL'
                  dataModePsal(idProf) = paramDataMode(idParam, idProf);
               case 'DOXY'
                  dataModeDoxy(idProf) = paramDataMode(idParam, idProf);
               case 'NITRATE'
                  dataModeNitrate(idProf) = paramDataMode(idParam, idProf);
               case 'PH_IN_SITU_TOTAL'
                  dataModePh(idProf) = paramDataMode(idParam, idProf);
               case 'DOWN_IRRADIANCE380'
                  dataModeDownIrr380(idProf) = paramDataMode(idParam, idProf);
               case 'DOWN_IRRADIANCE412'
                  dataModeDownIrr412(idProf) = paramDataMode(idParam, idProf);
               case 'DOWN_IRRADIANCE490'
                  dataModeDownIrr490(idProf) = paramDataMode(idParam, idProf);
               case 'DOWNWELLING_PAR'
                  dataModeDownwellingPar(idProf) = paramDataMode(idParam, idProf);
               case 'CHLA'
                  dataModeChla(idProf) = paramDataMode(idParam, idProf);
               case 'BBP700'
                  dataModeBbp700(idProf) = paramDataMode(idParam, idProf);
            end
         end
      end
   end

   for idP = idGoList' % one loop for each S profile

      paramDataModeAll = [ ...
         dataModePres(idP), dataModeTemp(idP), dataModePsal(idP), ...
         dataModeDoxy(idP), dataModeNitrate(idP), dataModePh(idP), ...
         dataModeDownIrr380(idP), dataModeDownIrr412(idP), ...
         dataModeDownIrr490(idP), dataModeDownwellingPar(idP), ...
         dataModeChla(idP), dataModeBbp700(idP)];

      % P, T, and S in 'A' or 'D' and
      % at least one BGC parameter in 'A' or 'D'
      if (~all(ismember(paramDataModeAll(1:3), 'AD')) || ~any(ismember(paramDataModeAll(4:end), 'AD')))
         continue
      end

      % get the ADJUSTED PTS measurements for the current profile
      presBest = presAdj(:, idP);
      presBestQc = presAdjQc(:, idP);
      presBestErr = presAdjErr(:, idP);
      defaultData = ones(size(presBest))*MEAS_FV;
      defaultDataQc = repmat(' ', size(presBest));
      if (ismember(dataModeTemp(idP), 'AD'))
         tempBest = tempAdj(:, idP);
         tempBestQc = tempAdjQc(:, idP);
         tempBestErr = tempAdjErr(:, idP);
      else
         tempBest = defaultData;
         tempBestQc = defaultDataQc;
         tempBestErr = defaultData;
      end
      if (ismember(dataModePsal(idP), 'AD'))
         psalBest = psalAdj(:, idP);
         psalBestQc = psalAdjQc(:, idP);
         psalBestErr = psalAdjErr(:, idP);
      else
         psalBest = defaultData;
         psalBestQc = defaultDataQc;
         psalBestErr = defaultData;
      end

      % get the BGC ADJUSTED measurements for the current profile
      if (ismember(dataModeDoxy(idP), 'AD'))
         doxyBest = doxyAdj(:, idP);
         doxyBestQc = doxyAdjQc(:, idP);
         doxyBestErr = doxyAdjErr(:, idP);
      else
         doxyBest = defaultData;
         doxyBestQc = defaultDataQc;
         doxyBestErr = defaultData;
      end
      if (ismember(dataModeNitrate(idP), 'AD'))
         nitrateBest = nitrateAdj(:, idP);
         nitrateBestQc = nitrateAdjQc(:, idP);
         nitrateBestErr = nitrateAdjErr(:, idP);
      else
         nitrateBest = defaultData;
         nitrateBestQc = defaultDataQc;
         nitrateBestErr = defaultData;
      end
      if (ismember(dataModePh(idP), 'AD'))
         phBest = phAdj(:, idP);
         phBestQc = phAdjQc(:, idP);
         phBestErr = phAdjErr(:, idP);
      else
         phBest = defaultData;
         phBestQc = defaultDataQc;
         phBestErr = defaultData;
      end
      if (ismember(dataModeDownIrr380(idP), 'AD'))
         downIrr380Best = downIrr380Adj(:, idP);
         downIrr380BestQc = downIrr380AdjQc(:, idP);
         downIrr380BestErr = downIrr380AdjErr(:, idP);
      else
         downIrr380Best = defaultData;
         downIrr380BestQc = defaultDataQc;
         downIrr380BestErr = defaultData;
      end
      if (ismember(dataModeDownIrr412(idP), 'AD'))
         downIrr412Best = downIrr412Adj(:, idP);
         downIrr412BestQc = downIrr412AdjQc(:, idP);
         downIrr412BestErr = downIrr412AdjErr(:, idP);
      else
         downIrr412Best = defaultData;
         downIrr412BestQc = defaultDataQc;
         downIrr412BestErr = defaultData;
      end
      if (ismember(dataModeDownIrr490(idP), 'AD'))
         downIrr490Best = downIrr490Adj(:, idP);
         downIrr490BestQc = downIrr490AdjQc(:, idP);
         downIrr490BestErr = downIrr490AdjErr(:, idP);
      else
         downIrr490Best = defaultData;
         downIrr490BestQc = defaultDataQc;
         downIrr490BestErr = defaultData;
      end
      if (ismember(dataModeDownwellingPar(idP), 'AD'))
         downwellingParBest = downwellingParAdj(:, idP);
         downwellingParBestQc = downwellingParAdjQc(:, idP);
         downwellingParBestErr = downwellingParAdjErr(:, idP);
      else
         downwellingParBest = defaultData;
         downwellingParBestQc = defaultDataQc;
         downwellingParBestErr = defaultData;
      end
      if (ismember(dataModeChla(idP), 'AD'))
         chlaBest = chlaAdj(:, idP);
         chlaBestQc = chlaAdjQc(:, idP);
         chlaBestErr = chlaAdjErr(:, idP);
      else
         chlaBest = defaultData;
         chlaBestQc = defaultDataQc;
         chlaBestErr = defaultData;
      end
      if (ismember(dataModeBbp700(idP), 'AD'))
         bbp700Best = bbp700Adj(:, idP);
         bbp700BestQc = bbp700AdjQc(:, idP);
         bbp700BestErr = bbp700AdjErr(:, idP);
      else
         bbp700Best = defaultData;
         bbp700BestQc = defaultDataQc;
         bbp700BestErr = defaultData;
      end

      rawData = [ ...
         presBest, tempBest, psalBest, ...
         doxyBest, nitrateBest, phBest, ...
         downIrr380Best, downIrr412Best, ...
         downIrr490Best, downwellingParBest, ...
         chlaBest, bbp700Best];
      rawDataQc = [ ...
         presBestQc, tempBestQc, psalBestQc, ...
         doxyBestQc, nitrateBestQc, phBestQc, ...
         downIrr380BestQc, downIrr412BestQc, ...
         downIrr490BestQc, downwellingParBestQc, ...
         chlaBestQc, bbp700BestQc];
      rawDataErr = [ ...
         presBestErr, tempBestErr, psalBestErr, ...
         doxyBestErr, nitrateBestErr, phBestErr, ...
         downIrr380BestErr, downIrr412BestErr, ...
         downIrr490BestErr, downwellingParBestErr, ...
         chlaBestErr, bbp700BestErr];

      if (g_cogeoab_generateOutputMatFlag)
         pres = get_data_from_name('PRES', profData);
         temp = get_data_from_name('TEMP', profData);
         if (isempty(temp))
            temp = defaultData;
         end
         psal = get_data_from_name('PSAL', profData);
         if (isempty(psal))
            psal = defaultData;
         end
         doxy = get_data_from_name('DOXY', profData);
         if (isempty(doxy))
            doxy = defaultData;
         end
         nitrate = get_data_from_name('NITRATE', profData);
         if (isempty(nitrate))
            nitrate = defaultData;
         end
         ph = get_data_from_name('PH_IN_SITU_TOTAL', profData);
         if (isempty(ph))
            ph = defaultData;
         end
         downIrr380 = get_data_from_name('DOWN_IRRADIANCE380', profData);
         if (isempty(downIrr380))
            downIrr380 = defaultData;
         end
         downIrr412 = get_data_from_name('DOWN_IRRADIANCE412', profData);
         if (isempty(downIrr412))
            downIrr412 = defaultData;
         end
         downIrr490 = get_data_from_name('DOWN_IRRADIANCE490', profData);
         if (isempty(downIrr490))
            downIrr490 = defaultData;
         end
         downwellingPar = get_data_from_name('DOWNWELLING_PAR', profData);
         if (isempty(downwellingPar))
            downwellingPar = defaultData;
         end
         chla = get_data_from_name('CHLA', profData);
         if (isempty(chla))
            chla = defaultData;
         end
         bbp700 = get_data_from_name('BBP700', profData);
         if (isempty(bbp700))
            bbp700 = defaultData;
         end

         matRawDataO = [ ...
            pres, temp, psal, ...
            doxy, nitrate, ph, ...
            downIrr380, downIrr412, ...
            downIrr490, downwellingPar, ...
            chla, bbp700];
         matRawData = rawData;
         matRawDataQc = rawDataQc;
      end

      for loopNumber = 1:5 % one loop for each BGC dataset

         switch (loopNumber)
            case 1
               parameterList = [{'PRES'} {'TEMP'} {'PSAL'} {'DOXY'}];
               paramDataMode = [dataModePres(idP), dataModeTemp(idP), dataModePsal(idP), dataModeDoxy(idP)];
               % be sure that all parameters are present (i.e. data mode ~= ' ')
               % and keep only measurements with data mode = 'A' or 'D'
               if (any(ismember(paramDataMode,  ' R')))
                  continue
               end

               % concatenate data and remove padding levels
               data = [presBest, tempBest, psalBest, doxyBest];
               dataErr = [presBestErr, tempBestErr, psalBestErr, doxyBestErr];

               presBestQc(presBestQc == ' ') = '7'; % QC='7' not used in Argo
               tempBestQc(tempBestQc == ' ') = '7'; % QC='7' not used in Argo
               psalBestQc(psalBestQc == ' ') = '7'; % QC='7' not used in Argo
               doxyBestQc(doxyBestQc == ' ') = '7'; % QC='7' not used in Argo
               dataQc = [str2num(presBestQc), str2num(tempBestQc), str2num(psalBestQc), str2num(doxyBestQc)];
               idDel = find(sum(dataQc == 7, 2) == length(parameterList)); % padding levels

               data(idDel, :) = [];
               dataErr(idDel, :) = [];
               dataQc(idDel, :) = [];
               data(data == MEAS_FV) = nan;
               dataErr(dataErr == MEAS_FV) = nan;

               % keep only Qc = '1', '2' or '8' for PTS data
               % keep only Qc = '1' for BGC data
               data(((dataQc(:, 1) ~= 1) & (dataQc(:, 1) ~= 2) & (dataQc(:, 1) ~= 8)), 1) = nan;
               data(((dataQc(:, 2) ~= 1) & (dataQc(:, 2) ~= 2) & (dataQc(:, 2) ~= 8)), 2) = nan;
               data(((dataQc(:, 3) ~= 1) & (dataQc(:, 3) ~= 2) & (dataQc(:, 3) ~= 8)), 3) = nan;
               data((dataQc(:, 4) ~= 1), 4) = nan;
               % keep only levels where all measurements are provided
               idDel = find(any(isnan(data), 2));

               data(idDel, :) = [];
               dataErr(idDel, :) = [];

            case 2
               parameterList = [{'PRES'} {'TEMP'} {'PSAL'} {'NITRATE'}];
               paramDataMode = [dataModePres(idP), dataModeTemp(idP), dataModePsal(idP), dataModeNitrate(idP)];
               % be sure that all parameters are present (i.e. data mode ~= ' ')
               % and keep only measurements with data mode = 'A' or 'D'
               if (any(ismember(paramDataMode,  ' R')))
                  continue
               end

               % concatenate data and remove padding levels
               data = [presBest, tempBest, psalBest, nitrateBest];
               dataErr = [presBestErr, tempBestErr, psalBestErr, nitrateBestErr];

               presBestQc(presBestQc == ' ') = '7'; % QC='7' not used in Argo
               tempBestQc(tempBestQc == ' ') = '7'; % QC='7' not used in Argo
               psalBestQc(psalBestQc == ' ') = '7'; % QC='7' not used in Argo
               nitrateBestQc(nitrateBestQc == ' ') = '7'; % QC='7' not used in Argo
               dataQc = [str2num(presBestQc), str2num(tempBestQc), str2num(psalBestQc), str2num(nitrateBestQc)];
               idDel = find(sum(dataQc == 7, 2) == length(parameterList)); % padding levels

               data(idDel, :) = [];
               dataErr(idDel, :) = [];
               dataQc(idDel, :) = [];
               data(data == MEAS_FV) = nan;
               dataErr(dataErr == MEAS_FV) = nan;

               % keep only Qc = '1', '2' or '8' for PTS data
               % keep only Qc = '1' for BGC data
               data(((dataQc(:, 1) ~= 1) & (dataQc(:, 1) ~= 2) & (dataQc(:, 1) ~= 8)), 1) = nan;
               data(((dataQc(:, 2) ~= 1) & (dataQc(:, 2) ~= 2) & (dataQc(:, 2) ~= 8)), 2) = nan;
               data(((dataQc(:, 3) ~= 1) & (dataQc(:, 3) ~= 2) & (dataQc(:, 3) ~= 8)), 3) = nan;
               data((dataQc(:, 4) ~= 1), 4) = nan;
               dataErr(isnan(data)) = nan;
               % keep only levels where all measurements are provided
               idDel = find(any(isnan(data), 2));

               data(idDel, :) = [];
               dataErr(idDel, :) = [];

            case 3
               parameterList = [{'PRES'} {'TEMP'} {'PSAL'} {'PH_IN_SITU_TOTAL'}];
               paramDataMode = [dataModePres(idP), dataModeTemp(idP), dataModePsal(idP), dataModePh(idP)];
               % be sure that all parameters are present (i.e. data mode ~= ' ')
               % and keep only measurements with data mode = 'A' or 'D'
               if (any(ismember(paramDataMode,  ' R')))
                  continue
               end

               % concatenate data and remove padding levels
               data = [presBest, tempBest, psalBest, phBest];
               dataErr = [presBestErr, tempBestErr, psalBestErr, phBestErr];

               presBestQc(presBestQc == ' ') = '7'; % QC='7' not used in Argo
               tempBestQc(tempBestQc == ' ') = '7'; % QC='7' not used in Argo
               psalBestQc(psalBestQc == ' ') = '7'; % QC='7' not used in Argo
               phBestQc(phBestQc == ' ') = '7'; % QC='7' not used in Argo
               dataQc = [str2num(presBestQc), str2num(tempBestQc), str2num(psalBestQc), str2num(phBestQc)];
               idDel = find(sum(dataQc == 7, 2) == length(parameterList)); % padding levels

               data(idDel, :) = [];
               dataErr(idDel, :) = [];
               dataQc(idDel, :) = [];
               data(data == MEAS_FV) = nan;
               dataErr(dataErr == MEAS_FV) = nan;

               % keep only Qc = '1', '2' or '8' for PTS data
               % keep only Qc = '1' for BGC data
               data(((dataQc(:, 1) ~= 1) & (dataQc(:, 1) ~= 2) & (dataQc(:, 1) ~= 8)), 1) = nan;
               data(((dataQc(:, 2) ~= 1) & (dataQc(:, 2) ~= 2) & (dataQc(:, 2) ~= 8)), 2) = nan;
               data(((dataQc(:, 3) ~= 1) & (dataQc(:, 3) ~= 2) & (dataQc(:, 3) ~= 8)), 3) = nan;
               data((dataQc(:, 4) ~= 1), 4) = nan;
               dataErr(isnan(data)) = nan;
               % keep only levels where all measurements are provided
               idDel = find(any(isnan(data), 2));

               data(idDel, :) = [];
               dataErr(idDel, :) = [];

            case 4
               parameterList = [{'PRES'} {'TEMP'} {'PSAL'} ...
                  {'DOWN_IRRADIANCE380'} {'DOWN_IRRADIANCE412'} {'DOWN_IRRADIANCE490'} {'DOWNWELLING_PAR'}];
               paramDataMode = [dataModePres(idP), dataModeTemp(idP), dataModePsal(idP), ...
                  dataModeDownIrr380(idP), dataModeDownIrr412(idP), dataModeDownIrr490(idP), dataModeDownwellingPar(idP)];
               % be sure that all parameters are present (i.e. data mode ~= ' ')
               % and keep only measurements with data mode = 'A' or 'D'
               paramDataModeCtd = [dataModePres(idP), dataModeTemp(idP), dataModePsal(idP)];
               if (any(ismember(paramDataModeCtd,  ' R')))
                  continue
               end
               paramDataModeRadiometry = [dataModeDownIrr380(idP), dataModeDownIrr412(idP), ...
                  dataModeDownIrr490(idP), dataModeDownwellingPar(idP)];
               if (all(ismember(upper(paramDataModeRadiometry),  ' R')))
                  continue
               end

               % concatenate data and remove padding levels
               data = [presBest, tempBest, psalBest, ...
                  downIrr380Best, downIrr412Best, downIrr490Best, downwellingParBest];
               dataErr = [presBestErr, tempBestErr, psalBestErr, ...
                  downIrr380BestErr, downIrr412BestErr, downIrr490BestErr, downwellingParBestErr];

               presBestQc(presBestQc == ' ') = '7'; % QC='7' not used in Argo
               tempBestQc(tempBestQc == ' ') = '7'; % QC='7' not used in Argo
               psalBestQc(psalBestQc == ' ') = '7'; % QC='7' not used in Argo
               downIrr380BestQc(downIrr380BestQc == ' ') = '7'; % QC='7' not used in Argo
               downIrr412BestQc(downIrr412BestQc == ' ') = '7'; % QC='7' not used in Argo
               downIrr490BestQc(downIrr490BestQc == ' ') = '7'; % QC='7' not used in Argo
               downwellingParBestQc(downwellingParBestQc == ' ') = '7'; % QC='7' not used in Argo
               dataQc = [str2num(presBestQc), str2num(tempBestQc), str2num(psalBestQc), ...
                  str2num(downIrr380BestQc), str2num(downIrr412BestQc), ...
                  str2num(downIrr490BestQc), str2num(downwellingParBestQc)];
               idDel = find(sum(dataQc == 7, 2) == length(parameterList)); % padding levels

               data(idDel, :) = [];
               dataErr(idDel, :) = [];
               dataQc(idDel, :) = [];
               data(data == MEAS_FV) = nan;
               dataErr(dataErr == MEAS_FV) = nan;

               % keep only Qc = '1', '2' or '8' for PTS data
               % keep only Qc = '1' for BGC data
               data(((dataQc(:, 1) ~= 1) & (dataQc(:, 1) ~= 2) & (dataQc(:, 1) ~= 8)), 1) = nan;
               data(((dataQc(:, 2) ~= 1) & (dataQc(:, 2) ~= 2) & (dataQc(:, 2) ~= 8)), 2) = nan;
               data(((dataQc(:, 3) ~= 1) & (dataQc(:, 3) ~= 2) & (dataQc(:, 3) ~= 8)), 3) = nan;
               data((dataQc(:, 4) ~= 1), 4) = nan;
               data((dataQc(:, 5) ~= 1), 5) = nan;
               data((dataQc(:, 6) ~= 1), 6) = nan;
               data((dataQc(:, 7) ~= 1), 7) = nan;
               dataErr(isnan(data)) = nan;
               % keep only levels where all PTS and at least one BGC measurements are provided
               idDel1 = find(any(isnan(data(:, 1:3)), 2)); % for PTS
               idDel2 = find(sum(isnan(data(:, 4:end)), 2) == 4); % for BGC
               idDel = unique([idDel1; idDel2]);

               data(idDel, :) = [];
               dataErr(idDel, :) = [];

            case 5
               parameterList = [{'PRES'} {'TEMP'} {'PSAL'} {'CHLA'} {'BBP700'}];
               paramDataMode = [dataModePres(idP), dataModeTemp(idP), dataModePsal(idP), ...
                  dataModeChla(idP), dataModeBbp700(idP)];
               % be sure that all parameters are present (i.e. data mode ~= ' ')
               % and keep only measurements with data mode = 'A' or 'D'
               paramDataModeCtd = [dataModePres(idP), dataModeTemp(idP), dataModePsal(idP)];
               if (any(ismember(paramDataModeCtd,  ' R')))
                  continue
               end
               paramDataModeChlaBbp = [dataModeChla(idP), dataModeBbp700(idP)];
               if (all(ismember(paramDataModeChlaBbp,  ' R')))
                  continue
               end

               % concatenate data and remove padding levels
               data = [presBest, tempBest, psalBest, ...
                  chlaBest, bbp700Best];
               dataErr = [presBestErr, tempBestErr, psalBestErr, ...
                  chlaBestErr, bbp700BestErr];

               presBestQc(presBestQc == ' ') = '7'; % QC='7' not used in Argo
               tempBestQc(tempBestQc == ' ') = '7'; % QC='7' not used in Argo
               psalBestQc(psalBestQc == ' ') = '7'; % QC='7' not used in Argo
               chlaBestQc(chlaBestQc == ' ') = '7'; % QC='7' not used in Argo
               bbp700BestQc(bbp700BestQc == ' ') = '7'; % QC='7' not used in Argo
               dataQc = [ ...
                  str2num(presBestQc), str2num(tempBestQc), str2num(psalBestQc), ...
                  str2num(chlaBestQc), str2num(bbp700BestQc)];
               idDel = find(sum(dataQc == 7, 2) == length(parameterList)); % padding levels

               data(idDel, :) = [];
               dataErr(idDel, :) = [];
               dataQc(idDel, :) = [];
               data(data == MEAS_FV) = nan;
               dataErr(dataErr == MEAS_FV) = nan;

               % keep only Qc = '1', '2' or '8' for PTS data
               % keep only Qc = '1' or '5' for BGC data
               data(((dataQc(:, 1) ~= 1) & (dataQc(:, 1) ~= 2) & (dataQc(:, 1) ~= 8)), 1) = nan;
               data(((dataQc(:, 2) ~= 1) & (dataQc(:, 2) ~= 2) & (dataQc(:, 2) ~= 8)), 2) = nan;
               data(((dataQc(:, 3) ~= 1) & (dataQc(:, 3) ~= 2) & (dataQc(:, 3) ~= 8)), 3) = nan;
               data(((dataQc(:, 4) ~= 1) & (dataQc(:, 4) ~= 5)), 4) = nan;
               data(((dataQc(:, 5) ~= 1) & (dataQc(:, 5) ~= 5)), 5) = nan;
               dataErr(isnan(data)) = nan;
               % keep only levels where all PTS and at least one BGC measurements are provided
               idDel1 = find(any(isnan(data(:, 1:3)), 2));
               idDel2 = find(sum(isnan(data(:, 4:end)), 2) == 2); % for BGC
               idDel = unique([idDel1; idDel2]);

               data(idDel, :) = [];
               dataErr(idDel, :) = [];
         end

         if (~isempty(data))

            profStruct = get_prof_data_init_struct;
            profStruct.loopNumber = loopNumber;
            profStruct.wmo = num2str(str2double(strtrim(platformNumber(idP, :)))); % issue whith AOML/1901501
            profStruct.dac = dataCenter(idP, :);
            profStruct.cyNum = cycleNumber(idP);
            profStruct.cyNumStr = num2str(cycleNumber(idP));
            profStruct.dir = upper(direction(idP));
            profStruct.parameterList = parameterList;
            profStruct.paramDataMode = paramDataMode;
            profStruct.juld = juld(idP);
            profStruct.juldStr = datestr(juld(idP)+g_cogeoab_janFirst1950InMatlab, 'yyyy-mm-ddTHH:MM:SSZ');
            profStruct.lat = latitude(idP);
            profStruct.latStr = sprintf('%.3f', latitude(idP));
            profStruct.lon = longitude(idP);
            profStruct.lonStr = sprintf('%.3f', longitude(idP));
            profStruct.data = data;
            profStruct.dataErr = dataErr;

            % store output profile information

            if (isempty(g_cogeoab_profTab) || (g_cogeoab_profTabId > length(g_cogeoab_profTab)))
               g_cogeoab_profTab = cat(2, g_cogeoab_profTab, ...
                  repmat(get_prof_data_init_struct, 1, g_cogeoab_nbProfToAllocate));
            end

            g_cogeoab_profTab(g_cogeoab_profTabId) = profStruct;
            g_cogeoab_profTabId = g_cogeoab_profTabId + 1;
         end
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % process raw data for the EasyOneArgoBGCLite

      % remove padding levels
      rawDataQc(rawDataQc == ' ') =  '7'; % QC='7' not used in Argo
      rawDataQc = [str2num(rawDataQc(:, 1)), str2num(rawDataQc(:, 2)), ...
         str2num(rawDataQc(:, 3)), str2num(rawDataQc(:, 4)), ...
         str2num(rawDataQc(:, 5)), str2num(rawDataQc(:, 6)), ...
         str2num(rawDataQc(:, 7)), str2num(rawDataQc(:, 8)), ...
         str2num(rawDataQc(:, 9)), str2num(rawDataQc(:, 10)), ...
         str2num(rawDataQc(:, 11)), str2num(rawDataQc(:, 12))];
      idDel = find(sum(rawDataQc == 7, 2) == size(rawDataQc, 2)); % padding levels
      rawData(idDel, :) = [];
      rawDataQc(idDel, :) = [];
      rawDataErr(idDel, :) = [];
      if (g_cogeoab_generateOutputMatFlag)
         matRawDataO(idDel, :) = [];
         matRawData(idDel, :) = [];
         matRawDataQc(idDel, :) = [];
      end

      if (~isempty(rawData))

         rawData(rawData == MEAS_FV) = nan;
         rawDataErr(rawDataErr == MEAS_FV) = nan;
         if (g_cogeoab_generateOutputMatFlag)
            matRawDataO(matRawDataO == MEAS_FV) = nan;
            matRawData(matRawData == MEAS_FV) = nan;
         end

         % apply QC criteria on each parameter individually
         for idParam = 1:12
            if (idParam <= 10)
               rawData((rawDataQc(:, idParam) ~= 1), idParam) = nan;
            else
               rawData(((rawDataQc(:, idParam) ~= 1) & (rawDataQc(:, idParam) ~= 5)), idParam) = nan;
            end
         end

         % P, T and S should be present
         % don't set P to nan because it can be used by one BGC parameter
         rawData(any(isnan(rawData(:, 1:3)), 2), 2) = nan;
         rawData(any(isnan(rawData(:, 1:3)), 2), 3) = nan;

         rawDataErr(isnan(rawData)) = nan;

         % remove useless levels
         idDel = find(sum(isnan(rawData(:, 2:end)), 2) == size(rawData(:, 2:end), 2));
         rawData(idDel, :) = [];
         rawDataErr(idDel, :) = [];

         % list of existing parameter value
         paramIdList = any(~isnan(rawData), 1);

         if ((sum(paramIdList(1:3)) == 3) && (sum(paramIdList) > 3))

            profStruct = get_prof_data_init_struct;
            profStruct.loopNumber = loopNumber;
            profStruct.wmo = num2str(str2double(strtrim(platformNumber(idP, :)))); % issue whith AOML/1901501
            profStruct.dac = dataCenter(idP, :);
            profStruct.cyNum = cycleNumber(idP);
            profStruct.cyNumStr = num2str(cycleNumber(idP));
            profStruct.dir = upper(direction(idP));
            profStruct.parameterList = [];
            profStruct.paramDataModeAll = paramDataModeAll;
            profStruct.juld = juld(idP);
            profStruct.juldStr = datestr(juld(idP)+g_cogeoab_janFirst1950InMatlab, 'yyyy-mm-ddTHH:MM:SSZ');
            profStruct.lat = latitude(idP);
            profStruct.latStr = sprintf('%.3f', latitude(idP));
            profStruct.lon = longitude(idP);
            profStruct.lonStr = sprintf('%.3f', longitude(idP));
            profStruct.rawDataParamId = paramIdList;
            profStruct.rawData = rawData;
            profStruct.rawDataErr = rawDataErr;
            profStruct.dataGridParamId = zeros(1, size(rawData, 2));
            profStruct.dataGrid = nan(length(g_cogeoab_bgcLevels), 12);
            profStruct.dataGridErr = nan(length(g_cogeoab_bgcLevels), 12);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % interpolate data mesurements on a vertical grid

            profStruct = interpolate_data(profStruct);

            if ((sum(profStruct.dataGridParamId(1:3)) == 3) && (sum(profStruct.dataGridParamId) > 3))

               % store output profile information

               if (isempty(g_cogeoab_profLiteTab) || (g_cogeoab_profLiteTabId > length(g_cogeoab_profLiteTab)))
                  g_cogeoab_profLiteTab = cat(2, g_cogeoab_profLiteTab, ...
                     repmat(get_prof_data_init_struct, 1, g_cogeoab_nbProfToAllocate));
               end

               g_cogeoab_profLiteTab(g_cogeoab_profLiteTabId) = profStruct;

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               % store additionnal information for MAT output

               if (~isempty(profStruct.dataMat))
                  % we need T,S and at least one BGC parameter
                  if (~isempty(profStruct.dataMat.templite) && ...
                        (~isempty(profStruct.dataMat.doxylite) || ...
                        ~isempty(profStruct.dataMat.nitratelite) || ...
                        ~isempty(profStruct.dataMat.phinsitutotallite) || ...
                        ~isempty(profStruct.dataMat.downirradiance380lite) || ...
                        ~isempty(profStruct.dataMat.downirradiance412lite) || ...
                        ~isempty(profStruct.dataMat.downirradiance490lite) || ...
                        ~isempty(profStruct.dataMat.downwellingparlite) || ...
                        ~isempty(profStruct.dataMat.chlalite) || ...
                        ~isempty(profStruct.dataMat.bbp700lite)))

                     wmoBox = pos_to_wmo(longitude(idP), latitude(idP));
                     if (~isnan(wmoBox))

                        profStruct.dataMat.wmoBox = wmoBox;
                        piNameVal = regexprep(strtrim(piName(idP, :)), ' ', '');
                        profStruct.dataMat.source = ...
                           {sprintf('%s_%03d.%s.%s', ...
                           strtrim(platformNumber(idP, :)), ...
                           cycleNumber(idP), ...
                           g_cogeoab_dacName, ...
                           piNameVal)};
                        profStruct.dataMat.dates = ...
                           {datestr(juld(idP) + g_cogeoab_janFirst1950InMatlab, 'yyyymmddHHMMSS')};
                        profStruct.dataMat.lat = latitude(idP);
                        long360 = longitude(idP);
                        if (long360 < 0)
                           long360 = long360 + 360;
                        end
                        profStruct.dataMat.long = long360;

                        profStruct.dataMat.nbLev = size(matRawDataO, 1);

                        if (isempty(profStruct.dataMat.doxylite))
                           profStruct.dataMat.doxylite = nan(length(g_cogeoab_bgcLevels), 1);
                        end
                        if (isempty(profStruct.dataMat.nitratelite))
                           profStruct.dataMat.nitratelite = nan(length(g_cogeoab_bgcLevels), 1);
                        end
                        if (isempty(profStruct.dataMat.phinsitutotallite))
                           profStruct.dataMat.phinsitutotallite = nan(length(g_cogeoab_bgcLevels), 1);
                        end
                        if (isempty(profStruct.dataMat.downirradiance380lite))
                           profStruct.dataMat.downirradiance380lite = nan(length(g_cogeoab_bgcLevels), 1);
                        end
                        if (isempty(profStruct.dataMat.downirradiance412lite))
                           profStruct.dataMat.downirradiance412lite = nan(length(g_cogeoab_bgcLevels), 1);
                        end
                        if (isempty(profStruct.dataMat.downirradiance490lite))
                           profStruct.dataMat.downirradiance490lite = nan(length(g_cogeoab_bgcLevels), 1);
                        end
                        if (isempty(profStruct.dataMat.downwellingparlite))
                           profStruct.dataMat.downwellingparlite = nan(length(g_cogeoab_bgcLevels), 1);
                        end
                        if (isempty(profStruct.dataMat.chlalite))
                           profStruct.dataMat.chlalite = nan(length(g_cogeoab_bgcLevels), 1);
                        end
                        if (isempty(profStruct.dataMat.bbp700lite))
                           profStruct.dataMat.bbp700lite = nan(length(g_cogeoab_bgcLevels), 1);
                        end

                        profStruct.dataMat.preso = matRawDataO(:, 1);
                        profStruct.dataMat.tempo = matRawDataO(:, 2);
                        profStruct.dataMat.salo = matRawDataO(:, 3);
                        profStruct.dataMat.doxyo = matRawDataO(:, 4);
                        profStruct.dataMat.nitrateo = matRawDataO(:, 5);
                        profStruct.dataMat.phinsitutotalo = matRawDataO(:, 6);
                        profStruct.dataMat.downirradiance380o = matRawDataO(:, 7);
                        profStruct.dataMat.downirradiance412o = matRawDataO(:, 8);
                        profStruct.dataMat.downirradiance490o = matRawDataO(:, 9);
                        profStruct.dataMat.downwellingparo = matRawDataO(:, 10);
                        profStruct.dataMat.chlao = matRawDataO(:, 11);
                        profStruct.dataMat.bbp700o = matRawDataO(:, 12);

                        profStruct.dataMat.presadj = matRawData(:, 1);
                        profStruct.dataMat.tempadj = matRawData(:, 2);
                        profStruct.dataMat.saladj = matRawData(:, 3);
                        profStruct.dataMat.doxyadj = matRawData(:, 4);
                        profStruct.dataMat.nitrateadj = matRawData(:, 5);
                        profStruct.dataMat.phinsitutotaladj = matRawData(:, 6);
                        profStruct.dataMat.downirradiance380adj = matRawData(:, 7);
                        profStruct.dataMat.downirradiance412adj = matRawData(:, 8);
                        profStruct.dataMat.downirradiance490adj = matRawData(:, 9);
                        profStruct.dataMat.downwellingparadj = matRawData(:, 10);
                        profStruct.dataMat.chlaadj = matRawData(:, 11);
                        profStruct.dataMat.bbp700adj = matRawData(:, 12);

                        profStruct.dataMat.presadjqc = matRawDataQc(:, 1);
                        profStruct.dataMat.tempadjqc = matRawDataQc(:, 2);
                        profStruct.dataMat.saladjqc = matRawDataQc(:, 3);
                        profStruct.dataMat.doxyadjqc = matRawDataQc(:, 4);
                        profStruct.dataMat.nitrateadjqc = matRawDataQc(:, 5);
                        profStruct.dataMat.phinsitutotaladjqc = matRawDataQc(:, 6);
                        profStruct.dataMat.downirradiance380adjqc = matRawDataQc(:, 7);
                        profStruct.dataMat.downirradiance412adjqc = matRawDataQc(:, 8);
                        profStruct.dataMat.downirradiance490adjqc = matRawDataQc(:, 9);
                        profStruct.dataMat.downwellingparadjqc = matRawDataQc(:, 10);
                        profStruct.dataMat.chlaadjqc = matRawDataQc(:, 11);
                        profStruct.dataMat.bbp700adjqc = matRawDataQc(:, 12);

                        g_cogeoab_profLiteTab(g_cogeoab_profLiteTabId).dataMat = profStruct.dataMat;

                        g_cogeoab_nbOutputProfMatExpected = g_cogeoab_nbOutputProfMatExpected + 1;
                     else

                        % not sure to select all location inconsistencies
                        % already managed inconsistencies are:
                        % AOML 4901542 #245A positionQc=8 and latitude=longitude=FV
                        % Coriolis 6902829 #102A positionQc=1 and latitude=longitude=FV
                        fprintf('ERROR: Bad location for float #%s cycle#%d%c - present in CSV output but not in MAT output\n', ...
                           profStruct.wmo, ...
                           profStruct.cyNum, ...
                           profStruct.dir);

                        g_cogeoab_profLiteTab(g_cogeoab_profLiteTabId).dataMat = [];
                     end
                  else
                     % we need T,S and at least one BGC parameter; if not then remove dataMat
                     g_cogeoab_profLiteTab(g_cogeoab_profLiteTabId).dataMat = [];
                  end
               end

               g_cogeoab_profLiteTabId = g_cogeoab_profLiteTabId + 1;
            end
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Interpolate PTS and BGC data on a vertical grid.
%
% SYNTAX :
%  [o_profStruct] = interpolate_data(a_profStruct)
%
% INPUT PARAMETERS :
%   a_profStruct : input profile data
%
% OUTPUT PARAMETERS :
%   o_profStruct : output profile data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation (from "Annie Wong, January 2024" code)
% ------------------------------------------------------------------------------
function [o_profStruct] = interpolate_data(a_profStruct)

% output parameters initialization
o_profStruct = a_profStruct;


% if ((str2num(o_profStruct.wmo) == 1901378) && (o_profStruct.cyNum == 10))
%    a=1
% end

% interpolate T&S data on the vertical grid
o_profStruct = interpolate_pts_data(o_profStruct);

% T, S are mandatory
if (sum(o_profStruct.dataGridParamId(1:3)) == 3)

   % interpolate BGC data on the vertical grid
   for paramId = 4:size(o_profStruct.rawData, 2)
      if (o_profStruct.rawDataParamId(paramId) == 1)

         switch (paramId)
            case {4, 5, 6} % DOXY, NITRATE, PH_IN_SITU_TOTAL

               o_profStruct = interpolate_bgc_data(o_profStruct, paramId);

            case {7, 8, 9, 10} % DOWN_IRRADIANCE380, DOWN_IRRADIANCE412, DOWN_IRRADIANCE490, DOWNWELLING_PAR

               % transform to logarithmic before interpolation
               rawDataTmp =  o_profStruct.rawData(:, paramId);
               o_profStruct.rawData(:, paramId) = log(o_profStruct.rawData(:, paramId));

               o_profStruct = interpolate_bgc_data(o_profStruct, paramId);

               if (o_profStruct.dataGridParamId(paramId) == 1)
                  o_profStruct.dataGrid(:, paramId) = exp(1).^o_profStruct.dataGrid(:, paramId);
               end
               o_profStruct.rawData(:, paramId) = rawDataTmp;

            case {11, 12} % CHLA, BBP700

               % apply a median filter before interpolation
               rawDataTmp =  o_profStruct.rawData(:, paramId);
               o_profStruct.rawData(:, paramId) = apply_median_filter( ...
                  o_profStruct.rawData(:, 1), o_profStruct.rawData(:, paramId));

               if (any(~isnan(o_profStruct.rawData(:, paramId))))
                  o_profStruct = interpolate_bgc_data(o_profStruct, paramId);
               end

               o_profStruct.rawData(:, paramId) = rawDataTmp;
         end
      end
   end

   % useful levels should have T, S and at least one BGC parameter
   idToNan = find(any(isnan(o_profStruct.dataGrid(:, 2:3)), 2) | ...
      all(isnan(o_profStruct.dataGrid(:, 4:end)), 2));
   if (~isempty(idToNan))
      o_profStruct.dataGrid(idToNan, 2:end) = nan(length(idToNan), size(o_profStruct.dataGrid, 2)-1);
      o_profStruct.dataGridErr(idToNan, :) = nan(length(idToNan), size(o_profStruct.dataGridErr, 2));
   end

   % remove levels below the deepest useful one
   idNan = find(any(isnan(o_profStruct.dataGrid(:, 2:3)), 2) | ...
      all(isnan(o_profStruct.dataGrid(:, 4:end)), 2));
   if (any(idNan == size(o_profStruct.dataGrid, 1)))
      firstUsefulUd = find(diff(flipud(idNan)) ~= -1, 1, 'first');
      lastUseful = size(o_profStruct.dataGrid, 1) - firstUsefulUd;
      o_profStruct.dataGrid(lastUseful+1:end, :) = [];
      o_profStruct.dataGridErr(lastUseful+1:end, :) = [];
   end

   % update dataGridParamId and paramDataModeAll
   o_profStruct.dataGridParamId = any(~isnan(o_profStruct.dataGrid), 1);
   o_profStruct.paramDataModeAll(o_profStruct.dataGridParamId == 0) = ' ';
end

return

% ------------------------------------------------------------------------------
% Interpolate profile PTS data on a vertical grid.
%
% SYNTAX :
%  [o_profStruct] = interpolate_pts_data(a_profStruct)
%
% INPUT PARAMETERS :
%   a_profStruct : input profile data
%
% OUTPUT PARAMETERS :
%   o_profStruct : output profile data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation (from "Annie Wong, January 2024" code)
% ------------------------------------------------------------------------------
function [o_profStruct] = interpolate_pts_data(a_profStruct)

% output parameters initialization
o_profStruct = a_profStruct;

global g_cogeoab_bgcLevels;
global g_cogeoab_pTolerance;

% berbose mode (for additionnal information on ignored data)
global g_cogeoab_verboseMode;

% input parameters
global g_cogeoab_generateOutputMatFlag;


% threshold to select data
DENSITY_INVERSION_THRESHOLD = -0.03; % to exclude density inversions > 0.03kg/m3
SIGMA_TOLERANCE = 1;

bgcLevels = g_cogeoab_bgcLevels;
pTolerance = g_cogeoab_pTolerance;

inputData = a_profStruct.rawData(:, 1:3);
inputDataErr = a_profStruct.rawDataErr(:, 1:3);
idNoDef = find(sum(~isnan(inputData), 2) == 3); % P, T and S should be present

if (~isempty(idNoDef))

   idGood = find(inputData(idNoDef, 1) > 0); % BM2020 does not support negative pressures
   if (length(idGood) > 4) % BM2020 requires at least 5 points

      pres = inputData(idNoDef(idGood), 1);
      temp = inputData(idNoDef(idGood), 2);
      psal = inputData(idNoDef(idGood), 3);
      paramErr = inputDataErr(idNoDef(idGood), 1:3);

      % BM2020 requires pressure increases monotonically, exclude density inversions > 0.03kg/m3
      diffPres = diff(pres);
      sigma = sw_pden(psal, temp, pres, 1000) - 1000; % use sigma1 here
      diffSigma = diff(sigma);

      if ~(any(diffPres <= 0) || any(diffSigma < DENSITY_INVERSION_THRESHOLD))

         [SA, ~] = gsw_SA_from_SP(psal, pres, a_profStruct.lon, a_profStruct.lat);
         CT = gsw_CT_from_t(SA, temp, pres);
         [SA_i, CT_i] = gsw_SA_CT_interp(SA, CT, pres, bgcLevels);
         [S_i, ~] = gsw_SP_from_SA(SA_i, bgcLevels, a_profStruct.lon, a_profStruct.lat);
         T_i = gsw_t_from_CT(SA_i, CT_i, bgcLevels);
         tInSitu = T_i;
         sPractical = S_i;

         % toss out points outside of input profile end points
         idOut = find((bgcLevels < min(pres)) | (bgcLevels > max(pres)));
         tInSitu(idOut) = nan;
         sPractical(idOut) = nan;

         pToleranceLookup = interp1(bgcLevels, pTolerance, pres(1:end-1), 'linear');
         for idLev = 1:length(pres)-1
            % toss out points where input pressure gap is greater than tolerance
            if (diffPres(idLev) > pToleranceLookup(idLev))
               idDel = find((bgcLevels > pres(idLev) & (bgcLevels < pres(idLev+1))));
               tInSitu(idDel) = nan;
               sPractical(idDel) = nan;
            end
            % toss out points where input sigma gap is greater than tolerance
            if (diffSigma(idLev) > SIGMA_TOLERANCE)
               idDel = find((bgcLevels > pres(idLev) & (bgcLevels < pres(idLev+1))));
               tInSitu(idDel) = nan;
               sPractical(idDel) = nan;
            end
         end

         % manage parameter error
         griddedParamErr = nan(size(bgcLevels, 1), 3);

         intParamList = [];
         for id = 1:3
            if (all(~isnan(paramErr(:, id))))
               if (isscalar(unique(paramErr(:, id))))
                  griddedParamErr(:, id) = paramErr(1, id); % error constant
               else
                  intParamList = [intParamList, id]; % error not constant
               end
            end
         end

         if (~isempty(intParamList))

            % we need to find the levels of each grid PRES neighbors in input data
            idAbove = nan(size(bgcLevels));
            idBelow = nan(size(bgcLevels));
            idCheckList = find((bgcLevels >= min(pres)) & (bgcLevels <= max(pres)));
            for id = idCheckList'
               lev = bgcLevels(id);
               idA = find(pres <= lev, 1, 'last');
               idB = find(pres >= lev, 1, 'first');
               if (~isempty(idA) && ~isempty(idB))
                  idAbove(id) = idA;
                  idBelow(id) = idB;
               end
            end

            for idInt = intParamList
               idOkList = find(~isnan(idAbove) & ~isnan(idBelow));
               for id = idOkList'
                  % grided param error value = max value of surrounding neighbors
                  griddedParamErr(id, idInt) = max(paramErr(idAbove(id), idInt), paramErr(idBelow(id), idInt));
               end
            end
         end

         % set EasyOneArgoBGCLite CSV output parameter
         dataGridPts = [bgcLevels, tInSitu, sPractical];
         idToNan = find(any(isnan(dataGridPts(:, 2:3)), 2)); % TS should be defined for each level
         dataGridPts(idToNan, 2:3) = nan(length(idToNan), 2);
         if (any(~isnan(dataGridPts(:, 2))))

            % TS levels remain in the grid => store it in the output structure
            o_profStruct.dataGrid(:, 1:3) = dataGridPts;

            % update and store parameter error
            idToNan = find(isnan(dataGridPts(:, 2)));
            griddedParamErr(idToNan, 1:3) = nan(length(idToNan), 3);
            o_profStruct.dataGridErr(:, 1:3) = griddedParamErr;

            o_profStruct.dataGridParamId(1:3) = 1;

            % set EasyOneArgoBGCLite_audit MAT output parameter
            if (g_cogeoab_generateOutputMatFlag)
               if ((o_profStruct.dir == 'A') && ...
                     ((o_profStruct.paramDataModeAll(1) == 'A') || (o_profStruct.paramDataModeAll(1) == 'D')))

                  o_profStruct.dataMat = get_mat_prof_data_init_struct;
                  o_profStruct.dataMat.templite = dataGridPts(:, 2);
                  o_profStruct.dataMat.sallite = dataGridPts(:, 3);
               end
            end
         end

      else
         if (g_cogeoab_verboseMode)
            if (any(diffPres <= 0))
               fprintf('INFO: Profile %s_%s_%c not interpolated (no monotonically increasing)\n', ...
                  a_profStruct.wmo, ...
                  a_profStruct.cyNumStr, ...
                  a_profStruct.dir);
            end
            if (any(diffSigma < DENSITY_INVERSION_THRESHOLD))
               fprintf('INFO: Profile %s_%s_%c not interpolated (density inversion)\n', ...
                  a_profStruct.wmo, ...
                  a_profStruct.cyNumStr, ...
                  a_profStruct.dir);
            end
         end
      end
   else
      if (g_cogeoab_verboseMode)
         fprintf('INFO: Profile %s_%s_%c not interpolated (only %d levels)\n', ...
            a_profStruct.wmo, ...
            a_profStruct.cyNumStr, ...
            a_profStruct.dir, ...
            length(idGood));
      end
   end
end

return

% ------------------------------------------------------------------------------
% Interpolate BGC data on a vertical grid (linear interpolation).
%
% SYNTAX :
%  [o_profStruct] = interpolate_bgc_data(a_profStruct, a_paramId)
%
% INPUT PARAMETERS :
%   a_profStruct : input profile data
%   a_paramId    : index of the parameter data in the input data array
%
% OUTPUT PARAMETERS :
%   o_profStruct : output profile data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profStruct] = interpolate_bgc_data(a_profStruct, a_paramId)

% output parameters initialization
o_profStruct = a_profStruct;

% input parameters
global g_cogeoab_generateOutputMatFlag;

global g_cogeoab_bgcLevels;


bgcLevels = g_cogeoab_bgcLevels;

presVal = a_profStruct.rawData(:, 1);
paramVal = a_profStruct.rawData(:, a_paramId);
paramErr = a_profStruct.rawDataErr(:, a_paramId);

idNoDef = find(~isnan(presVal) & ~isnan(paramVal)); % P and BGC parameter should be present
presVal = presVal(idNoDef);
paramVal = paramVal(idNoDef);
paramErr = paramErr(idNoDef);

if (length(presVal) > 1)

   % consider increasing pressures only (we start the algorithm from the middle
   % of the profile)
   idToNan = [];
   idStart = fix(length(presVal)/2);
   pMin = presVal(idStart);
   for id = idStart-1:-1:1
      if (presVal(id) >= pMin)
         idToNan = [idToNan id];
      else
         pMin = presVal(id);
      end
   end
   pMax = presVal(idStart);
   for id = idStart+1:length(presVal)
      if (presVal(id) <= pMax)
         idToNan = [idToNan id];
      else
         pMax = presVal(id);
      end
   end
   presVal(idToNan) = nan;
   paramVal(idToNan) = nan;
   paramErr(idToNan) = nan;

   idNoDef = find(~isnan(presVal) & ~isnan(paramVal));
   presVal = presVal(idNoDef);
   paramVal = paramVal(idNoDef);
   paramErr = paramErr(idNoDef);
end

if (~isempty(presVal))

   paramInt = nan(size(bgcLevels));
   paramIntErr = nan(size(bgcLevels));

   if (length(presVal) > 1)

      % interpolate PARAM values
      paramInt = interp1(presVal, paramVal, bgcLevels, 'linear');

      % manage parameter error
      if (all(~isnan(paramErr)))
         if (isscalar(unique(paramErr)))
            paramIntErr(~isnan(paramInt)) = unique(paramErr); % error constant
         else

            % we need to find the levels of each grid PRES neighbors in input data
            idAbove = nan(size(bgcLevels));
            idBelow = nan(size(bgcLevels));
            idCheckList = find((bgcLevels >= min(presVal)) & (bgcLevels <= max(presVal)));
            for id = idCheckList'
               lev = bgcLevels(id);
               idA = find(presVal <= lev, 1, 'last');
               idB = find(presVal >= lev, 1, 'first');
               if (~isempty(idA) && ~isempty(idB))
                  idAbove(id) = idA;
                  idBelow(id) = idB;
               end
            end

            idOkList = find(~isnan(idAbove) & ~isnan(idBelow));
            for id = idOkList'
               % grided param error value = max value of surrounding neighbors
               paramIntErr(id) = max(paramErr(idAbove(id)), paramErr(idBelow(id)));
            end
         end
      end

   elseif (any(bgcLevels == presVal))

      idF = find(bgcLevels == presVal);
      paramInt(idF) = paramVal;
      paramIntErr(idF) = paramErr;
   end

   if (any(~isnan(paramInt)))

      % set EasyOneArgoBGCLite CSV output parameter
      o_profStruct.dataGridParamId(:, a_paramId) = 1;
      o_profStruct.dataGrid(:, a_paramId) = paramInt;
      paramIntErr(isnan(paramInt)) = nan;
      o_profStruct.dataGridErr(:, a_paramId) = paramIntErr;

      % set EasyOneArgoBGCLite_audit MAT output parameter
      if (g_cogeoab_generateOutputMatFlag)
         if (~isempty(o_profStruct.dataMat)) % probably useless
            if ((o_profStruct.dir == 'A') && ...
                  ((o_profStruct.paramDataModeAll(a_paramId) == 'A') || (o_profStruct.paramDataModeAll(a_paramId) == 'D')))

               switch (a_paramId)
                  case {4} % DOXY
                     o_profStruct.dataMat.doxylite = paramInt;
                  case {5} % NITRATE
                     o_profStruct.dataMat.nitratelite = paramInt;
                  case {6} % PH_IN_SITU_TOTAL
                     o_profStruct.dataMat.phinsitutotallite = paramInt;
                  case {7} % DOWN_IRRADIANCE380
                     o_profStruct.dataMat.downirradiance380lite = paramInt;
                  case {8} % DOWN_IRRADIANCE412
                     o_profStruct.dataMat.downirradiance412lite = paramInt;
                  case {9} % DOWN_IRRADIANCE490
                     o_profStruct.dataMat.downirradiance490lite = paramInt;
                  case {10} % DOWNWELLING_PAR
                     o_profStruct.dataMat.downwellingparlite = paramInt;
                  case {11} % CHLA
                     o_profStruct.dataMat.chlalite = paramInt;
                  case {12} % BBP700
                     o_profStruct.dataMat.bbp700lite = paramInt;
               end
            end
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Compute adaptative median filter of a set of values.
%
% SYNTAX :
%  [o_profDataFilt] = apply_median_filter(a_profPres, a_profData)
%
% INPUT PARAMETERS :
%   a_profPres : input PRES data
%   a_profData : input BGC data
%
% OUTPUT PARAMETERS :
%   o_profDataFilt : filtered BGC data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profDataFilt] = apply_median_filter(a_profPres, a_profData)

% output parameters initialization
o_profDataFilt = nan(size(a_profData));


% valid levels of the BGC profile
idNoNan = find(~isnan(a_profPres) & ~isnan(a_profData));
if (~isempty(idNoNan))

   profRes = median(diff(a_profPres(idNoNan)));
   if (profRes <= 1)
      filterSize = 11;
   elseif (profRes < 3)
      filterSize = 7;
   else
      filterSize = 5;
   end

   o_profDataFilt(idNoNan) = median_filter(a_profData(idNoNan), filterSize);
end

return

% ------------------------------------------------------------------------------
% Compute median values of a set of data.
%
% SYNTAX :
%  [o_dataFiltVal] = median_filter(a_dataVal, a_size)
%
% INPUT PARAMETERS :
%   a_dataVal : input set of values
%   a_size    : size of the median filter
%
% OUTPUT PARAMETERS :
%   o_dataFiltVal : median values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataFiltVal] = median_filter(a_dataVal, a_size)

% output parameters initialization
o_dataFiltVal = nan(size(a_dataVal));


halfSize = fix(a_size/2);
for id = 1:length(a_dataVal)
   id1 = max(1, id-halfSize);
   id2 = min(length(a_dataVal), id+halfSize);
   o_dataFiltVal(id) = median(a_dataVal(id1:id2));
end

return

% ------------------------------------------------------------------------------
% Print output CSV files.
%
% SYNTAX :
%    print_output_file
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function print_output_file

% output directories
global g_cogeoab_dirOutputCsvFileDoxyData;
global g_cogeoab_dirOutputCsvFileNitrateData;
global g_cogeoab_dirOutputCsvFilePhData;
global g_cogeoab_dirOutputCsvFileRadiometryData;
global g_cogeoab_dirOutputCsvFileChlaBbpData;
global g_cogeoab_dirOutputCsvFileBgcLiteData;
global g_cogeoab_dirOutputMatFile;

% index files
global g_cogeoab_indexFileDoxy;
global g_cogeoab_indexFileNitrate;
global g_cogeoab_indexFilePh;
global g_cogeoab_indexFileRadiometry;
global g_cogeoab_indexFileChlaBbp;
global g_cogeoab_indexFileBgcLite;

global g_cogeoab_nowUtcStr;
global g_cogeoab_inputDataDoi;

global g_cogeoab_profTab;
global g_cogeoab_profLiteTab;
global g_cogeoab_profTabId;
global g_cogeoab_profLiteTabId;

% number of output files generated
global g_cogeoab_nbOutputFilesDoxy;
global g_cogeoab_nbOutputFilesNitrate;
global g_cogeoab_nbOutputFilesPh;
global g_cogeoab_nbOutputFilesRadiometry;
global g_cogeoab_nbOutputFilesChlaBbp;
global g_cogeoab_nbOutputFilesBgcLite;

% program version
global g_cogeoab_generateEasyOneArgoBgcVersion;

% number to create a unique Id for temporary output MAT file names
global g_cogeoab_tempoOutPutMatId;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create output EasyOneArgoBGC CSV data files

indexCellStr = cell(g_cogeoab_profTabId-1, 2);
indexCellStrCpt = 1;
for idProf = 1:g_cogeoab_profTabId-1
   prof = g_cogeoab_profTab(idProf);

   if (~isempty(prof.data))


      header = cell(16, 1);
      header{1} = '#format EasyOneArgoBGC';
      header{2} = ['#creation_date ' g_cogeoab_nowUtcStr];
      header{3} = '#creation_centre Ifremer';
      header{4} = '#creation_centre_pid https://ror.org/044jxhp58';
      header{5} = ['#data_source_doi ' g_cogeoab_inputDataDoi];
      header{6} = ['#data_centre ' prof.dac];
      header{7} = ['#platform_number ' prof.wmo];
      header{8} = ['#cycle_number ' prof.cyNumStr];
      header{9} = ['#direction_of_profile ' prof.dir];
      header{10} = ['#parameter_data_mode (listed in order of the parameter in the header) = ' regexprep(prof.paramDataMode, ' ', '-')];
      header{11} = ['#profile_date ' prof.juldStr];
      header{12} = ['#profile_latitude ' prof.latStr];
      header{13} = ['#profile_longitude ' prof.lonStr];
      header{14} = '#pressure =  sea water pressure equals 0 at sea-level';
      header{15} = '#temperature = sea temperature in-situ ITS-90 scale';
      header{16} = '#salinity = practical salinity';

      switch (prof.loopNumber)
         case 1
            header{17} = '#oxygen = dissolved oxygen';
            header{18} = 'pressure (decibar),temperature (degree_celsius),salinity (dimensionless),oxygen (micromole/kg),pressure_error (decibar),temperature_error (degree_celsius),salinity_error (dimensionless),oxygen_error (micromole/kg)';
            fmtParam = [{'%.2f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.2f'} {',%.3f'} {',%.3f'} {',%.3f'}];
            dirOutputCsvFileData = g_cogeoab_dirOutputCsvFileDoxyData;
            csvFileSpecificName = 'EasyDOXY.csv';
         case 2
            header{17} = '#nitrate = nitrate';
            header{18} = 'pressure (decibar),temperature (degree_celsius),salinity (dimensionless),nitrate (micromole/kg),pressure_error (decibar),temperature_error (degree_celsius),salinity_error (dimensionless),nitrate_error (micromole/kg)';
            fmtParam = [{'%.2f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.2f'} {',%.3f'} {',%.3f'} {',%.3f'}];
            dirOutputCsvFileData = g_cogeoab_dirOutputCsvFileNitrateData;
            csvFileSpecificName = 'EasyNITRATE.csv';
         case 3
            header{17} = '#pH = pH';
            header{18} = 'pressure (decibar),temperature (degree_celsius),salinity (dimensionless),pH (dimensionless),pressure_error (decibar),temperature_error (degree_celsius),salinity_error (dimensionless),pH_error (dimensionless)';
            fmtParam = [{'%.2f'} {',%.3f'} {',%.3f'} {',%.4f'} {',%.2f'} {',%.3f'} {',%.3f'} {',%.4f'}];
            dirOutputCsvFileData = g_cogeoab_dirOutputCsvFilePhData;
            g_cogeoab_nbOutputFilesPh = g_cogeoab_nbOutputFilesPh + 1;
            csvFileSpecificName = 'EasyPH.csv';
         case 4
            header{17} = '#downIrr380 = downwelling irradiance at 380 nanometers';
            header{18} = '#downIrr412 = downwelling irradiance at 412 nanometers';
            header{19} = '#downIrr490 = downwelling irradiance at 490 nanometers';
            header{20} = '#downwellingPar = downwelling photosynthetic available radiation';
            header{21} = 'pressure (decibar),temperature (degree_celsius),salinity (dimensionless),downIrr380 (W/m^2/nm),downIrr412 (W/m^2/nm),downIrr490 (W/m^2/nm),downwellingPar (microMoleQuanta/m^2/sec),pressure_error (decibar),temperature_error (degree_celsius),salinity_error (dimensionless),downIrr380_error (W/m^2/nm),downIrr412_error (W/m^2/nm),downIrr490_error (W/m^2/nm),downwellingPar_error (microMoleQuanta/m^2/sec)';
            fmtParam = [{'%.2f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.2f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'}];
            dirOutputCsvFileData = g_cogeoab_dirOutputCsvFileRadiometryData;
            csvFileSpecificName = 'EasyRADIOMETRY.csv';
         case 5
            header{17} = '#chla = chlorophyll-A';
            header{18} = '#bbp700 = particle backscattering at 700 nanometers';
            header{19} = 'pressure (decibar),temperature (degree_celsius),salinity (dimensionless),chla (mg/m3),bbp700 (m-1),pressure_error (decibar),temperature_error (degree_celsius),salinity_error (dimensionless),chla_error (mg/m3),bbp700_error (m-1)';
            fmtParam = [{'%.2f'} {',%.3f'} {',%.3f'} {',%.4f'} {',%.7f'} {',%.2f'} {',%.3f'} {',%.3f'} {',%.4f'} {',%.7f'}];
            dirOutputCsvFileData = g_cogeoab_dirOutputCsvFileChlaBbpData;
            csvFileSpecificName = 'EasyCHLA_BBP.csv';
      end

      dataStr = cell(size(prof.data, 1), 1);
      data = [prof.data, prof.dataErr];
      fmtData = repmat(fmtParam, size(data, 1), 1);
      fmtData(isnan(data)) = {','};
      for idL = 1:size(data, 1)
         dataL = data(idL, :);
         dataL(isnan(dataL)) = [];
         dataStr{idL} = sprintf([fmtData{idL, :}], dataL);
      end

      % create the float directory
      dirOutputCsvFloatName = [dirOutputCsvFileData '/' prof.wmo];
      if ~(exist(dirOutputCsvFloatName, 'dir') == 7)
         mkdir(dirOutputCsvFloatName);
      end

      % create output CSV file
      if (prof.dir == 'A')
         profDirStr = '';
      else
         profDirStr = 'D';
      end
      csvFileBaseName = sprintf('%s_%03d%c_', prof.wmo, prof.cyNum, profDirStr);
      csvFilepathName = [dirOutputCsvFloatName '/' csvFileBaseName csvFileSpecificName];
      fId = fopen(csvFilepathName, 'wt');
      if (fId == -1)
         fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
         return
      end

      fprintf(fId, '%s\n', header{:});
      fprintf(fId, '%s\n', dataStr{:});

      fclose(fId);

      % store index data
      indexStr = sprintf('%s,%s,%s,%c,%s,%s,%s,%s', ...
         prof.dac, ...
         prof.wmo, ...
         prof.cyNumStr, ...
         prof.dir, ...
         prof.paramDataMode, ...
         prof.juldStr, ...
         prof.latStr, ...
         prof.lonStr);
      indexCellStr(indexCellStrCpt, :) = [prof.loopNumber {indexStr}];
      indexCellStrCpt = indexCellStrCpt + 1;
   end
end

g_cogeoab_profTab(1:g_cogeoab_profTabId-1) = [];
g_cogeoab_profTabId = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create output EasyOneArgoBGC CSV index files

for loopNumber = 1:5 % one loop for each BGC dataset
   idForLoop = find([indexCellStr{1:indexCellStrCpt-1, 1}] == loopNumber);
   if (~isempty(idForLoop))

      switch (loopNumber)
         case 1
            indexFileHeaderFormat = 'EasyOneArgoDOXYIndexList';
            indexFilePathName = g_cogeoab_indexFileDoxy;
            g_cogeoab_nbOutputFilesDoxy = g_cogeoab_nbOutputFilesDoxy + length(idForLoop);
         case 2
            indexFileHeaderFormat = 'EasyOneArgoNITRATEIndexList';
            indexFilePathName = g_cogeoab_indexFileNitrate;
            g_cogeoab_nbOutputFilesNitrate = g_cogeoab_nbOutputFilesNitrate + length(idForLoop);
         case 3
            indexFileHeaderFormat = 'EasyOneArgoPHIndexList';
            indexFilePathName = g_cogeoab_indexFilePh;
            g_cogeoab_nbOutputFilesPh = g_cogeoab_nbOutputFilesPh + length(idForLoop);
         case 4
            indexFileHeaderFormat = 'EasyOneArgoRADIOMETRYIndexList';
            indexFilePathName = g_cogeoab_indexFileRadiometry;
            g_cogeoab_nbOutputFilesRadiometry = g_cogeoab_nbOutputFilesRadiometry + length(idForLoop);
         case 5
            indexFileHeaderFormat = 'EasyOneArgoCHLA_BBPIndexList';
            indexFilePathName = g_cogeoab_indexFileChlaBbp;
            g_cogeoab_nbOutputFilesChlaBbp = g_cogeoab_nbOutputFilesChlaBbp + length(idForLoop);
      end

      if ~(exist(indexFilePathName, 'file') == 2)

         header = cell(6, 1);
         header{1} = ['#format ' indexFileHeaderFormat];
         header{2} = ['#creation_date ' g_cogeoab_nowUtcStr];
         header{3} = '#creation_centre Ifremer';
         header{4} = '#creation_centre_pid https://ror.org/044jxhp58';
         header{5} = ['#creation_tool_version ' g_cogeoab_generateEasyOneArgoBgcVersion];
         header{6} = 'data_centre,platform_number,cycle_number,direction_of_profile,data_mode,profile_date,profile_latitude,profile_longitude';

         fId = fopen(indexFilePathName, 'wt');
         if (fId == -1)
            fprintf('ERROR: Error while creating file : %s\n', indexFilePathName);
            return
         end
         fprintf(fId, '%s\n', header{:});
         fclose(fId);
      end

      fId = fopen(indexFilePathName, 'at');
      if (fId == -1)
         fprintf('ERROR: Error while creating file : %s\n', indexFilePathName);
         return
      end
      fprintf(fId, '%s\n', indexCellStr{idForLoop, 2});
      fclose(fId);
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create output EasyOneArgoBGCLite CSV data files

indexCellStr = cell(g_cogeoab_profLiteTabId-1, 1);
indexCellStrCpt = 1;
matOutputData = repmat(get_mat_prof_data_init_struct, 1, g_cogeoab_profLiteTabId-1);
matOutputDataCpt = 1;
for idProf = 1:g_cogeoab_profLiteTabId-1
   prof = g_cogeoab_profLiteTab(idProf);

   if ((sum(prof.dataGridParamId(1:3)) == 3) && (sum(prof.dataGridParamId) > 3))

      header = cell(26, 1);
      header{1} = '#format EasyOneArgoBGCLite';
      header{2} = ['#creation_date ' g_cogeoab_nowUtcStr];
      header{3} = '#creation_centre Ifremer';
      header{4} = '#creation_centre_pid https://ror.org/044jxhp58';
      header{5} = ['#data_source_doi ' g_cogeoab_inputDataDoi];
      header{6} = ['#data_centre ' prof.dac];
      header{7} = ['#platform_number ' prof.wmo];
      header{8} = ['#cycle_number ' prof.cyNumStr];
      header{9} = ['#direction_of_profile ' prof.dir];
      header{10} = ['#parameter_data_mode (listed in order of the parameter in the header) = ' regexprep(prof.paramDataModeAll, ' ', '-')];
      header{11} = ['#profile_date ' prof.juldStr];
      header{12} = ['#profile_latitude ' prof.latStr];
      header{13} = ['#profile_longitude ' prof.lonStr];
      header{14} = '#pressure =  sea water pressure equals 0 at sea-level';
      header{15} = '#temperature = sea temperature in-situ ITS-90 scale';
      header{16} = '#salinity = practical salinity';
      header{17} = '#oxygen = dissolved oxygen';
      header{18} = '#nitrate = nitrate';
      header{19} = '#pH = pH';
      header{20} = '#downIrr380 = downwelling irradiance at 380 nanometers';
      header{21} = '#downIrr412 = downwelling irradiance at 412 nanometers';
      header{22} = '#downIrr490 = downwelling irradiance at 490 nanometers';
      header{23} = '#downwellingPar = downwelling photosynthetic available radiation';
      header{24} = '#chla = chlorophyll-A';
      header{25} = '#bbp700 = particle backscattering at 700 nanometers';
      header{26} = [ ...
         'pressure (decibar),temperature (degree_celsius),salinity (dimensionless),' ...
         'oxygen (micromole/kg),'...
         'nitrate (micromole/kg),' ...
         'pH (dimensionless),' ...
         'downIrr380 (W/m^2/nm),downIrr412 (W/m^2/nm),downIrr490 (W/m^2/nm),downwellingPar (microMoleQuanta/m^2/sec),' ...
         'chla (mg/m3),bbp700 (m-1),'...
         'pressure_error (decibar),temperature_error (degree_celsius),salinity_error (dimensionless),' ...
         'oxygen_error (micromole/kg),'...
         'nitrate_error (micromole/kg),' ...
         'pH_error (dimensionless),' ...
         'downIrr380_error (W/m^2/nm),downIrr412_error (W/m^2/nm),downIrr490_error (W/m^2/nm),downwellingPar_error (microMoleQuanta/m^2/sec),' ...
         'chla_error (mg/m3),bbp700_error (m-1)'];

      % some BGC parameters may be missing
      dataStr = cell(size(prof.dataGrid, 1), 1);
      fmtParam = [{'%.2f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.4f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.4f'} {',%.7f'} ...
         {',%.2f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.4f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.4f'} {',%.7f'}];
      data = [prof.dataGrid, prof.dataGridErr];
      fmtData = repmat(fmtParam, size(data, 1), 1);
      fmtData(isnan(data)) = {','};
      for idL = 1:size(data, 1)
         dataL = data(idL, :);
         dataL(isnan(dataL)) = [];
         dataStr{idL} = sprintf([fmtData{idL, :}], dataL);
      end

      % create the float directory
      dirOutputCsvFloatName = [g_cogeoab_dirOutputCsvFileBgcLiteData '/' prof.wmo];
      if ~(exist(dirOutputCsvFloatName, 'dir') == 7)
         mkdir(dirOutputCsvFloatName);
      end

      % create output CSV file
      if (prof.dir == 'A')
         profDirStr = '';
      else
         profDirStr = 'D';
      end
      csvFileBaseName = sprintf('%s_%03d%c_', prof.wmo, prof.cyNum, profDirStr);
      csvFilepathName = [dirOutputCsvFloatName '/' csvFileBaseName 'EasyBGCLite.csv'];
      fId = fopen(csvFilepathName, 'wt');
      if (fId == -1)
         fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
         return
      end

      fprintf(fId, '%s\n', header{:});
      fprintf(fId, '%s\n', dataStr{:});

      fclose(fId);

      % store index data
      indexStr = sprintf('%s,%s,%s,%c,%s,%s,%s,%s', ...
         prof.dac, ...
         prof.wmo, ...
         prof.cyNumStr, ...
         prof.dir, ...
         prof.paramDataModeAll, ...
         prof.juldStr, ...
         prof.latStr, ...
         prof.lonStr);
      indexCellStr(indexCellStrCpt) = {indexStr};
      indexCellStrCpt = indexCellStrCpt + 1;
   end

   % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % store MAT output data
   if (~isempty(prof.dataMat))
      matOutputData(matOutputDataCpt) = prof.dataMat;
      matOutputDataCpt = matOutputDataCpt + 1;
   end
end

g_cogeoab_profLiteTab(1:g_cogeoab_profLiteTabId-1) = [];
g_cogeoab_profLiteTabId = 1;
matOutputData(matOutputDataCpt:end) = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create output EasyOneArgoBGCLite CSV index file

if ~(exist(g_cogeoab_indexFileBgcLite, 'file') == 2)

   header = cell(6, 1);
   header{1} = '#format EasyOneArgoBGCLiteIndexList';
   header{2} = ['#creation_date ' g_cogeoab_nowUtcStr];
   header{3} = '#creation_centre Ifremer';
   header{4} = '#creation_centre_pid https://ror.org/044jxhp58';
   header{5} = ['#creation_tool_version ' g_cogeoab_generateEasyOneArgoBgcVersion];
   header{6} = 'data_centre,platform_number,cycle_number,direction_of_profile,data_mode,profile_date,profile_latitude,profile_longitude';

   fId = fopen(g_cogeoab_indexFileBgcLite, 'wt');
   if (fId == -1)
      fprintf('ERROR: Error while creating file : %s\n', g_cogeoab_indexFileBgcLite);
      return
   end
   fprintf(fId, '%s\n', header{:});
   fclose(fId);
end

fId = fopen(g_cogeoab_indexFileBgcLite, 'at');
if (fId == -1)
   fprintf('ERROR: Error while creating file : %s\n', g_cogeoab_indexFileBgcLite);
   return
end
fprintf(fId, '%s\n', indexCellStr{1:indexCellStrCpt-1});
fclose(fId);

g_cogeoab_nbOutputFilesBgcLite = g_cogeoab_nbOutputFilesBgcLite + indexCellStrCpt - 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create temporary output MAT files with output MAT data

if (~isempty(matOutputData))

   wmoBoxList = unique([matOutputData.wmoBox]);
   for boxNum = wmoBoxList
      idProf = find([matOutputData.wmoBox] == boxNum);

      % gather MAT data for the current WMO box
      profBox = get_mat_prof_data_init_struct;
      profBox.wmoBox = boxNum;
      profBox.nbLev = max([matOutputData(idProf).nbLev]);
      profBox.source = [matOutputData(idProf).source];
      profBox.dates = [matOutputData(idProf).dates];
      profBox.lat = [matOutputData(idProf).lat];
      profBox.long = [matOutputData(idProf).long];

      profBox.templite = [matOutputData(idProf).templite];
      profBox.sallite = [matOutputData(idProf).sallite];
      profBox.doxylite = [matOutputData(idProf).doxylite];
      profBox.nitratelite = [matOutputData(idProf).nitratelite];
      profBox.phinsitutotallite = [matOutputData(idProf).phinsitutotallite];
      profBox.downirradiance380lite = [matOutputData(idProf).downirradiance380lite];
      profBox.downirradiance412lite = [matOutputData(idProf).downirradiance412lite];
      profBox.downirradiance490lite = [matOutputData(idProf).downirradiance490lite];
      profBox.downwellingparlite = [matOutputData(idProf).downwellingparlite];
      profBox.chlalite = [matOutputData(idProf).chlalite];
      profBox.bbp700lite = [matOutputData(idProf).bbp700lite];

      profBox.preso = nan(profBox.nbLev, length(idProf));
      profBox.presadj = nan(profBox.nbLev, length(idProf));
      profBox.presadjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.tempo = nan(profBox.nbLev, length(idProf));
      profBox.tempadj = nan(profBox.nbLev, length(idProf));
      profBox.tempadjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.salo = nan(profBox.nbLev, length(idProf));
      profBox.saladj = nan(profBox.nbLev, length(idProf));
      profBox.saladjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.doxyo = nan(profBox.nbLev, length(idProf));
      profBox.doxyadj = nan(profBox.nbLev, length(idProf));
      profBox.doxyadjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.nitrateo = nan(profBox.nbLev, length(idProf));
      profBox.nitrateadj = nan(profBox.nbLev, length(idProf));
      profBox.nitrateadjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.phinsitutotalo = nan(profBox.nbLev, length(idProf));
      profBox.phinsitutotaladj = nan(profBox.nbLev, length(idProf));
      profBox.phinsitutotaladjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.downirradiance380o = nan(profBox.nbLev, length(idProf));
      profBox.downirradiance380adj = nan(profBox.nbLev, length(idProf));
      profBox.downirradiance380adjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.downirradiance412o = nan(profBox.nbLev, length(idProf));
      profBox.downirradiance412adj = nan(profBox.nbLev, length(idProf));
      profBox.downirradiance412adjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.downirradiance490o = nan(profBox.nbLev, length(idProf));
      profBox.downirradiance490adj = nan(profBox.nbLev, length(idProf));
      profBox.downirradiance490adjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.downwellingparo = nan(profBox.nbLev, length(idProf));
      profBox.downwellingparadj = nan(profBox.nbLev, length(idProf));
      profBox.downwellingparadjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.chlao = nan(profBox.nbLev, length(idProf));
      profBox.chlaadj = nan(profBox.nbLev, length(idProf));
      profBox.chlaadjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.bbp700o = nan(profBox.nbLev, length(idProf));
      profBox.bbp700adj = nan(profBox.nbLev, length(idProf));
      profBox.bbp700adjqc = repmat(' ', profBox.nbLev, length(idProf));

      for idP = 1:length(idProf)
         profBox.preso(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).preso;
         profBox.presadj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).presadj;
         profBox.presadjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).presadjqc);

         profBox.tempo(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).tempo;
         profBox.tempadj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).tempadj;
         profBox.tempadjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).tempadjqc);

         profBox.salo(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).salo;
         profBox.saladj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).saladj;
         profBox.saladjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).saladjqc);

         profBox.doxyo(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).doxyo;
         profBox.doxyadj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).doxyadj;
         profBox.doxyadjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).doxyadjqc);

         profBox.nitrateo(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).nitrateo;
         profBox.nitrateadj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).nitrateadj;
         profBox.nitrateadjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).nitrateadjqc);

         profBox.phinsitutotalo(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).phinsitutotalo;
         profBox.phinsitutotaladj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).phinsitutotaladj;
         profBox.phinsitutotaladjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).phinsitutotaladjqc);

         profBox.downirradiance380o(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).downirradiance380o;
         profBox.downirradiance380adj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).downirradiance380adj;
         profBox.downirradiance380adjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).downirradiance380adjqc);

         profBox.downirradiance412o(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).downirradiance412o;
         profBox.downirradiance412adj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).downirradiance412adj;
         profBox.downirradiance412adjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).downirradiance412adjqc);

         profBox.downirradiance490o(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).downirradiance490o;
         profBox.downirradiance490adj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).downirradiance490adj;
         profBox.downirradiance490adjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).downirradiance490adjqc);

         profBox.downwellingparo(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).downwellingparo;
         profBox.downwellingparadj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).downwellingparadj;
         profBox.downwellingparadjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).downwellingparadjqc);

         profBox.chlao(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).chlao;
         profBox.chlaadj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).chlaadj;
         profBox.chlaadjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).chlaadjqc);

         profBox.bbp700o(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).bbp700o;
         profBox.bbp700adj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).bbp700adj;
         profBox.bbp700adjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).bbp700adjqc);
      end

      % create output MAT file
      matFileName = sprintf('%d_%d_%d_%d_tempo.mat', ...
         boxNum, profBox.nbLev, size(profBox.preso, 2), g_cogeoab_tempoOutPutMatId);
      matFilePathName = [g_cogeoab_dirOutputMatFile '/' matFileName];
      save(matFilePathName, '-struct', 'profBox');
      g_cogeoab_tempoOutPutMatId = g_cogeoab_tempoOutPutMatId + 1;
   end
end

return

% ------------------------------------------------------------------------------
% Concatenate output MAT files.
%
% SYNTAX :
%    concat_output_mat_files
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/25/2024 - RNU - creation
% ------------------------------------------------------------------------------
function concat_output_mat_files

% input parameters
global g_cogeoab_generateOutputMatFlag;
global g_cogeoab_dirOutputMatFile;

global g_cogeoab_bgcLevels;

% number of output files generated
global g_cogeoab_nbOutputFilesMat;
global g_cogeoab_nbOutputProfMat;

if (~g_cogeoab_generateOutputMatFlag)
   return
end

% look for temporary output MAT files and retrieve information from their names
tempMatFileNames = dir([g_cogeoab_dirOutputMatFile '/*_tempo.mat']);
fileNameList = cell(1, length(tempMatFileNames));
wmoBoxList = nan(1, length(tempMatFileNames));
nbLevList = ones(1, length(tempMatFileNames))*-1;
nbProfList = zeros(1, length(tempMatFileNames));
nbFileIdList = nan(1, length(tempMatFileNames));
for idFile = 1:length(tempMatFileNames)
   fileName = tempMatFileNames(idFile).name;
   idFus = strfind(fileName, '_');
   fileNameList{idFile} = fileName;
   wmoBoxList(idFile) = str2double(fileName(1:idFus(1)-1));
   nbLevList(idFile) = str2double(fileName(idFus(1)+1:idFus(2)-1));
   nbProfList(idFile) = str2double(fileName(idFus(2)+1:idFus(3)-1));
   nbFileIdList(idFile) = str2double(fileName(idFus(3)+1:idFus(4)-1));
end

wmoBox = unique(wmoBoxList);
for boxNum = wmoBox
   idProf = find(wmoBoxList == boxNum);

   nbLev = max(nbLevList(idProf));
   nbProf = sum(nbProfList(idProf));
   % sort profiles so that they appear in each WMO box in the same order as in
   % the index file
   nbFileIdAll = [nbFileIdList(idProf)];
   [~, idSort] = sort(nbFileIdAll);
   idProf = idProf(idSort);

   % gather MAT data for the current WMO box
   profBox = get_mat_prof_data_init_struct;
   profBox.source =  cell(1, nbProf);
   profBox.dates = cell(1, nbProf);
   profBox.lat = nan(1, nbProf);
   profBox.long = nan(1, nbProf);

   profBox.preslitelevels = g_cogeoab_bgcLevels;
   profBox.templite = nan(length(g_cogeoab_bgcLevels), nbProf);
   profBox.sallite = nan(length(g_cogeoab_bgcLevels), nbProf);
   profBox.doxylite = nan(length(g_cogeoab_bgcLevels), nbProf);
   profBox.nitratelite = nan(length(g_cogeoab_bgcLevels), nbProf);
   profBox.phinsitutotallite = nan(length(g_cogeoab_bgcLevels), nbProf);
   profBox.downirradiance380lite = nan(length(g_cogeoab_bgcLevels), nbProf);
   profBox.downirradiance412lite = nan(length(g_cogeoab_bgcLevels), nbProf);
   profBox.downirradiance490lite = nan(length(g_cogeoab_bgcLevels), nbProf);
   profBox.downwellingparlite = nan(length(g_cogeoab_bgcLevels), nbProf);
   profBox.chlalite = nan(length(g_cogeoab_bgcLevels), nbProf);
   profBox.bbp700lite = nan(length(g_cogeoab_bgcLevels), nbProf);

   profBox.preso = nan(nbLev, nbProf);
   profBox.presadj = nan(nbLev, nbProf);
   profBox.presadjqc = repmat(' ', nbLev, nbProf);

   profBox.tempo = nan(nbLev, nbProf);
   profBox.tempadj = nan(nbLev, nbProf);
   profBox.tempadjqc = repmat(' ', nbLev, nbProf);

   profBox.salo = nan(nbLev, nbProf);
   profBox.saladj = nan(nbLev, nbProf);
   profBox.saladjqc = repmat(' ', nbLev, nbProf);

   profBox.doxyo = nan(nbLev, nbProf);
   profBox.doxyadj = nan(nbLev, nbProf);
   profBox.doxyadjqc = repmat(' ', nbLev, nbProf);

   profBox.nitrateo = nan(nbLev, nbProf);
   profBox.nitrateadj = nan(nbLev, nbProf);
   profBox.nitrateadjqc = repmat(' ', nbLev, nbProf);

   profBox.phinsitutotalo = nan(nbLev, nbProf);
   profBox.phinsitutotaladj = nan(nbLev, nbProf);
   profBox.phinsitutotaladjqc = repmat(' ', nbLev, nbProf);

   profBox.downirradiance380o = nan(nbLev, nbProf);
   profBox.downirradiance380adj = nan(nbLev, nbProf);
   profBox.downirradiance380adjqc = repmat(' ', nbLev, nbProf);

   profBox.downirradiance412o = nan(nbLev, nbProf);
   profBox.downirradiance412adj = nan(nbLev, nbProf);
   profBox.downirradiance412adjqc = repmat(' ', nbLev, nbProf);

   profBox.downirradiance490o = nan(nbLev, nbProf);
   profBox.downirradiance490adj = nan(nbLev, nbProf);
   profBox.downirradiance490adjqc = repmat(' ', nbLev, nbProf);

   profBox.downwellingparo = nan(nbLev, nbProf);
   profBox.downwellingparadj = nan(nbLev, nbProf);
   profBox.downwellingparadjqc = repmat(' ', nbLev, nbProf);

   profBox.chlao = nan(nbLev, nbProf);
   profBox.chlaadj = nan(nbLev, nbProf);
   profBox.chlaadjqc = repmat(' ', nbLev, nbProf);

   profBox.bbp700o = nan(nbLev, nbProf);
   profBox.bbp700adj = nan(nbLev, nbProf);
   profBox.bbp700adjqc = repmat(' ', nbLev, nbProf);

   fistId = 1;
   for idP = 1:length(idProf)

      tempMatFileName = [g_cogeoab_dirOutputMatFile '/' fileNameList{idProf(idP)}];
      profBoxIn = load(tempMatFileName);

      lastId = fistId + nbProfList(idProf(idP)) - 1;

      profBox.source(fistId:lastId) = profBoxIn.source;
      profBox.dates(fistId:lastId) = profBoxIn.dates;
      profBox.lat(fistId:lastId) = profBoxIn.lat;
      profBox.long(fistId:lastId) = profBoxIn.long;

      profBox.templite(:, fistId:lastId) = profBoxIn.templite;
      profBox.sallite(:, fistId:lastId) = profBoxIn.sallite;
      profBox.doxylite(:, fistId:lastId) = profBoxIn.doxylite;
      profBox.nitratelite(:, fistId:lastId) = profBoxIn.nitratelite;
      profBox.phinsitutotallite(:, fistId:lastId) = profBoxIn.phinsitutotallite;
      profBox.downirradiance380lite(:, fistId:lastId) = profBoxIn.downirradiance380lite;
      profBox.downirradiance412lite(:, fistId:lastId) = profBoxIn.downirradiance412lite;
      profBox.downirradiance490lite(:, fistId:lastId) = profBoxIn.downirradiance490lite;
      profBox.downwellingparlite(:, fistId:lastId) = profBoxIn.downwellingparlite;
      profBox.chlalite(:, fistId:lastId) = profBoxIn.chlalite;
      profBox.bbp700lite(:, fistId:lastId) = profBoxIn.bbp700lite;

      profBox.preso(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.preso;
      profBox.presadj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.presadj;
      profBox.presadjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.presadjqc;

      profBox.tempo(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.tempo;
      profBox.tempadj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.tempadj;
      profBox.tempadjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.tempadjqc;

      profBox.salo(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.salo;
      profBox.saladj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.saladj;
      profBox.saladjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.saladjqc;

      profBox.doxyo(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.doxyo;
      profBox.doxyadj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.doxyadj;
      profBox.doxyadjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.doxyadjqc;

      profBox.nitrateo(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.nitrateo;
      profBox.nitrateadj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.nitrateadj;
      profBox.nitrateadjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.nitrateadjqc;

      profBox.phinsitutotalo(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.phinsitutotalo;
      profBox.phinsitutotaladj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.phinsitutotaladj;
      profBox.phinsitutotaladjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.phinsitutotaladjqc;

      profBox.downirradiance380o(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance380o;
      profBox.downirradiance380adj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance380adj;
      profBox.downirradiance380adjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance380adjqc;

      profBox.downirradiance412o(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance412o;
      profBox.downirradiance412adj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance412adj;
      profBox.downirradiance412adjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance412adjqc;

      profBox.downirradiance490o(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance490o;
      profBox.downirradiance490adj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance490adj;
      profBox.downirradiance490adjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance490adjqc;

      profBox.downwellingparo(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downwellingparo;
      profBox.downwellingparadj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downwellingparadj;
      profBox.downwellingparadjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downwellingparadjqc;

      profBox.chlao(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.chlao;
      profBox.chlaadj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.chlaadj;
      profBox.chlaadjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.chlaadjqc;

      profBox.bbp700o(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.bbp700o;
      profBox.bbp700adj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.bbp700adj;
      profBox.bbp700adjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.bbp700adjqc;

      fistId = fistId + nbProfList(idProf(idP));

      % remove current temporary output MAT file
      delete(tempMatFileName);
   end

   % create output MAT file
   matFileName = sprintf('audit_%d.mat', boxNum);
   matFilePathName = [g_cogeoab_dirOutputMatFile '/' matFileName];
   save(matFilePathName, '-struct', 'profBox', ...
      'source', 'dates', 'lat', 'long', ...
      'preslitelevels', 'templite', 'sallite', ...
      'doxylite', 'nitratelite', 'phinsitutotallite', ...
      'downirradiance380lite', 'downirradiance412lite', 'downirradiance490lite', ...
      'downwellingparlite', 'chlalite', 'bbp700lite', ...
      'preso', 'presadj', 'presadjqc', ...
      'tempo', 'tempadj', 'tempadjqc', ...
      'salo', 'saladj', 'saladjqc', ...
      'doxyo', 'doxyadj', 'doxyadjqc', ...
      'nitrateo', 'nitrateadj', 'nitrateadjqc', ...
      'phinsitutotalo', 'phinsitutotaladj', 'phinsitutotaladjqc', ...
      'downirradiance380o', 'downirradiance380adj', 'downirradiance380adjqc', ...
      'downirradiance412o', 'downirradiance412adj', 'downirradiance412adjqc', ...
      'downirradiance490o', 'downirradiance490adj', 'downirradiance490adjqc', ...
      'downwellingparo', 'downwellingparadj', 'downwellingparadjqc', ...
      'chlao', 'chlaadj', 'chlaadjqc', ...
      'bbp700o', 'bbp700adj', 'bbp700adjqc');

   g_cogeoab_nbOutputProfMat = g_cogeoab_nbOutputProfMat + nbProf;
   g_cogeoab_nbOutputFilesMat = g_cogeoab_nbOutputFilesMat + 1;
end

return

% ------------------------------------------------------------------------------
% Function to convert position to WMO box number.
% number is nan if lat < -90 or lat >= 90
%
% SYNTAX :
%  [o_wmoNumber] = pos_to_wmo(a_long, a_lat)
%
% INPUT PARAMETERS :
%   a_long : position longitude ([0,360[ or [-180,180[)
%   a_lat  : position latitude ([-90,90[,)
%
% OUTPUT PARAMETERS :
%   o_wmoNumber : box WMO number
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/29/2025 - RNU - creation (from BAK 16 March 2004, based on earlier code by HRL)
% ------------------------------------------------------------------------------
function [o_wmoNumber] = pos_to_wmo(a_long, a_lat)

% output parameters initialization
o_wmoNumber = nan;

w = nan;
x = nan;
yz = nan;
LAT = a_lat;
LONG = mod(a_long, 360); %LONG is in range [0,360[

if     (LAT >= 0 &   0 <= LONG & LONG < 180) w = 1;
elseif (LAT >= 0 & 180 <= LONG & LONG < 360) w = 7;
elseif (LAT <  0 &   0 <= LONG & LONG < 180) w = 3;
elseif (LAT <  0 & 180 <= LONG & LONG < 360) w = 5;
end

%if         (( 0 <= LAT & LAT < 10) | (-10 <= LAT & LAT <   0)) x = 0;
%    elseif ((10 <= LAT & LAT < 20) | (-20 <= LAT & LAT < -10)) x = 1;
%    elseif ((20 <= LAT & LAT < 30) | (-30 <= LAT & LAT < -20)) x = 2;
%    elseif ((30 <= LAT & LAT < 40) | (-40 <= LAT & LAT < -30)) x = 3;
%    elseif ((40 <= LAT & LAT < 50) | (-50 <= LAT & LAT < -40)) x = 4;
%    elseif ((50 <= LAT & LAT < 60) | (-60 <= LAT & LAT < -50)) x = 5;
%    elseif ((60 <= LAT & LAT < 70) | (-70 <= LAT & LAT < -60)) x = 6;
%    elseif ((70 <= LAT & LAT < 80) | (-80 <= LAT & LAT < -70)) x = 7;
%    elseif ((80 <= LAT & LAT < 90) | (-90 <= LAT & LAT < -80)) x = 8;
%end

% the table above can be reduced to the following
if (LAT >= 0)
   x = floor(LAT/10);
else
   x = ceil(-LAT/10)-1;
end
if (x > 8)
   x = nan;
end

%if         ((  0 <= LONG & LONG <  10) | (350 <= LONG & LONG < 360)) y = 0;  z = 0;
%    elseif (( 10 <= LONG & LONG <  20) | (340 <= LONG & LONG < 350)) y = 0;  z = 1;
%    elseif (( 20 <= LONG & LONG <  30) | (330 <= LONG & LONG < 340)) y = 0;  z = 2;
%    elseif (( 30 <= LONG & LONG <  40) | (320 <= LONG & LONG < 330)) y = 0;  z = 3;
%    elseif (( 40 <= LONG & LONG <  50) | (310 <= LONG & LONG < 320)) y = 0;  z = 4;
%    elseif (( 50 <= LONG & LONG <  60) | (300 <= LONG & LONG < 310)) y = 0;  z = 5;
%    elseif (( 60 <= LONG & LONG <  70) | (290 <= LONG & LONG < 300)) y = 0;  z = 6;
%    elseif (( 70 <= LONG & LONG <  80) | (280 <= LONG & LONG < 290)) y = 0;  z = 7;
%    elseif (( 80 <= LONG & LONG <  90) | (270 <= LONG & LONG < 280)) y = 0;  z = 8;
%    elseif (( 90 <= LONG & LONG < 100) | (260 <= LONG & LONG < 270)) y = 0;  z = 9;
%    elseif ((100 <= LONG & LONG < 110) | (250 <= LONG & LONG < 260)) y = 1;  z = 0;
%    elseif ((110 <= LONG & LONG < 120) | (240 <= LONG & LONG < 250)) y = 1;  z = 1;
%    elseif ((120 <= LONG & LONG < 130) | (230 <= LONG & LONG < 240)) y = 1;  z = 2;
%    elseif ((130 <= LONG & LONG < 140) | (220 <= LONG & LONG < 230)) y = 1;  z = 3;
%    elseif ((140 <= LONG & LONG < 150) | (210 <= LONG & LONG < 220)) y = 1;  z = 4;
%    elseif ((150 <= LONG & LONG < 160) | (200 <= LONG & LONG < 210)) y = 1;  z = 5;
%    elseif ((160 <= LONG & LONG < 170) | (190 <= LONG & LONG < 200)) y = 1;  z = 6;
%    elseif ((170 <= LONG & LONG < 180) | (180 <= LONG & LONG < 190)) y = 1;  z = 7;
%end

% the table above can be reduced to the following
if (LONG >= 180)
   LONG = LONG-360;
end  %LONG is now in range [-180,180[
if(LONG >= 0)
   yz = floor(LONG/10);
else
   yz = ceil(-LONG/10)-1;
end

% o_wmoNumber = (w*1000 + x*100 + y*10 + z);
o_wmoNumber = (w*1000 + x*100 + yz);

return

% ------------------------------------------------------------------------------
% Load interpolation reference levels.
%
% SYNTAX :
%  load_bgc_levels_ref
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function load_bgc_levels_ref

global g_cogeoab_bgcLevels;
global g_cogeoab_pTolerance;

levels = [ ...
   [2, 6]; ...
   [5, 9]; ...
   [10, 15]; ...
   [15, 15]; ...
   [20, 15]; ...
   [25, 15]; ...
   [30, 15]; ...
   [35, 15]; ...
   [40, 15]; ...
   [45, 15]; ...
   [50, 15]; ...
   [55, 15]; ...
   [60, 15]; ...
   [65, 15]; ...
   [70, 15]; ...
   [75, 15]; ...
   [80, 15]; ...
   [85, 15]; ...
   [90, 15]; ...
   [95, 15]; ...
   [100, 15]; ...
   [105, 15]; ...
   [110, 15]; ...
   [115, 15]; ...
   [120, 15]; ...
   [125, 15]; ...
   [130, 15]; ...
   [135, 15]; ...
   [140, 15]; ...
   [145, 15]; ...
   [150, 15]; ...
   [155, 15]; ...
   [160, 15]; ...
   [165, 15]; ...
   [170, 15]; ...
   [175, 15]; ...
   [180, 15]; ...
   [185, 15]; ...
   [190, 15]; ...
   [195, 15]; ...
   [200, 15]; ...
   [205, 15]; ...
   [210, 15]; ...
   [215, 15]; ...
   [220, 15]; ...
   [225, 15]; ...
   [230, 15]; ...
   [235, 15]; ...
   [240, 15]; ...
   [245, 15]; ...
   [250, 15]; ...
   [260, 30]; ...
   [270, 30]; ...
   [280, 30]; ...
   [290, 30]; ...
   [300, 30]; ...
   [310, 30]; ...
   [320, 30]; ...
   [330, 30]; ...
   [340, 30]; ...
   [350, 30]; ...
   [375, 75]; ...
   [400, 75]; ...
   [425, 75]; ...
   [450, 75]; ...
   [475, 75]; ...
   [500, 75]; ...
   [550, 150]; ...
   [600, 150]; ...
   [650, 150]; ...
   [700, 150]; ...
   [750, 150]; ...
   [800, 150]; ...
   [850, 150]; ...
   [900, 150]; ...
   [950, 150]; ...
   [1000, 150]; ...
   [1100, 300]; ...
   [1200, 300]; ...
   [1300, 300]; ...
   [1400, 300]; ...
   [1500, 300]; ...
   [1600, 300]; ...
   [1700, 300]; ...
   [1800, 300]; ...
   [1900, 300]; ...
   [2000, 300]; ...
   [2200, 600]; ...
   [2400, 600]; ...
   [2600, 600]; ...
   [2800, 600]; ...
   [3000, 600]; ...
   [3200, 600]; ...
   [3400, 600]; ...
   [3600, 600]; ...
   [3800, 600]; ...
   [4000, 600]; ...
   [4200, 600]; ...
   [4400, 600]; ...
   [4600, 600]; ...
   [4800, 600]; ...
   [5000, 600]; ...
   [5200, 600]; ...
   [5400, 600]; ...
   [5600, 600]; ...
   [5800, 600]; ...
   [6000, 600]];

g_cogeoab_bgcLevels = levels(:, 1);
g_cogeoab_pTolerance = levels(:, 2);

return

% ------------------------------------------------------------------------------
% Get the dedicated structure to store profile information.
%
% SYNTAX :
%  [o_profDataStruct] = get_prof_data_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_profDataStruct : profile data initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profDataStruct] = get_prof_data_init_struct

% output parameters initialization
o_profDataStruct = struct( ...
   'loopNumber', '', ...
   'wmo', '', ...
   'dac', '', ...
   'cyNum', '', ...
   'cyNumStr', '', ...
   'dir', '', ...
   'parameterList', [], ...
   'paramDataMode', [], ...
   'paramDataModeAll', [], ...
   'juld', '', ...
   'juldStr', '', ...
   'lat', '', ...
   'latStr', '', ...
   'lon', '', ...
   'lonStr', '', ...
   'data', [], ...
   'dataErr', [], ...
   'rawDataParamId', [], ...
   'rawData', [], ...
   'rawDataErr', [], ...
   'dataGridParamId', [], ...
   'dataGrid', [], ...
   'dataGridErr', [], ...
   'dataMat', []);

return

% ------------------------------------------------------------------------------
% Get the dedicated structure to store profile information for MAT output.
%
% SYNTAX :
%  [o_matProfDataStruct] = get_mat_prof_data_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_matProfDataStruct : profile data initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/03/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_matProfDataStruct] = get_mat_prof_data_init_struct

% output parameters initialization
o_matProfDataStruct = struct( ...
   'wmoBox', '', ...
   'nbLev', '', ...
   'source', '', ...
   'dates', '', ...
   'lat', '', ...
   'long', '', ...
   'preso', [], ...
   'presadj', [], ...
   'presadjqc', [], ...
   'preslitelevels', [], ...
   'tempo', [], ...
   'tempadj', [], ...
   'tempadjqc', [], ...
   'templite', [], ...
   'salo', [], ...
   'saladj', [], ...
   'saladjqc', [], ...
   'sallite', [], ...
   'doxyo', [], ...
   'doxyadj', [], ...
   'doxyadjqc', [], ...
   'doxylite', [], ...
   'nitrateo', [], ...
   'nitrateadj', [], ...
   'nitrateadjqc', [], ...
   'nitratelite', [], ...
   'phinsitutotalo', [], ...
   'phinsitutotaladj', [], ...
   'phinsitutotaladjqc', [], ...
   'phinsitutotallite', [], ...
   'downirradiance380o', [], ...
   'downirradiance380adj', [], ...
   'downirradiance380adjqc', [], ...
   'downirradiance380lite', [], ...
   'downirradiance412o', [], ...
   'downirradiance412adj', [], ...
   'downirradiance412adjqc', [], ...
   'downirradiance412lite', [], ...
   'downirradiance490o', [], ...
   'downirradiance490adj', [], ...
   'downirradiance490adjqc', [], ...
   'downirradiance490lite', [], ...
   'downwellingparo', [], ...
   'downwellingparadj', [], ...
   'downwellingparadjqc', [], ...
   'downwellingparlite', [], ...
   'chlao', [], ...
   'chlaadj', [], ...
   'chlaadjqc', [], ...
   'chlalite', [], ...
   'bbp700o', [], ...
   'bbp700adj', [], ...
   'bbp700adjqc', [], ...
   'bbp700lite', []);

return

% ------------------------------------------------------------------------------
% Initialize XML report.
%
% SYNTAX :
%  init_xml_report(a_time)
%
% INPUT PARAMETERS :
%   a_time : start date of the run ('yyyymmddTHHMMSS' format)
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function init_xml_report(a_time)

% DOM node of XML report
global g_cogeoab_xmlReportDOMNode;

% program version
global g_cogeoab_generateEasyOneArgoBgcVersion;


% initialize XML report
docNode = com.mathworks.xml.XMLUtils.createDocument('coriolis_function_report');
docRootNode = docNode.getDocumentElement;

newChild = docNode.createElement('function');
newChild.appendChild(docNode.createTextNode('CO-05-08-16-02'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('comment');
newChild.appendChild(docNode.createTextNode('Argo Coriolis Easy OneArgo BGC generator (generate_easy_one_argo_bgc)'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('tool_version');
newChild.appendChild(docNode.createTextNode(g_cogeoab_generateEasyOneArgoBgcVersion));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('date');
newChild.appendChild(docNode.createTextNode(datestr(datenum(a_time, 'yyyymmddTHHMMSSZ'), 'dd/mm/yyyy HH:MM:SS')));
docRootNode.appendChild(newChild);

g_cogeoab_xmlReportDOMNode = docNode;

return

% ------------------------------------------------------------------------------
% Parse input parameters.
%
% SYNTAX :
%  [o_inputError] = parse_input_param(a_varargin)
%
% INPUT PARAMETERS :
%   a_varargin : input parameters
%
% OUTPUT PARAMETERS :
%   o_inputError : input error flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_inputError] = parse_input_param(a_varargin)

% output parameters initialization
o_inputError = 0;

global g_cogeoab_dirInputNcFiles;
global g_cogeoab_inputDataDoi;
global g_cogeoab_dirOutputCsvFiles;
global g_cogeoab_dirLogFile;
global g_cogeoab_dirOutputXmlFile;
global g_cogeoab_xmlReportFileName;
global g_cogeoab_generateOutputMatFlag;
global g_cogeoab_dirOutputMatFiles;

g_cogeoab_dirInputNcFiles = [];
g_cogeoab_inputDataDoi = [];
g_cogeoab_dirOutputCsvFiles = [];
g_cogeoab_dirLogFile = [];
g_cogeoab_dirOutputXmlFile = [];
g_cogeoab_xmlReportFileName = [];
g_cogeoab_generateOutputMatFlag = [];
g_cogeoab_dirOutputMatFiles = [];


% ignore empty input parameters
idDel = [];
for id = 1:length(a_varargin)
   if (isempty(a_varargin{id}))
      idDel = [idDel id];
   end
end
a_varargin(idDel) = [];

% check input parameters
if (~isempty(a_varargin))
   if (rem(length(a_varargin), 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') - exit\n');
      o_inputError = 1;
      return
   else
      for id = 1:2:length(a_varargin)
         if (strcmpi(a_varargin{id}, 'inputDataDir'))
            g_cogeoab_dirInputNcFiles = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'inputDataDoi'))
            g_cogeoab_inputDataDoi = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'csvOutputDir'))
            g_cogeoab_dirOutputCsvFiles = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'logDir'))
            g_cogeoab_dirLogFile = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'xmlReportDir'))
            g_cogeoab_dirOutputXmlFile = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'xmlReportName'))
            g_cogeoab_xmlReportFileName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'generateOutputMatFlag'))
            g_cogeoab_generateOutputMatFlag = str2double(a_varargin{id+1});
         elseif (strcmpi(a_varargin{id}, 'matOutputDir'))
            g_cogeoab_dirOutputMatFiles = a_varargin{id+1};
         else
            fprintf('WARNING: unexpected input argument (%s) - ignored\n', a_varargin{id});
         end
      end
   end
end

% check the xml report file name consistency
if (~isempty(g_cogeoab_xmlReportFileName))
   if (length(g_cogeoab_xmlReportFileName) < 29)
      fprintf('WARNING: inconsistent xml report file name (%s) expecting co05081602_yyyymmddTHHMMSSZ[_PID].xml - ignored\n', g_cogeoab_xmlReportFileName);
      g_cogeoab_xmlReportFileName = [];
   end
end

return

% ------------------------------------------------------------------------------
% Finalize the XML report.
%
% SYNTAX :
%  [o_status] = finalize_xml_report(a_ticStartTime, a_logFileName, a_error)
%
% INPUT PARAMETERS :
%   a_ticStartTime : identifier for the "tic" command
%   a_logFileName  : log file path name of the run
%   a_error        : Matlab error
%
% OUTPUT PARAMETERS :
%   o_status : final status of the run
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_status] = finalize_xml_report(a_ticStartTime, a_logFileName, a_error)

% input parameters
global g_cogeoab_generateOutputMatFlag;

% DOM node of XML report
global g_cogeoab_xmlReportDOMNode;

% number of input files processed
global g_cogeoab_nbInputFiles;

% number of input profiles processed
global g_cogeoab_nbInputProfiles;

% number of output files generated
global g_cogeoab_nbOutputFilesDoxy;
global g_cogeoab_nbOutputFilesNitrate;
global g_cogeoab_nbOutputFilesPh;
global g_cogeoab_nbOutputFilesRadiometry;
global g_cogeoab_nbOutputFilesChlaBbp;
global g_cogeoab_nbOutputFilesBgcLite;
global g_cogeoab_nbOutputFilesMat;
global g_cogeoab_nbOutputProfMatExpected;
global g_cogeoab_nbOutputProfMat;

% user report files
global g_cogeoab_reportFileDoxy;
global g_cogeoab_reportFileNitrate;
global g_cogeoab_reportFilePh;
global g_cogeoab_reportFileRadiometry;
global g_cogeoab_reportFileChlaBbp;
global g_cogeoab_reportFileBgcLite;

% program version
global g_cogeoab_generateEasyOneArgoBgcVersion;

% date of the run
global g_cogeoab_nowUtcStr;


% initalize final status
o_status = 'ok';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% finalize the xml report

docNode = g_cogeoab_xmlReportDOMNode;
docRootNode = docNode.getDocumentElement;

nbInputFiles = g_cogeoab_nbInputFiles;
nbInputProfiles = g_cogeoab_nbInputProfiles;
nbOutputFilesDoxy = g_cogeoab_nbOutputFilesDoxy;
nbOutputFilesNitrate = g_cogeoab_nbOutputFilesNitrate;
nbOutputFilesPh = g_cogeoab_nbOutputFilesPh;
nbOutputFilesRadiometry = g_cogeoab_nbOutputFilesRadiometry;
nbOutputFilesChlaBbp = g_cogeoab_nbOutputFilesChlaBbp;
nbOutputFilesBgcLite = g_cogeoab_nbOutputFilesBgcLite;
nbOutputFilesMat = g_cogeoab_nbOutputFilesMat;
nbOutputProfMatExpected = g_cogeoab_nbOutputProfMatExpected;
nbOutputProfMat = g_cogeoab_nbOutputProfMat;

% retrieve information from the log file
[infoMsg, warningMsg, errorMsg] = parse_log_file(a_logFileName);

error = a_error;

duration = format_time(toc(a_ticStartTime)/3600);

newChild = docNode.createElement('Nb_input_nc_files');
textNode = num2str(nbInputFiles);
newChild.appendChild(docNode.createTextNode(textNode));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('Nb_input_profiles');
textNode = num2str(nbInputProfiles);
newChild.appendChild(docNode.createTextNode(textNode));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('Nb_output_csv_files_EasyOneArgoDOXY');
textNode = num2str(nbOutputFilesDoxy);
newChild.appendChild(docNode.createTextNode(textNode));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('Nb_output_csv_files_EasyOneArgoNITRATE');
textNode = num2str(nbOutputFilesNitrate);
newChild.appendChild(docNode.createTextNode(textNode));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('Nb_output_csv_files_EasyOneArgoPH');
textNode = num2str(nbOutputFilesPh);
newChild.appendChild(docNode.createTextNode(textNode));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('Nb_output_csv_files_EasyOneArgoRADIOMETRY');
textNode = num2str(nbOutputFilesRadiometry);
newChild.appendChild(docNode.createTextNode(textNode));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('Nb_output_csv_files_EasyOneArgoCHLABBP');
textNode = num2str(nbOutputFilesChlaBbp);
newChild.appendChild(docNode.createTextNode(textNode));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('Nb_output_csv_files_EasyOneArgoBGCLite');
textNode = num2str(nbOutputFilesBgcLite);
newChild.appendChild(docNode.createTextNode(textNode));
docRootNode.appendChild(newChild);

if (g_cogeoab_generateOutputMatFlag)
   newChild = docNode.createElement('Nb_output_mat_files_EasyOneArgoBGCLite_audit');
   textNode = num2str(nbOutputFilesMat);
   newChild.appendChild(docNode.createTextNode(textNode));
   docRootNode.appendChild(newChild);

   newChild = docNode.createElement('Nb_output_mat_profiles_expected_EasyOneArgoBGCLite_audit');
   textNode = num2str(nbOutputProfMatExpected);
   newChild.appendChild(docNode.createTextNode(textNode));

   newChild = docNode.createElement('Nb_output_mat_profiles_EasyOneArgoBGCLite_audit');
   textNode = num2str(nbOutputProfMat);
   newChild.appendChild(docNode.createTextNode(textNode));
   docRootNode.appendChild(newChild);
end

if (~isempty(infoMsg))

   for idMsg = 1:length(infoMsg)
      newChild = docNode.createElement('info');
      textNode = infoMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
end

if (~isempty(warningMsg))

   for idMsg = 1:length(warningMsg)
      newChild = docNode.createElement('warning');
      textNode = warningMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
end

if (~isempty(errorMsg))

   for idMsg = 1:length(errorMsg)
      newChild = docNode.createElement('error');
      textNode = errorMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
   o_status = 'nok';
end

% add matlab error
if (~isempty(error))
   o_status = 'nok';

   newChild = docNode.createElement('matlab_error');

   for idE = 1:length(error)
      errStruct = error(idE);

      newChildBis = docNode.createElement('error_message');
      textNode = regexprep(errStruct.message, char(10), ': ');
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);

      for idS = 1:size(errStruct.stack, 1)
         newChildBis = docNode.createElement('stack_line');
         textNode = sprintf('Line: %3d File: %s (func: %s)', ...
            errStruct.stack(idS). line, ...
            errStruct.stack(idS). file, ...
            errStruct.stack(idS). name);
         newChildBis.appendChild(docNode.createTextNode(textNode));
         newChild.appendChild(newChildBis);
      end
   end
   docRootNode.appendChild(newChild);
end

newChild = docNode.createElement('duration');
newChild.appendChild(docNode.createTextNode(duration));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('status');
newChild.appendChild(docNode.createTextNode(o_status));
docRootNode.appendChild(newChild);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create user reports

for loopNumber = 1:6

   switch (loopNumber)
      case 1
         nbOutputFiles = nbOutputFilesDoxy;
         datasetName = 'EasyOneArgoDOXY';
         reportFilePathName = g_cogeoab_reportFileDoxy;
      case 2
         nbOutputFiles = nbOutputFilesNitrate;
         datasetName = 'EasyOneArgoNITRATE';
         reportFilePathName = g_cogeoab_reportFileNitrate;
      case 3
         nbOutputFiles = nbOutputFilesPh;
         datasetName = 'EasyOneArgoPH';
         reportFilePathName = g_cogeoab_reportFilePh;
      case 4
         nbOutputFiles = nbOutputFilesRadiometry;
         datasetName = 'EasyOneArgoRADIOMETRY';
         reportFilePathName = g_cogeoab_reportFileRadiometry;
      case 5
         nbOutputFiles = nbOutputFilesChlaBbp;
         datasetName = 'EasyOneArgoCHLA_BBP';
         reportFilePathName = g_cogeoab_reportFileChlaBbp;
      case 6
         nbOutputFiles = nbOutputFilesBgcLite;
         datasetName = 'EasyOneArgoBGCLite';
         reportFilePathName = g_cogeoab_reportFileBgcLite;
   end

   if (nbOutputFiles > 0)

      fId = fopen(reportFilePathName, 'wt');
      if (fId == -1)
         fprintf('ERROR: Error while creating file : %s\n', reportFilePathName);
         return
      end

      fprintf(fId, 'Generator version number: %s\n', g_cogeoab_generateEasyOneArgoBgcVersion);
      fprintf(fId, 'Run date: %s\n', g_cogeoab_nowUtcStr);
      fprintf(fId, 'Run time: %s\n', duration);
      fprintf(fId, 'Number of input Argo S-PROF NetCDF files: %d\n', nbInputFiles);
      fprintf(fId, 'Number of input profiles: %d\n', nbInputProfiles);
      fprintf(fId, 'Number of output CSV files in the %s dataset: %d\n', datasetName, nbOutputFiles);

      fclose(fId);
   end
end

return

% ------------------------------------------------------------------------------
% ------------------------------------------------------------------------------
% the following code is duplicated from Coriolis processing chain so that this
% tool can be used as a standalone function
% ------------------------------------------------------------------------------
% ------------------------------------------------------------------------------

% ------------------------------------------------------------------------------
% Retrieve data from NetCDF file.
%
% SYNTAX :
%  [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : NetCDF file name
%   a_wantedVars     : NetCDF variables to retrieve from the file
%
% OUTPUT PARAMETERS :
%   o_ncData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)

% output parameters initialization
o_ncData = [];


if (exist(a_ncPathFileName, 'file') == 2)

   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return
   end

   try

      % retrieve the list of variables that are present in the file
      varFlagList = vars_are_present_dec_argo(fCdf, a_wantedVars);

      % retrieve variables from NetCDF file
      for idVar = 1:length(a_wantedVars)
         if (varFlagList(idVar) == 1)
            varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, a_wantedVars{idVar}));
            o_ncData = [o_ncData {a_wantedVars{idVar}} {varValue}];
         else
            %          fprintf('WARNING: Variable %s not present in file : %s\n', ...
            %             varName, a_ncPathFileName);
            o_ncData = [o_ncData {a_wantedVars{idVar}} {''}];
         end

      end

      netcdf.close(fCdf);

   catch MException
      netcdf.close(fCdf);
      rethrow(MException)
   end
end

return

% ------------------------------------------------------------------------------
% Check if a given list of variables are present in a NetCDF file.
%
% SYNTAX :
%  [o_varFlagList] = vars_are_present_dec_argo(a_ncId, a_varNameList)
%
% INPUT PARAMETERS :
%   a_ncId        : NetCDF file Id
%   a_varNameList : list of variable names
%
% OUTPUT PARAMETERS :
%   o_varFlagList : 1 if the variable is present (0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/06/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_varFlagList] = vars_are_present_dec_argo(a_ncId, a_varNameList)

o_varFlagList = ones(size(a_varNameList));

[nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(a_ncId);

valList = cell(nbVars, 1);
for idVar = 0:nbVars-1
   [valList{idVar+1}, varType, varDims, nbAtts] = netcdf.inqVar(a_ncId, idVar);
end

notPresentList = setdiff(a_varNameList, valList);
for idVar = 1:length(notPresentList)
   o_varFlagList(strcmp(notPresentList{idVar}, a_varNameList)) = 0;
end

return

% ------------------------------------------------------------------------------
% Get data from name in a {var_name}/{var_data} list.
%
% SYNTAX :
%  [o_dataValues] = get_data_from_name(a_dataName, a_dataList)
%
% INPUT PARAMETERS :
%   a_dataName : name of the data to retrieve
%   a_dataList : {var_name}/{var_data} list
%
% OUTPUT PARAMETERS :
%   o_dataValues : concerned data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataValues] = get_data_from_name(a_dataName, a_dataList)

% output parameters initialization
o_dataValues = [];

idVal = find(strcmp(a_dataName, a_dataList(1:2:end)) == 1, 1);
if (~isempty(idVal))
   o_dataValues = a_dataList{2*idVal};
end

return

% ------------------------------------------------------------------------------
% Retrieve INFO, WARNING and ERROR messages from the log file.
%
% SYNTAX :
%  [o_infoMsg, o_warningMsg, o_errorMsg] = parse_log_file(a_logFileName)
%
% INPUT PARAMETERS :
%   a_logFileName  : log file path name of the run
%
% OUTPUT PARAMETERS :
%   o_infoMsg    : INFO messages
%   o_warningMsg : WARNING messages
%   o_errorMsg   : ERROR messages
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/20/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_infoMsg, o_warningMsg, o_errorMsg] = parse_log_file(a_logFileName)

% output parameters initialization
o_infoMsg = [];
o_warningMsg = [];
o_errorMsg = [];

if (~isempty(a_logFileName))
   % read log file
   fId = fopen(a_logFileName, 'r');
   if (fId == -1)
      errorLine = sprintf('ERROR: Unable to open file: %s\n', a_logFileName);
      o_errorMsg = [o_errorMsg {errorLine}];
      return
   end
   fileContents = textscan(fId, '%s', 'delimiter', '\n');
   fclose(fId);

   if (~isempty(fileContents))
      % retrieve wanted messages
      fileContents = fileContents{:};
      idLine = 1;
      while (1)
         line = fileContents{idLine};
         if (strncmp(line, 'INFO: ', length('INFO: ')))
            o_infoMsg = [o_infoMsg {line(length('INFO: ')+1:end)}];
         elseif (strncmp(line, 'WARNING: ', length('WARNING: ')))
            o_warningMsg = [o_warningMsg {line(length('WARNING: ')+1:end)}];
         elseif (strncmp(line, 'ERROR: ', length('ERROR: ')))
            o_errorMsg = [o_errorMsg {line(length('ERROR: ')+1:end)}];
         end
         idLine = idLine + 1;
         if (idLine > length(fileContents))
            break
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Duration format.
%
% SYNTAX :
%   [o_time] = format_time(a_time)
%
% INPUT PARAMETERS :
%   a_time : hour (in float)
%
% OUTPUT PARAMETERS :
%   o_time : formated duration
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/20/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_time] = format_time(a_time)

% output parameters initialization
o_time = [];

if (a_time >= 0)
   sign = '';
else
   sign = '-';
end
a_time = abs(a_time);
h = fix(a_time);
m = fix((a_time-h)*60);
s = round(((a_time-h)*60-m)*60);
if (s == 60)
   s = 0;
   m = m + 1;
   if (m == 60)
      m = 0;
      h = h + 1;
   end
end
if (isempty(sign))
   o_time = sprintf('%02d:%02d:%02d', h, m, s);
else
   o_time = sprintf('%c %02d:%02d:%02d', sign, h, m, s);
end

return
