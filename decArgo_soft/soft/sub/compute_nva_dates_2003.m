% ------------------------------------------------------------------------------
% Compute the main dates of a NOVA float cycle.
%
% SYNTAX :
%  [o_cycleStartDate, o_cycleStartDateAdj, ...
%    o_descentToParkStartDate, o_descentToParkStartDateAdj, ...
%    o_firstStabDate, o_firstStabDateAdj, o_firstStabPres, ...
%    o_descentToParkEndDate, o_descentToParkEndDateAdj, ...
%    o_descentToProfStartDate, o_descentToProfStartDateAdj, ...
%    o_descentToProfEndDate, o_descentToProfEndDateAdj, ...
%    o_ascentStartDate, o_ascentStartDateAdj, ...
%    o_ascentEndDate, o_ascentEndDateAdj, ...
%    o_gpsDate, o_gpsDateAdj, ...
%    o_firstMessageDate, o_lastMessageDate, ...
%    o_floatClockDrift] = compute_nva_dates_2003(a_tabTech, a_deepCycle)
%
% INPUT PARAMETERS :
%   a_tabTech   : decoded technical data
%   a_deepCycle : deep cycle flag
%
% OUTPUT PARAMETERS :
%   o_cycleStartDate            : cycle start date
%   o_cycleStartDateAdj         : cycle start adjusted date
%   o_descentToParkStartDate    : descent to park start date
%   o_descentToParkStartDateAdj : descent to park start adjusted date
%   o_firstStabDate             : first stabilisation date
%   o_firstStabDateAdj          : first stabilisation adjusted date
%   o_firstStabPres             : first stabilisation pressure
%   o_descentToParkEndDate      : descent to park end date
%   o_descentToParkEndDateAdj   : descent to park end adjusted date
%   o_descentToProfStartDate    : descent to profile start date
%   o_descentToProfStartDateAdj : descent to profile start adjusted date
%   o_descentToProfEndDate      : descent to profile end date
%   o_descentToProfEndDateAdj   : descent to profile end adjusted date
%   o_ascentStartDate           : ascent start date
%   o_ascentStartDateAdj        : ascent start adjusted date
%   o_ascentEndDate             : ascent end date
%   o_ascentEndDateAdj          : ascent end adjusted date
%   o_gpsDate                   : date associated to the GPS location
%   o_gpsDateAdj                : adjusted date associated to the GPS location
%   o_firstMessageDate          : first date of received emails
%   o_lastMessageDate           : last date of received emails
%   o_floatClockDrift           : float clock offset for the cycle
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/08/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleStartDate, o_cycleStartDateAdj, ...
   o_descentToParkStartDate, o_descentToParkStartDateAdj, ...
   o_firstStabDate, o_firstStabDateAdj, o_firstStabPres, ...
   o_descentToParkEndDate, o_descentToParkEndDateAdj, ...
   o_descentToProfStartDate, o_descentToProfStartDateAdj, ...
   o_descentToProfEndDate, o_descentToProfEndDateAdj, ...
   o_ascentStartDate, o_ascentStartDateAdj, ...
   o_ascentEndDate, o_ascentEndDateAdj, ...
   o_gpsDate, o_gpsDateAdj, ...
   o_firstMessageDate, o_lastMessageDate, ...
   o_floatClockDrift] = compute_nva_dates_2003(a_tabTech, a_deepCycle)

% output parameters initialization
o_cycleStartDate = [];
o_cycleStartDateAdj = [];
o_descentToParkStartDate = [];
o_descentToParkStartDateAdj = [];
o_firstStabDate = [];
o_firstStabDateAdj = [];
o_firstStabPres = [];
o_descentToParkEndDate = [];
o_descentToParkEndDateAdj = [];
o_descentToProfStartDate = [];
o_descentToProfStartDateAdj = [];
o_descentToProfEndDate = [];
o_descentToProfEndDateAdj = [];
o_ascentStartDate = [];
o_ascentStartDateAdj = [];
o_ascentEndDate = [];
o_ascentEndDateAdj = [];
o_gpsDate = [];
o_gpsDateAdj = [];
o_firstMessageDate = [];
o_lastMessageDate = [];
o_floatClockDrift = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_dateDef;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;

% cycle timings storage
global g_decArgo_timeData;

% pre-decoding data storage
global g_decArgo_preDecodedData;

% EOL mode
global g_decArgo_eolMode;

% final EOL flag (float in EOL mode and cycle number set to 256 by the decoder)
global g_decArgo_finalEolMode;


ID_OFFSET = 1;

% technical message
if (g_decArgo_finalEolMode == 0)
   if (size(a_tabTech, 1) > 1)
      fprintf('ERROR: Float #%d cycle #%d: BUFFER anomaly (%d tech message in the buffer) => using the last one\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         size(a_tabTech, 1));
      a_tabTech = a_tabTech(end, :);
   end
   
   if (size(a_tabTech, 1) == 1)
      id = 1;
      
      % create a structure to store the cycle timings
      cycleTimeStruct = get_nva_cycle_time_init_struct;
      
      % retrieve the Iridium message times of the current cycle
      [o_firstMessageDate, o_lastMessageDate] = ...
         compute_first_last_msg_time_from_iridium_mail(g_decArgo_iridiumMailData, g_decArgo_cycleNum);
      
      % retrieve the Iridium message times of the previous cycle
      [~, o_lastMessageDateOfPrevCycle] = ...
         compute_first_last_msg_time_from_iridium_mail(g_decArgo_iridiumMailData, g_decArgo_cycleNum-1);
      
      % compute GPS date
      if ~((a_tabTech(id, 39+ID_OFFSET) == 0) && ... % when DLF == TLF == 0 the GPS time is not consistent and the lat/lon are duplicated from the last good previous value
            (a_tabTech(id, 40+ID_OFFSET) == 0))
         
         if (~g_decArgo_eolMode)
            [dayNum, day, month, year, hour, min, sec] = format_juld_dec_argo(o_firstMessageDate);
         else
            [dayNum, day, month, year, hour, min, sec] = format_juld_dec_argo(a_tabTech(id, end)); % in EOL mode, FMT could be far from current TECH msg
         end
         if (day < a_tabTech(id, 39+ID_OFFSET))
            if (month > 1)
               month = month - 1;
            else
               month = 12;
               year = year - 1;
            end
         end
         o_gpsDate = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %s', ...
            year, month, a_tabTech(id, 39+ID_OFFSET), format_time_dec_argo(a_tabTech(id, 40+ID_OFFSET))));
      else
         
         % unable to get a GPS fix
         o_gpsDate = g_decArgo_dateDef;
      end
      
      % get the record id to retrieve SBDT of the current cycle
      if (g_decArgo_cycleNum < 256)
         idForSbdt = find((g_decArgo_preDecodedData.cycleNum == g_decArgo_cycleNum) & ...
            (g_decArgo_preDecodedData.used == 0));
      else
         idForSbdt = find((g_decArgo_preDecodedData.cycleNum == g_decArgo_cycleNum-1) & ...
            (g_decArgo_preDecodedData.used == 0));
      end
      if (~isempty(idForSbdt))
         idForSbdt = idForSbdt(1);
         g_decArgo_preDecodedData.used(idForSbdt) = 1;
      end
      
      % estimate clock offset
      o_gpsDateAdj = o_gpsDate;
      if (o_gpsDate ~= g_decArgo_dateDef)
         
         % use SBDT of the current cycle
         if (~isempty(idForSbdt))
            
            sbdt = g_decArgo_preDecodedData.sbdt(idForSbdt);
            if (~g_decArgo_eolMode)
               o_floatClockDrift = o_gpsDate + sbdt/86400 - o_firstMessageDate;
            else
               o_floatClockDrift = o_gpsDate + sbdt/86400 - a_tabTech(id, end);
            end
            %          fprintf('Float %d cycle %d: clock offset %s\n', ...
            %             g_decArgo_floatNum, g_decArgo_cycleNum, format_time_dec_argo(o_floatClockDrift*24));
            
            if (abs(o_floatClockDrift) > double(1/24))
               o_floatClockDrift = [];
            else
               o_gpsDateAdj = o_gpsDate - o_floatClockDrift;
            end
         end
      end
      
      o_cycleStartDate = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %s', ...
         a_tabTech(id, (47:-1:45)+ID_OFFSET), format_time_dec_argo(a_tabTech(id, 44+ID_OFFSET))));
      % clock offset is 0 at o_cycleStartDate (UTC) and o_floatClockDrift at o_gpsDate (UTC)
      o_cycleStartDateAdj = o_cycleStartDate;
      
      % store the cycle timings
      cycleTimeStruct.gpsTime = o_gpsDate;
      cycleTimeStruct.gpsTimeAdj = o_gpsDateAdj;
      cycleTimeStruct.firstMessageTime = o_firstMessageDate;
      cycleTimeStruct.lastMessageTime = o_lastMessageDate;
      cycleTimeStruct.cycleStartTime = o_cycleStartDate;
      cycleTimeStruct.cycleStartTimeAdj = o_cycleStartDateAdj;
      cycleTimeStruct.clockDrift = o_floatClockDrift;
      
      if (a_deepCycle == 1)
         
         if (a_tabTech(id, 28+ID_OFFSET) == 0)
            
            if (o_lastMessageDateOfPrevCycle ~= g_decArgo_dateDef)
               o_descentToParkStartDate = o_lastMessageDateOfPrevCycle + a_tabTech(id, 7+ID_OFFSET)/3/1440;
            else
               o_descentToParkStartDate = o_cycleStartDateAdj + a_tabTech(id, 7+ID_OFFSET)/3/1440;
            end
            o_descentToParkStartDateAdj = o_descentToParkStartDate - get_nva_clock_offset(o_descentToParkStartDate, g_decArgo_cycleNum, o_floatClockDrift, o_cycleStartDateAdj, o_gpsDateAdj);
            
            o_firstStabDate = fix(o_cycleStartDateAdj) + a_tabTech(id, 2+ID_OFFSET)/24;
            o_firstStabDateAdj = o_firstStabDate - get_nva_clock_offset(o_firstStabDate, g_decArgo_cycleNum, o_floatClockDrift, o_cycleStartDateAdj, o_gpsDateAdj);
            if (o_firstStabDateAdj < o_cycleStartDateAdj)
               o_firstStabDate = fix(o_cycleStartDateAdj) + a_tabTech(id, 2+ID_OFFSET)/24 + 1;
               o_firstStabDateAdj = o_firstStabDate - get_nva_clock_offset(o_firstStabDate, g_decArgo_cycleNum, o_floatClockDrift, o_cycleStartDateAdj, o_gpsDateAdj);
            end
            o_firstStabPres = a_tabTech(id, 15+ID_OFFSET)*10;
            
            o_descentToParkEndDate = fix(o_firstStabDateAdj) + a_tabTech(id, 1+ID_OFFSET)/24;
            o_descentToParkEndDateAdj = o_descentToParkEndDate - get_nva_clock_offset(o_descentToParkEndDate, g_decArgo_cycleNum, o_floatClockDrift, o_cycleStartDateAdj, o_gpsDateAdj);
            if (o_descentToParkEndDateAdj < o_firstStabDateAdj)
               o_descentToParkEndDate = fix(o_firstStabDateAdj) + a_tabTech(id, 1+ID_OFFSET)/24 + 1;
               o_descentToParkEndDateAdj = o_descentToParkEndDate - get_nva_clock_offset(o_descentToParkEndDate, g_decArgo_cycleNum, o_floatClockDrift, o_cycleStartDateAdj, o_gpsDateAdj);
            end
         else
            
            % in case of surface grounding these transmitted times are not relevant
            o_descentToParkStartDate = g_decArgo_dateDef;
            o_descentToParkStartDateAdj = g_decArgo_dateDef;
            o_firstStabDate = g_decArgo_dateDef;
            o_firstStabDateAdj = g_decArgo_dateDef;
            o_descentToParkEndDate = g_decArgo_dateDef;
            o_descentToParkEndDateAdj = g_decArgo_dateDef;
         end
         
         o_ascentEndDate = fix(o_firstMessageDate) + a_tabTech(id, 6+ID_OFFSET)/24;
         o_ascentEndDateAdj = o_ascentEndDate - get_nva_clock_offset(o_ascentEndDate, g_decArgo_cycleNum, o_floatClockDrift, o_cycleStartDateAdj, o_gpsDateAdj);
         if (o_ascentEndDateAdj > o_firstMessageDate)
            o_ascentEndDate = fix(o_firstMessageDate) + a_tabTech(id, 6+ID_OFFSET)/24 - 1;
            o_ascentEndDateAdj = o_ascentEndDate - get_nva_clock_offset(o_ascentEndDate, g_decArgo_cycleNum, o_floatClockDrift, o_cycleStartDateAdj, o_gpsDateAdj);
         end
         
         o_ascentStartDate = fix(o_ascentEndDateAdj) + a_tabTech(id, 5+ID_OFFSET)/24;
         o_ascentStartDateAdj = o_ascentStartDate - get_nva_clock_offset(o_ascentStartDate, g_decArgo_cycleNum, o_floatClockDrift, o_cycleStartDateAdj, o_gpsDateAdj);
         if (o_ascentStartDateAdj > o_ascentEndDateAdj)
            o_ascentStartDate = fix(o_ascentEndDateAdj) + a_tabTech(id, 5+ID_OFFSET)/24 - 1;
            o_ascentStartDateAdj = o_ascentStartDate - get_nva_clock_offset(o_ascentStartDate, g_decArgo_cycleNum, o_floatClockDrift, o_cycleStartDateAdj, o_gpsDateAdj);
         end
         
         if (a_tabTech(id, 28+ID_OFFSET) == 0)
            
            [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
            parkToProfTimeout = get_config_value('CONFIG_PM08', configNames, configValues);
            if (~isempty(parkToProfTimeout))
               
               % if PM08 is available we estimate the PET as AST - PM08 and use
               % this estimate to compute the day of PET
               estimatedDescentToProfStartDate = o_ascentStartDateAdj - parkToProfTimeout/24;
               o_descentToProfStartDate = round(estimatedDescentToProfStartDate) + a_tabTech(id, 3+ID_OFFSET)/24;
               o_descentToProfStartDate = o_descentToProfStartDate - ...
                  (round(o_descentToProfStartDate)-round(estimatedDescentToProfStartDate));
               o_descentToProfStartDateAdj = o_descentToProfStartDate - get_nva_clock_offset(o_descentToProfStartDate, g_decArgo_cycleNum, o_floatClockDrift, o_cycleStartDateAdj, o_gpsDateAdj);
               
               if (o_descentToProfStartDateAdj < o_descentToParkEndDateAdj)
                  o_descentToProfStartDate = round(estimatedDescentToProfStartDate) + a_tabTech(id, 3+ID_OFFSET)/24;
                  o_descentToProfStartDate = o_descentToProfStartDate - ...
                     (round(o_descentToProfStartDate)-round(estimatedDescentToProfStartDate)) + 1;
                  o_descentToProfStartDateAdj = o_descentToProfStartDate - get_nva_clock_offset(o_descentToProfStartDate, g_decArgo_cycleNum, o_floatClockDrift, o_cycleStartDateAdj, o_gpsDateAdj);
               end
               
               o_descentToProfEndDate = fix(o_descentToProfStartDateAdj) + a_tabTech(id, 4+ID_OFFSET)/24;
               o_descentToProfEndDateAdj = o_descentToProfEndDate - get_nva_clock_offset(o_descentToProfEndDate, g_decArgo_cycleNum, o_floatClockDrift, o_cycleStartDateAdj, o_gpsDateAdj);
               if (o_descentToProfEndDateAdj < o_descentToProfStartDateAdj)
                  o_descentToProfEndDate = fix(o_descentToProfStartDateAdj) + a_tabTech(id, 4+ID_OFFSET)/24 + 1;
                  o_descentToProfEndDateAdj = o_descentToProfEndDate - get_nva_clock_offset(o_descentToProfEndDate, g_decArgo_cycleNum, o_floatClockDrift, o_cycleStartDateAdj, o_gpsDateAdj);
               end
            else
               
               % if PM08 is not available we compute DDET from AST (this wil not
               % succeed if PM08 is more than (or equal to) 24h)
               
               o_descentToProfEndDate = fix(o_ascentStartDateAdj) + a_tabTech(id, 4+ID_OFFSET)/24;
               o_descentToProfEndDateAdj = o_descentToProfEndDate - get_nva_clock_offset(o_descentToProfEndDate, g_decArgo_cycleNum, o_floatClockDrift, o_cycleStartDateAdj, o_gpsDateAdj);
               if (o_descentToProfEndDateAdj > o_ascentStartDateAdj)
                  o_descentToProfEndDate = fix(o_ascentStartDateAdj) + a_tabTech(id, 4+ID_OFFSET)/24 - 1;
                  o_descentToProfEndDateAdj = o_descentToProfEndDate - get_nva_clock_offset(o_descentToProfEndDate, g_decArgo_cycleNum, o_floatClockDrift, o_cycleStartDateAdj, o_gpsDateAdj);
               end
               
               o_descentToProfStartDate = fix(o_descentToProfEndDateAdj) + a_tabTech(id, 3+ID_OFFSET)/24;
               o_descentToProfStartDateAdj = o_descentToProfStartDate - get_nva_clock_offset(o_descentToProfStartDate, g_decArgo_cycleNum, o_floatClockDrift, o_cycleStartDateAdj, o_gpsDateAdj);
               if (o_descentToProfStartDateAdj > o_descentToProfEndDateAdj)
                  o_descentToProfStartDate = fix(o_descentToProfEndDateAdj) + a_tabTech(id, 3+ID_OFFSET)/24 - 1;
                  o_descentToProfStartDateAdj = o_descentToProfStartDate - get_nva_clock_offset(o_descentToProfStartDate, g_decArgo_cycleNum, o_floatClockDrift, o_cycleStartDateAdj, o_gpsDateAdj);
               end
            end
         else
            
            % in case of surface grounding these transmitted times are not relevant
            o_descentToProfStartDate = g_decArgo_dateDef;
            o_descentToProfStartDateAdj = g_decArgo_dateDef;
            o_descentToProfEndDate = g_decArgo_dateDef;
            o_descentToProfEndDateAdj = g_decArgo_dateDef;
         end
         
         % store the cycle timings
         cycleTimeStruct.numberOfValveActionAtSurface = a_tabTech(id, 7+ID_OFFSET);
         cycleTimeStruct.descentToParkStartTime = o_descentToParkStartDate;
         cycleTimeStruct.descentToParkStartTimeAdj = o_descentToParkStartDateAdj;
         if (updated_time(o_firstStabDate, 'firstStabilizationTime', g_decArgo_floatNum))
            cycleTimeStruct.firstStabilizationTime = o_firstStabDate;
            cycleTimeStruct.firstStabilizationTimeAdj = o_firstStabDateAdj;
            cycleTimeStruct.firstStabilizationPres = o_firstStabPres;
         end
         if (updated_time(o_descentToParkEndDate, 'descentToParkEndTime', g_decArgo_floatNum))
            cycleTimeStruct.descentToParkEndTime = o_descentToParkEndDate;
            cycleTimeStruct.descentToParkEndTimeAdj = o_descentToParkEndDateAdj;
         end
         cycleTimeStruct.descentToProfStartTime = o_descentToProfStartDate;
         cycleTimeStruct.descentToProfStartTimeAdj = o_descentToProfStartDateAdj;
         if (updated_time(o_descentToProfEndDate, 'descentToProfEndTime', g_decArgo_floatNum))
            cycleTimeStruct.descentToProfEndTime = o_descentToProfEndDate;
            cycleTimeStruct.descentToProfEndTimeAdj = o_descentToProfEndDateAdj;
         end
         cycleTimeStruct.ascentStartTime = o_ascentStartDate;
         cycleTimeStruct.ascentStartTimeAdj = o_ascentStartDateAdj;
         cycleTimeStruct.ascentEndTime = o_ascentEndDate;
         cycleTimeStruct.ascentEndTimeAdj = o_ascentEndDateAdj;
         cycleTimeStruct.timeToGpsFix = a_tabTech(id, 48+ID_OFFSET);
      end
      
      % store the cycle timings of the current cycle
      if (~isempty(g_decArgo_timeData))
         % check that current cycle times are not already stored
         if (any([g_decArgo_timeData.cycleNum] == g_decArgo_cycleNum))
            % Ex: 6903179 #238
            fprintf('INFO: Float #%d cycle #%d: EOL mode detected\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum);
            
            g_decArgo_timeData.cycleNum = [g_decArgo_timeData.cycleNum g_decArgo_cycleNum];
            g_decArgo_timeData.cycleTime = [g_decArgo_timeData.cycleTime cycleTimeStruct];
            %          idCycleStruct = find([g_decArgo_timeData.cycleNum] == g_decArgo_cycleNum);
            %          g_decArgo_timeData.cycleTime(idCycleStruct) = cycleTimeStruct;
         else
            g_decArgo_timeData.cycleNum = [g_decArgo_timeData.cycleNum g_decArgo_cycleNum];
            g_decArgo_timeData.cycleTime = [g_decArgo_timeData.cycleTime cycleTimeStruct];
         end
      else
         g_decArgo_timeData.cycleNum = g_decArgo_cycleNum;
         g_decArgo_timeData.cycleTime = cycleTimeStruct;
      end
   else
      % if no tech msg has been received (ex: 6903179 #161)
      
      if (~isempty(g_decArgo_timeData))
         if (~any([g_decArgo_timeData.cycleNum] == g_decArgo_cycleNum))
            
            % create a structure to store the cycle timings
            cycleTimeStruct = get_nva_cycle_time_init_struct;
            
            % retrieve the Iridium message times of the current cycle
            [o_firstMessageDate, o_lastMessageDate] = ...
               compute_first_last_msg_time_from_iridium_mail(g_decArgo_iridiumMailData, g_decArgo_cycleNum);
            
            % retrieve the Iridium message times of the previous cycle
            [~, o_lastMessageDateOfPrevCycle] = ...
               compute_first_last_msg_time_from_iridium_mail(g_decArgo_iridiumMailData, g_decArgo_cycleNum-1);
            
            % store the cycle timings
            cycleTimeStruct.firstMessageTime = o_firstMessageDate;
            cycleTimeStruct.lastMessageTime = o_lastMessageDate;
            
            % store the cycle timings of the current cycle
            g_decArgo_timeData.cycleNum = [g_decArgo_timeData.cycleNum g_decArgo_cycleNum];
            g_decArgo_timeData.cycleTime = [g_decArgo_timeData.cycleTime cycleTimeStruct];
         end
      end
   end
else
   
   % when final EOL mode is detected we only consider GPS fix
   
   % create a structure to store the cycle timings
   cycleTimeStruct = get_nva_cycle_time_init_struct;
   
   % retrieve the Iridium message times of the current cycle
   [o_firstMessageDate, o_lastMessageDate] = ...
      compute_first_last_msg_time_from_iridium_mail(g_decArgo_iridiumMailData, g_decArgo_cycleNum);
   
   for idTech = 1:size(a_tabTech, 1)
      
      % compute GPS date
      if ~((a_tabTech(idTech, 39+ID_OFFSET) == 0) && ... % when DLF == TLF == 0 the GPS time is not consistent and the lat/lon are duplicated from the last good previous value
            (a_tabTech(idTech, 40+ID_OFFSET) == 0))
         
         [dayNum, day, month, year, hour, min, sec] = format_juld_dec_argo(a_tabTech(idTech, end)); % in EOL mode, FMT could be far from current TECH msg
         if (day < a_tabTech(idTech, 39+ID_OFFSET))
            if (month > 1)
               month = month - 1;
            else
               month = 12;
               year = year - 1;
            end
         end
         o_gpsDate = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %s', ...
            year, month, a_tabTech(idTech, 39+ID_OFFSET), format_time_dec_argo(a_tabTech(idTech, 40+ID_OFFSET))));
         
         % get the record id to retrieve SBDT of the current cycle
         idForSbdt = find((g_decArgo_preDecodedData.cycleNum == g_decArgo_cycleNum-1) & ...
            (g_decArgo_preDecodedData.used == 0));
         
         if (~isempty(idForSbdt))
            idForSbdt = idForSbdt(1);
            g_decArgo_preDecodedData.used(idForSbdt) = 1;
         end
         
         % estimate clock offset
         o_gpsDateAdj = o_gpsDate;
         
         % use SBDT of the current cycle
         if (~isempty(idForSbdt))
            
            sbdt = g_decArgo_preDecodedData.sbdt(idForSbdt);
            o_floatClockDrift = o_gpsDate + sbdt/86400 - a_tabTech(idTech, end);
            
            %          fprintf('Float %d cycle %d: clock offset %s\n', ...
            %             g_decArgo_floatNum, g_decArgo_cycleNum, format_time_dec_argo(o_floatClockDrift*24));
            
            if (abs(o_floatClockDrift) > double(1/24))
               o_floatClockDrift = [];
            else
               o_gpsDateAdj = o_gpsDate - o_floatClockDrift;
            end
         end
      end
      
      % store the cycle timings
      cycleTimeStruct.gpsTime = o_gpsDate;
      cycleTimeStruct.gpsTimeAdj = o_gpsDateAdj;
      cycleTimeStruct.firstMessageTime = o_firstMessageDate;
      cycleTimeStruct.lastMessageTime = o_lastMessageDate;
      cycleTimeStruct.clockDrift = o_floatClockDrift;
      
      g_decArgo_timeData.cycleNum = [g_decArgo_timeData.cycleNum g_decArgo_cycleNum];
      g_decArgo_timeData.cycleTime = [g_decArgo_timeData.cycleTime cycleTimeStruct];
   end
end

print = 0;
if (print == 1)
   
   fprintf('Float #%d cycle #%d:\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   if (~isempty(o_floatClockDrift))
      fprintf('CLOCK OFFSET               : %s\n', ...
         format_time_dec_argo(o_floatClockDrift*24));
   else
      fprintf('CLOCK OFFSET               : UNDEF\n');
   end
   if (~isempty(o_cycleStartDateAdj))
      fprintf('CYCLE START DATE           : %s\n', ...
         julian_2_gregorian_dec_argo(o_cycleStartDateAdj));
   else
      fprintf('CYCLE START DATE           : UNDEF\n');
   end
   if (~isempty(o_descentToParkStartDateAdj))
      fprintf('DESCENT TO PARK START DATE : %s\n', ...
         julian_2_gregorian_dec_argo(o_descentToParkStartDateAdj));
   else
      fprintf('DESCENT TO PARK START DATE : UNDEF\n');
   end
   if (~isempty(o_firstStabDateAdj))
      fprintf('FIRST STAB DATE            : %s (%d dbar)\n', ...
         julian_2_gregorian_dec_argo(o_firstStabDateAdj), o_firstStabPres);
   else
      fprintf('FIRST STAB DATE            : UNDEF\n');
   end
   if (~isempty(o_descentToParkEndDateAdj))
      fprintf('DESCENT TO PARK END DATE   : %s\n', ...
         julian_2_gregorian_dec_argo(o_descentToParkEndDateAdj));
   else
      fprintf('DESCENT TO PARK END DATE   : UNDEF\n');
   end
   if (~isempty(o_descentToProfStartDateAdj))
      fprintf('DESCENT TO PROF START DATE : %s\n', ...
         julian_2_gregorian_dec_argo(o_descentToProfStartDateAdj));
   else
      fprintf('DESCENT TO PROF START DATE : UNDEF\n');
   end
   if (~isempty(o_descentToProfEndDateAdj))
      fprintf('DESCENT TO PROF END DATE   : %s\n', ...
         julian_2_gregorian_dec_argo(o_descentToProfEndDateAdj));
   else
      fprintf('DESCENT TO PROF END DATE   : UNDEF\n');
   end
   if (~isempty(o_ascentStartDateAdj))
      fprintf('ASCENT START DATE          : %s\n', ...
         julian_2_gregorian_dec_argo(o_ascentStartDateAdj));
   else
      fprintf('ASCENT START DATE          : UNDEF\n');
   end
   if (~isempty(o_ascentEndDateAdj))
      fprintf('ASCENT END DATE            : %s\n', ...
         julian_2_gregorian_dec_argo(o_ascentEndDateAdj));
   else
      fprintf('ASCENT END DATE            : UNDEF\n');
   end
   if (~isempty(o_gpsDateAdj))
      fprintf('GPS DATE                   : %s\n', ...
         julian_2_gregorian_dec_argo(o_gpsDateAdj));
   else
      fprintf('GPS DATE                   : UNDEF\n');
   end
   fprintf('FIRST MESSAGE DATE         : %s\n', ...
      julian_2_gregorian_dec_argo(o_firstMessageDate));
   fprintf('LAST MESSAGE DATE          : %s\n', ...
      julian_2_gregorian_dec_argo(o_lastMessageDate));
end

check = 0;
if (check == 1)
   
   % retrieve cycle timings of the previous cycle
   lastMessageTimePrevCy = g_decArgo_dateDef;
   idCycleStructPrev = find([g_decArgo_timeData.cycleNum] == g_decArgo_cycleNum-1);
   if (~isempty(idCycleStructPrev))
      lastMessageTimePrevCy = g_decArgo_timeData.cycleTime(idCycleStructPrev).lastMessageTime;
   end
   cycleStartTime = cycleTimeStruct.cycleStartTimeAdj;
   descentToParkStartTime = cycleTimeStruct.descentToParkStartTimeAdj;
   firstStabilizationTime = cycleTimeStruct.firstStabilizationTimeAdj;
   firstStabilizationPres = cycleTimeStruct.firstStabilizationPres;
   descentToParkEndTime = cycleTimeStruct.descentToParkEndTimeAdj;
   descentToProfStartTime = cycleTimeStruct.descentToProfStartTimeAdj;
   descentToProfEndTime = cycleTimeStruct.descentToProfEndTimeAdj;
   ascentStartTime = cycleTimeStruct.ascentStartTimeAdj;
   ascentEndTime = cycleTimeStruct.ascentEndTimeAdj;
   gpsTime = cycleTimeStruct.gpsTimeAdj;
   firstMessageTime = cycleTimeStruct.firstMessageTime;
   lastMessageTime = cycleTimeStruct.lastMessageTime;
   
   timeList = [lastMessageTimePrevCy cycleStartTime descentToParkStartTime firstStabilizationTime ...
      descentToParkEndTime descentToProfStartTime descentToProfEndTime ...
      ascentStartTime ascentEndTime gpsTime ...
      firstMessageTime lastMessageTime];
   timeList(find(timeList == g_decArgo_dateDef)) = [];
   
   fprintf('FLOAT #%d: CHECK TIMES FOR CYCLE #%d: ', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   %    if (~any(diff(timeList) < -1/1440))
   if (~any(diff(timeList) < 0))
      fprintf('OK\n');
   else
      fprintf('ANOMALY\n');
      
      fprintf('CLOCK OFFSET                    : %s\n', ...
         format_time_dec_argo(o_floatClockDrift*24));
      fprintf('LAST MESSAGE TIME OF PREV CYCLE : %s\n', ...
         julian_2_gregorian_dec_argo(lastMessageTimePrevCy));
      fprintf('CYCLE START DATE                : %s\n', ...
         julian_2_gregorian_dec_argo(cycleStartTime));
      fprintf('DESCENT TO PARK START DATE      : %s\n', ...
         julian_2_gregorian_dec_argo(descentToParkStartTime));
      fprintf('FIRST STAB DATE                 : %s (%d dbar)\n', ...
         julian_2_gregorian_dec_argo(firstStabilizationTime), firstStabilizationPres);
      fprintf('DESCENT TO PARK END DATE        : %s\n', ...
         julian_2_gregorian_dec_argo(descentToParkEndTime));
      fprintf('DESCENT TO PROF START DATE      : %s\n', ...
         julian_2_gregorian_dec_argo(descentToProfStartTime));
      fprintf('DESCENT TO PROF END DATE        : %s\n', ...
         julian_2_gregorian_dec_argo(descentToProfEndTime));
      fprintf('ASCENT START DATE               : %s\n', ...
         julian_2_gregorian_dec_argo(ascentStartTime));
      fprintf('ASCENT END DATE                 : %s\n', ...
         julian_2_gregorian_dec_argo(ascentEndTime));
      fprintf('GPS DATE                        : %s\n', ...
         julian_2_gregorian_dec_argo(gpsTime));
      fprintf('FIRST MESSAGE DATE              : %s\n', ...
         julian_2_gregorian_dec_argo(firstMessageTime));
      fprintf('LAST MESSAGE DATE               : %s\n', ...
         julian_2_gregorian_dec_argo(lastMessageTime));
   end
end

return;

% ------------------------------------------------------------------------------
% Check if a transmitted date has been updated.
%
% SYNTAX :
%  [o_updated] = updated_time(a_time, a_fieldName, a_cycleNum)
%
% INPUT PARAMETERS :
%   a_time      : current time
%   a_fieldName : corresponding filed name in the cycle timing structure
%   a_cycleNum  : current cycle
%
% OUTPUT PARAMETERS :
%   o_updated : time updated flag
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/22/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_updated] = updated_time(a_time, a_fieldName, a_cycleNum)

% output parameters initialization
o_updated = 1;

% cycle timings storage
global g_decArgo_timeData;

% default values
global g_decArgo_dateDef;


% cycle timmings and associated cycle numbers
if (~isempty(g_decArgo_timeData))
   cycleNum = [g_decArgo_timeData.cycleNum];
   cycleTimes = [g_decArgo_timeData.cycleTime.(a_fieldName)];
   
   [cycleNum, idSort] = sort(cycleNum);
   cycleTimes = cycleTimes(idSort);
   
   idDel = find(cycleTimes == g_decArgo_dateDef);
   cycleNum(idDel) = [];
   cycleTimes(idDel) = [];
   
   idF = find(cycleNum < a_cycleNum);
   if (~isempty(idF))
      if ((a_time - fix(a_time)) == (cycleTimes(idF(end)) - fix(cycleTimes(idF(end)))))
         o_updated = 0;
      end
   end
end

return;
