% ------------------------------------------------------------------------------
% Get the basic structure to store technical information.
%
% SYNTAX :
%  [o_dataStruct] = get_apx_tech_data_init_struct(a_dataRedundancy)
%
% INPUT PARAMETERS :
%   a_dataRedundancy : redundancy of the information
%
% OUTPUT PARAMETERS :
%   o_dataStruct : technical data initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = get_apx_tech_data_init_struct(a_dataRedundancy)

% output parameters initialization
o_dataStruct = struct( ...
   'dataRed', a_dataRedundancy, ...
   'label', '', ...
   'techId', '', ...
   'value', '', ...
   'cyNum', '' ...
   );

return
