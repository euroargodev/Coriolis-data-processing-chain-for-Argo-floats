% ------------------------------------------------------------------------------
% Retrieve the list of intermediate parameters associated to a C or B parameter.
%
% SYNTAX :
 % [o_paramNameList] = get_intermediate_parameter_list(a_paramName)
%
% INPUT PARAMETERS :
%   a_paramName : C or B parameter name
%
% OUTPUT PARAMETERS :
%   o_paramNameList : list of associated parameters
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/15/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_paramNameList] = get_intermediate_parameter_list(a_paramName)

o_paramNameList = [];

switch (a_paramName)
   case 'PRES'
      o_paramNameList = [{'MTIME'} {'PRES_MED'} {'NB_SAMPLE_CTD'}];
   case 'PRES2'
      o_paramNameList = [{'MTIME'}];
   case 'TEMP'
      o_paramNameList = [{'TEMP_MED'} {'TEMP_STD'}];
   case 'PSAL'
      o_paramNameList = [{'CNDC'} {'TEMP_CNDC'} {'PSAL_STD'} {'PSAL_MED'}];
   case 'BBP532'
      o_paramNameList = [{'BETA_BACKSCATTERING532'} {'BETA_BACKSCATTERING532_STD'} {'BETA_BACKSCATTERING532_MED'}];
   case 'BBP700'
      o_paramNameList = [{'BETA_BACKSCATTERING700'} {'BETA_BACKSCATTERING700_STD'} {'BETA_BACKSCATTERING700_MED'}];
   case 'CDOM'
      o_paramNameList = [{'FLUORESCENCE_CDOM'} {'FLUORESCENCE_CDOM_STD'} {'FLUORESCENCE_CDOM_MED'}];
   case {'CHLA', 'CHLA2'}
      o_paramNameList = [{'FLUORESCENCE_CHLA'} {'FLUORESCENCE_CHLA_STD'} {'FLUORESCENCE_CHLA_MED'} ...
         {'FLUORESCENCE_VOLTAGE_CHLA'} {'FLUORESCENCE_VOLTAGE_CHLA_STD'} {'FLUORESCENCE_VOLTAGE_CHLA_MED'} ...
         {'TEMP_CPU_CHLA'}];
   case {'CHLA_FLUORESCENCE', 'CHLA_FLUORESCENCE2'}
      o_paramNameList = [{'FLUORESCENCE_CHLA'}];
   case 'CHLA435'
      o_paramNameList = [{'FLUORESCENCE_CHLA435'} {'FLUORESCENCE_CHLA435_STD'} {'FLUORESCENCE_CHLA435_MED'} ];
   case {'CONCENTRATION_LPM', 'CONCENTRATION_CATEGORY', 'BIOVOLUME_CATEGORY'}
      o_paramNameList = [{'NB_SIZE_SPECTRA_PARTICLES'} {'NB_SIZE_SPECTRA_PARTICLES_PER_IMAGE'} ...
         {'GREY_SIZE_SPECTRA_PARTICLES'} {'TEMP_PARTICLES'} {'NB_IMAGE_PARTICLES'} {'NB_IMAGE_CATEGORY'} ...
         {'BLACK_NB_IMAGE_PARTICLES'} {'NB_CATEGORY'} {'INDEX_CATEGORY'} {'NB_OBJECT_CATEGORY'} ...
         {'OBJECT_MEAN_VOLUME_CATEGORY'} {'OBJECT_MEAN_GREY_LEVEL_CATEGORY'} {'BLACK_NB_SIZE_SPECTRA_PARTICLES'} ...
         {'BLACK_TEMP_PARTICLES'} {'ECOTAXA_CATEGORY_ID'}];
   case 'CP660'
      o_paramNameList = [{'TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660'} ...
         {'TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660_STD'} {'TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660_MED'}];
   case 'DOWN_IRRADIANCE380'
      o_paramNameList = [{'RAW_DOWNWELLING_IRRADIANCE380'} {'RAW_DOWNWELLING_IRRADIANCE380_STD'} {'RAW_DOWNWELLING_IRRADIANCE380_MED'}];
   case 'DOWN_IRRADIANCE412'
      o_paramNameList = [{'RAW_DOWNWELLING_IRRADIANCE412'} {'RAW_DOWNWELLING_IRRADIANCE412_STD'} {'RAW_DOWNWELLING_IRRADIANCE412_MED'}];
   case 'DOWN_IRRADIANCE443'
      o_paramNameList = [{'RAW_DOWNWELLING_IRRADIANCE443'} {'RAW_DOWNWELLING_IRRADIANCE443_STD'} {'RAW_DOWNWELLING_IRRADIANCE443_MED'}];
   case 'DOWN_IRRADIANCE490'
      o_paramNameList = [{'RAW_DOWNWELLING_IRRADIANCE490'} {'RAW_DOWNWELLING_IRRADIANCE490_STD'} {'RAW_DOWNWELLING_IRRADIANCE490_MED'}];
   case 'DOWN_IRRADIANCE555'
      o_paramNameList = [{'RAW_DOWNWELLING_IRRADIANCE555'}];
   case 'DOWN_IRRADIANCE665'
      o_paramNameList = [{'RAW_DOWNWELLING_IRRADIANCE665'} {'RAW_DOWNWELLING_IRRADIANCE665_STD'} {'RAW_DOWNWELLING_IRRADIANCE665_MED'}];
   case 'DOWN_IRRADIANCE670'
      o_paramNameList = [{'RAW_DOWNWELLING_IRRADIANCE670'}];
   case 'DOWNWELLING_PAR'
      o_paramNameList = [{'RAW_DOWNWELLING_PAR'} {'RAW_DOWNWELLING_PAR_STD'} {'RAW_DOWNWELLING_PAR_MED'} ...
         {'VOLTAGE_DOWNWELLING_PAR'} {'TEMP_DOWNWELLING_PAR'}];
   case {'DOXY', 'DOXY2'}
      o_paramNameList = [ ...
         {'C1PHASE_DOXY'} {'C1PHASE_DOXY_STD'} {'C1PHASE_DOXY_MED'} ...
         {'C2PHASE_DOXY'} {'C2PHASE_DOXY_STD'} {'C2PHASE_DOXY_MED'} ...
         {'TEMP_DOXY'} {'TEMP_DOXY2'} {'TEMP_DOXY_MED'} {'TEMP_DOXY_STD'} {'MOLAR_DOXY'} ...
         {'TPHASE_DOXY'} {'RPHASE_DOXY'} {'DPHASE_DOXY'} {'DPHASE_DOXY_MED'} {'DPHASE_DOXY_STD'} ...
         {'BPHASE_DOXY'} {'PPOX_DOXY'} {'PHASE_DELAY_DOXY'} {'FREQUENCY_DOXY'}];
   case {'NITRATE', 'BISULFIDE'}
      o_paramNameList = [{'MOLAR_NITRATE'} {'UV_INTENSITY_NITRATE'} ...
         {'UV_INTENSITY_DARK_NITRATE'} {'UV_INTENSITY_DARK_NITRATE_STD'} {'FIT_ERROR_NITRATE'} ...
         {'TEMP_NITRATE'} {'TEMP_SPECTROPHOTOMETER_NITRATE'} {'HUMIDITY_NITRATE'} {'SPECTRUM_TYPE_NITRATE'} ...
         {'AVERAGING_NITRATE'} {'BLACK_AVERAGING_NITRATE'} {'FLASH_COUNT_NITRATE'} {'BLACK_FLASH_COUNT_NITRATE'} ...
         {'BLACK_TEMP_NITRATE'} {'UV_INTENSITY_FULL_NITRATE'} {'UV_INTENSITY_BINNED_NITRATE'} ...
         {'UV_INTENSITY_DARK_NITRATE_AVG'} {'UV_INTENSITY_DARK_NITRATE_SD'}];
   case 'PH_IN_SITU_TOTAL'
      o_paramNameList = [{'PH_IN_SITU_FREE'} {'VRS_PH'} {'VRS_PH_STD'} {'VRS_PH_MED'} ...
         {'IB_PH'} {'IB_PH_STD'} {'IB_PH_MED'} {'VK_PH'} {'VK_PH_STD'} {'VK_PH_MED'} ...
         {'IK_PH'} {'IK_PH_STD'} {'IK_PH_MED'} {'NB_SAMPLE_SFET'}];
   case 'TURBIDITY'
      o_paramNameList = [{'SIDE_SCATTERING_TURBIDITY'} {'SIDE_SCATTERING_TURBIDITY_STD'} {'SIDE_SCATTERING_TURBIDITY_MED'} ...
         {'VOLTAGE_TURBIDITY'} {'VOLTAGE_TURBIDITY_STD'} {'VOLTAGE_TURBIDITY_MED'}];
end

return
