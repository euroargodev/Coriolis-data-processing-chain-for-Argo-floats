%------------------------------------------------------------------------------
%
% tetai         - Algorithme de calcul de la temperature potentielle a un 
%                 niveau de reference
%
%------------------------------------------------------------------------------
%
%  Methode :
%  -----------
%       methode fofonoff, deep-sea research vol 24, 489-491, 1977 
%       calcul de gamma :                                         
%       formule de bryden, deep-sea research vol 20, 401-408, 1973 
%       valeurs de controle: p = 10**4 decibars
%                            t = 40 degres
%                            s = 40 nsu
%                            pr = 0
%                                >> teta = 36.89101
%
%       (ecrit a partir de tetai de hydrobib)
%
%     entree : 
%     ------   
%        xp8     : pression  
%        xt8,xs8 : temperature (t90) et salinite   
%        xpr8    : pression de reference
%
%     sortie : 
%     ------   
%        temperature potentielle (t90) au niveau pr en degres C
%
% Version:
% -------
%    02 Correction t90                                   07/07/92  C. Lagadec
%       Prise en compte de la nouvelle echelle de 
%       temperature
%  1.01 Création (d'après tetai8, chaine hydro)          04/06/96  F. Gaillard
%  2.01 Recopié de chez Fabienne après 
%       l'ajout du controle sur les dimensions           14/09/99
% 
%------------------------------------------------------------------------------
                                              
function [tpot] = tetai(pres, temp, sali, pref)

% controle sur les dimensions
% ---------------------------

[n,m] = size(pres);
if n>m,
      npt = n;
      p = pres;
else
      npt = m;
      p = pres';
end;

[n,m] = size(temp);
if n>m,
      t = temp;
else
      t = temp';
end;

[n,m] = size(sali);
if n>m,
      s = sali;
else
      s = sali';
end;

[n,m] = size(pref);
if n>m,
      pr = pref;
else
      pr = pref';
end;

% -----------------------------

acoef = [.35803e-01,  .85258e-02, -.68360e-04,  .66228e-06, ...
         .18932e-02, -.42393e-04,  .18741e-04, -.67795e-06, ...
         .87330e-08, -.54481e-10, -.11351e-06,  .27759e-08, ...
        -.46206e-09,  .18676e-10, -.21687e-12];

%.M2.deb
      t = t * 1.00024;
%.M2.fin
      s  = s - 35.0;
      dp = pr - p;
      i  = 0;
while i<4
   t2 = t.*t;
   t3 = t2.*t;
   p2 = p.*p;
   st = s.*t;
   g = acoef(1) + acoef(2)*t + acoef(3)*t2 + acoef(4)*t3 + acoef(5)*s ...
     + acoef(6)*st + acoef(7)*p +acoef(8)*p.*t + acoef(9)*p.*t2 ...
     + acoef(10)*p.*t3 + acoef(11)*p.*s + acoef(12)*p.*st ...
     + acoef(13)*p2 + acoef(14)*p2.*t + acoef(15)*p2.*t2;
   i = i + 1;

   if i == 1
        g1    = dp.*g*1.0e-03;
        teta1 = t + g1*0.5;
        p     = p + dp*0.5;
        t     = teta1;
   end

   if i == 2
        g2    = dp.*g*1.0e-03;
        teta2 = teta1 + 0.292893218*(g2 - g1);
        t     = teta2;
   end

   if i == 3
        g3    = dp.*g*1.0e-03;
        q2    = 0.585786437*g2 + 0.121320343*g1;
        teta3 = teta2 + 1.707106781*(g3 - q2);
        p     = pr;
        t     = teta3;
   end
end   % while i<4

g4    = dp.*g*1.0e-03 ;
q3    = 3.414213562*g3 - 4.121320343*q2;
teta4 = teta3 + (g4 - q3*2.0)/6.0;
%.M2.deb
        tpot = teta4 * 0.99976;
%.M2.fin 
