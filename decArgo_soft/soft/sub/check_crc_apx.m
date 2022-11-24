% ------------------------------------------------------------------------------
% Check data according to APEX CRC.
%
% SYNTAX :
%  [o_crcCheckOk] = check_crc_apx_prv(a_sensor)
%
% INPUT PARAMETERS :
%   a_sensor : data to be checked (32 bytes: the received CRC value followed by
%              the received 31 data bytes)
%
% OUTPUT PARAMETERS :
%   o_crcCheckOk : check result (1: succeded, 0: failed)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/15/2007 - RNU - creation
% ------------------------------------------------------------------------------
function [o_crcCheckOk] = check_crc_apx(a_sensor)

if (a_sensor(1) == compute_crc(a_sensor(2:length(a_sensor))))
   o_crcCheckOk = 1;
else
   o_crcCheckOk = 0;
end

return;

% ------------------------------------------------------------------------------
% WRC 31 bytes CRC algorithm.
%
% SYNTAX :
%   [o_computedCrc] = compute_crc(a_sensor)
%
% INPUT PARAMETERS :
%   a_sensor : 31 data bytes
%
% OUTPUT PARAMETERS :
%   o_computedCrc : computed CRC value
%
% EXAMPLES :
%
% SEE ALSO : hasard
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/15/2007 - RNU - creation
% ------------------------------------------------------------------------------
function [o_computedCrc] = compute_crc(a_sensor)

byteN = a_sensor(1);
for id = 2:length(a_sensor)
   byteN = hasard(byteN);
   byteN = bitxor(byteN, a_sensor(id));
end
o_computedCrc = hasard(byteN);
   
return;

function [o_byteN] = hasard(a_byteN)

if (a_byteN == 0)
   o_byteN = 127;
   return
end

x = 0;
if (bitand(a_byteN, 1) == 1)
   x = x + 1;
end
if (bitand(a_byteN, 4) == 4)
   x = x + 1;
end
if (bitand(a_byteN, 8) == 8)
   x = x + 1;
end
if (bitand(a_byteN, 16) == 16)
   x = x + 1;
end

if (bitand(x, 1) == 1)
   o_byteN = fix(a_byteN/2) + 128;
else
   o_byteN = fix(a_byteN/2);
end

return;

function test_crc()

ckeckData = '8F 00 08 1C 8E 47 23 91 48 A4 D2 E9 74 3A 1D 0E 07 03 81 C0 60 30 98 4C 26 93 49 24 92 C9 64 B2';
[val, count, errmsg, nextindex] = sscanf(ckeckData, '%x ');

fprintf('CRC Données: %d\n', val(1));
fprintf('CRC Calculé: %d\n', compute_crc(val(2:32)));

return;
