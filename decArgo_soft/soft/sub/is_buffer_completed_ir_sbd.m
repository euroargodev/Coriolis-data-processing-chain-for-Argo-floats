% ------------------------------------------------------------------------------
% Check if the buffer data is ready to be processed (if all expected data has
% been received).
%
% SYNTAX :
%  [o_completed] = is_buffer_completed_ir_sbd(a_whyFlag)
%
% INPUT PARAMETERS :
%   a_whyFlag : if 1, print what is missing
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
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_completed] = is_buffer_completed_ir_sbd(a_whyFlag, a_decoderId)

% output parameters initialization
o_completed = 0;

% current float WMO number
global g_decArgo_floatNum;

% flag to detect a second Iridium session
global g_decArgo_secondIridiumSession;

% arrays to store rough information on received data
global g_decArgo_0TypePacketReceivedFlag;
global g_decArgo_4TypePacketReceivedFlag;
global g_decArgo_5TypePacketReceivedFlag;
global g_decArgo_nbOf1Or8Or11Or14TypePacketExpected;
global g_decArgo_nbOf1Or8Or11Or14TypePacketReceived;
global g_decArgo_nbOf2Or9Or12Or15TypePacketExpected;
global g_decArgo_nbOf2Or9Or12Or15TypePacketReceived;
global g_decArgo_nbOf3Or10Or13Or16TypePacketExpected;
global g_decArgo_nbOf3Or10Or13Or16TypePacketReceived;
global g_decArgo_nbOf1Or8TypePacketExpected;
global g_decArgo_nbOf1Or8TypePacketReceived;
global g_decArgo_nbOf2Or9TypePacketExpected;
global g_decArgo_nbOf2Or9TypePacketReceived;
global g_decArgo_nbOf3Or10TypePacketExpected;
global g_decArgo_nbOf3Or10TypePacketReceived;
global g_decArgo_nbOf13Or11TypePacketExpected;
global g_decArgo_nbOf13Or11TypePacketReceived;
global g_decArgo_nbOf14Or12TypePacketExpected;
global g_decArgo_nbOf14Or12TypePacketReceived;


% check if all expected data have been received
if ((g_decArgo_0TypePacketReceivedFlag == 1) && ...
      (g_decArgo_4TypePacketReceivedFlag == 1) && ...
      (g_decArgo_5TypePacketReceivedFlag == 1) && ...
      (g_decArgo_nbOf1Or8Or11Or14TypePacketExpected == g_decArgo_nbOf1Or8Or11Or14TypePacketReceived) && ...
      (g_decArgo_nbOf2Or9Or12Or15TypePacketExpected == g_decArgo_nbOf2Or9Or12Or15TypePacketReceived) && ...
      (g_decArgo_nbOf3Or10Or13Or16TypePacketExpected == g_decArgo_nbOf3Or10Or13Or16TypePacketReceived) && ...
      (g_decArgo_nbOf1Or8TypePacketExpected == g_decArgo_nbOf1Or8TypePacketReceived) && ...
      (g_decArgo_nbOf2Or9TypePacketExpected == g_decArgo_nbOf2Or9TypePacketReceived) && ...
      (g_decArgo_nbOf3Or10TypePacketExpected == g_decArgo_nbOf3Or10TypePacketReceived) && ...
      (g_decArgo_nbOf13Or11TypePacketExpected == g_decArgo_nbOf13Or11TypePacketReceived) && ...
      (g_decArgo_nbOf14Or12TypePacketExpected == g_decArgo_nbOf14Or12TypePacketReceived))
   
   % the buffer is complete
   o_completed = 1;
   
   % set the "second Iridium session" flag
   if ((g_decArgo_nbOf1Or8Or11Or14TypePacketExpected == 0) && ...
         (g_decArgo_nbOf2Or9Or12Or15TypePacketExpected == 0) && ...
         (g_decArgo_nbOf3Or10Or13Or16TypePacketExpected == 0) && ...
         (g_decArgo_nbOf1Or8TypePacketExpected == 0) && ...
         (g_decArgo_nbOf2Or9TypePacketExpected == 0) && ...
         (g_decArgo_nbOf3Or10TypePacketExpected == 0) && ...
         (g_decArgo_nbOf13Or11TypePacketExpected == 0) && ...
         (g_decArgo_nbOf14Or12TypePacketExpected == 0))
      g_decArgo_secondIridiumSession = 1;
   else
      g_decArgo_secondIridiumSession = 0;
   end
      
elseif (a_whyFlag == 1)
   
   switch (a_decoderId)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      case {201, 202, 203} % Arvor-deep 4000 & 3500
         
         if (g_decArgo_0TypePacketReceivedFlag == 0)
            fprintf('BUFF_INFO: Float #%d: Technical packet #1 is missing\n', ...
               g_decArgo_floatNum);
         end
         if (g_decArgo_4TypePacketReceivedFlag == 0)
            fprintf('BUFF_INFO: Float #%d: Technical packet #2 is missing\n', ...
               g_decArgo_floatNum);
         end
         if (g_decArgo_5TypePacketReceivedFlag == 0)
            fprintf('BUFF_INFO: Float #%d: Parameter packet is missing\n', ...
               g_decArgo_floatNum);
         end
         if (g_decArgo_4TypePacketReceivedFlag == 1)
            if (g_decArgo_nbOf1Or8Or11Or14TypePacketExpected ~= g_decArgo_nbOf1Or8Or11Or14TypePacketReceived)
               fprintf('BUFF_INFO: Float #%d: %d descent data packets are missing\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_nbOf1Or8Or11Or14TypePacketExpected-g_decArgo_nbOf1Or8Or11Or14TypePacketReceived);
            end
            if (g_decArgo_nbOf2Or9Or12Or15TypePacketExpected ~= g_decArgo_nbOf2Or9Or12Or15TypePacketReceived)
               fprintf('BUFF_INFO: Float #%d: %d drift data packets are missing\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_nbOf2Or9Or12Or15TypePacketExpected-g_decArgo_nbOf2Or9Or12Or15TypePacketReceived);
            end
            if (g_decArgo_nbOf3Or10Or13Or16TypePacketExpected ~= g_decArgo_nbOf3Or10Or13Or16TypePacketReceived)
               fprintf('BUFF_INFO: Float #%d: %d ascent data packets are missing\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_nbOf3Or10Or13Or16TypePacketExpected-g_decArgo_nbOf3Or10Or13Or16TypePacketReceived);
            end
         end
         
      case {205, 204, 206, 207, 208}
         % Arvor Iridium 5.41 & 5.42 & 5.4
         % Provor-DO Iridium 5.71 & 5.7 & 5.72

         if (g_decArgo_0TypePacketReceivedFlag == 0)
            fprintf('BUFF_INFO: Float #%d: Technical packet is missing\n', ...
               g_decArgo_floatNum);
         end
         if (g_decArgo_4TypePacketReceivedFlag == 0)
            fprintf('BUFF_INFO: Float #%d: Parameter packet is missing\n', ...
               g_decArgo_floatNum);
         end
         if (g_decArgo_0TypePacketReceivedFlag == 1)
            if (g_decArgo_nbOf1Or8Or11Or14TypePacketExpected ~= g_decArgo_nbOf1Or8Or11Or14TypePacketReceived)
               fprintf('BUFF_INFO: Float #%d: %d descent data packets are missing\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_nbOf1Or8Or11Or14TypePacketExpected-g_decArgo_nbOf1Or8Or11Or14TypePacketReceived);
            end
            if (g_decArgo_nbOf2Or9Or12Or15TypePacketExpected ~= g_decArgo_nbOf2Or9Or12Or15TypePacketReceived)
               fprintf('BUFF_INFO: Float #%d: %d drift data packets are missing\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_nbOf2Or9Or12Or15TypePacketExpected-g_decArgo_nbOf2Or9Or12Or15TypePacketReceived);
            end
            if (g_decArgo_nbOf3Or10Or13Or16TypePacketExpected ~= g_decArgo_nbOf3Or10Or13Or16TypePacketReceived)
               fprintf('BUFF_INFO: Float #%d: %d ascent data packets are missing\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_nbOf3Or10Or13Or16TypePacketExpected-g_decArgo_nbOf3Or10Or13Or16TypePacketReceived);
            end
         end
         
      case {209}
         % Arvor-2DO Iridium 5.73

         if (g_decArgo_0TypePacketReceivedFlag == 0)
            fprintf('BUFF_INFO: Float #%d: Technical packet is missing\n', ...
               g_decArgo_floatNum);
         end
         if (g_decArgo_5TypePacketReceivedFlag == 0)
            fprintf('BUFF_INFO: Float #%d: Parameter packet is missing\n', ...
               g_decArgo_floatNum);
         end
         if (g_decArgo_0TypePacketReceivedFlag == 1)
            if (g_decArgo_nbOf1Or8Or11Or14TypePacketExpected ~= g_decArgo_nbOf1Or8Or11Or14TypePacketReceived)
               fprintf('BUFF_INFO: Float #%d: %d descent data packets are missing\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_nbOf1Or8Or11Or14TypePacketExpected-g_decArgo_nbOf1Or8Or11Or14TypePacketReceived);
            end
            if (g_decArgo_nbOf2Or9Or12Or15TypePacketExpected ~= g_decArgo_nbOf2Or9Or12Or15TypePacketReceived)
               fprintf('BUFF_INFO: Float #%d: %d drift data packets are missing\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_nbOf2Or9Or12Or15TypePacketExpected-g_decArgo_nbOf2Or9Or12Or15TypePacketReceived);
            end
            if (g_decArgo_nbOf3Or10Or13Or16TypePacketExpected ~= g_decArgo_nbOf3Or10Or13Or16TypePacketReceived)
               fprintf('BUFF_INFO: Float #%d: %d ascent data packets are missing\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_nbOf3Or10Or13Or16TypePacketExpected-g_decArgo_nbOf3Or10Or13Or16TypePacketReceived);
            end
         end
         
      case {210}
         % Arvor-ARN Iridium

         if (g_decArgo_0TypePacketReceivedFlag == 0)
            fprintf('BUFF_INFO: Float #%d: Technical #1 packet is missing\n', ...
               g_decArgo_floatNum);
         end
         if (g_decArgo_4TypePacketReceivedFlag == 0)
            fprintf('BUFF_INFO: Float #%d: Technical #2 packet is missing\n', ...
               g_decArgo_floatNum);
         end
         if (g_decArgo_5TypePacketReceivedFlag == 0)
            fprintf('BUFF_INFO: Float #%d: Parameter packet is missing\n', ...
               g_decArgo_floatNum);
         end
         if (g_decArgo_4TypePacketReceivedFlag == 1)
            if (g_decArgo_nbOf1Or8TypePacketExpected ~= g_decArgo_nbOf1Or8TypePacketReceived)
               fprintf('BUFF_INFO: Float #%d: %d descent data packets are missing\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_nbOf1Or8TypePacketExpected-g_decArgo_nbOf1Or8TypePacketReceived);
            end
            if (g_decArgo_nbOf2Or9TypePacketExpected ~= g_decArgo_nbOf2Or9TypePacketReceived)
               fprintf('BUFF_INFO: Float #%d: %d drift data packets are missing\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_nbOf2Or9TypePacketExpected-g_decArgo_nbOf2Or9TypePacketReceived);
            end
            if (g_decArgo_nbOf3Or10TypePacketExpected ~= g_decArgo_nbOf3Or10TypePacketReceived)
               fprintf('BUFF_INFO: Float #%d: %d ascent data packets are missing\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_nbOf3Or10TypePacketExpected-g_decArgo_nbOf3Or10TypePacketReceived);
            end
            if (g_decArgo_nbOf13Or11TypePacketExpected ~= g_decArgo_nbOf13Or11TypePacketReceived)
               fprintf('BUFF_INFO: Float #%d: %d near surface data packets are missing\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_nbOf13Or11TypePacketExpected-g_decArgo_nbOf13Or11TypePacketReceived);
            end
            if (g_decArgo_nbOf14Or12TypePacketExpected ~= g_decArgo_nbOf14Or12TypePacketReceived)
               fprintf('BUFF_INFO: Float #%d: %d in air data packets are missing\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_nbOf14Or12TypePacketExpected-g_decArgo_nbOf14Or12TypePacketReceived);
            end
         end
         
      otherwise
         fprintf('WARNING: Float #%d: Nothing implemented yet to explain what is missing in the buffer for decoderId #%d\n', ...
            g_decArgo_floatNum, ...
            a_decoderId);
   end
end

return;
