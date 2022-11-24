% ------------------------------------------------------------------------------
% Print dates in output CSV file.
%
% SYNTAX :
%  print_dates_in_csv_file_30( ...
%    a_floatClockDrift, ...
%    a_lastArgosMsgDateOfPrevCycle, ...
%    a_cycleStartDate, ...
%    a_descentToParkStartDate, ...
%    a_firstStabDate, a_firstStabPres, ...
%    a_descentToParkEndDate, ...
%    a_descentToProfStartDate, ...
%    a_descentToProfEndDate, ...
%    a_ascentStartDate, ...
%    a_ascentEndDate, ...
%    a_transStartDate, ...
%    a_argosLocDate, ...
%    a_argosDataDate, ...
%    a_firstGroundingDate, a_firstGroundingPres, ...
%    a_firstEmergencyAscentDate, a_firstEmergencyAscentPres, ...
%    a_descProfDate, a_descProfPres, ...
%    a_parkDate, a_parkTransDate, a_parkPres, ...
%    a_ascProfDate, a_ascProfPres)
%
% INPUT PARAMETERS :
%   a_floatClockDrift             : float clock drift
%   a_lastArgosMsgDateOfPrevCycle : date of the last Argos message of the
%                                   previous cycle
%   a_cycleStartDate              : cycle start date
%   a_descentToParkStartDate      : descent to park start date
%   a_firstStabDate               : first stabilisation date
%   a_firstStabPres               : first stabilisation pressure
%   a_descentToParkEndDate        : descent to park end date
%   a_descentToProfStartDate      : descent to profile start date
%   a_descentToProfEndDate        : descent to profile end date
%   a_ascentStartDate             : ascent start date
%   a_ascentEndDate               : ascent end date
%   a_transStartDate              : transmission start date
%   a_argosLocDate                : Argos location dates
%   a_argosDataDate               : Argos data message dates
%   a_firstGroundingDate          : first grounding date
%   a_firstGroundingPres          : first grounding pressure
%   a_firstEmergencyAscentDate    : first emergency ascent ascent date
%   a_firstEmergencyAscentPres    : first grounding pressure
%   a_descProfDate                : descending profile measurement dates
%   a_descProfPres                : descending profile measurement pressures
%   a_parkDate                    : parking measurement dates
%   a_parkTransDate               : transmitted (=1) or computed (=0) date of
%                                   parking measurements
%   a_parkPres                    : parking measurement pressures
%   a_ascProfDate                 : ascending profile measurement dates
%   a_ascProfPres                 : ascending profile measurement pressures
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/10/2015 - RNU - creation
% ------------------------------------------------------------------------------
function print_dates_in_csv_file_30( ...
   a_floatClockDrift, ...
   a_lastArgosMsgDateOfPrevCycle, ...
   a_cycleStartDate, ...
   a_descentToParkStartDate, ...
   a_firstStabDate, a_firstStabPres, ...
   a_descentToParkEndDate, ...
   a_descentToProfStartDate, ...
   a_descentToProfEndDate, ...
   a_ascentStartDate, ...
   a_ascentEndDate, ...
   a_transStartDate, ...
   a_argosLocDate, ...
   a_argosDataDate, ...
   a_firstGroundingDate, a_firstGroundingPres, ...
   a_firstEmergencyAscentDate, a_firstEmergencyAscentPres, ...
   a_descProfDate, a_descProfPres, ...
   a_parkDate, a_parkTransDate, a_parkPres, ...
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


tabDateFloat = [];
tabDateUtc = [];
tabLabel = [];
tabPres = [];

% round float drift to minutes
floatClockDriftCor = round(a_floatClockDrift*1440)/1440;

% cycle timings
if (a_lastArgosMsgDateOfPrevCycle ~= g_decArgo_dateDef)
   tabDateFloat(end+1) = g_decArgo_dateDef;
   tabDateUtc(end+1) = a_lastArgosMsgDateOfPrevCycle;
   tabLabel{end+1} = 'Date of last Argos message of previous cycle';
   tabPres(end+1) = g_decArgo_presDef;
end
if (a_cycleStartDate ~= g_decArgo_dateDef)
   tabDateFloat(end+1) = a_cycleStartDate+floatClockDriftCor;
   tabDateUtc(end+1) = a_cycleStartDate;
   tabLabel{end+1} = 'CYCLE_START_TIME';
   tabPres(end+1) = g_decArgo_presDef;
end
if (a_descentToParkStartDate ~= g_decArgo_dateDef)
   tabDateFloat(end+1) = a_descentToParkStartDate+floatClockDriftCor;
   tabDateUtc(end+1) = a_descentToParkStartDate;
   tabLabel{end+1} = 'DESCENT_TO_PARK_START_TIME';
   tabPres(end+1) = g_decArgo_presDef;
end
if (a_firstStabDate ~= g_decArgo_dateDef)
   tabDateFloat(end+1) = a_firstStabDate+floatClockDriftCor;
   tabDateUtc(end+1) = a_firstStabDate;
   tabLabel{end+1} = 'FIRST_STABILIZATION_TIME';
   tabPres(end+1) = a_firstStabPres;
end
if (a_descentToParkEndDate ~= g_decArgo_dateDef)
   tabDateFloat(end+1) = a_descentToParkEndDate+floatClockDriftCor;
   tabDateUtc(end+1) = a_descentToParkEndDate;
   tabLabel{end+1} = 'PARK_START_TIME';
   tabPres(end+1) = g_decArgo_presDef;
end
if (a_descentToProfStartDate ~= g_decArgo_dateDef)
   tabDateFloat(end+1) = a_descentToProfStartDate+floatClockDriftCor;
   tabDateUtc(end+1) = a_descentToProfStartDate;
   tabLabel{end+1} = 'PARK_END_TIME';
   tabPres(end+1) = g_decArgo_presDef;
end
if (a_descentToProfEndDate ~= g_decArgo_dateDef)
   tabDateFloat(end+1) = a_descentToProfEndDate+floatClockDriftCor;
   tabDateUtc(end+1) = a_descentToProfEndDate;
   tabLabel{end+1} = 'DEEP_PARK_START_TIME';
   tabPres(end+1) = g_decArgo_presDef;
end
if (a_ascentStartDate ~= g_decArgo_dateDef)
   tabDateFloat(end+1) = a_ascentStartDate+floatClockDriftCor;
   tabDateUtc(end+1) = a_ascentStartDate;
   tabLabel{end+1} = 'ASCENT_START_TIME';
   tabPres(end+1) = g_decArgo_presDef;
end
if (a_ascentEndDate ~= g_decArgo_dateDef)
   tabDateFloat(end+1) = a_ascentEndDate+floatClockDriftCor;
   tabDateUtc(end+1) = a_ascentEndDate;
   tabLabel{end+1} = 'ASCENT_END_TIME';
   tabPres(end+1) = g_decArgo_presDef;
end
if (a_transStartDate ~= g_decArgo_dateDef)
   tabDateFloat(end+1) = a_transStartDate+floatClockDriftCor;
   tabDateUtc(end+1) = a_transStartDate;
   tabLabel{end+1} = 'TRANSMISSION_START_TIME';
   tabPres(end+1) = g_decArgo_presDef;
end

firstArgosDate = min([a_argosLocDate; a_argosDataDate]);
lastArgosDate = max([a_argosLocDate; a_argosDataDate]);

tabDateFloat(end+1) = g_decArgo_dateDef;
tabDateUtc(end+1) = firstArgosDate;
tabLabel{end+1} = 'Date of first Argos message received';
tabPres(end+1) = g_decArgo_presDef;

if (~isempty(a_argosLocDate))
   tabDateFloat(end+1) = g_decArgo_dateDef;
   tabDateUtc(end+1) = min(a_argosLocDate);
   tabLabel{end+1} = 'Date of first Argos location';
   tabPres(end+1) = g_decArgo_presDef;
   
   tabDateFloat(end+1) = g_decArgo_dateDef;
   tabDateUtc(end+1) = max(a_argosLocDate);
   tabLabel{end+1} = 'Date of last Argos location';
   tabPres(end+1) = g_decArgo_presDef;
end

tabDateFloat(end+1) = g_decArgo_dateDef;
tabDateUtc(end+1) = lastArgosDate;
tabLabel{end+1} = 'Date of last Argos message received';
tabPres(end+1) = g_decArgo_presDef;

if (a_firstGroundingDate ~= g_decArgo_dateDef)
   tabDateFloat(end+1) = a_firstGroundingDate+floatClockDriftCor;
   tabDateUtc(end+1) = a_firstGroundingDate;
   tabLabel{end+1} = 'FIRST_GROUNDING_TIME';
   tabPres(end+1) = a_firstGroundingPres;
end
if (a_firstEmergencyAscentDate ~= g_decArgo_dateDef)
   tabDateFloat(end+1) = a_firstEmergencyAscentDate+floatClockDriftCor;
   tabDateUtc(end+1) = a_firstEmergencyAscentDate;
   tabLabel{end+1} = 'FIRST_EMERGENCY_ASCENT_TIME';
   tabPres(end+1) = a_firstEmergencyAscentPres;
end

% CTD dated measurements
idDated = find(a_descProfDate ~= g_decArgo_dateDef);
if (~isempty(idDated))
   descDates = a_descProfDate(idDated);
   descPres = a_descProfPres(idDated);
   [descDates, idSort] = sort(descDates);
   descPres = descPres(idSort);
   for idL = 1:length(descDates)
      tabDateFloat(end+1) = descDates(idL)+floatClockDriftCor;
      tabDateUtc(end+1) = descDates(idL);
      tabLabel{end+1} = sprintf('Desc. profile dated meas. #%d', idL);
      tabPres(end+1) = descPres(idL);
   end
end

idDated = find(a_parkDate ~= g_decArgo_dateDef);
if (~isempty(idDated))
   driftDates = a_parkDate(idDated);
   driftPres = a_parkPres(idDated);
   driftTransDates = a_parkTransDate(idDated);
   [driftDates, idSort] = sort(driftDates);
   driftPres = driftPres(idSort);
   driftTransDates = driftTransDates(idSort);
   for idL = 1:length(driftDates)
      if (driftTransDates(idL) == 1)
         trans = 'T';
      else
         trans = 'C';
      end
      tabDateFloat(end+1) = driftDates(idL)+floatClockDriftCor;
      tabDateUtc(end+1) = driftDates(idL);
      tabLabel{end+1} = sprintf('Park drift meas. (%c) #%d', trans, idL);
      tabPres(end+1) = driftPres(idL);
   end
end

idDated = find(a_ascProfDate ~= g_decArgo_dateDef);
if (~isempty(idDated))
   ascDates = a_ascProfDate(idDated);
   ascPres = a_ascProfPres(idDated);
   [ascDates, idSort] = sort(ascDates);
   ascPres = ascPres(idSort);
   for idL = 1:length(ascDates)
      tabDateFloat(end+1) = ascDates(idL)+floatClockDriftCor;
      tabDateUtc(end+1) = ascDates(idL);
      tabLabel{end+1} = sprintf('Asc. profile dated meas. #%d', idL);
      tabPres(end+1) = ascPres(idL);
   end
end
   
% sort the collected dates in chronological order
[tabDateUtc, idSorted] = sort(tabDateUtc);
tabDateFloat = tabDateFloat(idSorted);
tabLabel = tabLabel(idSorted);
tabPres = tabPres(idSorted);

% add vertical velocities
tabVertSpeed = ones(1, length(tabDateUtc))*99999;
tabMeanVertSpeed = ones(1, length(tabDateUtc))*99999;
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
         if (tabDateUtc(idSlice(idPres(idP))) ~= tabDateUtc(idSlice(idPres(idP-1))))
            vertSpeed = (tabPres(idSlice(idPres(idP)))-tabPres(idSlice(idPres(idP-1))))*100 / ...
               ((tabDateUtc(idSlice(idPres(idP)))-tabDateUtc(idSlice(idPres(idP-1))))*86400);
            tabVertSpeed(idF1+idP) = sign*vertSpeed;
         end
         if (tabDateUtc(idSlice(idPres(idP))) ~= tabDateUtc(idSlice(idPres(1))))
            meanVertSpeed = (tabPres(idSlice(idPres(idP)))-tabPres(idSlice(idPres(1))))*100 / ...
               ((tabDateUtc(idSlice(idPres(idP)))-tabDateUtc(idSlice(idPres(1))))*86400);
            tabMeanVertSpeed(idF1+idP) = sign*meanVertSpeed;
         end
      end
   end
end

if (~isempty(tabDateUtc))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; DATED INFORMATION\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; Float clock drift; %s; =>; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      format_time_dec_argo(a_floatClockDrift*24), format_time_dec_argo(floatClockDriftCor*24));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; Description; float time; UTC time; pressure (dbar); vert. speed (cm/s); mean vert. speed (cm/s)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   for id = 1:length(tabDateUtc)
      if (tabDateFloat(id) == g_decArgo_dateDef)
         if (tabPres(id) == g_decArgo_presDef)
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; %s; ; %s\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, ...
               tabLabel{id}, ...
               julian_2_gregorian_dec_argo(tabDateUtc(id)));
         else
            if (tabVertSpeed(id) == 99999)
               fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; %s; ; %s; %.1f\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  tabLabel{id}, ...
                  julian_2_gregorian_dec_argo(tabDateUtc(id)), ...
                  tabPres(id));
            else
               fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; %s; ; %s; %.1f; %.1f; %.1f\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  tabLabel{id}, ...
                  julian_2_gregorian_dec_argo(tabDateUtc(id)), ...
                  tabPres(id), tabVertSpeed(id), tabMeanVertSpeed(id));
            end
         end
      else
         if (tabPres(id) == g_decArgo_presDef)
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; %s; %s; %s\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, ...
               tabLabel{id}, ...
               julian_2_gregorian_dec_argo(tabDateFloat(id)), ...
               julian_2_gregorian_dec_argo(tabDateUtc(id)));
         else
            if (tabVertSpeed(id) == 99999)
               fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; %s; %s; %s; %.1f\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  tabLabel{id}, ...
                  julian_2_gregorian_dec_argo(tabDateFloat(id)), ...
                  julian_2_gregorian_dec_argo(tabDateUtc(id)), ...
                  tabPres(id));
            else
               fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; %s; %s; %s; %.1f; %.1f; %.1f\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  tabLabel{id}, ...
                  julian_2_gregorian_dec_argo(tabDateFloat(id)), ...
                  julian_2_gregorian_dec_argo(tabDateUtc(id)), ...
                  tabPres(id), tabVertSpeed(id), tabMeanVertSpeed(id));
            end
         end
      end
   end
end

return;
