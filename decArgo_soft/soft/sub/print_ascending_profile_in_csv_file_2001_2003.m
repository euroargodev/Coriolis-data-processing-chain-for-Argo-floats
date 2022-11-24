% ------------------------------------------------------------------------------
% Print ascending profile data in output CSV file.
%
% SYNTAX :
%  print_ascending_profile_in_csv_file_2001_2003( ...
%    a_ascProfDate, a_ascProfDateAdj, a_ascProfPres, a_ascProfTemp, a_ascProfSal)
%
% INPUT PARAMETERS :
%   a_ascProfDate    : ascending profile dates
%   a_ascProfDateAdj : ascending profile adjusted dates
%   a_ascProfPres    : ascending profile PRES
%   a_ascProfTemp    : ascending profile TEMP
%   a_ascProfSal     : ascending profile PSAL
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/28/2016 - RNU - creation
% ------------------------------------------------------------------------------
function print_ascending_profile_in_csv_file_2001_2003( ...
   a_ascProfDate, a_ascProfDateAdj, a_ascProfPres, a_ascProfTemp, a_ascProfSal)

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
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf; Description; Float time; UTC time; PRES (dbar); TEMP (°C); PSAL (PSU)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   for idMes = 1:length(a_ascProfPres)
      if (a_ascProfDate(idMes) == g_decArgo_dateDef)
         mesDateFloatStr = '';
         mesDateUtcStr = '';
      else
         mesDateFloatStr = julian_2_gregorian_dec_argo(a_ascProfDate(idMes));
         mesDateUtcStr = julian_2_gregorian_dec_argo(a_ascProfDateAdj(idMes));
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; AscProf; Asc. profile meas. #%d; %s; %s; %.1f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idMes, mesDateFloatStr, mesDateUtcStr, ...
         a_ascProfPres(idMes), a_ascProfTemp(idMes), a_ascProfSal(idMes));
   end
end

return
