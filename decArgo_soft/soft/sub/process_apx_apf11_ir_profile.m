% ------------------------------------------------------------------------------
% Create the profiles of decoded data.
%
% SYNTAX :
%  [o_ncProfile] = process_apx_apf11_ir_profile( ...
%    a_profCtdPts, a_profCtdCp, a_cycleTimeData, ...
%    a_cycleNum, a_presOffsetData)
%
% INPUT PARAMETERS :
%   a_profCtdPts     : CTD_PTS data
%   a_profCtdCp      : CTD_CP data
%   a_cycleTimeData  : cycle timings data
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
%   06/05/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncProfile] = process_apx_apf11_ir_profile( ...
   a_profCtdPts, a_profCtdCp, a_cycleTimeData, ...
   a_cycleNum, a_presOffsetData)

% output parameters initialization
o_ncProfile = [];


if (isempty(a_profCtdPts) && isempty(a_profCtdCp))
   return;
end

% select PTS measurements sampled during the ascending profile
profCtdPts = [];
if (~isempty(a_profCtdPts) && ...
      ~isempty(a_cycleTimeData.ascentStartDateSci) && ...
      ~isempty(a_cycleTimeData.ascentEndDateSci) && ...
      any((a_profCtdPts.dates >= a_cycleTimeData.ascentStartDateSci) & (a_profCtdPts.dates <= a_cycleTimeData.ascentEndDateSci)))
   profCtdPts = a_profCtdPts;
   idProfMeas = find(((a_profCtdPts.dates >= a_cycleTimeData.ascentStartDateSci) & (a_profCtdPts.dates <= a_cycleTimeData.ascentEndDateSci)) == 1);
   profCtdPts.data = profCtdPts.data(idProfMeas, :);
   if (~isempty(profCtdPts.dataAdj))
      profCtdPts.dataAdj = profCtdPts.dataAdj(idProfMeas, :);
   end
   profCtdPts.dates = profCtdPts.dates(idProfMeas, :);
   if (~isempty(profCtdPts.datesAdj))
      profCtdPts.datesAdj = profCtdPts.datesAdj(idProfMeas, :);
   end
end

if (isempty(profCtdPts) && isempty(a_profCtdCp))
   return;
end

profCtdPtsStruct = [];
profCtdCpStruct = [];
profCtdCpAuxStruct = [];

if (~isempty(profCtdPts))
   
   % initialize a NetCDF profile structure and fill it with decoded profile data
   profCtdPtsStruct = get_profile_init_struct(a_cycleNum, -1, -1, -1);
   profCtdPtsStruct.sensorNumber = 0;
   
   % positioning system
   profCtdPtsStruct.posSystem = 'GPS';
   
   % add parameter variables to the profile structure
   profCtdPtsStruct.paramList = profCtdPts.paramList;
   
   % add parameter data to the profile structure
   profCtdPtsStruct.data = profCtdPts.data;
   profCtdPtsStruct.dataAdj = profCtdPts.dataAdj;
   
   % add press offset data to the profile structure
   idCycleStruct = find([a_presOffsetData.cycleNumAdjPres] == a_cycleNum);
   if (~isempty(idCycleStruct))
      profCtdPtsStruct.presOffset = a_presOffsetData.presOffset(idCycleStruct);
   end
   
   % add configuration mission number
   profCtdPtsStruct.configMissionNumber = get_config_mission_number_ir_sbd(a_cycleNum);
   
   % add MTIME to data
   if (~isempty(profCtdPts.dateList))
      paramMtime = get_netcdf_param_attributes('MTIME');
      if (any(profCtdPts.dates ~= profCtdPts.dateList.fillValue))
         % we temporarily store JULD as MTIME (because profile date will be
         % computed later)
         mtimeData = profCtdPts.dates;
         mtimeData(find(mtimeData == profCtdPts.dateList.fillValue)) = paramMtime.fillValue;
      else
         mtimeData = ones(size(profCtdPts.data, 1), 1)*paramMtime.fillValue;
      end
      profCtdPtsStruct.paramList = [paramMtime profCtdPtsStruct.paramList];
      profCtdPtsStruct.data = cat(2, mtimeData, double(profCtdPtsStruct.data));
      
      if (~isempty(profCtdPts.dataAdj))
         if (any(profCtdPts.datesAdj ~= profCtdPts.dateList.fillValue))
            % we temporarily store JULD as MTIME (because profile date will be
            % computed later)
            if (~isempty(profCtdPts.datesAdj))
               mtimeDataAdj = profCtdPts.datesAdj;
               mtimeDataAdj(find(mtimeDataAdj == profCtdPts.dateList.fillValue)) = paramMtime.fillValue;
            elseif (~isempty(profCtdPts.dates))
               mtimeDataAdj = profCtdPts.dates;
               mtimeDataAdj(find(mtimeDataAdj == profCtdPts.dateList.fillValue)) = paramMtime.fillValue;
            else
               mtimeDataAdj = ones(size(profCtdPts.dataAdj, 1), 1)*paramMtime.fillValue;
            end
         else
            mtimeDataAdj = ones(size(profCtdPts.dataAdj, 1), 1)*paramMtime.fillValue;
         end
         profCtdPtsStruct.dataAdj = cat(2, mtimeDataAdj, double(profCtdPtsStruct.dataAdj));
      end
   end   
end

if (~isempty(a_profCtdCp))
   
   % initialize a NetCDF profile structure and fill it with decoded profile data
   profCtdCpStruct = get_profile_init_struct(a_cycleNum, -1, -1, -1);
   profCtdCpStruct.sensorNumber = 0;
   
   % positioning system
   profCtdCpStruct.posSystem = 'GPS';
   
   % add parameter variables to the profile structure
   profCtdCpStruct.paramList = a_profCtdCp.paramList;
   
   % add parameter data to the profile structure
   profCtdCpStruct.data = flipud(a_profCtdCp.data);
   profCtdCpStruct.dataAdj = flipud(a_profCtdCp.dataAdj);
   
   % add press offset data to the profile structure
   idCycleStruct = find([a_presOffsetData.cycleNumAdjPres] == a_cycleNum);
   if (~isempty(idCycleStruct))
      profCtdCpStruct.presOffset = a_presOffsetData.presOffset(idCycleStruct);
   end
   
   % add configuration mission number
   profCtdCpStruct.configMissionNumber = get_config_mission_number_ir_sbd(a_cycleNum);
   
   % create an AUX profile with NB_SAMPLE information
   % AUX profiles have 2 parameters PRES and NB_SAMPLE
   idNbSample  = find(strcmp({profCtdCpStruct.paramList.name}, 'NB_SAMPLE') == 1, 1);
   if (~isempty(idNbSample))
      
      profCtdCpAuxStruct = profCtdCpStruct;
      profCtdCpAuxStruct.sensorNumber = 101; % to go to PROF_AUX file
      profCtdCpStruct.paramList(idNbSample) = [];
      profCtdCpStruct.data(:, idNbSample) = [];
      if (~isempty(profCtdCpStruct.dataAdj))
         profCtdCpStruct.dataAdj(:, idNbSample) = [];
      end
      
      idPres  = find(strcmp({profCtdCpStruct.paramList.name}, 'PRES') == 1, 1);
      profCtdCpAuxStruct.paramList = [profCtdCpAuxStruct.paramList(idPres) profCtdCpAuxStruct.paramList(idNbSample)];
      profCtdCpAuxStruct.data = [profCtdCpAuxStruct.data(:, idPres) profCtdCpAuxStruct.data(:, idNbSample)];
      if (~isempty(profCtdCpAuxStruct.dataAdj))
         profCtdCpAuxStruct.dataAdj = [profCtdCpAuxStruct.dataAdj(:, idPres) profCtdCpAuxStruct.dataAdj(:, idNbSample)];
      end
   end
end

% set primary profile and add vertical sampling scheme
if (~isempty(profCtdCpStruct))
   
   % get detailed description of the VSS
   description = create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, 'CTD');
   
   % add vertical sampling scheme
   profCtdCpStruct.vertSamplingScheme = sprintf('Primary sampling: averaged [%s]', description);
   profCtdCpStruct.primarySamplingProfileFlag = 1;
   
   o_ncProfile = [o_ncProfile profCtdCpStruct];

   if (~isempty(profCtdCpAuxStruct))
      profCtdCpAuxStruct.vertSamplingScheme = sprintf('Primary sampling: averaged [%s]', description);
      profCtdCpAuxStruct.primarySamplingProfileFlag = 1;
      
      o_ncProfile = [o_ncProfile profCtdCpAuxStruct];
   end
end

if (~isempty(profCtdPtsStruct))
   
   % get detailed description of the VSS
   description = create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, 'PTS');
   
   % add vertical sampling scheme
   if (~isempty(profCtdCpStruct))
      profCtdPtsStruct.vertSamplingScheme = sprintf('Secondary sampling: discrete [%s]', description);
      profCtdPtsStruct.primarySamplingProfileFlag = 0;
   else
      profCtdPtsStruct.vertSamplingScheme = sprintf('Primary sampling: discrete [%s]', description);
      profCtdPtsStruct.primarySamplingProfileFlag = 1;
   end
   
   o_ncProfile = [o_ncProfile profCtdPtsStruct];
end

return;
