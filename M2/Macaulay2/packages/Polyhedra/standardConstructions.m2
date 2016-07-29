-- PURPOSE : Computing the cyclic polytope of n points in QQ^d
--   INPUT : '(d,n)',  two positive integers
--  OUTPUT : A polyhedron, the convex hull of 'n' points on the moment curve in 'd' space 
-- COMMENT : The moment curve is defined by t -> (t,t^2,...,t^d) in QQ^d, if we say we take 'n' points 
--            on the moment curve, we mean the images of 0,...,n-1
cyclicPolytope = method(TypicalValue => Polyhedron)
cyclicPolytope(ZZ,ZZ) := (d,n) -> (
     -- Checking for input errors
     if d < 1 then error("The dimension must be positive");
     if n < 1 then error("There must be a positive number of points");
     convexHull map(ZZ^d, ZZ^n, (i,j) -> j^(i+1)))


-- PURPOSE : Computing the cone of the Hirzebruch surface H_r
--   INPUT : 'r'  a positive integer
--  OUTPUT : The Hirzebruch surface H_r
hirzebruch = method(TypicalValue => Fan)
hirzebruch ZZ := r -> (
   -- Checking for input errors
   if r < 0 then error ("Input must be a positive integer");
   normalFan convexHull matrix {{0, 1, 0, r+1},{0, 0, 1, 1}}
)


-- PURPOSE : Generating the 'd'-dimensional hypercube with edge length 2*'s'
hypercube = method(TypicalValue => Polyhedron)

--   INPUT : '(d,s)',  where 'd' is a strictly positive integer, the dimension of the polytope, and
--     	    	       's' is a positive rational number, half of the edge length
--  OUTPUT : The 'd'-dimensional hypercube with edge length 2*'s' as a polyhedron
hypercube(ZZ,QQ) := (d,s) -> (
     -- Checking for input errors
     if d < 1 then error("dimension must at least be 1");
     if s <= 0 then error("size of the hypercube must be positive");
     -- Generating half-spaces matrix and vector
     intersection(map(QQ^d,QQ^d,1) || -map(QQ^d,QQ^d,1),matrix toList(2*d:{s})))



--   INPUT : '(d,s)',  where 'd' is a strictly positive integer, the dimension of the polytope, and
--     	    	       's' is a positive integer, half of the edge length
hypercube(ZZ,ZZ) := (d,s) -> hypercube(d,promote(s,QQ))

     
--   INPUT : 'd',  is a strictly positive integer, the dimension of the polytope 
hypercube ZZ := d -> hypercube(d,1_QQ)


-- PURPOSE : Computing the Newton polytope for a given polynomial
--   INPUT : 'p',  a RingElement
--  OUTPUT : The polyhedron that has the exponent vectors of the monomials of 'p' as vertices
newtonPolytope = method(TypicalValue => Polyhedron)
newtonPolytope RingElement := p -> convexHull transpose matrix exponents p


-- PURPOSE : Generating the positive orthant in n-space as a cone
--   INPUT : 'n",  a strictly positive integer
--  OUTPUT : The cone that is the positive orthant in n-space
posOrthant = method(TypicalValue => Cone)
posOrthant ZZ := n -> posHull map(QQ^n,QQ^n,1)


	  
-- PURPOSE : Computing the secondary Polytope of a Polyhedron
--   INPUT : 'P',  a Polyhedron which must be compact
--  OUTPUT : a polytope, the secondary polytope
secondaryPolytope = method(TypicalValue => Polyhedron)
secondaryPolytope Polyhedron := P -> (
     -- Checking for input errors
     if not isCompact P then error("The polyhedron must be compact.");
     -- Extracting necessary data
     V := vertices P;
     n := dim P;
     m := numColumns V;
     -- Computing the cell decomposition of P induced by the projection of the m-1 simplex onto P
     nCells := apply(subsets(m,n+1), e -> convexHull V_e);
     nCellsfd := select(nCells, C -> dim C == n);
     nCellsfd = inclMinCones nCellsfd;
     refCells := {};
     while nCellsfd != {} do (
	  newCells := {};
	  -- scan through the 'n' dimensional cells and check for each of the cells generated by
	  -- 'n+1' vertices if their intersection is 'n' dimensional and if the first one is not contained 
	  -- in the latter. If true, then their intersection will be saved in the list 'newCells'.
	  -- If false for every cone generated by 'n+1' vertices, then the 'n' dimensional cell will be 
	  -- appended to the list 'refCells'
	  refCells = refCells | (flatten apply(nCellsfd, C1 -> (
			 toBeAdded := flatten apply(nCells, C2 -> (
				   C := intersection(C2,C1);
				   if dim C == n and (not contains(C2,C1)) then C
				   else {}));
			 if toBeAdded == {} then C1
			 else (
			      newCells = newCells | toBeAdded;
			      {}))));
	  -- now, the new intersections will be the 'n' dimensional cones and the same procedure 
	  -- starts over again if this list is not empty
	  nCellsfd = unique newCells);
     refCells = if n != ambDim P then (
	  A := substitute((hyperplanes P)#0,ZZ);
	  A = inverse (smithNormalForm A)#2;
	  d := ambDim P;
	  A = A^{d-n..d-1};
	  apply(refCells, P -> (volume affineImage(A,P),interiorPoint P)))
     else apply(refCells, P -> (volume P,interiorPoint P));
     volP := sum apply(refCells,first);
     Id := -map(QQ^m,QQ^m,1);
     v := map(QQ^m,QQ^1,0);
     N := matrix{toList(m:1_QQ)} || V;
     w := matrix {{1_QQ}};
     sum apply(refCells, e -> (e#0/volP) * intersection(Id,v,N,w||e#1)))
     


-- PURPOSE : Computing the state polytope of the ideal 'I'
--   INPUT : 'I',  a homogeneous ideal with resect to some strictly psoitive grading
--  OUTPUT : The state polytope as a polyhedron
statePolytope = method(TypicalValue => Polyhedron)
statePolytope Ideal := I -> (
     -- Check if there exists a strictly positive grading such that 'I' is homogeneous with
     -- respect to this grading
     homogeneityCheck := I -> (
	  -- Generate the matrix 'M' that spans the space of the differeneces of the 
	  -- exponent vectors of the generators of 'I'
	  L := flatten entries gens I;
	  lt := apply(L, leadTerm);
	  M := matrix flatten apply(#L, i -> apply(exponents L#i, e -> (flatten exponents lt#i)-e));
	  -- intersect the span of 'M' with the positive orthant
	  C := intersection(map(source M,source M,1),M);
	  -- Check if an interior vector is strictly positive
	  v := interiorVector C;
	  (all(flatten entries v, e -> e > 0),v));
     -- Compute the Groebner cone
     gCone := (g,lt) -> (
	  -- for a given groebner basis compute the reduced Groebner basis
	  -- note: might be obsolete, but until now (Jan2009) groebner bases appear to be not reduced
	  g = apply(flatten entries gens g, l -> ((l-leadTerm(l))% g)+leadTerm(l));
	  -- collect the differences of the exponent vectors of the groebner basis
	  lt = flatten entries lt;
	  L := matrix flatten apply(#g, i -> apply(exponents g#i, e -> (flatten exponents lt#i)-e));
	  -- intersect the differences
	  intersection L);
     wLeadTerm := (w,I) -> (
	  -- Compute the Groebner basis and their leading terms of 'I' with respect to the weight 'w'
	  R := ring I;
	  -- Resize w to a primitive vector in ZZ
	  w = flatten entries substitute((1 / abs gcd flatten entries w) * w,ZZ);
	  -- generate the new ring with weight 'w'
	  S := (coefficientRing R)[gens R, MonomialOrder => {Weights => w}, Global => false];
	  f := map(S,R);
	  -- map 'I' into 'S' and compute Groebner basis and leadterm
	  I1 := f I;
	  g := gb I1;
	  lt := leadTerm I1;
	  gbRemove I1;
	  (g,lt));
     makePositive := (w,posv) -> (
	  w = flatten entries w;
	  posv = flatten entries posv;
	  j := min(apply(#w, i -> w#i/posv#i));
	  if j <= 0 then j = 1 - floor j else j = 0;
	  matrix transpose{w + j * posv});
     -- computes the symmetric difference of the two lists
     sortIn := (L1,L2) -> ((a,b) := (set apply(L1,first),set apply(L2,first)); join(select(L1,i->not b#?(i#0)),select(L2,i->not a#?(i#0))));
     --Checking for homogeneity
     (noError,posv) := homogeneityCheck I;
     if not noError then error("The ideal must be homogeneous w.r.t. some strictly positive grading");
     -- Compute a first Groebner basis to start with
     g := gb I;
     lt := leadTerm I;
     -- Compute the Groebner cone
     C := gCone(g,lt);
     gbRemove I;
     -- Generate all facets of 'C'
     -- Save each facet by an interior vector of it, the facet itself and the cone from 
     -- which it has been computed
     facets := apply(faces(1,C), f -> (interiorVector f,f,C));
     --Save the leading terms as the first vertex
     verts := {lt};
     -- Scan the facets
     while facets != {} do (
	  local omega';
	  local f;
	  (omega',f,C) = facets#0;
	  -- compute an interior vector of the big cone 'C' and take a small 'eps'
	  omega := promote(interiorVector C,QQ);
	  eps := 1/10;
	  omega1 := omega'-(eps*omega);
	  (g,lt) = wLeadTerm(makePositive(omega1,posv),I);
	  C' := gCone(g,lt);
	  -- reduce 'eps' until the Groebner cone generated by omega'-(eps*omega) is 
	  -- adjacent to the big cone 'C'
	  while intersection(C,C') != f do (
	       eps = eps * 1/10;
	       omega1 = omega'-(eps*omega);
	       (g,lt) = wLeadTerm(makePositive(omega1,posv),I);
	       C' = gCone(g,lt));
	  C = C';
	  -- save the new leadterms as a new vertex
	  verts = append(verts,lt);
	  -- Compute the facets of the new Groebner cone and save them in the same way as before
	  newfacets := faces(1,C);
	  newfacets = apply(newfacets, f -> (interiorVector f,f,C));
	  -- Save the symmetric difference into 'facets'
	  facets = sortIn(facets,newfacets));
     posv = substitute(posv,ZZ);
     R := ring I;
     -- generate a new ring with the strictly positive grading computed by the homogeneity check
     S := QQ[gens R, Degrees => entries posv];
     -- map the vertices into the new ring 'S'
     verts = apply(verts, el -> (map(S,ring el)) el);
     -- Compute the maximal degree of the vertices
     L := flatten apply(verts, l -> flatten entries l);
     d := (max apply(flatten L, degree))#0;
     -- compute the vertices of the state polytope
     vertmatrix := transpose matrix apply(verts, v -> (
	       VI := ideal flatten entries v;
	       SI := S/VI;
	       v = flatten apply(d, i -> flatten entries basis(i+1,SI));
	       flatten sum apply(v,exponents)));
     -- Compute the state polytope
     P := convexHull vertmatrix;
     (verts,P));


-- PURPOSE : Computing the bipyramid over the polyhedron 'P'
--   INPUT : 'P',  a polyhedron 
--  OUTPUT : A polyhedron, the convex hull of 'P', embedded into ambientdim+1 space and the 
--     	         points (barycenter of 'P',+-1)
bipyramid = method(TypicalValue => Polyhedron)
bipyramid Polyhedron := P -> (
   -- Saving the vertices
   V := vertices P;
   n := numColumns V;
   if n == 0 then error("P must not be empty");
   -- Computing the barycenter of P
   << "Compute barycenter." << endl;
   v := matrix toList(n:{1_QQ,1_QQ});
   v = (1/n)*V*v;
   << "Compute barycenter done." << endl;
   C := getProperty(P, underlyingCone);
   M := promote(rays C, QQ);
   LS := promote(linealitySpace C, QQ);
   r := ring M;
   -- Embedding into n+1 space and adding the two new vertices
   zerorow := map(r^1,source M,0);
   newvertices := makePrimitiveMatrix(matrix {{1,1}} || v || matrix {{1,-1}});
   M = (M || zerorow) | newvertices;
   LS = LS || map(r^1,source LS,0);
   newC := posHull(M, LS);
   result := new HashTable from {
      underlyingCone => newC
   };
   polyhedron result
)



-- PURPOSE : Computing the pyramid over the polyhedron 'P'
--   INPUT : 'P',  a polyhedron 
--  OUTPUT : A polyhedron, the convex hull of 'P', embedded into ambientdim+1 space, and the 
--     	         point (0,...,0,1)
pyramid = method(TypicalValue => Polyhedron)
pyramid Polyhedron := P -> (
   C := getProperty(P, underlyingCone);
   M := rays C;
   LS := linealitySpace C;
   -- Embedding into n+1 space and adding the new vertex
   zerorow := map(ZZ^1,source M,0);
   newvertex := 1 || map(ZZ^((numRows M)-1),ZZ^1,0) || 1;
   M = (M || zerorow) | newvertex;
   LS = LS || map(ZZ^1,source LS,0);
   newC := posHull(M, LS);
   result := new HashTable from {
      underlyingCone => newC
   };
   polyhedron result
)


-- PURPOSE : Generating the 'd'-dimensional crosspolytope with edge length 2*'s'
crossPolytope = method(TypicalValue => Polyhedron)

--   INPUT : '(d,s)',  where 'd' is a strictly positive integer, the dimension of the polytope, and 's' is
--     	    	       a strictly positive rational number, the distance of the vertices to the origin
--  OUTPUT : The 'd'-dimensional crosspolytope with vertex-origin distance 's'
crossPolytope(ZZ,QQ) := (d,s) -> (
   -- Checking for input errors
   if d < 1 then error("dimension must at least be 1");
   if s <= 0 then error("size of the crosspolytope must be positive");
   constructMatrix := (d,v) -> (
   if d != 0 then flatten {constructMatrix(d-1,v|{-1}),constructMatrix(d-1,v|{1})}
   else {v});
   homHalf := ( sort makePrimitiveMatrix transpose( matrix toList(2^d:{-s}) | promote(matrix constructMatrix(d,{}),QQ)),map(ZZ^(d+1),ZZ^0,0));
   homVert := (sort makePrimitiveMatrix (matrix {toList(2*d:1_QQ)} || (map(QQ^d,QQ^d,s) | map(QQ^d,QQ^d,-s))),map(ZZ^(d+1),ZZ^0,0));
   C := new HashTable from {
      computedRays => homVert#0,
      computedLinealityBasis => homVert#1,
      computedFacets => transpose(-homHalf#0),
      computedHyperplanes => transpose(homHalf#1)
   };
   C = cone C;
   result := new HashTable from {
      underlyingCone => C
   };
   polyhedron result
)


--   INPUT : '(d,s)',  where 'd' is a strictly positive integer, the dimension of the polytope, and 's' is a
--     	    	        strictly positive integer, the distance of the vertices to the origin
crossPolytope(ZZ,ZZ) := (d,s) -> crossPolytope(d,promote(s,QQ))


--   INPUT :  'd',  where 'd' is a strictly positive integer, the dimension of the polytope
crossPolytope ZZ := d -> crossPolytope(d,1_QQ)



-- PURPOSE : Generating the empty polyhedron in n space
--   INPUT : 'n',  a strictly positive integer
--  OUTPUT : The empty polyhedron in 'n'-space
emptyPolyhedron = method(TypicalValue => Polyhedron)
emptyPolyhedron ZZ := n -> (
   -- Checking for input errors
   if n < 1 then error("The ambient dimension must be positive");
   C := posHull map(ZZ^(n+1), ZZ^0,0);
   result := new HashTable from {
      underlyingCone => C
   };
   polyhedron result
);
	  
-- PURPOSE : Generating the 'd'-dimensional standard simplex in QQ^(d+1)
--   INPUT : 'd',  a positive integer
--  OUTPUT : The 'd'-dimensional standard simplex as a polyhedron
stdSimplex = method(TypicalValue => Polyhedron)
stdSimplex ZZ := d -> (
     -- Checking for input errors
     if d < 0 then error("dimension must not be negative");
     -- Generating the standard basis
     convexHull map(QQ^(d+1),QQ^(d+1),1))
