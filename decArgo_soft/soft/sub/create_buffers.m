% ------------------------------------------------------------------------------
% Check SBD files of a given directory to assign a processing rank to each of
% them.
%
% SYNTAX :
%  [o_sbdFileNameList, o_sbdFileRank, o_sbdFileDate, ...
%    o_sbdFileCyNum, o_sbdFileProfNum, o_sbdFileDataType] = ...
%    create_buffers(a_dirName, a_launchDate, a_floatEndDate, a_fidTxt, a_fidCsv)
%
% INPUT PARAMETERS :
%   a_dirName      : directory of the SBD files to check
%   a_launchDate   : float launch date
%   a_floatEndDate : end date of the data to process
%   a_fidTxt       : Id of the output TXT file
%   a_fidCsv       : Id of the output CSV file
%
% OUTPUT PARAMETERS :
%   o_sbdFileNameList : name of SBD files to process
%   o_sbdFileRank     : rank of SBD files to process
%   o_sbdFileDate     : date of SBD files to process
%   o_sbdFileCyNum    : cycle number of SBD files to process
%   o_sbdFileProfNum  : profile number of SBD files to process
%   o_sbdFileDataType : packet type of SBD files to process
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/04/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_sbdFileNameList, o_sbdFileRank, o_sbdFileDate, ...
   o_sbdFileCyNum, o_sbdFileProfNum, o_sbdFileDataType] = ...
   create_buffers(a_dirName, a_launchDate, a_floatEndDate, a_fidTxt, a_fidCsv)

o_sbdFileNameList = [];
o_sbdFileRank = [];
o_sbdFileDate = [];
o_sbdFileCyNum = [];
o_sbdFileProfNum = [];
o_sbdFileDataType = [];

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;


% collect information on SBD files of the directory
tabName = [];
tabInfo = [];
sbdFiles = dir([a_dirName '/*.sbd']);
% [~, idSort] = sort([sbdFiles.datenum]);
% sbdFiles = sbdFiles(idSort);
for idFile = 1:length(sbdFiles)
   
   sbdFileName = sbdFiles(idFile).name;
   
   idFUs = strfind(sbdFileName, '_');
   dateStr = sbdFileName(idFUs(1)+1:idFUs(2)-1);
   date = datenum(dateStr, 'yyyymmddTHHMMSS') - g_decArgo_janFirst1950InMatlab;
   typeStr = sbdFileName(idFUs(2)+1:idFUs(3)-1);
   type = str2num(typeStr);
   cycleStr = sbdFileName(idFUs(3)+1:idFUs(4)-1);
   if (strcmp(cycleStr, 'xxx'))
      cycle = -1;
   else
      cycle = str2num(cycleStr);
   end
   profileStr = sbdFileName(idFUs(4)+1:idFUs(5)-1);
   if (strcmp(profileStr, 'x'))
      profile = -1;
   else
      profile = str2num(profileStr);
   end
   phaseStr = sbdFileName(idFUs(5)+1:idFUs(6)-1);
   if (strcmp(phaseStr, 'xx'))
      phase = -1;
   else
      phase = str2num(phaseStr);
   end
   sensorStr = sbdFileName(idFUs(6)+1:idFUs(7)-1);
   if (strcmp(sensorStr, 'x'))
      sensor = -1;
   else
      sensor = str2num(sensorStr);
   end
   sensorDataTypeStr = sbdFileName(idFUs(7)+1:idFUs(8)-1);
   if (strcmp(sensorDataTypeStr, 'xx'))
      sensorDataType = -1;
   else
      sensorDataType = str2num(sensorDataTypeStr);
   end

   sbdFilePathName = [a_dirName '/' sbdFileName];
   tabName{end+1} = sbdFilePathName;
   tabInfo = [tabInfo;
      [idFile -1 date type cycle profile phase sensor sensorDataType]];
end

% sort files and associated information by date
[~, idSort] = sort(tabInfo(:, 3));
tabInfo = tabInfo(idSort, :);
tabName = tabName(idSort);
tabInfoOri = tabInfo;

% ignore files when cycle # is 65535
idF = find(tabInfo(:, 5) == 65535);
if (~isempty(idF))
   tabInfo(idF, :) = [];
   fprintf('INFO: %d files ignored (cycle # is 65535)\n', length(idF));
end

% ignore files when profile # is not in the range 0-9
idF = find(tabInfo(:, 6) > 9);
if (~isempty(idF))
   fprintf('INFO: %d files ignored (profile # not in range 0-9)\n', length(idF));
   %    fprintf('%d\n', tabInfo(idF, 1));
   tabInfo(idF, :) = [];
end

% ignore files received before float launch date
idF = find(tabInfo(:, 3) < a_launchDate);
if (~isempty(idF))
   fprintf('DEC_INFO: %d files ignored (dated before float launch date)\n', length(idF));
   %    fprintf('%d\n', tabInfo(idF, 1));
   tabInfo(idF, :) = [];
end

% ignore files received after float end date
if (a_floatEndDate ~= g_decArgo_dateDef)
   idF = find(tabInfo(:, 3) > a_floatEndDate);
   if (~isempty(idF))
      fprintf('DEC_INFO: %d files ignored (dated after float end date)\n', length(idF));
      %    fprintf('%d\n', tabInfo(idF, 1));
      tabInfo(idF, :) = [];
   end
end

% ignore files with not ordered cycle #
idDel = [];
stop = 0;
while (~stop)
   idCy = find(tabInfo(:, 5) ~= -1);
   tabInfoTmp = tabInfo(idCy, 5);
   idCut = find(diff(tabInfoTmp) < 0);
   if (~isempty(idCut))
      idDel = [idDel tabInfo(idCy(idCut(1)+1), 1)];
      tabInfo(idCy(idCut(1)+1), :) = [];
   else
      stop = 1;
   end
end
if (~isempty(idDel))
   fprintf('INFO: %d files ignored (not ordred cycle numbers)\n', length(idDel));
   %    fprintf('%d\n', idDel);
end

% process the SBD files of the directory
uCycle = sort(unique(tabInfo(:, 5)));
uCycle = uCycle(find(uCycle >= 0));
uProf = sort(unique(tabInfo(:, 6)));
uProf = uProf(find(uProf >= 0));
idEndPrev = 0;
numRank = 1;
for idCy = 1:length(uCycle)
   for idProf = 1:length(uProf)
      cyNum = uCycle(idCy);
      profNum = uProf(idProf);
      
      idCyProf = find((tabInfo(:, 5) == cyNum) & (tabInfo(:, 6) == profNum));
      if (~isempty(idCyProf))
         
         % SBD data files
         idF0 = idCyProf(find(tabInfo(idCyProf, 4) == 0));
         idF250 = idCyProf(find(tabInfo(idCyProf, 4) == 250));
         idF252 = idCyProf(find(tabInfo(idCyProf, 4) == 252));
         
         idStart = min([idF0' idF250' idF252']);
         idEnd = max([idF0' idF250' idF252']);
         
         if (~isempty(idStart))
            if ((cyNum == 0) && (profNum == 0))
               if (idStart > 1)
                  
                  % process files transmitted in the prelude phase
                  ids = 1:idStart-1;
                  dates = tabInfo(ids, 3);
                  idCut = find(diff(dates) > 10/1440);
                  
                  id1 = ids(1);
                  for id = 1:length(idCut)
                     id2 = idCut(id);
                     tabInfo(id1:id2, 2) = numRank;
                     numRank = numRank + 1;
                     id1 = id2 + 1;
                  end
                  id2 = ids(end);
                  tabInfo(id1:id2, 2) = numRank;
                  numRank = numRank + 1;
               end
            else
               if (idStart > idEndPrev + 1)
                  
                  % process end of data transmission SBD files and second iridium
                  % session SBD files
                  ids = idEndPrev:idStart-1;
                  dates = tabInfo(ids, 3);
                  idCut = find(diff(dates) > 10/1440);
                  
                  if (length(idCut) ~= 1)
                     cy = tabInfo(ids, 5);
                     prof = tabInfo(ids, 6);
                     fprintf('DEC_INFO: file #%d idCut = %d (cy #%d, prof #%d)\n', ...
                        ids(end), length(idCut), cy(end), prof(end));
                  end
                  
                  idFPrevRank = find(tabInfo(:, 2) == numRank - 1);
                  idFCyProf = find((tabInfo(idFPrevRank, 5) ~= -1) & (tabInfo(idFPrevRank, 6) ~= -1));
                  cyProfPrev = unique([tabInfo(idFPrevRank(idFCyProf), 5) tabInfo(idFPrevRank(idFCyProf), 6)], 'rows');
                  
                  id1 = ids(1)+1;
                  for id = 1:length(idCut)
                     
                     id2 = ids(idCut(id));
                     idList = id1:id2;
                     
                     if (~isempty(idList))
                        idFCyProf = find((tabInfo(idList, 5) ~= -1) & (tabInfo(idList, 6) ~= -1));
                        if (~isempty(idFCyProf))
                           cyProf = unique([tabInfo(idList(idFCyProf), 5) tabInfo(idList(idFCyProf), 6)], 'rows');
                           if ((cyProf(1) == cyProfPrev(1)) && (cyProf(2) == cyProfPrev(2)))
                              numRank = numRank - 1;
                           end
                        else
                           cy = tabInfo(idList, 5);
                           prof = tabInfo(idList, 6);
                           fprintf('DEC_INFO: file #%d empty idFCyProf (cy #%d, prof #%d)\n', ...
                              idList(end), cy(end), prof(end));
                           
                           if (id == 1)
                              numRank = numRank - 1;
                              cyProf = cyProfPrev;
                           end
                        end
                        
                        tabInfo(idList, 2) = numRank;
                        numRank = numRank + 1;
                        id1 = id2 + 1;
                        cyProfPrev = cyProf;
                     end
                  end
                  id2 = ids(end);
                  idList = id1:id2;
                  
                  idFCyProf = find((tabInfo(idList, 5) ~= -1) & (tabInfo(idList, 6) ~= -1));
                  if (~isempty(idFCyProf))
                     cyProf = unique([tabInfo(idList(idFCyProf), 5) tabInfo(idList(idFCyProf), 6)], 'rows');
                     if ((cyProf(1) == cyProfPrev(1)) && (cyProf(2) == cyProfPrev(2)))
                        numRank = numRank - 1;
                     end
                  else
                     cy = tabInfo(idList, 5);
                     prof = tabInfo(idList, 6);
                     fprintf('DEC_INFO: file #%d empty idFCyProf (cy #%d, prof #%d)\n', ...
                        idList(end), cy(end), prof(end));
                  end
                  
                  tabInfo(id1:id2, 2) = numRank;
                  numRank = numRank + 1;
               end
            end
            
            tabInfo(idStart:idEnd, 2) = numRank;
            numRank = numRank + 1;
            idEndPrev = idEnd;
         else
            fprintf('DEC_INFO: rank %d: no data\n', ...
               numRank);
            tabInfo(idCyProf, 2) = numRank;
            numRank = numRank + 1;
            idEndPrev = idCyProf(end);
         end
      end
   end
end

% process multi profile cycles
modifRank = 1;
while (modifRank)
   modifRank = 0;
   uCycle = sort(unique(tabInfo(:, 5)));
   uCycle = uCycle(find(uCycle >= 0));
   for idC = 1:length(uCycle)
      cyNum = uCycle(idC);
      
      idCy = find(tabInfo(:, 5) == cyNum);
      if (~isempty(idCy))
         profNumList = sort(unique(tabInfo(idCy, 6)));
         if (length(profNumList) > 1)
            rankNumList = sort(unique(tabInfo(idCy, 2)));
            
            % find second iridium session to ignore it
            idF1 = find(tabInfo(idCy, 2) == rankNumList(1));
            typeList = sort(unique(tabInfo(idCy(idF1), 4)));
            if (((length(unique(tabInfo(idCy(idF1), 6))) == 1) && (unique(tabInfo(idCy(idF1), 6)) == 0)) && ...
                  (~ismember(0, typeList)) && (~ismember(250, typeList)) && (~ismember(252, typeList)))
               % second iridium session data
               rankNumList = rankNumList(2:end);
               idCy = setdiff(idCy, idCy(idF1));
            end
            
            for idRk = 1:length(rankNumList)
               rankNum = rankNumList(idRk);
               idF2 = find(tabInfo(idCy, 2) == rankNum);
               profNumList2 = sort(unique(tabInfo(idCy(idF2), 6)));
               for idProf = 1:length(profNumList2)
                  pofNum = profNumList2(idProf);
                  % check if msg 253 has the same rank
                  idF253 = find((tabInfo(idCy, 6) == pofNum) & (tabInfo(idCy, 4) == 253));
                  if (~isempty(idF253))
                     rankMax = max(tabInfo(idCy(idF253), 2));
                     if (rankMax ~= rankNum)
                        % merge ranks
                        for rkNum = rankNum+1:rankMax
                           tabInfo(find(tabInfo(:, 2) == rkNum), 2) = rankNum;
                        end
                        modifRank = 1;
                        break;
                     else
                        % assign remaining files to the current rank
                        idF3 = find((tabInfo(idCy, 6) == pofNum) & (tabInfo(idCy, 2) > rankNum));
                        if (~isempty(idF3))
                           tabInfo(idCy(idF3), 2) = rankNum;
                           modifRank = 1;
                           break;
                        end
                     end
                  else
                     % assign remaining files to the current rank
                     idF3 = find((tabInfo(idCy, 6) == pofNum) & (tabInfo(idCy, 2) > rankNum));
                     if (~isempty(idF3))
                        tabInfo(idCy(idF3), 2) = rankNum;
                        modifRank = 1;
                        break;
                     end
                  end
               end
               if (modifRank == 1)
                  break;
               end
            end
         end
      end
      if (modifRank == 1)
         break;
      end
   end
end

% last files can be not assigned (because we need data of cycle N to finish
% cycle N-1 assignment
idNotAssigned = find(tabInfo(:, 2) == -1);
if (~isempty(idNotAssigned))
   for idF = 1:length(idNotAssigned)
      cyNum = tabInfo(idNotAssigned(idF), 5);
      profNum = tabInfo(idNotAssigned(idF), 6);
      if (cyNum ~= -1)
         idFCyProfNum = find((tabInfo(:, 5) == cyNum) & (tabInfo(:, 6) == profNum));
         rankNumList = sort(unique(tabInfo(idFCyProfNum, 2)));
         rankNumList = rankNumList(find(rankNumList >= 0));
         if (~isempty(rankNumList))
            tabInfo(idNotAssigned(idF), 2) = rankNumList(end);
         end
      end
   end
end

% check that msg type 251 are not alone within a given rank
uRank = sort(unique(tabInfo(:, 2)));
uRank = uRank(find(uRank >= 0));
for idRk = 1:length(uRank)
   rankNum = uRank(idRk);
   uTypeForRank = unique(tabInfo(find(tabInfo(:, 2) == rankNum), 4));
   if ((length(uTypeForRank) == 1) && (uTypeForRank == 251))
      idFiles = find(tabInfo(:, 2) == rankNum);
      for idF = 1:length(idFiles)
         fileDate = tabInfo(idFiles(idF), 3);
         [~, idSort] = sort(abs(tabInfo(:, 3)-fileDate));
         done = 0;
         id = 2;
         while (~done)
            if (tabInfo(idSort(id), 2) == rankNum)
               id = id + 1;
               if (id > length(idSort))
                  done = 1;
               end
            else
               tabInfo(idFiles(idF), 2) = tabInfo(idSort(id), 2);
               done = 1;
            end
         end
      end
      fprintf('DEC_INFO: rank reassigned for %d files (type 251)\n', ...
         length(idFiles));
   end
end

idNotAssigned = find(tabInfo(:, 2) == -1);
if (~isempty(idNotAssigned))
   fprintf('ERROR: %d files are not assigned\n', length(idNotAssigned));
end

% check consistency per rank
uRank = sort(unique(tabInfo(:, 2)));
uRank = uRank(find(uRank >= 0));
expCyNum = 0;
for idRk = 1:length(uRank)
   idForRank = find(tabInfo(:, 2) == uRank(idRk));
   cyRank = tabInfo(idForRank, 5);
   cyRank(find(cyRank == -1)) = [];
   uCyRank = unique(cyRank);
   if (length(uCyRank) == 1)
      if (uCyRank == expCyNum)
      elseif (uCyRank == expCyNum+1)
         expCyNum = expCyNum + 1;
      elseif (uCyRank > expCyNum)
         % missing cycles
         expCyNum = uCyRank;
         fprintf('DEC_WARNING: rank %d: missing cycle(s)\n', ...
            uRank(idRk));
      else
         fprintf('DEC_ERROR: rank %d: cycle = %d expected = %d\n', ...
            uRank(idRk), uCyRank, expCyNum);
      end
   else
      fprintf('DEC_ERROR: rank %d: %d cycle numbers\n', ...
         uRank(idRk), length(uCyRank));
   end
end

idNotAssigned = size(tabInfoOri, 1) - size(tabInfo, 1);
fprintf('DEC_INFO: %d files are not assigned\n', idNotAssigned);

% generate CSV output file
if (~isempty(a_fidCsv))
   
   header = 'Rank;File #;File;Cor cycle; Cor profile;Cycle #;Profile #;Data type;Phase #;Sensor #;Sensor data type #;Diff dates';
   fprintf(a_fidCsv, '%s\n', header);
   
   diffDates = diff(tabInfoOri(:, 3))*24;
   for idFile = 1:length(tabName)
      [~, fileName, fileExt] = fileparts(tabName{idFile});
      idF = find(tabInfo(:, 1) == idFile);
      if (~isempty(idF))
         if ((idF > 1) && (tabInfo(idF, 2) ~= lastRank))
            fprintf(a_fidCsv, '%d\n', lastRank);
         end
         fileRank = tabInfo(idF, 2);
         lastRank = fileRank;
      else
         fileRank = tabInfoOri(idFile, 2);
      end
      
      if (idFile > 1)
         diffDate = diffDates(idFile-1);
         diffDateStr = format_time_dec_argo(diffDate);
         if (diffDate > 10/60)
            diffDateMark = 'x';
         else
            diffDateMark = '';
         end
      else
         diffDateStr = '';
         diffDateMark = '';
      end
      
      if (fileRank == -1)
         unusedMark = 'o';
      else
         unusedMark = '';
      end
      
      fprintf(a_fidCsv, '%d; %d; %s; -1; -1; %d; %d; %d; %d; %d; %d; %s; %s; %s\n', ...
         fileRank, idFile, [fileName fileExt], ...
         tabInfoOri(idFile, 5), tabInfoOri(idFile, 6), tabInfoOri(idFile, 4), ...
         tabInfoOri(idFile, 7), tabInfoOri(idFile, 8), tabInfoOri(idFile, 9), ...
         diffDateStr, diffDateMark, unusedMark);
   end
end

% generate TXT output file
if (~isempty(a_fidTxt))
   for idFile = 1:length(tabName)
      [~, fileName, fileExt] = fileparts(tabName{idFile});
      idF = find(tabInfo(:, 1) == idFile);
      if (~isempty(idF))
         fileRank = tabInfo(idF, 2);
      else
         fileRank = tabInfoOri(idFile, 2);
      end
      
      fprintf(a_fidTxt, '%d %s -1 -1\n', ...
         fileRank, [fileName fileExt]);
   end
end

o_sbdFileNameList = tabName;
idFileKo = setdiff(1:length(tabName), tabInfo(:, 1));
o_sbdFileNameList(idFileKo) = [];
o_sbdFileRank = tabInfo(:, 2);
o_sbdFileDate = tabInfo(:, 3);
o_sbdFileCyNum = tabInfo(:, 5);
o_sbdFileProfNum = tabInfo(:, 6);
o_sbdFileDataType = tabInfo(:, 4);

return;


% % delete test SBD files
% idDel = [];
% uCycle = sort(unique(tabInfo(:, 3)));
% uCycle = uCycle(find(uCycle >= 0));
% uProf = sort(unique(tabInfo(:, 4)));
% uProf = uProf(find(uProf >= 0));
% for idCy = 1:length(uCycle)
%    for idProf = 1:length(uProf)
%       cyNum = uCycle(idCy);
%       profNum = uProf(idProf);
%
%       idCyProf = find((tabInfo(:, 3) == cyNum) & (tabInfo(:, 4) == profNum));
%       if (~isempty(idCyProf))
%          dates = tabInfo(idCyProf, 1);
%          idCut = find(diff(dates) > 100);
%          if (~isempty(idCut))
%             tabCut = [1 idCut' length(idCyProf)];
%             [~, idMax] = max(diff(tabCut));
%
%             if (idMax == 1)
%                idDel = [idDel; setdiff(idCyProf, idCyProf(tabCut(idMax):tabCut(idMax+1)))];
%             else
%                idDel = [idDel; setdiff(idCyProf, idCyProf(tabCut(idMax)+1:tabCut(idMax+1)))];
%             end
%          end
%       end
%    end
% end
% for idD = 1:length(idDel)
%    [~, fileName, fileExt] = fileparts(tabName{idDel(idD)});
%    fprintf('INFO: ignoring file %s\n', [fileName fileExt]);
% end
% if (~isempty(idDel))
%    fprintf('File numbers:\n');
%    fprintf('%d\n', idDel);
%    % tabInfo(idDel, :) = [];
%    % tabName(idDel) = [];
% end
