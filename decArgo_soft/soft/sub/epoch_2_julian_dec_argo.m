% ------------------------------------------------------------------------------
% Convert an EPOCH (1970) date to a julian 1950 one.
%
% SYNTAX :
%   [o_julDay] = epoch_2_julian_dec_argo(a_epoch)
%
% INPUT PARAMETERS :
%   a_epoch : EPOCH 1970 date
%
% OUTPUT PARAMETERS :
%   o_julDay : julian 1950 date
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_julDay] = epoch_2_julian_dec_argo(a_epoch)

% reference date (01/01/1970)
global g_decArgo_janFirst1970InJulD;

o_julDay = g_decArgo_janFirst1970InJulD + double(a_epoch)/86400;

return
