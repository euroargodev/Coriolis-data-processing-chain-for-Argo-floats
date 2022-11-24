% ------------------------------------------------------------------------------
% Create profile of SUNA APF frame sensor data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_SUNA_APF_110_113( ...
%    a_dataSUNAAPF, a_dataSUNAAPF2, ...
%    a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechSUNA)
%
% INPUT PARAMETERS :
%   a_dataSUNAAPF            : SUNA (APF frame) data (part 1)
%   a_dataSUNAAPF2           : SUNA (APF frame) data (part 2)
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_gpsData                : information on GPS locations
%   a_sensorTechSUNA         : SUNA technical data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : created output profiles
%   o_tabDrift    : created output drift measurement profiles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/22/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift] = process_profile_ir_rudics_SUNA_APF_110_113( ...
   a_dataSUNAAPF, a_dataSUNAAPF2, ...
   a_descentToParkStartDate, a_ascentEndDate, a_gpsData, a_sensorTechSUNA)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% global default values
global g_decArgo_dateDef;

% cycle phases
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseAscProf;

FITLM_MATLAB_FUNCTION_NOT_AVAILABLE = 0;


% unpack the input data
a_dataSUNAAPFDate = a_dataSUNAAPF{1};
a_dataSUNAAPFDateTrans = a_dataSUNAAPF{2};
a_dataSUNAAPFCTDPres = a_dataSUNAAPF{3};
a_dataSUNAAPFCTDTemp = a_dataSUNAAPF{4};
a_dataSUNAAPFCTDSal = a_dataSUNAAPF{5};
a_dataSUNAAPFIntTemp = a_dataSUNAAPF{6};
a_dataSUNAAPFSpecTemp = a_dataSUNAAPF{7};
a_dataSUNAAPFIntRelHumidity = a_dataSUNAAPF{8};
a_dataSUNAAPFDarkSpecMean = a_dataSUNAAPF{9};
a_dataSUNAAPFDarkSpecStd = a_dataSUNAAPF{10};
a_dataSUNAAPFSensorNitra = a_dataSUNAAPF{11};
a_dataSUNAAPFAbsFitRes = a_dataSUNAAPF{12};
a_dataSUNAAPFOutSpec = a_dataSUNAAPF{13};

a_dataSUNAAPF2Date = a_dataSUNAAPF2{1};
a_dataSUNAAPF2DateTrans = a_dataSUNAAPF2{2};
a_dataSUNAAPF2CTDPres = a_dataSUNAAPF2{3};
a_dataSUNAAPF2CTDTemp = a_dataSUNAAPF2{4};
a_dataSUNAAPF2CTDSal = a_dataSUNAAPF2{5};
a_dataSUNAAPF2IntTemp = a_dataSUNAAPF2{6};
a_dataSUNAAPF2SpecTemp = a_dataSUNAAPF2{7};
a_dataSUNAAPF2IntRelHumidity = a_dataSUNAAPF2{8};
a_dataSUNAAPF2DarkSpecMean = a_dataSUNAAPF2{9};
a_dataSUNAAPF2DarkSpecStd = a_dataSUNAAPF2{10};
a_dataSUNAAPF2SensorNitra = a_dataSUNAAPF2{11};
a_dataSUNAAPF2AbsFitRes = a_dataSUNAAPF2{12};
a_dataSUNAAPF2OutSpec = a_dataSUNAAPF2{13};

% process the profiles
cycleProfPhaseList = unique(a_dataSUNAAPFDate(:, 1:3), 'rows');
for idCyPrPh = 1:size(cycleProfPhaseList, 1)
   cycleNum = cycleProfPhaseList(idCyPrPh, 1);
   profNum = cycleProfPhaseList(idCyPrPh, 2);
   phaseNum = cycleProfPhaseList(idCyPrPh, 3);
   
   if ((phaseNum == g_decArgo_phaseDsc2Prk) || ...
         (phaseNum == g_decArgo_phaseParkDrift) || ...
         (phaseNum == g_decArgo_phaseAscProf))
      
      profStruct = get_profile_init_struct(cycleNum, profNum, phaseNum, 0);
      profStruct.sensorNumber = 6;
      
      % select the data (according to cycleNum, profNum and phaseNum)
      idDataAPF = find((a_dataSUNAAPFDate(:, 1) == cycleNum) & ...
         (a_dataSUNAAPFDate(:, 2) == profNum) & ...
         (a_dataSUNAAPFDate(:, 3) == phaseNum));
      idDataAPF2 = find((a_dataSUNAAPF2Date(:, 1) == cycleNum) & ...
         (a_dataSUNAAPF2Date(:, 2) == profNum) & ...
         (a_dataSUNAAPF2Date(:, 3) == phaseNum));
      
      if (~isempty(idDataAPF) && ~isempty(idDataAPF2))
         
         dataAPF = [];
         for idL = 1:length(idDataAPF)
            
            % find the corresonding line in SUNA APF2
            idF = find( ...
               (a_dataSUNAAPFDate(idDataAPF(idL), 4) == a_dataSUNAAPF2Date(idDataAPF2, 4)) & ...
               (a_dataSUNAAPFCTDPres(idDataAPF(idL), 4) == a_dataSUNAAPF2CTDPres(idDataAPF2, 4)) & ...
               (a_dataSUNAAPFCTDTemp(idDataAPF(idL), 4) == a_dataSUNAAPF2CTDTemp(idDataAPF2, 4)) & ...
               (a_dataSUNAAPFCTDSal(idDataAPF(idL), 4) == a_dataSUNAAPF2CTDSal(idDataAPF2, 4)) & ...
               (a_dataSUNAAPFIntTemp(idDataAPF(idL), 4) == a_dataSUNAAPF2IntTemp(idDataAPF2, 4)) & ...
               (a_dataSUNAAPFSpecTemp(idDataAPF(idL), 4) == a_dataSUNAAPF2SpecTemp(idDataAPF2, 4)) & ...
               (a_dataSUNAAPFIntRelHumidity(idDataAPF(idL), 4) == a_dataSUNAAPF2IntRelHumidity(idDataAPF2, 4)) & ...
               (a_dataSUNAAPFDarkSpecMean(idDataAPF(idL), 4) == a_dataSUNAAPF2DarkSpecMean(idDataAPF2, 4)) & ...
               (a_dataSUNAAPFDarkSpecStd(idDataAPF(idL), 4) == a_dataSUNAAPF2DarkSpecStd(idDataAPF2, 4)) & ...
               (a_dataSUNAAPFSensorNitra(idDataAPF(idL), 4) == a_dataSUNAAPF2SensorNitra(idDataAPF2, 4)) & ...
               (a_dataSUNAAPFAbsFitRes(idDataAPF(idL), 4) == a_dataSUNAAPF2AbsFitRes(idDataAPF2, 4)));
            if (isempty(idF))
               fprintf('ERROR: Float #%d Cycle #%d: Cannot find SUNA APF2 data associated to SUNA APF2 data - data not considered\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum);
               continue
            elseif (length(idF) > 1)
               fprintf('ERROR: Float #%d Cycle #%d: More than one SUNA APF2 data associated to SUNA APF2 data - the first one is used\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum);
               idF = idF(1);
            end
            
            if (FITLM_MATLAB_FUNCTION_NOT_AVAILABLE)
               dataAPF = cat(1, dataAPF, ...
                  [a_dataSUNAAPFDate(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFCTDPres(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFCTDTemp(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFCTDSal(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFIntTemp(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFSpecTemp(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFIntRelHumidity(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFDarkSpecMean(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFDarkSpecStd(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFSensorNitra(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFAbsFitRes(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFOutSpec(idDataAPF(idL), 4:end) ...
                  a_dataSUNAAPF2OutSpec(idDataAPF2(idF), 4:end)]);
            else
               dataAPF = cat(1, dataAPF, ...
                  [a_dataSUNAAPFDate(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFCTDPres(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFCTDTemp(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFCTDSal(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFIntTemp(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFSpecTemp(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFIntRelHumidity(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFDarkSpecMean(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFDarkSpecStd(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFAbsFitRes(idDataAPF(idL), 4)' ...
                  a_dataSUNAAPFOutSpec(idDataAPF(idL), 4:end) ...
                  a_dataSUNAAPF2OutSpec(idDataAPF2(idF), 4:end)]);
            end
         end
         
         if (~isempty(dataAPF))
            
            % compute the number of useful output spectrum channels
            nbOutSpec = 90;
            stop = 0;
            while ~((nbOutSpec == 0) || (stop == 1))
               dataCol = dataAPF(:, end);
               dataColU = unique(dataCol);
               if ((length(dataColU) == 1) && (dataColU == 0))
                  dataAPF(:, end) = [];
                  nbOutSpec = nbOutSpec - 1;
               else
                  stop = 1;
               end
            end
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramSUNAAPFCTDPres = get_netcdf_param_attributes('PRES');
            paramSUNAAPFCTDTemp = get_netcdf_param_attributes('TEMP');
            paramSUNAAPFCTDSal = get_netcdf_param_attributes('PSAL');
            paramSUNAAPFIntTemp = get_netcdf_param_attributes('TEMP_NITRATE');
            paramSUNAAPFSpecTemp = get_netcdf_param_attributes('TEMP_SPECTROPHOTOMETER_NITRATE');
            paramSUNAAPFIntRelHumidity = get_netcdf_param_attributes('HUMIDITY_NITRATE');
            paramSUNAAPFDarkSpecMean = get_netcdf_param_attributes('UV_INTENSITY_DARK_NITRATE');
            paramSUNAAPFDarkSpecStd = get_netcdf_param_attributes('UV_INTENSITY_DARK_NITRATE_STD');
            if (FITLM_MATLAB_FUNCTION_NOT_AVAILABLE)
               paramSUNAAPFSensorNitra = get_netcdf_param_attributes('MOLAR_NITRATE');
            end
            paramSUNAAPFAbsFitRes = get_netcdf_param_attributes('FIT_ERROR_NITRATE');
            paramSUNAAPFOutSpec = get_netcdf_param_attributes('UV_INTENSITY_NITRATE');
            
            % convert decoder default values to netCDF fill values
            dataAPF(find(dataAPF(:, 1) == g_decArgo_dateDef), 1) = paramJuld.fillValue;
            
            if (FITLM_MATLAB_FUNCTION_NOT_AVAILABLE)
               profStruct.paramList = [ ...
                  paramSUNAAPFCTDPres paramSUNAAPFCTDTemp paramSUNAAPFCTDSal ...
                  paramSUNAAPFIntTemp paramSUNAAPFSpecTemp paramSUNAAPFIntRelHumidity ...
                  paramSUNAAPFDarkSpecMean paramSUNAAPFDarkSpecStd paramSUNAAPFSensorNitra ...
                  paramSUNAAPFAbsFitRes paramSUNAAPFOutSpec];
            else
               profStruct.paramList = [ ...
                  paramSUNAAPFCTDPres paramSUNAAPFCTDTemp paramSUNAAPFCTDSal ...
                  paramSUNAAPFIntTemp paramSUNAAPFSpecTemp paramSUNAAPFIntRelHumidity ...
                  paramSUNAAPFDarkSpecMean paramSUNAAPFDarkSpecStd ...
                  paramSUNAAPFAbsFitRes paramSUNAAPFOutSpec];
            end
            profStruct.dateList = paramJuld;
            
            if (FITLM_MATLAB_FUNCTION_NOT_AVAILABLE)
               profStruct.paramNumberWithSubLevels = 11;
            else
               profStruct.paramNumberWithSubLevels = 10;
            end
            profStruct.paramNumberOfSubLevels = nbOutSpec;
            
            profStruct.data = dataAPF(:, [2:end]);
            profStruct.dates = dataAPF(:, 1);
            
            % measurement dates
            dates = dataAPF(:, 1);
            dates(find(dates == paramJuld.fillValue)) = [];
            profStruct.minMeasDate = min(dates);
            profStruct.maxMeasDate = max(dates);
         end
      end
      
      if (~isempty(profStruct.paramList))
         
         % add number of measurements in each zone
         [profStruct] = add_profile_nb_meas_ir_rudics_sbd2(profStruct, a_sensorTechSUNA);
         
         % add profile additional information
         if (phaseNum ~= g_decArgo_phaseParkDrift)
            
            % profile direction
            if (phaseNum == g_decArgo_phaseDsc2Prk)
               profStruct.direction = 'D';
            end
            
            % positioning system
            profStruct.posSystem = 'GPS';
            
            % profile date and location information
            [profStruct] = add_profile_date_and_location_ir_rudics_cts4( ...
               profStruct, ...
               a_descentToParkStartDate, a_ascentEndDate, ...
               a_gpsData);
            
            o_tabProfiles = [o_tabProfiles profStruct];
            
         else
            o_tabDrift = [o_tabDrift profStruct];
         end
      end
   end
end

return
