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
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
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
   case {222, 223}
      % decId = 222 or 223 => firmware is 5900A05
      % expected checksum:
      % for 5900A05: hex2dec('2C97') = 11415
      if (a_checkSum ~= 11415)
         fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float\n', ...
            a_floatNum, a_decoderId);
      else
         g_decArgo_decIdCheckFlag = 1;
      end
end

return
