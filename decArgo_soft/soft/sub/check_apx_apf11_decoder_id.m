% ------------------------------------------------------------------------------
% Check if the right decoder is used for a given float using the firmware
% version.
%
% SYNTAX :
%  check_apx_apf11_decoder_id(a_events, a_decoderId)
%
% INPUT PARAMETERS :
%   a_events    : input system_log file event data
%   a_decoderId : decoder id used
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/09/2020 - RNU - creation
% ------------------------------------------------------------------------------
function check_apx_apf11_decoder_id(a_events, a_decoderId)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% decoder Id check flag
global g_decArgo_decIdCheckFlag;


% retrieve firmware version
versionStr = '';
dataStr = a_events(end).message;
idSep = strfind(dataStr, ' ');
if (length(idSep) >= 3)
   dateStr = dataStr(1:idSep(1)-1);
   timeStr = dataStr(idSep(1)+1:idSep(2)-1);
   if ((length(strfind(dateStr, '/')) == 2) && (length(strfind(timeStr, ':')) == 2))
      versionStr = dataStr(idSep(2)+1:idSep(3)-1);
   end
end

% check firmware version against decoder Id
if (~isempty(versionStr))
   
   switch (a_decoderId)
      case 1121
         if (~strcmp(versionStr, '2.11.3'))
            fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float\n', ...
               g_decArgo_floatNum, a_decoderId);
         else
            g_decArgo_decIdCheckFlag = 1;
         end
      case 1122
         if (~strcmp(versionStr, '2.13.1') && ~strcmp(versionStr, '2.13.1.1'))
            fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float\n', ...
               g_decArgo_floatNum, a_decoderId);
         else
            g_decArgo_decIdCheckFlag = 1;
         end
      case 1123
         if (~strcmp(versionStr, '2.12.3'))
            fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float\n', ...
               g_decArgo_floatNum, a_decoderId);
         else
            g_decArgo_decIdCheckFlag = 1;
         end
      case 1124
         if (~strcmp(versionStr, '2.14.3'))
            fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float\n', ...
               g_decArgo_floatNum, a_decoderId);
         else
            g_decArgo_decIdCheckFlag = 1;
         end
      case 1125
         if (~strcmp(versionStr, '2.15.0'))
            fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float\n', ...
               g_decArgo_floatNum, a_decoderId);
         else
            g_decArgo_decIdCheckFlag = 1;
         end
      case 1126
         if (~strcmp(versionStr, '2.10.4'))
            fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float\n', ...
               g_decArgo_floatNum, a_decoderId);
         else
            g_decArgo_decIdCheckFlag = 1;
         end
      case 1127
         if (~strcmp(versionStr, '2.12.2.1'))
            fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float\n', ...
               g_decArgo_floatNum, a_decoderId);
         else
            g_decArgo_decIdCheckFlag = 1;
         end
      case 1321
         if (~strcmp(versionStr, '2.10.1'))
            fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float\n', ...
               g_decArgo_floatNum, a_decoderId);
         else
            g_decArgo_decIdCheckFlag = 1;
         end
      case 1322
         if (~strcmp(versionStr, '2.11.1'))
            fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float\n', ...
               g_decArgo_floatNum, a_decoderId);
         else
            g_decArgo_decIdCheckFlag = 1;
         end
      case 1323
         if (~strcmp(versionStr, '2.12.2.1'))
            fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float\n', ...
               g_decArgo_floatNum, a_decoderId);
         else
            g_decArgo_decIdCheckFlag = 1;
         end
         
      otherwise
         
         fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in check_apx_apf11_decoder_id for decoderId #%d\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            a_decoderId);
         
   end
   
else
   fprintf('ERROR: Float #%d Cycle #%d: Unable to retrieve firmware version\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
end

return
