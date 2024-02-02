% ------------------------------------------------------------------------------
% Add the profile date and location of a profile.
%
% SYNTAX :
%  [o_profStruct] = add_profile_date_and_location_ir_rudics_cts5( ...
%    a_profStruct, a_timedata, a_gpsData)
%
% INPUT PARAMETERS :
%   a_profStruct : input profile
%   a_timedata   : cycle timings
%   a_gpsData    : information on GPS locations
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
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profStruct] = add_profile_date_and_location_ir_rudics_cts5( ...
   a_profStruct, a_timedata, a_gpsData)

% output parameters initialization
o_profStruct = [];

% current float WMO number
global g_decArgo_floatNum;

% global default values
global g_decArgo_dateDef;

% QC flag values (char)
global g_decArgo_qcStrInterpolated;

% existing cycle and pattern numbers
global g_decArgo_cyclePatternNumFloat;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;


% unpack the input data
a_gpsLocCycleNum = a_gpsData{1};
a_gpsLocProfNum = a_gpsData{2};
a_gpsLocPhase = a_gpsData{3};
a_gpsLocDate = a_gpsData{4};
a_gpsLocLon = a_gpsData{5};
a_gpsLocLat = a_gpsData{6};
a_gpsLocQc = a_gpsData{7};
a_gpsLocAccuracy = a_gpsData{8};
a_gpsLocSbdFileDate = a_gpsData{9};

% look for the first and last times of the subsurface cycle
cycleStartDate = g_decArgo_dateDef;
descentToParkStartDate = g_decArgo_dateDef;
ascentEndDate = g_decArgo_dateDef;
for idT = 1:length(a_timedata)
   if (cycleStartDate == g_decArgo_dateDef)
      if (strcmp(a_timedata{idT}.label, 'CYCLE START TIME'))
         if (~isempty(a_timedata{idT}.timeAdj) && (a_timedata{idT}.timeAdj ~= g_decArgo_dateDef))
            cycleStartDate = a_timedata{idT}.timeAdj;
         else
            cycleStartDate = a_timedata{idT}.time;
         end
      end
   end
   if (descentToParkStartDate == g_decArgo_dateDef)
      if (strcmp(a_timedata{idT}.label, 'DESCENT TO PARK START TIME'))
         if (~isempty(a_timedata{idT}.timeAdj) && (a_timedata{idT}.timeAdj ~= g_decArgo_dateDef))
            descentToParkStartDate = a_timedata{idT}.timeAdj;
         else
            descentToParkStartDate = a_timedata{idT}.time;
         end
      end
   end
   if (ascentEndDate == g_decArgo_dateDef)
      if (strcmp(a_timedata{idT}.label, 'ASCENT END TIME'))
         if (~isempty(a_timedata{idT}.timeAdj) && (a_timedata{idT}.timeAdj ~= g_decArgo_dateDef))
            ascentEndDate = a_timedata{idT}.timeAdj;
         else
            ascentEndDate = a_timedata{idT}.time;
         end
      end
   end
   if ((ascentEndDate ~= g_decArgo_dateDef) && ...
         (descentToParkStartDate ~= g_decArgo_dateDef) && ...
         (cycleStartDate ~= g_decArgo_dateDef))
      break
   end
end

% add profile date and location
if (a_profStruct.direction == 'A')
   
   % ascent profile
   
   % add profile date
   a_profStruct.date = ascentEndDate;
   
   % add profile location
   
   % select the GPS data to use
   idPosToUse = find( ...
      (a_gpsLocCycleNum == a_profStruct.cycleNumber) & ...
      (a_gpsLocProfNum == a_profStruct.profileNumber));
   
   if (~isempty(idPosToUse))
      
      % the float surfaced after this profile
      [~, idMin] = min(a_gpsLocDate(idPosToUse));
      a_profStruct.locationDate = a_gpsLocDate(idPosToUse(idMin));
      a_profStruct.locationLon = a_gpsLocLon(idPosToUse(idMin));
      a_profStruct.locationLat = a_gpsLocLat(idPosToUse(idMin));
      a_profStruct.locationQc = num2str(a_gpsLocQc(idPosToUse(idMin)));
   else
      
      if (~isempty(g_decArgo_iridiumMailData))

         % we have not been able to set a location for the profile
         % we will use the Iridium locations
         if (a_profStruct.locationDate == g_decArgo_dateDef)

            [locDate, locLon, locLat, locQc, firstMsgTime] = ...
               compute_profile_location_from_iridium_locations_ir_sbd2( ...
               g_decArgo_iridiumMailData, a_profStruct.cycleNumber, a_profStruct.profileNumber, 0);

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

               [locDate, locLon, locLat, locQc, firstMsgTime] = ...
                  compute_profile_location2_from_iridium_locations_ir_sbd2( ...
                  g_decArgo_iridiumMailData, a_profStruct.cycleNumber, a_profStruct.profileNumber, 0);

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

      % we have not been able to set a location for the profile
      % we will interpolate between the existing GPS locations
      if (a_profStruct.date ~= g_decArgo_dateDef)
         
         % we must interpolate between the existing GPS locations
         prevLocDate = g_decArgo_dateDef;
         nextLocDate = g_decArgo_dateDef;
         
         % find the previous GPS location
         idPrev = find((a_gpsLocDate <= a_profStruct.date) & (a_gpsLocQc == 1));
         if (~isempty(idPrev))
            % previous good GPS locations exist, use the last one
            [~, idMax] = max(a_gpsLocDate(idPrev));
            prevLocDate = a_gpsLocDate(idPrev(idMax));
            prevLocLon = a_gpsLocLon(idPrev(idMax));
            prevLocLat = a_gpsLocLat(idPrev(idMax));
         end
         
         % find the next GPS location
         idNext = find((a_gpsLocDate >= a_profStruct.date) & (a_gpsLocQc == 1));
         if (~isempty(idNext))
            % next good GPS locations exist, use the first one
            [~, idMin] = min(a_gpsLocDate(idNext));
            nextLocDate = a_gpsLocDate(idNext(idMin));
            nextLocLon = a_gpsLocLon(idNext(idMin));
            nextLocLat = a_gpsLocLat(idNext(idMin));
         end
         
         % interpolate between the 2 locations
         if ((prevLocDate ~= g_decArgo_dateDef) && (nextLocDate ~= g_decArgo_dateDef))
            
            % interpolate the locations
            [interpLocLon, interpLocLat] = interpolate_between_2_locations(...
               prevLocDate, prevLocLon, prevLocLat, ...
               nextLocDate, nextLocLon, nextLocLat, ...
               a_profStruct.date);
            
            if (~isnan(interpLocLon))
               % assign the interpolated location to the profile
               a_profStruct.locationDate = a_profStruct.date;
               a_profStruct.locationLon = interpLocLon;
               a_profStruct.locationLat = interpLocLat;
               a_profStruct.locationQc = g_decArgo_qcStrInterpolated;
            else
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: time inconsistency detected while interpolating for profile location processing - profile not located\n', ...
                  g_decArgo_floatNum, ...
                  a_profStruct.cycleNumber, a_profStruct.profileNumber);
            end
         end
      end
   end
   
else
   
   % descent profile
   
   % add profile date
   a_profStruct.date = cycleStartDate;
   if (a_profStruct.date == g_decArgo_dateDef)
      a_profStruct.date = descentToParkStartDate;
   end
   
   % add profile location
   
   if (a_profStruct.date ~= g_decArgo_dateDef)
      
      % find the previous GPS location
      idPrev = find((a_gpsLocDate <= a_profStruct.date) & (a_gpsLocQc == 1));
      if (~isempty(idPrev))
         % previous good GPS locations exist, use the last one
         [~, idMax] = max(a_gpsLocDate(idPrev));
         idPrev = idPrev(idMax);
         useIt = 0;

         % search if we can use the previous GPS location
         % look for the previous received cycle and pattern numbers
         % CAREFUL: RECEIVED means that we can only consider what has been
         % received to find the previous location !
         idCurNum = find((g_decArgo_cyclePatternNumFloat(:, 1) == a_profStruct.cycleNumber) & ...
            (g_decArgo_cyclePatternNumFloat(:, 2) == a_profStruct.profileNumber));
         if (idCurNum == 1)
            % the previous location is not part of received data; it is the
            % launch position
            useIt = 1;
         else
            if ((a_gpsLocCycleNum(idPrev) == g_decArgo_cyclePatternNumFloat(idCurNum-1, 1)) && ...
                  (a_gpsLocProfNum(idPrev) == g_decArgo_cyclePatternNumFloat(idCurNum-1, 2)))
               % the previous location is the location of the previous RECEIVED
               % cycle
               useIt = 1;
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

      % we have not been able to set a location for the profile
      % we will use the Iridium locations
      if (a_profStruct.locationDate == g_decArgo_dateDef)

         % look for the cycle and pattern numbers of the previous cycle
         % CAREFUL: RECEIVED means that we can only consider what has been
         % received to find the previous location !
         prevCyNum = '';
         idCurNum = find((g_decArgo_cyclePatternNumFloat(:, 1) == a_profStruct.cycleNumber) & ...
            (g_decArgo_cyclePatternNumFloat(:, 2) == a_profStruct.profileNumber));
         if (idCurNum == 1)
            % the previous location is not part of received data => no Iridium location assigned
         else
            prevCyNum = g_decArgo_cyclePatternNumFloat(idCurNum-1, 1);
            prevProfNum = g_decArgo_cyclePatternNumFloat(idCurNum-1, 2);
         end

         if (~isempty(prevCyNum))

            [locDate, locLon, locLat, locQc, firstMsgTime] = ...
               compute_profile_location_from_iridium_locations_ir_sbd2( ...
               g_decArgo_iridiumMailData, prevCyNum, prevProfNum, 0);

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

               [locDate, locLon, locLat, locQc, firstMsgTime] = ...
                  compute_profile_location2_from_iridium_locations_ir_sbd2( ...
                  g_decArgo_iridiumMailData, prevCyNum, prevProfNum, 0);

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

      % we have not been able to set a location for the profile
      % we will interpolate between the existing GPS locations
      if (a_profStruct.locationDate == g_decArgo_dateDef)
         if (a_profStruct.date ~= g_decArgo_dateDef)

            % we must interpolate between the existing GPS locations

            % find the previous GPS location
            idPrev = find((a_gpsLocDate <= a_profStruct.date) & (a_gpsLocQc == 1));
            if (~isempty(idPrev))
               % previous good GPS locations exist, use the last one
               [~, idMax] = max(a_gpsLocDate(idPrev));
               idPrev = idPrev(idMax);
               
               % find the previous GPS location
               prevLocDate = a_gpsLocDate(idPrev);
               prevLocLon = a_gpsLocLon(idPrev);
               prevLocLat = a_gpsLocLat(idPrev);

               % find the next GPS location
               nextLocDate = g_decArgo_dateDef;
               idNext = find((a_gpsLocDate >= a_profStruct.date) & (a_gpsLocQc == 1));
               if (~isempty(idNext))
                  % next good GPS locations exist, use the first one
                  [~, idMin] = min(a_gpsLocDate(idNext));
                  nextLocDate = a_gpsLocDate(idNext(idMin));
                  nextLocLon = a_gpsLocLon(idNext(idMin));
                  nextLocLat = a_gpsLocLat(idNext(idMin));
               end

               % interpolate between the 2 locations
               if (nextLocDate ~= g_decArgo_dateDef)

                  % interpolate the locations
                  [interpLocLon, interpLocLat] = interpolate_between_2_locations(...
                     prevLocDate, prevLocLon, prevLocLat, ...
                     nextLocDate, nextLocLon, nextLocLat, ...
                     a_profStruct.date);

                  if (~isnan(interpLocLon))
                     % assign the interpolated location to the profile
                     a_profStruct.locationDate = a_profStruct.date;
                     a_profStruct.locationLon = interpLocLon;
                     a_profStruct.locationLat = interpLocLat;
                     a_profStruct.locationQc = g_decArgo_qcStrInterpolated;
                  else
                     fprintf('WARNING: Float #%d Cycle #%d Profile #%d: time inconsistency detected while interpolating for profile location processing - profile not located\n', ...
                        g_decArgo_floatNum, ...
                        a_profStruct.cycleNumber, a_profStruct.profileNumber);
                  end
               end
            end
         end
      end
   end
end

% output data
o_profStruct = a_profStruct;

return
