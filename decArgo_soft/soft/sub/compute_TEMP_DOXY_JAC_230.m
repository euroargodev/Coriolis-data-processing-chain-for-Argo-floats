% ------------------------------------------------------------------------------
% Compute TEMP_DOXY from TEMP_COUNT_DOXY provided by AROD_FT sensor.
%
% SYNTAX :
% [o_tempDoxyValues] = compute_TEMP_DOXY_JAC_230(o_tempCountDoxyValues)
%
% INPUT PARAMETERS :
%   o_tempCountDoxyValues : input o_tempCountDoxyValues optode data
%
% OUTPUT PARAMETERS :
%   o_tempDoxyValues : output TEMP_DOXY data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/09/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tempDoxyValues] = compute_TEMP_DOXY_JAC_230(o_tempCountDoxyValues)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_tempDoxyCountsDef;

% arrays to store calibration information
global g_decArgo_calibInfo;

% output parameters initialization
o_tempDoxyValues = ones(length(o_tempCountDoxyValues), 1)*g_decArgo_tempDoxyCountsDef;


if (isempty(o_tempCountDoxyValues))
   return
end

% get calibration information
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing - TEMP_DOXY data set to fill value\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif ((isfield(g_decArgo_calibInfo, 'OPTODE')) && (isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef')))
   tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
   % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 7 7
   if (~isempty(find((size(tabDoxyCoef) == [7 7]) ~= 1, 1)))
      fprintf('ERROR: Float #%d Cycle #%d: DOXY calibration coefficients are inconsistent - TEMP_DOXY data set to fill value\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   end
else
   fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing - TEMP_DOXY data set to fill value\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
end

idDef = find(o_tempCountDoxyValues == g_decArgo_tempDoxyCountsDef);
idNoDef = setdiff(1:length(o_tempCountDoxyValues), idDef);

if (~isempty(idNoDef))
   
   tempDoxyCoef = tabDoxyCoef(3, 1:6);
   if (any(isnan(tempDoxyCoef)))
      fprintf('WARNING: Float #%d Cycle #%d: TEMP_DOXY calibration coefficients are missing - TEMP_DOXY data set to fill value\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   end

   tempCountDoxyValues = o_tempCountDoxyValues(idNoDef);

   tempDoxyValues = tempCountDoxyValues.*(tempCountDoxyValues.*(tempCountDoxyValues.*( ...
      tempCountDoxyValues.*(tempCountDoxyValues.*tempDoxyCoef(6) + tempDoxyCoef(5)) + ...
      tempDoxyCoef(4)) + tempDoxyCoef(3)) + tempDoxyCoef(2)) + tempDoxyCoef(1);

   o_tempDoxyValues(idNoDef) = tempDoxyValues;
end

return
