% ------------------------------------------------------------------------------
% Get the basic structure to store Provor PFV2 tech event data.
%
% SYNTAX :
%  [o_dataStruct] = get_pfv2_tech_event_data_init_struct(a_evtNum)
%
% INPUT PARAMETERS :
%   a_evtNum : event number
%
% OUTPUT PARAMETERS :
%   o_dataStruct : data initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/07/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = get_pfv2_tech_event_data_init_struct(a_evtNum)

% output parameters initialization
o_dataStruct = struct( ...
   'techId', a_evtNum, ...
   'class', '', ...
   'label', '', ...
   'valueStr', '' ...
   );

return
