action(Actor, Action, Targets, Channel, []) :-
  action(Actor, Action, Targets, Channel).

action(_, kill, [X], _) :- !,
  kill(X, "has been killed").

action(_, lynch, [X], _) :- !,
  kill(X, "has been lynched"),
  asserta(dead(X)).

action(_, investigate, [X], Channel) :-
  current_phase(P),
  action_history(P, action(_, frame, [X], _, _), success), !,
  send(message(Channel, X, "is Mafia")).
  
action(_, investigate, [X], Channel) :-
  current_phase(P),
  action_history(P, action(_, represent, [X], _, _), success), !,
  send(message(Channel, X, "is not Mafia")).

action(_, investigate, [X], Channel) :-
  player_team(X, "mafia"), !,
  send(message(Channel, X, "is Mafia")).
  
action(_, investigate, [X], Channel) :- !,
  send(message(Channel, X, "is not Mafia")).

trackable_action(Act) :-
  current_phase(P),
  action_history(P, Act, Status),
  Status \= blocked,
  action(_, _, _, _, Mods) = Act,
  \+ member("ninja", Mods).

action(_, track, [X], Channel) :-
  current_phase(P),
  forall((
    trackable_action(action(X, _, Targets, _, _)),
    member(Target, Targets)
  ), send(message(Channel, Target, "was targeted"))).

action(_, watch, [X], Channel) :-
  current_phase(P),
  forall((
    trackable_action(action(Actor, _, Targets, _, _)),
    member(X, Targets)
  ), send(message(Channel, Actor, "targeted"))).

action(_, peep, [X], Channel) :-
  current_phase(P),
  forall((
    trackable_action(action(_, Action, Targets, _, _)),
    member(X, Targets)
  ), send(message(Channel, X, Action))).

action(_, follow, [X], Channel) :-
  current_phase(P),
  forall((
    trackable_action(action(X, Action, _, _, _))
  ), send(message(Channel, X, Action))).

action(_, visit, _, _).

action_mod("weak", Actor, _, Targets, _, _) :-
  member(T, Targets),
  player_team(T, Team),
  Team \= "town",
  !, kill(Actor).

action_mod(_,_,_,_,_,_).

action(Actor, Act, T, C, [Mod | Mods]) :-
  action_mod(Mod, Actor, Act, T, C, Mods),
  action(Actor, Act, T, C, Mods).

kill(Player, Message) :-
  send(message(Player, Message)),
  flip(Player),
  asserta(dead(Player)),
  forall(access(Player, Channel), retract_access(Player, Channel)).
