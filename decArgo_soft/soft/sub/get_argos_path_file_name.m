% ------------------------------------------------------------------------------
% Get the path file name of the Argos data file of a given cycle or the cycle
% numbers of the Argos existing data files.
%
% SYNTAX :
%  [o_argosPathFileName, o_argosExistingCycles] = get_argos_path_file_name( ...
%    a_floatArgosId, a_floatNum, a_cycleNum, a_floatEndDate)
%
% INPUT PARAMETERS :
%   a_floatArgosId : float PTT number
%   a_floatNum     : float WMO number
%   a_cycleNum     : cycle number (set to -1 if o_argosExistingCycles is wanted)
%   a_floatEndDate      : end date of the data to process
%
% OUTPUT PARAMETERS :
%   o_argosPathFileName   : corresponding Argos file path name(s)(filled when
%                           a_cycleNum ~= -1)
%   o_argosExistingCycles : cycle list of existing Argos data file (filled when
%                           a_cycleNum == -1)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/03/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_argosPathFileName, o_argosExistingCycles] = get_argos_path_file_name( ...
   a_floatArgosId, a_floatNum, a_cycleNum, a_floatEndDate)

% output parameters initialization
o_argosPathFileName = [];
o_argosExistingCycles = [];

% configuration values
global g_decArgo_hexArgosFileFormat;
global g_decArgo_dirInputHexArgosFileFormat1;
global g_decArgo_dirInputHexArgosFileFormat2;
global g_decArgo_hexArgosDataDirStruct;

% RT processing flag
global g_decArgo_realtimeFlag;

% report information structure
global g_decArgo_reportStruct;

% global input parameter information
global g_decArgo_processModeAll;

% Argos Id temporary sub-directory
global g_decArgo_tmpArgosIdDirectory;

% Argos existing files
global g_decArgo_existingArgosFileCycleNumber;
global g_decArgo_existingArgosFileSystemDate;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;


% find the corresponding Argos file name
argosDirName = [];
if (g_decArgo_hexArgosFileFormat == 1)
   argosDirName = [g_decArgo_dirInputHexArgosFileFormat1 '/'];
   
   if ((g_decArgo_realtimeFlag == 1) && (g_decArgo_processModeAll == 0))
      if (~isempty(g_decArgo_tmpArgosIdDirectory) && (exist(g_decArgo_tmpArgosIdDirectory, 'dir') == 7))
         argosDirName = [g_decArgo_tmpArgosIdDirectory '/'];
      else
         if (isempty(g_decArgo_tmpArgosIdDirectory))
            fprintf('ERROR: Empty variable g_decArgo_tmpArgosIdDirectory\n');
            return
         else
            fprintf('ERROR: Argos directory not found: %s\n', g_decArgo_tmpArgosIdDirectory);
            return
         end
      end
   end
elseif (g_decArgo_hexArgosFileFormat == 2)
   argosDirName = [g_decArgo_dirInputHexArgosFileFormat2 '/'];
end

if ~((g_decArgo_realtimeFlag == 1) && (g_decArgo_processModeAll == 0))
   if (g_decArgo_hexArgosDataDirStruct == 1)
      argosDirName = [argosDirName sprintf('%05d_%07d', a_floatArgosId, a_floatNum) '/'];
   elseif (g_decArgo_hexArgosDataDirStruct == 3)
      argosDirName = [argosDirName sprintf('%06d', a_floatArgosId) '/'];
   end
end

if ~(exist(argosDirName, 'dir') == 7)
   fprintf('ERROR: Argos directory not found: %s\n', argosDirName);
   return
end

if (a_cycleNum ~= -1)

   % find the Argos path file name(s) for this cycle
   argosFile = dir([argosDirName ...
      sprintf('*%d*%d_%03d*.txt', a_floatArgosId, a_floatNum, a_cycleNum)]);
   
   % do not consider files dated after float end date
   if (a_floatEndDate ~= g_decArgo_dateDef)
      
      idNotUse = [];
      for id = 1:length(argosFile)
         fileName = argosFile(id).name;
         fileDate = datenum(fileName(8:26), 'yyyy-mm-dd-HH-MM-SS') - g_decArgo_janFirst1950InMatlab;
         if (fileDate > a_floatEndDate)
            idNotUse = [idNotUse; id];
         end
      end
      argosFile(idNotUse) = [];
   end
   
   if (~isempty(argosFile))
      o_argosPathFileName = [];
      for id = 1:length(argosFile)
         o_argosPathFileName{id} = [argosDirName argosFile(id).name];
         
         if (g_decArgo_realtimeFlag == 1)
            % store information for the XML report
            g_decArgo_reportStruct.inputFiles = [g_decArgo_reportStruct.inputFiles ...
               {[argosDirName argosFile(id).name]}];
         end
      end
      %    else
      %       % should never occur because all processed cycles have an Argos file
      %       % (checked during cycle list creation)
      %       fprintf('ERROR: Float #%d Cycle #%d: argos file not found\n', ...
      %          a_floatNum, a_cycleNum);
   end
   
else
   
   % find cycle list of Argos files
   g_decArgo_existingArgosFileCycleNumber = [];
   g_decArgo_existingArgosFileSystemDate = [];
   existingCycles = [];
   argosFiles = dir([argosDirName sprintf('*%d*%d*.txt', a_floatArgosId, a_floatNum)]);
   for idFile = 1:length(argosFiles)
      cycleNumber = [];
      argosFileName = argosFiles(idFile).name;
      if (g_decArgo_hexArgosFileFormat == 1)
         [id, count, errmsg, nextIndex] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_%d.txt');
         if (isempty(errmsg) && (count == 9))
            cycleNumber = id(9);
         else
            % old file name versions
            [id, count, errmsg, nextIndex] = sscanf(argosFileName, '%d_%d-%d-%d_%d_%d.txt');
            if (isempty(errmsg))
               if (id(6) ~= 999)
                  cycleNumber = id(6);
               end
            else
               [id, count, errmsg, nextIndex] = sscanf(argosFileName, '%d_%d-%d-%d_%d_%d_%d.txt');
               if (isempty(errmsg))
                  if (id(6) ~= 999)
                     cycleNumber = id(6);
                  end
               else
                  [id, count, errmsg, nextIndex] = sscanf(argosFileName, '%d_%d-%d-%d_%d_%d_%d_%d_%d_%d.txt');
                  if (isempty(errmsg))
                     if (id(6) ~= 999)
                        cycleNumber = id(6);
                     end
                  end
               end
            end
         end
      elseif (g_decArgo_hexArgosFileFormat == 2)
         [id, count, errmsg, nextIndex] = sscanf(argosFileName, '%d_%d_%d.txt');
         if (isempty(errmsg))
            cycleNumber = id(3);
         end
      end
      if (~isempty(cycleNumber))
         existingCycles = [existingCycles; cycleNumber];
         
         g_decArgo_existingArgosFileCycleNumber = [g_decArgo_existingArgosFileCycleNumber; cycleNumber];
         fileDate = datenum(argosFiles(idFile).date, 'dd-mmmm-yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
         g_decArgo_existingArgosFileSystemDate = [g_decArgo_existingArgosFileSystemDate; fileDate];
      end
   end
   o_argosExistingCycles = sort(unique(existingCycles));
   
end

return
