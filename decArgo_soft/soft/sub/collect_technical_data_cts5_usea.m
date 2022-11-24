% ------------------------------------------------------------------------------
% Collect technical data from CTS5-USEA technical messages (and merge TECH and
% Event technical data)
%
% SYNTAX :
%  [o_techNcParamIndex, o_techNcParamValue, o_tabTechNMeas] = ...
%    collect_technical_data_cts5_usea(a_tabTech)
%
% INPUT PARAMETERS :
%   a_tabTech : data from AMPT technical messages
%
% OUTPUT PARAMETERS :
%   o_techNcParamIndex : collected technical index information
%   o_techNcParamValue : collected technical data
%   o_tabTechNMeas     : collected technical PARAM data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_techNcParamIndex, o_techNcParamValue, o_tabTechNMeas] = ...
   collect_technical_data_cts5_usea(a_tabTech)

% output parameters initialization
o_techNcParamIndex = [];
o_techNcParamValue = [];
o_tabTechNMeas = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloat;
global g_decArgo_patternNumFloat;

% decoded TECH event data
global g_decArgo_eventDataTech;

% decoded TECH PARAM event data
global g_decArgo_eventDataParamTech;

% global time status
global g_JULD_STATUS_2;

% cycle phases
global g_decArgo_phaseSatTrans;

% output NetCDF technical parameter names additional information
global g_decArgo_outputNcParamLabelInfo;
global g_decArgo_outputNcParamLabelInfoCounter;


COMPARISON_FLAG = 0;

% array to store tech data from both sources
techDataAll = [];

% retrieve tech data from TECH files
for idPack = 1:size(a_tabTech, 1)
   cycleNumber = a_tabTech{idPack, 1};
   profileNumber = a_tabTech{idPack, 2};
   techData = a_tabTech{idPack, 4};
   for idT = 1:length(techData)
      techDataAll = [techDataAll; ...
         cycleNumber profileNumber ...
         {techData{idT}.source} techData{idT}.techId techData{idT}.valueRaw techData{idT}.valueOutput {techData{idT}.shortSensorName}];
   end
end

% retrieve tech data from events
for idEvt = 1:length(g_decArgo_eventDataTech)
   eventData = g_decArgo_eventDataTech{idEvt};
   techDataAll = [techDataAll; ...
      g_decArgo_cycleNumFloat g_decArgo_patternNumFloat ...
      {eventData.source} eventData.techId eventData.valueRaw eventData.valueOutput {''}];
end

noArgoSensorNameList = [ ...
   {'Uvp'} ...
   {'UvpLpm'} ...
   {'UvpBlk'} ...
   {'OpusLgt'} ...
   {'OpusBlk'} ...
   {'Ramses'} ...
   {'Mpe'} ...
   {'HydrocC'} ...
   {'HydrocM'} ...
   ];
specificTechIdList = 216:221; % TECH Ids for witch a sensor of noArgoSensorNameList need a change (+ 1000) of TECH label
if (~isempty(techDataAll))
   
   % merge Tech and Event technical information
   idToDel = [];
   idFTech = find([techDataAll{:, 3}] == 'T');
   idFEvt = find([techDataAll{:, 3}] == 'E');
   uEvtTechId = unique([techDataAll{idFEvt, 4}]);
   for idTechId = 1:length(uEvtTechId)
      idT = find([techDataAll{idFTech, 4}] == uEvtTechId(idTechId));
      idE = find([techDataAll{idFEvt, 4}] == uEvtTechId(idTechId));
      if (~isempty(idT) && ~isempty(idE))
         idT = idFTech(idT);
         idE = idFEvt(idE);
         if (length(idT) > 1)
            idToDel = [idToDel idT(2:end)];
            idT = idT(1);
         end
         if (length(idE) > 1)
            idToDel = [idToDel idE(2:end)];
            idE = idE(1);
         end
         useEvent = 0;
         if (~strcmp(techDataAll{idT, 6}, techDataAll{idE, 6}))
            switch (uEvtTechId(idTechId))
               case {161, 162, 171, 185}
                  % 1
                  useEvent = 0;
               case {173}
                  % 1
                  useEvent = 1;
               case {102}
                  % .01
                  if (~strcmp(sprintf('%.2f', techDataAll{idT, 5}), sprintf('%.2f', techDataAll{idE, 5})))
                     useEvent = 0;
                  end
               case {103, 104}
                  % .1
                  if (~strcmp(sprintf('%.1f', techDataAll{idT, 5}), sprintf('%.1f', techDataAll{idE, 5})))
                     useEvent = 0;
                  end
               case {110, 121, 124, 184}
                  % dates
                  if (abs(techDataAll{idT, 5} - techDataAll{idE, 5}) > 1/86400)
                     useEvent = 1;
                  end
               otherwise
                  fprintf('WARNING: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Don''t know how to compare Tech and Event data for techId #%d\n', ...
                     g_decArgo_floatNum, ...
                     g_decArgo_cycleNum, ...
                     g_decArgo_cycleNumFloat, ...
                     g_decArgo_patternNumFloat, ...
                     uEvtTechId(idTechId));
            end
            if (COMPARISON_FLAG == 1)
               if (useEvent == 0)
                  fprintf('WARNING: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Tech and Event data differ for techId #%d: tech=''%s'' and evt=''%s'' - using the Tech one\n', ...
                     g_decArgo_floatNum, ...
                     g_decArgo_cycleNum, ...
                     g_decArgo_cycleNumFloat, ...
                     g_decArgo_patternNumFloat, ...
                     uEvtTechId(idTechId), techDataAll{idT, 6}, techDataAll{idE, 6});
               elseif (useEvent == 1)
                  fprintf('WARNING: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Tech and Event data differ for techId #%d: tech=''%s'' and evt=''%s'' - using the Event one\n', ...
                     g_decArgo_floatNum, ...
                     g_decArgo_cycleNum, ...
                     g_decArgo_cycleNumFloat, ...
                     g_decArgo_patternNumFloat, ...
                     uEvtTechId(idTechId), techDataAll{idT, 6}, techDataAll{idE, 6});
               end
            end
         end
         if (useEvent == 1)
            idToDel = [idToDel idT];
         else
            idToDel = [idToDel idE];
         end
      end
   end
   techDataAll(idToDel, :) = [];
   
   % fill output parameters
   o_techNcParamIndex = cell2mat(techDataAll(:, [1 2 4]));
   o_techNcParamIndex = cat(2, ...
      ones(size(techDataAll, 1), 1)*-1, ...
      o_techNcParamIndex(:, [1 2]), ...
      zeros(size(techDataAll, 1), 1), ...
      o_techNcParamIndex(:, 3), ...
      ones(size(techDataAll, 1), 1)*g_decArgo_cycleNum);
   o_techNcParamValue = techDataAll(:, 6);
   
   % additional information on short sensor names
   for idT = 1:size(o_techNcParamIndex, 1)
      if (~isempty(techDataAll{idT, 7}))
         if (ismember(o_techNcParamIndex(idT, 5), specificTechIdList) && ...
               ismember(techDataAll{idT, 7}, noArgoSensorNameList))
            % for TECH Id of the specificTechIdList AND sensor name of noArgoSensorNameList
            % we should switch to a TECH_AUX label
            o_techNcParamIndex(idT, 5) = o_techNcParamIndex(idT, 5) + 1000;
         end
         o_techNcParamIndex(idT, 4) = g_decArgo_outputNcParamLabelInfoCounter*-1;
         g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<short_sensor_name>'} techDataAll(idT, 7)];
         g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
      end
   end   
end

% retrieve tech PARAM data from events
if (~isempty(g_decArgo_eventDataParamTech))
   
   tabTechParamIndex = [];
   tabTechParamData = [];
   
   groupList = cell2mat(g_decArgo_eventDataParamTech)';
   groupList = [groupList.group];
   uGroupList = unique(groupList(find(groupList > 0)));
   for idG = 1:length(uGroupList)
      idF = find(groupList == uGroupList(idG));
      tabTechParamIndex = [tabTechParamIndex;
         g_decArgo_eventDataParamTech{idF(1)}.measCode g_decArgo_eventDataParamTech{idF(1)}.cycleNumber g_decArgo_eventDataParamTech{idF(1)}.patternNumber -1];
      tabTechParamData = [tabTechParamData; {g_decArgo_eventDataParamTech(idF)}];
   end
   idF = find(groupList == 0);
   for idG = idF
      tabTechParamIndex = [tabTechParamIndex;
         g_decArgo_eventDataParamTech{idG}.measCode g_decArgo_eventDataParamTech{idG}.cycleNumber g_decArgo_eventDataParamTech{idG}.patternNumber -1];
      tabTechParamData = [tabTechParamData; {g_decArgo_eventDataParamTech(idG)}];
   end
   
   paramValveActionFlag = get_netcdf_param_attributes('VALVE_ACTION_FLAG');
   paramPumpActionFlag = get_netcdf_param_attributes('PUMP_ACTION_FLAG');

   cycleNumList = sort(unique(tabTechParamIndex(:, 2)));
   profNumList = sort(unique(tabTechParamIndex(:, 3)));
   for idCyc = 1:length(cycleNumList)
      cycleNum = cycleNumList(idCyc);
      for idPrf = 1:length(profNumList)
         profNum = profNumList(idPrf);
         
         techNMeasStruct = get_traj_n_meas_init_struct(cycleNum, profNum);
                  
         % spy measurements
         idPackData  = find( ...
            (tabTechParamIndex(:, 2) == cycleNum) & ...
            (tabTechParamIndex(:, 3) == profNum));
         measDataTab = repmat(get_traj_one_meas_init_struct, length(idPackData), 1);
         for idspyMeas = 1:length(idPackData)
            id = idPackData(idspyMeas);
            data = tabTechParamData{id};
            paramName = cell2mat(data);
            paramName = {paramName.paramName};
            [measStruct, ~] = create_one_meas_float_time_bis(tabTechParamIndex(id, 1), ...
               data{find(strcmp(paramName, 'JULD'), 1)}.value, ...
               data{find(strcmp(paramName, 'JULD'), 1)}.valueAdj, ...
               g_JULD_STATUS_2);
            if (any(strcmp(paramName, 'VALVE_ACTION_FLAG')))
               measStruct.paramList = paramValveActionFlag;
               measStruct.paramData = single(data{find(strcmp(paramName, 'VALVE_ACTION_FLAG'), 1)}.value);
            elseif (any(strcmp(paramName, 'PUMP_ACTION_FLAG')))
               measStruct.paramList = paramPumpActionFlag;
               measStruct.paramData = single(data{find(strcmp(paramName, 'PUMP_ACTION_FLAG'), 1)}.value);
            end
            measStruct.cyclePhase = g_decArgo_phaseSatTrans;
            measDataTab(idspyMeas) = measStruct;
         end
         measData = measDataTab;
         
         % sort the data by date
         if (~isempty(measData))
            measDates = [measData.juld];
            [measDates, idSort] = sort(measDates);
            measData = measData(idSort);
            
            % store the data
            techNMeasStruct.tabMeas = [techNMeasStruct.tabMeas; measData];
         end
         
         o_tabTechNMeas = [o_tabTechNMeas techNMeasStruct];
      end
   end
end

return
