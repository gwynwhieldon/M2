





   
-- PURPOSE : Giving the generating Cones of the Fan
--   INPUT : 'F'  a Fan
--  OUTPUT : a List of Cones
maxCones = method(TypicalValue => List)
maxCones Fan := F -> maxObjects F



-- PURPOSE : Tests if a Fan is projective
--   INPUT : 'F'  a Fan
--  OUTPUT : a Polyhedron, which has 'F' as normal fan, if 'F' is projective or the empty polyhedron
isPolytopalLegacy = method(TypicalValue => Boolean)
isPolytopalLegacy Fan := F -> (
     if not F.cache.?isPolytopal then (
	  F.cache.isPolytopal = false;
	  -- First of all the fan must be complete
     	  if isComplete F then (
	       -- Extracting the generating cones, the ambient dimension, the codim 1 
	       -- cones (corresponding to the edges of the polytope if it exists)
	       i := 0;
	       L := hashTable apply(maxCones F, l -> (i=i+1; i=>l));
	       n := ambDim(F);
	       edges := cones(n-1,F);
	       -- Making a table that indicates in which generating cones each 'edge' is contained
	       edgeTCTable := hashTable apply(edges, e -> select(1..#L, j -> contains(L#j,e)) => e);
	       i = 0;
	       -- Making a table of all the edges where each entry consists of the pair of top cones corr. to
	       -- this edge, the codim 1 cone, an index number i, and the edge direction from the first to the
	       -- second top Cone
	       edgeTable := apply(pairs edgeTCTable, e -> (i=i+1; 
		    	 v := transpose hyperplanes e#1;
		    	 if not contains(dualCone L#((e#0)#0),v) then v = -v;
		    	 (e#0, e#1, i, v)));
	       edgeTCNoTable := hashTable apply(edgeTable, e -> e#0 => (e#2,e#3));
	       edgeTable = hashTable apply(edgeTable, e -> e#1 => (e#2,e#3));
	       -- Computing the list of correspondencies, i.e. for each codim 2 cone ( corresponding to 2dim-faces of the polytope) save 
	       -- the indeces of the top cones containing it
	       corrList := hashTable {};
	       scan(keys L, j -> (corrList = merge(corrList,hashTable apply(faces(2,L#j), C -> C => {j}),join)));
	       corrList = pairs corrList;
	       --  Generating the 0 matrix for collecting the conditions on the edges
	       m := #(keys edgeTable);
	       -- for each entry of corrlist another matrix is added to hyperplanesTmp
	       hyperplanesTmp := flatten apply(#corrList, j -> (
		    	 v := corrList#j#1;
		    	 hyperplanesTmpnew := map(ZZ^n,ZZ^m,0);
		    	 -- Scanning trough the top cones containing the active codim2 cone and order them in a circle by their 
		    	 -- connecting edges
		    	 v = apply(v, e -> L#e);
		    	 C := v#0;
		    	 v = drop(v,1);
		    	 C1 := C;
		    	 nv := #v;
		    	 scan(nv, i -> (
			      	   i = position(v, e -> dim intersection(C1,e) == n-1);
			      	   C2 := v#i;
			      	   v = drop(v,{i,i});
			      	   (a,b) := edgeTable#(intersection(C1,C2));
			      	   if not contains(dualCone C2,b) then b = -b;
			      	   -- 'b' is the edge direction inserted in column 'a', the index of this edge
			      	   hyperplanesTmpnew = hyperplanesTmpnew_{0..a-2} | b | hyperplanesTmpnew_{a..m-1};
			      	   C1 = C2));
		    	 C3 := intersection(C,C1);
		    	 (a,b) := edgeTable#C3;
		    	 if not contains(dualCone C,b) then b = -b;
		    	 -- 'b' is the edge direction inserted in column 'a', the index of this edge
		    	 -- the new restriction is that the edges ''around'' this codim2 Cone must add up to 0
		    	 entries(hyperplanesTmpnew_{0..a-2} | b | hyperplanesTmpnew_{a..m-1})));
	       if hyperplanesTmp != {} then hyperplanesTmp = matrix hyperplanesTmp
	       else hyperplanesTmp = map(ZZ^0,ZZ^m,0);
	       -- Find an interior vector in the cone of all positive vectors satisfying the restrictions
	       v := flatten entries interiorVector intersection(id_(ZZ^m),hyperplanesTmp);
	       M := {};
	       -- If the vector is strictly positive then there is a polytope with 'F' as normalFan
	       if all(v, e -> e > 0) then (
	       	    -- Construct the polytope
	       	    i = 1;
	       	    -- Start with the origin
	       	    p := map(ZZ^n,ZZ^1,0);
	       	    M = {p};
	       	    Lyes := {};
	       	    Lno := {};
	       	    vlist := apply(keys edgeTCTable,toList);
	       	    -- Walk along all edges recursively
	       	    edgerecursion := (i,p,vertexlist,Mvertices) -> (
		    	 vLyes := {};
		    	 vLno := {};
		    	 -- Sorting those edges into 'vLyes' who emerge from vertex 'i' and the rest in 'vLno'
		    	 vertexlist = partition(w -> member(i,w),vertexlist);
		    	 if vertexlist#?true then vLyes = vertexlist#true;
		    	 if vertexlist#?false then vLno = vertexlist#false;
		    	 -- Going along the edges in 'vLyes' with the length given in 'v' and calling edgerecursion again with the new index of the new 
		    	 -- top Cone, the new computed vertex, the remaining edges in 'vLno' and the extended matrix of vertices
		    	 scan(vLyes, w -> (
			      	   w = toSequence w;
			      	   j := edgeTCNoTable#w;
			      	   if w#0 == i then (
				   	(vLno,Mvertices) = edgerecursion(w#1,p+(j#1)*(v#((j#0)-1)),vLno,append(Mvertices,p+(j#1)*(v#((j#0)-1)))))
			      	   else (
				   	(vLno,Mvertices) = edgerecursion(w#0,p-(j#1)*(v#((j#0)-1)),vLno,append(Mvertices,p-(j#1)*(v#((j#0)-1)))))));
		    	 (vLno,Mvertices));
	       	    -- Start the recursion with vertex '1', the origin, all edges and the vertexmatrix containing already the origin
	       	    M = unique ((edgerecursion(i,p,vlist,M))#1);
	       	    M = matrix transpose apply(M, m -> flatten entries m);
	       	    -- Computing the convex hull
	       	    F.cache.polytope = convexHull M;
	       	    F.cache.isPolytopal = true)));
     F.cache.isPolytopal)


-- PURPOSE : Computing the stellar subdivision
--   INPUT : '(F,r)', where 'F' is a Fan and 'r' is a ray
--  OUTPUT : A fan, which is the stellar subdivision
stellarSubdivision = method()
stellarSubdivision (Fan,Matrix) := Fan => (F,r) -> (
     -- Checking for input errors
     if numColumns r != 1 or numRows r != ambDim F then error("The ray must be given by a one column matrix in the ambient dimension of the fan");
     divider := (C,r) -> if dim C != 1 then flatten apply(faces(1,C), f -> if not contains(f,r) then posHull {f,r} else divider(f,r)) else {C};
     L := flatten apply(maxCones F, C -> if contains(C,r) then divider(C,r) else {C});
     L = sort select(L, l -> all(L, e -> not contains(e,l) or e == l));
     n := dim L#0;
     R := unique(rays F|{promote(r,QQ)});
     new Fan from {
	  "generatingObjects" => set L,
	  "ambient dimension" => ambDim L#0,
	  "dimension" => n,
	  "number of generating cones" => #L,
	  "rays" => set R,
	  "number of rays" => #R,
	  "isPure" => dim L#0 == dim last L,
	  symbol cache => new CacheTable})






-- PURPOSE : Computes the coarsest common refinement of a given set of rays
--   INPUT : 'M'  a Matrix
--  OUTPUT : 'F'  a Fan, the coarsest common refinement of the rays in 'M'
ccRefinement = method(TypicalValue => Fan)
ccRefinement Matrix := M -> (
     -- Checking for input errors
     M = chkZZQQ(M,"rays");
     -- Extracting data
     n := numRows M;
     m := numColumns M;
     -- Generating all cones generated by 'n' rays in 'M'
     nCones := apply(subsets(m,n), e -> posHull M_e);
     -- Selecting those cones that are 'n' dimensional and do not contain any 
     -- of the others
     nConesfd := select(nCones, C -> dim C == n);
     nConesfd = inclMinCones nConesfd;
     refCones := {};
     while nConesfd != {} do (
	  newCones := {};
	  -- scan through the 'n' dimensional cones and check for each of the cones generated by
	  -- 'n' rays if their intersection is 'n' dimensional and if the first one is not contained 
	  -- in the latter. If true, then their intersection will be saved in the list 'newCones'.
	  -- If false for every cone generated by 'n' rays, then the 'n' dimensional cone will be 
	  -- appended to the list 'refCones'
	  refCones = refCones | (flatten apply(nConesfd, C1 -> (
			 toBeAdded := flatten apply(nCones, C2 -> (
				   C := intersection(C2,C1);
				   if dim C == n and (not contains(C2,C1)) then C
				   else {}));
			 if toBeAdded == {} then C1
			 else (
			      newCones = newCones | toBeAdded;
			      {}))));
	  -- now, the new intersections will be the 'n' dimensional cones and the same procedure 
	  -- starts over again if this list is not empty
	  nConesfd = unique newCones);
     -- Compute the fan generated by the 'refCones'
     fan refCones);
