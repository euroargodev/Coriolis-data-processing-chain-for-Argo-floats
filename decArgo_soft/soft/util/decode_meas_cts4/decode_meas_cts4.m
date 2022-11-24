% ------------------------------------------------------------------------------
% Decoding of PROVOR CTS4 sensor measurements and processing of derived
% parameters.
%
% SYNTAX :
%   decode_meas_cts4('imrbio007b')
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
%   02/05/2021 - RNU - creation
% ------------------------------------------------------------------------------
function decode_meas_cts4(varargin)

% input directory of float transmitted files
DIR_INPUT_FILES = 'C:\Users\jprannou\_DATA\ESSAIS_BASSIN\DATA\IN\';
DIR_INPUT_FILES = 'C:\Users\jprannou\_DATA\ESSAIS_BASSIN_20210611\DATA\';

% directory of output CSV files
DIR_OUTPUT_FILES = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';

% input directory of float META.json files
DIR_META_JSON_FILES = 'C:\Users\jprannou\_DATA\ESSAIS_BASSIN\META_JSON\';
DIR_META_JSON_FILES = 'C:\Users\jprannou\_DATA\ESSAIS_BASSIN_20210611\META_JSON\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

FLOAT_DECODER_ID = 111;

FITLM_MATLAB_FUNCTION_NOT_AVAILABLE = 0;


% default values
global g_decArgo_janFirst1950InMatlab;

% default values initialization
init_default_values;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;
g_decArgo_julD2FloatDayOffset = [];

global g_decArgo_floatTransType;
g_decArgo_floatTransType = 2;

% float configuration
global g_decArgo_floatConfig;

% to manage fitlm function for NITRATE processin
global g_temp_fitlmNotAvailable;
g_temp_fitlmNotAvailable = FITLM_MATLAB_FUNCTION_NOT_AVAILABLE;


if (nargin == 0)
   fprintf('ERROR: Float login name expected => exit\n');
   return
end
floatLoginName = varargin{:};

dateStr = datestr(now, 'yyyymmddTHHMMSS');
logFile = [DIR_LOG_FILE '/' 'decode_meas_cts4_' dateStr '.log'];
diary(logFile);
tic;

% get sensor list and calibration information
jsonFile = [DIR_META_JSON_FILES '/' floatLoginName '_meta.json'];
if ~(exist(jsonFile, 'file') == 2)
   fprintf('ERROR: File not found: %s => exit\n', jsonFile);
   return
end
ok = init_float_config_prv_ir_rudics_cts4(jsonFile, FLOAT_DECODER_ID);
if (~ok)
   return
end

dataDir = [DIR_INPUT_FILES '/' floatLoginName '/'];
if ~(exist(dataDir, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s => exit\n', dataDir);
   return
end

sbdFiles = dir([dataDir '/' sprintf('*_%s_*.bin', floatLoginName)]);
fprintf('Float %s: %d files to process\n', floatLoginName, length(sbdFiles));

% read .bin files and decode data
decodedDataTab = [];
for idFile = 1:length(sbdFiles)
   sbdFileName = sbdFiles(idFile).name;
   sbdFilePathName = [dataDir '/' sbdFileName];
   fprintf('   - %s\n', sbdFileName);
   
   % decode SBD file
   idFUs = strfind(sbdFileName, '_');
   sbdFileDate = datenum(sbdFileName(1:idFUs(2)-1), 'yymmdd_HHMMSS') - g_decArgo_janFirst1950InMatlab;
   decodedData = decode_sbd_file_cts4(sbdFileName, sbdFilePathName, sbdFileDate);
   decodedDataTab = cat(2, decodedDataTab, decodedData);
end

% assign all the (cycle, profile) to the unique configuration
cyProfList = unique([[decodedDataTab.cyNumRaw]' [decodedDataTab.profNumRaw]'], 'rows');
g_decArgo_floatConfig.USE.CYCLE = cyProfList(:, 1)';
g_decArgo_floatConfig.USE.PROFILE = cyProfList(:, 2)';
g_decArgo_floatConfig.USE.CONFIG = zeros(1, size(cyProfList, 1));

% process decoded data
[tabProfiles, tabDrift] = process_decoded_data_cts4(decodedDataTab, FLOAT_DECODER_ID);

% print decoded data in output CSV file
print_data_meas_in_csv_file(tabProfiles, tabDrift, DIR_OUTPUT_FILES, floatLoginName, dateStr);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
