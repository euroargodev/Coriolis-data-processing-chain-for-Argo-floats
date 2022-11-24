% ------------------------------------------------------------------------------
% Print "near surface" and "in air" profile data in output CSV file.
%
% SYNTAX :
%  print_in_air_meas_in_csv_file_210_211( ...
%    a_nearSurfDate, a_nearSurfTransDate, a_nearSurfPres, a_nearSurfTemp, a_nearSurfSal, ...
%    a_inAirDate, a_inAirTransDate, a_inAirPres, a_inAirTemp, a_inAirSal)
%
% INPUT PARAMETERS :
%   a_nearSurfDate      : "near surface" profile dates
%   a_nearSurfTransDate : "near surface" profile transmitted date falgs
%   a_nearSurfPres      : "near surface" profile PRES
%   a_nearSurfTemp      : "near surface" profile TEMP
%   a_nearSurfSal       : "near surface" profile PSAL
%   a_inAirDate         : "in air" profile dates
%   a_inAirTransDate    : "in air" profile transmitted date falgs
%   a_inAirPres         : "in air" profile PRES
%   a_inAirTemp         : "in air" profile TEMP
%   a_inAirSal          : "in air" profile PSAL
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/04/2016 - RNU - creation
% ------------------------------------------------------------------------------
function print_in_air_meas_in_csv_file_210_211( ...
   a_nearSurfDate, a_nearSurfTransDate, a_nearSurfPres, a_nearSurfTemp, a_nearSurfSal, ...
   a_inAirDate, a_inAirTransDate, a_inAirPres, a_inAirTemp, a_inAirSal)

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
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; NearSurf; Near surface meas. #%d; %s; %.1f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idMes, mesDateStr, ...
         a_nearSurfPres(idMes), a_nearSurfTemp(idMes), a_nearSurfSal(idMes));
   end
end

if (~isempty(a_inAirDate))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; InAir; IN AIR MEASUREMENTS\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
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
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; InAir; In air meas. #%d; %s; %.1f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idMes, mesDateStr, ...
         a_inAirPres(idMes), a_inAirTemp(idMes), a_inAirSal(idMes));
   end
end

return;
