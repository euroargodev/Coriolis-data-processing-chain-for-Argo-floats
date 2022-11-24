% ------------------------------------------------------------------------------
% Print ascending profile data in output CSV file.
%
% SYNTAX :
%  print_ascending_profile_in_csv_file_209( ...
%    a_ascProfDate, a_ascProfPres, a_ascProfTemp, a_ascProfSal, ...
%    a_ascProfC1PhaseDoxy, a_ascProfC2PhaseDoxy, a_ascProfTempDoxyAa, a_ascProfDoxyAa, ...
%    a_ascProfPhaseDelayDoxy, a_ascProfTempDoxySbe, a_ascProfDoxySbe)
%
% INPUT PARAMETERS :
%   a_ascProfDate           : ascending profile dates
%   a_ascProfPres           : ascending profile PRES
%   a_ascProfTemp           : ascending profile TEMP
%   a_ascProfSal            : ascending profile PSAL
%   a_ascProfC1PhaseDoxy    : ascending profile C1PHASE_DOXY
%   a_ascProfC2PhaseDoxy    : ascending profile C2PHASE_DOXY
%   a_ascProfTempDoxyAa     : ascending profile TEMP_DOXY (Aanderaa sensor)
%   a_ascProfDoxySbe        : ascending profile DOXY (Aanderaa sensor)
%   a_ascProfPhaseDelayDoxy : ascending profile PHASE_DELAY_DOXY
%   a_ascProfTempDoxySbe    : ascending profile TEMP_DOXY (SBE sensor)
%   a_ascProfDoxySbe        : ascending profile DOXY (SBE sensor)
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
function print_ascending_profile_in_csv_file_209( ...
   a_ascProfDate, a_ascProfPres, a_ascProfTemp, a_ascProfSal, ...
   a_ascProfC1PhaseDoxy, a_ascProfC2PhaseDoxy, a_ascProfTempDoxyAa, a_ascProfDoxyAa, ...
   a_ascProfPhaseDelayDoxy, a_ascProfTempDoxySbe, a_ascProfDoxySbe)

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
   
   if (~isempty(a_ascProfC1PhaseDoxy) && ~isempty(a_ascProfPhaseDelayDoxy))
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf; Description; UTC time; PRES (dbar); TEMP (degC); PSAL (PSU); C1PHASE_DOXY (degree); C2PHASE_DOXY (degree); TEMP_DOXY (degC); DOXY (micromol/kg); PHASE_DELAY_DOXY (usec); TEMP_DOXY2 (degC); DOXY2 (micromol/kg)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      for idMes = 1:length(a_ascProfPres)-1
         mesDate = a_ascProfDate(idMes);
         if (mesDate == g_decArgo_dateDef)
            mesDateStr = '';
         else
            mesDateStr = julian_2_gregorian_dec_argo(mesDate);
         end
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf; Asc. profile meas. #%d; %s; %.1f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            idMes, mesDateStr, ...
            a_ascProfPres(idMes), a_ascProfTemp(idMes), a_ascProfSal(idMes), ...
            a_ascProfC1PhaseDoxy(idMes), a_ascProfC2PhaseDoxy(idMes), a_ascProfTempDoxyAa(idMes), a_ascProfDoxyAa(idMes), ...
            a_ascProfPhaseDelayDoxy(idMes), a_ascProfTempDoxySbe(idMes), a_ascProfDoxySbe(idMes));
      end
      
   elseif (~isempty(a_ascProfC1PhaseDoxy))
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf; Description; UTC time; PRES (dbar); TEMP (degC); PSAL (PSU); C1PHASE_DOXY (degree); C2PHASE_DOXY (degree); TEMP_DOXY (degC); DOXY (micromol/kg)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      for idMes = 1:length(a_ascProfPres)-1
         mesDate = a_ascProfDate(idMes);
         if (mesDate == g_decArgo_dateDef)
            mesDateStr = '';
         else
            mesDateStr = julian_2_gregorian_dec_argo(mesDate);
         end
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf; Asc. profile meas. #%d; %s; %.1f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            idMes, mesDateStr, ...
            a_ascProfPres(idMes), a_ascProfTemp(idMes), a_ascProfSal(idMes), ...
            a_ascProfC1PhaseDoxy(idMes), a_ascProfC2PhaseDoxy(idMes), a_ascProfTempDoxyAa(idMes), a_ascProfDoxyAa(idMes));
      end
      
   elseif (~isempty(a_ascProfPhaseDelayDoxy))
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf; Description; UTC time; PRES (dbar); TEMP (degC); PSAL (PSU); PHASE_DELAY_DOXY (usec); TEMP_DOXY2 (degC); DOXY2 (micromol/kg)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      for idMes = 1:length(a_ascProfPres)-1
         mesDate = a_ascProfDate(idMes);
         if (mesDate == g_decArgo_dateDef)
            mesDateStr = '';
         else
            mesDateStr = julian_2_gregorian_dec_argo(mesDate);
         end
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf; Asc. profile meas. #%d; %s; %.1f; %.3f; %.3f; %.3f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            idMes, mesDateStr, ...
            a_ascProfPres(idMes), a_ascProfTemp(idMes), a_ascProfSal(idMes), ...
            a_ascProfPhaseDelayDoxy(idMes), a_ascProfTempDoxySbe(idMes), a_ascProfDoxySbe(idMes));
      end
      
   else
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf; Description; UTC time; PRES (dbar); TEMP (degC); PSAL (PSU)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      for idMes = 1:length(a_ascProfPres)-1
         mesDate = a_ascProfDate(idMes);
         if (mesDate == g_decArgo_dateDef)
            mesDateStr = '';
         else
            mesDateStr = julian_2_gregorian_dec_argo(mesDate);
         end
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf; Asc. profile meas. #%d; %s; %.1f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            idMes, mesDateStr, ...
            a_ascProfPres(idMes), a_ascProfTemp(idMes), a_ascProfSal(idMes));
      end
      
   end
   
end

return
