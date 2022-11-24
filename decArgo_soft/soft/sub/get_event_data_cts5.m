% ------------------------------------------------------------------------------
% Decode and store CTS5 event data.
%
% SYNTAX :
%  [o_ok] = get_event_data_cts5(a_cyclePatternNumFloat, a_launchDate, a_decoderId)
%
% INPUT PARAMETERS :
%   a_cyclePatternNumFloat : cycle and pattern numbers
%   a_launchDate           : launch date
%   a_decoderId            : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_ok : decoding report flag (1 if ok, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = get_event_data_cts5(a_cyclePatternNumFloat, a_launchDate, a_decoderId)

% output parameters initialization
o_ok = 0;

% input data dir
global g_decArgo_archiveDirectory;

% prefix of data file names
global g_decArgo_filePrefixCts5;

% number of the first cycle to process
global g_decArgo_firstCycleNumCts5;

% variable to store all useful event data
global g_decArgo_eventData;

% cycle numbers missing in event data
global g_decArgo_eventDataUnseenCycleNum;
g_decArgo_eventDataUnseenCycleNum = [];

% clock offset management
global g_decArgo_clockOffset;
g_decArgo_clockOffset = get_clock_offset_cts5_init_struct;

% get system file names
eventFiles = manage_split_files({g_decArgo_archiveDirectory}, ...
   {[g_decArgo_filePrefixCts5 '_system_*.hex']}, a_decoderId);

% sort the files
[~, idSort] = sort(eventFiles(:, 1));
eventFiles = eventFiles(idSort, :);

% check file consistency
fileNum = [];
for idF = 1:length(eventFiles)
   fileNum = [fileNum str2num(eventFiles{idF, 1}(13:17))];
end
if (any(find(diff(fileNum) ~= 1, 1)))
   fprintf('DEC_WARNING: missing system files\n');
end

fprintf('Processing %d system files\n', size(eventFiles, 1));

% decode needed events data
nbEventFiles = size(eventFiles, 1);

% fprintf('\n\nATTENTION: LIMITATION DES DONNEES\n\n\n');
% nbEventFiles = 20;

for idFile = 1:nbEventFiles
   
   filePathName = [eventFiles{idFile, 4} eventFiles{idFile, 1}];
   
   %    if (strcmp(eventFiles{idFile, 1}, '3aa9_system_00115_20180720142611.hex'))
   %        a=1
   %    end
   
   if ~(exist(filePathName, 'file') == 2)
      fprintf('DEC_ERROR: File not found: %s\n', filePathName);
      return;
   end
   
   % decode file contents
   ok = decode_event_data(filePathName, a_launchDate);
   if (~ok)
      o_ok = ok;
      return;
   end
end

% associate cycle and pattern numbers to each event
g_decArgo_eventData = cat(2, repmat({-1}, size(g_decArgo_eventData, 1), 2), g_decArgo_eventData);
idFCy = find([g_decArgo_eventData{:, 4}] == 89);
cyNumList = cell2mat([g_decArgo_eventData{idFCy, 5}]);
idFPtn = find([g_decArgo_eventData{:, 4}] == 90);
ptnNumList = cell2mat([g_decArgo_eventData{idFPtn, 5}]);

cycNumAutotest = [];
idAutotest = [];
idFileList = find([g_decArgo_eventData{:, 4}] == 28);
for idFile = 1:length(idFileList)
   if (any(strfind(g_decArgo_eventData{idFileList(idFile), 5}{:}, '_autotest_')))
      fileName = g_decArgo_eventData{idFileList(idFile), 5}{:};
      idFUs = strfind(fileName, '_');
      cyNum = str2num(fileName(idFUs(1)+1:idFUs(2)-1));
      cycNumAutotest = [cycNumAutotest cyNum];
      idAutotest = [idAutotest idFileList(idFile)];
   end
end

% cyclePatternNumFloat = a_cyclePatternNumFloat(find(a_cyclePatternNumFloat(:, 2) ~= 0), :);
cyclePatternNumFloat = a_cyclePatternNumFloat;
cyclePatternNumFloat(find(cyclePatternNumFloat(:, 1) < g_decArgo_firstCycleNumCts5), :) = [];
cyclePatternNumFloat = cat(2, cyclePatternNumFloat, nan(size(cyclePatternNumFloat, 1), 4));
for idL = 1:size(cyclePatternNumFloat, 1)
   cyNum = cyclePatternNumFloat(idL, 1);
   ptnNum = cyclePatternNumFloat(idL, 2);
   
%       if ((cyNum == 107) && (ptnNum == 1))
%           a=1
%       end

   if (ptnNum == 0)
      idF = find(cycNumAutotest == cyNum);
      if (~isempty(idF))
         cyclePatternNumFloat(idL, 3) = idAutotest(idF(end)); % you can have more than one autotest file for the same cycle
         cyclePatternNumFloat(idL, 4) = idAutotest(idF(end));
         cyclePatternNumFloat(idL, 5) = cyclePatternNumFloat(idL, 3);
      end
   else
      idFC = find(cyNumList == cyNum);
      idFP = find(ptnNumList == ptnNum);
      if (isempty(idFC) || isempty(idFP))
         continue;
      end
      idFCycle = idFCy(idFC);
      idFPattern = idFPtn(idFP);
      idF = find(idFPattern > idFCycle);
      idFPattern = idFPattern(idF(1));
      cyclePatternNumFloat(idL, 3) = idFCycle;
      cyclePatternNumFloat(idL, 4) = idFPattern;
      
      if (ptnNum > 1)
         cyclePatternNumFloat(idL, 5) = cyclePatternNumFloat(idL, 4);
      else
         cyclePatternNumFloat(idL, 5) = cyclePatternNumFloat(idL, 3);
      end
   end
end

for idL = 1:size(cyclePatternNumFloat, 1)-1
   cyNum = cyclePatternNumFloat(idL, 1);
   ptnNum = cyclePatternNumFloat(idL, 2);
   cyNumNext = cyclePatternNumFloat(idL+1, 1);
   ptnNumNext = cyclePatternNumFloat(idL+1, 2);
   
   % we do not manage (yet) missing pattern !
   if (cyNumNext-cyNum > 1)
      fprintf('DEC_WARNING: system file anomaly: events of float cycles %d to %d ignored\n', ...
         cyNum, cyNumNext-1);
      g_decArgo_eventDataUnseenCycleNum = [g_decArgo_eventDataUnseenCycleNum cyNum:cyNumNext-1];
   else
      cyclePatternNumFloat(idL, 6) = cyclePatternNumFloat(idL+1, 5) - 1;
   end
end
% we assume there is no anomaly between the last event #90 and the end of the file
if (~isnan(cyclePatternNumFloat(end, 5)))
   cyclePatternNumFloat(end, 6) = size(g_decArgo_eventData, 1);
end

for idL = 1:size(cyclePatternNumFloat, 1)
   if (~any(isnan(cyclePatternNumFloat(idL, :))))
      [g_decArgo_eventData{cyclePatternNumFloat(idL, 5):cyclePatternNumFloat(idL, 6), 1}] = deal(cyclePatternNumFloat(idL, 1));
      [g_decArgo_eventData{cyclePatternNumFloat(idL, 5):cyclePatternNumFloat(idL, 6), 2}] = deal(cyclePatternNumFloat(idL, 2));
   end
end

% collect clock offset information
idFClockOffset = find([g_decArgo_eventData{:, 4}] == 12);
for idC = 1:length(idFClockOffset)
   g_decArgo_clockOffset.cycleNum = [g_decArgo_clockOffset.cycleNum g_decArgo_eventData{idFClockOffset(idC), 1}];
   g_decArgo_clockOffset.patternNum = [g_decArgo_clockOffset.patternNum g_decArgo_eventData{idFClockOffset(idC), 2}];
   g_decArgo_clockOffset.juldUtc = [g_decArgo_clockOffset.juldUtc g_decArgo_eventData{idFClockOffset(idC), 5}{:}];
   g_decArgo_clockOffset.juldFloat = [g_decArgo_clockOffset.juldFloat g_decArgo_eventData{idFClockOffset(idC), 6}];
   g_decArgo_clockOffset.clockOffset = [g_decArgo_clockOffset.clockOffset ...
      g_decArgo_eventData{idFClockOffset(idC), 6}-g_decArgo_eventData{idFClockOffset(idC), 5}{:}];
end

% version below failed for 4901801 #44,0 => reset of the float
% for idC = 1:length(idFCy)
%    idStop = idFCy(idC)-1;
%    if (idStart > 0)
%       [g_decArgo_eventData{idStart:idStop, 1}] = deal(cyNumPrev);
%       [g_decArgo_eventData{idStart:idStop, 2}] = deal(ptnNumPrev);
%    end
%    idStart = idFCy(idC);
%    cyNumPrev = g_decArgo_eventData{idFCy(idC), 5}{:};
%    if (idC < length(idFCy))
%       idFP = find((idFPtn > idFCy(idC)) & (idFPtn < idFCy(idC+1)));
%       if (~isempty(idFP))
%          ptnNumPrev = g_decArgo_eventData{idFPtn(idFP(1)), 5}{:};
%          for idP = 2:length(idFP)
%             idStop = idFPtn(idFP(idP))-1;
%             [g_decArgo_eventData{idStart:idStop, 1}] = deal(cyNumPrev);
%             [g_decArgo_eventData{idStart:idStop, 2}] = deal(ptnNumPrev);
%             idStart = idFPtn(idFP(idP));
%             ptnNumPrev = g_decArgo_eventData{idFPtn(idFP(idP)), 5}{:};
%          end
%       end
%    end
% end
% [g_decArgo_eventData{idStart:end, 1}] = deal(cyNumPrev);
% [g_decArgo_eventData{idStart:end, 2}] = deal(ptnNumPrev);

o_ok = 1;

return;

% ------------------------------------------------------------------------------
% Decode and store CTS5 events of a given system file.
%
% SYNTAX :
%  [o_ok] = decode_event_data(a_inputFilePathName, a_launchDate)
%
% INPUT PARAMETERS :
%   a_inputFilePathName : system file path name
%   a_launchDate        : launch date
%
% OUTPUT PARAMETERS :
%   o_ok : decoding report flag (1 if ok, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = decode_event_data(a_inputFilePathName, a_launchDate)

% output parameters initialization
o_ok = 0;

% default values
global g_decArgo_janFirst2000InJulD;

% variable to store all useful event data
global g_decArgo_eventData;

% variable to store event numbers and types
global g_decArgo_eventNumTypeList;

% list of events to use
global g_decArgo_eventUsedList;


% initialize the list of event numbers and types
init_event_lists;

evtList = g_decArgo_eventNumTypeList;

if ~(exist(a_inputFilePathName, 'file') == 2)
   fprintf('ERROR: decode_event_data: File not found: %s\n', a_inputFilePathName);
   return;
end

% open the file and read the data
fId = fopen(a_inputFilePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_inputFilePathName);
   return;
end
data = fread(fId);
fclose(fId);

% find the position of the last useful byte
lastByteNum = get_last_byte_number(data, hex2dec('1a'));

timeOffset = 455812984;

curBit = 1;
ignoreEvts = 0;
ignoreNextEvt = 0;
clockError = 0;
evtJulDPrec = [];
while ((curBit-1)/8 < lastByteNum)
   if (lastByteNum - (curBit-1)/8 < 5)
      fprintf('ERROR: unexpected end of data (%d last bytes ignored) in file %s\n', ...
         lastByteNum - (curBit-1)/8, a_inputFilePathName);
      break;
   else
      
      rawData = get_bits(curBit, [8 32], data);
      curBit = curBit + 40;
      
      timeInfo = typecast(swapbytes(uint32(rawData(2))), 'uint32');
      evtDate = bitand(timeInfo, hex2dec('3FFFFFFF'));
      evtEpoch2000 = evtDate + timeOffset;
      evtJulD = g_decArgo_janFirst2000InJulD + double(evtEpoch2000)/86400;
      evtGregD = julian_2_gregorian_dec_argo(evtJulD);
      
      evtNum = rawData(1) + bitshift(timeInfo, -30)*256;
      idF = find(evtList(:, 1) == evtNum);
      if (length(idF) == 1)
         evtDataType = evtList(idF, 2);
         retrieve = 0;
         if (ismember(evtNum, g_decArgo_eventUsedList))
            retrieve = 1;
         end
         [ok, curBit, evtData] = get_event(curBit, data, evtDataType, retrieve);
         if (~ok)
            fprintf('ERROR: unable to retrieve event #%d (dated %s) in file %s\n', ...
               evtNum, evtGregD, a_inputFilePathName);
            return;
         end
         
         % BE CAREFUL: the RTC could be erroneously set
         % see for example float 6902829:
         % 23/07/2017 03:01	SYSTEM	Clock update 2001/01/00 00:00:00
         % in that case we ignore following events until the next #12 event
         stopClockError = 1;
         if (evtNum == 12)
            % check if the new RTC set date is after float launch date - 365
            if (evtData{:} > a_launchDate - 365)
               if (clockError == 1)
                  fprintf('WARNING: RTC correctly set to %s in file %s => end of event date correction\n', ...
                     julian_2_gregorian_dec_argo(evtData{:}), a_inputFilePathName);
                  clockError = 0;
                  stopClockError = 0;
               end
            else
               fprintf('WARNING: RTC erroneously set to %s in file %s => start of event date correction\n', ...
                  julian_2_gregorian_dec_argo(evtData{:}), a_inputFilePathName);
               clockError = 1;
            end
         end
         
         if (retrieve)
            evtNew = cell(1, 3);
            if (~isempty(g_decArgo_eventData))
               evtNew{1, 1} = size(g_decArgo_eventData, 1) + 1;
            else
               evtNew{1, 1} = 1;
            end
            evtNew{1, 2} = evtNum;
            evtNew{1, 3} = evtData;
            if ((clockError == 0) && (stopClockError == 1))
               evtNew{1, 4} = evtJulD;
               evtJulDPrec = evtJulD;
            else
               evtNew{1, 4} = fix(evtJulDPrec) + evtJulD - fix(evtJulD);
               if (ismember(evtNum, [12 66]))
                  evtNew{1, 3} = evtNew(1, 4);
               end
            end
            g_decArgo_eventData = cat(1, g_decArgo_eventData, evtNew);
         end
         
         % first version
         %          if (0)
         %             ignoreNextEvt = 0;
         %             if (evtNum == 12)
         %                % check if the new RTC set date is after float launch date - 365
         %                if (evtData{:} > a_launchDate - 365)
         %                   if (ignoreEvts == 1)
         %                      fprintf('WARNING: RTC correctly set to %s in file %s => end of ignored events\n', ...
         %                         julian_2_gregorian_dec_argo(evtData{:}), a_inputFilePathName);
         %                      ignoreEvts = 0;
         %                      ignoreNextEvt = 1;
         %                   end
         %                else
         %                   ignoreEvts = 1;
         %                   fprintf('WARNING: RTC erroneously set to %s in file %s => start of ignored events\n', ...
         %                      julian_2_gregorian_dec_argo(evtData{:}), a_inputFilePathName);
         %                end
         %             end
         %
         %             if (retrieve && ~ignoreEvts && ~ignoreNextEvt)
         %                evtNew = cell(1, 3);
         %                if (~isempty(g_decArgo_eventData))
         %                   evtNew{1, 1} = size(g_decArgo_eventData, 1) + 1;
         %                else
         %                   evtNew{1, 1} = 1;
         %                end
         %                evtNew{1, 2} = evtNum;
         %                evtNew{1, 3} = evtData;
         %                evtNew{1, 4} = evtJulD;
         %                g_decArgo_eventData = cat(1, g_decArgo_eventData, evtNew);
         %             elseif (retrieve && (ignoreEvts || ignoreNextEvt))
         %                fprintf('WARNING: event #%d ignored in file %s (due to erroneus RTC value)\n', ...
         %                   evtNum, a_inputFilePathName);
         %             end
         %          end
      else
         fprintf('ERROR: unexpected event number (%d) in file %s\n', ...
            evtNum, a_inputFilePathName);
         return;
      end
   end
end

o_ok = 1;

return;

% ------------------------------------------------------------------------------
% Decode (or only read without storing it) one CTS5 event.
%
% SYNTAX :
%  [o_ok, o_curBit, o_evtData] = get_event(a_curBit, a_data, a_evtDataType, a_retrieve)
%
% INPUT PARAMETERS :
%   a_curBit      : input current bit
%   a_data        : event data
%   a_evtDataType : event type
%   a_retrieve    : 1 if the event should be retrieved
%
% OUTPUT PARAMETERS :
%   o_ok      : decoding report flag (1 if ok, 0 otherwise)
%   o_curBit  : input current bit
%   o_evtData : retrieved event data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok, o_curBit, o_evtData] = get_event(a_curBit, a_data, a_evtDataType, a_retrieve)

% output parameters initialization
o_ok = 0;
o_curBit = a_curBit;
o_evtData = [];

% default values
global g_decArgo_janFirst2000InJulD;

% list of corresponding bit pattern (used to acces the data)
bitList = [ ...
   {0} {[8 32]}; ...
   {1} {[32]}; ...
   {2} {[8]}; ...
   {3} {[32 16]}; ...
   {4} {[32]}; ...
   {5} {[32]}; ...
   {6} {[16 32]}; ...
   {7} {[16]}; ...
   {8} {[32 16]}; ...
   {9} {[32 32]}; ...
   {10} {[8 8]}; ...
   {11} {[32 8]}; ...
   {12} {[16 8 8]}; ...
   {13} {[16 8 8 8]}; ...
   {14} {[8 8 8 8]}; ...
   {15} {[8]}; ...
   {16} {[8 8]}; ...
   ];

% retrive needed bit pattern
idF = find([bitList{:, 1}] == a_evtDataType);
if (length(idF) == 1)
   bitPattern = bitList{idF, 2};
else
   fprintf('ERROR: bit pattern not defined for event data type #%d\n', a_evtDataType);
   return;
end

switch (a_evtDataType)
   case 0
      % none
   case 1
      % F
      if (a_retrieve)
         evtRawData = get_bits(o_curBit, bitPattern, a_data);
         o_curBit = o_curBit + sum(bitPattern);
         o_evtData{end+1} = typecast(swapbytes(uint32(evtRawData)), 'single');
      else
         o_curBit = o_curBit + sum(bitPattern);
      end
   case {2, 15}
      % S
      if (a_retrieve)
         evtRawData = get_bits(o_curBit, bitPattern, a_data);
         o_curBit = o_curBit + sum(bitPattern);
         evtRawData2 = get_bits(o_curBit, repmat(8, 1, evtRawData), a_data);
         o_curBit = o_curBit + evtRawData*8;
         o_evtData{end+1} = char(evtRawData2-128)';
      else
         evtRawData = get_bits(o_curBit, bitPattern, a_data);
         o_curBit = o_curBit + sum(bitPattern) + evtRawData*8;
      end
   case 3
      % LUU
      if (a_retrieve)
         evtRawData = get_bits(o_curBit, bitPattern, a_data);
         o_curBit = o_curBit + sum(bitPattern);
         o_evtData{end+1} = typecast(swapbytes(uint32(evtRawData(1))), 'uint32');
         o_evtData{end+1} = typecast(swapbytes(uint16(evtRawData(2))), 'uint16');
      else
         o_curBit = o_curBit + sum(bitPattern);
      end
   case 4
      % LU
      if (a_retrieve)
         evtRawData = get_bits(o_curBit, bitPattern, a_data);
         o_curBit = o_curBit + sum(bitPattern);
         o_evtData{end+1} = typecast(swapbytes(uint32(evtRawData(1))), 'uint32');
      else
         o_curBit = o_curBit + sum(bitPattern);
      end
   case 5
      % CLK
      if (a_retrieve)
         evtRawData = get_bits(o_curBit, bitPattern, a_data);
         o_curBit = o_curBit + sum(bitPattern);
         evtDataEpoch = typecast(swapbytes(uint32(evtRawData)), 'uint32');
         evtDataJulD = g_decArgo_janFirst2000InJulD + double(evtDataEpoch)/86400;
         evtDataGregD = julian_2_gregorian_dec_argo(evtDataJulD);
         
         % BE CAREFUL: day and year are switched in the first firmware
         % version of CTS5 floats
         evtDay = str2num(evtDataGregD(1:4)) - 2000;
         evtMonth = str2num(evtDataGregD(6:7));
         evtYear = str2num(evtDataGregD(9:10)) + 2000;
         evtDataGregD = [sprintf('%04d/%02d/%02d', evtYear, evtMonth, evtDay) ' ' evtDataGregD(12:end)];
         o_evtData{end+1} = gregorian_2_julian_dec_argo(evtDataGregD);
      else
         o_curBit = o_curBit + sum(bitPattern);
      end
   case 6
      % UF
      if (a_retrieve)
         evtRawData = get_bits(o_curBit, bitPattern, a_data);
         o_curBit = o_curBit + sum(bitPattern);
         o_evtData{end+1} = typecast(swapbytes(uint16(evtRawData(1))), 'uint16');
         o_evtData{end+1} = typecast(swapbytes(uint32(evtRawData(2))), 'single');
      else
         o_curBit = o_curBit + sum(bitPattern);
      end
   case 7
      % U
      if (a_retrieve)
         evtRawData = get_bits(o_curBit, bitPattern, a_data);
         o_curBit = o_curBit + sum(bitPattern);
         o_evtData{end+1} = typecast(swapbytes(uint16(evtRawData)), 'uint16');
      else
         o_curBit = o_curBit + sum(bitPattern);
      end
   case 8
      % CLKU
      if (a_retrieve)
         evtRawData = get_bits(o_curBit, bitPattern, a_data);
         o_curBit = o_curBit + sum(bitPattern);
         evtDataEpoch = typecast(swapbytes(uint32(evtRawData(1))), 'uint32');
         evtDataJulD = g_decArgo_janFirst2000InJulD + double(evtDataEpoch)/86400;
         evtDataGregD = julian_2_gregorian_dec_argo(evtDataJulD);
         
         % BE CAREFUL: day and year are switched in the first firmware
         % version
         evtDay = str2num(evtDataGregD(1:4)) - 2000;
         evtMonth = str2num(evtDataGregD(6:7));
         evtYear = str2num(evtDataGregD(9:10)) + 2000;
         evtDataGregD = [sprintf('%04d/%02d/%02d', evtYear, evtMonth, evtDay) ' ' evtDataGregD(12:end)];
         o_evtData{end+1} = gregorian_2_julian_dec_argo(evtDataGregD);
         
         o_evtData{end+1} = typecast(swapbytes(uint16(evtRawData(2))), 'uint16');
      else
         o_curBit = o_curBit + sum(bitPattern);
      end
   case 9
      % FF
      if (a_retrieve)
         evtRawData = get_bits(o_curBit, bitPattern, a_data);
         o_curBit = o_curBit + sum(bitPattern);
         o_evtData{end+1} = typecast(swapbytes(uint32(evtRawData(1))), 'single');
         o_evtData{end+1} = typecast(swapbytes(uint32(evtRawData(2))), 'single');
      else
         o_curBit = o_curBit + sum(bitPattern);
      end
   case 10
      % SS
      if (a_retrieve)
         evtRawData = get_bits(o_curBit, bitPattern, a_data);
         if ((evtRawData(1) == 0) && (evtRawData(2) == 0))
            % empty GPS loc found in float 6902666 system file #26
            o_curBit = o_curBit + sum(bitPattern);
         else
            o_curBit = o_curBit + sum(bitPattern);
            evtRawData2 = get_bits(o_curBit, repmat(8, 1, evtRawData(1)), a_data);
            o_curBit = o_curBit + evtRawData(1)*8;
            % decode latitude
            rawDataLat = char(evtRawData2-128)';
            sign = 1;
            if (rawDataLat(end) == 'S')
               sign = -1;
            end
            data = str2double(rawDataLat(1:end-1));
            o_evtData{end+1} = (fix(data/100)+(data-fix(data/100)*100)/60)*sign;
            evtRawData3 = get_bits(o_curBit, repmat(8, 1, evtRawData(2)), a_data);
            o_curBit = o_curBit + evtRawData(2)*8;
            % decode longitude
            rawDataLat = char(evtRawData3-128)';
            sign = 1;
            if (rawDataLat(end) == 'W')
               sign = -1;
            end
            data = str2double(rawDataLat(1:end-1));
            o_evtData{end+1} = (fix(data/100)+(data-fix(data/100)*100)/60)*sign;
         end
      else
         evtRawData = get_bits(o_curBit, bitPattern, a_data);
         o_curBit = o_curBit + sum(bitPattern) + evtRawData(1)*8 + evtRawData(2)*8;
      end
   case 11
      % LUS
      if (a_retrieve)
         evtRawData = get_bits(o_curBit, bitPattern, a_data);
         o_curBit = o_curBit + sum(bitPattern);
         o_evtData{end+1} = typecast(swapbytes(uint32(evtRawData(1))), 'uint32');
         evtRawData2 = get_bits(o_curBit, repmat(8, 1, evtRawData(2)), a_data);
         o_curBit = o_curBit + evtRawData(2)*8;
         o_evtData{end+1} = char(evtRawData2-128)';
      else
         evtRawData = get_bits(o_curBit, bitPattern, a_data);
         o_curBit = o_curBit + sum(bitPattern) + evtRawData(2)*8;
      end
   case 12
      % USS
      if (a_retrieve)
         evtRawData = get_bits(o_curBit, bitPattern, a_data);
         o_curBit = o_curBit + sum(bitPattern);
         o_evtData{end+1} = typecast(swapbytes(uint16(evtRawData(1))), 'uint16');
         evtRawData2 = get_bits(o_curBit, repmat(8, 1, evtRawData(2)), a_data);
         o_curBit = o_curBit + evtRawData(2)*8;
         o_evtData{end+1} = char(evtRawData2-128)';
         evtRawData3 = get_bits(o_curBit, repmat(8, 1, evtRawData(3)), a_data);
         o_curBit = o_curBit + evtRawData(3)*8;
         o_evtData{end+1} = char(evtRawData3-128)';
      else
         evtRawData = get_bits(o_curBit, bitPattern, a_data);
         o_curBit = o_curBit + sum(bitPattern) + evtRawData(2)*8 + evtRawData(3)*8;
      end
   case 13
      % USSS
      if (a_retrieve)
         evtRawData = get_bits(o_curBit, bitPattern, a_data);
         o_curBit = o_curBit + sum(bitPattern);
         o_evtData{end+1} = typecast(swapbytes(uint16(evtRawData(1))), 'uint16');
         evtRawData2 = get_bits(o_curBit, repmat(8, 1, evtRawData(2)), a_data);
         o_curBit = o_curBit + evtRawData(2)*8;
         o_evtData{end+1} = char(evtRawData2-128)';
         %          evtRawData3 = get_bits(o_curBit, repmat(8, 1, evtRawData(3)), a_data);
         %          o_curBit = o_curBit + evtRawData(3)*8;
         evtRawData3 = get_bits(o_curBit, repmat(8, 1, evtRawData(3)-1), a_data);
         o_curBit = o_curBit + (evtRawData(3)-1)*8;
         o_evtData{end+1} = char(evtRawData3-128)';
         evtRawData4 = get_bits(o_curBit, repmat(8, 1, evtRawData(4)), a_data);
         %          o_curBit = o_curBit + evtRawData(4)*8;
         o_curBit = o_curBit + (evtRawData(4)+1)*8;
         o_evtData{end+1} = char(evtRawData4-128)';
      else
         evtRawData = get_bits(o_curBit, bitPattern, a_data);
         o_curBit = o_curBit + sum(bitPattern) + evtRawData(2)*8 + evtRawData(3)*8 + evtRawData(4)*8;
      end
   case 14
      % UUUU
      if (a_retrieve)
         evtRawData = get_bits(o_curBit, bitPattern, a_data);
         o_curBit = o_curBit + sum(bitPattern);
         o_evtData{end+1} = typecast(swapbytes(uint16(evtRawData(1))), 'uint16');
         o_evtData{end+1} = typecast(swapbytes(uint16(evtRawData(2))), 'uint16');
         o_evtData{end+1} = typecast(swapbytes(uint16(evtRawData(3))), 'uint16');
         o_evtData{end+1} = typecast(swapbytes(uint16(evtRawData(4))), 'uint16');
      else
         o_curBit = o_curBit + sum(bitPattern);
      end
   case 16
      % UU
      if (a_retrieve)
         evtRawData = get_bits(o_curBit, bitPattern, a_data);
         o_curBit = o_curBit + sum(bitPattern);
         o_evtData{end+1} = typecast(swapbytes(uint16(evtRawData(1))), 'uint16');
         o_evtData{end+1} = typecast(swapbytes(uint16(evtRawData(2))), 'uint16');
      else
         o_curBit = o_curBit + sum(bitPattern);
      end
   otherwise
      fprintf('ERROR: unexpected event data type (%d)\n', a_evtDataType);
      return;
end

o_ok = 1;

return;

% ------------------------------------------------------------------------------
% Init event type list and event used list.
%
% SYNTAX :
%  init_event_lists
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function init_event_lists

% variable to store event numbers and types
global g_decArgo_eventNumTypeList;

% list of events to use
global g_decArgo_eventUsedList;

g_decArgo_eventNumTypeList = [ ...
   0	,	0	; ...
   1	,	0	; ...
   2	,	0	; ...
   3	,	0	; ...
   4	,	0	; ...
   5	,	2	; ...
   6	,	1	; ...
   7	,	0	; ...
   8	,	0	; ...
   9	,	3	; ...
   10	,	3	; ...
   11	,	4	; ...
   12	,	5	; ...
   13	,	5	; ...
   14	,	0	; ...
   15	,	0	; ...
   16	,	0	; ...
   17	,	0	; ...
   18	,	1	; ...
   19	,	2	; ...
   20	,	5	; ...
   21	,	0	; ...
   22	,	0	; ...
   23	,	0	; ...
   24	,	0	; ...
   25	,	0	; ...
   26	,	0	; ...
   27	,	2	; ...
   28	,	2	; ...
   29	,	0	; ...
   30	,	2	; ...
   31	,	0	; ...
   32	,	0	; ...
   33	,	0	; ...
   34	,	6	; ...
   35	,	0	; ...
   36	,	7	; ...
   37	,	8	; ...
   38	,	8	; ...
   39	,	8	; ...
   40	,	7	; ...
   41	,	0	; ...
   42	,	0	; ...
   43	,	0	; ...
   44	,	0	; ...
   45	,	0	; ...
   46	,	0	; ...
   47	,	1	; ...
   48	,	1	; ...
   49	,	1	; ...
   50	,	0	; ...
   51	,	0	; ...
   52	,	0	; ...
   53	,	0	; ...
   54	,	0	; ...
   55	,	9	; ...
   56	,	0	; ...
   57	,	0	; ...
   58	,	0	; ...
   59	,	0	; ...
   60	,	0	; ...
   61	,	0	; ...
   62	,	0	; ...
   63	,	0	; ...
   64	,	0	; ...
   65	,	0	; ...
   66	,	5	; ...
   67	,	10	; ...
   68	,	0	; ...
   69	,	0	; ...
   70	,	0	; ...
   71	,	0	; ...
   72	,	0	; ...
   73	,	0	; ...
   74	,	0	; ...
   75	,	2	; ...
   76	,	11	; ...
   77	,	2	; ...
   78	,	4	; ...
   79	,	4	; ...
   80	,	0	; ...
   81	,	0	; ...
   82	,	0	; ...
   83	,	0	; ...
   84	,	0	; ...
   85	,	0	; ...
   86	,	7	; ...
   87	,	2	; ...
   88	,	2	; ...
   89	,	7	; ...
   90	,	7	; ...
   91	,	4	; ...
   92	,	5	; ...
   93	,	5	; ...
   94	,	5	; ...
   95	,	7	; ...
   96	,	0	; ...
   97	,	0	; ...
   98	,	0	; ...
   99	,	0	; ...
   100	,	0	; ...
   101	,	0	; ...
   102	,	0	; ...
   103	,	7	; ...
   104	,	7	; ...
   105	,	7	; ...
   106	,	7	; ...
   107	,	7	; ...
   108	,	0	; ...
   109	,	0	; ...
   110	,	0	; ...
   111	,	0	; ...
   112	,	0	; ...
   113	,	7	; ...
   114	,	0	; ...
   115	,	0	; ...
   116	,	0	; ...
   117	,	0	; ...
   118	,	0	; ...
   119	,	0	; ...
   120	,	0	; ...
   121	,	0	; ...
   122	,	0	; ...
   123	,	0	; ...
   124	,	0	; ...
   125	,	0	; ...
   126	,	0	; ...
   127	,	2	; ...
   128	,	0	; ...
   129	,	0	; ...
   130	,	0	; ...
   131	,	2	; ...
   132	,	0	; ...
   133	,	0	; ...
   134	,	0	; ...
   135	,	0	; ...
   136	,	0	; ...
   137	,	0	; ...
   138	,	0	; ...
   139	,	0	; ...
   140	,	0	; ...
   141	,	12	; ...
   142	,	13	; ...
   143	,	13	; ...
   144	,	2	; ...
   145	,	2	; ...
   146	,	2	; ...
   147	,	2	; ...
   148	,	0	; ...
   149	,	0	; ...
   150	,	0	; ...
   151	,	0	; ...
   152	,	0	; ...
   153	,	0	; ...
   154	,	0	; ...
   155	,	0	; ...
   156	,	0	; ...
   157	,	0	; ...
   158	,	0	; ...
   159	,	0	; ...
   160	,	0	; ...
   161	,	0	; ...
   162	,	0	; ...
   163	,	0	; ...
   164	,	0	; ...
   165	,	0	; ...
   166	,	0	; ...
   167	,	0	; ...
   168	,	0	; ...
   169	,	0	; ...
   170	,	0	; ...
   171	,	0	; ...
   172	,	0	; ...
   173	,	2	; ...
   174	,	14	; ...
   175	,	14	; ...
   176	,	14	; ...
   177	,	0	; ...
   178	,	0	; ...
   179	,	0	; ...
   180	,	0	; ...
   181	,	0	; ...
   182	,	15	; ...
   183	,	0	; ...
   184	,	0	; ...
   185	,	0	; ...
   186	,	0	; ...
   187	,	0	; ...
   188	,	0	; ...
   189	,	0	; ...
   190	,	0	; ...
   191	,	0	; ...
   192	,	2	; ...
   193	,	0	; ...
   194	,	16	; ...
   195	,	7	; ...
   196	,	0	; ...
   197	,	7	; ...
   198	,	1	; ...
   199	,	0	; ...
   200	,	0	; ...
   201	,	0	; ...
   202	,	0	; ...
   203	,	0	; ...
   204	,	0	; ...
   205	,	0	; ...
   206	,	0	; ...
   207	,	0	; ...
   208	,	0	; ...
   209	,	0	; ...
   210	,	7	; ...
   211	,	0	; ...
   212	,	0	; ...
   213	,	5	; ...
   214	,	0	; ...
   215	,	0	; ...
   216	,	0	; ...
   217	,	0	; ...
   218	,	0	; ...
   219	,	0	; ...
   220	,	0	; ...
   221	,	0	; ...
   222	,	0	; ...
   223	,	0	; ...
   224	,	0	; ...
   225	,	7	; ...
   226	,	0	; ...
   227	,	0	; ...
   228	,	0	; ...
   229	,	0	; ...
   230	,	0	; ...
   231	,	0	; ...
   232	,	2	; ...
   233	,	0	; ...
   234	,	0	; ...
   235	,	0	; ...
   236	,	0	; ...
   237	,	0	; ...
   238	,	0	; ...
   239	,	2	; ...
   240	,	2	; ...
   241	,	2	; ...
   242	,	2	; ...
   243	,	0  ...
   ];

g_decArgo_eventUsedList =  [9 10 12 28 31:36 40 45:49 66 67 76 87:89 90 96 100 103:111 113:115 121 126 127 141 197 198 204];

return;
