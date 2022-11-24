% ------------------------------------------------------------------------------
% Generate the file of float information from a data base export.
% Similar to get_meta_data_from_data_base with additionnal information + output
% information are sorted by 1: transSystem, 2: co version.
%
% SYNTAX :
%  get_meta_data_from_data_base_bis()
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/06/2015 - RNU - creation
% ------------------------------------------------------------------------------
function get_meta_data_from_data_base_bis()

% meta-data file exported from Coriolis data base
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\ASFAR\DBexport_ASFAR_fromVB20151029.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecNemo_info\_configParamNames\nemo_DB_export_from_VB_20160818.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\apex_DB_export_fromVB_20160817_20160823.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\exportJPR_5900A04_from_VB_20170825.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\exportJPR_ArvorDeep_from_VB_20170825.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_IR\DB_export_Finland_From_VB_20180904.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecNemo_info\_configParamNames\DB_export_NEMO_from_VB_20170911.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\APMT\CTS5_float_config\DB_export_CTS5_from_VB_20170912.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_IR_SBD\DB_Export_APEX_Poland_from_vb_20171020.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_IR_SBD\DB_Export_APEX_Poland_from_vb_20171020.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DBexport_DeepIce_5.65_from_VB_20171005.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecNova_info\_configParamNames\DB_export_Nova_from_VB_20171121.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\APMT\CTS5_float_config\DB_export_pH_Float.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecNova_info\_configParamNames\DB_export_Nova_historiques_allemands_et_grecs_from_vb_20180201.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_export_DeepIce_5.65_20180201.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\db_export-3902101_Arvor-Ir-Do_5.46_from_VB_20180216.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_export_BioAtlantos_from_VB_20180222.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DBexport_BioIndia_6.11_from_VB_20180308.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_export_BioAtlantos_lot2_from_VB_20180319.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_APF11\Argos\DB_export_APF11_Argos_from_VB_20171204.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_APF11\Iridium\DB_export_APF11_Iridium-SBD_from_VB_20180410.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_APF11\Argos\DB_export_APF11_Argos_lot2&3_from_VB_20180514.txt';
dataBaseFileName = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_APF11\Iridium\DB_export_APEX_APF11Bio_frm_VB_20180615.txt';

% list of concerned floats
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_asfar.txt';
floatListFileName = '';
% floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nemo_collecte_v2.txt';

% directory to store the log and csv file
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';


% create and start log file recording
logFile = [DIR_LOG_CSV_FILE '/' 'get_meta_data_from_data_base_bis_' datestr(now, 'yyyymmddTHHMMSS') '.log'];

diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/get_meta_data_from_data_base_bis_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   fprintf('Erreur ouverture fichier: %s\n', outputFileName);
   return;
end

header = ['Trans system; Activity flag; Data center; Decoder version; Serial No; Cycle length (days); Parking PRES; Profile PRES; WMO #; Decoder Id; PTT #;  Frame length (bytes); Cycle length (hours); Drift sampling period (hours); DELAI parameter (hours); Launch date (yyyymmddHHMMSS); Launch longitude; Launch latitude; Day of the first descent (yyyymmdd); End decoding date; DM flag; Decoder version'];
fprintf(fidOut, '%s\n', header);

% read meta file
fprintf('Processing file: %s\n', dataBaseFileName);
fId = fopen(dataBaseFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', dataBaseFileName);
   return;
end
metaFileContents = textscan(fId, '%s', 'delimiter', '\t');
metaFileContents = metaFileContents{:};
fclose(fId);

metaFileContents = regexprep(metaFileContents, '"', '');

metaData = reshape(metaFileContents, 5, size(metaFileContents, 1)/5)';

metaWmoList = metaData(:, 1);
for id = 1:length(metaWmoList)
   if (isempty(str2num(metaWmoList{id})))
      fprintf('%s is not a valid WMO number\n', metaWmoList{id});
      return;
   end
end
S = sprintf('%s*', metaWmoList{:});
metaWmoList = sscanf(S, '%f*');
metaFloatList = unique(metaWmoList);

paramCodeList = metaData(:, 5);
paramValueList = metaData(:, 4);

% create the list of floats to process
if (~isempty(floatListFileName))
   fprintf('Floats from list: %s\n', floatListFileName);
   floatList = textread(floatListFileName, '%d');
else
   floatList = sort(metaFloatList);
end

% process the floats
tabFloatNum = [];
tabTransSystem = [];
tabActivity = [];
tabDataCenter = [];
tabPtt = [];
tabSerialNum = [];
tabCycleTime = [];
tabParkPres = [];
tabProfPres = [];
tabDriftPeriod = [];
tabLaunchDate = [];
tabDayFirstDesc = [];
tabLaunchLon = [];
tabLaunchLat = [];
tabCoVersion = [];
for idFloat = 1:length(floatList)
   
   floatNum = floatList(idFloat);
   tabFloatNum{end+1} = floatNum;
   
   fprintf('%3d/%3d %d\n', idFloat, length(floatList), floatNum);
   
   idForWmo = find(metaWmoList == floatList(idFloat));
   
   idTransSystem = find(strcmp(paramCodeList(idForWmo), 'TRANS_SYSTEM') == 1, 1);
   transSystem = '';
   if (~isempty(idTransSystem))
      transSystem = paramValueList{idForWmo(idTransSystem)};
   end
   tabTransSystem{end+1} = transSystem;
   
   idActivityFlag = find(strcmp(paramCodeList(idForWmo), 'PF_ACTIVITY_FLAG') == 1, 1);
   activityFlag = '';
   if (~isempty(idActivityFlag))
      activityFlag = paramValueList{idForWmo(idActivityFlag)};
   end
   tabActivity{end+1} = activityFlag;

   idDataCenter = find(strcmp(paramCodeList(idForWmo), 'DATA_CENTRE') == 1, 1);
   dataCenter = '';
   if (~isempty(idDataCenter))
      dataCenter = paramValueList{idForWmo(idDataCenter)};
   end
   tabDataCenter{end+1} = dataCenter;

   idPtt = find(strcmp(paramCodeList(idForWmo), 'PTT') == 1, 1);
   ptt = '';
   if (~isempty(idPtt))
      ptt = paramValueList{idForWmo(idPtt)};
   end
   tabPtt{end+1} = ptt;

   idSerialNum = find(strcmp(paramCodeList(idForWmo), 'INST_REFERENCE') == 1, 1);
   serialNum = '';
   if (~isempty(idSerialNum))
      serialNum = paramValueList{idForWmo(idSerialNum)};
   end
   tabSerialNum{end+1} = serialNum;

   idCycleTime = find(strcmp(paramCodeList(idForWmo), 'CYCLE_TIME') == 1, 1);
   cycleTime = '';
   if (~isempty(idCycleTime))
      cycleTime = paramValueList{idForWmo(idCycleTime)};
   end
   tabCycleTime{end+1} = cycleTime;

   idParkPres = find(strcmp(paramCodeList(idForWmo), 'PARKING_PRESSURE') == 1, 1);
   parkPres = '';
   if (~isempty(idParkPres))
      if (length(idParkPres) > 1)
         parkPresList = [];
         for id = 1:length(idParkPres)
            parkPresList(end+1) = str2num(paramValueList{idForWmo(idParkPres(id))});
         end
         parkPresList = unique(parkPresList);
         parkPres = sprintf('%g ', parkPresList);
      else
         parkPres = paramValueList{idForWmo(idParkPres)};
      end
   end
   tabParkPres{end+1} = parkPres;

   idProfPres = find(strcmp(paramCodeList(idForWmo), 'DEEPEST_PRESSURE') == 1, 1);
   profPres = '';
   if (~isempty(idProfPres))
      if (length(idProfPres) > 1)
         profPresList = [];
         for id = 1:length(idProfPres)
            profPresList(end+1) = str2num(paramValueList{idForWmo(idProfPres(id))});
         end
         profPresList = unique(profPresList);
         profPres = sprintf('%g ', profPresList);
      else
         profPres = paramValueList{idForWmo(idProfPres)};
      end
   end
   tabProfPres{end+1} = profPres;
   
   idDriftPeriod = find(strcmp(paramCodeList(idForWmo), 'PR_IMMERSION_DRIFT_PERIOD') == 1, 1);
   driftPeriod = '';
   if (~isempty(idDriftPeriod))
      if (~strcmp(paramValueList{idForWmo(idDriftPeriod)}, '999') && ...
            ~strcmp(paramValueList{idForWmo(idDriftPeriod)}, '9999'))
         driftPeriod = paramValueList{idForWmo(idDriftPeriod)};
         driftPeriod = num2str(str2num(driftPeriod)/60);
      end
   end
   tabDriftPeriod{end+1} = driftPeriod;

   idLaunchDate = find(strcmp(paramCodeList(idForWmo), 'PR_LAUNCH_DATETIME') == 1, 1);
   launchDate = '';
   dayFirstDesc = '';
   if (~isempty(idLaunchDate))
      launchDate = paramValueList{idForWmo(idLaunchDate)};
      launchDate = datestr(datenum(launchDate, 'dd/mm/yyyy HH:MM:SS'), 'yyyymmddHHMMSS');
      dayFirstDesc = launchDate(1:8);
   end
   tabLaunchDate{end+1} = launchDate;
   tabDayFirstDesc{end+1} = dayFirstDesc;

   idLaunchLon = find(strcmp(paramCodeList(idForWmo), 'PR_LAUNCH_LONGITUDE') == 1, 1);
   launchLon = '';
   if (~isempty(idLaunchLon))
      launchLon = paramValueList{idForWmo(idLaunchLon)};
      launchLon = num2str(fix(str2num(launchLon)*1000)/1000);
   end
   tabLaunchLon{end+1} = launchLon;

   idLaunchLat = find(strcmp(paramCodeList(idForWmo), 'PR_LAUNCH_LATITUDE') == 1, 1);
   launchLat = '';
   if (~isempty(idLaunchLat))
      launchLat = paramValueList{idForWmo(idLaunchLat)};
      launchLat = num2str(fix(str2num(launchLat)*1000)/1000);
   end
   tabLaunchLat{end+1} = launchLat;

   idCoVersion = find(strcmp(paramCodeList(idForWmo), 'PR_VERSION') == 1, 1);
   coVersion = '';
   if (~isempty(idCoVersion))
      coVersion = paramValueList{idForWmo(idCoVersion)};
   end
   tabCoVersion{end+1} = coVersion;
   
end
   
% sort the collected data
refTransSystem = sort(unique(tabTransSystem));
refCoVersion = sort(unique(tabCoVersion));
for idTS = 1:length(refTransSystem)
   for idCV = 1:length(refCoVersion)
      idF = find((strcmp(tabTransSystem, refTransSystem{idTS}) == 1) & ...
         (strcmp(tabCoVersion, refCoVersion{idCV}) == 1));
      [~, idSort] = sort([tabFloatNum{idF}]);
      tabFloatNum(idF) = tabFloatNum(idF(idSort));
      tabTransSystem(idF) = tabTransSystem(idF(idSort));
      tabActivity(idF) = tabActivity(idF(idSort));
      tabDataCenter(idF) = tabDataCenter(idF(idSort));
      tabPtt(idF) = tabPtt(idF(idSort));
      tabSerialNum(idF) = tabSerialNum(idF(idSort));
      tabCycleTime(idF) = tabCycleTime(idF(idSort));
      tabParkPres(idF) = tabParkPres(idF(idSort));
      tabProfPres(idF) = tabProfPres(idF(idSort));
      tabDriftPeriod(idF) = tabDriftPeriod(idF(idSort));
      tabLaunchDate(idF) = tabLaunchDate(idF(idSort));
      tabDayFirstDesc(idF) = tabDayFirstDesc(idF(idSort));
      tabLaunchLon(idF) = tabLaunchLon(idF(idSort));
      tabLaunchLat(idF) = tabLaunchLat(idF(idSort));
      tabCoVersion(idF) = tabCoVersion(idF(idSort));
      
      for idL = 1:length(idF)
         id = idF(idL);
         fprintf(fidOut, '%s; %s; %s;''%s; %s; %g; %s; %s; %d; ; %s; 31; %s; %s; -1; %s; %s; %s; %s; 99999999999999; 0; %s\n', ...
            tabTransSystem{id}, tabActivity{id}, tabDataCenter{id}, tabCoVersion{id}, tabSerialNum{id}, ...
            str2num(tabCycleTime{id})/24, tabParkPres{id}, tabProfPres{id}, ...
            tabFloatNum{id}, tabPtt{id}, tabCycleTime{id}, tabDriftPeriod{id}, ...
            tabLaunchDate{id}, tabLaunchLon{id}, tabLaunchLat{id}, ...
            tabDayFirstDesc{id}, tabCoVersion{id});
      end
   end
end
   
% for id = 1:length(tabFloatNum)
%    fprintf(fidOut, '%s; %s; ''%s; %s; %g; %s; %s; %d; ; %s; 31; %s; %s; -1; %s; %s; %s; %s; 99999999999999; 0; %s\n', ...
%       tabActivity{id}, tabDataCenter{id}, tabCoVersion{id}, tabSerialNum{id}, ...
%       str2num(tabCycleTime{id})/24, tabParkPres{id}, tabProfPres{id}, ...
%       tabFloatNum{id}, tabPtt{id}, tabCycleTime{id}, tabDriftPeriod{id}, ...
%       tabLaunchDate{id}, tabLaunchLon{id}, tabLaunchLat{id}, ...
%       tabDayFirstDesc{id}, tabCoVersion{id});
% end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

fclose(fidOut);

diary off;

return;
