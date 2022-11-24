% ------------------------------------------------------------------------------
% Print descending profile data in output CSV file.
%
% SYNTAX :
%  print_descending_profile_in_csv_file_1_3_11_12_17_24_30_31( ...
%    a_descProfOcc, a_descProfDate, a_descProfPres, a_descProfTemp, a_descProfSal)
%
% INPUT PARAMETERS :
%   a_descProfOcc  : descending profile measurement redundancies
%   a_descProfDate : descending profile measurement dates
%   a_descProfPres : descending profile pressure measurements
%   a_descProfTemp : descending profile temperature measurements
%   a_descProfSal  : descending profile salinity measurements
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function print_descending_profile_in_csv_file_1_3_11_12_17_24_30_31( ...
   a_descProfOcc, a_descProfDate, a_descProfPres, a_descProfTemp, a_descProfSal)

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

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf; Description; UTC time; pressure (dbar); temperature (degC); salinity (SI); redundancy\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   for idMes = length(a_descProfPres):-1:1
      mesDate = a_descProfDate(idMes);
      if (mesDate == g_decArgo_dateDef)
         mesDateStr = '';
      else
         mesDateStr = julian_2_gregorian_dec_argo(mesDate);
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; DescProf; Desc. profile meas. #%d; %s; %.1f; %.3f; %.3f; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         length(a_descProfPres)-idMes+1, mesDateStr, ...
         a_descProfPres(idMes), a_descProfTemp(idMes), a_descProfSal(idMes), a_descProfOcc(idMes));
   end
end

return
