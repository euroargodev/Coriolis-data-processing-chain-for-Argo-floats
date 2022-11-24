% ------------------------------------------------------------------------------
% Parse payload configuration files.
%
% SYNTAX :
%  [o_configData] = read_payload_config(a_inputFilePathName)
%
% INPUT PARAMETERS :
%   a_inputFilePathName : payload configuration file path name
%
% OUTPUT PARAMETERS :
%   o_configData : payload configuration data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configData] = read_payload_config(a_inputFilePathName)

% output parameters initialization
o_configData = [];


if ~(exist(a_inputFilePathName, 'file') == 2)
   fprintf('ERROR: read_payload_config: File not found: %s\n', a_inputFilePathName);
   return
end

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
uLastLine = unique(data{end});
if ((length(uLastLine) == 1) && (uLastLine == hex2dec('1a')))
   data(end) = [];
end

% parse the config data
o_configData = parse_payload_config(data);

return

% ------------------------------------------------------------------------------
% Parse payload configuration data.
%
% SYNTAX :
%  [o_configData] = parse_payload_config(a_data)
%
% INPUT PARAMETERS :
%   a_data : payload configuration data
%
% OUTPUT PARAMETERS :
%   o_configData : payload configuration data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configData] = parse_payload_config(a_data)

% output parameters initialization
o_configData = [];

ptn1 = '<';
ptn2 = '</';
ptn3 = '>';
ptn4 = '/>';

data = [a_data{:}];
level = 1;
while(~isempty(data))
   if (data(1) == ptn1)
      if (strcmp(data(1:length(ptn2)), ptn2))
         % '</'
         idF3 = strfind(data, ptn3);
         if (~isempty(idF3))
            % '>'
            idF3 = idF3(1);
            text = data(length(ptn2)+1:idF3-1);
            level = level - 1;
            tag = strtrim(text);
            %             fprintf('Level %d: TAG: %s\n', level, [tag '_END']);
            newCell = cell(1, 4);
            newCell{1} = level;
            newCell{2} = tag;
            newCell{3} = 'E';
            newCell{4} = '';
            o_configData = cat(1, o_configData, newCell);
            data(1:idF3+length(ptn3)-1) = [];
         else
            fprintf('Error: %s\n', data(1:20));
         end
      elseif (strcmp(data(1:length(ptn1)), ptn1))
         % '<'
         idF3 = strfind(data, ptn3);
         idF4 = strfind(data, ptn4);
         if ((~isempty(idF3) && ~isempty(idF4) && (idF3(1) < idF4(1))) || ...
               (~isempty(idF3) && isempty(idF4)))
            % '>'
            idF3 = idF3(1);
            text = data(length(ptn1)+1:idF3-1);
            text = strtrim(text);
            idF5 = strfind(text, ' ');
            if (isempty(idF5))
               tag = text;
               att = '';
            else
               tag = text(1:idF5(1)-1);
               att = text(idF5(1)+1:end);
            end
            %             fprintf('Level %d: TAG: %s: #%s#\n', level, [tag '_BEGIN'], att);
            newCell = cell(1, 4);
            newCell{1} = level;
            newCell{2} = tag;
            newCell{3} = 'B';
            newCell{4} = att;
            o_configData = cat(1, o_configData, newCell);
            level = level + 1;
            data(1:idF3+length(ptn3)-1) = [];
         else
            % '/>'
            idF4 = idF4(1);
            text = data(length(ptn1)+1:idF4-1);
            text = strtrim(text);
            idF5 = strfind(text, ' ');
            if (isempty(idF5))
               tag = text;
               att = '';
            else
               tag = text(1:idF5(1)-1);
               att = text(idF5(1)+1:end);
            end
            %             fprintf('Level %d: TAG: %s: #%s#\n', level, [tag '_BEGIN'], att);
            %             fprintf('Level %d: TAG: %s\n', level, [tag '_END']);
            newCell = cell(1, 4);
            newCell{1} = level;
            newCell{2} = tag;
            newCell{3} = 'B';
            newCell{4} = att;
            o_configData = cat(1, o_configData, newCell);
            newCell = cell(1, 4);
            newCell{1} = level;
            newCell{2} = tag;
            newCell{3} = 'E';
            newCell{4} = '';
            o_configData = cat(1, o_configData, newCell);
            data(1:idF4+length(ptn4)-1) = [];
         end
      else
         fprintf('Error: %s\n', data(1:20));
      end
   else
      data(1) = [];
   end
end

% parse attributes to get att_name and att_value
for idL = 1:size(o_configData, 1)
   if (~isempty(o_configData{idL, 4}))
      info = o_configData{idL, 4};
      info = strtrim(info);
      idF1 = strfind(info, '=');
      idF2 = strfind(info, '"');
      if (length(idF2) == 2*length(idF1))
         data = [];
         first = 1;
         for id = 1:length(idF1)
            name = info(first:idF1(id)-1);
            name = strtrim(name);
            value = info(idF2(2*id-1)+1:idF2(2*id)-1);
            value = strtrim(value);
            [valueNum, status] = str2num(value);
            if (status && (length(valueNum) == 1))
               value = valueNum;
            end
            data{end+1} = name;
            data{end+1} = value;
            first = idF2(2*id)+1;
         end
         o_configData{idL, 4} = data;
      else
         fprintf('Error: %s\n', info);
      end
   end
end

return
