% ------------------------------------------------------------------------------
% Create decoding buffers.
%
% SYNTAX :
%  [o_decodedData] = create_decoding_buffers_212_214_216_217_218(a_decodedData, a_decoderId)
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
%   12/17/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decodedData] = create_decoding_buffers_212_214_216_217_218(a_decodedData, a_decoderId)

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

% global default values
global g_decArgo_dateDef;


% maximum number of transmission sessions (after deep cycle) to look for
% expected data
NB_SESSION_MAX = 3;

% remove unused parameter packets transmitted before launch date
tabPackType = [a_decodedData.packType];
tabCyNum = [a_decodedData.cyNumRaw];
if (a_decoderId == 216)
   idPackProg = find((tabPackType == 5) & (tabCyNum == 0));
else
   idPackProg = find(ismember(tabPackType, [5, 7]) & (tabCyNum == 0));
end
if (~isempty(idPackProg))
   % parameter packets have been received after launch date remove pre-launch
   % transmitted data
   idDel = find(tabCyNum == -1);
else
   % use only the last transmitted parameter packets
   idPackType5 = find(tabPackType == 5, 1, 'last');
   if (a_decoderId == 216)
      idPackType7 = [];
   else
      idPackType7 = find(tabPackType == 7, 1, 'last');
   end
   idF = find(tabCyNum == -1);
   idDel = setdiff(idF, [idPackType5, idPackType7]);
end
a_decodedData(idDel) = [];
clear tabPackType;
clear tabCyNum;

% specific
if (ismember(g_decArgo_floatNum, [3902104 7900510 3902101 3902107]))
   switch g_decArgo_floatNum
      case 3902104
         % the float transmitted cycle #51 twice
         idPackType4 = find(([a_decodedData.fileDate] == gregorian_2_julian_dec_argo('2018/09/10 09:44:32')) & ...
            ([a_decodedData.packType] == 4));
         a_decodedData(idPackType4).expNbDesc = 0;
         a_decodedData(idPackType4).expNbDrift = 0;
         a_decodedData(idPackType4).expNbAsc = 0;
         idDel = find(([a_decodedData.fileDate] >= gregorian_2_julian_dec_argo('2018/09/10 09:44:45')) & ...
            ([a_decodedData.fileDate] <= gregorian_2_julian_dec_argo('2018/09/10 09:46:50')));
         a_decodedData(idDel) = [];
      case 7900510
         % the float transmitted twice packets types 0, 4 and 5 of cycle #27
         idDel = find([a_decodedData.fileDate] == gregorian_2_julian_dec_argo('2019/09/08 06:03:48'));
         a_decodedData(idDel) = [];
      case 3902101
         % the float transmitted twice packets types 10 of cycle #373 in second
         % Iridium session
         idPackType4 = find(([a_decodedData.fileDate] == gregorian_2_julian_dec_argo('2020/02/07 09:23:19')) & ...
            ([a_decodedData.packType] == 4));
         a_decodedData(idPackType4).expNbAsc = 0;
         idDel = find( ...
            (([a_decodedData.fileDate] == gregorian_2_julian_dec_argo('2020/02/07 09:23:39')) | ...
            ([a_decodedData.fileDate] == gregorian_2_julian_dec_argo('2020/02/07 09:23:51')) | ...
            ([a_decodedData.fileDate] == gregorian_2_julian_dec_argo('2020/02/07 09:24:03'))) & ...
            ([a_decodedData.packType] == 10));
         a_decodedData(idDel) = [];
      case 3902107
         % packet type 7 transmitted twice in first transmitted session of cycle
         % #113, ignore the second one
         idDel = find([a_decodedData.fileDate] == gregorian_2_julian_dec_argo('2020/12/12 23:16:14'));
         a_decodedData(idDel) = [];
   end
end

tabFileName = {a_decodedData.fileName};
tabDate = [a_decodedData.fileDate];
tabDiffDate = [-1 diff(tabDate)];
tabCyNumRaw = [a_decodedData.cyNumRaw];
tabCyNum = tabCyNumRaw;
tabPackType = [a_decodedData.packType];
tabEolFlag = [a_decodedData.eolFlag];
tabResetDate = [a_decodedData.resetDate];
tabOffsetDate = [a_decodedData.julD2FloatDayOffset];
tabExpNbDesc = [a_decodedData.expNbDesc];
tabExpNbDrift = [a_decodedData.expNbDrift];
tabExpNbAsc = [a_decodedData.expNbAsc];

tabRankByCycle = ones(size(tabPackType))*-1;
tabRankByDate = ones(size(tabPackType))*-1;
tabResetFlag = zeros(size(tabPackType));
tabSession = ones(size(tabPackType))*-1;
tabSessionDeep = ones(size(tabPackType))*-1;
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

% specific
if (ismember(g_decArgo_floatNum, [ ...
      6902814, 6903230, 3901963, 6903265, 3901645, ...
      6903006, 6901880, 6902957, 6902849, 6902853, 6903019]))
   switch g_decArgo_floatNum
      case 6903230
         % packet type 0 4 5 transmitted after data packets
         id = find((tabCyNum == 10) & (tabPackType == 0), 1);
         tabSession(id:end) = tabSession(id:end) - 1;
         tabBase(id) = 0;
         id = find((tabCyNum == 12) & (tabPackType == 0), 1);
         tabSession(id:end) = tabSession(id:end) - 1;
         tabBase(id) = 0;
         
         % cycle #43 detected in 2 sessions
         id = find((tabCyNum == 43) & (tabBase == 1));
         tabBase(id(2)) = 0;
         tabSession(find(tabSession == tabSession(id(2)))) = tabSession(id(1));
         
         % 23/10/2020 transmission detected in 2 sessions
         id98 = find((tabCyNum == 98) & (tabBase == 1));
         id96 = find((tabCyNum == 96) & (tabBase == 1));
         tabBase(id96) = 0;
         tabSession(find(tabSession == tabSession(id96))) = tabSession(id98);
      case 6902814
         % packet type 0 4 5 transmitted after data packets
         id = find((tabCyNum == 12) & (tabPackType == 0), 1);
         tabSession(id:end) = tabSession(id:end) - 1;
         tabBase(id) = 0;
      case 3901963
         % packet type 0 4 5 transmitted after data packets
         id = find((tabCyNum == 10) & (tabPackType == 0), 1);
         tabSession(id:end) = tabSession(id:end) - 1;
         tabBase(id) = 0;
         % 5 sessions are needed to transmit cycle #13
         NB_SESSION_MAX = 5;
         % this is not the base SBD of cycle #12 (because transmitted in
         % delayed mode)
         id = find((tabCyNum == 12) & (tabPackType == 0), 1);
         tabSession(id:end) = tabSession(id:end) - 1;
         tabBase(id) = 0;
         % cycles 66 to 68 are surface cycles transmitted in delayed
         id = find((tabCyNum == 66) & (tabPackType == 0), 1, 'first');
         tabSession(id:end) = tabSession(id:end) + 1;
         id = find((tabCyNum == 66) & (tabPackType == 0), 1, 'last');
         tabSession(id:end) = tabSession(id:end) + 1;
         id = find((tabCyNum == 67) & (tabPackType == 0), 1, 'first');
         tabSession(id:end) = tabSession(id:end) + 1;
         id = find((tabCyNum == 67) & (tabPackType == 0), 1, 'last');
         tabSession(id:end) = tabSession(id:end) + 1;
         id = find((tabCyNum == 68) & (tabPackType == 0), 1, 'first');
         tabSession(id:end) = tabSession(id:end) + 1;
         id = find((tabCyNum == 68) & (tabPackType == 0), 1, 'last');
         tabSession(id:end) = tabSession(id:end) + 1;
      case 6903265
         % surface message types [0 4 5] of cycles 100 to 110 were
         % transmitted in the same session #102, we must separate them by
         % assigning them to distinct sessions
         idS = find((tabSession == 102) & (ismember(tabCyNum, 100:110)) & (tabPackType == 0));
         for id = idS
            tabSession(id:end) = tabSession(id:end) + 1;
         end
      case 3901645
         % packet type 0 4 5 transmitted after data packets
         id = find((tabCyNum == 31) & (tabPackType == 0), 1);
         tabSession(id:end) = tabSession(id:end) - 1;
         tabBase(id) = 0;
      case 6903006
         % packet type 0 4 5 transmitted after data packets
         id = find((tabCyNum == 105) & (tabPackType == 0), 1);
         tabSession(id:end) = tabSession(id:end) - 1;
         tabBase(id) = 0;
         id = find((tabCyNum == 107) & (tabPackType == 0), 1);
         tabSession(id:end) = tabSession(id:end) - 1;
         tabBase(id) = 0;
      case 6901880
         % packet type 0 4 5 transmitted after data packets
         id = find((tabCyNum == 40) & (tabPackType == 0), 1);
         tabSession(id:end) = tabSession(id:end) - 1;
         tabBase(id) = 0;
         % cycle 59 and 60 delayed
         session59 = min(tabSession(tabCyNum == 59));
         for idCy = 59:69
            id = find(tabCyNum == idCy);
            tabSession(id) = session59 + (idCy-59);
            tabBase(id) = 0;
            tabBase(id(1)) = 1;
         end
         session70 = min(tabSession(tabCyNum == 70));
         offset = session59 + 10 - session70 + 1;
         id = find(tabCyNum >= 70);
         tabSession(id) = tabSession(id) + offset;
         % packet type 0 4 5 transmitted after data packets
         id = find((tabCyNum == 97) & (tabPackType == 0), 1);
         tabSession(id:end) = tabSession(id:end) - 1;
         tabBase(id) = 0;
      case 6902957
         % packet type 0 4 5 transmitted after data packets
         id = find(tabCyNum == 119);
         tabSession(id) = max(tabSession(id));
         tabBase(id) = 0;
         id = find(tabCyNum == 121);
         tabSession(id) = max(tabSession(id));
         tabBase(id) = 0;         
         
         % from cycle 123: difficult transmission => stored in memory => full
         % memory ? dead at cycle 133 ?
         % cycles 124 to 127 delayed
         % cycles 128 to 132 missing (memory full ?)
         % last transmission cycle 133
         
         id = find(tabCyNum == 122);
         sessionNum122 = max(tabSession(id));
         
         for n = 1:5
            id = find(tabCyNum == 122+n);
            tabSession(id) = sessionNum122 + n;
            tabBase(id) = 0;
         end
         
         id = find(tabCyNum == 133);
         tabSession(id) = sessionNum122 + 11;
         tabBase(id) = 0;
      case 6902849
         % delayed transmission of second Iridium session of cycle #217, 221
         id = find((tabCyNum == 217) & (tabPackType == 0));
         idForSession = find(tabSession == tabSession(id(1)));
         tabBase(id(1)) = 1;
         tabSession(id(1):id(2)-1) = tabSession(id(1):id(2)-1) + 1;
         tabBase(id(2)) = 1;
         tabSession(id(2):idForSession(end)) = tabSession(id(2):idForSession(end)) + 2;
         tabSession(idForSession(end)+1:end) = tabSession(idForSession(end)+1:end) + 3;
         
         id = find((tabCyNum == 221) & (tabPackType == 0));
         idForSession = find(tabSession == tabSession(id(1)));
         tabBase(id(1)) = 1;
         tabSession(id(1):id(2)-1) = tabSession(id(1):id(2)-1) + 1;
         tabBase(id(2)) = 1;
         tabSession(id(2):idForSession(end)) = tabSession(id(2):idForSession(end)) + 2;
         tabSession(idForSession(end)+1:end) = tabSession(idForSession(end)+1:end) + 3;
      case 6902853
         % delayed transmission cycle #219 (2 sessions)
         id = find((tabCyNum == 219) & (tabPackType == 0));
         idForSession = find(tabSession == tabSession(id(1)));
         tabBase(id(1)) = 1;
         tabSession(id(1):id(2)-1) = tabSession(id(1):id(2)-1) + 1;
         tabBase(id(2)) = 1;
         tabSession(id(2):idForSession(end)) = tabSession(id(2):idForSession(end)) + 2;
         tabSession(idForSession(end)+1:end) = tabSession(idForSession(end)+1:end) + 3;
         
         % delayed transmission cycle #223 (2 sessions)
         id = find((tabCyNum == 223) & (tabPackType == 0));
         idForSession = find(tabSession == tabSession(id(1)));
         tabBase(id(1)) = 1;
         tabSession(id(1):id(2)-1) = tabSession(id(1):id(2)-1) + 1;
         tabBase(id(2)) = 1;
         tabSession(id(2):idForSession(end)) = tabSession(id(2):idForSession(end)) + 2;
         tabSession(idForSession(end)+1:end) = tabSession(idForSession(end)+1:end) + 3;

      case 6903019
         % delayed transmission cycle #150 (2 sessions)
         id = find((tabCyNum == 150) & (tabPackType == 0));
         idForSession = find(tabSession == tabSession(id(1)));
         tabBase(id(1)) = 1;
         tabSession(id(1):id(2)-1) = tabSession(id(1):id(2)-1) + 1;
         tabBase(id(2)) = 1;
         tabSession(id(2):idForSession(end)) = tabSession(id(2):idForSession(end)) + 2;
         tabSession(idForSession(end)+1:end) = tabSession(idForSession(end)+1:end) + 3;
   end
end

% consider only session after a deep cycle (to use NB_SESSION_MAX)
tabSessionDeep = tabSession;
sessionList = unique(tabSession);
for sesNum = sessionList
   idForSession = find(tabSession == sesNum);
   if (~any(ismember(tabPackType(idForSession), [1 2 3 8 9 10 11 13]))) % transmission after a deep cycle
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
   [completed, deep, ~] = check_buffer(idForCheck, tabPackType, tabExpNbDesc, tabExpNbDrift, tabExpNbAsc, a_decoderId, cyNum, 0);
   delayed = 0;
   
   % check data of following sessions (to get possibly unexpected data such
   % as pump or valve packets)
   sessionListBis = sessionList(find(sessionList > sesNum));
   if (any(ismember(tabSession, sessionListBis) & (tabCyNum == cyNum)))
      idRemaining = find(ismember(tabSession, sessionListBis) & (tabCyNum == cyNum));
      idStop = find(ismember(tabPackType(idRemaining), [0 4 5]), 1, 'first');
      
      % specific
      if (ismember(g_decArgo_floatNum, [ ...
            3901963, 6903256, 6903230]))
         switch g_decArgo_floatNum
            case 3901963
               % cycles #13, #24 and #25 are delayed and the packet types [0 4 5]
               % are not the first transmitted SBD
               if (ismember(cyNum, [13 24 25]))
                  idStop = [];
               end
            case 6903256
               if (cyNum == 6)
                  idStop = [];
               end
            case 6903230
               % cycle #98 is delayed and the packet types [0 4 5]
               % are not the first transmitted SBD
               if (cyNum == 98)
                  idStop = [];
               end
         end
      end
      
      if (~isempty(idStop))
         idRemaining = idRemaining(1:idStop-1);
      end
      if (~isempty(idRemaining))
         delayed = 2;
         idForCheck = [idForCheck idRemaining];
         [completed, deep, ~] = check_buffer(idForCheck, tabPackType, tabExpNbDesc, tabExpNbDrift, tabExpNbAsc, a_decoderId, cyNum, 0);
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
         [completed, deep, ~] = check_buffer(idForCheck, tabPackType, tabExpNbDesc, tabExpNbDrift, tabExpNbAsc, a_decoderId, cyNum, 0);
         
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
               [completed, deep, ~] = check_buffer(idForCheck, tabPackType, tabExpNbDesc, tabExpNbDrift, tabExpNbAsc, a_decoderId, cyNum, 0);
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

% sort rank numbers according to SBD date
% to compare CSV output (SHOULD NOT BE USED TO PROCESS NC DATA!)
% rank = 1;
% rankDoneList = [];
% for idL = 1:length(tabRank)
%    if (tabRank(idL) ~= -1)
%       if (isempty(rankDoneList) || ~any(rankDoneList(:,1) == tabRank(idL)))
%          tabRankByDate(idL) = rank;
%          rankDoneList = [rankDoneList; tabRank(idL) rank];
%          rank = rank + 1;
%       else
%          tabRankByDate(idL) = rankDoneList(find(rankDoneList(:,1) == tabRank(idL), 1), 2);
%       end
%    end
% end

% specific
if (ismember(g_decArgo_floatNum, [ ...
      6903772, 6903773, 3902137, 6903865, 6903264, 6903698, 6903771, 7900543, ...
      6900790, 6901880, 6903229, 6903795, 6903703]))
   switch g_decArgo_floatNum
      case 6903772
         % the float have been set to EOL at cycle #99, however the data of this
         % cycle has been sent twice
         id = find((tabCyNum == 99) & (tabPackType == 0));
         id = find(tabSession == tabSession(id(2)));
         tabDeep(id) = 0;
         id = find((tabSession == tabSession(id(2))) & (tabPackType == 3));
         tabRank(id) = -1;
         tabRankByCycle(id) = -1;
         tabRankByDate(id) = -1;
      case 6903773
         % the float has switched to EOL at cycle #87, however the data of this
         % cycle has been sent twice
         id = find((tabCyNum == 87) & (tabPackType == 0));
         id = find(tabSession == tabSession(id(2)));
         tabDeep(id) = 0;
         id = find((tabSession == tabSession(id(2))) & (tabPackType == 3));
         tabRank(id) = -1;
         tabRankByCycle(id) = -1;
         tabRankByDate(id) = -1;
      case 3902137
         % the float has switched to EOL at cycle #465, however the data of this
         % cycle has been sent twice
         id = find((tabCyNum == 465) & (tabPackType == 0));
         id = find(tabSession == tabSession(id(2)));
         tabDeep(id) = 0;
         id = find((tabSession == tabSession(id(2))) & (ismember(tabPackType, [1 2 3 13 14])));
         tabRank(id) = -1;
         tabRankByCycle(id) = -1;
         tabRankByDate(id) = -1;
      case 6903865
         % cycle #58 data are separated
         id = find((tabCyNum == 58) & (tabBase == 1));
         tabRank(tabCyNum == 58) = tabRank(id);
         tabRankByCycle(tabCyNum == 58) = tabRankByCycle(id);
         tabRankByDate(tabCyNum == 58) = tabRankByDate(id);   
      case 6903264
         % data of last cycle before EOL (#500) is transmitted twice
         id = find((tabCyNum == 500) & (tabBase == 1));
         id = id(2);
         tabDeep(tabSession == tabSession(id)) = 0;
         idDel = find((tabSession == tabSession(id)) & ismember(tabPackType, [2 3 13 14]));
         tabRank(idDel) = -1;
         tabRankByCycle(idDel) = -1;
         tabRankByDate(idDel) = -1;
      case 6903698
         % data packets transmitted twice in the first EOL session
         idBase = find(tabEolFlag ==1, 1, 'first');
         tabDeep(tabSession == tabSession(idBase)) = 0;
         idDel = find((tabSession == tabSession(idBase)) & ~ismember(tabPackType, [0 4 5]));
         tabRank(idDel) = -1;
         tabRankByCycle(idDel) = -1;
         tabRankByDate(idDel) = -1;
      case 6903771
         % tech#1, tech#2 and prog#1 packets are transmitted twice at cycle #60
         idDel = find((tabCyNum == 60) & (tabPackType == 0), 1, 'first');
         id = find((tabCyNum == 60) & (tabPackType == 4), 1, 'first');
         idDel = [idDel id];
         id = find((tabCyNum == 60) & (tabPackType == 5), 1, 'first');
         idDel = [idDel id];
         tabRank(idDel) = -1;
         tabRankByCycle(idDel) = -1;
         tabRankByDate(idDel) = -1;
      case 7900543
         % cycle #42 data are separated
         id = find((tabCyNum == 42) & (tabBase == 1));
         id = id(1);
         tabRank(tabCyNum == 42) = tabRank(id);
         tabRankByCycle(tabCyNum == 42) = tabRankByCycle(id);
         tabRankByDate(tabCyNum == 42) = tabRankByDate(id);   
         tabDeep(tabCyNum == 42) = 1;   
         % cycle #59 data are separated
         id = find((tabCyNum == 59) & (tabBase == 1));
         id = id(1);
         tabRank(tabCyNum == 59) = tabRank(id);
         tabRankByCycle(tabCyNum == 59) = tabRankByCycle(id);
         tabRankByDate(tabCyNum == 59) = tabRankByDate(id);   
         % cycle #62 data are separated
         id = find((tabCyNum == 62) & (tabBase == 1));
         id = id(1);
         tabRank(tabCyNum == 62) = tabRank(id);
         tabRankByCycle(tabCyNum == 62) = tabRankByCycle(id);
         tabRankByDate(tabCyNum == 62) = tabRankByDate(id);   
      case 6900790
         % cycle #107 data are separated
         id = find((tabCyNum == 107) & (tabBase == 1));
         id = id(1);
         tabRank(tabCyNum == 107) = tabRank(id);
         tabRankByCycle(tabCyNum == 107) = tabRankByCycle(id);
         tabRankByDate(tabCyNum == 107) = tabRankByDate(id);   
         tabDeep(tabCyNum == 107) = 1;
         tabDelayed(tabCyNum == 107) = 1;
      case 6901880
         % cycle #101 in 2 sessions
         idF101 = find(tabCyNum == 101);
         sessions = unique(tabSession(idF101));
         id = find((tabCyNum == 101) & (tabSession == sessions(2)));
         tabRank(id) = tabRank(idF101(1));
         tabRankByCycle(id) = tabRankByCycle(idF101(1));
         tabRankByDate(id) = tabRankByDate(idF101(1)); 
      case 6903229
         % cycle #120 in 2 sessions
         idRef120 = find((tabCyNum == 120) & (tabBase == 1));
         idRef120 = idRef120(1);
         idF120 = find(tabCyNum == 120);
         tabRank(idF120) = tabRank(idRef120);
         tabRankByCycle(idF120) = tabRankByCycle(idRef120);
         tabRankByDate(idF120) = tabRankByDate(idRef120); 
      case 6903795
         % cycle #57 set EOL cmd => data transmitted twice (float recovered)
         idStart = find((tabCyNum == 57) & (tabEolFlag == 1) & (tabPackType == 0));
         idStart = idStart(1);
         idStop = find((tabCyNum == 57) & (tabDeep == 0) & (tabPackType == 0));
         idStop = idStop(1) - 1;
         tabRank(idStart:idStop) = -1;
         tabRankByCycle(idStart:idStop) = -1;
         tabRankByDate(idStart:idStop) = -1;

         % 2 Prog #2 packets in one EOL buffer
         idType7 = find((tabCyNum == 57) & (tabPackType == 7));
         nbElts = hist(tabRank(idType7), unique(tabRank(idType7)));
         idF = find(nbElts > 1);
         tabRank(idType7(idF)) = -1;
         tabRankByCycle(idType7(idF)) = -1;
         tabRankByDate(idType7(idF)) = -1;
      case 6903703
         % cycle #114 set EOL cmd => data transmitted twice (float recovered)
         idStart = find((tabCyNum == 114) & (tabEolFlag == 1) & (tabPackType == 0));
         idStart = idStart(1);
         idStop = find((tabCyNum == 114) & (tabDeep == 0) & (tabPackType == 0));
         idStop = idStop(1) - 1;
         tabRank(idStart:idStop) = -1;
         tabRankByCycle(idStart:idStop) = -1;
         tabRankByDate(idStart:idStop) = -1;
         % during EOL some transmissions are with multiple PARAM packets
         idF = find(tabEolFlag == 1);
         for id = 1:length(idF)
            idProg1 = find((tabRank == tabRank(idF(id))) & (tabPackType == 5));
            if (length(idProg1) > 1)
               tabRank(idProg1(2:end)) = -1;
               tabRankByCycle(idProg1(2:end)) = -1;
               tabRankByDate(idProg1(2:end)) = -1;
            end
            idProg2 = find((tabRank == tabRank(idF(id))) & (tabPackType == 7));
            if (length(idProg2) > 1)
               tabRank(idProg2(2:end)) = -1;
               tabRankByCycle(idProg2(2:end)) = -1;
               tabRankByDate(idProg2(2:end)) = -1;
            end
         end
   end

   % UNCOMMENT TO SEE UPDATED INFORMATION ON BUFFERS
%    if (~isempty(g_decArgo_outputCsvFileId))
% 
%       % update tabCompleted array
%       cyNumList = unique(tabRankByCycle);
%       cyNumList(cyNumList < 0) = [];
%       for cyNum = 1:length(cyNumList)
%          idForCheck = find(tabRankByCycle == cyNumList(cyNum));
% 
%          % check current session contents
%          [completed, deep, ~] = check_buffer(idForCheck, tabPackType, tabExpNbDesc, tabExpNbDrift, tabExpNbAsc, a_decoderId, cyNum, 0);
%          if (completed == 1)
%             tabCompleted(idForCheck) = 1;
%          end
%       end
%    end
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
            [~, ~, why] = check_buffer(idForRankCy, tabPackType, tabExpNbDesc, tabExpNbDrift, tabExpNbAsc, a_decoderId, cyNum, 1);
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
tabRankByDateCell = num2cell(tabRankByDate);
[o_decodedData.rankByDate] = deal(tabRankByDateCell{:});
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
         
         header = '#;Rank;RnkByCycle;RnkByDate;Session;SesDeep;Base;Date;DiffDate;Eol;CyNum;Deep;Done;Delayed;Completed;Go;PackType;ExpNbDesc;tabExpNbDrift;tabExpNbAsc;CyNumRaw;ResetDate;ResetFlag;OffsetDate;PackTypeInfo';
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
                        
            fprintf(fId, '%d;%d;%d;%d;%d;%d;%d;%s;%s;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%s;%d;%d;%s\n', ...
               idL, ...
               tabRank(idL), ...
               tabRankByCycle(idL), ...
               tabRankByDate(idL), ...
               tabSession(idL), ...
               tabSessionDeep(idL), ...
               tabBase(idL), ...
               julian_2_gregorian_dec_argo(tabDate(idL)), ...
               diffDate, ...
               tabEolFlag(idL), ...
               tabCyNum(idL), ...
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
%    a_decoderId, a_cycleNum, a_whyFlag)
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
   a_decoderId, a_cycleNum, a_whyFlag)

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
% for 5.47 floats, float parameter message is transmitted only when a parameter
% has been modified
if (a_decoderId == 222)
   idPackProg = -1;
end
idPackDesc = find((a_tabPackType(a_idForCheck) == 1) | (a_tabPackType(a_idForCheck) == 8));
idPackDrift = find((a_tabPackType(a_idForCheck) == 2) | (a_tabPackType(a_idForCheck) == 9));
idPackAsc = find((a_tabPackType(a_idForCheck) == 3) | (a_tabPackType(a_idForCheck) == 10));

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
   case {212, 222, 214, 217}
      switch (a_packType)
         case 0
            o_packTypeDesc = 'Tech#1';
         case {1, 8}
            o_packTypeDesc = 'Desc meas';
         case {2, 9}
            o_packTypeDesc = 'Drift meas';
         case {3, 10}
            o_packTypeDesc = 'Asc meas';
         case 4
            o_packTypeDesc = 'Tech#2';
         case 5
            o_packTypeDesc = 'Prog#1';
         case 6
            o_packTypeDesc = 'Hydrau';
         case 7
            o_packTypeDesc = 'Prog#2';
         case {11, 13}
            o_packTypeDesc = 'NS meas';
         case {12, 14}
            o_packTypeDesc = 'IA meas';
         otherwise
            fprintf('WARNING: Unknown packet type #%d for decoderId #%d\n', ...
               a_packType, a_decoderId);
      end
   case {216}
      switch (a_packType)
         case 0
            o_packTypeDesc = 'Tech#1';
         case {1, 8}
            o_packTypeDesc = 'Desc meas';
         case {2, 9}
            o_packTypeDesc = 'Drift meas';
         case {3, 10}
            o_packTypeDesc = 'Asc meas';
         case 4
            o_packTypeDesc = 'Tech#2';
         case 5
            o_packTypeDesc = 'Prog';
         case 6
            o_packTypeDesc = 'Valve';
         case 7
            o_packTypeDesc = 'Pump';
         case {11, 13}
            o_packTypeDesc = 'NS meas';
         case {12, 14}
            o_packTypeDesc = 'IA meas';
         otherwise
            fprintf('WARNING: Unknown packet type #%d for decoderId #%d\n', ...
               a_packType, a_decoderId);
      end
   case {218}
      switch (a_packType)
         case 0
            o_packTypeDesc = 'Tech#1';
         case {1, 8}
            o_packTypeDesc = 'Desc meas';
         case {2, 9}
            o_packTypeDesc = 'Drift meas';
         case {3, 10}
            o_packTypeDesc = 'Asc meas';
         case 4
            o_packTypeDesc = 'Tech#2';
         case 5
            o_packTypeDesc = 'Prog#1';
         case 6
            o_packTypeDesc = 'Hydrau';
         case 7
            o_packTypeDesc = 'Prog#2';
         case {11, 13}
            o_packTypeDesc = 'NS meas';
         case {12, 14}
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
