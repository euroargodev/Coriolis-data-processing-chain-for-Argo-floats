% ------------------------------------------------------------------------------
% Check for existing cycle Iridium data files within a given list of expected
% cycles.
%
% SYNTAX :
%  [o_fileList] = ...
%    get_float_cycle_list_iridium_sbd(a_floatNum, a_floatImei, a_floatLaunchDate)
%
% INPUT PARAMETERS :
%   a_floatNum        : float WMO number
%   a_floatImei       : float IMEI
%   a_floatLaunchDate : float launch date
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
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_fileList] = ...
   get_float_cycle_list_iridium_sbd(a_floatNum, a_floatImei, a_floatLaunchDate)

% configuration values
global g_decArgo_iridiumDataDirectory;
global g_decArgo_expectedCycleList;

% RT processing flag
global g_decArgo_realtimeFlag;

% output parameters initialization
o_fileList = [];

% search for existing Iridium cycles
iriDirName = g_decArgo_iridiumDataDirectory;
if ~(exist(iriDirName, 'dir') == 7)
   fprintf('ERROR: Iridium directory not found: %s\n', iriDirName);
   return;
end

existingCycles = [];
if (g_decArgo_realtimeFlag == 0)
   [fileName, fileCycle, ~, ~] = get_dir_files_info_ir_sbd( ...
      [iriDirName '/' num2str(a_floatImei) '_' num2str(a_floatNum) '/archive/'], a_floatImei, 'txt', a_floatLaunchDate);
   existingCycles = sort(unique(fileCycle));
   
   % create the output cycle list
   if (isstrprop(g_decArgo_expectedCycleList, 'digit'))
      cycleList = existingCycles(1:min([length(existingCycles) str2num(g_decArgo_expectedCycleList)]));
   else
      cycleList = create_list(existingCycles, g_decArgo_expectedCycleList);
   end
   
   cycleList = sort(cycleList);
   o_fileList = fileName(find(ismember(fileCycle, cycleList)));
else
   existingCycles = 0:9999;
   
   % create the output cycle list
   if (isstrprop(g_decArgo_expectedCycleList, 'digit'))
      cycleList = existingCycles(1:min([length(existingCycles) str2num(g_decArgo_expectedCycleList)]));
   else
      cycleList = create_list(existingCycles, g_decArgo_expectedCycleList);
   end
   
   o_fileList = cycleList;
end

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
