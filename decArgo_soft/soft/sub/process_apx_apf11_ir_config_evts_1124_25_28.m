% ------------------------------------------------------------------------------
% Get configuration information from Apex APF11 events.
%
% SYNTAX :
%  [o_missionCfg, o_sampleCfg] = process_apx_apf11_ir_config_evts_1124_25_28(a_events)
%
% INPUT PARAMETERS :
%   a_events : input system_log file event data
%
% OUTPUT PARAMETERS :
%   o_missionCfg : mission configuration data
%   o_sampleCfg  : sample configuration data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/23/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_missionCfg, o_sampleCfg] = process_apx_apf11_ir_config_evts_1124_25_28(a_events)

% output parameters initialization
o_missionCfg = [];
o_sampleCfg = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


% mission configuration

% since
% PATTERN_START = '-----------Mission Parameters-----------';
% PATTERN_END = '----------------------------------------';
% have been removed in 2.13.1; as all mission configuration information are
% provided in the same timestamp, we use the most populated session with the
% 'mission_cfg'
events = a_events(find(strcmp({a_events.functionName}, 'mission_cfg')));
evtTimeList = [events.timestamp];
uEvtTimeList = unique(evtTimeList);
if (length(unique(uEvtTimeList)) > 1)
   nbElts = hist(evtTimeList, uEvtTimeList);
   [maxVal, maxId] = max(fliplr(nbElts)); % fliplr to catch the oldest one if more than one is provided
   if (maxVal > 40)
      maxId = length(nbElts) - maxId + 1;
      events = events(find([events.timestamp] == uEvtTimeList(maxId)));
   else
      events = [];
   end
else
   events = [];
end
configStruct = [];
for idEv = 1:length(events)
   evt = events(idEv);
   line = evt.message;
   info = textscan(line, '%s', 'delimiter', ' ');
   info = info{:};
   configStruct.(info{1}) = [];
   configStruct.(info{1}) = info(2:end)';
end
if (~isempty(configStruct))
   o_missionCfg = [events(1).timestamp {configStruct}];
end

% sample configuration

% since
% PATTERN_START = '#-----------Sample Config-----------';
% PATTERN_END = '#-----------------------------------';
% have been removed in 2.13.1; as all sample configuration information are
% provided in the same timestamp, we use the most populated session with the
% 'sample_cfg'
events = a_events(find(strcmp({a_events.functionName}, 'sample_cfg')));
evtTimeList = [events.timestamp];
uEvtTimeList = unique(evtTimeList);
if (length(unique(uEvtTimeList)) > 1)
   nbElts = hist(evtTimeList, uEvtTimeList);
   [maxVal, maxId] = max(fliplr(nbElts)); % fliplr to catch the oldest one if more than one is provided
   maxId = length(nbElts) - maxId + 1;
   events = events(find([events.timestamp] == uEvtTimeList(maxId)));
end
configStruct = [];
for idEv = 1:length(events)
   evt = events(idEv);
   line = evt.message;
   
   if ((line(1) == '<') && (line(end) == '>'))
      
      phase = line(2:end-1);
      if (~isfield(configStruct, phase))
         configStruct.(phase) = [];
      end
      
   elseif (strncmpi(line, 'SAMPLE', length('SAMPLE')))
      
      sampType = 'SAMPLE';
      if (~isfield(configStruct.(phase), sampType))
         configStruct.(phase).(sampType) = [];
      end
      
      % default values
      start = 2000;
      stop = 0;
      interval = 0;
      count = 1;
      
      info = textscan(line, '%s');
      info = info{:};
      
      if (~strcmpi(info{1}, 'SAMPLE'))
         fprintf('ERROR: Float #%d Cycle #%d: Inconsistent sample data\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
         return
      end
      
      idF = find(strcmp('DBAR', info), 1);
      if (~isempty(idF))
         info(idF) = [];
      end
      
      sensor = info{2};
      if (~isfield(configStruct.(phase).(sampType), sensor))
         configStruct.(phase).(sampType).(sensor) = [];
      end
      
      if (length(info) >= 3)
         start = str2num(info{3});
      end
      if (length(info) >= 4)
         stop = str2num(info{4});
      end
      if (length(info) >= 5)
         interval = str2num(info{5});
      end
      if (length(info) >= 6)
         count = str2num(info{6});
      end
      
      configStruct.(phase).(sampType).(sensor) = [configStruct.(phase).(sampType).(sensor); ...
         start stop interval count];
      
   elseif (strncmpi(line, 'PROFILE', length('PROFILE')))
      
      sampType = 'PROFILE';
      if (~isfield(configStruct.(phase), sampType))
         configStruct.(phase).(sampType) = [];
      end
      
      % default values
      start = 2000;
      stop = 0;
      bin_size = 2;
      rate = 1;
      
      info = textscan(line, '%s');
      info = info{:};
      
      if (~strcmpi(info{1}, 'PROFILE'))
         fprintf('ERROR: Float #%d Cycle #%d: Inconsistent sample data\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
         return
      end
      
      sensor = info{2};
      if (strcmp(sensor, 'PTSH'))
         sensor = 'PH';
         bin_size = 1;
         rate = -1;
      end
      if (~isfield(configStruct.(phase).(sampType), sensor))
         configStruct.(phase).(sampType).(sensor) = [];
      end
      
      if (length(info) >= 3)
         start = str2num(info{3});
      end
      if (length(info) >= 4)
         stop = str2num(info{4});
      end
      if (length(info) >= 5)
         bin_size = str2num(info{5});
      end
      if (length(info) >= 6)
         rate = str2num(info{6});
      end
      
      configStruct.(phase).(sampType).(sensor) = [configStruct.(phase).(sampType).(sensor); ...
         start stop bin_size rate];
      
   elseif (strncmpi(line, 'MEASURE', length('MEASURE')))
      
      sampType = 'MEASURE';
      if (~isfield(configStruct.(phase), sampType))
         configStruct.(phase).(sampType) = [];
      end
      
      % default values
      start = -1;
      stop = -1;
      interval = -1;
      count = -1;
      
      info = textscan(line, '%s');
      info = info{:};
      
      if (~strcmpi(info{1}, 'MEASURE'))
         fprintf('ERROR: Float #%d Cycle #%d: Inconsistent sample data\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
         return
      end
      
      sensor = info{2};
      if (~isfield(configStruct.(phase).(sampType), sensor))
         configStruct.(phase).(sampType).(sensor) = [];
      end
      
      configStruct.(phase).(sampType).(sensor) = [configStruct.(phase).(sampType).(sensor); ...
         start stop interval count];
      
   elseif (strncmpi(line, 'LISTEN', length('LISTEN')))
      
      sampType = 'LISTEN';
      if (~isfield(configStruct.(phase), sampType))
         configStruct.(phase).(sampType) = [];
      end
      
      % default values
      startDayTime = 0;
      duration = 120;
      
      info = textscan(line, '%s');
      info = info{:};
      
      if (~strcmpi(info{1}, 'LISTEN'))
         fprintf('ERROR: Float #%d Cycle #%d: Inconsistent sample data\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
         return
      end
            
      sensor = info{2};
      if (~isfield(configStruct.(phase).(sampType), sensor))
         configStruct.(phase).(sampType).(sensor) = [];
      end
            
      if (length(info) >= 3)
         startDayTime = str2num(info{3});
      end
      if (length(info) >= 4)
         duration = str2num(info{4});
      end
      
      configStruct.(phase).(sampType).(sensor) = [configStruct.(phase).(sampType).(sensor); ...
         startDayTime duration];

   elseif (strncmpi(line, 'POWER', length('POWER')))
      
      sampType = 'POWER';
      if (~isfield(configStruct.(phase), sampType))
         configStruct.(phase).(sampType) = [];
      end
      
      % default values
      start = -1;
      stop = -1;
      
      info = textscan(line, '%s');
      info = info{:};
      
      if (~strcmpi(info{1}, 'POWER'))
         fprintf('ERROR: Float #%d Cycle #%d: Inconsistent sample data\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
         return
      end
            
      sensor = info{2};
      if (~isfield(configStruct.(phase).(sampType), sensor))
         configStruct.(phase).(sampType).(sensor) = [];
      end
            
      if (length(info) >= 3)
         start = str2num(info{3});
      end
      if (length(info) >= 4)
         stop = str2num(info{4});
      end
      
      configStruct.(phase).(sampType).(sensor) = [configStruct.(phase).(sampType).(sensor); ...
         start stop];      

   else
      
      fprintf('ERROR: Float #%d Cycle #%d: Not managed sample information: %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, line);
      
   end
end

if (~isempty(configStruct))
   o_sampleCfg = [events(1).timestamp {configStruct}];
end

return
