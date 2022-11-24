% ------------------------------------------------------------------------------
% Compute NITRATE from UV_INTENSITY_NITRATE provided by the SUNA sensor.
%
% SYNTAX :
%  [o_NITRATE, o_rmsError] = ...
%    compute_profile_NITRATE_105_to_109_111_112_121_to_125( ...
%    a_UV_INTENSITY_NITRATE, a_UV_INTENSITY_DARK_NITRATE, ...
%    a_UV_INTENSITY_NITRATE_fill_value, a_UV_INTENSITY_DARK_NITRATE_fill_value, ...
%    a_NITRATE_fill_value, ...
%    a_UV_INTENSITY_NITRATE_pres, a_ctdData, ...
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
%   a_UV_INTENSITY_NITRATE_pres            : pressure levels of the
%                                            UV_INTENSITY_NITRATE data
%   a_ctdData                              : CTD (P, T, S) profile data
%   a_PRES_fill_value                      : fill value for input PRES data
%   a_TEMP_fill_value                      : fill value for input TEMP data
%   a_PSAL_fill_value                      : fill value for input PSAL data
%   a_profSuna                             : input SUNA profile structure
%   a_decoderId                            : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_NITRATE  : output NITRATE data
%   o_rmsError : RMS error of the fit
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/08/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_NITRATE, o_rmsError] = ...
   compute_profile_NITRATE_105_to_109_111_112_121_to_125( ...
   a_UV_INTENSITY_NITRATE, a_UV_INTENSITY_DARK_NITRATE, ...
   a_UV_INTENSITY_NITRATE_fill_value, a_UV_INTENSITY_DARK_NITRATE_fill_value, ...
   a_NITRATE_fill_value, ...
   a_UV_INTENSITY_NITRATE_pres, a_ctdData, ...
   a_PRES_fill_value, a_TEMP_fill_value, a_PSAL_fill_value, ...
   a_profSuna, a_decoderId)

% output parameters initialization
o_NITRATE = ones(size(a_UV_INTENSITY_NITRATE, 1), 1)*a_NITRATE_fill_value;
o_rmsError = nan(size(a_UV_INTENSITY_NITRATE, 1), 1);

% current float WMO number
global g_decArgo_floatNum;

% arrays to store calibration information
global g_decArgo_calibInfo;

global g_tempoJPR_nitrateFromFloat;


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
if (isempty(sunaVerticalOffset))
   sunaVerticalOffset = 0;
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: SUNA vertical offset is missing - NITRATE data computed with a 0 dbar vertical offset in ''%c'' profile of SUNA sensor\n', ...
      g_decArgo_floatNum, ...
      a_profSuna.cycleNumber, ...
      a_profSuna.profileNumber, ...
      a_profSuna.direction);
end

if (isempty(floatPixelBegin) || isempty(floatPixelBegin))
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: SUNA information (PIXEL_BEGIN, PIXEL_END) are missing - NITRATE data set to fill value in ''%c'' profile of SUNA sensor\n', ...
      g_decArgo_floatNum, ...
      a_profSuna.cycleNumber, ...
      a_profSuna.profileNumber, ...
      a_profSuna.direction);
   return
end

% in the first versions of CTS5 floats, the transmitted values of
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

% interpolate/extrapolate the CTD data at the pressures of the MOLAR_NITRATE
% measurements (to take the vertical offset into account)
ctdIntData = compute_interpolated_CTD_measurements( ...
   a_ctdData, a_UV_INTENSITY_NITRATE_pres+sunaVerticalOffset, a_profSuna.direction);

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
tabUvIntensityNitrate = a_UV_INTENSITY_NITRATE(:, pixelBegin-floatPixelBegin+1:pixelBegin-floatPixelBegin+1+(pixelEnd-pixelBegin+1)-1);

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
tempCalNitrate = repmat(tempCalNitrate, size(ctdIntData(:, 2)));
tabPsal = repmat(ctdIntData(:, 3), 1, size(tabUvIntensityNitrate, 2));
tabPres = repmat(ctdIntData(:, 1), 1, size(tabUvIntensityNitrate, 2));

% to test management of NoDef values
% if (size(ctdIntData, 1) == 9)
%    tempo = 1
%    tabUvIntensityNitrate(2, :) = ones(1, size(tabUvIntensityNitrate, 2))*a_UV_INTENSITY_NITRATE_fill_value;
%    tabUvIntensityNitrate(8, :) = ones(1, size(tabUvIntensityNitrate, 2))*a_UV_INTENSITY_NITRATE_fill_value;
%    ctdIntData(4, 1) = a_PRES_fill_value;
%    ctdIntData(6, 2) = a_TEMP_fill_value;
%    ctdIntData(6, 3) = a_PSAL_fill_value;
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
   (ctdIntData(:, 1) == a_PRES_fill_value) | ...
   (ctdIntData(:, 2) == a_TEMP_fill_value) | ...
   (ctdIntData(:, 3) == a_PSAL_fill_value))]);

idNoDef = setdiff([1:size(tabUvIntensityNitrate, 1)], idDef)';

if (~isempty(idNoDef))
   
   tabUvIntensityNitrate = tabUvIntensityNitrate(idNoDef, :);
   tabUvIntensityDarkNitrate = tabUvIntensityDarkNitrate(idNoDef, :);
   tabUvIntensityRefNitrate = tabUvIntensityRefNitrate(idNoDef, :);
   tabESwaNitrate = tabESwaNitrate(idNoDef, :);
   tempCalNitrate = tempCalNitrate(idNoDef);
   tabPsal = tabPsal(idNoDef, :);
   tabPres = tabPres(idNoDef, :);
   ctdData = ctdIntData(idNoDef, :);
   
   % compute NITRATE
   
   % Equation #1
   absorbanceSw = -log10((tabUvIntensityNitrate - tabUvIntensityDarkNitrate) ./ tabUvIntensityRefNitrate);
   
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
   
   tabMolarNitrate = nan(size(tabUvIntensityDarkNitrate, 1), 1);
   tabRmsError = nan(size(tabUvIntensityDarkNitrate, 1), 1);
   a = [tabOpticalWavelengthUv' tabENitrate'];
   nbComplex = 0;
   for idL = 1:length(tabMolarNitrate)
      b = absorbanceCorNitrate(idL, :)';
      if (all(imag(b) == 0))
         mdl = fitlm(double(a), double(b)); % both inputs should be double since R2020b
         tabMolarNitrate(idL) = mdl.Coefficients.Estimate(end);
         rawResiduals = mdl.Residuals.Raw;
         tabRmsError(idL) = sqrt(sum(rawResiduals.*rawResiduals)/size(absorbanceCorNitrate, 2));
      else
         % example: 3902122 #183
         nbComplex = nbComplex + 1;
      end
   end
   if (nbComplex > 0)
      fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d NITRATE values are complex - these values are set to fill value in ''%c'' profile of SUNA sensor\n', ...
         g_decArgo_floatNum, ...
         a_profSuna.cycleNumber, ...
         a_profSuna.profileNumber, ...
         nbComplex, ...
         a_profSuna.direction);
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
   o_rmsError(idNoDef) = tabRmsError;
   
   % replace Inf values with fillValue (ex: 3902122 (183, 0))
   if (any(isinf(o_NITRATE)))
      idToDef = find(isinf(o_NITRATE));
      o_NITRATE(idToDef) = a_NITRATE_fill_value;
      o_rmsError(idToDef) = nan;
      
      fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d NITRATE values are Inf - these values are set to fill value in ''%c'' profile of SUNA sensor\n', ...
         g_decArgo_floatNum, ...
         a_profSuna.cycleNumber, ...
         a_profSuna.profileNumber, ...
         length(idToDef), ...
         a_profSuna.direction);
   end
end

% print processing steps in .csv output file
if (0)
   outputFileName = sprintf('./nitrate_processing_%d_%d_%d_%c.csv', ...
      g_decArgo_floatNum, ...
      a_profSuna.cycleNumber, ...
      a_profSuna.profileNumber, ...
      a_profSuna.direction);
   fidOut = fopen(outputFileName, 'wt');
   if (fidOut ~= -1)
      
      fprintf(fidOut, 'CALIBRATION INFORMATION\n');
      
      fprintf(fidOut, 'TEMP_CAL_NITRATE; %g\n', g_decArgo_calibInfo.SUNA.TEMP_CAL_NITRATE);
      
      dataStr = sprintf('%g;', g_decArgo_calibInfo.SUNA.TabOpticalWavelengthUv);
      fprintf(fidOut, 'OPTICAL_WAVELENGTH_UV; %s\n', dataStr(1:end-1));
      
      dataStr = sprintf('%g;', g_decArgo_calibInfo.SUNA.TabENitrate);
      fprintf(fidOut, 'E_NITRATE; %s\n', dataStr(1:end-1));
      
      dataStr = sprintf('%g;', g_decArgo_calibInfo.SUNA.TabESwaNitrate);
      fprintf(fidOut, 'E_SWA_NITRATE; %s\n', dataStr(1:end-1));
      
      dataStr = sprintf('%g;', g_decArgo_calibInfo.SUNA.TabUvIntensityRefNitrate);
      fprintf(fidOut, 'UV_INTENSITY_REF_NITRATE; %s\n', dataStr(1:end-1));
      
      tabOpticalWavelengthUv = g_decArgo_calibInfo.SUNA.TabOpticalWavelengthUv;
      tabENitrate = g_decArgo_calibInfo.SUNA.TabENitrate;
      tabESwaNitrate = g_decArgo_calibInfo.SUNA.TabESwaNitrate;
      tabUvIntensityRefNitrate = g_decArgo_calibInfo.SUNA.TabUvIntensityRefNitrate;
      tempCalNitrate = g_decArgo_calibInfo.SUNA.TEMP_CAL_NITRATE;
      
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, 'CONFIGURATION INFORMATION\n');
      
      fprintf(fidOut, 'SUNA vertical offset; %g\n', sunaVerticalOffset);
      fprintf(fidOut, 'FLOAT PIXEL BEGIN; %g\n', floatPixelBegin);
      fprintf(fidOut, 'FLOAT PIXEL END; %g\n', floatPixelEnd);
      
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, 'NITRATE PROCESSING\n');
      
      fprintf(fidOut, 'PIXEL BEGIN; %g\n', pixelBegin);
      fprintf(fidOut, 'PIXEL END; %g\n', pixelEnd);
      
      [measLon, measLat] = get_meas_location(a_profSuna.cycleNumber, a_profSuna.profileNumber, a_profSuna);
      rhoOri = potential_density_gsw(a_ctdData(:, 1), a_ctdData(:, 2), a_ctdData(:, 3), 0, measLon, measLat);
      rhoOri = rhoOri/1000;
      
      fprintf(fidOut, 'CTD DATA\n');
      fprintf(fidOut, 'PRES; TEMP; PSAL; RHO\n');
      for idL = 1:size(a_ctdData, 1)
         fprintf(fidOut, '%g; %g; %g; %g\n', a_ctdData(idL, :), rhoOri(idL));
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, 'CTD data at the P level of the SUNA sensor\n');
      fprintf(fidOut, 'PRES; TEMP; PSAL; RHO\n');
      for idL = 1:size(a_ctdData, 1)
         fprintf(fidOut, '%g; %g; %g; %g\n', ctdIntData(idL, :), rho(idL));
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, 'INPUT DATA\n');
      fprintf(fidOut, 'PRES; UV_INTENSITY_DARK_NITRATE; UV_INTENSITY_NITRATE\n');
      for idL = 1:size(a_UV_INTENSITY_NITRATE, 1)
         dataStr = sprintf('%g;', a_UV_INTENSITY_NITRATE(idL, :));
         fprintf(fidOut, '%g; %g; %s\n', ctdIntData(idL, 1), a_UV_INTENSITY_DARK_NITRATE(idL), dataStr(1:end-1));
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, 'USED INPUT DATA\n');
      fprintf(fidOut, 'PRES; UV_INTENSITY_DARK_NITRATE; UV_INTENSITY_NITRATE\n');
      tmp = a_UV_INTENSITY_NITRATE(:, floatPixelBegin-pixelBegin+1:end-(floatPixelEnd-pixelEnd));
      for idL = 1:size(tmp, 1)
         dataStr = sprintf('%g;', tmp(idL, :));
         fprintf(fidOut, '%g; %g; %s\n', ctdIntData(idL, 1), a_UV_INTENSITY_DARK_NITRATE(idL), dataStr(1:end-1));
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, 'EQUATION #1\n');
      fprintf(fidOut, 'PRES; ABSORBANCE_SW\n');
      for idL = 1:size(absorbanceSw, 1)
         dataStr = sprintf('%g;', absorbanceSw(idL, :));
         fprintf(fidOut, '%g; %s\n', ctdIntData(idL, 1), dataStr(1:end-1));
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, 'EQUATION #2\n');
      fprintf(fidOut, 'PRES; E_SWA_INSITU\n');
      for idL = 1:size(eSwaInsitu, 1)
         dataStr = sprintf('%g;', eSwaInsitu(idL, :));
         fprintf(fidOut, '%g; %s\n', ctdIntData(idL, 1), dataStr(1:end-1));
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, 'EQUATION #4\n');
      fprintf(fidOut, 'PRES; ABSORBANCE_COR_NITRATE\n');
      for idL = 1:size(absorbanceCorNitrate, 1)
         dataStr = sprintf('%g;', absorbanceCorNitrate(idL, :));
         fprintf(fidOut, '%g; %s\n', ctdIntData(idL, 1), dataStr(1:end-1));
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, 'EQUATION #5\n');
      fprintf(fidOut, 'PRES; MOLAR_NITRATE\n');
      for idL = 1:size(tabMolarNitrate, 1)
         fprintf(fidOut, '%g; %g\n', ctdIntData(idL, 1), tabMolarNitrate(idL));
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, 'EQUATION #5\n');
      fprintf(fidOut, 'PRES; NITRATE\n');
      for idL = 1:size(o_NITRATE, 1)
         fprintf(fidOut, '%g; %g\n', ctdIntData(idL, 1), o_NITRATE(idL));
      end
      fprintf(fidOut, '\n');
      
      fprintf(fidOut, 'COMPARISON\n');
      fprintf(fidOut, 'PRES; NITRATE FROM SPECTRUM; NITRATE FROM FLOAT; |diff|\n');
      nitrateFromFloat = g_tempoJPR_nitrateFromFloat;
      for idL = 1:size(o_NITRATE, 1)
         fprintf(fidOut, '%g; %g; %g; %g\n', ctdIntData(idL, 1), o_NITRATE(idL), nitrateFromFloat(idL), abs(o_NITRATE(idL)-nitrateFromFloat(idL)));
      end
      fprintf(fidOut, '\n');
      
      fclose(fidOut);
   else
      fprintf('ERROR: Unable to create CSV output file: %s\n', outputFileName);
   end
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
