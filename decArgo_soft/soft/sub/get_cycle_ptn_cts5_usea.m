% ------------------------------------------------------------------------------
% Retrieve the list of cycle numbers, pattern numbers for CTS5-USEA floats.
%
% SYNTAX :
%  [o_cycleList, o_cyclePatternList] = get_cycle_ptn_cts5_usea
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_cycleList        : list of cycle numbers
%   o_cyclePatternList : list of pattern numbers
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleList, o_cyclePatternList] = get_cycle_ptn_cts5_usea

% output parameters initialization
o_cycleList = [];
o_cyclePatternList = [];

% input data dir
global g_decArgo_archiveDirectory;

% prefix of data file names
global g_decArgo_filePrefixCts5;

% type of files to consider
global g_decArgo_fileTypeListCts5;

% RT processing flag
global g_decArgo_realtimeFlag;

% report information structure
global g_decArgo_reportStruct;

% first float cycle number to consider
global g_decArgo_firstCycleNumFloat;


% collect cycles and patterns to consider
cycleList = [];
cyclePatternList = [];
for idType = 1:size(g_decArgo_fileTypeListCts5, 1)
   files = dir([g_decArgo_archiveDirectory '/' [g_decArgo_filePrefixCts5 g_decArgo_fileTypeListCts5{idType, 2}]]);
   for idFile = 1:length(files)
      fileName = files(idFile).name;
      
      if (g_decArgo_realtimeFlag == 1)
         % store information for the XML report
         g_decArgo_reportStruct.inputFiles = [g_decArgo_reportStruct.inputFiles ...
            {[g_decArgo_archiveDirectory '/' fileName]}];
      end
      
      switch (g_decArgo_fileTypeListCts5{idType, 1})
         case {2}
            % don't consider metadata.xml file because cycle # and pattern # may
            % be wrong (see 6903706)
         case {3}
            % only cycle #, no pattern #
            [val, count, errmsg, nextindex] = sscanf(fileName(1:g_decArgo_fileTypeListCts5{idType, 4}), [g_decArgo_filePrefixCts5 g_decArgo_fileTypeListCts5{idType, 3}]);
            if (isempty(errmsg) && (count == 1))
               cycleList = [cycleList; val(1)];
            end
         otherwise
            % cycle # and pattern #
            [val, count, errmsg, nextindex] = sscanf(fileName(1:g_decArgo_fileTypeListCts5{idType, 4}), [g_decArgo_filePrefixCts5 g_decArgo_fileTypeListCts5{idType, 3}]);
            if (isempty(errmsg) && (count == 2))
               cyclePatternList = [cyclePatternList; val'];
            end
      end
   end
end
cyclePatternList = unique(cyclePatternList, 'rows');
cycleList = [cycleList; cyclePatternList(:, 1)];
cycleList = unique(cycleList);

% THE FOLLOWING CODE IS NOT USED: cycle number prediction cannot be done mainly
% because profile #0 may or may not be a new cycle
% % predict final cycle numbers (i.e. consider delayed cycles)
% % 1- create the map of all possible cycles
% cyclePatternList1 = cyclePatternList;
% while (any(diff(cyclePatternList1(:, 1)) > 1))
%    idMis = find(diff(cyclePatternList1(:, 1)) > 1, 1);
%    startCy = cyclePatternList1(idMis, 1);
%    stopCy = cyclePatternList1(idMis+1, 1);
%    maxPattStopCy = max(cyclePatternList1(cyclePatternList1(:, 1) == stopCy, 2));
%    cyclePatternList02 = nan((stopCy-startCy+1)*maxPattStopCy, 2);
%    cpt = 1;
%    for idC = startCy:stopCy
%       for idP = 0:maxPattStopCy
%          cyclePatternList02(cpt, 1) = idC;
%          cyclePatternList02(cpt, 2) = idP;
%          cpt = cpt + 1;
%       end
%    end
%    cyclePatternList01 = cyclePatternList1(1:idMis, :);
%    cyclePatternList03 = cyclePatternList1(idMis+1:end, :);
%    cyclePatternList1 = cat(1, cyclePatternList01, cyclePatternList02);
%    cyclePatternList1 = cat(1, cyclePatternList1, cyclePatternList03);
%    cyclePatternListTmp = cyclePatternList1(:, 1)*10 + cyclePatternList1(:, 2);
%    [~, idSort] = sort(cyclePatternListTmp);
%    cyclePatternList1 = cyclePatternList1(idSort, :);
%    cyclePatternList1 = unique(cyclePatternList1, 'rows');
% end
% cyclePatternList1 = cat(2, cyclePatternList1, nan(size(cyclePatternList1, 1), 1));
% % 2- set the final cycle number
% idFStart = find((cyclePatternList1(:, 1) == g_decArgo_firstCycleNumFloat) & ...
%    (cyclePatternList1(:, 2) == 0));
% if (~isempty(idFStart))
%    cyclePatternList1(idFStart, 3) = 0;
% else
%    idFStart = find((cyclePatternList1(:, 1) == g_decArgo_firstCycleNumFloat) & ...
%       (cyclePatternList1(:, 2) == 1));
%    cyclePatternList1(idFStart, 3) = 1;
% end
% if (~isempty(idFStart))
%    for idC = idFStart+1:size(cyclePatternList1, 1)
%       if (cyclePatternList1(idC, 2) == 0)
%          % if (cyclePatternList1(idC-1, 2) == 0)
%          %    cyclePatternList1(idC, 3) = cyclePatternList1(idC-1, 3) + 1;
%          % else
%          cyclePatternList1(idC, 3) = cyclePatternList1(idC-1, 3);
%          % end
%       else
%          cyclePatternList1(idC, 3) = cyclePatternList1(idC-1, 3) + 1;
%       end
%    end
% end
% % 3- update the map of received cycles
% cyclePatternList = cat(2, cyclePatternList, nan(size(cyclePatternList, 1), 1));
% for idC = 1:size(cyclePatternList, 1)
%    idF = find((cyclePatternList1(:, 1) == cyclePatternList(idC, 1)) & ...
%       (cyclePatternList1(:, 2) == cyclePatternList(idC, 2)));
%    cyclePatternList(idC, 3) = cyclePatternList1(idF, 3);
% end

o_cycleList = cycleList;
o_cyclePatternList = cyclePatternList;

return
