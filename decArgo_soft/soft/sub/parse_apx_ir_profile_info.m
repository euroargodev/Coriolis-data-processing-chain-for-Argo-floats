% ------------------------------------------------------------------------------
% Parse Apex Iridium Rudics profile misc information.
%
% SYNTAX :
%  [o_profInfo] = parse_apx_ir_profile_info(a_profInfoDataStr)
%
% INPUT PARAMETERS :
%   a_profInfoDataStr : input ASCII profile misc informtion
%
% OUTPUT PARAMETERS :
%   o_profInfo : profile misc informtion
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profInfo] = parse_apx_ir_profile_info(a_profInfoDataStr)

% output parameters initialization
o_profInfo = [];

% default values
global g_decArgo_janFirst1950InMatlab;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
end

HEADER_1 = '$ Profile';
HEADER_2 = 'terminated:';

for idL = 1:length(a_profInfoDataStr)
   
   dataStr = a_profInfoDataStr{idL};
   if (isempty(dataStr))
      continue;
   end
   
   if (any(strfind(dataStr, HEADER_1)) && any(strfind(dataStr, HEADER_2)))
      
      idF1 = strfind(dataStr, HEADER_1);
      idF2 = strfind(dataStr, HEADER_2);
      
      if (~isempty(idF1)) && (~isempty(idF2))
         
         floatAndCyNum = strtrim(dataStr(idF1(1)+length(HEADER_1):idF2(1)-1));
         idF3 = strfind(floatAndCyNum, '.');
         o_profInfo.FloatRudicsId = strtrim(floatAndCyNum(1:idF3(1)-1));
         o_profInfo.CyNum = strtrim(floatAndCyNum(idF3(1)+1:end));
         profDateStr = strtrim(dataStr(idF2(1)+length(HEADER_2):end));
         profDate = datenum(profDateStr, 'ddd mmm dd HH:MM:SS yyyy') - g_decArgo_janFirst1950InMatlab;
         o_profInfo.ProfTime = profDate;

      else
         fprintf('DEC_INFO: %sAnomaly detected while parsing ''%s'' => ignored\n', errorHeader, dataStr);
         continue;
      end
      
   else
      fprintf('DEC_INFO: %sUnused prof info ''%s''\n', errorHeader, dataStr);
   end
end

return,
