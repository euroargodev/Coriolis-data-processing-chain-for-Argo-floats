% ------------------------------------------------------------------------------
% Get the basic structure to read APMT configuration.
%
% SYNTAX :
%  [o_configSectionList, o_configInfoStruct] = init_config_info_struct_121_to_123
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_configSectionList : list of sections
%   o_configInfoStruct  : information on each section
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configSectionList, o_configInfoStruct] = init_config_info_struct_121_to_123

% list of expected sections
o_configSectionList = [ ...
   {'SYSTEM'} ...
   {'TECHNICAL'} ...
   {'PATTERN_'} ...
   {'ALARM'} ...
   {'TEMPORIZATION'} ...
   {'END_OF_LIFE'} ...
   {'SECURITY'} ...
   {'SURFACE_APPROACH'} ...
   {'ICE'} ...
   {'CYCLE'} ...
   {'IRIDIUM_RUDICS'} ...
   {'MOTOR'} ...
   {'PAYLOAD'} ...
   {'GPS'} ...
   {'SENSOR_'} ...
   {'SENSOR_01'} ...
   {'BATTERY'} ...
   {'PRESSURE_I'} ...
   {'SBE41'} ...
   ];

o_configInfoStruct = [];

o_configInfoStruct.SYSTEM = [];
for idP = 0:12
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%s';
         param.name = 'mission description';
         param.fmtOut = '%s';
      case 1
         param.fmtIn = '%u';
         param.name = 'max level of events report';
         param.fmtOut = '%d';
      case 2
         param.fmtIn = '%s';
         param.name = 'CSV data file decimal and column separator';
         param.fmtOut = '%s';
      case 3
         param.fmtIn = '%s';
         param.name = 'float bluetooth IP addres';
         param.fmtOut = '%s';
      case 4
         param.fmtIn = '%s';
         param.name = 'system task list';
         param.fmtOut = '%s';
      case 5
         param.fmtIn = '%s';
         param.name = 'user log flag';
         param.fmtOut = '%s';
      case 6
         param.fmtIn = '%s';
         param.name = 'system log flag';
         param.fmtOut = '%s';
      case 7
         param.fmtIn = '%s';
         param.name = 'full autotest flag';
         param.fmtOut = '%s';
      case 8
         param.fmtIn = '%u';
         param.name = 'retroaction risk level';
         param.fmtOut = '%d';
      case 9
         param.fmtIn = '%s';
         param.name = 'full buoyancy flag';
         param.fmtOut = '%s';
      case 10
         param.fmtIn = '%s';
         param.name = 'external offset pres after surface flag';
         param.fmtOut = '%s';
      case 11
         param.fmtIn = '%u';
         param.name = 'date format in CSV file';
         param.fmtOut = '%d';
      case 12
         param.fmtIn = '%s';
         param.name = 'additional memory mandatory flag';
         param.fmtOut = '%s';
   end
   o_configInfoStruct.SYSTEM{end+1} = param;
end

o_configInfoStruct.TECHNICAL = [];
for idP = 0:22
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%f';
         param.name = 'min descent speed before EV action (cm/s)';
         param.fmtOut = '%g';
      case 1
         param.fmtIn = '%f';
         param.name = 'min ascent speed before pump action (cm/s)';
         param.fmtOut = '%g';
      case 2
         param.fmtIn = '%f';
         param.name = 'target descent speed (cm/s)';
         param.fmtOut = '%g';
      case 3
         param.fmtIn = '%f';
         param.name = 'target ascent speed (cm/s)';
         param.fmtOut = '%g';
      case 4
         param.fmtIn = '%u';
         param.name = 'descent depth interval (dbar)';
         param.fmtOut = '%d';
      case 5
         param.fmtIn = '%u';
         param.name = 'ascent depth interval (dbar)';
         param.fmtOut = '%d';
      case 6
         param.fmtIn = '%u';
         param.name = 'drift depth interval (dbar)';
         param.fmtOut = '%d';
      case 7
         param.fmtIn = '%u';
         param.name = 'drift repositionning depth interval (dbar)';
         param.fmtOut = '%d';
      case 8
         param.fmtIn = '%u';
         param.name = 'descent pres scrutation period (sec)';
         param.fmtOut = '%d';
      case 9
         param.fmtIn = '%u';
         param.name = 'ascent pres scrutation period (sec)';
         param.fmtOut = '%d';
      case 10
         param.fmtIn = '%u';
         param.name = 'drift pres scrutation period (sec)';
         param.fmtOut = '%d';
      case 11
         param.fmtIn = '%f';
         param.name = 'oil volume max for EV descent or repositionning action (cm3)';
         param.fmtOut = '%g';
      case 12
         param.fmtIn = '%f';
         param.name = 'oil volume max for pump repositionning action (cm3)';
         param.fmtOut = '%g';
      case 13
         param.fmtIn = '%f';
         param.name = 'buoyancy reduction first threshold (dbar)';
         param.fmtOut = '%g';
      case 14
         param.fmtIn = '%f';
         param.name = 'buoyancy reduction second threshold (dbar)';
         param.fmtOut = '%g';
      case 15
         param.fmtIn = '%f';
         param.name = 'nominal oil volume for pump ascent action (cm3)';
         param.fmtOut = '%g';
      case 16
         param.fmtIn = '%f';
         param.name = 'nominal oil volume for pump descent action (cm3)';
         param.fmtOut = '%g';
      case 17
         param.fmtIn = '%u';
         param.name = 'EV activation time during second phase of buoyancy reduction (csec)';
         param.fmtOut = '%d';
      case 18
         param.fmtIn = '%f';
         param.name = 'EV activation factor during second phase of buoyancy reduction';
         param.fmtOut = '%g';
      case 19
         param.fmtIn = '%f';
         param.name = 'nominal oil volume for final buoyancy acquisition (cm3)';
         param.fmtOut = '%g';
      case 20
         param.fmtIn = '%u';
         param.name = 'ascend end threshold (dbar)';
         param.fmtOut = '%d';
      case 21
         param.fmtIn = '%u';
         param.name = 'ascent slow-down type (0:none, 1:low, 2:high)';
         param.fmtOut = '%d';
      case 22
         param.fmtIn = '%f';
         param.name = 'slow-down factor for cancelled ascent (x P15)';
         param.fmtOut = '%g';
   end
   o_configInfoStruct.TECHNICAL{end+1} = param;
end

o_configInfoStruct.PATTERN_ = [];
for idP = 0:7
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%s';
         param.name = 'pattern activation flag';
         param.fmtOut = '%s';
      case 1
         param.fmtIn = '%u';
         param.name = 'park pressure (dbar)';
         param.fmtOut = '%d';
      case 2
         param.fmtIn = '%u';
         param.name = 'profile pressure (dbar)';
         param.fmtOut = '%d';
      case 3
         param.fmtIn = '%f';
         param.name = 'pattern duration (sec)';
         param.fmtOut = '%g';
      case 4
         param.fmtIn = '%s';
         param.name = 'surface time';
         param.fmtOut = '%s';
      case 5
         param.fmtIn = '%s';
         param.name = 'GPS location acquisition flag';
         param.fmtOut = '%s';
      case 6
         param.fmtIn = '%s';
         param.name = 'data transmission flag';
         param.fmtOut = '%s';
      case 7
         param.fmtIn = '%s';
         param.name = 'surface synchronisation flag';
         param.fmtOut = '%s';
   end
   o_configInfoStruct.PATTERN_{end+1} = param;
end

o_configInfoStruct.ALARM = [];
for idP = 0:25
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%f';
         param.name = 'threshold for low battery alarm (V)';
         param.fmtOut = '%g';
      case 1
         param.fmtIn = '%f';
         param.name = 'threshold for high internal pressure alarm (mbar)';
         param.fmtOut = '%g';
      case 2
         param.fmtIn = '%f';
         param.name = 'threshold for inconsistent external pressure alarm (cm/s)';
         param.fmtOut = '%g';
      case 3
         param.fmtIn = '%f';
         param.name = 'threshold for low external pressure alarm (dbar)';
         param.fmtOut = '%g';
      case 4
         param.fmtIn = '%f';
         param.name = 'threshold for high external pressure vs max pressure alarm (dbar)';
         param.fmtOut = '%g';
      case 5
         param.fmtIn = '%u';
         param.name = 'threshold for external pressure sensor failed alarm';
         param.fmtOut = '%d';
      case 6
         param.fmtIn = [];
         param.name = 'power-on information';
         param.fmtOut = [];
      case 7
         param.fmtIn = [];
         param.name = 'invalid configuration information';
         param.fmtOut = [];
      case 8
         param.fmtIn = [];
         param.name = 'system failure information';
         param.fmtOut = [];
      case 9
         param.fmtIn = '%f';
         param.name = 'threshold for grounding during descent alarm (cm3)';
         param.fmtOut = '%g';
      case 10
         param.fmtIn = '%f';
         param.name = 'threshold for grounding during ascent alarm (cm3)';
         param.fmtOut = '%g';
      case 11
         param.fmtIn = [];
         param.name = 'emergency phase information';
         param.fmtOut = [];
      case 12
         param.fmtIn = [];
         param.name = 'payload failure information';
         param.fmtOut = [];
      case 13
         param.fmtIn = [];
         param.name = 'GPS failure information';
         param.fmtOut = [];
      case 14
         param.fmtIn = [];
         param.name = 'EOL phase information';
         param.fmtOut = [];
      case 15
         param.fmtIn = [];
         param.name = 'hydraulic failure information';
         param.fmtOut = [];
      case 16
         param.fmtIn = '%f';
         param.name = 'threshold for high descent speed alarm';
         param.fmtOut = '%g';
      case 17
         param.fmtIn = [];
         param.name = 'offset pressure measurement failure information';
         param.fmtOut = [];
      case 18
         param.fmtIn = [];
         param.name = 'heavy float at deployment information';
         param.fmtOut = [];
      case 19
         param.fmtIn = [];
         param.name = 'light float at deployment information';
         param.fmtOut = [];
      case 20
         param.fmtIn = [];
         param.name = 'retroaction phase started information';
         param.fmtOut = [];
      case 21
         param.fmtIn = '%f';
         param.name = 'threshold for low battery level alarm (V)';
         param.fmtOut = '%g';
      case 22
         param.fmtIn = [];
         param.name = 'ADC failure information';
         param.fmtOut = [];
      case 23
         param.fmtIn = [];
         param.name = 'ISA enable information';
         param.fmtOut = [];
      case 24
         param.fmtIn = [];
         param.name = 'corrupted measurement file information';
         param.fmtOut = [];
      case 25
         param.fmtIn = [];
         param.name = 'RTC failure information';
         param.fmtOut = [];
   end
   o_configInfoStruct.ALARM{end+1} = param;
end

o_configInfoStruct.TEMPORIZATION = [];
for idP = 0:3
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%u';
         param.name = 'SA step before loops waiting time (sec)';
         param.fmtOut = '%d';
      case 1
         param.fmtIn = '%u';
         param.name = 'SA step within pattern loops waiting time (sec)';
         param.fmtOut = '%d';
      case 2
         param.fmtIn = '%u';
         param.name = 'SA step within cycle loops waiting time (sec)';
         param.fmtOut = '%d';
      case 3
         param.fmtIn = '%u';
         param.name = 'TC step waiting time (sec)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.TEMPORIZATION{end+1} = param;
end

o_configInfoStruct.END_OF_LIFE = [];
for idP = 0:3
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%s';
         param.name = 'scuttling flag';
         param.fmtOut = '%s';
      case 1
         param.fmtIn = '%s';
         param.name = 'GPS acquisition flag';
         param.fmtOut = '%s';
      case 2
         param.fmtIn = '%u';
         param.name = 'transmission period (sec)';
         param.fmtOut = '%d';
      case 3
         param.fmtIn = '%s';
         param.name = 'alarm list for EOL transition';
         param.fmtOut = '%s';
   end
   o_configInfoStruct.END_OF_LIFE{end+1} = param;
end

o_configInfoStruct.SECURITY = [];
for idP = 0:3
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%u';
         param.name = 'descent grounding mode';
         param.fmtOut = '%d';
      case 1
         param.fmtIn = '%u';
         param.name = 'pressure shift for descent grounding (dbar)';
         param.fmtOut = '%d';
      case 2
         param.fmtIn = '%u';
         param.name = 'ascent grounding mode';
         param.fmtOut = '%d';
      case 3
         param.fmtIn = '%u';
         param.name = 'pressure shift for ascent grounding';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SECURITY{end+1} = param;
end

o_configInfoStruct.SURFACE_APPROACH = [];
for idP = 0:1
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%s';
         param.name = 'surface slow-down flag';
         param.fmtOut = '%s';
      case 1
         param.fmtIn = '%u';
         param.name = 'surface slow-down threshold (dbar)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SURFACE_APPROACH{end+1} = param;
end

o_configInfoStruct.ICE = [];
for idP = 0:3
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%u';
         param.name = 'ice detection flag';
         param.fmtOut = '%d';
      case 1
         param.fmtIn = '%u';
         param.name = 'surface slow-down threshold (dbar)';
         param.fmtOut = '%d';
      case 2
         param.fmtIn = '%u';
         param.name = 'ice detection test depth (dbar)';
         param.fmtOut = '%d';
      case 3
         param.fmtIn = '%u';
         param.name = 'ice detection test duration';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.ICE{end+1} = param;
end

o_configInfoStruct.CYCLE = [];
for idP = 0:2
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%s';
         param.name = 'cycle periodicity flag';
         param.fmtOut = '%s';
      case 1
         param.fmtIn = '%u';
         param.name = 'park pressure (dbar)';
         param.fmtOut = '%d';
      case 2
         param.fmtIn = '%u';
         param.name = 'cycle duration (sec)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.CYCLE{end+1} = param;
end

o_configInfoStruct.IRIDIUM_RUDICS = [];
for idP = 0:7
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%s';
         param.name = 'DNIS number of SIM card';
         param.fmtOut = '%s';
      case 1
         param.fmtIn = '%s';
         param.name = 'login name';
         param.fmtOut = '%s';
      case 2
         param.fmtIn = '%s';
         param.name = 'password';
         param.fmtOut = '%s';
      case 3
         param.fmtIn = '%u';
         param.name = 'serial port number';
         param.fmtOut = '%d';
      case 4
         param.fmtIn = '%u';
         param.name = 'Iridium session max duration (sec)';
         param.fmtOut = '%d';
      case 5
         param.fmtIn = '%u';
         param.name = 'packet size for file splitting';
         param.fmtOut = '%d';
      case 6
         param.fmtIn = '%u';
         param.name = 'data file format';
         param.fmtOut = '%d';
      case 7
         param.fmtIn = '%u';
         param.name = 'data file transmission mode';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.IRIDIUM_RUDICS{end+1} = param;
end

o_configInfoStruct.MOTOR = [];
for idP = 0:1
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%s';
         param.name = 'motor type';
         param.fmtOut = '%s';
      case 1
         param.fmtIn = '%f';
         param.name = 'oil volume in hydraulic circuit (cm3)';
         param.fmtOut = '%g';
   end
   o_configInfoStruct.MOTOR{end+1} = param;
end

o_configInfoStruct.PAYLOAD = [];
for idP = 0:3
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%u';
         param.name = 'serial port number';
         param.fmtOut = '%d';
      case 1
         param.fmtIn = '%u';
         param.name = 'power output number';
         param.fmtOut = '%d';
      case 2
         param.fmtIn = '%s';
         param.name = '$ADJSUT message activation flag';
         param.fmtOut = '%s';
      case 3
         param.fmtIn = '%s';
         param.name = 'full autotest activation flag';
         param.fmtOut = '%s';
   end
   o_configInfoStruct.PAYLOAD{end+1} = param;
end

o_configInfoStruct.GPS = [];
for idP = 0:3
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%u';
         param.name = 'serial port number';
         param.fmtOut = '%d';
      case 1
         param.fmtIn = '%u';
         param.name = 'power output number';
         param.fmtOut = '%d';
      case 2
         param.fmtIn = '%s';
         param.name = 'PPS synchronisation activation flag';
         param.fmtOut = '%s';
      case 3
         param.fmtIn = '%s';
         param.name = 'improved positionning activation flag';
         param.fmtOut = '%s';
   end
   o_configInfoStruct.GPS{end+1} = param;
end

o_configInfoStruct.SENSOR_ = [];
for idP = 0:53
   param = init_basic_struct;
   param.num = idP;
   zoneNum = fix((idP-1)/9)+1;
   switch (idP)
      case 0
         param.fmtIn = '%s';
         param.name = 'sensor activation flag';
         param.fmtOut = '%s';
      case {1, 10, 19, 28, 37}
         param.fmtIn = '%u';
         param.name = sprintf('zone %d: sampling period - descent to park (sec)', zoneNum);
         param.fmtOut = '%d';
      case {2, 11, 20, 29, 38}
         param.fmtIn = '%u';
         param.name = sprintf('zone %d: sampling period - drift at park (sec)', zoneNum);
         param.fmtOut = '%d';
      case {3, 12, 21, 30, 39}
         param.fmtIn = '%u';
         param.name = sprintf('zone %d: sampling period - descent to prof (sec)', zoneNum);
         param.fmtOut = '%d';
      case {4, 13, 22, 31, 40}
         param.fmtIn = '%u';
         param.name = sprintf('zone %d: sampling period - drift at prof (sec)', zoneNum);
         param.fmtOut = '%d';
      case {5, 14, 23, 32, 41}
         param.fmtIn = '%u';
         param.name = sprintf('zone %d: sampling period - ascent (sec)', zoneNum);
         param.fmtOut = '%d';
      case {6, 15, 24, 33, 42}
         param.fmtIn = '%u';
         param.name = sprintf('zone %d: acquisition type', zoneNum);
         param.fmtOut = '%d';
      case {7, 16, 25, 34, 43}
         param.fmtIn = '%s';
         param.name = sprintf('zone %d: treatment type', zoneNum);
         param.fmtOut = '%s';
      case {8, 17, 26, 35, 44}
         param.fmtIn = '%s';
         param.name = sprintf('zone %d: synchronization type', zoneNum);
         param.fmtOut = '%s';
      case {9, 18, 27, 36, 45}
         param.fmtIn = '%u';
         param.name = sprintf('zone %d: slice thickness (dbar)', zoneNum);
         param.fmtOut = '%d';      
      case 46
         param.fmtIn = '%u';
         param.name = 'zone 1 to zone 2 threshold (dbar)';
         param.fmtOut = '%d';
      case 47
         param.fmtIn = '%u';
         param.name = 'zone 2 to zone 3 threshold (dbar)';
         param.fmtOut = '%d';
      case 48
         param.fmtIn = '%u';
         param.name = 'zone 3 to zone 4 threshold (dbar)';
         param.fmtOut = '%d';
      case 49
         param.fmtIn = '%u';
         param.name = 'zone 4 to zone 5 threshold (dbar)';
         param.fmtOut = '%d';
      case 50
         param.fmtIn = '%u';
         param.name = 'sensor warm-up time (msec)';
         param.fmtOut = '%d';
      case 51
         param.fmtIn = '%u';
         param.name = 'sensor power-off time (msec)';
         param.fmtOut = '%d';
      case 52
         param.fmtIn = '%u';
         param.name = 'first valid sample filtering index';
         param.fmtOut = '%d';
      case 53
         param.fmtIn = '%u';
         param.name = 'number of samples per slice in ECO mode acquisition';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SENSOR_{end+1} = param;
end

o_configInfoStruct.SENSOR_01 = o_configInfoStruct.SENSOR_;
param = init_basic_struct;
param.num = 54;
param.fmtIn = '%u';
param.name = 'CTD cut-off pressure (dbar)';
param.fmtOut = '%d';
o_configInfoStruct.SENSOR_01{end+1} = param;
   
o_configInfoStruct.BATTERY = [];
for idP = 0:3
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%u';
         param.name = 'first calibration point raw value';
         param.fmtOut = '%d';
      case 1
         param.fmtIn = '%u';
         param.name = 'second calibration point raw value';
         param.fmtOut = '%d';
      case 2
         param.fmtIn = '%f';
         param.name = 'first calibration point physical value';
         param.fmtOut = '%g';
      case 3
         param.fmtIn = '%f';
         param.name = 'second calibration point physical value';
         param.fmtOut = '%g';
   end
   o_configInfoStruct.BATTERY{end+1} = param;
end

o_configInfoStruct.PRESSURE_I = [];
for idP = 0:3
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%u';
         param.name = 'first calibration point raw value';
         param.fmtOut = '%d';
      case 1
         param.fmtIn = '%u';
         param.name = 'second calibration point raw value';
         param.fmtOut = '%d';
      case 2
         param.fmtIn = '%f';
         param.name = 'first calibration point physical value';
         param.fmtOut = '%g';
      case 3
         param.fmtIn = '%f';
         param.name = 'second calibration point physical value';
         param.fmtOut = '%g';
   end
   o_configInfoStruct.PRESSURE_I{end+1} = param;
end

o_configInfoStruct.SBE41 = [];
param = init_basic_struct;
param.num = 0;
param.fmtIn = '%u';
param.name = 'serial port number';
param.fmtOut = '%d';
o_configInfoStruct.SBE41{end+1} = param;

return

% ------------------------------------------------------------------------------
% Get the basic structure to store information on each item of a section.
%
% SYNTAX :
%  [o_newStruct] = init_basic_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_newStruct : initializes new structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_newStruct] = init_basic_struct

o_newStruct = [];
o_newStruct.rawData = [];
o_newStruct.id = [];
o_newStruct.fmtIn = [];
o_newStruct.name = [];
o_newStruct.fmtOut = [];

o_newStruct.count = 1;
o_newStruct.func = [];
o_newStruct.labelId = -1;

return
