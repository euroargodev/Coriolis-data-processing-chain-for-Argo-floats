% ------------------------------------------------------------------------------
% Decode payload data transmitted by a CTS5 float.
%
% SYNTAX :
%  [o_payloadData, o_emptyPayloadData] = decode_payload_data(a_inputFilePathName)
%
% INPUT PARAMETERS :
%   a_inputFilePathName : payload data file to decode
%
% OUTPUT PARAMETERS :
%   o_payloadData      : payload decoded data
%   o_emptyPayloadData : payload data empty flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_payloadData, o_emptyPayloadData] = decode_payload_data(a_inputFilePathName)

% output parameters initialization
o_payloadData = [];
o_emptyPayloadData = 1;


if ~(exist(a_inputFilePathName, 'file') == 2)
   fprintf('ERROR: decode_payload_data: File not found: %s\n', a_inputFilePathName);
   return;
end

% open the file and read the data
fId = fopen(a_inputFilePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_inputFilePathName);
   return;
end
data = fread(fId)';
fclose(fId);

% delete the part of the file padded with 0x1A
idF = find(fliplr(data) ~= hex2dec('1a'));
if (idF(1) > 1)
   data(end-(idF(1)-2):end) = [];
end

% parse payload data
o_payloadData = parse_payload_data(data);

% decode payload data
o_payloadData = decode_data(o_payloadData);

% finalize payload data
[o_payloadData, o_emptyPayloadData] = finalize_payload_data(o_payloadData);

return;

% ------------------------------------------------------------------------------
% Parse input payload data.
%
% SYNTAX :
%  [o_payloadData] = parse_payload_data(a_data)
%
% INPUT PARAMETERS :
%   a_data : payload data to parse
%
% OUTPUT PARAMETERS :
%   o_payloadData : parsed payload data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_payloadData] = parse_payload_data(a_data)

% output parameters initialization
o_payloadData = [];

% parse payload data
ptn1 = '<';
ptn2 = '<![CDATA[';
ptn3 = ']]>';
ptn4 = '</';
ptn5 = '>';
ptn6 = '/>';
ptn7 = '<!--';
ptn8 = '-->';

data = a_data;
payloadData = [];
start = 0;
level = 1;
textData = '';
while(~isempty(data))
   if (start == 0) && (char(data(1)) ~= ptn1)
      data(1) = [];
   else
      start = 1;
      if ((length(data) >= length(ptn2)) && (strcmp(char(data(1:length(ptn2))), ptn2)))
         % '<![CDATA['
         idF3 = strfind(char(data), ptn3);
         if (~isempty(idF3))
            % ']]>'
            idF3 = idF3(1);
            binData = data(length(ptn2)+1:idF3-1);
            newCell = cell(1, 5);
            newCell{1} = level;
            newCell{2} = 'CDATA';
            newCell{3} = 'B';
            newCell{4} = '';
            newCell{5} = binData;
            payloadData = cat(1, payloadData, newCell);
            newCell{1} = level;
            newCell{2} = 'CDATA';
            newCell{3} = 'E';
            newCell{4} = '';
            newCell{5} = '';
            payloadData = cat(1, payloadData, newCell);
            data(1:idF3+length(ptn3)-1) = [];
         else
            fprintf('ERROR: Inconsistent payload data => ignored\n');
            return;
         end
      elseif ((length(data) >= length(ptn7)) && (strcmp(char(data(1:length(ptn7))), ptn7)))
         % '<!--'
         idF8 = strfind(char(data), ptn8);
         if (~isempty(idF8))
            % '-->'
            idF8 = idF8(1);
            cmtData = char(data(length(ptn7)+1:idF8-1));
            newCell = cell(1, 5);
            newCell{1} = level;
            newCell{2} = 'COMMENT';
            newCell{3} = 'B';
            newCell{4} = '';
            newCell{5} = strtrim(cmtData);
            payloadData = cat(1, payloadData, newCell);
            newCell{1} = level;
            newCell{2} = 'COMMENT';
            newCell{3} = 'E';
            newCell{4} = '';
            newCell{5} = '';
            payloadData = cat(1, payloadData, newCell);
            data(1:idF8+length(ptn8)-1) = [];
         else
            fprintf('ERROR: Inconsistent payload data => ignored\n');
            return;
         end
      elseif ((length(data) >= length(ptn4)) && (strcmp(char(data(1:length(ptn4))), ptn4)))
         % '</'
         idF5 = strfind(data, ptn5);
         if (~isempty(idF5))
            % '>'
            idF5 = idF5(1);
            level = level - 1;
            tag = strtrim(char(data(length(ptn4)+1:idF5-1)));
            newCell = cell(1, 5);
            newCell{1} = level;
            newCell{2} = tag;
            newCell{3} = 'E';
            newCell{4} = '';
            % replace horizontal tab character by space (for Excel output)
            textData = regexprep(textData, char(9), char(32));
            newCell{5} = strtrim(textData);
            payloadData = cat(1, payloadData, newCell);
            data(1:idF5+length(ptn5)-1) = [];
            textData = '';
         else
            fprintf('ERROR: Inconsistent payload data => ignored\n');
            return;
         end
      elseif ((length(data) >= length(ptn1)) && (strcmp(char(data(1:length(ptn1))), ptn1)))
         % '<'
         idF5 = strfind(char(data), ptn5);
         idF6 = strfind(char(data), ptn6);
         if ((~isempty(idF5) && ~isempty(idF6) && (idF5(1) < idF6(1))) || ...
               (~isempty(idF5) && isempty(idF6)))
            % '>'
            idF5 = idF5(1);
            text = char(data(length(ptn1)+1:idF5-1));
            text = strtrim(text);
            idF = strfind(text, ' ');
            if (isempty(idF))
               tag = text;
               att = '';
            else
               tag = text(1:idF(1)-1);
               att = text(idF(1)+1:end);
            end
            newCell = cell(1, 5);
            newCell{1} = level;
            newCell{2} = tag;
            newCell{3} = 'B';
            newCell{4} = att;
            newCell{5} = '';
            payloadData = cat(1, payloadData, newCell);
            data(1:idF5+length(ptn5)-1) = [];
            level = level + 1;
            textData = '';
         else
            % '/>'
            idF6 = idF6(1);
            text = char(data(length(ptn1)+1:idF6-1));
            text = strtrim(text);
            idF = strfind(text, ' ');
            if (isempty(idF))
               tag = text;
               att = '';
            else
               tag = text(1:idF(1)-1);
               att = text(idF(1)+1:end);
            end
            newCell = cell(1, 5);
            newCell{1} = level;
            newCell{2} = tag;
            newCell{3} = 'B';
            newCell{4} = att;
            newCell{5} = '';
            payloadData = cat(1, payloadData, newCell);
            newCell = cell(1, 5);
            newCell{1} = level;
            newCell{2} = tag;
            newCell{3} = 'E';
            newCell{4} = '';
            newCell{5} = '';
            payloadData = cat(1, payloadData, newCell);
            data(1:idF6+length(ptn6)-1) = [];       
         end
      else
         textData = [textData char(data(1))];
         data(1) = [];
      end
   end
end

% assign the data to TAG_BEGIN (report the data assigned to TAG_END to its
% associated TAG_BEGIN)
idTagEnd = find([payloadData{:, 3}] == 'E');
for idT = 1:length(idTagEnd)
   if (~isempty(payloadData{idTagEnd(idT), 5}))
      
      % look for associated TAG_BEGIN
      idTagBegin = find(([payloadData{:, 1}] == payloadData{idTagEnd(idT), 1})' & ...
         (strcmp(payloadData(:, 2), payloadData(idTagEnd(idT), 2))) & ...
         ([payloadData{:, 3}] == 'B')');
      if (~isempty(idTagBegin))
         idPrev = find(idTagBegin < idTagEnd(idT));
         if (~isempty(idPrev))
            idTagBegin = idTagBegin(idPrev(end));
            payloadData{idTagBegin, 5} = payloadData{idTagEnd(idT), 5};
            payloadData{idTagEnd(idT), 5} = '';
         else
            fprintf('WARNING: Inconsistent payload data => ignored\n');
            return;
         end
      else
         fprintf('WARNING: Inconsistent payload data => ignored\n');
         return;
      end
   end
end

% parse attributes to get att_name and att_value
for idL = 1:size(payloadData, 1)
   if (~isempty(payloadData{idL, 4}))
      info = payloadData{idL, 4};
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
         payloadData{idL, 4} = data;
      else
         fprintf('ERROR: Inconsistent payload data => ignored\n');
         return;
      end
   end
end

o_payloadData = payloadData;

return;

% ------------------------------------------------------------------------------
% Decode payload data.
%
% SYNTAX :
%  [o_payloadData] = decode_data(a_payloadData)
%
% INPUT PARAMETERS :
%   a_payloadData : payload data to decode
%
% OUTPUT PARAMETERS :
%   o_payloadData : decoded payload data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_payloadData] = decode_data(a_payloadData)

% output parameters initialization
o_payloadData = [];

if (isempty(a_payloadData))
   return;
end

% decode sensor data
payloadData = a_payloadData;
idData = find(([payloadData{:, 1}] == 2)' & ...
   (strcmp(payloadData(:, 2), 'CDATA')) & ...
   ([payloadData{:, 3}] == 'B')');
for idL = 1:length(idData)
   idD = idData(idL);
   if (~isempty(payloadData{idD, 5}))
      
      % retrieve the associated sensor TAG_BEGIN
      idF = find(([payloadData{:, 1}] == 1)' & ...
         ([payloadData{:, 3}] == 'B')');
      if (~isempty(idF))
         idPrev = find(idF < idD);
         if (~isempty(idPrev))
            idSensor = idF(idPrev(end));
            
            % retrieve column names
            paramList = [];
            for id = idSensor+1:idD-1
               if ((payloadData{id, 1} == 2) && ...
                     (strncmp(payloadData{id, 2}, 'c[', 2)) && ...
                     (payloadData{id, 3} == 'B'))
                  paramList{end+1} = payloadData{id, 5};
               end
            end
            
            % decode sensor data
            data = decode_sensor_data(payloadData{idD, 5}, length(paramList));
            if (~isempty(data))
               payloadData{idD, 5} = {paramList {data}};
            else
               fprintf('ERROR: Inconsistent payload data\n');
               return;
            end
         else
            fprintf('ERROR: Inconsistent payload data\n');
            return;
         end
      else
         fprintf('ERROR: Inconsistent payload data\n');
         return;
      end
   end
end

o_payloadData = payloadData;

return;

% ------------------------------------------------------------------------------
% Decode payload sensor data.
%
% SYNTAX :
%  [o_sensorData] = decode_sensor_data(a_sensorData, a_nbCol)
%
% INPUT PARAMETERS :
%   a_sensorData : sensor data
%   a_nbCol      : number of columns in sensor data
%
% OUTPUT PARAMETERS :
%   o_sensorData : decoded sensor data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_sensorData] = decode_sensor_data(a_sensorData, a_nbCol)

% output parameters initialization
o_sensorData = [];

% check data consistency
if (rem(size(a_sensorData, 2), a_nbCol*4) ~= 0)
   fprintf('ERROR: Inconsistent payload data\n');
   return;
end

% decode sensor data
nbVal = length(a_sensorData)/4;
tabNbBits = repmat(32, 1, nbVal);
rawData = get_bits(1, tabNbBits, double(a_sensorData));
rawData = typecast(uint32(swapbytes(uint32(rawData))), 'single')';
rawData(find(rawData == inf('single'))) = nan;

o_sensorData = reshape(rawData, a_nbCol, length(rawData)/a_nbCol)';

return;

% ------------------------------------------------------------------------------
% Decode payload data.
%
% SYNTAX :
%  [o_payloadData, o_emptyPayloadData] = finalize_payload_data(a_payloadData)
%
% INPUT PARAMETERS :
%   a_payloadData : input payload data
%
% OUTPUT PARAMETERS :
%   o_payloadData      : finalized payload data
%   o_emptyPayloadData : payload data empty flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_payloadData, o_emptyPayloadData] = finalize_payload_data(a_payloadData)

% output parameters initialization
o_payloadData = [];
o_emptyPayloadData = 1;

if (isempty(a_payloadData))
   return;
end

ignoredItems = [ ...
   {'ENVIRONMENT'} ... % nominal
   {'LOG'} ... % nominal
   {'SENSOR_ACT'} ... % to manage float anomaly (ex: 2ee3_020_01_payload.bin)
   {'CYCLEPARK'} ... % to manage float anomaly (ex: 2ee3_020_01_payload.bin)
   {'PREDESCENT'} ... % to manage float anomaly (ex: 2ee3_020_01_payload.bin)
   {'DESCENT'} ... % to manage float anomaly (ex: 2ee3_020_01_payload.bin)
   {'PARK'} ... % to manage float anomaly (ex: 2ee3_020_01_payload.bin)
   {'DEEPPROFILE'} ... % to manage float anomaly (ex: 2ee3_020_01_payload.bin)
   {'SHORTPARK'} ... % to manage float anomaly (ex: 2ee3_020_01_payload.bin)
   {'ASCENT'} ... % to manage float anomaly (ex: 2ee3_020_01_payload.bin)
   {'SURFACE'} ... % to manage float anomaly (ex: 2ee3_020_01_payload.bin)
   ];

% add <SENSOR> TAGs around sensor data
payloadData = a_payloadData;
idLev1Begin = find(([payloadData{:, 1}] == 1) & ...
   ([payloadData{:, 3}] == 'B'));
for idLev1B = length(idLev1Begin):-1:1
   idLev1Start = idLev1Begin(idLev1B);
   if (~ismember(payloadData{idLev1Start, 2}, ignoredItems))
      o_emptyPayloadData = 0;
      idLev1End = find(strcmp(payloadData(:, 2), payloadData{idLev1Start, 2}) & ...
         ([payloadData{:, 3}] == 'E')');
      if (~isempty(idLev1End))
         idStop = find(idLev1End > idLev1Start);
         if (~isempty(idStop))
            idLev1Stop = idLev1End(idStop(1));
            [payloadData{[idLev1Start idLev1Stop], 1}] = deal(2);
            [payloadData{idLev1Start+1:idLev1Stop-1, 1}] = deal(3);
            
            % retrieve sensor number and phase name
            sensorInfo = payloadData{idLev1Start, 2};
            idF = strfind(sensorInfo, '-');
            sensorName = sensorInfo(1:idF(1)-1);
            if (~strcmp(sensorName, 'PSA'))
               sensorNum = sensorInfo(idF(1)+1);
            else
               sensorNum = sensorInfo(idF(2)+1);
            end
            
            if (idLev1Stop < size(payloadData, 1))
               payloadData(idLev1Stop+2:end+1, :) = payloadData(idLev1Stop+1:end, :);
               payloadData{idLev1Stop+1, 1} = 1;
               payloadData{idLev1Stop+1, 2} = ['SENSOR_0' sensorNum];
               payloadData{idLev1Stop+1, 3} = 'E';
               payloadData{idLev1Stop+1, 4} = '';
               payloadData{idLev1Stop+1, 5} = '';
            else
               payloadData{idLev1Stop+1, 1} = 1;
               payloadData{idLev1Stop+1, 2} = ['SENSOR_0' sensorNum];
               payloadData{idLev1Stop+1, 3} = 'E';
               payloadData{idLev1Stop+1, 4} = '';
               payloadData{idLev1Stop+1, 5} = '';
            end
            payloadData(idLev1Start+1:end+1, :) = payloadData(idLev1Start:end, :);
            payloadData{idLev1Start, 1} = 1;
            payloadData{idLev1Start, 2} = ['SENSOR_0' sensorNum];
            payloadData{idLev1Start, 3} = 'B';
            payloadData{idLev1Start, 4} = '';
            payloadData{idLev1Start, 5} = '';
         else
            fprintf('ERROR: Inconsistent payload data\n');
         end
      else
         fprintf('ERROR: Inconsistent payload data\n');
      end
   end
end

o_payloadData = payloadData;

return;
