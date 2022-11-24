% ------------------------------------------------------------------------------
% Read the predeployment configuration sheet to get the configuration at launch.
%
% SYNTAX :
%  [o_confParamNames, o_confParamValues] = get_conf_at_launch_cts5( ...
%    a_configReportFileName, a_configDefaultFilename, a_sensorList, a_dacFormatId)
%
% INPUT PARAMETERS :
%   a_configReportFileName : predeployment configuration sheet file name
%   a_sensorList           : list of the sensors mounted on the float
%   a_dacFormatId          : DAC version of the float
%
% OUTPUT PARAMETERS :
%   o_confParamNames  : configuration parameter names
%   o_confParamValues : configuration parameter values at launch
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_confParamNames, o_confParamValues] = get_conf_at_launch_cts5( ...
   a_configReportFileName, a_sensorList, a_dacFormatId)

% output parameters initialization
o_confParamNames = [];
o_confParamValues = [];

% retrieve deecId from DAC version
decoderId = [];
switch (a_dacFormatId)
   case {'7.01'}
      decoderId = 121;
   case {'7.02'}
      decoderId = 122;
   case {'7.03'}
      decoderId = 123;
   case {'7.04'}
      decoderId = 124;
   otherwise
      fprintf('ERROR: Cannot find decoderId from DAC version ''%s'' in get_conf_at_launch_cts5\n', ...
         a_dacFormatId);
      return;
end

% read configuration file
[confAtLaunchData] = read_apmt_config(a_configReportFileName, decoderId);
fieldNames = fieldnames(confAtLaunchData);
for idF = 1:length(fieldNames)
   section = fieldNames{idF};
   dataNumList = confAtLaunchData.(section).num;
   dataNameList = confAtLaunchData.(section).name;
   dataFmtList = confAtLaunchData.(section).fmt;
   dataValueList = confAtLaunchData.(section).data;
   for idI = 1:length(dataNameList)
      dataNum = dataNumList{idI};
      dataName = dataNameList{idI};
      dataFmt = dataFmtList{idI};
      dataValue = dataValueList{idI};
      o_confParamNames{end+1} = sprintf('CONFIG_APMT_%s_P%02d', section, dataNum);
      if (~isempty(dataFmt))
         o_confParamValues{end+1} = sprintf(dataFmt, dataValue);
      else
         o_confParamValues{end+1} = '1';
      end
   end
end

return;
