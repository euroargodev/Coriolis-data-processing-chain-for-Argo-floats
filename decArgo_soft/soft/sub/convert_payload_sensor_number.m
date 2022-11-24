% ------------------------------------------------------------------------------
% Convert the sensor number (from the payload cards) to the decoder sensor
% number.
%
% SYNTAX :
%  [o_argoSensorNum] = convert_payload_sensor_number(a_payloadSensorNum)
%
% INPUT PARAMETERS :
%   a_payloadSensorNum : number of the sensor in the payload card
%
% OUTPUT PARAMETERS :
%   o_argoSensorNum : decoder conresponding sensor number
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_argoSensorNum] = convert_payload_sensor_number(a_payloadSensorNum)

% output parameters initialization
o_argoSensorNum = [];

% current float WMO number
global g_decArgo_floatNum;

% sensor list
global g_decArgo_sensorList;


switch a_payloadSensorNum
   case 1 % BGC: ECOPuck_LF Not BGC: OCR507_UART1 => 103
      if (ismember(3, g_decArgo_sensorList))
         o_argoSensorNum = 3;
      elseif (ismember(103, g_decArgo_sensorList))
         o_argoSensorNum = 103;
      end
   case 2 % BGC: OCR504ICSW Not BGC: OCR507_UART2 => 104
      if (ismember(2, g_decArgo_sensorList))
         o_argoSensorNum = 2;
      elseif (ismember(104, g_decArgo_sensorList))
         o_argoSensorNum = 104;
      end
   case 3 % BGC: unused Not BGC: PSA-916
      o_argoSensorNum = 101;
   case 4 % BGC: SUNA Not BGC: OptTak => 102 or ECOPuck => 105
      if (ismember(6, g_decArgo_sensorList))
         o_argoSensorNum = 6;
      elseif (ismember(102, g_decArgo_sensorList))
         o_argoSensorNum = 102;
      elseif (ismember(105, g_decArgo_sensorList))
         o_argoSensorNum = 105;
      end
   case 6 % BGC: PHSEABIRD_UART6 Not BGC: UVP6 => 107
      if (ismember(107, g_decArgo_sensorList))
         o_argoSensorNum = 107;
      else
         o_argoSensorNum = 7;
      end
   case 7 % BGC: Optode Not BGC: Tilt => 106
      if (ismember(1, g_decArgo_sensorList))
         o_argoSensorNum = 1;
      elseif (ismember(106, g_decArgo_sensorList))
         o_argoSensorNum = 106;
      end
      
   otherwise
      fprintf('ERROR: Float #%d: Don''t know how to convert payload sensor #%d\n', ...
         g_decArgo_floatNum, ...
         a_payloadSensorNum);
end

return
