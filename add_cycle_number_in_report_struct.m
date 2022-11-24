% ------------------------------------------------------------------------------
% Add a cycle number into the report information structure.
%
% SYNTAX :
%  [o_reportStruct] = add_cycle_number_in_report_struct(a_reportStruct, a_cycleNumber)
%
% INPUT PARAMETERS :
%   a_reportStruct : input report structure
%   a_cycleNumber  : cycle number
%
% OUTPUT PARAMETERS :
%   o_reportStruct : output report structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/03/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_reportStruct] = add_cycle_number_in_report_struct(a_reportStruct, a_cycleNumber)

if (~isempty(a_reportStruct.cycleList))
   a_reportStruct.cycleList = [a_reportStruct.cycleList a_cycleNumber];
else
   a_reportStruct.cycleList = a_cycleNumber;
end

o_reportStruct = a_reportStruct;

return
