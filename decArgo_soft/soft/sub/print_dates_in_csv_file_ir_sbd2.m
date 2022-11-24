% ------------------------------------------------------------------------------
% Print decoded dates in output CSV file.
%
% SYNTAX :
%  print_dates_in_csv_file_ir_sbd2( ...
%    a_cycleStartDate, a_buoyancyRedStartDate, ...
%    a_descentToParkStartDate, ...
%    a_firstStabDate, a_firstStabPres, ...
%    a_descentToParkEndDate, ...
%    a_descentToProfStartDate, a_descentToProfEndDate, ...
%    a_ascentStartDate, a_ascentEndDate, ...
%    a_transStartDate, ...
%    a_dataCTD, a_dataOXY, a_dataFLBB, a_dataFLNTU, a_dataCYCLOPS, a_dataSEAPOINT, ...
%    a_gpsData)
%
% INPUT PARAMETERS :
%   a_cycleStartDate          : cycle start date
%   a_buoyancyRedStartDate    : buoyancy reduction start date
%   a_descentToParkStartDate  : descent to park start date
%   a_firstStabDate           : first stabilisation date
%   a_firstStabPres           : first stabilisation pressure
%   a_descentToParkEndDate    : descent to park end date
%   a_descentToProfStartDate  : descent to profile start date
%   a_descentToProfEndDate    : descent to profile end date
%   a_ascentStartDate         : ascent start date
%   a_ascentEndDate           : ascent end date
%   a_transStartDate          : transmission start date
%   a_dataCTD                 : decoded CTD data
%   a_dataOXY                 : decoded OXY data
%   a_dataFLBB                : decoded FLBB data
%   a_dataFLNTU               : decoded FLNTU data
%   a_dataCYCLOPS             : decoded CYCLOPS data
%   a_dataSEAPOINT            : decoded SEAPOINT data
%   a_gpsData                 : information on GPS locations
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function print_dates_in_csv_file_ir_sbd2( ...
   a_cycleStartDate, a_buoyancyRedStartDate, ...
   a_descentToParkStartDate, ...
   a_firstStabDate, a_firstStabPres, ...
   a_descentToParkEndDate, ...
   a_descentToProfStartDate, a_descentToProfEndDate, ...
   a_ascentStartDate, a_ascentEndDate, ...
   a_transStartDate, ...
   a_dataCTD, a_dataOXY, a_dataFLBB, a_dataFLNTU, a_dataCYCLOPS, a_dataSEAPOINT, ...
   a_gpsData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_dateDef;
global g_decArgo_vertSpeed;

% cycle phases
global g_decArgo_phasePreMission;
global g_decArgo_phaseSurfWait;
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseAscProf;
global g_decArgo_phaseSatTrans;
global g_decArgo_phaseEndOfLife;
global g_decArgo_phaseEmergencyAsc;


% unpack the input data
a_dataCTDMean = a_dataCTD{1};
a_dataCTDMeanDate = a_dataCTDMean{1};
a_dataCTDMeanDateTrans = a_dataCTDMean{2};
a_dataCTDMeanPres = a_dataCTDMean{3};

a_dataOXYMean = a_dataOXY{1};
a_dataOXYMeanDate = a_dataOXYMean{1};
a_dataOXYMeanDateTrans = a_dataOXYMean{2};
a_dataOXYMeanPres = a_dataOXYMean{3};

a_dataFLBBMean = [];
a_dataFLBBMeanDate = [];
a_dataFLBBMeanDateTrans = [];
a_dataFLBBMeanPres = [];
if (~isempty(a_dataFLBB))
   a_dataFLBBMean = a_dataFLBB{1};
   a_dataFLBBMeanDate = a_dataFLBBMean{1};
   a_dataFLBBMeanDateTrans = a_dataFLBBMean{2};
   a_dataFLBBMeanPres = a_dataFLBBMean{3};
end

a_dataFLNTUMean = [];
a_dataFLNTUMeanDate = [];
a_dataFLNTUMeanDateTrans = [];
a_dataFLNTUMeanPres = [];
if (~isempty(a_dataFLNTU))
   a_dataFLNTUMean = a_dataFLNTU{1};
   a_dataFLNTUMeanDate = a_dataFLNTUMean{1};
   a_dataFLNTUMeanDateTrans = a_dataFLNTUMean{2};
   a_dataFLNTUMeanPres = a_dataFLNTUMean{3};
end

a_dataCYCLOPSMean = [];
a_dataCYCLOPSMeanDate = [];
a_dataCYCLOPSMeanDateTrans = [];
a_dataCYCLOPSMeanPres = [];
if (~isempty(a_dataCYCLOPS))
   a_dataCYCLOPSMean = a_dataCYCLOPS{1};
   a_dataCYCLOPSMeanDate = a_dataCYCLOPSMean{1};
   a_dataCYCLOPSMeanDateTrans = a_dataCYCLOPSMean{2};
   a_dataCYCLOPSMeanPres = a_dataCYCLOPSMean{3};
end

a_dataSEAPOINTMean = [];
a_dataSEAPOINTMeanDate = [];
a_dataSEAPOINTMeanDateTrans = [];
a_dataSEAPOINTMeanPres = [];
if (~isempty(a_dataSEAPOINT))
   a_dataSEAPOINTMean = a_dataSEAPOINT{1};
   a_dataSEAPOINTMeanDate = a_dataSEAPOINTMean{1};
   a_dataSEAPOINTMeanDateTrans = a_dataSEAPOINTMean{2};
   a_dataSEAPOINTMeanPres = a_dataSEAPOINTMean{3};
end

a_gpsLocCycleNum = a_gpsData{1};
a_gpsLocProfNum = a_gpsData{2};
a_gpsLocPhase = a_gpsData{3};
a_gpsLocDate = a_gpsData{4};
a_gpsLocLon = a_gpsData{5};
a_gpsLocLat = a_gpsData{6};
a_gpsLocQc = a_gpsData{7};
a_gpsLocAccuracy = a_gpsData{8};
a_gpsLocSbdFileDate = a_gpsData{9};

% array for data information storage
tabDataCycle = [];
tabDataProf = [];
tabDataPhase = [];
tabDataType = [];
tabDataDate = [];
tabDataDateTrans = [];
tabDataPres = [];

% store the dated pressures
if (~isempty(a_dataCTDMeanDate))
   for idC = 4:size(a_dataCTDMeanDate, 2)
      tabDataCycle = [tabDataCycle; a_dataCTDMeanDate(:, 1)];
      tabDataProf = [tabDataProf; a_dataCTDMeanDate(:, 2)];
      tabDataPhase = [tabDataPhase; a_dataCTDMeanDate(:, 3)];
      tabDataType = [tabDataType; ones(size(a_dataCTDMeanDate, 1), 1)*0];
      tabDataDate = [tabDataDate; a_dataCTDMeanDate(:, idC)];
      tabDataDateTrans = [tabDataDateTrans; a_dataCTDMeanDateTrans(:, idC)];
      tabDataPres = [tabDataPres; a_dataCTDMeanPres(:, idC)];
   end
end

if (~isempty(a_dataOXYMeanDate))
   for idC = 4:size(a_dataOXYMeanDate, 2)
      tabDataCycle = [tabDataCycle; a_dataOXYMeanDate(:, 1)];
      tabDataProf = [tabDataProf; a_dataOXYMeanDate(:, 2)];
      tabDataPhase = [tabDataPhase; a_dataOXYMeanDate(:, 3)];
      tabDataType = [tabDataType; ones(size(a_dataOXYMeanDate, 1), 1)*3];
      tabDataDate = [tabDataDate; a_dataOXYMeanDate(:, idC)];
      tabDataDateTrans = [tabDataDateTrans; a_dataOXYMeanDateTrans(:, idC)];
      tabDataPres = [tabDataPres; a_dataOXYMeanPres(:, idC)];
   end
end

if (~isempty(a_dataFLBBMeanDate))
   for idC = 4:size(a_dataFLBBMeanDate, 2)
      tabDataCycle = [tabDataCycle; a_dataFLBBMeanDate(:, 1)];
      tabDataProf = [tabDataProf; a_dataFLBBMeanDate(:, 2)];
      tabDataPhase = [tabDataPhase; a_dataFLBBMeanDate(:, 3)];
      tabDataType = [tabDataType; ones(size(a_dataFLBBMeanDate, 1), 1)*6];
      tabDataDate = [tabDataDate; a_dataFLBBMeanDate(:, idC)];
      tabDataDateTrans = [tabDataDateTrans; a_dataFLBBMeanDateTrans(:, idC)];
      tabDataPres = [tabDataPres; a_dataFLBBMeanPres(:, idC)];
   end
end

if (~isempty(a_dataFLNTUMeanDate))
   for idC = 4:size(a_dataFLNTUMeanDate, 2)
      tabDataCycle = [tabDataCycle; a_dataFLNTUMeanDate(:, 1)];
      tabDataProf = [tabDataProf; a_dataFLNTUMeanDate(:, 2)];
      tabDataPhase = [tabDataPhase; a_dataFLNTUMeanDate(:, 3)];
      tabDataType = [tabDataType; ones(size(a_dataFLNTUMeanDate, 1), 1)*15];
      tabDataDate = [tabDataDate; a_dataFLNTUMeanDate(:, idC)];
      tabDataDateTrans = [tabDataDateTrans; a_dataFLNTUMeanDateTrans(:, idC)];
      tabDataPres = [tabDataPres; a_dataFLNTUMeanPres(:, idC)];
   end
end

if (~isempty(a_dataCYCLOPSMeanDate))
   for idC = 4:size(a_dataCYCLOPSMeanDate, 2)
      tabDataCycle = [tabDataCycle; a_dataCYCLOPSMeanDate(:, 1)];
      tabDataProf = [tabDataProf; a_dataCYCLOPSMeanDate(:, 2)];
      tabDataPhase = [tabDataPhase; a_dataCYCLOPSMeanDate(:, 3)];
      tabDataType = [tabDataType; ones(size(a_dataCYCLOPSMeanDate, 1), 1)*37];
      tabDataDate = [tabDataDate; a_dataCYCLOPSMeanDate(:, idC)];
      tabDataDateTrans = [tabDataDateTrans; a_dataCYCLOPSMeanDateTrans(:, idC)];
      tabDataPres = [tabDataPres; a_dataCYCLOPSMeanPres(:, idC)];
   end
end

if (~isempty(a_dataSEAPOINTMeanDate))
   for idC = 4:size(a_dataSEAPOINTMeanDate, 2)
      tabDataCycle = [tabDataCycle; a_dataSEAPOINTMeanDate(:, 1)];
      tabDataProf = [tabDataProf; a_dataSEAPOINTMeanDate(:, 2)];
      tabDataPhase = [tabDataPhase; a_dataSEAPOINTMeanDate(:, 3)];
      tabDataType = [tabDataType; ones(size(a_dataSEAPOINTMeanDate, 1), 1)*40];
      tabDataDate = [tabDataDate; a_dataSEAPOINTMeanDate(:, idC)];
      tabDataDateTrans = [tabDataDateTrans; a_dataSEAPOINTMeanDateTrans(:, idC)];
      tabDataPres = [tabDataPres; a_dataSEAPOINTMeanPres(:, idC)];
   end
end

profNumList = sort(unique(a_cycleStartDate(:, 2)));
for idPrf = 1:length(profNumList)
   profNum = profNumList(idPrf);
   
   % pre_mission dates
   idGPSToUse = find( ...
      (a_gpsLocCycleNum == g_decArgo_cycleNum) & ...
      (a_gpsLocProfNum == profNum) & ...
      (a_gpsLocPhase == g_decArgo_phasePreMission));
   for id = 1:length(idGPSToUse)
      idLoc = idGPSToUse(id);
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; GPS #%d (%s); %s; %.4f; %.4f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(0), ...
         id, get_phase_name(a_gpsLocPhase(idLoc)), ...
         julian_2_gregorian_dec_argo(a_gpsLocDate(idLoc)), ...
         a_gpsLocLon(idLoc), a_gpsLocLat(idLoc));
   end
   
   % surf wait dates
   idTechToUse = find( ...
      (a_cycleStartDate(:, 1) == g_decArgo_cycleNum) & ...
      (a_cycleStartDate(:, 2) == profNum) & ...
      (a_cycleStartDate(:, 3) == g_decArgo_phaseSurfWait));
   if (~isempty(idTechToUse))
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; CYCLE START DATE; %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(1), ...
         julian_2_gregorian_dec_argo(a_cycleStartDate(idTechToUse, 5)));
      
      idGPSToUse = find( ...
         (a_gpsLocCycleNum == g_decArgo_cycleNum) & ...
         (a_gpsLocProfNum == profNum) & ...
         (a_gpsLocPhase == g_decArgo_phaseSurfWait));
      for id = 1:length(idGPSToUse)
         idLoc = idGPSToUse(id);
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; GPS #%d (%s); %s; %.4f; %.4f\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(1), ...
            id, get_phase_name(a_gpsLocPhase(idLoc)), ...
            julian_2_gregorian_dec_argo(a_gpsLocDate(idLoc)), ...
            a_gpsLocLon(idLoc), a_gpsLocLat(idLoc));
      end
   end
   
   % subsurface dates
   idTechToUse = find( ...
      (a_cycleStartDate(:, 1) == g_decArgo_cycleNum) & ...
      (a_cycleStartDate(:, 2) == profNum) & ...
      (a_cycleStartDate(:, 3) == g_decArgo_phaseSatTrans));
      
   if (~isempty(idTechToUse))
      cycleStartDate = a_cycleStartDate(idTechToUse, 5);
      buoyancyRedStartDate = a_buoyancyRedStartDate(idTechToUse, 5);
      descentToParkStartDate = a_descentToParkStartDate(idTechToUse, 5);
      firstStabDate = a_firstStabDate(idTechToUse, 5);
      firstStabPres = a_firstStabPres(idTechToUse, 5);
      descentToParkEndDate = a_descentToParkEndDate(idTechToUse, 5);
      descentToProfStartDate = a_descentToProfStartDate(idTechToUse, 5);
      descentToProfEndDate = a_descentToProfEndDate(idTechToUse, 5);
      ascentStartDate = a_ascentStartDate(idTechToUse, 5);
      ascentEndDate = a_ascentEndDate(idTechToUse, 5);
      transStartDate = a_transStartDate(idTechToUse, 5);
      profNum = a_cycleStartDate(idTechToUse, 2);
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; CYCLE START DATE; %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(2), ...
         julian_2_gregorian_dec_argo(cycleStartDate));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; BUOYANCY REDUCTION START DATE; %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(4), ...
         julian_2_gregorian_dec_argo(buoyancyRedStartDate));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; DESCENT TO PARK START DATE; %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(5), ...
         julian_2_gregorian_dec_argo(descentToParkStartDate));
      
      descVertSpeed = g_decArgo_vertSpeed;
      if ((firstStabDate ~= g_decArgo_dateDef) && (firstStabDate ~= descentToParkStartDate))
         descVertSpeed = (firstStabPres*100)/ ...
            ((firstStabDate-descentToParkStartDate)*86400);
      end
      if (descVertSpeed ~= g_decArgo_vertSpeed)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; FIRST STABILIZATION DATE; %s; %d; dbar; =>; %.1f; cm/s\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(5), ...
            julian_2_gregorian_dec_argo(firstStabDate), ...
            firstStabPres, descVertSpeed);
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; FIRST STABILIZATION DATE; %s; %d; dbar\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(5), ...
            julian_2_gregorian_dec_argo(firstStabDate), ...
            firstStabPres);
      end
      
      % descent to park phase
      idDataUsed = find((tabDataCycle == g_decArgo_cycleNum) & ...
         (tabDataProf == profNum) & ...
         (tabDataPhase == g_decArgo_phaseDsc2Prk) & ...
         (tabDataDate ~= g_decArgo_dateDef) & ...
         (tabDataDateTrans ~= -1));
      meanDescVertSpeed = g_decArgo_vertSpeed;
      if (~isempty(idDataUsed))
         tabDescDataType = tabDataType(idDataUsed);
         tabDescDataDate = tabDataDate(idDataUsed);
         tabDescDataPres = tabDataPres(idDataUsed);
         
         [tabDescDataDate, idSort] = sort(tabDescDataDate);
         tabDescDataType = tabDescDataType(idSort);
         tabDescDataPres = tabDescDataPres(idSort);
         
         for idMes = 1:length(tabDescDataDate)
            if ((idMes > 1) && (tabDescDataDate(idMes) - tabDescDataDate(idMes-1) ~= 0))
               vertSpeed = ((tabDescDataPres(idMes)-tabDescDataPres(idMes-1))*10)/ ...
                  ((tabDescDataDate(idMes)-tabDescDataDate(idMes-1))*86400);
               
               fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; dated meas (%s); %s; %.1f; dbar; =>; %.1f; cm/s\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(5), ...
                  get_data_type_name(tabDescDataType(idMes)), ...
                  julian_2_gregorian_dec_argo(tabDescDataDate(idMes)), ...
                  tabDescDataPres(idMes)/10, vertSpeed);
            else
               fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; dated meas (%s); %s; %.1f; dbar\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(5), ...
                  get_data_type_name(tabDescDataType(idMes)), ...
                  julian_2_gregorian_dec_argo(tabDescDataDate(idMes)), ...
                  tabDescDataPres(idMes)/10);
            end
         end
         
         if ((length(tabDescDataDate) > 1) && (tabDescDataDate(end) - tabDescDataDate(1) ~= 0))
            meanDescVertSpeed = ((tabDescDataPres(end)-tabDescDataPres(1))*10)/ ...
               ((tabDescDataDate(end)-tabDescDataDate(1))*86400);
         end
      end
      
      if (meanDescVertSpeed == g_decArgo_vertSpeed)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; DESCENT TO PARK END DATE; %s\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(6), ...
            julian_2_gregorian_dec_argo(descentToParkEndDate));
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; DESCENT TO PARK END DATE; %s; ; ; =>; %.1f; cm/s; (mean for descent)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(6), ...
            julian_2_gregorian_dec_argo(descentToParkEndDate), ...
            meanDescVertSpeed);
      end
      
      % drift at park phase
      idDataUsed = find((tabDataCycle == g_decArgo_cycleNum) & ...
         (tabDataProf == profNum) & ...
         (tabDataPhase == g_decArgo_phaseParkDrift) & ...
         (tabDataDate ~= g_decArgo_dateDef) & ...
         (tabDataDateTrans ~= -1));
      if (~isempty(idDataUsed))
         tabDescDataType = tabDataType(idDataUsed);
         tabDescDataDate = tabDataDate(idDataUsed);
         tabDescDataPres = tabDataPres(idDataUsed);
         
         [tabDescDataDate, idSort] = sort(tabDescDataDate);
         tabDescDataType = tabDescDataType(idSort);
         tabDescDataPres = tabDescDataPres(idSort);
         
         for id = 1:length(tabDescDataDate)
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; dated meas (%s); %s; %.1f; dbar\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(6), ...
               get_data_type_name(tabDescDataType(id)), ...
               julian_2_gregorian_dec_argo(tabDescDataDate(id)), ...
               tabDescDataPres(id)/10);
         end
      end
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; DESCENT TO PROF START DATE; %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(7), ...
         julian_2_gregorian_dec_argo(descentToProfStartDate));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; DESCENT TO PROF END DATE; %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(8), ...
         julian_2_gregorian_dec_argo(descentToProfEndDate));
      
      % ascent phase
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; ASCENT START DATE; %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(9), ...
         julian_2_gregorian_dec_argo(ascentStartDate));
      
      idDataUsed = find((tabDataCycle == g_decArgo_cycleNum) & ...
         (tabDataProf == profNum) & ...
         (tabDataPhase == g_decArgo_phaseAscProf) & ...
         (tabDataDate ~= g_decArgo_dateDef) & ...
         (tabDataDateTrans ~= -1));
      meanAscVertSpeed = g_decArgo_vertSpeed;
      if (~isempty(idDataUsed))
         tabAscDataType = tabDataType(idDataUsed);
         tabAscDataDate = tabDataDate(idDataUsed);
         tabAscDataPres = tabDataPres(idDataUsed);
         
         [tabAscDataDate, idSort] = sort(tabAscDataDate);
         tabAscDataType = tabAscDataType(idSort);
         tabAscDataPres = tabAscDataPres(idSort);
         
         for idMes = 1:length(tabAscDataDate)
            if ((idMes > 1) && (tabAscDataDate(idMes) - tabAscDataDate(idMes-1) ~= 0))
               vertSpeed = ((-tabAscDataPres(idMes)+tabAscDataPres(idMes-1))*10)/ ...
                  ((tabAscDataDate(idMes)-tabAscDataDate(idMes-1))*86400);
               
               fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; dated meas (%s); %s; %.1f; dbar; =>; %.1f; cm/s\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(9), ...
                  get_data_type_name(tabAscDataType(idMes)), ...
                  julian_2_gregorian_dec_argo(tabAscDataDate(idMes)), ...
                  tabAscDataPres(idMes)/10, vertSpeed);
            else
               fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; dated meas (%s); %s; %.1f; dbar\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(9), ...
                  get_data_type_name(tabAscDataType(idMes)), ...
                  julian_2_gregorian_dec_argo(tabAscDataDate(idMes)), ...
                  tabAscDataPres(idMes)/10);
            end
         end
         
         if ((length(tabAscDataDate) > 1) && (tabAscDataDate(end) - tabAscDataDate(1) ~= 0))
            meanAscVertSpeed = ((-tabAscDataPres(end)+tabAscDataPres(1))*10)/ ...
               ((tabAscDataDate(end)-tabAscDataDate(1))*86400);
         end
      end
      
      if (meanAscVertSpeed ~= g_decArgo_vertSpeed)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; ASCENT END DATE; %s; ; ; =>; %.1f; cm/s; (mean for ascent)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(10), ...
            julian_2_gregorian_dec_argo(ascentEndDate), ...
            meanAscVertSpeed);
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; ASCENT END DATE; %s\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(10), ...
            julian_2_gregorian_dec_argo(ascentEndDate));
      end
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; TRANSMISSION START DATE; %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(12), ...
         julian_2_gregorian_dec_argo(transStartDate));
   end
   
   % transmission phase
   idGPSToUse = find( ...
      (a_gpsLocCycleNum == g_decArgo_cycleNum) & ...
      (a_gpsLocProfNum == profNum) & ...
      (a_gpsLocPhase == g_decArgo_phaseSatTrans));
   for id = 1:length(idGPSToUse)
      idLoc = idGPSToUse(id);
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; GPS #%d (%s); %s; %.4f; %.4f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(12), ...
         id, get_phase_name(a_gpsLocPhase(idLoc)), ...
         julian_2_gregorian_dec_argo(a_gpsLocDate(idLoc)), ...
         a_gpsLocLon(idLoc), a_gpsLocLat(idLoc));
   end
   
   % EOL phase
   idGPSToUse = find( ...
      (a_gpsLocCycleNum == g_decArgo_cycleNum) & ...
      (a_gpsLocProfNum == profNum) & ...
      (a_gpsLocPhase == g_decArgo_phaseEndOfLife));
   for id = 1:length(idGPSToUse)
      idLoc = idGPSToUse(id);
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; GPS #%d (%s); %s; %.4f; %.4f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(14), ...
         id, get_phase_name(a_gpsLocPhase(idLoc)), ...
         julian_2_gregorian_dec_argo(a_gpsLocDate(idLoc)), ...
         a_gpsLocLon(idLoc), a_gpsLocLat(idLoc));
   end
   
   % emergency phase
   idGPSToUse = find( ...
      (a_gpsLocCycleNum == g_decArgo_cycleNum) & ...
      (a_gpsLocProfNum == profNum) & ...
      (a_gpsLocPhase == g_decArgo_phaseEmergencyAsc));
   for id = 1:length(idGPSToUse)
      idLoc = idGPSToUse(id);
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; GPS #%d (%s); %s; %.4f; %.4f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, profNum, get_phase_name(15), ...
         id, get_phase_name(a_gpsLocPhase(idLoc)), ...
         julian_2_gregorian_dec_argo(a_gpsLocDate(idLoc)), ...
         a_gpsLocLon(idLoc), a_gpsLocLat(idLoc));
   end
   
end

return;
