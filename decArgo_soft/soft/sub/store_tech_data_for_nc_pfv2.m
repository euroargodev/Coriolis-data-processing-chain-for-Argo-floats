% ------------------------------------------------------------------------------
% Store technical message #1 data for output NetCDF file.
%
% SYNTAX :
% [o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, o_tabTechAuxNMeas] = ...
%   store_tech_data_for_nc_pfv2( ...
%   a_selfTest, a_tech1, a_tech2, a_eol, a_cycleNum, a_tabTechNMeas, a_tabTechAuxNMeas)
%
% INPUT PARAMETERS :
%   a_selfTest        : self test tech data
%   a_tech1           : tech #1 data
%   a_tech2           : tech #2 data
%   a_eol             : EOL tech data
%   a_cycleNum        : cycle number
%   a_tabTechNMeas    : input N_MEASUREMENT structure of technical data time series
%   a_tabTechAuxNMeas : input N_MEASUREMENT structure of AUX technical data time series
%
% OUTPUT PARAMETERS :
%   o_tabNcTechIndex  : NC TECH Ids
%   o_tabNcTechVal    : NC TECH values
%   o_tabTechNMeas    : output N_MEASUREMENT structure of technical data time series
%   o_tabTechAuxNMeas : output N_MEASUREMENT structure of AUX technical data time series
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/07/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, o_tabTechAuxNMeas] = ...
   store_tech_data_for_nc_pfv2( ...
   a_selfTest, a_tech1, a_tech2, a_eol, a_cycleNum, a_tabTechNMeas, a_tabTechAuxNMeas)

% output parameters initialization
o_tabNcTechIndex = [];
o_tabNcTechVal = [];
o_tabTechNMeas = a_tabTechNMeas;
o_tabTechAuxNMeas = a_tabTechAuxNMeas;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% global measurement codes
global g_MC_FillValue;

% global time status
global g_JULD_STATUS_2;

% output NetCDF technical parameter Ids
global g_decArgo_outputNcParamId;

% output NetCDF technical parameter labels
global g_decArgo_outputNcParamLabel;
global g_decArgo_outputNcParamDescription;


% structure to store N_MEASUREMENT technical data
tabTechNMeas = get_traj_n_meas_init_struct(a_cycleNum, -1);
tabTechAuxNMeas = get_traj_n_meas_init_struct(a_cycleNum, -1);

for file = 1:4
   if (file == 1)
      inputData = a_selfTest;
   elseif (file == 2)
      inputData = a_tech2;
   elseif (file == 3)
      inputData = a_tech1;
   elseif (file == 4)
      inputData = a_eol;
   end

   for idL = 1:size(inputData, 1)      

      techData = inputData{idL, 1};
      techTimeData = inputData{idL, 2};

      % replace templates in TECH labels
      for idT = 1:length(techData)
         if (~isempty(techData(idT).shortSensorName) || ~isempty(techData(idT).depthZoneNum))
            idF = find(g_decArgo_outputNcParamId == techData(idT).techId);
            if (isempty(idF))
               fprintf('ERROR: Float #%d Cycle #%d: Cannot find name and description of techId %d\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, techData(idT).techId);
               continue
            end
            paramName = g_decArgo_outputNcParamLabel{idF};
            paramDescription = g_decArgo_outputNcParamDescription{idF};
            if (~isempty(techData(idT).shortSensorName))
               paramName = regexprep(paramName, '<short_sensor_name>', techData(idT).shortSensorName);
               paramDescription = regexprep(paramDescription, '<short_sensor_name>', techData(idT).shortSensorName);
            end
            if (~isempty(techData(idT).depthZoneNum))
               paramName = regexprep(paramName, '<Z>', num2str(techData(idT).depthZoneNum));
               paramDescription = regexprep(paramDescription, '<Z>', num2str(techData(idT).depthZoneNum));
            end

            % update the techId field (and reference lists if needed)
            idF = find(strcmp(paramName, g_decArgo_outputNcParamLabel));
            if (isempty(idF))
               % add a new entry in g_decArgo_outputNcParamId,
               % g_decArgo_outputNcParamLabel and g_decArgo_outputNcParamDescription
               ncParamId = techData(idT).techId + 1000000;
               while (any(g_decArgo_outputNcParamId == ncParamId))
                  ncParamId = ncParamId + 1;
               end
               g_decArgo_outputNcParamId = [g_decArgo_outputNcParamId ncParamId];
               g_decArgo_outputNcParamLabel{end+1} = paramName;
               g_decArgo_outputNcParamDescription{end+1} = paramDescription;
               techData(idT).techId = ncParamId;
            else
               techData(idT).techId = g_decArgo_outputNcParamId(idF);
            end
         end
      end

      % store technical information
      o_tabNcTechIndex = [o_tabNcTechIndex; [ones(length(techData), 1)*a_cycleNum [techData.techId]']];
      o_tabNcTechVal = [o_tabNcTechVal; {techData.value}'];

      % create time series of technical data (to be stored in TECH_AUX file)
      juldMcList = unique([[techTimeData.julD]' [techTimeData.measCode]'], 'rows');
      for idJM = 1:size(juldMcList, 1)
         idForJM = find(([techTimeData.julD] == juldMcList(idJM, 1)) & ([techTimeData.measCode] == juldMcList(idJM, 2)));
         measCode = juldMcList(idJM, 2);
         if (measCode == -1) % cannot use nan (not working in unique (.., 'rows')
            measCode = g_MC_FillValue;
         end
         [measStruct, ~] = create_one_meas_float_time_pfv2( ...
            measCode, ...
            juldMcList(idJM, 1), g_JULD_STATUS_2, nan);

         % create parameter list and associated data
         paramList = [];
         paramIdList = [];
         paramData = [];
         paramAuxList = [];
         paramAuxIdList = [];
         paramAuxData = [];
         for id = idForJM
            idF = find(g_decArgo_outputNcParamId == techTimeData(id).techId);
            if (isempty(idF))
               fprintf('ERROR: Float #%d Cycle #%d: Cannot find name and description of techId %d\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, techTimeData(id).techId);
               continue
            end
            paramName = g_decArgo_outputNcParamLabel{idF};
            paramDescription = g_decArgo_outputNcParamDescription{idF};

            % replace templates in TECH labels
            if (~isempty(techTimeData(id).shortSensorName) || ~isempty(techTimeData(id).depthZoneNum))
               if (~isempty(techTimeData(id).shortSensorName))
                  paramName = regexprep(paramName, '<short_sensor_name>', techTimeData(id).shortSensorName);
                  paramDescription = regexprep(paramDescription, '<short_sensor_name>', techTimeData(id).shortSensorName);
               end
               if (~isempty(techTimeData(id).depthZoneNum))
                  paramName = regexprep(paramName, '<Z>', num2str(techTimeData(id).depthZoneNum));
                  paramDescription = regexprep(paramDescription, '<Z>', num2str(techTimeData(id).depthZoneNum));
               end

               % update the reference lists if needed
               idF = find(strcmp(paramName, g_decArgo_outputNcParamLabel));
               if (isempty(idF))
                  % add a new entry in g_decArgo_outputNcParamId,
                  % g_decArgo_outputNcParamLabel and g_decArgo_outputNcParamDescription
                  ncParamId = techTimeData(id).techId + 1000000;
                  while (any(g_decArgo_outputNcParamId == ncParamId))
                     ncParamId = ncParamId + 1;
                  end
                  g_decArgo_outputNcParamId = [g_decArgo_outputNcParamId ncParamId];
                  g_decArgo_outputNcParamLabel{end+1} = paramName;
                  g_decArgo_outputNcParamDescription{end+1} = paramDescription;
               else
                  ncParamId = g_decArgo_outputNcParamId(idF);
               end
            else
               ncParamId = techTimeData(id).techId;
            end

            paramNameForStruct = paramName;
            idUS = strfind(paramName, '_');
            if (strncmp(paramName, 'TECH_AUX_', length('TECH_AUX_')))
               if (length(idUS) > 3)
                  paramUnits = paramName(idUS(4)+1:end);
               else
                  paramUnits = '';
               end
            else
               if (length(idUS) > 1)
                  paramUnits = paramName(idUS(2)+1:end);
                  paramNameForStruct = paramName(1:idUS(2)-1);
               else
                  paramUnits = '';
               end
            end

            paramStruct = struct('name', paramNameForStruct, ...
               'longName', paramDescription, ...
               'standardName', '', ...
               'fillValue', single(99999), ...
               'units', paramUnits, ...
               'validMin', '', ...
               'validMax', '', ...
               'axis', '', ...
               'cFormat', '', ...
               'fortranFormat', '', ...
               'resolution', '', ...
               'paramType', 't', ...
               'paramNcType', 'NC_FLOAT', ...
               'adjAllowed', 0);

            if (strncmp(paramName, 'TECH_AUX_', length('TECH_AUX_')))
               paramAuxList = [paramAuxList paramStruct];
               paramAuxIdList = [paramAuxIdList ncParamId];
               paramAuxData = [paramAuxData techTimeData(id).value];
            else
               paramList = [paramList paramStruct];
               paramIdList = [paramIdList ncParamId];
               paramData = [paramData techTimeData(id).value];
            end
         end

         if (~isempty(paramList))
            measStruct.paramList = paramList;
            measStruct.paramIdList = paramIdList;
            measStruct.paramData = paramData;
            tabTechNMeas.tabMeas = [tabTechNMeas.tabMeas; measStruct];
         end

         if (~isempty(paramAuxList))
            measStruct.paramList = paramAuxList;
            measStruct.paramIdList = paramAuxIdList;
            measStruct.paramData = paramAuxData;
            tabTechAuxNMeas.tabMeas = [tabTechAuxNMeas.tabMeas; measStruct];
         end
      end
   end
end

if (~isempty(tabTechNMeas.tabMeas))
   o_tabTechNMeas = [o_tabTechNMeas tabTechNMeas];
end
if (~isempty(tabTechAuxNMeas.tabMeas))
   o_tabTechAuxNMeas = [o_tabTechAuxNMeas tabTechAuxNMeas];
end

return
