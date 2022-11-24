% ------------------------------------------------------------------------------
% Parse and process Apex Iridium Rudics time data from log file.
%
% SYNTAX :
%  [o_timeData] = process_apx_ir_rudics_time_data_evts(a_events, a_decoderId)
%
% INPUT PARAMETERS :
%   a_events    : input log file event data
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_timeData : time data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_timeData] = process_apx_ir_rudics_time_data_evts(a_events, a_decoderId)

% output parameters initialization
o_timeData = get_apx_ir_rudics_float_time_init_struct;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
end

if (any(strcmp({a_events.cmd}, 'DescentInit()')))
   
   idEvts = find(strcmp({a_events.cmd}, 'DescentInit()'));
   events = a_events(idEvts);
   
   PATTERN1 = 'Deep profile';
   PATTERN2 = 'Park profile';
   PATTERN3 = 'Surface pressure:';

   for idEv = 1:length(events)
      dataStr = events(idEv).info;
      if (isempty(strtrim(dataStr)))
         continue;
      end
      %    fprintf('''%s''\n', dataStr);
      
      if (any(strfind(dataStr, PATTERN1)))
         
         [val, count, errmsg, nextIndex] = sscanf(dataStr, 'Deep profile %d initiated at mission-time %dsec.');
         if (~isempty(errmsg) || (count ~= 2))
            fprintf('DEC_INFO: %sAnomaly detected while parsing time information (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
            continue;
         end
         o_timeData.cycleNum = val(1);
         o_timeData.cycleStartDate = events(idEv).time - events(idEv).mTime/86400;
         o_timeData.descentStartDate = events(idEv).time;
         
      elseif (any(strfind(dataStr, PATTERN2)))
         
         [val, count, errmsg, nextIndex] = sscanf(dataStr, 'Park profile %d initiated at mission-time %dsec.');
         if (~isempty(errmsg) || (count ~= 2))
            fprintf('DEC_INFO: %sAnomaly detected while parsing time information (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
            continue;
         end
         o_timeData.cycleNum = val(1);
         o_timeData.cycleStartDate = events(idEv).time - events(idEv).mTime/86400;
         o_timeData.descentStartDate = events(idEv).time;
         
      elseif (any(strfind(dataStr, PATTERN3)))
         
         [val, count, errmsg, nextIndex] = sscanf(dataStr, 'Surface pressure: %fdbars.');
         if (~isempty(errmsg) || (count ~= 1))
            [val, count, errmsg, nextIndex] = sscanf(dataStr, 'Surface pressure: %fdbars.  IER: %i');
            if (~isempty(errmsg) || (count ~= 2))
               fprintf('DEC_INFO: %sAnomaly detected while parsing time information (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
               continue;
            end
         end
         o_timeData.descentStartSurfPres = val(1);
         
      else
         fprintf('DEC_INFO: %sNot managed information for ''%s'' cmd (from evts) ''%s'' => ignored\n', errorHeader, 'DescentInit()', dataStr);
      end
   end
end

if (any(strcmp({a_events.cmd}, 'ParkInit()')))
   
   idEvts = find(strcmp({a_events.cmd}, 'ParkInit()'));
   events = a_events(idEvts);
   
   for idEv = 1:length(events)
      %    fprintf('''%s''\n', dataStr);
      
      o_timeData.parkStartDate = events(idEv).time;
   end
end

if (any(strcmp({a_events.cmd}, 'ParkTerminate()')))
   
   idEvts = find(strcmp({a_events.cmd}, 'ParkTerminate()'));
   events = a_events(idEvts);

   PATTERN1 = 'Piston Position:';
   PATTERN2 = 'Buoyancy Position:';

   parkEndMeas = [];
   for idEv = 1:length(events)
      dataStr = events(idEv).info;
      if (isempty(strtrim(dataStr)))
         continue;
      end
      %    fprintf('''%s''\n', dataStr);
      
      if (any(strfind(dataStr, PATTERN1)))
         o_timeData.parkEndDate = events(idEv).time;
      elseif (any(strfind(dataStr, PATTERN2)))
         o_timeData.parkEndDate = events(idEv).time;
      else
         parkEndMeas{end+1} = dataStr;
      end
   end
   
   o_timeData.parkEndMeas = process_apx_ir_rudics_park_data_evts(o_timeData.parkEndDate, parkEndMeas, a_decoderId);

end

if (any(strcmp({a_events.cmd}, 'ProfileInit()')))
   
   idEvts = find(strcmp({a_events.cmd}, 'ProfileInit()'));
   events = a_events(idEvts);
   
   PATTERN_UNUSED = [ ...
      {'FLBB sampling has been disabled.'} ...
      {'Shallow water trap detected at'} ...
      {'Attempt to configure optode 4330 failed.'} ...
      ];

   PATTERN = 'PrfId:';

   for idEv = 1:length(events)
      dataStr = events(idEv).info;
      if (isempty(strtrim(dataStr)))
         continue;
      end
      %    fprintf('''%s''\n', dataStr);
      
      if (any(strfind(dataStr, PATTERN)))
         
         [val, count, errmsg, nextIndex] = sscanf(dataStr, 'PrfId:%d  Pressure:%fdbar  pTable[%d]:%ddbar');
         if (~isempty(errmsg) || (count ~= 4))
            fprintf('DEC_INFO: %sAnomaly detected while parsing time information (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
            continue;
         end
         if (isempty(o_timeData.cycleNum))
            o_timeData.cycleNum = val(1);
         elseif (o_timeData.cycleNum ~= val(1))
            fprintf('DEC_INFO: %sAnomaly detected between cycle number of DST and AST => ignored\n', errorHeader);
            continue;
         end
         o_timeData.ascentStartDate = events(idEv).time;
         o_timeData.ascentStartPres = val(2);
         
      else
         idF = cellfun(@(x) strfind(dataStr, x), PATTERN_UNUSED, 'UniformOutput', 0);
         if (isempty([idF{:}]))
            fprintf('DEC_INFO: %sNot managed information for ''%s'' cmd (from evts) ''%s'' => ignored\n', errorHeader, 'ProfileInit()', dataStr);
            continue;
         end
      end
   end
end

if (any(strcmp({a_events.cmd}, 'SurfaceDetect()')))
   
   idEvts = find(strcmp({a_events.cmd}, 'SurfaceDetect()'));
   events = a_events(idEvts);
   
   PATTERN_UNUSED = [ ...
      {'Deactivation CP mode failed.'} ...
      {'Piston fully extended before surface detected.'} ...
      {'Subsurfaceobs['} ...
      ];
   
   PATTERN = 'SurfacePressure:';

   for idEv = 1:length(events)
      dataStr = events(idEv).info;
      if (isempty(strtrim(dataStr)))
         continue;
      end
      %    fprintf('''%s''\n', dataStr);
      
      if (any(strfind(dataStr, PATTERN)))
         
         [val, count, errmsg, nextIndex] = sscanf(dataStr, 'SurfacePressure:%fdbars Pressure:%fdbars PistonPosition:%d');
         if (~isempty(errmsg) || (count ~= 3))
            [val, count, errmsg, nextIndex] = sscanf(dataStr, 'SurfacePressure:%fdbars Pressure:%fdbars BuoyancyPosition:%d');
            if (~isempty(errmsg) || (count ~= 3))
               fprintf('DEC_INFO: %sAnomaly detected while parsing time information (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
               continue;
            end
         end
         o_timeData.ascentEndDate = events(idEv).time;
         o_timeData.ascentEndSurfPres = val(1);
         o_timeData.ascentEndPres = val(2);
      else
         idF = cellfun(@(x) strfind(dataStr, x), PATTERN_UNUSED, 'UniformOutput', 0);
         if (isempty([idF{:}]))
            fprintf('DEC_INFO: %sNot managed information for ''%s'' cmd (from evts) ''%s'' => ignored\n', errorHeader, 'SurfaceDetect()', dataStr);
            continue;
         end
      end
   end
end

if (any(strcmp({a_events.cmd}, 'login()')))
   
   idEvts = find(strcmp({a_events.cmd}, 'login()'));
   events = a_events(idEvts);
   
   PATTERN_UNUSED = [ ...
      {'Login failed.'} ...
      {'No carrier detected.'} ...
      {'Attempt to set the command prompt failed.'} ...
      {'Login prompt not received.'} ...
      {'Password prompt not received.'} ...
      ];
   
   PATTERN = 'Login successful.';

   for idEv = 1:length(events)
      dataStr = events(idEv).info;
      if (isempty(strtrim(dataStr)))
         continue;
      end
      %    fprintf('''%s''\n', dataStr);
      
      if (any(strfind(dataStr, PATTERN)))
         
         % we store the first one
         if (isempty(o_timeData.transStartDate))
            o_timeData.transStartDate = events(idEv).time;
            o_timeData.transStartDateMTime = events(idEv).mTime;
         end
      else
         idF = cellfun(@(x) strfind(dataStr, x), PATTERN_UNUSED, 'UniformOutput', 0);
         if (isempty([idF{:}]))
            fprintf('DEC_INFO: %sNot managed information for ''%s'' cmd (from evts) ''%s'' => ignored\n', errorHeader, 'login()', dataStr);
            continue;
         end
      end
   end
end

if (any(strcmp({a_events.cmd}, 'logout()')))
   
   idEvts = find(strcmp({a_events.cmd}, 'logout()'));
   events = a_events(idEvts);
   
   PATTERN_UNUSED = [ ...
      {'Can''t get command prompt.'} ...
      {'Attempt to log-out failed.'} ...
      {'No carrier detected.'} ...
      ];
   
   PATTERN = 'Log-out successful.';

   for idEv = 1:length(events)
      dataStr = events(idEv).info;
      if (isempty(strtrim(dataStr)))
         continue;
      end
      %    fprintf('''%s''\n', dataStr);
      
      if (any(strfind(dataStr, PATTERN)))
         
         % we store the last one
         o_timeData.transEndDate = events(idEv).time;
         o_timeData.transEndDateMTime = events(idEv).mTime;
      else
         idF = cellfun(@(x) strfind(dataStr, x), PATTERN_UNUSED, 'UniformOutput', 0);
         if (isempty([idF{:}]))
            fprintf('DEC_INFO: %sNot managed information for ''%s'' cmd (from evts) ''%s'' => ignored\n', errorHeader, 'logout()', dataStr);
            continue;
         end
      end
   end
end

return;
