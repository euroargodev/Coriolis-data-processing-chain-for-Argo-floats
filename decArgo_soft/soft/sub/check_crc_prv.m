% ------------------------------------------------------------------------------
% Check data according to PROVOR CRC.
%
% SYNTAX :
%  [o_crcCheckOk] = check_crc_prv(a_sensor, a_decoderId)
%
% INPUT PARAMETERS :
%   a_sensor    : data to be checked
%   a_decoderId : float decoder Id
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
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_crcCheckOk] = check_crc_prv(a_sensor, a_decoderId)

switch (a_decoderId)
   case {1, 3, 4, 11, 12, 17, 19, 24, 25, 27, 28, 29, 30, 31, 32}

      % retrieve Argos message CRC value and set CRC bits (#5 to #20) to 0
      [a_sensor, expectedCrc] = set_bits(0, 5, 16, a_sensor);

      % compute the CRC for these data
      computedCrc = compute_crc_prv(a_sensor);

      if (computedCrc == expectedCrc)
         o_crcCheckOk = 1;
      else
         o_crcCheckOk = 0;
      end
   otherwise
      fprintf('WARNING: Nothing done yet in check_crc_prv for decoderId #%d\n', ...
         a_decoderId);
end

return

% ------------------------------------------------------------------------------
% Compute PROVOR CRC for given data.
%
% SYNTAX :
%  [o_computedCrc] = compute_crc_prv(a_sensor)
%
% INPUT PARAMETERS :
%   a_sensor : data to check
%
% OUTPUT PARAMETERS :
%   o_computedCrc : computed CRC
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_computedCrc] = compute_crc_prv(a_sensor)

% add 8 bits set to 0 at the end of the data
if (length(a_sensor) == 31)
   a_sensor(end+1) = 0;
end

% compute CRC
poly = uint16(hex2dec('1021'));
crc = uint16(0);
for idByte = 1:length(a_sensor)
   crc = bitxor(crc, bitshift(uint16(a_sensor(idByte)), 8));
   for idBit = 1:8
      droppedBit = bitget(crc, 16);
      crc = bitshift(crc, 1);
      if (droppedBit == 1)
         crc = bitxor(crc, poly);
      end
   end
end

o_computedCrc = crc;

return
