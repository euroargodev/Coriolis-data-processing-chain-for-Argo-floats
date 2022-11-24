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

if (~isempty(a_qcValues))
   o_qcValues = char(max(a_qcValues, repmat(a_newQcValue, size(a_qcValues))));
end

return;
