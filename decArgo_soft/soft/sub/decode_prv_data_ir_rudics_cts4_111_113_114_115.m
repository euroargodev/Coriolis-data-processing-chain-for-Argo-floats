% ------------------------------------------------------------------------------
% Decode PROVOR packet data.
%
% SYNTAX :
%  [o_decodedData] = decode_prv_data_ir_rudics_cts4_111_113_114_115( ...
%    a_tabData, a_sbdFileName, a_sbdFileDate, a_sbdFileSize)
%
% INPUT PARAMETERS :
%   a_tabData     : data packet to decode
%   a_sbdFileName : SBD file name
%   a_sbdFileDate : SBD file date
%   a_sbdFileSize : SBD file size
%
% OUTPUT PARAMETERS :
%   o_decodedData : decoded data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/10/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decodedData] = decode_prv_data_ir_rudics_cts4_111_113_114_115( ...
   a_tabData, a_sbdFileName, a_sbdFileDate, a_sbdFileSize)

% output parameters initialization
o_decodedData = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_dateDef;
global g_decArgo_janFirst1950InMatlab;

% sensor list
global g_decArgo_sensorList;
global g_decArgo_sensorMountedOnFloat;


% packet type
packType = a_tabData(1);

% structure to store decoded data
decodedData = get_decoded_data_cts4_init_struct;
decodedData.fileName = a_sbdFileName;
decodedData.fileDate = a_sbdFileDate;
decodedData.fileSize = a_sbdFileSize;
% decodedData.rawData = msgData;
decodedData.cyNumFile = g_decArgo_cycleNum;
decodedData.packType = packType;

% decode packet data

switch (packType)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 0
      % sensor data
      
      % sensor data type
      sensorDataType = a_tabData(2);
      decodedData.sensorDataType = sensorDataType;
      
      % message data frame
      msgData = a_tabData(3:end);
      
      % empty msg
      if (~any(msgData ~= 0))
         return
      end
      
      decData = [];
      switch (sensorDataType)
         
         case {0, 2}
            % CTD (mean & raw)
            
            if (~ismember(0, g_decArgo_sensorList))
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) - ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  sensorDataType, 0);
               return
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
            
            measDate = ones(1, 21)*g_decArgo_dateDef;
            measDate(1) = epoch2000_2_julian(values(4));
            measDateTrans = zeros(1, 21);
            
            measPres = nan(1, 21);
            measTemp = nan(1, 21);
            measSal = nan(1, 21);
            for idBin = 1:21
               measPres(idBin) = values(3*(idBin-1)+5);
               measTemp(idBin) = values(3*(idBin-1)+6);
               measSal(idBin) = values(3*(idBin-1)+7);
            end
            measDateTrans(1) = 1;
            measDateTrans(find((measPres == 0) & (measTemp == 0) & (measSal == 0))) = -1;
            
            decData{1} = [cycleNum profNum phaseNum measDate];
            decData{2} = [cycleNum profNum phaseNum measDateTrans];
            decData{3} = [cycleNum profNum phaseNum measPres];
            decData{4} = [cycleNum profNum phaseNum measTemp];
            decData{5} = [cycleNum profNum phaseNum measSal];
            
            cyProfPhaseList = [packType sensorDataType cycleNum profNum phaseNum a_sbdFileDate];
            
            decodedData.decData = decData;
            decodedData.cyProfPhaseList = cyProfPhaseList;
            decodedData.cyNumRaw = cycleNum;
            decodedData.profNumRaw = profNum;
            decodedData.phaseNumRaw = phaseNum;
            
         case {1}
            % CTD (stDev & median)
            
            if (~ismember(0, g_decArgo_sensorList))
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) - ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  sensorDataType, 0);
               return
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
            
            measDate = ones(1, 13)*g_decArgo_dateDef;
            measDate(1) = epoch2000_2_julian(values(4));
            measDateTrans = zeros(1, 13);
            
            measPresMean = nan(1, 13);
            measTempStd = nan(1, 13);
            measSalStd = nan(1, 13);
            measPresMed = nan(1, 13);
            measTempMed = nan(1, 13);
            measSalMed = nan(1, 13);
            for idBin = 1:13
               measPresMean(idBin) = values(6*(idBin-1)+5);
               measTempStd(idBin) = values(6*(idBin-1)+6);
               measSalStd(idBin) = values(6*(idBin-1)+7);
               measPresMed(idBin) = values(6*(idBin-1)+8);
               measTempMed(idBin) = values(6*(idBin-1)+9);
               measSalMed(idBin) = values(6*(idBin-1)+10);
            end
            measDateTrans(1) = 1;
            measDateTrans(find((measPresMean == 0) & (measTempStd == 0) & (measSalStd == 0) & ...
               (measPresMed == 0) & (measTempMed == 0) & (measSalMed == 0))) = -1;
            
            decData{1} = [cycleNum profNum phaseNum measDate];
            decData{2} = [cycleNum profNum phaseNum measDateTrans];
            decData{3} = [cycleNum profNum phaseNum measPresMean];
            decData{4} = [cycleNum profNum phaseNum measTempStd];
            decData{5} = [cycleNum profNum phaseNum measSalStd];
            decData{6} = [cycleNum profNum phaseNum measPresMed];
            decData{7} = [cycleNum profNum phaseNum measTempMed];
            decData{8} = [cycleNum profNum phaseNum measSalMed];
            
            cyProfPhaseList = [packType sensorDataType cycleNum profNum phaseNum a_sbdFileDate];
            
            decodedData.decData = decData;
            decodedData.cyProfPhaseList = cyProfPhaseList;
            decodedData.cyNumRaw = cycleNum;
            decodedData.profNumRaw = profNum;
            decodedData.phaseNumRaw = phaseNum;
            
         case {3, 5}
            % OXYGEN (mean & raw)
            
            if (~ismember(1, g_decArgo_sensorList))
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) - ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  sensorDataType, 1);
               return
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
            
            measDate = ones(1, 10)*g_decArgo_dateDef;
            measDate(1) = epoch2000_2_julian(values(4));
            measDateTrans = zeros(1, 10);
            
            measPres = nan(1, 10);
            measC1Phase = nan(1, 10);
            measC2Phase = nan(1, 10);
            measTemp = nan(1, 10);
            for idBin = 1:10
               measPres(idBin) = values(4*(idBin-1)+5);
               measC1Phase(idBin) = twos_complement_dec_argo(values(4*(idBin-1)+6), 32);
               measC2Phase(idBin) = twos_complement_dec_argo(values(4*(idBin-1)+7), 32);
               measTemp(idBin) = values(4*(idBin-1)+8);
            end
            measDateTrans(1) = 1;
            measDateTrans(find((measPres == 0) & (measC1Phase == 0) & (measC2Phase == 0) & (measTemp == 0))) = -1;
            
            decData{1} = [cycleNum profNum phaseNum measDate];
            decData{2} = [cycleNum profNum phaseNum measDateTrans];
            decData{3} = [cycleNum profNum phaseNum measPres];
            decData{4} = [cycleNum profNum phaseNum measC1Phase];
            decData{5} = [cycleNum profNum phaseNum measC2Phase];
            decData{6} = [cycleNum profNum phaseNum measTemp];
            
            cyProfPhaseList = [packType sensorDataType cycleNum profNum phaseNum a_sbdFileDate];
            
            decodedData.decData = decData;
            decodedData.cyProfPhaseList = cyProfPhaseList;
            decodedData.cyNumRaw = cycleNum;
            decodedData.profNumRaw = profNum;
            decodedData.phaseNumRaw = phaseNum;
            
         case {4}
            % OXYGEN (stDev & median)
            
            if (~ismember(1, g_decArgo_sensorList))
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) - ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  sensorDataType, 1);
               return
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
            
            measDate = ones(1, 7)*g_decArgo_dateDef;
            measDate(1) = epoch2000_2_julian(values(4));
            measDateTrans = zeros(1, 7);
            
            measPresMean = nan(1, 7);
            measC1PhaseStd = nan(1, 7);
            measC2PhaseStd = nan(1, 7);
            measTempStd = nan(1, 7);
            measC1PhaseMed = nan(1, 7);
            measC2PhaseMed = nan(1, 7);
            measTempMed = nan(1, 7);
            for idBin = 1:7
               measPresMean(idBin) = values(7*(idBin-1)+5);
               measC1PhaseStd(idBin) = values(7*(idBin-1)+6);
               measC2PhaseStd(idBin) = values(7*(idBin-1)+7);
               measTempStd(idBin) = values(7*(idBin-1)+8);
               measC1PhaseMed(idBin) = twos_complement_dec_argo(values(7*(idBin-1)+9), 32);
               measC2PhaseMed(idBin) = twos_complement_dec_argo(values(7*(idBin-1)+10), 32);
               measTempMed(idBin) = values(7*(idBin-1)+11);
            end
            measDateTrans(1) = 1;
            measDateTrans(find((measPresMean == 0) & (measC1PhaseStd == 0) & ...
               (measC2PhaseStd == 0) & (measTempStd == 0) & ...
               (measC1PhaseMed == 0) & (measC2PhaseMed == 0) & (measTempMed == 0))) = -1;
            
            decData{1} = [cycleNum profNum phaseNum measDate];
            decData{2} = [cycleNum profNum phaseNum measDateTrans];
            decData{3} = [cycleNum profNum phaseNum measPresMean];
            decData{4} = [cycleNum profNum phaseNum measC1PhaseStd];
            decData{5} = [cycleNum profNum phaseNum measC2PhaseStd];
            decData{6} = [cycleNum profNum phaseNum measTempStd];
            decData{7} = [cycleNum profNum phaseNum measC1PhaseMed];
            decData{8} = [cycleNum profNum phaseNum measC2PhaseMed];
            decData{9} = [cycleNum profNum phaseNum measTempMed];
            
            cyProfPhaseList = [packType sensorDataType cycleNum profNum phaseNum a_sbdFileDate];
            
            decodedData.decData = decData;
            decodedData.cyProfPhaseList = cyProfPhaseList;
            decodedData.cyNumRaw = cycleNum;
            decodedData.profNumRaw = profNum;
            decodedData.phaseNumRaw = phaseNum;
            
         case {6, 8}
            % ECO2 (mean & raw)
            
            if (~ismember(3, g_decArgo_sensorList))
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) - ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  sensorDataType, 3);
               return
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
            
            measDate = ones(1, 21)*g_decArgo_dateDef;
            measDate(1) = epoch2000_2_julian(values(4));
            measDateTrans = zeros(1, 21);
            
            measPres = nan(1, 21);
            measChloroA = nan(1, 21);
            measBackscat = nan(1, 21);
            for idBin = 1:21
               measPres(idBin) = values(3*(idBin-1)+5);
               measChloroA(idBin) = values(3*(idBin-1)+6);
               measBackscat(idBin) = values(3*(idBin-1)+7);
            end
            measDateTrans(1) = 1;
            measDateTrans(find((measPres == 0) & ...
               (measChloroA == 0) & (measBackscat == 0))) = -1;
            
            decData{1} = [cycleNum profNum phaseNum measDate];
            decData{2} = [cycleNum profNum phaseNum measDateTrans];
            decData{3} = [cycleNum profNum phaseNum measPres];
            decData{4} = [cycleNum profNum phaseNum measChloroA];
            decData{5} = [cycleNum profNum phaseNum measBackscat];
            
            cyProfPhaseList = [packType sensorDataType cycleNum profNum phaseNum a_sbdFileDate];
            
            decodedData.decData = decData;
            decodedData.cyProfPhaseList = cyProfPhaseList;
            decodedData.cyNumRaw = cycleNum;
            decodedData.profNumRaw = profNum;
            decodedData.phaseNumRaw = phaseNum;
            
         case {7}
            % ECO2 (stDev & median)
            
            if (~ismember(3, g_decArgo_sensorList))
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) - ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  sensorDataType, 3);
               return
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
            
            measDate = ones(1, 16)*g_decArgo_dateDef;
            measDate(1) = epoch2000_2_julian(values(4));
            measDateTrans = zeros(1, 16);
            
            measPresMean = nan(1, 16);
            measChloroAStd = nan(1, 16);
            measBackscatStd = nan(1, 16);
            measChloroAMed = nan(1, 16);
            measBackscatMed = nan(1, 16);
            for idBin = 1:16
               measPresMean(idBin) = values(5*(idBin-1)+5);
               measChloroAStd(idBin) = values(5*(idBin-1)+6);
               measBackscatStd(idBin) = values(5*(idBin-1)+7);
               measChloroAMed(idBin) = values(5*(idBin-1)+8);
               measBackscatMed(idBin) = values(5*(idBin-1)+9);
            end
            measDateTrans(1) = 1;
            measDateTrans(find((measPresMean == 0) & ...
               (measChloroAStd == 0) & (measBackscatStd == 0) & ...
               (measChloroAMed == 0) & (measBackscatMed == 0))) = -1;
            
            decData{1} = [cycleNum profNum phaseNum measDate];
            decData{2} = [cycleNum profNum phaseNum measDateTrans];
            decData{3} = [cycleNum profNum phaseNum measPresMean];
            decData{4} = [cycleNum profNum phaseNum measChloroAStd];
            decData{5} = [cycleNum profNum phaseNum measBackscatStd];
            decData{6} = [cycleNum profNum phaseNum measChloroAMed];
            decData{7} = [cycleNum profNum phaseNum measBackscatMed];
            
            cyProfPhaseList = [packType sensorDataType cycleNum profNum phaseNum a_sbdFileDate];
            
            decodedData.decData = decData;
            decodedData.cyProfPhaseList = cyProfPhaseList;
            decodedData.cyNumRaw = cycleNum;
            decodedData.profNumRaw = profNum;
            decodedData.phaseNumRaw = phaseNum;
            
         case {9, 11}
            % ECO3 (mean & raw)
            
            if (~ismember(3, g_decArgo_sensorList))
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) - ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  sensorDataType, 3);
               return
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
            
            measDate = ones(1, 16)*g_decArgo_dateDef;
            measDate(1) = epoch2000_2_julian(values(4));
            measDateTrans = zeros(1, 16);
            
            measPres = nan(1, 16);
            measChloroA = nan(1, 16);
            measBackscat = nan(1, 16);
            measCdom = nan(1, 16);
            for idBin = 1:16
               measPres(idBin) = values(4*(idBin-1)+5);
               measChloroA(idBin) = values(4*(idBin-1)+6);
               measBackscat(idBin) = values(4*(idBin-1)+7);
               measCdom(idBin) = values(4*(idBin-1)+8);
            end
            measDateTrans(1) = 1;
            measDateTrans(find((measPres == 0) & ...
               (measChloroA == 0) & (measBackscat == 0) & (measCdom == 0))) = -1;
            
            decData{1} = [cycleNum profNum phaseNum measDate];
            decData{2} = [cycleNum profNum phaseNum measDateTrans];
            decData{3} = [cycleNum profNum phaseNum measPres];
            decData{4} = [cycleNum profNum phaseNum measChloroA];
            decData{5} = [cycleNum profNum phaseNum measBackscat];
            decData{6} = [cycleNum profNum phaseNum measCdom];
            
            cyProfPhaseList = [packType sensorDataType cycleNum profNum phaseNum a_sbdFileDate];
            
            decodedData.decData = decData;
            decodedData.cyProfPhaseList = cyProfPhaseList;
            decodedData.cyNumRaw = cycleNum;
            decodedData.profNumRaw = profNum;
            decodedData.phaseNumRaw = phaseNum;
            
         case {10}
            % ECO3 (stDev & median)
            
            if (~ismember(3, g_decArgo_sensorList))
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) - ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  sensorDataType, 3);
               return
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
            
            measDate = ones(1, 11)*g_decArgo_dateDef;
            measDate(1) = epoch2000_2_julian(values(4));
            measDateTrans = zeros(1, 11);
            
            measPresMean = nan(1, 11);
            measChloroAStd = nan(1, 11);
            measBackscatStd = nan(1, 11);
            measCdomStd = nan(1, 11);
            measChloroAMed = nan(1, 11);
            measBackscatMed = nan(1, 11);
            measCdomMed = nan(1, 11);
            for idBin = 1:11
               measPresMean(idBin) = values(7*(idBin-1)+5);
               measChloroAStd(idBin) = values(7*(idBin-1)+6);
               measBackscatStd(idBin) = values(7*(idBin-1)+7);
               measCdomStd(idBin) = values(7*(idBin-1)+8);
               measChloroAMed(idBin) = values(7*(idBin-1)+9);
               measBackscatMed(idBin) = values(7*(idBin-1)+10);
               measCdomMed(idBin) = values(7*(idBin-1)+11);
            end
            measDateTrans(1) = 1;
            measDateTrans(find((measPresMean == 0) & ...
               (measChloroAStd == 0) & (measBackscatStd == 0) & (measCdomStd == 0) & ...
               (measChloroAMed == 0) & (measBackscatMed == 0) & (measCdomMed == 0))) = -1;
            
            decData{1} = [cycleNum profNum phaseNum measDate];
            decData{2} = [cycleNum profNum phaseNum measDateTrans];
            decData{3} = [cycleNum profNum phaseNum measPresMean];
            decData{4} = [cycleNum profNum phaseNum measChloroAStd];
            decData{5} = [cycleNum profNum phaseNum measBackscatStd];
            decData{6} = [cycleNum profNum phaseNum measCdomStd];
            decData{7} = [cycleNum profNum phaseNum measChloroAMed];
            decData{8} = [cycleNum profNum phaseNum measBackscatMed];
            decData{9} = [cycleNum profNum phaseNum measCdomMed];
            
            cyProfPhaseList = [packType sensorDataType cycleNum profNum phaseNum a_sbdFileDate];
            
            decodedData.decData = decData;
            decodedData.cyProfPhaseList = cyProfPhaseList;
            decodedData.cyNumRaw = cycleNum;
            decodedData.profNumRaw = profNum;
            decodedData.phaseNumRaw = phaseNum;
            
         case {12, 14}
            % OCR (mean & raw)
            
            if (~ismember(2, g_decArgo_sensorList))
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) - ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  sensorDataType, 2);
               return
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
            
            measDate = ones(1, 7)*g_decArgo_dateDef;
            measDate(1) = epoch2000_2_julian(values(4));
            measDateTrans = zeros(1, 7);
            
            measPres = nan(1, 7);
            measIr1 = nan(1, 7);
            measIr2 = nan(1, 7);
            measIr3 = nan(1, 7);
            measIr4 = nan(1, 7);
            for idBin = 1:7
               measPres(idBin) = values(5*(idBin-1)+5);
               measIr1(idBin) = values(5*(idBin-1)+6);
               measIr2(idBin) = values(5*(idBin-1)+7);
               measIr3(idBin) = values(5*(idBin-1)+8);
               measIr4(idBin) = values(5*(idBin-1)+9);
            end
            measDateTrans(1) = 1;
            measDateTrans(find((measPres == 0) & ...
               (measIr1 == 0) & (measIr2 == 0) & (measIr3 == 0) & (measIr4 == 0))) = -1;
            
            decData{1} = [cycleNum profNum phaseNum measDate];
            decData{2} = [cycleNum profNum phaseNum measDateTrans];
            decData{3} = [cycleNum profNum phaseNum measPres];
            decData{4} = [cycleNum profNum phaseNum measIr1];
            decData{5} = [cycleNum profNum phaseNum measIr2];
            decData{6} = [cycleNum profNum phaseNum measIr3];
            decData{7} = [cycleNum profNum phaseNum measIr4];
            
            cyProfPhaseList = [packType sensorDataType cycleNum profNum phaseNum a_sbdFileDate];
            
            decodedData.decData = decData;
            decodedData.cyProfPhaseList = cyProfPhaseList;
            decodedData.cyNumRaw = cycleNum;
            decodedData.profNumRaw = profNum;
            decodedData.phaseNumRaw = phaseNum;
            
         case {13}
            % OCR (stDev & median)
            
            if (~ismember(2, g_decArgo_sensorList))
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) - ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  sensorDataType, 2);
               return
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
            
            measDate = ones(1, 3)*g_decArgo_dateDef;
            measDate(1) = epoch2000_2_julian(values(4));
            measDateTrans = zeros(1, 3);
            
            measPresMean = nan(1, 3);
            measIr1Std = nan(1, 3);
            measIr2Std = nan(1, 3);
            measIr3Std = nan(1, 3);
            measIr4Std = nan(1, 3);
            measIr1Med = nan(1, 3);
            measIr2Med = nan(1, 3);
            measIr3Med = nan(1, 3);
            measIr4Med = nan(1, 3);
            for idBin = 1:3
               measPresMean(idBin) = values(9*(idBin-1)+5);
               measIr1Std(idBin) = values(9*(idBin-1)+6);
               measIr2Std(idBin) = values(9*(idBin-1)+7);
               measIr3Std(idBin) = values(9*(idBin-1)+8);
               measIr4Std(idBin) = values(9*(idBin-1)+9);
               measIr1Med(idBin) = values(9*(idBin-1)+10);
               measIr2Med(idBin) = values(9*(idBin-1)+11);
               measIr3Med(idBin) = values(9*(idBin-1)+12);
               measIr4Med(idBin) = values(9*(idBin-1)+13);
            end
            measDateTrans(1) = 1;
            measDateTrans(find((measPresMean == 0) & (measIr1Std == 0) & ...
               (measIr2Std == 0) & (measIr3Std == 0) & (measIr4Std == 0) & ...
               (measIr1Med == 0) & (measIr2Med == 0) & (measIr3Med == 0) & (measIr4Med == 0))) = -1;
            
            decData{1} = [cycleNum profNum phaseNum measDate];
            decData{2} = [cycleNum profNum phaseNum measDateTrans];
            decData{3} = [cycleNum profNum phaseNum measPresMean];
            decData{4} = [cycleNum profNum phaseNum measIr1Std];
            decData{5} = [cycleNum profNum phaseNum measIr2Std];
            decData{6} = [cycleNum profNum phaseNum measIr3Std];
            decData{7} = [cycleNum profNum phaseNum measIr4Std];
            decData{8} = [cycleNum profNum phaseNum measIr1Med];
            decData{9} = [cycleNum profNum phaseNum measIr2Med];
            decData{10} = [cycleNum profNum phaseNum measIr3Med];
            decData{11} = [cycleNum profNum phaseNum measIr4Med];
            
            cyProfPhaseList = [packType sensorDataType cycleNum profNum phaseNum a_sbdFileDate];
            
            decodedData.decData = decData;
            decodedData.cyProfPhaseList = cyProfPhaseList;
            decodedData.cyNumRaw = cycleNum;
            decodedData.profNumRaw = profNum;
            decodedData.phaseNumRaw = phaseNum;
            
         case {15, 17}
            % FLNTU (mean & raw)
            
            if (~ismember(4, g_decArgo_sensorList))
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) - ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  sensorDataType, 4);
               return
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
            
            measDate = ones(1, 21)*g_decArgo_dateDef;
            measDate(1) = epoch2000_2_julian(values(4));
            measDateTrans = zeros(1, 21);
            
            measPres = nan(1, 21);
            measChloro = nan(1, 21);
            measTurbi = nan(1, 21);
            for idBin = 1:21
               measPres(idBin) = values(3*(idBin-1)+5);
               measChloro(idBin) = values(3*(idBin-1)+6);
               measTurbi(idBin) = values(3*(idBin-1)+7);
            end
            measDateTrans(1) = 1;
            measDateTrans(find((measPres == 0) & (measChloro == 0) & (measTurbi == 0))) = -1;
            
            decData{1} = [cycleNum profNum phaseNum measDate];
            decData{2} = [cycleNum profNum phaseNum measDateTrans];
            decData{3} = [cycleNum profNum phaseNum measPres];
            decData{4} = [cycleNum profNum phaseNum measChloro];
            decData{5} = [cycleNum profNum phaseNum measTurbi];
            
            cyProfPhaseList = [packType sensorDataType cycleNum profNum phaseNum a_sbdFileDate];
            
            decodedData.decData = decData;
            decodedData.cyProfPhaseList = cyProfPhaseList;
            decodedData.cyNumRaw = cycleNum;
            decodedData.profNumRaw = profNum;
            decodedData.phaseNumRaw = phaseNum;
            
         case {16}
            % FLNTU (stDev & median)
            
            if (~ismember(4, g_decArgo_sensorList))
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) - ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  sensorDataType, 4);
               return
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
            
            measDate = ones(1, 16)*g_decArgo_dateDef;
            measDate(1) = epoch2000_2_julian(values(4));
            measDateTrans = zeros(1, 16);
            
            measPresMean = nan(1, 16);
            measChloroStd = nan(1, 16);
            measTurbiStd = nan(1, 16);
            measChloroMed = nan(1, 16);
            measTurbiMed = nan(1, 16);
            for idBin = 1:16
               measPresMean(idBin) = values(5*(idBin-1)+5);
               measChloroStd(idBin) = values(5*(idBin-1)+6);
               measTurbiStd(idBin) = values(5*(idBin-1)+7);
               measChloroMed(idBin) = values(5*(idBin-1)+8);
               measTurbiMed(idBin) = values(5*(idBin-1)+9);
            end
            measDateTrans(1) = 1;
            measDateTrans(find((measPresMean == 0) & (measChloroStd == 0) & ...
               (measTurbiStd == 0) & (measChloroMed == 0) & (measTurbiMed == 0))) = -1;
            
            decData{1} = [cycleNum profNum phaseNum measDate];
            decData{2} = [cycleNum profNum phaseNum measDateTrans];
            decData{3} = [cycleNum profNum phaseNum measPresMean];
            decData{4} = [cycleNum profNum phaseNum measChloroStd];
            decData{5} = [cycleNum profNum phaseNum measTurbiStd];
            decData{6} = [cycleNum profNum phaseNum measChloroMed];
            decData{7} = [cycleNum profNum phaseNum measTurbiMed];
            
            cyProfPhaseList = [packType sensorDataType cycleNum profNum phaseNum a_sbdFileDate];
            
            decodedData.decData = decData;
            decodedData.cyProfPhaseList = cyProfPhaseList;
            decodedData.cyNumRaw = cycleNum;
            decodedData.profNumRaw = profNum;
            decodedData.phaseNumRaw = phaseNum;
            
         case {18, 20}
            % cROVER (mean & raw)
            
            if (~ismember(5, g_decArgo_sensorList))
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) - ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  sensorDataType, 5);
               return
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
            
            measDate = ones(1, 21)*g_decArgo_dateDef;
            measDate(1) = epoch2000_2_julian(values(4));
            measDateTrans = zeros(1, 21);
            
            measPres = nan(1, 21);
            measCoefAtt = nan(1, 21);
            for idBin = 1:21
               measPres(idBin) = values(2*(idBin-1)+5);
               measCoefAtt(idBin) = twos_complement_dec_argo(values(2*(idBin-1)+6), 32);
            end
            measDateTrans(1) = 1;
            measDateTrans(find((measPres == 0) & (measCoefAtt == 0))) = -1;
            
            decData{1} = [cycleNum profNum phaseNum measDate];
            decData{2} = [cycleNum profNum phaseNum measDateTrans];
            decData{3} = [cycleNum profNum phaseNum measPres];
            decData{4} = [cycleNum profNum phaseNum measCoefAtt];
            
            cyProfPhaseList = [packType sensorDataType cycleNum profNum phaseNum a_sbdFileDate];
            
            decodedData.decData = decData;
            decodedData.cyProfPhaseList = cyProfPhaseList;
            decodedData.cyNumRaw = cycleNum;
            decodedData.profNumRaw = profNum;
            decodedData.phaseNumRaw = phaseNum;
            
         case {19}
            % cRover (stDev & median)
            
            if (~ismember(5, g_decArgo_sensorList))
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) - ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  sensorDataType, 5);
               return
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
            
            measDate = ones(1, 16)*g_decArgo_dateDef;
            measDate(1) = epoch2000_2_julian(values(4));
            measDateTrans = zeros(1, 16);
            
            measPresMean = nan(1, 16);
            measCoefAttStd = nan(1, 16);
            measCoefAttMed = nan(1, 16);
            for idBin = 1:16
               measPresMean(idBin) = values(3*(idBin-1)+5);
               measCoefAttStd(idBin) = values(3*(idBin-1)+6);
               measCoefAttMed(idBin) = twos_complement_dec_argo(values(3*(idBin-1)+7), 32);
            end
            measDateTrans(1) = 1;
            measDateTrans(find((measPresMean == 0) & (measCoefAttStd == 0) & (measCoefAttMed == 0))) = -1;
            
            decData{1} = [cycleNum profNum phaseNum measDate];
            decData{2} = [cycleNum profNum phaseNum measDateTrans];
            decData{3} = [cycleNum profNum phaseNum measPresMean];
            decData{4} = [cycleNum profNum phaseNum measCoefAttStd];
            decData{5} = [cycleNum profNum phaseNum measCoefAttMed];
            
            cyProfPhaseList = [packType sensorDataType cycleNum profNum phaseNum a_sbdFileDate];
            
            decodedData.decData = decData;
            decodedData.cyProfPhaseList = cyProfPhaseList;
            decodedData.cyNumRaw = cycleNum;
            decodedData.profNumRaw = profNum;
            decodedData.phaseNumRaw = phaseNum;
            
         case {21, 23}
            % SUNA (mean & raw)
            
            if (~ismember(6, g_decArgo_sensorList))
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) - ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  sensorDataType, 6);
               return
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
            
            measDate = ones(1, 21)*g_decArgo_dateDef;
            measDate(1) = epoch2000_2_julian(values(4));
            measDateTrans = zeros(1, 21);
            
            measPres = nan(1, 21);
            measConcNitra = nan(1, 21);
            for idBin = 1:21
               measPres(idBin) = values(2*(idBin-1)+5);
               measConcNitra(idBin) = double(typecast(uint32(values(2*(idBin-1)+6)), 'single'));
            end
            measDateTrans(1) = 1;
            measDateTrans(find((measPres == 0) & (measConcNitra == 0))) = -1;
            
            decData{1} = [cycleNum profNum phaseNum measDate];
            decData{2} = [cycleNum profNum phaseNum measDateTrans];
            decData{3} = [cycleNum profNum phaseNum measPres];
            decData{4} = [cycleNum profNum phaseNum measConcNitra];
            
            cyProfPhaseList = [packType sensorDataType cycleNum profNum phaseNum a_sbdFileDate];
            
            decodedData.decData = decData;
            decodedData.cyProfPhaseList = cyProfPhaseList;
            decodedData.cyNumRaw = cycleNum;
            decodedData.profNumRaw = profNum;
            decodedData.phaseNumRaw = phaseNum;
            
         case {22}
            % SUNA (stDev & median)
            
            if (~ismember(6, g_decArgo_sensorList))
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) - ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  sensorDataType, 6);
               return
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
            
            measDate = ones(1, 16)*g_decArgo_dateDef;
            measDate(1) = epoch2000_2_julian(values(4));
            measDateTrans = zeros(1, 16);
            
            measPresMean = nan(1, 16);
            measConcNitraStd = nan(1, 16);
            measConcNitraMed = nan(1, 16);
            for idBin = 1:16
               measPresMean(idBin) = values(3*(idBin-1)+5);
               measConcNitraStd(idBin) = values(3*(idBin-1)+6);
               measConcNitraMed(idBin) = double(typecast(uint32(values(3*(idBin-1)+7)), 'single'));
            end
            measDateTrans(1) = 1;
            measDateTrans(find((measPresMean == 0) & (measConcNitraStd == 0) & (measConcNitraMed == 0))) = -1;
            
            decData{1} = [cycleNum profNum phaseNum measDate];
            decData{2} = [cycleNum profNum phaseNum measDateTrans];
            decData{3} = [cycleNum profNum phaseNum measPresMean];
            decData{4} = [cycleNum profNum phaseNum measConcNitraStd];
            decData{5} = [cycleNum profNum phaseNum measConcNitraMed];
            
            cyProfPhaseList = [packType sensorDataType cycleNum profNum phaseNum a_sbdFileDate];
            
            decodedData.decData = decData;
            decodedData.cyProfPhaseList = cyProfPhaseList;
            decodedData.cyNumRaw = cycleNum;
            decodedData.profNumRaw = profNum;
            decodedData.phaseNumRaw = phaseNum;
            
         case {24, 25}
            % SUNA (APF)
            
            if (~ismember(6, g_decArgo_sensorList))
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) - ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  sensorDataType, 6);
               return
            end
            
            % first item bit number
            firstBit = 1;
            % item bit lengths
            tabNbBits = [16 8 8 32 repmat(32, 1, 10) repmat(16, 1, 45)];
            % get item bits
            values = get_bits(firstBit, tabNbBits, msgData);
            
            % decode and store data values
            cycleNum = values(1);
            profNum = values(2);
            phaseNum = values(3);
            
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
            
            decData{1} = dataSUNAAPFDate;
            decData{2} = dataSUNAAPFDateTrans;
            decData{3} = dataSUNAAPFCTDPres;
            decData{4} = dataSUNAAPFCTDTemp;
            decData{5} = dataSUNAAPFCTDSal;
            decData{6} = dataSUNAAPFIntTemp;
            decData{7} = dataSUNAAPFSpecTemp;
            decData{8} = dataSUNAAPFIntRelHumidity;
            decData{9} = dataSUNAAPFDarkSpecMean;
            decData{10} = dataSUNAAPFDarkSpecStd;
            decData{11} = dataSUNAAPFSensorNitra;
            decData{12} = dataSUNAAPFAbsFitRes;
            decData{13} = dataSUNAAPFOutSpec;
            
            cyProfPhaseList = [packType sensorDataType cycleNum profNum phaseNum a_sbdFileDate];
            
            decodedData.decData = decData;
            decodedData.cyProfPhaseList = cyProfPhaseList;
            decodedData.cyNumRaw = cycleNum;
            decodedData.profNumRaw = profNum;
            decodedData.phaseNumRaw = phaseNum;
            
         case {46, 48}
            % SEAFET (mean & raw)
            
            if (~ismember(4, g_decArgo_sensorList))
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) - ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  sensorDataType, 4);
               return
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
            
            measDate = ones(1, 21)*g_decArgo_dateDef;
            measDate(1) = epoch2000_2_julian(values(4));
            measDateTrans = zeros(1, 21);
            
            measPres = nan(1, 21);
            measVref = nan(1, 21);
            for idBin = 1:21
               measPres(idBin) = values(2*(idBin-1)+5);
               measVref(idBin) = twos_complement_dec_argo(values(2*(idBin-1)+6), 32);
            end
            measDateTrans(1) = 1;
            measDateTrans(find((measPres == 0) & (measVref == 0))) = -1;
            
            decData{1} = [cycleNum profNum phaseNum measDate];
            decData{2} = [cycleNum profNum phaseNum measDateTrans];
            decData{3} = [cycleNum profNum phaseNum measPres];
            decData{4} = [cycleNum profNum phaseNum measVref];
            
            cyProfPhaseList = [packType sensorDataType cycleNum profNum phaseNum a_sbdFileDate];
            
            decodedData.decData = decData;
            decodedData.cyProfPhaseList = cyProfPhaseList;
            decodedData.cyNumRaw = cycleNum;
            decodedData.profNumRaw = profNum;
            decodedData.phaseNumRaw = phaseNum;
            
         case {47}
            % SEAFET (stDev & median)
            
            if (~ismember(4, g_decArgo_sensorList))
               fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor DATA packet received (#%d while sensor #%d is not mounted on the float) - ignoring packet data\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  sensorDataType, 4);
               return
            end
            
            % first item bit number
            firstBit = 1;
            % item bit lengths
            tabNbBits = [16 8 8 32 repmat([16 32 32], 1, 13)];
            % get item bits
            values = get_bits(firstBit, tabNbBits, msgData);
            
            % decode and store data values
            cycleNum = values(1);
            profNum = values(2);
            phaseNum = values(3);
            
            measDate = ones(1, 13)*g_decArgo_dateDef;
            measDate(1) = epoch2000_2_julian(values(4));
            measDateTrans = zeros(1, 13);
            
            measPresMean = nan(1, 13);
            measVrefStd = nan(1, 13);
            measVrefMed = nan(1, 13);
            for idBin = 1:13
               measPresMean(idBin) = values(3*(idBin-1)+5);
               measVrefStd(idBin) = values(3*(idBin-1)+6);
               measVrefMed(idBin) = twos_complement_dec_argo(values(3*(idBin-1)+7), 32);
            end
            measDateTrans(1) = 1;
            measDateTrans(find((measPresMean == 0) & (measVrefStd == 0) & (measVrefMed == 0))) = -1;
            
            decData{1} = [cycleNum profNum phaseNum measDate];
            decData{2} = [cycleNum profNum phaseNum measDateTrans];
            decData{3} = [cycleNum profNum phaseNum measPresMean];
            decData{4} = [cycleNum profNum phaseNum measVrefStd];
            decData{5} = [cycleNum profNum phaseNum measVrefMed];
            
            cyProfPhaseList = [packType sensorDataType cycleNum profNum phaseNum a_sbdFileDate];
            
            decodedData.decData = decData;
            decodedData.cyProfPhaseList = cyProfPhaseList;
            decodedData.cyNumRaw = cycleNum;
            decodedData.profNumRaw = profNum;
            decodedData.phaseNumRaw = phaseNum;
            
         otherwise
            fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet for sensor data type #%d\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum, ...
               sensorDataType);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 247
      % grounding data
      
      % message data frame
      msgData = a_tabData(2:end);
      
      % first item bit number
      firstBit = 1;
      % item bit lengths
      tabNbBits = [16 repmat([8 8 8 8 8 8 8 16 16 16], 1, 10) 56];
      % get item bits
      values = get_bits(firstBit, tabNbBits, msgData);
      
      % decode and store data values
      cycleNum = values(1);
      for idBin = 1:10
         profNum = values(10*(idBin-1)+2);
         phaseNum = values(10*(idBin-1)+3);
         day = values(10*(idBin-1)+4);
         month = values(10*(idBin-1)+5);
         year = values(10*(idBin-1)+6);
         hour = values(10*(idBin-1)+7);
         minute = values(10*(idBin-1)+8);
         grdPres = values(10*(idBin-1)+9);
         setPoint = values(10*(idBin-1)+10);
         intVacuum = values(10*(idBin-1)+11);
         
         if ((profNum == 0) && (phaseNum == 0) && ...
               (day == 0) && (month == 0) && (year == 0) && ...
               (hour == 0) && (minute == 0) && ...
               (grdPres == 0) && (setPoint == 0) && (intVacuum == 0))
            continue
         end
         
         grdDate = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:00', ...
            year+2000, month, day, hour, minute));
         
         decData = [];
         decData{1} = [cycleNum profNum phaseNum grdDate];
         decData{2} = [cycleNum profNum phaseNum grdPres];
         decData{3} = [cycleNum profNum phaseNum setPoint];
         decData{4} = [cycleNum profNum phaseNum intVacuum];
         
         cyProfPhaseList = [247 -1 cycleNum profNum phaseNum a_sbdFileDate];
         
         decodedDataTmp = decodedData;
         decodedDataTmp.decData = decData;
         decodedDataTmp.cyProfPhaseList = cyProfPhaseList;
         decodedDataTmp.cyNumRaw = cycleNum;
         decodedDataTmp.profNumRaw = profNum;
         decodedDataTmp.phaseNumRaw = phaseNum;
         
         o_decodedData = cat(2, o_decodedData, decodedDataTmp);
      end
      
      return
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 248
      % RUDICS parameters
      
      % message data frame
      msgData = a_tabData(2:end);
      
      % first item bit number
      firstBit = 1;
      % item bit lengths
      tabNbBits = [repmat(8, 1, 6) ...
         16 8 ...
         16 16 8 8 8 ...
         984];
      % get item bits
      values = get_bits(firstBit, tabNbBits, msgData);
      
      cycleNum = values(7);
      profNum = values(8);
      phaseNum = -1;
      
      % packet date
      packJulD = datenum(sprintf('%02d%02d%02d%02d%02d%02d', values(1:6)), 'ddmmyyHHMMSS') - g_decArgo_janFirst1950InMatlab;
      
      decData = [packJulD values(7:13)' a_sbdFileDate];
      
      cyProfPhaseList = [248 -1 cycleNum profNum -1 a_sbdFileDate];
      
      decodedData.decData = decData;
      decodedData.cyProfPhaseList = cyProfPhaseList;
      decodedData.cyNumRaw = cycleNum;
      decodedData.profNumRaw = profNum;
      decodedData.phaseNumRaw = phaseNum;
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 249
      % sensor parameters
      
      % message data frame
      msgData = a_tabData(2:end);
      
      % first item bit number
      firstBit = 1;
      % item bit lengths
      tabNbBits = [6 2];
      % get item bits
      values = get_bits(firstBit, tabNbBits, msgData);
      
      paramType = values(2);
      
      if (paramType == 0)
         
         % standard parameters
         % item bit lengths
         tabNbBits = [6 2 ...
            16 8 8 ...
            32 repmat(16, 1, 49), ...
            256];
         % get item bits
         values = get_bits(firstBit, tabNbBits, msgData);
      else
         
         % specific parameters
         % item bit lengths
         tabNbBits = [6 2 ...
            16 8 8 ...
            32 repmat(32, 1, 20), ... % there are at most 20 specific parameters
            400];
         % get item bits
         values = get_bits(firstBit, tabNbBits, msgData);
         
         values(7:26) = typecast(uint32(values(7:26)), 'single');
         values(27:55) = nan;
         
         % for TRANSISTOR_PH Min/Max Vref is provided in uV and stored in
         % mV
         if (ismember('TRANSISTOR_PH', g_decArgo_sensorMountedOnFloat))
            if (values(1) == 4)
               values(11) = values(11)/1000;
               values(12) = values(12)/1000;
            end
         end
      end
      
      sensorType = values(1);
      cycleNum = values(3);
      profNum = values(4);
      phaseNum = values(5);
      
      % packet date
      packJulD = epoch2000_2_julian(values(6));
      
      decData = [packJulD values(1:55)' a_sbdFileDate];
      
      cyProfPhaseList = [249 sensorType cycleNum profNum phaseNum a_sbdFileDate];
      
      decodedData.decData = decData;
      decodedData.cyProfPhaseList = cyProfPhaseList;
      decodedData.cyNumRaw = cycleNum;
      decodedData.profNumRaw = profNum;
      decodedData.phaseNumRaw = phaseNum;
      decodedData.sensorType = sensorType;
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 250
      % sensor tech data
      
      % packet type 250 is 70 bytes length whereas input SBD size is 140 bytes
      % => transmitted packet should be split
      for idM = 1:2
         if (idM == 1)
            tabData = [a_tabData(1:70) zeros(1, 70)];
         else
            if (any(a_tabData(71:140) ~= 255))
               tabData = [a_tabData(71:140) zeros(1, 70)];
            else
               continue
            end
         end
         
         % sensor type
         sensorType = tabData(2);
         
         if (~ismember(sensorType, g_decArgo_sensorList))
            fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor TECH packet received (for sensor #%d which is not mounted on the float) - ignoring packet data\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, ...
               sensorType);
            return
         end
         
         % message data frame
         msgData = tabData(3:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [16 repmat(8, 1, 16) 400];
         % get item bits
         values = get_bits(firstBit, tabNbBits, msgData);
         
         % decode and store data values
         cycleNum = values(1);
         profNum = values(2);
         phaseNum = -1;
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
         
         cyProfPhaseList = [250 sensorType cycleNum profNum -1 a_sbdFileDate];
         
         decodedData.cyProfPhaseList = cyProfPhaseList;
         decodedData.cyNumRaw = cycleNum;
         decodedData.profNumRaw = profNum;
         decodedData.phaseNumRaw = phaseNum;
         decodedData.sensorType = sensorType;
         decodedData.expNbDesc = nbPackDesc;
         decodedData.expNbDrift = nbPackDrift;
         decodedData.expNbAsc = nbPackAsc;
         
         % message data frame
         msgData = tabData(21:end);
         
         decData = [];
         switch (sensorType)
            
            case 0
               % CTD
               
               % first item bit number
               firstBit = 1;
               % item bit lengths
               tabNbBits = [repmat(32, 1, 4) 272];
               % get item bits
               values = get_bits(firstBit, tabNbBits, msgData);
               
               % decode and store data values
               measOffsetPres = typecast(uint32(swapbytes(uint32(values(1)))), 'single');
               measSubPres = typecast(uint32(swapbytes(uint32(values(2)))), 'single');
               measTempPres = typecast(uint32(swapbytes(uint32(values(3)))), 'single');
               measSalPres = typecast(uint32(swapbytes(uint32(values(4)))), 'single');
               
               decData{1} = [cycleNum profNum nbPackDesc];
               decData{2} = [cycleNum profNum nbPackDrift];
               decData{3} = [cycleNum profNum nbPackAsc];
               decData{4} = [cycleNum profNum nbMeasDescZ1];
               decData{5} = [cycleNum profNum nbMeasDescZ2];
               decData{6} = [cycleNum profNum nbMeasDescZ3];
               decData{7} = [cycleNum profNum nbMeasDescZ4];
               decData{8} = [cycleNum profNum nbMeasDescZ5];
               decData{9} = [cycleNum profNum nbMeasDrift];
               decData{10} = [cycleNum profNum nbMeasAscZ1];
               decData{11} = [cycleNum profNum nbMeasAscZ2];
               decData{12} = [cycleNum profNum nbMeasAscZ3];
               decData{13} = [cycleNum profNum nbMeasAscZ4];
               decData{14} = [cycleNum profNum nbMeasAscZ5];
               decData{15} = [cycleNum profNum sensorState];
               decData{16} = [cycleNum profNum measOffsetPres];
               decData{17} = [cycleNum profNum measSubPres];
               decData{18} = [cycleNum profNum measTempPres];
               decData{19} = [cycleNum profNum measSalPres];
               
               decodedData.decData = decData;
               
            case 1
               % OPTODE
               
               % first item bit number
               firstBit = 1;
               % item bit lengths
               tabNbBits = [16 384];
               % get item bits
               values = get_bits(firstBit, tabNbBits, msgData);
               
               % decode and store data values
               measSensorSerialNum = swapbytes(uint16(values(1)));
               
               decData{1} = [cycleNum profNum nbPackDesc];
               decData{2} = [cycleNum profNum nbPackDrift];
               decData{3} = [cycleNum profNum nbPackAsc];
               decData{4} = [cycleNum profNum nbMeasDescZ1];
               decData{5} = [cycleNum profNum nbMeasDescZ2];
               decData{6} = [cycleNum profNum nbMeasDescZ3];
               decData{7} = [cycleNum profNum nbMeasDescZ4];
               decData{8} = [cycleNum profNum nbMeasDescZ5];
               decData{9} = [cycleNum profNum nbMeasDrift];
               decData{10} = [cycleNum profNum nbMeasAscZ1];
               decData{11} = [cycleNum profNum nbMeasAscZ2];
               decData{12} = [cycleNum profNum nbMeasAscZ3];
               decData{13} = [cycleNum profNum nbMeasAscZ4];
               decData{14} = [cycleNum profNum nbMeasAscZ5];
               decData{15} = [cycleNum profNum sensorState];
               decData{16} = [cycleNum profNum measSensorSerialNum];
               
               decodedData.decData = decData;
               
            case 2
               % OCR
               
               % first item bit number
               firstBit = 1;
               % item bit lengths
               tabNbBits = [16 repmat([8 repmat(8, 1, 16) 32], 1, 2) 48];
               % get item bits
               values = get_bits(firstBit, tabNbBits, msgData);
               
               % decode and store data values
               measSensorSerialNum = swapbytes(uint16(values(1)));
               measCoefSensor1 = values(2);
               measCoefSensor2 = values(20);
               
               decData{1} = [cycleNum profNum nbPackDesc];
               decData{2} = [cycleNum profNum nbPackDrift];
               decData{3} = [cycleNum profNum nbPackAsc];
               decData{4} = [cycleNum profNum nbMeasDescZ1];
               decData{5} = [cycleNum profNum nbMeasDescZ2];
               decData{6} = [cycleNum profNum nbMeasDescZ3];
               decData{7} = [cycleNum profNum nbMeasDescZ4];
               decData{8} = [cycleNum profNum nbMeasDescZ5];
               decData{9} = [cycleNum profNum nbMeasDrift];
               decData{10} = [cycleNum profNum nbMeasAscZ1];
               decData{11} = [cycleNum profNum nbMeasAscZ2];
               decData{12} = [cycleNum profNum nbMeasAscZ3];
               decData{13} = [cycleNum profNum nbMeasAscZ4];
               decData{14} = [cycleNum profNum nbMeasAscZ5];
               decData{15} = [cycleNum profNum sensorState];
               decData{16} = [cycleNum profNum measSensorSerialNum];
               
               if (measCoefSensor1 == 1) && (measCoefSensor2 == 2)
                  
                  measCoefLambda1A0 = get_double_from_little_endian(values(3:10));
                  measCoefLambda1A1 = get_double_from_little_endian(values(11:18));
                  measCoefLambda1Lm = typecast(uint32(swapbytes(uint32(values(19)))), 'single');
                  
                  measCoefLambda2A0 = get_double_from_little_endian(values(21:28));
                  measCoefLambda2A1 = get_double_from_little_endian(values(29:36));
                  measCoefLambda2Lm = typecast(uint32(swapbytes(uint32(values(37)))), 'single');
                  
                  decData{17} = [cycleNum profNum measCoefLambda1A0];
                  decData{18} = [cycleNum profNum measCoefLambda1A1];
                  decData{19} = [cycleNum profNum measCoefLambda1Lm];
                  decData{20} = [cycleNum profNum measCoefLambda2A0];
                  decData{21} = [cycleNum profNum measCoefLambda2A1];
                  decData{22} = [cycleNum profNum measCoefLambda2Lm];
                  decData{23} = [cycleNum profNum nan];
                  decData{24} = [cycleNum profNum nan];
                  decData{25} = [cycleNum profNum nan];
                  decData{26} = [cycleNum profNum nan];
                  decData{27} = [cycleNum profNum nan];
                  decData{28} = [cycleNum profNum nan];
                  
               elseif (measCoefSensor1 == 3) && (measCoefSensor2 == 4)
                  
                  measCoefLambda3A0 = get_double_from_little_endian(values(3:10));
                  measCoefLambda3A1 = get_double_from_little_endian(values(11:18));
                  measCoefLambda3Lm = typecast(uint32(swapbytes(uint32(values(19)))), 'single');
                  
                  measCoefParA0 = get_double_from_little_endian(values(21:28));
                  measCoefParA1 = get_double_from_little_endian(values(29:36));
                  measCoefParLm = typecast(uint32(swapbytes(uint32(values(37)))), 'single');
                  
                  decData{17} = [cycleNum profNum nan];
                  decData{18} = [cycleNum profNum nan];
                  decData{19} = [cycleNum profNum nan];
                  decData{20} = [cycleNum profNum nan];
                  decData{21} = [cycleNum profNum nan];
                  decData{22} = [cycleNum profNum nan];
                  decData{23} = [cycleNum profNum measCoefLambda3A0];
                  decData{24} = [cycleNum profNum measCoefLambda3A1];
                  decData{25} = [cycleNum profNum measCoefLambda3Lm];
                  decData{26} = [cycleNum profNum measCoefParA0];
                  decData{27} = [cycleNum profNum measCoefParA1];
                  decData{28} = [cycleNum profNum measCoefParLm];
                  
               end
               
               decodedData.decData = decData;
               
            case 3
               % ECO2 or ECO3
               
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
               
               decData{1} = [cycleNum profNum nbPackDesc];
               decData{2} = [cycleNum profNum nbPackDrift];
               decData{3} = [cycleNum profNum nbPackAsc];
               decData{4} = [cycleNum profNum nbMeasDescZ1];
               decData{5} = [cycleNum profNum nbMeasDescZ2];
               decData{6} = [cycleNum profNum nbMeasDescZ3];
               decData{7} = [cycleNum profNum nbMeasDescZ4];
               decData{8} = [cycleNum profNum nbMeasDescZ5];
               decData{9} = [cycleNum profNum nbMeasDrift];
               decData{10} = [cycleNum profNum nbMeasAscZ1];
               decData{11} = [cycleNum profNum nbMeasAscZ2];
               decData{12} = [cycleNum profNum nbMeasAscZ3];
               decData{13} = [cycleNum profNum nbMeasAscZ4];
               decData{14} = [cycleNum profNum nbMeasAscZ5];
               decData{15} = [cycleNum profNum sensorState];
               decData{16} = [cycleNum profNum measSensorSerialNum];
               decData{17} = [cycleNum profNum measCoefScaleFactChloroA];
               decData{18} = [cycleNum profNum measCoefDarkCountChloroA];
               decData{19} = [cycleNum profNum measCoefScaleFactBackscat];
               decData{20} = [cycleNum profNum measCoefDarkCountBackscat];
               
               if (ismember('ECO3', g_decArgo_sensorMountedOnFloat))
                  decData{21} = [cycleNum profNum measCoefScaleFactCdom];
                  decData{22} = [cycleNum profNum measCoefDarkCountCdom];
               end
               
               decodedData.decData = decData;
               
            case 4
               % FLNTU or SEAFET
               
               if (ismember('FLNTU', g_decArgo_sensorMountedOnFloat))
                  
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
                  
                  decData{1} = [cycleNum profNum nbPackDesc];
                  decData{2} = [cycleNum profNum nbPackDrift];
                  decData{3} = [cycleNum profNum nbPackAsc];
                  decData{4} = [cycleNum profNum nbMeasDescZ1];
                  decData{5} = [cycleNum profNum nbMeasDescZ2];
                  decData{6} = [cycleNum profNum nbMeasDescZ3];
                  decData{7} = [cycleNum profNum nbMeasDescZ4];
                  decData{8} = [cycleNum profNum nbMeasDescZ5];
                  decData{9} = [cycleNum profNum nbMeasDrift];
                  decData{10} = [cycleNum profNum nbMeasAscZ1];
                  decData{11} = [cycleNum profNum nbMeasAscZ2];
                  decData{12} = [cycleNum profNum nbMeasAscZ3];
                  decData{13} = [cycleNum profNum nbMeasAscZ4];
                  decData{14} = [cycleNum profNum nbMeasAscZ5];
                  decData{15} = [cycleNum profNum sensorState];
                  decData{16} = [cycleNum profNum measCoefScaleChloro];
                  decData{17} = [cycleNum profNum measDarkCountChloro];
                  decData{18} = [cycleNum profNum measCoefScaleTurbi];
                  decData{19} = [cycleNum profNum measDarkCountTurbi];
                  
               elseif (ismember('TRANSISTOR_PH', g_decArgo_sensorMountedOnFloat))
                  
                  % SEAFET
                  
                  % first item bit number
                  firstBit = 1;
                  % item bit lengths
                  tabNbBits = [32 368];
                  % get item bits
                  values = get_bits(firstBit, tabNbBits, msgData);
                  
                  % decode and store data values
                  measSensorSerialNum = swapbytes(uint32(values(1)));
                  
                  decData{1} = [cycleNum profNum nbPackDesc];
                  decData{2} = [cycleNum profNum nbPackDrift];
                  decData{3} = [cycleNum profNum nbPackAsc];
                  decData{4} = [cycleNum profNum nbMeasDescZ1];
                  decData{5} = [cycleNum profNum nbMeasDescZ2];
                  decData{6} = [cycleNum profNum nbMeasDescZ3];
                  decData{7} = [cycleNum profNum nbMeasDescZ4];
                  decData{8} = [cycleNum profNum nbMeasDescZ5];
                  decData{9} = [cycleNum profNum nbMeasDrift];
                  decData{10} = [cycleNum profNum nbMeasAscZ1];
                  decData{11} = [cycleNum profNum nbMeasAscZ2];
                  decData{12} = [cycleNum profNum nbMeasAscZ3];
                  decData{13} = [cycleNum profNum nbMeasAscZ4];
                  decData{14} = [cycleNum profNum nbMeasAscZ5];
                  decData{15} = [cycleNum profNum sensorState];
                  decData{16} = [cycleNum profNum measSensorSerialNum];
                  
               end
               
               decodedData.decData = decData;
               
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
               
               decData{1} = [cycleNum profNum nbPackDesc];
               decData{2} = [cycleNum profNum nbPackDrift];
               decData{3} = [cycleNum profNum nbPackAsc];
               decData{4} = [cycleNum profNum nbMeasDescZ1];
               decData{5} = [cycleNum profNum nbMeasDescZ2];
               decData{6} = [cycleNum profNum nbMeasDescZ3];
               decData{7} = [cycleNum profNum nbMeasDescZ4];
               decData{8} = [cycleNum profNum nbMeasDescZ5];
               decData{9} = [cycleNum profNum nbMeasDrift];
               decData{10} = [cycleNum profNum nbMeasAscZ1];
               decData{11} = [cycleNum profNum nbMeasAscZ2];
               decData{12} = [cycleNum profNum nbMeasAscZ3];
               decData{13} = [cycleNum profNum nbMeasAscZ4];
               decData{14} = [cycleNum profNum nbMeasAscZ5];
               decData{15} = [cycleNum profNum sensorState];
               decData{16} = [cycleNum profNum measSensorSerialNum];
               
               decodedData.decData = decData;
               
            case 6
               % SUNA
               
               % first item bit number
               firstBit = 1;
               % item bit lengths
               tabNbBits = [16 repmat(32, 1, 5) 16 16 192];
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
               
               decData{1} = [cycleNum profNum nbPackDesc];
               decData{2} = [cycleNum profNum nbPackDrift];
               decData{3} = [cycleNum profNum nbPackAsc];
               decData{4} = [cycleNum profNum nbMeasDescZ1];
               decData{5} = [cycleNum profNum nbMeasDescZ2];
               decData{6} = [cycleNum profNum nbMeasDescZ3];
               decData{7} = [cycleNum profNum nbMeasDescZ4];
               decData{8} = [cycleNum profNum nbMeasDescZ5];
               decData{9} = [cycleNum profNum nbMeasDrift];
               decData{10} = [cycleNum profNum nbMeasAscZ1];
               decData{11} = [cycleNum profNum nbMeasAscZ2];
               decData{12} = [cycleNum profNum nbMeasAscZ3];
               decData{13} = [cycleNum profNum nbMeasAscZ4];
               decData{14} = [cycleNum profNum nbMeasAscZ5];
               decData{15} = [cycleNum profNum sensorState];
               decData{16} = [cycleNum profNum measSensorSerialNum];
               decData{17} = [cycleNum profNum measSampCounter];
               decData{18} = [cycleNum profNum measPowerCycleCounter];
               decData{19} = [cycleNum profNum measErrorCounter];
               decData{20} = [cycleNum profNum measSupplyVoltage];
               decData{21} = [cycleNum profNum measSupplyCurrent];
               decData{22} = [cycleNum profNum measOutPixelBegin];
               decData{23} = [cycleNum profNum measOutPixelEnd];
               
               decodedData.decData = decData;
               
            otherwise
               fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet for sensor tech data type #%d\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum, ...
                  sensorType);
         end
         
         o_decodedData = cat(2, o_decodedData, decodedData);
      end
      
      return
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 252
      % float pressure data
      
      % message data frame
      msgData = a_tabData(2:end);
      
      % first item bit number
      firstBit = 1;
      % item bit lengths
      tabNbBits = [16 repmat([8 4 4 8 16 16], 1, 19) 32];
      % get item bits
      values = get_bits(firstBit, tabNbBits, msgData);
      
      % decode and store data values
      cycleNum = values(1);
      
      for idBin = 1:19
         profNum = values(6*(idBin-1)+3);
         phaseNum = values(6*(idBin-1)+2);
         pumpOrEv = values(6*(idBin-1)+4);
         actPres = values(6*(idBin-1)+5);
         actTime = values(6*(idBin-1)+6);
         actDuration = values(6*(idBin-1)+7);
         
         if ((profNum == 0) && (phaseNum == 0) && (pumpOrEv == 0) && ...
               (actPres == 0) && (actTime == 0) && (actDuration == 0))
            continue
         end
         
         decData = [];
         decData{1} = [cycleNum profNum phaseNum pumpOrEv];
         decData{2} = [cycleNum profNum phaseNum actPres];
         decData{3} = [cycleNum profNum phaseNum actTime];
         decData{4} = [cycleNum profNum phaseNum actDuration];
         
         cyProfPhaseList = [252 -1 cycleNum profNum phaseNum a_sbdFileDate];
         
         decodedDataTmp = decodedData;
         decodedDataTmp.decData = decData;
         decodedDataTmp.cyProfPhaseList = cyProfPhaseList;
         decodedDataTmp.cyNumRaw = cycleNum;
         decodedDataTmp.profNumRaw = profNum;
         decodedDataTmp.phaseNumRaw = phaseNum;
         
         o_decodedData = cat(2, o_decodedData, decodedDataTmp);
      end
      
      return
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 253
      % float technical data
      
      % message data frame
      msgData = a_tabData(2:end);
      
      % first item bit number
      firstBit = 1;
      % item bit lengths
      tabNbBits = [repmat(8, 1, 6) 16 repmat([16 16 8], 1, 3) 8 8 ...
         16 16 8 8 ...
         16 16 8 ...
         repmat(16, 1, 6) repmat(8, 1, 4) ...
         repmat(8, 1, 6) ...
         repmat(16, 1, 4) repmat(8, 1, 3) ...
         repmat(8, 1, 6) ...
         repmat(16, 1, 4) repmat(8, 1, 2) ...
         8 8 16 16 ...
         8 8 16 16 ...
         8 16 repmat(8, 1, 3) ...
         8 8 16 repmat(8, 1, 3) 16 repmat(8, 1, 4) 32 ...
         8 16 ...
         16 16 ...
         16 16 ...
         16 ...
         48];
      % get item bits
      values = get_bits(firstBit, tabNbBits, msgData);
      
      cycleNum = values(9);
      profNum = values(10);
      phaseNum = values(13);
      
      % packet date
      packJulD = datenum(sprintf('%02d%02d%02d%02d%02d%02d', values(1:6)), 'ddmmyyHHMMSS') - g_decArgo_janFirst1950InMatlab;
      
      % compute GPS location
      if (values(77) == 0)
         signLat = 1;
      else
         signLat = -1;
      end
      gpsLocLat = signLat*(values(74) + (values(75) + ...
         values(76)/10000)/60);
      if (values(81) == 0)
         signLon = 1;
      else
         signLon = -1;
      end
      gpsLocLon = signLon*(values(78) + (values(79) + ...
         values(80)/10000)/60);
      
      tabTech = [packJulD values(7:92)' gpsLocLon gpsLocLat a_sbdFileDate];
      
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
      
      cyProfPhaseList = [253 -1 cycleNum profNum phaseNum a_sbdFileDate];
      
      decodedData.decData = tabTech;
      decodedData.cyProfPhaseList = cyProfPhaseList;
      decodedData.cyNumRaw = cycleNum;
      decodedData.profNumRaw = profNum;
      decodedData.phaseNumRaw = phaseNum;
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 254
      % float prog technical data
      
      % message data frame
      msgData = a_tabData(2:end);
      
      % first item bit number
      firstBit = 1;
      % item bit lengths
      tabNbBits = [repmat(8, 1, 6) ...
         16 8 ...
         repmat(16, 1, 30) ...
         repmat(16, 1, 9) ...
         416];
      % get item bits
      values = get_bits(firstBit, tabNbBits, msgData);
      
      % calibration coefficients
      values(37) = values(37)/1000;
      if (values(38) < 32768) % 32768 = 65536/2
         values(38) = -values(38);
      else
         values(38) = 65536 - values(38);
      end
      
      cycleNum = values(7);
      profNum = values(8);
      phaseNum = -1;
      
      % packet date
      packJulD = datenum(sprintf('%02d%02d%02d%02d%02d%02d', values(1:6)), 'ddmmyyHHMMSS') - g_decArgo_janFirst1950InMatlab;
      
      floatProgTech = [packJulD values(7:47)' a_sbdFileDate];
      
      cyProfPhaseList = [254 -1 cycleNum profNum phaseNum a_sbdFileDate];
      
      decodedData.decData = floatProgTech;
      decodedData.cyProfPhaseList = cyProfPhaseList;
      decodedData.cyNumRaw = cycleNum;
      decodedData.profNumRaw = profNum;
      decodedData.phaseNumRaw = phaseNum;
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 255
      % float prog param data
      
      % message data frame
      msgData = a_tabData(2:end);
      
      % first item bit number
      firstBit = 1;
      % item bit lengths
      tabNbBits = [repmat(8, 1, 6) ...
         16 8 ...
         8 8 ...
         8 16 8 16 repmat(8, 1, 3) ...
         8 16 8 repmat([8 8 16 16 8], 1, 10) ...
         360];
      
      % get item bits
      values = get_bits(firstBit, tabNbBits, msgData);
      
      cycleNum = values(7);
      profNum = values(8);
      phaseNum = -1;
      
      % packet date
      packJulD = datenum(sprintf('%02d%02d%02d%02d%02d%02d', values(1:6)), 'ddmmyyHHMMSS') - g_decArgo_janFirst1950InMatlab;
      
      floatProgParam = [packJulD values(7:70)' a_sbdFileDate];
      
      cyProfPhaseList = [255 -1 cycleNum profNum phaseNum a_sbdFileDate];
      
      decodedData.decData = floatProgParam;
      decodedData.cyProfPhaseList = cyProfPhaseList;
      decodedData.cyNumRaw = cycleNum;
      decodedData.profNumRaw = profNum;
      decodedData.phaseNumRaw = phaseNum;
      
   otherwise
      fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet for packet type #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         packType);
end

o_decodedData = cat(2, o_decodedData, decodedData);

return
