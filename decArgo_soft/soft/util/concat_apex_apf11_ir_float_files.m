% ------------------------------------------------------------------------------
% Concat all the science_log, vitals_log and system_log files of an APF11 float
% in the same file.
%
% SYNTAX :
%   concat_apex_apf11_ir_float_files
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
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function concat_apex_apf11_ir_float_files

% directory of the float files
DIR_FLOAT_FILE = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_APF11\IRIDIUM_SBD\CHECK_DECODING\WORK\';
% DIR_FLOAT_FILE = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_APF11\IRIDIUM_RUDICS\CHECK_DECODING\WORK\';

% internal path (to choose Argo or Teledyne decoding)
INTERNAL_PATH = '\ARGO\FLOAT_FILES\ASCII\'; % to use Argo decoding
% INTERNAL_PATH = '\TELEDYNE\FLOAT_FILES\ASCII\'; % to use Teledyne decoding


dirNames = dir(DIR_FLOAT_FILE);
for idD = 1:length(dirNames)
   dirName = dirNames(idD).name;
   if (~strcmp(dirName, '.') && ~strcmp(dirName, '..'))
      floatWmo = dirName;
      fprintf('%s\n', floatWmo);
      dirFloatFile = [DIR_FLOAT_FILE '\' floatWmo '\' INTERNAL_PATH '\'];
      
      % create cycle number list
      cycleList = [];
      fileNames = [dir([dirFloatFile '*.txt']); dir([dirFloatFile '*.csv'])];
      for idFile = 1:length(fileNames)
         fileName = fileNames(idFile).name;
         idF = strfind(fileName, '.');
         if (length(idF) > 1)
            cyNum = fileName(idF(1)+1:idF(2)-1);
            [cyNum, status] = str2num(cyNum);
            if (status)
               cycleList = [cycleList cyNum];
            end
         end
      end
      cycleList = unique(cycleList);
      
      % concat log files
      for idFile = 1:3
         for idCy = 1:length(cycleList)
            if (idFile == 1)
               files = dir([dirFloatFile sprintf('*.%03d.*.science_log.csv', cycleList(idCy))]);
            elseif (idFile == 2)
               files = dir([dirFloatFile sprintf('*.%03d.*.vitals_log.csv', cycleList(idCy))]);
            elseif (idFile == 3)
               files = dir([dirFloatFile sprintf('*.%03d.*.system_log.txt', cycleList(idCy))]);
            end
            
            if (~isempty(files))
               if (idCy == 1)
                  fileName = files(1).name;
                  idF = strfind(fileName, '.');
                  if (idFile == 1)
                     outputFileName = ['_' fileName(1:idF(1)-1) '_ALL_science_log.csv'];
                     outputFileName2 = '_ALL_science_log.csv';
                  elseif (idFile == 2)
                     outputFileName = ['_' fileName(1:idF(1)-1) '_ALL_vitals_log.csv'];
                     outputFileName2 = '_ALL_vitals_log.csv';
                  elseif (idFile == 3)
                     outputFileName = ['_' fileName(1:idF(1)-1) '_ALL_system_log.csv'];
                     outputFileName2 = '_ALL_system_log.csv';
                  end
                  outputFilePathName = [dirFloatFile outputFileName];
                  outputFilePathName2 = [DIR_FLOAT_FILE '\' outputFileName2];
                  
                  fIdOut = fopen(outputFilePathName, 'wt');
                  if (fIdOut == -1)
                     fprintf('ERROR: Unable to create file: %s\n', outputFilePathName);
                     return;
                  end
                  fIdOut2 = fopen(outputFilePathName2, 'a');
                  if (fIdOut2 == -1)
                     fprintf('ERROR: Unable to create file: %s\n', outputFilePathName2);
                     return;
                  end
               end
               
               for iFile = 1:length(files)
                  filePathName = [dirFloatFile files(iFile).name];
                  
                  fId = fopen(filePathName, 'r');
                  if (fId == -1)
                     fprintf('ERROR: Unable to open file: %s\n', filePathName);
                     return;
                  end
                  
                  lineNum = 0;
                  while 1
                     line = fgetl(fId);
                     
                     if (line == -1)
                        break;
                     end
                     
                     lineNum = lineNum + 1;
                     line = strtrim(line);
                     if (isempty(line))
                        continue;
                     end
                     if (isempty(line) || ((line(1) == '>') && (length(line) == 1)))
                        continue;
                     end
                     
                     if (idFile == 3)
                        line = regexprep(line, '\|', ';');
                     end
                     
                     fprintf(fIdOut, '%d;%s\n', cycleList(idCy), line);
                     fprintf(fIdOut2, '%s;%d;%s\n', floatWmo, cycleList(idCy), line);
                  end
                  
                  fclose(fId);
                  
               end
               
               if (idCy == length(cycleList))
                  fclose(fIdOut);
                  fclose(fIdOut2);
               end
            end
         end
      end
   end
end

return;
