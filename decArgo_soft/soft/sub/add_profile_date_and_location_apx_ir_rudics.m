% ------------------------------------------------------------------------------
% Add the date and location of a profile.
%
% SYNTAX :
%  [o_tabProfiles] = add_profile_date_and_location_apx_ir_rudics( ...
%    a_tabProfiles, a_gpsData, o_tabTrajNMeas, o_tabTrajNCycle)
%
% INPUT PARAMETERS :
%   a_tabProfiles   : input profiles
%   a_gpsData       : information on GPS locations
%   o_tabTrajNMeas  : traj N_MEAS information
%   o_tabTrajNCycle : traj N_CYCLE information
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : output profiles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = add_profile_date_and_location_apx_ir_rudics( ...
   a_tabProfiles, a_gpsData, o_tabTrajNMeas, o_tabTrajNCycle)

% output parameters initialization
o_tabProfiles = a_tabProfiles;

% global default values
global g_decArgo_dateDef;

% current float WMO number
global g_decArgo_floatNum;

% global measurement codes
global g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST;
global g_MC_InAirSingleMeasRelativeToTST;

% QC flag values (char)
global g_decArgo_qcStrInterpolated;


% unpack the GPS input data
a_gpsLocCycleNum = a_gpsData{1};
a_gpsLocDate = a_gpsData{4};
a_gpsLocLon = a_gpsData{5};
a_gpsLocLat = a_gpsData{6};
a_gpsLocQc = a_gpsData{7};
a_gpsLocReceivedCyNum = [];
if (length(a_gpsData) > 11)
   a_gpsLocReceivedCyNum = a_gpsData{12};
end

% process all the profiles of the list
for idP = 1:length(o_tabProfiles)
   prof = o_tabProfiles(idP);
   
   if (isempty(prof.bounceFlag) || (strcmp(prof.bounceFlag, 'BS')))
      if (prof.direction == 'A')
         
         % add profile date
         idCyNCycle = find([o_tabTrajNCycle.cycleNumber] == prof.cycleNumber);
         if (~isempty(idCyNCycle))
            
            % choice #1 - ASCEND_END_DATE
            if (~isempty(o_tabTrajNCycle(idCyNCycle).juldAscentEnd))
               prof.date = o_tabTrajNCycle(idCyNCycle).juldAscentEnd;
            else
               idCyNMeas = find([o_tabTrajNMeas.cycleNumber] == prof.cycleNumber);
               if (~isempty(idCyNMeas))
                  if (~isempty(o_tabTrajNMeas(idCyNMeas).tabMeas))
                     
                     % choice #2 - last near surface measurement date (Navis only)
                     idNSSOM = find([o_tabTrajNMeas(idCyNMeas).tabMeas.measCode] == g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST);
                     if (~isempty(idNSSOM))
                        nearSurfMeasdates = [o_tabTrajNMeas(idCyNMeas).tabMeas(idNSSOM).juld];
                        if (~isempty(nearSurfMeasdates))
                           prof.date = max(nearSurfMeasdates);
                        end
                     end
                     
                     % choice #3 - first surface measurement date
                     if (prof.date == g_decArgo_dateDef)
                        idIASOM = find([o_tabTrajNMeas(idCyNMeas).tabMeas.measCode] == g_MC_InAirSingleMeasRelativeToTST);
                        if (~isempty(idIASOM))
                           surfMeasdates = [o_tabTrajNMeas(idCyNMeas).tabMeas(idIASOM).juld];
                           if (~isempty(surfMeasdates))
                              prof.date = min(surfMeasdates);
                           end
                        end
                     end
                  end
               end
               
               if ((prof.date == g_decArgo_dateDef) && isempty(prof.bounceFlag))
                  if (~isempty(o_tabTrajNCycle(idCyNCycle).juldFirstLocation))
                     % choice #4 - FIRST_LOCATION_DATE
                     prof.date = o_tabTrajNCycle(idCyNCycle).juldFirstLocation;
                  elseif (~isempty(o_tabTrajNCycle(idCyNCycle).juldTransmissionStart))
                     % choice #5 - TRANSMISSION_START_DATE
                     prof.date = o_tabTrajNCycle(idCyNCycle).juldTransmissionStart;
                  end
               end
            end
         end
      else
         fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in add_profile_date_and_location_apx_ir_rudics for profile direction ''%c''\n', ...
            g_decArgo_floatNum, ...
            prof.cycleNumber, ...
            prof.direction);
      end
   end
   
   if (prof.date == g_decArgo_dateDef)
      fprintf('WARNING: Float #%d Cycle #%d: Unable to find the date of the profile\n', ...
         g_decArgo_floatNum, ...
         prof.cycleNumber);
   end
   
   % set MTIME values
   idMtime  = find(strcmp({prof.paramList.name}, 'MTIME') == 1, 1);
   if (~isempty(idMtime))
      paramMtime = get_netcdf_param_attributes('MTIME');
      if (prof.date ~= g_decArgo_dateDef)
         % we compute MTIME as JULD-prof.date
         idDef = find(prof.data(:, idMtime) == paramMtime.fillValue);
         idNoDef = find(prof.data(:, idMtime) ~= paramMtime.fillValue);
         prof.data(idDef, idMtime) = prof.paramList(idMtime).fillValue;
         prof.data(idNoDef, idMtime) = prof.data(idNoDef, idMtime) - prof.date;
      else
         % we are not able to compute MTIME
         prof.data(:, idMtime) = ones(size(prof.data, 1), 1)*paramMtime.fillValue;
      end
   end
      
   % add profile location
   
   if (isempty(prof.bounceFlag))
      
      % select the GPS data to use
      idPosToUse = find((a_gpsLocCycleNum == prof.cycleNumber) & (a_gpsLocQc == 1));
      
      if (~isempty(idPosToUse))
         % set the profile updated flag if no GPS fix has been received during
         % the last cycle of the current decoding session (used to detect when a
         % profile needs to be updated in GENERATE_NC_MONO_PROF = 2 mode)
         if (~isempty(a_gpsLocReceivedCyNum)) % set for APF11 only
            if (~any(a_gpsLocReceivedCyNum(idPosToUse) == prof.cycleNumber))
               if ((any(a_gpsLocReceivedCyNum(idPosToUse) == max(a_gpsLocCycleNum))) || ...
                     (a_gpsLocCycleNum(end) == prof.cycleNumber))
                  prof.updated = 1;
               end
            end
         end
         
         % a GPS fix exists
         [~, idMin] = min(a_gpsLocDate(idPosToUse));
         idPosToUse = idPosToUse(idMin);
         prof.locationDate = a_gpsLocDate(idPosToUse);
         prof.locationLon = a_gpsLocLon(idPosToUse);
         prof.locationLat = a_gpsLocLat(idPosToUse);
         prof.locationQc = num2str(a_gpsLocQc(idPosToUse));
         
      else
         % no GPS fix exists
         
         if (prof.date ~= g_decArgo_dateDef)
            
            % we must interpolate between the existing GPS locations
            prevLocDate = g_decArgo_dateDef;
            nextLocDate = g_decArgo_dateDef;
            
            % find the previous GPS location
            idPrev = find((a_gpsLocDate <= prof.date) & (a_gpsLocQc == 1));
            if (~isempty(idPrev))
               % previous good GPS locations exist, use the last one
               [~, idMax] = max(a_gpsLocDate(idPrev));
               prevLocDate = a_gpsLocDate(idPrev(idMax));
               prevLocLon = a_gpsLocLon(idPrev(idMax));
               prevLocLat = a_gpsLocLat(idPrev(idMax));
            end
            
            % find the next GPS location
            idNext = find((a_gpsLocDate >= prof.date) & (a_gpsLocQc == 1));
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
                  prof.date);
               
               if (~isnan(interpLocLon))
                  % assign the interpolated location to the profile
                  prof.locationDate = prof.date;
                  prof.locationLon = interpLocLon;
                  prof.locationLat = interpLocLat;
                  prof.locationQc = g_decArgo_qcStrInterpolated;
                  
                  % set the profile updated flag if profile location is
                  % interpolated thanks to a new GPS received during the last
                  % cycle of the current decoding session (used to detect when a
                  % profile needs to be updated in GENERATE_NC_MONO_PROF = 2 mode)
                  if (~isempty(a_gpsLocReceivedCyNum)) % set for APF11 only
                     idNext = find(a_gpsLocDate == nextLocDate);
                     idPosUsed = find((a_gpsLocCycleNum == a_gpsLocCycleNum(idNext)) & (a_gpsLocQc == 1));
                     if (~any(a_gpsLocReceivedCyNum(idPosUsed) == a_gpsLocCycleNum(idNext)))
                        if ((any(a_gpsLocReceivedCyNum(idPosUsed) == max(a_gpsLocCycleNum))) || ...
                              (a_gpsLocCycleNum(end) == a_gpsLocCycleNum(idNext)))
                           prof.updated = 1;
                        end
                     end
                  end
               else
                  fprintf('WARNING: Float #%d Cycle #%d: time inconsistency detected while interpolating for profile location processing - profile not located\n', ...
                     g_decArgo_floatNum, ...
                     prof.cycleNumber);
               end
            end
         end
      end
   else
      
      % bounce profiles
      
      % select the GPS data to use
      idPosToUse = find((a_gpsLocCycleNum == prof.cycleNumber) & (a_gpsLocQc == 1));
      
      if (~isempty(idPosToUse))
         % set the profile updated flag if no GPS fix has been received during
         % the last cycle of the current decoding session (used to detect when a
         % profile needs to be updated in GENERATE_NC_MONO_PROF = 2 mode)
         if (~isempty(a_gpsLocReceivedCyNum)) % set for APF11 only
            if (~any(a_gpsLocReceivedCyNum(idPosToUse) == prof.cycleNumber))
               if ((any(a_gpsLocReceivedCyNum(idPosToUse) == max(a_gpsLocCycleNum))) || ...
                     (a_gpsLocCycleNum(end) == prof.cycleNumber))
                  prof.updated = 1;
               end
            end
         end
         
         % a GPS fix exists
         [~, idMin] = min(a_gpsLocDate(idPosToUse));
         idPosToUse = idPosToUse(idMin);
         currentLocDate = a_gpsLocDate(idPosToUse);
         currentLocLon = a_gpsLocLon(idPosToUse);
         currentLocLat = a_gpsLocLat(idPosToUse);
         currentLocQc = num2str(a_gpsLocQc(idPosToUse));
         
         if (strcmp(prof.bounceFlag, 'BE'))
            
            % last bounce profile => set the GPS location
            prof.locationDate = currentLocDate;
            prof.locationLon = currentLocLon;
            prof.locationLat = currentLocLat;
            prof.locationQc = currentLocQc;
         else
            
            % other bounce profile => interpolate available GPS locations
            if (prof.date ~= g_decArgo_dateDef)
               
               % we must interpolate between the existing GPS locations
               prevLocDate = g_decArgo_dateDef;
               
               % find the previous GPS location
               %                idPrev = find((a_gpsLocDate <= prof.date) & (a_gpsLocQc == 1));
               idPrev = find((a_gpsLocDate <= prof.date)); % no restriction on a_gpsLocQc because for cycle #1, the launch date is welcome
               if (~isempty(idPrev))
                  % previous good GPS locations exist, use the last one
                  [~, idMax] = max(a_gpsLocDate(idPrev));
                  prevLocDate = a_gpsLocDate(idPrev(idMax));
                  prevLocLon = a_gpsLocLon(idPrev(idMax));
                  prevLocLat = a_gpsLocLat(idPrev(idMax));
               end
               
               % interpolate between the 2 locations
               if (prevLocDate ~= g_decArgo_dateDef)
                  
                  % interpolate the locations
                  [interpLocLon, interpLocLat] = interpolate_between_2_locations(...
                     prevLocDate, prevLocLon, prevLocLat, ...
                     currentLocDate, currentLocLon, currentLocLat, ...
                     prof.date);
                  
                  if (~isnan(interpLocLon))
                     % assign the interpolated location to the profile
                     prof.locationDate = prof.date;
                     prof.locationLon = interpLocLon;
                     prof.locationLat = interpLocLat;
                     prof.locationQc = g_decArgo_qcStrInterpolated;
                     
                     % set the profile updated flag if profile location is
                     % interpolated thanks to a new GPS received during the last
                     % cycle of the current decoding session (used to detect when a
                     % profile needs to be updated in GENERATE_NC_MONO_PROF = 2 mode)
                     if (~isempty(a_gpsLocReceivedCyNum)) % set for APF11 only
                        idNext = find(a_gpsLocDate == currentLocDate);
                        idPosUsed = find((a_gpsLocCycleNum == a_gpsLocCycleNum(idNext)) & (a_gpsLocQc == 1));
                        if (~any(a_gpsLocReceivedCyNum(idPosUsed) == a_gpsLocCycleNum(idNext)))
                           if ((any(a_gpsLocReceivedCyNum(idPosUsed) == max(a_gpsLocCycleNum))) || ...
                                 (a_gpsLocCycleNum(end) == a_gpsLocCycleNum(idNext)))
                              prof.updated = 1;
                           end
                        end
                     end
                  else
                     fprintf('WARNING: Float #%d Cycle #%d: time inconsistency detected while interpolating for profile location processing - profile not located\n', ...
                        g_decArgo_floatNum, ...
                        prof.cycleNumber);
                  end
               end
            end
         end
      else
         
         % no GPS fix exists
         
         if (prof.date ~= g_decArgo_dateDef)
            
            % we must interpolate between the existing GPS locations
            prevLocDate = g_decArgo_dateDef;
            nextLocDate = g_decArgo_dateDef;
            
            % find the previous GPS location
            idPrev = find((a_gpsLocDate <= prof.date) & (a_gpsLocQc == 1));
            if (~isempty(idPrev))
               % previous good GPS locations exist, use the last one
               [~, idMax] = max(a_gpsLocDate(idPrev));
               prevLocDate = a_gpsLocDate(idPrev(idMax));
               prevLocLon = a_gpsLocLon(idPrev(idMax));
               prevLocLat = a_gpsLocLat(idPrev(idMax));
            end
            
            % find the next GPS location
            idNext = find((a_gpsLocDate >= prof.date) & (a_gpsLocQc == 1));
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
                  prof.date);
               
               if (~isnan(interpLocLon))
                  % assign the interpolated location to the profile
                  prof.locationDate = prof.date;
                  prof.locationLon = interpLocLon;
                  prof.locationLat = interpLocLat;
                  prof.locationQc = g_decArgo_qcStrInterpolated;
                  
                  % set the profile updated flag if profile location is
                  % interpolated thanks to a new GPS received during the last
                  % cycle of the current decoding session (used to detect when a
                  % profile needs to be updated in GENERATE_NC_MONO_PROF = 2 mode)
                  if (~isempty(a_gpsLocReceivedCyNum)) % set for APF11 only
                     idNext = find(a_gpsLocDate == nextLocDate);
                     idPosUsed = find((a_gpsLocCycleNum == a_gpsLocCycleNum(idNext)) & (a_gpsLocQc == 1));
                     if (~any(a_gpsLocReceivedCyNum(idPosUsed) == a_gpsLocCycleNum(idNext)))
                        if ((any(a_gpsLocReceivedCyNum(idPosUsed) == max(a_gpsLocCycleNum))) || ...
                              (a_gpsLocCycleNum(end) == a_gpsLocCycleNum(idNext)))
                           prof.updated = 1;
                        end
                     end
                  end
               else
                  fprintf('WARNING: Float #%d Cycle #%d: time inconsistency detected while interpolating for profile location processing - profile not located\n', ...
                     g_decArgo_floatNum, ...
                     prof.cycleNumber);
               end
            end
         end
      end      
   end
   
   if (prof.locationDate == g_decArgo_dateDef)
      fprintf('WARNING: Float #%d Cycle #%d: Unable to find the location of the profile\n', ...
         g_decArgo_floatNum, ...
         prof.cycleNumber);
   end
   
   o_tabProfiles(idP) = prof;
end

return
