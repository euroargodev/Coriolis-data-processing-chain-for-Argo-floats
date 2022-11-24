% ------------------------------------------------------------------------------
% Print vitals data in CSV file.
%
% SYNTAX :
%  print_vitals_info_apx_apf11_in_csv_file(a_vitalsData)
%
% INPUT PARAMETERS :
%   a_vitalsData : vitals data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function print_vitals_info_apx_apf11_in_csv_file(a_vitalsData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_vitalsData))
   return;
end

if (isfield(a_vitalsData, 'VITALS_CORE'))
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Vitals_core; Vit; Set#\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   for idV = 1:size(a_vitalsData.VITALS_CORE, 1)
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Vitals_core; Vit; %d; Date of vitals set; %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idV, julian_2_gregorian_dec_argo(a_vitalsData.VITALS_CORE(idV, 1)));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Vitals_core; Vit; %d; Air bladder pressure; %d counts; =>; %.3f dbar\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idV, a_vitalsData.VITALS_CORE(idV, 4), a_vitalsData.VITALS_CORE(idV, 3));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Vitals_core; Vit; %d; Internal vacuum pressure; %d counts; =>; %.3f dbar\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idV, a_vitalsData.VITALS_CORE(idV, 10), a_vitalsData.VITALS_CORE(idV, 9));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Vitals_core; Vit; %d; Battery voltage; %d counts; =>; %.3f volts\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idV, a_vitalsData.VITALS_CORE(idV, 6), a_vitalsData.VITALS_CORE(idV, 5));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Vitals_core; Vit; %d; Battery current draw; %.3f mA\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idV, a_vitalsData.VITALS_CORE(idV, 12));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Vitals_core; Vit; %d; Battery current raw; %.3f mA\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idV, a_vitalsData.VITALS_CORE(idV, 13));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Vitals_core; Vit; %d; Humidity (percent relative); %.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idV, a_vitalsData.VITALS_CORE(idV, 7));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Vitals_core; Vit; %d; Leak detect voltage; %.3f volts\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idV, a_vitalsData.VITALS_CORE(idV, 8));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Vitals_core; Vit; %d; Coulomb counter; %.3f Ah\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idV, a_vitalsData.VITALS_CORE(idV, 11));
   end
end

if (isfield(a_vitalsData, 'WD_CNT'))
   
   for idV = 1:size(a_vitalsData.WD_CNT, 1)
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Watchdog; Vit; Date; %s; Firmware watchdog count; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         julian_2_gregorian_dec_argo(a_vitalsData.WD_CNT(idV, 1)), ...
         a_vitalsData.WD_CNT(idV, 3));
   end
end

return;
