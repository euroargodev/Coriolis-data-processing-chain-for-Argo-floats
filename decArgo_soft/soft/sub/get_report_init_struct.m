% ------------------------------------------------------------------------------
% Get the basic structure to store report information.
%
% SYNTAX :
%  [o_reportStruct] = get_report_init_struct(a_floatNum, a_floatCycleList)
%
% INPUT PARAMETERS :
%   a_floatNum       : float WMO number
%   a_floatCycleList : processed float cycle list
%
% OUTPUT PARAMETERS :
%   o_reportStruct : report initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/12/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_reportStruct] = get_report_init_struct(a_floatNum, a_floatCycleList)

% output parameters initialization
o_reportStruct = struct( ...
   'floatNum', a_floatNum, ...
   'cycleList', a_floatCycleList, ...
   'inputFiles', '' ,...
   'outputMetaFiles', '', ...
   'outputMonoProfFiles', '', ...
   'outputMultiProfFiles', '', ...
   'outputTrajFiles', '', ...
   'outputTechFiles', '', ...
   'outputMetaAuxFiles', '', ...
   'outputMonoProfAuxFiles', '', ...
   'outputTrajAuxFiles', '', ...
   'outputTechAuxFiles', '' ...
   );

return;