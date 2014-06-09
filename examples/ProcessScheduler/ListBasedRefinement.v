Require Import DBSchema SetEq.
Require Import QueryStructureNotations.
Require Import ListImplementation.


Unset Implicit Arguments.
Notation "x '∈' y" := (In _ y x) (at level 50, no associativity).

Section ListBasedRefinement.

  Definition SimpleDB := prod nat (list Process).

  Definition SimpleDB_equivalence
             (rep : UnConstrQueryStructure ProcessSchedulerSchema)
             (db: SimpleDB) :=
    (forall a, List.In a (snd db) -> fst db > (a PID)) /\
    rep ! "processes" ≃ snd db.
    
  Lemma refine_decision :
    forall n c,
    (forall a, (GetUnConstrRelation c PROCESSES) a ->
               n > (a PID)) ->
      refine
        ({b |
          decides b
                  (forall tup' : Tuple,
              GetUnConstrRelation c PROCESSES tup' ->
              tupleAgree
                <PID_COLUMN :: n, STATE_COLUMN :: SLEEPING,
                   CPU_COLUMN :: 0> tup' [PID_COLUMN]%SchemaConstraints ->
              tupleAgree
                <PID_COLUMN :: n, STATE_COLUMN :: SLEEPING,
                   CPU_COLUMN :: 0> tup'
                [CPU_COLUMN; STATE_COLUMN]%SchemaConstraints)})
        (ret true).
  Proof.
    unfold refine, decides; intros; constructor; inversion_by computes_to_inv; subst.
    unfold tupleAgree; intros.
    elimtype False; generalize (H _ H0), (H1 PID).
    unfold BuildTuple, PID, ith_Bounded; simpl; intros.
    rewrite H4 in H3; eauto.
    omega.
  Qed.

  Lemma refine_decision' :
    forall n c,
    (forall a, (GetUnConstrRelation c PROCESSES) a ->
               n > (a PID)) ->
      refine
        ({b |
          decides b
                  (forall tup' : Tuple,
              GetUnConstrRelation c PROCESSES tup' ->
              tupleAgree tup'
                <PID_COLUMN :: n, STATE_COLUMN :: SLEEPING,
                   CPU_COLUMN :: 0> [PID_COLUMN]%SchemaConstraints ->
              tupleAgree tup'
                <PID_COLUMN :: n, STATE_COLUMN :: SLEEPING,
                   CPU_COLUMN :: 0>
                [CPU_COLUMN; STATE_COLUMN]%SchemaConstraints)})
        (ret true).
  Proof.
    unfold refine, decides; intros; constructor; inversion_by computes_to_inv; subst.
    unfold tupleAgree; intros.
    elimtype False; generalize (H _ H0), (H1 PID).
    unfold BuildTuple, PID, ith_Bounded; simpl; intros.
    rewrite H4 in H3; eauto.
    omega.
  Qed.

  Lemma tupleAgree_sym :
    forall h: Heading,
    forall t1 t2 attrs,
      @tupleAgree h t1 t2 attrs <-> @tupleAgree h t2 t1 attrs.
  Proof.
    intros h t1 t2 attrs; unfold tupleAgree.
    assert (forall attr, t1 attr = t2 attr <-> t2 attr = t1 attr) as inner_sym by (split; symmetry; trivial).
    setoid_rewrite inner_sym.
    f_equiv.
  Qed.

  Definition ProcessScheduler :
    Sharpened ProcessSchedulerSpec.
  Proof.
    unfold ProcessSchedulerSpec.

    unfold ForAll_In; start honing QueryStructure.

    (* == Introduce the list-based (SimpleDB) representation == *)
    hone representation using SimpleDB_equivalence.

    (* == Implement ENUMERATE == *)
    hone method ENUMERATE.
    {
      unfold SimpleDB_equivalence in *; split_and; subst.
      setoid_rewrite refineEquiv_pick_ex_computes_to_and.
      simplify with monad laws.
      setoid_rewrite Equivalent_UnConstr_In_EnsembleListEquivalence;
        simpl; eauto.
      setoid_rewrite Equivalent_List_In_Where; simpl.
      setoid_rewrite refine_For_List_Return; simplify with monad laws.
      rewrite refineEquiv_pick_pair with
      (PA := fun a => (forall a0 : Process, List.In a0 (snd a) -> fst a > a0 PID)
                      /\ _ (snd a)).
      rewrite refineEquiv_pick_pair_fst_dep with
      (PA := fun a => (forall a0 : Process, List.In a0 (snd a) -> fst a > a0 PID)).
      repeat (rewrite refine_pick_val; [simplify with monad laws | eassumption]).
      setoid_rewrite refineEquiv_pick_eq'.
      simplify with monad laws.
      finish honing.
    }

    (* == Implement GET_CPU_TIME == *)
    hone method GET_CPU_TIME.
    {
      unfold SimpleDB_equivalence in *; split_and.
      setoid_rewrite refineEquiv_pick_ex_computes_to_and.
      simplify with monad laws.
      setoid_rewrite Equivalent_UnConstr_In_EnsembleListEquivalence;
        simpl; eauto.
      setoid_rewrite Equivalent_List_In_Where; simpl.
      setoid_rewrite refine_For_List_Return; simplify with monad laws.
      simpl; rewrite refineEquiv_pick_pair with 
      (PA := fun a : SimpleDB => (forall a0 : Process, List.In a0 (snd a) -> fst a > a0 PID)
                      /\ EnsembleListEquivalence.EnsembleListEquivalence
        (c!"processes")%QueryImpl (snd a)).
      rewrite refineEquiv_pick_pair_fst_dep with
      (PA := fun a => (forall a0 : Process, List.In a0 (snd a) -> (fst a) > a0 PID)).
      repeat (rewrite refine_pick_val; [simplify with monad laws | eassumption]).
      setoid_rewrite refineEquiv_pick_eq'.
      simplify with monad laws.
      finish honing.
    }

    hone constructor INIT.
    {
      unfold SimpleDB_equivalence, DropQSConstraints_AbsR.
      repeat setoid_rewrite refineEquiv_pick_ex_computes_to_and.
      repeat setoid_rewrite refineEquiv_pick_eq'.
      simplify with monad laws.
      rewrite refineEquiv_pick_pair_fst_dep with
      (PA := fun a => (forall a0 : Process, List.In a0 (snd a) -> (fst a) > a0 PID)).
      repeat (rewrite refine_pick_val;
              [simplify with monad laws
              | apply EnsembleListEquivalence_Empty]).
      rewrite refine_pick_val.
      simplify with monad laws;
      subst_body; higher_order_1_reflexivity.
      instantiate (1 := 0); simpl; intuition.
    }

    (* Need to first drop Insertion Constraints.
    hone method SPAWN.
    {
      unfold SimpleDB_equivalence in *; split_and.
      setoid_rewrite refineEquiv_split_ex.
      setoid_rewrite refineEquiv_pick_computes_to_and.
      simplify with monad laws.
      setoid_rewrite refine_pick_eq_ex_bind.
      setoid_rewrite refine_pick_forall_Prop.
      setoid_rewrite refine_pick_eq_forall_Prop.
      setoid_rewrite (refine_pick_val _ (a := fst r_n)); eauto.
      setoid_rewrite refine_decision; eauto; try simplify with monad laws.
      setoid_rewrite refine_decision'; eauto; try simplify with monad laws.
      rewrite refine_pick_eq_ex_bind.
      rewrite refineEquiv_pick_pair with
      (PA := fun a => (forall a0 : Process, List.In a0 (snd a) -> fst a > a0 PID)
                      /\ _ (snd a)).
      rewrite refineEquiv_pick_pair_fst_dep with
      (PA := fun a => forall t : Tuple, List.In t (snd a) -> fst a > t PID).
      setoid_rewrite ImplementListInsert_eq; eauto;
      simplify with monad laws.
      setoid_rewrite (refine_pick_val _ (a := S (fst r_n))); eauto.
      simplify with monad laws.
      setoid_rewrite refineEquiv_pick_eq';
        simplify with monad laws; simpl.
      finish honing.
      simpl; intros; intuition.
      subst; unfold BuildTuple, PID, ith_Bounded; simpl; omega.
      generalize (H1 _ H3); omega.
      intros; eapply H1; eapply H2; eauto.
      intros; eapply H1; eapply H2; eauto.
      intros; eapply H1; eapply H2; eauto.
    } *)

    finish sharpening.
  Defined.
End ListBasedRefinement.
