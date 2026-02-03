% ------------------------------------------------------------------------------
% Get configuration information from Apex APF11 events.
%
% SYNTAX :
%  [o_missionCfg, o_sampleCfg] = process_apx_apf11_ir_config_evts_1124_25_28_to_32(a_events)
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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/23/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_missionCfg, o_sampleCfg] = process_apx_apf11_ir_config_evts_1124_25_28_to_32(a_events)

% output parameters initialization
o_missionCfg = [];
o_sampleCfg = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mission configuration

% PATTERN_START = '-----------Mission Parameters-----------';
% PATTERN_END = '----------------------------------------';
% have been removed in 2.13.1

% we are not sure that all mission configuration information are provided with
% the same timestamp
% => we use contiguous events.number to select sets of configuration information
% => we keep only those with more than 40 parameters

events = a_events(find(strcmp({a_events.functionName}, 'mission_cfg')));

idCut = find(diff([events.number]) > 1);
for idC = 1:length(idCut)+1
   if (idC == 1)
      idStart = 1;
   else
      idStart = idCut(idC-1) + 1;
   end
   if (idC <= length(idCut))
      idStop = idCut(idC);
   else
      idStop = length(events);
   end
   eventsM = events(idStart:idStop);

   if (length(eventsM) > 40)

      configStruct = [];
      for idEv = 1:length(eventsM)
         evt = eventsM(idEv);
         line = evt.message;
         info = textscan(line, '%s', 'delimiter', ' ');
         info = info{:};
         configStruct.(info{1}) = [];
         configStruct.(info{1}) = info(2:end)';
      end
      if (~isempty(configStruct))
         o_missionCfg = [o_missionCfg; [eventsM(1).timestamp {configStruct}]];
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sample configuration

% PATTERN_START = '#-----------Sample Config-----------';
% PATTERN_END = '#-----------------------------------';
% have been removed in 2.13.1

% we are not sure that all sample configuration information are provided with
% the same timestamp
% => we use contiguous events.number to select sets of configuration information

events = a_events(find(strcmp({a_events.functionName}, 'sample_cfg')));

idCut = find(diff([events.number]) > 1);
for idC = 1:length(idCut)+1
   if (idC == 1)
      idStart = 1;
   else
      idStart = idCut(idC-1) + 1;
   end
   if (idC <= length(idCut))
      idStop = idCut(idC);
   else
      idStop = length(events);
   end
   eventsC = events(idStart:idStop);

   configStruct = [];
   for idEv = 1:length(eventsC)
      evt = eventsC(idEv);
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
         start = 2500;
         stop = 0;
         interval = 0;
         units = 1; % 1: DBAR, 2:SEC
         count = 1;
         maxSamp = 0;

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
         idF = find(strcmp('SEC', info), 1);
         if (~isempty(idF))
            units = 2;
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
         if (length(info) >= 7)
            maxSamp = str2num(info{7});
         end
         ignore = 0;
         if (length(info) >= 8)
            if (strncmpi(info{8}, 'HIT_BOTTOM', length('HIT_BOTTOM')))
               % we don't report the configuration triggered by HIT_BOTTOM
               % because it seems to be too difficult to report
               ignore = 1;
            end
         end

         if (~ignore)
            configStruct.(phase).(sampType).(sensor) = [configStruct.(phase).(sampType).(sensor); ...
               start stop interval units count maxSamp];
         end

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

      elseif (strcmp(line, 'verify_updaters|no updaters found') || ... % see 7900589
            strcmp(line, '# no updaters') || ...
            strcmp(line, 'parse attempt 1/3 failed, FSEntry_Query Error: 323'))

         % not considered

      elseif (strncmp(line, 'changing PARK SAMPLE PTS updater stop pressure from', ...
            length('changing PARK SAMPLE PTS updater stop pressure from')))

         % not considered

      else

         fprintf('ERROR: Float #%d Cycle #%d: Not managed sample information: %s\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, line);

      end
   end

   if (~isempty(configStruct))
      o_sampleCfg = [o_sampleCfg; [eventsC(1).timestamp {configStruct}]];
   end
end

return
