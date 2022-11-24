% ------------------------------------------------------------------------------
% Print descending profile data in output CSV file.
%
% SYNTAX :
%  print_descending_profile_in_csv_file_2001_2003( ...
%    a_descProfDate, a_descProfDateAdj, a_descProfPres, a_descProfTemp, a_descProfSal)
%
% INPUT PARAMETERS :
%   a_descProfDate    : descending profile dates
%   a_descProfDateAdj : descending profile adjusted dates
%   a_descProfPres    : descending profile PRES
%   a_descProfTemp    : descending profile TEMP
%   a_descProfSal     : descending profile PSAL
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
function print_descending_profile_in_csv_file_2001_2003( ...
   a_descProfDate, a_descProfDateAdj, a_descProfPres, a_descProfTemp, a_descProfSal)

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
   
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf; Description; Float time; UTC time; PRES (dbar); TEMP (degC); PSAL (PSU)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   
   for idMes = length(a_descProfPres):-1:1
      if (a_descProfDate(idMes) == g_decArgo_dateDef)
         mesDateFloatStr = '';
         mesDateUtcStr = '';
      else
         mesDateFloatStr = julian_2_gregorian_dec_argo(a_descProfDate(idMes));
         mesDateUtcStr = julian_2_gregorian_dec_argo(a_descProfDateAdj(idMes));
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf; Desc. profile meas. #%d; %s; %s; %.1f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         length(a_descProfPres)-idMes+1, mesDateFloatStr, mesDateUtcStr, ...
         a_descProfPres(idMes), a_descProfTemp(idMes), a_descProfSal(idMes));
   end
end

return
