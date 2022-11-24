% ------------------------------------------------------------------------------
% Store GPS data in a cell array.
%
% SYNTAX :
% store_gps_data_ir_rudics_cts5(a_apmtTech, a_fileTypeNum)
%
% INPUT PARAMETERS :
%   a_apmtTech    : float APMT technical data
%   a_fileTypeNum : type of APMT technical file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function store_gps_data_ir_rudics_cts5(a_apmtTech, a_fileTypeNum)

% array to store GPS data
global g_decArgo_gpsData;

% current cycle and pattern number
global g_decArgo_cycleNumFloat;
global g_decArgo_patternNumFloat;

% cycle phases
global g_decArgo_phasePreMission;
global g_decArgo_phaseSatTrans;
global g_decArgo_phaseEndOfLife;

% global default values
global g_decArgo_dateDef;


if (~isempty(a_apmtTech))
   if (isfield(a_apmtTech, 'GPS'))
      
      idF1 = find(strcmp(a_apmtTech.GPS.name, 'GPS location date'), 1);
      idF2 = find(strcmp(a_apmtTech.GPS.name, 'GPS location longitude'), 1);
      idF3 = find(strcmp(a_apmtTech.GPS.name, 'GPS location latitude'), 1);
      if (~isempty(idF1) && ~isempty(idF2) && ~isempty(idF3))
         
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
         
         % the Provor CTS5 provides only valid GPS locations
         gpsLocCycleNum = [gpsLocCycleNum; g_decArgo_cycleNumFloat];
         if (~isempty(g_decArgo_patternNumFloat))
            gpsLocProfNum = [gpsLocProfNum; g_decArgo_patternNumFloat];
         else
            gpsLocProfNum = [gpsLocProfNum; 0];
         end
         if (a_fileTypeNum == 3)
            % '*_autotest_*.txt'
            locPhase = g_decArgo_phasePreMission;
         elseif (a_fileTypeNum == 4)
            % '*_technical*.txt'
            locPhase = g_decArgo_phaseSatTrans;
         elseif (a_fileTypeNum == 5)
            % '*_default_*.txt'
            locPhase = g_decArgo_phaseEndOfLife;
         end
         gpsLocPhase = [gpsLocPhase; locPhase];
         gpsLocDate = [gpsLocDate; a_apmtTech.GPS.data{idF1}];
         gpsLocLon = [gpsLocLon; a_apmtTech.GPS.data{idF2}];
         gpsLocLat = [gpsLocLat; a_apmtTech.GPS.data{idF3}];
         gpsLocQc = [gpsLocQc; 0];
         gpsLocAccuracy = [gpsLocAccuracy; 'G'];
         gpsLocSbdFileDate = [gpsLocSbdFileDate; g_decArgo_dateDef];
         
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

return;
