% ------------------------------------------------------------------------------
% Compute DOWNWELLING_IRRADIANCE from RAW_DOWNWELLING_IRRADIANCE provided by the
% RAMSES_ACC sensor.
%
% SYNTAX :
% [o_DOWN_IRRADIANCE_SPECTRUM, o_DOWN_IRRADIANCE_SPECTRUM_WAVELENGTHS] = ...
%   compute_DOWN_IRRADIANCE_SPECTRUM( ...
%   a_RADIOMETER_DOWN_IRR_INTEGRATION_TIME, ...
%   a_RADIOMETER_DOWN_IRR_DARK_AVERAGE, ...
%   a_RAW_DOWNWELLING_IRRADIANCE, ...
%   a_RADIOMETER_DOWN_IRR_INTEGRATION_TIME_fill_value, ...
%   a_RADIOMETER_DOWN_IRR_DARK_AVERAGE_fill_value, ...
%   a_RAW_DOWNWELLING_IRRADIANCE_fill_value, ...
%   a_DOWN_IRRADIANCE_SPECTRUM_fill_value, ...
%   a_DOWN_IRRADIANCE_SPECTRUM_WAVELENGTHS_fill_value, ...
%   a_profRamsesAcc)
%
% INPUT PARAMETERS :
%   a_RADIOMETER_DOWN_IRR_INTEGRATION_TIME            : input RADIOMETER_DOWN_IRR_INTEGRATION_TIME data
%   a_RADIOMETER_DOWN_IRR_DARK_AVERAGE                : input RADIOMETER_DOWN_IRR_DARK_AVERAGE data
%   a_RAW_DOWNWELLING_IRRADIANCE                      : input RAW_DOWNWELLING_IRRADIANCE data
%   a_RADIOMETER_DOWN_IRR_INTEGRATION_TIME_fill_value : fill value for input RADIOMETER_DOWN_IRR_INTEGRATION_TIME data
%   a_RADIOMETER_DOWN_IRR_DARK_AVERAGE_fill_value     : fill value for input RADIOMETER_DOWN_IRR_DARK_AVERAGE data
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
%   02/19/2025 - RNU - creation (from Catherine Schmechtig's "January 2025 'R' code")
% ------------------------------------------------------------------------------
function [o_DOWN_IRRADIANCE_SPECTRUM, o_DOWN_IRRADIANCE_SPECTRUM_WAVELENGTHS] = ...
   compute_DOWN_IRRADIANCE_SPECTRUM( ...
   a_RADIOMETER_DOWN_IRR_INTEGRATION_TIME, ...
   a_RADIOMETER_DOWN_IRR_DARK_AVERAGE, ...
   a_RAW_DOWNWELLING_IRRADIANCE, ...
   a_RADIOMETER_DOWN_IRR_INTEGRATION_TIME_fill_value, ...
   a_RADIOMETER_DOWN_IRR_DARK_AVERAGE_fill_value, ...
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
      isfield(g_decArgo_calibInfo.RAMSES_ACC, 'Back1Dark') && ...
      isfield(g_decArgo_calibInfo.RAMSES_ACC, 'Back2Dark') && ...
      isfield(g_decArgo_calibInfo.RAMSES_ACC, 'CalAq') && ...
      isfield(g_decArgo_calibInfo.RAMSES_ACC, 'RamsesAccVerticalOffset'))
   cisCoef = g_decArgo_calibInfo.RAMSES_ACC.CisCoef;
   wavelength = g_decArgo_calibInfo.RAMSES_ACC.Wavelength;
   back1 = g_decArgo_calibInfo.RAMSES_ACC.Back1;
   back2 = g_decArgo_calibInfo.RAMSES_ACC.Back2;
   back1Dark = g_decArgo_calibInfo.RAMSES_ACC.Back1Dark;
   back2Dark = g_decArgo_calibInfo.RAMSES_ACC.Back2Dark;
   calAq = g_decArgo_calibInfo.RAMSES_ACC.CalAq;
   ramsesAccVerticalOffset = g_decArgo_calibInfo.RAMSES_ACC.RamsesAccVerticalOffset;
else
   fprintf('ERROR: Float #%d Cycle #%d Profile #%d: inconsistent RAMSES_ACC calibration information - DOWNWELLING_IRRADIANCE data set to fill value\n', ...
      g_decArgo_floatNum, ...
      a_profRamsesAcc.cycleNumber, ...
      a_profRamsesAcc.profileNumber);
   return
end

% retrieve PixelBegin, PixelEnd and Binning from the configuration
[configNames, configValues] = get_float_config_ir_rudics_sbd2(a_profRamsesAcc.cycleNumber, a_profRamsesAcc.profileNumber);
spectrumPixelBegin = get_config_value('CONFIG_APMT_SENSOR_14_P54', configNames, configValues);
spectrumPixelEnd = get_config_value('CONFIG_APMT_SENSOR_14_P55', configNames, configValues);
spectrumBinning = get_config_value('CONFIG_APMT_SENSOR_14_P56', configNames, configValues);

if (isempty(spectrumPixelBegin) || isempty(spectrumPixelEnd) || isempty(spectrumBinning))
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: RAMSES_ACC information (PIXEL_BEGIN, PIXEL_END, BINNING) are missing - DOWNWELLING_IRRADIANCE data set to fill value\n', ...
      g_decArgo_floatNum, ...
      a_profRamsesAcc.cycleNumber, ...
      a_profRamsesAcc.profileNumber);
   return
end

iMin = spectrumPixelBegin;
iMax = spectrumPixelEnd;
nBin = spectrumBinning;

% estimation of the background signal for the exposed pixels (back1b, back2b)
% estimation of the wavelength (waveb)
% estimation of the calAqb

nValues = floor((iMax - iMin + 1)/spectrumBinning);
back1b = zeros(nValues, 1);
back2b = zeros(nValues, 1);
backb = zeros(nValues, 1);
waveb = zeros(nValues, 1);
calAqb = zeros(nValues, 1);
for ib = 1:nValues
   indexList = (iMin+(ib-1)*nBin):(iMin+ib*nBin-1);
   back1b(ib) = sum(back1(indexList))/nBin;
   back2b(ib) = sum(back2(indexList))/nBin;
   waveb(ib) = sum(wavelength(indexList))/nBin;
   calAqb(ib) = sum(calAq(indexList))/nBin;
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
   find((a_RADIOMETER_DOWN_IRR_INTEGRATION_TIME == a_RADIOMETER_DOWN_IRR_INTEGRATION_TIME_fill_value) & ...
   (a_RADIOMETER_DOWN_IRR_DARK_AVERAGE == a_RADIOMETER_DOWN_IRR_DARK_AVERAGE_fill_value))]);

idNoDef = setdiff(1:length(a_RADIOMETER_DOWN_IRR_INTEGRATION_TIME), idDef);

% process input data
if (~isempty(idNoDef))

   for idLev = idNoDef

      integTime = a_RADIOMETER_DOWN_IRR_INTEGRATION_TIME(idLev);
      rawIrr = a_RAW_DOWNWELLING_IRRADIANCE(idLev, :);
      darkAvg = a_RADIOMETER_DOWN_IRR_DARK_AVERAGE(idLev);

      s1b = rawIrr;
      irrb = rawIrr;

      % estimation of the backDark
      % NB : it depends on the integration time so on LEVELS

      backDark = back1Dark + integTime*back2Dark/8192;
      sd = darkAvg/65535 - backDark;

      % estimation of the Background spectrum
      % NB: the Background spectrum depends on the integration time so on LEVELS

      for ib = 1:nValues
         backb(ib) = back1b(ib) + integTime*back2b(ib)/8192;

         % normalize the spectrum and substract the background
         s1b(ib) = rawIrr(ib)/65535 - backb(ib);

         % substract dark signal and apply sensibility coefficient
         irrb(ib) = (8192/integTime) * (s1b(ib) - sd)/calAqb(ib);

         o_DOWN_IRRADIANCE_SPECTRUM(idLev, ib) = irrb(ib)/10; % to be in line with the units
      end
   end

   o_DOWN_IRRADIANCE_SPECTRUM_WAVELENGTHS = repmat(waveb', size(o_DOWN_IRRADIANCE_SPECTRUM, 1), 1);

end

return
