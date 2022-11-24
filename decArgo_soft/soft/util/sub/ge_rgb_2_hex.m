% ------------------------------------------------------------------------------
% Conversion hexa d'une couleur donnée en RGB pour affichage dans GE.
%
% SYNTAX :
%   [o_color] = ge_rgb_2_hex(a_red, a_green, a_blue)
%
% INPUT PARAMETERS :
%   a_red   : valeur du rouge [0..1]
%   a_green : valeur du vert [0..1]
%   a_blue  : valeur du bleu [0..1]
%
% OUTPUT PARAMETERS :
%   o_color : valeur hexa de la couleur souhaitée
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/01/2009 - RNU - creation
% ------------------------------------------------------------------------------
function [o_color] = ge_rgb_2_hex(a_red, a_green, a_blue)

o_color = '000000';

hexR = dec2hex(round(a_red*255));
hexG = dec2hex(round(a_green*255));
hexB = dec2hex(round(a_blue*255));

LR = length(hexR);
LG = length(hexG);
LB = length(hexB);

o_color(7-LR:6) = hexR;
o_color(5-LG:4) = hexG;
o_color(3-LB:2) = hexB;

return
