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
   return
end

% create the configuration info structure
[configSectionList, configInfoStruct] = init_config_info_struct(a_decoderId);

% open the file and read the data
fId = fopen(a_inputFilePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_inputFilePathName);
   return
end
data = [];
while (1)
   line = fgetl(fId);
   if (isempty(line))
      continue
   end
   if (line == -1)
      break
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
            break
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
                  break
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
      continue
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
      continue
   end
   if (strcmp(fieldNames{idF}, 'SENSOR_13'))
      continue
   end
   if (strcmp(fieldNames{idF}, 'SENSOR_16'))
      continue
   end
   if (strcmp(fieldNames{idF}, 'EXTTRIG'))
      continue
   end
   rawData = configData.(fieldNames{idF}).raw;
   for idI = 1:length(rawData)
      data = rawData{idI};

      % present in float 6902968 (first CTS5 UVP), should not be considered
      % should be considered from CTS5-USEA version (decId 126)
      if (a_decoderId == 124)
         if (strcmp(data, 'P60=0'))
            continue
         end
      end
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

         %          if ~(strcmp(fieldNames{idF}, 'TECHNICAL') && ((paramNum == 23) || (paramNum == 24)))
         [val, count, errmsg, nextindex] = sscanf(data(idFEq(1)+1:end), paramInfoStruct.fmtIn);
         if (isempty(errmsg))
            configData.(fieldNames{idF}).data{end+1} = val;
         else
            fprintf('WARNING: read_apmt_config: Unable to read data ''%s'' of section ''%s'' in file (%s)\n', ...
               data, fieldNames{idF}, a_inputFilePathName);
            configData.(fieldNames{idF}).data{end+1} = [];
         end
         %          else
         %             % multi dimentionnal parameter
         %             dataCell = split(data(idFEq(1)+1:end), ';');
         %             dataTab = cellfun(@str2num, dataCell);
         %             configData.(fieldNames{idF}).data{end+1} = dataTab';
         %          end
      else
         if (~any(strfind(data, '->')))
            fprintf('ERROR: read_apmt_config: ''='' not found in file (%s)\n', ...
               a_inputFilePathName);
         end
      end
   end
end

% duplicate SENSOR_14_PXX (RAMSES) into SENSOR_21_PXX (RAMSES2) except for XX = 54, 55, 56
if (isfield(configData, 'SENSOR_14') && isfield(configData, 'SENSOR_21'))
   for id = 1:length(configData.SENSOR_14.num)
      if (~ismember(configData.SENSOR_14.num{id}, [configData.SENSOR_21.num{:}]))
         configData.SENSOR_21.raw{end+1} = configData.SENSOR_14.raw{id};
         configData.SENSOR_21.num{end+1} = configData.SENSOR_14.num{id};
         configData.SENSOR_21.name{end+1} = configData.SENSOR_14.name{id};
         configData.SENSOR_21.fmt{end+1} = configData.SENSOR_14.fmt{id};
         configData.SENSOR_21.data{end+1} = configData.SENSOR_14.data{id};
      end
   end
end

o_configData = configData;

return

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
   case {124, 125}
      [o_configSectionList, o_configInfoStruct] = init_config_info_struct_124_125;
   case {126}
      [o_configSectionList, o_configInfoStruct] = init_config_info_struct_126;
   case {127}
      [o_configSectionList, o_configInfoStruct] = init_config_info_struct_127;
   case {128}
      [o_configSectionList, o_configInfoStruct] = init_config_info_struct_128;
   case {129, 130, 131}
      [o_configSectionList, o_configInfoStruct] = init_config_info_struct_129_130_131;
   otherwise
      fprintf('ERROR: Don''t know how to initialize decoding structure for decoder Id #%d\n', ...
         a_decoderId);
      return
end

return
