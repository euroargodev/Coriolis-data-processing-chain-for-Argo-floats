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
%    a_profCtdPt, a_profCtdPts, a_profCtdPtsh, a_profDo, ...
%    a_profCtdCp, a_profCtdCpH, ...
%    a_profFlbbCd, a_profOcr504I, a_profRamses, ...
%    a_cycleTimeData, ...
%    a_cycleNum, a_presOffsetData)
%
% INPUT PARAMETERS :
%   a_profCtdPt      : CTD_PT data
%   a_profCtdPts     : CTD_PTS data
%   a_profCtdPtsh    : CTD_PTSH data
%   a_profDo         : O2 data
%   a_profCtdCp      : CTD_CP data
%   a_profCtdCpH     : CTD_CP_H data
%   a_profFlbbCd     : FLBB_CD data
%   a_profOcr504I    : OCR_504I data
%   a_profRamses     : RAMSES data
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
   a_profCtdPt, a_profCtdPts, a_profCtdPtsh, a_profDo, ...
   a_profCtdCp, a_profCtdCpH, ...
   a_profFlbbCd, a_profOcr504I, a_profRamses, ...
   a_cycleTimeData, ...
   a_cycleNum, a_presOffsetData)

% output parameters initialization
o_ncProfile = [];

% QC flag values (numerical)
global g_decArgo_qcDef;
global g_decArgo_qcProbablyGood;


if (isempty(a_profCtdPt) && ...
      isempty(a_profCtdPts) && ...
      isempty(a_profCtdPtsh) && ...
      isempty(a_profDo) && ...
      isempty(a_profCtdCp) && ...
      isempty(a_profCtdCpH) && ...
      isempty(a_profFlbbCd) && ...
      isempty(a_profOcr504I) && ...
      isempty(a_profRamses))
   return
end

% remove PPOX_DOXY data from the DO profile
if (~isempty(a_profDo))
   idPpoxDoxy  = find(strcmp({a_profDo.paramList.name}, 'PPOX_DOXY'), 1);
   if (~isempty(idPpoxDoxy))
      a_profDo.paramList(idPpoxDoxy) = [];
      if (~isempty(a_profDo.paramDataMode))
         a_profDo.paramDataMode(idPpoxDoxy) = [];
      end
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
profRamses = [];

profIceCtdPt = [];
profIceCtdPts = [];
profIceCtdPtsh = [];
profIceDo = [];
profIceFlbbCd = [];
profIceOcr504I = [];
profIceRamses = [];
for idS = 0:6

   if (idS == 0)
      inputData = a_profCtdPt;
   elseif (idS == 1)
      inputData = a_profCtdPts;
   elseif (idS == 2)
      inputData = a_profCtdPtsh;
   elseif (idS == 3)
      inputData = a_profDo;
   elseif (idS == 4)
      inputData = a_profFlbbCd;
   elseif (idS == 5)
      inputData = a_profOcr504I;
   elseif (idS == 6)
      inputData = a_profRamses;
   end
   
   if (isempty(inputData))
      continue
   end
   
   % ascent profiles
   if ((idS > 0) && ...
         ~isempty(a_cycleTimeData.ascentStartDateSci) && ...
         ~isempty(a_cycleTimeData.ascentEndDate) && ...
         any((inputData.dates >= a_cycleTimeData.ascentStartDateSci) & (inputData.dates <= a_cycleTimeData.ascentEndDate)))
      outputData = inputData;
      idProfMeas = find((inputData.dates >= a_cycleTimeData.ascentStartDateSci) & (inputData.dates <= a_cycleTimeData.ascentEndDate));
      outputData.data = outputData.data(idProfMeas, :);
      if (~isempty(outputData.dataAdj))
         outputData.dataAdj = outputData.dataAdj(idProfMeas, :);
      end
      outputData.dates = outputData.dates(idProfMeas, :);
      if (~isempty(outputData.datesAdj))
         outputData.datesAdj = outputData.datesAdj(idProfMeas, :);
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
      elseif (idS == 6)
         profRamses = outputData;
      end
      clear outputData
   end
   
   % manage Ice descent and ascent cycles
   if (~isempty(a_cycleTimeData.iceDescentStartDateSci))
      for idC = 1:length(a_cycleTimeData.iceDescentStartDateSci)
         
         % Ice descent profiles
         if (~isempty(a_cycleTimeData.iceDescentStartDateSci(idC)) && ...
               ~isempty(a_cycleTimeData.iceAscentStartDateSci(idC)) && ...
               any((inputData.dates > a_cycleTimeData.iceDescentStartDateSci(idC)) & (inputData.dates < a_cycleTimeData.iceAscentStartDateSci(idC))))
            outputData = inputData;
            idProfMeas = find(((inputData.dates >  a_cycleTimeData.iceDescentStartDateSci(idC)) & (inputData.dates < a_cycleTimeData.iceAscentStartDateSci(idC))));
            outputData.data = outputData.data(idProfMeas, :);
            if (~isempty(outputData.dataAdj))
               outputData.dataAdj = outputData.dataAdj(idProfMeas, :);
            end
            outputData.dates = outputData.dates(idProfMeas, :);
            if (~isempty(outputData.datesAdj))
               outputData.datesAdj = outputData.datesAdj(idProfMeas, :);
            end
            
            if (idS == 0)
               profIceCtdPt = [profIceCtdPt; [idC 1 {outputData}]];
            elseif (idS == 1)
               profIceCtdPts = [profIceCtdPts; [idC 1 {outputData}]];
            elseif (idS == 2)
               profIceCtdPtsh = [profIceCtdPtsh; [idC 1 {outputData}]];
            elseif (idS == 3)
               profIceDo = [profIceDo; [idC 1 {outputData}]];
            elseif (idS == 4)
               profIceFlbbCd = [profIceFlbbCd; [idC 1 {outputData}]];
            elseif (idS == 5)
               profIceOcr504I = [profIceOcr504I; [idC 1 {outputData}]];
            elseif (idS == 6)
               profIceRamses = [profIceRamses; [idC 1 {outputData}]];
            end
            clear outputData
         end
         
         % Ice ascent profiles
         if (~isempty(a_cycleTimeData.iceAscentStartDateSci(idC)) && ...
               ~isempty(a_cycleTimeData.iceAscentEndDateSci(idC)) && ...
               any((inputData.dates >= a_cycleTimeData.iceAscentStartDateSci(idC)) & (inputData.dates <= a_cycleTimeData.iceAscentEndDateSci(idC))))
            outputData = inputData;
            idProfMeas = find(((inputData.dates >=  a_cycleTimeData.iceAscentStartDateSci(idC)) & (inputData.dates <= a_cycleTimeData.iceAscentEndDateSci(idC))));
            outputData.data = outputData.data(idProfMeas, :);
            if (~isempty(outputData.dataAdj))
               outputData.dataAdj = outputData.dataAdj(idProfMeas, :);
            end
            outputData.dates = outputData.dates(idProfMeas, :);
            if (~isempty(outputData.datesAdj))
               outputData.datesAdj = outputData.datesAdj(idProfMeas, :);
            end
            
            if (idS == 0)
               profIceCtdPt = [profIceCtdPt; [idC 2 {outputData}]];
            elseif (idS == 1)
               profIceCtdPts = [profIceCtdPts; [idC 2 {outputData}]];
            elseif (idS == 2)
               profIceCtdPtsh = [profIceCtdPtsh; [idC 2 {outputData}]];
            elseif (idS == 3)
               profIceDo = [profIceDo; [idC 2 {outputData}]];
            elseif (idS == 4)
               profIceFlbbCd = [profIceFlbbCd; [idC 2 {outputData}]];
            elseif (idS == 5)
               profIceOcr504I = [profIceOcr504I; [idC 2 {outputData}]];
            elseif (idS == 6)
               profIceRamses = [profIceRamses; [idC 2 {outputData}]];
            end
            clear outputData
         end
      end
   end
   clear inputData
end

if (isempty(profCtdPts) && ...
      isempty(profCtdPtsh) && ...
      isempty(profDo) && ...
      isempty(profFlbbCd) && ...
      isempty(profOcr504I) && ...
      isempty(profRamses) && ...
      isempty(a_profCtdCp) && ...
      isempty(a_profCtdCpH) && ...
      isempty(profIceCtdPt) && ...
      isempty(profIceCtdPts) && ...
      isempty(profIceCtdPtsh) && ...
      isempty(profIceDo) && ...
      isempty(profIceFlbbCd) && ...
      isempty(profIceOcr504I) && ...
      isempty(profIceRamses) ...
   )
   return
end

profCtdPtsStruct = [];
profCtdPtshStruct = [];
profDoStruct = [];
profFlbbCdStruct = [];
profOcr504IStruct = [];
profCtdCpStruct = [];
profCtdCpHStruct = [];
profRamsesStruct = [];

paramMtime = get_netcdf_param_attributes('MTIME');
paramNbSampleCtd = get_netcdf_param_attributes('NB_SAMPLE_CTD');
paramVrsPh = get_netcdf_param_attributes('VRS_PH');
paramPhInSituFree = get_netcdf_param_attributes('PH_IN_SITU_FREE');
paramPhInSituTotal = get_netcdf_param_attributes('PH_IN_SITU_TOTAL');
paramNbSampleSfet = get_netcdf_param_attributes('NB_SAMPLE_SFET');

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
   profCtdPtsStruct.paramDataMode = profCtdPts.paramDataMode;
   
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
      if (~isempty(profCtdPtsStruct.paramDataMode))
         profCtdPtsStruct.paramDataMode = [' ' profCtdPtsStruct.paramDataMode];
      end
      profCtdPtsStruct.data = cat(2, mtimeData, double(profCtdPtsStruct.data));
      
      if (~isempty(profCtdPts.dataAdj))
         mtimeDataAdj = ones(size(profCtdPts.dataAdj, 1), 1)*paramMtime.fillValue;
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
   profCtdPtshStruct.paramDataMode = profCtdPtsh.paramDataMode;
   
   % add parameter data to the profile structure
   profCtdPtshStruct.data = profCtdPtsh.data;
   profCtdPtshStruct.dataAdj = profCtdPtsh.dataAdj;
   
   % add press offset data to the profile structure
   profCtdPtshStruct.presOffset = presOffset;
   
   % add configuration mission number
   profCtdPtshStruct.configMissionNumber = configMissionNumber;
   
   % add MTIME to data
   if (~isempty(profCtdPtsh.dateList))
      if (any(profCtdPtsh.dates ~= profCtdPtsh.dateList.fillValue))
         % we temporarily store JULD as MTIME (because profile date will be
         % computed later)
         mtimeData = profCtdPtsh.dates;
         mtimeData(find(mtimeData == profCtdPtsh.dateList.fillValue)) = paramMtime.fillValue;
      else
         mtimeData = ones(size(profCtdPtsh.data, 1), 1)*paramMtime.fillValue;
      end
      profCtdPtshStruct.paramList = [paramMtime profCtdPtshStruct.paramList];
      if (~isempty(profCtdPtshStruct.paramDataMode))
         profCtdPtshStruct.paramDataMode = [' ' profCtdPtshStruct.paramDataMode];
      end
      profCtdPtshStruct.data = cat(2, mtimeData, double(profCtdPtshStruct.data));
      
      if (~isempty(profCtdPtsh.dataAdj))
         mtimeDataAdj = ones(size(profCtdPtsh.dataAdj, 1), 1)*paramMtime.fillValue;
         profCtdPtshStruct.dataAdj = cat(2, mtimeDataAdj, double(profCtdPtshStruct.dataAdj));
      end
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
   profDoStruct.paramDataMode = profDo.paramDataMode;

   % add parameter data to the profile structure
   profDoStruct.data = profDo.data;
   profDoStruct.dataAdj = profDo.dataAdj;
   
   % add press offset data to the profile structure
   profDoStruct.presOffset = presOffset;
   
   % add configuration mission number
   profDoStruct.configMissionNumber = configMissionNumber;
   
   % add MTIME to data
   if (profDo.temporaryDates ~= 1)
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
         if (~isempty(profDoStruct.paramDataMode))
            profDoStruct.paramDataMode = [' ' profDoStruct.paramDataMode];
         end
         profDoStruct.data = cat(2, mtimeData, double(profDoStruct.data));
         
         if (~isempty(profDo.dataAdj))
            mtimeDataAdj = ones(size(profDo.dataAdj, 1), 1)*paramMtime.fillValue;
            profDoStruct.dataAdj = cat(2, mtimeDataAdj, double(profDoStruct.dataAdj));
         end
      end
   else
      idPres = find(strcmp({profDoStruct.paramList.name}, 'PRES'), 1);
      profDoStruct.dataQc = ones(size(profDoStruct.data))*g_decArgo_qcDef;
      profDoStruct.dataQc(:, idPres) = g_decArgo_qcProbablyGood;
      if (~isempty(profDoStruct.dataAdj))
         profDoStruct.dataAdjQc = ones(size(profDoStruct.data))*g_decArgo_qcDef;
         profDoStruct.dataAdjQc(:, idPres) = g_decArgo_qcProbablyGood;
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
   profFlbbCdStruct.paramDataMode = profFlbbCd.paramDataMode;
   
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
      if (~isempty(profFlbbCdStruct.paramDataMode))
         profFlbbCdStruct.paramDataMode = [' ' profFlbbCdStruct.paramDataMode];
      end
      profFlbbCdStruct.data = cat(2, mtimeData, double(profFlbbCdStruct.data));
      
      if (~isempty(profFlbbCd.dataAdj))
         mtimeDataAdj = ones(size(profFlbbCd.dataAdj, 1), 1)*paramMtime.fillValue;
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
   profOcr504IStruct.paramDataMode = profOcr504I.paramDataMode;
   
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
      if (~isempty(profOcr504IStruct.paramDataMode))
         profOcr504IStruct.paramDataMode = [' ' profOcr504IStruct.paramDataMode];
      end
      profOcr504IStruct.data = cat(2, mtimeData, double(profOcr504IStruct.data));
      
      if (~isempty(profOcr504I.dataAdj))
         mtimeDataAdj = ones(size(profOcr504I.dataAdj, 1), 1)*paramMtime.fillValue;
         profOcr504IStruct.dataAdj = cat(2, mtimeDataAdj, double(profOcr504IStruct.dataAdj));
      end
   end
end

% create a profile with RAMSES data
if (~isempty(profRamses))
   
   % initialize a NetCDF profile structure and fill it with decoded profile data
   profRamsesStruct = get_profile_init_struct(a_cycleNum, -1, -1, -1);
   profRamsesStruct.sensorNumber = 109; % to go to PROF_AUX file
   
   % positioning system
   profRamsesStruct.posSystem = 'GPS';
   
   % add parameter variables to the profile structure
   profRamsesStruct.paramList = profRamses.paramList;
   profRamsesStruct.paramDataMode = profRamses.paramDataMode;
   profRamsesStruct.paramNumberWithSubLevels = profRamses.paramNumberWithSubLevels;
   profRamsesStruct.paramNumberOfSubLevels = profRamses.paramNumberOfSubLevels;
   
   % add parameter data to the profile structure
   profRamsesStruct.data = profRamses.data;
   profRamsesStruct.dataAdj = profRamses.dataAdj;
   
   % add press offset data to the profile structure
   profRamsesStruct.presOffset = presOffset;
   
   % add configuration mission number
   profRamsesStruct.configMissionNumber = configMissionNumber;
   
   % add MTIME to data
   if (~isempty(profRamses.dateList))
      if (any(profRamses.dates ~= profRamses.dateList.fillValue))
         % we temporarily store JULD as MTIME (because profile date will be
         % computed later)
         mtimeData = profRamses.dates;
         mtimeData(find(mtimeData == profRamses.dateList.fillValue)) = paramMtime.fillValue;
      else
         mtimeData = ones(size(profRamses.data, 1), 1)*paramMtime.fillValue;
      end
      profRamsesStruct.paramList = [paramMtime profRamsesStruct.paramList];
      profRamsesStruct.paramNumberWithSubLevels = profRamsesStruct.paramNumberWithSubLevels + 1;
      if (~isempty(profRamsesStruct.paramDataMode))
         profRamsesStruct.paramDataMode = [' ' profRamsesStruct.paramDataMode];
      end
      profRamsesStruct.data = cat(2, mtimeData, double(profRamsesStruct.data));
      
      if (~isempty(profRamses.dataAdj))
         mtimeDataAdj = ones(size(profRamses.dataAdj, 1), 1)*paramMtime.fillValue;
         profRamsesStruct.dataAdj = cat(2, mtimeDataAdj, double(profRamsesStruct.dataAdj));
      end
   end
end

% merge CTD_CP data in the CTD_CP_H profile
if ((~isempty(a_profCtdCpH)) && (~isempty(a_profCtdCp)))
   
   a_profCtdCpH.data = [a_profCtdCpH.data; ...
      [a_profCtdCp.data ...
      ones(size(a_profCtdCp.data, 1), 1)*paramVrsPh.fillValue ...
      ones(size(a_profCtdCp.data, 1), 1)*paramNbSampleSfet.fillValue ...
      ones(size(a_profCtdCp.data, 1), 1)*paramPhInSituFree.fillValue ...
      ones(size(a_profCtdCp.data, 1), 1)*paramPhInSituTotal.fillValue]];
   [~, idSort] = sort(a_profCtdCpH.data(:, 1), 'descend');
   a_profCtdCpH.data = a_profCtdCpH.data(idSort, :);
   if (~isempty(a_profCtdCpH.dataAdj))
      a_profCtdCpH.dataAdj = [a_profCtdCpH.dataAdj; ...
         [a_profCtdCp.dataAdj ...
         ones(size(a_profCtdCp.dataAdj, 1), 1)*paramVrsPh.fillValue ...
         ones(size(a_profCtdCp.dataAdj, 1), 1)*paramNbSampleSfet.fillValue ...
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
   profCtdCpStruct.paramDataMode = a_profCtdCp.paramDataMode;
   
   % add parameter data to the profile structure
   profCtdCpStruct.data = flipud(a_profCtdCp.data);
   profCtdCpStruct.dataAdj = flipud(a_profCtdCp.dataAdj);
   
   % add press offset data to the profile structure
   profCtdCpStruct.presOffset = presOffset;
   
   % add configuration mission number
   profCtdCpStruct.configMissionNumber = configMissionNumber;

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
   profCtdCpHStruct.paramDataMode = a_profCtdCpH.paramDataMode;
   
   % add parameter data to the profile structure
   profCtdCpHStruct.data = flipud(a_profCtdCpH.data);
   profCtdCpHStruct.dataAdj = flipud(a_profCtdCpH.dataAdj);
   
   % add press offset data to the profile structure
   profCtdCpHStruct.presOffset = presOffset;
   
   % add configuration mission number
   profCtdCpHStruct.configMissionNumber = configMissionNumber;
   
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
      idPresCtdPtsh  = find(strcmp({profCtdPtshStruct.paramList.name}, 'PRES'), 1);
      idShallow = find(profCtdPtshStruct.data(:, idPresCtdPtsh) < min(profCtdCpStruct.data(:, 1)));
      idDeep = find(profCtdPtshStruct.data(:, idPresCtdPtsh) > max(profCtdCpStruct.data(:, 1)));
      if (~isempty(idShallow) || ~isempty(idDeep))
         profCtdCpStruct.paramList = [paramMtime profCtdCpStruct.paramList paramVrsPh paramNbSampleSfet paramPhInSituFree paramPhInSituTotal];
         if (~isempty(profCtdCpStruct.paramDataMode))
            profCtdCpStruct.paramDataMode = [' ' profCtdCpStruct.paramDataMode '    '];
         end
         profCtdCpStruct.data = [ ...
            ones(size(profCtdCpStruct.data, 1), 1)*paramMtime.fillValue ...
            double(profCtdCpStruct.data) ...
            ones(size(profCtdCpStruct.data, 1), 1)*double(paramVrsPh.fillValue) ...
            ones(size(profCtdCpStruct.data, 1), 1)*double(paramNbSampleSfet.fillValue) ...
            ones(size(profCtdCpStruct.data, 1), 1)*double(paramPhInSituFree.fillValue) ...
            ones(size(profCtdCpStruct.data, 1), 1)*double(paramPhInSituTotal.fillValue)];
         if (~isempty(profCtdCpStruct.dataAdj))
            profCtdCpStruct.dataAdj = [ ...
               ones(size(profCtdCpStruct.dataAdj, 1), 1)*paramMtime.fillValue ...
               double(profCtdCpStruct.dataAdj) ...
               ones(size(profCtdCpStruct.dataAdj, 1), 1)*double(paramVrsPh.fillValue) ...
               ones(size(profCtdCpStruct.dataAdj, 1), 1)*double(paramNbSampleSfet.fillValue) ...
               ones(size(profCtdCpStruct.dataAdj, 1), 1)*double(paramPhInSituFree.fillValue) ...
               ones(size(profCtdCpStruct.dataAdj, 1), 1)*double(paramPhInSituTotal.fillValue)];
         end
         idPresCtdCp  = find(strcmp({profCtdCpStruct.paramList.name}, 'PRES'), 1);
         if (~isempty(idShallow))
            profCtdCpStruct.data = [profCtdCpStruct.data; ...
               profCtdPtshStruct.data(idShallow, :)];
            [~, idSort] = sort(profCtdCpStruct.data(:, idPresCtdCp), 'descend');
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
            [~, idSort] = sort(profCtdCpStruct.data(:, idPresCtdCp), 'descend');
            profCtdCpStruct.data = profCtdCpStruct.data(idSort, :);
            if (~isempty(profCtdCpStruct.dataAdj))
               profCtdCpStruct.dataAdj = [profCtdCpStruct.dataAdj; ...
                  profCtdPtshStruct.dataAdj(idDeep, :)];
               profCtdCpStruct.dataAdj = profCtdCpStruct.dataAdj(idSort, :);
            end
         end
         
         % get detailed description of the VSS
         minMax = [{minP} {maxP}];
         description = create_vss_description_apx_apf11_ir(a_cycleNum, 'CTD', 'PTSH', minMax);
         dataTypeStr = 'mixed';
      end
   elseif (~isempty(profCtdPtsStruct))
      idPresCtdPts  = find(strcmp({profCtdPtsStruct.paramList.name}, 'PRES'), 1);
      idShallow = find(profCtdPtsStruct.data(:, idPresCtdPts) < min(profCtdCpStruct.data(:, 1)));
      idDeep = find(profCtdPtsStruct.data(:, idPresCtdPts) > max(profCtdCpStruct.data(:, 1)));
      if (~isempty(idShallow) || ~isempty(idDeep))
         profCtdCpStruct.paramList = [paramMtime profCtdCpStruct.paramList];
         if (~isempty(profCtdCpStruct.paramDataMode))
            profCtdCpStruct.paramDataMode = [' ' profCtdCpStruct.paramDataMode];
         end
         profCtdCpStruct.data = [ ...
            ones(size(profCtdCpStruct.data, 1), 1)*paramMtime.fillValue ...
            double(profCtdCpStruct.data)];
         if (~isempty(profCtdCpStruct.dataAdj))
            profCtdCpStruct.dataAdj = [ ...
               ones(size(profCtdCpStruct.dataAdj, 1), 1)*paramMtime.fillValue ...
               double(profCtdCpStruct.dataAdj)];
         end
         idPresCtdCp  = find(strcmp({profCtdCpStruct.paramList.name}, 'PRES'), 1);
         if (~isempty(idShallow))
            profCtdCpStruct.data = [profCtdCpStruct.data; ...
               [profCtdPtsStruct.data(idShallow, :) ...
               ones(size(idShallow))*double(paramNbSampleCtd.fillValue) ...
               ]];
            [~, idSort] = sort(profCtdCpStruct.data(:, idPresCtdCp), 'descend');
            profCtdCpStruct.data = profCtdCpStruct.data(idSort, :);
            if (~isempty(profCtdCpStruct.dataAdj))
               profCtdCpStruct.dataAdj = [profCtdCpStruct.dataAdj; ...
                  [profCtdPtsStruct.dataAdj(idShallow, :) ...
                  ones(size(idShallow))*double(paramNbSampleCtd.fillValue) ...
                  ]];
               profCtdCpStruct.dataAdj = profCtdCpStruct.dataAdj(idSort, :);
            end
         end
         if (~isempty(idDeep))
            profCtdCpStruct.data = [profCtdCpStruct.data; ...
               [profCtdPtsStruct.data(idDeep, :) ...
               ones(size(idDeep))*double(paramNbSampleCtd.fillValue) ...
               ]];
            [~, idSort] = sort(profCtdCpStruct.data(:, idPresCtdCp), 'descend');
            profCtdCpStruct.data = profCtdCpStruct.data(idSort, :);
            if (~isempty(profCtdCpStruct.dataAdj))
               profCtdCpStruct.dataAdj = [profCtdCpStruct.dataAdj; ...
                  [profCtdPtsStruct.dataAdj(idDeep, :) ...
                  ones(size(idDeep))*double(paramNbSampleCtd.fillValue) ...
                  ]];
               profCtdCpStruct.dataAdj = profCtdCpStruct.dataAdj(idSort, :);
            end
         end
         
         % get detailed description of the VSS
         minMax = [{minP} {maxP}];
         description = create_vss_description_apx_apf11_ir(a_cycleNum, 'CTD', 'PTS', minMax);
         dataTypeStr = 'mixed';
      else
         
         % get detailed description of the VSS
         minMax = [{''} {''}];
         description = create_vss_description_apx_apf11_ir(a_cycleNum, 'CTD', '', minMax);
         dataTypeStr = 'averaged';
      end
   else
      
      % get detailed description of the VSS
      minMax = [{''} {''}];
      description = create_vss_description_apx_apf11_ir(a_cycleNum, 'CTD', '', minMax);
      dataTypeStr = 'averaged';
   end
      
   % add vertical sampling scheme
   profCtdCpStruct.vertSamplingScheme = sprintf('Primary sampling: %s [%s]', dataTypeStr, description);
   profCtdCpStruct.primarySamplingProfileFlag = 1;
   primaryProfSetFlag = 1;
   
   % add bounce information
   if (~isempty(a_cycleTimeData.iceDescentStartDateSci))
      profCtdCpStruct.bounceFlag = 'BS';
   end
   
   o_ncProfile = [o_ncProfile profCtdCpStruct];
   
   % remove shallow and deep data from original profile
   if (~isempty(profCtdPtshStruct))
      profCtdPtshStruct.data([idShallow; idDeep], :) = [];
      if (~isempty(profCtdPtshStruct.dataAdj))
         profCtdPtshStruct.dataAdj([idShallow; idDeep], :) = [];
      end
      if (isempty(profCtdPtshStruct.data))
         profCtdPtshStruct = [];
      end
   elseif (~isempty(profCtdPtsStruct))
      profCtdPtsStruct.data([idShallow; idDeep], :) = [];
      if (~isempty(profCtdPtsStruct.dataAdj))
         profCtdPtsStruct.dataAdj([idShallow; idDeep], :) = [];
      end
      if (isempty(profCtdPtsStruct.data))
         profCtdPtsStruct = [];
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
      idPresCtdPtsh = find(strcmp({profCtdPtshStruct.paramList.name}, 'PRES'), 1);
      idShallow = find(profCtdPtshStruct.data(:, idPresCtdPtsh) < min(profCtdCpHStruct.data(:, 1)));
      idDeep = find(profCtdPtshStruct.data(:, idPresCtdPtsh) > max(profCtdCpHStruct.data(:, 1)));
      if (~isempty(idShallow) || ~isempty(idDeep))
         profCtdCpHStruct.paramList = [paramMtime profCtdCpHStruct.paramList];
         if (~isempty(profCtdCpHStruct.paramDataMode))
            profCtdCpHStruct.paramDataMode = [' ' profCtdCpHStruct.paramDataMode];
         end
         profCtdCpHStruct.data = [ ...
            ones(size(profCtdCpHStruct.data, 1), 1)*paramMtime.fillValue ...
            double(profCtdCpHStruct.data)];
         if (~isempty(profCtdCpHStruct.dataAdj))
            profCtdCpHStruct.dataAdj = [ ...
               ones(size(profCtdCpHStruct.dataAdj, 1), 1)*paramMtime.fillValue ...
               double(profCtdCpHStruct.dataAdj)];
         end
         idPresCtdCpH = find(strcmp({profCtdCpHStruct.paramList.name}, 'PRES'), 1);
         if (~isempty(idShallow))
            profCtdCpHStruct.data = [profCtdCpHStruct.data; ...
               [double(profCtdPtshStruct.data(idShallow, 1:4)) ...
               ones(size(idShallow))*double(paramNbSampleCtd.fillValue) ...
               double(profCtdPtshStruct.data(idShallow, 5)) ...
               ones(size(idShallow))*double(paramNbSampleSfet.fillValue) ...
               double(profCtdPtshStruct.data(idShallow, 6:end)) ...
               ]];
            [~, idSort] = sort(profCtdCpHStruct.data(:, idPresCtdCpH), 'descend');
            profCtdCpHStruct.data = profCtdCpHStruct.data(idSort, :);
            if (~isempty(profCtdCpHStruct.dataAdj))
               profCtdCpHStruct.dataAdj = [profCtdCpHStruct.dataAdj; ...
                  [double(profCtdPtshStruct.dataAdj(idShallow, 1:4)) ...
                  ones(size(idShallow))*double(paramNbSampleCtd.fillValue) ...
                  double(profCtdPtshStruct.dataAdj(idShallow, 5)) ...
                  ones(size(idShallow))*double(paramNbSampleSfet.fillValue) ...
                  double(profCtdPtshStruct.dataAdj(idShallow, 6:end)) ...
                  ]];
               profCtdCpHStruct.dataAdj = profCtdCpHStruct.dataAdj(idSort, :);
            end
         end
         if (~isempty(idDeep))
            profCtdCpHStruct.data = [profCtdCpHStruct.data; ...
               [double(profCtdPtshStruct.data(idDeep, 1:4)) ...
               ones(size(idDeep))*double(paramNbSampleCtd.fillValue) ...
               double(profCtdPtshStruct.data(idDeep, 5)) ...
               ones(size(idDeep))*double(paramNbSampleSfet.fillValue) ...
               double(profCtdPtshStruct.data(idDeep, 6:end)) ...
               ]];
            [~, idSort] = sort(profCtdCpHStruct.data(:, idPresCtdCpH), 'descend');
            profCtdCpHStruct.data = profCtdCpHStruct.data(idSort, :);
            if (~isempty(profCtdCpHStruct.dataAdj))
               profCtdCpHStruct.dataAdj = [profCtdCpHStruct.dataAdj; ...
                  [double(profCtdPtshStruct.dataAdj(idDeep, 1:4)) ...
                  ones(size(idDeep))*double(paramNbSampleCtd.fillValue) ...
                  double(profCtdPtshStruct.dataAdj(idDeep, 5)) ...
                  ones(size(idDeep))*double(paramNbSampleSfet.fillValue) ...
                  double(profCtdPtshStruct.dataAdj(idDeep, 6:end)) ...
                  ]];
               profCtdCpHStruct.dataAdj = profCtdCpHStruct.dataAdj(idSort, :);
            end
         end
         
         % get detailed description of the VSS
         minMax = [{minP} {maxP}];
         description = create_vss_description_apx_apf11_ir(a_cycleNum, 'PH', 'PTSH', minMax);
         dataTypeStr = 'mixed';
      else
         
         idPresCtdCpH = find(strcmp({profCtdCpHStruct.paramList.name}, 'PRES'), 1);
         [~, idSort] = sort(profCtdCpHStruct.data(:, idPresCtdCpH), 'descend');
         profCtdCpHStruct.data = profCtdCpHStruct.data(idSort, :);
         if (~isempty(profCtdCpHStruct.dataAdj))
            profCtdCpHStruct.dataAdj = profCtdCpHStruct.dataAdj(idSort, :);
         end
         
         % get detailed description of the VSS
         minMax = [{''} {''}];
         description = create_vss_description_apx_apf11_ir(a_cycleNum, 'PH', '', minMax);
         dataTypeStr = 'averaged';
      end
   elseif (~isempty(profCtdPtsStruct))
      idPresCtdPts = find(strcmp({profCtdPtsStruct.paramList.name}, 'PRES'), 1);
      idShallow = find(profCtdPtsStruct.data(:, idPresCtdPts) < min(profCtdCpHStruct.data(:, 1)));
      idDeep = find(profCtdPtsStruct.data(:, idPresCtdPts) > max(profCtdCpHStruct.data(:, 1)));
      if (~isempty(idShallow) || ~isempty(idDeep))
         profCtdCpHStruct.paramList = [paramMtime profCtdCpHStruct.paramList];
         if (~isempty(profCtdCpHStruct.paramDataMode))
            profCtdCpHStruct.paramDataMode = [' ' profCtdCpHStruct.paramDataMode];
         end
         profCtdCpHStruct.data = [ ...
            ones(size(profCtdCpHStruct.data, 1), 1)*paramMtime.fillValue ...
            double(profCtdCpHStruct.data)];
         if (~isempty(profCtdCpHStruct.dataAdj))
            profCtdCpHStruct.dataAdj = [ ...
               ones(size(profCtdCpHStruct.dataAdj, 1), 1)*paramMtime.fillValue ...
               double(profCtdCpHStruct.dataAdj)];
         end
         idPresCtdCpH = find(strcmp({profCtdCpHStruct.paramList.name}, 'PRES'), 1);
         if (~isempty(idShallow))
            profCtdCpHStruct.data = [profCtdCpHStruct.data; ...
               [profCtdPtsStruct.data(idShallow, :) ...
               ones(length(idShallow), 1)*paramNbSampleCtd.fillValue ...
               ones(length(idShallow), 1)*paramVrsPh.fillValue ...
               ones(length(idShallow), 1)*paramNbSampleSfet.fillValue ...
               ones(length(idShallow), 1)*paramPhInSituFree.fillValue ...
               ones(length(idShallow), 1)*paramPhInSituTotal.fillValue]];
            [~, idSort] = sort(profCtdCpHStruct.data(:, idPresCtdCpH), 'descend');
            profCtdCpHStruct.data = profCtdCpHStruct.data(idSort, :);
            if (~isempty(profCtdCpHStruct.dataAdj))
               profCtdCpHStruct.dataAdj = [profCtdCpHStruct.dataAdj; ...
                  [profCtdPtsStruct.dataAdj(idShallow, :) ...
                  ones(length(idShallow), 1)*paramNbSampleCtd.fillValue ...
                  ones(length(idShallow), 1)*paramVrsPh.fillValue ...
                  ones(length(idShallow), 1)*paramNbSampleSfet.fillValue ...
                  ones(length(idShallow), 1)*paramPhInSituFree.fillValue ...
                  ones(length(idShallow), 1)*paramPhInSituTotal.fillValue]];
               profCtdCpHStruct.dataAdj = profCtdCpHStruct.dataAdj(idSort, :);
            end
         end
         if (~isempty(idDeep))
            profCtdCpHStruct.data = [profCtdCpHStruct.data; ...
               [profCtdPtsStruct.data(idDeep, :) ...
               ones(length(idDeep), 1)*paramNbSampleCtd.fillValue ...
               ones(length(idDeep), 1)*paramVrsPh.fillValue ...
               ones(length(idDeep), 1)*paramNbSampleSfet.fillValue ...
               ones(length(idDeep), 1)*paramPhInSituFree.fillValue ...
               ones(length(idDeep), 1)*paramPhInSituTotal.fillValue]];
            [~, idSort] = sort(profCtdCpHStruct.data(:, idPresCtdCpH), 'descend');
            profCtdCpHStruct.data = profCtdCpHStruct.data(idSort, :);
            if (~isempty(profCtdCpHStruct.dataAdj))
               profCtdCpHStruct.dataAdj = [profCtdCpHStruct.dataAdj; ...
                  [profCtdPtsStruct.dataAdj(idDeep, :) ...
                  ones(length(idDeep), 1)*paramNbSampleCtd.fillValue ...
                  ones(length(idDeep), 1)*paramVrsPh.fillValue ...
                  ones(length(idDeep), 1)*paramNbSampleSfet.fillValue ...
                  ones(length(idDeep), 1)*paramPhInSituFree.fillValue ...
                  ones(length(idDeep), 1)*paramPhInSituTotal.fillValue]];
               profCtdCpHStruct.dataAdj = profCtdCpHStruct.dataAdj(idSort, :);
            end
         end
         
         % get detailed description of the VSS
         minMax = [{minP} {maxP}];
         description = create_vss_description_apx_apf11_ir(a_cycleNum, 'PH', 'PTS', minMax);
         dataTypeStr = 'mixed';
      else
         
         idPresCtdCpH = find(strcmp({profCtdCpHStruct.paramList.name}, 'PRES'), 1);
         [~, idSort] = sort(profCtdCpHStruct.data(:, idPresCtdCpH), 'descend');
         profCtdCpHStruct.data = profCtdCpHStruct.data(idSort, :);
         if (~isempty(profCtdCpHStruct.dataAdj))
            profCtdCpHStruct.dataAdj = profCtdCpHStruct.dataAdj(idSort, :);
         end
         
         % get detailed description of the VSS
         minMax = [{''} {''}];
         description = create_vss_description_apx_apf11_ir(a_cycleNum, 'PH', '', minMax);
         dataTypeStr = 'averaged';
      end
   else
      
      idPresCtdCpH = find(strcmp({profCtdCpHStruct.paramList.name}, 'PRES'), 1);
      [~, idSort] = sort(profCtdCpHStruct.data(:, idPresCtdCpH), 'descend');
      profCtdCpHStruct.data = profCtdCpHStruct.data(idSort, :);
      if (~isempty(profCtdCpHStruct.dataAdj))
         profCtdCpHStruct.dataAdj = profCtdCpHStruct.dataAdj(idSort, :);
      end
      
      % get detailed description of the VSS
      minMax = [{''} {''}];
      description = create_vss_description_apx_apf11_ir(a_cycleNum, 'PH', '', minMax);
      dataTypeStr = 'averaged';
   end
   
   % add vertical sampling scheme
   profCtdCpHStruct.vertSamplingScheme = sprintf('Primary sampling: %s [%s]', dataTypeStr, description);
   profCtdCpHStruct.primarySamplingProfileFlag = 1;
   primaryProfSetFlag = 1;
   
   % add bounce information
   if (~isempty(a_cycleTimeData.iceDescentStartDateSci))
      profCtdCpHStruct.bounceFlag = 'BS';
   end
   
   o_ncProfile = [o_ncProfile profCtdCpHStruct];

   % remove shallow and deep data from original profile
   if (~isempty(profCtdPtshStruct))
      profCtdPtshStruct.data([idShallow; idDeep], :) = [];
      if (~isempty(profCtdPtshStruct.dataAdj))
         profCtdPtshStruct.dataAdj([idShallow; idDeep], :) = [];
      end
      % discrete PH data are not sampled during CP mode, we should remove
      % associated parameters in discrete profile
      profCtdPtshStruct = remove_unused_param(profCtdPtshStruct);
      if (isempty(profCtdPtshStruct.data))
         profCtdPtshStruct = [];
      end
   elseif (~isempty(profCtdPtsStruct))
      profCtdPtsStruct.data([idShallow; idDeep], :) = [];
      if (~isempty(profCtdPtsStruct.dataAdj))
         profCtdPtsStruct.dataAdj([idShallow; idDeep], :) = [];
      end
      if (isempty(profCtdPtsStruct.data))
         profCtdPtsStruct = [];
      end
   end
end

if (~isempty(profCtdPtsStruct))
   
   % get detailed description of the VSS
   minMax = [{''} {''}];
   description = create_vss_description_apx_apf11_ir(a_cycleNum, 'PTS', '', minMax);
   
   % add vertical sampling scheme
   if (~primaryProfSetFlag)
      profCtdPtsStruct.vertSamplingScheme = sprintf('Primary sampling: discrete [%s]', description);
      profCtdPtsStruct.primarySamplingProfileFlag = 1;
      primaryProfSetFlag = 1;
   else
      profCtdPtsStruct.vertSamplingScheme = sprintf('Secondary sampling: discrete [%s]', description);
      profCtdPtsStruct.primarySamplingProfileFlag = 0;
   end
   
   % add bounce information
   if (~isempty(a_cycleTimeData.iceDescentStartDateSci))
      profCtdPtsStruct.bounceFlag = 'BS';
   end
   
   o_ncProfile = [o_ncProfile profCtdPtsStruct];
end

if (~isempty(profCtdPtshStruct))
   
   % get detailed description of the VSS
   minMax = [{''} {''}];
   description = create_vss_description_apx_apf11_ir(a_cycleNum, 'PTSH', '', minMax);
   
   % add vertical sampling scheme
   if (~primaryProfSetFlag)
      profCtdPtshStruct.vertSamplingScheme = sprintf('Primary sampling: discrete [%s]', description);
      profCtdPtshStruct.primarySamplingProfileFlag = 1;
   else
      profCtdPtshStruct.vertSamplingScheme = sprintf('Secondary sampling: discrete [%s]', description);
      profCtdPtshStruct.primarySamplingProfileFlag = 0;
   end
   
   % add bounce information
   if (~isempty(a_cycleTimeData.iceDescentStartDateSci))
      profCtdPtshStruct.bounceFlag = 'BS';
   end
   
   o_ncProfile = [o_ncProfile profCtdPtshStruct];
end

if (~isempty(profDoStruct))
   
   % get detailed description of the VSS
   minMax = [{''} {''}];
   description = create_vss_description_apx_apf11_ir(a_cycleNum, 'OPT', '', minMax);
   
   % add vertical sampling scheme
   profDoStruct.vertSamplingScheme = sprintf('Secondary sampling: discrete [%s]', description);
   profDoStruct.primarySamplingProfileFlag = 0;
   
   % add bounce information
   if (~isempty(a_cycleTimeData.iceDescentStartDateSci))
      profDoStruct.bounceFlag = 'BS';
   end
   
   o_ncProfile = [o_ncProfile profDoStruct];
end

if (~isempty(profFlbbCdStruct))
   
   % get detailed description of the VSS
   minMax = [{''} {''}];
   description = create_vss_description_apx_apf11_ir(a_cycleNum, 'FLBB', '', minMax);
   
   % add vertical sampling scheme
   profFlbbCdStruct.vertSamplingScheme = sprintf('Secondary sampling: discrete [%s]', description);
   profFlbbCdStruct.primarySamplingProfileFlag = 0;
   
   % add bounce information
   if (~isempty(a_cycleTimeData.iceDescentStartDateSci))
      profFlbbCdStruct.bounceFlag = 'BS';
   end
   
   o_ncProfile = [o_ncProfile profFlbbCdStruct];
end

if (~isempty(profOcr504IStruct))
   
   % get detailed description of the VSS
   minMax = [{''} {''}];
   description = create_vss_description_apx_apf11_ir(a_cycleNum, 'IRAD', '', minMax);
   
   % add vertical sampling scheme
   profOcr504IStruct.vertSamplingScheme = sprintf('Secondary sampling: discrete [%s]', description);
   profOcr504IStruct.primarySamplingProfileFlag = 0;
   
   % add bounce information
   if (~isempty(a_cycleTimeData.iceDescentStartDateSci))
      profOcr504IStruct.bounceFlag = 'BS';
   end
   
   o_ncProfile = [o_ncProfile profOcr504IStruct];
end

if (~isempty(profRamsesStruct))
   
   % get detailed description of the VSS
   minMax = [{''} {''}];
   description = create_vss_description_apx_apf11_ir(a_cycleNum, 'IRAD', '', minMax);
   
   % add vertical sampling scheme
   profRamsesStruct.vertSamplingScheme = sprintf('Secondary sampling: discrete [%s]', description);
   profRamsesStruct.primarySamplingProfileFlag = 0;
   
   % add bounce information
   if (~isempty(a_cycleTimeData.iceDescentStartDateSci))
      profRamsesStruct.bounceFlag = 'BS';
   end
   
   o_ncProfile = [o_ncProfile profRamsesStruct];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ICE PROFILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create Ice profiles
if (~isempty(profIceCtdPt) || ...
      ~isempty(profIceCtdPts) || ...
      ~isempty(profIceCtdPtsh) || ...
      ~isempty(profIceDo) || ...
      ~isempty(profIceFlbbCd) || ...
      ~isempty(profIceOcr504I) || ...
      ~isempty(profIceRamses) ...
      )
   
   for idS = 0:6

      if (idS == 0)
         profIce = profIceCtdPt;
         sensorName = 'PT';
      elseif (idS == 1)
         profIce = profIceCtdPts;
         sensorName = 'PTS';
      elseif (idS == 2)
         profIce = profIceCtdPtsh;
         sensorName = 'PTSH';
      elseif (idS == 3)
         profIce = profIceDo;
         sensorName = 'OPT';
      elseif (idS == 4)
         profIce = profIceFlbbCd;
         sensorName = 'FLBB';
      elseif (idS == 5)
         profIce = profIceOcr504I;
         sensorName = 'IRAD';
      elseif (idS == 6)
         profIce = profIceRamses;
         sensorName = 'IRAD';
      end
      
      if (isempty(profIce))
         continue
      end
      
      for idP = 1:size(profIce, 1)
         
         profIceData = profIce{idP, 3};
         
         % initialize a NetCDF profile structure and fill it with decoded profile data
         profIceStruct = get_profile_init_struct(a_cycleNum, -1, -1, -1);
         profIceStruct.sensorNumber = 0;
         if (idS == 6)
            profIceStruct.sensorNumber = 109; % to go to PROF_AUX file
         end
         
         % date of the profile
         profIceStruct.date = a_cycleTimeData.iceAscentEndDateSci(profIce{idP, 1});
         if (profIce{idP, 2} == 1)
            profIceStruct.direction = 'D';
            profIceStruct.date = a_cycleTimeData.iceDescentStartDateSci(profIce{idP, 1});
         end
         
         % positioning system
         profIceStruct.posSystem = 'GPS';
         
         % add parameter variables to the profile structure
         profIceStruct.paramList = profIceData.paramList;
         profIceStruct.paramDataMode = profIceData.paramDataMode;
         
         % add parameter data to the profile structure
         profIceStruct.data = profIceData.data;
         profIceStruct.dataAdj = profIceData.dataAdj;
         
         % add press offset data to the profile structure
         profIceStruct.presOffset = presOffset;
         
         % add configuration mission number
         profIceStruct.configMissionNumber = configMissionNumber;

         % add MTIME to data
         if (profIceData.temporaryDates ~= 1)
            if (~isempty(profIceData.dateList))
               if (any(profIceData.dates ~= profIceData.dateList.fillValue))
                  % we temporarily store JULD as MTIME (because profile date will be
                  % computed later)
                  mtimeData = profIceData.dates;
                  mtimeData(find(mtimeData == profIceData.dateList.fillValue)) = paramMtime.fillValue;
               else
                  mtimeData = ones(size(profIceData.data, 1), 1)*paramMtime.fillValue;
               end
               profIceStruct.paramList = [paramMtime profIceStruct.paramList];
               if (~isempty(profIceStruct.paramDataMode))
                  profIceStruct.paramDataMode = [' ' profIceStruct.paramDataMode];
               end
               profIceStruct.data = cat(2, mtimeData, double(profIceStruct.data));
               
               if (~isempty(profIceData.dataAdj))
                  mtimeDataAdj = ones(size(profIceData.dataAdj, 1), 1)*paramMtime.fillValue;
                  profIceStruct.dataAdj = cat(2, mtimeDataAdj, double(profIceStruct.dataAdj));
               end
            end
         else
            idPres = find(strcmp({profIceStruct.paramList.name}, 'PRES'), 1);
            profIceStruct.dataQc = ones(size(profIceStruct.data))*g_decArgo_qcDef;
            profIceStruct.dataQc(:, idPres) = g_decArgo_qcProbablyGood;
            if (~isempty(profIceStruct.dataAdj))
               profIceStruct.dataAdjQc = ones(size(profIceStruct.data))*g_decArgo_qcDef;
               profIceStruct.dataAdjQc(:, idPres) = g_decArgo_qcProbablyGood;
            end
         end
         
         % get detailed description of the VSS
         description = create_vss_description_apx_apf11_ir_ice_cycle(a_cycleNum, sensorName, profIceStruct.direction);
         
         % add vertical sampling scheme
         profIceStruct.vertSamplingScheme = sprintf('Bounce sampling: discrete [%s]', description);
         profIceStruct.primarySamplingProfileFlag = 0;
         
         % add bounce information
         if (profIce{idP, 1} == max(profIce{:, 1}))
            profIceStruct.bounceFlag = 'BE';
         else
            profIceStruct.bounceFlag = 'B';
         end
         
         o_ncProfile = [o_ncProfile profIceStruct];
      end
   end
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
if (~isempty(o_ncProfile.paramDataMode))
   o_ncProfile.paramDataMode(idParamTodel) = [];
end
o_ncProfile.data(:, idParamTodel) = [];
if (~isempty(o_ncProfile.dataAdj))
   o_ncProfile.dataAdj(:, idParamTodel) = [];
end

return

