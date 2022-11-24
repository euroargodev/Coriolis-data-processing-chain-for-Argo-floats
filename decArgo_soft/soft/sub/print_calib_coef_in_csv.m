% ------------------------------------------------------------------------------
% Print DOXY calibration coefficient in output CSV file.
%
% SYNTAX :
%  print_calib_coef_in_csv(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/21/2015 - RNU - creation
% ------------------------------------------------------------------------------
function print_calib_coef_in_csv(a_decoderId)

% arrays to store calibration information
global g_decArgo_calibInfo;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% current float WMO number
global g_decArgo_floatNum;


if (~isempty(g_decArgo_calibInfo) && isfield(g_decArgo_calibInfo, 'OPTODE') && isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
   tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
   if (~isempty(tabDoxyCoef))
      
      %       For the Stern-Volmer method: size(a_tabCoef) = 1 7 and
      %          a_tabCoef(1, 1:7) = [SVUFoilCoef0 SVUFoilCoef1 ... SVUFoilCoef6]
      %       For the Aanderaa standard calibration method:
      %          size(a_tabCoef) = 5 28 and
      %          a_tabCoef(1, 1:4) = [PhaseCoef0 PhaseCoef1 ... PhaseCoef3]
      %          a_tabCoef(2, 1:6) = [TempCoef0 TempCoef1 ... TempCoef5]
      %          a_tabCoef(3, 1:28) = [FoilCoefA0 FoilCoefA1 ... FoilCoefA13 FoilCoefB0 FoilCoefB1 ... FoilCoefB13]
      %          a_tabCoef(4, 1:28) = [FoilPolyDegT0 FoilPolyDegT1 ... FoilPolyDegT27]
      %          a_tabCoef(5, 1:28) = [FoilPolyDegO0 FoilPolyDegO1 ... FoilPolyDegO27]
      %       For the Aanderaa standard calibration  + an additional two-point adjustment method:
      %          size(a_tabCoef) = 6 28 and
      %          a_tabCoef(1, 1:4) = [PhaseCoef0 PhaseCoef1 ... PhaseCoef3]
      %          a_tabCoef(2, 1:6) = [TempCoef0 TempCoef1 ... TempCoef5]
      %          a_tabCoef(3, 1:28) = [FoilCoefA0 FoilCoefA1 ... FoilCoefA13 FoilCoefB0 FoilCoefB1 ... FoilCoefB13]
      %          a_tabCoef(4, 1:28) = [FoilPolyDegT0 FoilPolyDegT1 ... FoilPolyDegT27]
      %          a_tabCoef(5, 1:28) = [FoilPolyDegO0 FoilPolyDegO1 ... FoilPolyDegO27]
      %          a_tabCoef(6, 1:2) = [ConcCoef0 ConcCoef1]
      
      if (ismember(a_decoderId, [28 29 106 202 207 208 301]))
         % as tempValues come from the CTD or from TEMP_DOXY, we don't use TempCoefI, so
         tabDoxyCoef(2, 1:6) = [0 1 0 0 0 0];
      end

      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; CALIBRATION COEFFICIENTS\n', ...
         g_decArgo_floatNum, -1);
      
      if (size(tabDoxyCoef, 1) == 1)
         for idC = 1:7
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['SVUFoilCoef' num2str(idC-1)], tabDoxyCoef(1, idC));
         end
      elseif ((size(tabDoxyCoef, 1) == 5) || (size(tabDoxyCoef, 1) == 6))
         for idC = 1:4
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['PhaseCoef' num2str(idC-1)], tabDoxyCoef(1, idC));
         end
         for idC = 1:6
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['TempCoef' num2str(idC-1)], tabDoxyCoef(2, idC));
         end
         for idC = 1:14
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['FoilCoefA' num2str(idC-1)], tabDoxyCoef(3, idC));
         end
         for idC = 15:28
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['FoilCoefB' num2str(idC-1)], tabDoxyCoef(3, idC));
         end
         for idC = 1:28
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['FoilPolyDegT' num2str(idC-1)], tabDoxyCoef(4, idC));
         end
         for idC = 1:28
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['FoilPolyDegO' num2str(idC-1)], tabDoxyCoef(5, idC));
         end
      end
      if (size(tabDoxyCoef, 1) == 6)
         for idC = 1:2
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['ConcCoef' num2str(idC-1)], tabDoxyCoef(6, idC));
         end
      end
      
      % for Arvor 2DO print SBE coef also
      if (a_decoderId == 209)
      end
   end
end

% for Arvor 2DO print SBE coef also
if (a_decoderId == 209)
   if (~isempty(g_decArgo_calibInfo) && isfield(g_decArgo_calibInfo, 'OPTODE') && isfield(g_decArgo_calibInfo.OPTODE, 'SbeTabDoxyCoef'))
      tabDoxyCoef = g_decArgo_calibInfo.OPTODE.SbeTabDoxyCoef;
      % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 1 9
      
      for idC = 1:3
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; %s; %g\n', ...
            g_decArgo_floatNum, -1, ...
            ['SBEOptodeA' num2str(idC-1)], tabDoxyCoef(1, idC));
      end
      for idC = 1:2
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; %s; %g\n', ...
            g_decArgo_floatNum, -1, ...
            ['SBEOptodeB' num2str(idC-1)], tabDoxyCoef(1, idC+3));
      end
      for idC = 1:3
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; %s; %g\n', ...
            g_decArgo_floatNum, -1, ...
            ['SBEOptodeC' num2str(idC-1)], tabDoxyCoef(1, idC+5));
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; %s; %g\n', ...
         g_decArgo_floatNum, -1, ...
         'SBEOptodeE', tabDoxyCoef(1, 9));
   end
end

return;
