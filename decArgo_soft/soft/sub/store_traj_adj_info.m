% ------------------------------------------------------------------------------
% Store trajectory adjustment information for NetCDF file.
%
% SYNTAX :
%  store_traj_adj_info(a_adjType, a_cycleNumber, ...
%    a_paramName, a_equation, a_coefficient, a_comment, a_date)
%
% INPUT PARAMETERS :
%   a_adjType     : adjustement type
%   a_cycleNumber : concerned cycle numbers
%   a_paramName   : adjusted parameter
%   a_equation    : adjustement equation
%   a_coefficient : adjustement coefficients
%   a_comment     : adjustement comment
%   a_date        : adjustment date
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/30/2021 - RNU - creation
% ------------------------------------------------------------------------------
function store_traj_adj_info(a_adjType, a_cycleNumber, ...
   a_paramName, a_equation, a_coefficient, a_comment, a_date)

% to store information on adjustments
global g_decArgo_paramTrajAdjInfo;
global g_decArgo_paramTrajAdjId;


idF = [];
if (~isempty(g_decArgo_paramTrajAdjInfo))
   idF = find(([g_decArgo_paramTrajAdjInfo{:, 2}]' == a_adjType) & ...
      (strcmp(g_decArgo_paramTrajAdjInfo(:, 4), a_paramName)) & ...
      (strcmp(g_decArgo_paramTrajAdjInfo(:, 5), a_equation)) & ...
      (strcmp(g_decArgo_paramTrajAdjInfo(:, 6), a_coefficient)) & ...
      (strcmp(g_decArgo_paramTrajAdjInfo(:, 7), a_comment)) & ...
      (strcmp(g_decArgo_paramTrajAdjInfo(:, 8), a_date)));
end
if (isempty(idF))
   g_decArgo_paramTrajAdjInfo = [g_decArgo_paramTrajAdjInfo;
      g_decArgo_paramTrajAdjId a_adjType a_cycleNumber ...
      {a_paramName} {a_equation} {a_coefficient} {a_comment} {a_date}];
   g_decArgo_paramTrajAdjId = g_decArgo_paramTrajAdjId + 1;
else
   cyNumList = unique([g_decArgo_paramTrajAdjInfo{idF, 3} a_cycleNumber]);
   g_decArgo_paramTrajAdjInfo{idF, 3} = cyNumList;
end

return
