% ------------------------------------------------------------------------------
% Set one QC value to a set of existing ones.
%
% SYNTAX :
%  [o_qcValues] = set_qc(a_qcValues, a_newQcValue)
%
% INPUT PARAMETERS :
%   a_qcValues   : existing set on QC values
%   a_newQcValue : QC value
%
% OUTPUT PARAMETERS :
%   o_qcValues : resulting set on QC values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_qcValues] = set_qc(a_qcValues, a_newQcValue)

o_qcValues = a_qcValues;

% QC flag values (char)
global g_decArgo_qcStrDef;
global g_decArgo_qcStrNoQc;
global g_decArgo_qcStrGood;
global g_decArgo_qcStrProbablyGood;
global g_decArgo_qcStrCorrectable;
global g_decArgo_qcStrBad;


if (~isempty(a_qcValues))
   id1 = find(ismember(a_qcValues, [ ...
      g_decArgo_qcStrDef ...
      g_decArgo_qcStrNoQc ...
      g_decArgo_qcStrGood ...
      g_decArgo_qcStrProbablyGood ...
      g_decArgo_qcStrCorrectable ...
      g_decArgo_qcStrBad]));
   o_qcValues(id1) = char(max(a_qcValues(id1), repmat(a_newQcValue, size(id1))));
   id2 = setdiff(1:length(a_qcValues), id1);
   o_qcValues(id2) = repmat(a_newQcValue, size(id2));
end

return;
