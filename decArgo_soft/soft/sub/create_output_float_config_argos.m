% ------------------------------------------------------------------------------
% Create the final configuration that will be used in the meta.nc file.
%
% SYNTAX :
%  [o_ncConfig] = create_output_float_config_argos(a_decArgoConfParamNames, a_ncConfParamNames)
%
% INPUT PARAMETERS :
% a_decArgoConfParamNames : internal configuration parameter names
% a_ncConfParamNames      : NetCDF configuration parameter names
%
% OUTPUT PARAMETERS :
% o_ncConfig : NetCDF configuration
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/10/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncConfig] = create_output_float_config_argos(a_decArgoConfParamNames, a_ncConfParamNames)

% output parameters initialization
o_ncConfig = [];

% float configuration
global g_decArgo_floatConfig;

% current float WMO number
global g_decArgo_floatNum;


% current configuration
finalConfigNum = [];
finalConfigName = [];
finalConfigValue = [];
if (~isempty(g_decArgo_floatConfig))
   finalConfigNum = g_decArgo_floatConfig.NUMBER;
   finalConfigName = g_decArgo_floatConfig.NAMES;
   finalConfigValue = g_decArgo_floatConfig.VALUES;
end

% delete the unused configuration parameters
idDel = [];
for idL = 1:size(finalConfigValue, 1)
   if (sum(isnan(finalConfigValue(idL, :))) == size(finalConfigValue, 2))
      idDel = [idDel; idL];
   end
end
finalConfigName(idDel) = [];
finalConfigValue(idDel, :) = [];

% convert decoder names into NetCDF ones
if (~isempty(a_decArgoConfParamNames))
   idDel = [];
   for idConfParam = 1:length(finalConfigName)
      idFUs = strfind(finalConfigName{idConfParam}, '_');
      idF = find(strcmp(finalConfigName{idConfParam}(1:idFUs(2)-1), a_decArgoConfParamNames) == 1);
      if (~isempty(idF))
         finalConfigName{idConfParam} = a_ncConfParamNames{idF};
      else
         % some of the managed parameters are not saved in the meta.nc file
         idDel = [idDel; idConfParam];
         %          fprintf('DEC_INFO: Float #%d: Cannot convert configuration param name :''%s'' into NetCDF one\n', ...
         %             g_decArgo_floatNum, ...
         %             finalConfigName{idConfParam});
      end
   end
   finalConfigName(idDel) = [];
   finalConfigValue(idDel, :) = [];
   
   % output data
   o_ncConfig.NUMBER = finalConfigNum;
   o_ncConfig.NAMES = finalConfigName;
   o_ncConfig.VALUES = finalConfigValue;
end

return;
