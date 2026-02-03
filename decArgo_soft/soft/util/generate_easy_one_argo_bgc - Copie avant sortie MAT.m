% ------------------------------------------------------------------------------
% Generate Easy OneArgo BGC data sets
% (EasyOneArgoDOXY, EasyOneArgoNITRATE, EasyOneArgoPH, EasyOneArgoRADIOMETRY,
% EasyOneArgoCHLA&BBP and EasyOneArgoBGCLite).
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
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\ONE_ARGO_BGC\IN\mono_multiS\';

% DOI of the reference input data set
INPUT_DATA_DOI = 'http://doi.org/10.17882/42182#114627';

% top directory of output CSV files
DIR_OUTPUT_CSV_FILES = 'C:\Users\jprannou\_DATA\ONE_ARGO_BGC\OUT\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log';

% directory to store the xml report
DIR_XML_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\xml\';

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
% EasyOneArgoCHLA&BBP and EasyOneArgoBGCLite).
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
g_cogeoab_nbOutputFilesDoxy = 0;
g_cogeoab_nbOutputFilesNitrate = 0;
g_cogeoab_nbOutputFilesPh = 0;
g_cogeoab_nbOutputFilesRadiometry = 0;
g_cogeoab_nbOutputFilesChlaBbp = 0;
g_cogeoab_nbOutputFilesBgcLite = 0;

% store DAC from input directories
global g_cogeoab_dacName;


diary(g_cogeoab_logFilePathName);
tic;

% print input parameter values in log file
fprintf('\nINPUT PARAMETERS:\n');
fprintf('DIR_INPUT_NC_FILES   : ''%s''\n', g_cogeoab_dirInputNcFiles);
fprintf('INPUT_DATA_DOI       : ''%s''\n', g_cogeoab_inputDataDoi);
fprintf('DIR_OUTPUT_CSV_FILES : ''%s''\n', g_cogeoab_dirOutputCsvFiles);
fprintf('DIR_LOG_FILE         : ''%s''\n', g_cogeoab_dirLogFile);
fprintf('DIR_XML_FILE         : ''%s''\n', g_cogeoab_dirOutputXmlFile);

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
g_cogeoab_dirOutputCsvFileChlaBbp = [g_cogeoab_dirOutputCsvFiles '/EasyOneArgoCHLA&BBP_' datestr(g_cogeoab_nowUtc, 'yyyymmddTHHMMSSZ')];
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

% set index file names
g_cogeoab_indexFileDoxy = [g_cogeoab_dirOutputCsvFileDoxy '/EasyOneArgoDOXY_index.csv'];
g_cogeoab_indexFileNitrate = [g_cogeoab_dirOutputCsvFileNitrate '/EasyOneArgoNITRATE_index.csv'];
g_cogeoab_indexFilePh = [g_cogeoab_dirOutputCsvFilePh '/EasyOneArgoPH_index.csv'];
g_cogeoab_indexFileRadiometry = [g_cogeoab_dirOutputCsvFileRadiometry '/EasyOneArgoRADIOMETRY_index.csv'];
g_cogeoab_indexFileChlaBbp = [g_cogeoab_dirOutputCsvFileChlaBbp '/EasyOneArgoCHLA&BBP_index.csv'];
g_cogeoab_indexFileBgcLite = [g_cogeoab_dirOutputCsvFileBgcLite '/EasyOneArgoBGCLite_index.csv'];

% set report file names
g_cogeoab_reportFileDoxy = [g_cogeoab_dirOutputCsvFileDoxy '/EasyOneArgoDOXY_report.txt'];
g_cogeoab_reportFileNitrate = [g_cogeoab_dirOutputCsvFileNitrate '/EasyOneArgoNITRATE_report.txt'];
g_cogeoab_reportFilePh = [g_cogeoab_dirOutputCsvFilePh '/EasyOneArgoPH_report.txt'];
g_cogeoab_reportFileRadiometry = [g_cogeoab_dirOutputCsvFileRadiometry '/EasyOneArgoRADIOMETRY_report.txt'];
g_cogeoab_reportFileChlaBbp = [g_cogeoab_dirOutputCsvFileChlaBbp '/EasyOneArgoCHLA&BBP_report.txt'];
g_cogeoab_reportFileBgcLite = [g_cogeoab_dirOutputCsvFileBgcLite '/EasyOneArgoBGCLite_report.txt'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process input directory

stop = 0;
dirNames = dir(g_cogeoab_dirInputNcFiles);
MULTI = 0;
if (MULTI)

   % input are multi-cycles S profile files
   for idDir = 1:length(dirNames)

      if (stop)
         break
      end

      dacName = dirNames(idDir).name;
      if (strcmp(dacName, '.') || strcmp(dacName, '..'))
         continue
      end

      fprintf('Processing DAC %s:\n', dacName);
      g_cogeoab_dacName = dacName;

      floatDirPath = [g_cogeoab_dirInputNcFiles '/' dacName '/'];
      floatDirNames = dir(floatDirPath);
      for idFDir = 1:length(floatDirNames)

         floatDirName = floatDirNames(idFDir).name;
         if (strcmp(floatDirName, '.') || strcmp(floatDirName, '..'))
            continue
         end

         profFilePathName = [floatDirPath '/' floatDirName '/' floatDirName '_Sprof.nc'];
         if ~(exist(profFilePathName, 'file') == 2)
            continue
         end

         fprintf('%04d/%04d %s \n', idFDir-2, length(floatDirNames)-2, floatDirName);

         % process one multi-profile file
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
else

   % input are mono-cycle S profile files
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
end

% save the remaining stored data in CSV files
print_output_file;

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

% default values
global g_cogeoab_janFirst1950InMatlab;

% number of input profiles processed
global g_cogeoab_nbInputProfiles;

global g_cogeoab_bgcLevels;

% fillValue of LATITUDE and LONGITUDE (not retreive from NetCDF file to speed up
% the process)
LAT_LON_FV = double(99999);

% fillValue of all concerned measurements (not retrieved from NetCDF file to speed up the
% process)
MEAS_FV = single(99999);


% retrieve data from profile file
wantedVars = [ ...
   {'PLATFORM_NUMBER'} ...
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

      if (~isempty(rawData))

         rawData(rawData == MEAS_FV) = nan;
         rawDataErr(rawDataErr == MEAS_FV) = nan;

         % apply QC criteria on each parameter individually
         for idParam = 1:12
            if (idParam < 10)
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
            profStruct.parameterList = parameterList;
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

            % store output profile information

            if (isempty(g_cogeoab_profLiteTab) || (g_cogeoab_profLiteTabId > length(g_cogeoab_profLiteTab)))
               g_cogeoab_profLiteTab = cat(2, g_cogeoab_profLiteTab, ...
                  repmat(get_prof_data_init_struct, 1, g_cogeoab_nbProfToAllocate));
            end

            g_cogeoab_profLiteTab(g_cogeoab_profLiteTabId) = profStruct;
            g_cogeoab_profLiteTabId = g_cogeoab_profLiteTabId + 1;
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
idNoDef = find(~isnan(a_profPres) & ~isnan(a_profData));
if (length(idNoDef) > 1)

   profPres = a_profPres(idNoDef);
   profData = a_profData(idNoDef);

   presDiff = diff(profPres);
   presDiff = [presDiff(1); presDiff];

   id1 = find(presDiff <= 1);
   if (~isempty(id1))
      profDataFilt = median_filter(profData, 11);
      o_profDataFilt(idNoDef(id1)) = profDataFilt(id1);
   end
   id2 = find((presDiff > 1) & (presDiff < 3));
   if (~isempty(id2))
      profDataFilt = median_filter(profData, 7);
      o_profDataFilt(idNoDef(id2)) = profDataFilt(id2);
   end
   id3 = find(presDiff >= 3);
   if (~isempty(id3))
      profDataFilt = median_filter(profData, 5);
      o_profDataFilt(idNoDef(id3)) = profDataFilt(id3);
   end
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
      header{10} = ['#parameter_data_mode ' prof.paramDataMode];
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
            csvFileSpecificName = 'EasyCHLA&BBP.csv';
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
            indexFileHeaderFormat = 'EasyOneArgoCHLA&BBPIndexList';
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
      header{10} = ['#parameter_data_mode ' prof.paramDataModeAll];
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
end

g_cogeoab_profLiteTab(1:g_cogeoab_profLiteTabId-1) = [];
g_cogeoab_profLiteTabId = 1;

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
   'dataGridErr', []);

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

g_cogeoab_dirInputNcFiles = [];
g_cogeoab_inputDataDoi = [];
g_cogeoab_dirOutputCsvFiles = [];
g_cogeoab_dirLogFile = [];
g_cogeoab_dirOutputXmlFile = [];
g_cogeoab_xmlReportFileName = [];


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
         datasetName = 'EasyOneArgoCHLA&BBP';
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
