% ------------------------------------------------------------------------------
% Retrieve current UTC date and time.
%
% SYNTAX :
%  [o_now] = now_utc
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_now : current UTC date and time
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/15/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_now] = now_utc

o_now = (java.lang.System.currentTimeMillis/8.64e7) + datenum('1970', 'yyyy');

return
