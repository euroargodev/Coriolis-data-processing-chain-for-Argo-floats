% ------------------------------------------------------------------------------
% Print hydraulic data in output CSV file.
%
% SYNTAX :
%  print_hydraulic_data_in_csv_file_221_222_223_225(a_evAct, a_pumpAct)
%
% INPUT PARAMETERS :
%   a_evAct   : hydraulic (EV) data
%   a_pumpAct : hydraulic (pump) data
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
function print_hydraulic_data_in_csv_file_221_222_223_225(a_evAct, a_pumpAct)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;


if (~isempty(a_evAct))
   
   evDate = [];
   evDateAdj = [];
   evPres = [];
   evDur = [];
   for idP = 1:size(a_evAct, 1)
      evDate = [evDate; a_evAct(idP, 3) + g_decArgo_julD2FloatDayOffset];
      evDateAdj = [evDateAdj; a_evAct(idP, 4)];
      evPres = [evPres; a_evAct(idP, 5)];
      evDur = [evDur; a_evAct(idP, 6)];
   end
   
   % sort the actions in chronological order
   [evDate, idSorted] = sort(evDate);
   evDateAdj = evDateAdj(idSorted);
   evPres = evPres(idSorted);
   evDur = evDur(idSorted);
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; EV act.; EV ACTIONS\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; EV act.; Description; Float time; UTC time; PRES (dbar); Duration (csec)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   for idAct = 1:length(evDate)
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; EV act.; EV act. #%d; %s; %s; %d; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idAct, ...
         julian_2_gregorian_dec_argo(evDate(idAct)), ...
         julian_2_gregorian_dec_argo(evDateAdj(idAct)), ...
         evPres(idAct), evDur(idAct));
   end
end

if (~isempty(a_pumpAct))
   
   pumpDate = [];
   pumpDateAdj = [];
   pumpPres = [];
   pumpDur = [];
   for idP = 1:size(a_pumpAct, 1)
      pumpDate = [pumpDate; a_pumpAct(idP, 3) + g_decArgo_julD2FloatDayOffset];
      pumpDateAdj = [pumpDateAdj; a_pumpAct(idP, 4)];
      pumpPres = [pumpPres; a_pumpAct(idP, 5)];
      pumpDur = [pumpDur; a_pumpAct(idP, 6)];
   end
   
   % sort the actions in chronological order
   [pumpDate, idSorted] = sort(pumpDate);
   pumpDateAdj = pumpDateAdj(idSorted);
   pumpPres = pumpPres(idSorted);
   pumpDur = pumpDur(idSorted);
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Pump act.; PUMP ACTIONS\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Pump act.; Description; Float time; UTC time; PRES (dbar); Duration (csec)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   for idAct = 1:length(pumpDate)
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Pump act.; pump act. #%d; %s; %s; %d; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idAct, ...
         julian_2_gregorian_dec_argo(pumpDate(idAct)), ...
         julian_2_gregorian_dec_argo(pumpDateAdj(idAct)), ...
         pumpPres(idAct), pumpDur(idAct));
   end
end

return
