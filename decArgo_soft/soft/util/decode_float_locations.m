% ------------------------------------------------------------------------------
% Decode float GPS locations.
% Used to decode EOL data of a float to be recovered, the tool:
%   1- duplicates input files from a RSYNC directory (and a SPOOL directory if any)
%   2- decodes the GPS locations of the duplicated input files
%   3- generates an output CSV file of decoded GPS times and locations
%
% SYNTAX :
%   decode_float_locations(6902899)
%
% INPUT PARAMETERS :
%   varargin : WMO number of float to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/19/2021 - RNU - creation: floats CTS4 not Ice, APF11 IR RUDICS, CTS3 5.75
%   05/31/2021 - RNU - added float Arvor DEEP 5.62
%   10/04/2021 - RNU - added float Arvor DEEP 5.64
% ------------------------------------------------------------------------------
function decode_float_locations(varargin)

% to switch between Coriolis and JPR configurations
CORIOLIS_CONFIGURATION_FLAG = 0;

if (CORIOLIS_CONFIGURATION_FLAG)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % CORIOLIS CONFIGURATION - START
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % directory of JSON float information files
   DIR_INPUT_JSON_FLOAT_INFORMATION_FILES = '/home/coriolis_exp/binlx/co04/co0414/co041404/decArgo_config_floats/json_float_info/';
   
   % directory to store the log file
   DIR_LOG_FILE = '/home/coriolis_exp/spool/co04/co0414/co041404/recovery/log/';
   
   % directory to store the CSV file
   DIR_CSV_FILE = '/home/coriolis_exp/spool/co04/co0414/co041404/recovery/csv/';
   
   % maximum age of input files to consider (in hours)
   MAX_FILE_AGE_IN_HOUR = 30*24;
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % IRIDIUM SBD CONFIGURATION - START
   
   % rsync directory
   DIR_INPUT_RSYNC_DATA_IRIDIUM_SBD = '/home/coriolis_exp/spool/co01/co0101/co010106/archive/cycle/';
   
   % spool directory
   DIR_INPUT_SPOOL_DATA_IRIDIUM_SBD = '/home/coriolis_exp/spool/co01/co0101/co010106/message/';
   
   % directory to store duplicated mail files
   DIR_OUTPUT_DATA_IRIDIUM_SBD = '/home/coriolis_exp/spool/co04/co0414/co041404/recovery/iridium/';
   
   % IRIDIUM SBD CONFIGURATION - END
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % APF11 RUDICS CONFIGURATION - START
   
   % rsync directory
   DIR_INPUT_RSYNC_DATA_APF11_RUDICS = '/home/coriolis_exp/spool/co01/co0101/co010108/archive/cycle/';
   
   % spool directory
   DIR_INPUT_SPOOL_DATA_APF11_RUDICS = '';
   
   % directory to store duplicated mail files
   DIR_OUTPUT_DATA_APF11_RUDICS = '/home/coriolis_exp/spool/co04/co0414/co041404/recovery/iridium/';
   
   % APF11 RUDICS CONFIGURATION - END
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % REMOCEAN SBD CONFIGURATION - START
   
   % rsync directory
   DIR_INPUT_RSYNC_DATA_REMOCEAN_SBD = '/home/coriolis_exp/spool/co01/co0101/co010111/rsync/';
   
   % spool directory
   DIR_INPUT_SPOOL_DATA_REMOCEAN_SBD = '';
   
   % directory to store duplicated mail files
   DIR_OUTPUT_DATA_REMOCEAN_SBD = '/home/coriolis_exp/spool/co04/co0414/co041404/recovery/iridium/';
   
   % REMOCEAN SBD CONFIGURATION - END
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % PROVOR CTS5 CONFIGURATION - START
   
   % rsync directory
   DIR_INPUT_RSYNC_DATA_CTS5 = '/home/coriolis_exp/spool/co01/co0101/co010111/rsync/';
   
   % spool directory
   DIR_INPUT_SPOOL_DATA_CTS5 = '';
   
   % directory to store duplicated mail files
   DIR_OUTPUT_DATA_CTS5 = '/home/coriolis_exp/spool/co04/co0414/co041404/recovery/iridium/';
   
   % PROVOR CTS5 CONFIGURATION - END
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % CORIOLIS CONFIGURATION - END
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
else
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % JPR CONFIGURATION - START
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % directory of JSON float information files
   DIR_INPUT_JSON_FLOAT_INFORMATION_FILES = 'C:/Users/jprannou/_DATA/IN/decArgo_config_floats/json_float_info/';
   
   % directory to store the log file
   DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';
   
   % directory to store the CSV file
   DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';
   
   % maximum age of input files to consider (in hours)
   MAX_FILE_AGE_IN_HOUR = 365*24;
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % IRIDIUM SBD CONFIGURATION - START
   
   % rsync directory
   DIR_INPUT_RSYNC_DATA_IRIDIUM_SBD = 'C:\Users\jprannou\_DATA\IN\RSYNC\CTS3\rsync_data\';
   
   % spool directory
   DIR_INPUT_SPOOL_DATA_IRIDIUM_SBD = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\FLOAT_RECOVERY\TEST_SPOOL\';
   
   % directory to store duplicated mail files
   DIR_OUTPUT_DATA_IRIDIUM_SBD = 'C:\Users\jprannou\_DATA\TEST\OUTPUT\';
   
   % IRIDIUM SBD CONFIGURATION - END
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % APF11 RUDICS CONFIGURATION - START
   
   % rsync directory
   DIR_INPUT_RSYNC_DATA_APF11_RUDICS = 'C:\Users\jprannou\_DATA\IN\RSYNC\APEX_APF11_IR_RUDICS\rsync_data\';
   
   % spool directory
   DIR_INPUT_SPOOL_DATA_APF11_RUDICS = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\FLOAT_RECOVERY\TEST_SPOOL\';
   
   % directory to store duplicated mail files
   DIR_OUTPUT_DATA_APF11_RUDICS = 'C:\Users\jprannou\_DATA\TEST\OUTPUT\';
   
   % APF11 RUDICS CONFIGURATION - END
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % REMOCEAN SBD CONFIGURATION - START
   
   % rsync directory
   DIR_INPUT_RSYNC_DATA_REMOCEAN_SBD = 'C:\Users\jprannou\_DATA\IN\RSYNC\CTS4_V1.xx_V2.xx\rsync_data\';
   
   % spool directory
   DIR_INPUT_SPOOL_DATA_REMOCEAN_SBD = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\FLOAT_RECOVERY\TEST_SPOOL\';
   
   % directory to store duplicated mail files
   DIR_OUTPUT_DATA_REMOCEAN_SBD = 'C:\Users\jprannou\_DATA\TEST\OUTPUT\';
   
   % REMOCEAN SBD CONFIGURATION - END
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % PROVOR CTS5 CONFIGURATION - START
   
   % rsync directory
   DIR_INPUT_RSYNC_DATA_CTS5 = 'C:\Users\jprannou\_DATA\IN\RSYNC\CTS5\rsync_data\';
   
   % spool directory
   DIR_INPUT_SPOOL_DATA_CTS5 = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\FLOAT_RECOVERY\TEST_SPOOL\';
   
   % directory to store duplicated mail files
   DIR_OUTPUT_DATA_CTS5 = 'C:\Users\jprannou\_DATA\TEST\OUTPUT\';
   
   % PROVOR CTS5 CONFIGURATION - END
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % JPR CONFIGURATION - END
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
end

% lists of managed decoders
global g_decArgo_decoderIdListNkeCts4NotIce;
global g_decArgo_decoderIdListNkeCts5;
global g_decArgo_decoderIdListApexApf11IridiumRudics;

% default values
global g_decArgo_janFirst1950InMatlab;

% default values initialization
init_default_values;


% list of decId already managed
decIdManagedList = [ ...
   203 ... % Arvor-deep 4000 5.62
   213 ... % Provor-ARN-DO Iridium 5.74
   214 ... % Provor-ARN-DO-Ice Iridium 5.75
   215 ... % Arvor-deep 4000 with "Near Surface" & "In Air" measurements
   g_decArgo_decoderIdListNkeCts4NotIce ... % no Ice versions of Provor CTS4
   g_decArgo_decoderIdListNkeCts5 ... % all versions of Provor CTS5
   g_decArgo_decoderIdListApexApf11IridiumRudics ... % all versions of Apex APF11 Iridium Rudics
   ];

% check inputs
if ~(exist(DIR_LOG_FILE, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s\n', DIR_LOG_FILE);
   return
end

% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

% check inputs
if ~(exist(DIR_CSV_FILE, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s\n', DIR_CSV_FILE);
   return
end

% check inputs
if ~(exist(DIR_INPUT_JSON_FLOAT_INFORMATION_FILES, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s\n', DIR_INPUT_JSON_FLOAT_INFORMATION_FILES);
   ellapsedTime = toc;
   fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);
   diary off;
   return
end

% get float WMO
if (nargin == 1)
   floatWmo = cell2mat(varargin);
else
   fprintf('ERROR: Input parameter is expected to be the float WMO number\n');
   ellapsedTime = toc;
   fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);
   diary off;
   return
end

% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'decode_float_locations_' num2str(floatWmo) '_' currentTime '.log'];
diary(logFile);
tic;

% get float JSON information file
floatInfoFileNames = dir([DIR_INPUT_JSON_FLOAT_INFORMATION_FILES '/' sprintf('%d_*_info.json', floatWmo)]);
if (length(floatInfoFileNames) == 1)
   floatInfoFileName = [DIR_INPUT_JSON_FLOAT_INFORMATION_FILES '/' floatInfoFileNames(1).name];
elseif (isempty(floatInfoFileNames))
   fprintf('ERROR: Float information file not found for float #%d\n', floatWmo);
   ellapsedTime = toc;
   fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);
   diary off;
   return
else
   fprintf('ERROR: Multiple float information files for float #%d\n', floatWmo);
   ellapsedTime = toc;
   fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);
   diary off;
   return
end

% read information file
fileContents = loadjson(floatInfoFileName);

% retrieve ptt and decoderId
if (isfield(fileContents, 'PTT'))
   floatPtt = fileContents.PTT;
else
   fprintf('ERROR: Cannot find ''PTT'' in file %s\n', floatInfoFileName);
   ellapsedTime = toc;
   fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);
   diary off;
   return
end
if (isfield(fileContents, 'DECODER_ID'))
   floatDecId = str2double(fileContents.DECODER_ID);
else
   fprintf('ERROR: Cannot find ''DECODER_ID'' in file %s\n', floatInfoFileName);
   ellapsedTime = toc;
   fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);
   diary off;
   return
end

% check that decdId is managed
if (~ismember(floatDecId, decIdManagedList))
   fprintf('ERROR: DecId #%d is not managed yet - ASK FOR AN UPDATE OF THIS TOOL\n', floatDecId);
   ellapsedTime = toc;
   fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);
   diary off;
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% duplicate input files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (ismember(floatDecId, g_decArgo_decoderIdListNkeCts4NotIce))
   duplicate_remocean_sbd_files_float_to_recover( ...
      floatWmo, ...
      floatPtt, ...
      DIR_INPUT_RSYNC_DATA_REMOCEAN_SBD, ...
      DIR_INPUT_SPOOL_DATA_REMOCEAN_SBD, ...
      DIR_OUTPUT_DATA_REMOCEAN_SBD, ...
      MAX_FILE_AGE_IN_HOUR);
elseif (ismember(floatDecId, g_decArgo_decoderIdListApexApf11IridiumRudics))
   duplicate_apx_apf11_iridium_rudics_files_float_to_recover( ...
      floatWmo, ...
      floatPtt, ...
      DIR_INPUT_RSYNC_DATA_APF11_RUDICS, ...
      DIR_INPUT_SPOOL_DATA_APF11_RUDICS, ...
      DIR_OUTPUT_DATA_APF11_RUDICS, ...
      MAX_FILE_AGE_IN_HOUR);
elseif (ismember(floatDecId, g_decArgo_decoderIdListNkeCts5))
   duplicate_cts5_files_float_to_recover( ...
      floatWmo, ...
      floatPtt, ...
      DIR_INPUT_RSYNC_DATA_CTS5, ...
      DIR_INPUT_SPOOL_DATA_CTS5, ...
      DIR_OUTPUT_DATA_CTS5, ...
      MAX_FILE_AGE_IN_HOUR);
else
   switch (floatDecId)
      case {203, 213, 214, 215}
         duplicate_iridium_mail_files_float_to_recover( ...
            floatWmo, ...
            floatPtt, ...
            DIR_INPUT_RSYNC_DATA_IRIDIUM_SBD, ...
            DIR_INPUT_SPOOL_DATA_IRIDIUM_SBD, ...
            DIR_OUTPUT_DATA_IRIDIUM_SBD, ...
            MAX_FILE_AGE_IN_HOUR);
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% decode float locations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (ismember(floatDecId, g_decArgo_decoderIdListNkeCts4NotIce))
   [decodedDataTab] = decode_float_location_remocean_sbd(floatWmo, floatPtt, DIR_OUTPUT_DATA_REMOCEAN_SBD);
elseif (ismember(floatDecId, g_decArgo_decoderIdListApexApf11IridiumRudics))
   [decodedDataTab] = decode_float_location_apf11_rudics(floatWmo, floatPtt, DIR_OUTPUT_DATA_APF11_RUDICS);
elseif (ismember(floatDecId, g_decArgo_decoderIdListNkeCts5))
   [decodedDataTab] = decode_float_location_cts5(floatDecId, floatWmo, floatPtt, DIR_OUTPUT_DATA_CTS5);
else
   switch (floatDecId)
      case {203, 213, 214, 215}
         [decodedDataTab] = decode_float_location_iridium_sbd(floatDecId, floatWmo, floatPtt, DIR_OUTPUT_DATA_IRIDIUM_SBD);
   end
end

% sort GPS location
[~, idSort] = sort(decodedDataTab(:, 1));
decodedDataTab = decodedDataTab(idSort, :);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% generate CSV file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create the CSV output file
outputFileName = [DIR_CSV_FILE '/' 'decode_float_locations_' num2str(floatWmo) '_' currentTime '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = 'PLATFORM,DATE (yyyy-mm-ddThh:mi:ssZ),LATITUDE (degree_north),LONGITUDE (degree_east),LATITUDE (degree_north_ddm),LONGITUDE (degree_east_ddm)';
fprintf(fidOut, '%s\n', header);

for idLoc = 1:size(decodedDataTab, 1)
   [lonStr, latStr] = format_position(decodedDataTab(idLoc, 2), decodedDataTab(idLoc, 3));
   fprintf(fidOut, '%d,%s,%.4f,%.4f,%s,%s\n', ...
      floatWmo, ...
      datestr(decodedDataTab(idLoc,1)+g_decArgo_janFirst1950InMatlab, 'yyyy-mm-ddTHH:MM:SSZ'), ...
      decodedDataTab(idLoc, 3), decodedDataTab(idLoc, 2), ...
      latStr, lonStr);
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Decode GPS location for PROVOR CTS5 floats.
%
% SYNTAX :
%  [o_decodedDataTab] = decode_float_location_cts5(a_decoderId, a_floatNum, a_floatRudicsId, a_inputFileDir)
%
% INPUT PARAMETERS :
%   a_decoderId    : float decoder Id
%   a_floatNum     : float WMO number
%   a_floatImei    : float Rudics Id
%   a_inputFileDir : top directory of files to be decoded
%
% OUTPUT PARAMETERS :
%   o_decodedData : GPS data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/09/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decodedData] = decode_float_location_cts5(a_decoderId, a_floatNum, a_floatRudicsId, a_inputFileDir)

% output parameters initialization
o_decodedData = [];


% set useful directories
floatIriDirName = [a_inputFileDir '/' a_floatRudicsId '_' num2str(a_floatNum) '/'];
archiveDirectory = [floatIriDirName 'archive/'];

% process float files
fileNames = [ ...
   dir([archiveDirectory '*_autotest_*.txt']); ...
   dir([archiveDirectory '*_technical*.txt']); ...
   dir([archiveDirectory '*_default_*.txt']) ...
   ];
for idFile = 1:length(fileNames)
   fileName = fileNames(idFile).name;
   
   % read technical file
   [apmtTech, ~, ~, ~, ~] = read_apmt_technical([archiveDirectory fileName], a_decoderId);
   
   % store GPS data
   if (~isempty(apmtTech))
      if (isfield(apmtTech, 'GPS'))
         
         idF1 = find(strcmp(apmtTech.GPS.name, 'GPS location date'), 1);
         idF2 = find(strcmp(apmtTech.GPS.name, 'GPS location longitude'), 1);
         idF3 = find(strcmp(apmtTech.GPS.name, 'GPS location latitude'), 1);
         if (~isempty(idF1) && ~isempty(idF2) && ~isempty(idF3))
            o_decodedData = [o_decodedData; ...
               [apmtTech.GPS.data{idF1} apmtTech.GPS.data{idF2} apmtTech.GPS.data{idF3}]];
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Decode GPS location for Remocean floats.
%
% SYNTAX :
%  [o_decodedDataTab] = decode_float_location_remocean_sbd(a_floatNum, a_floatLoginName, a_inputFileDir)
%
% INPUT PARAMETERS :
%   a_floatNum       : float WMO number
%   a_floatLoginName : float login name
%   a_inputFileDir   : top directory of files to be decoded
%
% OUTPUT PARAMETERS :
%   o_decodedDataTab : GPS data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/20/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decodedDataTab] = decode_float_location_remocean_sbd(a_floatNum, a_floatLoginName, a_inputFileDir)

% output parameters initialization
o_decodedDataTab = [];

% set useful directories
floatIriDirName = [a_inputFileDir '/' a_floatLoginName '_' num2str(a_floatNum) '/'];
archiveDirectory = [floatIriDirName 'archive/'];

% process sbd files
sbdFiles = [ ...
   dir([archiveDirectory '/' sprintf('*_%s_*.b64', a_floatLoginName)]); ...
   dir([archiveDirectory '/' sprintf('*_%s_*.bin', a_floatLoginName)])];
for idFile = 1:length(sbdFiles)
   sbdFileName = sbdFiles(idFile).name;
   sbdFilePathName = [archiveDirectory '/' sbdFileName];
   
   
   % read sbd file
   fId = fopen(sbdFilePathName, 'r');
   if (fId == -1)
      fprintf('ERROR: Float #%d: Error while opening file : %s\n', ...
         a_floatNum, ...
         sbdFilePathName);
      continue
   end
   sbdData = fread(fId);
   fclose(fId);
   
   if (strcmp(sbdFileName(end-3:end), '.b64'))
      idZ = find(sbdData == 0, 1, 'first');
      if (any(sbdData(idZ:end) ~= 0))
         fprintf('ERROR: Float #%d: Inconsistent data in file : %s\n', ...
            a_floatNum, ...
            sbdFilePathName);
         continue
      end
      sbdData = double(base64decode(sbdData(1:idZ-1), '', 'matlab'));
   elseif (strcmp(sbdFileName(end-3:end), '.bin'))
      if (length(sbdData) == 1024)
         sbdData = sbdData(1:980);
      end
   end
   
   sbdDataData = [];
   if (rem(length(sbdData), 140) == 0)
      sbdData = reshape(sbdData, 140, length(sbdData)/140)';
      for idMsg = 1:size(sbdData, 1)
         data = sbdData(idMsg, :);
         if ~((isempty(find(data ~= 0, 1)) || isempty(find(data ~= 26, 1))))
            sbdDataData = [sbdDataData; data];
         end
      end
   else
      fprintf('WARNING: Float #%d: input file ignored because of unexpected size (%d bytes)  : %s\n', ...
         a_floatNum, ...
         length(sbdData), ...
         sbdFilePathName);
      continue
   end
   
   if (~isempty(sbdDataData))
      decodedData = decode_remocean_sbd_location(sbdDataData);
      if (~isempty(decodedData))
         o_decodedDataTab = [o_decodedDataTab; decodedData];
      end
   end
end

return

% ------------------------------------------------------------------------------
% Decode GPS location for Remocean floats.
%
% SYNTAX :
%  [o_decodedData] = decode_remocean_sbd_location(a_tabSensors)
%
% INPUT PARAMETERS :
%   a_tabSensors : transmitted data
%
% OUTPUT PARAMETERS :
%   o_decodedData : GPS data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/20/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decodedData] = decode_remocean_sbd_location(a_tabSensors)

% output parameters initialization
o_decodedData = [];

% default values
global g_decArgo_janFirst1950InMatlab;


% split sensor technical data packets (packet type 250 is 70 bytes length
% whereas input SBD size is 140 bytes)
tabSensors = [];
idSensorTechDataPack = find(a_tabSensors(:, 1) == 250);
for id = 1:length(idSensorTechDataPack)
   idPack = idSensorTechDataPack(id);
   
   dataPack = a_tabSensors(idPack, :);
   
   tabSensors = [tabSensors; [dataPack(1:70) repmat([0], 1, 70)]];
   
   if ~((length(unique(dataPack(71:140))) == 1) && (dataPack(71) == 255))
      tabSensors = [tabSensors; [dataPack(71:140) repmat([0], 1, 70)]];
   end
end
idOther = setdiff([1:size(a_tabSensors, 1)], idSensorTechDataPack);
tabSensors = [tabSensors; a_tabSensors(idOther, :)];

% decode packet data
for idMes = 1:size(tabSensors, 1)
   
   % packet type
   packType = tabSensors(idMes, 1);
   
   if (packType == 253)
      
      % float technical data
      
      % message data frame
      msgData = tabSensors(idMes, 2:end);
      
      % first item bit number
      firstBit = 1;
      % item bit lengths
      tabNbBits = [repmat([8], 1, 6) 16 repmat([16 16 8], 1, 3) 8 8 16 16 8 8 ...
         repmat([16], 1, 6) repmat([8], 1, 10) repmat([16], 1, 4) ...
         repmat([8], 1, 9) repmat([16], 1, 4) 8 8 8 16 16 8 16 ...
         repmat([8], 1, 7) repmat([16 8 8 8], 1, 2) 8 32 232];
      % get item bits
      tabTech = get_bits(firstBit, tabNbBits, msgData);
      
      % GPS valid fix
      gpsValidFix = tabTech(76);
      if (gpsValidFix == 0)
         continue
      end
      
      % packet date
      packJulD = datenum(sprintf('%02d%02d%02d%02d%02d%02d', tabTech(1:6)), 'ddmmyyHHMMSS') - g_decArgo_janFirst1950InMatlab;
      
      % compute GPS location
      if (tabTech(71) == 0)
         signLat = 1;
      else
         signLat = -1;
      end
      gpsLocLat = signLat*(tabTech(68) + (tabTech(69) + ...
         tabTech(70)/10000)/60);
      if (tabTech(75) == 0)
         signLon = 1;
      else
         signLon = -1;
      end
      gpsLocLon = signLon*(tabTech(72) + (tabTech(73) + ...
         tabTech(74)/10000)/60);
      
      o_decodedData = [o_decodedData; [packJulD gpsLocLon gpsLocLat]];
   end
end

return

% ------------------------------------------------------------------------------
% Decode GPS location for Apex APF11 RUDICS floats.
%
% SYNTAX :
%  [o_decodedData] = decode_float_location_apf11_rudics(a_floatNum, a_floatRudicsId, a_inputFileDir)
%
% INPUT PARAMETERS :
%   a_floatNum      : float WMO number
%   a_floatRudicsId : float RUDICS Id
%   a_inputFileDir  : top directory of files to be decoded
%
% OUTPUT PARAMETERS :
%   o_decodedData : GPS data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/20/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decodedData] = decode_float_location_apf11_rudics(a_floatNum, a_floatRudicsId, a_inputFileDir)

% output parameters initialization
o_decodedData = [];

% set useful directories
floatIriDirName = [a_inputFileDir '/' a_floatRudicsId '_' num2str(a_floatNum) '/'];
archiveDirectory = [floatIriDirName 'archive/'];
archiveFloatFilesDirectory = [floatIriDirName 'archive/float_files/'];
if (exist(archiveFloatFilesDirectory, 'dir') == 7)
   rmdir(archiveFloatFilesDirectory, 's');
end
mkdir(archiveFloatFilesDirectory);

% process float files
fileNames = dir([archiveDirectory a_floatRudicsId '*system_log*.gz']);
for idFile = 1:length(fileNames)
   fileName = fileNames(idFile).name;
   
   % uncompress float file
   floatFileName = [archiveDirectory fileName];
   gunzip(floatFileName, archiveFloatFilesDirectory);
   floatFileName = [archiveFloatFilesDirectory fileName(1:end-3)];
   
   % read float file
   [error, events] = read_apx_apf11_ir_system_log_file(floatFileName, 0);
   if (error == 1)
      fprintf('ERROR: Float #%d: Error in file: %s - ignored\n', ...
         a_floatNum, floatFileName);
      continue
   end
   
   if (isempty(events))
      continue
   end
   
   % retrieve GPS data
   idEvts = find(strcmp({events.functionName}, 'GPS'));
   if (~isempty(idEvts))
      gpsData = process_apx_apf11_ir_gps_evts(events(idEvts));
      if (~isempty(gpsData))
         o_decodedData = [o_decodedData; gpsData(:, [1 3 2])];
      end
   end
end

return

% ------------------------------------------------------------------------------
% Decode GPS location for Arvor and Provor Iridium SBD floats.
%
% SYNTAX :
%  [o_decodedDataTab] = decode_float_location_iridium_sbd(a_decoderId, a_floatNum, a_floatImei, a_inputFileDir)
%
% INPUT PARAMETERS :
%   a_decoderId    : float decoder Id
%   a_floatNum     : float WMO number
%   a_floatImei    : float IMEI
%   a_inputFileDir : top directory of files to be decoded
%
% OUTPUT PARAMETERS :
%   o_decodedDataTab : GPS data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/20/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decodedDataTab] = decode_float_location_iridium_sbd(a_decoderId, a_floatNum, a_floatImei, a_inputFileDir)

% output parameters initialization
o_decodedDataTab = [];

% set useful directories
floatIriDirName = [a_inputFileDir '/' num2str(a_floatImei) '_' num2str(a_floatNum) '/'];
archiveDirectory = [floatIriDirName 'archive/'];
archiveSbdDirectory = [floatIriDirName 'archive/sbd/'];
if (exist(archiveSbdDirectory, 'dir') == 7)
   rmdir(archiveSbdDirectory, 's');
end
mkdir(archiveSbdDirectory);

% process mail files
fileList = dir([archiveDirectory '*.txt']);
for idF = 1:length(fileList)
   mailFileName = fileList(idF).name;
   
   % extract the attachement
   [~, attachmentFound] = read_mail_and_extract_attachment( ...
      mailFileName, archiveDirectory, archiveSbdDirectory);
   if (attachmentFound == 0)
      continue
   end
   
   % decode SBD file
   sbdFileName = regexprep(mailFileName, '.txt', '.sbd');
   decodedData = decode_sbd_file_location([archiveSbdDirectory sbdFileName], a_decoderId);
   if (~isempty(decodedData))
      o_decodedDataTab = [o_decodedDataTab; decodedData];
   end
end

return

% ------------------------------------------------------------------------------
% Decode GPS location for Arvor and Provor Iridium SBD floats.
%
% SYNTAX :
%  [o_decodedData] = decode_sbd_file_location(a_sbdFileName, a_decoderId, a_floatNum)
%
% INPUT PARAMETERS :
%   a_sbdFileName : sbd file to decode
%   a_decoderId   : float decoder Id
%   a_floatNum    : float WMO number
%
% OUTPUT PARAMETERS :
%   o_decodedData : GPS data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/20/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decodedData] = decode_sbd_file_location(a_sbdFileName, a_decoderId, a_floatNum)

% output parameters initialization
o_decodedData = [];

% default values
global g_decArgo_janFirst1950InMatlab;


% read SBD data
sbdDataTab = [];
file = dir(a_sbdFileName);
fileSize = file(1).bytes;
if (rem(fileSize, 100) == 0)
   fId = fopen(a_sbdFileName, 'r');
   if (fId == -1)
      fprintf('ERROR: Float #%d: Error while opening file : %s\n', ...
         a_floatNum, ...
         a_sbdFileName);
      return
   end
   sbdData = fread(fId);
   fclose(fId);
   
   sbdData = reshape(sbdData, 100, size(sbdData, 1)/100)';
   for idMsg = 1:size(sbdData, 1)
      data = sbdData(idMsg, :);
      if (any(data ~= 0) && any(data ~= 26)) % historical SBD buffers were padded with 0, they are now padded with 0x1A = 26
         sbdDataTab = [sbdDataTab; data];
      end
   end
   
else
   fprintf('WARNING: Float #%d: SBD file ignored because of unexpected size (%d bytes) : %s\n', ...
      a_floatNum, ...
      fileSize, ...
      a_sbdFileName);
   return
end

% decode SBD data
for idMsg = 1:size(sbdDataTab, 1)
   
   tabData = sbdDataTab(idMsg, :);
   
   % packet type
   packType = tabData(1);
   
   if (packType == 0)
      
      % technical packet #1
      
      % message data frame
      msgData = tabData(2:end);
      
      switch (a_decoderId)
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         case {203}
            % Arvor-deep 4000 5.62
            
            % first item bit number
            firstBit = 1;
            % item bit lengths
            tabNbBits = [ ...
               16 ...
               8 8 8 16 16 16 8 8 ...
               16 16 16 8 8 16 16 ...
               8 8 8 16 16 8 8 ...
               16 16 8 8 16 ...
               8 8 8 8 16 16 ...
               16 16 8 ...
               8 8 8  repmat(8, 1, 9) ...
               8 8 16 8 8 8 16 8 8 16 8 ...
               repmat(8, 1, 2) ...
               repmat(8, 1, 7) ...
               16 8 16 ...
               repmat(8, 1, 4) ...
               ];
            % get item bits
            tabTech = get_bits(firstBit, tabNbBits, msgData);
            
            % GPS valid fix
            gpsValidFix = tabTech(58);
            if (gpsValidFix == 0)
               continue
            end
            
            % compute float time
            floatTime = datenum(sprintf('%02d%02d%02d%02d%02d%02d', tabTech(38:43)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
            
            % compute GPS location
            if (tabTech(53) == 0)
               signLat = 1;
            else
               signLat = -1;
            end
            gpsLocLat = signLat*(tabTech(50) + (tabTech(51) + ...
               tabTech(52)/10000)/60);
            if (tabTech(57) == 0)
               signLon = 1;
            else
               signLon = -1;
            end
            gpsLocLon = signLon*(tabTech(54) + (tabTech(55) + ...
               tabTech(56)/10000)/60);
            
            o_decodedData = [o_decodedData; [floatTime gpsLocLon gpsLocLat]];
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         case {213}
            % Provor-ARN-DO Iridium 5.74
            
            % first item bit number
            firstBit = 1;
            % item bit lengths
            tabNbBits = [ ...
               16 8 16 16 ...
               8 8 8 16 16 16 8 8 ...
               16 16 16 8 8 16 16 ...
               8 8 8 16 16 8 8 ...
               16 16 8 8 16 ...
               8 8 8 8 16 16 ...
               16 16 8 ...
               repmat(8, 1, 12) ...
               8 8 16 8 8 8 16 8 8 16 8 16 8 ...
               repmat(8, 1, 10) ...
               ];
            % get item bits
            tabTech1 = get_bits(firstBit, tabNbBits, msgData);
            
            % GPS valid fix
            gpsValidFix = tabTech1(61);
            if (gpsValidFix == 0)
               continue
            end
            
            % compute float time
            floatTime = datenum(sprintf('%02d%02d%02d%02d%02d%02d', tabTech1(41:46)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
            
            % compute GPS location
            if (tabTech1(56) == 0)
               signLat = 1;
            else
               signLat = -1;
            end
            gpsLocLat = signLat*(tabTech1(53) + (tabTech1(54) + ...
               tabTech1(55)/10000)/60);
            if (tabTech1(60) == 0)
               signLon = 1;
            else
               signLon = -1;
            end
            gpsLocLon = signLon*(tabTech1(57) + (tabTech1(58) + ...
               tabTech1(59)/10000)/60);
            
            o_decodedData = [o_decodedData; [floatTime gpsLocLon gpsLocLat]];
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         case {214}
            % Provor-ARN-DO-Ice Iridium 5.75
            
            % first item bit number
            firstBit = 1;
            % item bit lengths
            tabNbBits = [ ...
               16 8 16 16 ...
               8 8 8 16 16 16 8 8 ...
               16 16 16 8 8 16 16 ...
               8 8 8 16 16 8 8 ...
               16 16 8 8 16 ...
               8 8 8 8 16 16 ...
               16 16 8 ...
               repmat(8, 1, 12) ...
               8 8 16 8 8 8 16 8 8 16 8 16 8 ...
               repmat(8, 1, 7) ...
               repmat(8, 1, 3) ...
               ];
            % get item bits
            tabTech1 = get_bits(firstBit, tabNbBits, msgData);
            
            % GPS valid fix
            gpsValidFix = tabTech1(61);
            if (gpsValidFix == 0)
               continue
            end
            
            % compute float time
            floatTime = datenum(sprintf('%02d%02d%02d%02d%02d%02d', tabTech1(41:46)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
            
            % compute GPS location
            if (tabTech1(56) == 0)
               signLat = 1;
            else
               signLat = -1;
            end
            gpsLocLat = signLat*(tabTech1(53) + (tabTech1(54) + ...
               tabTech1(55)/10000)/60);
            if (tabTech1(60) == 0)
               signLon = 1;
            else
               signLon = -1;
            end
            gpsLocLon = signLon*(tabTech1(57) + (tabTech1(58) + ...
               tabTech1(59)/10000)/60);
            
            o_decodedData = [o_decodedData; [floatTime gpsLocLon gpsLocLat]];
           
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         case {215}
            % Arvor-deep 4000 with "Near Surface" & "In Air" measurements

            % first item bit number
            firstBit = 1;
            % item bit lengths
            tabNbBits = [ ...
               16 ...
               8 8 8 16 16 16 8 8 ...
               16 16 16 8 8 16 16 ...
               8 8 8 16 16 8 8 ...
               16 16 8 8 16 ...
               8 8 8 8 16 16 ...
               16 16 8 ...
               8 8 8  repmat(8, 1, 9) ...
               8 8 16 8 8 8 16 8 8 16 8 ...
               repmat(8, 1, 2) ...
               repmat(8, 1, 7) ...
               16 8 16 ...
               repmat(8, 1, 4) ...
               ];
            % get item bits
            tabTech = get_bits(firstBit, tabNbBits, msgData);

            % compute float time
            floatTime = datenum(sprintf('%02d%02d%02d%02d%02d%02d', tabTech(38:43)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
            
            % compute GPS location
            if (tabTech(53) == 0)
               signLat = 1;
            else
               signLat = -1;
            end
            gpsLocLat = signLat*(tabTech(50) + (tabTech(51) + ...
               tabTech(52)/10000)/60);
            if (tabTech(57) == 0)
               signLon = 1;
            else
               signLon = -1;
            end
            gpsLocLon = signLon*(tabTech(54) + (tabTech(55) + ...
               tabTech(56)/10000)/60);
            
            o_decodedData = [o_decodedData; [floatTime gpsLocLon gpsLocLat]];

      end
   end
end

return
