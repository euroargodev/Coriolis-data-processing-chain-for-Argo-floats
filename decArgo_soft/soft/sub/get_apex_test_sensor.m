% ------------------------------------------------------------------------------
% Read and select data of APEX test message transmission.
%
% SYNTAX :
%  [o_argosLocDate, o_argosLocLon, o_argosLocLat, o_argosLocAcc, o_argosLocSat, ...
%    o_argosDataData, o_argosDataDate, o_sensorData, o_sensorDate] = ...
%    get_apex_test_sensor(a_argosPathFileName, a_argosId, a_frameLength, ...
%    a_nbTestMsg, a_testMsgBytesToFreeze)
%
% INPUT PARAMETERS :
%   a_argosPathFileName    : input Argos file path name
%   a_argosId              : float Argos Id number
%   a_frameLength          : test message length (in bytes)
%   a_nbTestMsg            : number of test messages of this APEX version
%   a_testMsgBytesToFreeze : bytes to freeze during the redundancy step of the
%                            data selection
%
% OUTPUT PARAMETERS :
%   o_argosLocDate  : Argos location dates
%   o_argosLocLon   : Argos location longitudes
%   o_argosLocLat   : Argos location latitudes
%   o_argosLocAcc   : Argos location classes
%   o_argosLocSat   : Argos location satellite names
%   o_argosDataData : original Argos data
%   o_argosDataDate : Argos message dates
%   o_sensorData    : data of selected test message(s)
%   o_sensorDate    : date of selected messages
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/27/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_argosLocDate, o_argosLocLon, o_argosLocLat, o_argosLocAcc, o_argosLocSat, ...
   o_argosDataData, o_argosDataUsed, o_argosDataDate, o_sensorData, o_sensorDate] = ...
   get_apex_test_sensor(a_argosPathFileName, a_argosId, a_frameLength, ...
   a_nbTestMsg, a_testMsgBytesToFreeze)

% output parameters initialization
o_argosLocDate = [];
o_argosLocLon = [];
o_argosLocLat = [];
o_argosLocAcc = [];
o_argosLocSat = [];
o_argosDataData = [];
o_argosDataUsed = [];
o_argosDataDate = [];
o_sensorData = [];
o_sensorDate = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% configuration values
global g_decArgo_generateNcTech;


if ~(exist(a_argosPathFileName, 'file') == 2)
   fprintf('ERROR: Argos file not found: %s\n', a_argosPathFileName);
   return;
end

% read Argos file
[o_argosLocDate, o_argosLocLon, o_argosLocLat, o_argosLocAcc, o_argosLocSat, ...
   o_argosDataDate, o_argosDataData] = read_argos_file({a_argosPathFileName}, a_argosId, a_frameLength);

if (a_frameLength == 31)
   if (size(o_argosDataData, 2) == 32)
      o_argosDataData(:, 32) = [];
   end
end

nbMesCrcOk = 0;
if (a_nbTestMsg == 1)
   
   % process all test data together
   
   % bytes to freeze for these messages
   sensorTofreeze = [];
   if (~isempty(a_testMsgBytesToFreeze))
      sensorTofreeze = a_testMsgBytesToFreeze{1, 2};
   end
   
   % process the CRC check on the message data
   idMsgCrcOk = [];
   for idMsg = 1:size(o_argosDataData, 1)
      sensor = o_argosDataData(idMsg, :);
      if (check_crc_apx(sensor) == 1)
         idMsgCrcOk = [idMsgCrcOk idMsg];
         nbMesCrcOk = nbMesCrcOk + 1;
      end
   end
   
   % some messages succeed the CRC check
   if (~isempty(idMsgCrcOk))
      
      % select the "most redundant" message
      tabFrozenData = [];
      tabData = [];
      tabDate = [];
      tabOcc = [];
      tabId = [];
      for id = 1:length(idMsgCrcOk)
         
         sensor = o_argosDataData(idMsgCrcOk(id), :);
         
         % freeze bytes for the redundancy step
         if (~isempty(sensorTofreeze))
            % store the original values of the sensor to freeze
            frozenSensors = sensor(sensorTofreeze);
            sensor(sensorTofreeze) = 0;
         end
         
         currentData = sensor(2:end);
         
         % don't take NULL data message into account
         if (unique(currentData) == 0)
            continue;
         end
         
         % compute the redundancy of the messages
         ok = 0;
         for idData = 1:size(tabData, 1)
            comp = (tabData(idData, :) == currentData);
            if (isempty(find(comp == 0, 1)))
               % already received message, update the redundancy counter
               tabOcc(idData) = tabOcc(idData) + 1;
               tabId{idData} = [tabId{idData} idMsgCrcOk(id)];
               ok = 1;
               break;
            end
         end
         
         if (ok == 0)
            % never received message, initialize the redundancy counter
            if (~isempty(sensorTofreeze))
               tabFrozenData = [tabFrozenData; frozenSensors];
            end
            tabData = [tabData; currentData];
            tabDate = [tabDate; o_argosDataDate(idMsgCrcOk(id))];
            tabOcc = [tabOcc; 1];
            tabId{end+1} = idMsgCrcOk(id);
         end
      end
      
      % select the "most redundant" message
      if (~isempty(tabOcc))
         [valMax, idMax] = max(tabOcc);
         data = tabData(idMax, :);
         if (~isempty(sensorTofreeze))
            data(sensorTofreeze-1) = tabFrozenData(idMax, :);
         end
         o_sensorData = [o_sensorData; valMax data];
         o_sensorDate = [o_sensorDate; tabDate(idMax)];
         o_argosDataUsed{end+1} = tabId{idMax};
      end
      
   else
      
      % there is no message with a good CRC
      
      if (size(o_argosDataData, 1) > 1)
         
         % store the original values of the sensor to freeze
         tabFrozenData = [];
         tabBadData = [];
         for id = 1:size(o_argosDataData, 1)
            
            sensor = o_argosDataData(id, :);
            
            % freeze bytes
            if (~isempty(sensorTofreeze))
               tabFrozenData = [tabFrozenData; sensor(sensorTofreeze)];
               sensor(sensorTofreeze) = 0;
            end
            
            tabBadData(id, :) = sensor';
         end
         
         % create a new message by combining the bits of the received ones
         [combinedData] = combine_bits_apx(tabBadData);
         
         % replace the frozen values in the combined message and check the
         % CRC of the created message
         for id = 1:size(o_argosDataData, 1)
            
            % set the CRC value
            combinedMsg = combinedData;
            combinedMsg(1) = tabBadData(id, 1);
            
            % replace the original frozen values
            if (~isempty(sensorTofreeze))
               combinedMsg(sensorTofreeze) = tabFrozenData(id, :);
            end
            
            % process the CRC check on the message data
            if (check_crc_apx(combinedMsg) == 1)
               o_sensorData = [o_sensorData; 0 combinedData(2:end)];
               o_sensorDate = [o_sensorDate; o_argosDataDate(id)];
               o_argosDataUsed{end+1} = [];
               nbMesCrcOk = nbMesCrcOk + 1;
               break;
            end
         end
      end
   end
   
else
   
   % process test data according to message Id
   % (similar to sensor data processing, see get_apex_data_sensor.m)
   
   msgNums = sort(unique(o_argosDataData(:, 2)));
   if (any(msgNums > a_nbTestMsg))
      idDel = find(msgNums > a_nbTestMsg);
      %       ignoredStr = sprintf('#%d, ', msgNums(idDel));
      %       fprintf('WARNING: Float #%d Cycle #%d: ignored Argos test message %s\n', ...
      %          g_decArgo_floatNum, g_decArgo_cycleNum, ignoredStr(1:end-2));
      msgNums(idDel) = [];
   end
   for idNum = 1:length(msgNums)
      
      % first message Id is #1
      if (msgNums(idNum) > 0)
         
         % bytes to freeze for this message Id
         sensorTofreeze = [];
         idMTF = find(cell2mat(a_testMsgBytesToFreeze(:, 1)) == msgNums(idNum));
         if (~isempty(idMTF))
            sensorTofreeze = a_testMsgBytesToFreeze{idMTF, 2};
         end
         
         % process the CRC check on the message data
         idForNumCrcOk = [];
         idForNum = find(o_argosDataData(:, 2) == msgNums(idNum));
         for idMsg = 1:length(idForNum)
            sensor = o_argosDataData(idForNum(idMsg), :);
            if (check_crc_apx(sensor) == 1)
               idForNumCrcOk = [idForNumCrcOk idForNum(idMsg)];
               nbMesCrcOk = nbMesCrcOk + 1;
            end
         end
         
         % some messages succeed the CRC check
         if (~isempty(idForNumCrcOk))
            
            % select the "most redundant" message for this msg Id
            tabFrozenData = [];
            tabData = [];
            tabDate = [];
            tabOcc = [];
            tabId = [];
            for id = 1:length(idForNumCrcOk)
               
               sensor = o_argosDataData(idForNumCrcOk(id), :);
               
               % freeze bytes for the redundancy step
               if (~isempty(sensorTofreeze))
                  % store the original values of the sensor to freeze
                  frozenSensors = sensor(sensorTofreeze);
                  sensor(sensorTofreeze) = 0;
               end
               
               currentData = sensor(3:end);
               
               % don't take NULL data message into account
               if (unique(currentData) == 0)
                  continue;
               end
               
               % compute the redundancy of the messages
               ok = 0;
               for idData = 1:size(tabData, 1)
                  comp = (tabData(idData, :) == currentData);
                  if (isempty(find(comp == 0, 1)))
                     % already received message, update the redundancy counter
                     tabOcc(idData) = tabOcc(idData) + 1;
                     tabId{idData} = [tabId{idData} idForNumCrcOk(id)];
                     ok = 1;
                     break;
                  end
               end
               
               if (ok == 0)
                  % never received message, initialize the redundancy counter
                  if (~isempty(sensorTofreeze))
                     tabFrozenData = [tabFrozenData; frozenSensors];
                  end
                  tabData = [tabData; currentData];
                  tabDate = [tabDate; o_argosDataDate(idForNumCrcOk(id))];
                  tabOcc = [tabOcc; 1];
                  tabId{end+1} = idForNumCrcOk(id);
               end
            end
            
            % select the "most redundant" message
            if (~isempty(tabOcc))
               [valMax, idMax] = max(tabOcc);
               data = tabData(idMax, :);
               if (~isempty(sensorTofreeze))
                  data(sensorTofreeze-2) = tabFrozenData(idMax, :);
               end
               o_sensorData = [o_sensorData; valMax msgNums(idNum) data];
               o_sensorDate = [o_sensorDate; tabDate(idMax)];
               o_argosDataUsed{end+1} = tabId{idMax};
            end
            
         else
            
            % there is no message with a good CRC
            
            if (length(idForNum) > 1)
               
               % store the original values of the sensor to freeze
               tabFrozenData = [];
               tabBadData = [];
               for id = 1:length(idForNum)
                  
                  sensor = o_argosDataData(idForNum(id), :);
                  
                  % freeze bytes
                  if (~isempty(sensorTofreeze))
                     tabFrozenData = [tabFrozenData; sensor(sensorTofreeze)];
                     sensor(sensorTofreeze) = 0;
                  end
                  
                  tabBadData(id, :) = sensor';
               end
               
               % create a new message by combining the bits of the received ones
               [combinedData] = combine_bits_apx(tabBadData);
               
               % replace the frozen values in the combined message and check the
               % CRC of the created message
               for id = 1:length(idForNum)
                  
                  % set the CRC value
                  combinedMsg = combinedData;
                  combinedMsg(1) = tabBadData(id, 1);
                  
                  % replace the original frozen values
                  if (~isempty(sensorTofreeze))
                     combinedMsg(sensorTofreeze) = tabFrozenData(id, :);
                  end
                  
                  % process the CRC check on the message data
                  if (check_crc_apx(combinedMsg) == 1)
                     o_sensorData = [o_sensorData; 0 msgNums(idNum) combinedData(3:end)];
                     o_sensorDate = [o_sensorDate; o_argosDataDate(idForNum(id))];
                     o_argosDataUsed{end+1} = [];
                     nbMesCrcOk = nbMesCrcOk + 1;
                     break;
                  end
               end
            end
         end
      end
   end
end

% output CSV file
if (~isempty(g_decArgo_outputCsvFileId))
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Info; -; ARGOS DATA FILE CONTENTS\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   [~, fileName, ext] = fileparts(a_argosPathFileName);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Info; -; Argos data file name; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, [fileName ext]);
   
   firstArgosMsgDate = min([o_argosLocDate; o_argosDataDate]);
   lastArgosMsgDate = max([o_argosLocDate; o_argosDataDate]);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Info; -; Argos data file time span; %s (%s to %s)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      format_time_dec_argo((lastArgosMsgDate-firstArgosMsgDate)*24), ...
      julian_2_gregorian_dec_argo(firstArgosMsgDate), ...
      julian_2_gregorian_dec_argo(lastArgosMsgDate));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Info; -; Number of locations received; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, length(o_argosLocDate));
   
   nbMesTot = size(o_argosDataData, 1);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Info; -; Number of messages received; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, nbMesTot);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Info; -; Number of messages with good CRC; %d; %.f %%\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, nbMesCrcOk, nbMesCrcOk*100/nbMesTot);
   
   expected = 1:a_nbTestMsg;
   received = [];
   if (~isempty(o_sensorData))
      received = o_sensorData(:, 2)';
   end
   numMissing = setdiff(expected, received);
   if (~isempty(numMissing))
      missingStr = sprintf('#%d, ', numMissing);
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Info; -; ! MISSING TEST MESSAGE (%s) !;\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, missingStr(1:end-2));
   end
   
end

% output NetCDF files
if (g_decArgo_generateNcTech ~= 0)
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 10];
   g_decArgo_outputNcParamValue{end+1} = length(o_argosLocAcc);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 11];
   g_decArgo_outputNcParamValue{end+1} = sum(char(o_argosLocAcc) == '0');
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 12];
   g_decArgo_outputNcParamValue{end+1} = sum(char(o_argosLocAcc) == '1');
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 13];
   g_decArgo_outputNcParamValue{end+1} = sum(char(o_argosLocAcc) == '2');
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 14];
   g_decArgo_outputNcParamValue{end+1} = sum(char(o_argosLocAcc) == '3');
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 15];
   g_decArgo_outputNcParamValue{end+1} = sum(char(o_argosLocAcc) == 'A');
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 16];
   g_decArgo_outputNcParamValue{end+1} = sum(char(o_argosLocAcc) == 'B');
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 17];
   g_decArgo_outputNcParamValue{end+1} = sum(char(o_argosLocAcc) == 'Z');
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 18];
   g_decArgo_outputNcParamValue{end+1} = size(o_argosDataData, 1);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 19];
   g_decArgo_outputNcParamValue{end+1} = nbMesCrcOk;
   
end

return;
