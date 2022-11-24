% ------------------------------------------------------------------------------
% Compute pressure surface offset to use to adjust pressure measurements
% (according to Argo QC manual). Then, adjust decoded PRES measurements.
%
% SYNTAX :
%  [o_profCtdP, o_profCtdPt, o_profCtdPts, o_profCtdPtsh, o_profDo, ...
%    o_profCtdCp, o_profCtdCpH, o_profFlbbCd, o_profFlbbCdCfg, o_profOcr504I, ...
%    o_profRamses, ...
%    o_grounding, o_iceDetection, o_buoyancy, o_cycleTimeData, o_presOffsetData] = ...
%    adjust_pres_from_surf_offset_apx_apf11_ir( ...
%    a_profCtdP, a_profCtdPt, a_profCtdPts, a_profCtdPtsh, a_profDo, ...
%    a_profCtdCp, a_profCtdCpH, a_profFlbbCd, a_profFlbbCdCfg, a_profOcr504I, ...
%    a_profRamses, ...
%    a_grounding, a_iceDetection, a_buoyancy, a_cycleTimeData, a_presOffsetData)
%
% INPUT PARAMETERS :
%   a_profCtdP       : input CTD_P data
%   a_profCtdPt      : input CTD_PT data
%   a_profCtdPts     : input CTD_PTS data
%   a_profCtdPtsh    : input CTD_PTSH data
%   a_profDo         : input O2 data
%   a_profCtdCp      : input CTD_CP data
%   a_profCtdCpH     : input CTD_CP_H data
%   a_profFlbbCd     : input FLBB_CD data
%   a_profFlbbCdCfg  : input FLBB_CD_CFG data
%   a_profOcr504I    : input OCR_504I data
%   a_profRamses     : input RAMSES data
%   a_grounding      : input grounding data
%   a_iceDetection   : input ice detection data
%   a_buoyancy       : input buoyancy data
%   a_cycleTimeData  : input cycle timings data
%   a_presOffsetData : input pressure offset information
%
% OUTPUT PARAMETERS :
%   o_profCtdP       : output CTD_P data
%   o_profCtdPt      : output CTD_PT data
%   o_profCtdPts     : output CTD_PTS data
%   o_profCtdPtsh    : output CTD_PTSH data
%   o_profDo         : output O2 data
%   o_profCtdCp      : output CTD_CP data
%   o_profCtdCpH     : output CTD_CP_H data
%   o_profFlbbCd     : output FLBB_CD data
%   o_profFlbbCdCfg  : output FLBB_CD_CFG data
%   o_profOcr504I    : output OCR_504I data
%   o_profRamses     : output RAMSES data
%   o_grounding      : output grounding data
%   o_iceDetection   : output ice detection data
%   o_buoyancy       : output buoyancy data
%   o_cycleTimeData  : output cycle timings data
%   o_presOffsetData : updated pressure offset information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profCtdP, o_profCtdPt, o_profCtdPts, o_profCtdPtsh, o_profDo, ...
   o_profCtdCp, o_profCtdCpH, o_profFlbbCd, o_profFlbbCdCfg, o_profOcr504I, ...
   o_profRamses, ...
   o_grounding, o_iceDetection, o_buoyancy, o_cycleTimeData, o_presOffsetData] = ...
   adjust_pres_from_surf_offset_apx_apf11_ir( ...
   a_profCtdP, a_profCtdPt, a_profCtdPts, a_profCtdPtsh, a_profDo, ...
   a_profCtdCp, a_profCtdCpH, a_profFlbbCd, a_profFlbbCdCfg, a_profOcr504I, ...
   a_profRamses, ...
   a_grounding, a_iceDetection, a_buoyancy, a_cycleTimeData, a_presOffsetData)

% output parameters initialization
o_surfPresInfo = [];
o_profCtdP = a_profCtdP;
o_profCtdPt = a_profCtdPt;
o_profCtdPts = a_profCtdPts;
o_profCtdPtsh = a_profCtdPtsh;
o_profDo = a_profDo;
o_profCtdCp = a_profCtdCp;
o_profCtdCpH = a_profCtdCpH;
o_profFlbbCd = a_profFlbbCd;
o_profFlbbCdCfg = a_profFlbbCdCfg;
o_profOcr504I = a_profOcr504I;
o_profRamses = a_profRamses;
o_grounding = a_grounding;
o_iceDetection = a_iceDetection;
o_buoyancy = a_buoyancy;
o_cycleTimeData = a_cycleTimeData;
o_presOffsetData = a_presOffsetData;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% current cycle number
global g_decArgo_cycleNum;


% select the pressure offset value to use
presOffset = get_pres_offset(o_presOffsetData, g_decArgo_cycleNum);

% report information in CSV file
if (~isempty(g_decArgo_outputCsvFileId))
   if (~isempty(presOffset))
      dataStruct = get_apx_misc_data_init_struct('Pres offset', [], [], []);
      dataStruct.label = 'PRES adjustment value';
      dataStruct.value = presOffset;
      dataStruct.format = '%.1f';
      dataStruct.unit = 'dbar';
      o_surfPresInfo{end+1} = dataStruct;
   else
      dataStruct = get_apx_misc_data_init_struct('Pres offset', [], [], []);
      dataStruct.label = 'PRES ADJUSTMENT VALUE CANNOT BE DETERMINED';
      o_surfPresInfo{end+1} = dataStruct;
   end
end

if (~isempty(presOffset))
   
   % store the adjustment value
   o_presOffsetData.cycleNumAdjPres(end+1) = g_decArgo_cycleNum;
   o_presOffsetData.presOffset(end+1) = presOffset;
   
   o_profCtdP = adjust_profile(o_profCtdP, presOffset);
   o_profCtdPt = adjust_profile(o_profCtdPt, presOffset);
   o_profCtdPts = adjust_profile(o_profCtdPts, presOffset);
   o_profCtdPtsh = adjust_profile(o_profCtdPtsh, presOffset);
   o_profDo = adjust_profile(o_profDo, presOffset);
   o_profCtdCp = adjust_profile(o_profCtdCp, presOffset);
   o_profCtdCpH = adjust_profile(o_profCtdCpH, presOffset);
   o_profFlbbCd = adjust_profile(o_profFlbbCd, presOffset);
   o_profFlbbCdCfg = adjust_profile(o_profFlbbCdCfg, presOffset);
   o_profOcr504I = adjust_profile(o_profOcr504I, presOffset);
   o_profRamses = adjust_profile(o_profRamses, presOffset);
   
   for idG =1:size(o_grounding, 1)
      o_grounding(idG, 4) = adjust_value(o_grounding(idG, 3), presOffset);
   end
   
   for idI = 1:length(o_iceDetection)
      iceDetection = o_iceDetection{idI};
      
      for idM = 1:length(iceDetection.thermalDetect.samplePres)
         iceDetection.thermalDetect.samplePresAdj(idM) = ...
            adjust_value(iceDetection.thermalDetect.samplePres(idM), presOffset);
      end
      if (~isempty(iceDetection.thermalDetect.detectPres))
         iceDetection.thermalDetect.detectPresAdj = ...
            adjust_value(iceDetection.thermalDetect.detectPres, presOffset);
      end
      if (~isempty(iceDetection.thermalDetect.detectMedianPres))
         iceDetection.thermalDetect.detectMedianPresAdj = ...
            adjust_value(iceDetection.thermalDetect.detectMedianPres, presOffset);
      end
      
      o_iceDetection{idI} = iceDetection;
   end
   
   for idB =1:size(o_buoyancy, 1)
      o_buoyancy(idB, 4) = adjust_value(o_buoyancy(idB, 3), presOffset);
   end

   o_cycleTimeData.descentStartAdjPresSci = adjust_value(o_cycleTimeData.descentStartPresSci, presOffset);
   o_cycleTimeData.descentEndAdjPres = adjust_value(o_cycleTimeData.descentEndPres, presOffset);
   for idT = 1:length(o_cycleTimeData.rafosCorrelationStartPresSci)
      o_cycleTimeData.rafosCorrelationStartAdjPresSci = [o_cycleTimeData.rafosCorrelationStartAdjPresSci ...
         adjust_value(o_cycleTimeData.rafosCorrelationStartPresSci(idT), presOffset)];
   end
   o_cycleTimeData.parkStartAdjPresSci = adjust_value(o_cycleTimeData.parkStartPresSci, presOffset);
   o_cycleTimeData.parkEndAdjPresSci = adjust_value(o_cycleTimeData.parkEndPresSci, presOffset);
   o_cycleTimeData.deepDescentEndAdjPres = adjust_value(o_cycleTimeData.deepDescentEndPres, presOffset);
   o_cycleTimeData.ascentStartAdjPresSci = adjust_value(o_cycleTimeData.ascentStartPresSci, presOffset);
   o_cycleTimeData.continuousProfileStartAdjPresSci = adjust_value(o_cycleTimeData.continuousProfileStartPresSci, presOffset);
   o_cycleTimeData.continuousProfileEndAdjPresSci = adjust_value(o_cycleTimeData.continuousProfileEndPresSci, presOffset);
   o_cycleTimeData.ascentEndAdjPresSci = adjust_value(o_cycleTimeData.ascentEndPresSci, presOffset);
   o_cycleTimeData.ascentAbortAdjPres = adjust_value(o_cycleTimeData.ascentAbortPres, presOffset);
   for idT = 1:length(o_cycleTimeData.iceDescentStartPresSci)
      o_cycleTimeData.iceDescentStartAdjPresSci = [o_cycleTimeData.iceDescentStartAdjPresSci ...
         adjust_value(o_cycleTimeData.iceDescentStartPresSci(idT), presOffset)];
   end
   for idT = 1:length(o_cycleTimeData.iceAscentStartPresSci)
      o_cycleTimeData.iceAscentStartAdjPresSci = [o_cycleTimeData.iceAscentStartAdjPresSci ...
         adjust_value(o_cycleTimeData.iceAscentStartPresSci(idT), presOffset)];
   end
   for idT = 1:length(o_cycleTimeData.iceAscentEndPresSci)
      o_cycleTimeData.iceAscentEndAdjPresSci = [o_cycleTimeData.iceAscentEndAdjPresSci ...
         adjust_value(o_cycleTimeData.iceAscentEndPresSci(idT), presOffset)];
   end
end

return

% ------------------------------------------------------------------------------
% Compute pressure surface offset to use to adjust pressure measurements
% (according to Argo QC manual).
%
% SYNTAX :
%  [o_presOffset] = get_pres_offset(a_presOffsetData, a_cycleNum)
%
% INPUT PARAMETERS :
%   a_presOffsetData : pressure offset information
%   a_cycleNum       : concerned cycle number
%
% OUTPUT PARAMETERS :
%   o_presOffset : computed perssure offset value
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_presOffset] = get_pres_offset(a_presOffsetData, a_cycleNum)

% output parameters initialization
o_presOffset = [];

% current float WMO number
global g_decArgo_floatNum;


if (isempty(a_presOffsetData))
   return
end

% select the pressure offset value to use
prevPresOffset = [];
idLastCycleStruct = find([a_presOffsetData.cycleNumAdjPres] < a_cycleNum);
if (~isempty(idLastCycleStruct))
   prevPresOffset = a_presOffsetData.presOffset(idLastCycleStruct(end));
end

presOffset = [];
idCycleStruct = find([a_presOffsetData.cycleNum] == a_cycleNum);
if (~isempty(idCycleStruct))
   cyclePresOffset = a_presOffsetData.cyclePresOffset(idCycleStruct);
   if (abs(cyclePresOffset) <= 20)
      if (~isempty(prevPresOffset))
         if (abs(cyclePresOffset - prevPresOffset) <= 5)
            presOffset = cyclePresOffset;
         end
      else
         presOffset = cyclePresOffset;
      end
   else
      idF = find(ismember(a_cycleNum:-1:a_cycleNum-5, [a_presOffsetData.cycleNum]));
      if ((length(idF) == 6) && ~any(abs(a_presOffsetData.cyclePresOffset(idF)) <= 20))
         fprintf('WARNING: Float #%d should be put on the grey list because of pressure error\n', ...
            g_decArgo_floatNum);
      end
   end
end
if (isempty(presOffset))
   if (~isempty(prevPresOffset))
      presOffset = prevPresOffset;
   end
end

o_presOffset = presOffset;

return

% ------------------------------------------------------------------------------
% Adjust PRES measurements of a given profile.
%
% SYNTAX :
%  [o_profData] = adjust_profile(a_profData, a_presOffset)
%
% INPUT PARAMETERS :
%   a_profData   : profile data to adjust
%   a_presOffset : pressure offset
%
% OUTPUT PARAMETERS :
%   o_profData : adjusted profile data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profData] = adjust_profile(a_profData, a_presOffset)

% output parameters initialization
o_profData = a_profData;


if (~isempty(o_profData))
   if (~isempty(o_profData.data))
      idPres = find(strcmp({o_profData.paramList.name}, 'PRES') == 1, 1);
      if (~isempty(idPres))
         
         profDataAdj = o_profData.data(:, idPres);
         paramPres = get_netcdf_param_attributes('PRES');
         idNoDef = find(profDataAdj ~= paramPres.fillValue);
         if (~isempty(idNoDef))
            
            if (isempty(o_profData.dataAdj))
               o_profData.paramDataMode = repmat(' ', 1, length(o_profData.paramList));
               paramFillValue = get_prof_param_fill_value(o_profData);
               o_profData.dataAdj = repmat(double(paramFillValue), size(o_profData.data, 1), 1);
            end
            
            profDataAdj(idNoDef) = profDataAdj(idNoDef) - a_presOffset;
            o_profData.dataAdj(:, idPres) = profDataAdj;
            o_profData.paramDataMode(idPres) = 'A';
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Adjust PRES of a givent measurement.
%
% SYNTAX :
%  [o_valueAdj] = adjust_value(a_value, a_presOffset)
%
% INPUT PARAMETERS :
%   a_value      : PRES value to adjust
%   a_presOffset : pressure offset to apply
%
% OUTPUT PARAMETERS :
%   o_valueAdj : adjusted PRES value
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_valueAdj] = adjust_value(a_value, a_presOffset)

% output parameters initialization
o_valueAdj = a_value;

% default values
global g_decArgo_presDef;


if (~isempty(a_value) && (a_value ~= g_decArgo_presDef))
   o_valueAdj = a_value - a_presOffset;
end

return
