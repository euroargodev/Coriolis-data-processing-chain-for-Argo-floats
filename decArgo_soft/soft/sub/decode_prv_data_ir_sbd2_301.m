% ------------------------------------------------------------------------------
% Decode PROVOR packet data.
%
% SYNTAX :
%  [o_cyProfPhaseList, ...
%    o_dataCTD, o_dataOXY, o_dataFLBB, ...
%    o_sensorTechCTD, o_sensorTechOPTODE, o_sensorTechFLBB, ...
%    o_sensorParam, ...
%    o_floatPres, ...
%    o_tabTech, o_floatProgTech, o_floatProgParam] = ...
%    decode_prv_data_ir_sbd2_301(a_tabSensors, a_tabDates, a_procLevel)
%
% INPUT PARAMETERS :
%   a_tabSensors : data frame to decode
%   a_tabDates   : corresponding dates of Iridium messages
%   a_procLevel  : processing level (0: collect only rough information, 1:
%                  process data and technical information, 2: process
%                  configuration information)
%
% OUTPUT PARAMETERS :
%   o_cyProfPhaseList  : information (cycle #, prof #, phase #) on each
%                        received packet
%   o_dataCTD          : decoded CTD data
%   o_dataOXY          : decoded OXY data
%   o_dataFLBB         : decoded FLBB data
%   o_sensorTechCTD    : decoded CTD technical data
%   o_sensorTechOPTODE : decoded OXY technical data
%   o_sensorTechFLBB   : decoded FLBB technical data
%   o_sensorParam      : decoded modified sensor data
%   o_floatPres        : decoded float pressure actions
%   o_tabTech          : decoded float technical data
%   o_floatProgTech    : decoded float technical programmed data
%   o_floatProgParam   : decoded float parameter programmed data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cyProfPhaseList, ...
   o_dataCTD, o_dataOXY, o_dataFLBB, ...
   o_sensorTechCTD, o_sensorTechOPTODE, o_sensorTechFLBB, ...
   o_sensorParam, ...
   o_floatPres, ...
   o_tabTech, o_floatProgTech, o_floatProgParam] = ...
   decode_prv_data_ir_sbd2_301(a_tabSensors, a_tabDates, a_procLevel)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_dateDef;
global g_decArgo_janFirst1950InMatlab;

% arrays to store rough information on received data
global g_decArgo_0TypeReceivedData;
global g_decArgo_250TypeReceivedData;
global g_decArgo_251TypeReceivedData;
global g_decArgo_252TypeReceivedData;
global g_decArgo_253TypeReceivedData;
global g_decArgo_254TypeReceivedData;
global g_decArgo_255TypeReceivedData;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% cycle phases
global g_decArgo_phaseSatTrans;
global g_decArgo_phaseParkDrift;

% array to store ko sensor states
global g_decArgo_koSensorState;

% to check timeouted buffer contents
global g_decArgo_needFullBufferInfo;


% output parameters initialization
o_cyProfPhaseList = [];

o_dataCTD = [];
o_dataOXY = [];
o_dataFLBB = [];

o_sensorTechCTD = [];
o_sensorTechOPTODE = [];
o_sensorTechFLBB = [];

o_sensorParam = [];

o_floatPres = [];

o_tabTech = [];

o_floatProgTech = [];

o_floatProgParam = [];

% output packet parameters initialization
o_dataCTDMeanDate = [];
o_dataCTDMeanDateTrans = [];
o_dataCTDMeanPres = [];
o_dataCTDMeanTemp = [];
o_dataCTDMeanSal = [];

o_dataCTDStdMedDate = [];
o_dataCTDStdMedDateTrans = [];
o_dataCTDStdMedPresMean  = [];
o_dataCTDStdMedTempStd  = [];
o_dataCTDStdMedSalStd  = [];
o_dataCTDStdMedPresMed  = [];
o_dataCTDStdMedTempMed  = [];
o_dataCTDStdMedSalMed  = [];

o_dataOXYMeanDate = [];
o_dataOXYMeanDateTrans = [];
o_dataOXYMeanPres = [];
o_dataOXYMeanC1Phase = [];
o_dataOXYMeanC2Phase = [];
o_dataOXYMeanTemp = [];

o_dataOXYStdMedDate = [];
o_dataOXYStdMedDateTrans = [];
o_dataOXYStdMedPresMean = [];
o_dataOXYStdMedC1PhaseStd = [];
o_dataOXYStdMedC2PhaseStd = [];
o_dataOXYStdMedTempStd = [];
o_dataOXYStdMedC1PhaseMed = [];
o_dataOXYStdMedC2PhaseMed = [];
o_dataOXYStdMedTempMed = [];

o_dataFLBBMeanDate = [];
o_dataFLBBMeanDateTrans = [];
o_dataFLBBMeanPres = [];
o_dataFLBBMeanChloroA = [];
o_dataFLBBMeanBackscat = [];

o_dataFLBBStdMedDate = [];
o_dataFLBBStdMedDateTrans = [];
o_dataFLBBStdMedPresMean = [];
o_dataFLBBStdMedChloroAStd = [];
o_dataFLBBStdMedBackscatStd = [];
o_dataFLBBStdMedChloroAMed = [];
o_dataFLBBStdMedBackscatMed = [];

o_sensorTechCTDNbPackDesc = [];
o_sensorTechCTDNbPackDrift = [];
o_sensorTechCTDNbPackAsc = [];
o_sensorTechCTDNbMeasDescZ1 = [];
o_sensorTechCTDNbMeasDescZ2 = [];
o_sensorTechCTDNbMeasDescZ3 = [];
o_sensorTechCTDNbMeasDescZ4 = [];
o_sensorTechCTDNbMeasDescZ5 = [];
o_sensorTechCTDNbMeasDrift = [];
o_sensorTechCTDNbMeasAscZ1 = [];
o_sensorTechCTDNbMeasAscZ2 = [];
o_sensorTechCTDNbMeasAscZ3 = [];
o_sensorTechCTDNbMeasAscZ4 = [];
o_sensorTechCTDNbMeasAscZ5 = [];
o_sensorTechCTDSensorState = [];
o_sensorTechCTDOffsetPres = [];
o_sensorTechCTDSubPres = [];
o_sensorTechCTDSubTemp = [];
o_sensorTechCTDSubSal = [];

o_sensorTechOPTODENbPackDesc = [];
o_sensorTechOPTODENbPackDrift = [];
o_sensorTechOPTODENbPackAsc = [];
o_sensorTechOPTODENbMeasDescZ1 = [];
o_sensorTechOPTODENbMeasDescZ2 = [];
o_sensorTechOPTODENbMeasDescZ3 = [];
o_sensorTechOPTODENbMeasDescZ4 = [];
o_sensorTechOPTODENbMeasDescZ5 = [];
o_sensorTechOPTODENbMeasDrift = [];
o_sensorTechOPTODENbMeasAscZ1 = [];
o_sensorTechOPTODENbMeasAscZ2 = [];
o_sensorTechOPTODENbMeasAscZ3 = [];
o_sensorTechOPTODENbMeasAscZ4 = [];
o_sensorTechOPTODENbMeasAscZ5 = [];
o_sensorTechOPTODESensorState = [];

o_sensorTechFLBBNbPackDesc = [];
o_sensorTechFLBBNbPackDrift = [];
o_sensorTechFLBBNbPackAsc = [];
o_sensorTechFLBBNbMeasDescZ1 = [];
o_sensorTechFLBBNbMeasDescZ2 = [];
o_sensorTechFLBBNbMeasDescZ3 = [];
o_sensorTechFLBBNbMeasDescZ4 = [];
o_sensorTechFLBBNbMeasDescZ5 = [];
o_sensorTechFLBBNbMeasDrift = [];
o_sensorTechFLBBNbMeasAscZ1 = [];
o_sensorTechFLBBNbMeasAscZ2 = [];
o_sensorTechFLBBNbMeasAscZ3 = [];
o_sensorTechFLBBNbMeasAscZ4 = [];
o_sensorTechFLBBNbMeasAscZ5 = [];
o_sensorTechFLBBSensorState = [];
o_sensorTechFLBBSensorSerialNum = [];
o_sensorTechFLBBCoefScaleFactChloroA = [];
o_sensorTechFLBBCoefDarkCountChloroA = [];
o_sensorTechFLBBCoefScaleFactBackscat = [];
o_sensorTechFLBBCoefDarkCountBackscat = [];

o_sensorParamModSensorNum = [];
o_sensorParamParamType = [];
o_sensorParamParamNum = [];
o_sensorParamOldVal = [];
o_sensorParamNewVal = [];

o_floatPresPumpOrEv = [];
o_floatPresActPres = [];
o_floatPresTime = [];

% split sensor technical data packets (packet type 250 is 70 bytes length
% whereas input SBD size is 140 bytes)
tabSensors = [];
tabDates = [];
idSensorTechDataPack = find(a_tabSensors(:, 1) == 250);
for id = 1:length(idSensorTechDataPack)
   idPack = idSensorTechDataPack(id);
   
   dataPack = a_tabSensors(idPack, :);
   datePack = a_tabDates(idPack);
   
   tabSensors = [tabSensors; [dataPack(1:70) repmat([0], 1, 70)]];
   tabDates = [tabDates; datePack];
   
   if ~((dataPack(71) == 250) && (length(unique(dataPack(72:75))) == 1) && (dataPack(72) == 255))
      tabSensors = [tabSensors; [dataPack(71:140) repmat([0], 1, 70)]];
      tabDates = [tabDates; datePack];
   end
end
idOther = setdiff([1:size(a_tabSensors, 1)], idSensorTechDataPack);
tabSensors = [tabSensors; a_tabSensors(idOther, :)];
tabDates = [tabDates; a_tabDates(idOther, :)];

% sort data by date
[tabDates, idSort] = sort(tabDates);
tabSensors = tabSensors(idSort, :);

% decode packet data
for idMes = 1:size(tabSensors, 1)
   % packet type
   packType = tabSensors(idMes, 1);
   
   % date of the SBD file
   sbdFileDate = tabDates(idMes);
   
   switch (packType)
      
      case 0
         % sensor data
         
         if (a_procLevel == 2)
            continue
         end
         
         % sensor data type
         sensorDataType = tabSensors(idMes, 2);
         
         % message data frame
         msgData = tabSensors(idMes, 3:end);
         
         % empty msg
         uMsgdata = unique(msgData);
         if ((length(uMsgdata) == 1) && (uMsgdata == 0))
            continue
         end
         
         switch (sensorDataType)
            
            case {0}
               % CTD (mean)
               
               % first item bit number
               firstBit = 1;
               % item bit lengths
               tabNbBits = [16 8 8 32 repmat([16 16 16], 1, 21) 32];
               % get item bits
               values = get_bits(firstBit, tabNbBits, msgData);
               
               % decode and store data values
               cycleNum = values(1);
               profNum = values(2);
               phaseNum = values(3);
               g_decArgo_cycleNum = cycleNum;
               
               if (profNum > 9)
                  fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent profile number (#%d) - ignoring packet data\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, ...
                     profNum);
                  continue
               end
               
               if (a_procLevel == 0)
                  g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                     sensorDataType cycleNum profNum phaseNum];
                  continue
               end
               
               measDate = ones(1, 21)*g_decArgo_dateDef;
               measDate(1) = epoch2000_2_julian(values(4));
               measDateTrans = zeros(1, 21);
               
               measPres = [];
               measTemp = [];
               measSal = [];
               for idBin = 1:21
                  measPres = [measPres values(3*(idBin-1)+5)];
                  measTemp = [measTemp values(3*(idBin-1)+6)];
                  measSal = [measSal values(3*(idBin-1)+7)];
               end
               measDateTrans(1) = 1;
               measDateTrans(find((measPres == 0) & (measTemp == 0) & (measSal == 0))) = -1;
               
               o_dataCTDMeanDate = [o_dataCTDMeanDate; [cycleNum profNum phaseNum measDate]];
               o_dataCTDMeanDateTrans = [o_dataCTDMeanDateTrans; [cycleNum profNum phaseNum measDateTrans]];
               o_dataCTDMeanPres = [o_dataCTDMeanPres; [cycleNum profNum phaseNum measPres]];
               o_dataCTDMeanTemp = [o_dataCTDMeanTemp; [cycleNum profNum phaseNum measTemp]];
               o_dataCTDMeanSal = [o_dataCTDMeanSal; [cycleNum profNum phaseNum measSal]];
               
               o_cyProfPhaseList = [o_cyProfPhaseList; ...
                  packType sensorDataType cycleNum profNum phaseNum sbdFileDate];
               
            case {1}
               % CTD (stDev & median)
               
               % first item bit number
               firstBit = 1;
               % item bit lengths
               tabNbBits = [16 8 8 32 repmat([16 8 8 16 16 16], 1, 13)];
               % get item bits
               values = get_bits(firstBit, tabNbBits, msgData);
               
               % decode and store data values
               cycleNum = values(1);
               profNum = values(2);
               phaseNum = values(3);
               g_decArgo_cycleNum = cycleNum;
               
               if (profNum > 9)
                  fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent profile number (#%d) - ignoring packet data\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, ...
                     profNum);
                  continue
               end
               
               if (a_procLevel == 0)
                  g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                     sensorDataType cycleNum profNum phaseNum];
                  continue
               end
               
               measDate = ones(1, 13)*g_decArgo_dateDef;
               measDate(1) = epoch2000_2_julian(values(4));
               measDateTrans = zeros(1, 13);
               
               measPresMean = [];
               measTempStd = [];
               measSalStd = [];
               measPresMed = [];
               measTempMed = [];
               measSalMed = [];
               for idBin = 1:13
                  measPresMean = [measPresMean values(6*(idBin-1)+5)];
                  measTempStd = [measTempStd values(6*(idBin-1)+6)];
                  measSalStd = [measSalStd values(6*(idBin-1)+7)];
                  measPresMed = [measPresMed values(6*(idBin-1)+8)];
                  measTempMed = [measTempMed values(6*(idBin-1)+9)];
                  measSalMed = [measSalMed values(6*(idBin-1)+10)];
               end
               measDateTrans(1) = 1;
               measDateTrans(find((measPresMean == 0) & (measTempStd == 0) & (measSalStd == 0) & ...
                  (measPresMed == 0) & (measTempMed == 0) & (measSalMed == 0))) = -1;
               
               o_dataCTDStdMedDate = [o_dataCTDStdMedDate; [cycleNum profNum phaseNum measDate]];
               o_dataCTDStdMedDateTrans = [o_dataCTDStdMedDate; [cycleNum profNum phaseNum measDateTrans]];
               o_dataCTDStdMedPresMean  = [o_dataCTDStdMedPresMean; [cycleNum profNum phaseNum measPresMean]];
               o_dataCTDStdMedTempStd  = [o_dataCTDStdMedTempStd; [cycleNum profNum phaseNum measTempStd]];
               o_dataCTDStdMedSalStd  = [o_dataCTDStdMedSalStd; [cycleNum profNum phaseNum measSalStd]];
               o_dataCTDStdMedPresMed  = [o_dataCTDStdMedPresMed; [cycleNum profNum phaseNum measPresMed]];
               o_dataCTDStdMedTempMed  = [o_dataCTDStdMedTempMed; [cycleNum profNum phaseNum measTempMed]];
               o_dataCTDStdMedSalMed  = [o_dataCTDStdMedSalMed; [cycleNum profNum phaseNum measSalMed]];
               
               o_cyProfPhaseList = [o_cyProfPhaseList; ...
                  packType sensorDataType cycleNum profNum phaseNum sbdFileDate];
               
            case {3}
               % OXYGEN (mean)
               
               % first item bit number
               firstBit = 1;
               % item bit lengths
               tabNbBits = [16 8 8 32 repmat([16 32 32 16], 1, 10) 80];
               % get item bits
               values = get_bits(firstBit, tabNbBits, msgData);
               
               % decode and store data values
               cycleNum = values(1);
               profNum = values(2);
               phaseNum = values(3);
               g_decArgo_cycleNum = cycleNum;
               
               if (profNum > 9)
                  fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent profile number (#%d) - ignoring packet data\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, ...
                     profNum);
                  continue
               end
               
               if (a_procLevel == 0)
                  g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                     sensorDataType cycleNum profNum phaseNum];
                  continue
               end
               
               measDate = ones(1, 10)*g_decArgo_dateDef;
               measDate(1) = epoch2000_2_julian(values(4));
               measDateTrans = zeros(1, 10);
               
               measPres = [];
               measC1Phase = [];
               measC2Phase = [];
               measTemp = [];
               for idBin = 1:10
                  measPres = [measPres values(4*(idBin-1)+5)];
                  measC1Phase = [measC1Phase twos_complement_dec_argo(values(4*(idBin-1)+6), 32)];
                  measC2Phase = [measC2Phase twos_complement_dec_argo(values(4*(idBin-1)+7), 32)];
                  measTemp = [measTemp values(4*(idBin-1)+8)];
               end
               measDateTrans(1) = 1;
               measDateTrans(find((measPres == 0) & (measC1Phase == 0) & (measC2Phase == 0) & (measTemp == 0))) = -1;
               
               o_dataOXYMeanDate = [o_dataOXYMeanDate; [cycleNum profNum phaseNum measDate]];
               o_dataOXYMeanDateTrans = [o_dataOXYMeanDateTrans; [cycleNum profNum phaseNum measDateTrans]];
               o_dataOXYMeanPres = [o_dataOXYMeanPres; [cycleNum profNum phaseNum measPres]];
               o_dataOXYMeanC1Phase = [o_dataOXYMeanC1Phase; [cycleNum profNum phaseNum measC1Phase]];
               o_dataOXYMeanC2Phase = [o_dataOXYMeanC2Phase; [cycleNum profNum phaseNum measC2Phase]];
               o_dataOXYMeanTemp = [o_dataOXYMeanTemp; [cycleNum profNum phaseNum measTemp]];
               
               o_cyProfPhaseList = [o_cyProfPhaseList; ...
                  packType sensorDataType cycleNum profNum phaseNum sbdFileDate];
               
            case {4}
               % OXYGEN (stDev & median)
               
               % first item bit number
               firstBit = 1;
               % item bit lengths
               tabNbBits = [16 8 8 32 repmat([16 16 16 8 32 32 16], 1, 7) 88];
               % get item bits
               values = get_bits(firstBit, tabNbBits, msgData);
               
               % decode and store data values
               cycleNum = values(1);
               profNum = values(2);
               phaseNum = values(3);
               g_decArgo_cycleNum = cycleNum;
               
               if (profNum > 9)
                  fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent profile number (#%d) - ignoring packet data\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, ...
                     profNum);
                  continue
               end
               
               if (a_procLevel == 0)
                  g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                     sensorDataType cycleNum profNum phaseNum];
                  continue
               end
               
               measDate = ones(1, 7)*g_decArgo_dateDef;
               measDate(1) = epoch2000_2_julian(values(4));
               measDateTrans = zeros(1, 7);
               
               measPresMean = [];
               measC1PhaseStd = [];
               measC2PhaseStd = [];
               measTempStd = [];
               measC1PhaseMed = [];
               measC2PhaseMed = [];
               measTempMed = [];
               for idBin = 1:7
                  measPresMean = [measPresMean values(7*(idBin-1)+5)];
                  measC1PhaseStd = [measC1PhaseStd values(7*(idBin-1)+6)];
                  measC2PhaseStd = [measC2PhaseStd values(7*(idBin-1)+7)];
                  measTempStd = [measTempStd values(7*(idBin-1)+8)];
                  measC1PhaseMed = [measC1PhaseMed twos_complement_dec_argo(values(7*(idBin-1)+9), 32)];
                  measC2PhaseMed = [measC2PhaseMed twos_complement_dec_argo(values(7*(idBin-1)+10), 32)];
                  measTempMed = [measTempMed values(7*(idBin-1)+11)];
               end
               measDateTrans(1) = 1;
               measDateTrans(find((measPresMean == 0) & (measC1PhaseStd == 0) & ...
                  (measC2PhaseStd == 0) & (measTempStd == 0) & ...
                  (measC1PhaseMed == 0) & (measC2PhaseMed == 0) & (measTempMed == 0))) = -1;
               
               o_dataOXYStdMedDate = [o_dataOXYStdMedDate; [cycleNum profNum phaseNum measDate]];
               o_dataOXYStdMedDateTrans = [o_dataOXYStdMedDateTrans; [cycleNum profNum phaseNum measDateTrans]];
               o_dataOXYStdMedPresMean  = [o_dataOXYStdMedPresMean; [cycleNum profNum phaseNum measPresMean]];
               o_dataOXYStdMedC1PhaseStd  = [o_dataOXYStdMedC1PhaseStd; [cycleNum profNum phaseNum measC1PhaseStd]];
               o_dataOXYStdMedC2PhaseStd  = [o_dataOXYStdMedC2PhaseStd; [cycleNum profNum phaseNum measC2PhaseStd]];
               o_dataOXYStdMedTempStd  = [o_dataOXYStdMedTempStd; [cycleNum profNum phaseNum measTempStd]];
               o_dataOXYStdMedC1PhaseMed  = [o_dataOXYStdMedC1PhaseMed; [cycleNum profNum phaseNum measC1PhaseMed]];
               o_dataOXYStdMedC2PhaseMed  = [o_dataOXYStdMedC2PhaseMed; [cycleNum profNum phaseNum measC2PhaseMed]];
               o_dataOXYStdMedTempMed  = [o_dataOXYStdMedTempMed; [cycleNum profNum phaseNum measTempMed]];
               
               o_cyProfPhaseList = [o_cyProfPhaseList; ...
                  packType sensorDataType cycleNum profNum phaseNum sbdFileDate];
               
            case {6}
               % FLBB (mean)
               
               % first item bit number
               firstBit = 1;
               % item bit lengths
               tabNbBits = [16 8 8 32 repmat([16 16 16], 1, 21) 32];
               % get item bits
               values = get_bits(firstBit, tabNbBits, msgData);
               
               % decode and store data values
               cycleNum = values(1);
               profNum = values(2);
               phaseNum = values(3);
               g_decArgo_cycleNum = cycleNum;
               
               if (profNum > 9)
                  fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent profile number (#%d) - ignoring packet data\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, ...
                     profNum);
                  continue
               end
               
               if (a_procLevel == 0)
                  g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                     sensorDataType cycleNum profNum phaseNum];
                  continue
               end
               
               measDate = ones(1, 21)*g_decArgo_dateDef;
               measDate(1) = epoch2000_2_julian(values(4));
               measDateTrans = zeros(1, 21);
               
               measPres = [];
               measChloroA = [];
               measBackscat = [];
               for idBin = 1:21
                  measPres = [measPres values(3*(idBin-1)+5)];
                  measChloroA = [measChloroA values(3*(idBin-1)+6)];
                  measBackscat = [measBackscat values(3*(idBin-1)+7)];
               end
               measDateTrans(1) = 1;
               measDateTrans(find((measPres == 0) & (measChloroA == 0) & (measBackscat == 0))) = -1;
               
               o_dataFLBBMeanDate = [o_dataFLBBMeanDate; [cycleNum profNum phaseNum measDate]];
               o_dataFLBBMeanDateTrans = [o_dataFLBBMeanDateTrans; [cycleNum profNum phaseNum measDateTrans]];
               o_dataFLBBMeanPres = [o_dataFLBBMeanPres; [cycleNum profNum phaseNum measPres]];
               o_dataFLBBMeanChloroA = [o_dataFLBBMeanChloroA; [cycleNum profNum phaseNum measChloroA]];
               o_dataFLBBMeanBackscat = [o_dataFLBBMeanBackscat; [cycleNum profNum phaseNum measBackscat]];
               
               o_cyProfPhaseList = [o_cyProfPhaseList; ...
                  packType sensorDataType cycleNum profNum phaseNum sbdFileDate];
               
            case {7}
               % FLBB (stDev & median)
               
               % first item bit number
               firstBit = 1;
               % item bit lengths
               tabNbBits = [16 8 8 32 repmat([16 8 8 16 16], 1, 16) 16];
               % get item bits
               values = get_bits(firstBit, tabNbBits, msgData);
               
               % decode and store data values
               cycleNum = values(1);
               profNum = values(2);
               phaseNum = values(3);
               g_decArgo_cycleNum = cycleNum;
               
               if (profNum > 9)
                  fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent profile number (#%d) - ignoring packet data\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, ...
                     profNum);
                  continue
               end
               
               if (a_procLevel == 0)
                  g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                     sensorDataType cycleNum profNum phaseNum];
                  continue
               end
               
               measDate = ones(1, 16)*g_decArgo_dateDef;
               measDate(1) = epoch2000_2_julian(values(4));
               measDateTrans = zeros(1, 16);
               
               measPresMean = [];
               measChloroAStd = [];
               measBackscatStd = [];
               measChloroAMed = [];
               measBackscatMed = [];
               for idBin = 1:16
                  measPresMean = [measPresMean values(5*(idBin-1)+5)];
                  measChloroAStd = [measChloroAStd values(5*(idBin-1)+6)];
                  measBackscatStd = [measBackscatStd values(5*(idBin-1)+7)];
                  measChloroAMed = [measChloroAMed values(5*(idBin-1)+8)];
                  measBackscatMed = [measBackscatMed values(5*(idBin-1)+9)];
               end
               measDateTrans(1) = 1;
               measDateTrans(find((measPresMean == 0) & (measChloroAStd == 0) & ...
                  (measBackscatStd == 0) & (measChloroAMed == 0) & (measBackscatMed == 0))) = -1;
               
               o_dataFLBBStdMedDate = [o_dataFLBBStdMedDate; [cycleNum profNum phaseNum measDate]];
               o_dataFLBBStdMedDateTrans = [o_dataFLBBStdMedDateTrans; [cycleNum profNum phaseNum measDateTrans]];
               o_dataFLBBStdMedPresMean  = [o_dataFLBBStdMedPresMean; [cycleNum profNum phaseNum measPresMean]];
               o_dataFLBBStdMedChloroAStd  = [o_dataFLBBStdMedChloroAStd; [cycleNum profNum phaseNum measChloroAStd]];
               o_dataFLBBStdMedBackscatStd  = [o_dataFLBBStdMedBackscatStd; [cycleNum profNum phaseNum measBackscatStd]];
               o_dataFLBBStdMedChloroAMed  = [o_dataFLBBStdMedChloroAMed; [cycleNum profNum phaseNum measChloroAMed]];
               o_dataFLBBStdMedBackscatMed  = [o_dataFLBBStdMedBackscatMed; [cycleNum profNum phaseNum measBackscatMed]];
               
               o_cyProfPhaseList = [o_cyProfPhaseList; ...
                  packType sensorDataType cycleNum profNum phaseNum sbdFileDate];
               
            otherwise
               fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet for sensor data type #%d\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum, ...
                  sensorDataType);
         end
         
      case 250
         % sensor tech data
         
         if (a_procLevel == 2)
            continue
         end
         
         % message data frame
         msgData = tabSensors(idMes, 3:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [16 repmat([8], 1, 16) 400];
         % get item bits
         values = get_bits(firstBit, tabNbBits, msgData);
         
         % decode and store data values
         cycleNum = values(1);
         profNum = values(2);
         nbPackDesc = values(3);
         nbPackDrift = values(4);
         nbPackAsc = values(5);
         nbMeasDescZ1 = values(6);
         nbMeasDescZ2 = values(7);
         nbMeasDescZ3 = values(8);
         nbMeasDescZ4 = values(9);
         nbMeasDescZ5 = values(10);
         nbMeasDrift = values(11);
         nbMeasAscZ1 = values(12);
         nbMeasAscZ2 = values(13);
         nbMeasAscZ3 = values(14);
         nbMeasAscZ4 = values(15);
         nbMeasAscZ5 = values(16);
         sensorState = values(17);
         g_decArgo_cycleNum = cycleNum;
         
         if (profNum > 9)
            fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent profile number (#%d) - ignoring packet data\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, ...
               profNum);
            continue
         end
         
         % sensor type
         sensorType = tabSensors(idMes, 2);
         
         if (a_procLevel == 0)
            g_decArgo_250TypeReceivedData = [g_decArgo_250TypeReceivedData; ...
               sensorType cycleNum profNum nbPackDesc nbPackDrift nbPackAsc];
            continue
         end
         
         % store ko sensor state
         if (sensorState == 0)
            g_decArgo_koSensorState = [g_decArgo_koSensorState; ...
               cycleNum profNum sensorType];
            fprintf('DEC_WARNING: Float #%d Cycle #%d: %d type status sensor is Ko\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, ...
               sensorType);
         end
         
         o_cyProfPhaseList = [o_cyProfPhaseList; ...
            250 sensorType cycleNum profNum -1 sbdFileDate];
         
         % message data frame
         msgData = tabSensors(idMes, 21:end);
         
         switch (sensorType)
            
            case 0
               % CTD
               
               % first item bit number
               firstBit = 1;
               % item bit lengths
               tabNbBits = [repmat([32], 1, 4) 272];
               % get item bits
               values = get_bits(firstBit, tabNbBits, msgData);
               
               % decode and store data values
               measOffsetPres = typecast(uint32(swapbytes(uint32(values(1)))), 'single');
               measSubPres = typecast(uint32(swapbytes(uint32(values(2)))), 'single');
               measTempPres = typecast(uint32(swapbytes(uint32(values(3)))), 'single');
               measSalPres = typecast(uint32(swapbytes(uint32(values(4)))), 'single');
               
               o_sensorTechCTDNbPackDesc = [o_sensorTechCTDNbPackDesc; cycleNum profNum nbPackDesc];
               o_sensorTechCTDNbPackDrift = [o_sensorTechCTDNbPackDrift; cycleNum profNum nbPackDrift];
               o_sensorTechCTDNbPackAsc = [o_sensorTechCTDNbPackAsc; cycleNum profNum nbPackAsc];
               o_sensorTechCTDNbMeasDescZ1 = [o_sensorTechCTDNbMeasDescZ1; cycleNum profNum nbMeasDescZ1];
               o_sensorTechCTDNbMeasDescZ2 = [o_sensorTechCTDNbMeasDescZ2; cycleNum profNum nbMeasDescZ2];
               o_sensorTechCTDNbMeasDescZ3 = [o_sensorTechCTDNbMeasDescZ3; cycleNum profNum nbMeasDescZ3];
               o_sensorTechCTDNbMeasDescZ4 = [o_sensorTechCTDNbMeasDescZ4; cycleNum profNum nbMeasDescZ4];
               o_sensorTechCTDNbMeasDescZ5 = [o_sensorTechCTDNbMeasDescZ5; cycleNum profNum nbMeasDescZ5];
               o_sensorTechCTDNbMeasDrift = [o_sensorTechCTDNbMeasDrift; cycleNum profNum nbMeasDrift];
               o_sensorTechCTDNbMeasAscZ1 = [o_sensorTechCTDNbMeasAscZ1; cycleNum profNum nbMeasAscZ1];
               o_sensorTechCTDNbMeasAscZ2 = [o_sensorTechCTDNbMeasAscZ2; cycleNum profNum nbMeasAscZ2];
               o_sensorTechCTDNbMeasAscZ3 = [o_sensorTechCTDNbMeasAscZ3; cycleNum profNum nbMeasAscZ3];
               o_sensorTechCTDNbMeasAscZ4 = [o_sensorTechCTDNbMeasAscZ4; cycleNum profNum nbMeasAscZ4];
               o_sensorTechCTDNbMeasAscZ5 = [o_sensorTechCTDNbMeasAscZ5; cycleNum profNum nbMeasAscZ5];
               o_sensorTechCTDSensorState = [o_sensorTechCTDSensorState; cycleNum profNum sensorState];
               o_sensorTechCTDOffsetPres = [o_sensorTechCTDOffsetPres; cycleNum profNum measOffsetPres];
               o_sensorTechCTDSubPres = [o_sensorTechCTDSubPres; cycleNum profNum measSubPres];
               o_sensorTechCTDSubTemp = [o_sensorTechCTDSubTemp; cycleNum profNum measTempPres];
               o_sensorTechCTDSubSal = [o_sensorTechCTDSubSal; cycleNum profNum measSalPres];
               
            case 1
               % OPTODE
               
               o_sensorTechOPTODENbPackDesc = [o_sensorTechOPTODENbPackDesc; cycleNum profNum nbPackDesc];
               o_sensorTechOPTODENbPackDrift = [o_sensorTechOPTODENbPackDrift; cycleNum profNum nbPackDrift];
               o_sensorTechOPTODENbPackAsc = [o_sensorTechOPTODENbPackAsc; cycleNum profNum nbPackAsc];
               o_sensorTechOPTODENbMeasDescZ1 = [o_sensorTechOPTODENbMeasDescZ1; cycleNum profNum nbMeasDescZ1];
               o_sensorTechOPTODENbMeasDescZ2 = [o_sensorTechOPTODENbMeasDescZ2; cycleNum profNum nbMeasDescZ2];
               o_sensorTechOPTODENbMeasDescZ3 = [o_sensorTechOPTODENbMeasDescZ3; cycleNum profNum nbMeasDescZ3];
               o_sensorTechOPTODENbMeasDescZ4 = [o_sensorTechOPTODENbMeasDescZ4; cycleNum profNum nbMeasDescZ4];
               o_sensorTechOPTODENbMeasDescZ5 = [o_sensorTechOPTODENbMeasDescZ5; cycleNum profNum nbMeasDescZ5];
               o_sensorTechOPTODENbMeasDrift = [o_sensorTechOPTODENbMeasDrift; cycleNum profNum nbMeasDrift];
               o_sensorTechOPTODENbMeasAscZ1 = [o_sensorTechOPTODENbMeasAscZ1; cycleNum profNum nbMeasAscZ1];
               o_sensorTechOPTODENbMeasAscZ2 = [o_sensorTechOPTODENbMeasAscZ2; cycleNum profNum nbMeasAscZ2];
               o_sensorTechOPTODENbMeasAscZ3 = [o_sensorTechOPTODENbMeasAscZ3; cycleNum profNum nbMeasAscZ3];
               o_sensorTechOPTODENbMeasAscZ4 = [o_sensorTechOPTODENbMeasAscZ4; cycleNum profNum nbMeasAscZ4];
               o_sensorTechOPTODENbMeasAscZ5 = [o_sensorTechOPTODENbMeasAscZ5; cycleNum profNum nbMeasAscZ5];
               o_sensorTechOPTODESensorState = [o_sensorTechOPTODESensorState; cycleNum profNum sensorState];
               
            case 4
               % FLBB
               
               % first item bit number
               firstBit = 1;
               % item bit lengths
               tabNbBits = [16 repmat([32 16], 1, 2) 288];
               % get item bits
               values = get_bits(firstBit, tabNbBits, msgData);
               
               % decode and store data values
               measSensorSerialNum = swapbytes(uint16(values(1)));
               measCoefScaleFactChloroA = typecast(uint32(swapbytes(uint32(values(2)))), 'single');
               measCoefDarkCountChloroA = swapbytes(uint16(values(3)));
               measCoefScaleFactBackscat = typecast(uint32(swapbytes(uint32(values(4)))), 'single');
               measCoefDarkCountBackscat = swapbytes(uint16(values(5)));
               
               o_sensorTechFLBBNbPackDesc = [o_sensorTechFLBBNbPackDesc; cycleNum profNum nbPackDesc];
               o_sensorTechFLBBNbPackDrift = [o_sensorTechFLBBNbPackDrift; cycleNum profNum nbPackDrift];
               o_sensorTechFLBBNbPackAsc = [o_sensorTechFLBBNbPackAsc; cycleNum profNum nbPackAsc];
               o_sensorTechFLBBNbMeasDescZ1 = [o_sensorTechFLBBNbMeasDescZ1; cycleNum profNum nbMeasDescZ1];
               o_sensorTechFLBBNbMeasDescZ2 = [o_sensorTechFLBBNbMeasDescZ2; cycleNum profNum nbMeasDescZ2];
               o_sensorTechFLBBNbMeasDescZ3 = [o_sensorTechFLBBNbMeasDescZ3; cycleNum profNum nbMeasDescZ3];
               o_sensorTechFLBBNbMeasDescZ4 = [o_sensorTechFLBBNbMeasDescZ4; cycleNum profNum nbMeasDescZ4];
               o_sensorTechFLBBNbMeasDescZ5 = [o_sensorTechFLBBNbMeasDescZ5; cycleNum profNum nbMeasDescZ5];
               o_sensorTechFLBBNbMeasDrift = [o_sensorTechFLBBNbMeasDrift; cycleNum profNum nbMeasDrift];
               o_sensorTechFLBBNbMeasAscZ1 = [o_sensorTechFLBBNbMeasAscZ1; cycleNum profNum nbMeasAscZ1];
               o_sensorTechFLBBNbMeasAscZ2 = [o_sensorTechFLBBNbMeasAscZ2; cycleNum profNum nbMeasAscZ2];
               o_sensorTechFLBBNbMeasAscZ3 = [o_sensorTechFLBBNbMeasAscZ3; cycleNum profNum nbMeasAscZ3];
               o_sensorTechFLBBNbMeasAscZ4 = [o_sensorTechFLBBNbMeasAscZ4; cycleNum profNum nbMeasAscZ4];
               o_sensorTechFLBBNbMeasAscZ5 = [o_sensorTechFLBBNbMeasAscZ5; cycleNum profNum nbMeasAscZ5];
               o_sensorTechFLBBSensorState = [o_sensorTechFLBBSensorState; cycleNum profNum sensorState];
               o_sensorTechFLBBSensorSerialNum = [o_sensorTechFLBBSensorSerialNum; cycleNum profNum measSensorSerialNum];
               o_sensorTechFLBBCoefScaleFactChloroA = [o_sensorTechFLBBCoefScaleFactChloroA; cycleNum profNum measCoefScaleFactChloroA];
               o_sensorTechFLBBCoefDarkCountChloroA = [o_sensorTechFLBBCoefDarkCountChloroA; cycleNum profNum measCoefDarkCountChloroA];
               o_sensorTechFLBBCoefScaleFactBackscat = [o_sensorTechFLBBCoefScaleFactBackscat; cycleNum profNum measCoefScaleFactBackscat];
               o_sensorTechFLBBCoefDarkCountBackscat = [o_sensorTechFLBBCoefDarkCountBackscat; cycleNum profNum measCoefDarkCountBackscat];
               
            otherwise
               fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet for sensor tech data type #%d\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum, ...
                  sensorType);
         end
         
      case 251
         % sensor parameter
         
         if ((g_decArgo_needFullBufferInfo == 1) && (a_procLevel == 0))
            if (isempty(g_decArgo_251TypeReceivedData))
               g_decArgo_251TypeReceivedData = 1;
            else
               g_decArgo_251TypeReceivedData = g_decArgo_251TypeReceivedData + 1;
            end
         end
         
         if ((a_procLevel == 0) || (a_procLevel == 1))
            continue
         end
         
         % message data frame
         msgData = tabSensors(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [repmat([8 8 8 32 32], 1, 12) 56];
         % get item bits
         values = get_bits(firstBit, tabNbBits, msgData);
         
         % decode and store data values
         measModSensorNum = [];
         measParamType = [];
         measParamNum = [];
         measOldVal = [];
         measNewVal = [];
         for idBin = 1:12
            measModSensorNum = [measModSensorNum values(5*(idBin-1)+1)];
            measParamType = [measParamType values(5*(idBin-1)+2)];
            measParamNum = [measParamNum values(5*(idBin-1)+3)];
            measOldVal = [measOldVal typecast(uint32(values(5*(idBin-1)+4)), 'single')];
            measNewVal = [measNewVal typecast(uint32(values(5*(idBin-1)+5)), 'single')];
         end
         
         % try to identify 'bad' reported sensor modification
         data = [measModSensorNum' measParamType' measParamNum' measOldVal' measNewVal'];
         idDel = find((data(:, 1) == 0) & (data(:, 2) == 0) & (data(:, 3) == 0) & ...
            (data(:, 4) == 0) & (data(:, 5) == 0));
         if (~isempty(idDel))
            if (idDel(end) == size(data, 1))
               idCut = find(diff(idDel) ~= 1);
               if (~isempty(idCut))
                  idDel = idDel(idCut(end)+1:end);
               end
               measModSensorNum(idDel) = -1;
               measParamType(idDel) = -1;
               measParamNum(idDel) = -1;
               measOldVal(idDel) = -1;
               measNewVal(idDel) = -1;
            end
         end
         
         o_sensorParamModSensorNum = [o_sensorParamModSensorNum; measModSensorNum];
         o_sensorParamParamType = [o_sensorParamParamType; measParamType];
         o_sensorParamParamNum = [o_sensorParamParamNum; measParamNum];
         o_sensorParamOldVal = [o_sensorParamOldVal; measOldVal];
         o_sensorParamNewVal = [o_sensorParamNewVal; measNewVal];
         
         o_cyProfPhaseList = [o_cyProfPhaseList; ...
            251 -1 -1 -1 -1 sbdFileDate];
         
         % update float configuration
         update_float_config_ir_rudics_105_to_110_112_sbd2(251, sbdFileDate, ...
            [measModSensorNum' measParamType' measParamNum' measOldVal' measNewVal']);
         
      case 252
         % float pressure data
         
         if ((g_decArgo_needFullBufferInfo == 1) && (a_procLevel == 0))
            % message data frame
            msgData = tabSensors(idMes, 2:end);
            
            % first item bit number
            firstBit = 1;
            % item bit lengths
            tabNbBits = [16 repmat([4 4 8 8 16], 1, 27) 16];
            % get item bits
            values = get_bits(firstBit, tabNbBits, msgData);
            
            % decode and store data values
            cycleNum = values(1);
            
            for idBin = 1:27
               profNum = values(5*(idBin-1)+3);
               phaseNum = values(5*(idBin-1)+2);
               pumpOrEv = values(5*(idBin-1)+4);
               actPres = values(5*(idBin-1)+5);
               time = values(5*(idBin-1)+6);
               
               if ((profNum == 0) && (phaseNum == 0) && (pumpOrEv == 0) && (actPres == 0) && (time == 0))
                  continue
               end
               
               g_decArgo_252TypeReceivedData = [g_decArgo_252TypeReceivedData; ...
                  cycleNum profNum phaseNum];
            end
         end
         
         if ((a_procLevel == 0) || (a_procLevel == 2))
            continue
         end
         
         % message data frame
         msgData = tabSensors(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [16 repmat([4 4 8 8 16], 1, 27) 16];
         % get item bits
         values = get_bits(firstBit, tabNbBits, msgData);
         
         % decode and store data values
         cycleNum = values(1);
         g_decArgo_cycleNum = cycleNum;
         
         for idBin = 1:27
            profNum = values(5*(idBin-1)+3);
            phaseNum = values(5*(idBin-1)+2);
            pumpOrEv = values(5*(idBin-1)+4);
            actPres = values(5*(idBin-1)+5);
            time = values(5*(idBin-1)+6);
            
            if ((profNum == 0) && (phaseNum == 0) && (pumpOrEv == 0) && (actPres == 0) && (time == 0))
               continue
            end
            
            o_floatPresPumpOrEv = [o_floatPresPumpOrEv; ...
               [cycleNum profNum phaseNum pumpOrEv]];
            o_floatPresActPres = [o_floatPresActPres; ...
               [cycleNum profNum phaseNum actPres]];
            o_floatPresTime = [o_floatPresTime; ...
               [cycleNum profNum phaseNum time]];
            
            o_cyProfPhaseList = [o_cyProfPhaseList; ...
               252 -1 cycleNum profNum phaseNum sbdFileDate];
         end
         
      case 253
         % float technical data
         
         if (a_procLevel == 2)
            continue
         end
         
         % message data frame
         msgData = tabSensors(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [repmat([8], 1, 6) 16 repmat([16 16 8], 1, 3) 8 8 16 16 8 8 ...
            repmat([16], 1, 6) repmat([8], 1, 10) repmat([16], 1, 4) ...
            repmat([8], 1, 9) repmat([16], 1, 4) 8 8 8 16 16 8 16 ...
            repmat([8], 1, 7) repmat([16 8 8 8], 1, 2) 8 32 232];
         % get item bits
         tabTech = get_bits(firstBit, tabNbBits, msgData);
         g_decArgo_cycleNum = tabTech(9);
         
         % anomaly management (ex: 2902087 cycle #38)
         profNum = tabTech(10);
         if (profNum > 9)
            fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent profile number (#%d) - ignoring packet data\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, ...
               profNum);
            continue
         end
         
         if (a_procLevel == 0)
            g_decArgo_253TypeReceivedData = [g_decArgo_253TypeReceivedData; ...
               tabTech(9) tabTech(10) tabTech(13)];
            continue
         end
         
         % packet date
         packJulD = datenum(sprintf('%02d%02d%02d%02d%02d%02d', tabTech(1:6)), 'ddmmyyHHMMSS') - g_decArgo_janFirst1950InMatlab;
         
         % compute GPS location
         if (tabTech(71) == 0)
            signLat = 1;
         else
            signLat = -1;
         end
         gpsLocLat = signLat*(tabTech(68) + (tabTech(69) + ...
            tabTech(70)/10000)/60);
         if (tabTech(75) == 0)
            signLon = 1;
         else
            signLon = -1;
         end
         gpsLocLon = signLon*(tabTech(72) + (tabTech(73) + ...
            tabTech(74)/10000)/60);
         
         tabTech = [packJulD tabTech(7:80)' gpsLocLon gpsLocLat sbdFileDate];
         
         % internal pressure in mbar
         tabTech(11) = tabTech(11)*5;
         
         % some pressures are given in bars
         %          tabTech(26) = tabTech(26)*10;
         %          tabTech(27) = tabTech(27)*10;
         %          tabTech(30) = tabTech(30)*10;
         %          tabTech(31) = tabTech(31)*10;
         %          tabTech(40) = tabTech(40)*10;
         %          tabTech(45) = tabTech(45)*10;
         %          tabTech(46) = tabTech(46)*10;
         %          tabTech(53) = tabTech(53)*10;
         %          tabTech(58) = tabTech(58)*10;
         
         o_tabTech = [o_tabTech; tabTech];
         
         o_cyProfPhaseList = [o_cyProfPhaseList; ...
            253 -1 tabTech(4) tabTech(5) tabTech(8) sbdFileDate];
         
      case 254
         % float prog technical data
         
         if ((g_decArgo_needFullBufferInfo == 1) && (a_procLevel == 0))
            % message data frame
            msgData = tabSensors(idMes, 2:end);
            
            % first item bit number
            firstBit = 1;
            % item bit lengths
            tabNbBits = [repmat([8], 1, 6) 16 8 repmat([16], 1, 28) 592];
            % get item bits
            values = get_bits(firstBit, tabNbBits, msgData);
            
            g_decArgo_254TypeReceivedData = [g_decArgo_254TypeReceivedData; ...
               values(7) values(8)];
         end
         
         if (a_procLevel == 1)
            continue
         end
         
         % message data frame
         msgData = tabSensors(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [repmat([8], 1, 6) 16 8 repmat([16], 1, 28) 592];
         % get item bits
         values = get_bits(firstBit, tabNbBits, msgData);
         
         profNum = values(8);
         if (profNum > 9)
            fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent profile number (#%d) - ignoring packet data\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, ...
               profNum);
            continue
         end
         
         if (a_procLevel == 0)
            g_decArgo_254TypeReceivedData = [g_decArgo_254TypeReceivedData; ...
               values(7) values(8)];
            continue
         end
         
         % calibration coefficients
         values(35) = values(35)/1000;
         if (values(36) < 32768) % 32768 = 65536/2
            values(36) = -values(36);
         else
            values(36) = 65536 - values(36);
         end
         
         cycleNum = values(7);
         
         if (cycleNum ~= g_decArgo_cycleNum)
            fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) - ignoring packet data\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, ...
               cycleNum, g_decArgo_cycleNum);
            continue
         end
         
         % packet date
         packJulD = datenum(sprintf('%02d%02d%02d%02d%02d%02d', values(1:6)), 'ddmmyyHHMMSS') - g_decArgo_janFirst1950InMatlab;
         
         floatProgTech = [packJulD values(7:36)' sbdFileDate];
         
         o_floatProgTech = [o_floatProgTech; floatProgTech];
         
         o_cyProfPhaseList = [o_cyProfPhaseList; ...
            254 -1 values(7) values(8) -1 sbdFileDate];
         
         % update float configuration
         update_float_config_ir_rudics_105_to_110_112_sbd2(254, packJulD, values(7:36));
         
      case 255
         % float prog param data
         
         if ((g_decArgo_needFullBufferInfo == 1) && (a_procLevel == 0))
            % message data frame
            msgData = tabSensors(idMes, 2:end);
            
            % first item bit number
            firstBit = 1;
            % item bit lengths
            tabNbBits = [repmat([8], 1, 6) 16 8 8 16 8 repmat([16 8 8 8], 1, 5) ...
               8 16 8 repmat([8 8 16 16 8], 1, 10) 216];
            
            % get item bits
            values = get_bits(firstBit, tabNbBits, msgData);
            
            g_decArgo_255TypeReceivedData = [g_decArgo_255TypeReceivedData; ...
               values(7) values(8)];
         end
         
         if (a_procLevel == 1)
            continue
         end
         
         % message data frame
         msgData = tabSensors(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [repmat([8], 1, 6) 16 8 8 16 8 repmat([16 8 8 8], 1, 5) ...
            8 16 8 repmat([8 8 16 16 8], 1, 10) 216];
         
         % get item bits
         values = get_bits(firstBit, tabNbBits, msgData);
         
         profNum = values(8);
         if (profNum > 9)
            fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent profile number (#%d) - ignoring packet data\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, ...
               profNum);
            continue
         end
         
         if (a_procLevel == 0)
            g_decArgo_255TypeReceivedData = [g_decArgo_255TypeReceivedData; ...
               values(7) values(8)];
            continue
         end
         
         g_decArgo_cycleNum = values(7);
         
         % packet date
         packJulD = datenum(sprintf('%02d%02d%02d%02d%02d%02d', values(1:6)), 'ddmmyyHHMMSS') - g_decArgo_janFirst1950InMatlab;
         
         floatProgParam = [packJulD values(7:84)' sbdFileDate];
         
         o_floatProgParam = [o_floatProgParam; floatProgParam];
         
         o_cyProfPhaseList = [o_cyProfPhaseList; ...
            255 -1 values(7) values(8) -1 sbdFileDate];
         
         % update float configuration
         update_float_config_ir_rudics_105_to_110_112_sbd2(255, packJulD, values(7:84));
         
      otherwise
         fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet for packet type #%d\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            packType);
   end
   
end


% sometimes (#6901473), technical message of a given cycle and profile is
% received several times and only the last one has all the information

% clean these data
if (~isempty(o_cyProfPhaseList))
   id253 = find((o_cyProfPhaseList(:, 1) == 253) & ...
      (o_cyProfPhaseList(:, 5) == g_decArgo_phaseSatTrans));
   if (~isempty(id253))
      idDelInList = [];
      idDelInTech = [];
      uCyProf = unique(o_cyProfPhaseList(id253, 3:4),'rows');
      for id = 1:size(uCyProf, 1)
         cyProf = uCyProf(id, :);
         cy = cyProf(1);
         prof = cyProf(2);
         idMulti = find((o_cyProfPhaseList(id253, 3) == cy) & ...
            (o_cyProfPhaseList(id253, 4) == prof));
         if (length(idMulti) > 1)
            idDelInList = [idDelInList; id253(idMulti(1:end-1))];
            
            idTech = find((o_tabTech(:, 4) == cy) & ...
               (o_tabTech(:, 5) == prof) & ...
               (o_tabTech(:, 8) == g_decArgo_phaseSatTrans));
            if (length(idTech) > 1)
               idDelInTech = [idDelInTech; idTech(1:end-1)];
               
               fprintf('WARNING: Float #%d: %d duplicated float technical messages for cycle #%d and profile #%d - only the last one is considered\n', ...
                  g_decArgo_floatNum, length(idTech), cy, prof);
            end
         end
      end
      
      if (~isempty(idDelInList))
         o_cyProfPhaseList(idDelInList, :) = [];
      end
      if (~isempty(idDelInTech))
         o_tabTech(idDelInTech, :) = [];
      end
   end
end

% store output data in cell arrays
o_dataCTDMean{1} = o_dataCTDMeanDate;
o_dataCTDMean{2} = o_dataCTDMeanDateTrans;
o_dataCTDMean{3} = o_dataCTDMeanPres;
o_dataCTDMean{4} = o_dataCTDMeanTemp;
o_dataCTDMean{5} = o_dataCTDMeanSal;

o_dataCTDStdMed{1} = o_dataCTDStdMedDate;
o_dataCTDStdMed{2} = o_dataCTDStdMedDateTrans;
o_dataCTDStdMed{3} = o_dataCTDStdMedPresMean;
o_dataCTDStdMed{4} = o_dataCTDStdMedTempStd;
o_dataCTDStdMed{5} = o_dataCTDStdMedSalStd;
o_dataCTDStdMed{6} = o_dataCTDStdMedPresMed;
o_dataCTDStdMed{7} = o_dataCTDStdMedTempMed;
o_dataCTDStdMed{8} = o_dataCTDStdMedSalMed;

o_dataCTD{1} = o_dataCTDMean;
o_dataCTD{2} = o_dataCTDStdMed;

o_dataOXYMean{1} = o_dataOXYMeanDate;
o_dataOXYMean{2} = o_dataOXYMeanDateTrans;
o_dataOXYMean{3} = o_dataOXYMeanPres;
o_dataOXYMean{4} = o_dataOXYMeanC1Phase;
o_dataOXYMean{5} = o_dataOXYMeanC2Phase;
o_dataOXYMean{6} = o_dataOXYMeanTemp;

o_dataOXYStdMed{1} = o_dataOXYStdMedDate;
o_dataOXYStdMed{2} = o_dataOXYStdMedDateTrans;
o_dataOXYStdMed{3} = o_dataOXYStdMedPresMean;
o_dataOXYStdMed{4} = o_dataOXYStdMedC1PhaseStd;
o_dataOXYStdMed{5} = o_dataOXYStdMedC2PhaseStd;
o_dataOXYStdMed{6} = o_dataOXYStdMedTempStd;
o_dataOXYStdMed{7} = o_dataOXYStdMedC1PhaseMed;
o_dataOXYStdMed{8} = o_dataOXYStdMedC2PhaseMed;
o_dataOXYStdMed{9} = o_dataOXYStdMedTempMed;

o_dataOXY{1} = o_dataOXYMean;
o_dataOXY{2} = o_dataOXYStdMed;

o_dataFLBBMean{1} = o_dataFLBBMeanDate;
o_dataFLBBMean{2} = o_dataFLBBMeanDateTrans;
o_dataFLBBMean{3} = o_dataFLBBMeanPres;
o_dataFLBBMean{4} = o_dataFLBBMeanChloroA;
o_dataFLBBMean{5} = o_dataFLBBMeanBackscat;

o_dataFLBBStdMed{1} = o_dataFLBBStdMedDate;
o_dataFLBBStdMed{2} = o_dataFLBBStdMedDateTrans;
o_dataFLBBStdMed{3} = o_dataFLBBStdMedPresMean;
o_dataFLBBStdMed{4} = o_dataFLBBStdMedChloroAStd;
o_dataFLBBStdMed{5} = o_dataFLBBStdMedBackscatStd;
o_dataFLBBStdMed{6} = o_dataFLBBStdMedChloroAMed;
o_dataFLBBStdMed{7} = o_dataFLBBStdMedBackscatMed;

o_dataFLBB{1} = o_dataFLBBMean;
o_dataFLBB{2} = o_dataFLBBStdMed;

o_sensorTechCTD{1} = o_sensorTechCTDNbPackDesc;
o_sensorTechCTD{2} = o_sensorTechCTDNbPackDrift;
o_sensorTechCTD{3} = o_sensorTechCTDNbPackAsc;
o_sensorTechCTD{4} = o_sensorTechCTDNbMeasDescZ1;
o_sensorTechCTD{5} = o_sensorTechCTDNbMeasDescZ2;
o_sensorTechCTD{6} = o_sensorTechCTDNbMeasDescZ3;
o_sensorTechCTD{7} = o_sensorTechCTDNbMeasDescZ4;
o_sensorTechCTD{8} = o_sensorTechCTDNbMeasDescZ5;
o_sensorTechCTD{9} = o_sensorTechCTDNbMeasDrift;
o_sensorTechCTD{10} = o_sensorTechCTDNbMeasAscZ1;
o_sensorTechCTD{11} = o_sensorTechCTDNbMeasAscZ2;
o_sensorTechCTD{12} = o_sensorTechCTDNbMeasAscZ3;
o_sensorTechCTD{13} = o_sensorTechCTDNbMeasAscZ4;
o_sensorTechCTD{14} = o_sensorTechCTDNbMeasAscZ5;
o_sensorTechCTD{15} = o_sensorTechCTDSensorState;
o_sensorTechCTD{16} = o_sensorTechCTDOffsetPres;
o_sensorTechCTD{17} = o_sensorTechCTDSubPres;
o_sensorTechCTD{18} = o_sensorTechCTDSubTemp;
o_sensorTechCTD{19} = o_sensorTechCTDSubSal;

o_sensorTechOPTODE{1} = o_sensorTechOPTODENbPackDesc;
o_sensorTechOPTODE{2} = o_sensorTechOPTODENbPackDrift;
o_sensorTechOPTODE{3} = o_sensorTechOPTODENbPackAsc;
o_sensorTechOPTODE{4} = o_sensorTechOPTODENbMeasDescZ1;
o_sensorTechOPTODE{5} = o_sensorTechOPTODENbMeasDescZ2;
o_sensorTechOPTODE{6} = o_sensorTechOPTODENbMeasDescZ3;
o_sensorTechOPTODE{7} = o_sensorTechOPTODENbMeasDescZ4;
o_sensorTechOPTODE{8} = o_sensorTechOPTODENbMeasDescZ5;
o_sensorTechOPTODE{9} = o_sensorTechOPTODENbMeasDrift;
o_sensorTechOPTODE{10} = o_sensorTechOPTODENbMeasAscZ1;
o_sensorTechOPTODE{11} = o_sensorTechOPTODENbMeasAscZ2;
o_sensorTechOPTODE{12} = o_sensorTechOPTODENbMeasAscZ3;
o_sensorTechOPTODE{13} = o_sensorTechOPTODENbMeasAscZ4;
o_sensorTechOPTODE{14} = o_sensorTechOPTODENbMeasAscZ5;
o_sensorTechOPTODE{15} = o_sensorTechOPTODESensorState;

o_sensorTechFLBB{1} = o_sensorTechFLBBNbPackDesc;
o_sensorTechFLBB{2} = o_sensorTechFLBBNbPackDrift;
o_sensorTechFLBB{3} = o_sensorTechFLBBNbPackAsc;
o_sensorTechFLBB{4} = o_sensorTechFLBBNbMeasDescZ1;
o_sensorTechFLBB{5} = o_sensorTechFLBBNbMeasDescZ2;
o_sensorTechFLBB{6} = o_sensorTechFLBBNbMeasDescZ3;
o_sensorTechFLBB{7} = o_sensorTechFLBBNbMeasDescZ4;
o_sensorTechFLBB{8} = o_sensorTechFLBBNbMeasDescZ5;
o_sensorTechFLBB{9} = o_sensorTechFLBBNbMeasDrift;
o_sensorTechFLBB{10} = o_sensorTechFLBBNbMeasAscZ1;
o_sensorTechFLBB{11} = o_sensorTechFLBBNbMeasAscZ2;
o_sensorTechFLBB{12} = o_sensorTechFLBBNbMeasAscZ3;
o_sensorTechFLBB{13} = o_sensorTechFLBBNbMeasAscZ4;
o_sensorTechFLBB{14} = o_sensorTechFLBBNbMeasAscZ5;
o_sensorTechFLBB{15} = o_sensorTechFLBBSensorState;
o_sensorTechFLBB{16} = o_sensorTechFLBBSensorSerialNum;
o_sensorTechFLBB{17} = o_sensorTechFLBBCoefScaleFactChloroA;
o_sensorTechFLBB{18} = o_sensorTechFLBBCoefDarkCountChloroA;
o_sensorTechFLBB{19} = o_sensorTechFLBBCoefScaleFactBackscat;
o_sensorTechFLBB{20} = o_sensorTechFLBBCoefDarkCountBackscat;

o_sensorParam{1} = o_sensorParamModSensorNum;
o_sensorParam{2} = o_sensorParamParamType;
o_sensorParam{3} = o_sensorParamParamNum;
o_sensorParam{4} = o_sensorParamOldVal;
o_sensorParam{5} = o_sensorParamNewVal;

o_floatPres{1} = o_floatPresPumpOrEv;
o_floatPres{2} = o_floatPresActPres;
o_floatPres{3} = o_floatPresTime;

return
