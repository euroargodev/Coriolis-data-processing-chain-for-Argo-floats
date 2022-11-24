% ------------------------------------------------------------------------------
% Print payload sensor data in output CSV file.
%
% SYNTAX :
%  print_payload_data_in_csv_file_ir_rudics_cts5(a_payloadData)
%
% INPUT PARAMETERS :
%   a_payloadData : payload sensor data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function print_payload_data_in_csv_file_ir_rudics_cts5(a_payloadData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloatStr;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_payloadData))
   return;
end

tabDataFormat = {';%g' ';%d'};

fileTypeStr = 'Data_payload';

% level #1
idLev1Begin = find(([a_payloadData{:, 1}] == 1) & ...
   ([a_payloadData{:, 3}] == 'B'));

% sort output data (ENVIRONMENT, SENSOR_X and LOG)
idLev1BeginSort = [];
idF = find(strcmp(a_payloadData(idLev1Begin, 2), 'ENVIRONMENT'));
if (~isempty(idF))
   idLev1BeginSort = idLev1Begin(idF);
end
idF = find(strncmp(a_payloadData(idLev1Begin, 2), 'SENSOR_', length('SENSOR_')) & ...
   ~strcmp(a_payloadData(idLev1Begin, 2), 'SENSOR_ACT')); % to manage float anomaly (ex: 2ee3_020_01_payload.bin)
if (~isempty(idF))
   idF = idLev1Begin(idF);
   [~, idSort] = sort(a_payloadData(idF, 2));
   idLev1BeginSort = [idLev1BeginSort, idF(idSort)];
end
idF = find(strcmp(a_payloadData(idLev1Begin, 2), 'LOG'));
if (~isempty(idF))
   idLev1BeginSort = [idLev1BeginSort, idLev1Begin(idF)];
end

for idLev1B = 1:length(idLev1BeginSort)
   idLev1Start = idLev1BeginSort(idLev1B);
   if (strcmp(a_payloadData{idLev1Start, 2}, 'ENVIRONMENT'))
      lev1Name = a_payloadData{idLev1Start, 2};
      logFlag = 0;
      sensorFlag = 0;
   elseif (strcmp(a_payloadData{idLev1Start, 2}, 'LOG'))
      lev1Name = a_payloadData{idLev1Start, 2};
      logFlag = 1;
      sensorFlag = 1;
   elseif (strncmp(a_payloadData{idLev1Start, 2}, 'SENSOR', length('SENSOR')))
      lev1Name = a_payloadData{idLev1Start, 2};
      logFlag = 0;
      sensorFlag = 1;
   else
      fprintf('ERROR: Inconsistent payload data\n');
   end
   idLev1End = find(strcmp(a_payloadData(:, 2), a_payloadData{idLev1Start, 2}) & ...
      ([a_payloadData{:, 3}] == 'E')');
   if (~isempty(idLev1End))
      idStop = find(idLev1End > idLev1Start);
      if (~isempty(idStop))
         idLev1Stop = idLev1End(idStop(1));
         
         % print a line for the lev1 TAG if there is associated data
         attLev1 = a_payloadData{idLev1Start, 4};
         dataLev1 = a_payloadData{idLev1Start, 5};
         if (~isempty(attLev1) || ~isempty(dataLev1))
            if (~logFlag)
               fprintf(g_decArgo_outputCsvFileId, '%d;%s;%s;%s;%s;;;%s', ...
                  g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                  fileTypeStr, lev1Name, dataLev1);
               for idP = 1:length(attLev1)/2
                  if (ischar(attLev1{idP*2}))
                     info = sprintf('%s:%s', attLev1{idP*2-1:idP*2});
                  else
                     info = sprintf('%s:%g', attLev1{idP*2-1:idP*2});
                  end
                  fprintf(g_decArgo_outputCsvFileId, ';%s', info);
               end
               fprintf(g_decArgo_outputCsvFileId, '\n');
            else
               fprintf(g_decArgo_outputCsvFileId, '%d;%s;%s;%s;%s;;;NOT DECODED\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                  fileTypeStr, lev1Name);
            end
         end
         
         % level #2
         listLev1Id = idLev1Start+1:idLev1Stop-1;
         if (length(listLev1Id) > 2)
            idLev2Begin = find(([a_payloadData{listLev1Id, 1}] == 2) & ...
               ([a_payloadData{listLev1Id, 3}] == 'B'));
            idLev2Begin = listLev1Id(idLev2Begin);
            for idLev2B = 1:length(idLev2Begin)
               idLev2Start = idLev2Begin(idLev2B);
               idLev2End = find(strcmp(a_payloadData(:, 2), a_payloadData{idLev2Start, 2}) & ...
                  ([a_payloadData{:, 3}] == 'E')');
               if (~isempty(idLev2End))
                  idStop = find(idLev2End > idLev2Start);
                  if (~isempty(idStop))
                     idLev2Stop = idLev2End(idStop(1));
                     
                     % print a line for the lev2 TAG if there is associated data
                     attLev2 = a_payloadData{idLev2Start, 4};
                     dataLev2 = a_payloadData{idLev2Start, 5};
                     if (~isempty(attLev2) || ~isempty(dataLev2))
                        if (~sensorFlag)
                           fprintf(g_decArgo_outputCsvFileId, '%d;%s;%s;%s;%s;%s;;%s', ...
                              g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                              fileTypeStr, lev1Name, a_payloadData{idLev2Start, 2}, dataLev2);
                           for idP = 1:length(attLev2)/2
                              if (ischar(attLev2{idP*2}))
                                 info = sprintf('%s:%s', attLev2{idP*2-1:idP*2});
                              else
                                 info = sprintf('%s:%g', attLev2{idP*2-1:idP*2});
                              end
                              fprintf(g_decArgo_outputCsvFileId, ';%s', info);
                           end
                           fprintf(g_decArgo_outputCsvFileId, '\n');
                        else
                           sensorInfo = a_payloadData{idLev2Start, 2};
                           idF = strfind(sensorInfo, '-');
                           sensorName = sensorInfo(1:idF(1)-1);
                           if (strcmp(sensorName, 'PSA'))
                              sensorName = sensorInfo(1:idF(2)-1);
                           end
                           phaseName = sensorInfo(idF(end)+1:end);
                           switch phaseName
                              case 'PRE'
                                 phaseName = 'PREDESCENT';
                              case 'DES'
                                 phaseName = 'DESCENT';
                              case 'PAR'
                                 phaseName = 'PARK';
                              case 'DEE'
                                 phaseName = 'DEEP_PROFILE';
                              case 'SHO'
                                 phaseName = 'SHORT_PARK';
                              case 'ASC'
                                 phaseName = 'ASCENT';
                              case 'SUR'
                                 phaseName = 'SURFACE';
                              case 'RAW'
                                 phaseName = 'RAW';
                           end
                           fprintf(g_decArgo_outputCsvFileId, '%d;%s;%s;%s;%s;%s;%s;%s;%s', ...
                              g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                              fileTypeStr, phaseName, lev1Name, sensorName, a_payloadData{idLev2Start, 2}, dataLev2);
                           for idP = 1:length(attLev2)/2
                              if (ischar(attLev2{idP*2}))
                                 info = sprintf('%s:%s', attLev2{idP*2-1:idP*2});
                              else
                                 info = sprintf('%s:%g', attLev2{idP*2-1:idP*2});
                              end
                              fprintf(g_decArgo_outputCsvFileId, ';%s', info);
                           end
                           fprintf(g_decArgo_outputCsvFileId, '\n');
                        end
                     end
                     
                     % level #3
                     listLev2Id = idLev2Start+1:idLev2Stop-1;
                     if (length(listLev2Id) > 2)
                        idLev3Begin = find(([a_payloadData{listLev2Id, 1}] == 3) & ...
                           ([a_payloadData{listLev2Id, 3}] == 'B'));
                        idLev3Begin = listLev2Id(idLev3Begin);
                        for idLev3B = 1:length(idLev3Begin)
                           idLev3Start = idLev3Begin(idLev3B);
                           idLev3End = find(strcmp(a_payloadData(:, 2), a_payloadData{idLev3Start, 2}) & ...
                              ([a_payloadData{:, 3}] == 'E')');
                           if (~isempty(idLev3End))
                              idStop = find(idLev3End > idLev3Start);
                              if (~isempty(idStop))
                                 idLev3Stop = idLev3End(idStop(1));
                                 
                                 % print a line for the lev3 TAG if there is associated data
                                 attLev3 = a_payloadData{idLev3Start, 4};
                                 dataLev3 = a_payloadData{idLev3Start, 5};
                                 if (~isempty(attLev3) || ~isempty(dataLev3))
                                    if (~sensorFlag)
                                       fprintf(g_decArgo_outputCsvFileId, '%d;%s;%s;%s;%s;%s;%s;%s', ...
                                          g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                                          fileTypeStr, lev1Name, a_payloadData{idLev2Start, 2}, a_payloadData{idLev3Start, 2}, dataLev3);
                                       for idP = 1:length(attLev3)/2
                                          if (ischar(attLev3{idP*2}))
                                             info = sprintf('%s:%s', attLev3{idP*2-1:idP*2});
                                          else
                                             info = sprintf('%s:%g', attLev3{idP*2-1:idP*2});
                                          end
                                          fprintf(g_decArgo_outputCsvFileId, ';%s', info);
                                       end
                                       fprintf(g_decArgo_outputCsvFileId, '\n');
                                    else
                                       if (~strcmp(a_payloadData{idLev3Start, 2}, 'CDATA'))
                                          fprintf(g_decArgo_outputCsvFileId, '%d;%s;%s;%s;%s;%s;%s;%s;%s', ...
                                             g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                                             fileTypeStr, phaseName, lev1Name, sensorName, a_payloadData{idLev3Start, 2}, dataLev3);
                                          for idP = 1:length(attLev3)/2
                                             if (ischar(attLev3{idP*2}))
                                                info = sprintf('%s:%s', attLev3{idP*2-1:idP*2});
                                             else
                                                info = sprintf('%s:%g', attLev3{idP*2-1:idP*2});
                                             end
                                             fprintf(g_decArgo_outputCsvFileId, ';%s', info);
                                          end
                                          fprintf(g_decArgo_outputCsvFileId, '\n');
                                       else
                                          fprintf(g_decArgo_outputCsvFileId, '%d;%s;%s;%s;%s;%s;%s;Parameters', ...
                                             g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                                             fileTypeStr, phaseName, lev1Name, sensorName);
                                          fprintf(g_decArgo_outputCsvFileId, ';%s', dataLev3{1}{:});
                                          fprintf(g_decArgo_outputCsvFileId, '\n');
                                          dataValue = dataLev3{2}{:};
                                          for idL = 1:size(dataValue, 1)
                                             fprintf(g_decArgo_outputCsvFileId, '%d;%s;%s;%s;%s;%s;%s;Values', ...
                                                g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                                                fileTypeStr, phaseName, lev1Name, sensorName);
                                             fmt = [tabDataFormat{([dataValue(idL, :)-fix(dataValue(idL, :))] == 0)+1}];
                                             fprintf(g_decArgo_outputCsvFileId, fmt, dataValue(idL, :));
                                             fprintf(g_decArgo_outputCsvFileId, '\n');
                                          end
                                       end
                                    end
                                 end
                              else
                                 fprintf('ERROR: Inconsistent payload data\n');
                              end
                           else
                              fprintf('ERROR: Inconsistent payload data\n');
                           end
                        end
                     end
                  else
                     fprintf('ERROR: Inconsistent payload data\n');
                  end
               else
                  fprintf('ERROR: Inconsistent payload data\n');
               end
            end
         end
      else
         fprintf('ERROR: Inconsistent payload data\n');
      end
   end
end

return;
