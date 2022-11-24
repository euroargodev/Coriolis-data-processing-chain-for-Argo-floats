% ------------------------------------------------------------------------------
% Decode APEX Argos messages.
%
% SYNTAX :
%  [o_miscInfo, o_auxInfo, o_profData, o_profNstData, o_parkData, o_astData, o_metaData, o_techData, o_trajData, ...
%    o_timeInfo, o_timeData, o_presOffsetData] = ...
%    decode_apx(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, ...
%    a_cycleNum, a_timeData, a_presOffsetData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_argosDataData  : Argos received message data
%   a_argosDataUsed  : Argos used message data
%   a_argosDataDate  : Argos received message dates
%   a_sensorData     : Argos selected data
%   a_sensorDate     : Argos selected data dates
%   a_cycleNum       : cycle number
%   a_timeData       : input cycle time data structure
%   a_presOffsetData : input pressure offset data structure
%   a_decoderId      : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_miscInfo       : misc info from test and data messages
%   o_auxInfo        : auxiliary info from auxiliary engineering data
%   o_profData       : profile data
%   o_profNstData    : NST profile data
%   o_parkData       : parking data
%   o_astData        : AST data
%   o_metaData       : meta data
%   o_techData       : technical data
%   o_trajData       : trajectory data
%   o_timeInfo       : time info from test and data messages
%   o_timeData       : updated cycle time data structure
%   o_presOffsetData : updated pressure offset data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/19/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_miscInfo, o_auxInfo, o_profData, o_profNstData, o_parkData, o_astData, o_surfData, o_metaData, o_techData, o_trajData, ...
   o_timeInfo, o_timeData, o_presOffsetData] = ...
   decode_apx(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, ...
   a_cycleNum, a_timeData, a_presOffsetData, a_decoderId)

% output parameters initialization
o_miscInfo = [];
o_auxInfo = [];
o_profData = [];
o_profNstData = [];
o_parkData = [];
o_astData = [];
o_surfData = [];
o_metaData = [];
o_techData = [];
o_trajData = [];
o_timeInfo = [];
o_timeData = a_timeData;
o_presOffsetData = a_presOffsetData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   case {1001} % 071412
      
      if (a_cycleNum == 0)
         [o_miscInfo, o_metaData, o_techData, o_timeInfo, o_presOffsetData] = ...
            decode_test_apx_1(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, o_presOffsetData);
      else
         [o_miscInfo, o_auxInfo, o_profData, o_parkData, o_metaData, o_techData, o_trajData, o_timeInfo, o_timeData, o_presOffsetData] = ...
            decode_data_apx_1_5(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, a_cycleNum, o_timeData, o_presOffsetData, a_decoderId);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {1002} % 062608
      
      if (a_cycleNum == 0)
         [o_miscInfo, o_metaData, o_techData, o_timeInfo, o_presOffsetData] = ...
            decode_test_apx_2_3(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, o_presOffsetData);
      else
         [o_miscInfo, o_auxInfo, o_profData, o_parkData, o_astData, o_metaData, o_techData, o_trajData, o_timeInfo, o_timeData, o_presOffsetData] = ...
            decode_data_apx_2(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, a_cycleNum, o_timeData, o_presOffsetData, a_decoderId);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {1003} % 061609
      
      if (a_cycleNum == 0)
         [o_miscInfo, o_metaData, o_techData, o_timeInfo, o_presOffsetData] = ...
            decode_test_apx_2_3(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, o_presOffsetData);
      else
         [o_miscInfo, o_auxInfo, o_profData, o_profNstData, o_parkData, o_astData, o_metaData, o_techData, o_trajData, o_timeInfo, o_timeData, o_presOffsetData] = ...
            decode_data_apx_3(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, a_cycleNum, o_timeData, o_presOffsetData, a_decoderId);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {1004} % 021009
      
      if (a_cycleNum == 0)
         [o_miscInfo, o_metaData, o_techData, o_timeInfo, o_presOffsetData] = ...
            decode_test_apx_4(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, o_presOffsetData);
      else
         [o_miscInfo, o_auxInfo, o_profData, o_parkData, o_metaData, o_techData, o_trajData, o_timeInfo, o_timeData, o_presOffsetData] = ...
            decode_data_apx_4(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, a_cycleNum, o_timeData, o_presOffsetData, a_decoderId);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {1005} % 061810
      
      if (a_cycleNum == 0)
         [o_miscInfo, o_metaData, o_techData, o_timeInfo, o_presOffsetData] = ...
            decode_test_apx_5(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, o_presOffsetData);
      else
         [o_miscInfo, o_auxInfo, o_profData, o_parkData, o_metaData, o_techData, o_trajData, o_timeInfo, o_timeData, o_presOffsetData] = ...
            decode_data_apx_1_5(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, a_cycleNum, o_timeData, o_presOffsetData, a_decoderId);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {1006} % 093008
      
      if (a_cycleNum == 0)
         [o_miscInfo, o_metaData, o_techData, o_timeInfo, o_presOffsetData] = ...
            decode_test_apx_6(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, o_presOffsetData);
      else
         [o_miscInfo, o_auxInfo, o_profData, o_parkData, o_astData, o_surfData, o_metaData, o_techData, o_trajData, o_timeInfo, o_timeData, o_presOffsetData] = ...
            decode_data_apx_6(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, a_cycleNum, o_timeData, o_presOffsetData, a_decoderId);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {1007} % 082213
      
      if (a_cycleNum == 0)
         [o_miscInfo, o_metaData, o_techData, o_timeInfo, o_presOffsetData] = ...
            decode_test_apx_7(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, o_presOffsetData);
      else
         [o_miscInfo, o_auxInfo, o_profData, o_parkData, o_metaData, o_techData, o_trajData, o_timeInfo, o_timeData, o_presOffsetData] = ...
            decode_data_apx_7(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, a_cycleNum, o_timeData, o_presOffsetData, a_decoderId);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {1008} % 021208
      
      if (a_cycleNum == 0)
         [o_miscInfo, o_metaData, o_techData, o_timeInfo, o_presOffsetData] = ...
            decode_test_apx_8_14(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, o_presOffsetData);
      else
         [o_miscInfo, o_auxInfo, o_profData, o_parkData, o_surfData, o_metaData, o_techData, o_trajData, o_timeInfo, o_timeData, o_presOffsetData] = ...
            decode_data_apx_8(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, a_cycleNum, o_timeData, o_presOffsetData, a_decoderId);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {1009} % 032213
      
      if (a_cycleNum == 0)
         [o_miscInfo, o_metaData, o_techData, o_timeInfo, o_presOffsetData] = ...
            decode_test_apx_9(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, o_presOffsetData);
      else
         [o_miscInfo, o_auxInfo, o_profData, o_parkData, o_surfData, o_metaData, o_techData, o_trajData, o_timeInfo, o_timeData, o_presOffsetData] = ...
            decode_data_apx_9(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, a_cycleNum, o_timeData, o_presOffsetData, a_decoderId);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {1010} % 110613&090413
      
      if (a_cycleNum == 0)
         [o_miscInfo, o_metaData, o_techData, o_timeInfo, o_presOffsetData] = ...
            decode_test_apx_10(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, o_presOffsetData);
      else
         [o_miscInfo, o_auxInfo, o_profData, o_parkData, o_surfData, o_metaData, o_techData, o_trajData, o_timeInfo, o_timeData, o_presOffsetData] = ...
            decode_data_apx_10(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, a_cycleNum, o_timeData, o_presOffsetData, a_decoderId);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {1011} % 121512
      
      if (a_cycleNum == 0)
         [o_miscInfo, o_metaData, o_techData, o_timeInfo, o_presOffsetData] = ...
            decode_test_apx_11(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, o_presOffsetData);
      else
         [o_miscInfo, o_auxInfo, o_profData, o_parkData, o_metaData, o_techData, o_trajData, o_timeInfo, o_timeData, o_presOffsetData] = ...
            decode_data_apx_11(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, a_cycleNum, o_timeData, o_presOffsetData, a_decoderId);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {1012} % 110813
      
      if (a_cycleNum == 0)
         [o_miscInfo, o_metaData, o_techData, o_timeInfo, o_presOffsetData] = ...
            decode_test_apx_12(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, o_presOffsetData);
      else
         [o_miscInfo, o_auxInfo, o_profData, o_parkData, o_metaData, o_techData, o_trajData, o_timeInfo, o_timeData, o_presOffsetData] = ...
            decode_data_apx_12(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, a_cycleNum, o_timeData, o_presOffsetData, a_decoderId);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {1013} % 071807
      
      if (a_cycleNum == 0)
         [o_miscInfo, o_metaData, o_techData, o_timeInfo, o_presOffsetData] = ...
            decode_test_apx_13_15(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, o_presOffsetData);
      else
         [o_miscInfo, o_auxInfo, o_profData, o_parkData, o_metaData, o_techData, o_trajData, o_timeInfo, o_timeData, o_presOffsetData] = ...
            decode_data_apx_13(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, a_cycleNum, o_timeData, o_presOffsetData, a_decoderId);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {1014} % 082807
      
      if (a_cycleNum == 0)
         [o_miscInfo, o_metaData, o_techData, o_timeInfo, o_presOffsetData] = ...
            decode_test_apx_8_14(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, o_presOffsetData);
      else
         [o_miscInfo, o_auxInfo, o_profData, o_parkData, o_surfData, o_metaData, o_techData, o_trajData, o_timeInfo, o_timeData, o_presOffsetData] = ...
            decode_data_apx_14(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, a_cycleNum, o_timeData, o_presOffsetData, a_decoderId);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {1015} % 020110
      
      if (a_cycleNum == 0)
         [o_miscInfo, o_metaData, o_techData, o_timeInfo, o_presOffsetData] = ...
            decode_test_apx_13_15(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, o_presOffsetData);
      else
         [o_miscInfo, o_auxInfo, o_profData, o_parkData, o_surfData, o_metaData, o_techData, o_trajData, o_timeInfo, o_timeData, o_presOffsetData] = ...
            decode_data_apx_15(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, a_cycleNum, o_timeData, o_presOffsetData, a_decoderId);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {1016} % 090810
      
      if (a_cycleNum == 0)
         [o_miscInfo, o_metaData, o_techData, o_timeInfo, o_presOffsetData] = ...
            decode_test_apx_16(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, o_presOffsetData);
      else
         [o_miscInfo, o_auxInfo, o_profData, o_parkData, o_surfData, o_metaData, o_techData, o_trajData, o_timeInfo, o_timeData, o_presOffsetData] = ...
            decode_data_apx_16(a_argosDataData, a_argosDataUsed, a_argosDataDate, a_sensorData, a_sensorDate, a_cycleNum, o_timeData, o_presOffsetData, a_decoderId);
      end
      
   otherwise
      fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in decode_apex_argos_data for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_decoderId);
end

return;
