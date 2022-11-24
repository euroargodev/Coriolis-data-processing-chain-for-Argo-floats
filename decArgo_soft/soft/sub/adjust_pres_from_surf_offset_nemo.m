% ------------------------------------------------------------------------------
% Compute pressure surface offset to use to adjust pressure measurements
% (according to Argo QC manual). Then, adjust decoded PRES measurements.
% 
% SYNTAX :
%  [o_surfPresInfo, ...
%    o_parkData, o_rafosData, o_profileData, o_cycleTimeData, ...
%    o_presOffsetData] = ...
%    adjust_pres_from_surf_offset_nemo(a_parkData, a_rafosData, a_profileData, ...
%    a_cycleTimeData, a_presOffsetData)
% 
% INPUT PARAMETERS :
%   a_parkData       : input park data
%   a_rafosData      : input RAFOS data
%   a_profileData    : input profile data
%   a_cycleTimeData  : input cycle timings
%   a_presOffsetData : input pressure offset information
% 
% OUTPUT PARAMETERS :
%   o_surfPresInfo   : offset pressure information
%   o_parkData       : output park data
%   o_rafosData      : output RAFOS data
%   o_profileData    : output profile data
%   o_cycleTimeData  : output cycle timings
%   o_presOffsetData : output pressure offset information
% 
% EXAMPLES :
% 
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_surfPresInfo, ...
   o_parkData, o_rafosData, o_profileData, o_cycleTimeData, ...
   o_presOffsetData] = ...
   adjust_pres_from_surf_offset_nemo(a_parkData, a_rafosData, a_profileData, ...
   a_cycleTimeData, a_presOffsetData)

% output parameters initialization
o_surfPresInfo = [];
o_parkData = a_parkData;
o_rafosData = a_rafosData;
o_profileData = a_profileData;
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
   
   o_parkData = adjust_profile(o_parkData, presOffset);
   o_rafosData = adjust_profile(o_rafosData, presOffset);
   o_profileData = adjust_profile(o_profileData, presOffset);
   
   if (~isempty(o_cycleTimeData))
      if (~isempty(o_cycleTimeData.rafosPres))
         o_cycleTimeData.rafosAdjPres = o_cycleTimeData.rafosPres - presOffset;
      end
      if (~isempty(o_cycleTimeData.profilePres))
         o_cycleTimeData.profileAdjPres = o_cycleTimeData.profilePres - presOffset;
      end
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
%   02/03/2020 - RNU - creation
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
%   02/03/2020 - RNU - creation
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
