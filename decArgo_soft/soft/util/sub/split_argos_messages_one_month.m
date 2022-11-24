% ------------------------------------------------------------------------------
% Split one month of Argos message files (one file for each Argos Id and each
% satellite pass).
% (Created to avoid memory leak problems in Matlab R2006b version).
%
% SYNTAX :
%  split_argos_messages_one_month(a_inputPathName, a_inputDirName, ...
%    a_outputPathName, a_timeStamp, a_subDir)
%
% INPUT PARAMETERS :
%   a_inputPathName  : path name of the input directory
%   a_inputDirName   : name of the input directory
%   a_outputPathName : path name of the output directory
%   a_timeStamp      : time stamp used with the subDir option
%   a_subDir         : create a sub-directory and add a time stamp in the output
%                      files names
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
function split_argos_messages_one_month(a_inputPathName, a_inputDirName, ...
   a_outputPathName, a_timeStamp, a_subDir)

DIR_INPUT_ARGOS_FILES = [a_inputPathName '/' a_inputDirName '/'];
if (a_subDir == 1)
   DIR_OUTPUT_ARGOS_FILES = [a_outputPathName '/' a_inputDirName '_' a_timeStamp '/'];
else
   DIR_OUTPUT_ARGOS_FILES = [a_outputPathName '/'];
end

% default values
global g_decArgo_janFirst1950InMatlab;

% default values initialization
init_default_values;


% create the output directory
if ~(exist(DIR_OUTPUT_ARGOS_FILES, 'dir') == 7)
   mkdir(DIR_OUTPUT_ARGOS_FILES);
end

% process the files of the input directory
files = dir(DIR_INPUT_ARGOS_FILES);
nbFiles = length(files);
for idFile = 1:nbFiles

   fileName = files(idFile).name;
   filePathName = [DIR_INPUT_ARGOS_FILES '/' fileName];

   fprintf('%03d/%03d %s\n', idFile, nbFiles, fileName);

   if (exist(filePathName, 'file') == 2)

      % open and process the current input file
      fIdIn = fopen(filePathName, 'r');
      if (fIdIn == -1)
         fprintf('Error while opening file : %s\n', filePathName);
         return;
      end

      clear text;
      clear floatArgosId;
      clear dateList;
      text = [];
      floatArgosId = [];
      dateList = [];
      lineNum = 0;
      while (1)
         line = fgetl(fIdIn);
         lineNum = lineNum + 1;
         if (line == -1)
            if (~isempty(floatArgosId))

               % save the data of the previous satellite pass

               % create the output directory
               dirFloatOutPut = [DIR_OUTPUT_ARGOS_FILES '/' sprintf('%06d', floatArgosId) '/'];
               if ~(exist(dirFloatOutPut, 'dir') == 7)
                  mkdir(dirFloatOutPut);
               end

               % create the output file name
               if (a_subDir == 1)
                  outputFileName = sprintf('%06d_%s_%s', ...
                     floatArgosId, ...
                     datestr(min(dateList)+g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'), ...
                     a_inputDirName);
               else
                  outputFileName = sprintf('%06d_%s', ...
                     floatArgosId, ...
                     datestr(min(dateList)+g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'));
               end

               stop = 0;
               fileNum = 1;
               while (~stop)
                  outputFilePathName = [dirFloatOutPut '/' ...
                     sprintf('%s_%03d.txt', outputFileName, fileNum)];
                  if (exist(outputFilePathName, 'file') == 2)
                     fileNum = fileNum + 1;
                  else
                     stop = 1;
                  end
                  if (fileNum == 1000)
                     fprintf('ERROR: Unable to find an output file name %s\n', outputFilePathName);
                  end
               end

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

            end

            break;
         end

         % empty line
         if (strcmp(deblank(line), ''))
            continue;
         end

         if (line(1) == '>')
            line = line(2:end);
         end

         if (isempty(floatArgosId))
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
               % store the data of the current satellite pass

               floatArgosId = val(2);
               text{end+1} = line;

               if (date1 == 1)
                  date = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
                     val(7), val(8), val(9), val(10), val(11), val(12)));
                  dateList = [dateList; date];
               end
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
               % save the data of the previous satellite pass

               % create the output directory
               dirFloatOutPut = [DIR_OUTPUT_ARGOS_FILES '/' sprintf('%06d', floatArgosId) '/'];
               if ~(exist(dirFloatOutPut, 'dir') == 7)
                  mkdir(dirFloatOutPut);
               end

               % create the output file name
               if (a_subDir == 1)
                  outputFileName = sprintf('%06d_%s_%s', ...
                     floatArgosId, ...
                     datestr(min(dateList)+g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'), ...
                     a_inputDirName);
               else
                  outputFileName = sprintf('%06d_%s', ...
                     floatArgosId, ...
                     datestr(min(dateList)+g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'));
               end

               stop = 0;
               fileNum = 1;
               while (~stop)
                  outputFilePathName = [dirFloatOutPut '/' ...
                     sprintf('%s_%03d.txt', outputFileName, fileNum)];
                  if (exist(outputFilePathName, 'file') == 2)
                     fileNum = fileNum + 1;
                  else
                     stop = 1;
                  end
                  if (fileNum == 1000)
                     fprintf('ERROR: Unable to find an output file name %s\n', outputFilePathName);
                  end
               end

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
               
               clear text;
               clear floatArgosId;
               clear dateList;
               text = [];
               floatArgosId = [];
               dateList = [];

               % store the data of the current satellite pass
               floatArgosId = val(2);
               text{end+1} = line;

               if (date1 == 1)
                  date = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
                     val(7), val(8), val(9), val(10), val(11), val(12)));
                  dateList = [dateList; date];
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
                     dateList = [dateList; date];
                  end
               else
                  fprintf('Line #%d: %s\n', lineNum, line);
               end
            end
         end
      end

      fclose(fIdIn);
   end
end

return;
