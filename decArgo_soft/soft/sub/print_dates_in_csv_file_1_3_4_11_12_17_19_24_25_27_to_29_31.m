% ------------------------------------------------------------------------------
% Print dates in output CSV file.
%
% SYNTAX :
%  print_dates_in_csv_file_1_3_4_11_12_17_19_24_25_27_to_29_31( ...
%    a_floatClockDrift, a_lastArgosMsgDateOfPrevCycle, ...
%    a_descentStartDate, a_firstStabDate, a_firstStabPres, a_descentEndDate, ...
%    a_descentToProfStartDate, a_descentToProfEndDate, a_ascentStartDate, ...
%    a_ascentEndDate, a_transStartDate, a_argosLocDate, a_argosDataDate, ...
%    a_descProfDate, a_descProfPres, ...
%    a_parkDate, a_parkTransDate, a_parkPres, ...
%    a_ascProfDate, a_ascProfPres)
%
% INPUT PARAMETERS :
%   a_floatClockDrift             : float clock drift
%   a_lastArgosMsgDateOfPrevCycle : date of the last Argos message of the
%                                   previous cycle
%   a_descentStartDate            : descent start date
%   a_firstStabDate               : first stabilisation date
%   a_firstStabPres               : first stabilisation pressure (dbar)
%   a_descentEndDate              : descent end date
%   a_descentToProfStartDate      : descent to profile start date
%   a_descentToProfEndDate        : descent to profile end date
%   a_ascentStartDate             : ascent start date
%   a_ascentEndDate               : ascent end date
%   a_transStartDate              : transmission start date
%   a_argosLocDate                : Argos location dates
%   a_argosDataDate               : Argos data message dates
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
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function print_dates_in_csv_file_1_3_4_11_12_17_19_24_25_27_to_29_31( ...
   a_floatClockDrift, a_lastArgosMsgDateOfPrevCycle, ...
   a_descentStartDate, a_firstStabDate, a_firstStabPres, a_descentEndDate, ...
   a_descentToProfStartDate, a_descentToProfEndDate, a_ascentStartDate, ...
   a_ascentEndDate, a_transStartDate, a_argosLocDate, a_argosDataDate, ...
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

fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; DATED INFORMATION\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum);

floatClockDrift = round(a_floatClockDrift*1440)/1440;
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; Float clock drift; %s; =>; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, ...
   format_time_dec_argo(a_floatClockDrift*24), format_time_dec_argo(floatClockDrift*24));

fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; Description; float time; UTC time; pressure (dbar)\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum);

fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; Date of last Argos message of previous cycle; ; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, julian_2_gregorian_dec_argo(a_lastArgosMsgDateOfPrevCycle));
if (a_descentStartDate ~= g_decArgo_dateDef)
   descentStartDateFtStr = julian_2_gregorian_dec_argo(a_descentStartDate+floatClockDrift);
   descentStartDateUtcStr = julian_2_gregorian_dec_argo(a_descentStartDate);
else
   descentStartDateFtStr = julian_2_gregorian_dec_argo(a_descentStartDate);
   descentStartDateUtcStr = julian_2_gregorian_dec_argo(g_decArgo_dateDef);
end
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; DESCENT START DATE; %s; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, descentStartDateFtStr, descentStartDateUtcStr);
if (a_firstStabDate ~= g_decArgo_dateDef)
   firstStabDateFtStr = julian_2_gregorian_dec_argo(a_firstStabDate+floatClockDrift);
   firstStabDateUtcStr = julian_2_gregorian_dec_argo(a_firstStabDate);
else
   firstStabDateFtStr = julian_2_gregorian_dec_argo(a_firstStabDate);
   firstStabDateUtcStr = julian_2_gregorian_dec_argo(g_decArgo_dateDef);
end
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; FIRST STAB DATE; %s; %s; %.1f; dbar\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, firstStabDateFtStr, firstStabDateUtcStr, a_firstStabPres);

idDescDatedMes = find(a_descProfDate ~= g_decArgo_dateDef);
if (~isempty(idDescDatedMes))
   descDates = a_descProfDate(idDescDatedMes);
   descPres = a_descProfPres(idDescDatedMes);
   [descDates, idSort] = sort(descDates);
   descPres = descPres(idSort);
   for idMes = 1:length(descDates)
      if (descDates(idMes) ~= g_decArgo_dateDef)
         descDatesFtStr = julian_2_gregorian_dec_argo(descDates(idMes)+floatClockDrift);
         descDatesUtcStr = julian_2_gregorian_dec_argo(descDates(idMes));
      else
         descDatesFtStr = julian_2_gregorian_dec_argo(descDates(idMes));
         descDatesUtcStr = julian_2_gregorian_dec_argo(g_decArgo_dateDef);
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; Desc. profile dated meas. #%d; %s; %s; %.1f; dbar\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idMes, descDatesFtStr, descDatesUtcStr, descPres(idMes));
   end
end

if (a_descentEndDate ~= g_decArgo_dateDef)
   descentEndDateFtStr = julian_2_gregorian_dec_argo(a_descentEndDate+floatClockDrift);
   descentEndDateUtcStr = julian_2_gregorian_dec_argo(a_descentEndDate);
else
   descentEndDateFtStr = julian_2_gregorian_dec_argo(a_descentEndDate);
   descentEndDateUtcStr = julian_2_gregorian_dec_argo(g_decArgo_dateDef);
end
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; DESCENT END DATE; %s; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, descentEndDateFtStr, descentEndDateUtcStr);

idDriftDatedMes = find(a_parkPres ~= g_decArgo_presDef);
if (~isempty(idDriftDatedMes))
   driftDates = a_parkDate(idDriftDatedMes);
   driftPres = a_parkPres(idDriftDatedMes);
   driftTransDates = a_parkTransDate(idDriftDatedMes);
   [driftDates, idSort] = sort(driftDates);
   driftPres = driftPres(idSort);
   driftTransDates = driftTransDates(idSort);
   for idMes = 1:length(driftDates)
      if (driftTransDates(idMes) == 1)
         trans = 'T';
      else
         trans = 'C';
      end
      if (driftDates(idMes) ~= g_decArgo_dateDef)
         driftDatesFtStr = julian_2_gregorian_dec_argo(driftDates(idMes)+floatClockDrift);
         driftDatesUtcStr = julian_2_gregorian_dec_argo(driftDates(idMes));
      else
         driftDatesFtStr = julian_2_gregorian_dec_argo(driftDates(idMes));
         driftDatesUtcStr = julian_2_gregorian_dec_argo(g_decArgo_dateDef);
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; Drift meas. (%c) #%d; %s; %s; %.1f; dbar\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         trans, idMes, driftDatesFtStr, driftDatesUtcStr, driftPres(idMes));
   end
end

if (a_descentToProfStartDate ~= g_decArgo_dateDef)
   descentToProfStartDateFtStr = julian_2_gregorian_dec_argo(a_descentToProfStartDate+floatClockDrift);
   descentToProfStartDateUtcStr = julian_2_gregorian_dec_argo(a_descentToProfStartDate);
else
   descentToProfStartDateFtStr = julian_2_gregorian_dec_argo(a_descentToProfStartDate);
   descentToProfStartDateUtcStr = julian_2_gregorian_dec_argo(g_decArgo_dateDef);
end
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; DESCENT TO PROF START DATE; %s; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, ...
   descentToProfStartDateFtStr, descentToProfStartDateUtcStr);
if (a_descentToProfEndDate ~= g_decArgo_dateDef)
   descentToProfEndDateFtStr = julian_2_gregorian_dec_argo(a_descentToProfEndDate+floatClockDrift);
   descentToProfEndDateUtcStr = julian_2_gregorian_dec_argo(a_descentToProfEndDate);
else
   descentToProfEndDateFtStr = julian_2_gregorian_dec_argo(a_descentToProfEndDate);
   descentToProfEndDateUtcStr = julian_2_gregorian_dec_argo(g_decArgo_dateDef);
end
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; DESCENT TO PROF END DATE; %s; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, ...
   descentToProfEndDateFtStr, descentToProfEndDateUtcStr);
if (a_ascentStartDate ~= g_decArgo_dateDef)
   ascentStartDateFtStr = julian_2_gregorian_dec_argo(a_ascentStartDate+floatClockDrift);
   ascentStartDateUtcStr = julian_2_gregorian_dec_argo(a_ascentStartDate);
else
   ascentStartDateFtStr = julian_2_gregorian_dec_argo(a_ascentStartDate);
   ascentStartDateUtcStr = julian_2_gregorian_dec_argo(g_decArgo_dateDef);
end
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; ASCENT START DATE; %s; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, ...
   ascentStartDateFtStr, ascentStartDateUtcStr);

idAscDatedMes = find(a_ascProfDate ~= g_decArgo_dateDef);
if (~isempty(idAscDatedMes))
   ascDates = a_ascProfDate(idAscDatedMes);
   ascPres = a_ascProfPres(idAscDatedMes);
   [ascDates, idSort] = sort(ascDates);
   ascPres = ascPres(idSort);
   for idMes = 1:length(ascDates)
      if (ascDates(idMes) ~= g_decArgo_dateDef)
         ascDatesFtStr = julian_2_gregorian_dec_argo(ascDates(idMes)+floatClockDrift);
         ascDatesUtcStr = julian_2_gregorian_dec_argo(ascDates(idMes));
      else
         ascDatesFtStr = julian_2_gregorian_dec_argo(ascDates(idMes));
         ascDatesUtcStr = julian_2_gregorian_dec_argo(g_decArgo_dateDef);
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; Asc. profile dated meas. #%d; %s; %s; %.1f; dbar\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idMes, ...
         ascDatesFtStr, ascDatesUtcStr, ascPres(idMes));
   end
end

if (a_ascentEndDate ~= g_decArgo_dateDef)
   ascentEndDateFtStr = julian_2_gregorian_dec_argo(a_ascentEndDate+floatClockDrift);
   ascentEndDateUtcStr = julian_2_gregorian_dec_argo(a_ascentEndDate);
else
   ascentEndDateFtStr = julian_2_gregorian_dec_argo(a_ascentEndDate);
   ascentEndDateUtcStr = julian_2_gregorian_dec_argo(g_decArgo_dateDef);
end
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; ASCENT END DATE; %s; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, ...
   ascentEndDateFtStr, ascentEndDateUtcStr);
if (a_transStartDate ~= g_decArgo_dateDef)
   transStartDateFtStr = julian_2_gregorian_dec_argo(a_transStartDate+floatClockDrift);
   transStartDateUtcStr = julian_2_gregorian_dec_argo(a_transStartDate);
else
   transStartDateFtStr = julian_2_gregorian_dec_argo(a_transStartDate);
   transStartDateUtcStr = julian_2_gregorian_dec_argo(g_decArgo_dateDef);
end
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; TRANSMISSION START DATE; %s; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, ...
   transStartDateFtStr, transStartDateUtcStr);

firstArgosDate = min([a_argosLocDate; a_argosDataDate]);
lastArgosDate = max([a_argosLocDate; a_argosDataDate]);
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; Date of first Argos message received; ; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, julian_2_gregorian_dec_argo(firstArgosDate));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; Date of first Argos location; ; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, julian_2_gregorian_dec_argo(min(a_argosLocDate)));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; Date of last Argos location; ; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, julian_2_gregorian_dec_argo(max(a_argosLocDate)));
fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; Date of last Argos message received; ; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, julian_2_gregorian_dec_argo(lastArgosDate));

return;
