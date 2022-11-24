% ------------------------------------------------------------------------------
% Add the profile date and location of a profile.
%
% SYNTAX :
%  [o_profStruct] = add_profile_date_and_location_ir_sbd2( ...
%    a_profStruct, ...
%    a_descentToParkStartDate, a_ascentEndDate, ...
%    a_gpsData, a_iridiumMailData)
%
% INPUT PARAMETERS :
%   a_profStruct             : input profile
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_gpsData                : information on GPS locations
%   a_iridiumMailData        : information on Iridium locations
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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profStruct] = add_profile_date_and_location_ir_sbd2( ...
   a_profStruct, ...
   a_descentToParkStartDate, a_ascentEndDate, ...
   a_gpsData, a_iridiumMailData)

% output parameters initialization
o_profStruct = [];

% current float WMO number
global g_decArgo_floatNum;

% cycle phases
global g_decArgo_phaseSurfWait;
global g_decArgo_phaseSatTrans;

% global default values
global g_decArgo_dateDef;


% unpack the input data
a_gpsLocCycleNum = a_gpsData{1};
a_gpsLocProfNum = a_gpsData{2};
a_gpsLocPhase = a_gpsData{3};
a_gpsLocDate = a_gpsData{4};
a_gpsLocLon = a_gpsData{5};
a_gpsLocLat = a_gpsData{6};
a_gpsLocQc = a_gpsData{7};

% add profile date dans location
if (a_profStruct.direction == 'A')
   
   % ascending profile

   % add profile date
   if (~isempty(a_ascentEndDate))
      
      % select the technical packet to use
      idTechToUse = find( ...
         (a_ascentEndDate(:, 1) == a_profStruct.cycleNumber) & ...
         (a_ascentEndDate(:, 2) == a_profStruct.profileNumber) & ...
         (a_ascentEndDate(:, 3) == g_decArgo_phaseSatTrans));
      
      if (~isempty(idTechToUse))
         a_profStruct.date = a_ascentEndDate(idTechToUse, 5);
      end
   end
      
   % add profile location

   % select the GPS data to use
   idPosToUse = find( ...
      (a_gpsLocCycleNum == a_profStruct.cycleNumber) & ...
      (a_gpsLocProfNum == a_profStruct.profileNumber) & ...
      (a_gpsLocPhase == g_decArgo_phaseSatTrans));

   if (~isempty(idPosToUse))

      if (length(idPosToUse) > 1)
         % anomaly management float #6901440 cycle #9
         fprintf('ERROR: Float #%d Cycle #%d Profile #%d: %d GPS locations to locate the profile - using the last one\n', ...
            g_decArgo_floatNum, ...
            a_profStruct.cycleNumber, a_profStruct.profileNumber, ...
            length(idPosToUse));
         idPosToUse = idPosToUse(end);
      end

      % the float surfaced after this profile
      a_profStruct.locationDate = a_gpsLocDate(idPosToUse);
      a_profStruct.locationLon = a_gpsLocLon(idPosToUse);
      a_profStruct.locationLat = a_gpsLocLat(idPosToUse);
      a_profStruct.locationQc = num2str(a_gpsLocQc(idPosToUse));
   end

   % we have not been able to set a location for the profile, we will use the
   % Iridium locations
   if (a_profStruct.locationDate == g_decArgo_dateDef)

      [locDate, locLon, locLat, locQc, firstMsgTime, ~] = ...
         compute_profile_location_from_iridium_locations_ir_sbd2( ...
         a_iridiumMailData, a_profStruct.cycleNumber, a_profStruct.profileNumber, 0);

      if (~isempty(locDate))

         if (a_profStruct.date == g_decArgo_dateDef)
            a_profStruct.date = firstMsgTime;
         end

         % assign the averaged Iridium location to the profile
         a_profStruct.locationDate = locDate;
         a_profStruct.locationLon = locLon;
         a_profStruct.locationLat = locLat;
         a_profStruct.locationQc = locQc;
         a_profStruct.iridiumLocation = 1;

         % positioning system
         a_profStruct.posSystem = 'IRIDIUM';

      else

         [locDate, locLon, locLat, locQc, firstMsgTime, ~] = ...
            compute_profile_location2_from_iridium_locations_ir_sbd2( ...
            a_iridiumMailData, a_profStruct.cycleNumber, a_profStruct.profileNumber, 0);

         if (~isempty(locDate))

            if (a_profStruct.date == g_decArgo_dateDef)
               a_profStruct.date = firstMsgTime;
            end

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
   
   % descending profile

   % add profile date
   if (~isempty(a_descentToParkStartDate))
      
      % select the technical packet to use
      idTechToUse = find( ...
         (a_descentToParkStartDate(:, 1) == a_profStruct.cycleNumber) & ...
         (a_descentToParkStartDate(:, 2) == a_profStruct.profileNumber) & ...
         (a_descentToParkStartDate(:, 3) == g_decArgo_phaseSatTrans));
      
      if (~isempty(idTechToUse))
         % add profile date
         a_profStruct.date = a_descentToParkStartDate(idTechToUse, 5);
      end
   end
      
   % add profile location
               
   % find the previous GPS location
   idPrev = find((a_gpsLocDate <= a_profStruct.date) & (a_gpsLocQc == 1));
   if (~isempty(idPrev))
      % previous good GPS locations exist, use the last one
      [~, idMax] = max(a_gpsLocDate(idPrev));
      idPrev = idPrev(idMax);
      useIt = 0;

      % search if we can use the previous GPS location
      if ((a_profStruct.cycleNumber == 0) && (a_profStruct.profileNumber == 0))
         % the previous location is the launch position or the location of
         % the second Iridium session of the first cycle (#0)
         useIt = 1;
      else
         if (a_profStruct.profileNumber > 0)
            if ((a_gpsLocCycleNum(idPrev) == a_profStruct.cycleNumber) && ...
                  (a_gpsLocProfNum(idPrev) == a_profStruct.profileNumber-1))
               % the previous location is the location of the previous
               % profile (sub-cycle) of the current cycle
               useIt = 1;
            end
         else
            if ((a_gpsLocCycleNum(idPrev) == a_profStruct.cycleNumber) && ...
                  (a_gpsLocProfNum(idPrev) == a_profStruct.profileNumber) && ...
                  (a_gpsLocPhase(idPrev) == g_decArgo_phaseSurfWait))
               % the previous location is the location of the second
               % Iridium session of the current cycle
               useIt = 1;
            else
               if ((a_gpsLocCycleNum(idPrev) == a_profStruct.cycleNumber-1) && ...
                     (a_gpsLocPhase(idPrev) == g_decArgo_phaseSatTrans))
                  % the previous location is the location of the last
                  % transmission of the previous cycle (we speculate that
                  % all the profiles of the previous cycle has been
                  % received)
                  useIt = 1;
               end
            end
         end
      end

      if (useIt == 1)

         % directly use the previous location
         a_profStruct.locationDate = a_gpsLocDate(idPrev);
         a_profStruct.locationLon = a_gpsLocLon(idPrev);
         a_profStruct.locationLat = a_gpsLocLat(idPrev);
         a_profStruct.locationQc = num2str(a_gpsLocQc(idPrev));

      end
   end

   % we have not been able to set a location for the profile, we will use the
   % Iridium locations
   if (a_profStruct.locationDate == g_decArgo_dateDef)

      [locDate, locLon, locLat, locQc, firstMsgTime, ~] = ...
         compute_profile_location_from_iridium_locations_ir_sbd2( ...
         a_iridiumMailData, a_profStruct.cycleNumber, a_profStruct.profileNumber, 1);

      if (~isempty(locDate))

         if (a_profStruct.date == g_decArgo_dateDef)
            a_profStruct.date = firstMsgTime;
         end

         % assign the averaged Iridium location to the profile
         a_profStruct.locationDate = locDate;
         a_profStruct.locationLon = locLon;
         a_profStruct.locationLat = locLat;
         a_profStruct.locationQc = locQc;
         a_profStruct.iridiumLocation = 1;

         % positioning system
         a_profStruct.posSystem = 'IRIDIUM';

      else

         [locDate, locLon, locLat, locQc, firstMsgTime, ~] = ...
            compute_profile_location2_from_iridium_locations_ir_sbd2( ...
            a_iridiumMailData, a_profStruct.cycleNumber, a_profStruct.profileNumber, 1);

         if (~isempty(locDate))

            if (a_profStruct.date == g_decArgo_dateDef)
               a_profStruct.date = firstMsgTime;
            end

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
