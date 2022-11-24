% ------------------------------------------------------------------------------
% Create SBD files from Remocean data packets.
%
% SYNTAX :
%  [o_ok] = save_mono_packet_sbd_files(a_tabSensors, a_tabDates, a_loginName, a_outputPathName, a_cyNumFile)
%
% INPUT PARAMETERS :
%   a_tabSensors     : data packets
%   a_tabDates       : data packet reception dates
%   a_loginName      : float login name
%   a_outputPathName : name of the directory to save the SBD files
%   a_cyNumFile      : cycle numbe of the original the SBD file
%
% OUTPUT PARAMETERS :
%   o_ok : nominal processing flag (1 if everything is ok, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/04/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = save_mono_packet_sbd_files(a_tabSensors, a_tabDates, a_loginName, a_outputPathName, a_cyNumFile)

o_ok = 0;

global g_decArgo_janFirst1950InMatlab;


% split sensor technical data packets (packet type 250 is 70 bytes length
% whereas input SBD size is 140 bytes)
tabSensors = [];
tabDates = [];
idSensorTechDataPack = find(a_tabSensors(:, 1) == 250);
for id = 1:length(idSensorTechDataPack)
   idPack = idSensorTechDataPack(id);
   
   dataPack = a_tabSensors(idPack, :);
   datePack = a_tabDates(idPack);
   
   tabSensors = [tabSensors; [dataPack(1:70) repmat([0], 1, 70)]];
   tabDates = [tabDates; datePack];
   
   if ~((length(unique(dataPack(71:140))) == 1) && (dataPack(71) == 255))
      tabSensors = [tabSensors; [dataPack(71:140) repmat([0], 1, 70)]];
      tabDates = [tabDates; datePack];
   end
end
idOther = setdiff([1:size(a_tabSensors, 1)], idSensorTechDataPack);
tabSensors = [tabSensors; a_tabSensors(idOther, :)];
tabDates = [tabDates; a_tabDates(idOther, :)];

% lut to convert sensor data type to sensor number
lut = [0 0 0 1 1 1 -1 -1 -1 3 3 3 2 2 2 4 4 4 5 5 5 6 6 6 6 6];

% decode packet data
for idMes = 1:size(tabSensors, 1)
   
   % sensor data type
   sensorDataType = [];
   
   % sensor number
   sensorNum = [];
   
   % packet type
   packType = tabSensors(idMes, 1);
   
   % output data
   outputData = tabSensors(idMes, :);
   
   switch (packType)
      
      case 0
         % sensor data
         
         % sensor data type
         sensorDataType = tabSensors(idMes, 2);
         if ((sensorDataType+1 < 1) || (sensorDataType+1 > length(lut)))
            fprintf('WARNING: Inconsistent sensorDataType (%d) => packet ignored\n', ...
               sensorDataType);
            continue
         end
         
         % sensor number
         sensorNum = lut(sensorDataType+1);
         
         % message data frame
         msgData = tabSensors(idMes, 3:end);
         
         % empty msg
         uMsgdata = unique(msgData);
         if ((length(uMsgdata) == 1) && (uMsgdata == 0))
            continue
         end
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [16 8 8];
         % get item bits
         values = get_bits(firstBit, tabNbBits, msgData);
         
         % decode and store data values
         cycleNum = values(1);
         profNum = values(2);
         phaseNum = values(3);
         
         %          if ((sensorNum == 0) && (cycleNum == 3) && (profNum == 0) && (phaseNum == 9))
         %             g_decArgo_cpt = g_decArgo_cpt + 1
         %          end
         
      case 250
         % sensor tech data
         
         % sensor number
         sensorNum = tabSensors(idMes, 2);
         
         % message data frame
         msgData = tabSensors(idMes, 3:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [16 8];
         % get item bits
         values = get_bits(firstBit, tabNbBits, msgData);
         
         % decode and store data values
         cycleNum = values(1);
         profNum = values(2);
         phaseNum = '';
         
      case 251
         % sensor parameter
         
         % sensor number
         sensorNum = tabSensors(idMes, 2);

         cycleNum = '';
         profNum = '';
         phaseNum = '';
         
      case 252
         % float pressure data
         
         % message data frame
         msgData = tabSensors(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [16 repmat([4 4 8 8 16], 1, 27) 16];
         % get item bits
         values = get_bits(firstBit, tabNbBits, msgData);
         
         % decode and store data values
         cycleNum = values(1);
         
         outputData = [];
         for idBin = 1:27
            profNum = values(5*(idBin-1)+3);
            phaseNum = values(5*(idBin-1)+2);
            pumpOrEv = values(5*(idBin-1)+4);
            actPres = values(5*(idBin-1)+5);
            time = values(5*(idBin-1)+6);
            
            outputData = [outputData; ...
               [cycleNum ...
               profNum ...
               phaseNum ...
               uint8(packType) ...
               uint8(bitshift(cycleNum, -8)) ...
               uint8(bitand(cycleNum, 2^8-1)) ...
               uint8(bitshift(phaseNum, 4) + profNum) ...
               uint8(pumpOrEv) ...
               uint8(actPres) ...
               uint8(bitshift(time, -8)) ...
               uint8(bitand(time, 2^8-1)) ...
               repmat(uint8(0), 1, 132)]];
         end
         
      case 253
         % float technical data
         
         % message data frame
         msgData = tabSensors(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [repmat([8], 1, 6) 16 repmat([16 16 8], 1, 2)];
         % get item bits
         tabTech = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabTech(9);
         profNum = tabTech(10);
         phaseNum = tabTech(13);
         
      case 254
         % float prog technical data
         
         % message data frame
         msgData = tabSensors(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [repmat([8], 1, 6) 16 8 repmat([16], 1, 28) 592];
         % get item bits
         values = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = values(7);
         profNum = values(8);
         phaseNum = '';
         
      case 255
         % float prog param data
         
         % message data frame
         msgData = tabSensors(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [repmat([8], 1, 6) 16 8 8 16 8 repmat([16 8 8 8], 1, 5) ...
            8 16 8 repmat([8 8 16 16 8], 1, 10) 216];
         
         % get item bits
         values = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = values(7);
         profNum = values(8);
         phaseNum = '';
         
      otherwise
         fprintf('WARNING: Nothing done yet for packet type #%d\n', ...
            packType);
         cycleNum = '';
         profNum = '';
         phaseNum = '';
   end
   
   %    fprintf('Type %d ycle #%d prof #%d phase %d\n', ...
   %       packType, cycleNum, profNum, phaseNum);
   
   cycleNumStr = 'xxx';
   profNumStr = 'x';
   phaseNumStr = 'xx';
   sensorDataTypeStr = 'xx';
   sensorNumStr = 'x';

   if (packType ~= 252)
      %       if (~isempty(cycleNum) && (cycleNum == a_cyNumFile))
      if (~isempty(cycleNum))
         cycleNumStr = sprintf('%03d', cycleNum);
      end
      if (~isempty(profNum))
         profNumStr = sprintf('%d', profNum);
      end
      if (~isempty(phaseNum))
         phaseNumStr = sprintf('%02d', phaseNum);
      end
      if (~isempty(sensorDataType))
         sensorDataTypeStr = sprintf('%02d', sensorDataType);
      end
      if (~isempty(sensorNum))
         sensorNumStr = sprintf('%d', sensorNum);
      end
      
      outputFileName = [ ...
         a_loginName '_' ...
         datestr(a_tabDates + g_decArgo_janFirst1950InMatlab, 'yyyymmddTHHMMSS') '_' ...
         sprintf('%03d', packType) '_' ...
         cycleNumStr '_' ...
         profNumStr '_' ...
         phaseNumStr '_' ...
         sensorNumStr '_' ...
         sensorDataTypeStr];
      
      fileNnum = 0;
      outputFilePathName = [a_outputPathName '/' outputFileName '_' sprintf('%03d.sbd', fileNnum)];
      if (exist(outputFilePathName, 'file') == 2)
         maxNum = 0;
         existingFiles = dir([a_outputPathName '/' outputFileName '_*.sbd']);
         for idFile = 1:length(existingFiles)
            fileName = existingFiles(idFile).name;
            idFUs = strfind(fileName, '_');
            maxNum = max(maxNum, str2num(fileName(idFUs(8)+1:end-4)));
         end
         fileNnum = maxNum + 1;
         outputFilePathName = [a_outputPathName '/' outputFileName '_' sprintf('%03d.sbd', fileNnum)];
      end
      
      if (exist(outputFilePathName, 'file') == 2)
         fprintf('ERROR: Output file already exists: %s\n', ...
            outputFilePathName);
      else
         fId = fopen(outputFilePathName, 'w');
         if (fId == -1)
            fprintf('ERROR: Error while creating file : %s\n', ...
               outputFilePathName);
         end
         
         fwrite(fId, outputData');
         
         fclose(fId);
      end
      %       elseif (~isempty(cycleNum))
      %          fprintf('WARNING: Cycle number of the data (%d) differ from cycle number of the SBD file name (%d) => data not considered\n', ...
      %             cycleNum, a_cyNumFile);
      %       end
   else
      
      for idMsg = 1:size(outputData, 1)
         cycleNum = outputData(idMsg, 1);
         profNum = outputData(idMsg, 2);
         phaseNum = outputData(idMsg, 3);
         
         cycleNumStr = sprintf('%03d', cycleNum);
         profNumStr = sprintf('%d', profNum);
         phaseNumStr = sprintf('%02d', phaseNum);
         
         outputFileName = [ ...
            a_loginName '_' ...
            datestr(a_tabDates + g_decArgo_janFirst1950InMatlab, 'yyyymmddTHHMMSS') '_' ...
            sprintf('%03d', packType) '_' ...
            cycleNumStr '_' ...
            profNumStr '_' ...
            phaseNumStr '_' ...
            sensorNumStr '_' ...
            sensorDataTypeStr];
      
         fileNnum = 0;
         outputFilePathName = [a_outputPathName '/' outputFileName '_' sprintf('%03d.sbd', fileNnum)];
         if (exist(outputFilePathName, 'file') == 2)
            maxNum = 0;
            existingFiles = dir([a_outputPathName '/' outputFileName '_*.sbd']);
            for idFile = 1:length(existingFiles)
               fileName = existingFiles(idFile).name;
               idFUs = strfind(fileName, '_');
               maxNum = max(maxNum, str2num(fileName(idFUs(8)+1:end-4)));
            end
            fileNnum = maxNum + 1;
            outputFilePathName = [a_outputPathName '/' outputFileName '_' sprintf('%03d.sbd', fileNnum)];
         end
         
         if (exist(outputFilePathName, 'file') == 2)
            fprintf('ERROR: Output file already exists: %s\n', ...
               outputFilePathName);
         else
            fId = fopen(outputFilePathName, 'w');
            if (fId == -1)
               fprintf('ERROR: Error while creating file : %s\n', ...
                  outputFilePathName);
            end
            
            fwrite(fId, outputData(idMsg, 4:end)');
            
            fclose(fId);
         end
         %          else
         %             fprintf('WARNING: Cycle number of the data (%d) differ from cycle number of the SBD file name (%d) => data not considered\n', ...
         %                cycleNum, a_cyNumFile);
         %          end
      end
   end
end

o_ok = 1;

return
