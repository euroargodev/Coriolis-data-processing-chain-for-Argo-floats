% ------------------------------------------------------------------------------
% Print time information in output CSV file.
%
% SYNTAX :
%  print_dates_in_csv_file_ir_rudics_cts5_usea(a_timeDataFromApmtTech, ...
%    a_apmtCtd, a_apmtDo, a_apmtEco, a_apmtOcr, a_uvpLpmData, a_uvpBlackData)
%
% INPUT PARAMETERS :
%   a_timeDataFromApmtTech : times from APMT technical data
%   a_apmtCtd              : CTS5-USEA CTD data
%   a_apmtDo               : CTS5-USEA DO data
%   a_apmtEco              : CTS5-USEA ECO data
%   a_apmtOcr              : CTS5-USEA OCR data
%   a_uvpLpmData           : CTS5-USEA UVP-LPM data
%   a_uvpBlackData         : CTS5-USEA UVP-BLACK data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function print_dates_in_csv_file_ir_rudics_cts5_usea(a_timeDataFromApmtTech, ...
   a_apmtCtd, a_apmtDo, a_apmtEco, a_apmtOcr, a_uvpLpmData, a_uvpBlackData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloatStr;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
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
sensorDataList = [ ...
   {'a_apmtCtd'} ...
   {'a_apmtDo'} ...
   {'a_apmtEco'} ...
   {'a_apmtOcr'} ...
   ];
sensorNameList = [ ...
   {'CTD'} ...
   {'DO'} ...
   {'ECO'} ...
   {'OCR'} ...
   ];
for idS = 1:4
   dataSensor = eval(sensorDataList{idS});
   for idP = 1:length(dataSensor)
      
      dataStruct = dataSensor{idP};
      
      if (strcmp(dataStruct.treat, '(SS)'))
         label = 'Subsurface measurement';
      else
         label = sprintf('Dated %s meas. %s', sensorNameList{idS}, dataStruct.phase);
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
