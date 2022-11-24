% ------------------------------------------------------------------------------
% Print sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_sbd2( ...
%    a_decoderId, ...
%    a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
%    a_dataCTD, a_dataOXY, a_dataFLBB, a_dataFLNTU, a_dataCYCLOPS, a_dataSEAPOINT)
%
% INPUT PARAMETERS :
%   a_decoderId            : float decoder Id
%   a_cyProfPhaseList      : information (cycle #, prof #, phase #) on each
%                            received packet
%   a_cyProfPhaseIndexList : index list of the data to print
%   a_dataCTD              : CTD data
%   a_dataOXY              : OXY data
%   a_dataFLBB             : FLBB data
%   a_dataFLNTU            : FLNTU data
%   a_dataCYCLOPS          : CYCLOPS data
%   a_dataSEAPOINT         : SEAPOINT data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/26/2015 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_in_csv_file_ir_sbd2( ...
   a_decoderId, ...
   a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
   a_dataCTD, a_dataOXY, a_dataFLBB, a_dataFLNTU, a_dataCYCLOPS, a_dataSEAPOINT)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% unpack the input data
a_dataCTDMean = a_dataCTD{1};
a_dataCTDStdMed = a_dataCTD{2};

a_dataOXYMean = a_dataOXY{1};
a_dataOXYStdMed = a_dataOXY{2};

a_dataFLBBMean = [];
a_dataFLBBStdMed = [];
if (~isempty(a_dataFLBB))
   a_dataFLBBMean = a_dataFLBB{1};
   a_dataFLBBStdMed = a_dataFLBB{2};
end

a_dataFLNTUMean = [];
a_dataFLNTUStdMed = [];
if (~isempty(a_dataFLNTU))
   a_dataFLNTUMean = a_dataFLNTU{1};
   a_dataFLNTUStdMed = a_dataFLNTU{2};
end

a_dataCYCLOPSMean = [];
a_dataCYCLOPSStdMed = [];
if (~isempty(a_dataCYCLOPS))
   a_dataCYCLOPSMean = a_dataCYCLOPS{1};
   a_dataCYCLOPSStdMed = a_dataCYCLOPS{2};
end

a_dataSEAPOINTMean = [];
a_dataSEAPOINTStdMed = [];
if (~isempty(a_dataSEAPOINT))
   a_dataSEAPOINTMean = a_dataSEAPOINT{1};
   a_dataSEAPOINTStdMed = a_dataSEAPOINT{2};
end

% packet type 0
dataCyProfPhaseList = a_cyProfPhaseList(a_cyProfPhaseIndexList, :);
cycleList = unique(dataCyProfPhaseList(:, 3));

if (~isempty(cycleList))
   if (length(cycleList) > 1)
      fprintf('WARNING: Float #%d Cycle #%d: more than one cycle data in the data SBD files\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
   end
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
         if (ismember(dataType, [1 4 7 16 38 41]))
            continue
         end
         
         switch (dataType)
            case 0
               % CTD (mean & stDev & median)
               print_data_in_csv_file_ir_rudics_sbd2_CTD_mean_stdMed( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataCTDMean, a_dataCTDStdMed);
               
            case 3
               % OXYGEN (mean & stDev & median)
               switch (a_decoderId)
                  case {301}
                     print_data_in_csv_file_OXY_mean_stdMed_301( ...
                        a_decoderId, cycleNum, profNum, phaseNum, ...
                        a_dataOXYMean, a_dataOXYStdMed);
                  case {302, 303}
                     print_data_in_csv_file_OXY_mean_stdMed_302_303( ...
                        a_decoderId, cycleNum, profNum, phaseNum, ...
                        a_dataOXYMean, a_dataOXYStdMed);
                  otherwise
                     fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet to process data type #%d for decoderId #%d\n', ...
                        g_decArgo_floatNum, ...
                        g_decArgo_cycleNum, ...
                        dataType, a_decoderId);
               end
               
            case 6
               % FLBB (mean & stDev & median)
               print_data_in_csv_file_ir_sbd2_FLBB_mean_stdMed( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataFLBBMean, a_dataFLBBStdMed);
               
            case 15
               % FLNTU (mean & stDev & median)
               print_data_in_csv_file_ir_rudics_sbd2_FLNTU_mean_stdMed( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataFLNTUMean, a_dataFLNTUStdMed);
               
            case 37
               % CYCLOPS (mean & stDev & median)
               print_data_in_csv_file_ir_sbd2_CYCLOPS_mean_stdMed( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataCYCLOPSMean, a_dataCYCLOPSStdMed);
               
            case 40
               % SEAPOINT (mean & stDev & median)
               print_data_in_csv_file_ir_sbd2_SEAPOINT_mean_stdMed( ...
                  a_decoderId, cycleNum, profNum, phaseNum, ...
                  a_dataSEAPOINTMean, a_dataSEAPOINTStdMed);
               
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
