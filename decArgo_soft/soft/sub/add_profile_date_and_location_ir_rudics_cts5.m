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

% first float cycle number to consider
global g_decArgo_firstCycleNumFloat;

% existing cycle and pattern numbers
global g_decArgo_cyclePatternNumFloat;


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
ascentEndDate = g_decArgo_dateDef;
for idT = 1:length(a_timedata)
   if (cycleStartDate == g_decArgo_dateDef)
      if (strcmp(a_timedata{idT}.label, 'CYCLE START TIME'))
         if (~isempty(a_timedata{idT}.timeAdj))
            cycleStartDate = a_timedata{idT}.timeAdj;
         else
            cycleStartDate = a_timedata{idT}.time;
         end
      end
   end
   if (ascentEndDate == g_decArgo_dateDef)
      if (strcmp(a_timedata{idT}.label, 'ASCENT END TIME'))
         if (~isempty(a_timedata{idT}.timeAdj))
            ascentEndDate = a_timedata{idT}.timeAdj;
         else
            ascentEndDate = a_timedata{idT}.time;
         end
      end
   end
   if ((ascentEndDate ~= g_decArgo_dateDef) && (cycleStartDate ~= g_decArgo_dateDef))
      break
   end
end

% add profile date dans location
if (a_profStruct.direction == 'A')
   
   % ascent profile
   
   if (~isempty(ascentEndDate))
      
      % add profile date
      a_profStruct.date = ascentEndDate;
      
      % add profile location
      
      % select the GPS data to use
      idPosToUse = find( ...
         (a_gpsLocCycleNum == a_profStruct.cycleNumber) & ...
         (a_gpsLocProfNum == a_profStruct.profileNumber));
      
      if (~isempty(idPosToUse))
                  
         % the float surfaced after this profile
         idPosToUse = idPosToUse(1);
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
                  fprintf('WARNING: Float #%d Cycle #%d Profile #%d: time inconsistency detected while interpolating for profile location processing => profile not located\n', ...
                     g_decArgo_floatNum, ...
                     a_profStruct.cycleNumber, a_profStruct.profileNumber);
               end
            end
         end
      end
   end
   
else
   
   % descent profile
   
   if (~isempty(cycleStartDate))
      
      % add profile date
      a_profStruct.date = cycleStartDate;
      
      % add profile location
      
      if (a_profStruct.date ~= g_decArgo_dateDef)
         
         % find the previous GPS location
         idPrev = find(a_gpsLocDate <= a_profStruct.date);
         if (~isempty(idPrev))
            idPrev = idPrev(end);            
            useIt = 0;
                        
            % search if we can use the previous GPS location
            if ((a_profStruct.cycleNumber == g_decArgo_firstCycleNumFloat) && ...
                  (a_profStruct.profileNumber == 1))
               % the previous location is the launch position or the location of
               % the prelude (cycle = g_decArgo_firstCycleNumFloat, pattern = 0)
               useIt = 1;
            else
               if (a_profStruct.profileNumber == 1)
                  
                  % retrieve the last pattern number of the previous cycle
                  idF = find(g_decArgo_cyclePatternNumFloat(:, 1) == a_profStruct.cycleNumber-1);
                  if (~isempty(idF))
                     lastPtnNumOfPrevCy = max(g_decArgo_cyclePatternNumFloat(idF, 2));
                     
                     if ((a_gpsLocCycleNum(idPrev) == a_profStruct.cycleNumber-1) && ...
                           (a_gpsLocProfNum(idPrev) == lastPtnNumOfPrevCy))
                        
                        % the previous location is the location of the last
                        % transmission of the previous cycle
                        useIt = 1;
                     end
                  end
               else
                  if ((a_gpsLocCycleNum(idPrev) == a_profStruct.cycleNumber) && ...
                        (a_gpsLocProfNum(idPrev) == a_profStruct.profileNumber-1))
                     % the previous location is the location of the previous
                     % profile (sub-cycle) of the current cycle
                     useIt = 1;
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

return
