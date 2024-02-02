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

% sensor list
global g_decArgo_sensorMountedOnFloat;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;


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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Update OCR calibartion coefficients

if (ismember('OCR', g_decArgo_sensorMountedOnFloat))
   
   % calibration coefficients
   missingFlag = 1;
   if (~isempty(g_decArgo_calibInfo) && isfield(g_decArgo_calibInfo, 'OCR') && ...
         isfield(g_decArgo_calibInfo.OCR, 'A0Lambda380') && ...
         isfield(g_decArgo_calibInfo.OCR, 'A1Lambda380') && ...
         isfield(g_decArgo_calibInfo.OCR, 'LmLambda380') && ...
         isfield(g_decArgo_calibInfo.OCR, 'A0Lambda412') && ...
         isfield(g_decArgo_calibInfo.OCR, 'A1Lambda412') && ...
         isfield(g_decArgo_calibInfo.OCR, 'LmLambda412') && ...
         isfield(g_decArgo_calibInfo.OCR, 'A0Lambda490') && ...
         isfield(g_decArgo_calibInfo.OCR, 'A1Lambda490') && ...
         isfield(g_decArgo_calibInfo.OCR, 'LmLambda490') && ...
         isfield(g_decArgo_calibInfo.OCR, 'A0PAR') && ...
         isfield(g_decArgo_calibInfo.OCR, 'A1PAR') && ...
         isfield(g_decArgo_calibInfo.OCR, 'LmPAR') && ...
         ~isempty(g_decArgo_calibInfo.OCR.A0Lambda380) && ...
         ~isempty(g_decArgo_calibInfo.OCR.A1Lambda380) && ...
         ~isempty(g_decArgo_calibInfo.OCR.LmLambda380) && ...
         ~isempty(g_decArgo_calibInfo.OCR.A0Lambda412) && ...
         ~isempty(g_decArgo_calibInfo.OCR.A1Lambda412) && ...
         ~isempty(g_decArgo_calibInfo.OCR.LmLambda412) && ...
         ~isempty(g_decArgo_calibInfo.OCR.A0Lambda490) && ...
         ~isempty(g_decArgo_calibInfo.OCR.A1Lambda490) && ...
         ~isempty(g_decArgo_calibInfo.OCR.LmLambda490) && ...
         ~isempty(g_decArgo_calibInfo.OCR.A0PAR) && ...
         ~isempty(g_decArgo_calibInfo.OCR.A1PAR) && ...
         ~isempty(g_decArgo_calibInfo.OCR.LmPAR) ...
         )
      missingFlag = 0;
   end
   
   if (missingFlag)
      
      fprintf('WARNING: OCR calibration information is missing, please update the META.json file with the following calibration information\n');
      
      sensorTechOCRCoefLambda380A0 = sensorTechOCR{:, 17}(:, 3);
      sensorTechOCRCoefLambda380A0 = unique(sensorTechOCRCoefLambda380A0(~isnan(sensorTechOCRCoefLambda380A0)));
      sensorTechOCRCoefLambda380A1 = sensorTechOCR{:, 18}(:, 3);
      sensorTechOCRCoefLambda380A1 = unique(sensorTechOCRCoefLambda380A1(~isnan(sensorTechOCRCoefLambda380A1)));
      sensorTechOCRCoefLambda380Lm = sensorTechOCR{:, 19}(:, 3);
      sensorTechOCRCoefLambda380Lm = unique(sensorTechOCRCoefLambda380Lm(~isnan(sensorTechOCRCoefLambda380Lm)));
      sensorTechOCRCoefLambda412A0 = sensorTechOCR{:, 20}(:, 3);
      sensorTechOCRCoefLambda412A0 = unique(sensorTechOCRCoefLambda412A0(~isnan(sensorTechOCRCoefLambda412A0)));
      sensorTechOCRCoefLambda412A1 = sensorTechOCR{:, 21}(:, 3);
      sensorTechOCRCoefLambda412A1 = unique(sensorTechOCRCoefLambda412A1(~isnan(sensorTechOCRCoefLambda412A1)));
      sensorTechOCRCoefLambda412Lm = sensorTechOCR{:, 22}(:, 3);
      sensorTechOCRCoefLambda412Lm = unique(sensorTechOCRCoefLambda412Lm(~isnan(sensorTechOCRCoefLambda412Lm)));
      sensorTechOCRCoefLambda490A0 = sensorTechOCR{:, 23}(:, 3);
      sensorTechOCRCoefLambda490A0 = unique(sensorTechOCRCoefLambda490A0(~isnan(sensorTechOCRCoefLambda490A0)));
      sensorTechOCRCoefLambda490A1 = sensorTechOCR{:, 24}(:, 3);
      sensorTechOCRCoefLambda490A1 = unique(sensorTechOCRCoefLambda490A1(~isnan(sensorTechOCRCoefLambda490A1)));
      sensorTechOCRCoefLambda490Lm = sensorTechOCR{:, 25}(:, 3);
      sensorTechOCRCoefLambda490Lm = unique(sensorTechOCRCoefLambda490Lm(~isnan(sensorTechOCRCoefLambda490Lm)));
      sensorTechOCRCoefParA0 = sensorTechOCR{:, 26}(:, 3);
      sensorTechOCRCoefParA0 = unique(sensorTechOCRCoefParA0(~isnan(sensorTechOCRCoefParA0)));
      sensorTechOCRCoefParA1 = sensorTechOCR{:, 27}(:, 3);
      sensorTechOCRCoefParA1 = unique(sensorTechOCRCoefParA1(~isnan(sensorTechOCRCoefParA1)));
      sensorTechOCRCoefParLm = sensorTechOCR{:, 28}(:, 3);
      sensorTechOCRCoefParLm = unique(sensorTechOCRCoefParLm(~isnan(sensorTechOCRCoefParLm)));
      
      fprintf('      "OCR" :\n');
      fprintf('         {\n');
      fprintf('            "A0Lambda380" : %f,\n', sensorTechOCRCoefLambda380A0);
      fprintf('            "A1Lambda380" : %g,\n', sensorTechOCRCoefLambda380A1);
      fprintf('            "LmLambda380" : %f,\n', sensorTechOCRCoefLambda380Lm);
      fprintf('            "A0Lambda412" : %f,\n', sensorTechOCRCoefLambda412A0);
      fprintf('            "A1Lambda412" : %g,\n', sensorTechOCRCoefLambda412A1);
      fprintf('            "LmLambda412" : %f,\n', sensorTechOCRCoefLambda412Lm);
      fprintf('            "A0Lambda490" : %f,\n', sensorTechOCRCoefLambda490A0);
      fprintf('            "A1Lambda490" : %g,\n', sensorTechOCRCoefLambda490A1);
      fprintf('            "LmLambda490" : %f,\n', sensorTechOCRCoefLambda490Lm);
      fprintf('            "A0PAR" : %f,\n', sensorTechOCRCoefParA0);
      fprintf('            "A1PAR" : %g,\n', sensorTechOCRCoefParA1);
      fprintf('            "LmPAR" : %f\n', sensorTechOCRCoefParLm);
      fprintf('         },\n');
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Update SUNA configuration (PIXEL_BEGIN, PIXEL_END)

if (ismember('SUNA', g_decArgo_sensorMountedOnFloat))
   
   missingFlag = 1;
   if (~isempty(g_decArgo_calibInfo) && isfield(g_decArgo_calibInfo, 'SUNA') && ...
         isfield(g_decArgo_calibInfo.SUNA, 'SunaVerticalOffset') && ...
         isfield(g_decArgo_calibInfo.SUNA, 'FloatPixelBegin') && ...
         isfield(g_decArgo_calibInfo.SUNA, 'FloatPixelEnd') && ...
         ~isempty(g_decArgo_calibInfo.SUNA.SunaVerticalOffset) && ...
         ~isempty(g_decArgo_calibInfo.SUNA.FloatPixelBegin) && ...
         ~isempty(g_decArgo_calibInfo.SUNA.FloatPixelEnd) ...
         )
      missingFlag = 0;
   end
   
   if (missingFlag)
      
      fprintf('WARNING: SUNA configuration is not completed, please update the META.json file with the following configuration parameters\n');
      
      sensorTechSUNAPixelBegin = unique(sensorTechSUNA{:, 22}(:, 3));
      sensorTechSUNAPixelEnd = unique(sensorTechSUNA{:, 23}(:, 3));
      
      fprintf('         "CONFIG_PARAMETER_NAME_XXX" : "CONFIG_PX_1_6_0_0_3",\n');
      fprintf('         "CONFIG_PARAMETER_NAME_YYY" : "CONFIG_PX_1_6_0_0_4",\n');
      fprintf('         "CONFIG_PARAMETER_NAME_ZZZ" : "CONFIG_PX_1_6_0_0_0"\n\n');
      
      fprintf('         "CONFIG_PARAMETER_VALUE_XXX" : "%d",\n', sensorTechSUNAPixelBegin);
      fprintf('         "CONFIG_PARAMETER_VALUE_YYY" : "%d",\n', sensorTechSUNAPixelEnd);
      fprintf('         "CONFIG_PARAMETER_VALUE_ZZZ" : "0"\n');
   end
end

% store GPS data
store_gps_data_ir_rudics_111_113_to_116(tabTech);

if (~isempty(cyProfPhaseList) && any(cyProfPhaseList(:, 1) == 0))
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % PROF NetCDF file
   
   descentToParkStartDate = '';
   ascentEndDate = '';
   
   % process profile data for PROF NetCDF file
   [tabProfiles, tabDrift] = process_profiles_ir_rudics_cts4_111_113_to_116( ...
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
