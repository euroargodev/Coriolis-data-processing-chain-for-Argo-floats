% ------------------------------------------------------------------------------
% Print drift measurement data in output CSV file.
%
% SYNTAX :
% print_drift_measurements_in_csv_file_230( ...
%   a_parkDate, a_parkDateAdj, a_parkTransDate, ...
%   a_parkPres, a_parkTemp, a_parkSal, ...
%   a_parkC1PhaseDoxy, a_parkC2PhaseDoxy, a_parkTempDoxy, a_parkDoxy, ...
%   a_parkTempCountDoxy, a_parkCountDoxy, a_parkLedFlashingCountDoxy, a_parkTempDoxy2, a_parkDoxy2)
%
% INPUT PARAMETERS :
%   a_parkDate                 : drift meas dates
%   a_parkDateAdj              : drift meas adjusted dates
%   a_parkTransDate            : drift meas transmitted date flags
%   a_parkPres                 : drift meas PRES
%   a_parkTemp                 : drift meas TEMP
%   a_parkSal                  : drift meas PSAL
%   a_parkC1PhaseDoxy          : drift meas C1PHASE_DOXY
%   a_parkC2PhaseDoxy          : drift meas C2PHASE_DOXY
%   a_parkTempDoxy             : drift meas TEMP_DOXY
%   a_parkDoxy                 : drift meas DOXY
%   a_parkTempCountDoxy        : drift meas TEMP_COUNT_DOXY
%   a_parkCountDoxy            : drift meas COUNT_DOXY
%   a_parkLedFlashingCountDoxy : drift meas LED_FLASHING_COUNT_DOXY DOXY
%   a_parkTempDoxy2            : drift meas TEMP_DOXY2
%   a_parkDoxy2                : drift meas DOXY2
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/05/2024 - RNU - creation
% ------------------------------------------------------------------------------
function print_drift_measurements_in_csv_file_230( ...
   a_parkDate, a_parkDateAdj, a_parkTransDate, ...
   a_parkPres, a_parkTemp, a_parkSal, ...
   a_parkC1PhaseDoxy, a_parkC2PhaseDoxy, a_parkTempDoxy, a_parkDoxy, ...
   a_parkTempCountDoxy, a_parkCountDoxy, a_parkLedFlashingCountDoxy, a_parkTempDoxy2, a_parkDoxy2)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_dateDef;

if (~isempty(a_parkPres))
   fprintf(g_decArgo_outputCsvFileId, '%d;%d;Drift;DRIFT MEASUREMENTS\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   fprintf(g_decArgo_outputCsvFileId, '%d;%d;Drift;Description;Float time;UTC time;PRES (dbar);TEMP (degC);PSAL (PSU);C1PHASE_DOXY (degree);C2PHASE_DOXY (degree);TEMP_DOXY (degC);DOXY (micromol/kg);COUNT_DOXY (count);LED_FLASHING_COUNT_DOXY (count);TEMP_COUNT_DOXY (count);TEMP_DOXY2 (degC);DOXY2 (micromol/kg)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   for idMes = 1:length(a_parkDate)
      mesDate = a_parkDate(idMes);
      if (mesDate == g_decArgo_dateDef)
         mesDateStr = '';
      else
         mesDateStr = julian_2_gregorian_dec_argo(mesDate);
      end
      mesDateAdj = a_parkDateAdj(idMes);
      if (mesDateAdj == g_decArgo_dateDef)
         mesDateAdjStr = '';
      else
         mesDateAdjStr = julian_2_gregorian_dec_argo(mesDateAdj);
      end
      if (a_parkTransDate(idMes) == 1)
         trans = 'T';
      else
         trans = 'C';
      end

      fprintf(g_decArgo_outputCsvFileId, '%d;%d;Drift;Drift meas. #%d; %s; %s (%c);%.1f;%.3f;%.3f;%.3f;%.3f;%.3f;%.3f;%d;%d;%d;%.3f;%.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idMes, mesDateStr, mesDateAdjStr, trans, ...
         a_parkPres(idMes), a_parkTemp(idMes), a_parkSal(idMes), ...
         a_parkC1PhaseDoxy(idMes), a_parkC2PhaseDoxy(idMes), a_parkTempDoxy(idMes), a_parkDoxy(idMes), ...
         a_parkCountDoxy(idMes), a_parkLedFlashingCountDoxy(idMes), a_parkTempCountDoxy(idMes), a_parkTempDoxy2(idMes), a_parkDoxy2(idMes));
   end
end

return
