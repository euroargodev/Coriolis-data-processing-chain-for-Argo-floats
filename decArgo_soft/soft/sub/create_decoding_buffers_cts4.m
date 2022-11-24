% ------------------------------------------------------------------------------
% Create decoding buffers.
%
% SYNTAX :
%  [o_decodedData] = create_decoding_buffers_cts4(a_decodedData, a_decoderId)
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
%   01/10/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decodedData] = create_decoding_buffers_cts4(a_decodedData, a_decoderId)

% output parameters initialization
o_decodedData = [];

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% configuration values
global g_decArgo_dirOutputCsvFile;
global g_decArgo_processRemainingBuffers;

% cycle phases
global g_decArgo_phaseSurfWait;
global g_decArgo_phaseSatTrans;

% ICE float firmware
global g_decArgo_floatFirmware;

% global default values
global g_decArgo_dateDef;


% maximum number of transmission sessions (after deep cycle) to look for
% expected data
NB_SESSION_MAX = 3;

tabDate = [a_decodedData.fileDate];
tabDiffDate = [-1 diff(tabDate)];
tabCyProfPhaseList = {a_decodedData.cyProfPhaseList};
tabCyNumOut = [a_decodedData.cyNumOut];
tabCyNumFile = [a_decodedData.cyNumFile];
tabCyNumRaw = [a_decodedData.cyNumRaw];
tabProfNumRaw = [a_decodedData.profNumRaw];
tabPhaseNumRaw = [a_decodedData.phaseNumRaw];
tabCyNum = tabCyNumRaw*100 + tabProfNumRaw;
tabPackType = [a_decodedData.packType];
tabSensorType = [a_decodedData.sensorType];
tabSensorDataType = [a_decodedData.sensorDataType];
tabExpNbDesc = [a_decodedData.expNbDesc];
tabExpNbDrift = [a_decodedData.expNbDrift];
tabExpNbAsc = [a_decodedData.expNbAsc];

tabRankByCycle = ones(size(tabPackType))*-1;
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
% SET SESSION NUMBERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set a session number for each SBD
startId = find(tabPackType == 253, 1);
sesNum = 1;
stop = 0;
while (~stop)
   stopId = find( ...
      (tabPackType == 253) & ...
      (tabCyNum >= tabCyNum(startId)) & ...
      (tabDate > (tabDate(startId))) ...
      , 1);
   if (~isempty(stopId))
      tabSession(startId:stopId-1) = sesNum;
      tabBase(startId) = 1;
      if (tabPhaseNumRaw(startId) == g_decArgo_phaseSatTrans)
         tabDeep(startId:stopId-1) = 1;
      else
         tabDeep(startId:stopId-1) = 0;
      end
      sesNum = sesNum + 1;
      startId = stopId;
   else
      tabSession(startId:end) = sesNum;
      tabBase(startId) = 1;
      if (tabPhaseNumRaw(startId) == g_decArgo_phaseSatTrans)
         tabDeep(startId:end) = 1;
      else
         tabDeep(startId:end) = 0;
      end
      stop = 1;
   end
end

% specific
if (ismember(a_decoderId, [111, 113]))
   % sensor parameter packets of surface cycle have a bad cycle number
   % (cycle number + 1 would be expected)
   idSurfSensorParam = find((tabPackType == 249) & (tabPhaseNumRaw == g_decArgo_phaseSurfWait));
   tabCyNum(idSurfSensorParam) = (tabCyNumRaw(idSurfSensorParam)+1)*100 + tabProfNumRaw(idSurfSensorParam);
end
if (ismember(g_decArgo_floatNum, ...
      [2902263, 6903240, 6903549, 6903551, 2902239, 2902264, 6903550, 3902122, 2902241, 6903026]))
   switch g_decArgo_floatNum
      case 6903026
         % cycle #54 and #55 are transmitted together => set the second one to a
         % different transmission session
         startId54 = find((tabCyNumRaw == 54) & (tabProfNumRaw == 0) & (tabPackType == 253) & (tabPhaseNumRaw == g_decArgo_phaseSatTrans));
         stopId54 = find((tabCyNumRaw == 54) & (tabProfNumRaw == 0) & (tabPackType == 250), 1, 'last');

         startId55 = find((tabCyNumRaw == 55) & (tabProfNumRaw == 0) & (tabPackType == 253) & (tabPhaseNumRaw == g_decArgo_phaseSatTrans));
         stopId55 = find((tabCyNumRaw == 55) & (tabProfNumRaw == 0) & (tabPackType == 248));
         
         tabSession(startId55:end) = tabSession(startId55:end) + 1;
         tabBase(startId55) = 1;
         tabDeep(startId55:stopId55) = 1;
         
         a_decodedData(startId55).cyProfPhaseList(6) = a_decodedData(startId54).cyProfPhaseList(6);
         for id = startId54:stopId54
            a_decodedData(id).cyProfPhaseList(6) = g_decArgo_dateDef;
         end
         
      case 2902263
         idF = find((tabCyNumRaw == 48) & (tabProfNumRaw == 0) & ismember(tabPackType, [248 254 255]));
         tabCyNum(idF) = tabCyNumRaw(idF)*100 + tabProfNumRaw(idF) + 1;
         
      case 6903240
         idF = find((tabCyNumRaw == 2) & (tabProfNumRaw == 0) & (tabPackType == 250) & (tabSensorType == 6));
         tabExpNbDesc(idF) = 338 - 256;
         idF = find((tabCyNumRaw == 3) & (tabProfNumRaw == 0) & (tabPackType == 250) & (tabSensorType == 6));
         tabExpNbDesc(idF) = 316 - 256;
         idF = find((tabCyNumRaw == 4) & (tabProfNumRaw == 0) & (tabPackType == 250) & (tabSensorType == 6));
         tabExpNbDesc(idF) = 346 - 256;
         idF = find((tabCyNumRaw == 5) & (tabProfNumRaw == 0) & (tabPackType == 250) & (tabSensorType == 6));
         tabExpNbDesc(idF) = 336 - 256;
         idF = find((tabCyNumRaw == 6) & (tabProfNumRaw == 0) & (tabPackType == 250) & (tabSensorType == 6));
         tabExpNbDesc(idF) = 358 - 256;
         idF = find((tabCyNumRaw == 7) & (tabProfNumRaw == 0) & (tabPackType == 250) & (tabSensorType == 6));
         tabExpNbDesc(idF) = 258 - 256;
         idF = find((tabCyNumRaw == 8) & (tabProfNumRaw == 0) & (tabPackType == 250) & (tabSensorType == 6));
         tabExpNbDesc(idF) = 278 - 256;
         
      case 6903549
         startId = find((tabDate == gregorian_2_julian_dec_argo('2019/12/21 11:50:59')) & (tabPhaseNumRaw == g_decArgo_phaseSatTrans));
         stopId = find(tabSession == tabSession(startId), 1, 'last');
         tabSession(startId:end) = tabSession(startId:end) + 1;
         tabBase(startId) = 1;
         tabDeep(startId:stopId) = 1;
         
         startId44 = find((tabDate == gregorian_2_julian_dec_argo('2019/12/21 11:42:25')) & (tabPhaseNumRaw == g_decArgo_phaseSatTrans));
         stopId44 = find(tabSession == (tabSession(startId44)+1), 1, 'last');
         a_decodedData(startId).cyProfPhaseList(6) = a_decodedData(startId44).cyProfPhaseList(6);
         for id = startId44:stopId44
            a_decodedData(id).cyProfPhaseList(6) = g_decArgo_dateDef;
         end
         
      case 6903551
         startId = find((tabDate == gregorian_2_julian_dec_argo('2019/12/21 11:49:41')) & (tabPhaseNumRaw == g_decArgo_phaseSatTrans));
         stopId = find(tabSession == tabSession(startId), 1, 'last');
         tabSession(startId:end) = tabSession(startId:end) + 1;
         tabBase(startId) = 1;
         tabDeep(startId:stopId) = 1;
         
         startId43 = find((tabDate == gregorian_2_julian_dec_argo('2019/12/21 11:43:56')) & (tabPhaseNumRaw == g_decArgo_phaseSatTrans));
         stopId43 = find(tabSession == (tabSession(startId43)+1), 1, 'last');
         a_decodedData(startId).cyProfPhaseList(6) = a_decodedData(startId43).cyProfPhaseList(6);
         for id = startId43:stopId43
            a_decodedData(id).cyProfPhaseList(6) = g_decArgo_dateDef;
         end
         
         idF = find(tabSession >= 129);
         tabSession(idF) = tabSession(idF) + 1;
         idF = find(((tabSession == 128) & (tabCyNum == 6500) & (tabPackType == 253) & (tabPhaseNumRaw == g_decArgo_phaseSatTrans)) | ...
            ((tabSession == 128) & (tabCyNum == 6500) & (tabPackType == 252) & (tabPhaseNumRaw ~= g_decArgo_phaseSurfWait)) | ...
            ((tabSession == 128) & (tabCyNum == 6500) & (tabPackType ~= 253) & (tabPackType ~= 252)));
         tabSession(idF) = 129;
         tabBase(idF(1)) = 1;
         tabDeep(idF) = 1;
         
         idF = find(ismember(tabSession, 127:130));
         for id = idF
            a_decodedData(id).cyProfPhaseList(6) = g_decArgo_dateDef;
         end
         
         % two following cycle numbers are set only to avoid unused packets in
         % the log file (these packet are not used because we don't know the
         % reference date used in a "surface waiting period" phase to date a
         % buoyancy action)
         tabCyNum(18972:18973) = 6400;
         tabCyNum(19275:19276) = 6500;
         
         % buoyancy action during the "surface session" data transmitted for an
         % Ice deep cycle => unused
         tabCyNum(21355:21356) = 7200;
         tabCyNum(21662:21663) = 7300;
         % FMT/LMT are erroneous in such case
         idF = find(ismember(tabSession, [143:148]));
         for id = idF
            a_decodedData(id).cyProfPhaseList(6) = g_decArgo_dateDef;
         end
         
         % cycle 118 to 121 are transmitted together
         tabBase(35408) = 1;
         tabSession(35408:end) = tabSession(35408:end) + 1;
         tabDeep(35408:35707) = 1;

         tabBase(35718) = 1;
         tabSession(35718:end) = tabSession(35718:end) + 1;
         tabDeep(35718:36008) = 1;

         tabBase(36019) = 1;
         tabSession(36019:end) = tabSession(36019:end) + 1;
         tabDeep(36019:36313) = 1;
      
         % FMT/LMT are erroneous in such case
         for id = 35109:36018
            a_decodedData(id).cyProfPhaseList(6) = g_decArgo_dateDef;
         end
         
         % three following cycle numbers are set only to avoid unused packets in
         % the log file (these packet are not used because we don't know the
         % reference date used in a "surface waiting period" phase to date a
         % buoyancy action)
         tabDone(35399:35400) = 1;
         tabDone(35709:35710) = 1;
         tabDone(36010:36011) = 1;

      case 2902239
         startId = find(tabDate == gregorian_2_julian_dec_argo('2019/01/15 18:11:13'), 1, 'first');
         stopId = find(tabDate == gregorian_2_julian_dec_argo('2019/01/15 18:11:13'), 1, 'last');
         tabSession(startId:end) = tabSession(startId:end) + 1;
         tabBase(startId) = 1;
         tabDeep(startId:stopId) = 0;
         
         startId = find((tabDate == gregorian_2_julian_dec_argo('2019/12/21 17:50:38')) & (tabPhaseNumRaw == g_decArgo_phaseSatTrans));
         stopId = find(tabSession == tabSession(startId), 1, 'last');
         tabSession(startId:end) = tabSession(startId:end) + 1;
         tabBase(startId) = 1;
         tabDeep(startId:stopId) = 1;
         
         startId158 = find((tabDate == gregorian_2_julian_dec_argo('2019/12/21 17:49:37')) & (tabPhaseNumRaw == g_decArgo_phaseSatTrans));
         stopId158 = find(tabSession == (tabSession(startId158)+1), 1, 'last');
         a_decodedData(startId).cyProfPhaseList(6) = a_decodedData(startId158).cyProfPhaseList(6);
         for id = startId158:stopId158
            a_decodedData(id).cyProfPhaseList(6) = g_decArgo_dateDef;
         end
         
      case 2902264
         startId = find((tabDate == gregorian_2_julian_dec_argo('2019/12/21 17:54:48')) & (tabPhaseNumRaw == g_decArgo_phaseSatTrans));
         stopId = find(tabSession == tabSession(startId), 1, 'last');
         tabSession(startId:end) = tabSession(startId:end) + 1;
         tabBase(startId) = 1;
         tabDeep(startId:stopId) = 1;
         
         startId125 = find((tabDate == gregorian_2_julian_dec_argo('2019/12/21 17:53:45')) & (tabPhaseNumRaw == g_decArgo_phaseSatTrans));
         stopId125 = find(tabSession == (tabSession(startId125)+1), 1, 'last');
         a_decodedData(startId).cyProfPhaseList(6) = a_decodedData(startId125).cyProfPhaseList(6);
         for id = startId125:stopId125
            a_decodedData(id).cyProfPhaseList(6) = g_decArgo_dateDef;
         end
         
      case 6903550
         startId = find((tabDate == gregorian_2_julian_dec_argo('2019/12/22 12:04:36')) & (tabPhaseNumRaw == g_decArgo_phaseSatTrans));
         
         startId44 = find((tabDate == gregorian_2_julian_dec_argo('2019/12/22 11:56:25')) & (tabPhaseNumRaw == g_decArgo_phaseSatTrans));
         stopId44 = find(tabSession == (tabSession(startId44)+1), 1, 'last');
         a_decodedData(startId).cyProfPhaseList(6) = a_decodedData(startId44).cyProfPhaseList(6);
         for id = startId44:stopId44
            a_decodedData(id).cyProfPhaseList(6) = g_decArgo_dateDef;
         end
         
      case 3902122
         % transmission of second Iridium session of cycle 192, 0 failed => data
         % transmitted with cycle 193, 0 ones
         
         % separate the data
         startId = find((tabDate == gregorian_2_julian_dec_argo('2020/02/01 14:06:08')) & (tabPhaseNumRaw == g_decArgo_phaseSatTrans));
         stopId = find(tabSession == tabSession(startId), 1, 'last');
         tabSession(startId:end) = tabSession(startId:end) + 1;
         tabBase(startId) = 1;
         tabDeep(startId:stopId) = 1;
         
         % update sbd file dates for FMT and LMT
         stopId192_1 = find((tabDate == gregorian_2_julian_dec_argo('2020/01/27 10:15:59')), 1, 'last');
         startId192_2 = find((tabDate == gregorian_2_julian_dec_argo('2020/02/01 14:06:08')) & (tabPhaseNumRaw == g_decArgo_phaseSurfWait));
         stopId192_2 = find(tabSession == tabSession(startId192_2), 1, 'last');
         for id = startId192_2:stopId192_2
            a_decodedData(id).cyProfPhaseList(6) = a_decodedData(stopId192_1).cyProfPhaseList(6);
         end
         
      case 2902241
         % error in transmitted data
         idDel = find((tabSession == 373) & (tabCyNum ~= 18600));
         tabDone(idDel) = 1;
         
         idDel = find((tabSession == 374) & (tabCyNum ~= 18600) & (tabBase == 0));
         tabDone(idDel) = 1;
         idDel = find((tabSession == 374) & (tabCyNum == 18600) & (tabPackType == 0));
         tabDone(idDel) = 1;
                  
   end
end

% modify cycle number of the second Iridum session expected files
idSurf = find((tabDeep == 0) & ismember(tabPackType, [248 249 253 254 255]));
tabCyNum(idSurf) = max(((tabCyNum(idSurf)/100)-1), 0)*100 + tabProfNumRaw(idSurf);

% consider only session after a deep cycle (to use NB_SESSION_MAX)
tabSessionDeep = tabSession;
sessionList = unique(tabSession);
for sesNum = sessionList
   idForSession = find(tabSession == sesNum);
   if (~any(ismember(tabPackType(idForSession), [0 252]))) % transmission after a deep cycle
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
         
   idBaseForSession = find((tabSession == sesNum) & (tabBase == 1) & (tabDone == 0), 1);
   if (tabPhaseNumRaw(idBaseForSession) == g_decArgo_phaseSatTrans)
      % deep session
      idForCheck = find((tabSession == sesNum) & (tabCyNum == tabCyNum(idBaseForSession)) & (tabDone == 0));
      deepExpected = 1;
   else
      % surface session
      idForCheck = find((tabSession == sesNum) & ismember(tabCyNum, [tabCyNum(idBaseForSession)-100 tabCyNum(idBaseForSession)]) & (tabDone == 0));
      deepExpected = 0;
   end
   
   % check current session contents
   [completed, deep, ~] = check_buffer(idForCheck, tabPackType, tabPhaseNumRaw, tabSensorType, tabSensorDataType, tabExpNbDesc, tabExpNbDrift, tabExpNbAsc, 0);
   delayed = 0;
   
   if ((completed == 1) && (deep ~= deepExpected))
      fprintf('\nINFO: Float #%d : session number %d : no measurement during deep cycle\n\n', ...
         g_decArgo_floatNum, sesNum);
   end
   
   % TO BE CHECKED AND UPDATED ONCE FIRST DELAYED TRANSMISSION OCCUR
   %    % check data of following sessions (to get possibly unexpected packets such
   %    % as pump or valve packets)
   %    sessionListBis = sessionList(find(sessionList > sesNum));
   %    if (any(ismember(tabSession, sessionListBis) & (tabCyNum == cyNum)))
   %       idRemaining = find(ismember(tabSession, sessionListBis) & (tabCyNum == cyNum));
   %       idStop = find(ismember(tabPackType(idRemaining), [0 4 5]), 1, 'first');
   %       if (~isempty(idStop))
   %          idRemaining = idRemaining(1:idStop-1);
   %       end
   %       if (~isempty(idRemaining))
   %          delayed = 2;
   %          idForCheck = [idForCheck idRemaining];
   %          [completed, deep, ~] = check_buffer(idForCheck, tabPackType, tabExpNbDesc, tabExpNbDrift, tabExpNbAsc, 0);
   %       end
   %    end
   
   if (completed == 1)
      tabRank(idForCheck) = rank;
      rank = rank + 1;
      %       tabDeep(idForCheck) = deep;
      tabDone(idForCheck) = 1;
      tabDelayed(idForCheck) = delayed;
      tabCompleted(idForCheck) = 1;
      tabGo(idForCheck) = 1;
   else
      sesNumDeep = min(tabSessionDeep(idForCheck));
      if ((max(tabSessionDeep) - sesNumDeep) >= NB_SESSION_MAX-1)
         tabRank(idForCheck) = rank;
         rank = rank + 1;
         %          tabDeep(idForCheck) = deep;
         tabDone(idForCheck) = 1;
         tabDelayed(idForCheck) = delayed;
         tabCompleted(idForCheck) = 0;
         tabGo(idForCheck) = 1;
      else
         %          tabDeep(idForCheck) = deep;
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

% TO BE CHECKED AND UPDATED ONCE FIRST DELAYED TRANSMISSION OCCUR
% % process the remaining SBD
% for sesNum = sessionList
%    idForSession = find((tabSession == sesNum) & (tabDone == 0));
%    if (~isempty(idForSession))
%       cyNumList = unique(tabCyNum(idForSession));
%       for cyNum = cyNumList
%                   
%          idForCheck = find((tabSession == sesNum) & (tabCyNum == cyNum));
%          
%          % check current session contents
%          [completed, deep, ~] = check_buffer(idForCheck, tabPackType, tabExpNbDesc, tabExpNbDrift, tabExpNbAsc, 0);
%          
%          % check data of following sessions (to get possibly unexpected data such
%          % as pump or valve packets)
%          sessionListBis = sessionList(find(sessionList > sesNum));
%          if (any(ismember(tabSession, sessionListBis) & (tabCyNum == cyNum)))
%             idRemaining = find(ismember(tabSession, sessionListBis) & (tabCyNum == cyNum));
%             idStop = find(ismember(tabPackType(idRemaining), [0 4 5]), 1, 'first');
%             if (~isempty(idStop))
%                idRemaining = idRemaining(1:idStop-1);
%             end
%             if (~isempty(idRemaining))
%                idForCheck = [idForCheck idRemaining];
%                [completed, deep, ~] = check_buffer(idForCheck, tabPackType, tabExpNbDesc, tabExpNbDrift, tabExpNbAsc, 0);
%             end
%          end
%          
%          if (completed == 1)
%             tabRank(idForCheck) = rank;
%             rank = rank + 1;
%             tabDeep(idForCheck) = deep;
%             tabDone(idForCheck) = 1;
%             tabDelayed(idForCheck) = 1;
%             tabCompleted(idForCheck) = 1;
%             tabGo(idForCheck) = 1;
%          else
%             sesNumDeep = min(tabSessionDeep(idForCheck));
%             if ((max(tabSessionDeep) - sesNumDeep) >= NB_SESSION_MAX-1)
%                tabRank(idForCheck) = rank;
%                rank = rank + 1;
%                tabDeep(idForCheck) = deep;
%                tabDone(idForCheck) = 1;
%                tabDelayed(idForCheck) = 1;
%                tabCompleted(idForCheck) = 0;
%                tabGo(idForCheck) = 1;
%             else
%                tabDeep(idForCheck) = deep;
%                tabDone(idForCheck) = 1;
%                if (g_decArgo_processRemainingBuffers)
%                   tabRank(idForCheck) = rank;
%                   rank = rank + 1;
%                   tabDelayed(idForCheck) = 1;
%                   tabCompleted(idForCheck) = 0;
%                   tabGo(idForCheck) = 2;
%                end
%             end
%          end
%       end
%    end
% end

% specific
if (ismember(a_decoderId, [111, 113]))
   % sensor tech packets are transmitted again during surface cycle (remove
   % it from decoding buffers)
   idSurfSensorTech = find((tabPackType == 250) & (tabDeep == 0) & (tabCyNum > 0));
   tabRank(idSurfSensorTech) = -1;
end
if (ismember(g_decArgo_floatNum, ...
      [6903249 6902906]))
   switch g_decArgo_floatNum

      case 6903249
         % cycle #184 is ok for vector timings but without any measurements +
         % TECH packets of the OCR don't have the expected length => ignore TECH
         % packets of OCR sensor
         idSession = find((tabCyNum == 18400) & (tabPhaseNumRaw == 12));
         idDel = find((tabSession == tabSession(idSession)) & (tabSensorType == 2));
         tabRank(idDel) = -1;
         
      case 6902906
         % during first and second Iridium session of cycle #115, 0, thefloat
         % transmitted old memorized data
         idSession = find((tabCyNumRaw == 115) & (tabProfNumRaw == 0) & (tabPhaseNumRaw == 12));
         idDel = find((tabSession == tabSession(idSession)) & (tabCyNumRaw ~= 115));
         tabRank(idDel) = -1;
         tabDone(idDel) = 1;

         idSession = find((tabCyNumRaw == 116) & (tabProfNumRaw == 0) & (tabPhaseNumRaw == 1));
         idDel = find((tabSession == tabSession(idSession)) & ...
            ~((tabCyNumRaw == 116) | ((tabCyNumRaw == 115) & (tabPackType == 250))));
         tabRank(idDel) = -1;
         tabDone(idDel) = 1;
   
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WRITE CYCLE INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check received data
fprintf('BUFF_INFO: Float #%d : FIRMWARE VERSION : %s\n', ...
   g_decArgo_floatNum, g_decArgo_floatFirmware);

% check that all SBD files are used
if (any(tabDone == 0))
   fprintf('\nERROR: Float #%d : %d SBD files are not used\n\n', ...
      g_decArgo_floatNum, length(find(tabDone == 0)));
end

% create list of expected cycle numbers
cyNumList = [];
for cyNum = 0:max(fix(tabCyNum/100))
   cyMin = cyNum*100;
   cyNumList = [cyNumList cyMin];
   cyMax = max(tabCyNum(find((tabCyNum >= cyMin) & (tabCyNum < cyMin+100))));
   cyNumList = [cyNumList cyMin:cyMax];
end
cyNumList = unique(cyNumList);
cyNumOut = 0:length(cyNumList)-1;
for idCy = 1:length(cyNumList)
   cyNum = cyNumList(idCy);
   idForCy = find(tabCyNum == cyNum);
   if (isempty(idForCy))
      fprintf('BUFF_INFO: Float #%d Cycle #%3d: FloatCy #%3d FloatProf #%2d: - NO DATA\n', ...
         g_decArgo_floatNum, cyNumOut(idCy), fix(cyNum/100), cyNum-fix(cyNum/100)*100);
   else
      rankNumList = setdiff(unique(tabRank(idForCy), 'stable'), -1);
      for rankNum = rankNumList
         idForRankCy = idForCy(find(tabRank(idForCy) == rankNum));
         tabCyNumOut(idForRankCy) = cyNumOut(idCy);
         idRankCy = idForRankCy(1);
         
         if (tabDeep(idRankCy) == 1)
            deepStr = 'DEEP CYCLE   ';
         elseif (tabDeep(idRankCy) == 0)
            deepStr = 'SURFACE CYCLE';
         end
            
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
         
         fprintf('BUFF_INFO: Float #%d Cycle #%3d: FloatCy #%3d FloatProf #%2d: %4d SBD - %s - %s - %s%s%s\n', ...
            g_decArgo_floatNum, cyNumOut(idCy), fix(cyNum/100), cyNum-fix(cyNum/100)*100, ...
            length(idForRankCy), deepStr, delayedStr, completedStr, sessionListStr, piDecStr);
         
         if (tabCompleted(idRankCy) == 0)
            [~, ~, why] = check_buffer(idForRankCy, ...
               tabPackType, tabPhaseNumRaw, tabSensorType, tabSensorDataType, tabExpNbDesc, tabExpNbDrift, tabExpNbAsc, 1);
            for idL = 1:length(why)
               fprintf('   -> %s\n', why{idL});
            end
         end
      end
   end
end

% output data
o_decodedData = a_decodedData;
tabCyNumOutCell = num2cell(tabCyNumOut);
[o_decodedData.cyNumOut] = deal(tabCyNumOutCell{:});
tabCyNumCell = num2cell(tabCyNum);
[o_decodedData.cyNum] = deal(tabCyNumCell{:});
tabRankByCycleCell = num2cell(tabRankByCycle);
[o_decodedData.rankByCycle] = deal(tabRankByCycleCell{:});
tabDeepCell = num2cell(tabDeep);
[o_decodedData.deep] = deal(tabDeepCell{:});

if (~isempty(g_decArgo_outputCsvFileId))
   if (1)
      % CSV output
      csvFilepathName = [g_decArgo_dirOutputCsvFile '\' num2str(g_decArgo_floatNum) '_buffers_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
      fId = fopen(csvFilepathName, 'wt');
      if (fId ~= -1)
         
         header = '#;Rank;RnkByCycle;Session;SesDeep;Base;Date;DiffDate;CyNumOut;CyNum;CyNumFile;CyNumRaw;ProfNumRaw;PhaseNumRaw;Deep;Done;Delayed;Completed;Go;PackType;SensorType;SensorDataType;ExpNbDesc;tabExpNbDrift;tabExpNbAsc;PackTypeInfo';
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
            
            fprintf(fId, '%d;%d;%d;%d;%d;%d;%s;%s;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%s\n', ...
               idL, ...
               tabRank(idL), ...
               tabRankByCycle(idL), ...
               tabSession(idL), ...
               tabSessionDeep(idL), ...
               tabBase(idL), ...
               julian_2_gregorian_dec_argo(tabDate(idL)), ...
               diffDate, ...
               tabCyNumOut(idL), ...
               tabCyNum(idL), ...
               tabCyNumFile(idL), ...
               tabCyNumRaw(idL), ...
               tabProfNumRaw(idL), ...
               tabPhaseNumRaw(idL), ...
               tabDeep(idL), ...
               tabDone(idL), ...
               tabDelayed(idL), ...
               tabCompleted(idL), ...
               tabGo(idL), ...
               tabPackType(idL), ...
               tabSensorType(idL), ...
               tabSensorDataType(idL), ...
               tabExpNbDesc(idL), ...
               tabExpNbDrift(idL), ...
               tabExpNbAsc(idL), ...
               get_pack_type_desc(tabPackType(idL), tabSensorType(idL), tabSensorDataType(idL), tabPhaseNumRaw(idL), a_decoderId) ...
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
%    a_idForCheck, a_tabPackType, a_tabPhaseNum, a_tabSensorType, a_tabSensorDataType, ...
%    a_tabExpNbDesc, a_tabExpNbDrift, a_tabExpNbAsc, a_whyFlag)
%
% INPUT PARAMETERS :
%   a_idForCheck        : Id list of SBD to be checked
%   a_tabPackType       : SBD packet types
%   a_tabPhaseNum       : SBD packet phase
%   a_tabSensorType     : SBD packet sensor type
%   a_tabSensorDataType : SBD packet sensor data type
%   a_tabExpNbDesc      : expected number of descending data packets
%   a_tabExpNbDrift     : expected number of drift data packets
%   a_tabExpNbAsc       : expected number of ascending data packets
%   a_whyFlag           : if set to 1, print why the buffer is not completed
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
%   01/10/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_completed, o_deep, o_whyStr] = check_buffer( ...
   a_idForCheck, a_tabPackType, a_tabPhaseNum, a_tabSensorType, a_tabSensorDataType, ...
   a_tabExpNbDesc, a_tabExpNbDrift, a_tabExpNbAsc, a_whyFlag)

% output parameter initialization
o_completed = 0;
o_deep = 0;
o_whyStr = '';

% sensor list
global g_decArgo_sensorList;

% cycle phases
global g_decArgo_phasePreMission;
global g_decArgo_phaseSurfWait;
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseDsc2Prof;
global g_decArgo_phaseProfDrift;
global g_decArgo_phaseAscProf;
global g_decArgo_phaseSatTrans;


% check buffer completion
sensorList = g_decArgo_sensorList;
nbSensorTechList = zeros(size(sensorList));
sensorExpNbDesc = ones(size(sensorList))*-1;
sensorExpNbDrift = ones(size(sensorList))*-1;
sensorExpNbAsc = ones(size(sensorList))*-1;
sensorRecNbDesc = zeros(size(sensorList));
sensorRecNbDrift = zeros(size(sensorList));
sensorRecNbAsc = zeros(size(sensorList));

idVectorTech = find(a_tabPackType(a_idForCheck) == 253);
if (~isempty(idVectorTech))
   if (a_tabPhaseNum(a_idForCheck(idVectorTech)) == g_decArgo_phaseSatTrans)
      
      % transmission after a deep cycle
      % we expect:
      % - one float technical packet (253) with phase g_decArgo_phaseSatTrans (#12)
      % - one sensor technical packet (250) for each sensor (two for OCR)
      % - as many measurements (0) as mentionned in the sensor technical packet
      
      for idS = 1:length(sensorList)
         idSensorTech = find((a_tabPackType(a_idForCheck) == 250) & (a_tabSensorType(a_idForCheck) == sensorList(idS)));
         if (~isempty(idSensorTech))
            nbSensorTechList(idS) = length(idSensorTech);
            sensorExpNbDesc(idS) = a_tabExpNbDesc(a_idForCheck(idSensorTech(1)));
            sensorExpNbDrift(idS) = a_tabExpNbDrift(a_idForCheck(idSensorTech(1)));
            sensorExpNbAsc(idS) = a_tabExpNbAsc(a_idForCheck(idSensorTech(1)));
         end
         
         sensorRecNbDesc(idS) = length(find( ...
            (a_tabPackType(a_idForCheck) == 0) & ...
            ismember(a_tabSensorDataType(a_idForCheck), get_sensor_data_type_list(sensorList(idS))) & ...
            ismember(a_tabPhaseNum(a_idForCheck), [g_decArgo_phaseDsc2Prk g_decArgo_phaseDsc2Prof])));
         sensorRecNbDrift(idS) = length(find( ...
            (a_tabPackType(a_idForCheck) == 0) & ...
            ismember(a_tabSensorDataType(a_idForCheck), get_sensor_data_type_list(sensorList(idS))) & ...
            ismember(a_tabPhaseNum(a_idForCheck), [g_decArgo_phaseParkDrift g_decArgo_phaseProfDrift])));
         sensorRecNbAsc(idS) = length(find( ...
            (a_tabPackType(a_idForCheck) == 0) & ...
            ismember(a_tabSensorDataType(a_idForCheck), get_sensor_data_type_list(sensorList(idS))) & ...
            ismember(a_tabPhaseNum(a_idForCheck), [g_decArgo_phaseAscProf])));
         
      end
      
      idSensorOcr = find(sensorList == 2);
      if (~any(nbSensorTechList(setdiff(1:length(sensorList), idSensorOcr)) ~= 1) && ...
            ~any(nbSensorTechList(idSensorOcr) ~= 2) && ...
            ~any(sensorExpNbDesc ~= mod(sensorRecNbDesc, 256)) && ...
            ~any(sensorExpNbDrift ~= mod(sensorRecNbDrift, 256)) && ...
            ~any(sensorExpNbAsc ~= mod(sensorRecNbAsc, 256)))
         o_completed = 1;
         if (any(a_tabPackType(a_idForCheck) == 0))
            o_deep = 1;
         else
            o_deep = 0;
         end
      end
      
      if (a_whyFlag && ~o_completed)
         for idS = 1:length(sensorList)
            if (sensorList(idS) == 2)
               if (nbSensorTechList(idS) ~= 2)
                  o_whyStr{end+1} = sprintf('%d %s sensor tech packet(s) is missing', ...
                     nbSensorTechList(idS)-2, get_sensor_desc(sensorList(idS)));
               end
            else
               if (nbSensorTechList(idS) ~= 1)
                  o_whyStr{end+1} = [get_sensor_desc(sensorList(idS)) ' sensor tech packet is missing'];
               end
            end
         end
         for idS = 1:length(sensorList)
            if (sensorExpNbDesc ~= -1)
               if (sensorExpNbDesc(idS) ~= mod(sensorRecNbDesc(idS), 256))
                  if (sensorExpNbDesc(idS) > mod(sensorRecNbDesc(idS), 256))
                     o_whyStr{end+1} = sprintf('%s: %d descending data packets are MISSING', ...
                        get_sensor_desc(sensorList(idS)), ...
                        sensorExpNbDesc(idS)-mod(sensorRecNbDesc(idS), 256));
                  else
                     o_whyStr{end+1} = sprintf('%s: %d descending data packets are NOT EXPECTED', ...
                        get_sensor_desc(sensorList(idS)), ...
                        -sensorExpNbDesc(idS)-mod(sensorRecNbDesc(idS), 256));
                  end
               end
               if (sensorExpNbDrift(idS) ~= mod(sensorRecNbDrift(idS), 256))
                  if (sensorExpNbDrift(idS) > mod(sensorRecNbDrift(idS), 256))
                     o_whyStr{end+1} = sprintf('%s: %d drift data packets are MISSING', ...
                        get_sensor_desc(sensorList(idS)), ...
                        sensorExpNbDrift(idS)-mod(sensorRecNbDrift(idS), 256));
                  else
                     o_whyStr{end+1} = sprintf('%s: %d drift data packets are NOT EXPECTED', ...
                        get_sensor_desc(sensorList(idS)), ...
                        -sensorExpNbDrift(idS)-mod(sensorRecNbDrift(idS), 256));
                  end
               end
               if (sensorExpNbAsc(idS) ~= mod(sensorRecNbAsc(idS), 256))
                  if (sensorExpNbAsc(idS) > mod(sensorRecNbAsc(idS), 256))
                     o_whyStr{end+1} = sprintf('%s: %d ascending data packets are MISSING', ...
                        get_sensor_desc(sensorList(idS)), ...
                        sensorExpNbAsc(idS)-mod(sensorRecNbAsc(idS), 256));
                  else
                     o_whyStr{end+1} = sprintf('%s: %d ascending data packets are NOT EXPECTED', ...
                        get_sensor_desc(sensorList(idS)), ...
                        -sensorExpNbAsc(idS)-mod(sensorRecNbAsc(idS), 256));
                  end
               end
            end
         end
      end
      
   elseif (a_tabPhaseNum(a_idForCheck(idVectorTech)) == g_decArgo_phasePreMission)
      
      % prelude cycle
      % we expect:
      % - one float technical packet (253) with phase g_decArgo_phasePreMission (#0)
      % - all configuration packets (248, 249, 254, 255)
      
      idRudicsParam = find(a_tabPackType(a_idForCheck) == 248);
      idSensorParam = find(a_tabPackType(a_idForCheck) == 249);
      idPtPgParam = find(a_tabPackType(a_idForCheck) == 254);
      idPvPmParam = find(a_tabPackType(a_idForCheck) == 255);
      if (~isempty(idRudicsParam) && ~isempty(idSensorParam) && ...
            ~isempty(idPtPgParam) && ~isempty(idPvPmParam))
         o_completed = 1;
         o_deep = 0;
      end
      
      if (a_whyFlag && ~o_completed)
         if (~isempty(idRudicsParam))
            o_whyStr{end+1} = 'Rudics parameter packet is missing';
         end
         if (~isempty(idSensorParam))
            o_whyStr{end+1} = 'Sensor parameter packet is missing';
         end
         if (~isempty(idPtPgParam))
            o_whyStr{end+1} = 'PT & PG parameter packet is missing';
         end
         if (~isempty(idPvPmParam))
            o_whyStr{end+1} = 'PV & PM parameter packet is missing';
         end
      end
      
   elseif (a_tabPhaseNum(a_idForCheck(idVectorTech)) == g_decArgo_phaseSurfWait)
      
      % surface cycle
      % we expect:
      % - one float technical packet (253) with phase g_decArgo_phaseSurfWait (#1)
      % - bug of the firmware 3.01: one sensor technical packet (250) for each sensor (two for OCR)
      
      for idS = 1:length(sensorList)
         idSensorTech = find((a_tabPackType(a_idForCheck) == 250) & (a_tabSensorType(a_idForCheck) == sensorList(idS)));
         if (~isempty(idSensorTech))
            nbSensorTechList(idS) = length(idSensorTech);
         end
      end
      
      idSensorOcr = find(sensorList == 2);
      if (~any(nbSensorTechList(setdiff(1:length(sensorList), idSensorOcr)) ~= 1) && ...
            ~any(nbSensorTechList(idSensorOcr) ~= 2))
         o_completed = 1;
         o_deep = 0;
      end
      
      if (a_whyFlag && ~o_completed)
         for idS = 1:length(sensorList)
            if (sensorList(idS) == 2)
               if (nbSensorTechList(idS) ~= 2)
                  o_whyStr{end+1} = sprintf('%d %s sensor tech packet(s) is missing', ...
                     nbSensorTechList(idS)-2, get_sensor_desc(sensorList(idS)));
               end
            else
               if (nbSensorTechList(idS) ~= 1)
                  o_whyStr{end+1} = [get_sensor_desc(sensorList(idS)) ' sensor tech packet is missing'];
               end
            end
         end
      end
      
   end
else
   if (a_whyFlag && ~o_completed)
      o_whyStr{end+1} = 'Vector tech packet is missing - at least (analysis stopped)';
   end
end

return

% ------------------------------------------------------------------------------
% Convert packet type number into description string.
%
% SYNTAX :
%  [o_packTypeDesc] = get_pack_type_desc( ...
%    a_packType, a_sensorType, a_sensorDataType, a_phaseNum, a_decoderId)
%
% INPUT PARAMETERS :
%   a_packType       : packet type number
%   a_sensorType     : packet sensor type number
%   a_sensorDataType : packet sensor data type number
%   a_phaseNum       : packet phase number
%   a_decoderId      : float decoder Id
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
%   01/10/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_packTypeDesc] = get_pack_type_desc( ...
   a_packType, a_sensorType, a_sensorDataType, a_phaseNum, a_decoderId)

% output parameter initialization
o_packTypeDesc = '';

switch (a_decoderId)
   case {111, 113}
      switch (a_packType)
         case 0
            % sensor data
            o_packTypeDesc = ['Data: ' get_data_desc(a_sensorDataType) '- Phase: ' get_phase_desc(a_phaseNum)];
         case 248
            % rudics parameters
            o_packTypeDesc = 'Rudics parameters';
         case 249
            % sensor parameters
            o_packTypeDesc = ['Sensor parameters - Phase: ' get_phase_desc(a_phaseNum)];
         case 250
            % sensor technical data
            o_packTypeDesc = [get_sensor_desc(a_sensorType) ' sensor technical data'];
         case 251
            % PC sensor parameters
            o_packTypeDesc = 'PC sensor parameters';
         case 252
            % vector pressure data
            o_packTypeDesc = ['Vector pressure data - Phase: ' get_phase_desc(a_phaseNum)];
         case 253
            % vector technical data
            o_packTypeDesc = ['Vector technical data - Phase: ' get_phase_desc(a_phaseNum)];
         case 254
            % PT & PG parameters
            o_packTypeDesc = 'PT & PG parameters';
         case 255
            % PV & PM parameters
            o_packTypeDesc = 'PV & PM parameters';
         otherwise
            fprintf('WARNING: Unknown packet type #%d for decoderId #%d\n', ...
               a_packType, a_decoderId);
      end
   otherwise
      fprintf('WARNING: Nothing done yet in get_pack_type_desc for decoderId #%d\n', ...
         a_decoderId);
end

return

% ------------------------------------------------------------------------------
% Convert packet data type number into description string.
%
% SYNTAX :
%  [o_dataDesc] = get_data_desc(a_sensorDataType)
%
% INPUT PARAMETERS :
%   a_sensorDataType : packet sensor data type number
%
% OUTPUT PARAMETERS :
%   o_dataDesc : packet data type description
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/10/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataDesc] = get_data_desc(a_sensorDataType)

% output parameter initialization
o_dataDesc = '';

switch (a_sensorDataType)
   case 0
      o_dataDesc = 'CTD mean';
   case 1
      o_dataDesc = 'CTD stdev&media,';
   case 2
      o_dataDesc = 'CTD raw';
   case 3
      o_dataDesc = 'OPTODE mean';
   case 4
      o_dataDesc = 'OPTODE stdev&media,';
   case 5
      o_dataDesc = 'OPTODE raw';
   case 6
      o_dataDesc = 'ECO2 mean';
   case 7
      o_dataDesc = 'ECO2 stdev&media,';
   case 8
      o_dataDesc = 'ECO2 raw';
   case 9
      o_dataDesc = 'ECO3 mean';
   case 10
      o_dataDesc = 'ECO3 stdev&media,';
   case 11
      o_dataDesc = 'ECO3 raw';
   case 12
      o_dataDesc = 'OCR mean';
   case 13
      o_dataDesc = 'OCR stdev&media,';
   case 14
      o_dataDesc = 'OCR raw';
   case 18
      o_dataDesc = 'cROVER mean';
   case 19
      o_dataDesc = 'cROVER stdev&media,';
   case 20
      o_dataDesc = 'cROVER raw';
   case 21
      o_dataDesc = 'SUNA mean';
   case 22
      o_dataDesc = 'SUNA stdev&media,';
   case 23
      o_dataDesc = 'SUNA raw';
   case 24
      o_dataDesc = 'SUNA APF frame';
   case 25
      o_dataDesc = 'SUNA APF frame 2';
   case 46
      o_dataDesc = 'SEAFET mean';
   case 47
      o_dataDesc = 'SEAFET stdev&media,';
   case 48
      o_dataDesc = 'SEAFET raw';
   otherwise
      fprintf('WARNING: Nothing done yet in get_data_desc for sensorDataType #%d\n', ...
         a_sensorDataType);
end

return

% ------------------------------------------------------------------------------
% Convert phase number into description string.
%
% SYNTAX :
%  [o_phaseDesc] = get_phase_desc(a_phaseNum)
%
% INPUT PARAMETERS :
%   a_phaseNum : phase number
%
% OUTPUT PARAMETERS :
%   o_phaseDesc : phase description
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/10/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_phaseDesc] = get_phase_desc(a_phaseNum)

% output parameter initialization
o_phaseDesc = '';

switch (a_phaseNum)
   case 0
      o_phaseDesc = 'pre mission';
   case 1
      o_phaseDesc = 'surf wait';
   case 2
      o_phaseDesc = 'init new cycle';
   case 3
      o_phaseDesc = 'init new prof';
   case 4
      o_phaseDesc = 'buoy reduction';
   case 5
      o_phaseDesc = 'desc 2 park';
   case 6
      o_phaseDesc = 'park drift';
   case 7
      o_phaseDesc = 'desc 2 prof';
   case 8
      o_phaseDesc = 'prof drift';
   case 9
      o_phaseDesc = 'asc prof';
   case 10
      o_phaseDesc = 'emergence';
   case 11
      o_phaseDesc = 'data processing';
   case 12
      o_phaseDesc = 'sat trans';
   case 13
      o_phaseDesc = 'end of profile';
   case 14
      o_phaseDesc = 'end of life';
   case 15
      o_phaseDesc = 'emergency ascent';
   case 16
      o_phaseDesc = 'user dialog';
   case 17
      o_phaseDesc = 'buoy invertion';
   otherwise
      fprintf('WARNING: Nothing done yet in get_phase_desc for phaseNum #%d\n', ...
         a_phaseNum);
end

return

% ------------------------------------------------------------------------------
% Convert sensor number into description string.
%
% SYNTAX :
%  [o_sensorDesc] = get_sensor_desc(a_sensorType)
%
% INPUT PARAMETERS :
%   a_sensorType : sensor number
%
% OUTPUT PARAMETERS :
%   o_sensorDesc : sensor description
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/10/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_sensorDesc] = get_sensor_desc(a_sensorType)

% output parameter initialization
o_sensorDesc = '';

switch (a_sensorType)
   case 0
      o_sensorDesc = 'CTD';
   case 1
      o_sensorDesc = 'OPTODE';
   case 2
      o_sensorDesc = 'OCR';
   case 3
      o_sensorDesc = 'ECO';
   case 4
      o_sensorDesc = 'SEAFET';
   case 5
      o_sensorDesc = 'cROVER';
   case 6
      o_sensorDesc = 'SUNA';
   otherwise
      fprintf('WARNING: Nothing done yet in get_sensor_desc for sensorType #%d\n', ...
         a_sensorType);
end

return

% ------------------------------------------------------------------------------
% Retrieve data type number list associated to a given sensor.
%
% SYNTAX :
%  [o_sensorDataTypeList] = get_sensor_data_type_list(a_sensorType)
%
% INPUT PARAMETERS :
%   a_sensorType : sensor number
%
% OUTPUT PARAMETERS :
%   o_sensorDataTypeList : data type number list
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/10/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_sensorDataTypeList] = get_sensor_data_type_list(a_sensorType)

% output parameter initialization
o_sensorDataTypeList = [];

% sensor list
global g_decArgo_sensorMountedOnFloat;


switch (a_sensorType)
   case 0
      o_sensorDataTypeList = 0:2;
   case 1
      o_sensorDataTypeList = 3:5;
   case 2
      o_sensorDataTypeList = 12:14;
   case 3
      if (ismember('ECO2', g_decArgo_sensorMountedOnFloat))
         o_sensorDataTypeList = 6:8;
      elseif (ismember('ECO3', g_decArgo_sensorMountedOnFloat))
         o_sensorDataTypeList = 9:11;
      end
   case 4
      o_sensorDataTypeList = 46:48;
   case 5
      o_sensorDataTypeList = 18:20;
   case 6
      o_sensorDataTypeList = 21:25;
   otherwise
      fprintf('WARNING: Nothing done yet in get_sensor_data_type_list for sensorType #%d\n', ...
         a_sensorType);
end

return
