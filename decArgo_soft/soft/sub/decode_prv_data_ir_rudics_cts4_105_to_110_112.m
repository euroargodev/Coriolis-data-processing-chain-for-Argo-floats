% ------------------------------------------------------------------------------
% Decode PROVOR packet data.
%
% SYNTAX :
%  [o_cyProfPhaseList, ...
%    o_dataCTD, o_dataOXY, o_dataOCR, o_dataECO3, o_dataFLNTU, ...
%    o_dataCROVER, o_dataSUNA, ...
%    o_sensorTechCTD, o_sensorTechOPTODE, ...
%    o_sensorTechOCR, o_sensorTechECO3, ...
%    o_sensorTechFLNTU, o_sensorTechCROVER, o_sensorTechSUNA, ...
%    o_sensorParam, ...
%    o_floatPres, ...
%    o_tabTech, o_floatProgTech, o_floatProgParam] = ...
%    decode_prv_data_ir_rudics_cts4_105_to_110_112(a_tabSensors, a_tabDates, a_procLevel, a_floatDmFlag)
%
% INPUT PARAMETERS :
%   a_tabSensors  : data frame to decode
%   a_tabDates    : corresponding dates of Iridium messages
%   a_procLevel   : processing level (0: collect only rough information, 1:
%                   process data and technical information, 2: process
%                   configuration information)
%   a_floatDmFlag : float DM flag
%
% OUTPUT PARAMETERS :
%   o_cyProfPhaseList  : information (cycle #, prof #, phase #) on each
%                        received packet
%   o_dataCTD          : decoded CTD data
%   o_dataOXY          : decoded OXY data
%   o_dataOCR          : decoded OCR data
%   o_dataECO3         : decoded ECO3 data
%   o_dataFLNTU        : decoded FLNTU data
%   o_dataCROVER       : decoded cROVER data
%   o_dataSUNA         : decoded SUNA data
%   o_sensorTechCTD    : decoded CTD technical data
%   o_sensorTechOPTODE : decoded OXY technical data
%   o_sensorTechOCR    : decoded OCR technical data
%   o_sensorTechECO3   : decoded ECO3 technical data
%   o_sensorTechFLNTU  : decoded FLNTU technical data
%   o_sensorTechCROVER : decoded cROVER technical data
%   o_sensorTechSUNA   : decoded SUNA technical data
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
%   02/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cyProfPhaseList, ...
   o_dataCTD, o_dataOXY, o_dataOCR, o_dataECO3, o_dataFLNTU, ...
   o_dataCROVER, o_dataSUNA, ...
   o_sensorTechCTD, o_sensorTechOPTODE, ...
   o_sensorTechOCR, o_sensorTechECO3, ...
   o_sensorTechFLNTU, o_sensorTechCROVER, o_sensorTechSUNA, ...
   o_sensorParam, ...
   o_floatPres, ...
   o_tabTech, o_floatProgTech, o_floatProgParam] = ...
   decode_prv_data_ir_rudics_cts4_105_to_110_112(a_tabSensors, a_tabDates, a_procLevel, a_floatDmFlag)

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

% sensor list
global g_decArgo_sensorList;

% to check timeouted buffer contents
global g_decArgo_needFullBufferInfo;


% output parameters initialization
o_cyProfPhaseList = [];

o_dataCTD = [];
o_dataOXY = [];
o_dataECO3 = [];
o_dataOCR = [];
o_dataFLNTU = [];
o_dataCROVER = [];
o_dataSUNA = [];

o_sensorTechCTD = [];
o_sensorTechOPTODE = [];
o_sensorTechOCR = [];
o_sensorTechECO3 = [];
o_sensorTechFLNTU = [];
o_sensorTechCROVER = [];
o_sensorTechSUNA = [];

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

o_dataCTDRawDate = [];
o_dataCTDRawDateTrans = [];
o_dataCTDRawPres = [];
o_dataCTDRawTemp = [];
o_dataCTDRawSal = [];

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

o_dataOXYRawDate = [];
o_dataOXYRawDateTrans = [];
o_dataOXYRawPres = [];
o_dataOXYRawC1Phase = [];
o_dataOXYRawC2Phase = [];
o_dataOXYRawTemp = [];

o_dataOXYStdMedDate = [];
o_dataOXYStdMedDateTrans = [];
o_dataOXYStdMedPresMean = [];
o_dataOXYStdMedC1PhaseStd = [];
o_dataOXYStdMedC2PhaseStd = [];
o_dataOXYStdMedTempStd = [];
o_dataOXYStdMedC1PhaseMed = [];
o_dataOXYStdMedC2PhaseMed = [];
o_dataOXYStdMedTempMed = [];

o_dataECO3MeanDate = [];
o_dataECO3MeanDateTrans = [];
o_dataECO3MeanPres = [];
o_dataECO3MeanChloroA = [];
o_dataECO3MeanBackscat = [];
o_dataECO3MeanCdom = [];

o_dataECO3RawDate = [];
o_dataECO3RawDateTrans = [];
o_dataECO3RawPres = [];
o_dataECO3RawChloroA = [];
o_dataECO3RawBackscat = [];
o_dataECO3RawCdom = [];

o_dataECO3StdMedDate = [];
o_dataECO3StdMedDateTrans = [];
o_dataECO3StdMedPresMean = [];
o_dataECO3StdMedChloroAStd = [];
o_dataECO3StdMedBackscatStd = [];
o_dataECO3StdMedCdomStd = [];
o_dataECO3StdMedChloroAMed = [];
o_dataECO3StdMedBackscatMed = [];
o_dataECO3StdMedCdomMed = [];

o_dataOCRMeanDate = [];
o_dataOCRMeanDateTrans = [];
o_dataOCRMeanPres = [];
o_dataOCRMeanIr1 = [];
o_dataOCRMeanIr2 = [];
o_dataOCRMeanIr3 = [];
o_dataOCRMeanIr4 = [];

o_dataOCRRawDate = [];
o_dataOCRRawDateTrans = [];
o_dataOCRRawPres = [];
o_dataOCRRawIr1 = [];
o_dataOCRRawIr2 = [];
o_dataOCRRawIr3 = [];
o_dataOCRRawIr4 = [];

o_dataOCRStdMedDate = [];
o_dataOCRStdMedDateTrans = [];
o_dataOCRStdMedPresMean = [];
o_dataOCRStdMedIr1Std = [];
o_dataOCRStdMedIr2Std = [];
o_dataOCRStdMedIr3Std = [];
o_dataOCRStdMedIr4Std = [];
o_dataOCRStdMedIr1Med = [];
o_dataOCRStdMedIr2Med = [];
o_dataOCRStdMedIr3Med = [];
o_dataOCRStdMedIr4Med = [];

o_dataFLNTUMeanDate = [];
o_dataFLNTUMeanDateTrans = [];
o_dataFLNTUMeanPres = [];
o_dataFLNTUMeanChloro = [];
o_dataFLNTUMeanTurbi = [];

o_dataFLNTURawDate = [];
o_dataFLNTURawDateTrans = [];
o_dataFLNTURawPres = [];
o_dataFLNTURawChloro = [];
o_dataFLNTURawTurbi = [];

o_dataFLNTUStdMedDate = [];
o_dataFLNTUStdMedDateTrans = [];
o_dataFLNTUStdMedPresMean = [];
o_dataFLNTUStdMedChloroStd = [];
o_dataFLNTUStdMedTurbiStd = [];
o_dataFLNTUStdMedChloroMed = [];
o_dataFLNTUStdMedTurbiMed = [];

o_dataCROVERMeanDate = [];
o_dataCROVERMeanDateTrans = [];
o_dataCROVERMeanPres = [];
o_dataCROVERMeanCoefAtt = [];

o_dataCROVERRawDate = [];
o_dataCROVERRawDateTrans = [];
o_dataCROVERRawPres = [];
o_dataCROVERRawCoefAtt = [];

o_dataCROVERStdMedDate = [];
o_dataCROVERStdMedDateTrans = [];
o_dataCROVERStdMedPresMean = [];
o_dataCROVERStdMedCoefAttStd = [];
o_dataCROVERStdMedCoefAttMed = [];

o_dataSUNAMeanDate = [];
o_dataSUNAMeanDateTrans = [];
o_dataSUNAMeanPres = [];
o_dataSUNAMeanConcNitra = [];

o_dataSUNARawDate = [];
o_dataSUNARawDateTrans = [];
o_dataSUNARawPres = [];
o_dataSUNARawConcNitra = [];

o_dataSUNAStdMedDate = [];
o_dataSUNAStdMedDateTrans = [];
o_dataSUNAStdMedPresMean = [];
o_dataSUNAStdMedConcNitraStd = [];
o_dataSUNAStdMedConcNitraMed = [];

dataSUNAAPFDate = [];
dataSUNAAPFDateTrans = [];
dataSUNAAPFCTDPres = [];
dataSUNAAPFCTDTemp = [];
dataSUNAAPFCTDSal = [];
dataSUNAAPFIntTemp = [];
dataSUNAAPFSpecTemp = [];
dataSUNAAPFIntRelHumidity = [];
dataSUNAAPFDarkSpecMean = [];
dataSUNAAPFDarkSpecStd = [];
dataSUNAAPFSensorNitra = [];
dataSUNAAPFAbsFitRes = [];
dataSUNAAPFOutSpec = [];

o_dataSUNAAPFDate = [];
o_dataSUNAAPFDateTrans = [];
o_dataSUNAAPFCTDPres = [];
o_dataSUNAAPFCTDTemp = [];
o_dataSUNAAPFCTDSal = [];
o_dataSUNAAPFIntTemp = [];
o_dataSUNAAPFSpecTemp = [];
o_dataSUNAAPFIntRelHumidity = [];
o_dataSUNAAPFDarkSpecMean = [];
o_dataSUNAAPFDarkSpecStd = [];
o_dataSUNAAPFSensorNitra = [];
o_dataSUNAAPFAbsFitRes = [];
o_dataSUNAAPFOutSpec = [];

o_dataSUNAAPF2Date = [];
o_dataSUNAAPF2DateTrans = [];
o_dataSUNAAPF2CTDPres = [];
o_dataSUNAAPF2CTDTemp = [];
o_dataSUNAAPF2CTDSal = [];
o_dataSUNAAPF2IntTemp = [];
o_dataSUNAAPF2SpecTemp = [];
o_dataSUNAAPF2IntRelHumidity = [];
o_dataSUNAAPF2DarkSpecMean = [];
o_dataSUNAAPF2DarkSpecStd = [];
o_dataSUNAAPF2SensorNitra = [];
o_dataSUNAAPF2AbsFitRes = [];
o_dataSUNAAPF2OutSpec = [];

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

o_sensorTechOCRNbPackDesc = [];
o_sensorTechOCRNbPackDrift = [];
o_sensorTechOCRNbPackAsc = [];
o_sensorTechOCRNbMeasDescZ1 = [];
o_sensorTechOCRNbMeasDescZ2 = [];
o_sensorTechOCRNbMeasDescZ3 = [];
o_sensorTechOCRNbMeasDescZ4 = [];
o_sensorTechOCRNbMeasDescZ5 = [];
o_sensorTechOCRNbMeasDrift = [];
o_sensorTechOCRNbMeasAscZ1 = [];
o_sensorTechOCRNbMeasAscZ2 = [];
o_sensorTechOCRNbMeasAscZ3 = [];
o_sensorTechOCRNbMeasAscZ4 = [];
o_sensorTechOCRNbMeasAscZ5 = [];
o_sensorTechOCRSensorState = [];
o_sensorTechOCRSensorSerialNum = [];
o_sensorTechOCRCoefLambda1A0 = [];
o_sensorTechOCRCoefLambda1A1 = [];
o_sensorTechOCRCoefLambda1Lm = [];
o_sensorTechOCRCoefLambda2A0 = [];
o_sensorTechOCRCoefLambda2A1 = [];
o_sensorTechOCRCoefLambda2Lm = [];
o_sensorTechOCRCoefLambda3A0 = [];
o_sensorTechOCRCoefLambda3A1 = [];
o_sensorTechOCRCoefLambda3Lm = [];
o_sensorTechOCRCoefParA0 = [];
o_sensorTechOCRCoefParA1 = [];
o_sensorTechOCRCoefParLm = [];

o_sensorTechECO3NbPackDesc = [];
o_sensorTechECO3NbPackDrift = [];
o_sensorTechECO3NbPackAsc = [];
o_sensorTechECO3NbMeasDescZ1 = [];
o_sensorTechECO3NbMeasDescZ2 = [];
o_sensorTechECO3NbMeasDescZ3 = [];
o_sensorTechECO3NbMeasDescZ4 = [];
o_sensorTechECO3NbMeasDescZ5 = [];
o_sensorTechECO3NbMeasDrift = [];
o_sensorTechECO3NbMeasAscZ1 = [];
o_sensorTechECO3NbMeasAscZ2 = [];
o_sensorTechECO3NbMeasAscZ3 = [];
o_sensorTechECO3NbMeasAscZ4 = [];
o_sensorTechECO3NbMeasAscZ5 = [];
o_sensorTechECO3SensorState = [];
o_sensorTechECO3SensorSerialNum = [];
o_sensorTechECO3CoefScaleFactChloroA = [];
o_sensorTechECO3CoefDarkCountChloroA = [];
o_sensorTechECO3CoefScaleFactBackscat = [];
o_sensorTechECO3CoefDarkCountBackscat = [];
o_sensorTechECO3CoefScaleFactCdom = [];
o_sensorTechECO3CoefDarkCountCdom = [];

o_sensorTechFLNTUNbPackDesc = [];
o_sensorTechFLNTUNbPackDrift = [];
o_sensorTechFLNTUNbPackAsc = [];
o_sensorTechFLNTUNbMeasDescZ1 = [];
o_sensorTechFLNTUNbMeasDescZ2 = [];
o_sensorTechFLNTUNbMeasDescZ3 = [];
o_sensorTechFLNTUNbMeasDescZ4 = [];
o_sensorTechFLNTUNbMeasDescZ5 = [];
o_sensorTechFLNTUNbMeasDrift = [];
o_sensorTechFLNTUNbMeasAscZ1 = [];
o_sensorTechFLNTUNbMeasAscZ2 = [];
o_sensorTechFLNTUNbMeasAscZ3 = [];
o_sensorTechFLNTUNbMeasAscZ4 = [];
o_sensorTechFLNTUNbMeasAscZ5 = [];
o_sensorTechFLNTUSensorState = [];
o_sensorTechFLNTUCoefScaleChloro = [];
o_sensorTechFLNTUDarkCountChloro = [];
o_sensorTechFLNTUCoefScaleTurbi = [];
o_sensorTechFLNTUDarkCountTurbi = [];

o_sensorTechCROVERNbPackDesc = [];
o_sensorTechCROVERNbPackDrift = [];
o_sensorTechCROVERNbPackAsc = [];
o_sensorTechCROVERNbMeasDescZ1 = [];
o_sensorTechCROVERNbMeasDescZ2 = [];
o_sensorTechCROVERNbMeasDescZ3 = [];
o_sensorTechCROVERNbMeasDescZ4 = [];
o_sensorTechCROVERNbMeasDescZ5 = [];
o_sensorTechCROVERNbMeasDrift = [];
o_sensorTechCROVERNbMeasAscZ1 = [];
o_sensorTechCROVERNbMeasAscZ2 = [];
o_sensorTechCROVERNbMeasAscZ3 = [];
o_sensorTechCROVERNbMeasAscZ4 = [];
o_sensorTechCROVERNbMeasAscZ5 = [];
o_sensorTechCROVERSensorState = [];
o_sensorTechCROVERSensorSerialNum = [];

o_sensorTechSUNANbPackDesc = [];
o_sensorTechSUNANbPackDrift = [];
o_sensorTechSUNANbPackAsc = [];
o_sensorTechSUNANbMeasDescZ1 = [];
o_sensorTechSUNANbMeasDescZ2 = [];
o_sensorTechSUNANbMeasDescZ3 = [];
o_sensorTechSUNANbMeasDescZ4 = [];
o_sensorTechSUNANbMeasDescZ5 = [];
o_sensorTechSUNANbMeasDrift = [];
o_sensorTechSUNANbMeasAscZ1 = [];
o_sensorTechSUNANbMeasAscZ2 = [];
o_sensorTechSUNANbMeasAscZ3 = [];
o_sensorTechSUNANbMeasAscZ4 = [];
o_sensorTechSUNANbMeasAscZ5 = [];
o_sensorTechSUNASensorState = [];
o_sensorTechSUNASensorSerialNum = [];
o_sensorTechSUNAAPFSampCounter = [];
o_sensorTechSUNAAPFPowerCycleCounter = [];
o_sensorTechSUNAAPFErrorCounter = [];
o_sensorTechSUNAAPFSupplyVoltage = [];
o_sensorTechSUNAAPFSupplyCurrent = [];
o_sensorTechSUNAAPFOutPixelBegin = [];
o_sensorTechSUNAAPFOutPixelEnd = [];

o_sensorParamModSensorNum = [];
o_sensorParamParamType = [];
o_sensorParamParamNum = [];
o_sensorParamOldVal = [];
o_sensorParamNewVal = [];

o_floatPresPumpOrEv = [];
o_floatPresActPres = [];
o_floatPresTime = [];

if (~isempty(a_tabSensors))
   
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
      
      if ~((length(unique(dataPack(71:140))) == 1) && (dataPack(71) == 255))
         tabSensors = [tabSensors; [dataPack(71:140) repmat([0], 1, 70)]];
         tabDates = [tabDates; datePack];
      end
   end
   idOther = setdiff([1:size(a_tabSensors, 1)], idSensorTechDataPack);
   tabSensors = [tabSensors; a_tabSensors(idOther, :)];
   tabDates = [tabDates; a_tabDates(idOther, :)];
   
   % sort data by date
   if (a_floatDmFlag == 0)
      [tabDates, idSort] = sort(tabDates);
      tabSensors = tabSensors(idSort, :);
   end
   
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
               
               case {0, 2}
                  % CTD (mean & raw)
                  
                  if (~ismember(0, g_decArgo_sensorList))
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        sensorDataType, 0);
                     continue
                  end
                  
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
                  
                  if (a_procLevel == 0)
                     g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                        sensorDataType cycleNum profNum phaseNum];
                     continue
                  end
                  
                  if (cycleNum ~= g_decArgo_cycleNum)
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        cycleNum, g_decArgo_cycleNum);
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
                                    
                  if (sensorDataType == 0)
                     o_dataCTDMeanDate = [o_dataCTDMeanDate; [cycleNum profNum phaseNum measDate]];
                     o_dataCTDMeanDateTrans = [o_dataCTDMeanDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                     o_dataCTDMeanPres = [o_dataCTDMeanPres; [cycleNum profNum phaseNum measPres]];
                     o_dataCTDMeanTemp = [o_dataCTDMeanTemp; [cycleNum profNum phaseNum measTemp]];
                     o_dataCTDMeanSal = [o_dataCTDMeanSal; [cycleNum profNum phaseNum measSal]];
                  elseif (sensorDataType == 2)
                     o_dataCTDRawDate = [o_dataCTDRawDate; [cycleNum profNum phaseNum measDate]];
                     o_dataCTDRawDateTrans = [o_dataCTDRawDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                     o_dataCTDRawPres = [o_dataCTDRawPres; [cycleNum profNum phaseNum measPres]];
                     o_dataCTDRawTemp = [o_dataCTDRawTemp; [cycleNum profNum phaseNum measTemp]];
                     o_dataCTDRawSal = [o_dataCTDRawSal; [cycleNum profNum phaseNum measSal]];
                  end
                  
                  o_cyProfPhaseList = [o_cyProfPhaseList; ...
                     packType sensorDataType cycleNum profNum phaseNum sbdFileDate];
                  
               case {1}
                  % CTD (stDev & median)
                  
                  if (~ismember(0, g_decArgo_sensorList))
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        sensorDataType, 0);
                     continue
                  end
                  
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
                  
                  if (a_procLevel == 0)
                     g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                        sensorDataType cycleNum profNum phaseNum];
                     continue
                  end
                  
                  if (cycleNum ~= g_decArgo_cycleNum)
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        cycleNum, g_decArgo_cycleNum);
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
                  
               case {3, 5}
                  % OXYGEN (mean & raw)
                  
                  if (~ismember(1, g_decArgo_sensorList))
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        sensorDataType, 1);
                     continue
                  end
                  
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
                  
                  if (a_procLevel == 0)
                     g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                        sensorDataType cycleNum profNum phaseNum];
                     continue
                  end
                  
                  if (cycleNum ~= g_decArgo_cycleNum)
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        cycleNum, g_decArgo_cycleNum);
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
                                    
                  if (sensorDataType == 3)
                     o_dataOXYMeanDate = [o_dataOXYMeanDate; [cycleNum profNum phaseNum measDate]];
                     o_dataOXYMeanDateTrans = [o_dataOXYMeanDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                     o_dataOXYMeanPres = [o_dataOXYMeanPres; [cycleNum profNum phaseNum measPres]];
                     o_dataOXYMeanC1Phase = [o_dataOXYMeanC1Phase; [cycleNum profNum phaseNum measC1Phase]];
                     o_dataOXYMeanC2Phase = [o_dataOXYMeanC2Phase; [cycleNum profNum phaseNum measC2Phase]];
                     o_dataOXYMeanTemp = [o_dataOXYMeanTemp; [cycleNum profNum phaseNum measTemp]];
                  elseif (sensorDataType == 5)
                     o_dataOXYRawDate = [o_dataOXYRawDate; [cycleNum profNum phaseNum measDate]];
                     o_dataOXYRawDateTrans = [o_dataOXYRawDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                     o_dataOXYRawPres = [o_dataOXYRawPres; [cycleNum profNum phaseNum measPres]];
                     o_dataOXYRawC1Phase = [o_dataOXYRawC1Phase; [cycleNum profNum phaseNum measC1Phase]];
                     o_dataOXYRawC2Phase = [o_dataOXYRawC2Phase; [cycleNum profNum phaseNum measC2Phase]];
                     o_dataOXYRawTemp = [o_dataOXYRawTemp; [cycleNum profNum phaseNum measTemp]];
                  end
                  
                  o_cyProfPhaseList = [o_cyProfPhaseList; ...
                     packType sensorDataType cycleNum profNum phaseNum sbdFileDate];
                  
               case {4}
                  % OXYGEN (stDev & median)
                  
                  if (~ismember(1, g_decArgo_sensorList))
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        sensorDataType, 1);
                     continue
                  end
                  
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
                  
                  if (a_procLevel == 0)
                     g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                        sensorDataType cycleNum profNum phaseNum];
                     continue
                  end
                  
                  if (cycleNum ~= g_decArgo_cycleNum)
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        cycleNum, g_decArgo_cycleNum);
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
                  
               case {9, 11}
                  % ECO3 (mean & raw)
                  
                  if (~ismember(3, g_decArgo_sensorList))
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        sensorDataType, 3);
                     continue
                  end
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [16 8 8 32 repmat([16 16 16 16], 1, 16) 16];
                  % get item bits
                  values = get_bits(firstBit, tabNbBits, msgData);
                  
                  % decode and store data values
                  cycleNum = values(1);
                  profNum = values(2);
                  phaseNum = values(3);
                  
                  if (a_procLevel == 0)
                     g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                        sensorDataType cycleNum profNum phaseNum];
                     continue
                  end
                  
                  if (cycleNum ~= g_decArgo_cycleNum)
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        cycleNum, g_decArgo_cycleNum);
                     continue
                  end
                  
                  measDate = ones(1, 16)*g_decArgo_dateDef;
                  measDate(1) = epoch2000_2_julian(values(4));
                  measDateTrans = zeros(1, 16);
                  
                  measPres = [];
                  measChloroA = [];
                  measBackscat = [];
                  measCdom = [];
                  for idBin = 1:16
                     measPres = [measPres values(4*(idBin-1)+5)];
                     measChloroA = [measChloroA values(4*(idBin-1)+6)];
                     measBackscat = [measBackscat values(4*(idBin-1)+7)];
                     measCdom = [measCdom values(4*(idBin-1)+8)];
                  end
                  measDateTrans(1) = 1;
                  measDateTrans(find((measPres == 0) & (measChloroA == 0) & ...
                     (measBackscat == 0) & (measCdom == 0))) = -1;
                  
                  if (sensorDataType == 9)
                     o_dataECO3MeanDate = [o_dataECO3MeanDate; [cycleNum profNum phaseNum measDate]];
                     o_dataECO3MeanDateTrans = [o_dataECO3MeanDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                     o_dataECO3MeanPres = [o_dataECO3MeanPres; [cycleNum profNum phaseNum measPres]];
                     o_dataECO3MeanChloroA = [o_dataECO3MeanChloroA; [cycleNum profNum phaseNum measChloroA]];
                     o_dataECO3MeanBackscat = [o_dataECO3MeanBackscat; [cycleNum profNum phaseNum measBackscat]];
                     o_dataECO3MeanCdom = [o_dataECO3MeanCdom; [cycleNum profNum phaseNum measCdom]];
                  elseif (sensorDataType == 11)
                     o_dataECO3RawDate = [o_dataECO3RawDate; [cycleNum profNum phaseNum measDate]];
                     o_dataECO3RawDateTrans = [o_dataECO3RawDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                     o_dataECO3RawPres = [o_dataECO3RawPres; [cycleNum profNum phaseNum measPres]];
                     o_dataECO3RawChloroA = [o_dataECO3RawChloroA; [cycleNum profNum phaseNum measChloroA]];
                     o_dataECO3RawBackscat = [o_dataECO3RawBackscat; [cycleNum profNum phaseNum measBackscat]];
                     o_dataECO3RawCdom = [o_dataECO3RawCdom; [cycleNum profNum phaseNum measCdom]];
                  end
                  
                  o_cyProfPhaseList = [o_cyProfPhaseList; ...
                     packType sensorDataType cycleNum profNum phaseNum sbdFileDate];
                  
               case {10}
                  % ECO3 (stDev & median)
                  
                  if (~ismember(3, g_decArgo_sensorList))
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        sensorDataType, 3);
                     continue
                  end
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [16 8 8 32 repmat([16 8 8 8 16 16 16], 1, 11) 72];
                  % get item bits
                  values = get_bits(firstBit, tabNbBits, msgData);
                  
                  % decode and store data values
                  cycleNum = values(1);
                  profNum = values(2);
                  phaseNum = values(3);
                  
                  if (a_procLevel == 0)
                     g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                        sensorDataType cycleNum profNum phaseNum];
                     continue
                  end
                  
                  if (cycleNum ~= g_decArgo_cycleNum)
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        cycleNum, g_decArgo_cycleNum);
                     continue
                  end
                  
                  measDate = ones(1, 11)*g_decArgo_dateDef;
                  measDate(1) = epoch2000_2_julian(values(4));
                  measDateTrans = zeros(1, 11);
                  
                  measPresMean = [];
                  measChloroAStd = [];
                  measBackscatStd = [];
                  measCdomStd = [];
                  measChloroAMed = [];
                  measBackscatMed = [];
                  measCdomMed = [];
                  for idBin = 1:11
                     measPresMean = [measPresMean values(7*(idBin-1)+5)];
                     measChloroAStd = [measChloroAStd values(7*(idBin-1)+6)];
                     measBackscatStd = [measBackscatStd values(7*(idBin-1)+7)];
                     measCdomStd = [measCdomStd values(7*(idBin-1)+8)];
                     measChloroAMed = [measChloroAMed values(7*(idBin-1)+9)];
                     measBackscatMed = [measBackscatMed values(7*(idBin-1)+10)];
                     measCdomMed = [measCdomMed values(7*(idBin-1)+11)];
                  end
                  measDateTrans(1) = 1;
                  measDateTrans(find((measPresMean == 0) & (measChloroAStd == 0) & ...
                     (measBackscatStd == 0) & (measCdomStd == 0) & (measChloroAMed == 0) & ...
                     (measBackscatMed == 0) & (measCdomMed == 0))) = -1;
                  
                  o_dataECO3StdMedDate = [o_dataECO3StdMedDate; [cycleNum profNum phaseNum measDate]];
                  o_dataECO3StdMedDateTrans = [o_dataECO3StdMedDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                  o_dataECO3StdMedPresMean  = [o_dataECO3StdMedPresMean; [cycleNum profNum phaseNum measPresMean]];
                  o_dataECO3StdMedChloroAStd  = [o_dataECO3StdMedChloroAStd; [cycleNum profNum phaseNum measChloroAStd]];
                  o_dataECO3StdMedBackscatStd  = [o_dataECO3StdMedBackscatStd; [cycleNum profNum phaseNum measBackscatStd]];
                  o_dataECO3StdMedCdomStd  = [o_dataECO3StdMedCdomStd; [cycleNum profNum phaseNum measCdomStd]];
                  o_dataECO3StdMedChloroAMed  = [o_dataECO3StdMedChloroAMed; [cycleNum profNum phaseNum measChloroAMed]];
                  o_dataECO3StdMedBackscatMed  = [o_dataECO3StdMedBackscatMed; [cycleNum profNum phaseNum measBackscatMed]];
                  o_dataECO3StdMedCdomMed  = [o_dataECO3StdMedCdomMed; [cycleNum profNum phaseNum measCdomMed]];
                  
                  o_cyProfPhaseList = [o_cyProfPhaseList; ...
                     packType sensorDataType cycleNum profNum phaseNum sbdFileDate];
                  
               case {12, 14}
                  % OCR (mean & raw)
                  
                  if (~ismember(2, g_decArgo_sensorList))
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        sensorDataType, 2);
                     continue
                  end
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [16 8 8 32 repmat([16 32 32 32 32], 1, 7) 32];
                  % get item bits
                  values = get_bits(firstBit, tabNbBits, msgData);
                  
                  % decode and store data values
                  cycleNum = values(1);
                  profNum = values(2);
                  phaseNum = values(3);
                  
                  if (a_procLevel == 0)
                     g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                        sensorDataType cycleNum profNum phaseNum];
                     continue
                  end
                  
                  if (cycleNum ~= g_decArgo_cycleNum)
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        cycleNum, g_decArgo_cycleNum);
                     continue
                  end
                  
                  measDate = ones(1, 7)*g_decArgo_dateDef;
                  measDate(1) = epoch2000_2_julian(values(4));
                  measDateTrans = zeros(1, 7);
                  
                  measPres = [];
                  measIr1 = [];
                  measIr2 = [];
                  measIr3 = [];
                  measIr4 = [];
                  for idBin = 1:7
                     measPres = [measPres values(5*(idBin-1)+5)];
                     measIr1 = [measIr1 values(5*(idBin-1)+6)];
                     measIr2 = [measIr2 values(5*(idBin-1)+7)];
                     measIr3 = [measIr3 values(5*(idBin-1)+8)];
                     measIr4 = [measIr4 values(5*(idBin-1)+9)];
                  end
                  measDateTrans(1) = 1;
                  measDateTrans(find((measPres == 0) & (measIr1 == 0) & ...
                     (measIr2 == 0) & (measIr3 == 0) & (measIr4 == 0))) = -1;
                  
                  if (sensorDataType == 12)
                     o_dataOCRMeanDate = [o_dataOCRMeanDate; [cycleNum profNum phaseNum measDate]];
                     o_dataOCRMeanDateTrans = [o_dataOCRMeanDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                     o_dataOCRMeanPres = [o_dataOCRMeanPres; [cycleNum profNum phaseNum measPres]];
                     o_dataOCRMeanIr1 = [o_dataOCRMeanIr1; [cycleNum profNum phaseNum measIr1]];
                     o_dataOCRMeanIr2 = [o_dataOCRMeanIr2; [cycleNum profNum phaseNum measIr2]];
                     o_dataOCRMeanIr3 = [o_dataOCRMeanIr3; [cycleNum profNum phaseNum measIr3]];
                     o_dataOCRMeanIr4 = [o_dataOCRMeanIr4; [cycleNum profNum phaseNum measIr4]];
                  elseif (sensorDataType == 14)
                     o_dataOCRRawDate = [o_dataOCRRawDate; [cycleNum profNum phaseNum measDate]];
                     o_dataOCRRawDateTrans = [o_dataOCRRawDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                     o_dataOCRRawPres = [o_dataOCRRawPres; [cycleNum profNum phaseNum measPres]];
                     o_dataOCRRawIr1 = [o_dataOCRRawIr1; [cycleNum profNum phaseNum measIr1]];
                     o_dataOCRRawIr2 = [o_dataOCRRawIr2; [cycleNum profNum phaseNum measIr2]];
                     o_dataOCRRawIr3 = [o_dataOCRRawIr3; [cycleNum profNum phaseNum measIr3]];
                     o_dataOCRRawIr4 = [o_dataOCRRawIr4; [cycleNum profNum phaseNum measIr4]];
                  end
                  
                  o_cyProfPhaseList = [o_cyProfPhaseList; ...
                     packType sensorDataType cycleNum profNum phaseNum sbdFileDate];
                  
               case {13}
                  % OCR (stDev & median)
                  
                  if (~ismember(2, g_decArgo_sensorList))
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        sensorDataType, 2);
                     continue
                  end
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [16 8 8 32 repmat([16 32 32 32 32 32 32 32 32], 1, 3) 224];
                  % get item bits
                  values = get_bits(firstBit, tabNbBits, msgData);
                  
                  % decode and store data values
                  cycleNum = values(1);
                  profNum = values(2);
                  phaseNum = values(3);
                  
                  if (a_procLevel == 0)
                     g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                        sensorDataType cycleNum profNum phaseNum];
                     continue
                  end
                  
                  if (cycleNum ~= g_decArgo_cycleNum)
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        cycleNum, g_decArgo_cycleNum);
                     continue
                  end
                  
                  measDate = ones(1, 3)*g_decArgo_dateDef;
                  measDate(1) = epoch2000_2_julian(values(4));
                  measDateTrans = zeros(1, 3);
                  
                  measPresMean = [];
                  measIr1Std = [];
                  measIr2Std = [];
                  measIr3Std = [];
                  measIr4Std = [];
                  measIr1Med = [];
                  measIr2Med = [];
                  measIr3Med = [];
                  measIr4Med = [];
                  for idBin = 1:3
                     measPresMean = [measPresMean values(9*(idBin-1)+5)];
                     measIr1Std = [measIr1Std values(9*(idBin-1)+6)];
                     measIr2Std = [measIr2Std values(9*(idBin-1)+7)];
                     measIr3Std = [measIr3Std values(9*(idBin-1)+8)];
                     measIr4Std = [measIr4Std values(9*(idBin-1)+9)];
                     measIr1Med = [measIr1Med values(9*(idBin-1)+10)];
                     measIr2Med = [measIr2Med values(9*(idBin-1)+11)];
                     measIr3Med = [measIr3Med values(9*(idBin-1)+12)];
                     measIr4Med = [measIr4Med values(9*(idBin-1)+13)];
                  end
                  measDateTrans(1) = 1;
                  measDateTrans(find((measPresMean == 0) & (measIr1Std == 0) & ...
                     (measIr2Std == 0) & (measIr3Std == 0) & (measIr4Std == 0) & ...
                     (measIr1Med == 0) & (measIr2Med == 0) & (measIr3Med == 0) & (measIr4Med == 0))) = -1;
                  
                  o_dataOCRStdMedDate = [o_dataOCRStdMedDate; [cycleNum profNum phaseNum measDate]];
                  o_dataOCRStdMedDateTrans = [o_dataOCRStdMedDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                  o_dataOCRStdMedPresMean  = [o_dataOCRStdMedPresMean; [cycleNum profNum phaseNum measPresMean]];
                  o_dataOCRStdMedIr1Std  = [o_dataOCRStdMedIr1Std; [cycleNum profNum phaseNum measIr1Std]];
                  o_dataOCRStdMedIr2Std  = [o_dataOCRStdMedIr2Std; [cycleNum profNum phaseNum measIr2Std]];
                  o_dataOCRStdMedIr3Std  = [o_dataOCRStdMedIr3Std; [cycleNum profNum phaseNum measIr3Std]];
                  o_dataOCRStdMedIr4Std  = [o_dataOCRStdMedIr4Std; [cycleNum profNum phaseNum measIr4Std]];
                  o_dataOCRStdMedIr1Med  = [o_dataOCRStdMedIr1Med; [cycleNum profNum phaseNum measIr1Med]];
                  o_dataOCRStdMedIr2Med  = [o_dataOCRStdMedIr2Med; [cycleNum profNum phaseNum measIr2Med]];
                  o_dataOCRStdMedIr3Med  = [o_dataOCRStdMedIr3Med; [cycleNum profNum phaseNum measIr3Med]];
                  o_dataOCRStdMedIr4Med  = [o_dataOCRStdMedIr4Med; [cycleNum profNum phaseNum measIr4Med]];
                  
                  o_cyProfPhaseList = [o_cyProfPhaseList; ...
                     packType sensorDataType cycleNum profNum phaseNum sbdFileDate];
                  
               case {15, 17}
                  % FLNTU (mean & raw)
                  
                  if (~ismember(4, g_decArgo_sensorList))
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        sensorDataType, 4);
                     continue
                  end
                  
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
                  
                  if (a_procLevel == 0)
                     g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                        sensorDataType cycleNum profNum phaseNum];
                     continue
                  end
                  
                  if (cycleNum ~= g_decArgo_cycleNum)
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        cycleNum, g_decArgo_cycleNum);
                     continue
                  end
                  
                  measDate = ones(1, 21)*g_decArgo_dateDef;
                  measDate(1) = epoch2000_2_julian(values(4));
                  measDateTrans = zeros(1, 21);
                  
                  measPres = [];
                  measChloro = [];
                  measTurbi = [];
                  for idBin = 1:21
                     measPres = [measPres values(3*(idBin-1)+5)];
                     measChloro = [measChloro values(3*(idBin-1)+6)];
                     measTurbi = [measTurbi values(3*(idBin-1)+7)];
                  end
                  measDateTrans(1) = 1;
                  measDateTrans(find((measPres == 0) & (measChloro == 0) & (measTurbi == 0))) = -1;
                  
                  if (sensorDataType == 15)
                     o_dataFLNTUMeanDate = [o_dataFLNTUMeanDate; [cycleNum profNum phaseNum measDate]];
                     o_dataFLNTUMeanDateTrans = [o_dataFLNTUMeanDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                     o_dataFLNTUMeanPres = [o_dataFLNTUMeanPres; [cycleNum profNum phaseNum measPres]];
                     o_dataFLNTUMeanChloro = [o_dataFLNTUMeanChloro; [cycleNum profNum phaseNum measChloro]];
                     o_dataFLNTUMeanTurbi = [o_dataFLNTUMeanTurbi; [cycleNum profNum phaseNum measTurbi]];
                  elseif (sensorDataType == 17)
                     o_dataFLNTURawDate = [o_dataFLNTURawDate; [cycleNum profNum phaseNum measDate]];
                     o_dataFLNTURawDateTrans = [o_dataFLNTURawDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                     o_dataFLNTURawPres = [o_dataFLNTURawPres; [cycleNum profNum phaseNum measPres]];
                     o_dataFLNTURawChloro = [o_dataFLNTURawChloro; [cycleNum profNum phaseNum measChloro]];
                     o_dataFLNTURawTurbi = [o_dataFLNTURawTurbi; [cycleNum profNum phaseNum measTurbi]];
                  end
                  
                  o_cyProfPhaseList = [o_cyProfPhaseList; ...
                     packType sensorDataType cycleNum profNum phaseNum sbdFileDate];
                  
               case {16}
                  % FLNTU (stDev & median)
                  
                  if (~ismember(4, g_decArgo_sensorList))
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        sensorDataType, 4);
                     continue
                  end
                  
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
                  
                  if (a_procLevel == 0)
                     g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                        sensorDataType cycleNum profNum phaseNum];
                     continue
                  end
                  
                  if (cycleNum ~= g_decArgo_cycleNum)
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        cycleNum, g_decArgo_cycleNum);
                     continue
                  end
                  
                  measDate = ones(1, 16)*g_decArgo_dateDef;
                  measDate(1) = epoch2000_2_julian(values(4));
                  measDateTrans = zeros(1, 16);
                  
                  measPresMean = [];
                  measChloroStd = [];
                  measTurbiStd = [];
                  measChloroMed = [];
                  measTurbiMed = [];
                  for idBin = 1:16
                     measPresMean = [measPresMean values(5*(idBin-1)+5)];
                     measChloroStd = [measChloroStd values(5*(idBin-1)+6)];
                     measTurbiStd = [measTurbiStd values(5*(idBin-1)+7)];
                     measChloroMed = [measChloroMed values(5*(idBin-1)+8)];
                     measTurbiMed = [measTurbiMed values(5*(idBin-1)+9)];
                  end
                  measDateTrans(1) = 1;
                  measDateTrans(find((measPresMean == 0) & (measChloroStd == 0) & ...
                     (measTurbiStd == 0) & (measChloroMed == 0) & (measTurbiMed == 0))) = -1;
                  
                  o_dataFLNTUStdMedDate = [o_dataFLNTUStdMedDate; [cycleNum profNum phaseNum measDate]];
                  o_dataFLNTUStdMedDateTrans = [o_dataFLNTUStdMedDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                  o_dataFLNTUStdMedPresMean  = [o_dataFLNTUStdMedPresMean; [cycleNum profNum phaseNum measPresMean]];
                  o_dataFLNTUStdMedChloroStd  = [o_dataFLNTUStdMedChloroStd; [cycleNum profNum phaseNum measChloroStd]];
                  o_dataFLNTUStdMedTurbiStd  = [o_dataFLNTUStdMedTurbiStd; [cycleNum profNum phaseNum measTurbiStd]];
                  o_dataFLNTUStdMedChloroMed  = [o_dataFLNTUStdMedChloroMed; [cycleNum profNum phaseNum measChloroMed]];
                  o_dataFLNTUStdMedTurbiMed  = [o_dataFLNTUStdMedTurbiMed; [cycleNum profNum phaseNum measTurbiMed]];
                  
                  o_cyProfPhaseList = [o_cyProfPhaseList; ...
                     packType sensorDataType cycleNum profNum phaseNum sbdFileDate];
                  
               case {18, 20}
                  % cROVER (mean & raw)
                  
                  if (~ismember(5, g_decArgo_sensorList))
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        sensorDataType, 5);
                     continue
                  end
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [16 8 8 32 repmat([16 32], 1, 21) 32];
                  % get item bits
                  values = get_bits(firstBit, tabNbBits, msgData);
                  
                  % decode and store data values
                  cycleNum = values(1);
                  profNum = values(2);
                  phaseNum = values(3);
                  
                  if (a_procLevel == 0)
                     g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                        sensorDataType cycleNum profNum phaseNum];
                     continue
                  end
                  
                  if (cycleNum ~= g_decArgo_cycleNum)
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        cycleNum, g_decArgo_cycleNum);
                     continue
                  end
                  
                  measDate = ones(1, 21)*g_decArgo_dateDef;
                  measDate(1) = epoch2000_2_julian(values(4));
                  measDateTrans = zeros(1, 21);
                  
                  measPres = [];
                  measCoefAtt = [];
                  for idBin = 1:21
                     measPres = [measPres values(2*(idBin-1)+5)];
                     measCoefAtt = [measCoefAtt twos_complement_dec_argo(values(2*(idBin-1)+6), 32)];
                  end
                  measDateTrans(1) = 1;
                  measDateTrans(find((measPres == 0) & (measCoefAtt == 0))) = -1;
                  
                  if (sensorDataType == 18)
                     o_dataCROVERMeanDate = [o_dataCROVERMeanDate; [cycleNum profNum phaseNum measDate]];
                     o_dataCROVERMeanDateTrans = [o_dataCROVERMeanDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                     o_dataCROVERMeanPres = [o_dataCROVERMeanPres; [cycleNum profNum phaseNum measPres]];
                     o_dataCROVERMeanCoefAtt = [o_dataCROVERMeanCoefAtt; [cycleNum profNum phaseNum measCoefAtt]];
                  elseif (sensorDataType == 20)
                     o_dataCROVERRawDate = [o_dataCROVERRawDate; [cycleNum profNum phaseNum measDate]];
                     o_dataCROVERRawDateTrans = [o_dataCROVERRawDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                     o_dataCROVERRawPres = [o_dataCROVERRawPres; [cycleNum profNum phaseNum measPres]];
                     o_dataCROVERRawCoefAtt = [o_dataCROVERRawCoefAtt; [cycleNum profNum phaseNum measCoefAtt]];
                  end
                  
                  o_cyProfPhaseList = [o_cyProfPhaseList; ...
                     packType sensorDataType cycleNum profNum phaseNum sbdFileDate];
                  
               case {19}
                  % cRover (stDev & median)
                  
                  if (~ismember(5, g_decArgo_sensorList))
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        sensorDataType, 5);
                     continue
                  end
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [16 8 8 32 repmat([16 16 32], 1, 16) 16];
                  % get item bits
                  values = get_bits(firstBit, tabNbBits, msgData);
                  
                  % decode and store data values
                  cycleNum = values(1);
                  profNum = values(2);
                  phaseNum = values(3);
                  
                  if (a_procLevel == 0)
                     g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                        sensorDataType cycleNum profNum phaseNum];
                     continue
                  end
                  
                  if (cycleNum ~= g_decArgo_cycleNum)
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        cycleNum, g_decArgo_cycleNum);
                     continue
                  end
                  
                  measDate = ones(1, 16)*g_decArgo_dateDef;
                  measDate(1) = epoch2000_2_julian(values(4));
                  measDateTrans = zeros(1, 16);
                  
                  measPresMean = [];
                  measCoefAttStd = [];
                  measCoefAttMed = [];
                  for idBin = 1:16
                     measPresMean = [measPresMean values(3*(idBin-1)+5)];
                     measCoefAttStd = [measCoefAttStd values(3*(idBin-1)+6)];
                     measCoefAttMed = [measCoefAttMed twos_complement_dec_argo(values(3*(idBin-1)+7), 32)];
                  end
                  measDateTrans(1) = 1;
                  measDateTrans(find((measPresMean == 0) & (measCoefAttStd == 0) & (measCoefAttMed == 0))) = -1;
                  
                  o_dataCROVERStdMedDate = [o_dataCROVERStdMedDate; [cycleNum profNum phaseNum measDate]];
                  o_dataCROVERStdMedDateTrans = [o_dataCROVERStdMedDate; [cycleNum profNum phaseNum measDateTrans]];
                  o_dataCROVERStdMedPresMean  = [o_dataCROVERStdMedPresMean; [cycleNum profNum phaseNum measPresMean]];
                  o_dataCROVERStdMedCoefAttStd  = [o_dataCROVERStdMedCoefAttStd; [cycleNum profNum phaseNum measCoefAttStd]];
                  o_dataCROVERStdMedCoefAttMed  = [o_dataCROVERStdMedCoefAttMed; [cycleNum profNum phaseNum measCoefAttMed]];
                  
                  o_cyProfPhaseList = [o_cyProfPhaseList; ...
                     packType sensorDataType cycleNum profNum phaseNum sbdFileDate];
                  
               case {21, 23}
                  % SUNA (mean & raw)
                  
                  if (~ismember(6, g_decArgo_sensorList))
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        sensorDataType, 6);
                     continue
                  end
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [16 8 8 32 repmat([16 32], 1, 21) 32];
                  % get item bits
                  values = get_bits(firstBit, tabNbBits, msgData);
                  
                  % decode and store data values
                  cycleNum = values(1);
                  profNum = values(2);
                  phaseNum = values(3);
                  
                  if (a_procLevel == 0)
                     g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                        sensorDataType cycleNum profNum phaseNum];
                     continue
                  end
                  
                  if (cycleNum ~= g_decArgo_cycleNum)
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        cycleNum, g_decArgo_cycleNum);
                     continue
                  end
                  
                  measDate = ones(1, 21)*g_decArgo_dateDef;
                  measDate(1) = epoch2000_2_julian(values(4));
                  measDateTrans = zeros(1, 21);
                  
                  measPres = [];
                  measConcNitra = [];
                  for idBin = 1:21
                     measPres = [measPres values(2*(idBin-1)+5)];
                     measConcNitra = [measConcNitra double(typecast(uint32(values(2*(idBin-1)+6)), 'single'))];
                  end
                  measDateTrans(1) = 1;
                  measDateTrans(find((measPres == 0) & (measConcNitra == 0))) = -1;
                  
                  if (sensorDataType == 21)
                     o_dataSUNAMeanDate = [o_dataSUNAMeanDate; [cycleNum profNum phaseNum measDate]];
                     o_dataSUNAMeanDateTrans = [o_dataSUNAMeanDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                     o_dataSUNAMeanPres = [o_dataSUNAMeanPres; [cycleNum profNum phaseNum measPres]];
                     o_dataSUNAMeanConcNitra = [o_dataSUNAMeanConcNitra; [cycleNum profNum phaseNum measConcNitra]];
                  elseif (sensorDataType == 23)
                     o_dataSUNARawDate = [o_dataSUNARawDate; [cycleNum profNum phaseNum measDate]];
                     o_dataSUNARawDateTrans = [o_dataSUNARawDate; [cycleNum profNum phaseNum measDateTrans]];
                     o_dataSUNARawPres = [o_dataSUNARawPres; [cycleNum profNum phaseNum measPres]];
                     o_dataSUNARawConcNitra = [o_dataSUNARawConcNitra; [cycleNum profNum phaseNum measConcNitra]];
                  end
                  
                  o_cyProfPhaseList = [o_cyProfPhaseList; ...
                     packType sensorDataType cycleNum profNum phaseNum sbdFileDate];
                  
               case {22}
                  % SUNA (stDev & median)
                  
                  if (~ismember(6, g_decArgo_sensorList))
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        sensorDataType, 6);
                     continue
                  end
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [16 8 8 32 repmat([16 16 32], 1, 16) 16];
                  % get item bits
                  values = get_bits(firstBit, tabNbBits, msgData);
                  
                  % decode and store data values
                  cycleNum = values(1);
                  profNum = values(2);
                  phaseNum = values(3);
                  
                  if (a_procLevel == 0)
                     g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                        sensorDataType cycleNum profNum phaseNum];
                     continue
                  end
                  
                  if (cycleNum ~= g_decArgo_cycleNum)
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        cycleNum, g_decArgo_cycleNum);
                     continue
                  end
                  
                  measDate = ones(1, 16)*g_decArgo_dateDef;
                  measDate(1) = epoch2000_2_julian(values(4));
                  measDateTrans = zeros(1, 16);
                  
                  measPresMean = [];
                  measConcNitraStd = [];
                  measConcNitraMed = [];
                  for idBin = 1:16
                     measPresMean = [measPresMean values(3*(idBin-1)+5)];
                     measConcNitraStd = [measConcNitraStd values(3*(idBin-1)+6)];
                     measConcNitraMed = [measConcNitraMed double(typecast(uint32(values(3*(idBin-1)+7)), 'single'))];
                  end
                  measDateTrans(1) = 1;
                  measDateTrans(find((measPresMean == 0) & (measConcNitraStd == 0) & (measConcNitraMed == 0))) = -1;
                  
                  o_dataSUNAStdMedDate = [o_dataSUNAStdMedDate; [cycleNum profNum phaseNum measDate]];
                  o_dataSUNAStdMedDateTrans = [o_dataSUNAStdMedDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                  o_dataSUNAStdMedPresMean  = [o_dataSUNAStdMedPresMean; [cycleNum profNum phaseNum measPresMean]];
                  o_dataSUNAStdMedConcNitraStd  = [o_dataSUNAStdMedConcNitraStd; [cycleNum profNum phaseNum measConcNitraStd]];
                  o_dataSUNAStdMedConcNitraMed  = [o_dataSUNAStdMedConcNitraMed; [cycleNum profNum phaseNum measConcNitraMed]];
                  
                  o_cyProfPhaseList = [o_cyProfPhaseList; ...
                     packType sensorDataType cycleNum profNum phaseNum sbdFileDate];
                  
               case {24, 25}
                  % SUNA (APF)
                  
                  if (~ismember(6, g_decArgo_sensorList))
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        sensorDataType, 6);
                     continue
                  end
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [16 8 8 32 repmat([32], 1, 10) repmat([16], 1, 45)];
                  % get item bits
                  values = get_bits(firstBit, tabNbBits, msgData);
                  
                  % decode and store data values
                  cycleNum = values(1);
                  profNum = values(2);
                  phaseNum = values(3);
                  
                  if (a_procLevel == 0)
                     g_decArgo_0TypeReceivedData = [g_decArgo_0TypeReceivedData; ...
                        sensorDataType cycleNum profNum phaseNum];
                     continue
                  end
                  
                  if (cycleNum ~= g_decArgo_cycleNum)
                     fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) => ignoring packet data\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        cycleNum, g_decArgo_cycleNum);
                     continue
                  end
                  
                  dataSUNAAPFDate = [cycleNum profNum phaseNum epoch2000_2_julian(values(4))];
                  dataSUNAAPFDateTrans = [cycleNum profNum phaseNum 1];
                  dataSUNAAPFCTDPres = [cycleNum profNum phaseNum double(typecast(uint32(values(5)), 'single'))];
                  dataSUNAAPFCTDTemp = [cycleNum profNum phaseNum double(typecast(uint32(values(6)), 'single'))];
                  dataSUNAAPFCTDSal = [cycleNum profNum phaseNum double(typecast(uint32(values(7)), 'single'))];
                  dataSUNAAPFIntTemp = [cycleNum profNum phaseNum double(typecast(uint32(values(8)), 'single'))];
                  dataSUNAAPFSpecTemp = [cycleNum profNum phaseNum double(typecast(uint32(values(9)), 'single'))];
                  dataSUNAAPFIntRelHumidity = [cycleNum profNum phaseNum double(typecast(uint32(values(10)), 'single'))];
                  dataSUNAAPFDarkSpecMean = [cycleNum profNum phaseNum double(typecast(uint32(values(11)), 'single'))];
                  dataSUNAAPFDarkSpecStd = [cycleNum profNum phaseNum double(typecast(uint32(values(12)), 'single'))];
                  dataSUNAAPFSensorNitra = [cycleNum profNum phaseNum double(typecast(uint32(values(13)), 'single'))];
                  dataSUNAAPFAbsFitRes = [cycleNum profNum phaseNum double(typecast(uint32(values(14)), 'single'))];
                  
                  measOutSpec = [];
                  for idBin = 1:45
                     measOutSpec = [measOutSpec values((idBin-1)+15)];
                  end
                  dataSUNAAPFOutSpec = [cycleNum profNum phaseNum measOutSpec];
                  
                  if (sensorDataType == 24)
                     o_dataSUNAAPFDate = [o_dataSUNAAPFDate; dataSUNAAPFDate];
                     o_dataSUNAAPFDateTrans = [o_dataSUNAAPFDateTrans; dataSUNAAPFDateTrans];
                     o_dataSUNAAPFCTDPres = [o_dataSUNAAPFCTDPres; dataSUNAAPFCTDPres];
                     o_dataSUNAAPFCTDTemp = [o_dataSUNAAPFCTDTemp; dataSUNAAPFCTDTemp];
                     o_dataSUNAAPFCTDSal = [o_dataSUNAAPFCTDSal; dataSUNAAPFCTDSal];
                     o_dataSUNAAPFIntTemp = [o_dataSUNAAPFIntTemp; dataSUNAAPFIntTemp];
                     o_dataSUNAAPFSpecTemp = [o_dataSUNAAPFSpecTemp; dataSUNAAPFSpecTemp];
                     o_dataSUNAAPFIntRelHumidity = [o_dataSUNAAPFIntRelHumidity; dataSUNAAPFIntRelHumidity];
                     o_dataSUNAAPFDarkSpecMean = [o_dataSUNAAPFDarkSpecMean; dataSUNAAPFDarkSpecMean];
                     o_dataSUNAAPFDarkSpecStd = [o_dataSUNAAPFDarkSpecStd; dataSUNAAPFDarkSpecStd];
                     o_dataSUNAAPFSensorNitra = [o_dataSUNAAPFSensorNitra; dataSUNAAPFSensorNitra];
                     o_dataSUNAAPFAbsFitRes = [o_dataSUNAAPFAbsFitRes; dataSUNAAPFAbsFitRes];
                     o_dataSUNAAPFOutSpec = [o_dataSUNAAPFOutSpec; dataSUNAAPFOutSpec];
                  else
                     o_dataSUNAAPF2Date = [o_dataSUNAAPF2Date; dataSUNAAPFDate];
                     o_dataSUNAAPF2DateTrans = [o_dataSUNAAPF2DateTrans; dataSUNAAPFDateTrans];
                     o_dataSUNAAPF2CTDPres = [o_dataSUNAAPF2CTDPres; dataSUNAAPFCTDPres];
                     o_dataSUNAAPF2CTDTemp = [o_dataSUNAAPF2CTDTemp; dataSUNAAPFCTDTemp];
                     o_dataSUNAAPF2CTDSal = [o_dataSUNAAPF2CTDSal; dataSUNAAPFCTDSal];
                     o_dataSUNAAPF2IntTemp = [o_dataSUNAAPF2IntTemp; dataSUNAAPFIntTemp];
                     o_dataSUNAAPF2SpecTemp = [o_dataSUNAAPF2SpecTemp; dataSUNAAPFSpecTemp];
                     o_dataSUNAAPF2IntRelHumidity = [o_dataSUNAAPF2IntRelHumidity; dataSUNAAPFIntRelHumidity];
                     o_dataSUNAAPF2DarkSpecMean = [o_dataSUNAAPF2DarkSpecMean; dataSUNAAPFDarkSpecMean];
                     o_dataSUNAAPF2DarkSpecStd = [o_dataSUNAAPF2DarkSpecStd; dataSUNAAPFDarkSpecStd];
                     o_dataSUNAAPF2SensorNitra = [o_dataSUNAAPF2SensorNitra; dataSUNAAPFSensorNitra];
                     o_dataSUNAAPF2AbsFitRes = [o_dataSUNAAPF2AbsFitRes; dataSUNAAPFAbsFitRes];
                     o_dataSUNAAPF2OutSpec = [o_dataSUNAAPF2OutSpec; dataSUNAAPFOutSpec];
                  end
                  
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
            
            % sensor type
            sensorType = tabSensors(idMes, 2);

            if (~ismember(sensorType, g_decArgo_sensorList))
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor TECH packet received (for sensor #%d which is not mounted on the float) => ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  sensorType);
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
            
            if (a_procLevel == 0)
               g_decArgo_250TypeReceivedData = [g_decArgo_250TypeReceivedData; ...
                  sensorType cycleNum profNum nbPackDesc nbPackDrift nbPackAsc];
               continue
            end
            
            if (cycleNum ~= g_decArgo_cycleNum)
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) => ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  cycleNum, g_decArgo_cycleNum);
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
                  
               case 2
                  % OCR
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [16 repmat([32], 1, 12)];
                  % get item bits
                  values = get_bits(firstBit, tabNbBits, msgData);
                  
                  % decode and store data values
                  measSensorSerialNum = swapbytes(uint16(values(1)));
                  measCoefLambda1A0 = typecast(uint32(swapbytes(uint32(values(2)))), 'single');
                  measCoefLambda1A1 = typecast(uint32(swapbytes(uint32(values(3)))), 'single');
                  measCoefLambda1Lm = typecast(uint32(swapbytes(uint32(values(4)))), 'single');
                  measCoefLambda2A0 = typecast(uint32(swapbytes(uint32(values(5)))), 'single');
                  measCoefLambda2A1 = typecast(uint32(swapbytes(uint32(values(6)))), 'single');
                  measCoefLambda2Lm = typecast(uint32(swapbytes(uint32(values(7)))), 'single');
                  measCoefLambda3A0 = typecast(uint32(swapbytes(uint32(values(8)))), 'single');
                  measCoefLambda3A1 = typecast(uint32(swapbytes(uint32(values(9)))), 'single');
                  measCoefLambda3Lm = typecast(uint32(swapbytes(uint32(values(10)))), 'single');
                  measCoefParA0 = typecast(uint32(swapbytes(uint32(values(11)))), 'single');
                  measCoefParA1 = typecast(uint32(swapbytes(uint32(values(12)))), 'single');
                  measCoefParLm = typecast(uint32(swapbytes(uint32(values(13)))), 'single');
                  
                  o_sensorTechOCRNbPackDesc = [o_sensorTechOCRNbPackDesc; cycleNum profNum nbPackDesc];
                  o_sensorTechOCRNbPackDrift = [o_sensorTechOCRNbPackDrift; cycleNum profNum nbPackDrift];
                  o_sensorTechOCRNbPackAsc = [o_sensorTechOCRNbPackAsc; cycleNum profNum nbPackAsc];
                  o_sensorTechOCRNbMeasDescZ1 = [o_sensorTechOCRNbMeasDescZ1; cycleNum profNum nbMeasDescZ1];
                  o_sensorTechOCRNbMeasDescZ2 = [o_sensorTechOCRNbMeasDescZ2; cycleNum profNum nbMeasDescZ2];
                  o_sensorTechOCRNbMeasDescZ3 = [o_sensorTechOCRNbMeasDescZ3; cycleNum profNum nbMeasDescZ3];
                  o_sensorTechOCRNbMeasDescZ4 = [o_sensorTechOCRNbMeasDescZ4; cycleNum profNum nbMeasDescZ4];
                  o_sensorTechOCRNbMeasDescZ5 = [o_sensorTechOCRNbMeasDescZ5; cycleNum profNum nbMeasDescZ5];
                  o_sensorTechOCRNbMeasDrift = [o_sensorTechOCRNbMeasDrift; cycleNum profNum nbMeasDrift];
                  o_sensorTechOCRNbMeasAscZ1 = [o_sensorTechOCRNbMeasAscZ1; cycleNum profNum nbMeasAscZ1];
                  o_sensorTechOCRNbMeasAscZ2 = [o_sensorTechOCRNbMeasAscZ2; cycleNum profNum nbMeasAscZ2];
                  o_sensorTechOCRNbMeasAscZ3 = [o_sensorTechOCRNbMeasAscZ3; cycleNum profNum nbMeasAscZ3];
                  o_sensorTechOCRNbMeasAscZ4 = [o_sensorTechOCRNbMeasAscZ4; cycleNum profNum nbMeasAscZ4];
                  o_sensorTechOCRNbMeasAscZ5 = [o_sensorTechOCRNbMeasAscZ5; cycleNum profNum nbMeasAscZ5];
                  o_sensorTechOCRSensorState = [o_sensorTechOCRSensorState; cycleNum profNum sensorState];
                  o_sensorTechOCRSensorSerialNum = [o_sensorTechOCRSensorSerialNum; cycleNum profNum measSensorSerialNum];
                  o_sensorTechOCRCoefLambda1A0 = [o_sensorTechOCRCoefLambda1A0; cycleNum profNum measCoefLambda1A0];
                  o_sensorTechOCRCoefLambda1A1 = [o_sensorTechOCRCoefLambda1A1; cycleNum profNum measCoefLambda1A1];
                  o_sensorTechOCRCoefLambda1Lm = [o_sensorTechOCRCoefLambda1Lm; cycleNum profNum measCoefLambda1Lm];
                  o_sensorTechOCRCoefLambda2A0 = [o_sensorTechOCRCoefLambda2A0; cycleNum profNum measCoefLambda2A0];
                  o_sensorTechOCRCoefLambda2A1 = [o_sensorTechOCRCoefLambda2A1; cycleNum profNum measCoefLambda2A1];
                  o_sensorTechOCRCoefLambda2Lm = [o_sensorTechOCRCoefLambda2Lm; cycleNum profNum measCoefLambda2Lm];
                  o_sensorTechOCRCoefLambda3A0 = [o_sensorTechOCRCoefLambda3A0; cycleNum profNum measCoefLambda3A0];
                  o_sensorTechOCRCoefLambda3A1 = [o_sensorTechOCRCoefLambda3A1; cycleNum profNum measCoefLambda3A1];
                  o_sensorTechOCRCoefLambda3Lm = [o_sensorTechOCRCoefLambda3Lm; cycleNum profNum measCoefLambda3Lm];
                  o_sensorTechOCRCoefParA0 = [o_sensorTechOCRCoefParA0; cycleNum profNum measCoefParA0];
                  o_sensorTechOCRCoefParA1 = [o_sensorTechOCRCoefParA1; cycleNum profNum measCoefParA1];
                  o_sensorTechOCRCoefParLm = [o_sensorTechOCRCoefParLm; cycleNum profNum measCoefParLm];
                  
               case 3
                  % ECO3
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [16 repmat([32 16], 1, 3) 240];
                  % get item bits
                  values = get_bits(firstBit, tabNbBits, msgData);
                  
                  % decode and store data values
                  measSensorSerialNum = swapbytes(uint16(values(1)));
                  measCoefScaleFactChloroA = typecast(uint32(swapbytes(uint32(values(2)))), 'single');
                  measCoefDarkCountChloroA = swapbytes(uint16(values(3)));
                  measCoefScaleFactBackscat = typecast(uint32(swapbytes(uint32(values(4)))), 'single');
                  measCoefDarkCountBackscat = swapbytes(uint16(values(5)));
                  measCoefScaleFactCdom = typecast(uint32(swapbytes(uint32(values(6)))), 'single');
                  measCoefDarkCountCdom = swapbytes(uint16(values(7)));
                  
                  o_sensorTechECO3NbPackDesc = [o_sensorTechECO3NbPackDesc; cycleNum profNum nbPackDesc];
                  o_sensorTechECO3NbPackDrift = [o_sensorTechECO3NbPackDrift; cycleNum profNum nbPackDrift];
                  o_sensorTechECO3NbPackAsc = [o_sensorTechECO3NbPackAsc; cycleNum profNum nbPackAsc];
                  o_sensorTechECO3NbMeasDescZ1 = [o_sensorTechECO3NbMeasDescZ1; cycleNum profNum nbMeasDescZ1];
                  o_sensorTechECO3NbMeasDescZ2 = [o_sensorTechECO3NbMeasDescZ2; cycleNum profNum nbMeasDescZ2];
                  o_sensorTechECO3NbMeasDescZ3 = [o_sensorTechECO3NbMeasDescZ3; cycleNum profNum nbMeasDescZ3];
                  o_sensorTechECO3NbMeasDescZ4 = [o_sensorTechECO3NbMeasDescZ4; cycleNum profNum nbMeasDescZ4];
                  o_sensorTechECO3NbMeasDescZ5 = [o_sensorTechECO3NbMeasDescZ5; cycleNum profNum nbMeasDescZ5];
                  o_sensorTechECO3NbMeasDrift = [o_sensorTechECO3NbMeasDrift; cycleNum profNum nbMeasDrift];
                  o_sensorTechECO3NbMeasAscZ1 = [o_sensorTechECO3NbMeasAscZ1; cycleNum profNum nbMeasAscZ1];
                  o_sensorTechECO3NbMeasAscZ2 = [o_sensorTechECO3NbMeasAscZ2; cycleNum profNum nbMeasAscZ2];
                  o_sensorTechECO3NbMeasAscZ3 = [o_sensorTechECO3NbMeasAscZ3; cycleNum profNum nbMeasAscZ3];
                  o_sensorTechECO3NbMeasAscZ4 = [o_sensorTechECO3NbMeasAscZ4; cycleNum profNum nbMeasAscZ4];
                  o_sensorTechECO3NbMeasAscZ5 = [o_sensorTechECO3NbMeasAscZ5; cycleNum profNum nbMeasAscZ5];
                  o_sensorTechECO3SensorState = [o_sensorTechECO3SensorState; cycleNum profNum sensorState];
                  o_sensorTechECO3SensorSerialNum = [o_sensorTechECO3SensorSerialNum; cycleNum profNum measSensorSerialNum];
                  o_sensorTechECO3CoefScaleFactChloroA = [o_sensorTechECO3CoefScaleFactChloroA; cycleNum profNum measCoefScaleFactChloroA];
                  o_sensorTechECO3CoefDarkCountChloroA = [o_sensorTechECO3CoefDarkCountChloroA; cycleNum profNum measCoefDarkCountChloroA];
                  o_sensorTechECO3CoefScaleFactBackscat = [o_sensorTechECO3CoefScaleFactBackscat; cycleNum profNum measCoefScaleFactBackscat];
                  o_sensorTechECO3CoefDarkCountBackscat = [o_sensorTechECO3CoefDarkCountBackscat; cycleNum profNum measCoefDarkCountBackscat];
                  o_sensorTechECO3CoefScaleFactCdom = [o_sensorTechECO3CoefScaleFactCdom; cycleNum profNum measCoefScaleFactCdom];
                  o_sensorTechECO3CoefDarkCountCdom = [o_sensorTechECO3CoefDarkCountCdom; cycleNum profNum measCoefDarkCountCdom];
                  
               case 4
                  % FLNTU
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [repmat([32 16], 1, 2) 304];
                  % get item bits
                  values = get_bits(firstBit, tabNbBits, msgData);
                  
                  % decode and store data values
                  measCoefScaleChloro = typecast(uint32(swapbytes(uint32(values(1)))), 'single');
                  measDarkCountChloro = swapbytes(uint16(values(2)));
                  measCoefScaleTurbi = typecast(uint32(swapbytes(uint32(values(3)))), 'single');
                  measDarkCountTurbi = swapbytes(uint16(values(4)));
                  
                  o_sensorTechFLNTUNbPackDesc = [o_sensorTechFLNTUNbPackDesc; cycleNum profNum nbPackDesc];
                  o_sensorTechFLNTUNbPackDrift = [o_sensorTechFLNTUNbPackDrift; cycleNum profNum nbPackDrift];
                  o_sensorTechFLNTUNbPackAsc = [o_sensorTechFLNTUNbPackAsc; cycleNum profNum nbPackAsc];
                  o_sensorTechFLNTUNbMeasDescZ1 = [o_sensorTechFLNTUNbMeasDescZ1; cycleNum profNum nbMeasDescZ1];
                  o_sensorTechFLNTUNbMeasDescZ2 = [o_sensorTechFLNTUNbMeasDescZ2; cycleNum profNum nbMeasDescZ2];
                  o_sensorTechFLNTUNbMeasDescZ3 = [o_sensorTechFLNTUNbMeasDescZ3; cycleNum profNum nbMeasDescZ3];
                  o_sensorTechFLNTUNbMeasDescZ4 = [o_sensorTechFLNTUNbMeasDescZ4; cycleNum profNum nbMeasDescZ4];
                  o_sensorTechFLNTUNbMeasDescZ5 = [o_sensorTechFLNTUNbMeasDescZ5; cycleNum profNum nbMeasDescZ5];
                  o_sensorTechFLNTUNbMeasDrift = [o_sensorTechFLNTUNbMeasDrift; cycleNum profNum nbMeasDrift];
                  o_sensorTechFLNTUNbMeasAscZ1 = [o_sensorTechFLNTUNbMeasAscZ1; cycleNum profNum nbMeasAscZ1];
                  o_sensorTechFLNTUNbMeasAscZ2 = [o_sensorTechFLNTUNbMeasAscZ2; cycleNum profNum nbMeasAscZ2];
                  o_sensorTechFLNTUNbMeasAscZ3 = [o_sensorTechFLNTUNbMeasAscZ3; cycleNum profNum nbMeasAscZ3];
                  o_sensorTechFLNTUNbMeasAscZ4 = [o_sensorTechFLNTUNbMeasAscZ4; cycleNum profNum nbMeasAscZ4];
                  o_sensorTechFLNTUNbMeasAscZ5 = [o_sensorTechFLNTUNbMeasAscZ5; cycleNum profNum nbMeasAscZ5];
                  o_sensorTechFLNTUSensorState = [o_sensorTechFLNTUSensorState; cycleNum profNum sensorState];
                  o_sensorTechFLNTUCoefScaleChloro = [o_sensorTechFLNTUCoefScaleChloro; cycleNum profNum measCoefScaleChloro];
                  o_sensorTechFLNTUDarkCountChloro = [o_sensorTechFLNTUDarkCountChloro; cycleNum profNum measDarkCountChloro];
                  o_sensorTechFLNTUCoefScaleTurbi = [o_sensorTechFLNTUCoefScaleTurbi; cycleNum profNum measCoefScaleTurbi];
                  o_sensorTechFLNTUDarkCountTurbi = [o_sensorTechFLNTUDarkCountTurbi; cycleNum profNum measDarkCountTurbi];
                  
               case 5
                  % CROVER
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [16 384];
                  % get item bits
                  values = get_bits(firstBit, tabNbBits, msgData);
                  
                  % decode and store data values
                  measSensorSerialNum = swapbytes(uint16(values(1)));
                  
                  o_sensorTechCROVERNbPackDesc = [o_sensorTechCROVERNbPackDesc; cycleNum profNum nbPackDesc];
                  o_sensorTechCROVERNbPackDrift = [o_sensorTechCROVERNbPackDrift; cycleNum profNum nbPackDrift];
                  o_sensorTechCROVERNbPackAsc = [o_sensorTechCROVERNbPackAsc; cycleNum profNum nbPackAsc];
                  o_sensorTechCROVERNbMeasDescZ1 = [o_sensorTechCROVERNbMeasDescZ1; cycleNum profNum nbMeasDescZ1];
                  o_sensorTechCROVERNbMeasDescZ2 = [o_sensorTechCROVERNbMeasDescZ2; cycleNum profNum nbMeasDescZ2];
                  o_sensorTechCROVERNbMeasDescZ3 = [o_sensorTechCROVERNbMeasDescZ3; cycleNum profNum nbMeasDescZ3];
                  o_sensorTechCROVERNbMeasDescZ4 = [o_sensorTechCROVERNbMeasDescZ4; cycleNum profNum nbMeasDescZ4];
                  o_sensorTechCROVERNbMeasDescZ5 = [o_sensorTechCROVERNbMeasDescZ5; cycleNum profNum nbMeasDescZ5];
                  o_sensorTechCROVERNbMeasDrift = [o_sensorTechCROVERNbMeasDrift; cycleNum profNum nbMeasDrift];
                  o_sensorTechCROVERNbMeasAscZ1 = [o_sensorTechCROVERNbMeasAscZ1; cycleNum profNum nbMeasAscZ1];
                  o_sensorTechCROVERNbMeasAscZ2 = [o_sensorTechCROVERNbMeasAscZ2; cycleNum profNum nbMeasAscZ2];
                  o_sensorTechCROVERNbMeasAscZ3 = [o_sensorTechCROVERNbMeasAscZ3; cycleNum profNum nbMeasAscZ3];
                  o_sensorTechCROVERNbMeasAscZ4 = [o_sensorTechCROVERNbMeasAscZ4; cycleNum profNum nbMeasAscZ4];
                  o_sensorTechCROVERNbMeasAscZ5 = [o_sensorTechCROVERNbMeasAscZ5; cycleNum profNum nbMeasAscZ5];
                  o_sensorTechCROVERSensorState = [o_sensorTechCROVERSensorState; cycleNum profNum sensorState];
                  o_sensorTechCROVERSensorSerialNum = [o_sensorTechCROVERSensorSerialNum; cycleNum profNum measSensorSerialNum];
                  
               case 6
                  % SUNA
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [16 repmat([32], 1, 5) 16 16 192];
                  % get item bits
                  values = get_bits(firstBit, tabNbBits, msgData);
                  
                  % decode and store data values
                  measSensorSerialNum = swapbytes(uint16(values(1)));
                  measSampCounter = swapbytes(uint32(values(2)));
                  measPowerCycleCounter = swapbytes(uint32(values(3)));
                  measErrorCounter = swapbytes(uint32(values(4)));
                  measSupplyVoltage = typecast(uint32(swapbytes(uint32(values(5)))), 'single');
                  measSupplyCurrent = typecast(uint32(swapbytes(uint32(values(6)))), 'single');
                  measOutPixelBegin = swapbytes(uint16(values(7)));
                  measOutPixelEnd = swapbytes(uint16(values(8)));
                  
                  o_sensorTechSUNANbPackDesc = [o_sensorTechSUNANbPackDesc; cycleNum profNum nbPackDesc];
                  o_sensorTechSUNANbPackDrift = [o_sensorTechSUNANbPackDrift; cycleNum profNum nbPackDrift];
                  o_sensorTechSUNANbPackAsc = [o_sensorTechSUNANbPackAsc; cycleNum profNum nbPackAsc];
                  o_sensorTechSUNANbMeasDescZ1 = [o_sensorTechSUNANbMeasDescZ1; cycleNum profNum nbMeasDescZ1];
                  o_sensorTechSUNANbMeasDescZ2 = [o_sensorTechSUNANbMeasDescZ2; cycleNum profNum nbMeasDescZ2];
                  o_sensorTechSUNANbMeasDescZ3 = [o_sensorTechSUNANbMeasDescZ3; cycleNum profNum nbMeasDescZ3];
                  o_sensorTechSUNANbMeasDescZ4 = [o_sensorTechSUNANbMeasDescZ4; cycleNum profNum nbMeasDescZ4];
                  o_sensorTechSUNANbMeasDescZ5 = [o_sensorTechSUNANbMeasDescZ5; cycleNum profNum nbMeasDescZ5];
                  o_sensorTechSUNANbMeasDrift = [o_sensorTechSUNANbMeasDrift; cycleNum profNum nbMeasDrift];
                  o_sensorTechSUNANbMeasAscZ1 = [o_sensorTechSUNANbMeasAscZ1; cycleNum profNum nbMeasAscZ1];
                  o_sensorTechSUNANbMeasAscZ2 = [o_sensorTechSUNANbMeasAscZ2; cycleNum profNum nbMeasAscZ2];
                  o_sensorTechSUNANbMeasAscZ3 = [o_sensorTechSUNANbMeasAscZ3; cycleNum profNum nbMeasAscZ3];
                  o_sensorTechSUNANbMeasAscZ4 = [o_sensorTechSUNANbMeasAscZ4; cycleNum profNum nbMeasAscZ4];
                  o_sensorTechSUNANbMeasAscZ5 = [o_sensorTechSUNANbMeasAscZ5; cycleNum profNum nbMeasAscZ5];
                  o_sensorTechSUNASensorState = [o_sensorTechSUNASensorState; cycleNum profNum sensorState];
                  o_sensorTechSUNASensorSerialNum = [o_sensorTechSUNASensorSerialNum; cycleNum profNum measSensorSerialNum];
                  o_sensorTechSUNAAPFSampCounter = [o_sensorTechSUNAAPFSampCounter; cycleNum profNum measSampCounter];
                  o_sensorTechSUNAAPFPowerCycleCounter = [o_sensorTechSUNAAPFPowerCycleCounter; cycleNum profNum measPowerCycleCounter];
                  o_sensorTechSUNAAPFErrorCounter = [o_sensorTechSUNAAPFErrorCounter; cycleNum profNum measErrorCounter];
                  o_sensorTechSUNAAPFSupplyVoltage = [o_sensorTechSUNAAPFSupplyVoltage; cycleNum profNum measSupplyVoltage];
                  o_sensorTechSUNAAPFSupplyCurrent = [o_sensorTechSUNAAPFSupplyCurrent; cycleNum profNum measSupplyCurrent];
                  o_sensorTechSUNAAPFOutPixelBegin = [o_sensorTechSUNAAPFOutPixelBegin; cycleNum profNum measOutPixelBegin];
                  o_sensorTechSUNAAPFOutPixelEnd = [o_sensorTechSUNAAPFOutPixelEnd; cycleNum profNum measOutPixelEnd];
                  
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
            
            if (cycleNum ~= g_decArgo_cycleNum)
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) => ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  cycleNum, g_decArgo_cycleNum);
               continue
            end
            
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
            
            if (a_procLevel == 0)
               g_decArgo_253TypeReceivedData = [g_decArgo_253TypeReceivedData; ...
                  tabTech(9) tabTech(10) tabTech(13)];
               continue
            end
            
            cycleNum = tabTech(9);
            if (cycleNum ~= g_decArgo_cycleNum)
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) => ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  cycleNum, g_decArgo_cycleNum);
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
            
            if ((a_procLevel == 0) || (a_procLevel == 1))
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
            
            % calibration coefficients
            values(35) = values(35)/1000;
            values(36) = -values(36);
            
            cycleNum = values(7);
            if (cycleNum ~= g_decArgo_cycleNum)
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) => ignoring packet data\n', ...
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

            if ((a_procLevel == 0) || (a_procLevel == 1))
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
            
            cycleNum = values(7);
            if (cycleNum ~= g_decArgo_cycleNum)
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent cycle number (#%d instead of #%d) => ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  cycleNum, g_decArgo_cycleNum);
               continue
            end
            
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
                  
                  fprintf('WARNING: Float #%d: %d duplicated float technical messages for cycle #%d and profile #%d => only the last one is considered\n', ...
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
end

% store output data in cell arrays
o_dataCTDMean{1} = o_dataCTDMeanDate;
o_dataCTDMean{2} = o_dataCTDMeanDateTrans;
o_dataCTDMean{3} = o_dataCTDMeanPres;
o_dataCTDMean{4} = o_dataCTDMeanTemp;
o_dataCTDMean{5} = o_dataCTDMeanSal;

o_dataCTDRaw{1} = o_dataCTDRawDate;
o_dataCTDRaw{2} = o_dataCTDRawDateTrans;
o_dataCTDRaw{3} = o_dataCTDRawPres;
o_dataCTDRaw{4} = o_dataCTDRawTemp;
o_dataCTDRaw{5} = o_dataCTDRawSal;

o_dataCTDStdMed{1} = o_dataCTDStdMedDate;
o_dataCTDStdMed{2} = o_dataCTDStdMedDateTrans;
o_dataCTDStdMed{3} = o_dataCTDStdMedPresMean;
o_dataCTDStdMed{4} = o_dataCTDStdMedTempStd;
o_dataCTDStdMed{5} = o_dataCTDStdMedSalStd;
o_dataCTDStdMed{6} = o_dataCTDStdMedPresMed;
o_dataCTDStdMed{7} = o_dataCTDStdMedTempMed;
o_dataCTDStdMed{8} = o_dataCTDStdMedSalMed;

o_dataCTD{1} = o_dataCTDMean;
o_dataCTD{2} = o_dataCTDRaw;
o_dataCTD{3} = o_dataCTDStdMed;

o_dataOXYMean{1} = o_dataOXYMeanDate;
o_dataOXYMean{2} = o_dataOXYMeanDateTrans;
o_dataOXYMean{3} = o_dataOXYMeanPres;
o_dataOXYMean{4} = o_dataOXYMeanC1Phase;
o_dataOXYMean{5} = o_dataOXYMeanC2Phase;
o_dataOXYMean{6} = o_dataOXYMeanTemp;

o_dataOXYRaw{1} = o_dataOXYRawDate;
o_dataOXYRaw{2} = o_dataOXYRawDateTrans;
o_dataOXYRaw{3} = o_dataOXYRawPres;
o_dataOXYRaw{4} = o_dataOXYRawC1Phase;
o_dataOXYRaw{5} = o_dataOXYRawC2Phase;
o_dataOXYRaw{6} = o_dataOXYRawTemp;

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
o_dataOXY{2} = o_dataOXYRaw;
o_dataOXY{3} = o_dataOXYStdMed;

o_dataECO3Mean{1} = o_dataECO3MeanDate;
o_dataECO3Mean{2} = o_dataECO3MeanDateTrans;
o_dataECO3Mean{3} = o_dataECO3MeanPres;
o_dataECO3Mean{4} = o_dataECO3MeanChloroA;
o_dataECO3Mean{5} = o_dataECO3MeanBackscat;
o_dataECO3Mean{6} = o_dataECO3MeanCdom;

o_dataECO3Raw{1} = o_dataECO3RawDate;
o_dataECO3Raw{2} = o_dataECO3RawDateTrans;
o_dataECO3Raw{3} = o_dataECO3RawPres;
o_dataECO3Raw{4} = o_dataECO3RawChloroA;
o_dataECO3Raw{5} = o_dataECO3RawBackscat;
o_dataECO3Raw{6} = o_dataECO3RawCdom;

o_dataECO3StdMed{1} = o_dataECO3StdMedDate;
o_dataECO3StdMed{2} = o_dataECO3StdMedDateTrans;
o_dataECO3StdMed{3} = o_dataECO3StdMedPresMean;
o_dataECO3StdMed{4} = o_dataECO3StdMedChloroAStd;
o_dataECO3StdMed{5} = o_dataECO3StdMedBackscatStd;
o_dataECO3StdMed{6} = o_dataECO3StdMedCdomStd;
o_dataECO3StdMed{7} = o_dataECO3StdMedChloroAMed;
o_dataECO3StdMed{8} = o_dataECO3StdMedBackscatMed;
o_dataECO3StdMed{9} = o_dataECO3StdMedCdomMed;

o_dataECO3{1} = o_dataECO3Mean;
o_dataECO3{2} = o_dataECO3Raw;
o_dataECO3{3} = o_dataECO3StdMed;

o_dataOCRMean{1} = o_dataOCRMeanDate;
o_dataOCRMean{2} = o_dataOCRMeanDateTrans;
o_dataOCRMean{3} = o_dataOCRMeanPres;
o_dataOCRMean{4} = o_dataOCRMeanIr1;
o_dataOCRMean{5} = o_dataOCRMeanIr2;
o_dataOCRMean{6} = o_dataOCRMeanIr3;
o_dataOCRMean{7} = o_dataOCRMeanIr4;

o_dataOCRRaw{1} = o_dataOCRRawDate;
o_dataOCRRaw{2} = o_dataOCRRawDateTrans;
o_dataOCRRaw{3} = o_dataOCRRawPres;
o_dataOCRRaw{4} = o_dataOCRRawIr1;
o_dataOCRRaw{5} = o_dataOCRRawIr2;
o_dataOCRRaw{6} = o_dataOCRRawIr3;
o_dataOCRRaw{7} = o_dataOCRRawIr4;

o_dataOCRStdMed{1} = o_dataOCRStdMedDate;
o_dataOCRStdMed{2} = o_dataOCRStdMedDateTrans;
o_dataOCRStdMed{3} = o_dataOCRStdMedPresMean;
o_dataOCRStdMed{4} = o_dataOCRStdMedIr1Std;
o_dataOCRStdMed{5} = o_dataOCRStdMedIr2Std;
o_dataOCRStdMed{6} = o_dataOCRStdMedIr3Std;
o_dataOCRStdMed{7} = o_dataOCRStdMedIr4Std;
o_dataOCRStdMed{8} = o_dataOCRStdMedIr1Med;
o_dataOCRStdMed{9} = o_dataOCRStdMedIr2Med;
o_dataOCRStdMed{10} = o_dataOCRStdMedIr3Med;
o_dataOCRStdMed{11} = o_dataOCRStdMedIr4Med;

o_dataOCR{1} = o_dataOCRMean;
o_dataOCR{2} = o_dataOCRRaw;
o_dataOCR{3} = o_dataOCRStdMed;

o_dataFLNTUMean{1} = o_dataFLNTUMeanDate;
o_dataFLNTUMean{2} = o_dataFLNTUMeanDateTrans;
o_dataFLNTUMean{3} = o_dataFLNTUMeanPres;
o_dataFLNTUMean{4} = o_dataFLNTUMeanChloro;
o_dataFLNTUMean{5} = o_dataFLNTUMeanTurbi;

o_dataFLNTURaw{1} = o_dataFLNTURawDate;
o_dataFLNTURaw{2} = o_dataFLNTURawDateTrans;
o_dataFLNTURaw{3} = o_dataFLNTURawPres;
o_dataFLNTURaw{4} = o_dataFLNTURawChloro;
o_dataFLNTURaw{5} = o_dataFLNTURawTurbi;

o_dataFLNTUStdMed{1} = o_dataFLNTUStdMedDate;
o_dataFLNTUStdMed{2} = o_dataFLNTUStdMedDateTrans;
o_dataFLNTUStdMed{3} = o_dataFLNTUStdMedPresMean;
o_dataFLNTUStdMed{4} = o_dataFLNTUStdMedChloroStd;
o_dataFLNTUStdMed{5} = o_dataFLNTUStdMedTurbiStd;
o_dataFLNTUStdMed{6} = o_dataFLNTUStdMedChloroMed;
o_dataFLNTUStdMed{7} = o_dataFLNTUStdMedTurbiMed;

o_dataFLNTU{1} = o_dataFLNTUMean;
o_dataFLNTU{2} = o_dataFLNTURaw;
o_dataFLNTU{3} = o_dataFLNTUStdMed;

o_dataCROVERMean{1} = o_dataCROVERMeanDate;
o_dataCROVERMean{2} = o_dataCROVERMeanDateTrans;
o_dataCROVERMean{3} = o_dataCROVERMeanPres;
o_dataCROVERMean{4} = o_dataCROVERMeanCoefAtt;

o_dataCROVERRaw{1} = o_dataCROVERRawDate;
o_dataCROVERRaw{2} = o_dataCROVERRawDateTrans;
o_dataCROVERRaw{3} = o_dataCROVERRawPres;
o_dataCROVERRaw{4} = o_dataCROVERRawCoefAtt;

o_dataCROVERStdMed{1} = o_dataCROVERStdMedDate;
o_dataCROVERStdMed{2} = o_dataCROVERStdMedDateTrans;
o_dataCROVERStdMed{3} = o_dataCROVERStdMedPresMean;
o_dataCROVERStdMed{4} = o_dataCROVERStdMedCoefAttStd;
o_dataCROVERStdMed{5} = o_dataCROVERStdMedCoefAttMed;

o_dataCROVER{1} = o_dataCROVERMean;
o_dataCROVER{2} = o_dataCROVERRaw;
o_dataCROVER{3} = o_dataCROVERStdMed;

o_dataSUNAMean{1} = o_dataSUNAMeanDate;
o_dataSUNAMean{2} = o_dataSUNAMeanDateTrans;
o_dataSUNAMean{3} = o_dataSUNAMeanPres;
o_dataSUNAMean{4} = o_dataSUNAMeanConcNitra;

o_dataSUNARaw{1} = o_dataSUNARawDate;
o_dataSUNARaw{2} = o_dataSUNARawDateTrans;
o_dataSUNARaw{3} = o_dataSUNARawPres;
o_dataSUNARaw{4} = o_dataSUNARawConcNitra;

o_dataSUNAStdMed{1} = o_dataSUNAStdMedDate;
o_dataSUNAStdMed{2} = o_dataSUNAStdMedDateTrans;
o_dataSUNAStdMed{3} = o_dataSUNAStdMedPresMean;
o_dataSUNAStdMed{4} = o_dataSUNAStdMedConcNitraStd;
o_dataSUNAStdMed{5} = o_dataSUNAStdMedConcNitraMed;

o_dataSUNAAPF{1} = o_dataSUNAAPFDate;
o_dataSUNAAPF{2} = o_dataSUNAAPFDateTrans;
o_dataSUNAAPF{3} = o_dataSUNAAPFCTDPres;
o_dataSUNAAPF{4} = o_dataSUNAAPFCTDTemp;
o_dataSUNAAPF{5} = o_dataSUNAAPFCTDSal;
o_dataSUNAAPF{6} = o_dataSUNAAPFIntTemp;
o_dataSUNAAPF{7} = o_dataSUNAAPFSpecTemp;
o_dataSUNAAPF{8} = o_dataSUNAAPFIntRelHumidity;
o_dataSUNAAPF{9} = o_dataSUNAAPFDarkSpecMean;
o_dataSUNAAPF{10} = o_dataSUNAAPFDarkSpecStd;
o_dataSUNAAPF{11} = o_dataSUNAAPFSensorNitra;
o_dataSUNAAPF{12} = o_dataSUNAAPFAbsFitRes;
o_dataSUNAAPF{13} = o_dataSUNAAPFOutSpec;

o_dataSUNAAPF2 = [];
if (~isempty(o_dataSUNAAPF2Date))
   o_dataSUNAAPF2{1} = o_dataSUNAAPF2Date;
   o_dataSUNAAPF2{2} = o_dataSUNAAPF2DateTrans;
   o_dataSUNAAPF2{3} = o_dataSUNAAPF2CTDPres;
   o_dataSUNAAPF2{4} = o_dataSUNAAPF2CTDTemp;
   o_dataSUNAAPF2{5} = o_dataSUNAAPF2CTDSal;
   o_dataSUNAAPF2{6} = o_dataSUNAAPF2IntTemp;
   o_dataSUNAAPF2{7} = o_dataSUNAAPF2SpecTemp;
   o_dataSUNAAPF2{8} = o_dataSUNAAPF2IntRelHumidity;
   o_dataSUNAAPF2{9} = o_dataSUNAAPF2DarkSpecMean;
   o_dataSUNAAPF2{10} = o_dataSUNAAPF2DarkSpecStd;
   o_dataSUNAAPF2{11} = o_dataSUNAAPF2SensorNitra;
   o_dataSUNAAPF2{12} = o_dataSUNAAPF2AbsFitRes;
   o_dataSUNAAPF2{13} = o_dataSUNAAPF2OutSpec;
end

o_dataSUNA{1} = o_dataSUNAMean;
o_dataSUNA{2} = o_dataSUNARaw;
o_dataSUNA{3} = o_dataSUNAStdMed;
o_dataSUNA{4} = o_dataSUNAAPF;
o_dataSUNA{5} = o_dataSUNAAPF2;

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

o_sensorTechOCR{1} = o_sensorTechOCRNbPackDesc;
o_sensorTechOCR{2} = o_sensorTechOCRNbPackDrift;
o_sensorTechOCR{3} = o_sensorTechOCRNbPackAsc;
o_sensorTechOCR{4} = o_sensorTechOCRNbMeasDescZ1;
o_sensorTechOCR{5} = o_sensorTechOCRNbMeasDescZ2;
o_sensorTechOCR{6} = o_sensorTechOCRNbMeasDescZ3;
o_sensorTechOCR{7} = o_sensorTechOCRNbMeasDescZ4;
o_sensorTechOCR{8} = o_sensorTechOCRNbMeasDescZ5;
o_sensorTechOCR{9} = o_sensorTechOCRNbMeasDrift;
o_sensorTechOCR{10} = o_sensorTechOCRNbMeasAscZ1;
o_sensorTechOCR{11} = o_sensorTechOCRNbMeasAscZ2;
o_sensorTechOCR{12} = o_sensorTechOCRNbMeasAscZ3;
o_sensorTechOCR{13} = o_sensorTechOCRNbMeasAscZ4;
o_sensorTechOCR{14} = o_sensorTechOCRNbMeasAscZ5;
o_sensorTechOCR{15} = o_sensorTechOCRSensorState;
o_sensorTechOCR{16} = o_sensorTechOCRSensorSerialNum;
o_sensorTechOCR{17} = o_sensorTechOCRCoefLambda1A0;
o_sensorTechOCR{18} = o_sensorTechOCRCoefLambda1A1;
o_sensorTechOCR{19} = o_sensorTechOCRCoefLambda1Lm;
o_sensorTechOCR{20} = o_sensorTechOCRCoefLambda2A0;
o_sensorTechOCR{21} = o_sensorTechOCRCoefLambda2A1;
o_sensorTechOCR{22} = o_sensorTechOCRCoefLambda2Lm;
o_sensorTechOCR{23} = o_sensorTechOCRCoefLambda3A0;
o_sensorTechOCR{24} = o_sensorTechOCRCoefLambda3A1;
o_sensorTechOCR{25} = o_sensorTechOCRCoefLambda3Lm;
o_sensorTechOCR{26} = o_sensorTechOCRCoefParA0;
o_sensorTechOCR{27} = o_sensorTechOCRCoefParA1;
o_sensorTechOCR{28} = o_sensorTechOCRCoefParLm;

o_sensorTechECO3{1} = o_sensorTechECO3NbPackDesc;
o_sensorTechECO3{2} = o_sensorTechECO3NbPackDrift;
o_sensorTechECO3{3} = o_sensorTechECO3NbPackAsc;
o_sensorTechECO3{4} = o_sensorTechECO3NbMeasDescZ1;
o_sensorTechECO3{5} = o_sensorTechECO3NbMeasDescZ2;
o_sensorTechECO3{6} = o_sensorTechECO3NbMeasDescZ3;
o_sensorTechECO3{7} = o_sensorTechECO3NbMeasDescZ4;
o_sensorTechECO3{8} = o_sensorTechECO3NbMeasDescZ5;
o_sensorTechECO3{9} = o_sensorTechECO3NbMeasDrift;
o_sensorTechECO3{10} = o_sensorTechECO3NbMeasAscZ1;
o_sensorTechECO3{11} = o_sensorTechECO3NbMeasAscZ2;
o_sensorTechECO3{12} = o_sensorTechECO3NbMeasAscZ3;
o_sensorTechECO3{13} = o_sensorTechECO3NbMeasAscZ4;
o_sensorTechECO3{14} = o_sensorTechECO3NbMeasAscZ5;
o_sensorTechECO3{15} = o_sensorTechECO3SensorState;
o_sensorTechECO3{16} = o_sensorTechECO3SensorSerialNum;
o_sensorTechECO3{17} = o_sensorTechECO3CoefScaleFactChloroA;
o_sensorTechECO3{18} = o_sensorTechECO3CoefDarkCountChloroA;
o_sensorTechECO3{19} = o_sensorTechECO3CoefScaleFactBackscat;
o_sensorTechECO3{20} = o_sensorTechECO3CoefDarkCountBackscat;
o_sensorTechECO3{21} = o_sensorTechECO3CoefScaleFactCdom;
o_sensorTechECO3{22} = o_sensorTechECO3CoefDarkCountCdom;

o_sensorTechFLNTU{1} = o_sensorTechFLNTUNbPackDesc;
o_sensorTechFLNTU{2} = o_sensorTechFLNTUNbPackDrift;
o_sensorTechFLNTU{3} = o_sensorTechFLNTUNbPackAsc;
o_sensorTechFLNTU{4} = o_sensorTechFLNTUNbMeasDescZ1;
o_sensorTechFLNTU{5} = o_sensorTechFLNTUNbMeasDescZ2;
o_sensorTechFLNTU{6} = o_sensorTechFLNTUNbMeasDescZ3;
o_sensorTechFLNTU{7} = o_sensorTechFLNTUNbMeasDescZ4;
o_sensorTechFLNTU{8} = o_sensorTechFLNTUNbMeasDescZ5;
o_sensorTechFLNTU{9} = o_sensorTechFLNTUNbMeasDrift;
o_sensorTechFLNTU{10} = o_sensorTechFLNTUNbMeasAscZ1;
o_sensorTechFLNTU{11} = o_sensorTechFLNTUNbMeasAscZ2;
o_sensorTechFLNTU{12} = o_sensorTechFLNTUNbMeasAscZ3;
o_sensorTechFLNTU{13} = o_sensorTechFLNTUNbMeasAscZ4;
o_sensorTechFLNTU{14} = o_sensorTechFLNTUNbMeasAscZ5;
o_sensorTechFLNTU{15} = o_sensorTechFLNTUSensorState;
o_sensorTechFLNTU{16} = o_sensorTechFLNTUCoefScaleChloro;
o_sensorTechFLNTU{17} = o_sensorTechFLNTUDarkCountChloro;
o_sensorTechFLNTU{18} = o_sensorTechFLNTUCoefScaleTurbi;
o_sensorTechFLNTU{19} = o_sensorTechFLNTUDarkCountTurbi;

o_sensorTechCROVER{1} = o_sensorTechCROVERNbPackDesc;
o_sensorTechCROVER{2} = o_sensorTechCROVERNbPackDrift;
o_sensorTechCROVER{3} = o_sensorTechCROVERNbPackAsc;
o_sensorTechCROVER{4} = o_sensorTechCROVERNbMeasDescZ1;
o_sensorTechCROVER{5} = o_sensorTechCROVERNbMeasDescZ2;
o_sensorTechCROVER{6} = o_sensorTechCROVERNbMeasDescZ3;
o_sensorTechCROVER{7} = o_sensorTechCROVERNbMeasDescZ4;
o_sensorTechCROVER{8} = o_sensorTechCROVERNbMeasDescZ5;
o_sensorTechCROVER{9} = o_sensorTechCROVERNbMeasDrift;
o_sensorTechCROVER{10} = o_sensorTechCROVERNbMeasAscZ1;
o_sensorTechCROVER{11} = o_sensorTechCROVERNbMeasAscZ2;
o_sensorTechCROVER{12} = o_sensorTechCROVERNbMeasAscZ3;
o_sensorTechCROVER{13} = o_sensorTechCROVERNbMeasAscZ4;
o_sensorTechCROVER{14} = o_sensorTechCROVERNbMeasAscZ5;
o_sensorTechCROVER{15} = o_sensorTechCROVERSensorState;
o_sensorTechCROVER{16} = o_sensorTechCROVERSensorSerialNum;

o_sensorTechSUNA{1} = o_sensorTechSUNANbPackDesc;
o_sensorTechSUNA{2} = o_sensorTechSUNANbPackDrift;
o_sensorTechSUNA{3} = o_sensorTechSUNANbPackAsc;
o_sensorTechSUNA{4} = o_sensorTechSUNANbMeasDescZ1;
o_sensorTechSUNA{5} = o_sensorTechSUNANbMeasDescZ2;
o_sensorTechSUNA{6} = o_sensorTechSUNANbMeasDescZ3;
o_sensorTechSUNA{7} = o_sensorTechSUNANbMeasDescZ4;
o_sensorTechSUNA{8} = o_sensorTechSUNANbMeasDescZ5;
o_sensorTechSUNA{9} = o_sensorTechSUNANbMeasDrift;
o_sensorTechSUNA{10} = o_sensorTechSUNANbMeasAscZ1;
o_sensorTechSUNA{11} = o_sensorTechSUNANbMeasAscZ2;
o_sensorTechSUNA{12} = o_sensorTechSUNANbMeasAscZ3;
o_sensorTechSUNA{13} = o_sensorTechSUNANbMeasAscZ4;
o_sensorTechSUNA{14} = o_sensorTechSUNANbMeasAscZ5;
o_sensorTechSUNA{15} = o_sensorTechSUNASensorState;
o_sensorTechSUNA{16} = o_sensorTechSUNASensorSerialNum;
o_sensorTechSUNA{17} = o_sensorTechSUNAAPFSampCounter;
o_sensorTechSUNA{18} = o_sensorTechSUNAAPFPowerCycleCounter;
o_sensorTechSUNA{19} = o_sensorTechSUNAAPFErrorCounter;
o_sensorTechSUNA{20} = o_sensorTechSUNAAPFSupplyVoltage;
o_sensorTechSUNA{21} = o_sensorTechSUNAAPFSupplyCurrent;
o_sensorTechSUNA{22} = o_sensorTechSUNAAPFOutPixelBegin;
o_sensorTechSUNA{23} = o_sensorTechSUNAAPFOutPixelEnd;

o_sensorParam{1} = o_sensorParamModSensorNum;
o_sensorParam{2} = o_sensorParamParamType;
o_sensorParam{3} = o_sensorParamParamNum;
o_sensorParam{4} = o_sensorParamOldVal;
o_sensorParam{5} = o_sensorParamNewVal;

o_floatPres{1} = o_floatPresPumpOrEv;
o_floatPres{2} = o_floatPresActPres;
o_floatPres{3} = o_floatPresTime;

return
