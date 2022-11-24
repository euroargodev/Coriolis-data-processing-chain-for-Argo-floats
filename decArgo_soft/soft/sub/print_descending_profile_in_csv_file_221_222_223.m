% ------------------------------------------------------------------------------
% Print descending profile data in output CSV file.
%
% SYNTAX :
%  print_descending_profile_in_csv_file_221_222_223( ...
%    a_descProfDate, a_descProfDateAdj, a_descProfPres, a_descProfTemp, a_descProfSal, ...
%    a_descProfC1PhaseDoxy, a_descProfC2PhaseDoxy, a_descProfTempDoxy, a_descProfDoxy)
%
% INPUT PARAMETERS :
%   a_descProfDate        : descending profile dates
%   a_descProfDateAdj     : descending profile adjusted dates
%   a_descProfPres        : descending profile PRES
%   a_descProfTemp        : descending profile TEMP
%   a_descProfSal         : descending profile PSAL
%   a_descProfC1PhaseDoxy : descending profile C1PHASE_DOXY
%   a_descProfC2PhaseDoxy : descending profile C2PHASE_DOXY
%   a_descProfTempDoxy    : descending profile TEMP_DOXY
%   a_descProfDoxy        : descending profile DOXY
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/09/2019 - RNU - creation
% ------------------------------------------------------------------------------
function print_descending_profile_in_csv_file_221_222_223( ...
   a_descProfDate, a_descProfDateAdj, a_descProfPres, a_descProfTemp, a_descProfSal, ...
   a_descProfC1PhaseDoxy, a_descProfC2PhaseDoxy, a_descProfTempDoxy, a_descProfDoxy)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_dateDef;

if (~isempty(a_descProfPres))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf; DESCENDING PROFILE\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   if (isempty(a_descProfC1PhaseDoxy))
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf; Description; Float time; UTC time; PRES (dbar); TEMP (degC); PSAL (PSU)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      for idMes = length(a_descProfPres):-1:1
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
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf; Desc. profile meas. #%d; %s; %s; %.1f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            length(a_descProfPres)-idMes+1, mesDateStr, mesDateAdjStr, ...
            a_descProfPres(idMes), a_descProfTemp(idMes), a_descProfSal(idMes));
      end
   else
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf; Description; Float time; UTC time; PRES (dbar); TEMP (degC); PSAL (PSU); C1PHASE_DOXY (degree); C2PHASE_DOXY (degree); TEMP_DOXY (degC); DOXY (micromol/kg)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      for idMes = length(a_descProfPres):-1:1
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
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf; Desc. profile meas. #%d; %s; %s; %.1f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            length(a_descProfPres)-idMes+1, mesDateStr, mesDateAdjStr, ...
            a_descProfPres(idMes), a_descProfTemp(idMes), a_descProfSal(idMes), ...
            a_descProfC1PhaseDoxy(idMes), a_descProfC2PhaseDoxy(idMes), a_descProfTempDoxy(idMes), a_descProfDoxy(idMes));
      end
   end
end

return
