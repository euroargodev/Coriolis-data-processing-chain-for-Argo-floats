% ------------------------------------------------------------------------------
% Génération des coordonnées d'une flêche utilisée pour figurer un déplacement.
%
% SYNTAX :
%   [o_lonArrowHead o_latArrowHead] = ge_compute_arrow_head_coords( ...
%      a_lon1, a_lat1, a_lon2, a_lat2, a_alphaArrow, a_heightArrow)
%
% INPUT PARAMETERS :
%   a_lon1, a_lat1 : coordonnées du point début du déplacement
%   a_lon2, a_lat2 : coordonnées du point fin du déplacement
%   a_alphaArrow   : valeur du demi angle de la flêche
%   a_heightArrow  : valeur de la hauteur de la flêche
%
% OUTPUT PARAMETERS :
%   o_lonArrowHead, o_latArrowHead : coordonnées des segments constituant la
%                                    flêche
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/01/2009 - RNU - creation
% ------------------------------------------------------------------------------
function [o_lonArrowHead o_latArrowHead] = ge_compute_arrow_head_coords( ...
   a_lon1, a_lat1, a_lon2, a_lat2, a_alphaArrow, a_heightArrow)

if (abs(a_lon2-a_lon1) > 180)
   if (a_lon1 < 0)
      a_lon1 = a_lon1 + 360;
   end
   if (a_lon2 < 0)
      a_lon2 = a_lon2 + 360;
   end
end

dArrow = a_heightArrow * sind(a_alphaArrow);

xPos1 = a_lon1;
yPos1 = a_lat1;

xPos2 = (a_lon2 - xPos1) * cosd(a_lat1);
yPos2 = (a_lat2 - yPos1);

if ((xPos2 == 0) && (yPos2 == 0))
   alpha = 0;
elseif (xPos2 == 0)
   if (yPos2 > 0)
      alpha = 90;
   else
      alpha = -90;
   end
else
   alpha = rad2deg(atan2(yPos2, xPos2));
end

dx = dArrow * cosd(alpha+a_alphaArrow);
dy = dArrow * sind(alpha+a_alphaArrow);
xPoint1 = xPos2 - dx;
yPoint1 = yPos2 - dy;

dx = dArrow * cosd(alpha-a_alphaArrow);
dy = dArrow * sind(alpha-a_alphaArrow);
xPoint2 = xPos2 - dx;
yPoint2 = yPos2 - dy;

lonPoint1 = (xPoint1/cosd(a_lat1)) + xPos1;
latPoint1 = yPoint1 + yPos1;

lonPoint2 = (xPoint2/cosd(a_lat1)) + xPos1;
latPoint2 = yPoint2 + yPos1;

o_lonArrowHead(1) = lonPoint1;
o_latArrowHead(1) = latPoint1;

o_lonArrowHead(2) = lonPoint2;
o_latArrowHead(2) = latPoint2;

o_lonArrowHead(3) = a_lon2;
o_latArrowHead(3) = a_lat2;

id = find(o_lonArrowHead > 180);
o_lonArrowHead(id) = o_lonArrowHead(id) -360;

return
