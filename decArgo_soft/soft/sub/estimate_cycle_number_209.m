% ------------------------------------------------------------------------------
% Estimate the cycle number (used when we didn't receive the technical message).
%
% SYNTAX :
%  [o_cycleNumber] = estimate_cycle_number_209(a_dataCTDX, a_cycleNumberPrev, a_refDay)
%
% INPUT PARAMETERS :
%   a_dataCTDX        : decoded data of the CTD/CTDO sensor
%   a_cycleNumberPrev : number of the previous cycle
%   a_refDay          : reference day (day of the first descent)
%
% OUTPUT PARAMETERS :
%   o_cycleNumber : estimated cycle numver
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/05/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleNumber] = estimate_cycle_number_209(a_dataCTDX, a_cycleNumberPrev, a_refDay)

% output parameters initialization
o_cycleNumber = a_cycleNumberPrev + 1;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;


if (isempty(a_dataCTDX))
   return;
end

% retrieve the cycle time from the configuration (the processing is done under
% the assumption that this configuration parameter has not been modified)
[configNames, configValues] = get_float_config_ir_sbd(a_cycleNumberPrev);
cycleTimeDays = get_config_value('CONFIG_PM01', configNames, configValues);
if (isempty(cycleTimeDays))
   return;
end

% retrieve the last message time of the previous cycle
[~, lastMsgDateOfPrevCycle] = ...
   compute_first_last_msg_time_from_iridium_mail(g_decArgo_iridiumMailData, a_cycleNumberPrev);

% estimate cycle number
optodeType = unique(a_dataCTDX(:, end));
switch (optodeType)
   case 2
      % CTD only
      descTypeNum = 1;
      driftTypeNum = 2;
      ascTypeNum = 3;
   case 1
      % CTD + Aanderaa 4330
      descTypeNum = 8;
      driftTypeNum = 9;
      ascTypeNum = 10;
   case 4
      % CTD + SBE 63
      descTypeNum = 11;
      driftTypeNum = 12;
      ascTypeNum = 13;
   case 5
      % CTD + Aanderaa 4330 + SBE 63
      descTypeNum = 14;
      driftTypeNum = 15;
      ascTypeNum = 16;
   otherwise
      fprintf('WARNING: Nothing done yet for optode type #%d\n', ...
         optodeType);
end

idAsc = find(a_dataCTDX(:, 1) == ascTypeNum);
if (~isempty(idAsc))
   % from ascent dates
   dates = [];
   for idP = 1:length(idAsc)
      data = a_dataCTDX(idAsc(idP), :);
      dates = [dates; data(2)];
   end
   lastDate  = max(dates) + a_refDay;
   nbCycles = round((lastDate-lastMsgDateOfPrevCycle)/cycleTimeDays);
   o_cycleNumber = a_cycleNumberPrev + nbCycles;
else
   idDesc = find(a_dataCTDX(:, 1) == descTypeNum);
   if (~isempty(idDesc))
      % from descent dates
      dates = [];
      for idP = 1:length(idDesc)
         data = a_dataCTDX(idDesc(idP), :);
         dates = [dates; data(2)];
      end
      firstDate  = min(dates) + a_refDay;
      nbCycles = round((firstDate-lastMsgDateOfPrevCycle)/cycleTimeDays) + 1;
      o_cycleNumber = a_cycleNumberPrev + nbCycles;
   else
      idDrift = find(a_dataCTDX(:, 1) == driftTypeNum);
      if (~isempty(idDrift))
         % from drift dates
         dates = [];
         for idP = 1:length(idDrift)
            data = a_dataCTDX(idDrift(idP), :);
            dates = [dates; data(2)];
         end
         lastDate  = max(dates) + a_refDay;
         nbCycles = round((lastDate-lastMsgDateOfPrevCycle)/cycleTimeDays);
         o_cycleNumber = a_cycleNumberPrev + nbCycles;
      end
   end
end

return;
