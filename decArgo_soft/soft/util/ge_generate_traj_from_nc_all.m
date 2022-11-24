% ------------------------------------------------------------------------------
% Génération d'un fichier GE de trajectoire d'un flotteur à partir des données
% du fichier _traj.nc.
% Similaire à ge_generate_traj_from_nc mais ici on considère également les
% positions Iridium.
%
% SYNTAX :
%   ge_generate_traj_from_nc_all ou ge_generate_traj_from_nc_all(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : éventuellement la liste des numéros de flotteurs à traiter
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/31/2022 - RNU - creation
% ------------------------------------------------------------------------------
function ge_generate_traj_from_nc_all(varargin)

global g_dateDef;
global g_MC_Launch;
global g_MC_Surface;

% default values initialization
init_default_values;

% initialisation des valeurs par défaut
init_valdef;

% initialisation des MC
init_measurement_codes;


% flag d'exclusion des localisations Argos/Gps du fichier GE généré
ARGOS_GPS_LOC_FLAG = 1;

% flag d'exclusion des localisations Iridium du fichier GE généré
IRIDIUM_LOC_FLAG = 1;

% liste des flotteurs à considérer
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11_iridium-rudics_2.13.1.txt';

% répertoire des fichiers NetCDF
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';

% répertoire de production des fichier KML
DIR_OUTPUT_KML_FILES = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% répertoire de stockage des répertoires temporaires
DIR_TMP_FILES = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';


% convertion des dates julienes 1950 en dates grégoriennes
referenceDateStr = '1950-01-01 00:00:00';
referenceDate = datenum(referenceDateStr, 'yyyy-mm-dd HH:MM:SS');

if (nargin == 0)
   % les flotteurs pris en compte sont ceux d'une liste prédéfinie
   if (~exist(FLOAT_LIST_FILE_NAME, 'file'))
      fprintf('Fichier introuvable: %s\n', FLOAT_LIST_FILE_NAME);
      return
   end

   fprintf('Flotteurs de la liste: %s\n', FLOAT_LIST_FILE_NAME);
   floatList = textread(FLOAT_LIST_FILE_NAME, '%d');
else
   % les flotteurs pris en compte sont ceux fournis en paramètre
   floatList = cell2mat(varargin);
end

% création du répertoire temporaire de stockage du code kml
ident = datestr(now, 'yyyymmddTHHMMSS');
tmpDirName = [DIR_TMP_FILES sprintf('tmp%s', ident)];
if (~exist(tmpDirName, 'dir'))
   mkdir(tmpDirName);
else
   fprintf('Répertoire temporaire (%s) existe déjà: STOP\n', tmpDirName);
   return
end

% fichiers temporaires de stockage
outputTempLaunchFileName = [tmpDirName '/' 'ge_generate_traj_from_nc_all_LAUNCH'];
outputTempLocFileName = [tmpDirName '/' 'ge_generate_traj_from_nc_all_LOC'];
outputTempLocIrFileName = [tmpDirName '/' 'ge_generate_traj_ir_from_nc_all_LOC'];
outputTempTrajFileName = [tmpDirName '/' 'ge_generate_traj_from_nc_all_TRAJ'];
outputTempTrajIrFileName = [tmpDirName '/' 'ge_generate_traj_ir_from_nc_all_TRAJ'];

% création et ouverture du fichier de sortie
if (nargin == 0)
   [pathstr, name, ext] = fileparts(FLOAT_LIST_FILE_NAME);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

kmlFileName = ['ge_generate_traj_from_nc_all' name '_CEP_MIN_AVG_' ident '.kml'];
kmzFileName = [kmlFileName(1:end-4) '.kmz'];
outputFileName = [DIR_OUTPUT_KML_FILES kmlFileName];

fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   fprintf('Impossible de créer le fichier %s\n', outputFileName);
   return
end

% écriture de l'entête du fichier kml
description = 'Trajectory generated with traj.nc files contents';
ge_put_header1(fidOut, description, kmlFileName);

% traitement des flotteurs
nbFloats = length(floatList);
for idFloat = 1:nbFloats

   % variable de stockage du code kml
   kmlStrLaunch = [];
   kmlStrLoc = [];
   kmlStrLocIr = [];
   kmlStrTraj = [];
   kmlStrTrajIr = [];

   floatNumStr = num2str(floatList(idFloat));
   fprintf('\n%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % lecture du contenu du fichier de meta données
   metaFileName = [DIR_INPUT_NC_FILES '/' floatNumStr '/' floatNumStr '_meta.nc'];
   
   if ~(exist(metaFileName, 'file') == 2)
      fprintf('\n');
      fprintf('Fichier introuvable: %s\n', metaFileName);
   end
   
   % retrieve information from META file
   wantedVars = [ ...
      {'FORMAT_VERSION'} ...
      {'PLATFORM_NUMBER'} ...
      {'PTT'} ...
      {'TRANS_SYSTEM'} ...
      {'POSITIONING_SYSTEM'} ...
      {'PLATFORM_TYPE'} ...
      {'FLOAT_SERIAL_NO'} ...
      {'DAC_FORMAT_ID'} ...
      {'PROJECT_NAME'} ...
      {'DATA_CENTRE'} ...
      {'PI_NAME'} ...
      {'LAUNCH_DATE'} ...
      {'LAUNCH_LATITUDE'} ...
      {'LAUNCH_LONGITUDE'} ...
      ];
   [metaData] = get_data_from_nc_file(metaFileName, wantedVars);
   
   idVal = find(strcmp('FORMAT_VERSION', metaData(1:2:end)) == 1, 1);
   metaFileFormatVersion = strtrim(metaData{2*idVal}');
   
   % contrôle de la version
   if (~strcmp(metaFileFormatVersion, '3.1'))
      fprintf('\n');
      fprintf('ERROR: Fichier de meta-données (%s) attendu en version 3.1 (mais FORMAT_VERSION = %s)\n', ...
         metaFileName, metaFileFormatVersion);
      return
   end   
   
   metaStruct = [];
   for id = 2:length(wantedVars)
      idVal = find(strcmp(wantedVars{id}, metaData(1:2:end)) == 1, 1);
      value = metaData{2*idVal};
      if (ischar(value))
         value = strtrim(value');
         if (size(value, 1) > 1)
            value2 = strtrim(value(1, :));
            for id2 = 2:size(value, 1)
               value2 = [value2 '/' strtrim(value(id2, :))];
            end
            value = value2;
         end
         metaStruct.(wantedVars{id}) = value;
      else
         metaStruct.(wantedVars{id}) = num2str(value);
      end
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % from TRAJ file
   trajFileName = [DIR_INPUT_NC_FILES '/' floatNumStr '/' floatNumStr '_Rtraj.nc'];

   if ~(exist(trajFileName, 'file') == 2)
      fprintf('\n');
      fprintf('Fichier introuvable: %s\n', trajFileName);
   end
   
   % retrieve information from TRAJ file
   wantedVars = [ ...
      {'FORMAT_VERSION'} ...
      {'JULD'} ...
      {'JULD_ADJUSTED'} ...
      {'CYCLE_NUMBER'} ...
      {'MEASUREMENT_CODE'} ...
      {'LATITUDE'} ...
      {'LONGITUDE'} ...
      {'POSITION_ACCURACY'} ...
      {'POSITION_QC'} ...
      {'AXES_ERROR_ELLIPSE_MAJOR'} ...
      {'AXES_ERROR_ELLIPSE_MINOR'} ...
      ];
   [trajData] = get_data_from_nc_file(trajFileName, wantedVars);
      
   idVal = find(strcmp('FORMAT_VERSION', trajData(1:2:end)) == 1, 1);
   formatVersion = strtrim(trajData{2*idVal}');
   
   % contrôle de la version
   if (~ismember(formatVersion, [{'3.1'} {'3.2'}]))
      fprintf('\n');
      fprintf('ERROR: Fichier de trajectoire (%s) attendu en version 3.1 (mais FORMAT_VERSION = %s)\n', ...
         trajFileName, formatVersion);
      return
   end
   
   idVal = find(strcmp('CYCLE_NUMBER', trajData(1:2:end)) == 1, 1);
   cycleNumber = trajData{2*idVal};
   
   idVal = find(strcmp('MEASUREMENT_CODE', trajData(1:2:end)) == 1, 1);
   measCode = trajData{2*idVal};
   
   idVal = find(strcmp('JULD', trajData(1:2:end)) == 1, 1);
   juld = trajData{2*idVal};
   
   idVal = find(strcmp('JULD_ADJUSTED', trajData(1:2:end)) == 1, 1);
   juldAdj = trajData{2*idVal};
   
   idVal = find(strcmp('LATITUDE', trajData(1:2:end)) == 1, 1);
   latitude = trajData{2*idVal};
   
   idVal = find(strcmp('LONGITUDE', trajData(1:2:end)) == 1, 1);
   longitude = trajData{2*idVal};
   
   idVal = find(strcmp('POSITION_ACCURACY', trajData(1:2:end)) == 1, 1);
   positionAccuracy = trajData{2*idVal};
   
   idVal = find(strcmp('POSITION_QC', trajData(1:2:end)) == 1, 1);
   positionQC = trajData{2*idVal};
   
   idVal = find(strcmp('AXES_ERROR_ELLIPSE_MAJOR', trajData(1:2:end)) == 1, 1);
   errorEllipseMaj = trajData{2*idVal};
   
   idVal = find(strcmp('AXES_ERROR_ELLIPSE_MINOR', trajData(1:2:end)) == 1, 1);
   errorEllipseMin = trajData{2*idVal};

   % merge JULD et JULD_ADJUSTED
   idF = find(juldAdj ~= 999999);
   juld(idF) = juldAdj(idF);
   juld(find(juld == 999999)) = g_dateDef;

   % date de lâcher
   launchDateJuld = g_dateDef;
   idF = find(measCode == g_MC_Launch);
   if (~isempty(idF))
      launchDateJuld = juld(idF);
      launchLatitudeMeta = latitude(idF);
      launchLongitudeMeta = longitude(idF);
   end

   % selection des positions Iridium
   cycleNumberIr = [];
   juldIr = [];
   latitudeIr = [];
   longitudeIr = [];
   positionAccuracyIr = [];
   idF = find((measCode == g_MC_Surface) & (positionAccuracy == 'I'));
   if (~isempty(idF))
      cycleNumberIr = cycleNumber(idF);
      juldIr = juld(idF);
      latitudeIr = latitude(idF);
      longitudeIr = longitude(idF);
      positionAccuracyIr = positionAccuracy(idF);
      errorEllipseMajIr = errorEllipseMaj(idF);
   end

   % on ne conserve que les positions Argos/Gps du fichier trajectoires
   % (i.e. celles qui ont une localisation)
   idF = find((measCode == g_MC_Surface) & (positionAccuracy ~= 'I'));
   if (~isempty(idF))
      cycleNumber = cycleNumber(idF);
      juld = juld(idF);
      latitude = latitude(idF);
      longitude = longitude(idF);
      positionAccuracy = positionAccuracy(idF);
      positionQC = positionQC(idF);
   end

   % sélection des cycles
   % sélection des positions Argos de qualité
   %    idGoodPos = find( ...
   %       (positionAccuracy == '1') | ...
   %       (positionAccuracy == '2') | ...
   %       (positionAccuracy == '3') | ...
   %       (positionAccuracy == 'G') | ...
   %       (positionQC == '1') | ...
   %       (positionQC == '2'));
   %    cycleNumber = cycleNumber(idGoodPos);
   %    juld = juld(idGoodPos);
   %    longitude = longitude(idGoodPos);
   %    latitude = latitude(idGoodPos);
   %    positionAccuracy = positionAccuracy(idGoodPos);

   % position de lâcher du flotteur
   if (launchDateJuld ~= g_dateDef)
      prevDate = launchDateJuld;
   else
      prevDate = min(juld);
   end

   labelList = fieldnames(metaStruct);
   valueList = struct2cell(metaStruct);
   launchDescription = '';
   for id = 1:length(labelList)
      launchDescription = [launchDescription ...
         sprintf('%s: %s\n', labelList{id}, valueList{id})];
   end      

   timeSpanStart = datestr(prevDate+referenceDate, 'yyyy-mm-ddTHH:MM:SSZ');

   kmlStrLaunch = [kmlStrLaunch, ge_create_pos(launchLongitudeMeta, launchLatitudeMeta, ...
      launchDescription, floatNumStr, '#CUR_LAUNCH_POS', timeSpanStart, '')];

   prevLon = launchLongitudeMeta;
   prevLat = launchLatitudeMeta;

   kmlStrLoc = [kmlStrLoc, ...
      9, '<Folder>', 10, ...
      9, 9, '<name>', floatNumStr, '</name>', 10, ...
      ];

   kmlStrLocIr = [kmlStrLocIr, ...
      9, '<Folder>', 10, ...
      9, 9, '<name>', floatNumStr, '</name>', 10, ...
      ];

   kmlStrTrajIr = [kmlStrTrajIr, ...
      9, '<Folder>', 10, ...
      9, 9, '<name>', floatNumStr, '</name>', 10, ...
      ];
   
   kmlStrTraj = [kmlStrTraj, ...
      9, '<Folder>', 10, ...
      9, 9, '<name>', floatNumStr, '</name>', 10, ...
      ];

   % traitement des cycles (positions Argos/Gps)
   cycleNumbers = unique(cycleNumber);
   nbCycle = length(cycleNumbers);
   for idCycle = 1:nbCycle
      cycleNum = cycleNumbers(idCycle);

      idCy = find(cycleNumber == cycleNum);
      juldCy = juld(idCy);
      longitudeCy = longitude(idCy);
      latitudeCy = latitude(idCy);
      positionAccuracyCy = positionAccuracy(idCy);

      if (~isempty(juldCy))

         % POSITIONS ARGOS
         
         if (ARGOS_GPS_LOC_FLAG == 1)

            kmlStrLoc = [kmlStrLoc, ...
               9, '<Folder>', 10, ...
               9, 9, '<name>', sprintf('cycle %d', cycleNum), '</name>', 10, ...
               ];

            nbPos = length(juldCy);
            for idPos = 1:nbPos
               argosPosDescription = [];
               argosPosDescription = [argosPosDescription, ...
                  sprintf('POSITION (lon, lat): %8.3f, %7.3f\n', longitudeCy(idPos), latitudeCy(idPos))];
               argosPosDescription = [argosPosDescription, ...
                  sprintf('DATE               : %s\n', julian_2_gregorian_dec_argo(juldCy(idPos)))];
               argosPosDescription = [argosPosDescription, ...
                  sprintf('LOC CLASS          : %c\n', positionAccuracyCy(idPos))];

               timeSpanStart = datestr(juldCy(idPos)+referenceDate, 'yyyy-mm-ddTHH:MM:SSZ');

               kmlStrLoc = [kmlStrLoc, ge_create_pos( ...
                  longitudeCy(idPos), latitudeCy(idPos), ...
                  argosPosDescription, ...
                  sprintf('%d_%d', cycleNum, idPos), ...
                  sprintf('#CUR_ARGOS_POS_%c', positionAccuracyCy(idPos)), ...
                  timeSpanStart, '')];
            end

            kmlStrLoc = [kmlStrLoc, ...
               9, '</Folder>', 10, ...
               ];
         end
         
         % TRAJECTOIRE ARGOS

         kmlStrTraj = [kmlStrTraj, ...
            9, '<Folder>', 10, ...
            9, 9, '<name>', sprintf('cycle %d', cycleNum), '</name>', 10, ...
            ];

         argosLineDescription = '';
         timeSpanStart = datestr(juldCy(1)+referenceDate, 'yyyy-mm-ddTHH:MM:SSZ');
         kmlStrTraj = [kmlStrTraj, ge_create_line( ...
            longitudeCy, latitudeCy, ...
            argosLineDescription, ...
            '', ...
            '#CUR_ARGOS_TRAJ', ...
            timeSpanStart, '')];

         % DEPLACEMENT
         lonArrow(1) = prevLon;
         latArrow(1) = prevLat;
         lonArrow(2) = longitudeCy(1);
         latArrow(2) = latitudeCy(1);

         dispDescription = '';
         timeSpanStart = datestr(prevDate+referenceDate, 'yyyy-mm-ddTHH:MM:SSZ');
         timeSpanEnd = datestr(juldCy(1)+referenceDate, 'yyyy-mm-ddTHH:MM:SSZ');
         
         kmlStrTraj = [kmlStrTraj, ...
            ge_create_arrow( ...
            lonArrow, latArrow, dispDescription, ...
            '#CUR_DISP', '#OLD_DISP', ...
            timeSpanStart, timeSpanEnd)];

         kmlStrTraj = [kmlStrTraj, ...
            9, '</Folder>', 10, ...
            ];

         prevLon = longitudeCy(end);
         prevLat = latitudeCy(end);
         prevDate = juldCy(end);
      end
   end

   % traitement des cycles (positions Iridium)
   if (IRIDIUM_LOC_FLAG == 1)

      prevLon = launchLongitudeMeta;
      prevLat = launchLatitudeMeta;

      cycleNumbersIr = unique(cycleNumberIr);
      nbCycle = length(cycleNumbersIr);
      for idCycle = 1:nbCycle
         cycleNum = cycleNumbersIr(idCycle);

         idCy = find(cycleNumberIr == cycleNum);
         juldCy = juldIr(idCy);
         longitudeCy = longitudeIr(idCy);
         latitudeCy = latitudeIr(idCy);
         positionAccuracyCy = positionAccuracyIr(idCy);
         errorEllipseMajCy = errorEllipseMajIr(idCy);

         if (~isempty(juldCy))

            % réduction du nombre de positions Iridium

            %             % suppression des doublons (lon, lat)
            %             locTab = [juldCy longitudeCy latitudeCy double(errorEllipseMajCy)];
            %             uLocTab = unique(locTab(:, [2 3]), 'rows', 'stable');
            %             idOk = [];
            %             for idLoc = 1:size(uLocTab, 1)
            %                idL = find((locTab(:, 2) == uLocTab(idLoc, 1)) & (locTab(:, 3) == uLocTab(idLoc, 2)));
            %                minCep = min(locTab(idL, 4));
            %                idL2 = find(locTab(idL, 4) == minCep);
            %                minDate = min(locTab(idL(idL2), 1));
            %                idL3 = find(locTab(idL(idL2), 1) == minDate);
            %                idOk = [idOk idL(idL2(idL3))];
            %             end
            %
            %             juldCy = juldCy(idOk);
            %             longitudeCy = longitudeCy(idOk);
            %             latitudeCy = latitudeCy(idOk);
            %             errorEllipseMajCy = errorEllipseMajCy(idOk);

            % on ne garde que les positions avec le CEP min
            minCep = min(errorEllipseMajCy);
            idOk = find(errorEllipseMajCy == minCep);
            juldCy = juldCy(idOk);
            longitudeCy = longitudeCy(idOk);
            latitudeCy = latitudeCy(idOk);
            errorEllipseMajCy = errorEllipseMajCy(idOk);

            % on effectue une moyenne pondérée des positions
            weight = 1./(errorEllipseMajCy.*errorEllipseMajCy);
            juldCy = mean(juldCy);
            longitudeCy = sum(longitudeCy.*weight)/sum(weight);
            latitudeCy = sum(latitudeCy.*weight)/sum(weight);
            errorEllipseMajCy = errorEllipseMajCy(1);

            % POSITIONS Iridium

            kmlStrLocIr = [kmlStrLocIr, ...
               9, '<Folder>', 10, ...
               9, 9, '<name>', sprintf('cycle %d', cycleNum), '</name>', 10, ...
               ];

            nbPos = length(juldCy);
            for idPos = 1:nbPos
               irPosDescription = [];
               irPosDescription = [irPosDescription, ...
                  sprintf('POSITION (lon, lat): %8.3f, %7.3f\n', longitudeCy(idPos), latitudeCy(idPos))];
               irPosDescription = [irPosDescription, ...
                  sprintf('DATE               : %s\n', julian_2_gregorian_dec_argo(juldCy(idPos)))];
               irPosDescription = [irPosDescription, ...
                  sprintf('LOC CLASS          : I\n')];
               irPosDescription = [irPosDescription, ...
                  sprintf('CEP RADIUS (km)    : %d\n', errorEllipseMajCy(idPos)/1000)];

               timeSpanStart = datestr(juldCy(idPos)+referenceDate, 'yyyy-mm-ddTHH:MM:SSZ');

               kmlStrLocIr = [kmlStrLocIr, ge_create_pos( ...
                  longitudeCy(idPos), latitudeCy(idPos), ...
                  irPosDescription, ...
                  sprintf('%d_%d (%d)', cycleNum, idPos, errorEllipseMajCy(idPos)/1000), ...
                  sprintf('#CUR_ARGOS_POS_%c', positionAccuracyCy(idPos)), ...
                  timeSpanStart, '')];
            end

            kmlStrLocIr = [kmlStrLocIr, ...
               9, '</Folder>', 10, ...
               ];

            % TRAJECTOIRE Iridium

            kmlStrTrajIr = [kmlStrTrajIr, ...
               9, '<Folder>', 10, ...
               9, 9, '<name>', sprintf('cycle %d', cycleNum), '</name>', 10, ...
               ];

            argosLineDescription = '';
            timeSpanStart = datestr(juldCy(1)+referenceDate, 'yyyy-mm-ddTHH:MM:SSZ');
            kmlStrTrajIr = [kmlStrTrajIr, ge_create_line2( ...
               longitudeCy, latitudeCy, ...
               argosLineDescription, ...
               '', ...
               '0', ...
               '#CUR_IRIDIUM_TRAJ', ...
               timeSpanStart, '')];

            % DEPLACEMENT
            lonArrow(1) = prevLon;
            latArrow(1) = prevLat;
            lonArrow(2) = longitudeCy(1);
            latArrow(2) = latitudeCy(1);

            dispDescription = '';
            timeSpanStart = datestr(prevDate+referenceDate, 'yyyy-mm-ddTHH:MM:SSZ');
            timeSpanEnd = datestr(juldCy(1)+referenceDate, 'yyyy-mm-ddTHH:MM:SSZ');

            kmlStrTrajIr = [kmlStrTrajIr, ge_create_line2( ...
               lonArrow, latArrow, ...
               dispDescription, ...
               '', ...
               '0', ...
               '#CUR_IRIDIUM_DISP', ...
               timeSpanStart, '')];

            kmlStrTrajIr = [kmlStrTrajIr, ...
               9, '</Folder>', 10, ...
               ];

            prevLon = longitudeCy(end);
            prevLat = latitudeCy(end);
            prevDate = juldCy(end);

         end
      end
   end

   kmlStrLoc = [kmlStrLoc, ...
      9, '</Folder>', 10, ...
      ];

   kmlStrLocIr = [kmlStrLocIr, ...
      9, '</Folder>', 10, ...
      ];

   kmlStrTraj = [kmlStrTraj, ...
      9, '</Folder>', 10, ...
      ];

   kmlStrTrajIr = [kmlStrTrajIr, ...
      9, '</Folder>', 10, ...
      ];
   
   % sauvegarde temporaire du code kml généré
   fidOutTmp = fopen([outputTempLaunchFileName floatNumStr '.tmp'], 'wt');
   if (fidOutTmp == -1)
      fprintf('Impossible de créer le fichier %s\n', outputTempLaunchFileName);
      return
   end
   fprintf(fidOutTmp, '%s', kmlStrLaunch);
   fclose(fidOutTmp);

   if (ARGOS_GPS_LOC_FLAG == 1)
      fidOutTmp = fopen([outputTempLocFileName floatNumStr '.tmp'], 'wt');
      if (fidOutTmp == -1)
         fprintf('Impossible de créer le fichier %s\n', outputTempLocFileName);
         return
      end
      fprintf(fidOutTmp, '%s', kmlStrLoc);
      fclose(fidOutTmp);
   end

   if (IRIDIUM_LOC_FLAG == 1)
      fidOutTmp = fopen([outputTempLocIrFileName floatNumStr '.tmp'], 'wt');
      if (fidOutTmp == -1)
         fprintf('Impossible de créer le fichier %s\n', outputTempLocIrFileName);
         return
      end
      fprintf(fidOutTmp, '%s', kmlStrLocIr);
      fclose(fidOutTmp);

      fidOutTmp = fopen([outputTempTrajIrFileName floatNumStr '.tmp'], 'wt');
      if (fidOutTmp == -1)
         fprintf('Impossible de créer le fichier %s\n', outputTempTrajIrFileName);
         return
      end
      fprintf(fidOutTmp, '%s', kmlStrTrajIr);
      fclose(fidOutTmp);
   end

   fidOutTmp = fopen([outputTempTrajFileName floatNumStr '.tmp'], 'wt');
   if (fidOutTmp == -1)
      fprintf('Impossible de créer le fichier %s\n', outputTempTrajFileName);
      return
   end
   fprintf(fidOutTmp, '%s', kmlStrTraj);
   fclose(fidOutTmp);
end

% sauvegarde du code kml généré
kmlStr = [ ...
   9, '<Folder>', 10, ...
   9, 9, '<name>floats launch postions</name>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);
for idFloat = 1:nbFloats
   floatNumStr = num2str(floatList(idFloat));
   outputTempFileName = [outputTempLaunchFileName floatNumStr '.tmp'];
   fidOutTmp = fopen(outputTempFileName, 'r');
   if (fidOutTmp == -1)
      fprintf('Impossible de créer le fichier %s\n', outputTempFileName);
      return
   end
   while 1
      line = fgetl(fidOutTmp);
      if (~ischar(line))
         break
      end
      fprintf(fidOut, '%s\n', line);
   end
   fclose(fidOutTmp);
end
kmlStr = [ ...
   9, '</Folder>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);

if (ARGOS_GPS_LOC_FLAG == 1)
   kmlStr = [ ...
      9, '<Folder>', 10, ...
      9, 9, '<name>floats Argos or GPS positions</name>', 10, ...
      ];
   fprintf(fidOut, '%s', kmlStr);
   for idFloat = 1:nbFloats
      floatNumStr = num2str(floatList(idFloat));
      outputTempFileName = [outputTempLocFileName floatNumStr '.tmp'];
      fidOutTmp = fopen(outputTempFileName, 'r');
      if (fidOutTmp == -1)
         fprintf('Impossible de créer le fichier %s\n', outputTempFileName);
         return
      end
      while 1
         line = fgetl(fidOutTmp);
         if (~ischar(line))
            break
         end
         fprintf(fidOut, '%s\n', line);
      end
      fclose(fidOutTmp);
   end
   kmlStr = [ ...
      9, '</Folder>', 10, ...
      ];
   fprintf(fidOut, '%s', kmlStr);
end

if (IRIDIUM_LOC_FLAG == 1)
   kmlStr = [ ...
      9, '<Folder>', 10, ...
      9, 9, '<name>floats Iridium positions</name>', 10, ...
      ];
   fprintf(fidOut, '%s', kmlStr);
   for idFloat = 1:nbFloats
      floatNumStr = num2str(floatList(idFloat));
      outputTempFileName = [outputTempLocIrFileName floatNumStr '.tmp'];
      fidOutTmp = fopen(outputTempFileName, 'r');
      if (fidOutTmp == -1)
         fprintf('Impossible de créer le fichier %s\n', outputTempFileName);
         return
      end
      while 1
         line = fgetl(fidOutTmp);
         if (~ischar(line))
            break
         end
         fprintf(fidOut, '%s\n', line);
      end
      fclose(fidOutTmp);
   end
   kmlStr = [ ...
      9, '</Folder>', 10, ...
      ];
   fprintf(fidOut, '%s', kmlStr);

   kmlStr = [ ...
      9, '<Folder>', 10, ...
      9, 9, '<name>floats Iridium trajectories</name>', 10, ...
      ];
   fprintf(fidOut, '%s', kmlStr);
   for idFloat = 1:nbFloats
      floatNumStr = num2str(floatList(idFloat));
      outputTempFileName = [outputTempTrajIrFileName floatNumStr '.tmp'];
      fidOutTmp = fopen(outputTempFileName, 'r');
      if (fidOutTmp == -1)
         fprintf('Impossible de créer le fichier %s\n', outputTempFileName);
         return
      end
      while 1
         line = fgetl(fidOutTmp);
         if (~ischar(line))
            break
         end
         fprintf(fidOut, '%s\n', line);
      end
      fclose(fidOutTmp);
   end
   kmlStr = [ ...
      9, '</Folder>', 10, ...
      ];
   fprintf(fidOut, '%s', kmlStr);

end

kmlStr = [ ...
   9, '<Folder>', 10, ...
   9, 9, '<name>floats Argos or GPS trajectories</name>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);
for idFloat = 1:nbFloats
   floatNumStr = num2str(floatList(idFloat));
   outputTempFileName = [outputTempTrajFileName floatNumStr '.tmp'];
   fidOutTmp = fopen(outputTempFileName, 'r');
   if (fidOutTmp == -1)
      fprintf('Impossible de créer le fichier %s\n', outputTempFileName);
      return
   end
   while 1
      line = fgetl(fidOutTmp);
      if (~ischar(line))
         break
      end
      fprintf(fidOut, '%s\n', line);
   end
   fclose(fidOutTmp);
end
kmlStr = [ ...
   9, '</Folder>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);

% finalisation du fichier kml
footer = [ ...
   '</Document>', 10, ...
   '</kml>', 10];

fprintf(fidOut,'%s',footer);
fclose(fidOut);

% suppression du répertoire temporaire
rmdir(tmpDirName,'s');

% création du fichier kmz
zip([DIR_OUTPUT_KML_FILES kmzFileName], [DIR_OUTPUT_KML_FILES kmlFileName]);
delete([DIR_OUTPUT_KML_FILES kmlFileName]);
move_file([DIR_OUTPUT_KML_FILES kmzFileName '.zip '], [DIR_OUTPUT_KML_FILES kmzFileName]);

return
