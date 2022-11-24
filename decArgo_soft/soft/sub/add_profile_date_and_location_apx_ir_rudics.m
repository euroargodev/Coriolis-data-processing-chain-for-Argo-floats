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
global g_MC_NearSurfaceSeriesOfMeas;
global g_MC_InAirSeriesOfMeas;

% QC flag values (char)
global g_decArgo_qcStrInterpolated;


% unpack the GPS input data
a_gpsLocCycleNum = a_gpsData{1};
a_gpsLocDate = a_gpsData{4};
a_gpsLocLon = a_gpsData{5};
a_gpsLocLat = a_gpsData{6};
a_gpsLocQc = a_gpsData{7};

% process all the profiles of the list
for idP = 1:length(o_tabProfiles)
   prof = o_tabProfiles(idP);
   
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
                  idNSSOM = find([o_tabTrajNMeas(idCyNMeas).tabMeas.measCode] == g_MC_NearSurfaceSeriesOfMeas);
                  if (~isempty(idNSSOM))
                     nearSurfMeasdates = [o_tabTrajNMeas(idCyNMeas).tabMeas(idNSSOM).juld];
                     if (~isempty(nearSurfMeasdates))
                        prof.date = max(nearSurfMeasdates);
                     end
                  end
                  
                  % choice #3 - first surface measurement date
                  if (prof.date == g_decArgo_dateDef)
                     idIASOM = find([o_tabTrajNMeas(idCyNMeas).tabMeas.measCode] == g_MC_InAirSeriesOfMeas);
                     if (~isempty(idIASOM))
                        surfMeasdates = [o_tabTrajNMeas(idCyNMeas).tabMeas(idIASOM).juld];
                        if (~isempty(surfMeasdates))
                           prof.date = min(surfMeasdates);
                        end
                     end
                  end
               end
            end
            
            if (prof.date == g_decArgo_dateDef)
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
            idPrev = find(a_gpsLocDate <= prof.date);
            if (~isempty(idPrev))
               idPrev = idPrev(end);
               prevLocDate = a_gpsLocDate(idPrev);
               prevLocLon = a_gpsLocLon(idPrev);
               prevLocLat = a_gpsLocLat(idPrev);
            end
            
            % find the next GPS location
            idNext = find(a_gpsLocDate >= prof.date);
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
                  prof.date);
               
               if (~isnan(interpLocLon))
                  % assign the interpolated location to the profile
                  prof.locationDate = prof.date;
                  prof.locationLon = interpLocLon;
                  prof.locationLat = interpLocLat;
                  prof.locationQc = g_decArgo_qcStrInterpolated;
               else
                  fprintf('WARNING: Float #%d Cycle #%d: time inconsistency detected while interpolating for profile location processing => profile not located\n', ...
                     g_decArgo_floatNum, ...
                     prof.cycleNumber);
               end
            end
         end
      end
      
      if (prof.date == g_decArgo_dateDef)
         fprintf('WARNING: Float #%d Cycle #%d: Unable to find the date of the profile\n', ...
            g_decArgo_floatNum, ...
            prof.cycleNumber);
      end
      if (prof.locationDate == g_decArgo_dateDef)
         fprintf('WARNING: Float #%d Cycle #%d: Unable to find the loction of the profile\n', ...
            g_decArgo_floatNum, ...
            prof.cycleNumber);
      end
   else
      fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in add_profile_date_and_location_apx_ir_rudics for profile direction ''%c''\n', ...
         g_decArgo_floatNum, ...
         prof.cycleNumber, ...
         prof.direction);
   end
   
   o_tabProfiles(idP) = prof;
end

return;
