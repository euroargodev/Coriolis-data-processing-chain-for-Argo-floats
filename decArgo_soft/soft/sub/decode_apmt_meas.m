% ------------------------------------------------------------------------------
% Decode measurement data transmitted by a CTS5 float.
%
% SYNTAX :
%  [o_rawData] = decode_apmt_meas(a_rawData, a_nbBits, a_signedFlag, a_inputFilePathName)
%
% INPUT PARAMETERS :
%   a_rawData           : input data
%   a_nbBits            : number of bits for the data
%   a_signedFlag        : data signed flag
%   a_inputFilePathName : concerned file
%
% OUTPUT PARAMETERS :
%   o_rawData : output data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/02/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_rawData] = decode_apmt_meas(a_rawData, a_nbBits, a_signedFlag, a_inputFilePathName)

% decode the data according to number of bits and signed flag
switch (a_nbBits)
   case {16}
      if (a_signedFlag == 0)
         o_rawData = typecast(swapbytes(uint16(a_rawData)), 'uint16');
      else
         o_rawData = typecast(swapbytes(uint16(a_rawData)), 'int16');
      end
   case {32}
      if (a_signedFlag == 0)
         o_rawData = typecast(swapbytes(uint32(a_rawData)), 'uint32');
      else
         o_rawData = typecast(swapbytes(uint32(a_rawData)), 'int32');
      end
   otherwise
      fprintf('ERROR: Unexpected number of bits in file: %s\n', a_inputFilePathName);
      o_rawData = nan;
end

return
