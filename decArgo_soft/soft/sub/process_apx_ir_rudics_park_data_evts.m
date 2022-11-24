% ------------------------------------------------------------------------------
% Parse and process Apex Iridium Rudics park data from log file.
%
% SYNTAX :
%  [o_parkData] = process_apx_ir_rudics_park_data_evts(a_parkDate, a_parkMeasStr, a_decoderId)
%
% INPUT PARAMETERS :
%   a_parkDate    : date of the park measurement
%   a_parkMeasStr : input ASCII park measurement data
%   a_decoderId   : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_parkData : park data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkData] = process_apx_ir_rudics_park_data_evts(a_parkDate, a_parkMeasStr, a_decoderId)

% output parameters initialization
o_parkData = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% global time status
global g_JULD_STATUS_2;


if (isempty(a_parkMeasStr))
   return;
end

errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
end

data = [];
data1 = [];
data2 = [];
for idM= 1:length(a_parkMeasStr)
   dataStr = a_parkMeasStr{idM};
   %    fprintf('''%s''\n', dataStr);
   switch (a_decoderId)
      
      case {1101} % 030410
         
         PATTERN1 = 'PTSO:';
         PATTERN2 = 'FLBB FSig, BbSig, TSig:';
         
         if (any(strfind(dataStr, PATTERN1)))
            
            [val, count, errmsg, nextIndex] = sscanf(dataStr, 'PTSO: %fdbars %fC %fPSU     %d');
            if (~isempty(errmsg) || (count ~= 4))
               fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
               continue;
            end
            data1 = val';
            
         elseif (any(strfind(dataStr, PATTERN2)))
            
            [val, count, errmsg, nextIndex] = sscanf(dataStr, 'FLBB FSig, BbSig, TSig: %d, %d, %d');
            if (~isempty(errmsg) || (count ~= 3))
               fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
               continue;
            end
            data2 = val';
            
         else
            fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
         end
         
      case {1102, 1106, 1108} % 120210 & 060612 & 062813_2
         
         PATTERN = 'PTS:';
         
         if (any(strfind(dataStr, PATTERN)))
            
            [val, count, errmsg, nextIndex] = sscanf(dataStr, 'PTS: %fdbars %fC %fPSU');
            if (~isempty(errmsg) || (count ~= 3))
               fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
               continue;
            end
            data = val';
            
         else
            fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
         end
         
      case {1103, 1109} % 012811 & 062813_3
         
         PATTERN = 'PTS:';
         
         if (any(strfind(dataStr, PATTERN)))
            
            [val, count, errmsg, nextIndex] = sscanf(dataStr, 'PTS: %fdbars %fC %fPSU');
            if (~isempty(errmsg) || (count ~= 3))
               fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
               continue;
            end
            data = val';
            
         else
            fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
         end
         
      case {1104} % 020212
         
         PATTERN = 'PTS/O2,T2,TPhase,RawTemp:';

         if (any(strfind(dataStr, PATTERN)))
            
            [val, count, errmsg, nextIndex] = sscanf(dataStr, 'PTS/O2,T2,TPhase,RawTemp: %fdbars %fC %fPSU / %fuM %fC %f %f');
            if (~isempty(errmsg) || (count ~= 7))
               fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
               continue;
            end
            data = [val(1) val(2) val(3) val(6) val(5)];
            
         else
            fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
         end
         
      case {1105} % 030512
         
         PATTERN1 = 'PTS/O2,T2,TPhase,RawTemp:';
         PATTERN2 = 'FLBB FSig, BbSig, TSig:';
         
         if (any(strfind(dataStr, PATTERN1)))
            
            [val, count, errmsg, nextIndex] = sscanf(dataStr, 'PTS/O2,T2,TPhase,RawTemp: %fdbars %fC %fPSU / %fuM %fC %f %f');
            if (~isempty(errmsg) || (count ~= 7))
               fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
               continue;
            end
            data1 = [val(1) val(2) val(3) val(6) val(5)];
            
         elseif (any(strfind(dataStr, PATTERN2)))
            
            [val, count, errmsg, nextIndex] = sscanf(dataStr, 'FLBB FSig, BbSig, TSig: %d, %d, %d');
            if (~isempty(errmsg) || (count ~= 3))
               fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
               continue;
            end
            data2 = val';
            
         else
            fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
         end
         
      case {1107} % 062813
         
         PATTERN = 'PTS/O2,T2,TPhase,RawTemp:';

         if (any(strfind(dataStr, PATTERN)))
            
            [val, count, errmsg, nextIndex] = sscanf(dataStr, 'PTS/O2,T2,TPhase,RawTemp: %fdbars %fC %fPSU / %fuM %fC %f %f %f');
            if (~isempty(errmsg) || (count ~= 8))
               fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
               continue;
            end
            data = [val(1) val(2) val(3) val(5) val(6) val(7)];
            
         else
            fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
         end
         
      case {1110, 1112} % 092813 & 102815
         
         PATTERN1 = 'PTS/O2,T2,TPhase,RawTemp:';
         PATTERN2 = 'FLBB FSig, BbSig, TSig:';
         
         if (any(strfind(dataStr, PATTERN1)))
            
            [val, count, errmsg, nextIndex] = sscanf(dataStr, 'PTS/O2,T2,TPhase,RawTemp: %fdbars %fC %fPSU / %fuM %fC %f %f %f');
            if (~isempty(errmsg) || (count ~= 8))
               fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
               continue;
            end
            data1 = [val(1) val(2) val(3) val(5) val(6) val(7)];
            
         elseif (any(strfind(dataStr, PATTERN2)))
            
            [val, count, errmsg, nextIndex] = sscanf(dataStr, 'FLBB FSig, BbSig, TSig: %d, %d, %d');
            if (~isempty(errmsg) || (count ~= 3))
               fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
               continue;
            end
            data2 = val';
            
         else
            fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
         end
         
      case {1111} % 073014
         
         PATTERN1 = 'PTS/O2,T2,TPhase,RawTemp:';
         PATTERN2 = 'FLBB FSig, BbSig, TSig:';
         
         if (any(strfind(dataStr, PATTERN1)))
            
            [val, count, errmsg, nextIndex] = sscanf(dataStr, 'PTS/O2,T2,TPhase,RawTemp: %fdbars %fC %fPSU / %fuM %fC %f %f %f');
            if (~isempty(errmsg) || (count ~= 8))
               fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
               continue;
            end
            data1 = [val(1) val(2) val(3) val(5) val(6) val(7)];
            
         elseif (any(strfind(dataStr, PATTERN2)))
            
            [val, count, errmsg, nextIndex] = sscanf(dataStr, 'FLBB FSig, BbSig, TSig: %d, %d, %d');
            if (~isempty(errmsg) || (count ~= 3))
               fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
               continue;
            end
            data2 = val';
            
         else
            fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
         end         
         
      case {1113} % 110216
         
         PATTERN = 'PTS/O2,T2,TPhase,RawTemp:';

         if (any(strfind(dataStr, PATTERN)))
            
            [val, count, errmsg, nextIndex] = sscanf(dataStr, 'PTS/O2,T2,TPhase,RawTemp: %fdbars %fC %fPSU / %fuM %fC %f %f %f');
            if (~isempty(errmsg) || (count ~= 8))
               fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
               continue;
            end
            data = [val(1) val(2) val(3) val(5) val(6) val(7)];
            
         else
            fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
         end
         
      case {1201} % 061113
                  
         PATTERN = 'PTS/O,T,TPhase,RawTemp:';
         
         if (any(strfind(dataStr, PATTERN)))
            
            [val, count, errmsg, nextIndex] = sscanf(dataStr, 'PTS/O,T,TPhase,RawTemp: %fdbars %fC %fPSU/ %fuM %fC %f %f RPh=%f/ %fml/l %fC %f %f');
            if (~isempty(errmsg) || (count ~= 12))
               [val, count, errmsg, nextIndex] = sscanf(dataStr, 'PTS/O,T,TPhase,RawTemp: %fdbars %fC %fPSU/ NaN NaN NaN NaN NaN/ NaN NaN NaN NaN');
               if (~isempty(errmsg) || (count ~= 3))
                  fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
                  continue;
               else
                  data = [val(1) val(2) val(3)];
               end
            else
               data = [val(1) val(2) val(3) val(6) val(5) val(8) val(11) val(10)];
            end
            
         else
            fprintf('DEC_INFO: %sAnomaly detected while parsing park end measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
         end
         
      otherwise
         fprintf('DEC_INFO: %sNothing done yet in process_apx_ir_rudics_park_data_evts for decoderId #%d\n', ...
            errorHeader, a_decoderId);
         return;
   end
end

if ~(isempty(a_parkDate) && isempty(data) && isempty(data1) && isempty(data2))
   
   switch (a_decoderId)
      
      case {1101} % 030410
         
         % create the parameters
         paramJuld = get_netcdf_param_attributes('JULD');
         paramPres = get_netcdf_param_attributes('PRES');
         paramTemp = get_netcdf_param_attributes('TEMP');
         paramSal = get_netcdf_param_attributes('PSAL');
         paramFrequencyDoxy = get_netcdf_param_attributes('FREQUENCY_DOXY');
         paramFluorescenceChla = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
         paramBetaBackscattering700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');
         paramTempCpuChla = get_netcdf_param_attributes('TEMP_CPU_CHLA');
         
         data = [ ...
            paramPres.fillValue, ...
            paramTemp.fillValue, ...
            paramSal.fillValue, ...
            paramFrequencyDoxy.fillValue, ...
            paramFluorescenceChla.fillValue, ...
            paramBetaBackscattering700.fillValue, ...
            paramTempCpuChla.fillValue, ...
            ];
         
         if (~isempty(data1))
            data(1:4) = data1;
         end
         if (~isempty(data2))
            data(5:7) = data2;
         end
         
         % store park end data
         o_parkData = get_apx_profile_data_init_struct;
         o_parkData.paramList = [paramPres paramTemp paramSal paramFrequencyDoxy ...
            paramFluorescenceChla paramBetaBackscattering700 paramTempCpuChla];
         o_parkData.data = data;
         
         if (~isempty(a_parkDate))
            o_parkData.dateList = paramJuld;
            o_parkData.dates = a_parkDate;
            o_parkData.datesStatus = repmat(g_JULD_STATUS_2, size(o_parkData.dates));
         end
         
      case {1102, 1103, 1106, 1108, 1109} % 120210 & 012811 & 060612 & 062813_2 & 062813_3
         
         % create the parameters
         paramJuld = get_netcdf_param_attributes('JULD');
         paramPres = get_netcdf_param_attributes('PRES');
         paramTemp = get_netcdf_param_attributes('TEMP');
         paramSal = get_netcdf_param_attributes('PSAL');
         
         % store park end data
         o_parkData = get_apx_profile_data_init_struct;
         o_parkData.paramList = [paramPres paramTemp paramSal];
         o_parkData.data = data;
         
         if (~isempty(a_parkDate))
            o_parkData.dateList = paramJuld;
            o_parkData.dates = a_parkDate;
            o_parkData.datesStatus = repmat(g_JULD_STATUS_2, size(o_parkData.dates));
         end
         
      case {1104} % 020212
         
         % create the parameters
         paramJuld = get_netcdf_param_attributes('JULD');
         paramPres = get_netcdf_param_attributes('PRES');
         paramTemp = get_netcdf_param_attributes('TEMP');
         paramSal = get_netcdf_param_attributes('PSAL');
         paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
         paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
         
         % store park end data
         o_parkData = get_apx_profile_data_init_struct;
         o_parkData.paramList = [paramPres paramTemp paramSal ...
            paramTPhaseDoxy paramTempDoxy];
         o_parkData.data = data;
         
         if (~isempty(a_parkDate))
            o_parkData.dateList = paramJuld;
            o_parkData.dates = a_parkDate;
            o_parkData.datesStatus = repmat(g_JULD_STATUS_2, size(o_parkData.dates));
         end
         
      case {1105} % 030512
         
         % create the parameters
         paramJuld = get_netcdf_param_attributes('JULD');
         paramPres = get_netcdf_param_attributes('PRES');
         paramTemp = get_netcdf_param_attributes('TEMP');
         paramSal = get_netcdf_param_attributes('PSAL');
         paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
         paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
         paramFluorescenceChla = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
         paramBetaBackscattering700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');
         paramTempCpuChla = get_netcdf_param_attributes('TEMP_CPU_CHLA');
         
         data = [ ...
            paramPres.fillValue, ...
            paramTemp.fillValue, ...
            paramSal.fillValue, ...
            paramTPhaseDoxy.fillValue, ...
            paramTempDoxy.fillValue, ...
            paramFluorescenceChla.fillValue, ...
            paramBetaBackscattering700.fillValue, ...
            paramTempCpuChla.fillValue, ...
            ];
         
         if (~isempty(data1))
            data(1:5) = data1;
         end
         if (~isempty(data2))
            data(6:8) = data2;
         end
         
         % store park end data
         o_parkData = get_apx_profile_data_init_struct;
         o_parkData.paramList = [paramPres paramTemp paramSal ...
            paramTPhaseDoxy paramTempDoxy ...
            paramFluorescenceChla paramBetaBackscattering700 paramTempCpuChla];
         o_parkData.data = data;
         
         if (~isempty(a_parkDate))
            o_parkData.dateList = paramJuld;
            o_parkData.dates = a_parkDate;
            o_parkData.datesStatus = repmat(g_JULD_STATUS_2, size(o_parkData.dates));
         end
         
      case {1107, 1113} % 062813 & 110216
         
         % create the parameters
         paramJuld = get_netcdf_param_attributes('JULD');
         paramPres = get_netcdf_param_attributes('PRES');
         paramTemp = get_netcdf_param_attributes('TEMP');
         paramSal = get_netcdf_param_attributes('PSAL');
         paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
         paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
         paramRPhaseDoxy = get_netcdf_param_attributes('RPHASE_DOXY');
         
         % store park end data
         o_parkData = get_apx_profile_data_init_struct;
         o_parkData.paramList = [paramPres paramTemp paramSal ...
            paramTempDoxy paramTPhaseDoxy paramRPhaseDoxy];
         o_parkData.data = data;
         
         if (~isempty(a_parkDate))
            o_parkData.dateList = paramJuld;
            o_parkData.dates = a_parkDate;
            o_parkData.datesStatus = repmat(g_JULD_STATUS_2, size(o_parkData.dates));
         end
         
      case {1110, 1111, 1112} % 092813 & 073014 & 102815
         
         % create the parameters
         paramJuld = get_netcdf_param_attributes('JULD');
         paramPres = get_netcdf_param_attributes('PRES');
         paramTemp = get_netcdf_param_attributes('TEMP');
         paramSal = get_netcdf_param_attributes('PSAL');
         paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
         paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
         paramRPhaseDoxy = get_netcdf_param_attributes('RPHASE_DOXY');
         paramFluorescenceChla = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
         paramBetaBackscattering700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');
         paramTempCpuChla = get_netcdf_param_attributes('TEMP_CPU_CHLA');
         
         data = [ ...
            paramPres.fillValue, ...
            paramTemp.fillValue, ...
            paramSal.fillValue, ...
            paramTempDoxy.fillValue, ...
            paramTPhaseDoxy.fillValue, ...
            paramRPhaseDoxy.fillValue, ...
            paramFluorescenceChla.fillValue, ...
            paramBetaBackscattering700.fillValue, ...
            paramTempCpuChla.fillValue, ...
            ];
         
         if (~isempty(data1))
            data(1:6) = data1;
         end
         if (~isempty(data2))
            data(7:9) = data2;
         end
         
         % store park end data
         o_parkData = get_apx_profile_data_init_struct;
         o_parkData.paramList = [paramPres paramTemp paramSal ...
            paramTempDoxy paramTPhaseDoxy paramRPhaseDoxy ...
            paramFluorescenceChla paramBetaBackscattering700 paramTempCpuChla];
         o_parkData.data = data;
         
         if (~isempty(a_parkDate))
            o_parkData.dateList = paramJuld;
            o_parkData.dates = a_parkDate;
            o_parkData.datesStatus = repmat(g_JULD_STATUS_2, size(o_parkData.dates));
         end
         
      case {1201} % 061113
         
         % create the parameters
         paramJuld = get_netcdf_param_attributes('JULD');
         paramPres = get_netcdf_param_attributes('PRES');
         paramTemp = get_netcdf_param_attributes('TEMP');
         paramSal = get_netcdf_param_attributes('PSAL');
         paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
         paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
         paramRPhaseDoxy = get_netcdf_param_attributes('RPHASE_DOXY');
         paramPhaseDelayDoxy = get_netcdf_param_attributes('PHASE_DELAY_DOXY2');
         paramTempDoxy2 = get_netcdf_param_attributes('TEMP_DOXY2');
         
         % store park end data
         o_parkData = get_apx_profile_data_init_struct;
         o_parkData.paramList = [paramPres paramTemp paramSal ...
            paramTPhaseDoxy paramTempDoxy paramRPhaseDoxy ...
            paramPhaseDelayDoxy paramTempDoxy2];
         if (length(data) == 3)
            o_parkData.paramList = [paramPres paramTemp paramSal];
         end
         o_parkData.data = data;
         
         if (~isempty(a_parkDate))
            o_parkData.dateList = paramJuld;
            o_parkData.dates = a_parkDate;
            o_parkData.datesStatus = repmat(g_JULD_STATUS_2, size(o_parkData.dates));
         end
         
      otherwise
         fprintf('DEC_WARNING: %sNothing done yet in process_apx_ir_rudics_park_data_evts for decoderId #%d\n', ...
            errorHeader, a_decoderId);
         return;
   end
end

return;
