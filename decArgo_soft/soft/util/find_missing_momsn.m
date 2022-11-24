% ------------------------------------------------------------------------------
% Look for missing email files (from MOMSN values).
%
% SYNTAX :
%   find_missing_momsn
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
%   02/18/2019 - RNU - creation
%   12/20/2019 - RNU - version without using external configuration file
% ------------------------------------------------------------------------------
function find_missing_momsn

% directory to store the log and the csv files
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% choose to check RSYNC_DATA or IRIDIUM_DATA directory
% if CHECK_RSYNC_DATA = 1, we will check all email files stored in the
% RSYNC_DATA_DIRECTORY directory
% if CHECK_RSYNC_DATA = 0, we will check all useful email files of
% the IRIDIUM_DATA_DIRECTORY directory that concern floats of the
% FLOAT_INFORMATION_FILE_NAME file
CHECK_RSYNC_DATA = 1;

% if CHECK_RSYNC_DATA = 1
% provide the RSYNC_DATA_DIRECTORY directory to check
RSYNC_DATA_DIRECTORY = 'C:\Users\jprannou\_DATA\IN\RSYNC\CTS3\rsync_data\';

% if CHECK_RSYNC_DATA = 0
% provide the IRIDIUM_DATA_DIRECTORY directory to check and the 
% FLOAT_INFORMATION_FILE_NAME file to use
IRIDIUM_DATA_DIRECTORY = 'C:\Users\jprannou\_DATA\IN\IRIDIUM_DATA\CTS3\';
FLOAT_INFORMATION_FILE_NAME = 'C:\Users\jprannou\_DATA\IN\decArgo_config_floats\argoFloatInfo\_provor_floats_information_co.txt';

% default values initialization
init_default_values;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;


logFile = [DIR_LOG_FILE '/' 'find_missing_momsn_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% check inputs
if (CHECK_RSYNC_DATA == 1)

   if ~(exist(RSYNC_DATA_DIRECTORY, 'dir') == 7)
      fprintf('ERROR: Directory not found: %s\n', RSYNC_DATA_DIRECTORY);
      return
   end
   
   fprintf('Find missing MOMSN in the emails of the directory:\n');
   fprintf(' RSYNC_DATA_DIRECTORY = %s\n\n', RSYNC_DATA_DIRECTORY);
   
else
   
   if ~(exist(IRIDIUM_DATA_DIRECTORY, 'dir') == 7)
      fprintf('ERROR: Directory not found: %s\n', IRIDIUM_DATA_DIRECTORY);
      return
   end
   
   if ~(exist(FLOAT_INFORMATION_FILE_NAME, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', FLOAT_INFORMATION_FILE_NAME);
      return
   end
   
   fprintf('Find missing MOMSN in the emails of the directory:\n');
   fprintf(' IRIDIUM_DATA_DIRECTORY = %s\n', IRIDIUM_DATA_DIRECTORY);
   fprintf('According to float info file::\n');
   fprintf(' FLOAT_INFORMATION_FILE_NAME = %s\n\n', FLOAT_INFORMATION_FILE_NAME);

end

% create the CSV output file
outputFileName = [DIR_LOG_FILE '/' 'find_missing_momsn_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = 'Directory; Start date; End date; Nb missing mails; First missing MOMSN; Last missing MOMSN';
fprintf(fidOut, '%s\n', header);

if (CHECK_RSYNC_DATA == 1)
   
   imeiDirs = dir(RSYNC_DATA_DIRECTORY);
   for idDir = 1:length(imeiDirs)
      
      imeiDirName = imeiDirs(idDir).name;
      imeiDirPathName = [RSYNC_DATA_DIRECTORY '/' imeiDirName];
      if ((exist(imeiDirPathName, 'dir') == 7) && ~strcmp(imeiDirName, '.') && ~strcmp(imeiDirName, '..'))
         
         fprintf('Processing directory: %s\n', imeiDirName);
         
         imeiFiles = dir(imeiDirPathName);
         tabDate = cell(length(imeiFiles), 1);
         tabMomsn = ones(length(imeiFiles), 1)*-1;
         cpt = 1;
         for idFile = 1:length(imeiFiles)
            
            imeiFileName = imeiFiles(idFile).name;
            imeiFilePathName = [imeiDirPathName '/' imeiFileName];
            if (exist(imeiFilePathName, 'file') == 2)
               idFUs = strfind(imeiFileName, '_');
               tabDate{cpt} = imeiFileName(idFUs(1)+1:idFUs(2)-1);
               tabMomsn(cpt) = str2double(imeiFileName(idFUs(3)+1:idFUs(4)-1));
               cpt = cpt + 1;
               %                fprintf('   - %s\n', imeiFileName);
            end
         end
         tabDate(find(tabMomsn == -1)) = [];
         tabMomsn(find(tabMomsn == -1)) = [];
         
         missingListId = find(diff(tabMomsn) > 1);
         for idM = 1:length(missingListId)
            
            startDate = datenum(tabDate{missingListId(idM)}, 'yyyymmddTHHMMSSZ') - g_decArgo_janFirst1950InMatlab;
            endDate = datenum(tabDate{missingListId(idM)+1}, 'yyyymmddTHHMMSSZ') - g_decArgo_janFirst1950InMatlab;
            
            fprintf(fidOut, '%s;%s;%s;%d;%d;%d\n', ...
               imeiDirName, ...
               julian_2_gregorian_dec_argo(startDate), ...
               julian_2_gregorian_dec_argo(endDate), ...
               tabMomsn(missingListId(idM)+1)-tabMomsn(missingListId(idM))-1, ...
               tabMomsn(find(strcmp(tabDate{missingListId(idM)}, tabDate), 1, 'first'))+1, ...
               tabMomsn(find(strcmp(tabDate{missingListId(idM)}, tabDate), 1, 'last')+1)-1);
         end
      end
   end
   
else
      
   % read the list to associate a WMO number to a login name
   [floatWmoList, ~, ~, ~, ~, ~, ~, launchDateList, ~, ~, ~, endDateList, ~] = ...
      get_floats_info(FLOAT_INFORMATION_FILE_NAME);
   if (isempty(floatWmoList))
      return
   end
   
   imeiDirs = dir(IRIDIUM_DATA_DIRECTORY);
   for idDir = 1:length(imeiDirs)
      
      imeiDirName = imeiDirs(idDir).name;
      imeiDirPathName = [IRIDIUM_DATA_DIRECTORY '/' imeiDirName '/archive/'];
      if ((exist(imeiDirPathName, 'dir') == 7) && ~strcmp(imeiDirName, '.') && ~strcmp(imeiDirName, '..'))
         
         idFUs = strfind(imeiDirName, '_');
         floatWmo = str2double(imeiDirName(idFUs(1)+1:end));
         idFloat = find(floatWmoList == floatWmo);
         if (~isempty(idFloat))
            floatLaunchDate = launchDateList(idFloat);
            floatEndDate = endDateList(idFloat);
            
            fprintf('Processing directory: %s\n', imeiDirName);
            
            imeiFiles = dir(imeiDirPathName);
            tabDate = cell(length(imeiFiles), 1);
            tabMomsn = ones(length(imeiFiles), 1)*-1;
            cpt = 1;
            for idFile = 1:length(imeiFiles)
               
               imeiFileName = imeiFiles(idFile).name;
               imeiFilePathName = [imeiDirPathName '/' imeiFileName];
               if (exist(imeiFilePathName, 'file') == 2)
                  idFUs = strfind(imeiFileName, '_');
                  tabDate{cpt} = imeiFileName(idFUs(1)+1:idFUs(2)-1);
                  tabMomsn(cpt) = str2double(imeiFileName(idFUs(3)+1:idFUs(4)-1));
                  cpt = cpt + 1;
                  %                fprintf('   - %s\n', imeiFileName);
               end
            end
            tabDate(find(tabMomsn == -1)) = [];
            tabMomsn(find(tabMomsn == -1)) = [];
            
            missingListId = find(diff(tabMomsn) > 1);
            for idM = 1:length(missingListId)
               
               startDate = datenum(tabDate{missingListId(idM)}, 'yyyymmddTHHMMSSZ') - g_decArgo_janFirst1950InMatlab;
               endDate = datenum(tabDate{missingListId(idM)+1}, 'yyyymmddTHHMMSSZ') - g_decArgo_janFirst1950InMatlab;
               
               if (floatEndDate ~= g_decArgo_dateDef)
                  if ((floatLaunchDate > endDate) || (floatEndDate > startDate))
                     continue
                  end
               else
                  if (floatLaunchDate > endDate)
                     continue
                  end
               end
               
               fprintf(fidOut, '%s;%s;%s;%d;%d;%d\n', ...
                  imeiDirName, ...
                  julian_2_gregorian_dec_argo(startDate), ...
                  julian_2_gregorian_dec_argo(endDate), ...
                  tabMomsn(missingListId(idM)+1)-tabMomsn(missingListId(idM))-1, ...
                  tabMomsn(find(strcmp(tabDate{missingListId(idM)}, tabDate), 1, 'first'))+1, ...
                  tabMomsn(find(strcmp(tabDate{missingListId(idM)}, tabDate), 1, 'last')+1)-1);
            end
         end
      end
   end
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
