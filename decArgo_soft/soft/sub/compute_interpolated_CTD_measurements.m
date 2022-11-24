% ------------------------------------------------------------------------------
% Interpolate the T and S measurements of a CTD profile at given P levels.
%
% SYNTAX :
%  [o_ctdIntData] = compute_interpolated_CTD_measurements( ...
%    a_ctdMeasData, a_presData, a_presData, a_profDir)
%
% INPUT PARAMETERS :
%   a_ctdMeasData : CTD profile measurements
%   a_presData    : P levels of T and S measurement interpolation
%   a_profDir     : profile direction
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
   a_ctdMeasData, a_presData, a_profDir)

% output parameters initialization
o_ctdIntData = [];


if (isempty(a_ctdMeasData))
   return
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

if (~isempty(idNoDefInput))
   
   % get PTS measurements
   ctdPresData = a_ctdMeasData(idNoDefInput, 1);
   ctdTempData = a_ctdMeasData(idNoDefInput, 2);
   ctdPsalData = a_ctdMeasData(idNoDefInput, 3);
   
   % if it is a ascending profile, flip measurements up to down
   %    if (length(find(diff(ctdPresData)<0)) > length(ctdPresData)/2)
   if (a_profDir == 'A')
      ctdPresData = flipud(ctdPresData);
      ctdTempData = flipud(ctdTempData);
      ctdPsalData = flipud(ctdPsalData);
   end
   
   if (length(ctdPresData) > 1)
      
      % consider increasing pressures only (we start the algorithm from the middle
      % of the profile)
      idToDelete = [];
      idStart = fix(length(ctdPresData)/2);
      pMin = ctdPresData(idStart);
      for id = idStart-1:-1:1
         if (ctdPresData(id) >= pMin)
            idToDelete = [idToDelete id];
         else
            pMin = ctdPresData(id);
         end
      end
      pMax = ctdPresData(idStart);
      for id = idStart+1:length(ctdPresData)
         if (ctdPresData(id) <= pMax)
            idToDelete = [idToDelete id];
         else
            pMax = ctdPresData(id);
         end
      end
      
      ctdPresData(idToDelete) = [];
      ctdTempData(idToDelete) = [];
      ctdPsalData(idToDelete) = [];
   end
   
   if (~isempty(ctdPresData))
      
      % duplicate T&S values 10 dbar above the shallowest level
      ctdPresData = [ctdPresData(1)-10; ctdPresData];
      ctdTempData = [ctdTempData(1); ctdTempData];
      ctdPsalData = [ctdPsalData(1); ctdPsalData];
      
      % duplicate T&S values 50 dbar below the deepest level
      ctdPresData = [ctdPresData; ctdPresData(end)+50];
      ctdTempData = [ctdTempData; ctdTempData(end)];
      ctdPsalData = [ctdPsalData; ctdPsalData(end)];
      
      tempIntData = interp1(ctdPresData, ...
         ctdTempData, ...
         a_presData(idNoDefOutput), 'linear');
      psalIntData = interp1(ctdPresData, ...
         ctdPsalData, ...
         a_presData(idNoDefOutput), 'linear');
      
      tempIntData(isnan(tempIntData)) = paramTemp.fillValue;
      psalIntData(isnan(psalIntData)) = paramSal.fillValue;
      
      % output parameters
      o_ctdIntData = [ ...
         a_presData ...
         ones(length(a_presData), 1)*paramTemp.fillValue ...
         ones(length(a_presData), 1)*paramSal.fillValue];
      o_ctdIntData(idNoDefOutput, 2) = tempIntData;
      o_ctdIntData(idNoDefOutput, 3) = psalIntData;
   end
end

return
