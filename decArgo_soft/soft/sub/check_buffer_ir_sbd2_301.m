% ------------------------------------------------------------------------------
% Decode PROVOR Iridium float with SBD files.
% Decode a list of SBD files and provide information on the resulting
% buffer contents.
%
% SYNTAX :
%  check_buffer_ir_sbd2_301( ...
%    a_mailFileNameList, a_mailFileDateList)
%
% INPUT PARAMETERS :
%   a_mailFileNameList : list of SBD file names
%   a_mailFileDateList : list of SBD file dates
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function check_buffer_ir_sbd2_301( ...
   a_mailFileNameList, a_mailFileDateList)

% current float WMO number
global g_decArgo_floatNum;

% SBD sub-directories
global g_decArgo_archiveSbdDirectory;

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
for idBufFile = 1:length(a_mailFileNameList)
   
   sbdFileName = a_mailFileNameList{idBufFile};
   
   sbdFilePathName = [g_decArgo_archiveSbdDirectory '/' sbdFileName];
   sbdFileDate = a_mailFileDateList(idBufFile);
   
   fId = fopen(sbdFilePathName, 'r');
   if (fId == -1)
      fprintf('ERROR: Float #%d: Error while opening file : %s\n', ...
         g_decArgo_floatNum, ...
         sbdFilePathName);
   end
   sbdData = fread(fId);
   fclose(fId);
   
   if (rem(length(sbdData), 140) == 0)
      sbdData = reshape(sbdData, 140, size(sbdData, 1)/140)';
      for idMsg = 1:size(sbdData, 1)
         data = sbdData(idMsg, :);
         if (~isempty(find(data ~= 0, 1)))
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
   decode_prv_data_ir_sbd2_301(sbdDataData, sbdDataDate, 0);
   
   % print information on buffer contents
   print_buffer_info_ir_sbd2_301;
   
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
