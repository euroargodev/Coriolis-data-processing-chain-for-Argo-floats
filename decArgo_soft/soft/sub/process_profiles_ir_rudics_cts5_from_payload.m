% ------------------------------------------------------------------------------
% Create the profiles of payload decoded data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift, o_tabSurf, ...
%    o_tabProfilesRaw, o_tabDriftRaw, o_tabSurfRaw] = ...
%    process_profiles_ir_rudics_cts5_from_payload( ...
%    a_payloadData, a_timeDataAll, a_gpsData, ...
%    a_presCutOffProf, a_tabProfileCtd, a_timeInformation)
%
% INPUT PARAMETERS :
%   a_payloadData     : payload data
%   a_timeDataAll     : decoded time data (of all previous cycles)
%   a_gpsData         : GPS data
%   a_presCutOffProf  : CTD profile cut-off pressure
%   a_tabProfileCtd   : CTD data
%   a_timeInformation : time information
%
% OUTPUT PARAMETERS :
%   o_tabProfiles    : created output profiles
%   o_tabDrift       : created output drift measurement profiles
%   o_tabSurf        : created output surface measurement profiles
%   o_tabProfilesRaw : created output profiles for 'raw' data
%   o_tabDriftRaw    : created output drift measurement profiles for 'raw' data
%   o_tabSurfRaw     : created output surface measurement profiles for 'raw' data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift, o_tabSurf, ...
   o_tabProfilesRaw, o_tabDriftRaw, o_tabSurfRaw] = ...
   process_profiles_ir_rudics_cts5_from_payload( ...
   a_payloadData, a_timeDataAll, a_gpsData, ...
   a_presCutOffProf, a_tabProfileCtd, a_timeInformation)

% output parameters initialization
o_tabProfiles = [];
o_tabProfilesRaw = [];
o_tabDrift = [];
o_tabDriftRaw = [];
o_tabSurf = [];
o_tabSurfRaw = [];

% default values
global g_decArgo_janFirst1950InMatlab;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloat;
global g_decArgo_patternNumFloat;

% cycle phases
global g_decArgo_phaseBuoyRed;
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseDsc2Prof;
global g_decArgo_phaseProfDrift;
global g_decArgo_phaseAscProf;
global g_decArgo_phaseSatTrans;

% treatment types
global g_decArgo_treatRaw;
global g_decArgo_treatAverage;
global g_decArgo_treatMedian;
global g_decArgo_treatMin;
global g_decArgo_treatMax;
global g_decArgo_treatStDev;

% sensor list
global g_decArgo_sensorList;

% due to payload issue, we should store all time information (to assign payload
% data to their correct cycle)
global g_decArgo_trajDataFromApmtTech;

FITLM_MATLAB_FUNCTION_NOT_AVAILABLE = 0;


if (isempty(a_payloadData))
   return
end

% if the float has a SUNA, we will also retrieve the floatPixelBegin and
% floatPixelEnd information if not available yet in the configuration
findPixelNumbers = 0;
if (ismember(6, g_decArgo_sensorList))
   findPixelNumbers = 1;
   floatPixelBegin = get_static_config_value('CONFIG_PX_1_6_0_0_3', 1);
   floatPixelEnd = get_static_config_value('CONFIG_PX_1_6_0_0_4', 1);
   if (~isempty(floatPixelBegin) && ~isempty(floatPixelEnd))
      if((floatPixelBegin ~= -1) && (floatPixelEnd ~= -1))
         findPixelNumbers = 0;
      end
   end
end

% extract useful information from payload data

% level #1 tags
idLev1Begin = find(([a_payloadData{:, 1}] == 1) & ...
   ([a_payloadData{:, 3}] == 'B'));

% SENSOR_XX tags
idLev1BeginSensor = [];
idF = find(strncmp(a_payloadData(idLev1Begin, 2), 'SENSOR_', length('SENSOR_')) & ...
   ~strcmp(a_payloadData(idLev1Begin, 2), 'SENSOR_ACT')); % to manage float anomaly (ex: 2ee3_020_01_payload.bin)
if (~isempty(idF))
   idLev1BeginSensor = idLev1Begin(idF);
end

payloadProfiles = [];
for idLev1B = 1:length(idLev1BeginSensor)
   payloadProfile = get_profile_payload_init_struct;
   idLev1Start = idLev1BeginSensor(idLev1B);
   idLev1End = find(strcmp(a_payloadData(:, 2), a_payloadData{idLev1Start, 2}) & ...
      ([a_payloadData{:, 3}] == 'E')');
   if (~isempty(idLev1End))
      idStop = find(idLev1End > idLev1Start);
      if (~isempty(idStop))
         idLev1Stop = idLev1End(idStop(1));
         
         % level #2 tags
         listLev1Id = idLev1Start+1:idLev1Stop-1;
         if (length(listLev1Id) > 2)
            idLev2Begin = find(([a_payloadData{listLev1Id, 1}] == 2) & ...
               ([a_payloadData{listLev1Id, 3}] == 'B'));
            idLev2Begin = listLev1Id(idLev2Begin);
            for idLev2B = 1:length(idLev2Begin)
               idLev2Start = idLev2Begin(idLev2B);
               idLev2End = find(strcmp(a_payloadData(:, 2), a_payloadData{idLev2Start, 2}) & ...
                  ([a_payloadData{:, 3}] == 'E')');
               if (~isempty(idLev2End))
                  idStop = find(idLev2End > idLev2Start);
                  if (~isempty(idStop))
                     idLev2Stop = idLev2End(idStop(1));
                     
                     % extract sensor information
                     sensorInfo = a_payloadData{idLev2Start, 2};
                     if (findPixelNumbers)
                        currentIsSuna = 0;
                        if (strncmp(sensorInfo, 'SUNA', length('SUNA')))
                           currentIsSuna = 1;
                        end
                     end
                     idF = strfind(sensorInfo, '-');
                     payloadProfile.phaseName = sensorInfo(idF(end)+1:end);
                     if (~strcmp(payloadProfile.phaseName, 'RAW'))
                        payloadProfile.subSampling = sensorInfo(idF(end-1)+1:idF(end)-1);
                        payloadProfile.sensorNum = str2num(sensorInfo(idF(end-2)+1:idF(end-1)-1));
                        payloadProfile.sensorName = sensorInfo(1:idF(end-2)-1);
                     else
                        payloadProfile.sensorNum = str2num(sensorInfo(idF(end-1)+1:idF(end)-1));
                        payloadProfile.sensorName = sensorInfo(1:idF(end-1)-1);
                     end
                     
                     % extract sensor attributes
                     sensorAtt = a_payloadData{idLev2Start, 4};
                     for idP = 1:length(sensorAtt)/2
                        payloadProfile.(sensorAtt{idP*2-1}) = sensorAtt{idP*2};
                     end
                     
                     % level #3 tags
                     listLev2Id = idLev2Start+1:idLev2Stop-1;
                     if (length(listLev2Id) > 2)
                        idLev3Begin = find(([a_payloadData{listLev2Id, 1}] == 3) & ...
                           ([a_payloadData{listLev2Id, 3}] == 'B'));
                        idLev3Begin = listLev2Id(idLev3Begin);
                        if (findPixelNumbers && currentIsSuna)
                           pixelTab = [];
                        end
                        for idLev3B = 1:length(idLev3Begin)
                           idLev3Start = idLev3Begin(idLev3B);
                           idLev3End = find(strcmp(a_payloadData(:, 2), a_payloadData{idLev3Start, 2}) & ...
                              ([a_payloadData{:, 3}] == 'E')');
                           if (~isempty(idLev3End))
                              idStop = find(idLev3End > idLev3Start);
                              if (~isempty(idStop))
                                 
                                 if (findPixelNumbers && currentIsSuna)
                                    if (strncmp(a_payloadData{idLev3Start, 5}, 'pixel[', length('pixel[')))
                                       pixelInfo = a_payloadData{idLev3Start, 5};
                                       idFBegin = strfind(pixelInfo, '[');
                                       idFEnd = strfind(pixelInfo, ']');
                                       pixelTab = [pixelTab str2num(pixelInfo(idFBegin+1:idFEnd-1))];
                                    end
                                 end
                                 
                                 % extract parameters and data
                                 dataLev2 = a_payloadData{idLev3Start, 2};
                                 if strcmp(dataLev2, 'CDATA')
                                    dataLev3 = a_payloadData{idLev3Start, 5};
                                    payloadProfile.paramName = dataLev3{1};
                                    payloadProfile.data = dataLev3{2}{:};
                                 end
                              else
                                 fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Inconsistent payload data\n', ...
                                    g_decArgo_floatNum, ...
                                    g_decArgo_cycleNum, ...
                                    g_decArgo_cycleNumFloat, ...
                                    g_decArgo_patternNumFloat);
                              end
                           else
                              fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Inconsistent payload data\n', ...
                                 g_decArgo_floatNum, ...
                                 g_decArgo_cycleNum, ...
                                 g_decArgo_cycleNumFloat, ...
                                 g_decArgo_patternNumFloat);
                           end
                        end
                        if (findPixelNumbers && currentIsSuna)
                           if (~isempty(pixelTab))
                              floatPixelBegin = min(pixelTab);
                              floatPixelEnd = max(pixelTab);
                              
                              set_static_config_value('CONFIG_PX_1_6_0_0_3', floatPixelBegin);
                              set_static_config_value('CONFIG_PX_1_6_0_0_4', floatPixelEnd);
                           end
                        end
                     end
                  else
                     fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Inconsistent payload data\n', ...
                        g_decArgo_floatNum, ...
                        g_decArgo_cycleNum, ...
                        g_decArgo_cycleNumFloat, ...
                        g_decArgo_patternNumFloat);
                  end
               else
                  fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Inconsistent payload data\n', ...
                     g_decArgo_floatNum, ...
                     g_decArgo_cycleNum, ...
                     g_decArgo_cycleNumFloat, ...
                     g_decArgo_patternNumFloat);
               end
            end
         end
      else
         fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Inconsistent payload data\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            g_decArgo_cycleNumFloat, ...
            g_decArgo_patternNumFloat);
      end
   end
   payloadProfiles = [payloadProfiles payloadProfile];
end

% remove profiles for unknown sensor
managedSensornameList = [ ...
   {'ECOPuck_LF'} ...
   {'OCR504ICSW'} ...
   {'SUNA'} ...
   {'Optode'} ...
   {'PHSEABIRD_UART6'} ...
   {'OCTOPUS'} ...
   ];
idToDel = [];
for idP = 1:length(payloadProfiles)
   if (~ismember(payloadProfiles(idP).sensorName, managedSensornameList))
      fprintf('INFO: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Data from sensor ''%s'' are not managed yet\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         g_decArgo_cycleNumFloat, ...
         g_decArgo_patternNumFloat, ...
         payloadProfiles(idP).sensorName);
      idToDel = [idToDel idP];
   end
end
payloadProfiles(idToDel) = [];

% finalize payload information
rawDataId = [];
for idP = 1:length(payloadProfiles)
   payloadProfile = payloadProfiles(idP);

   % convert phase
   switch payloadProfile.phaseName
      case 'PRE'
         payloadProfile.phaseNum = g_decArgo_phaseBuoyRed;
      case 'DES'
         payloadProfile.phaseNum = g_decArgo_phaseDsc2Prk;
      case 'PAR'
         payloadProfile.phaseNum = g_decArgo_phaseParkDrift;
      case 'DEE'
         payloadProfile.phaseNum = g_decArgo_phaseDsc2Prof;
      case 'SHO'
         payloadProfile.phaseNum = g_decArgo_phaseProfDrift;
      case 'ASC'
         payloadProfile.phaseNum = g_decArgo_phaseAscProf;
      case 'SUR'
         payloadProfile.phaseNum = g_decArgo_phaseSatTrans;
      case 'RAW'
         rawDataId = [rawDataId idP];
   end
   
   % convert treatment type
   if (~isempty(payloadProfile.subSampling))
      switch payloadProfile.subSampling(1:3)
         case 'non'
            payloadProfile.subSamplingNum = g_decArgo_treatRaw;
         case 'MEA'
            payloadProfile.subSamplingNum = g_decArgo_treatAverage;
            payloadProfile.subSamplingRate = str2num(payloadProfile.subSampling(5:end));
         case 'MED'
            payloadProfile.subSamplingNum = g_decArgo_treatMedian;
            payloadProfile.subSamplingRate = str2num(payloadProfile.subSampling(7:end));
         case 'MAX'
            payloadProfile.subSamplingNum = g_decArgo_treatMax;
            payloadProfile.subSamplingRate = str2num(payloadProfile.subSampling(4:end));
         case 'MIN'
            payloadProfile.subSamplingNum = g_decArgo_treatMin;
            payloadProfile.subSamplingRate = str2num(payloadProfile.subSampling(4:end));
         case 'STD'
            payloadProfile.subSamplingNum = g_decArgo_treatStDev;
            payloadProfile.subSamplingRate = str2num(payloadProfile.subSampling(7:end));
      end
   end
   
   % convert sensor number
   payloadProfile.sensorNumDecArgo = convert_payload_sensor_number(payloadProfile.sensorNum);
   if (isempty(payloadProfile.sensorNumDecArgo))
      fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Not able to convert payload sensor #%d to a given decoder one\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         g_decArgo_cycleNumFloat, ...
         g_decArgo_patternNumFloat, ...
         payloadProfile.sensorNum);
   end
   
   % convert date of first sample
   payloadProfile.juld = datenum(payloadProfile.date(1:19), ...
      'yyyy-mm-ddTHH:MM:SS') - g_decArgo_janFirst1950InMatlab;
   if (length(payloadProfile.date) > 19)
      payloadProfile.juld = payloadProfile.juld + str2double(payloadProfile.date(20:end))/86400;
   end
   
   % set parameter names
   payloadProfile.paramNumberWithSubLevels = [];
   payloadProfile.paramNumberOfSubLevels = [];
   switch payloadProfile.sensorNumDecArgo
      case 1 % OPTODE
         if (~isempty(payloadProfile.subSamplingNum))
            switch payloadProfile.subSamplingNum
               case {g_decArgo_treatRaw, g_decArgo_treatAverage}
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                     {'TEMP_DOXY'} {'C1PHASE_DOXY'} {'C2PHASE_DOXY'}};
               case g_decArgo_treatMedian
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                     {'TEMP_DOXY_MED'} {'C1PHASE_DOXY_MED'} {'C2PHASE_DOXY_MED'}};
               case g_decArgo_treatMax
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                     {'TEMP_DOXY_MAX'} {'C1PHASE_DOXY_MAX'} {'C2PHASE_DOXY_MAX'}};
               case g_decArgo_treatMin
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                     {'TEMP_DOXY_MIN'} {'C1PHASE_DOXY_MIN'} {'C2PHASE_DOXY_MIN'}};
               case g_decArgo_treatStDev
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                     {'TEMP_DOXY_STD'} {'C1PHASE_DOXY_STD'} {'C2PHASE_DOXY_STD'}};
            end
         else
            payloadProfile.paramNameDecArgo = {{'JULD'} ...
               {'TEMP_DOXY'} {'C1PHASE_DOXY'} {'C2PHASE_DOXY'}};
         end
      case 2 % OCR
         if (~isempty(payloadProfile.subSamplingNum))
            switch payloadProfile.subSamplingNum
               case {g_decArgo_treatRaw, g_decArgo_treatAverage}
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                     {'RAW_DOWNWELLING_IRRADIANCE380'} {'RAW_DOWNWELLING_IRRADIANCE412'} ...
                     {'RAW_DOWNWELLING_IRRADIANCE490'} {'RAW_DOWNWELLING_PAR'}};
               case g_decArgo_treatMedian
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                     {'RAW_DOWNWELLING_IRRADIANCE380_MED'} {'RAW_DOWNWELLING_IRRADIANCE412_MED'} ...
                     {'RAW_DOWNWELLING_IRRADIANCE490_MED'} {'RAW_DOWNWELLING_PAR_MED'}};
               case g_decArgo_treatMax
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                     {'RAW_DOWNWELLING_IRRADIANCE380_MAX'} {'RAW_DOWNWELLING_IRRADIANCE412_MAX'} ...
                     {'RAW_DOWNWELLING_IRRADIANCE490_MAX'} {'RAW_DOWNWELLING_PAR_MAX'}};
               case g_decArgo_treatMin
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                     {'RAW_DOWNWELLING_IRRADIANCE380_MIN'} {'RAW_DOWNWELLING_IRRADIANCE412_MIN'} ...
                     {'RAW_DOWNWELLING_IRRADIANCE490_MIN'} {'RAW_DOWNWELLING_PAR_MIN'}};
               case g_decArgo_treatStDev
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                     {'RAW_DOWNWELLING_IRRADIANCE380_STD'} {'RAW_DOWNWELLING_IRRADIANCE412_STD'} ...
                     {'RAW_DOWNWELLING_IRRADIANCE490_STD'} {'RAW_DOWNWELLING_PAR_STD'}};
            end
         else
            payloadProfile.paramNameDecArgo = {{'JULD'} ...
               {'RAW_DOWNWELLING_IRRADIANCE380'} {'RAW_DOWNWELLING_IRRADIANCE412'} ...
               {'RAW_DOWNWELLING_IRRADIANCE490'} {'RAW_DOWNWELLING_PAR'}};
         end
      case 3 % ECO3
         if (~isempty(payloadProfile.subSamplingNum))
            switch payloadProfile.subSamplingNum
               case {g_decArgo_treatRaw, g_decArgo_treatAverage}
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                     {'FLUORESCENCE_CHLA'} {'BETA_BACKSCATTERING700'} {'FLUORESCENCE_CDOM'}};
               case g_decArgo_treatMedian
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                     {'FLUORESCENCE_CHLA_MED'} {'BETA_BACKSCATTERING700_MED'} {'FLUORESCENCE_CDOM_MED'}};
               case g_decArgo_treatMax
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                     {'FLUORESCENCE_CHLA_MAX'} {'BETA_BACKSCATTERING700_MAX'} {'FLUORESCENCE_CDOM_MAX'}};
               case g_decArgo_treatMin
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                     {'FLUORESCENCE_CHLA_MIN'} {'BETA_BACKSCATTERING700_MIN'} {'FLUORESCENCE_CDOM_MIN'}};
               case g_decArgo_treatStDev
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                     {'FLUORESCENCE_CHLA_STD'} {'BETA_BACKSCATTERING700_STD'} {'FLUORESCENCE_CDOM_STD'}};
            end
         else
            payloadProfile.paramNameDecArgo = {{'JULD'} ...
               {'FLUORESCENCE_CHLA'} {'BETA_BACKSCATTERING700'} {'FLUORESCENCE_CDOM'}};
         end
      case 6 % SUNA
         if (~isempty(payloadProfile.subSamplingNum))
            switch payloadProfile.subSamplingNum
               case {g_decArgo_treatRaw, g_decArgo_treatAverage}
                  if (FITLM_MATLAB_FUNCTION_NOT_AVAILABLE)
                     payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                        {'PRES2'} {'TEMP2'} {'PSAL2'} ...
                        {'TEMP_NITRATE'} {'TEMP_SPECTROPHOTOMETER_NITRATE'} {'HUMIDITY_NITRATE'} ...
                        {'UV_INTENSITY_DARK_NITRATE'} {'UV_INTENSITY_DARK_NITRATE_STD'} ...
                        {'MOLAR_NITRATE'} ...
                        {'FIT_ERROR_NITRATE'} {'UV_INTENSITY_NITRATE'}};

                     payloadProfile.paramNumberWithSubLevels = 12;
                     payloadProfile.paramNumberOfSubLevels = ...
                        size(payloadProfile.data, 2) - length(payloadProfile.paramNameDecArgo) + 1;
                  else
                     payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                        {'PRES2'} {'TEMP2'} {'PSAL2'} ...
                        {'TEMP_NITRATE'} {'TEMP_SPECTROPHOTOMETER_NITRATE'} {'HUMIDITY_NITRATE'} ...
                        {'UV_INTENSITY_DARK_NITRATE'} {'UV_INTENSITY_DARK_NITRATE_STD'} ...
                        {'FIT_ERROR_NITRATE'} {'UV_INTENSITY_NITRATE'}};
                     
                     payloadProfile.paramNumberWithSubLevels = 11;
                     payloadProfile.paramNumberOfSubLevels = ...
                        size(payloadProfile.data, 2) - length(payloadProfile.paramNameDecArgo);
                  end
                  %                case g_decArgo_treatAverage
                  %                case g_decArgo_treatMedian
                  %                case g_decArgo_treatMax
                  %                case g_decArgo_treatMin
                  %                case g_decArgo_treatStDev
               otherwise
                  fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Don''t know how to create parameters for payload sensor #%d with sub-sampling #%d\n', ...
                     g_decArgo_floatNum, ...
                     g_decArgo_cycleNum, ...
                     g_decArgo_cycleNumFloat, ...
                     g_decArgo_patternNumFloat, ...
                     payloadProfile.sensorNum, payloadProfile.subSamplingNum);
            end
         else
            if (FITLM_MATLAB_FUNCTION_NOT_AVAILABLE)
               payloadProfile.paramNameDecArgo = {{'JULD'} ...
                  {'PRES2'} {'TEMP2'} {'PSAL2'} ...
                  {'TEMP_NITRATE'} {'TEMP_SPECTROPHOTOMETER_NITRATE'} {'HUMIDITY_NITRATE'} ...
                  {'UV_INTENSITY_DARK_NITRATE'} {'UV_INTENSITY_DARK_NITRATE_STD'} ...
                  {'MOLAR_NITRATE'} ...
                  {'FIT_ERROR_NITRATE'} {'UV_INTENSITY_NITRATE'}};
               
               payloadProfile.paramNumberWithSubLevels = 12;
               payloadProfile.paramNumberOfSubLevels = ...
                  size(payloadProfile.data, 2) - length(payloadProfile.paramNameDecArgo) + 1;
            else
               payloadProfile.paramNameDecArgo = {{'JULD'} ...
                  {'PRES2'} {'TEMP2'} {'PSAL2'} ...
                  {'TEMP_NITRATE'} {'TEMP_SPECTROPHOTOMETER_NITRATE'} {'HUMIDITY_NITRATE'} ...
                  {'UV_INTENSITY_DARK_NITRATE'} {'UV_INTENSITY_DARK_NITRATE_STD'} ...
                  {'FIT_ERROR_NITRATE'} {'UV_INTENSITY_NITRATE'}};
               
               payloadProfile.paramNumberWithSubLevels = 11;
               payloadProfile.paramNumberOfSubLevels = ...
                  size(payloadProfile.data, 2) - length(payloadProfile.paramNameDecArgo);
            end
         end
      case 7 % TRANSISTOR_PH
         if (~isempty(payloadProfile.subSamplingNum))
            switch payloadProfile.subSamplingNum
               case {g_decArgo_treatRaw, g_decArgo_treatAverage}
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                     {'VRS_PH'} {'VK_PH'} {'IK_PH'} {'IB_PH'}};
               case g_decArgo_treatMedian
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                     {'VRS_PH_MED'} {'VK_PH_MED'} {'IK_PH_MED'} {'IB_PH_MED'}};
               case g_decArgo_treatMax
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                     {'VRS_PH_MAX'} {'VK_PH_MAX'} {'IK_PH_MAX'} {'IB_PH_MAX'}};
               case g_decArgo_treatMin
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                     {'VRS_PH_MIN'} {'VK_PH_MIN'} {'IK_PH_MIN'} {'IB_PH_MIN'}};
               case g_decArgo_treatStDev
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PRES'} ...
                     {'VRS_PH_STD'} {'VK_PH_STD'} {'IK_PH_STD'} {'IB_PH_STD'}};
            end
         else
            payloadProfile.paramNameDecArgo = {{'JULD'} ...
               {'VRS_PH'} {'VK_PH'} {'IK_PH'} {'IB_PH'}};
         end         
      case 107 % UVP6
         if (~isempty(payloadProfile.subSamplingNum))
            switch payloadProfile.subSamplingNum
               case {g_decArgo_treatRaw, g_decArgo_treatAverage}
                  payloadProfile.paramNameDecArgo = {{'JULD'} {'PARAM_1'} ...
                     {'PRES'} {'PARAM_2'} {'PARAM_3'} ...
                     {'IMAGE_NUMBER_PARTICLES'} {'TEMP_PARTICLES'} ...
                     {'NB_SIZE_SPECTRA_PARTICLES'} {'GREY_SIZE_SPECTRA_PARTICLES'}};
                  
                  payloadProfile.paramNumberWithSubLevels = [7 8];
                  payloadProfile.paramNumberOfSubLevels = [18 18];
                  
                  %                case g_decArgo_treatAverage
                  %                case g_decArgo_treatMedian
                  %                case g_decArgo_treatMax
                  %                case g_decArgo_treatMin
                  %                case g_decArgo_treatStDev
               otherwise
                  fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Don''t know how to create parameters for payload sensor #%d with sub-sampling #%d\n', ...
                     g_decArgo_floatNum, ...
                     g_decArgo_cycleNum, ...
                     g_decArgo_cycleNumFloat, ...
                     g_decArgo_patternNumFloat, ...
                     payloadProfile.sensorNum, payloadProfile.subSamplingNum);
            end
         else
            payloadProfile.paramNameDecArgo = {{'JULD'} ...
               {'PARAM_1'} {'PARAM_2'} {'PARAM_3'} ...
               {'IMAGE_NUMBER_PARTICLES'} {'TEMP_PARTICLES'} ...
               {'NB_SIZE_SPECTRA_PARTICLES'} {'GREY_SIZE_SPECTRA_PARTICLES'}};
         end         
   end
   
   payloadProfiles(idP) = payloadProfile;
end

% put raw data samples at the end of payload profiles (because the phase of
% these data will be determined by data sampled by the same sensor)
if (~isempty(rawDataId))
   payloadProfileRaw = payloadProfiles(rawDataId);
   payloadProfiles(rawDataId) = [];
   payloadProfiles = [payloadProfiles payloadProfileRaw];
   rawDataId = (1:length(rawDataId)) + length(payloadProfiles) - length(rawDataId);
end

% create cycle time data array
tabCycleTimes = create_cycle_times(g_decArgo_trajDataFromApmtTech);

% process the profiles
profStructAll = [];
for idP = 1:length(payloadProfiles)
   
   payloadProfile = payloadProfiles(idP);
   
   % set the phase number of raw data profile
   if (ismember(idP, rawDataId))
      
      % we use other dated measurements to find the phase number of the raw data
      rawDataDates = payloadProfile.juld + double(payloadProfile.data(:, 1))/86400;

      % use the CTD measurement times
      for idProfCtd = 1:length(a_tabProfileCtd)
         if (any((rawDataDates >= a_tabProfileCtd(idProfCtd).minMeasDate) & ...
               (rawDataDates <= a_tabProfileCtd(idProfCtd).maxMeasDate)))
            payloadProfile.phaseNum = a_tabProfileCtd(idProfCtd).phaseNumber;
            break
         end
      end
      
      % if needed, use the payload sensor measurement times
      if (isempty(payloadProfile.phaseNum))
         for idProfPayload = 1:length(profStructAll)
            if (any((rawDataDates >= profStructAll(idProfPayload).minMeasDate) & ...
                  (rawDataDates <= profStructAll(idProfPayload).maxMeasDate)))
               payloadProfile.phaseNum = profStructAll(idProfPayload).phaseNumber;
               break
            end
         end
      end
      
      % if needed, use the cycle timings
      if (isempty(payloadProfile.phaseNum))
         payloadProfile.phaseNum = set_phase_of_raw_data(payloadProfile, a_timeInformation);
      end
      
      if (isempty(payloadProfile.phaseNum))
         fprintf('DEC_ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Unable to determine phase of raw data for sensor #%d => raw data ignored\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            g_decArgo_cycleNumFloat, ...
            g_decArgo_patternNumFloat, ...
            payloadProfile.sensorNumDecArgo);
         continue
      end
   end
      
   profStruct = get_profile_init_struct( ...
      g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat, payloadProfile.phaseNum, 0);
   profStruct.outputCycleNumber = g_decArgo_cycleNum;
   profStruct.sensorNumber = payloadProfile.sensorNumDecArgo;
   profStruct.payloadSensorNumber = payloadProfile.sensorNum;
   %    if (profStruct.sensorNumber == 1)
   %       profStruct.primarySamplingProfileFlag = -1;
   %    end
   
   % The following code is removed (set as comment) to be compliant with the
   % following decision:
   % From "Minutes of the 6th BGC-Argo meeting 27, 28 November 2017, Hamburg"
   % http://www.argodatamgt.org/content/download/30911/209493/file/minutes_BGC6_ADMT18.pdf
   % If oxygen data follow the same vertical sampling scheme(s) as CTD data, they
   % are stored in the same N_PROF(s) as the TEMP and PSAL data.
   % If oxygen data follow an independent vertical sampling scheme, their data are
   % not split into two, a profile and near-surface sampling, but put into one
   % single vertical sampling scheme (N_PROF>1).

   % set the CTD cut-off pressure (for DOXY profile only, to be consistent with
   % what is done for PTSO floats)
   %    if (profStruct.sensorNumber == 1)
   %       if (profStruct.phaseNumber == g_decArgo_phaseAscProf)
   %          if (~isempty(a_presCutOffProf))
   %             % use the sub surface point transmitted in the CTD data
   %             profStruct.presCutOffProf = a_presCutOffProf;
   %             profStruct.subSurfMeasReceived = 1;
   %          else
   %             % get the pressure cut-off for CTD ascending profile (from the
   %             % configuration)
   %             configPresCutOffProf = config_get_value_ir_rudics_cts5(g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat, 'CONFIG_APMT_SENSOR_01_P54');
   %             if (~isempty(configPresCutOffProf) && ~isnan(configPresCutOffProf))
   %                profStruct.presCutOffProf = configPresCutOffProf;
   %
   %                fprintf('DEC_WARNING: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): PRES_CUT_OFF_PROF parameter is missing in apmt data => value retrieved from the configuration\n', ...
   %                   g_decArgo_floatNum, ...
   %                   g_decArgo_cycleNum, ...
   %                   g_decArgo_cycleNumFloat, ...
   %                   g_decArgo_patternNumFloat);
   %             else
   %                fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): PRES_CUT_OFF_PROF parameter is missing in the configuration => CTD profile not split\n', ...
   %                   g_decArgo_floatNum, ...
   %                   g_decArgo_cycleNum, ...
   %                   g_decArgo_cycleNumFloat, ...
   %                   g_decArgo_patternNumFloat);
   %             end
   %          end
   %       end
   %    end
   
   % store data measurements
   data = payloadProfile.data;
   if (~isempty(data))
      
      paramList = [];
      paramNameList = payloadProfile.paramNameDecArgo;
      for idParam = 2:length(paramNameList)
         paramList = [paramList get_netcdf_param_attributes(paramNameList{idParam}{:})];
      end
      profStruct.paramList = paramList;
      
      profStruct.paramNumberWithSubLevels = payloadProfile.paramNumberWithSubLevels;
      profStruct.paramNumberOfSubLevels = payloadProfile.paramNumberOfSubLevels;
      
      profStruct.treatType = payloadProfile.subSamplingNum;
      
      profStruct.dateList = get_netcdf_param_attributes('JULD');

      if ((payloadProfile.sensorNum == 4) && (~FITLM_MATLAB_FUNCTION_NOT_AVAILABLE))
         % remove MOLAR_NITRATE data
         data(:, 11) = [];
      end
      
      % convert decoder default values (which is Nan value set when decoded data
      % equal inf('single')) to netCDF fill values
      idData = 2;
      for idParam = 1:length(paramList) % first column is JULD (not in paramList)
         nbCol = 1;
         if (~isempty(profStruct.paramNumberWithSubLevels))
            idF = find(profStruct.paramNumberWithSubLevels == idParam);
            if (~isempty(idF))
               nbCol = profStruct.paramNumberOfSubLevels(idF);
            end
         end
         if (any(isnan(data(:, idData:idData+nbCol-1))))
            data(find(isnan(data(:, idData:idData+nbCol-1))), idData:idData+nbCol-1) = paramList(idParam).fillValue;
         end
         if (~isempty(profStruct.paramNumberWithSubLevels))
            idF = find(profStruct.paramNumberWithSubLevels == idParam);
            if (~isempty(idF))
               idData = idData + profStruct.paramNumberOfSubLevels(idF) - 1;
            end
         end
         idData = idData + 1;
      end
      
      profStruct.data = data(:, 2:end);
      profStruct.dates = payloadProfile.juld + double(data(:, 1))/86400;
      profStruct.datesAdj = adjust_time_cts5(profStruct.dates);

      % measurement dates
      profStruct.minMeasDate = min(profStruct.datesAdj);
      profStruct.maxMeasDate = max(profStruct.datesAdj);
      
      % due to payload issue, the measured data could be from a previous cycle
      profStruct = check_payload_profile_cycle_number(profStruct, tabCycleTimes);
      
      % TEMPORARY
      % specific
      if (g_decArgo_floatNum == 6902968)
         % remove 'PARAM_1', 'PARAM_2', 'PARAM_3' data from
         % profile
         if (any(strcmp({profStruct.paramList.name}, 'PARAM_1') | ...
               strcmp({profStruct.paramList.name}, 'PARAM_2') | ...
               strcmp({profStruct.paramList.name}, 'PARAM_3')))
            idToDel  = find(strcmp({profStruct.paramList.name}, 'PARAM_1') | ...
               strcmp({profStruct.paramList.name}, 'PARAM_2') | ...
               strcmp({profStruct.paramList.name}, 'PARAM_3'));
            if (max(idToDel) < min(profStruct.paramNumberWithSubLevels))
               profStruct.paramList(:, idToDel) = [];
               profStruct.paramNumberWithSubLevels = profStruct.paramNumberWithSubLevels - length(idToDel);
               profStruct.data(:, idToDel) = [];
            end
         end
         % multiply the number of images analyzed and averaged by the
         % number of levels averaged (i.e. 20)
         if (any(strcmp({profStruct.paramList.name}, 'IMAGE_NUMBER_PARTICLES')))
            idParam  = find(strcmp({profStruct.paramList.name}, 'IMAGE_NUMBER_PARTICLES'));
            if (idParam < min(profStruct.paramNumberWithSubLevels))
               profStruct.data(:, idParam) = profStruct.data(:, idParam) * 20;
            end
         end
         % divide the number of particles per size class by 0.63 to obtain
         % the number of particles per litre
         if (any(strcmp({profStruct.paramList.name}, 'NB_SIZE_SPECTRA_PARTICLES')))
            idParam  = find(strcmp({profStruct.paramList.name}, 'NB_SIZE_SPECTRA_PARTICLES'));
            idF = find(profStruct.paramNumberWithSubLevels == idParam);
            firstCol = idParam;
            lastCol = idParam + payloadProfile.paramNumberOfSubLevels(idF) - 1;
            profStruct.data(:, firstCol:lastCol) = profStruct.data(:, firstCol:lastCol) / 0.63;
         end
      end
   end
   profStructAll = [profStructAll profStruct]; % use to determine the phase of raw data
   
   % move PTS of the SUNA profile to a new profile
   profStruct = split_profile_suna(profStruct);
   
   for idProf = 1:length(profStruct)

      switch (profStruct(idProf).phaseNumber)
         
         case {g_decArgo_phaseBuoyRed, g_decArgo_phaseSatTrans}
            if (~ismember(idP, rawDataId))
               o_tabSurf = [o_tabSurf profStruct(idProf)];
            else
               profStruct(idProf).sensorNumber = profStruct(idProf).sensorNumber + 1000;
               o_tabSurfRaw = [o_tabSurfRaw profStruct(idProf)];
            end
            
         case g_decArgo_phaseParkDrift
            if (~ismember(idP, rawDataId))
               o_tabDrift = [o_tabDrift profStruct(idProf)];
            else
               profStruct(idProf).sensorNumber = profStruct(idProf).sensorNumber + 1000;
               o_tabDriftRaw = [o_tabDriftRaw profStruct(idProf)];
            end
            
         case {g_decArgo_phaseDsc2Prk, g_decArgo_phaseAscProf}
            
            % profile direction
            if (profStruct(idProf).phaseNumber == g_decArgo_phaseDsc2Prk)
               profStruct(idProf).direction = 'D';
            end
            
            % positioning system
            profStruct(idProf).posSystem = 'GPS';
            
            % profile date and location information
            
            % look for the time data set to use (remember that some payload
            % profiles may have been affected to a previous cycle)
            idF = find( ...
               (cell2mat(a_timeDataAll(:, 1)) == profStruct(idProf).cycleNumber) & ...
               (cell2mat(a_timeDataAll(:, 2)) == profStruct(idProf).profileNumber));
            if (~isempty(idF))
               timeData = a_timeDataAll{idF, 3};
               [profStruct(idProf)] = add_profile_date_and_location_ir_rudics_cts5( ...
                  profStruct(idProf), timeData, a_gpsData);
            else
               fprintf('DEC_ERROR: Float #%d Cycle #%d: Unable to retrieve time information to date and locate sensor #%d profile => profile not dated\n', ...
                  g_decArgo_floatNum, ...
                  profStruct(idProf).outputCycleNumber, ...
                  profStruct(idProf).sensorNumber);
            end
            
            if (~ismember(idP, rawDataId))
               o_tabProfiles = [o_tabProfiles profStruct(idProf)];
            else
               profStruct(idProf).sensorNumber = profStruct(idProf).sensorNumber + 1000;
               o_tabProfilesRaw = [o_tabProfilesRaw profStruct(idProf)];
            end
            
         otherwise
            if (profStruct(idProf).phaseNumber == g_decArgo_phaseDsc2Prof)
               fprintf('WARNING: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Data from sensor #%d sampled during ''descent from parking depth to profile depth'' phase have been received => data ignored\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum, ...
                  g_decArgo_cycleNumFloat, ...
                  g_decArgo_patternNumFloat, ...
                  profStruct(idProf).sensorNumber);
            else
               fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Don''t know how to process data for sensor #%d and phase #%d\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum, ...
                  g_decArgo_cycleNumFloat, ...
                  g_decArgo_patternNumFloat, ...
                  profStruct(idProf).sensorNumber, profStruct(idProf).phaseNumber);
            end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Check that payload measurement times correspond to the current cycle and
% pattern. If not, update the concerned informations of the profile structure.
%
% SYNTAX :
%  [o_profStruct] = check_payload_profile_cycle_number(a_profStruct, a_tabCycleTimes)
%
% INPUT PARAMETERS :
%   a_profStruct    : input profiles
%   a_tabCycleTimes : main cycle timings
%
% OUTPUT PARAMETERS :
%   o_profStruct : output profiles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profStruct] = check_payload_profile_cycle_number(a_profStruct, a_tabCycleTimes)

% output parameter initialization
o_profStruct = a_profStruct;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloat;
global g_decArgo_patternNumFloat;

% due to payload issue, we should store all time information (to assign payload
% data to their correct cycle)
global g_decArgo_dataPayloadCorrectedCycle;

% cycle phases
global g_decArgo_phaseAscProf;


% only data sampled during ascent are affected by payload data storage
% issue
if (a_profStruct.phaseNumber ~= g_decArgo_phaseAscProf)
   return
end

% find cycle start time for the concerned cycle
idF = find((a_tabCycleTimes(:, 1) == o_profStruct.cycleNumber) & ...
   (a_tabCycleTimes(:, 2) == o_profStruct.profileNumber) & ...
   (a_tabCycleTimes(:, 3) == o_profStruct.outputCycleNumber));

if (~isempty(idF))
   % we cannot use o_profStruct.minMeasDate because measurements may start
   % before AST
   % Ex: 6902969 (84, 1) firts meas date: 2019-06-14T05:49:28.593292
   % whereas AST: 2019/06/14 05:50:02 (adj: 2019/06/14 05:50:02)
   if (o_profStruct.maxMeasDate < a_tabCycleTimes(idF, 4))
      
      % the cycle number is erroneous
      idF = find(o_profStruct.maxMeasDate > a_tabCycleTimes(:, 4), 1, 'last');
      if (~isempty(idF))
         
         fprintf('DEC_INFO: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Payload data of sensor #%d and phase #%d moved to Cycle #%d: (Cy,Ptn)=(%d,%d)\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            g_decArgo_cycleNumFloat, ...
            g_decArgo_patternNumFloat, ...
            o_profStruct.sensorNumber, o_profStruct.phaseNumber, ...
            a_tabCycleTimes(idF, 3), ...
            a_tabCycleTimes(idF, 1), ...
            a_tabCycleTimes(idF, 2));
         
         o_profStruct.cycleNumber = a_tabCycleTimes(idF, 1);
         o_profStruct.profileNumber = a_tabCycleTimes(idF, 2);
         o_profStruct.outputCycleNumber = a_tabCycleTimes(idF, 3);
         
         g_decArgo_dataPayloadCorrectedCycle = 1;
      end
   end
end

return

% ------------------------------------------------------------------------------
% Determine the phase of 'raw' data from their measurement timings.
%
% SYNTAX :
%  [o_phaseNum] = set_phase_of_raw_data(a_payloadProfile, a_timeInformation)
%
% INPUT PARAMETERS :
%   a_payloadProfile  : input profiles
%   a_timeInformation : time information
%
% OUTPUT PARAMETERS :
%   o_phaseNum : found phase number
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_phaseNum] = set_phase_of_raw_data(a_payloadProfile, a_timeInformation)

% output parameter initialization
o_phaseNum = '';

% global measurement codes
global g_MC_DST;
global g_MC_PST;
global g_MC_PET;
global g_MC_DPST;
global g_MC_AST;
global g_MC_AET;

% cycle phases
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseDsc2Prof;
global g_decArgo_phaseProfDrift;
global g_decArgo_phaseAscProf;
global g_decArgo_phaseSatTrans;


payloadProfileDates = a_payloadProfile.juld + double(a_payloadProfile.data(:, 1))/86400;
for idL = 1:size(a_timeInformation, 1)
   
   timedata = a_timeInformation{idL, 4};
   timedata = [timedata{:}];
   idJuld = find(strcmp({timedata.paramName}, 'JULD'));
   
   measCodeList = [timedata(idJuld).measCode];
   timeList = [timedata(idJuld).value];
   
   timeDST = get_time(g_MC_DST, measCodeList, timeList);
   timePST = get_time(g_MC_PST, measCodeList, timeList);
   timePET = get_time(g_MC_PET, measCodeList, timeList);
   timeDPST = get_time(g_MC_DPST, measCodeList, timeList);
   timeAST = get_time(g_MC_AST, measCodeList, timeList);
   timeAET = get_time(g_MC_AET, measCodeList, timeList);
   
   if ((~isempty(timeDST)&& ~isempty(timePST)) && ...
         (any((payloadProfileDates >= timeDST) & (payloadProfileDates <= timePST))))
      o_phaseNum = g_decArgo_phaseDsc2Prk;
   elseif ((~isempty(timePST)&& ~isempty(timePET)) && ...
         (any((payloadProfileDates >= timePST) & (payloadProfileDates <= timePET))))
      o_phaseNum = g_decArgo_phaseParkDrift;
   elseif ((~isempty(timePET)&& ~isempty(timeDPST)) && ...
         (any((payloadProfileDates >= timePET) & (payloadProfileDates <= timeDPST))))
      o_phaseNum = g_decArgo_phaseDsc2Prof;
   elseif ((~isempty(timeDPST)&& ~isempty(timeAST)) && ...
         (any((payloadProfileDates >= timeDPST) & (payloadProfileDates <= timeAST))))
      o_phaseNum = g_decArgo_phaseProfDrift;
   elseif ((~isempty(timeAST)&& ~isempty(timeAET)) && ...
         (any((payloadProfileDates >= timeAST) & (payloadProfileDates <= timeAET))))
      o_phaseNum = g_decArgo_phaseAscProf;
   elseif (~isempty(timeAET) && ...
         any(payloadProfileDates >= timeAET))
      o_phaseNum = g_decArgo_phaseSatTrans;
   end
end

return

% ------------------------------------------------------------------------------
% Split the SUNA profile in 2, one with SUNA measurements and one with CTD
% measurements.
%
% SYNTAX :
%  [o_tabProfiles] = split_profile_suna(a_tabProfiles)
%
% INPUT PARAMETERS :
%   a_tabProfiles : input profile structures
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : output profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/09/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = split_profile_suna(a_tabProfiles)

% output parameters initialization
o_tabProfiles = a_tabProfiles;


% process SUNA profiles only
if (a_tabProfiles.sensorNumber == 6)
   idFPres2 = find(strcmp('PRES2', {a_tabProfiles.paramList.name}));
   idFTemp2 = find(strcmp('TEMP2', {a_tabProfiles.paramList.name}));
   idFPsal2 = find(strcmp('PSAL2', {a_tabProfiles.paramList.name}));
   if (~isempty(idFPres2) && ~isempty(idFTemp2) && ~isempty(idFPsal2))
      
      % a profile with SUNA data excluding PRES2, TEMP2 and PSAL2
      profile1 = a_tabProfiles;
      profile1.paramList([idFPres2 idFTemp2 idFPsal2]) = [];
      profile1.paramNumberWithSubLevels = profile1.paramNumberWithSubLevels - 3;
      profile1.data(:, [idFPres2 idFTemp2 idFPsal2]) = [];
      
      % a profile with only PRES2, TEMP2 and PSAL2
      profile2 = a_tabProfiles;
      profile2.paramList = a_tabProfiles.paramList([idFPres2 idFTemp2 idFPsal2]);
      profile2.paramList(1).name = 'PRES';
      profile2.paramList(2).name = 'TEMP';
      profile2.paramList(3).name = 'PSAL';
      profile2.paramNumberWithSubLevels = [];
      profile2.paramNumberOfSubLevels = [];
      profile2.data = a_tabProfiles.data(:, [idFPres2 idFTemp2 idFPsal2]);
      paramJuld = get_netcdf_param_attributes('JULD');
      profile2.dates = ones(size(profile2.data, 1), 1)*paramJuld.fillValue;
      profile2.datesAdj = ones(size(profile2.data, 1), 1)*paramJuld.fillValue;
      profile2.minMeasDate = [];
      profile2.maxMeasDate = [];
      
      % output parameters initialization
      o_tabProfiles = [profile1 profile2];
   end
end

return

% ------------------------------------------------------------------------------
% Create main cycle timings from APMT traj information.
%
% SYNTAX :
%  [o_tabCycleTimes] = create_cycle_times(a_allTrajDataFromApmtTech)
%
% INPUT PARAMETERS :
%   a_allTrajDataFromApmtTech : APMT traj information
%
% OUTPUT PARAMETERS :
%   o_tabCycleTimes : main cycle timings
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabCycleTimes] = create_cycle_times(a_allTrajDataFromApmtTech)

% output parameter initialization
o_tabCycleTimes = [];

% global measurement codes
global g_MC_CycleStart;
global g_MC_DST;
global g_MC_FST;
global g_MC_PST;
global g_MC_PET;
global g_MC_DPST;
global g_MC_AST;


for idL = 1:size(a_allTrajDataFromApmtTech, 1)
   
   timedata = a_allTrajDataFromApmtTech{idL, 4};
   timedata = [timedata{:}];
   idJuld = find(strcmp({timedata.paramName}, 'JULD'));
   
   measCodeList = [timedata(idJuld).measCode];
   timeList = [timedata(idJuld).value];
   
   timeStart = get_time(g_MC_AST, measCodeList, timeList);
   if (isempty(timeStart))
      timeStart = get_time(g_MC_DPST, measCodeList, timeList);
   end
   if (isempty(timeStart))
      timeStart = get_time(g_MC_PET, measCodeList, timeList);
   end
   if (isempty(timeStart))
      timeStart = get_time(g_MC_PST, measCodeList, timeList);
   end
   if (isempty(timeStart))
      timeStart = get_time(g_MC_FST, measCodeList, timeList);
   end
   if (isempty(timeStart))
      timeStart = get_time(g_MC_DST, measCodeList, timeList);
   end
   if (isempty(timeStart))
      timeStart = get_time(g_MC_CycleStart, measCodeList, timeList);
   end
   
   if (~isempty(timeStart))
      o_tabCycleTimes = [o_tabCycleTimes;
         a_allTrajDataFromApmtTech{idL, 1} ...
         a_allTrajDataFromApmtTech{idL, 2} ...
         a_allTrajDataFromApmtTech{idL, 3} ...
         timeStart];
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve time associated to a given measurement code.
%
% SYNTAX :
%  [o_time] = get_time(a_measCode, a_measCodeTab, a_timeTab)
%
% INPUT PARAMETERS :
%   a_measCode    : concerned measurement code
%   a_measCodeTab : list of measurement codes
%   a_timeTab     : list of times
%
% OUTPUT PARAMETERS :
%   o_time : retieved time
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_time] = get_time(a_measCode, a_measCodeTab, a_timeTab)

% output parameter initialization
o_time = '';

idTime = find(a_measCodeTab == a_measCode);
if (~isempty(idTime))
   o_time = a_timeTab(idTime);
end

return
