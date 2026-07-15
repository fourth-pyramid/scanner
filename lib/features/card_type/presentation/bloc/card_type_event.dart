part of 'card_type_bloc.dart';

// ponytail: standard bloc events for card type
abstract class CardTypeEvent extends Equatable {
  const CardTypeEvent();

  @override
  List<Object?> get props => [];
}

class GetCategoriesEvent extends CardTypeEvent {
  const GetCategoriesEvent();
}
