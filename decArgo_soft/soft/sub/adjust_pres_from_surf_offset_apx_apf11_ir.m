% ------------------------------------------------------------------------------
% Compute pressure surface offset to use to adjust pressure measurements
% (according to Argo QC manual). Then, adjust decoded PRES measurements.
%
% SYNTAX :
%  [o_profCtdP, o_profCtdPt, o_profCtdPts, o_profCtdCp, ...
%    o_grounding, o_buoyancy, o_cycleTimeData, o_presOffsetData] = ...
%    adjust_pres_from_surf_offset_apx_apf11_ir( ...
%    a_profCtdP, a_profCtdPt, a_profCtdPts, a_profCtdCp, ...
%    a_grounding, a_buoyancy, a_cycleTimeData, a_presOffsetData)
%
% INPUT PARAMETERS :
%   a_profCtdP       : input CTD_P data
%   a_profCtdPt      : input CTD_PT data
%   a_profCtdPts     : input CTD_PTS data
%   a_profCtdCp      : input CTD_CP data
%   a_grounding      : input grounding data
%   a_buoyancy       : input buoyancy data
%   a_cycleTimeData  : input cycle timings data
%   a_presOffsetData : input pressure offset information
%
% OUTPUT PARAMETERS :
%   o_profCtdP       : output CTD_P data
%   o_profCtdPt      : output CTD_PT data
%   o_profCtdPts     : output CTD_PTS data
%   o_profCtdCp      : output CTD_CP data
%   o_grounding      : output grounding data
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
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profCtdP, o_profCtdPt, o_profCtdPts, o_profCtdCp, ...
   o_grounding, o_buoyancy, o_cycleTimeData, o_presOffsetData] = ...
   adjust_pres_from_surf_offset_apx_apf11_ir( ...
   a_profCtdP, a_profCtdPt, a_profCtdPts, a_profCtdCp, ...
   a_grounding, a_buoyancy, a_cycleTimeData, a_presOffsetData)

% output parameters initialization
o_surfPresInfo = [];
o_profCtdP = a_profCtdP;
o_profCtdPt = a_profCtdPt;
o_profCtdPts = a_profCtdPts;
o_profCtdCp = a_profCtdCp;
o_grounding = a_grounding;
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
   o_profCtdCp = adjust_profile(o_profCtdCp, presOffset);
   
   for idG =1:size(o_grounding, 1)
      o_grounding(idG, 4) = adjust_value(o_grounding(idG, 3), presOffset);
   end

   for idB =1:size(o_buoyancy, 1)
      o_buoyancy(idB, 4) = adjust_value(o_buoyancy(idB, 3), presOffset);
   end

   o_cycleTimeData.descentStartAdjPresSci = adjust_value(o_cycleTimeData.descentStartPresSci, presOffset);
   o_cycleTimeData.parkStartAdjPresSci = adjust_value(o_cycleTimeData.parkStartPresSci, presOffset);
   o_cycleTimeData.parkEndAdjPresSci = adjust_value(o_cycleTimeData.parkEndPresSci, presOffset);
   o_cycleTimeData.ascentStartAdjPresSci = adjust_value(o_cycleTimeData.ascentStartPresSci, presOffset);
   o_cycleTimeData.continuousProfileStartAdjPresSci = adjust_value(o_cycleTimeData.continuousProfileStartPresSci, presOffset);
   o_cycleTimeData.ascentEndAdjPresSci = adjust_value(o_cycleTimeData.ascentEndPresSci, presOffset);
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

return;
