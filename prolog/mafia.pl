% seq/1, status

%% :- module(mafia, [join/1, vote/4, unvote/3, join_channel/2, access/2, setup_game/1, game_info/2, flush/1, create_channel/3, next_phase/0, call_self/1]).

setup_size(N) :- findall(Id, setup_alignment(Id, _), Ids), length(Ids, N).

% defining dynamic predicates the erlog way
voting(q, q, q, q, q) :- fail.
action_history(q, q, q) :- fail.
access(q, q) :- fail.
current_phase(q) :- fail. % false during signups
player(q, q) :- fail. % user_id. player_id
phase_timer(q, q) :- fail.
speed(q) :- fail.
setup_alignment(q, q) :- fail.
setup_role(q, q, q) :- fail.
channel_role(q, q) :- fail.
channel_type(q, q) :- fail.
locked(q, q, q, q) :- fail.
dead(q) :- fail.
setup_phases(q) :- fail.

:- include(roles).
:- include(actions).
:- include(resolve).
:- include(utils).

%% setup_game(Setup, Speed) :-
%%   dict_get_ex(teams, Setup, Teams),
%%   dict_get_ex(player_roles, Setup, PlayerRoles),
%%   dict_get_ex(alignment_roles, Setup, AlignmentRoles),
%%   dict_get_ex(global_roles, Setup, GlobalRoles),
%%   dict_get_ex(phases, Setup, Phases),
%%   forall(member(A, Teams), assertz(setup_alignment(A.player,A.team))),
%%   forall(member(A, PlayerRoles), assertz(player_role(A.player, (A.mods, A.role)))),
%%   forall(member(A, AlignmentRoles), assertz(alignment_role(A.team, (A.mods, A.role)))),
%%   forall(member(A, GlobalRoles), assertz(global_role((A.mods, A.role)))),
%%   asserta(speed(Speed)),
%%   assertz(setup_phases(Phases)).

signups :- \+ current_phase(_).

state(X) :- asserta(X), send(X).

phase_name(PhaseNumber, Name) :-
  setup_phases(Phases),
  length(Phases, L),
  I is PhaseNumber mod L,
  nth0(I, Phases, Name).

current_phase_name(Name) :-
  current_phase(P),
  phase_name(P, Name).

players(Players) :- findall(P, player(_, P), Players).
player_count(N) :- players(Players), length(Players, N).
full_game :- player_count(P), setup_size(S), P >= S.

alive(X) :- player(X, _), \+ dead(X).

%set_phase_timer(T) :-
%speed(Speed),
%RealT is T / Speed,
%alarm(RealT, next_phase, Id),
%asserta(phase_timer(Id)).

game_info(User, [active(Active), next_phase(End), players(Players)]) :-
  player(User, Player),
  findall([channel(C), members(Members), actions(Actions), votes(Votes), role(Role), type(Type)], (
      join_channel(User, C),
      findall(Member, join_channel(Member, C), Members),
      nil_fallback(Role, channel_role(C, Role)),
      channel_type(C, Type),
      findall([act(Action), opt(Targets)], channel_action(C, Action, Targets), Actions),
      ignore(current_phase(P)),
      findall([player(Player), action(Action), targets(T)], voting(P, Player, C, Action, T), Votes)
  ), Active),
  nil_fallback(End, phase_timer(_, End)),
  findall([player(P), user(U), status(Status)], (
      player(U, P), status(P, Status)
  ), Players).

join(User) :- player(User, _), !.
join(User) :-
  signups,
  \+ full_game,
  asserta(player(User, User)), % player id is the id of the first user taking the slot
  forall(join_channel(User, Channel), send(join(User, Channel))),
  (full_game, set_phase_timer(10), !; true).

set_phase_timer(After) :-
  remove_phase_timer,
  speed(Speed),
  Ms is truncate(After * 1000 / Speed),
  get_time(Time),
  End is Time + Ms,
  erl(erlang:self, Self),
  erl(erlang:send_after(Ms, Self, next_phase), Timer),
  send(next_phase(End)),
  asserta(phase_timer(Timer, End)).

remove_phase_timer :-
  phase_timer(Timer, _), !,
  erl(timer:cancel(Timer), _),
  retract(phase_timer(_, _)).

remove_phase_timer.

next_phase :-
  full_game,
  end_phase,
  increase_current_phase,
  start_phase.

locked_actions(Actions) :-
  current_phase(P),
  findall(action(Actor, Action, Targets, Channel, ActionMods), (
    locked(Channel, Action, Targets, ActionMods),
    once(voting(P, Actor, Channel, Action, Targets)),
    \+ member(noone, Targets)
    ), Actions).

end_phase :-
  current_phase(_), !, % game has already started
  locked_actions(Actions),
  retract_all(locked(_, _, _, _)),
  resolve(Actions, SuccessfulActions),
  forall(member(A, SuccessfulActions), process_action(A)),
  forall((
    channel_role(Channel, _),
    \+ join_channel(_, Channel)),
    send(leave(all, Channel))
  ).

end_phase :- send(leave(all, pre)), start_game. % ending signups = starting the game

increase_current_phase :- retract(current_phase(P)), Next is P + 1, asserta(current_phase(Next)), !.
increase_current_phase :- asserta(current_phase(0)).

start_phase :- !, true.
start_phase :-
  forall(player(_, Player), (
    game_info(Player, GameInfo),
    send(game_info(Player, GameInfo))
  )).

start_game :-
  players(Players),
  random_permutation(Players, ShuffledPlayers),
  forall(player(_, Player), (
    create_channel(player, none, Channel),
    grant_access(Player, Channel)
  )),
  forall(setup_role(player, N, Role), (
    nth1(N, ShuffledPlayers, Player),
    create_channel(player_role, Role, Channel),
    grant_access(Player, Channel)
   )),
  forall(setup_role(alignment, Alignment, Role), ( % for every alignment role, add a channel
    create_channel(alignment_role, Role, Channel),
    forall((setup_alignment(N, Alignment), nth1(N, ShuffledPlayers, Player)), grant_access(Player, Channel))
  )),
  forall(setup_role(global, _, Role), (
    create_channel(global_role, Role, Channel),
    asserta(global_channel(Channel)),
    forall(member(Player, Players), grant_access(Player, Channel))
  )).


channel_action(C, A, T) :- channel_action(C, A, T, _).
channel_action(C, A) :- once(channel_action(C, A, _, _)).
channel_action(C) :- once(channel_action(C, _, _, _)).

channel_action(Channel, Action, Targets, ActionMods) :-
  channel_role(Channel, Role),
  role_action(Role, Action, Targets, Channel, [], ActionMods),
  current_phase(P),
  \+ action_history(P, action(_, Action, _, Channel), _).

create_channel(Type, Role, Channel) :-
  uid(Channel),
  send(create_channel(Channel)),
  asserta(channel_role(Channel, Role)),
  asserta(channel_type(Channel, Type)).

grant_access(Player, Channel) :- access(Player, Channel), !.
grant_access(Player, Channel) :-
  player(User, Player),
  send(join(User, Channel)),  
  asserta(access(Player, Channel)).

retract_access(Player, Channel) :- \+ access(Player, Channel), !.
retract_access(Player, Channel) :-
  retract(access(Player, Channel)),
  send(leave(Player, Channel)),
  asserta(access(Player, Channel)).

join_channel(User, Channel) :-
  player(User, Player),
  channel_type(Channel, signups),
  signups.

join_channel(User, Channel) :-
  player(User, Player),
  access(Player, Channel),
  (channel_type(Channel, player); once(channel_action(Channel, _, _))).

unvote(User, Channel, Action) :-
  player(User, Player),
  current_phase(P),
  can_unvote(Player, Channel, Action),
  ignore(retract_all(voting(P, Player, Channel, Action, _))),
  send(unvote(Player, Channel, Action)).

vote(User, Channel, Action, Targets) :-
  player(User, Player),
  current_phase(P),
  can_vote(Player, Channel, Action, Targets, ActionMods),
  ignore(retract(voting(P, Player, Channel, Action, _))),
  asserta(voting(P, Player, Channel, Action, Targets)),
  send(vote(Player, Channel, Action, Targets)),
  check_hammer(Channel, Action, Targets, ActionMods).

can_unvote(_Player, Channel, Action) :-
  channel_action(Channel, Action, _),
  \+ locked(Channel, Action, _, _).

can_vote(_Player, Channel, Action, Targets, ActionMods) :-
  channel_action(Channel, Action, Targets, ActionMods),
  \+ locked(Channel, Action, _, _).

check_hammer(Channel, Action, Targets, ActionMods) :-
  count(access(_, Channel), ChannelMemberCount),
  current_phase(P),
  count(voting(P, _, Channel, Action, Targets), VoteCount),
  VoteCount > ChannelMemberCount / 2, !,
  lock(Channel, Action, Targets, ActionMods),
  maybe_next_phase.

check_hammer(_, _, _, _).

lock(Channel, Action, Targets, ActionMods) :-
    asserta(locked(Channel, Action, Targets, ActionMods)).

maybe_next_phase :-
  forall(channel_action(Channel, Action, _), locked(Channel, Action, _, _)), !,
  next_phase.

maybe_next_phase.

status(Player, dead) :- dead(Player), !.
status(Player, alive).

%role_action([cop], check, _).
%role_action([doc], protect, _).
%role_action([{shot, 1} | Role], Action, Channel) :- action_history(_, Action, Channel, _), role_action(Role, Action).

%blocked(Player, (_, Phase, _), _) :- status(Phase, Player, blocked).
%blocked(Player, Action, Targets) :- member(X, Targets), status(Phase, X, rolestopped).

%do_action(Player, Action, Targets) :- action(Player, Action, Targets), \+ blocked(Player).
%do_action(Player, Action, Targets).

%status(Phase, Player, blocked) :- action(_, (block, _), Targets), member(Player, Targets).
