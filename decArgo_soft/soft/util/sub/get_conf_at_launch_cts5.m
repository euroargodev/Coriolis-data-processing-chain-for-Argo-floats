% ------------------------------------------------------------------------------
% Read the predeployment configuration sheet to get the configuration at launch.
%
% SYNTAX :
%  [o_confParamNames, o_confParamValues] = get_conf_at_launch_cts5( ...
%    a_configReportFileName, a_configDefaultFilename, a_sensorList)
%
% INPUT PARAMETERS :
%   a_configReportFileName : predeployment configuration sheet file name
%   a_sensorList : list of the sensors mounted on the float
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
   a_configReportFileName, a_sensorList)

% output parameters initialization
o_confParamNames = [];
o_confParamValues = [];


% read configuration file
[confAtLaunchData] = read_apmt_config(a_configReportFileName);
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
