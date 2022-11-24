% ------------------------------------------------------------------------------
% Print "near surface" and "in air" profile data in output CSV file.
%
% SYNTAX :
%  print_in_air_meas_in_csv_file_210_to_216( ...
%    a_nearSurfDate, a_nearSurfTransDate, a_nearSurfPres, a_nearSurfTemp, a_nearSurfSal, ...
%    a_nearSurfC1PhaseDoxy, a_nearSurfC2PhaseDoxy, a_nearSurfTempDoxy, a_nearSurfDoxy, ...
%    a_inAirDate, a_inAirTransDate, a_inAirPres, a_inAirTemp, a_inAirSal, ...
%    a_inAirC1PhaseDoxy, a_inAirC2PhaseDoxy, a_inAirTempDoxy, a_inAirDoxy)
%
% INPUT PARAMETERS :
%   a_nearSurfDate        : "near surface" profile dates
%   a_nearSurfTransDate   : "near surface" profile transmitted date flags
%   a_nearSurfPres        : "near surface" profile PRES
%   a_nearSurfTemp        : "near surface" profile TEMP
%   a_nearSurfSal         : "near surface" profile PSAL
%   a_nearSurfC1PhaseDoxy : "near surface" profile C1PHASE_DOXY
%   a_nearSurfC2PhaseDoxy : "near surface" profile C2PHASE_DOXY
%   a_nearSurfTempDoxy    : "near surface" profile TEMP_DOXY
%   a_nearSurfDoxy        : "near surface" profile DOXY
%   a_inAirDate           : "in air" profile dates
%   a_inAirTransDate      : "in air" profile transmitted date flags
%   a_inAirPres           : "in air" profile PRES
%   a_inAirTemp           : "in air" profile TEMP
%   a_inAirSal            : "in air" profile PSAL
%   a_inAirC1PhaseDoxy    : "in air" profile C1PHASE_DOXY
%   a_inAirC2PhaseDoxy    : "in air" profile C2PHASE_DOXY
%   a_inAirTempDoxy       : "in air" profile TEMP_DOXY
%   a_inAirDoxy           : "in air" profile DOXY
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/07/2017 - RNU - creation
% ------------------------------------------------------------------------------
function print_in_air_meas_in_csv_file_210_to_216( ...
   a_nearSurfDate, a_nearSurfTransDate, a_nearSurfPres, a_nearSurfTemp, a_nearSurfSal, ...
   a_nearSurfC1PhaseDoxy, a_nearSurfC2PhaseDoxy, a_nearSurfTempDoxy, a_nearSurfDoxy, ...
   a_inAirDate, a_inAirTransDate, a_inAirPres, a_inAirTemp, a_inAirSal, ...
   a_inAirC1PhaseDoxy, a_inAirC2PhaseDoxy, a_inAirTempDoxy, a_inAirDoxy)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_dateDef;

if (~isempty(a_nearSurfDate))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; NearSurf; NEAR SURFACE MEASUREMENTS\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   if (isempty(a_nearSurfC1PhaseDoxy))
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; NearSurf; Description; UTC time; PRES (dbar); TEMP (°C); PSAL (PSU)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      for idMes = 1:length(a_nearSurfPres)
         mesDate = a_nearSurfDate(idMes);
         if (mesDate == g_decArgo_dateDef)
            mesDateStr = '';
         else
            mesDateStr = julian_2_gregorian_dec_argo(mesDate);
         end
         if (a_nearSurfTransDate(idMes) == 1)
            trans = 'T';
         else
            trans = 'C';
         end
         
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; NearSurf; Near surface meas. #%d; %s (%c); %.1f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            idMes, mesDateStr, trans, ...
            a_nearSurfPres(idMes), a_nearSurfTemp(idMes), a_nearSurfSal(idMes));
      end
   else
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; NearSurf; Description; UTC time; PRES (dbar); TEMP (°C); PSAL (PSU); C1PHASE_DOXY (degree); C2PHASE_DOXY (degree); TEMP_DOXY (°C); DOXY (micromol/kg)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      for idMes = 1:length(a_nearSurfPres)
         mesDate = a_nearSurfDate(idMes);
         if (mesDate == g_decArgo_dateDef)
            mesDateStr = '';
         else
            mesDateStr = julian_2_gregorian_dec_argo(mesDate);
         end
         if (a_nearSurfTransDate(idMes) == 1)
            trans = 'T';
         else
            trans = 'C';
         end
         
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; NearSurf; Near surface meas. #%d; %s (%c); %.1f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            idMes, mesDateStr, trans, ...
            a_nearSurfPres(idMes), a_nearSurfTemp(idMes), a_nearSurfSal(idMes), ...
            a_nearSurfC1PhaseDoxy(idMes), a_nearSurfC2PhaseDoxy(idMes), a_nearSurfTempDoxy(idMes), a_nearSurfDoxy(idMes));
      end
   end
end

if (~isempty(a_inAirDate))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; InAir; IN AIR MEASUREMENTS\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   if (isempty(a_inAirC1PhaseDoxy))
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; InAir; Description; UTC time; PRES (dbar); TEMP (°C); PSAL (PSU)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      for idMes = 1:length(a_inAirPres)
         mesDate = a_inAirDate(idMes);
         if (mesDate == g_decArgo_dateDef)
            mesDateStr = '';
         else
            mesDateStr = julian_2_gregorian_dec_argo(mesDate);
         end
         if (a_inAirTransDate(idMes) == 1)
            trans = 'T';
         else
            trans = 'C';
         end
         
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; InAir; In air meas. #%d; %s (%c); %.1f; %.3f; %.3f\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            idMes, mesDateStr, trans, ...
            a_inAirPres(idMes), a_inAirTemp(idMes), a_inAirSal(idMes));
      end
   else
      if (~isempty(a_inAirDoxy))
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; InAir; Description; UTC time; PRES (dbar); TEMP (°C); PSAL (PSU); C1PHASE_DOXY (degree); C2PHASE_DOXY (degree); TEMP_DOXY (°C); DOXY (micromol/kg)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
         
         for idMes = 1:length(a_inAirPres)
            mesDate = a_inAirDate(idMes);
            if (mesDate == g_decArgo_dateDef)
               mesDateStr = '';
            else
               mesDateStr = julian_2_gregorian_dec_argo(mesDate);
            end
            if (a_inAirTransDate(idMes) == 1)
               trans = 'T';
            else
               trans = 'C';
            end
            
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; InAir; In air meas. #%d; %s (%c); %.1f; %.3f; %.3f; %.3f; %.3f; %.3f; %.3f\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, ...
               idMes, mesDateStr, trans, ...
               a_inAirPres(idMes), a_inAirTemp(idMes), a_inAirSal(idMes), ...
               a_inAirC1PhaseDoxy(idMes), a_inAirC2PhaseDoxy(idMes), a_inAirTempDoxy(idMes), a_inAirDoxy(idMes));
         end
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; InAir; Description; UTC time; PRES (dbar); TEMP (°C); PSAL (PSU); C1PHASE_DOXY (degree); C2PHASE_DOXY (degree); TEMP_DOXY (°C)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
         
         for idMes = 1:length(a_inAirPres)
            mesDate = a_inAirDate(idMes);
            if (mesDate == g_decArgo_dateDef)
               mesDateStr = '';
            else
               mesDateStr = julian_2_gregorian_dec_argo(mesDate);
            end
            if (a_inAirTransDate(idMes) == 1)
               trans = 'T';
            else
               trans = 'C';
            end
            
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; InAir; In air meas. #%d; %s (%c); %.1f; %.3f; %.3f; %.3f; %.3f; %.3f\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, ...
               idMes, mesDateStr, trans, ...
               a_inAirPres(idMes), a_inAirTemp(idMes), a_inAirSal(idMes), ...
               a_inAirC1PhaseDoxy(idMes), a_inAirC2PhaseDoxy(idMes), a_inAirTempDoxy(idMes));
         end
      end
   end
end

return;
