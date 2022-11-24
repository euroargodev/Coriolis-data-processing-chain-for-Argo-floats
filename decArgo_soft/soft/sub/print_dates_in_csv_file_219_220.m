% ------------------------------------------------------------------------------
% Print dates in output CSV file.
%
% SYNTAX :
%  print_dates_in_csv_file_219_220( ...
%    a_cycleStartDate, ...
%    a_descentStartDate, ...
%    a_descentEndDate, ...
%    a_ascentStartDate, ...
%    a_ascentEndDate, ...
%    a_transStartDate, ...
%    a_gpsDates)
%
% INPUT PARAMETERS :
%   a_cycleStartDate   : cycle start date
%   a_descentStartDate : descent to park start date
%   a_descentEndDate   : descent to park end date
%   a_ascentStartDate  : ascent start date
%   a_ascentEndDate    : ascent end date
%   a_transStartDate   : transmission start date
%   a_gpsDates         : dates associated to the GPS location
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/17/2019 - RNU - creation
% ------------------------------------------------------------------------------
function print_dates_in_csv_file_219_220( ...
   a_cycleStartDate, ...
   a_descentStartDate, ...
   a_descentEndDate, ...
   a_ascentStartDate, ...
   a_ascentEndDate, ...
   a_transStartDate, ...
   a_gpsDates)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
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
if (~isempty(a_descentStartDate))
   tabDate(end+1) = a_descentStartDate;
   tabLabel{end+1} = 'DESCENT_START_TIME';
   tabPres(end+1) = g_decArgo_presDef;
end
if (~isempty(a_descentEndDate))
   tabDate(end+1) = a_descentEndDate;
   tabLabel{end+1} = 'DESCENT_END_TIME';
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
if (~isempty(a_gpsDates))
   for id = 1:length(a_gpsDates)
      tabDate(end+1) = a_gpsDates(id);
      tabLabel{end+1} = 'GPS_LOCATION_TIME';
      tabPres(end+1) = g_decArgo_presDef;
   end
end

% sort the collected dates in chronological order
[tabDate, idSorted] = sort(tabDate);
tabLabel = tabLabel(idSorted);
tabPres = tabPres(idSorted);

% add vertical velocities
tabVertSpeed = ones(1, length(tabDate))*99999;
tabMeanVertSpeed = ones(1, length(tabDate))*99999;
for id = 1:2
   if (id == 1)
      idF1 = find (strcmp(tabLabel, 'DESCENT_START_TIME') == 1);
      idF2 = find (strcmp(tabLabel, 'DESCENT_END_TIME') == 1);
      sign = 1;
   elseif (id == 2)
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
