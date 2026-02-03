% ------------------------------------------------------------------------------
% Retrieve the treatment type of the depth zone associated to a given pressure
% value.
%
% SYNTAX :
% [o_treatType] = config_get_treatment_type_ir_rudics_cts5( ...
%   a_cycleNum, a_profNum, a_presValue)
%
% INPUT PARAMETERS :
%   a_sensorNum : sensor number
%   a_cycleNum  : cycle number
%   a_presValue : pressure value
%
% OUTPUT PARAMETERS :
%   o_treatType : treatment type
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/26/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_treatType] = config_get_treatment_type_ir_rudics_cts5( ...
   a_cycleNum, a_profNum, a_presValue)
   
% output parameters initialization
o_treatType = '';


[configNames, configValues] = get_float_config_ir_rudics_sbd2(a_cycleNum, a_profNum);
if (~isempty(configNames))

   % find the depth zone of the PRES value
   depthZoneNum = -1;
   for id = 1:4
      % zone threshold
      zoneThreshold = get_config_value(sprintf('CONFIG_APMT_SENSOR_01_P%02d', ...
         46+id-1), configNames, configValues);
      if (a_presValue <= zoneThreshold)
         depthZoneNum = id;
         break
      end
   end
   if (depthZoneNum == -1)
      depthZoneNum = 5;
   end

   % retrieve treatment type for this depth zone
   o_treatType = get_config_value(sprintf('CONFIG_APMT_SENSOR_01_P%02d', ...
      7+(depthZoneNum-1)*9), configNames, configValues);
end

return
