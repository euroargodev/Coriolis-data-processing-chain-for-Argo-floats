% ------------------------------------------------------------------------------
% Create the final configuration that will be used in the meta.nc file.
%
% SYNTAX :
%  [o_ncConfig] = create_output_float_config_pfv2( ...
%    a_decArgoConfParamNames, a_ncConfParamNames, a_ncConfParamIds)
%
% INPUT PARAMETERS :
%   a_decArgoConfParamNames : internal configuration parameter names
%   a_ncConfParamNames      : NetCDF configuration parameter names
%    a_ncConfParamIds       : NetCDF configuration parameter Ids
%
% OUTPUT PARAMETERS :
%   o_ncConfig : NetCDF configuration
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/03/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncConfig] = create_output_float_config_pfv2( ...
   a_decArgoConfParamNames, a_ncConfParamNames, a_ncConfParamIds)

% output parameters initialization
o_ncConfig = [];

% float configuration
global g_decArgo_floatConfig;

% current float WMO number
global g_decArgo_floatNum;

% management of meta-data transmitted in TECH files
global g_decArgo_metaFromTech


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Static configuration parameters coming from TECH data

staticConfigName = cell(length(g_decArgo_metaFromTech.techId), 1);
staticConfigValue = nan(length(g_decArgo_metaFromTech.techId), 1);
for idM = 1:length(g_decArgo_metaFromTech.techId)
   confParamId =['META-FROM-TECH.P' num2str(g_decArgo_metaFromTech.techId(idM))];
   idF = find(strcmp(confParamId, a_ncConfParamIds));
   if (~isempty(idF))
      staticConfigName{idM} = a_ncConfParamIds{idF};
      staticConfigValue(idM) = g_decArgo_metaFromTech.value(idM);
   end
end
staticConfigValue = cat(2, ...
   staticConfigValue, nan(size(staticConfigValue, 1), size(g_decArgo_floatConfig.DYNAMIC.VALUES, 2)-1));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize final configuration
configNum = g_decArgo_floatConfig.DYNAMIC.NUMBER;
configName = [staticConfigName; g_decArgo_floatConfig.DYNAMIC.NAMES];
configId = cell(size(configName));
configValue = [staticConfigValue; g_decArgo_floatConfig.DYNAMIC.VALUES];

% remove the '-LOOPXX-CYCLEXX' parameters from the final configuration
% only parameters xith '-L-C' pattern are considered
idDel = find(contains(configName, '-LOOP') & contains(configName, '-CYCLE'));
configName(idDel) = [];
configId(idDel) = [];
configValue(idDel, :) = [];

% set 'MISSION-L-C.P1' to nan if set to 0
idConf = find(strcmp(configName, 'MISSION-L-C.P1'));
if (~isempty(idConf))
   idNul = find(configValue(idConf, :) == 0);
   configValue(idConf, idNul) = nan;
end

% delete the unused configuration parameters
idDel = [];
for idL = 1:size(configValue, 1)
   if (sum(isnan(configValue(idL, :))) == size(configValue, 2))
      idDel = [idDel; idL];
   end
end
configName(idDel) = [];
configId(idDel) = [];
configValue(idDel, :) = [];

% delete configuration parameters not reported in NetCDF file
excludedParamList = [ ...
{'MISSION-LOOPXX.P0'} ...
{'MISSION-LOOPXX-CYCLEXX.P0'} ...
];

% convert decoder names into NetCDF ones
if (~isempty(a_decArgoConfParamNames))
   
   idDel = [];
   for idP = 1:length(configName)
      confName = configName{idP};
      if (ismember(confName, excludedParamList))
         idDel = [idDel; idP];
         continue
      end
      idF = find(strcmp(confName, a_decArgoConfParamNames));
      if (~isempty(idF))
         configName{idP} = a_ncConfParamNames{idF};
         configId{idP} = a_ncConfParamIds{idF};
      else
         if (any(strfind(confName, '-LOOP')))
            idL = strfind(confName, '-LOOP');
            confName(idL+length('-LOOP')+(0:1)) = 'XX';
         end
         if (any(strfind(confName, '-CYCLE')))
            idL = strfind(confName, '-CYCLE');
            confName(idL+length('-CYCLE')+(0:1)) = 'XX';
         end
         if (any(strfind(confName, '-L-C')))
            confName = regexprep(confName, '-L-C', '-LOOPXX-CYCLEXX');
         end
         if (ismember(confName, excludedParamList))
            idDel = [idDel; idP];
            continue
         end
         idF = find(strcmp(confName, a_decArgoConfParamNames));
         if (~isempty(idF))
            configName{idP} = a_ncConfParamNames{idF};
            configId{idP} = a_ncConfParamIds{idF};
         else
            sensorNum = nan;
            zoneNum = nan;
            if (any(strfind(confName, '-SENSOR')))
               idS = strfind(confName, '-SENSOR');
               sensorNum = str2double(confName(idS+length('-SENSOR')+(0:1)));
               confName(idS+length('-SENSOR')+(0:1)) = 'XX';
            end
            if (any(strfind(confName, '-ZONE')))
               idS = strfind(confName, '-ZONE');
               zoneNum = str2double(confName(idS+length('-ZONE')));
               confName(idS+length('-ZONE')) = 'N';
            end
            if (ismember(confName, excludedParamList))
               idDel = [idDel; idP];
               continue
            end
            idF = find(strcmp(confName, a_decArgoConfParamNames));
            if (~isempty(idF))
               ncConfName = a_ncConfParamNames{idF};
               configId{idP} = a_ncConfParamIds{idF};
               if (~isnan(sensorNum))
                  switch (sensorNum)
                     case {1, 3}
                        shortSensorName = 'Ctd';
                     case {2}
                        shortSensorName = 'Optode';
                  end
                  ncConfName = regexprep(ncConfName, '<short_sensor_name>', shortSensorName);
               end
               if (~isnan(zoneNum))
                  idS = strfind(ncConfName, '<N>');
                  ncConfName = [ncConfName(1:idS-1) num2str(zoneNum) ncConfName(idS+length('<N>'):end)];
                  idS = strfind(ncConfName, '<N+1>');
                  if (~isempty(idS))
                     ncConfName = [ncConfName(1:idS-1) num2str(zoneNum+1) ncConfName(idS+length('<N+1>'):end)];
                  end
               end
               configName{idP} = ncConfName;
            else
               % this should not happend
               idDel = [idDel; idP];
               fprintf('ERROR: Float #%d: Cannot convert configuration param name :''%s'' into NetCDF one\n', ...
                  g_decArgo_floatNum, ...
                  configName{idP});
            end
         end
      end
   end
   configName(idDel) = [];
   configId(idDel) = [];
   configValue(idDel, :) = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% remove ICE configuration parameters if ICE.P0 = 0 (not activated)
idF = find(strcmp(configId, 'ICE.P0'));
if (~isempty(idF))
   if (~any(configValue(idF, :) == 1))
      idDel = find(contains(configId, 'ICE'));
      configName(idDel) = [];
      configId(idDel) = [];
      configValue(idDel, :) = [];
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% look for duplicates in final configuration labels
if (length(configName) ~= length(unique(configName)))
   confNameList = configName;
   uConfNameList = unique(confNameList);
   anomalyStr = '';
   for idP = 1:length(uConfNameList)
      idF = find(strcmp(uConfNameList(idP), confNameList));
      if (length(idF) > 1)
         anomalyStr = [anomalyStr ...
            sprintf('%s; ', uConfNameList{idP})];
      end
   end
   fprintf('ERROR: Float #%d: Duplicated CONFIG labels (%s)\n', ...
      g_decArgo_floatNum, anomalyStr(1:end-2));
end

% output data
o_ncConfig.DYNAMIC_NC.NUMBER = configNum;
o_ncConfig.DYNAMIC_NC.NAMES = configName;
o_ncConfig.DYNAMIC_NC.IDS = configId;
o_ncConfig.DYNAMIC_NC.VALUES = configValue;

return
