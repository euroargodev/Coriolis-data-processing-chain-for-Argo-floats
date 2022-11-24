% ------------------------------------------------------------------------------
% Compute the profile quality flag of a given parameter.
%
% SYNTAX :
%  [o_profQc] = compute_profile_quality_flag(a_qcFlags)
%
% INPUT PARAMETERS :
%   a_qcFlags : QC flags of the parameter
%
% OUTPUT PARAMETERS :
%   o_profQc : computed profile quality flag
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/09/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profQc] = compute_profile_quality_flag(a_qcFlags)

% QC flag values
global g_decArgo_qcStrDef;           % ' '
global g_decArgo_qcStrNoQc;          % '0'
global g_decArgo_qcStrGood;          % '1'
global g_decArgo_qcStrProbablyGood;  % '2'
global g_decArgo_qcStrCorrectable;   % '3'
global g_decArgo_qcStrBad;           % '4'
global g_decArgo_qcStrChanged;       % '5'
global g_decArgo_qcStrInterpolated;  % '8'
global g_decArgo_qcStrMissing;       % '9'

% output parameters initialization
o_profQc = g_decArgo_qcStrDef;

if (length(find((a_qcFlags == g_decArgo_qcStrDef) | ...
      (a_qcFlags == g_decArgo_qcStrNoQc) | ...
      (a_qcFlags == g_decArgo_qcStrMissing))) ~= length(a_qcFlags))
   
   % compute the ratio of good data
   nbUsefulLev = length(find((a_qcFlags ~= g_decArgo_qcStrDef) & ...
      (a_qcFlags ~= g_decArgo_qcStrMissing)));
   nbGoodLev = length(find((a_qcFlags == g_decArgo_qcStrGood) | ...
      (a_qcFlags == g_decArgo_qcStrProbablyGood) | ...
      (a_qcFlags == g_decArgo_qcStrChanged) | ...
      (a_qcFlags == g_decArgo_qcStrInterpolated)));
   ratio = 100*nbGoodLev/nbUsefulLev;
   if (ratio == 0)
      o_profQc = 'F';
   elseif (ratio < 25)
      o_profQc = 'E';
   elseif (ratio < 50)
      o_profQc = 'D';
   elseif (ratio < 75)
      o_profQc = 'C';
   elseif (ratio < 100)
      o_profQc = 'B';
   else
      o_profQc = 'A';
   end
end

return
