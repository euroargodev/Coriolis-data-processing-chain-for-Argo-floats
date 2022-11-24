% ------------------------------------------------------------------------------
% Print drift measurement data in output CSV file.
%
% SYNTAX :
% print_drift_measurements_in_csv_file_27_28_29_32( ...
%    a_parkOcc, a_parkDate, a_parkTransDate, a_parkPres, a_parkTemp, a_parkSal, ...
%    a_parkTPhaseDoxy, a_parkDoxy)
%
% INPUT PARAMETERS :
%   a_parkOcc         : redundancy of parking measurements
%   a_parkDate        : date of parking measurements
%   a_parkTransDate   : transmitted (=1) or computed (=0) date of parking
%                       measurements
%   a_parkPres        : parking pressure measurements
%   a_parkTemp        : parking temperature measurements
%   a_parkSal         : parking salinity measurements
%   a_parkTPhaseDoxy  : parking oxygen TPHASE measurements
%   a_parkDoxy        : parking oxygen DOXY measurements
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/06/2013 - RNU - creation
% ------------------------------------------------------------------------------
function print_drift_measurements_in_csv_file_27_28_29_32( ...
   a_parkOcc, a_parkDate, a_parkTransDate, a_parkPres, a_parkTemp, a_parkSal, ...
   a_parkTPhaseDoxy, a_parkDoxy)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_dateDef;

if (~isempty(a_parkPres))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift; DRIFT MEASUREMENTS\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift; Description; UTC time (Trans./Comp.); pressure (dbar); temperature (°C); salinity (SI); TPHASE_DOXY (degree); DOXY (micromol/kg); redundancy\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   if (~isempty(find(a_parkDate ~= g_decArgo_dateDef, 1)))
      % drift measurements are dated
      for idMes = 1:length(a_parkDate)
         mesDate = a_parkDate(idMes);
         if (mesDate == g_decArgo_dateDef)
            mesDateStr = '';
         else
            mesDateStr = julian_2_gregorian_dec_argo(mesDate);
         end
         if (a_parkTransDate(idMes) == 1)
            trans = 'T';
         else
            trans = 'C';
         end

         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift; Drift meas. #%d; %s (%c); %.1f; %.3f; %.3f; %.3f; %.3f; %d\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            idMes, mesDateStr, trans, ...
            a_parkPres(idMes), a_parkTemp(idMes), a_parkSal(idMes), ...
            a_parkTPhaseDoxy(idMes), a_parkDoxy(idMes), a_parkOcc(idMes));
      end
   else
      % drift measurements are not dated
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift; DO NOT CONSIDER MEASUREMENTS ORDER\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);

      for idMes = 1:length(a_parkPres)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Drift; Drift meas.; ; %.1f; %.3f; %.3f; %.3f; %.3f; %d\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            a_parkPres(idMes), a_parkTemp(idMes), a_parkSal(idMes), ...
            a_parkTPhaseDoxy(idMes), a_parkDoxy(idMes), a_parkOcc(idMes));
      end
   end
end

return;
