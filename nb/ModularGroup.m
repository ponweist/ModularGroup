(* ::Package:: *)

(* 
 * Mathematica package ModularGroup, version 0.1 
 *)

(*
 * The MIT License (MIT)
 *
 * Copyright (C) 2014 Thomas Ponweiser
 *
 * Permission is hereby granted, free of charge, to any person obtaining a 
 * copy of this software and associated documentation files (the "Software"), 
 * to deal in the Software without restriction, including without limitation 
 * the rights to use, copy, modify, merge, publish, distribute, sublicense, 
 * and/or sell copies of the Software, and to permit persons to whom the 
 * Software is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in 
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
 * DEALINGS IN THE SOFTWARE.
 *)


(* 
 * Helper package for "object-oriented programming" (OOP) needed by main 
 * package ModularGroup.
 *)
BeginPackage["ModularGroup`OOP`"];

Unprotect[Class, NewClass, New, Init, Super, InstanceQ, Info];
Unprotect[Iterator, ListIterator, HasNext, GetNext];

(* ---------------------------------------------------------- Public Elements *)

Class::usage = 
  "Class is a reserved symbol identifying the type of a class.";
NewClass::usage = 
  "NewClass[c] declares the symbol c to be a class.";
NewAbstractClass::usage =
  "NewAbstractClass[c] declares the symbol c to be an abstract class.";

AbstractQ::usage =
  "AbstractQ[c] returns True if c is an abstract class.";

New::usage = StringJoin[
  "New[c, args...] instantiates an objtect of class c, ",
  "passing the given arguments to its constructor."
];
New::notaclass = "`1` is not a class.";
New::abstractinst = "`1` is an abstract class and cannot be instantiated.";

Init::usage = StringJoin[
  "Init[c, o, args...] defines the constructor of a class c ",
  "and initializes the new object o. ",
  "Never call directly, use o = New[c, args...] instead."
];
Init::undef = StringJoin[
  "Constructor for class `1` and arguments `2` not defined. ",
  "Make sure you have defined Init[`1`, obj_, args___] ^:= ..."
];

Super::usage = StringJoin[
  "Super[b, o, args...] calls the constructor of a base-class b ",
  "for a new object o. ",
  "To be used within the Init function of a class c which inherits from b."
];

InstanceQ::usage = StringJoin[
  "InstanceQ[c][o] returns True, if the object o is instance of class c."
];

Info::usage = StringJoin[
  "Info[o] displays data associated with the object o."
];

Iterator::usage = StringJoin[
  "Iterator is an abstract base class for objects o providing methods ",
  "HasNext[o] and GetNext[o]."
];

HasNext::usage =
  "HasNext[o] tests if the Iterator o has a next element.";

GetNext::usage =
  "GetNext[o] returns the next value of the Iterator o.";

ListIterator::usage =
  "New[ListIterator, l] creates an iterator for the objects in the list l.";

Begin["`Private`"];

NewClass[class_] := (
  class /: InstanceQ[Class][class] = True;
  class /: Init[class, obj_, args___] := (
    Message[Init::undef, class, {args}];
    $Failed
  );
);
NewAbstractClass[class_] := (
  NewClass[class];
  AbstractQ[class] ^= True;
);

New[class_?(InstanceQ[Class]), args___] := (
  If[TrueQ@AbstractQ@class, (
    Message[New::abstractclass, class];
    $Failed
  ), (
    Module[{obj = Unique[class]},
      Super[class, obj, args];
      obj
    ]
  )]
);

New[notaclass_, args___] := (
  Message[New::notaclass, notaclass];
  $Failed
);

Super[class_?(InstanceQ[Class]), obj_, args___] := (
  Init[class, obj, args];
  obj /: InstanceQ[class][obj] = True;
);

Info[obj_] := Information@Evaluate@obj;

NewAbstractClass[Iterator];
Init[Iterator, obj_] ^:= Null;

NewClass[ListIterator];
Init[ListIterator, obj_, list_] ^:= (
  Super[Iterator, obj];
  Pos[obj] ^= 1;
  HasNext[obj] ^:= Pos[obj] <= Length[list];
  GetNext[obj] ^:= Module[{next}, 
    next = list[[Pos[obj]]]; 
    Pos[obj] ^= Pos[obj]+1;
    next
  ];
);

End[];

Protect[Class, NewClass, New, Init, Super, InstanceQ, Info];
Protect[Iterator, ListIterator, HasNext, GetNext];

EndPackage[];


(*
 * Helper package with generic queue data structures and enumeration 
 * algorithms used by main package ModularGroup.
 *)
BeginPackage["ModularGroup`Queue`", {"ModularGroup`OOP`"}];

Unprotect[Queue, Enqueue, Dequeue, EmptyQ];
Unprotect[FifoQueue, LifoQueue, PriorityQueue];
Unprotect[SearchIteartor, BFSIterator, DFSIterator, PFSIterator];

(* ---------------------------------------------------------- Public Elements *)

Queue::usage = 
  "Queue is an abstract base class for queues and cannot be instantiated.";

Enqueue::usage =
  "Enqueue[q, e] enqueues the element e to the queue q.";

Dequeue::usage =
  "Dequeue[q] returns the element at the top of the queue q.";

EmptyQ::usage =
  "EmptyQ[q] tests if queue q is empty.";

FifoQueue::usage = 
  "New[FifoQueue] constructs an empty first-in-first-out queue.";

LifoQueue::usage = StringJoin[
  "New[LifoQueue] constructs an empty last-in-first-out queue, ",
  "also known as stack."
];

PriorityQueue::usage = StringJoin[
  "New[PriorityQueue, p] constructs an empty priority queue ",
  "with p as the ordering predicate."
];

SearchIterator::usage = StringJoin[
  "it = New[SearchIterator, q, f, p] constructs an iterator over a sequence ",
  "which is defined by the initial contents of the Queue q, ",
  "a transition function f and a predicate p.",
  "\nHasNext[it] returns True as long as q contains elements satisfying p.",
  "\nGetNext[it] returns the first element t of q which satisfies p ",
  "and enqueues all elements f[t]={a,b,c,...} to q."
];

BFSIterator::usage = StringJoin[
  "New[BFSIterator, s, f, p] constructs an iterator ",
  "for performing a breadth-first-search ",
  "starting with the element s. For any element e, ",
  "f[e] should return a (possibly empty) list of elements to be visited next."
];

DFSIterator::usage = StringJoin[
  "New[DFSIterator, s, f] constructs an iterator ",
  "for performing a depth-first-search ",
  "starting with the element s. For any element e, ",
  "f[e] should return a (possibly empty) list of elements to be visited next."
];

PFSIterator::usage = StringJoin[
  "New[PFSIterator, s, f, o, p] constructs an iterator ",
  "for performing a priority-first-search ",
  "starting with the element s and using the ordering predicate o. ",
  "For any element e, ",
  "f[e] should return a (possibly empty) list of elements to be visited next."
];

Begin["`Private`"];

(* -------------------------------------------------------------- Class Queue *)
NewAbstractClass[Queue];

Init[Queue, obj_] ^:= Null;

(* ---------------------------------------------------------- Class FifoQueue *)
NewClass[FifoQueue];

Init[FifoQueue, obj_] ^:= (
  Super[Queue, obj];
  Contents@obj ^= {};
);

Enqueue[queue_?(InstanceQ[FifoQueue]), elem_] := (
  Contents@queue ^= Append[Contents@queue, elem];
);

EmptyQ[queue_?(InstanceQ[FifoQueue])] := (
  Length@Contents@queue == 0
);

Dequeue[queue_?(InstanceQ[FifoQueue])] := 
Module[{elem},
  elem = First@Contents@queue;
  Contents@queue ^= Rest@Contents@queue;
  elem
];

(* ---------------------------------------------------------- Class LifoQueue *)
NewClass[LifoQueue];

Init[LifoQueue, obj_] ^:= (
  Super[Queue, obj];
  Contents@obj ^= {};
);

Enqueue[queue_?(InstanceQ[LifoQueue]), elem_] := (
  Contents@queue ^= {elem, Contents@queue};
);

EmptyQ[queue_?(InstanceQ[LifoQueue])] := (
  Length@Contents@queue == 0
);

Dequeue[queue_?(InstanceQ[LifoQueue])] := 
Module[{elem},
  elem = Contents[queue][[1]];
  Contents@queue ^= Contents[queue][[2]];
  elem
];

(* ------------------------------------------------------ Class PriorityQueue *)
NewClass[PriorityQueue];

Init[PriorityQueue, obj_, orderingFunction_] ^:= (
  Super[Queue, obj];
  OrderingFunction[obj] ^= orderingFunction;
  Contents[obj] ^= Table[Null, {i,16}];
  Size[obj] ^= 0;
);

Enqueue[queue_?(InstanceQ[PriorityQueue]), elem_] := 
Module[{contents},
  contents = Grow[queue];
  Size@queue ^= Size@queue + 1;
  contents[[Size@queue]] = elem;
  Contents@queue ^= contents;
  Contents@queue ^= HeapUp[queue];
];

Grow[queue_] := Module[{contents, capacity},
  contents = Contents@queue;
  capacity = Length@contents;
  If[Size@queue >= capacity,
    contents = Join[contents, Table[Null, {i, capacity}]];
  ]; 
  contents
];

HeapUp[queue_] := 
Module[{contents, orderingFunction, i, p},
  contents = Contents@queue;
  orderingFunction = OrderingFunction@queue;
  i = Size@queue;
  p = BitShiftRight[i, 1];
  While[p > 0 && !orderingFunction[contents[[p]], contents[[i]]],
    {contents[[p]], contents[[i]]} = {contents[[i]], contents[[p]]};
    i = p; 
    p = BitShiftRight[p, 1];
  ]; 
  contents
];

EmptyQ[queue_?(InstanceQ[PriorityQueue])] := (
  Size@queue == 0
);

Dequeue[queue_?(InstanceQ[PriorityQueue])] := 
Module[{contents, top},
  contents = Contents@queue;
  top = contents[[1]];
  contents[[1]] = contents[[Size[queue]]];
  Size[queue] ^= Size[queue] - 1;
  Contents@queue ^= contents;
  Contents@queue ^= HeapDown[queue];
  top
];

HeapDown[queue_] :=
Module[{contents, orderingFunction, size, i, c},
  contents = Contents@queue;
  orderingFunction = OrderingFunction@queue;
  size = Size@queue;
  i = 1;
  c = SmallerChild[contents, queue, i];
  While[c <= size && !orderingFunction[contents[[i]], contents[[c]]],
    {contents[[i]], contents[[c]]} = {contents[[c]], contents[[i]]};
    i = c;
    c = SmallerChild[contents, queue, i];
  ];
  contents
];

SmallerChild[contents_, queue_, i_] := 
Module[{c},
  c = BitShiftLeft[i, 1];
  If[c+1 <= Size@queue && OrderingFunction[queue][contents[[c+1]], contents[[c]]],
    c++;
  ];
  c
];

(* --------------------------------------------------------- Class Enumerator *)
NewClass[SearchIterator];
Init[SearchIterator, obj_, queue_?(InstanceQ[Queue]), f_, p_:(True&)] ^:= 
Module[{current, next, hasNext, SetNext},
  SetNext := (
    hasNext = False;
    While[!EmptyQ[queue] && !(hasNext = p[next = Dequeue[queue]])];
  );
  SetNext;
  HasNext[obj] ^:= hasNext;
  GetNext[obj] ^:= (
    current = next; 
    Enqueue[queue, #]& /@ f[current];
    SetNext;
    current
  );
];

NewClass[BFSIterator];
Init[BFSIterator, obj_, s_, f_, p_:(True&)] ^:= Module[{fifo},
  fifo = New[FifoQueue];
  If[Head[s] === List, Enqueue[fifo, #]& /@ s, Enqueue[fifo,s]];
  Super[SearchIterator, obj, fifo, f, p];
];

NewClass[DFSIterator];
Init[DFSIterator, obj_, s_, f_, p_:(True&)] ^:= Module[{stack},
  stack = New[LifoQueue];
  If[Head[s] === List, Enqueue[stack, #]& /@ s, Enqueue[stack,s]];
  Super[SearchIterator, obj, stack, f, p];
];

NewClass[PFSIterator];
Init[PFSIterator, obj_, s_, f_, o_, p_:(True&)] ^:= Module[{heap},
  heap = New[PriorityQueue, o];
  If[Head[s] === List, Enqueue[heap, #]& /@ s, Enqueue[heap,s]];
  Super[SearchIterator, obj, heap, f, p];
];

End[];

Protect[Queue, Enqueue, Dequeue, EmptyQ];
Protect[FifoQueue, LifoQueue, PriorityQueue];
Protect[SearchIteartor, BFSIterator, DFSIterator, PFSIterator];

EndPackage[];


(*
 * The definitions for the main package ModularGroup start here.
 *)
BeginPackage["ModularGroup`", {"ModularGroup`OOP`", "ModularGroup`Queue`"}];


(* ---------------------------------------------------------- Public Elements *)

MoebiusTransformation::usage = StringJoin[
  "New[MoebiusTransformation, {{a, b}, {c, d}}] ",
  "creates the moebius transformation ",
  "z \[RightTeeArrow] \!\(\*FractionBox[\(\(a\[CenterDot]z\)\(\\\ \)\(+\)\(\\\ \)\(b\)\(\\\ \)\), \(c\[CenterDot]z\\\  + \\\ d\)]\)."
];
Mat::usage = 
  "Mat[t] returns the coefficients of the MoebiusTransformation t as matrix.";
Inv::usage = 
  "Inv[t] returns the inverse of the MoebiusTransformation t.";

mtModCayley::usage =
  "mtModCayley is the modified Cayley transform z \[RightTeeArrow] (\[ImaginaryI]z+1)/(z+\[ImaginaryI]).";

PSL2CInv::usage = 
  "PSL2CInv[m] returns a matrix which is inverse to m within \!\(\*SubscriptBox[\(PSL\), \(2\)]\)(\[DoubleStruckCapitalC])";
PSL2ZInv::usage = 
  "PSL2ZInv[m] returns a matrix which is inverse to m within \!\(\*SubscriptBox[\(PSL\), \(2\)]\)(\[DoubleStruckCapitalZ])";
PSL2ZNormalForm::usage = StringJoin[
  "PSL2ZNormalForm[m] returns a scalar multiple ",
  "{{a,b},{c,d}} = \[PlusMinus]m of the matrix m \[Element] \!\(\*SubscriptBox[\(PSL\), \(2\)]\)(\[DoubleStruckCapitalZ]) ",
  "such that c > 0 && (c == 0 || a > 0)."
];
PSL2ZGrading::usage = StringJoin[
  "PSL2ZGrading[m] returns the sum of the squared coefficients ",
  "of the matrix m \[Element] \!\(\*SubscriptBox[\(PSL\), \(2\)]\)(\[DoubleStruckCapitalZ])."
];
RandomPSL2Z::usage = StringJoin[
  "RandomPSL2Z[n,N] returns a list of n random matrices within \!\(\*SubscriptBox[\(PSL\), \(2\)]\)(\[DoubleStruckCapitalZ]) ",
  "with coefficient absolute values <= N."
];

Inhom::usage = 
  "Inhom[{z1,z2}] returns z1 / z2 or ComplexInfinity, if z2 == 0.";

ModularTransformation::usage = StringJoin[
  "New[ModularTransformation, {{a, b}, {c, d}}] ",
  "creates the modular transformation ",
  "z \[RightTeeArrow] \!\(\*FractionBox[\(\(a\[CenterDot]z\)\(\\\ \)\(+\)\(\\\ \)\(b\)\(\\\ \)\), \(c\[CenterDot]z\\\  + \\\ d\)]\)."
];

TRList::usage = StringJoin[
  "TRList[t] returns the factors of unique R-T-product representation ",
  "of the modular transformation t as list ",
  "consisting of the ModularTransformations mtT, mtR and Inv@mtR. ", 
  "The transformation t may be given in matrix form ",
  "or as ModularTransformation object. "
];

TRRight::usage = StringJoin[
  "TRRight[t] returns the rightmost factor of the unique R-T-product representation ",
  "of the modular transformation t, which may be given in matrix form ",
  "or as ModularTransformation object. ",
  "The return value is one of the ModularTransformations mtT, mtR and Inv@mtR.\n",
  "TRRight[t] is equivalent to Last[TRList[t]]."
];

TRIndicateLeft::usage = StringJoin[
  "TRIndicateLeft[t] returns one of the numbers -1, 0 or 1, ",
  "depending on the leftmost factor of the unique R-T-product representation ",
  "of the modular transformation t, given in matrix form. ",
  "The meaning of the numbers is: -1\[RightArrow]\!\(\*SuperscriptBox[\(R\), \(-1\)]\) - 0\[RightArrow]T - 1\[RightArrow]R."
];
TRIndicateRight::usage = StringJoin[
  "TRIndicateRight[t] returns one of the numbers -1, 0 or 1, ",
  "depending on the rightmost factor of the unique R-T-product representation ",
  "of the modular transformation t given in matrix form. ",
  "The meaning of the numbers is: -1\[RightArrow]\!\(\*SuperscriptBox[\(R\), \(-1\)]\) - 0\[RightArrow]T - 1\[RightArrow]R."
];

TRIndicatorList::usage = StringJoin[
  "TRIndicatorList[t] returns a list of numbers -1, 0 or 1, ",
  "representing the unique R-T-product representation ",
  "of the modular transformation t given in matrix form. ",
  "The meaning of the numbers is: -1\[RightArrow]\!\(\*SuperscriptBox[\(R\), \(-1\)]\) - 0\[RightArrow]T - 1\[RightArrow]R."
];

TRLeft::usage = StringJoin[
  "Returns the leftmost factor of the unique R-T-product representation ",
  "of the modular transformation t, which may be given in matrix form ",
  "or as ModularTransformation object. ",
  "The return value is one of the ModularTransformations mtT, mtR and Inv@mtR.\n", 
  "TRLeft[t] is equivalent to First[TRList[t]]."
];


TRWord::usage = StringJoin[
  "TRWord[t] returns the unique R-T-group word representation ",
  "of the modular transformation t which may be given in matrix form ",
  "or as ModularTransformation object."
];

TUExponents::usage = StringJoin[
  "TUExponents[t] returns for a ModularTransformation t a list of exponents ",
  "{\!\(\*SubscriptBox[\(e\), \(0\)]\),...,\!\(\*SubscriptBox[\(e\), \(n\)]\)} ",
  "such that t = \!\(\*SuperscriptBox[\(U\), SubscriptBox[\(e\), \(0\)]]\)\!\(\*SuperscriptBox[\(TU\), SubscriptBox[\(e\), \(1\)]]\)...\!\(\*SuperscriptBox[\(TU\), SubscriptBox[\(e\), \(n\)]]\).",
  "\nThe option QuotientFunction is supported."
];
 
QuotientFunction::usage = StringJoin[
  "QuotientFunction is an option which defines the ",
  "integer quotient function to be used within the Euclidean algorithm. ",
  "Default is Mathematica's built-in function Quotient. ",
  "Predefined alternatives are CentralQuotient and CQuotient."
];

CentralQuotient::usage = StringJoin[
  "CentralQuotient[m,n] returns the integer quotient q of m = q n + r, ",
  "such that -n/2 \[LessEqual] r < n/2 (for positive q and n).\n",
  "CentralQuotient[m,n] is eqivalent to Quotient[m, n, -n/2]"
];

CQuotient::usage = StringJoin[
  "CQuotient[m,n] returns the integer quotient of m and n ",
  "with rounding towards 0 ",
  "(equivalent to integer division e.g. in the programming language C)."
];

TUEval::usage = StringJoin[
  "TUEval[t, subsT, subsU, product, power] ",
  "substitutes the symbols T and U ",
  "in the group word representation of the ModularTransformation t ",
  "with subsT and subsU respectively ",
  "and evaluates using the provided product and power functions.",
  "\nExample: TUEval[phi, Mat[mtT], Mat[mtU], Dot, MatrixPower]",
  "\nThe option QuotientFunction is supported."
];

TUWord::usage = StringJoin[
  "TUWord[t] returns a symbolic group word representation ",
  "of the ModularTransformation t in terms of the group generators T and U.",
  "\nThe option QuotientFunction is supported."
];

AssociatedMap::usage = StringJoin[
  "AssociatedMap[z] returns the matrix ",
  "of a modular transformation A, ",
  "such that z \[Element] A(F), where F is the fundamental region, ",
  "F = {x \[Element] \[DoubleStruckCapitalC] | Abs[Re[x]] <= 1/2 && Abs[x] >= 1}."
];

InvAssociatedMap::usage = StringJoin[
  "InvAssociatedMap[z] returns the matrix ",
  "of a modular transformation A, ",
  "such that Az \[Element] F, where F is the fundamental region, ",
  "F = {x \[Element] \[DoubleStruckCapitalC] | Abs[Re[x]] <= 1/2 && Abs[x] >= 1}."
];

(* Some frequently used ModularTransformations *)
mtId::usage = StringJoin[
  "mtId is the identity element ",
  "of the classes MoebiusTransformation and ModularTransformation."
];

mtU::usage = "mtU is the ModularTransformation U: z \[RightTeeArrow] z+1.";
mtT::usage = "mtT is the ModularTransformation T: z \[RightTeeArrow] -\!\(\*FractionBox[\(1\), \(z\)]\).";
mtR::usage = "mtR is the ModularTransformation R = TU : z \[RightTeeArrow] -\!\(\*FractionBox[\(1\), \(z + 1\)]\).";

GeneralizedDisk::usage = StringJoin[
  "New[GeneralizedDisk, {{a, b},{c, d}}] constructs the a generalized disk ", 
  "whose points z satisfy a\[CenterDot]|z\!\(\*SuperscriptBox[\(|\), \(2\)]\) + b\[CenterDot]\!\(\*OverscriptBox[\(z\), \(_\)]\) + c\[CenterDot]z + d \[LessSlantEqual] 0. ",
  "The matrix {{a, b}, {c, d}} must be Hermitian with negative determinant."
];
NoncompactDisk::usage = StringJoin[
  "New[NoncompactDisk, c, r] constructs a GeneralizedDisk ",
  "which contains the point \[Infinity] and whose complement in \[DoubleStruckCapitalC] is a disk ",
  "with center c and radius r."
];
Halfplane::usage = StringJoin[
  "New[Halfplane, z, n] constructs a GeneralizedDisk ",
  "containing all points of a half-plane ",
  "which is given by a point z on its border ",
  "and a complex number n pointing inside the half-plane ",
  "in normal direction to its border."
];
CompactDisk::usage = StringJoin[
  "New[CompactDisk, c, r] constructs a GeneralizedDisk ",
  "with center c and radius r."
];
InteriorQ::usage = StringJoin[
  "InteriorQ[d, z] tests if the GeneralizedDisk d contains the point z, ",
  "which also may be given in homogeneous form."
];

(* Some predefined GeneralizedDisks *)
gdUnitDisk::usage =
  "gdUnitDisk is the set of points z satisfying |z| \[LessEqual] 1.";
gdUpperHalfplane::usage =
  "gdUpperHalfPlane is the set of points z satisfying Im[z] \[GreaterSlantEqual] 0.";
gdLowerHalfplane::usage =
  "gdLowerHalfPlane is the set of points z satisfying Im[z] \[LessSlantEqual] 0.";
gdRightHalfplane::usage =
  "gdRightHalfPlane is the set of points z satisfying Re[z] \[GreaterSlantEqual] 0.";
gdLeftHalfplane::usage =
  "gdLeftHalfPlane is the set of points z satisfying Re[z] \[LessSlantEqual] 0.";
gdUnitCodisk::usage = 
  "gdUnitCodisk is the set of points z satisfying |z| \[GreaterSlantEqual] 1.";
gdFord0::usage = 
  "gdFord0 is the ford circle at infinity, i.e. the set of points z satisfying Im[z] \[GreaterSlantEqual] 1";
gdIncircle0::usage = StringJoin[
  "gdIncircle0 is the GeneralziedDisk ",
  "corresponding to the incircle of the standard fundamental domain, ",
  "i.e. the disk around the point \!\(\*FractionBox[\(3  \[ImaginaryI]\), \(2\)]\) with radius \!\(\*FractionBox[\(1\), \(2\)]\)."
];

GDiskRadius::usage = StringJoin[
  "GDiskRadius[d] returns the radius of the GeneralizedDisk d. ", 
  "It is defined for CompactDisks only."
];
GDiskCenter::usage = StringJoin[
  "GDiskCenter[d] returns the center of a GeneralizdeDisk d. ",
  "It is defined for CompactDisks only."
];
GDiskCoradius::usage = StringJoin[
  "GDiskCoradius[d] returns the co-radius of a GeneralizedDisk d. ",
  "It is defined for NoncompactDisks only."
];
GDiskCocenter::usage = StringJoin[
  "GDiskCocenter[d] returns the co-center of a GeneralizedDisk d. ",
  "It is defined for NoncompactDisks only."
];
GDiskMatRadius::usage = StringJoin[
  "GDiskMatRadius[m] returns the radius or coradius ",
  "of the generalized disk corresponding to the matrix m. ",
  "The matrix m must be Hermitian with negative determinant."
];
GDiskMatCenter::usage = StringJoin[
  "GDiskMatCenter[m] returns the center ", 
  "of the generalized disk corresponding to the matrix m. ",
  "The matrix m must be Hermitian with negative determinant."
];
GDiskMatClass::usage = StringJoin[
  "GDiskMatClass[m] returns -1, 0 or 1, indicating if ",
  "if the generalized disk corresponding to the matrix m is ",
  "a compact disk (1), a half-plane (0), or a non-compact disk (-1). ",
  "The matrix m must be Hermitian with negative determinant."
];  
GDiskMatMap::usage = StringJoin[
  "GDiskMatMap[m, t] returns the image ",
  "of the generalized disk corresponding to the matrix m ",
  "under the Moebius transformation t as matrix. ",
  "The transformation t must be given matrix form.",
  "The matrix m must be Hermitian with negative determinant."
];

GDisk::usage = StringJoin[
  "GDisk[d] gives a two-dimensional graphics object ",
  "representing the GeneralizedDisk d.",
  "\nGDisk[d, {\!\(\*SubscriptBox[\(t\), \(1\)]\),\!\(\*SubscriptBox[\(t\), \(2\)]\),...}] ",
  "draws all Moebius transformed GeneralizedDisks \!\(\*SubscriptBox[\(t\), \(1\)]\)[d], \!\(\*SubscriptBox[\(t\), \(2\)]\)[d], ...",
  "\nThe option GDiskNPoints is supported."
];
GDiskNPoints::usage = StringJoin[
  "GDiskNPoints is an option of GDisk. It specifies, how many points are used ",
  "in the approximation of the boundary of a NoncompactDisk with a regular n-gon."
];

GCircle::usage = StringJoin[
  "GCircle[d] gives a two-dimensional grphics object ",
  "representing the boundary of the GeneralizedDisk d.",
  "\nGCircle[d, {\!\(\*SubscriptBox[\(t\), \(1\)]\),\!\(\*SubscriptBox[\(t\), \(2\)]\),...}] ",
  "draws all boundaries of the Moebius transformed GeneralizedDisks \!\(\*SubscriptBox[\(t\), \(1\)]\)[d], \!\(\*SubscriptBox[\(t\), \(2\)]\)[d], ..."
];

GDiskLabel::usage = StringJoin[
  "GDiskLabel[d, {\!\(\*SubscriptBox[\(t\), \(1\)]\),\!\(\*SubscriptBox[\(t\), \(2\)]\),...}, {\!\(\*SubscriptBox[\(l\), \(1\)]\),\!\(\*SubscriptBox[\(l\), \(2\)]\),...}] ",
  "can be used for labelling compact disks or circles drawn with GDisk or GCircle. ",
  "GDiskLabel outputs the list {Text[\!\(\*SubscriptBox[\(l\), \(1\)]\), \!\(\*SubscriptBox[\(p\), \(1\)]\)], Text[\!\(\*SubscriptBox[\(l\), \(2\)]\), \!\(\*SubscriptBox[\(p\), \(2\)]\)],...} where each \!\(\*SubscriptBox[\(p\), \(i\)]\) is the ",
  "center of the Moebius transformed disk \!\(\*SubscriptBox[\(t\), \(i\)]\)[d]. ",
  "\nThe option Magnification is supported. ",
  "If Magnification is set to a numerical value m, ",
  "(default: Magnification -> Off) ",
  "each label \!\(\*SubscriptBox[\(l\), \(\(i\)\(\\\ \)\)]\)is magnified by the factor m\[CenterDot]\!\(\*SubscriptBox[\(r\), \(i\)]\), ",
  "where \!\(\*SubscriptBox[\(r\), \(i\)]\) is the radius of the Moebius transformed disk \!\(\*SubscriptBox[\(t\), \(i\)]\)[d]."
];
GDiskLabel::listlength = StringJoin[
  "Number of disks and labels does not match."
];
GDiskLabel::noncompact = StringJoin[
  "Labels for noncompact disks are not yet supported."
]; 

ModularTiling::usage = StringJoin[
  "ModularTiling[{\!\(\*SubscriptBox[\(m\), \(1\)]\), \!\(\*SubscriptBox[\(m\), \(2\)]\),...}, t] produces a graphic ",
  "of the tiling of the upper half-plane associated to the modular group, ",
  "transformed by the given MoebiusTransformation t. ", 
  "By default, the output is just the orbit of the unit circle ",
  "under the given ModularTransformations \!\(\*SubscriptBox[\(m\), \(1\)]\), \!\(\*SubscriptBox[\(m\), \(2\)]\), ..., ",
  "(ModularGroupList may be used to generate a appropriate list of ModularTransformations). ",
  "\nFollowing Options are supported (default values are underlined): ",
  "\nInteriorMode \[Rule] GDisk/GCircle/\!\(\*
StyleBox[\"Off\",\nFontVariations->{\"Underline\"->True}]\): Function for drawing the (transformed) upper half-plane. ",
  "\nInteriorStyle \[Rule] \!\(\*
StyleBox[\"Black\",\nFontVariations->{\"Underline\"->True}]\): Graphics style for drawing the (transformed) upper half-plane. ",
  "\nBorderMode \[RightArrow] \!\(\*
StyleBox[\"GCircle\",\nFontVariations->{\"Underline\"->True}]\)/Off: Function for drawing the (transformed) real axis. ",
  "\nBoderStyle \[Rule] \!\(\*
StyleBox[\"Black\",\nFontVariations->{\"Underline\"->True}]\): Style for drawing the (transformed) real axis. ",
  "\nExteriorMode \[Rule] \!\(\*
StyleBox[\"GDisk\",\nFontVariations->{\"Underline\"->True}]\)/GCircle/Off: Function for drawing the (transformed) lower half-plane. ", 
  "\nExteriorStyle \[Rule] \!\(\*
StyleBox[\"White\",\nFontVariations->{\"Underline\"->True}]\): Graphics style for drawing the (transformed) lower half-plane. ", 
  "\nTilingMode \[Rule] GDisk/\!\(\*
StyleBox[\"GCircle\",\nFontVariations->{\"Underline\"->True}]\)/Off: Function for drawing the orbit of the unit disk (tiling). ",
  "\nTilingStyle \[Rule] \!\(\*
StyleBox[\"Black\",\nFontVariations->{\"Underline\"->True}]\): Graphics style for drawing the orbit of the unit disk (tiling). ",
  "\nTilingThreshold \[Rule] 0: Minimum radius for drawing tiling arcs. ",
  "\nExtendedTilingMode \[Rule] GDisk/GCircle/\!\(\*
StyleBox[\"Off\",\nFontVariations->{\"Underline\"->True}]\): Function for drawing the orbit of the imaginary axis (extended tiling). ",
  "\nExtendedTilingStyle \[Rule] \!\(\*
StyleBox[\"Gray\",\nFontVariations->{\"Underline\"->True}]\): Graphics style for drawing the orbit of the imaginary axis (extended tiling). ",
  "\nFordDiskMode \[Rule] GDisk/GCircle/\!\(\*
StyleBox[\"Off\",\nFontVariations->{\"Underline\"->True}]\): Function for drawing ford circles. ",
  "\nFordDiskStyle \[Rule] \!\(\*
StyleBox[\"Brown\",\nFontVariations->{\"Underline\"->True}]\): Graphics style for drawing ford circles. ",
  "\nFordDiskThreshold \[Rule] 0: Minimum radius for drawing ford circles. ",
  "\nIncircleMode \[Rule] GDisk/GCircle/\!\(\*
StyleBox[\"Off\",\nFontVariations->{\"Underline\"->True}]\): Function for drawing incircles of tiles. ",
  "\nIncircleStyle \[Rule] \!\(\*
StyleBox[\"Blue\",\nFontVariations->{\"Underline\"->True}]\): Graphics style for drawing incircles of tiles. ",
  "\nIncircleThreshold \[Rule] 0: Minimum radius for drawing incircles. ",
  "\nLabelMode \[Rule] TUWord/TRWord/Mat/.../\!\(\*
StyleBox[\"Off\",\nFontVariations->{\"Underline\"->True}]\): Function for printing tile labels. ",
  "\nLabelStyle \[Rule] \!\(\*
StyleBox[\"Black\",\nFontVariations->{\"Underline\"->True}]\): Style for printing tile lables. ",
  "\nLabelThreshold \[Rule] \!\(\*SuperscriptBox[\(2\), \(-3\)]\): Minimum inradius of tiles for printing tile labels. ",
  "\nMagnification \[Rule] n/\!\(\*
StyleBox[\"Off\",\nFontVariations->{\"Underline\"->True}]\): If set to a numerical value n, labels are magnified with a factor n\[CenterDot]r, where r is the according tile inradius. " 
];
Options[ModularTiling] = {
  InteriorMode -> Off, InteriorStyle -> Black,
  ExteriorMode -> GDisk, ExteriorStyle -> White,
  BorderMode -> GCircle, BorderStyle -> Black,
  TilingMode -> GCircle, TilingStyle -> Black, TilingThreshold -> 0,
  ExtendedTilingMode -> Off, ExtendedTilingStyle -> Gray,
  FordDiskMode -> Off, FordDiskStyle -> Brown, FordDiskThreshold -> 0,
  IncircleMode -> Off, IncircleStyle -> Blue, IncircleThreshold -> 0,
  LabelMode -> Off, LabelThreshold -> 2^-3, LabelStyle -> Black, Magnification -> Off,
  FordLabelMode -> Off, FordLabelThreshold -> 2^-3, FordLabelStyle -> Black 
};
(#::usage = ToString@# <> " is an option of ModularTiling. See usage of ModularTiling for more information.")& /@ DeleteCases[#[[1]]& /@ Options[ModularTiling], Magnification|LabelStyle];

ModularGroupList::usage = StringJoin[
  "ModularGroupList[p] ",
  "returns a list of ModularTransformations satisfying the predicate p. ",
  "Starting with the identity transformation, ",
  "a duplicate-free list of transformations is generated ",
  "by successively applying T and U from the right, ",
  "using a depth-first-search algorithm ",
  "which continues as long as p returns True. ",
  "\nThe options StartTransformation and MaxIterations are supported."
];
ModularGroupList::maxit =
  "Maximum number of iterations exceeded. Current setting: MaxIterations \[RightArrow] `1`.";

ModularGroupIterator::usage = StringJoin[
  "it = ModularGroupIterator[o] returns an Iterator for ModularTransformations ",
  "with ordering defined by the ordering predicate o.",
  "\nHasNext[it] returns True forever, as the ModularGroup has infinitely many elements.",
  "\nGetNext[it] returns the next ModularTransformation ",
  "determined by a priority-first-search algorithm, ",
  "which successively applies transformations T and U from the right ",
  "to already known transformations and uses the ordering predicate o."
];
StartTransformation::usage = StringJoin[
  "StartTransformation is an option ",
  "of ModularGroupList and ModularGroupIterator. ",
  "It defines the ModularTransformation which is used for starting the enumeration."
];

ModularSubgroupCosets::usage = StringJoin[
  "ModularSubgroupCosets[s, o] returns a list of coset representatives ",
  "of a subgroup of the modular group given by the membership predicate s. ",
  "The algorithm starts with the emtpy set ",
  "and successively adds applicable ModularTransformations ",
  "until a complete system of coset representatives is found. ",
  "The subgroup given by the membership predicate s ",
  "has to be of finite index within the modular group, ",
  "otherwise the algorithm will not terminate. ",
  "The order in which ModularTransformations are added to the result set ",
  "is given by the the ordering predicate o.\n",
  "The option StartTrasformation is supported."
];


Begin["`Private`"];


(* ---------------------------------------------- Basic PSL and PGL functions *)
PSL2CInv = Compile[{{m,_Complex,2}},
  {{m[[2,2]], -m[[1,2]]}, {-m[[2,1]], m[[1,1]]}},
  RuntimeAttributes->Listable
];

PSL2ZInv = Compile[{{m,_Integer,2}},
  {{m[[2,2]], -m[[1,2]]}, {-m[[2,1]], m[[1,1]]}},
  RuntimeAttributes->Listable
];

PSL2ZNormalForm = Compile[{{m,_Integer,2}}, 
  Module[{a,c},
    a = m[[1,1]]; c = m[[2,1]];
    If[a > 0 || (a == 0 && c > 0), m, -m]
  ], RuntimeAttributes->Listable
];

PSL2ZGrading = Compile[{{m,_Integer,2}},
  {1,1}.(m^2).{1,1},
  RuntimeAttributes -> Listable
];

RandomPSL2Z[n_Integer, N_Integer] := Module[{mats, l, firstRows, scndRows, gcds, coprime},
  mats = {};
  l = 0;
  While[l < n,
    firstRows = RandomInteger[{-N,N}, {n-l,2}];
    gcds = ExtendedGCD@@@firstRows;
    coprime = (#[[1]]==1)& /@ gcds;
    firstRows = Pick[firstRows, coprime];
    If[Length@firstRows > 0,
      gcds = Pick[gcds, coprime];
      scndRows = #[[2]]& /@ gcds;
      mats = mats ~Join~ Thread@{firstRows, scndRows.{{0,1},{-1,0}}};
      l = Length[mats];
    ];
  ];
  mats  
];



(* ---------------------------------------------- Class MoebiusTransformation *)

NewClass[MoebiusTransformation];

Inhom[{z1_,z2_}] := (
  If[TrueQ[z2 == 0], 
    ComplexInfinity, 
    z1 / z2
  ]
);

Init[MoebiusTransformation, obj_, mat_?MatrixQ] ^:= (
  Mat[obj] ^= mat;
  obj /: InstanceQ[ModularTransformation][obj] := (
  obj /: InstanceQ[ModularTransformation][obj] = 
    MatrixQ[mat, IntegerQ] && Det[mat] == 1
  );
  obj@t_?(InstanceQ[MoebiusTransformation]) := 
    New[MoebiusTransformation, mat.Mat[t]];
  obj@h_?VectorQ := mat.h;
  obj@z_ := (
    If[z === ComplexInfinity, 
      Inhom[mat.{1,0}], 
      Inhom[mat.{z, 1}]
    ]
  );
);

Inv[t_?(InstanceQ[MoebiusTransformation])] := Inv[t] ^= 
  Module[{inverse},
    inverse = If[TrueQ@InstanceQ[ModularTransformation][t],
       New[ModularTransformation, PSL2ZInv@Mat@t],
       New[MoebiusTransformation, PSL2CInv@Mat@t]
    ];
    Inv[inverse] ^= t;
    inverse
  ];

(* ------------------------------------------- Special MoebiusTransformations *)
mtModCayley = New[MoebiusTransformation,{{I,1},{1,I}}];



(* ---------------------------------------------- Class ModularTransformation *)
NewClass[ModularTransformation];

Init[ModularTransformation, obj_, mat_?(MatrixQ[#,IntegerQ]&)] ^:= (
  Assert[Det[mat] == 1];
  Super[MoebiusTransformation, obj, PSL2ZNormalForm@mat];
);

mtId = New[ModularTransformation, IdentityMatrix[2]];
Inv[mtId] ^= mtId; (* Identity is self-inverse *)

(* ------------------------------------------- Special ModularTransformations *)
mtU = New[ModularTransformation, {{1,1},{0,1}}];

mtT = New[ModularTransformation, {{0,-1},{1,0}}];
Inv[mtT] ^= mtT; (* T is self-inverse *)

mtR = New[ModularTransformation, Mat[mtT].Mat[mtU]];

(* ---------------------------------------------------- Group word algorithms *)

TUExponents[obj_, OptionsPattern[]] := 
  Module[{quotientFu, sgn, m, q},
    quotientFu = OptionValue[QuotientFunction];
    Reap[
      m = If[MatrixQ[obj], obj, Mat[obj]];
      sgn = 1;
      While[m[[2,1]] != 0,
        q = quotientFu[m[[1,1]], m[[2,1]]];
        m = {{0, 1}, {1, -q}}.m;
        Sow[sgn q];
        sgn = -sgn;
      ];
      Sow[m[[1,1]] m[[1,2]]];
    ][[2,1]]
  ];
Options[TUExponents] = {QuotientFunction->Quotient};
CentralQuotient[p_, q_] := Quotient[p, q, -q/2];
CQuotient[p_, q_] := If[p q > 0, Quotient[p, q], -Quotient[-p, q]];

TUEval[obj_, t_, u_, product_, power_, opts : OptionsPattern[]] := (
  product@@Riffle[power[u,#]&/@TUExponents[obj,opts],"T "]/."T "->t
);

TUWord[obj_, opts:OptionsPattern[]] := 
Module[{factors},
  factors = DeleteCases[
    TUEval[obj, "T", "U", List, Superscript, opts],
    Superscript["U",0]
  ];
  If[factors === {}, "1", Row@factors]
];

TRIndicateLeft = Compile[{{mat, _Integer, 2}},
  Module[{a,b,c,d, ac, bd},
    {{a,b},{c,d}} = mat;
    ac = a c; bd = b d;
    Which[
      ac >= 0 && bd >= 0, 0,
      a^2 + ac <= 0 && b^2 + bd <= 0, 1,
      True, -1
    ]
  ], RuntimeAttributes->Listable
];

TRIndicateRight = Compile[{{mat, _Integer, 2}},
  Module[{a,b,c,d, ab, cd},
    {{a,b},{c,d}} = mat;
    ab = a b; cd = c d;
    Which[
      ab <= 0 && cd <= 0, 0,
      a^2 - ab <= 0 && c^2 - cd <= 0, 1,
      True, -1
    ]
  ], RuntimeAttributes->Listable
];

TRIndicatorList = Compile[{{m, _Integer, 2}},
  Module[{r,mat,mT,mR,mRInv,e},
    r = Rest@{0}; (* Trick for telling the compilor that r is an integer tensor. *)
    mat = m;
    mT = {{0,-1},{1,0}};
    mR = {{0,-1},{1,1}};
    mRInv = {{1,1},{-1,0}};
    While[PSL2ZNormalForm@mat != {{1,0},{0,1}},
      e = TRIndicateLeft[mat];
      AppendTo[r, e];
      Which[
        e == 0, mat = mT.mat,
        e == 1, mat = mRInv.mat,
        True, mat = mR.mat
      ];
    ];
    r
  ], RuntimeAttributes->Listable, CompilationOptions -> {"InlineExternalDefinitions" -> True}
];

TRIndicatorReplacements = {0 -> mtT, 1 -> mtR, -1 -> Inv@mtR};

TRLeft[obj_] := Module[{mat},
  mat = Which[
    MatrixQ[obj], obj,
    ListQ[obj], Mat /@ obj,
    True, Mat@obj
  ];
  TRIndicateLeft[mat] /. TRIndicatorReplacements
];

TRRight[obj_] := Module[{mat},
  mat = Which[
    MatrixQ[obj], obj,
    ListQ[obj], Mat /@ obj,
    True, Mat@obj
  ];
  TRIndicateRight[mat] /. TRIndicatorReplacements
];

TRList[obj_] := Module[{mat},
  mat = Which[
    MatrixQ[obj], obj,
    ListQ[obj], Mat /@ obj,
    True, Mat@obj
  ];
  TRIndicatorList[mat] /. TRIndicatorReplacements
];

TRWord[obj_] := Module[{mat, list},
  mat = If[MatrixQ[obj], obj, Mat@obj];
  list = TRIndicatorList[mat];
  If[Length@list == 0,
    "1",
    Row@(list /. {
      -1 -> Superscript["R", 2],
      0 -> "T",
      1 -> Superscript["R", 1]
    })
  ]
];

InvAssociatedMap = Compile[{{zp, _Complex}},
  Module[{z, m, mT, n},
    z = zp;
    m = {{1,0},{0,1}};
    mT = {{0, -1}, {1, 0}};
    
    If[Abs[z] < 1, m = mT.m; z = If[z != 0.+0I, -1/z, 1.I]];

    While[Abs@Re@z > 1/2,
      n = Quotient[Re@z, 1, -1/2];
      m = {{1, -n}, {0, 1}}.m;
      z -= n;
      If[Abs[z] < 1, 
        m = mT.m; z = If[z != 0.+0I, -1/z, 1.I],
        Break[]
      ];
    ];
    m
  ], RuntimeAttributes -> Listable
];

AssociatedMap = Compile[{{z, _Complex}},
  PSL2ZInv@InvAssociatedMap@z,
  RuntimeAttributes -> Listable,
  CompilationOptions -> {"InlineExternalDefinitions" -> True}
];


(* --------------------------------------------------- Enumeration algorithms *)

Transition[ModularGroup] = Function[cur, 
Module[{steps, next},
  steps = NeighborSteps[cur];
  Table[
    next = cur@step;
    Parent[next] ^= cur;
    NeighborSteps[next] ^= If[step === mtT, Inv@#&/@Rest[steps], {mtT, step}];
    next, {step, steps}]
]];

ModularGroupList[criteria_, OptionsPattern[]] := Reap[
Module[{i, max, mtStart, it},
  i = 0;
  max = OptionValue[MaxIterations];
  mtStart = OptionValue[StartTransformation];
  NeighborSteps[mtStart] ^= {mtT, mtU, Inv@mtU};
  it = New[DFSIterator, mtStart, Transition[ModularGroup], criteria];
  While[i++ < max && HasNext@it,
    Sow@GetNext@it
  ];
  If[i >= max, Message[ModularGroupList::maxit, max]];
]][[2,1]];
Options[ModularGroupList] = {MaxIterations -> 2^12, StartTransformation->mtId};

ModularGroupIterator[ordering_, OptionsPattern[]] := 
Module[{mtStart},
  mtStart = OptionValue[StartTransformation];
  NeighborSteps[mtStart] ^= {mtT, mtU, Inv@mtU};
  New[PFSIterator, mtStart, Transition[ModularGroup], ordering]
];
Options[ModularGroupIterator] = {StartTransformation -> mtId};

ModularSubgroupCosets[subgroupMemberQ_, ordering_, OptionsPattern[]] := 
Module[{i, max, cosets, mtStart, Exclude, Neighbors, NotYetSeen, n, it},
  i = 0;
  max = OptionValue[MaxIterations];
  cosets = {};
 
  mtStart = OptionValue[StartTransformation];
  Exclude@mtStart = Null;
 
  NotYetSeen[m_] := !MemberQ[cosets, _?(subgroupMemberQ[#@Inv[m]]&)];
  Neighbors[m_] := (
    n = m@#;
    Exclude@n = Inv@#;
    n
  )& /@ DeleteCases[{mtT, mtU, Inv@mtU}, Exclude@m];

  it = New[PFSIterator, mtStart, Neighbors, ordering, NotYetSeen];
  While[i++ < max && HasNext[it],
    AppendTo[cosets, GetNext[it]];
  ];
  If[i >= max, Message[ModularGroupList::maxit, max]];
  cosets
];
Options[ModularSubgroupCosets] = {MaxIterations -> 2^10, StartTransformation -> mtId};


(* -------------------------------------------------- Class GeneralizedDisk *)
NewClass[GeneralizedDisk];
NewClass[NoncompactDisk];
NewClass[Halfplane];
NewClass[CompactDisk];

GDiskMatMap = Compile[{{m, _Complex, 2},{t, _Complex, 2}},
  Module[{tinv},
    tinv = {{t[[2,2]], -t[[1,2]]},{-t[[2,1]], t[[1,1]]}};
    ConjugateTranspose@tinv . m . tinv
  ],
  RuntimeAttributes -> {Listable}
];

Init[GeneralizedDisk, obj_, pmat_?MatrixQ] ^:= Module[{a, mat},
  mat=FullSimplify[pmat];
  (*Assert[HermitianMatrixQ@mat && Simplify[Det[mat] < 0]];*)
  Mat[obj] ^= mat;
  a = mat[[1,1]];
  obj /: InstanceQ[NoncompactDisk][obj] = (a < 0);
  obj /: InstanceQ[Halfplane][obj] = (a == 0);
  obj /: InstanceQ[CompactDisk][obj] = (a > 0); 
  
  t_?(InstanceQ[MoebiusTransformation])[obj] ^:=
    New[GeneralizedDisk, GDiskMatMap[mat, Mat@t]];
];

Init[NoncompactDisk, obj_, cocenter_, coradius_] ^:= Module[{mat},
  mat = {{-1, cocenter}, {Conjugate@cocenter, coradius^2 - cocenter*Conjugate@cocenter}};
  Super[GeneralizedDisk, obj, mat];
  GDiskCocenter[obj] ^= cocenter;
  GDiskCoradius[obj] ^= coradius;
];

Init[CompactDisk, obj_, center_, radius_] ^:= Module[{mat},
  mat = {{1, -center}, {-Conjugate@center, center*Conjugate@center - radius^2}};
  Super[GeneralizedDisk, obj, mat];
  GDiskCenter[obj] ^= center;
  GDiskRadius[obj] ^= radius;
];

Init[Halfplane, obj_, pt_, normal_] ^:= Module[{b, d, mat},
  b = -normal/2;
  d = Re[pt*Conjugate@normal];
  mat = {{0, b}, {Conjugate@b, d}};
  Super[GeneralizedDisk, obj, mat];
];

(* ----------------------------------------------- Special GeneralizedDisks *)

gdUnitDisk = New[CompactDisk, 0, 1];
gdUpperHalfplane = New[Halfplane, 0, I];
gdLowerHalfplane = New[Halfplane, 0, -I];
gdRightHalfplane = New[Halfplane, 0, 1];
gdLeftHalfplane = New[Halfplane, 0, -1];
gdUnitCodisk = New[NoncompactDisk, 0, 1];
gdFord0 = New[Halfplane, I, I];
gdIncircle0 = New[CompactDisk, 3 I / 2, 1 / 2];

(* ------------------------------------------- Methods for GeneralizedDisks *)

InteriorQ[disk_?(InstanceQ[GeneralizedDisk]), z_?VectorQ] := (
  Re[Conjugate[z].Mat[disk].z] <= 0
)

InteriorQ[disk_?(InstanceQ[GeneralizedDisk]), z_] := (
  If[TrueQ[z === ComplexInfinity], 
    !InstanceQ[CompactDisk][disk], 
    InteriorQ[disk,{z,1}]
  ]
);

GDiskMatRadius = Compile[{{m,_Complex,2}},
  Module[{a,b,d,aSqr},
    a = Re@m[[1,1]];
    b = m[[2,1]];
    d = Re@m[[2,2]];
    aSqr = a^2;   
    If[aSqr < Evaluate[2.^-64], 
      Evaluate[2.^64], 
      Sqrt[(Re[b]^2 + Im[b]^2 - a d) / aSqr]
    ]
  ],
  RuntimeAttributes -> {Listable}
];
GDiskMatCenter = Compile[{{m, _Complex, 2}},
  -m[[1,2]] / m[[1,1]],
  RuntimeAttributes -> {Listable}
];
GDiskMatClass = With[{maxRadiusSqr=N[2^30]},
  Compile[{{m, _Complex, 2}},
    Module[{a,b,d,aSqr},
      a = Re@m[[1,1]];
      b = m[[2,1]];
      d = Re@m[[2,2]];
      aSqr = a^2;
      If[aSqr == 0. || (Re[b]^2 + Im[b]^2 - a d) / aSqr > maxRadiusSqr,
        0,
        Sign@a
      ]
    ],
    RuntimeAttributes -> {Listable}
  ]
];

GDiskRadius[disk_?(InstanceQ[CompactDisk])] := 
GDiskRadius[disk] ^= (
  GDiskMatRadius[Mat[disk]]
);

GDiskCenter[disk_?(InstanceQ[CompactDisk])] :=
GDiskCenter[disk] ^= (
  GDiskMatCenter[Mat[disk]]
);

GDiskCoradius[disk_?(InstanceQ[NoncompactDisk])] :=
GDiskCoradius[disk] ^= (
  GDiskMatRadius[Mat[disk]]
);

GDiskCocenter[disk_?(InstanceQ[NoncompactDisk])] :=
GDiskCocenter[disk] ^= (
  GDiskMatCenter[Mat[disk]]
);

(* ----------------------------------------------------- Drawing algorithms *)
Options[GDisk] ^= {
  GDiskNPoints->64
};

GDisk[disk_, opts:OptionsPattern[]] := Module[{m},
  m = If[MatrixQ[disk], disk, Mat@disk];
  Switch[GDiskMatClass[m],
    1, (* CompactDisk *)
    Module[{c = GDiskMatCenter[m]},
      Disk[{Re[c],Im[c]}, GDiskMatRadius[m]]
    ],
    -1, (* NoncompactDisk *)
    Module[{points, c, r, n},
      n = OptionValue[GDiskNPoints];
      c = GDiskMatCenter[m];
      r = GDiskMatRadius[m];
      points = Table[c+r Exp[2 Pi I t], {t, 1/2, -1/2, -1/n}];
      Polygon[Join[{Re@#, Im@#}& /@ points, Scaled /@ {{-1,0.5},{-1,-1},{2,-1},{2,2},{-1,2},{-1,0.5}}]]
    ],
    _, (* Halfplane *) 
    Module[{absb, b0, rot},
      absb = Abs[m[[1,2]]];
      b0 = m[[1,2]] / absb;
      rot = {{Re@b0, -Im@b0}, {Im@b0, Re@b0}};
      GeometricTransformation[
        Rectangle[Scaled@{-1024, -1024}, Scaled[{0, 1024}, {-m[[2,2]]/(2 absb), 0}]],
        rot
      ]
    ]
  ]
];

udTransforms[mlist_] := Module[{c,r},
  Table[
    c = GDiskMatCenter[m];
    r = GDiskMatRadius[m];
    {{{r,0},{0,r}}, {Re@c, Im@c}},
  {m, mlist}]
]

GDisk[disk_, tlist_List, opts:OptionsPattern[]] :=
Module[{m, ts, mlists},
  If[Length@tlist > 0, (
    m = If[MatrixQ@disk, disk, Mat@disk];
    ts = If[MatrixQ[tlist[[1]]], tlist, Mat /@ tlist];
    mlists = SplitBy[GDiskMatMap[m, ts], GDiskMatClass];
    Table[
      If[GDiskMatClass[mlist[[1]]] == 1,
        GeometricTransformation[Disk[], udTransforms[mlist]],
        GDisk[#, opts]& /@ mlist
      ], {mlist, mlists}
    ]
  ), (* else: tlist is empty *) (
    {} 
  )]
];

GCircle[disk_] := Module[{m},
  m = If[MatrixQ@disk, disk, Mat@disk];
  If[GDiskMatClass[m] == 0,
    (* Halfplane *) 
    Module[{absb, b0, rot, x},
      absb = Abs[m[[1,2]]];
      b0 = m[[1,2]] / absb;
      rot = {{Re@b0, -Im@b0}, {Im@b0, Re@b0}};
      x = -m[[2,2]]/(2 absb);
      GeometricTransformation[
        Line[Scaled[#, {x, 0}]& /@ {{0, -1}, {0, 2}}],
        rot
      ]
    ],
    (* CompactDisk or NoncompactDisk *)
    Module[{c = GDiskMatCenter[m]},
      Circle[{Re[c],Im[c]}, GDiskMatRadius[m]]
    ] 
  ]
];

GCircle[disk_, tlist_List] :=
Module[{m, ts, mlists},
  If[Length@tlist > 0,
    m = If[MatrixQ@disk, disk, Mat@disk];
    ts = If[MatrixQ[tlist[[1]]], tlist, Mat /@ tlist];
    mlists = SplitBy[GDiskMatMap[m, ts], GDiskMatClass];
    Table[
      If[GDiskMatClass[mlist[[1]]] == 0,
        GCircle /@ mlist,      
        GeometricTransformation[Circle[], udTransforms[mlist]]
      ], {mlist, mlists}
    ],
    (* else: tlist empty *)
    {}
  ]
];

Options[GDiskLabel] = {
  Magnification -> Off
};
GDiskLabel[disk_, tlist_List, labels_List, opts:OptionsPattern[]] :=
Module[{m, ts, disks, magFactor, magLabels},
  Which[
    Length@tlist != Length@labels, (
      Message[GDiskLabel::listlength]
      $Failed
    ), 
    Length@tlist > 0, (
      m = If[MatrixQ@disk, disk, Mat@disk];
      ts = If[MatrixQ[tlist[[1]]], tlist, Mat /@ tlist];
      disks = GDiskMatMap[m, ts];
      magFactor = OptionValue[Magnification];
      magLabels = If[magFactor === Off, labels, 
        Thread@Magnify[labels, magFactor GDiskMatRadius[disks]]
      ];
      Thread@Text[magLabels, {Re@#, Im@#}& /@ GDiskMatCenter[disks]]
    ), 
    _, {}
  ]
];

fordCriteria = Compile[{{m,_Integer,2}},
  Module[{a,b,c,d, ab, cd},
    {{a,b},{c,d}} = m;
    ab = a b; cd = c d;
    ab <= 0 && cd <= 0 && (Abs@a > Abs@b || Abs@c > Abs@d)
  ], RuntimeAttributes -> Listable
];

ModularTiling[ptlist_List, pphi_:mtId, opts:OptionsPattern[]] :=
If[Length[ptlist] > 0,
  Module[{tlist, phi, output = {}, tTiling, tFord, tIncircle, tLabel, f, min, ds, sel},
    tlist = ptlist; (*If[MatrixQ[ptlist[[1]]], ptlist, Mat/@ptlist];*)
    phi = If[MatrixQ[pphi], pphi, Mat@pphi];

    tTiling := tTiling = Rest@Pick[tlist, TRIndicateRight[Mat/@tlist], 0];

    (* Draw upper half-plane *)
    f = OptionValue[InteriorMode]; 
    If[!(f === Off),
      AppendTo[output, {OptionValue[InteriorStyle], f[gdUpperHalfplane, {phi}]}];
    ];

    (* Draw ford disks *)
    f = OptionValue[FordDiskMode];
    If[!(f === Off),
      tFord = Pick[tlist, fordCriteria[Mat/@tlist]];
      min = OptionValue[FordDiskThreshold];
      If[TrueQ[min > 0], 
        tFord = Pick[
          tFord, 
          Thread[GDiskMatRadius[GDiskMatMap[Mat@gdFord0, phi.Mat@#& /@ tFord]] >= min]
        ]
      ];
      AppendTo[output, {OptionValue[FordDiskStyle], f[gdFord0, phi.Mat@#& /@ tFord]}];
    ];
  
    (* Draw incircles *)
    f = OptionValue[IncircleMode];
    If[!(f === Off),
      min = OptionValue[IncircleThreshold];
      tIncircle = If[TrueQ[min > 0],
        Pick[
          tlist, 
          Thread[GDiskMatRadius[GDiskMatMap[Mat@gdIncircle0, phi.Mat@#& /@ tlist]] >= min]
        ],
        tlist
      ];
      AppendTo[output, {OptionValue[IncircleStyle], f[gdIncircle0, phi.Mat@#& /@ tIncircle]}];
    ];

    (* Draw tiling *)
    f = OptionValue[TilingMode];
    If[!(f === Off),
      min = OptionValue[TilingThreshold];
      If[TrueQ[min > 0],
        tTiling = Pick[
          tTiling, 
          Thread[GDiskMatRadius[GDiskMatMap[Mat@gdUnitDisk, phi.Mat@#& /@ tTiling]] >= min]
        ];
      ];
      AppendTo[output, {OptionValue[TilingStyle], f[gdUnitDisk, phi.Mat@#& /@ tTiling]}];
    ];

    (* Draw Ford disk labels *)
    f = OptionValue[FordLabelMode];
    If[!(f === Off),
      min = OptionValue[FordLabelThreshold];
      tFord = Pick[tlist, fordCriteria[Mat/@tlist]];
      ds = GDiskMatMap[Mat@gdFord0, phi.Mat@#& /@ tFord];
      sel = Re[#[[1,1]]] > 0& /@ ds;
      tFord = Pick[tFord, sel];
      ds = Pick[ds, sel];
      tLabel = If[TrueQ[min > 0],
        Pick[
          tFord, 
          Thread[GDiskMatRadius[ds] >= min]
        ],
        tFord
      ];
      AppendTo[output, {
        OptionValue[LabelStyle], 
        GDiskLabel[
          gdFord0, phi.Mat@#& /@ tLabel, f /@ tLabel, 
          FilterRules[{opts}, Options[GDiskLabel]]
        ]
      }];
    ];

    (* Draw labels *)
    f = OptionValue[LabelMode];
    If[!(f === Off),
      min = OptionValue[LabelThreshold];
      tLabel = If[TrueQ[min > 0],
        Pick[
          tlist, 
          Thread[GDiskMatRadius[GDiskMatMap[Mat@gdIncircle0, phi.Mat@#& /@ tlist]] >= min]
        ],
        tlist
      ];
      AppendTo[output, {
        OptionValue[LabelStyle], 
        GDiskLabel[
          gdIncircle0, phi.Mat@#& /@ tLabel, f /@ tLabel, 
          FilterRules[{opts}, Options[GDiskLabel]]
        ]
      }];
    ];

    (* Draw lower half-plane *)
    f = OptionValue[ExteriorMode]; 
    If[!(f === Off),
      AppendTo[output, {OptionValue[ExteriorStyle], f[gdLowerHalfplane,{phi}]}];
    ];

    (* Draw real axis *)
    f = OptionValue[BorderMode]; 
    If[!(f === Off),
      AppendTo[output, {OptionValue[BorderStyle], f[gdLowerHalfplane,{phi}]}];
    ];

    output
  ], {} (* mtList is empty *)
];


End[];

(*Protect[MoebiusTransformation, Mat, Inv];
Protect[ModularTransformation, QuotientFunction];
Protect[TUExponents, TUEval, TUWord];*)

EndPackage[];
