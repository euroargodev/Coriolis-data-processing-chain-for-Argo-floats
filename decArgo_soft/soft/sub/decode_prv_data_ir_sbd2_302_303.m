% ------------------------------------------------------------------------------
% Decode PROVOR packet data.
%
% SYNTAX :
%  [o_cyProfPhaseList, ...
%    o_dataCTD, o_dataOXY, o_dataFLNTU, o_dataCYCLOPS, o_dataSEAPOINT, ...
%    o_sensorTechCTD, o_sensorTechOPTODE, o_sensorTechFLNTU, ...
%    o_sensorTechCYCLOPS, o_sensorTechSEAPOINT, ...
%    o_sensorParam, ...
%    o_floatPres, ...
%    o_tabTech, o_floatProgTech, o_floatProgParam] = ...
%    decode_prv_data_ir_sbd2_302_303(a_tabSensors, a_tabDates, a_procLevel)
%
% INPUT PARAMETERS :
%   a_tabSensors : data frame to decode
%   a_tabDates   : corresponding dates of Iridium messages
%   a_procLevel  : processing level (0: collect only rough information, 1:
%                  process data and technical information, 2: process
%                  configuration information)
%
% OUTPUT PARAMETERS :
%   o_cyProfPhaseList    : information (cycle #, prof #, phase #) on each
%                          received packet
%   o_dataCTD            : decoded CTD data
%   o_dataOXY            : decoded OXY data
%   o_dataFLNTU          : decoded FLNTU data
%   o_dataCYCLOPS        : decoded CYCLOPS data
%   o_dataSEAPOINT       : decoded SEAPOINT data
%   o_sensorTechCTD      : decoded CTD technical data
%   o_sensorTechOPTODE   : decoded OXY technical data
%   o_sensorTechFLNTU    : decoded FLNTU technical data
%   o_sensorTechCYCLOPS  : decoded CYCLOPS technical data
%   o_sensorTechSEAPOINT : decoded SEAPOINT technical data
%   o_sensorParam        : decoded modified sensor data
%   o_floatPres          : decoded float pressure actions
%   o_tabTech            : decoded float technical data
%   o_floatProgTech      : decoded float technical programmed data
%   o_floatProgParam     : decoded float parameter programmed data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/26/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cyProfPhaseList, ...
   o_dataCTD, o_dataOXY, o_dataFLNTU, o_dataCYCLOPS, o_dataSEAPOINT, ...
   o_sensorTechCTD, o_sensorTechOPTODE, o_sensorTechFLNTU, ...
   o_sensorTechCYCLOPS, o_sensorTechSEAPOINT, ...
   o_sensorParam, ...
   o_floatPres, ...
   o_tabTech, o_floatProgTech, o_floatProgParam] = ...
   decode_prv_data_ir_sbd2_302_303(a_tabSensors, a_tabDates, a_procLevel)

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


% output parameters initialization
o_cyProfPhaseList = [];

o_dataCTD = [];
o_dataOXY = [];
o_dataFLNTU = [];
o_dataCYCLOPS = [];
o_dataSEAPOINT = [];

o_sensorTechCTD = [];
o_sensorTechOPTODE = [];
o_sensorTechFLNTU = [];
o_sensorTechCYCLOPS = [];
o_sensorTechSEAPOINT = [];

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
o_dataOXYMeanDPhase = [];
o_dataOXYMeanTemp = [];

o_dataOXYStdMedDate = [];
o_dataOXYStdMedDateTrans = [];
o_dataOXYStdMedPresMean = [];
o_dataOXYStdMedDPhaseStd = [];
o_dataOXYStdMedTempStd = [];
o_dataOXYStdMedDPhaseMed = [];
o_dataOXYStdMedTempMed = [];

o_dataFLNTUMeanDate = [];
o_dataFLNTUMeanDateTrans = [];
o_dataFLNTUMeanPres = [];
o_dataFLNTUMeanChloro = [];
o_dataFLNTUMeanTurbi = [];

o_dataFLNTUStdMedDate = [];
o_dataFLNTUStdMedDateTrans = [];
o_dataFLNTUStdMedPresMean = [];
o_dataFLNTUStdMedChloroStd = [];
o_dataFLNTUStdMedTurbiStd = [];
o_dataFLNTUStdMedChloroMed = [];
o_dataFLNTUStdMedTurbiMed = [];

o_dataCYCLOPSMeanDate = [];
o_dataCYCLOPSMeanDateTrans = [];
o_dataCYCLOPSMeanPres = [];
o_dataCYCLOPSMeanChloro = [];

o_dataCYCLOPSStdMedDate = [];
o_dataCYCLOPSStdMedDateTrans = [];
o_dataCYCLOPSStdMedPresMean = [];
o_dataCYCLOPSStdMedChloroStd = [];
o_dataCYCLOPSStdMedChloroMed = [];

o_dataSEAPOINTMeanDate = [];
o_dataSEAPOINTMeanDateTrans = [];
o_dataSEAPOINTMeanPres = [];
o_dataSEAPOINTMeanTurbi = [];

o_dataSEAPOINTStdMedDate = [];
o_dataSEAPOINTStdMedDateTrans = [];
o_dataSEAPOINTStdMedPresMean = [];
o_dataSEAPOINTStdMedTurbiStd = [];
o_dataSEAPOINTStdMedTurbiMed = [];

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

o_sensorTechCYCLOPSNbPackDesc = [];
o_sensorTechCYCLOPSNbPackDrift = [];
o_sensorTechCYCLOPSNbPackAsc = [];
o_sensorTechCYCLOPSNbMeasDescZ1 = [];
o_sensorTechCYCLOPSNbMeasDescZ2 = [];
o_sensorTechCYCLOPSNbMeasDescZ3 = [];
o_sensorTechCYCLOPSNbMeasDescZ4 = [];
o_sensorTechCYCLOPSNbMeasDescZ5 = [];
o_sensorTechCYCLOPSNbMeasDrift = [];
o_sensorTechCYCLOPSNbMeasAscZ1 = [];
o_sensorTechCYCLOPSNbMeasAscZ2 = [];
o_sensorTechCYCLOPSNbMeasAscZ3 = [];
o_sensorTechCYCLOPSNbMeasAscZ4 = [];
o_sensorTechCYCLOPSNbMeasAscZ5 = [];
o_sensorTechCYCLOPSSensorState = [];
o_sensorTechCYCLOPSAvgSampMax = [];
o_sensorTechCYCLOPSCalib1Volts = [];
o_sensorTechCYCLOPSCalib1PhysicalValue = [];
o_sensorTechCYCLOPSCalib2Volts = [];
o_sensorTechCYCLOPSCalib2PhysicalValue = [];
o_sensorTechCYCLOPSOpenDrainOutputUsedForSensorGain = [];
o_sensorTechCYCLOPSOpenDrainOutputState = [];

o_sensorTechSEAPOINTNbPackDesc = [];
o_sensorTechSEAPOINTNbPackDrift = [];
o_sensorTechSEAPOINTNbPackAsc = [];
o_sensorTechSEAPOINTNbMeasDescZ1 = [];
o_sensorTechSEAPOINTNbMeasDescZ2 = [];
o_sensorTechSEAPOINTNbMeasDescZ3 = [];
o_sensorTechSEAPOINTNbMeasDescZ4 = [];
o_sensorTechSEAPOINTNbMeasDescZ5 = [];
o_sensorTechSEAPOINTNbMeasDrift = [];
o_sensorTechSEAPOINTNbMeasAscZ1 = [];
o_sensorTechSEAPOINTNbMeasAscZ2 = [];
o_sensorTechSEAPOINTNbMeasAscZ3 = [];
o_sensorTechSEAPOINTNbMeasAscZ4 = [];
o_sensorTechSEAPOINTNbMeasAscZ5 = [];
o_sensorTechSEAPOINTSensorState = [];
o_sensorTechSEAPOINTAvgSampMax = [];
o_sensorTechSEAPOINTCalib1Volts = [];
o_sensorTechSEAPOINTCalib1PhysicalValue = [];
o_sensorTechSEAPOINTCalib2Volts = [];
o_sensorTechSEAPOINTCalib2PhysicalValue = [];
o_sensorTechSEAPOINTOpenDrainOutputUsedForSensorGain = [];
o_sensorTechSEAPOINTOpenDrainOutputState = [];

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
                  % CTD mean
                  
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
                  % OXYGEN mean
                  
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
                  measDPhase = [];
                  measTemp = [];
                  for idBin = 1:10
                     measPres = [measPres values(4*(idBin-1)+5)];
                     measDPhase = [measDPhase twos_complement_dec_argo(values(4*(idBin-1)+6), 32)];
                     measTemp = [measTemp values(4*(idBin-1)+8)];
                  end
                  measDateTrans(1) = 1;
                  measDateTrans(find((measPres == 0) & (measDPhase == 0) & (measTemp == 0))) = -1;
                  
                  o_dataOXYMeanDate = [o_dataOXYMeanDate; [cycleNum profNum phaseNum measDate]];
                  o_dataOXYMeanDateTrans = [o_dataOXYMeanDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                  o_dataOXYMeanPres = [o_dataOXYMeanPres; [cycleNum profNum phaseNum measPres]];
                  o_dataOXYMeanDPhase = [o_dataOXYMeanDPhase; [cycleNum profNum phaseNum measDPhase]];
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
                  measDPhaseStd = [];
                  measTempStd = [];
                  measDPhaseMed = [];
                  measTempMed = [];
                  for idBin = 1:7
                     measPresMean = [measPresMean values(7*(idBin-1)+5)];
                     measDPhaseStd = [measDPhaseStd values(7*(idBin-1)+6)];
                     measTempStd = [measTempStd values(7*(idBin-1)+8)];
                     measDPhaseMed = [measDPhaseMed twos_complement_dec_argo(values(7*(idBin-1)+9), 32)];
                     measTempMed = [measTempMed values(7*(idBin-1)+11)];
                  end
                  measDateTrans(1) = 1;
                  measDateTrans(find((measPresMean == 0) & (measDPhaseStd == 0) & ...
                     (measTempStd == 0) & (measDPhaseMed == 0) & (measTempMed == 0))) = -1;
                  
                  o_dataOXYStdMedDate = [o_dataOXYStdMedDate; [cycleNum profNum phaseNum measDate]];
                  o_dataOXYStdMedDateTrans = [o_dataOXYStdMedDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                  o_dataOXYStdMedPresMean  = [o_dataOXYStdMedPresMean; [cycleNum profNum phaseNum measPresMean]];
                  o_dataOXYStdMedDPhaseStd  = [o_dataOXYStdMedDPhaseStd; [cycleNum profNum phaseNum measDPhaseStd]];
                  o_dataOXYStdMedTempStd  = [o_dataOXYStdMedTempStd; [cycleNum profNum phaseNum measTempStd]];
                  o_dataOXYStdMedDPhaseMed  = [o_dataOXYStdMedDPhaseMed; [cycleNum profNum phaseNum measDPhaseMed]];
                  o_dataOXYStdMedTempMed  = [o_dataOXYStdMedTempMed; [cycleNum profNum phaseNum measTempMed]];
                  
                  o_cyProfPhaseList = [o_cyProfPhaseList; ...
                     packType sensorDataType cycleNum profNum phaseNum sbdFileDate];

               case {15}
                  % FLNTU mean
                  
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
                  measChloro = [];
                  measTurbi = [];
                  for idBin = 1:21
                     measPres = [measPres values(3*(idBin-1)+5)];
                     measChloro = [measChloro values(3*(idBin-1)+6)];
                     measTurbi = [measTurbi values(3*(idBin-1)+7)];
                  end
                  measDateTrans(1) = 1;
                  measDateTrans(find((measPres == 0) & (measChloro == 0) & (measTurbi == 0))) = -1;
                  
                  o_dataFLNTUMeanDate = [o_dataFLNTUMeanDate; [cycleNum profNum phaseNum measDate]];
                  o_dataFLNTUMeanDateTrans = [o_dataFLNTUMeanDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                  o_dataFLNTUMeanPres = [o_dataFLNTUMeanPres; [cycleNum profNum phaseNum measPres]];
                  o_dataFLNTUMeanChloro = [o_dataFLNTUMeanChloro; [cycleNum profNum phaseNum measChloro]];
                  o_dataFLNTUMeanTurbi = [o_dataFLNTUMeanTurbi; [cycleNum profNum phaseNum measTurbi]];
                  
                  o_cyProfPhaseList = [o_cyProfPhaseList; ...
                     packType sensorDataType cycleNum profNum phaseNum sbdFileDate];
                  
               case {16}
                  % FLNTU (stDev & median)
                  
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
                  
               case {37}
                  % CYCLOPS mean
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [16 8 8 32 repmat([16 16], 1, 32) 16];
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
                  
                  measDate = ones(1, 32)*g_decArgo_dateDef;
                  measDate(1) = epoch2000_2_julian(values(4));
                  measDateTrans = zeros(1, 32);
                  
                  measPres = [];
                  measChloro = [];
                  for idBin = 1:32
                     measPres = [measPres values(2*(idBin-1)+5)];
                     measChloro = [measChloro values(2*(idBin-1)+6)];
                  end
                  measDateTrans(1) = 1;
                  measDateTrans(find((measPres == 0) & (measChloro == 0))) = -1;
                  
                  o_dataCYCLOPSMeanDate = [o_dataCYCLOPSMeanDate; [cycleNum profNum phaseNum measDate]];
                  o_dataCYCLOPSMeanDateTrans = [o_dataCYCLOPSMeanDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                  o_dataCYCLOPSMeanPres = [o_dataCYCLOPSMeanPres; [cycleNum profNum phaseNum measPres]];
                  o_dataCYCLOPSMeanChloro = [o_dataCYCLOPSMeanChloro; [cycleNum profNum phaseNum measChloro]];
                  
                  o_cyProfPhaseList = [o_cyProfPhaseList; ...
                     packType sensorDataType cycleNum profNum phaseNum sbdFileDate];                  

               case {38}
                  % CYCLOPS (stDev & median)
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [16 8 8 32 repmat([16 8 16], 1, 26)];
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
                  
                  measDate = ones(1, 26)*g_decArgo_dateDef;
                  measDate(1) = epoch2000_2_julian(values(4));
                  measDateTrans = zeros(1, 26);
                  
                  measPresMean = [];
                  measChloroStd = [];
                  measChloroMed = [];
                  for idBin = 1:26
                     measPresMean = [measPresMean values(3*(idBin-1)+5)];
                     measChloroStd = [measChloroStd values(3*(idBin-1)+6)];
                     measChloroMed = [measChloroMed values(3*(idBin-1)+7)];
                  end
                  measDateTrans(1) = 1;
                  measDateTrans(find((measPresMean == 0) & (measChloroStd == 0) & (measChloroMed == 0))) = -1;
                  
                  o_dataCYCLOPSStdMedDate = [o_dataCYCLOPSStdMedDate; [cycleNum profNum phaseNum measDate]];
                  o_dataCYCLOPSStdMedDateTrans = [o_dataCYCLOPSStdMedDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                  o_dataCYCLOPSStdMedPresMean  = [o_dataCYCLOPSStdMedPresMean; [cycleNum profNum phaseNum measPresMean]];
                  o_dataCYCLOPSStdMedChloroStd  = [o_dataCYCLOPSStdMedChloroStd; [cycleNum profNum phaseNum measChloroStd]];
                  o_dataCYCLOPSStdMedChloroMed  = [o_dataCYCLOPSStdMedChloroMed; [cycleNum profNum phaseNum measChloroMed]];
                  
                  o_cyProfPhaseList = [o_cyProfPhaseList; ...
                     packType sensorDataType cycleNum profNum phaseNum sbdFileDate];

               case {40}
                  % SEAPOINT mean
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [16 8 8 32 repmat([16 16], 1, 32) 16];
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
                  
                  measDate = ones(1, 32)*g_decArgo_dateDef;
                  measDate(1) = epoch2000_2_julian(values(4));
                  measDateTrans = zeros(1, 32);
                  
                  measPres = [];
                  measTurbi = [];
                  for idBin = 1:32
                     measPres = [measPres values(2*(idBin-1)+5)];
                     measTurbi = [measTurbi values(2*(idBin-1)+6)];
                  end
                  measDateTrans(1) = 1;
                  measDateTrans(find((measPres == 0) & (measTurbi == 0))) = -1;
                  
                  o_dataSEAPOINTMeanDate = [o_dataSEAPOINTMeanDate; [cycleNum profNum phaseNum measDate]];
                  o_dataSEAPOINTMeanDateTrans = [o_dataSEAPOINTMeanDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                  o_dataSEAPOINTMeanPres = [o_dataSEAPOINTMeanPres; [cycleNum profNum phaseNum measPres]];
                  o_dataSEAPOINTMeanTurbi = [o_dataSEAPOINTMeanTurbi; [cycleNum profNum phaseNum measTurbi]];
                  
                  o_cyProfPhaseList = [o_cyProfPhaseList; ...
                     packType sensorDataType cycleNum profNum phaseNum sbdFileDate];      

               case {41}
                  % SEAPOINT (stDev & median)
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [16 8 8 32 repmat([16 8 16], 1, 26)];
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
                  
                  measDate = ones(1, 26)*g_decArgo_dateDef;
                  measDate(1) = epoch2000_2_julian(values(4));
                  measDateTrans = zeros(1, 26);
                  
                  measPresMean = [];
                  measTurbiStd = [];
                  measTurbiMed = [];
                  for idBin = 1:26
                     measPresMean = [measPresMean values(3*(idBin-1)+5)];
                     measTurbiStd = [measTurbiStd values(3*(idBin-1)+6)];
                     measTurbiMed = [measTurbiMed values(3*(idBin-1)+7)];
                  end
                  measDateTrans(1) = 1;
                  measDateTrans(find((measPresMean == 0) & (measTurbiStd == 0) & (measTurbiMed == 0))) = -1;
                  
                  o_dataSEAPOINTStdMedDate = [o_dataSEAPOINTStdMedDate; [cycleNum profNum phaseNum measDate]];
                  o_dataSEAPOINTStdMedDateTrans = [o_dataSEAPOINTStdMedDateTrans; [cycleNum profNum phaseNum measDateTrans]];
                  o_dataSEAPOINTStdMedPresMean  = [o_dataSEAPOINTStdMedPresMean; [cycleNum profNum phaseNum measPresMean]];
                  o_dataSEAPOINTStdMedTurbiStd  = [o_dataSEAPOINTStdMedTurbiStd; [cycleNum profNum phaseNum measTurbiStd]];
                  o_dataSEAPOINTStdMedTurbiMed  = [o_dataSEAPOINTStdMedTurbiMed; [cycleNum profNum phaseNum measTurbiMed]];
                  
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
                  
               case 7
                  % CYCLOPS
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [8 32 32 32 32 8 8 248];
                  % get item bits
                  values = get_bits(firstBit, tabNbBits, msgData);
                  
                  % decode and store data values
                  measAvgSampMax = swapbytes(uint8(values(1)));
                  measCalib1Volts = typecast(uint32(swapbytes(uint32(values(2)))), 'single');
                  measCalib1PhysicalValue = typecast(uint32(swapbytes(uint32(values(3)))), 'single');
                  measCalib2Volts = typecast(uint32(swapbytes(uint32(values(4)))), 'single');
                  measCalib2PhysicalValue = typecast(uint32(swapbytes(uint32(values(5)))), 'single');
                  measOpenDrainOutputUsedForSensorGain = swapbytes(uint8(values(6)));
                  measOpenDrainOutputState = swapbytes(uint8(values(7)));
                  
                  o_sensorTechCYCLOPSNbPackDesc = [o_sensorTechCYCLOPSNbPackDesc; cycleNum profNum nbPackDesc];
                  o_sensorTechCYCLOPSNbPackDrift = [o_sensorTechCYCLOPSNbPackDrift; cycleNum profNum nbPackDrift];
                  o_sensorTechCYCLOPSNbPackAsc = [o_sensorTechCYCLOPSNbPackAsc; cycleNum profNum nbPackAsc];
                  o_sensorTechCYCLOPSNbMeasDescZ1 = [o_sensorTechCYCLOPSNbMeasDescZ1; cycleNum profNum nbMeasDescZ1];
                  o_sensorTechCYCLOPSNbMeasDescZ2 = [o_sensorTechCYCLOPSNbMeasDescZ2; cycleNum profNum nbMeasDescZ2];
                  o_sensorTechCYCLOPSNbMeasDescZ3 = [o_sensorTechCYCLOPSNbMeasDescZ3; cycleNum profNum nbMeasDescZ3];
                  o_sensorTechCYCLOPSNbMeasDescZ4 = [o_sensorTechCYCLOPSNbMeasDescZ4; cycleNum profNum nbMeasDescZ4];
                  o_sensorTechCYCLOPSNbMeasDescZ5 = [o_sensorTechCYCLOPSNbMeasDescZ5; cycleNum profNum nbMeasDescZ5];
                  o_sensorTechCYCLOPSNbMeasDrift = [o_sensorTechCYCLOPSNbMeasDrift; cycleNum profNum nbMeasDrift];
                  o_sensorTechCYCLOPSNbMeasAscZ1 = [o_sensorTechCYCLOPSNbMeasAscZ1; cycleNum profNum nbMeasAscZ1];
                  o_sensorTechCYCLOPSNbMeasAscZ2 = [o_sensorTechCYCLOPSNbMeasAscZ2; cycleNum profNum nbMeasAscZ2];
                  o_sensorTechCYCLOPSNbMeasAscZ3 = [o_sensorTechCYCLOPSNbMeasAscZ3; cycleNum profNum nbMeasAscZ3];
                  o_sensorTechCYCLOPSNbMeasAscZ4 = [o_sensorTechCYCLOPSNbMeasAscZ4; cycleNum profNum nbMeasAscZ4];
                  o_sensorTechCYCLOPSNbMeasAscZ5 = [o_sensorTechCYCLOPSNbMeasAscZ5; cycleNum profNum nbMeasAscZ5];
                  o_sensorTechCYCLOPSSensorState = [o_sensorTechCYCLOPSSensorState; cycleNum profNum sensorState];
                  o_sensorTechCYCLOPSAvgSampMax = [o_sensorTechCYCLOPSAvgSampMax; cycleNum profNum measAvgSampMax];
                  o_sensorTechCYCLOPSCalib1Volts = [o_sensorTechCYCLOPSCalib1Volts; cycleNum profNum measCalib1Volts];
                  o_sensorTechCYCLOPSCalib1PhysicalValue = [o_sensorTechCYCLOPSCalib1PhysicalValue; cycleNum profNum measCalib1PhysicalValue];
                  o_sensorTechCYCLOPSCalib2Volts = [o_sensorTechCYCLOPSCalib2Volts; cycleNum profNum measCalib2Volts];                  
                  o_sensorTechCYCLOPSCalib2PhysicalValue = [o_sensorTechCYCLOPSCalib2PhysicalValue; cycleNum profNum measCalib2PhysicalValue];                  
                  o_sensorTechCYCLOPSOpenDrainOutputUsedForSensorGain = [o_sensorTechCYCLOPSOpenDrainOutputUsedForSensorGain; cycleNum profNum measOpenDrainOutputUsedForSensorGain];                  
                  o_sensorTechCYCLOPSOpenDrainOutputState = [o_sensorTechCYCLOPSOpenDrainOutputState; cycleNum profNum measOpenDrainOutputState];                  
                  
               case 8
                  % SEAPOINT
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [8 32 32 32 32 8 8 248];
                  % get item bits
                  values = get_bits(firstBit, tabNbBits, msgData);
                  
                  % decode and store data values
                  measAvgSampMax = swapbytes(uint8(values(1)));
                  measCalib1Volts = typecast(uint32(swapbytes(uint32(values(2)))), 'single');
                  measCalib1PhysicalValue = typecast(uint32(swapbytes(uint32(values(3)))), 'single');
                  measCalib2Volts = typecast(uint32(swapbytes(uint32(values(4)))), 'single');
                  measCalib2PhysicalValue = typecast(uint32(swapbytes(uint32(values(5)))), 'single');
                  measOpenDrainOutputUsedForSensorGain = swapbytes(uint8(values(6)));
                  measOpenDrainOutputState = swapbytes(uint8(values(7)));
                  
                  o_sensorTechSEAPOINTNbPackDesc = [o_sensorTechSEAPOINTNbPackDesc; cycleNum profNum nbPackDesc];
                  o_sensorTechSEAPOINTNbPackDrift = [o_sensorTechSEAPOINTNbPackDrift; cycleNum profNum nbPackDrift];
                  o_sensorTechSEAPOINTNbPackAsc = [o_sensorTechSEAPOINTNbPackAsc; cycleNum profNum nbPackAsc];
                  o_sensorTechSEAPOINTNbMeasDescZ1 = [o_sensorTechSEAPOINTNbMeasDescZ1; cycleNum profNum nbMeasDescZ1];
                  o_sensorTechSEAPOINTNbMeasDescZ2 = [o_sensorTechSEAPOINTNbMeasDescZ2; cycleNum profNum nbMeasDescZ2];
                  o_sensorTechSEAPOINTNbMeasDescZ3 = [o_sensorTechSEAPOINTNbMeasDescZ3; cycleNum profNum nbMeasDescZ3];
                  o_sensorTechSEAPOINTNbMeasDescZ4 = [o_sensorTechSEAPOINTNbMeasDescZ4; cycleNum profNum nbMeasDescZ4];
                  o_sensorTechSEAPOINTNbMeasDescZ5 = [o_sensorTechSEAPOINTNbMeasDescZ5; cycleNum profNum nbMeasDescZ5];
                  o_sensorTechSEAPOINTNbMeasDrift = [o_sensorTechSEAPOINTNbMeasDrift; cycleNum profNum nbMeasDrift];
                  o_sensorTechSEAPOINTNbMeasAscZ1 = [o_sensorTechSEAPOINTNbMeasAscZ1; cycleNum profNum nbMeasAscZ1];
                  o_sensorTechSEAPOINTNbMeasAscZ2 = [o_sensorTechSEAPOINTNbMeasAscZ2; cycleNum profNum nbMeasAscZ2];
                  o_sensorTechSEAPOINTNbMeasAscZ3 = [o_sensorTechSEAPOINTNbMeasAscZ3; cycleNum profNum nbMeasAscZ3];
                  o_sensorTechSEAPOINTNbMeasAscZ4 = [o_sensorTechSEAPOINTNbMeasAscZ4; cycleNum profNum nbMeasAscZ4];
                  o_sensorTechSEAPOINTNbMeasAscZ5 = [o_sensorTechSEAPOINTNbMeasAscZ5; cycleNum profNum nbMeasAscZ5];
                  o_sensorTechSEAPOINTSensorState = [o_sensorTechSEAPOINTSensorState; cycleNum profNum sensorState];
                  o_sensorTechSEAPOINTAvgSampMax = [o_sensorTechSEAPOINTAvgSampMax; cycleNum profNum measAvgSampMax];
                  o_sensorTechSEAPOINTCalib1Volts = [o_sensorTechSEAPOINTCalib1Volts; cycleNum profNum measCalib1Volts];
                  o_sensorTechSEAPOINTCalib1PhysicalValue = [o_sensorTechSEAPOINTCalib1PhysicalValue; cycleNum profNum measCalib1PhysicalValue];
                  o_sensorTechSEAPOINTCalib2Volts = [o_sensorTechSEAPOINTCalib2Volts; cycleNum profNum measCalib2Volts];                  
                  o_sensorTechSEAPOINTCalib2PhysicalValue = [o_sensorTechSEAPOINTCalib2PhysicalValue; cycleNum profNum measCalib2PhysicalValue];                  
                  o_sensorTechSEAPOINTOpenDrainOutputUsedForSensorGain = [o_sensorTechSEAPOINTOpenDrainOutputUsedForSensorGain; cycleNum profNum measOpenDrainOutputUsedForSensorGain];                  
                  o_sensorTechSEAPOINTOpenDrainOutputState = [o_sensorTechSEAPOINTOpenDrainOutputState; cycleNum profNum measOpenDrainOutputState];                  

               otherwise
                  fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet for sensor tech data type #%d\n', ...
                     g_decArgo_floatNum, ...
                     g_decArgo_cycleNum, ...
                     sensorType);
            end
            
         case 251
            % sensor parameter
            
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
            
            if (a_procLevel == 0)
               g_decArgo_253TypeReceivedData = [g_decArgo_253TypeReceivedData; ...
                  tabTech(9) tabTech(10) tabTech(13)];
               continue
            end
            
            cycleNum = tabTech(9);
            g_decArgo_cycleNum = cycleNum;

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
            g_decArgo_cycleNum = cycleNum;
            
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
            
            if (a_procLevel == 0)
               g_decArgo_255TypeReceivedData = [g_decArgo_255TypeReceivedData; ...
                  values(7) values(8)];
               continue
            end

            g_decArgo_cycleNum = values(7);
            
            % BUG! for the Arvor CM: CONFIG_PM_7 = 1 (even if the float
            % transmits CONFIG_PM_7 = 0)
            values(39) = 1;

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
o_dataOXYMean{4} = o_dataOXYMeanDPhase;
o_dataOXYMean{5} = o_dataOXYMeanTemp;

o_dataOXYStdMed{1} = o_dataOXYStdMedDate;
o_dataOXYStdMed{2} = o_dataOXYStdMedDateTrans;
o_dataOXYStdMed{3} = o_dataOXYStdMedPresMean;
o_dataOXYStdMed{4} = o_dataOXYStdMedDPhaseStd;
o_dataOXYStdMed{5} = o_dataOXYStdMedTempStd;
o_dataOXYStdMed{6} = o_dataOXYStdMedDPhaseMed;
o_dataOXYStdMed{7} = o_dataOXYStdMedTempMed;

o_dataOXY{1} = o_dataOXYMean;
o_dataOXY{2} = o_dataOXYStdMed;

o_dataFLNTUMean{1} = o_dataFLNTUMeanDate;
o_dataFLNTUMean{2} = o_dataFLNTUMeanDateTrans;
o_dataFLNTUMean{3} = o_dataFLNTUMeanPres;
o_dataFLNTUMean{4} = o_dataFLNTUMeanChloro;
o_dataFLNTUMean{5} = o_dataFLNTUMeanTurbi;

o_dataFLNTUStdMed{1} = o_dataFLNTUStdMedDate;
o_dataFLNTUStdMed{2} = o_dataFLNTUStdMedDateTrans;
o_dataFLNTUStdMed{3} = o_dataFLNTUStdMedPresMean;
o_dataFLNTUStdMed{4} = o_dataFLNTUStdMedChloroStd;
o_dataFLNTUStdMed{5} = o_dataFLNTUStdMedTurbiStd;
o_dataFLNTUStdMed{6} = o_dataFLNTUStdMedChloroMed;
o_dataFLNTUStdMed{7} = o_dataFLNTUStdMedTurbiMed;

o_dataFLNTU{1} = o_dataFLNTUMean;
o_dataFLNTU{2} = o_dataFLNTUStdMed;

if (~isempty(o_dataCYCLOPSMeanDate) || ~isempty(o_dataCYCLOPSStdMedDate))
   o_dataCYCLOPSMean{1} = o_dataCYCLOPSMeanDate;
   o_dataCYCLOPSMean{2} = o_dataCYCLOPSMeanDateTrans;
   o_dataCYCLOPSMean{3} = o_dataCYCLOPSMeanPres;
   o_dataCYCLOPSMean{4} = o_dataCYCLOPSMeanChloro;
   
   o_dataCYCLOPSStdMed{1} = o_dataCYCLOPSStdMedDate;
   o_dataCYCLOPSStdMed{2} = o_dataCYCLOPSStdMedDateTrans;
   o_dataCYCLOPSStdMed{3} = o_dataCYCLOPSStdMedPresMean;
   o_dataCYCLOPSStdMed{4} = o_dataCYCLOPSStdMedChloroStd;
   o_dataCYCLOPSStdMed{5} = o_dataCYCLOPSStdMedChloroMed;
   
   o_dataCYCLOPS{1} = o_dataCYCLOPSMean;
   o_dataCYCLOPS{2} = o_dataCYCLOPSStdMed;
end

if (~isempty(o_dataSEAPOINTMeanDate) || ~isempty(o_dataSEAPOINTStdMedDate))
   o_dataSEAPOINTMean{1} = o_dataSEAPOINTMeanDate;
   o_dataSEAPOINTMean{2} = o_dataSEAPOINTMeanDateTrans;
   o_dataSEAPOINTMean{3} = o_dataSEAPOINTMeanPres;
   o_dataSEAPOINTMean{4} = o_dataSEAPOINTMeanTurbi;
   
   o_dataSEAPOINTStdMed{1} = o_dataSEAPOINTStdMedDate;
   o_dataSEAPOINTStdMed{2} = o_dataSEAPOINTStdMedDateTrans;
   o_dataSEAPOINTStdMed{3} = o_dataSEAPOINTStdMedPresMean;
   o_dataSEAPOINTStdMed{4} = o_dataSEAPOINTStdMedTurbiStd;
   o_dataSEAPOINTStdMed{5} = o_dataSEAPOINTStdMedTurbiMed;
   
   o_dataSEAPOINT{1} = o_dataSEAPOINTMean;
   o_dataSEAPOINT{2} = o_dataSEAPOINTStdMed;
end

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

if (~isempty(o_sensorTechCYCLOPSNbPackDesc))
   o_sensorTechCYCLOPS{1} = o_sensorTechCYCLOPSNbPackDesc;
   o_sensorTechCYCLOPS{2} = o_sensorTechCYCLOPSNbPackDrift;
   o_sensorTechCYCLOPS{3} = o_sensorTechCYCLOPSNbPackAsc;
   o_sensorTechCYCLOPS{4} = o_sensorTechCYCLOPSNbMeasDescZ1;
   o_sensorTechCYCLOPS{5} = o_sensorTechCYCLOPSNbMeasDescZ2;
   o_sensorTechCYCLOPS{6} = o_sensorTechCYCLOPSNbMeasDescZ3;
   o_sensorTechCYCLOPS{7} = o_sensorTechCYCLOPSNbMeasDescZ4;
   o_sensorTechCYCLOPS{8} = o_sensorTechCYCLOPSNbMeasDescZ5;
   o_sensorTechCYCLOPS{9} = o_sensorTechCYCLOPSNbMeasDrift;
   o_sensorTechCYCLOPS{10} = o_sensorTechCYCLOPSNbMeasAscZ1;
   o_sensorTechCYCLOPS{11} = o_sensorTechCYCLOPSNbMeasAscZ2;
   o_sensorTechCYCLOPS{12} = o_sensorTechCYCLOPSNbMeasAscZ3;
   o_sensorTechCYCLOPS{13} = o_sensorTechCYCLOPSNbMeasAscZ4;
   o_sensorTechCYCLOPS{14} = o_sensorTechCYCLOPSNbMeasAscZ5;
   o_sensorTechCYCLOPS{15} = o_sensorTechCYCLOPSSensorState;
   o_sensorTechCYCLOPS{16} = o_sensorTechCYCLOPSAvgSampMax;
   o_sensorTechCYCLOPS{17} = o_sensorTechCYCLOPSCalib1Volts;
   o_sensorTechCYCLOPS{18} = o_sensorTechCYCLOPSCalib1PhysicalValue;
   o_sensorTechCYCLOPS{19} = o_sensorTechCYCLOPSCalib2Volts;
   o_sensorTechCYCLOPS{20} = o_sensorTechCYCLOPSCalib2PhysicalValue;
   o_sensorTechCYCLOPS{21} = o_sensorTechCYCLOPSOpenDrainOutputUsedForSensorGain;
   o_sensorTechCYCLOPS{22} = o_sensorTechCYCLOPSOpenDrainOutputState;
end

if (~isempty(o_sensorTechSEAPOINTNbPackDesc))
   o_sensorTechSEAPOINT{1} = o_sensorTechSEAPOINTNbPackDesc;
   o_sensorTechSEAPOINT{2} = o_sensorTechSEAPOINTNbPackDrift;
   o_sensorTechSEAPOINT{3} = o_sensorTechSEAPOINTNbPackAsc;
   o_sensorTechSEAPOINT{4} = o_sensorTechSEAPOINTNbMeasDescZ1;
   o_sensorTechSEAPOINT{5} = o_sensorTechSEAPOINTNbMeasDescZ2;
   o_sensorTechSEAPOINT{6} = o_sensorTechSEAPOINTNbMeasDescZ3;
   o_sensorTechSEAPOINT{7} = o_sensorTechSEAPOINTNbMeasDescZ4;
   o_sensorTechSEAPOINT{8} = o_sensorTechSEAPOINTNbMeasDescZ5;
   o_sensorTechSEAPOINT{9} = o_sensorTechSEAPOINTNbMeasDrift;
   o_sensorTechSEAPOINT{10} = o_sensorTechSEAPOINTNbMeasAscZ1;
   o_sensorTechSEAPOINT{11} = o_sensorTechSEAPOINTNbMeasAscZ2;
   o_sensorTechSEAPOINT{12} = o_sensorTechSEAPOINTNbMeasAscZ3;
   o_sensorTechSEAPOINT{13} = o_sensorTechSEAPOINTNbMeasAscZ4;
   o_sensorTechSEAPOINT{14} = o_sensorTechSEAPOINTNbMeasAscZ5;
   o_sensorTechSEAPOINT{15} = o_sensorTechSEAPOINTSensorState;
   o_sensorTechSEAPOINT{16} = o_sensorTechSEAPOINTAvgSampMax;
   o_sensorTechSEAPOINT{17} = o_sensorTechSEAPOINTCalib1Volts;
   o_sensorTechSEAPOINT{18} = o_sensorTechSEAPOINTCalib1PhysicalValue;
   o_sensorTechSEAPOINT{19} = o_sensorTechSEAPOINTCalib2Volts;
   o_sensorTechSEAPOINT{20} = o_sensorTechSEAPOINTCalib2PhysicalValue;
   o_sensorTechSEAPOINT{21} = o_sensorTechSEAPOINTOpenDrainOutputUsedForSensorGain;
   o_sensorTechSEAPOINT{22} = o_sensorTechSEAPOINTOpenDrainOutputState;
end

o_sensorParam{1} = o_sensorParamModSensorNum;
o_sensorParam{2} = o_sensorParamParamType;
o_sensorParam{3} = o_sensorParamParamNum;
o_sensorParam{4} = o_sensorParamOldVal;
o_sensorParam{5} = o_sensorParamNewVal;

o_floatPres{1} = o_floatPresPumpOrEv;
o_floatPres{2} = o_floatPresActPres;
o_floatPres{3} = o_floatPresTime;

return
