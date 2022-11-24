% ------------------------------------------------------------------------------
% Print drift measurement data in output CSV file.
%
% SYNTAX :
%  print_drift_meas_in_csv_file_201_to_203_206_to_208_213_to_218( ...
%    a_parkDate, a_parkTransDate, ...
%    a_parkPres, a_parkTemp, a_parkSal, ...
%    a_parkC1PhaseDoxy, a_parkC2PhaseDoxy, a_parkTempDoxy, a_parkDoxy)
%
% INPUT PARAMETERS :
%   a_parkDate        : drift meas dates
%   a_parkTransDate   : drift meas transmitted date flags
%   a_parkPres        : drift meas PRES
%   a_parkTemp        : drift meas TEMP
%   a_parkSal         : drift meas PSAL
%   a_parkC1PhaseDoxy : drift meas C1PHASE_DOXY
%   a_parkC2PhaseDoxy : drift meas C2PHASE_DOXY
%   a_parkTempDoxy    : drift meas TEMP_DOXY
%   a_parkDoxy        : drift meas DOXY
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
function print_drift_meas_in_csv_file_201_to_203_206_to_208_213_to_218( ...
   a_parkDate, a_parkTransDate, ...
   a_parkPres, a_parkTemp, a_parkSal, ...
   a_parkC1PhaseDoxy, a_parkC2PhaseDoxy, a_parkTempDoxy, a_parkDoxy)

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
   
   if (isempty(a_parkC1PhaseDoxy))
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift; Description; UTC time; PRES (dbar); TEMP (degC); PSAL (PSU)\n', ...
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
   else
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift; Description; UTC time; PRES (dbar); TEMP (degC); PSAL (PSU); C1PHASE_DOXY (degree); C2PHASE_DOXY (degree); TEMP_DOXY (degC); DOXY (micromol/kg)\n', ...
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
         
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift; Drift meas. #%d; %s (%c); %.1f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            idMes, mesDateStr, trans, ...
            a_parkPres(idMes), a_parkTemp(idMes), a_parkSal(idMes), ...
            a_parkC1PhaseDoxy(idMes), a_parkC2PhaseDoxy(idMes), a_parkTempDoxy(idMes), a_parkDoxy(idMes));
      end
   end
end

return
