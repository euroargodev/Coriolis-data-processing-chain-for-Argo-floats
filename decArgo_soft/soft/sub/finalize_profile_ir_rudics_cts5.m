% ------------------------------------------------------------------------------
% Finalize CTS5 profiles (add 'MTIME' parameter).
%
% SYNTAX :
%  [o_tabProfiles] = finalize_profile_ir_rudics_cts5(a_tabProfiles)
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
function [o_tabProfiles] = finalize_profile_ir_rudics_cts5(a_tabProfiles)

% output parameters initialization
o_tabProfiles = [];

% global default values
global g_decArgo_dateDef;
global g_decArgo_qcDef;


% add MTIME parameter to profiles
paramMtime = get_netcdf_param_attributes('MTIME');
for idProf = 1:length(a_tabProfiles)
   
   profStruct = a_tabProfiles(idProf);
   
   % sort raw data by date
   if (profStruct.sensorNumber > 1000)
      [profStruct.dates, idSort] = sort(profStruct.dates);
      profStruct.data = profStruct.data(idSort, :);
   end
   
   if (profStruct.date ~= g_decArgo_dateDef)
      mtimeData = profStruct.dates-profStruct.date;
   else
      mtimeData = ones(size(profStruct.data, 1), 1)*paramMtime.fillValue;
   end
   profStruct.paramList = [paramMtime profStruct.paramList];
   profStruct.data = cat(2, mtimeData, double(profStruct.data));
   profStruct.paramNumberWithSubLevels = profStruct.paramNumberWithSubLevels + 1;
   
   if (~isempty(profStruct.dataQc))
      profStruct.dataQc = cat(2, ones(size(profStruct.dataQc, 1), 1)*g_decArgo_qcDef, profStruct.dataQc);
   end
   
   if (~isempty(profStruct.dataAdj))
      if (profStruct.date ~= g_decArgo_dateDef)
         if (~isempty(profStruct.datesAdj))
            mtimeDataAdj = profStruct.datesAdj-profStruct.date;
         elseif (~isempty(profStruct.dates))
            mtimeDataAdj = profStruct.dates-profStruct.date;
         else
            mtimeDataAdj = ones(size(profStruct.dataAdj, 1), 1)*paramMtime.fillValue;
         end
      else
         mtimeDataAdj = ones(size(profStruct.dataAdj, 1), 1)*paramMtime.fillValue;
      end
      profStruct.dataAdj = cat(2, mtimeDataAdj, double(profStruct.dataAdj));
      
      if (~isempty(profStruct.dataAdjQc))
         profStruct.dataAdjQc = cat(2, ones(size(profStruct.dataAdjQc, 1), 1)*g_decArgo_qcDef, profStruct.dataAdjQc);
      end
   end
   
   a_tabProfiles(idProf) = profStruct;
end

% update output parameters
o_tabProfiles = a_tabProfiles;

return;
