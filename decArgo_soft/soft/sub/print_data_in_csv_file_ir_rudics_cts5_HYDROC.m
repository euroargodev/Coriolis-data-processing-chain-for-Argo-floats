% ------------------------------------------------------------------------------
% Print CTS5-USEA HYDROC data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_cts5_HYDROC(a_hydrocMData, a_hydrocCData)
%
% INPUT PARAMETERS :
%   a_hydrocMData : CTS5-USEA HYDROC M data
%   a_hydrocCData : CTS5-USEA HYDROC C data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/11/2022 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_in_csv_file_ir_rudics_cts5_HYDROC(a_hydrocMData, a_hydrocCData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloatStr;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_hydrocMData) && isempty(a_hydrocCData))
   return
end

if (~isempty(a_hydrocMData))
   
   fileTypeStr = 'Data_apmt';
   sensorNum = 'SENSOR_18';
   sensorName = 'Hydroc M';
   phasePrev = '';
   for idP = 1:length(a_hydrocMData)
      
      dataStruct = a_hydrocMData{idP};
      phase = dataStruct.phase;
      phase = phase(2:end-1);
      if (~strcmp(phase, phasePrev))
         measNum = 1;
      end
      phasePrev = phase;
      
      data = dataStruct.data;
      
      treat = dataStruct.treat;
      
      switch (treat)
         case {'(RW)', '(AM)', '(DW)'}
            fprintf(g_decArgo_outputCsvFileId, ['%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; PRES (dbar); ' ...
               'ACQUISITION_MODE; SIGNAL_RAW; SIGNAL_REF; PRES_IN (mbar); PRES_NDIR (mbar); TEMP_NDIR (degC); TEMP_GAS (degC); ' ...
               'HUMIDITY_GAS (%%); PUMP_POWER (W); SUPPLY_VOLTAGE (V); TOTAL_CURRENT (mA); RUNTIME (sec)\n'], ...
               g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
               fileTypeStr, phase, sensorNum, sensorName);
            outputFmt = '%s; %s;%.1f;%d;%d;%d;%f;%f;%f;%f;%f;%f;%f;%f;%d';
            if (strcmp(treat, '(RW)'))
               measType = 'raw';
            elseif (strcmp(treat, '(AM)'))
               measType = 'mean';
            elseif (strcmp(treat, '(DW)'))
               measType = 'decimated raw';
            end
         otherwise
            fprintf('ERROR: Float #%d: MPE treatment type not managed: %s\n', ...
               g_decArgo_floatNum, ...
               treat);
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

if (~isempty(a_hydrocCData))
   
   fileTypeStr = 'Data_apmt';
   sensorNum = 'SENSOR_18';
   sensorName = 'Hydroc C';
   phasePrev = '';
   for idP = 1:length(a_hydrocCData)
      
      dataStruct = a_hydrocCData{idP};
      phase = dataStruct.phase;
      phase = phase(2:end-1);
      if (~strcmp(phase, phasePrev))
         measNum = 1;
      end
      phasePrev = phase;
      
      data = dataStruct.data;
      
      treat = dataStruct.treat;
      
      switch (treat)
         case {'(RW)', '(AM)', '(DW)'}
            fprintf(g_decArgo_outputCsvFileId, ['%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; PRES (dbar); ' ...
               'ACQUISITION_MODE; SIGNAL_RAW; SIGNAL_REF; PRES_IN (mbar); PRES_NDIR (mbar); TEMP_NDIR (degC); TEMP_GAS (degC); ' ...
               'HUMIDITY_GAS (%%); PUMP_POWER (W); SUPPLY_VOLTAGE (V); TOTAL_CURRENT (mA); RUNTIME (sec)\n'], ...
               g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
               fileTypeStr, phase, sensorNum, sensorName);
            outputFmt = '%s; %s;%.1f;%d;%d;%d;%f;%f;%f;%f;%f;%f;%f;%f;%d';
            if (strcmp(treat, '(RW)'))
               measType = 'raw';
            elseif (strcmp(treat, '(AM)'))
               measType = 'mean';
            elseif (strcmp(treat, '(DW)'))
               measType = 'decimated raw';
            end
         otherwise
            fprintf('ERROR: Float #%d: MPE treatment type not managed: %s\n', ...
               g_decArgo_floatNum, ...
               treat);
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

return
