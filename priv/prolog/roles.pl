role_action(R, A, T, C) :- role_action(R, A, T, C, [], _).
role_action(R, A, T, C, O) :- role_action(R, A, T, C, [], O).

role_action(([], Role), Action, Targets, Channel, ActionMods, ActionMods) :-
  main_role_action(Role, Action), !,
  (member(phase, ActionMods), !; default_phase_constraint(Role)),
  (member(target, ActionMods), !; default_target_constraint(Role, Channel, Targets)).

role_action(([], Alias), Action, Targets, Channel, LeftActionMods, RightActionMods) :-
  alias(Alias, Role),
  role_action(Role, Action, Targets, Channel, LeftActionMods, RightActionMods).

role_action((["self" | Mods], Role), Action, [Target], Channel, LeftActionMods, RightActionMods) :-
  !, (access(Target, Channel); Target = noone),
  role_action((Mods, Role), Action, [Target], Channel, [target | LeftActionMods], RightActionMods).

% limiting modifiers, also ones that alter default behavior such as day
role_action(([Mod | Mods], Role), Action, Targets, Channel, LeftActionMods, RightActionMods) :-
  action_mods(Mod, LeftActionMods, NewActionMods),
  role_action((Mods, Role), Action, Targets, Channel, NewActionMods, RightActionMods),
  \+ mod_excludes(Mod, Action, Targets, Channel).

default_phase_constraint(village) :-
  !, current_phase_name(day).

default_phase_constraint(_) :-
  current_phase_name(night).

alive_or_noone(Player) :- alive(Player).
alive_or_noone(noone).

default_target_constraint(_, Channel, [Target]) :-
  alive_or_noone(Target),
  (channel_type(Channel, global_role); other(Target, Channel)).

other(Player, Channel) :- \+ access(Player, Channel).

main_role_action(village, lynch).
main_role_action(cop, investigate).
main_role_action(killer, kill).
main_role_action(doctor, protect).
main_role_action(roleblocker, block).
main_role_action(jailkeeper, jail).
main_role_action(tracker, track).
main_role_action(watcher, watch).
main_role_action(follower, follow).
main_role_action(voyeur, peep).
main_role_action(visitor, visit).

alias(bulletproof, (["ninja", "hyperactive", "strong-willed", "instant", "self"], doctor)).

mod_excludes([Xchar | "-shot"], Action, _, Channel) :-
  char_nr(Xchar, X),
  count(action_history(_, action(_, Action, _, Channel), _), Count),
  Count >= X.

mod_excludes("compulsive", _, Targets, _) :-
  member(noone, Targets).

mod_excludes("instant", _, Targets, _) :-
  member(noone, Targets).

even :-
  current_phase_number(N),
  N mod 2 is 0.

mod_excludes("odd-day", _, _, _) :-
  even,
  \+ current_phase_name(day).

mod_excludes("even-day", _, _, _) :-
  \+ even,
  \+ current_phase_name(day).

mod_excludes("day", _, _, _) :-
  \+ current_phase_name(day).

mod_excludes("vengeful", _, _, VengefulChannel) :-
  \+ (
    locked(LynchChannel, lynch, [Actor], _),
    access(Actor, VengefulChannel),
    access(Actor, LynchChannel)
  ).

action_mods("day", N, [phase | N]) :- !.
action_mods("hyperactive", N, [phase | N]) :- !.
action_mods("vengeful", N, [phase | N]) :- !.

% add any remaining role mods as an action mod; will be ignored if useless
action_mods(Mod, N, [Mod | N]).

is_role(Role) :-
  clause(main_role_action(Role, _), _).

is_role(Role) :-
  clause(alias(Role, _), _).

is_mod(Mod) :-
  clause(role_action(([Mod | _], _), _, _, _, _, _), _),
  string(Mod).

is_mod(Mod) :-
  clause(mod_excludes(Mod, _, _, _), _),
  string(Mod).

is_mod(Mod) :-
  clause(action_mod(Mod, _, _, _, _, _), _),
  string(Mod).

is_mod([X|"-shot"]) :- char_nr(X, _).

role_info([roles(Roles), mods(Mods)]) :-
  findall(R, is_role(R), Roles),
  findall(M, is_mod(M), Mods).
