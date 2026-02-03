% ------------------------------------------------------------------------------
% Create temporary directory used to store generated NetCDF files.
%
% SYNTAX :
%  [o_inputError] = create_nc_temp_dir(a_time)
%
% INPUT PARAMETERS :
%   a_time : start date of the run ('yyyymmddTHHMMSS' format)
%
% OUTPUT PARAMETERS :
%   o_inputError : input error flag
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/06/05 - RNU - creation
% ------------------------------------------------------------------------------
function [o_inputError] = create_nc_temp_dir(a_time)

% output parameters initialization
o_inputError = 0;

% temporary directory used to store generated NetCDF files
global g_decArgo_ncTempDir;


if ~(exist(g_decArgo_ncTempDir, 'dir') == 7)
   fprintf('ERROR: ''DIR_OUTPUT_TEMPORARY'' directory does not exists - exit\n');
   o_inputError = 1;
   return
end

ncTmpDir = [g_decArgo_ncTempDir '/decode_argo_2_nc_rt_tmp_dir_' a_time '_' num2str(feature('getpid')) '/'];
while (exist(ncTmpDir, 'dir') == 7)
   ncTmpDir = [g_decArgo_ncTempDir '/decode_argo_2_nc_rt_tmp_dir_' datestr(now, 'yyyymmddTHHMMSSZ') '_' feature('getpid') '/'];
end
mkdir(ncTmpDir);

g_decArgo_ncTempDir = ncTmpDir;

return
