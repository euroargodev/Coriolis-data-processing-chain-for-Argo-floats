% ------------------------------------------------------------------------------
% Decode "Profile number" information transmitted by Apex floats.
%
% SYNTAX :
%  [o_cycleNumber, o_cycleNumberCount] = ...
%    decode_apex_cycle_number(a_argosPathFileName, a_decoderId, a_ArgosId, a_checkTestMsg)
%
% INPUT PARAMETERS :
%   a_argosPathFileName : input Argos file path name
%   a_decoderId         : float decoder Id number
%   a_argosId           : float Argos Id number
%   a_checkTestMsg      : the input file can be a test message (first try to
%                         choose between a test or a data messager)
%
% OUTPUT PARAMETERS :
%   o_cycleNumber      : decoded cycle number
%   o_cycleNumberCount : redundancy of the decoded information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/27/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleNumber, o_cycleNumberCount] = ...
   decode_apex_cycle_number(a_argosPathFileName, a_decoderId, a_ArgosId, a_checkTestMsg)

% output parameters initialization
o_cycleNumber = -1;
o_cycleNumberCount = -1;

% current float WMO number
global g_decArgo_floatNum;


% retrieve the list of bytes to freeze
[testMsgBytesToFreeze, dataMsgBytesToFreeze] = get_bytes_to_freeze(a_decoderId);

if (a_checkTestMsg == 1)
   
   % try to identify a test or a data msg
   testSensor = [];
   dataSensor = [];
   bytePos = 6;
   switch (a_decoderId)
      case {1001} % 071412
         
         nbTestMsg = 2;
         [~, ~, ~, ~, ~, ~, ~, ~, testSensor, ~] = get_apex_test_sensor(a_argosPathFileName, ...
            a_ArgosId, 31, nbTestMsg, testMsgBytesToFreeze);
                  
         [~, ~, ~, ~, ~, ~, ~, ~, dataSensor, ~] = get_apex_data_sensor(a_argosPathFileName, ...
            a_ArgosId, 31, dataMsgBytesToFreeze, 999999999);

      otherwise
         fprintf('WARNING: Float #%d: Nothing done yet in decode_apex_cycle_number for decoderId #%d\n', ...
            g_decArgo_floatNum, ...
            a_decoderId);
   end
   
   if (~isempty(testSensor) && ...
         (max(testSensor(:, 1)) > max(dataSensor(:, 1))) && ...
         (size(dataSensor, 1) <= nbTestMsg))
      
      % this is a test message
      o_cycleNumber = 0;
      o_cycleNumberCount = max(testSensor(:, 1));
   else
      
      % this is a data message
      
      % decode profile number information
      if (~isempty(dataSensor))
         for idL = 1:size(dataSensor, 1)
            data = dataSensor(idL, :);
            msgNum = data(2);
            if (msgNum == 1)
               o_cycleNumber = data(bytePos);
               o_cycleNumberCount = data(1);
               break;
            end
         end
      end
   end
         
else
   
   % compute cycle number from data message
   
   sensor = [];
   bytePos = 6;
   switch (a_decoderId)
      case {1001} % 071412
         [~, ~, ~, ~, ~, ~, ~, ~, sensor, ~] = get_apex_data_sensor(a_argosPathFileName, ...
            a_ArgosId, 31, dataMsgBytesToFreeze, 999999999);

      otherwise
         fprintf('WARNING: Float #%d: Nothing done yet in decode_apex_cycle_number for decoderId #%d\n', ...
            g_decArgo_floatNum, ...
            a_decoderId);
   end
   
   % decode profile number information
   if (~isempty(sensor))
      for idL = 1:size(sensor, 1)
         data = sensor(idL, :);
         msgNum = data(2);
         if (msgNum == 1)
            o_cycleNumber = data(bytePos);
            o_cycleNumberCount = data(1);
            break;
         end
      end
   end

end

return;
