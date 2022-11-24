% ------------------------------------------------------------------------------
% Print hydraulic data in output CSV file.
%
% SYNTAX :
%  print_hydraulic_data_in_csv_file_201_202_203(a_evAct, a_pumpAct)
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
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function print_hydraulic_data_in_csv_file_201_202_203(a_evAct, a_pumpAct)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_dateDef;
global g_decArgo_presCountsDef;
global g_decArgo_durationDef;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;


if (~isempty(a_evAct))
   
   evDate = [];
   evPres = [];
   evDur = [];
   for idP = 1:size(a_evAct, 1)
      data = a_evAct(idP, 2:end);
      for idPoint = 1:15
         if ~((data(idPoint) == g_decArgo_dateDef) && ...
               (data(idPoint+15) == g_decArgo_presCountsDef) && ...
               (data(idPoint+15*2) == g_decArgo_durationDef))
            
            evDate = [evDate; data(idPoint) + g_decArgo_julD2FloatDayOffset];
            evPres = [evPres; data(idPoint+15)];
            evDur = [evDur; data(idPoint+15*2)];
         else
            break;
         end
      end
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
      data = a_pumpAct(idP, 2:end);
      for idPoint = 1:15
         if ~((data(idPoint) == g_decArgo_dateDef) && ...
               (data(idPoint+15) == g_decArgo_presCountsDef) && ...
               (data(idPoint+15*2) == g_decArgo_durationDef))
            
            pumpDate = [pumpDate; data(idPoint) + g_decArgo_julD2FloatDayOffset];
            pumpPres = [pumpPres; data(idPoint+15)];
            pumpDur = [pumpDur; data(idPoint+15*2)];
         else
            break;
         end
      end
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

return;
