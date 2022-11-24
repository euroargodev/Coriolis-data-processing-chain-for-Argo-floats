% ------------------------------------------------------------------------------
% Parse and process Apex Iridium Rudics surface data from log file.
%
% SYNTAX :
%  [o_surfData] = process_apx_ir_rudics_surf_data_evts(a_events, a_decoderId)
%
% INPUT PARAMETERS :
%   a_events    : input log file event data
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_surfData : surface data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_surfData] = process_apx_ir_rudics_surf_data_evts(a_events, a_decoderId)

% output parameters initialization
o_surfData = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% global time status
global g_JULD_STATUS_2;


errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
end

idEvts = strcmp({a_events.cmd}, 'TelemetryInit()');
if (~isempty(idEvts))
   events = a_events(idEvts);
   
   PATTERN = 'Profile';
   
   cycleNum = [];
   for idEv = 1:length(events)
      dataStr = events(idEv).info;
      %    fprintf('''%s''\n', dataStr);
      
      if (any(strfind(dataStr, PATTERN)))
         
         idF = strfind(dataStr, '.');
         if (~isempty(idF))
            cycleNum = str2num(dataStr(length(PATTERN+1):idF(1)-1));
         else
            fprintf('DEC_INFO: %sNot managed information for ''%s'' cmd (from evts) ''%s'' => ignored\n', errorHeader, 'TelemetryInit()', dataStr);
         end
      end
   end
end

idEvts = strcmp({a_events.cmd}, 'GetSurfaceObs()');
if (~isempty(idEvts))
   events = a_events(idEvts);
   
   data = [];
   for idEv = 1:length(events)
      dataStr = events(idEv).info;
      %    fprintf('''%s''\n', dataStr);
      
      switch (a_decoderId)
         
         case {1101} % 030410
            
            HEADER = 'P/FSig,BbSig,TSig:';
            if (any(strfind(dataStr, HEADER)))
               [val, count, errmsg, nextIndex] = sscanf(dataStr(length(HEADER)+1:end), '%fdbars/%d,%d,%d');
               if (~isempty(errmsg) || (count ~= 4))
                  fprintf('DEC_INFO: %sAnomaly detected while parsing surface measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
                  continue;
               end
               data = [data; events(idEv).time  val' events(idEv).mTime];
            else
               fprintf('DEC_INFO: %sAnomaly detected while parsing surface measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
            end
            
         case {1105} % 030512
            
            HEADER = 'P/O2,T2,TPhase,RawTemp/FSig,BbSig,TSig:';
            if (any(strfind(dataStr, HEADER)))
               [val, count, errmsg, nextIndex] = sscanf(dataStr(length(HEADER)+1:end), '%fdbars / %fuM %fC %f %f / %d,%d,%d');
               if (~isempty(errmsg) || (count ~= 8))
                  fprintf('DEC_INFO: %sAnomaly detected while parsing surface measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
                  continue;
               end
               data = [data; events(idEv).time val(1) val(4) val(3) val(6) val(7) val(8) events(idEv).mTime];
            else
               fprintf('DEC_INFO: %sAnomaly detected while parsing surface measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
            end
            
         case {1110, 1111, 1112} % 092813 & 073014 & 102815
            
            HEADER = 'P/O2,T2,TPhase,RPhase,RawTemp/FSig,BbSig,TSig:';
            if (any(strfind(dataStr, HEADER)))
               [val, count, errmsg, nextIndex] = sscanf(dataStr(length(HEADER)+1:end), '%fdbars / %fuM %fC %f %f %f / %d,%d,%d');
               if (~isempty(errmsg) || (count ~= 9))
                  fprintf('DEC_INFO: %sAnomaly detected while parsing surface measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
                  continue;
               end
               data = [data; events(idEv).time val(1) val(3) val(4) val(5) val(6) val(7) val(8) events(idEv).mTime];
            else
               fprintf('DEC_INFO: %sAnomaly detected while parsing surface measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
            end
            
         case {1201} % 061113
            
            HEADER = 'Pressure failed for surface Optode sample.';
            if (any(strfind(dataStr, HEADER)))
               % surface measurements are not reported in log file
            else
               fprintf('DEC_INFO: %sAnomaly detected while parsing surface measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
            end
            
         otherwise
            fprintf('DEC_WARNING: %sNothing done yet in process_apx_ir_rudics_surf_data_evts for decoderId #%d\n', ...
               errorHeader, a_decoderId);
            return;
      end
   end
end

if (~isempty(data))
   
   switch (a_decoderId)
      
      case {1101} % 030410
         
         % create the parameters
         paramJuld = get_netcdf_param_attributes('JULD');
         paramPres = get_netcdf_param_attributes('PRES');
         paramFluorescenceChla = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
         paramBetaBackscattering700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');
         paramTempCpuChla = get_netcdf_param_attributes('TEMP_CPU_CHLA');
         
         % store surface data
         o_surfData = get_apx_profile_data_init_struct;
         
         % add parameter variables to the data structure
         o_surfData.dateList = paramJuld;
         o_surfData.paramList = [paramPres ...
            paramFluorescenceChla paramBetaBackscattering700 paramTempCpuChla];
         
         % add parameter data to the data structure
         o_surfData.dates = data(:, 1);
         o_surfData.mTime = data(:, end);
         o_surfData.data = data(:, 2:5);
         
         % add date status to the data structure
         o_surfData.datesStatus = repmat(g_JULD_STATUS_2, size(o_surfData.dates));
         
      case {1105} % 030512
         
         % create the parameters
         paramJuld = get_netcdf_param_attributes('JULD');
         paramPres = get_netcdf_param_attributes('PRES');
         paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
         paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
         paramFluorescenceChla = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
         paramBetaBackscattering700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');
         paramTempCpuChla = get_netcdf_param_attributes('TEMP_CPU_CHLA');
         
         % store surface data
         o_surfData = get_apx_profile_data_init_struct;
         
         % add parameter variables to the data structure
         o_surfData.dateList = paramJuld;
         o_surfData.paramList = [paramPres ...
            paramTPhaseDoxy paramTempDoxy ...
            paramFluorescenceChla paramBetaBackscattering700 paramTempCpuChla];
         
         % add parameter data to the data structure
         o_surfData.dates = data(:, 1);
         o_surfData.mTime = data(:, end);
         o_surfData.data = data(:, 2:7);
         
         % add date status to the data structure
         o_surfData.datesStatus = repmat(g_JULD_STATUS_2, size(o_surfData.dates));
         
      case {1110, 1111, 1112} % 092813 & 073014 & 102815
         
         % create the parameters
         paramJuld = get_netcdf_param_attributes('JULD');
         paramPres = get_netcdf_param_attributes('PRES');
         paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
         paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
         paramRPhaseDoxy = get_netcdf_param_attributes('RPHASE_DOXY');
         paramFluorescenceChla = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
         paramBetaBackscattering700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');
         paramTempCpuChla = get_netcdf_param_attributes('TEMP_CPU_CHLA');
         
         % store surface data
         o_surfData = get_apx_profile_data_init_struct;
         
         % add parameter variables to the data structure
         o_surfData.dateList = paramJuld;
         o_surfData.paramList = [paramPres ...
            paramTempDoxy paramTPhaseDoxy paramRPhaseDoxy ...
            paramFluorescenceChla paramBetaBackscattering700 paramTempCpuChla];
         
         % add parameter data to the data structure
         o_surfData.dates = data(:, 1);
         o_surfData.mTime = data(:, end);
         o_surfData.data = data(:, 2:8);
         
         % add date status to the data structure
         o_surfData.datesStatus = repmat(g_JULD_STATUS_2, size(o_surfData.dates));
         
      otherwise
         fprintf('DEC_WARNING: %sNothing done yet in process_apx_ir_rudics_surf_data_evts for decoderId #%d\n', ...
            errorHeader, a_decoderId);
         return;
   end
end

return;
