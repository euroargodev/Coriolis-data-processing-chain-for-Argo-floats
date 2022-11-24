% ------------------------------------------------------------------------------
% Print technical message data in output CSV file.
%
% SYNTAX :
%  print_tech_data_in_csv_file_2001(a_tabTech, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabTech   : decoded technical data
%   a_decoderId : float decoder Id
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
function print_tech_data_in_csv_file_2001(a_tabTech, a_decoderId)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

ID_OFFSET = 1;


if (isempty(a_tabTech))
   return;
end

if (size(a_tabTech, 1) > 1)
   fprintf('ERROR: Float #%d cycle #%d: BUFFER anomaly (%d tech message in the buffer)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      size(a_tabTech, 1));
elseif (size(a_tabTech, 1) == 1)
   id = 1;
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; TECHNICAL PACKET CONTENTS\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Transmission time of technical packet; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, julian_2_gregorian_dec_argo(a_tabTech(id, end)));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Descent end time; %.3f; => %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 1+ID_OFFSET), format_time_dec_argo(a_tabTech(id, 1+ID_OFFSET)));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Time of first valve action during descent; %.3f; => %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 2+ID_OFFSET), format_time_dec_argo(a_tabTech(id, 2+ID_OFFSET)));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Park end time; %.3f; => %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 3+ID_OFFSET), format_time_dec_argo(a_tabTech(id, 3+ID_OFFSET)));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Deep descent end time; %.3f; => %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 4+ID_OFFSET), format_time_dec_argo(a_tabTech(id, 4+ID_OFFSET)));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Ascent start time; %.3f; => %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 5+ID_OFFSET), format_time_dec_argo(a_tabTech(id, 5+ID_OFFSET)));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Ascent end time; %.3f; => %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 6+ID_OFFSET), format_time_dec_argo(a_tabTech(id, 6+ID_OFFSET)));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of valve actions at surface; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 7+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of valve actions during the descent to parking depth; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 8+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of pump actions during the descent to parking depth; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 9+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of valve actions during the descent to profile depth; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 10+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of pump actions during the descent to profile depth; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 11+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of pump actions during the ascent to surface; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 12+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of depth corrections during drift at parking depth; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 13+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of entries in parking zone; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 14+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; First stabilization pressure during descent; %d; => %d dbar\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 15+ID_OFFSET), a_tabTech(id, 15+ID_OFFSET)*10);
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Max pressure recorded during drift at parking depth; %d; => %d dbar\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 16+ID_OFFSET), a_tabTech(id, 16+ID_OFFSET)*10);
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Min pressure recorded during drift at parking depth; %d; => %d dbar\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 17+ID_OFFSET), a_tabTech(id, 17+ID_OFFSET)*10);
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Max pressure recorded during the cycle; %d; => %d dbar\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 18+ID_OFFSET), a_tabTech(id, 18+ID_OFFSET)*10);
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of CTD points in descent profile; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 19+ID_OFFSET));

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of packets for descent profile data; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 20+ID_OFFSET));

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of CTD points in ascent profile; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 21+ID_OFFSET));

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of packets for ascent profile data; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 22+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of CTD points in drift at parking depth; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 23+ID_OFFSET));

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of packets for drift at parking depth data; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 24+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of packets in pressure; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 25+ID_OFFSET));

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; CTD pressure offset; %.1f dbar\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 26+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Internal vacuum; %d mbar\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 27+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Ground detection at surface; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 28+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Ground detection during descent; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 29+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Cycle number; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 30+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Battery voltage; %.1f volts\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 31+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of power resets CTD; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 32+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of failed acquisitions CTD; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 33+ID_OFFSET));

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; CTD command error flag; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 34+ID_OFFSET));
   
   if (a_tabTech(id, 34+ID_OFFSET) ~= 0)
      
      % decode flags of CTD communication errors
      missionErrorCtdFpFlag = 0; % flag for error on CTD Fast Pressure command
      missionErrorCtdStartProfileFlag = 0; % flag for error on CTD Start Profile command
      missionErrorCtdStopProfileFlag = 0; % flag for error on CTD Stop Profile command
      missionErrorCtdDownloadFlag = 0; % flag for error on CTD Download command
      missionErrorCtdAverageFlag = 0; % flag for error on CTD Average command
      
      ctdCmdErrorFlag = a_tabTech(34+ID_OFFSET);
      if (ctdCmdErrorFlag ~= 0)
         if (bitand(ctdCmdErrorFlag, 1) == 1)
            missionErrorCtdFpFlag = 1;
         end
         if (bitand(ctdCmdErrorFlag, 2) == 2)
            missionErrorCtdStartProfileFlag = 1;
         end
         if (bitand(ctdCmdErrorFlag, 4) == 4)
            missionErrorCtdStopProfileFlag = 1;
         end
         if (bitand(ctdCmdErrorFlag, 8) == 8)
            missionErrorCtdDownloadFlag = 1;
         end
         if (bitand(ctdCmdErrorFlag, 16) == 16)
            missionErrorCtdAverageFlag = 1;
         end
      end
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; CTD Fast Pressure command flag; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, missionErrorCtdFpFlag);
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; CTD Start Profile command flag; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, missionErrorCtdStartProfileFlag);
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; CTD Stop Profile command flag; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, missionErrorCtdStopProfileFlag);
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; CTD Download command flag; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, missionErrorCtdDownloadFlag);
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; CTD Average command flag; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, missionErrorCtdAverageFlag);
   end

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of power resets Iridium; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 35+ID_OFFSET));

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of incoming packets of previous session; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 36+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of power resets GPS; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 37+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; GPS latitude; %g\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 38+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; GPS longitude; %g\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 39+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Day in the month of last GPS fix; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 40+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Time of last GPS fix; %.3f; => %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 41+ID_OFFSET), format_time_dec_argo(a_tabTech(id, 41+ID_OFFSET)));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Emergency ascent flag; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 42+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Watchdog timeout flag; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 43+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Number of hydraulic records; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 44+ID_OFFSET));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Start cycle date (dd/mm/yyyy hh:mm:ss); %02d/%02d/%04d %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, (46:48)+ID_OFFSET), format_time_dec_argo(a_tabTech(id, 45+ID_OFFSET)));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Time to last GPS fix; %d seconds; => %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 49+ID_OFFSET), format_time_dec_argo(a_tabTech(id, 49+ID_OFFSET)/3600));
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Tech; Time needed to transmit last technical packet; %d seconds; => %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_tabTech(id, 50+ID_OFFSET), format_time_dec_argo(a_tabTech(id, 50+ID_OFFSET)/3600));

end

return;
