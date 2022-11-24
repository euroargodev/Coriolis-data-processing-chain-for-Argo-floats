% ------------------------------------------------------------------------------
% Create the profiles from decoded data.
%
% If CP data have been sampled: the primary profile is created from the
% concatenation of CTD_CP and CTD_CP_H data (and the merge of CTD_PTS and
% CTD_PTSH data outside the range of the CP data). A secondary profile is create
% from the merge of CTD_PTS and CTD_PTSH data inside the range of the CP data.
% Other sensors produce their own secondary profile.
% If CP data have not been sampled: the primary profile is created from the
% merge of CTD_PTS and CTD_PTSH data. Other sensors produce their own secondary
% profile.
%
% SYNTAX :
%  [o_ncProfile] = process_apx_apf11_ir_profile( ...
%    a_profCtdPts, a_profCtdPtsh, a_profDo, ...
%    a_profCtdCp, a_profCtdCpH, ...
%    a_profFlbbCd, a_profOcr504I, ...
%    a_cycleTimeData, ...
%    a_cycleNum, a_presOffsetData)
%
% INPUT PARAMETERS :
%   a_profCtdPts     : CTD_PTS data
%   a_profCtdPtsh    : CTD_PTSH data
%   a_profDo         : O2 data
%   a_profCtdCp      : CTD_CP data
%   a_profCtdCpH     : CTD_CP_H data
%   a_profFlbbCd     : FLBB_CD data
%   a_profOcr504I    : OCR_504I data
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
%   07/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncProfile] = process_apx_apf11_ir_profile( ...
   a_profCtdPts, a_profCtdPtsh, a_profDo, ...
   a_profCtdCp, a_profCtdCpH, ...
   a_profFlbbCd, a_profOcr504I, ...
   a_cycleTimeData, ...
   a_cycleNum, a_presOffsetData)

% output parameters initialization
o_ncProfile = [];


if (isempty(a_profCtdPts) && ...
      isempty(a_profCtdPtsh) && ...
      isempty(a_profDo) && ...
      isempty(a_profCtdCp) && ...
      isempty(a_profCtdCpH) && ...
      isempty(a_profFlbbCd) && ...
      isempty(a_profOcr504I))
   return
end

% remove PPOX_DOXY data from the DO profile
if (~isempty(a_profDo))
   idPpoxDoxy  = find(strcmp({a_profDo.paramList.name}, 'PPOX_DOXY') == 1, 1);
   if (~isempty(idPpoxDoxy))
      a_profDo.paramList(idPpoxDoxy) = [];
      a_profDo.data(:, idPpoxDoxy) = [];
      if (~isempty(a_profDo.dataAdj))
         a_profDo.dataAdj(:, idPpoxDoxy) = [];
      end
   end
end

% for each sensor, select (from their timestamps) the discrete measurements
% sampled during the ascending profile
profCtdPts = [];
profCtdPtsh = [];
profDo = [];
profFlbbCd = [];
profOcr504I = [];
for idS = 1:5
   outputData = [];
   if (idS == 1)
      inputData = a_profCtdPts;
   elseif (idS == 2)
      inputData = a_profCtdPtsh;
   elseif (idS == 3)
      inputData = a_profDo;
   elseif (idS == 4)
      inputData = a_profFlbbCd;
   elseif (idS == 5)
      inputData = a_profOcr504I;
   end
   
   if (~isempty(inputData) && ...
         ~isempty(a_cycleTimeData.ascentStartDateSci) && ...
         ~isempty(a_cycleTimeData.ascentEndDate) && ...
         any((inputData.dates >= a_cycleTimeData.ascentStartDateSci) & (inputData.dates <= a_cycleTimeData.ascentEndDate)))
      outputData = inputData;
      idProfMeas = find(((inputData.dates >= a_cycleTimeData.ascentStartDateSci) & (inputData.dates <= a_cycleTimeData.ascentEndDate)) == 1);
      outputData.data = outputData.data(idProfMeas, :);
      if (~isempty(outputData.dataAdj))
         outputData.dataAdj = outputData.dataAdj(idProfMeas, :);
      end
      outputData.dates = outputData.dates(idProfMeas, :);
      if (~isempty(outputData.datesAdj))
         outputData.datesAdj = outputData.datesAdj(idProfMeas, :);
      end
   end
   
   if (idS == 1)
      profCtdPts = outputData;
   elseif (idS == 2)
      profCtdPtsh = outputData;
   elseif (idS == 3)
      profDo = outputData;
   elseif (idS == 4)
      profFlbbCd = outputData;
   elseif (idS == 5)
      profOcr504I = outputData;
   end
end

if (isempty(profCtdPts) && ...
      isempty(profCtdPtsh) && ...
      isempty(profDo) && ...
      isempty(profFlbbCd) && ...
      isempty(profOcr504I) && ...
      isempty(a_profCtdCp) && ...
      isempty(a_profCtdCpH))
   return
end

profCtdPtsStruct = [];
profCtdPtshStruct = [];
profDoStruct = [];
profFlbbCdStruct = [];
profOcr504IStruct = [];
profCtdCpStruct = [];
profCtdCpAuxStruct = [];
profCtdCpHStruct = [];
profCtdCpHAuxStruct = [];

paramMtime = get_netcdf_param_attributes('MTIME');
paramVrsPh = get_netcdf_param_attributes('VRS_PH');
paramPhInSituFree = get_netcdf_param_attributes('PH_IN_SITU_FREE');
paramPhInSituTotal = get_netcdf_param_attributes('PH_IN_SITU_TOTAL');
paramNbSample = get_netcdf_param_attributes('NB_SAMPLE');
paramNbSampleCtd = get_netcdf_param_attributes('NB_SAMPLE_CTD');
paramNbSampleTransistorPh = get_netcdf_param_attributes('NB_SAMPLE_TRANSISTOR_PH');

% get configuration mission number
configMissionNumber = get_config_mission_number_ir_sbd(a_cycleNum);

% get press offset
presOffset = '';
idCycleStruct = find([a_presOffsetData.cycleNumAdjPres] == a_cycleNum);
if (~isempty(idCycleStruct))
   presOffset = a_presOffsetData.presOffset(idCycleStruct);
end

% merge CTD_PTS data in the CTD_PTSH profile
if ((~isempty(profCtdPtsh)) && (~isempty(profCtdPts)))
   
   profCtdPtsh.dates = [profCtdPtsh.dates; profCtdPts.dates];
   profCtdPtsh.data = [profCtdPtsh.data; ...
      [profCtdPts.data ...
      ones(size(profCtdPts.data, 1), 1)*paramVrsPh.fillValue ...
      ones(size(profCtdPts.data, 1), 1)*paramPhInSituFree.fillValue ...
      ones(size(profCtdPts.data, 1), 1)*paramPhInSituTotal.fillValue]];
   [profCtdPtsh.dates, idSort] = sort(profCtdPtsh.dates);
   profCtdPtsh.data = profCtdPtsh.data(idSort, :);
   if (~isempty(profCtdPtsh.datesAdj))
      profCtdPtsh.datesAdj = [profCtdPtsh.datesAdj; profCtdPts.datesAdj];
      profCtdPtsh.datesAdj = profCtdPtsh.datesAdj(idSort, :);
   end
   if (~isempty(profCtdPtsh.dataAdj))
      profCtdPtsh.dataAdj = [profCtdPtsh.dataAdj; ...
         [profCtdPts.dataAdj ...
         ones(size(profCtdPts.dataAdj, 1), 1)*paramVrsPh.fillValue ...
         ones(size(profCtdPts.dataAdj, 1), 1)*paramPhInSituFree.fillValue ...
         ones(size(profCtdPts.dataAdj, 1), 1)*paramPhInSituTotal.fillValue]];
      profCtdPtsh.dataAdj = profCtdPtsh.dataAdj(idSort, :);
   end
   clear profCtdPts;
   profCtdPts = [];
end

% create a profile with CTD_PTS data
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
   profCtdPtsStruct.presOffset = presOffset;
   
   % add configuration mission number
   profCtdPtsStruct.configMissionNumber = configMissionNumber;
   
   % add MTIME to data
   if (~isempty(profCtdPts.dateList))
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

% create a profile with CTD_PTSH data
if (~isempty(profCtdPtsh))
   
   % initialize a NetCDF profile structure and fill it with decoded profile data
   profCtdPtshStruct = get_profile_init_struct(a_cycleNum, -1, -1, -1);
   profCtdPtshStruct.sensorNumber = 7;
   
   % positioning system
   profCtdPtshStruct.posSystem = 'GPS';
   
   % add parameter variables to the profile structure
   profCtdPtshStruct.paramList = profCtdPtsh.paramList;
   
   % add parameter data to the profile structure
   profCtdPtshStruct.data = profCtdPtsh.data;
   profCtdPtshStruct.dataAdj = profCtdPtsh.dataAdj;
   
   % add press offset data to the profile structure
   profCtdPtshStruct.presOffset = presOffset;
   
   % add configuration mission number
   profCtdPtshStruct.configMissionNumber = configMissionNumber;
   
   % add MTIME to data
   if (any(profCtdPtsh.dates ~= profCtdPtsh.dateList.fillValue))
      % we temporarily store JULD as MTIME (because profile date will be
      % computed later)
      mtimeData = profCtdPtsh.dates;
      mtimeData(find(mtimeData == profCtdPtsh.dateList.fillValue)) = paramMtime.fillValue;
   else
      mtimeData = ones(size(profCtdPtsh.data, 1), 1)*paramMtime.fillValue;
   end
   profCtdPtshStruct.paramList = [paramMtime profCtdPtshStruct.paramList];
   profCtdPtshStruct.data = cat(2, mtimeData, double(profCtdPtshStruct.data));
   
   if (~isempty(profCtdPtsh.dataAdj))
      if (any(profCtdPtsh.datesAdj ~= profCtdPtsh.dateList.fillValue))
         % we temporarily store JULD as MTIME (because profile date will be
         % computed later)
         if (~isempty(profCtdPtsh.datesAdj))
            mtimeDataAdj = profCtdPtsh.datesAdj;
            mtimeDataAdj(find(mtimeDataAdj == profCtdPtsh.dateList.fillValue)) = paramMtime.fillValue;
         elseif (~isempty(profCtdPtsh.dates))
            mtimeDataAdj = profCtdPtsh.dates;
            mtimeDataAdj(find(mtimeDataAdj == profCtdPtsh.dateList.fillValue)) = paramMtime.fillValue;
         else
            mtimeDataAdj = ones(size(profCtdPtsh.dataAdj, 1), 1)*paramMtime.fillValue;
         end
      else
         mtimeDataAdj = ones(size(profCtdPtsh.dataAdj, 1), 1)*paramMtime.fillValue;
      end
      profCtdPtshStruct.dataAdj = cat(2, mtimeDataAdj, double(profCtdPtshStruct.dataAdj));
   end
end

% create a profile with OPTODE data
if (~isempty(profDo))
   
   % initialize a NetCDF profile structure and fill it with decoded profile data
   profDoStruct = get_profile_init_struct(a_cycleNum, -1, -1, -1);
   profDoStruct.sensorNumber = 1;
   
   % positioning system
   profDoStruct.posSystem = 'GPS';
   
   % add parameter variables to the profile structure
   profDoStruct.paramList = profDo.paramList;
   
   % add parameter data to the profile structure
   profDoStruct.data = profDo.data;
   profDoStruct.dataAdj = profDo.dataAdj;
   
   % add press offset data to the profile structure
   profDoStruct.presOffset = presOffset;
   
   % add configuration mission number
   profDoStruct.configMissionNumber = configMissionNumber;
   
   % add MTIME to data
   if (~isempty(profDo.dateList))
      if (any(profDo.dates ~= profDo.dateList.fillValue))
         % we temporarily store JULD as MTIME (because profile date will be
         % computed later)
         mtimeData = profDo.dates;
         mtimeData(find(mtimeData == profDo.dateList.fillValue)) = paramMtime.fillValue;
      else
         mtimeData = ones(size(profDo.data, 1), 1)*paramMtime.fillValue;
      end
      profDoStruct.paramList = [paramMtime profDoStruct.paramList];
      profDoStruct.data = cat(2, mtimeData, double(profDoStruct.data));
      
      if (~isempty(profDo.dataAdj))
         if (any(profDo.datesAdj ~= profDo.dateList.fillValue))
            % we temporarily store JULD as MTIME (because profile date will be
            % computed later)
            if (~isempty(profDo.datesAdj))
               mtimeDataAdj = profDo.datesAdj;
               mtimeDataAdj(find(mtimeDataAdj == profDo.dateList.fillValue)) = paramMtime.fillValue;
            elseif (~isempty(profDo.dates))
               mtimeDataAdj = profDo.dates;
               mtimeDataAdj(find(mtimeDataAdj == profDo.dateList.fillValue)) = paramMtime.fillValue;
            else
               mtimeDataAdj = ones(size(profDo.dataAdj, 1), 1)*paramMtime.fillValue;
            end
         else
            mtimeDataAdj = ones(size(profDo.dataAdj, 1), 1)*paramMtime.fillValue;
         end
         profDoStruct.dataAdj = cat(2, mtimeDataAdj, double(profDoStruct.dataAdj));
      end
   end
end

% create a profile with FLBBCD data
if (~isempty(profFlbbCd))
   
   % initialize a NetCDF profile structure and fill it with decoded profile data
   profFlbbCdStruct = get_profile_init_struct(a_cycleNum, -1, -1, -1);
   profFlbbCdStruct.sensorNumber = 4;
   
   % positioning system
   profFlbbCdStruct.posSystem = 'GPS';
   
   % add parameter variables to the profile structure
   profFlbbCdStruct.paramList = profFlbbCd.paramList;
   
   % add parameter data to the profile structure
   profFlbbCdStruct.data = profFlbbCd.data;
   profFlbbCdStruct.dataAdj = profFlbbCd.dataAdj;
   
   % add press offset data to the profile structure
   profFlbbCdStruct.presOffset = presOffset;
   
   % add configuration mission number
   profFlbbCdStruct.configMissionNumber = configMissionNumber;
   
   % add MTIME to data
   if (~isempty(profFlbbCd.dateList))
      if (any(profFlbbCd.dates ~= profFlbbCd.dateList.fillValue))
         % we temporarily store JULD as MTIME (because profile date will be
         % computed later)
         mtimeData = profFlbbCd.dates;
         mtimeData(find(mtimeData == profFlbbCd.dateList.fillValue)) = paramMtime.fillValue;
      else
         mtimeData = ones(size(profFlbbCd.data, 1), 1)*paramMtime.fillValue;
      end
      profFlbbCdStruct.paramList = [paramMtime profFlbbCdStruct.paramList];
      profFlbbCdStruct.data = cat(2, mtimeData, double(profFlbbCdStruct.data));
      
      if (~isempty(profFlbbCd.dataAdj))
         if (any(profFlbbCd.datesAdj ~= profFlbbCd.dateList.fillValue))
            % we temporarily store JULD as MTIME (because profile date will be
            % computed later)
            if (~isempty(profFlbbCd.datesAdj))
               mtimeDataAdj = profFlbbCd.datesAdj;
               mtimeDataAdj(find(mtimeDataAdj == profFlbbCd.dateList.fillValue)) = paramMtime.fillValue;
            elseif (~isempty(profFlbbCd.dates))
               mtimeDataAdj = profFlbbCd.dates;
               mtimeDataAdj(find(mtimeDataAdj == profFlbbCd.dateList.fillValue)) = paramMtime.fillValue;
            else
               mtimeDataAdj = ones(size(profFlbbCd.dataAdj, 1), 1)*paramMtime.fillValue;
            end
         else
            mtimeDataAdj = ones(size(profFlbbCd.dataAdj, 1), 1)*paramMtime.fillValue;
         end
         profFlbbCdStruct.dataAdj = cat(2, mtimeDataAdj, double(profFlbbCdStruct.dataAdj));
      end
   end
end

% create a profile with OCR540I data
if (~isempty(profOcr504I))
   
   % initialize a NetCDF profile structure and fill it with decoded profile data
   profOcr504IStruct = get_profile_init_struct(a_cycleNum, -1, -1, -1);
   profOcr504IStruct.sensorNumber = 2;
   
   % positioning system
   profOcr504IStruct.posSystem = 'GPS';
   
   % add parameter variables to the profile structure
   profOcr504IStruct.paramList = profOcr504I.paramList;
   
   % add parameter data to the profile structure
   profOcr504IStruct.data = profOcr504I.data;
   profOcr504IStruct.dataAdj = profOcr504I.dataAdj;
   
   % add press offset data to the profile structure
   profOcr504IStruct.presOffset = presOffset;
   
   % add configuration mission number
   profOcr504IStruct.configMissionNumber = configMissionNumber;
   
   % add MTIME to data
   if (~isempty(profOcr504I.dateList))
      if (any(profOcr504I.dates ~= profOcr504I.dateList.fillValue))
         % we temporarily store JULD as MTIME (because profile date will be
         % computed later)
         mtimeData = profOcr504I.dates;
         mtimeData(find(mtimeData == profOcr504I.dateList.fillValue)) = paramMtime.fillValue;
      else
         mtimeData = ones(size(profOcr504I.data, 1), 1)*paramMtime.fillValue;
      end
      profOcr504IStruct.paramList = [paramMtime profOcr504IStruct.paramList];
      profOcr504IStruct.data = cat(2, mtimeData, double(profOcr504IStruct.data));
      
      if (~isempty(profOcr504I.dataAdj))
         if (any(profOcr504I.datesAdj ~= profOcr504I.dateList.fillValue))
            % we temporarily store JULD as MTIME (because profile date will be
            % computed later)
            if (~isempty(profOcr504I.datesAdj))
               mtimeDataAdj = profOcr504I.datesAdj;
               mtimeDataAdj(find(mtimeDataAdj == profOcr504I.dateList.fillValue)) = paramMtime.fillValue;
            elseif (~isempty(profOcr504I.dates))
               mtimeDataAdj = profOcr504I.dates;
               mtimeDataAdj(find(mtimeDataAdj == profOcr504I.dateList.fillValue)) = paramMtime.fillValue;
            else
               mtimeDataAdj = ones(size(profOcr504I.dataAdj, 1), 1)*paramMtime.fillValue;
            end
         else
            mtimeDataAdj = ones(size(profOcr504I.dataAdj, 1), 1)*paramMtime.fillValue;
         end
         profOcr504IStruct.dataAdj = cat(2, mtimeDataAdj, double(profOcr504IStruct.dataAdj));
      end
   end
end

% merge CTD_CP data in the CTD_CP_H profile
if ((~isempty(a_profCtdCpH)) && (~isempty(a_profCtdCp)))
   
   a_profCtdCpH.data = [a_profCtdCpH.data; ...
      [a_profCtdCp.data ...
      ones(size(a_profCtdCp.data, 1), 1)*paramVrsPh.fillValue ...
      ones(size(a_profCtdCp.data, 1), 1)*paramNbSampleTransistorPh.fillValue ...
      ones(size(a_profCtdCp.data, 1), 1)*paramPhInSituFree.fillValue ...
      ones(size(a_profCtdCp.data, 1), 1)*paramPhInSituTotal.fillValue]];
   [~, idSort] = sort(a_profCtdCpH.data(:, 1), 'descend');
   a_profCtdCpH.data = a_profCtdCpH.data(idSort, :);
   if (~isempty(a_profCtdCpH.dataAdj))
      a_profCtdCpH.dataAdj = [a_profCtdCpH.dataAdj; ...
         [a_profCtdCp.dataAdj ...
         ones(size(a_profCtdCp.dataAdj, 1), 1)*paramVrsPh.fillValue ...
         ones(size(a_profCtdCp.dataAdj, 1), 1)*paramNbSampleTransistorPh.fillValue ...
         ones(size(a_profCtdCp.dataAdj, 1), 1)*paramPhInSituFree.fillValue ...
         ones(size(a_profCtdCp.dataAdj, 1), 1)*paramPhInSituTotal.fillValue]];
      a_profCtdCpH.dataAdj = a_profCtdCpH.dataAdj(idSort, :);
   end
   clear a_profCtdCp;
   a_profCtdCp = [];
end

% create a profile with CTD_CP data
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
   profCtdCpStruct.presOffset = presOffset;
   
   % add configuration mission number
   profCtdCpStruct.configMissionNumber = configMissionNumber;
   
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

% create a profile with CTD_CP_H data
if (~isempty(a_profCtdCpH))
   
   % initialize a NetCDF profile structure and fill it with decoded profile data
   profCtdCpHStruct = get_profile_init_struct(a_cycleNum, -1, -1, -1);
   profCtdCpHStruct.sensorNumber = 7;
   
   % positioning system
   profCtdCpHStruct.posSystem = 'GPS';
   
   % add parameter variables to the profile structure
   profCtdCpHStruct.paramList = a_profCtdCpH.paramList;
   
   % add parameter data to the profile structure
   profCtdCpHStruct.data = flipud(a_profCtdCpH.data);
   profCtdCpHStruct.dataAdj = flipud(a_profCtdCpH.dataAdj);
   
   % add press offset data to the profile structure
   profCtdCpHStruct.presOffset = presOffset;
   
   % add configuration mission number
   profCtdCpHStruct.configMissionNumber = configMissionNumber;
   
   % create an AUX profile with NB_SAMPLE_CTD and NB_SAMPLE_TRANSISTOR_PH information
   % AUX profiles have 3 parameters PRES, NB_SAMPLE_CTD and NB_SAMPLE_TRANSISTOR_PH
   idNbSampleCtd  = find(strcmp({profCtdCpHStruct.paramList.name}, 'NB_SAMPLE_CTD') == 1, 1);
   idNbSampleTransistorPh  = find(strcmp({profCtdCpHStruct.paramList.name}, 'NB_SAMPLE_TRANSISTOR_PH') == 1, 1);
   if (~isempty(idNbSampleCtd) && ~isempty(idNbSampleTransistorPh))
      
      profCtdCpHAuxStruct = profCtdCpHStruct;
      profCtdCpHAuxStruct.sensorNumber = 107; % to go to PROF_AUX file
      profCtdCpHStruct.paramList([idNbSampleCtd idNbSampleTransistorPh]) = [];
      profCtdCpHStruct.data(:, [idNbSampleCtd idNbSampleTransistorPh]) = [];
      if (~isempty(profCtdCpHStruct.dataAdj))
         profCtdCpHStruct.dataAdj(:, [idNbSampleCtd idNbSampleTransistorPh]) = [];
      end
      
      idPres  = find(strcmp({profCtdCpHStruct.paramList.name}, 'PRES') == 1, 1);
      profCtdCpHAuxStruct.paramList = [profCtdCpHAuxStruct.paramList(idPres) profCtdCpHAuxStruct.paramList([idNbSampleCtd idNbSampleTransistorPh])];
      profCtdCpHAuxStruct.data = [profCtdCpHAuxStruct.data(:, idPres) profCtdCpHAuxStruct.data(:, [idNbSampleCtd idNbSampleTransistorPh])];
      if (~isempty(profCtdCpHAuxStruct.dataAdj))
         profCtdCpHAuxStruct.dataAdj = [profCtdCpHAuxStruct.dataAdj(:, idPres) profCtdCpHAuxStruct.dataAdj(:, [idNbSampleCtd idNbSampleTransistorPh])];
      end
   end
end

% set primary profile and add vertical sampling scheme
primaryProfSetFlag = 0;
if (~isempty(profCtdCpStruct))
   
   idShallow = [];
   idDeep = [];
   dataTypeStr = '';
   
   minP = min(profCtdCpStruct.data(:, 1));
   maxP = max(profCtdCpStruct.data(:, 1));
   if (~isempty(profCtdPtshStruct))
      idShallow = find(profCtdPtshStruct.data(:, 2) < min(profCtdCpStruct.data(:, 1)));
      idDeep = find(profCtdPtshStruct.data(:, 2) > max(profCtdCpStruct.data(:, 1)));
      if (~isempty(idShallow) || ~isempty(idDeep))
         profCtdCpStruct.paramList = [paramMtime profCtdCpStruct.paramList paramVrsPh paramPhInSituFree paramPhInSituTotal];
         profCtdCpStruct.data = [ ...
            ones(size(profCtdCpStruct.data, 1), 1)*paramMtime.fillValue ...
            double(profCtdCpStruct.data) ...
            ones(size(profCtdCpStruct.data, 1), 1)*double(paramVrsPh.fillValue) ...
            ones(size(profCtdCpStruct.data, 1), 1)*double(paramPhInSituFree.fillValue) ...
            ones(size(profCtdCpStruct.data, 1), 1)*double(paramPhInSituTotal.fillValue)];
         if (~isempty(profCtdCpStruct.dataAdj))
            profCtdCpStruct.dataAdj = [ ...
               ones(size(profCtdCpStruct.dataAdj, 1), 1)*paramMtime.fillValue ...
               double(profCtdCpStruct.dataAdj) ...
               ones(size(profCtdCpStruct.dataAdj, 1), 1)*double(paramVrsPh.fillValue) ...
               ones(size(profCtdCpStruct.dataAdj, 1), 1)*double(paramPhInSituFree.fillValue) ...
               ones(size(profCtdCpStruct.dataAdj, 1), 1)*double(paramPhInSituTotal.fillValue)];
         end
         if (~isempty(idShallow))
            profCtdCpStruct.data = [profCtdCpStruct.data; ...
               profCtdPtshStruct.data(idShallow, :)];
            [~, idSort] = sort(profCtdCpStruct.data(:, 2), 'descend');
            profCtdCpStruct.data = profCtdCpStruct.data(idSort, :);
            if (~isempty(profCtdCpStruct.dataAdj))
               profCtdCpStruct.dataAdj = [profCtdCpStruct.dataAdj; ...
                  profCtdPtshStruct.data(idShallow, :)];
               profCtdCpStruct.dataAdj = profCtdCpStruct.dataAdj(idSort, :);
            end
         end
         if (~isempty(idDeep))
            profCtdCpStruct.data = [profCtdCpStruct.data; ...
               profCtdPtshStruct.data(idDeep, :)];
            [~, idSort] = sort(profCtdCpStruct.data(:, 2), 'descend');
            profCtdCpStruct.data = profCtdCpStruct.data(idSort, :);
            if (~isempty(profCtdCpStruct.dataAdj))
               profCtdCpStruct.dataAdj = [profCtdCpStruct.dataAdj; ...
                  profCtdPtshStruct.dataAdj(idDeep, :)];
               profCtdCpStruct.dataAdj = profCtdCpStruct.dataAdj(idSort, :);
            end
         end
         
         % get detailed description of the VSS
         minMax = [{minP} {maxP}];
         description = create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, 'CTD', 'PTSH', minMax);
         dataTypeStr = 'mixed';
      end
   elseif (~isempty(profCtdPtsStruct))
      idShallow = find(profCtdPtsStruct.data(:, 2) < min(profCtdCpStruct.data(:, 1)));
      idDeep = find(profCtdPtsStruct.data(:, 2) > max(profCtdCpStruct.data(:, 1)));
      if (~isempty(idShallow) || ~isempty(idDeep))
         profCtdCpStruct.paramList = [paramMtime profCtdCpStruct.paramList];
         profCtdCpStruct.data = [ ...
            ones(size(profCtdCpStruct.data, 1), 1)*paramMtime.fillValue ...
            double(profCtdCpStruct.data)];
         if (~isempty(profCtdCpStruct.dataAdj))
            profCtdCpStruct.dataAdj = [ ...
               ones(size(profCtdCpStruct.dataAdj, 1), 1)*paramMtime.fillValue ...
               double(profCtdCpStruct.dataAdj)];
         end
         if (~isempty(idShallow))
            profCtdCpStruct.data = [profCtdCpStruct.data; ...
               profCtdPtsStruct.data(idShallow, :)];
            [~, idSort] = sort(profCtdCpStruct.data(:, 2), 'descend');
            profCtdCpStruct.data = profCtdCpStruct.data(idSort, :);
            if (~isempty(profCtdCpStruct.dataAdj))
               profCtdCpStruct.dataAdj = [profCtdCpStruct.dataAdj; ...
                  profCtdPtsStruct.dataAdj(idShallow, :)];
               profCtdCpStruct.dataAdj = profCtdCpStruct.dataAdj(idSort, :);
            end
         end
         if (~isempty(idDeep))
            profCtdCpStruct.data = [profCtdCpStruct.data; ...
               profCtdPtsStruct.data(idDeep, :)];
            [~, idSort] = sort(profCtdCpStruct.data(:, 2), 'descend');
            profCtdCpStruct.data = profCtdCpStruct.data(idSort, :);
            if (~isempty(profCtdCpStruct.dataAdj))
               profCtdCpStruct.dataAdj = [profCtdCpStruct.dataAdj; ...
                  profCtdPtsStruct.dataAdj(idDeep, :)];
               profCtdCpStruct.dataAdj = profCtdCpStruct.dataAdj(idSort, :);
            end
         end
         
         % get detailed description of the VSS
         minMax = [{minP} {maxP}];
         description = create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, 'CTD', 'PTS', minMax);
         dataTypeStr = 'mixed';
      else
         
         % get detailed description of the VSS
         minMax = [{''} {''}];
         description = create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, 'CTD', '', minMax);
         dataTypeStr = 'averaged';
      end
   else
      
      % get detailed description of the VSS
      minMax = [{''} {''}];
      description = create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, 'CTD', '', minMax);
      dataTypeStr = 'averaged';
   end
   
   % add vertical sampling scheme
   profCtdCpStruct.vertSamplingScheme = sprintf('Primary sampling: %s [%s]', dataTypeStr, description);
   profCtdCpStruct.primarySamplingProfileFlag = 1;
   primaryProfSetFlag = 1;
   
   o_ncProfile = [o_ncProfile profCtdCpStruct];
   
   if (~isempty(profCtdCpAuxStruct))
      
      if (~isempty(profCtdPtshStruct))
         if (~isempty(idShallow) || ~isempty(idDeep))
            if (~isempty(idShallow))
               profCtdCpAuxStruct.data = [profCtdCpAuxStruct.data; ...
                  [profCtdPtshStruct.data(idShallow, 2) ones(length(idShallow), 1)*paramNbSample.fillValue]];
               [~, idSort] = sort(profCtdCpAuxStruct.data(:, 1), 'descend');
               profCtdCpAuxStruct.data = profCtdCpAuxStruct.data(idSort, :);
            end
            if (~isempty(idDeep))
               profCtdCpAuxStruct.data = [profCtdCpAuxStruct.data; ...
                  [profCtdPtshStruct.data(idDeep, 2) ones(length(idDeep), 1)*paramNbSample.fillValue]];
               [~, idSort] = sort(profCtdCpAuxStruct.data(:, 1), 'descend');
               profCtdCpAuxStruct.data = profCtdCpAuxStruct.data(idSort, :);
            end
            
            % get detailed description of the VSS
            description = create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, 'CTD', 'PTSH', minMax);
            dataTypeStr = 'mixed';
         end
      elseif (~isempty(profCtdPtsStruct))
         if (~isempty(idShallow) || ~isempty(idDeep))
            if (~isempty(idShallow))
               profCtdCpAuxStruct.data = [profCtdCpAuxStruct.data; ...
                  [profCtdPtsStruct.data(idShallow, 2) ones(length(idShallow), 1)*paramNbSample.fillValue]];
               [~, idSort] = sort(profCtdCpAuxStruct.data(:, 1), 'descend');
               profCtdCpAuxStruct.data = profCtdCpAuxStruct.data(idSort, :);
            end
            if (~isempty(idDeep))
               profCtdCpAuxStruct.data = [profCtdCpAuxStruct.data; ...
                  [profCtdPtsStruct.data(idDeep, 2) ones(length(idDeep), 1)*paramNbSample.fillValue]];
               [~, idSort] = sort(profCtdCpAuxStruct.data(:, 1), 'descend');
               profCtdCpAuxStruct.data = profCtdCpAuxStruct.data(idSort, :);
            end
            
            % get detailed description of the VSS
            description = create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, 'CTD', 'PTS', minMax);
            dataTypeStr = 'mixed';
         end
      else
         
         % get detailed description of the VSS
         description = create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, 'CTD', '', minMax);
         dataTypeStr = 'averaged';
      end
      
      profCtdCpAuxStruct.vertSamplingScheme = sprintf('Primary sampling: %s [%s]', dataTypeStr, description);
      profCtdCpAuxStruct.primarySamplingProfileFlag = 1;
      
      o_ncProfile = [o_ncProfile profCtdCpAuxStruct];
   end
   
   % remove shallow and deep data from original profile
   if (~isempty(profCtdPtshStruct))
      profCtdPtshStruct.data([idShallow; idDeep], :) = [];
      if (~isempty(profCtdPtshStruct.dataAdj))
         profCtdPtshStruct.dataAdj([idShallow; idDeep], :) = [];
      end
   elseif (~isempty(profCtdPtsStruct))
      profCtdPtsStruct.data([idShallow; idDeep], :) = [];
      if (~isempty(profCtdPtsStruct.dataAdj))
         profCtdPtsStruct.dataAdj([idShallow; idDeep], :) = [];
      end
   end
end

if (~isempty(profCtdCpHStruct))
   
   idShallow = [];
   idDeep = [];
   dataTypeStr = '';
   
   minP = min(profCtdCpHStruct.data(:, 1));
   maxP = max(profCtdCpHStruct.data(:, 1));
   if (~isempty(profCtdPtshStruct))
      idShallow = find(profCtdPtshStruct.data(:, 2) < min(profCtdCpHStruct.data(:, 1)));
      idDeep = find(profCtdPtshStruct.data(:, 2) > max(profCtdCpHStruct.data(:, 1)));
      if (~isempty(idShallow) || ~isempty(idDeep))
         profCtdCpHStruct.paramList = [paramMtime profCtdCpHStruct.paramList];
         profCtdCpHStruct.data = [ ...
            ones(size(profCtdCpHStruct.data, 1), 1)*paramMtime.fillValue ...
            double(profCtdCpHStruct.data)];
         if (~isempty(profCtdCpHStruct.dataAdj))
            profCtdCpHStruct.dataAdj = [ ...
               ones(size(profCtdCpHStruct.dataAdj, 1), 1)*paramMtime.fillValue ...
               double(profCtdCpHStruct.dataAdj)];
         end
         if (~isempty(idShallow))
            profCtdCpHStruct.data = [profCtdCpHStruct.data; ...
               profCtdPtshStruct.data(idShallow, :)];
            [~, idSort] = sort(profCtdCpHStruct.data(:, 2), 'descend');
            profCtdCpHStruct.data = profCtdCpHStruct.data(idSort, :);
            if (~isempty(profCtdCpHStruct.dataAdj))
               profCtdCpHStruct.dataAdj = [profCtdCpHStruct.dataAdj; ...
                  profCtdPtshStruct.dataAdj(idShallow, :)];
               profCtdCpHStruct.dataAdj = profCtdCpHStruct.dataAdj(idSort, :);
            end
         end
         if (~isempty(idDeep))
            profCtdCpHStruct.data = [profCtdCpHStruct.data; ...
               profCtdPtshStruct.data(idDeep, :)];
            [~, idSort] = sort(profCtdCpHStruct.data(:, 2), 'descend');
            profCtdCpHStruct.data = profCtdCpHStruct.data(idSort, :);
            if (~isempty(profCtdCpHStruct.dataAdj))
               profCtdCpHStruct.dataAdj = [profCtdCpHStruct.dataAdj; ...
                  profCtdPtshStruct.dataAdj(idDeep, :)];
               profCtdCpHStruct.dataAdj = profCtdCpHStruct.dataAdj(idSort, :);
            end
         end
         
         % get detailed description of the VSS
         minMax = [{minP} {maxP}];
         description = create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, 'PH', 'PTSH', minMax);
         dataTypeStr = 'mixed';
      end
   elseif (~isempty(profCtdPtsStruct))
      idShallow = find(profCtdPtsStruct.data(:, 2) < min(profCtdCpHStruct.data(:, 1)));
      idDeep = find(profCtdPtsStruct.data(:, 2) > max(profCtdCpHStruct.data(:, 1)));
      if (~isempty(idShallow) || ~isempty(idDeep))
         profCtdCpHStruct.paramList = [paramMtime profCtdCpHStruct.paramList];
         profCtdCpHStruct.data = [ ...
            ones(size(profCtdCpHStruct.data, 1), 1)*paramMtime.fillValue ...
            double(profCtdCpHStruct.data)];
         if (~isempty(profCtdCpHStruct.dataAdj))
            profCtdCpHStruct.dataAdj = [ ...
               ones(size(profCtdCpHStruct.dataAdj, 1), 1)*paramMtime.fillValue ...
               double(profCtdCpHStruct.dataAdj)];
         end
         if (~isempty(idShallow))
            profCtdCpHStruct.data = [profCtdCpHStruct.data; ...
               [profCtdPtsStruct.data(idShallow, :) ...
               ones(length(idShallow), 1)*paramVrsPh.fillValue ...
               ones(length(idShallow), 1)*paramPhInSituFree.fillValue ...
               ones(length(idShallow), 1)*paramPhInSituTotal.fillValue]];
            [~, idSort] = sort(profCtdCpHStruct.data(:, 2), 'descend');
            profCtdCpHStruct.data = profCtdCpHStruct.data(idSort, :);
            if (~isempty(profCtdCpHStruct.dataAdj))
               profCtdCpHStruct.dataAdj = [profCtdCpHStruct.dataAdj; ...
                  [profCtdPtsStruct.dataAdj(idShallow, :) ...
                  ones(length(idShallow), 1)*paramVrsPh.fillValue ...
                  ones(length(idShallow), 1)*paramPhInSituFree.fillValue ...
                  ones(length(idShallow), 1)*paramPhInSituTotal.fillValue]];
               profCtdCpHStruct.dataAdj = profCtdCpHStruct.dataAdj(idSort, :);
            end
         end
         if (~isempty(idDeep))
            profCtdCpHStruct.data = [profCtdCpHStruct.data; ...
               [profCtdPtsStruct.data(idDeep, :) ...
               ones(length(idDeep), 1)*paramVrsPh.fillValue ...
               ones(length(idDeep), 1)*paramPhInSituFree.fillValue ...
               ones(length(idDeep), 1)*paramPhInSituTotal.fillValue]];
            [~, idSort] = sort(profCtdCpHStruct.data(:, 2), 'descend');
            profCtdCpHStruct.data = profCtdCpHStruct.data(idSort, :);
            if (~isempty(profCtdCpHStruct.dataAdj))
               profCtdCpHStruct.dataAdj = [profCtdCpHStruct.dataAdj; ...
                  [profCtdPtsStruct.dataAdj(idDeep, :) ...
                  ones(length(idDeep), 1)*paramVrsPh.fillValue ...
                  ones(length(idDeep), 1)*paramPhInSituFree.fillValue ...
                  ones(length(idDeep), 1)*paramPhInSituTotal.fillValue]];
               profCtdCpHStruct.dataAdj = profCtdCpHStruct.dataAdj(idSort, :);
            end
         end
         
         % get detailed description of the VSS
         minMax = [{minP} {maxP}];
         description = create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, 'PH', 'PTS', minMax);
         dataTypeStr = 'mixed';
      end
   else
      
      % get detailed description of the VSS
      minMax = [{''} {''}];
      description = create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, 'PH', '', minMax);
      dataTypeStr = 'averaged';
   end
   
   % add vertical sampling scheme
   profCtdCpHStruct.vertSamplingScheme = sprintf('Primary sampling: %s [%s]', dataTypeStr, description);
   profCtdCpHStruct.primarySamplingProfileFlag = 1;
   primaryProfSetFlag = 1;
   
   o_ncProfile = [o_ncProfile profCtdCpHStruct];
   
   if (~isempty(profCtdCpHAuxStruct))
      
      if (~isempty(profCtdPtshStruct))
         if (~isempty(idShallow) || ~isempty(idDeep))
            if (~isempty(idShallow))
               profCtdCpHAuxStruct.data = [profCtdCpHAuxStruct.data; ...
                  [profCtdPtshStruct.data(idShallow, 2) ...
                  ones(length(idShallow), 1)*paramNbSampleCtd.fillValue ...
                  ones(length(idShallow), 1)*paramNbSampleTransistorPh.fillValue]];
               [~, idSort] = sort(profCtdCpHAuxStruct.data(:, 1), 'descend');
               profCtdCpHAuxStruct.data = profCtdCpHAuxStruct.data(idSort, :);
            end
            if (~isempty(idDeep))
               profCtdCpHAuxStruct.data = [profCtdCpHAuxStruct.data; ...
                  [profCtdPtshStruct.data(idDeep, 2) ...
                  ones(length(idDeep), 1)*paramNbSampleCtd.fillValue ...
                  ones(length(idDeep), 1)*paramNbSampleTransistorPh.fillValue]];
               [~, idSort] = sort(profCtdCpHAuxStruct.data(:, 1), 'descend');
               profCtdCpHAuxStruct.data = profCtdCpHAuxStruct.data(idSort, :);
            end
            
            % get detailed description of the VSS
            description = create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, 'PH', 'PTSH', minMax);
            dataTypeStr = 'mixed';
         end
      elseif (~isempty(profCtdPtsStruct))
         if (~isempty(idShallow) || ~isempty(idDeep))
            if (~isempty(idShallow))
               profCtdCpHAuxStruct.data = [profCtdCpHAuxStruct.data; ...
                  [profCtdPtshStruct.data(idShallow, 2) ...
                  ones(length(idShallow), 1)*paramNbSampleCtd.fillValue ...
                  ones(length(idShallow), 1)*paramNbSampleTransistorPh.fillValue]];
               [~, idSort] = sort(profCtdCpHAuxStruct.data(:, 1), 'descend');
               profCtdCpHAuxStruct.data = profCtdCpHAuxStruct.data(idSort, :);
            end
            if (~isempty(idDeep))
               profCtdCpHAuxStruct.data = [profCtdCpHAuxStruct.data; ...
                  [profCtdPtshStruct.data(idDeep, 2) ...
                  ones(length(idDeep), 1)*paramNbSampleCtd.fillValue ...
                  ones(length(idDeep), 1)*paramNbSampleTransistorPh.fillValue]];
               [~, idSort] = sort(profCtdCpHAuxStruct.data(:, 1), 'descend');
               profCtdCpHAuxStruct.data = profCtdCpHAuxStruct.data(idSort, :);
            end
            
            % get detailed description of the VSS
            description = create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, 'PH', 'PTS', minMax);
            dataTypeStr = 'mixed';
         end
      else
         
         % get detailed description of the VSS
         description = create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, 'PH', '', minMax);
         dataTypeStr = 'averaged';
      end
      
      profCtdCpHAuxStruct.vertSamplingScheme = sprintf('Primary sampling: %s [%s]', dataTypeStr, description);
      profCtdCpHAuxStruct.primarySamplingProfileFlag = 1;
      
      o_ncProfile = [o_ncProfile profCtdCpHAuxStruct];
   end
   
   % remove shallow and deep data from original profile
   if (~isempty(profCtdPtshStruct))
      profCtdPtshStruct.data([idShallow; idDeep], :) = [];
      if (~isempty(profCtdPtshStruct.dataAdj))
         profCtdPtshStruct.dataAdj([idShallow; idDeep], :) = [];
      end
      % discrete PH data are not sampled during CP mode, we should remove
      % associated parameters in discrete profile
      profCtdPtshStruct = remove_unused_param(profCtdPtshStruct);
   elseif (~isempty(profCtdPtsStruct))
      profCtdPtsStruct.data([idShallow; idDeep], :) = [];
      if (~isempty(profCtdPtsStruct.dataAdj))
         profCtdPtsStruct.dataAdj([idShallow; idDeep], :) = [];
      end
   end
end

if (~isempty(profCtdPtsStruct))
   
   % get detailed description of the VSS
   minMax = [{''} {''}];
   description = create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, 'PTS', '', minMax);
   
   % add vertical sampling scheme
   if (~primaryProfSetFlag)
      profCtdPtsStruct.vertSamplingScheme = sprintf('Primary sampling: discrete [%s]', description);
      profCtdPtsStruct.primarySamplingProfileFlag = 1;
      primaryProfSetFlag = 1;
   else
      profCtdPtsStruct.vertSamplingScheme = sprintf('Secondary sampling: discrete [%s]', description);
      profCtdPtsStruct.primarySamplingProfileFlag = 0;
   end
   
   o_ncProfile = [o_ncProfile profCtdPtsStruct];
end

if (~isempty(profCtdPtshStruct))
   
   % get detailed description of the VSS
   minMax = [{''} {''}];
   description = create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, 'PTSH', '', minMax);
   
   % add vertical sampling scheme
   if (~primaryProfSetFlag)
      profCtdPtshStruct.vertSamplingScheme = sprintf('Primary sampling: discrete [%s]', description);
      profCtdPtshStruct.primarySamplingProfileFlag = 1;
   else
      profCtdPtshStruct.vertSamplingScheme = sprintf('Secondary sampling: discrete [%s]', description);
      profCtdPtshStruct.primarySamplingProfileFlag = 0;
   end
   
   o_ncProfile = [o_ncProfile profCtdPtshStruct];
end

if (~isempty(profDoStruct))
   
   % get detailed description of the VSS
   minMax = [{''} {''}];
   description = create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, 'OPT', '', minMax);
   
   % add vertical sampling scheme
   profDoStruct.vertSamplingScheme = sprintf('Secondary sampling: discrete [%s]', description);
   profDoStruct.primarySamplingProfileFlag = 0;
   
   o_ncProfile = [o_ncProfile profDoStruct];
end

if (~isempty(profFlbbCdStruct))
   
   % get detailed description of the VSS
   minMax = [{''} {''}];
   description = create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, 'FLBB', '', minMax);
   
   % add vertical sampling scheme
   profFlbbCdStruct.vertSamplingScheme = sprintf('Secondary sampling: discrete [%s]', description);
   profFlbbCdStruct.primarySamplingProfileFlag = 0;
   
   o_ncProfile = [o_ncProfile profFlbbCdStruct];
end

if (~isempty(profOcr504IStruct))
   
   % get detailed description of the VSS
   minMax = [{''} {''}];
   description = create_vertical_sampling_scheme_description_apx_apf11_ir(a_cycleNum, 'IRAD', '', minMax);
   
   % add vertical sampling scheme
   profOcr504IStruct.vertSamplingScheme = sprintf('Secondary sampling: discrete [%s]', description);
   profOcr504IStruct.primarySamplingProfileFlag = 0;
   
   o_ncProfile = [o_ncProfile profOcr504IStruct];
end

return

% ------------------------------------------------------------------------------
% Clean profile data from unused parameters.
%
% SYNTAX :
%  [o_ncProfile] = remove_unused_param(a_ncProfile)
%
% INPUT PARAMETERS :
%   a_ncProfile : input profile
%
% OUTPUT PARAMETERS :
%   o_ncProfile : output profile
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncProfile] = remove_unused_param(a_ncProfile)

% output parameters initialization
o_ncProfile = a_ncProfile;


if (isempty(o_ncProfile))
   return
end

idParamTodel = [];
for idParam = 1:length(o_ncProfile.paramList)
   paramInfo = get_netcdf_param_attributes(o_ncProfile.paramList(idParam).name);
   if (~any(o_ncProfile.data(:, idParam) ~= paramInfo.fillValue))
      idParamTodel = [idParamTodel idParam];
   end
end
o_ncProfile.paramList(idParamTodel) = [];
o_ncProfile.data(:, idParamTodel) = [];
if (~isempty(o_ncProfile.dataAdj))
   o_ncProfile.dataAdj(:, idParamTodel) = [];
end

return

