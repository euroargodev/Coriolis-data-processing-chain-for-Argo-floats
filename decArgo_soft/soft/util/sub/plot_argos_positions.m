% ------------------------------------------------------------------------------
% Plot surface locations.
%
% SYNTAX :
%  [o_legendPlots, o_legendLabels] = plot_argos_positions( ...
%    a_lon1, a_lat1, a_posAcc1, ...
%    a_lon2, a_lat2, a_posAcc2, ...
%    a_lineSpec, a_markerSize, a_legendPlots, a_legendLabels, a_labelTextId)
%
% INPUT PARAMETERS :
%   a_lon          : location longitudes
%   a_lat          : location latitudes
%   a_posAcc       : location accuracies
%   a_lineSpec     : graphic specifications of the locations to plot
%   a_markerSize   : size of the locations markers
%   a_legendPlots  : information for the legend
%   a_legendLabels : labels for the legend
%   a_labelTextId  : text Id to be used for the legend
%
% OUTPUT PARAMETERS :
%   o_legendPlots  : legend elements
%   o_legendLabels : legend labels
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_legendPlots, o_legendLabels] = plot_argos_positions( ...
   a_lon1, a_lat1, a_posAcc1, ...
   a_lon2, a_lat2, a_posAcc2, ...
   a_lineSpec, a_markerSize, a_legendPlots, a_legendLabels, a_labelTextId)

o_legendPlots = a_legendPlots;
o_legendLabels = a_legendLabels;

% labels used in the legend of the plot
switch a_labelTextId
   case 1
      argosPosLabels = [{'Argos pos.'} {'(class 1)'} {'Argos pos.'} ...
         {'(class 2)'} {'Argos pos.'} {'(class 3)'}];
   case 2
      argosPosLabels = [{'Lin. fitted pos.'} {''} {'Lin. fitted pos.'} {''} ...
         {'Lin. fitted pos.'} {''}];
   case 3
      argosPosLabels = [{'Lin&inert. fitted pos.'} {''} ...
         {'Lin&inert. fitted pos.'} {''} {'Lin&inert. fitted pos.'} {''}];
   case 4
      argosPosLabels = [{'Argos pos.'} {'(class 1)'} {'Argos pos.'} ...
         {'(class 2)'} {'Argos pos.'} {'(class 3)'}];
end

for id = 1:2
   if (id == 1)
      lon = a_lon1;
      lat = a_lat1;
      posAcc = a_posAcc1;
   else
      lon = a_lon2;
      lat = a_lat2;
      posAcc = a_posAcc2;
   end

   % plot of the first location
   if (length(lon) > 0)
      firstLat = lat(1);
      firstLon = lon(1);
      firstPosAcc = posAcc(1);

      newLabel = [];
      switch firstPosAcc
         case {'1', '6'}
            plotHdl = m_plot(firstLon, firstLat, char(a_lineSpec(1, 1)), 'Markersize', a_markerSize(1));
            newLabel = [char(argosPosLabels(1)) ' #1 ' char(argosPosLabels(2))];
         case {'2', '7'}
            plotHdl = m_plot(firstLon, firstLat, char(a_lineSpec(1, 2)), 'Markersize', a_markerSize(1));
            newLabel = [char(argosPosLabels(3)) ' #1 ' char(argosPosLabels(4))];
         case {'3', '8', 'G', 'P'}
            plotHdl = m_plot(firstLon, firstLat, char(a_lineSpec(1, 3)), 'Markersize', a_markerSize(1));
            newLabel = [char(argosPosLabels(5)) ' #1 ' char(argosPosLabels(6))];
         case {' '}
            plotHdl = m_plot(firstLon, firstLat, 'ro', 'Markersize', 5);
            newLabel = 'Launch pos.';
      end
      
      if (~isempty(newLabel))
         if (isempty(strmatch(newLabel, o_legendLabels, 'exact')))
            o_legendPlots = [o_legendPlots plotHdl];
            o_legendLabels = [o_legendLabels {newLabel}];
         end
      end
   end

   % plot of the last location
   if (length(lon) > 1)
      lastLat = lat(end);
      lastLon = lon(end);
      lastPosAcc = posAcc(end);

      newLabel = [];
      switch lastPosAcc
         case {'1', '6'}
            plotHdl = m_plot(lastLon, lastLat, char(a_lineSpec(3, 1)), 'Markersize', a_markerSize(3));
            newLabel = [char(argosPosLabels(1)) ' #end ' char(argosPosLabels(2))];
         case {'2', '7'}
            plotHdl = m_plot(lastLon, lastLat, char(a_lineSpec(3, 2)), 'Markersize', a_markerSize(3));
            newLabel = [char(argosPosLabels(3)) ' #end ' char(argosPosLabels(4))];
         case {'3', '8', 'G', 'P'}
            plotHdl = m_plot(lastLon, lastLat, char(a_lineSpec(3, 3)), 'Markersize', a_markerSize(3));
            newLabel = [char(argosPosLabels(5)) ' #end ' char(argosPosLabels(6))];
      end

      if (~isempty(newLabel))
         if (isempty(strmatch(newLabel, o_legendLabels, 'exact')))
            o_legendPlots = [o_legendPlots plotHdl];
            o_legendLabels = [o_legendLabels {newLabel}];
         end
      end
   end

   % plot of the inner locations
   if (length(lon) > 2)
      otherLat = lat(2:end-1);
      otherLon = lon(2:end-1);
      otherPosAcc = posAcc(2:end-1);

      idAcc1 = find((otherPosAcc == '1') | (otherPosAcc == '6'));
      latAcc1 = otherLat(idAcc1);
      lonAcc1 = otherLon(idAcc1);
      plotHdl = m_plot(lonAcc1, latAcc1, char(a_lineSpec(2, 1)), 'Markersize', a_markerSize(2));
      if (~isempty(idAcc1))
         newLabel = [char(argosPosLabels(1)) char(argosPosLabels(2))];
         if (isempty(strmatch(newLabel, o_legendLabels, 'exact')))
            o_legendPlots = [o_legendPlots plotHdl];
            o_legendLabels = [o_legendLabels {newLabel}];
         end
      end

      idAcc2 = find((otherPosAcc == '2') | (otherPosAcc == '7'));
      latAcc2 = otherLat(idAcc2);
      lonAcc2 = otherLon(idAcc2);
      plotHdl = m_plot(lonAcc2, latAcc2, char(a_lineSpec(2, 2)), 'Markersize', a_markerSize(2));
      if (~isempty(idAcc2))
         newLabel = [char(argosPosLabels(3)) char(argosPosLabels(4))];
         if (isempty(strmatch(newLabel, o_legendLabels, 'exact')))
            o_legendPlots = [o_legendPlots plotHdl];
            o_legendLabels = [o_legendLabels {newLabel}];
         end
      end

      idAcc3 = find((otherPosAcc == '3') | (otherPosAcc == '8') | (otherPosAcc == 'G') | (otherPosAcc == 'P'));
      latAcc3 = otherLat(idAcc3);
      lonAcc3 = otherLon(idAcc3);
      plotHdl = m_plot(lonAcc3, latAcc3, char(a_lineSpec(2, 3)), 'Markersize', a_markerSize(2));
      if (~isempty(idAcc3))
         newLabel = [char(argosPosLabels(5)) char(argosPosLabels(6))];
         if (isempty(strmatch(newLabel, o_legendLabels, 'exact')))
            o_legendPlots = [o_legendPlots plotHdl];
            o_legendLabels = [o_legendLabels {newLabel}];
         end
      end
   end
end

return
