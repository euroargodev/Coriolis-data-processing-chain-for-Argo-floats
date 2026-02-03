% ------------------------------------------------------------------------------
% Generate Easy OneArgo core data sets (EasyOneArgoCore and EasyOneArgoCoreLite).
%
% SYNTAX :
%   generate_easy_one_argo_core(varargin)
%
% INPUT PARAMETERS :
%   varargin :
%      input parameters:
%         - should be provided as pairs ('param_name','param_value')
%         - 'param_name' value is not case sensitive
%   no mandatory input parameters
%   possible input parameters:
%      inputDataDir          : top directory of input NetCDF files
%      inputDataDoi          : DOI of the input data set (Argo monthly snapshot)
%      csvOutputDir          : directory to store the CSV output data sets
%      logDir                : directory to store the log file
%      xmlReportDir          : directory to store the XML report
%      xmlReportName         : file name of the XML report
%      generateOutputMatFlag : flag to generate MAT files
%      matOutputDir          : directory to store the MAT output data set
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/25/2024 - RNU - V 0.1: creation
%   03/25/2025 - RNU - V 1.0: first deployed version
%   03/31/2025 - RNU - V 1.1: modification of XML report contents
%   04/23/2025 - RNU - V 1.2: - back to previous version of xml report.
%                             - one user report for each dataset.
%                             - csv files moved to a dedicated "data" directory
%                             - "profile_latitude" instead of "latitude" in
%                             CSV files.
%                             - "profile_longitude" instead of "longitude" in
%                             CSV files.
%                             - "direction_of_profile" instead of "direction" in
%                             CSV files.
%                             - long names of pressure, temperature and salinity
%                             added in the end of the CSV file header.
%   05/06/2025 - RNU - V 1.3: typo corrected in EasyOneArgoTSLite user report.
%   05/19/2025 - RNU - V 1.4: 'generateOutputMatFlag' input argument value
%                             should be converted in integer.
%   06/02/2025 - RNU - V 1.5: in EasyOneArgoTSLite_audit dataset provide (in
%                             preso, presadj, tempo, tempadj, salo and saladj)
%                             all profile levels without any restriction due to
%                             their QC.
%   10/10/2025 - RNU - V 1.6: - new number for the Coriolis function
%                             - improved efficiency of get_data_from_nc_file
%                             - new vertical grid for interpolation (same as BGC
%                             one)
%   10/15/2025 - RNU - V 1.7: - use of mono-cycle profile files as input
%                             - remove multi sessions mode
%   10/24/2025 - RNU - V 1.8: in the EasyOneArgoTSLite dataset: provide, in CSV
%                             output files, all the pressure levels of the
%                             vertical grid (from 2dbar down to the deepest
%                             "useful" level) even when there is no interpolated
%                             value.
%   11/17/2025 - RNU - V 1.9: in the EasyOneArgoTSLite dataset: bug when looking
%                             for the deepest "useful" level when all the
%                             pressure levels of the vertical grid are fill.
% ------------------------------------------------------------------------------
function generate_easy_one_argo_core(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START

% top directory of input NetCDF profile files
% (can be one directory with all profile files to process or top directory
% of the DAC name directories (as in the GDAC))
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\ONE_ARGO\IN\mini\';

% DOI of the reference input data set
INPUT_DATA_DOI = 'http://doi.org/10.17882/42182#114627';

% top directory of output CSV files
DIR_OUTPUT_CSV_FILES = 'C:\Users\jprannou\_DATA\ONE_ARGO\OUT\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log';

% directory to store the xml report
DIR_XML_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\xml\';

% generate output MAT files
GENERATE_OUTPUT_MAT_FLAG = 0;

% top directory of output MAT files
DIR_OUTPUT_MAT_FILES = 'C:\Users\jprannou\_DATA\ONE_ARGO\OUT\';

% CONFIGURATION - END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% process a reduced number of profile files (set to -1 to process all the files)
global g_cogeoac_nbFilesToProcess;
g_cogeoac_nbFilesToProcess = -1;

% program version
global g_cogeoac_generateEasyOneArgoCoreVersion;
g_cogeoac_generateEasyOneArgoCoreVersion = '1.9';

% berbose mode (for additionnal information on ignored data)
global g_cogeoac_verboseMode;
g_cogeoac_verboseMode = 0;

% minimum number of profiles in memory before creating associated CSV files
global g_cogeoac_minNbProfBeforeSaving;
% g_cogeoac_minNbProfBeforeSaving = 10000;
% g_cogeoac_minNbProfBeforeSaving = 7000;
g_cogeoac_minNbProfBeforeSaving = 2000;

% number of profiles in memory to allocate
global g_cogeoac_nbProfToAllocate;
% g_cogeoac_nbProfToAllocate = 10500;
% g_cogeoac_nbProfToAllocate = 7500;
g_cogeoac_nbProfToAllocate = 2500;

% input parameters
global g_cogeoac_dirInputNcFiles;
global g_cogeoac_inputDataDoi;
global g_cogeoac_dirOutputCsvFiles;
global g_cogeoac_dirLogFile;
global g_cogeoac_dirOutputXmlFile;
global g_cogeoac_xmlReportFileName;
global g_cogeoac_logFilePathName;
global g_cogeoac_generateOutputMatFlag;
global g_cogeoac_dirOutputMatFiles;

% store DAC from input directories
global g_cogeoac_dacName;
g_cogeoac_dacName = '';

global g_cogeoac_janFirst1950InMatlab;
g_cogeoac_janFirst1950InMatlab = datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');

% DOM node of XML report
global g_cogeoac_xmlReportDOMNode;

% XML report information structure
global g_cogeoac_reportXmlData;
g_cogeoac_reportXmlData = [];

% date of the run
global g_cogeoac_nowUtc;
g_cogeoac_nowUtc = now_utc;
global g_cogeoac_nowUtcStr;
g_cogeoac_nowUtcStr = datestr(g_cogeoac_nowUtc, 'yyyy-mm-ddTHH:MM:SSZ');

% number to create a unique Id for temporary output MAT file names
global g_cogeoac_tempoOutPutMatId;
g_cogeoac_tempoOutPutMatId = 1;


logFileName = [];
status = 'nok';
try

   % startTime
   ticStartTime = tic;

   % store the start time of the run
   currentTime = datestr(g_cogeoac_nowUtc, 'yyyymmddTHHMMSSZ');

   % init the XML report
   init_xml_report(currentTime);

   % get input parameters
   [inputError] = parse_input_param(varargin);

   if (inputError == 0)

      % set parameter default values
      if (isempty(g_cogeoac_dirInputNcFiles))
         g_cogeoac_dirInputNcFiles = DIR_INPUT_NC_FILES;
      end
      if (isempty(g_cogeoac_inputDataDoi))
         g_cogeoac_inputDataDoi = INPUT_DATA_DOI;
      end
      if (isempty(g_cogeoac_dirOutputCsvFiles))
         g_cogeoac_dirOutputCsvFiles = DIR_OUTPUT_CSV_FILES;
      end
      if (isempty(g_cogeoac_dirLogFile))
         g_cogeoac_dirLogFile = DIR_LOG_FILE;
      end
      if (isempty(g_cogeoac_dirOutputXmlFile))
         g_cogeoac_dirOutputXmlFile = DIR_XML_FILE;
      end
      if (isempty(g_cogeoac_generateOutputMatFlag))
         g_cogeoac_generateOutputMatFlag = GENERATE_OUTPUT_MAT_FLAG;
      end
      if (isempty(g_cogeoac_dirOutputMatFiles))
         g_cogeoac_dirOutputMatFiles = DIR_OUTPUT_MAT_FILES;
      end

      % log file creation
      if (~isempty(g_cogeoac_xmlReportFileName))
         logFileName = [g_cogeoac_dirLogFile '/generate_easy_one_argo_core_' g_cogeoac_xmlReportFileName(10:end-4) '.log'];
      else
         logFileName = [g_cogeoac_dirLogFile '/generate_easy_one_argo_core_' currentTime '.log'];
      end

      g_cogeoac_logFilePathName = logFileName;

      % process the files according to input and configuration parameters
      generate_easy_one_argo_core_;

      % finalize XML report
      [status] = finalize_xml_report(ticStartTime, logFileName, []);

   else
      g_cogeoac_dirOutputXmlFile = DIR_XML_FILE;
   end

catch

   diary off;

   % finalize XML report
   [status] = finalize_xml_report(ticStartTime, logFileName, lasterror);

end

% create the XML report path file name
if (~isempty(g_cogeoac_xmlReportFileName))
   xmlFileName = [g_cogeoac_dirOutputXmlFile '/' g_cogeoac_xmlReportFileName];
else
   xmlFileName = [g_cogeoac_dirOutputXmlFile '/co05081601_' currentTime '.xml'];
end

% save the XML report
xmlwrite(xmlFileName, g_cogeoac_xmlReportDOMNode);
% if (strcmp(status, 'nok') == 1)
%    edit(xmlFileName);
% end

return

% ------------------------------------------------------------------------------
% Generate Easy OneArgo core data sets (EasyOneArgoCore and EasyOneArgoCoreLite).
%
% SYNTAX :
%    generate_easy_one_argo_core_
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
function generate_easy_one_argo_core_

% input parameters
global g_cogeoac_dirInputNcFiles;
global g_cogeoac_inputDataDoi;
global g_cogeoac_dirOutputCsvFiles;
global g_cogeoac_dirLogFile;
global g_cogeoac_dirOutputXmlFile;
global g_cogeoac_logFilePathName;
global g_cogeoac_generateOutputMatFlag;
global g_cogeoac_dirOutputMatFiles;

% output directories
global g_cogeoac_dirOutputCsvFile;
g_cogeoac_dirOutputCsvFile = [];
global g_cogeoac_dirOutputCsvFileData;
g_cogeoac_dirOutputCsvFileData = [];
global g_cogeoac_dirOutputCsvFileLite;
g_cogeoac_dirOutputCsvFileLite = [];
global g_cogeoac_dirOutputCsvFileLiteData;
g_cogeoac_dirOutputCsvFileLiteData = [];
global g_cogeoac_dirOutputMatFile;
g_cogeoac_dirOutputMatFile = [];

% index files
global g_cogeoac_indexFile;
g_cogeoac_indexFile = '';
global g_cogeoac_indexFileLite;
g_cogeoac_indexFileLite = '';

% user report files
global g_cogeoac_reportFile;
g_cogeoac_reportFile = '';
global g_cogeoac_reportFileLite;
g_cogeoac_reportFileLite = '';

% time of the processed dataset
global g_cogeoac_nowUtc;

% process a reduced number of profile files
global g_cogeoac_nbFilesToProcess;

% array of processed data
global g_cogeoac_profTab;
g_cogeoac_profTab = [];

% index in array of processed data
global g_cogeoac_profTabId;
g_cogeoac_profTabId = 1;

% minimum number of profiles in memory before creating associated CSV files
global g_cogeoac_minNbProfBeforeSaving;

% number of input files processed
global g_cogeoac_nbInputFiles;
g_cogeoac_nbInputFiles = 0;

% number of output files generated
global g_cogeoac_nbOutputFiles;
g_cogeoac_nbOutputFiles = 0;
global g_cogeoac_nbOutputFilesLite;
g_cogeoac_nbOutputFilesLite = 0;
global g_cogeoac_nbOutputFilesMat;
g_cogeoac_nbOutputFilesMat = 0;
global g_cogeoac_nbOutputProfMatExpected;
g_cogeoac_nbOutputProfMatExpected = 0;
global g_cogeoac_nbOutputProfMat;
g_cogeoac_nbOutputProfMat = 0;

% store DAC from input directories
global g_cogeoac_dacName;


diary(g_cogeoac_logFilePathName);
tic;

% print input parameter values in log file
fprintf('\nINPUT PARAMETERS:\n');
fprintf('DIR_INPUT_NC_FILES      : ''%s''\n', g_cogeoac_dirInputNcFiles);
fprintf('INPUT_DATA_DOI          : ''%s''\n', g_cogeoac_inputDataDoi);
fprintf('DIR_OUTPUT_CSV_FILES    : ''%s''\n', g_cogeoac_dirOutputCsvFiles);
fprintf('DIR_LOG_FILE            : ''%s''\n', g_cogeoac_dirLogFile);
fprintf('DIR_XML_FILE            : ''%s''\n', g_cogeoac_dirOutputXmlFile);
fprintf('GENERATE_OUTPUT_MAT_FLAG: %d\n', g_cogeoac_generateOutputMatFlag);
fprintf('DIR_OUTPUT_MAT_FILES    : ''%s''\n\n', g_cogeoac_dirOutputMatFiles);

% load interpolation reference data
load_core_levels_ref;

% create output directories
if ~(exist(g_cogeoac_dirOutputCsvFiles, 'dir') == 7)
   mkdir(g_cogeoac_dirOutputCsvFiles);
end
g_cogeoac_dirOutputCsvFile = [g_cogeoac_dirOutputCsvFiles '/EasyOneArgoTS_' datestr(g_cogeoac_nowUtc, 'yyyymmddTHHMMSSZ')];
if ~(exist(g_cogeoac_dirOutputCsvFile, 'dir') == 7)
   mkdir(g_cogeoac_dirOutputCsvFile);
end
g_cogeoac_dirOutputCsvFileData = [g_cogeoac_dirOutputCsvFile '/data'];
if ~(exist(g_cogeoac_dirOutputCsvFileData, 'dir') == 7)
   mkdir(g_cogeoac_dirOutputCsvFileData);
end
g_cogeoac_dirOutputCsvFileLite = [g_cogeoac_dirOutputCsvFiles '/EasyOneArgoTSLite_' datestr(g_cogeoac_nowUtc, 'yyyymmddTHHMMSSZ')];
if ~(exist(g_cogeoac_dirOutputCsvFileLite, 'dir') == 7)
   mkdir(g_cogeoac_dirOutputCsvFileLite);
end
g_cogeoac_dirOutputCsvFileLiteData = [g_cogeoac_dirOutputCsvFileLite '/data'];
if ~(exist(g_cogeoac_dirOutputCsvFileLiteData, 'dir') == 7)
   mkdir(g_cogeoac_dirOutputCsvFileLiteData);
end
if (g_cogeoac_generateOutputMatFlag == 1)
   if ~(exist(g_cogeoac_dirOutputMatFiles, 'dir') == 7)
      mkdir(g_cogeoac_dirOutputMatFiles);
   end
   g_cogeoac_dirOutputMatFile = [g_cogeoac_dirOutputMatFiles '/EasyOneArgoTSLite_audit_' datestr(g_cogeoac_nowUtc, 'yyyymmddTHHMMSSZ')];
   if ~(exist(g_cogeoac_dirOutputMatFile, 'dir') == 7)
      mkdir(g_cogeoac_dirOutputMatFile);
   end
end

% set index file names
g_cogeoac_indexFile = [g_cogeoac_dirOutputCsvFile '/EasyOneArgoTS_index.csv'];
g_cogeoac_indexFileLite = [g_cogeoac_dirOutputCsvFileLite '/EasyOneArgoTSLite_index.csv'];

% set report file names
g_cogeoac_reportFile = [g_cogeoac_dirOutputCsvFile '/EasyOneArgoTS_report.txt'];
g_cogeoac_reportFileLite = [g_cogeoac_dirOutputCsvFileLite '/EasyOneArgoTSLite_report.txt'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process input directory

% input are mono-cycle profile files
stop = 0;
nbFiles = 0;
dirNames = dir(g_cogeoac_dirInputNcFiles);
for idDir = 1:length(dirNames)

   if (stop)
      break
   end

   dacName = dirNames(idDir).name;
   if (strcmp(dacName, '.') || strcmp(dacName, '..'))
      continue
   end

   fprintf('Processing DAC %s:\n', dacName);
   g_cogeoac_dacName = dacName;

   floatDirPath = [g_cogeoac_dirInputNcFiles '/' dacName '/'];
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

      profFiles = [ ...
         dir([floatDirPath '/' floatDirName '/profiles/D' floatDirName '*.nc']); ...
         dir([floatDirPath '/' floatDirName '/profiles/R' floatDirName '*.nc'])];
      for idFFile = 1:length(profFiles)

         profFilePathName = [floatDirPath '/' floatDirName '/profiles/' profFiles(idFFile).name];
         % fprintf('   %s\n', profFiles(idFFile).name);

         % process one file
         process_profile_file(profFilePathName);
         g_cogeoac_nbInputFiles = g_cogeoac_nbInputFiles + 1;

         if (g_cogeoac_profTabId > g_cogeoac_minNbProfBeforeSaving)
            % save the stored data in CSV/MAT files
            print_output_file;
         end
         nbFiles = nbFiles + 1;

         if (nbFiles == g_cogeoac_nbFilesToProcess)
            stop = 1;
            break
         end
      end
   end
end

% save the remaining stored data in CSV/MAT files
print_output_file;

% concatenate output MAT files
concat_output_mat_files;

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Process one profile file.
%
% SYNTAX :
% process_profile_file(a_profFilePathName)
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
%   11/25/2024 - RNU - creation
% ------------------------------------------------------------------------------
function process_profile_file(a_profFilePathName)

% array of processed data
global g_cogeoac_profTab;

% index in array of processed data
global g_cogeoac_profTabId;

% number of profiles in memory to allocate
global g_cogeoac_nbProfToAllocate;

% berbose mode (for additionnal information on ignored data)
global g_cogeoac_verboseMode;

% number of output files generated
global g_cogeoac_nbOutputProfMatExpected;

% default values
global g_cogeoac_janFirst1950InMatlab;

% store DAC from input directories
global g_cogeoac_dacName;

% fillValue of LATITUDE and LONGITUDE (not retreive from NetCDF file to speed up
% the process)
LAT_LON_FV = double(99999);

% fillValue of PTS measurements (not retrieved from NetCDF file to speed up the
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
   {'DATA_MODE'} ...
   {'JULD'} ...
   {'JULD_QC'} ...
   {'JULD_LOCATION'} ...
   {'LATITUDE'} ...
   {'LONGITUDE'} ...
   {'POSITION_QC'} ...
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
[profData] = get_data_from_nc_file(a_profFilePathName, wantedVars);

juldQc = get_data_from_name('JULD_QC', profData);
positionQc = get_data_from_name('POSITION_QC', profData);
latitude = get_data_from_name('LATITUDE', profData);
longitude = get_data_from_name('LONGITUDE', profData);

% select 'good' profiles
idGoList = find(((juldQc == '1') | (juldQc == '5') | (juldQc == '8')) & ...
   ((positionQc == '1') | (positionQc == '5') | (positionQc == '8')) & ...
   ~((latitude == LAT_LON_FV) | (longitude == LAT_LON_FV))); % AOML 4901542 #245A positionQc=8 and latitude=longitude=FV, Coriolis 6902829 #102A positionQc=1 and latitude=longitude=FV
if (~isempty(idGoList))

   % we use only the N_PROF = 1 profile
   if (any(idGoList == 1))

      idPrim = 1;

      platformNumber = get_data_from_name('PLATFORM_NUMBER', profData)';
      piName = get_data_from_name('PI_NAME', profData)';
      dataCenter = get_data_from_name('DATA_CENTRE', profData)';
      dataMode = get_data_from_name('DATA_MODE', profData);
      cycleNumber = get_data_from_name('CYCLE_NUMBER', profData);
      direction = get_data_from_name('DIRECTION', profData);
      juld = get_data_from_name('JULD', profData);
      pres = get_data_from_name('PRES', profData);
      presQc = get_data_from_name('PRES_QC', profData);
      presAdj = get_data_from_name('PRES_ADJUSTED', profData);
      presAdjQc = get_data_from_name('PRES_ADJUSTED_QC', profData);
      presAdjErr = get_data_from_name('PRES_ADJUSTED_ERROR', profData);
      temp = get_data_from_name('TEMP', profData);
      tempQc = get_data_from_name('TEMP_QC', profData);
      tempAdj = get_data_from_name('TEMP_ADJUSTED', profData);
      tempAdjQc = get_data_from_name('TEMP_ADJUSTED_QC', profData);
      tempAdjErr = get_data_from_name('TEMP_ADJUSTED_ERROR', profData);
      psal = get_data_from_name('PSAL', profData);
      psalQc = get_data_from_name('PSAL_QC', profData);
      psalAdj = get_data_from_name('PSAL_ADJUSTED', profData);
      psalAdjQc = get_data_from_name('PSAL_ADJUSTED_QC', profData);
      psalAdjErr = get_data_from_name('PSAL_ADJUSTED_ERROR', profData);

      if (~isempty(pres) && ~isempty(temp) && ~isempty(psal))

         % select the 'best' PTS data from their data mode
         if (dataMode(idPrim) == 'R')
            presBest = pres(:, idPrim);
            presBestQc = presQc(:, idPrim);
            presBestErr = nan(size(presBest));
            tempBest = temp(:, idPrim);
            tempBestQc = tempQc(:, idPrim);
            tempBestErr = nan(size(tempBest));
            psalBest = psal(:, idPrim);
            psalBestQc = psalQc(:, idPrim);
            psalBestErr = nan(size(psalBest));
         else
            presBest = presAdj(:, idPrim);
            presBestQc = presAdjQc(:, idPrim);
            presBestErr = presAdjErr(:, idPrim);
            tempBest = tempAdj(:, idPrim);
            tempBestQc = tempAdjQc(:, idPrim);
            tempBestErr = tempAdjErr(:, idPrim);
            psalBest = psalAdj(:, idPrim);
            psalBestQc = psalAdjQc(:, idPrim);
            psalBestErr = psalAdjErr(:, idPrim);
         end

         % concatenate data and remove padded levels
         data = [presBest, tempBest, psalBest, presBestErr, tempBestErr, psalBestErr];
         presBestQc((presBestQc == ' ')) = '7'; % QC='7' not used in Argo
         tempBestQc((tempBestQc == ' ')) = '7'; % QC='7' not used in Argo
         psalBestQc((psalBestQc == ' ')) = '7'; % QC='7' not used in Argo
         dataQc = [str2num(presBestQc), str2num(tempBestQc), str2num(psalBestQc), ones(length(presBestQc), 3)];
         idDel = find((dataQc(:, 1) == 7) & (dataQc(:, 2) == 7) & (dataQc(:, 3) == 7));
         data(idDel, :) = [];
         dataQc(idDel, :) = [];

         if (~isempty(data))

            profStruct = get_prof_data_init_struct;
            profStruct.wmo = num2str(str2double(strtrim(platformNumber(idPrim, :)))); % issue with few AOML files (ex: 1900022) which use the char(0) character as fill value instead of the blank character (char(32))
            profStruct.piName = strtrim(piName(idPrim, :));
            profStruct.dac = dataCenter(idPrim, :);
            profStruct.cyNum = cycleNumber(idPrim);
            profStruct.cyNumStr = num2str(cycleNumber(idPrim));
            profStruct.dir = upper(direction(idPrim));
            profStruct.dataMode = upper(dataMode(idPrim));
            profStruct.juld = juld(idPrim);
            profStruct.juldStr = datestr(juld(idPrim)+g_cogeoac_janFirst1950InMatlab, 'yyyy-mm-ddTHH:MM:SSZ');
            profStruct.lat = latitude(idPrim);
            profStruct.latStr = sprintf('%.3f', latitude(idPrim));
            profStruct.lon = longitude(idPrim);
            profStruct.lonStr = sprintf('%.3f', longitude(idPrim));
            profStruct.data = data;
            profStruct.dataQc = dataQc;

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % interpolate_data PTS mesurements on a vertical grid

            profStruct = interpolate_data(profStruct);

            if (~isempty(profStruct.dataCsv))

               % store output profile information

               if (isempty(g_cogeoac_profTab) || (g_cogeoac_profTabId > length(g_cogeoac_profTab)))
                  g_cogeoac_profTab = cat(2, g_cogeoac_profTab, ...
                     repmat(get_prof_data_init_struct, 1, g_cogeoac_nbProfToAllocate));
               end

               g_cogeoac_profTab(g_cogeoac_profTabId) = profStruct;

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               % store additionnal information for MAT output

               if (~isempty(profStruct.dataMat))

                  wmoBox = pos_to_wmo(longitude(idPrim), latitude(idPrim));
                  if (~isnan(wmoBox))

                     profStruct.dataMat.wmoBox = wmoBox;
                     piNameVal = regexprep(strtrim(piName(idPrim, :)), ' ', '');
                     profStruct.dataMat.source = ...
                        {sprintf('%s_%03d.%s.%s', ...
                        strtrim(platformNumber(idPrim, :)), ...
                        cycleNumber(idPrim), ...
                        g_cogeoac_dacName, ...
                        piNameVal)};
                     profStruct.dataMat.dates = ...
                        {datestr(juld(idPrim) + g_cogeoac_janFirst1950InMatlab, 'yyyymmddHHMMSS')};
                     profStruct.dataMat.lat = latitude(idPrim);
                     long360 = longitude(idPrim);
                     if (long360 < 0)
                        long360 = long360 + 360;
                     end
                     profStruct.dataMat.long = long360;

                     % remove padding values in measurements
                     dataMat = [pres(:, idPrim), temp(:, idPrim), psal(:, idPrim), presAdj(:, idPrim), tempAdj(:, idPrim), psalAdj(:, idPrim)];

                     presMatQc = presAdjQc(:, idPrim);
                     tempMatQc = tempAdjQc(:, idPrim);
                     psalMatQc = psalAdjQc(:, idPrim);
                     presMatQc((presMatQc == ' ')) = '7'; % QC='7' not used in Argo
                     tempMatQc((tempMatQc == ' ')) = '7'; % QC='7' not used in Argo
                     psalMatQc((psalMatQc == ' ')) = '7'; % QC='7' not used in Argo

                     dataMatQc = [str2num(presMatQc), str2num(tempMatQc), str2num(psalMatQc)];
                     idDel = find((dataMatQc(:, 1) == 7) & (dataMatQc(:, 2) == 7) & (dataMatQc(:, 3) == 7));
                     dataMat(idDel, :) = [];
                     dataMatQc(idDel, :) = [];
                     dataMat(dataMat == MEAS_FV) = nan;

                     profStruct.dataMat.nbLev = size(dataMat, 1);

                     profStruct.dataMat.preso = dataMat(:, 1);
                     profStruct.dataMat.tempo = dataMat(:, 2);
                     profStruct.dataMat.salo = dataMat(:, 3);

                     profStruct.dataMat.presadj = dataMat(:, 4);
                     profStruct.dataMat.tempadj = dataMat(:, 5);
                     profStruct.dataMat.saladj = dataMat(:, 6);

                     profStruct.dataMat.presadjqc = dataMatQc(:, 1);
                     profStruct.dataMat.tempadjqc = dataMatQc(:, 2);
                     profStruct.dataMat.saladjqc = dataMatQc(:, 3);

                     g_cogeoac_profTab(g_cogeoac_profTabId).dataMat = profStruct.dataMat;

                     g_cogeoac_nbOutputProfMatExpected = g_cogeoac_nbOutputProfMatExpected + 1;
                  else

                     % not sure to select all location inconsistencies
                     % already managed inconsistencies are:
                     % AOML 4901542 #245A positionQc=8 and latitude=longitude=FV
                     % Coriolis 6902829 #102A positionQc=1 and latitude=longitude=FV
                     fprintf('ERROR: Bad location for float #%s cycle#%d%c - present in CSV output but not in MAT output\n', ...
                        profStruct.wmo, ...
                        profStruct.cyNum, ...
                        profStruct.dir);

                     g_cogeoac_profTab(g_cogeoac_profTabId).dataMat = [];
                  end
               end

               g_cogeoac_profTabId = g_cogeoac_profTabId + 1;
            end
         end
      else
         if (g_cogeoac_verboseMode)
            if (~isempty(pres) && ~isempty(temp))
               fprintf('INFO: Only PT in file : %s\n', a_profFilePathName);
            end
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Interpolate profile PTS data on a vertical grid.
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
%   11/25/2024 - RNU - creation (from "Annie Wong, January 2024" code)
% ------------------------------------------------------------------------------
function [o_profStruct] = interpolate_data(a_profStruct)

% output parameters initialization
o_profStruct = a_profStruct;

global g_cogeoac_coreLevels;
global g_cogeoac_pTolerance;

% berbose mode (for additionnal information on ignored data)
global g_cogeoac_verboseMode;

% input parameters
global g_cogeoac_generateOutputMatFlag;


% fillValue of PTS measurements (not retrieved from NetCDF file to speed up the
% process)
MEAS_FV = single(99999);

% threshold to select data
DENSITY_INVERSION_THRESHOLD = -0.03;
SIGMA_TOLERANCE = 1;

coreLevels = g_cogeoac_coreLevels;
pTolerance = g_cogeoac_pTolerance;

inputData = a_profStruct.data;
inputDataQc = a_profStruct.dataQc;

% select data for CSV output
% keep only Qc = '1' data
inputData(inputDataQc ~= 1) = nan;
% keep only data with PTS provided
inputData(inputData == MEAS_FV) = nan;
inputData(any(isnan(inputData(:, 1:3)), 2), :) = [];

if (~isempty(inputData))

   % set EasyOneArgoTS CSV output parameter
   o_profStruct.dataCsv = inputData;

   idGood = find(inputData(:, 1) > 0); % BM2020 does not support negative pressures
   if (length(idGood) > 4) % BM2020 requires at least 5 points

      pres = inputData(idGood, 1);
      temp = inputData(idGood, 2);
      psal = inputData(idGood, 3);
      paramErr = inputData(idGood, 4:6);

      % BM2020 requires pressure increases monotonically, exclude density inversions > 0.03kg/m3
      diffPres = diff(pres);
      sigma = sw_pden(psal, temp, pres, 1000) - 1000; % use sigma1 here
      diffSigma = diff(sigma);

      if ~(any(diffPres <= 0) || any(diffSigma < DENSITY_INVERSION_THRESHOLD))

         [SA, ~] = gsw_SA_from_SP(psal, pres, a_profStruct.lon, a_profStruct.lat);
         CT = gsw_CT_from_t(SA, temp, pres);
         [SA_i, CT_i] = gsw_SA_CT_interp(SA, CT, pres, coreLevels);
         [S_i, ~] = gsw_SP_from_SA(SA_i, coreLevels, a_profStruct.lon, a_profStruct.lat);
         T_i = gsw_t_from_CT(SA_i, CT_i, coreLevels);
         tInSitu = T_i;
         sPractical = S_i;

         % toss out points outside of input profile end points
         idOut = find((coreLevels < min(pres)) | (coreLevels > max(pres)));
         tInSitu(idOut) = nan;
         sPractical(idOut) = nan;

         pToleranceLookup = interp1(coreLevels, pTolerance, pres(1:end-1), 'linear');
         for idLev = 1:length(pres)-1
            % toss out points where input pressure gap is greater than tolerance
            if (diffPres(idLev) > pToleranceLookup(idLev))
               idDel = find((coreLevels > pres(idLev) & (coreLevels < pres(idLev+1))));
               tInSitu(idDel) = nan;
               sPractical(idDel) = nan;
            end
            % toss out points where input sigma gap is greater than tolerance
            if (diffSigma(idLev) > SIGMA_TOLERANCE)
               idDel = find((coreLevels > pres(idLev) & (coreLevels < pres(idLev+1))));
               tInSitu(idDel) = nan;
               sPractical(idDel) = nan;
            end
         end

         % manage parameter error
         grdParamErr = nan(size(coreLevels, 1), 3);

         intParamList = [];
         for id = 1:3
            if (all(~isnan(paramErr(:, id))))
               if (isscalar(unique(paramErr(:, id))))
                  grdParamErr(:, id) = paramErr(1, id); % error constant
               else
                  intParamList = [intParamList, id]; % error not constant
               end
            end
         end

         if (~isempty(intParamList))

            % we need to find the levels of each grid PRES neighbors in input data
            idAbove = nan(size(coreLevels));
            idBelow = nan(size(coreLevels));
            idCheckList = find((coreLevels >= min(pres)) & (coreLevels <= max(pres)));
            for id = idCheckList'
               lev = coreLevels(id);
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
                  grdParamErr(id, idInt) = max(paramErr(idAbove(id), idInt), paramErr(idBelow(id), idInt));
               end
            end
         end

         % set EasyOneArgoTSLite CSV output parameter
         dataGrid = [coreLevels, tInSitu, sPractical, grdParamErr];

         % remove levels below the deepest useful one
         idNan = find(any(isnan(dataGrid(:, 1:3)), 2));
         if (any(idNan == size(dataGrid, 1)))
            firstUsefulUd = find(diff(flipud(idNan)) ~= -1, 1, 'first');
            lastUseful = size(dataGrid, 1) - firstUsefulUd;
            dataGrid(lastUseful+1:end, :) = [];
         else
            lastUseful = size(dataGrid, 1);
         end

         % set grdParamErr to Nan in useless levels
         idToNan = find(any(isnan(dataGrid(1:lastUseful, 1:3)), 2));
         dataGrid(idToNan, 4:end) = nan(length(idToNan), 3);

         o_profStruct.dataGrid = dataGrid;

         % set EasyOneArgoTSLite_audit MAT output parameter
         if (g_cogeoac_generateOutputMatFlag ==1)
            if ((o_profStruct.dir == 'A') && (o_profStruct.dataMode == 'D'))

               o_profStruct.dataMat = get_mat_prof_data_init_struct;
               o_profStruct.dataMat.templite = tInSitu;
               o_profStruct.dataMat.sallite = sPractical;
            end
         end

      else
         if (g_cogeoac_verboseMode)
            if (any(diffPres <= 0))
               fprintf('INFO: Profile %s_%s_%c_%c not interpolated (no monotonically increasing)\n', ...
                  a_profStruct.wmo, ...
                  a_profStruct.cyNumStr, ...
                  a_profStruct.dir, ...
                  a_profStruct.dataMode);
            end
            if (any(diffSigma < DENSITY_INVERSION_THRESHOLD))
               fprintf('INFO: Profile %s_%s_%c_%c not interpolated (density inversion)\n', ...
                  a_profStruct.wmo, ...
                  a_profStruct.cyNumStr, ...
                  a_profStruct.dir, ...
                  a_profStruct.dataMode);
            end
         end
      end
   else
      if (g_cogeoac_verboseMode)
         fprintf('INFO: Profile %s_%s_%c_%c not interpolated (only %d levels)\n', ...
            a_profStruct.wmo, ...
            a_profStruct.cyNumStr, ...
            a_profStruct.dir, ...
            a_profStruct.dataMode, ...
            length(idGood));
      end
   end
end

return

% ------------------------------------------------------------------------------
% Print output CSV/MAT files.
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
%   11/25/2024 - RNU - creation
% ------------------------------------------------------------------------------
function print_output_file

global g_cogeoac_dirOutputCsvFileData;
global g_cogeoac_dirOutputCsvFileLiteData;
global g_cogeoac_dirOutputMatFile;

global g_cogeoac_indexFile;
global g_cogeoac_indexFileLite;

global g_cogeoac_nowUtcStr;
global g_cogeoac_inputDataDoi;

global g_cogeoac_profTab;
global g_cogeoac_profTabId;

% number of output files generated
global g_cogeoac_nbOutputFiles;
global g_cogeoac_nbOutputFilesLite;

% program version
global g_cogeoac_generateEasyOneArgoCoreVersion;

% number to create a unique Id for temporary output MAT file names
global g_cogeoac_tempoOutPutMatId;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create output CSV files

matOutputData = repmat(get_mat_prof_data_init_struct, 1, g_cogeoac_profTabId-1);
matOutputDataCpt = 1;
for idP = 1:g_cogeoac_profTabId-1
   prof = g_cogeoac_profTab(idP);

   header = cell(14, 1);
   header{1} = '#format EasyOneArgoTS';
   header{2} = ['#creation_date ' g_cogeoac_nowUtcStr];
   header{3} = '#creation_centre Ifremer';
   header{4} = '#creation_centre_pid https://ror.org/044jxhp58';
   header{5} = ['#data_source_doi ' g_cogeoac_inputDataDoi];
   header{6} = ['#data_centre ' prof.dac];
   header{7} = ['#platform_number ' prof.wmo];
   header{8} = ['#cycle_number ' prof.cyNumStr];
   header{9} = ['#direction_of_profile ' prof.dir];
   header{10} = ['#data_mode ' prof.dataMode];
   header{11} = ['#profile_date ' prof.juldStr];
   header{12} = ['#profile_latitude ' prof.latStr];
   header{13} = ['#profile_longitude ' prof.lonStr];
   header{14} = '#pressure =  sea water pressure equals 0 at sea-level';
   header{15} = '#temperature = sea temperature in-situ ITS-90 scale';
   header{16} = '#salinity = practical salinity';

   header{17} = 'pressure (decibar),temperature (degree_celsius),salinity (dimensionless),pressure_error (decibar),temperature_error (degree_celsius),salinity_error (dimensionless)';


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % create EasyOneArgoTS file
   if (~isempty(prof.dataCsv))

      fmtParam = [{'%.2f'} {',%.3f'} {',%.3f'} {',%.2f'} {',%.3f'} {',%.3f'}];
      data = prof.dataCsv;
      dataStr = cell(size(data, 1), 1);
      fmtData = repmat(fmtParam, size(data, 1), 1);
      fmtData(isnan(data)) = {','};
      for idL = 1:size(data, 1)
         dataL = data(idL, :);
         dataL(isnan(dataL)) = [];
         dataStr{idL} = sprintf([fmtData{idL, :}], dataL);
      end

      % create the float directory
      dirOutputCsvFloatName = [g_cogeoac_dirOutputCsvFileData '/' prof.wmo];
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
      csvFilepathName = [dirOutputCsvFloatName '/' csvFileBaseName 'EasyTS.csv'];
      fId = fopen(csvFilepathName, 'wt');
      if (fId == -1)
         fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
         return
      end

      fprintf(fId, '%s\n', header{:});
      fprintf(fId, '%s\n', dataStr{:});

      fclose(fId);
      g_cogeoac_nbOutputFiles = g_cogeoac_nbOutputFiles + 1;
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % create EasyOneArgoTSLite file
   if (~isempty(prof.dataGrid))

      header{1} = '#format EasyOneArgoTSLite';

      fmtParam = [{'%.2f'} {',%.3f'} {',%.3f'} {',%.2f'} {',%.3f'} {',%.3f'}];
      data = prof.dataGrid;
      dataStr = cell(size(data, 1), 1);
      fmtData = repmat(fmtParam, size(data, 1), 1);
      fmtData(isnan(data)) = {','};
      for idL = 1:size(data, 1)
         dataL = data(idL, :);
         dataL(isnan(dataL)) = [];
         dataStr{idL} = sprintf([fmtData{idL, :}], dataL);
      end

      % create the float directory
      dirOutputCsvFloatName = [g_cogeoac_dirOutputCsvFileLiteData '/' prof.wmo];
      if ~(exist(dirOutputCsvFloatName, 'dir') == 7)
         mkdir(dirOutputCsvFloatName);
      end

      % create output CSV file
      csvFilepathName = [dirOutputCsvFloatName '/' csvFileBaseName  'EasyTSLite.csv'];
      fId = fopen(csvFilepathName, 'wt');
      if (fId == -1)
         fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
         return
      end

      fprintf(fId, '%s\n', header{:});
      fprintf(fId, '%s\n', dataStr{:});

      fclose(fId);
      g_cogeoac_nbOutputFilesLite = g_cogeoac_nbOutputFilesLite + 1;
   end

   % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % store MAT output data
   if (~isempty(prof.dataMat))
      matOutputData(matOutputDataCpt) = prof.dataMat;
      matOutputDataCpt = matOutputDataCpt + 1;
   end
end
matOutputData(matOutputDataCpt:end) = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create output CSV index files

if ~(exist(g_cogeoac_indexFile, 'file') == 2)

   header = cell(5, 1);
   header{1} = '#format EasyOneArgoTSIndexList';
   header{2} = ['#creation_date ' g_cogeoac_nowUtcStr];
   header{3} = '#creation_centre Ifremer';
   header{4} = '#creation_centre_pid https://ror.org/044jxhp58';
   header{5} = ['#creation_tool_version ' g_cogeoac_generateEasyOneArgoCoreVersion];
   header{6} = 'data_centre,platform_number,cycle_number,direction_of_profile,data_mode,profile_date,profile_latitude,profile_longitude';

   fId = fopen(g_cogeoac_indexFile, 'wt');
   if (fId == -1)
      fprintf('ERROR: Error while creating file : %s\n', g_cogeoac_indexFile);
      return
   end
   fprintf(fId, '%s\n', header{:});
   fclose(fId);
end
if ~(exist(g_cogeoac_indexFileLite, 'file') == 2)

   header{1} = '#format EasyOneArgoTSLiteIndexList';

   fId = fopen(g_cogeoac_indexFileLite, 'wt');
   if (fId == -1)
      fprintf('ERROR: Error while creating file : %s\n', g_cogeoac_indexFileLite);
      return
   end
   fprintf(fId, '%s\n', header{:});
   fclose(fId);
end

fId = fopen(g_cogeoac_indexFile, 'at');
if (fId == -1)
   fprintf('ERROR: Error while creating file : %s\n', g_cogeoac_indexFile);
   return
end

fIdLite = fopen(g_cogeoac_indexFileLite, 'at');
if (fIdLite == -1)
   fprintf('ERROR: Error while creating file : %s\n', g_cogeoac_indexFileLite);
   return
end

for idP = 1:g_cogeoac_profTabId-1
   prof = g_cogeoac_profTab(idP);

   fprintf(fId, '%s,%s,%s,%c,%c,%s,%s,%s\n', ...
      prof.dac, ...
      prof.wmo, ...
      prof.cyNumStr, ...
      prof.dir, ...
      prof.dataMode, ...
      prof.juldStr, ...
      prof.latStr, ...
      prof.lonStr);

   if (~isempty(prof.dataGrid))

      fprintf(fIdLite, '%s,%s,%s,%c,%c,%s,%s,%s\n', ...
         prof.dac, ...
         prof.wmo, ...
         prof.cyNumStr, ...
         prof.dir, ...
         prof.dataMode, ...
         prof.juldStr, ...
         prof.latStr, ...
         prof.lonStr);
   end
end

fclose(fId);
fclose(fIdLite);

g_cogeoac_profTab(1:g_cogeoac_profTabId-1) = [];
g_cogeoac_profTabId = 1;

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

      profBox.preso = nan(profBox.nbLev, length(idProf));
      profBox.presadj = nan(profBox.nbLev, length(idProf));
      profBox.presadjqc = repmat(' ', profBox.nbLev, length(idProf));
      profBox.tempo = nan(profBox.nbLev, length(idProf));
      profBox.tempadj = nan(profBox.nbLev, length(idProf));
      profBox.tempadjqc = repmat(' ', profBox.nbLev, length(idProf));
      profBox.salo = nan(profBox.nbLev, length(idProf));
      profBox.saladj = nan(profBox.nbLev, length(idProf));
      profBox.saladjqc = repmat(' ', profBox.nbLev, length(idProf));

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
      end

      % create output MAT file
      matFileName = sprintf('%d_%d_%d_%d_tempo.mat', ...
         boxNum, profBox.nbLev, size(profBox.preso, 2), g_cogeoac_tempoOutPutMatId);
      matFilePathName = [g_cogeoac_dirOutputMatFile '/' matFileName];
      save(matFilePathName, '-struct', 'profBox');
      g_cogeoac_tempoOutPutMatId = g_cogeoac_tempoOutPutMatId + 1;
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
global g_cogeoac_generateOutputMatFlag;
global g_cogeoac_dirOutputMatFile;

global g_cogeoac_coreLevels;

% number of output files generated
global g_cogeoac_nbOutputFilesMat;
global g_cogeoac_nbOutputProfMat;


if (g_cogeoac_generateOutputMatFlag == 0)
   return
end

% look for temporary output MAT files and retrieve information from their names
tempMatFileNames = dir([g_cogeoac_dirOutputMatFile '/*_tempo.mat']);
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

   profBox.preslitelevels = g_cogeoac_coreLevels;
   profBox.templite = nan(length(g_cogeoac_coreLevels), nbProf);
   profBox.sallite = nan(length(g_cogeoac_coreLevels), nbProf);

   profBox.preso = nan(nbLev, nbProf);
   profBox.presadj = nan(nbLev, nbProf);
   profBox.presadjqc = repmat(' ', nbLev, nbProf);
   profBox.tempo = nan(nbLev, nbProf);
   profBox.tempadj = nan(nbLev, nbProf);
   profBox.tempadjqc = repmat(' ', nbLev, nbProf);
   profBox.salo = nan(nbLev, nbProf);
   profBox.saladj = nan(nbLev, nbProf);
   profBox.saladjqc = repmat(' ', nbLev, nbProf);

   fistId = 1;
   for idP = 1:length(idProf)

      tempMatFileName = [g_cogeoac_dirOutputMatFile '/' fileNameList{idProf(idP)}];
      profBoxIn = load(tempMatFileName);

      lastId = fistId + nbProfList(idProf(idP)) - 1;

      profBox.source(fistId:lastId) = profBoxIn.source;
      profBox.dates(fistId:lastId) = profBoxIn.dates;
      profBox.lat(fistId:lastId) = profBoxIn.lat;
      profBox.long(fistId:lastId) = profBoxIn.long;

      profBox.templite(:, fistId:lastId) = profBoxIn.templite;
      profBox.sallite(:, fistId:lastId) = profBoxIn.sallite;

      profBox.preso(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.preso;
      profBox.presadj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.presadj;
      profBox.presadjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.presadjqc;
      profBox.tempo(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.tempo;
      profBox.tempadj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.tempadj;
      profBox.tempadjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.tempadjqc;
      profBox.salo(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.salo;
      profBox.saladj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.saladj;
      profBox.saladjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.saladjqc;

      fistId = fistId + nbProfList(idProf(idP));

      % remove current temporary output MAT file
      delete(tempMatFileName);
   end

   % create output MAT file
   matFileName = sprintf('audit_%d.mat', boxNum);
   matFilePathName = [g_cogeoac_dirOutputMatFile '/' matFileName];
   save(matFilePathName, '-struct', 'profBox', ...
      'source', 'dates', 'lat', 'long', ...
      'preslitelevels', 'templite', 'sallite', ...
      'preso', 'presadj', 'presadjqc', ...
      'tempo', 'tempadj', 'tempadjqc', ...
      'salo', 'saladj', 'saladjqc');

   g_cogeoac_nbOutputProfMat = g_cogeoac_nbOutputProfMat + nbProf;
   g_cogeoac_nbOutputFilesMat = g_cogeoac_nbOutputFilesMat + 1;
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
% Load interpolation reference data.
%
% SYNTAX :
%  load_core_levels_ref
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
function load_core_levels_ref

global g_cogeoac_coreLevels;
global g_cogeoac_pTolerance;

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

g_cogeoac_coreLevels = levels(:, 1);
g_cogeoac_pTolerance = levels(:, 2);

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
%   11/25/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profDataStruct] = get_prof_data_init_struct

% output parameters initialization
o_profDataStruct = struct( ...
   'wmo', '', ...
   'piName', '', ...
   'dac', '', ...
   'cyNum', '', ...
   'cyNumStr', '', ...
   'dir', '', ...
   'dataMode', '', ...
   'juld', '', ...
   'juldStr', '', ...
   'lat', '', ...
   'latStr', '', ...
   'lon', '', ...
   'lonStr', '', ...
   'data', [], ...
   'dataQc', [], ...
   'dataCsv', [], ...
   'dataGrid', [], ...
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
%   11/25/2024 - RNU - creation
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
   'preso', '', ...
   'presadj', '', ...
   'presadjqc', '', ...
   'preslitelevels', '', ...
   'tempo', '', ...
   'tempadj', '', ...
   'tempadjqc', '', ...
   'templite', '', ...
   'salo', '', ...
   'saladj', '', ...
   'saladjqc', '', ...
   'sallite', '');

return

% ------------------------------------------------------------------------------
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
%   11/25/2024 - RNU - creation
% ------------------------------------------------------------------------------
function init_xml_report(a_time)

% DOM node of XML report
global g_cogeoac_xmlReportDOMNode;

% program version
global g_cogeoac_generateEasyOneArgoCoreVersion;


% initialize XML report
docNode = com.mathworks.xml.XMLUtils.createDocument('coriolis_function_report');
docRootNode = docNode.getDocumentElement;

newChild = docNode.createElement('function');
newChild.appendChild(docNode.createTextNode('CO-05-08-16-01'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('comment');
newChild.appendChild(docNode.createTextNode('Argo Coriolis Easy OneArgo core generator (generate_easy_one_argo_core)'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('tool_version');
newChild.appendChild(docNode.createTextNode(g_cogeoac_generateEasyOneArgoCoreVersion));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('date');
newChild.appendChild(docNode.createTextNode(datestr(datenum(a_time, 'yyyymmddTHHMMSSZ'), 'dd/mm/yyyy HH:MM:SS')));
docRootNode.appendChild(newChild);

g_cogeoac_xmlReportDOMNode = docNode;

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
%   11/25/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_inputError] = parse_input_param(a_varargin)

% output parameters initialization
o_inputError = 0;

global g_cogeoac_dirInputNcFiles;
global g_cogeoac_inputDataDoi;
global g_cogeoac_dirOutputCsvFiles;
global g_cogeoac_dirLogFile;
global g_cogeoac_dirOutputXmlFile;
global g_cogeoac_xmlReportFileName;
global g_cogeoac_generateOutputMatFlag;
global g_cogeoac_dirOutputMatFiles;

g_cogeoac_dirInputNcFiles = [];
g_cogeoac_inputDataDoi = [];
g_cogeoac_dirOutputCsvFiles = [];
g_cogeoac_dirLogFile = [];
g_cogeoac_dirOutputXmlFile = [];
g_cogeoac_xmlReportFileName = [];
g_cogeoac_generateOutputMatFlag = [];
g_cogeoac_dirOutputMatFiles = [];


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
            g_cogeoac_dirInputNcFiles = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'inputDataDoi'))
            g_cogeoac_inputDataDoi = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'csvOutputDir'))
            g_cogeoac_dirOutputCsvFiles = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'logDir'))
            g_cogeoac_dirLogFile = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'xmlReportDir'))
            g_cogeoac_dirOutputXmlFile = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'xmlReportName'))
            g_cogeoac_xmlReportFileName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'generateOutputMatFlag'))
            g_cogeoac_generateOutputMatFlag = str2double(a_varargin{id+1});
         elseif (strcmpi(a_varargin{id}, 'matOutputDir'))
            g_cogeoac_dirOutputMatFiles = a_varargin{id+1};
         else
            fprintf('WARNING: unexpected input argument (%s) - ignored\n', a_varargin{id});
         end
      end
   end
end

% check the xml report file name consistency
if (~isempty(g_cogeoac_xmlReportFileName))
   if (length(g_cogeoac_xmlReportFileName) < 29)
      fprintf('WARNING: inconsistent xml report file name (%s) expecting coXXXXXX_yyyymmddTHHMMSSZ[_PID].xml - ignored\n', g_cogeoac_xmlReportFileName);
      g_cogeoac_xmlReportFileName = [];
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
%   11/25/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_status] = finalize_xml_report(a_ticStartTime, a_logFileName, a_error)

% DOM node of XML report
global g_cogeoac_xmlReportDOMNode;

% number of input files processed
global g_cogeoac_nbInputFiles;

% number of output files generated
global g_cogeoac_nbOutputFiles;
global g_cogeoac_nbOutputFilesLite;
global g_cogeoac_nbOutputFilesMat;
global g_cogeoac_nbOutputProfMatExpected;
global g_cogeoac_nbOutputProfMat;

% user report files
global g_cogeoac_reportFile;
global g_cogeoac_reportFileLite;

% program version
global g_cogeoac_generateEasyOneArgoCoreVersion;

% date of the run
global g_cogeoac_nowUtcStr;


% initalize final status
o_status = 'ok';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% finalize the xml report

docNode = g_cogeoac_xmlReportDOMNode;
docRootNode = docNode.getDocumentElement;

nbInputFiles = g_cogeoac_nbInputFiles;
nbOutputFiles = g_cogeoac_nbOutputFiles;
nbOutputFilesLite = g_cogeoac_nbOutputFilesLite;
nbOutputFilesMat = g_cogeoac_nbOutputFilesMat;
nbOutputProfMatExpected = g_cogeoac_nbOutputProfMatExpected;
nbOutputProfMat = g_cogeoac_nbOutputProfMat;

% retrieve information from the log file
[infoMsg, warningMsg, errorMsg] = parse_log_file(a_logFileName);

error = a_error;

duration = format_time(toc(a_ticStartTime)/3600);

newChild = docNode.createElement('Nb_input_nc_files');
% textNode = ['Number of input Argo profile NetCDF files: ' num2str(nbInputFiles)];
textNode = num2str(nbInputFiles);
newChild.appendChild(docNode.createTextNode(textNode));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('Nb_output_csv_files_EasyOneArgoTS');
% textNode = ['Number of output CSV files in the EasyOneArgoTS dataset: ' num2str(nbOutputFiles)];
textNode = num2str(nbOutputFiles);
newChild.appendChild(docNode.createTextNode(textNode));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('Nb_output_csv_files_EasyOneArgoTSLite');
% textNode = ['Number of output CSV files in the EasyOneArgoTSLite dataset: ' num2str(nbOutputFilesLite)];
textNode = num2str(nbOutputFilesLite);
newChild.appendChild(docNode.createTextNode(textNode));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('Nb_output_mat_files_EasyOneArgoTSLite_audit');
% textNode = ['Number of output mat files in the EasyOneArgoTSLite audit dataset: ' num2str(nbOutputFilesMat)];
textNode = num2str(nbOutputFilesMat);
newChild.appendChild(docNode.createTextNode(textNode));
docRootNode.appendChild(newChild);

% newChild = docNode.createElement('Nb_output_mat_profiles_expected_EasyOneArgoTSLite_audit');
% newChild.appendChild(docNode.createTextNode(num2str(nbOutputProfMatExpected)));
% docRootNode.appendChild(newChild);

newChild = docNode.createElement('Nb_output_mat_profiles_EasyOneArgoTSLite_audit');
% textNode = ['Number of output profiles in the EasyOneArgoTSLite audit dataset: ' num2str(nbOutputProfMat)];
textNode = num2str(nbOutputProfMat);
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

fId = fopen(g_cogeoac_reportFile, 'wt');
if (fId == -1)
   fprintf('ERROR: Error while creating file : %s\n', g_cogeoac_reportFile);
   return
end

fprintf(fId, 'Generator version number: %s\n', g_cogeoac_generateEasyOneArgoCoreVersion);
fprintf(fId, 'Run date: %s\n', g_cogeoac_nowUtcStr);
fprintf(fId, 'Run time: %s\n', duration);
fprintf(fId, 'Number of input Argo profile NetCDF files: %d\n', nbInputFiles);
fprintf(fId, 'Number of output CSV files in the EasyOneArgoTS dataset: %d\n', nbOutputFiles);

fclose(fId);

fId = fopen(g_cogeoac_reportFileLite, 'wt');
if (fId == -1)
   fprintf('ERROR: Error while creating file : %s\n', g_cogeoac_reportFileLite);
   return
end

fprintf(fId, 'Generator version number: %s\n', g_cogeoac_generateEasyOneArgoCoreVersion);
fprintf(fId, 'Run date: %s\n', g_cogeoac_nowUtcStr);
fprintf(fId, 'Run time: %s\n', duration);
fprintf(fId, 'Number of input Argo profile NetCDF files: %d\n', nbInputFiles);
fprintf(fId, 'Number of output CSV files in the EasyOneArgoTSLite dataset: %d\n', nbOutputFilesLite);

fclose(fId);

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
