% ------------------------------------------------------------------------------
% Print descending profile data in output CSV file.
%
% SYNTAX :
% print_descending_profile_in_csv_file_2T_229( ...
%   a_descProfDate, a_descProfDateAdj, ...
%   a_descProfPresRbr, a_descProfTempRbr, a_descProfSalRbr, a_descProfTempCndcRbr, ...
%   a_descProfPresSbe61, a_descProfTempSbe61, a_descProfSalSbe61)
%
% INPUT PARAMETERS :
%   a_descProfDate        : descending profile dates
%   a_descProfDateAdj     : descending profile adjusted dates
%   a_descProfPresRbr     : descending profile PRES from RBR sensor
%   a_descProfTempRbr     : descending profile TEMP from RBR sensor
%   a_descProfSalRbr      : descending profile PSAL from RBR sensor
%   a_descProfTempCndcRbr : descending profile TEMP_CNDC from RBR sensor
%   a_descProfPresSbe61   : descending profile PRES from SBE61 sensor
%   a_descProfTempSbe61   : descending profile TEMP from SBE61 sensor
%   a_descProfSalSbe61    : descending profile PSAL from SBE61 sensor
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2024 - RNU - creation
% ------------------------------------------------------------------------------
function print_descending_profile_in_csv_file_2T_229( ...
   a_descProfDate, a_descProfDateAdj, ...
   a_descProfPresRbr, a_descProfTempRbr, a_descProfSalRbr, a_descProfTempCndcRbr, ...
   a_descProfPresSbe61, a_descProfTempSbe61, a_descProfSalSbe61)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_dateDef;

if (~isempty(a_descProfPresRbr))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf RBR; DESCENDING PROFILE FROM RBR SENSOR\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf RBR; Description; Float time; UTC time; PRES (dbar); TEMP (degC); PSAL (PSU); TEMP_CNDC (degC)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   for idMes = length(a_descProfPresRbr):-1:1
      mesDate = a_descProfDate(idMes);
      if (mesDate == g_decArgo_dateDef)
         mesDateStr = '';
      else
         mesDateStr = julian_2_gregorian_dec_argo(mesDate);
      end
      mesDateAdj = a_descProfDateAdj(idMes);
      if (mesDateAdj == g_decArgo_dateDef)
         mesDateAdjStr = '';
      else
         mesDateAdjStr = julian_2_gregorian_dec_argo(mesDateAdj);
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf RBR; Desc. profile meas. #%d; %s; %s; %.1f; %.3f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         length(a_descProfPresRbr)-idMes+1, mesDateStr, mesDateAdjStr, ...
         a_descProfPresRbr(idMes), a_descProfTempRbr(idMes), a_descProfSalRbr(idMes), a_descProfTempCndcRbr(idMes));
   end
end

if (~isempty(a_descProfPresSbe61))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf SBE61; DESCENDING PROFILE FROM SBE61 SENSOR\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf SBE61; Description; Float time; UTC time; PRES (dbar); TEMP (degC); PSAL (PSU)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   for idMes = length(a_descProfPresSbe61):-1:1
      mesDate = a_descProfDate(idMes);
      if (mesDate == g_decArgo_dateDef)
         mesDateStr = '';
      else
         mesDateStr = julian_2_gregorian_dec_argo(mesDate);
      end
      mesDateAdj = a_descProfDateAdj(idMes);
      if (mesDateAdj == g_decArgo_dateDef)
         mesDateAdjStr = '';
      else
         mesDateAdjStr = julian_2_gregorian_dec_argo(mesDateAdj);
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf SBE61; Desc. profile meas. #%d; %s; %s; %.1f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         length(a_descProfPresSbe61)-idMes+1, mesDateStr, mesDateAdjStr, ...
         a_descProfPresSbe61(idMes), a_descProfTempSbe61(idMes), a_descProfSalSbe61(idMes));
   end
end

return
