% ------------------------------------------------------------------------------
% Duplicate a list of files from a directory to another one.
%
% SYNTAX :
%  [o_nbFiles] = duplicate_files_ir_cts5(a_listFileNames, a_inputDir, a_outputDir, a_floatNum)
%
% INPUT PARAMETERS :
%   a_listFileNames : names of the files to duplicate
%   a_inputDir      : input directory
%   a_outputDir     : output directory
%   a_floatNum      : concerned float WMO number
%
% OUTPUT PARAMETERS :
%   o_nbFiles : number of files duplicated
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_nbFiles] = duplicate_files_ir_cts5(a_listFileNames, a_inputDir, a_outputDir, a_floatNum)

% output parameters initialization
o_nbFiles = 0;

% default values
global g_decArgo_janFirst1950InMatlab;

% SBD sub-directories
global g_decArgo_updatedDirectory;
global g_decArgo_unusedDirectory;


% type of files to copy
fileTypeList = [ ...
   {'_apmt'} {'.ini'}; ...
   {'_payload'} {'.xml'}; ...
   {'_payload_'} {'.txt'}; ...
   {'_autotest_'} {'.txt'}; ...
   {'_technical'} {'.txt'}; ...
   {'_default_'} {'.txt'}; ...
   {'_sbe41'} {'.hex'}; ...
   {'_payload'} {'.bin'}; ...
   {'_system_'} {'.hex'}; ...
   ];

% copy the files of the list
for idFile = 1:length(a_listFileNames)
   
   % control file type
   [~, fileName, fileExtension] = fileparts(a_listFileNames{idFile});
      
   ok = 0;
   for idType = 1:size(fileTypeList, 1)
      if (~isempty(strfind(fileName, fileTypeList{idType, 1})) && ...
            strcmp(fileExtension, fileTypeList{idType, 2}))
         ok = 1;
         break
      end
   end
   
   % copy file
   if (ok)
      
      fileName = a_listFileNames{idFile};
      fileNameIn = [a_inputDir '/' fileName];
      fileInfo = dir(fileNameIn);
      fileNameOut = [ ...
         fileName(1:end-4) '_' ...
         datestr(datenum(fileInfo.date, 'dd-mmmm-yyyy HH:MM:SS'), 'yyyymmddHHMMSS') ...
         fileName(end-3:end)];
      
      filePathNameOut = [a_outputDir '/' fileNameOut];
      if (exist(filePathNameOut, 'file') == 2)
         % file exists
         %          fprintf('%s => unchanged\n', fileNameOut);
      else
         fileExist = dir([a_outputDir '/' fileName(1:end-4) '_*' fileName(end-3:end)]);
         if (~isempty(fileExist))
            % update existing file
            move_file([a_outputDir '/' fileExist.name], g_decArgo_updatedDirectory);
            copy_file(fileNameIn, filePathNameOut);
            o_nbFiles = o_nbFiles + 1;
            %             fprintf('%s => copy (update of %s)\n', fileNameOut,fileExist.name);
         else
            % copy new file
            copy_file(fileNameIn, filePathNameOut);
            o_nbFiles = o_nbFiles + 1;
            %             fprintf('%s => copy\n', fileNameOut);
         end
      end
   end
end

% clean files to be processed
switch(a_floatNum)
   case 4901801
      % files 019b_* should be kept
      delFile = dir([a_outputDir '/019b_*']);
      for idF = 1:length(delFile)
         move_file([a_outputDir '/' delFile(idF).name], g_decArgo_unusedDirectory);
         %          fprintf('MISC: %s => not used\n', delFile(idF).name);
      end
      
   case 4901802
      % file 013b_system_00007#01.hex is not the first part of
      % 013b_system_00007.hex => only 013b_system_00007#02.hex should be kept
      delFile = dir([a_outputDir '/013b_system_00007#01*.hex']);
      if (~isempty(delFile))
         move_file([a_outputDir '/' delFile.name], g_decArgo_unusedDirectory);
      end
      %       fprintf('MISC: %s => not used\n', delFile.name);
      % 013b_system_00007#02.hex should be renamed 013b_system_00007#02.hex
      movFile = dir([a_outputDir '/013b_system_00007#02*.hex']);
      if (~isempty(movFile))
         move_file([a_outputDir '/' movFile.name], ...
            [a_outputDir '/' regexprep(movFile.name, '#02', '')]);
      end
      
   case 4901805
      % files 012b_* should not be kept
      delFile = dir([a_outputDir '/012b_*']);
      for idF = 1:length(delFile)
         move_file([a_outputDir '/' delFile(idF).name], g_decArgo_unusedDirectory);
      end
      
   case 6902667
      % there are 2 deployments of the same float => use only files dated
      % after july 2016
      startDate = gregorian_2_julian_dec_argo('2016/07/01 00:00:00');
      files = dir(a_outputDir);
      for idF = 1:length(files)
         if (~files(idF).isdir)
            if (datenum(files(idF).date, 'dd-mmmm-yyyy HH:MM:SS')-g_decArgo_janFirst1950InMatlab < startDate)
               move_file([a_outputDir '/' files(idF).name], g_decArgo_unusedDirectory);
               %                fprintf('MISC: %s => not used\n', files(idF).name);
            end
         end
      end
      
   case 6902669
      % files 3a9b_* should not be kept
      delFile = dir([a_outputDir '/3a9b_*']);
      for idF = 1:length(delFile)
         move_file([a_outputDir '/' delFile(idF).name], g_decArgo_unusedDirectory);
      end
      
   case 6902829
      % file 3aa9_system_00116.hex should not be kept
      delFile = dir([a_outputDir '/3aa9_system_00116_*.hex']);
      if (~isempty(delFile))
         move_file([a_outputDir '/' delFile.name], g_decArgo_unusedDirectory);
      end
      
   case 6902968
      % file 4279_047_00_payload.xml doesn't contain configuration at
      % launch for UVP sensor => we should use file _payload_190528_073923.xml
      delFile = dir([a_outputDir '/4279_047_00_payload_*.xml']);
      if (~isempty(delFile))
         inFile = dir([a_inputDir '/_payload_190528_073923.xml']);
         if (~isempty(inFile))
            move_file([a_outputDir '/' delFile.name], g_decArgo_unusedDirectory);
            outFile = [a_outputDir '/4279_047_00_payload_' ...
               datestr(datenum(inFile.date, 'dd-mmmm-yyyy HH:MM:SS'), 'yyyymmddHHMMSS') '.xml'];
            copy_file([a_inputDir '/' inFile.name], outFile);
         end
      end
end

return
