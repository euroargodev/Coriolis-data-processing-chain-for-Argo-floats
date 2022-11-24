% ------------------------------------------------------------------------------
% Interpolate the T and S measurements of a CTD profile at given P levels.
%
% SYNTAX :
%  [o_ctdIntData] = compute_interpolated_CTD_measurements( ...
%    a_ctdMeasData, a_presData, a_extrapFlag)
%
% INPUT PARAMETERS :
%   a_ctdMeasData : CTD profile measurements
%   a_presData    : P levels of T and S measurement interpolation
%   a_extrapFlag  : extrapolated flag (if 1 do the extrapolation for P levels
%                   that are outside the CTD P interval)
%
% OUTPUT PARAMETERS :
%   o_ctdIntData : CTD interpolated data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/02/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ctdIntData] = compute_interpolated_CTD_measurements( ...
   a_ctdMeasData, a_presData, a_extrapFlag)

% output parameters initialization
o_ctdIntData = [];


if (isempty(a_ctdMeasData))
   return;
end

paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramSal = get_netcdf_param_attributes('PSAL');

% get the measurement levels of output data
idNoDefOutput = find((a_presData ~= paramPres.fillValue));

% interpolate the T and S measurements at the output P levels
idNoDefInput = find(~((a_ctdMeasData(:, 1) == paramPres.fillValue) | ...
   (a_ctdMeasData(:, 2) == paramTemp.fillValue) | ...
   (a_ctdMeasData(:, 3) == paramSal.fillValue)));

if (length(idNoDefInput) > 1)
   
   % output parameters initialization
   o_ctdIntData = [ ...
      a_presData ...
      ones(length(a_presData), 1)*paramTemp.fillValue ...
      ones(length(a_presData), 1)*paramSal.fillValue];

   [ctdPresData, idUnique, ~] = unique(a_ctdMeasData(idNoDefInput, 1));
   ctdTempData = a_ctdMeasData(idNoDefInput, 2);
   ctdTempData = ctdTempData(idUnique);
   ctdPsalData = a_ctdMeasData(idNoDefInput, 3);
   ctdPsalData = ctdPsalData(idUnique);
   
   if (a_extrapFlag == 0)
      tempIntData = interp1(ctdPresData, ...
         ctdTempData, ...
         a_presData(idNoDefOutput), 'linear');
      psalIntData = interp1(ctdPresData, ...
         ctdPsalData, ...
         a_presData(idNoDefOutput), 'linear');
   else
      tempIntData = interp1(ctdPresData, ...
         ctdTempData, ...
         a_presData(idNoDefOutput), 'linear', 'extrap');
      psalIntData = interp1(ctdPresData, ...
         ctdPsalData, ...
         a_presData(idNoDefOutput), 'linear', 'extrap');
   end
   
   o_ctdIntData(idNoDefOutput, 2) = tempIntData;
   o_ctdIntData(idNoDefOutput, 3) = psalIntData;
   
elseif ((length(idNoDefInput) == 1) && (length(a_presData) == 1) && ...
      (a_ctdMeasData(idNoDefInput, 1) == a_presData))
   
   o_ctdIntData = a_ctdMeasData;

end

return;
