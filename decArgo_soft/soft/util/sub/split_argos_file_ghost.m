% ------------------------------------------------------------------------------
% Split an Argos cycle file (the last satellite pass is moved to a second file).
%
% SYNTAX :
%  [o_newFiles] = split_argos_file_ghost(a_filePathName, a_floatNum, a_argosId)
%
% INPUT PARAMETERS :
%   a_filePathNames : input Argos cycle file to split
%   a_floatNum      : float WMO number
%   a_argosId       : float Argos Id number
%
% OUTPUT PARAMETERS :
%   o_newFiles : created file path names
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/04/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_newFiles] = split_argos_file_ghost(a_filePathName, a_floatNum, a_argosId)

% output parameters initialization
o_newFiles = [];

% default values
global g_decArgo_janFirst1950InMatlab;


% open and process the Argos input file
fIdIn = fopen(a_filePathName, 'r');
if (fIdIn == -1)
   fprintf('ERROR: Error while opening file : %s\n', a_filePathName);
   return;
end

text = [];
text1 = [];
text2 = [];
satDateList = [];
dataDateList = [];
dataDateList1 = [];
dataDateList2 = [];
lineNum = 0;
while (1)
   line = fgetl(fIdIn);
   lineNum = lineNum + 1;
   
   if (line == -1)
      
      % store the data of the last satellite pass in the correct array
      if (~isempty(dataDateList))
         % in the second file
         text2 = [text2 text];
         dataDateList2 = [dataDateList2; dataDateList];
      elseif (~isempty(satDateList))
         % in the second file
         text2 = [text2 text];
      else
         % we only have pass header(s) without location => ignored
      end
      
      % clear the current arrays
      text = [];
      satDateList = [];
      dataDateList = [];
      
      break;
   end
   
   % empty line
   if (strcmp(deblank(line), ''))
      continue;
   end
   
   if (isempty(text))
      % look for a new satellite pass header
      ok1 = 0;
      date1 = 0;
      val = [];
      [val3, count3, errmsg3, nextindex3] = sscanf(line, '%d %d %d %d %c %d-%d-%d %d:%d:%f %d %x %x %x %x');
      if (isempty(errmsg3) && (count3 == 16) && (isempty(find(val3(13:end) > 255, 1))))
         ok1 = 1;
         val = val3;
         date1 = 1;
      else
         [val2, count2, errmsg2, nextindex2] = sscanf(line, '%d %d %d %d %c');
         if (isempty(errmsg2) && (count2 == 5) && (val2(2) > 99))
            ok1 = 1;
            val = val2;
         else
            [val1, count1, errmsg1, nextindex1] = sscanf(line, '%d %d %d %d %c %c %d-%d-%d %d:%d:%f %f %f %f %d');
            if ((isempty(errmsg1) && (count1 == 16)))
               ok1 = 1;
               val = val1;
               date1 = 1;
            end
         end
      end
      
      if (ok1 == 1)
         % store the data of the current satellite pass
         
         text{end+1} = line;
         
         if (date1 == 1)
            date = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
               val(7), val(8), val(9), val(10), val(11), val(12)));
            satDateList = [satDateList; date];
         end
      else
         fprintf('Unexpected format in line #%d: %s\n', lineNum, line);
      end
   else
      
      % look for satellite pass header
      ok1 = 0;
      date1 = 0;
      val = [];
      [val3, count3, errmsg3, nextindex3] = sscanf(line, '%d %d %d %d %c %d-%d-%d %d:%d:%f %d %x %x %x %x');
      if (isempty(errmsg3) && (count3 == 16) && (isempty(find(val3(13:end) > 255, 1))))
         ok1 = 1;
         val = val3;
         date1 = 1;
      else
         [val2, count2, errmsg2, nextindex2] = sscanf(line, '%d %d %d %d %c');
         if (isempty(errmsg2) && (count2 == 5) && (val2(2) > 99))
            ok1 = 1;
            val = val2;
         else
            [val1, count1, errmsg1, nextindex1] = sscanf(line, '%d %d %d %d %c %c %d-%d-%d %d:%d:%f %f %f %f %d');
            if ((isempty(errmsg1) && (count1 == 16)))
               ok1 = 1;
               val = val1;
               date1 = 1;
            end
         end
      end
      
      if (ok1 == 1)
         
         % store the data of the previous satellite pass in the correct array
         if (~isempty(dataDateList))
            % in the first file
            text1 = [text1 text];
            dataDateList1 = [dataDateList1; dataDateList];
         elseif (~isempty(satDateList))
            % in the first file
            text1 = [text1 text];
         else
            % we only have pass header(s) without location => ignored
         end
         
         % clear the current arrays
         text = [];
         satDateList = [];
         dataDateList = [];
         
         % store the data of the current satellite pass
         
         text{end+1} = line;
         
         if (date1 == 1)
            date = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
               val(7), val(8), val(9), val(10), val(11), val(12)));
            satDateList = [satDateList; date];
         end
      else
         
         % look for all expected formats
         ok2 = 0;
         date2 = 0;
         val = [];
         [val20, count20, errmsg20, nextindex20] = sscanf(line, '%x %x %x %x');
         if (isempty(errmsg20) && ((count20 == 4) || (count20 == 3) || (count20 == 1)) && (isempty(find(val20(1:end) > 255, 1))))
            ok2 = 1;
         else
            [val10, count10, errmsg10, nextindex10] = sscanf(line, '%d-%d-%d %d:%d:%f %d %x %x %x %x');
            if ((isempty(errmsg10) && (count10 == 11) && (isempty(find(val10(8:end) > 255, 1)))))
               ok2 = 1;
               val = val10;
               date2 = 1;
            else
               [val11, count11, errmsg11, nextindex11] = sscanf(line, '%d-%d-%d %d:%d:%f %d %x %x %x');
               if (isempty(errmsg11) && (count11 == 10) && (isempty(find(val11(8:end) > 255, 1))))
                  ok2 = 1;
                  val = val11;
                  date2 = 1;
               else
                  [val21, count21, errmsg21, nextindex21] = sscanf(line, '%d-%d-%d %d:%d:%f %d %c %x %x %x');
                  if (isempty(errmsg21) && (count21 == 11) && (isempty(find(val21(9:end) > 255, 1))))
                     ok2 = 1;
                     val = val21;
                     date2 = 1;
                  else
                     [val12, count12, errmsg12, nextindex12] = sscanf(line, '%d-%d-%d %d:%d:%f %d %8c %x %x %x');
                     if (isempty(errmsg12) && (count12 == 11) && (isempty(find(val12(9:end) > 255, 1))))
                        ok2 = 1;
                        val = val12;
                        date2 = 1;
                     else
                        [val13, count13, errmsg13, nextindex13] = sscanf(line, '%d-%d-%d %d:%d:%f %d'); % uniquement pour ne pas rompre le flux
                        if (isempty(errmsg13) && (count13 == 7))
                           ok2 = 1;
                           val = val13;
                           date2 = 1;
                        else
                           [val14, count14, errmsg14, nextindex14] = sscanf(line, '%d-%d-%d %d:%d:%f %d %8c'); % uniquement pour ne pas rompre le flux
                           if (isempty(errmsg14) && (count14 == 8))
                              ok2 = 1;
                              val = val14;
                              date2 = 1;
                           end
                        end
                     end
                  end
               end
            end
         end
         
         if (ok2 == 1)
            
            text{end+1} = line;
            
            if (date2 == 1)
               date = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
                  val(1), val(2), val(3), val(4), val(5), val(6)));
               dataDateList = [dataDateList; date];
            end
         else
            fprintf('Unexpected format in line #%d: %s\n', lineNum, line);
         end
      end
   end
end

fclose(fIdIn);

% move the input Argos file
[filePath, fileName, fileExt] = fileparts(a_filePathName);
filePathNameToDelete = [filePath fileName '_TO_DELETE' fileExt];
movefile(a_filePathName, filePathNameToDelete);

% create the new Argos files
for idF = 1:2
   eval(['text = text' num2str(idF) ';']);
   eval(['dataDateList = dataDateList' num2str(idF) ';']);
   
   % create the output file name
   if (idF == 1)
      outputFilePathName = a_filePathName;
   else
      outputFileName = sprintf('%06d_%s_%d_GGG.txt', ...
         a_argosId, ...
         datestr(min(dataDateList)+g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'), ...
         a_floatNum);
      outputFilePathName = [filePath '/' outputFileName];
   end
   
   if (exist(outputFilePathName, 'file') == 2)
      fprintf('ERROR: Argos cycle file already exist: %s\n', ...
         outputFilePathName);
      return;
   else
      
      % store the data in the output file
      fIdOut = fopen(outputFilePathName, 'wt');
      if (fIdOut == -1)
         fprintf('ERROR: Unable to open file: %s\n', outputFilePathName);
         return;
      end
      
      for id = 1:length(text)
         fprintf(fIdOut, '%s\n', text{id});
      end
      
      fclose(fIdOut);
      
      o_newFiles{end+1} = outputFilePathName;
   end
end

% move the input Argos file
delete(filePathNameToDelete);

return;
