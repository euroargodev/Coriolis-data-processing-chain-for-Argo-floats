% ------------------------------------------------------------------------------
% Get the basic structure to read CTS5-USEA configuration.
%
% SYNTAX :
%  [o_configSectionList, o_configInfoStruct] = init_config_info_struct_128
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
%   02/12/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configSectionList, o_configInfoStruct] = init_config_info_struct_128

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
   {'SURFACE_ACQUISITION'} ...
   {'CYCLE'} ...
   {'ICE_AVOIDANCE'} ...
   {'ISA'} ...
   {'IRIDIUM_RUDICS'} ...
   {'MOTOR'} ...
   {'PAYLOAD'} ...
   {'EMAP_1'} ...
   {'GPS'} ...
   {'SENSOR_'} ...
   {'SENSOR_01'} ...
   {'SENSOR_02'} ...
   {'SENSOR_03'} ...
   {'SENSOR_04'} ...
   {'SENSOR_05'} ...
   {'SENSOR_06'} ...
   {'SENSOR_07'} ...
   {'SENSOR_08'} ...
   {'SENSOR_09'} ...
   {'SENSOR_10'} ...
   {'SENSOR_11'} ...
   {'SENSOR_11'} ...
   {'SENSOR_14'} ...
   {'SENSOR_15'} ...
   {'SENSOR_17'} ...
   {'SENSOR_18'} ...
   {'SDA14'} ...
   {'SPECIAL'} ...
   {'PRESSURE_ACTIVATION'} ...
   {'BATTERY'} ...
   {'PRESSURE_I'} ...
   {'SBE41'} ...
   {'DO'} ...
   {'OCR'} ...
   {'ECO'} ...
   {'SBEPH'} ...
   {'CROVER'} ...
   {'SUNA'} ...
   {'HYDROC'} ...
   {'RAMSES'} ...
   {'OPUS'} ...
   {'UVP6'} ...
   {'UVP6'} ...
   {'MPE'} ...
   {'GUI'} ...
   ];

o_configInfoStruct = [];

o_configInfoStruct.SYSTEM = [];
for idP = 0:12
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%s';
         param.name = 'mission description script';
         param.fmtOut = '%s';
      case 1
         param.fmtIn = '%u';
         param.name = 'event log level of detail';
         param.fmtOut = '%d';
      case 2
         param.fmtIn = '%s';
         param.name = 'decimal and column separators for CSV data files';
         param.fmtOut = '%s';
      case 3
         param.fmtIn = '%s';
         param.name = 'IP address of the float on a local connection via Bluetooth';
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
         param.name = 'complete self-test flag';
         param.fmtOut = '%s';
      case 8
         param.fmtIn = '%u';
         param.name = 'feedback-related risk criterion';
         param.fmtOut = '%d';
      case 9
         param.fmtIn = '%s';
         param.name = 'maximum buoyancy recovery';
         param.fmtOut = '%s';
      case 10
         param.fmtIn = '%s';
         param.name = 'external pressure offset after effective surface only';
         param.fmtOut = '%s';
      case 11
         param.fmtIn = '%u';
         param.name = 'time stamping format for CSV data files';
         param.fmtOut = '%d';
      case 12
         param.fmtIn = '%s';
         param.name = 'mandatory additional memory card for the mission';
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
         param.name = 'rate of descent threshold for SV action (cm/s)';
         param.fmtOut = '%g';
      case 1
         param.fmtIn = '%f';
         param.name = 'rate of ascent threshold for pump action (cm/s)';
         param.fmtOut = '%g';
      case 2
         param.fmtIn = '%f';
         param.name = 'typical rate of descent (cm/s)';
         param.fmtOut = '%g';
      case 3
         param.fmtIn = '%f';
         param.name = 'typical rate of ascent (cm/s)';
         param.fmtOut = '%g';
      case 4
         param.fmtIn = '%u';
         param.name = 'pressure tolerance for positioning in descent (dbar)';
         param.fmtOut = '%d';
      case 5
         param.fmtIn = '%u';
         param.name = 'pressure tolerance for positioning in ascent (dbar)';
         param.fmtOut = '%d';
      case 6
         param.fmtIn = '%u';
         param.name = 'pressure tolerance before repositioning in park (dbar)';
         param.fmtOut = '%d';
      case 7
         param.fmtIn = '%u';
         param.name = 'pressure tolerance for positioning in park (dbar)';
         param.fmtOut = '%d';
      case 8
         param.fmtIn = '%u';
         param.name = 'pressure monitoring period during descent (sec)';
         param.fmtOut = '%d';
      case 9
         param.fmtIn = '%u';
         param.name = 'pressure monitoring period during ascent (sec)';
         param.fmtOut = '%d';
      case 10
         param.fmtIn = '%u';
         param.name = 'pressure monitoring period during drift (sec)';
         param.fmtOut = '%d';
      case 11
         param.fmtIn = '%f';
         param.name = 'maximum volume of an SV action during descent/repositioning (cm3)';
         param.fmtOut = '%g';
      case 12
         param.fmtIn = '%f';
         param.name = 'maximum volume of a pump action during repositioning (cm3)';
         param.fmtOut = '%g';
      case 13
         param.fmtIn = '%f';
         param.name = 'emergence reduction threshold 1 (dbar)';
         param.fmtOut = '%g';
      case 14
         param.fmtIn = '%f';
         param.name = 'emergence reduction threshold 2 (dbar)';
         param.fmtOut = '%g';
      case 15
         param.fmtIn = '%f';
         param.name = 'fixed volume of a pump action during ascent (cm3)';
         param.fmtOut = '%g';
      case 16
         param.fmtIn = '%f';
         param.name = 'fixed volume of a pump action during braking (cm3)';
         param.fmtOut = '%g';
      case 17
         param.fmtIn = '%u';
         param.name = 'SV activation time during phase 2 of emergence reduction (csec)';
         param.fmtOut = '%d';
      case 18
         param.fmtIn = '%f';
         param.name = 'SV activation factor during phase 2 of emergence reduction';
         param.fmtOut = '%g';
      case 19
         param.fmtIn = '%f';
         param.name = 'fixed emergence volume (cm3)';
         param.fmtOut = '%g';
      case 20
         param.fmtIn = '%u';
         param.name = 'end of ascent detection threshold (dbar)';
         param.fmtOut = '%d';
      case 21
         param.fmtIn = '%u';
         param.name = 'deceleration during ascent (0 = none, 1 = low, 5 = high)';
         param.fmtOut = '%d';
      case 22
         param.fmtIn = '%f';
         param.name = 'braking power in ascent abortion (multiplies P15)';
         param.fmtOut = '%g';
   end
   o_configInfoStruct.TECHNICAL{end+1} = param;
end

o_configInfoStruct.PATTERN_ = [];
for idP = 0:8
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%s';
         param.name = 'enable/disable pattern';
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
         param.name = 'time of presence at the surface';
         param.fmtOut = '%s';
      case 5
         param.fmtIn = '%s';
         param.name = 'enable/disable GPS position acquisition';
         param.fmtOut = '%s';
      case 6
         param.fmtIn = '%s';
         param.name = 'enable/disable transmission session';
         param.fmtOut = '%s';
      case 7
         param.fmtIn = '%s';
         param.name = 'enable/disable surface presence synchronization';
         param.fmtOut = '%s';
      case 8
         param.fmtIn = '%f';
         param.name = 'UNUSED IN THIS VERSION';
         param.fmtOut = '%g';
   end
   o_configInfoStruct.PATTERN_{end+1} = param;
end

o_configInfoStruct.ALARM = [];
for idP = 0:28
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%f';
         param.name = 'low battery voltage detection threshold (V)';
         param.fmtOut = '%g';
      case 1
         param.fmtIn = '%f';
         param.name = 'high internal pressure detection threshold (mbar)';
         param.fmtOut = '%g';
      case 2
         param.fmtIn = '%f';
         param.name = 'detection threshold for inconsistent external pressure jumps (cm/s)';
         param.fmtOut = '%g';
      case 3
         param.fmtIn = '%f';
         param.name = 'low external pressure detection threshold (dbar)';
         param.fmtOut = '%g';
      case 4
         param.fmtIn = '%f';
         param.name = 'detection threshold for high external pressure / pressure limit (dbar)';
         param.fmtOut = '%g';
      case 5
         param.fmtIn = '%u';
         param.name = 'detection of broken external pressure sensor (successive errors)';
         param.fmtOut = '%d';
      case 6
         param.fmtIn = [];
         param.name = 'information: Power-on detection';
         param.fmtOut = [];
      case 7
         param.fmtIn = [];
         param.name = 'information: Detection of invalid configuration';
         param.fmtOut = [];
      case 8
         param.fmtIn = [];
         param.name = 'information: Detection of "system" failure';
         param.fmtOut = [];
      case 9
         param.fmtIn = '%f';
         param.name = 'detection threshold for grounding during descent (cm3)';
         param.fmtOut = '%g';
      case 10
         param.fmtIn = '%f';
         param.name = 'detection threshold for snagging during ascent (cm3)';
         param.fmtOut = '%g';
      case 11
         param.fmtIn = [];
         param.name = 'information: "Survival" procedure initiated';
         param.fmtOut = [];
      case 12
         param.fmtIn = [];
         param.name = 'information: Detection of "payload" failure';
         param.fmtOut = [];
      case 13
         param.fmtIn = [];
         param.name = 'information: Detection of "GPS" failure';
         param.fmtOut = [];
      case 14
         param.fmtIn = [];
         param.name = 'information: "End of life" procedure initiated';
         param.fmtOut = [];
      case 15
         param.fmtIn = [];
         param.name = 'information: Detection of "hydraulic" failure';
         param.fmtOut = [];
      case 16
         param.fmtIn = '%f';
         param.name = 'detection of high rate of descent (braking)';
         param.fmtOut = '%g';
      case 17
         param.fmtIn = [];
         param.name = 'information: Detection of failure during external pressure offset';
         param.fmtOut = [];
      case 18
         param.fmtIn = [];
         param.name = 'information: Detection of deployment with "float too heavy"';
         param.fmtOut = [];
      case 19
         param.fmtIn = [];
         param.name = 'information: Detection of deployment with "float too light"';
         param.fmtOut = [];
      case 20
         param.fmtIn = [];
         param.name = 'information: "Feedback" procedure initiated';
         param.fmtOut = [];
      case 21
         param.fmtIn = '%f';
         param.name = 'low battery voltage detection threshold (min. on pump) (V)';
         param.fmtOut = '%g';
      case 22
         param.fmtIn = [];
         param.name = 'information: Detection of "ADC" failure';
         param.fmtOut = [];
      case 23
         param.fmtIn = [];
         param.name = 'information: Detection of ice via "ISA" algorithm';
         param.fmtOut = [];
      case 24
         param.fmtIn = [];
         param.name = 'information: Detection of corrupted measurement file';
         param.fmtOut = [];
      case 25
         param.fmtIn = [];
         param.name = 'information: Detection of "RTC" failure';
         param.fmtOut = [];
      case 26
         param.fmtIn = [];
         param.name = 'information: Detection of pressure switch activation';
         param.fmtOut = [];
      case 27
         param.fmtIn = [];
         param.name = 'information: Detection of "SDA14" failure';
         param.fmtOut = [];
      case 28
         param.fmtIn = [];
         param.name = 'information: Detection of water in the float';
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
         param.name = 'delay time at surface "SA" stage before loop (sec)';
         param.fmtOut = '%d';
      case 1
         param.fmtIn = '%u';
         param.name = 'delay time at surface "SA" stage in "pattern" loop (sec)';
         param.fmtOut = '%d';
      case 2
         param.fmtIn = '%u';
         param.name = 'delay time at surface "SA" stage in "cycle" loop (sec)';
         param.fmtOut = '%d';
      case 3
         param.fmtIn = '%u';
         param.name = 'delay time for test ("TC" stage) (sec)';
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
         param.name = 'enable/disable float recovery in end of life';
         param.fmtOut = '%s';
      case 1
         param.fmtIn = '%s';
         param.name = 'enable/disable GPS position acquisition at end of life';
         param.fmtOut = '%s';
      case 2
         param.fmtIn = '%u';
         param.name = 'transmission period at end of life (sec)';
         param.fmtOut = '%d';
      case 3
         param.fmtIn = '%s';
         param.name = 'list of alarms that can cause end of life';
         param.fmtOut = '%s';
   end
   o_configInfoStruct.END_OF_LIFE{end+1} = param;
end

o_configInfoStruct.SECURITY = [];
for idP = 0:4
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%u';
         param.name = 'management method for grounding detection during descent parking';
         param.fmtOut = '%d';
      case 1
         param.fmtIn = '%u';
         param.name = 'set point offset in case of grounding management by correction (dbar)';
         param.fmtOut = '%d';
      case 2
         param.fmtIn = '%u';
         param.name = 'detection management method for snagging during ascent';
         param.fmtOut = '%d';
      case 3
         param.fmtIn = '%u';
         param.name = 'minimum pressure for correction in case of grounding detection (dbar)';
         param.fmtOut = '%d';
      case 4
         param.fmtIn = '%u';
         param.name = 'management method for grounding detection during descent profile';
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
         param.name = 'enable/disable near-surface deceleration';
         param.fmtOut = '%s';
      case 1
         param.fmtIn = '%u';
         param.name = 'depth for "slow" start of ascent (dbar)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SURFACE_APPROACH{end+1} = param;
end

o_configInfoStruct.SURFACE_ACQUISITION = [];
for idP = 0:1
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%s';
         param.name = 'enable/disable surface acquisition';
         param.fmtOut = '%s';
      case 1
         param.fmtIn = '%u';
         param.name = 'acquisition duration (sec)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SURFACE_ACQUISITION{end+1} = param;
end

o_configInfoStruct.ICE = [];
for idP = 0:3
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%u';
         param.name = 'enable/disable ice detection';
         param.fmtOut = '%d';
      case 1
         param.fmtIn = '%u';
         param.name = 'depth for "slow" start of ascent (dbar)';
         param.fmtOut = '%d';
      case 2
         param.fmtIn = '%u';
         param.name = 'depth for execution of ice detection test (dbar)';
         param.fmtOut = '%d';
      case 3
         param.fmtIn = '%u';
         param.name = 'duration of ice detection test';
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
         param.name = 'enable/disable cycle periodicity';
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

o_configInfoStruct.ICE_AVOIDANCE = [];
for idP = 0:4
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%s';
         param.name = 'enable/disable ice avoidance';
         param.fmtOut = '%s';
      case 1
         param.fmtIn = '%u';
         param.name = 'depth for "slow" start of ascent (dbar)';
         param.fmtOut = '%d';
      case 2
         param.fmtIn = '%u';
         param.name = 'maximum duration period without trying a transmission session (month)';
         param.fmtOut = '%d';
      case 3
         param.fmtIn = '%u';
         param.name = 'systematic abort profile period after ISA detection (days)';
         param.fmtOut = '%d';
      case 4
         param.fmtIn = '%u';
         param.name = 'Systematic abort profile period after collision or cover detection (days)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.ICE_AVOIDANCE{end+1} = param;
end

o_configInfoStruct.ISA = [];
for idP = 0:4
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%s';
         param.name = 'enable/disable ISA detection';
         param.fmtOut = '%s';
      case 1
         param.fmtIn = '%u';
         param.name = 'collection starting depth (dbar)';
         param.fmtOut = '%d';
      case 2
         param.fmtIn = '%u';
         param.name = 'collection stopping depth (dbar)';
         param.fmtOut = '%d';
      case 3
         param.fmtIn = '%f';
         param.name = 'median temperature threshold (degC)';
         param.fmtOut = '%g';
      case 4
         param.fmtIn = '%u';
         param.name = 'successive detections counter threshold';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.ISA{end+1} = param;
end

o_configInfoStruct.IRIDIUM_RUDICS = [];
for idP = 0:8
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%s';
         param.name = 'DNIS number associated with the SIM card';
         param.fmtOut = '%s';
      case 1
         param.fmtIn = '%s';
         param.name = 'login of account associated with float (on the server)';
         param.fmtOut = '%s';
      case 2
         param.fmtIn = '%s';
         param.name = 'password of account associated with float (on the server)';
         param.fmtOut = '%s';
      case 3
         param.fmtIn = '%u';
         param.name = 'serial port number';
         param.fmtOut = '%d';
      case 4
         param.fmtIn = '%u';
         param.name = 'maximum duration of Iridium session (sec)';
         param.fmtOut = '%d';
      case 5
         param.fmtIn = '%u';
         param.name = 'block size for file segmentation';
         param.fmtOut = '%d';
      case 6
         param.fmtIn = '%u';
         param.name = 'measurement file format (*.csv, *.hex extended, *.hex standard)';
         param.fmtOut = '%d';
      case 7
         param.fmtIn = '%u';
         param.name = 'file transmission mode (standard, extended, high speed)';
         param.fmtOut = '%d';
      case 8
         param.fmtIn = '%u';
         param.name = 'unused (graphical interface)';
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
         param.name = 'mechanics identification';
         param.fmtOut = '%s';
      case 1
         param.fmtIn = '%f';
         param.name = 'total oil volume in the hydraulic system (cm3)';
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
         param.name = 'enable/disable "$ADJUST" message';
         param.fmtOut = '%s';
      case 3
         param.fmtIn = '%s';
         param.name = 'enable/disable complete self-test';
         param.fmtOut = '%s';
   end
   o_configInfoStruct.PAYLOAD{end+1} = param;
end

o_configInfoStruct.EMAP_1 = [];
for idP = 0:2
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
         param.name = 'USEA sensor list';
         param.fmtOut = '%s';
   end
   o_configInfoStruct.EMAP_1{end+1} = param;
end

o_configInfoStruct.GPS = [];
for idP = 0:4
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
         param.name = 'enable/disable PPS synchronisation (external module)';
         param.fmtOut = '%s';
      case 3
         param.fmtIn = '%s';
         param.name = 'enable/disable enhanced positioning (altitude 0m)';
         param.fmtOut = '%s';
      case 4
         param.fmtIn = '%s';
         param.name = 'Enable/disable system clock synchronization';
         param.fmtOut = '%s';
   end
   o_configInfoStruct.GPS{end+1} = param;
end

o_configInfoStruct.SENSOR_ = [];
for idP = 0:53
   param = init_basic_struct;
   param.num = idP;
   if (idP <= 45)
      zoneNum = fix((idP-1)/9)+1;
   end
   switch (idP)
      case 0
         param.fmtIn = '%s';
         param.name = 'enable/disable the sensor';
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
         param.name = sprintf('zone %d: processing type', zoneNum);
         param.fmtOut = '%s';
      case {8, 17, 26, 35, 44}
         param.fmtIn = '%s';
         param.name = sprintf('zone %d: synchronization type', zoneNum);
         param.fmtOut = '%s';
      case {9, 18, 27, 36, 45}
         param.fmtIn = '%f';
         param.name = sprintf('zone %d: section depth (dbar)', zoneNum);
         param.fmtOut = '%g';      
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
         param.name = 'sensor shut down time (msec)';
         param.fmtOut = '%d';
      case 52
         param.fmtIn = '%u';
         param.name = 'filtering index of first valid sample';
         param.fmtOut = '%d';
      case 53
         param.fmtIn = '%u';
         param.name = 'number of samples per section in "Eco" acquisition mode';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SENSOR_{end+1} = param;
end

% SBE41
o_configInfoStruct.SENSOR_01 = o_configInfoStruct.SENSOR_;
for idP = 54:60
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 54
         param.fmtIn = '%u';
         param.name = 'CTD "Cut-off" pressure (dbar)';
         param.fmtOut = '%d';
      case 55
         param.fmtIn = '%s';
         param.name = 'enable/disable fast sampling period (1 Hz)';
         param.fmtOut = '%s';
      case 60
         param.fmtIn = '%u';
         param.name = 'surface - sampling period / in-air measurements (sec)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SENSOR_01{end+1} = param;
end

% DO
o_configInfoStruct.SENSOR_02 = o_configInfoStruct.SENSOR_;
for idP = 54:60
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 60
         param.fmtIn = '%u';
         param.name = 'surface - sampling period / in-air measurements (sec)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SENSOR_02{end+1} = param;
end

% OCR
o_configInfoStruct.SENSOR_03 = o_configInfoStruct.SENSOR_;
for idP = 54:60
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 60
         param.fmtIn = '%u';
         param.name = 'surface - sampling period / in-air measurements (sec)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SENSOR_03{end+1} = param;
end

% ECO
o_configInfoStruct.SENSOR_04 = o_configInfoStruct.SENSOR_;
for idP = 54:60
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 60
         param.fmtIn = '%u';
         param.name = 'surface - sampling period / in-air measurements (sec)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SENSOR_04{end+1} = param;
end

% SBEPH
o_configInfoStruct.SENSOR_05 = o_configInfoStruct.SENSOR_;
for idP = 54:60
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 60
         param.fmtIn = '%u';
         param.name = 'surface - sampling period / in-air measurements (sec)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SENSOR_05{end+1} = param;
end

% CROVER
o_configInfoStruct.SENSOR_06 = o_configInfoStruct.SENSOR_;
for idP = 54:60
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 60
         param.fmtIn = '%u';
         param.name = 'surface - sampling period / in-air measurements (sec)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SENSOR_06{end+1} = param;
end

% SUNA
o_configInfoStruct.SENSOR_07 = o_configInfoStruct.SENSOR_;
for idP = 54:60
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 60
         param.fmtIn = '%u';
         param.name = 'surface - sampling period / in-air measurements (sec)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SENSOR_07{end+1} = param;
end

% UVP6
o_configInfoStruct.SENSOR_08 = o_configInfoStruct.SENSOR_;
for idP = 54:62
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 54
         param.fmtIn = '%s';
         param.name = 'zone 1 - configuration file';
         param.fmtOut = '%s';
      case 55
         param.fmtIn = '%s';
         param.name = 'zone 2 - configuration file';
         param.fmtOut = '%s';
      case 56
         param.fmtIn = '%s';
         param.name = 'zone 3 - configuration file';
         param.fmtOut = '%s';
      case 57
         param.fmtIn = '%s';
         param.name = 'zone 4 - configuration file';
         param.fmtOut = '%s';
      case 58
         param.fmtIn = '%s';
         param.name = 'zone 5 - configuration file';
         param.fmtOut = '%s';
      case 59
         param.fmtIn = '%s';
         param.name = 'parking depth drift - configuration file';
         param.fmtOut = '%s';
      case 60
         param.fmtIn = '%u';
         param.name = 'surface - sampling period / in-air measurements (sec)';
         param.fmtOut = '%d';
      case 61
         param.fmtIn = '%u';
         param.name = 'parking depth drift - image count for average';
         param.fmtOut = '%d';
      case 62
         param.fmtIn = '%u';
         param.name = 'parking depth drift - sampling period (sec)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SENSOR_08{end+1} = param;
end

% created because UVP6 sensor generates 4 data types with different
% processings(NKE personal communication)
o_configInfoStruct.SENSOR_09 = o_configInfoStruct.SENSOR_;
for idP = 54:60
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 60
         param.fmtIn = '%u';
         param.name = 'surface - sampling period / in-air measurements (sec)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SENSOR_09{end+1} = param;
end

% created because UVP6 sensor generates 4 data types with different
% processings(NKE personal communication)
o_configInfoStruct.SENSOR_10 = o_configInfoStruct.SENSOR_;
for idP = 54:60
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 60
         param.fmtIn = '%u';
         param.name = 'surface - sampling period / in-air measurements (sec)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SENSOR_10{end+1} = param;
end

% created because UVP6 sensor generates 4 data types with different
% processings(NKE personal communication)
o_configInfoStruct.SENSOR_11 = o_configInfoStruct.SENSOR_;
for idP = 54:60
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 60
         param.fmtIn = '%u';
         param.name = 'surface - sampling period / in-air measurements (sec)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SENSOR_11{end+1} = param;
end

% RAMSES
o_configInfoStruct.SENSOR_14 = o_configInfoStruct.SENSOR_;
for idP = 54:60
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 54
         param.fmtIn = '%u';
         param.name = 'spectrum pixel begin';
         param.fmtOut = '%d';
      case 55
         param.fmtIn = '%u';
         param.name = 'spectrum pixel end';
         param.fmtOut = '%d';
      case 56
         param.fmtIn = '%u';
         param.name = 'spectrum binning';
         param.fmtOut = '%d';
      case 60
         param.fmtIn = '%u';
         param.name = 'surface - sampling period / in-air measurements (sec)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SENSOR_14{end+1} = param;
end

% OPUS
o_configInfoStruct.SENSOR_15 = o_configInfoStruct.SENSOR_;
for idP = 54:70
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 54
         param.fmtIn = '%u';
         param.name = 'spectrum pixel begin';
         param.fmtOut = '%d';
      case 55
         param.fmtIn = '%u';
         param.name = 'spectrum pixel pivot';
         param.fmtOut = '%d';
      case 56
         param.fmtIn = '%u';
         param.name = 'spectrum pixel end';
         param.fmtOut = '%d';
      case 57
         param.fmtIn = '%u';
         param.name = 'spectrum binning';
         param.fmtOut = '%d';
      case 60
         param.fmtIn = '%u';
         param.name = 'surface - sampling period / in-air measurements (sec)';
         param.fmtOut = '%d';
      case 61
         param.fmtIn = '%s';
         param.name = 'zone 1 - acquisition mode';
         param.fmtOut = '%s';
      case 62
         param.fmtIn = '%s';
         param.name = 'zone 2 - acquisition mode';
         param.fmtOut = '%s';
      case 63
         param.fmtIn = '%s';
         param.name = 'zone 3 - acquisition mode';
         param.fmtOut = '%s';
      case 64
         param.fmtIn = '%s';
         param.name = 'zone 4 - acquisition mode';
         param.fmtOut = '%s';
      case 65
         param.fmtIn = '%s';
         param.name = 'zone 5 - acquisition mode';
         param.fmtOut = '%s';
      case 66
         param.fmtIn = '%u';
         param.name = 'zone 1 - dark subsampling';
         param.fmtOut = '%d';
      case 67
         param.fmtIn = '%u';
         param.name = 'zone 2 - dark subsampling';
         param.fmtOut = '%d';
      case 68
         param.fmtIn = '%u';
         param.name = 'zone 3 - dark subsampling';
         param.fmtOut = '%d';
      case 69
         param.fmtIn = '%u';
         param.name = 'zone 4 - dark subsampling';
         param.fmtOut = '%d';
      case 70
         param.fmtIn = '%u';
         param.name = 'zone 5 - dark subsampling';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SENSOR_15{end+1} = param;
end

% MPE
o_configInfoStruct.SENSOR_17 = o_configInfoStruct.SENSOR_;
for idP = 54:60
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 60
         param.fmtIn = '%u';
         param.name = 'surface - sampling period / in-air measurements (sec)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SENSOR_17{end+1} = param;
end

% HYDROC
o_configInfoStruct.SENSOR_18 = o_configInfoStruct.SENSOR_;
for idP = 54:60
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 54
         param.fmtIn = '%u';
         param.name = 'warm-up time';
         param.fmtOut = '%d';
      case 55
         param.fmtIn = '%u';
         param.name = 'zero time';
         param.fmtOut = '%d';
      case 56
         param.fmtIn = '%u';
         param.name = 'flush time';
         param.fmtOut = '%d';
      case 57
         param.fmtIn = '%u';
         param.name = 'warm-up filter';
         param.fmtOut = '%d';
      case 58
         param.fmtIn = '%u';
         param.name = 'zero filter';
         param.fmtOut = '%d';
      case 59
         param.fmtIn = '%u';
         param.name = 'flush filter';
         param.fmtOut = '%d';
      case 60
         param.fmtIn = '%u';
         param.name = 'surface - sampling period / in-air measurements (sec)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SENSOR_18{end+1} = param;
end

o_configInfoStruct.SPECIAL = [];
for idP = 0:1
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%s';
         param.name = 'enable/disable sub-surface duration optimization';
         param.fmtOut = '%s';
      case 1
         param.fmtIn = '%s';
         param.name = 'enable/disable sub-surface brake action';
         param.fmtOut = '%s';
   end
   o_configInfoStruct.SPECIAL{end+1} = param;
end

o_configInfoStruct.PRESSURE_ACTIVATION = [];
for idP = 0:2
   param = init_basic_struct;
   param.num = idP;
   switch (idP)
      case 0
         param.fmtIn = '%s';
         param.name = 'enable/disable the pressure activation';
         param.fmtOut = '%s';
      case 1
         param.fmtIn = '%u';
         param.name = 'pressure threshold for mission activation (dbar)';
         param.fmtOut = '%d';
      case 0
         param.fmtIn = '%u';
         param.name = 'maximum duration of the pressure test (sec)';
         param.fmtOut = '%d';
   end
   o_configInfoStruct.SPECIAL{end+1} = param;
end

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

o_configInfoStruct.DO = [];
param = init_basic_struct;
param.num = 0;
param.fmtIn = '%u';
param.name = 'serial port number';
param.fmtOut = '%d';
o_configInfoStruct.DO{end+1} = param;

o_configInfoStruct.OCR = [];
param = init_basic_struct;
param.num = 0;
param.fmtIn = '%u';
param.name = 'serial port number';
param.fmtOut = '%d';
o_configInfoStruct.OCR{end+1} = param;

o_configInfoStruct.ECO = [];
param = init_basic_struct;
param.num = 0;
param.fmtIn = '%u';
param.name = 'serial port number';
param.fmtOut = '%d';
o_configInfoStruct.ECO{end+1} = param;

o_configInfoStruct.CROVER = [];
param = init_basic_struct;
param.num = 0;
param.fmtIn = '%u';
param.name = 'serial port number';
param.fmtOut = '%d';
o_configInfoStruct.CROVER{end+1} = param;

o_configInfoStruct.SUNA = [];
param = init_basic_struct;
param.num = 0;
param.fmtIn = '%u';
param.name = 'serial port number';
param.fmtOut = '%d';
o_configInfoStruct.SUNA{end+1} = param;

o_configInfoStruct.SBEPH = [];
param = init_basic_struct;
param.num = 0;
param.fmtIn = '%u';
param.name = 'serial port number';
param.fmtOut = '%d';
o_configInfoStruct.SBEPH{end+1} = param;

o_configInfoStruct.UVP6 = [];
param = init_basic_struct;
param.num = 0;
param.fmtIn = '%u';
param.name = 'serial port number';
param.fmtOut = '%d';
o_configInfoStruct.UVP6{end+1} = param;

o_configInfoStruct.RAMSES = [];
param = init_basic_struct;
param.num = 0;
param.fmtIn = '%u';
param.name = 'serial port number';
param.fmtOut = '%d';
o_configInfoStruct.RAMSES{end+1} = param;

o_configInfoStruct.OPUS = [];
param = init_basic_struct;
param.num = 0;
param.fmtIn = '%u';
param.name = 'serial port number';
param.fmtOut = '%d';
o_configInfoStruct.OPUS{end+1} = param;

o_configInfoStruct.MPE = [];
param = init_basic_struct;
param.num = 0;
param.fmtIn = '%u';
param.name = 'serial port number';
param.fmtOut = '%d';
o_configInfoStruct.MPE{end+1} = param;

o_configInfoStruct.HYDROC = [];
param = init_basic_struct;
param.num = 0;
param.fmtIn = '%u';
param.name = 'serial port number';
param.fmtOut = '%d';
o_configInfoStruct.HYDROC{end+1} = param;

o_configInfoStruct.GUI = [];

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
%   09/09/2020 - RNU - creation
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
