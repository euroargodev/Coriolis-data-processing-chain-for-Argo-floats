% ------------------------------------------------------------------------------
% Use interpolations of surface locations to fill empty profile locations.
%
% SYNTAX :
%  [o_tabProfiles] = fill_empty_profile_locations_ir_sbd(...
%    a_gpsData, a_tabProfiles)
%
% INPUT PARAMETERS :
%   a_gpsData       : GPS data
%   a_tabProfiles   : input profiles to check
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : checked output profiles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = fill_empty_profile_locations_ir_sbd(...
   a_gpsData, a_tabProfiles)

% output parameters initialization
o_tabProfiles = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% QC flag values (char)
global g_decArgo_qcStrInterpolated;

% global default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;

% maximum time difference (in days) between 2 GPS locations used to replace
% Iridium profile locations by interpolated GPS profile locations
global g_decArgo_maxDelayToReplaceIrLocByInterpolatedGpsLoc;


% update GPS position QC information if needed
if (any((a_gpsData{1} ~= -1) & (a_gpsData{7} == 0)))
   gpsData = update_gps_position_qc_ir_sbd;
else
   gpsData = a_gpsData;
end

% unpack the GPS data
gpsLocCycleNum = gpsData{1};
gpsLocDate = gpsData{4};
gpsLocLon = gpsData{5};
gpsLocLat = gpsData{6};
gpsLocQc = gpsData{7};
      
for idProf = 1:length(a_tabProfiles)
   profile = a_tabProfiles(idProf);
   if ((profile.date ~= g_decArgo_dateDef) && ...
         ((profile.locationLon == g_decArgo_argosLonDef) || ...
         (profile.iridiumLocation == 1)))

      prevLocDate = g_decArgo_dateDef;
      nextLocDate = g_decArgo_dateDef;
      
      % find the previous good GPS location
      idPrev = find((gpsLocDate <= profile.date) & (gpsLocQc == 1));
      if (~isempty(idPrev))
         idPrev = idPrev(end);
         prevLocDate = gpsLocDate(idPrev);
         prevLocLon = gpsLocLon(idPrev);
         prevLocLat = gpsLocLat(idPrev);
      end
      
      % find the next good GPS location
      idNext = find((gpsLocDate >= profile.date) & (gpsLocQc == 1));
      if (~isempty(idNext))
         idNext = idNext(1);
         nextLocDate = gpsLocDate(idNext);
         nextLocLon = gpsLocLon(idNext);
         nextLocLat = gpsLocLat(idNext);
         nextLocCyNum = gpsLocCycleNum(idNext);
      end
      
      % interpolate between the 2 locations
      if ((prevLocDate ~= g_decArgo_dateDef) && (nextLocDate ~= g_decArgo_dateDef) && ...
            ((nextLocDate-prevLocDate) <= g_decArgo_maxDelayToReplaceIrLocByInterpolatedGpsLoc))
         
         % interpolate the locations
         [interpLocLon, interpLocLat] = interpolate_between_2_locations(...
            prevLocDate, prevLocLon, prevLocLat, ...
            nextLocDate, nextLocLon, nextLocLat, ...
            profile.date);
         
         if (~isnan(interpLocLon))
            % assign the interpolated location to the profile
            a_tabProfiles(idProf).locationDate = profile.date;
            a_tabProfiles(idProf).locationLon = interpLocLon;
            a_tabProfiles(idProf).locationLat = interpLocLat;
            a_tabProfiles(idProf).locationQc = g_decArgo_qcStrInterpolated;
            a_tabProfiles(idProf).iridiumLocation = 0;
            a_tabProfiles(idProf).posSystem = 'GPS';
            
            % to update the associated NetCDF file
            if (nextLocCyNum == max(gpsLocCycleNum))
               a_tabProfiles(idProf).updated = 1;
            end
         else
            fprintf('WARNING: Float #%d Cycle #%d: time inconsistency detected while interpolating for profile location processing => profile not located\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum);
         end
      end
   end
end

% output data
o_tabProfiles = a_tabProfiles;

return;
