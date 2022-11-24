% ------------------------------------------------------------------------------
% Remove timestamp information from Apex APF11 Iridium-SBD float profiles.
%
% SYNTAX :
%  [o_profDo] = ...
%    remove_temporary_dates_from_profile_apx_apf11_ir(a_profDo)
%
% INPUT PARAMETERS :
%   a_profDo     : input O2 data
%
% OUTPUT PARAMETERS :
%   o_profDo     : output O2 data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/29/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profDo] = ...
   remove_temporary_dates_from_profile_apx_apf11_ir(a_profDo)

% output parameters initialization
o_profDo = a_profDo;


% remove the unused entries of the DO profile
if (~isempty(o_profDo))
   if (o_profDo.temporaryDates == 1)
      paramJuld = get_netcdf_param_attributes('JULD');
      o_profDo.dates = ones(size(o_profDo.dates))*paramJuld.fillValue;
      o_profDo.temporaryDates = 0;
   end
end

return
