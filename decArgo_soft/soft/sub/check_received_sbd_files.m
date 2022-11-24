% ------------------------------------------------------------------------------
% Check if received SBD files are consistent to create completed buffers for a
% give list of cycles.
%
% SYNTAX :
%  [o_cycleNumberList, o_bufferCompleted] = check_received_sbd_files( ...
%    a_sbdFileNameList, a_sbdFileDateList, a_sbdFileSizeList, a_cycleNumberList, a_decoderId)
%
% INPUT PARAMETERS :
%   a_sbdFileNameList  : list of SBD file names
%   a_sbdFileDateList  : list of SBD file dates
%   a_sbdFileSizeList  : list of SBD file sizes
%   a_cycleNumberList  : list of cycles for which the consistency should be
%                        checked
%   a_decoderId        : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_cycleNumberList : list of cycles
%   o_bufferCompleted : completed buffer flags for associated list of cycles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/16/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleNumberList, o_bufferCompleted] = check_received_sbd_files( ...
   a_sbdFileNameList, a_sbdFileDateList, a_sbdFileSizeList, a_cycleNumberList, a_decoderId)

% output parameters initialization
o_cycleNumberList = [];
o_bufferCompleted = [];

% current float WMO number
global g_decArgo_floatNum;

% SBD sub-directories
global g_decArgo_bufferDirectory;
global g_decArgo_archiveSbdDirectory;

% generate nc flag
global g_decArgo_generateNcFlag;
g_decArgo_generateNcFlag = 1;

% number of the first deep cycle
global g_decArgo_firstDeepCycleNumber;
g_decArgo_firstDeepCycleNumber = 1;

% to use virtual buffers instead of directories
global g_decArgo_virtualBuff;


% read the SBD file data
sbdDataDate = [];
sbdDataData = [];
for idFile = 1:length(a_sbdFileNameList)
   
   sbdFileName = a_sbdFileNameList{idFile};
   if (g_decArgo_virtualBuff)
      sbdFilePathName = [g_decArgo_archiveSbdDirectory '/' sbdFileName];
   else
      sbdFilePathName = [g_decArgo_bufferDirectory '/' sbdFileName];
   end
   
   if (a_sbdFileSizeList(idFile) > 0)
      
      if (rem(a_sbdFileSizeList(idFile), 100) == 0)
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
               sbdDataDate = [sbdDataDate; a_sbdFileDateList(idFile)];
            end
         end
      else
         fprintf('DEC_WARNING: Float #%d: SBD file ignored because of unexpected size (%d bytes)  : %s\n', ...
            g_decArgo_floatNum, ...
            a_sbdFileSizeList(idFile), ...
            sbdFilePathName);
      end
      
   end
end

% roughly check SBD data

switch (a_decoderId)
   
   case {212} % Arvor-ARN-Ice Iridium 5.45
      
      % decode the collected data
      decode_prv_data_ir_sbd_212(sbdDataData, sbdDataDate, 0, a_cycleNumberList);
      
   case {214} % % Provor-ARN-DO-Ice Iridium 5.75
      
      % decode the collected data
      decode_prv_data_ir_sbd_214(sbdDataData, sbdDataDate, 0, a_cycleNumberList);

   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in check_received_sbd_files for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

[o_cycleNumberList, o_bufferCompleted] = is_buffer_completed_ir_sbd_delayed(0, a_decoderId);

return;
