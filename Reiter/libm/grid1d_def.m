function g = grid1d_def(x0,dim,nAggrVar);
  g = struct('x',[],'v',[],'dv',[],'contr',[],'AV',[],...
	     'TolBelowBound',1e-12,...
	     'TolAboveBound',1e-12,...
	     'interpBelowBound',@extrapol_nan,...
	     'interpAboveBound',@extrapol_nan,...
	     'interpCBelowBound',@extrapol_nan,...
	     'interpCAboveBound',@extrapol_nan);
  if(nargin>0)
    g.x = x0;
  end;
  if(nargin>1)
    g.v = zeros(dim);
    g.dv = zeros(dim);
  end;
  if(nargin>2)  %assumes that first two dimensions refer to aggregate states:
    g.AV = zeros(nAggrVar,dim(1),dim(2));
  end;