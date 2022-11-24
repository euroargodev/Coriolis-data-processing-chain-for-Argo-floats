% ------------------------------------------------------------------------------
% Create the profiles of decoded data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profiles_ir_rudics_cts4_111_113( ...
%    a_decoderId, ...
%    a_cyProfPhaseList, ...
%    a_dataCTD, a_dataOXY, a_dataOCR, ...
%    a_dataECO2, a_dataECO3, a_dataFLNTU, ...
%    a_dataCROVER, a_dataSUNA, ...
%    a_descentToParkStartDate, a_ascentEndDate, a_gpsData, ...
%    a_sensorTechCTD, a_sensorTechOPTODE, a_sensorTechOCR, ...
%    a_sensorTechECO2, a_sensorTechECO3, ...
%    a_sensorTechFLNTU, a_sensorTechCROVER, a_sensorTechSUNA)
%
% INPUT PARAMETERS :
%   a_decoderId              : float decoder Id
%   a_cyProfPhaseList        : information (cycle #, prof #, phase #) on each
%                              received packet
%   a_dataCTD                : decoded CTD data
%   a_dataOXY                : decoded OXY data
%   a_dataOCR                : decoded OCR data
%   a_dataECO2               : decoded ECO2 data
%   a_dataECO3               : decoded ECO3 data
%   a_dataFLNTU              : decoded FLNTU data
%   a_dataCROVER             : decoded cROVER data
%   a_dataSUNA               : decoded SUNA data
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_gpsData                : information on GPS locations
%   a_sensorTechCTD          : CTD technical data
%   a_sensorTechOPTODE       : OPTODE technical data
%   a_sensorTechOCR          : OCR technical data
%   a_sensorTechECO2         : ECO2 technical data
%   a_sensorTechECO3         : ECO3 technical data
%   a_sensorTechFLNTU        : FLNTU technical data
%   a_sensorTechCROVER       : CROVER technical data
%   a_sensorTechSUNA         : SUNA technical data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : created output profiles
%   o_tabDrift    : created output drift measurement profiles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift] = process_profiles_ir_rudics_cts4_111_113( ...
   a_decoderId, ...
   a_cyProfPhaseList, ...
   a_dataCTD, a_dataOXY, a_dataOCR, ...
   a_dataECO2, a_dataECO3, a_dataFLNTU, ...
   a_dataCROVER, a_dataSUNA, ...
   a_descentToParkStartDate, a_ascentEndDate, a_gpsData, ...
   a_sensorTechCTD, a_sensorTechOPTODE, a_sensorTechOCR, ...
   a_sensorTechECO2, a_sensorTechECO3, ...
   a_sensorTechFLNTU, a_sensorTechCROVER, a_sensorTechSUNA)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (isempty(a_cyProfPhaseList))
   return
end

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

% consider only sensor data
idData = find(a_cyProfPhaseList(:, 1) == 0);
dataCyProfPhaseList = a_cyProfPhaseList(idData, :);

% create a profile for each different sampling scheme
dataTypeList = sort(unique(dataCyProfPhaseList(:, 2)));
for idDataType = 1:length(dataTypeList)
   dataType = dataTypeList(idDataType);
   
   % the stDev & median data are associated with mean data
   % SUNA APF2 (dataType == 25) is processed with SUNA APF (dataType == 24)
   if (ismember(dataType, [1 4 7 10 13 16 19 22 25]))
      continue
   end
   
   prof = [];
   switch (dataType)
      case 0
         % CTD (mean & stDev & median)
         [prof, drift] = process_profile_ir_rudics_CTD_mean_stdMed( ...
            a_dataCTDMean, a_dataCTDStdMed, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechCTD, a_decoderId);
         
      case 2
         % CTD (raw)
         [prof, drift] = process_profile_ir_rudics_CTD_raw( ...
            a_dataCTDRaw, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechCTD, a_decoderId);
         
      case 3
         % OXYGEN (mean & stDev & median)
         [prof, drift] = process_profile_ir_rudics_OXY_mean_stdMed( ...
            a_dataOXYMean, a_dataOXYStdMed, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechOPTODE, a_sensorTechCTD, a_decoderId);

      case 5
         % OXYGEN (raw)
         [prof, drift] = process_profile_ir_rudics_OXY_raw( ...
            a_dataOXYRaw, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechOPTODE, a_sensorTechCTD, a_decoderId);
         
      case 6
         % ECO2 (mean & stDev & median)
         [prof, drift] = process_profile_ECO2_mean_stdMed_111_113( ...
            a_dataECO2Mean, a_dataECO2StdMed, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechECO2, a_decoderId);
         
      case 8
         % ECO2 (raw)
         [prof, drift] = process_profile_ECO2_raw_111_113( ...
            a_dataECO2Raw, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechECO2, a_decoderId);
         
      case 9
         % ECO3 (mean & stDev & median)
         [prof, drift] = process_profile_ECO3_mean_stdMed_105_to_107_110_to_113( ...
            a_dataECO3Mean, a_dataECO3StdMed, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechECO3, a_decoderId);
         
      case 11
         % ECO3 (raw)
         [prof, drift] = process_profile_ECO3_raw_105_to_107_110_to_113( ...
            a_dataECO3Raw, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechECO3, a_decoderId);
         
      case 12
         % OCR (mean & stDev & median)
         [prof, drift] = process_profile_ir_rudics_OCR_mean_stdMed( ...
            a_dataOCRMean, a_dataOCRStdMed, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechOCR, a_decoderId);
         
      case 14
         % OCR (raw)
         [prof, drift] = process_profile_ir_rudics_OCR_raw( ...
            a_dataOCRRaw, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechOCR, a_decoderId);
         
      case 15
         fprintf('WARNING: Float #%d Cycle #%d: FLNTU is implemented but not used before checked\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum);
         if (0)
            % FLNTU (mean & stDev & median)
            [prof, drift] = process_profile_ir_rudics_FLNTU_mean_stdMed( ...
               a_dataFLNTUMean, a_dataFLNTUStdMed, ...
               a_descentToParkStartDate, a_ascentEndDate, ...
               a_gpsData, a_sensorTechFLNTU, a_decoderId);
         end
         
      case 17
         fprintf('WARNING: Float #%d Cycle #%d: FLNTU is implemented but not used before checked\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum);
         if (0)
            % FLNTU (raw)
            [prof, drift] = process_profile_ir_rudics_FLNTU_raw( ...
               a_dataFLNTURaw, ...
               a_descentToParkStartDate, a_ascentEndDate, ...
               a_gpsData, a_sensorTechFLNTU, a_decoderId);
         end
         
      case 18
         % cROVER (mean & stDev & median)
         [prof, drift] = process_profile_ir_rudics_CROVER_mean_stdMed( ...
            a_dataCROVERMean, a_dataCROVERStdMed, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechCROVER, a_decoderId);
         
      case 20
         % cROVER (raw)
         [prof, drift] = process_profile_ir_rudics_CROVER_raw( ...
            a_dataCROVERRaw, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechCROVER, a_decoderId);
         
      case 21
         fprintf('WARNING: Float #%d Cycle #%d: SUNA (mean & stDev & median) is implemented but not used before checked\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum);
         if (0)
            % SUNA (mean & stDev & median)
            [prof, drift] = process_profile_ir_rudics_SUNA_mean_stdMed( ...
               a_dataSUNAMean, a_dataSUNAStdMed, ...
               a_descentToParkStartDate, a_ascentEndDate, ...
               a_gpsData, a_sensorTechSUNA, a_decoderId);
         end
         
      case 23
         fprintf('WARNING: Float #%d Cycle #%d: SUNA (raw) is implemented but not used before checked\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum);
         if (0)
            % SUNA (raw)
            [prof, drift] = process_profile_ir_rudics_SUNA_raw( ...
               a_dataSUNARaw, ...
               a_descentToParkStartDate, a_ascentEndDate, ...
               a_gpsData, a_sensorTechSUNA, a_decoderId);
         end
         
      case 24
         % SUNA (APF)
         if (a_decoderId ~= 113)
            [prof, drift] = process_prof_ir_rudics_SUNA_APF_105_to_109_111_112_121_to_125( ...
               a_dataSUNAAPF, ...
               a_descentToParkStartDate, a_ascentEndDate, ...
               a_gpsData, a_sensorTechSUNA);
         end
         
      otherwise
         fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet for processing profiles with data type #%d\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            dataType);
         
   end
   
   if (~isempty(prof))
      o_tabProfiles = [o_tabProfiles prof];
   end
   
   if (~isempty(drift))
      o_tabDrift = [o_tabDrift drift];
   end
end

% process SUNA APF and SUNA APF2 together for decId == 113
if (a_decoderId == 113)
   if (ismember(24, dataTypeList) && ismember(25, dataTypeList))
      if (~isempty(a_dataSUNAAPF) && ~isempty(a_dataSUNAAPF2))
         
         [prof, drift] = process_profile_ir_rudics_SUNA_APF_110_113( ...
            a_dataSUNAAPF, a_dataSUNAAPF2, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechSUNA);
         
         if (~isempty(prof))
            o_tabProfiles = [o_tabProfiles prof];
         end
         
         if (~isempty(drift))
            o_tabDrift = [o_tabDrift drift];
         end
      elseif ((isempty(a_dataSUNAAPF) && ~isempty(a_dataSUNAAPF2)) || ...
            (~isempty(a_dataSUNAAPF) && isempty(a_dataSUNAAPF2)))
         fprintf('ERROR: Float #%d Cycle #%d: SUNA APF and SUNA APF2 have not been received together\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum);
      end
   elseif ((ismember(24, dataTypeList) && ismember(25, dataTypeList)) || ...
         (ismember(24, dataTypeList) && ismember(25, dataTypeList)))
      fprintf('ERROR: Float #%d Cycle #%d: SUNA APF and SUNA APF2 have not been received together\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
   end
end

return
