% ------------------------------------------------------------------------------
% Add the profile date and location of a profile.
%
% SYNTAX :
%  [o_profStruct] = add_profile_date_and_location_201_to_226_2001_to_2003( ...
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
function [o_profStruct] = add_profile_date_and_location_201_to_226_2001_to_2003( ...
   a_profStruct, a_gpsData, a_iridiumMailData, ...
   a_descentToParkStartDate, a_ascentEndDate, a_transStartDate)

% output parameters initialization
o_profStruct = [];

% default values
global g_decArgo_dateDef;

% number of the first deep cycle
global g_decArgo_firstDeepCycleNumber;

% QC flag values (char)
global g_decArgo_qcStrNoQc;


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
      
      % update GPS position QC information if needed
      if (any((a_gpsData{1} ~= -1) & (a_gpsData{7} == 0)))
         gpsData = update_gps_position_qc_ir_sbd;
      else
         gpsData = a_gpsData;
      end
      
      % use the GPS locations
      gpsLocCycleNum = gpsData{1};
      gpsLocDate = gpsData{4};
      gpsLocLon = gpsData{5};
      gpsLocLat = gpsData{6};
      gpsLocQc = gpsData{7};
      
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
         a_profStruct.locationQc = g_decArgo_qcStrNoQc;
         a_profStruct.iridiumLocation = 0;
         
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

      else

         [locDate, locLon, locLat, locQc] = ...
            compute_profile_location2_from_iridium_locations_ir_sbd(a_iridiumMailData, a_profStruct.cycleNumber-1);
         if (~isempty(locDate))
            % assign the averaged Iridium location to the profile
            a_profStruct.locationDate2 = locDate;
            a_profStruct.locationLon2 = locLon;
            a_profStruct.locationLat2 = locLat;
            a_profStruct.locationQc2 = locQc;
            a_profStruct.iridiumLocation2 = 1;

            % positioning system
            a_profStruct.posSystem2 = 'IRIDIUM';
         end
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
      
      % update GPS position QC information if needed
      if (any((a_gpsData{1} ~= -1) & (a_gpsData{7} == 0)))
         gpsData = update_gps_position_qc_ir_sbd;
      else
         gpsData = a_gpsData;
      end
      
      % use the GPS locations
      gpsLocCycleNum = gpsData{1};
      gpsLocDate = gpsData{4};
      gpsLocLon = gpsData{5};
      gpsLocLat = gpsData{6};
      gpsLocQc = gpsData{7};
      
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

      else

         [locDate, locLon, locLat, locQc] = ...
            compute_profile_location2_from_iridium_locations_ir_sbd(a_iridiumMailData, a_profStruct.cycleNumber);
         if (~isempty(locDate))
            % assign the averaged Iridium location to the profile
            a_profStruct.locationDate2 = locDate;
            a_profStruct.locationLon2 = locLon;
            a_profStruct.locationLat2 = locLat;
            a_profStruct.locationQc2 = locQc;
            a_profStruct.iridiumLocation2 = 1;

            % positioning system
            a_profStruct.posSystem2 = 'IRIDIUM';
         end
      end
   end
   
end

% output data
o_profStruct = a_profStruct;

return
