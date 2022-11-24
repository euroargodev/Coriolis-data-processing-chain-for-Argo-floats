% ------------------------------------------------------------------------------
% Finalize CTS5 AUX profiles (add 'MTIME' parameter).
%
% SYNTAX :
%  [o_tabProfiles] = finalize_profile_aux_ir_rudics_cts5(a_tabProfiles)
%
% INPUT PARAMETERS :
%   a_tabProfiles : input profile structures
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : output profile structures
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = finalize_profile_aux_ir_rudics_cts5(a_tabProfiles)

% output parameters initialization
o_tabProfiles = [];

% global default values
global g_decArgo_dateDef;


% add MTIME parameter to AUX profiles
paramMtime = get_netcdf_param_attributes('MTIME');
for idProf = 1:length(a_tabProfiles)
   
   profStruct = a_tabProfiles(idProf);
   if (profStruct.sensorNumber > 100)
      
      % sort raw data by date
      if (profStruct.sensorNumber > 1000)
         [profStruct.dates, idSort] = sort(profStruct.dates);
         profStruct.data = profStruct.data(idSort, :);
      end
      
      if (profStruct.date ~= g_decArgo_dateDef)
         mtimeData = profStruct.dates-profStruct.date;
      else
         mtimeData = ones(size(profStruct.dates))*paramMtime.fillValue;
      end
      
      profStruct.paramList = [paramMtime profStruct.paramList];
      profStruct.data = cat(2, mtimeData, double(profStruct.data));
      profStruct.paramNumberWithSubLevels = profStruct.paramNumberWithSubLevels + 1;
      
      a_tabProfiles(idProf) = profStruct;
   end
end

% update output parameters
o_tabProfiles = a_tabProfiles;

return;
