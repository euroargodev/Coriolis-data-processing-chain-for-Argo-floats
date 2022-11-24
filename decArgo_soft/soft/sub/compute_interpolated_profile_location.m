% ------------------------------------------------------------------------------
% Compute a profile location using existing good locations of the surafce
% trajectory.
%
% SYNTAX :
%  [o_profLocDate, o_profLocLon, o_profLocLat] = ...
%    compute_interpolated_profile_location(a_floatSurfData, a_cycleNum, a_profDate)
%
% INPUT PARAMETERS :
%   a_floatSurfData : surface data structure
%   a_cycleNum      : reference cycle number
%   a_profDate      : profile date
%
% OUTPUT PARAMETERS :
%   o_profLocDate : profile location date (== a_profDate)
%   o_profLocLon  : profile extrapolated longitude
%   o_profLocLat  : profile extrapolated latitude
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/03/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profLocDate, o_profLocLon, o_profLocLat] = ...
   compute_interpolated_profile_location(a_floatSurfData, a_cycleNum, a_profDate)

% output parameters initialization
o_profLocDate = [];
o_profLocLon = [];
o_profLocLat = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;

% QC flag values (char)
global g_decArgo_qcStrGood;


% find a good location in the previous cycles
prevLocDate = g_decArgo_dateDef;
prevLocLon = g_decArgo_argosLonDef;
prevLocLat = g_decArgo_argosLatDef;

% get the existing previous cycles
idPrevCycles = find(a_floatSurfData.cycleNumbers < a_cycleNum);
if (~isempty(idPrevCycles))
   prevCycles = sort(a_floatSurfData.cycleNumbers(idPrevCycles), 'descend');
   for id = 1:length(prevCycles)
      
      idCy = find(a_floatSurfData.cycleNumbers == prevCycles(id));
      
      if (~isempty(a_floatSurfData.cycleData(idCy).argosLocDate))
         locDate = a_floatSurfData.cycleData(idCy).argosLocDate;
         locLon = a_floatSurfData.cycleData(idCy).argosLocLon;
         locLat = a_floatSurfData.cycleData(idCy).argosLocLat;
         locQc = a_floatSurfData.cycleData(idCy).argosLocQc;
         
         idGoodLoc = find(locQc == g_decArgo_qcStrGood);
         if (~isempty(idGoodLoc))
            prevLocDate = locDate(idGoodLoc(end));
            prevLocLon = locLon(idGoodLoc(end));
            prevLocLat = locLat(idGoodLoc(end));
         end
      end
      
      if (prevLocDate ~= g_decArgo_dateDef)
         break;
      end
   end
end

if (prevLocDate == g_decArgo_dateDef)
   % use the launch date and location
   prevLocDate = a_floatSurfData.launchDate;
   prevLocLon = a_floatSurfData.launchLon;
   prevLocLat = a_floatSurfData.launchLat;
end

if (prevLocDate ~= g_decArgo_dateDef)
   
   % find a good location in the current cycle
   curLocDate = g_decArgo_dateDef;
   curLocLon = g_decArgo_argosLonDef;
   curLocLat = g_decArgo_argosLatDef;

   % retrieve the first good location of the current cycle
   idCy = find(a_floatSurfData.cycleNumbers == a_cycleNum);
   
   if (~isempty(a_floatSurfData.cycleData(idCy).argosLocDate))
      locDate = a_floatSurfData.cycleData(idCy).argosLocDate;
      locLon = a_floatSurfData.cycleData(idCy).argosLocLon;
      locLat = a_floatSurfData.cycleData(idCy).argosLocLat;
      locQc = a_floatSurfData.cycleData(idCy).argosLocQc;
      
      idGoodLoc = find(locQc == g_decArgo_qcStrGood);
      if (~isempty(idGoodLoc))
         curLocDate = locDate(idGoodLoc(1));
         curLocLon = locLon(idGoodLoc(1));
         curLocLat = locLat(idGoodLoc(1));
      end
   end
   
   if (curLocDate ~= g_decArgo_dateDef)
      % interpolate the positions
      o_profLocDate = a_profDate;
      o_profLocLon = interp1q([prevLocDate; curLocDate], [prevLocLon; curLocLon], a_profDate);
      o_profLocLat = interp1q([prevLocDate; curLocDate], [prevLocLat; curLocLat], a_profDate);
      
      if (isnan(o_profLocLon))
         o_profLocDate = [];
         o_profLocLon = [];
         o_profLocLat = [];
         
         fprintf('WARNING: Float #%d Cycle #%d: time inconsistency detected while interpolating for profile location processing => profile not located\n', ...
            a_cycleNum, ...
            g_decArgo_cycleNum);
      end
   end
end

return;
