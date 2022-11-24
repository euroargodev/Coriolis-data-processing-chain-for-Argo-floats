% ------------------------------------------------------------------------------
% Decode science_log files of one cycle of APEX APF11 Iridium data.
%
% SYNTAX :
%  [o_miscInfo, o_techData, o_gpsData, ...
%    o_profCtdP, o_profCtdPt, o_profCtdPts, o_profCtdPtsh, o_profDo, ...
%    o_profCtdCp, o_profCtdCpH, ...
%    o_profFlbb, o_profFlbbCfg, o_profFlbbCd, o_profFlbbCdCfg, o_profOcr504I, ...
%    o_profRamses, ...
%    o_profRafosRtc, o_profRafos, ...
%    o_cycleTimeData] = ...
%    decode_science_log_apx_apf11_ir(a_scienceLogFileList, a_iradLogFileList, ...
%    a_cycleTimeData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_scienceLogFileList : list of science_log files
%   a_iradLogFileList    : list of irad_log files
%   a_cycleTimeData      : input cycle timings data
%   a_decoderId          : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_miscInfo      : misc information from science_log files
%   o_techData      : TECH data from science_log files
%   o_gpsData       : GPS data from science_log files
%   o_profCtdP      : CTD_P data
%   o_profCtdPt     : CTD_PT data
%   o_profCtdPts    : CTD_PTS data
%   o_profCtdPtsh   : CTD_PTSH data
%   o_profDo        : O2 data
%   o_profCtdCp     : CTD_CP data
%   o_profCtdCpH    : CTD_CP_H data
%   o_profFlbb      : FLBB data
%   o_profFlbbCfg   : FLBB_CFG data
%   o_profFlbbCd    : FLBB_CD data
%   o_profFlbbCdCfg : FLBB_CD_CFG data
%   o_profOcr504I   : OCR_504I data
%   o_profRamses    : RAMSES data
%   o_profRafosRtc  : RAFOS_RTC data
%   o_profRafos     : RAFOS data
%   o_cycleTimeData : cycle timings data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_miscInfo, o_techData, o_gpsData, ...
   o_profCtdP, o_profCtdPt, o_profCtdPts, o_profCtdPtsh, o_profDo, ...
   o_profCtdCp, o_profCtdCpH, ...
   o_profFlbb, o_profFlbbCfg, o_profFlbbCd, o_profFlbbCdCfg, o_profOcr504I, ...
   o_profRamses, ...
   o_profRafosRtc, o_profRafos, ...
   o_cycleTimeData] = ...
   decode_science_log_apx_apf11_ir(a_scienceLogFileList, a_iradLogFileList, ...
   a_cycleTimeData, a_decoderId)

% output parameters initialization
o_miscInfo = [];
o_techData = [];
o_gpsData = [];
o_profCtdP = [];
o_profCtdPt = [];
o_profCtdPts = [];
o_profCtdPtsh = [];
o_profDo = [];
o_profCtdCp = [];
o_profCtdCpH = [];
o_profFlbb = [];
o_profFlbbCfg = [];
o_profFlbbCd = [];
o_profFlbbCdCfg = [];
o_profRamses = [];
o_profOcr504I = [];
o_profRafosRtc = [];
o_profRafos = [];
o_cycleTimeData = a_cycleTimeData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% parameter added "on the fly" to meta-data file
global g_decArgo_addParamNbSampleCtd;
global g_decArgo_addParamNbSampleSfet;


if (isempty(a_scienceLogFileList))
   return
end

if (length(a_scienceLogFileList) > 1)
   fprintf('DEC_INFO: Float #%d Cycle #%d: multiple (%d) science_log file for this cycle\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, length(a_scienceLogFileList));
end

expectedFields = [ ...
   {'Message'} ...
   {'GPS'} ...
   {'CTD_bins'} ...
   {'CTD_P'} ...
   {'CTD_PT'} ...
   {'CTD_PTS'} ...
   {'CTD_PTSH'} ...
   {'CTD_CP'} ...
   {'CTD_CP_H'} ...
   {'O2'} ...
   {'FLBB'} ...
   {'FLBB_CFG'} ...
   {'FLBB_CD'} ...
   {'FLBB_CD_CFG'} ...
   {'OCR_504I'} ...
   {'RAFOS_RTC'} ...
   {'RAFOS'} ...
   {'IRAD'} ...
   ];

usedMessages = [ ...
   {'Prelude/Self Test'} ...
   {'Park Descent Mission'} ...
   {'Park Mission'} ...
   {'Deep Descent Mission'} ...
   {'Profiling Mission'} ... % replaced by 'ASCENT' since 2.13.1.R & 2.13.1.1.R version
   {'CP Started'} ...
   {'CP Stopped'} ...
   {'Surface Mission'} ...
   {'ASCENT'} ... % replaces 'Profiling Mission' since 2.13.1.R & 2.13.1.1.R version
   {'ICEDESCENT'} ...
   {'ICEASCENT'} ...
   {'RAFOS correlation initiated'} ...
   ];

ignoredMessages = [ ...
   {'Firmware: '} ...
   {'Username: '} ...
   {'Float ID: '} ...
   {'CP Already Stopped'} ...
   {'Recovery Mission'} ...
   ];

descentStartTime = [];
ctdP = [];
ctdPt = [];
ctdPts = [];
ctdPtsh = [];
ctdCp = [];
ctdCpH = [];
do = [];
doId = [];
flbb = [];
flbbId = [];
flbbCfg = [];
flbbCd = [];
flbbCdId = [];
flbbCdCfg = [];
ocr504I = [];
ocr504IId = [];
rafosRtc = [];
rafos = [];
ramses = [];
ramsesId = [];
allPresVal = [];
for idFile = 1:length(a_scienceLogFileList)

   sciFilePathName = a_scienceLogFileList{idFile};

   % read input file
   if (isempty(g_decArgo_outputCsvFileId))
      fromLaunchFlag = 1;
   else
      fromLaunchFlag = 0;
   end
   [error, data] = read_apx_apf11_ir_binary_log_file(sciFilePathName, 'science', fromLaunchFlag, 0, a_decoderId);
   if (error == 1)
      fprintf('ERROR: Float #%d Cycle #%d: Error in file: %s - ignored\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, sciFilePathName);
      return
   end
   
   % remove CTD_P measurements with FillValue = -999 for PRES
   if (~isempty(data.CTD_P))
      if (any(data.CTD_P(:, 3) == -999))
         idF = find(data.CTD_P(:, 3) == -999);
         fprintf('WARNING: Float #%d Cycle #%d: %d CTD_P measurements (with PRES = -999) in file: %s - removed\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, length(idF), sciFilePathName);
         data.CTD_P(idF, :) = [];
      end
   end
   
   % remove CTD_PT measurements with PRES = 0 and TEMP = 0
   if (~isempty(data.CTD_PT))
      if (any((data.CTD_PT(:, 3) == 0) & (data.CTD_PT(:, 4) == 0)))
         idF = find((data.CTD_PT(:, 3) == 0) & (data.CTD_PT(:, 4) == 0));
         fprintf('WARNING: Float #%d Cycle #%d: %d CTD_PT measurements (with PRES = 0 and TEMP = 0) in file: %s - removed\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, length(idF), sciFilePathName);
         data.CTD_PT(idF, :) = [];
      end
   end
   
   dataFields = fieldnames(data);
   for idFld = 1:length(dataFields)
      fieldName = dataFields{idFld};
      if (~any(strfind(fieldName, '_labels')))
         if (~isempty(data.(fieldName)))
            if (ismember(fieldName, expectedFields))
               switch (fieldName)
                  case 'Message'
                     msg = data.(fieldName);
                     for idM = 1:size(msg, 1)
                        msgData = msg{idM, 2};
                        idF = cellfun(@(x) strfind(msgData, x), usedMessages, 'UniformOutput', 0);
                        if (~isempty([idF{:}]))
                           msgId = find(cellfun(@(x) ~isempty(x), idF));
                           if (length(msgId) > 1)
                              if (strcmp(msgData, 'ICEASCENT'))
                                 msgId = msgId(end);
                              end
                           end
                           switch (msgId)
                              case 1 % 'Prelude/Self Test'
                                 o_cycleTimeData.preludeStartDateSci = msg{idM, 1};
                              case 2 % 'Park Descent Mission'
                                 descentStartTime = msg{idM, 1};
                                 o_cycleTimeData.descentStartDateSci = msg{idM, 1};
                              case 3 % 'Park Mission'
                                 o_cycleTimeData.parkStartDateSci = msg{idM, 1};
                              case 4 % 'Deep Descent Mission'
                                 o_cycleTimeData.parkEndDateSci = msg{idM, 1};
                              case {5, 9} % 'Profiling Mission' or 'ASCENT'
                                 o_cycleTimeData.ascentStartDateSci = msg{idM, 1};
                                 % when PARK _PRES = PROF_PRES, 'Profiling
                                 % Mission' corresponds to PARK_END_DATE
                                 if (isempty(o_cycleTimeData.parkEndDateSci))
                                    o_cycleTimeData.parkEndDateSci = o_cycleTimeData.ascentStartDateSci;
                                 end
                              case 6 % 'CP Started'
                                 o_cycleTimeData.continuousProfileStartDateSci = msg{idM, 1};
                              case 7 % 'CP Stopped'
                                 o_cycleTimeData.continuousProfileEndDateSci = msg{idM, 1};
                              case 8 % 'Surface Mission'
                                 o_cycleTimeData.ascentEndDateSci = [ ...
                                    o_cycleTimeData.ascentEndDateSci msg{idM, 1}];
                              case 10 % 'ICEDESCENT'
                                 o_cycleTimeData.iceDescentStartDateSci = [ ...
                                    o_cycleTimeData.iceDescentStartDateSci msg{idM, 1}];
                              case 11 % 'ICEASCENT'
                                 o_cycleTimeData.iceAscentStartDateSci = [ ...
                                    o_cycleTimeData.iceAscentStartDateSci msg{idM, 1}];
                              case 12 % 'RAFOS correlation initiated'
                                 o_cycleTimeData.rafosCorrelationStartDateSci = [ ...
                                    o_cycleTimeData.rafosCorrelationStartDateSci msg{idM, 1}];
                              otherwise
                                 fprintf('WARNING: Float #%d Cycle #%d: Message #%d is not managed - ignored\n', ...
                                    g_decArgo_floatNum, g_decArgo_cycleNum, msgId);
                           end
                        else
                           idF = cellfun(@(x) strfind(msgData, x), ignoredMessages, 'UniformOutput', 0);
                           if (isempty([idF{:}]))
                              fprintf('ERROR: Float #%d Cycle #%d: Not managed ''%s'' information (''%s'') in file: %s - ignored (ASK FOR AN UPDATE OF THE DECODER)\n', ...
                                 g_decArgo_floatNum, g_decArgo_cycleNum, 'Message', msgData, sciFilePathName);
                              continue
                           end
                        end
                     end
                  case 'GPS'
                     dataVal = data.(fieldName);
                     o_gpsData = [o_gpsData; dataVal(:, 2:end)];
                  case 'CTD_bins'
                     info = data.(fieldName);
                     
                     dataStruct = get_apx_misc_data_init_struct('CTD_CP_info', [], [], []);
                     dataStruct.label = 'Number of samples recorded during the mission';
                     dataStruct.value = info(3);
                     dataStruct.format = '%d';
                     o_miscInfo{end+1} = dataStruct;
                     
                     dataStruct = get_apx_tech_data_init_struct(1);
                     dataStruct.label = 'Number of samples recorded during the mission';
                     dataStruct.techId = 1001;
                     dataStruct.value = num2str(info(3));
                     dataStruct.cyNum = g_decArgo_cycleNum;
                     o_techData{end+1} = dataStruct;

                     dataStruct = get_apx_misc_data_init_struct('CTD_CP_info', [], [], []);
                     dataStruct.label = 'Number of bins recorded during the mission';
                     dataStruct.value = info(4);
                     dataStruct.format = '%d';
                     o_miscInfo{end+1} = dataStruct;
                     
                     dataStruct = get_apx_tech_data_init_struct(1);
                     dataStruct.label = 'Number of bins recorded during the mission';
                     dataStruct.techId = 1002;
                     dataStruct.value = num2str(info(4));
                     dataStruct.cyNum = g_decArgo_cycleNum;
                     o_techData{end+1} = dataStruct;

                     dataStruct = get_apx_misc_data_init_struct('CTD_CP_info', [], [], []);
                     dataStruct.label = 'Highest pressure in decibars recorded during the mission';
                     dataStruct.value = info(5);
                     dataStruct.format = '%.3f';
                     o_miscInfo{end+1} = dataStruct;
                     
                     dataStruct = get_apx_tech_data_init_struct(1);
                     dataStruct.label = 'Highest pressure in decibars recorded during the mission';
                     dataStruct.techId = 1003;
                     dataStruct.value = num2str(info(5));
                     dataStruct.cyNum = g_decArgo_cycleNum;
                     o_techData{end+1} = dataStruct;

                  case 'CTD_P'
                     dataVal = data.(fieldName);
                     ctdP = [ctdP; dataVal(:, 2:end)];
                     allPresVal = [allPresVal; dataVal(:, 1:3)];
                  case 'CTD_PT'
                     dataVal = data.(fieldName);
                     ctdPt = [ctdPt; dataVal(:, 2:end)];
                     allPresVal = [allPresVal; dataVal(:, 1:3)];
                  case 'CTD_PTS'
                     dataVal = data.(fieldName);
                     ctdPts = [ctdPts; dataVal(:, 2:end)];
                     allPresVal = [allPresVal; dataVal(:, 1:3)];
                  case 'CTD_PTSH'
                     dataVal = data.(fieldName);
                     ctdPtsh = [ctdPtsh; dataVal(:, 2:end)];
                     allPresVal = [allPresVal; dataVal(:, 1:3)];
                  case 'CTD_CP'
                     dataVal = data.(fieldName);
                     ctdCp = [ctdCp; dataVal(:, 2:end)];
                  case 'CTD_CP_H'
                     dataVal = data.(fieldName);
                     ctdCpH = [ctdCpH; dataVal(:, 2:end)];
                  case 'O2'
                     dataVal = data.(fieldName);
                     do = [do; dataVal(:, 2:end)];
                     doId = [doId; dataVal(:, 1)];
                  case 'FLBB'
                     dataVal = data.(fieldName);
                     flbb = [flbb; dataVal(:, 2:end)];
                     flbbId = [flbbId; dataVal(:, 1)];
                  case 'FLBB_CFG'
                     dataVal = data.(fieldName);
                     flbbCfg = [flbbCfg; dataVal(:, 2:end)];
                  case 'FLBB_CD'
                     dataVal = data.(fieldName);
                     flbbCd = [flbbCd; dataVal(:, 2:end)];
                     flbbCdId = [flbbCdId; dataVal(:, 1)];
                  case 'FLBB_CD_CFG'
                     dataVal = data.(fieldName);
                     flbbCdCfg = [flbbCdCfg; dataVal(:, 2:end)];
                  case 'OCR_504I'
                     dataVal = data.(fieldName);
                     ocr504I = [ocr504I; dataVal(:, 2:end)];
                     ocr504IId = [ocr504IId; dataVal(:, 1)];
                  case 'RAFOS_RTC'
                     dataVal = data.(fieldName);
                     rafosRtc = [rafosRtc; dataVal(:, 2:end)];
                  case 'RAFOS'
                     dataVal = data.(fieldName);
                     rafos = [rafos; dataVal(:, 2:end)];
                  case 'IRAD'
                     dataVal = data.(fieldName);
                     ramses = [ramses; dataVal(:, 2:end)];
                     ramsesId = [ramsesId; dataVal(:, 1)];
               end
            else
               fprintf('ERROR: Float #%d Cycle #%d: Field ''%s'' not expected in file: %s - ignored (ASK FOR AN UPDATE OF THE DECODER)\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, fieldName, sciFilePathName);
            end
         end
      end
   end
end

ramsesSpectrum = [];
for idFile = 1:length(a_iradLogFileList)

   iradFilePathName = a_iradLogFileList{idFile};

   % read input file
   if (isempty(g_decArgo_outputCsvFileId))
      fromLaunchFlag = 1;
   else
      fromLaunchFlag = 0;
   end
   [error, data] = read_apx_apf11_ir_binary_log_file(iradFilePathName, 'irad', fromLaunchFlag, 0, a_decoderId);
   if (error == 1)
      fprintf('ERROR: Float #%d Cycle #%d: Error in file: %s - ignored\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, iradFilePathName);
      return
   end
   
   dataFields = fieldnames(data);
   for idFld = 1:length(dataFields)
      fieldName = dataFields{idFld};
      switch (fieldName)
         case 'IRAD_SPECTRUM'
            ramsesSpectrum = [ramsesSpectrum; data.(fieldName)];
         otherwise
            fprintf('ERROR: Float #%d Cycle #%d: Field ''%s'' not expected in file: %s - ignored (ASK FOR AN UPDATE OF THE DECODER)\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, fieldName, iradFilePathName);
      end
   end
end

% manage Ice Descent and Ascent cycles
if (isempty(o_cycleTimeData.iceDescentStartDateSci))
   o_cycleTimeData.ascentEndDate = o_cycleTimeData.ascentEndDateSci;
else
   % store AED of Ice cycles
   o_cycleTimeData.iceAscentEndDateSci = [ ...
      o_cycleTimeData.iceDescentStartDateSci(2:end) ...
      o_cycleTimeData.ascentEndDateSci(end)];

   % first 'ICEDESCENT' is AED of primary profile
   o_cycleTimeData.ascentEndDateSci = o_cycleTimeData.iceDescentStartDateSci(1);
   o_cycleTimeData.ascentEndDate = o_cycleTimeData.ascentEndDateSys;
end

% add cycle number to GPS fixes
if (~isempty(o_gpsData))
   % first column cycle number of the fix, lats column cycle number of the fix
   % reception (used to detect when a profile needs to be updated in
   % GENERATE_NC_MONO_PROF = 2 mode)
   o_gpsData = [ones(size(o_gpsData, 1), 1)*g_decArgo_cycleNum o_gpsData ones(size(o_gpsData, 1), 1)*g_decArgo_cycleNum];
   if (~isempty(descentStartTime))
      idPrevCy = find(o_gpsData(:, 2) < descentStartTime);
      o_gpsData(idPrevCy, 1) = g_decArgo_cycleNum - 1;
   end
end

% store measurement in profile structures

% create the parameters
paramJuld = get_netcdf_param_attributes('JULD');
paramPres = get_netcdf_param_attributes('PRES');
paramPres.cFormat = '%8.2f';
paramPres.fortranFormat = 'F8.2';
paramTemp = get_netcdf_param_attributes('TEMP');
paramTemp.cFormat = '%10.4f';
paramTemp.fortranFormat = 'F10.4';
paramSal = get_netcdf_param_attributes('PSAL');
paramSal.cFormat = '%10.4f';
paramSal.fortranFormat = 'F10.4';

paramVrsPh = get_netcdf_param_attributes('VRS_PH');

paramO2 = get_netcdf_param_attributes('O2');
paramO2.cFormat = '%.5f';

paramAirSat = get_netcdf_param_attributes('AirSat');
paramAirSat.cFormat = '%.5f';

paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');

paramCalPhase = get_netcdf_param_attributes('CalPhase');
paramCalPhase.cFormat = '%.5f';

paramTphaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');

paramC1phaseDoxy = get_netcdf_param_attributes('C1PHASE_DOXY');

paramC2phaseDoxy = get_netcdf_param_attributes('C2PHASE_DOXY');

paramC1Amp = get_netcdf_param_attributes('C1Amp');
paramC1Amp.cFormat = '%.5f';

paramC2Amp = get_netcdf_param_attributes('C2Amp');
paramC2Amp.cFormat = '%.5f';

paramRawTemp = get_netcdf_param_attributes('RawTemp');
paramRawTemp.cFormat = '%.5f';

paramNbSampleCtd = get_netcdf_param_attributes('NB_SAMPLE_CTD');
paramNbSampleSfet = get_netcdf_param_attributes('NB_SAMPLE_SFET');

paramChlWave = get_netcdf_param_attributes('chl_wave');
paramChlWave.cFormat = '%d';

paramFluorescenceChla = get_netcdf_param_attributes('FLUORESCENCE_CHLA');

paramBscWave = get_netcdf_param_attributes('bsc_wave');
paramBscWave.cFormat = '%d';

paramBetaBackscattering700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');

paramCdWave = get_netcdf_param_attributes('cd_wave');
paramCdWave.cFormat = '%d';

paramFluorescenceCdom = get_netcdf_param_attributes('FLUORESCENCE_CDOM');

paramThermSig = get_netcdf_param_attributes('therm_sig');
paramThermSig.cFormat = '%d';

paramDownIrradiance380 = get_netcdf_param_attributes('DOWN_IRRADIANCE380');
paramDownIrradiance412 = get_netcdf_param_attributes('DOWN_IRRADIANCE412');
paramDownIrradiance490 = get_netcdf_param_attributes('DOWN_IRRADIANCE490');
paramDownwellingPar = get_netcdf_param_attributes('DOWNWELLING_PAR');

paramDownIrradiance443 = get_netcdf_param_attributes('DOWN_IRRADIANCE443');
paramDownIrradiance555 = get_netcdf_param_attributes('DOWN_IRRADIANCE555');
paramDownIrradiance670 = get_netcdf_param_attributes('DOWN_IRRADIANCE670');

paramRafosRtcTime = get_netcdf_param_attributes('RAFOS_RTC_TIME');
paramRafosCorrelation = get_netcdf_param_attributes('COR');
paramRafosRawToa = get_netcdf_param_attributes('RAW_TOA');

paramRadiometerIntegrationTime = get_netcdf_param_attributes('RADIOMETER_INTEGRATION_TIME');
paramRadiometerTemp = get_netcdf_param_attributes('RADIOMETER_TEMP');
paramRadiometerPres = get_netcdf_param_attributes('RADIOMETER_PRES');
paramRadiometerPreInclination = get_netcdf_param_attributes('RADIOMETER_PRE_INCLINATION');
paramRadiometerPostInclination = get_netcdf_param_attributes('RADIOMETER_POST_INCLINATION');
paramRawDownwellingIrradiance = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE');

if (~isempty(ctdP))
   o_profCtdP = get_apx_profile_data_init_struct;
   o_profCtdP.dateList = paramJuld;
   o_profCtdP.dates = ctdP(:, 1);
   o_profCtdP.dates(isnan(o_profCtdP.dates)) = paramJuld.fillValue;
   o_profCtdP.paramList = [paramPres];
   o_profCtdP.data = ctdP(:, 2);
   
   if (any(isnan(o_profCtdP.dates)))
      idNoDate = find(isnan(o_profCtdP.dates));
      fprintf('ERROR: Float #%d Cycle #%d: %d not dated CTD_P measurements in file: %s - ASK FOR AN UPDATE OF THE DECODER\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, length(idNoDate), sciFilePathName);
      o_profCtdP.dates(isnan(o_profCtdP.dates)) = paramJuld.fillValue;
   end
end

if (~isempty(ctdPt))
   o_profCtdPt = get_apx_profile_data_init_struct;
   o_profCtdPt.dateList = paramJuld;
   o_profCtdPt.dates = ctdPt(:, 1);
   o_profCtdPt.paramList = [paramPres paramTemp];
   o_profCtdPt.data = ctdPt(:, 2:end);
   
   if (any(isnan(o_profCtdPt.dates)))
      idNoDate = find(isnan(o_profCtdPt.dates));
      fprintf('ERROR: Float #%d Cycle #%d: %d not dated CTD_PT measurements in file: %s - ASK FOR AN UPDATE OF THE DECODER\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, length(idNoDate), sciFilePathName);
      o_profCtdPt.dates(isnan(o_profCtdPt.dates)) = paramJuld.fillValue;
   end
end

if (~isempty(ctdPts))
   o_profCtdPts = get_apx_profile_data_init_struct;
   o_profCtdPts.dateList = paramJuld;
   o_profCtdPts.dates = ctdPts(:, 1);
   o_profCtdPts.paramList = [paramPres paramTemp paramSal];
   o_profCtdPts.data = ctdPts(:, 2:end);
   
   if (any(isnan(o_profCtdPts.dates)))
      idNoDate = find(isnan(o_profCtdPts.dates));
      fprintf('ERROR: Float #%d Cycle #%d: %d not dated CTD_PTS measurements in file: %s - ASK FOR AN UPDATE OF THE DECODER\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, length(idNoDate), sciFilePathName);
      o_profCtdPts.dates(isnan(o_profCtdPts.dates)) = paramJuld.fillValue;
   end
end

if (~isempty(ctdPtsh))
   o_profCtdPtsh = get_apx_profile_data_init_struct;
   o_profCtdPtsh.dateList = paramJuld;
   o_profCtdPtsh.dates = ctdPtsh(:, 1);
   o_profCtdPtsh.paramList = [paramPres paramTemp paramSal paramVrsPh];
   o_profCtdPtsh.data = ctdPtsh(:, 2:end);
   o_profCtdPtsh.data(isnan(o_profCtdPtsh.data(:, 4)), 4) = paramVrsPh.fillValue;
   
   if (any(isnan(o_profCtdPtsh.dates)))
      idNoDate = find(isnan(o_profCtdPtsh.dates));
      fprintf('ERROR: Float #%d Cycle #%d: %d not dated CTD_PTSH measurements in file: %s - ASK FOR AN UPDATE OF THE DECODER\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, length(idNoDate), sciFilePathName);
      o_profCtdPtsh.dates(isnan(o_profCtdPtsh.dates)) = paramJuld.fillValue;
   end
end

if (~isempty(do))
   o_profDo = get_apx_profile_data_init_struct;
   o_profDo.dateList = paramJuld;
   o_profDo.dates = do(:, 1);
   o_profDo.paramList = [paramPres paramO2 paramAirSat paramTempDoxy ...
      paramCalPhase paramTphaseDoxy paramC1phaseDoxy paramC2phaseDoxy ...
      paramC1Amp paramC2Amp paramRawTemp];
   o_profDo.data = [ones(size(do, 1), 1)*paramPres.fillValue do(:, 2:end)];
   o_profDo.data(isnan(o_profDo.data(:, 4)), 4) = paramTempDoxy.fillValue;
   o_profDo.data(isnan(o_profDo.data(:, 7)), 7) = paramC1phaseDoxy.fillValue;
   o_profDo.data(isnan(o_profDo.data(:, 8)), 8) = paramC2phaseDoxy.fillValue;
   
   if (any(isnan(o_profDo.dates)))
      
      idNoDate = find(isnan(o_profDo.dates));
      fprintf('WARNING: Float #%d Cycle #%d: %d not dated O2 measurements in file: %s - PRES is averaged\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, length(idNoDate), sciFilePathName);

   end
end

if (~isempty(ctdCp))
   o_profCtdCp = get_apx_profile_data_init_struct;
   o_profCtdCp.paramList = [paramPres paramTemp paramSal paramNbSampleCtd];
   o_profCtdCp.data = ctdCp(:, 2:end);
   g_decArgo_addParamNbSampleCtd = 1;
end

if (~isempty(ctdCpH))
   o_profCtdCpH = get_apx_profile_data_init_struct;
   o_profCtdCpH.paramList = [paramPres paramTemp paramSal paramNbSampleCtd paramVrsPh paramNbSampleSfet];
   o_profCtdCpH.data = ctdCpH(:, 2:end);
   o_profCtdCpH.data(isnan(o_profCtdCpH.data(:, 5)), 5) = paramVrsPh.fillValue;
   g_decArgo_addParamNbSampleCtd = 1;
   g_decArgo_addParamNbSampleSfet = 1;
end

if (~isempty(flbb))
   o_profFlbb = get_apx_profile_data_init_struct;
   o_profFlbb.dateList = paramJuld;
   o_profFlbb.dates = flbb(:, 1);
   o_profFlbb.paramList = [paramPres paramFluorescenceChla paramBetaBackscattering700 paramThermSig];
   o_profFlbb.data = [ones(size(flbb, 1), 1)*paramPres.fillValue flbb(:, 2:end)];
   
   if (any(isnan(o_profFlbb.dates)))
      idNoDate = find(isnan(o_profFlbb.dates));
      fprintf('ERROR: Float #%d Cycle #%d: %d not dated FLBB measurements in file: %s - ASK FOR AN UPDATE OF THE DECODER\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, length(idNoDate), sciFilePathName);
      o_profFlbb.dates(isnan(o_profFlbb.dates)) = paramJuld.fillValue;
   end
end

if (~isempty(flbbCfg))
   o_profFlbbCfg = get_apx_profile_data_init_struct;
   o_profFlbbCfg.dateList = paramJuld;
   o_profFlbbCfg.dates = flbbCfg(:, 1);
   o_profFlbbCfg.paramList = [paramPres paramChlWave paramBscWave];
   o_profFlbbCfg.data = [ones(size(flbbCfg, 1), 1)*paramPres.fillValue flbbCfg(:, 2:end)];
   
   if (any(isnan(o_profFlbbCfg.dates)))
      idNoDate = find(isnan(o_profFlbbCfg.dates));
      fprintf('ERROR: Float #%d Cycle #%d: %d not dated FLBB_CFG measurements in file: %s - ASK FOR AN UPDATE OF THE DECODER\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, length(idNoDate), sciFilePathName);
      o_profFlbbCfg.dates(isnan(o_profFlbbCfg.dates)) = paramJuld.fillValue;
   end
end

if (~isempty(flbbCd))
   o_profFlbbCd = get_apx_profile_data_init_struct;
   o_profFlbbCd.dateList = paramJuld;
   o_profFlbbCd.dates = flbbCd(:, 1);
   if (ismember(a_decoderId, [1121, 1122, 1123, 1124, 1126, 1127, 1321, 1322, 1323])) % the decoding template differs for decoders before 2.15.0
      o_profFlbbCd.paramList = [paramPres paramChlWave paramFluorescenceChla paramBscWave ...
         paramBetaBackscattering700 paramCdWave paramFluorescenceCdom paramThermSig];
   else
      o_profFlbbCd.paramList = [paramPres paramFluorescenceChla ...
         paramBetaBackscattering700 paramFluorescenceCdom paramThermSig];
   end
   o_profFlbbCd.data = [ones(size(flbbCd, 1), 1)*paramPres.fillValue flbbCd(:, 2:end)];
   
   if (any(isnan(o_profFlbbCd.dates)))
      idNoDate = find(isnan(o_profFlbbCd.dates));
      fprintf('ERROR: Float #%d Cycle #%d: %d not dated FLBB_CD measurements in file: %s - ASK FOR AN UPDATE OF THE DECODER\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, length(idNoDate), sciFilePathName);
      o_profFlbbCd.dates(isnan(o_profFlbbCd.dates)) = paramJuld.fillValue;
   end
end

if (~isempty(flbbCdCfg))
   o_profFlbbCdCfg = get_apx_profile_data_init_struct;
   o_profFlbbCdCfg.dateList = paramJuld;
   o_profFlbbCdCfg.dates = flbbCdCfg(:, 1);
   o_profFlbbCdCfg.paramList = [paramPres paramChlWave paramBscWave paramCdWave];
   o_profFlbbCdCfg.data = [ones(size(flbbCdCfg, 1), 1)*paramPres.fillValue flbbCdCfg(:, 2:end)];
   
   if (any(isnan(o_profFlbbCdCfg.dates)))
      idNoDate = find(isnan(o_profFlbbCdCfg.dates));
      fprintf('ERROR: Float #%d Cycle #%d: %d not dated FLBB_CD_CFG measurements in file: %s - ASK FOR AN UPDATE OF THE DECODER\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, length(idNoDate), sciFilePathName);
      o_profFlbbCdCfg.dates(isnan(o_profFlbbCdCfg.dates)) = paramJuld.fillValue;
   end
end

if (~isempty(ocr504I))
   % use calibration coefficients to define which parameters are concerned
   if (isempty(g_decArgo_calibInfo))
      fprintf('ERROR: Float #%d Cycle #%d: Calibration information is missing - cannot determine OCR parameters\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
   elseif (~isfield(g_decArgo_calibInfo, 'OCR'))
      fprintf('ERROR: Float #%d Cycle #%d: OCR sensor calibration information is missing - cannot determine OCR parameters\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
   else
      if (isfield(g_decArgo_calibInfo.OCR, 'A0Lambda380') && ...
            isfield(g_decArgo_calibInfo.OCR, 'A1Lambda380') && ...
            isfield(g_decArgo_calibInfo.OCR, 'LmLambda380') && ...
            isfield(g_decArgo_calibInfo.OCR, 'A0Lambda412') && ...
            isfield(g_decArgo_calibInfo.OCR, 'A1Lambda412') && ...
            isfield(g_decArgo_calibInfo.OCR, 'LmLambda412') && ...
            isfield(g_decArgo_calibInfo.OCR, 'A0Lambda490') && ...
            isfield(g_decArgo_calibInfo.OCR, 'A1Lambda490') && ...
            isfield(g_decArgo_calibInfo.OCR, 'LmLambda490') && ...
            isfield(g_decArgo_calibInfo.OCR, 'A0PAR') && ...
            isfield(g_decArgo_calibInfo.OCR, 'A1PAR') && ...
            isfield(g_decArgo_calibInfo.OCR, 'LmPAR'))
         
         o_profOcr504I = get_apx_profile_data_init_struct;
         o_profOcr504I.dateList = paramJuld;
         o_profOcr504I.dates = ocr504I(:, 1);
         o_profOcr504I.paramList = [paramPres ...
            paramDownIrradiance380 paramDownIrradiance412 ...
            paramDownIrradiance490 paramDownwellingPar];
         % BE CAREFULL: convert to Argo parameter units
         ocr504I(:, 2:4) =  ocr504I(:, 2:4)*0.01;
         o_profOcr504I.data = [ones(size(ocr504I, 1), 1)*paramPres.fillValue ocr504I(:, 2:end)];
         
         if (any(isnan(o_profOcr504I.dates)))
            idNoDate = find(isnan(o_profOcr504I.dates));
            fprintf('ERROR: Float #%d Cycle #%d: %d not dated OCR_504I measurements in file: %s - ASK FOR AN UPDATE OF THE DECODER\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, length(idNoDate), sciFilePathName);
            o_profOcr504I.dates(isnan(o_profOcr504I.dates)) = paramJuld.fillValue;
         end
         
      elseif (isfield(g_decArgo_calibInfo.OCR, 'A0Lambda443') && ...
            isfield(g_decArgo_calibInfo.OCR, 'A1Lambda443') && ...
            isfield(g_decArgo_calibInfo.OCR, 'LmLambda443') && ...
            isfield(g_decArgo_calibInfo.OCR, 'A0Lambda490') && ...
            isfield(g_decArgo_calibInfo.OCR, 'A1Lambda490') && ...
            isfield(g_decArgo_calibInfo.OCR, 'LmLambda490') && ...
            isfield(g_decArgo_calibInfo.OCR, 'A0Lambda555') && ...
            isfield(g_decArgo_calibInfo.OCR, 'A1Lambda555') && ...
            isfield(g_decArgo_calibInfo.OCR, 'LmLambda555') && ...
            isfield(g_decArgo_calibInfo.OCR, 'A0Lambda670') && ...
            isfield(g_decArgo_calibInfo.OCR, 'A1Lambda670') && ...
            isfield(g_decArgo_calibInfo.OCR, 'LmLambda670'))
         
         o_profOcr504I = get_apx_profile_data_init_struct;
         o_profOcr504I.dateList = paramJuld;
         o_profOcr504I.dates = ocr504I(:, 1);
         o_profOcr504I.paramList = [paramPres ...
            paramDownIrradiance443 paramDownIrradiance490 ...
            paramDownIrradiance555 paramDownIrradiance670];
         % BE CAREFULL: convert to Argo parameter units
         ocr504I(:, 2:end) =  ocr504I(:, 2:end)*0.01;
         o_profOcr504I.data = [ones(size(ocr504I, 1), 1)*paramPres.fillValue ocr504I(:, 2:end)];
         
         if (any(isnan(o_profOcr504I.dates)))
            idNoDate = find(isnan(o_profOcr504I.dates));
            fprintf('ERROR: Float #%d Cycle #%d: %d not dated OCR_504I measurements in file: %s - ASK FOR AN UPDATE OF THE DECODER\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, length(idNoDate), sciFilePathName);
            o_profOcr504I.dates(isnan(o_profOcr504I.dates)) = paramJuld.fillValue;
         end
         
      else
         fprintf('ERROR: Float #%d Cycle #%d: Found unexpected set of OCR calibration coefficients - cannot determine OCR parameters\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
      end
   end
end

if (~isempty(rafosRtc))
   o_profRafosRtc = get_apx_profile_data_init_struct;
   o_profRafosRtc.dateList = paramJuld;
   o_profRafosRtc.dates = rafosRtc(:, 1);
   o_profRafosRtc.dates(isnan(o_profRafosRtc.dates)) = paramJuld.fillValue;
   o_profRafosRtc.paramList = paramRafosRtcTime;
   o_profRafosRtc.data = rafosRtc(:, 2);
end

if (~isempty(rafos))
   o_profRafos = get_apx_profile_data_init_struct;
   o_profRafos.dateList = paramJuld;
   o_profRafos.dates = rafos(:, 1);
   o_profRafos.paramList = [paramRafosCorrelation paramRafosRawToa];
   o_profRafos.paramNumberWithSubLevels = 1:2;
   o_profRafos.paramNumberOfSubLevels = [6 6];
   o_profRafos.data = rafos(:, [2:2:end 3:2:end]);
   
   if (any(isnan(o_profRafos.dates)))
      idNoDate = find(isnan(o_profRafos.dates));
      fprintf('ERROR: Float #%d Cycle #%d: %d not dated RAFOS measurements in file: %s - ASK FOR AN UPDATE OF THE DECODER\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, length(idNoDate), sciFilePathName);
      o_profRafos.dates(isnan(o_profRafos.dates)) = paramJuld.fillValue;
   end
end

if (~isempty(ramses) && ~isempty(ramsesSpectrum))
   
   % merge ramses and ramsesSpectrum data
   dates = unique([ramses(:, 1) ramsesSpectrum(:, 1)]);
   data = nan(length(dates), size(ramses, 2)+size(ramsesSpectrum, 2)-2);
   idF = find(ramses(:, 1) == dates);
   data(idF, 1:size(ramses, 2)-1) = ramses(:, 2:end);
   idF = find(ramsesSpectrum(:, 1) == dates);
   data(idF, size(ramses, 2):end) = ramsesSpectrum(:, 2:end);
   
   % create the profile structure
   o_profRamses = get_apx_profile_data_init_struct;
   o_profRamses.dateList = paramJuld;
   o_profRamses.dates = dates;
   o_profRamses.paramList = [paramPres ...
      paramRadiometerIntegrationTime ...
      paramRadiometerTemp paramRadiometerPres ...
      paramRadiometerPreInclination paramRadiometerPostInclination ...
      paramRawDownwellingIrradiance];
   o_profRamses.paramNumberWithSubLevels = 7;
   o_profRamses.paramNumberOfSubLevels = 255;
   o_profRamses.data = [ones(size(data, 1), 1)*paramPres.fillValue data];
   
   % RADIOMETER_PRES is provided in bars
   o_profRamses.data(:, 4) = o_profRamses.data(:, 4)*10;
   
   if (any(isnan(o_profRamses.dates)))
      idNoDate = find(isnan(o_profRamses.dates));
      fprintf('ERROR: Float #%d Cycle #%d: %d not dated RAMSES measurements in file: %s - ASK FOR AN UPDATE OF THE DECODER\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, length(idNoDate), sciFilePathName);
      o_profRamses.dates(isnan(o_profRamses.dates)) = paramJuld.fillValue;
   end
end

% add PRES for DO, FLBB, OCR and RAMSES data
if (~isempty(o_profDo) || ...
      ~isempty(o_profFlbb)|| ...
      ~isempty(o_profFlbbCd) || ...
      ~isempty(o_profOcr504I) || ...
      ~isempty(o_profRamses))
   tabJuld = [];
   tabPres = [];
   if (~isempty(o_profCtdP))
      tabJuld = [tabJuld; o_profCtdP.dates];
      tabPres = [tabPres; o_profCtdP.data];
   end
   if (~isempty(o_profCtdPt))
      tabJuld = [tabJuld; o_profCtdPt.dates];
      tabPres = [tabPres; o_profCtdPt.data(:, 1)];
   end
   if (~isempty(o_profCtdPts))
      tabJuld = [tabJuld; o_profCtdPts.dates];
      tabPres = [tabPres; o_profCtdPts.data(:, 1)];
   end
   if (~isempty(o_profCtdPtsh))
      tabJuld = [tabJuld; o_profCtdPtsh.dates];
      tabPres = [tabPres; o_profCtdPtsh.data(:, 1)];
   end
   idDel = find(tabPres == paramPres.fillValue);
   tabJuld(idDel) = [];
   tabPres(idDel) = [];
   
   if (~isempty(tabPres))
      [tabJuld, idSort] = sort(tabJuld);
      tabPres = tabPres(idSort);
      
      idJuldEq = find(diff(tabJuld) == 0);
      if (~isempty(idJuldEq))
         tabJuld(idJuldEq) = [];
         tabPres(idJuldEq) = [];
      end
   end
   
   if (length(tabPres) > 1)
      if (~isempty(o_profDo))
         interpData = interp1(tabJuld, tabPres, o_profDo.dates, 'linear');
         o_profDo.data(~isnan(interpData), 1) = interpData(~isnan(interpData));
      end
      if (~isempty(o_profFlbb))
         o_profFlbb.data(:, 1) = interp1(tabJuld, tabPres, o_profFlbb.dates, 'linear');
         o_profFlbb.data(isnan(o_profFlbb.data(:, 1)), 1) = paramPres.fillValue;
      end
      if (~isempty(o_profFlbbCd))
         o_profFlbbCd.data(:, 1) = interp1(tabJuld, tabPres, o_profFlbbCd.dates, 'linear');
         o_profFlbbCd.data(isnan(o_profFlbbCd.data(:, 1)), 1) = paramPres.fillValue;
      end
      if (~isempty(o_profOcr504I))
         o_profOcr504I.data(:, 1) = interp1(tabJuld, tabPres, o_profOcr504I.dates, 'linear');
         o_profOcr504I.data(isnan(o_profOcr504I.data(:, 1)), 1) = paramPres.fillValue;
      end
      if (~isempty(o_profRamses))
         o_profRamses.data(:, 1) = interp1(tabJuld, tabPres, o_profRamses.dates, 'linear');
         o_profRamses.data(isnan(o_profRamses.data(:, 1)), 1) = paramPres.fillValue;
      end
   end
end

% add times to do measurements
if (~isempty(o_profDo) && any(isnan(o_profDo.dates)))
   
   % gather all (Id, JULD, PRES) information
   presAll = allPresVal;
   if (~isempty(flbbId))
      presAll = [presAll; [flbbId o_profFlbb.dates double(o_profFlbb.data(:, 1))]];
   end
   if (~isempty(flbbCdId))
      presAll = [presAll; [flbbCdId o_profFlbbCd.dates double(o_profFlbbCd.data(:, 1))]];
   end
   if (~isempty(ocr504IId))
      presAll = [presAll; [ocr504IId o_profOcr504I.dates double(o_profOcr504I.data(:, 1))]];
   end
   if (~isempty(ramsesId))
      presAll = [presAll; [ramsesId o_profRamses.dates double(o_profRamses.data(:, 1))]];
   end
   
   % add do measurements Ids
   presAll = [presAll; [doId nan(size(doId, 1), 2)]];

   % fill do pressures and times
   presDo = ones(size(do, 1), 1)*paramPres.fillValue;
   presDates = ones(size(do, 1), 1)*paramJuld.fillValue;
   
   [~, sortId] = sort(presAll(:, 1));
   presAll = presAll(sortId, :);
   prevPres = '';
   lastNanId = [];
   for id = 1:size(presAll, 1)
      if (~isnan(presAll(id, 3)))
         if (~isempty(lastNanId))
            if (~isempty(prevPres))
               presDo(doId == presAll(lastNanId, 1)) = prevPres(3) + (presAll(id, 3) - prevPres(3))/2;
               presDates(doId == presAll(lastNanId, 1)) = prevPres(2) + (presAll(id, 2) - prevPres(2))/2;
            else
               presDo(doId == presAll(lastNanId, 1)) = presAll(id, 3);
               presDates(doId == presAll(lastNanId, 1)) = presAll(id, 2);
            end
            lastNanId = [];
         end
         prevPres = presAll(id, :);
      else
         lastNanId = [lastNanId; id];
      end
   end
   if (isnan(presAll(end, 3)))
      if (~isempty(prevPres))
         presDo(doId == presAll(lastNanId, 1)) = prevPres(3);
         presDates(doId == presAll(lastNanId, 1)) = prevPres(2);
      end
   end
   
   o_profDo.dates = presDates; % profil generation process is based on measurements dates
   o_profDo.data(:, 1) = presDo;
   o_profDo.temporaryDates = 1;
end

% add cycle times associated pressures (from CTD_P measurements)
if (~isempty(o_profCtdP))
   if (~isempty(o_cycleTimeData.descentStartDateSci))
      refDateStr = julian_2_gregorian_dec_argo(o_cycleTimeData.descentStartDateSci);
      idF1 = find(o_profCtdP.dates >= o_cycleTimeData.descentStartDateSci, 1, 'first');
      idF2 = find(o_profCtdP.dates <= o_cycleTimeData.descentStartDateSci, 1, 'last');
      if (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF1)), refDateStr))
         o_cycleTimeData.descentStartPresSci = o_profCtdP.data(idF1);
      elseif (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF2)), refDateStr))
         o_cycleTimeData.descentStartPresSci = o_profCtdP.data(idF2);
      else
         o_cycleTimeData.descentStartPresSci = (o_profCtdP.data(idF1)+o_profCtdP.data(idF2))/2;
      end
   end
   if (~isempty(o_cycleTimeData.rafosCorrelationStartDateSci))
      dates = o_cycleTimeData.rafosCorrelationStartDateSci;
      for idD = 1:length(dates)
         refDateStr = julian_2_gregorian_dec_argo(dates(idD));
         idF1 = find(o_profCtdP.dates >= dates(idD), 1, 'first');
         idF2 = find(o_profCtdP.dates <= dates(idD), 1, 'last');
         if (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF1)), refDateStr))
            o_cycleTimeData.rafosCorrelationStartPresSci = [ ...
               o_cycleTimeData.rafosCorrelationStartPresSci o_profCtdP.data(idF1)];
         elseif (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF2)), refDateStr))
            o_cycleTimeData.rafosCorrelationStartPresSci = [ ...
               o_cycleTimeData.rafosCorrelationStartPresSci o_profCtdP.data(idF2)];
         else
            o_cycleTimeData.rafosCorrelationStartPresSci = [ ...
               o_cycleTimeData.rafosCorrelationStartPresSci (o_profCtdP.data(idF1)+o_profCtdP.data(idF2))/2];
         end
      end
   end
   if (~isempty(o_cycleTimeData.parkStartDateSci))
      refDateStr = julian_2_gregorian_dec_argo(o_cycleTimeData.parkStartDateSci);
      idF1 = find(o_profCtdP.dates >= o_cycleTimeData.parkStartDateSci, 1, 'first');
      idF2 = find(o_profCtdP.dates <= o_cycleTimeData.parkStartDateSci, 1, 'last');
      if (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF1)), refDateStr))
         o_cycleTimeData.parkStartPresSci = o_profCtdP.data(idF1);
      elseif (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF2)), refDateStr))
         o_cycleTimeData.parkStartPresSci = o_profCtdP.data(idF2);
      else
         o_cycleTimeData.parkStartPresSci = (o_profCtdP.data(idF1)+o_profCtdP.data(idF2))/2;
      end
   end
   if (~isempty(o_cycleTimeData.parkEndDateSci))
      refDateStr = julian_2_gregorian_dec_argo(o_cycleTimeData.parkEndDateSci);
      idF1 = find(o_profCtdP.dates >= o_cycleTimeData.parkEndDateSci, 1, 'first');
      idF2 = find(o_profCtdP.dates <= o_cycleTimeData.parkEndDateSci, 1, 'last');
      if (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF1)), refDateStr))
         o_cycleTimeData.parkEndPresSci = o_profCtdP.data(idF1);
      elseif (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF2)), refDateStr))
         o_cycleTimeData.parkEndPresSci = o_profCtdP.data(idF2);
      else
         o_cycleTimeData.parkEndPresSci = (o_profCtdP.data(idF1)+o_profCtdP.data(idF2))/2;
      end
   end
   if (~isempty(o_cycleTimeData.ascentStartDateSci))
      refDateStr = julian_2_gregorian_dec_argo(o_cycleTimeData.ascentStartDateSci);
      idF1 = find(o_profCtdP.dates >= o_cycleTimeData.ascentStartDateSci, 1, 'first');
      idF2 = find(o_profCtdP.dates <= o_cycleTimeData.ascentStartDateSci, 1, 'last');
      if (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF1)), refDateStr))
         o_cycleTimeData.ascentStartPresSci = o_profCtdP.data(idF1);
      elseif (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF2)), refDateStr))
         o_cycleTimeData.ascentStartPresSci = o_profCtdP.data(idF2);
      else
         o_cycleTimeData.ascentStartPresSci = (o_profCtdP.data(idF1)+o_profCtdP.data(idF2))/2;
      end
   end
   if (~isempty(o_cycleTimeData.continuousProfileStartDateSci))
      refDateStr = julian_2_gregorian_dec_argo(o_cycleTimeData.continuousProfileStartDateSci);
      idF1 = find(o_profCtdP.dates >= o_cycleTimeData.continuousProfileStartDateSci, 1, 'first');
      idF2 = find(o_profCtdP.dates <= o_cycleTimeData.continuousProfileStartDateSci, 1, 'last');
      if (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF1)), refDateStr))
         o_cycleTimeData.continuousProfileStartPresSci = o_profCtdP.data(idF1);
      elseif (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF2)), refDateStr))
         o_cycleTimeData.continuousProfileStartPresSci = o_profCtdP.data(idF2);
      else
         o_cycleTimeData.continuousProfileStartPresSci = (o_profCtdP.data(idF1)+o_profCtdP.data(idF2))/2;
      end
   end
   if (~isempty(o_cycleTimeData.continuousProfileEndDateSci))
      refDateStr = julian_2_gregorian_dec_argo(o_cycleTimeData.continuousProfileEndDateSci);
      idF1 = find(o_profCtdP.dates >= o_cycleTimeData.continuousProfileEndDateSci, 1, 'first');
      idF2 = find(o_profCtdP.dates <= o_cycleTimeData.continuousProfileEndDateSci, 1, 'last');
      if (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF1)), refDateStr))
         o_cycleTimeData.continuousProfileEndPresSci = o_profCtdP.data(idF1);
      elseif (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF2)), refDateStr))
         o_cycleTimeData.continuousProfileEndPresSci = o_profCtdP.data(idF2);
      else
         o_cycleTimeData.continuousProfileEndPresSci = (o_profCtdP.data(idF1)+o_profCtdP.data(idF2))/2;
      end
   end
   if (~isempty(o_cycleTimeData.ascentEndDateSci))
      refDateStr = julian_2_gregorian_dec_argo(o_cycleTimeData.ascentEndDateSci);
      idF1 = find(o_profCtdP.dates >= o_cycleTimeData.ascentEndDateSci, 1, 'first');
      idF2 = find(o_profCtdP.dates <= o_cycleTimeData.ascentEndDateSci, 1, 'last');
      if (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF1)), refDateStr))
         o_cycleTimeData.ascentEndPresSci = o_profCtdP.data(idF1);
      elseif (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF2)), refDateStr))
         o_cycleTimeData.ascentEndPresSci = o_profCtdP.data(idF2);
      else
         o_cycleTimeData.ascentEndPresSci = (o_profCtdP.data(idF1)+o_profCtdP.data(idF2))/2;
      end
   end
   if (~isempty(o_cycleTimeData.iceDescentStartDateSci))
      dates = o_cycleTimeData.iceDescentStartDateSci;
      for idD = 1:length(dates)
         refDateStr = julian_2_gregorian_dec_argo(dates(idD));
         idF1 = find(o_profCtdP.dates >= dates(idD), 1, 'first');
         idF2 = find(o_profCtdP.dates <= dates(idD), 1, 'last');
         if (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF1)), refDateStr))
            o_cycleTimeData.iceDescentStartPresSci = [ ...
               o_cycleTimeData.iceDescentStartPresSci o_profCtdP.data(idF1)];
         elseif (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF2)), refDateStr))
            o_cycleTimeData.iceDescentStartPresSci = [ ...
               o_cycleTimeData.iceDescentStartPresSci o_profCtdP.data(idF2)];
         else
            o_cycleTimeData.iceDescentStartPresSci = [ ...
               o_cycleTimeData.iceDescentStartPresSci (o_profCtdP.data(idF1)+o_profCtdP.data(idF2))/2];
         end
      end
   end
   if (~isempty(o_cycleTimeData.iceAscentStartDateSci))
      dates = o_cycleTimeData.iceAscentStartDateSci;
      for idD = 1:length(dates)
         refDateStr = julian_2_gregorian_dec_argo(dates(idD));
         idF1 = find(o_profCtdP.dates >= dates(idD), 1, 'first');
         idF2 = find(o_profCtdP.dates <= dates(idD), 1, 'last');
         if (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF1)), refDateStr))
            o_cycleTimeData.iceAscentStartPresSci = [ ...
               o_cycleTimeData.iceAscentStartPresSci o_profCtdP.data(idF1)];
         elseif (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF2)), refDateStr))
            o_cycleTimeData.iceAscentStartPresSci = [ ...
               o_cycleTimeData.iceAscentStartPresSci o_profCtdP.data(idF2)];
         else
            o_cycleTimeData.iceAscentStartPresSci = [ ...
               o_cycleTimeData.iceAscentStartPresSci (o_profCtdP.data(idF1)+o_profCtdP.data(idF2))/2];
         end
      end
   end
   if (~isempty(o_cycleTimeData.iceAscentEndDateSci))
      dates = o_cycleTimeData.iceAscentEndDateSci;
      for idD = 1:length(dates)
         refDateStr = julian_2_gregorian_dec_argo(dates(idD));
         idF1 = find(o_profCtdP.dates >= dates(idD), 1, 'first');
         idF2 = find(o_profCtdP.dates <= dates(idD), 1, 'last');
         if (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF1)), refDateStr))
            o_cycleTimeData.iceAscentEndPresSci = [ ...
               o_cycleTimeData.iceAscentEndPresSci o_profCtdP.data(idF1)];
         elseif (strcmp(julian_2_gregorian_dec_argo(o_profCtdP.dates(idF2)), refDateStr))
            o_cycleTimeData.iceAscentEndPresSci = [ ...
               o_cycleTimeData.iceAscentEndPresSci o_profCtdP.data(idF2)];
         else
            o_cycleTimeData.iceAscentEndPresSci = [ ...
               o_cycleTimeData.iceAscentEndPresSci (o_profCtdP.data(idF1)+o_profCtdP.data(idF2))/2];
         end
      end
   end
end

return
