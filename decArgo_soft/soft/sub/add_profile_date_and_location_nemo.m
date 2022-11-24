% ------------------------------------------------------------------------------
% Add the date and location of a profile.
%
% SYNTAX :
%  [o_profile] = add_profile_date_and_location_nemo( ...
%    a_profile, a_cycleTimeData, a_gpsData, a_iridiumData)
%
% INPUT PARAMETERS :
%   a_profile       : output profiles
%   a_cycleTimeData : cycle time data structure
%   a_gpsData       : GPS fix information
%   a_iridiumData   : Iridium fix information
%
% OUTPUT PARAMETERS :
%   o_profile : output profiles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profile] = add_profile_date_and_location_nemo( ...
   a_profile, a_cycleTimeData, a_gpsData, a_iridiumData)

% output parameters initialization
o_profile = a_profile;

% global default values
global g_decArgo_dateDef;

% current float WMO number
global g_decArgo_floatNum;

% QC flag values (char)
global g_decArgo_qcStrInterpolated;


% unpack the GPS input data
a_gpsLocCycleNum = a_gpsData{1};
a_gpsLocDate = a_gpsData{4};
a_gpsLocLon = a_gpsData{5};
a_gpsLocLat = a_gpsData{6};
a_gpsLocQc = a_gpsData{7};

% add profile date

% from misc cycle timings
if (~isempty(a_cycleTimeData.surfaceStartAdjDate))
   o_profile.date = a_cycleTimeData.surfaceStartAdjDate;
elseif (~isempty(a_cycleTimeData.surfaceStartDate))
   o_profile.date = a_cycleTimeData.surfaceStartDate;
elseif (~isempty(a_cycleTimeData.ascentEndAdjDate))
   o_profile.date = a_cycleTimeData.ascentEndAdjDate;
elseif (~isempty(a_cycleTimeData.ascentEndDate))
   o_profile.date = a_cycleTimeData.ascentEndDate;
end

% from first GPS or Iridium date
if (o_profile.date == g_decArgo_dateDef)
   dates = [a_cycleTimeData.gpsDate a_cycleTimeData.iridiumDate];
   if (~isempty(dates))
      o_profile.date = min(dates);
   end
end

% from last profile measurement date
if (o_profile.date == g_decArgo_dateDef)
   if (~isempty(o_profile.dateList))
      if (~isempty(o_profile.datesAdj) && any(o_profile.datesAdj ~= o_profile.dateList.fillValue))
         dates = o_profile.datesAdj;
      elseif (~isempty(o_profile.dates) && any(o_profile.dates ~= o_profile.dateList.fillValue))
         dates = o_profile.dates;
      end
      dates(find(dates == o_profile.dateList.fillValue)) = [];
      if (~isempty(dates))
         o_profile.date = max(dates);
      end
   end
end

% set MTIME values
idMtime = find(strcmp({o_profile.paramList.name}, 'MTIME') == 1, 1);
if (~isempty(idMtime))
   paramMtime = o_profile.paramList(idMtime);
   if (o_profile.date ~= g_decArgo_dateDef)
      % we compute MTIME as JULD-prof.date
      idNoDef = find(o_profile.data(:, idMtime) ~= paramMtime.fillValue);
      o_profile.data(idNoDef, idMtime) = o_profile.data(idNoDef, idMtime) - o_profile.date;
   else
      % we are not able to compute MTIME
      o_profile.data(:, idMtime) = ones(size(o_profile.data, 1), 1)*paramMtime.fillValue;
   end
end

% add profile location

% select the GPS data to use
idPosToUse = find((a_gpsLocCycleNum == o_profile.cycleNumber) & (a_gpsLocQc == 1));
if (~isempty(idPosToUse))
   % a GPS fix exists
   [~, idMin] = min(a_gpsLocDate(idPosToUse));
   idPosToUse = idPosToUse(idMin);
   o_profile.locationDate = a_gpsLocDate(idPosToUse);
   o_profile.locationLon = a_gpsLocLon(idPosToUse);
   o_profile.locationLat = a_gpsLocLat(idPosToUse);
   o_profile.locationQc = num2str(a_gpsLocQc(idPosToUse));
   
   % positioning system
   o_profile.posSystem = 'GPS';
else
   % no GPS fix exists
   
   if (o_profile.date ~= g_decArgo_dateDef)
      
      % we must interpolate between the existing GPS locations
      prevLocDate = g_decArgo_dateDef;
      nextLocDate = g_decArgo_dateDef;
      
      % find the previous GPS location
      idPrev = find(a_gpsLocDate <= o_profile.date);
      if (~isempty(idPrev))
         idPrev = idPrev(end);
         prevLocDate = a_gpsLocDate(idPrev);
         prevLocLon = a_gpsLocLon(idPrev);
         prevLocLat = a_gpsLocLat(idPrev);
      end
      
      % find the next GPS location
      idNext = find(a_gpsLocDate >= o_profile.date);
      if (~isempty(idNext))
         idNext = idNext(1);
         nextLocDate = a_gpsLocDate(idNext);
         nextLocLon = a_gpsLocLon(idNext);
         nextLocLat = a_gpsLocLat(idNext);
      end
      
      % interpolate between the 2 locations
      if ((prevLocDate ~= g_decArgo_dateDef) && (nextLocDate ~= g_decArgo_dateDef))
         
         % interpolate the locations
         [interpLocLon, interpLocLat] = interpolate_between_2_locations(...
            prevLocDate, prevLocLon, prevLocLat, ...
            nextLocDate, nextLocLon, nextLocLat, ...
            o_profile.date);
         
         if (~isnan(interpLocLon))
            % assign the interpolated location to the profile
            o_profile.locationDate = o_profile.date;
            o_profile.locationLon = interpLocLon;
            o_profile.locationLat = interpLocLat;
            o_profile.locationQc = g_decArgo_qcStrInterpolated;
            
            % positioning system
            o_profile.posSystem = 'GPS';
         else
            fprintf('WARNING: Float #%d Cycle #%d: time inconsistency detected while interpolating for profile location processing - profile not located\n', ...
               g_decArgo_floatNum, ...
               o_profile.cycleNumber);
         end
      end
   end
end

% we have not been able to set a location for the profile, we will use the
% Iridium locations
if (o_profile.locationDate == g_decArgo_dateDef)
   [locDate, locLon, locLat, locQc, lastCycleFlag] = ...
      compute_profile_location_from_iridium_locations_ir_sbd(a_iridiumData, o_profile.cycleNumber);
   if (~isempty(locDate))
      % assign the averaged Iridium location to the profile
      o_profile.locationDate = locDate;
      o_profile.locationLon = locLon;
      o_profile.locationLat = locLat;
      o_profile.locationQc = locQc;
      o_profile.iridiumLocation = 1;
      
      % positioning system
      o_profile.posSystem = 'IRIDIUM';
      
      % if the current cycle is the last received cycle, the location could
      % have been updated (if the last cycle data have been received in two
      % different rsync log files)
      if (lastCycleFlag == 1)
         o_profile.updated = 1;
      end
   end
end

if (o_profile.date == g_decArgo_dateDef)
   fprintf('WARNING: Float #%d Cycle #%d: Unable to find the date of the profile\n', ...
      g_decArgo_floatNum, ...
      o_profile.cycleNumber);
end
if (o_profile.locationDate == g_decArgo_dateDef)
   fprintf('WARNING: Float #%d Cycle #%d: Unable to find the loction of the profile\n', ...
      g_decArgo_floatNum, ...
      o_profile.cycleNumber);
end

return
