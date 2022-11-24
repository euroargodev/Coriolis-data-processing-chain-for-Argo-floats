% ------------------------------------------------------------------------------
% Create the profiles of decoded data.
%
% SYNTAX :
%  [o_ncProfile] = process_nemo_profile(a_profileData, ...
%    a_cycleNum, a_presOffsetData, a_cycleTimeData, a_gpsData, a_iridiumData)
%
% INPUT PARAMETERS :
%   a_profileData    : decoded profile data
%   a_cycleNum       : cycle number
%   a_presOffsetData : pressure offset data structure
%   a_cycleTimeData  : cycle time data structure
%   a_gpsData        : GPS fix information
%   a_iridiumData    : Iridium fix information
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
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncProfile] = process_nemo_profile(a_profileData, ...
   a_cycleNum, a_presOffsetData, a_cycleTimeData, a_gpsData, a_iridiumData)

% output parameters initialization
o_ncProfile = [];


if (isempty(a_profileData))
   return
end

% initialize a NetCDF profile structure and fill it with decoded profile data
profStruct = get_profile_init_struct(a_cycleNum, -1, -1, -1);
profStruct.sensorNumber = 0;

% positioning system
profStruct.posSystem = 'GPS';

% add parameter variables to the profile structure
profStruct.paramList = a_profileData.paramList;

% add parameter data to the profile structure
profStruct.data = a_profileData.data;
profStruct.dataAdj = a_profileData.dataAdj;

% add press offset data to the profile structure
idCycleStruct = find([a_presOffsetData.cycleNumAdjPres] == a_cycleNum);
if (~isempty(idCycleStruct))
   profStruct.presOffset = a_presOffsetData.presOffset(idCycleStruct);
end

% add configuration mission number
profStruct.configMissionNumber = get_config_mission_number_nemo(a_cycleNum);

% add MTIME to data
if (~isempty(a_profileData.dateList))
   paramMtime = get_netcdf_param_attributes('MTIME');
   if (any(a_profileData.dates ~= a_profileData.dateList.fillValue))
      % we temporarily store JULD as MTIME (because profile date will be
      % computed later)
      mtimeData = a_profileData.dates;
      mtimeData(find(mtimeData == a_profileData.dateList.fillValue)) = paramMtime.fillValue;
   else
      mtimeData = ones(size(a_profileData.data, 1), 1)*paramMtime.fillValue;
   end
   profStruct.paramList = [paramMtime profStruct.paramList];
   profStruct.data = cat(2, mtimeData, double(profStruct.data));
   
   if (~isempty(a_profileData.dataAdj))
      if (any(a_profileData.datesAdj ~= a_profileData.dateList.fillValue))
         % we temporarily store JULD as MTIME (because profile date will be
         % computed later)
         if (~isempty(a_profileData.datesAdj))
            mtimeDataAdj = a_profileData.datesAdj;
            mtimeDataAdj(find(mtimeDataAdj == a_profileData.dateList.fillValue)) = paramMtime.fillValue;
         elseif (~isempty(a_profileData.dates))
            mtimeDataAdj = a_profileData.dates;
            mtimeDataAdj(find(mtimeDataAdj == a_profileData.dateList.fillValue)) = paramMtime.fillValue;
         else
            mtimeDataAdj = ones(size(a_profileData.dataAdj, 1), 1)*paramMtime.fillValue;
         end
      else
         mtimeDataAdj = ones(size(a_profileData.dataAdj, 1), 1)*paramMtime.fillValue;
      end
      profStruct.dataAdj = cat(2, mtimeDataAdj, double(profStruct.dataAdj));
   end
end

% add vertical sampling scheme
profStruct.vertSamplingScheme = 'Primary sampling: discrete []';
profStruct.primarySamplingProfileFlag = 1;

% add the date and location of the profile
[profStruct] = add_profile_date_and_location_nemo(profStruct, ...
   a_cycleTimeData, a_gpsData, a_iridiumData);

profStruct = squeeze_profile_data(profStruct);

% create an auxiliary profile with 'LIGHT442', 'LIGHT550' and 'LIGHT676'
% parameters
idF1 = find(strcmp({profStruct.paramList.name}, 'LIGHT442') == 1, 1);
idF2 = find(strcmp({profStruct.paramList.name}, 'LIGHT550') == 1, 1);
idF3 = find(strcmp({profStruct.paramList.name}, 'LIGHT676') == 1, 1);
idDel = [idF1 idF2 idF3];
profAuxStruct = [];
if (~isempty(idDel))
   
   profAuxStruct = profStruct;
   
   profStruct.paramList(idDel) = [];
   profStruct.data(:, idDel) = [];
   if (~isempty(profStruct.dataAdj))
      profStruct.dataAdj(:, idDel) = [];
   end
               
   profAuxStruct.sensorNumber = 101;
   idPres = find(strcmp({profAuxStruct.paramList.name}, 'PRES') == 1, 1);
   idKeep = [idPres idDel];
   profAuxStruct.paramList = profAuxStruct.paramList(idKeep);
   profAuxStruct.data = profAuxStruct.data(:, idKeep);
   if (~isempty(profAuxStruct.dataAdj))
      profAuxStruct.dataAdj = profAuxStruct.dataAdj(:, idKeep);
   end
end

o_ncProfile = [profStruct profAuxStruct];

return
