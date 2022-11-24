% ------------------------------------------------------------------------------
% Get the list of cycle to be processed for a CTS5 float.
%
% SYNTAX :
%  [o_cycleList] = get_float_cycle_list_iridium_rudics_cts5(a_floatNum, a_floatLoginName)
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
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleList] = get_float_cycle_list_iridium_rudics_cts5(a_floatNum, a_floatLoginName)

% output parameters initialization
o_cycleList = [];

% configuration values
global g_decArgo_iridiumDataDirectory;
global g_decArgo_expectedCycleList;

% prefix of data file names
global g_decArgo_filePrefixCts5;

% mode processing flags
global g_decArgo_realtimeFlag;

% list of CTS5 files
global g_decArgo_provorCts5UseaFileTypeList;


if (g_decArgo_realtimeFlag == 1)
   return
end

% search for existing Iridium cycles
iriDirName = g_decArgo_iridiumDataDirectory;
if ~(exist(iriDirName, 'dir') == 7)
   fprintf('ERROR: Iridium directory not found: %s\n', iriDirName);
   return
end

% set file prefix
fileDir = [iriDirName '/' a_floatLoginName '_' num2str(a_floatNum) '/archive/'];
g_decArgo_filePrefixCts5 = get_file_prefix_cts5(fileDir);

% type of files to consider
fileTypeList = g_decArgo_provorCts5UseaFileTypeList;

fileDir = [iriDirName '/' a_floatLoginName '_' num2str(a_floatNum) '/archive/'];
existingCycles = [];
for idType = 1:length(fileTypeList)
   files = dir([fileDir [g_decArgo_filePrefixCts5 '_' fileTypeList{idType}]]);
   for idFile = 1:length(files)
      fileName = files(idFile).name;
      existingCycles(end+1) = str2num(fileName(6:8));
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

return

% ------------------------------------------------------------------------------
% Create cycle list from existing and expected cycle list.
%
% SYNTAX :
%  [o_outputList] = create_list(a_existingCycleList, a_expectedCycleList)
%
% INPUT PARAMETERS :
%   a_existingCycleList : list of existing cycles
%   a_expectedCycleList : (coded) list of expected cycles
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
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_outputList] = create_list(a_existingCycleList, a_expectedCycleList)

% output parameters initialization
o_outputList = [];

% expected cycle list interpretation
% [n1, n2, n3] => list of cycles
% [~] => all cycles
% [n1~n2] => from cycle #n1 to cycle #n2
% [~n2] => all cycles until cycle #n2
% [n1~] => all cycles from cycle #n1

first = strfind(a_expectedCycleList, '[');
last = strfind(a_expectedCycleList, ']');
if (isempty(first) || isempty(last))
   fprintf('ERROR: Syntax error in EXPECTED_CYCLE_LIST configuration parameter: %s\n', a_expectedCycleList);
   return
end

g_decArgo_expectedCycleList = strtrim(a_expectedCycleList(first+1:last-1));
remain = g_decArgo_expectedCycleList;
while (1)
   [info, remain] = strtok(remain, ',');
   if (isempty(info))
      break
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
         fprintf('ERROR: Syntax error in EXPECTED_CYCLE_LIST configuration parameter: %s\n', a_expectedCycleList);
         o_outputList = [];
         return
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

return
