% ------------------------------------------------------------------------------
% Correction of the Argos HEX data.
% The correction only concerns the number of lines of the satellite pass.
%
% SYNTAX :
%   co_cls_correct_argos_raw_file
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
%   04/04/2014 - RNU - creation
% ------------------------------------------------------------------------------
function co_cls_correct_argos_raw_file()

% input directory(ies) to process
tabInputDirName = [];
% tabInputDirName{end+1} = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160208\archive_cycle\ori\';
% tabInputDirName{end+1} = 'C:\Users\jprannou\_DATA\tmp_20160227\';
% tabInputDirName{end+1} = 'C:\Users\jprannou\_DATA\IN\ARN\ori_split_cycle\';
% tabInputDirName{end+1} = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160823\archive_cycle_20160823\ori\';
% tabInputDirName{end+1} = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\spool_20160824\ori\';
% tabInputDirName{end+1} = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\archive_cycle_all_20160823\ori\';
% tabInputDirName{end+1} = 'C:\Users\jprannou\_DATA\Apex_set2\110813_ori\';
% tabInputDirName{end+1} = 'C:\Users\jprannou\_DATA\Apex_set2\082213_ori\';
% tabInputDirName{end+1} = 'C:\Users\jprannou\_DATA\Apex_set2\082213_1_ori\';
% tabInputDirName{end+1} = 'C:\Users\jprannou\_DATA\Apex_set2\021208_ori\';
% tabInputDirName{end+1} = 'C:\Users\jprannou\_DATA\Apex_set2\032213_ori\';
% tabInputDirName{end+1} = 'C:\Users\jprannou\_DATA\Apex_set2\110613_ori\';
% tabInputDirName{end+1} = 'C:\Users\jprannou\_DATA\Apex_set2\090413_ori\';
% tabInputDirName{end+1} = 'C:\Users\jprannou\_DATA\Apex_set2\121512_ori\';
% tabInputDirName{end+1} = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\recup_mail_VB_20160830\final_processing\ori\';
% tabInputDirName{end+1} = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160823\Complement_argos_V110813\ori\';
tabInputDirName{end+1} = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160914\fichiers_cycle_apex_233_floats_bascule_20160823\';


% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% flag to process also sub-directories
SUB_DIR_FLAG = 1;


% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'co_cls_correct_argos_raw_file_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

for idName = 1:length(tabInputDirName)
   
   % directory to process
   inputDirName = char(tabInputDirName{idName});
   
   fprintf('Processing directory : %s\n', inputDirName);

   % directory to store corrected files
   corDirName = [inputDirName(1:end-1) '_CORRECT/'];
   if ~(exist(corDirName, 'dir') == 7)
      mkdir(corDirName);
   end

   if (SUB_DIR_FLAG == 0)
      co_cls_correct_argos_raw_file_one_dir(inputDirName, corDirName);
   else
      dirs = dir(inputDirName);
      nbDirs = length(dirs);
      for idDir = 1:nbDirs
         
         dirName = dirs(idDir).name;
         subDirPathName = [inputDirName '/' dirName '/'];
         
         if (isdir(subDirPathName))
            if ~(strcmp(dirName, '.') || strcmp(dirName, '..'))
               
               corSubDirName = [corDirName '/' dirName];
               if ~(exist(corSubDirName, 'dir') == 7)
                  mkdir(corSubDirName);
               end
               
               fprintf('Processing sub-directory : %s\n', dirName);
               
               co_cls_correct_argos_raw_file_one_dir(subDirPathName, corSubDirName);
            end
         end
      end
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;

% ------------------------------------------------------------------------------
% Correction of the Argos HEX files of a given directory.
% The correction only concerns the number of lines of the satellite pass.
%
% SYNTAX :
%  co_cls_correct_argos_raw_file(a_inputDir, a_outputDir)
%
% INPUT PARAMETERS :
%   a_inputDir  : input directory of the files to correct
%   a_outputDir : output directory of the corrected files
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/04/2014 - RNU - creation
% ------------------------------------------------------------------------------
function co_cls_correct_argos_raw_file_one_dir(a_inputDir, a_outputDir)

% processing of current directory contents
files = dir(a_inputDir);
nbFiles = length(files);
fprintf('Dir: %s (%d files)\n', a_inputDir, nbFiles);
for idFic = 1:nbFiles
   fileName = files(idFic).name;
   filePathName = [a_inputDir '/' fileName];
   
   if (exist(filePathName, 'file') == 2)
      
      % process the current file
      fIdIn = fopen(filePathName, 'r');
      if (fIdIn == -1)
         fprintf('Error while opening file : %s\n', filePathName);
         return;
      end
      
      % first step: looking for satellite pass header and storing the number of
      % lines of each satellite pass
      tabNbLinesToReadCor = [];
      tabNbLinesToReadOri = [];
      startLine = -1;
      lineNum = 0;
      while (1)
         line = fgetl(fIdIn);
         if (line == -1)
            if (startLine ~= -1)
               tabNbLinesToReadCor = [tabNbLinesToReadCor; lineNum-startLine+1];
            end
            break;
         end
         lineNum = lineNum + 1;
         
         % looking for satellite pass header
         [val1, count1, errmsg1, nextindex1] = sscanf(line, '%d %d %d %d %c %c %d-%d-%d %d:%d:%f %f %f %f %d');
         [val2, count2, errmsg2, nextindex2] = sscanf(line, '%d %d %d %d %c');
         [val3, count3, errmsg3, nextindex3] = sscanf(line, '%d %d %d %d %c %d-%d-%d %d:%d:%f %d %x %x %x %x');
         if ((isempty(errmsg1) && (count1 == 16)) || ...
               (isempty(errmsg2) && (count2 == 5) && (val2(2) > 99)) || ...
               (isempty(errmsg3) && (count3 == 16) && (isempty(find(val3(13:end) > 255, 1)))))
            
            if (startLine ~= -1)
               tabNbLinesToReadCor = [tabNbLinesToReadCor; lineNum-startLine];
            end
            startLine = lineNum;
            tabNbLinesToReadOri = [tabNbLinesToReadOri; val1(3)];
         end
      end
      
      fclose(fIdIn);
      
      % second step: writing of output file with the updated number of lines of
      % each satellite pass
      if (~isempty(tabNbLinesToReadCor))
         
         if (isempty(find((tabNbLinesToReadCor-tabNbLinesToReadOri) ~= 0, 1)))
            % no error dected => duplicate the file
            fileIn = filePathName;
            fileOut = [a_outputDir '/' fileName];
            copyfile(fileIn, fileOut);
         else
            % error(s) detected => correct the file

            % input file
            fIdIn = fopen(filePathName, 'r');
            if (fIdIn == -1)
               fprintf('Error while opening file : %s\n', filePathName);
               return;
            end
            
            % output file
            outputFileName = [a_outputDir '/' fileName];
            fIdOut = fopen(outputFileName, 'wt');
            if (fIdOut == -1)
               fprintf('Error while creating file : %s\n', outputFileName);
               return;
            end
            
            lineNum = 0;
            for id = 1:length(tabNbLinesToReadCor)
               started = 0;
               nbLinesToCopy = tabNbLinesToReadCor(id);
               while (nbLinesToCopy > 0)
                  line = fgetl(fIdIn);
                  if (line == -1)
                     break;
                  end
                  lineNum = lineNum + 1;
                  
                  if (started == 1)
                     nbLinesToCopy = nbLinesToCopy - 1;
                  end
                  
                  % looking for satellite pass header
                  [val1, count1, errmsg1, nextindex1] = sscanf(line, '%d %d %d %d %c %c %d-%d-%d %d:%d:%f %f %f %f %d');
                  [val2, count2, errmsg2, nextindex2] = sscanf(line, '%d %d %d %d %c');
                  [val3, count3, errmsg3, nextindex3] = sscanf(line, '%d %d %d %d %c %d-%d-%d %d:%d:%f %d %x %x %x %x');
                  if ((isempty(errmsg1) && (count1 == 16)) || ...
                        (isempty(errmsg2) && (count2 == 5) && (val2(2) > 99)) || ...
                        (isempty(errmsg3) && (count3 == 16) && (isempty(find(val3(13:end) > 255, 1)))))
                     
                     started = 1;
                     nbLinesToCopy = nbLinesToCopy - 1;
                     if (tabNbLinesToReadCor(id) > 1)
                        if (val1(3) ~= tabNbLinesToReadCor(id))
                           idBlank = strfind(line, ' ');
                           
                           idB1 = idBlank(1);
                           idB = idBlank(2);
                           pos = 3;
                           while ((idB == idB1+1) && (pos <= length(idBlank)))
                              idB = idBlank(pos);
                              pos = pos + 1;
                           end
                           idB2 = idB;
                           idB = idBlank(pos);
                           pos = pos + 1;
                           while ((idB == idB2+1) && (pos <= length(idBlank)))
                              idB = idBlank(pos);
                              pos = pos + 1;
                           end
                           idB3 = idB;
                           
                           line = [line(1:idB2) num2str(tabNbLinesToReadCor(id)) line(idB3:end)];
                           fprintf('File corrected %s: line %d (%d instead of %d)\n', ...
                              fileName, lineNum, tabNbLinesToReadCor(id), val1(3));
                        end
                     end
                  end
                  
                  if (tabNbLinesToReadCor(id) > 1)
                     fprintf(fIdOut, '%s\n', line);
                  end
               end
            end
            
            fclose(fIdOut);
            fclose(fIdIn);
         end
      end
   end
end

return;
