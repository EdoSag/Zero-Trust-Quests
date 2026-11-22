import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_trust_core/zero_trust_core.dart';
import 'package:zerotrust_quests/engine/hero.dart';
import 'package:zerotrust_quests/model/quest.dart';
import 'package:zerotrust_quests/model/reward.dart';
import 'package:zerotrust_quests/party/party_data.dart';
import 'package:zerotrust_quests/party/party_model.dart';
import 'package:zerotrust_quests/party/party_pages.dart';
import 'package:zerotrust_quests/ui/home_page.dart';

import 'support/app.dart';

const alice = '11111111-1111-4111-8111-111111111111';
const bob = '22222222-2222-4222-8222-222222222222';
const carol = '33333333-3333-4333-8333-333333333333';

Quest daily(String day, {bool done = true, String goal = 'g'}) => Quest(
  id: 'daily-$goal-$day-0',
  goalId: goal,
  kind: QuestKind.daily,
  day: day,
  steps: [QuestStep(activity: 'pushups', target: 10, progress: done ? 10 : 2)],
  difficulty: 1,
  xp: 35,
  gold: 8,
);

Reward task(String id, String day) =>
    Reward(id: 'task-$id', source: RewardSource.task, day: day, xp: 8, gold: 2);

Uint8List dek(int seed) =>
    Uint8List.fromList(List<int>.generate(32, (i) => (seed * 7 + i) & 0xff));

/// One account's phone, on the in-memory stand-in for Supabase.
class Phone {
  Phone(this.server, this.userId, this.seed);
  final InMemorySpaceServer server;
  final String userId;
  final int seed;
  final Map<String, InMemoryItemStore> stores = {};
  late final SharedSpaces spaces;

  Future<Phone> start() async {
    spaces = SharedSpaces(
      app: 'quests',
      myUserId: userId,
      identity: await ZtIdentity.fromDek(dek(seed)),
      backend: server.backendFor(userId),
      privateStore: InMemorySpacePrivateStore(),
      openStore: (id) async => stores.putIfAbsent(id, InMemoryItemStore.new),
      deleteStore: (id) async => stores.remove(id),
      deviceId: 'phone-$userId',
      policy: questsSpacePolicy,
    );
    return this;
  }

  Future<PartyData> read(String spaceId) async {
    final space = await spaces.open(spaceId);
    await spaces.sync(space);
    final info = (await spaces.list()).firstWhere((i) => i.id == spaceId);
    return readParty(SpaceEntry(info: info, space: space), userId);
  }
}

void main() {
  const party = Party(name: 'Night Owls');

  group('hunts', () {
    test('a new hunt picks the next boss and spans its days', () {
      final first = party.nextHunt('2026-11-20', 7, salt: 'space');
      expect(first.round, 1);
      expect(first.start, '2026-11-20');
      expect(first.end, '2026-11-26');
      expect(first.days, 7);
      expect(partyBosses, contains(first.boss));
      final second = first.nextHunt('2026-11-27', 3, salt: 'space');
      expect(second.round, 2);
      expect(second.boss, isNot(first.boss));
      expect(second.name, 'Night Owls');
    });

    test('the boss grows with the party', () {
      final hunt = party.nextHunt('2026-11-20', 7);
      expect(hunt.hp(1), 15 * 7);
      expect(hunt.hp(3), 15 * 7 * 3);
      expect(
        party
            .copyWith(difficulty: PartyDifficulty.hard)
            .nextHunt('2026-11-20', 3)
            .hp(2),
        20 * 3 * 2,
      );
    });

    test('damage counts done dailies and tasks inside the hunt only', () {
      final hunt = party.nextHunt('2026-11-20', 3);
      final quests = [
        daily('2026-11-19'), // before
        daily('2026-11-20'),
        daily('2026-11-21', goal: 'h'),
        daily('2026-11-21', done: false, goal: 'k'),
        daily('2026-11-23'), // after
      ];
      final rewards = [
        for (var i = 0; i < 12; i++) task('a$i', '2026-11-20'), // 10 count
        task('b', '2026-11-25'),
      ];
      final me = PartyMember.compute(
        userId: alice,
        party: hunt,
        quests: quests,
        rewards: rewards,
        stats: HeroStats.empty,
        look: const HeroLook(emblem: 'star', color: 'rose'),
      );
      expect(me.dailies, 2);
      expect(me.tasks, HeroStats.tasksPerDay);
      expect(me.damage, 2 * 10 + 10 * 2);
      expect(me.round, 1);
      expect(me.emblem, 'star');
    });

    test('the board sums current members, for this hunt only', () {
      final hunt = party.nextHunt('2026-11-20', 3);
      final state = HuntState.of(
        party: hunt,
        members: {alice: 'Alice', bob: 'Bob'},
        progress: {
          alice: const PartyMember(userId: alice, round: 1, damage: 50),
          bob: const PartyMember(userId: bob, round: 0, damage: 999),
        },
      );
      expect(state.hp, 15 * 3 * 2);
      expect(state.damage, 50); // Bob's numbers are from an older hunt
      expect(state.board.first.name, 'Alice');
      expect(state.defeated, isFalse);
      expect(state.overOn('2026-11-22'), isFalse);
      expect(state.overOn('2026-11-23'), isTrue);

      final beaten = HuntState.of(
        party: hunt,
        members: {alice: 'Alice'},
        progress: {
          alice: const PartyMember(userId: alice, round: 1, damage: 45),
        },
      );
      expect(beaten.defeated, isTrue);
      expect(beaten.hpLeft, 0);
    });

    test('member rows are read only under their owner id', () {
      expect(
        PartyMember.fromJson('member/$alice', {'damage': 3})?.userId,
        alice,
      );
      expect(PartyMember.fromJson('member/', {'damage': 3}), isNull);
      expect(PartyMember.fromJson('party', {'damage': 3}), isNull);
      expect(PartyMember.fromJson('member/$alice', {'damage': -5})?.damage, 0);
    });

    test('a beaten boss stays for helpers who were offline', () {
      final hunt = party.nextHunt('2026-11-20', 3);
      final beaten = HuntState.of(
        party: hunt,
        members: {alice: 'Alice', bob: 'Bob', carol: 'Carol'},
        progress: {
          alice: const PartyMember(userId: alice, round: 1, damage: 120),
          bob: const PartyMember(userId: bob, round: 1, damage: 20),
          carol: const PartyMember(userId: carol, round: 1),
        },
      );
      expect(beaten.defeated, isTrue);
      final next = hunt
          .rememberWin(beaten)
          .nextHunt('2026-11-24', 7, salt: 's');
      expect(next.round, 2);
      final back = Party.fromJson(next.toJson());
      expect(back.won.single.round, 1);
      expect(back.won.single.days, 3);
      expect(back.won.single.helpers, unorderedEquals([alice, bob]));
      final r = pastHuntReward(
        spaceId: 's1',
        hunt: back.won.single,
        day: '2026-11-25',
      );
      // The same id as when taken during the hunt: never twice.
      expect(
        r.id,
        partyReward(spaceId: 's1', party: hunt, day: '2026-11-22').id,
      );
      expect(r.xp, PartyRules.rewardXp(3));

      // Not beaten: nothing kept.
      final lost = HuntState.of(
        party: hunt,
        members: {alice: 'Alice'},
        progress: const {},
      );
      expect(hunt.rememberWin(lost).won, isEmpty);

      // Only the last few are kept.
      var p = party;
      for (var i = 0; i < Party.keepWon + 2; i++) {
        p = p.nextHunt('2026-11-20', 3);
        p = p.rememberWin(
          HuntState.of(
            party: p,
            members: {alice: 'Alice'},
            progress: {
              alice: PartyMember(userId: alice, round: p.round, damage: 999),
            },
          ),
        );
      }
      expect(p.won.length, Party.keepWon);
      expect(p.won.last.round, Party.keepWon + 2);
    });

    test('beating a boss is one reward per hunt', () {
      final hunt = party.nextHunt('2026-11-20', 7);
      final r = partyReward(spaceId: 's1', party: hunt, day: '2026-11-22');
      expect(r.id, 'party-s1-1');
      expect(r.xp, 40 + 70);
      expect(r.gold, (40 + 70) ~/ 3);
      final stats = HeroStats.compute(
        const [],
        const [],
        '2026-11-22',
        rewards: [r],
      );
      expect(stats.partyWins, 1);
      expect(stats.xp, r.xp);
      expect(stats.gold, r.gold);
    });
  });

  group('shared party', () {
    late InMemorySpaceServer server;
    late Phone a, b;

    setUp(() async {
      server = InMemorySpaceServer();
      a = await Phone(server, alice, 1).start();
      b = await Phone(server, bob, 2).start();
    });

    Future<String> startParty() async {
      final space = await a.spaces.create(myName: 'Alice');
      await space.save(
        Party.itemId,
        party.nextHunt('2026-11-20', 7, salt: space.id).toJson(),
      );
      await a.spaces.sync(space);
      final link = await a.spaces.invite(space.id);
      final joined = await b.spaces.answer(
        SpaceInviteLink.parse(link.toString()),
        myName: 'Bob',
      );
      final pending = await a.spaces.pendingJoins(space.id);
      expect(pending.single.verificationCode, joined.verificationCode);
      await a.spaces.confirm(pending.single);
      await b.spaces.sync(await b.spaces.open(space.id));
      return space.id;
    }

    test('both phones see the boss and everyone\'s damage', () async {
      final id = await startParty();
      for (final (phone, damage) in [(a, 40), (b, 30)]) {
        final space = await phone.spaces.open(id);
        await space.save(
          PartyMember.itemIdFor(phone.userId),
          PartyMember(userId: phone.userId, round: 1, damage: damage).toJson(),
        );
        await phone.spaces.sync(space);
      }
      for (final phone in [a, b]) {
        final data = await phone.read(id);
        expect(data.party?.name, 'Night Owls');
        expect(data.members.keys, containsAll([alice, bob]));
        expect(data.hunt!.damage, 70);
        expect(data.hunt!.hp, 15 * 7 * 2);
      }
    });

    test(
      'members can\'t change the hunt or write in someone else\'s name',
      () async {
        final id = await startParty();
        final space = await b.spaces.open(id);
        expect(
          () => space.save(
            PartyMember.itemIdFor(alice),
            const PartyMember(userId: alice, round: 1, damage: 1).toJson(),
          ),
          throwsArgumentError,
        );
        // Bob isn't an owner: the party item is refused.
        await expectLater(() async {
          await space.save(
            Party.itemId,
            party.copyWith(name: 'Hijacked').toJson(),
          );
          await b.spaces.sync(space);
        }(), throwsA(anything));
        final data = await a.read(id);
        expect(data.party?.name, 'Night Owls');
      },
    );
  });

  group('screens', () {
    testWidgets('a running hunt shows the boss\'s hit points', (tester) async {
      final hunt = party.nextHunt('2026-11-20', 7, salt: 's');
      final state = HuntState.of(
        party: hunt,
        members: {alice: 'Alice'},
        progress: {
          alice: const PartyMember(userId: alice, round: 1, damage: 30),
        },
      );
      await tester.pumpWidget(
        app(
          Scaffold(
            body: HuntBar(hunt: state, today: '2026-11-22'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('75 of 105 HP left'), findsOneWidget);
    });

    testWidgets('a beaten boss says what everyone gets', (tester) async {
      final hunt = party.nextHunt('2026-11-20', 3, salt: 's');
      final state = HuntState.of(
        party: hunt,
        members: {alice: 'Alice'},
        progress: {
          alice: const PartyMember(userId: alice, round: 1, damage: 45),
        },
      );
      await tester.pumpWidget(
        app(
          Scaffold(
            body: HuntBar(hunt: state, today: '2026-11-21'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Beaten! Everyone who helped gets 70 XP and 23 gold.'),
        findsOneWidget,
      );
    });

    testWidgets('the party tab offers to start or join a party', (
      tester,
    ) async {
      await tester.pumpWidget(app(const HomePage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Party'));
      await tester.pumpAndSettle();
      final start = tester.getRect(find.text('Start a party'));
      final join = tester.getRect(find.text('Join with an invite'));
      expect(start.width, greaterThan(0));
      // Join is under Start, both on screen.
      expect(join.top, greaterThan(start.bottom));
      expect(
        join.bottom,
        lessThan(
          tester.view.physicalSize.height / tester.view.devicePixelRatio,
        ),
      );
      await tester.tap(find.text('Start a party'));
      await tester.pumpAndSettle();
      expect(find.text('Party name'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      // Nothing to create without a name.
      final create = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Create party'),
      );
      expect(create.onPressed, isNull);
    });
  });
}
