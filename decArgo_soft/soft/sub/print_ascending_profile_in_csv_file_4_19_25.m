% ------------------------------------------------------------------------------
% Print ascending profile data in output CSV file.
%
% SYNTAX :
% print_ascending_profile_in_csv_file_4_19_25( ...
%    a_ascProfOcc, a_ascProfDate, a_ascProfPres, a_ascProfTemp, a_ascProfSal, ...
%    a_acProfMolarDoxy, a_ascProfDoxy)
%
% INPUT PARAMETERS :
%   a_ascProfOcc      : ascending profile measurement redundancies
%   a_ascProfDate     : ascending profile measurement dates
%   a_ascProfPres     : ascending profile pressure measurements
%   a_ascProfTemp     : ascending profile temperature measurements
%   a_ascProfSal      : ascending profile salinity measurements
%   a_acProfMolarDoxy : ascending profile oxygen measurements (counts)
%   a_ascProfDoxy     : ascending profile oxygen measurements
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/20/2011 - RNU - creation
% ------------------------------------------------------------------------------
function print_ascending_profile_in_csv_file_4_19_25( ...
   a_ascProfOcc, a_ascProfDate, a_ascProfPres, a_ascProfTemp, a_ascProfSal, ...
   a_acProfMolarDoxy, a_ascProfDoxy)

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

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf; Description; UTC time; pressure (dbar); temperature (°C); salinity (SI); MOLAR_DOXY (micromol/l); DOXY (micromol/kg); redundancy\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   for idMes = length(a_ascProfPres):-1:1
      mesDate = a_ascProfDate(idMes);
      if (mesDate == g_decArgo_dateDef)
         mesDateStr = '';
      else
         mesDateStr = julian_2_gregorian_dec_argo(mesDate);
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf; Asc. profile meas. #%d; %s; %.1f; %.3f; %.3f; %d; %.3f; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         length(a_ascProfPres)-idMes+1, mesDateStr, ...
         a_ascProfPres(idMes), a_ascProfTemp(idMes), a_ascProfSal(idMes), a_acProfMolarDoxy(idMes), a_ascProfDoxy(idMes), a_ascProfOcc(idMes));
   end
end

return
