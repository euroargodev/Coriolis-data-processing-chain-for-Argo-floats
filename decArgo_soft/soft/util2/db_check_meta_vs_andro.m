% ------------------------------------------------------------------------------
% Check ANDRO corrected mete-data VS Coriolis data base contents.
%
% SYNTAX :
%   db_check_meta_vs_andro
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
%   03/23/2014 - RNU - creation
% ------------------------------------------------------------------------------
function db_check_meta_vs_andro()

% meta-data file exported from Coriolis data base
dbMetaFileName = 'C:\users\RNU\Argo\work\meta_tmp_20140317.txt';

% meta-data file exported from ANDRO
androMetaFileName = 'C:\users\RNU\Argo\work\andro_20140317.txt';

fprintf('Checking DB meta-data (%s) against ANDRO meta-data (%s)\n', ...
   dbMetaFileName, androMetaFileName);

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\users\RNU\Argo\work\';


logFile = [DIR_LOG_CSV_FILE '/' 'db_check_meta_vs_andro_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);

% read DB meta file
if ~(exist(dbMetaFileName, 'file') == 2)
   fprintf('ERROR: Meta-data file not found: %s\n', dbMetaFileName);
   return;
end

fId = fopen(dbMetaFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', dbMetaFileName);
   return;
end
fileContents = textscan(fId, '%s', 'delimiter', '\t');
fileContents = fileContents{:};
fclose(fId);
fileContents = regexprep(fileContents, '"', '');

metaData = reshape(fileContents, 5, size(fileContents, 1)/5)';

% process the meta-data to fill the structure
% wmoList = str2num(cell2mat(metaData(:, 1))); % works only if all raws have the sme number of digits
% dimLevlist = str2num(cell2mat(metaData(:, 3))); % works only if all raws have the sme number of digits
wmoList = metaData(:, 1);
for id = 1:length(wmoList)
   if (isempty(str2num(wmoList{id})))
      fprintf('%s is not a valid WMO number\n', wmoList{id});
      return;
   end
end
S = sprintf('%s*', wmoList{:});
wmoList = sscanf(S, '%f*');

techParamIdList = metaData(:, 2);
S = sprintf('%s*', techParamIdList{:});
techParamIdList = sscanf(S, '%f*');

dimLevelList = metaData(:, 3);
S = sprintf('%s*', dimLevelList{:});
dimLevelList = sscanf(S, '%f*');

% load ANDRO meta file
if ~(exist(androMetaFileName, 'file') == 2)
   fprintf('ERROR: Meta-data file not found: %s\n', androMetaFileName);
   return;
end

data = load(androMetaFileName);
androWmo = data(:, 1);
androRepRate = data(:, 4);
androCycleTime = data(:, 7);
androParkPres = data(:, 8);
androProfPres = data(:, 9);

androFloats = unique(androWmo);
% androFloats = 1900109;
for idF = 1:length(androFloats)
   
   floatNum = androFloats(idF);
   fprintf('%03d/%03d %d\n', idF, length(androFloats), floatNum);
   
   idForFloat = find(androWmo == floatNum);
   nbMis = length(idForFloat);
   
   idForWmo = find(wmoList == floatNum);
   
   % REPETITION_RATE
   idRepRate = find(techParamIdList(idForWmo) == 419);
   if (length(idRepRate) ~= nbMis)
      fprintf('ERROR: length(REPETITION_RATE)\n');
      continue;
   end
   
   % CYCLE_TIME
   idCyTime = find(techParamIdList(idForWmo) == 420);
   if (length(idCyTime) ~= nbMis)
      fprintf('ERROR: length(CYCLE_TIME)\n');
      continue;
   end

   % PARKING_PRESSURE
   idParkPres = find(techParamIdList(idForWmo) == 425);
   if (length(idParkPres) ~= nbMis)
      fprintf('ERROR: length(PARKING_PRESSURE)\n');
      continue;
   end

   % DEEPEST_PRESSURE
   idProfPres = find(techParamIdList(idForWmo) == 426);
   if (length(idProfPres) ~= nbMis)
      fprintf('ERROR: length(DEEPEST_PRESSURE)\n');
      continue;
   end
   
   for idMis = 1:nbMis
      aRepRate = androRepRate(idForFloat(idMis));
      id = find(dimLevelList(idForWmo(idRepRate)) == idMis);
      bRepRate = str2num(metaData{idForWmo(idRepRate(id)), 4});
      if (aRepRate ~= bRepRate)
         fprintf('ERROR: REPETITION_RATE\n');
         continue;
      end
      
      aCyTime = androCycleTime(idForFloat(idMis));
      id = find(dimLevelList(idForWmo(idCyTime)) == idMis);
      bCyTime = str2num(metaData{idForWmo(idCyTime(id)), 4});
      if (aCyTime ~= bCyTime)
         fprintf('ERROR: CYCLE_TIME\n');
         continue;
      end

      aParkPres = androParkPres(idForFloat(idMis));
      id = find(dimLevelList(idForWmo(idParkPres)) == idMis);
      bParkPres = str2num(metaData{idForWmo(idParkPres(id)), 4});
      if (aParkPres ~= bParkPres)
         fprintf('ERROR: PARKING_PRESSURE\n');
         continue;
      end
      
      aProfPres = androProfPres(idForFloat(idMis));
      id = find(dimLevelList(idForWmo(idProfPres)) == idMis);
      bProfPres = str2num(metaData{idForWmo(idProfPres(id)), 4});
      if (aProfPres ~= bProfPres)
         fprintf('ERROR: DEEPEST_PRESSURE\n');
         continue;
      end
   end
end

fprintf('done\n');

diary off;

return;
