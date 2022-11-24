% ------------------------------------------------------------------------------
% Decode science_log files of one cycle of APEX APF11 Iridium data.
%
% SYNTAX :
%  [o_miscInfo, o_techData, o_gpsData, ...
%    o_profCtdP, o_profCtdPt, o_profCtdPts, o_profCtdCp, o_profDo, ...
%    o_profFlbbCd, o_profOcr504I, o_cycleTimeData] = ...
%    decode_science_log_apx_apf11_ir_1121_1321(a_scienceLogFileList, a_cycleTimeData)
%
% INPUT PARAMETERS :
%   a_scienceLogFileList : list of science_log files
%   a_cycleTimeData      : input cycle timings data
%
% OUTPUT PARAMETERS :
%   o_miscInfo      : misc information from science_log files
%   o_techData      : TECH data from science_log files
%   o_gpsData       : GPS data from science_log files
%   o_profCtdP      : CTD_P data
%   o_profCtdPt     : CTD_PT data
%   o_profCtdPts    : CTD_PTS data
%   o_profCtdCp     : CTD_CP data
%   o_profDo        : O2 data
%   o_profFlbbCd    : FLBB_CD data
%   o_profOcr504I   : OCR_504I data
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
   o_profCtdP, o_profCtdPt, o_profCtdPts, o_profCtdCp, o_profDo, ...
   o_profFlbbCd, o_profOcr504I, o_cycleTimeData] = ...
   decode_science_log_apx_apf11_ir_1121_1321(a_scienceLogFileList, a_cycleTimeData)

% output parameters initialization
o_miscInfo = [];
o_techData = [];
o_gpsData = [];
o_profCtdP = [];
o_profCtdPt = [];
o_profCtdPts = [];
o_profCtdCp = [];
o_profDo = [];
o_profFlbbCd = [];
o_profOcr504I = [];

o_cycleTimeData = a_cycleTimeData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


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
   {'CTD_CP'} ...
   {'O2'} ...
   {'FLBB_CD'} ...
   {'OCR_504I'} ...
   ];

usedMessages = [ ...
   {'Prelude/Self Test'} ...
   {'Park Descent Mission'} ...
   {'Park Mission'} ...
   {'Deep Descent Mission'} ...
   {'Profiling Mission'} ...
   {'CP Started'} ...
   {'CP Stopped'} ...
   {'Surface Mission'} ...
   ];

ignoredMessages = [ ...
   {'Firmware: '} ...
   {'Username: '} ...
   {'Float ID: '} ...
   {'CP Already Stopped'} ...
   ];

descentStartTime = [];
ctdP = [];
ctdPt = [];
ctdPts = [];
ctdCp = [];
do = [];
flbbCd = [];
ocr504I = [];
for idFile = 1:length(a_scienceLogFileList)

   sciFilePathName = a_scienceLogFileList{idFile};

   % read input file
   [error, data] = read_apx_apf11_ir_binary_log_file(sciFilePathName, 'science', 0);
   if (error == 1)
      fprintf('ERROR: Float #%d Cycle #%d: Error in file: %s => ignored\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, sciFilePathName);
      return
   end
   
   % remove CTD_P measurements with FillValue = -999 for PRES
   if (~isempty(data.CTD_P))
      if (any(data.CTD_P(:, 2) == -999))
         idF = find(data.CTD_P(:, 2) == -999);
         fprintf('WARNING: Float #%d Cycle #%d: %d CTD_P measurements (with PRES = -999) in file: %s => removed\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, length(idF), sciFilePathName);
         data.CTD_P(idF, :) = [];
      end
   end
   
   % remove CTD_PT measurements with PRES = 0 and TEMP = 0
   if (~isempty(data.CTD_PT))
      if (any((data.CTD_PT(:, 2) == 0) & (data.CTD_PT(:, 3) == 0)))
         idF = find((data.CTD_PT(:, 2) == 0) & (data.CTD_PT(:, 3) == 0));
         fprintf('WARNING: Float #%d Cycle #%d: %d CTD_PT measurements (with PRES = 0 and TEMP = 0) in file: %s => removed\n', ...
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
                           switch (msgId)
                              case 1
                                 o_cycleTimeData.preludeStartDateSci = msg{idM, 1};
                              case 2
                                 descentStartTime = msg{idM, 1};
                                 o_cycleTimeData.descentStartDateSci = msg{idM, 1};
                              case 3
                                 o_cycleTimeData.parkStartDateSci = msg{idM, 1};
                              case 4
                                 o_cycleTimeData.parkEndDateSci = msg{idM, 1};
                              case 5
                                 o_cycleTimeData.ascentStartDateSci = msg{idM, 1};
                              case 6
                                 o_cycleTimeData.continuousProfileStartDateSci = msg{idM, 1};
                              case 7
                                 o_cycleTimeData.continuousProfileEndDateSci = msg{idM, 1};
                              case 8
                                 o_cycleTimeData.ascentEndDateSci = msg{idM, 1};
                                 o_cycleTimeData.ascentEndDate = o_cycleTimeData.ascentEndDateSci;
                              otherwise
                                 fprintf('WARNING: Float #%d Cycle #%d: Message #%d is not managed => ignored\n', ...
                                    g_decArgo_floatNum, g_decArgo_cycleNum, msgId);
                           end
                        else
                           idF = cellfun(@(x) strfind(msgData, x), ignoredMessages, 'UniformOutput', 0);
                           if (isempty([idF{:}]))
                              fprintf('ERROR: Float #%d Cycle #%d: Not managed ''%s'' information (''%s'') in file: %s => ignored (ASK FOR AN UPDATE OF THE DECODER)\n', ...
                                 g_decArgo_floatNum, g_decArgo_cycleNum, 'Message', msgData, sciFilePathName);
                              continue
                           end
                        end
                     end
                  case 'GPS'
                     o_gpsData = [o_gpsData; data.(fieldName)];
                  case 'CTD_bins'
                     info = data.(fieldName);
                     
                     dataStruct = get_apx_misc_data_init_struct('CTD_CP_info', [], [], []);
                     dataStruct.label = 'Number of samples recorded during the mission';
                     dataStruct.value = info(2);
                     dataStruct.format = '%d';
                     o_miscInfo{end+1} = dataStruct;
                     
                     dataStruct = get_apx_tech_data_init_struct(1);
                     dataStruct.label = 'Number of samples recorded during the mission';
                     dataStruct.techId = 1001;
                     dataStruct.value = num2str(info(2));
                     dataStruct.cyNum = g_decArgo_cycleNum;
                     o_techData{end+1} = dataStruct;

                     dataStruct = get_apx_misc_data_init_struct('CTD_CP_info', [], [], []);
                     dataStruct.label = 'Number of bins recorded during the mission';
                     dataStruct.value = info(3);
                     dataStruct.format = '%d';
                     o_miscInfo{end+1} = dataStruct;
                     
                     dataStruct = get_apx_tech_data_init_struct(1);
                     dataStruct.label = 'Number of bins recorded during the mission';
                     dataStruct.techId = 1002;
                     dataStruct.value = num2str(info(3));
                     dataStruct.cyNum = g_decArgo_cycleNum;
                     o_techData{end+1} = dataStruct;

                     dataStruct = get_apx_misc_data_init_struct('CTD_CP_info', [], [], []);
                     dataStruct.label = 'Highest pressure in decibars recorded during the mission';
                     dataStruct.value = info(4);
                     dataStruct.format = '%.3f';
                     o_miscInfo{end+1} = dataStruct;
                     
                     dataStruct = get_apx_tech_data_init_struct(1);
                     dataStruct.label = 'Highest pressure in decibars recorded during the mission';
                     dataStruct.techId = 1003;
                     dataStruct.value = num2str(info(4));
                     dataStruct.cyNum = g_decArgo_cycleNum;
                     o_techData{end+1} = dataStruct;

                  case 'CTD_P'
                     ctdP = [ctdP; data.(fieldName)];
                  case 'CTD_PT'
                     ctdPt = [ctdPt; data.(fieldName)];
                  case 'CTD_PTS'
                     ctdPts = [ctdPts; data.(fieldName)];
                  case 'CTD_CP'
                     ctdCp = [ctdCp; data.(fieldName)];
                  case 'O2'
                     do = [do; data.(fieldName)];
                  case 'FLBB_CD'
                     flbbCd = [flbbCd; data.(fieldName)];
                  case 'OCR_504I'
                     ocr504I = [ocr504I; data.(fieldName)];
               end
            else
               fprintf('ERROR: Float #%d Cycle #%d: Field ''%s'' not expected in file: %s => ignored (ASK FOR AN UPDATE OF THE DECODER)\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, fieldName, sciFilePathName);
            end
         end
      end
   end
end

% add cycle number to GPS fixes
if (~isempty(o_gpsData))
   o_gpsData = [ones(size(o_gpsData, 1), 1)*g_decArgo_cycleNum o_gpsData];
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
paramTemp = get_netcdf_param_attributes('TEMP');
paramTemp.cFormat = '%10.4f';
paramSal = get_netcdf_param_attributes('PSAL');
paramSal.cFormat = '%10.4f';
paramNbSample = get_netcdf_param_attributes('NB_SAMPLE');

paramO2 = get_netcdf_param_attributes('TEMP_DOXY');
paramO2.name = 'O2';
paramO2.units = '';
paramO2.cFormat = '%.5f';

paramAirSat = get_netcdf_param_attributes('TEMP_DOXY');
paramAirSat.name = 'AirSat';
paramAirSat.units = '';
paramAirSat.cFormat = '%.5f';

paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
paramTempDoxy.cFormat = '%.5f';

paramCalPhase = get_netcdf_param_attributes('TEMP_DOXY');
paramCalPhase.name = 'CalPhase';
paramCalPhase.units = '';
paramCalPhase.cFormat = '%.5f';

paramTphaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
paramTphaseDoxy.cFormat = '%.5f';

paramC1phaseDoxy = get_netcdf_param_attributes('C1PHASE_DOXY');
paramC1phaseDoxy.cFormat = '%.5f';

paramC2phaseDoxy = get_netcdf_param_attributes('C2PHASE_DOXY');
paramC2phaseDoxy.cFormat = '%.5f';

paramC1Amp = get_netcdf_param_attributes('TEMP_DOXY');
paramC1Amp.name = 'C1Amp';
paramC1Amp.units = '';
paramC1Amp.cFormat = '%.5f';

paramC2Amp = get_netcdf_param_attributes('TEMP_DOXY');
paramC2Amp.name = 'C2Amp';
paramC2Amp.units = '';
paramC2Amp.cFormat = '%.5f';

paramRawTemp = get_netcdf_param_attributes('TEMP_DOXY');
paramRawTemp.name = 'RawTemp';
paramRawTemp.units = '';
paramRawTemp.cFormat = '%.5f';

paramChlWave = get_netcdf_param_attributes('TEMP_DOXY');
paramChlWave.name = 'chl_wave';
paramChlWave.units = '';
paramChlWave.cFormat = '%d';

paramFluorescenceChla = get_netcdf_param_attributes('FLUORESCENCE_CHLA');

paramBscWave = get_netcdf_param_attributes('TEMP_DOXY');
paramBscWave.name = 'bsc_wave';
paramBscWave.units = '';
paramBscWave.cFormat = '%d';

paramBetaBackscattering700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');

paramCdWave = get_netcdf_param_attributes('TEMP_DOXY');
paramCdWave.name = 'cd_wave';
paramCdWave.units = '';
paramCdWave.cFormat = '%d';

paramFluorescenceCdom = get_netcdf_param_attributes('FLUORESCENCE_CDOM');

paramThermSig = get_netcdf_param_attributes('TEMP_DOXY');
paramThermSig.name = 'therm_sig';
paramThermSig.units = '';
paramThermSig.cFormat = '%d';

paramDownIrradiance380 = get_netcdf_param_attributes('DOWN_IRRADIANCE380');

paramDownIrradiance412 = get_netcdf_param_attributes('DOWN_IRRADIANCE412');

paramDownIrradiance490 = get_netcdf_param_attributes('DOWN_IRRADIANCE490');

paramDownwellingPar = get_netcdf_param_attributes('DOWNWELLING_PAR');

if (~isempty(ctdP))
   o_profCtdP = get_apx_profile_data_init_struct;
   o_profCtdP.dateList = paramJuld;
   o_profCtdP.dates = ctdP(:, 1);
   o_profCtdP.paramList = [paramPres];
   o_profCtdP.data = ctdP(:, 2);
end

if (~isempty(ctdPt))
   o_profCtdPt = get_apx_profile_data_init_struct;
   o_profCtdPt.dateList = paramJuld;
   o_profCtdPt.dates = ctdPt(:, 1);
   o_profCtdPt.paramList = [paramPres paramTemp];
   o_profCtdPt.data = ctdPt(:, 2:end);
end

if (~isempty(ctdPts))
   o_profCtdPts = get_apx_profile_data_init_struct;
   o_profCtdPts.dateList = paramJuld;
   o_profCtdPts.dates = ctdPts(:, 1);
   o_profCtdPts.paramList = [paramPres paramTemp paramSal];
   o_profCtdPts.data = ctdPts(:, 2:end);
end

if (~isempty(ctdCp))
   o_profCtdCp = get_apx_profile_data_init_struct;
   %    o_profCtdCp.dateList = paramJuld;
   %    o_profCtdCp.dates = ctdCp(:, 1);
   o_profCtdCp.paramList = [paramPres paramTemp paramSal paramNbSample];
   o_profCtdCp.data = ctdCp(:, 2:end);
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
end

if (~isempty(flbbCd))
   o_profFlbbCd = get_apx_profile_data_init_struct;
   o_profFlbbCd.dateList = paramJuld;
   o_profFlbbCd.dates = flbbCd(:, 1);
   o_profFlbbCd.paramList = [paramPres paramChlWave paramFluorescenceChla paramBscWave ...
      paramBetaBackscattering700 paramCdWave paramFluorescenceCdom paramThermSig];
   o_profFlbbCd.data = [ones(size(flbbCd, 1), 1)*paramPres.fillValue flbbCd(:, 2:end)];
end

if (~isempty(ocr504I))
   o_profOcr504I = get_apx_profile_data_init_struct;
   o_profOcr504I.dateList = paramJuld;
   o_profOcr504I.dates = ocr504I(:, 1);
   o_profOcr504I.paramList = [paramPres ...
      paramDownIrradiance380 paramDownIrradiance412 ...
      paramDownIrradiance490 paramDownwellingPar];
   o_profOcr504I.data = [ones(size(ocr504I, 1), 1)*paramPres.fillValue ocr504I(:, 2:end)];
end

% add PRES for DO, FLBB and OCR data
if (~isempty(o_profDo))
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
   
   if (~isempty(tabPres))
      if (~isempty(o_profDo))
         o_profDo.data(:, 1) = interp1(tabJuld, tabPres, o_profDo.dates, 'linear');
         o_profDo.data(isnan(o_profDo.data(:, 1)), 1) = paramPres.fillValue;
      end
      if (~isempty(o_profFlbbCd))
         o_profFlbbCd.data(:, 1) = interp1(tabJuld, tabPres, o_profFlbbCd.dates, 'linear');
         o_profFlbbCd.data(isnan(o_profFlbbCd.data(:, 1)), 1) = paramPres.fillValue;
      end
      if (~isempty(o_profOcr504I))
         o_profOcr504I.data(:, 1) = interp1(tabJuld, tabPres, o_profOcr504I.dates, 'linear');
         o_profOcr504I.data(isnan(o_profOcr504I.data(:, 1)), 1) = paramPres.fillValue;
      end
   end
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
end

return
