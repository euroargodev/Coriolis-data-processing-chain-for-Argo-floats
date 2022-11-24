% ------------------------------------------------------------------------------
% Print decoded dates in output CSV file.
%
% SYNTAX :
%  print_dates_in_csv_file_ir_rudics_cts4_111_113( ...
%    a_decoderId, ...
%    a_cycleStartDate, a_buoyancyRedStartDate, ...
%    a_descentToParkStartDate, ...
%    a_firstStabDate, a_firstStabPres, ...
%    a_descentToParkEndDate, ...
%    a_descentToProfStartDate, a_descentToProfEndDate, ...
%    a_ascentStartDate, a_ascentEndDate, ...
%    a_transStartDate, ...
%    a_buoyancyInvStartDate, ...
%    a_firstGroundDate, a_firstGroundPres, ...
%    a_firstHangDate, a_firstHangPres, ...
%    a_firstEmerAscentDate, a_firstEmergencyAscentPres, ...
%    a_dataCTD, a_dataOXY, a_dataOCR, ...
%    a_dataECO2, a_dataECO3, a_dataFLNTU, ...
%    a_dataCROVER, a_dataSUNA, ...
%    a_gpsData)
%
% INPUT PARAMETERS :
%   a_cycleStartDate           : cycle start date
%   a_buoyancyRedStartDate     : buoyancy reduction start date
%   a_descentToParkStartDate   : descent to park start date
%   a_firstStabDate            : first stabilisation date
%   a_firstStabPres            : first stabilisation pressure
%   a_descentToParkEndDate     : descent to park end date
%   a_descentToProfStartDate   : descent to profile start date
%   a_descentToProfEndDate     : descent to profile end date
%   a_ascentStartDate          : ascent start date
%   a_ascentEndDate            : ascent end date
%   a_transStartDate           : transmission start date
%   a_buoyancyInvStartDate     : buoyancy inversion start date
%   a_firstGroundDate          : first grounding date
%   a_firstGroundPres          : first grounding pressure
%   a_firstHangDate            : first hanging date
%   a_firstHangPres            : first hanging pressure
%   a_firstEmerAscentDate      : first emergency ascent date
%   a_firstEmergencyAscentPres : first emergency ascent pressure
%   a_dataCTD                  : decoded CTD data
%   a_dataOXY                  : decoded OXY data
%   a_dataOCR                  : decoded OCR data
%   a_dataECO2                 : decoded ECO2 data
%   a_dataECO3                 : decoded ECO3 data
%   a_dataFLNTU                : decoded FLNTU data
%   a_dataCROVER               : decoded cROVER data
%   a_dataSUNA                 : decoded SUNA data
%   a_gpsData                  : information on GPS locations
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function print_dates_in_csv_file_ir_rudics_cts4_111_113( ...
   a_decoderId, ...
   a_cycleStartDate, a_buoyancyRedStartDate, ...
   a_descentToParkStartDate, ...
   a_firstStabDate, a_firstStabPres, ...
   a_descentToParkEndDate, ...
   a_descentToProfStartDate, a_descentToProfEndDate, ...
   a_ascentStartDate, a_ascentEndDate, ...
   a_transStartDate, ...
   a_buoyancyInvStartDate, ...
   a_firstGroundDate, a_firstGroundPres, ...
   a_firstHangDate, a_firstHangPres, ...
   a_firstEmerAscentDate, a_firstEmergencyAscentPres, ...
   a_dataCTD, a_dataOXY, a_dataOCR, ...
   a_dataECO2, a_dataECO3, a_dataFLNTU, ...
   a_dataCROVER, a_dataSUNA, ...
   a_gpsData)

% current float WMO number
global g_decArgo_floatNum;

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
a_dataCTDRaw = a_dataCTD{2};

a_dataCTDMeanDate = a_dataCTDMean{1};
a_dataCTDMeanDateTrans = a_dataCTDMean{2};
a_dataCTDMeanPres = a_dataCTDMean{3};

a_dataCTDRawDate = a_dataCTDRaw{1};
a_dataCTDRawDateTrans = a_dataCTDRaw{2};
a_dataCTDRawPres = a_dataCTDRaw{3};

a_dataOXYMean = a_dataOXY{1};
a_dataOXYRaw = a_dataOXY{2};

a_dataOXYMeanDate = a_dataOXYMean{1};
a_dataOXYMeanDateTrans = a_dataOXYMean{2};
a_dataOXYMeanPres = a_dataOXYMean{3};

a_dataOXYRawDate = a_dataOXYRaw{1};
a_dataOXYRawDateTrans = a_dataOXYRaw{2};
a_dataOXYRawPres = a_dataOXYRaw{3};

a_dataOCRMean = a_dataOCR{1};
a_dataOCRRaw = a_dataOCR{2};

a_dataOCRMeanDate = a_dataOCRMean{1};
a_dataOCRMeanDateTrans = a_dataOCRMean{2};
a_dataOCRMeanPres = a_dataOCRMean{3};

a_dataOCRRawDate = a_dataOCRRaw{1};
a_dataOCRRawDateTrans = a_dataOCRRaw{2};
a_dataOCRRawPres = a_dataOCRRaw{3};

a_dataECO2Mean = a_dataECO2{1};
a_dataECO2Raw = a_dataECO2{2};

a_dataECO2MeanDate = a_dataECO2Mean{1};
a_dataECO2MeanDateTrans = a_dataECO2Mean{2};
a_dataECO2MeanPres = a_dataECO2Mean{3};

a_dataECO2RawDate = a_dataECO2Raw{1};
a_dataECO2RawDateTrans = a_dataECO2Raw{2};
a_dataECO2RawPres = a_dataECO2Raw{3};

a_dataECO3Mean = a_dataECO3{1};
a_dataECO3Raw = a_dataECO3{2};

a_dataECO3MeanDate = a_dataECO3Mean{1};
a_dataECO3MeanDateTrans = a_dataECO3Mean{2};
a_dataECO3MeanPres = a_dataECO3Mean{3};

a_dataECO3RawDate = a_dataECO3Raw{1};
a_dataECO3RawDateTrans = a_dataECO3Raw{2};
a_dataECO3RawPres = a_dataECO3Raw{3};

a_dataFLNTUMean = a_dataFLNTU{1};
a_dataFLNTURaw = a_dataFLNTU{2};

a_dataFLNTUMeanDate = a_dataFLNTUMean{1};
a_dataFLNTUMeanDateTrans = a_dataFLNTUMean{2};
a_dataFLNTUMeanPres = a_dataFLNTUMean{3};

a_dataFLNTURawDate = a_dataFLNTURaw{1};
a_dataFLNTURawDateTrans = a_dataFLNTURaw{2};
a_dataFLNTURawPres = a_dataFLNTURaw{3};

a_dataCROVERMean = a_dataCROVER{1};
a_dataCROVERRaw = a_dataCROVER{2};

a_dataCROVERMeanDate = a_dataCROVERMean{1};
a_dataCROVERMeanDateTrans = a_dataCROVERMean{2};
a_dataCROVERMeanPres = a_dataCROVERMean{3};

a_dataCROVERRawDate = a_dataCROVERRaw{1};
a_dataCROVERRawDateTrans = a_dataCROVERRaw{2};
a_dataCROVERRawPres = a_dataCROVERRaw{3};

a_dataSUNAMean = a_dataSUNA{1};
a_dataSUNARaw = a_dataSUNA{2};
a_dataSUNAAPF = a_dataSUNA{4};
a_dataSUNAAPF2 = a_dataSUNA{5};

a_dataSUNAMeanDate = a_dataSUNAMean{1};
a_dataSUNAMeanDateTrans = a_dataSUNAMean{2};
a_dataSUNAMeanPres = a_dataSUNAMean{3};

a_dataSUNARawDate = a_dataSUNARaw{1};
a_dataSUNARawDateTrans = a_dataSUNARaw{2};
a_dataSUNARawPres = a_dataSUNARaw{3};

a_dataSUNAAPFDate = a_dataSUNAAPF{1};
a_dataSUNAAPFDateTrans = a_dataSUNAAPF{2};
a_dataSUNAAPFCTDPres = a_dataSUNAAPF{3};

if (~isempty(a_dataSUNAAPF2))
   a_dataSUNAAPF2Date = a_dataSUNAAPF2{1};
   a_dataSUNAAPF2DateTrans = a_dataSUNAAPF2{2};
   a_dataSUNAAPF2CTDPres = a_dataSUNAAPF2{3};
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

if (~isempty(a_dataCTDRawDate))
   for idC = 4:size(a_dataCTDRawDate, 2)
      tabDataCycle = [tabDataCycle; a_dataCTDRawDate(:, 1)];
      tabDataProf = [tabDataProf; a_dataCTDRawDate(:, 2)];
      tabDataPhase = [tabDataPhase; a_dataCTDRawDate(:, 3)];
      tabDataType = [tabDataType; ones(size(a_dataCTDRawDate, 1), 1)*2];
      tabDataDate = [tabDataDate; a_dataCTDRawDate(:, idC)];
      tabDataDateTrans = [tabDataDateTrans; a_dataCTDRawDateTrans(:, idC)];
      tabDataPres = [tabDataPres; a_dataCTDRawPres(:, idC)];
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

if (~isempty(a_dataOXYRawDate))
   for idC = 4:size(a_dataOXYRawDate, 2)
      tabDataCycle = [tabDataCycle; a_dataOXYRawDate(:, 1)];
      tabDataProf = [tabDataProf; a_dataOXYRawDate(:, 2)];
      tabDataPhase = [tabDataPhase; a_dataOXYRawDate(:, 3)];
      tabDataType = [tabDataType; ones(size(a_dataOXYRawDate, 1), 1)*5];
      tabDataDate = [tabDataDate; a_dataOXYRawDate(:, idC)];
      tabDataDateTrans = [tabDataDateTrans; a_dataOXYRawDateTrans(:, idC)];
      tabDataPres = [tabDataPres; a_dataOXYRawPres(:, idC)];
   end
end

if (~isempty(a_dataOCRMeanDate))
   for idC = 4:size(a_dataOCRMeanDate, 2)
      tabDataCycle = [tabDataCycle; a_dataOCRMeanDate(:, 1)];
      tabDataProf = [tabDataProf; a_dataOCRMeanDate(:, 2)];
      tabDataPhase = [tabDataPhase; a_dataOCRMeanDate(:, 3)];
      tabDataType = [tabDataType; ones(size(a_dataOCRMeanDate, 1), 1)*12];
      tabDataDate = [tabDataDate; a_dataOCRMeanDate(:, idC)];
      tabDataDateTrans = [tabDataDateTrans; a_dataOCRMeanDateTrans(:, idC)];
      tabDataPres = [tabDataPres; a_dataOCRMeanPres(:, idC)];
   end
end

if (~isempty(a_dataOCRRawDate))
   for idC = 4:size(a_dataOCRRawDate, 2)
      tabDataCycle = [tabDataCycle; a_dataOCRRawDate(:, 1)];
      tabDataProf = [tabDataProf; a_dataOCRRawDate(:, 2)];
      tabDataPhase = [tabDataPhase; a_dataOCRRawDate(:, 3)];
      tabDataType = [tabDataType; ones(size(a_dataOCRRawDate, 1), 1)*14];
      tabDataDate = [tabDataDate; a_dataOCRRawDate(:, idC)];
      tabDataDateTrans = [tabDataDateTrans; a_dataOCRRawDateTrans(:, idC)];
      tabDataPres = [tabDataPres; a_dataOCRRawPres(:, idC)];
   end
end

if (~isempty(a_dataECO2MeanDate))
   for idC = 4:size(a_dataECO2MeanDate, 2)
      tabDataCycle = [tabDataCycle; a_dataECO2MeanDate(:, 1)];
      tabDataProf = [tabDataProf; a_dataECO2MeanDate(:, 2)];
      tabDataPhase = [tabDataPhase; a_dataECO2MeanDate(:, 3)];
      tabDataType = [tabDataType; ones(size(a_dataECO2MeanDate, 1), 1)*6];
      tabDataDate = [tabDataDate; a_dataECO2MeanDate(:, idC)];
      tabDataDateTrans = [tabDataDateTrans; a_dataECO2MeanDateTrans(:, idC)];
      tabDataPres = [tabDataPres; a_dataECO2MeanPres(:, idC)];
   end
end

if (~isempty(a_dataECO2RawDate))
   for idC = 4:size(a_dataECO2RawDate, 2)
      tabDataCycle = [tabDataCycle; a_dataECO2RawDate(:, 1)];
      tabDataProf = [tabDataProf; a_dataECO2RawDate(:, 2)];
      tabDataPhase = [tabDataPhase; a_dataECO2RawDate(:, 3)];
      tabDataType = [tabDataType; ones(size(a_dataECO2RawDate, 1), 1)*8];
      tabDataDate = [tabDataDate; a_dataECO2RawDate(:, idC)];
      tabDataDateTrans = [tabDataDateTrans; a_dataECO2RawDateTrans(:, idC)];
      tabDataPres = [tabDataPres; a_dataECO2RawPres(:, idC)];
   end
end

if (~isempty(a_dataECO3MeanDate))
   for idC = 4:size(a_dataECO3MeanDate, 2)
      tabDataCycle = [tabDataCycle; a_dataECO3MeanDate(:, 1)];
      tabDataProf = [tabDataProf; a_dataECO3MeanDate(:, 2)];
      tabDataPhase = [tabDataPhase; a_dataECO3MeanDate(:, 3)];
      tabDataType = [tabDataType; ones(size(a_dataECO3MeanDate, 1), 1)*9];
      tabDataDate = [tabDataDate; a_dataECO3MeanDate(:, idC)];
      tabDataDateTrans = [tabDataDateTrans; a_dataECO3MeanDateTrans(:, idC)];
      tabDataPres = [tabDataPres; a_dataECO3MeanPres(:, idC)];
   end
end

if (~isempty(a_dataECO3RawDate))
   for idC = 4:size(a_dataECO3RawDate, 2)
      tabDataCycle = [tabDataCycle; a_dataECO3RawDate(:, 1)];
      tabDataProf = [tabDataProf; a_dataECO3RawDate(:, 2)];
      tabDataPhase = [tabDataPhase; a_dataECO3RawDate(:, 3)];
      tabDataType = [tabDataType; ones(size(a_dataECO3RawDate, 1), 1)*11];
      tabDataDate = [tabDataDate; a_dataECO3RawDate(:, idC)];
      tabDataDateTrans = [tabDataDateTrans; a_dataECO3RawDateTrans(:, idC)];
      tabDataPres = [tabDataPres; a_dataECO3RawPres(:, idC)];
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

if (~isempty(a_dataFLNTURawDate))
   for idC = 4:size(a_dataFLNTURawDate, 2)
      tabDataCycle = [tabDataCycle; a_dataFLNTURawDate(:, 1)];
      tabDataProf = [tabDataProf; a_dataFLNTURawDate(:, 2)];
      tabDataPhase = [tabDataPhase; a_dataFLNTURawDate(:, 3)];
      tabDataType = [tabDataType; ones(size(a_dataFLNTURawDate, 1), 1)*17];
      tabDataDate = [tabDataDate; a_dataFLNTURawDate(:, idC)];
      tabDataDateTrans = [tabDataDateTrans; a_dataFLNTURawDateTrans(:, idC)];
      tabDataPres = [tabDataPres; a_dataFLNTURawPres(:, idC)];
   end
end

if (~isempty(a_dataCROVERMeanDate))
   for idC = 4:size(a_dataFLNTURawDate, 2)
      tabDataCycle = [tabDataCycle; a_dataCROVERMeanDate(:, 1)];
      tabDataProf = [tabDataProf; a_dataCROVERMeanDate(:, 2)];
      tabDataPhase = [tabDataPhase; a_dataCROVERMeanDate(:, 3)];
      tabDataType = [tabDataType; ones(size(a_dataCROVERMeanDate, 1), 1)*18];
      tabDataDate = [tabDataDate; a_dataCROVERMeanDate(:, idC)];
      tabDataDateTrans = [tabDataDateTrans; a_dataCROVERMeanDateTrans(:, idC)];
      tabDataPres = [tabDataPres; a_dataCROVERMeanPres(:, idC)];
   end
end

if (~isempty(a_dataCROVERRawDate))
   for idC = 4:size(a_dataCROVERRawDate, 2)
      tabDataCycle = [tabDataCycle; a_dataCROVERRawDate(:, 1)];
      tabDataProf = [tabDataProf; a_dataCROVERRawDate(:, 2)];
      tabDataPhase = [tabDataPhase; a_dataCROVERRawDate(:, 3)];
      tabDataType = [tabDataType; ones(size(a_dataCROVERRawDate, 1), 1)*20];
      tabDataDate = [tabDataDate; a_dataCROVERRawDate(:, idC)];
      tabDataDateTrans = [tabDataDateTrans; a_dataCROVERRawDateTrans(:, idC)];
      tabDataPres = [tabDataPres; a_dataCROVERRawPres(:, idC)];
   end
end

if (~isempty(a_dataSUNAMeanDate))
   for idC = 4:size(a_dataCROVERRawDate, 2)
      tabDataCycle = [tabDataCycle; a_dataSUNAMeanDate(:, 1)];
      tabDataProf = [tabDataProf; a_dataSUNAMeanDate(:, 2)];
      tabDataPhase = [tabDataPhase; a_dataSUNAMeanDate(:, 3)];
      tabDataType = [tabDataType; ones(size(a_dataSUNAMeanDate, 1), 1)*21];
      tabDataDate = [tabDataDate; a_dataSUNAMeanDate(:, idC)];
      tabDataDateTrans = [tabDataDateTrans; a_dataSUNAMeanDateTrans(:, idC)];
      tabDataPres = [tabDataPres; a_dataSUNAMeanPres(:, idC)];
   end
end

if (~isempty(a_dataSUNARawDate))
   for idC = 4:size(a_dataSUNARawDate, 2)
      tabDataCycle = [tabDataCycle; a_dataSUNARawDate(:, 1)];
      tabDataProf = [tabDataProf; a_dataSUNARawDate(:, 2)];
      tabDataPhase = [tabDataPhase; a_dataSUNARawDate(:, 3)];
      tabDataType = [tabDataType; ones(size(a_dataSUNARawDate, 1), 1)*23];
      tabDataDate = [tabDataDate; a_dataSUNARawDate(:, idC)];
      tabDataDateTrans = [tabDataDateTrans; a_dataSUNARawDateTrans(:, idC)];
      tabDataPres = [tabDataPres; a_dataSUNARawPres(:, idC)];
   end
end

tabDataPres = sensor_2_value_for_pressure_ir_rudics_sbd2(tabDataPres, a_decoderId);

if (~isempty(a_dataSUNAAPFDate))
   for idC = 4:size(a_dataSUNAAPFDate, 2)
      tabDataCycle = [tabDataCycle; a_dataSUNAAPFDate(:, 1)];
      tabDataProf = [tabDataProf; a_dataSUNAAPFDate(:, 2)];
      tabDataPhase = [tabDataPhase; a_dataSUNAAPFDate(:, 3)];
      tabDataType = [tabDataType; ones(size(a_dataSUNAAPFDate, 1), 1)*24];
      tabDataDate = [tabDataDate; a_dataSUNAAPFDate(:, idC)];
      tabDataDateTrans = [tabDataDateTrans; a_dataSUNAAPFDateTrans(:, idC)];
      tabDataPres = [tabDataPres; a_dataSUNAAPFCTDPres(:, idC)]; % APF frame pressure data provided in dbar
   end
end

if (~isempty(a_dataSUNAAPF2))
   if (~isempty(a_dataSUNAAPF2Date))
      for idC = 4:size(a_dataSUNAAPF2Date, 2)
         tabDataCycle = [tabDataCycle; a_dataSUNAAPF2Date(:, 1)];
         tabDataProf = [tabDataProf; a_dataSUNAAPF2Date(:, 2)];
         tabDataPhase = [tabDataPhase; a_dataSUNAAPF2Date(:, 3)];
         tabDataType = [tabDataType; ones(size(a_dataSUNAAPF2Date, 1), 1)*25];
         tabDataDate = [tabDataDate; a_dataSUNAAPF2Date(:, idC)];
         tabDataDateTrans = [tabDataDateTrans; a_dataSUNAAPF2DateTrans(:, idC)];
         tabDataPres = [tabDataPres; a_dataSUNAAPF2CTDPres(:, idC)]; % APF frame pressure data provided in dbar
      end
   end
end

cycleProfList = unique(a_cycleStartDate(:, 1:2), 'rows');
for idCyPr = 1:size(cycleProfList, 1)
   cycleNum = cycleProfList(idCyPr, 1);
   profNum = cycleProfList(idCyPr, 2);
   
   % pre_mission dates
   idGPSToUse = find( ...
      (a_gpsLocCycleNum == cycleNum) & ...
      (a_gpsLocProfNum == profNum) & ...
      (a_gpsLocPhase == g_decArgo_phasePreMission));
   for id = 1:length(idGPSToUse)
      idLoc = idGPSToUse(id);
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; GPS #%d (%s); %s; %.4f; %.4f\n', ...
         g_decArgo_floatNum, cycleNum, profNum, get_phase_name(0), ...
         id, get_phase_name(a_gpsLocPhase(idLoc)), ...
         julian_2_gregorian_dec_argo(a_gpsLocDate(idLoc)), ...
         a_gpsLocLon(idLoc), a_gpsLocLat(idLoc));
   end
   
   % surf wait dates
   idTechToUse = find( ...
      (a_cycleStartDate(:, 1) == cycleNum) & ...
      (a_cycleStartDate(:, 2) == profNum) & ...
      (a_cycleStartDate(:, 3) == g_decArgo_phaseSurfWait));
   if (~isempty(idTechToUse))
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; CYCLE START DATE; %s\n', ...
         g_decArgo_floatNum, cycleNum, profNum, get_phase_name(1), ...
         julian_2_gregorian_dec_argo(a_cycleStartDate(idTechToUse, 5)));
      
      idGPSToUse = find( ...
         (a_gpsLocCycleNum == cycleNum) & ...
         (a_gpsLocProfNum == profNum) & ...
         (a_gpsLocPhase == g_decArgo_phaseSurfWait));
      for id = 1:length(idGPSToUse)
         idLoc = idGPSToUse(id);
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; GPS #%d (%s); %s; %.4f; %.4f\n', ...
            g_decArgo_floatNum, cycleNum, profNum, get_phase_name(1), ...
            id, get_phase_name(a_gpsLocPhase(idLoc)), ...
            julian_2_gregorian_dec_argo(a_gpsLocDate(idLoc)), ...
            a_gpsLocLon(idLoc), a_gpsLocLat(idLoc));
      end
   end
   
   % subsurface dates
   idTechToUse = find( ...
      (a_cycleStartDate(:, 1) == cycleNum) & ...
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
      
      buoyancyInvStartDate = a_buoyancyInvStartDate(idTechToUse, 5);
      firstGroundDate = a_firstGroundDate(idTechToUse, 5);
      firstGroundPres = a_firstGroundPres(idTechToUse, 5);
      firstHangDate = a_firstHangDate(idTechToUse, 5);
      firstHangPres = a_firstHangPres(idTechToUse, 5);
      firstEmerAscentDate = a_firstEmerAscentDate(idTechToUse, 5);
      firstEmergencyAscentPres = a_firstEmergencyAscentPres(idTechToUse, 5);
      
      if (buoyancyInvStartDate ~= g_decArgo_dateDef)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; BUOYANCY INVERSION START DATE; %s\n', ...
            g_decArgo_floatNum, cycleNum, profNum, get_phase_name(2), ...
            julian_2_gregorian_dec_argo(buoyancyInvStartDate));
      end
      if (firstGroundDate ~= g_decArgo_dateDef)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; FIRST GROUNDING DATE; %s; %d; dbar\n', ...
            g_decArgo_floatNum, cycleNum, profNum, get_phase_name(5), ...
            julian_2_gregorian_dec_argo(firstGroundDate), ...
            firstGroundPres);
      end
      if (firstHangDate ~= g_decArgo_dateDef)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; FIRST HANGING DATE; %s; %d; dbar\n', ...
            g_decArgo_floatNum, cycleNum, profNum, get_phase_name(5), ...
            julian_2_gregorian_dec_argo(firstHangDate), ...
            firstHangPres);
      end
      if (firstEmerAscentDate ~= g_decArgo_dateDef)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; FIRST EMERGENCY ASCENT DATE; %s; %d; dbar\n', ...
            g_decArgo_floatNum, cycleNum, profNum, get_phase_name(5), ...
            julian_2_gregorian_dec_argo(firstEmerAscentDate), ...
            firstEmergencyAscentPres);
      end
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; CYCLE START DATE; %s\n', ...
         g_decArgo_floatNum, cycleNum, profNum, get_phase_name(2), ...
         julian_2_gregorian_dec_argo(cycleStartDate));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; BUOYANCY REDUCTION START DATE; %s\n', ...
         g_decArgo_floatNum, cycleNum, profNum, get_phase_name(4), ...
         julian_2_gregorian_dec_argo(buoyancyRedStartDate));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; DESCENT TO PARK START DATE; %s\n', ...
         g_decArgo_floatNum, cycleNum, profNum, get_phase_name(5), ...
         julian_2_gregorian_dec_argo(descentToParkStartDate));
      
      descVertSpeed = g_decArgo_vertSpeed;
      if ((firstStabDate ~= g_decArgo_dateDef) && (firstStabDate ~= descentToParkStartDate))
         descVertSpeed = (firstStabPres*100)/ ...
            ((firstStabDate-descentToParkStartDate)*86400);
      end
      if (descVertSpeed ~= g_decArgo_vertSpeed)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; FIRST STABILIZATION DATE; %s; %d; dbar; =>; %.1f; cm/s\n', ...
            g_decArgo_floatNum, cycleNum, profNum, get_phase_name(5), ...
            julian_2_gregorian_dec_argo(firstStabDate), ...
            firstStabPres, descVertSpeed);
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; FIRST STABILIZATION DATE; %s; %d; dbar\n', ...
            g_decArgo_floatNum, cycleNum, profNum, get_phase_name(5), ...
            julian_2_gregorian_dec_argo(firstStabDate), ...
            firstStabPres);
      end
      
      % descent to park phase
      idDataUsed = find((tabDataCycle == cycleNum) & ...
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
               vertSpeed = ((tabDescDataPres(idMes)-tabDescDataPres(idMes-1))*100)/ ...
                  ((tabDescDataDate(idMes)-tabDescDataDate(idMes-1))*86400);
               
               fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; dated meas (%s); %s; %.1f; dbar; =>; %.1f; cm/s\n', ...
                  g_decArgo_floatNum, cycleNum, profNum, get_phase_name(5), ...
                  get_data_type_name(tabDescDataType(idMes)), ...
                  julian_2_gregorian_dec_argo(tabDescDataDate(idMes)), ...
                  tabDescDataPres(idMes), vertSpeed);
            else
               fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; dated meas (%s); %s; %.1f; dbar\n', ...
                  g_decArgo_floatNum, cycleNum, profNum, get_phase_name(5), ...
                  get_data_type_name(tabDescDataType(idMes)), ...
                  julian_2_gregorian_dec_argo(tabDescDataDate(idMes)), ...
                  tabDescDataPres(idMes));
            end
         end
         
         if ((length(tabDescDataDate) > 1) && (tabDescDataDate(end) - tabDescDataDate(1) ~= 0))
            meanDescVertSpeed = ((tabDescDataPres(end)-tabDescDataPres(1))*100)/ ...
               ((tabDescDataDate(end)-tabDescDataDate(1))*86400);
         end
      end
      
      if (meanDescVertSpeed == g_decArgo_vertSpeed)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; DESCENT TO PARK END DATE; %s\n', ...
            g_decArgo_floatNum, cycleNum, profNum, get_phase_name(6), ...
            julian_2_gregorian_dec_argo(descentToParkEndDate));
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; DESCENT TO PARK END DATE; %s; ; ; =>; %.1f; cm/s; (mean for descent)\n', ...
            g_decArgo_floatNum, cycleNum, profNum, get_phase_name(6), ...
            julian_2_gregorian_dec_argo(descentToParkEndDate), ...
            meanDescVertSpeed);
      end
      
      % drift at park phase
      idDataUsed = find((tabDataCycle == cycleNum) & ...
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
               g_decArgo_floatNum, cycleNum, profNum, get_phase_name(6), ...
               get_data_type_name(tabDescDataType(id)), ...
               julian_2_gregorian_dec_argo(tabDescDataDate(id)), ...
               tabDescDataPres(id));
         end
      end
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; DESCENT TO PROF START DATE; %s\n', ...
         g_decArgo_floatNum, cycleNum, profNum, get_phase_name(7), ...
         julian_2_gregorian_dec_argo(descentToProfStartDate));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; DESCENT TO PROF END DATE; %s\n', ...
         g_decArgo_floatNum, cycleNum, profNum, get_phase_name(8), ...
         julian_2_gregorian_dec_argo(descentToProfEndDate));
      
      % ascent phase
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; ASCENT START DATE; %s\n', ...
         g_decArgo_floatNum, cycleNum, profNum, get_phase_name(9), ...
         julian_2_gregorian_dec_argo(ascentStartDate));
      
      idDataUsed = find((tabDataCycle == cycleNum) & ...
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
               vertSpeed = ((-tabAscDataPres(idMes)+tabAscDataPres(idMes-1))*100)/ ...
                  ((tabAscDataDate(idMes)-tabAscDataDate(idMes-1))*86400);
               
               fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; dated meas (%s); %s; %.1f; dbar; =>; %.1f; cm/s\n', ...
                  g_decArgo_floatNum, cycleNum, profNum, get_phase_name(9), ...
                  get_data_type_name(tabAscDataType(idMes)), ...
                  julian_2_gregorian_dec_argo(tabAscDataDate(idMes)), ...
                  tabAscDataPres(idMes), vertSpeed);
            else
               fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; dated meas (%s); %s; %.1f; dbar\n', ...
                  g_decArgo_floatNum, cycleNum, profNum, get_phase_name(9), ...
                  get_data_type_name(tabAscDataType(idMes)), ...
                  julian_2_gregorian_dec_argo(tabAscDataDate(idMes)), ...
                  tabAscDataPres(idMes));
            end
         end
         
         if ((length(tabAscDataDate) > 1) && (tabAscDataDate(end) - tabAscDataDate(1) ~= 0))
            meanAscVertSpeed = ((-tabAscDataPres(end)+tabAscDataPres(1))*100)/ ...
               ((tabAscDataDate(end)-tabAscDataDate(1))*86400);
         end
      end
      
      if (meanAscVertSpeed ~= g_decArgo_vertSpeed)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; ASCENT END DATE; %s; ; ; =>; %.1f; cm/s; (mean for ascent)\n', ...
            g_decArgo_floatNum, cycleNum, profNum, get_phase_name(10), ...
            julian_2_gregorian_dec_argo(ascentEndDate), ...
            meanAscVertSpeed);
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; ASCENT END DATE; %s\n', ...
            g_decArgo_floatNum, cycleNum, profNum, get_phase_name(10), ...
            julian_2_gregorian_dec_argo(ascentEndDate));
      end
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; TRANSMISSION START DATE; %s\n', ...
         g_decArgo_floatNum, cycleNum, profNum, get_phase_name(12), ...
         julian_2_gregorian_dec_argo(transStartDate));
   end
   
   % transmission phase
   idGPSToUse = find( ...
      (a_gpsLocCycleNum == cycleNum) & ...
      (a_gpsLocProfNum == profNum) & ...
      (a_gpsLocPhase == g_decArgo_phaseSatTrans));
   for id = 1:length(idGPSToUse)
      idLoc = idGPSToUse(id);
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; GPS #%d (%s); %s; %.4f; %.4f\n', ...
         g_decArgo_floatNum, cycleNum, profNum, get_phase_name(12), ...
         id, get_phase_name(a_gpsLocPhase(idLoc)), ...
         julian_2_gregorian_dec_argo(a_gpsLocDate(idLoc)), ...
         a_gpsLocLon(idLoc), a_gpsLocLat(idLoc));
   end
   
   % EOL phase
   idGPSToUse = find( ...
      (a_gpsLocCycleNum == cycleNum) & ...
      (a_gpsLocProfNum == profNum) & ...
      (a_gpsLocPhase == g_decArgo_phaseEndOfLife));
   for id = 1:length(idGPSToUse)
      idLoc = idGPSToUse(id);
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; GPS #%d (%s); %s; %.4f; %.4f\n', ...
         g_decArgo_floatNum, cycleNum, profNum, get_phase_name(14), ...
         id, get_phase_name(a_gpsLocPhase(idLoc)), ...
         julian_2_gregorian_dec_argo(a_gpsLocDate(idLoc)), ...
         a_gpsLocLon(idLoc), a_gpsLocLat(idLoc));
   end
   
   % emergency phase
   idGPSToUse = find( ...
      (a_gpsLocCycleNum == cycleNum) & ...
      (a_gpsLocProfNum == profNum) & ...
      (a_gpsLocPhase == g_decArgo_phaseEmergencyAsc));
   for id = 1:length(idGPSToUse)
      idLoc = idGPSToUse(id);
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; dates; GPS #%d (%s); %s; %.4f; %.4f\n', ...
         g_decArgo_floatNum, cycleNum, profNum, get_phase_name(15), ...
         id, get_phase_name(a_gpsLocPhase(idLoc)), ...
         julian_2_gregorian_dec_argo(a_gpsLocDate(idLoc)), ...
         a_gpsLocLon(idLoc), a_gpsLocLat(idLoc));
   end
end

return
