% ------------------------------------------------------------------------------
% Create calibration and RTOffset configuration structures from JSON meta-data
% information.
%
% SYNTAX :
%  init_float_config_nemo(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatRudicsId] = init_float_config_nemo(a_decoderId)

% output parameters initialization
o_floatRudicsId = [];

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

% Argos (1), Iridium RUDICS (2), Iridium SBD (3) float
global g_decArgo_floatTransType;

% float configuration
global g_decArgo_floatConfig;

% json meta-data
global g_decArgo_jsonMetaData;


% json meta-data file for this float
jsonInputFileName = [g_decArgo_dirInputJsonFloatMetaDataFile '/' sprintf('%d_meta.json', g_decArgo_floatNum)];

if ~(exist(jsonInputFileName, 'file') == 2)
   g_decArgo_calibInfo = [];
   fprintf('ERROR: Json meta-data file not found: %s\n', jsonInputFileName);
   return
end

% read meta-data file
jsonMetaData = loadjson(jsonInputFileName);
g_decArgo_jsonMetaData = jsonMetaData;

% create the configurations from JSON data
configNames = [];
configValues = [];
configNumbers = [];
if ((isfield(jsonMetaData, 'CONFIG_PARAMETER_NAME')) && ...
      (isfield(jsonMetaData, 'CONFIG_PARAMETER_VALUE')))
   
   configNames = struct2cell(jsonMetaData.CONFIG_PARAMETER_NAME);
   cellConfigValues = jsonMetaData.CONFIG_PARAMETER_VALUE;
   configValues = nan(size(configNames, 1), size(cellConfigValues, 2));
   configNumbers = 1:length(cellConfigValues);
   for idConf = 1:length(cellConfigValues)
      cellConfigVals = struct2cell(cellConfigValues{idConf});
      for idVal = 1:length(cellConfigVals)
         if (~isempty(cellConfigVals{idVal}))
            [value, status] = str2num(cellConfigVals{idVal});
            if ((length(value) == 1) && (status == 1))
               configValues(idVal, idConf) = value;
            else
               fprintf('ERROR: Float #%d: The configuration value ''%s'' cannot be converted to numerical value\n', ...
                  g_decArgo_floatNum, ...
                  configNames{idConf});
               return
            end
         end
      end
   end
end

% store the configuration
g_decArgo_floatConfig = [];
g_decArgo_floatConfig.NAMES = configNames;
g_decArgo_floatConfig.VALUES = configValues;
g_decArgo_floatConfig.NUMBER = configNumbers;

% retrieve the RT offsets
g_decArgo_rtOffsetInfo = get_rt_adj_info_from_meta_data(jsonMetaData);

return
