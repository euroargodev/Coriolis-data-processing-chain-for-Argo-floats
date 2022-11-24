% ------------------------------------------------------------------------------
% Add the dates of the drift measurements.
%
% SYNTAX :
%  [o_dataCTD, o_dataOXY, o_dataOCR, o_dataECO2, o_dataECO3, o_dataFLNTU, ...
%    o_dataCROVER, o_dataSUNA, o_dataSEAFET, o_measDates] = ...
%    add_drift_meas_dates_ir_rudics_111_113(a_decoderId, ...
%    a_dataCTD, a_dataOXY, a_dataOCR, ...
%    a_dataECO2, a_dataECO3, a_dataFLNTU, ...
%    a_dataCROVER, a_dataSUNA, a_dataSEAFET)
%
% INPUT PARAMETERS :
%   a_dataCTD    : input CTD data
%   a_dataOXY    : input OXY data
%   a_dataOCR    : input OCR data
%   a_dataECO2   : input ECO2 data
%   a_dataECO3   : input ECO3 data
%   a_dataFLNTU  : input FLNTU data
%   a_dataCROVER : input cROVER data
%   a_dataSUNA   : input SUNA data
%   a_dataSEAFET : input SEAFET data
%
% OUTPUT PARAMETERS :
%   a_decoderId  : float decoder Id
%   o_dataCTD    : output CTD data
%   o_dataOXY    : output OXY data
%   o_dataOCR    : output OCR data
%   o_dataECO2   : output ECO2 data
%   o_dataECO3   : output ECO3 data
%   o_dataFLNTU  : output FLNTU data
%   o_dataCROVER : output cROVER data
%   o_dataSUNA   : output SUNA data
%   o_dataSEAFET : output SEAFET data
%   o_measDates  : measurement dates transmitted by the float
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataCTD, o_dataOXY, o_dataOCR, o_dataECO2, o_dataECO3, o_dataFLNTU, ...
   o_dataCROVER, o_dataSUNA, o_dataSEAFET, o_measDates] = ...
   add_drift_meas_dates_ir_rudics_111_113(a_decoderId, ...
   a_dataCTD, a_dataOXY, a_dataOCR, ...
   a_dataECO2, a_dataECO3, a_dataFLNTU, ...
   a_dataCROVER, a_dataSUNA, a_dataSEAFET)
            
% cycle phases
global g_decArgo_phaseParkDrift;


% output parameters initialization
o_dataCTD = [];
o_dataOXY = [];
o_dataOCR = [];
o_dataECO2 = [];
o_dataECO3 = [];
o_dataFLNTU = [];
o_dataCROVER = [];
o_dataSUNA = [];
o_dataSEAFET = [];
o_measDates = [];

% unpack the input data
a_dataCTDMean = a_dataCTD{1};
a_dataCTDRaw = a_dataCTD{2};
a_dataCTDStdMed = a_dataCTD{3};

a_dataCTDMeanDate = a_dataCTDMean{1};
a_dataCTDMeanDateTrans = a_dataCTDMean{2};
a_dataCTDMeanPres = a_dataCTDMean{3};
a_dataCTDMeanTemp = a_dataCTDMean{4};
a_dataCTDMeanSal = a_dataCTDMean{5};

a_dataCTDStdMedDate = a_dataCTDStdMed{1};
a_dataCTDStdMedDateTrans = a_dataCTDStdMed{2};
a_dataCTDStdMedPresMean  = a_dataCTDStdMed{3};
a_dataCTDStdMedTempStd  = a_dataCTDStdMed{4};
a_dataCTDStdMedSalStd  = a_dataCTDStdMed{5};
a_dataCTDStdMedPresMed  = a_dataCTDStdMed{6};
a_dataCTDStdMedTempMed  = a_dataCTDStdMed{7};
a_dataCTDStdMedSalMed  = a_dataCTDStdMed{8};

a_dataCTDRawDate = a_dataCTDRaw{1};
a_dataCTDRawDateTrans = a_dataCTDRaw{2};
a_dataCTDRawPres = a_dataCTDRaw{3};
a_dataCTDRawTemp = a_dataCTDRaw{4};
a_dataCTDRawSal = a_dataCTDRaw{5};

a_dataOXYMean = a_dataOXY{1};
a_dataOXYRaw = a_dataOXY{2};
a_dataOXYStdMed = a_dataOXY{3};

a_dataOXYMeanDate = a_dataOXYMean{1};
a_dataOXYMeanDateTrans = a_dataOXYMean{2};
a_dataOXYMeanPres = a_dataOXYMean{3};
a_dataOXYMeanC1Phase = a_dataOXYMean{4};
a_dataOXYMeanC2Phase = a_dataOXYMean{5};
a_dataOXYMeanTemp = a_dataOXYMean{6};

a_dataOXYStdMedDate = a_dataOXYStdMed{1};
a_dataOXYStdMedDateTrans = a_dataOXYStdMed{2};
a_dataOXYStdMedPresMean = a_dataOXYStdMed{3};
a_dataOXYStdMedC1PhaseStd = a_dataOXYStdMed{4};
a_dataOXYStdMedC2PhaseStd = a_dataOXYStdMed{5};
a_dataOXYStdMedTempStd = a_dataOXYStdMed{6};
a_dataOXYStdMedC1PhaseMed = a_dataOXYStdMed{7};
a_dataOXYStdMedC2PhaseMed = a_dataOXYStdMed{8};
a_dataOXYStdMedTempMed = a_dataOXYStdMed{9};

a_dataOXYRawDate = a_dataOXYRaw{1};
a_dataOXYRawDateTrans = a_dataOXYRaw{2};
a_dataOXYRawPres = a_dataOXYRaw{3};
a_dataOXYRawC1Phase = a_dataOXYRaw{4};
a_dataOXYRawC2Phase = a_dataOXYRaw{5};
a_dataOXYRawTemp = a_dataOXYRaw{6};

a_dataOCRMean = a_dataOCR{1};
a_dataOCRRaw = a_dataOCR{2};
a_dataOCRStdMed = a_dataOCR{3};

a_dataOCRMeanDate = a_dataOCRMean{1};
a_dataOCRMeanDateTrans = a_dataOCRMean{2};
a_dataOCRMeanPres = a_dataOCRMean{3};
a_dataOCRMeanIr1 = a_dataOCRMean{4};
a_dataOCRMeanIr2 = a_dataOCRMean{5};
a_dataOCRMeanIr3 = a_dataOCRMean{6};
a_dataOCRMeanIr4 = a_dataOCRMean{7};

a_dataOCRStdMedDate = a_dataOCRStdMed{1};
a_dataOCRStdMedDateTrans = a_dataOCRStdMed{2};
a_dataOCRStdMedPresMean = a_dataOCRStdMed{3};
a_dataOCRStdMedIr1Std = a_dataOCRStdMed{4};
a_dataOCRStdMedIr2Std = a_dataOCRStdMed{5};
a_dataOCRStdMedIr3Std = a_dataOCRStdMed{6};
a_dataOCRStdMedIr4Std = a_dataOCRStdMed{7};
a_dataOCRStdMedIr1Med = a_dataOCRStdMed{8};
a_dataOCRStdMedIr2Med = a_dataOCRStdMed{9};
a_dataOCRStdMedIr3Med = a_dataOCRStdMed{10};
a_dataOCRStdMedIr4Med = a_dataOCRStdMed{11};

a_dataOCRRawDate = a_dataOCRRaw{1};
a_dataOCRRawDateTrans = a_dataOCRRaw{2};
a_dataOCRRawPres = a_dataOCRRaw{3};
a_dataOCRRawIr1 = a_dataOCRRaw{4};
a_dataOCRRawIr2 = a_dataOCRRaw{5};
a_dataOCRRawIr3 = a_dataOCRRaw{6};
a_dataOCRRawIr4 = a_dataOCRRaw{7};

a_dataECO2Mean = a_dataECO2{1};
a_dataECO2Raw = a_dataECO2{2};
a_dataECO2StdMed = a_dataECO2{3};

a_dataECO2MeanDate = a_dataECO2Mean{1};
a_dataECO2MeanDateTrans = a_dataECO2Mean{2};
a_dataECO2MeanPres = a_dataECO2Mean{3};
a_dataECO2MeanChloroA = a_dataECO2Mean{4};
a_dataECO2MeanBackscat = a_dataECO2Mean{5};

a_dataECO2StdMedDate = a_dataECO2StdMed{1};
a_dataECO2StdMedDateTrans = a_dataECO2StdMed{2};
a_dataECO2StdMedPresMean = a_dataECO2StdMed{3};
a_dataECO2StdMedChloroAStd = a_dataECO2StdMed{4};
a_dataECO2StdMedBackscatStd = a_dataECO2StdMed{5};
a_dataECO2StdMedChloroAMed = a_dataECO2StdMed{6};
a_dataECO2StdMedBackscatMed = a_dataECO2StdMed{7};

a_dataECO2RawDate = a_dataECO2Raw{1};
a_dataECO2RawDateTrans = a_dataECO2Raw{2};
a_dataECO2RawPres = a_dataECO2Raw{3};
a_dataECO2RawChloroA = a_dataECO2Raw{4};
a_dataECO2RawBackscat = a_dataECO2Raw{5};

a_dataECO3Mean = a_dataECO3{1};
a_dataECO3Raw = a_dataECO3{2};
a_dataECO3StdMed = a_dataECO3{3};

a_dataECO3MeanDate = a_dataECO3Mean{1};
a_dataECO3MeanDateTrans = a_dataECO3Mean{2};
a_dataECO3MeanPres = a_dataECO3Mean{3};
a_dataECO3MeanChloroA = a_dataECO3Mean{4};
a_dataECO3MeanBackscat = a_dataECO3Mean{5};
a_dataECO3MeanCdom = a_dataECO3Mean{6};

a_dataECO3StdMedDate = a_dataECO3StdMed{1};
a_dataECO3StdMedDateTrans = a_dataECO3StdMed{2};
a_dataECO3StdMedPresMean = a_dataECO3StdMed{3};
a_dataECO3StdMedChloroAStd = a_dataECO3StdMed{4};
a_dataECO3StdMedBackscatStd = a_dataECO3StdMed{5};
a_dataECO3StdMedCdomStd = a_dataECO3StdMed{6};
a_dataECO3StdMedChloroAMed = a_dataECO3StdMed{7};
a_dataECO3StdMedBackscatMed = a_dataECO3StdMed{8};
a_dataECO3StdMedCdomMed = a_dataECO3StdMed{9};

a_dataECO3RawDate = a_dataECO3Raw{1};
a_dataECO3RawDateTrans = a_dataECO3Raw{2};
a_dataECO3RawPres = a_dataECO3Raw{3};
a_dataECO3RawChloroA = a_dataECO3Raw{4};
a_dataECO3RawBackscat = a_dataECO3Raw{5};
a_dataECO3RawCdom = a_dataECO3Raw{6};

a_dataFLNTUMean = a_dataFLNTU{1};
a_dataFLNTURaw = a_dataFLNTU{2};
a_dataFLNTUStdMed = a_dataFLNTU{3};

a_dataFLNTUMeanDate = a_dataFLNTUMean{1};
a_dataFLNTUMeanDateTrans = a_dataFLNTUMean{2};
a_dataFLNTUMeanPres = a_dataFLNTUMean{3};
a_dataFLNTUMeanChloro = a_dataFLNTUMean{4};
a_dataFLNTUMeanTurbi = a_dataFLNTUMean{5};

a_dataFLNTUStdMedDate = a_dataFLNTUStdMed{1};
a_dataFLNTUStdMedDateTrans = a_dataFLNTUStdMed{2};
a_dataFLNTUStdMedPresMean = a_dataFLNTUStdMed{3};
a_dataFLNTUStdMedChloroStd = a_dataFLNTUStdMed{4};
a_dataFLNTUStdMedTurbiStd = a_dataFLNTUStdMed{5};
a_dataFLNTUStdMedChloroMed = a_dataFLNTUStdMed{6};
a_dataFLNTUStdMedTurbiMed = a_dataFLNTUStdMed{7};

a_dataFLNTURawDate = a_dataFLNTURaw{1};
a_dataFLNTURawDateTrans = a_dataFLNTURaw{2};
a_dataFLNTURawPres = a_dataFLNTURaw{3};
a_dataFLNTURawChloro = a_dataFLNTURaw{4};
a_dataFLNTURawTurbi = a_dataFLNTURaw{5};

a_dataCROVERMean = a_dataCROVER{1};
a_dataCROVERRaw = a_dataCROVER{2};
a_dataCROVERStdMed = a_dataCROVER{3};

a_dataCROVERMeanDate = a_dataCROVERMean{1};
a_dataCROVERMeanDateTrans = a_dataCROVERMean{2};
a_dataCROVERMeanPres = a_dataCROVERMean{3};
a_dataCROVERMeanCoefAtt = a_dataCROVERMean{4};

a_dataCROVERStdMedDate = a_dataCROVERStdMed{1};
a_dataCROVERStdMedDateTrans = a_dataCROVERStdMed{2};
a_dataCROVERStdMedPresMean = a_dataCROVERStdMed{3};
a_dataCROVERStdMedCoefAttStd = a_dataCROVERStdMed{4};
a_dataCROVERStdMedCoefAttMed = a_dataCROVERStdMed{5};

a_dataCROVERRawDate = a_dataCROVERRaw{1};
a_dataCROVERRawDateTrans = a_dataCROVERRaw{2};
a_dataCROVERRawPres = a_dataCROVERRaw{3};
a_dataCROVERRawCoefAtt = a_dataCROVERRaw{4};

a_dataSUNAMean = a_dataSUNA{1};
a_dataSUNARaw = a_dataSUNA{2};
a_dataSUNAStdMed = a_dataSUNA{3};
a_dataSUNAAPF = a_dataSUNA{4};
a_dataSUNAAPF2 = a_dataSUNA{5};

a_dataSUNAMeanDate = a_dataSUNAMean{1};
a_dataSUNAMeanDateTrans = a_dataSUNAMean{2};
a_dataSUNAMeanPres = a_dataSUNAMean{3};
a_dataSUNAMeanConcNitra = a_dataSUNAMean{4};

a_dataSUNAStdMedDate = a_dataSUNAStdMed{1};
a_dataSUNAStdMedDateTrans = a_dataSUNAStdMed{2};
a_dataSUNAStdMedPresMean = a_dataSUNAStdMed{3};
a_dataSUNAStdMedConcNitraStd = a_dataSUNAStdMed{4};
a_dataSUNAStdMedConcNitraMed = a_dataSUNAStdMed{5};

a_dataSUNARawDate = a_dataSUNARaw{1};
a_dataSUNARawDateTrans = a_dataSUNARaw{2};
a_dataSUNARawPres = a_dataSUNARaw{3};
a_dataSUNARawConcNitra = a_dataSUNARaw{4};

a_dataSUNAAPFDate = a_dataSUNAAPF{1};
a_dataSUNAAPFDateTrans = a_dataSUNAAPF{2};
a_dataSUNAAPFCTDPres = a_dataSUNAAPF{3};
a_dataSUNAAPFCTDTemp = a_dataSUNAAPF{4};
a_dataSUNAAPFCTDSal = a_dataSUNAAPF{5};
a_dataSUNAAPFIntTemp = a_dataSUNAAPF{6};
a_dataSUNAAPFSpecTemp = a_dataSUNAAPF{7};
a_dataSUNAAPFIntRelHumidity = a_dataSUNAAPF{8};
a_dataSUNAAPFDarkSpecMean = a_dataSUNAAPF{9};
a_dataSUNAAPFDarkSpecStd = a_dataSUNAAPF{10};
a_dataSUNAAPFSensorNitra = a_dataSUNAAPF{11};
a_dataSUNAAPFAbsFitRes = a_dataSUNAAPF{12};
a_dataSUNAAPFOutSpec = a_dataSUNAAPF{13};

if (~isempty(a_dataSUNAAPF2))
   a_dataSUNAAPF2Date = a_dataSUNAAPF2{1};
   a_dataSUNAAPF2DateTrans = a_dataSUNAAPF2{2};
   a_dataSUNAAPF2CTDPres = a_dataSUNAAPF2{3};
   a_dataSUNAAPF2CTDTemp = a_dataSUNAAPF2{4};
   a_dataSUNAAPF2CTDSal = a_dataSUNAAPF2{5};
   a_dataSUNAAPF2IntTemp = a_dataSUNAAPF2{6};
   a_dataSUNAAPF2SpecTemp = a_dataSUNAAPF2{7};
   a_dataSUNAAPF2IntRelHumidity = a_dataSUNAAPF2{8};
   a_dataSUNAAPF2DarkSpecMean = a_dataSUNAAPF2{9};
   a_dataSUNAAPF2DarkSpecStd = a_dataSUNAAPF2{10};
   a_dataSUNAAPF2SensorNitra = a_dataSUNAAPF2{11};
   a_dataSUNAAPF2AbsFitRes = a_dataSUNAAPF2{12};
   a_dataSUNAAPF2OutSpec = a_dataSUNAAPF2{13};
end

a_dataSEAFETMean = a_dataSEAFET{1};
a_dataSEAFETRaw = a_dataSEAFET{2};
a_dataSEAFETStdMed = a_dataSEAFET{3};

a_dataSEAFETMeanDate = a_dataSEAFETMean{1};
a_dataSEAFETMeanDateTrans = a_dataSEAFETMean{2};
a_dataSEAFETMeanPres = a_dataSEAFETMean{3};
a_dataSEAFETMeanVref = a_dataSEAFETMean{4};

a_dataSEAFETStdMedDate = a_dataSEAFETStdMed{1};
a_dataSEAFETStdMedDateTrans = a_dataSEAFETStdMed{2};
a_dataSEAFETStdMedPresMean = a_dataSEAFETStdMed{3};
a_dataSEAFETStdMedVrefStd = a_dataSEAFETStdMed{4};
a_dataSEAFETStdMedVrefMed = a_dataSEAFETStdMed{5};

a_dataSEAFETRawDate = a_dataSEAFETRaw{1};
a_dataSEAFETRawDateTrans = a_dataSEAFETRaw{2};
a_dataSEAFETRawPres = a_dataSEAFETRaw{3};
a_dataSEAFETRawVref = a_dataSEAFETRaw{4};


% find first pressure measurement
presList = [];
dateList = [];
if (~isempty(a_dataCTDMeanDate))
   idDrift = find(a_dataCTDMeanDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataCTDMeanPres(idDrift, 4)];
      dateList = [dateList; a_dataCTDMeanDate(idDrift, 4)];
   end
end
if (~isempty(a_dataCTDStdMedDate))
   idDrift = find(a_dataCTDStdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataCTDStdMedPresMean(idDrift, 4)];
      dateList = [dateList; a_dataCTDStdMedDate(idDrift, 4)];
   end
end
if (~isempty(a_dataCTDRawDate))
   idDrift = find(a_dataCTDRawDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataCTDRawPres(idDrift, 4)];
      dateList = [dateList; a_dataCTDRawDate(idDrift, 4)];
   end
end
if (~isempty(presList))
   [~, idMin] = min(dateList);
   firstPres = presList(idMin);
   firstPres = sensor_2_value_for_pressure_ir_rudics_sbd2(firstPres, a_decoderId);
end
% add the drift measurement dates
if (~isempty(a_dataCTDMeanDate))
   idDrift = find(a_dataCTDMeanDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataCTDMeanDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(0, firstPres, ...
         a_dataCTDMeanDate(idDrift(idL), 1), a_dataCTDMeanDate(idDrift(idL), 2), ...
         a_dataCTDMeanDate(idDrift(idL), 4:end), a_dataCTDMeanPres(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataCTDMeanDate(:, 1:4)];
end
if (~isempty(a_dataCTDStdMedDate))
   idDrift = find(a_dataCTDStdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataCTDStdMedDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(0, firstPres, ...
         a_dataCTDStdMedDate(idDrift(idL), 1), a_dataCTDStdMedDate(idDrift(idL), 2), ...
         a_dataCTDStdMedDate(idDrift(idL), 4:end), a_dataCTDStdMedPresMean(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataCTDStdMedDate(:, 1:4)];
end
if (~isempty(a_dataCTDRawDate))
   idDrift = find(a_dataCTDRawDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataCTDRawDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(0, firstPres, ...
         a_dataCTDRawDate(idDrift(idL), 1), a_dataCTDRawDate(idDrift(idL), 2), ...
         a_dataCTDRawDate(idDrift(idL), 4:end), a_dataCTDRawPres(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataCTDRawDate(:, 1:4)];
end

% find first pressure measurement
presList = [];
dateList = [];
if (~isempty(a_dataOXYMeanDate))
   idDrift = find(a_dataOXYMeanDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataOXYMeanPres(idDrift, 4)];
      dateList = [dateList; a_dataOXYMeanDate(idDrift, 4)];
   end
end
if (~isempty(a_dataOXYStdMedDate))
   idDrift = find(a_dataOXYStdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataOXYStdMedPresMean(idDrift, 4)];
      dateList = [dateList; a_dataOXYStdMedDate(idDrift, 4)];
   end
end
if (~isempty(a_dataOXYRawDate))
   idDrift = find(a_dataOXYRawDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataOXYRawPres(idDrift, 4)];
      dateList = [dateList; a_dataOXYRawDate(idDrift, 4)];
   end
end
if (~isempty(presList))
   [~, idMin] = min(dateList);
   firstPres = presList(idMin);
   firstPres = sensor_2_value_for_pressure_ir_rudics_sbd2(firstPres, a_decoderId);
end
% add the drift measurement dates
if (~isempty(a_dataOXYMeanDate))
   idDrift = find(a_dataOXYMeanDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataOXYMeanDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(1, firstPres, ...
         a_dataOXYMeanDate(idDrift(idL), 1), a_dataOXYMeanDate(idDrift(idL), 2), ...
         a_dataOXYMeanDate(idDrift(idL), 4:end), a_dataOXYMeanPres(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataOXYMeanDate(:, 1:4)];
end
if (~isempty(a_dataOXYStdMedDate))
   idDrift = find(a_dataOXYStdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataOXYStdMedDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(1, firstPres, ...
         a_dataOXYStdMedDate(idDrift(idL), 1), a_dataOXYStdMedDate(idDrift(idL), 2), ...
         a_dataOXYStdMedDate(idDrift(idL), 4:end), a_dataOXYStdMedPresMean(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataOXYStdMedDate(:, 1:4)];
end
if (~isempty(a_dataOXYRawDate))
   idDrift = find(a_dataOXYRawDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataOXYRawDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(1, firstPres, ...
         a_dataOXYRawDate(idDrift(idL), 1), a_dataOXYRawDate(idDrift(idL), 2), ...
         a_dataOXYRawDate(idDrift(idL), 4:end), a_dataOXYRawPres(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataOXYRawDate(:, 1:4)];
end

% find first pressure measurement
presList = [];
dateList = [];
if (~isempty(a_dataOCRMeanDate))
   idDrift = find(a_dataOCRMeanDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataOCRMeanPres(idDrift, 4)];
      dateList = [dateList; a_dataOCRMeanDate(idDrift, 4)];
   end
end
if (~isempty(a_dataOCRStdMedDate))
   idDrift = find(a_dataOCRStdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataOCRStdMedPresMean(idDrift, 4)];
      dateList = [dateList; a_dataOCRStdMedDate(idDrift, 4)];
   end
end
if (~isempty(a_dataOCRRawDate))
   idDrift = find(a_dataOCRRawDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataOCRRawPres(idDrift, 4)];
      dateList = [dateList; a_dataOCRRawDate(idDrift, 4)];
   end
end
if (~isempty(presList))
   [~, idMin] = min(dateList);
   firstPres = presList(idMin);
   firstPres = sensor_2_value_for_pressure_ir_rudics_sbd2(firstPres, a_decoderId);
end
% add the drift measurement dates
if (~isempty(a_dataOCRMeanDate))
   idDrift = find(a_dataOCRMeanDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataOCRMeanDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(2, firstPres, ...
         a_dataOCRMeanDate(idDrift(idL), 1), a_dataOCRMeanDate(idDrift(idL), 2), ...
         a_dataOCRMeanDate(idDrift(idL), 4:end), a_dataOCRMeanPres(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataOCRMeanDate(:, 1:4)];
end
if (~isempty(a_dataOCRStdMedDate))
   idDrift = find(a_dataOCRStdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataOCRStdMedDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(2, firstPres, ...
         a_dataOCRStdMedDate(idDrift(idL), 1), a_dataOCRStdMedDate(idDrift(idL), 2), ...
         a_dataOCRStdMedDate(idDrift(idL), 4:end), a_dataOCRStdMedPresMean(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataOCRStdMedDate(:, 1:4)];
end
if (~isempty(a_dataOCRRawDate))
   idDrift = find(a_dataOCRRawDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataOCRRawDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(2, firstPres, ...
         a_dataOCRRawDate(idDrift(idL), 1), a_dataOCRRawDate(idDrift(idL), 2), ...
         a_dataOCRRawDate(idDrift(idL), 4:end), a_dataOCRRawPres(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataOCRRawDate(:, 1:4)];
end

% find first pressure measurement
presList = [];
dateList = [];
if (~isempty(a_dataECO2MeanDate))
   idDrift = find(a_dataECO2MeanDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataECO2MeanPres(idDrift, 4)];
      dateList = [dateList; a_dataECO2MeanDate(idDrift, 4)];
   end
end
if (~isempty(a_dataECO2StdMedDate))
   idDrift = find(a_dataECO2StdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataECO2StdMedPresMean(idDrift, 4)];
      dateList = [dateList; a_dataECO2StdMedDate(idDrift, 4)];
   end
end
if (~isempty(a_dataECO2RawDate))
   idDrift = find(a_dataECO2RawDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataECO2RawPres(idDrift, 4)];
      dateList = [dateList; a_dataECO2RawDate(idDrift, 4)];
   end
end
if (~isempty(presList))
   [~, idMin] = min(dateList);
   firstPres = presList(idMin);
   firstPres = sensor_2_value_for_pressure_ir_rudics_sbd2(firstPres, a_decoderId);
end
% add the drift measurement dates
if (~isempty(a_dataECO2MeanDate))
   idDrift = find(a_dataECO2MeanDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataECO2MeanDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(3, firstPres, ...
         a_dataECO2MeanDate(idDrift(idL), 1), a_dataECO2MeanDate(idDrift(idL), 2), ...
         a_dataECO2MeanDate(idDrift(idL), 4:end), a_dataECO2MeanPres(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataECO2MeanDate(:, 1:4)];
end
if (~isempty(a_dataECO2StdMedDate))
   idDrift = find(a_dataECO2StdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataECO2StdMedDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(3, firstPres, ...
         a_dataECO2StdMedDate(idDrift(idL), 1), a_dataECO2StdMedDate(idDrift(idL), 2), ...
         a_dataECO2StdMedDate(idDrift(idL), 4:end), a_dataECO2StdMedPresMean(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataECO2StdMedDate(:, 1:4)];
end
if (~isempty(a_dataECO2RawDate))
   idDrift = find(a_dataECO2RawDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataECO2RawDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(3, firstPres, ...
         a_dataECO2RawDate(idDrift(idL), 1), a_dataECO2RawDate(idDrift(idL), 2), ...
         a_dataECO2RawDate(idDrift(idL), 4:end), a_dataECO2RawPres(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataECO2RawDate(:, 1:4)];
end

% find first pressure measurement
presList = [];
dateList = [];
if (~isempty(a_dataECO3MeanDate))
   idDrift = find(a_dataECO3MeanDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataECO3MeanPres(idDrift, 4)];
      dateList = [dateList; a_dataECO3MeanDate(idDrift, 4)];
   end
end
if (~isempty(a_dataECO3StdMedDate))
   idDrift = find(a_dataECO3StdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataECO3StdMedPresMean(idDrift, 4)];
      dateList = [dateList; a_dataECO3StdMedDate(idDrift, 4)];
   end
end
if (~isempty(a_dataECO3RawDate))
   idDrift = find(a_dataECO3RawDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataECO3RawPres(idDrift, 4)];
      dateList = [dateList; a_dataECO3RawDate(idDrift, 4)];
   end
end
if (~isempty(presList))
   [~, idMin] = min(dateList);
   firstPres = presList(idMin);
   firstPres = sensor_2_value_for_pressure_ir_rudics_sbd2(firstPres, a_decoderId);
end
% add the drift measurement dates
if (~isempty(a_dataECO3MeanDate))
   idDrift = find(a_dataECO3MeanDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataECO3MeanDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(3, firstPres, ...
         a_dataECO3MeanDate(idDrift(idL), 1), a_dataECO3MeanDate(idDrift(idL), 2), ...
         a_dataECO3MeanDate(idDrift(idL), 4:end), a_dataECO3MeanPres(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataECO3MeanDate(:, 1:4)];
end
if (~isempty(a_dataECO3StdMedDate))
   idDrift = find(a_dataECO3StdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataECO3StdMedDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(3, firstPres, ...
         a_dataECO3StdMedDate(idDrift(idL), 1), a_dataECO3StdMedDate(idDrift(idL), 2), ...
         a_dataECO3StdMedDate(idDrift(idL), 4:end), a_dataECO3StdMedPresMean(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataECO3StdMedDate(:, 1:4)];
end
if (~isempty(a_dataECO3RawDate))
   idDrift = find(a_dataECO3RawDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataECO3RawDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(3, firstPres, ...
         a_dataECO3RawDate(idDrift(idL), 1), a_dataECO3RawDate(idDrift(idL), 2), ...
         a_dataECO3RawDate(idDrift(idL), 4:end), a_dataECO3RawPres(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataECO3RawDate(:, 1:4)];
end

% find first pressure measurement
presList = [];
dateList = [];
if (~isempty(a_dataFLNTUMeanDate))
   idDrift = find(a_dataFLNTUMeanDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataFLNTUMeanPres(idDrift, 4)];
      dateList = [dateList; a_dataFLNTUMeanDate(idDrift, 4)];
   end
end
if (~isempty(a_dataFLNTUStdMedDate))
   idDrift = find(a_dataFLNTUStdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataFLNTUStdMedPresMean(idDrift, 4)];
      dateList = [dateList; a_dataFLNTUStdMedDate(idDrift, 4)];
   end
end
if (~isempty(a_dataFLNTURawDate))
   idDrift = find(a_dataFLNTURawDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataFLNTURawPres(idDrift, 4)];
      dateList = [dateList; a_dataFLNTURawDate(idDrift, 4)];
   end
end
if (~isempty(presList))
   [~, idMin] = min(dateList);
   firstPres = presList(idMin);
   firstPres = sensor_2_value_for_pressure_ir_rudics_sbd2(firstPres, a_decoderId);
end
% add the drift measurement dates
if (~isempty(a_dataFLNTUMeanDate))
   idDrift = find(a_dataFLNTUMeanDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataFLNTUMeanDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(4, firstPres, ...
         a_dataFLNTUMeanDate(idDrift(idL), 1), a_dataFLNTUMeanDate(idDrift(idL), 2), ...
         a_dataFLNTUMeanDate(idDrift(idL), 4:end), a_dataFLNTUMeanPres(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataFLNTUMeanDate(:, 1:4)];
end
if (~isempty(a_dataFLNTUStdMedDate))
   idDrift = find(a_dataFLNTUStdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataFLNTUStdMedDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(4, firstPres, ...
         a_dataFLNTUStdMedDate(idDrift(idL), 1), a_dataFLNTUStdMedDate(idDrift(idL), 2), ...
         a_dataFLNTUStdMedDate(idDrift(idL), 4:end), a_dataFLNTUStdMedPresMean(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataFLNTUStdMedDate(:, 1:4)];
end
if (~isempty(a_dataFLNTURawDate))
   idDrift = find(a_dataFLNTURawDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataFLNTURawDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(4, firstPres, ...
         a_dataFLNTURawDate(idDrift(idL), 1), a_dataFLNTURawDate(idDrift(idL), 2), ...
         a_dataFLNTURawDate(idDrift(idL), 4:end), a_dataFLNTURawPres(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataFLNTURawDate(:, 1:4)];
end

% find first pressure measurement
presList = [];
dateList = [];
if (~isempty(a_dataCROVERMeanDate))
   idDrift = find(a_dataCROVERMeanDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataCROVERMeanPres(idDrift, 4)];
      dateList = [dateList; a_dataCROVERMeanDate(idDrift, 4)];
   end
end
if (~isempty(a_dataCROVERStdMedDate))
   idDrift = find(a_dataCROVERStdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataCROVERStdMedPresMean(idDrift, 4)];
      dateList = [dateList; a_dataCROVERStdMedDate(idDrift, 4)];
   end
end
if (~isempty(a_dataCROVERRawDate))
   idDrift = find(a_dataCROVERRawDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataCROVERRawPres(idDrift, 4)];
      dateList = [dateList; a_dataCROVERRawDate(idDrift, 4)];
   end
end
if (~isempty(presList))
   [~, idMin] = min(dateList);
   firstPres = presList(idMin);
   firstPres = sensor_2_value_for_pressure_ir_rudics_sbd2(firstPres, a_decoderId);
end
% add the drift measurement dates
if (~isempty(a_dataCROVERMeanDate))
   idDrift = find(a_dataCROVERMeanDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataCROVERMeanDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(5, firstPres, ...
         a_dataCROVERMeanDate(idDrift(idL), 1), a_dataCROVERMeanDate(idDrift(idL), 2), ...
         a_dataCROVERMeanDate(idDrift(idL), 4:end), a_dataCROVERMeanPres(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataCROVERMeanDate(:, 1:4)];
end
if (~isempty(a_dataCROVERStdMedDate))
   idDrift = find(a_dataCROVERStdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataCROVERStdMedDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(5, firstPres, ...
         a_dataCROVERStdMedDate(idDrift(idL), 1), a_dataCROVERStdMedDate(idDrift(idL), 2), ...
         a_dataCROVERStdMedDate(idDrift(idL), 4:end), a_dataCROVERStdMedPresMean(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataCROVERStdMedDate(:, 1:4)];
end
if (~isempty(a_dataCROVERRawDate))
   idDrift = find(a_dataCROVERRawDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataCROVERRawDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(5, firstPres, ...
         a_dataCROVERRawDate(idDrift(idL), 1), a_dataCROVERRawDate(idDrift(idL), 2), ...
         a_dataCROVERRawDate(idDrift(idL), 4:end), a_dataCROVERRawPres(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataCROVERRawDate(:, 1:4)];
end

% find first pressure measurement
presList = [];
dateList = [];
if (~isempty(a_dataSUNAMeanDate))
   idDrift = find(a_dataSUNAMeanDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataSUNAMeanPres(idDrift, 4)];
      dateList = [dateList; a_dataSUNAMeanDate(idDrift, 4)];
   end
end
if (~isempty(a_dataSUNAStdMedDate))
   idDrift = find(a_dataSUNAStdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataSUNAStdMedPresMean(idDrift, 4)];
      dateList = [dateList; a_dataSUNAStdMedDate(idDrift, 4)];
   end
end
if (~isempty(a_dataSUNARawDate))
   idDrift = find(a_dataSUNARawDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataSUNARawPres(idDrift, 4)];
      dateList = [dateList; a_dataSUNARawDate(idDrift, 4)];
   end
end
if (~isempty(a_dataSUNAAPFDate))
   idDrift = find(a_dataSUNAAPFDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataSUNAAPFCTDPres(idDrift, 4)];
      dateList = [dateList; a_dataSUNAAPFDate(idDrift, 4)];
   end
end
if (~isempty(a_dataSUNAAPF2))
   if (~isempty(a_dataSUNAAPF2Date))
      idDrift = find(a_dataSUNAAPF2Date(:, 3) == g_decArgo_phaseParkDrift);
      if (~isempty(idDrift))
         presList = [presList; a_dataSUNAAPF2CTDPres(idDrift, 4)];
         dateList = [dateList; a_dataSUNAAPF2Date(idDrift, 4)];
      end
   end
end
if (~isempty(presList))
   [~, idMin] = min(dateList);
   firstPres = presList(idMin);
   firstPres = sensor_2_value_for_pressure_ir_rudics_sbd2(firstPres, a_decoderId);
end
% add the drift measurement dates
if (~isempty(a_dataSUNAMeanDate))
   idDrift = find(a_dataSUNAMeanDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataSUNAMeanDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(6, firstPres, ...
         a_dataSUNAMeanDate(idDrift(idL), 1), a_dataSUNAMeanDate(idDrift(idL), 2), ...
         a_dataSUNAMeanDate(idDrift(idL), 4:end), a_dataSUNAMeanPres(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataSUNAMeanDate(:, 1:4)];
end
if (~isempty(a_dataSUNAStdMedDate))
   idDrift = find(a_dataSUNAStdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataSUNAStdMedDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(6, firstPres, ...
         a_dataSUNAStdMedDate(idDrift(idL), 1), a_dataSUNAStdMedDate(idDrift(idL), 2), ...
         a_dataSUNAStdMedDate(idDrift(idL), 4:end), a_dataSUNAStdMedPresMean(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataSUNAStdMedDate(:, 1:4)];
end
if (~isempty(a_dataSUNARawDate))
   idDrift = find(a_dataSUNARawDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataSUNARawDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(6, firstPres, ...
         a_dataSUNARawDate(idDrift(idL), 1), a_dataSUNARawDate(idDrift(idL), 2), ...
         a_dataSUNARawDate(idDrift(idL), 4:end), a_dataSUNARawPres(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataSUNARawDate(:, 1:4)];
end
if (~isempty(a_dataSUNAAPFDate))
   idDrift = find(a_dataSUNAAPFDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataSUNAAPFDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(6, firstPres, ...
         a_dataSUNAAPFDate(idDrift(idL), 1), a_dataSUNAAPFDate(idDrift(idL), 2), ...
         a_dataSUNAAPFDate(idDrift(idL), 4:end), a_dataSUNAAPFCTDPres(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataSUNAAPFDate(:, 1:4)];
end
if (~isempty(a_dataSUNAAPF2))
   if (~isempty(a_dataSUNAAPF2Date))
      idDrift = find(a_dataSUNAAPF2Date(:, 3) == g_decArgo_phaseParkDrift);
      for idL = 1:length(idDrift)
         [a_dataSUNAAPF2Date(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(6, firstPres, ...
            a_dataSUNAAPF2Date(idDrift(idL), 1), a_dataSUNAAPF2Date(idDrift(idL), 2), ...
            a_dataSUNAAPF2Date(idDrift(idL), 4:end), a_dataSUNAAPF2CTDPres(idDrift(idL), 4:end));
      end
   end
   o_measDates = [o_measDates; a_dataSUNAAPF2Date(:, 1:4)];
end

% find first pressure measurement
presList = [];
dateList = [];
if (~isempty(a_dataSEAFETMeanDate))
   idDrift = find(a_dataSEAFETMeanDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataSEAFETMeanPres(idDrift, 4)];
      dateList = [dateList; a_dataSEAFETMeanDate(idDrift, 4)];
   end
end
if (~isempty(a_dataSEAFETStdMedDate))
   idDrift = find(a_dataSEAFETStdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataSEAFETStdMedPresMean(idDrift, 4)];
      dateList = [dateList; a_dataSEAFETStdMedDate(idDrift, 4)];
   end
end
if (~isempty(a_dataSEAFETRawDate))
   idDrift = find(a_dataSEAFETRawDate(:, 3) == g_decArgo_phaseParkDrift);
   if (~isempty(idDrift))
      presList = [presList; a_dataSEAFETRawPres(idDrift, 4)];
      dateList = [dateList; a_dataSEAFETRawDate(idDrift, 4)];
   end
end
if (~isempty(presList))
   [~, idMin] = min(dateList);
   firstPres = presList(idMin);
   firstPres = sensor_2_value_for_pressure_ir_rudics_sbd2(firstPres, a_decoderId);
end
% add the drift measurement dates
if (~isempty(a_dataSEAFETMeanDate))
   idDrift = find(a_dataSEAFETMeanDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataSEAFETMeanDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(5, firstPres, ...
         a_dataSEAFETMeanDate(idDrift(idL), 1), a_dataSEAFETMeanDate(idDrift(idL), 2), ...
         a_dataSEAFETMeanDate(idDrift(idL), 4:end), a_dataSEAFETMeanPres(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataSEAFETMeanDate(:, 1:4)];
end
if (~isempty(a_dataSEAFETStdMedDate))
   idDrift = find(a_dataSEAFETStdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataSEAFETStdMedDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(5, firstPres, ...
         a_dataSEAFETStdMedDate(idDrift(idL), 1), a_dataSEAFETStdMedDate(idDrift(idL), 2), ...
         a_dataSEAFETStdMedDate(idDrift(idL), 4:end), a_dataSEAFETStdMedPresMean(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataSEAFETStdMedDate(:, 1:4)];
end
if (~isempty(a_dataSEAFETRawDate))
   idDrift = find(a_dataSEAFETRawDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataSEAFETRawDate(idDrift(idL), 4:end)] = compute_drift_dates_ir_rudics_111_113(5, firstPres, ...
         a_dataSEAFETRawDate(idDrift(idL), 1), a_dataSEAFETRawDate(idDrift(idL), 2), ...
         a_dataSEAFETRawDate(idDrift(idL), 4:end), a_dataSEAFETRawPres(idDrift(idL), 4:end));
   end
   o_measDates = [o_measDates; a_dataSEAFETRawDate(:, 1:4)];
end

% store output data in cell arrays
o_dataCTDMean{1} = a_dataCTDMeanDate;
o_dataCTDMean{2} = a_dataCTDMeanDateTrans;
o_dataCTDMean{3} = a_dataCTDMeanPres;
o_dataCTDMean{4} = a_dataCTDMeanTemp;
o_dataCTDMean{5} = a_dataCTDMeanSal;

o_dataCTDRaw{1} = a_dataCTDRawDate;
o_dataCTDRaw{2} = a_dataCTDRawDateTrans;
o_dataCTDRaw{3} = a_dataCTDRawPres;
o_dataCTDRaw{4} = a_dataCTDRawTemp;
o_dataCTDRaw{5} = a_dataCTDRawSal;

o_dataCTDStdMed{1} = a_dataCTDStdMedDate;
o_dataCTDStdMed{2} = a_dataCTDStdMedDateTrans;
o_dataCTDStdMed{3} = a_dataCTDStdMedPresMean;
o_dataCTDStdMed{4} = a_dataCTDStdMedTempStd;
o_dataCTDStdMed{5} = a_dataCTDStdMedSalStd;
o_dataCTDStdMed{6} = a_dataCTDStdMedPresMed;
o_dataCTDStdMed{7} = a_dataCTDStdMedTempMed;
o_dataCTDStdMed{8} = a_dataCTDStdMedSalMed;

o_dataCTD{1} = o_dataCTDMean;
o_dataCTD{2} = o_dataCTDRaw;
o_dataCTD{3} = o_dataCTDStdMed;

o_dataOXYMean{1} = a_dataOXYMeanDate;
o_dataOXYMean{2} = a_dataOXYMeanDateTrans;
o_dataOXYMean{3} = a_dataOXYMeanPres;
o_dataOXYMean{4} = a_dataOXYMeanC1Phase;
o_dataOXYMean{5} = a_dataOXYMeanC2Phase;
o_dataOXYMean{6} = a_dataOXYMeanTemp;

o_dataOXYRaw{1} = a_dataOXYRawDate;
o_dataOXYRaw{2} = a_dataOXYRawDateTrans;
o_dataOXYRaw{3} = a_dataOXYRawPres;
o_dataOXYRaw{4} = a_dataOXYRawC1Phase;
o_dataOXYRaw{5} = a_dataOXYRawC2Phase;
o_dataOXYRaw{6} = a_dataOXYRawTemp;

o_dataOXYStdMed{1} = a_dataOXYStdMedDate;
o_dataOXYStdMed{2} = a_dataOXYStdMedDateTrans;
o_dataOXYStdMed{3} = a_dataOXYStdMedPresMean;
o_dataOXYStdMed{4} = a_dataOXYStdMedC1PhaseStd;
o_dataOXYStdMed{5} = a_dataOXYStdMedC2PhaseStd;
o_dataOXYStdMed{6} = a_dataOXYStdMedTempStd;
o_dataOXYStdMed{7} = a_dataOXYStdMedC1PhaseMed;
o_dataOXYStdMed{8} = a_dataOXYStdMedC2PhaseMed;
o_dataOXYStdMed{9} = a_dataOXYStdMedTempMed;

o_dataOXY{1} = o_dataOXYMean;
o_dataOXY{2} = o_dataOXYRaw;
o_dataOXY{3} = o_dataOXYStdMed;

o_dataOCRMean{1} = a_dataOCRMeanDate;
o_dataOCRMean{2} = a_dataOCRMeanDateTrans;
o_dataOCRMean{3} = a_dataOCRMeanPres;
o_dataOCRMean{4} = a_dataOCRMeanIr1;
o_dataOCRMean{5} = a_dataOCRMeanIr2;
o_dataOCRMean{6} = a_dataOCRMeanIr3;
o_dataOCRMean{7} = a_dataOCRMeanIr4;

o_dataOCRRaw{1} = a_dataOCRRawDate;
o_dataOCRRaw{2} = a_dataOCRRawDateTrans;
o_dataOCRRaw{3} = a_dataOCRRawPres;
o_dataOCRRaw{4} = a_dataOCRRawIr1;
o_dataOCRRaw{5} = a_dataOCRRawIr2;
o_dataOCRRaw{6} = a_dataOCRRawIr3;
o_dataOCRRaw{7} = a_dataOCRRawIr4;

o_dataOCRStdMed{1} = a_dataOCRStdMedDate;
o_dataOCRStdMed{2} = a_dataOCRStdMedDateTrans;
o_dataOCRStdMed{3} = a_dataOCRStdMedPresMean;
o_dataOCRStdMed{4} = a_dataOCRStdMedIr1Std;
o_dataOCRStdMed{5} = a_dataOCRStdMedIr2Std;
o_dataOCRStdMed{6} = a_dataOCRStdMedIr3Std;
o_dataOCRStdMed{7} = a_dataOCRStdMedIr4Std;
o_dataOCRStdMed{8} = a_dataOCRStdMedIr1Med;
o_dataOCRStdMed{9} = a_dataOCRStdMedIr2Med;
o_dataOCRStdMed{10} = a_dataOCRStdMedIr3Med;
o_dataOCRStdMed{11} = a_dataOCRStdMedIr4Med;

o_dataOCR{1} = o_dataOCRMean;
o_dataOCR{2} = o_dataOCRRaw;
o_dataOCR{3} = o_dataOCRStdMed;

o_dataECO2Mean{1} = a_dataECO2MeanDate;
o_dataECO2Mean{2} = a_dataECO2MeanDateTrans;
o_dataECO2Mean{3} = a_dataECO2MeanPres;
o_dataECO2Mean{4} = a_dataECO2MeanChloroA;
o_dataECO2Mean{5} = a_dataECO2MeanBackscat;

o_dataECO2Raw{1} = a_dataECO2RawDate;
o_dataECO2Raw{2} = a_dataECO2RawDateTrans;
o_dataECO2Raw{3} = a_dataECO2RawPres;
o_dataECO2Raw{4} = a_dataECO2RawChloroA;
o_dataECO2Raw{5} = a_dataECO2RawBackscat;

o_dataECO2StdMed{1} = a_dataECO2StdMedDate;
o_dataECO2StdMed{2} = a_dataECO2StdMedDateTrans;
o_dataECO2StdMed{3} = a_dataECO2StdMedPresMean;
o_dataECO2StdMed{4} = a_dataECO2StdMedChloroAStd;
o_dataECO2StdMed{5} = a_dataECO2StdMedBackscatStd;
o_dataECO2StdMed{6} = a_dataECO2StdMedChloroAMed;
o_dataECO2StdMed{7} = a_dataECO2StdMedBackscatMed;

o_dataECO2{1} = o_dataECO2Mean;
o_dataECO2{2} = o_dataECO2Raw;
o_dataECO2{3} = o_dataECO2StdMed;

o_dataECO3Mean{1} = a_dataECO3MeanDate;
o_dataECO3Mean{2} = a_dataECO3MeanDateTrans;
o_dataECO3Mean{3} = a_dataECO3MeanPres;
o_dataECO3Mean{4} = a_dataECO3MeanChloroA;
o_dataECO3Mean{5} = a_dataECO3MeanBackscat;
o_dataECO3Mean{6} = a_dataECO3MeanCdom;

o_dataECO3Raw{1} = a_dataECO3RawDate;
o_dataECO3Raw{2} = a_dataECO3RawDateTrans;
o_dataECO3Raw{3} = a_dataECO3RawPres;
o_dataECO3Raw{4} = a_dataECO3RawChloroA;
o_dataECO3Raw{5} = a_dataECO3RawBackscat;
o_dataECO3Raw{6} = a_dataECO3RawCdom;

o_dataECO3StdMed{1} = a_dataECO3StdMedDate;
o_dataECO3StdMed{2} = a_dataECO3StdMedDateTrans;
o_dataECO3StdMed{3} = a_dataECO3StdMedPresMean;
o_dataECO3StdMed{4} = a_dataECO3StdMedChloroAStd;
o_dataECO3StdMed{5} = a_dataECO3StdMedBackscatStd;
o_dataECO3StdMed{6} = a_dataECO3StdMedCdomStd;
o_dataECO3StdMed{7} = a_dataECO3StdMedChloroAMed;
o_dataECO3StdMed{8} = a_dataECO3StdMedBackscatMed;
o_dataECO3StdMed{9} = a_dataECO3StdMedCdomMed;

o_dataECO3{1} = o_dataECO3Mean;
o_dataECO3{2} = o_dataECO3Raw;
o_dataECO3{3} = o_dataECO3StdMed;

o_dataFLNTUMean{1} = a_dataFLNTUMeanDate;
o_dataFLNTUMean{2} = a_dataFLNTUMeanDateTrans;
o_dataFLNTUMean{3} = a_dataFLNTUMeanPres;
o_dataFLNTUMean{4} = a_dataFLNTUMeanChloro;
o_dataFLNTUMean{5} = a_dataFLNTUMeanTurbi;

o_dataFLNTURaw{1} = a_dataFLNTURawDate;
o_dataFLNTURaw{2} = a_dataFLNTURawDateTrans;
o_dataFLNTURaw{3} = a_dataFLNTURawPres;
o_dataFLNTURaw{4} = a_dataFLNTURawChloro;
o_dataFLNTURaw{5} = a_dataFLNTURawTurbi;

o_dataFLNTUStdMed{1} = a_dataFLNTUStdMedDate;
o_dataFLNTUStdMed{2} = a_dataFLNTUStdMedDateTrans;
o_dataFLNTUStdMed{3} = a_dataFLNTUStdMedPresMean;
o_dataFLNTUStdMed{4} = a_dataFLNTUStdMedChloroStd;
o_dataFLNTUStdMed{5} = a_dataFLNTUStdMedTurbiStd;
o_dataFLNTUStdMed{6} = a_dataFLNTUStdMedChloroMed;
o_dataFLNTUStdMed{7} = a_dataFLNTUStdMedTurbiMed;

o_dataFLNTU{1} = o_dataFLNTUMean;
o_dataFLNTU{2} = o_dataFLNTURaw;
o_dataFLNTU{3} = o_dataFLNTUStdMed;

o_dataCROVERMean{1} = a_dataCROVERMeanDate;
o_dataCROVERMean{2} = a_dataCROVERMeanDateTrans;
o_dataCROVERMean{3} = a_dataCROVERMeanPres;
o_dataCROVERMean{4} = a_dataCROVERMeanCoefAtt;

o_dataCROVERRaw{1} = a_dataCROVERRawDate;
o_dataCROVERRaw{2} = a_dataCROVERRawDateTrans;
o_dataCROVERRaw{3} = a_dataCROVERRawPres;
o_dataCROVERRaw{4} = a_dataCROVERRawCoefAtt;

o_dataCROVERStdMed{1} = a_dataCROVERStdMedDate;
o_dataCROVERStdMed{2} = a_dataCROVERStdMedDateTrans;
o_dataCROVERStdMed{3} = a_dataCROVERStdMedPresMean;
o_dataCROVERStdMed{4} = a_dataCROVERStdMedCoefAttStd;
o_dataCROVERStdMed{5} = a_dataCROVERStdMedCoefAttMed;

o_dataCROVER{1} = o_dataCROVERMean;
o_dataCROVER{2} = o_dataCROVERRaw;
o_dataCROVER{3} = o_dataCROVERStdMed;

o_dataSUNAMean{1} = a_dataSUNAMeanDate;
o_dataSUNAMean{2} = a_dataSUNAMeanDateTrans;
o_dataSUNAMean{3} = a_dataSUNAMeanPres;
o_dataSUNAMean{4} = a_dataSUNAMeanConcNitra;

o_dataSUNARaw{1} = a_dataSUNARawDate;
o_dataSUNARaw{2} = a_dataSUNARawDateTrans;
o_dataSUNARaw{3} = a_dataSUNARawPres;
o_dataSUNARaw{4} = a_dataSUNARawConcNitra;

o_dataSUNAStdMed{1} = a_dataSUNAStdMedDate;
o_dataSUNAStdMed{2} = a_dataSUNAStdMedDateTrans;
o_dataSUNAStdMed{3} = a_dataSUNAStdMedPresMean;
o_dataSUNAStdMed{4} = a_dataSUNAStdMedConcNitraStd;
o_dataSUNAStdMed{5} = a_dataSUNAStdMedConcNitraMed;

o_dataSUNAAPF{1} = a_dataSUNAAPFDate;
o_dataSUNAAPF{2} = a_dataSUNAAPFDateTrans;
o_dataSUNAAPF{3} = a_dataSUNAAPFCTDPres;
o_dataSUNAAPF{4} = a_dataSUNAAPFCTDTemp;
o_dataSUNAAPF{5} = a_dataSUNAAPFCTDSal;
o_dataSUNAAPF{6} = a_dataSUNAAPFIntTemp;
o_dataSUNAAPF{7} = a_dataSUNAAPFSpecTemp;
o_dataSUNAAPF{8} = a_dataSUNAAPFIntRelHumidity;
o_dataSUNAAPF{9} = a_dataSUNAAPFDarkSpecMean;
o_dataSUNAAPF{10} = a_dataSUNAAPFDarkSpecStd;
o_dataSUNAAPF{11} = a_dataSUNAAPFSensorNitra;
o_dataSUNAAPF{12} = a_dataSUNAAPFAbsFitRes;
o_dataSUNAAPF{13} = a_dataSUNAAPFOutSpec;

o_dataSUNAAPF2 = [];
if (~isempty(a_dataSUNAAPF2))
   o_dataSUNAAPF2{1} = a_dataSUNAAPF2Date;
   o_dataSUNAAPF2{2} = a_dataSUNAAPF2DateTrans;
   o_dataSUNAAPF2{3} = a_dataSUNAAPF2CTDPres;
   o_dataSUNAAPF2{4} = a_dataSUNAAPF2CTDTemp;
   o_dataSUNAAPF2{5} = a_dataSUNAAPF2CTDSal;
   o_dataSUNAAPF2{6} = a_dataSUNAAPF2IntTemp;
   o_dataSUNAAPF2{7} = a_dataSUNAAPF2SpecTemp;
   o_dataSUNAAPF2{8} = a_dataSUNAAPF2IntRelHumidity;
   o_dataSUNAAPF2{9} = a_dataSUNAAPF2DarkSpecMean;
   o_dataSUNAAPF2{10} = a_dataSUNAAPF2DarkSpecStd;
   o_dataSUNAAPF2{11} = a_dataSUNAAPF2SensorNitra;
   o_dataSUNAAPF2{12} = a_dataSUNAAPF2AbsFitRes;
   o_dataSUNAAPF2{13} = a_dataSUNAAPF2OutSpec;
end

o_dataSUNA{1} = o_dataSUNAMean;
o_dataSUNA{2} = o_dataSUNARaw;
o_dataSUNA{3} = o_dataSUNAStdMed;
o_dataSUNA{4} = o_dataSUNAAPF;
o_dataSUNA{5} = o_dataSUNAAPF2;

o_dataSEAFETMean{1} = a_dataSEAFETMeanDate;
o_dataSEAFETMean{2} = a_dataSEAFETMeanDateTrans;
o_dataSEAFETMean{3} = a_dataSEAFETMeanPres;
o_dataSEAFETMean{4} = a_dataSEAFETMeanVref;

o_dataSEAFETRaw{1} = a_dataSEAFETRawDate;
o_dataSEAFETRaw{2} = a_dataSEAFETRawDateTrans;
o_dataSEAFETRaw{3} = a_dataSEAFETRawPres;
o_dataSEAFETRaw{4} = a_dataSEAFETRawVref;

o_dataSEAFETStdMed{1} = a_dataSEAFETStdMedDate;
o_dataSEAFETStdMed{2} = a_dataSEAFETStdMedDateTrans;
o_dataSEAFETStdMed{3} = a_dataSEAFETStdMedPresMean;
o_dataSEAFETStdMed{4} = a_dataSEAFETStdMedVrefStd;
o_dataSEAFETStdMed{5} = a_dataSEAFETStdMedVrefMed;

o_dataSEAFET{1} = o_dataSEAFETMean;
o_dataSEAFET{2} = o_dataSEAFETRaw;
o_dataSEAFET{3} = o_dataSEAFETStdMed;

return
