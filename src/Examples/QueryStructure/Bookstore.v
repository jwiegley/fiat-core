Require Import Fiat.QueryStructure.Automation.MasterPlan.

(* Our bookstore has two relations (tables):
   - The [Books] relation contains the books in the
     inventory, represented as a tuple with
     [Author], [Title], and [ISBN] attributes.
     The [ISBN] attribute is a key for the relation,
     specified by the [where attributes .. depend on ..]
     constraint.
   - The [Orders] relation contains the orders that
     have been placed, represented as a tuple with the
     [ISBN] and [Date] attributes.

   The schema for the entire query structure specifies that
   the [ISBN] attribute of [Orders] is a foreign key into
   [Books], specified by the [attribute .. of .. references ..]
   constraint.
 *)

(* Let's define some synonyms for strings we'll need,
 * to save on type-checking time. *)
Definition sBOOKS := "Books".
Definition sAUTHOR := "Authors".
Definition sTITLE := "Title".
Definition sISBN := "ISBN".
Definition sORDERS := "Orders".
Definition sDATE := "Date".

(* Now here's the actual schema, in the usual sense. *)
Definition BookStoreSchema :=
  Query Structure Schema
    [ relation sBOOKS has
              schema <sAUTHOR :: string,
                      sTITLE :: string,
                      sISBN :: nat>
                      where attributes [sTITLE; sAUTHOR] depend on [sISBN];
      relation sORDERS has
              schema <sISBN :: nat,
                      sDATE :: nat> ]
    enforcing [attribute sISBN for sORDERS references sBOOKS].

(* Aliases for the tuples contained in Books and Orders, respectively. *)
Definition Book := TupleDef BookStoreSchema sBOOKS.
Definition Order := TupleDef BookStoreSchema sORDERS.

(* Our bookstore has two mutators:
   - [PlaceOrder] : Place an order into the 'Orders' table
   - [AddBook] : Add a book to the inventory

   Our bookstore has two observers:
   - [GetTitles] : The titles of books written by a given author
   - [NumOrders] : The number of orders for a given author
 *)

(* So, first let's give the type signatures of the methods. *)
Definition BookStoreSig : ADTSig :=
  ADTsignature {
      Constructor "Init" : rep,
      Method "PlaceOrder" : rep * Order -> rep * bool,
      Method "DeleteOrder" : rep * nat -> rep * (list Order),
      Method "AddBook" : rep * Book -> rep * bool,
      Method "DeleteBook" : rep * nat -> rep * (list Book),
      Method "GetTitles" : rep * string -> rep * (list string),
      Method "NumOrders" : rep * string -> rep * nat
    }.

(* Now we write what the methods should actually do. *)

Definition BookStoreSpec : ADT BookStoreSig :=
  Eval simpl in
    QueryADTRep BookStoreSchema {
    Def Constructor0 "Init" : rep := empty,

    Def Method1 "PlaceOrder" ( r : rep) (o : Order ) : rep * bool :=
        Insert o into r!sORDERS,

    Def Method1 "DeleteOrder" (r : rep) (oid : nat) : rep * list Order :=
       Delete o from r!sORDERS where o!sISBN = oid,

    Def Method1 "AddBook" (r : rep) (b : Book ) : rep * bool :=
        Insert b into r!sBOOKS ,

    Def Method1 "DeleteBook" ( r : rep) (id : nat ) : rep * list Book :=
        Delete book from r!sBOOKS where book!sISBN = id,

    Def Method1 "GetTitles" (r : rep) (author : string) : rep * list string :=
        titles <- For (b in r ! sBOOKS)
               Where (author = b!sAUTHOR)
               Return (b!sTITLE);
    ret (r, titles),

    Def Method1 "NumOrders" (r : rep) (author : string ) : rep * nat :=
      count <- Count (For (o in r!sORDERS) (b in r!sBOOKS)
                              Where (author = b!sAUTHOR)
                              Where (o!sISBN = b!sISBN)
                              Return ());
      ret (r, count)
}%methDefParsing.

Theorem SharpenedBookStore :
  FullySharpened BookStoreSpec.
Proof.

  start sharpening ADT.
  pose_string_hyps.
  eapply SharpenStep;
  [ match goal with
        |- context [@BuildADT (QueryStructure ?Rep) _ _ _ _ _ _] =>
        eapply refineADT_BuildADT_Rep_refine_All with (AbsR := @DropQSConstraints_AbsR Rep);
          [ repeat (first [eapply refine_Constructors_nil
                          | eapply refine_Constructors_cons;
                            [ simpl; intros;
                              match goal with
                              | |- refine _ (?E _ _ _ _) => let H := fresh in set (H := E)
                              | |- refine _ (?E _ _ _) => let H := fresh in set (H := E)
                              | |- refine _ (?E _ _) => let H := fresh in set (H := E)
                              | |- refine _ (?E _) => let H := fresh in set (H := E)
                              | |- refine _ (?E) => let H := fresh in set (H := E)
                              | _ => idtac
                              end;
                              (* Drop constraints from empty *)
                              try apply Constructor_DropQSConstraints;
                              cbv delta [GetAttribute] beta; simpl
                            | ] ])
          | repeat (first [eapply refine_Methods_nil
                          | eapply refine_Methods_cons;
                            [ simpl; intros;
                              match goal with
                              | |- refine _ (?E _ _ _ _) => let H := fresh in set (H := E)
                              | |- refine _ (?E _ _ _) => let H := fresh in set (H := E)
                              | |- refine _ (?E _ _) => let H := fresh in set (H := E)
                              | |- refine _ (?E _) => let H := fresh in set (H := E)
                              | |- refine _ (?E) => let H := fresh in set (H := E)
                              | _ => idtac
                              end;
                              cbv delta [GetAttribute] beta; simpl | ]
                          ])]
    end | ].
  - doAny drop_constraints
           master_rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
  - doAny drop_constraints
           master_rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
  - doAny drop_constraints
           master_rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
  - doAny drop_constraints
           master_rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
  - doAny drop_constraints
           master_rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
  - doAny drop_constraints
           master_rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
  - hone representation using (@FiniteTables_AbsR BookStoreSchema).
    + simplify with monad laws.
      refine pick val _; simpl; intuition.
      eauto using FiniteTables_AbsR_QSEmptySpec.
    + doAny simplify_queries
            Finite_AbsR_rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
    + doAny simplify_queries
            Finite_AbsR_rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
    + doAny simplify_queries
            Finite_AbsR_rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
    + doAny simplify_queries
            Finite_AbsR_rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
    + doAny simplify_queries
            Finite_AbsR_rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
    + doAny simplify_queries
            Finite_AbsR_rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
    + simpl.

      (* Delegate_AbsR is a super-generic abstraction relation for any *)
      (* representation parameterized over some abstract models of state. *)
      Definition Delegate_AbsR
                 (* The fixed set of 'abstract' types in the ADT's *)
                 (* representation. *)
                 (DelegateIDs : nat)
                 (AbstractReps : Fin.t DelegateIDs -> Type)

                 (* The parameterized representation type. Intuitively, *)
                 (* this relation swaps in 'concrete' types for the *)
                 (* abstract ones, i.e. lists for sets. The type's *)
                 (* parametricity is witnessed by FunctorRepT. *)
                 (RepT : (Fin.t DelegateIDs -> Type) -> Type)
                 (FunctorRepT : forall RepsT RepsT',
                     (forall idx, RepsT idx -> RepsT' idx)
                     -> RepT RepsT -> RepT RepsT')

                 (* The signatures of each delegate's constructors *)
                 (* and methods in terms of the abstract representation *)
                 (* types. *)
                 (numDelegateConstructors : Fin.t DelegateIDs -> nat)
                 (DelegateConstructorSigs
                  : forall (idx : Fin.t DelegateIDs),
                     Vector.t consSig (numDelegateConstructors idx))
                 (numDelegateMethods : Fin.t DelegateIDs -> nat)
                 (DelegateMethodSigs
                  : forall (idx : Fin.t DelegateIDs),
                     Vector.t methSig (numDelegateMethods idx))
                 (DelegateSigs := fun idx =>
                                    BuildADTSig
                                      (DelegateConstructorSigs idx)
                                      (DelegateMethodSigs idx))

                 (* The specifications of each delegate's constructors *)
                 (* and methods in terms of the abstract representation *)
                 (* types. *)
                 (DelegateConstructorSpecs
                  : forall (idx : Fin.t DelegateIDs),
                     ilist (B := consDef (Rep := AbstractReps idx))
                           (DelegateConstructorSigs idx))
                 (DelegateMethodSpecs
                  : forall (idx : Fin.t DelegateIDs),
                     ilist (B := methDef (Rep := AbstractReps idx))
                           (DelegateMethodSigs idx))
                 (DelegateSpecs := fun idx =>
                                     BuildADT
                                       (DelegateConstructorSpecs idx)
                                       (DelegateMethodSpecs idx))

                 (* The concrete implementations of each delegate. *)
                 (ConcreteReps : Fin.t DelegateIDs -> Type)
                 (DelegateImpls : forall idx,
                     ComputationalADT.pcADT (DelegateSigs idx)
                                            (ConcreteReps idx))
                 (ValidImpls
                  : forall idx : Fin.t DelegateIDs,
                     refineADT (DelegateSpecs idx)
                               (ComputationalADT.LiftcADT (existT _ _ (DelegateImpls idx))))

                 (r_o : RepT AbstractReps)
                 (r_n : RepT ConcreteReps)
        : Prop :=
        exists r_o_n : RepT (fun idx => sigT (fun ac =>
                                                AbsR (ValidImpls idx) (fst ac) (snd ac))),
          r_o = FunctorRepT _ _ (fun idx ac => fst (projT1 ac)) r_o_n
          /\ r_n = FunctorRepT _ _ (fun idx ac => snd (projT1 ac)) r_o_n.

      (* SharpenFully_w_Delegates constructs a FullySharpened ADT *)
      (* for an ADT whose representation is parameterized over some *)
      (* abstract models of state. *)
      Definition
        SharpenFully_w_Delegates
        (* The fixed set of 'abstract' types in the ADT's *)
        (* representation. *)
        (DelegateIDs : nat)
        (AbstractReps : Fin.t DelegateIDs -> Type)

        (* The parameterized representation type. Intuitively, *)
        (* this relation swaps in 'concrete' types for the *)
        (* abstract ones, i.e. lists for sets. The type's *)
        (* parametricity is witnessed by FunctorRepT. *)
        (pRepT : (Fin.t DelegateIDs -> Type) -> Type)
        
        (* The initial representation type. *)
        (RepT := pRepT AbstractReps)

        (* The constructors and methods of the ADT being *)
        (* sharpened. *)
        {n n'}
        (consSigs : Vector.t consSig n)
        (methSigs : Vector.t methSig n')
        (consDefs : ilist (B := consDef (Rep := RepT)) consSigs)
        (methDefs : ilist (B := methDef (Rep := RepT)) methSigs)


        (* The signatures of each delegate's constructors *)
        (* and methods in terms of the abstract representation *)
        (* types. *)
        (numDelegateConstructors : Fin.t DelegateIDs -> nat)
        (DelegateConstructorSigs
         : forall (idx : Fin.t DelegateIDs),
            Vector.t consSig (numDelegateConstructors idx))
        (numDelegateMethods : Fin.t DelegateIDs -> nat)
        (DelegateMethodSigs
         : forall (idx : Fin.t DelegateIDs),
            Vector.t methSig (numDelegateMethods idx))
        (DelegateSigs := fun idx =>
                           BuildADTSig
                             (DelegateConstructorSigs idx)
                             (DelegateMethodSigs idx))

        (* The specifications of each delegate's constructors *)
        (* and methods in terms of the abstract representation *)
        (* types. *)
        (DelegateConstructorSpecs
         : forall (idx : Fin.t DelegateIDs),
            ilist (B := consDef (Rep := AbstractReps idx))
                  (DelegateConstructorSigs idx))
        (DelegateMethodSpecs
         : forall (idx : Fin.t DelegateIDs),
            ilist (B := methDef (Rep := AbstractReps idx))
                  (DelegateMethodSigs idx))
        (DelegateSpecs := fun idx =>
                            BuildADT
                              (DelegateConstructorSpecs idx)
                              (DelegateMethodSpecs idx))

        (* An abstraction relation between the original representation *)
        (* and the abstract representation (generally equality). This is *)
        (* generically lifted to a relation between the original *)
        (* representation and the concrete representation. *)
        (pAbsR : forall (A B : Fin.t DelegateIDs -> Type),
                     (forall idx, A idx -> B idx -> Prop)
                     -> pRepT A -> pRepT B -> Prop)
        (cAbsR :=
           fun ConcreteReps' DelegateImpls'
               (ValidImpls'
                : forall idx : Fin.t DelegateIDs,
                   refineADT (DelegateSpecs idx)
                             (ComputationalADT.LiftcADT (existT _ _ (DelegateImpls' idx))))
               r_o r_n =>
             pAbsR _ _ (fun idx => AbsR (ValidImpls' idx)) r_o r_n)

        cConstructors
        cMethods
        cConstructorsRefinesSpec
        cMethodsRefinesSpec

        (* The concrete implementations of each delegate. *)
        (ConcreteReps : Fin.t DelegateIDs -> Type)
        (DelegateImpls : forall idx,
            ComputationalADT.pcADT (DelegateSigs idx)
                                   (ConcreteReps idx))
        (ValidImpls
         : forall idx : Fin.t DelegateIDs,
            refineADT (DelegateSpecs idx)
                      (ComputationalADT.LiftcADT (existT _ _ (DelegateImpls idx))))

        := Notation_Friendly_SharpenFully'
             consSigs methSigs consDefs methDefs
             DelegateSigs pRepT
             cConstructors
             cMethods
             DelegateSpecs cAbsR
             cConstructorsRefinesSpec
             cMethodsRefinesSpec.

      Fixpoint Iterate_Dep_Type_AbsR {n}
               (A B : Fin.t n -> Type)
               (AB_AbsR : forall idx, A idx -> B idx -> Prop)
               (a : Iterate_Dep_Type_BoundedIndex A)
               (b : Iterate_Dep_Type_BoundedIndex B)
        : Prop :=
        match n as n' return
              forall (A B : Fin.t n' -> Type)
                     (AB_AbsR : forall idx, A idx -> B idx -> Prop),
                Iterate_Dep_Type_BoundedIndex A
                -> Iterate_Dep_Type_BoundedIndex B
                -> Prop with
        | S n' => fun A B AB_AbsR a b =>
                    AB_AbsR _ (prim_fst a) (prim_fst b)
                    /\ Iterate_Dep_Type_AbsR (fun n' => A (Fin.FS n'))
                                             (fun n' => B (Fin.FS n'))
                                             (fun n' => AB_AbsR (Fin.FS n'))
                                             (prim_snd a)
                                             (prim_snd b)
        | _ => fun _ _ _ _ _ => True
        end A B AB_AbsR a b.

      Fixpoint UnConstryQueryStructure_Abstract_AbsR'
               {n}
               {qsSchema}
               (r_o : ilist2 (B := (fun ns : RawSchema => RawUnConstrRelation (rawSchemaHeading ns))) qsSchema)
               (r_n : Iterate_Dep_Type_BoundedIndex
                          (fun idx : Fin.t n=>
                             @IndexedEnsemble
                               (@RawTuple
                                  (rawSchemaHeading (Vector.nth qsSchema idx)))))
        : Prop :=
        match qsSchema as qsSchema return
              forall
                (r_o : ilist2 (B := (fun ns : RawSchema => RawUnConstrRelation (rawSchemaHeading ns))) qsSchema)
                (r_n : Iterate_Dep_Type_BoundedIndex
                          (fun idx : Fin.t _ =>
                             @IndexedEnsemble
                               (@RawTuple
                                  (rawSchemaHeading (Vector.nth qsSchema idx))))), Prop with
        | Vector.cons sch _ qsSchema' =>
          fun r_o r_n =>
            ilist2_hd r_o = prim_fst r_n
            /\ UnConstryQueryStructure_Abstract_AbsR'
                 (prim_snd r_o)
                 (prim_snd r_n)
        | Vector.nil  => fun _ _ => True
        end r_o r_n.

      Definition UnConstryQueryStructure_Abstract_AbsR
                 {qsSchema}
                 (r_o : UnConstrQueryStructure qsSchema)
                 (r_n : Iterate_Dep_Type_BoundedIndex _)
        := UnConstryQueryStructure_Abstract_AbsR' r_o r_n.

      hone representation using (@UnConstryQueryStructure_Abstract_AbsR BookStoreSchema).
      simplify with monad laws.
      refine pick val (imap2 rawRel (Build_EmptyRelations (qschemaSchemas BookStoreSchema))).
      finish honing.
      unfold UnConstryQueryStructure_Abstract_AbsR; simpl; intuition.
      Lemma UpdateUnConstrRelation_Abstract_AbsR {qsSchema}
        : forall (r_o : UnConstrQueryStructure qsSchema)
                 (r_n : Iterate_Dep_Type_BoundedIndex _),
          UnConstryQueryStructure_Abstract_AbsR r_o r_n
          -> forall idx R,
            UnConstryQueryStructure_Abstract_AbsR
              (UpdateUnConstrRelation r_o idx R)
              (Update_Iterate_Dep_Type idx _ r_n R).
       Admitted.
       Ltac UpdateUnConstrRelation_Abstract :=
       match goal with
         H : UnConstryQueryStructure_Abstract_AbsR ?r_o ?r_n
         |- context [{ r_n | UnConstryQueryStructure_Abstract_AbsR
                               (UpdateUnConstrRelation ?r_o ?idx ?R) r_n }] =>
         refine pick val _;
           [ | apply (UpdateUnConstrRelation_Abstract_AbsR r_o r_n H idx R); eauto]
        end.
       Ltac PickUnchangedRep :=
         match goal with
           |- context [Pick (fun r_n => @?R r_n)] =>
           match goal with
             H : ?R' ?r_n |- _ => unify R R'; refine pick val r_n; [ | apply H]
           end
         end.
       Lemma GetUnConstrRelation_Abstract_AbsR {qsSchema}
        : forall (r_o : UnConstrQueryStructure qsSchema)
                 (r_n : Iterate_Dep_Type_BoundedIndex _),
          UnConstryQueryStructure_Abstract_AbsR r_o r_n
          -> forall idx,
            GetUnConstrRelation r_o idx = Lookup_Iterate_Dep_Type _ r_n idx.
      Proof.
      Admitted.
      Ltac GetUnConstrRelation_Abstract :=
        match goal with
          H : UnConstryQueryStructure_Abstract_AbsR ?r_o ?r_n
          |- context [GetUnConstrRelation ?r_o ?idx] =>
          rewrite (GetUnConstrRelation_Abstract_AbsR r_o r_n H idx)
        end.
      Transparent UpdateUnConstrRelationInsertC.
      Transparent UpdateUnConstrRelationDeleteC.

      Ltac parameterize_query_structure :=
        repeat first
               [ simplify with monad laws; cbv beta; simpl
               | rewrite refine_If_Then_Else_Bind
               | GetUnConstrRelation_Abstract
               | UpdateUnConstrRelation_Abstract
               | progress unfold QSDeletedTuples
               | PickUnchangedRep].
      doAny parameterize_query_structure
            rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
      doAny parameterize_query_structure
            rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
      doAny parameterize_query_structure
            rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
      doAny parameterize_query_structure
            rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
      doAny parameterize_query_structure
            rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
      doAny parameterize_query_structure
            rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
      eapply FullySharpened_Finish.
      Locate Ltac makeEvar.
      Print BuildADT.

      Ltac makeEvar T k :=
  let x := fresh in evar (x : T); let y := eval unfold x in x in clear x; k y.

      Ltac ilist_of_evar_dep' n C D B As k :=
  match n with
  | 0 => k (fun (c : C) (d : D c) => @inil _ (B c))
  | S ?n' =>
    makeEvar (forall (c : C) (d : D c), B c (Vector.hd As))
             ltac:(fun b =>
                           ilist_of_evar_dep' n'
                                             C D B (Vector.tl As)
                                             ltac:(fun Bs' => k (fun (c : C) (d : D c) => icons (a := Vector.hd As) (b c d) (Bs' c d))))
  end.
      
Ltac FullySharpenEachMethod_w_Delegates
     DelegateIDs
     AbstractReps
     dRepT
     dAbsR :=
  match goal with
    |- FullySharpenedUnderDelegates (@BuildADT ?Rep ?n ?n' ?consSigs ?methSigs ?consDefs ?methDefs) _ =>
    (* We build a bunch of evars in order to decompose the goal *)
    (* into a single subgoal for each constructor. *)
    makeEvar (Fin.t DelegateIDs -> nat)
      ltac:(fun numDelegateConstructors => 
    makeEvar (Fin.t DelegateIDs -> nat)
      ltac:(fun numDelegateMethods =>
    makeEvar (Iterate_Dep_Type_BoundedIndex
                (fun (idx : Fin.t DelegateIDs)=> 
                   Vector.t consSig (numDelegateConstructors idx)))
      ltac:(fun DelegateConstructorSigs' => 
    makeEvar (Iterate_Dep_Type_BoundedIndex
                (fun (idx : Fin.t DelegateIDs)=> 
                   Vector.t methSig (numDelegateMethods idx)))
      ltac:(fun DelegateMethodSigs' =>
        let DelegateConstructorSigs :=
            constr:(Lookup_Iterate_Dep_Type _ DelegateConstructorSigs') in
        let DelegateMethodSigs :=
            constr:(Lookup_Iterate_Dep_Type _ DelegateMethodSigs') in
        let DelegateSigs :=
            constr:(fun idx =>
                      BuildADTSig (DelegateConstructorSigs idx) (DelegateMethodSigs idx)) in
    makeEvar (Iterate_Dep_Type_BoundedIndex
                          (fun (idx : Fin.t DelegateIDs) => 
                             ilist (B := consDef (Rep := AbstractReps idx))
                                   (DelegateConstructorSigs idx)))
      ltac:(fun DelegateConstructorSpecs' => 
    makeEvar (Iterate_Dep_Type_BoundedIndex
                (fun (idx : Fin.t DelegateIDs) =>
                  ilist (B := methDef (Rep := AbstractReps idx))
                        (DelegateMethodSigs idx)))
      ltac:(fun DelegateMethodSpecs' => 
        let DelegateConstructorSpecs :=
            constr:(Lookup_Iterate_Dep_Type _ DelegateConstructorSpecs') in
        let DelegateMethodSpecs :=
            constr:(Lookup_Iterate_Dep_Type _ DelegateMethodSpecs') in
        let DelegateSpecs :=
            constr:(fun idx =>
                      BuildADT (DelegateConstructorSpecs idx) (DelegateMethodSpecs idx)) in 
      ilist_of_evar_dep' n
        (Fin.t DelegateIDs -> Type)
        (fun D =>
           forall idx,
             ComputationalADT.pcADT (DelegateSigs idx) (D idx))
        (fun D Sig => ComputationalADT.cConstructorType (dRepT D) (consDom Sig))
        consSigs
        ltac:(fun cCons =>
                ilist_of_evar_dep' n'
                                  (Fin.t DelegateIDs -> Type)
                                  (fun D =>
                                     forall idx,
                                       ComputationalADT.pcADT
                             ((fun idx0 : Fin.t DelegateIDs =>
                               DecADTSig
                                 ((fun idx1 : Fin.t DelegateIDs =>
                                   BuildADTSig (DelegateConstructorSigs idx1)
                                     (DelegateMethodSigs idx1)) idx0)) idx)
 (D idx))
        (fun D Sig => ComputationalADT.cMethodType (dRepT D) (methDom Sig) (methCod Sig))
        methSigs
        ltac:(fun cMeths =>
                eapply (@SharpenFully_w_Delegates
                          DelegateIDs AbstractReps dRepT n n'
                          consSigs methSigs
                          consDefs methDefs
                          numDelegateConstructors
                          DelegateConstructorSigs
                          numDelegateMethods
                          DelegateMethodSigs
                          DelegateConstructorSpecs
                          DelegateMethodSpecs
                          dAbsR cCons cMeths)))))))))
    end; try (simpl; repeat split; intros; subst).
FullySharpenEachMethod_w_Delegates
  2
  (fun idx : Fin.t (numRawQSschemaSchemas BookStoreSchema) =>
     @IndexedEnsemble (@RawTuple (rawSchemaHeading (Vector.nth (qschemaSchemas BookStoreSchema) idx))))
  (@Iterate_Dep_Type_BoundedIndex 2)
  (@Iterate_Dep_Type_AbsR 2).
Focus 2.
simplify with monad laws; simpl.

Ltac identify_Abstract_Rep_Use r_o AbstractReps k :=
  first [unify r_o (AbstractReps Fin.F1);
          match type of AbstractReps with
          | Fin.t ?n -> _ => k (@Fin.F1 (n - 1))
          end
        | identify_Abstract_Rep_Use r_o (fun n => AbstractReps (Fin.FS n))
                                    ltac:(fun n => k (Fin.FS n))].
Unset Ltac Debug.
etransitivity.

rewrite_drill.
Ltac find_Abstract_Rep AbstractReps k :=
  match goal with
    |- context [?r_o] =>
    identify_Abstract_Rep_Use
      ltac:(type of r_o)
      AbstractReps ltac:(k r_o)
      
  end.

find_Abstract_Rep
  (fun idx : Fin.t (numRawQSschemaSchemas BookStoreSchema) =>
                                                                         @IndexedEnsemble (@RawTuple (rawSchemaHeading (Vector.nth (qschemaSchemas BookStoreSchema) idx))))
  ltac:(fun r_o n => makeEvar (DelegateReps n)
                              ltac:(fun r_n' =>
                                      let AbsR_r_o := fresh in 
                                      assert (AbsR (ValidImpls n) r_o r_n')
                                      as AbsR_r_o by intuition eauto)).
intuition.
eauto.
simpl in t.
Focus 2.


      * simplify with monad laws; simpl.
        refine pick val {| prim_fst := _;
                           prim_snd := {| prim_fst := _;
                                          prim_snd := _ |} |}.
        Focus 2.
        simpl.
        intuition.
        
        simpl in *.

      eapply SharpenFully_w_Delegates with
      (DelegateIDs := 2)
        (pAbsR := Iterate_Dep_Type_AbsR);
        intros; simpl; try split; try solve [econstructor]; intros.
      unfold UnConstryQueryStructure_Abstract_AbsR in *; simpl in *.
      Show Existentials. Variables.
      (fun idx =>

                      @IndexedEnsemble
                        (@RawTuple
                           (GetNRelSchemaHeading (qschemaSchemas BookStoreSchema)
                                                 idx)))).

             ).
        : Prop :=
        exists r_o_n : RepT (fun idx => sigT (fun ac =>
                                                AbsR (ValidImpls idx) (fst ac) (snd ac))),
          r_o = FunctorRepT _ _ (fun idx ac => fst (projT1 ac)) r_o_n
          /\ r_n = FunctorRepT _ _ (fun idx ac => snd (projT1 ac)) r_o_n.

      Definition




             (cAbsR :
                forall
,
                  RepT -> rep DelegateReps -> Prop)




(cAbsR : forall (DelegateReps : Fin.t DelegateIDs -> Type)
                    (DelegateImpls : forall idx : Fin.t DelegateIDs,
                                     ComputationalADT.pcADT
                                       (DelegateSigs idx)
                                       (DelegateReps idx)),
                  (forall idx : Fin.t DelegateIDs,
                   Sharpened (DelegateSpecs idx)) ->
                  RepT -> rep DelegateReps -> Prop)


      Definition UnConstrQueryStructure_AbsR
                 qsSchema
                 (DelegateIDs := numRawQSschemaSchemas qsSchema)
                 (DelegateReps :=
                    fun idx =>
                      @IndexedEnsemble
                        (@RawTuple
                           (GetNRelSchemaHeading (qschemaSchemas qsSchema)
                                                 idx)))

                 (numDelegateConstructors : Fin.t DelegateIDs -> nat)
                 (DelegateConstructorSigs
                  : forall (idx : Fin.t DelegateIDs),
                     Vector.t consSig (numDelegateConstructors idx))
                 (DelegateConstructorDefs
                  : forall (idx : Fin.t DelegateIDs),
                     ilist (B := consDef (Rep := DelegateReps idx))
                           (DelegateConstructorSigs idx))

                 (numDelegateMethods : Fin.t DelegateIDs -> nat)
                 (DelegateMethodSigs
                  : forall (idx : Fin.t DelegateIDs),
                     Vector.t methSig (numDelegateMethods idx))
                 (DelegateMethodDefs
                  : forall (idx : Fin.t DelegateIDs),
                     ilist (B := methDef (Rep := DelegateReps idx))
                           (DelegateMethodSigs idx))

                 (r_o : UnConstrQueryStructure qsSchema)
                 (r_n : Iterate_Dep_Type_BoundedIndex DelegateReps)
        : Prop :=
        forall (idx : Fin.t DelegateIDs),
          Same_set _ (GetUnConstrRelation r_o idx)
                   (Lookup_Iterate_Dep_Type _ r_n idx).



      eapply FullySharpened_Finish.
      match goal with
        |- FullySharpenedUnderDelegates (BuildADT (Rep := ?rep) _ _) _ =>
        let rep' := (eval cbv [UnConstrQueryStructure
                                 BookStoreSchema
                                 numRawQSschemaSchemas
                                 numQSschemaSchemas
                                 QueryStructureSchemaRaw
                                 qschemaSchemas
                                 Vector.map
                                 QSschemaSchemas
                                 ilist2
                                 rawSchemaHeading
                                 schemaRaw
                                 relSchema] in rep) in
        assert True; pose rep'
      end.


      simpl in T.
      Print RawUnConstrRelation.
      unfold BookStoreSchema in T.
      simpl BookStoreSchema in T.
      simpl in T.
      cbv delta in T.
      simpl in T.
      Set Printing All.
      idtac.

      apply Notation_Friendly_SharpenFully'.
      simpl.

      repeat simplify_queries.
      master_rewrite_drill.
finish honing.
eauto with typeclass_instances.
repeat simplify_queries'.
finish honing.
assert (pointwise_relation
Focus 2.
setoid_replace H' with c.

setoid_replace H1 with H1.
setoid_rewrite H1.

setoid_rewrite (@refine_Where_Intersection _ _ _ _ _ _).
      repeat simplify_queries'.

      doAny' simplify_queries
             rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
    + doAny' simplify_queries
             rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
    + doAny' simplify_queries
             rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
    + doAny' simplify_queries
             rewrite_drill ltac:(repeat subst_refine_evar; try finish honing).
      repeat simplify_queries.
      rewrite_drill.
      repeat simplify_queries.
      (rewrite_drill || finish honing).
      repeat simplify_queries.
      (rewrite_drill || finish honing).
      repeat simplify_queries.
      (rewrite_drill || finish honing).
      repeat simplify_queries.
      (rewrite_drill || finish honing).

    simplify_queries; set_refine_evar.
    repeat simplify_queries.
    Focus 2.
    repeat simplify_queries.
    (rewrite_drill || finish honing).

    doAny' simplify_queries rewrite_drill ltac:(try finish honing).

    rewrite_drill.
    { subst_FiniteTables_AbsR.
      finish honing. }

    finish honing.
    repeat first [
             simplify with monad laws
           | rewrite (@refine_Where_Intersection _ _ _ _ _ _)
           | Finite_FiniteTables_AbsR
           | subst_FiniteTables_AbsR
           ].
    rewrite_drill.
    repeat first [
             simplify with monad laws
           | rewrite (@refine_Where_Intersection _ _ _ _ _ _)
           | Finite_FiniteTables_AbsR
           | subst_FiniteTables_AbsR
           ].
    finish honing.

    simplify with monad laws.

    rewrite_drill.

    eauto using FiniteTable_FiniteTableAbsR',
      FiniteTable_FiniteTableAbsR.
    Focus 2.
    eapply FiniteTable_FiniteTableAbsR.
    unfold QueryResultComp; setoid_rewrite flatten_CompList_Return.
    finish honing.
    eapply ((proj2 H0) Fin.F1).
    simplify with monad laws.

    Ltac implement_stuff  :=
      repeat (cbv beta; simpl;
              first
                [simplify with monad laws; simpl
                | setoid_rewrite refine_If_Then_Else_Bind
                | rewrite (@FiniteTables_AbsR_Insert BookStoreSchema);
                  try simplify with monad laws; eauto
                | rewrite (@FiniteTables_AbsR_Delete BookStoreSchema);
                  eauto with typeclass_instances
                | try (refine pick val _; [ | eassumption ])
             ]).
    etransitivity.

Ltac stuff :=
  doAny ltac:(implement_stuff) rewrite_drill ltac:(finish honing).
stuff.
simpl.
destruct H0; subst.
finish honing.
  - etransitivity. stuff.
    destruct H0; subst; finish honing.
  - simplify with monad laws.
    unfold UnConstrQuery_In.
    Focused_refine_Query.
    rewrite (@refine_Where_Intersection _ _ _ _ _ _); eauto.
    unfold QueryResultComp; setoid_rewrite flatten_CompList_Return.
    finish honing.
    eapply ((proj2 H0) Fin.F1).
    simplify with monad laws.
    etransitivity.
    stuff.
    destruct H0; subst.
    finish honing.
  - simplify with monad laws.
    unfold UnConstrQuery_In.
    Focused_refine_Query.
    unfold QueryResultComp.
    setoid_rewrite (@refine_Where_Intersection _ _ _ _ _ _); eauto.
    unfold QueryResultComp; setoid_rewrite flatten_CompList_Return.
    finish honing.
    eapply ((proj2 H0) Fin.F1).
    simplify with monad laws.
    etransitivity.
    stuff.
    destruct H0; subst.
    finish honing.

    rewrite_drill.
Focus 2.
rewrite_drill.
Focus 2.
rewrite_drill.
rewrite (@FiniteTables_AbsR_Insert BookStoreSchema);
  try simplify with monad laws; eauto.

simpl.
    unfold QueryResultComp. set_evars. unfold FlattenCompList.flatten_CompList.
    finish honing.
    Show Existentials.
    unfold Query_For.
    unfold QueryResultComp; simpl.


  }

  master_plan EqIndexTactics.
      (* Uncomment this to see the mostly sharpened implementation *)
  (* partial_master_plan EqIndexTactics. *)

Time Defined.

Time Definition BookstoreImpl : ComputationalADT.cADT BookStoreSig :=
  Eval simpl in projT1 SharpenedBookStore.

Print BookstoreImpl.
