% ------------------------------------------------------------------------------
% Print dates in output CSV file.
%
% SYNTAX :
%  print_dates_in_csv_file_nva_1_2( ...
%    a_descProfDate, a_descProfDateAdj, a_descProfPres, ...
%    a_parkDate, a_parkDateAdj, a_parkPres, ...
%    a_ascProfDate, a_ascProfDateAdj, a_ascProfPres, ...
%    a_dataHydrau)
%
% INPUT PARAMETERS :
%   a_descProfDate    : descending profile measurement dates
%   a_descProfDateAdj : descending profile measurement adjusted dates
%   a_descProfPres    : associated descending profile PRES measurements
%   a_parkDate        : park drift measurement dates
%   a_parkDateAdj     : park drift measurement adjusted dates
%   a_parkPres        : associated park drift PRES measurements
%   a_ascProfDate     : ascending profile measurement dates
%   a_ascProfDateAdj  : ascending profile measurement adjusted dates
%   a_ascProfPres     : associated ascending profile PRES measurements
%   a_dataHydrau      : hydraulic data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/28/2016 - RNU - creation
% ------------------------------------------------------------------------------
function print_dates_in_csv_file_nva_1_2( ...
   a_descProfDate, a_descProfDateAdj, a_descProfPres, ...
   a_parkDate, a_parkDateAdj, a_parkPres, ...
   a_ascProfDate, a_ascProfDateAdj, a_ascProfPres, ...
   a_dataHydrau)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;

% cycle timings storage
global g_decArgo_timeData;


% retrieve cycle timings
if (~isempty(g_decArgo_timeData))
   idCycleStruct = find([g_decArgo_timeData.cycleNum] == g_decArgo_cycleNum);
   if (~isempty(idCycleStruct))
      idCycleStruct = idCycleStruct(end);
      cycleTimeStruct = g_decArgo_timeData.cycleTime(idCycleStruct);
      
      % retrieve cycle timings of the previous cycle
      cycleTimeStructPrev = [];
      idCycleStructPrev = find([g_decArgo_timeData.cycleNum] == g_decArgo_cycleNum-1);
      if (~isempty(idCycleStructPrev))
         cycleTimeStructPrev = g_decArgo_timeData.cycleTime(idCycleStructPrev);
      end
   
      % store cycle timings
      tabDateFloat = [];
      tabDateUtc = [];
      tabDate = [];
      tabLabel = [];
      tabPres = [];
      
      % cycle timings
      if (~isempty(cycleTimeStructPrev))
         tabDateFloat(end+1) = g_decArgo_dateDef;
         tabDateUtc(end+1) = cycleTimeStructPrev.lastMessageTime;
         tabDate(end+1) = cycleTimeStructPrev.lastMessageTime;
         tabLabel{end+1} = 'LAST_MESSAGE_TIME_OF_PREV_CYCLE';
         tabPres(end+1) = g_decArgo_presDef;
      end
      if (cycleTimeStruct.cycleStartTime ~= g_decArgo_dateDef)
         tabDateFloat(end+1) = cycleTimeStruct.cycleStartTime;
         tabDateUtc(end+1) = cycleTimeStruct.cycleStartTimeAdj;
         if (~isempty(cycleTimeStruct.clockDrift))
            tabDate(end+1) = cycleTimeStruct.cycleStartTimeAdj;
         else
            tabDate(end+1) = cycleTimeStruct.cycleStartTime;
         end
         tabLabel{end+1} = 'CYCLE_START_TIME';
         tabPres(end+1) = g_decArgo_presDef;
      end
      if (cycleTimeStruct.descentToParkStartTime ~= g_decArgo_dateDef)
         tabDateFloat(end+1) = cycleTimeStruct.descentToParkStartTime;
         tabDateUtc(end+1) = cycleTimeStruct.descentToParkStartTimeAdj;
         if (~isempty(cycleTimeStruct.clockDrift))
            tabDate(end+1) = cycleTimeStruct.descentToParkStartTimeAdj;
         else
            tabDate(end+1) = cycleTimeStruct.descentToParkStartTime;
         end
         tabLabel{end+1} = 'DESCENT_TO_PARK_START_TIME';
         tabPres(end+1) = g_decArgo_presDef;
      end
      if (cycleTimeStruct.firstStabilizationTime ~= g_decArgo_dateDef)
         tabDateFloat(end+1) = cycleTimeStruct.firstStabilizationTime;
         tabDateUtc(end+1) = cycleTimeStruct.firstStabilizationTimeAdj;
         if (~isempty(cycleTimeStruct.clockDrift))
            tabDate(end+1) = cycleTimeStruct.firstStabilizationTimeAdj;
         else
            tabDate(end+1) = cycleTimeStruct.firstStabilizationTime;
         end
         tabLabel{end+1} = 'FIRST_STABILIZATION_TIME';
         tabPres(end+1) = cycleTimeStruct.firstStabilizationPres;
      end
      if (cycleTimeStruct.descentToParkEndTime ~= g_decArgo_dateDef)
         tabDateFloat(end+1) = cycleTimeStruct.descentToParkEndTime;
         tabDateUtc(end+1) = cycleTimeStruct.descentToParkEndTimeAdj;
         if (~isempty(cycleTimeStruct.clockDrift))
            tabDate(end+1) = cycleTimeStruct.descentToParkEndTimeAdj;
         else
            tabDate(end+1) = cycleTimeStruct.descentToParkEndTime;
         end
         tabLabel{end+1} = 'PARK_START_TIME';
         tabPres(end+1) = g_decArgo_presDef;
      end
      if (cycleTimeStruct.descentToProfStartTime ~= g_decArgo_dateDef)
         tabDateFloat(end+1) = cycleTimeStruct.descentToProfStartTime;
         tabDateUtc(end+1) = cycleTimeStruct.descentToProfStartTimeAdj;
         if (~isempty(cycleTimeStruct.clockDrift))
            tabDate(end+1) = cycleTimeStruct.descentToProfStartTimeAdj;
         else
            tabDate(end+1) = cycleTimeStruct.descentToProfStartTime;
         end
         tabLabel{end+1} = 'PARK_END_TIME';
         tabPres(end+1) = g_decArgo_presDef;
      end
      if (cycleTimeStruct.descentToProfEndTime ~= g_decArgo_dateDef)
         tabDateFloat(end+1) = cycleTimeStruct.descentToProfEndTime;
         tabDateUtc(end+1) = cycleTimeStruct.descentToProfEndTimeAdj;
         if (~isempty(cycleTimeStruct.clockDrift))
            tabDate(end+1) = cycleTimeStruct.descentToProfEndTimeAdj;
         else
            tabDate(end+1) = cycleTimeStruct.descentToProfEndTime;
         end
         tabLabel{end+1} = 'DEEP_PARK_START_TIME';
         tabPres(end+1) = g_decArgo_presDef;
      end
      if (cycleTimeStruct.ascentStartTime ~= g_decArgo_dateDef)
         tabDateFloat(end+1) = cycleTimeStruct.ascentStartTime;
         tabDateUtc(end+1) = cycleTimeStruct.ascentStartTimeAdj;
         if (~isempty(cycleTimeStruct.clockDrift))
            tabDate(end+1) = cycleTimeStruct.ascentStartTimeAdj;
         else
            tabDate(end+1) = cycleTimeStruct.ascentStartTime;
         end
         tabLabel{end+1} = 'ASCENT_START_TIME';
         tabPres(end+1) = g_decArgo_presDef;
      end
      if (cycleTimeStruct.ascentEndTime ~= g_decArgo_dateDef)
         tabDateFloat(end+1) = cycleTimeStruct.ascentEndTime;
         tabDateUtc(end+1) = cycleTimeStruct.ascentEndTimeAdj;
         if (~isempty(cycleTimeStruct.clockDrift))
            tabDate(end+1) = cycleTimeStruct.ascentEndTimeAdj;
         else
            tabDate(end+1) = cycleTimeStruct.ascentEndTime;
         end
         tabLabel{end+1} = 'ASCENT_END_TIME';
         tabPres(end+1) = g_decArgo_presDef;
      end
      if (cycleTimeStruct.gpsTime ~= g_decArgo_dateDef)
         tabDateFloat(end+1) = cycleTimeStruct.gpsTime;
         tabDateUtc(end+1) = cycleTimeStruct.gpsTimeAdj;
         if (~isempty(cycleTimeStruct.clockDrift))
            tabDate(end+1) = cycleTimeStruct.gpsTimeAdj;
         else
            tabDate(end+1) = cycleTimeStruct.gpsTime;
         end
         tabLabel{end+1} = 'GPS_LOCATION_TIME';
         tabPres(end+1) = g_decArgo_presDef;
      end
      if (cycleTimeStruct.firstMessageTime ~= g_decArgo_dateDef)
         tabDateFloat(end+1) = g_decArgo_dateDef;
         tabDateUtc(end+1) = cycleTimeStruct.firstMessageTime;
         tabDate(end+1) = cycleTimeStruct.firstMessageTime;
         tabLabel{end+1} = 'FIRST_MESSAGE_TIME';
         tabPres(end+1) = g_decArgo_presDef;
      end
      if (cycleTimeStruct.lastMessageTime ~= g_decArgo_dateDef)
         tabDateFloat(end+1) = g_decArgo_dateDef;
         tabDateUtc(end+1) = cycleTimeStruct.lastMessageTime;
         tabDate(end+1) = cycleTimeStruct.lastMessageTime;
         tabLabel{end+1} = 'LAST_MESSAGE_TIME';
         tabPres(end+1) = g_decArgo_presDef;
      end
               
      % CTD dated measurements
            
      idDated = find(a_descProfDate ~= g_decArgo_dateDef);
      if (~isempty(idDated))
         tabDateFloat = [tabDateFloat a_descProfDateAdj(idDated)'];
         tabDateUtc = [tabDateUtc a_descProfDate(idDated)'];
         if (~isempty(cycleTimeStruct.clockDrift))
            tabDate = [tabDate a_descProfDateAdj(idDated)'];
         else
            tabDate = [tabDate a_descProfDate(idDated)'];
         end
         tabLabel = [tabLabel repmat({'Dated level of descent profile'}, 1, length(idDated))];
         tabPres = [tabPres a_descProfPres(idDated)'];
      end
      
      idDated = find(a_parkDate ~= g_decArgo_dateDef);
      if (~isempty(idDated))
         tabDateFloat = [tabDateFloat a_parkDateAdj(idDated)'];
         tabDateUtc = [tabDateUtc a_parkDate(idDated)'];
         if (~isempty(cycleTimeStruct.clockDrift))
            tabDate = [tabDate a_parkDateAdj(idDated)'];
         else
            tabDate = [tabDate a_parkDate(idDated)'];
         end
         tabLabel = [tabLabel repmat({'Park drift meas.'}, 1, length(idDated))];
         tabPres = [tabPres a_parkPres(idDated)'];
      end
      
      idDated = find(a_ascProfDate ~= g_decArgo_dateDef);
      if (~isempty(idDated))
         tabDateFloat = [tabDateFloat a_ascProfDateAdj(idDated)'];
         tabDateUtc = [tabDateUtc a_ascProfDate(idDated)'];
         if (~isempty(cycleTimeStruct.clockDrift))
            tabDate = [tabDate a_ascProfDateAdj(idDated)'];
         else
            tabDate = [tabDate a_ascProfDate(idDated)'];
         end
         tabLabel = [tabLabel repmat({'Dated level of ascent profile'}, 1, length(idDated))];
         tabPres = [tabPres a_ascProfPres(idDated)'];
      end
      
      % Hydraulic actions
      if (~isempty(a_dataHydrau) && (cycleTimeStruct.cycleStartTime ~= g_decArgo_dateDef))
         
         for idH = 1:size(a_dataHydrau, 1)
            data = a_dataHydrau(idH, :);
            tabDateFloat(end+1) = data(4)/24 + cycleTimeStruct.cycleStartTime;
            if (~isempty(cycleTimeStruct.clockDrift))
               clockOffset = get_nva_clock_offset(tabDateFloat(end), g_decArgo_cycleNum, [], [], []);
               % round clock offset to 6 minutes
               clockOffset = round(clockOffset*1440/6)*6/1440;
               tabDateUtc(end+1) = tabDateFloat(end) - clockOffset;
               tabDate(end+1) = tabDateUtc(end);
            else
               tabDateUtc(end+1) = g_decArgo_dateDef;
               tabDate(end+1) = tabDateFloat(end);
            end
            if (data(5) == hex2dec('ffff'))
               tabLabel{end+1} = 'Valve action';
            else
               tabLabel{end+1} = 'Pump action';
            end
            tabPres(end+1) = data(3)*10;
         end
      end
               
      % sort the collected dates in chronological order
      [tabDate, idSorted] = sort(tabDate);
      tabDateFloat = tabDateFloat(idSorted);
      tabDateUtc = tabDateUtc(idSorted);
      tabLabel = tabLabel(idSorted);
      tabPres = tabPres(idSorted);
      
      % add vertical velocities
      tabVertSpeed = ones(1, length(tabDate))*99999;
      tabMeanVertSpeed = ones(1, length(tabDate))*99999;
      for id = 1:3
         if (id == 1)
            idF1 = find (strcmp(tabLabel, 'DESCENT_TO_PARK_START_TIME') == 1);
            idF2 = find (strcmp(tabLabel, 'PARK_START_TIME') == 1);
            sign = 1;
         elseif (id == 2)
            idF1 = find (strcmp(tabLabel, 'PARK_END_TIME') == 1);
            idF2 = find (strcmp(tabLabel, 'DEEP_PARK_START_TIME') == 1);
            sign = 1;
         elseif (id == 3)
            idF1 = find (strcmp(tabLabel, 'ASCENT_START_TIME') == 1);
            idF2 = find (strcmp(tabLabel, 'ASCENT_END_TIME') == 1);
            sign = -1;
         end
         
         if (~isempty(idF1) && ~isempty(idF2))
            idSlice = idF1+1:idF2-1;
            idPres = find(tabPres(idSlice) ~= g_decArgo_presDef);
            for idP = 2:length(idPres)
               if (tabDate(idSlice(idPres(idP))) ~= tabDate(idSlice(idPres(idP-1))))
                  vertSpeed = (tabPres(idSlice(idPres(idP)))-tabPres(idSlice(idPres(idP-1))))*100 / ...
                     ((tabDate(idSlice(idPres(idP)))-tabDate(idSlice(idPres(idP-1))))*86400);
                  tabVertSpeed(idF1+idP) = sign*vertSpeed;
               end
               if (tabDate(idSlice(idPres(idP))) ~= tabDate(idSlice(idPres(1))))
                  meanVertSpeed = (tabPres(idSlice(idPres(idP)))-tabPres(idSlice(idPres(1))))*100 / ...
                     ((tabDate(idSlice(idPres(idP)))-tabDate(idSlice(idPres(1))))*86400);
                  tabMeanVertSpeed(idF1+idP) = sign*meanVertSpeed;
               end
            end
         end
      end
      
      if (~isempty(cycleTimeStruct.clockDrift))
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; Clock offset; %s\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, format_time_dec_argo(cycleTimeStruct.clockDrift*24));
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; Clock offset; UNKNOWN\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
      end
      
      if (~isempty(tabDate))
         
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; Description; Float time; UTC time; pressure (dbar); vert. speed (cm/s); mean vert. speed (cm/s)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
         
         for id = 1:length(tabDate)
            if (tabPres(id) == g_decArgo_presDef)
               fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; %s; %s; %s\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  tabLabel{id}, julian_2_gregorian_dec_argo(tabDateFloat(id)), julian_2_gregorian_dec_argo(tabDateUtc(id)));
            else
               if (tabVertSpeed(id) == 99999)
                  fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; %s; %s; %s; %.1f\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, ...
                     tabLabel{id}, julian_2_gregorian_dec_argo(tabDateFloat(id)), julian_2_gregorian_dec_argo(tabDateUtc(id)), tabPres(id));
               else
                  fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; %s; %s; %s; %.1f; %.1f; %.1f\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, ...
                     tabLabel{id}, julian_2_gregorian_dec_argo(tabDateFloat(id)), julian_2_gregorian_dec_argo(tabDateUtc(id)), tabPres(id), tabVertSpeed(id), tabMeanVertSpeed(id));
               end
            end
         end
      end
   end
end

return;
