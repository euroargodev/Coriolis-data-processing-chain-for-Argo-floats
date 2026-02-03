% ------------------------------------------------------------------------------
% Get the basic structure to store clock offset information.
%
% SYNTAX :
%  [o_dataStruct] = get_clock_offset_prv_ir_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_dataStruct : clock offset initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/09/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = get_clock_offset_prv_ir_init_struct

% output parameters initialization
o_dataStruct = struct( ...
   'cycleNum', [], ...
   'juldUtc', [], ...
   'juldFloat', [], ...
   'clockOffset', [] ...
   );

return
