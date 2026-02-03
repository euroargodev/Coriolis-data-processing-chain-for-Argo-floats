% ------------------------------------------------------------------------------
% Finalize data decoded from system_log files
%
% SYNTAX :
% [o_buoyancy, o_cycleTimeData, o_iceDetection, o_techData] = ...
%   finalize_system_log_decoded_data_apx_apf11_ir( ...
%   a_buoyancy, a_cycleTimeData, a_iceDetection, a_techData, ...
%   a_profCtdP, a_profCtdPt, a_profCtdPts, a_profCtdPtsh)
%
% INPUT PARAMETERS :
%   a_buoyancy      : input buoyancy events
%   a_cycleTimeData : input cycle timings data
%   a_iceDetection  : input ICE data
%   a_techData      : input TECH data
%   a_profCtdP      : CTD_P data
%   a_profCtdPt     : CTD_PT data
%   a_profCtdPts    : CTD_PTS data
%   a_profCtdPtsh   : CTD_PTSH data
%
% OUTPUT PARAMETERS :
%   o_buoyancy      : output buoyancy events
%   o_cycleTimeData : output cycle timings data
%   o_iceDetection  : output ICE data
%   o_techData      : output TECH data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/10/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_buoyancy, o_cycleTimeData, o_iceDetection, o_techData] = ...
   finalize_system_log_decoded_data_apx_apf11_ir( ...
   a_buoyancy, a_cycleTimeData, a_iceDetection, a_techData, ...
   a_profCtdP, a_profCtdPt, a_profCtdPts, a_profCtdPtsh)

% output parameters initialization
o_buoyancy = a_buoyancy;
o_cycleTimeData = a_cycleTimeData;
o_iceDetection = a_iceDetection;
o_techData = a_techData;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_presDef;
global g_decArgo_janFirst1950InMatlab;


if (isempty(o_buoyancy) && isempty(o_iceDetection))
   return
end

% create the list of all available PRES vs times
times = [];
pres = [];
if (~isempty(a_profCtdP))
   idPres  = find(strcmp({a_profCtdP.paramList.name}, 'PRES') == 1, 1);
   if (~isempty(idPres) && ~isempty(a_profCtdP.dates))
      times = [times; a_profCtdP.dates];
      pres = [pres; a_profCtdP.data(:, idPres)];
   end
end
if (~isempty(a_profCtdPt))
   idPres  = find(strcmp({a_profCtdPt.paramList.name}, 'PRES') == 1, 1);
   if (~isempty(idPres) && ~isempty(a_profCtdPt.dates))
      times = [times; a_profCtdPt.dates];
      pres = [pres; a_profCtdPt.data(:, idPres)];
   end
end
if (~isempty(a_profCtdPts))
   idPres  = find(strcmp({a_profCtdPts.paramList.name}, 'PRES') == 1, 1);
   if (~isempty(idPres) && ~isempty(a_profCtdPts.dates))
      times = [times; a_profCtdPts.dates];
      pres = [pres; a_profCtdPts.data(:, idPres)];
   end
end
if (~isempty(a_profCtdPtsh))
   idPres  = find(strcmp({a_profCtdPtsh.paramList.name}, 'PRES') == 1, 1);
   if (~isempty(idPres) && ~isempty(a_profCtdPtsh.dates))
      times = [times; a_profCtdPtsh.dates];
      pres = [pres; a_profCtdPtsh.data(:, idPres)];
   end
end

paramJuld = get_netcdf_param_attributes('JULD');
paramPres = get_netcdf_param_attributes('PRES');

idDel = find((times == paramJuld.fillValue) | (pres == paramPres.fillValue));
times(idDel) = [];
pres(idDel) = [];
if (~isempty(times))
   [times, idSort] = sort(times);
   pres = pres(idSort);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (~isempty(o_iceDetection))

   % set AED when profile has been aborted
   if (isempty(o_cycleTimeData.ascentEndDate))
      if (~isempty(o_iceDetection.ascentAbort))
         if (~isempty(times))
            o_iceDetection.ascentPerigeeTime = times(end);
            o_iceDetection.ascentPerigeePres = pres(end);
            if (o_iceDetection.ascentPerigeeTime < o_iceDetection.ascentAbort.abortTypeTime)
               o_iceDetection.ascentPerigeeTime = o_iceDetection.ascentAbort.abortTypeTime;
            end
         end
         o_cycleTimeData.ascentEndDate = o_iceDetection.ascentPerigeeTime;
         o_cycleTimeData.ascentEndDateSci = o_iceDetection.ascentPerigeeTime;
         o_cycleTimeData.ascentEndPresSci = o_iceDetection.ascentPerigeePres;

         % remove "AIR	starting inflation from x.xx dbar" event because the
         % float didn't surface
         o_cycleTimeData.bladderInflationStartDateSys = '';
      end
   end

   % store ICE information in TECH data
   for idT = 1:length(o_iceDetection.thermalDetect)
      if (~isempty(o_iceDetection.thermalDetect(idT).medianTemp))
         dataStruct = get_apx_tech_data_init_struct(1);
         dataStruct.label = 'Median TEMP of mixed layer samples';
         dataStruct.techId = 1005;
         dataStruct.value = num2str(o_iceDetection.thermalDetect(idT).medianTemp);
         dataStruct.cyNum = g_decArgo_cycleNum;
         o_techData{end+1} = dataStruct;
      end
      if (~isempty(o_iceDetection.thermalDetect(idT).sampleTemp))
         dataStruct = get_apx_tech_data_init_struct(1);
         dataStruct.label = 'Number of mixed layer samples';
         dataStruct.techId = 1006;
         dataStruct.value = num2str(length(o_iceDetection.thermalDetect(idT).sampleTemp));
         dataStruct.cyNum = g_decArgo_cycleNum;
         o_techData{end+1} = dataStruct;
      end
      if (~isempty(o_iceDetection.thermalDetect(idT).detectTime))
         dataStruct = get_apx_tech_data_init_struct(1);
         dataStruct.label = 'ISA detection alarm: flag';
         dataStruct.techId = 1009;
         dataStruct.value = num2str(1);
         dataStruct.cyNum = g_decArgo_cycleNum;
         o_techData{end+1} = dataStruct;
      end
      if (~isempty(o_iceDetection.thermalDetect(idT).detectTime))
         dataStruct = get_apx_tech_data_init_struct(1);
         dataStruct.label = 'ISA detection alarm: time';
         dataStruct.techId = 1010;
         dataStruct.value = datestr(o_iceDetection.thermalDetect(idT).detectTime + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
         dataStruct.cyNum = g_decArgo_cycleNum;
         o_techData{end+1} = dataStruct;
      end
      if (~isempty(o_iceDetection.thermalDetect(idT).detectPres))
         dataStruct = get_apx_tech_data_init_struct(1);
         dataStruct.label = 'ISA detection alarm: pres';
         dataStruct.techId = 1011;
         dataStruct.value = num2str(o_iceDetection.thermalDetect(idT).detectPres);
         dataStruct.cyNum = g_decArgo_cycleNum;
         o_techData{end+1} = dataStruct;
      end
   end
   for idB = 1:length(o_iceDetection.breakupDetect)
      if (o_iceDetection.breakupDetect(idB).detectFlag == 1)
         dataStruct = get_apx_tech_data_init_struct(1);
         dataStruct.label = 'Breakup detection alarm: flag';
         dataStruct.techId = 1012;
         dataStruct.value = num2str(1);
         dataStruct.cyNum = g_decArgo_cycleNum;
         o_techData{end+1} = dataStruct;
         if (~isempty(o_iceDetection.breakupDetect(idB).detectTime))
            dataStruct = get_apx_tech_data_init_struct(1);
            dataStruct.label = 'Breakup detection alarm: time';
            dataStruct.techId = 1013;
            dataStruct.value = datestr(o_iceDetection.breakupDetect(idB).detectTime + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            dataStruct.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = dataStruct;
         end
      end
   end
   for idC = 1:length(o_iceDetection.capDetect)
      if (o_iceDetection.capDetect(idC).detectFlag == 1)
         dataStruct = get_apx_tech_data_init_struct(1);
         dataStruct.label = 'Mask_sat detection alarm: flag';
         dataStruct.techId = 1014;
         dataStruct.value = num2str(1);
         dataStruct.cyNum = g_decArgo_cycleNum;
         o_techData{end+1} = dataStruct;
         if (~isempty(o_iceDetection.capDetect(idC).detectTime))
            dataStruct = get_apx_tech_data_init_struct(1);
            dataStruct.label = 'Mask_sat detection alarm: time';
            dataStruct.techId = 1015;
            dataStruct.value = datestr(o_iceDetection.capDetect(idC).detectTime + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            dataStruct.cyNum = g_decArgo_cycleNum;
            o_techData{end+1} = dataStruct;
         end
      end
   end
   if (~isempty(o_iceDetection.ascentAbort))
      dataStruct = get_apx_tech_data_init_struct(1);
      dataStruct.label = 'Ascent abort alarm: flag';
      dataStruct.techId = 1016;
      dataStruct.value = num2str(1);
      dataStruct.cyNum = g_decArgo_cycleNum;
      o_techData{end+1} = dataStruct;
      if (~isempty(o_iceDetection.ascentAbort.abortTypeTime))
         dataStruct = get_apx_tech_data_init_struct(1);
         dataStruct.label = 'Ascent abort alarm: time';
         dataStruct.techId = 1017;
         dataStruct.value = datestr(o_iceDetection.ascentAbort.abortTypeTime + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
         dataStruct.cyNum = g_decArgo_cycleNum;
         o_techData{end+1} = dataStruct;
      end
   end
   if (~isempty(o_iceDetection.ascentPerigeePres))
      dataStruct = get_apx_tech_data_init_struct(1);
      dataStruct.label = 'Pressure when float avoids ice';
      dataStruct.techId = 1007;
      dataStruct.value = num2str(o_iceDetection.ascentPerigeePres);
      dataStruct.cyNum = g_decArgo_cycleNum;
      o_techData{end+1} = dataStruct;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add PRES to buoyancy events
if (any(o_buoyancy(:, 3) == g_decArgo_presDef))
   if (~isempty(times))
      idNoPres = find(o_buoyancy(:, 3) == g_decArgo_presDef);
      o_buoyancy(idNoPres, 3) = interp1(times, pres, o_buoyancy(idNoPres, 1), 'linear');
      idDel = find(isnan(o_buoyancy(:, 3)));
      o_buoyancy(idDel, :) = [];
   end
end

return
