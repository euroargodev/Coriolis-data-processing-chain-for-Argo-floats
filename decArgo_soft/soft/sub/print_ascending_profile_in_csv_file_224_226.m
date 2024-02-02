% ------------------------------------------------------------------------------
% Print ascending profile data in output CSV file.
%
% SYNTAX :
%  print_ascending_profile_in_csv_file_224_226( ...
%    a_ascProfDate, a_ascProfDateAdj, ...
%    a_ascProfPres, a_ascProfTemp, a_ascProfSal, ascProfTempCndc, ...
%    a_ascProfC1PhaseDoxy, a_ascProfC2PhaseDoxy, a_ascProfTempDoxy, a_ascProfDoxy)
%
% INPUT PARAMETERS :
%   a_ascProfDate        : ascending profile dates
%   a_ascProfDateAdj     : ascending profile adjusted dates
%   a_ascProfPres        : ascending profile PRES
%   a_ascProfTemp        : ascending profile TEMP
%   a_ascProfSal         : ascending profile PSAL
%   ascProfTempCndc      : ascending profile TEMP_CNDC
%   a_ascProfC1PhaseDoxy : ascending profile C1PHASE_DOXY
%   a_ascProfC2PhaseDoxy : ascending profile C2PHASE_DOXY
%   a_ascProfTempDoxy    : ascending profile TEMP_DOXY
%   a_ascProfDoxy        : ascending profile DOXY
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/08/2021 - RNU - creation
% ------------------------------------------------------------------------------
function print_ascending_profile_in_csv_file_224_226( ...
   a_ascProfDate, a_ascProfDateAdj, ...
   a_ascProfPres, a_ascProfTemp, a_ascProfSal, ascProfTempCndc, ...
   a_ascProfC1PhaseDoxy, a_ascProfC2PhaseDoxy, a_ascProfTempDoxy, a_ascProfDoxy)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_dateDef;

if (~isempty(a_ascProfPres))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf; ASCENDING PROFILE\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   if (isempty(a_ascProfC1PhaseDoxy))
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf; Description; Float time; UTC time; PRES (dbar); TEMP (degC); PSAL (PSU); TEMP_CNDC (degC)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      for idMes = 1:length(a_ascProfPres)
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
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf; Asc. profile meas. #%d; %s; %s; %.1f; %.3f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            idMes, mesDateStr, mesDateAdjStr, ...
            a_ascProfPres(idMes), a_ascProfTemp(idMes), a_ascProfSal(idMes), ascProfTempCndc(idMes));
      end
   else
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf; Description; Float time; UTC time; PRES (dbar); TEMP (degC); PSAL (PSU); TEMP_CNDC (degC); C1PHASE_DOXY (degree); C2PHASE_DOXY (degree); TEMP_DOXY (degC); DOXY (micromol/kg)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      for idMes = 1:length(a_ascProfPres)
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
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf; Asc. profile meas. #%d; %s; %s; %.1f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            idMes, mesDateStr, mesDateAdjStr, ...
            a_ascProfPres(idMes), a_ascProfTemp(idMes), a_ascProfSal(idMes), ascProfTempCndc(idMes), ...
            a_ascProfC1PhaseDoxy(idMes), a_ascProfC2PhaseDoxy(idMes), a_ascProfTempDoxy(idMes), a_ascProfDoxy(idMes));
      end
   end
end

return
