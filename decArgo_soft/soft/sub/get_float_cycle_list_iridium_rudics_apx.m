% ------------------------------------------------------------------------------
% Retrieve the list of existing cycles of an Apex Iridium Rudics float.
%
% SYNTAX :
%  [o_cycleList, o_restricted] = get_float_cycle_list_iridium_rudics_apx(a_floatNum, a_floatRudicsId)
%
% INPUT PARAMETERS :
%   a_floatNum      : float WMO number
%   a_floatRudicsId : float Rudics Id
%
% OUTPUT PARAMETERS :
%   o_cycleList  : existing cycles list
%   o_restricted : restricted cycle list flag
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleList, o_restricted] = get_float_cycle_list_iridium_rudics_apx(a_floatNum, a_floatRudicsId)

% output parameters initialization
o_cycleList = [];
o_restricted = 0;

% configuration values
global g_decArgo_expectedCycleList;
global g_decArgo_iridiumDataDirectory;

% IRIDIUM_DATA sub-directories
global g_decArgo_archiveDirectory;


% search for existing Iridium cycles
iriDirName = [g_decArgo_iridiumDataDirectory '/' sprintf('%04d', a_floatRudicsId) '_' num2str(a_floatNum) '/archive/'];
if ~(exist(iriDirName, 'dir') == 7)
   fprintf('ERROR: Iridium directory not found: %s\n', iriDirName);
   return;
end

existingCycles = [];
fileNames = dir([iriDirName sprintf('%04d', a_floatRudicsId) '*' num2str(a_floatNum) '*']);
for idFile = 1:length(fileNames)
   fileName = fileNames(idFile).name;
   idF1 = strfind(fileName, num2str(a_floatNum));
   idF2 = strfind(fileName, '_');
   idF3 = find(idF2 > idF1);
   cyNum = fileName(idF2(idF3(1))+1:idF2(idF3(2))-1);
   [cyNum, status] = str2num(cyNum);
   if (status)
      existingCycles = [existingCycles cyNum];
   end
end
existingCycles = unique(existingCycles);

% create the output cycle list
if (isstrprop(g_decArgo_expectedCycleList, 'digit'))
   o_cycleList = existingCycles(1:min([length(existingCycles) str2num(g_decArgo_expectedCycleList)]));
else
   [o_cycleList] = create_list(existingCycles, g_decArgo_expectedCycleList);
end

o_cycleList = sort(o_cycleList);

if (length(existingCycles) > length(o_cycleList))
   o_restricted = 1;
end

return;

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
%   07/10/2017 - RNU - creation
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
   return;
end

g_decArgo_expectedCycleList = strtrim(a_expectedCycleList(first+1:last-1));
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
         fprintf('ERROR: Syntax error in EXPECTED_CYCLE_LIST configuration parameter: %s\n', a_expectedCycleList);
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
