% ------------------------------------------------------------------------------
% Print time data in output CSV file.
%
% SYNTAX :
%  print_time_data_in_csv_file(a_timeData, ...
%    a_argosLocDate, a_argosLocLon, a_argosLocLat, ...
%    a_argosLocAcc, a_argosLocSat, a_argosLocQc)
%
% INPUT PARAMETERS :
%   a_timeData     : time data structure
%   a_argosLocDate : Argos location dates
%   a_argosLocLon  : Argos location longitudes
%   a_argosLocLat  : Argos location latitudes
%   a_argosLocAcc  : Argos location accuracies
%   a_argosLocSat  : Argos location satellites
%   a_argosLocQc   : Argos location QCs
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/23/2015 - RNU - creation
% ------------------------------------------------------------------------------
function print_time_data_in_csv_file(a_timeData, ...
   a_argosLocDate, a_argosLocLon, a_argosLocLat, ...
   a_argosLocAcc, a_argosLocSat, a_argosLocQc)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% global time status
global g_JULD_STATUS_fill_value;
global g_JULD_STATUS_4;

% default values
global g_decArgo_dateDef;


fprintf(g_decArgo_outputCsvFileId, ...
   '%d;%d;Dates;-;DATED INFORMATION;RTC time;Time (UTC);Status;Lon/PRES;Lat;Sat;Acc;Qc\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum);

tabLabel = [];
tabTimes = [];
if (~isempty(a_timeData.cycleNum))
   idCy = find([a_timeData.cycleNum] == g_decArgo_cycleNum);
   if (~isempty(idCy))
      
      fprintf(g_decArgo_outputCsvFileId, ...
         '%d;%d;Dates;-;Cycle clock offset; %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         format_time_dec_argo(a_timeData.cycleTime(idCy).clockOffset*24));
      
      lastMsgTimeOfPrevCy = g_decArgo_dateDef;
      lastMsgTimeOfPrevCyStatus = g_JULD_STATUS_fill_value;
      idPrevCy = find([a_timeData.cycleNum] == g_decArgo_cycleNum-1);
      if (~isempty(idPrevCy))
         lastMsgTimeOfPrevCy = a_timeData.cycleTime(idPrevCy).lastMsgTime;
         lastMsgTimeOfPrevCyStatus = g_JULD_STATUS_4;
      end
      fprintf(g_decArgo_outputCsvFileId, ...
         '%d;%d;Dates;-;Last message time of previous cycle;; %s;%c\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         julian_2_gregorian_dec_argo(lastMsgTimeOfPrevCy), ...
         lastMsgTimeOfPrevCyStatus);
      
      if (g_decArgo_cycleNum > 0)
         
         label = sprintf( ...
            '%d;%d;Dates;-;Descent start time; %s; %s;%c', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).descentStartTime), ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).descentStartTimeAdj), ...
            a_timeData.cycleTime(idCy).descentStartTimeStatus);
         tabLabel{end+1} = label;
         tabTimes(end+1) = a_timeData.cycleTime(idCy).descentStartTimeAdj;
         
         if (~isempty(a_timeData.cycleTime(idCy).descPresMark))
            descPresMark = a_timeData.cycleTime(idCy).descPresMark;
            if (any(descPresMark.dates ~= g_decArgo_dateDef))
               for idPM = 2:length(descPresMark.dates)
                  if (~isempty(descPresMark.dataAdj))
                     label = sprintf( ...
                        '%d;%d;Dates;-;Desc. pressure mark #%d; %s; %s;%c;%d', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        idPM, ...
                        julian_2_gregorian_dec_argo(descPresMark.dates(idPM)), ...
                        julian_2_gregorian_dec_argo(descPresMark.datesAdj(idPM)), ...
                        descPresMark.datesStatus(idPM), ...
                        descPresMark.dataAdj(idPM));
                  else
                     label = sprintf( ...
                        '%d;%d;Dates;-;Desc. pressure mark #%d; %s; %s;%c;%d', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, ...
                        idPM, ...
                        julian_2_gregorian_dec_argo(descPresMark.dates(idPM)), ...
                        julian_2_gregorian_dec_argo(descPresMark.datesAdj(idPM)), ...
                        descPresMark.datesStatus(idPM), ...
                        descPresMark.data(idPM));
                  end
                  tabLabel{end+1} = label;
                  tabTimes(end+1) = descPresMark.datesAdj(idPM);
               end
            end
         end
         
         label = sprintf( ...
            '%d;%d;Dates;-;Park end time; %s; %s;%c', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).parkEndTime), ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).parkEndTimeAdj), ...
            a_timeData.cycleTime(idCy).parkEndTimeStatus);
         tabLabel{end+1} = label;
         tabTimes(end+1) = a_timeData.cycleTime(idCy).parkEndTimeAdj;
         
         label = sprintf( ...
            '%d;%d;Dates;-;Deep descent end time; %s; %s;%c', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).deepDescentEndTime), ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).deepDescentEndTimeAdj), ...
            a_timeData.cycleTime(idCy).deepDescentEndTimeStatus);
         tabLabel{end+1} = label;
         tabTimes(end+1) = a_timeData.cycleTime(idCy).deepDescentEndTimeAdj;
         
         label = sprintf( ...
            '%d;%d;Dates;-;DOWN_TIME end time; %s; %s;%c', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).downTimeEnd), ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).downTimeEndAdj), ...
            a_timeData.cycleTime(idCy).downTimeEndStatus);
         tabLabel{end+1} = label;
         tabTimes(end+1) = a_timeData.cycleTime(idCy).downTimeEndAdj;
         
         label = sprintf( ...
            '%d;%d;Dates;-;Ascent start time; %s; %s;%c', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).ascentStartTime), ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).ascentStartTimeAdj), ...
            a_timeData.cycleTime(idCy).ascentStartTimeStatus);
         tabLabel{end+1} = label;
         tabTimes(end+1) = a_timeData.cycleTime(idCy).ascentStartTimeAdj;
         
         label = sprintf( ...
            '%d;%d;Dates;-;Ascent start time (from float); %s; %s;%c', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).ascentStartTimeFloat), ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).ascentStartTimeFloatAdj), ...
            a_timeData.cycleTime(idCy).ascentStartTimeFloatStatus);
         tabLabel{end+1} = label;
         tabTimes(end+1) = a_timeData.cycleTime(idCy).ascentStartTimeFloatAdj;
         
         label = sprintf( ...
            '%d;%d;Dates;-;Ascent end time; %s; %s;%c', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).ascentEndTime), ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).ascentEndTimeAdj), ...
            a_timeData.cycleTime(idCy).ascentEndTimeStatus);
         tabLabel{end+1} = label;
         tabTimes(end+1) = a_timeData.cycleTime(idCy).ascentEndTimeAdj;
         
         label = sprintf( ...
            '%d;%d;Dates;-;Ascent end time (from float); %s; %s;%c', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).ascentEndTimeFloat), ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).ascentEndTimeFloatAdj), ...
            a_timeData.cycleTime(idCy).ascentEndTimeFloatStatus);
         tabLabel{end+1} = label;
         tabTimes(end+1) = a_timeData.cycleTime(idCy).ascentEndTimeFloatAdj;
         
         label = sprintf( ...
            '%d;%d;Dates;-;Trans start time; %s; %s;%c', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).transStartTime), ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).transStartTimeAdj), ...
            a_timeData.cycleTime(idCy).transStartTimeStatus);
         tabLabel{end+1} = label;
         tabTimes(end+1) = a_timeData.cycleTime(idCy).transStartTimeAdj;
         
         label = sprintf( ...
            '%d;%d;Dates;-;Trans start time (from float); %s; %s;%c', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).transStartTimeFloat), ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).transStartTimeFloatAdj), ...
            a_timeData.cycleTime(idCy).transStartTimeFloatStatus);
         tabLabel{end+1} = label;
         tabTimes(end+1) = a_timeData.cycleTime(idCy).transStartTimeFloatAdj;
         
         label = sprintf( ...
            '%d;%d;Dates;-;Trans end time; %s; %s;%c', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).transEndTime), ...
            julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).transEndTimeAdj), ...
            a_timeData.cycleTime(idCy).transEndTimeStatus);
         tabLabel{end+1} = label;
         tabTimes(end+1) = a_timeData.cycleTime(idCy).transEndTimeAdj;
         
      end
      
      label = sprintf( ...
         '%d;%d;Dates;-;First msg time;; %s;%c', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).firstMsgTime), ...
         g_JULD_STATUS_4);
      tabLabel{end+1} = label;
      tabTimes(end+1) = a_timeData.cycleTime(idCy).firstMsgTime;
      
      for idL = 1:length(a_argosLocDate)
         label = sprintf( ...
            '%d;%d;Dates;-;Argos location #%d;; %s;%c;%.4f;%.4f;%c;%c;%c', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            idL, julian_2_gregorian_dec_argo(a_argosLocDate(idL)), ...
            g_JULD_STATUS_4, ...
            a_argosLocLon(idL), a_argosLocLat(idL), ...
            a_argosLocSat(idL), a_argosLocAcc(idL), a_argosLocQc(idL));
         tabLabel{end+1} = label;
         tabTimes(end+1) = a_argosLocDate(idL);
      end
      
      label = sprintf( ...
         '%d;%d;Dates;-;Last msg time;; %s;%c', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         julian_2_gregorian_dec_argo(a_timeData.cycleTime(idCy).lastMsgTime), ...
         g_JULD_STATUS_4);
      tabLabel{end+1} = label;
      tabTimes(end+1) = a_timeData.cycleTime(idCy).lastMsgTime;
   end
end

[~, idSort] = sort(tabTimes);
for idLine = 1:length(idSort)
   fprintf(g_decArgo_outputCsvFileId, '%s\n', tabLabel{idSort(idLine)});
end

return;