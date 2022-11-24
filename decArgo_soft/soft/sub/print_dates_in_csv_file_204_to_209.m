% ------------------------------------------------------------------------------
% Print dates in output CSV file.
%
% SYNTAX :
%  print_dates_in_csv_file_204_to_209( ...
%    a_cycleStartDate, ...
%    a_descentToParkStartDate, ...
%    a_firstStabDate, a_firstStabPres, ...
%    a_descentToParkEndDate, ...
%    a_descentToProfStartDate, ...
%    a_descentToProfEndDate, ...
%    a_ascentStartDate, ...
%    a_ascentEndDate, ...
%    a_transStartDate, ...
%    a_gpsDate, ...
%    a_firstGroundingDate, a_firstGroundingPres, ...
%    a_firstEmergencyAscentDate, a_firstEmergencyAscentPres, ...
%    a_descProfDate, a_descProfPres, ...
%    a_parkDate, a_parkPres, ...
%    a_ascProfDate, a_ascProfPres)
%
% INPUT PARAMETERS :
%   a_cycleStartDate           : cycle start date
%   a_descentToParkStartDate   : descent to park start date
%   a_firstStabDate            : first stabilisation date
%   a_firstStabPres            : first stabilisation pressure
%   a_descentToParkEndDate     : descent to park end date
%   a_descentToProfStartDate   : descent to profile start date
%   a_descentToProfEndDate     : descent to profile end date
%   a_ascentStartDate          : ascent start date
%   a_ascentEndDate            : ascent end date
%   a_transStartDate           : transmission start date
%   a_gpsDate                  : date associated to the GPS location
%   a_firstGroundingDate       : first grounding date
%   a_firstGroundingPres       : first grounding pressure
%   a_firstEmergencyAscentDate : first emergency ascent ascent date
%   a_firstEmergencyAscentPres : first grounding pressure
%   a_descProfDate             : descending profile dates
%   a_descProfPres             : descending profile PRES
%   a_parkDate                 : drift meas dates
%   a_parkPres                 : drift meas PRES
%   a_ascProfDate              : ascending profile dates
%   a_ascProfPres              : ascending profile PRES
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/11/2015 - RNU - creation
% ------------------------------------------------------------------------------
function print_dates_in_csv_file_204_to_209( ...
   a_cycleStartDate, ...
   a_descentToParkStartDate, ...
   a_firstStabDate, a_firstStabPres, ...
   a_descentToParkEndDate, ...
   a_descentToProfStartDate, ...
   a_descentToProfEndDate, ...
   a_ascentStartDate, ...
   a_ascentEndDate, ...
   a_transStartDate, ...
   a_gpsDate, ...
   a_firstGroundingDate, a_firstGroundingPres, ...
   a_firstEmergencyAscentDate, a_firstEmergencyAscentPres, ...
   a_descProfDate, a_descProfPres, ...
   a_parkDate, a_parkPres, ...
   a_ascProfDate, a_ascProfPres)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;


tabDate = [];
tabLabel = [];
tabPres = [];

% cycle timings
if (~isempty(a_cycleStartDate))
   tabDate(end+1) = a_cycleStartDate;
   tabLabel{end+1} = 'CYCLE_START_TIME';
   tabPres(end+1) = g_decArgo_presDef;
end
if (~isempty(a_descentToParkStartDate))
   tabDate(end+1) = a_descentToParkStartDate;
   tabLabel{end+1} = 'DESCENT_TO_PARK_START_TIME';
   tabPres(end+1) = g_decArgo_presDef;
end
if (~isempty(a_firstStabDate))
   tabDate(end+1) = a_firstStabDate;
   tabLabel{end+1} = 'FIRST_STABILIZATION_TIME';
   tabPres(end+1) = a_firstStabPres;
end
if (~isempty(a_descentToParkEndDate))
   tabDate(end+1) = a_descentToParkEndDate;
   tabLabel{end+1} = 'PARK_START_TIME';
   tabPres(end+1) = g_decArgo_presDef;
end
if (~isempty(a_descentToProfStartDate))
   tabDate(end+1) = a_descentToProfStartDate;
   tabLabel{end+1} = 'PARK_END_TIME';
   tabPres(end+1) = g_decArgo_presDef;
end
if (~isempty(a_descentToProfEndDate))
   tabDate(end+1) = a_descentToProfEndDate;
   tabLabel{end+1} = 'DEEP_PARK_START_TIME';
   tabPres(end+1) = g_decArgo_presDef;
end
if (~isempty(a_ascentStartDate))
   tabDate(end+1) = a_ascentStartDate;
   tabLabel{end+1} = 'ASCENT_START_TIME';
   tabPres(end+1) = g_decArgo_presDef;
end
if (~isempty(a_ascentEndDate))
   tabDate(end+1) = a_ascentEndDate;
   tabLabel{end+1} = 'ASCENT_END_TIME';
   tabPres(end+1) = g_decArgo_presDef;
end
if (~isempty(a_transStartDate))
   tabDate(end+1) = a_transStartDate;
   tabLabel{end+1} = 'TRANSMISSION_START_TIME';
   tabPres(end+1) = g_decArgo_presDef;
end
if (~isempty(a_gpsDate))
   tabDate(end+1) = a_gpsDate;
   tabLabel{end+1} = 'GPS_LOCATION_TIME';
   tabPres(end+1) = g_decArgo_presDef;
end
if (~isempty(a_firstGroundingDate))
   tabDate(end+1) = a_firstGroundingDate;
   tabLabel{end+1} = 'FIRST_GROUNDING_TIME';
   tabPres(end+1) = a_firstGroundingPres;
end
if (~isempty(a_firstEmergencyAscentDate))
   tabDate(end+1) = a_firstEmergencyAscentDate;
   tabLabel{end+1} = 'FIRST_EMERGENCY_ASCENT_TIME';
   tabPres(end+1) = a_firstEmergencyAscentPres;
end

% CTD dated measurements
idDated = find(a_descProfDate ~= g_decArgo_dateDef);
if (~isempty(idDated))
   tabDate = [tabDate a_descProfDate(idDated)'];
   tabLabel = [tabLabel repmat({'Dated level of descent profile'}, 1, length(idDated))];
   tabPres = [tabPres a_descProfPres(idDated)'];
end

idDated = find(a_parkDate ~= g_decArgo_dateDef);
if (~isempty(idDated))
   tabDate = [tabDate a_parkDate(idDated)'];
   tabLabel = [tabLabel repmat({'Park drift meas.'}, 1, length(idDated))];
   tabPres = [tabPres a_parkPres(idDated)'];
end

idDated = find(a_ascProfDate ~= g_decArgo_dateDef);
if (~isempty(idDated))
   tabDate = [tabDate a_ascProfDate(idDated)'];
   tabLabel = [tabLabel repmat({'Dated level of ascent profile'}, 1, length(idDated))];
   tabPres = [tabPres a_ascProfPres(idDated)'];
end
   
% sort the collected dates in chronological order
[tabDate, idSorted] = sort(tabDate);
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

if (~isempty(tabDate))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; Description; UTC time; pressure (dbar); vert. speed (cm/s); mean vert. speed (cm/s)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   for id = 1:length(tabDate)
      if (tabPres(id) == g_decArgo_presDef)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; %s; %s\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            tabLabel{id}, julian_2_gregorian_dec_argo(tabDate(id)));
      else
         if (tabVertSpeed(id) == 99999)
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; %s; %s; %.1f\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, ...
               tabLabel{id}, julian_2_gregorian_dec_argo(tabDate(id)), tabPres(id));
         else
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; %s; %s; %.1f; %.1f; %.1f\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, ...
               tabLabel{id}, julian_2_gregorian_dec_argo(tabDate(id)), tabPres(id), tabVertSpeed(id), tabMeanVertSpeed(id));
         end
      end
   end
end

return
