% ------------------------------------------------------------------------------
% Store technical message data for output NetCDF file.
%
% SYNTAX :
%  store_tech_data_for_nc_2002(a_tabTech, a_deepCycle)
%
% INPUT PARAMETERS :
%   a_tabTech   : decoded technical data
%   a_deepCycle : deep cycle flag
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/28/2016 - RNU - creation
% ------------------------------------------------------------------------------
function store_tech_data_for_nc_2002(a_tabTech, a_deepCycle)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% final EOL flag (float in EOL mode and cycle number set to 256 by the decoder)
global g_decArgo_finalEolMode;

ID_OFFSET = 1;


if (isempty(a_tabTech))
   return;
end

% retrieve technical message data
if (g_decArgo_finalEolMode == 0)
   if (size(a_tabTech, 1) > 1)
      fprintf('WARNING: Float #%d cycle #%d: %d tech message in the buffer => using the last one\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         size(a_tabTech, 1));
   end
   tabTech = a_tabTech(end, :);
   
   if (a_deepCycle == 1)
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 100];
      g_decArgo_outputNcParamValue{end+1} = format_time_hhmmss_dec_argo(tabTech(1+ID_OFFSET));
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 101];
      g_decArgo_outputNcParamValue{end+1} = format_time_hhmmss_dec_argo(tabTech(2+ID_OFFSET));
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 102];
      g_decArgo_outputNcParamValue{end+1} = format_time_hhmmss_dec_argo(tabTech(3+ID_OFFSET));
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 103];
      g_decArgo_outputNcParamValue{end+1} = format_time_hhmmss_dec_argo(tabTech(4+ID_OFFSET));
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 104];
      g_decArgo_outputNcParamValue{end+1} = format_time_hhmmss_dec_argo(tabTech(5+ID_OFFSET));
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 105];
      g_decArgo_outputNcParamValue{end+1} = format_time_hhmmss_dec_argo(tabTech(6+ID_OFFSET));
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 106];
      g_decArgo_outputNcParamValue{end+1} = tabTech(7+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 107];
      g_decArgo_outputNcParamValue{end+1} = tabTech(8+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 108];
      g_decArgo_outputNcParamValue{end+1} = tabTech(9+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 109];
      g_decArgo_outputNcParamValue{end+1} = tabTech(10+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 110];
      g_decArgo_outputNcParamValue{end+1} = tabTech(11+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 111];
      g_decArgo_outputNcParamValue{end+1} = tabTech(12+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 112];
      g_decArgo_outputNcParamValue{end+1} = tabTech(13+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 113];
      g_decArgo_outputNcParamValue{end+1} = tabTech(14+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 114];
      g_decArgo_outputNcParamValue{end+1} = tabTech(19+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 115];
      g_decArgo_outputNcParamValue{end+1} = tabTech(20+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 116];
      g_decArgo_outputNcParamValue{end+1} = tabTech(21+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 117];
      g_decArgo_outputNcParamValue{end+1} = tabTech(22+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 118];
      g_decArgo_outputNcParamValue{end+1} = tabTech(23+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 119];
      g_decArgo_outputNcParamValue{end+1} = tabTech(24+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 120];
      g_decArgo_outputNcParamValue{end+1} = tabTech(25+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 121];
      g_decArgo_outputNcParamValue{end+1} = tabTech(26+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 122];
      g_decArgo_outputNcParamValue{end+1} = tabTech(27+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 123];
      g_decArgo_outputNcParamValue{end+1} = tabTech(28+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 124];
      g_decArgo_outputNcParamValue{end+1} = tabTech(29+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 125];
      g_decArgo_outputNcParamValue{end+1} = tabTech(31+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 126];
      g_decArgo_outputNcParamValue{end+1} = tabTech(32+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 127];
      g_decArgo_outputNcParamValue{end+1} = tabTech(33+ID_OFFSET);
      
      % decode flags of CTD communication errors
      missionErrorCtdFpFlag = 0; % flag for error on CTD Fast Pressure command
      missionErrorCtdStartProfileFlag = 0; % flag for error on CTD Start Profile command
      missionErrorCtdStopProfileFlag = 0; % flag for error on CTD Stop Profile command
      missionErrorCtdDownloadFlag = 0; % flag for error on CTD Download command
      missionErrorCtdAverageFlag = 0; % flag for error on CTD Average command
      
      ctdCmdErrorFlag = tabTech(34+ID_OFFSET);
      if (ctdCmdErrorFlag ~= 0)
         if (bitand(ctdCmdErrorFlag, 1) == 1)
            missionErrorCtdFpFlag = 1;
         end
         if (bitand(ctdCmdErrorFlag, 2) == 2)
            missionErrorCtdStartProfileFlag = 1;
         end
         if (bitand(ctdCmdErrorFlag, 4) == 4)
            missionErrorCtdStopProfileFlag = 1;
         end
         if (bitand(ctdCmdErrorFlag, 8) == 8)
            missionErrorCtdDownloadFlag = 1;
         end
         if (bitand(ctdCmdErrorFlag, 16) == 16)
            missionErrorCtdAverageFlag = 1;
         end
      end
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 128];
      g_decArgo_outputNcParamValue{end+1} = missionErrorCtdFpFlag;
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 129];
      g_decArgo_outputNcParamValue{end+1} = missionErrorCtdStartProfileFlag;
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 130];
      g_decArgo_outputNcParamValue{end+1} = missionErrorCtdStopProfileFlag;
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 131];
      g_decArgo_outputNcParamValue{end+1} = missionErrorCtdDownloadFlag;
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 132];
      g_decArgo_outputNcParamValue{end+1} = missionErrorCtdAverageFlag;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 133];
      g_decArgo_outputNcParamValue{end+1} = tabTech(35+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 134];
      g_decArgo_outputNcParamValue{end+1} = tabTech(36+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 135];
      g_decArgo_outputNcParamValue{end+1} = tabTech(37+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 136];
      g_decArgo_outputNcParamValue{end+1} = tabTech(40+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 137];
      g_decArgo_outputNcParamValue{end+1} = tabTech(41+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 138];
      g_decArgo_outputNcParamValue{end+1} = tabTech(42+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 139];
      g_decArgo_outputNcParamValue{end+1} = tabTech(43+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 140];
      g_decArgo_outputNcParamValue{end+1} = tabTech(44+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 141];
      g_decArgo_outputNcParamValue{end+1} = tabTech(49+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 142];
      g_decArgo_outputNcParamValue{end+1} = tabTech(50+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 143];
      g_decArgo_outputNcParamValue{end+1} = tabTech(51+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 144];
      g_decArgo_outputNcParamValue{end+1} = tabTech(52+ID_OFFSET);
      
   else
      
      offset = 10000;
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 121+offset];
      g_decArgo_outputNcParamValue{end+1} = tabTech(26+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 122+offset];
      g_decArgo_outputNcParamValue{end+1} = tabTech(27+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 125+offset];
      g_decArgo_outputNcParamValue{end+1} = tabTech(31+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 141+offset];
      g_decArgo_outputNcParamValue{end+1} = tabTech(49+ID_OFFSET);
      
   end
else
   
   % final EOL mode is detected
   offset = 10000;
   for idTech = 1:size(a_tabTech, 1)
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 121+offset];
      g_decArgo_outputNcParamValue{end+1} = a_tabTech(idTech, 26+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 122+offset];
      g_decArgo_outputNcParamValue{end+1} = a_tabTech(idTech, 27+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 125+offset];
      g_decArgo_outputNcParamValue{end+1} = a_tabTech(idTech, 31+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 141+offset];
      g_decArgo_outputNcParamValue{end+1} = a_tabTech(idTech, 49+ID_OFFSET);
   end
end
 
return;
