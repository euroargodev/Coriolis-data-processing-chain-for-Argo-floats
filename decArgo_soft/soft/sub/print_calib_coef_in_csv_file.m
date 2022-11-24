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
   
   case {1006, 1008, 1014, 1016}
      
      if (~isempty(g_decArgo_calibInfo) && ...
            (isfield(g_decArgo_calibInfo, 'OPTODE')) && ...
            (isfield(g_decArgo_calibInfo.OPTODE, 'TabPhaseCoef')) && ...
            (isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef')))
         tabPhaseCoef = g_decArgo_calibInfo.OPTODE.TabPhaseCoef;
         % the size of the tabPhaseCoef should be: size(tabDoxyCoef) = 1 4 for the
         % Aanderaa standard calibration (tabPhaseCoef(i) = PhaseCoefi).
         if (~isempty(find((size(tabPhaseCoef) == [1 4]) ~= 1, 1)))
            fprintf('ERROR: Float #%d Cycle #%d: DOXY calibration coefficients are inconsistent - PPOX_DOXY not computed\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum);
            return
         end
         tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
         % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 4 for the
         % Aanderaa standard calibration (tabDoxyCoef(i,j) = Cij).
         if (~isempty(find((size(tabDoxyCoef) == [5 4]) ~= 1, 1)))
            fprintf('ERROR: Float #%d Cycle #%d: DOXY calibration coefficients are inconsistent - PPOX_DOXY not computed\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum);
            return
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
            return
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
      
   case {1013, 1015}
      
      if (~isempty(g_decArgo_calibInfo) && ...
            (isfield(g_decArgo_calibInfo, 'OPTODE')) && ...
            (isfield(g_decArgo_calibInfo.OPTODE, 'SbeTabDoxyCoef')))
         tabDoxyCoef = g_decArgo_calibInfo.OPTODE.SbeTabDoxyCoef;
         % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 1 6
         if (~isempty(find((size(tabDoxyCoef) == [1 6]) ~= 1, 1)))
            fprintf('ERROR: Float #%d Cycle #%d: DOXY calibration coefficients are inconsistent\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum);
            return
         end
         
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; CALIBRATION COEFFICIENTS\n', ...
            g_decArgo_floatNum, -1);
         
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; Soc; %g\n', ...
            g_decArgo_floatNum, -1, tabDoxyCoef(1));
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; Foffset; %g\n', ...
            g_decArgo_floatNum, -1, tabDoxyCoef(2));
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; A; %g\n', ...
            g_decArgo_floatNum, -1, tabDoxyCoef(3));
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; B; %g\n', ...
            g_decArgo_floatNum, -1, tabDoxyCoef(4));
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; C; %g\n', ...
            g_decArgo_floatNum, -1, tabDoxyCoef(5));
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; E; %g\n', ...
            g_decArgo_floatNum, -1, tabDoxyCoef(6));
         
      end
      
   case {1101}
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; CALIBRATION COEFFICIENTS\n', ...
         g_decArgo_floatNum, -1);
      
      % print SBE optode coef
      if (~isempty(g_decArgo_calibInfo) && ...
            isfield(g_decArgo_calibInfo, 'OPTODE') && ...
            isfield(g_decArgo_calibInfo.OPTODE, 'SbeTabDoxyCoef'))
         tabDoxyCoef = g_decArgo_calibInfo.OPTODE.SbeTabDoxyCoef;
         
         
         % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 1 6
         
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; SBE 43 IDO; %s; %g\n', ...
            g_decArgo_floatNum, -1, ...
            'Soc', tabDoxyCoef(1, 1));
         
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; SBE 43 IDO; %s; %g\n', ...
            g_decArgo_floatNum, -1, ...
            'FOffset', tabDoxyCoef(1, 2));
         
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; SBE 43 IDO; %s; %g\n', ...
            g_decArgo_floatNum, -1, ...
            'CoefA', tabDoxyCoef(1, 3));
         
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; SBE 43 IDO; %s; %g\n', ...
            g_decArgo_floatNum, -1, ...
            'CoefB', tabDoxyCoef(1, 4));
         
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; SBE 43 IDO; %s; %g\n', ...
            g_decArgo_floatNum, -1, ...
            'CoefC', tabDoxyCoef(1, 5));
         
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; SBE 43 IDO; %s; %g\n', ...
            g_decArgo_floatNum, -1, ...
            'CoefE', tabDoxyCoef(1, 6));
      end
      
      % print FLBB coef
      if (~isempty(g_decArgo_calibInfo) && ...
            isfield(g_decArgo_calibInfo, 'FLBB'))
         
         fNames = fieldnames(g_decArgo_calibInfo.FLBB);
         for idField = 1:length(fNames)
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; FLBB; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               fNames{idField}, g_decArgo_calibInfo.FLBB.(fNames{idField}));
         end
      end
      
   case {1104}
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; CALIBRATION COEFFICIENTS\n', ...
         g_decArgo_floatNum, -1);
      
      % print Aanderaa optode coef
      if (~isempty(g_decArgo_calibInfo) && ...
            isfield(g_decArgo_calibInfo, 'OPTODE') && ...
            isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
         tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
         
         %       For the Aanderaa standard calibration method:
         %          size(a_tabCoef) = 5 28 and
         %          a_tabCoef(1, 1:4) = [PhaseCoef0 PhaseCoef1 ... PhaseCoef3]
         %          a_tabCoef(2, 1:6) = [TempCoef0 TempCoef1 ... TempCoef5]
         %          a_tabCoef(3, 1:28) = [FoilCoefA0 FoilCoefA1 ... FoilCoefA13 FoilCoefB0 FoilCoefB1 ... FoilCoefB13]
         %          a_tabCoef(4, 1:28) = [FoilPolyDegT0 FoilPolyDegT1 ... FoilPolyDegT27]
         %          a_tabCoef(5, 1:28) = [FoilPolyDegO0 FoilPolyDegO1 ... FoilPolyDegO27]
         
         for idC = 1:4
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; Aanderaa 4330; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['PhaseCoef' num2str(idC-1)], tabDoxyCoef(1, idC));
         end
         for idC = 1:6
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; Aanderaa 4330; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['TempCoef' num2str(idC-1)], tabDoxyCoef(2, idC));
         end
         for idC = 1:14
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; Aanderaa 4330; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['FoilCoefA' num2str(idC-1)], tabDoxyCoef(3, idC));
         end
         for idC = 15:28
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; Aanderaa 4330; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['FoilCoefB' num2str(idC-1)], tabDoxyCoef(3, idC));
         end
         for idC = 1:28
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; Aanderaa 4330; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['FoilPolyDegT' num2str(idC-1)], tabDoxyCoef(4, idC));
         end
         for idC = 1:28
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; Aanderaa 4330; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['FoilPolyDegO' num2str(idC-1)], tabDoxyCoef(5, idC));
         end
      end
      
   case {1105, 1110, 1111}
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; CALIBRATION COEFFICIENTS\n', ...
         g_decArgo_floatNum, -1);
      
      % print Aanderaa optode coef
      if (~isempty(g_decArgo_calibInfo) && ...
            isfield(g_decArgo_calibInfo, 'OPTODE') && ...
            isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
         tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
         
         %       For the Aanderaa standard calibration method:
         %          size(a_tabCoef) = 5 28 and
         %          a_tabCoef(1, 1:4) = [PhaseCoef0 PhaseCoef1 ... PhaseCoef3]
         %          a_tabCoef(2, 1:6) = [TempCoef0 TempCoef1 ... TempCoef5]
         %          a_tabCoef(3, 1:28) = [FoilCoefA0 FoilCoefA1 ... FoilCoefA13 FoilCoefB0 FoilCoefB1 ... FoilCoefB13]
         %          a_tabCoef(4, 1:28) = [FoilPolyDegT0 FoilPolyDegT1 ... FoilPolyDegT27]
         %          a_tabCoef(5, 1:28) = [FoilPolyDegO0 FoilPolyDegO1 ... FoilPolyDegO27]
         
         for idC = 1:4
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; Aanderaa 4330; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['PhaseCoef' num2str(idC-1)], tabDoxyCoef(1, idC));
         end
         for idC = 1:6
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; Aanderaa 4330; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['TempCoef' num2str(idC-1)], tabDoxyCoef(2, idC));
         end
         for idC = 1:14
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; Aanderaa 4330; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['FoilCoefA' num2str(idC-1)], tabDoxyCoef(3, idC));
         end
         for idC = 15:28
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; Aanderaa 4330; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['FoilCoefB' num2str(idC-1)], tabDoxyCoef(3, idC));
         end
         for idC = 1:28
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; Aanderaa 4330; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['FoilPolyDegT' num2str(idC-1)], tabDoxyCoef(4, idC));
         end
         for idC = 1:28
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; Aanderaa 4330; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['FoilPolyDegO' num2str(idC-1)], tabDoxyCoef(5, idC));
         end
      end
      
      % print FLBB coef
      if (~isempty(g_decArgo_calibInfo) && ...
            isfield(g_decArgo_calibInfo, 'FLBB'))
         
         fNames = fieldnames(g_decArgo_calibInfo.FLBB);
         for idField = 1:length(fNames)
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; FLBB; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               fNames{idField}, g_decArgo_calibInfo.FLBB.(fNames{idField}));
         end
      end
      
   case {1107, 1113}
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; CALIBRATION COEFFICIENTS\n', ...
         g_decArgo_floatNum, -1);
      
      % print Aanderaa optode coef
      if (~isempty(g_decArgo_calibInfo) && ...
            isfield(g_decArgo_calibInfo, 'OPTODE') && ...
            isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
         tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
         
         %       For the Stern-Volmer method: size(a_tabCoef) = 2 7 and
         %          a_tabCoef(1, 1:4) = [PhaseCoef0 PhaseCoef1 ... PhaseCoef3]
         %          a_tabCoef(2, 1:7) = [SVUFoilCoef0 SVUFoilCoef1 ... SVUFoilCoef6]
         
         for idC = 1:4
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; Aanderaa 4330; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['PhaseCoef' num2str(idC-1)], tabDoxyCoef(1, idC));
         end
         for idC = 1:7
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; Aanderaa 4330; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['SVUFoilCoef' num2str(idC-1)], tabDoxyCoef(2, idC));
         end
      end
      
   case {1112}
      
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; CALIBRATION COEFFICIENTS\n', ...
         g_decArgo_floatNum, -1);
      
      % print Aanderaa optode coef
      if (~isempty(g_decArgo_calibInfo) && ...
            isfield(g_decArgo_calibInfo, 'OPTODE') && ...
            isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
         tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
         
         %       For the Stern-Volmer method: size(a_tabCoef) = 2 7 and
         %          a_tabCoef(1, 1:4) = [PhaseCoef0 PhaseCoef1 ... PhaseCoef3]
         %          a_tabCoef(2, 1:7) = [SVUFoilCoef0 SVUFoilCoef1 ... SVUFoilCoef6]
         
         for idC = 1:4
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; Aanderaa 4330; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['PhaseCoef' num2str(idC-1)], tabDoxyCoef(1, idC));
         end
         for idC = 1:7
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; Aanderaa 4330; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               ['SVUFoilCoef' num2str(idC-1)], tabDoxyCoef(2, idC));
         end
      end
      
      % print FLBB coef
      if (~isempty(g_decArgo_calibInfo) && ...
            isfield(g_decArgo_calibInfo, 'FLBB'))
         
         fNames = fieldnames(g_decArgo_calibInfo.FLBB);
         for idField = 1:length(fNames)
            fprintf(g_decArgo_outputCsvFileId, '%d; %d; Calib; -; -; FLBB; %s; %g\n', ...
               g_decArgo_floatNum, -1, ...
               fNames{idField}, g_decArgo_calibInfo.FLBB.(fNames{idField}));
         end
      end
end

return
