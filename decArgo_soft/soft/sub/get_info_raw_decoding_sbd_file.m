% ------------------------------------------------------------------------------
% Retrieve basic information (cycle numbers and packet types) on decoded data.
%
% SYNTAX :
%  [o_sbdInfoStr, o_cyList] = get_info_raw_decoding_sbd_file( ...
%    a_tabData, a_tabDataDates, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabData         : data frame to decode
%   a_tabDataDates    : corresponding dates of Iridium SBD
%   a_decoderId       : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_sbdInfoStr : decoded information
%   o_cyList     : list of cycle numbers
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/16/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_sbdInfoStr, o_cyList] = get_info_raw_decoding_sbd_file( ...
   a_tabData, a_tabDataDates, a_decoderId)

% output parameters initialization
o_sbdInfoStr = '';
o_cyList = [];

% current float WMO number
global g_decArgo_floatNum;

% arrays to store rough information on received data
global g_decArgo_cycleList;
global g_decArgo_0TypePacketReceivedFlag;
global g_decArgo_4TypePacketReceivedFlag;
global g_decArgo_5TypePacketReceivedFlag;
global g_decArgo_7TypePacketReceivedFlag;
global g_decArgo_nbOf1Or8TypePacketReceived;
global g_decArgo_nbOf2Or9TypePacketReceived;
global g_decArgo_nbOf3Or10TypePacketReceived;
global g_decArgo_nbOf13Or11TypePacketReceived;
global g_decArgo_nbOf14Or12TypePacketReceived;
global g_decArgo_nbOf6TypePacketReceived;
global g_decArgo_nbOf7TypePacketReceived;


idDel = [];
for idMsg = 1:size(a_tabData, 1)
   if (~any(a_tabData(idMsg, :) ~= 0))
      idDel = [idDel idMsg];
   end
end
a_tabData(idDel, :) = [];
a_tabDataDates(idDel) = [];

if (isempty(a_tabData))
   return;
end

switch (a_decoderId)
   
   case {212} % Arvor-ARN-Ice Iridium
      
      % decode the collected data
      decode_prv_data_ir_sbd_212(a_tabData, a_tabDataDates, 0, []);
      o_cyList = g_decArgo_cycleList;
      
      for cyId = 1:length(g_decArgo_cycleList)
         cyInfoStr = '';
         
         if (~isempty(g_decArgo_0TypePacketReceivedFlag) && ...
               (length(g_decArgo_0TypePacketReceivedFlag) >= cyId) && ...
               (g_decArgo_0TypePacketReceivedFlag(cyId) == 1))
            cyInfoStr = [cyInfoStr '#0 '];
         end
         if (~isempty(g_decArgo_4TypePacketReceivedFlag) && ...
               (length(g_decArgo_4TypePacketReceivedFlag) >= cyId) && ...
               (g_decArgo_4TypePacketReceivedFlag(cyId) == 1))
            cyInfoStr = [cyInfoStr '#4 '];
         end
         if (~isempty(g_decArgo_5TypePacketReceivedFlag) && ...
               (length(g_decArgo_5TypePacketReceivedFlag) >= cyId) && ...
               (g_decArgo_5TypePacketReceivedFlag(cyId) == 1))
            cyInfoStr = [cyInfoStr '#5 '];
         end
         if (~isempty(g_decArgo_7TypePacketReceivedFlag) && ...
               (length(g_decArgo_7TypePacketReceivedFlag) >= cyId) && ...
               (g_decArgo_7TypePacketReceivedFlag(cyId) == 1))
            cyInfoStr = [cyInfoStr '#7 '];
         end
         if (~isempty(g_decArgo_nbOf6TypePacketReceived) && ...
               (length(g_decArgo_nbOf6TypePacketReceived) >= cyId) && ...
               (g_decArgo_nbOf6TypePacketReceived(cyId) > 0))
            cyInfoStr = [cyInfoStr sprintf('#6 (%d) ', g_decArgo_nbOf6TypePacketReceived(cyId))];
         end
         if (~isempty(g_decArgo_nbOf1Or8TypePacketReceived) && ...
               (length(g_decArgo_nbOf1Or8TypePacketReceived) >= cyId) && ...
               (g_decArgo_nbOf1Or8TypePacketReceived(cyId) > 0))
            cyInfoStr = [cyInfoStr sprintf('#1 (%d) ', g_decArgo_nbOf1Or8TypePacketReceived(cyId))];
         end
         if (~isempty(g_decArgo_nbOf2Or9TypePacketReceived) && ...
               (length(g_decArgo_nbOf2Or9TypePacketReceived) >= cyId) && ...
               (g_decArgo_nbOf2Or9TypePacketReceived(cyId) > 0))
            cyInfoStr = [cyInfoStr sprintf('#2 (%d) ', g_decArgo_nbOf2Or9TypePacketReceived(cyId))];
         end
         if (~isempty(g_decArgo_nbOf3Or10TypePacketReceived) && ...
               (length(g_decArgo_nbOf3Or10TypePacketReceived) >= cyId) && ...
               (g_decArgo_nbOf3Or10TypePacketReceived(cyId) > 0))
            cyInfoStr = [cyInfoStr sprintf('#3 (%d) ', g_decArgo_nbOf3Or10TypePacketReceived(cyId))];
         end
         if (~isempty(g_decArgo_nbOf13Or11TypePacketReceived) && ...
               (length(g_decArgo_nbOf13Or11TypePacketReceived) >= cyId) && ...
               (g_decArgo_nbOf13Or11TypePacketReceived(cyId) > 0))
            cyInfoStr = [cyInfoStr sprintf('#13 (%d) ', g_decArgo_nbOf13Or11TypePacketReceived(cyId))];
         end
         if (~isempty(g_decArgo_nbOf14Or12TypePacketReceived) && ...
               (length(g_decArgo_nbOf14Or12TypePacketReceived) >= cyId) && ...
               (g_decArgo_nbOf14Or12TypePacketReceived(cyId) > 0))
            cyInfoStr = [cyInfoStr sprintf('#14 (%d) ', g_decArgo_nbOf14Or12TypePacketReceived(cyId))];
         end
         
         if (~isempty(cyInfoStr))
            o_sbdInfoStr = [o_sbdInfoStr  sprintf('Cy %d : %s;', g_decArgo_cycleList(cyId), cyInfoStr(1:end-1))];
         end
      end
      
   case {214} % Provor-ARN-DO-Ice Iridium 5.75
      
      % decode the collected data
      decode_prv_data_ir_sbd_214(a_tabData, a_tabDataDates, 0, []);
      o_cyList = g_decArgo_cycleList;

      for cyId = 1:length(g_decArgo_cycleList)
         cyInfoStr = '';
         
         if (~isempty(g_decArgo_0TypePacketReceivedFlag) && ...
               (length(g_decArgo_0TypePacketReceivedFlag) >= cyId) && ...
               (g_decArgo_0TypePacketReceivedFlag(cyId) == 1))
            cyInfoStr = [cyInfoStr '#0 '];
         end
         if (~isempty(g_decArgo_4TypePacketReceivedFlag) && ...
               (length(g_decArgo_4TypePacketReceivedFlag) >= cyId) && ...
               (g_decArgo_4TypePacketReceivedFlag(cyId) == 1))
            cyInfoStr = [cyInfoStr '#4 '];
         end
         if (~isempty(g_decArgo_5TypePacketReceivedFlag) && ...
               (length(g_decArgo_5TypePacketReceivedFlag) >= cyId) && ...
               (g_decArgo_5TypePacketReceivedFlag(cyId) == 1))
            cyInfoStr = [cyInfoStr '#5 '];
         end
         if (~isempty(g_decArgo_7TypePacketReceivedFlag) && ...
               (length(g_decArgo_7TypePacketReceivedFlag) >= cyId) && ...
               (g_decArgo_7TypePacketReceivedFlag(cyId) == 1))
            cyInfoStr = [cyInfoStr '#7 '];
         end
         if (~isempty(g_decArgo_nbOf6TypePacketReceived) && ...
               (length(g_decArgo_nbOf6TypePacketReceived) >= cyId) && ...
               (g_decArgo_nbOf6TypePacketReceived(cyId) > 0))
            cyInfoStr = [cyInfoStr sprintf('#6 (%d) ', g_decArgo_nbOf6TypePacketReceived(cyId))];
         end
         if (~isempty(g_decArgo_nbOf1Or8TypePacketReceived) && ...
               (length(g_decArgo_nbOf1Or8TypePacketReceived) >= cyId) && ...
               (g_decArgo_nbOf1Or8TypePacketReceived(cyId) > 0))
            cyInfoStr = [cyInfoStr sprintf('#8 (%d) ', g_decArgo_nbOf1Or8TypePacketReceived(cyId))];
         end
         if (~isempty(g_decArgo_nbOf2Or9TypePacketReceived) && ...
               (length(g_decArgo_nbOf2Or9TypePacketReceived) >= cyId) && ...
               (g_decArgo_nbOf2Or9TypePacketReceived(cyId) > 0))
            cyInfoStr = [cyInfoStr sprintf('#9 (%d) ', g_decArgo_nbOf2Or9TypePacketReceived(cyId))];
         end
         if (~isempty(g_decArgo_nbOf3Or10TypePacketReceived) && ...
               (length(g_decArgo_nbOf3Or10TypePacketReceived) >= cyId) && ...
               (g_decArgo_nbOf3Or10TypePacketReceived(cyId) > 0))
            cyInfoStr = [cyInfoStr sprintf('#10 (%d) ', g_decArgo_nbOf3Or10TypePacketReceived(cyId))];
         end
         if (~isempty(g_decArgo_nbOf13Or11TypePacketReceived) && ...
               (length(g_decArgo_nbOf13Or11TypePacketReceived) >= cyId) && ...
               (g_decArgo_nbOf13Or11TypePacketReceived(cyId) > 0))
            cyInfoStr = [cyInfoStr sprintf('#11 (%d) ', g_decArgo_nbOf13Or11TypePacketReceived(cyId))];
         end
         if (~isempty(g_decArgo_nbOf14Or12TypePacketReceived) && ...
               (length(g_decArgo_nbOf14Or12TypePacketReceived) >= cyId) && ...
               (g_decArgo_nbOf14Or12TypePacketReceived(cyId) > 0))
            cyInfoStr = [cyInfoStr sprintf('#12 (%d) ', g_decArgo_nbOf14Or12TypePacketReceived(cyId))];
         end
         
         if (~isempty(cyInfoStr))
            o_sbdInfoStr = [o_sbdInfoStr  sprintf('Cy %d : %s;', g_decArgo_cycleList(cyId), cyInfoStr(1:end-1))];
         end
      end
      
   case {216} % Arvor-Deep-Ice Iridium 5.65
      
      % decode the collected data
      decode_prv_data_ir_sbd_216(a_tabData, a_tabDataDates, 0, []);
      o_cyList = g_decArgo_cycleList;

      for cyId = 1:length(g_decArgo_cycleList)
         cyInfoStr = '';
         
         if (~isempty(g_decArgo_0TypePacketReceivedFlag) && ...
               (length(g_decArgo_0TypePacketReceivedFlag) >= cyId) && ...
               (g_decArgo_0TypePacketReceivedFlag(cyId) == 1))
            cyInfoStr = [cyInfoStr '#0 '];
         end
         if (~isempty(g_decArgo_4TypePacketReceivedFlag) && ...
               (length(g_decArgo_4TypePacketReceivedFlag) >= cyId) && ...
               (g_decArgo_4TypePacketReceivedFlag(cyId) == 1))
            cyInfoStr = [cyInfoStr '#4 '];
         end
         if (~isempty(g_decArgo_5TypePacketReceivedFlag) && ...
               (length(g_decArgo_5TypePacketReceivedFlag) >= cyId) && ...
               (g_decArgo_5TypePacketReceivedFlag(cyId) == 1))
            cyInfoStr = [cyInfoStr '#5 '];
         end
         if (~isempty(g_decArgo_nbOf6TypePacketReceived) && ...
               (length(g_decArgo_nbOf6TypePacketReceived) >= cyId) && ...
               (g_decArgo_nbOf6TypePacketReceived(cyId) > 0))
            cyInfoStr = [cyInfoStr sprintf('#6 (%d) ', g_decArgo_nbOf6TypePacketReceived(cyId))];
         end
         if (~isempty(g_decArgo_nbOf7TypePacketReceived) && ...
               (length(g_decArgo_nbOf7TypePacketReceived) >= cyId) && ...
               (g_decArgo_nbOf7TypePacketReceived(cyId) > 0))
            cyInfoStr = [cyInfoStr sprintf('#7 (%d) ', g_decArgo_nbOf7TypePacketReceived(cyId))];
         end
         if (~isempty(g_decArgo_nbOf1Or8TypePacketReceived) && ...
               (length(g_decArgo_nbOf1Or8TypePacketReceived) >= cyId) && ...
               (g_decArgo_nbOf1Or8TypePacketReceived(cyId) > 0))
            cyInfoStr = [cyInfoStr sprintf('#8 (%d) ', g_decArgo_nbOf1Or8TypePacketReceived(cyId))];
         end
         if (~isempty(g_decArgo_nbOf2Or9TypePacketReceived) && ...
               (length(g_decArgo_nbOf2Or9TypePacketReceived) >= cyId) && ...
               (g_decArgo_nbOf2Or9TypePacketReceived(cyId) > 0))
            cyInfoStr = [cyInfoStr sprintf('#9 (%d) ', g_decArgo_nbOf2Or9TypePacketReceived(cyId))];
         end
         if (~isempty(g_decArgo_nbOf3Or10TypePacketReceived) && ...
               (length(g_decArgo_nbOf3Or10TypePacketReceived) >= cyId) && ...
               (g_decArgo_nbOf3Or10TypePacketReceived(cyId) > 0))
            cyInfoStr = [cyInfoStr sprintf('#10 (%d) ', g_decArgo_nbOf3Or10TypePacketReceived(cyId))];
         end
         if (~isempty(g_decArgo_nbOf13Or11TypePacketReceived) && ...
               (length(g_decArgo_nbOf13Or11TypePacketReceived) >= cyId) && ...
               (g_decArgo_nbOf13Or11TypePacketReceived(cyId) > 0))
            cyInfoStr = [cyInfoStr sprintf('#11 (%d) ', g_decArgo_nbOf13Or11TypePacketReceived(cyId))];
         end
         if (~isempty(g_decArgo_nbOf14Or12TypePacketReceived) && ...
               (length(g_decArgo_nbOf14Or12TypePacketReceived) >= cyId) && ...
               (g_decArgo_nbOf14Or12TypePacketReceived(cyId) > 0))
            cyInfoStr = [cyInfoStr sprintf('#12 (%d) ', g_decArgo_nbOf14Or12TypePacketReceived(cyId))];
         end
         
         if (~isempty(cyInfoStr))
            o_sbdInfoStr = [o_sbdInfoStr  sprintf('Cy %d : %s;', g_decArgo_cycleList(cyId), cyInfoStr(1:end-1))];
         end
      end
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in get_info_raw_decoding_sbd_file for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
