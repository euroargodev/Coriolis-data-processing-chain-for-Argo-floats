% ------------------------------------------------------------------------------
% Check for existing cycle Iridium data files within a given list of expected
% cycles.
%
% SYNTAX :
%  [o_cycleList] = get_float_cycle_list_iridium_rudics(a_floatNum, a_floatLoginName)
%
% INPUT PARAMETERS :
%   a_floatNum       : float WMO number
%   a_floatLoginName : float login name
%
% OUTPUT PARAMETERS :
%   o_cycleList : existing cycle Iridium data files
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/27/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleList] = get_float_cycle_list_iridium_rudics(a_floatNum, a_floatLoginName)

% configuration values
global g_decArgo_iridiumDataDirectory;
global g_decArgo_expectedCycleList;

% mode processing flags
global g_decArgo_realtimeFlag;

% output parameters initialization
o_cycleList = [];

% search for existing Iridium cycles
iriDirName = g_decArgo_iridiumDataDirectory;
if ~(exist(iriDirName, 'dir') == 7)
   fprintf('ERROR: Iridium directory not found: %s\n', iriDirName);
   return;
end

existingCycles = [];
if (g_decArgo_realtimeFlag == 0)
   sbdFiles = dir([iriDirName '/' a_floatLoginName '/archive/' sprintf('*_%s_*.b*.sbd', a_floatLoginName)]);
   for idFile = 1:length(sbdFiles)
      sbdFileName = sbdFiles(idFile).name;
      if (~isempty(strfind(sbdFileName, '.b64.sbd')))
         [id, count, errmsg, nextIndex] = sscanf(sbdFileName, '%d_%d_%10c_%d.b64.sbd');
      else
         [id, count, errmsg, nextIndex] = sscanf(sbdFileName, '%d_%d_%10c_%d.bin.sbd');
      end
      if (isempty(errmsg))
         existingCycles = [existingCycles; id(end)];
      end
   end
else
   sbdFiles = dir([iriDirName '/' a_floatLoginName '/spool/' sprintf('*_%s_*.b*.sbd', a_floatLoginName)]);
   for idFile = 1:length(sbdFiles)
      sbdFileName = sbdFiles(idFile).name;
      [id, count, errmsg, nextIndex] = sscanf(sbdFileName, '%d_%d_%10c_%d.b*.sbd');
      if (isempty(errmsg))
         existingCycles = [existingCycles; id(end)];
      end
   end
   sbdFiles = dir([iriDirName '/' a_floatLoginName '/buff/' sprintf('*_%s_*.b*.sbd', a_floatLoginName)]);
   for idFile = 1:length(sbdFiles)
      sbdFileName = sbdFiles(idFile).name;
      [id, count, errmsg, nextIndex] = sscanf(sbdFileName, '%d_%d_%10c_%d.b*.sbd');
      if (isempty(errmsg))
         existingCycles = [existingCycles; id(end)];
      end
   end
end
existingCycles = sort(unique(existingCycles));

% create the output cycle list
if (isstrprop(g_decArgo_expectedCycleList, 'digit'))
   o_cycleList = existingCycles(1:min([length(existingCycles) str2num(g_decArgo_expectedCycleList)]));
else
   [o_cycleList] = create_list(existingCycles, g_decArgo_expectedCycleList);
end

o_cycleList = sort(o_cycleList);

return;

% ------------------------------------------------------------------------------
% Create cycle list from existing and expected cycle list.
%
% SYNTAX :
%  [o_outputList] = create_list(a_existingCycleList, a_g_decArgo_expectedCycleList)
%
% INPUT PARAMETERS :
%   a_existingCycleList : list of existing cycles
%   a_g_decArgo_expectedCycleList : (coded) list of expected cycles
%
% OUTPUT PARAMETERS :
%   o_outputList : list of cycles to decode
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_outputList] = create_list(a_existingCycleList, a_g_decArgo_expectedCycleList)

% output parameters initialization
o_outputList = [];

% expected cycle list interpretation
% [n1, n2, n3] => list of cycles
% [~] => all cycles
% [n1~n2] => from cycle #n1 to cycle #n2
% [~n2] => all cycles until cycle #n2
% [n1~] => all cycles from cycle #n1

first = strfind(a_g_decArgo_expectedCycleList, '[');
last = strfind(a_g_decArgo_expectedCycleList, ']');
if (isempty(first) || isempty(last))
   fprintf('ERROR: Syntax error in EXPECTED_CYCLE_LIST configuration parameter: %s\n', a_g_decArgo_expectedCycleList);
   return;
end

g_decArgo_expectedCycleList = strtrim(a_g_decArgo_expectedCycleList(first+1:last-1));
remain = g_decArgo_expectedCycleList;
while (1)
   [info, remain] = strtok(remain, ',');
   if (isempty(info))
      break;
   end
   info = strtrim(info);
   if (isstrprop(info, 'digit'))
      % [n1, n2, n3] => list of cycles
      if (ismember(str2num(info), a_existingCycleList))
         o_outputList = [o_outputList; str2num(info)];
      end
   else
      tildePos = strfind(info, '~');
      if (isempty(tildePos))
         fprintf('ERROR: Syntax error in EXPECTED_CYCLE_LIST configuration parameter: %s\n', a_g_decArgo_expectedCycleList);
         o_outputList = [];
         return;
      end
      if (length(info) == 1)
         % [~] => all cycles
         o_outputList = a_existingCycleList;
      elseif (tildePos == 1)
         % [~n2] => all cycles until cycle #n2
         lastCycle = str2num(info(tildePos+1:end));
         o_outputList = [o_outputList; ...
            a_existingCycleList(find(a_existingCycleList <= lastCycle))];
      elseif (tildePos == length(info))
         % [n1~] => all cycles from cycle #n1
         firstCycle = str2num(info(1:tildePos-1));
         o_outputList = [o_outputList; ...
            a_existingCycleList(find(a_existingCycleList >= firstCycle))];
      else
         % [n1~n2] => from cycle #n1 to cycle #n2
         firstCycle = str2num(info(1:tildePos-1));
         lastCycle = str2num(info(tildePos+1:end));
         o_outputList = [o_outputList; ...
            a_existingCycleList(find((a_existingCycleList >= firstCycle) & ...
            (a_existingCycleList <= lastCycle)))];
      end
   end
end

o_outputList = sort(unique(o_outputList));

return;
