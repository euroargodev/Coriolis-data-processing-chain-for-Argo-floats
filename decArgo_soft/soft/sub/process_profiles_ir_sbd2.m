% ------------------------------------------------------------------------------
% Create the profiles of decoded data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profiles_ir_sbd2( ...
%    a_decoderId, ...
%    a_cyProfPhaseList, ...
%    a_dataCTD, a_dataOXY, a_dataFLBB, a_dataFLNTU, a_dataCYCLOPS, a_dataSEAPOINT, ...
%    a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_iridiumMailData, ...
%    a_sensorTechCTD, a_sensorTechOPTODE, a_sensorTechFLBB, a_sensorTechFLNTU, ...
%    a_sensorTechCYCLOPS, a_sensorTechSEAPOINT)
%
% INPUT PARAMETERS :
%   a_decoderId              : float decoder Id
%   a_cyProfPhaseList        : information (cycle #, prof #, phase #) on each
%                              received packet
%   a_dataCTD                : decoded CTD data
%   a_dataOXY                : decoded OXY data
%   a_dataFLBB               : decoded FLBB data
%   a_dataFLNTU              : decoded FLNTU data
%   a_dataCYCLOPS            : decoded CYCLOPS data
%   a_dataSEAPOINT           : decoded SEAPOINT data
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_gpsData                : information on GPS locations
%   a_iridiumMailData        : information on Iridium locations
%   a_sensorTechCTD          : CTD technical data
%   a_sensorTechOPTODE       : OPTODE technical data
%   a_sensorTechFLBB         : FLBB technical data
%   a_sensorTechFLNTU        : FLNTU technical data
%   a_sensorTechCYCLOPS      : CYCLOPS technical data
%   a_sensorTechSEAPOINT     : SEAPOINT technical data
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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift] = process_profiles_ir_sbd2( ...
   a_decoderId, ...
   a_cyProfPhaseList, ...
   a_dataCTD, a_dataOXY, a_dataFLBB, a_dataFLNTU, a_dataCYCLOPS, a_dataSEAPOINT, ...
   a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_iridiumMailData, ...
   a_sensorTechCTD, a_sensorTechOPTODE, a_sensorTechFLBB, a_sensorTechFLNTU, ...
   a_sensorTechCYCLOPS, a_sensorTechSEAPOINT)

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

if (isempty(a_cyProfPhaseList))
   return
end

% consider only sensor data
idData = find(a_cyProfPhaseList(:, 1) == 0);
dataCyProfPhaseList = a_cyProfPhaseList(idData, :);

% create a profile for each different sampling scheme
dataTypeList = sort(unique(dataCyProfPhaseList(:, 2)));
for idDataType = 1:length(dataTypeList)
   dataType = dataTypeList(idDataType);
   
   % the stDev & median data are associated with mean data
   if (ismember(dataType, [1 4 7 16 38 41]))
      continue
   end
   
   prof = [];
   switch (dataType)
      case 0
         % CTD (mean & stDev & median)
         [prof, drift] = process_profile_ir_sbd2_CTD_mean_stdMed( ...
            a_dataCTDMean, a_dataCTDStdMed, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_iridiumMailData, a_sensorTechCTD, a_decoderId);
                  
      case 3
         % OXYGEN (mean & stDev & median)
         switch (a_decoderId)
            case {301}
               [prof, drift] = process_profile_ir_sbd2_OXY_mean_stdMed_301( ...
                  a_dataOXYMean, a_dataOXYStdMed, ...
                  a_descentToParkStartDate, a_ascentEndDate, ...
                  a_gpsData, a_iridiumMailData, a_sensorTechOPTODE, a_sensorTechCTD, a_decoderId);
            case {302, 303}
               [prof, drift] = process_profile_ir_sbd2_OXY_mean_stdMed_302_303( ...
                  a_dataOXYMean, a_dataOXYStdMed, ...
                  a_descentToParkStartDate, a_ascentEndDate, ...
                  a_gpsData, a_iridiumMailData, a_sensorTechOPTODE, a_sensorTechCTD, a_decoderId);
            otherwise
               fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet to process data type #%d for decoderId #%d\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum, ...
                  dataType, a_decoderId);
         end
         
      case 6
         % FLBB (mean & stDev & median)
         [prof, drift] = process_profile_ir_sbd2_FLBB_mean_stdMed( ...
            a_dataFLBBMean, a_dataFLBBStdMed, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_iridiumMailData, a_sensorTechFLBB, a_decoderId);
         
      case 15
         % FLNTU (mean & stDev & median)
         [prof, drift] = process_profile_ir_sbd2_FLNTU_mean_stdMed( ...
            a_dataFLNTUMean, a_dataFLNTUStdMed, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_iridiumMailData, a_sensorTechFLNTU, a_decoderId);
         
      case 37
         % CYCLOPS (mean & stDev & median)
         [prof, drift] = process_profile_ir_sbd2_CYCLOPS_mean_stdMed( ...
            a_dataCYCLOPSMean, a_dataCYCLOPSStdMed, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_iridiumMailData, a_sensorTechCYCLOPS, a_decoderId);
         
      case 40
         % SEAPOINT (mean & stDev & median)
         [prof, drift] = process_profile_ir_sbd2_SEAPOINT_mean_stdMed( ...
            a_dataSEAPOINTMean, a_dataSEAPOINTStdMed, ...
            a_descentToParkStartDate, a_ascentEndDate, ...
            a_gpsData, a_iridiumMailData, a_sensorTechSEAPOINT, a_decoderId);

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

return
