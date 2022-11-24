% ------------------------------------------------------------------------------
% Compute, from configuration information, the minimum delay between 2 surface
% transmission phases. Used for 'delayed' decoder (Ice floats) to separate
% transmission phases.
%
% SYNTAX :
%  [o_minDeltaTrans] = compute_min_delta_trans(a_fileName, a_decoderId)
%
% INPUT PARAMETERS :
%   a_fileName  : list of SBD files to be decoded
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_minDeltaTrans : minimum delay between 2 surface transmission phases (in
%                     minutes)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/14/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_minDeltaTrans] = compute_min_delta_trans(a_fileName, a_decoderId)

% output parameters initialization
o_minDeltaTrans = [];

% current float WMO number
global g_decArgo_floatNum;

% SBD sub-directories
global g_decArgo_bufferDirectory;
global g_decArgo_archiveDirectory;
global g_decArgo_archiveSbdDirectory;

% to use virtual buffers instead of directories
global g_decArgo_virtualBuff;


% extract SBD files in g_decArgo_archiveSbdDirectory
for idFile = 1:length(a_fileName)
   
   % move the next file into the buffer directory
   add_to_list_ir_sbd(a_fileName{idFile}, 'buffer');
   remove_from_list_ir_sbd(a_fileName{idFile}, 'spool', 0, 1);

   % extract the attachement
   [~, attachmentFound] = read_mail_and_extract_attachment( ...
      a_fileName{idFile}, g_decArgo_archiveDirectory, g_decArgo_archiveSbdDirectory);
   if (attachmentFound == 0)
      remove_from_list_ir_sbd(a_fileName{idFile}, 'buffer', 1, 1);
      if (idFile < length(a_fileName))
         continue;
      end
   end
   
end

% retrieve information on the files in the buffer
[tabFileNames, ~, tabFileDates, tabFileSizes] = get_list_files_info_ir_sbd( ...
   'buffer', '');

% read the SBD file data
sbdDataDate = [];
sbdDataData = [];
for idFile = 1:length(tabFileNames)
   
   sbdFileName = tabFileNames{idFile};
   if (g_decArgo_virtualBuff)
      sbdFilePathName = [g_decArgo_archiveSbdDirectory '/' sbdFileName];
   else
      sbdFilePathName = [g_decArgo_bufferDirectory '/' sbdFileName];
   end
   
   if (tabFileSizes(idFile) > 0)
      
      if (rem(tabFileSizes(idFile), 100) == 0)
         fId = fopen(sbdFilePathName, 'r');
         if (fId == -1)
            fprintf('ERROR: Float #%d: Error while opening file : %s\n', ...
               g_decArgo_floatNum, ...
               sbdFilePathName);
         end
         
         [sbdData, sbdDataCount] = fread(fId);
         
         fclose(fId);
         
         sbdData = reshape(sbdData, 100, size(sbdData, 1)/100)';
         for idMsg = 1:size(sbdData, 1)
            data = sbdData(idMsg, :);
            if (~isempty(find(data ~= 0, 1)))
               sbdDataData = [sbdDataData; data];
               sbdDataDate = [sbdDataDate; tabFileDates(idFile)];
            end
         end
      else
         fprintf('DEC_WARNING: Float #%d: SBD file ignored because of unexpected size (%d bytes)  : %s\n', ...
            g_decArgo_floatNum, ...
            tabFileSizes(idFile), ...
            sbdFilePathName);
      end
   end
end

% decode SBD data
tabCyclePeriodMinutes = [];
tabEolTransPeriodMinutes = [];
tabSecondIrWaitTimeMinutes = [];
switch (a_decoderId)
   
   case {212, 214, 217}
      
      % Arvor-ARN-Ice Iridium 5.45
      % Provor-ARN-DO-Ice Iridium 5.75
      % Arvor-ARN-DO-Ice Iridium 5.46
      
      for idMes = 1:size(sbdDataData, 1)
         % packet type
         packType = sbdDataData(idMes, 1);
         
         if (packType == 5)
            % parameter packet #1
            
            % message data frame
            msgData = sbdDataData(idMes, 2:end);
            
            % first item bit number
            firstBit = 1;
            % item bit lengths
            tabNbBits = [ ...
               16 repmat(8, 1, 7) 16 ...
               repmat(16, 1, 4) repmat(8, 1, 7) repmat(16, 1, 4) 8 16 16 16 8 8 8 16 16 repmat(8, 1, 6) 16 16 ...
               16 repmat(8, 1, 5) 16 repmat(8, 1, 5) 16 8 16 repmat(8, 1, 9) 16 16 ...
               repmat(8, 1, 9) ...
               ];
            % get item bits
            tabParam1 = get_bits(firstBit, tabNbBits, msgData);
            
            cyclePeriod1_MC2 = tabParam1(12);
            cyclePeriod2_MC3 = tabParam1(13);
            eolTransPeriod_MC22 = tabParam1(32);
            secondIrWaitTime_MC23 = tabParam1(33);
            tabCyclePeriodMinutes = [tabCyclePeriodMinutes cyclePeriod1_MC2*60 cyclePeriod2_MC3*60];
            tabEolTransPeriodMinutes = [tabEolTransPeriodMinutes eolTransPeriod_MC22];
            tabSecondIrWaitTimeMinutes = [tabSecondIrWaitTimeMinutes secondIrWaitTime_MC23];
         end
      end
      
      o_minDeltaTrans = min(tabCyclePeriodMinutes);
      if (any(tabSecondIrWaitTimeMinutes ~= 0))
         o_minDeltaTrans = min(o_minDeltaTrans, ...
            min(tabSecondIrWaitTimeMinutes(find(tabSecondIrWaitTimeMinutes ~= 0))));
      end

   case {216} % Arvor-Deep-Ice Iridium 5.65
      
      for idMes = 1:size(sbdDataData, 1)
         % packet type
         packType = sbdDataData(idMes, 1);
         
         if (packType == 5)
            % parameter packet #1
            
            % message data frame
            msgData = sbdDataData(idMes, 2:end);
            
            % first item bit number
            firstBit = 1;
            % item bit lengths
            tabNbBits = [ ...
               repmat(8, 1, 6) 16 ...
               16 repmat(8, 1, 6) repmat(16, 1, 4) 8 8 8 16 16 8 ...
               repmat(8, 1, 6) 16 repmat(8, 1, 5) 16 repmat(8, 1, 4) 16 repmat(8, 1, 12) 16 16 8 8 16 16 16 ...
               16 16 8 8 16 16 8 8 16 8 8 8 8 16 ...
               repmat(8, 1, 2) ...
               ];
            % get item bits
            tabParam1 = get_bits(firstBit, tabNbBits, msgData);
            
            cyclePeriod_PM1 = tabParam1(9);
            eolTransPeriod_PM15 = tabParam1(22);
            secondIrWaitTime_PM16 = tabParam1(23);
            tabCyclePeriodMinutes = [tabCyclePeriodMinutes cyclePeriod_PM1*1440];
            tabEolTransPeriodMinutes = [tabEolTransPeriodMinutes eolTransPeriod_PM15];
            tabSecondIrWaitTimeMinutes = [tabSecondIrWaitTimeMinutes secondIrWaitTime_PM16];
         end
      end

      o_minDeltaTrans = min(tabCyclePeriodMinutes);
      if (any(tabSecondIrWaitTimeMinutes ~= 0))
         o_minDeltaTrans = min(o_minDeltaTrans, ...
            min(tabSecondIrWaitTimeMinutes(find(tabSecondIrWaitTimeMinutes ~= 0))));
      end
      
   otherwise
      fprintf('ERROR: Float #%d: Nothing implemented yet in compute_min_delta_trans for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end


% clean virtual list
remove_from_list_ir_sbd(tabFileNames, 'buffer', 1, 1);

% clean g_decArgo_archiveSbdDirectory
if (exist(g_decArgo_archiveSbdDirectory, 'dir') == 7)
   rmdir(g_decArgo_archiveSbdDirectory, 's');
end
mkdir(g_decArgo_archiveSbdDirectory);

return;
