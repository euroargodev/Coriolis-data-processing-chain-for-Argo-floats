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

% output parameters initialization
o_firstMsgTime = g_decArgo_dateDef;
o_lastMsgTime = g_decArgo_dateDef;


% process the contents of the Iridium mail associated to the current cycle
idFCyNum = find([a_iridiumMailData.cycleNumber] == a_cycleNumber);
if (~isempty(idFCyNum))
   timeList = [a_iridiumMailData(idFCyNum).timeOfSessionJuld];
   o_firstMsgTime = min(timeList);
   o_lastMsgTime = max(timeList);
end

return
