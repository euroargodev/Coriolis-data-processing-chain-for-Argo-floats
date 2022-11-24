% ------------------------------------------------------------------------------
% Store GPS data in a cell array.
%
% SYNTAX :
%  store_gps_data_ir_sbd_nva_2003(a_tabTech)
%
% INPUT PARAMETERS :
%   a_tabTech : float technical data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/08/2018 - RNU - creation
% ------------------------------------------------------------------------------
function store_gps_data_ir_sbd_nva_2003(a_tabTech)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% array to store GPS data
global g_decArgo_gpsData;

% cycle timings storage
global g_decArgo_timeData;

% final EOL flag (float in EOL mode and cycle number set to 256 by the decoder)
global g_decArgo_finalEolMode;


ID_OFFSET = 1;

if (~isempty(a_tabTech))
   
   if ((g_decArgo_finalEolMode == 0) && (size(a_tabTech, 1) > 1))
      fprintf('ERROR: Float #%d cycle #%d: BUFFER anomaly (%d tech message in the buffer)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         size(a_tabTech, 1));
   end
   
   % retrieve cycle dates from g_decArgo_timeData structure
   idCycleStruct = find([g_decArgo_timeData.cycleNum] == g_decArgo_cycleNum);
   gpsTimeList = [];
   if (~isempty([g_decArgo_timeData.cycleTime(idCycleStruct).gpsTime]))
      gpsTimeList = julian_2_gregorian_dec_argo([g_decArgo_timeData.cycleTime(idCycleStruct).gpsTime]);
      gpsTimeList = cellstr(gpsTimeList(:, 9:end));
   end
   
   for idTech = 1:size(a_tabTech, 1)
      
      % no GPS fix in the TECH message
      if ((a_tabTech(idTech, 39+ID_OFFSET) == 0) && ...
            (a_tabTech(idTech, 40+ID_OFFSET) == 0))
         return
      end

      % unpack the GPS data
      if (~isempty(g_decArgo_gpsData))
         gpsLocCycleNum = g_decArgo_gpsData{1};
         gpsLocProfNum = g_decArgo_gpsData{2};
         gpsLocPhase = g_decArgo_gpsData{3};
         gpsLocDate = g_decArgo_gpsData{4};
         gpsLocLon = g_decArgo_gpsData{5};
         gpsLocLat = g_decArgo_gpsData{6};
         gpsLocQc = g_decArgo_gpsData{7};
         gpsLocAccuracy = g_decArgo_gpsData{8};
         gpsLocSbdFileDate = g_decArgo_gpsData{9};
      else
         gpsLocCycleNum = [];
         gpsLocProfNum = [];
         gpsLocPhase = [];
         gpsLocDate = [];
         gpsLocLon = [];
         gpsLocLat = [];
         gpsLocQc = [];
         gpsLocAccuracy = [];
         gpsLocSbdFileDate = [];
      end
      
      % append new GPS fix information
      gpsLocCycleNum = [gpsLocCycleNum; g_decArgo_cycleNum];
      gpsLocProfNum = [gpsLocProfNum; -1];
      gpsLocPhase = [gpsLocPhase; -1];
      
      gpsTime = sprintf('%02d %s', ...
         a_tabTech(idTech, 39+ID_OFFSET), ...
         format_time_dec_argo(a_tabTech(idTech, 40+ID_OFFSET)));
      idF = find(strcmp(gpsTime, gpsTimeList));
      
      if (~isempty(idF))
         
         if (length(idF) > 1)
            [~, idMin] = min(abs([g_decArgo_timeData.cycleTime(idCycleStruct(idF)).gpsTime] - a_tabTech(idTech, end)));
            idF = idF(idMin);
         end
         
         if (~isempty(g_decArgo_timeData.cycleTime(idCycleStruct(idF)).gpsTimeAdj))
            
            gpsLocDate = [gpsLocDate; g_decArgo_timeData.cycleTime(idCycleStruct(idF)).gpsTimeAdj];
            
            gpsLocLon = [gpsLocLon; a_tabTech(idTech, 38+ID_OFFSET)];
            gpsLocLat = [gpsLocLat; a_tabTech(idTech, 37+ID_OFFSET)];
            gpsLocQc = [gpsLocQc; 0];
            gpsLocAccuracy = [gpsLocAccuracy; 'G'];
            gpsLocSbdFileDate = [gpsLocSbdFileDate; a_tabTech(idTech, end)];
            
            % update GPS data global variable
            g_decArgo_gpsData{1} = gpsLocCycleNum;
            g_decArgo_gpsData{2} = gpsLocProfNum;
            g_decArgo_gpsData{3} = gpsLocPhase;
            g_decArgo_gpsData{4} = gpsLocDate;
            g_decArgo_gpsData{5} = gpsLocLon;
            g_decArgo_gpsData{6} = gpsLocLat;
            g_decArgo_gpsData{7} = gpsLocQc;
            g_decArgo_gpsData{8} = gpsLocAccuracy;
            g_decArgo_gpsData{9} = gpsLocSbdFileDate;
         end
      end
   end
end

return
