% ------------------------------------------------------------------------------
% Create configuration structures from JSON meta-data information.
%
% SYNTAX :
%  [o_floatRudicsId] = init_float_config_apx_apf11_ir(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_floatRudicsId : float Rudics Id
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatRudicsId] = init_float_config_apx_apf11_ir(a_decoderId)

% output parameters initialization
o_floatRudicsId = [];

% float configuration
global g_decArgo_floatConfig;

% current float WMO number
global g_decArgo_floatNum;

% directory of json meta-data files
global g_decArgo_dirInputJsonFloatMetaDataFile;

% arrays to store calibration information
global g_decArgo_calibInfo;
g_decArgo_calibInfo = [];

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;
g_decArgo_rtOffsetInfo = [];


% json meta-data file for this float
jsonInputFileName = [g_decArgo_dirInputJsonFloatMetaDataFile '/' sprintf('%d_meta.json', g_decArgo_floatNum)];

if ~(exist(jsonInputFileName, 'file') == 2)
   g_decArgo_calibInfo = [];
   fprintf('ERROR: Json meta-data file not found: %s\n', jsonInputFileName);
   return;
end

% read meta-data file
metaData = loadjson(jsonInputFileName);

% retrieve float username
if (isfield(metaData, 'FLOAT_RUDICS_ID'))
   o_floatRudicsId = metaData.FLOAT_RUDICS_ID;
end
if (isempty(o_floatRudicsId))
   fprintf('ERROR: FLOAT_RUDICS_ID is mandatory, it should be set in Json meta-data file (%s)\n', jsonInputFileName);
   return;
end

% initialize the configuration with the json meta-data file contents
configNames = struct2cell(metaData.CONFIG_PARAMETER_NAME);
configValues = nan(length(configNames), 1);

jConfValues = struct2cell(metaData.CONFIG_PARAMETER_VALUE);
for id = 1:length(jConfValues)
   if (~isempty(jConfValues{id}))
      configValues(id) = str2double(jConfValues{id});
   end
end

% compute CONFIG_CT_CycleTime
idF1 = find(strcmp(configNames, 'CONFIG_CT_CycleTime'));
idF2 = find(strcmp(configNames, 'CONFIG_DOWN_DownTime'));
idF3 = find(strcmp(configNames, 'CONFIG_UP_UpTime'));
if (~isempty(idF1) && ~isempty(idF2) && ~isempty(idF3))
   configValues(idF1) = configValues(idF2) + configValues(idF3);
end

% store the configuration
g_decArgo_floatConfig = [];
g_decArgo_floatConfig.NAMES = configNames;
g_decArgo_floatConfig.VALUES = configValues;
g_decArgo_floatConfig.NUMBER = 0;
g_decArgo_floatConfig.USE.CYCLE = [];
g_decArgo_floatConfig.USE.CONFIG = [];

% retrieve the RT offsets
g_decArgo_rtOffsetInfo = get_rt_adj_info_from_meta_data(metaData);

return;
