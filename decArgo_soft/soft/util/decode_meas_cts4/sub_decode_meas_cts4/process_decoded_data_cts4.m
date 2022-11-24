% ------------------------------------------------------------------------------
% Process decoded data into Argo dedicated structures.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = ...
%    process_decoded_data_cts4(a_decodedDataTab, a_decoderId)
%
% INPUT PARAMETERS :
%   a_decodedDataTab : decoded data
%   a_decoderId      : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabProfiles    : output decoded profile measurements
%   o_tabProfiles    : output decoded park measurements
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/05/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift] = ...
   process_decoded_data_cts4(a_decodedDataTab, a_decoderId)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];

% current cycle number
global g_decArgo_cycleNum;

% current cycle&prof number
global g_decArgo_cycleProfNum;

% array to store GPS data
global g_decArgo_gpsData;

% generate nc flag
global g_decArgo_generateNcFlag;


% no data to process
if (isempty(a_decodedDataTab))
   return
end

g_decArgo_generateNcFlag = 1;

% set information on current cycle
g_decArgo_cycleNum = unique([a_decodedDataTab.cyNumOut]);
g_decArgo_cycleProfNum = unique([a_decodedDataTab.cyNum]);

% process decoded data

% get decoded data
[cyProfPhaseList, ...
   dataCTD, dataOXY, dataOCR, ...
   dataECO2, dataECO3, dataFLNTU, ...
   dataCROVER, dataSUNA, dataSEAFET, ...
   sensorTechCTD, sensorTechOPTODE, sensorTechOCR, ...
   sensorTechECO2, sensorTechECO3, ...
   sensorTechFLNTU, sensorTechSEAFET, ...
   sensorTechCROVER, sensorTechSUNA, ...
   tabTech, floatPres, grounded, ...
   floatProgRudics, floatProgTech, floatProgParam, floatProgSensor] = ...
   get_decoded_data_cts4(a_decodedDataTab, a_decoderId);

% store GPS data
store_gps_data_ir_rudics_111_113_114(tabTech);

if (~isempty(cyProfPhaseList) && any(cyProfPhaseList(:, 1) == 0))
      
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % PROF NetCDF file
   
   descentToParkStartDate = '';
   ascentEndDate = '';
   
   % process profile data for PROF NetCDF file
   [tabProfiles, tabDrift] = process_profiles_ir_rudics_cts4_111_113_114( ...
      a_decoderId, ...
      cyProfPhaseList, ...
      dataCTD, dataOXY, dataOCR, ...
      dataECO2, dataECO3, dataFLNTU, ...
      dataCROVER, dataSUNA, dataSEAFET, ...
      descentToParkStartDate, ascentEndDate, ...
      g_decArgo_gpsData, ...
      sensorTechCTD, sensorTechOPTODE, sensorTechOCR, ...
      sensorTechECO2, sensorTechECO3, ...
      sensorTechFLNTU, sensorTechSEAFET, ...
      sensorTechCROVER, sensorTechSUNA);
      
   % merge profile measurements (raw and averaged measurements of
   % a given profile)
   [tabProfiles] = merge_profile_meas_ir_rudics_sbd2(tabProfiles);
   
   % compute derived parameters of the profiles
   [tabProfiles] = compute_profile_derived_parameters_ir_rudics(tabProfiles, a_decoderId);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % TRAJ NetCDF file
   
   % merge drift measurements (raw and averaged measurements of
   % the park phase)
   [tabDrift] = merge_profile_meas_ir_rudics_sbd2(tabDrift);
   
   % compute derived parameters of the park phase
   [tabDrift] = compute_drift_derived_parameters_ir_rudics(tabDrift, a_decoderId);
end

o_tabProfiles = tabProfiles;
o_tabDrift = tabDrift;

return
