% ------------------------------------------------------------------------------
% Print drift measurement data in output CSV file.
%
% SYNTAX :
%  print_drift_measurements_in_csv_file_209( ...
%    a_parkDate, a_parkTransDate, ...
%    a_parkPres, a_parkTemp, a_parkSal, ...
%    a_parkC1PhaseDoxy, a_parkC2PhaseDoxy, a_parkTempDoxyAa, a_parkDoxyAa, ...
%    a_parkPhaseDelayDoxy, a_parkTempDoxySbe, a_parkDoxySbe)
%
% INPUT PARAMETERS :
%   a_parkDate           : drift meas dates
%   a_parkTransDate      : drift meas transmitted date flags
%   a_parkPres           : drift meas PRES
%   a_parkTemp           : drift meas TEMP
%   a_parkSal            : drift meas PSAL
%   a_parkC1PhaseDoxy    : drift meas C1PHASE_DOXY
%   a_parkC2PhaseDoxy    : drift meas C2PHASE_DOXY
%   a_parkTempDoxyAa     : drift meas TEMP_DOXY (Aanderaa sensor)
%   a_parkDoxyAa         : drift meas DOXY (Aanderaa sensor)
%   a_parkPhaseDelayDoxy : drift meas PHASE_DELAY_DOXY
%   a_parkTempDoxySbe    : drift meas TEMP_DOXY (SBE sensor)
%   a_parkDoxySbe        : drift meas DOXY (SBE sensor)
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/03/2015 - RNU - creation
% ------------------------------------------------------------------------------
function print_drift_measurements_in_csv_file_209( ...
   a_parkDate, a_parkTransDate, ...
   a_parkPres, a_parkTemp, a_parkSal, ...
   a_parkC1PhaseDoxy, a_parkC2PhaseDoxy, a_parkTempDoxyAa, a_parkDoxyAa, ...
   a_parkPhaseDelayDoxy, a_parkTempDoxySbe, a_parkDoxySbe)

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
   
   if (~isempty(a_parkC1PhaseDoxy) && ~isempty(a_parkPhaseDelayDoxy))

      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift; Description; UTC time; PRES (dbar); TEMP (°C); PSAL (PSU); C1PHASE_DOXY (degree); C2PHASE_DOXY (degree); TEMP_DOXY (°C); DOXY (micromol/kg); PHASE_DELAY_DOXY (usec); TEMP_DOXY2 (°C); DOXY2 (micromol/kg)\n', ...
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
         
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift; Drift meas. #%d; %s (%c); %.1f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            idMes, mesDateStr, trans, ...
            a_parkPres(idMes), a_parkTemp(idMes), a_parkSal(idMes), ...
            a_parkC1PhaseDoxy(idMes), a_parkC2PhaseDoxy(idMes), a_parkTempDoxyAa(idMes), a_parkDoxyAa(idMes), ...
            a_parkPhaseDelayDoxy(idMes), a_parkTempDoxySbe(idMes), a_parkDoxySbe(idMes));
      end
      
   elseif (~isempty(a_parkC1PhaseDoxy))
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift; Description; UTC time; PRES (dbar); TEMP (°C); PSAL (PSU); C1PHASE_DOXY (degree); C2PHASE_DOXY (degree); TEMP_DOXY (°C); DOXY (micromol/kg)\n', ...
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
            a_parkC1PhaseDoxy(idMes), a_parkC2PhaseDoxy(idMes), a_parkTempDoxyAa(idMes), a_parkDoxyAa(idMes));
      end
      
   elseif (~isempty(a_parkPhaseDelayDoxy))
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift; Description; UTC time; PRES (dbar); TEMP (°C); PSAL (PSU); PHASE_DELAY_DOXY (usec); TEMP_DOXY2 (°C); DOXY2 (micromol/kg)\n', ...
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
         
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift; Drift meas. #%d; %s (%c); %.1f; %.3f; %.3f; %.3f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            idMes, mesDateStr, trans, ...
            a_parkPres(idMes), a_parkTemp(idMes), a_parkSal(idMes), ...
            a_parkPhaseDelayDoxy(idMes), a_parkTempDoxySbe(idMes), a_parkDoxySbe(idMes));
      end
      
   else
      
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
end

return;
