% ------------------------------------------------------------------------------
% G�n�ration du code kml permettant de cr�er une fl�che repr�sentative d'un
% d�placement.
%
% SYNTAX :
%   [o_kmlStr] = ge_create_arrow(a_lonArrow, a_latArrow, a_description, ...
%                a_curStyle, a_oldStyle, a_timeSpanStart, a_timeSpanEnd)
%
% INPUT PARAMETERS :
%   a_lonArrow, a_latArrow : extr�mit�s du d�placement
%   a_description          : contenu du champ 'description'
%   a_curStyle             : style (pr�d�fini) utilis� pour le d�placement
%                            courant
%   a_oldStyle             : style (pr�d�fini) utilis� pour l'historique du
%                            d�placement
%   a_timeSpanStart        : date de d�but d'affichage du d�placement
%   a_timeSpanEnd          : date de fin d'affichage du d�placement
%
% OUTPUT PARAMETERS :
%   o_kmlStr : code kml g�n�r�
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   21/01/2009 - RNU - creation
% ------------------------------------------------------------------------------
function [o_kmlStr] = ge_create_arrow(a_lonArrow, a_latArrow, a_description, ...
   a_curStyle, a_oldStyle, a_timeSpanStart, a_timeSpanEnd)

o_kmlStr = [];

% demi angle au sommet et hauteur des fl�ches figurant les d�placements
ALPHA_ARROW = 20;
ALPHA_HEIGHT = 0.2;

o_kmlStr = [o_kmlStr, ge_create_line( ...
   a_lonArrow, a_latArrow, ...
   a_description, ...
   '', ...
   a_curStyle, ...
   a_timeSpanStart, a_timeSpanEnd)];
o_kmlStr = [o_kmlStr, ge_create_line( ...
   a_lonArrow, a_latArrow, ...
   a_description, ...
   '', ...
   a_oldStyle, ...
   a_timeSpanStart, '')];

[lonArrowHead latArrowHead] = ge_compute_arrow_head_coords(...
   a_lonArrow(1), a_latArrow(1), ...
   a_lonArrow(2), a_latArrow(2), ALPHA_ARROW, ALPHA_HEIGHT);

lonArrowH(1) = lonArrowHead(1);
lonArrowH(2) = lonArrowHead(3);
latArrowH(1) = latArrowHead(1);
latArrowH(2) = latArrowHead(3);

o_kmlStr = [o_kmlStr, ge_create_line( ...
   lonArrowH, latArrowH, ...
   a_description, ...
   '', ...
   a_curStyle, ...
   a_timeSpanStart, a_timeSpanEnd)];
o_kmlStr = [o_kmlStr, ge_create_line( ...
   lonArrowH, latArrowH, ...
   a_description, ...
   '', ...
   a_oldStyle, ...
   a_timeSpanStart, '')];

lonArrowH(1) = lonArrowHead(2);
lonArrowH(2) = lonArrowHead(3);
latArrowH(1) = latArrowHead(2);
latArrowH(2) = latArrowHead(3);

o_kmlStr = [o_kmlStr, ge_create_line( ...
   lonArrowH, latArrowH, ...
   a_description, ...
   '', ...
   a_curStyle, ...
   a_timeSpanStart, a_timeSpanEnd)];
o_kmlStr = [o_kmlStr, ge_create_line( ...
   lonArrowH, latArrowH, ...
   a_description, ...
   '', ...
   a_oldStyle, ...
   a_timeSpanStart, '')];

return
