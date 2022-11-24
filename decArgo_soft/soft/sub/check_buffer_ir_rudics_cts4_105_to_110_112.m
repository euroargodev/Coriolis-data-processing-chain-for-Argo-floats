% ------------------------------------------------------------------------------
% Decode PROVOR Iridium float with RUDICS SBD files.
% Decode a list of SBD files and provide information on the resulting
% buffer contents.
%
% SYNTAX :
%  check_buffer_ir_rudics_cts4_105_to_110_112( ...
%    a_sbdFileNameList, a_sbdFileDateList, a_floatDmFlag)
%
% INPUT PARAMETERS :
%   a_sbdFileNameList  : list of SBD file names
%   a_sbdFileNameList  : list of SBD file dates
%   a_buffModeFlag     : predefined buffer mode flag
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/13/2018 - RNU - creation
% ------------------------------------------------------------------------------
function check_buffer_ir_rudics_cts4_105_to_110_112( ...
   a_sbdFileNameList, a_sbdFileDateList, a_floatDmFlag)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% SBD sub-directories
global g_decArgo_bufferDirectory;
global g_decArgo_archiveDirectory;

% arrays to store rough information on received data
global g_decArgo_0TypeReceivedData;
global g_decArgo_250TypeReceivedData;
global g_decArgo_251TypeReceivedData;
global g_decArgo_252TypeReceivedData;
global g_decArgo_253TypeReceivedData;
global g_decArgo_254TypeReceivedData;
global g_decArgo_255TypeReceivedData;
global g_decArgo_253PacketPhaseReceived;

% phase of received data
global g_decArgo_receivedDataPhase;

% to use virtual buffers instead of directories
global g_decArgo_virtualBuff;


% initialize information arrays
g_decArgo_0TypeReceivedData = [];
g_decArgo_250TypeReceivedData = [];
g_decArgo_251TypeReceivedData = [];
g_decArgo_252TypeReceivedData = [];
g_decArgo_253TypeReceivedData = [];
g_decArgo_254TypeReceivedData = [];
g_decArgo_255TypeReceivedData = [];
g_decArgo_253PacketPhaseReceived = [];
g_decArgo_receivedDataPhase = [];

% initialize SBD data
sbdDataDate = [];
sbdDataData = [];
for idBufFile = 1:length(a_sbdFileNameList)
   
   sbdFileName = a_sbdFileNameList{idBufFile};
   
   if (idBufFile == 1)
      g_decArgo_cycleNum = get_cycle_num_from_sbd_name_ir_rudics({sbdFileName});
   end
   
   if (g_decArgo_virtualBuff)
      sbdFilePathName = [g_decArgo_archiveDirectory '/' sbdFileName];
   else
      sbdFilePathName = [g_decArgo_bufferDirectory '/' sbdFileName];
   end
   sbdFileDate = a_sbdFileDateList(idBufFile);
   
   fId = fopen(sbdFilePathName, 'r');
   if (fId == -1)
      fprintf('ERROR: Float #%d: Error while opening file : %s\n', ...
         g_decArgo_floatNum, ...
         sbdFilePathName);
   end
   sbdData = fread(fId);
   fclose(fId);
   
   if (strcmp(sbdFileName(end-3:end), '.b64'))
      idZ = find(sbdData == 0, 1, 'first');
      if (any(sbdData(idZ:end) ~= 0))
         fprintf('ERROR: Float #%d: Inconsistent data in file : %s\n', ...
            g_decArgo_floatNum, ...
            sbdFilePathName);
         continue
      end
      sbdData = double(base64decode(sbdData(1:idZ-1), '', 'matlab'));
   elseif (strcmp(sbdFileName(end-3:end), '.bin'))
      if (length(sbdData) == 1024)
         sbdData = sbdData(1:980);
      end
   end
   
   if (rem(length(sbdData), 140) == 0)
      sbdData = reshape(sbdData, 140, length(sbdData)/140)';
      for idMsg = 1:size(sbdData, 1)
         data = sbdData(idMsg, :);
         if ~((isempty(find(data ~= 0, 1)) || isempty(find(data ~= 26, 1))))
            sbdDataData = [sbdDataData; data];
            sbdDataDate = [sbdDataDate; sbdFileDate];
         end
      end
   else
      fprintf('DEC_WARNING: Float #%d: input file ignored because of unexpected size (%d bytes)  : %s\n', ...
         g_decArgo_floatNum, ...
         length(sbdData), ...
         sbdFilePathName);
   end
end

% roughly check the received data
if (~isempty(sbdDataData))
   
   % decode transmitted data
   decode_prv_data_ir_rudics_cts4_105_to_110_112(sbdDataData, sbdDataDate, 0, a_floatDmFlag);
   
   % print information on buffer contents
   print_buffer_info_ir_rudics_cts4_105_to_110_112;
   
end

% initialize information arrays
g_decArgo_0TypeReceivedData = [];
g_decArgo_250TypeReceivedData = [];
g_decArgo_251TypeReceivedData = [];
g_decArgo_252TypeReceivedData = [];
g_decArgo_253TypeReceivedData = [];
g_decArgo_254TypeReceivedData = [];
g_decArgo_255TypeReceivedData = [];
g_decArgo_253PacketPhaseReceived = [];
g_decArgo_receivedDataPhase = [];

return
