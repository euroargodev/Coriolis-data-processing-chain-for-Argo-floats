% ------------------------------------------------------------------------------
% Parse APMT configuration files.
%
% SYNTAX :
%  [o_configData] = read_apmt_config(a_inputFilePathName, a_decoderId)
%
% INPUT PARAMETERS :
%   a_inputFilePathName : APMT configuration file path name
%   a_decoderId         : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_configData : APMT configuration data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configData] = read_apmt_config(a_inputFilePathName, a_decoderId)

% output parameters initialization
o_configData = [];


if ~(exist(a_inputFilePathName, 'file') == 2)
   fprintf('ERROR: read_apmt_config: File not found: %s\n', a_inputFilePathName);
   return;
end

% create the configuration info structure
[configSectionList, configInfoStruct] = init_config_info_struct(a_decoderId);

% open the file and read the data
fId = fopen(a_inputFilePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_inputFilePathName);
   return;
end
data = [];
while (1)
   line = fgetl(fId);
   if (isempty(line))
      continue;
   end
   if (line == -1)
      break;
   end
   data{end+1} = line;
end
fclose(fId);

% delete the part of the file padded with 0x1A
stop = 0;
while(~stop && ~isempty(data))
   uLastLine = unique(data{end});
   if ((length(uLastLine) == 1) && (uLastLine == hex2dec('1a')))
      data(end) = [];
   else
      stop = 1;
   end
end

% parse the data according to expected sections
configData = [];
currentStruct = [];
currentSectionNum = -1;
newSectionNum = -1;
for idL = 1:length(data)
   line = data{idL};

   % look for a new section header
   if (line(1) == '[')
      for idSection = 1:length(configSectionList)
         sectionName = configSectionList{idSection};
         if (strcmp(line, ['[' sectionName ']']))
            newSectionNum = idSection;
            break;
         end
      end
      if (newSectionNum == -1)
         for idSection = 1:length(configSectionList)
            sectionName = configSectionList{idSection};
            if (sectionName(end) == '_')
               if (~isempty(strfind(line, sectionName)))
                  newSectionName = line(2:end-1);
                  configSectionList{end+1} = newSectionName;
                  configInfoStruct.(newSectionName) = configInfoStruct.(sectionName);
                  newSectionNum = length(configSectionList);
                  break;
               end
            end
         end
      end
      if (newSectionNum == -1)
         fprintf('WARNING: read_apmt_config: Unexpected section (%s) found in file (%s)\n', ...
            line(2:end-1), a_inputFilePathName);
         newSectionNum = 0;
      end
   end
   
   % consider the new section
   if (newSectionNum ~= -1)
      if ((currentSectionNum ~= -1) && (currentSectionNum ~= 0))
         fieldName = configSectionList{currentSectionNum};
         if (~isfield(configData, fieldName)) % if multiple configurations are present in the file, only the first one should be considered (see 3aa9_091_01_apmt.ini)
            configData.(fieldName).raw = currentStruct;
            configData.(fieldName).num = [];
            configData.(fieldName).name = [];
            configData.(fieldName).fmt = [];
            configData.(fieldName).data = [];
         end
      end
      currentStruct = [];
      currentSectionNum = newSectionNum;
      newSectionNum = -1;
      continue;
   end

   currentStruct{end+1} = line;
end

if ((currentSectionNum ~= -1) && (currentSectionNum ~= 0))
   fieldName = configSectionList{currentSectionNum};
   if (~isfield(configData, fieldName)) % if multiple configurations are present in the file, only the first one should be considered (see 3aa9_091_01_apmt.ini)
      configData.(fieldName).raw = currentStruct;
      configData.(fieldName).num = [];
      configData.(fieldName).name = [];
      configData.(fieldName).fmt = [];
      configData.(fieldName).data = [];
   end
end

% retrieve technical information
fieldNames = fieldnames(configData);
for idF = 1:length(fieldNames)
   if (strcmp(fieldNames{idF}, 'GUI'))
      continue;
   end
   rawData = configData.(fieldNames{idF}).raw;
   for idI = 1:length(rawData)
      data = rawData{idI};
      idFEq = strfind(data, '=');
      % manage known errors
      if (isempty(idFEq))
         if (strcmp(data, 'P6False'))
            dataOri = data;
            data = 'P6=False';
            fprintf('WARNING: read_apmt_config: ''%s'' replaced by ''%s'' in the ''%s'' section of the file: %s\n', ...
               dataOri, data, fieldNames{idF}, a_inputFilePathName);
            idFEq = strfind(data, '=');
         end
      end
      if (~isempty(idFEq))
         paramNum = str2num(data(2:idFEq(1)-1));
         paramInfoStruct = configInfoStruct.(fieldNames{idF}){paramNum+1};
         configData.(fieldNames{idF}).num{end+1} = paramInfoStruct.num;
         configData.(fieldNames{idF}).name{end+1} = paramInfoStruct.name;
         configData.(fieldNames{idF}).fmt{end+1} = paramInfoStruct.fmtOut;
         
         [val, count, errmsg, nextindex] = sscanf(data(idFEq(1)+1:end), paramInfoStruct.fmtIn);
         if (isempty(errmsg))
            configData.(fieldNames{idF}).data{end+1} = val;
         else
            fprintf('WARNING: read_apmt_config: Unable to read data ''%s'' of section ''%s'' in file (%s)\n', ...
               data, fieldNames{idF}, a_inputFilePathName);
            configData.(fieldNames{idF}).data{end+1} = [];
         end
      else
         fprintf('ERROR: read_apmt_config: ''='' not found in file (%s)\n', ...
            a_inputFilePathName);
      end
   end
end

o_configData = configData;

return;

% ------------------------------------------------------------------------------
% Get the basic structure to read APMT configuration.
%
% SYNTAX :
%  [o_configSectionList, o_configInfoStruct] = init_config_info_struct(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
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
%   10/16/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configSectionList, o_configInfoStruct] = init_config_info_struct(a_decoderId)

% output parameters initialization
o_configSectionList = [];
o_configInfoStruct = [];

switch (a_decoderId)
   case {121, 122, 123}
      [o_configSectionList, o_configInfoStruct] = init_config_info_struct_121_to_123;
   case {124}
      [o_configSectionList, o_configInfoStruct] = init_config_info_struct_124;
   otherwise
      fprintf('ERROR: Don''t know how to initialize decoding structure for decoder Id #%d\n', ...
         a_decoderId);
      return;
end

return;

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

return;

% ------------------------------------------------------------------------------
% Get the basic structure to read APMT configuration.
%
% SYNTAX :
%  [o_configSectionList, o_configInfoStruct] = init_config_info_struct_124
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
%   10/16/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configSectionList, o_configInfoStruct] = init_config_info_struct_124

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
   {'SPECIAL'} ...
   {'PRESSURE_ACTIVATION'} ...
   {'BATTERY'} ...
   {'PRESSURE_I'} ...
   {'SBE41'} ...
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
for idP = 0:7
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

o_configInfoStruct.IRIDIUM_RUDICS = [];
for idP = 0:7
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
   zoneNum = fix((idP-1)/9)+1;
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
         param.fmtIn = '%u';
         param.name = sprintf('zone %d: section depth (dbar)', zoneNum);
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

o_configInfoStruct.SENSOR_01 = o_configInfoStruct.SENSOR_;
for idP = 54:55
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
   end
   o_configInfoStruct.SENSOR_01{end+1} = param;
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

o_configInfoStruct.GUI = [];

return;

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

return;
