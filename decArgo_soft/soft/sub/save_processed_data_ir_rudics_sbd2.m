% ------------------------------------------------------------------------------
% Save the processed data in a temporary file.
%
% SYNTAX :
%  save_processed_data_ir_rudics_sbd2(a_tabProfiles, ...
%    a_tabTrajNMeas, a_tabTrajNCycle, ...
%    a_tabNcTechIndex, a_tabNcTechVal)
%
% INPUT PARAMETERS :
%   a_tabProfiles    : decoded profiles
%   a_tabTrajNMeas   : decoded trajectory N_MEASUREMENT data
%   a_tabTrajNCycle  : decoded trajectory N_CYCLE data
%   a_tabNcTechIndex : decoded technical index information
%   a_tabNcTechVal   : decoded technical data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/18/2013 - RNU - creation
% ------------------------------------------------------------------------------
function save_processed_data_ir_rudics_sbd2(a_tabProfiles, ...
   a_tabTrajNMeas, a_tabTrajNCycle, ...
   a_tabNcTechIndex, a_tabNcTechVal)

% current float WMO number
global g_decArgo_floatNum;

% processed data directory
global g_decArgo_tmpDirectory;

% array to store GPS data
global g_decArgo_gpsData;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;

% sensor list
global g_decArgo_sensorList;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% float configuration
global g_decArgo_floatConfig;

% output NetCDF technical parameter names additional information
global g_decArgo_outputNcParamLabelInfo;
global g_decArgo_outputNcParamLabelInfoCounter;


% file name of the processed data file
dataFileName = [sprintf('processed_data_%d_%s', g_decArgo_floatNum, datestr(now, 'yyyymmddTHHMMSS')) '_save7.3.mat'];
dataFilePathName = [g_decArgo_tmpDirectory '/' dataFileName];

fprintf('DEC_INFO: saving decoded data in file: %s  wait ...', dataFileName);

% save the processed data in a file
save(dataFilePathName, 'a_tabProfiles', '-v7.3');
save(dataFilePathName, '-append', 'a_tabTrajNMeas');
save(dataFilePathName, '-append', 'a_tabTrajNCycle');
save(dataFilePathName, '-append', 'a_tabNcTechIndex');
save(dataFilePathName, '-append', 'a_tabNcTechVal');
save(dataFilePathName, '-append', 'g_decArgo_gpsData');
save(dataFilePathName, '-append', 'g_decArgo_iridiumMailData');
save(dataFilePathName, '-append', 'g_decArgo_sensorList');
save(dataFilePathName, '-append', 'g_decArgo_calibInfo');
save(dataFilePathName, '-append', 'g_decArgo_floatConfig');
save(dataFilePathName, '-append', 'g_decArgo_outputNcParamLabelInfo');
save(dataFilePathName, '-append', 'g_decArgo_outputNcParamLabelInfoCounter');

% delete previous files of processed data
dataFiles = dir([g_decArgo_tmpDirectory '/' sprintf('processed_data_%d_*.mat', g_decArgo_floatNum)]);
for idFile = 1:length(dataFiles)
   
   if (strcmp(dataFiles(idFile).name, dataFileName) == 0)
      delete([g_decArgo_tmpDirectory '/' dataFiles(idFile).name]);
   end
end

fprintf('done\n');

return;
