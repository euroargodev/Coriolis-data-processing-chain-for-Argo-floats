% ------------------------------------------------------------------------------
% Create decoding buffers.
%
% SYNTAX :
%  [o_decodedData] = create_decoding_buffers_224(a_decodedData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_decodedData : decoded data
%   a_decoderId   : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_decodedData : decoded data (decoding buffers are in 'rankByCycle'
%                   field)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/08/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decodedData] = create_decoding_buffers_224(a_decodedData, a_decoderId)

% output parameters initialization
o_decodedData = [];

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% configuration values
global g_decArgo_dirOutputCsvFile;
global g_decArgo_processRemainingBuffers;

% ICE float firmware
global g_decArgo_floatFirmware;

% clock offset storage
global g_decArgo_clockOffset;


% maximum number of transmission sessions (after deep cycle) to look for
% expected data
NB_SESSION_MAX = 3;

% remove unused parameter packets transmitted before launch date
tabPackType = [a_decodedData.packType];
tabCyNum = [a_decodedData.cyNumRaw];
idPackProg = find(ismember(tabPackType, [5, 7]) & (tabCyNum == 0));
if (~isempty(idPackProg))
   % parameter packets have been received after launch date remove pre-launch
   % transmitted data
   idDel = find(tabCyNum == -1);
else
   % use only the last transmitted parameter packets
   idPackType5 = find(tabPackType == 5, 1, 'last');
   idPackType7 = find(tabPackType == 7, 1, 'last');
   idF = find(tabCyNum == -1);
   idDel = setdiff(idF, [idPackType5, idPackType7]);
end
a_decodedData(idDel) = [];
clear tabPackType;
clear tabCyNum;

tabFileName = {a_decodedData.fileName};
tabDate = [a_decodedData.fileDate];
tabDiffDate = [-1 diff(tabDate)];
tabCyNumRaw = [a_decodedData.cyNumRaw];
tabCyNum = tabCyNumRaw;
tabIrSession = [a_decodedData.irSession];
tabPackType = [a_decodedData.packType];
tabEolFlag = [a_decodedData.eolFlag];
tabResetDate = [a_decodedData.resetDate];
tabOffsetDate = [a_decodedData.julD2FloatDayOffset];
tabExpNbDesc = [a_decodedData.expNbDesc];
tabExpNbDrift = [a_decodedData.expNbDrift];
tabExpNbAsc = [a_decodedData.expNbAsc];

tabRankByCycle = ones(size(tabPackType))*-1;
tabResetFlag = zeros(size(tabPackType));
tabSession = ones(size(tabPackType))*-1;
tabBase = zeros(size(tabPackType));
tabRank = ones(size(tabPackType))*-1;
tabDeep = ones(size(tabPackType))*-1;
tabDone = zeros(size(tabPackType));
tabDelayed = ones(size(tabPackType))*-1;
tabCompleted = zeros(size(tabPackType));
tabGo = zeros(size(tabPackType));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MANAGE FLOAT RESET
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% manage possible reset of the float to create reliable cycle numbers
idPackType4 = find(tabPackType == 4);
if (any(diff(tabResetDate(idPackType4)) > 0))
   resetListId = find(diff(tabResetDate(idPackType4)) > 0) + 1;
   
   fprintf('INFO: Float #%d: %d reset detected\n', ...
      g_decArgo_floatNum, ...
      length(resetListId));
   
   for idR = 1:length(resetListId)
      resetId = idPackType4(resetListId(idR));
      resetDate = tabResetDate(resetId);
      tabResetFlag(resetId) = 1;
      cycNumPrev = tabCyNum(find(tabDate < resetDate, 1, 'last'));
      firstPack = find(tabDate >= resetDate, 1);
      
      fprintf('INFO: Float #%d: A reset has been performed at sea on %s\n', ...
         g_decArgo_floatNum, julian_2_gregorian_dec_argo(resetDate));
      
      if (tabCyNumRaw(firstPack) ~= 0)
         fprintf('WARNING: Float #%d: cycle number after reset (dated %s) should be 0\n', ...
            g_decArgo_floatNum, ...
            julian_2_gregorian_dec_argo(resetDate));
      end
      
      if (cycNumPrev > 0)
         tabCyNum(firstPack:end) = tabCyNumRaw(firstPack:end) + cycNumPrev + 1;
      end
      
      % update also cycle numbers in clock offset structure
      firstPackClockOffset = find(g_decArgo_clockOffset.juldUtc >= resetDate, 1);
      cycNumPrevClockOffset = g_decArgo_clockOffset.cycleNum( ...
         find(g_decArgo_clockOffset.juldUtc < resetDate, 1, 'last'));
      offset = 0;
      if (idR == 1)
         offset = cycNumPrevClockOffset;
      end
      
      if (cycNumPrevClockOffset > 0)
         g_decArgo_clockOffset.cycleNum(firstPackClockOffset:end) = ...
            g_decArgo_clockOffset.cycleNum(firstPackClockOffset:end) + offset + 1;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SET SESSION NUMBERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set a session number for each SBD
startId = find(ismember(tabPackType, [0 4 5]), 1);
sesNum = 1;
stop = 0;
while (~stop)
   stopId = find( ...
      (ismember(tabPackType, [0 4 5]) & ... % new cycle
      (tabCyNum > tabCyNum(startId)) & ...
      (tabDate > (tabDate(startId)))) | ...
      (ismember(tabPackType, [0]) & ... % same cycle
      (tabCyNum == tabCyNum(startId)) & ...
      (tabDate > (tabDate(startId)))) ...
      , 1);
   if (~isempty(stopId))
      tabSession(startId:stopId-1) = sesNum;
      tabBase(startId) = 1;
      sesNum = sesNum + 1;
      startId = stopId;
   else
      tabSession(startId:end) = sesNum;
      tabBase(startId) = 1;
      stop = 1;
   end
end

% the base packet of the session (packet type 0 4 5) may have been delayed
% (Ex: float 6902814 #12)
% => add new session when delay between transmissions exceeds 0.5 day
ONE_DAY = 1;
idTransDelay = find(tabDiffDate > ONE_DAY/2);
for idT = 1:length(idTransDelay)
   if (tabSession(idTransDelay(idT)-1) == tabSession(idTransDelay(idT)))
      tabSession(idTransDelay(idT):end) = tabSession(idTransDelay(idT):end) + 1;
      tabBase(idTransDelay(idT)) = 1;
   end
end

% remove session when delay of base packet is less than 10 minutes (except
% for the same cycle)
TEN_MINUTES = 10/1440;
idBase = find(tabBase == 1);
for idB = 1:length(idBase)
   if ((idBase(idB) > 1) && ...
         (tabDiffDate(idBase(idB)) < TEN_MINUTES) && ...
         (tabCyNum(idBase(idB)) ~= tabCyNum(idBase(idB)-1)))
      tabSession(idBase(idB):end) = tabSession(idBase(idB):end) - 1;
      tabBase(idBase(idB)) = 0;
   end
end

% add new session for EOL transmissions
idEol = find(tabEolFlag == 1);
for idE = 1:length(idEol)
   if ((idEol(idE) > 1) && (tabSession(idEol(idE)) == tabSession(idEol(idE)-1)))
      tabSession(idEol(idE):end) = tabSession(idEol(idE):end) + 1;
      tabBase(idEol(idE)) = 1;
   end
end

% consider only session after a deep cycle (to use NB_SESSION_MAX)
tabSessionDeep = tabSession;
sessionList = unique(tabSession);
for sesNum = sessionList
   idForSession = find(tabSession == sesNum);
   if (~any(ismember(tabPackType(idForSession), [1:3 8:11 13 15:18 20:23]))) % transmission after a deep cycle
      tabSessionDeep(idForSession(1):end) = tabSessionDeep(idForSession(1):end) - 1;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CREATE BUFFERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% process the main transmission of each session number
rank = 1;
sessionList = unique(tabSession);
for sesNum = sessionList
   
   cyNum = tabCyNum(find(tabSession == sesNum, 1, 'first'));
   idForCheck = find((tabSession == sesNum) & (tabCyNum == cyNum));
   
   % check current session contents
   [completed, deep, ~] = check_buffer(idForCheck, tabPackType, tabExpNbDesc, tabExpNbDrift, tabExpNbAsc, a_decoderId, cyNum, 0, 0);
   delayed = 0;
   
   % check data of following sessions (to get possibly unexpected data such
   % as pump or valve packets)
   sessionListBis = sessionList(find(sessionList > sesNum));
   if (any(ismember(tabSession, sessionListBis) & (tabCyNum == cyNum)))
      idRemaining = find(ismember(tabSession, sessionListBis) & (tabCyNum == cyNum));
      idStop = find(ismember(tabPackType(idRemaining), [0 4 5]), 1, 'first');
      
      if (~isempty(idStop))
         idRemaining = idRemaining(1:idStop-1);
      end
      if (~isempty(idRemaining))
         delayed = 2;
         idForCheck = [idForCheck idRemaining];
         [completed, deep, ~] = check_buffer(idForCheck, tabPackType, tabExpNbDesc, tabExpNbDrift, tabExpNbAsc, a_decoderId, cyNum, 0, 0);
      end
   end
   
   if (completed == 1)
      tabRank(idForCheck) = rank;
      rank = rank + 1;
      tabDeep(idForCheck) = deep;
      tabDone(idForCheck) = 1;
      tabDelayed(idForCheck) = delayed;
      tabCompleted(idForCheck) = 1;
      tabGo(idForCheck) = 1;
   else
      sesNumDeep = min(tabSessionDeep(idForCheck));
      if ((max(tabSessionDeep) - sesNumDeep) >= NB_SESSION_MAX-1)
         tabRank(idForCheck) = rank;
         rank = rank + 1;
         tabDeep(idForCheck) = deep;
         tabDone(idForCheck) = 1;
         tabDelayed(idForCheck) = delayed;
         tabCompleted(idForCheck) = 0;
         tabGo(idForCheck) = 1;
      else
         tabDeep(idForCheck) = deep;
         tabDone(idForCheck) = 1;
         if (g_decArgo_processRemainingBuffers)
            tabRank(idForCheck) = rank;
            rank = rank + 1;
            tabDelayed(idForCheck) = delayed;
            tabCompleted(idForCheck) = 0;
            tabGo(idForCheck) = 2;
         end
      end
   end
end

% process the remaining SBD
for sesNum = sessionList
   idForSession = find((tabSession == sesNum) & (tabDone == 0));
   if (~isempty(idForSession))
      cyNumList = unique(tabCyNum(idForSession));
      for cyNum = cyNumList
         idForCheck = find((tabSession == sesNum) & (tabCyNum == cyNum));
         
         % check current session contents
         [completed, deep, ~] = check_buffer(idForCheck, tabPackType, tabExpNbDesc, tabExpNbDrift, tabExpNbAsc, a_decoderId, cyNum, 0, 0);
         
         % check data of following sessions (to get possibly unexpected data such
         % as pump or valve packets)
         sessionListBis = sessionList(find(sessionList > sesNum));
         if (any(ismember(tabSession, sessionListBis) & (tabCyNum == cyNum)))
            idRemaining = find(ismember(tabSession, sessionListBis) & (tabCyNum == cyNum));
            idStop = find(ismember(tabPackType(idRemaining), [0 4 5]), 1, 'first');
            if (~isempty(idStop))
               idRemaining = idRemaining(1:idStop-1);
            end
            if (~isempty(idRemaining))
               idForCheck = [idForCheck idRemaining];
               [completed, deep, ~] = check_buffer(idForCheck, tabPackType, tabExpNbDesc, tabExpNbDrift, tabExpNbAsc, a_decoderId, cyNum, 0, 0);
            end
         end
         
         if (completed == 1)
            tabRank(idForCheck) = rank;
            rank = rank + 1;
            tabDeep(idForCheck) = deep;
            tabDone(idForCheck) = 1;
            tabDelayed(idForCheck) = 1;
            tabCompleted(idForCheck) = 1;
            tabGo(idForCheck) = 1;
         else
            sesNumDeep = min(tabSessionDeep(idForCheck));
            if ((max(tabSessionDeep) - sesNumDeep) >= NB_SESSION_MAX-1)
               tabRank(idForCheck) = rank;
               rank = rank + 1;
               tabDeep(idForCheck) = deep;
               tabDone(idForCheck) = 1;
               tabDelayed(idForCheck) = 1;
               tabCompleted(idForCheck) = 0;
               tabGo(idForCheck) = 1;
            else
               tabDeep(idForCheck) = deep;
               tabDone(idForCheck) = 1;
               if (g_decArgo_processRemainingBuffers)
                  tabRank(idForCheck) = rank;
                  rank = rank + 1;
                  tabDelayed(idForCheck) = 1;
                  tabCompleted(idForCheck) = 0;
                  tabGo(idForCheck) = 2;
               end
            end
         end
      end
   end
end

% the data are transmitted twice in case of EOL (data transmitted again during
% the first EOL transmission, except perhaps if it occured during a deep cycle
% (emergency ascend) ?)
idEol = find(tabEolFlag == 1);
eolCyNumList = unique(tabCyNum(idEol));
for cyNum = eolCyNumList
   idFirstEol = find((tabEolFlag == 1) & (tabCyNum == cyNum), 1, 'first');
   if (~isempty(idFirstEol))
      % get nominal transmission session of data for the same cycle
      idPrevTrans = find((tabCyNum == tabCyNum(idFirstEol)) & (tabIrSession == 0) & (tabEolFlag == 0), 1, 'last');
      if (~isempty(idPrevTrans))
         % check that the data have alreay be transmitted and the buffer is
         % completed
         if (tabCompleted(idPrevTrans))
            % ignore the data of the EOL transmission
            idAll = find(tabRank == tabRank(idFirstEol));
            tabDeep(idAll) = 0;
            idDel = find(~ismember(tabPackType(idAll), [0 4 5 7]));
            tabRank(idAll(idDel)) = -1;
         end
      end
   end
end

% in EOL mode param packet are sometimes transmitted twice (Ex: 6903703 #114),
% keep only the last transmitted one
eolRankNumList = unique(tabRank(idEol));
for rankNum = eolRankNumList
   idAll = find(tabRank == rankNum);
   idType5 = find(tabPackType(idAll) == 5);
   if (length(idType5) > 1)
      tabRank(idAll(idType5(1:end-1))) = -1;
   end
   idType7 = find(tabPackType(idAll) == 7);
   if (length(idType7) > 1)
      tabRank(idAll(idType7(1:end-1))) = -1;
   end
end

% in case of delayed transmission, second Iridium session packets are also
% delayed, set them to a dedicated buffer
tabRankOld = tabRank;
rankNumList = unique(tabRankOld);
for rankNum = rankNumList
   if (rankNum > 0)
      idAll = find(tabRankOld == rankNum);
      if (any(tabIrSession(idAll) == 0) && any(tabIrSession(idAll) == 1))
         % packets of the second Iridium session
         id2 = idAll(tabIrSession(idAll) == 1);
         idType5 = idAll(tabPackType(idAll) == 5);
         idType5 = idType5(idType5 > max(id2));
         id2 = [id2 idType5];
         idType7 = idAll(tabPackType(idAll) == 7);
         idType7 = idType7(idType7 > max(id2));
         id2 = [id2 idType7];
         % packets of the first Iridium session
         id1 = setdiff(idAll, id2);

         tabRank(tabRank > rankNum) = tabRank(tabRank > rankNum) + 1;
         tabRank(id2) = tabRank(id2) + 1;
         tabDeep(id1) = 1;
         tabGo(idAll) = 1;
      end
   end
end

% sort rank numbers according to cycle numbers
rank = 1;
cyNumList = unique(tabCyNum);
for cyNum = cyNumList
   idForCy = find(tabCyNum == cyNum);
   rankNumList = setdiff(unique(tabRank(idForCy)), -1);
   for rankNum = rankNumList
      idForRankCy = idForCy(find(tabRank(idForCy) == rankNum));
      tabRankByCycle(idForRankCy) = rank;
      rank = rank + 1;
   end
end

% update tabCompleted array
cyNumList = unique(tabRankByCycle);
cyNumList(cyNumList < 0) = [];
for cyId = 1:length(cyNumList)
   cyNum = cyNumList(cyId);
   idForCheck = find(tabRankByCycle == cyNum);

   % check current session contents
   [completed, ~, ~] = check_buffer(idForCheck, tabPackType, tabExpNbDesc, tabExpNbDrift, tabExpNbAsc, a_decoderId, cyNum, 0, 1);
   if (completed == 1)
      tabCompleted(idForCheck) = 1;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WRITE CYCLE INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check received data
fprintf('BUFF_INFO: Float #%d : FIRMWARE VERSION : %s\n', ...
   g_decArgo_floatNum, g_decArgo_floatFirmware);
cyNumList = 0:max(tabCyNum);
for cyNum = cyNumList
   idForCy = find(tabCyNum == cyNum);
   if (isempty(idForCy))
      fprintf('BUFF_INFO: Float #%d Cycle #%3d : - NO DATA\n', ...
         g_decArgo_floatNum, cyNum);
   else
      rankNumList = setdiff(unique(tabRank(idForCy), 'stable'), -1);
      for rankNum = rankNumList
         idForRankCy = idForCy(find(tabRank(idForCy) == rankNum));
         idRankCy = idForRankCy(1);
         
         if (tabDeep(idRankCy) == 1)
            deepStr = 'DEEP CYCLE   ';
         elseif (tabDeep(idRankCy) == 0)
            deepStr = 'SURFACE CYCLE';
         end
         
         delayedStr = 'UNKNOWN      ';
         if (tabDelayed(idRankCy) == 0)
            delayedStr = 'NOT DELAYED  ';
         elseif (tabDelayed(idRankCy) == 1)
            delayedStr = 'ICE DELAYED  ';
         elseif (tabDelayed(idRankCy) == 2)
            delayedStr = 'TRANS DELAYED';
         end
         
         if (tabCompleted(idRankCy) == 1)
            completedStr = 'COMPLETED';
         elseif (tabGo(idRankCy) == 1)
            completedStr = 'UNCOMPLETED (DECODED)';
         else
            completedStr = 'UNCOMPLETED (STILL WAITING)';
         end
         
         sessionList = unique(tabSession(idForRankCy));
         sessionStr = sprintf('#%d ', sessionList);
         sessionListStr = sprintf(' - %d session(s) (%s)', length(sessionList), sessionStr(1:end-1));
         
         piDecStr = '';
         if (tabGo(idRankCy) == 2)
            piDecStr = ' - DECODED WITH ''PROCESS_REMAINING_BUFFERS'' FLAG';
         end
         
         fprintf('BUFF_INFO: Float #%d Cycle #%3d : %3d SBD - %s - %s - %s%s%s\n', ...
            g_decArgo_floatNum, cyNum, ...
            length(idForRankCy), deepStr, delayedStr, completedStr, sessionListStr, piDecStr);
         
         if (tabCompleted(idRankCy) == 0)
            [~, ~, why] = check_buffer(idForRankCy, tabPackType, tabExpNbDesc, tabExpNbDrift, tabExpNbAsc, a_decoderId, cyNum, 1, 0);
            for idL = 1:length(why)
               fprintf('   -> %s\n', why{idL});
            end
         end
      end
   end
end

% assign cycle number to Iridium mail files

% 1- generate a new table of sessions only based on times (one new session if no
% transmission during more than 0.5 day)
idTransDelay = find(tabDiffDate > ONE_DAY/2);
tabSessionBis = nan(size(tabDate));
sessionNum = 1;
start = 1;
for idT = 1:length(idTransDelay)
   tabSessionBis(start:idTransDelay(idT)-1) = sessionNum;
   start = idTransDelay(idT);
   sessionNum = sessionNum + 1;
end
tabSessionBis(start:end) = sessionNum;

% 2- assign a cycle number (the first transmitted one) to each session
tabSbdFileName = [];
tabCycleNumber = [];
sessionListDone = [];
cyNumList = unique(tabCyNum, 'stable');
for idC = 1:length(cyNumList)
   idForCyNum = find(tabCyNum == cyNumList(idC), 1, 'first');
   sessionNum = tabSessionBis(idForCyNum);
   if (~ismember(sessionNum, sessionListDone))
      idSessionForCyNum = find(tabSessionBis == sessionNum);
      sbdFileNameList = unique(tabFileName(idSessionForCyNum));
      tabSbdFileName = [tabSbdFileName sbdFileNameList];
      tabCycleNumber = [tabCycleNumber repmat(cyNumList(idC), 1, length(sbdFileNameList))];
      sessionListDone = [sessionListDone sessionNum];
   end
end
update_mail_data_ir_sbd_delayed(tabSbdFileName, tabCycleNumber);

% PREVIOUS CODE - START
% assign cycle number to Iridium mail files
% idBase = find(tabBase == 1);
% for idB = 1:length(idBase)
%    idForSession = find(tabSession == tabSession(idBase(idB)));
%    sbdFileNameList = unique(tabFileName(idForSession));
%    tabSbdFileName = [tabSbdFileName sbdFileNameList];
%    tabCycleNumber = [tabCycleNumber repmat(tabCyNum(idBase(idB)), 1, length(sbdFileNameList))];
% end
% update_mail_data_ir_sbd_delayed(tabSbdFileName, tabCycleNumber);
% PREVIOUS CODE - END

% output data
o_decodedData = a_decodedData;
tabCyNumCell = num2cell(tabCyNum);
[o_decodedData.cyNum] = deal(tabCyNumCell{:});
tabRankByCycleCell = num2cell(tabRankByCycle);
[o_decodedData.rankByCycle] = deal(tabRankByCycleCell{:});
tabDeepCell = num2cell(tabDeep);
[o_decodedData.deep] = deal(tabDeepCell{:});
tabResetFlagCell = num2cell(tabResetFlag);
[o_decodedData.reset] = deal(tabResetFlagCell{:});
tabIceDelayed = zeros(size(tabDelayed)); % needed because we can have Ice delayed cycles without measurements (i.e. considered as 'surface' cycles) cf. 6902910
tabIceDelayed(find(tabDelayed == 1)) = 1;
tabIceDelayedCell = num2cell(tabIceDelayed);
[o_decodedData.iceDelayed] = deal(tabIceDelayedCell{:});
tabDelayedCell = num2cell(tabDelayed);
[o_decodedData.delayed] = deal(tabDelayedCell{:});
tabCompletedCell = num2cell(tabCompleted);
[o_decodedData.completed] = deal(tabCompletedCell{:});

if (~isempty(g_decArgo_outputCsvFileId))
   if (1)
      % CSV output
      csvFilepathName = [g_decArgo_dirOutputCsvFile '\' num2str(g_decArgo_floatNum) '_buffers_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
      fId = fopen(csvFilepathName, 'wt');
      if (fId ~= -1)
         
         header = '#;Rank;RnkByCycle;Session;SesDeep;Base;Date;DiffDate;Eol;CyNum;IrSession;Deep;Done;Delayed;Completed;Go;PackType;ExpNbDesc;tabExpNbDrift;tabExpNbAsc;CyNumRaw;ResetDate;ResetFlag;OffsetDate;PackTypeInfo';
         fprintf(fId, '%s\n', header);
         
         for idL = 1:length(tabPackType)
            
            if (idL > 1)
               if (tabSession(idL) ~= tabSession(idL-1))
                  fprintf(fId, '%d\n', -1);
               end
            end
            
            if (tabDiffDate(idL) == -1)
               diffDate = '';
            else
               diffDate = format_time_dec_argo(tabDiffDate(idL)*24);
            end
            
            if (tabResetDate(idL) == -1)
               resetDate = '';
            else
               resetDate = julian_2_gregorian_dec_argo(tabResetDate(idL));
            end
            
            fprintf(fId, '%d;%d;%d;%d;%d;%d;%s;%s;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%s;%d;%d;%s\n', ...
               idL, ...
               tabRank(idL), ...
               tabRankByCycle(idL), ...
               tabSession(idL), ...
               tabSessionDeep(idL), ...
               tabBase(idL), ...
               julian_2_gregorian_dec_argo(tabDate(idL)), ...
               diffDate, ...
               tabEolFlag(idL), ...
               tabCyNum(idL), ...
               tabIrSession(idL), ...
               tabDeep(idL), ...
               tabDone(idL), ...
               tabDelayed(idL), ...
               tabCompleted(idL), ...
               tabGo(idL), ...
               tabPackType(idL), ...
               tabExpNbDesc(idL), ...
               tabExpNbDrift(idL), ...
               tabExpNbAsc(idL), ...
               tabCyNumRaw(idL), ...
               resetDate, ...
               tabResetFlag(idL), ...
               tabOffsetDate(idL), ...
               get_pack_type_desc(tabPackType(idL), a_decoderId) ...
               );
            
         end
         
         fclose(fId);
      end
   end
end

return

% ------------------------------------------------------------------------------
% Check buffer completion.
%
% SYNTAX :
%  [o_completed, o_deep, o_whyStr] = check_buffer( ...
%    a_idForCheck, a_tabPackType, a_tabExpNbDesc, a_tabExpNbDrift, a_tabExpNbAsc, ...
%    a_decoderId, a_cycleNum, a_whyFlag, a_msgFlag)
%
% INPUT PARAMETERS :
%   a_idForCheck    : Id list of SBD to be checked
%   a_tabPackType   : SBD packet types
%   a_tabExpNbDesc  : expected number of descending data packets
%   a_tabExpNbDrift : expected number of drift data packets
%   a_tabExpNbAsc   : expected number of ascending data packets
%   a_decoderId     : float decoder Id
%   a_cycleNum      : cycle number
%   a_whyFlag       : if set to 1, print why the buffer is not completed
%   a_msgFlag       : if set to 1, print inconsistencies in buffer contents
%
% OUTPUT PARAMETERS :
%   o_completed : 1 if the buffer is completed, 0 otherwise
%   o_deep      : 1 if it is a deep cycle, 0 if it is a surface cycle
%   o_whyStr    : outpout strings that explain why the buffer is not
%                 completed
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/17/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_completed, o_deep, o_whyStr] = check_buffer( ...
   a_idForCheck, a_tabPackType, a_tabExpNbDesc, a_tabExpNbDrift, a_tabExpNbAsc, ...
   a_decoderId, a_cycleNum, a_whyFlag, a_msgFlag)

% output parameter initialization
o_completed = 0;
o_deep = 0;
o_whyStr = '';

% current float WMO number
global g_decArgo_floatNum;


% check buffer completion
idPackTech1 = find(a_tabPackType(a_idForCheck) == 0);
idPackTech2 = find(a_tabPackType(a_idForCheck) == 4);
idPackProg = find(a_tabPackType(a_idForCheck) == 5);
% for 5.49 floats, float parameter message is transmitted only when a parameter
% has been modified
if (ismember(a_decoderId, [224]))
   idPackProg = -1;
end
idPackDesc = find((a_tabPackType(a_idForCheck) == 1) | (a_tabPackType(a_idForCheck) == 8) | (a_tabPackType(a_idForCheck) == 15) | (a_tabPackType(a_idForCheck) == 20));
idPackDrift = find((a_tabPackType(a_idForCheck) == 2) | (a_tabPackType(a_idForCheck) == 9) | (a_tabPackType(a_idForCheck) == 16) | (a_tabPackType(a_idForCheck) == 21));
idPackAsc = find((a_tabPackType(a_idForCheck) == 3) | (a_tabPackType(a_idForCheck) == 10) | (a_tabPackType(a_idForCheck) == 17) | (a_tabPackType(a_idForCheck) == 22));

if ((length(idPackTech1) > 1) || (length(idPackTech2) > 1) || (length(idPackProg) > 1))
   if ((length(idPackTech1) > 1) && a_msgFlag)
      fprintf('ERROR: Float #%d Cycle #%3d : multiple (%d) Tech#1 packet in the buffer\n', ...
         g_decArgo_floatNum, a_cycleNum, length(idPackTech1));
   end
   if ((length(idPackTech2) > 1) && a_msgFlag)
      fprintf('ERROR: Float #%d Cycle #%3d : multiple (%d) Tech#2 packet in the buffer\n', ...
         g_decArgo_floatNum, a_cycleNum, length(idPackTech2));
   end
   if ((length(idPackProg) > 1) && a_msgFlag)
      fprintf('ERROR: Float #%d Cycle #%3d : multiple (%d) Prog#1 packet in the buffer\n', ...
         g_decArgo_floatNum, a_cycleNum, length(idPackProg));
   end
   return
end

if (~isempty(idPackDesc))
   recNbDesc = length(idPackDesc);
   o_deep = 1;
else
   recNbDesc = 0;
end
if (~isempty(idPackDrift))
   recNbDrift = length(idPackDrift);
   o_deep = 1;
else
   recNbDrift = 0;
end
if (~isempty(idPackAsc))
   recNbAsc = length(idPackAsc);
   o_deep = 1;
else
   recNbAsc = 0;
end

if (~isempty(idPackTech2))
   expNbDesc = a_tabExpNbDesc(a_idForCheck(idPackTech2));
   expNbDrift = a_tabExpNbDrift(a_idForCheck(idPackTech2));
   expNbAsc = a_tabExpNbAsc(a_idForCheck(idPackTech2));
   if (~isempty(idPackTech1) && ~isempty(idPackTech2) && ~isempty(idPackProg))
      if ((expNbDesc == 0) && (expNbDrift == 0) && (expNbAsc == 0))
         % surface cycle
         o_completed = 1;
      else
         % deep cycle
         if ((recNbDesc >= expNbDesc) && ...
               (recNbDrift >= expNbDrift) && ...
               (recNbAsc >= expNbAsc))
            o_completed = 1;
            
            if (recNbDesc > expNbDesc)
               fprintf('BUFF_WARNING: Float #%d Cycle #%3d : %d descending data packets are NOT EXPECTED\n', ...
                  g_decArgo_floatNum, a_cycleNum, recNbDesc-expNbDesc);
            end
            if (recNbDrift > expNbDrift)
               fprintf('BUFF_WARNING: Float #%d Cycle #%3d : %d drift data packets are NOT EXPECTED\n', ...
                  g_decArgo_floatNum, a_cycleNum, recNbDrift-expNbDrift);
            end
            if (recNbAsc > expNbAsc)
               fprintf('BUFF_WARNING: Float #%d Cycle #%3d : %d ascending data packets are NOT EXPECTED\n', ...
                  g_decArgo_floatNum, a_cycleNum, recNbAsc-expNbAsc);
            end
         end
         o_deep = 1;
      end
   end
end

% print what is missing in the buffer
if (a_whyFlag && ~o_completed)
   if (isempty(idPackTech1))
      o_whyStr{end+1} = 'Tech1 packet is missing';
   end
   if (isempty(idPackTech2))
      o_whyStr{end+1} = 'Tech2 packet is missing';
   end
   if (isempty(idPackProg))
      o_whyStr{end+1} = 'Prog packet is missing';
   end
   if (~isempty(idPackTech2))
      if (recNbDesc ~= expNbDesc)
         if (expNbDesc > recNbDesc)
            o_whyStr{end+1} = sprintf('%d descending data packets are MISSING', expNbDesc-recNbDesc);
         else
            o_whyStr{end+1} = sprintf('%d descending data packets are NOT EXPECTED', -(expNbDesc-recNbDesc));
         end
      end
      if (recNbDrift ~= expNbDrift)
         if (expNbDrift > recNbDrift)
            o_whyStr{end+1} = sprintf('%d drift data packets are MISSING', expNbDrift-recNbDrift);
         else
            o_whyStr{end+1} = sprintf('%d drift data packets are NOT EXPECTED', -(expNbDrift-recNbDrift));
         end
      end
      if (recNbAsc ~= expNbAsc)
         if (expNbAsc > recNbAsc)
            o_whyStr{end+1} = sprintf('%d ascending data packets are MISSING', expNbAsc-recNbAsc);
         else
            o_whyStr{end+1} = sprintf('%d ascending data packets are NOT EXPECTED', -(expNbAsc-recNbAsc));
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Convert packet type number into description string.
%
% SYNTAX :
%  [o_packTypeDesc] = get_pack_type_desc(a_packType, a_decoderId)
%
% INPUT PARAMETERS :
%   a_packType  : packet type number
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_packTypeDesc : packet type description
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/17/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_packTypeDesc] = get_pack_type_desc(a_packType, a_decoderId)

% output parameter initialization
o_packTypeDesc = '';

switch (a_decoderId)
   case {224}
      switch (a_packType)
         case 0
            o_packTypeDesc = 'Tech#1';
         case {1, 8, 15, 20}
            o_packTypeDesc = 'Desc meas';
         case {2, 9, 16, 21}
            o_packTypeDesc = 'Drift meas';
         case {3, 10, 17, 22}
            o_packTypeDesc = 'Asc meas';
         case 4
            o_packTypeDesc = 'Tech#2';
         case 5
            o_packTypeDesc = 'Prog#1';
         case 6
            o_packTypeDesc = 'Hydrau';
         case 7
            o_packTypeDesc = 'Prog#2';
         case {11, 13, 18, 23}
            o_packTypeDesc = 'NS meas';
         case {12, 14, 19, 24}
            o_packTypeDesc = 'IA meas';
         otherwise
            fprintf('WARNING: Unknown packet type #%d for decoderId #%d\n', ...
               a_packType, a_decoderId);
      end
      
   otherwise
      fprintf('WARNING: Nothing done yet in get_pack_type_desc for decoderId #%d\n', ...
         a_decoderId);
end

return
