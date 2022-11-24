% ------------------------------------------------------------------------------
% Used to correct mail files inconsistencies for float #6903703
%
% SYNTAX :
%   correct_iridium_mail_files_for_6903703
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
%   07/18/2020 - RNU - creation
% ------------------------------------------------------------------------------
function correct_iridium_mail_files_for_6903703()

% input directory
INPUT_DIR_NAME = 'C:\Users\jprannou\Contacts\Desktop\6903703\6903703_recup\mails_OUT\300234067778190\';
INPUT_DIR_NAME = 'C:\Users\jprannou\Contacts\Desktop\6903703\6903703_recup\mails_OUT\300234068833480\';

% output directory
OUTPUT_DIR_NAME = 'C:\Users\jprannou\Contacts\Desktop\6903703\6903703_recup\mails_OUT2\300234067778190';
OUTPUT_DIR_NAME = 'C:\Users\jprannou\Contacts\Desktop\6903703\6903703_recup\mails_OUT2\300234068833480';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\'; 


% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'correct_iridium_mail_files_for_6903703_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
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
         lines{end+1} = regexprep(line, ' =3D ', ' = ');
      end
      
      fclose(fId);
      
      idF = cellfun(@(x) strfind(lines, x), {'Transf='}, 'UniformOutput', 0);
      if (~isempty([idF{:}]))
         
         modif = 0;
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
               idF03 = strfind(line3, 'Session Status:');
               line3bis = line3(idF03:end);
               line3 = line3(1:idF03-2);
               lines(idF3+1:end+1) = lines(idF3:end);
               lines{idF1} = line3;
               lines{idF1+1} = line3bis;
               lines{idF3+1} = line4;
               modif = 1;
            end
         end
         
         idF4 = cellfun(@(x) strfind(lines, x), {'Unit Location:'}, 'UniformOutput', 0);
         idF4 = find(~cellfun(@isempty, idF4{:}) == 1);
         if (~isempty(idF4))
            line4 = lines{idF4};
            idF04 = strfind(line4, 'CEPradius');
            line4bis = line4(idF04:end);
            line4 = line4(1:idF04-2);
            lines(idF4+1:end+1) = lines(idF4:end);
            lines{idF4} = line4;
            lines{idF4+1} = line4bis;
            modif = 1;
         end
         
         if (modif == 1)
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

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
