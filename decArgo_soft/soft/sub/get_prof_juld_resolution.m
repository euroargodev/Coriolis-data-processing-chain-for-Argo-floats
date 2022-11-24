% ------------------------------------------------------------------------------
% Retrieve the resolution of the profile JULD for each float transmission type
% and decoder Id.
%
% SYNTAX :
%  [o_profJuldRes, o_profJulDComment] = get_prof_juld_resolution(a_floatTransType, a_decoderId)
%
% INPUT PARAMETERS :
%   a_floatTransType : float transmission type
%   a_decoderId      : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_profJuldRes     : profile JULD resolution
%   o_profJulDComment : comment on profile JULD resolution
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profJuldRes, o_profJulDComment] = get_prof_juld_resolution(a_floatTransType, a_decoderId)

% output parameter initialization
o_profJuldRes = [];
o_profJulDComment = [];

switch (a_floatTransType)
   
   case {1} % Argos floats
      
      switch (a_decoderId)
         
         case {1, 3, 4, 11, 12, 17, 19, 24, 25, 27, 28, 29, 31}
            o_profJuldRes = double(6/1440); % 6 minutes
            o_profJulDComment = 'JULD resolution is 6 minutes, except when JULD = JULD_LOCATION or when JULD = JULD_FIRST_MESSAGE (TRAJ file variable); in that case, JULD resolution is 1 second';
            
         case {30, 32}
            o_profJuldRes = double(1/1440); % 1 minutes
            o_profJulDComment = 'JULD resolution is 1 minute, except when JULD = JULD_LOCATION or when JULD = JULD_FIRST_MESSAGE (TRAJ file variable); in that case, JULD resolution is 1 second';
            
         case {1001, 1002, 1003, 1004, 1005, 1006}
            o_profJuldRes = double(1/86400); % 1 second
            o_profJulDComment = '';

         otherwise
            fprintf('WARNING: Nothing done yet in get_prof_juld_resolution for decoderId #%d\n', ...
               a_decoderId);
      end
      
   case {2} % Iridium RUDICS floats
      
      o_profJuldRes = double(1/1440); % 1 minute
      o_profJulDComment = 'JULD resolution is 1 minute, except when JULD = JULD_LOCATION or when JULD = JULD_FIRST_MESSAGE (TRAJ file variable); in that case, JULD resolution is 1 second';
      
   case {3} % Iridium SBD floats
      
      switch (a_decoderId)
         
         case {101, 102, 103}
            o_profJuldRes = double(6/1440); % 6 minutes
            o_profJulDComment = 'JULD resolution is 6 minutes, except when JULD = JULD_LOCATION or when JULD = JULD_FIRST_MESSAGE (TRAJ file variable); in that case, JULD resolution is 1 second';
            
         case {104}
            o_profJuldRes = double(1/1440); % 1 minute
            o_profJulDComment = 'JULD resolution is 1 minute, except when JULD = JULD_LOCATION or when JULD = JULD_FIRST_MESSAGE (TRAJ file variable); in that case, JULD resolution is 1 second';
        
         case {201, 202, 203, 204, 205, 206, 207, 208, 209, 210}
            o_profJuldRes = double(1/1440); % 1 minute
            o_profJulDComment = 'JULD resolution is 1 minute, except when JULD = JULD_LOCATION or when JULD = JULD_FIRST_MESSAGE (TRAJ file variable); in that case, JULD resolution is 1 second';
            
         case {2001, 2002}
            o_profJuldRes = double(1/86400); % 1 second
            o_profJulDComment = '';
            
         otherwise
            fprintf('WARNING: No JULD profile resolution defined yet for float transmission type #%d and decoder Id #%d\n', ...
               a_floatTransType, a_decoderId);
            
      end
      
   case {4} % Iridium SBD ProvBioII floats
      
      o_profJuldRes = double(1/1440); % 1 minute
      o_profJulDComment = 'JULD resolution is 1 minute, except when JULD = JULD_LOCATION or when JULD = JULD_FIRST_MESSAGE (TRAJ file variable); in that case, JULD resolution is 1 second';      
      
   otherwise
      fprintf('WARNING: No JULD profile resolution defined yet for float transmission type #%d\n', ...
         a_floatTransType);
end

return;
