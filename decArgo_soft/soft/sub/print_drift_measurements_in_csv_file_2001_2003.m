% ------------------------------------------------------------------------------
% Print drift measurement data in output CSV file.
%
% SYNTAX :
%  print_drift_measurements_in_csv_file_2001_2003( ...
%    a_parkDate, a_parkDateAdj, a_parkTransDate, ...
%    a_parkPres, a_parkTemp, a_parkSal)
%
% INPUT PARAMETERS :
%   a_parkDate      : drift meas dates
%   a_parkDateAdj   : drift meas adjusted dates
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
%   04/28/2016 - RNU - creation
% ------------------------------------------------------------------------------
function print_drift_measurements_in_csv_file_2001_2003( ...
   a_parkDate, a_parkDateAdj, a_parkTransDate, a_parkPres, a_parkTemp, a_parkSal)

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
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift; Description; Float time; UTC time; PRES (dbar); TEMP (°C); PSAL (PSU)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   for idMes = 1:length(a_parkDate)
      if (a_parkDate(idMes) == g_decArgo_dateDef)
         mesDateFloatStr = '';
         mesDateUtcStr = '';
      else
         mesDateFloatStr = julian_2_gregorian_dec_argo(a_parkDate(idMes));
         mesDateUtcStr = julian_2_gregorian_dec_argo(a_parkDateAdj(idMes));
      end
      if (a_parkTransDate(idMes) == 1)
         trans = 'T';
      else
         trans = 'C';
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift; Drift meas. #%d; %s (%c); %s; %.1f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idMes, mesDateFloatStr, trans, mesDateUtcStr, ...
         a_parkPres(idMes), a_parkTemp(idMes), a_parkSal(idMes));
   end
end

return;
