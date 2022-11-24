% ------------------------------------------------------------------------------
% Get the basic structure to store Iridium e-mail contents.
%
% SYNTAX :
%  [o_iridiumMail, o_iridiumMailAllBis] = get_iridium_mail_init_struct(a_mailFileName)
%
% INPUT PARAMETERS :
%   a_mailFileName : e-mail file name
%
% OUTPUT PARAMETERS :
%   o_iridiumMail       : e-mail contents (stored)
%   o_iridiumMailAllBis : e-mail contents (not stored)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_iridiumMail, o_iridiumMailAllBis] = get_iridium_mail_init_struct(a_mailFileName)

% default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;

% output parameters initialization
o_iridiumMail = struct( ...
   'mailFileName', a_mailFileName, ...
   'timeOfSessionJuld', g_decArgo_dateDef, ...
   'messageSize', '', ...
   'unitLocationLat', g_decArgo_argosLatDef, ...
   'unitLocationLon', g_decArgo_argosLonDef, ...
   'cepRadius', 0, ... % initialized to 0 (so that the Iridium location is not considered if not present in the mail; Ex: co_20190527T062249Z_300234065420780_000939_000000_10565.txt)
   'attachementFileFlag', 0, ...
   'cycleNumber', -1, ...
   'floatCycleNumber', -1, ...
   'floatProfileNumber', -1, ...
   'locInTrajFlag', 0 ... % in EOL, to process only new incoming locations
   );

o_iridiumMailAllBis = struct( ...
   'timeOfSession', '', ...
   'unitLocation', '', ...
   'attachementFileName', '' ...
   );

return
