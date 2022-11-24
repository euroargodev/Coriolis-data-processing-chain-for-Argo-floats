% ------------------------------------------------------------------------------
% Print hydraulic data in output CSV file.
%
% SYNTAX :
%  print_hydraulic_data_in_csv_file_212_214_217_218(a_evAct, a_pumpAct)
%
% INPUT PARAMETERS :
%   a_evAct   : decoded hydraulic (EV) data
%   a_pumpAct : decoded hydraulic (pump) data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/16/2017 - RNU - creation
% ------------------------------------------------------------------------------
function print_hydraulic_data_in_csv_file_212_214_217_218(a_evAct, a_pumpAct)

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
   evPres = [];
   evDur = [];
   for idP = 1:size(a_evAct, 1)
      evDate = [evDate; a_evAct(idP, 3) + g_decArgo_julD2FloatDayOffset];
      evPres = [evPres; a_evAct(idP, 4)];
      evDur = [evDur; a_evAct(idP, 5)];
   end
   
   % sort the actions in chronological order
   [evDate, idSorted] = sort(evDate);
   evPres = evPres(idSorted);
   evDur = evDur(idSorted);
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; EV act.; EV ACTIONS\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; EV act.; Description; UTC time; PRES (dbar); Duration (csec)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   for idAct = 1:length(evDate)
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; EV act.; EV act. #%d; %s; %d; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idAct, julian_2_gregorian_dec_argo(evDate(idAct)), ...
         evPres(idAct), evDur(idAct));
   end
end

if (~isempty(a_pumpAct))
   
   pumpDate = [];
   pumpPres = [];
   pumpDur = [];
   for idP = 1:size(a_pumpAct, 1)
      pumpDate = [pumpDate; a_pumpAct(idP, 3) + g_decArgo_julD2FloatDayOffset];
      pumpPres = [pumpPres; a_pumpAct(idP, 4)];
      pumpDur = [pumpDur; a_pumpAct(idP, 5)];
   end
   
   % sort the actions in chronological order
   [pumpDate, idSorted] = sort(pumpDate);
   pumpPres = pumpPres(idSorted);
   pumpDur = pumpDur(idSorted);
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Pump act.; PUMP ACTIONS\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Pump act.; Description; UTC time; PRES (dbar); Duration (csec)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   for idAct = 1:length(pumpDate)
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Pump act.; pump act. #%d; %s; %d; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idAct, julian_2_gregorian_dec_argo(pumpDate(idAct)), ...
         pumpPres(idAct), pumpDur(idAct));
   end
end

return
