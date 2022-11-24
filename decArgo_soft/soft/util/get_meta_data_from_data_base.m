% ------------------------------------------------------------------------------
% Generate the file of float information from a data base export.
%
% SYNTAX :
%  get_meta_data_from_data_base()
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
%   08/06/2014 - RNU - creation
% ------------------------------------------------------------------------------
function get_meta_data_from_data_base()

% meta-data file exported from Coriolis data base
dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\ASFAR\DBexport_ASFAR_fromVB20151029.txt';
dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\Arvor-Cm-Bio\DBexport_arvorCM_fromVB20151030.txt';
dataBaseFileName = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\export_meta_APEX_from_VB_20150703.txt';
dataBaseFileName = 'C:\Users\jprannou\_RNU\DecNova_info\_configParamNames\NOVA_DBExport_20160226.txt';
dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\export_ARVOR_I_5-43_21060628.txt';
dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\export_4-55_20160701.txt';
dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\export_4-54_20160701.txt';
dataBaseFileName = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\DB_export_apex102015_20161006.txt';

% list of concerned floats
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_asfar.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_062608.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_061609.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_021009.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_061810.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_093008.txt';
floatListFileName = '';

% directory to store the log and csv file
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';


% create and start log file recording
logFile = [DIR_LOG_CSV_FILE '/' 'get_meta_data_from_data_base_' datestr(now, 'yyyymmddTHHMMSS') '.log'];

diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/get_meta_data_from_data_base_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   fprintf('Erreur ouverture fichier: %s\n', outputFileName);
   return;
end

header = ['Data center; Decoder version; Serial No; Cycle length (days); Parking PRES; Profile PRES; WMO #; Decoder Id; PTT #;  Frame length (bytes); Cycle length (hours); Drift sampling period (hours); DELAI parameter (hours); Launch date (yyyymmddHHMMSS); Launch longitude; Launch latitude; Day of the first descent (yyyymmdd); End decoding date; DM flag; Decoder version'];
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
for idFloat = 1:length(floatList)
   
   floatNum = floatList(idFloat);
   fprintf('%3d/%3d %d\n', idFloat, length(floatList), floatNum);
   
   idForWmo = find(metaWmoList == floatList(idFloat));
   
   idDataCenter = find(strcmp(paramCodeList(idForWmo), 'DATA_CENTRE') == 1, 1);
   dataCenter = '';
   if (~isempty(idDataCenter))
      dataCenter = paramValueList{idForWmo(idDataCenter)};
   end
   
   idPtt = find(strcmp(paramCodeList(idForWmo), 'PTT') == 1, 1);
   ptt = '';
   if (~isempty(idPtt))
      ptt = paramValueList{idForWmo(idPtt)};
   else
      idPtt = find(strcmp(paramCodeList(idForWmo), 'IMEI') == 1, 1);
      if (~isempty(idPtt))
         ptt = paramValueList{idForWmo(idPtt)};
      end
   end
   
   idSerialNum = find(strcmp(paramCodeList(idForWmo), 'INST_REFERENCE') == 1, 1);
   serialNum = '';
   if (~isempty(idSerialNum))
      serialNum = paramValueList{idForWmo(idSerialNum)};
   end
   
   idCycleTime = find(strcmp(paramCodeList(idForWmo), 'CYCLE_TIME') == 1, 1);
   cycleTime = '';
   if (~isempty(idCycleTime))
      cycleTime = paramValueList{idForWmo(idCycleTime)};
   end
   
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
   
   idDriftPeriod = find(strcmp(paramCodeList(idForWmo), 'PR_IMMERSION_DRIFT_PERIOD') == 1, 1);
   driftPeriod = '';
   if (~isempty(idDriftPeriod))
      if (~strcmp(paramValueList{idForWmo(idDriftPeriod)}, '999') && ...
            ~strcmp(paramValueList{idForWmo(idDriftPeriod)}, '9999'))
         driftPeriod = paramValueList{idForWmo(idDriftPeriod)};
         driftPeriod = num2str(str2num(driftPeriod)/60);
      end
   end
   
   idLaunchDate = find(strcmp(paramCodeList(idForWmo), 'PR_LAUNCH_DATETIME') == 1, 1);
   launchDate = '';
   dayFirstDesc = '';
   if (~isempty(idLaunchDate))
      launchDate = paramValueList{idForWmo(idLaunchDate)};
      launchDate = datestr(datenum(launchDate, 'dd/mm/yyyy HH:MM:SS'), 'yyyymmddHHMMSS');
      dayFirstDesc = launchDate(1:8);
   end
   
   idLaunchLon = find(strcmp(paramCodeList(idForWmo), 'PR_LAUNCH_LONGITUDE') == 1, 1);
   launchLon = '';
   if (~isempty(idLaunchLon))
      launchLon = paramValueList{idForWmo(idLaunchLon)};
      launchLon = num2str(fix(str2num(launchLon)*1000)/1000);
   end
   
   idLaunchLat = find(strcmp(paramCodeList(idForWmo), 'PR_LAUNCH_LATITUDE') == 1, 1);
   launchLat = '';
   if (~isempty(idLaunchLat))
      launchLat = paramValueList{idForWmo(idLaunchLat)};
      launchLat = num2str(fix(str2num(launchLat)*1000)/1000);
   end
   
   idCoVersion = find(strcmp(paramCodeList(idForWmo), 'PR_VERSION') == 1, 1);
   coVersion = '';
   if (~isempty(idCoVersion))
      coVersion = paramValueList{idForWmo(idCoVersion)};
   end
   
   fprintf(fidOut, '%s; %s; %s; %g; %s; %s; %d; ; %s; 31; %s; %s; -1; %s; %s; %s; %s; 99999999999999; 0; %s\n', ...
      dataCenter, coVersion, serialNum, str2num(cycleTime)/24, parkPres, profPres, ...
      floatNum, ptt, cycleTime, driftPeriod, launchDate, launchLon, launchLat, dayFirstDesc, coVersion);
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

fclose(fidOut);

diary off;

return;
