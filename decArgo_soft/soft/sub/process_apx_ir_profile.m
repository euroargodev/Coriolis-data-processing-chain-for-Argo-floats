% ------------------------------------------------------------------------------
% Create the profiles of decoded data.
%
% SYNTAX :
%  [o_ncProfile] = process_apx_ir_profile( ...
%    a_profLrData, a_profHrData, a_nearSurfData, ...
%    a_cycleNum, a_presOffsetData)
%
% INPUT PARAMETERS :
%   a_profLrData     : LR profile data
%   a_profHrData     : HR profile data
%   a_nearSurfData   : NS profile data
%   a_cycleNum       : cycle number
%   a_presOffsetData : pressure offset data structure
%
% OUTPUT PARAMETERS :
%   o_ncProfile : created output profiles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncProfile] = process_apx_ir_profile( ...
   a_profLrData, a_profHrData, a_nearSurfData, ...
   a_cycleNum, a_presOffsetData)

% output parameters initialization
o_ncProfile = [];


if (isempty(a_profLrData) && isempty(a_profHrData) && isempty(a_nearSurfData))
   return;
end

profLrStruct = [];
profHrStruct = [];
profHrAuxStruct = [];

if (~isempty(a_profLrData))
   
   % initialize a NetCDF profile structure and fill it with decoded profile data
   profLrStruct = get_profile_init_struct(a_cycleNum, -1, -1, -1);
   profLrStruct.sensorNumber = 0;
   
   % positioning system
   profLrStruct.posSystem = 'GPS';
   
   % add parameter variables to the profile structure
   profLrStruct.paramList = a_profLrData.paramList;
   
   % add parameter data to the profile structure
   profLrStruct.data = a_profLrData.data;
   profLrStruct.dataAdj = a_profLrData.dataAdj;
   
   % add press offset data to the profile structure
   idCycleStruct = find([a_presOffsetData.cycleNumAdjPres] == a_cycleNum);
   if (~isempty(idCycleStruct))
      profLrStruct.presOffset = a_presOffsetData.presOffset(idCycleStruct);
   end
   
   % add configuration mission number
   profLrStruct.configMissionNumber = get_config_mission_number_ir_sbd(a_cycleNum);
   
   % add MTIME to data
   if (~isempty(a_profLrData.dateList))
      paramMtime = get_netcdf_param_attributes('MTIME');
      if (any(a_profLrData.dates ~= a_profLrData.dateList.fillValue))
         % we temporarily store JULD as MTIME (because profile date will be
         % computed later)
         mtimeData = a_profLrData.dates;
         mtimeData(find(mtimeData == a_profLrData.dateList.fillValue)) = paramMtime.fillValue;
      else
         mtimeData = ones(size(a_profLrData.data, 1), 1)*paramMtime.fillValue;
      end
      profLrStruct.paramList = [paramMtime profLrStruct.paramList];
      profLrStruct.data = cat(2, mtimeData, double(profLrStruct.data));
      
      if (~isempty(a_profLrData.dataAdj))
         if (any(a_profLrData.datesAdj ~= a_profLrData.dateList.fillValue))
            % we temporarily store JULD as MTIME (because profile date will be
            % computed later)
            if (~isempty(a_profLrData.datesAdj))
               mtimeDataAdj = a_profLrData.datesAdj;
               mtimeDataAdj(find(mtimeDataAdj == a_profLrData.dateList.fillValue)) = paramMtime.fillValue;
            elseif (~isempty(a_profLrData.dates))
               mtimeDataAdj = a_profLrData.dates;
               mtimeDataAdj(find(mtimeDataAdj == a_profLrData.dateList.fillValue)) = paramMtime.fillValue;
            else
               mtimeDataAdj = ones(size(a_profLrData.dataAdj, 1), 1)*paramMtime.fillValue;
            end
         else
            mtimeDataAdj = ones(size(a_profLrData.dataAdj, 1), 1)*paramMtime.fillValue;
         end
         profLrStruct.dataAdj = cat(2, mtimeDataAdj, double(profLrStruct.dataAdj));
      end
   end   
   
   profLrStruct = squeeze_profile_data(profLrStruct);   
end

if (~isempty(a_profHrData))
   
   % initialize a NetCDF profile structure and fill it with decoded profile data
   profHrStruct = get_profile_init_struct(a_cycleNum, -1, -1, -1);
   profHrStruct.sensorNumber = 0;
   
   % positioning system
   profHrStruct.posSystem = 'GPS';
   
   % add parameter variables to the profile structure
   profHrStruct.paramList = a_profHrData.paramList;
   
   % add parameter data to the profile structure
   profHrStruct.data = a_profHrData.data;
   profHrStruct.dataAdj = a_profHrData.dataAdj;
   
   % add press offset data to the profile structure
   idCycleStruct = find([a_presOffsetData.cycleNumAdjPres] == a_cycleNum);
   if (~isempty(idCycleStruct))
      profHrStruct.presOffset = a_presOffsetData.presOffset(idCycleStruct);
   end
   
   % add configuration mission number
   profHrStruct.configMissionNumber = get_config_mission_number_ir_sbd(a_cycleNum);
   
   % create an AUX profile with NB_SAMPLE information
   % HR AUX profiles have 2 parameters PRES and NB_SAMPLE
   profHrAuxStruct = [];
   idNbSample  = find(strcmp({profHrStruct.paramList.name}, 'NB_SAMPLE') == 1, 1);
   if (~isempty(idNbSample))
      
      profHrAuxStruct = profHrStruct;
      profHrAuxStruct.sensorNumber = 101; % to go to PROF_AUX file
      profHrStruct.paramList(idNbSample) = [];
      profHrStruct.data(:, idNbSample) = [];
      if (~isempty(profHrStruct.dataAdj))
         profHrStruct.dataAdj(:, idNbSample) = [];
      end
      
      idPres  = find(strcmp({profHrStruct.paramList.name}, 'PRES') == 1, 1);
      profHrAuxStruct.paramList = [profHrAuxStruct.paramList(idPres) profHrAuxStruct.paramList(idNbSample)];
      profHrAuxStruct.data = [profHrAuxStruct.data(:, idPres) profHrAuxStruct.data(:, idNbSample)];
      if (~isempty(profHrAuxStruct.dataAdj))
         profHrAuxStruct.dataAdj = [profHrAuxStruct.dataAdj(:, idPres) profHrAuxStruct.dataAdj(:, idNbSample)];
      end
   end
   
   profHrStruct = squeeze_profile_data(profHrStruct);
   profHrAuxStruct = squeeze_profile_data(profHrAuxStruct);
   
end

if (~isempty(profLrStruct) && ~isempty(profHrStruct))
   
   % merge HR and LR profiles to the primary sampling one
   [profMergedStruct, profLrStruct, profMergedHrAuxStruct] = ...
      merge_profile_LR_HR(profLrStruct, profHrStruct, profHrAuxStruct);
   
   o_ncProfile = [o_ncProfile profMergedStruct profMergedHrAuxStruct profLrStruct];

elseif (~isempty(profLrStruct))
   
   % add vertical sampling scheme
   profLrStruct.vertSamplingScheme = 'Primary sampling: discrete [low resolution profile]';
   profLrStruct.primarySamplingProfileFlag = 1;
      
   o_ncProfile = [o_ncProfile profLrStruct];
   
elseif (~isempty(profHrStruct))
   
   % add vertical sampling scheme
   profHrStruct.vertSamplingScheme = 'Primary sampling: averaged [high resolution profile: 2dbar-bin averaged]';
   profHrStruct.primarySamplingProfileFlag = 1;
   
   if (~isempty(profHrAuxStruct))
      profHrAuxStruct.vertSamplingScheme = 'Primary sampling: averaged [high resolution profile: 2dbar-bin averaged]';
      profHrAuxStruct.primarySamplingProfileFlag = 1;
   end
   
   o_ncProfile = [o_ncProfile profHrStruct profHrAuxStruct];
   
end

if (~isempty(a_nearSurfData))
   
   % the same set of NS data is transmitted at each transmission session => we
   % only consider the first one
   a_nearSurfData = a_nearSurfData{1};
   
   % initialize a NetCDF profile structure and fill it with decoded profile data
   profNsStruct = get_profile_init_struct(a_cycleNum, -1, -1, -1);
   profNsStruct.sensorNumber = 0;
   
   % positioning system
   profNsStruct.posSystem = 'GPS';
   
   % add parameter variables to the profile structure
   profNsStruct.paramList = a_nearSurfData.paramList;
   
   % add parameter data to the profile structure
   profNsStruct.data = a_nearSurfData.data;
   profNsStruct.dataAdj = a_nearSurfData.dataAdj;
   
   % add press offset data to the profile structure
   idCycleStruct = find([a_presOffsetData.cycleNumAdjPres] == a_cycleNum);
   if (~isempty(idCycleStruct))
      profNsStruct.presOffset = a_presOffsetData.presOffset(idCycleStruct);
   end
   
   % add configuration mission number
   profNsStruct.configMissionNumber = get_config_mission_number_ir_sbd(a_cycleNum);
   
   % add vertical sampling scheme
   profNsStruct.vertSamplingScheme = 'Near-surface sampling: []';
   profNsStruct.primarySamplingProfileFlag = 0;
   
   % add MTIME to data
   if (~isempty(a_nearSurfData.dateList))
      paramMtime = get_netcdf_param_attributes('MTIME');
      if (any(a_nearSurfData.dates ~= a_nearSurfData.dateList.fillValue))
         % we temporarily store JULD as MTIME (because profile date will be
         % computed later)
         mtimeData = a_nearSurfData.dates;
         mtimeData(find(mtimeData == a_nearSurfData.dateList.fillValue)) = paramMtime.fillValue;
      else
         mtimeData = ones(size(a_nearSurfData.data, 1), 1)*paramMtime.fillValue;
      end
      profNsStruct.paramList = [paramMtime profNsStruct.paramList];
      profNsStruct.data = cat(2, mtimeData, double(profNsStruct.data));
      
      if (~isempty(a_nearSurfData.dataAdj))
         if (any(a_nearSurfData.datesAdj ~= a_nearSurfData.dateList.fillValue))
            % we temporarily store JULD as MTIME (because profile date will be
            % computed later)
            if (~isempty(a_nearSurfData.datesAdj))
               mtimeDataAdj = a_nearSurfData.datesAdj;
               mtimeDataAdj(find(mtimeDataAdj == a_nearSurfData.dateList.fillValue)) = paramMtime.fillValue;
            elseif (~isempty(a_nearSurfData.dates))
               mtimeDataAdj = a_nearSurfData.dates;
               mtimeDataAdj(find(mtimeDataAdj == a_nearSurfData.dateList.fillValue)) = paramMtime.fillValue;
            else
               mtimeDataAdj = ones(size(a_nearSurfData.dataAdj, 1), 1)*paramMtime.fillValue;
            end
         else
            mtimeDataAdj = ones(size(a_nearSurfData.dataAdj, 1), 1)*paramMtime.fillValue;
         end
         profNsStruct.dataAdj = cat(2, mtimeDataAdj, double(profNsStruct.dataAdj));
      end      
   end   
   
   profNsStruct = squeeze_profile_data(profNsStruct);
   
   o_ncProfile = [o_ncProfile profNsStruct];
   
end

return;

% ------------------------------------------------------------------------------
% Merge HR and LR profiles to create the primary sampling one.
%
% SYNTAX :
%  [o_profMergedStruct, o_profLrStruct, o_profMergedHrAuxStruct] = ...
%    merge_profile_LR_HR(a_profLrStruct, a_profHrStruct, a_profHrAuxStruct)
%
% INPUT PARAMETERS :
%   a_profLrStruct    : input LR profile
%   a_profHrStruct    : input HR profile
%   a_profHrAuxStruct : input HR AUX profile
%
% OUTPUT PARAMETERS :
%   o_profMergedStruct      : output merged profile
%   o_profLrStruct          : output LR profile
%   o_profMergedHrAuxStruct : output merged HR AUX profile
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/02/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profMergedStruct, o_profLrStruct, o_profMergedHrAuxStruct] = ...
   merge_profile_LR_HR(a_profLrStruct, a_profHrStruct, a_profHrAuxStruct)

% output parameters initialization
o_profMergedStruct = [];
o_profLrStruct = [];
o_profMergedHrAuxStruct = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


% retrieve the list of common parameters
mergedParamList = [];
paramListIdHr = [];
paramListIdLr = [];
for idP = 1:length(a_profHrStruct.paramList)
   idF = find(strcmp(a_profHrStruct.paramList(idP).name, {a_profLrStruct.paramList.name}));
   if (~isempty(idF))
      mergedParamList = [mergedParamList a_profHrStruct.paramList(idP)];
      paramListIdHr = [paramListIdHr idP];
      paramListIdLr = [paramListIdLr idF];
   end
end

% if HR profile has additionnal parameters (this is the case for BGC floats),
% the LR profile is store in the PROF file (as a secondary profile)
if ~(isempty(setdiff(sort({a_profLrStruct.paramList.name}), sort({a_profHrStruct.paramList.name}))) && ...
      isempty(setdiff(sort({a_profHrStruct.paramList.name}), sort({a_profLrStruct.paramList.name}))))
   o_profLrStruct = a_profLrStruct;
   o_profLrStruct.vertSamplingScheme = 'Secondary sampling: discrete [low resolution profile]';
end

idPresHr = find(strcmp('PRES', {a_profHrStruct.paramList.name}));
idPresLr = find(strcmp('PRES', {a_profLrStruct.paramList.name}));

if (~isempty(idPresHr) && ~isempty(idPresLr))
   
   mergedData = a_profHrStruct.data(:, paramListIdHr);
   mergedDataAdj = a_profHrStruct.dataAdj(:, paramListIdHr);
   
   if (~isempty(a_profHrAuxStruct))
      mergedHrAuxData = a_profHrAuxStruct.data;
      mergedHrAuxDataAdj = a_profHrAuxStruct.dataAdj;
   end
   
   presHr = a_profHrStruct.data(:, idPresHr);
   presLr = a_profLrStruct.data(:, idPresLr);
   presHrBis = presHr(presHr ~= a_profHrStruct.paramList(idPresHr).fillValue);
   presHrDeepest = presHrBis(1);
   presHrShallowest = presHrBis(end);
   
   idFLastLrDeep = find(presLr > presHrDeepest);
   if (~isempty(idFLastLrDeep))
   
      idFLastLrDeep = idFLastLrDeep(end);
      
      mergedData = cat(1, a_profLrStruct.data(1:idFLastLrDeep, paramListIdLr), mergedData);
      mergedDataAdj = cat(1, a_profLrStruct.dataAdj(1:idFLastLrDeep, paramListIdLr), mergedDataAdj);
            
      if (~isempty(a_profHrAuxStruct))
         mergedHrAuxData = cat(1, ...
            cat(2, a_profLrStruct.data(1:idFLastLrDeep, idPresLr), ...
            ones(idFLastLrDeep, 1)*a_profHrAuxStruct.paramList(2).fillValue), ...
            mergedHrAuxData);
         mergedHrAuxDataAdj = cat(1, ...
            cat(2, a_profLrStruct.dataAdj(1:idFLastLrDeep, idPresLr), ...
            ones(idFLastLrDeep, 1)*a_profHrAuxStruct.paramList(2).fillValue), ...
            mergedHrAuxDataAdj);
      end
   end
   
   idFFistLrShallow = find(presLr < presHrShallowest);
   if (~isempty(idFFistLrShallow))

      idFFistLrShallow = idFFistLrShallow(1);
      
      mergedData = cat(1, mergedData, a_profLrStruct.data(idFFistLrShallow:end, paramListIdLr));
      mergedDataAdj = cat(1, mergedDataAdj, a_profLrStruct.dataAdj(idFFistLrShallow:end, paramListIdLr));
            
      if (~isempty(a_profHrAuxStruct))
         mergedHrAuxData = cat(1, ...
            mergedHrAuxData, ...
            cat(2, a_profLrStruct.data(idFFistLrShallow:end, idPresLr), ...
            ones(size(a_profLrStruct.data, 1)-idFFistLrShallow+1, 1)*a_profHrAuxStruct.paramList(2).fillValue));
         mergedHrAuxDataAdj = cat(1, ...
            mergedHrAuxDataAdj, ...
            cat(2, a_profLrStruct.dataAdj(idFFistLrShallow:end, idPresLr), ...
            ones(size(a_profLrStruct.dataAdj, 1)-idFFistLrShallow+1, 1)*a_profHrAuxStruct.paramList(2).fillValue));
      end
   end
   
   % initialize a NetCDF profile structure and fill it with merged profile data
   o_profMergedStruct = get_profile_init_struct(a_profLrStruct.cycleNumber, -1, -1, -1);
   o_profMergedStruct.sensorNumber = 0;
   
   % positioning system
   o_profMergedStruct.posSystem = 'GPS';
   
   % add parameter variables to the profile structure
   o_profMergedStruct.paramList = mergedParamList;
   
   % add parameter data to the profile structure
   o_profMergedStruct.data = mergedData;
   o_profMergedStruct.dataAdj = mergedDataAdj;
   
   % add press offset data to the profile structure
   o_profMergedStruct.presOffset = a_profLrStruct.presOffset;
   
   % add configuration mission number
   o_profMergedStruct.configMissionNumber = a_profLrStruct.configMissionNumber;
   
   % create vertical sampling scheme
   if (~isempty(idFLastLrDeep) && ~isempty(idFFistLrShallow))
      vertSamplingScheme = sprintf('Primary sampling: mixed [PRES < %g dbar and PRES > %g dbar: discrete; otherwise: 2dbar-bin averaged]', ...
         presHrShallowest, presHrDeepest);
   elseif (~isempty(idFLastLrDeep))
      vertSamplingScheme = sprintf('Primary sampling: mixed [PRES > %g dbar: discrete; otherwise: 2dbar-bin averaged]', ...
         presHrDeepest);
   elseif (~isempty(idFFistLrShallow))
      vertSamplingScheme = sprintf('Primary sampling: mixed [PRES < %g dbar: discrete; otherwise: 2dbar-bin averaged]', ...
         presHrShallowest);
   else
      vertSamplingScheme = 'Primary sampling: averaged [2dbar-bin averaged]';
   end
   
   % add vertical sampling scheme
   o_profMergedStruct.vertSamplingScheme = vertSamplingScheme;
   o_profMergedStruct.primarySamplingProfileFlag = 1;

   % update HR AUX profiles
   if (~isempty(a_profHrAuxStruct))
      o_profMergedHrAuxStruct = a_profHrAuxStruct;
      
      o_profMergedHrAuxStruct.data = mergedHrAuxData;
      o_profMergedHrAuxStruct.dataAdj = mergedHrAuxDataAdj;
      
      o_profMergedHrAuxStruct.vertSamplingScheme = o_profMergedStruct.vertSamplingScheme;
      o_profMergedHrAuxStruct.primarySamplingProfileFlag = 1;
   end
   
else
   fprintf('ERROR: Float #%d Cycle #%d: Unable to get PRES data to merge HR and LR profiles\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
end

return;
