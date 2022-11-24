% ------------------------------------------------------------------------------
% Clean duplicates in received data for a given cycle during a given
% transmission session.
%
% SYNTAX :
%  [o_decDataTab] = clean_duplicates_in_received_data(a_decDataTab, a_decoderId)
%
% INPUT PARAMETERS :
%   a_decDataTab : input received data
%   a_decoderId  : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_decDataTab : output (cleaned) received data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/17/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decDataTab] = clean_duplicates_in_received_data(a_decDataTab, a_decoderId)

% output parameters initialization
o_decDataTab = a_decDataTab;

% current float WMO number
global g_decArgo_floatNum;


% clean multiple transmission
% some messages could be transmitted more than once (Ex: 3901868 #13)
rawData = reshape([o_decDataTab.rawData], [99, length(a_decDataTab)])';
if ((size(rawData, 1) ~= size(unique(rawData, 'rows'), 1)))
   [uTabData, ia, ~] = unique(rawData, 'rows', 'stable');
   for idMes = 1:size(uTabData, 1)
      idEq = [];
      for idM = 1:size(rawData, 1)
         if (sum(uTabData(idMes, :) == rawData(idM, :)) == size(rawData, 2))
            idEq = [idEq idM];
         end
      end
      if (length(idEq) > 1)
         % packet type
         packType = rawData(idEq(1), 1);
         packetName = get_packet_name(packType, a_decoderId);
         
         if (length(idEq) == 2)
            fprintf('INFO: Float #%d: %s received twice => only one is decoded\n', ...
               g_decArgo_floatNum, ...
               packetName);
         else
            fprintf('INFO: Float #%d: %s received %d times => only one is decoded\n', ...
               g_decArgo_floatNum, ...
               packetName, ...
               length(idEq));
         end
      end
   end
   idDel = setdiff(1:size(rawData, 1), ia);
   o_decDataTab(idDel) = [];
end

return

% ------------------------------------------------------------------------------
% Convert packet type number into packet type name.
%
% SYNTAX :
%  [o_packetName] = get_packet_name(a_packType, a_decoderId)
%
% INPUT PARAMETERS :
%   a_packType  : packet type number
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_packetName : packet type name
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/17/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_packetName] = get_packet_name(a_packType, a_decoderId)

% output parameter initialization
o_packetName = '';

switch (a_decoderId)
   case {212, 214, 217}
      switch (a_packType)
         case 0
            o_packetName = 'one technical packet #1';
         case 4
            o_packetName = 'one technical packet #2';
         case 5
            o_packetName = 'one parameter packet #1';
         case 6
            o_packetName = 'one parameter packet #2';
         case 7
            o_packetName = 'one hydraulic packet';
         otherwise
            o_packetName = 'one data packet';
      end
   case {216}
      switch (a_packType)
         case 0
            o_packetName = 'one technical packet #1';
         case 4
            o_packetName = 'one technical packet #2';
         case 5
            o_packetName = 'one parameter packet #1';
         case 6
            o_packetName = 'one hydraulic valve packet';
         case 7
            o_packetName = 'one hydraulic pump packet';
         otherwise
            o_packetName = 'one data packet';
      end
   otherwise
      fprintf('WARNING: Nothing done yet in get_packet_name for decoderId #%d\n', ...
         a_decoderId);
end

return
