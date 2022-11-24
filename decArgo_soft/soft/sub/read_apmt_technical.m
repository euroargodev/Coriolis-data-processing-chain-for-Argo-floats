% ------------------------------------------------------------------------------
% Parse APMT technical files.
%
% SYNTAX :
%  [o_techData, o_timeData, ...
%    o_ncTechData, o_ncTrajData, o_ncMetaData] = read_apmt_technical(...
%    a_inputFilePathName, a_decoderId)
%
% INPUT PARAMETERS :
%   a_inputFilePathName : APMT technical file path name
%   a_decoderId         : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_techData   : APMT technical data
%   o_timeData   : APMT time data
%   o_ncTechData : APMT technical data for nc file
%   o_ncTrajData : APMT trajectory data for nc file
%   o_ncMetaData : APMT meta data for nc file
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_techData, o_timeData, ...
   o_ncTechData, o_ncTrajData, o_ncMetaData] = read_apmt_technical(...
   a_inputFilePathName, a_decoderId)

% output parameters initialization
o_techData = [];
o_timeData = [];
o_ncTechData = [];
o_ncTrajData = [];
o_ncMetaData = [];

% default values
global g_decArgo_janFirst1950InMatlab; % used in an inline function


if ~(exist(a_inputFilePathName, 'file') == 2)
   fprintf('ERROR: read_apmt_technical: File not found: %s\n', a_inputFilePathName);
   return
end

% create the technical info structure
[techSectionList, techInfoStruct] = init_tech_info_struct(a_decoderId);

% open the file and read the data
fId = fopen(a_inputFilePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_inputFilePathName);
   return
end
data = [];
while (1)
   line = fgetl(fId);
   if (line == -1)
      break
   end
   data{end+1} = line;
end
fclose(fId);

% delete the part of the file padded with 0x1A
uLastLine = unique(data{end});
if ((length(uLastLine) == 1) && (uLastLine == hex2dec('1a')))
   data(end) = [];
end

% parse the data according to expected sections
techData = [];
currentStruct = [];
currentSectionNum = -1;
newSectionNum = -1;
for idL = 1:length(data)
   line = data{idL};

   % look for a new section header
   if (line(1) == '[')
      for idSection = 1:length(techSectionList)
         sectionName = techSectionList{idSection};
         if (strcmp(line, ['[' sectionName ']']))
            newSectionNum = idSection;
            break
         end
      end
      if (newSectionNum == -1)
         fprintf('ERROR: read_apmt_technical: Unexpected section (%s) found in file (%s)\n', ...
            line(2:end-1), a_inputFilePathName);
      end
   end
   
   % consider the new section
   if (newSectionNum ~= -1)
      if (currentSectionNum ~= -1)
         fieldName = techSectionList{currentSectionNum};
         techData.(fieldName).raw = currentStruct;
         techData.(fieldName).name = [];
         techData.(fieldName).fmt = [];
         techData.(fieldName).data = [];
         techData.(fieldName).dataAdj = [];
         techData.(fieldName).dataStr = [];
         techData.(fieldName).dataAdjStr = [];
      end
      currentStruct = [];
      currentSectionNum = newSectionNum;
      newSectionNum = -1;
      continue
   end

   currentStruct{end+1} = line;
end

if (currentSectionNum ~= -1)
   fieldName = techSectionList{currentSectionNum};
   techData.(fieldName).raw = currentStruct;
   techData.(fieldName).name = [];
   techData.(fieldName).fmt = [];
   techData.(fieldName).data = [];
   techData.(fieldName).dataAdj = [];
   techData.(fieldName).dataStr = [];
   techData.(fieldName).dataAdjStr = [];
end

% retrieve technical information
fieldNames = fieldnames(techData);
for idF = 1:length(fieldNames)
   rawData = techData.(fieldNames{idF}).raw;
   for idI = 1:length(rawData)
      done = 0;
      data = rawData{idI};
      for idP = 1:length(techInfoStruct.(fieldNames{idF}))
         if (isempty(techInfoStruct.(fieldNames{idF}){idP}.patternStart))
            pattern = techInfoStruct.(fieldNames{idF}){idP}.pattern;
            
            expCount = techInfoStruct.(fieldNames{idF}){idP}.count;
            [val, count, errmsg, nextindex] = sscanf(data, pattern);
            if (isempty(errmsg) && (count == expCount))
               
               % for "Ice (%s)" alarm
               if (~isempty(val) && (val(end) == ')') && (strcmp(pattern(end-2:end), '%s)')))
                  val(end) = [];
               end
               
               for idD = 1:length(techInfoStruct.(fieldNames{idF}){idP}.id)
                  id = techInfoStruct.(fieldNames{idF}){idP}.id{idD};
                  if (~isempty(techInfoStruct.(fieldNames{idF}){idP}.func) && ...
                        ~isempty(techInfoStruct.(fieldNames{idF}){idP}.func{idD}))
                     f = eval(techInfoStruct.(fieldNames{idF}){idP}.func{idD});
                     techData.(fieldNames{idF}).data{end+1} = f(val(id));
                  else
                     if (count == 0)
                        techData.(fieldNames{idF}).data{end+1} = [];
                     elseif (count == 1)
                        techData.(fieldNames{idF}).data{end+1} = val;
                     elseif (count > 1)
                        techData.(fieldNames{idF}).data{end+1} = val(id);
                     end
                  end
                  if (~isempty(techData.(fieldNames{idF}).data{end}) && ...
                        ~isempty(techInfoStruct.(fieldNames{idF}){idP}.func1) && ...
                        ~isempty(techInfoStruct.(fieldNames{idF}){idP}.func1{idD}))
                     f = eval(techInfoStruct.(fieldNames{idF}){idP}.func1{idD});
                     techData.(fieldNames{idF}).dataAdj{end+1} = ...
                        f(techData.(fieldNames{idF}).data{end});
                  else
                     techData.(fieldNames{idF}).dataAdj{end+1} = [];
                  end
                  if (~isempty(techInfoStruct.(fieldNames{idF}){idP}.func2) && ...
                        ~isempty(techInfoStruct.(fieldNames{idF}){idP}.func2{idD}))
                     f = eval(techInfoStruct.(fieldNames{idF}){idP}.func2{idD});
                     if (~isempty(techData.(fieldNames{idF}).data{end}))
                        techData.(fieldNames{idF}).dataStr{end+1} = f(techData.(fieldNames{idF}).data{end});
                     else
                        techData.(fieldNames{idF}).dataStr{end+1} = [];
                     end
                     if (~isempty(techData.(fieldNames{idF}).dataAdj{end}))
                        techData.(fieldNames{idF}).dataAdjStr{end+1} = f(techData.(fieldNames{idF}).dataAdj{end});
                     else
                        techData.(fieldNames{idF}).dataAdjStr{end+1} = [];
                     end
                  else
                     techData.(fieldNames{idF}).dataStr{end+1} = [];
                     techData.(fieldNames{idF}).dataAdjStr{end+1} = [];
                  end
                  techData.(fieldNames{idF}).name{end+1} = techInfoStruct.(fieldNames{idF}){idP}.name{idD};
                  if (~isempty(techInfoStruct.(fieldNames{idF}){idP}.fmt))
                     techData.(fieldNames{idF}).fmt{end+1} = techInfoStruct.(fieldNames{idF}){idP}.fmt{idD};
                  else
                     techData.(fieldNames{idF}).fmt{end+1} = [];
                  end
                  
                  % collect TECH data
                  if (~isempty(techInfoStruct.(fieldNames{idF}){idP}.tech))
                     if (~isempty(techInfoStruct.(fieldNames{idF}){idP}.tech{idD}))
                        dataForTech = techInfoStruct.(fieldNames{idF}){idP}.tech{idD};
                        if (~ismember(dataForTech.techId, [152]))
                           if (~isempty(dataForTech.func))
                              dataForTech.valueRaw = techData.(fieldNames{idF}).data{end};
                              if (~isempty(dataForTech.func1))
                                 f = eval(dataForTech.func1);
                                 dataForTech.valueRaw = f(dataForTech.valueRaw);
                              end
                              f = eval(dataForTech.func);
                              dataForTech.valueOutput = f(dataForTech.valueRaw);
                           else
                              if (isempty(techData.(fieldNames{idF}).data{end}))
                                 dataForTech.valueRaw = 1;
                                 dataForTech.valueOutput = num2str(dataForTech.valueRaw);
                              else
                                 dataForTech.valueRaw = techData.(fieldNames{idF}).data{end};
                                 dataForTech.valueOutput = num2str(dataForTech.valueRaw);
                              end
                           end
                           o_ncTechData{end+1} = dataForTech;
                        elseif (dataForTech.techId == 152)
                           % manage failed autotest report
                           selfTestAlarmValue = techData.(fieldNames{idF}).data{end};
                           % boolean value
                           dataForTech.valueRaw = 1;
                           dataForTech.valueOutput = num2str(dataForTech.valueRaw);
                           o_ncTechData{end+1} = dataForTech;
                           % detailed description of subsystems that failed
                           dataForTech.label = 'Selft test alarm detailed description';
                           dataForTech.techId = 153;
                           dataForTech.valueRaw = create_self_test_alarm_value(selfTestAlarmValue);
                           dataForTech.valueOutput = num2str(dataForTech.valueRaw);
                           o_ncTechData{end+1} = dataForTech;
                        end
                     end
                  end
                  
                  % collect META data
                  if (~isempty(techInfoStruct.(fieldNames{idF}){idP}.meta))
                     if (~isempty(techInfoStruct.(fieldNames{idF}){idP}.meta{idD}))
                        dataForMeta = techInfoStruct.(fieldNames{idF}){idP}.meta{idD};
                        dataForMeta.value = techData.(fieldNames{idF}).data{end};
                        o_ncMetaData{end+1} = dataForMeta;
                     end
                  end
                  
                  % collect TIME data
                  if (~isempty(techInfoStruct.(fieldNames{idF}){idP}.time))
                     if (~isempty(techInfoStruct.(fieldNames{idF}){idP}.time{idD}))
                        dataForTime = techInfoStruct.(fieldNames{idF}){idP}.time{idD};
                        if (strcmp(dataForTime.paramName, 'JULD'))
                           dataForTime.time = techData.(fieldNames{idF}).data{end};
                           if (~isempty(techData.(fieldNames{idF}).dataAdj{end}))
                              dataForTime.timeAdj = adjust_time_cts5(dataForTime.time);
                           end
                        else
                           dataForTime.pres = techData.(fieldNames{idF}).data{end};
                        end
                        o_timeData{end+1} = dataForTime;
                     end
                  end
                  
                  % collect TRAJ data
                  if (~isempty(techInfoStruct.(fieldNames{idF}){idP}.traj))
                     if (~isempty(techInfoStruct.(fieldNames{idF}){idP}.traj{idD}))
                        dataForTraj = techInfoStruct.(fieldNames{idF}){idP}.traj{idD};
                        dataForTraj.value = techData.(fieldNames{idF}).data{end};
                        if (strcmp(dataForTraj.paramName, 'JULD'))
                           if (~isempty(techData.(fieldNames{idF}).dataAdj{end}))
                              dataForTraj.valueAdj = adjust_time_cts5(dataForTraj.value);
                           end
                        end
                        o_ncTrajData{end+1} = dataForTraj;
                     end
                  end
               end
               
               done = 1;
               break
            end
         end
      end
      if (done == 0)
         for idP = 1:length(techInfoStruct.(fieldNames{idF}))
            if (~isempty(techInfoStruct.(fieldNames{idF}){idP}.patternStart))
               patternStart = techInfoStruct.(fieldNames{idF}){idP}.patternStart;               
               if (strncmp(data, patternStart, length(patternStart)))
                  patternEnd = techInfoStruct.(fieldNames{idF}){idP}.patternEnd;
                  idStart = length(patternStart) + 1;
                  idEnd = strfind(data, patternEnd);
                  id = find(idEnd > idStart);
                  idEnd = idEnd(id) - 1;
                  
                  techData.(fieldNames{idF}).data{end+1} = data(idStart:idEnd);
                  techData.(fieldNames{idF}).dataAdj{end+1} = [];
                  techData.(fieldNames{idF}).dataStr{end+1} = [];
                  techData.(fieldNames{idF}).dataAdjStr{end+1} = [];
                  techData.(fieldNames{idF}).name{end+1} = techInfoStruct.(fieldNames{idF}){idP}.name{1};
                  if (~isempty(techInfoStruct.(fieldNames{idF}){idP}.fmt))
                     techData.(fieldNames{idF}).fmt{end+1} = techInfoStruct.(fieldNames{idF}){idP}.fmt{1};
                  else
                     techData.(fieldNames{idF}).fmt{end+1} = [];
                  end
                              
                  if (~isempty(techInfoStruct.(fieldNames{idF}){idP}.pattern))
                     pattern = techInfoStruct.(fieldNames{idF}){idP}.pattern;
                     expCount = techInfoStruct.(fieldNames{idF}){idP}.count;
                     [val, count, errmsg, nextindex] = sscanf(data(idEnd+1+length(patternEnd):end), pattern);
                     if (isempty(errmsg) && (count == expCount))
                        
                        for idD = 2:length(techInfoStruct.(fieldNames{idF}){idP}.id)
                           id = techInfoStruct.(fieldNames{idF}){idP}.id{idD};
                           if (~isempty(techInfoStruct.(fieldNames{idF}){idP}.func) && ...
                                 ~isempty(techInfoStruct.(fieldNames{idF}){idP}.func{idD}))
                              f = eval(techInfoStruct.(fieldNames{idF}){idP}.func{idD});
                              techData.(fieldNames{idF}).data{end+1} = f(val(id));
                           else
                              if (count == 0)
                                 techData.(fieldNames{idF}).data{end+1} = [];
                              elseif (count == 1)
                                 techData.(fieldNames{idF}).data{end+1} = val;
                              elseif (count > 1)
                                 techData.(fieldNames{idF}).data{end+1} = val(id);
                              end
                           end
                           if (~isempty(techData.(fieldNames{idF}).data{end}) && ...
                                 ~isempty(techInfoStruct.(fieldNames{idF}){idP}.func1) && ...
                                 ~isempty(techInfoStruct.(fieldNames{idF}){idP}.func1{idD}))
                              f = eval(techInfoStruct.(fieldNames{idF}){idP}.func1{idD});
                              techData.(fieldNames{idF}).dataAdj{end+1} = ...
                                 f(techData.(fieldNames{idF}).data{end});
                           else
                              techData.(fieldNames{idF}).dataAdj{end+1} = [];
                           end
                           if (~isempty(techInfoStruct.(fieldNames{idF}){idP}.func2) && ...
                                 ~isempty(techInfoStruct.(fieldNames{idF}){idP}.func2{idD}))
                              f = eval(techInfoStruct.(fieldNames{idF}){idP}.func2{idD});
                              if (~isempty(techData.(fieldNames{idF}).data{end}))
                                 techData.(fieldNames{idF}).dataStr{end+1} = f(techData.(fieldNames{idF}).data{end});
                              else
                                 techData.(fieldNames{idF}).dataStr{end+1} = [];
                              end
                              if (~isempty(techData.(fieldNames{idF}).dataAdj{end}))
                                 techData.(fieldNames{idF}).dataAdjStr{end+1} = f(techData.(fieldNames{idF}).dataAdj{end});
                              else
                                 techData.(fieldNames{idF}).dataAdjStr{end+1} = [];
                              end
                           else
                              techData.(fieldNames{idF}).dataStr{end+1} = [];
                              techData.(fieldNames{idF}).dataAdjStr{end+1} = [];
                           end
                           techData.(fieldNames{idF}).name{end+1} = techInfoStruct.(fieldNames{idF}){idP}.name{idD};
                           if (~isempty(techInfoStruct.(fieldNames{idF}){idP}.fmt))
                              techData.(fieldNames{idF}).fmt{end+1} = techInfoStruct.(fieldNames{idF}){idP}.fmt{idD};
                           else
                              techData.(fieldNames{idF}).fmt{end+1} = [];
                           end
                        end
                     end
                  end
                  
                  % collect TECH data
                  if (~isempty(techInfoStruct.(fieldNames{idF}){idP}.tech))
                     if (~isempty(techInfoStruct.(fieldNames{idF}){idP}.tech{idD}))
                        dataForTech = techInfoStruct.(fieldNames{idF}){idP}.tech{idD};
                        if (ismember(dataForTech.techId, [171 173]))
                           if (dataForTech.techId == 171)
                              % manage EOL
                              eolReasonValue = techData.(fieldNames{idF}).data{end};
                              % boolean value
                              dataForTech.valueRaw = 1;
                              dataForTech.valueOutput = num2str(dataForTech.valueRaw);
                              o_ncTechData{end+1} = dataForTech;
                              % cause of EOL
                              dataForTech.label = 'Cause of EOL mode';
                              dataForTech.techId = 202;
                              dataForTech.valueRaw = eolReasonValue;
                              dataForTech.valueOutput = eolReasonValue;
                              o_ncTechData{end+1} = dataForTech;
                           elseif (dataForTech.techId == 173)
                              % manage feedback
                              feedbackTypeValue = techData.(fieldNames{idF}).data{end};
                              % boolean value
                              dataForTech.valueRaw = 1;
                              dataForTech.valueOutput = num2str(dataForTech.valueRaw);
                              o_ncTechData{end+1} = dataForTech;
                              % feedback type
                              dataForTech.label = 'Feedback type';
                              dataForTech.techId = 203;
                              dataForTech.valueRaw = feedbackTypeValue;
                              dataForTech.valueOutput = feedbackTypeValue;
                              o_ncTechData{end+1} = dataForTech;
                           end
                        end
                     end
                  end
                  
                  done = 1;
                  break
               end
            end
         end
      end
      if (done == 0)
         fprintf('ERROR: read_apmt_technical: Unexpected information (%s) found in section ''%s'' of file (%s)\n', ...
            data, fieldNames{idF}, a_inputFilePathName);
      end
   end
end

o_techData = techData;

return

% ------------------------------------------------------------------------------
% Get the basic structure to read APMT technical data.
%
% SYNTAX :
%  [o_techSectionList, o_techInfoStruct] = init_tech_info_struct(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_techSectionList : list of sections
%   o_techInfoStruct  : information on each section
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/14/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_techSectionList, o_techInfoStruct] = init_tech_info_struct(a_decoderId)

% output parameters initialization
o_techSectionList = [];
o_techInfoStruct = [];

switch (a_decoderId)
   
   case {121}
      [o_techSectionList, o_techInfoStruct] = init_tech_info_struct_121;

   case {122, 123}
      [o_techSectionList, o_techInfoStruct] = init_tech_info_struct_122_123;

   case {124}
      [o_techSectionList, o_techInfoStruct] = init_tech_info_struct_124;

   otherwise
      fprintf('ERROR: init_tech_info_struct: Don''t know how to parse APMT technical data for techId #%d\n', ...
         a_decoderId);
      
end

return

% ------------------------------------------------------------------------------
% In line function to compute GPS latitude.
%
% SYNTAX :
%  [o_lat] = compute_latitude(a_lat, a_latStr)
%
% INPUT PARAMETERS :
%   a_lat    : latitude value
%   a_latStr : latitude sign ('N' or 'S')
%
% OUTPUT PARAMETERS :
%   o_lat : computed latitude value
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_lat] = compute_latitude(a_lat, a_latStr)

decode_GPS = @(x) sign(x).*(fix(abs(x)/100)+ mod(abs(x),100)./60);

sig = 1;
if (char(a_latStr) == 'S')
   sig = -1;
end
o_lat = decode_GPS(a_lat)*sig;

return

% ------------------------------------------------------------------------------
% In line function to compute GPS longitude.
%
% SYNTAX :
%  [o_lon] = compute_longitude(a_lon, a_lonStr)
%
% INPUT PARAMETERS :
%   a_lon    : longitude value
%   a_lonStr : longitude sign ('E' or 'W')
%
% OUTPUT PARAMETERS :
%   o_lon : computed longitude value
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_lon] = compute_longitude(a_lon, a_lonStr)

decode_GPS = @(x) sign(x).*(fix(abs(x)/100)+ mod(abs(x),100)./60);

sig = 1;
if (char(a_lonStr) == 'W')
   sig = -1;
end
o_lon = decode_GPS(a_lon)*sig;

return

% ------------------------------------------------------------------------------
% Create self test alarm value from alarm item list.
%
% SYNTAX :
%  [o_selfTestAlarmValue] = create_self_test_alarm_value(a_selfTestAlarm)
%
% INPUT PARAMETERS :
%   a_selfTestAlarm : alarm list
%
% OUTPUT PARAMETERS :
%   o_selfTestAlarmValue : alarm value
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_selfTestAlarmValue] = create_self_test_alarm_value(a_selfTestAlarm)

% output parameters initialization
o_selfTestAlarmValue = 0;


subSystemList = [ ...
   {'FRAM'} ...
   {'FLASH'} ...
   {'RTC'} ...
   {'Vbatt'} ...
   {'Pi'} ...
   {'Pe'} ...
   {'SBE41-Cutoff'} ...
   {'SBE41-Offset'} ...
   {'GPS'} ...
   {'Payload'} ...
   {'Sensor'} ...
   {'Transmitter'} ...
   ];

for idS = 1:length(subSystemList)
   if (any(strfind(a_selfTestAlarm, subSystemList{idS})))
      o_selfTestAlarmValue = o_selfTestAlarmValue + 2^(length(subSystemList)-idS);
   end
end

return
