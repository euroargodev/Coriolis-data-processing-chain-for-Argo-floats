% ------------------------------------------------------------------------------
% Remove unused parameters from Apex APF11 Iridium-SBD float profiles.
%
% SYNTAX :
%  [o_profDo, o_profFlbbCd] = ...
%    remove_parameter_from_profile_apx_apf11_ir(a_profDo, a_profFlbbCd, a_decoderId)
%
% INPUT PARAMETERS :
%   a_profDo     : input O2 data
%   a_profFlbbCd : input FLBB_CD data
%   a_decoderId  : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_profDo     : output O2 data
%   o_profFlbbCd : output FLBB_CD data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/19/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profDo, o_profFlbbCd] = ...
   remove_parameter_from_profile_apx_apf11_ir(a_profDo, a_profFlbbCd, a_decoderId)

% output parameters initialization
o_profDo = a_profDo;
o_profFlbbCd = a_profFlbbCd;


% remove the unused entries of the DO profile
if (~isempty(o_profDo))
   o_profDo.paramList([2 3 5 6 9:11]) = [];
   o_profDo.data(:, [2 3 5 6 9:11]) = [];
   if (~isempty(o_profDo.dataAdj))
      o_profDo.dataAdj(:, [2 3 5 6 9:11]) = [];
   end
end

% remove the unused entries of the FLBBCD profile
if (~isempty(o_profFlbbCd))
   if (ismember(a_decoderId, [1121, 1122, 1123, 1124, 1126, 1127, 1321, 1322, 1323])) % the decoding template differs for decoders before 2.15.0
      o_profFlbbCd.paramList([2:2:8]) = [];
      o_profFlbbCd.data(:, [2:2:8]) = [];
      if (~isempty(o_profFlbbCd.dataAdj))
         o_profFlbbCd.dataAdj(:, [2:2:8]) = [];
      end
   else
      o_profFlbbCd.paramList(5) = [];
      o_profFlbbCd.data(:, 5) = [];
      if (~isempty(o_profFlbbCd.dataAdj))
         o_profFlbbCd.dataAdj(:, 5) = [];
      end
   end
end

return
