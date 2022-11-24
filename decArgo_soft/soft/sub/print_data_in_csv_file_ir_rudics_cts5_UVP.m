% ------------------------------------------------------------------------------
% Print CTS5-USEA UVP data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_cts5_UVP(a_uvpLpmData, a_uvpBlackData)
%
% INPUT PARAMETERS :
%   a_uvpLpmData   : CTS5-USEA UVP-LPM data
%   a_uvpBlackData : CTS5-USEA UVP-BLACK data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_in_csv_file_ir_rudics_cts5_UVP(a_uvpLpmData, a_uvpBlackData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloatStr;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_uvpLpmData) && isempty(a_uvpBlackData))
   return
end

if (~isempty(a_uvpLpmData))
   
   fileTypeStr = 'Data_apmt';
   sensorNum = 'SENSOR_08';
   sensorName = 'Uvp (LPM)';
   phasePrev = '';
   for idP = 1:length(a_uvpLpmData)
      
      dataStruct = a_uvpLpmData{idP};
      
      phase = dataStruct.phase;
      phase = phase(2:end-1);
      if (~strcmp(phase, phasePrev))
         measNum = 1;
      end
      phasePrev = phase;
      
      treat = dataStruct.treat;
      
      switch (treat)
         case {'(RW)', '(DW)'}
            if (ismember(phase, [{'PARK'} {'SHORT_PARK'} {'SURFACE'}]))
               fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; IMAGE_NUMBER_PARTICLES (count); DEPTH_SIZE_SPECTRA_PARTICLES (dbar); TEMP_PARTICLES (degC); NB_SIZE_SPECTRA_PARTICLES (nb/analyzed images);;;;;;;;;;;;;;;;;; GREY_SIZE_SPECTRA_PARTICLES (bit)\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                  fileTypeStr, phase, sensorNum, sensorName);
               outputFmt = '%s; %s;%d;%.1f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d';
            else
               fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; DEPTH_SIZE_SPECTRA_PARTICLES (dbar); TEMP_PARTICLES (degC); NB_SIZE_SPECTRA_PARTICLES (Nb/analyzed images);;;;;;;;;;;;;;;;;; GREY_SIZE_SPECTRA_PARTICLES (bit)\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                  fileTypeStr, phase, sensorNum, sensorName);
               outputFmt = '%s; %s;%.1f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d';
            end
            if (strcmp(treat, '(RW)'))
               measType = 'raw';
            elseif (strcmp(treat, '(AM)'))
               measType = 'mean';
            elseif (strcmp(treat, '(DW)'))
               measType = 'decimated raw';
            end
         case {'(AM)'}
            fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; IMAGE_NUMBER_PARTICLES (count); DEPTH_SIZE_SPECTRA_PARTICLES (dbar); TEMP_PARTICLES (degC); NB_SIZE_SPECTRA_PARTICLES (nb/analyzed images);;;;;;;;;;;;;;;;;; GREY_SIZE_SPECTRA_PARTICLES (bit)\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
               fileTypeStr, phase, sensorNum, sensorName);
            outputFmt = '%s; %s;%d;%.1f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%.4f;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d';
            measType = 'mean';
         otherwise
            fprintf('ERROR: Float #%d: UVP-LPM treatment type not managed: %s\n', ...
               g_decArgo_floatNum, ...
               treat);
      end
      
      data = dataStruct.data;
      datesAdj = adjust_time_cts5(data(:, 1));
      for idL = 1:size(data, 1)
         fprintf(g_decArgo_outputCsvFileId, ['%d; %s; %s; %s; %s; %s; %s; meas #%4d (%s); ' outputFmt '\n'], ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            fileTypeStr, phase, sensorNum, sensorName, ...
            measNum, measType, ...
            julian_2_gregorian_dec_argo(data(idL, 1)), julian_2_gregorian_dec_argo(datesAdj(idL)), ...
            data(idL, 2:end));
         measNum = measNum + 1;
      end
   end
end

if (~isempty(a_uvpBlackData))
   
   fileTypeStr = 'Data_apmt';
   sensorNum = 'SENSOR_08';
   sensorName = 'Uvp (BLACK)';
   phasePrev = '';
   for idP = 1:length(a_uvpBlackData)
      
      dataStruct = a_uvpBlackData{idP};
      
      phase = dataStruct.phase;
      phase = phase(2:end-1);
      if (~strcmp(phase, phasePrev))
         measNum = 1;
      end
      phasePrev = phase;
      
      treat = dataStruct.treat;
      
      switch (treat)
         case {'(RW)', '(DW)'}
            fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; DEPTH_BLACK_PARTICLE (dbar); BLACK_TEMP (degC); BLACK_NB_SIZE_SPECTRA_PARTICLES (count)\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
               fileTypeStr, phase, sensorNum, sensorName);
            outputFmt = '%s; %s;%.1f;%.4f;%d;%d;%d;%d;%d';
            if (strcmp(treat, '(RW)'))
               measType = 'raw';
            elseif (strcmp(treat, '(DW)'))
               measType = 'decimated raw';
            end
         otherwise
            fprintf('ERROR: Float #%d: UVP-BLACK treatment type not managed: %s\n', ...
               g_decArgo_floatNum, ...
               treat);
      end
      
      data = dataStruct.data;
      datesAdj = adjust_time_cts5(data(:, 1));
      for idL = 1:size(data, 1)
         fprintf(g_decArgo_outputCsvFileId, ['%d; %s; %s; %s; %s; %s; %s; meas #%4d (%s); ' outputFmt '\n'], ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            fileTypeStr, phase, sensorNum, sensorName, ...
            measNum, measType, ...
            julian_2_gregorian_dec_argo(data(idL, 1)), julian_2_gregorian_dec_argo(datesAdj(idL)), ...
            data(idL, 2:end));
         measNum = measNum + 1;
      end
   end
end

return
