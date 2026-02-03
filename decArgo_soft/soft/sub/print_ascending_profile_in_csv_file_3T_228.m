% ------------------------------------------------------------------------------
% Print ascending profile data in output CSV file.
%
% SYNTAX :
% print_ascending_profile_in_csv_file_3T_228( ...
%   a_ascProfDate, a_ascProfDateAdj, ...
%   a_ascProfPresSbe41, a_ascProfTempSbe41, a_ascProfSalSbe41, ...
%   a_ascProfPresSbe61, a_ascProfTempSbe61, a_ascProfSalSbe61, ...
%   a_ascProfPresRbr, a_ascProfTempRbr, a_ascProfSalRbr, a_ascProfTempCndcRbr)
%
% INPUT PARAMETERS :
%   a_ascProfDate        : ascending profile dates
%   a_ascProfDateAdj     : ascending profile adjusted dates
%   a_ascProfPresSbe41   : ascending profile PRES from SBE41 sensor
%   a_ascProfTempSbe41   : ascending profile TEMP from SBE41 sensor
%   a_ascProfSalSbe41   : ascending profile PSAL from SBE41 sensor
%   a_ascProfPresSbe61   : ascending profile PRES from SBE61 sensor
%   a_ascProfTempSbe61   : ascending profile TEMP from SBE61 sensor
%   a_ascProfSalSbe61    : ascending profile PSAL from SBE61 sensor
%   a_ascProfPresRbr     : ascending profile PRES from RBR sensor
%   a_ascProfTempRbr     : ascending profile TEMP from RBR sensor
%   a_ascProfSalRbr      : ascending profile PSAL from RBR sensor
%   a_ascProfTempCndcRbr : ascending profile TEMP_CNDC from RBR sensor
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
function print_ascending_profile_in_csv_file_3T_228( ...
   a_ascProfDate, a_ascProfDateAdj, ...
   a_ascProfPresSbe41, a_ascProfTempSbe41, a_ascProfSalSbe41, ...
   a_ascProfPresSbe61, a_ascProfTempSbe61, a_ascProfSalSbe61, ...
   a_ascProfPresRbr, a_ascProfTempRbr, a_ascProfSalRbr, a_ascProfTempCndcRbr)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_dateDef;

if (~isempty(a_ascProfPresSbe41))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf SBE41; ASCENDING PROFILE FROM SBE41 SENSOR\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf SBE41; Description; Float time; UTC time; PRES (dbar); TEMP (degC); PSAL (PSU)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   for idMes = 1:length(a_ascProfPresSbe41)
      mesDate = a_ascProfDate(idMes);
      if (mesDate == g_decArgo_dateDef)
         mesDateStr = '';
      else
         mesDateStr = julian_2_gregorian_dec_argo(mesDate);
      end
      mesDateAdj = a_ascProfDateAdj(idMes);
      if (mesDateAdj == g_decArgo_dateDef)
         mesDateAdjStr = '';
      else
         mesDateAdjStr = julian_2_gregorian_dec_argo(mesDateAdj);
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf SBE41; Asc. profile meas. #%d; %s; %s; %.1f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idMes, mesDateStr, mesDateAdjStr, ...
         a_ascProfPresSbe41(idMes), a_ascProfTempSbe41(idMes), a_ascProfSalSbe41(idMes));
   end
end

if (~isempty(a_ascProfPresSbe61))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf SBE61; ASCENDING PROFILE FROM SBE61 SENSOR\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf SBE61; Description; Float time; UTC time; PRES (dbar); TEMP (degC); PSAL (PSU)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   for idMes = 1:length(a_ascProfPresSbe61)
      mesDate = a_ascProfDate(idMes);
      if (mesDate == g_decArgo_dateDef)
         mesDateStr = '';
      else
         mesDateStr = julian_2_gregorian_dec_argo(mesDate);
      end
      mesDateAdj = a_ascProfDateAdj(idMes);
      if (mesDateAdj == g_decArgo_dateDef)
         mesDateAdjStr = '';
      else
         mesDateAdjStr = julian_2_gregorian_dec_argo(mesDateAdj);
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf SBE61; Asc. profile meas. #%d; %s; %s; %.1f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idMes, mesDateStr, mesDateAdjStr, ...
         a_ascProfPresSbe61(idMes), a_ascProfTempSbe61(idMes), a_ascProfSalSbe61(idMes));
   end
end

if (~isempty(a_ascProfPresRbr))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf RBR; ASCENDING PROFILE FROM RBR SENSOR\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf RBR; Description; Float time; UTC time; PRES (dbar); TEMP (degC); PSAL (PSU); TEMP_CNDC (degC)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   for idMes = 1:length(a_ascProfPresRbr)
      mesDate = a_ascProfDate(idMes);
      if (mesDate == g_decArgo_dateDef)
         mesDateStr = '';
      else
         mesDateStr = julian_2_gregorian_dec_argo(mesDate);
      end
      mesDateAdj = a_ascProfDateAdj(idMes);
      if (mesDateAdj == g_decArgo_dateDef)
         mesDateAdjStr = '';
      else
         mesDateAdjStr = julian_2_gregorian_dec_argo(mesDateAdj);
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf RBR; Asc. profile meas. #%d; %s; %s; %.1f; %.3f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idMes, mesDateStr, mesDateAdjStr, ...
         a_ascProfPresRbr(idMes), a_ascProfTempRbr(idMes), a_ascProfSalRbr(idMes), a_ascProfTempCndcRbr(idMes));
   end
end

return
