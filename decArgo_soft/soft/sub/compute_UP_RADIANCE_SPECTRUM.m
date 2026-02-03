% ------------------------------------------------------------------------------
% Compute UP_RADIANCE_SPECTRUM from RAW_UPWELLING_RADIANCE provided by the
% RAMSES_ARC sensor.
%
% SYNTAX :
% [o_UP_RADIANCE_SPECTRUM, o_UP_RADIANCE_SPECTRUM_WAVELENGTHS] = ...
%   compute_UP_RADIANCE_SPECTRUM( ...
%   a_RADIOMETER_UP_RAD_INTEGRATION_TIME, ...
%   a_RADIOMETER_UP_RAD_DARK_AVERAGE, ...
%   a_RAW_UPWELLING_RADIANCE, ...
%   a_RADIOMETER_UP_RAD_INTEGRATION_TIME_fill_value, ...
%   a_RADIOMETER_UP_RAD_DARK_AVERAGE_fill_value, ...
%   a_RAW_UPWELLING_RADIANCE_fill_value, ...
%   a_UP_RADIANCE_SPECTRUM_fill_value, ...
%   a_UP_RADIANCE_SPECTRUM_WAVELENGTHS_fill_value, ...
%   a_profRamsesArc)
%
% INPUT PARAMETERS :
%   a_RADIOMETER_UP_RAD_INTEGRATION_TIME            : input RADIOMETER_UP_RAD_INTEGRATION_TIME data
%   a_RADIOMETER_UP_RAD_DARK_AVERAGE                : input RADIOMETER_UP_RAD_DARK_AVERAGE data
%   a_RAW_UPWELLING_RADIANCE                        : input RAW_UPWELLING_RADIANCE data
%   a_RADIOMETER_UP_RAD_INTEGRATION_TIME_fill_value : fill value for input RADIOMETER_UP_RAD_INTEGRATION_TIME data
%   a_RADIOMETER_UP_RAD_DARK_AVERAGE_fill_value     : fill value for input RADIOMETER_UP_RAD_DARK_AVERAGE data
%   a_RAW_UPWELLING_RADIANCE_fill_value             : fill value for input RAW_UPWELLING_RADIANCE data
%   a_UP_RADIANCE_SPECTRUM_fill_value               : fill value for input UP_RADIANCE_SPECTRUM data
%   a_UP_RADIANCE_SPECTRUM_WAVELENGTHS_fill_value   : fill value for input UP_RADIANCE_SPECTRUM_WAVELENGTHS data
%   a_profRamsesArc                                 : input RAMSES_ARC profile structure
%
% OUTPUT PARAMETERS :
%   o_UP_RADIANCE_SPECTRUM              : output UP_RADIANCE_SPECTRUM data
%   o_UP_RADIANCE_SPECTRUM_WAVELENGTHS  : associated wavelengths
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2025 - RNU - creation (from Catherine Schmechtig's "January 2025 'R' code")
% ------------------------------------------------------------------------------
function [o_UP_RADIANCE_SPECTRUM, o_UP_RADIANCE_SPECTRUM_WAVELENGTHS] = ...
   compute_UP_RADIANCE_SPECTRUM( ...
   a_RADIOMETER_UP_RAD_INTEGRATION_TIME, ...
   a_RADIOMETER_UP_RAD_DARK_AVERAGE, ...
   a_RAW_UPWELLING_RADIANCE, ...
   a_RADIOMETER_UP_RAD_INTEGRATION_TIME_fill_value, ...
   a_RADIOMETER_UP_RAD_DARK_AVERAGE_fill_value, ...
   a_RAW_UPWELLING_RADIANCE_fill_value, ...
   a_UP_RADIANCE_SPECTRUM_fill_value, ...
   a_UP_RADIANCE_SPECTRUM_WAVELENGTHS_fill_value, ...
   a_profRamsesArc)

% output parameters initialization
o_UP_RADIANCE_SPECTRUM = ones(size(a_RAW_UPWELLING_RADIANCE))*a_UP_RADIANCE_SPECTRUM_fill_value;
o_UP_RADIANCE_SPECTRUM_WAVELENGTHS = ones(size(a_RAW_UPWELLING_RADIANCE))*a_UP_RADIANCE_SPECTRUM_WAVELENGTHS_fill_value;

% current float WMO number
global g_decArgo_floatNum;

% arrays to store calibration information
global g_decArgo_calibInfo;


if (isempty(a_RAW_UPWELLING_RADIANCE))
   return
end

% get calibration information
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: RAMSES_ARC calibration information are missing - UP_RADIANCE_SPECTRUM data set to fill value\n', ...
      g_decArgo_floatNum, ...
      a_profRamsesArc.cycleNumber, ...
      a_profRamsesArc.profileNumber);
   return
elseif (isfield(g_decArgo_calibInfo, 'RAMSES_ARC') && ...
      isfield(g_decArgo_calibInfo.RAMSES_ARC, 'CisCoef') && ...
      isfield(g_decArgo_calibInfo.RAMSES_ARC, 'Wavelength') && ...
      isfield(g_decArgo_calibInfo.RAMSES_ARC, 'Back1') && ...
      isfield(g_decArgo_calibInfo.RAMSES_ARC, 'Back2') && ...
      isfield(g_decArgo_calibInfo.RAMSES_ARC, 'Back1Dark') && ...
      isfield(g_decArgo_calibInfo.RAMSES_ARC, 'Back2Dark') && ...
      isfield(g_decArgo_calibInfo.RAMSES_ARC, 'CalAq') && ...
      isfield(g_decArgo_calibInfo.RAMSES_ARC, 'RamsesArcVerticalOffset'))
   cisCoef = g_decArgo_calibInfo.RAMSES_ARC.CisCoef;
   wavelength = g_decArgo_calibInfo.RAMSES_ARC.Wavelength;
   back1 = g_decArgo_calibInfo.RAMSES_ARC.Back1;
   back2 = g_decArgo_calibInfo.RAMSES_ARC.Back2;
   back1Dark = g_decArgo_calibInfo.RAMSES_ARC.Back1Dark;
   back2Dark = g_decArgo_calibInfo.RAMSES_ARC.Back2Dark;
   calAq = g_decArgo_calibInfo.RAMSES_ARC.CalAq;
   ramsesArcVerticalOffset = g_decArgo_calibInfo.RAMSES_ARC.RamsesArcVerticalOffset;
else
   fprintf('ERROR: Float #%d Cycle #%d Profile #%d: inconsistent RAMSES_ARC calibration information - UP_RADIANCE_SPECTRUM data set to fill value\n', ...
      g_decArgo_floatNum, ...
      a_profRamsesArc.cycleNumber, ...
      a_profRamsesArc.profileNumber);
   return
end

% retrieve PixelBegin, PixelEnd and Binning from the configuration
[configNames, configValues] = get_float_config_ir_rudics_sbd2(a_profRamsesArc.cycleNumber, a_profRamsesArc.profileNumber);
spectrumPixelBegin = get_config_value('CONFIG_APMT_SENSOR_21_P54', configNames, configValues);
spectrumPixelEnd = get_config_value('CONFIG_APMT_SENSOR_21_P55', configNames, configValues);
spectrumBinning = get_config_value('CONFIG_APMT_SENSOR_21_P56', configNames, configValues);

if (isempty(spectrumPixelBegin) || isempty(spectrumPixelEnd) || isempty(spectrumBinning))
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: RAMSES_ARC information (PIXEL_BEGIN, PIXEL_END, BINNING) are missing - UP_RADIANCE_SPECTRUM data set to fill value\n', ...
      g_decArgo_floatNum, ...
      a_profRamsesArc.cycleNumber, ...
      a_profRamsesArc.profileNumber);
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
for idL = 1:size(a_RAW_UPWELLING_RADIANCE, 1)
   data = a_RAW_UPWELLING_RADIANCE(idL, :);
   if ((length(unique(data)) == 1) && (unique(data) == a_RAW_UPWELLING_RADIANCE_fill_value))
      idDef = [idDef; idL];
   end
end

idDef = sort([idDef; ...
   find((a_RADIOMETER_UP_RAD_INTEGRATION_TIME == a_RADIOMETER_UP_RAD_INTEGRATION_TIME_fill_value) & ...
   (a_RADIOMETER_UP_RAD_DARK_AVERAGE == a_RADIOMETER_UP_RAD_DARK_AVERAGE_fill_value))]);

idNoDef = setdiff(1:length(a_RADIOMETER_UP_RAD_INTEGRATION_TIME), idDef);

% process input data
if (~isempty(idNoDef))

   for idLev = idNoDef

      integTime = a_RADIOMETER_UP_RAD_INTEGRATION_TIME(idLev);
      rawIrr = a_RAW_UPWELLING_RADIANCE(idLev, :);
      darkAvg = a_RADIOMETER_UP_RAD_DARK_AVERAGE(idLev);

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

         o_UP_RADIANCE_SPECTRUM(idLev, ib) = irrb(ib)/10; % to be in line with the units
      end
   end

   o_UP_RADIANCE_SPECTRUM_WAVELENGTHS = repmat(waveb', size(o_UP_RADIANCE_SPECTRUM, 1), 1);

end

return
