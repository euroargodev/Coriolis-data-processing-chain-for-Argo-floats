% ------------------------------------------------------------------------------
% Generate a KML file to plot profile locations.
%
% SYNTAX :
%   ge_generate_prof_from_nc or ge_generate_prof_from_nc(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : WMO number of floats to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/26/2019 - RNU - creation
% ------------------------------------------------------------------------------
function ge_generate_prof_from_nc(varargin)

% default values
global g_decArgo_janFirst1950InMatlab;

% default values initialization
init_default_values;

% default list of floats to process
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11_iridium-rudics_2.13.1.txt';

% directory of input NetCDF files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';

% directory of output KML file
DIR_OUTPUT_KML_FILES = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% temporary directory
DIR_TMP_FILES = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';


% julain 2 gregorian date conversion
referenceDateStr = '1950-01-01 00:00:00';
referenceDate = datenum(referenceDateStr, 'yyyy-mm-dd HH:MM:SS');

if (nargin == 0)
   % floats to process come from FLOAT_LIST_FILE_NAME
   if (~exist(FLOAT_LIST_FILE_NAME, 'file'))
      fprintf('ERROR: File not found: %s\n', FLOAT_LIST_FILE_NAME);
      return
   end
   
   fprintf('Floats from list: %s\n', FLOAT_LIST_FILE_NAME);
   floatList = textread(FLOAT_LIST_FILE_NAME, '%d');
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create temporary directory
ident = datestr(now, 'yyyymmddTHHMMSS');
tmpDirName = [DIR_TMP_FILES sprintf('tmp%s', ident)];
if (~exist(tmpDirName, 'dir'))
   mkdir(tmpDirName);
else
   fprintf('Temporary directory (%s) already exists: STOP\n', tmpDirName);
   return
end

% temporary files
outputTempLaunchFileName = [tmpDirName '/' 'ge_generate_prof_from_nc_LAUNCH'];
outputTempLocFileName = [tmpDirName '/' 'ge_generate_prof_from_nc_LOC'];
outputTempTrajFileName = [tmpDirName '/' 'ge_generate_prof_from_nc_TRAJ'];

% create and open output KML file
if (nargin == 0)
   [pathstr, name, ext] = fileparts(FLOAT_LIST_FILE_NAME);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

kmlFileName = ['ge_generate_prof_from_nc' name '_' ident '.kml'];
kmzFileName = [kmlFileName(1:end-4) '.kmz'];
outputFileName = [DIR_OUTPUT_KML_FILES kmlFileName];

fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   fprintf('Unable to create file %s\n', outputFileName);
   return
end

% put KML header
description = 'Profile locations generated with Argo NetCDF mono-prof files contents';
ge_put_header1(fidOut, description, kmlFileName);

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   kmlStrLaunch = [];
   kmlStrLoc = [];
   kmlStrTraj = [];
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatList(idFloat));
   fprintf('\n%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % meta-data processing
   metaFileName = [DIR_INPUT_NC_FILES '/' floatNumStr '/' floatNumStr '_meta.nc'];
   
   if ~(exist(metaFileName, 'file') == 2)
      fprintf('\n');
      fprintf('ERROR: File not found: %s\n', metaFileName);
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
   
   % check input file version
   if (~strcmp(metaFileFormatVersion, '3.1'))
      fprintf('\n');
      fprintf('ERROR: Meta-data file (%s) is expected to be of 3.1 format version (but FORMAT_VERSION = %s) - unused\n', ...
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
   
   idVal = find(strcmp('LAUNCH_DATE', metaData(1:2:end)) == 1, 1);
   launchDate = metaData{2*idVal};
   launchDateJuld = datenum(launchDate', 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
   idVal = find(strcmp('LAUNCH_LATITUDE', metaData(1:2:end)) == 1, 1);
   launchLatitude = metaData{2*idVal};
   idVal = find(strcmp('LAUNCH_LONGITUDE', metaData(1:2:end)) == 1, 1);
   launchLongitude = metaData{2*idVal};
   
   labelList = fieldnames(metaStruct);
   valueList = struct2cell(metaStruct);
   launchDescription = '';
   for id = 1:length(labelList)
      launchDescription = [launchDescription ...
         sprintf('%s: %s\n', labelList{id}, valueList{id})];
   end
   
   timeSpanStart = datestr(launchDateJuld+referenceDate, 'yyyy-mm-ddTHH:MM:SSZ');
   
   kmlStrLaunch = [kmlStrLaunch, ge_create_pos(launchLongitude, launchLatitude, ...
      launchDescription, floatNumStr, '#CUR_LAUNCH_POS', timeSpanStart, '')];
   
   kmlStrLoc = [kmlStrLoc, ...
      9, '<Folder>', 10, ...
      9, 9, '<name>', floatNumStr, '</name>', 10, ...
      ];
   
   kmlStrTraj = [kmlStrTraj, ...
      9, '<Folder>', 10, ...
      9, 9, '<name>', floatNumStr, '</name>', 10, ...
      ];
   
   profTrajJuld = launchDateJuld;
   profTrajLon = launchLongitude;
   profTrajLat = launchLatitude;
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % from PROF files
   profDirName = [DIR_INPUT_NC_FILES '/' floatNumStr '/profiles/'];
   
   floatFiles = dir([profDirName '/' sprintf('*%d_*.nc', floatNum)]);
   for idFile = 1:length(floatFiles)
      floatFileName = floatFiles(idFile).name;
      if (floatFileName(1) == 'B')
         continue
      end
      floatFilePathName = [profDirName '/' floatFileName];
      
      % retrieve information from PROF file
      wantedVars = [ ...
         {'FORMAT_VERSION'} ...
         {'JULD_LOCATION'} ...
         {'LATITUDE'} ...
         {'LONGITUDE'} ...
         {'POSITION_QC'} ...
         {'POSITIONING_SYSTEM'} ...
         {'JULD'} ...
         {'CYCLE_NUMBER'} ...
         {'DIRECTION'} ...
         {'PRES'} ...
         ];
      [profData] = get_data_from_nc_file(floatFilePathName, wantedVars);
      
      idVal = find(strcmp('FORMAT_VERSION', profData(1:2:end)) == 1, 1);
      profFileFormatVersion = strtrim(profData{2*idVal}');
      
      % contrôle de la version
      if (~strcmp(profFileFormatVersion, '3.1'))
         fprintf('\n');
         fprintf('ERROR: Profile file (%s) is expected to be of 3.1 format version (but FORMAT_VERSION = %s) - unused\n', ...
            floatFileName, profFileFormatVersion);
         continue
      end
      
      idVal = find(strcmp('JULD_LOCATION', profData(1:2:end)) == 1, 1);
      juldLocation = profData{2*idVal};
      idVal = find(strcmp('LATITUDE', profData(1:2:end)) == 1, 1);
      latitude = profData{2*idVal};
      idVal = find(strcmp('LONGITUDE', profData(1:2:end)) == 1, 1);
      longitude = profData{2*idVal};
      idVal = find(strcmp('POSITION_QC', profData(1:2:end)) == 1, 1);
      positionQc = profData{2*idVal};
      idVal = find(strcmp('POSITIONING_SYSTEM', profData(1:2:end)) == 1, 1);
      positioningSystem = profData{2*idVal}';
      idVal = find(strcmp('JULD', profData(1:2:end)) == 1, 1);
      juld = profData{2*idVal};
      idVal = find(strcmp('CYCLE_NUMBER', profData(1:2:end)) == 1, 1);
      cycleNumber = profData{2*idVal};
      idVal = find(strcmp('DIRECTION', profData(1:2:end)) == 1, 1);
      direction = profData{2*idVal};
      idVal = find(strcmp('PRES', profData(1:2:end)) == 1, 1);
      pres = profData{2*idVal};
      
      idBad = find((juldLocation == 999999) | (latitude == 99999) | (longitude == 99999));
      juldLocation(idBad) = [];
      latitude(idBad) = [];
      longitude(idBad) = [];
      positionQc(idBad) = [];
      positioningSystem(idBad, :) = [];
      juld(idBad) = [];
      cycleNumber(idBad) = [];
      direction(idBad) = [];
      pres(:, idBad) = [];
      
      for idProf = 1:length(juld)
         posDescription = [];
         posDescription = [posDescription, ...
            sprintf('JULD LOCATION : %s\n', julian_2_gregorian_dec_argo(juldLocation(idProf)))];
         posDescription = [posDescription, ...
            sprintf('LOCATION (lon, lat): %8.3f, %7.3f\n', longitude(idProf), latitude(idProf))];
         posDescription = [posDescription, ...
            sprintf('POSITION QC : %c\n', positionQc(idProf))];
         posDescription = [posDescription, ...
            sprintf('POSITIONING_SYSTEM : %s\n', strtrim(positioningSystem(idProf, :)))];
         posDescription = [posDescription, ...
            sprintf('JULD : %s\n', julian_2_gregorian_dec_argo(juld(idProf)))];
         posDescription = [posDescription, ...
            sprintf('CYCLE NUMBER : %d\n', cycleNumber(idProf))];
         posDescription = [posDescription, ...
            sprintf('DIRECTION : %c\n', direction(idProf))];
         profPres = pres(:, idProf);
         profPres(find(profPres == 99999)) = [];
         posDescription = [posDescription, ...
            sprintf('PRES range : %.1f - %.1f\n', min(profPres), max(profPres))];
         
         timeSpanStart = datestr(juldLocation(idProf)+referenceDate, 'yyyy-mm-ddTHH:MM:SSZ');
         
         style = '#PROF_POS_LOC';
         if (positionQc(idProf) == '8')
            style = '#PROF_POS_INTERP';
         end
         kmlStrLoc = [kmlStrLoc, ge_create_pos( ...
            longitude(idProf), latitude(idProf), ...
            posDescription, ...
            sprintf('%d_%c', cycleNumber(idProf), direction(idProf)), ...
            style, ...
            timeSpanStart, '')];
      end
      
      profTrajJuld = [profTrajJuld; juldLocation];
      profTrajLon = [profTrajLon; longitude];
      profTrajLat = [profTrajLat; latitude];
      
   end
   
   kmlStrLoc = [kmlStrLoc, ...
      9, '</Folder>', 10, ...
      ];
   
   [profTrajJuld, idSort] = sort(profTrajJuld);
   profTrajLat = profTrajLat(idSort);
   profTrajLon = profTrajLon(idSort);
   
   timeSpanStart = datestr(min(profTrajJuld+referenceDate), 'yyyy-mm-ddTHH:MM:SSZ');
   kmlStrTraj = [kmlStrTraj, ge_create_line( ...
      profTrajLon, profTrajLat, '', '', '#CUR_ARGOS_TRAJ', ...
      timeSpanStart, '')];
   
   kmlStrTraj = [kmlStrTraj, ...
      9, '</Folder>', 10, ...
      ];
   
   % store temporary KML code
   fidOutTmp = fopen([outputTempLaunchFileName floatNumStr '.tmp'], 'wt');
   if (fidOutTmp == -1)
      fprintf('Unable to create file %s\n', outputTempLaunchFileName);
      return
   end
   fprintf(fidOutTmp, '%s', kmlStrLaunch);
   fclose(fidOutTmp);
   
   fidOutTmp = fopen([outputTempLocFileName floatNumStr '.tmp'], 'wt');
   if (fidOutTmp == -1)
      fprintf('Unable to create file %s\n', outputTempLocFileName);
      return
   end
   fprintf(fidOutTmp, '%s', kmlStrLoc);
   fclose(fidOutTmp);
   
   fidOutTmp = fopen([outputTempTrajFileName floatNumStr '.tmp'], 'wt');
   if (fidOutTmp == -1)
      fprintf('Unable to create file %s\n', outputTempTrajFileName);
      return
   end
   fprintf(fidOutTmp, '%s', kmlStrTraj);
   fclose(fidOutTmp);
end

% concatenate temporay KML code
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
      fprintf('Unable to create file %s\n', outputTempFileName);
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
   9, 9, '<name>profile positions</name>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);
for idFloat = 1:nbFloats
   floatNumStr = num2str(floatList(idFloat));
   outputTempFileName = [outputTempLocFileName floatNumStr '.tmp'];
   fidOutTmp = fopen(outputTempFileName, 'r');
   if (fidOutTmp == -1)
      fprintf('Unable to create file %s\n', outputTempFileName);
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
   9, 9, '<name>floats trajectories from profile positions</name>', 10, ...
   ];
fprintf(fidOut, '%s', kmlStr);
for idFloat = 1:nbFloats
   floatNumStr = num2str(floatList(idFloat));
   outputTempFileName = [outputTempTrajFileName floatNumStr '.tmp'];
   fidOutTmp = fopen(outputTempFileName, 'r');
   if (fidOutTmp == -1)
      fprintf('Unable to create file %s\n', outputTempFileName);
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

% KML file finalization
footer = [ ...
   '</Document>', 10, ...
   '</kml>', 10];

fprintf(fidOut,'%s',footer);
fclose(fidOut);

% remove temporary directory
rmdir(tmpDirName,'s');

% KMZ file generation
zip([DIR_OUTPUT_KML_FILES kmzFileName], [DIR_OUTPUT_KML_FILES kmlFileName]);
delete([DIR_OUTPUT_KML_FILES kmlFileName]);
move_file([DIR_OUTPUT_KML_FILES kmzFileName '.zip '], [DIR_OUTPUT_KML_FILES kmzFileName]);

return
