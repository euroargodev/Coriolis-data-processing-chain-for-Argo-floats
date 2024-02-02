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
end

% we have not been able to set a location for the profile, we will use the
% Iridium locations
if (o_profile.locationDate == g_decArgo_dateDef)

   [locDate, locLon, locLat, locQc] = ...
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

   else

      [locDate, locLon, locLat, locQc] = ...
         compute_profile_location2_from_iridium_locations_ir_sbd(a_iridiumData, o_profile.cycleNumber);
      if (~isempty(locDate))
         % assign the averaged Iridium location to the profile
         o_profile.locationDate2 = locDate;
         o_profile.locationLon2 = locLon;
         o_profile.locationLat2 = locLat;
         o_profile.locationQc2 = locQc;
         o_profile.iridiumLocation2 = 1;

         % positioning system
         o_profile.posSystem2 = 'IRIDIUM';
      end
   end
end

if (o_profile.date == g_decArgo_dateDef)
   fprintf('WARNING: Float #%d Cycle #%d: Unable to find the date of the profile\n', ...
      g_decArgo_floatNum, ...
      o_profile.cycleNumber);
end
if (o_profile.locationDate == g_decArgo_dateDef)
   fprintf('WARNING: Float #%d Cycle #%d: Unable to find the location of the profile\n', ...
      g_decArgo_floatNum, ...
      o_profile.cycleNumber);
end

return
