% ------------------------------------------------------------------------------
% Decode cycle number transmitted by an Argos float.
%
% SYNTAX :
%  [o_cycleNumber] = decode_cycle_number(a_argosFileName, ...
%    a_floatNum, a_argosId, a_frameLength, a_decoderId)
%
% INPUT PARAMETERS :
%   a_argosFileName : Argos transmitted file
%   a_floatNum      : float WMO number
%   a_argosId       : Argos Id
%   a_frameLength   : Argos float message length
%   a_decoderId     : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_cycleNumber : decoded cycle number
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/10/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleNumber] = decode_cycle_number(a_argosFileName, ...
   a_floatNum, a_argosId, a_frameLength, a_decoderId)

% output parameters initialization
o_cycleNumber = [];


% read Argos file
[argosLocDate, argosLocLon, argosLocLat, argosLocAcc, argosLocSat, ...
   argosDataDate, argosDataData] = read_argos_file_fmt1({a_argosFileName}, a_argosId, a_frameLength);

% select only the Argos messages with a good CRC
idMsgCrcOk = 0;
tabSensors = [];
for idMsg = 1:size(argosDataData, 1)
   sensor = argosDataData(idMsg, :);
   
   if (check_crc_prv(sensor, a_decoderId) == 1)
      % CRC check succeeded
      idMsgCrcOk = idMsgCrcOk + 1;
      tabSensors(idMsgCrcOk, :) = sensor';
   end
end

if (~isempty(tabSensors))
   
   % format the data to be decoded
   tabType = get_message_type(tabSensors, a_decoderId);
   sensors = [tabType ones(size(tabSensors, 1), 1) tabSensors];
   
   % decode cycle number from the Argos data
   switch (a_decoderId)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {30} % V4.52
         
         % decode CTD and technical messages
         [cycleNumber] = decode_cycle_number_30(sensors);
         
      otherwise
         fprintf('WARNING: Float #%d: Nothing done yet in decode_cycle_number for decoderId #%d\n', ...
            a_floatNum, ...
            a_decoderId);
   end
   
   if (~isempty(cycleNumber))
      uCycleNumber = unique(cycleNumber);
      if (length(uCycleNumber) == 1)
         o_cycleNumber = uCycleNumber;
      else
         o_cycleNumber = -1;
         fprintf('WARNING: Float #%d: Multiple cycle numbers decoded from file: %s\n', ...
            a_floatNum, a_argosFileName);
      end
   end
end

return;
