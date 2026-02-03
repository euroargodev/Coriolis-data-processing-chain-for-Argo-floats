% ------------------------------------------------------------------------------
% Print CTS5-USEA TRIDENTE data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_cts5_TRIDENTE(a_tridente3Data, a_tridente9Data)
%
% INPUT PARAMETERS :
%   a_tridente3Data : CTS5-USEA TRIDENTE (3 channels) data
%   a_tridente9Data : CTS5-USEA TRIDENTE (9 channels) data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/19/2025 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_in_csv_file_ir_rudics_cts5_TRIDENTE(a_tridente3Data, a_tridente9Data)

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloatStr;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% sensor list
global g_decArgo_sensorMountedOnFloat;


if (isempty(a_tridente3Data) && isempty(a_tridente9Data))
   return
end

if (ismember('TRIDENTE', g_decArgo_sensorMountedOnFloat))

   if (~isempty(a_tridente3Data))

      fileTypeStr = 'Data_apmt';
      sensorNum = 'SENSOR_24';
      sensorName = 'Tridente (3 channels)';
      phasePrev = '';
      for idP = 1:length(a_tridente3Data)

         dataStruct = a_tridente3Data{idP};

         phase = dataStruct.phase;
         phase = phase(2:end-1);
         if (~strcmp(phase, phasePrev))
            measNum = 1;
         end
         phasePrev = phase;

         treat = dataStruct.treat;

         data = dataStruct.data;

         fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; PRES (dbar); BETA_BACKSCATTERING700_SCALED (m-1sr-1); CHLA (mg/m3); CDOM (ppb)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            fileTypeStr, phase, sensorNum, sensorName);
         outputFmt = '%s; %s;%.1f;%g;%g;%g';

         if (strcmp(treat, '(RW)'))
            measType = 'raw';
         elseif (strcmp(treat, '(AM)'))
            measType = 'mean';
         elseif (strcmp(treat, '(DW)'))
            measType = 'decimated raw';
         end

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

   elseif (~isempty(a_tridente9Data))

      fileTypeStr = 'Data_apmt';
      sensorNum = 'SENSOR_24';
      sensorName = 'Tridente (9 channels)';
      phasePrev = '';
      for idP = 1:length(a_tridente9Data)

         dataStruct = a_tridente9Data{idP};

         phase = dataStruct.phase;
         phase = phase(2:end-1);
         if (~strcmp(phase, phasePrev))
            measNum = 1;
         end
         phasePrev = phase;

         treat = dataStruct.treat;

         data = dataStruct.data;

         fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; PRES (dbar); BETA_BACKSCATTERING700_SCALED (m-1sr-1); CHLA (mg/m3); CDOM (ppb); BETA_BACKSCATTERING700_SCALED_MED (m-1sr-1); CHLA_MED (mg/m3); CDOM_MED (ppb); BETA_BACKSCATTERING700_SCALED_STD (m-1sr-1); CHLA_STD (mg/m3); CDOM_STD (ppb)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            fileTypeStr, phase, sensorNum, sensorName);
         outputFmt = '%s; %s;%.1f;%g;%g;%g;%g;%g;%g;%g;%g;%g';

         if (strcmp(treat, '(RW)'))
            measType = 'raw';
         elseif (strcmp(treat, '(AM)'))
            measType = 'mean';
         elseif (strcmp(treat, '(DW)'))
            measType = 'decimated raw';
         end

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

elseif (ismember('TRIDENTE2', g_decArgo_sensorMountedOnFloat))

   if (~isempty(a_tridente3Data))

      fileTypeStr = 'Data_apmt';
      sensorNum = 'SENSOR_24';
      sensorName = 'Tridente (3 channels)';
      phasePrev = '';
      for idP = 1:length(a_tridente3Data)

         dataStruct = a_tridente3Data{idP};

         phase = dataStruct.phase;
         phase = phase(2:end-1);
         if (~strcmp(phase, phasePrev))
            measNum = 1;
         end
         phasePrev = phase;

         treat = dataStruct.treat;

         data = dataStruct.data;

         fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; PRES (dbar); BETA_BACKSCATTERING700_SCALED (m-1sr-1); BETA_BACKSCATTERING700_SCALED_2 (m-1sr-1); CHLA_2 (mg/m3)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            fileTypeStr, phase, sensorNum, sensorName);
         outputFmt = '%s; %s;%.1f;%g;%g;%g';

         if (strcmp(treat, '(RW)'))
            measType = 'raw';
         elseif (strcmp(treat, '(AM)'))
            measType = 'mean';
         elseif (strcmp(treat, '(DW)'))
            measType = 'decimated raw';
         end

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

   elseif (~isempty(a_tridente9Data))

      fileTypeStr = 'Data_apmt';
      sensorNum = 'SENSOR_24';
      sensorName = 'Tridente (9 channels)';
      phasePrev = '';
      for idP = 1:length(a_tridente9Data)

         dataStruct = a_tridente9Data{idP};

         phase = dataStruct.phase;
         phase = phase(2:end-1);
         if (~strcmp(phase, phasePrev))
            measNum = 1;
         end
         phasePrev = phase;

         treat = dataStruct.treat;

         data = dataStruct.data;

         fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; PRES (dbar); BETA_BACKSCATTERING700_SCALED (m-1sr-1); BETA_BACKSCATTERING700_SCALED_2 (m-1sr-1); CHLA_2 (mg/m3); BETA_BACKSCATTERING700_SCALED_MED (m-1sr-1); BETA_BACKSCATTERING700_SCALED_2_MED (m-1sr-1); CHLA_2_MED (mg/m3); BETA_BACKSCATTERING700_SCALED_STD (m-1sr-1); BETA_BACKSCATTERING700_SCALED_2_STD (m-1sr-1); CHLA_2_STD (mg/m3)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            fileTypeStr, phase, sensorNum, sensorName);
         outputFmt = '%s; %s;%.1f;%g;%g;%g;%g;%g;%g;%g;%g;%g';

         if (strcmp(treat, '(RW)'))
            measType = 'raw';
         elseif (strcmp(treat, '(AM)'))
            measType = 'mean';
         elseif (strcmp(treat, '(DW)'))
            measType = 'decimated raw';
         end

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

end

return
