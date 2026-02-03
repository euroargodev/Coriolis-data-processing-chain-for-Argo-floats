% ------------------------------------------------------------------------------
% Print drift measurement data in output CSV file.
%
% SYNTAX :
% print_drift_measurements_in_csv_file_3T_228( ...
%   a_parkDate, a_parkDateAdj, a_parkTransDate, ...
%   a_parkPresSbe41, a_parkTempSbe41, a_parkSalSbe41, ...
%   a_parkPresSbe61, a_parkTempSbe61, a_parkSalSbe61, ...
%   a_parkPresRbr, a_parkTempRbr, a_parkSalRbr, a_parkTempCndcRbr)
%
% INPUT PARAMETERS :
%   a_parkDate        : drift meas dates
%   a_parkDateAdj     : drift meas adjusted dates
%   a_parkTransDate   : drift meas transmitted date flags
%   a_parkPresSbe41   : drift meas PRES from SBE41 sensor
%   a_parkTempSbe41   : drift meas TEMP from SBE41 sensor
%   a_parkSalSbe41    : drift meas PSAL from SBE41 sensor
%   a_parkPresSbe61   : drift meas PRES from SBE61 sensor
%   a_parkTempSbe61   : drift meas TEMP from SBE61 sensor
%   a_parkSalSbe61    : drift meas PSAL from SBE61 sensor
%   a_parkPresRbr     : drift meas PRES from RBR sensor
%   a_parkTempRbr     : drift meas TEMP from RBR sensor
%   a_parkSalRbr      : drift meas PSAL from RBR sensor
%   a_parkTempCndcRbr : drift meas TEMP_CNDC from RBR sensor
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/22/2024 - RNU - creation
% ------------------------------------------------------------------------------
function print_drift_measurements_in_csv_file_3T_228( ...
   a_parkDate, a_parkDateAdj, a_parkTransDate, ...
   a_parkPresSbe41, a_parkTempSbe41, a_parkSalSbe41, ...
   a_parkPresSbe61, a_parkTempSbe61, a_parkSalSbe61, ...
   a_parkPresRbr, a_parkTempRbr, a_parkSalRbr, a_parkTempCndcRbr)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_dateDef;

if (~isempty(a_parkPresSbe41))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift SBE41; DRIFT MEASUREMENTS FROM SBE41 SENSOR\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift SBE41; Description; Float time; UTC time; PRES (dbar); TEMP (degC); PSAL (PSU)\n', ...
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

      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift SBE41; Drift meas. #%d; %s; %s (%c); %.1f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idMes, mesDateStr, mesDateAdjStr, trans, ...
         a_parkPresSbe41(idMes), a_parkTempSbe41(idMes), a_parkSalSbe41(idMes));
   end
end

if (~isempty(a_parkPresSbe61))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift SBE61; DRIFT MEASUREMENTS FROM SBE61 SENSOR\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift SBE61; Description; Float time; UTC time; PRES (dbar); TEMP (degC); PSAL (PSU)\n', ...
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

      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift SBE61; Drift meas. #%d; %s; %s (%c); %.1f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idMes, mesDateStr, mesDateAdjStr, trans, ...
         a_parkPresSbe61(idMes), a_parkTempSbe61(idMes), a_parkSalSbe61(idMes));
   end
end

if (~isempty(a_parkPresRbr))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift RBR; DRIFT MEASUREMENTS FROM RBR SENSOR\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift RBR; Description; Float time; UTC time; PRES (dbar); TEMP (degC); PSAL (PSU); TEMP_CNDC (degC)\n', ...
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

      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift RBR; Drift meas. #%d; %s; %s (%c); %.1f; %.3f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idMes, mesDateStr, mesDateAdjStr, trans, ...
         a_parkPresRbr(idMes), a_parkTempRbr(idMes), a_parkSalRbr(idMes), a_parkTempCndcRbr(idMes));
   end
end

return
