% ------------------------------------------------------------------------------
% Get the basic structure to store dated measurements.
%
% SYNTAX :
%  [o_datedMeasStruct] = get_dated_meas_init_struct(a_cycleNum, a_profNum, a_phaseNum)
%
% INPUT PARAMETERS :
%   a_cycleNum : cycle number
%   a_profNum  : profile number
%   a_phaseNum : phase number
%
% OUTPUT PARAMETERS :
%   o_datedMeasStruct : initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/06/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_datedMeasStruct] = get_dated_meas_init_struct(a_cycleNum, a_profNum, a_phaseNum)

% output parameters initialization
o_datedMeasStruct = struct( ...
   'cycleNumber', a_cycleNum, ...
   'profileNumber', a_profNum, ...
   'phaseNumber', a_phaseNum, ...
   'paramList', [], ...
   'paramNumberWithSubLevels', [], ... % position, in the paramList of the parameters with a sublevel
   'paramNumberOfSubLevels', [], ... % number of sublevels for the concerned parameter
   'data', [], ...
   'ptsForDoxy', [], ... % to store PTS data used to compute DOXY
   'dateList', [], ...
   'dates', [], ...
   'datesAdj', [], ...
   'sensorNumber', -1);

return
