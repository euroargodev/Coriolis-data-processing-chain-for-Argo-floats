% ------------------------------------------------------------------------------
% Compute RTQC data for NITRATE data.
%
% SYNTAX :
%  [o_profNitrateQc] = add_nitrate_rtqc_to_profile_file( ...
%    a_floatNum, a_cyNum, ...
%    a_UV_INTENSITY_NITRATE, a_UV_INTENSITY_DARK_NITRATE, ...
%    a_UV_INTENSITY_NITRATE_fill_value, a_UV_INTENSITY_DARK_NITRATE_fill_value, ...
%    a_UV_INTENSITY_NITRATE_pres, a_ctdData, ...
%    a_PRES_fill_value, a_TEMP_fill_value, a_PSAL_fill_value, ...
%    a_profNitrateQc, a_decoderId)
%
% INPUT PARAMETERS :
%   a_floatNum                             : float WMO number
%   a_cyNum                                : cycle number
%   a_UV_INTENSITY_NITRATE                 : input UV_INTENSITY_NITRATE data
%   a_UV_INTENSITY_DARK_NITRATE            : input UV_INTENSITY_DARK_NITRATE
%                                            data
%   a_UV_INTENSITY_NITRATE_fill_value      : fill value for input
%                                            UV_INTENSITY_NITRATE data
%   a_UV_INTENSITY_DARK_NITRATE_fill_value : fill value for input
%                                            UV_INTENSITY_DARK_NITRATE data
%   a_UV_INTENSITY_NITRATE_pres            : pressure levels of the
%                                            UV_INTENSITY_NITRATE data
%   a_ctdData                              : CTD (P, T, S) profile data
%   a_PRES_fill_value                      : fill value for input PRES data
%   a_TEMP_fill_value                      : fill value for input TEMP data
%   a_PSAL_fill_value                      : fill value for input PSAL data
%   a_profNitrateQc                        : input NITRATE_QC data
%   a_decoderId                            : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_profNitrateQc : Qcs of the NITRATE parameter profile
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/01/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profNitrateQc] = add_nitrate_rtqc_to_profile_file( ...
   a_floatNum, a_cyNum, ...
   a_UV_INTENSITY_NITRATE, a_UV_INTENSITY_DARK_NITRATE, ...
   a_UV_INTENSITY_NITRATE_fill_value, a_UV_INTENSITY_DARK_NITRATE_fill_value, ...
   a_UV_INTENSITY_NITRATE_pres, a_ctdData, ...
   a_PRES_fill_value, a_TEMP_fill_value, a_PSAL_fill_value, ...
   a_profNitrateQc, a_decoderId)

% output parameters initialization
o_profNitrateQc = [];

% arrays to store calibration information
global g_decArgo_calibInfo;

% QC flag values
global g_decArgo_qcStrDef;           % ' '
global g_decArgo_qcStrNoQc;          % '0'
global g_decArgo_qcStrGood;          % '1'
global g_decArgo_qcStrProbablyGood;  % '2'
global g_decArgo_qcStrCorrectable;   % '3'
global g_decArgo_qcStrBad;           % '4'
global g_decArgo_qcStrChanged;       % '5'
global g_decArgo_qcStrInterpolated;  % '8'
global g_decArgo_qcStrMissing;       % '9'


if (isempty(a_UV_INTENSITY_NITRATE) || isempty(a_UV_INTENSITY_DARK_NITRATE))
   return
end

% get calibration information
if (isempty(g_decArgo_calibInfo))
   fprintf('RTQC_WARNING: Float #%d Cycle #%d: SUNA calibration information are missing => unable to perform NITRATE RTQC specific test (Test #59)\n', ...
      a_floatNum, a_cyNum);
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
   fprintf('RTQC_WARNING: Float #%d Cycle #%d: inconsistent SUNA calibration information => unable to perform NITRATE RTQC specific test (Test #59)\n', ...
      a_floatNum, a_cyNum);
   return
end

% retrieve configuration information
if (isempty(sunaVerticalOffset))
   sunaVerticalOffset = 0;
   fprintf('RTQC_WARNING: Float #%d Cycle #%d: SUNA vertical offset is missing => NITRATE RTQC specific test (Test #59) performed with a 0 dbar vertical offset\n', ...
      a_floatNum, a_cyNum);
end

if (isempty(floatPixelBegin) || isempty(floatPixelBegin))
   fprintf('RTQC_WARNING: Float #%d Cycle #%d: SUNA information (PIXEL_BEGIN, PIXEL_END) are missing => unable to perform NITRATE RTQC specific test (Test #59)\n', ...
      a_floatNum, a_cyNum);
   return
end

% in the first versions of CTS5 floats, the transmitted values of
% Pixel Begin/End should be shifted by one pixel to the right
if (a_decoderId == 121)
   floatPixelBegin = floatPixelBegin + 1;
   floatPixelEnd = floatPixelEnd + 1;
else
   % specific
   if (ismember(a_floatNum, [6902897]))
      floatPixelBegin = floatPixelBegin + 1;
      floatPixelEnd = floatPixelEnd + 1;
   end
end

% interpolate/extrapolate the CTD data at the pressures of the MOLAR_NITRATE
% measurements (to take the vertical offset into account)
ctdIntData = compute_interpolated_CTD_measurements(a_ctdData, a_UV_INTENSITY_NITRATE_pres+sunaVerticalOffset);

% compute pixel interval that covers the [217 nm, 240 nm] wavelength interval
idF1 = find(tabOpticalWavelengthUv >= 217);
idF2 = find(tabOpticalWavelengthUv <= 240);
pixelBegin = idF1(1);
pixelEnd = idF2(end);
if ((pixelBegin < floatPixelBegin) || (pixelEnd > floatPixelEnd))
   fprintf('RTQC_WARNING: Float #%d Cycle #%d: not enough SUNA transmitted pixels => unable to perform NITRATE RTQC specific test (Test #59)\n', ...
      a_floatNum, a_cyNum);
   return
end

% output parameters initialization
% we should not consider input QC so that test #59 results can be used for
% updating NITRATE_QC and NITRATE_ADJUSTED_QC
o_profNitrateQc = a_profNitrateQc;
o_profNitrateQc(find(o_profNitrateQc ~= g_decArgo_qcStrDef)) = g_decArgo_qcStrNoQc;

% select useful data
tabOpticalWavelengthUv = tabOpticalWavelengthUv(pixelBegin:pixelEnd);
tabENitrate = tabENitrate(pixelBegin:pixelEnd);
tabESwaNitrate = tabESwaNitrate(pixelBegin:pixelEnd);
tabUvIntensityRefNitrate = tabUvIntensityRefNitrate(pixelBegin:pixelEnd);

% tabUvIntensityNitrate = a_UV_INTENSITY_NITRATE(:, floatPixelBegin-pixelBegin+1:end-(floatPixelEnd-pixelEnd));
tabUvIntensityNitrate = a_UV_INTENSITY_NITRATE(:, pixelBegin-floatPixelBegin+1:pixelBegin-floatPixelBegin+1+(pixelEnd-pixelBegin+1)-1);

% format useful data
tabUvIntensityDarkNitrate = repmat(a_UV_INTENSITY_DARK_NITRATE, 1, size(tabUvIntensityNitrate, 2));
tabUvIntensityRefNitrate = repmat(tabUvIntensityRefNitrate, size(tabUvIntensityNitrate, 1), 1);
tabESwaNitrate = repmat(tabESwaNitrate, size(tabUvIntensityNitrate, 1), 1);
tempCalNitrate = repmat(tempCalNitrate, size(ctdIntData(:, 2)));
tabPsal = repmat(ctdIntData(:, 3), 1, size(tabUvIntensityNitrate, 2));
tabPres = repmat(ctdIntData(:, 1), 1, size(tabUvIntensityNitrate, 2));

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
   (ctdIntData(:, 1) == a_PRES_fill_value) | ...
   (ctdIntData(:, 2) == a_TEMP_fill_value) | ...
   (ctdIntData(:, 3) == a_PSAL_fill_value))]);

idNoDef = setdiff([1:size(tabUvIntensityNitrate, 1)], idDef)';

if (~isempty(idNoDef))
   
   profNitrateQc = o_profNitrateQc(idNoDef);
   tabUvIntensityNitrate = tabUvIntensityNitrate(idNoDef, :);
   tabUvIntensityDarkNitrate = tabUvIntensityDarkNitrate(idNoDef, :);
   tabUvIntensityRefNitrate = tabUvIntensityRefNitrate(idNoDef, :);
   tabESwaNitrate = tabESwaNitrate(idNoDef, :);
   tempCalNitrate = tempCalNitrate(idNoDef);
   tabPsal = tabPsal(idNoDef, :);
   tabPres = tabPres(idNoDef, :);
   ctdData = ctdIntData(idNoDef, :);
   
   % check saturation of spectrophotometer
   for idL = 1:size(tabUvIntensityNitrate, 1)
      if (any(tabUvIntensityNitrate(idL, :) == 65535))
         %          fprintf('RTQC_INFO_TEMPO: Float #%d Cycle #%d: NITRATE saturation test failed (level: %d)\n', ...
         %             a_floatNum, a_cyNum, idL);
         profNitrateQc(idL) = set_qc(profNitrateQc(idL), g_decArgo_qcStrCorrectable);
      end
   end
   
   % compute NITRATE
   
   % Equation #1
   absorbanceSw = -log10((tabUvIntensityNitrate - tabUvIntensityDarkNitrate) ./ tabUvIntensityRefNitrate);
   
   % check absorbance at 240 nm
   for idL = 1:size(absorbanceSw, 1)
      if ((absorbanceSw(idL, end) >= 0.8) && (absorbanceSw(idL, end) < 1.1))
         %          fprintf('RTQC_INFO_TEMPO: Float #%d Cycle #%d: NITRATE absorbance test failed (level: %d value: %g)\n', ...
         %             a_floatNum, a_cyNum, idL, absorbanceSw(idL, end));
         profNitrateQc(idL) = set_qc(profNitrateQc(idL), g_decArgo_qcStrCorrectable);
      elseif (absorbanceSw(idL, end) >= 1.1)
         %          fprintf('RTQC_INFO_TEMPO: Float #%d Cycle #%d: NITRATE absorbance test failed (level: %d value: %g)\n', ...
         %            a_floatNum, a_cyNum, idL, absorbanceSw(idL, end));
         profNitrateQc(idL) = set_qc(profNitrateQc(idL), g_decArgo_qcStrBad);
      end
   end
   
   % check RMS Error
   
   % check that the 'fitlm' function is available in the Matlab configuration
   if (~isempty(which('fitlm')))
      
      % Equation #2
      eSwaInsitu = tabESwaNitrate .* ...
         f_function(tabOpticalWavelengthUv, ctdData(:, 2)) ./ ...
         f_function(tabOpticalWavelengthUv, tempCalNitrate);
      
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
      
      a = [tabOpticalWavelengthUv' tabENitrate'];
      for idL = 1:size(absorbanceCorNitrate, 1)
         b = absorbanceCorNitrate(idL, :)';
         mdl = fitlm(a, b);
         
         % check RMS Error
         rawResiduals = mdl.Residuals.Raw;
         fitErrorNitrate = sqrt(sum(rawResiduals.*rawResiduals)/size(absorbanceCorNitrate, 2));
         if (fitErrorNitrate >= 0.003)
            %             fprintf('RTQC_INFO_TEMPO: Float #%d Cycle #%d: NITRATE RMS Error test failed (level: %d value: %g)\n', ...
            %                a_floatNum, a_cyNum, idL, fitErrorNitrate);
            profNitrateQc(idL) = set_qc(profNitrateQc(idL), g_decArgo_qcStrBad);
         end
      end
      
   else
      fprintf('RTQC_WARNING: Float #%d Cycle #%d: the ''fitlm'' function is not available in your Matlab configuration => unable to perform ''RMS Error'' part of NITRATE RTQC specific test (Test #59)\n', ...
         a_floatNum, a_cyNum);
   end
   
   % update NITRATE_QC
   o_profNitrateQc(idNoDef) = profNitrateQc;
end

return

% ------------------------------------------------------------------------------
% Subfunction for NITRATE processing from UV_INTENSITY_NITRATE.
%
% SYNTAX :
%  [o_output] = f_function(a_opticalWavelength, a_temp)
%
% INPUT PARAMETERS :
%   a_opticalWavelength : OPTICAL_WAVELENGTH_UV calibration information
%   a_temp              : temperature used in the processing
%
% OUTPUT PARAMETERS :
%   o_output : result
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/08/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_output] = f_function(a_opticalWavelength, a_temp)

% NITRATE coefficients
global g_decArgo_nitrate_a;
global g_decArgo_nitrate_b;
global g_decArgo_nitrate_c;
global g_decArgo_nitrate_d;
global g_decArgo_nitrate_opticalWavelengthOffset;

tabOpticalWavelength = repmat(a_opticalWavelength, size(a_temp, 1), 1);
tabTemp = repmat(a_temp, 1, size(a_opticalWavelength, 2));
o_output = (g_decArgo_nitrate_a + g_decArgo_nitrate_b*tabTemp) .* exp((g_decArgo_nitrate_c + g_decArgo_nitrate_d*tabTemp) .* (tabOpticalWavelength - g_decArgo_nitrate_opticalWavelengthOffset));

return
