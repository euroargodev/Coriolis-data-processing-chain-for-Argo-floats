% ------------------------------------------------------------------------------
% Retrieve decoded data.
%
% SYNTAX :
%  [o_cyProfPhaseList, ...
%    o_dataCTD, o_dataOXY, o_dataOCR, o_dataECO2, o_dataECO3, o_dataFLNTU, ...
%    o_dataCROVER, o_dataSUNA, o_dataSEAFET, ...
%    o_sensorTechCTD, o_sensorTechOPTODE, o_sensorTechOCR, ...
%    o_sensorTechECO2, o_sensorTechECO3, o_sensorTechFLNTU, o_sensorTechSEAFET, ...
%    o_sensorTechCROVER, o_sensorTechSUNA, ...
%    o_tabTech, o_floatPres, o_grounding, ...
%    o_floatProgRudics, o_floatProgTech, o_floatProgParam, o_floatProgSensor] = ...
%    get_decoded_data_cts4(a_decDataTab, a_decoderId)
%
% INPUT PARAMETERS :
%   a_decodedDataTab : decoded data
%   a_decoderId      : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_cyProfPhaseList  : information (cycle #, prof #, phase #) on each
%                        received packet
%   o_dataCTD          : decoded CTD data
%   o_dataOXY          : decoded OXY data
%   o_dataOCR          : decoded OCR data
%   o_dataECO2         : decoded ECO2 data
%   o_dataECO3         : decoded ECO3 data
%   o_dataFLNTU        : decoded FLNTU data
%   o_dataCROVER       : decoded cROVER data
%   o_dataSUNA         : decoded SUNA data
%   o_dataSEAFET       : decoded SEAFET data
%   o_sensorTechCTD    : decoded CTD technical data
%   o_sensorTechOPTODE : decoded OXY technical data
%   o_sensorTechOCR    : decoded OCR technical data
%   o_sensorTechECO2   : decoded ECO2 technical data
%   o_sensorTechECO3   : decoded ECO3 technical data
%   o_sensorTechFLNTU  : decoded FLNTU technical data
%   o_sensorTechSEAFET : decoded SEAFET technical data
%   o_sensorTechCROVER : decoded cROVER technical data
%   o_sensorTechSUNA   : decoded SUNA technical data
%   o_tabTech          : decoded float technical data
%   o_floatPres        : decoded float pressure actions
%   o_grounding        : decoded float grounding data
%   o_floatProgRudics  : decoded float Iridium config (PI) data (type 248)
%   o_floatProgTech    : decoded float Tech config (PT and PG) data (type 254)
%   o_floatProgParam   : decoded float Vector & Mission config (PV and PM) data (type 255)
%   o_floatProgSensor  : decoded float Sensor config (PC) data (type 249)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/10/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cyProfPhaseList, ...
   o_dataCTD, o_dataOXY, o_dataOCR, o_dataECO2, o_dataECO3, o_dataFLNTU, ...
   o_dataCROVER, o_dataSUNA, o_dataSEAFET, ...
   o_sensorTechCTD, o_sensorTechOPTODE, o_sensorTechOCR, ...
   o_sensorTechECO2, o_sensorTechECO3, o_sensorTechFLNTU, o_sensorTechSEAFET, ...
   o_sensorTechCROVER, o_sensorTechSUNA, ...
   o_tabTech, o_floatPres, o_grounding, ...
   o_floatProgRudics, o_floatProgTech, o_floatProgParam, o_floatProgSensor] = ...
   get_decoded_data_cts4(a_decDataTab, a_decoderId)

% current float WMO number
global g_decArgo_floatNum;

% sensor list
global g_decArgo_sensorMountedOnFloat;

% array to store ko sensor states
global g_decArgo_koSensorState;

% output parameters initialization
o_cyProfPhaseList = [];

o_dataCTD = [];
o_dataOXY = [];
o_dataECO2 = [];
o_dataECO3 = [];
o_dataOCR = [];
o_dataFLNTU = [];
o_dataCROVER = [];
o_dataSUNA = [];
o_dataSEAFET = [];

o_sensorTechCTD = [];
o_sensorTechOPTODE = [];
o_sensorTechOCR = [];
o_sensorTechECO2 = [];
o_sensorTechECO3 = [];
o_sensorTechFLNTU = [];
o_sensorTechSEAFET = [];
o_sensorTechCROVER = [];
o_sensorTechSUNA = [];

o_tabTech = [];

o_floatPres = [];

o_grounding = [];

o_floatProgRudics = [];
o_floatProgTech = [];
o_floatProgParam = [];
o_floatProgSensor = [];

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

o_dataECO2MeanDate = [];
o_dataECO2MeanDateTrans = [];
o_dataECO2MeanPres = [];
o_dataECO2MeanChloroA = [];
o_dataECO2MeanBackscat = [];

o_dataECO2RawDate = [];
o_dataECO2RawDateTrans = [];
o_dataECO2RawPres = [];
o_dataECO2RawChloroA = [];
o_dataECO2RawBackscat = [];

o_dataECO2StdMedDate = [];
o_dataECO2StdMedDateTrans = [];
o_dataECO2StdMedPresMean = [];
o_dataECO2StdMedChloroAStd = [];
o_dataECO2StdMedBackscatStd = [];
o_dataECO2StdMedChloroAMed = [];
o_dataECO2StdMedBackscatMed = [];

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

o_dataSEAFETMeanDate = [];
o_dataSEAFETMeanDateTrans = [];
o_dataSEAFETMeanPres = [];
o_dataSEAFETMeanVref = [];

o_dataSEAFETRawDate = [];
o_dataSEAFETRawDateTrans = [];
o_dataSEAFETRawPres = [];
o_dataSEAFETRawVref = [];

o_dataSEAFETStdMedDate = [];
o_dataSEAFETStdMedDateTrans = [];
o_dataSEAFETStdMedPresMean = [];
o_dataSEAFETStdMedVrefStd = [];
o_dataSEAFETStdMedVrefMed = [];

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
o_sensorTechOPTODESensorSerialNum = [];

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

o_sensorTechECO2NbPackDesc = [];
o_sensorTechECO2NbPackDrift = [];
o_sensorTechECO2NbPackAsc = [];
o_sensorTechECO2NbMeasDescZ1 = [];
o_sensorTechECO2NbMeasDescZ2 = [];
o_sensorTechECO2NbMeasDescZ3 = [];
o_sensorTechECO2NbMeasDescZ4 = [];
o_sensorTechECO2NbMeasDescZ5 = [];
o_sensorTechECO2NbMeasDrift = [];
o_sensorTechECO2NbMeasAscZ1 = [];
o_sensorTechECO2NbMeasAscZ2 = [];
o_sensorTechECO2NbMeasAscZ3 = [];
o_sensorTechECO2NbMeasAscZ4 = [];
o_sensorTechECO2NbMeasAscZ5 = [];
o_sensorTechECO2SensorState = [];
o_sensorTechECO2SensorSerialNum = [];
o_sensorTechECO2CoefScaleFactChloroA = [];
o_sensorTechECO2CoefDarkCountChloroA = [];
o_sensorTechECO2CoefScaleFactBackscat = [];
o_sensorTechECO2CoefDarkCountBackscat = [];

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

o_sensorTechSEAFETNbPackDesc = [];
o_sensorTechSEAFETNbPackDrift = [];
o_sensorTechSEAFETNbPackAsc = [];
o_sensorTechSEAFETNbMeasDescZ1 = [];
o_sensorTechSEAFETNbMeasDescZ2 = [];
o_sensorTechSEAFETNbMeasDescZ3 = [];
o_sensorTechSEAFETNbMeasDescZ4 = [];
o_sensorTechSEAFETNbMeasDescZ5 = [];
o_sensorTechSEAFETNbMeasDrift = [];
o_sensorTechSEAFETNbMeasAscZ1 = [];
o_sensorTechSEAFETNbMeasAscZ2 = [];
o_sensorTechSEAFETNbMeasAscZ3 = [];
o_sensorTechSEAFETNbMeasAscZ4 = [];
o_sensorTechSEAFETNbMeasAscZ5 = [];
o_sensorTechSEAFETSensorState = [];
o_sensorTechSEAFETSensorSerialNum = [];

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

o_floatPresPumpOrEv = [];
o_floatPresActPres = [];
o_floatPresActTime = [];
o_floatPresActDuration = [];

o_groundingDate = [];
o_groundingPres = [];
o_groundingSetPoint = [];
o_groundingIntVacuum = [];

switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {111, 113, 114, 115} % Remocean V3.00 and higher
      
      % retrieve data
      for idSbd = 1:length(a_decDataTab)
         
         o_cyProfPhaseList = cat(1, o_cyProfPhaseList, a_decDataTab(idSbd).cyProfPhaseList);
         
         packType = a_decDataTab(idSbd).packType;
         switch (packType)
            
            case 0
               % sensor data
               
               sensorDataType = a_decDataTab(idSbd).sensorDataType;
               decData = a_decDataTab(idSbd).decData;

               switch (sensorDataType)
                  
                  case {0, 2}
                     % CTD (mean & raw)
                     
                     if (sensorDataType == 0)
                        o_dataCTDMeanDate = cat(1, o_dataCTDMeanDate, decData{1});
                        o_dataCTDMeanDateTrans = cat(1, o_dataCTDMeanDateTrans, decData{2});
                        o_dataCTDMeanPres = cat(1, o_dataCTDMeanPres, decData{3});
                        o_dataCTDMeanTemp = cat(1, o_dataCTDMeanTemp, decData{4});
                        o_dataCTDMeanSal = cat(1, o_dataCTDMeanSal, decData{5});
                     elseif (sensorDataType == 2)
                        o_dataCTDRawDate = cat(1, o_dataCTDRawDate, decData{1});
                        o_dataCTDRawDateTrans = cat(1, o_dataCTDRawDateTrans, decData{2});
                        o_dataCTDRawPres = cat(1, o_dataCTDRawPres, decData{3});
                        o_dataCTDRawTemp = cat(1, o_dataCTDRawTemp, decData{4});
                        o_dataCTDRawSal = cat(1, o_dataCTDRawSal, decData{5});
                     end
                     
                  case {1}
                     % CTD (stDev & median)
                     
                     o_dataCTDStdMedDate = cat(1, o_dataCTDStdMedDate, decData{1});
                     o_dataCTDStdMedDateTrans = cat(1, o_dataCTDStdMedDateTrans, decData{2});
                     o_dataCTDStdMedPresMean = cat(1, o_dataCTDStdMedPresMean, decData{3});
                     o_dataCTDStdMedTempStd = cat(1, o_dataCTDStdMedTempStd, decData{4});
                     o_dataCTDStdMedSalStd = cat(1, o_dataCTDStdMedSalStd, decData{5});
                     o_dataCTDStdMedPresMed = cat(1, o_dataCTDStdMedPresMed, decData{6});
                     o_dataCTDStdMedTempMed = cat(1, o_dataCTDStdMedTempMed, decData{7});
                     o_dataCTDStdMedSalMed = cat(1, o_dataCTDStdMedSalMed, decData{8});
                     
                  case {3, 5}
                     % OXYGEN (mean & raw)
                     
                     if (sensorDataType == 3)
                        o_dataOXYMeanDate = cat(1, o_dataOXYMeanDate, decData{1});
                        o_dataOXYMeanDateTrans = cat(1, o_dataOXYMeanDateTrans, decData{2});
                        o_dataOXYMeanPres = cat(1, o_dataOXYMeanPres, decData{3});
                        o_dataOXYMeanC1Phase = cat(1, o_dataOXYMeanC1Phase, decData{4});
                        o_dataOXYMeanC2Phase = cat(1, o_dataOXYMeanC2Phase, decData{5});
                        o_dataOXYMeanTemp = cat(1, o_dataOXYMeanTemp, decData{6});
                     elseif (sensorDataType == 5)
                        o_dataOXYRawDate = cat(1, o_dataOXYRawDate, decData{1});
                        o_dataOXYRawDateTrans = cat(1, o_dataOXYRawDateTrans, decData{2});
                        o_dataOXYRawPres = cat(1, o_dataOXYRawPres, decData{3});
                        o_dataOXYRawC1Phase = cat(1, o_dataOXYRawC1Phase, decData{4});
                        o_dataOXYRawC2Phase = cat(1, o_dataOXYRawC2Phase, decData{5});
                        o_dataOXYRawTemp = cat(1, o_dataOXYRawTemp, decData{6});
                     end
                     
                  case {4}
                     % OXYGEN (stDev & median)
                     
                     o_dataOXYStdMedDate = cat(1, o_dataOXYStdMedDate, decData{1});
                     o_dataOXYStdMedDateTrans = cat(1, o_dataOXYStdMedDateTrans, decData{2});
                     o_dataOXYStdMedPresMean = cat(1, o_dataOXYStdMedPresMean, decData{3});
                     o_dataOXYStdMedC1PhaseStd = cat(1, o_dataOXYStdMedC1PhaseStd, decData{4});
                     o_dataOXYStdMedC2PhaseStd = cat(1, o_dataOXYStdMedC2PhaseStd, decData{5});
                     o_dataOXYStdMedTempStd = cat(1, o_dataOXYStdMedTempStd, decData{6});
                     o_dataOXYStdMedC1PhaseMed = cat(1, o_dataOXYStdMedC1PhaseMed, decData{7});
                     o_dataOXYStdMedC2PhaseMed = cat(1, o_dataOXYStdMedC2PhaseMed, decData{8});
                     o_dataOXYStdMedTempMed = cat(1, o_dataOXYStdMedTempMed, decData{9});
                     
                  case {6, 8}
                     % ECO2 (mean & raw)
                     
                     if (sensorDataType == 6)
                        o_dataECO2MeanDate = cat(1, o_dataECO2MeanDate, decData{1});
                        o_dataECO2MeanDateTrans = cat(1, o_dataECO2MeanDateTrans, decData{2});
                        o_dataECO2MeanPres = cat(1, o_dataECO2MeanPres, decData{3});
                        o_dataECO2MeanChloroA = cat(1, o_dataECO2MeanChloroA, decData{4});
                        o_dataECO2MeanBackscat = cat(1, o_dataECO2MeanBackscat, decData{5});
                     elseif (sensorDataType == 8)
                        o_dataECO2RawDate = cat(1, o_dataECO2RawDate, decData{1});
                        o_dataECO2RawDateTrans = cat(1, o_dataECO2RawDateTrans, decData{2});
                        o_dataECO2RawPres = cat(1, o_dataECO2RawPres, decData{3});
                        o_dataECO2RawChloroA = cat(1, o_dataECO2RawChloroA, decData{4});
                        o_dataECO2RawBackscat = cat(1, o_dataECO2RawBackscat, decData{5});
                     end
                     
                  case {7}
                     % ECO2 (stDev & median)
                     
                     o_dataECO2StdMedDate = cat(1, o_dataECO2StdMedDate, decData{1});
                     o_dataECO2StdMedDateTrans = cat(1, o_dataECO2StdMedDateTrans, decData{2});
                     o_dataECO2StdMedPresMean = cat(1, o_dataECO2StdMedPresMean, decData{3});
                     o_dataECO2StdMedChloroAStd = cat(1, o_dataECO2StdMedChloroAStd, decData{4});
                     o_dataECO2StdMedBackscatStd = cat(1, o_dataECO2StdMedBackscatStd, decData{5});
                     o_dataECO2StdMedChloroAMed = cat(1, o_dataECO2StdMedChloroAMed, decData{6});
                     o_dataECO2StdMedBackscatMed = cat(1, o_dataECO2StdMedBackscatMed, decData{7});
                     
                  case {9, 11}
                     % ECO3 (mean & raw)
                     
                     if (sensorDataType == 9)
                        o_dataECO3MeanDate = cat(1, o_dataECO3MeanDate, decData{1});
                        o_dataECO3MeanDateTrans = cat(1, o_dataECO3MeanDateTrans, decData{2});
                        o_dataECO3MeanPres = cat(1, o_dataECO3MeanPres, decData{3});
                        o_dataECO3MeanChloroA = cat(1, o_dataECO3MeanChloroA, decData{4});
                        o_dataECO3MeanBackscat = cat(1, o_dataECO3MeanBackscat, decData{5});
                        o_dataECO3MeanCdom = cat(1, o_dataECO3MeanCdom, decData{6});
                     elseif (sensorDataType == 11)
                        o_dataECO3RawDate = cat(1, o_dataECO3RawDate, decData{1});
                        o_dataECO3RawDateTrans = cat(1, o_dataECO3RawDateTrans, decData{2});
                        o_dataECO3RawPres = cat(1, o_dataECO3RawPres, decData{3});
                        o_dataECO3RawChloroA = cat(1, o_dataECO3RawChloroA, decData{4});
                        o_dataECO3RawBackscat = cat(1, o_dataECO3RawBackscat, decData{5});
                        o_dataECO3RawCdom = cat(1, o_dataECO3RawCdom, decData{6});
                     end
                     
                  case {10}
                     % ECO3 (stDev & median)
                     
                     o_dataECO3StdMedDate = cat(1, o_dataECO3StdMedDate, decData{1});
                     o_dataECO3StdMedDateTrans = cat(1, o_dataECO3StdMedDateTrans, decData{2});
                     o_dataECO3StdMedPresMean = cat(1, o_dataECO3StdMedPresMean, decData{3});
                     o_dataECO3StdMedChloroAStd = cat(1, o_dataECO3StdMedChloroAStd, decData{4});
                     o_dataECO3StdMedBackscatStd = cat(1, o_dataECO3StdMedBackscatStd, decData{5});
                     o_dataECO3StdMedCdomStd = cat(1, o_dataECO3StdMedCdomStd, decData{6});
                     o_dataECO3StdMedChloroAMed = cat(1, o_dataECO3StdMedChloroAMed, decData{7});
                     o_dataECO3StdMedBackscatMed = cat(1, o_dataECO3StdMedBackscatMed, decData{8});
                     o_dataECO3StdMedCdomMed = cat(1, o_dataECO3StdMedCdomMed, decData{9});
                     
                  case {12, 14}
                     % OCR (mean & raw)
                     
                     if (sensorDataType == 12)
                        o_dataOCRMeanDate = cat(1, o_dataOCRMeanDate, decData{1});
                        o_dataOCRMeanDateTrans = cat(1, o_dataOCRMeanDateTrans, decData{2});
                        o_dataOCRMeanPres = cat(1, o_dataOCRMeanPres, decData{3});
                        o_dataOCRMeanIr1 = cat(1, o_dataOCRMeanIr1, decData{4});
                        o_dataOCRMeanIr2 = cat(1, o_dataOCRMeanIr2, decData{5});
                        o_dataOCRMeanIr3 = cat(1, o_dataOCRMeanIr3, decData{6});
                        o_dataOCRMeanIr4 = cat(1, o_dataOCRMeanIr4, decData{7});
                     elseif (sensorDataType == 14)
                        o_dataOCRRawDate = cat(1, o_dataOCRRawDate, decData{1});
                        o_dataOCRRawDateTrans = cat(1, o_dataOCRRawDateTrans, decData{2});
                        o_dataOCRRawPres = cat(1, o_dataOCRRawPres, decData{3});
                        o_dataOCRRawIr1 = cat(1, o_dataOCRRawIr1, decData{4});
                        o_dataOCRRawIr2 = cat(1, o_dataOCRRawIr2, decData{5});
                        o_dataOCRRawIr3 = cat(1, o_dataOCRRawIr3, decData{6});
                        o_dataOCRRawIr4 = cat(1, o_dataOCRRawIr4, decData{7});
                     end
                     
                  case {13}
                     % OCR (stDev & median)
                     
                     o_dataOCRStdMedDate = cat(1, o_dataOCRStdMedDate, decData{1});
                     o_dataOCRStdMedDateTrans = cat(1, o_dataOCRStdMedDateTrans, decData{2});
                     o_dataOCRStdMedPresMean = cat(1, o_dataOCRStdMedPresMean, decData{3});
                     o_dataOCRStdMedIr1Std = cat(1, o_dataOCRStdMedIr1Std, decData{4});
                     o_dataOCRStdMedIr2Std = cat(1, o_dataOCRStdMedIr2Std, decData{5});
                     o_dataOCRStdMedIr3Std = cat(1, o_dataOCRStdMedIr3Std, decData{6});
                     o_dataOCRStdMedIr4Std = cat(1, o_dataOCRStdMedIr4Std, decData{7});
                     o_dataOCRStdMedIr1Med = cat(1, o_dataOCRStdMedIr1Med, decData{8});
                     o_dataOCRStdMedIr2Med = cat(1, o_dataOCRStdMedIr2Med, decData{9});
                     o_dataOCRStdMedIr3Med = cat(1, o_dataOCRStdMedIr3Med, decData{10});
                     o_dataOCRStdMedIr4Med = cat(1, o_dataOCRStdMedIr4Med, decData{11});
                     
                  case {15, 17}
                     % FLNTU (mean & raw)
                     
                     if (sensorDataType == 15)
                        o_dataFLNTUMeanDate = cat(1, o_dataFLNTUMeanDate, decData{1});
                        o_dataFLNTUMeanDateTrans = cat(1, o_dataFLNTUMeanDateTrans, decData{2});
                        o_dataFLNTUMeanPres = cat(1, o_dataFLNTUMeanPres, decData{3});
                        o_dataFLNTUMeanChloro = cat(1, o_dataFLNTUMeanChloro, decData{4});
                        o_dataFLNTUMeanTurbi = cat(1, o_dataFLNTUMeanTurbi, decData{5});
                     elseif (sensorDataType == 17)
                        o_dataFLNTURawDate = cat(1, o_dataFLNTURawDate, decData{1});
                        o_dataFLNTURawDateTrans = cat(1, o_dataFLNTURawDateTrans, decData{2});
                        o_dataFLNTURawPres = cat(1, o_dataFLNTURawPres, decData{3});
                        o_dataFLNTURawChloro = cat(1, o_dataFLNTURawChloro, decData{4});
                        o_dataFLNTURawTurbi = cat(1, o_dataFLNTURawTurbi, decData{5});
                     end
                     
                  case {16}
                     % FLNTU (stDev & median)

                     o_dataFLNTUStdMedDate = cat(1, o_dataFLNTUStdMedDate, decData{1});
                     o_dataFLNTUStdMedDateTrans = cat(1, o_dataFLNTUStdMedDateTrans, decData{2});
                     o_dataFLNTUStdMedPresMean = cat(1, o_dataFLNTUStdMedPresMean, decData{3});
                     o_dataFLNTUStdMedChloroStd = cat(1, o_dataFLNTUStdMedChloroStd, decData{4});
                     o_dataFLNTUStdMedTurbiStd = cat(1, o_dataFLNTUStdMedTurbiStd, decData{5});
                     o_dataFLNTUStdMedChloroMed = cat(1, o_dataFLNTUStdMedChloroMed, decData{6});
                     o_dataFLNTUStdMedTurbiMed = cat(1, o_dataFLNTUStdMedTurbiMed, decData{7});
                     
                  case {18, 20}
                     % cROVER (mean & raw)
                     
                     if (sensorDataType == 18)
                        o_dataCROVERMeanDate = cat(1, o_dataCROVERMeanDate, decData{1});
                        o_dataCROVERMeanDateTrans = cat(1, o_dataCROVERMeanDateTrans, decData{2});
                        o_dataCROVERMeanPres = cat(1, o_dataCROVERMeanPres, decData{3});
                        o_dataCROVERMeanCoefAtt = cat(1, o_dataCROVERMeanCoefAtt, decData{4});
                     elseif (sensorDataType == 20)
                        o_dataCROVERRawDate = cat(1, o_dataCROVERRawDate, decData{1});
                        o_dataCROVERRawDateTrans = cat(1, o_dataCROVERRawDateTrans, decData{2});
                        o_dataCROVERRawPres = cat(1, o_dataCROVERRawPres, decData{3});
                        o_dataCROVERRawCoefAtt = cat(1, o_dataCROVERRawCoefAtt, decData{4});
                     end
                     
                  case {19}
                     % cRover (stDev & median)
                     
                     o_dataCROVERStdMedDate = cat(1, o_dataCROVERStdMedDate, decData{1});
                     o_dataCROVERStdMedDateTrans = cat(1, o_dataCROVERStdMedDateTrans, decData{2});
                     o_dataCROVERStdMedPresMean = cat(1, o_dataCROVERStdMedPresMean, decData{3});
                     o_dataCROVERStdMedCoefAttStd = cat(1, o_dataCROVERStdMedCoefAttStd, decData{4});
                     o_dataCROVERStdMedCoefAttMed = cat(1, o_dataCROVERStdMedCoefAttMed, decData{5});
                     
                  case {21, 23}
                     % SUNA (mean & raw)
                     
                     if (sensorDataType == 21)
                        o_dataSUNAMeanDate = cat(1, o_dataSUNAMeanDate, decData{1});
                        o_dataSUNAMeanDateTrans = cat(1, o_dataSUNAMeanDateTrans, decData{2});
                        o_dataSUNAMeanPres = cat(1, o_dataSUNAMeanPres, decData{3});
                        o_dataSUNAMeanConcNitra = cat(1, o_dataSUNAMeanConcNitra, decData{4});
                     elseif (sensorDataType == 23)
                        o_dataSUNARawDate = cat(1, o_dataSUNARawDate, decData{1});
                        o_dataSUNARawDateTrans = cat(1, o_dataSUNARawDateTrans, decData{2});
                        o_dataSUNARawPres = cat(1, o_dataSUNARawPres, decData{3});
                        o_dataSUNARawConcNitra = cat(1, o_dataSUNARawConcNitra, decData{4});
                     end
                     
                  case {22}
                     % SUNA (stDev & median)
                     
                     o_dataSUNAStdMedDate = cat(1, o_dataSUNAStdMedDate, decData{1});
                     o_dataSUNAStdMedDateTrans = cat(1, o_dataSUNAStdMedDateTrans, decData{2});
                     o_dataSUNAStdMedPresMean = cat(1, o_dataSUNAStdMedPresMean, decData{3});
                     o_dataSUNAStdMedConcNitraStd = cat(1, o_dataSUNAStdMedConcNitraStd, decData{4});
                     o_dataSUNAStdMedConcNitraMed = cat(1, o_dataSUNAStdMedConcNitraMed, decData{5});
                     
                  case {24, 25}
                     % SUNA (APF)
                     
                     if (sensorDataType == 24)
                        o_dataSUNAAPFDate = cat(1, o_dataSUNAAPFDate, decData{1});
                        o_dataSUNAAPFDateTrans = cat(1, o_dataSUNAAPFDateTrans, decData{2});
                        o_dataSUNAAPFCTDPres = cat(1, o_dataSUNAAPFCTDPres, decData{3});
                        o_dataSUNAAPFCTDTemp = cat(1, o_dataSUNAAPFCTDTemp, decData{4});
                        o_dataSUNAAPFCTDSal = cat(1, o_dataSUNAAPFCTDSal, decData{5});
                        o_dataSUNAAPFIntTemp = cat(1, o_dataSUNAAPFIntTemp, decData{6});
                        o_dataSUNAAPFSpecTemp = cat(1, o_dataSUNAAPFSpecTemp, decData{7});
                        o_dataSUNAAPFIntRelHumidity = cat(1, o_dataSUNAAPFIntRelHumidity, decData{8});
                        o_dataSUNAAPFDarkSpecMean = cat(1, o_dataSUNAAPFDarkSpecMean, decData{9});
                        o_dataSUNAAPFDarkSpecStd = cat(1, o_dataSUNAAPFDarkSpecStd, decData{10});
                        o_dataSUNAAPFSensorNitra = cat(1, o_dataSUNAAPFSensorNitra, decData{11});
                        o_dataSUNAAPFAbsFitRes = cat(1, o_dataSUNAAPFAbsFitRes, decData{12});
                        o_dataSUNAAPFOutSpec = cat(1, o_dataSUNAAPFOutSpec, decData{13});
                     elseif (sensorDataType == 25)
                        o_dataSUNAAPF2Date = cat(1, o_dataSUNAAPF2Date, decData{1});
                        o_dataSUNAAPF2DateTrans = cat(1, o_dataSUNAAPF2DateTrans, decData{2});
                        o_dataSUNAAPF2CTDPres = cat(1, o_dataSUNAAPF2CTDPres, decData{3});
                        o_dataSUNAAPF2CTDTemp = cat(1, o_dataSUNAAPF2CTDTemp, decData{4});
                        o_dataSUNAAPF2CTDSal = cat(1, o_dataSUNAAPF2CTDSal, decData{5});
                        o_dataSUNAAPF2IntTemp = cat(1, o_dataSUNAAPF2IntTemp, decData{6});
                        o_dataSUNAAPF2SpecTemp = cat(1, o_dataSUNAAPF2SpecTemp, decData{7});
                        o_dataSUNAAPF2IntRelHumidity = cat(1, o_dataSUNAAPF2IntRelHumidity, decData{8});
                        o_dataSUNAAPF2DarkSpecMean = cat(1, o_dataSUNAAPF2DarkSpecMean, decData{9});
                        o_dataSUNAAPF2DarkSpecStd = cat(1, o_dataSUNAAPF2DarkSpecStd, decData{10});
                        o_dataSUNAAPF2SensorNitra = cat(1, o_dataSUNAAPF2SensorNitra, decData{11});
                        o_dataSUNAAPF2AbsFitRes = cat(1, o_dataSUNAAPF2AbsFitRes, decData{12});
                        o_dataSUNAAPF2OutSpec = cat(1, o_dataSUNAAPF2OutSpec, decData{13});
                     end
                     
                  case {46, 48}
                     % SEAFET (mean & raw)
                     
                     if (sensorDataType == 46)
                        o_dataSEAFETMeanDate = cat(1, o_dataSEAFETMeanDate, decData{1});
                        o_dataSEAFETMeanDateTrans = cat(1, o_dataSEAFETMeanDateTrans, decData{2});
                        o_dataSEAFETMeanPres = cat(1, o_dataSEAFETMeanPres, decData{3});
                        o_dataSEAFETMeanVref = cat(1, o_dataSEAFETMeanVref, decData{4});
                     elseif (sensorDataType == 48)
                        o_dataSEAFETRawDate = cat(1, o_dataSEAFETRawDate, decData{1});
                        o_dataSEAFETRawDateTrans = cat(1, o_dataSEAFETRawDateTrans, decData{2});
                        o_dataSEAFETRawPres = cat(1, o_dataSEAFETRawPres, decData{3});
                        o_dataSEAFETRawVref = cat(1, o_dataSEAFETRawVref, decData{4});
                     end
                     
                  case {47}
                     % SEAFET (stDev & median)
                     
                     o_dataSEAFETStdMedDate = cat(1, o_dataSEAFETStdMedDate, decData{1});
                     o_dataSEAFETStdMedDateTrans = cat(1, o_dataSEAFETStdMedDateTrans, decData{2});
                     o_dataSEAFETStdMedPresMean = cat(1, o_dataSEAFETStdMedPresMean, decData{3});
                     o_dataSEAFETStdMedVrefStd = cat(1, o_dataSEAFETStdMedVrefStd, decData{4});
                     o_dataSEAFETStdMedVrefMed = cat(1, o_dataSEAFETStdMedVrefMed, decData{5});                     
               end
               
            case 247
               % grounding data

               decData = a_decDataTab(idSbd).decData;
               o_groundingDate = cat(1, o_groundingDate, decData{1});
               o_groundingPres = cat(1, o_groundingPres, decData{2});
               o_groundingSetPoint = cat(1, o_groundingSetPoint, decData{3});
               o_groundingIntVacuum = cat(1, o_groundingIntVacuum, decData{4});

            case 248
               % RUDICS parameters
               
               o_floatProgRudics = cat(1, o_floatProgRudics, a_decDataTab(idSbd).decData);

            case 249
               % sensor parameters

               o_floatProgSensor = cat(1, o_floatProgSensor, a_decDataTab(idSbd).decData);

            case 250
               % sensor tech data
               
               sensorType = a_decDataTab(idSbd).sensorType;
               decData = a_decDataTab(idSbd).decData;
               
               % store ko sensor state
               sensorState = decData{15}(3);
               if (sensorState == 0)
                  g_decArgo_koSensorState = cat(1, g_decArgo_koSensorState, ...
                     [a_decDataTab(idSbd).cyNumRaw a_decDataTab(idSbd).profNumRaw sensorType]);
                  fprintf('DEC_WARNING: Float #%d Cycle #%d: %d type status sensor is Ko\n', ...
                     g_decArgo_floatNum, a_decDataTab(idSbd).cyNumOut, ...
                     sensorType);
               end
               
               switch (sensorType)
                  
                  case 0
                     % CTD
                     
                     o_sensorTechCTDNbPackDesc = cat(1, o_sensorTechCTDNbPackDesc, decData{1});
                     o_sensorTechCTDNbPackDrift = cat(1, o_sensorTechCTDNbPackDrift, decData{2});
                     o_sensorTechCTDNbPackAsc = cat(1, o_sensorTechCTDNbPackAsc, decData{3});
                     o_sensorTechCTDNbMeasDescZ1 = cat(1, o_sensorTechCTDNbMeasDescZ1, decData{4});
                     o_sensorTechCTDNbMeasDescZ2 = cat(1, o_sensorTechCTDNbMeasDescZ2, decData{5});
                     o_sensorTechCTDNbMeasDescZ3 = cat(1, o_sensorTechCTDNbMeasDescZ3, decData{6});
                     o_sensorTechCTDNbMeasDescZ4 = cat(1, o_sensorTechCTDNbMeasDescZ4, decData{7});
                     o_sensorTechCTDNbMeasDescZ5 = cat(1, o_sensorTechCTDNbMeasDescZ5, decData{8});
                     o_sensorTechCTDNbMeasDrift = cat(1, o_sensorTechCTDNbMeasDrift, decData{9});
                     o_sensorTechCTDNbMeasAscZ1 = cat(1, o_sensorTechCTDNbMeasAscZ1, decData{10});
                     o_sensorTechCTDNbMeasAscZ2 = cat(1, o_sensorTechCTDNbMeasAscZ2, decData{11});
                     o_sensorTechCTDNbMeasAscZ3 = cat(1, o_sensorTechCTDNbMeasAscZ3, decData{12});
                     o_sensorTechCTDNbMeasAscZ4 = cat(1, o_sensorTechCTDNbMeasAscZ4, decData{13});
                     o_sensorTechCTDNbMeasAscZ5 = cat(1, o_sensorTechCTDNbMeasAscZ5, decData{14});
                     o_sensorTechCTDSensorState = cat(1, o_sensorTechCTDSensorState, decData{15});
                     o_sensorTechCTDOffsetPres = cat(1, o_sensorTechCTDOffsetPres, decData{16});
                     o_sensorTechCTDSubPres = cat(1, o_sensorTechCTDSubPres, decData{17});
                     o_sensorTechCTDSubTemp = cat(1, o_sensorTechCTDSubTemp, decData{18});
                     o_sensorTechCTDSubSal = cat(1, o_sensorTechCTDSubSal, decData{19});
                     
                  case 1
                     % OPTODE
                     
                     o_sensorTechOPTODENbPackDesc = cat(1, o_sensorTechOPTODENbPackDesc, decData{1});
                     o_sensorTechOPTODENbPackDrift = cat(1, o_sensorTechOPTODENbPackDrift, decData{2});
                     o_sensorTechOPTODENbPackAsc = cat(1, o_sensorTechOPTODENbPackAsc, decData{3});
                     o_sensorTechOPTODENbMeasDescZ1 = cat(1, o_sensorTechOPTODENbMeasDescZ1, decData{4});
                     o_sensorTechOPTODENbMeasDescZ2 = cat(1, o_sensorTechOPTODENbMeasDescZ2, decData{5});
                     o_sensorTechOPTODENbMeasDescZ3 = cat(1, o_sensorTechOPTODENbMeasDescZ3, decData{6});
                     o_sensorTechOPTODENbMeasDescZ4 = cat(1, o_sensorTechOPTODENbMeasDescZ4, decData{7});
                     o_sensorTechOPTODENbMeasDescZ5 = cat(1, o_sensorTechOPTODENbMeasDescZ5, decData{8});
                     o_sensorTechOPTODENbMeasDrift = cat(1, o_sensorTechOPTODENbMeasDrift, decData{9});
                     o_sensorTechOPTODENbMeasAscZ1 = cat(1, o_sensorTechOPTODENbMeasAscZ1, decData{10});
                     o_sensorTechOPTODENbMeasAscZ2 = cat(1, o_sensorTechOPTODENbMeasAscZ2, decData{11});
                     o_sensorTechOPTODENbMeasAscZ3 = cat(1, o_sensorTechOPTODENbMeasAscZ3, decData{12});
                     o_sensorTechOPTODENbMeasAscZ4 = cat(1, o_sensorTechOPTODENbMeasAscZ4, decData{13});
                     o_sensorTechOPTODENbMeasAscZ5 = cat(1, o_sensorTechOPTODENbMeasAscZ5, decData{14});
                     o_sensorTechOPTODESensorState = cat(1, o_sensorTechOPTODESensorState, decData{15});
                     o_sensorTechOPTODESensorSerialNum = cat(1, o_sensorTechOPTODESensorSerialNum, decData{16});
                     
                  case 2
                     % OCR
                     
                     o_sensorTechOCRNbPackDesc = cat(1, o_sensorTechOCRNbPackDesc, decData{1});
                     o_sensorTechOCRNbPackDrift = cat(1, o_sensorTechOCRNbPackDrift, decData{2});
                     o_sensorTechOCRNbPackAsc = cat(1, o_sensorTechOCRNbPackAsc, decData{3});
                     o_sensorTechOCRNbMeasDescZ1 = cat(1, o_sensorTechOCRNbMeasDescZ1, decData{4});
                     o_sensorTechOCRNbMeasDescZ2 = cat(1, o_sensorTechOCRNbMeasDescZ2, decData{5});
                     o_sensorTechOCRNbMeasDescZ3 = cat(1, o_sensorTechOCRNbMeasDescZ3, decData{6});
                     o_sensorTechOCRNbMeasDescZ4 = cat(1, o_sensorTechOCRNbMeasDescZ4, decData{7});
                     o_sensorTechOCRNbMeasDescZ5 = cat(1, o_sensorTechOCRNbMeasDescZ5, decData{8});
                     o_sensorTechOCRNbMeasDrift = cat(1, o_sensorTechOCRNbMeasDrift, decData{9});
                     o_sensorTechOCRNbMeasAscZ1 = cat(1, o_sensorTechOCRNbMeasAscZ1, decData{10});
                     o_sensorTechOCRNbMeasAscZ2 = cat(1, o_sensorTechOCRNbMeasAscZ2, decData{11});
                     o_sensorTechOCRNbMeasAscZ3 = cat(1, o_sensorTechOCRNbMeasAscZ3, decData{12});
                     o_sensorTechOCRNbMeasAscZ4 = cat(1, o_sensorTechOCRNbMeasAscZ4, decData{13});
                     o_sensorTechOCRNbMeasAscZ5 = cat(1, o_sensorTechOCRNbMeasAscZ5, decData{14});
                     o_sensorTechOCRSensorState = cat(1, o_sensorTechOCRSensorState, decData{15});
                     o_sensorTechOCRSensorSerialNum = cat(1, o_sensorTechOCRSensorSerialNum, decData{16});
                     o_sensorTechOCRCoefLambda1A0 = cat(1, o_sensorTechOCRCoefLambda1A0, decData{17});
                     o_sensorTechOCRCoefLambda1A1 = cat(1, o_sensorTechOCRCoefLambda1A1, decData{18});
                     o_sensorTechOCRCoefLambda1Lm = cat(1, o_sensorTechOCRCoefLambda1Lm, decData{19});
                     o_sensorTechOCRCoefLambda2A0 = cat(1, o_sensorTechOCRCoefLambda2A0, decData{20});
                     o_sensorTechOCRCoefLambda2A1 = cat(1, o_sensorTechOCRCoefLambda2A1, decData{21});
                     o_sensorTechOCRCoefLambda2Lm = cat(1, o_sensorTechOCRCoefLambda2Lm, decData{22});
                     o_sensorTechOCRCoefLambda3A0 = cat(1, o_sensorTechOCRCoefLambda3A0, decData{23});
                     o_sensorTechOCRCoefLambda3A1 = cat(1, o_sensorTechOCRCoefLambda3A1, decData{24});
                     o_sensorTechOCRCoefLambda3Lm = cat(1, o_sensorTechOCRCoefLambda3Lm, decData{25});
                     o_sensorTechOCRCoefParA0 = cat(1, o_sensorTechOCRCoefParA0, decData{26});
                     o_sensorTechOCRCoefParA1 = cat(1, o_sensorTechOCRCoefParA1, decData{27});
                     o_sensorTechOCRCoefParLm = cat(1, o_sensorTechOCRCoefParLm, decData{28});
                     
                  case 3
                     % ECO2 or ECO3
                     
                     if (ismember('ECO2', g_decArgo_sensorMountedOnFloat))
                        
                        % ECO2
                        o_sensorTechECO2NbPackDesc = cat(1, o_sensorTechECO2NbPackDesc, decData{1});
                        o_sensorTechECO2NbPackDrift = cat(1, o_sensorTechECO2NbPackDrift, decData{2});
                        o_sensorTechECO2NbPackAsc = cat(1, o_sensorTechECO2NbPackAsc, decData{3});
                        o_sensorTechECO2NbMeasDescZ1 = cat(1, o_sensorTechECO2NbMeasDescZ1, decData{4});
                        o_sensorTechECO2NbMeasDescZ2 = cat(1, o_sensorTechECO2NbMeasDescZ2, decData{5});
                        o_sensorTechECO2NbMeasDescZ3 = cat(1, o_sensorTechECO2NbMeasDescZ3, decData{6});
                        o_sensorTechECO2NbMeasDescZ4 = cat(1, o_sensorTechECO2NbMeasDescZ4, decData{7});
                        o_sensorTechECO2NbMeasDescZ5 = cat(1, o_sensorTechECO2NbMeasDescZ5, decData{8});
                        o_sensorTechECO2NbMeasDrift = cat(1, o_sensorTechECO2NbMeasDrift, decData{9});
                        o_sensorTechECO2NbMeasAscZ1 = cat(1, o_sensorTechECO2NbMeasAscZ1, decData{10});
                        o_sensorTechECO2NbMeasAscZ2 = cat(1, o_sensorTechECO2NbMeasAscZ2, decData{11});
                        o_sensorTechECO2NbMeasAscZ3 = cat(1, o_sensorTechECO2NbMeasAscZ3, decData{12});
                        o_sensorTechECO2NbMeasAscZ4 = cat(1, o_sensorTechECO2NbMeasAscZ4, decData{13});
                        o_sensorTechECO2NbMeasAscZ5 = cat(1, o_sensorTechECO2NbMeasAscZ5, decData{14});
                        o_sensorTechECO2SensorState = cat(1, o_sensorTechECO2SensorState, decData{15});
                        o_sensorTechECO2SensorSerialNum = cat(1, o_sensorTechECO2SensorSerialNum, decData{16});
                        o_sensorTechECO2CoefScaleFactChloroA = cat(1, o_sensorTechECO2CoefScaleFactChloroA, decData{17});
                        o_sensorTechECO2CoefDarkCountChloroA = cat(1, o_sensorTechECO2CoefDarkCountChloroA, decData{18});
                        o_sensorTechECO2CoefScaleFactBackscat = cat(1, o_sensorTechECO2CoefScaleFactBackscat, decData{19});
                        o_sensorTechECO2CoefDarkCountBackscat = cat(1, o_sensorTechECO2CoefDarkCountBackscat, decData{20});
                        
                     elseif (ismember('ECO3', g_decArgo_sensorMountedOnFloat))
                        
                        % ECO3
                        o_sensorTechECO3NbPackDesc = cat(1, o_sensorTechECO3NbPackDesc, decData{1});
                        o_sensorTechECO3NbPackDrift = cat(1, o_sensorTechECO3NbPackDrift, decData{2});
                        o_sensorTechECO3NbPackAsc = cat(1, o_sensorTechECO3NbPackAsc, decData{3});
                        o_sensorTechECO3NbMeasDescZ1 = cat(1, o_sensorTechECO3NbMeasDescZ1, decData{4});
                        o_sensorTechECO3NbMeasDescZ2 = cat(1, o_sensorTechECO3NbMeasDescZ2, decData{5});
                        o_sensorTechECO3NbMeasDescZ3 = cat(1, o_sensorTechECO3NbMeasDescZ3, decData{6});
                        o_sensorTechECO3NbMeasDescZ4 = cat(1, o_sensorTechECO3NbMeasDescZ4, decData{7});
                        o_sensorTechECO3NbMeasDescZ5 = cat(1, o_sensorTechECO3NbMeasDescZ5, decData{8});
                        o_sensorTechECO3NbMeasDrift = cat(1, o_sensorTechECO3NbMeasDrift, decData{9});
                        o_sensorTechECO3NbMeasAscZ1 = cat(1, o_sensorTechECO3NbMeasAscZ1, decData{10});
                        o_sensorTechECO3NbMeasAscZ2 = cat(1, o_sensorTechECO3NbMeasAscZ2, decData{11});
                        o_sensorTechECO3NbMeasAscZ3 = cat(1, o_sensorTechECO3NbMeasAscZ3, decData{12});
                        o_sensorTechECO3NbMeasAscZ4 = cat(1, o_sensorTechECO3NbMeasAscZ4, decData{13});
                        o_sensorTechECO3NbMeasAscZ5 = cat(1, o_sensorTechECO3NbMeasAscZ5, decData{14});
                        o_sensorTechECO3SensorState = cat(1, o_sensorTechECO3SensorState, decData{15});
                        o_sensorTechECO3SensorSerialNum = cat(1, o_sensorTechECO3SensorSerialNum, decData{16});
                        o_sensorTechECO3CoefScaleFactChloroA = cat(1, o_sensorTechECO3CoefScaleFactChloroA, decData{17});
                        o_sensorTechECO3CoefDarkCountChloroA = cat(1, o_sensorTechECO3CoefDarkCountChloroA, decData{18});
                        o_sensorTechECO3CoefScaleFactBackscat = cat(1, o_sensorTechECO3CoefScaleFactBackscat, decData{19});
                        o_sensorTechECO3CoefDarkCountBackscat = cat(1, o_sensorTechECO3CoefDarkCountBackscat, decData{20});
                        o_sensorTechECO3CoefScaleFactCdom = cat(1, o_sensorTechECO3CoefScaleFactCdom, decData{21});
                        o_sensorTechECO3CoefDarkCountCdom = cat(1, o_sensorTechECO3CoefDarkCountCdom, decData{22});
                     end
                     
                  case 4
                     % FLNTU or SEAFET
                     
                     if (ismember('FLNTU', g_decArgo_sensorMountedOnFloat))

                        % FLNTU
                        o_sensorTechFLNTUNbPackDesc = cat(1, o_sensorTechFLNTUNbPackDesc, decData{1});
                        o_sensorTechFLNTUNbPackDrift = cat(1, o_sensorTechFLNTUNbPackDrift, decData{2});
                        o_sensorTechFLNTUNbPackAsc = cat(1, o_sensorTechFLNTUNbPackAsc, decData{3});
                        o_sensorTechFLNTUNbMeasDescZ1 = cat(1, o_sensorTechFLNTUNbMeasDescZ1, decData{4});
                        o_sensorTechFLNTUNbMeasDescZ2 = cat(1, o_sensorTechFLNTUNbMeasDescZ2, decData{5});
                        o_sensorTechFLNTUNbMeasDescZ3 = cat(1, o_sensorTechFLNTUNbMeasDescZ3, decData{6});
                        o_sensorTechFLNTUNbMeasDescZ4 = cat(1, o_sensorTechFLNTUNbMeasDescZ4, decData{7});
                        o_sensorTechFLNTUNbMeasDescZ5 = cat(1, o_sensorTechFLNTUNbMeasDescZ5, decData{8});
                        o_sensorTechFLNTUNbMeasDrift = cat(1, o_sensorTechFLNTUNbMeasDrift, decData{9});
                        o_sensorTechFLNTUNbMeasAscZ1 = cat(1, o_sensorTechFLNTUNbMeasAscZ1, decData{10});
                        o_sensorTechFLNTUNbMeasAscZ2 = cat(1, o_sensorTechFLNTUNbMeasAscZ2, decData{11});
                        o_sensorTechFLNTUNbMeasAscZ3 = cat(1, o_sensorTechFLNTUNbMeasAscZ3, decData{12});
                        o_sensorTechFLNTUNbMeasAscZ4 = cat(1, o_sensorTechFLNTUNbMeasAscZ4, decData{13});
                        o_sensorTechFLNTUNbMeasAscZ5 = cat(1, o_sensorTechFLNTUNbMeasAscZ5, decData{14});
                        o_sensorTechFLNTUSensorState = cat(1, o_sensorTechFLNTUSensorState, decData{15});
                        o_sensorTechFLNTUCoefScaleChloro = cat(1, o_sensorTechFLNTUCoefScaleChloro, decData{16});
                        o_sensorTechFLNTUDarkCountChloro = cat(1, o_sensorTechFLNTUDarkCountChloro, decData{17});
                        o_sensorTechFLNTUCoefScaleTurbi = cat(1, o_sensorTechFLNTUCoefScaleTurbi, decData{18});
                        o_sensorTechFLNTUDarkCountTurbi = cat(1, o_sensorTechFLNTUDarkCountTurbi, decData{19});
                        
                     elseif (ismember('TRANSISTOR_PH', g_decArgo_sensorMountedOnFloat))
                        
                        % SEAFET
                        o_sensorTechSEAFETNbPackDesc = cat(1, o_sensorTechSEAFETNbPackDesc, decData{1});
                        o_sensorTechSEAFETNbPackDrift = cat(1, o_sensorTechSEAFETNbPackDrift, decData{2});
                        o_sensorTechSEAFETNbPackAsc = cat(1, o_sensorTechSEAFETNbPackAsc, decData{3});
                        o_sensorTechSEAFETNbMeasDescZ1 = cat(1, o_sensorTechSEAFETNbMeasDescZ1, decData{4});
                        o_sensorTechSEAFETNbMeasDescZ2 = cat(1, o_sensorTechSEAFETNbMeasDescZ2, decData{5});
                        o_sensorTechSEAFETNbMeasDescZ3 = cat(1, o_sensorTechSEAFETNbMeasDescZ3, decData{6});
                        o_sensorTechSEAFETNbMeasDescZ4 = cat(1, o_sensorTechSEAFETNbMeasDescZ4, decData{7});
                        o_sensorTechSEAFETNbMeasDescZ5 = cat(1, o_sensorTechSEAFETNbMeasDescZ5, decData{8});
                        o_sensorTechSEAFETNbMeasDrift = cat(1, o_sensorTechSEAFETNbMeasDrift, decData{9});
                        o_sensorTechSEAFETNbMeasAscZ1 = cat(1, o_sensorTechSEAFETNbMeasAscZ1, decData{10});
                        o_sensorTechSEAFETNbMeasAscZ2 = cat(1, o_sensorTechSEAFETNbMeasAscZ2, decData{11});
                        o_sensorTechSEAFETNbMeasAscZ3 = cat(1, o_sensorTechSEAFETNbMeasAscZ3, decData{12});
                        o_sensorTechSEAFETNbMeasAscZ4 = cat(1, o_sensorTechSEAFETNbMeasAscZ4, decData{13});
                        o_sensorTechSEAFETNbMeasAscZ5 = cat(1, o_sensorTechSEAFETNbMeasAscZ5, decData{14});
                        o_sensorTechSEAFETSensorState = cat(1, o_sensorTechSEAFETSensorState, decData{15});
                        o_sensorTechSEAFETSensorSerialNum = cat(1, o_sensorTechSEAFETSensorSerialNum, decData{16});
                     end
                     
                  case 5
                     % CROVER
                     
                     o_sensorTechCROVERNbPackDesc = cat(1, o_sensorTechCROVERNbPackDesc, decData{1});
                     o_sensorTechCROVERNbPackDrift = cat(1, o_sensorTechCROVERNbPackDrift, decData{2});
                     o_sensorTechCROVERNbPackAsc = cat(1, o_sensorTechCROVERNbPackAsc, decData{3});
                     o_sensorTechCROVERNbMeasDescZ1 = cat(1, o_sensorTechCROVERNbMeasDescZ1, decData{4});
                     o_sensorTechCROVERNbMeasDescZ2 = cat(1, o_sensorTechCROVERNbMeasDescZ2, decData{5});
                     o_sensorTechCROVERNbMeasDescZ3 = cat(1, o_sensorTechCROVERNbMeasDescZ3, decData{6});
                     o_sensorTechCROVERNbMeasDescZ4 = cat(1, o_sensorTechCROVERNbMeasDescZ4, decData{7});
                     o_sensorTechCROVERNbMeasDescZ5 = cat(1, o_sensorTechCROVERNbMeasDescZ5, decData{8});
                     o_sensorTechCROVERNbMeasDrift = cat(1, o_sensorTechCROVERNbMeasDrift, decData{9});
                     o_sensorTechCROVERNbMeasAscZ1 = cat(1, o_sensorTechCROVERNbMeasAscZ1, decData{10});
                     o_sensorTechCROVERNbMeasAscZ2 = cat(1, o_sensorTechCROVERNbMeasAscZ2, decData{11});
                     o_sensorTechCROVERNbMeasAscZ3 = cat(1, o_sensorTechCROVERNbMeasAscZ3, decData{12});
                     o_sensorTechCROVERNbMeasAscZ4 = cat(1, o_sensorTechCROVERNbMeasAscZ4, decData{13});
                     o_sensorTechCROVERNbMeasAscZ5 = cat(1, o_sensorTechCROVERNbMeasAscZ5, decData{14});
                     o_sensorTechCROVERSensorState = cat(1, o_sensorTechCROVERSensorState, decData{15});
                     o_sensorTechCROVERSensorSerialNum = cat(1, o_sensorTechCROVERSensorSerialNum, decData{16});
                     
                  case 6
                     % SUNA
                     
                     o_sensorTechSUNANbPackDesc = cat(1, o_sensorTechSUNANbPackDesc, decData{1});
                     o_sensorTechSUNANbPackDrift = cat(1, o_sensorTechSUNANbPackDrift, decData{2});
                     o_sensorTechSUNANbPackAsc = cat(1, o_sensorTechSUNANbPackAsc, decData{3});
                     o_sensorTechSUNANbMeasDescZ1 = cat(1, o_sensorTechSUNANbMeasDescZ1, decData{4});
                     o_sensorTechSUNANbMeasDescZ2 = cat(1, o_sensorTechSUNANbMeasDescZ2, decData{5});
                     o_sensorTechSUNANbMeasDescZ3 = cat(1, o_sensorTechSUNANbMeasDescZ3, decData{6});
                     o_sensorTechSUNANbMeasDescZ4 = cat(1, o_sensorTechSUNANbMeasDescZ4, decData{7});
                     o_sensorTechSUNANbMeasDescZ5 = cat(1, o_sensorTechSUNANbMeasDescZ5, decData{8});
                     o_sensorTechSUNANbMeasDrift = cat(1, o_sensorTechSUNANbMeasDrift, decData{9});
                     o_sensorTechSUNANbMeasAscZ1 = cat(1, o_sensorTechSUNANbMeasAscZ1, decData{10});
                     o_sensorTechSUNANbMeasAscZ2 = cat(1, o_sensorTechSUNANbMeasAscZ2, decData{11});
                     o_sensorTechSUNANbMeasAscZ3 = cat(1, o_sensorTechSUNANbMeasAscZ3, decData{12});
                     o_sensorTechSUNANbMeasAscZ4 = cat(1, o_sensorTechSUNANbMeasAscZ4, decData{13});
                     o_sensorTechSUNANbMeasAscZ5 = cat(1, o_sensorTechSUNANbMeasAscZ5, decData{14});
                     o_sensorTechSUNASensorState = cat(1, o_sensorTechSUNASensorState, decData{15});
                     o_sensorTechSUNASensorSerialNum = cat(1, o_sensorTechSUNASensorSerialNum, decData{16});
                     o_sensorTechSUNAAPFSampCounter = cat(1, o_sensorTechSUNAAPFSampCounter, decData{17});
                     o_sensorTechSUNAAPFPowerCycleCounter = cat(1, o_sensorTechSUNAAPFPowerCycleCounter, decData{18});
                     o_sensorTechSUNAAPFErrorCounter = cat(1, o_sensorTechSUNAAPFErrorCounter, decData{19});
                     o_sensorTechSUNAAPFSupplyVoltage = cat(1, o_sensorTechSUNAAPFSupplyVoltage, decData{20});
                     o_sensorTechSUNAAPFSupplyCurrent = cat(1, o_sensorTechSUNAAPFSupplyCurrent, decData{21});
                     o_sensorTechSUNAAPFOutPixelBegin = cat(1, o_sensorTechSUNAAPFOutPixelBegin, decData{22});
                     o_sensorTechSUNAAPFOutPixelEnd = cat(1, o_sensorTechSUNAAPFOutPixelEnd, decData{23});
               end
               
            case 252
               % float pressure data
               
               decData = a_decDataTab(idSbd).decData;
               o_floatPresPumpOrEv = cat(1, o_floatPresPumpOrEv, decData{1});
               o_floatPresActPres = cat(1, o_floatPresActPres, decData{2});
               o_floatPresActTime = cat(1, o_floatPresActTime, decData{3});
               o_floatPresActDuration = cat(1, o_floatPresActDuration, decData{4});
               
            case 253
               % float technical data

               o_tabTech = cat(1, o_tabTech, a_decDataTab(idSbd).decData);
                              
            case 254
               % float prog technical data

               o_floatProgTech = cat(1, o_floatProgTech, a_decDataTab(idSbd).decData);
               
            case 255
               % float prog param data
               
               o_floatProgParam = cat(1, o_floatProgParam, a_decDataTab(idSbd).decData);
         end
      end

otherwise
   fprintf('WARNING: Float #%d: Nothing implemented yet in get_decoded_data_cts4 for decoderId #%d\n', ...
      g_decArgo_floatNum, ...
      a_decoderId);
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

o_dataECO2Mean{1} = o_dataECO2MeanDate;
o_dataECO2Mean{2} = o_dataECO2MeanDateTrans;
o_dataECO2Mean{3} = o_dataECO2MeanPres;
o_dataECO2Mean{4} = o_dataECO2MeanChloroA;
o_dataECO2Mean{5} = o_dataECO2MeanBackscat;

o_dataECO2Raw{1} = o_dataECO2RawDate;
o_dataECO2Raw{2} = o_dataECO2RawDateTrans;
o_dataECO2Raw{3} = o_dataECO2RawPres;
o_dataECO2Raw{4} = o_dataECO2RawChloroA;
o_dataECO2Raw{5} = o_dataECO2RawBackscat;

o_dataECO2StdMed{1} = o_dataECO2StdMedDate;
o_dataECO2StdMed{2} = o_dataECO2StdMedDateTrans;
o_dataECO2StdMed{3} = o_dataECO2StdMedPresMean;
o_dataECO2StdMed{4} = o_dataECO2StdMedChloroAStd;
o_dataECO2StdMed{5} = o_dataECO2StdMedBackscatStd;
o_dataECO2StdMed{6} = o_dataECO2StdMedChloroAMed;
o_dataECO2StdMed{7} = o_dataECO2StdMedBackscatMed;

o_dataECO2{1} = o_dataECO2Mean;
o_dataECO2{2} = o_dataECO2Raw;
o_dataECO2{3} = o_dataECO2StdMed;

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

o_dataSEAFETMean{1} = o_dataSEAFETMeanDate;
o_dataSEAFETMean{2} = o_dataSEAFETMeanDateTrans;
o_dataSEAFETMean{3} = o_dataSEAFETMeanPres;
o_dataSEAFETMean{4} = o_dataSEAFETMeanVref;

o_dataSEAFETRaw{1} = o_dataSEAFETRawDate;
o_dataSEAFETRaw{2} = o_dataSEAFETRawDateTrans;
o_dataSEAFETRaw{3} = o_dataSEAFETRawPres;
o_dataSEAFETRaw{4} = o_dataSEAFETRawVref;

o_dataSEAFETStdMed{1} = o_dataSEAFETStdMedDate;
o_dataSEAFETStdMed{2} = o_dataSEAFETStdMedDateTrans;
o_dataSEAFETStdMed{3} = o_dataSEAFETStdMedPresMean;
o_dataSEAFETStdMed{4} = o_dataSEAFETStdMedVrefStd;
o_dataSEAFETStdMed{5} = o_dataSEAFETStdMedVrefMed;

o_dataSEAFET{1} = o_dataSEAFETMean;
o_dataSEAFET{2} = o_dataSEAFETRaw;
o_dataSEAFET{3} = o_dataSEAFETStdMed;

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
o_sensorTechOPTODE{16} = o_sensorTechOPTODESensorSerialNum;

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

o_sensorTechECO2{1} = o_sensorTechECO2NbPackDesc;
o_sensorTechECO2{2} = o_sensorTechECO2NbPackDrift;
o_sensorTechECO2{3} = o_sensorTechECO2NbPackAsc;
o_sensorTechECO2{4} = o_sensorTechECO2NbMeasDescZ1;
o_sensorTechECO2{5} = o_sensorTechECO2NbMeasDescZ2;
o_sensorTechECO2{6} = o_sensorTechECO2NbMeasDescZ3;
o_sensorTechECO2{7} = o_sensorTechECO2NbMeasDescZ4;
o_sensorTechECO2{8} = o_sensorTechECO2NbMeasDescZ5;
o_sensorTechECO2{9} = o_sensorTechECO2NbMeasDrift;
o_sensorTechECO2{10} = o_sensorTechECO2NbMeasAscZ1;
o_sensorTechECO2{11} = o_sensorTechECO2NbMeasAscZ2;
o_sensorTechECO2{12} = o_sensorTechECO2NbMeasAscZ3;
o_sensorTechECO2{13} = o_sensorTechECO2NbMeasAscZ4;
o_sensorTechECO2{14} = o_sensorTechECO2NbMeasAscZ5;
o_sensorTechECO2{15} = o_sensorTechECO2SensorState;
o_sensorTechECO2{16} = o_sensorTechECO2SensorSerialNum;
o_sensorTechECO2{17} = o_sensorTechECO2CoefScaleFactChloroA;
o_sensorTechECO2{18} = o_sensorTechECO2CoefDarkCountChloroA;
o_sensorTechECO2{19} = o_sensorTechECO2CoefScaleFactBackscat;
o_sensorTechECO2{20} = o_sensorTechECO2CoefDarkCountBackscat;

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

o_sensorTechSEAFET{1} = o_sensorTechSEAFETNbPackDesc;
o_sensorTechSEAFET{2} = o_sensorTechSEAFETNbPackDrift;
o_sensorTechSEAFET{3} = o_sensorTechSEAFETNbPackAsc;
o_sensorTechSEAFET{4} = o_sensorTechSEAFETNbMeasDescZ1;
o_sensorTechSEAFET{5} = o_sensorTechSEAFETNbMeasDescZ2;
o_sensorTechSEAFET{6} = o_sensorTechSEAFETNbMeasDescZ3;
o_sensorTechSEAFET{7} = o_sensorTechSEAFETNbMeasDescZ4;
o_sensorTechSEAFET{8} = o_sensorTechSEAFETNbMeasDescZ5;
o_sensorTechSEAFET{9} = o_sensorTechSEAFETNbMeasDrift;
o_sensorTechSEAFET{10} = o_sensorTechSEAFETNbMeasAscZ1;
o_sensorTechSEAFET{11} = o_sensorTechSEAFETNbMeasAscZ2;
o_sensorTechSEAFET{12} = o_sensorTechSEAFETNbMeasAscZ3;
o_sensorTechSEAFET{13} = o_sensorTechSEAFETNbMeasAscZ4;
o_sensorTechSEAFET{14} = o_sensorTechSEAFETNbMeasAscZ5;
o_sensorTechSEAFET{15} = o_sensorTechSEAFETSensorState;
o_sensorTechSEAFET{16} = o_sensorTechSEAFETSensorSerialNum;

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

if (~isempty(o_floatPresPumpOrEv))
   o_floatPres{1} = o_floatPresPumpOrEv;
   o_floatPres{2} = o_floatPresActPres;
   o_floatPres{3} = o_floatPresActTime;
   o_floatPres{4} = o_floatPresActDuration;
end

if (~isempty(o_groundingDate))
   o_grounding{1} = o_groundingDate;
   o_grounding{2} = o_groundingPres;
   o_grounding{3} = o_groundingSetPoint;
   o_grounding{4} = o_groundingIntVacuum;
end

return
