% ------------------------------------------------------------------------------
% Print descending profile data in output CSV file.
%
% SYNTAX :
%  print_descending_profile_in_csv_file_209( ...
%    a_descProfDate, a_descProfPres, a_descProfTemp, a_descProfSal, ...
%    a_descProfC1PhaseDoxy, a_descProfC2PhaseDoxy, a_descProfTempDoxyAa, a_descProfDoxyAa, ...
%    a_descProfPhaseDelayDoxy, a_descProfTempDoxySbe, a_descProfDoxySbe)
%
% INPUT PARAMETERS :
%   a_descProfDate           : descending profile dates
%   a_descProfPres           : descending profile PRES
%   a_descProfTemp           : descending profile TEMP
%   a_descProfSal            : descending profile PSAL
%   a_descProfC1PhaseDoxy    : descending profile C1PHASE_DOXY
%   a_descProfC2PhaseDoxy    : descending profile C2PHASE_DOXY
%   a_descProfTempDoxyAa     : descending profile TEMP_DOXY (Aanderaa sensor)
%   a_descProfDoxyAa         : descending profile DOXY (Aanderaa sensor)
%   a_descProfPhaseDelayDoxy : descending profile PHASE_DELAY_DOXY
%   a_descProfTempDoxySbe    : descending profile TEMP_DOXY (SBE sensor)
%   a_descProfDoxySbe        : descending profile DOXY (SBE sensor)
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
function print_descending_profile_in_csv_file_209( ...
   a_descProfDate, a_descProfPres, a_descProfTemp, a_descProfSal, ...
   a_descProfC1PhaseDoxy, a_descProfC2PhaseDoxy, a_descProfTempDoxyAa, a_descProfDoxyAa, ...
   a_descProfPhaseDelayDoxy, a_descProfTempDoxySbe, a_descProfDoxySbe)

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

   if (~isempty(a_descProfC1PhaseDoxy) && ~isempty(a_descProfPhaseDelayDoxy))
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf; Description; UTC time; PRES (dbar); TEMP (°C); PSAL (PSU); C1PHASE_DOXY (degree); C2PHASE_DOXY (degree); TEMP_DOXY (°C); DOXY (micromol/kg); PHASE_DELAY_DOXY (usec); TEMP_DOXY2 (°C); DOXY2 (micromol/kg)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      for idMes = length(a_descProfPres):-1:1
         mesDate = a_descProfDate(idMes);
         if (mesDate == g_decArgo_dateDef)
            mesDateStr = '';
         else
            mesDateStr = julian_2_gregorian_dec_argo(mesDate);
         end
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf; Desc. profile meas. #%d; %s; %.1f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            length(a_descProfPres)-idMes+1, mesDateStr, ...
            a_descProfPres(idMes), a_descProfTemp(idMes), a_descProfSal(idMes), ...
            a_descProfC1PhaseDoxy(idMes), a_descProfC2PhaseDoxy(idMes), a_descProfTempDoxyAa(idMes), a_descProfDoxyAa(idMes), ...
            a_descProfPhaseDelayDoxy(idMes), a_descProfTempDoxySbe(idMes), a_descProfDoxySbe(idMes));
      end
   
   elseif (~isempty(a_descProfC1PhaseDoxy))
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf; Description; UTC time; PRES (dbar); TEMP (°C); PSAL (PSU); C1PHASE_DOXY (degree); C2PHASE_DOXY (degree); TEMP_DOXY (°C); DOXY (micromol/kg)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      for idMes = length(a_descProfPres):-1:1
         mesDate = a_descProfDate(idMes);
         if (mesDate == g_decArgo_dateDef)
            mesDateStr = '';
         else
            mesDateStr = julian_2_gregorian_dec_argo(mesDate);
         end
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf; Desc. profile meas. #%d; %s; %.1f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            length(a_descProfPres)-idMes+1, mesDateStr, ...
            a_descProfPres(idMes), a_descProfTemp(idMes), a_descProfSal(idMes), ...
            a_descProfC1PhaseDoxy(idMes), a_descProfC2PhaseDoxy(idMes), a_descProfTempDoxyAa(idMes), a_descProfDoxyAa(idMes));
      end     
      
   elseif (~isempty(a_descProfPhaseDelayDoxy))
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf; Description; UTC time; PRES (dbar); TEMP (°C); PSAL (PSU); PHASE_DELAY_DOXY (usec); TEMP_DOXY2 (°C); DOXY2 (micromol/kg)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      for idMes = length(a_descProfPres):-1:1
         mesDate = a_descProfDate(idMes);
         if (mesDate == g_decArgo_dateDef)
            mesDateStr = '';
         else
            mesDateStr = julian_2_gregorian_dec_argo(mesDate);
         end
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf; Desc. profile meas. #%d; %s; %.1f; %.3f; %.3f; %.3f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            length(a_descProfPres)-idMes+1, mesDateStr, ...
            a_descProfPres(idMes), a_descProfTemp(idMes), a_descProfSal(idMes), ...
            a_descProfPhaseDelayDoxy(idMes), a_descProfTempDoxySbe(idMes), a_descProfDoxySbe(idMes));
      end      
      
   else
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf; Description; UTC time; PRES (dbar); TEMP (°C); PSAL (PSU)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      for idMes = length(a_descProfPres):-1:1
         mesDate = a_descProfDate(idMes);
         if (mesDate == g_decArgo_dateDef)
            mesDateStr = '';
         else
            mesDateStr = julian_2_gregorian_dec_argo(mesDate);
         end
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf; Desc. profile meas. #%d; %s; %.1f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            length(a_descProfPres)-idMes+1, mesDateStr, ...
            a_descProfPres(idMes), a_descProfTemp(idMes), a_descProfSal(idMes));
      end
      
   end   
end

return;
