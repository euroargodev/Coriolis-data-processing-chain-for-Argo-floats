% ------------------------------------------------------------------------------
% Compute the main dates of this Arvor float cycle.
%
% SYNTAX :
%  [o_cycleStartDate, ...
%    o_descentStartDate, ...
%    o_descentEndDate, ...
%    o_ascentStartDate, ...
%    o_ascentEndDate, ...
%    o_transStartDate, ...
%    o_gpsDates] = ...
%    compute_prv_dates_219_220(a_tabTech, a_deepCycle, ...
%    a_lastMsgDateOfPrevCycle, a_launchDate)
%
% INPUT PARAMETERS :
%   a_tabTech                : decoded technical data
%   a_deepCycle              : deep cycle flag
%   a_lastMsgDateOfPrevCycle : last time of the messages received during the
%                              previous cycle
%   a_launchDate             : launch date
%
% OUTPUT PARAMETERS :
%   o_cycleStartDate   : cycle start date
%   o_descentStartDate : descent to park start date
%   o_descentEndDate   : descent to park end date
%   o_ascentStartDate  : ascent start date
%   o_ascentEndDate    : ascent end date
%   o_transStartDate   : transmission start date
%   o_gpsDates         : dates associated to the GPS location
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/17/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleStartDate, ...
   o_descentStartDate, ...
   o_descentEndDate, ...
   o_ascentStartDate, ...
   o_ascentEndDate, ...
   o_transStartDate, ...
   o_gpsDates] = ...
   compute_prv_dates_219_220(a_tabTech, a_deepCycle, ...
   a_lastMsgDateOfPrevCycle, a_launchDate)

% output parameters initialization
o_cycleStartDate = [];
o_descentStartDate = [];
o_descentEndDate = [];
o_ascentStartDate = [];
o_ascentEndDate = [];
o_transStartDate = [];
o_gpsDates = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_dateDef;


if (isempty(a_tabTech))
   return
end

% technical message
idF = find((a_tabTech(:, 1) == 0) & (a_tabTech(:, end-4) == 1));
if (length(idF) > 1)
   fprintf('ERROR: Float #%d cycle #%d: BUFFER anomaly (%d tech message in the buffer)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      length(idF));
elseif (length(idF) == 1)
   
   id = idF(1);
         
   if (a_lastMsgDateOfPrevCycle ~= g_decArgo_dateDef)
      
      o_cycleStartDate = fix(a_lastMsgDateOfPrevCycle) + a_tabTech(id, 2)/1440;
      
      if (o_cycleStartDate < (floor(a_lastMsgDateOfPrevCycle*1440)/1440))
         o_cycleStartDate = o_cycleStartDate + round((floor(a_lastMsgDateOfPrevCycle*1440)/1440)-o_cycleStartDate);
         % we cannot do o_cycleStartDate = o_cycleStartDate + 1 because clock
         % drift is not zero for some floats (Ex: 2902127) and cycle start
         % date can be < last msg date of previous floats
      end
   elseif (g_decArgo_cycleNum == 1)
      
      o_cycleStartDate = fix(a_launchDate) + a_tabTech(id, 2)/1440;
      if (o_cycleStartDate < (floor(a_launchDate*1440)/1440))
         o_cycleStartDate = o_cycleStartDate + round((floor(a_launchDate*1440)/1440)-o_cycleStartDate);
      end
   end
   
   if (~isempty(o_cycleStartDate))
      
      o_descentStartDate = fix(o_cycleStartDate) + a_tabTech(id, 3)/1440;
      if (o_descentStartDate < o_cycleStartDate)
         o_descentStartDate = o_descentStartDate + 1;
      end
      
      o_descentEndDate = fix(o_descentStartDate) + a_tabTech(id, 4)/1440;
      if (o_descentEndDate < o_descentStartDate)
         o_descentEndDate = o_descentEndDate + 1;
      end
      
      o_gpsDates = a_tabTech(id, end-3);
      
      o_transStartDate = fix(o_gpsDates) +  a_tabTech(id, 7)/1440;
      if (o_transStartDate > o_gpsDates)
         o_transStartDate = o_transStartDate - 1;
      end
      
      o_ascentEndDate = fix(o_transStartDate) +  a_tabTech(id, 6)/1440;
      if (o_ascentEndDate > o_transStartDate)
         o_ascentEndDate = o_transStartDate - 1;
      end
      
      o_ascentStartDate = fix(o_ascentEndDate) +  a_tabTech(id, 5)/1440;
      if (o_ascentStartDate > o_ascentEndDate)
         o_ascentStartDate = o_ascentStartDate - 1;
      end
   end
end

idF = find((a_tabTech(:, 1) == 0) & (a_tabTech(:, end-4) == 0));
for idT = 1:length(idF)
   o_gpsDates = [o_gpsDates; a_tabTech(idF(idT), end-3)];
end

print = 0;
if (print == 1)
   
   fprintf('Float #%d cycle #%d:\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   if (~isempty(o_cycleStartDate))
      fprintf('CYCLE START DATE        : %s\n', ...
         julian_2_gregorian_dec_argo(o_cycleStartDate));
   else
      fprintf('CYCLE START DATE        : UNDEF\n');
   end
   if (~isempty(o_descentStartDate))
      fprintf('DESCENT START DATE      : %s\n', ...
         julian_2_gregorian_dec_argo(o_descentStartDate));
   else
      fprintf('DESCENT START DATE      : UNDEF\n');
   end
   if (~isempty(o_descentEndDate))
      fprintf('DESCENT END DATE        : %s\n', ...
         julian_2_gregorian_dec_argo(o_descentEndDate));
   else
      fprintf('DESCENT END DATE        : UNDEF\n');
   end
   if (~isempty(o_ascentStartDate))
      fprintf('ASCENT START DATE       : %s\n', ...
         julian_2_gregorian_dec_argo(o_ascentStartDate));
   else
      fprintf('ASCENT START DATE       : UNDEF\n');
   end
   if (~isempty(o_ascentEndDate))
      fprintf('ASCENT END DATE         : %s\n', ...
         julian_2_gregorian_dec_argo(o_ascentEndDate));
   else
      fprintf('ASCENT END DATE         : UNDEF\n');
   end
   if (~isempty(o_transStartDate))
      fprintf('TRANSMISSION START DATE : %s\n', ...
         julian_2_gregorian_dec_argo(o_transStartDate));
   else
      fprintf('TRANSMISSION START DATE : UNDEF\n');
   end
   if (~isempty(o_gpsDates))
      fprintf('GPS DATE                : %s\n', ...
         julian_2_gregorian_dec_argo(o_gpsDates));
   else
      fprintf('GPS DATE                : UNDEF\n');
   end
end

return
