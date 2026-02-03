% ------------------------------------------------------------------------------
% Create decoding buffers.
%
% SYNTAX :
% [o_floatbuffers] = create_decoding_buffers_401(a_floatData)
%
% INPUT PARAMETERS :
%   o_floatData : float data information
%
% OUTPUT PARAMETERS :
%   o_floatbuffers  : float decoding buffers
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/18/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatbuffers] = create_decoding_buffers_401(a_floatData)

% output parameters initialization
o_floatbuffers = [];

% current float WMO number
global g_decArgo_floatNum;

% configuration values
global g_decArgo_dirOutputCsvFile;

% output CSV file Id
global g_decArgo_outputCsvFileId;


% floatData : float data information
% 1: fileType
%    (10: selfTest, 11: tech_1, 12: tech_2, 13: eol,
%     20: desc2Park, 21: parkDrift, 22: desc2Prof, 23: profDrift, 24: asc, 25: inAir,
%     30: config, 40: command)
% 2: missionNum
% 3: cycleNum
% 4: fileName
% 5: tabTechEvt or tabTech or sensorNum or confLabels
% 6: tabTechTime or formatNum or confValues
% 7: tabTechTraj or measData
% 8: tabTechBuoy
% 9: tabTechSpy
% 10: selfTestDate or settingDate or cycleLastDate
% 11: float HEX base file Name
% 12: float final file name
% 13: zip file size
% 14: final file size
% 15: SBD file information (1: SBD file name, 2: SBD file date, 3: SBD file size, 4: data file size

% buffers : buffers information
% 1: index to float data array
% 2: rank
% 3: cycleNum
% 4: buffer completed
% 5: deep cycle flag
% 6: data type
% 7: sensor #1 data flag
% 8 to 13: nb meas from sensor #1 for phases #0 to #5
% 14: sensor #2 data flag
% 15 to 20: nb meas from sensor #2 for phases #0 to #5
% 21: sensor #3 data flag
% 22 to 27: nb meas from sensor #3 for phases #0 to #5

buffers = nan(size(a_floatData, 1), 27);

% index to float data
buffers(:, 1) = 1:size(a_floatData, 1);

% rank for decoding
buffers(:, 2) = -1;

% cycle number
buffers(:, 3) = [a_floatData{:, 3}];
idTech1 = find([a_floatData{:, 1}] == 11);
idTech2 = find([a_floatData{:, 1}] == 12);
% assign cycle # - 1 to TECH #1 files
% (it is the second session of the previous cycle)
buffers(idTech1, 3) = buffers(idTech1, 3) - 1;

% deep cycle flag
buffers(:, 5) = 0;

% data type
buffers(:, 6) = [a_floatData{:, 1}];

% set expected number of measurements from TECH #2 data
if (~isempty(g_decArgo_outputCsvFileId))
   for idT = idTech2
      idSensor = find([a_floatData{idT, 5}.techId] == 900001);
      if (~isempty(idSensor))
         idPhase = find([a_floatData{idT, 5}.techId] == 900002);
         idZ1 = find([a_floatData{idT, 5}.techId] == 900003);
         idZ2 = find([a_floatData{idT, 5}.techId] == 900005);
         idZ3 = find([a_floatData{idT, 5}.techId] == 900007);
         idZ4 = find([a_floatData{idT, 5}.techId] == 900009);
         idZ5 = find([a_floatData{idT, 5}.techId] == 900011);
         for id = 1:length(idSensor)
            sensorNum = str2double(a_floatData{idT, 5}(idSensor(id)).valueStr);
            phaseNum = str2double(a_floatData{idT, 5}(idPhase(id)).valueStr);
            nbZ1 = str2double(a_floatData{idT, 5}(idZ1(id)).valueStr);
            nbZ2 = str2double(a_floatData{idT, 5}(idZ2(id)).valueStr);
            nbZ3 = str2double(a_floatData{idT, 5}(idZ3(id)).valueStr);
            nbZ4 = str2double(a_floatData{idT, 5}(idZ4(id)).valueStr);
            nbZ5 = str2double(a_floatData{idT, 5}(idZ5(id)).valueStr);
            nb = nbZ1 + nbZ2 + nbZ3 + nbZ4 + nbZ5;

            buffers(idT, (sensorNum-1)*7+7) = sensorNum;
            buffers(idT, (sensorNum-1)*7+7 + phaseNum+1) = nb;
         end
      end

      idSensor = find([a_floatData{idT, 5}.techId] == 900101);
      if (~isempty(idSensor))
         idPhase = find([a_floatData{idT, 5}.techId] == 900102);
         idNb = find([a_floatData{idT, 5}.techId] == 900103);
         for id = 1:length(idSensor)
            sensorNum = str2double(a_floatData{idT, 5}(idSensor(id)).valueStr);
            phaseNum = str2double(a_floatData{idT, 5}(idPhase(id)).valueStr);
            nb = str2double(a_floatData{idT, 5}(idNb(id)).valueStr);

            buffers(idT, (sensorNum-1)*7+7) = sensorNum;
            buffers(idT, (sensorNum-1)*7+7 + phaseNum+1) = nb;
         end
      end
   end
else
   for idT = idTech2
      idTech = find(ismember([a_floatData{idT, 5}.techId], [900013, 900014, 900015, 900104, 900105, 900106]));
      for id = 1:length(idTech)
         tech = a_floatData{idT, 5}(idTech(id));
         sensorNum = tech.sensorNum;
         phaseNum = tech.phaseNum;
         nb = str2double(tech.value);

         buffers(idT, (sensorNum-1)*7+7) = sensorNum;
         if (isnan(buffers(idT, (sensorNum-1)*7+7 + phaseNum+1)))
            buffers(idT, (sensorNum-1)*7+7 + phaseNum+1) = nb;
         else
            buffers(idT, (sensorNum-1)*7+7 + phaseNum+1) = buffers(idT, (sensorNum-1)*7+7 + phaseNum+1) + nb;
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% specific PFV2
if (g_decArgo_floatNum == 2904006)
   % remove the reported measurement at deep park drift in M3C2TEC2.hex, M3C3TEC2.hex and M3C4TEC2.hex files
   idFiles = find(ismember(a_floatData(:, 4), [{'M3C2TEC2.hex'}, {'M3C3TEC2.hex'}, {'M3C4TEC2.hex'}]));
   sensorNum = 1;
   phaseNum = 3;
   for idF = idFiles'
      buffers(idF, (sensorNum-1)*7+7 + phaseNum+1) = nan;
   end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set received number of measurements from data files
idData = find(ismember([a_floatData{:, 1}], 20:25));
for idD = idData
   phaseNum = a_floatData{idD, 1} - 20;
   sensorNum = a_floatData{idD, 5};
   nb = size(a_floatData{idD, 7}, 1);
   buffers(idD, (sensorNum-1)*7+7) = sensorNum;
   buffers(idD, (sensorNum-1)*7+7 + phaseNum+1) = nb;
end

% assign last config received before data to cycle #0
idConf = find(([a_floatData{:, 1}] == 30) & isnan([a_floatData{:, 3}]));
if (~isempty(idConf))
   buffers(idConf(end), 3) = 0;
end

% assign self test data to following cycle #
idSelfTest = find([a_floatData{:, 1}] == 10);
if (~isempty(idSelfTest))
   buffers(idSelfTest, 3) = buffers(idSelfTest+1, 3);
end

% remove command files
idCmd = find([a_floatData{:, 1}] == 40);
buffers(idCmd, :) = [];

% check buffers
cyNumList = unique(buffers(:, 3));
expCyNumList = 0:max(cyNumList);
rank = 1;
fprintf('\n');
for cyNum = expCyNumList
   idForCy = find(buffers(:, 3) == cyNum);
   if (~isempty(idForCy))
      fprintf('BUFF_INFO: Float #%d Cycle #%3d : ', ...
         g_decArgo_floatNum, cyNum);
      okFlag = 1;
      if (cyNum > 0)         
         idTech1 = find(buffers(idForCy, 6) == 11);
         idTech2 = find(buffers(idForCy, 6) == 12);
         if (~isempty(idTech1) && ~isempty(idTech2))
            idNoTech = find((buffers(idForCy, 6) ~= 11) & (buffers(idForCy, 6) ~= 12));
         elseif (~isempty(idTech2))
            idNoTech = find((buffers(idForCy, 6) ~= 11) & (buffers(idForCy, 6) ~= 12));
         end
         if (~isempty(idTech2))
            for idS = 1:3
               if (~isnan(buffers(idForCy(idTech2), (idS-1)*7+7)))
                  for idP = 0:5
                     if (~isnan(buffers(idForCy(idTech2), (idS-1)*7+7 + idP+1)))
                        if (sum(buffers(idForCy(idNoTech), (idS-1)*7+7 + idP+1), "omitnan") ~= buffers(idForCy(idTech2), (idS-1)*7+7 + idP+1))
                           okFlag = 0;
                           break
                        end
                     end
                  end
               end
               if (~okFlag)
                  break
               end
            end
            if (okFlag)
               fprintf('COMPLETED\n');
            else
               fprintf('UNCOMPLETED\n');
               for idS = 1:3
                  if (~isnan(buffers(idForCy(idTech2), (idS-1)*7+7)))
                     for idP = 0:5
                        if (~isnan(buffers(idForCy(idTech2), (idS-1)*7+7 + idP+1)))
                           expected = buffers(idForCy(idTech2), (idS-1)*7+7 + idP+1);
                           received = sum(buffers(idForCy(idNoTech), (idS-1)*7+7 + idP+1), "omitnan");
                           if (received < expected)
                              fprintf('   -> Sensor #%d Phase #%d: %d meas. missing\n', ...
                                 idS, idP, ...
                                 expected - received);
                           elseif (received > expected)
                              fprintf('   -> Sensor #%d Phase #%d: %d meas. not expected\n', ...
                                 idS, idP, ...
                                 received - expected);
                           end
                        end
                     end
                  end
               end
            end
         elseif (~isempty(idTech1) && (length(idForCy) == 1))
            okFlag = 1;
            fprintf('COMPLETED (TECH #1 message only)\n');
         elseif ((length(unique(buffers(idForCy, 6))) == 1) && (unique(buffers(idForCy, 6)) == 13))
            okFlag = 1;
            fprintf('COMPLETED (EOL messages only)\n');
         else
            okFlag = 0;
            fprintf('UNCOMPLETED\n');
            fprintf('   -> TECH #2 is missiong\n');
         end
      else
         % no constraint yet
         fprintf('COMPLETED\n');
      end
      buffers(idForCy, 4) = okFlag;
      buffers(idForCy, 5) = any(ismember(buffers(idForCy, 6), 20:24));
      buffers(idForCy, 2) = rank;
      rank = rank + 1;
   else
      fprintf('BUFF_INFO: Float #%d Cycle #%3d : - NO DATA\n', ...
         g_decArgo_floatNum, cyNum);
   end
end
fprintf('\n');

o_floatbuffers = buffers;

if (~isempty(g_decArgo_outputCsvFileId))

   % CSV output
   csvFilepathName = [g_decArgo_dirOutputCsvFile '\' num2str(g_decArgo_floatNum) '_buffers_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
   fId = fopen(csvFilepathName, 'wt');
   if (fId ~= -1)

      header = '#;Rank;CyNum;Completed;Deep cycle;Data type;File name;Data size;S1 DescPark;S1 DriftPark;S1 DescProf;S1 DriftProf;S1 Asc;S1 InAir;S2 DescPark;S2 DriftPark;S2 DescProf;S2 DriftProf;S2 Asc;S2 InAir;S3 DescPark;S3 DriftPark;S3 DescProf;S3 DriftProf;S3 Asc;S3 InAir';
      fprintf(fId, '%s\n', header);

      prevRank = nan;
      for idL = 1:size(o_floatbuffers, 1)
         if ((idL > 1) && (prevRank ~= o_floatbuffers(idL, 2)))
            fprintf(fId, '-1\n');
         end

         dataSize = '';
         if (ismember(o_floatbuffers(idL, 6), 20:25))
            dataSize = num2str(size(a_floatData{o_floatbuffers(idL, 1), 7}, 1));
         end

         expectNb = o_floatbuffers(idL, [8:13 15:20 22:27]);
         expectNbStr = repmat({''}, size(expectNb));
         for id = 1:length(expectNb)
            if (~isnan(expectNb(id)))
               expectNbStr{id} = num2str(expectNb(id));
            end
         end

         fprintf(fId, '%d;%d;%d;%d;%d;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s\n', ...
            idL, ...
            o_floatbuffers(idL, 2:5), ...
            get_type_str(o_floatbuffers(idL, 6)), ...
            a_floatData{o_floatbuffers(idL, 1), 4}, ...
            dataSize , ...
            expectNbStr{:} ...
            );

         prevRank = o_floatbuffers(idL, 2);
      end

      fclose(fId);
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve the description of a data type code.
%
% SYNTAX :
% [o_dataTypeStr] = get_type_str(a_dataType)
%
% INPUT PARAMETERS :
%   a_dataType  : data type number
%
% OUTPUT PARAMETERS :
%   o_dataTypeStr : data type description
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/23/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataTypeStr] = get_type_str(a_dataType)

switch (a_dataType)
   case -1
      o_dataTypeStr = 'Ignored';
   case 10
      o_dataTypeStr = 'Self test';
   case 11
      o_dataTypeStr = 'Tech #1';
   case 12
      o_dataTypeStr = 'Tech #2';
   case 13
      o_dataTypeStr = 'Eol';
   case 20
      o_dataTypeStr = 'Desc park';
   case 21
      o_dataTypeStr = 'Park drift';
   case 22
      o_dataTypeStr = 'Desc prof';
   case 23
      o_dataTypeStr = 'Prof drift';
   case 24
      o_dataTypeStr = 'Asc';
   case 25
      o_dataTypeStr = 'In air';
   case 30
      o_dataTypeStr = 'Config';
   case 40
      o_dataTypeStr = 'Cmd';

   otherwise
      fprintf('WARNING: Data packet type #%d\n', ...
         a_dataType);
      o_dataTypeStr = '';
end

return