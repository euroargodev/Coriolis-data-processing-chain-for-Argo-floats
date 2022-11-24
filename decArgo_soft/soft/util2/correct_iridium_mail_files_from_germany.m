% ------------------------------------------------------------------------------
% When Iridium mail files come from (german) PI personal mailbox use this tool
% to correct the mail contents:
% "Time of Session (UTC): Mon Jan 21 06:04:01 2019 Session Status: 00 - Transf=\n er OK Message Size (bytes): 300"
% is corrected to
% "Time of Session (UTC): Mon Jan 21 06:04:01 2019 Session Status: 00 - Transfer \nOK Message Size (bytes): 300"
%
% SYNTAX :
%   correct_iridium_mail_files_from_germany
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
%   03/13/2019 - RNU - creation
% ------------------------------------------------------------------------------
function correct_iridium_mail_files_from_germany()

% input directory
INPUT_DIR_NAME = 'C:\Users\lrichier\Desktop\MISSING_DATA\20190312\';
INPUT_DIR_NAME = 'C:\Users\jprannou\Contacts\Desktop\6903703\6903703_recup\mails_OUT\300234067778190\';

% output directory
OUTPUT_DIR_NAME = 'C:\Users\lrichier\Desktop\MISSING_DATA\OUT\';
OUTPUT_DIR_NAME = 'C:\Users\lrichier\Desktop\MISSING_DATA\20190312\';
OUTPUT_DIR_NAME = 'C:\Users\jprannou\Contacts\Desktop\6903703\6903703_recup\mails_OUT2\300234067778190';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';


% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'correct_iridium_mail_files_from_germany_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% check the input directory
if ~(exist(INPUT_DIR_NAME, 'dir') == 7)
   fprintf('ERROR: Input directory doesn''t exist - exit\n');
   return
end

% create the output directory
if ~(exist(OUTPUT_DIR_NAME, 'dir') == 7)
   fprintf('Creating directory %s\n', OUTPUT_DIR_NAME);
   mkdir(OUTPUT_DIR_NAME);
end

% process the files of the input directory
files = dir(INPUT_DIR_NAME);
for idF = 1:length(files)
   
   fileName = files(idF).name;
   filePathName = [INPUT_DIR_NAME '/' fileName];
   
   if (exist(filePathName, 'file') == 2)
      
      fId = fopen(filePathName, 'r');
      if (fId == -1)
         fprintf('Error while opening file : %s\n', filePathName);
      end
      
      lines = [];
      while 1
         line = fgetl(fId);
         if (line == -1)
            break
         end
         lines{end+1} = line;
      end
      
      fclose(fId);
      
      idF = cellfun(@(x) strfind(lines, x), {'Transf='}, 'UniformOutput', 0);
      if (~isempty([idF{:}]))
         idF1 = cellfun(@(x) strfind(lines, x), {'Time of Session (UTC):'}, 'UniformOutput', 0);
         idF2 = cellfun(@(x) strfind(lines, x), {'Transf='}, 'UniformOutput', 0);
         idF3 = cellfun(@(x) strfind(lines, x), {'Message Size'}, 'UniformOutput', 0);
         idF1 = find(~cellfun(@isempty, idF1{:}) == 1);
         idF2 = find(~cellfun(@isempty, idF2{:}) == 1);
         idF3 = find(~cellfun(@isempty, idF3{:}) == 1);
         if (~isempty(idF1) && ~isempty(idF2) && ~isempty(idF3))
            if ((idF1 == idF2) && (idF3 == idF1+1))
               line1 = lines{idF1};
               line2 = lines{idF3};
               idF01 = strfind(line1, 'Transf=');
               idF02 = strfind(line2, 'Message Size');
               line3 = [line1(1:idF01+length('Transf')-1) line2(1:idF02-1)];
               line4 = line2(idF02:end);
               lines{idF1} = line3;
               lines{idF3} = line4;
               
               fprintf('Corrected file : %s\n', fileName);

               filePathNameOut = [OUTPUT_DIR_NAME '/' fileName];
               
               % write lines in output file
               fIdOut = fopen(filePathNameOut, 'w');
               if (fIdOut == -1)
                  fprintf('Error while opening file : %s\n', filePathNameOut);
                  return
               end
               fprintf(fIdOut, '%s\n', lines{:});
               fclose(fIdOut);
            end
         end
      end
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
