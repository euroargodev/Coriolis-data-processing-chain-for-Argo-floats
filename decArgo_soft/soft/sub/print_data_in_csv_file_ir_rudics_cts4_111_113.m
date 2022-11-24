% ------------------------------------------------------------------------------
% Print sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_cts4_111_113( ...
%    a_decoderId, ...
%    a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
%    a_dataCTD, a_dataOXY, ...
%    a_dataECO2, a_dataECO3, ...
%    a_dataOCR, a_dataFLNTU, ...
%    a_dataCROVER, a_dataSUNA,...
%    a_dataSEAFET)
%
% INPUT PARAMETERS :
%   a_decoderId            : float decoder Id
%   a_cyProfPhaseList      : information (cycle #, prof #, phase #) on each
%                            received packet
%   a_cyProfPhaseIndexList : index list of the data to print
%   a_dataCTD              : CTD data
%   a_dataOXY              : OXY data
%   a_dataECO2             : ECO2 data
%   a_dataECO3             : ECO3 data
%   a_dataOCR              : OCR data
%   a_dataFLNTU            : FLNTU data
%   a_dataCROVER           : cROVER data
%   a_dataSUNA             : SUNA data
%   a_dataSEAFET           : SEAFET data
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
function print_data_in_csv_file_ir_rudics_cts4_111_113( ...
   a_decoderId, ...
   a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
   a_dataCTD, a_dataOXY, ...
   a_dataECO2, a_dataECO3, ...
   a_dataOCR, a_dataFLNTU, ...
   a_dataCROVER, a_dataSUNA,...
   a_dataSEAFET)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% unpack the input data
a_dataCTDMean = a_dataCTD{1};
a_dataCTDRaw = a_dataCTD{2};
a_dataCTDStdMed = a_dataCTD{3};

a_dataOXYMean = a_dataOXY{1};
a_dataOXYRaw = a_dataOXY{2};
a_dataOXYStdMed = a_dataOXY{3};

a_dataECO2Mean = a_dataECO2{1};
a_dataECO2Raw = a_dataECO2{2};
a_dataECO2StdMed = a_dataECO2{3};

a_dataECO3Mean = a_dataECO3{1};
a_dataECO3Raw = a_dataECO3{2};
a_dataECO3StdMed = a_dataECO3{3};

a_dataOCRMean = a_dataOCR{1};
a_dataOCRRaw = a_dataOCR{2};
a_dataOCRStdMed = a_dataOCR{3};

a_dataFLNTUMean = a_dataFLNTU{1};
a_dataFLNTURaw = a_dataFLNTU{2};
a_dataFLNTUStdMed = a_dataFLNTU{3};

a_dataCROVERMean = a_dataCROVER{1};
a_dataCROVERRaw = a_dataCROVER{2};
a_dataCROVERStdMed = a_dataCROVER{3};

a_dataSUNAMean = a_dataSUNA{1};
a_dataSUNARaw = a_dataSUNA{2};
a_dataSUNAStdMed = a_dataSUNA{3};
a_dataSUNAAPF = a_dataSUNA{4};
a_dataSUNAAPF2 = a_dataSUNA{5};

a_dataSEAFETMean = a_dataSEAFET{1};
a_dataSEAFETRaw = a_dataSEAFET{2};
a_dataSEAFETStdMed = a_dataSEAFET{3};

% packet type 0
dataCyProfPhaseList = a_cyProfPhaseList(a_cyProfPhaseIndexList, :);
cycleList = unique(dataCyProfPhaseList(:, 3));

if (length(cycleList) > 1)
   fprintf('WARNING: Float #%d Cycle #%d: more than one cycle data in the data SBD files\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
end

% print the sensor data
cycleProfPhaseList = unique(dataCyProfPhaseList(:, 3:5), 'rows');
for idCyPrPh = 1:size(cycleProfPhaseList, 1)
   cycleNum = cycleProfPhaseList(idCyPrPh, 1);
   profNum = cycleProfPhaseList(idCyPrPh, 2);
   phaseNum = cycleProfPhaseList(idCyPrPh, 3);
   
   idPack = find((dataCyProfPhaseList(:, 3) == cycleNum) & ...
      (dataCyProfPhaseList(:, 4) == profNum) & ...
      (dataCyProfPhaseList(:, 5) == phaseNum));
   
   if (~isempty(idPack))
      dataTypeList = sort(unique(dataCyProfPhaseList(idPack, 2)));
      for idDataType = 1:length(dataTypeList)
         dataType = dataTypeList(idDataType);
         
         % the stDev & median data are printed with the mean data
         if (ismember(dataType, [1 4 7 10 13 16 19 22 47]))
            continue
         end
         
         switch (dataType)
            case 0
               % CTD (mean & stDev & median)
               print_data_in_csv_file_ir_rudics_sbd2_CTD_mean_stdMed( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataCTDMean, a_dataCTDStdMed);
               
            case 2
               % CTD (raw)
               print_data_in_csv_file_ir_rudics_CTD_raw( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataCTDRaw);
               
            case 3
               % OXYGEN (mean & stDev & median)
               print_data_in_csv_file_ir_rudics_OXY_mean_stdMed( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataOXYMean, a_dataOXYStdMed);
               
            case 5
               % OXYGEN (raw)
               print_data_in_csv_file_ir_rudics_OXY_raw( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataOXYRaw);
               
            case 6
               % ECO2 (mean & stDev & median)
               print_data_in_csv_file_ECO2_mean_stdMed_111_113( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataECO2Mean, a_dataECO2StdMed);
               
            case 8
               % ECO2 (raw)
               print_data_in_csv_file_ECO2_raw_111_113( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataECO2Raw);
               
            case 9
               % ECO3 (mean & stDev & median)
               print_data_in_csv_file_ECO3_mean_stdMed_105_to_107_110_to_113( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataECO3Mean, a_dataECO3StdMed);
               
            case 11
               % ECO3 (raw)
               print_data_in_csv_file_ECO3_raw_105_to_107_110_to_113( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataECO3Raw);
               
            case 12
               % OCR (mean & stDev & median)
               print_data_in_csv_file_ir_rudics_OCR_mean_stdMed( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataOCRMean, a_dataOCRStdMed);
               
            case 14
               % OCR (raw)
               print_data_in_csv_file_ir_rudics_OCR_raw( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataOCRRaw);
               
            case 15
               % FLNTU (mean & stDev & median)
               print_data_in_csv_file_ir_rudics_sbd2_FLNTU_mean_stdMed( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataFLNTUMean, a_dataFLNTUStdMed);
               
            case 17
               % FLNTU (raw)
               print_data_in_csv_file_ir_rudics_FLNTU_raw( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataFLNTURaw);
               
            case 18
               % cROVER (mean & stDev & median)
               print_data_in_csv_file_ir_rudics_CROVER_mean_stdMed( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataCROVERMean, a_dataCROVERStdMed);
               
            case 20
               % cROVER (raw)
               print_data_in_csv_file_ir_rudics_CROVER_raw( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataCROVERRaw);
               
            case 21
               fprintf('WARNING: Float #%d Cycle #%d: SUNA (mean & stDev & median) is implemented but not used before checked\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum);
               if (0)
                  % SUNA (mean & stDev & median)
                  print_data_in_csv_file_ir_rudics_SUNA_mean_stdMed( ...
                     a_decoderId, cycleNum, profNum, phaseNum, ...
                     a_dataSUNAMean, a_dataSUNAStdMed);
               end
               
            case 23
               fprintf('WARNING: Float #%d Cycle #%d: SUNA (raw) is implemented but not used before checked\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum);
               if (0)
                  % SUNA (raw)
                  print_data_in_csv_file_ir_rudics_SUNA_raw( ...
                     a_decoderId, cycleNum, profNum, phaseNum, ...
                     a_dataSUNARaw);
               end
               
            case {24, 25}
               % SUNA (APF)
               if (dataType == 24)
                  info = 'SUNA APF';
                  dataSUNAAPF = a_dataSUNAAPF;
               else
                  info = 'SUNA APF2';
                  dataSUNAAPF = a_dataSUNAAPF2;
               end
               print_data_in_csv_file_ir_rudics_SUNA_APF( ...
                  cycleNum, profNum, phaseNum, ...
                  dataSUNAAPF, info);
               
            case 46
               % SEAFET (mean & stDev & median)
               print_data_in_csv_file_ir_rudics_SEAFET_mean_stdMed( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataSEAFETMean, a_dataSEAFETStdMed);
               
            case 48
               % SEAFET (raw)
               print_data_in_csv_file_ir_rudics_SEAFET_raw( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataSEAFETRaw);

            otherwise
               fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet for printing data of sensor data type #%d\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum, ...
                  dataType);
         end
      end
   end
end

return
