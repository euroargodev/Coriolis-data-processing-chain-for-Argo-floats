% ------------------------------------------------------------------------------
% Check if the buffer data is ready to be processed (if all expected data has
% been received).
%
% SYNTAX :
%  [o_completed] = is_buffer_completed_ir_sbd_nva(a_whyFlag, a_decoderId)
%
% INPUT PARAMETERS :
%   a_whyFlag   : if 1, print what is missing
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_completed : buffer completed flag (1 if the data can be processed, 0
%                 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/28/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_completed] = is_buffer_completed_ir_sbd_nva(a_whyFlag, a_decoderId)

% output parameters initialization
o_completed = 0;

% current float WMO number
global g_decArgo_floatNum;

% arrays to store rough information on received data
global g_decArgo_1TypePacketReceived;
global g_decArgo_5TypePacketReceived;
global g_decArgo_nbOf2To4TypePacketExpected;
global g_decArgo_nbOf10To29TypePacketExpected;
global g_decArgo_nbOf30To49TypePacketExpected;
global g_decArgo_nbOf50To55TypePacketExpected;
global g_decArgo_nbOf2To4TypePacketReceived;
global g_decArgo_nbOf10To29TypePacketReceived;
global g_decArgo_nbOf30To49TypePacketReceived;
global g_decArgo_nbOf50To55TypePacketReceived;
global g_decArgo_ackPacket;
g_decArgo_ackPacket = 0;


% check if all expected data have been received
if ((g_decArgo_1TypePacketReceived == 1) && ...
      (g_decArgo_nbOf2To4TypePacketExpected == g_decArgo_nbOf2To4TypePacketReceived) && ...
      (g_decArgo_nbOf10To29TypePacketExpected == g_decArgo_nbOf10To29TypePacketReceived) && ...
      (g_decArgo_nbOf30To49TypePacketExpected == g_decArgo_nbOf30To49TypePacketReceived) && ...
      (g_decArgo_nbOf50To55TypePacketExpected == g_decArgo_nbOf50To55TypePacketReceived))
   
   % the buffer is complete
   o_completed = 1;
   
elseif (g_decArgo_5TypePacketReceived == 1)
   
   % the buffer is complete
   o_completed = 1;
   
   % we received an acknowledgment packet
   g_decArgo_ackPacket = 1;
   
elseif (a_whyFlag == 1)
   
   switch (a_decoderId)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      case {2001, 2002, 2003} % Nova, Dova
         
         if (g_decArgo_1TypePacketReceived == 0)
            fprintf('BUFF_INFO: Float #%d: Technical packet #1 is missing\n', ...
               g_decArgo_floatNum);
         end
         if (g_decArgo_1TypePacketReceived == 1)
            if (g_decArgo_nbOf2To4TypePacketExpected ~= g_decArgo_nbOf2To4TypePacketReceived)
               fprintf('BUFF_INFO: Float #%d: %d hydraulic packets are missing\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_nbOf2To4TypePacketExpected-g_decArgo_nbOf2To4TypePacketReceived);
            end
            if (g_decArgo_nbOf10To29TypePacketExpected ~= g_decArgo_nbOf10To29TypePacketReceived)
               fprintf('BUFF_INFO: Float #%d: %d ascent data packets are missing\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_nbOf10To29TypePacketExpected-g_decArgo_nbOf10To29TypePacketReceived);
            end
            if (g_decArgo_nbOf30To49TypePacketExpected ~= g_decArgo_nbOf30To49TypePacketReceived)
               fprintf('BUFF_INFO: Float #%d: %d descent data packets are missing\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_nbOf30To49TypePacketExpected-g_decArgo_nbOf30To49TypePacketReceived);
            end
            if (g_decArgo_nbOf50To55TypePacketExpected ~= g_decArgo_nbOf50To55TypePacketReceived)
               fprintf('BUFF_INFO: Float #%d: %d drift data packets are missing\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_nbOf50To55TypePacketExpected-g_decArgo_nbOf50To55TypePacketReceived);
            end
         end
         
      otherwise
         fprintf('WARNING: Float #%d: Nothing implemented yet to explain what is missing in the buffer for decoderId #%d\n', ...
            g_decArgo_floatNum, ...
            a_decoderId);
   end
end

return
