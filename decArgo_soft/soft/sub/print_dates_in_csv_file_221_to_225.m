% ------------------------------------------------------------------------------
% Print dates in output CSV file.
%
% SYNTAX :
%  print_dates_in_csv_file_221_to_225( ...
%    a_cycleTimeData, ...
%    a_descProfDate, a_descProfDateAdj, a_descProfPres, ...
%    a_parkDate, a_parkDateAdj, a_parkPres, ...
%    a_ascProfDate, a_ascProfDateAdj, a_ascProfPres, ...
%    a_nearSurfDate, a_nearSurfDateAdj, a_nearSurfPres, ...
%    a_inAirDate, a_inAirDateAdj, a_inAirPres, ...
%    a_evAct, a_pumpAct)
%
% INPUT PARAMETERS :
%   a_cycleTimeData   : cycle timings structure
%   a_descProfDate    : descending profile dates
%   a_descProfDateAdj : descending profile adjusted dates
%   a_descProfPres    : descending profile PRES
%   a_parkDate        : drift meas dates
%   a_parkDateAdj     : drift meas adjusted dates
%   a_parkPres        : drift meas PRES
%   a_ascProfDate     : ascending profile dates
%   a_ascProfDateAdj  : ascending profile adjusted dates
%   a_ascProfPres     : ascending profile PRES
%   a_nearSurfDate    : "near surface" profile dates
%   a_nearSurfDateAdj : "near surface" profile adjusted dates
%   a_nearSurfPres    : "near surface" profile PRES
%   a_inAirDate       : "in air" profile dates
%   a_inAirDateAdj    : "in air" profile adjusted dates
%   a_inAirPres       : "in air" profile PRES
%   a_evAct           : hydraulic (EV) data
%   a_pumpAct         : hydraulic (pump) data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/09/2019 - RNU - creation
% ------------------------------------------------------------------------------
function print_dates_in_csv_file_221_to_225( ...
   a_cycleTimeData, ...
   a_descProfDate, a_descProfDateAdj, a_descProfPres, ...
   a_parkDate, a_parkDateAdj, a_parkPres, ...
   a_ascProfDate, a_ascProfDateAdj, a_ascProfPres, ...
   a_nearSurfDate, a_nearSurfDateAdj, a_nearSurfPres, ...
   a_inAirDate, a_inAirDateAdj, a_inAirPres, ...
   a_evAct, a_pumpAct)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;


tabDate = [];
tabDateAdj = [];
tabLabel = [];
tabPres = [];

% cycle timings
if (~isempty(a_cycleTimeData.cycleStartDate))
   tabDate(end+1) = a_cycleTimeData.cycleStartDate;
   tabDateAdj(end+1) = g_decArgo_dateDef;
   tabLabel{end+1} = 'CYCLE_START_TIME';
   tabPres(end+1) = g_decArgo_presDef;
   if (~isempty(a_cycleTimeData.cycleStartDateAdj))
      tabDateAdj(end) = a_cycleTimeData.cycleStartDateAdj;
   end
end
if (~isempty(a_cycleTimeData.descentToParkStartDate))
   tabDate(end+1) = a_cycleTimeData.descentToParkStartDate;
   tabDateAdj(end+1) = g_decArgo_dateDef;
   tabLabel{end+1} = 'DESCENT_TO_PARK_START_TIME';
   tabPres(end+1) = g_decArgo_presDef;
   if (~isempty(a_cycleTimeData.descentToParkStartDateAdj))
      tabDateAdj(end) = a_cycleTimeData.descentToParkStartDateAdj;
   end
end
if (~isempty(a_cycleTimeData.firstStabDate))
   tabDate(end+1) = a_cycleTimeData.firstStabDate;
   tabDateAdj(end+1) = g_decArgo_dateDef;
   tabLabel{end+1} = 'FIRST_STABILIZATION_TIME';
   tabPres(end+1) = a_cycleTimeData.firstStabPres;
   if (~isempty(a_cycleTimeData.firstStabDateAdj))
      tabDateAdj(end) = a_cycleTimeData.firstStabDateAdj;
   end
end
if (~isempty(a_cycleTimeData.descentToParkEndDate))
   tabDate(end+1) = a_cycleTimeData.descentToParkEndDate;
   tabDateAdj(end+1) = g_decArgo_dateDef;
   tabLabel{end+1} = 'PARK_START_TIME';
   tabPres(end+1) = g_decArgo_presDef;
   if (~isempty(a_cycleTimeData.descentToParkEndDateAdj))
      tabDateAdj(end) = a_cycleTimeData.descentToParkEndDateAdj;
   end
end
if (~isempty(a_cycleTimeData.descentToProfStartDate))
   tabDate(end+1) = a_cycleTimeData.descentToProfStartDate;
   tabDateAdj(end+1) = g_decArgo_dateDef;
   tabLabel{end+1} = 'PARK_END_TIME';
   tabPres(end+1) = g_decArgo_presDef;
   if (~isempty(a_cycleTimeData.descentToProfStartDateAdj))
      tabDateAdj(end) = a_cycleTimeData.descentToProfStartDateAdj;
   end
end
if (~isempty(a_cycleTimeData.descentToProfEndDate))
   tabDate(end+1) = a_cycleTimeData.descentToProfEndDate;
   tabDateAdj(end+1) = g_decArgo_dateDef;
   tabLabel{end+1} = 'DEEP_PARK_START_TIME';
   tabPres(end+1) = g_decArgo_presDef;
   if (~isempty(a_cycleTimeData.descentToProfEndDateAdj))
      tabDateAdj(end) = a_cycleTimeData.descentToProfEndDateAdj;
   end
end
if (~isempty(a_cycleTimeData.ascentStartDate))
   tabDate(end+1) = a_cycleTimeData.ascentStartDate;
   tabDateAdj(end+1) = g_decArgo_dateDef;
   tabLabel{end+1} = 'ASCENT_START_TIME';
   tabPres(end+1) = g_decArgo_presDef;
   if (~isempty(a_cycleTimeData.ascentStartDateAdj))
      tabDateAdj(end) = a_cycleTimeData.ascentStartDateAdj;
   end
end
if (~isempty(a_cycleTimeData.ascentEndDate))
   tabDate(end+1) = a_cycleTimeData.ascentEndDate;
   tabDateAdj(end+1) = g_decArgo_dateDef;
   tabLabel{end+1} = 'ASCENT_END_TIME';
   tabPres(end+1) = g_decArgo_presDef;
   if (~isempty(a_cycleTimeData.ascentEndDateAdj))
      tabDateAdj(end) = a_cycleTimeData.ascentEndDateAdj;
   end
end
if (~isempty(a_cycleTimeData.transStartDate))
   tabDate(end+1) = a_cycleTimeData.transStartDate;
   tabDateAdj(end+1) = g_decArgo_dateDef;
   tabLabel{end+1} = 'TRANSMISSION_START_TIME';
   tabPres(end+1) = g_decArgo_presDef;
   if (~isempty(a_cycleTimeData.transStartDateAdj))
      tabDateAdj(end) = a_cycleTimeData.transStartDateAdj;
   end
end
if (~isempty(a_cycleTimeData.gpsDate))
   tabDate(end+1) = a_cycleTimeData.gpsDate;
   tabDateAdj(end+1) = g_decArgo_dateDef;
   tabLabel{end+1} = 'GPS_LOCATION_TIME';
   tabPres(end+1) = g_decArgo_presDef;
   if (~isempty(a_cycleTimeData.gpsDate))
      tabDateAdj(end) = a_cycleTimeData.gpsDate;
   end
end
if (~isempty(a_cycleTimeData.eolStartDate))
   tabDate(end+1) = a_cycleTimeData.eolStartDate;
   tabDateAdj(end+1) = g_decArgo_dateDef;
   tabLabel{end+1} = 'EOL_START_TIME';
   tabPres(end+1) = g_decArgo_presDef;
   if (~isempty(a_cycleTimeData.eolStartDateAdj))
      tabDateAdj(end) = a_cycleTimeData.eolStartDateAdj;
   end
end
if (~isempty(a_cycleTimeData.firstGroundingDate))
   tabDate(end+1) = a_cycleTimeData.firstGroundingDate;
   tabDateAdj(end+1) = g_decArgo_dateDef;
   tabLabel{end+1} = 'FIRST_GROUNDING_TIME';
   tabPres(end+1) = a_cycleTimeData.firstGroundingPres;
   if (~isempty(a_cycleTimeData.firstGroundingDateAdj))
      tabDateAdj(end) = a_cycleTimeData.firstGroundingDateAdj;
   end
end
if (~isempty(a_cycleTimeData.secondGroundingDate))
   tabDate(end+1) = a_cycleTimeData.secondGroundingDate;
   tabDateAdj(end+1) = g_decArgo_dateDef;
   tabLabel{end+1} = 'SECOND_GROUNDING_TIME';
   tabPres(end+1) = a_cycleTimeData.secondGroundingPres;
   if (~isempty(a_cycleTimeData.secondGroundingDateAdj))
      tabDateAdj(end) = a_cycleTimeData.secondGroundingDateAdj;
   end
end
if (~isempty(a_cycleTimeData.firstEmergencyAscentDate))
   tabDate(end+1) = a_cycleTimeData.firstEmergencyAscentDate;
   tabDateAdj(end+1) = g_decArgo_dateDef;
   tabLabel{end+1} = 'FIRST_EMERGENCY_ASCENT_TIME';
   tabPres(end+1) = a_cycleTimeData.firstEmergencyAscentPres;
   if (~isempty(a_cycleTimeData.firstEmergencyAscentDateAdj))
      tabDateAdj(end) = a_cycleTimeData.firstEmergencyAscentDateAdj;
   end
end

% CTDO dated measurements
idDated = find(a_descProfDate ~= g_decArgo_dateDef);
if (~isempty(idDated))
   tabDate = [tabDate a_descProfDate(idDated)'];
   if (~any(a_descProfDateAdj(idDated) == g_decArgo_dateDef))
      tabDateAdj = [tabDateAdj a_descProfDateAdj(idDated)'];
   else
      tabDateAdj = [tabDateAdj ones(1, length(idDated))*g_decArgo_dateDef];
   end
   tabLabel = [tabLabel repmat({'Dated level of descent profile'}, 1, length(idDated))];
   tabPres = [tabPres a_descProfPres(idDated)'];
end

idDated = find(a_parkDate ~= g_decArgo_dateDef);
if (~isempty(idDated))
   tabDate = [tabDate a_parkDate(idDated)'];
   if (~any(a_parkDateAdj(idDated) == g_decArgo_dateDef))
      tabDateAdj = [tabDateAdj a_parkDateAdj(idDated)'];
   else
      tabDateAdj = [tabDateAdj ones(1, length(idDated))*g_decArgo_dateDef];
   end
   tabLabel = [tabLabel repmat({'Park drift meas.'}, 1, length(idDated))];
   tabPres = [tabPres a_parkPres(idDated)'];
end

idDated = find(a_ascProfDate ~= g_decArgo_dateDef);
if (~isempty(idDated))
   tabDate = [tabDate a_ascProfDate(idDated)'];
   if (~any(a_ascProfDateAdj(idDated) == g_decArgo_dateDef))
      tabDateAdj = [tabDateAdj a_ascProfDateAdj(idDated)'];
   else
      tabDateAdj = [tabDateAdj ones(1, length(idDated))*g_decArgo_dateDef];
   end
   tabLabel = [tabLabel repmat({'Dated level of ascent profile'}, 1, length(idDated))];
   tabPres = [tabPres a_ascProfPres(idDated)'];
end

idDated = find(a_nearSurfDate ~= g_decArgo_dateDef);
if (~isempty(idDated))
   tabDate = [tabDate a_nearSurfDate(idDated)'];
   if (~any(a_nearSurfDateAdj(idDated) == g_decArgo_dateDef))
      tabDateAdj = [tabDateAdj a_nearSurfDateAdj(idDated)'];
   else
      tabDateAdj = [tabDateAdj ones(1, length(idDated))*g_decArgo_dateDef];
   end
   tabLabel = [tabLabel repmat({'Near surface meas. date'}, 1, length(idDated))];
   tabPres = [tabPres a_nearSurfPres(idDated)'];
end

idDated = find(a_inAirDate ~= g_decArgo_dateDef);
if (~isempty(idDated))
   tabDate = [tabDate a_inAirDate(idDated)'];
   if (~any(a_inAirDateAdj(idDated) == g_decArgo_dateDef))
      tabDateAdj = [tabDateAdj a_inAirDateAdj(idDated)'];
   else
      tabDateAdj = [tabDateAdj ones(1, length(idDated))*g_decArgo_dateDef];
   end
   tabLabel = [tabLabel repmat({'In air meas. date'}, 1, length(idDated))];
   tabPres = [tabPres a_inAirPres(idDated)'];
end

% hydraulic actions
for idP = 1:size(a_evAct, 1)
   tabDate(end+1) = a_evAct(idP, 3) + g_decArgo_julD2FloatDayOffset;
   tabDateAdj(end+1) = a_evAct(idP, 4);
   tabLabel{end+1} = 'EV action';
   tabPres(end+1) = a_evAct(idP, 5);
end

for idP = 1:size(a_pumpAct, 1)
   tabDate(end+1) = a_pumpAct(idP, 3) + g_decArgo_julD2FloatDayOffset;
   tabDateAdj(end+1) = a_pumpAct(idP, 4);
   tabLabel{end+1} = 'Pump action';
   tabPres(end+1) = a_pumpAct(idP, 5);
end
   
% sort the collected dates in chronological order
[tabDate, idSorted] = sort(tabDate);
tabDateAdj = tabDateAdj(idSorted);
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

if (~isempty(a_cycleTimeData.cycleClockOffset))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; RTCOffset; Clock offset; %d; seconds\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      a_cycleTimeData.cycleClockOffset);
else
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; RTCOffset; Clock offset; UNDEFINED\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
end

if (~isempty(tabDate))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; Description;Float time;UTC time; pressure (dbar); vert. speed (cm/s); mean vert. speed (cm/s)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   for id = 1:length(tabDate)
      if (tabPres(id) == g_decArgo_presDef)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; %s; %s; %s\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            tabLabel{id}, ...
            julian_2_gregorian_dec_argo(tabDate(id)), ...
            julian_2_gregorian_dec_argo(tabDateAdj(id)));
      else
         if (tabVertSpeed(id) == 99999)
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; %s; %s; %s; %.1f\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, ...
               tabLabel{id}, ...
               julian_2_gregorian_dec_argo(tabDate(id)), ...
               julian_2_gregorian_dec_argo(tabDateAdj(id)), ...
               tabPres(id));
         else
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; %s; %s; %s; %.1f; %.1f; %.1f\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, ...
               tabLabel{id}, ...
               julian_2_gregorian_dec_argo(tabDate(id)), ...
               julian_2_gregorian_dec_argo(tabDateAdj(id)), ...
               tabPres(id), tabVertSpeed(id), tabMeanVertSpeed(id));
         end
      end
   end
end

return
