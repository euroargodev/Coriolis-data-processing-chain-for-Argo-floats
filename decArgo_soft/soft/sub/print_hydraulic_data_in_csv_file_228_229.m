% ------------------------------------------------------------------------------
% Print hydraulic data in output CSV file.
%
% SYNTAX :
%  print_hydraulic_data_in_csv_file_228_229(a_evAct, a_pumpAct, a_dataStartPos)
%
% INPUT PARAMETERS :
%   a_evAct        : decoded hydraulic (EV) data
%   a_pumpAct      : decoded hydraulic (pump) data
%   a_dataStartPos : position of the first data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/15/2024 - RNU - creation
% ------------------------------------------------------------------------------
function print_hydraulic_data_in_csv_file_228_229(a_evAct, a_pumpAct, a_dataStartPos)

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
   evDateAdj = [];
   evPres = [];
   evDur = [];
   for idP = 1:size(a_evAct, 1)
      data = a_evAct(idP, a_dataStartPos:end);
      for idPoint = 1:15
         if ~((data(idPoint) == g_decArgo_dateDef) && ...
               (data(idPoint+30) == g_decArgo_presCountsDef) && ...
               (data(idPoint+45) == g_decArgo_durationDef))
            
            evDate = [evDate; data(idPoint) + g_decArgo_julD2FloatDayOffset];
            evDateAdj = [evDateAdj; data(idPoint+15) + g_decArgo_julD2FloatDayOffset];
            evPres = [evPres; data(idPoint+30)];
            evDur = [evDur; data(idPoint+45)];
         else
            break
         end
      end
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
         idAct, julian_2_gregorian_dec_argo(evDate(idAct)), ...
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
      data = a_pumpAct(idP, a_dataStartPos:end);
      for idPoint = 1:15
         if ~((data(idPoint) == g_decArgo_dateDef) && ...
               (data(idPoint+30) == g_decArgo_presCountsDef) && ...
               (data(idPoint+45) == g_decArgo_durationDef))
            
            pumpDate = [pumpDate; data(idPoint) + g_decArgo_julD2FloatDayOffset];
            pumpDateAdj = [pumpDateAdj; data(idPoint+15) + g_decArgo_julD2FloatDayOffset];
            pumpPres = [pumpPres; data(idPoint+30)];
            pumpDur = [pumpDur; data(idPoint+45)];
         else
            break
         end
      end
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
         idAct, julian_2_gregorian_dec_argo(pumpDate(idAct)), ...
         julian_2_gregorian_dec_argo(pumpDateAdj(idAct)), ...
         pumpPres(idAct), pumpDur(idAct));
   end
end

return
