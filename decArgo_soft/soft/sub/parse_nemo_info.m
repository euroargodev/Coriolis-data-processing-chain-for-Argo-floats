% ------------------------------------------------------------------------------
% Parse NEMO information data.
%
% SYNTAX :
%  [o_infoData] = parse_nemo_info(a_infoStr)
%
% INPUT PARAMETERS :
%   a_infoStr : input ASCII information data
%
% OUTPUT PARAMETERS :
%   o_infoData : information data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/04/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_infoData] = parse_nemo_info(a_infoStr)

% output parameters initialization
o_infoData = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
end

% split information in a structure label.value
for idInfo = 1:length(a_infoStr)
   
   dataStr = a_infoStr{idInfo};
   
   idF = strfind(dataStr, char(9));
   if (~isempty(idF))
      itemName = dataStr(1:idF(1)-1);
      if (itemName(1) == '-')
         itemName(1) = [];
      end
      itemValue = strtrim(dataStr(idF(1)+1:end));
      o_infoData.(itemName) = itemValue;
   else
      fprintf('WARNING: %s inconsistent line ''%s''\n', errorHeader, dataStr);
   end
end

return,
