% ------------------------------------------------------------------------------
% Compute derived parameters for Apex Iridium Rudics & navis floats.
%
% SYNTAX :
%  [o_surfDataLog, ...
%    o_driftData, o_parkData, o_parkDataEng, ...
%    o_profLrData, o_profHrData, ...
%    o_nearSurfData, ...
%    o_surfDataBladderDeflated, o_surfDataBladderInflated, o_surfDataMsg, ...
%    o_timeDataLog] = ...
%    compute_derived_parameters_apx_ir_rudics(a_surfDataLog, ...
%    a_driftData, a_parkData, a_parkDataEng, ...
%    a_profLrData, a_profHrData, ...
%    a_nearSurfData, ...
%    a_surfDataBladderDeflated, a_surfDataBladderInflated, a_surfDataMsg, ...
%    a_timeDataLog, ...
%    a_decoderId)
%
% INPUT PARAMETERS :
%   a_surfDataLog             : input surf data from log file
%   a_driftData               : input drift data
%   a_parkData                : input park data
%   a_parkDataEng             : input park data from engineering data
%   a_profLrData              : input profile LR data
%   a_profHrData              : input profile HR data
%   a_nearSurfData            : input NS data
%   a_surfDataBladderDeflated : input surface data
%   a_surfDataBladderInflated : input surface data
%   a_surfDataMsg             : input surface data from engineering data
%   a_timeDataLog             : input time data from log file
%   a_decoderId               : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_surfDataLog             : output surf data from log file
%   o_driftData               : output drift data
%   o_parkData                : output park data
%   o_parkDataEng             : output park data from engineering data
%   o_profLrData              : output profile LR data
%   o_profHrData              : output profile HR data
%   o_nearSurfData            : output NS data
%   o_surfDataBladderDeflated : output surface data
%   o_surfDataBladderInflated : output surface data
%   o_surfDataMsg             : output surface data from engineering data
%   o_timeDataLog             : output time data from log file
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_surfDataLog, ...
   o_driftData, o_parkData, o_parkDataEng, ...
   o_profLrData, o_profHrData, ...
   o_nearSurfData, ...
   o_surfDataBladderDeflated, o_surfDataBladderInflated, o_surfDataMsg, ...
   o_timeDataLog] = ...
   compute_derived_parameters_apx_ir_rudics(a_surfDataLog, ...
   a_driftData, a_parkData, a_parkDataEng, ...
   a_profLrData, a_profHrData, ...
   a_nearSurfData, ...
   a_surfDataBladderDeflated, a_surfDataBladderInflated, a_surfDataMsg, ...
   a_timeDataLog, ...
   a_decoderId)

% output parameters initialization
o_surfDataLog = a_surfDataLog;
o_driftData = a_driftData;
o_parkData = a_parkData;
o_parkDataEng = a_parkDataEng;
o_profLrData = a_profLrData;
o_profHrData = a_profHrData;
o_nearSurfData = a_nearSurfData;
o_surfDataBladderDeflated = a_surfDataBladderDeflated;
o_surfDataBladderInflated = a_surfDataBladderInflated;
o_surfDataMsg = a_surfDataMsg;
o_timeDataLog = a_timeDataLog;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% CTD data of the previous cycle
global g_decArgo_floatNumPrev;
global g_decArgo_cycleNumPrev;
global g_decArgo_profLrCtdDataPrev;
global g_decArgo_profHrCtdDataPrev;


switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {1101}
      
      % compute DOXY
      o_parkData = compute_doxy(o_parkData, a_decoderId);
      o_parkDataEng = compute_doxy(o_parkDataEng, a_decoderId);
      if (~isempty(o_timeDataLog))
         o_timeDataLog.parkEndMeas = compute_doxy(o_timeDataLog.parkEndMeas, a_decoderId);
      end
      o_profLrData = compute_doxy(o_profLrData, a_decoderId);
      o_profHrData = compute_doxy(o_profHrData, a_decoderId);
      
      % compute CHLA
      o_surfDataLog = compute_chla(o_surfDataLog);
      o_parkData = compute_chla(o_parkData);
      o_parkDataEng = compute_chla(o_parkDataEng);
      if (~isempty(o_timeDataLog))
         o_timeDataLog.parkEndMeas = compute_chla(o_timeDataLog.parkEndMeas);
      end
      o_profLrData = compute_chla(o_profLrData);
      o_surfDataMsg = compute_chla(o_surfDataMsg);
      
      % compute BBP 700
      profLrCtdData = get_ctd(o_profLrData);
      profHrCtdData = get_ctd(o_profHrData);
      if ((g_decArgo_floatNumPrev == g_decArgo_floatNum) && ...
            (g_decArgo_cycleNumPrev == g_decArgo_cycleNum - 1))
         o_surfDataLog = compute_bbp700(o_surfDataLog, g_decArgo_profLrCtdDataPrev, g_decArgo_profHrCtdDataPrev);
      else
         o_surfDataLog = compute_bbp700(o_surfDataLog, [], []);
      end
      o_parkData = compute_bbp700(o_parkData, [], []);
      o_parkDataEng = compute_bbp700(o_parkDataEng, [], []);
      if (~isempty(o_timeDataLog))
         o_timeDataLog.parkEndMeas = compute_bbp700(o_timeDataLog.parkEndMeas, [], []);
      end
      o_profLrData = compute_bbp700(o_profLrData, [], []);
      o_surfDataMsg = compute_bbp700(o_surfDataMsg, profLrCtdData, profHrCtdData);
      
      g_decArgo_floatNumPrev = g_decArgo_floatNum;
      g_decArgo_cycleNumPrev = g_decArgo_cycleNum;
      g_decArgo_profLrCtdDataPrev = profLrCtdData;
      g_decArgo_profHrCtdDataPrev = profHrCtdData;
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {1104, 1107, 1113}
      
      % compute DOXY
      o_parkData = compute_doxy(o_parkData, a_decoderId);
      if (~isempty(o_timeDataLog))
         o_timeDataLog.parkEndMeas = compute_doxy(o_timeDataLog.parkEndMeas, a_decoderId);
      end
      o_profLrData = compute_doxy(o_profLrData, a_decoderId);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {1105, 1110, 1111, 1112}
      
      % compute DOXY
      o_parkData = compute_doxy(o_parkData, a_decoderId);
      o_parkDataEng = compute_doxy(o_parkDataEng, a_decoderId);
      if (~isempty(o_timeDataLog))
         o_timeDataLog.parkEndMeas = compute_doxy(o_timeDataLog.parkEndMeas, a_decoderId);
      end
      o_profLrData = compute_doxy(o_profLrData, a_decoderId);
      
      % compute PPOX_DOXY
      o_surfDataLog = compute_ppox_doxy(o_surfDataLog, a_decoderId);
      o_surfDataMsg = compute_ppox_doxy(o_surfDataMsg, a_decoderId);
      
      % compute CHLA
      o_surfDataLog = compute_chla(o_surfDataLog);
      o_parkData = compute_chla(o_parkData);
      o_parkDataEng = compute_chla(o_parkDataEng);
      if (~isempty(o_timeDataLog))
         o_timeDataLog.parkEndMeas = compute_chla(o_timeDataLog.parkEndMeas);
      end
      o_profLrData = compute_chla(o_profLrData);
      o_surfDataMsg = compute_chla(o_surfDataMsg);
      
      % compute BBP700
      profLrCtdData = get_ctd(o_profLrData);
      profHrCtdData = get_ctd(o_profHrData);
      if ((g_decArgo_floatNumPrev == g_decArgo_floatNum) && ...
            (g_decArgo_cycleNumPrev == g_decArgo_cycleNum - 1))
         o_surfDataLog = compute_bbp700(o_surfDataLog, g_decArgo_profLrCtdDataPrev, g_decArgo_profHrCtdDataPrev);
      else
         o_surfDataLog = compute_bbp700(o_surfDataLog, [], []);
      end
      o_parkData = compute_bbp700(o_parkData, [], []);
      o_parkDataEng = compute_bbp700(o_parkDataEng, [], []);
      if (~isempty(o_timeDataLog))
         o_timeDataLog.parkEndMeas = compute_bbp700(o_timeDataLog.parkEndMeas, [], []);
      end
      o_profLrData = compute_bbp700(o_profLrData, [], []);
      o_surfDataMsg = compute_bbp700(o_surfDataMsg, profLrCtdData, profHrCtdData);
      
      g_decArgo_floatNumPrev = g_decArgo_floatNum;
      g_decArgo_cycleNumPrev = g_decArgo_cycleNum;
      g_decArgo_profLrCtdDataPrev = profLrCtdData;
      g_decArgo_profHrCtdDataPrev = profHrCtdData;
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {1201}
      
      % compute DOXY
      o_driftData = compute_doxy(o_driftData, a_decoderId);
      o_parkData = compute_doxy(o_parkData, a_decoderId);
      o_parkDataEng = compute_doxy(o_parkDataEng, a_decoderId);
      if (~isempty(o_timeDataLog))
         o_timeDataLog.parkEndMeas = compute_doxy(o_timeDataLog.parkEndMeas, a_decoderId);
      end
      o_profLrData = compute_doxy(o_profLrData, a_decoderId);
      profLrCtdData = get_ctd(o_profLrData);
      profHrCtdData = get_ctd(o_profHrData);
      o_nearSurfData = compute_doxy_NS(o_nearSurfData, a_decoderId, profLrCtdData, profHrCtdData);
      
      % compute PPOX_DOXY
      o_nearSurfData = compute_ppox_doxy(o_nearSurfData, a_decoderId);
      o_surfDataBladderDeflated = compute_ppox_doxy(o_surfDataBladderDeflated, a_decoderId);
      o_surfDataBladderInflated = compute_ppox_doxy(o_surfDataBladderInflated, a_decoderId);
      
      % compute DOXY2
      o_driftData = compute_doxy2(o_driftData, a_decoderId);
      o_parkData = compute_doxy2(o_parkData, a_decoderId);
      o_parkDataEng = compute_doxy2(o_parkDataEng, a_decoderId);
      if (~isempty(o_timeDataLog))
         o_timeDataLog.parkEndMeas = compute_doxy2(o_timeDataLog.parkEndMeas, a_decoderId);
      end
      o_profLrData = compute_doxy2(o_profLrData, a_decoderId);
      
end

return;

% ------------------------------------------------------------------------------
% Compute sub-surface DOXY for Apex Iridium Rudics & Navis floats.
%
% SYNTAX :
%  [o_outputData] = compute_doxy(a_inputData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_inputData : input data
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_outputData : output data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_outputData] = compute_doxy(a_inputData, a_decoderId)

% output parameters initialization
o_outputData = a_inputData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (isempty(o_outputData))
   return;
end

switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {1101}
      
      paramPres = get_netcdf_param_attributes('PRES');
      paramTemp = get_netcdf_param_attributes('TEMP');
      paramSal = get_netcdf_param_attributes('PSAL');
      paramFrequencyDoxy = get_netcdf_param_attributes('FREQUENCY_DOXY');
      paramDoxy = get_netcdf_param_attributes('DOXY');
      
      if (iscell(o_outputData))
         for idS = 1:length(o_outputData)
            dataStruct = o_outputData{idS};
            idPres = find(strcmp({dataStruct.paramList.name}, 'PRES') == 1);
            idTemp = find(strcmp({dataStruct.paramList.name}, 'TEMP') == 1);
            idPsal = find(strcmp({dataStruct.paramList.name}, 'PSAL') == 1);
            idFrequencyDoxy = find(strcmp({dataStruct.paramList.name}, 'FREQUENCY_DOXY') == 1);
            
            if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal) && ~isempty(idFrequencyDoxy))
               % compute DOXY
               doxy = compute_DOXY_SBE_1013_1015_1101(dataStruct.data(:, idFrequencyDoxy), ...
                  paramFrequencyDoxy.fillValue, ...
                  dataStruct.data(:, idPres), ...
                  dataStruct.data(:, idTemp), ...
                  dataStruct.data(:, idPsal), ...
                  paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
                  paramDoxy.fillValue);
               
               % add DOXY to the data structure
               dataStruct.paramList = [dataStruct.paramList paramDoxy];
               dataStruct.data = [dataStruct.data doxy];
               
               if (~isempty(dataStruct.dataAdj))
                  % compute DOXY
                  doxy = compute_DOXY_SBE_1013_1015_1101(dataStruct.dataAdj(:, idFrequencyDoxy), ...
                     paramFrequencyDoxy.fillValue, ...
                     dataStruct.dataAdj(:, idPres), ...
                     dataStruct.dataAdj(:, idTemp), ...
                     dataStruct.dataAdj(:, idPsal), ...
                     paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
                     paramDoxy.fillValue);
                  
                  % add DOXY to the data structure
                  dataStruct.dataAdj = [dataStruct.dataAdj doxy];
               end
            end
            
            o_outputData{idS} = dataStruct;
         end
      else
         dataStruct = o_outputData;
         idPres = find(strcmp({dataStruct.paramList.name}, 'PRES') == 1);
         idTemp = find(strcmp({dataStruct.paramList.name}, 'TEMP') == 1);
         idPsal = find(strcmp({dataStruct.paramList.name}, 'PSAL') == 1);
         idFrequencyDoxy = find(strcmp({dataStruct.paramList.name}, 'FREQUENCY_DOXY') == 1);
         
         if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal) && ~isempty(idFrequencyDoxy))
            % compute DOXY
            doxy = compute_DOXY_SBE_1013_1015_1101(dataStruct.data(:, idFrequencyDoxy), ...
               paramFrequencyDoxy.fillValue, ...
               dataStruct.data(:, idPres), ...
               dataStruct.data(:, idTemp), ...
               dataStruct.data(:, idPsal), ...
               paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
               paramDoxy.fillValue);
            
            % add DOXY to the data structure
            dataStruct.paramList = [dataStruct.paramList paramDoxy];
            dataStruct.data = [dataStruct.data doxy];
            
            if (~isempty(dataStruct.dataAdj))
               % compute DOXY
               doxy = compute_DOXY_SBE_1013_1015_1101(dataStruct.dataAdj(:, idFrequencyDoxy), ...
                  paramFrequencyDoxy.fillValue, ...
                  dataStruct.dataAdj(:, idPres), ...
                  dataStruct.dataAdj(:, idTemp), ...
                  dataStruct.dataAdj(:, idPsal), ...
                  paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
                  paramDoxy.fillValue);
               
               % add DOXY to the data structure
               dataStruct.dataAdj = [dataStruct.dataAdj doxy];
            end
         end
         
         o_outputData = dataStruct;
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {1104, 1105, 1110, 1111}
      
      paramPres = get_netcdf_param_attributes('PRES');
      paramTemp = get_netcdf_param_attributes('TEMP');
      paramSal = get_netcdf_param_attributes('PSAL');
      paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
      paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
      paramDoxy = get_netcdf_param_attributes('DOXY');
      
      if (iscell(o_outputData))
         for idS = 1:length(o_outputData)
            dataStruct = o_outputData{idS};
            idPres = find(strcmp({dataStruct.paramList.name}, 'PRES') == 1);
            idTemp = find(strcmp({dataStruct.paramList.name}, 'TEMP') == 1);
            idPsal = find(strcmp({dataStruct.paramList.name}, 'PSAL') == 1);
            idTPhaseDoxy = find(strcmp({dataStruct.paramList.name}, 'TPHASE_DOXY') == 1);
            idTempDoxy = find(strcmp({dataStruct.paramList.name}, 'TEMP_DOXY') == 1);
            
            if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal) && ...
                  ~isempty(idTPhaseDoxy) && ~isempty(idTempDoxy))
               
               % compute DOXY
               doxy = compute_DOXY_1104_1105_1110_1111( ...
                  dataStruct.data(:, idTPhaseDoxy), ...
                  dataStruct.data(:, idTempDoxy), ...
                  paramTPhaseDoxy.fillValue, ...
                  paramTempDoxy.fillValue, ...
                  dataStruct.data(:, idPres), ...
                  dataStruct.data(:, idTemp), ...
                  dataStruct.data(:, idPsal), ...
                  paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
                  paramDoxy.fillValue);
               
               % add DOXY to the data structure
               dataStruct.paramList = [dataStruct.paramList paramDoxy];
               dataStruct.data = [dataStruct.data doxy];
               
               if (~isempty(dataStruct.dataAdj))
                  % compute DOXY
                  doxy = compute_DOXY_1104_1105_1110_1111( ...
                     dataStruct.dataAdj(:, idTPhaseDoxy), ...
                     dataStruct.dataAdj(:, idTempDoxy), ...
                     paramTPhaseDoxy.fillValue, ...
                     paramTempDoxy.fillValue, ...
                     dataStruct.dataAdj(:, idPres), ...
                     dataStruct.dataAdj(:, idTemp), ...
                     dataStruct.dataAdj(:, idPsal), ...
                     paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
                     paramDoxy.fillValue);
                  
                  % add DOXY to the data structure
                  dataStruct.dataAdj = [dataStruct.dataAdj doxy];
               end
            end
            
            o_outputData{idS} = dataStruct;
         end
      else
         dataStruct = o_outputData;
         idPres = find(strcmp({dataStruct.paramList.name}, 'PRES') == 1);
         idTemp = find(strcmp({dataStruct.paramList.name}, 'TEMP') == 1);
         idPsal = find(strcmp({dataStruct.paramList.name}, 'PSAL') == 1);
         idTPhaseDoxy = find(strcmp({dataStruct.paramList.name}, 'TPHASE_DOXY') == 1);
         idTempDoxy = find(strcmp({dataStruct.paramList.name}, 'TEMP_DOXY') == 1);
         
         if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal) && ...
               ~isempty(idTPhaseDoxy) && ~isempty(idTempDoxy))
            
            % compute DOXY
            doxy = compute_DOXY_1104_1105_1110_1111( ...
               dataStruct.data(:, idTPhaseDoxy), ...
               dataStruct.data(:, idTempDoxy), ...
               paramTPhaseDoxy.fillValue, ...
               paramTempDoxy.fillValue, ...
               dataStruct.data(:, idPres), ...
               dataStruct.data(:, idTemp), ...
               dataStruct.data(:, idPsal), ...
               paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
               paramDoxy.fillValue);
            
            % add DOXY to the data structure
            dataStruct.paramList = [dataStruct.paramList paramDoxy];
            dataStruct.data = [dataStruct.data doxy];
            
            if (~isempty(dataStruct.dataAdj))
               % compute DOXY
               doxy = compute_DOXY_1104_1105_1110_1111( ...
                  dataStruct.dataAdj(:, idTPhaseDoxy), ...
                  dataStruct.dataAdj(:, idTempDoxy), ...
                  paramTPhaseDoxy.fillValue, ...
                  paramTempDoxy.fillValue, ...
                  dataStruct.dataAdj(:, idPres), ...
                  dataStruct.dataAdj(:, idTemp), ...
                  dataStruct.dataAdj(:, idPsal), ...
                  paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
                  paramDoxy.fillValue);
               
               % add DOXY to the data structure
               dataStruct.dataAdj = [dataStruct.dataAdj doxy];
            end
         end
         
         o_outputData = dataStruct;
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {1107, 1112, 1113, 1201}
      
      paramPres = get_netcdf_param_attributes('PRES');
      paramTemp = get_netcdf_param_attributes('TEMP');
      paramSal = get_netcdf_param_attributes('PSAL');
      paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
      paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
      paramDoxy = get_netcdf_param_attributes('DOXY');
      
      if (iscell(o_outputData))
         for idS = 1:length(o_outputData)
            dataStruct = o_outputData{idS};
            idPres = find(strcmp({dataStruct.paramList.name}, 'PRES') == 1);
            idTemp = find(strcmp({dataStruct.paramList.name}, 'TEMP') == 1);
            idPsal = find(strcmp({dataStruct.paramList.name}, 'PSAL') == 1);
            idTPhaseDoxy = find(strcmp({dataStruct.paramList.name}, 'TPHASE_DOXY') == 1);
            idTempDoxy = find(strcmp({dataStruct.paramList.name}, 'TEMP_DOXY') == 1);
            
            if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal) && ...
                  ~isempty(idTPhaseDoxy) && ~isempty(idTempDoxy))
               
               % compute DOXY
               doxy = compute_DOXY_1009_1107_1112_1113_1201( ...
                  dataStruct.data(:, idTPhaseDoxy), ...
                  dataStruct.data(:, idTempDoxy), ...
                  paramTPhaseDoxy.fillValue, ...
                  paramTempDoxy.fillValue, ...
                  dataStruct.data(:, idPres), ...
                  dataStruct.data(:, idTemp), ...
                  dataStruct.data(:, idPsal), ...
                  paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
                  paramDoxy.fillValue);
               
               % add DOXY to the data structure
               dataStruct.paramList = [dataStruct.paramList paramDoxy];
               dataStruct.data = [dataStruct.data doxy];
               
               if (~isempty(dataStruct.dataAdj))
                  % compute DOXY
                  doxy = compute_DOXY_1009_1107_1112_1113_1201( ...
                     dataStruct.dataAdj(:, idTPhaseDoxy), ...
                     dataStruct.dataAdj(:, idTempDoxy), ...
                     paramTPhaseDoxy.fillValue, ...
                     paramTempDoxy.fillValue, ...
                     dataStruct.dataAdj(:, idPres), ...
                     dataStruct.dataAdj(:, idTemp), ...
                     dataStruct.dataAdj(:, idPsal), ...
                     paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
                     paramDoxy.fillValue);
                  
                  % add DOXY to the data structure
                  dataStruct.dataAdj = [dataStruct.dataAdj doxy];
               end
            end
            
            o_outputData{idS} = dataStruct;
         end
      else
         dataStruct = o_outputData;
         idPres = find(strcmp({dataStruct.paramList.name}, 'PRES') == 1);
         idTemp = find(strcmp({dataStruct.paramList.name}, 'TEMP') == 1);
         idPsal = find(strcmp({dataStruct.paramList.name}, 'PSAL') == 1);
         idTPhaseDoxy = find(strcmp({dataStruct.paramList.name}, 'TPHASE_DOXY') == 1);
         idTempDoxy = find(strcmp({dataStruct.paramList.name}, 'TEMP_DOXY') == 1);
         
         if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal) && ...
               ~isempty(idTPhaseDoxy) && ~isempty(idTempDoxy))
            
            % compute DOXY
            doxy = compute_DOXY_1009_1107_1112_1113_1201( ...
               dataStruct.data(:, idTPhaseDoxy), ...
               dataStruct.data(:, idTempDoxy), ...
               paramTPhaseDoxy.fillValue, ...
               paramTempDoxy.fillValue, ...
               dataStruct.data(:, idPres), ...
               dataStruct.data(:, idTemp), ...
               dataStruct.data(:, idPsal), ...
               paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
               paramDoxy.fillValue);
            
            % add DOXY to the data structure
            dataStruct.paramList = [dataStruct.paramList paramDoxy];
            dataStruct.data = [dataStruct.data doxy];
            
            if (~isempty(dataStruct.dataAdj))
               % compute DOXY
               doxy = compute_DOXY_1009_1107_1112_1113_1201( ...
                  dataStruct.dataAdj(:, idTPhaseDoxy), ...
                  dataStruct.dataAdj(:, idTempDoxy), ...
                  paramTPhaseDoxy.fillValue, ...
                  paramTempDoxy.fillValue, ...
                  dataStruct.dataAdj(:, idPres), ...
                  dataStruct.dataAdj(:, idTemp), ...
                  dataStruct.dataAdj(:, idPsal), ...
                  paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
                  paramDoxy.fillValue);
               
               % add DOXY to the data structure
               dataStruct.dataAdj = [dataStruct.dataAdj doxy];
            end
         end
         
         o_outputData = dataStruct;
      end
      
   otherwise
      fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in compute_doxy for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_decoderId);
end

return;

% ------------------------------------------------------------------------------
% Compute NS DOXY for Navis floats.
%
% SYNTAX :
%  [o_outputData] = compute_doxy_NS(a_inputData, a_decoderId, a_lrCtdData, a_hrCtdData)
%
% INPUT PARAMETERS :
%   a_inputData : input data
%   a_decoderId : float decoder Id
%   a_lrCtdData : CTD data of LR profile
%   a_hrCtdData : CTD data of HR profile
%
% OUTPUT PARAMETERS :
%   o_outputData : output data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_outputData] = compute_doxy_NS(a_inputData, a_decoderId, a_lrCtdData, a_hrCtdData)

% output parameters initialization
o_outputData = a_inputData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (isempty(o_outputData))
   return;
end

switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {1201}
      
      ctdData = [];
      if (~isempty(a_lrCtdData) || ~isempty(a_hrCtdData))
         [ctdData, ctdDataAdj] = get_shallowest_ctd(a_lrCtdData, a_hrCtdData);
      end
      
      if (~isempty(ctdData))
         paramPres = get_netcdf_param_attributes('PRES');
         paramTemp = get_netcdf_param_attributes('TEMP');
         paramSal = get_netcdf_param_attributes('PSAL');
         paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
         paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
         paramDoxy = get_netcdf_param_attributes('DOXY');
         
         if (iscell(o_outputData))
            for idS = 1:length(o_outputData)
               dataStruct = o_outputData{idS};
               idPres = find(strcmp({dataStruct.paramList.name}, 'PRES') == 1);
               idTPhaseDoxy = find(strcmp({dataStruct.paramList.name}, 'TPHASE_DOXY') == 1);
               idTempDoxy = find(strcmp({dataStruct.paramList.name}, 'TEMP_DOXY') == 1);
               
               if (~isempty(idPres) && ...
                     ~isempty(idTPhaseDoxy) && ~isempty(idTempDoxy))
                  
                  % compute DOXY
                  dataCtd = repmat(ctdData, size(dataStruct.data, 1), 1);
                  doxy = compute_DOXY_1009_1107_1112_1113_1201( ...
                     dataStruct.data(:, idTPhaseDoxy), ...
                     dataStruct.data(:, idTempDoxy), ...
                     paramTPhaseDoxy.fillValue, ...
                     paramTempDoxy.fillValue, ...
                     dataStruct.data(:, idPres), ...
                     dataCtd(:, 2), ...
                     dataCtd(:, 3), ...
                     paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
                     paramDoxy.fillValue);
                  
                  % add DOXY to the data structure
                  dataStruct.paramList = [dataStruct.paramList paramDoxy];
                  dataStruct.data = [dataStruct.data doxy];
                  
                  if (~isempty(dataStruct.dataAdj) && ~isempty(ctdDataAdj))
                     % compute DOXY
                     dataAdjCtd = repmat(ctdDataAdj, size(dataStruct.dataAdj, 1), 1);
                     doxy = compute_DOXY_1009_1107_1112_1113_1201( ...
                        dataStruct.dataAdj(:, idTPhaseDoxy), ...
                        dataStruct.dataAdj(:, idTempDoxy), ...
                        paramTPhaseDoxy.fillValue, ...
                        paramTempDoxy.fillValue, ...
                        dataStruct.dataAdj(:, idPres), ...
                        dataAdjCtd(:, 2), ...
                        dataAdjCtd(:, 3), ...
                        paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
                        paramDoxy.fillValue);
                     
                     % add DOXY to the data structure
                     dataStruct.dataAdj = [dataStruct.dataAdj doxy];
                  end
               end
               
               o_outputData{idS} = dataStruct;
            end
         else
            dataStruct = o_outputData;
            idPres = find(strcmp({dataStruct.paramList.name}, 'PRES') == 1);
            idTPhaseDoxy = find(strcmp({dataStruct.paramList.name}, 'TPHASE_DOXY') == 1);
            idTempDoxy = find(strcmp({dataStruct.paramList.name}, 'TEMP_DOXY') == 1);
            
            if (~isempty(idPres) && ...
                  ~isempty(idTPhaseDoxy) && ~isempty(idTempDoxy))
               
               % compute DOXY
               dataCtd = repmat(ctdData, size(dataStruct.data, 1), 1);
               doxy = compute_DOXY_1009_1107_1112_1113_1201( ...
                  dataStruct.data(:, idTPhaseDoxy), ...
                  dataStruct.data(:, idTempDoxy), ...
                  paramTPhaseDoxy.fillValue, ...
                  paramTempDoxy.fillValue, ...
                  dataStruct.data(:, idPres), ...
                  dataCtd(:, 2), ...
                  dataCtd(:, 3), ...
                  paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
                  paramDoxy.fillValue);
               
               % add DOXY to the data structure
               dataStruct.paramList = [dataStruct.paramList paramDoxy];
               dataStruct.data = [dataStruct.data doxy];
               
               if (~isempty(dataStruct.dataAdj) && ~isempty(ctdDataAdj))
                  % compute DOXY
                  dataAdjCtd = repmat(ctdDataAdj, size(dataStruct.dataAdj, 1), 1);
                  doxy = compute_DOXY_1009_1107_1112_1113_1201( ...
                     dataStruct.dataAdj(:, idTPhaseDoxy), ...
                     dataStruct.dataAdj(:, idTempDoxy), ...
                     paramTPhaseDoxy.fillValue, ...
                     paramTempDoxy.fillValue, ...
                     dataStruct.dataAdj(:, idPres), ...
                     dataAdjCtd(:, 2), ...
                     dataAdjCtd(:, 3), ...
                     paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
                     paramDoxy.fillValue);
                  
                  % add DOXY to the data structure
                  dataStruct.dataAdj = [dataStruct.dataAdj doxy];
               end
            end
            
            o_outputData = dataStruct;
         end
      end
      
   otherwise
      fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in compute_doxy for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_decoderId);
end

return;

% ------------------------------------------------------------------------------
% Compute DOXY2 for Navis floats.
%
% SYNTAX :
%  [o_outputData] = compute_doxy2(a_inputData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_inputData : input data
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_outputData : output data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_outputData] = compute_doxy2(a_inputData, a_decoderId)

% output parameters initialization
o_outputData = a_inputData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (isempty(o_outputData))
   return;
end

switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {1201}
      
      paramPres = get_netcdf_param_attributes('PRES');
      paramTemp = get_netcdf_param_attributes('TEMP');
      paramSal = get_netcdf_param_attributes('PSAL');
      paramPhaseDelayDoxy = get_netcdf_param_attributes('PHASE_DELAY_DOXY2');
      paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
      paramDoxy = get_netcdf_param_attributes('DOXY2');
      
      if (iscell(o_outputData))
         for idS = 1:length(o_outputData)
            dataStruct = o_outputData{idS};
            idPres = find(strcmp({dataStruct.paramList.name}, 'PRES') == 1);
            idTemp = find(strcmp({dataStruct.paramList.name}, 'TEMP') == 1);
            idPsal = find(strcmp({dataStruct.paramList.name}, 'PSAL') == 1);
            idPhaseDelayDoxy = find(strcmp({dataStruct.paramList.name}, 'PHASE_DELAY_DOXY2') == 1);
            idTempDoxy = find(strcmp({dataStruct.paramList.name}, 'TEMP_DOXY2') == 1);
            
            if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal) && ...
                  ~isempty(idPhaseDelayDoxy) && ~isempty(idTempDoxy))
               
               % compute DOXY
               doxy = compute_DOXY_SBE_1201( ...
                  dataStruct.data(:, idPhaseDelayDoxy), ...
                  dataStruct.data(:, idTempDoxy), ...
                  paramPhaseDelayDoxy.fillValue, ...
                  paramTempDoxy.fillValue, ...
                  dataStruct.data(:, idPres), ...
                  dataStruct.data(:, idTemp), ...
                  dataStruct.data(:, idPsal), ...
                  paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
                  paramDoxy.fillValue);
               
               % add DOXY to the data structure
               dataStruct.paramList = [dataStruct.paramList paramDoxy];
               dataStruct.data = [dataStruct.data doxy];
               
               if (~isempty(dataStruct.dataAdj))
                  % compute DOXY
                  doxy = compute_DOXY_SBE_1201( ...
                     dataStruct.dataAdj(:, idPhaseDelayDoxy), ...
                     dataStruct.dataAdj(:, idTempDoxy), ...
                     paramPhaseDelayDoxy.fillValue, ...
                     paramTempDoxy.fillValue, ...
                     dataStruct.dataAdj(:, idPres), ...
                     dataStruct.dataAdj(:, idTemp), ...
                     dataStruct.dataAdj(:, idPsal), ...
                     paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
                     paramDoxy.fillValue);
                  
                  % add DOXY to the data structure
                  dataStruct.dataAdj = [dataStruct.dataAdj doxy];
               end
            end
            
            o_outputData{idS} = dataStruct;
         end
      else
         dataStruct = o_outputData;
         idPres = find(strcmp({dataStruct.paramList.name}, 'PRES') == 1);
         idTemp = find(strcmp({dataStruct.paramList.name}, 'TEMP') == 1);
         idPsal = find(strcmp({dataStruct.paramList.name}, 'PSAL') == 1);
         idPhaseDelayDoxy = find(strcmp({dataStruct.paramList.name}, 'PHASE_DELAY_DOXY2') == 1);
         idTempDoxy = find(strcmp({dataStruct.paramList.name}, 'TEMP_DOXY2') == 1);
         
         if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal) && ...
               ~isempty(idPhaseDelayDoxy) && ~isempty(idTempDoxy))
            
            % compute DOXY
            doxy = compute_DOXY_SBE_1201( ...
               dataStruct.data(:, idPhaseDelayDoxy), ...
               dataStruct.data(:, idTempDoxy), ...
               paramPhaseDelayDoxy.fillValue, ...
               paramTempDoxy.fillValue, ...
               dataStruct.data(:, idPres), ...
               dataStruct.data(:, idTemp), ...
               dataStruct.data(:, idPsal), ...
               paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
               paramDoxy.fillValue);
            
            % add DOXY to the data structure
            dataStruct.paramList = [dataStruct.paramList paramDoxy];
            dataStruct.data = [dataStruct.data doxy];
            
            if (~isempty(dataStruct.dataAdj))
               % compute DOXY
               doxy = compute_DOXY_SBE_1201( ...
                  dataStruct.dataAdj(:, idPhaseDelayDoxy), ...
                  dataStruct.dataAdj(:, idTempDoxy), ...
                  paramPhaseDelayDoxy.fillValue, ...
                  paramTempDoxy.fillValue, ...
                  dataStruct.dataAdj(:, idPres), ...
                  dataStruct.dataAdj(:, idTemp), ...
                  dataStruct.dataAdj(:, idPsal), ...
                  paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue, ...
                  paramDoxy.fillValue);
               
               % add DOXY to the data structure
               dataStruct.dataAdj = [dataStruct.dataAdj doxy];
            end
         end
         
         o_outputData = dataStruct;
      end
      
   otherwise
      fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in compute_doxy for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_decoderId);
end

return;

% ------------------------------------------------------------------------------
% Compute PPOX_DOXY for Apex Iridium Rudics & Navis floats.
%
% SYNTAX :
%  [o_outputData] = compute_ppox_doxy(a_inputData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_inputData : input data
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_outputData : output data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_outputData] = compute_ppox_doxy(a_inputData, a_decoderId)

% output parameters initialization
o_outputData = a_inputData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (isempty(o_outputData))
   return;
end

switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {1105, 1110, 1111}
      
      paramPres = get_netcdf_param_attributes('PRES');
      paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
      paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
      paramPpoxDoxy = get_netcdf_param_attributes('PPOX_DOXY');
      
      if (iscell(o_outputData))
         for idS = 1:length(o_outputData)
            dataStruct = o_outputData{idS};
            idPres = find(strcmp({dataStruct.paramList.name}, 'PRES') == 1);
            idTPhaseDoxy = find(strcmp({dataStruct.paramList.name}, 'TPHASE_DOXY') == 1);
            idTempDoxy = find(strcmp({dataStruct.paramList.name}, 'TEMP_DOXY') == 1);
            
            if (~isempty(idPres) && ...
                  ~isempty(idTPhaseDoxy) && ~isempty(idTempDoxy))
               
               % compute PPOX_DOXY
               ppoxDoxy = compute_PPOX_DOXY_1105_1110_1111( ...
                  dataStruct.data(:, idTPhaseDoxy), ...
                  dataStruct.data(:, idTempDoxy), ...
                  paramTPhaseDoxy.fillValue, ...
                  paramTempDoxy.fillValue, ...
                  dataStruct.data(:, idPres), ...
                  paramPres.fillValue, ...
                  paramPpoxDoxy.fillValue);
               
               % add DOXY to the data structure
               dataStruct.paramList = [dataStruct.paramList paramPpoxDoxy];
               dataStruct.data = [dataStruct.data ppoxDoxy];
               
               if (~isempty(dataStruct.dataAdj))
                  % compute PPOX_DOXY
                  ppoxDoxy = compute_PPOX_DOXY_1105_1110_1111( ...
                     dataStruct.dataAdj(:, idTPhaseDoxy), ...
                     dataStruct.dataAdj(:, idTempDoxy), ...
                     paramTPhaseDoxy.fillValue, ...
                     paramTempDoxy.fillValue, ...
                     dataStruct.dataAdj(:, idPres), ...
                     paramPres.fillValue, ...
                     paramPpoxDoxy.fillValue);
                  
                  % add DOXY to the data structure
                  dataStruct.dataAdj = [dataStruct.dataAdj ppoxDoxy];
               end
            end
            
            o_outputData{idS} = dataStruct;
         end
      else
         dataStruct = o_outputData;
         idPres = find(strcmp({dataStruct.paramList.name}, 'PRES') == 1);
         idTPhaseDoxy = find(strcmp({dataStruct.paramList.name}, 'TPHASE_DOXY') == 1);
         idTempDoxy = find(strcmp({dataStruct.paramList.name}, 'TEMP_DOXY') == 1);
         
         if (~isempty(idPres) && ...
               ~isempty(idTPhaseDoxy) && ~isempty(idTempDoxy))
            
            % compute PPOX_DOXY
            ppoxDoxy = compute_PPOX_DOXY_1105_1110_1111( ...
               dataStruct.data(:, idTPhaseDoxy), ...
               dataStruct.data(:, idTempDoxy), ...
               paramTPhaseDoxy.fillValue, ...
               paramTempDoxy.fillValue, ...
               dataStruct.data(:, idPres), ...
               paramPres.fillValue, ...
               paramPpoxDoxy.fillValue);
            
            % add DOXY to the data structure
            dataStruct.paramList = [dataStruct.paramList paramPpoxDoxy];
            dataStruct.data = [dataStruct.data ppoxDoxy];
            
            if (~isempty(dataStruct.dataAdj))
               % compute PPOX_DOXY
               ppoxDoxy = compute_PPOX_DOXY_1105_1110_1111( ...
                  dataStruct.dataAdj(:, idTPhaseDoxy), ...
                  dataStruct.dataAdj(:, idTempDoxy), ...
                  paramTPhaseDoxy.fillValue, ...
                  paramTempDoxy.fillValue, ...
                  dataStruct.dataAdj(:, idPres), ...
                  paramPres.fillValue, ...
                  paramPpoxDoxy.fillValue);
               
               % add DOXY to the data structure
               dataStruct.dataAdj = [dataStruct.dataAdj ppoxDoxy];
            end
         end
         
         o_outputData = dataStruct;
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {1112, 1201}
      
      paramPres = get_netcdf_param_attributes('PRES');
      paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
      paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
      paramPpoxDoxy = get_netcdf_param_attributes('PPOX_DOXY');
      
      if (iscell(o_outputData))
         for idS = 1:length(o_outputData)
            dataStruct = o_outputData{idS};
            idPres = find(strcmp({dataStruct.paramList.name}, 'PRES') == 1);
            idTPhaseDoxy = find(strcmp({dataStruct.paramList.name}, 'TPHASE_DOXY') == 1);
            idTempDoxy = find(strcmp({dataStruct.paramList.name}, 'TEMP_DOXY') == 1);
            
            if (~isempty(idPres) && ...
                  ~isempty(idTPhaseDoxy) && ~isempty(idTempDoxy))
               
               % compute PPOX_DOXY
               ppoxDoxy = compute_PPOX_DOXY_1009_1112_1201( ...
                  dataStruct.data(:, idTPhaseDoxy), ...
                  dataStruct.data(:, idTempDoxy), ...
                  paramTPhaseDoxy.fillValue, ...
                  paramTempDoxy.fillValue, ...
                  dataStruct.data(:, idPres), ...
                  paramPres.fillValue, ...
                  paramPpoxDoxy.fillValue);
               
               % add DOXY to the data structure
               dataStruct.paramList = [dataStruct.paramList paramPpoxDoxy];
               dataStruct.data = [dataStruct.data ppoxDoxy];
               
               if (~isempty(dataStruct.dataAdj))
                  % compute PPOX_DOXY
                  ppoxDoxy = compute_PPOX_DOXY_1009_1112_1201( ...
                     dataStruct.dataAdj(:, idTPhaseDoxy), ...
                     dataStruct.dataAdj(:, idTempDoxy), ...
                     paramTPhaseDoxy.fillValue, ...
                     paramTempDoxy.fillValue, ...
                     dataStruct.dataAdj(:, idPres), ...
                     paramPres.fillValue, ...
                     paramPpoxDoxy.fillValue);
                  
                  % add DOXY to the data structure
                  dataStruct.dataAdj = [dataStruct.dataAdj ppoxDoxy];
               end
            end
            
            o_outputData{idS} = dataStruct;
         end
      else
         dataStruct = o_outputData;
         idPres = find(strcmp({dataStruct.paramList.name}, 'PRES') == 1);
         idTPhaseDoxy = find(strcmp({dataStruct.paramList.name}, 'TPHASE_DOXY') == 1);
         idTempDoxy = find(strcmp({dataStruct.paramList.name}, 'TEMP_DOXY') == 1);
         
         if (~isempty(idPres) && ...
               ~isempty(idTPhaseDoxy) && ~isempty(idTempDoxy))
            
            % compute PPOX_DOXY
            ppoxDoxy = compute_PPOX_DOXY_1009_1112_1201( ...
               dataStruct.data(:, idTPhaseDoxy), ...
               dataStruct.data(:, idTempDoxy), ...
               paramTPhaseDoxy.fillValue, ...
               paramTempDoxy.fillValue, ...
               dataStruct.data(:, idPres), ...
               paramPres.fillValue, ...
               paramPpoxDoxy.fillValue);
            
            % add DOXY to the data structure
            dataStruct.paramList = [dataStruct.paramList paramPpoxDoxy];
            dataStruct.data = [dataStruct.data ppoxDoxy];
            
            if (~isempty(dataStruct.dataAdj))
               % compute PPOX_DOXY
               ppoxDoxy = compute_PPOX_DOXY_1009_1112_1201( ...
                  dataStruct.dataAdj(:, idTPhaseDoxy), ...
                  dataStruct.dataAdj(:, idTempDoxy), ...
                  paramTPhaseDoxy.fillValue, ...
                  paramTempDoxy.fillValue, ...
                  dataStruct.dataAdj(:, idPres), ...
                  paramPres.fillValue, ...
                  paramPpoxDoxy.fillValue);
               
               % add DOXY to the data structure
               dataStruct.dataAdj = [dataStruct.dataAdj ppoxDoxy];
            end
         end
         
         o_outputData = dataStruct;
      end
      
   otherwise
      fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in compute_ppox_doxy for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_decoderId);
end

return;

% ------------------------------------------------------------------------------
% Compute CHLA for Apex Iridium Rudics floats.
%
% SYNTAX :
%  [o_outputData] = compute_chla(a_inputData)
%
% INPUT PARAMETERS :
%   a_inputData : input data
%
% OUTPUT PARAMETERS :
%   o_outputData : output data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_outputData] = compute_chla(a_inputData)

% output parameters initialization
o_outputData = a_inputData;


if (isempty(o_outputData))
   return;
end

paramFluorescenceChla = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
paramChla = get_netcdf_param_attributes('CHLA');

if (iscell(o_outputData))
   for idS = 1:length(o_outputData)
      dataStruct = o_outputData{idS};
      idFluorescenceChla = find(strcmp({dataStruct.paramList.name}, 'FLUORESCENCE_CHLA') == 1);
      
      if (~isempty(idFluorescenceChla))
         % compute CHLA
         chla = compute_CHLA_301_1015_1101_1105_1110_1111_1112( ...
            dataStruct.data(:, idFluorescenceChla), ...
            paramFluorescenceChla.fillValue, paramChla.fillValue);
         
         % add CHLA to the data structure
         dataStruct.paramList = [dataStruct.paramList paramChla];
         dataStruct.data = [dataStruct.data chla];
         
         if (~isempty(dataStruct.dataAdj))
            % compute CHLA
            chla = compute_CHLA_301_1015_1101_1105_1110_1111_1112( ...
               dataStruct.dataAdj(:, idFluorescenceChla), ...
               paramFluorescenceChla.fillValue, paramChla.fillValue);
            
            % add CHLA to the data structure
            dataStruct.dataAdj = [dataStruct.dataAdj chla];
         end
      end
      
      o_outputData{idS} = dataStruct;
   end
else
   dataStruct = o_outputData;
   idFluorescenceChla = find(strcmp({dataStruct.paramList.name}, 'FLUORESCENCE_CHLA') == 1);
   
   if (~isempty(idFluorescenceChla))
      % compute CHLA
      chla = compute_CHLA_301_1015_1101_1105_1110_1111_1112( ...
         dataStruct.data(:, idFluorescenceChla), ...
         paramFluorescenceChla.fillValue, paramChla.fillValue);
      
      % add CHLA to the data structure
      dataStruct.paramList = [dataStruct.paramList paramChla];
      dataStruct.data = [dataStruct.data chla];
      
      if (~isempty(dataStruct.dataAdj))
         % compute CHLA
         chla = compute_CHLA_301_1015_1101_1105_1110_1111_1112( ...
            dataStruct.dataAdj(:, idFluorescenceChla), ...
            paramFluorescenceChla.fillValue, paramChla.fillValue);
         
         % add CHLA to the data structure
         dataStruct.dataAdj = [dataStruct.dataAdj chla];
      end
   end
   
   o_outputData = dataStruct;
end

return;

% ------------------------------------------------------------------------------
% Compute BBP700 for Apex Iridium Rudics floats.
%
% SYNTAX :
%  [o_outputData] = compute_bbp700(a_inputData, a_lrCtdData, a_hrCtdData)
%
% INPUT PARAMETERS :
%   a_inputData : input data
%   a_lrCtdData : CTD data of LR profile
%   a_hrCtdData : CTD data of HR profile
%
% OUTPUT PARAMETERS :
%   o_outputData : output data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_outputData] = compute_bbp700(a_inputData, a_lrCtdData, a_hrCtdData)

% output parameters initialization
o_outputData = a_inputData;


if (isempty(o_outputData))
   return;
end

paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramSal = get_netcdf_param_attributes('PSAL');
paramBetaBackscattering700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');
paramBbp700 = get_netcdf_param_attributes('BBP700');

if (iscell(o_outputData))
   for idS = 1:length(o_outputData)
      dataStruct = o_outputData{idS};
      idPres = find(strcmp({dataStruct.paramList.name}, 'PRES') == 1);
      idTemp = find(strcmp({dataStruct.paramList.name}, 'TEMP') == 1);
      idPsal = find(strcmp({dataStruct.paramList.name}, 'PSAL') == 1);
      idBetaBackscattering70 = find(strcmp({dataStruct.paramList.name}, 'BETA_BACKSCATTERING700') == 1);
      
      if (~isempty(idBetaBackscattering70))
         ctdData = [];
         ctdDataAdj = [];
         if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal))
            ctdData = dataStruct.data(:, [idPres idTemp idPsal]);
            if (~isempty(dataStruct.dataAdj))
               ctdDataAdj = dataStruct.dataAdj(:, [idPres idTemp idPsal]);
            end
         else
            if (~isempty(a_lrCtdData) || ~isempty(a_hrCtdData))
               [ctdData, ctdDataAdj] = get_shallowest_ctd(a_lrCtdData, a_hrCtdData);
               if (~isempty(ctdData))
                  ctdData = repmat(ctdData, size(dataStruct.data, 1), 1);
                  if (~isempty(ctdData))
                     ctdDataAdj = repmat(ctdDataAdj, size(dataStruct.data, 1), 1);
                  end
               end
            end
         end
         
         if (~isempty(ctdData))
            % compute BBP700
            bbp700 = compute_BBP700_301_1015_1101_1105_1110_1111_1112( ...
               dataStruct.data(:, idBetaBackscattering70), ...
               paramBetaBackscattering700.fillValue, paramBbp700.fillValue, ...
               ctdData, ...
               paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue);
            
            % add BBP700 to the data structure
            dataStruct.paramList = [dataStruct.paramList paramBbp700];
            dataStruct.data = [dataStruct.data bbp700];
            
            if (~isempty(dataStruct.dataAdj))
               % compute BBP700
               bbp700 = compute_BBP700_301_1015_1101_1105_1110_1111_1112( ...
                  dataStruct.dataAdj(:, idBetaBackscattering70), ...
                  paramBetaBackscattering700.fillValue, paramBbp700.fillValue, ...
                  ctdDataAdj, ...
                  paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue);
               
               % add CHLA to the data structure
               dataStruct.dataAdj = [dataStruct.dataAdj bbp700];
            end
         end
      end
      
      o_outputData{idS} = dataStruct;
   end
else
   dataStruct = o_outputData;
   idPres = find(strcmp({dataStruct.paramList.name}, 'PRES') == 1);
   idTemp = find(strcmp({dataStruct.paramList.name}, 'TEMP') == 1);
   idPsal = find(strcmp({dataStruct.paramList.name}, 'PSAL') == 1);
   idBetaBackscattering70 = find(strcmp({dataStruct.paramList.name}, 'BETA_BACKSCATTERING700') == 1);
   
   if (~isempty(idBetaBackscattering70))
      ctdData = [];
      ctdDataAdj = [];
      if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal))
         ctdData = dataStruct.data(:, [idPres idTemp idPsal]);
         if (~isempty(dataStruct.dataAdj))
            ctdDataAdj = dataStruct.dataAdj(:, [idPres idTemp idPsal]);
         end
      else
         if (~isempty(a_lrCtdData) || ~isempty(a_hrCtdData))
            [ctdData, ctdDataAdj] = get_shallowest_ctd(a_lrCtdData, a_hrCtdData);
            if (~isempty(ctdData))
               ctdData = repmat(ctdData, size(dataStruct.data, 1), 1);
               if (~isempty(ctdData))
                  ctdDataAdj = repmat(ctdDataAdj, size(dataStruct.data, 1), 1);
               end
            end
         end
      end
      
      if (~isempty(ctdData))
         % compute BBP700
         bbp700 = compute_BBP700_301_1015_1101_1105_1110_1111_1112( ...
            dataStruct.data(:, idBetaBackscattering70), ...
            paramBetaBackscattering700.fillValue, paramBbp700.fillValue, ...
            ctdData, ...
            paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue);
         
         % add BBP700 to the data structure
         dataStruct.paramList = [dataStruct.paramList paramBbp700];
         dataStruct.data = [dataStruct.data bbp700];
         
         if (~isempty(dataStruct.dataAdj))
            % compute BBP700
            bbp700 = compute_BBP700_301_1015_1101_1105_1110_1111_1112( ...
               dataStruct.dataAdj(:, idBetaBackscattering70), ...
               paramBetaBackscattering700.fillValue, paramBbp700.fillValue, ...
               ctdDataAdj, ...
               paramPres.fillValue, paramTemp.fillValue, paramSal.fillValue);
            
            % add CHLA to the data structure
            dataStruct.dataAdj = [dataStruct.dataAdj bbp700];
         end
      end
   end
   
   o_outputData = dataStruct;
end

return;

% ------------------------------------------------------------------------------
% Retrieve shallowest CTD measurement of profile LR and HR data.
%
% SYNTAX :
%  [o_ctdData, o_ctdDataAdj] = get_shallowest_ctd(a_lrCtdData, a_hrCtdData)
%
% INPUT PARAMETERS :
%   a_lrCtdData : CTD data of LR profile
%   a_hrCtdData : CTD data of HR profile
%
% OUTPUT PARAMETERS :
%   o_ctdData    : shallowest CTD data
%   o_ctdDataAdj : shallowest CTD adjusted data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ctdData, o_ctdDataAdj] = get_shallowest_ctd(a_lrCtdData, a_hrCtdData)

% output parameters initialization
o_ctdData = [];
o_ctdDataAdj = [];


if (isempty(a_lrCtdData) && isempty(a_hrCtdData))
   return;
end

ctdStruct = [];
if (~isempty(a_lrCtdData))
   idPres = find(strcmp({a_lrCtdData.paramList.name}, 'PRES') == 1);
   idTemp = find(strcmp({a_lrCtdData.paramList.name}, 'TEMP') == 1);
   idPsal = find(strcmp({a_lrCtdData.paramList.name}, 'PSAL') == 1);
   if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal))
      ctdStruct = get_apx_profile_data_init_struct;
      ctdStruct.paramList = a_lrCtdData.paramList([idPres idTemp idPsal]);
      ctdStruct.data = a_lrCtdData.data(:, [idPres idTemp idPsal]);
      if (~isempty(a_lrCtdData.dataAdj))
         ctdStruct.dataAdj = a_lrCtdData.dataAdj(:, [idPres idTemp idPsal]);
      end
   end
end
if (~isempty(a_hrCtdData))
   idPres = find(strcmp({a_hrCtdData.paramList.name}, 'PRES') == 1);
   idTemp = find(strcmp({a_hrCtdData.paramList.name}, 'TEMP') == 1);
   idPsal = find(strcmp({a_hrCtdData.paramList.name}, 'PSAL') == 1);
   if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal))
      if (isempty(ctdStruct))
         ctdStruct = get_apx_profile_data_init_struct;
         ctdStruct.paramList = a_hrCtdData.paramList([idPres idTemp idPsal]);
         ctdStruct.data = a_hrCtdData.data(:, [idPres idTemp idPsal]);
         if (~isempty(a_hrCtdData.dataAdj))
            ctdStruct.dataAdj = a_hrCtdData.dataAdj(:, [idPres idTemp idPsal]);
         end
      else
         ctdStruct.data = [ctdStruct.data; a_hrCtdData.data(:, [idPres idTemp idPsal])];
         if (~isempty(a_hrCtdData.dataAdj))
            ctdStruct.dataAdj = [ctdStruct.data; a_hrCtdData.dataAdj(:, [idPres idTemp idPsal])];
         end
      end
   end
end
ctdStruct = squeeze_profile_data(ctdStruct);

if (~isempty(ctdStruct))
   [~, idMin] = min(ctdStruct.data(:, 1));
   o_ctdData = ctdStruct.data(idMin, :);
   if (~isempty(ctdStruct.dataAdj))
      o_ctdDataAdj = ctdStruct.dataAdj(idMin, :);
   end
end

return;

% ------------------------------------------------------------------------------
% Retrieve PTS measurements of a profile.
%
% SYNTAX :
%  [o_ctdData] = get_ctd(a_profData)
%
% INPUT PARAMETERS :
%   a_profData : profile data
%
% OUTPUT PARAMETERS :
%   o_ctdData : PTS measurements of the profile
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ctdData] = get_ctd(a_profData)

% output parameters initialization
o_ctdData = [];


if (isempty(a_profData))
   return;
end

if (iscell(a_profData))
   for idS = 1:length(a_profData)
      dataStruct = a_profData{idS};
      idPres = find(strcmp({dataStruct.paramList.name}, 'PRES') == 1);
      idTemp = find(strcmp({dataStruct.paramList.name}, 'TEMP') == 1);
      idPsal = find(strcmp({dataStruct.paramList.name}, 'PSAL') == 1);
      
      if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal))
         ctdStruct = get_apx_profile_data_init_struct;
         ctdStruct.paramList = dataStruct.paramList([idPres idTemp idPsal]);
         ctdStruct.data = dataStruct.data([idPres idTemp idPsal]);
         if (~isempty(dataStruct.dataAdj))
            ctdStruct.dataAdj = dataStruct.dataAdj([idPres idTemp idPsal]);
         end
         o_ctdData{idS} = ctdStruct;
      end
   end
else
   dataStruct = a_profData;
   idPres = find(strcmp({dataStruct.paramList.name}, 'PRES') == 1);
   idTemp = find(strcmp({dataStruct.paramList.name}, 'TEMP') == 1);
   idPsal = find(strcmp({dataStruct.paramList.name}, 'PSAL') == 1);
   
   if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal))
      ctdStruct = get_apx_profile_data_init_struct;
      ctdStruct.paramList = dataStruct.paramList([idPres idTemp idPsal]);
      ctdStruct.data = dataStruct.data(:, [idPres idTemp idPsal]);
      if (~isempty(dataStruct.dataAdj))
         ctdStruct.dataAdj = dataStruct.dataAdj(:, [idPres idTemp idPsal]);
      end
      o_ctdData = ctdStruct;
   end
end

return;
