% ------------------------------------------------------------------------------
% Get the basic structure to store PROVOR CTS4 decoded
% information.
%
% SYNTAX :
%  [o_decodeData] = get_decoded_data_CTS4_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_decodeData : PROVOR CTS4 decoded structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/10/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decodeData] = get_decoded_data_cts4_init_struct

% output parameter
o_decodeData = struct( ...
   'fileName', '', ... % SBD file name
   'fileDate', '', ... % SBD file date
   'fileSize', '', ... % SBD file size
   'rawData', [], ... % SBD received data
   'decData', [], ... % SBD decoded data
   'cyProfPhaseList', [], ... % information (cycle #, prof #, phase #) on each received packet
   'cyNumFile', -1, ... % cycle number from SBD file name
   'cyNumRaw', -1, ... % transmitted cycle number
   'profNumRaw', -1, ... % transmitted profile number
   'phaseNumRaw', -1, ... % transmitted phase number
   'cyNum', -1, ... % cycle number (set to floatCyNum*100 + floatProfNum))
   'cyNumOut', -1, ... % output cycle number
   'packType', -1, ... % packet type number
   'sensorDataType', -1, ... % sensor data type number
   'sensorType', -1, ... % sensor type number
   'eolFlag', -1, ... % EOL flag provided by the float
   'resetDate', -1, ... % date of the last reset of the float
   'julD2FloatDayOffset', -1, ... % offset between julian day and float day
   'expNbDesc', -1, ... % expected number of packets for descending data
   'expNbDrift', -1, ... % expected number of packets for drift data
   'expNbAsc', -1, ... % expected number of packets for ascending data
   'rankByCycle', -1, ... % number of the decoding buffer (sorted by cycle number)
   'rankByDate', -1, ... % number of the decoding buffer (sorted by SBD transmission date)
   'deep', -1, ... % 1 for a deep cycle, 0 otherwise
   'reset', -1 ... % 1 if a reset has been detected, 0 otherwise
   );

return
