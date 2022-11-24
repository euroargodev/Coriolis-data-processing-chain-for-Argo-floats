% ------------------------------------------------------------------------------
% Add a new item to one virtual buffer list.
%
% SYNTAX :
%  add_to_list_ir_rudics(a_fileName, a_listName)
%
% INPUT PARAMETERS :
%   a_fileName : name of the file to be added
%   a_listName : name of the virtual buffer list
%
% OUTPUT PARAMETERS :
%   o_ok : copy operation report flag (1 if ok, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/17/2016 - RNU - creation
% ------------------------------------------------------------------------------
function add_to_list_ir_rudics(a_fileName, a_listName)

% current float WMO number
global g_decArgo_floatNum;

% to use virtual buffers instead of directories
global g_decArgo_spoolFileList;
global g_decArgo_bufFileList;


if (~ismember(a_listName, [{'spool'} {'buffer'}]))
   fprintf('BUFF_ERROR: Float #%d: add_to_list_ir_rudics: unknown list name (''%s'')\n', ...
      g_decArgo_floatNum, a_listName);
   return
end

if (strcmp(a_listName, 'spool'))
   g_decArgo_spoolFileList{end+1} = a_fileName;
elseif (strcmp(a_listName, 'buffer'))
   g_decArgo_bufFileList{end+1} = a_fileName;
end

return
