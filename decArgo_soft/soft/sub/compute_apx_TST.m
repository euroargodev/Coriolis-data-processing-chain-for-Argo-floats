% ------------------------------------------------------------------------------
% Compute APEX TST using 2 methods: the TWR one and the 'improved' one.
%
% SYNTAX :
%  [o_tst1, o_tst2] = compute_apx_TST( ...
%    a_argosDataData, a_argosDataUsed, a_argosDataDate, a_timeDataConfig, a_decoderId)
%
% INPUT PARAMETERS :
%   a_argosDataData  : Argos received message data
%   a_argosDataUsed  : Argos used message data
%   a_argosDataDate  : Argos received message dates
%   a_timeDataConfig : useful configuration information
%   a_decoderId      : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tst1 : TST values computed from TWR method
%   o_tst2 : TST values computed from 'improved' method
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tst1, o_tst2] = compute_apx_TST( ...
   a_argosDataData, a_argosDataUsed, a_argosDataDate, a_timeDataConfig, a_decoderId)

% default values
global g_decArgo_dateDef;

% output parameters initialization
o_tst1 = g_decArgo_dateDef;
o_tst2 = g_decArgo_dateDef;


% collect information
tabDates = [];
tabMsgNum = [];
tabMsgBlockNum = [];
for idL = 1:length(a_argosDataUsed)
   idList = a_argosDataUsed{idL};
   for idMsg = 1:length(idList)
      sensor = a_argosDataData(idList(idMsg), :);
      msgNum = sensor(2);
      tabDates = [tabDates a_argosDataDate(idList(idMsg))];
      tabMsgNum = [tabMsgNum msgNum];
      if (msgNum == 1)
         tabMsgBlockNum = [tabMsgBlockNum sensor(3)];
      else
         tabMsgBlockNum = [tabMsgBlockNum -1];
      end
   end
end

% delete identical dates
[tabDates, idSorted] = sort(tabDates);
tabMsgNum = tabMsgNum(idSorted);
tabMsgBlockNum = tabMsgBlockNum(idSorted);

idDel = find(diff(tabDates) == 0);
tabDates(idDel+1) = [];
tabMsgNum(idDel+1) = [];
tabMsgBlockNum(idDel+1) = [];

% correct possible roll over on message block number
idPos = find(tabMsgBlockNum ~= -1);
idDiff = find(diff(tabMsgBlockNum(idPos)) < 0);
if (~isempty(idDiff))
   idRollOver = idPos(idDiff+1);
   for id = 1:length(idRollOver)
      idAdd = find(idPos >= idRollOver(id));
      tabMsgBlockNum(idPos(idAdd)) = tabMsgBlockNum(idPos(idAdd)) + 256*(id+1);
   end
end

% compute TST
[o_tst1, o_tst2] = compute_TST(tabDates, tabMsgBlockNum, a_timeDataConfig, a_decoderId);

return;

% ------------------------------------------------------------------------------
% Compute APEX TST using 2 methods: the TWR one and the 'improved' one.
%
% SYNTAX :
%  [o_tst1, o_tst2] = compute_TST(a_date, a_msgBlockNum, a_timeDataConfig, a_decoderId)
%
% INPUT PARAMETERS :
%   a_date           : Argos message dates
%   a_msgBlockNum    : Argos message block numbers
%   a_timeDataConfig : useful configuration information
%   a_decoderId      : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tst1 : TST values computed from TWR method
%   o_tst2 : TST values computed from 'improved' method
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tst1, o_tst2] = compute_TST(a_date, a_msgBlockNum, a_timeDataConfig, a_decoderId)

% default values
global g_decArgo_dateDef;

% output parameters initialization
o_tst1 = g_decArgo_dateDef;
o_tst2 = g_decArgo_dateDef;


% method #1 (TWR method) and method #2 (improved method) provide the same result
% we will compute both when possible.
% - we will use method #1 when 'Argos repetition rate' and 'Profile length' are
% available
% - otherwise we will use method #2 when at least 2 messages with distinct block
% numbers are available
% note that:
% 1- when we use message block number #1 the result slightly differs from other
% block numbers => if possible, don't use message block number #1
% 2- when many messages are transmitted (the float stayed near the surface) the
% result is not correct if we use all block numbers => compute only NB_LOOP_MAX
% determinations of TSD
NB_LOOP_MAX = 100;


% only message with block numbers are used
idDel = find(a_msgBlockNum == -1);
a_date(idDel) = [];
a_msgBlockNum(idDel) = [];

% don't use message block number #1 if possible (the result is slightly
% different)
if (any(a_msgBlockNum ~= 1))
   idDel = find(a_msgBlockNum == 1);
   a_date(idDel) = [];
   a_msgBlockNum(idDel) = [];
end

% method #1 (TWR method)
transRepPeriod = a_timeDataConfig.transRepPeriod;
profileLength = a_timeDataConfig.profileLength;
if (~isempty(transRepPeriod) && ~isempty(profileLength))
   
   tabTsd1 = [];
   nbMsg = compute_number_of_apx_argos_msg(profileLength, a_decoderId);
   if (~isempty(nbMsg))
      for id = 1:min(length(a_date), NB_LOOP_MAX)
         tranStartDate = a_date(id) - ((a_msgBlockNum(id)-1)*nbMsg*transRepPeriod)/86400;
         % next line: only to round dates
         tranStartDate = gregorian_2_julian_dec_argo(julian_2_gregorian_dec_argo(tranStartDate));
         tabTsd1 = [tabTsd1 tranStartDate];
      end
      o_tst1 = tabTsd1;
   end
   
end

% method #2 (improved method)

% process all combinations between different message block numbers
nbLoopMax = NB_LOOP_MAX;
tabTsd2 = [];
for id1 = 1:length(a_date)-1
   for id2 = id1+1:length(a_date)
      if (a_msgBlockNum(id1) ~= a_msgBlockNum(id2))
         tranStartDate = compute_trans_start_date( ...
            a_date(id1), a_msgBlockNum(id1), ...
            a_date(id2), a_msgBlockNum(id2));
         % next line: only to round dates
         tranStartDate = gregorian_2_julian_dec_argo(julian_2_gregorian_dec_argo(tranStartDate));
         tabTsd2 = [tabTsd2 tranStartDate];

         nbLoopMax = nbLoopMax - 1;
         if (nbLoopMax == 0)
            break
         end
      end
   end
   if (nbLoopMax == 0)
      break
   end
end
if (~isempty(tabTsd2))
   o_tst2 = tabTsd2;
end

return;

% ------------------------------------------------------------------------------
% Compute one APEX TST.
%
% SYNTAX :
%  [o_tranStartDate] = compute_trans_start_date(a_date1, a_num1, a_date2, a_num2)
%
% INPUT PARAMETERS :
%   a_date1 : first Argos message date
%   a_num1  : first Argos message block number
%   a_date2 : second Argos message date
%   a_num2  : second Argos message block number
%
% OUTPUT PARAMETERS :
%   o_tranStartDate : computed TST value
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tranStartDate] = compute_trans_start_date(a_date1, a_num1, a_date2, a_num2)

deltaDate = a_date2 - a_date1;
deltaNum = a_num2 - a_num1;
blockTransTime = deltaDate/deltaNum;

o_tranStartDate = a_date2 - (a_num2-1)*blockTransTime;

return;
