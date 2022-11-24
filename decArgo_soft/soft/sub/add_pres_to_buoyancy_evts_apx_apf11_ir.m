% ------------------------------------------------------------------------------
% Add pressure information to buoyancy events (from PRES vs time
% measurements).
%
% SYNTAX :
%  [o_buoyancy, o_cycleTimeData] = add_pres_to_buoyancy_evts_apx_apf11_ir( ...
%    a_buoyancy, a_profCtdP, a_profCtdPt, a_profCtdPts, a_profCtdPtsh, a_cycleTimeData)
%
% INPUT PARAMETERS :
%   a_buoyancy      : input bupyancy events
%   a_profCtdP      : input CTD_P data
%   a_profCtdPt     : input CTD_PT data
%   a_profCtdPts    : input CTD_PTS data
%   a_profCtdPtsh   : input CTD_PTSH data
%   a_cycleTimeData : input cycle timings data
%
% OUTPUT PARAMETERS :
%   o_buoyancy      : updated buoyancy events
%   o_cycleTimeData : cycle timings data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/27/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_buoyancy, o_cycleTimeData] = add_pres_to_buoyancy_evts_apx_apf11_ir( ...
   a_buoyancy, a_profCtdP, a_profCtdPt, a_profCtdPts, a_profCtdPtsh, a_cycleTimeData)

% output parameters initialization
o_buoyancy = a_buoyancy;
o_cycleTimeData = a_cycleTimeData;

% default values
global g_decArgo_presDef;


% add PRES to AED (when recovered from system_log file i.e. when Ice has
% been detected)
if (isempty(o_cycleTimeData.ascentEndDateSci) && ~isempty(o_cycleTimeData.ascentEndDate))
   if (~isempty(a_profCtdP))
      refDateStr = julian_2_gregorian_dec_argo(o_cycleTimeData.ascentEndDate);
      idF1 = find(a_profCtdP.dates >= o_cycleTimeData.ascentEndDate, 1, 'first');
      idF2 = find(a_profCtdP.dates <= o_cycleTimeData.ascentEndDate, 1, 'last');
      if (strcmp(julian_2_gregorian_dec_argo(a_profCtdP.dates(idF1)), refDateStr))
         o_cycleTimeData.ascentEndPresSci = a_profCtdP.data(idF1);
      elseif (strcmp(julian_2_gregorian_dec_argo(a_profCtdP.dates(idF2)), refDateStr))
         o_cycleTimeData.ascentEndPresSci = a_profCtdP.data(idF2);
      else
         o_cycleTimeData.ascentEndPresSci = (a_profCtdP.data(idF1)+a_profCtdP.data(idF2))/2;
      end
   end
end

if (isempty(o_buoyancy))
   return
end

if (~any(o_buoyancy(:, 3) == g_decArgo_presDef))
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

% add PRES to buoyancy events
if (~isempty(times))
   idNoPres = find(o_buoyancy(:, 3) == g_decArgo_presDef);
   o_buoyancy(idNoPres, 3) = interp1(times, pres, o_buoyancy(idNoPres, 1), 'linear');
   idDel = find(isnan(o_buoyancy(:, 3)));
   o_buoyancy(idDel, :) = [];
end

return
