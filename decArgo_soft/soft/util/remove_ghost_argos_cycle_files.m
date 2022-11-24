% ------------------------------------------------------------------------------
% Remove the first/last satellite pass from an Argos cycle file.
%
% SYNTAX :
% remove_ghost_argos_cycle_files(WMO, cycle_number, 'F' or 'L') => remove first (if 'F') or last (if 'L') satellite pass from Argos cycle file of float #WMO and cycle number #cycle_number
%
% INPUT PARAMETERS :
%   WMO          : WMO number of the float
%   cycle_number : cycle number of the Argos file
%   'F' or 'L'   : remove the first or last satellite pass
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/15/2016 - RNU - creation
% ------------------------------------------------------------------------------
function remove_ghost_argos_cycle_files(varargin)

% directory of the Argos cycle files
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160914\fichiers_cycle_apex_233_floats_bascule_20160823_CORRECT_FINAL\';


% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values initialization
init_default_values;


% configuration parameters
configVar = [];
configVar{end+1} = 'FLOAT_INFORMATION_FILE_NAME';

% get configuration parameters
g_decArgo_realtimeFlag = 0;
g_decArgo_delayedModeFlag = 0;
[configVal, unusedVarargin, inputError] = get_config_dec_argo(configVar, []);
floatInformationFileName = configVal{1};

if (nargin ~= 3)
   fprintf('Bad input parameters!\n');
   fprintf('Expecting:\n');
   fprintf('   remove_ghost_argos_cycle_files(WMO, cycle_number, ''F'' or ''L'') => remove first (if ''F'') or last (if ''L'') satellite pass from Argos cycle file of float #WMO and cycle number #cycle_number\n');
   fprintf('aborted ...\n');
   return
else
   floatNum = varargin{1};
   cycleNum = varargin{2};
   first = varargin{3};
   
   if ((upper(first) ~= 'F') && (upper(first) ~= 'L'))
      fprintf('Bad input parameters!\n');
      fprintf('Expecting:\n');
      fprintf('   remove_ghost_argos_cycle_files(WMO, cycle_number, ''F'' or ''L'') => remove first (if ''F'') or last (if ''L'') satellite pass from Argos cycle file of float #WMO and cycle number #cycle_number\n');
      fprintf('aborted ...\n');
      return
   else
      firstFlag = 1;
      if (upper(first) ~= 'F')
         firstFlag = 0;
      end
   end
end

% check the input directory
if ~(exist(DIR_INPUT_ARGOS_FILES, 'dir') == 7)
   fprintf('ERROR: The Argos cycle files directory %s does not exist => exit\n', DIR_INPUT_ARGOS_FILES);
   return
end

% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

% find current float Argos Id
idF = find(listWmoNum == floatNum, 1);
if (isempty(idF))
   fprintf('ERROR: No information on float #%d => exit\n', floatNum);
   return
end
floatArgosId = str2num(listArgosId{idF});

% check the Argos files of the float
dirFloat = [DIR_INPUT_ARGOS_FILES '/' sprintf('%06d', floatArgosId) '/'];
argosFiles = dir([dirFloat '/' sprintf('%06d*%d_%03d.txt', floatArgosId, floatNum, cycleNum)]);
if (length(argosFiles) == 1)
   
   argosFileName = argosFiles(1).name;
   argosFilePathName = [dirFloat '/' argosFileName];
   
   % create a common save directory
   saveDir = [dirFloat '/save/'];
   if ~(exist(saveDir, 'dir') == 7)
      fprintf('Creating directory %s\n', saveDir);
      mkdir(saveDir);
   end
   % create a specific save directory
   saveDirNow = [saveDir '/save_' datestr(now, 'yyyymmddTHHMMSS') '/'];
   if ~(exist(saveDirNow, 'dir') == 7)
      fprintf('Creating directory %s\n', saveDirNow);
      mkdir(saveDirNow);
   end

   % duplicate the input file
   fprintf('Saving file %s to directory %s\n', argosFileName, saveDirNow);
   copy_file(argosFilePathName, saveDirNow);

   % remove the first/last satellite pass
   [newFiles] = remove_satellite_path(argosFilePathName, floatNum, cycleNum, floatArgosId, firstFlag);
   
   if (~isempty(newFiles))
      if (firstFlag == 1)
         fprintf('File modified %s\n', newFiles{2});
         fprintf('File created %s\n', newFiles{1});
      else
         fprintf('File modified %s\n', newFiles{1});
         fprintf('File created %s\n', newFiles{2});
      end
   end
else
   if (isempty(argosFiles))
      fprintf('ERROR: Cannot find Argos cycle file for float #%d cycle #%d => aborted\n', floatNum, cycleNum);
   else
      fprintf('ERROR: Multiple Argos cycle file for float #%d cycle #%d => aborted\n', floatNum, cycleNum);
   end
end

fprintf('done\n');

return

% ------------------------------------------------------------------------------
% Split an Argos cycle file (the first or last satellite pass is moved to a
% second file).
%
% SYNTAX :
%  [o_newFiles] = remove_satellite_path(a_filePathName, a_floatNum, a_cycleNum, a_argosId, a_firstFlag)
%
% INPUT PARAMETERS :
%   a_filePathNames : input Argos cycle file to split
%   a_floatNum      : float WMO number
%   a_cycleNum      : cycle number
%   a_argosId       : float Argos Id number
%   a_firstFlag     : if 1: remove the first satellite pas, the last otherwise
%
% OUTPUT PARAMETERS :
%   o_newFiles : resulting file path names
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/15/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_newFiles] = remove_satellite_path(a_filePathName, a_floatNum, a_cycleNum, a_argosId, a_firstFlag)

% output parameters initialization
o_newFiles = [];

% default values
global g_decArgo_janFirst1950InMatlab;


% open and process the Argos input file
fIdIn = fopen(a_filePathName, 'r');
if (fIdIn == -1)
   fprintf('ERROR: Error while opening file : %s\n', a_filePathName);
   return
end

text = [];
text1 = [];
text2 = [];
satDateList = [];
dataDateList = [];
dataDateList1 = [];
dataDateList2 = [];
lineNum = 0;

if (a_firstFlag == 1)
   
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
         
         break
      end
      
      % empty line
      if (strcmp(deblank(line), ''))
         continue
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
            if (isempty(text1))
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
            else
               if (~isempty(dataDateList))
                  % in the first file
                  text2 = [text2 text];
                  dataDateList2 = [dataDateList2; dataDateList];
               elseif (~isempty(satDateList))
                  % in the first file
                  text2 = [text2 text];
               else
                  % we only have pass header(s) without location => ignored
               end
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
   
else
   
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
         
         break
      end
      
      % empty line
      if (strcmp(deblank(line), ''))
         continue
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
end

fclose(fIdIn);

% move the input Argos file
[filePath, fileName, fileExt] = fileparts(a_filePathName);
filePathNameToDelete = [filePath fileName '_TO_DELETE' fileExt];
move_file(a_filePathName, filePathNameToDelete);

% create the new Argos files
for idF = 1:2
   eval(['text = text' num2str(idF) ';']);
   eval(['dataDateList = dataDateList' num2str(idF) ';']);
   
   % create the output file name
   if (a_firstFlag == 1)
      if (idF == 1)
         outputFileName = sprintf('%06d_%s_%d_GGG.txt', ...
            a_argosId, ...
            datestr(min(dataDateList)+g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'), ...
            a_floatNum);
         outputFilePathName = [filePath '/' outputFileName];
      else         
         outputFileName = sprintf('%06d_%s_%d_%03d.txt', ...
            a_argosId, ...
            datestr(min(dataDateList)+g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'), ...
            a_floatNum, ...
            a_cycleNum);
         outputFilePathName = [filePath '/' outputFileName];
      end
   else
      if (idF == 1)
         outputFilePathName = a_filePathName;
      else
         outputFileName = sprintf('%06d_%s_%d_GGG.txt', ...
            a_argosId, ...
            datestr(min(dataDateList)+g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'), ...
            a_floatNum);
         outputFilePathName = [filePath '/' outputFileName];
      end
   end
   
   if (exist(outputFilePathName, 'file') == 2)
      fprintf('ERROR: Argos cycle file already exist: %s\n', ...
         outputFilePathName);
      return
   else
      
      % store the data in the output file
      fIdOut = fopen(outputFilePathName, 'wt');
      if (fIdOut == -1)
         fprintf('ERROR: Unable to open file: %s\n', outputFilePathName);
         return
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

return
