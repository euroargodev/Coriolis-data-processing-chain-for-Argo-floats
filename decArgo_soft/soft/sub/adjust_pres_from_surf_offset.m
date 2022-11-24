% ------------------------------------------------------------------------------
% Compute pressure surface offset to use to adjust pressure measurements
% (according to Argo QC manual). Then, adjust decoded PRES measurements.
%
% SYNTAX :
%  [o_miscInfo, o_profData, o_profNstData, o_parkData, o_astData, ...
%    o_surfData, o_timeData, o_presOffsetData] = ...
%    adjust_pres_from_surf_offset(a_miscInfo, a_profData, a_profNstData, ...
%    a_parkData, a_astData, a_surfData, ...
%    a_timeData, a_cycleNum, a_presOffsetData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_miscInfo       : misc info from test and data messages
%   a_profData       : profile data
%   a_profNstData    : NST profile data
%   a_parkData       : parking data
%   a_astData        : AST data
%   a_surfData       : surface data
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
   o_surfData, o_timeData, o_presOffsetData] = ...
   adjust_pres_from_surf_offset(a_miscInfo, a_profData, a_profNstData, ...
   a_parkData, a_astData, a_surfData, ...
   a_timeData, a_cycleNum, a_presOffsetData, a_decoderId)

% output parameters initialization
o_miscInfo = a_miscInfo;
o_profData = a_profData;
o_profNstData = a_profNstData;
o_parkData = a_parkData;
o_astData = a_astData;
o_surfData = a_surfData;
o_presOffsetData = a_presOffsetData;
o_timeData = a_timeData;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% current float WMO number
global g_decArgo_floatNum;


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
   
   o_profData = adjust_profile(o_profData, presOffset, a_decoderId);
   o_profNstData = adjust_profile(o_profNstData, presOffset, a_decoderId);
   o_parkData = adjust_profile(o_parkData, presOffset, a_decoderId);
   o_astData = adjust_profile(o_astData, presOffset, a_decoderId);
   o_surfData = adjust_profile(o_surfData, presOffset, a_decoderId);
   
   if (~isempty(o_timeData))
      idCycleStruct = find([o_timeData.cycleNum] == a_cycleNum);
      if (~isempty(idCycleStruct))
         o_timeData.cycleTime(idCycleStruct).descPresMark = adjust_profile(o_timeData.cycleTime(idCycleStruct).descPresMark, round(presOffset/10));
      end
   end
   
end

return;

% ------------------------------------------------------------------------------
% Adjust PRES measurements of a given profile.
%
% SYNTAX :
%  [o_profData] = adjust_profile(a_profData, a_presOffset, a_decoderId)
%
% INPUT PARAMETERS :
%   a_profData   : profile data to adjust
%   a_presOffset : pressure offset
%   a_decoderId  : float decoder Id
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
function [o_profData] = adjust_profile(a_profData, a_presOffset, a_decoderId)

% output parameters initialization
o_profData = a_profData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (~isempty(o_profData))
   profParamList = o_profData.paramList;
   profDataAdj = o_profData.data;
   
   idPres = find(strcmp({profParamList.name}, 'PRES') == 1, 1);
   if (~isempty(idPres))
      paramPres = get_netcdf_param_attributes('PRES');
      idNoDef = find(profDataAdj(:, idPres) ~= paramPres.fillValue);
      profDataAdj(idNoDef, idPres) = profDataAdj(idNoDef, idPres) - a_presOffset;
      o_profData.dataAdj = profDataAdj;
      
      idDoxy = find(strcmp({profParamList.name}, 'DOXY') == 1, 1);
      if (~isempty(idDoxy))
         
         % compute DOXY with the adjusted pressure
         switch (a_decoderId)
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case {1006} % 093008
               
               idTemp = find(strcmp({profParamList.name}, 'TEMP') == 1, 1);
               idPsal = find(strcmp({profParamList.name}, 'PSAL') == 1, 1);
               idBPhaseDoxy = find(strcmp({profParamList.name}, 'BPHASE_DOXY') == 1, 1);
               idTempDoxy = find(strcmp({profParamList.name}, 'TEMP_DOXY') == 1, 1);
               if (~isempty(idTemp) && ~isempty(idPsal) && ~isempty(idBPhaseDoxy) && ~isempty(idTempDoxy))
                  
                  paramPres = get_netcdf_param_attributes('PRES');
                  paramTemp = get_netcdf_param_attributes('TEMP');
                  paramSal = get_netcdf_param_attributes('PSAL');
                  paramBPhaseDoxy = get_netcdf_param_attributes('BPHASE_DOXY');
                  paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
                  paramDoxy = get_netcdf_param_attributes('DOXY');
                  
                  profDataAdj(:, idDoxy) = compute_DOXY_1006( ...
                     profDataAdj(:, idPres), ...
                     profDataAdj(:, idTemp), ...
                     profDataAdj(:, idPsal), ...
                     profDataAdj(:, idBPhaseDoxy), ...
                     profDataAdj(:, idTempDoxy), ...
                     paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
                     paramBPhaseDoxy.fillValue, paramTempDoxy.fillValue, paramDoxy.fillValue);
                  
                  o_profData.dataAdj = profDataAdj;
               end
               
            otherwise
               fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in adjust_profile to adjust DOXY for decoderId #%d\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum, ...
                  a_decoderId);
               
         end
      end
      
      idPpoxDoxy = find(strcmp({profParamList.name}, 'PPOX_DOXY') == 1, 1);
      if (~isempty(idPpoxDoxy))
         
         % compute PPOX_DOXY with the adjusted pressure
         switch (a_decoderId)
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case {1006} % 093008
               
               idBPhaseDoxy = find(strcmp({profParamList.name}, 'BPHASE_DOXY') == 1, 1);
               idTempDoxy = find(strcmp({profParamList.name}, 'TEMP_DOXY') == 1, 1);
               if (~isempty(idBPhaseDoxy) && ~isempty(idTempDoxy))
                  
                  paramPres = get_netcdf_param_attributes('PRES');
                  paramBPhaseDoxy = get_netcdf_param_attributes('BPHASE_DOXY');
                  paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
                  paramPpoxDoxy = get_netcdf_param_attributes('PPOX_DOXY');
                  
                  profDataAdj(:, idPpoxDoxy) = compute_PPOX_DOXY_1006( ...
                     profDataAdj(:, idPres), ...
                     profDataAdj(:, idBPhaseDoxy), ...
                     profDataAdj(:, idTempDoxy), ...
                     paramPres.fillValue, paramBPhaseDoxy.fillValue, ...
                     paramTempDoxy.fillValue, paramPpoxDoxy.fillValue);
                  
                  o_profData.dataAdj = profDataAdj;
               end
               
            otherwise
               fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in adjust_profile to adjust DOXY for decoderId #%d\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum, ...
                  a_decoderId);
               
         end
      end
   end
end

return;
