% ------------------------------------------------------------------------------
% Compute pressure surface offset to use to adjust pressure measurements
% (according to Argo QC manual). Then, adjust decoded PRES measurements.
%
% SYNTAX :
%  [o_miscInfo, o_profData, o_profNstData, o_parkData, o_astData, ...
%    o_surfData, o_trajData, o_timeData, o_presOffsetData] = ...
%    adjust_pres_from_surf_offset_apx_argos(a_miscInfo, a_profData, a_profNstData, ...
%    a_parkData, a_astData, a_surfData, a_trajData, ...
%    a_timeData, a_cycleNum, a_presOffsetData)
%
% INPUT PARAMETERS :
%   a_miscInfo       : misc info from test and data messages
%   a_profData       : profile data
%   a_profNstData    : NST profile data
%   a_parkData       : parking data
%   a_astData        : AST data
%   a_surfData       : surface data
%   a_trajData       : trajectory data
%   a_timeData       : updated cycle time data structure
%   a_cycleNum       : cycle number
%   a_presOffsetData : updated pressure offset data structure
%   a_decoderId      : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_miscInfo       : misc info from test and data messages
%   o_profData       : profile data
%   o_profNstData    : NST profile data
%   o_parkData       : parking data
%   o_surfData       : surface data
%   o_trajData       : trajectory data
%   o_timeData       : updated cycle time data structure
%   a_presOffsetData : updated pressure offset data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_miscInfo, o_profData, o_profNstData, o_parkData, o_astData, ...
   o_surfData, o_trajData, o_timeData, o_presOffsetData] = ...
   adjust_pres_from_surf_offset_apx_argos(a_miscInfo, a_profData, a_profNstData, ...
   a_parkData, a_astData, a_surfData, a_trajData, ...
   a_timeData, a_cycleNum, a_presOffsetData)

% output parameters initialization
o_miscInfo = a_miscInfo;
o_profData = a_profData;
o_profNstData = a_profNstData;
o_parkData = a_parkData;
o_astData = a_astData;
o_surfData = a_surfData;
o_trajData = a_trajData;
o_presOffsetData = a_presOffsetData;
o_timeData = a_timeData;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% current float WMO number
global g_decArgo_floatNum;

% global measurement codes
global g_MC_MinPresInDriftAtParkSupportMeas;
global g_MC_MaxPresInDriftAtParkSupportMeas;
global g_MC_DriftAtParkMean;
global g_MC_MinPresInDriftAtPark;
global g_MC_MaxPresInDriftAtPark;

% default values
global g_decArgo_presDef;


% select the pressure offset value to use
prevPresOffset = [];
idLastCycleStruct = find([o_presOffsetData.cycleNumAdjPres] < a_cycleNum);
if (~isempty(idLastCycleStruct))
   prevPresOffset = o_presOffsetData.presOffset(idLastCycleStruct(end));
end

presOffset = [];
idCycleStruct = find([o_presOffsetData.cycleNum] == a_cycleNum);
if (~isempty(idCycleStruct))
   cyclePresOffset = o_presOffsetData.cyclePresOffset(idCycleStruct);
   if (abs(cyclePresOffset) <= 20)
      if (~isempty(prevPresOffset))
         if (abs(cyclePresOffset - prevPresOffset) <= 5)
            presOffset = cyclePresOffset;
         end
      else
         presOffset = cyclePresOffset;
      end
   else
      idF = find(ismember(a_cycleNum:-1:a_cycleNum-5, [o_presOffsetData.cycleNum]));
      if ((length(idF) == 6) && ~any(abs(o_presOffsetData.cyclePresOffset(idF)) <= 20))
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

% report information in CSV file
if (~isempty(g_decArgo_outputCsvFileId))
   if (~isempty(presOffset))
      dataStruct = get_apx_misc_data_init_struct('Pres offset', '', '', '');
      dataStruct.label = 'PRES adjustment value';
      dataStruct.value = presOffset;
      dataStruct.format = '%.1f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;
   else
      dataStruct = get_apx_misc_data_init_struct('Pres offset', '', '', '');
      dataStruct.label = 'PRES ADJUSTMENT VALUE CANNOT BE DETERMINED';
      o_miscInfo{end+1} = dataStruct;
   end
end

if (~isempty(presOffset))
   
   % store the adjustment value
   o_presOffsetData.cycleNumAdjPres(end+1) = a_cycleNum;
   o_presOffsetData.presOffset(end+1) = presOffset;
   
   % adjust pressure data
   if (~isempty(g_decArgo_outputCsvFileId))
      labelList = [ ...
         {'Mean pressure of park-level PT samples'}, ...
         {'Pressure associated with Tmin of park-level PT samples'}, ...
         {'Pressure associated with Tmax of park-level PT samples'}, ...
         {'Minimum pressure of park-level PT samples'}, ...
         {'Maximum pressure of park-level PT samples'} ...
         ];
      for idL = 1:length(labelList)
         [idStruct, ~] = find_struct(o_miscInfo, 'label', labelList{idL}, '');
         if (~isempty(idStruct))
            o_miscInfo{idStruct}.valueAdj = o_miscInfo{idStruct}.value - presOffset;
         end
      end
   end
   
   if (~isempty(o_trajData))
      measCodeList = [ ...
         g_MC_DriftAtParkMean ...
         g_MC_MinPresInDriftAtParkSupportMeas ...
         g_MC_MaxPresInDriftAtParkSupportMeas ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         ];
      for idL = 1:length(measCodeList)
         idF = find(([o_trajData.measCode] == measCodeList(idL)) & ...
            strcmp('PRES', {o_trajData.paramName}));
         if (~isempty(idF))
            if (~isempty(o_trajData(idF).value) && (o_trajData(idF).value ~= g_decArgo_presDef))
               o_trajData(idF).valueAdj = o_trajData(idF).value - presOffset;
            end
         end
      end
   end
   
   o_profData = adjust_profile(o_profData, presOffset);
   o_profNstData = adjust_profile(o_profNstData, presOffset);
   o_parkData = adjust_profile(o_parkData, presOffset);
   o_astData = adjust_profile(o_astData, presOffset);
   o_surfData = adjust_profile(o_surfData, presOffset);
   
   if (~isempty(o_timeData))
      idCycleStruct = find([o_timeData.cycleNum] == a_cycleNum);
      if (~isempty(idCycleStruct))
         o_timeData.cycleTime(idCycleStruct).descPresMark = adjust_profile(o_timeData.cycleTime(idCycleStruct).descPresMark, round(presOffset/10)*10);
      end
   end
   
end

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
%   11/02/2015 - RNU - creation
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
