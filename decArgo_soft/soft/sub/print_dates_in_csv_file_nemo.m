% ------------------------------------------------------------------------------
% Print dated information in CSV file.
%
% SYNTAX :
%  print_dates_in_csv_file_nemo(a_cycleTimeData)
%
% INPUT PARAMETERS :
%   a_cycleTimeData : cycle time data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function print_dates_in_csv_file_nemo(a_cycleTimeData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;


allTabDate = [];
allTabDateAdj = [];
allTabPres = [];
allTabPresAdj = [];
allTabLabel = [];
allTabCyNum = [];

% collect park measurements
if (~isempty(a_cycleTimeData.parkDate))
   allTabDate = [allTabDate a_cycleTimeData.parkDate'];
   allTabDateAdj = [allTabDateAdj a_cycleTimeData.parkAdjDate'];
   if (isempty(a_cycleTimeData.parkAdjDate))
      allTabDateAdj = [allTabDateAdj repmat(g_decArgo_dateDef, size(a_cycleTimeData.parkDate'))];
   end
   allTabPres = [allTabPres a_cycleTimeData.parkPres'];
   if (isempty(a_cycleTimeData.parkPres))
      allTabPres = [allTabPres repmat(g_decArgo_presDef, size(a_cycleTimeData.parkDate'))];
   end
   allTabPresAdj = [allTabPresAdj a_cycleTimeData.parkAdjPres'];
   if (isempty(a_cycleTimeData.parkAdjPres))
      allTabPresAdj = [allTabPresAdj repmat(g_decArgo_presDef, size(a_cycleTimeData.parkDate'))];
   end
   allTabLabel = [allTabLabel repmat({'PARK data'}, size(a_cycleTimeData.parkDate'))];
   allTabCyNum = [allTabCyNum repmat(g_decArgo_cycleNum, size(a_cycleTimeData.parkDate'))];
end

% collect rafos measurements
if (~isempty(a_cycleTimeData.rafosDate))
   allTabDate = [allTabDate a_cycleTimeData.rafosDate'];
   allTabDateAdj = [allTabDateAdj a_cycleTimeData.rafosAdjDate'];
   if (isempty(a_cycleTimeData.rafosAdjDate))
      allTabDateAdj = [allTabDateAdj repmat(g_decArgo_dateDef, size(a_cycleTimeData.rafosDate'))];
   end
   allTabPres = [allTabPres a_cycleTimeData.rafosPres'];
   if (isempty(a_cycleTimeData.rafosPres))
      allTabPres = [allTabPres repmat(g_decArgo_presDef, size(a_cycleTimeData.rafosDate'))];
   end
   allTabPresAdj = [allTabPresAdj a_cycleTimeData.rafosAdjPres'];
   if (isempty(a_cycleTimeData.rafosAdjPres))
      allTabPresAdj = [allTabPresAdj repmat(g_decArgo_presDef, size(a_cycleTimeData.rafosDate'))];
   end
   allTabLabel = [allTabLabel repmat({'RAFOS data'}, size(a_cycleTimeData.rafosDate'))];
   allTabCyNum = [allTabCyNum repmat(g_decArgo_cycleNum, size(a_cycleTimeData.rafosDate'))];
end

% collect profile measurements
if (~isempty(a_cycleTimeData.profileDate))
   allTabDate = [allTabDate a_cycleTimeData.profileDate'];
   allTabDateAdj = [allTabDateAdj a_cycleTimeData.profileAdjDate'];
   if (isempty(a_cycleTimeData.profileAdjDate))
      allTabDateAdj = [allTabDateAdj repmat(g_decArgo_dateDef, size(a_cycleTimeData.profileDate'))];
   end
   allTabPres = [allTabPres a_cycleTimeData.profilePres'];
   if (isempty(a_cycleTimeData.profilePres))
      allTabPres = [allTabPres repmat(g_decArgo_presDef, size(a_cycleTimeData.profileDate'))];
   end
   allTabPresAdj = [allTabPresAdj a_cycleTimeData.profileAdjPres'];
   if (isempty(a_cycleTimeData.profileAdjPres))
      allTabPresAdj = [allTabPresAdj repmat(g_decArgo_presDef, size(a_cycleTimeData.profileDate'))];
   end
   allTabLabel = [allTabLabel repmat({'Profile data'}, size(a_cycleTimeData.profileDate'))];
   allTabCyNum = [allTabCyNum repmat(g_decArgo_cycleNum, size(a_cycleTimeData.profileDate'))];
end

% collect GPS dates
if (~isempty(a_cycleTimeData.gpsDate))
   allTabDate = [allTabDate a_cycleTimeData.gpsDate];
   allTabDateAdj = [allTabDateAdj a_cycleTimeData.gpsDate];
   allTabPres = [allTabPres zeros(size(a_cycleTimeData.gpsDate))];
   allTabPresAdj = [allTabPresAdj zeros(size(a_cycleTimeData.gpsDate))];
   allTabLabel = [allTabLabel repmat({'GPS fix'}, size(a_cycleTimeData.gpsDate))];
   allTabCyNum = [allTabCyNum repmat(g_decArgo_cycleNum, size(a_cycleTimeData.gpsDate))];
end

% collect Iridium dates
if (~isempty(a_cycleTimeData.iridiumDate))
   allTabDate = [allTabDate a_cycleTimeData.iridiumDate];
   allTabDateAdj = [allTabDateAdj a_cycleTimeData.iridiumDate];
   allTabPres = [allTabPres zeros(size(a_cycleTimeData.iridiumDate))];
   allTabPresAdj = [allTabPresAdj zeros(size(a_cycleTimeData.iridiumDate))];
   allTabLabel = [allTabLabel repmat({'Iridium fix'}, size(a_cycleTimeData.iridiumDate))];
   allTabCyNum = [allTabCyNum repmat(g_decArgo_cycleNum, size(a_cycleTimeData.iridiumDate))];
end

% collect misc measurements
if (~isempty(a_cycleTimeData.floatStartupDate) && (a_cycleTimeData.cycleNum == 1))
   allTabDate = [allTabDate a_cycleTimeData.floatStartupDate];
   allTabDateAdj = [allTabDateAdj a_cycleTimeData.floatStartupDate];
   allTabPres = [allTabPres 0];
   allTabPresAdj = [allTabPresAdj 0];
   allTabLabel = [allTabLabel {'Float StartUp'}];
   allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
end
if (~isempty(a_cycleTimeData.descentStartDate))
   allTabDate = [allTabDate a_cycleTimeData.descentStartDate];
   allTabDateAdj = [allTabDateAdj a_cycleTimeData.descentStartAdjDate];
   if (isempty(a_cycleTimeData.descentStartAdjDate))
      allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
   end
   allTabPres = [allTabPres g_decArgo_presDef];
   allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
   allTabLabel = [allTabLabel {'DESCENT START'}];
   allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
end
if (~isempty(a_cycleTimeData.parkStartDate))
   allTabDate = [allTabDate a_cycleTimeData.parkStartDate];
   allTabDateAdj = [allTabDateAdj a_cycleTimeData.parkStartAdjDate];
   if (isempty(a_cycleTimeData.parkStartAdjDate))
      allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
   end
   allTabPres = [allTabPres g_decArgo_presDef];
   allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
   allTabLabel = [allTabLabel {'PARK START'}];
   allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
end
if (~isempty(a_cycleTimeData.upcastStartDate))
   allTabDate = [allTabDate a_cycleTimeData.upcastStartDate];
   allTabDateAdj = [allTabDateAdj a_cycleTimeData.upcastStartAdjDate];
   if (isempty(a_cycleTimeData.upcastStartAdjDate))
      allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
   end
   allTabPres = [allTabPres g_decArgo_presDef];
   allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
   allTabLabel = [allTabLabel {'UPCAST START'}];
   allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
end
if (~isempty(a_cycleTimeData.ascentStartDate))
   allTabDate = [allTabDate a_cycleTimeData.ascentStartDate];
   allTabDateAdj = [allTabDateAdj a_cycleTimeData.ascentStartAdjDate];
   if (isempty(a_cycleTimeData.ascentStartAdjDate))
      allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
   end
   allTabPres = [allTabPres g_decArgo_presDef];
   allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
   allTabLabel = [allTabLabel {'ASCENT START'}];
   allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
end
if (~isempty(a_cycleTimeData.ascentEndDate))
   allTabDate = [allTabDate a_cycleTimeData.ascentEndDate];
   allTabDateAdj = [allTabDateAdj a_cycleTimeData.ascentEndAdjDate];
   if (isempty(a_cycleTimeData.ascentEndAdjDate))
      allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
   end
   allTabPres = [allTabPres g_decArgo_presDef];
   allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
   allTabLabel = [allTabLabel {'ASCENT END'}];
   allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
end
if (~isempty(a_cycleTimeData.surfaceStartDate))
   allTabDate = [allTabDate a_cycleTimeData.surfaceStartDate];
   allTabDateAdj = [allTabDateAdj a_cycleTimeData.surfaceStartAdjDate];
   if (isempty(a_cycleTimeData.surfaceStartAdjDate))
      allTabDateAdj = [allTabDateAdj g_decArgo_dateDef];
   end
   allTabPres = [allTabPres g_decArgo_presDef];
   allTabPresAdj = [allTabPresAdj g_decArgo_presDef];
   allTabLabel = [allTabLabel {'SURFACE START'}];
   allTabCyNum = [allTabCyNum g_decArgo_cycleNum];
end

% sort the collected dates in chronological order
if (length(find(allTabDateAdj ~= g_decArgo_dateDef)) >= length(find(allTabDateAdj == g_decArgo_dateDef)))
   [allTabDateAdj, idSorted] = sort(allTabDateAdj);
   allTabDate = allTabDate(idSorted);
else
   [allTabDate, idSorted] = sort(allTabDate);
   allTabDateAdj = allTabDateAdj(idSorted);
end
allTabPres = allTabPres(idSorted);
allTabPresAdj = allTabPresAdj(idSorted);
allTabLabel = allTabLabel(idSorted);
allTabCyNum = allTabCyNum(idSorted);

% add vertical velocities
tabVertSpeed = ones(1, length(allTabDateAdj))*99999;
id2 = 0;
for id1 = id2+1:length(allTabDateAdj)-1
   if (allTabPres(id1) ~= g_decArgo_presDef)
      idFirst = id1;
      for id2 = id1+1:length(allTabDateAdj)
         if (allTabPres(id2) ~= g_decArgo_presDef)
            if ((allTabDateAdj(idFirst) ~= g_decArgo_dateDef) && (allTabDateAdj(id2) ~= g_decArgo_dateDef))
               if ((allTabDateAdj(id2) - allTabDateAdj(idFirst)) >= 1/1440)
                  tabVertSpeed(id2) = (allTabPres(idFirst) - allTabPres(id2))*100 / ((allTabDateAdj(id2) - allTabDateAdj(idFirst))*86400);
               end
            end
            idFirst = id2;
         else
            break
         end
      end
   end
end

if (~isempty(allTabDate))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; Date type; JULD_ADJUSTED; JULD; PRES_ADJUSTED; PRES; vert. speed (cm/s)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   for idL = 1:length(allTabDateAdj)
      if (tabVertSpeed(idL) ~= 99999)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; %s; %s; %s; %.1f; %.1f; %.1f\n', ...
            g_decArgo_floatNum, allTabCyNum(idL), ...
            allTabLabel{idL}, ...
            julian_2_gregorian_dec_argo(allTabDateAdj(idL)), ...
            julian_2_gregorian_dec_argo(allTabDate(idL)), ...
            allTabPresAdj(idL), ...
            allTabPres(idL), ...
            tabVertSpeed(idL));
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Dates; %s; %s; %s; %.1f; %.1f\n', ...
            g_decArgo_floatNum, allTabCyNum(idL), ...
            allTabLabel{idL}, ...
            julian_2_gregorian_dec_argo(allTabDateAdj(idL)), ...
            julian_2_gregorian_dec_argo(allTabDate(idL)), ...
            allTabPresAdj(idL), ...
            allTabPres(idL));
      end
   end
end

if (0)
   % check date consistency
   dates = [];
   dateLabels = [];
   if (~isempty(a_cycleTimeData.floatStartupDate))
      dates = [dates a_cycleTimeData.floatStartupDate];
      dateLabels = [dateLabels {'FLOAT_STARTUP'}];
   end
   if (~isempty(a_cycleTimeData.descentStartAdjDate))
      dates = [dates a_cycleTimeData.descentStartAdjDate];
      dateLabels = [dateLabels {'DESCENT_START_ADJUSTED'}];
   elseif (~isempty(a_cycleTimeData.descentStartDate))
      dates = [dates a_cycleTimeData.descentStartDate];
      dateLabels = [dateLabels {'DESCENT_START'}];
   end
   if (~isempty(a_cycleTimeData.parkStartAdjDate))
      dates = [dates a_cycleTimeData.parkStartAdjDate];
      dateLabels = [dateLabels {'PARK_START_ADJUSTED'}];
   elseif (~isempty(a_cycleTimeData.parkStartDate))
      dates = [dates a_cycleTimeData.parkStartDate];
      dateLabels = [dateLabels {'PARK_START'}];
   end
   if (~isempty(a_cycleTimeData.rafosAdjDate))
      dates = [dates a_cycleTimeData.rafosAdjDate'];
      dateLabels = [dateLabels repmat({'RAFOS_DATE_ADJUSTED'}, 1, length(a_cycleTimeData.rafosAdjDate))];
   elseif (~isempty(a_cycleTimeData.rafosDate))
      dates = [dates a_cycleTimeData.rafosDate'];
      dateLabels = [dateLabels repmat({'RAFOS_DATE'}, 1, length(a_cycleTimeData.rafosDate))];
   end
   if (~isempty(a_cycleTimeData.upcastStartAdjDate))
      dates = [dates a_cycleTimeData.upcastStartAdjDate];
      dateLabels = [dateLabels {'UPCAST_START_ADJUSTED'}];
   elseif (~isempty(a_cycleTimeData.upcastStartDate))
      dates = [dates a_cycleTimeData.upcastStartDate];
      dateLabels = [dateLabels {'UPCAST_START'}];
   end
   if (~isempty(a_cycleTimeData.ascentStartAdjDate))
      dates = [dates a_cycleTimeData.ascentStartAdjDate];
      dateLabels = [dateLabels {'ASCENT_START_ADJUSTED'}];
   elseif (~isempty(a_cycleTimeData.ascentStartDate))
      dates = [dates a_cycleTimeData.ascentStartDate];
      dateLabels = [dateLabels {'ASCENT_START'}];
   end
   if (~isempty(a_cycleTimeData.profileAdjDate))
      dates = [dates a_cycleTimeData.profileAdjDate'];
      dateLabels = [dateLabels repmat({'PROFILE_DATE_ADJUSTED'}, 1, length(a_cycleTimeData.profileAdjDate))];
   elseif (~isempty(a_cycleTimeData.profileDate))
      dates = [dates a_cycleTimeData.profileDate'];
      dateLabels = [dateLabels repmat({'PROFILE_DATE'}, 1, length(a_cycleTimeData.profileDate))];
   end
   if (~isempty(a_cycleTimeData.ascentEndAdjDate))
      dates = [dates a_cycleTimeData.ascentEndAdjDate];
      dateLabels = [dateLabels {'ASCENT_END_ADJUSTED'}];
   elseif (~isempty(a_cycleTimeData.ascentEndDate))
      dates = [dates a_cycleTimeData.ascentEndDate];
      dateLabels = [dateLabels {'ASCENT_END'}];
   end
   if (~isempty(a_cycleTimeData.surfaceStartAdjDate))
      dates = [dates a_cycleTimeData.surfaceStartAdjDate];
      dateLabels = [dateLabels {'SURFACE_START_ADJUSTED'}];
   elseif (~isempty(a_cycleTimeData.surfaceStartDate))
      dates = [dates a_cycleTimeData.surfaceStartDate];
      dateLabels = [dateLabels {'SURFACE_START'}];
   end
   if (~isempty(a_cycleTimeData.gpsDate))
      dates = [dates a_cycleTimeData.gpsDate];
      dateLabels = [dateLabels repmat({'GPS_DATE'}, 1, length(a_cycleTimeData.gpsDate))];
   end
   if (~isempty(a_cycleTimeData.iridiumDate))
      dates = [dates a_cycleTimeData.iridiumDate];
      dateLabels = [dateLabels repmat({'IRIDIUM_DATE'}, 1, length(a_cycleTimeData.iridiumDate))];
   end
   
   % dates = [ ...
   %    a_cycleTimeData.floatStartupDate ...
   %    a_cycleTimeData.descentStartDate ...
   %    a_cycleTimeData.parkStartDate ...
   %    a_cycleTimeData.rafosDate' ...
   %    a_cycleTimeData.upcastStartDate ...
   %    a_cycleTimeData.ascentStartDate ...
   %    a_cycleTimeData.profileDate' ...
   %    a_cycleTimeData.ascentEndDate ...
   %    a_cycleTimeData.surfaceStartDate ...
   %    a_cycleTimeData.gpsDate ...
   %    a_cycleTimeData.iridiumDate ...
   %    ];
   
   if (any(diff(dates) < 0))
      fprintf('Some dates are inconsistent\n');
      errorList = find(diff(dates) < 0);
      for id = 1:length(errorList)
         fprintf('   - between %s (%s) and %s (%s)\n', ...
            dateLabels{errorList(id)}, julian_2_gregorian_dec_argo(dates(errorList(id))), ...
            dateLabels{errorList(id)+1}, julian_2_gregorian_dec_argo(dates(errorList(id)+1)));
      end
   end
end

return
