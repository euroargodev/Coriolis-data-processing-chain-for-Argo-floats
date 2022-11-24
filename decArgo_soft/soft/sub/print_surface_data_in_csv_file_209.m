% ------------------------------------------------------------------------------
% Print ascending profile data in output CSV file.
%
% SYNTAX :
%  print_surface_data_in_csv_file_209( ...
%    a_ascProfDate, a_ascProfPres, a_ascProfTemp, a_ascProfSal, ...
%    a_ascProfC1PhaseDoxy, a_ascProfC2PhaseDoxy, a_ascProfTempDoxyAa, a_surfDoxyAa, ...
%    a_ascProfPhaseDelayDoxy, a_ascProfTempDoxySbe, a_surfDoxySbe)
%
% INPUT PARAMETERS :
%   a_ascProfDate           : ascending profile dates
%   a_ascProfPres           : ascending profile PRES
%   a_ascProfTemp           : ascending profile TEMP
%   a_ascProfSal            : ascending profile PSAL
%   a_ascProfC1PhaseDoxy    : ascending profile C1PHASE_DOXY
%   a_ascProfC2PhaseDoxy    : ascending profile C2PHASE_DOXY
%   a_ascProfTempDoxyAa     : ascending profile TEMP_DOXY (Aanderaa sensor)
%   a_surfDoxyAa            : surface PPOX_DOXY (Aanderaa sensor)
%   a_ascProfPhaseDelayDoxy : ascending profile PHASE_DELAY_DOXY
%   a_ascProfTempDoxySbe    : ascending profile TEMP_DOXY (SBE sensor)
%   a_surfDoxySbe           : surface PPOX_DOXY (SBE sensor)
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/26/2016 - RNU - creation
% ------------------------------------------------------------------------------
function print_surface_data_in_csv_file_209( ...
   a_ascProfDate, a_ascProfPres, a_ascProfTemp, a_ascProfSal, ...
   a_ascProfC1PhaseDoxy, a_ascProfC2PhaseDoxy, a_ascProfTempDoxyAa, a_surfDoxyAa, ...
   a_ascProfPhaseDelayDoxy, a_ascProfTempDoxySbe, a_surfDoxySbe)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_dateDef;

if (~isempty(a_ascProfPres))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Surf; SURFACE MEASUREMENT\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   if (~isempty(a_ascProfC1PhaseDoxy) && ~isempty(a_ascProfPhaseDelayDoxy))
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Surf; Description; UTC time; PRES (dbar); TEMP (°C); PSAL (PSU); C1PHASE_DOXY (degree); C2PHASE_DOXY (degree); TEMP_DOXY (°C); PPOX_DOXY (millibar); PHASE_DELAY_DOXY (usec); TEMP_DOXY2 (°C); PPOX_DOXY2 (millibar)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      mesDate = a_ascProfDate(end);
      if (mesDate == g_decArgo_dateDef)
         mesDateStr = '';
      else
         mesDateStr = julian_2_gregorian_dec_argo(mesDate);
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Surf; Surface meas.; %s; %.1f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         mesDateStr, ...
         a_ascProfPres(end), a_ascProfTemp(end), a_ascProfSal(end), ...
         a_ascProfC1PhaseDoxy(end), a_ascProfC2PhaseDoxy(end), a_ascProfTempDoxyAa(end), a_surfDoxyAa, ...
         a_ascProfPhaseDelayDoxy(end), a_ascProfTempDoxySbe(end), a_surfDoxySbe);
      
   elseif (~isempty(a_ascProfC1PhaseDoxy))
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Surf; Description; UTC time; PRES (dbar); TEMP (°C); PSAL (PSU); C1PHASE_DOXY (degree); C2PHASE_DOXY (degree); TEMP_DOXY (°C); PPOX_DOXY (millibar)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      mesDate = a_ascProfDate(end);
      if (mesDate == g_decArgo_dateDef)
         mesDateStr = '';
      else
         mesDateStr = julian_2_gregorian_dec_argo(mesDate);
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Surf; Surface meas.; %s; %.1f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         mesDateStr, ...
         a_ascProfPres(end), a_ascProfTemp(end), a_ascProfSal(end), ...
         a_ascProfC1PhaseDoxy(end), a_ascProfC2PhaseDoxy(end), a_ascProfTempDoxyAa(end), a_surfDoxyAa);
      
   elseif (~isempty(a_ascProfPhaseDelayDoxy))
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Surf; Description; UTC time; PRES (dbar); TEMP (°C); PSAL (PSU); PHASE_DELAY_DOXY (usec); TEMP_DOXY2 (°C); PPOX_DOXY2 (millibar)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      mesDate = a_ascProfDate(end);
      if (mesDate == g_decArgo_dateDef)
         mesDateStr = '';
      else
         mesDateStr = julian_2_gregorian_dec_argo(mesDate);
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Surf; Surf meas.; %s; %.1f; %.3f; %.3f; %.3f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         mesDateStr, ...
         a_ascProfPres(end), a_ascProfTemp(end), a_ascProfSal(end), ...
         a_ascProfPhaseDelayDoxy(end), a_ascProfTempDoxySbe(end), a_surfDoxySbe);
      
   else
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Surf; Description; UTC time; PRES (dbar); TEMP (°C); PSAL (PSU)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      mesDate = a_ascProfDate(end);
      if (mesDate == g_decArgo_dateDef)
         mesDateStr = '';
      else
         mesDateStr = julian_2_gregorian_dec_argo(mesDate);
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Surf; Surf meas.; %s; %.1f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         mesDateStr, ...
         a_ascProfPres(end), a_ascProfTemp(end), a_ascProfSal(end));
      
   end
   
end

return;
