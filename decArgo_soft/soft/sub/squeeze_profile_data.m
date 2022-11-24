% ------------------------------------------------------------------------------
% Squeeze profile data (remove levels where all parameters are FillValue).
%
% SYNTAX :
%  [o_ncProfile] = squeeze_profile_data(a_ncProfile)
%
% INPUT PARAMETERS :
%   a_ncProfile : input profile data
%
% OUTPUT PARAMETERS :
%   o_ncProfile : output profile data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncProfile] = squeeze_profile_data(a_ncProfile)

% output parameters initialization
o_ncProfile = a_ncProfile;


if (isempty(o_ncProfile))
   return
end

if (~isempty(o_ncProfile.data))
   
   idDef = 1:size(o_ncProfile.data, 1);
   for idP = 1:length(o_ncProfile.paramList)
      idDef = idDef(find(o_ncProfile.data(idDef, idP) == o_ncProfile.paramList(idP).fillValue));
      if (isempty(idDef))
         break
      end
   end
   
   if (~isempty(idDef))
      o_ncProfile.data(idDef, :) = [];
      if (~isempty(o_ncProfile.dataAdj))
         o_ncProfile.dataAdj(idDef, :) = [];
      end
      if (~isempty(o_ncProfile.data))
         if (~isempty(o_ncProfile.dates))
            o_ncProfile.dates(idDef, :) = [];
            if (~isempty(o_ncProfile.datesAdj))
               o_ncProfile.datesAdj(idDef, :) = [];
            end
         end
      else
         o_ncProfile = [];
      end
   end
end
   
return
