% ------------------------------------------------------------------------------
% Compute pressure surface offset to use to adjust pressure measurements
% (according to Argo QC manual). Then, adjust decoded PRES measurements.
%
% SYNTAX :
%  [o_miscInfo, o_profData, o_profNstData, o_parkData, o_astData, ...
%    o_surfData, o_timeData, o_presOffsetData] = ...
%    adjust_pres_from_surf_offset_apx_argos(a_miscInfo, a_profData, a_profNstData, ...
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
   adjust_pres_from_surf_offset_apx_argos(a_miscInfo, a_profData, a_profNstData, ...
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
   
   o_profData = adjust_profile(o_profData, presOffset, [], a_decoderId);
   o_profNstData = adjust_profile(o_profNstData, presOffset, [], a_decoderId);
   o_parkData = adjust_profile(o_parkData, presOffset, [], a_decoderId);
   o_astData = adjust_profile(o_astData, presOffset, [], a_decoderId);
   o_surfData = adjust_profile(o_surfData, presOffset, o_profData, a_decoderId);
   
   if (~isempty(o_timeData))
      idCycleStruct = find([o_timeData.cycleNum] == a_cycleNum);
      if (~isempty(idCycleStruct))
         o_timeData.cycleTime(idCycleStruct).descPresMark = adjust_profile(o_timeData.cycleTime(idCycleStruct).descPresMark, round(presOffset/10)*10, [], a_decoderId);
      end
   end
   
end

return;

% ------------------------------------------------------------------------------
% Adjust PRES measurements of a given profile.
%
% SYNTAX :
%  [o_profData] = adjust_profile(a_profData, a_presOffset, a_ctdData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_profData   : profile data to adjust
%   a_presOffset : pressure offset
%   a_ctdData    : CTD profile data (used for surface data when TS are needed
%                  but not available (for BBP700)
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
function [o_profData] = adjust_profile(a_profData, a_presOffset, a_ctdData, a_decoderId)

% output parameters initialization
o_profData = a_profData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


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
         
         % from "Minutes of the 6th BGC-Argo meeting 27, 28 November 2017,
         % Hamburg"
         % http://www.argodatamgt.org/content/download/30911/209493/file/minutes_BGC6_ADMT18.pdf
         % -For a parameter to pass to mode 'A' (i.e., adjusted in real-time), 
         % the calculation for the adjustment must involve the parameter itself 
         % (e.g., with an offset or slope). If a different parameter used for 
         % the calculations is in mode 'A' (e.g., PSAL_ADJUSTED), this does not
         % transitions onto the parameter itself and does not put it into mode 
         % 'A'. The <PARAM> field is always calculated with other parameters in 
         % 'R' mode (e.g., PSAL). <PARAM>_ADJUSTED  is  only  populated  with  a
         % "real"  parameter  adjustment  as  defined above.  A calculation  
         % without  a  "real"  parameter  adjustment  but  involving  other  
         % adjusted  parameters (e.g., PSAL_ADJUSTED) is not performed/not 
         % recorded in the BGC-Argofiles.

         % there is no need to compute derived parameters with PRES_ADJUSTED
         %          idDoxy = find(strcmp({profParamList.name}, 'DOXY') == 1, 1);
         %          if (~isempty(idDoxy))
         %
         %             % compute DOXY with the adjusted pressure
         %             switch (a_decoderId)
         %
         %                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %                case {1006, 1008, 1014, 1016} % 093008, 021208, 082807, 090810
         %
         %                   idTemp = find(strcmp({profParamList.name}, 'TEMP') == 1, 1);
         %                   idPsal = find(strcmp({profParamList.name}, 'PSAL') == 1, 1);
         %                   idBPhaseDoxy = find(strcmp({profParamList.name}, 'BPHASE_DOXY') == 1, 1);
         %                   idTempDoxy = find(strcmp({profParamList.name}, 'TEMP_DOXY') == 1, 1);
         %                   if (~isempty(idTemp) && ~isempty(idPsal) && ~isempty(idBPhaseDoxy) && ~isempty(idTempDoxy))
         %
         %                      paramPres = get_netcdf_param_attributes('PRES');
         %                      paramTemp = get_netcdf_param_attributes('TEMP');
         %                      paramSal = get_netcdf_param_attributes('PSAL');
         %                      paramBPhaseDoxy = get_netcdf_param_attributes('BPHASE_DOXY');
         %                      paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
         %                      paramDoxy = get_netcdf_param_attributes('DOXY');
         %
         %                      profDataAdj(:, idDoxy) = compute_DOXY_1006_1008_1014_1016( ...
         %                         profDataAdj(:, idBPhaseDoxy), ...
         %                         profDataAdj(:, idTempDoxy), ...
         %                         paramBPhaseDoxy.fillValue, ...
         %                         paramTempDoxy.fillValue, ...
         %                         profDataAdj(:, idPres), ...
         %                         profDataAdj(:, idTemp), ...
         %                         profDataAdj(:, idPsal), ...
         %                         paramPres.fillValue, ...
         %                         paramTemp.fillValue, ...
         %                         paramSal.fillValue, ...
         %                         paramDoxy.fillValue);
         %
         %                      o_profData.dataAdj = profDataAdj;
         %                   end
         %
         %                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %                case {1009} % 032213
         %
         %                   idTemp = find(strcmp({profParamList.name}, 'TEMP') == 1, 1);
         %                   idPsal = find(strcmp({profParamList.name}, 'PSAL') == 1, 1);
         %                   idTPhaseDoxy = find(strcmp({profParamList.name}, 'TPHASE_DOXY') == 1, 1);
         %                   idTempDoxy = find(strcmp({profParamList.name}, 'TEMP_DOXY') == 1, 1);
         %                   if (~isempty(idTemp) && ~isempty(idPsal) && ~isempty(idTPhaseDoxy) && ~isempty(idTempDoxy))
         %
         %                      paramPres = get_netcdf_param_attributes('PRES');
         %                      paramTemp = get_netcdf_param_attributes('TEMP');
         %                      paramSal = get_netcdf_param_attributes('PSAL');
         %                      paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
         %                      paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
         %                      paramDoxy = get_netcdf_param_attributes('DOXY');
         %
         %                      profDataAdj(:, idDoxy) = compute_DOXY_1009_1107_1112_1113_1201( ...
         %                         profDataAdj(:, idTPhaseDoxy), ...
         %                         profDataAdj(:, idTempDoxy), ...
         %                         paramTPhaseDoxy.fillValue, ...
         %                         paramTempDoxy.fillValue, ...
         %                         profDataAdj(:, idPres), ...
         %                         profDataAdj(:, idTemp), ...
         %                         profDataAdj(:, idPsal), ...
         %                         paramPres.fillValue, ...
         %                         paramTemp.fillValue, ...
         %                         paramSal.fillValue, ...
         %                         paramDoxy.fillValue);
         %
         %                      o_profData.dataAdj = profDataAdj;
         %                   end
         %
         %                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %                case {1013, 1015} % 071807, 020110
         %
         %                   idTemp = find(strcmp({profParamList.name}, 'TEMP') == 1, 1);
         %                   idPsal = find(strcmp({profParamList.name}, 'PSAL') == 1, 1);
         %                   idFrequencyDoxy = find(strcmp({profParamList.name}, 'FREQUENCY_DOXY') == 1, 1);
         %                   if (~isempty(idTemp) && ~isempty(idPsal) && ~isempty(idFrequencyDoxy))
         %
         %                      paramPres = get_netcdf_param_attributes('PRES');
         %                      paramTemp = get_netcdf_param_attributes('TEMP');
         %                      paramSal = get_netcdf_param_attributes('PSAL');
         %                      paramFrequencyDoxy = get_netcdf_param_attributes('FREQUENCY_DOXY');
         %                      paramDoxy = get_netcdf_param_attributes('DOXY');
         %
         %                      profDataAdj(:, idDoxy) = compute_DOXY_SBE_1013_1015_1101( ...
         %                         profDataAdj(:, idFrequencyDoxy), ...
         %                         paramFrequencyDoxy.fillValue, ...
         %                         profDataAdj(:, idPres), ...
         %                         profDataAdj(:, idTemp), ...
         %                         profDataAdj(:, idPsal), ...
         %                         paramPres.fillValue, ...
         %                         paramTemp.fillValue, ...
         %                         paramSal.fillValue, ...
         %                         paramDoxy.fillValue);
         %
         %                      o_profData.dataAdj = profDataAdj;
         %                   end
         %
         %                otherwise
         %                   fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in adjust_profile to adjust DOXY for decoderId #%d\n', ...
         %                      g_decArgo_floatNum, ...
         %                      g_decArgo_cycleNum, ...
         %                      a_decoderId);
         %
         %             end
         %          end
         %
         %          idPpoxDoxy = find(strcmp({profParamList.name}, 'PPOX_DOXY') == 1, 1);
         %          if (~isempty(idPpoxDoxy))
         %
         %             % compute PPOX_DOXY with the adjusted pressure
         %             switch (a_decoderId)
         %
         %                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %                case {1006, 1008, 1014, 1016} % 093008, 021208, 082807, 090810
         %
         %                   idBPhaseDoxy = find(strcmp({profParamList.name}, 'BPHASE_DOXY') == 1, 1);
         %                   idTempDoxy = find(strcmp({profParamList.name}, 'TEMP_DOXY') == 1, 1);
         %                   if (~isempty(idBPhaseDoxy) && ~isempty(idTempDoxy))
         %
         %                      paramPres = get_netcdf_param_attributes('PRES');
         %                      paramBPhaseDoxy = get_netcdf_param_attributes('BPHASE_DOXY');
         %                      paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
         %                      paramPpoxDoxy = get_netcdf_param_attributes('PPOX_DOXY');
         %
         %                      profDataAdj(:, idPpoxDoxy) = compute_PPOX_DOXY_1006_1008_1014_1016( ...
         %                         profDataAdj(:, idBPhaseDoxy), ...
         %                         profDataAdj(:, idTempDoxy), ...
         %                         paramBPhaseDoxy.fillValue, ...
         %                         paramTempDoxy.fillValue, ...
         %                         profDataAdj(:, idPres), ...
         %                         paramPres.fillValue, ...
         %                         paramPpoxDoxy.fillValue);
         %
         %                      o_profData.dataAdj = profDataAdj;
         %                   end
         %
         %                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %                case {1009} % 032213
         %
         %                   idTPhaseDoxy = find(strcmp({profParamList.name}, 'TPHASE_DOXY') == 1, 1);
         %                   idTempDoxy = find(strcmp({profParamList.name}, 'TEMP_DOXY') == 1, 1);
         %                   if (~isempty(idTPhaseDoxy) && ~isempty(idTempDoxy))
         %
         %                      paramPres = get_netcdf_param_attributes('PRES');
         %                      paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
         %                      paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
         %                      paramPpoxDoxy = get_netcdf_param_attributes('PPOX_DOXY');
         %
         %                      profDataAdj(:, idPpoxDoxy) = compute_PPOX_DOXY_1009_1112_1201( ...
         %                         profDataAdj(:, idTPhaseDoxy), ...
         %                         profDataAdj(:, idTempDoxy), ...
         %                         paramTPhaseDoxy.fillValue, ...
         %                         paramTempDoxy.fillValue, ...
         %                         profDataAdj(:, idPres), ...
         %                         paramPres.fillValue, ...
         %                         paramPpoxDoxy.fillValue);
         %
         %                      o_profData.dataAdj = profDataAdj;
         %                   end
         %
         %                otherwise
         %                   fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in adjust_profile to adjust DOXY for decoderId #%d\n', ...
         %                      g_decArgo_floatNum, ...
         %                      g_decArgo_cycleNum, ...
         %                      a_decoderId);
         %
         %             end
         %          end
         %
         %          idBbp700 = find(strcmp({profParamList.name}, 'BBP700') == 1, 1);
         %          if (~isempty(idBbp700))
         %
         %             idTemp = find(strcmp({profParamList.name}, 'TEMP') == 1, 1);
         %             idPsal = find(strcmp({profParamList.name}, 'PSAL') == 1, 1);
         %             idBetaBackscattering700 = find(strcmp({profParamList.name}, 'BETA_BACKSCATTERING700') == 1, 1);
         %             ptsDataAdj = [];
         %             if (~isempty(idTemp) && ~isempty(idPsal) && ~isempty(idBetaBackscattering700))
         %                ptsDataAdj = profDataAdj(:, [idPres idTemp idPsal]);
         %             else
         %                if (~isempty(a_ctdData))
         %                   idPres = find(strcmp({profParamList.name}, 'PRES') == 1, 1);
         %                   idTemp = find(strcmp({a_ctdData.paramList.name}, 'TEMP') == 1, 1);
         %                   idPsal = find(strcmp({a_ctdData.paramList.name}, 'PSAL') == 1, 1);
         %
         %                   if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal))
         %
         %                      paramTemp = get_netcdf_param_attributes('TEMP');
         %                      paramSal = get_netcdf_param_attributes('PSAL');
         %
         %                      idLev = find((a_ctdData.dataAdj(:, idTemp) ~= paramTemp.fillValue) & ...
         %                         (a_ctdData.dataAdj(:, idPsal) ~= paramSal.fillValue));
         %                      if (~isempty(idLev))
         %                         idLev = idLev(end);
         %                         ptsDataAdj = [profDataAdj(:, idPres) ...
         %                            ones(size(profDataAdj, 1), 1)*a_ctdData.dataAdj(idLev, idTemp) ...
         %                            ones(size(profDataAdj, 1), 1)*a_ctdData.dataAdj(idLev, idPsal)];
         %                      end
         %                   end
         %                end
         %             end
         %
         %             if (~isempty(ptsDataAdj))
         %
         %                paramPres = get_netcdf_param_attributes('PRES');
         %                paramTemp = get_netcdf_param_attributes('TEMP');
         %                paramSal = get_netcdf_param_attributes('PSAL');
         %                paramBetaBackscattering700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');
         %                paramBbp700 = get_netcdf_param_attributes('BBP700');
         %
         %                profDataAdj(:, idBbp700) = compute_BBP700_301_1015_1101_1105_1110_1111_1112( ...
         %                   profDataAdj(:, idBetaBackscattering700), ...
         %                   paramBetaBackscattering700.fillValue, ...
         %                   paramBbp700.fillValue, ...
         %                   ptsDataAdj, ...
         %                   paramPres.fillValue, ...
         %                   paramTemp.fillValue, ...
         %                   paramSal.fillValue);
         %
         %                o_profData.dataAdj = profDataAdj;
         %
         %             end
         %          end
         
         % but we prefer to set fillValue for derived parameters
         idDoxy = find(strcmp({profParamList.name}, 'DOXY') == 1, 1);
         if (~isempty(idDoxy))
            
            paramDoxy = get_netcdf_param_attributes('DOXY');
            o_profData.dataAdj(:, idDoxy) = ones(size(o_profData.dataAdj, 1), 1)*paramDoxy.fillValue;
         end
         
         idPpoxDoxy = find(strcmp({profParamList.name}, 'PPOX_DOXY') == 1, 1);
         if (~isempty(idPpoxDoxy))
            
            paramPpoxDoxy = get_netcdf_param_attributes('PPOX_DOXY');
            o_profData.dataAdj(:, idPpoxDoxy) = ones(size(o_profData.dataAdj, 1), 1)*paramPpoxDoxy.fillValue;
         end
         
         idBbp700 = find(strcmp({profParamList.name}, 'BBP700') == 1, 1);
         if (~isempty(idBbp700))
            
            paramBbp700 = get_netcdf_param_attributes('BBP700');
            o_profData.dataAdj(:, idBbp700) = ones(size(o_profData.dataAdj, 1), 1)*paramBbp700.fillValue;
         end
      end
   end
end

return;
