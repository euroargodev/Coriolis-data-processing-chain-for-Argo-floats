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

% QC flag values (char)
global g_decArgo_qcStrInterpolated;

% maximum time difference (in days) between 2 GPS locations used to replace
% Iridium profile locations by interpolated GPS profile locations
global g_decArgo_maxDelayToReplaceIrLocByInterpolatedGpsLoc;


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
      
      % add profile location
      
      % select the GPS data to use
      idPosToUse = find( ...
         (a_gpsLocCycleNum == a_profStruct.cycleNumber) & ...
         (a_gpsLocProfNum == a_profStruct.profileNumber) & ...
         (a_gpsLocPhase == g_decArgo_phaseSatTrans));
      
      if (~isempty(idPosToUse))

         if (length(idPosToUse) > 1)
            % anomaly management float #6901440 cycle #9
            fprintf('ERROR: Float #%d Cycle #%d Profile #%d: %d GPS locations to locate the profile => using the last one\n', ...
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
      else
         
         % the float didn't surface after this profile
         if (a_profStruct.date ~= g_decArgo_dateDef)
            
            % we must interpolate between the existing GPS locations
            prevLocDate = g_decArgo_dateDef;
            nextLocDate = g_decArgo_dateDef;
            
            % find the previous GPS location
            idPrev = find(a_gpsLocDate <= a_profStruct.date);
            if (~isempty(idPrev))
               idPrev = idPrev(end);
               prevLocDate = a_gpsLocDate(idPrev);
               prevLocLon = a_gpsLocLon(idPrev);
               prevLocLat = a_gpsLocLat(idPrev);
            end
            
            % find the next GPS location
            idNext = find(a_gpsLocDate >= a_profStruct.date);
            if (~isempty(idNext))
               idNext = idNext(1);
               nextLocDate = a_gpsLocDate(idNext);
               nextLocLon = a_gpsLocLon(idNext);
               nextLocLat = a_gpsLocLat(idNext);
            end
            
            % interpolate between the 2 locations
            if ((prevLocDate ~= g_decArgo_dateDef) && (nextLocDate ~= g_decArgo_dateDef) && ...
                  ((nextLocDate-prevLocDate) <= g_decArgo_maxDelayToReplaceIrLocByInterpolatedGpsLoc))

            % interpolate the locations
               interpLocLon = interp1q([prevLocDate; nextLocDate], [prevLocLon; nextLocLon], a_profStruct.date);
               interpLocLat = interp1q([prevLocDate; nextLocDate], [prevLocLat; nextLocLat], a_profStruct.date);
               
               if (~isnan(interpLocLon))
                  % assign the interpolated location to the profile
                  a_profStruct.locationDate = a_profStruct.date;
                  a_profStruct.locationLon = interpLocLon;
                  a_profStruct.locationLat = interpLocLat;
                  a_profStruct.locationQc = g_decArgo_qcStrInterpolated;
               else
                  fprintf('WARNING: Float #%d Cycle #%d Profile #%d: time inconsistency detected while interpolating for profile location processing => profile not located\n', ...
                     g_decArgo_floatNum, ...
                     a_profStruct.cycleNumber, a_profStruct.profileNumber);
               end
            end
         end
      end
   end
   
   % we have not been able to set a location for the profile, we will use the
   % Iridium locations
   if (a_profStruct.locationDate == g_decArgo_dateDef)
      [locDate, locLon, locLat, locQc, firstMsgTime, lastCycleFlag] = ...
         compute_profile_location_from_iridium_locations_ir_sbd2( ...
         a_iridiumMailData, a_profStruct.cycleNumber, a_profStruct.profileNumber);

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
         
         % if the current cycle is the last received cycle, the location could
         % have been updated (if the last cycle data have been received in two
         % different rsync log files)
         if (lastCycleFlag == 1)
            a_profStruct.updated = 1;
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
      
      % add profile location
      
      if (a_profStruct.date ~= g_decArgo_dateDef)
         
         % find the previous GPS location
         idPrev = find(a_gpsLocDate <= a_profStruct.date);
         if (~isempty(idPrev))
            idPrev = idPrev(end);            
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
                     % Iridium session of the current cyle
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
               
            else
               
               % we must interpolate between the existing GPS locations
               
               % find the previous GPS location
               prevLocDate = a_gpsLocDate(idPrev);
               prevLocLon = a_gpsLocLon(idPrev);
               prevLocLat = a_gpsLocLat(idPrev);
               
               % find the next GPS location
               nextLocDate = g_decArgo_dateDef;
               idNext = find(a_gpsLocDate >= a_profStruct.date);
               if (~isempty(idNext))
                  idNext = idNext(1);
                  nextLocDate = a_gpsLocDate(idNext);
                  nextLocLon = a_gpsLocLon(idNext);
                  nextLocLat = a_gpsLocLat(idNext);
               end
               
               % interpolate between the 2 locations
               if (nextLocDate ~= g_decArgo_dateDef)
                  
                  % interpolate the locations
                  interpLocLon = interp1q([prevLocDate; nextLocDate], [prevLocLon; nextLocLon], a_profStruct.date);
                  interpLocLat = interp1q([prevLocDate; nextLocDate], [prevLocLat; nextLocLat], a_profStruct.date);
                  
                  if (~isnan(interpLocLon))
                     % assign the interpolated location to the profile
                     a_profStruct.locationDate = a_profStruct.date;
                     a_profStruct.locationLon = interpLocLon;
                     a_profStruct.locationLat = interpLocLat;
                     a_profStruct.locationQc = g_decArgo_qcStrInterpolated;
                  else
                     fprintf('WARNING: Float #%d Cycle #%d Profile #%d: time inconsistency detected while interpolating for profile location processing => profile not located\n', ...
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

return;
