(*
Verifies the field properties of Quadratic Field Extensions of fields of prime order p,
where p mod 4 = 3.
*)

Require Import ZArith Znumtheory.
Require Import Eqdep_dec.
Require Import List.
Require Import Lia.
Require Import Field.
From Coqprime Require Import Euler.
From Coqprime Require Import UList.
From Coqprime Require Import GZnZ.
From Coqprime Require Import Zp.
From Coqprime Require Import Pmod.
Require Import Zpow_facts.
Require Import Znat. 

Section Fp2.

Variable p: Z.
Hypothesis p_prime: prime p.
Hypothesis p_odd: 2 < p. 
Hypothesis p_mod3: p mod 4 =? 3 = true.

Lemma p_mod3_eq: p mod 4 = 3.
Proof. apply Z.eqb_eq, p_mod3. Qed.

Notation "x +p y" := (add p x y) (at level 100).
Notation "x *p y" := (mul p x y) (at level 90).
Notation "x -p y" := (sub p x y) (at level 100).
Notation "x /p y" := (div p x y) (at level 90).
Notation "n 'zmod' p" := (mkznz p (n mod p) (modz p n)) (at level 90).

Definition Quad_non_res: znz p :=
if (p mod 4 =? 3) then -1 zmod p
  else ( if (p mod 8 =? 3) then 2 zmod p
    else -2 zmod p ).

Notation "'β'" := Quad_non_res.

Ltac discriminate_incongruence H:= repeat
      (try (rewrite Zmod_small, Zmod_small in H; auto with zarith);
      rewrite <- Z_mod_plus_full with (b :=1) in H).

Lemma Quad_nres_not_zero:
β <> zero p.
Proof.
  unfold Quad_non_res, not; intros H. destruct (p mod 4 =? 3).
  - inversion H as [H1]; discriminate_incongruence H1.
  - destruct (p mod 8 =? 3) eqn:case2; inversion H as [H1]; discriminate_incongruence H1.
Qed.


Lemma minus_one_odd_power: forall x,
   0 <= x -> (-1)^(2*x + 1) = -1.
Proof.
  intros x H. rewrite (Z.pow_opp_odd 1 _), Z.pow_1_l; auto with zarith.
  exists x; reflexivity. Qed.

Lemma beta_is_non_res:
~(exists x, (x *p x) = β).
Proof.
  intros contra. assert (β = (-1 zmod p)) as case by (unfold Quad_non_res; rewrite p_mod3; reflexivity).
  rewrite case in contra; destruct contra as [x H]. inversion H as [H1].
  assert ((val p x)^(phi p) mod p = 1) as H0.
  - apply phi_power_is_1; auto with zarith.
    apply rel_prime_div with (val p x * val p x); try auto with zarith; 
    apply rel_prime_sym, prime_rel_prime; try apply p_prime; intros contra; apply Zdivide_mod in contra; rewrite contra in H1;
    rewrite <- Zmod_0_l with (p) in H1; symmetry in H1; discriminate_incongruence H1. 
  - pose proof p_mod3_eq as H'.
    assert (p = 4 * (p / 4) + 3) as H2 by (rewrite <- H'; apply Z_div_mod_eq; auto with zarith).
    apply (f_equal (fun y => y - 1)) in H2; remember (2 * (p / 4) + 1) as m eqn:Hm2.
    assert (p - 1 = 2 * m) as Hm; auto with zarith.
    apply (f_equal (fun y => y^m mod p)) in H1; rewrite <- Zpower_mod in H1; rewrite <- Zpower_mod in H1; try omega.
    assert (phi p = p - 1) as H3 by (apply prime_phi_n_minus_1; apply p_prime).
    assert ((val p x * val p x)^m = (val p x) ^ (phi p)) as H4 by (rewrite H3, Hm;
    assert (2 * m = m + m); auto with zarith;
    rewrite H4; rewrite Zpower_exp; try auto with zarith; apply Zmult_power; auto with zarith).
    rewrite <- H4 in H0; rewrite H0 in H1.
    assert ((-1)^m = -1) as H5 by (rewrite Hm2; apply minus_one_odd_power; omega).
    rewrite H5, <- Z_mod_plus_full with (-1) (1) (p) in H1.
    rewrite Zmod_small in H1; auto with zarith.
Qed.


Definition Fp2: Set := (znz p) * (znz p).

Theorem Fp2irr : forall (x1 x2 y1 y2 : znz p),
  x1 = y1 -> x2 = y2 -> (x1, x2) = (y1, y2).
Proof. intros x1 x2 y1 y2 H1 H2; subst x1 x2; reflexivity. Qed. 

(* Defining Ring Structure of Fp2 *)

Definition zerop2 := (zero p, zero p).

Definition onep2 := (one p, zero p).

Definition addp2 x1 x2 :=
  ( fst x1 +p fst x2, snd x1 +p snd x2).

Definition subp2 x1 x2 :=
  (fst x1 -p fst x2, snd x1 -p snd x2).

Definition mulp2 x1 x2 :=
   (fst x1 *p fst x2 +p β *p snd x1 *p snd x2,
    fst x1 *p snd x2 +p snd x1 *p fst x2).
  
Definition oppp2 x := (opp p (fst x), opp p (snd x)).

Add Field Fp : (FZpZ p p_prime).

Definition RFp2: ring_theory zerop2
  onep2 addp2 mulp2 subp2 oppp2 (@eq Fp2).
Proof.
  split; intros; case x; intros; refine (Fp2irr _ _ _ _ _ _); simpl; field. Qed.

Definition Zerop2_iff: forall x,
  x = zerop2 <-> ( fst x = zero p /\ snd x = zero p ).
Proof.
  intros [x1 x2]; split.
  - intros H; inversion H; split; reflexivity.
  - intros H; simpl in H; destruct H as [H1 H2]; rewrite H1, H2; reflexivity.
Qed.

Definition Zerop_iff: forall x,
  x = zero p <-> val p x = 0.
intros.
  split.
  - intros H; destruct x as [xval]; inversion H as [H1]; simpl;
    rewrite Zmod_small in H1; try apply H1; auto with zarith.
  - intros H; destruct x as [xval]; refine (zirr p _ _ _ _ _); simpl in H; rewrite H; auto with zarith.
  Qed.

Definition ZpZ_integral_domain: forall x y,
  x <> zero p -> y <> zero p -> (x *p y) <> zero p.
Proof.
  intros x y Hx Hy contra. 
  assert ((one p *p one p) = zero p) as H by (
    assert ((x *p y *p inv p x *p inv p y) = zero p) as H0 by
    (rewrite contra; field; split; assumption);
    rewrite <- H0; field; split; assumption).
  apply (FZpZ p p_prime); rewrite <- H; field.
Qed.

(* Definining additional field structure *)

Definition invp2 x :=
if ((val p (fst x)) =? 0) then  (zero p, inv p (snd x *p β))
  else
     ( one p /p fst x +p ( (snd x *p snd x *p β /p (fst x *p fst x)) *p inv p (fst x -p ( snd x *p snd x *p β /p fst x)) ), 
       opp p ((snd x /p fst x) /p ( fst x -p snd x *p snd x *p β /p fst x ))).

Definition divp2 x1 x2 := mulp2 x1 (invp2 x2).

Definition FFp2: field_theory zerop2 onep2 addp2 mulp2
  subp2 oppp2 divp2 invp2 (@eq Fp2).
Proof.
  split.
  - apply RFp2.
  - intros H; injection H; intros H'; discriminate_incongruence H'.
  - reflexivity.
  - intros [x1 x2] H. unfold invp2, mulp2, onep2. simpl. destruct (val p x1 =? 0) eqn:eq1; simpl.
    (*Case : x1 is zero*)
    + apply Z.eqb_eq in eq1; refine (Fp2irr _ _ _ _ _ _). field; split.
      * apply Quad_nres_not_zero.
      * intros contra; apply H. rewrite Zerop2_iff, Zerop_iff; auto.
      * apply Zerop_iff in eq1; rewrite eq1; field.
        split; try apply Quad_nres_not_zero.
        intros contra; rewrite eq1 in H; rewrite contra in H; contradiction.
    (* Case : x1 is not zero *)
    + apply Z.eqb_neq in eq1; refine (Fp2irr _ _ _ _ _ _); simpl. field. split.
      * intros H1; apply Zerop_iff in H1; contradiction.
      * destruct (val p x2 =? 0) eqn:eq2.
          (* case x2 is zero *)
          apply Z.eqb_eq in eq2; apply Zerop_iff in eq2; rewrite eq2.
          assert ((x1 *p x1 -p (zero p *p zero p) *p β) = (x1 *p x1)) as H0. field. rewrite H0.
          apply ZpZ_integral_domain; intros contra; apply Zerop_iff in contra; contradiction.
          (* case x2 is not zero *)
          intros contra.
          apply (f_equal (fun x => (x +p x2 *p x2 *p β) /p (x2 *p x2))) in contra.
          field_simplify in contra; try (apply Z.eqb_neq in eq2; apply Zerop_iff in contra; contradiction).
          apply beta_is_non_res; exists (x1 /p x2); rewrite <- contra;
          field; intros contra2; apply Zerop_iff in contra2; apply Z.eqb_neq in eq2; auto.
      * field. split. intros contra; apply Zerop_iff in contra; contradiction.
        destruct (val p x2 =? 0) eqn:eq2.
          (* case x2 is zero *)
          apply Z.eqb_eq in eq2; apply Zerop_iff in eq2; rewrite eq2.
          assert ((x1 *p x1 -p (zero p *p zero p) *p β) = (x1 *p x1)) as H0 by field. rewrite H0.
          apply ZpZ_integral_domain; intros contra; apply Zerop_iff in contra; contradiction.
          (* case x2 is not zero *)
          intros contra.
          apply (f_equal (fun x => (x +p x2 *p x2 *p β) /p (x2 *p x2))) in contra.
          field_simplify in contra; try (apply Z.eqb_neq in eq2; apply Zerop_iff in contra; contradiction).
          apply beta_is_non_res; exists (x1 /p x2); rewrite <- contra;
          field; intros contra2; apply Zerop_iff in contra2; apply Z.eqb_neq in eq2; auto.
Qed.

End Fp2.