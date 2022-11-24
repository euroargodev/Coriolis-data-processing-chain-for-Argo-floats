% ------------------------------------------------------------------------------
% Parse Apex Iridium Rudics configuration data from .msg file.
%
% SYNTAX :
%  [o_configData] = parse_apx_ir_config_data(a_configDataStr)
%
% INPUT PARAMETERS :
%   a_configDataStr : input ASCII configuration data
%
% OUTPUT PARAMETERS :
%   o_configData : configuration data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configData] = parse_apx_ir_config_data(a_configDataStr)

% output parameters initialization
o_configData = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
end

HEADER = '$ Mission configuration for';

for idConf = 1:length(a_configDataStr)
   
   dataStr = a_configDataStr{idConf};
   if (isempty(dataStr))
      continue;
   end
   
   if (any(strfind(dataStr, HEADER)))
      
      idF1 = strfind(dataStr, '(');
      idF2 = strfind(dataStr, ')');
      idF3 = strfind(dataStr, ':');
      idF4 = strfind(dataStr, ' ');
      
      if (~isempty(idF1)) && (~isempty(idF2) && ~isempty(idF3))
         %             item = strtrim(dataStr(length(HEADER)+1:idF1(1)-1));
         item = 'FloatRudicsId';
         value = strtrim(dataStr(idF1(1)+1:idF2(1)-1));
         unit = '';
         o_configData.(item) = value;
         o_configData.([item '_unit']) = unit;
         
         item = 'FirmRev';
         idF = find(idF4 < idF3);
         value = strtrim(dataStr(idF4(idF(end))+1:idF3(1)-1));
         unit = '';
         o_configData.(item) = value;
         o_configData.([item '_unit']) = unit;
         
      else
         fprintf('DEC_INFO: %sAnomaly detected while parsing ''%s'' => ignored\n', errorHeader, dataStr);
         continue;
      end
      
   else
      
      idF1 = strfind(dataStr, '(');
      idF2 = strfind(dataStr, ')');
      idF3 = strfind(dataStr, '[');
      idF4 = strfind(dataStr, ']');
      
      if (~isempty(idF1)) && (~isempty(idF2))
         if (~isempty(idF3)) && (~isempty(idF4))
            item = strtrim(dataStr(2:idF1(1)-1));
            value = strtrim(dataStr(idF1(1)+1:idF2(1)-1));
            unit = strtrim(dataStr(idF3(1)+1:idF4(1)-1));
         else
            item = strtrim(dataStr(2:idF1(1)-1));
            value = strtrim(dataStr(idF1(1)+1:idF2(1)-1));
            unit = '';
         end
         if (isempty(regexp(lower(item(1)), '[a-z]', 'once')))
            fprintf('DEC_INFO: %sAnomaly detected while parsing ''%s''=> ignored\n', errorHeader, dataStr);
            continue;
         end
         if (any(strfind(item, ' ')))
            fprintf('DEC_INFO: %sAnomaly detected while parsing ''%s''=> ignored\n', errorHeader, dataStr);
            continue;
         end
         o_configData.(item) = value;
         o_configData.([item '_unit']) = unit;
      else
         fprintf('DEC_INFO: %sAnomaly detected while parsing ''%s'' => ignored\n', errorHeader, dataStr);
         continue;
      end
   end
end

return,
