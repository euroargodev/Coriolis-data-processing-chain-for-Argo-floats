% ------------------------------------------------------------------------------
% Add 'MTIME' parameter in profiles.
%
% SYNTAX :
%  [o_tabProfiles] = add_mtime_in_profile(a_tabProfiles)
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
%   08/29/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = add_mtime_in_profile(a_tabProfiles)

% output parameters initialization
o_tabProfiles = a_tabProfiles;

% global default values
global g_decArgo_dateDef;
global g_decArgo_qcDef;


% add MTIME parameter into profiles
paramMtime = get_netcdf_param_attributes('MTIME');
paramJuld = get_netcdf_param_attributes('JULD');
for idProf = 1:length(o_tabProfiles)
   
   profStruct = o_tabProfiles(idProf);

   if ((profStruct.date ~= g_decArgo_dateDef) && ...
         (~isempty(profStruct.dates)) && ...
         (any(profStruct.dates ~= paramJuld.fillValue)))

      mtimeData = ones(size(profStruct.data, 1), 1)*paramMtime.fillValue;
      idDated = find(profStruct.dates ~= paramJuld.fillValue);
      mtimeData(idDated) = profStruct.dates(idDated) - profStruct.date;

      profStruct.paramList = [paramMtime profStruct.paramList];
      profStruct.data = cat(2, mtimeData, double(profStruct.data));
      if (~isempty(profStruct.paramNumberWithSubLevels))
         profStruct.paramNumberWithSubLevels = profStruct.paramNumberWithSubLevels + 1;
      end

      if (~isempty(profStruct.dataQc))
         profStruct.dataQc = cat(2, ones(size(profStruct.dataQc, 1), 1)*g_decArgo_qcDef, profStruct.dataQc);
      end

      if (~isempty(profStruct.paramDataMode))
         profStruct.paramDataMode = [' ' profStruct.paramDataMode];
      end

      o_tabProfiles(idProf) = profStruct;
   end
end

return
