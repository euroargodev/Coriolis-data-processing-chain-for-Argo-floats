% ------------------------------------------------------------------------------
% Compute NEMO cycle timings.
%
% SYNTAX :
%  [o_cycleTimeData, o_profileData] = process_cycle_times_nemo( ...
%    a_cycleTimeData, a_timeData, a_rafosData, a_profileData)
%
% INPUT PARAMETERS :
%   a_cycleTimeData : input cycle timings data
%   a_timeData      : decoded time data
%   a_rafosData     : decoded RAFOS data
%   a_profileData   : input profile data
%
% OUTPUT PARAMETERS :
%   o_cycleTimeData : output cycle timings data
%   o_profileData   : output profile data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleTimeData, o_profileData] = process_cycle_times_nemo( ...
   a_cycleTimeData, a_timeData, a_rafosData, a_profileData)
      
% output parameters initialization
o_cycleTimeData = a_cycleTimeData;
o_profileData = a_profileData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% array to store GPS data
global g_decArgo_gpsData;

% array to store Iridium data
global g_decArgo_iridiumData;

% float startup date
global g_decArgo_nemoStartupDate;


% store float STARTUP_DATE
if (~isempty(g_decArgo_nemoStartupDate))
   o_cycleTimeData.floatStartupDate = g_decArgo_nemoStartupDate;
end

% store decoded data in the time structure
for idT = 1:length(a_timeData)
   timeStruct = a_timeData{idT};
   if (isfield(o_cycleTimeData, timeStruct.label))
      timeValue = str2num(timeStruct.value);
      if (timeValue > 0)
         o_cycleTimeData.(timeStruct.label) = timeValue;
      end
   else
      fprintf('WARNING: Float #%d Cycle #%d: Don''t know what to do with time dedicated field ''%s'' => not considered\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         timeStruct.label);
   end
end

% process cycle timings (from counter based times)
if (~isempty(o_cycleTimeData.floatStartupDate))
   o_cycleTimeData.descentStartDate = o_cycleTimeData.floatStartupDate + o_cycleTimeData.xmit_descent_start_time/86400;
   o_cycleTimeData.parkStartDate = o_cycleTimeData.floatStartupDate + o_cycleTimeData.xmit_parking_start_time/86400;
   o_cycleTimeData.upcastStartDate = o_cycleTimeData.floatStartupDate + o_cycleTimeData.xmit_upcast_start_time/86400;
   o_cycleTimeData.ascentStartDate = o_cycleTimeData.floatStartupDate + o_cycleTimeData.xmit_ascent_start_time/86400;
   o_cycleTimeData.ascentEndDate = o_cycleTimeData.floatStartupDate + o_cycleTimeData.xmit_ascent_end_time/86400;
   o_cycleTimeData.surfaceStartDate = o_cycleTimeData.floatStartupDate + o_cycleTimeData.xmit_surface_start_time/86400;
end

% process RAFOS dates
if (~isempty(a_rafosData))
   if (~isempty(a_rafosData.dates))
      if (~isempty(o_cycleTimeData.parkStartDate) && (min(a_rafosData.dates) < o_cycleTimeData.parkStartDate))
         fprintf('WARNING: Float #%d Cycle #%d: First RAFOS date (%s) is before PARK_START_TIME (%s)\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            julian_2_gregorian_dec_argo(min(a_rafosData.dates)), ...
            julian_2_gregorian_dec_argo(o_cycleTimeData.parkStartDate));
      end
      %       if (~isempty(o_cycleTimeData.upcastStartDate) && (max(a_rafosData.dates) < o_cycleTimeData.upcastStartDate))
      %          fprintf('WARNING: Float #%d Cycle #%d: Last RAFOS date (%s) is before UPCAST_START_TIME (%s)\n', ...
      %             g_decArgo_floatNum, ...
      %             g_decArgo_cycleNum, ...
      %             julian_2_gregorian_dec_argo(max(a_rafosData.dates)), ...
      %             julian_2_gregorian_dec_argo(o_cycleTimeData.upcastStartDate));
      %       end
      
      o_cycleTimeData.rafosDate = a_rafosData.dates;
      idPres = find(strcmp({a_rafosData.paramList.name}, 'PRES') == 1, 1);
      o_cycleTimeData.rafosPres = a_rafosData.data(:, idPres);
   end
end

% process profile dates
if (~isempty(o_profileData))
   if (~isempty(o_profileData.dates))
      if (~isempty(o_cycleTimeData.ascentStartDate))
         idProfDate = find(o_profileData.dates ~= o_profileData.dateList.fillValue);
         day = fix(o_cycleTimeData.ascentStartDate);
         if (day + min(o_profileData.dates(idProfDate)) < o_cycleTimeData.ascentStartDate)
            day = day + 1;
         end
         o_profileData.dates(idProfDate) = o_profileData.dates(idProfDate)/24 + day;
         o_cycleTimeData.profileDate = o_profileData.dates(idProfDate);
         idPres = find(strcmp({o_profileData.paramList.name}, 'PRES') == 1, 1);
         o_cycleTimeData.profilePres = o_profileData.data(:, idPres);
      end
   end
end

% store GPS dates
if (~isempty(g_decArgo_gpsData))
   gpsLocCycleNum = g_decArgo_gpsData{1};
   gpsLocDate = g_decArgo_gpsData{4};
   
   idF = find(gpsLocCycleNum == g_decArgo_cycleNum);
   o_cycleTimeData.gpsDate = gpsLocDate(idF);
end

% store Iridium dates
SURFACE_START_TO_LAST_IRIDIUM_MAX_DELAY_IN_DAYS = 1; % it is more than 0.5 days for float #7900413
if (~isempty(g_decArgo_iridiumData))
   if (~isempty(o_cycleTimeData.surfaceStartDate))
      idAfter = find(abs([g_decArgo_iridiumData.timeOfSessionJuld] - o_cycleTimeData.surfaceStartDate) < SURFACE_START_TO_LAST_IRIDIUM_MAX_DELAY_IN_DAYS, 1, 'first');
      timeOfSessionJuld = [g_decArgo_iridiumData(idAfter:end).timeOfSessionJuld];
      idF = find(diff(timeOfSessionJuld) > 1, 1);
      if (~isempty(idF))
         [g_decArgo_iridiumData(idAfter:idAfter+idF-1).cycleNumber] = deal(g_decArgo_cycleNum);
         o_cycleTimeData.iridiumDate = [g_decArgo_iridiumData(idAfter:idAfter+idF-1).timeOfSessionJuld];
      else
         [g_decArgo_iridiumData(idAfter:end).cycleNumber] = deal(g_decArgo_cycleNum);
         o_cycleTimeData.iridiumDate = [g_decArgo_iridiumData(idAfter:end).timeOfSessionJuld];
      end
   end
end

if (0)
   if (isempty(o_cycleTimeData.gpsDate) && isempty(o_cycleTimeData.iridiumDate))
      fprintf('DELAYED CYCLE *************************************************\n');
   else
      fprintf('SURFACED CYCLE\n');
   end
   fprintf('   STARTUP_DATE       %s\n', julian_2_gregorian_dec_argo(o_cycleTimeData.floatStartupDate));
   fprintf('   DESCENT_START_DATE %s\n', julian_2_gregorian_dec_argo(o_cycleTimeData.descentStartDate));
   fprintf('   PARK_START_DATE    %s\n', julian_2_gregorian_dec_argo(o_cycleTimeData.parkStartDate));
   fprintf('   UPCAST_START_DATE  %s\n', julian_2_gregorian_dec_argo(o_cycleTimeData.upcastStartDate));
   fprintf('   ASCENT_START_DATE  %s\n', julian_2_gregorian_dec_argo(o_cycleTimeData.ascentStartDate));
   fprintf('   ASCENT_END_DATE    %s\n', julian_2_gregorian_dec_argo(o_cycleTimeData.ascentEndDate));
   fprintf('   SURFACE_START_DATE %s\n', julian_2_gregorian_dec_argo(o_cycleTimeData.surfaceStartDate));
   fprintf('   RAFOS_DATES \n');
   for id = 1:length(o_cycleTimeData.rafosDate)
      fprintf('      RAFOS#%d - %s (%g dbar)\n', id, julian_2_gregorian_dec_argo(o_cycleTimeData.rafosDate(id)), o_cycleTimeData.rafosPres(id));
   end
   fprintf('   PROFILE_DATES \n');
   for id = 1:length(o_cycleTimeData.profileDate)
      fprintf('      PROFILE#%d - %s (%g dbar)\n', id, julian_2_gregorian_dec_argo(o_cycleTimeData.profileDate(id)), o_cycleTimeData.profilePres(id));
   end   
   fprintf('   GPS_DATES \n');
   for id = 1:length(o_cycleTimeData.gpsDate)
      fprintf('      GPS#%d - %s\n', id, julian_2_gregorian_dec_argo(o_cycleTimeData.gpsDate(id)));
   end   
   fprintf('   IRIDIUM_DATES \n');
   for id = 1:length(o_cycleTimeData.iridiumDate)
      fprintf('      IRIDIUM#%d - %s\n', id, julian_2_gregorian_dec_argo(o_cycleTimeData.iridiumDate(id)));
   end   
end

return
