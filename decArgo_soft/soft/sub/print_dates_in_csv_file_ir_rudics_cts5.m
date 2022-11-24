% ------------------------------------------------------------------------------
% Print time information in output CSV file.
%
% SYNTAX :
%  print_dates_in_csv_file_ir_rudics_cts5(a_timeDataFromApmtTech, a_apmtCtd, a_payloadData)
%
% INPUT PARAMETERS :
%   a_timeDataFromApmtTech : times from APMT technical data
%   a_apmtCtd              : APMT CTD data
%   a_payloadData          : payload sensor data
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
function print_dates_in_csv_file_ir_rudics_cts5(a_timeDataFromApmtTech, a_apmtCtd, a_payloadData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloatStr;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_presDef;

% decoded event data
global g_decArgo_eventDataTime;


tabDateFloat = [];
tabDateUtc = [];
tabLabel = [];
tabPres = [];

% retrieve time information from Event data
for idEvt = 1:length(g_decArgo_eventDataTime)
   tabDateFloat(end+1) = g_decArgo_eventDataTime{idEvt}.time;
   tabDateUtc(end+1) = adjust_time_cts5(g_decArgo_eventDataTime{idEvt}.time);
   tabLabel{end+1} = [g_decArgo_eventDataTime{idEvt}.label ' (event)'];
   if (isempty(g_decArgo_eventDataTime{idEvt}.pres))
      tabPres(end+1) = g_decArgo_presDef;
   else
      tabPres(end+1) = g_decArgo_eventDataTime{idEvt}.pres;
   end
end

% retrieve time information from tech data
for idL = 1:size(a_timeDataFromApmtTech, 1)
   timeData = a_timeDataFromApmtTech{idL, 3};
   for idT = 1:length(timeData)
      if (strcmp(timeData{idT}.paramName, 'JULD'))
         tabDateFloat(end+1) = timeData{idT}.time;
         tabDateUtc(end+1) = timeData{idT}.timeAdj;
         tabLabel{end+1} = [timeData{idT}.label ' (tech)'];
         if (isempty(timeData{idT}.pres))
            tabPres(end+1) = g_decArgo_presDef;
         else
            tabPres(end+1) = timeData{idT}.pres;
         end
      end
   end
end

% retrieve dated CTD measurements
for idP = 1:length(a_apmtCtd)
   
   dataStruct = a_apmtCtd{idP};
   
   if (strcmp(dataStruct.treat, '(SS)'))
      label = 'Subsurface measurement';
   else
      label = sprintf('Dated CTD meas. %s', dataStruct.phase);
   end
   
   data = dataStruct.data;
   datesAdj = adjust_time_cts5(data(:, 1));
   for idL = 1:size(data, 1)
      tabDateFloat(end+1) = data(idL, 1);
      tabDateUtc(end+1) = datesAdj(idL);
      tabLabel{end+1} = label;
      tabPres(end+1) =  data(idL, 2);
   end
end

% retrieve dated payload measurements
% extract useful information from payload data

if (~isempty(a_payloadData))
   
   % level #1 tags
   idLev1Begin = find(([a_payloadData{:, 1}] == 1) & ...
      ([a_payloadData{:, 3}] == 'B'));
   
   % SENSOR_XX tags
   idLev1BeginSensor = [];
   idF = find(strncmp(a_payloadData(idLev1Begin, 2), 'SENSOR_', length('SENSOR_')) & ...
      ~strcmp(a_payloadData(idLev1Begin, 2), 'SENSOR_ACT')); % to manage float anomaly (ex: 2ee3_020_01_payload.bin)
   if (~isempty(idF))
      idLev1BeginSensor = idLev1Begin(idF);
   end
   
   payloadProfiles = [];
   for idLev1B = 1:length(idLev1BeginSensor)
      payloadProfile = get_profile_payload_init_struct;
      idLev1Start = idLev1BeginSensor(idLev1B);
      idLev1End = find(strcmp(a_payloadData(:, 2), a_payloadData{idLev1Start, 2}) & ...
         ([a_payloadData{:, 3}] == 'E')');
      if (~isempty(idLev1End))
         idStop = find(idLev1End > idLev1Start);
         if (~isempty(idStop))
            idLev1Stop = idLev1End(idStop(1));
            
            % level #2 tags
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
                        
                        % extract sensor information
                        sensorInfo = a_payloadData{idLev2Start, 2};
                        idF = strfind(sensorInfo, '-');
                        payloadProfile.phaseName = sensorInfo(idF(end)+1:end);
                        if (~strcmp(payloadProfile.phaseName, 'RAW'))
                           payloadProfile.subSampling = sensorInfo(idF(end-1)+1:idF(end)-1);
                           payloadProfile.sensorNum = str2num(sensorInfo(idF(end-2)+1:idF(end-1)-1));
                           payloadProfile.sensorName = sensorInfo(1:idF(end-2)-1);
                        else
                           payloadProfile.sensorNum = str2num(sensorInfo(idF(end-1)+1:idF(end)-1));
                           payloadProfile.sensorName = sensorInfo(1:idF(end-1)-1);
                        end
                        
                        % extract sensor attributes
                        sensorAtt = a_payloadData{idLev2Start, 4};
                        for idP = 1:length(sensorAtt)/2
                           payloadProfile.(sensorAtt{idP*2-1}) = sensorAtt{idP*2};
                        end
                        
                        % level #3 tags
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
                                    
                                    % extract parameters and data
                                    dataLev2 = a_payloadData{idLev3Start, 2};
                                    if strcmp(dataLev2, 'CDATA')
                                       dataLev3 = a_payloadData{idLev3Start, 5};
                                       payloadProfile.paramName = dataLev3{1};
                                       payloadProfile.data = dataLev3{2}{:};
                                    end
                                 else
                                    fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Inconsistent payload data\n', ...
                                       g_decArgo_floatNum, ...
                                       g_decArgo_cycleNum, ...
                                       g_decArgo_cycleNumFloat, ...
                                       g_decArgo_patternNumFloat);
                                 end
                              else
                                 fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Inconsistent payload data\n', ...
                                    g_decArgo_floatNum, ...
                                    g_decArgo_cycleNum, ...
                                    g_decArgo_cycleNumFloat, ...
                                    g_decArgo_patternNumFloat);
                              end
                           end
                        end
                     else
                        fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Inconsistent payload data\n', ...
                           g_decArgo_floatNum, ...
                           g_decArgo_cycleNum, ...
                           g_decArgo_cycleNumFloat, ...
                           g_decArgo_patternNumFloat);
                     end
                  else
                     fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Inconsistent payload data\n', ...
                        g_decArgo_floatNum, ...
                        g_decArgo_cycleNum, ...
                        g_decArgo_cycleNumFloat, ...
                        g_decArgo_patternNumFloat);
                  end
               end
            end
         else
            fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Inconsistent payload data\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum, ...
               g_decArgo_cycleNumFloat, ...
               g_decArgo_patternNumFloat);
         end
      end
      payloadProfiles = [payloadProfiles payloadProfile];
   end
   
   % finalize payload information
   for idP = 1:length(payloadProfiles)
      payloadProfile = payloadProfiles(idP);
      
      % set label
      switch payloadProfile.phaseName
         case 'PRE'
            label = sprintf('Dated payload meas. [PREDESCENT]');
         case 'DES'
            label = sprintf('Dated payload meas. [DESCENT]');
         case 'PAR'
            label = sprintf('Dated payload meas. [PARK]');
         case 'DEE'
            label = sprintf('Dated payload meas. [DEEPPROFILE]');
         case 'SHO'
            label = sprintf('Dated payload meas. [SHORTPARK]');
         case 'ASC'
            label = sprintf('Dated payload meas. [ASCENT]');
         case 'SUR'
            label = sprintf('Dated payload meas. [SURFACE]');
         case 'RAW'
            continue
      end
      
      % convert date of first sample
      payloadProfile.juld = datenum(payloadProfile.date(1:19), ...
         'yyyy-mm-ddTHH:MM:SS') - g_decArgo_janFirst1950InMatlab;
      if (length(payloadProfile.date) > 19)
         payloadProfile.juld = payloadProfile.juld + str2double(payloadProfile.date(20:end))/86400;
      end
      
      data = payloadProfile.data;
      if (~isempty(data))
         
         dates = payloadProfile.juld + double(data(:, 1))/86400;
         datesAdj = adjust_time_cts5(dates);
         
         for idL = 1:size(data, 1)
            tabDateFloat(end+1) = dates(idL);
            tabDateUtc(end+1) = datesAdj(idL);
            tabLabel{end+1} = label;
            tabPres(end+1) =  data(idL, 2);
         end
      end
   end
end

% sort the collected dates in chronological order
[tabDateUtc, idSorted] = sort(tabDateUtc);
tabDateFloat = tabDateFloat(idSorted);
tabLabel = tabLabel(idSorted);
tabPres = tabPres(idSorted);

if (~isempty(tabDateUtc))
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; Dates; Description; Float time; UTC time; PRES (dbar)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr);

   for id = 1:length(tabDateUtc)
      if (tabPres(id) == g_decArgo_presDef)
         fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; Dates; %s; %s; %s\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            tabLabel{id}, julian_2_gregorian_dec_argo(tabDateFloat(id)), julian_2_gregorian_dec_argo(tabDateUtc(id)));
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; Dates; %s; %s; %s; %.2f\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            tabLabel{id}, julian_2_gregorian_dec_argo(tabDateFloat(id)), julian_2_gregorian_dec_argo(tabDateUtc(id)), tabPres(id));
      end
   end
end

return
