% ------------------------------------------------------------------------------
% Compute FMT and LMT from Iridium mail contents for a given cycle number.
%
% SYNTAX :
%  [o_firstMsgTime, o_lastMsgTime] = ...
%    compute_first_last_msg_time_from_iridium_mail(a_iridiumMailData, a_cycleNumber)
%
% INPUT PARAMETERS :
%   a_iridiumMailData : Iridium mail contents
%   a_cycleNumber     : concerned cycle number 
%
% OUTPUT PARAMETERS :
%   o_firstMsgTime : first message time
%   o_lastMsgTime  : last message time
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_firstMsgTime, o_lastMsgTime] = ...
   compute_first_last_msg_time_from_iridium_mail(a_iridiumMailData, a_cycleNumber)

% default values
global g_decArgo_dateDef;

% current float WMO number
global g_decArgo_floatNum;

% output parameters initialization
o_firstMsgTime = g_decArgo_dateDef;
o_lastMsgTime = g_decArgo_dateDef;


% specific
if (ismember(g_decArgo_floatNum, [6903256, 6902957, 6901880]))
   switch g_decArgo_floatNum
      case 6903256
         if (a_cycleNumber == 4)
            return
         elseif (a_cycleNumber == 6)
            idFCyNum = find(([a_iridiumMailData.cycleNumber] == a_cycleNumber) | ...
               ([a_iridiumMailData.cycleNumber] == 4));
            if (~isempty(idFCyNum))
               idFCyNum(end) = [];
               timeList = [a_iridiumMailData(idFCyNum).timeOfSessionJuld];
               o_firstMsgTime = min(timeList);
               o_lastMsgTime = max(timeList);
            end
            return
         elseif (a_cycleNumber == 11)
            idFCyNum = find([a_iridiumMailData.cycleNumber] == 4);
            if (~isempty(idFCyNum))
               timeList = [a_iridiumMailData(idFCyNum).timeOfSessionJuld];
               o_firstMsgTime = max(timeList);
               o_lastMsgTime = max(timeList);
            end
            return
         end
      case 6902957
         % cycle duration is 24 h => errors in mail <-> cycle attribution
         if (ismember(a_cycleNumber, [118:122]))
            switch a_cycleNumber
               case 118
                  idFCyNum = find([a_iridiumMailData.cycleNumber] == a_cycleNumber);
                  if (~isempty(idFCyNum))
                     timeList = [a_iridiumMailData(idFCyNum).timeOfSessionJuld];
                     timeList = timeList(1:4);
                     o_firstMsgTime = min(timeList);
                     o_lastMsgTime = max(timeList);
                  end
                  return
               case 119
                  idFCyNum = find([a_iridiumMailData.cycleNumber] == a_cycleNumber-1);
                  if (~isempty(idFCyNum))
                     timeList = [a_iridiumMailData(idFCyNum).timeOfSessionJuld];
                     timeList = timeList(5:end);
                     o_firstMsgTime = min(timeList);
                     o_lastMsgTime = max(timeList);
                  end
                  return
               case 120
                  idFCyNum = find([a_iridiumMailData.cycleNumber] == a_cycleNumber);
                  if (~isempty(idFCyNum))
                     timeList = [a_iridiumMailData(idFCyNum).timeOfSessionJuld];
                     timeList = timeList(1:6);
                     o_firstMsgTime = min(timeList);
                     o_lastMsgTime = max(timeList);
                  end
                  return
               case 121
                  idFCyNum = find([a_iridiumMailData.cycleNumber] == a_cycleNumber-1);
                  if (~isempty(idFCyNum))
                     timeList = [a_iridiumMailData(idFCyNum).timeOfSessionJuld];
                     timeList = timeList(7:end);
                     o_firstMsgTime = min(timeList);
                     o_lastMsgTime = max(timeList);
                  end
                  return
               case 122
                  idFCyNum = find([a_iridiumMailData.cycleNumber] == a_cycleNumber);
                  if (~isempty(idFCyNum))
                     timeList = [a_iridiumMailData(idFCyNum).timeOfSessionJuld];
                     timeList = timeList(1:5);
                     o_firstMsgTime = min(timeList);
                     o_lastMsgTime = max(timeList);
                  end
                  return
            end
         end
      case 6901880
         if (ismember(a_cycleNumber, [58 59 63]))
            switch a_cycleNumber
               case 58
                  idFCyNum = find([a_iridiumMailData.cycleNumber] == a_cycleNumber);
                  if (~isempty(idFCyNum))
                     timeList = [a_iridiumMailData(idFCyNum).timeOfSessionJuld];
                     timeList = timeList(1:8);
                     o_firstMsgTime = min(timeList);
                     o_lastMsgTime = max(timeList);
                  end
                  return
               case 59
                  idFCyNum = find([a_iridiumMailData.cycleNumber] == a_cycleNumber-1);
                  if (~isempty(idFCyNum))
                     timeList = [a_iridiumMailData(idFCyNum).timeOfSessionJuld];
                     timeList = timeList(9:end-1);
                     o_firstMsgTime = min(timeList);
                     o_lastMsgTime = max(timeList);
                  end
                  return
               case 63
                  idFCyNum = find([a_iridiumMailData.cycleNumber] == a_cycleNumber);
                  if (~isempty(idFCyNum))
                     timeList = [a_iridiumMailData(idFCyNum).timeOfSessionJuld];
                     timeList = timeList(1:3);
                     o_firstMsgTime = min(timeList);
                     o_lastMsgTime = max(timeList);
                  end
                  return
            end
         end
   end
end

% process the contents of the Iridium mail associated to the current cycle
idFCyNum = find([a_iridiumMailData.cycleNumber] == a_cycleNumber);
if (~isempty(idFCyNum))
   timeList = [a_iridiumMailData(idFCyNum).timeOfSessionJuld];
   o_firstMsgTime = min(timeList);
   o_lastMsgTime = max(timeList);
end

return
