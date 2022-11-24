% ------------------------------------------------------------------------------
% Print drift measurement data in output CSV file.
%
% SYNTAX :
%  print_drift_measurements_in_csv_file_204_205_210_to_212( ...
%    a_parkDate, a_parkTransDate, ...
%    a_parkPres, a_parkTemp, a_parkSal)
%
% INPUT PARAMETERS :
%   a_parkDate      : drift meas dates
%   a_parkTransDate : drift meas transmitted date flags
%   a_parkPres      : drift meas PRES
%   a_parkTemp      : drift meas TEMP
%   a_parkSal       : drift meas PSAL
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/11/2015 - RNU - creation
% ------------------------------------------------------------------------------
function print_drift_measurements_in_csv_file_204_205_210_to_212( ...
   a_parkDate, a_parkTransDate, ...
   a_parkPres, a_parkTemp, a_parkSal)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_dateDef;

if (~isempty(a_parkPres))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift; DRIFT MEASUREMENTS\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift; Description; UTC time; PRES (dbar); TEMP (°C); PSAL (PSU)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   for idMes = 1:length(a_parkDate)
      mesDate = a_parkDate(idMes);
      if (mesDate == g_decArgo_dateDef)
         mesDateStr = '';
      else
         mesDateStr = julian_2_gregorian_dec_argo(mesDate);
      end
      if (a_parkTransDate(idMes) == 1)
         trans = 'T';
      else
         trans = 'C';
      end
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift; Drift meas. #%d; %s (%c); %.1f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idMes, mesDateStr, trans, ...
         a_parkPres(idMes), a_parkTemp(idMes), a_parkSal(idMes));
   end
end

return
