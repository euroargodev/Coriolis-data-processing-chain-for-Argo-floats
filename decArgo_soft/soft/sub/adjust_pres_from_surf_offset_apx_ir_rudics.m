% ------------------------------------------------------------------------------
% Compute pressure surface offset to use to adjust pressure measurements
% (according to Argo QC manual). Then, adjust decoded PRES measurements.
%
% SYNTAX :
%  [o_surfPresInfo, ...
%    o_surfDataLog, ...
%    o_pMarkDataMsg, o_pMarkDataLog, ...
%    o_driftData, o_parkData, o_parkDataEng, ...
%    o_profLrData, o_profHrData, ...
%    o_nearSurfData, ...
%    o_surfDataBladderDeflated, o_surfDataBladderInflated, o_surfDataMsg, ...
%    o_timeDataLog, ...
%    o_presOffsetData] = ...
%    adjust_pres_from_surf_offset_apx_ir_rudics(a_surfDataLog, ...
%    a_pMarkDataMsg, a_pMarkDataLog, ...
%    a_driftData, a_parkData, a_parkDataEng, ...
%    a_profLrData, a_profHrData, ...
%    a_nearSurfData, ...
%    a_surfDataBladderDeflated, a_surfDataBladderInflated, a_surfDataMsg, ...
%    a_timeDataLog, ...
%    a_presOffsetData)
%
% INPUT PARAMETERS :
%   a_surfDataLog             : input surf data from log file
%   a_pMarkDataMsg            : input P marks from msg file
%   a_pMarkDataLog            : input P marks from log file
%   a_driftData               : input drift data
%   a_parkData                : input park data
%   a_parkDataEng             : input park data from engineering data
%   a_profLrData              : input profile LR data
%   a_profHrData              : input profile HR data
%   a_nearSurfData            : input NS data
%   a_surfDataBladderDeflated : input surface data
%   a_surfDataBladderInflated : input surface data
%   a_surfDataMsg             : input surface data from engineering data
%   a_timeDataLog             : input cycle timings from log file
%   a_presOffsetData          : input pressure offset information
%
% OUTPUT PARAMETERS :
%   o_surfPresInfo            : offset pressure information
%   o_surfDataLog             : output surf data from log file
%   o_pMarkDataMsg            : output P marks from msg file
%   o_pMarkDataLog            : output P marks from log file
%   o_driftData               : output drift data
%   o_parkData                : output park data
%   o_parkDataEng             : output park data from engineering data
%   o_profLrData              : output profile LR data
%   o_profHrData              : output profile HR data
%   o_nearSurfData            : output NS data
%   o_surfDataBladderDeflated : output surface data
%   o_surfDataBladderInflated : output surface data
%   o_surfDataMsg             : output surface data from engineering data
%   o_timeDataLog             : output cycle timings from log file
%   o_presOffsetData          : updated pressure offset information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_surfPresInfo, ...
   o_surfDataLog, ...
   o_pMarkDataMsg, o_pMarkDataLog, ...
   o_driftData, o_parkData, o_parkDataEng, ...
   o_profLrData, o_profHrData, ...
   o_nearSurfData, ...
   o_surfDataBladderDeflated, o_surfDataBladderInflated, o_surfDataMsg, ...
   o_timeDataLog, ...
   o_presOffsetData] = ...
   adjust_pres_from_surf_offset_apx_ir_rudics(a_surfDataLog, ...
   a_pMarkDataMsg, a_pMarkDataLog, ...
   a_driftData, a_parkData, a_parkDataEng, ...
   a_profLrData, a_profHrData, ...
   a_nearSurfData, ...
   a_surfDataBladderDeflated, a_surfDataBladderInflated, a_surfDataMsg, ...
   a_timeDataLog, ...
   a_presOffsetData)

% output parameters initialization
o_surfPresInfo = [];
o_surfDataLog = a_surfDataLog;
o_pMarkDataMsg = a_pMarkDataMsg;
o_pMarkDataLog = a_pMarkDataLog;
o_driftData = a_driftData;
o_parkData = a_parkData;
o_parkDataEng = a_parkDataEng;
o_profLrData = a_profLrData;
o_profHrData = a_profHrData;
o_nearSurfData = a_nearSurfData;
o_surfDataBladderDeflated = a_surfDataBladderDeflated;
o_surfDataBladderInflated = a_surfDataBladderInflated;
o_surfDataMsg = a_surfDataMsg;
o_timeDataLog = a_timeDataLog;
o_presOffsetData = a_presOffsetData;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% current cycle number
global g_decArgo_cycleNum;


% select the pressure offset value to use
presOffset = get_pres_offset(o_presOffsetData, g_decArgo_cycleNum);
presOffsetPrev = get_pres_offset(o_presOffsetData, max(g_decArgo_cycleNum-1, 0));

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

if (~isempty(presOffsetPrev))
   o_surfDataLog = adjust_profile(o_surfDataLog, presOffsetPrev);
end

if (~isempty(presOffset))
   
   % store the adjustment value
   o_presOffsetData.cycleNumAdjPres(end+1) = g_decArgo_cycleNum;
   o_presOffsetData.presOffset(end+1) = presOffset;
   
   o_pMarkDataMsg = adjust_profile(o_pMarkDataMsg, round(presOffset/10)*10);
   o_pMarkDataLog = adjust_profile(o_pMarkDataLog, presOffset);
   o_driftData = adjust_profile(o_driftData, presOffset);
   o_parkData = adjust_profile(o_parkData, presOffset);
   o_parkDataEng = adjust_profile(o_parkDataEng, presOffset);
   o_profLrData = adjust_profile(o_profLrData, presOffset);
   o_profHrData = adjust_profile(o_profHrData, presOffset);
   o_nearSurfData = adjust_profile(o_nearSurfData, presOffset);
   o_surfDataBladderDeflated = adjust_profile(o_surfDataBladderDeflated, presOffset);
   o_surfDataBladderInflated = adjust_profile(o_surfDataBladderInflated, presOffset);
   o_surfDataMsg = adjust_profile(o_surfDataMsg, presOffset);

   if (~isempty(o_timeDataLog))
      if (~isempty(o_timeDataLog.parkEndMeas))
         o_timeDataLog.parkEndMeas = adjust_profile(o_timeDataLog.parkEndMeas, presOffset);
      end
      if (~isempty(o_timeDataLog.ascentStartPres))
         o_timeDataLog.ascentStartAdjPres = o_timeDataLog.ascentStartPres - presOffset;
      end
      if (~isempty(o_timeDataLog.ascentEndPres))
         o_timeDataLog.ascentEndAdjPres = o_timeDataLog.ascentEndPres - presOffset;
      end
   end
end

return;

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
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_presOffset] = get_pres_offset(a_presOffsetData, a_cycleNum)

% output parameters initialization
o_presOffset = [];

% current float WMO number
global g_decArgo_floatNum;


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

return;

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
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profData] = adjust_profile(a_profData, a_presOffset)

% output parameters initialization
o_profData = a_profData;


if (iscell(a_profData))
   for idP = 1:length(o_profData)
      o_profData{idP} = adjust_one_profile(o_profData{idP}, a_presOffset);
   end
else
   o_profData = adjust_one_profile(o_profData, a_presOffset);
end

return;

% ------------------------------------------------------------------------------
% Adjust PRES measurements of a given profile.
%
% SYNTAX :
%  [o_profData] = adjust_one_profile(a_profData, a_presOffset)
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
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profData] = adjust_one_profile(a_profData, a_presOffset)

% output parameters initialization
o_profData = a_profData;


if (~isempty(o_profData))
   profParamList = o_profData.paramList;
   profDataAdj = o_profData.data;
   
   if (~isempty(profDataAdj))
      idPres = find(strcmp({profParamList.name}, 'PRES') == 1, 1);
      if (~isempty(idPres))
         paramPres = get_netcdf_param_attributes('PRES');
         idNoDef = find(profDataAdj(:, idPres) ~= paramPres.fillValue);
         profDataAdj(idNoDef, idPres) = profDataAdj(idNoDef, idPres) - a_presOffset;
         o_profData.dataAdj = profDataAdj;
      end
   end
end

return;
