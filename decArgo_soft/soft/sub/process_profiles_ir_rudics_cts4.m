% ------------------------------------------------------------------------------
% Create the profiles of decoded data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profiles_ir_rudics_cts4( ...
%    a_decoderId, ...
%    a_cyProfPhaseList, ...
%    a_dataCTD, a_dataOXY, a_dataOCR, a_dataECO3, ...
%    a_dataFLNTU, a_dataCROVER, a_dataSUNA, ...
%    a_descentToParkStartDate, a_ascentEndDate, a_gpsData, ...
%    a_sensorTechCTD, a_sensorTechOPTODE, ...
%    a_sensorTechOCR, a_sensorTechECO3, ...
%    a_sensorTechFLNTU, a_sensorTechCROVER, a_sensorTechSUNA)
%
% INPUT PARAMETERS :
%   a_decoderId              : float decoder Id
%   a_cyProfPhaseList        : information (cycle #, prof #, phase #) on each
%                              received packet
%   a_dataCTD                : decoded CTD data
%   a_dataOXY                : decoded OXY data
%   a_dataOCR                : decoded OCR data
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
%   02/22/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift] = process_profiles_ir_rudics_cts4( ...
   a_decoderId, ...
   a_cyProfPhaseList, ...
   a_dataCTD, a_dataOXY, a_dataOCR, a_dataECO3, ...
   a_dataFLNTU, a_dataCROVER, a_dataSUNA, ...
   a_descentToParkStartDate, a_ascentEndDate, a_gpsData, ...
   a_sensorTechCTD, a_sensorTechOPTODE, ...
   a_sensorTechOCR, a_sensorTechECO3, ...
   a_sensorTechFLNTU, a_sensorTechCROVER, a_sensorTechSUNA)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% float configuration
global g_decArgo_floatConfig;


% unpack the input data
a_dataCTDMean = a_dataCTD{1};
a_dataCTDRaw = a_dataCTD{2};
a_dataCTDStdMed = a_dataCTD{3};

a_dataOXYMean = a_dataOXY{1};
a_dataOXYRaw = a_dataOXY{2};
a_dataOXYStdMed = a_dataOXY{3};

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

if (isempty(a_cyProfPhaseList))
   return;
end

% consider only sensor data
idData = find(a_cyProfPhaseList(:, 1) == 0);
dataCyProfPhaseList = a_cyProfPhaseList(idData, :);

% create a profile for each different sampling scheme
dataTypeList = sort(unique(dataCyProfPhaseList(:, 2)));
for idDataType = 1:length(dataTypeList)
   dataType = dataTypeList(idDataType);
   
   % the stDev & median data are associated with mean data
   if (ismember(dataType, [1 4 10 13 16 19 22]))
      continue;
   end
   
   prof = [];
   switch (dataType)
      case 0
         % CTD (mean & stDev & median)
         [prof, drift] = process_profile_ir_rudics_CTD_mean_stdMed( ...
            a_dataCTDMean, a_dataCTDStdMed, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechCTD);
         
      case 2
         % CTD (raw)
         [prof, drift] = process_profile_ir_rudics_CTD_raw( ...
            a_dataCTDRaw, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechCTD);
         
      case 3
         % OXYGEN (mean & stDev & median)
         [prof, drift] = process_profile_ir_rudics_OXY_mean_stdMed( ...
            a_dataOXYMean, a_dataOXYStdMed, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechOPTODE, a_sensorTechCTD);
         
      case 5
         % OXYGEN (raw)
         [prof, drift] = process_profile_ir_rudics_OXY_raw( ...
            a_dataOXYRaw, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechOPTODE, a_sensorTechCTD);
         
      case 9
         % ECO3 (mean & stDev & median)
         switch (a_decoderId)
            case {105, 106, 107}
               [prof, drift] = process_profile_ECO3_mean_stdMed_105_to_107( ...
                  a_dataECO3Mean, a_dataECO3StdMed, ...
                  a_descentToParkStartDate, a_ascentEndDate, ...
                  a_gpsData, a_sensorTechECO3);
            case {108, 109}
               [prof, drift] = process_profile_ECO3_mean_stdMed_108_109( ...
                  a_dataECO3Mean, a_dataECO3StdMed, ...
                  a_descentToParkStartDate, a_ascentEndDate, ...
                  a_gpsData, a_sensorTechECO3);
            otherwise
               fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet to process data type #%d for decoderId #%d\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum, ...
                  dataType, a_decoderId);
         end
         
      case 11
         % ECO3 (raw)
         switch (a_decoderId)
            case {105, 106, 107}
               [prof, drift] = process_profile_ECO3_raw_105_to_107( ...
                  a_dataECO3Raw, ...
                  a_descentToParkStartDate, a_ascentEndDate, ...
                  a_gpsData, a_sensorTechECO3);
            case {108, 109}
               [prof, drift] = process_profile_ECO3_raw_108_109( ...
                  a_dataECO3Raw, ...
                  a_descentToParkStartDate, a_ascentEndDate, ...
                  a_gpsData, a_sensorTechECO3);
            otherwise
               fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet to process data type #%d for decoderId #%d\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum, ...
                  dataType, a_decoderId);
         end
         
      case 12
         % OCR (mean & stDev & median)
         [prof, drift] = process_profile_ir_rudics_OCR_mean_stdMed( ...
            a_dataOCRMean, a_dataOCRStdMed, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechOCR);
         
      case 14
         % OCR (raw)
         [prof, drift] = process_profile_ir_rudics_OCR_raw( ...
            a_dataOCRRaw, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechOCR);
         
      case 15
         fprintf('WARNING: Float #%d Cycle #%d: FLNTU is implemented but not used before checked\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum);
         if (0)
            % FLNTU (mean & stDev & median)
            [prof, drift] = process_profile_ir_rudics_FLNTU_mean_stdMed( ...
               a_dataFLNTUMean, a_dataFLNTUStdMed, ...
               a_descentToParkStartDate, a_ascentEndDate, ...
               a_gpsData, a_sensorTechFLNTU);
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
               a_gpsData, a_sensorTechFLNTU);
         end
         
      case 18
         % cROVER (mean & stDev & median)
         [prof, drift] = process_profile_ir_rudics_CROVER_mean_stdMed( ...
            a_dataCROVERMean, a_dataCROVERStdMed, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechCROVER);
         
      case 20
         % cROVER (raw)
         [prof, drift] = process_profile_ir_rudics_CROVER_raw( ...
            a_dataCROVERRaw, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechCROVER);
         
      case 21
         fprintf('WARNING: Float #%d Cycle #%d: SUNA (mean & stDev & median) is implemented but not used before checked\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum);
         if (0)
            % SUNA (mean & stDev & median)
            [prof, drift] = process_profile_ir_rudics_SUNA_mean_stdMed( ...
               a_dataSUNAMean, a_dataSUNAStdMed, ...
               a_descentToParkStartDate, a_ascentEndDate, ...
               a_gpsData, a_sensorTechSUNA);
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
               a_gpsData, a_sensorTechSUNA);
         end
         
      case 24
         % SUNA (APF)
         [prof, drift] = process_profile_ir_rudics_SUNA_APF( ...
            a_dataSUNAAPF, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_sensorTechSUNA);
         
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

% if (~isempty(o_tabProfiles))
%    
%    % retrieve cycle and profile numbers from configuration
%    confCyNum = g_decArgo_floatConfig.USE.CYCLE;
%    confProfNum = g_decArgo_floatConfig.USE.PROFILE;
% 
%    % fill the holes in consecutive numbers
%    finalCyNum = [];
%    finalProfNum = [];
%    for cyNum = 0:max(confCyNum)
%       idF = find(confCyNum == cyNum);
%       if (~isempty(idF))
%          finalCyNum = [finalCyNum repmat(cyNum, 1, max(confProfNum(idF))+1)];
%          finalProfNum = [finalProfNum 0:max(confProfNum(idF))];
%       else
%          finalCyNum = [finalCyNum cyNum];
%          finalProfNum = [finalProfNum 0];
%       end
%    end
%    
%    % set the outputCycleNumber information of the profile structure
%    for idP = 1:length(o_tabProfiles)
%       idF = find((finalCyNum == o_tabProfiles(idP).cycleNumber) & ...
%          (finalProfNum == o_tabProfiles(idP).profileNumber));
%       if (length(idF) == 1)
%          o_tabProfiles(idP).outputCycleNumber = idF;
%       else
%          if (isempty(idF))
%             fprintf('ERROR: Float #%d Cycle #%d: Configuration is missing for cycle #%d and profile #%d\n', ...
%                g_decArgo_floatNum, ...
%                g_decArgo_cycleNum, ...
%                o_tabProfiles(idP).cycleNumber, ...
%                o_tabProfiles(idP).profileNumber);
%          else
%             fprintf('ERROR: Float #%d Cycle #%d: %d configurations found for cycle #%d and profile #%d\n', ...
%                g_decArgo_floatNum, ...
%                g_decArgo_cycleNum, ...
%                length(idF), ...
%                o_tabProfiles(idP).cycleNumber, ...
%                o_tabProfiles(idP).profileNumber);
%          end
%       end
%    end
% end

return;
