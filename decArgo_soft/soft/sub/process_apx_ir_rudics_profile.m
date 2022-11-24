% ------------------------------------------------------------------------------
% Create the profiles of decoded data.
%
% SYNTAX :
%  [o_ncProfile] = process_apx_ir_rudics_profile( ...
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
function [o_ncProfile] = process_apx_ir_rudics_profile( ...
   a_profLrData, a_profHrData, a_nearSurfData, ...
   a_cycleNum, a_presOffsetData)

% output parameters initialization
o_ncProfile = [];

% global default values
global g_decArgo_dateDef;


if (isempty(a_profLrData) && isempty(a_profHrData) && isempty(a_nearSurfData))
   return;
end

if (~isempty(a_profLrData))
   
   % initialize a NetCDF profile structure and fill it with decoded profile data
   profStruct = get_profile_init_struct(a_cycleNum, -1, -1, -1);
   profStruct.sensorNumber = 0;
   
   % positioning system
   profStruct.posSystem = 'GPS';
   
   % add parameter variables to the profile structure
   profStruct.paramList = a_profLrData.paramList;
   
   % add parameter data to the profile structure
   profStruct.data = a_profLrData.data;
   profStruct.dataAdj = a_profLrData.dataAdj;
   
   % add press offset data to the profile structure
   idCycleStruct = find([a_presOffsetData.cycleNumAdjPres] == a_cycleNum);
   if (~isempty(idCycleStruct))
      profStruct.presOffset = a_presOffsetData.presOffset(idCycleStruct);
   end
   
   % add configuration mission number
   profStruct.configMissionNumber = get_config_mission_number_ir_sbd(a_cycleNum);
   
   % add vertical sampling scheme
   profStruct.vertSamplingScheme = 'Primary sampling: discrete [Low resolution profile]';
   profStruct.primarySamplingProfileFlag = 1;
      
   % create an AUX profile with measurement dates (stored in MTIME)
   profStructAux = [];
   if (~isempty(a_profLrData.dateList))
      if (any(a_profLrData.dates ~= a_profLrData.dateList.fillValue))
         
         profStructAux = profStruct;
         profStructAux.sensorNumber = 101;
         idPres  = find(strcmp({profStruct.paramList.name}, 'PRES') == 1, 1);
         profStructAux.paramList = profStructAux.paramList(idPres);
         % BE CAREFUL: profStructAux.data should be a double precision array (to
         % store final MTIME values with their full resolution
         profStructAux.data = double(profStructAux.data(:, idPres));
         if (~isempty(profStructAux.dataAdj))
            profStructAux.dataAdj = double(profStructAux.dataAdj(:, idPres));
         end
         
         paramMtime = get_netcdf_param_attributes('MTIME');
         % we temporarily store JULD in MTIME (because profile date will be
         % computed later)
         mtimeData = a_profLrData.dates;
         %          if (profStructAux.date ~= g_decArgo_dateDef)
         %             mtimeData = a_profLrData.dates-profStructAux.date;
         %          else
         %             mtimeData = ones(size(a_profLrData.dates))*paramMtime.fillValue;
         %          end
         profStructAux.paramList = [profStructAux.paramList paramMtime];
         profStructAux.data = [profStructAux.data mtimeData];
         if (~isempty(profStructAux.dataAdj))
            profStructAux.dataAdj = [profStructAux.dataAdj mtimeData];
         end
      end
   end
   
   profStruct = squeeze_profile_data(profStruct);
   profStructAux = squeeze_profile_data(profStructAux);
   
   o_ncProfile = [o_ncProfile profStruct profStructAux];
   
end

if (~isempty(a_profHrData))
   
   % initialize a NetCDF profile structure and fill it with decoded profile data
   profStruct = get_profile_init_struct(a_cycleNum, -1, -1, -1);
   profStruct.sensorNumber = 0;
   
   % positioning system
   profStruct.posSystem = 'GPS';
   
   % add parameter variables to the profile structure
   profStruct.paramList = a_profHrData.paramList;
   
   % add parameter data to the profile structure
   profStruct.data = a_profHrData.data;
   profStruct.dataAdj = a_profHrData.dataAdj;
   
   % add press offset data to the profile structure
   idCycleStruct = find([a_presOffsetData.cycleNumAdjPres] == a_cycleNum);
   if (~isempty(idCycleStruct))
      profStruct.presOffset = a_presOffsetData.presOffset(idCycleStruct);
   end
   
   % add configuration mission number
   profStruct.configMissionNumber = get_config_mission_number_ir_sbd(a_cycleNum);
   
   % add vertical sampling scheme
   if (~isempty(o_ncProfile))
      profStruct.vertSamplingScheme = 'Secondary sampling: averaged [High resolution profile]';
      profStruct.primarySamplingProfileFlag = 0;
   else
      profStruct.vertSamplingScheme = 'Primary sampling: averaged [High resolution profile]';
      profStruct.primarySamplingProfileFlag = 1;
   end
      
   % create an AUX profile with NB_SAMPLE information
   profStructAux = [];
   idNbSample  = find(strcmp({profStruct.paramList.name}, 'NB_SAMPLE') == 1, 1);
   if (~isempty(idNbSample))
      
      profStructAux = profStruct;
      profStructAux.sensorNumber = 101;
      profStruct.paramList(idNbSample) = [];
      profStruct.data(:, idNbSample) = [];
      if (~isempty(profStruct.dataAdj))
         profStruct.dataAdj(:, idNbSample) = [];
      end
      
      idPres  = find(strcmp({profStruct.paramList.name}, 'PRES') == 1, 1);
      profStructAux.paramList = [profStructAux.paramList(idPres) profStructAux.paramList(idNbSample)];
      profStructAux.data = [profStructAux.data(:, idPres) profStructAux.data(:, idNbSample)];
      if (~isempty(profStructAux.dataAdj))
         profStructAux.dataAdj = [profStructAux.dataAdj(:, idPres) profStructAux.dataAdj(:, idNbSample)];
      end
   end
   
   profStruct = squeeze_profile_data(profStruct);
   profStructAux = squeeze_profile_data(profStructAux);
   
   o_ncProfile = [o_ncProfile profStruct profStructAux];
   
end

if (~isempty(a_nearSurfData))
   
   % the same set of NS data is transmitted at each transmission session => we
   % only consider the first one
   a_nearSurfData = a_nearSurfData{1};
   
   % initialize a NetCDF profile structure and fill it with decoded profile data
   profStruct = get_profile_init_struct(a_cycleNum, -1, -1, -1);
   profStruct.sensorNumber = 0;
   
   % positioning system
   profStruct.posSystem = 'GPS';
   
   % add parameter variables to the profile structure
   profStruct.paramList = a_nearSurfData.paramList;
   
   % add parameter data to the profile structure
   profStruct.data = a_nearSurfData.data;
   profStruct.dataAdj = a_nearSurfData.dataAdj;
   
   % add press offset data to the profile structure
   idCycleStruct = find([a_presOffsetData.cycleNumAdjPres] == a_cycleNum);
   if (~isempty(idCycleStruct))
      profStruct.presOffset = a_presOffsetData.presOffset(idCycleStruct);
   end
   
   % add configuration mission number
   profStruct.configMissionNumber = get_config_mission_number_ir_sbd(a_cycleNum);
   
   % add vertical sampling scheme
   profStruct.vertSamplingScheme = 'Near-surface sampling: []';
   profStruct.primarySamplingProfileFlag = 0;
      
   % create an AUX profile with measurement dates (stored in MTIME)
   profStructAux = [];
   if (~isempty(a_nearSurfData.dateList))
      if (any(a_nearSurfData.dates ~= a_nearSurfData.dateList.fillValue))
         
         profStructAux = profStruct;
         profStructAux.sensorNumber = 101;
         idPres  = find(strcmp({profStruct.paramList.name}, 'PRES') == 1, 1);
         profStructAux.paramList = profStructAux.paramList(idPres);
         % BE CAREFUL: profStructAux.data should be a double precision array (to
         % store final MTIME values with their full resolution
         profStructAux.data = double(profStructAux.data(:, idPres));
         if (~isempty(profStructAux.dataAdj))
            profStructAux.data = double(profStructAux.dataAdj(:, idPres));
         end
         
         paramMtime = get_netcdf_param_attributes('MTIME');
         % we temporarily store JULD in MTIME (because profile date will be
         % computed later)
         mtimeData = a_nearSurfData.dates;
         %          if (profStructAux.date ~= g_decArgo_dateDef)
         %             mtimeData = a_nearSurfData.dates-profStructAux.date;
         %          else
         %             mtimeData = ones(size(a_nearSurfData.dates))*paramMtime.fillValue;
         %          end
         profStructAux.paramList = [profStructAux.paramList paramMtime];
         profStructAux.data = [profStructAux.data mtimeData];
         if (~isempty(profStructAux.dataAdj))
            profStructAux.dataAdj = [profStructAux.dataAdj mtimeData];
         end
      end
   end
   
   profStruct = squeeze_profile_data(profStruct);
   profStructAux = squeeze_profile_data(profStructAux);
   
   o_ncProfile = [o_ncProfile profStruct profStructAux];
   
end

return;
