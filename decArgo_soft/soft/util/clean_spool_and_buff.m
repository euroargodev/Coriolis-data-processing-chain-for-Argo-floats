% ------------------------------------------------------------------------------
% Clean spool and buffer directories of Remocean floats.
%
% SYNTAX :
% clean_spool_and_buff
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
%   07/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function clean_spool_and_buff

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values initialization
init_default_values;


% configuration parameters
configVar = [];
configVar{end+1} = 'IRIDIUM_DATA_DIRECTORY';
configVar{end+1} = 'FLOAT_TRANSMISSION_TYPE';

% get configuration parameters
g_decArgo_realtimeFlag = 0;
g_decArgo_delayedModeFlag = 0;
[configVal, unusedVarargin, inputError] = get_config_dec_argo(configVar, []);
iridiumDataDirectory = configVal{1};
floatTransmissionType = str2num(configVal{2});

topDir = iridiumDataDirectory;
% topDir = 'E:\remocean_data\';

dirAll = dir(topDir);
for dirNum = 1:length(dirAll)
   if ~(strcmp(dirAll(dirNum).name, '.') || strcmp(dirAll(dirNum).name, '..'))
      dirName = dirAll(dirNum).name;
      dirPathName = [topDir '/' dirName '/'];
      if (exist(dirPathName, 'dir') == 7)
         
         dir1Sub = dir(dirPathName);
         for idDir1 = 1:length(dir1Sub)
            dir2Name = dir1Sub(idDir1).name;
            if (strcmp(dir2Name, 'spool') || strcmp(dir2Name, 'buffer'))
               
               dir2PathName = [topDir '/' dirName '/' dir2Name '/'];
               
               dir2Sub = dir(dir2PathName);
               for idDir2 = 1:length(dir2Sub)
                  sbdFileName = dir2Sub(idDir2).name;
                  sbdFilePathNameIn = [topDir '/' dirName '/' dir2Name '/' sbdFileName];
                  
                  if (exist(sbdFilePathNameIn, 'file') == 2)
                     
                     if (((floatTransmissionType == 3) || (floatTransmissionType == 4)) && (strcmp(sbdFileName(end-3:end), '.sbd')))
                        
                        fprintf('delete file %s\n', sbdFilePathNameIn);
                        delete(sbdFilePathNameIn);
                     else
                     
                        sbdFilePathNameOut = [topDir '/' dirName '/archive/' sbdFileName];
                        
                        fprintf('mv(%s, %s)\n', sbdFilePathNameIn, sbdFilePathNameOut);
                        
                        move_file(sbdFilePathNameIn, sbdFilePathNameOut);
                     end
                  end
               end
            end
         end
      end
   end
end

return;
