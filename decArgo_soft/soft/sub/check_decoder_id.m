% ------------------------------------------------------------------------------
% Check if the right decoder is used for a given float using the checksum of
% its firmware version.
%
% SYNTAX :
%  check_decoder_id(a_checkSum, a_decoderId, a_floatNum)
%
% INPUT PARAMETERS :
%   a_checkSum  : checksum of the firmware version of the drifter
%   a_decoderId : decoder id used
%   a_floatNum  : float number
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/28/2020 - RNU - creation
% ------------------------------------------------------------------------------
function check_decoder_id(a_checkSum, a_decoderId, a_floatNum)

% decoder Id check flag
global g_decArgo_decIdCheckFlag;


switch (a_decoderId)
   case 212
      % decId = 212 => firmware is 5900A03 or 5900A04
      % expected checksum:
      % for 5900A03: hex2dec('97BC') = 38844
      % for 5900A04: hex2dec('B8C9') = 47305
      if ((a_checkSum ~= 38844) && (a_checkSum ~= 47305))
         fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float\n', ...
            a_floatNum, a_decoderId);
      else
         g_decArgo_decIdCheckFlag = 1;
      end
   case {214, 217}
      % decId = 214 or 217 => firmware is 5900A04
      % expected checksum:
      % for 5900A04: hex2dec('B8C9') = 47305
      if (a_checkSum ~= 47305)
         fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float\n', ...
            a_floatNum, a_decoderId);
      else
         g_decArgo_decIdCheckFlag = 1;
      end
   case {222, 223, 225}
      % decId = 222 or 223 or 225 => firmware is 5900A05
      % expected checksum:
      % for 5900A05: hex2dec('2C97') = 11415
      if (a_checkSum ~= 11415)
         fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float\n', ...
            a_floatNum, a_decoderId);
      else
         g_decArgo_decIdCheckFlag = 1;
      end
   case {224}
      % decId = 224 => firmware is 5900A06
      % expected checksum:
      % for 5900A06: hex2dec('ab9b') = 43931
      if (a_checkSum ~= 43931)
         fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float\n', ...
            a_floatNum, a_decoderId);
      else
         g_decArgo_decIdCheckFlag = 1;
      end
   case {226, 231}
      % decId = 226 => firmware is 5900A07
      % decId = 231 => firmware is 5900A07
      % expected checksum:
      % for 5900A07: hex2dec('a847') = 43079
      if (a_checkSum ~= 43079)
         fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float\n', ...
            a_floatNum, a_decoderId);
      else
         g_decArgo_decIdCheckFlag = 1;
      end
   case {227}
      % decId = 227 => firmware is 5900A08
      % expected checksum:
      % for 5900A08: hex2dec('FC75') = 64629
      if (a_checkSum ~= 64629)
         fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float\n', ...
            a_floatNum, a_decoderId);
      else
         g_decArgo_decIdCheckFlag = 1;
      end
   case {232}
      % decId = 232 => firmware is 5900A05B
      % expected checksum:
      % for 5900A05B: hex2dec('3630') = 13872
      if (a_checkSum ~= 13872)
         fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float\n', ...
            a_floatNum, a_decoderId);
      else
         g_decArgo_decIdCheckFlag = 1;
      end
end

return
