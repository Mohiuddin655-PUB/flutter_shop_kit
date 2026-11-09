import '../enums/pass_type.dart';
import 'buy_limit.dart';

/// What a pass costs now and what it gives, by its [type]: a duration pass runs [minutes] (more of them when it
/// [stack]s while running), a counter pass gives [count] uses, a daily pass [count] uses a day for [days], a limited
/// pass [count] uses within [minutes], an until pass runs until [until]; a lifetime pass needs none of them. A counter
/// holds at most [max] uses (0: no most), and a [limit] caps how often it is bought.
typedef PassTerms = ({PassType type, int price, int minutes, int count, int days, bool stack, DateTime? until, int max, BuyLimit? limit});
