% ------------------------------------------------------------------------------
% Decode CTS5 events for a given cycle and pattern.
%
% SYNTAX :
%  decode_event_data_cts5(a_cyNum, a_ptnNum)
%
% INPUT PARAMETERS :
%   a_cyNum  : concerned cycle number
%   a_ptnNum : concerned pattern number
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function decode_event_data_cts5(a_cyNum, a_ptnNum)

% number used to group traj information
global g_decArgo_trajItemGroupNum;

% number used to group tech PARAM information
global g_decArgo_techItemGroupNum;

% variable to store all useful event data
global g_decArgo_eventData;

% decoded event data
global g_decArgo_eventDataTech;
g_decArgo_eventDataTech = [];
global g_decArgo_eventDataParamTech;
g_decArgo_eventDataParamTech = [];
global g_decArgo_eventDataTraj;
g_decArgo_eventDataTraj = [];
global g_decArgo_eventDataMeta;
g_decArgo_eventDataMeta = [];
global g_decArgo_eventDataTime;
g_decArgo_eventDataTime = [];

% global measurement codes
global g_MC_CycleStart;
global g_MC_DST;
global g_MC_FST;
global g_MC_SpyInDescToPark;
global g_MC_PST;
global g_MC_SpyAtPark;
global g_MC_PET;
global g_MC_SpyInDescToProf;
global g_MC_DPST;
global g_MC_SpyAtProf;
global g_MC_AST;
global g_MC_SpyInAscProf;
global g_MC_AET;
global g_MC_SpyAtSurface;
global g_MC_TST;
global g_MC_Surface;
global g_MC_TET;
global g_MC_Grounded;


% global g_decArgo_cycleNumFloat;
% if (g_decArgo_cycleNumFloat == 85)
%    a=1
% end

if (a_ptnNum == 0)
   return
end

% event for the concerned float (cycle, pattern)
idFCyPtn = find(([g_decArgo_eventData{:, 1}] == a_cyNum) & ([g_decArgo_eventData{:, 2}] == a_ptnNum));

% cycle start time
cycleStartTime = [];
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 100);
if (~isempty(idF))
   g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
      'CYCLE START TIME', 'JULD', g_decArgo_eventData{idFCyPtn(idF), 6}, []);
   g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
      g_MC_CycleStart, 'JULD', ...
      'Buoyancy reduction start date', g_decArgo_eventData{idFCyPtn(idF), 6}, ...
      a_cyNum, a_ptnNum);
   cycleStartTime = g_decArgo_eventData{idFCyPtn(idF), 6};
end

% descent start time
descStartDate = [];
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 103);
if (~isempty(idF))
   g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
      'DESCENT TO PARK START TIME', 'JULD', g_decArgo_eventData{idFCyPtn(idF), 6}, []);
   g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
      g_MC_DST, 'JULD', ...
      'Descent to parking depth start date', g_decArgo_eventData{idFCyPtn(idF), 6}, ...
      a_cyNum, a_ptnNum);
   descStartDate = g_decArgo_eventData{idFCyPtn(idF), 6};
end

% first stabilization time
if (~isempty(descStartDate))
   idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 9);
   if (~isempty(idF))
      evtTimes = [g_decArgo_eventData{idFCyPtn(idF), 6}];
      idF2 = find(evtTimes >= descStartDate);
      if (~isempty(idF2))
         idF2 = idF2(1);
         g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
            'FIRST STABILIZATION TIME', 'JULD', g_decArgo_eventData{idFCyPtn(idF(idF2)), 6}, ...
            g_decArgo_eventData{idFCyPtn(idF(idF2)), 5}{2});
         g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
            g_MC_FST, 'JULD', ...
            'Stabilization time after buoyancy reduction (dbar)', g_decArgo_eventData{idFCyPtn(idF(idF2)), 6}, ...
            a_cyNum, a_ptnNum);
         g_decArgo_eventDataTraj{end}.group = g_decArgo_trajItemGroupNum;
         g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
            g_MC_FST, 'PRES', ...
            'Stabilization pressure after buoyancy reduction (dbar)', g_decArgo_eventData{idFCyPtn(idF(idF2)), 5}{2}, ...
            a_cyNum, a_ptnNum);
         g_decArgo_eventDataTraj{end}.group = g_decArgo_trajItemGroupNum;
         g_decArgo_trajItemGroupNum = g_decArgo_trajItemGroupNum + 1;
      end
   end
end

% park start time
parkStartDate = [];
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 104);
if (~isempty(idF))
   g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
      'PARK START TIME', 'JULD', g_decArgo_eventData{idFCyPtn(idF), 6}, []);
   g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
      g_MC_PST, 'JULD', ...
      'Descent to parking depth end date', g_decArgo_eventData{idFCyPtn(idF), 6}, ...
      a_cyNum, a_ptnNum);
   parkStartDate = g_decArgo_eventData{idFCyPtn(idF), 6};
end

% stabilizde park start time
stabParkStartDate = [];
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 105);
if (~isempty(idF))
   g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
      'STABILIZED PARK START TIME', 'JULD', g_decArgo_eventData{idFCyPtn(idF), 6}, ...
      g_decArgo_eventData{idFCyPtn(idF), 5}{:});
   g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
      184, 'Stabilized park start date', g_decArgo_eventData{idFCyPtn(idF), 6});
   g_decArgo_eventDataTech{end}.func = '@(x) format_date_yyyymmddhhmiss_dec_argo(x)';
   g_decArgo_eventDataTech{end}.func1 = '@(x) adjust_time_cts5(x)';
   g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
      185, 'Stabilized park pressure (dbar)', g_decArgo_eventData{idFCyPtn(idF), 5}{:});
   stabParkStartDate = g_decArgo_eventData{idFCyPtn(idF), 6};
end

% park end time
parkEndDate = [];
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 106);
if (~isempty(idF))
   g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
      'PARK END TIME', 'JULD', g_decArgo_eventData{idFCyPtn(idF), 6}, []);
   g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
      g_MC_PET, 'JULD', ...
      'Descent to profile depth start date', g_decArgo_eventData{idFCyPtn(idF), 6}, ...
      a_cyNum, a_ptnNum);
   parkEndDate = g_decArgo_eventData{idFCyPtn(idF), 6};
end

% deep descent end time
deepParkStartDate = [];
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 107);
if (~isempty(idF))
   g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
      'DEEP PARK START TIME', 'JULD', g_decArgo_eventData{idFCyPtn(idF), 6}, []);
   g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
      g_MC_DPST, 'JULD', ...
      'Deep park start date', g_decArgo_eventData{idFCyPtn(idF), 6}, ...
      a_cyNum, a_ptnNum);
   deepParkStartDate = g_decArgo_eventData{idFCyPtn(idF), 6};
end

% ascent start time
ascentStartDate = [];
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 108);
if (~isempty(idF))
   g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
      'ASCENT START TIME', 'JULD', g_decArgo_eventData{idFCyPtn(idF), 6}, []);
   g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
      g_MC_AST, 'JULD', ...
      'Standard ascent start date', g_decArgo_eventData{idFCyPtn(idF), 6}, ...
      a_cyNum, a_ptnNum);
   ascentStartDate = g_decArgo_eventData{idFCyPtn(idF), 6};
end

% slow ascent start time
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 109);
if (~isempty(idF))
   g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
      'SLOW ASCENT START TIME', 'JULD', g_decArgo_eventData{idFCyPtn(idF), 6}, []);
   g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
      121, 'Slow ascent start date', g_decArgo_eventData{idFCyPtn(idF), 6});
   g_decArgo_eventDataTech{end}.func = '@(x) format_date_yyyymmddhhmiss_dec_argo(x)';
   g_decArgo_eventDataTech{end}.func1 = '@(x) adjust_time_cts5(x)';
end

% resumed ascent start time
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 110);
if (~isempty(idF))
   g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
      'RESUMED ASCENT START TIME', 'JULD', g_decArgo_eventData{idFCyPtn(idF), 6}, []);
   g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
      124, 'Resumed ascent start date', g_decArgo_eventData{idFCyPtn(idF), 6});
   g_decArgo_eventDataTech{end}.func = '@(x) format_date_yyyymmddhhmiss_dec_argo(x)';
   g_decArgo_eventDataTech{end}.func1 = '@(x) adjust_time_cts5(x)';
end

% ascent end time
ascentEndDate = [];
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 96);
if (~isempty(idF))
   g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
      'ASCENT END TIME', 'JULD', g_decArgo_eventData{idFCyPtn(idF), 6}, []);
   g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
      g_MC_AET, 'JULD', ...
      'Ascent end date', g_decArgo_eventData{idFCyPtn(idF), 6}, ...
      a_cyNum, a_ptnNum);
   ascentEndDate = g_decArgo_eventData{idFCyPtn(idF), 6};
end

% surface time (final pump action start date
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 97);
if (~isempty(idF))
   g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
      'FINAL PUMP ACTION START TIME', 'JULD', g_decArgo_eventData{idFCyPtn(idF), 6}, []);
   g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
      g_MC_SpyAtSurface, 'JULD', ...
      'Final pump action start date', g_decArgo_eventData{idFCyPtn(idF), 6}, ...
      a_cyNum, a_ptnNum);
end

% transmission start time
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 121);
if (~isempty(idF))
   transmissionStartTime = min([g_decArgo_eventData{idFCyPtn(idF), 6}]);
   
   g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
      'TRANSMISSION START TIME', 'JULD', transmissionStartTime, []);
   g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
      g_MC_TST, 'JULD', ...
      'Transmission start date', transmissionStartTime, ...
      a_cyNum, a_ptnNum);
end

% transmission end time
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 126);
if (~isempty(idF))
   transmissionEndTime = max([g_decArgo_eventData{idFCyPtn(idF), 6}]);
   
   g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
      'TRANSMISSION END TIME', 'JULD', transmissionEndTime, []);
   g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
      g_MC_TET, 'JULD', ...
      'Transmission end date', transmissionEndTime, ...
      a_cyNum, a_ptnNum);
end

% GPS locations
idF1 = find([g_decArgo_eventData{idFCyPtn, 4}] == 66);
if (~isempty(idF1))
   for id = 1:length(idF1)
      idF2 = find(([g_decArgo_eventData{idFCyPtn, 4}] == 67) & ...
         ([g_decArgo_eventData{idFCyPtn, 6}] == g_decArgo_eventData{idFCyPtn(idF1(id)), 6}));
      if (isempty(idF2))
         % we can have a 1 second diffenrence betweeen GPS location time and
         % latitude/longitude
         idF2 = find(([g_decArgo_eventData{idFCyPtn, 4}] == 67) & ...
            ([g_decArgo_eventData{idFCyPtn, 6}] == g_decArgo_eventData{idFCyPtn(idF1(id)), 6}+1/86400));
      end
      if (~isempty(idF2))
         % LATITUDE/LONGITUDE can be empty for some GPS fixes
         if (~isempty(g_decArgo_eventData{idFCyPtn(idF2), 5}))
            g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
               'GPS LOCATION', 'JULD', g_decArgo_eventData{idFCyPtn(idF1(id)), 5}{:}, []);
            g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
               g_MC_Surface, 'JULD', ...
               'GPS location date', g_decArgo_eventData{idFCyPtn(idF1(id)), 5}{:}, ...
               a_cyNum, a_ptnNum);
            g_decArgo_eventDataTraj{end}.group = g_decArgo_trajItemGroupNum;
            g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
               g_MC_Surface, 'LATITUDE', ...
               'GPS location latitude', g_decArgo_eventData{idFCyPtn(idF2), 5}{1}, ...
               a_cyNum, a_ptnNum);
            g_decArgo_eventDataTraj{end}.group = g_decArgo_trajItemGroupNum;
            g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
               g_MC_Surface, 'LONGITUDE', ...
               'GPS location longitude', g_decArgo_eventData{idFCyPtn(idF2), 5}{2}, ...
               a_cyNum, a_ptnNum);
            g_decArgo_eventDataTraj{end}.group = g_decArgo_trajItemGroupNum;
            g_decArgo_trajItemGroupNum = g_decArgo_trajItemGroupNum + 1;
         end
      end
   end
end

% CTD pump cut-off pressure
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 197);
if (~isempty(idF))
   g_decArgo_eventDataMeta{end+1} = get_cts5_tech_data_init_struct(...
      188, 'CTD pump cut-off pressure (dbar)', g_decArgo_eventData{idFCyPtn(idF), 5}{:});
end

% pressure offset
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 198);
if (~isempty(idF))
   g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
      102, 'Pressure offset (dbar)', g_decArgo_eventData{idFCyPtn(idF), 5}{:});
end

% surface pressure
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 47);
if (~isempty(idF))
   g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
      177, 'Surface pressure (dbar)', g_decArgo_eventData{idFCyPtn(idF(1)), 5}{:});
end

% internal pressure
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 48);
if (~isempty(idF))
   g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
      103, 'Internal pressure (mbar)', g_decArgo_eventData{idFCyPtn(idF(1)), 5}{:});
end

% battery voltage
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 49);
if (~isempty(idF))
   g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
      104, 'Battery voltage (V)', g_decArgo_eventData{idFCyPtn(idF(1)), 5}{:});
end

% buoyancy actions
idF = find(([g_decArgo_eventData{idFCyPtn, 4}] == 9) | ...
   ([g_decArgo_eventData{idFCyPtn, 4}] == 10));
if (~isempty(idF))
   for id = 1:length(idF)
      if (g_decArgo_eventData{idFCyPtn(idF(id)), 4} == 9)
         g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
            'Valve action', 'JULD', g_decArgo_eventData{idFCyPtn(idF(id)), 6}, ...
            g_decArgo_eventData{idFCyPtn(idF(id)), 5}{2});
      else
         g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
            'Pump action', 'JULD', g_decArgo_eventData{idFCyPtn(idF(id)), 6}, ...
            g_decArgo_eventData{idFCyPtn(idF(id)), 5}{2});
      end
   end
   
   evtTimes = [g_decArgo_eventData{idFCyPtn(idF), 6}];
   refParkStart = parkStartDate;
   if (isempty(refParkStart))
      refParkStart = stabParkStartDate;
   end
   if (~isempty(descStartDate) && ~isempty(refParkStart))
      idF2 = find((evtTimes >= descStartDate) & (evtTimes <= refParkStart));
      for id = 1:length(idF2)
         g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
            g_MC_SpyInDescToPark, 'JULD', ...
            'Buoyancy action time during descent to park', ...
            g_decArgo_eventData{idFCyPtn(idF(idF2(id))), 6}, ...
            a_cyNum, a_ptnNum);
         g_decArgo_eventDataTraj{end}.group = g_decArgo_trajItemGroupNum;
         g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
            g_MC_SpyInDescToPark, 'PRES', ...
            'Buoyancy action pressure during descent to park', ...
            g_decArgo_eventData{idFCyPtn(idF(idF2(id))), 5}{2}, ...
            a_cyNum, a_ptnNum);
         g_decArgo_eventDataTraj{end}.group = g_decArgo_trajItemGroupNum;
         g_decArgo_trajItemGroupNum = g_decArgo_trajItemGroupNum + 1;
         
         g_decArgo_eventDataParamTech{end+1} = get_cts5_traj_data_init_struct(...
            g_MC_SpyInDescToPark, 'JULD', ...
            'Buoyancy action time during descent to park', ...
            g_decArgo_eventData{idFCyPtn(idF(idF2(id))), 6}, ...
            a_cyNum, a_ptnNum);
         g_decArgo_eventDataParamTech{end}.group = g_decArgo_techItemGroupNum;
         if (g_decArgo_eventData{idFCyPtn(idF(idF2(id))), 4} == 9)
            % valve action
            g_decArgo_eventDataParamTech{end+1} = get_cts5_traj_data_init_struct(...
               g_MC_SpyInDescToPark, 'VALVE_ACTION_FLAG', ...
               'Buoyancy action (valve action) during descent to park', ...
               1, ...
               a_cyNum, a_ptnNum);
            g_decArgo_eventDataParamTech{end}.group = g_decArgo_techItemGroupNum;
         else
            % pump action
            g_decArgo_eventDataParamTech{end+1} = get_cts5_traj_data_init_struct(...
               g_MC_SpyInDescToPark, 'PUMP_ACTION_FLAG', ...
               'Buoyancy action (pump action) during descent to park', ...
               1, ...
               a_cyNum, a_ptnNum);
            g_decArgo_eventDataParamTech{end}.group = g_decArgo_techItemGroupNum;
         end
         g_decArgo_techItemGroupNum = g_decArgo_techItemGroupNum + 1;
      end
   end
   if (~isempty(refParkStart) && ~isempty(parkEndDate))
      idF2 = find((evtTimes >= refParkStart) & (evtTimes <= parkEndDate));
      for id = 1:length(idF2)
         g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
            g_MC_SpyAtPark, 'JULD', ...
            'Buoyancy action time during drift at park', ...
            g_decArgo_eventData{idFCyPtn(idF(idF2(id))), 6}, ...
            a_cyNum, a_ptnNum);
         g_decArgo_eventDataTraj{end}.group = g_decArgo_trajItemGroupNum;
         g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
            g_MC_SpyAtPark, 'PRES', ...
            'Buoyancy action pressure during drift at park', ...
            g_decArgo_eventData{idFCyPtn(idF(idF2(id))), 5}{2}, ...
            a_cyNum, a_ptnNum);
         g_decArgo_eventDataTraj{end}.group = g_decArgo_trajItemGroupNum;
         g_decArgo_trajItemGroupNum = g_decArgo_trajItemGroupNum + 1;
         
         g_decArgo_eventDataParamTech{end+1} = get_cts5_traj_data_init_struct(...
            g_MC_SpyAtPark, 'JULD', ...
            'Buoyancy action time during drift at park', ...
            g_decArgo_eventData{idFCyPtn(idF(idF2(id))), 6}, ...
            a_cyNum, a_ptnNum);
         g_decArgo_eventDataParamTech{end}.group = g_decArgo_techItemGroupNum;
         if (g_decArgo_eventData{idFCyPtn(idF(idF2(id))), 4} == 9)
            % valve action
            g_decArgo_eventDataParamTech{end+1} = get_cts5_traj_data_init_struct(...
               g_MC_SpyAtPark, 'VALVE_ACTION_FLAG', ...
               'Buoyancy action (valve action) during drift at park', ...
               1, ...
               a_cyNum, a_ptnNum);
            g_decArgo_eventDataParamTech{end}.group = g_decArgo_techItemGroupNum;
         else
            % pump action
            g_decArgo_eventDataParamTech{end+1} = get_cts5_traj_data_init_struct(...
               g_MC_SpyAtPark, 'PUMP_ACTION_FLAG', ...
               'Buoyancy action (pump action) during drift at park', ...
               1, ...
               a_cyNum, a_ptnNum);
            g_decArgo_eventDataParamTech{end}.group = g_decArgo_techItemGroupNum;
         end
         g_decArgo_techItemGroupNum = g_decArgo_techItemGroupNum + 1;
      end
   end
   if (~isempty(parkEndDate) && ~isempty(deepParkStartDate))
      idF2 = find((evtTimes >= parkEndDate) & (evtTimes <= deepParkStartDate));
      for id = 1:length(idF2)
         g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
            g_MC_SpyInDescToProf, 'JULD', ...
            'Buoyancy action time during descent to prof', ...
            g_decArgo_eventData{idFCyPtn(idF(idF2(id))), 6}, ...
            a_cyNum, a_ptnNum);
         g_decArgo_eventDataTraj{end}.group = g_decArgo_trajItemGroupNum;
         g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
            g_MC_SpyInDescToProf, 'PRES', ...
            'Buoyancy action pressure during descent to prof', ...
            g_decArgo_eventData{idFCyPtn(idF(idF2(id))), 5}{2}, ...
            a_cyNum, a_ptnNum);
         g_decArgo_eventDataTraj{end}.group = g_decArgo_trajItemGroupNum;
         g_decArgo_trajItemGroupNum = g_decArgo_trajItemGroupNum + 1;
         
         g_decArgo_eventDataParamTech{end+1} = get_cts5_traj_data_init_struct(...
            g_MC_SpyInDescToProf, 'JULD', ...
            'Buoyancy action time during descent to prof', ...
            g_decArgo_eventData{idFCyPtn(idF(idF2(id))), 6}, ...
            a_cyNum, a_ptnNum);
         g_decArgo_eventDataParamTech{end}.group = g_decArgo_techItemGroupNum;
         if (g_decArgo_eventData{idFCyPtn(idF(idF2(id))), 4} == 9)
            % valve action
            g_decArgo_eventDataParamTech{end+1} = get_cts5_traj_data_init_struct(...
               g_MC_SpyInDescToProf, 'VALVE_ACTION_FLAG', ...
               'Buoyancy action (valve action) during descent to prof', ...
               1, ...
               a_cyNum, a_ptnNum);
            g_decArgo_eventDataParamTech{end}.group = g_decArgo_techItemGroupNum;
         else
            % pump action
            g_decArgo_eventDataParamTech{end+1} = get_cts5_traj_data_init_struct(...
               g_MC_SpyInDescToProf, 'PUMP_ACTION_FLAG', ...
               'Buoyancy action (pump action) during descent to prof', ...
               1, ...
               a_cyNum, a_ptnNum);
            g_decArgo_eventDataParamTech{end}.group = g_decArgo_techItemGroupNum;
         end
         g_decArgo_techItemGroupNum = g_decArgo_techItemGroupNum + 1;
      end
   end
   if (~isempty(deepParkStartDate) && ~isempty(ascentStartDate))
      idF2 = find((evtTimes >= deepParkStartDate) & (evtTimes <= ascentStartDate));
      for id = 1:length(idF2)
         g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
            g_MC_SpyAtProf, 'JULD', ...
            'Buoyancy action time during drift at prof', ...
            g_decArgo_eventData{idFCyPtn(idF(idF2(id))), 6}, ...
            a_cyNum, a_ptnNum);
         g_decArgo_eventDataTraj{end}.group = g_decArgo_trajItemGroupNum;
         g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
            g_MC_SpyAtProf, 'PRES', ...
            'Buoyancy action pressure during drift at prof', ...
            g_decArgo_eventData{idFCyPtn(idF(idF2(id))), 5}{2}, ...
            a_cyNum, a_ptnNum);
         g_decArgo_eventDataTraj{end}.group = g_decArgo_trajItemGroupNum;
         g_decArgo_trajItemGroupNum = g_decArgo_trajItemGroupNum + 1;
         
         g_decArgo_eventDataParamTech{end+1} = get_cts5_traj_data_init_struct(...
            g_MC_SpyAtProf, 'JULD', ...
            'Buoyancy action time during drift at prof', ...
            g_decArgo_eventData{idFCyPtn(idF(idF2(id))), 6}, ...
            a_cyNum, a_ptnNum);
         g_decArgo_eventDataParamTech{end}.group = g_decArgo_techItemGroupNum;
         if (g_decArgo_eventData{idFCyPtn(idF(idF2(id))), 4} == 9)
            % valve action
            g_decArgo_eventDataParamTech{end+1} = get_cts5_traj_data_init_struct(...
               g_MC_SpyAtProf, 'VALVE_ACTION_FLAG', ...
               'Buoyancy action (valve action) during drift at prof', ...
               1, ...
               a_cyNum, a_ptnNum);
            g_decArgo_eventDataParamTech{end}.group = g_decArgo_techItemGroupNum;
         else
            % pump action
            g_decArgo_eventDataParamTech{end+1} = get_cts5_traj_data_init_struct(...
               g_MC_SpyAtProf, 'PUMP_ACTION_FLAG', ...
               'Buoyancy action (pump action) during drift at prof', ...
               1, ...
               a_cyNum, a_ptnNum);
            g_decArgo_eventDataParamTech{end}.group = g_decArgo_techItemGroupNum;
         end
         g_decArgo_techItemGroupNum = g_decArgo_techItemGroupNum + 1;
      end
   end
   if (~isempty(ascentStartDate))
      idF2 = [];
      if (~isempty(ascentEndDate))
         idF2 = find((evtTimes >= ascentStartDate) & (evtTimes <= ascentEndDate));
      else
         % accepted feedback
         idF3 = find([g_decArgo_eventData{idFCyPtn, 4}] == 88);
         if (~isempty(idF3))
            ascentEndDate = g_decArgo_eventData{idFCyPtn(idF3), 6};
            idF2 = find((evtTimes >= ascentStartDate) & (evtTimes <= ascentEndDate));
         end
      end
      for id = 1:length(idF2)
         g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
            g_MC_SpyInAscProf, 'JULD', ...
            'Buoyancy action time during ascent to surface', ...
            g_decArgo_eventData{idFCyPtn(idF(idF2(id))), 6}, ...
            a_cyNum, a_ptnNum);
         g_decArgo_eventDataTraj{end}.group = g_decArgo_trajItemGroupNum;
         g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
            g_MC_SpyInAscProf, 'PRES', ...
            'Buoyancy action pressure during ascent to surface', ...
            g_decArgo_eventData{idFCyPtn(idF(idF2(id))), 5}{2}, ...
            a_cyNum, a_ptnNum);
         g_decArgo_eventDataTraj{end}.group = g_decArgo_trajItemGroupNum;
         g_decArgo_trajItemGroupNum = g_decArgo_trajItemGroupNum + 1;
         
         g_decArgo_eventDataParamTech{end+1} = get_cts5_traj_data_init_struct(...
            g_MC_SpyInAscProf, 'JULD', ...
            'Buoyancy action time during ascent to surface', ...
            g_decArgo_eventData{idFCyPtn(idF(idF2(id))), 6}, ...
            a_cyNum, a_ptnNum);
         g_decArgo_eventDataParamTech{end}.group = g_decArgo_techItemGroupNum;
         if (g_decArgo_eventData{idFCyPtn(idF(idF2(id))), 4} == 9)
            % valve action
            g_decArgo_eventDataParamTech{end+1} = get_cts5_traj_data_init_struct(...
               g_MC_SpyInAscProf, 'VALVE_ACTION_FLAG', ...
               'Buoyancy action (valve action) during ascent to surface', ...
               1, ...
               a_cyNum, a_ptnNum);
            g_decArgo_eventDataParamTech{end}.group = g_decArgo_techItemGroupNum;
         else
            % pump action
            g_decArgo_eventDataParamTech{end+1} = get_cts5_traj_data_init_struct(...
               g_MC_SpyInAscProf, 'PUMP_ACTION_FLAG', ...
               'Buoyancy action (pump action) during ascent to surface', ...
               1, ...
               a_cyNum, a_ptnNum);
            g_decArgo_eventDataParamTech{end}.group = g_decArgo_techItemGroupNum;
         end
         g_decArgo_techItemGroupNum = g_decArgo_techItemGroupNum + 1;
      end
   end
end

% grounding detection (on the beach)
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 35);
if (~isempty(idF))
   for id = 1:length(idF)
      g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
         'GROUNDING START DATE', 'JULD', g_decArgo_eventData{idFCyPtn(idF(id)), 6}, []);
      g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
         g_MC_Grounded, 'JULD', ...
         'Grounding start date', g_decArgo_eventData{idFCyPtn(idF(id)), 6}, ...
         a_cyNum, a_ptnNum);
   end
end

% grounding detection
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 36);
if (~isempty(idF))
   for id = 1:length(idF)
      g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
         'GROUNDING START DATE', 'JULD', g_decArgo_eventData{idFCyPtn(idF(id)), 6}, ...
         g_decArgo_eventData{idFCyPtn(idF(id)), 5}{:});
      g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
         g_MC_Grounded, 'JULD', ...
         'Grounding start date', g_decArgo_eventData{idFCyPtn(idF(id)), 6}, ...
         a_cyNum, a_ptnNum);
      g_decArgo_eventDataTraj{end}.group = g_decArgo_trajItemGroupNum;
      g_decArgo_eventDataTraj{end+1} = get_cts5_traj_data_init_struct(...
         g_MC_Grounded, 'PRES', ...
         'Grounding pressure', g_decArgo_eventData{idFCyPtn(idF(id)), 5}{:}, ...
         a_cyNum, a_ptnNum);
      g_decArgo_eventDataTraj{end}.group = g_decArgo_trajItemGroupNum;
      g_decArgo_trajItemGroupNum = g_decArgo_trajItemGroupNum + 1;
   end
end

% grounding escape
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 204);
if (~isempty(idF))
   for id = 1:length(idF)
      g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
         'GROUNDING END DATE', 'JULD', g_decArgo_eventData{idFCyPtn(idF(id)), 6}, []);
      g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
         110, 'Grounding end time', g_decArgo_eventData{idFCyPtn(idF(id)), 6});
      g_decArgo_eventDataTech{end}.func = '@(x) format_date_yyyymmddhhmiss_dec_argo(x)';
      g_decArgo_eventDataTech{end}.func1 = '@(x) adjust_time_cts5(x)';
   end
end

% hanging detection
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 40);
if (~isempty(idF))
   for id = 1:length(idF)
      g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
         'HANGING START DATE', 'JULD', g_decArgo_eventData{idFCyPtn(idF(id)), 6}, ...
         g_decArgo_eventData{idFCyPtn(idF(id)), 5}{:});
      g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
         174, 'Hanging start time', g_decArgo_eventData{idFCyPtn(idF(id)), 6});
      g_decArgo_eventDataTech{end}.func = '@(x) format_date_yyyymmddhhmiss_dec_argo(x)';
      g_decArgo_eventDataTech{end}.func1 = '@(x) adjust_time_cts5(x)';
      g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
         161, 'Hanging pressure alarm received (dbar)', g_decArgo_eventData{idFCyPtn(idF(id)), 5}{:});
   end
end

% hanging escape
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 45);
if (~isempty(idF))
   for id = 1:length(idF)
      g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
         'HANGING END DATE', 'JULD', g_decArgo_eventData{idFCyPtn(idF(id)), 6}, []);
      g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
         175, 'Hanging end time', g_decArgo_eventData{idFCyPtn(idF(id)), 6});
      g_decArgo_eventDataTech{end}.func = '@(x) format_date_yyyymmddhhmiss_dec_argo(x)';
      g_decArgo_eventDataTech{end}.func1 = '@(x) adjust_time_cts5(x)';
   end
end

% braking
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 34);
if (~isempty(idF))
   for id = 1:length(idF)
      g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
         'BRAKING DATE', 'JULD', g_decArgo_eventData{idFCyPtn(idF(id)), 6}, ...
         g_decArgo_eventData{idFCyPtn(idF(id)), 5}{1});
      g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
         178, 'Braking time', g_decArgo_eventData{idFCyPtn(idF(id)), 6});
      g_decArgo_eventDataTech{end}.func = '@(x) format_date_yyyymmddhhmiss_dec_argo(x)';
      g_decArgo_eventDataTech{end}.func1 = '@(x) adjust_time_cts5(x)';
      g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
         179, 'Braking pressure', g_decArgo_eventData{idFCyPtn(idF(id)), 5}{1});
      g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
         162, 'Braking flag', 1);
   end
end

% ice detection (ISA)
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 111);
if (~isempty(idF))
   g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
      'ICE DETECTION TIME (ISA)', 'JULD', g_decArgo_eventData{idFCyPtn(idF), 6}, []);
   g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
      180, 'Ice detection (ISA) time', g_decArgo_eventData{idFCyPtn(idF), 6});
   g_decArgo_eventDataTech{end}.func = '@(x) format_date_yyyymmddhhmiss_dec_argo(x)';
   g_decArgo_eventDataTech{end}.func1 = '@(x) adjust_time_cts5(x)';
end

% ice detection
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 113);
if (~isempty(idF))
   g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
      'ICE DETECTION TIME', 'JULD', g_decArgo_eventData{idFCyPtn(idF), 6}, ...
      g_decArgo_eventData{idFCyPtn(idF), 5}{:});
   g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
      181, 'Ice detection time', g_decArgo_eventData{idFCyPtn(idF), 6});
   g_decArgo_eventDataTech{end}.func = '@(x) format_date_yyyymmddhhmiss_dec_argo(x)';
   g_decArgo_eventDataTech{end}.func1 = '@(x) adjust_time_cts5(x)';
   g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
      182, 'Ice detection pressure', g_decArgo_eventData{idFCyPtn(idF(id)), 5}{:});
end

% refused feedback
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 87);
if (~isempty(idF))
   % we can have more than one refused feedback
   idF = idF(1);
   g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
      'REFUSED FEEDBACK', 'JULD', g_decArgo_eventData{idFCyPtn(idF), 6}, []);
   g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
      173, 'Refused feedback time', 0);
end

% accepted feedback
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 88);
if (~isempty(idF))
   g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
      'ACCEPTED FEEDBACK', 'JULD', g_decArgo_eventData{idFCyPtn(idF), 6}, []);
   g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
      173, 'Accepted feedback time', 1);
end

% end of life
idF = find([g_decArgo_eventData{idFCyPtn, 4}] == 115);
if (~isempty(idF))
   for id = 1:length(idF)
      g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
         'END OF LIFE TIME', 'JULD', g_decArgo_eventData{idFCyPtn(idF(id)), 6}, []);
      g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
         183, 'End of life time', g_decArgo_eventData{idFCyPtn(idF(id)), 6});
      g_decArgo_eventDataTech{end}.func = '@(x) format_date_yyyymmddhhmiss_dec_argo(x)';
      g_decArgo_eventDataTech{end}.func1 = '@(x) adjust_time_cts5(x)';
      g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
         171, 'End of life flag', 1);
   end
end

% emergency ascent
idF = find(([g_decArgo_eventData{idFCyPtn, 4}] == 31) | ...
   ([g_decArgo_eventData{idFCyPtn, 4}] == 32) | ...
   ([g_decArgo_eventData{idFCyPtn, 4}] == 33) | ...
   ([g_decArgo_eventData{idFCyPtn, 4}] == 46) | ...
   ([g_decArgo_eventData{idFCyPtn, 4}] == 114));
if (~isempty(idF))
   emergencyAscentStartTime = min([g_decArgo_eventData{idFCyPtn(idF), 6}]);

   g_decArgo_eventDataTime{end+1} = get_cts5_time_data_init_struct(...
      'EMERGENCY ASCENT START DATE', 'JULD', emergencyAscentStartTime, []);
   g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
      176, 'Emergency ascent start time', emergencyAscentStartTime);
   g_decArgo_eventDataTech{end}.func = '@(x) format_date_yyyymmddhhmiss_dec_argo(x)';
   g_decArgo_eventDataTech{end}.func1 = '@(x) adjust_time_cts5(x)';
   g_decArgo_eventDataTech{end+1} = get_cts5_tech_data_init_struct(...
      172, 'Emergency ascent flag', 1);
end

% update output value of TECH data
for idEvt = 1:length(g_decArgo_eventDataTech)
   if (isempty(g_decArgo_eventDataTech{idEvt}.func))
      g_decArgo_eventDataTech{idEvt}.valueOutput = num2str(g_decArgo_eventDataTech{idEvt}.valueRaw);
   else
      f = eval(g_decArgo_eventDataTech{idEvt}.func);
      g_decArgo_eventDataTech{idEvt}.valueOutput = f(g_decArgo_eventDataTech{idEvt}.valueRaw);
      if (isempty(g_decArgo_eventDataTech{idEvt}.func1))
         f = eval(g_decArgo_eventDataTech{idEvt}.func1);
         g_decArgo_eventDataTech{idEvt}.valueOutput = f(g_decArgo_eventDataTech{idEvt}.valueOutput);
      end
   end
end

% adjust value of time data
for idEvt = 1:length(g_decArgo_eventDataTime)
   if (isempty(g_decArgo_eventDataTime{idEvt}.time))
      g_decArgo_eventDataTime{idEvt}.timeAdj = adjust_time_cts5(g_decArgo_eventDataTime{idEvt}.time);
   end
end

% adjust value of TRAJ data
for idEvt = 1:length(g_decArgo_eventDataTraj)
   if (strcmp(g_decArgo_eventDataTraj{idEvt}.paramName, 'JULD'))
      if (~isempty(g_decArgo_eventDataTraj{idEvt}.value))
         g_decArgo_eventDataTraj{idEvt}.valueAdj = adjust_time_cts5(g_decArgo_eventDataTraj{idEvt}.value);
      end
   end
end

% adjust value of TECH parameter data
for idEvt = 1:length(g_decArgo_eventDataParamTech)
   if (strcmp(g_decArgo_eventDataParamTech{idEvt}.paramName, 'JULD'))
      if (~isempty(g_decArgo_eventDataParamTech{idEvt}.value))
         g_decArgo_eventDataParamTech{idEvt}.valueAdj = adjust_time_cts5(g_decArgo_eventDataParamTech{idEvt}.value);
      end
   end
end

return

% ------------------------------------------------------------------------------
% Get the basic structure to store trajectory information.
%
% SYNTAX :
%  [o_dataStruct] = get_cts5_traj_data_init_struct( ...
%    a_measCode, a_paramName, a_label, a_value, a_CycleNum, a_patternNum)
%
% INPUT PARAMETERS :
%   a_measCode   : measurement code
%   a_paramName  : parameter name
%   a_label      : item label
%   a_value      : parameter value
%   a_CycleNum   : cycle number
%   a_patternNum : pattern number
%
% OUTPUT PARAMETERS :
%   o_dataStruct : trajectory data initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = get_cts5_traj_data_init_struct( ...
   a_measCode, a_paramName, a_label, a_value, a_CycleNum, a_patternNum)

% output parameters initialization
o_dataStruct = struct( ...
   'label', a_label, ...
   'paramName', a_paramName, ...
   'measCode', a_measCode, ...
   'group', 0, ... % if different from 0: many items are linked to a same measCode
   'value', a_value, ...
   'valueAdj', [], ...
   'source', 'E', ... % 'T': from tech data 'E': from event data
   'cycleNumber', a_CycleNum, ...
   'patternNumber', a_patternNum ...
   );

return

% ------------------------------------------------------------------------------
% Get the basic structure to store time information.
%
% SYNTAX :
%  [o_dataStruct] = get_cts5_time_data_init_struct( ...
%    a_label, a_paramName, a_time, a_pres)
%
% INPUT PARAMETERS :
%   a_label      : item label
%   a_paramName  : parameter name
%   a_time       : time value
%   a_pres       : PRES value
%
% OUTPUT PARAMETERS :
%   o_dataStruct : time data initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = get_cts5_time_data_init_struct( ...
   a_label, a_paramName, a_time, a_pres)

% output parameters initialization
o_dataStruct = struct( ...
   'label', a_label, ...
   'paramName', a_paramName, ...
   'time', a_time, ...
   'timeAdj', [], ...
   'pres', a_pres, ...
   'source', 'E' ... % 'T': from tech data 'E': from event data
   );

return

% ------------------------------------------------------------------------------
% Get the basic structure to store technical information.
%
% SYNTAX :
%  [o_dataStruct] = get_cts5_tech_data_init_struct( ...
%    a_techId, a_label, a_valueRaw)
%
% INPUT PARAMETERS :
%   a_techId   : decoder technical Id
%   a_label    : item label
%   a_valueRaw : technical value (raw)
%
% OUTPUT PARAMETERS :
%   o_dataStruct : technical data initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = get_cts5_tech_data_init_struct( ...
   a_techId, a_label, a_valueRaw)

% output parameters initialization
o_dataStruct = struct( ...
   'label', a_label, ...
   'techId', a_techId, ...
   'func', [], ...
   'func1', [], ...
   'valueRaw', a_valueRaw, ...
   'valueOutput', [], ...
   'source', 'E' ... % 'T': from tech data 'E': from event data
   );

return
