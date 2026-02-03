% ------------------------------------------------------------------------------
% Retrieve value from byte array.
%
% SYNTAX :
% [o_data, o_curByte] = get_bytes_pfv2(a_data, a_curByte, a_Nbytes)
%
% INPUT PARAMETERS :
%   a_data    : byte array
%   a_curByte : current byte position
%   a_Nbytes  : number of bytes to consider
%
% OUTPUT PARAMETERS :
%   o_data    : value
%   o_curByte : current byte position
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/07/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_data, o_curByte] = get_bytes_pfv2(a_data, a_curByte, a_Nbytes)

% output parameters initialization
o_data = [];

switch (a_Nbytes)
   
   case 1
      o_data = a_data(a_curByte);
      o_curByte = a_curByte + 1;
   case 2
      rawData = get_bits(1, 16, a_data(a_curByte:a_curByte+1));
      o_data = double(swapbytes(uint16(rawData)));
      o_curByte = a_curByte + 2;
   case -2
      rawData = get_bits(1, 16, a_data(a_curByte:a_curByte+1));
      o_data = double(swapbytes(int16(rawData)));
      o_curByte = a_curByte + 2;
   case 4
      rawData = get_bits(1, 32, a_data(a_curByte:a_curByte+3));
      o_data = double(swapbytes(uint32(rawData)));
      o_curByte = a_curByte + 4;
   case 5
      rawData = get_bits(1, 32, a_data(a_curByte:a_curByte+3));
      o_data = double(typecast(swapbytes(uint32(rawData)), 'single'));
      o_curByte = a_curByte + 4;
   case 32
      o_data = [];
      o_curByte = a_curByte + 32;
end

return
