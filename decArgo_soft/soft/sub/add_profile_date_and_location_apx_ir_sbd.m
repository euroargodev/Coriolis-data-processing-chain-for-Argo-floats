% ------------------------------------------------------------------------------
% Add the date and location of a profile.
%
% SYNTAX :
%  [o_tabProfiles] = add_profile_date_and_location_apx_ir_sbd( ...
%    a_tabProfiles, a_gpsData, a_iridiumMailData, a_tabTrajNMeas, a_tabTrajNCycle)
%
% INPUT PARAMETERS :
%   a_tabProfiles     : input profiles
%   a_gpsData         : information on GPS locations
%   a_iridiumMailData : Iridium mail contents
%   a_tabTrajNMeas    : traj N_MEAS information
%   a_tabTrajNCycle   : traj N_CYCLE information
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
%   11/03/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = add_profile_date_and_location_apx_ir_sbd( ...
   a_tabProfiles, a_gpsData, a_iridiumMailData, a_tabTrajNMeas, a_tabTrajNCycle)

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
if (length(a_gpsData) > 11)
   a_gpsLocReceivedCyNum = a_gpsData{12};
end

% process all the profiles of the list
for idP = 1:length(o_tabProfiles)
   prof = o_tabProfiles(idP);
   
   if (prof.direction == 'A')
      
      % add profile date
      idCyNCycle = find([a_tabTrajNCycle.cycleNumber] == prof.cycleNumber);
      if (~isempty(idCyNCycle))
         
         % choice #1 - ASCEND_END_DATE
         if (~isempty(a_tabTrajNCycle(idCyNCycle).juldAscentEnd))
            prof.date = a_tabTrajNCycle(idCyNCycle).juldAscentEnd;
         else
            idCyNMeas = find([a_tabTrajNMeas.cycleNumber] == prof.cycleNumber);
            if (~isempty(idCyNMeas))
               if (~isempty(a_tabTrajNMeas(idCyNMeas).tabMeas))
                  
                  % choice #2 - last near surface measurement date (Navis only)
                  idNSSOM = find([a_tabTrajNMeas(idCyNMeas).tabMeas.measCode] == g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST);
                  if (~isempty(idNSSOM))
                     nearSurfMeasdates = [a_tabTrajNMeas(idCyNMeas).tabMeas(idNSSOM).juld];
                     if (~isempty(nearSurfMeasdates))
                        prof.date = max(nearSurfMeasdates);
                     end
                  end
                  
                  % choice #3 - first surface measurement date
                  if (prof.date == g_decArgo_dateDef)
                     idIASOM = find([a_tabTrajNMeas(idCyNMeas).tabMeas.measCode] == g_MC_InAirSingleMeasRelativeToTST);
                     if (~isempty(idIASOM))
                        surfMeasdates = [a_tabTrajNMeas(idCyNMeas).tabMeas(idIASOM).juld];
                        if (~isempty(surfMeasdates))
                           prof.date = min(surfMeasdates);
                        end
                     end
                  end
               end
            end
            
            if (prof.date == g_decArgo_dateDef)
               if (~isempty(a_tabTrajNCycle(idCyNCycle).juldFirstLocation))
                  % choice #4 - FIRST_LOCATION_DATE
                  prof.date = a_tabTrajNCycle(idCyNCycle).juldFirstLocation;
               elseif (~isempty(a_tabTrajNCycle(idCyNCycle).juldTransmissionStart))
                  % choice #5 - TRANSMISSION_START_DATE
                  prof.date = a_tabTrajNCycle(idCyNCycle).juldTransmissionStart;
               end
            end
         end
      end
      
      if (prof.date == g_decArgo_dateDef)
         % choice #5 - FIRST_MESSAGE_DATE
         [firstMsgTime, ~] = ...
            compute_first_last_msg_time_from_iridium_mail(a_iridiumMailData, prof.cycleNumber);
         if (firstMsgTime ~= g_decArgo_dateDef)
            prof.date = firstMsgTime;
         end
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
            if (~isempty(prof.dataAdj))
               idDef = find(prof.dataAdj(:, idMtime) == paramMtime.fillValue);
               idNoDef = find(prof.dataAdj(:, idMtime) ~= paramMtime.fillValue);
               prof.dataAdj(idDef, idMtime) = prof.paramList(idMtime).fillValue;
               prof.dataAdj(idNoDef, idMtime) = prof.dataAdj(idNoDef, idMtime) - prof.date;
            end
         else
            % we are not able to compute MTIME
            prof.data(:, idMtime) = ones(size(prof.data, 1), 1)*paramMtime.fillValue;
            if (~isempty(prof.dataAdj))
               prof.dataAdj(:, idMtime) = ones(size(prof.dataAdj, 1), 1)*paramMtime.fillValue;
            end
         end
      end
      
      % add profile location
      
      % select the GPS data to use
      idPosToUse = find((a_gpsLocCycleNum == prof.cycleNumber) & (a_gpsLocQc == 1));
      
      if (~isempty(idPosToUse))
         % set the profile updated flag if no GPS fix has been received during
         % the current cycle (used to detect when a profile needs to be updated
         % in GENERATE_NC_MONO_PROF = 2 mode)
         if (~isempty(a_gpsLocReceivedCyNum)) % set for APF11 only
            if (~any(a_gpsLocReceivedCyNum(idPosToUse) == prof.cycleNumber))
               if (prof.cycleNumber == max(a_gpsLocCycleNum))
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
               else
                  fprintf('WARNING: Float #%d Cycle #%d: time inconsistency detected while interpolating for profile location processing - profile not located\n', ...
                     g_decArgo_floatNum, ...
                     prof.cycleNumber);
               end
            end
         end
      end
      
      % we have not been able to set a location for the profile, we will use the
      % Iridium locations
      if (prof.locationDate == g_decArgo_dateDef)
         [locDate, locLon, locLat, locQc, lastCycleFlag] = ...
            compute_profile_location_from_iridium_locations_ir_sbd(a_iridiumMailData, prof.cycleNumber);
         if (~isempty(locDate))
            % assign the averaged Iridium location to the profile
            prof.locationDate = locDate;
            prof.locationLon = locLon;
            prof.locationLat = locLat;
            prof.locationQc = locQc;
            prof.iridiumLocation = 1;
            
            % positioning system
            prof.posSystem = 'IRIDIUM';
            
            % if the current cycle is the last received cycle, the location could
            % have been updated (if the last cycle data have been received in two
            % different rsync log files)
            if (lastCycleFlag == 1)
               prof.updated = 1;
            end
         end
      end
      
      if (prof.date == g_decArgo_dateDef)
         fprintf('WARNING: Float #%d Cycle #%d: Unable to find the date of the profile\n', ...
            g_decArgo_floatNum, ...
            prof.cycleNumber);
      end
      if (prof.locationDate == g_decArgo_dateDef)
         fprintf('WARNING: Float #%d Cycle #%d: Unable to find the location of the profile\n', ...
            g_decArgo_floatNum, ...
            prof.cycleNumber);
      end
   else
      fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in add_profile_date_and_location_apx_ir_sbd for profile direction ''%c''\n', ...
         g_decArgo_floatNum, ...
         prof.cycleNumber, ...
         prof.direction);
   end
   
   o_tabProfiles(idP) = prof;
end

return
