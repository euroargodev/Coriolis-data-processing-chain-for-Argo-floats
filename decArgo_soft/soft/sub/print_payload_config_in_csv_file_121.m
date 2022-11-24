% ------------------------------------------------------------------------------
% Print payload configuration data in output CSV file.
%
% SYNTAX :
%  print_payload_config_in_csv_file_121(a_configData)
%
% INPUT PARAMETERS :
%   a_configData : payload configuration data
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
function print_payload_config_in_csv_file_121(a_configData)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% current cycle and pattern number
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloatStr;


if (isempty(a_configData))
   return;
end


tag1ExpectedList = [ ...
   {'SENSOR_ACT'} ... % not in the manual
   {'PREDESCENT'} ...
   {'DESCENT'} ...
   {'PARK'} ...
   {'DEEPPROFILE'} ...
   {'SHORTPARK'} ...
   {'CYCLEPARK'} ... % not in the manual
   {'ASCENT'} ...
   {'SURFACE'} ...
   ];

tag2ExpectedList = [ ...
   {'UP'} ...
   {'PREQ'} ...
   {'ACQUISITION'} ...
   {'POWEROFF'} ...
   {'ISA'} ...
   {'AID'} ...
   {'AC1'} ... % not in the manual
   {'STOP_AUTO_OFF'} ... % not in the manual
   ];

tag3ExpectedList = [ ...
   {'SENSOR'} ...
   {'SUBSAMPLING'} ...
   {'SPR_INHIB'} ...
   {'ISA_DEPTH'} ...
   {'TC'} ...
   {'ACTIF'} ...
   {'MSG'} ...
   {'NEXT_MEASURE'} ...
   {'PARAMS'} ...
   ];

% check consistency with expected data
tagExpectedList = [];
tagExpectedList{end+1} = tag1ExpectedList;
tagExpectedList{end+1} = tag2ExpectedList;
tagExpectedList{end+1} = tag3ExpectedList;
for idLev = 1:3
   tagList = unique(a_configData(find([a_configData{:, 1}] == idLev), 2));
   koList = setdiff(tagList, tagExpectedList{idLev});
   for idT = 1:length(koList)
      fprintf('ERROR: Not expected level #%d TAG: %s\n', idLev, koList{idT});
   end
end


fileTypeStr = 'Config_PAYLOAD';

% level #1
lev1ListId = find([a_configData{:, 1}] == 1);
for idPhase = 1:length(tag1ExpectedList)
   idPhaseBegin = find(strcmp(a_configData(lev1ListId, 2), tag1ExpectedList{idPhase}) & ...
      ([a_configData{lev1ListId, 3}] == 'B')');
   idPhaseBegin = lev1ListId(idPhaseBegin);
   for idPhaseNum = 1:length(idPhaseBegin)
      phaseName = [tag1ExpectedList{idPhase} '_' num2str(idPhaseNum)];
      idPhaseStart = idPhaseBegin(idPhaseNum);
      idPhaseEnd = find(strcmp(a_configData(lev1ListId, 2), tag1ExpectedList{idPhase}) & ...
         ([a_configData{lev1ListId, 3}] == 'E')');
      idPhaseEnd = lev1ListId(idPhaseEnd);
      if (~isempty(idPhaseEnd))
         idStop = find(idPhaseEnd > idPhaseStart);
         if (~isempty(idStop))
            idPhaseStop = idPhaseEnd(idStop(1));
            
            % print a line for the phase if there is associated data
            dataPhase = a_configData{idPhaseStart, 4};
            if (~isempty(dataPhase))
               fprintf(g_decArgo_outputCsvFileId, '%d;%s;%s;%s;%s;;', ...
                  g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                  fileTypeStr, phaseName);
               for idP = 1:length(dataPhase)/2
                  if (ischar(dataPhase{idP*2}))
                     info = sprintf('%s:%s', dataPhase{idP*2-1:idP*2});
                  else
                     info = sprintf('%s:%g', dataPhase{idP*2-1:idP*2});
                  end
                  fprintf(g_decArgo_outputCsvFileId, ';%s', info);
               end
               fprintf(g_decArgo_outputCsvFileId, '\n');
            end
            
            % level #2
            listPhaseId = idPhaseStart:idPhaseStop;
            if (length(listPhaseId) > 2)
               lev2ListId = find([a_configData{listPhaseId, 1}] == 2);
               lev2ListId = listPhaseId(lev2ListId);
               for idAction = 1:length(tag2ExpectedList)
                  idActionBegin = find(strcmp(a_configData(lev2ListId, 2), tag2ExpectedList{idAction}) & ...
                     ([a_configData{lev2ListId, 3}] == 'B')');
                  idActionBegin = lev2ListId(idActionBegin);
                  for idActionNum = 1:length(idActionBegin)
                     actionName = [tag2ExpectedList{idAction} '_' num2str(idActionNum)];
                     idActionStart = idActionBegin(idActionNum);
                     idActionEnd = find(strcmp(a_configData(lev2ListId, 2), tag2ExpectedList{idAction}) & ...
                        ([a_configData{lev2ListId, 3}] == 'E')');
                     idActionEnd = lev2ListId(idActionEnd);
                     if (~isempty(idActionEnd))
                        idStop = find(idActionEnd > idActionStart);
                        if (~isempty(idStop))
                           idActionStop = idActionEnd(idStop(1));
                           
                           % print a line for the action
                           dataAction = a_configData{idActionStart, 4};
                           if (isempty(dataAction))
                              fprintf(g_decArgo_outputCsvFileId, '%d;%s;%s;%s;%s;%s\n', ...
                                 g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                                 fileTypeStr, phaseName, actionName);
                           else
                              fprintf(g_decArgo_outputCsvFileId, '%d;%s;%s;%s;%s;%s;', ...
                                 g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                                 fileTypeStr, phaseName, actionName);

                              for idA = 1:length(dataAction)/2
                                 if (ischar(dataAction{idA*2}))
                                    info = sprintf('%s:%s', dataAction{idA*2-1:idA*2});
                                 else
                                    info = sprintf('%s:%g', dataAction{idA*2-1:idA*2});
                                 end
                                 fprintf(g_decArgo_outputCsvFileId, ';%s', info);
                              end
                              fprintf(g_decArgo_outputCsvFileId, '\n');
                           end
                           
                           % level #3
                           listActionId = idActionStart+1:idActionStop-1;
                           if (~isempty(listActionId))
                              lev3ListId = find([a_configData{listActionId, 1}] == 3);
                              lev3ListId = listActionId(lev3ListId);
                              for idMisc = 1:length(tag3ExpectedList)
                                 idMiscBegin = find(strcmp(a_configData(lev3ListId, 2), tag3ExpectedList{idMisc}) & ...
                                    ([a_configData{lev3ListId, 3}] == 'B')');
                                 idMiscBegin = lev3ListId(idMiscBegin);
                                 for idMiscNum = 1:length(idMiscBegin)
                                    miscName = [tag3ExpectedList{idMisc} '_' num2str(idMiscNum)];
                                    idMiscStart = idMiscBegin(idMiscNum);
                                    idMiscEnd = find(strcmp(a_configData(lev3ListId, 2), tag3ExpectedList{idMisc}) & ...
                                       ([a_configData{lev3ListId, 3}] == 'E')');
                                    idMiscEnd = lev3ListId(idMiscEnd);
                                    if (~isempty(idMiscEnd))
                                       
                                       idStop = find(idMiscEnd > idMiscStart);
                                       if (~isempty(idStop))
                                          idMiscStop = idMiscEnd(idStop(1));
                                          
                                          % print a line for the misc
                                          dataMisc = a_configData{idMiscStart, 4};
                                          if (isempty(dataMisc))
                                             fprintf(g_decArgo_outputCsvFileId, '%d;%s;%s;%s;%s;%s;%s\n', ...
                                                g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                                                fileTypeStr, phaseName, actionName, miscName);
                                          else
                                             fprintf(g_decArgo_outputCsvFileId, '%d;%s;%s;%s;%s;%s;%s', ...
                                                g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                                                fileTypeStr, phaseName, actionName, miscName);
                                             for idM = 1:length(dataMisc)/2
                                                if (ischar(dataMisc{idM*2}))
                                                   info = sprintf('%s:%s', dataMisc{idM*2-1:idM*2});
                                                else
                                                   info = sprintf('%s:%g', dataMisc{idM*2-1:idM*2});
                                                end
                                                fprintf(g_decArgo_outputCsvFileId, ';%s', info);
                                             end
                                             fprintf(g_decArgo_outputCsvFileId, '\n');
                                          end
                                       else
                                          fprintf('ERROR: Inconsistent payload configuration\n');
                                       end
                                    else
                                       fprintf('ERROR: Inconsistent payload configuration\n');
                                    end
                                 end
                              end
                           end
                        else
                           fprintf('ERROR: Inconsistent payload configuration\n');
                        end
                     else
                        fprintf('ERROR: Inconsistent payload configuration\n');
                     end
                  end
               end
            end
         else
            fprintf('ERROR: Inconsistent payload configuration\n');
         end
      else
         fprintf('ERROR: Inconsistent payload configuration\n');
      end
   end
end

return;
