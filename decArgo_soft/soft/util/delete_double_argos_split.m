% ------------------------------------------------------------------------------
% Find and delete identical split files (one file for each satellite pass)
% of a given directory.
%
% SYNTAX :
%   delete_double_argos_split
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
%   03/18/2014 - RNU - creation
% ------------------------------------------------------------------------------
function delete_double_argos_split()

% DIR_INPUT_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_RNU\DecApx_info\ArgosProcessing\apex_argos';
% DIR_INPUT_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_062608\ori_split';
% DIR_INPUT_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_061609\in_split';
% DIR_INPUT_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_021009\in_split';
% DIR_INPUT_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_061810\in_split';
% DIR_INPUT_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_093008\in_split';
% DIR_INPUT_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_061810\118188\in_split';
% DIR_INPUT_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160208\historical_processing\';
% DIR_INPUT_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\rerun\ori_split\';
% DIR_INPUT_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\ARN\ori_split\';
% DIR_INPUT_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160823\historical_processing\';
% DIR_INPUT_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\historical_processing\';
% DIR_INPUT_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\Desktop\recup\argos_split_CORRECT\';
% DIR_INPUT_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\recup_mail_VB_20160830\final_processing\';
% DIR_INPUT_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160823\split_raw_sans_doubles_FINAL_119Apex\tmp\';
% DIR_INPUT_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\historical_processing\';
DIR_INPUT_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\APEX_ARGOS_APF11\IN\ori_split';


% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';


% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'delete_double_argos_split_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% process the directories of the input directory
dirs = dir(DIR_INPUT_OUTPUT_ARGOS_FILES);
nbDirs = length(dirs);
for idDir = 1:nbDirs

   dirName = dirs(idDir).name;
   dirPathName = [DIR_INPUT_OUTPUT_ARGOS_FILES '/' dirName];

   if (isdir(dirPathName))
      if ~(strcmp(dirName, '.') || strcmp(dirName, '..'))
         
         fprintf('%03d/%03d Processing directory %s\n', idDir, nbDirs, dirName);

         % look for possible duplicated files and delete files with no date
         fileList = [];
         files = dir(dirPathName);
         nbFiles = length(files);
         for idFile = 1:nbFiles

            fileName = files(idFile).name;
            if ~(strcmp(fileName, '.') || strcmp(fileName, '..'))
               
               if (isempty(strfind(fileName, '-'))) % no date in the file
                  filePathName = [dirPathName '/' fileName];
                  fprintf('INFO: File %s deleted (no date)\n', fileName);
                  delete(filePathName);
               else
                  fileList{end+1} = fileName(1:end-7);
               end
            end
         end
         fileList = unique(fileList);

         % process possible duplicated files
         nbFiles = length(fileList);
         for idFile = 1:nbFiles
            stop = 0;
            while (~stop)
               if (length(dir([dirPathName '/' fileList{idFile} '*'])) > 1)

                  dFiles = dir([dirPathName '/' fileList{idFile} '*']);                  
                  nbDFiles = length(dFiles);
                  deleted = 0;
                  for id1 = 1:nbDFiles
                     
                     fileName1 = [dirPathName '/' dFiles(id1).name];
                     fid1 = fopen(fileName1, 'r');
                     if (fid1 == -1)
                        fprintf('ERROR: Unable to open file: %s\n', fileName1);
                        return;
                     end
                     file1Contents = textscan(fid1, '%s');
                     fclose(fid1);
                     file1Contents = file1Contents{:};
                        
                     for id2 = id1+1:nbDFiles
                        
                        fileName2 = [dirPathName '/' dFiles(id2).name];
                        fid2 = fopen(fileName2, 'r');
                        if (fid2 == -1)
                           fprintf('ERROR: Unable to open file: %s\n', fileName2);
                           return;
                        end
                        file2Contents = textscan(fid2, '%s');
                        fclose(fid2);
                        file2Contents = file2Contents{:};

                        % compare the 2 file contents
                        compRes = 1;
                        for idL = 1:min([length(file1Contents) length(file2Contents)])
                           if ((length(file1Contents) >= idL) && (length(file2Contents) >= idL))
                              if (strcmp(file1Contents{idL}, file2Contents{idL}) == 0)
                                 compRes = 2;
                                 break;
                              end
                           elseif (length(file1Contents) >= idL)
                              compRes = 3;
                              break;
                           elseif (length(file2Contents) >= idL)
                              compRes = 4;
                              break;
                           end
                        end

                        if (compRes == 1)

                           % files are identical
                           fprintf('INFO: Files %s and %s are identical => %s deleted\n', dFiles(id1).name, dFiles(id2).name, dFiles(id2).name);
                           delete(fileName2);
                           deleted = 1;
                           break;
                        elseif (compRes == 3)

                           % new file contents is included in base file
                           fprintf('INFO: File %s includes file %s contents => %s deleted\n', dFiles(id1).name, dFiles(id2).name, dFiles(id2).name);
                           delete(fileName2);
                           deleted = 1;
                           break;
                        elseif (compRes == 4)

                           % base file contents is included in new file
                           fprintf('INFO: File %s includes file %s contents => %s deleted\n', dFiles(id2).name, dFiles(id1).name, dFiles(id1).name);
                           delete(fileName1);
                           deleted = 1;
                           break;
                        end
                     end
                     if (deleted == 1)
                        break;
                     end
                  end

                  if (deleted == 0)
                     stop = 1;
                  end
               else
                  stop = 1;
               end
            end
         end
      end
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;
