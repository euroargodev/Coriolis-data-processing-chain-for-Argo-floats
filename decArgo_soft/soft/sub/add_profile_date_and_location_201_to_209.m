% ------------------------------------------------------------------------------
% Add the profile date and location of a profile.
%
% SYNTAX :
%  [o_profStruct] = add_profile_date_and_location_201_to_209( ...
%    a_profStruct, a_gpsData, a_iridiumMailData, ...
%    a_descentToParkStartDate, a_ascentEndDate, a_transStartDate)
%
% INPUT PARAMETERS :
%   a_profStruct             : input profile
%   a_gpsData                : GPS data
%   a_iridiumMailData        : Iridium mail contents
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_transStartDate         : transmission start date
%
% OUTPUT PARAMETERS :
%   o_profStruct : output dated and located profile
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profStruct] = add_profile_date_and_location_201_to_209( ...
   a_profStruct, a_gpsData, a_iridiumMailData, ...
   a_descentToParkStartDate, a_ascentEndDate, a_transStartDate)

% output parameters initialization
o_profStruct = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_dateDef;

% number of the first deep cycle
global g_decArgo_firstDeepCycleNumber;


% add profile date dans location
if (a_profStruct.direction == 'D')
   
   % descending profile
   
   % add profile date (it is a_descentToParkStartDate, always present in the
   % tech msg of a deep cycle)
   if (~isempty(a_descentToParkStartDate))
      % nominal case
      a_profStruct.date = a_descentToParkStartDate;
   else
      % the tech msg has not been received
      
      % retrieve the last message of the previous cycle or the float launch date
      % (cycle = -1)
      [~, lastMsgTime] = ...
         compute_first_last_msg_time_from_iridium_mail(a_iridiumMailData, a_profStruct.cycleNumber-1);
      if (lastMsgTime ~= g_decArgo_dateDef)
         a_profStruct.date = lastMsgTime;
      end
   end
   
   % add profile location
   if (~isempty(a_gpsData))
      
      % use the GPS locations of the previous cycle
      gpsLocCycleNum = a_gpsData{1};
      gpsLocDate = a_gpsData{4};
      gpsLocLon = a_gpsData{5};
      gpsLocLat = a_gpsData{6};
      gpsLocQc = a_gpsData{7};
      
      % retrieve the good locations of the previous cycle
      idLocCy = find((gpsLocCycleNum == a_profStruct.cycleNumber - 1) & (gpsLocQc == 1));
      if (~isempty(idLocCy))
         
         % good GPS locations exist for the previous cycle, use the last one
         [~, idMax] = max(gpsLocDate(idLocCy));
         a_profStruct.locationDate = gpsLocDate(idLocCy(idMax));
         a_profStruct.locationLon = gpsLocLon(idLocCy(idMax));
         a_profStruct.locationLat = gpsLocLat(idLocCy(idMax));
         a_profStruct.locationQc = num2str(gpsLocQc(idLocCy(idMax))); % it is '1'
         a_profStruct.iridiumLocation = 0;
         
      elseif (a_profStruct.cycleNumber == g_decArgo_firstDeepCycleNumber)
         
         % it is the first deep cycle and there is no good GPS fix collected during
         % the prelude phase, use the launch date and location
         idLocLaunch = find(gpsLocCycleNum == -1);
         a_profStruct.locationDate = gpsLocDate(idLocLaunch);
         a_profStruct.locationLon = gpsLocLon(idLocLaunch);
         a_profStruct.locationLat = gpsLocLat(idLocLaunch);
         a_profStruct.locationQc = '0';
         a_profStruct.iridiumLocation = 0;
         
      elseif (a_profStruct.date ~= g_decArgo_dateDef)
         
         % there is no GPS locations for the previous cycle, we must interpolate
         % between existing GPS locations
         prevLocDate = g_decArgo_dateDef;
         nextLocDate = g_decArgo_dateDef;
         
         % find the previous GPS location
         idPrev = find(gpsLocDate <= a_profStruct.date);
         if (~isempty(idPrev))
            idPrev = idPrev(end);
            prevLocDate = gpsLocDate(idPrev);
            prevLocLon = gpsLocLon(idPrev);
            prevLocLat = gpsLocLat(idPrev);
         end
         
         % find the next GPS location
         idNext = find(gpsLocDate >= a_profStruct.date);
         if (~isempty(idNext))
            idNext = idNext(1);
            nextLocDate = gpsLocDate(idNext);
            nextLocLon = gpsLocLon(idNext);
            nextLocLat = gpsLocLat(idNext);
         end
         
         % interpolate between the 2 locations
         if ((prevLocDate ~= g_decArgo_dateDef) && (nextLocDate ~= g_decArgo_dateDef))
            
            % interpolate the locations
            interpLocLon = interp1q([prevLocDate; nextLocDate], [prevLocLon; nextLocLon], a_profStruct.date);
            interpLocLat = interp1q([prevLocDate; nextLocDate], [prevLocLat; nextLocLat], a_profStruct.date);
            
            if (~isnan(interpLocLon))
               % assign the interpolated location to the profile
               a_profStruct.locationDate = a_profStruct.date;
               a_profStruct.locationLon = interpLocLon;
               a_profStruct.locationLat = interpLocLat;
               a_profStruct.locationQc = '8';
               a_profStruct.iridiumLocation = 0;
            else
               fprintf('WARNING: Float #%d Cycle #%d: time inconsistency detected while interpolating for profile location processing => profile not located\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum);
            end
         end
      end
   end
   
   % we have not been able to set a location for the profile, we will use the
   % Iridium locations
   if (a_profStruct.locationDate == g_decArgo_dateDef)
      
      [locDate, locLon, locLat, locQc] = ...
         compute_profile_location_from_iridium_locations_ir_sbd(a_iridiumMailData, a_profStruct.cycleNumber-1);
      if (~isempty(locDate))
         % assign the averaged Iridium location to the profile
         a_profStruct.locationDate = locDate;
         a_profStruct.locationLon = locLon;
         a_profStruct.locationLat = locLat;
         a_profStruct.locationQc = locQc;
         a_profStruct.iridiumLocation = 1;
         
         % positioning system
         a_profStruct.posSystem = 'IRIDIUM';
      end
      
   end
   
else
   
   % ascending profile
   
   % add profile date (it is a_ascentEndDate if exists (if PT4 is known),
   % otherwise it is a_transStartDate, always present in the tech msg of a
   % deep cycle)
   if (~isempty(a_ascentEndDate))
      % nominal case
      a_profStruct.date = a_ascentEndDate;
   elseif (~isempty(a_transStartDate))
      % CONFIG_PT04 is unknown
      a_profStruct.date = a_transStartDate;
   else
      % the tech msg has not been received
      
      % retrieve the first message of the current cycle
      [firstMsgTime, ~] = ...
         compute_first_last_msg_time_from_iridium_mail(a_iridiumMailData, a_profStruct.cycleNumber);
      if (firstMsgTime ~= g_decArgo_dateDef)
         a_profStruct.date = firstMsgTime;
      end
   end
   
   % add profile location
   if (~isempty(a_gpsData))
      
      % use the GPS locations
      gpsLocCycleNum = a_gpsData{1};
      gpsLocDate = a_gpsData{4};
      gpsLocLon = a_gpsData{5};
      gpsLocLat = a_gpsData{6};
      gpsLocQc = a_gpsData{7};
      
      % retrieve the good locations of the current cycle
      idLocCy = find((gpsLocCycleNum == a_profStruct.cycleNumber) & (gpsLocQc == 1));
      if (~isempty(idLocCy))
         
         % good GPS locations exist for the current cycle, use the first one
         [~, idMin] = min(gpsLocDate(idLocCy));
         a_profStruct.locationDate = gpsLocDate(idLocCy(idMin));
         a_profStruct.locationLon = gpsLocLon(idLocCy(idMin));
         a_profStruct.locationLat = gpsLocLat(idLocCy(idMin));
         a_profStruct.locationQc = num2str(gpsLocQc(idLocCy(idMin))); % it is '1'
         a_profStruct.iridiumLocation = 0;
         
      elseif (a_profStruct.date ~= g_decArgo_dateDef)
         
         % there is no good GPS locations for this cycle, we must interpolate between
         % the existing GPS locations
         prevLocDate = g_decArgo_dateDef;
         nextLocDate = g_decArgo_dateDef;
         
         % find the previous GPS location
         idPrev = find(gpsLocDate <= a_profStruct.date);
         if (~isempty(idPrev))
            idPrev = idPrev(end);
            prevLocDate = gpsLocDate(idPrev);
            prevLocLon = gpsLocLon(idPrev);
            prevLocLat = gpsLocLat(idPrev);
         end
         
         % find the next GPS location
         idNext = find(gpsLocDate >= a_profStruct.date);
         if (~isempty(idNext))
            idNext = idNext(1);
            nextLocDate = gpsLocDate(idNext);
            nextLocLon = gpsLocLon(idNext);
            nextLocLat = gpsLocLat(idNext);
         end
         
         % interpolate between the 2 locations
         if ((prevLocDate ~= g_decArgo_dateDef) && (nextLocDate ~= g_decArgo_dateDef))
            
            % interpolate the locations
            interpLocLon = interp1q([prevLocDate; nextLocDate], [prevLocLon; nextLocLon], a_profStruct.date);
            interpLocLat = interp1q([prevLocDate; nextLocDate], [prevLocLat; nextLocLat], a_profStruct.date);
            
            if (~isnan(interpLocLon))
               % assign the interpolated location to the profile
               a_profStruct.locationDate = a_profStruct.date;
               a_profStruct.locationLon = interpLocLon;
               a_profStruct.locationLat = interpLocLat;
               a_profStruct.locationQc = '8';
               a_profStruct.iridiumLocation = 0;
            else
               fprintf('WARNING: Float #%d Cycle #%d: time inconsistency detected while interpolating for profile location processing => profile not located\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum);
            end
         end
      end
   end
   
   % we have not been able to set a location for the profile, we will use the
   % Iridium locations
   if (a_profStruct.locationDate == g_decArgo_dateDef)
      [locDate, locLon, locLat, locQc] = ...
         compute_profile_location_from_iridium_locations_ir_sbd(a_iridiumMailData, a_profStruct.cycleNumber);
      if (~isempty(locDate))
         % assign the averaged Iridium location to the profile
         a_profStruct.locationDate = locDate;
         a_profStruct.locationLon = locLon;
         a_profStruct.locationLat = locLat;
         a_profStruct.locationQc = locQc;
         a_profStruct.iridiumLocation = 1;
         
         % positioning system
         a_profStruct.posSystem = 'IRIDIUM';
      end
   end
   
end

% output data
o_profStruct = a_profStruct;

return;
