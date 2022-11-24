% ------------------------------------------------------------------------------
% Print vitals data in CSV file.
%
% SYNTAX :
%  print_vitals_info_apx_apf11_in_csv_file(a_vitals)
%
% INPUT PARAMETERS :
%   a_vitals : vitals data
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
function print_vitals_info_apx_apf11_in_csv_file(a_vitals)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_vitals))
   return;
end

fprintf(g_decArgo_outputCsvFileId, '%d; %d; Vitals; Vit; Set#\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum);

for idV = 1:size(a_vitals, 1)
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Vitals; Vit; %d; Date of vitals set; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      idV, julian_2_gregorian_dec_argo(a_vitals(idV, 1)));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Vitals; Vit; %d; Air bladder pressure; %d counts; =>; %.3f dbar\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      idV, a_vitals(idV, 4), a_vitals(idV, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Vitals; Vit; %d; Internal vacuum pressure; %d counts; =>; %.3f dbar\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      idV, a_vitals(idV, 10), a_vitals(idV, 9));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Vitals; Vit; %d; Battery voltage; %d counts; =>; %.3f volts\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      idV, a_vitals(idV, 6), a_vitals(idV, 5));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Vitals; Vit; %d; Battery current draw; %.3f mA\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      idV, a_vitals(idV, 12));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Vitals; Vit; %d; Battery current raw; %.3f mA\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      idV, a_vitals(idV, 13));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Vitals; Vit; %d; Humidity (percent relative); %.3f\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      idV, a_vitals(idV, 7));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Vitals; Vit; %d; Leak detect voltage; %.3f volts\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      idV, a_vitals(idV, 8));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Vitals; Vit; %d; Coulomb counter; %.3f Ah\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      idV, a_vitals(idV, 11));
end

return;
