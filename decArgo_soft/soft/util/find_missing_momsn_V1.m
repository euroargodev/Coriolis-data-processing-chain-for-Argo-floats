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
% ------------------------------------------------------------------------------
function find_missing_momsn

% directory to store the log and the csv files
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% choose to check RSYNC_DATA or IRIDIUM_DATA directory
% if CHECK_RSYNC_DATA = 1, we will check all email files stored in the
% RSYNC_DATA directory
% if CHECK_RSYNC_DATA = 0, we will check all useful email files of IRIDIUM_DATA
% that concern floats of the (provor/apex/nemo)_float_info set in the
% _argo_decoder_conf.txt file
CHECK_RSYNC_DATA = 0;

% when CHECK_RSYNC_DATA = 1, set the RSYNC_DATA directory path name in the
% following variable
RSYNC_DATA_DIRECTORY = 'C:\Users\jprannou\_DATA\IN\RSYNC\CTS3\rsync_data\';
% RSYNC_DATA_DIRECTORY = 'C:\Users\jprannou\_DATA\IN\RSYNC\CTS3\rsync_data\6902798\';
RSYNC_DATA_DIRECTORY = 'C:\Users\jprannou\_DATA\TEST_20121218\cycle\';

% default values initialization
init_default_values;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;


logFile = [DIR_LOG_FILE '/' 'find_missing_momsn_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

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
   
   % configuration parameters
   configVar = [];
   configVar{end+1} = 'FLOAT_INFORMATION_FILE_NAME';
   configVar{end+1} = 'IRIDIUM_DATA_DIRECTORY';
   
   % get configuration parameters
   g_decArgo_realtimeFlag = 0;
   g_decArgo_delayedModeFlag = 0;
   [configVal, ~, ~] = get_config_dec_argo(configVar, []);
   floatInformationFileName = configVal{1};
   iridiumDataDir = configVal{2};
   
   % read the list to associate a WMO number to a login name
   [floatWmoList, ~, ~, ~, ~, ~, ~, launchDateList, ~, ~, ~, endDateList, ~] = ...
      get_floats_info(floatInformationFileName);
   if (isempty(floatWmoList))
      return
   end
   
   imeiDirs = dir(iridiumDataDir);
   for idDir = 1:length(imeiDirs)
      
      imeiDirName = imeiDirs(idDir).name;
      imeiDirPathName = [iridiumDataDir '/' imeiDirName '/archive/'];
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
