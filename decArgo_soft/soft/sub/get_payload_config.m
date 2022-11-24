% ------------------------------------------------------------------------------
% Decode payload configuration file.
%
% SYNTAX :
%  [o_configNames, o_configValues] = get_payload_config(a_inputFilePathName)
%
% INPUT PARAMETERS :
%   a_inputFilePathName : payload configuration file path name
%
% OUTPUT PARAMETERS :
%   o_configNames  : decoded configuration names
%   o_configValues : decoded configuration values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configNames, o_configValues] = get_payload_config(a_inputFilePathName)

% output parameters initialization
o_configNames = [];
o_configValues = [];


if ~(exist(a_inputFilePathName, 'file') == 2)
   fprintf('ERROR: get_payload_config: File not found: %s\n', a_inputFilePathName);
   return;
end

% read payload configuration file
payloadConfig = read_payload_config(a_inputFilePathName);

% format payload config data
[o_configNames, o_configValues] = format_payload_config(payloadConfig);

return;

% ------------------------------------------------------------------------------
% Format payload configuration data.
%
% SYNTAX :
%  [o_configNames, o_configValues] = format_payload_config(a_configData)
%
% INPUT PARAMETERS :
%   a_configData : payload configuration data
%
% OUTPUT PARAMETERS :
%   o_configNames  : formated configuration names
%   o_configValues : formated configuration values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configNames, o_configValues] = format_payload_config(a_configData)

% output parameters initialization
o_configNames = [];
o_configValues = [];


phaseList = [ ...
   {'PREDESCENT'} ...
   {'DESCENT'} ...
   {'PARK'} ...
   {'DEEPPROFILE'} ...
   {'SHORTPARK'} ...
   {'ASCENT'} ...
   {'SURFACE'} ...
   ];

actionList = [ ...
   {'ACQUISITION'} ...
   {'ISA'} ...
   {'AID'} ...
   {'AC1'} ...
   ];

tag3ExpectedList = [ ...
   {'SENSOR'} ...
   {'SUBSAMPLING'} ...
   {'SPR_INHIB'} ...
   {'ISA_DEPTH'} ...
   {'TC'} ...
   {'ACTIF'} ...
   {'NEXT_MEASURE'} ...
   {'PARAMS'} ...
   ];

powerAcqModeList = [ ...
   {'CONTINUOUS'} ...
   {'ON_DEMAND'} ...
   {'ONE_SHOT'} ...
   ];

subsamplingList = [ ...
   {'MEAN'} ...
   {'MEDIAN'} ...
   {'MIN'} ...
   {'MAX'} ...
   {'STDDEV'} ...
   ];

% collect acquisiton information

% level #1
dataAcq = [];
dataIsa = [];
dataAid = [];
dataAc1 = [];
lev1ListId = find([a_configData{:, 1}] == 1);
for idPhase = 1:length(phaseList)
   idPhaseBegin = find(strcmp(a_configData(lev1ListId, 2), phaseList{idPhase}) & ...
      ([a_configData{lev1ListId, 3}] == 'B')');
   idPhaseBegin = lev1ListId(idPhaseBegin);
   for idPhaseNum = 1:length(idPhaseBegin)
      idPhaseStart = idPhaseBegin(idPhaseNum);
      idPhaseEnd = find(strcmp(a_configData(lev1ListId, 2), phaseList{idPhase}) & ...
         ([a_configData{lev1ListId, 3}] == 'E')');
      idPhaseEnd = lev1ListId(idPhaseEnd);
      if (~isempty(idPhaseEnd))
         idStop = find(idPhaseEnd > idPhaseStart);
         if (~isempty(idStop))
            idPhaseStop = idPhaseEnd(idStop(1));
                        
            % level #2
            listPhaseId = idPhaseStart:idPhaseStop;
            if (length(listPhaseId) > 2)
               lev2ListId = find([a_configData{listPhaseId, 1}] == 2);
               lev2ListId = listPhaseId(lev2ListId);
               for idAction = 1:length(actionList)
                  idActionBegin = find(strcmp(a_configData(lev2ListId, 2), actionList{idAction}) & ...
                     ([a_configData{lev2ListId, 3}] == 'B')');
                  idActionBegin = lev2ListId(idActionBegin);
                  for idActionNum = 1:length(idActionBegin)
                     idActionStart = idActionBegin(idActionNum);
                     idActionEnd = find(strcmp(a_configData(lev2ListId, 2), actionList{idAction}) & ...
                        ([a_configData{lev2ListId, 3}] == 'E')');
                     idActionEnd = lev2ListId(idActionEnd);
                     if (~isempty(idActionEnd))
                        idStop = find(idActionEnd > idActionStart);
                        if (~isempty(idStop))
                           idActionStop = idActionEnd(idStop(1));
                           
                           % create a new action
                           dataAction = a_configData{idActionStart, 4};
                           if (~isempty(dataAction))
                              newAction = [];
                              newAction.PHASE = idPhase;
                              newAction.PHASE_NUM = idPhaseNum;
                              newAction.ACTION_NUM = idActionNum;
                              for idA = 1:length(dataAction)/2
                                 newAction.(dataAction{idA*2-1}) = dataAction{idA*2};
                              end
                           else
                              fprintf('ERROR: Inconsistent payload configuration\n');
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
                                    miscName = tag3ExpectedList{idMisc};
                                    idMiscStart = idMiscBegin(idMiscNum);
                                    idMiscEnd = find(strcmp(a_configData(lev3ListId, 2), tag3ExpectedList{idMisc}) & ...
                                       ([a_configData{lev3ListId, 3}] == 'E')');
                                    idMiscEnd = lev3ListId(idMiscEnd);
                                    if (~isempty(idMiscEnd))
                                       
                                       idStop = find(idMiscEnd > idMiscStart);
                                       if (~isempty(idStop))
                                          
                                          % set new acquisition parameters
                                          dataMisc = a_configData{idMiscStart, 4};
                                          if (~isempty(dataMisc))
                                             for idM = 1:length(dataMisc)/2
                                                newAction.(miscName).(dataMisc{idM*2-1}) = dataMisc{idM*2};
                                             end
                                          else
                                             fprintf('ERROR: Inconsistent payload configuration\n');
                                          end
                                       else
                                          fprintf('ERROR: Inconsistent payload configuration\n');
                                       end
                                    else
                                       fprintf('ERROR: Inconsistent payload configuration\n');
                                    end
                                 end
                              end
                              
                              % store new action
                              if (strcmp(actionList{idAction}, 'ACQUISITION'))
                                 dataAcq{end+1} = newAction;
                              elseif (strcmp(actionList{idAction}, 'ISA'))
                                 dataIsa{end+1} = newAction;
                              elseif (strcmp(actionList{idAction}, 'AID'))
                                 dataAid{end+1} = newAction;
                              elseif (strcmp(actionList{idAction}, 'AC1'))
                                 dataAc1{end+1} = newAction;
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

% store acquisition information
configNames = [];
configValues = [];
infoAcq = [];
horizontalPhaseList = [3 5 7];
verticalPhaseList = [1 2 4 6];
for idAcq = 1:length(dataAcq)
   acqData = dataAcq{idAcq};
   if (ismember(acqData.PHASE, horizontalPhaseList))
      phaseAcronym = 'HP';
   elseif (ismember(acqData.PHASE, verticalPhaseList))
      phaseAcronym = 'VP';
   end
   sensorNum = acqData.SENSOR.id;
   configNamePrefix = sprintf('CONFIG_PAYLOAD_SENSOR_%02d_', sensorNum);
   infoAcq = [infoAcq; [sensorNum acqData.PHASE acqData.PHASE_NUM]];
   
   % number of depth zone
   configName = [configNamePrefix 'P00_' sprintf('%s%02d_%d', phaseAcronym, acqData.PHASE, acqData.PHASE_NUM)];
   idF = find(strcmp(configName, configNames), 1);
   if (isempty(idF))
      configNames{end+1} = configName;
      configValues(end+1) = 1;
      depthZoneNum = 1;
      idF = length(configValues);
   else
      configValues(idF) = configValues(idF) + 1;
      depthZoneNum = configValues(idF);
   end
   
   % start pressure to define the depth zone
   configName = [configNamePrefix 'P01_' sprintf('%s%02d_%d_%d', phaseAcronym, acqData.PHASE, acqData.PHASE_NUM, depthZoneNum)];
   configNames{end+1} = configName;
   configValues(end+1) = acqData.trig/100;
   
   % stop pressure to define the depth zone
   configName = [configNamePrefix 'P02_' sprintf('%s%02d_%d_%d', phaseAcronym, acqData.PHASE, acqData.PHASE_NUM, depthZoneNum)];
   configNames{end+1} = configName;
   configValues(end+1) = acqData.stop/100;
   
   % sampling period for the depth zone
   configName = [configNamePrefix 'P03_' sprintf('%s%02d_%d_%d', phaseAcronym, acqData.PHASE, acqData.PHASE_NUM, depthZoneNum)];
   configNames{end+1} = configName;
   if (isfield(acqData, 'period'))
      configValues(end+1) = acqData.period/100;
   else
      configValues(end+1) = nan;
   end
   
   % power acquisition mode for the depth zone
   configName = [configNamePrefix 'P04_' sprintf('%s%02d_%d_%d', phaseAcronym, acqData.PHASE, acqData.PHASE_NUM, depthZoneNum)];
   configNames{end+1} = configName;
   configValues(end+1) = find(strcmp(acqData.type, powerAcqModeList), 1);
   
   % number of additional raw data sampled in the depth zone
   configName = [configNamePrefix 'P05_' sprintf('%s%02d_%d_%d', phaseAcronym, acqData.PHASE, acqData.PHASE_NUM, depthZoneNum)];
   configNames{end+1} = configName;
   if (~isfield(acqData, 'raw'))
      configValues(end+1) = 0;
   else
      configValues(end+1) = acqData.raw;
   end
   
   % number of subsamplings for data sampled in the depth zone
   configName = [configNamePrefix 'P06_' sprintf('%s%02d_%d_%d', phaseAcronym, acqData.PHASE, acqData.PHASE_NUM, depthZoneNum)];
   idF = find(strcmp(configName, configNames), 1);
   if (isempty(idF))
      configNames{end+1} = configName;
      if (~isfield(acqData, 'SUBSAMPLING'))
         configValues(end+1) = 0;
      else
         configValues(end+1) = 1;
         
         % data processing mode of the concerned subsampling
         configName = [configNamePrefix 'P07_' sprintf('%s%02d_%d_%d_1', phaseAcronym, acqData.PHASE, acqData.PHASE_NUM, depthZoneNum)];
         configNames{end+1} = configName;
         configValues(end+1) = find(strcmp(acqData.SUBSAMPLING.id, subsamplingList), 1);
         
         % data processing rate of the concerned subsampling
         configName = [configNamePrefix 'P08_' sprintf('%s%02d_%d_%d_1', phaseAcronym, acqData.PHASE, acqData.PHASE_NUM, depthZoneNum)];
         configNames{end+1} = configName;
         configValues(end+1) = acqData.SUBSAMPLING.rate;
      end
   else
      configValues(idF) = configValues(idF) + 1;
      subsamplingNum = configValues(idF);
      
      % data processing mode of the concerned subsampling
      configName = [configNamePrefix 'P07_' sprintf('%s%02d_%d_%d_%d', phaseAcronym, acqData.PHASE, acqData.PHASE_NUM, depthZoneNum, subsamplingNum)];
      configNames{end+1} = configName;
      configValues(end+1) = find(strcmp(acqData.SUBSAMPLING.id, subsamplingList), 1);
      
      % data processing rate of the concerned subsampling
      configName = [configNamePrefix 'P08_' sprintf('%s%02d_%d_%d_%d', phaseAcronym, acqData.PHASE, acqData.PHASE_NUM, depthZoneNum, subsamplingNum)];
      configNames{end+1} = configName;
      configValues(end+1) = acqData.SUBSAMPLING.rate;
   end
end

% count number of phases of each type
infoAcq = unique(infoAcq, 'rows');
sensorPhase = unique(infoAcq(:, 1:2), 'rows');
for idSP = 1:size(sensorPhase, 1)
   sensorNum = sensorPhase(idSP, 1);
   phase = sensorPhase(idSP, 2);
   if (ismember(phase, horizontalPhaseList))
      phaseAcronym = 'HP';
   elseif (ismember(phase, verticalPhaseList))
      phaseAcronym = 'VP';
   end
   idF = find((infoAcq(:, 1) == sensorNum) & (infoAcq(:, 2) == phase));
   
   % number of such vertical phases
   configNamePrefix = sprintf('CONFIG_PAYLOAD_SENSOR_%02d_', sensorNum);
   configName = [configNamePrefix 'P09_' sprintf('%s%02d', phaseAcronym, phase)];
   configNames{end+1} = configName;
   configValues(end+1) = length(idF);
end

% sort acquisition configuration parameters
sensorList = [];
phaseList = [];
phaseNumList = [];
depthZoneList = [];
subSamplingNumList = [];
for idL = 1:length(configNames)
   configName = configNames{idL};
   idFUs = strfind(configName, '_');
   sensorList = [sensorList str2num(configName(idFUs(3)+1:idFUs(4)-1))];
   if (length(idFUs) == 5)
      phaseList = [phaseList str2num(configName(idFUs(5)+3:end))];
   else
      phaseList = [phaseList str2num(configName(idFUs(5)+3:idFUs(6)-1))];
      if (length(idFUs) == 6)
         phaseNumList = [phaseNumList str2num(configName(idFUs(6)+1:end))];
      else
         phaseNumList = [phaseNumList str2num(configName(idFUs(6)+1:idFUs(7)-1))];
         depthZoneList = [depthZoneList str2num(configName(idFUs(7)+1:end))];
      end
   end
   if (any(strfind(configName, 'PAYLOAD_SENSOR_')) && any(strfind(configName, '_P06_')))
      subSamplingNumList = [subSamplingNumList configValues(idL)];
   end
end
maxSubSamplingNum = max(subSamplingNumList);

sensorList = unique(sensorList);
phaseList = unique(phaseList);
phaseNumList = unique(phaseNumList);
depthZoneList = unique(depthZoneList);
for sensorNum = sensorList
   configNamePrefix = sprintf('CONFIG_PAYLOAD_SENSOR_%02d_', sensorNum);
   for phase = phaseList
      if (ismember(phase, horizontalPhaseList))
         phaseAcronym = 'HP';
      elseif (ismember(phase, verticalPhaseList))
         phaseAcronym = 'VP';
      end
      for phaseNum = phaseNumList
         for depthZoneNum = depthZoneList
            for paramNum = [9 0:8]
               if (paramNum == 9)
                  configName = [configNamePrefix sprintf('P%02d_%s%02d', paramNum, phaseAcronym, phase)];
               elseif (paramNum == 0)
                  configName = [configNamePrefix sprintf('P%02d_%s%02d_%d', paramNum, phaseAcronym, phase, phaseNum)];
               elseif (paramNum < 7)
                  configName = [configNamePrefix sprintf('P%02d_%s%02d_%d_%d', paramNum, phaseAcronym, phase, phaseNum, depthZoneNum)];
               else
                  for subSamplingNum = 1:maxSubSamplingNum
                     configName = [configNamePrefix sprintf('P%02d_%s%02d_%d_%d_%d', paramNum, phaseAcronym, phase, phaseNum, depthZoneNum, subSamplingNum)];
                  end
               end
               idF = find(strcmp(configName, configNames), 1);
               if (~isempty(idF))
                  o_configNames{end+1} = configNames{idF};
                  o_configValues(end+1) = configValues(idF);
                  configNames(idF) = [];
                  configValues(idF) = [];
               end
            end
         end
      end
   end
end

% store ISA information
configNames = [];
configValues = [];
for idIsa = 1:length(dataIsa)
   isaData = dataIsa{idIsa};
   configNamePrefix = 'CONFIG_PAYLOAD_ISA_';
   
   % spring inhibition ascend end pressure
   configName = [configNamePrefix 'P00_' sprintf('%d', isaData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = isaData.SPR_INHIB.trig;
   
   % spring inhibition delay since last ISA detection
   configName = [configNamePrefix 'P01_' sprintf('%d', isaData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = isaData.SPR_INHIB.last;
   
   % ISA algorithm storing data start pressure 
   configName = [configNamePrefix 'P02_' sprintf('%d', isaData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = isaData.trig/100;
   
   % ISA algorithm storing data stop pressure 
   configName = [configNamePrefix 'P03_' sprintf('%d', isaData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = isaData.stop/100;
   
   % ISA algorithm storing data sampling period
   configName = [configNamePrefix 'P04_' sprintf('%d', isaData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = isaData.period/100;
   
   % ISA algorithm start pres
   configName = [configNamePrefix 'P05_' sprintf('%d', isaData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = isaData.ISA_DEPTH.p;
   
   % ISA algorithm reference temperature
   configName = [configNamePrefix 'P06_' sprintf('%d', isaData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = isaData.TC.a;
   
   % ISA algorithm salinity coefficient
   configName = [configNamePrefix 'P07_' sprintf('%d', isaData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = isaData.TC.b;
   
   % ISA algorithm applicable month
   configName = [configNamePrefix 'P08_' sprintf('%d', isaData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = bin2dec(regexprep(isaData.ACTIF.month, ',', ''));
end

% count number of ascent phases
nbAscentPhases = max(infoAcq(find(infoAcq(:, 2) == 6), 3));
configNames{end+1} = [configNamePrefix 'P09'];
configValues(end+1) = nbAscentPhases;

o_configNames = cat(2, o_configNames, configNames);
o_configValues = cat(2, o_configValues, configValues);

% store AID information
configNames = [];
configValues = [];
for idAid = 1:length(dataAid)
   aidData = dataAid{idAid};
   configNamePrefix = 'CONFIG_PAYLOAD_AID_';
   
   % AID algorithm start pressure
   configName = [configNamePrefix 'P00_' sprintf('%d', aidData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = aidData.trig/100;
   
   % AID algorithm stop pressure 
   configName = [configNamePrefix 'P01_' sprintf('%d', aidData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = aidData.stop/100;
   
   % AID algorithm sampling period 
   configName = [configNamePrefix 'P02_' sprintf('%d', aidData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = aidData.period/100;
   
   % AID algorithm next measurement reach 
   configName = [configNamePrefix 'P03_' sprintf('%d', aidData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = aidData.NEXT_MEASURE.reach;
   
   % AID algorithm next measurement margin 
   configName = [configNamePrefix 'P04_' sprintf('%d', aidData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = aidData.NEXT_MEASURE.margin;
   
   % AID algorithm number of distance meas 
   configName = [configNamePrefix 'P05_' sprintf('%d', aidData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = aidData.SUBSAMPLING.rate;
   
   % AID algorithm linear correction 
   configName = [configNamePrefix 'P06_' sprintf('%d', aidData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = aidData.PARAMS.corlin;
   
   % AID algorithm dbar to meter coefficien
   configName = [configNamePrefix 'P07_' sprintf('%d', aidData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = aidData.PARAMS.rhog;
   
   % AID algorithm min threshold for valid meas
   configName = [configNamePrefix 'P08_' sprintf('%d', aidData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = aidData.PARAMS.distmax;
   
   % AID algorithm max diff between distance meas
   configName = [configNamePrefix 'P09_' sprintf('%d', aidData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = aidData.PARAMS.deltadistmax;
   
   % AID algorithm min draught
   configName = [configNamePrefix 'P10_' sprintf('%d', aidData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = aidData.PARAMS.temin;
   
   % AID algorithm min number of detections
   configName = [configNamePrefix 'P11_' sprintf('%d', aidData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = aidData.PARAMS.nrep;
   
   % AID algorithm max draught difference for detection
   configName = [configNamePrefix 'P12_' sprintf('%d', aidData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = aidData.PARAMS.deltarep;

   % AID algorithm max distance to target to abort ascent
   configName = [configNamePrefix 'P13_' sprintf('%d', aidData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = aidData.PARAMS.abortdist;
   
   % AID algorithm applicable month
   configName = [configNamePrefix 'P14_' sprintf('%d', aidData.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = bin2dec(regexprep(aidData.ACTIF.month, ',', ''));
end

% add number of ascent phases
configNames{end+1} = [configNamePrefix 'P15'];
configValues(end+1) = nbAscentPhases;

o_configNames = cat(2, o_configNames, configNames);
o_configValues = cat(2, o_configValues, configValues);

% store AC1 information
configNames = [];
configValues = [];
for idAc1 = 1:length(dataAc1)
   ac1Data = dataAc1{idAc1};
   configNamePrefix = 'CONFIG_PAYLOAD_AC1_';
   
   % Pressure to abort ascent
   configName = [configNamePrefix 'P00_' sprintf('%d', ac1Data.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = ac1Data.trig/100;
   
   % Applicable month
   configName = [configNamePrefix 'P01_' sprintf('%d', ac1Data.PHASE_NUM)];
   configNames{end+1} = configName;
   configValues(end+1) = bin2dec(regexprep(ac1Data.ACTIF.month, ',', ''));
end

% add number of ascent phases
configNames{end+1} = [configNamePrefix 'P02'];
configValues(end+1) = nbAscentPhases;

o_configNames = cat(2, o_configNames, configNames);
o_configValues = cat(2, o_configValues, configValues);

% duplicate all payload configuration names from CONFIG_PAYLOAD_xxx to
% CONFIG_PAYLOAD_USED_xxx without the phase number (<i>)
% the associated values are set to nan and will be copied from
% CONFIG_PAYLOAD_xxx when a configuration is assigned to a given (cycle, pattern)
configNames = [];
for idP = 1:length(o_configNames)
   configName = o_configNames{idP};
   idFUs = strfind(configName, '_');
   if (strncmp(configName, 'CONFIG_PAYLOAD_SENSOR_', length('CONFIG_PAYLOAD_SENSOR_')))
      if (length(idFUs) == 5)
         continue; % P09 is not duplicated
      elseif (length(idFUs) == 6)
         configName = configName(1:idFUs(end)-1);
      else
         configName = configName([1:idFUs(6) idFUs(7)+1:end]);
      end
   else
      if (length(idFUs) == 3)
         continue; % number of ascent phases are not duplicated
      else
         configName = configName(1:idFUs(end)-1);
      end
   end
   configNames{end+1} = regexprep(configName, 'CONFIG_PAYLOAD_', 'CONFIG_PAYLOAD_USED_');
end
configNames = unique(configNames, 'stable');
o_configNames = cat(2, o_configNames, configNames);
o_configValues = cat(2, o_configValues, nan(1, size(configNames, 2)));

% voir = cat(2, o_configNames', num2cell(o_configValues'));

return;
