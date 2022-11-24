% ------------------------------------------------------------------------------
% Read the predeployment configuration sheet to get the configuration at launch.
%
% SYNTAX :
%  [o_confParamNames, o_confParamValues] = read_conf_cmd_report( ...
%    a_configReportFileName, a_configDefaultFilename, a_sensorList)
%
% INPUT PARAMETERS :
%   a_configReportFileName : predeployment configuration sheet file name
%   a_configDefaultFilename : default configuration file name
%   a_sensorList : list of the sensors mounted on the float
%
% OUTPUT PARAMETERS :
%   o_confParamNames  : configuration parameter names
%   o_confParamValues : configuration parameter values at launch
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_confParamNames, o_confParamValues] = read_conf_cmd_report( ...
   a_configReportFileName, a_configDefaultFilename, a_sensorList)

% output parameters initialization
o_confParamNames = [];
o_confParamValues = [];

% verbose mode flag
VERBOSE_MODE = 0;

% convert sensor names to numbers
sensorList = [];
for id = 1:length(a_sensorList)
   sensorName = a_sensorList{id};
   switch (sensorName)
      case 'CTD'
         sensorList = [sensorList 0];
      case 'OPTODE'
         sensorList = [sensorList 1];
      case 'OCR'
         sensorList = [sensorList 2];
      case 'ECO3'
         sensorList = [sensorList 3];
      case 'FLNTU'
         sensorList = [sensorList 4];
      case 'CROVER'
         sensorList = [sensorList 5];
      case 'SUNA'
         sensorList = [sensorList 6];
      otherwise
         fprintf('ERROR: Unknown sensor name %s\n', sensorName);
   end
end
sensorList = sort(sensorList);

% initialize configuration names and values (with user's manual default values)
values = [{'0'} {''} {''} {'60'} {'3'} {'3'} {'1'} {'1'}];
for id = 0:7
   o_confParamNames{end+1} = sprintf('CONFIG_PI_%d', id);
   o_confParamValues{end+1} = values{id+1};
end
for id = 0:27
   o_confParamNames{end+1} = sprintf('CONFIG_PT_%d', id);
   o_confParamValues{end+1} = '';
end
values = [1 0 1 repmat([1 4 1000 2000 0], 1, 10)];
for id = 0:52
   o_confParamNames{end+1} = sprintf('CONFIG_PM_%d', id);
   o_confParamValues{end+1} = num2str(values(id+1));
end
values = [1 60 10 repmat([24 31 12 99], 1, 5)];
for id = 0:22
   o_confParamNames{end+1} = sprintf('CONFIG_PV_%d', id);
   o_confParamValues{end+1} = num2str(values(id+1));
end
nbSpecific = 0;
values = [0 60 0 0 10 3 1 0 1 0 60 0 0 10 3 1 0 5 0 60 0 0 10 3 1 0 10 0 60 0 0 10 3 1 0 20 0 60 0 0 10 3 1 0 25 10 200 500 1000];
for idS = 1:length(sensorList)
   sensorNum = sensorList(idS);
   for id = 0:48
      o_confParamNames{end+1} = sprintf('CONFIG_PC_%d_0_%d', sensorNum, id);
      o_confParamValues{end+1} = num2str(values(id+1));
   end
   switch sensorNum
      case 0
         values2 = [{'4800'} {'5000'} {'0'} {'1'} {'5'} {'-5'} {'2500'} {'-5'} {'50'} {'0'} {'50'} {'0.083'} {'0.01'}];
         lastId = 12;
      case 1
         values2 = [{'1500'} {'10000'} {'0'} {'1'} {''} {''} {''} {''} {''} {''}];
         lastId = 9;
      case 2
         values2 = [{'1900'} {'4000'} {'0'} {'1'} {''} {''} {''} {''} {''} {''} {''} {''}];
         lastId = 11;
      case 3
         values2 = [{'3600'} {'4000'} {'0'} {'1'} {'0'} {'4130'} {'0'} {'4130'} {'0'} {'4130'}];
         lastId = 9;
      case 4
         values2 = [{'3600'} {'4000'} {'0'} {'0'} {'4130'} {'0'} {'4130'} {'0'} {'1'} {'0'} {'1'} {'0'}];
         lastId = 12;
      case 5
         values2 = [{'1100'} {'2000'} {'0'} {'1'} {'-1'} {'90'}];
         lastId = 5;
      case 6
         values2 = [{'5300'} {'3000'} {'0'} {'1'} {'1'} {''} {''}];
         lastId = 6;
   end
   nbSpecific = nbSpecific + lastId + 1;
   for id = 0:lastId
      o_confParamNames{end+1} = sprintf('CONFIG_PC_%d_1_%d', sensorNum, id);
      o_confParamValues{end+1} = values2{id+1};
   end
end

% read the default configuration file
fId = fopen(a_configDefaultFilename, 'r');
if (fId == -1)
   fprintf('ERROR: Error while opening file: %s\n', a_configDefaultFilename);
   return;
end

% parse input data and store configuration information
lineNum = 0;
while (1)
   line = fgetl(fId);
   lineNum = lineNum + 1;
   if (line == -1)
      break;
   end
   line = strtrim(line);
   
   % empty line
   if (isempty(line))
      continue;
   end
   
   % configuration parameters
   if (~isempty(strfind(line, '!PV ')) || ...
         ~isempty(strfind(line, '!PM ')) || ...
         ~isempty(strfind(line, '!PC ')))
      
      remain = line;
      id = 1;
      name = 'CONFIG';
      if (~isempty(strfind(line, '!PC ')))
         pcCmd = 1;
      else
         pcCmd = 0;
      end
      while (1)
         [info, remain] = strtok(remain, ' ');
         if (isempty(info))
            break;
         end
         if (id == 1)
            name = [name '_' info(2:end)];
         elseif (id == 2)
            if (pcCmd == 1)
               if (~ismember(str2num(info), sensorList))
                  break;
               end
            end
            name = [name '_' info];
         elseif (id == 3)
            if (pcCmd == 0)
               o_confParamNames{end+1} = name;
               o_confParamValues{end+1} = info;
            else
               name = [name '_' info];
            end
         elseif (id == 5)
            o_confParamNames{end+1} = name;
            o_confParamValues{end+1} = info;
         else
            name = [name '_' info];
         end
         id = id + 1;
      end
   end
end

fclose(fId);

% read the configuration file
if ~(exist(a_configReportFileName, 'file') == 2)
   fprintf('WARNING: Input file not found: %s => using the default configuration\n', a_configReportFileName);
else
   
   fId = fopen(a_configReportFileName, 'r');
   if (fId == -1)
      fprintf('ERROR: Error while opening file: %s\n', a_configReportFileName);
      return;
   end
   
   % parse input data and store configuration information
   lineNum = 0;
   while (1)
      line = fgetl(fId);
      lineNum = lineNum + 1;
      if (line == -1)
         break;
      end
      line = strtrim(line);
      
      % empty line
      if (isempty(line))
         continue;
      end
      
      if (~isempty(strfind(line, '<VL V')))
         fprintf('\n#@# %s\n', line);
      end
      
      % configuration parameters
      if (~isempty(strfind(line, '<PM ')) || ...
            ~isempty(strfind(line, '<PV ')) || ...
            ~isempty(strfind(line, '<PT ')) || ...
            ~isempty(strfind(line, '<PI ')))
         
         start = strfind(line, '<');
         stop = strfind(line, '>');
         if (~isempty(start) && ~isempty(stop))
            
            remain = line(start+1:stop-1);
            id = 1;
            name = 'CONFIG';
            while (1)
               [info, remain] = strtok(remain, ' ');
               if (isempty(info))
                  break;
               end
               if (id == 3)
                  o_confParamNames{end+1} = name;
                  o_confParamValues{end+1} = info;
               else
                  name = [name '_' info];
               end
               id = id + 1;
            end
         end
      end
   end
   
   frewind(fId)
   
   lineNum = 0;
   while (1)
      line = fgetl(fId);
      lineNum = lineNum + 1;
      if (line == -1)
         break;
      end
      line = strtrim(line);
      
      % empty line
      if (isempty(line))
         continue;
      end
      
      % configuration parameters
      if (~isempty(strfind(line, 'PARAM SENSOR Measure: Sensor No')))
         
         start = strfind(line, 'PARAM SENSOR Measure: Sensor No');
         line2 = line(start:end);
         
         [val, count, errmsg, nextindex] = sscanf(line2, 'PARAM SENSOR Measure: Sensor No%d Standard parameter No%d Value: %f');
         if (~isempty(errmsg) || (count ~= 3))
            [val, count, errmsg, nextindex] = sscanf(line2, 'PARAM SENSOR Measure: Sensor No%d Specific parameter No%d Value: %f');
            if (~isempty(errmsg) || (count ~= 3))
               fprintf('PARSING_ERROR: Cannot parse line #%d: %s\n', lineNum, line);
            else
               if (~ismember(val(1), sensorList))
                  continue;
               end
               o_confParamNames{end+1} = sprintf('CONFIG_PC_%d_1_%d', val(1), val(2));
               o_confParamValues{end+1} = num2str(val(3));
            end
         else
            if (~ismember(val(1), sensorList))
               continue;
            end
            o_confParamNames{end+1} = sprintf('CONFIG_PC_%d_0_%d', val(1), val(2));
            o_confParamValues{end+1} = num2str(val(3));
         end
         
      end
   end
   
   fclose(fId);
   
end

% delete duplicated values (keep only the last one)
[C, ia, ic] = unique(o_confParamNames);
idToKeep = ones(1, length(ic))*-1;
for id = length(ic):-1:1
   if (idToKeep(id) == -1)
      value = ic(id);
      for id2 = id-1:-1:1
         if (ic(id2) == value)
            idToKeep(id2) = 0;
         end
      end
      idToKeep(id) = 1;
   end
end

% delete the values
if (~isempty(find(idToKeep == 0, 1)))
   idToDel = find(idToKeep == 0);
   
   if (VERBOSE_MODE == 1)
      fprintf('Deleting duplicated configuration values:\n');
      icToDel = ic(idToDel);
      uIcTodel = unique(icToDel);
      for id = 1:length(uIcTodel)
         idDel = uIcTodel(id);
         idDelVal = find(ic == idDel);
         for id2 = 1:length(idDelVal)
            fprintf('%s:%s', ...
               char(o_confParamNames{idDelVal(id2)}), ...
               char(o_confParamValues{idDelVal(id2)}));
            if (id2 < length(idDelVal))
               fprintf(' => DELETED\n');
            else
               fprintf(' => PRESERVED\n');
            end
         end
         fprintf('\n');
      end
   end
   
   o_confParamNames(idToDel) = [];
   o_confParamValues(idToDel) = [];
end

% create expected configuration names
configNames = [];
for id = 0:7
   configNames{end+1} = sprintf('CONFIG_PI_%d', id);
end
for id = 0:27
   configNames{end+1} = sprintf('CONFIG_PT_%d', id);
end
for id = 0:52
   configNames{end+1} = sprintf('CONFIG_PM_%d', id);
end
for id = 0:22
   configNames{end+1} = sprintf('CONFIG_PV_%d', id);
end
for idS = 0:6
   for id = 0:48
      configNames{end+1} = sprintf('CONFIG_PC_%d_0_%d', idS, id);
   end
   switch idS
      case 0
         lastId = 12;
      case 1
         lastId = 9;
      case 2
         lastId = 11;
      case 3
         lastId = 9;
      case 4
         lastId = 12;
      case 5
         lastId = 5;
      case 6
         lastId = 6;
   end
   for id = 0:lastId
      configNames{end+1} = sprintf('CONFIG_PC_%d_1_%d', idS, id);
   end
end

% delete unexpected values
idToDel = [];
for id = 1:length(o_confParamNames)
   idF = strfind(configNames', o_confParamNames{id});
   if (isempty(cell2mat(idF)))
      idToDel = [idToDel; id];
   end
end
o_confParamNames(idToDel) = [];
o_confParamValues(idToDel) = [];

if (length(o_confParamNames) ~= 112+(49*length(sensorList))+(nbSpecific))
   fprintf('WARNING: Number of config parameters (%d) different from expected (%d)\n', ...
      length(o_confParamNames), 112+(49*length(sensorList))+(nbSpecific));
else
   fprintf('INFO: %d config parameters\n', length(o_confParamNames));
end

% sort the configuration names
[o_confParamNames, idSort] = sort(o_confParamNames);
o_confParamValues = o_confParamValues(idSort);

return;
