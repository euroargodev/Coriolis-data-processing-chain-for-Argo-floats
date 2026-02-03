% ------------------------------------------------------------------------------
% Print "near surface" and "in air" profile data in output CSV file.
%
% SYNTAX :
% print_in_air_meas_in_csv_file_230( ...
%   a_nearSurfDate, a_nearSurfDateAdj, a_nearSurfTransDate, a_nearSurfPres, a_nearSurfTemp, a_nearSurfSal, ...
%   a_nearSurfC1PhaseDoxy, a_nearSurfC2PhaseDoxy, a_nearSurfTempDoxy, a_nearSurfPpoxDoxy, ...
%   a_nearSurfTempCountDoxy, a_nearSurfCountDoxy, a_nearSurfLedFlashingCountDoxy, a_nearSurfTempDoxy2, a_nearSurfPpoxDoxy2, ...
%   a_inAirDate, a_inAirDateAdj, a_inAirTransDate, a_inAirPres, a_inAirTemp, a_inAirSal, ...
%   a_inAirC1PhaseDoxy, a_inAirC2PhaseDoxy, a_inAirTempDoxy, a_inAirPpoxDoxy, ...
%   a_inAirTempCountDoxy, a_inAirCountDoxy, a_inAirLedFlashingCountDoxy, a_inAirTempDoxy2, a_inAirPpoxDoxy2)
%
% INPUT PARAMETERS :
%   a_nearSurfDate                 : "near surface" profile dates
%   a_nearSurfDateAdj              : "near surface" profile adjusted dates
%   a_nearSurfTransDate            : "near surface" profile transmitted date flags
%   a_nearSurfPres                 : "near surface" profile PRES
%   a_nearSurfTemp                 : "near surface" profile TEMP
%   a_nearSurfSal                  : "near surface" profile PSAL
%   a_nearSurfC1PhaseDoxy          : "near surface" profile C1PHASE_DOXY
%   a_nearSurfC2PhaseDoxy          : "near surface" profile C2PHASE_DOXY
%   a_nearSurfTempDoxy             : "near surface" profile TEMP_DOXY
%   a_nearSurfPpoxDoxy             : "near surface" profile PPOX_DOXY
%   a_nearSurfTempCountDoxy        : "near surface" profile TEMP_COUNT_DOXY
%   a_nearSurfCountDoxy            : "near surface" profile COUNT_DOXY
%   a_nearSurfLedFlashingCountDoxy : "near surface" profile LED_FLASHING_COUNT_DOXY DOXY
%   a_nearSurfTempDoxy2            : "near surface" profile TEMP_DOXY2
%   a_nearSurfPpoxDoxy2            : "near surface" profile PPOX_DOXY2
%   a_inAirDate                    : "in air" profile dates
%   a_inAirDateAdj                 : "in air" profile adjusted dates
%   a_inAirTransDate               : "in air" profile transmitted date flags
%   a_inAirPres                    : "in air" profile PRES
%   a_inAirTemp                    : "in air" profile TEMP
%   a_inAirSal                     : "in air" profile PSAL
%   a_inAirC1PhaseDoxy             : "in air" profile C1PHASE_DOXY
%   a_inAirC2PhaseDoxy             : "in air" profile C2PHASE_DOXY
%   a_inAirTempDoxy                : "in air" profile TEMP_DOXY
%   a_inAirPpoxDoxy                : "in air" profile PPOX_DOXY
%   a_inAirTempCountDoxy           : "in air" profile TEMP_COUNT_DOXY
%   a_inAirCountDoxy               : "in air" profile COUNT_DOXY
%   a_inAirLedFlashingCountDoxy    : "in air" profile LED_FLASHING_COUNT_DOXY DOXY
%   a_inAirTempDoxy2               : "in air" profile TEMP_DOXY2
%   a_inAirPpoxDoxy2               : "in air" profile PPOX_DOXY2
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/06/2024 - RNU - creation
% ------------------------------------------------------------------------------
function print_in_air_meas_in_csv_file_230( ...
   a_nearSurfDate, a_nearSurfDateAdj, a_nearSurfTransDate, a_nearSurfPres, a_nearSurfTemp, a_nearSurfSal, ...
   a_nearSurfC1PhaseDoxy, a_nearSurfC2PhaseDoxy, a_nearSurfTempDoxy, a_nearSurfPpoxDoxy, ...
   a_nearSurfTempCountDoxy, a_nearSurfCountDoxy, a_nearSurfLedFlashingCountDoxy, a_nearSurfTempDoxy2, a_nearSurfPpoxDoxy2, ...
   a_inAirDate, a_inAirDateAdj, a_inAirTransDate, a_inAirPres, a_inAirTemp, a_inAirSal, ...
   a_inAirC1PhaseDoxy, a_inAirC2PhaseDoxy, a_inAirTempDoxy, a_inAirPpoxDoxy, ...
   a_inAirTempCountDoxy, a_inAirCountDoxy, a_inAirLedFlashingCountDoxy, a_inAirTempDoxy2, a_inAirPpoxDoxy2)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_dateDef;

if (~isempty(a_nearSurfDate))
   fprintf(g_decArgo_outputCsvFileId, '%d;%d;NearSurf;NEAR SURFACE MEASUREMENTS\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   fprintf(g_decArgo_outputCsvFileId, '%d;%d;NearSurf;Description;Float time;UTC time;PRES (dbar);TEMP (degC);PSAL (PSU);C1PHASE_DOXY (degree);C2PHASE_DOXY (degree);TEMP_DOXY (degC);PPOX_DOXY (millibar);COUNT_DOXY (count);LED_FLASHING_COUNT_DOXY (count);TEMP_COUNT_DOXY (count);TEMP_DOXY2 (degC);PPOX_DOXY2 (millibar)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   for idMes = 1:length(a_nearSurfPres)
      mesDate = a_nearSurfDate(idMes);
      if (mesDate == g_decArgo_dateDef)
         mesDateStr = '';
      else
         mesDateStr = julian_2_gregorian_dec_argo(mesDate);
      end
      mesDateAdj = a_nearSurfDateAdj(idMes);
      if (mesDateAdj == g_decArgo_dateDef)
         mesDateAdjStr = '';
      else
         mesDateAdjStr = julian_2_gregorian_dec_argo(mesDateAdj);
      end
      if (a_nearSurfTransDate(idMes) == 1)
         trans = 'T';
      else
         trans = 'C';
      end

      fprintf(g_decArgo_outputCsvFileId, '%d;%d;NearSurf;Near surface meas. #%d; %s (%c); %s;%.1f;%.3f;%.3f;%.3f;%.3f;%.3f;%.3f;%d;%d;%d;%.3f;%.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idMes, mesDateStr, trans, mesDateAdjStr, ...
         a_nearSurfPres(idMes), a_nearSurfTemp(idMes), a_nearSurfSal(idMes), ...
         a_nearSurfC1PhaseDoxy(idMes), a_nearSurfC2PhaseDoxy(idMes), a_nearSurfTempDoxy(idMes), a_nearSurfPpoxDoxy(idMes), ...
         a_nearSurfCountDoxy(idMes), a_nearSurfLedFlashingCountDoxy(idMes), a_nearSurfTempCountDoxy(idMes), a_nearSurfTempDoxy2(idMes), a_nearSurfPpoxDoxy2(idMes));
   end
end

if (~isempty(a_inAirDate))
   fprintf(g_decArgo_outputCsvFileId, '%d;%d;InAir;IN AIR MEASUREMENTS\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   fprintf(g_decArgo_outputCsvFileId, '%d;%d;InAir;Description;Float time;UTC time;PRES (dbar);TEMP (degC);PSAL (PSU);C1PHASE_DOXY (degree);C2PHASE_DOXY (degree);TEMP_DOXY (degC);PPOX_DOXY (millibar);COUNT_DOXY (count);LED_FLASHING_COUNT_DOXY (count);TEMP_COUNT_DOXY (count);TEMP_DOXY2 (degC);PPOX_DOXY2 (millibar)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   for idMes = 1:length(a_inAirPres)
      mesDate = a_inAirDate(idMes);
      if (mesDate == g_decArgo_dateDef)
         mesDateStr = '';
      else
         mesDateStr = julian_2_gregorian_dec_argo(mesDate);
      end
      mesDateAdj = a_inAirDateAdj(idMes);
      if (mesDateAdj == g_decArgo_dateDef)
         mesDateAdjStr = '';
      else
         mesDateAdjStr = julian_2_gregorian_dec_argo(mesDateAdj);
      end
      if (a_inAirTransDate(idMes) == 1)
         trans = 'T';
      else
         trans = 'C';
      end

      fprintf(g_decArgo_outputCsvFileId, '%d;%d;InAir;In air meas. #%d; %s (%c); %s;%.1f;%.3f;%.3f;%.3f;%.3f;%.3f;%.3f;%d;%d;%d;%.3f;%.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idMes, mesDateStr, trans, mesDateAdjStr, ...
         a_inAirPres(idMes), a_inAirTemp(idMes), a_inAirSal(idMes), ...
         a_inAirC1PhaseDoxy(idMes), a_inAirC2PhaseDoxy(idMes), a_inAirTempDoxy(idMes), a_inAirPpoxDoxy(idMes), ...
         a_inAirCountDoxy(idMes), a_inAirLedFlashingCountDoxy(idMes), a_inAirTempCountDoxy(idMes), a_inAirTempDoxy2(idMes), a_inAirPpoxDoxy2(idMes));
   end
end

return
