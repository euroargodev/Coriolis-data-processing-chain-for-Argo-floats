% ------------------------------------------------------------------------------
% Compute NITRATE from UV_INTENSITY_NITRATE provided by the SUNA sensor.
%
% SYNTAX :
%  [o_NITRATE] = compute_drift_NITRATE_1xx_5_to_9_11_12_14_15_21_to_26_28_to_31( ...
%    a_UV_INTENSITY_NITRATE, a_UV_INTENSITY_DARK_NITRATE, ...
%    a_UV_INTENSITY_NITRATE_fill_value, a_UV_INTENSITY_DARK_NITRATE_fill_value, ...
%    a_NITRATE_fill_value, ...
%    a_UV_INTENSITY_NITRATE_dates, a_ctdDates, a_ctdData, ...
%    a_PRES_fill_value, a_TEMP_fill_value, a_PSAL_fill_value, ...
%    a_profSuna, a_decoderId)
%
% INPUT PARAMETERS :
%   a_UV_INTENSITY_NITRATE                 : input UV_INTENSITY_NITRATE data
%   a_UV_INTENSITY_DARK_NITRATE            : input UV_INTENSITY_DARK_NITRATE
%                                            data
%   a_UV_INTENSITY_NITRATE_fill_value      : fill value for input
%                                            UV_INTENSITY_NITRATE data
%   a_UV_INTENSITY_DARK_NITRATE_fill_value : fill value for input
%                                            UV_INTENSITY_DARK_NITRATE data
%   a_NITRATE_fill_value                   : fill value for output NITRATE data
%   a_UV_INTENSITY_NITRATE_dates           : dates of the UV_INTENSITY_NITRATE
%                                            data
%   a_ctdDates                             : dates of ascociated CTD (P, T, S)
%                                            data
%   a_ctdData                              : ascociated CTD (P, T, S) data
%   a_PRES_fill_value                      : fill value for input PRES data
%   a_TEMP_fill_value                      : fill value for input TEMP data
%   a_PSAL_fill_value                      : fill value for input PSAL data
%   a_profSuna                             : input SUNA profile structure
%   a_decoderId                            : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_NITRATE : output NITRATE data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/08/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_NITRATE] = compute_drift_NITRATE_1xx_5_to_9_11_12_14_15_21_to_26_28_to_31( ...
   a_UV_INTENSITY_NITRATE, a_UV_INTENSITY_DARK_NITRATE, ...
   a_UV_INTENSITY_NITRATE_fill_value, a_UV_INTENSITY_DARK_NITRATE_fill_value, ...
   a_NITRATE_fill_value, ...
   a_UV_INTENSITY_NITRATE_dates, a_ctdDates, a_ctdData, ...
   a_PRES_fill_value, a_TEMP_fill_value, a_PSAL_fill_value, ...
   a_profSuna, a_decoderId)

% output parameters initialization
o_NITRATE = ones(size(a_UV_INTENSITY_NITRATE, 1), 1)*a_NITRATE_fill_value;

% current float WMO number
global g_decArgo_floatNum;

% arrays to store calibration information
global g_decArgo_calibInfo;

% NITRATE coefficients
global g_decArgo_nitrate_a;
global g_decArgo_nitrate_b;
global g_decArgo_nitrate_c;
global g_decArgo_nitrate_d;
global g_decArgo_nitrate_e;
global g_decArgo_nitrate_opticalWavelengthOffset;


if (isempty(a_UV_INTENSITY_NITRATE) || isempty(a_UV_INTENSITY_DARK_NITRATE))
   return
end

% check that the 'fitlm' function is available in the Matlab configuration
if (isempty(which('fitlm')))
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: the ''fitlm'' function is not available in your Matlab configuration - NITRATE data set to fill value in ''%c'' profile of SUNA sensor\n', ...
      g_decArgo_floatNum, ...
      a_profSuna.cycleNumber, ...
      a_profSuna.profileNumber, ...
      a_profSuna.direction);
   return
end

% get calibration information
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: SUNA calibration information are missing - NITRATE data set to fill value in ''%c'' profile of SUNA sensor\n', ...
      g_decArgo_floatNum, ...
      a_profSuna.cycleNumber, ...
      a_profSuna.profileNumber, ...
      a_profSuna.direction);
   return
elseif (isfield(g_decArgo_calibInfo, 'SUNA') && ...
      isfield(g_decArgo_calibInfo.SUNA, 'TabOpticalWavelengthUv') && ...
      isfield(g_decArgo_calibInfo.SUNA, 'TabENitrate') && ...
      isfield(g_decArgo_calibInfo.SUNA, 'TabESwaNitrate') && ...
      isfield(g_decArgo_calibInfo.SUNA, 'TabUvIntensityRefNitrate') && ...
      isfield(g_decArgo_calibInfo.SUNA, 'TEMP_CAL_NITRATE') && ...
      isfield(g_decArgo_calibInfo.SUNA, 'SunaVerticalOffset') && ...
      isfield(g_decArgo_calibInfo.SUNA, 'FloatPixelBegin') && ...
      isfield(g_decArgo_calibInfo.SUNA, 'FloatPixelEnd'))
   tabOpticalWavelengthUv = g_decArgo_calibInfo.SUNA.TabOpticalWavelengthUv;
   tabENitrate = g_decArgo_calibInfo.SUNA.TabENitrate;
   tabESwaNitrate = g_decArgo_calibInfo.SUNA.TabESwaNitrate;
   tabUvIntensityRefNitrate = g_decArgo_calibInfo.SUNA.TabUvIntensityRefNitrate;
   tempCalNitrate = g_decArgo_calibInfo.SUNA.TEMP_CAL_NITRATE;
   sunaVerticalOffset = g_decArgo_calibInfo.SUNA.SunaVerticalOffset;
   floatPixelBegin = g_decArgo_calibInfo.SUNA.FloatPixelBegin;
   floatPixelEnd = g_decArgo_calibInfo.SUNA.FloatPixelEnd;
else
   fprintf('ERROR: Float #%d Cycle #%d Profile #%d: inconsistent SUNA calibration information - NITRATE data set to fill value in ''%c'' profile of SUNA sensor\n', ...
      g_decArgo_floatNum, ...
      a_profSuna.cycleNumber, ...
      a_profSuna.profileNumber, ...
      a_profSuna.direction);
   return
end

% retrieve configuration information
if (isempty(floatPixelBegin) || isempty(floatPixelEnd))
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: SUNA information (PIXEL_BEGIN, PIXEL_END) are missing - NITRATE data set to fill value in ''%c'' profile of SUNA sensor\n', ...
      g_decArgo_floatNum, ...
      a_profSuna.cycleNumber, ...
      a_profSuna.profileNumber, ...
      a_profSuna.direction);
   return
end

% in first version of CTS5 floats (decoderId = 121), the transmitted values of
% Pixel Begin/End should be shifted by one pixel to the right
if (a_decoderId == 121)
   floatPixelBegin = floatPixelBegin + 1;
   floatPixelEnd = floatPixelEnd + 1;
else
   % specific
   if (ismember(g_decArgo_floatNum, [6902897]))
      floatPixelBegin = floatPixelBegin + 1;
      floatPixelEnd = floatPixelEnd + 1;
   end
end

% assign the CTD data to the UV_INTENSITY_NITRATE measurements (timely closest
% association)
ctdLinkData = assign_CTD_measurements(a_ctdDates, a_ctdData, a_UV_INTENSITY_NITRATE_dates);

% compute pixel interval that covers the [217 nm, 240 nm] wavelength interval
idF1 = find(tabOpticalWavelengthUv >= 217);
idF2 = find(tabOpticalWavelengthUv <= 240);
pixelBegin = idF1(1);
pixelEnd = idF2(end);
if ((pixelBegin < floatPixelBegin) || (pixelEnd > floatPixelEnd))
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: not enough SUNA transmitted pixels - NITRATE data set to fill value in ''%c'' profile of SUNA sensor\n', ...
      g_decArgo_floatNum, ...
      a_profSuna.cycleNumber, ...
      a_profSuna.profileNumber, ...
      a_profSuna.direction);
   return
end

% select useful data
tabOpticalWavelengthUv = tabOpticalWavelengthUv(pixelBegin:pixelEnd);
tabENitrate = tabENitrate(pixelBegin:pixelEnd);
tabESwaNitrate = tabESwaNitrate(pixelBegin:pixelEnd);
tabUvIntensityRefNitrate = tabUvIntensityRefNitrate(pixelBegin:pixelEnd);

% tabUvIntensityNitrate = a_UV_INTENSITY_NITRATE(:, floatPixelBegin-pixelBegin+1:end-(floatPixelEnd-pixelEnd));
tabUvIntensityNitrate = a_UV_INTENSITY_NITRATE(:, floatPixelBegin-pixelBegin+1:floatPixelBegin-pixelBegin+1+(pixelEnd-pixelBegin+1)-1);

% if (size(tabUvIntensityRefNitrate, 2) ~= size(tabUvIntensityNitrate, 2))
%    fprintf('ERROR: Float #%d Cycle #%d Profile #%d: SUNA data are inconsistent (in size) - NITRATE data set to fill value in ''%c'' profile of SUNA sensor\n', ...
%       g_decArgo_floatNum, ...
%       a_profSuna.cycleNumber, ...
%       a_profSuna.profileNumber, ...
%       a_profSuna.direction);
%    return
% end

% format useful data
tabUvIntensityDarkNitrate = repmat(a_UV_INTENSITY_DARK_NITRATE, 1, size(tabUvIntensityNitrate, 2));
tabUvIntensityRefNitrate = repmat(tabUvIntensityRefNitrate, size(tabUvIntensityNitrate, 1), 1);
tabESwaNitrate = repmat(tabESwaNitrate, size(tabUvIntensityNitrate, 1), 1);
tempCalNitrate = repmat(tempCalNitrate, size(ctdLinkData(:, 2)));
tabPsal = repmat(ctdLinkData(:, 3), 1, size(tabUvIntensityNitrate, 2));
tabPres = repmat(ctdLinkData(:, 1), 1, size(tabUvIntensityNitrate, 2));

% to test management of NoDef values
% if (size(ctdLinkData, 1) == 9)
%    tempo = 1
%    tabUvIntensityNitrate(2, :) = ones(1, size(tabUvIntensityNitrate, 2))*a_UV_INTENSITY_NITRATE_fill_value;
%    tabUvIntensityNitrate(8, :) = ones(1, size(tabUvIntensityNitrate, 2))*a_UV_INTENSITY_NITRATE_fill_value;
%    ctdLinkData(4, 1) = a_PRES_fill_value;
%    ctdLinkData(6, 2) = a_TEMP_fill_value;
%    ctdLinkData(6, 3) = a_PSAL_fill_value;
% end

% exclude fill values
idDef = [];
for idL = 1:size(tabUvIntensityNitrate, 1)
   data = tabUvIntensityNitrate(idL, :);
   if ((length(unique(data)) == 1) && (unique(data) == a_UV_INTENSITY_NITRATE_fill_value))
      idDef = [idDef; idL];
   end
end

idDef = sort([idDef; ...
   find((a_UV_INTENSITY_DARK_NITRATE == a_UV_INTENSITY_DARK_NITRATE_fill_value) | ...
   (ctdLinkData(:, 1) == a_PRES_fill_value) | ...
   (ctdLinkData(:, 2) == a_TEMP_fill_value) | ...
   (ctdLinkData(:, 3) == a_PSAL_fill_value))]);

idNoDef = setdiff([1:size(tabUvIntensityNitrate, 1)], idDef)';

if (~isempty(idNoDef))
   
   tabUvIntensityNitrate = tabUvIntensityNitrate(idNoDef, :);
   tabUvIntensityDarkNitrate = tabUvIntensityDarkNitrate(idNoDef, :);
   tabUvIntensityRefNitrate = tabUvIntensityRefNitrate(idNoDef, :);
   tabESwaNitrate = tabESwaNitrate(idNoDef, :);
   tempCalNitrate = tempCalNitrate(idNoDef);
   tabPsal = tabPsal(idNoDef, :);
   tabPres = tabPres(idNoDef, :);
   ctdData = ctdLinkData(idNoDef, :);
   
   % compute NITRATE
   
   % Equation #1
   absorbanceSw = -log10((tabUvIntensityNitrate - tabUvIntensityDarkNitrate) ./ tabUvIntensityRefNitrate);

   % Equation #2
   tCorrCoef = [g_decArgo_nitrate_a g_decArgo_nitrate_b g_decArgo_nitrate_c g_decArgo_nitrate_d g_decArgo_nitrate_e];
   tCorr = polyval(tCorrCoef, (tabOpticalWavelengthUv - g_decArgo_nitrate_opticalWavelengthOffset)) .* (ctdData(:, 2) - tempCalNitrate);
   eSwaInsitu = tabESwaNitrate .* exp(tCorr);

   % Equation #4 (with the pressure effect taken into account)
   absorbanceCorNitrate = absorbanceSw - (eSwaInsitu .* tabPsal) .* (1 - (0.026 * tabPres / 1000));

   % Equation #5
   % solve:
   % A11*x1 + A12x2 + A13*X3 = B1
   % A21*x1 + A22x2 + A23*X3 = B2
   % ...
   % Ar1*x1 + Ar2x2 + Ar3*X3 = Br
   % where B1 ... Br = ABSORBANCE_COR_NITRATE(r)
   % where A12 ... Ar2 = OPTICAL_WAVELENGTH_UV(r)
   % where A13 ... Ar3 = E_NITRATE(r)
   % then X3 = MOLAR_NITRATE
   
   tabMolarNitrate = nan(size(tabUvIntensityDarkNitrate, 1), 1);
   a = [tabOpticalWavelengthUv' tabENitrate'];
   nbComplex = 0;
   for idL = 1:length(tabMolarNitrate)
      b = absorbanceCorNitrate(idL, :)';
      if (all(imag(b) == 0))
         mdl = fitlm(double(a), double(b)); % both inputs should be double since R2020b
         tabMolarNitrate(idL) = mdl.Coefficients.Estimate(end);
      else
         nbComplex = nbComplex + 1;
      end
   end
   if (nbComplex > 0)
      fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d NITRATE values are complex - these values are set to fill value in drift measurements of SUNA sensor\n', ...
         g_decArgo_floatNum, ...
         a_profSuna.cycleNumber, ...
         a_profSuna.profileNumber, ...
         nbComplex);
   end
   
   % Equation #6
   % compute potential temperature and potential density
   [measLon, measLat] = get_meas_location(a_profSuna.cycleNumber, a_profSuna.profileNumber, a_profSuna);
   rho = potential_density_gsw(ctdData(:, 1), ctdData(:, 2), ctdData(:, 3), 0, measLon, measLat);
   rho = rho/1000;
   
   % compute NITRATE data (units convertion: micromol/L to micromol/kg)
   nitrateValues = tabMolarNitrate ./ rho;
   idNoNan = find(~isnan(nitrateValues));
   o_NITRATE(idNoDef(idNoNan)) = nitrateValues(idNoNan);

   % replace Inf values with fillValue
   if (any(isinf(o_NITRATE)))
      idToDef = find(isinf(o_NITRATE));
      o_NITRATE(idToDef) = a_NITRATE_fill_value;
      
      fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d NITRATE values are Inf - these values are set to fill value in drift measurements of SUNA sensor\n', ...
         g_decArgo_floatNum, ...
         a_profSuna.cycleNumber, ...
         a_profSuna.profileNumber, ...
         length(idToDef));
   end
end

return
