test(start_game) :- next_phase, flush(_).

test(simple) :-
  channel_type(Channel, player_role),
  role_action(([], village), lynch, _, Channel).

test(xshot) :-
  channel_type(Channel, player_role),
  role_action((["1-shot"], village), lynch, _, Channel).

test(self) :-
  channel_type(Channel, player_role),
  access(Player, Channel),
  \+ role_action(([], village), lynch, [Player], Channel),
  role_action((["self"], village), lynch, [Player], Channel),
  findall(T, role_action((["self"], village), lynch, T, Channel), TargetLists),
  TargetLists = [[Player], [noone]].

test(day) :-
  channel_type(Channel, player_role),
  \+ role_action(([], doctor), protect, _, Channel),
  role_action((["day"], doctor), protect, _, Channel).

test(hyperactive) :-
  channel_type(Channel, player_role),
  \+ role_action(([], doctor), protect, _, Channel),
  role_action((["hyperactive"], doctor), protect, _, Channel).

test(weak) :-
  channel_type(Channel, player_role),
  role_action((["weak"], village), lynch, _, Channel, [], ActionMods),
  member("weak", ActionMods).

test(compulsive) :-
  channel_type(Channel, player_role),
  role_action(([], village), lynch, [noone], Channel),
  role_action((["compulsive"], village), lynch, [_], Channel),
  \+ role_action((["compulsive"], village), lynch, [noone], Channel).

test(alias) :-
  channel_type(Channel, player_role),
  access(Player, Channel),
  role_action((["day", "self", "compulsive"], doctor), protect, _, Channel),
  role_action((["day"], bulletproof), protect, _, Channel).

test(crole) :-
  channel_type(Channel, player_role),
  retract_all(channel_role(Channel, _)),
  asserta(channel_role(Channel, (["day"], doctor))),
  channel_action(Channel, protect, _).

test(vengeful) :-
  channel_type(Channel, player_role),
  access(Player, Channel),
  retract_all(channel_role(Channel, _)),
  asserta(channel_role(Channel, (["vengeful"], cop))),
  \+ can_vote(_, Channel, investigate, _, _),
  channel_type(Global, global_role),
  handle_hammer(Global, lynch, [Player], []),
  channel_action(Channel, investigate, [3]),
  retract_all(locked(_,_,_,_)).

test(automatic) :-
  channel_type(Channel, player_role),
  retract_all(channel_role(Channel, _)),
  asserta(channel_role(Channel, (["instant", "self", "day"], cop))),
  findall(A, can_vote(P, Channel, A, T, _), X),
  X = [_],
  maybe_next_phase,
  flush(Y),
  Y = [message(Channel, _, "is not Mafia")].

test(bulletproof) :-
  channel_type(Channel, player_role),
  retract_all(channel_role(Channel, _)),
  asserta(channel_role(Channel, ([], bulletproof))),
  findall(A, can_vote(P, Channel, A, T, _), X),
  X = [_],
  maybe_next_phase,
  action_history(_, action(P, protect, [P], _, _), _).
