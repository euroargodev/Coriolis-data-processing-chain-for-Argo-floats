% ------------------------------------------------------------------------------
% Merge N_MEASUREMENT records of CTS5 floats.
%
% SYNTAX :
%  [o_tabTrajNMeas] = merge_n_measurement_data_cts5(o_tabTrajNMeasMain, o_tabTrajNMeasAdd)
%
% INPUT PARAMETERS :
%   o_tabTrajNMeasMain : N_MEASUREMENT main record
%   o_tabTrajNMeasAdd  : N_MEASUREMENT records to be merged
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas : resulting N_MEASUREMENT records
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas] = merge_n_measurement_data_cts5(o_tabTrajNMeasMain, o_tabTrajNMeasAdd)
               
% output parameters initialization
o_tabTrajNMeas = o_tabTrajNMeasMain;


% collect the measurement codes to update
inputMeasCodeList = unique([o_tabTrajNMeasAdd.tabMeas.measCode]);

% remove these measurement codes in output arrays
currentMeasCodeList = [o_tabTrajNMeas.tabMeas.measCode];
idDel = find(ismember(currentMeasCodeList, inputMeasCodeList));
o_tabTrajNMeas.tabMeas(idDel) = [];

% add new measurement codes
o_tabTrajNMeas.tabMeas = [o_tabTrajNMeas.tabMeas; o_tabTrajNMeasAdd.tabMeas];

return
