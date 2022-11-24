% ------------------------------------------------------------------------------
% Print DOXY calibration coefficient in output CSV file.
%
% SYNTAX :
%  print_calib_coef_in_csv_file(a_decoderId)
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
%   01/26/2016 - RNU - creation
% ------------------------------------------------------------------------------
function print_calib_coef_in_csv_file(a_decoderId)

% arrays to store calibration information
global g_decArgo_calibInfo;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   case {1006, 1008}
      
      if (~isempty(g_decArgo_calibInfo) && ...
            (isfield(g_decArgo_calibInfo, 'OPTODE')) && ...
            (isfield(g_decArgo_calibInfo.OPTODE, 'TabPhaseCoef')) && ...
            (isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef')))
         tabPhaseCoef = g_decArgo_calibInfo.OPTODE.TabPhaseCoef;
         % the size of the tabPhaseCoef should be: size(tabDoxyCoef) = 1 4 for the
         % Aanderaa standard calibration (tabPhaseCoef(i) = PhaseCoefi).
         if (~isempty(find((size(tabPhaseCoef) == [1 4]) ~= 1, 1)))
            fprintf('ERROR: Float #%d Cycle #%d: DOXY calibration coefficients are inconsistent => PPOX_DOXY not computed\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum);
            return;
         end
         tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
         % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 4 for the
         % Aanderaa standard calibration (tabDoxyCoef(i,j) = Cij).
         if (~isempty(find((size(tabDoxyCoef) == [5 4]) ~= 1, 1)))
            fprintf('ERROR: Float #%d Cycle #%d: DOXY calibration coefficients are inconsistent => PPOX_DOXY not computed\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum);
            return;
         end
         
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; CALIBRATION COEFFICIENTS\n', ...
            g_decArgo_floatNum, -1);
         
         if (~isempty(tabPhaseCoef))
            for idC = 1:size(tabPhaseCoef, 2)
               fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; %s; %g\n', ...
                  g_decArgo_floatNum, -1, ...
                  ['PhaseCoef' num2str(idC-1)], tabPhaseCoef(1, idC));
            end
         end
         if (~isempty(tabDoxyCoef))
            for idL = 1:size(tabDoxyCoef, 1)
               for idC = 1:size(tabDoxyCoef, 2)
                  fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; %s; %g\n', ...
                     g_decArgo_floatNum, -1, ...
                     ['C' num2str(idL-1) num2str(idC-1)], tabDoxyCoef(idL, idC));
               end
            end
         end
      end
      
   case {1009}
      
      if (~isempty(g_decArgo_calibInfo) && ...
            (isfield(g_decArgo_calibInfo, 'OPTODE')) && ...
            (isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef')))
         tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
         % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7
         if (~isempty(find((size(tabDoxyCoef) == [2 7]) ~= 1, 1)))
            fprintf('ERROR: Float #%d Cycle #%d: DOXY calibration coefficients are inconsistent\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum);
            return;
         end
         
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; CALIBRATION COEFFICIENTS\n', ...
            g_decArgo_floatNum, -1);
         
         for idC = 1:4
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['PhaseCoef' num2str(idC-1)], tabDoxyCoef(1, idC));
         end
         for idC = 1:7
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['SVUFoilCoef' num2str(idC-1)], tabDoxyCoef(2, idC));
         end

      end
end

return;
