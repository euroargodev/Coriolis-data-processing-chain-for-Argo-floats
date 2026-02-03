% ------------------------------------------------------------------------------
% Compute DOWNWELLING_IRRADIANCE from RAW_DOWNWELLING_IRRADIANCE provided by the
% RAMSES_ACC sensor monted on an Apex APF11 float.
%
% SYNTAX :
% [o_DOWN_IRRADIANCE_SPECTRUM, o_DOWN_IRRADIANCE_SPECTRUM_WAVELENGTHS] = ...
%   compute_DOWN_IRRADIANCE_SPECTRUM_apx_apf11( ...
%   a_RADIOMETER_DOWN_IRR_INTEGRATION_TIME, ...
%   a_RAW_DOWNWELLING_IRRADIANCE, ...
%   a_RADIOMETER_DOWN_IRR_INTEGRATION_TIME_fill_value, ...
%   a_RAW_DOWNWELLING_IRRADIANCE_fill_value, ...
%   a_DOWN_IRRADIANCE_SPECTRUM_fill_value, ...
%   a_DOWN_IRRADIANCE_SPECTRUM_WAVELENGTHS_fill_value, ...
%   a_profRamsesAcc)
%
% INPUT PARAMETERS :
%   a_RADIOMETER_DOWN_IRR_INTEGRATION_TIME            : input RADIOMETER_DOWN_IRR_INTEGRATION_TIME data
%   a_RAW_DOWNWELLING_IRRADIANCE                      : input RAW_DOWNWELLING_IRRADIANCE data
%   a_RADIOMETER_DOWN_IRR_INTEGRATION_TIME_fill_value : fill value for input RADIOMETER_DOWN_IRR_INTEGRATION_TIME data
%   a_RAW_DOWNWELLING_IRRADIANCE_fill_value           : fill value for input RAW_DOWNWELLING_IRRADIANCE data
%   a_DOWN_IRRADIANCE_SPECTRUM_fill_value             : fill value for input DOWN_IRRADIANCE_SPECTRUM data
%   a_DOWN_IRRADIANCE_SPECTRUM_WAVELENGTHS_fill_value : fill value for input DOWN_IRRADIANCE_SPECTRUM_WAVELENGTHS data
%   a_profRamsesAcc                                   : input RAMSES_ACC profile structure
%
% OUTPUT PARAMETERS :
%   o_DOWN_IRRADIANCE_SPECTRUM              : output DOWN_IRRADIANCE_SPECTRUM data
%   o_DOWN_IRRADIANCE_SPECTRUM_WAVELENGTHS  : associated wavelengths
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/06/2025 - RNU - creation (from Catherine Schmechtig's "January 2025 'R' code")
% ------------------------------------------------------------------------------
function [o_DOWN_IRRADIANCE_SPECTRUM, o_DOWN_IRRADIANCE_SPECTRUM_WAVELENGTHS] = ...
   compute_DOWN_IRRADIANCE_SPECTRUM_apx_apf11( ...
   a_RADIOMETER_DOWN_IRR_INTEGRATION_TIME, ...
   a_RAW_DOWNWELLING_IRRADIANCE, ...
   a_RADIOMETER_DOWN_IRR_INTEGRATION_TIME_fill_value, ...
   a_RAW_DOWNWELLING_IRRADIANCE_fill_value, ...
   a_DOWN_IRRADIANCE_SPECTRUM_fill_value, ...
   a_DOWN_IRRADIANCE_SPECTRUM_WAVELENGTHS_fill_value, ...
   a_profRamsesAcc)

% output parameters initialization
o_DOWN_IRRADIANCE_SPECTRUM = ones(size(a_RAW_DOWNWELLING_IRRADIANCE))*a_DOWN_IRRADIANCE_SPECTRUM_fill_value;
o_DOWN_IRRADIANCE_SPECTRUM_WAVELENGTHS = ones(size(a_RAW_DOWNWELLING_IRRADIANCE))*a_DOWN_IRRADIANCE_SPECTRUM_WAVELENGTHS_fill_value;

% current float WMO number
global g_decArgo_floatNum;

% arrays to store calibration information
global g_decArgo_calibInfo;


if (isempty(a_RAW_DOWNWELLING_IRRADIANCE))
   return
end

% get calibration information
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: RAMSES_ACC calibration information are missing - DOWNWELLING_IRRADIANCE data set to fill value\n', ...
      g_decArgo_floatNum, ...
      a_profRamsesAcc.cycleNumber, ...
      a_profRamsesAcc.profileNumber);
   return
elseif (isfield(g_decArgo_calibInfo, 'RAMSES_ACC') && ...
      isfield(g_decArgo_calibInfo.RAMSES_ACC, 'CisCoef') && ...
      isfield(g_decArgo_calibInfo.RAMSES_ACC, 'Wavelength') && ...
      isfield(g_decArgo_calibInfo.RAMSES_ACC, 'Back1') && ...
      isfield(g_decArgo_calibInfo.RAMSES_ACC, 'Back2') && ...
      isfield(g_decArgo_calibInfo.RAMSES_ACC, 'CalAq') && ...
      isfield(g_decArgo_calibInfo.RAMSES_ACC, 'RamsesAccVerticalOffset') && ...
      isfield(g_decArgo_calibInfo.RAMSES_ACC, 'RamsesAccDarkPixelBegin') && ...
      isfield(g_decArgo_calibInfo.RAMSES_ACC, 'RamsesAccDarkPixelEnd'))
   cisCoef = g_decArgo_calibInfo.RAMSES_ACC.CisCoef;
   wavelength = g_decArgo_calibInfo.RAMSES_ACC.Wavelength;
   back1 = g_decArgo_calibInfo.RAMSES_ACC.Back1;
   back2 = g_decArgo_calibInfo.RAMSES_ACC.Back2;
   calAq = g_decArgo_calibInfo.RAMSES_ACC.CalAq;
   ramsesAccVerticalOffset = g_decArgo_calibInfo.RAMSES_ACC.RamsesAccVerticalOffset;
   ramsesAccDarkPixelBegin = g_decArgo_calibInfo.RAMSES_ACC.RamsesAccDarkPixelBegin;
   ramsesAccDarkPixelEnd = g_decArgo_calibInfo.RAMSES_ACC.RamsesAccDarkPixelEnd;
else
   fprintf('ERROR: Float #%d Cycle #%d Profile #%d: inconsistent RAMSES_ACC calibration information - DOWNWELLING_IRRADIANCE data set to fill value\n', ...
      g_decArgo_floatNum, ...
      a_profRamsesAcc.cycleNumber, ...
      a_profRamsesAcc.profileNumber);
   return
end

% exclude fill values
idDef = [];
for idL = 1:size(a_RAW_DOWNWELLING_IRRADIANCE, 1)
   data = a_RAW_DOWNWELLING_IRRADIANCE(idL, :);
   if ((length(unique(data)) == 1) && (unique(data) == a_RAW_DOWNWELLING_IRRADIANCE_fill_value))
      idDef = [idDef; idL];
   end
end

idDef = sort([idDef; ...
   find(a_RADIOMETER_DOWN_IRR_INTEGRATION_TIME == a_RADIOMETER_DOWN_IRR_INTEGRATION_TIME_fill_value)]);

idNoDef = setdiff(1:length(a_RADIOMETER_DOWN_IRR_INTEGRATION_TIME), idDef);

% process input data
if (~isempty(idNoDef))

   nValues = 255;
   backb = zeros(nValues, 1);
   downIrradianceSpectrum = ones(size(a_RAW_DOWNWELLING_IRRADIANCE))*a_DOWN_IRRADIANCE_SPECTRUM_fill_value;
   for idLev = idNoDef

      integTime = a_RADIOMETER_DOWN_IRR_INTEGRATION_TIME(idLev);
      rawIrr = a_RAW_DOWNWELLING_IRRADIANCE(idLev, :);

      s1b = rawIrr;
      irrb = rawIrr;

      % estimation of the Background spectrum
      % NB: the Background spectrum depends on the integration time so on LEVELS

      for ib = 1:nValues
         backb(ib) = back1(ib) + integTime*back2(ib)/8192;

         % normalize the spectrum and substract the background
         s1b(ib) = rawIrr(ib)/65535 - backb(ib);
      end

      % average for the DARK pixel
      sd = mean(s1b(ramsesAccDarkPixelBegin:ramsesAccDarkPixelEnd));

      for ib = 1:nValues

         % substract dark signal and apply sensibility coefficient
         irrb(ib) = (8192/integTime) * (s1b(ib) - sd)/calAq(ib);

         downIrradianceSpectrum(idLev, ib) = irrb(ib)/10; % to be in line with the units
      end
   end

   o_DOWN_IRRADIANCE_SPECTRUM(~isnan(downIrradianceSpectrum)) = downIrradianceSpectrum(~isnan(downIrradianceSpectrum)); % the Nan levels of calAq create Nan columns in downIrradianceSpectrum
   o_DOWN_IRRADIANCE_SPECTRUM_WAVELENGTHS = repmat(wavelength', size(o_DOWN_IRRADIANCE_SPECTRUM, 1), 1);
end

return
